import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../data/services/exhibition_service.dart';
import '../../../../core/utils/feedback_helper.dart';

class ManageExhibitionImagesBottomSheet extends StatefulWidget {
  final ExhibitionModel exhibition;

  const ManageExhibitionImagesBottomSheet({super.key, required this.exhibition});

  @override
  State<ManageExhibitionImagesBottomSheet> createState() =>
      _ManageExhibitionImagesBottomSheetState();
}

class _ManageExhibitionImagesBottomSheetState
    extends State<ManageExhibitionImagesBottomSheet> {
  final List<String> _existingUrls = [];
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  final ExhibitionService _service = ExhibitionService();
  bool _isUploading = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _existingUrls.addAll(widget.exhibition.imageUrls);
  }

  int get _totalCount => _existingUrls.length + _newImages.length;

  Future<void> _pickImages() async {
    setState(() {
      _formError = null;
    });

    if (_totalCount >= 4) {
      setState(() {
        _formError = 'You can upload up to 4 images only.';
      });
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_existingUrls.length + _newImages.length < 4) {
              _newImages.add(file);
            } else {
              _formError = 'You can upload up to 4 images only.';
              break;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingUrls.removeAt(index);
      _formError = null;
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _formError = null;
    });
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
      _isUploading = true;
    });

    final provider = context.read<ExhibitionProvider>();

    try {
      // 1. Upload new images to Storage if any
      List<String> uploadedUrls = [];
      if (_newImages.isNotEmpty) {
        uploadedUrls = await _service.uploadExhibitionImages(
          exhibitionId: widget.exhibition.id,
          images: _newImages,
        );
      }

      // 2. Combine remaining existing URLs with new URLs
      final finalUrls = [..._existingUrls, ...uploadedUrls];

      // 3. Update exhibition document
      final updatedExhibition = widget.exhibition.copyWith(imageUrls: finalUrls);
      final success = await provider.updateExhibition(updatedExhibition);

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          Navigator.pop(context);
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Images updated successfully',
            );
          }
        } else {
          setState(() {
            _formError = 'Failed to update images. Please try again.';
          });
        }
      }
    } catch (e) {
      debugPrint('Error saving images: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _formError = 'Error updating images. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = _isUploading || context.watch<ExhibitionProvider>().isLoading;

    return AppBottomSheetScaffold(
      title: 'Manage Images',
      primaryLabel: 'Save Changes',
      isLoading: isLoading,
      onPrimaryPressed: _handleSave,
      isScrollable: true,
      maxHeightFactor: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formError!,
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          const Text(
            'Exhibition Gallery (Max 4)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Changes will apply once you click Save Changes.',
            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
          ),
          const SizedBox(height: AppSpacing.m),
          
          if (_totalCount == 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: AppSpacing.s),
                  Text('No images uploaded', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.s,
                mainAxisSpacing: AppSpacing.s,
                childAspectRatio: 1.2,
              ),
              itemCount: _totalCount,
              itemBuilder: (context, index) {
                if (index < _existingUrls.length) {
                  // Existing image from network
                  final url = _existingUrls[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Uploaded',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Newly picked image
                  final newIndex = index - _existingUrls.length;
                  final file = _newImages[newIndex];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                                  file.path,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(file.path),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeNewImage(newIndex),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
          
          const SizedBox(height: AppSpacing.m),
          if (_totalCount < 4)
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryAccent,
                side: const BorderSide(color: AppColors.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.l),
        ],
      ),
    );
  }
}
