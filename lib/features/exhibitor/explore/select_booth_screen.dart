import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../data/models/booth_spot_model.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booth_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import 'widgets/public_booth_spot_card.dart';
import '../../../core/utils/feedback_helper.dart';

class SelectBoothScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const SelectBoothScreen({super.key, required this.exhibition});

  @override
  State<SelectBoothScreen> createState() => _SelectBoothScreenState();
}

class _SelectBoothScreenState extends State<SelectBoothScreen> {
  BoothSpotModel? _selectedSpot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
    context.read<BoothProvider>().fetchBoothPackages(widget.exhibition.id);
  }

  Widget _buildOverviewCard(List<BoothSpotModel> spots) {
    final int selectedCount = _selectedSpot != null ? 1 : 0;
    final int availableCount = spots.where((s) => s.status == 'Available').length - selectedCount;
    final int bookedCount = spots.where((s) => s.status != 'Available').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOverviewIndicator(
              color: const Color(0xFF0F9D58),
              count: availableCount,
              label: 'Available',
            ),
            _buildOverviewIndicator(
              color: Colors.blue.shade600,
              count: selectedCount,
              label: 'Selected',
              isBold: selectedCount > 0,
            ),
            _buildOverviewIndicator(
              color: Colors.red.shade600,
              count: bookedCount,
              label: 'Booked',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewIndicator({
    required Color color,
    required int count,
    required String label,
    bool isBold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.bold,
            color: isBold ? Colors.blue.shade800 : Colors.grey.shade800,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? Colors.blue.shade700 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(int totalSpots) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal + 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'BOOTH LAYOUT MAP',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.4,
            ),
          ),
          Text(
            '$totalSpots spots total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildBookingClosedBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryAccent.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Booking is currently closed for this exhibition.',
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = context.watch<BoothSpotProvider>();
    final boothProvider = context.watch<BoothProvider>();
    
    final spots = spotProvider.boothSpots;
    final isLoading = spotProvider.isLoading || boothProvider.isLoading;

    int maxRow = 0;
    int maxCol = 0;
    for (final spot in spots) {
      final r = getRowIndex(spot.spotNumber);
      final c = getColIndex(spot.spotNumber);
      if (r > maxRow) maxRow = r;
      if (c > maxCol) maxCol = c;
    }

    final rowsCount = widget.exhibition.layoutRows ?? (spots.isEmpty ? 0 : maxRow + 1);
    final columnsCount = widget.exhibition.layoutColumns ?? (spots.isEmpty ? 0 : maxCol + 1);

    final List<List<BoothSpotModel?>> grid = List.generate(
      rowsCount,
      (_) => List.filled(columnsCount, null),
    );

    for (final spot in spots) {
      final r = getRowIndex(spot.spotNumber);
      final c = getColIndex(spot.spotNumber);
      if (r >= 0 && r < rowsCount && c >= 0 && c < columnsCount) {
        grid[r][c] = spot;
      }
    }

    Widget buildEmptyTile(int r, int c) {
      final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);
      final colNumber = (c + 1).toString().padLeft(2, '0');
      final spotLabel = '$rowLetter$colNumber';

      return Container(
        width: 145,
        height: 155,
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                spotLabel,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gap / Path',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildSpotTile(BoothSpotModel spot) {
      final isSelected = _selectedSpot?.id == spot.id;
      final isAvailable = spot.status == 'Available';
      
      return Container(
        width: 145,
        height: 155,
        margin: const EdgeInsets.all(5),
        child: PublicBoothSpotCard(
          spot: spot,
          isSelected: isSelected,
          onTap: isAvailable
              ? (widget.exhibition.isBookingOpen
                  ? () => setState(() => _selectedSpot = spot)
                  : () {
                      FeedbackHelper.showWarning(
                        context,
                        'Booking is currently closed for this exhibition.',
                      );
                    })
              : null,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Select Booth',
              showBackButton: true,
            ),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : spots.isEmpty
                      ? const AppEmptyState(
                          title: 'No Booths Available',
                          message: 'The organizer has not added any booth spots for this event.',
                          icon: Icons.grid_off,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            _buildOverviewCard(spots),
                            if (!widget.exhibition.isBookingOpen) ...[
                              const SizedBox(height: 12),
                              _buildBookingClosedBanner(),
                            ],
                            const SizedBox(height: 24),
                            _buildSectionHeader(spots.length),
                            const SizedBox(height: 10),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final double availableHeight = constraints.maxHeight;
                                  
                                  final double tileHeight = 165.0; // 155.0 tile height + 10.0 vertical margins (5 top, 5 bottom)
                                  final double baseDecorHeight = 40.0; // outer container margins + canvas padding
                                  
                                  final double desiredHeight = (rowsCount * tileHeight) + baseDecorHeight;
                                  final double maxGridHeight = availableHeight - 16.0;
                                  final double containerHeight = desiredHeight <= maxGridHeight 
                                      ? desiredHeight 
                                      : (maxGridHeight > 100 ? maxGridHeight : 100.0);

                                  final double matrixWidth = columnsCount * 155.0;

                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.screenHorizontal,
                                      0,
                                      AppSpacing.screenHorizontal,
                                      0,
                                    ),
                                    child: Container(
                                      height: containerHeight,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.grey.shade200, width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.02),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          color: Colors.grey.shade50,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.vertical,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                  left: 12,
                                                  right: 12,
                                                  top: 12,
                                                  bottom: 120 + MediaQuery.of(context).padding.bottom,
                                                ),
                                                child: SizedBox(
                                                  width: matrixWidth,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      for (int r = 0; r < rowsCount; r++)
                                                        Row(
                                                          children: [
                                                            for (int c = 0; c < columnsCount; c++)
                                                              grid[r][c] != null
                                                                  ? buildSpotTile(grid[r][c]!)
                                                                  : buildEmptyTile(r, c),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16, // Premium visual lift above home indicators matching details page
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: widget.exhibition.isBookingOpen
            ? AppButton(
                text: _selectedSpot == null ? 'Select a Booth' : 'Continue',
                onPressed: _selectedSpot == null
                    ? null
                    : () {
                        final package = boothProvider.boothPackages
                            .where((p) => p.id == _selectedSpot!.boothPackageId)
                            .firstOrNull;

                        if (package == null) {
                          FeedbackHelper.showError(context, 'Could not resolve booth package.');
                          return;
                        }

                        // Authenticate Guest User at checkout point
                        final authProvider = context.read<AuthProvider>();
                        if (!authProvider.isLoggedIn) {
                          FeedbackHelper.showWarning(context, 'Please log in to apply for a booth');
                          context.push(AppRoutes.login);
                          return;
                        }

                        if (authProvider.currentUser?.role != 'Exhibitor') {
                          FeedbackHelper.showWarning(context, 'Only exhibitors can book booths');
                          return;
                        }

                        context.push(
                          AppRoutes.applicationForm,
                          extra: {
                            'exhibition': widget.exhibition,
                            'boothSpot': _selectedSpot,
                            'boothPackage': package,
                          },
                        );
                      },
              )
            : GestureDetector(
                onTap: () {
                  FeedbackHelper.showWarning(
                    context,
                    'Booking is currently closed for this exhibition.',
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppRadius.l),
                  ),
                  child: Text(
                    'Booking Closed',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
