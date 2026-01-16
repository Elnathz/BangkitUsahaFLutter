import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk mengelola badge notifikasi dan chat secara global
class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BadgeService._internal();

  factory BadgeService() {
    return _instance;
  }

  /// Stream untuk notifikasi badge (ada unread notification?)
  Stream<bool> getNotificationBadgeStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  /// Stream untuk chat badge (ada unread message?)
  Stream<bool> getChatBadgeStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          // Check if any chat room has unread messages
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final int unreadCount = data['unread_count_$userId'] ?? 0;
            if (unreadCount > 0) {
              return true; // Ada unread message
            }
          }
          return false; // Semua sudah dibaca
        });
  }

  /// Stream gabungan notifikasi dan chat (untuk beranda)
  Future<bool> hasAnyBadge() async {
    final notif = await hasUnreadNotifications();
    final chat = await hasUnreadChats();
    return notif || chat;
  }

  /// Get notification badge status (one-time check)
  Future<bool> hasUnreadNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking notifications: $e");
      return false;
    }
  }

  /// Get chat badge status (one-time check)
  Future<bool> hasUnreadChats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('chat_rooms')
          .where('participants', arrayContains: userId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final int unreadCount = data['unread_count_$userId'] ?? 0;
        if (unreadCount > 0) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print("Error checking chats: $e");
      return false;
    }
  }
}
