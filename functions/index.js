const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Konfigurasi global (Opsional: membatasi instance agar hemat biaya)
setGlobalOptions({ maxInstances: 10, region: "asia-southeast2" });

// Fungsi ini akan berjalan otomatis setiap ada pesan baru di chat_rooms
exports.sendChatNotification = onDocumentCreated(
  "chat_rooms/{roomId}/messages/{messageId}",
  async (event) => {
    // Di Gen 2, data snapshot ada di event.data
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    // Parameter path (roomId) ada di event.params
    const roomId = event.params.roomId;

    // 1. Ambil data Room untuk tahu siapa saja pesertanya
    const roomSnap = await admin
      .firestore()
      .collection("chat_rooms")
      .doc(roomId)
      .get();
    if (!roomSnap.exists) return;

    const participants = roomSnap.data().participants;

    // 2. Cari siapa penerimanya (yang BUKAN pengirim pesan ini)
    const receiverId = participants.find((id) => id !== messageData.senderId);
    if (!receiverId) return null;

    // 3. Ambil Token FCM milik penerima dari database users
    const userSnap = await admin
      .firestore()
      .collection("users")
      .doc(receiverId)
      .get();
    const userData = userSnap.data();

    if (!userData) return null;

    // Kumpulkan token (Support Single & Multiple)
    let tokens = [];
    if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
      tokens = userData.fcmTokens;
    } else if (userData.fcmToken) {
      tokens = [userData.fcmToken];
    }

    if (tokens.length === 0) {
      console.log("User tidak memiliki token FCM.");
      return null;
    }

    // 4. Siapkan Pesan Notifikasi (Format V1 API - Lebih Stabil)
    const message = {
      tokens: tokens,
      notification: {
        title: "Pesan Baru",
        body:
          messageData.type === "image"
            ? "📷 Mengirim gambar"
            : messageData.text,
      },
      // Konfigurasi Spesifik Android
      android: {
        priority: "high",
        ttl: 3600 * 1000, // (PENTING) Time To Live 1 jam. Membantu menembus mode Doze/Hemat Baterai.
        notification: {
          channelId: "chat_channel_id", // Channel ID wajib di sini
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          sound: "default",
          priority: "max", // (PENTING) Ubah ke 'max' agar muncul Popup (Heads-up) saat layar mati/app close
          defaultSound: true,
          defaultVibrateTimings: true,
          visibility: "public",
          icon: "ic_launcher", // (OPSIONAL) Memastikan icon muncul (menggunakan icon aplikasi)
        },
      },
      data: {
        roomId: roomId,
        type: "chat",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
    };

    return admin.messaging().sendEachForMulticast(message);
  }
);

// ==========================================
// AUTO-CANCEL STALE ORDERS (SCHEDULED)
// ==========================================
// Runs every 6 hours to check for orders waiting > 3 days

exports.autoCancelStaleOrders = onSchedule(
  {
    schedule: "every 6 hours",
    region: "asia-southeast2",
    timeZone: "Asia/Jakarta",
  },
  async (event) => {
    const db = admin.firestore();

    // Calculate 3 days ago
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);

    try {
      // Query orders that are still "Menunggu" and older than 3 days
      const staleOrdersSnapshot = await db
        .collection("orders")
        .where("status", "==", "Menunggu")
        .where(
          "createdAt",
          "<",
          admin.firestore.Timestamp.fromDate(threeDaysAgo)
        )
        .get();

      if (staleOrdersSnapshot.empty) {
        console.log("No stale orders found");
        return null;
      }

      console.log(`Found ${staleOrdersSnapshot.size} stale orders to cancel`);

      const batch = db.batch();
      const notifications = [];
      const stockUpdates = [];

      for (const doc of staleOrdersSnapshot.docs) {
        const orderData = doc.data();
        const orderId = doc.id;
        const buyerId = orderData.buyerId;
        const sellerId = orderData.sellerId;
        const items = orderData.items || [];
        const productName =
          items.length > 0 ? items[0].name || "Pesanan" : "Pesanan";

        // Update order status to cancelled
        batch.update(doc.ref, {
          status: "Dibatalkan",
          cancelReason:
            "Otomatis dibatalkan - Penjual tidak merespon dalam 3 hari",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Prepare stock restoration
        for (const item of items) {
          if (item.productId) {
            stockUpdates.push({
              productId: item.productId,
              qty: item.qty || 1,
            });
          }
        }

        // Prepare notifications
        notifications.push({
          recipientId: buyerId,
          title: "Pesanan Dibatalkan ⚠️",
          body: `Pesanan '${productName}' dibatalkan karena penjual tidak merespon dalam 3 hari.`,
          type: "order_cancelled",
          relatedId: orderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        notifications.push({
          recipientId: sellerId,
          title: "Pesanan Terlewat ⚠️",
          body: `Pesanan '${productName}' dibatalkan otomatis karena tidak diproses dalam 3 hari.`,
          type: "order_cancelled",
          relatedId: orderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      // Commit batch update for orders
      await batch.commit();

      // Restore stock for each product
      for (const update of stockUpdates) {
        await db
          .collection("products")
          .doc(update.productId)
          .update({
            stock: admin.firestore.FieldValue.increment(update.qty),
            sold: admin.firestore.FieldValue.increment(-update.qty),
          });
      }

      // Send notifications
      for (const notif of notifications) {
        await db.collection("notifications").add(notif);
      }

      console.log(
        `Successfully cancelled ${staleOrdersSnapshot.size} stale orders`
      );
      return null;
    } catch (error) {
      console.error("Error cancelling stale orders:", error);
      throw error;
    }
  }
);
