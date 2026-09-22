import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gestion_piece_de_rechange/screens/loading_page.dart';
import 'package:gestion_piece_de_rechange/utils/app_utils.dart';
import 'package:gestion_piece_de_rechange/widgets/shared_widgets.dart';
import 'package:gestion_piece_de_rechange/widgets/custom_bottom_navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPage extends StatefulWidget {
  final String token;
  final String role;

  const ScanPage({required this.token, this.role = 'user', super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Camera access required'),
          content: const Text(
            'Please enable camera access in app settings to take a photo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        ),
      );
      return false;
    }
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<void> pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final granted = await _requestCameraPermission();
      if (!granted) return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      if (!await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read the selected image. Try again.'),
          ),
        );
        return;
      }
      // Debug: log selected file path and size
      try {
        final len = await file.length();
        debugPrint(
          'scan_page.pickImage: selected file path=$file.path, size=$len',
        );
      } catch (e) {
        debugPrint(
          'scan_page.pickImage: selected file path=$file.path, could not read length: $e',
        );
      }
      if (!mounted) return;
      setState(() {
        _selectedImageFile = file;
      });
      Navigator.push(
        context,
        createRoute(
          LoadingPage(image: file, token: widget.token, role: widget.role),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      final message = e.message ?? 'Unable to access the camera or gallery.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: STBG.surface,
      body: Stack(
        children: [
          Column(
            children: [
              const STBGHeader(
                title: 'Scan a Part',
                subtitle: 'Identify a spare part using your camera or gallery',
                showBack: true,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      if (_selectedImageFile != null)
                        Center(
                          child: SizedBox(
                            width: 240,
                            height: 160,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImageFile!,
                                fit: BoxFit.cover,
                                width: 240,
                                height: 160,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                STBG.steel.withAlpha((0.15 * 255).round()),
                                STBG.steel.withAlpha((0.03 * 255).round()),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: STBG.steel.withAlpha((0.2 * 255).round()),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.document_scanner_rounded,
                            size: 58,
                            color: STBG.steel.withAlpha((0.7 * 255).round()),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ScanOption(
                        icon: Icons.camera_alt_rounded,
                        title: 'Take a Photo',
                        subtitle: 'Use your camera to capture the part',
                        onTap: () => pickImage(ImageSource.camera),
                      ),
                      const SizedBox(height: 14),
                      ScanOption(
                        icon: Icons.photo_library_rounded,
                        title: 'Choose from Gallery',
                        subtitle: 'Select an existing photo',
                        onTap: () => pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigationBar(
              currentIndex: 1,
              token: widget.token,
              role: widget.role,
            ),
          ),
        ],
      ),
    );
  }
}
