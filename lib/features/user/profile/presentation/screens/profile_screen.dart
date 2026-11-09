import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/features/user/app_info/presentation/screens/app_information_screen.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';
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
import 'change_password_screen.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TabPageHeader(title: context.l10n.uiAccount),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizedClientLabel(context, state.successMessage!),
                ),
                backgroundColor: DiscoveryColors.successDark,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  localizedClientLabel(context, state.errorMessage!),
                ),
                backgroundColor: DiscoveryColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final user = state.user;
          final isAuthenticated = state.isAuthenticated;

          return SafeArea(
            top: false,
            child: ListView(
              children: [
                if (state.status == AuthStatus.loading)
                  const LinearProgressIndicator(),
                if (state.status == AuthStatus.failure && user == null)
                  ListTile(
                    title: Text(context.l10n.uiUnableToLoadYourSession),
                    trailing: TextButton(
                      onPressed: () => context.read<AuthBloc>().add(
                        const CheckAuthStatusEvent(),
                      ),
                      child: Text(context.l10n.uiTryAgain),
                    ),
                  ),
                if (isAuthenticated && user != null)
                  _buildUserCard(context, user)
                else
                  _buildGuestCard(context),
                const Divider(height: 1, color: DiscoveryColors.neutral200),
                _buildMenuList([
                  if (isAuthenticated && user != null) ...[
                    _MenuRow(
                      icon: Icons.stars_outlined,
                      title: context.l10n.uiVexgoPoints,
                      trailingText: context.l10n.uiPoints746cfa(
                        user.diemTichLuy,
                      ),
                    ),
                    _MenuRow(
                      icon: Icons.person_outline_rounded,
                      title: context.l10n.uiPersonalInformation,
                      onTap: () => EditProfileDialog.show(context, user: user),
                    ),
                    _MenuRow(
                      icon: Icons.lock_outline_rounded,
                      title: context.l10n.uiChangePassword,
                      onTap: () => ChangePasswordScreen.show(context),
                    ),
                  ],
                  _MenuRow(
                    icon: Icons.forum_outlined,
                    title: context.l10n.uiChatWithOperator,
                    onTap: () => context.push(AppRoutes.supportChat),
                  ),
                  _MenuRow(
                    icon: Icons.smart_toy_outlined,
                    title: context.l10n.uiAiAssistant,
                    onTap: () => context.push(AppRoutes.aiChatbot),
                  ),
                  _MenuRow(
                    icon: Icons.info_outline_rounded,
                    title: context.l10n.uiAboutVexgo,
                    onTap: () => openAppInformation(
                      context,
                      const AppInformationScreen(),
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.language_rounded,
                    title: context.l10n.uiLanguage,
                    trailingText: context.l10n.localeName == 'en'
                        ? 'English'
                        : context.l10n.uiTiNgViT,
                    onTap: () => _selectLanguage(context),
                  ),
                ]),
                if (isAuthenticated) ...[
                  const Divider(height: 1, color: DiscoveryColors.neutral200),
                  _buildMenuList([
                    _MenuRow(
                      icon: Icons.logout_rounded,
                      title: context.l10n.uiSignOut6827e6,
                      color: DiscoveryColors.error,
                      onTap: () => _confirmLogout(context),
                    ),
                  ]),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Text(
                    context.l10n.uiVersion100,
                    textAlign: TextAlign.center,
                    style: DiscoveryTextStyles.caption.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final controller = LocaleController.instance;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(sheetContext.l10n.uiLanguage)),
            for (final option in {
              'vi': context.l10n.uiTiNgViT,
              'en': 'English',
            }.entries)
              ListTile(
                title: Text(option.value),
                selected: controller.value.languageCode == option.key,
                trailing: controller.value.languageCode == option.key
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option.key),
              ),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    try {
      await controller.select(chosen);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            chosen == 'en'
                ? 'Language changed for this session. Unable to save your preference.'
                : context.l10n.uiLanguageChangedForThisSessionUnableToSave,
          ),
        ),
      );
    }
  }

  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      : context.l10n.uiNoEmailAdded,
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
            tooltip: context.l10n.uiEditProfile,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                      context.l10n.uiWelcomeToVexgo,
                      style: DiscoveryTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DiscoveryColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.uiSignInForEasierBookingAndToManage,
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
            child: Text(
              context.l10n.uiSignInSignUp,
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(List<_MenuRow> items) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            const Divider(
              height: 1,
              indent: 56,
              endIndent: 20,
              color: DiscoveryColors.neutral200,
            ),
          _buildMenuRow(items[index]),
        ],
      ],
    );
  }

  Widget _buildMenuRow(_MenuRow item) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackValue =
                    constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                final value = Text(
                  item.trailingText ?? '',
                  style: DiscoveryTextStyles.bodyMedium.copyWith(
                    color: DiscoveryColors.neutral600,
                  ),
                );
                return Row(
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: item.color ?? DiscoveryColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: DiscoveryTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: item.color ?? DiscoveryColors.neutral900,
                            ),
                          ),
                          if (stackValue && item.trailingText != null) ...[
                            const SizedBox(height: 4),
                            value,
                          ],
                        ],
                      ),
                    ),
                    if (!stackValue && item.trailingText != null) ...[
                      const SizedBox(width: 12),
                      Flexible(child: value),
                    ],
                    if (item.onTap != null) ...[
                      const SizedBox(width: 8),
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: DiscoveryColors.neutral500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
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
                context.l10n.uiSignOut,
                style: DiscoveryTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: DiscoveryColors.neutral900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.uiAreYouSureYouWantToSignOut,
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
            child: Text(context.l10n.uiStay),
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
            child: Text(
              context.l10n.uiSignOut,
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
  final Color? color;
  final String? trailingText;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.color,
    this.trailingText,
    this.onTap,
  });
}
