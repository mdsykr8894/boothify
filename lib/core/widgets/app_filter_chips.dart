import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

// Reusable horizontal filter chips.
class AppFilterChips extends StatelessWidget {
  final String selectedValue;
  final List<String> filters;
  final List<String> moreFilters;
  final ValueChanged<String> onChanged;

  const AppFilterChips({
    super.key,
    required this.selectedValue,
    required this.filters,
    this.moreFilters = const [],
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> displayItems;
    final List<String> overflowItems;

    // Split visible filters and overflow filters.
    if (moreFilters.isNotEmpty) {
      displayItems = filters;
      overflowItems = moreFilters;
    } else {
      final List<String> all = [...filters];
      if (all.length <= 4) {
        displayItems = all;
        overflowItems = [];
      } else {
        displayItems = all.sublist(0, 3);
        overflowItems = all.sublist(3);
      }
    }

    final bool isSelectedInMore = overflowItems.contains(selectedValue);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double basePadding = 14.0;
        const double maxPadding = 20.0;
        double dynamicPadding = basePadding;

        final int chipCount =
            displayItems.length + (overflowItems.isNotEmpty ? 1 : 0);

        // Adjust chip padding when there is extra space.
        if (chipCount >= 4) {
          final double availableWidth =
              constraints.maxWidth - (AppSpacing.screenHorizontal * 2);

          double totalEstimatedWidth = 0.0;
          for (final filter in displayItems) {
            final double textWidth = filter.length * 8.0;
            final double baseChipWidth = textWidth + (2 * basePadding);
            final double finalChipWidth = filter == 'All'
                ? baseChipWidth.clamp(72.0, double.infinity)
                : baseChipWidth;
            totalEstimatedWidth += finalChipWidth;
          }

          if (overflowItems.isNotEmpty) {
            final double textWidth = 4 * 8.0;
            final double extraDecorations =
                18.0 + 4.0 + (isSelectedInMore ? 12.0 : 0.0);
            final double moreChipWidth =
                textWidth + extraDecorations + (2 * basePadding);
            totalEstimatedWidth += moreChipWidth;
          }

          totalEstimatedWidth += (chipCount - 1) * 8.0;

          if (totalEstimatedWidth < availableWidth) {
            final double remainingSpace = availableWidth - totalEstimatedWidth;
            final double extraPadding = remainingSpace / (2 * chipCount);
            dynamicPadding =
                (basePadding + extraPadding).clamp(basePadding, maxPadding);
          }
        }

        final List<Widget> chips = [];
        for (int i = 0; i < displayItems.length; i++) {
          final filter = displayItems[i];
          final bool isSelected = filter == selectedValue;
          chips.add(
            _buildChip(
              label: filter,
              isSelected: isSelected,
              onTap: () => onChanged(filter),
              horizontalPadding: dynamicPadding,
            ),
          );
        }

        // Add more filter menu when needed.
        if (overflowItems.isNotEmpty) {
          chips.add(
            _buildMoreChip(
              isSelected: isSelectedInMore,
              overflowItems: overflowItems,
              onSelected: (val) => onChanged(val),
              horizontalPadding: dynamicPadding,
            ),
          );
        }

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            itemCount: chips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return chips[index];
            },
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double horizontalPadding,
  }) {
    final bool isAll = label == 'All';
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final FontWeight fontWeight;

    // Apply selected chip styling.
    if (isSelected) {
      if (isAll) {
        backgroundColor = AppColors.primaryText;
        borderColor = AppColors.primaryText;
        textColor = Colors.white;
      } else {
        backgroundColor = AppColors.primaryAccent.withValues(alpha: 0.08);
        borderColor = AppColors.primaryAccent;
        textColor = AppColors.primaryAccent;
      }
      fontWeight = FontWeight.w600;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      fontWeight = FontWeight.w500;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        constraints: isAll ? const BoxConstraints(minWidth: 72) : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreChip({
    required bool isSelected,
    required List<String> overflowItems,
    required Function(String) onSelected,
    required double horizontalPadding,
  }) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;
    final Color dotColor;
    final FontWeight fontWeight;

    // Apply selected more chip styling.
    if (isSelected) {
      backgroundColor = AppColors.primaryAccent.withValues(alpha: 0.08);
      borderColor = AppColors.primaryAccent;
      textColor = AppColors.primaryAccent;
      iconColor = AppColors.primaryAccent;
      dotColor = AppColors.primaryAccent;
      fontWeight = FontWeight.w600;
    } else {
      backgroundColor = Colors.white;
      borderColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
      iconColor = Colors.grey.shade600;
      dotColor = Colors.grey.shade600;
      fontWeight = FontWeight.w500;
    }

    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 50),
      elevation: 4,
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.l),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      itemBuilder: (context) {
        return overflowItems.map((filter) {
          final bool isItemFilterSelected = filter == selectedValue;
          return PopupMenuItem<String>(
            value: filter,
            height: 48,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isItemFilterSelected
                    ? AppColors.primaryAccent.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    filter,
                    style: TextStyle(
                      color: isItemFilterSelected
                          ? AppColors.primaryAccent
                          : AppColors.primaryText,
                      fontWeight: isItemFilterSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  if (isItemFilterSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryAccent,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              'More',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: fontWeight,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}