import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_spot_model.dart';
import '../../../providers/booth_package_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import '../../../providers/exhibition_provider.dart';
import 'widgets/booth_spot_bottom_sheet.dart';
import 'widgets/booth_spot_card.dart';
import 'widgets/create_floor_layout_bottom_sheet.dart';
import 'widgets/edit_floor_layout_bottom_sheet.dart';
import '../../../core/utils/feedback_helper.dart';

// Display booth spots and floor plan layout.
class BoothSpotsScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const BoothSpotsScreen({super.key, required this.exhibition});

  @override
  State<BoothSpotsScreen> createState() => _BoothSpotsScreenState();
}

class _BoothSpotsScreenState extends State<BoothSpotsScreen> {
  @override
  void initState() {
    super.initState();

    // Load booth spots and packages after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    // Load floor plan spots and booth packages.
    context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
    context.read<BoothPackageProvider>().fetchBoothPackages(widget.exhibition.id);
  }

  void _showAddSpotSheet(
    bool isLayoutEmpty,
    List<BoothSpotModel> spots,
    int rowsCount,
    int columnsCount,
  ) {
    if (isLayoutEmpty) {
      // Create floor layout before adding spots.
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            CreateFloorLayoutBottomSheet(exhibitionId: widget.exhibition.id),
      );
      return;
    }

    String? nextAvailable;

    // Find first empty booth coordinate.
    for (int r = 0; r < rowsCount; r++) {
      final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);

      for (int c = 0; c < columnsCount; c++) {
        final colNumber = (c + 1).toString().padLeft(2, '0');
        final spotNum = '$rowLetter$colNumber';

        final exists = spots.any(
          (s) => s.spotNumber.trim().toUpperCase() == spotNum,
        );

        if (!exists) {
          nextAvailable = spotNum;
          break;
        }
      }

      if (nextAvailable != null) break;
    }

    if (nextAvailable == null) {
      FeedbackHelper.showWarning(
        context,
        'Layout is full. Increase rows or columns to add more spots.',
      );
      return;
    }

    // Open add booth spot bottom sheet.
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BoothSpotBottomSheet(
        exhibitionId: widget.exhibition.id,
        rows: rowsCount,
        columns: columnsCount,
        presetSpotNumber: nextAvailable,
      ),
    ).then((result) {
      if (result == true && mounted) {
        FeedbackHelper.showSuccess(context, 'Spot created successfully.');
      }
    });
  }

  void _showEditLayoutSheet(ExhibitionModel exhibition, int rows, int columns) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditFloorLayoutBottomSheet(
        exhibition: exhibition,
        currentRows: rows,
        currentColumns: columns,
      ),
    ).then((_) {
      if (mounted) {
        // Refresh exhibition layout metadata.
        context.read<ExhibitionProvider>().fetchOrganizerExhibitions(
          widget.exhibition.organizerId,
        );
      }
    });
  }

  int getRowIndex(String spotNumber) {
    if (spotNumber.isEmpty) return 0;

    final firstChar = spotNumber[0].toUpperCase();

    if (firstChar.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
        firstChar.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) {
      return firstChar.codeUnitAt(0) - 'A'.codeUnitAt(0);
    }

    return 0;
  }

  int getColIndex(String spotNumber) {
    if (spotNumber.length < 2) return 0;

    final digits = spotNumber.substring(1);
    final val = int.tryParse(digits);

    if (val != null) {
      return val - 1;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final spotProvider = context.watch<BoothSpotProvider>();
    final boothProvider = context.watch<BoothPackageProvider>();
    final exhibitionProvider = context.watch<ExhibitionProvider>();

    final spots = spotProvider.boothSpots;
    final isLoading = spotProvider.isLoading || boothProvider.isLoading;

    // Get latest exhibition layout metadata.
    final exhibition = exhibitionProvider.organizerExhibitions.firstWhere(
      (e) => e.id == widget.exhibition.id,
      orElse: () => widget.exhibition,
    );

    int maxRow = 0;
    int maxCol = 0;

    // Calculate layout size from existing spots.
    for (final spot in spots) {
      final r = getRowIndex(spot.spotNumber);
      final c = getColIndex(spot.spotNumber);

      if (r > maxRow) maxRow = r;
      if (c > maxCol) maxCol = c;
    }

    final rowsCount = exhibition.layoutRows ?? (spots.isEmpty ? 0 : maxRow + 1);
    final columnsCount =
        exhibition.layoutColumns ?? (spots.isEmpty ? 0 : maxCol + 1);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Floor Plan',
              showBackButton: true,
              actions: spots.isNotEmpty && !isLoading
                  ? [
                      IconButton(
                        // Open layout editor.
                        onPressed: () => _showEditLayoutSheet(
                          exhibition,
                          rowsCount,
                          columnsCount,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ]
                  : null,
            ),

            // Show booth status summary.
            if (!isLoading && spots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.m,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.s + 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    children: [
                      Expanded(
                        child: Center(
                          child: _buildOverviewStatusItem(
                            'Available',
                            spots.where((s) => s.status == 'Available').length,
                            const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildOverviewStatusItem(
                            'Pending',
                            spots.where((s) => s.status == 'Pending').length,
                            const Color(0xFFEF6C00),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildOverviewStatusItem(
                            'Booked',
                            spots.where((s) => s.status == 'Booked').length,
                            const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : spots.isEmpty
                  ? const AppEmptyState(
                      title: 'No Floor Layout Yet',
                      message: 'Create booth locations and assign packages.',
                      icon: Icons.map_outlined,
                    )
                  : _buildFloorPlanCanvas(exhibition, spots, rowsCount, columnsCount),
            ),
          ],
        ),
      ),

      // Show create layout or add spot action.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showAddSpotSheet(spots.isEmpty, spots, rowsCount, columnsCount),
        backgroundColor: AppColors.primaryText,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          spots.isEmpty ? 'Create Layout' : 'Add Spot',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOverviewStatusItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFloorPlanCanvas(
    ExhibitionModel exhibition,
    List<BoothSpotModel> spots,
    int rowsCount,
    int columnsCount,
  ) {
    final List<List<BoothSpotModel?>> grid = List.generate(
      rowsCount,
      (_) => List.filled(columnsCount, null),
    );

    // Place booth spots into layout grid.
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
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
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
      return Container(
        width: 145,
        height: 155,
        margin: const EdgeInsets.all(5),
        child: BoothSpotCard(
          spot: spot,
          exhibition: exhibition,
          compact: true,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;

        final double tileHeight = 165.0;
        final double headerHeight = 24.0 + 24.0 + 10.0;
        final double baseDecorHeight = 40.0;

        final double desiredHeight = (rowsCount * tileHeight) + baseDecorHeight;
        final double maxGridHeight = availableHeight - headerHeight;
        final double containerHeight = desiredHeight <= maxGridHeight
            ? desiredHeight
            : (maxGridHeight > 100 ? maxGridHeight : 100.0);

        final double matrixWidth = columnsCount * 155.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildSectionHeader(
              'BOOTH LAYOUT MAP',
              trailing: '${spots.length} spots total',
            ),
            const SizedBox(height: 10),
            Padding(
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
                            bottom: 96 + MediaQuery.of(context).padding.bottom,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? trailing,
    IconData? trailingIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.4,
            ),
          ),
          if (trailing != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingIcon != null) ...[
                  Icon(trailingIcon, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                ],
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
