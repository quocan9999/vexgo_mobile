import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: const ChangePasswordDialog(),
    ),
  );

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _old.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listenWhen: (previous, current) =>
        previous.passwordChangeStatus != current.passwordChangeStatus ||
        previous.isAuthenticated != current.isAuthenticated,
    listener: (context, state) {
      if (!state.isAuthenticated) {
        Navigator.of(context).pop();
      } else if (_submitted &&
          state.passwordChangeStatus == PasswordChangeStatus.success) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công.')),
        );
      }
    },
    builder: (context, state) {
      final busy =
          state.passwordChangeStatus == PasswordChangeStatus.submitting;
      Widget field(
        String label,
        TextEditingController controller,
        String? Function(String?) validate,
      ) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          key: ValueKey(label),
          controller: controller,
          enabled: !busy,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: label),
          validator: validate,
        ),
      );
      return PopScope(
        canPop: !busy,
        child: AlertDialog(
          title: const Text('Đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  field(
                    'Mật khẩu hiện tại',
                    _old,
                    (value) => value == null || value.isEmpty
                        ? 'Nhập mật khẩu hiện tại.'
                        : null,
                  ),
                  field('Mật khẩu mới', _next, (value) {
                    final length = utf8.encode(value ?? '').length;
                    if (length < 8 || length > 72) {
                      return 'Mật khẩu cần dài 8–72 byte UTF-8.';
                    }
                    if (value == _old.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại.';
                    }
                    return null;
                  }),
                  field(
                    'Xác nhận mật khẩu mới',
                    _confirm,
                    (value) => value != _next.text
                        ? 'Mật khẩu xác nhận không khớp.'
                        : null,
                  ),
                  if (_submitted && state.passwordChangeError != null)
                    Text(
                      state.passwordChangeError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () {
                      if (!_form.currentState!.validate()) return;
                      setState(() => _submitted = true);
                      context.read<AuthBloc>().add(
                        ChangePasswordEvent(
                          oldPassword: _old.text,
                          newPassword: _next.text,
                        ),
                      );
                    },
              child: const Text('Lưu mật khẩu'),
            ),
          ],
        ),
      );
    },
  );
}
