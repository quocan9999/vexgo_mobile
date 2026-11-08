import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/token_storage.dart';
import '../../../data/models/ai_chatbot_model.dart';
import '../../../data/repositories/ai_chatbot_repository.dart';

export '../../../data/models/ai_chatbot_model.dart';

/// One acknowledged local exchange; history remains a separate read snapshot.
class AiChatExchange {
  final String question;
  final AiChatReply answer;
  const AiChatExchange(this.question, this.answer);
}

class AiChatbotState {
  final List<AiChatExchange> exchanges;
  final List<AiSuggestion> suggestions;
  final String draft;
  final bool sending, loadingSuggestions, loadingHistory, uncertain;
  final String? error, suggestionsError, historyError;
  final AiChatHistory? historySnapshot;
  // A capability, kept in memory only. Never render/log or pass via route URLs.
  final String? sessionToken;
  final int? companyId;
  const AiChatbotState({
    this.exchanges = const [],
    this.suggestions = const [],
    this.draft = '',
    this.sending = false,
    this.loadingSuggestions = false,
    this.loadingHistory = false,
    this.uncertain = false,
    this.error,
    this.suggestionsError,
    this.historyError,
    this.historySnapshot,
    this.sessionToken,
    this.companyId,
  });
  bool get canSend =>
      !sending &&
      !loadingHistory &&
      !uncertain &&
      draft.trim().isNotEmpty &&
      draft.trim().runes.length <= 2000;
  bool get requiresHumanHandoff =>
      exchanges.isNotEmpty && exchanges.last.answer.requiresHumanHandoff;
  String? get handoffReason =>
      requiresHumanHandoff ? exchanges.last.answer.handoffReason : null;
  static const _keep = Object();
  AiChatbotState copyWith({
    List<AiChatExchange>? exchanges,
    List<AiSuggestion>? suggestions,
    String? draft,
    bool? sending,
    bool? loadingSuggestions,
    bool? loadingHistory,
    bool? uncertain,
    Object? error = _keep,
    Object? suggestionsError = _keep,
    Object? historyError = _keep,
    Object? historySnapshot = _keep,
    Object? sessionToken = _keep,
  }) => AiChatbotState(
    exchanges: exchanges == null
        ? this.exchanges
        : List.unmodifiable(exchanges),
    suggestions: suggestions == null
        ? this.suggestions
        : List.unmodifiable(suggestions),
    draft: draft ?? this.draft,
    sending: sending ?? this.sending,
    loadingSuggestions: loadingSuggestions ?? this.loadingSuggestions,
    loadingHistory: loadingHistory ?? this.loadingHistory,
    uncertain: uncertain ?? this.uncertain,
    error: identical(error, _keep) ? this.error : error as String?,
    suggestionsError: identical(suggestionsError, _keep)
        ? this.suggestionsError
        : suggestionsError as String?,
    historyError: identical(historyError, _keep)
        ? this.historyError
        : historyError as String?,
    historySnapshot: identical(historySnapshot, _keep)
        ? this.historySnapshot
        : historySnapshot as AiChatHistory?,
    sessionToken: identical(sessionToken, _keep)
        ? this.sessionToken
        : sessionToken as String?,
    companyId: companyId,
  );
}

/// Does not navigate, call an LLM provider, persist a token, or send to CSKH.
class AiChatbotCubit extends Cubit<AiChatbotState> {
  final AiChatbotRepository repository;
  late final StreamSubscription<void> _changes, _invalidations;
  int _generation = 0;
  bool _closing = false;
  AiChatbotCubit({required this.repository, int? companyId})
    : super(AiChatbotState(companyId: companyId)) {
    if (companyId != null && companyId < 1) {
      throw ArgumentError('Invalid company');
    }
    _changes = TokenStorage.sessionChanges.listen(
      (_) => _reset(state.companyId),
    );
    _invalidations = TokenStorage.sessionInvalidations.listen(
      (_) => _reset(state.companyId),
    );
  }
  bool _current(int generation, int session) =>
      !_closing &&
      !isClosed &&
      _generation == generation &&
      TokenStorage.sessionVersion == session;
  void _reset(int? companyId, {String draft = ''}) {
    if (_closing || isClosed) return;
    _generation++;
    emit(AiChatbotState(companyId: companyId, draft: draft));
  }

  void setCompany(int? id) {
    if (id != null && id < 1) throw ArgumentError('Invalid company');
    if (id != state.companyId) _reset(id);
  }

  /// Explicit user action, especially after an uncertain first POST.
  /// Starts a separate session; it cannot undo/delete the request on the server.
  void newConversation({bool keepDraft = false}) =>
      _reset(state.companyId, draft: keepDraft ? state.draft : '');

  void setDraft(String text) {
    if (!_closing && !isClosed) {
      emit(
        state.copyWith(
          draft: text,
          error: state.uncertain ? state.error : null,
        ),
      );
    }
  }

  Future<void> loadSuggestions() async {
    if (_closing || isClosed || state.loadingSuggestions) return;
    final generation = _generation, session = TokenStorage.sessionVersion;
    emit(state.copyWith(loadingSuggestions: true, suggestionsError: null));
    try {
      final suggestions = await repository.suggestions();
      if (_current(generation, session)) {
        emit(
          state.copyWith(suggestions: suggestions, loadingSuggestions: false),
        );
      }
    } catch (_) {
      if (_current(generation, session)) {
        emit(
          state.copyWith(
            loadingSuggestions: false,
            suggestionsError:
                'Chưa tải được câu hỏi gợi ý. Bạn vẫn có thể nhập câu hỏi.',
          ),
        );
      }
    }
  }

  Future<void> send() async {
    if (_closing ||
        isClosed ||
        state.sending ||
        state.loadingHistory ||
        state.uncertain) {
      return;
    }
    final question = state.draft.trim();
    if (question.isEmpty || question.runes.length > 2000) {
      emit(state.copyWith(error: 'Nhập câu hỏi từ 1 đến 2.000 ký tự.'));
      return;
    }
    final generation = _generation, session = TokenStorage.sessionVersion;
    final originalDraft = state.draft;
    emit(
      state.copyWith(
        sending: true,
        error: null,
        historySnapshot: null,
        historyError: null,
      ),
    );
    try {
      final answer = await repository.send(
        message: question,
        sessionToken: state.sessionToken,
        companyId: state.companyId,
      );
      if (!_current(generation, session)) return;
      emit(
        state.copyWith(
          sending: false,
          sessionToken: answer.sessionToken,
          exchanges: [...state.exchanges, AiChatExchange(question, answer)],
          draft: state.draft == originalDraft ? '' : state.draft,
        ),
      );
    } catch (e) {
      if (!_current(generation, session)) return;
      // Unknown/parse/server errors may arrive after server-side persistence.
      final uncertain =
          e is! ApiException || e.statusCode >= 500 || e.statusCode == 408;
      final message = uncertain
          ? 'Chưa xác định được câu hỏi đã xử lý hay chưa. Giữ lại bản nháp; không gửi lại tự động.'
          : e is UnauthorizedException
          ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
          : e.statusCode == 429
          ? 'Bạn đang gửi quá nhanh. Vui lòng chờ rồi thử lại.'
          : 'Chưa gửi được câu hỏi. Vui lòng kiểm tra và thử lại.';
      emit(
        state.copyWith(sending: false, uncertain: uncertain, error: message),
      );
    }
  }

  /// Read-only snapshot, never a replacement for local exchanges. ec75064
  /// stores ASSISTANT only and has no request ID to reconcile a timed-out POST.
  Future<void> readHistory() async {
    if (_closing ||
        isClosed ||
        state.sending ||
        state.loadingHistory ||
        state.sessionToken == null) {
      return;
    }
    final token = state.sessionToken!;
    final generation = _generation, session = TokenStorage.sessionVersion;
    emit(state.copyWith(loadingHistory: true, historyError: null));
    try {
      final history = await repository.history(token);
      if (_current(generation, session)) {
        emit(state.copyWith(loadingHistory: false, historySnapshot: history));
      }
    } catch (e) {
      if (_current(generation, session)) {
        emit(
          state.copyWith(
            loadingHistory: false,
            historyError: e is ApiException && e.statusCode == 404
                ? 'Chưa tìm thấy lịch sử phiên này.'
                : 'Chưa tải được lịch sử. Hội thoại trên máy vẫn được giữ.',
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    _generation++;
    await _changes.cancel();
    await _invalidations.cancel();
    return super.close();
  }
}
