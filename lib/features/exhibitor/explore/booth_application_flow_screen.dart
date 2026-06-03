import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/bottom_sheet_date_field.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/booth_spot_model.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booth_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import 'widgets/public_booth_spot_card.dart';
import '../../../core/utils/feedback_helper.dart';

class BoothApplicationFlowScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const BoothApplicationFlowScreen({super.key, required this.exhibition});

  @override
  State<BoothApplicationFlowScreen> createState() => _BoothApplicationFlowScreenState();
}

class _BoothApplicationFlowScreenState extends State<BoothApplicationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  BoothSpotModel? _selectedSpot;

  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customRequirementController = TextEditingController();

  String? _selectedBusinessType;

  static const List<String> _businessTypeOptions = [
    'Technology',
    'Retail',
    'Food & Beverage',
    'Fashion',
    'Education',
    'Health & Wellness',
    'Art & Creative',
    'Services',
    'Other',
  ];

  final List<String> _selectedRequirements = [];
  final List<String> _availableRequirements = [
    'WiFi',
    'Extra Table & Chair',
  ];

  DateTime? _participationStartDate;
  DateTime? _participationEndDate;

  @override
  void initState() {
    super.initState();
    _participationStartDate = widget.exhibition.startDate;
    _participationEndDate = widget.exhibition.endDate;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
    context.read<BoothProvider>().fetchBoothPackages(widget.exhibition.id);
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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

  Widget _buildOverviewCard(List<BoothSpotModel> spots) {
    final int selectedCount = _selectedSpot != null ? 1 : 0;
    final int availableCount = spots.where((s) => s.status == 'Available').length - selectedCount;
    final int bookedCount = spots.where((s) => s.status != 'Available').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 28),
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

  @override
  void dispose() {
    _pageController.dispose();
    _companyController.dispose();
    _businessTypeController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    _customRequirementController.dispose();
    super.dispose();
  }

  Future<void> _selectParticipationDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart 
          ? (_participationStartDate ?? widget.exhibition.startDate) 
          : (_participationEndDate ?? widget.exhibition.endDate),
      firstDate: widget.exhibition.startDate,
      lastDate: widget.exhibition.endDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryText,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: AppColors.primaryText,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dayStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _participationStartDate = picked;
          if (_participationEndDate != null && _participationStartDate!.isAfter(_participationEndDate!)) {
            _participationEndDate = _participationStartDate;
          }
        } else {
          _participationEndDate = picked;
          if (_participationStartDate != null && _participationEndDate!.isBefore(_participationStartDate!)) {
            _participationStartDate = _participationEndDate;
          }
        }
      });
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _addCustomRequirement() {
    final text = _customRequirementController.text.trim();
    if (text.isEmpty) return;

    // Prevent duplicate in selected requirements (case-insensitive check)
    final isDuplicate = _selectedRequirements.any((r) => r.toLowerCase() == text.toLowerCase());
    if (!isDuplicate) {
      setState(() {
        _selectedRequirements.add(text);
      });
    }
    _customRequirementController.clear();
  }

  void _handleSubmit() async {
    // 1. Fast local check
    if (!widget.exhibition.isBookingOpen) {
      FeedbackHelper.showError(
        context,
        'Booking is closed. You cannot submit an application for this exhibition.',
      );
      return;
    }

    if (_participationStartDate == null || _participationEndDate == null) {
      FeedbackHelper.showError(context, 'Please select participation dates.');
      return;
    }

    if (_participationStartDate!.isAfter(_participationEndDate!)) {
      FeedbackHelper.showError(context, 'Start date cannot be after end date.');
      return;
    }

    if (_participationStartDate!.isBefore(widget.exhibition.startDate) ||
        _participationEndDate!.isAfter(widget.exhibition.endDate)) {
      FeedbackHelper.showError(context, 'Participation dates must be within the exhibition duration.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      FeedbackHelper.showWarning(context, 'Please login to submit application.');
      context.go(AppRoutes.login);
      return;
    }

    // 2. Real-time Firestore check
    try {
      final doc = await FirebaseFirestore.instance
          .collection('exhibitions')
          .doc(widget.exhibition.id)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final isBookingOpen = data['isBookingOpen'] as bool? ?? true;
          if (!isBookingOpen) {
            if (!mounted) return;
            FeedbackHelper.showError(
              context,
              'Booking is closed. You cannot submit an application for this exhibition.',
            );
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error verifying booking status: $e');
    }

    if (!mounted) return;
    final boothProvider = context.read<BoothProvider>();
    final package = _selectedSpot != null
        ? boothProvider.boothPackages
            .where((p) => p.id == _selectedSpot!.boothPackageId)
            .firstOrNull
        : null;

    if (package == null) {
      FeedbackHelper.showError(context, 'Could not resolve booth package.');
      return;
    }

    final application = ApplicationModel(
      id: '',
      userId: user.uid,
      exhibitionId: widget.exhibition.id,
      boothSpotId: _selectedSpot!.id,
      boothNumber: _selectedSpot!.spotNumber,
      companyName: _companyController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      productName: _productNameController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _selectedRequirements,
      status: 'Pending',
      createdAt: DateTime.now(),
      participationStartDate: _participationStartDate,
      participationEndDate: _participationEndDate,
    );

    if (!mounted) return;
    final appProvider = context.read<ApplicationProvider>();
    final success = await appProvider.submitApplication(application);

    if (mounted) {
      if (success) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        FeedbackHelper.showError(context, appProvider.errorMessage ?? 'Submission failed.');
      }
    }
  }

  String get _stepTitle {
    switch (_currentStep) {
      case 0:
        return 'Select Booth';
      case 1:
        return 'Application Form';
      case 2:
        return 'Review Details';
      default:
        return 'Success';
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.s,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (_currentStep < 3)
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                _stepTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_currentStep == 2)
              SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryText),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerRight,
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    if (!widget.exhibition.isBookingOpen && _currentStep < 3) {
      return GestureDetector(
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
      );
    }
    switch (_currentStep) {
      case 0:
        return AppButton(
          text: _selectedSpot == null ? 'Select a Booth' : 'Continue',
          onPressed: _selectedSpot == null
              ? null
              : () {
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

                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
        );
      case 1:
        return AppButton(
          text: 'Review Application',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              if (_participationStartDate == null || _participationEndDate == null) {
                FeedbackHelper.showError(context, 'Please select participation dates.');
                return;
              }
              if (_participationStartDate!.isAfter(_participationEndDate!)) {
                FeedbackHelper.showError(context, 'Start date cannot be after end date.');
                return;
              }
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      case 2:
        final isLoading = context.watch<ApplicationProvider>().isLoading;
        return AppButton(
          text: 'Submit Application',
          isLoading: isLoading,
          onPressed: _handleSubmit,
        );
      case 3:
        return AppButton(
          text: 'Return to Explore',
          onPressed: () {
            context.go(AppRoutes.root);
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSelectBoothStep() {
    final spotProvider = context.watch<BoothSpotProvider>();
    final boothProvider = context.watch<BoothProvider>();
    
    final spots = spotProvider.boothSpots;
    final isLoading = spotProvider.isLoading || boothProvider.isLoading;

    if (isLoading) {
      return const Center(child: AppLoading());
    }

    if (spots.isEmpty) {
      return const AppEmptyState(
        title: 'No Booths Available',
        message: 'The organizer has not added any booth spots for this event.',
        icon: Icons.grid_off,
      );
    }

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

    return Column(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
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
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryText,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryText, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 25,
            left: 35,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 35,
            right: 35,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            left: 30,
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF81C784),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 35,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E6C9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFC8E6C9).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSummaryCard(BoothSpotModel spot, BoothModel package) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            icon: Icons.grid_view_rounded,
            label: 'Booth Spot',
            value: spot.spotNumber,
          ),
          const Divider(height: 24, thickness: 0.8, color: Color(0xFFF5F5F5)),
          _buildSummaryRow(
            icon: Icons.layers_rounded,
            label: 'Package',
            value: '${package.name} (${package.size})',
          ),
          const Divider(height: 24, thickness: 0.8, color: Color(0xFFF5F5F5)),
          _buildSummaryRow(
            icon: Icons.info_outline_rounded,
            label: 'Status',
            value: 'Pending Review',
            isStatus: true,
          ),
          const Divider(height: 24, thickness: 0.8, color: Color(0xFFF5F5F5)),
          _buildSummaryRow(
            icon: Icons.payments_outlined,
            label: 'Price',
            value: 'RM ${package.price.toStringAsFixed(0)}',
            isPrice: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
        ),
        const Spacer(),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending Review',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE65100),
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isPrice ? AppColors.primaryAccent : AppColors.primaryText,
            ),
          ),
      ],
    );
  }

  Widget _buildAmenitiesChipList(List<String> amenities) {
    if (amenities.isEmpty) {
      return Text(
        'No included amenities listed',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade400,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 14, color: Colors.green.shade600),
              const SizedBox(width: 6),
              Text(
                a,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplicationFormStep() {
    final boothProvider = context.watch<BoothProvider>();
    final authProvider = context.watch<AuthProvider>();
    final package = _selectedSpot != null
        ? boothProvider.boothPackages
            .where((p) => p.id == _selectedSpot!.boothPackageId)
            .firstOrNull
        : null;

    final currentUser = authProvider.currentUser;

    // Gather chips: pre-defined + custom requirement chips
    final List<Widget> requirementChips = [];

    // Pre-defined chips
    for (var req in _availableRequirements) {
      final isSelected = _selectedRequirements.contains(req);
      requirementChips.add(
        FilterChip(
          label: Text(req),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (_selectedRequirements.contains(req)) {
                _selectedRequirements.remove(req);
              } else {
                _selectedRequirements.add(req);
              }
            });
          },
          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primaryAccent,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primaryAccent : Colors.grey.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Dynamic custom requirements chips (items in _selectedRequirements but not in _availableRequirements)
    final customRequirements = _selectedRequirements.where((r) => !_availableRequirements.contains(r)).toList();
    for (var req in customRequirements) {
      requirementChips.add(
        FilterChip(
          label: Text(req),
          selected: true,
          onSelected: (_) {
            setState(() {
              _selectedRequirements.remove(req);
            });
          },
          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primaryAccent,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: AppColors.primaryAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 140,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Selected Booth Details
              if (_selectedSpot != null && package != null)
                _buildFormSection(
                  title: 'Selected Booth Details',
                  children: [
                    _buildSummaryCard(_selectedSpot!, package),
                  ],
                ),

              // Section 1.5: Participation Period
              _buildFormSection(
                title: 'Participation Period',
                children: [
                  Text(
                    'Select your intended stay duration. The booth package price remains fixed.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      BottomSheetDateField(
                        innerLabel: 'Start Date',
                        date: _participationStartDate ?? widget.exhibition.startDate,
                        onTap: () => _selectParticipationDate(context, true),
                        dateFormat: DateFormat('d MMM yyyy'),
                      ),
                      const SizedBox(width: 16),
                      BottomSheetDateField(
                        innerLabel: 'End Date',
                        date: _participationEndDate ?? widget.exhibition.endDate,
                        onTap: () => _selectParticipationDate(context, false),
                        dateFormat: DateFormat('d MMM yyyy'),
                      ),
                    ],
                  ),
                ],
              ),

              // Section 2: Company Information
              _buildFormSection(
                title: 'Company Information',
                children: [
                  _buildFormTextField(
                    controller: _companyController,
                    label: 'Company Name',
                    hint: 'Enter registered company name',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFormDropdownField(
                    label: 'Business Type',
                    hint: 'Select business type',
                    value: _selectedBusinessType,
                    items: _businessTypeOptions,
                    onChanged: (val) {
                      setState(() {
                        _selectedBusinessType = val;
                        if (val != 'Other') {
                          _businessTypeController.text = val ?? '';
                        } else {
                          _businessTypeController.clear();
                        }
                      });
                    },
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  if (_selectedBusinessType == 'Other') ...[
                    const SizedBox(height: 20),
                    _buildFormTextField(
                      controller: _businessTypeController,
                      label: 'Specify Business Type',
                      hint: 'Enter your business type',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ],
              ),

              // Section 3: Contact Information
              _buildFormSection(
                title: 'Contact Information',
                children: [
                  _buildReadOnlyField(
                    label: 'Contact Person Name',
                    value: currentUser?.name ?? 'Loading profile...',
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField(
                    label: 'Email Address',
                    value: currentUser?.email ?? 'Loading profile...',
                  ),
                ],
              ),

              // Section 4: Booth Details
              _buildFormSection(
                title: 'Booth Details',
                children: [
                  _buildFormTextField(
                    controller: _productNameController,
                    label: 'Product / Service Name',
                    hint: 'What are you showcasing?',
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildFormTextField(
                    controller: _descriptionController,
                    label: 'Product / Booth Description',
                    hint: 'Briefly describe your participation and display goals...',
                    maxLines: 4,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                ],
              ),

              // Section 5: Included Amenities
              if (package != null)
                _buildFormSection(
                  title: 'Included Amenities',
                  children: [
                    _buildAmenitiesChipList(package.amenities),
                  ],
                ),

              // Section 6: Additional Requirements
              _buildFormSection(
                title: 'Additional Requirements',
                children: [
                  if (requirementChips.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: requirementChips,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customRequirementController,
                          style: const TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add custom requirement...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            fillColor: Colors.white,
                            filled: true,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
                            ),
                          ),
                          onSubmitted: (_) => _addCustomRequirement(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addCustomRequirement,
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.primaryAccent,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BoothSpotModel spot, BoothModel package) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exhibition.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 15.5,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booth Spot: ${spot.spotNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                  color: AppColors.primaryText,
                ),
              ),
              Text(
                'RM ${package.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14.5,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Package: ${package.name} (${package.size})',
            style: TextStyle(
              color: Colors.grey.shade500, 
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildReviewSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewDetailRow(String label, String value, {bool isPrice = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryText.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isPrice ? FontWeight.bold : FontWeight.w600,
              color: isPrice ? AppColors.primaryAccent : AppColors.primaryText,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final boothProvider = context.watch<BoothProvider>();
    final authProvider = context.watch<AuthProvider>();
    final package = _selectedSpot != null
        ? boothProvider.boothPackages
            .where((p) => p.id == _selectedSpot!.boothPackageId)
            .firstOrNull
        : null;

    final currentUser = authProvider.currentUser;

    if (_selectedSpot == null || package == null) {
      return const Center(child: Text('Review data incomplete.'));
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top checkout summary card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.exhibition.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Booth ${_selectedSpot!.spotNumber} · ${package.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryText.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'RM ${package.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),

            // Event Information Section
            _buildReviewSection(
              title: 'Event Information',
              children: [
                _buildReviewDetailRow('Exhibition', widget.exhibition.name),
                const SizedBox(height: 12),
                _buildReviewDetailRow('Location', widget.exhibition.location),
                const SizedBox(height: 12),
                _buildReviewDetailRow(
                  'Date',
                  '${_formatDate(widget.exhibition.startDate)} - ${_formatDate(widget.exhibition.endDate)}',
                ),
              ],
            ),

            // Selected Booth Section
            _buildReviewSection(
              title: 'Selected Booth',
              children: [
                _buildReviewDetailRow('Spot Number', _selectedSpot!.spotNumber),
                const SizedBox(height: 12),
                _buildReviewDetailRow('Package Name', package.name),
                const SizedBox(height: 12),
                _buildReviewDetailRow('Size', package.size),
                const SizedBox(height: 12),
                _buildReviewDetailRow('Price', 'RM ${package.price.toStringAsFixed(0)}', isPrice: true),
                const SizedBox(height: 12),
                _buildReviewDetailRow(
                  'Participation Period',
                  (_participationStartDate != null && _participationEndDate != null)
                      ? '${_formatDate(_participationStartDate!)} - ${_formatDate(_participationEndDate!)}'
                      : 'Full Event Duration',
                ),
              ],
            ),

            // Company & Contact Information Section
            _buildReviewSection(
              title: 'Company & Contact Info',
              children: [
                if (_companyController.text.trim().isNotEmpty) ...[
                  _buildReviewDetailRow('Company Name', _companyController.text.trim()),
                  const SizedBox(height: 12),
                ],
                if (_businessTypeController.text.trim().isNotEmpty) ...[
                  _buildReviewDetailRow('Business Type', _businessTypeController.text.trim()),
                  const SizedBox(height: 12),
                ],
                if (currentUser?.name != null && currentUser!.name.isNotEmpty) ...[
                  _buildReviewDetailRow('Contact Person', currentUser.name),
                  const SizedBox(height: 12),
                ],
                if (currentUser?.email != null && currentUser!.email.isNotEmpty) ...[
                  _buildReviewDetailRow('Email Address', currentUser.email),
                ],
              ],
            ),

            // Booth Details Section
            _buildReviewSection(
              title: 'Booth Details',
              children: [
                _buildReviewDetailRow('Showcasing', _productNameController.text.trim()),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _descriptionController.text.trim(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryText,
                    height: 1.45,
                  ),
                ),
              ],
            ),

            // Included Amenities Section
            _buildReviewSection(
              title: 'Included Amenities',
              children: [
                if (package.amenities.isEmpty)
                  const Text(
                    'No included amenities listed',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: package.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 13, color: Colors.green.shade600),
                            const SizedBox(width: 4),
                            Text(
                              a,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),

            // Additional Requirements Section
            _buildReviewSection(
              title: 'Additional Requirements',
              children: [
                if (_selectedRequirements.isEmpty)
                  Text(
                    'No additional requirements',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedRequirements.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.15), width: 0.8),
                        ),
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStep() {
    final boothProvider = context.watch<BoothProvider>();
    final package = _selectedSpot != null
        ? boothProvider.boothPackages
            .where((p) => p.id == _selectedSpot!.boothPackageId)
            .firstOrNull
        : null;

    if (_selectedSpot == null || package == null) {
      return const Center(
        child: Text(
          'Submission data incomplete.',
          style: TextStyle(color: Colors.redAccent, fontSize: 16),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 30,
          bottom: 140,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSuccessIcon(),
            const SizedBox(height: 28),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Text(
              'Your application for booth spot ${_selectedSpot!.spotNumber} has been submitted successfully. The event organizer will review your request shortly.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            _buildSuccessSummaryCard(_selectedSpot!, package),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() {
                    _currentStep = idx;
                  });
                },
                children: [
                  _buildSelectBoothStep(),
                  _buildApplicationFormStep(),
                  _buildReviewStep(),
                  _buildSuccessStep(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: _buildBottomAction(),
              ),
            ),
    );
  }
}
