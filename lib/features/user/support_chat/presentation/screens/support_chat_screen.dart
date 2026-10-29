import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design/discovery_theme.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../data/models/operator_model.dart';
import '../../../profile/bloc/auth_bloc.dart';
import '../../../profile/bloc/auth_state.dart';
import '../../../profile/presentation/widgets/auth_modal_sheet.dart';
import '../../bloc/support_chat_cubit.dart';
import '../widgets/support_chat_composer.dart';
import '../widgets/support_chat_conversation_card.dart';
import '../widgets/support_chat_message_bubble.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _messageKeys = <int, GlobalKey>{};
  bool _readScheduled = false;
  SupportChatCubit? _cubit;
  Future<List<OperatorModel>>? _companies;
  String? _composerSession;
  int? _composerConversation;
  bool _choosing = false, _confirmClose = false;
  bool _restoreComposerFocus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_queueVisibleRead);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cubit == null) {
      _cubit = context.read<SupportChatCubit>();
      if (!ApiConfig.isDemoMode) unawaited(_cubit!.activate());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cubit?.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit?.deactivate();
    _composer.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _choose() {
    setState(() {
      _choosing = true;
      _companies = _cubit!.companies();
    });
  }

  void _toggleCloseConfirmation() {
    if (_confirmClose) {
      _keepConversation();
      return;
    }
    _restoreComposerFocus = _composerFocus.hasFocus;
    _composerFocus.unfocus();
    _cubit!.typing(false);
    setState(() => _confirmClose = true);
  }

  void _keepConversation() {
    final restoreFocus = _restoreComposerFocus;
    final session = _cubit!.state.session;
    final conversation = _cubit!.state.selected?.id;
    setState(() => _confirmClose = false);
    _restoreComposerFocus = false;
    if (restoreFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_confirmClose &&
            _cubit!.state.session == session &&
            _cubit!.state.selected?.id == conversation) {
          _composerFocus.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, auth) {
      final mediaQuery = MediaQuery.of(context);
      final isShort =
          mediaQuery.size.height < 400 ||
          (mediaQuery.size.height - mediaQuery.viewInsets.bottom < 260);

      if (!auth.isAuthenticated || ApiConfig.isDemoMode) {
        return Scaffold(
          backgroundColor: DiscoveryColors.background,
          appBar: AppBar(
            toolbarHeight: isShort ? 44 : kToolbarHeight,
            backgroundColor: DiscoveryColors.surface,
            elevation: 0,
            title: Text(
              'Chat với nhà xe',
              style: (isShort ? DiscoveryTextStyles.h4 : DiscoveryTextStyles.h3)
                  .copyWith(color: DiscoveryColors.neutral900),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: DiscoveryColors.divider),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isShort ? 54 : 72,
                    height: isShort ? 54 : 72,
                    decoration: BoxDecoration(
                      color: DiscoveryColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DiscoveryColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      size: isShort ? 30 : 40,
                      color: DiscoveryColors.primary,
                    ),
                  ),
                  SizedBox(height: isShort ? 12 : 20),
                  Text(
                    ApiConfig.isDemoMode
                        ? 'Chat cần kết nối máy chủ ở chế độ trực tuyến.'
                        : 'Đăng nhập để trò chuyện với nhà xe.',
                    textAlign: TextAlign.center,
                    style:
                        (isShort
                                ? DiscoveryTextStyles.bodyMedium
                                : DiscoveryTextStyles.bodyLarge)
                            .copyWith(
                              color: DiscoveryColors.neutral800,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                  if (!ApiConfig.isDemoMode) ...[
                    SizedBox(height: isShort ? 10 : 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DiscoveryColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isShort ? 18 : 24,
                          vertical: isShort ? 8 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => AuthModalSheet.show(context),
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontFamily: 'VexGoJakarta',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      return BlocBuilder<SupportChatCubit, SupportChatState>(
        builder: (context, state) {
          final cubit = context.read<SupportChatCubit>();
          // A mounted route must never render a prior session's payload.
          if (state.session != auth.user!.taiKhoanId.toString()) {
            return Scaffold(
              backgroundColor: DiscoveryColors.background,
              appBar: AppBar(
                toolbarHeight: isShort ? 44 : kToolbarHeight,
                backgroundColor: DiscoveryColors.surface,
                elevation: 0,
                title: Text(
                  'Chat với nhà xe',
                  style:
                      (isShort
                              ? DiscoveryTextStyles.h4
                              : DiscoveryTextStyles.h3)
                          .copyWith(color: DiscoveryColors.neutral900),
                ),
              ),
              body: const SizedBox.shrink(),
            );
          }
          if (_composerSession != state.session ||
              _composerConversation != state.selected?.id) {
            _composer.clear();
            _messageKeys.clear();
            _composerSession = state.session;
            _composerConversation = state.selected?.id;
            _confirmClose = false;
            _restoreComposerFocus = false;
          }
          final selected = state.selected;
          _queueVisibleRead();
          return PopScope(
            canPop: selected == null && !_choosing,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (selected != null) {
                cubit.backToList();
              } else {
                setState(() => _choosing = false);
              }
            },
            child: Scaffold(
              backgroundColor: DiscoveryColors.background,
              appBar: AppBar(
                toolbarHeight: isShort ? 44 : kToolbarHeight,
                backgroundColor: DiscoveryColors.surface,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: selected != null || _choosing
                    ? IconButton(
                        tooltip: 'Quay lại',
                        icon: const Icon(
                          Icons.arrow_back,
                          color: DiscoveryColors.neutral900,
                        ),
                        onPressed: () {
                          if (selected != null) {
                            cubit.backToList();
                          } else {
                            setState(() => _choosing = false);
                          }
                        },
                      )
                    : null,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selected?.companyName ??
                          (_choosing ? 'Chọn nhà xe' : 'Chat với nhà xe'),
                      style:
                          (isShort
                                  ? DiscoveryTextStyles.h4
                                  : DiscoveryTextStyles.h3)
                              .copyWith(color: DiscoveryColors.neutral900),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (selected != null)
                      Text(
                        selected.statusLabel,
                        style: TextStyle(
                          fontFamily: 'VexGoJakarta',
                          fontSize: isShort ? 10 : 12,
                          color: DiscoveryColors.neutral600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
                actions: [
                  if (selected != null && selected.canSend && !state.closing)
                    IconButton(
                      tooltip: 'Kết thúc hội thoại',
                      icon: const Icon(
                        Icons.stop_circle_outlined,
                        color: DiscoveryColors.error,
                      ),
                      onPressed: _toggleCloseConfirmation,
                    ),
                  IconButton(
                    tooltip: 'Tải lại',
                    icon: const Icon(
                      Icons.refresh,
                      color: DiscoveryColors.neutral800,
                    ),
                    onPressed: () => selected == null
                        ? cubit.loadConversations()
                        : cubit.refresh(),
                  ),
                ],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, color: DiscoveryColors.divider),
                ),
              ),
              floatingActionButton: selected == null && !_choosing
                  ? FloatingActionButton.extended(
                      backgroundColor: DiscoveryColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      onPressed: _choose,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text(
                        'Hội thoại mới',
                        style: TextStyle(
                          fontFamily: 'VexGoJakarta',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    if (!state.connected)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isShort ? 3 : 8,
                        ),
                        color: DiscoveryColors.warningLight,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_problem_rounded,
                              size: 14,
                              color: DiscoveryColors.warningDark,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Realtime đang kết nối lại. Bạn vẫn có thể gửi và tải lại tin nhắn.',
                                style: TextStyle(
                                  fontFamily: 'VexGoJakarta',
                                  fontSize: 11,
                                  color: DiscoveryColors.warningDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (state.error != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isShort ? 2 : 6,
                        ),
                        color: DiscoveryColors.errorLight,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 14,
                              color: DiscoveryColors.error,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                state.error!,
                                style: const TextStyle(
                                  fontFamily: 'VexGoJakarta',
                                  fontSize: 11,
                                  color: DiscoveryColors.error,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              tooltip: 'Thử lại',
                              icon: const Icon(
                                Icons.refresh,
                                size: 18,
                                color: DiscoveryColors.error,
                              ),
                              onPressed: () => selected == null
                                  ? cubit.loadConversations()
                                  : cubit.refresh(),
                            ),
                          ],
                        ),
                      ),
                    if (state.loading ||
                        state.historyLoading ||
                        state.creating ||
                        state.closing)
                      const LinearProgressIndicator(
                        minHeight: 2,
                        color: DiscoveryColors.primary,
                        backgroundColor: DiscoveryColors.primaryLight,
                      ),
                    Expanded(
                      child: selected != null
                          ? IndexedStack(
                              index: _confirmClose ? 1 : 0,
                              sizing: StackFit.expand,
                              children: [
                                _transcript(state),
                                SingleChildScrollView(
                                  key: const ValueKey(
                                    'chat-close-confirmation-scroll',
                                  ),
                                  child: _closeConfirmation(cubit),
                                ),
                              ],
                            )
                          : _choosing
                          ? _companyList(state)
                          : _conversationList(state),
                    ),
                    if (selected != null) ...[
                      if (state.typing && !_confirmClose)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: isShort ? 2 : 6,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: DiscoveryColors.neutral500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Nhân viên đang nhập…',
                                style: TextStyle(
                                  fontFamily: 'VexGoJakarta',
                                  fontSize: 12,
                                  color: DiscoveryColors.neutral600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (selected.canSend && !state.closing)
                        Visibility(
                          visible: !_confirmClose,
                          maintainState: true,
                          child: _input(state, isDense: isShort),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isShort ? 8 : 14),
                          decoration: const BoxDecoration(
                            color: DiscoveryColors.neutral100,
                            border: Border(
                              top: BorderSide(color: DiscoveryColors.divider),
                            ),
                          ),
                          child: const Text(
                            'Hội thoại đã kết thúc hoặc chưa thể gửi tin. Mở hội thoại mới để được hỗ trợ.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'VexGoJakarta',
                              fontSize: 12,
                              color: DiscoveryColors.neutral600,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _closeConfirmation(SupportChatCubit cubit) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DiscoveryColors.warningLight,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: DiscoveryColors.warning.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 18,
              color: DiscoveryColors.warningDark,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.',
                style: DiscoveryTextStyles.bodyMedium.copyWith(
                  color: DiscoveryColors.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          spacing: 8,
          overflowSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: _keepConversation,
              child: const Text('Giữ hội thoại'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: DiscoveryColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _restoreComposerFocus = false;
                setState(() => _confirmClose = false);
                unawaited(cubit.closeConversation());
              },
              child: const Text('Kết thúc'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _companyList(SupportChatState state) =>
      FutureBuilder<List<OperatorModel>>(
        future: _companies,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: _choose,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Không tải được nhà xe. Thử lại'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: DiscoveryColors.primary),
            );
          }
          final companies = snapshot.data!
              .where((c) => int.tryParse(c.id) != null)
              .toList();
          if (companies.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có nhà xe để liên hệ.',
                style: TextStyle(
                  fontFamily: 'VexGoJakarta',
                  color: DiscoveryColors.neutral600,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: DiscoveryColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: DiscoveryColors.neutral200),
                ),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: DiscoveryColors.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DiscoveryColors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_outlined,
                      color: DiscoveryColors.primary,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    company.name,
                    style: DiscoveryTextStyles.h4.copyWith(
                      color: DiscoveryColors.neutral900,
                    ),
                  ),
                  subtitle: Text(
                    'Mở hoặc tiếp tục hội thoại',
                    style: DiscoveryTextStyles.bodySmall.copyWith(
                      color: DiscoveryColors.neutral600,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: DiscoveryColors.neutral400,
                  ),
                  enabled: !state.creating,
                  onTap: () async {
                    final session = state.session;
                    await _cubit!.start(int.parse(company.id));
                    if (mounted &&
                        _cubit!.state.session == session &&
                        _cubit!.state.selected != null) {
                      setState(() => _choosing = false);
                    }
                  },
                ),
              );
            },
          );
        },
      );

  Widget _conversationList(SupportChatState state) {
    final cubit = context.read<SupportChatCubit>();
    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () => cubit.loadConversations(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        children: [
          if (state.conversations.isEmpty && !state.loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: DiscoveryColors.neutral100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      size: 38,
                      color: DiscoveryColors.neutral400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có hội thoại nào. Chọn “Hội thoại mới” để liên hệ nhà xe.',
                    textAlign: TextAlign.center,
                    style: DiscoveryTextStyles.bodyMedium.copyWith(
                      color: DiscoveryColors.neutral600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          for (final conversation in state.conversations)
            SupportChatConversationCard(
              conversation: conversation,
              onTap: () => cubit.select(conversation),
            ),
          if (state.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: state.loading
                      ? null
                      : () => cubit.loadConversations(more: true),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: const Text('Tải thêm hội thoại'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _transcript(SupportChatState state) {
    final messages = state.messages.reversed.toList(),
        cubit = context.read<SupportChatCubit>();
    return RefreshIndicator(
      color: DiscoveryColors.primary,
      onRefresh: () => cubit.refresh(),
      child: SizedBox(
        key: _viewportKey,
        child: ListView.builder(
          key: ValueKey('transcript-${state.session}-${state.selected!.id}'),
          controller: _scroll,
          reverse: true,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: messages.length + 1,
          itemBuilder: (context, index) {
            if (index == messages.length) {
              if (state.hasOlder) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextButton.icon(
                      onPressed: state.historyLoading
                          ? null
                          : () => cubit.refresh(older: true),
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Tải tin nhắn trước'),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  messages.isEmpty
                      ? 'Chưa có tin nhắn. Gửi lời chào để bắt đầu.'
                      : 'Bắt đầu hội thoại',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'VexGoJakarta',
                    fontSize: 13,
                    color: DiscoveryColors.neutral500,
                  ),
                ),
              );
            }
            final message = messages[index],
                own = message.senderId.toString() == state.session;
            final system = message.senderType == 'HE_THONG';
            return Container(
              key: message.id == null
                  ? ValueKey(message.clientId)
                  : _messageKeys.putIfAbsent(message.id!, GlobalKey.new),
              child: SupportChatMessageBubble(
                message: message,
                isOwn: own,
                isSystem: system,
                canSend: state.selected!.canSend,
                onRetry: () => cubit.retry(message),
              ),
            );
          },
        ),
      ),
    );
  }

  void _queueVisibleRead() {
    if (_readScheduled || !mounted) return;
    _readScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readScheduled = false;
      if (!mounted ||
          _confirmClose ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final cubit = _cubit;
      if (cubit == null ||
          cubit.state.historyLoading ||
          cubit.state.selected == null) {
        return;
      }
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (viewport is! RenderBox || !viewport.hasSize) return;
      final bounds = viewport.localToGlobal(Offset.zero) & viewport.size;
      final visible = <int>[];
      for (final entry in _messageKeys.entries) {
        final render = entry.value.currentContext?.findRenderObject();
        if (render is RenderBox &&
            render.hasSize &&
            bounds.overlaps(render.localToGlobal(Offset.zero) & render.size)) {
          visible.add(entry.key);
        }
      }
      unawaited(cubit.markRead(visible));
    });
  }

  Widget _input(SupportChatState state, {bool isDense = false}) =>
      SupportChatComposer(
        controller: _composer,
        focusNode: _composerFocus,
        isDense: isDense,
        onChanged: (text) => _cubit!.typing(text.trim().isNotEmpty),
        onSend: () {
          final text = _composer.text.trim();
          if (text.isEmpty) return;
          _composer.clear();
          _cubit!.typing(false);
          unawaited(_cubit!.send(text));
          if (_scroll.hasClients) {
            _scroll.animateTo(
              0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        },
      );
}
