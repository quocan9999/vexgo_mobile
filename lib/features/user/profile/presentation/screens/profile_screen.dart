import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/constants/app_colors.dart';
import 'package:vexgo_app/core/constants/app_dimensions.dart';
import 'package:vexgo_app/core/constants/app_text_styles.dart';
import 'package:vexgo_app/core/widgets/custom_button.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../widgets/auth_modal_sheet.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/loyalty_card_widget.dart';
import '../widgets/loyalty_history_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isAuthenticated = state.isAuthenticated;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base, vertical: AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Profile Header
                  if (isAuthenticated && user != null)
                    _buildUserHeader(context, user)
                  else
                    _buildGuestHeader(context),

                  const SizedBox(height: AppDimensions.base),

                  // 2. Loyalty VIP Card (If authenticated)
                  if (isAuthenticated && user != null) ...[
                    LoyaltyCardWidget(user: user),
                    const SizedBox(height: AppDimensions.base),
                    _buildQuickStats(context, user),
                    const SizedBox(height: AppDimensions.base),
                  ],

                  // 3. Menu Sections
                  if (isAuthenticated && user != null) ...[
                    _buildSectionTitle('QUẢN LÝ TÀI KHOẢN'),
                    _buildMenuCard([
                      _MenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Thông tin cá nhân',
                        subtitle: 'Họ tên, email, CCCD, ngày sinh',
                        onTap: () => EditProfileDialog.show(context, user: user),
                      ),
                      _MenuItem(
                        icon: Icons.lock_outline_rounded,
                        title: 'Đổi mật khẩu',
                        subtitle: 'Cập nhật mật khẩu định kỳ để an toàn',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng Đổi mật khẩu đã sẵn sàng!')),
                          );
                        },
                      ),
                      _MenuItem(
                        icon: Icons.people_outline_rounded,
                        title: 'Danh sách hành khách thường xuyên',
                        subtitle: 'Lưu thông tin để đặt vé nhanh hơn',
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.base),

                    _buildSectionTitle('ĐIỂM THƯỞNG & ƯU ĐÃI'),
                    _buildMenuCard([
                      _MenuItem(
                        icon: Icons.stars_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Lịch sử điểm VexGo Points',
                        subtitle: 'Tích điểm mỗi chuyến đi, đổi voucher giảm giá',
                        onTap: () => LoyaltyHistorySheet.show(context, user: user),
                      ),
                      _MenuItem(
                        icon: Icons.confirmation_number_outlined,
                        iconColor: AppColors.primary,
                        title: 'Ví Voucher & Khuyến mãi',
                        subtitle: 'Mã giảm giá đang có hiệu lực',
                        onTap: () {},
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.base),
                  ],

                  _buildSectionTitle('CÀI ĐẶT ỨNG DỤNG'),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.language_rounded,
                      title: 'Ngôn ngữ (Language)',
                      trailing: Text(
                        state.language == 'en' ? 'English' : 'Tiếng Việt',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        final next = state.language == 'vi' ? 'en' : 'vi';
                        context.read<AuthBloc>().add(ToggleLanguageEvent(next));
                      },
                    ),
                    _MenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Thông báo đẩy',
                      trailing: Switch(
                        value: state.pushEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          context.read<AuthBloc>().add(TogglePushNotificationEvent(val));
                        },
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.fingerprint_rounded,
                      title: 'Đăng nhập sinh trắc học',
                      trailing: Switch(
                        value: true,
                        activeThumbColor: AppColors.primary,
                        onChanged: (_) {},
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.base),

                  _buildSectionTitle('HỖ TRỢ & THÔNG TIN'),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.headset_mic_outlined,
                      title: 'Tổng đài chăm sóc khách hàng',
                      subtitle: '1900 8888 (24/7, 1.000đ/phút)',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Tổng đài hỗ trợ VexGo'),
                            content: const Text('Quý khách vui lòng gọi 1900 8888 để được giải đáp thắc mắc và hỗ trợ đặt vé khẩn cấp.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.policy_outlined,
                      title: 'Quy chế hoạt động & Chính sách',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Về ứng dụng VexGo',
                      subtitle: 'Phiên bản 1.0.0 (Đồ án Khóa luận Tốt nghiệp)',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.lg),

                  // 4. Logout / Login CTA
                  if (isAuthenticated)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _confirmLogout(context),
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        label: Text(
                          'Đăng xuất tài khoản',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: AppDimensions.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          // Avatar with badge
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.hoTen.isNotEmpty ? user.hoTen[0].toUpperCase() : 'U',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
            ],
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
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.soDienThoai,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            onPressed: () => EditProfileDialog.show(context, user: user),
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
            tooltip: 'Chỉnh sửa hồ sơ',
          ),
        ],
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: AppColors.neutral500, size: 28),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng bạn đến với VexGo',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Đăng nhập để tích điểm và nhận ưu đãi độc quyền',
                      style: AppTextStyles.caption.copyWith(color: AppColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          CustomButton(
            text: 'ĐĂNG NHẬP / ĐĂNG KÝ',
            width: double.infinity,
            type: ButtonType.primary,
            onPressed: () => AuthModalSheet.show(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.md, horizontal: AppDimensions.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('12', 'Chuyến đã đi', Icons.directions_bus_rounded, AppColors.primary),
          ),
          Container(width: 1, height: 32, color: AppColors.neutral200),
          Expanded(
            child: _buildStatItem('${user.diemTichLuy}', 'Điểm VexGo', Icons.stars_rounded, AppColors.secondary),
          ),
          Container(width: 1, height: 32, color: AppColors.neutral200),
          Expanded(
            child: _buildStatItem('3', 'Voucher', Icons.card_giftcard_rounded, const Color(0xFF0F9D58)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.neutral500, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppDimensions.xs),
      child: Text(
        title,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.neutral500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.neutral200),
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
                  top: idx == 0 ? const Radius.circular(AppDimensions.radiusLg) : Radius.zero,
                  bottom: isLast ? const Radius.circular(AppDimensions.radiusLg) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.base,
                    vertical: AppDimensions.md - 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (item.iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.iconColor ?? AppColors.primary,
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item.subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.neutral500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      item.trailing ??
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.neutral400,
                          ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 56),
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
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const LogoutEvent());
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}
