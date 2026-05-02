import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/di/injection.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';
import 'package:bitwise_academy/core/widgets/pixel_input.dart';
import 'package:bitwise_academy/features/store/data/repositories/store_repository.dart';

class AdminUploadSkinPage extends StatefulWidget {
  const AdminUploadSkinPage({super.key});

  @override
  State<AdminUploadSkinPage> createState() => _AdminUploadSkinPageState();
}

class _AdminUploadSkinPageState extends State<AdminUploadSkinPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  File? _selectedImage;
  bool _isUploading = false;

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadSkin() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image file first.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final priceStr = _priceController.text.trim();

    if (name.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name and price.')),
      );
      return;
    }

    final price = int.tryParse(priceStr);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a positive integer.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final storeRepo = getIt<StoreRepository>();
    final result = await storeRepo.uploadSkin(
      imageFile: _selectedImage!,
      name: name,
      price: price,
    );

    if (mounted) {
      setState(() => _isUploading = false);

      switch (result) {
        case Success():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Skin uploaded successfully!')),
          );
          context.go('/admin'); // Return to admin dashboard
        case Failure(:final exception):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload: ${exception.message}')),
          );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => context.go('/admin'),
        ),
        title: Text(
          'UPLOAD PIXEL SKIN',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker UI
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: _selectedImage != null
                    ? Image.file(
                        _selectedImage!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none, // Good for pixel art
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'TAP TO SELECT FILE',
                            style: AppTypography.labelLg.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Form Inputs
            PixelInput(
              label: 'SKIN NAME',
              hintText: 'E.G. NEON KNIGHT',
              controller: _nameController,
            ),
            const SizedBox(height: AppSpacing.lg),
            PixelInput(
              label: 'PRICE (COINS)',
              hintText: '500',
              keyboardType: TextInputType.number,
              controller: _priceController,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Submit Button
            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            else
              PixelButton(
                label: 'DEPLOY TO STORE',
                icon: Icons.cloud_upload,
                width: double.infinity,
                onPressed: _uploadSkin,
              ),
          ],
        ),
      ),
    );
  }
}
