import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class ChangePasswordScreen extends StatefulWidget {
  final int? ownerUserId;

  const ChangePasswordScreen({super.key, this.ownerUserId});

  static Future<void> show(BuildContext context, {int? ownerUserId}) {
    final authBloc = context.read<AuthBloc>();
    final effectiveOwnerId = ownerUserId ?? authBloc.state.user?.taiKhoanId;
    return Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: ChangePasswordScreen(ownerUserId: effectiveOwnerId),
        ),
      ),
    );
  }

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _oldFocus = FocusNode();
  final _nextFocus = FocusNode();
  final _confirmFocus = FocusNode();
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
    _oldFocus.dispose();
    _nextFocus.dispose();
    _confirmFocus.dispose();
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
          SnackBar(content: Text(context.l10n.uiPasswordChangedSuccessfully)),
        );
      }
    },
    buildWhen: (previous, current) =>
        previous.passwordChangeStatus != current.passwordChangeStatus ||
        previous.passwordChangeError != current.passwordChangeError ||
        previous.user?.taiKhoanId != current.user?.taiKhoanId,
    builder: (context, state) {
      final busy =
          state.passwordChangeStatus == PasswordChangeStatus.submitting;

      void submit() {
        if (_isRevoked) return;
        final currentUser = context.read<AuthBloc>().state.user;
        if (_ownerUserId != null && currentUser?.taiKhoanId != _ownerUserId) {
          _isRevoked = true;
          _clearControllers();
          _dismissOwnRoute();
          return;
        }
        if (!_form.currentState!.validate()) return;
        FocusScope.of(context).unfocus();
        setState(() => _submitted = true);
        context.read<AuthBloc>().add(
          ChangePasswordEvent(oldPassword: _old.text, newPassword: _next.text),
        );
      }

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
          focusNode: controller == _old
              ? _oldFocus
              : controller == _next
              ? _nextFocus
              : _confirmFocus,
          textInputAction: controller == _confirm
              ? TextInputAction.done
              : TextInputAction.next,
          onFieldSubmitted: (_) {
            if (busy) return;
            if (controller == _old) {
              _nextFocus.requestFocus();
            } else if (controller == _next) {
              _confirmFocus.requestFocus();
            } else {
              submit();
            }
          },
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
                  ? LocaleController.strings.uiHide(semanticLabel)
                  : LocaleController.strings.uiShow(semanticLabel),
              onPressed: busy ? null : onToggle,
            ),
          ),
          validator: validate,
        ),
      );

      return PopScope(
        canPop: !busy,
        child: Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: AppBar(
            title: Text(context.l10n.uiChangePassword),
            leading: BackButton(onPressed: busy ? null : _dismissOwnRoute),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.l10n.uiKeepYourAccountSecure,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context
                                  .l10n
                                  .uiEnterYourCurrentAndNewPasswordsDoNot,
                            ),
                            const SizedBox(height: 24),
                            Form(
                              key: _form,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  field(
                                    label: context.l10n.uiCurrentPassword,
                                    controller: _old,
                                    showPassword: _showOldPassword,
                                    onToggle: () => setState(
                                      () =>
                                          _showOldPassword = !_showOldPassword,
                                    ),
                                    semanticLabel:
                                        context.l10n.uiCurrentPassword03603d,
                                    validate: (value) =>
                                        value == null || value.isEmpty
                                        ? context
                                              .l10n
                                              .uiEnterYourCurrentPassword
                                        : null,
                                  ),
                                  field(
                                    label: context.l10n.uiNewPassword,
                                    controller: _next,
                                    showPassword: _showNewPassword,
                                    onToggle: () => setState(
                                      () =>
                                          _showNewPassword = !_showNewPassword,
                                    ),
                                    semanticLabel:
                                        context.l10n.uiNewPassword31bb86,
                                    validate: (value) {
                                      final length = utf8
                                          .encode(value ?? '')
                                          .length;
                                      if (length < 8 || length > 72) {
                                        return context
                                            .l10n
                                            .uiPasswordMustBe872Utf8Bytes;
                                      }
                                      if (value == _old.text) {
                                        return context
                                            .l10n
                                            .uiYourNewPasswordMustDifferFromYourCurrent;
                                      }
                                      return null;
                                    },
                                  ),
                                  field(
                                    label: context.l10n.uiConfirmNewPassword,
                                    controller: _confirm,
                                    showPassword: _showConfirmPassword,
                                    onToggle: () => setState(
                                      () => _showConfirmPassword =
                                          !_showConfirmPassword,
                                    ),
                                    semanticLabel:
                                        context.l10n.uiPasswordConfirmation,
                                    validate: (value) => value != _next.text
                                        ? context.l10n.uiPasswordsDoNotMatch
                                        : null,
                                  ),
                                  if (_submitted &&
                                      state.passwordChangeError != null)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        top: 4,
                                        bottom: 8,
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: DiscoveryColors.errorLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: DiscoveryColors.error
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        state.passwordChangeError!,
                                        style: DiscoveryTextStyles.caption
                                            .copyWith(
                                              color: DiscoveryColors.errorDark,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  if (busy) const LinearProgressIndicator(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: busy ? null : submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: DiscoveryColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            busy
                                ? context.l10n.uiSaving
                                : context.l10n.uiSavePassword,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
