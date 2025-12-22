import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String targetUid;
  final String targetName;
  final String targetImage;

  const ChatDetailScreen({
    super.key,
    required this.targetUid,
    required this.targetName,
    required this.targetImage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  String? _chatRoomId;
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _setChatRoomId();
    _markAsRead(); // Reset angka unread saat dibuka
  }

  void _setChatRoomId() {
    List<String> ids = [currentUser!.uid, widget.targetUid];
    ids.sort();
    _chatRoomId = ids.join("_");
  }

  // --- FUNGSI TANDAI SUDAH DIBACA ---
  Future<void> _markAsRead() async {
    if (_chatRoomId != null && currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(_chatRoomId)
            .update({
              // Reset angka unread milik SAYA menjadi 0
              'unread_count_${currentUser!.uid}': 0,
            });
      } catch (e) {
        // print("Gagal update status baca: $e");
      }
    }
  }

  // --- FUNGSI AMBIL GAMBAR ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() => _isSending = true);

        await _chatService.sendMessage(
          chatRoomId: _chatRoomId!,
          senderId: currentUser!.uid,
          receiverId: widget.targetUid,
          text: "",
          imageFile: pickedFile,
        );

        setState(() => _isSending = false);
      }
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal kirim gambar: $e")));
    }
  }

  // --- FUNGSI KIRIM TEXT ---
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String msg = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      chatRoomId: _chatRoomId!,
      senderId: currentUser!.uid,
      receiverId: widget.targetUid,
      text: msg,
    );
  }

  // --- MENU EDIT & HAPUS ---
  void _showMessageOptions(
    String docId,
    String currentText,
    String type,
    bool isMe,
  ) {
    if (!isMe) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (type == 'text')
                ListTile(
                  leading: const Icon(LucideIcons.edit),
                  title: const Text('Edit Pesan'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(docId, currentText);
                  },
                ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text(
                  'Hapus Pesan',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _chatService.deleteMessage(_chatRoomId!, docId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOG EDIT ---
  void _showEditDialog(String docId, String oldText) {
    final editCtrl = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Pesan"),
        content: TextField(controller: editCtrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (editCtrl.text.trim().isNotEmpty) {
                _chatService.editMessage(
                  _chatRoomId!,
                  docId,
                  editCtrl.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0, // Rapatkan jarak
        title: Row(
          children: [
            // FOTO PROFIL HEADER (UPDATED)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              // Logic: Tampilkan gambar jika ada & bukan placeholder
              backgroundImage:
                  (widget.targetImage.isNotEmpty &&
                      widget.targetImage != 'https://via.placeholder.com/150')
                  ? NetworkImage(widget.targetImage)
                  : null,
              // Logic: Tampilkan Icon jika gambar kosong/placeholder
              child:
                  (widget.targetImage.isEmpty ||
                      widget.targetImage == 'https://via.placeholder.com/150')
                  ? const Icon(LucideIcons.user, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.targetName,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // LIST PESAN
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    String docId = messages[index].id;
                    bool isMe = data['senderId'] == currentUser!.uid;

                    return _buildMessageItem(docId, data, isMe);
                  },
                );
              },
            ),
          ),

          // LOADING UPLOAD
          if (_isSending)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),

          // INPUT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.image, color: Colors.grey),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.camera, color: Colors.grey),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUBBLE PESAN (UPDATED: FOTO PROFIL KIRI) ---
  Widget _buildMessageItem(String docId, Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    String text = data['text'] ?? '';
    bool isEdited = data['isEdited'] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 1. FOTO PROFIL LAWAN (Kiri) - Hanya muncul kalau bukan saya
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  (widget.targetImage.isNotEmpty &&
                      widget.targetImage != 'https://via.placeholder.com/150')
                  ? NetworkImage(widget.targetImage)
                  : null,
              child:
                  (widget.targetImage.isEmpty ||
                      widget.targetImage == 'https://via.placeholder.com/150')
                  ? const Icon(LucideIcons.user, size: 14, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // 2. ISI PESAN (Bubble)
          GestureDetector(
            onLongPress: () => _showMessageOptions(docId, text, type, isMe),
            child: Container(
              padding: type == 'image'
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isMe ? Colors.orange : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                ),
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (type == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: text,
                        placeholder: (context, url) => const SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      ),
                    )
                  else
                    Text(
                      text,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),

                  // Label "Edited"
                  if (isEdited && type == 'text')
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "diedit",
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
