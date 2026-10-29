import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class EditProfileDialog extends StatefulWidget {
  final UserModel user;

  const EditProfileDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, {required UserModel user}) {
    final authBloc = context.read<AuthBloc>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: authBloc,
        child: EditProfileDialog(user: user),
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cccdFieldKey = GlobalKey<FormFieldState<String>>();
  final _dobFieldKey = GlobalKey<FormFieldState<String>>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _cccdController;
  late TextEditingController _dobController;

  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _cccdFocusNode;
  late final FocusNode _dobFocusNode;

  ModalRoute<dynamic>? _route;
  bool _isRevoked = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.hoTen);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _cccdController = TextEditingController(text: widget.user.cccd ?? '');
    _dobController = TextEditingController(text: widget.user.ngaySinh ?? '');

    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _cccdFocusNode = FocusNode();
    _dobFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
  }

  void _clearDraft() {
    _nameController.clear();
    _emailController.clear();
    _cccdController.clear();
    _dobController.clear();
  }

  void _revokeAndDismiss() {
    if (_isRevoked) return;
    _isRevoked = true;
    _clearDraft();
    if (_route != null && _route!.isActive) {
      if (_route!.isCurrent) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).removeRoute(_route!);
      }
    }
  }

  @override
  void dispose() {
    _clearDraft();
    _nameController.dispose();
    _emailController.dispose();
    _cccdController.dispose();
    _dobController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _cccdFocusNode.dispose();
    _dobFocusNode.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_isRevoked) return;
    final currentUser = context.read<AuthBloc>().state.user;
    if (currentUser == null ||
        currentUser.taiKhoanId != widget.user.taiKhoanId) {
      _revokeAndDismiss();
      return;
    }

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() {
        _nameError = 'Họ và tên không được để trống';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Họ và tên không được để trống')),
      );
      return;
    }

    final updated = widget.user.copyWith(
      hoTen: trimmedName,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      cccd: _cccdController.text.trim().isEmpty
          ? null
          : _cccdController.text.trim(),
      ngaySinh: _dobController.text.trim().isEmpty
          ? null
          : _dobController.text.trim(),
    );

    context.read<AuthBloc>().add(UpdateProfileEvent(updated));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.isAuthenticated != current.isAuthenticated ||
          previous.user?.taiKhoanId != current.user?.taiKhoanId,
      listener: (context, state) {
        if (!state.isAuthenticated ||
            state.user?.taiKhoanId != widget.user.taiKhoanId) {
          _revokeAndDismiss();
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: DiscoveryColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppDimensions.base,
          AppDimensions.base,
          AppDimensions.base,
          MediaQuery.viewInsetsOf(context).bottom + AppDimensions.base,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: DiscoveryColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: DiscoveryColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: DiscoveryColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chỉnh sửa thông tin cá nhân',
                              style: DiscoveryTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: DiscoveryColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cập nhật hồ sơ tài khoản VexGo',
                              style: DiscoveryTextStyles.caption.copyWith(
                                color: DiscoveryColors.neutral500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // Field 1: Họ và tên (Bắt buộc)
                  Text(
                    'Họ và tên *',
                    style: DiscoveryTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    onChanged: (val) {
                      if (_nameError != null && val.trim().isNotEmpty) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Nhập họ và tên đầy đủ',
                      hintStyle: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral400,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: DiscoveryColors.neutral500,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.neutral300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.neutral300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.primary,
                          width: 1.5,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.error,
                        ),
                      ),
                      errorText: _nameError,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Field 2: Số điện thoại (Read-only)
                  Text(
                    'Số điện thoại',
                    style: DiscoveryTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: DiscoveryColors.neutral100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DiscoveryColors.neutral300),
                    ),
                    child: LayoutBuilder(
                      builder: (context, phoneBox) {
                        final badge = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.user.daXacThucSoDienThoai
                                ? DiscoveryColors.successLight
                                : DiscoveryColors.neutral200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.user.daXacThucSoDienThoai
                                ? 'Đã xác thực'
                                : 'Chưa xác thực',
                            style: TextStyle(
                              color: widget.user.daXacThucSoDienThoai
                                  ? DiscoveryColors.successDark
                                  : DiscoveryColors.neutral600,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );

                        if (phoneBox.maxWidth < 260 ||
                            MediaQuery.textScalerOf(context).scale(11) > 15) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone_android_rounded,
                                    color: DiscoveryColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppDimensions.sm),
                                  Expanded(
                                    child: Text(
                                      widget.user.soDienThoai,
                                      style: DiscoveryTextStyles.bodyMedium
                                          .copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: DiscoveryColors.neutral800,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              badge,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              color: DiscoveryColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Text(
                                widget.user.soDienThoai,
                                style: DiscoveryTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: DiscoveryColors.neutral800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            badge,
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Số điện thoại dùng để đăng nhập và tra cứu vé, không thể thay đổi.',
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral500,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Field 3: Email
                  Text(
                    'Email',
                    style: DiscoveryTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DiscoveryColors.neutral800,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@vexgo.vn',
                      hintStyle: DiscoveryTextStyles.bodySmall.copyWith(
                        color: DiscoveryColors.neutral400,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: DiscoveryColors.neutral500,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.neutral300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.neutral300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: DiscoveryColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),

                  // Field 4 & 5: Số CCCD & Ngày sinh
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow =
                          constraints.maxWidth < 360 ||
                          MediaQuery.textScalerOf(context).scale(12) > 15;
                      final cccdField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Số CCCD / CMND',
                            style: DiscoveryTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral800,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          TextFormField(
                            key: _cccdFieldKey,
                            controller: _cccdController,
                            focusNode: _cccdFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '12 chữ số',
                              hintStyle: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.neutral400,
                              ),
                              prefixIcon: const Icon(
                                Icons.credit_card_outlined,
                                color: DiscoveryColors.neutral500,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.neutral300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.neutral300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      );

                      final dobField = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ngày sinh (YYYY-MM-DD)',
                            style: DiscoveryTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: DiscoveryColors.neutral800,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          TextFormField(
                            key: _dobFieldKey,
                            controller: _dobController,
                            focusNode: _dobFocusNode,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              hintText: '2002-12-22',
                              hintStyle: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.neutral400,
                              ),
                              prefixIcon: const Icon(
                                Icons.cake_outlined,
                                color: DiscoveryColors.neutral500,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.neutral300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.neutral300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: DiscoveryColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            cccdField,
                            const SizedBox(height: AppDimensions.md),
                            dobField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cccdField),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(child: dobField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.lg),

                  // Actions Dock
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final saveBtn = FilledButton(
                        onPressed: _onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: DiscoveryColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );

                      final cancelBtn = OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Hủy'),
                      );

                      if (constraints.maxWidth < 340 ||
                          MediaQuery.textScalerOf(context).scale(14) > 16) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            saveBtn,
                            const SizedBox(height: AppDimensions.sm),
                            cancelBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancelBtn),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(child: saveBtn),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
