import 'dart:io';
import 'package:flutter/material.dart';

class AvatarBox extends StatelessWidget {
  final File? avatar;

  const AvatarBox({super.key, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF2F2F2),
      ),
      child: avatar == null
          ? const Icon(Icons.person, size: 36, color: Colors.grey)
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(avatar!, fit: BoxFit.cover),
            ),
    );
  }
}
