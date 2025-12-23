import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrendingTopic {
  final String id;
  final String title; // Ini adalah hashtagnya, misal: #Bisnis
  final int posts;    // Jumlah post
  final IconData icon;

  TrendingTopic({
    required this.id,
    required this.title,
    required this.posts,
    this.icon = LucideIcons.hash, // Default icon hash
  });

  factory TrendingTopic.fromFirestore(Map<String, dynamic> data, String id) {
    return TrendingTopic(
      id: id,
      title: data['tag'] ?? '#Topik',
      posts: data['count'] ?? 0,
    );
  }
}