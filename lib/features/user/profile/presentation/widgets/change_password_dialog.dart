import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class ChangePasswordDialog extends StatefulWidget {
  final int? ownerUserId;

  const ChangePasswordDialog({super.key, this.ownerUserId});

  static Future<void> show(BuildContext context, {int? ownerUserId}) {
    final authBloc = context.read<AuthBloc>();
    final effectiveOwnerId = ownerUserId ?? authBloc.state.user?.taiKhoanId;
    return showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: authBloc,
        child: ChangePasswordDialog(ownerUserId: effectiveOwnerId),
      ),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _isRevoked = false;
  int? _ownerUserId;
  ModalRoute<dynamic>? _route;

  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ownerUserId ??=
        widget.ownerUserId ?? context.read<AuthBloc>().state.user?.taiKhoanId;
    _route ??= ModalRoute.of(context);
  }

  void _dismissOwnRoute() {
    final route = _route;
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  void _clearControllers() {
    _old.clear();
    _next.clear();
    _confirm.clear();
  }

  @override
  void dispose() {
    _clearControllers();
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listenWhen: (previous, current) =>
        previous.passwordChangeStatus != current.passwordChangeStatus ||
        previous.isAuthenticated != current.isAuthenticated ||
        previous.user?.taiKhoanId != current.user?.taiKhoanId,
    listener: (context, state) {
      final ownerChanged =
          _ownerUserId != null && state.user?.taiKhoanId != _ownerUserId;
      if (!state.isAuthenticated || ownerChanged) {
        _isRevoked = true;
        _clearControllers();
        _dismissOwnRoute();
      } else if (_submitted &&
          state.passwordChangeStatus == PasswordChangeStatus.success) {
        final messenger = ScaffoldMessenger.of(context);
        _dismissOwnRoute();
        messenger.showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công.')),
        );
      }
    },
    builder: (context, state) {
      final busy =
          state.passwordChangeStatus == PasswordChangeStatus.submitting;

      Widget field({
        required String label,
        required TextEditingController controller,
        required bool showPassword,
        required VoidCallback onToggle,
        required String semanticLabel,
        required String? Function(String?) validate,
      }) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          key: ValueKey(label),
          controller: controller,
          enabled: !busy,
          obscureText: !showPassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: DiscoveryTextStyles.bodySmall.copyWith(
              color: DiscoveryColors.neutral600,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DiscoveryColors.neutral300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: DiscoveryColors.neutral300),
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
              borderSide: const BorderSide(color: DiscoveryColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: DiscoveryColors.neutral500,
                size: 20,
              ),
              tooltip: showPassword
                  ? 'Ẩn $semanticLabel'
                  : 'Hiện $semanticLabel',
              onPressed: busy ? null : onToggle,
            ),
          ),
          validator: validate,
        ),
      );

      return PopScope(
        canPop: !busy,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DiscoveryColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  color: DiscoveryColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đổi mật khẩu',
                  style: DiscoveryTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DiscoveryColors.neutral900,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field(
                    label: 'Mật khẩu hiện tại',
                    controller: _old,
                    showPassword: _showOldPassword,
                    onToggle: () =>
                        setState(() => _showOldPassword = !_showOldPassword),
                    semanticLabel: 'mật khẩu hiện tại',
                    validate: (value) => value == null || value.isEmpty
                        ? 'Nhập mật khẩu hiện tại.'
                        : null,
                  ),
                  field(
                    label: 'Mật khẩu mới',
                    controller: _next,
                    showPassword: _showNewPassword,
                    onToggle: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                    semanticLabel: 'mật khẩu mới',
                    validate: (value) {
                      final length = utf8.encode(value ?? '').length;
                      if (length < 8 || length > 72) {
                        return 'Mật khẩu cần dài 8–72 byte UTF-8.';
                      }
                      if (value == _old.text) {
                        return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
                      }
                      return null;
                    },
                  ),
                  field(
                    label: 'Xác nhận mật khẩu mới',
                    controller: _confirm,
                    showPassword: _showConfirmPassword,
                    onToggle: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                    semanticLabel: 'mật khẩu xác nhận',
                    validate: (value) => value != _next.text
                        ? 'Mật khẩu xác nhận không khớp.'
                        : null,
                  ),
                  if (_submitted && state.passwordChangeError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DiscoveryColors.errorLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DiscoveryColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        state.passwordChangeError!,
                        style: DiscoveryTextStyles.caption.copyWith(
                          color: DiscoveryColors.errorDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : _dismissOwnRoute,
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (_isRevoked) return;
                      final currentUser = context.read<AuthBloc>().state.user;
                      if (_ownerUserId != null &&
                          currentUser?.taiKhoanId != _ownerUserId) {
                        _isRevoked = true;
                        _clearControllers();
                        _dismissOwnRoute();
                        return;
                      }
                      if (!_form.currentState!.validate()) return;
                      setState(() => _submitted = true);
                      context.read<AuthBloc>().add(
                        ChangePasswordEvent(
                          oldPassword: _old.text,
                          newPassword: _next.text,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: DiscoveryColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lưu mật khẩu',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    },
  );
}
