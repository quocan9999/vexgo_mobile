import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/constants/app_typography.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/ai_chatbot_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/ai_chatbot/ai_chatbot_cubit.dart';
import '../widgets/ai_chatbot_composer.dart';
import '../widgets/ai_chatbot_exchange_item.dart';
import '../widgets/ai_chatbot_status_banners.dart';
import '../widgets/ai_chatbot_suggestions_view.dart';

class AiChatbotScreen extends StatefulWidget {
  final AiChatbotCubit? cubit;
  final AiChatbotRepository? repository;
  final TripRepository? tripRepository;
  final int? initialCompanyId;
  final void Function(TripModel trip, DateTime departureDate)?
  onOpenVerifiedTrip;
  final VoidCallback? onOpenSupportChat;

  const AiChatbotScreen({
    super.key,
    this.cubit,
    this.repository,
    this.tripRepository,
    this.initialCompanyId,
    this.onOpenVerifiedTrip,
    this.onOpenSupportChat,
  });

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  late final AiChatbotCubit _cubit;
  late final bool _ownsCubit;
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<void>? _sessionChangesSub;
  StreamSubscription<void>? _sessionInvalidationsSub;

  String? _pendingSentQuestion;
  int? _verifyingTripId;
  int _tripLookupGeneration = 0;
  String? _tripLookupError;
  bool _showNewConversationConfirm = false;
  int _lastExchangeCount = 0;

  @override
  void initState() {
    super.initState();
    _ownsCubit = widget.cubit == null;
    _cubit =
        widget.cubit ??
        AiChatbotCubit(
          repository: widget.repository ?? RealAiChatbotRepository(),
          companyId: widget.initialCompanyId,
        );
    _composerController.text = _cubit.state.draft;
    _lastExchangeCount = _cubit.state.exchanges.length;

    _sessionChangesSub = TokenStorage.sessionChanges.listen((_) {
      _handleIdentityReset();
    });
    _sessionInvalidationsSub = TokenStorage.sessionInvalidations.listen((_) {
      _handleIdentityReset();
    });

    if (_cubit.state.suggestions.isEmpty && !_cubit.state.loadingSuggestions) {
      unawaited(_cubit.loadSuggestions());
    }
  }

  void _handleIdentityReset() {
    _tripLookupGeneration++;
    if (!mounted) return;
    setState(() {
      _pendingSentQuestion = null;
      _verifyingTripId = null;
      _tripLookupError = null;
      _showNewConversationConfirm = false;
    });
    _syncControllerWithDraft('');
    unawaited(_cubit.loadSuggestions());
  }

  void _syncControllerWithDraft(String targetDraft) {
    if (_composerController.text == targetDraft) return;
    _composerController.value = TextEditingValue(
      text: targetDraft,
      selection: TextSelection.collapsed(offset: targetDraft.length),
    );
  }

  @override
  void dispose() {
    _tripLookupGeneration++;
    _sessionChangesSub?.cancel();
    _sessionInvalidationsSub?.cancel();
    _composerController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    if (_ownsCubit) {
      unawaited(_cubit.close());
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        maxScroll,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handleSend() {
    final trimmed = _cubit.state.draft.trim();
    if (trimmed.isNotEmpty && trimmed.runes.length <= 2000) {
      setState(() {
        _pendingSentQuestion = trimmed;
        _tripLookupError = null;
      });
    }
    unawaited(_cubit.send());
    _scrollToBottom();
  }

  void _handleQuickAsk(String question) {
    if (_cubit.state.sending ||
        _cubit.state.loadingHistory ||
        _cubit.state.uncertain) {
      return;
    }
    _syncControllerWithDraft(question);
    _cubit.setDraft(question);
    _handleSend();
  }

  void _handleFillDraft(String question) {
    _syncControllerWithDraft(question);
    _cubit.setDraft(question);
    _composerFocusNode.requestFocus();
  }

  void _handleStartNewConversation({required bool keepDraft}) {
    _tripLookupGeneration++;
    setState(() {
      _showNewConversationConfirm = false;
      _pendingSentQuestion = null;
      _verifyingTripId = null;
      _tripLookupError = null;
    });
    _cubit.newConversation(keepDraft: keepDraft);
    _syncControllerWithDraft(_cubit.state.draft);
    if (_cubit.state.suggestions.isEmpty && !_cubit.state.loadingSuggestions) {
      unawaited(_cubit.loadSuggestions());
    }
  }

  TripRepository? _resolveTripRepository(BuildContext context) {
    if (widget.tripRepository != null) return widget.tripRepository;
    try {
      return context.read<TripRepository>();
    } catch (_) {
      return null;
    }
  }

  DateTime? _resolveVerifiedDepartureDate(TripModel trip) {
    final raw = trip.rawDepartureTime?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.contains('T')) {
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return null;
      // Backend stores business time zone (Vietnam ICT: UTC+7).
      final vnTime = parsed.isUtc
          ? parsed.add(const Duration(hours: 7))
          : parsed;
      return DateTime(vnTime.year, vnTime.month, vnTime.day);
    }
    final dateOnlyMatch = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (dateOnlyMatch != null) {
      final year = int.parse(dateOnlyMatch.group(1)!);
      final month = int.parse(dateOnlyMatch.group(2)!);
      final day = int.parse(dateOnlyMatch.group(3)!);
      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _handleSelectTrip(AiSuggestedTrip suggested) async {
    if (_verifyingTripId != null) return;
    final repo = _resolveTripRepository(context);
    if (repo == null) {
      setState(() {
        _tripLookupError =
            'Chưa tải được thông tin chuyến xe từ máy chủ. Vui lòng thử lại sau.';
      });
      return;
    }

    final lookupGeneration = ++_tripLookupGeneration;
    final sessionVersion = TokenStorage.sessionVersion;
    final companyId = _cubit.state.companyId;
    setState(() {
      _verifyingTripId = suggested.tripId;
      _tripLookupError = null;
    });

    try {
      final trip = await repo.getTripById(suggested.tripId.toString());
      if (!mounted ||
          lookupGeneration != _tripLookupGeneration ||
          sessionVersion != TokenStorage.sessionVersion ||
          _cubit.state.companyId != companyId) {
        return;
      }
      if (trip == null) {
        setState(() {
          _verifyingTripId = null;
          _tripLookupError =
              'Chuyến xe không còn khả dụng hoặc chưa tải được dữ liệu thực tế.';
        });
        return;
      }
      final departureDate = _resolveVerifiedDepartureDate(trip);
      if (departureDate == null) {
        setState(() {
          _verifyingTripId = null;
          _tripLookupError =
              'Chuyến xe không có thông tin ngày khởi hành hợp lệ từ máy chủ.';
        });
        return;
      }
      setState(() {
        _verifyingTripId = null;
      });
      if (widget.onOpenVerifiedTrip != null) {
        widget.onOpenVerifiedTrip!(trip, departureDate);
      } else {
        context.push(
          AppRoutes.seatSelection,
          extra: {'trip': trip, 'date': departureDate, 'ticketCount': 1},
        );
      }
    } catch (_) {
      if (!mounted ||
          lookupGeneration != _tripLookupGeneration ||
          sessionVersion != TokenStorage.sessionVersion ||
          _cubit.state.companyId != companyId) {
        return;
      }
      setState(() {
        _verifyingTripId = null;
        _tripLookupError =
            'Chưa tải được thông tin chuyến xe từ máy chủ. Vui lòng thử lại sau.';
      });
    }
  }

  void _handleOpenSupportChat() {
    if (widget.onOpenSupportChat != null) {
      widget.onOpenSupportChat!();
      return;
    }
    context.push(AppRoutes.supportChat);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final textScale = mediaQuery.textScaler.scale(1.0);
    final isShort =
        mediaQuery.size.height < 420 ||
        availableHeight < 360 ||
        (textScale >= 1.5 && mediaQuery.viewInsets.bottom > 0);

    return DiscoveryTheme(
      child: BlocProvider<AiChatbotCubit>.value(
        value: _cubit,
        child: BlocConsumer<AiChatbotCubit, AiChatbotState>(
          bloc: _cubit,
          listener: (context, state) {
            if (_composerController.text != state.draft) {
              _syncControllerWithDraft(state.draft);
            }
            if (!state.sending && _pendingSentQuestion != null) {
              setState(() => _pendingSentQuestion = null);
            }
            if (state.exchanges.length != _lastExchangeCount) {
              _lastExchangeCount = state.exchanges.length;
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            final canQuickAsk =
                !state.sending && !state.loadingHistory && !state.uncertain;
            final pendingBubbleText =
                _pendingSentQuestion ?? state.draft.trim();

            return Scaffold(
              backgroundColor: DiscoveryColors.background,
              appBar: _buildAppBar(context, state, isShort),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      key: const Key('ai-chatbot-scroll-view'),
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        16,
                        isShort ? 10 : 16,
                        16,
                        16,
                      ),
                      children: [
                        if (_showNewConversationConfirm)
                          _buildNewConversationConfirmBar(),
                        if (state.companyId != null)
                          _buildCompanyScopeBanner(state.companyId!),

                        if (state.exchanges.isEmpty) ...[
                          AiChatbotSuggestionsView(
                            suggestions: state.suggestions,
                            loading: state.loadingSuggestions,
                            error: state.suggestionsError,
                            canInteract: canQuickAsk,
                            onRetry: () => _cubit.loadSuggestions(),
                            onSelectSuggestion: (item) =>
                                _handleQuickAsk(item.question),
                            onFillDraftOnly: (item) =>
                                _handleFillDraft(item.question),
                            compact: isShort,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Local acknowledged exchanges
                        ...state.exchanges.asMap().entries.map((entry) {
                          return AiChatbotExchangeItem(
                            exchangeIndex: entry.key,
                            exchange: entry.value,
                            canInteract: canQuickAsk,
                            verifyingTripId: _verifyingTripId,
                            onSelectTrip: _handleSelectTrip,
                            onSelectFollowUpQuestion: _handleQuickAsk,
                            onOpenSupportChat: _handleOpenSupportChat,
                          );
                        }),

                        // Pending exchange while POST is in flight
                        if (state.sending)
                          AiChatbotPendingExchange(
                            pendingQuestion: pendingBubbleText,
                          ),

                        // Read-only server history snapshot
                        if (state.loadingHistory ||
                            state.historyError != null ||
                            state.historySnapshot != null)
                          AiChatbotHistoryCard(
                            loading: state.loadingHistory,
                            error: state.historyError,
                            snapshot: state.historySnapshot,
                            onRefresh: () => _cubit.readHistory(),
                            onOpenSupportChat: _handleOpenSupportChat,
                          ),

                        // Trip verification error banner
                        if (_tripLookupError != null)
                          AiChatbotErrorBanner(
                            key: const Key('ai-chatbot-trip-error-banner'),
                            error: _tripLookupError!,
                          ),

                        // Uncertain POST banner
                        if (state.uncertain)
                          AiChatbotUncertainBanner(
                            message: state.error,
                            hasKnownSession: state.sessionToken != null,
                            loadingHistory: state.loadingHistory,
                            onReadHistory: () => _cubit.readHistory(),
                            onNewConversationKeepDraft: () =>
                                _handleStartNewConversation(keepDraft: true),
                            onNewConversationClearDraft: () =>
                                _handleStartNewConversation(keepDraft: false),
                          )
                        else if (state.error != null)
                          AiChatbotErrorBanner(error: state.error!),
                      ],
                    ),
                  ),
                  AiChatbotComposer(
                    controller: _composerController,
                    focusNode: _composerFocusNode,
                    onChanged: (text) {
                      _cubit.setDraft(text);
                      setState(() {});
                    },
                    onSend: _handleSend,
                    canSend: state.canSend,
                    sending: state.sending,
                    isDense: isShort,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AiChatbotState state,
    bool isShort,
  ) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: isShort ? 48 : kToolbarHeight,
      backgroundColor: DiscoveryColors.header,
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: canPop
          ? IconButton(
              key: const Key('ai-chatbot-back-btn'),
              tooltip: 'Quay lại',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            )
          : null,
      titleSpacing: canPop ? 0 : 16,
      title: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trợ lý AI',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isShort ? DiscoveryTextStyles.h4 : DiscoveryTextStyles.h3)
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      actions: [
        if (state.sessionToken != null)
          IconButton(
            key: const Key('ai-chatbot-read-history-btn'),
            tooltip: 'Xem phản hồi đã lưu',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: (state.sending || state.loadingHistory)
                ? null
                : () => _cubit.readHistory(),
            icon: const Icon(Icons.history_rounded, color: Colors.white),
          ),
        IconButton(
          key: const Key('ai-chatbot-new-conv-btn'),
          tooltip: 'Hội thoại mới',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () {
            final nextShow = !_showNewConversationConfirm;
            setState(() => _showNewConversationConfirm = nextShow);
            if (nextShow && _scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          },
          icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
        ),
        IconButton(
          key: const Key('ai-chatbot-header-support-btn'),
          tooltip: 'Chat với nhân viên',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _handleOpenSupportChat,
          icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCompanyScopeBanner(int companyId) {
    return Container(
      key: const Key('ai-chatbot-company-banner'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DiscoveryColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DiscoveryColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.business_rounded,
                  size: 16,
                  color: DiscoveryColors.primaryDark,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Đang lọc theo nhà xe #$companyId',
                  style: DiscoveryTextStyles.bodySmall.copyWith(
                    color: DiscoveryColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            key: const Key('ai-chatbot-clear-company-btn'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 40),
              foregroundColor: DiscoveryColors.primaryDark,
            ),
            onPressed: () {
              _tripLookupGeneration++;
              setState(() {
                _pendingSentQuestion = null;
                _verifyingTripId = null;
                _tripLookupError = null;
              });
              _cubit.setCompany(null);
              _syncControllerWithDraft('');
              unawaited(_cubit.loadSuggestions());
            },
            child: const Text('Bỏ lọc nhà xe'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewConversationConfirmBar() {
    return Container(
      key: const Key('ai-chatbot-new-conv-confirm-bar'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DiscoveryColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DiscoveryColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bắt đầu hội thoại mới?',
            style: DiscoveryTextStyles.titleSmall.copyWith(
              color: DiscoveryColors.neutral900,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thao tác này mở một phiên trò chuyện mới trên ứng dụng và không xóa các yêu cầu đã gửi lên máy chủ trước đó.',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: DiscoveryColors.neutral700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                key: const Key('ai-chatbot-confirm-new-clear-btn'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  backgroundColor: DiscoveryColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _handleStartNewConversation(keepDraft: false),
                child: const Text('Tạo phiên mới'),
              ),
              OutlinedButton(
                key: const Key('ai-chatbot-confirm-new-keep-btn'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: DiscoveryColors.primaryDark,
                  side: const BorderSide(color: DiscoveryColors.primary),
                ),
                onPressed: () => _handleStartNewConversation(keepDraft: true),
                child: const Text('Tạo mới & Giữ nháp'),
              ),
              TextButton(
                key: const Key('ai-chatbot-cancel-new-btn'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: DiscoveryColors.neutral700,
                ),
                onPressed: () =>
                    setState(() => _showNewConversationConfirm = false),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
