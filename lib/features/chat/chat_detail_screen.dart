import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart'; // Wajib import ini
import 'package:chewie/chewie.dart'; // Wajib import ini

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
    _markAsRead();
  }

  void _setChatRoomId() {
    List<String> ids = [currentUser!.uid, widget.targetUid];
    ids.sort();
    _chatRoomId = ids.join("_");
  }

  Future<void> _markAsRead() async {
    if (_chatRoomId != null && currentUser != null) {
      try {
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(_chatRoomId)
            .update({'unread_count_${currentUser!.uid}': 0});
      } catch (e) {
        // Silent error
      }
    }
  }

  // --- PICK IMAGE ---
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
          type: 'image', // Pastikan tipe diset image
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

  // --- PICK VIDEO (FITUR BARU) ---
  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 1), // Batas durasi video
      );

      if (pickedFile != null) {
        setState(() => _isSending = true);

        // Asumsi: ChatService Anda sudah diupdate untuk handle videoFile
        // Jika belum, nanti di langkah selanjutnya kita update ChatService
        await _chatService.sendMessage(
          chatRoomId: _chatRoomId!,
          senderId: currentUser!.uid,
          receiverId: widget.targetUid,
          text: "",
          imageFile: pickedFile, // Menggunakan param yang sama (file)
          type: 'video', // Tipe video
        );

        setState(() => _isSending = false);
      }
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal kirim video: $e")));
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String msg = _messageController.text.trim();
    _messageController.clear();

    await _chatService.sendMessage(
      chatRoomId: _chatRoomId!,
      senderId: currentUser!.uid,
      receiverId: widget.targetUid,
      text: msg,
      type: 'text',
    );
  }

  // --- MENU OPSI PESAN ---
  void _showMessageOptions(
    String docId,
    String currentText,
    String type,
    bool isMe,
  ) {
    if (!isMe) return; // Hanya bisa edit pesan sendiri

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (type == 'text')
                ListTile(
                  leading: const Icon(LucideIcons.edit3, color: Colors.blue),
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
                  _confirmDelete(docId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Pesan?"),
        content: const Text("Pesan akan dihapus untuk semua orang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _chatService.deleteMessage(_chatRoomId!, docId);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String docId, String oldText) {
    final editCtrl = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Pesan"),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
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

  // --- LOGIC ZOOM GAMBAR ---
  void _openFullImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  (widget.targetImage.isNotEmpty &&
                      widget.targetImage != 'https://via.placeholder.com/150')
                  ? NetworkImage(widget.targetImage)
                  : null,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      "Mulai percakapan dengan ${widget.targetName}",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 20,
                  ),
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

          if (_isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // INPUT FIELD
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.image, color: Colors.grey),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    tooltip: "Kirim Foto",
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.video, color: Colors.grey),
                    onPressed: _pickVideo, // Panggil fungsi Video
                    tooltip: "Kirim Video",
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.camera, color: Colors.grey),
                    onPressed: () => _pickImage(ImageSource.camera),
                    tooltip: "Ambil Foto",
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Tulis pesan...",
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: primaryColor,
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
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(String docId, Map<String, dynamic> data, bool isMe) {
    String type = data['type'] ?? 'text';
    String content =
        data['text'] ?? ''; // Bisa URL gambar/video atau teks biasa
    bool isEdited = data['isEdited'] ?? false;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar Lawan
            if (!isMe) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                backgroundImage: (widget.targetImage.isNotEmpty)
                    ? NetworkImage(widget.targetImage)
                    : null,
                child: (widget.targetImage.isEmpty)
                    ? const Icon(LucideIcons.user, size: 14, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
            ],

            // BUBBLE PESAN
            Flexible(
              child: GestureDetector(
                onLongPress: () =>
                    _showMessageOptions(docId, content, type, isMe),
                onTap: type == 'image' ? () => _openFullImage(content) : null,
                child: Container(
                  padding: type == 'text'
                      ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
                      : const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.orange : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isMe
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // KONTEN BERDASARKAN TIPE
                      if (type == 'image')
                        Hero(
                          tag: content, // Tag unik untuk animasi
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: content,
                              width: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 200,
                                height: 200,
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        )
                      else if (type == 'video')
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: VideoMessagePlayer(
                              videoUrl: content,
                            ), // Widget Khusus
                          ),
                        )
                      else
                        Text(
                          content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),

                      // Label "Edited"
                      if (isEdited && type == 'text')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            LucideIcons.pencil,
                            size: 10,
                            color: isMe ? Colors.white70 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET PLAYER VIDEO KECIL DI CHAT ---
class VideoMessagePlayer extends StatefulWidget {
  final String videoUrl;
  const VideoMessagePlayer({super.key, required this.videoUrl});

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      showControls: true, // Tampilkan tombol play/pause
      placeholder: Container(color: Colors.black),
      autoInitialize: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text("Video Error", style: TextStyle(color: Colors.white)),
        );
      },
    );

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return Chewie(controller: _chewieController!);
  }
}
