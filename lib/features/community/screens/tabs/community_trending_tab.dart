import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/trending_topic.dart';
import '../community_topic_detail_page.dart';

class CommunityTrendingTab extends StatelessWidget {
  // Data Statis untuk Trending
  final List<TrendingTopic> trendingTopics = [
    TrendingTopic(
      id: '1',
      title: 'Strategi Marketing 2024',
      posts: 1250,
      icon: LucideIcons.trendingUp,
    ),
    TrendingTopic(
      id: '2',
      title: 'Ide Bisnis Modal Kecil',
      posts: 856,
      icon: LucideIcons.lightbulb,
    ),
    TrendingTopic(
      id: '3',
      title: 'Digitalisasi UMKM',
      posts: 645,
      icon: LucideIcons.smartphone,
    ),
    TrendingTopic(
      id: '4',
      title: 'Perizinan Usaha & Legalitas',
      posts: 420,
      icon: LucideIcons.fileText,
    ),
  ];

  CommunityTrendingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🔥 Topik Trending',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...trendingTopics.map((topic) => Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(topic.icon, color: Colors.deepOrange),
            ),
            title: Text(
              topic.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${topic.posts} diskusi'),
            trailing: const Icon(LucideIcons.chevronRight, size: 20),
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => CommunityTopicDetailPage(topic: topic),
                ),
              );
            },
          ),
        )),
      ],
    );
  }
}