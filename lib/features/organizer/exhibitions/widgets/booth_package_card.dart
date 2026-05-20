import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/booth_model.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../core/widgets/base_dialog.dart';
import 'booth_package_bottom_sheet.dart';
import '../../../../core/utils/feedback_helper.dart';

class BoothPackageCard extends StatelessWidget {
  final BoothModel package;
  final String exhibitionId;

  const BoothPackageCard({
    super.key,
    required this.package,
    required this.exhibitionId,
  });

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BoothPackageBottomSheet(
        exhibitionId: exhibitionId,
        package: package,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Package updated successfully.',
        );
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    // 1. Check if package is used by any booth spot
    final spotProvider = context.read<BoothSpotProvider>();
    final isUsed = spotProvider.boothSpots.any((s) => s.boothPackageId == package.id);

    if (isUsed) {
      FeedbackHelper.showWarning(
        context,
        'This package is used by existing booth spots. Delete or reassign those spots first.',
      );
      return;
    }

    // 2. If not used, show confirmation dialog
    BaseDialog.show(
      context: context,
      title: 'Delete Package?',
      message: 'This booth package "${package.name}" will be permanently removed.',
      variant: DialogVariant.destructive,
      primaryLabel: 'Delete',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        final provider = context.read<BoothProvider>();
        final success = await provider.deleteBoothPackage(package.id, exhibitionId);
        if (context.mounted) {
          if (success) {
            FeedbackHelper.showSuccess(
              context,
              'Package deleted successfully',
            );
          } else {
            FeedbackHelper.showError(
              context,
              'Failed to delete package',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        package.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.primaryAccent.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'RM ${package.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.aspect_ratio_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      package.size,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (package.amenities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: package.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          a,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showEditSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primaryText.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Package',
                            style: TextStyle(
                              color: AppColors.primaryText.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _confirmDelete(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.primaryAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
