import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/booth_package_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import 'widgets/booth_package_bottom_sheet.dart';
import 'widgets/booth_package_card.dart';
import '../../../core/utils/feedback_helper.dart';

// Display booth packages for selected exhibition.
class BoothPackagesScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const BoothPackagesScreen({super.key, required this.exhibition});

  @override
  State<BoothPackagesScreen> createState() => _BoothPackagesScreenState();
}

class _BoothPackagesScreenState extends State<BoothPackagesScreen> {
  @override
  void initState() {
    super.initState();

    // Load booth packages and spots after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoothPackageProvider>().fetchBoothPackages(widget.exhibition.id);
      context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
    });
  }

  void _showAddPackageSheet() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          BoothPackageBottomSheet(exhibitionId: widget.exhibition.id),
    ).then((result) {
      if (result == true && mounted) {
        FeedbackHelper.showSuccess(context, 'Package created successfully.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothPackageProvider>();
    final packages = boothProvider.boothPackages;
    final isLoading = boothProvider.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Booth Packages', showBackButton: true),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : packages.isEmpty
                  ? const AppEmptyState(
                      title: 'No Packages Yet',
                      message: 'Create booth types for this exhibition.',
                      icon: Icons.inventory_2_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                        vertical: AppSpacing.m,
                      ),
                      itemCount: packages.length,
                      itemBuilder: (context, index) {
                        // Show booth package card.
                        return BoothPackageCard(
                          package: packages[index],
                          exhibitionId: widget.exhibition.id,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Show add package action.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPackageSheet,
        backgroundColor: AppColors.primaryText,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Package', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
