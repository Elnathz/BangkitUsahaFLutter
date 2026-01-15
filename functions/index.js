const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// Konfigurasi global (Opsional: membatasi instance agar hemat biaya)
setGlobalOptions({ maxInstances: 10, region: "asia-southeast2" });

// Fungsi ini akan berjalan otomatis setiap ada pesan baru di chat_rooms
exports.sendChatNotification = onDocumentCreated("chat_rooms/{roomId}/messages/{messageId}", async (event) => {
    // Di Gen 2, data snapshot ada di event.data
    const snap = event.data;
    if (!snap) return;

    const messageData = snap.data();
    // Parameter path (roomId) ada di event.params
    const roomId = event.params.roomId;

    // 1. Ambil data Room untuk tahu siapa saja pesertanya
    const roomSnap = await admin.firestore().collection('chat_rooms').doc(roomId).get();
    if (!roomSnap.exists) return;

    const participants = roomSnap.data().participants;

    // 2. Cari siapa penerimanya (yang BUKAN pengirim pesan ini)
    const receiverId = participants.find(id => id !== messageData.senderId);
    if (!receiverId) return null;

    // 3. Ambil Token FCM milik penerima dari database users
    const userSnap = await admin.firestore().collection('users').doc(receiverId).get();
    const userData = userSnap.data();

    if (!userData || !userData.fcmToken) {
      console.log("User tidak memiliki token FCM.");
      return null;
    }

    // 4. Siapkan Pesan Notifikasi
    const payload = {
      notification: {
        title: 'Pesan Baru',
        body: messageData.type === 'image' ? '📷 Mengirim gambar' : messageData.text,
        click_action: 'FLUTTER_NOTIFICATION_CLICK', // Penting agar aplikasi terbuka saat diklik
      },
      data: {
        roomId: roomId,
        type: 'chat'
      }
    };

    // 5. Kirim Notifikasi ke HP Penerima
    return admin.messaging().sendToDevice(userData.fcmToken, payload);
  });
