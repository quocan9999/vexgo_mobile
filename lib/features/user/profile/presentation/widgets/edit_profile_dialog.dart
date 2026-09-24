import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/core/widgets/custom_text_field.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;

  const EditProfileDialog({
    super.key,
    required this.user,
  });

  static Future<void> show(BuildContext context, {required UserModel user}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileDialog(user: user),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cccdController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.hoTen);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _cccdController = TextEditingController(text: widget.user.cccd ?? '');
    _dobController = TextEditingController(text: widget.user.ngaySinh ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cccdController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Họ và tên không được để trống')),
      );
      return;
    }

    final updated = widget.user.copyWith(
      hoTen: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      cccd: _cccdController.text.trim().isEmpty ? null : _cccdController.text.trim(),
      ngaySinh: _dobController.text.trim().isEmpty ? null : _dobController.text.trim(),
    );

    context.read<AuthBloc>().add(UpdateProfileEvent(updated));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.base),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXl),
            topRight: Radius.circular(AppDimensions.radiusXl),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Chỉnh sửa thông tin cá nhân',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.neutral600),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppDimensions.sm),

              // Họ tên
              Text(
                'Họ và tên *',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              CustomTextField(
                controller: _nameController,
                hintText: 'Nhập họ và tên',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.neutral500),
              ),

              const SizedBox(height: AppDimensions.md),

              // Số điện thoại (Read-only)
              Text(
                'Số điện thoại (Đã xác thực)',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      widget.user.soDienThoai,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đã kích hoạt',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.md),

              // Email
              Text(
                'Email',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              CustomTextField(
                controller: _emailController,
                hintText: 'example@gmail.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.neutral500),
              ),

              const SizedBox(height: AppDimensions.md),

              // CCCD & Ngày sinh
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số CCCD / CMND',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        CustomTextField(
                          controller: _cccdController,
                          hintText: '12 chữ số',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ngày sinh (YYYY-MM-DD)',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutral700,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        CustomTextField(
                          controller: _dobController,
                          hintText: '2002-12-22',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.xl),

              // Save button
              CustomButton(
                text: 'LƯU THAY ĐỔI',
                width: double.infinity,
                type: ButtonType.primary,
                onPressed: _onSave,
              ),
              const SizedBox(height: AppDimensions.sm),
            ],
          ),
        ),
      ),
    );
  }
}
