import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class AvatarPicker extends StatefulWidget {
  final Function(File? file, Uint8List? bytes) onChanged;

  const AvatarPicker({super.key, required this.onChanged});

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? fileImage; // dùng cho mobile
  Uint8List? webImageBytes; // dùng cho web

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    // Tự động crop 1:1 (center crop)
    final croppedBytes = await _cropToSquare(bytes);

    if (kIsWeb) {
      webImageBytes = croppedBytes;
      fileImage = null;
      widget.onChanged(null, webImageBytes);
      setState(() {});
    } else {
      // Mobile: lưu vào file tạm
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(croppedBytes);

      fileImage = tempFile;
      webImageBytes = null;
      widget.onChanged(fileImage, null);
      setState(() {});
    }
  }

  Future<Uint8List> _cropToSquare(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;

    final size = image.width < image.height ? image.width : image.height;
    final offsetX = (image.width - size) ~/ 2;
    final offsetY = (image.height - size) ~/ 2;

    final cropped = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
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
