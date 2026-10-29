import 'package:flutter/material.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';

/// Unified passenger info input form for round-trip booking.
/// Dispatches updates to both outbound and inbound flows via coordinator.
class RoundTripPassengerStep extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialEmail;
  final String initialNote;
  final bool isValid;
  final bool busy;
  final bool readOnly;
  final int? countdownSeconds;
  final ValueChanged<UpdatePassengerInfoEvent> onUpdate;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const RoundTripPassengerStep({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.initialEmail,
    required this.initialNote,
    required this.isValid,
    required this.busy,
    this.readOnly = false,
    this.countdownSeconds,
    required this.onUpdate,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<RoundTripPassengerStep> createState() => _RoundTripPassengerStepState();
}

class _RoundTripPassengerStepState extends State<RoundTripPassengerStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _emailController = TextEditingController(text: widget.initialEmail);
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void didUpdateWidget(covariant RoundTripPassengerStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameReadOnly = widget.readOnly && !oldWidget.readOnly;
    if ((becameReadOnly || oldWidget.initialName != widget.initialName) &&
        _nameController.text != widget.initialName) {
      _nameController.text = widget.initialName;
    }
    if ((becameReadOnly || oldWidget.initialPhone != widget.initialPhone) &&
        _phoneController.text != widget.initialPhone) {
      _phoneController.text = widget.initialPhone;
    }
    if ((becameReadOnly || oldWidget.initialEmail != widget.initialEmail) &&
        _emailController.text != widget.initialEmail) {
      _emailController.text = widget.initialEmail;
    }
    if ((becameReadOnly || oldWidget.initialNote != widget.initialNote) &&
        _noteController.text != widget.initialNote) {
      _noteController.text = widget.initialNote;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _dispatchUpdate() {
    if (widget.readOnly) return;
    widget.onUpdate(
      UpdatePassengerInfoEvent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header description
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DiscoveryColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DiscoveryColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: DiscoveryColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.readOnly
                        ? 'Thông tin hành khách được giữ theo đơn đã tạo. Bạn có thể đổi ghế và điểm đón/trả của chiều còn lại.'
                        : 'Thông tin hành khách sẽ được áp dụng chung cho cả Lượt đi và Lượt về.',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Form fields card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DiscoveryColors.neutral200),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thông tin liên hệ',
                  style: DiscoveryTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // Họ và tên
                _buildField(
                  key: const ValueKey('passenger-name-field'),
                  label: 'Họ và tên *',
                  hint: 'Nguyễn Văn A',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  onChanged: (_) => _dispatchUpdate(),
                ),

                const SizedBox(height: 14),

                // Số điện thoại
                _buildField(
                  key: const ValueKey('passenger-phone-field'),
                  label: 'Số điện thoại *',
                  hint: '0912345678',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _dispatchUpdate(),
                ),

                const SizedBox(height: 14),

                // Email
                _buildField(
                  key: const ValueKey('passenger-email-field'),
                  label: 'Email nhận vé (tùy chọn)',
                  hint: 'example@email.com',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _dispatchUpdate(),
                ),

                const SizedBox(height: 14),

                // Ghi chú
                _buildField(
                  key: const ValueKey('passenger-note-field'),
                  label: 'Ghi chú cho nhà xe (tùy chọn)',
                  hint: 'Đón tại ngã tư, có hành lý cồng kềnh...',
                  controller: _noteController,
                  icon: Icons.note_alt_outlined,
                  maxLines: 2,
                  onChanged: (_) => _dispatchUpdate(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: widget.busy ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                  side: const BorderSide(color: DiscoveryColors.neutral300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Quay lại',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const ValueKey('passenger-continue-btn'),
                  onPressed: (!widget.isValid || widget.busy)
                      ? null
                      : widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DiscoveryColors.secondary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DiscoveryColors.neutral300,
                    minimumSize: const Size(140, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Xác nhận thông tin',
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _buildField({
    required Key key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DiscoveryTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: DiscoveryColors.neutral700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          readOnly: widget.readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: widget.readOnly ? null : onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DiscoveryTextStyles.bodyMedium.copyWith(
              color: DiscoveryColors.neutral400,
            ),
            prefixIcon: Icon(icon, color: DiscoveryColors.neutral500, size: 20),
            filled: true,
            fillColor: DiscoveryColors.neutral100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: DiscoveryColors.neutral200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: DiscoveryColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
