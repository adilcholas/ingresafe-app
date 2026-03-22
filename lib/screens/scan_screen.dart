import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ingresafe/providers/scan_provider.dart';
import 'package:provider/provider.dart';
import '../utils/theme_constants.dart';

class ScanScreen extends StatelessWidget {
  ScanScreen({super.key});
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Product"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          /// Camera Preview Placeholder (Will integrate ML Kit later)
          Container(color: Colors.black),

          /// Scan Frame Overlay
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
            ),
          ),

          /// Instructions
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Align ingredients list inside the frame",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),

          /// Bottom Controls (Camera + Gallery)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                /// Capture Button
                GestureDetector(
                  onTap: () => _captureImage(context),
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// Gallery Upload
                TextButton.icon(
                  onPressed: () => _pickFromGallery(context),
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  label: const Text(
                    "Upload from Gallery",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await context.read<ScanProvider>().processImage(file);

      if (context.mounted) {
        context.go('/processing');
      }
    } else {
      if (context.mounted) {
        context.go('/error');
      }
    }
  }

  Future<void> _captureImage(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await context.read<ScanProvider>().processImage(file);

      if (context.mounted) {
        context.go('/processing');
      }
    } else {
      if (context.mounted) {
        context.go('/error');
      }
    }
  }
}
