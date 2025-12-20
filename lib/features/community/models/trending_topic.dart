import 'package:flutter/material.dart';

class TrendingTopic {
  final String id;
  final String title;
  final int posts;
  final IconData icon;

  TrendingTopic({
    required this.id,
    required this.title,
    required this.posts,
    required this.icon,
  });
}