import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../../core/network/token_storage.dart';
import '../../../../../../core/design/discovery_theme.dart';
import '../../bloc/booking_flow_bloc.dart';
import '../../bloc/booking_flow_event.dart';

/// Manual-code entry stays open until the authoritative quote accepts the code.
class PromotionCodeSheet extends StatefulWidget {
  final BookingFlowBloc bloc;
  const PromotionCodeSheet({super.key, required this.bloc});

  static Future<void> show(BuildContext context, BookingFlowBloc bloc) =>
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        requestFocus: false,
        showDragHandle: true,
        builder: (_) => PromotionCodeSheet(bloc: bloc),
      );

  @override
  State<PromotionCodeSheet> createState() => _PromotionCodeSheetState();
}

class _PromotionCodeSheetState extends State<PromotionCodeSheet> {
  late final _code = TextEditingController(
    text: widget.bloc.state.requestedPromotionCode,
  );
  final _focus = FocusNode();
  final _session = TokenStorage.sessionVersion;
  StreamSubscription<void>? _changes;
  StreamSubscription<void>? _invalidations;
  ModalRoute<dynamic>? _route;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _changes = TokenStorage.sessionChanges.listen((_) => _dismiss());
    _invalidations = TokenStorage.sessionInvalidations.listen(
      (_) => _dismiss(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route ??= ModalRoute.of(context);
  }

  void _dismiss() {
    final route = _route;
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  Future<void> _apply({bool remove = false}) async {
    if (_busy || widget.bloc.isClosed) return;
    if (_session != TokenStorage.sessionVersion) {
      _dismiss();
      return;
    }
    final code = _code.text.trim().toUpperCase();
    if (!remove && code.isEmpty) {
      setState(() => _error = 'Nhập mã khuyến mãi để tiếp tục.');
      _focus.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.bloc.applyDraftAction(
        remove ? const RemoveVoucherEvent() : ApplyPromotionCodeEvent(code),
      );
      if (!mounted || widget.bloc.isClosed) return;
      if (_session != TokenStorage.sessionVersion) {
        _dismiss();
        return;
      }
      final result = widget.bloc.state;
      if (remove ||
          (result.hasUsableQuote &&
              result.requestedPromotionCode == code &&
              result.quote?.appliedPromotionCode?.toUpperCase() == code)) {
        _dismiss();
      } else {
        setState(
          () => _error =
              result.quoteError ?? 'Chưa xác nhận được mã. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    _invalidations?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    // Follow the keyboard inset directly: do not start a second competing animation.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Mã khuyến mãi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      tooltip: 'Đóng',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Nhập mã để kiểm tra ưu đãi cho chuyến đi của bạn.'),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _code,
                  focusNode: _focus,
                  enabled: !_busy,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Nhập mã khuyến mãi',
                    hintText: 'Ví dụ: VEXGO30',
                    errorText: _error,
                    errorMaxLines: 4,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onFieldSubmitted: (_) => _apply(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _busy ? null : () => _apply(),
                    style: FilledButton.styleFrom(
                      backgroundColor: DiscoveryColors.primary,
                    ),
                    child: Text(_busy ? 'Đang kiểm tra…' : 'Áp dụng'),
                  ),
                ),
                if (widget.bloc.state.requestedPromotionCode.isNotEmpty)
                  TextButton(
                    onPressed: _busy ? null : () => _apply(remove: true),
                    child: const Text('Bỏ mã'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
