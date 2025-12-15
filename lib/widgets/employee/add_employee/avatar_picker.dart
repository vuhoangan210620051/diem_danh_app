import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AvatarPicker extends StatefulWidget {
  final Function(File? file, Uint8List? bytes) onChanged;

  const AvatarPicker({super.key, required this.onChanged});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? fileImage;           // dùng cho mobile
  Uint8List? webImageBytes;  // dùng cho web

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    if (kIsWeb) {
      // ----- WEB: đọc bytes -----
      webImageBytes = await picked.readAsBytes();
      fileImage = null;
      widget.onChanged(null, webImageBytes);
    } else {
      // ----- MOBILE: dùng File -----
      fileImage = File(picked.path);
      webImageBytes = null;
      widget.onChanged(fileImage, null);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFF2F2F2),
        ),
        child: _buildAvatar(),
      ),
    );
  }

  Widget _buildAvatar() {
    if (kIsWeb && webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(webImageBytes!, fit: BoxFit.cover),
      );
    }

    if (!kIsWeb && fileImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(fileImage!, fit: BoxFit.cover),
      );
    }

    return const Icon(Icons.add_a_photo, size: 32, color: Colors.grey);
  }
}
