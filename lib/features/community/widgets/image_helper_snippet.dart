import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

Widget _buildImagePreview(dynamic imageFile) {
  if (imageFile == null) return const SizedBox.shrink();

  if (kIsWeb) {
    if (imageFile.path == null || imageFile.path.isEmpty) {
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (ctx, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      );
    }
    return Image.network(
      imageFile.path,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  return Image.file(
    File(imageFile.path),
    fit: BoxFit.cover,
    width: double.infinity,
  );
}
