import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../data/models/application_model.dart';
import '../../../../providers/application_provider.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

// Dialog for completing application payment.
class PaymentDialog extends StatefulWidget {
  final ApplicationModel application;

  const PaymentDialog({super.key, required this.application});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedMethod = 'Credit Card';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'name': 'Credit Card',
      'icon': Icons.credit_card_rounded,
      'desc': 'Visa, Mastercard, or AMEX',
    },
    {
      'name': 'Online Banking',
      'icon': Icons.account_balance_rounded,
      'desc': 'Instant FPX Bank Transfer',
    },
    {
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet_rounded,
      'desc': 'TNG, GrabPay, or ShopeePay',
    },
  ];

  void _handleConfirm() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final appProvider = context.read<ApplicationProvider>();

    // Generate mock transaction ID.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = widget.application.id.length >= 4
        ? widget.application.id.substring(0, 4).toUpperCase()
        : 'MOCK';
    final txnId = 'BTF-TXN-$timestamp-$randomSuffix';

    // Submit payment through provider.
    final success = await appProvider.makePayment(
      applicationId: widget.application.id,
      userId: widget.application.userId,
      paymentMethod: _selectedMethod,
      transactionId: txnId,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context, true);
      } else {
        final error = appProvider.errorMessage ??
            'Simulated payment processing failed. Please try again.';
        FeedbackHelper.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();

    // Resolve booth package details.
    final spot = spotProvider.boothSpots
        .where((s) => s.id == widget.application.boothSpotId)
        .firstOrNull;

    final package = spot != null && spot.boothPackageId.isNotEmpty
        ? boothProvider.boothPackages
            .where((p) => p.id == spot.boothPackageId)
            .firstOrNull
        : null;

    final packageName = package?.name ?? 'Standard Booth';
    final priceStr =
        package != null ? 'RM ${package.price.toStringAsFixed(2)}' : 'RM 800.00';

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show payment dialog header.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Make Payment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryText,
                        letterSpacing: -0.4,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 24,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF5F5F5),
              ),

              // Show payment summary.
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, width: 0.8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Booth ${widget.application.boothNumber}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        priceStr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SELECT PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryText,
                    letterSpacing: 1.0,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Show payment method options.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: _paymentMethods.map((method) {
                    final name = method['name'] as String;
                    final icon = method['icon'] as IconData;
                    final desc = method['desc'] as String;
                    final isSelected = _selectedMethod == name;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryAccent
                              : Colors.grey.shade200,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedMethod = name;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  icon,
                                  color: isSelected
                                      ? AppColors.primaryAccent
                                      : Colors.grey.shade500,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? AppColors.primaryText
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      desc,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: name,
                                // ignore: deprecated_member_use
                                groupValue: _selectedMethod,
                                activeColor: AppColors.primaryAccent,
                                // ignore: deprecated_member_use
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedMethod = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              const Divider(
                height: 1,
                thickness: 0.8,
                color: Color(0xFFF5F5F5),
              ),

              // Confirm selected payment method.
              Padding(
                padding: const EdgeInsets.all(24),
                child: AppButton(
                  text: 'Confirm Payment',
                  color: AppColors.primaryText,
                  height: 48,
                  borderRadius: 14,
                  isLoading: _isSubmitting,
                  onPressed: _handleConfirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}