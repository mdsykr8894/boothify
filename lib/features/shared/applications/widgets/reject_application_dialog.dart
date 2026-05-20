import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/base_dialog.dart';

class RejectApplicationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Function(String reason) onConfirm;

  const RejectApplicationDialog({
    super.key,
    this.title = 'Reject Application',
    this.subtitle = 'Please provide a reason for rejecting this application.',
    required this.onConfirm,
  });

  @override
  State<RejectApplicationDialog> createState() => _RejectApplicationDialogState();
}

class _RejectApplicationDialogState extends State<RejectApplicationDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: widget.title,
      message: widget.subtitle,
      variant: DialogVariant.destructive,
      primaryLabel: 'Reject',
      secondaryLabel: 'Cancel',
      onSecondaryPressed: () => Navigator.pop(context),
      onPrimaryPressed: () {
        if (_formKey.currentState!.validate()) {
          widget.onConfirm(_reasonController.text.trim());
          Navigator.pop(context);
        }
      },
      customBody: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rejection Reason',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w500,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Reason is required' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Documentation incomplete or verification details missing',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryAccent,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 1.5,
                    ),
                  ),
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
