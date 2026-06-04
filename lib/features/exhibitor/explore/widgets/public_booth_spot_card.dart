import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/booth_spot_model.dart';
import '../../../../providers/booth_package_provider.dart';

class PublicBoothSpotCard extends StatelessWidget {
  final BoothSpotModel spot;
  final bool isSelected;
  final VoidCallback? onTap;

  const PublicBoothSpotCard({
    super.key,
    required this.spot,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothPackageProvider>();
    final package = boothProvider.boothPackages
        .where((p) => p.id == spot.boothPackageId)
        .firstOrNull;

    final bool isUnassigned = spot.boothPackageId.isEmpty;
    final bool isAvailable = spot.status == 'Available' && !isUnassigned;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isUnassigned ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? Colors.blue.shade600 
                  : (isAvailable ? Colors.grey.shade200 : Colors.grey.shade100),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spot.spotNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 20,
                  color: isAvailable ? AppColors.primaryText : AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(
                label: isUnassigned ? 'Unavailable' : spot.status,
                color: isUnassigned ? Colors.grey : _getStatusColor(spot.status),
              ),
              const SizedBox(height: 8),
              Text(
                package?.name ?? 'Unassigned',
                style: TextStyle(
                  fontSize: 12, 
                  color: isAvailable ? AppColors.secondaryText : Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (package != null)
                Text(
                  'RM ${package.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? AppColors.primaryAccent : Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Booked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
