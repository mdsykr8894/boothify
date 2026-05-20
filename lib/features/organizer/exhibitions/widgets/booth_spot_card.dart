import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/booth_spot_model.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../core/widgets/base_dialog.dart';
import 'booth_spot_bottom_sheet.dart';
import '../../../../core/utils/feedback_helper.dart';

class BoothSpotCard extends StatelessWidget {
  final BoothSpotModel spot;
  final String exhibitionId;
  final bool compact;

  const BoothSpotCard({
    super.key,
    required this.spot,
    required this.exhibitionId,
    this.compact = false,
  });

  int getRowIndex(String spotNumber) {
    if (spotNumber.isEmpty) return 0;
    final firstChar = spotNumber[0].toUpperCase();
    if (firstChar.codeUnitAt(0) >= 'A'.codeUnitAt(0) && firstChar.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) {
      return firstChar.codeUnitAt(0) - 'A'.codeUnitAt(0);
    }
    return 0;
  }

  int getColIndex(String spotNumber) {
    if (spotNumber.length < 2) return 0;
    final digits = spotNumber.substring(1);
    final val = int.tryParse(digits);
    if (val != null) {
      return val - 1; // 0-indexed
    }
    return 0;
  }

  void _showEditSheet(BuildContext context) {
    final spots = context.read<BoothSpotProvider>().boothSpots;
    final exhibitionProvider = context.read<ExhibitionProvider>();
    
    final exhibition = exhibitionProvider.organizerExhibitions.firstWhere(
      (e) => e.id == exhibitionId,
    );

    int maxRow = 0;
    int maxCol = 0;
    for (final s in spots) {
      final r = getRowIndex(s.spotNumber);
      final c = getColIndex(s.spotNumber);
      if (r > maxRow) maxRow = r;
      if (c > maxCol) maxCol = c;
    }

    final rowsCount = exhibition.layoutRows ?? (spots.isEmpty ? 0 : maxRow + 1);
    final columnsCount = exhibition.layoutColumns ?? (spots.isEmpty ? 0 : maxCol + 1);

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BoothSpotBottomSheet(
        exhibitionId: exhibitionId,
        spot: spot,
        rows: rowsCount,
        columns: columnsCount,
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Spot updated successfully.',
        );
      }
    });
  }

  void _confirmDelete(BuildContext context) {
    BaseDialog.show(
      context: context,
      title: 'Delete Booth Spot?',
      message: 'This booth spot "${spot.spotNumber}" will be permanently removed from the floor plan.',
      variant: DialogVariant.destructive,
      primaryLabel: 'Delete',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () async {
        Navigator.pop(context);
        final provider = context.read<BoothSpotProvider>();
        final success = await provider.deleteBoothSpot(spot.id, exhibitionId);
        if (context.mounted) {
          if (success) {
            FeedbackHelper.showSuccess(
              context,
              'Spot deleted successfully',
            );
          } else {
            FeedbackHelper.showError(
              context,
              'Failed to delete spot',
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothProvider>();
    final packageName = spot.boothPackageId.isEmpty
        ? 'Unassigned'
        : (boothProvider.boothPackages
            .where((p) => p.id == spot.boothPackageId)
            .firstOrNull
            ?.name ?? 'Unknown Package');

    final bool isAvailable = spot.status == 'Available';

    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(
          color: isAvailable ? Colors.grey.shade200 : Colors.grey.shade100,
          width: compact ? 1.2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: compact 
                  ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
                  : const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Spot number
                  Text(
                    spot.spotNumber,
                    style: TextStyle(
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 2. Status Badge Pill
                  Container(
                    padding: compact 
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(spot.status),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _getStatusBorderColor(spot.status),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      spot.status,
                      style: TextStyle(
                        color: _getStatusTextColor(spot.status),
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  // 3. Package Name as Metadata (Icon + Text)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: compact ? 12 : 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          packageName,
                          style: TextStyle(
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          // 4. Compact footer action buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showEditSheet(context),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(compact ? 16 : 20),
                  ),
                  child: Container(
                    height: compact ? 34 : 38,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: compact ? 12 : 13,
                          color: AppColors.primaryText.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.primaryText.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: compact ? 16 : 18,
                width: 1,
                color: Colors.grey.shade200,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _confirmDelete(context),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(compact ? 16 : 20),
                  ),
                  child: Container(
                    height: compact ? 34 : 38,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: compact ? 12 : 13,
                          color: AppColors.primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF2E7D32);
      case 'Pending':
        return const Color(0xFFEF6C00);
      case 'Booked':
        return const Color(0xFFC62828);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFFE8F5E9);
      case 'Pending':
        return const Color(0xFFFFF3E0);
      case 'Booked':
        return const Color(0xFFFFEBEE);
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFFA5D6A7);
      case 'Pending':
        return const Color(0xFFFFE082);
      case 'Booked':
        return const Color(0xFFEF9A9A);
      default:
        return Colors.grey.shade200;
    }
  }
}
