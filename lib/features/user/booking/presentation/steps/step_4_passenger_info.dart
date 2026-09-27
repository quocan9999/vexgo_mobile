import 'package:flutter/material.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_event.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';

class Step4PassengerInfo extends StatefulWidget {
  final BookingFlowState state;
  final BookingFlowBloc bloc;

  const Step4PassengerInfo({
    super.key,
    required this.state,
    required this.bloc,
  });

  @override
  State<Step4PassengerInfo> createState() => _Step4PassengerInfoState();
}

class _Step4PassengerInfoState extends State<Step4PassengerInfo> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _noteController;
  late bool _saveInfo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.passengerName);
    _phoneController = TextEditingController(text: widget.state.passengerPhone);
    _emailController = TextEditingController(text: widget.state.passengerEmail);
    _noteController = TextEditingController(text: widget.state.passengerNote);
    _saveInfo = widget.state.savePassengerInfo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _syncData() {
    widget.bloc.add(UpdatePassengerInfoEvent(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      note: _noteController.text,
      saveInfo: _saveInfo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    'Thông tin này được dùng để gửi mã vé điện tử và để tài xế liên hệ đón bạn.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.neutral700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.base),

          // Form Container
          Container(
            padding: const EdgeInsets.all(AppDimensions.base),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.neutral200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thông tin liên hệ & người đi', style: AppTextStyles.h4),
                const SizedBox(height: AppDimensions.md),

                // Full name
                CustomTextField(
                  label: 'Họ và tên hành khách *',
                  hintText: 'Ví dụ: Nguyễn Văn An',
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  onChanged: (_) => _syncData(),
                ),

                const SizedBox(height: AppDimensions.base),

                // Phone
                CustomTextField(
                  label: 'Số điện thoại di động *',
                  hintText: 'Ví dụ: 0987654321',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                  onChanged: (_) => _syncData(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Nhà xe sẽ nhắn tin SMS/Zalo mã vé và gọi đón qua số này.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral400, fontSize: 11),
                  ),
                ),

                const SizedBox(height: AppDimensions.base),

                // Email
                CustomTextField(
                  label: 'Email nhận vé điện tử *',
                  hintText: 'Ví dụ: nguyenvanan@gmail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                  onChanged: (_) => _syncData(),
                ),

                const SizedBox(height: AppDimensions.base),

                // Note
                CustomTextField(
                  label: 'Ghi chú cho nhà xe (Tùy chọn)',
                  hintText: 'Ví dụ: Có người già, mang theo 2 vali lớn...',
                  controller: _noteController,
                  maxLines: 2,
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.neutral500),
                  onChanged: (_) => _syncData(),
                ),

                const SizedBox(height: AppDimensions.md),

                // Save info checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _saveInfo,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) {
                          setState(() {
                            _saveInfo = val ?? true;
                          });
                          _syncData();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _saveInfo = !_saveInfo;
                          });
                          _syncData();
                        },
                        child: Text(
                          'Lưu thông tin cho những lần đặt vé sau',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
