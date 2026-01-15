import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareBottomSheet extends StatelessWidget {
  final String postUrl; // Mock URL or content to share

  const ShareBottomSheet({super.key, required this.postUrl});

  Future<void> _shareToWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent("Lihat postingan ini dari UMKM Community:\n$postUrl");
    final whatsappUrl = Uri.parse("https://wa.me/?text=$text");
    
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text("WhatsApp tidak terinstall"),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _shareToInstagram(BuildContext context) async {
    // Instagram doesn't have direct URL sharing for DMs
    // We'll open Instagram app or show a message
    final instagramUrl = Uri.parse("instagram://user?username=");
    
    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
      // Copy link to clipboard for manual sharing
      await Clipboard.setData(ClipboardData(text: postUrl));
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text("Link disalin! Bagikan ke Instagram Story atau DM"),
          type: ToastificationType.success,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } else {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text("Instagram tidak terinstall"),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _shareToTelegram(BuildContext context) async {
    final text = Uri.encodeComponent("Lihat postingan ini:\n$postUrl");
    final telegramUrl = Uri.parse("https://t.me/share/url?url=$postUrl&text=$text");
    
    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: const Text("Telegram tidak terinstall"),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: postUrl));
    if (context.mounted) {
      Navigator.pop(context);
      toastification.show(
        context: context,
        title: const Text("Tautan disalin ke clipboard"),
        type: ToastificationType.success,
        autoCloseDuration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Text(
              "Bagikan Postingan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Share Options Grid
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildShareItem(
                  context,
                  label: "Salin Tautan",
                  icon: LucideIcons.link,
                  color: Colors.grey[700]!,
                  bgColor: Colors.grey[200]!,
                  onTap: () => _copyLink(context),
                ),
                _buildShareItem(
                  context,
                  label: "WhatsApp",
                  icon: LucideIcons.messageCircle,
                  color: Colors.white,
                  bgColor: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToWhatsApp(context);
                  },
                ),
                _buildShareItem(
                  context,
                  label: "Instagram",
                  icon: LucideIcons.instagram,
                  color: Colors.white,
                  bgColor: const Color(0xFFE1306C),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToInstagram(context);
                  },
                ),
                _buildShareItem(
                  context,
                  label: "Telegram",
                  icon: LucideIcons.send,
                  color: Colors.white,
                  bgColor: const Color(0xFF0088CC),
                  onTap: () {
                    Navigator.pop(context);
                    _shareToTelegram(context);
                  },
                ),
                _buildShareItem(
                  context,
                  label: "Kirim ke Teman",
                  icon: LucideIcons.users,
                  color: Colors.white,
                  bgColor: const Color(0xFF1976D2),
                  onTap: () {
                    Navigator.pop(context);
                    toastification.show(
                      context: context,
                      title: const Text("Dikirim ke daftar teman!"),
                      type: ToastificationType.success,
                      autoCloseDuration: const Duration(seconds: 2),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildShareItem(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

