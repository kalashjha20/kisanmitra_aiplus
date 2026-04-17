import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../features/scan/scan_screen.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  Future<void> _openCamera(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (picked == null) return;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          imageFile: File(picked.path),
        ),
      ),
    );
  }

  Future<void> _openGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked == null) return;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          imageFile: File(picked.path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText:
                "Search crop diseases, fertilizers...",
                border: InputBorder.none,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.camera_alt,
              color: Colors.green,
            ),
            onPressed: () => _openCamera(context),
          ),

          IconButton(
            icon: const Icon(
              Icons.upload,
              color: Colors.green,
            ),
            onPressed: () => _openGallery(context),
          ),
        ],
      ),
    );
  }
}
