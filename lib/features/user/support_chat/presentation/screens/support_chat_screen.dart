import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_config.dart';
import '../../../../../data/models/operator_model.dart';
import '../../../../../data/models/support_chat_model.dart';
import '../../../profile/bloc/auth_bloc.dart';
import '../../../profile/bloc/auth_state.dart';
import '../../../profile/presentation/widgets/auth_modal_sheet.dart';
import '../../bloc/support_chat_cubit.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});
  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _messageKeys = <int, GlobalKey>{};
  bool _readScheduled = false;
  SupportChatCubit? _cubit;
  Future<List<OperatorModel>>? _companies;
  String? _composerSession;
  int? _composerConversation;
  bool _choosing = false, _confirmClose = false;
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
    _scroll.dispose();
    super.dispose();
  }

  void _choose() {
    setState(() {
      _choosing = true;
      _companies = _cubit!.companies();
    });
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, auth) {
      if (!auth.isAuthenticated || ApiConfig.isDemoMode) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chat với nhà xe')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ApiConfig.isDemoMode
                        ? 'Chat cần kết nối máy chủ ở chế độ trực tuyến.'
                        : 'Đăng nhập để trò chuyện với nhà xe.',
                    textAlign: TextAlign.center,
                  ),
                  if (!ApiConfig.isDemoMode)
                    TextButton(
                      onPressed: () => AuthModalSheet.show(context),
                      child: const Text('Đăng nhập'),
                    ),
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
              appBar: AppBar(title: const Text('Chat với nhà xe')),
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
              backgroundColor: AppColors.background,
              appBar: AppBar(
                leading: selected != null || _choosing
                    ? IconButton(
                        tooltip: 'Quay lại',
                        icon: const Icon(Icons.arrow_back),
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
                  children: [
                    Text(
                      selected?.companyName ??
                          (_choosing ? 'Chọn nhà xe' : 'Chat với nhà xe'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selected != null)
                      Text(
                        selected.statusLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.neutral600,
                        ),
                      ),
                  ],
                ),
                actions: [
                  if (selected != null && selected.canSend && !state.closing)
                    IconButton(
                      tooltip: 'Kết thúc hội thoại',
                      icon: const Icon(Icons.stop_circle_outlined),
                      onPressed: () =>
                          setState(() => _confirmClose = !_confirmClose),
                    ),
                  IconButton(
                    tooltip: 'Tải lại',
                    icon: const Icon(Icons.refresh),
                    onPressed: () => selected == null
                        ? cubit.loadConversations()
                        : cubit.refresh(),
                  ),
                ],
              ),
              floatingActionButton: selected == null && !_choosing
                  ? FloatingActionButton.extended(
                      onPressed: _choose,
                      icon: const Icon(Icons.add_comment_outlined),
                      label: const Text('Hội thoại mới'),
                    )
                  : null,
              body: SafeArea(
                child: Column(
                  children: [
                    if (!state.connected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        color: AppColors.warningLight,
                        child: const Text(
                          'Realtime đang kết nối lại. Bạn vẫn có thể gửi và tải lại tin nhắn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (state.error != null)
                      Material(
                        color: AppColors.errorLight,
                        child: ListTile(
                          dense: true,
                          title: Text(state.error!),
                          trailing: IconButton(
                            tooltip: 'Thử lại',
                            icon: const Icon(Icons.refresh),
                            onPressed: () => selected == null
                                ? cubit.loadConversations()
                                : cubit.refresh(),
                          ),
                        ),
                      ),
                    if (state.loading ||
                        state.historyLoading ||
                        state.creating ||
                        state.closing)
                      const LinearProgressIndicator(minHeight: 2),
                    if (_confirmClose && selected != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.',
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _confirmClose = false),
                                  child: const Text('Giữ hội thoại'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _confirmClose = false);
                                    unawaited(cubit.closeConversation());
                                  },
                                  child: const Text('Kết thúc'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: selected != null
                          ? _transcript(state)
                          : _choosing
                          ? _companyList(state)
                          : _conversationList(state),
                    ),
                    if (selected != null) ...[
                      if (state.typing)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Nhân viên đang nhập…',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.neutral500,
                            ),
                          ),
                        ),
                      if (selected.canSend && !state.closing)
                        _input(state)
                      else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Hội thoại đã kết thúc hoặc chưa thể gửi tin. Mở hội thoại mới để được hỗ trợ.',
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
  Widget _companyList(SupportChatState state) =>
      FutureBuilder<List<OperatorModel>>(
        future: _companies,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _choose,
                child: const Text('Không tải được nhà xe. Thử lại'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final companies = snapshot.data!
              .where((c) => int.tryParse(c.id) != null)
              .toList();
          if (companies.isEmpty) {
            return const Center(child: Text('Chưa có nhà xe để liên hệ.'));
          }
          return ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.directions_bus_outlined),
                ),
                title: Text(company.name),
                subtitle: const Text('Mở hoặc tiếp tục hội thoại'),
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
              );
            },
          );
        },
      );
  Widget _conversationList(SupportChatState state) {
    final cubit = context.read<SupportChatCubit>();
    return RefreshIndicator(
      onRefresh: () => cubit.loadConversations(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        children: [
          if (state.conversations.isEmpty && !state.loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 56,
                    color: AppColors.neutral400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa có hội thoại nào. Chọn “Hội thoại mới” để liên hệ nhà xe.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          for (final conversation in state.conversations)
            Card(
              elevation: 0,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.support_agent, color: AppColors.primary),
                ),
                title: Text(
                  conversation.companyName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${conversation.statusLabel}\n${conversation.preview ?? conversation.title}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => cubit.select(conversation),
              ),
            ),
          if (state.hasMore)
            TextButton(
              onPressed: state.loading
                  ? null
                  : () => cubit.loadConversations(more: true),
              child: const Text('Tải thêm hội thoại'),
            ),
        ],
      ),
    );
  }

  Widget _transcript(SupportChatState state) {
    final messages = state.messages.reversed.toList(),
        cubit = context.read<SupportChatCubit>();
    return RefreshIndicator(
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
                return TextButton(
                  onPressed: state.historyLoading
                      ? null
                      : () => cubit.refresh(older: true),
                  child: const Text('Tải tin nhắn trước'),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  messages.isEmpty
                      ? 'Chưa có tin nhắn. Gửi lời chào để bắt đầu.'
                      : 'Bắt đầu hội thoại',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.neutral500),
                ),
              );
            }
            final message = messages[index],
                own = message.senderId.toString() == state.session;
            final system = message.senderType == 'HE_THONG';
            return Align(
              alignment: system
                  ? Alignment.center
                  : own
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                key: message.id == null
                    ? ValueKey(message.clientId)
                    : _messageKeys.putIfAbsent(message.id!, GlobalKey.new),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: system
                      ? AppColors.neutral100
                      : own
                      ? AppColors.primaryLight
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!own && !system)
                      const Text(
                        'Nhân viên hỗ trợ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.neutral500,
                        ),
                      ),
                    SelectableText(
                      message.type == 'HINH_ANH'
                          ? '[Hình ảnh] ${message.content}'
                          : message.content,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${message.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${message.createdAt.toLocal().minute.toString().padLeft(2, '0')}${own ? ' • ${switch (message.delivery) {
                              ChatDelivery.sending => 'Đang gửi…',
                              ChatDelivery.failed => 'Chưa xác nhận gửi',
                              ChatDelivery.sent => message.read ? 'Đã đọc' : 'Đã gửi',
                            }}' : ''}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.neutral500,
                      ),
                    ),
                    if (own && message.delivery == ChatDelivery.failed)
                      TextButton(
                        onPressed: state.selected!.canSend
                            ? () => cubit.retry(message)
                            : null,
                        child: const Text('Thử gửi lại'),
                      ),
                  ],
                ),
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
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
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

  Widget _input(SupportChatState state) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('chat-composer'),
            controller: _composer,
            minLines: 1,
            maxLines: 5,
            maxLength: 2000,
            onChanged: (text) => _cubit!.typing(text.trim().isNotEmpty),
            decoration: const InputDecoration(
              hintText: 'Nhắn tin cho nhà xe…',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Gửi tin nhắn',
          icon: const Icon(Icons.send_rounded, color: AppColors.primary),
          onPressed: () {
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
        ),
      ],
    ),
  );
}
