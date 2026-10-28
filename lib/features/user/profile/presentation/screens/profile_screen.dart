import 'package:go_router/go_router.dart';
import '../../../../../app/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiscoveryColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: DiscoveryColors.successDark,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: DiscoveryColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isAuthenticated = state.isAuthenticated;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base,
                vertical: AppDimensions.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Page Header
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 2,
                      bottom: AppDimensions.md,
                    ),
                    child: Text(
                      'Tài khoản',
                      style: DiscoveryTextStyles.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                  ),

                  if (state.status == AuthStatus.loading) ...[
                    const LinearProgressIndicator(
                      color: DiscoveryColors.primary,
                      backgroundColor: DiscoveryColors.primaryLight,
                    ),
                    const SizedBox(height: AppDimensions.sm),
                  ],

                  if (state.status == AuthStatus.failure && state.user == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.md),
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DiscoveryColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: DiscoveryColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Text(
                              'Không thể tải phiên đăng nhập.',
                              style: DiscoveryTextStyles.bodySmall.copyWith(
                                color: DiscoveryColors.errorDark,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.read<AuthBloc>().add(
                              const CheckAuthStatusEvent(),
                            ),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),

                  // 1. Identity Card (User vs Guest)
                  if (isAuthenticated && user != null)
                    _buildUserCard(context, user)
                  else
                    _buildGuestCard(context),

                  const SizedBox(height: AppDimensions.base),

                  // 2. Loyalty Points Card (Only for authenticated)
                  if (isAuthenticated && user != null) ...[
                    _buildPointsCard(context, user),
                    const SizedBox(height: AppDimensions.base),
                  ],

                  // 3. Account Management Group (Only for authenticated)
                  if (isAuthenticated && user != null) ...[
                    _buildSectionHeader('QUẢN LÝ TÀI KHOẢN'),
                    _buildMenuContainer([
                      _MenuRow(
                        icon: Icons.person_outline_rounded,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Họ tên, email, CCCD, ngày sinh',
                        onTap: () =>
                            EditProfileDialog.show(context, user: user),
                      ),
                      _MenuRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Cập nhật mật khẩu định kỳ để an toàn',
                        onTap: () => ChangePasswordDialog.show(context),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.base),
                  ],

                  _buildSectionHeader('HỖ TRỢ'),
                  _buildMenuContainer([
                    _MenuRow(
                      icon: Icons.forum_outlined,
                      title: 'Chat với nhà xe',
                      subtitle: 'Trao đổi trực tiếp về chuyến đi của bạn',
                      onTap: () => context.push(AppRoutes.supportChat),
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.base),

                  // 4. App Info Group
                  _buildSectionHeader('THÔNG TIN ỨNG DỤNG'),
                  _buildMenuContainer([
                    const _MenuRow(
                      icon: Icons.language_rounded,
                      title: 'Ngôn ngữ',
                      subtitle: 'Giao diện ứng dụng',
                      trailingText: 'Tiếng Việt',
                    ),
                    const _MenuRow(
                      icon: Icons.info_outline_rounded,
                      title: 'Phiên bản ứng dụng',
                      subtitle: 'Hệ thống Đặt vé xe khách VexGo',
                      trailingText: '1.0.0',
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.lg),

                  // 5. Logout Action (Only for authenticated)
                  if (isAuthenticated) ...[
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: DiscoveryColors.error,
                          size: 20,
                        ),
                        label: Text(
                          'Đăng xuất tài khoản',
                          style: DiscoveryTextStyles.bodyMedium.copyWith(
                            color: DiscoveryColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.base),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Letter Avatar
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: DiscoveryColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.hoTen.isNotEmpty ? user.hoTen[0].toUpperCase() : 'U',
                style: DiscoveryTextStyles.h1.copyWith(
                  color: DiscoveryColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.hoTen,
                        style: DiscoveryTextStyles.h4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: DiscoveryColors.neutral900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.daXacThucSoDienThoai) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: DiscoveryColors.primary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.soDienThoai,
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.neutral700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email != null && user.email!.trim().isNotEmpty
                      ? user.email!
                      : 'Chưa cập nhật email',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Edit Profile Action
          IconButton(
            onPressed: () => EditProfileDialog.show(context, user: user),
            icon: const Icon(
              Icons.edit_note_rounded,
              color: DiscoveryColors.primary,
              size: 26,
            ),
            tooltip: 'Chỉnh sửa hồ sơ',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: DiscoveryColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: DiscoveryColors.neutral500,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng bạn đến với VexGo',
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đăng nhập để đặt vé thuận tiện và quản lý thông tin chuyến đi',
                      style: DiscoveryTextStyles.caption.copyWith(
                        color: DiscoveryColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.base),
          FilledButton(
            onPressed: () => AuthModalSheet.show(context),
            style: FilledButton.styleFrom(
              backgroundColor: DiscoveryColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text(
              'ĐĂNG NHẬP / ĐĂNG KÝ',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DiscoveryColors.secondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: DiscoveryColors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Điểm tích lũy VexGo',
                  style: DiscoveryTextStyles.caption.copyWith(
                    color: DiscoveryColors.neutral600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.diemTichLuy} điểm',
                  style: DiscoveryTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    color: DiscoveryColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.xs),
      child: Text(
        title,
        style: DiscoveryTextStyles.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: DiscoveryColors.neutral500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<_MenuRow> items) {
    return Container(
      decoration: BoxDecoration(
        color: DiscoveryColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DiscoveryColors.neutral200),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: isLast ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.base,
                    vertical: 12,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTight =
                          constraints.maxWidth < 280 ||
                          MediaQuery.textScalerOf(context).scale(12) > 15;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: DiscoveryColors.primaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.icon,
                              color: DiscoveryColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: DiscoveryTextStyles.bodyMedium
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: DiscoveryColors.neutral900,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle!,
                                    style: DiscoveryTextStyles.caption.copyWith(
                                      color: DiscoveryColors.neutral500,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (isTight && item.trailingText != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.trailingText!,
                                    style: DiscoveryTextStyles.bodySmall
                                        .copyWith(
                                          color: DiscoveryColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (!isTight && item.trailingText != null) ...[
                            const SizedBox(width: AppDimensions.sm),
                            Flexible(
                              child: Text(
                                item.trailingText!,
                                style: DiscoveryTextStyles.bodySmall.copyWith(
                                  color: DiscoveryColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else if (item.onTap != null)
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: DiscoveryColors.neutral400,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 56,
                  color: DiscoveryColors.divider,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: DiscoveryColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: DiscoveryColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Đăng xuất',
                style: DiscoveryTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DiscoveryColors.neutral900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?',
          style: DiscoveryTextStyles.bodyMedium.copyWith(
            color: DiscoveryColors.neutral700,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () {
              final authBloc = context.read<AuthBloc>();
              Navigator.of(ctx).pop();
              authBloc.add(const LogoutEvent());
            },
            style: FilledButton.styleFrom(
              backgroundColor: DiscoveryColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.onTap,
  });
}
