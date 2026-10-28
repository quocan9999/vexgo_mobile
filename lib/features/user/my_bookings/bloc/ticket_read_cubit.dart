import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'cancellation_policy.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'my_tickets_bloc.dart';
import 'my_tickets_event.dart';

enum TicketReadStatus {
  initial,
  loading,
  loaded,
  cancelling,
  failure,
  invalidated,
}

class TicketReadState {
  final TicketReadStatus status;
  final TicketModel? ticket;
  final String? error;
  final String? message;
  final bool cancellationUncertain;
  const TicketReadState(
    this.status, {
    this.ticket,
    this.error,
    this.message,
    this.cancellationUncertain = false,
  });
}

/// A fresh read has its own lifecycle; navigation/list snapshots never authorize QR.
class TicketReadCubit extends Cubit<TicketReadState> {
  final MyTicketsBloc owner;
  late final StreamSubscription<dynamic> _ownerChanges;
  late final StreamSubscription<void> _invalidations;
  late final int _session;
  late final int _tokenVersion;
  int _request = 0;
  Future<TicketModel?> Function()? _retry;
  String? _expectedId;
  String? _expectedCode;
  bool _isPublic = false;
  String? _lookupPhone;
  String? _cancelledTicketId;
  bool _mutationInFlight = false;
  final _uncertainCancellationCodes = <String>{};
  bool get _uncertainCancellation =>
      _uncertainCancellationCodes.contains(_expectedCode);
  TicketReadCubit({required this.owner})
    : super(const TicketReadState(TicketReadStatus.initial)) {
    _session = owner.sessionGeneration;
    _tokenVersion = TokenStorage.sessionVersion;
    _ownerChanges = owner.stream.listen((_) {
      if (!_isCurrent) invalidate();
      if (_expectedId != null &&
          owner.state.tickets.any(
            (t) =>
                t.id == _expectedId &&
                t.status == TicketStatus.cancelled &&
                TicketModel.parseSupportedStatus(t.rawStatus) ==
                    TicketStatus.cancelled,
          )) {
        _cancelledTicketId = _expectedId;
        if (_isCurrent &&
            state.status == TicketReadStatus.loaded &&
            state.ticket?.status != TicketStatus.cancelled) {
          _request++;
          emit(
            const TicketReadState(
              TicketReadStatus.failure,
              error:
                  'Trạng thái vé đã thay đổi. Vui lòng cập nhật thông tin vé.',
            ),
          );
        }
      }
    });
    _invalidations = TokenStorage.sessionChanges.listen((_) => invalidate());
  }

  bool get _isCurrent =>
      owner.sessionGeneration == _session &&
      TokenStorage.sessionVersion == _tokenVersion;

  void invalidate() {
    if (isClosed || state.status == TicketReadStatus.invalidated) return;
    _request++;
    _retry = null;
    _lookupPhone = null;
    emit(
      const TicketReadState(
        TicketReadStatus.invalidated,
        error: 'Phiên đã thay đổi. Vui lòng mở lại thông tin vé.',
      ),
    );
  }

  Future<void> loadTicket(TicketModel initial) {
    if (_mutationInFlight) return Future.value();
    _expectedId = initial.id;
    _expectedCode = initial.ticketCode;
    _isPublic = owner.state.requiresLogin && !ApiConfig.isDemoMode;
    _lookupPhone = _isPublic ? initial.passenger.phone : null;
    _retry = _isPublic
        ? () => owner.bookingRepository.lookupTicket(
            ticketCode: initial.ticketCode,
            phoneNumber: initial.passenger.phone,
          )
        : () => owner.bookingRepository.getTicketById(initial.id);
    return refresh();
  }

  Future<void> lookup({
    required String ticketCode,
    required String phoneNumber,
  }) {
    if (_mutationInFlight) return Future.value();
    _expectedId = null;
    _expectedCode = ticketCode.trim();
    _isPublic = true;
    final phone = phoneNumber.trim();
    _lookupPhone = phone;
    _retry = () => owner.bookingRepository.lookupTicket(
      ticketCode: ticketCode.trim(),
      phoneNumber: phone,
    );
    return refresh();
  }

  Future<void> refresh() => _read();

  Future<void> _read({bool afterMutation = false}) async {
    if (_mutationInFlight && !afterMutation) return;
    if (!_isCurrent) {
      invalidate();
      return;
    }
    final read = _retry;
    if (read == null || isClosed) return;
    final request = ++_request;
    emit(const TicketReadState(TicketReadStatus.loading));
    try {
      final ticket = await read();
      if (isClosed || request != _request) return;
      if (!_isCurrent) {
        invalidate();
        return;
      }
      if (ticket == null ||
          ticket.ticketCode != _expectedCode ||
          (_expectedId != null && ticket.id != _expectedId) ||
          (!ApiConfig.isDemoMode && !ticket.hasFullDetails)) {
        throw StateError('Thông tin vé trả về không đầy đủ.');
      }
      if (!ApiConfig.isDemoMode &&
          TicketModel.parseSupportedStatus(ticket.rawStatus) == null) {
        throw StateError(
          'Trạng thái vé chưa được hỗ trợ. Vui lòng liên hệ nhà xe.',
        );
      }
      if (ticket.id == _cancelledTicketId &&
          ticket.status != TicketStatus.cancelled) {
        throw StateError('Trạng thái hủy vé chưa được đồng bộ.');
      }
      if (ticket.status == TicketStatus.cancelled) {
        _uncertainCancellationCodes.remove(ticket.ticketCode);
      }
      emit(
        TicketReadState(
          TicketReadStatus.loaded,
          ticket: ticket,
          cancellationUncertain: _uncertainCancellation,
        ),
      );
      if (!_isPublic) owner.add(SyncTicketDetailsEvent(ticket, _session));
    } catch (error) {
      if (isClosed || request != _request) return;
      if (!_isCurrent) {
        invalidate();
        return;
      }
      emit(
        TicketReadState(
          TicketReadStatus.failure,
          error:
              'Không thể tải thông tin vé. Vui lòng kiểm tra mã vé, số điện thoại và thử lại. ($error)',
          cancellationUncertain: _uncertainCancellation,
        ),
      );
    }
  }

  /// Only the current public lookup authorizes a guest mutation. The sheet
  /// obtains a fresh lookup first; the server rechecks the quoted fee on POST.
  Future<void> cancelTicket({
    required TicketModel quotedTicket,
    required String reason,
  }) async {
    if (_mutationInFlight || isClosed || _uncertainCancellation) return;
    if (!_isCurrent) {
      invalidate();
      return;
    }
    final quote = quotedTicket.cancellation;
    final phone = _lookupPhone;
    if (!_isPublic ||
        state.status != TicketReadStatus.loaded ||
        !identical(state.ticket, quotedTicket) ||
        !hasUsableCancellationQuote(quotedTicket) ||
        reason.trim().isEmpty ||
        reason.trim().length > 500 ||
        phone == null ||
        quote == null ||
        !quotedTicket.canCancel ||
        !quote.cancelFeeRate.isFinite ||
        quote.cancelFeeRate < 0 ||
        quote.cancelFeeRate > 1 ||
        quote.cancelFee < 0 ||
        quote.refundAmount < 0) {
      return;
    }
    _mutationInFlight = true;
    _uncertainCancellationCodes.add(quotedTicket.ticketCode);
    final request = ++_request;
    emit(const TicketReadState(TicketReadStatus.cancelling));
    String? errorMessage;
    var accepted = false;
    try {
      final response = await owner.bookingRepository.cancelTicket(
        ticketCode: quotedTicket.ticketCode,
        phoneNumber: phone,
        expectedCancelFeeRate: quote.cancelFeeRate,
        reason: reason,
      );
      final payload = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      if (!confirmsCancellation(payload, quotedTicket)) {
        throw const FormatException('Phản hồi hủy vé không khớp.');
      }
      accepted = true;
    } catch (error) {
      if (error is ApiException &&
          error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408) {
        _uncertainCancellationCodes.remove(quotedTicket.ticketCode);
      }
      // Includes an expired quote or unknown POST result. Never retry POST
      // automatically: reconcile by a public lookup and ask for confirmation.
      errorMessage =
          'Chưa xác nhận được yêu cầu hủy. Hãy kiểm tra trạng thái vé và mức phí mới trước khi thử lại.';
    }
    try {
      if (isClosed || request != _request) return;
      if (!_isCurrent) {
        invalidate();
        return;
      }
      if (accepted) _cancelledTicketId = quotedTicket.id;
      await _read(afterMutation: true);
      if (isClosed ||
          !_isCurrent ||
          state.status == TicketReadStatus.invalidated) {
        return;
      }
      final cancelled = state.ticket?.status == TicketStatus.cancelled;
      emit(
        TicketReadState(
          state.status,
          ticket: state.ticket,
          error: cancelled ? null : errorMessage ?? state.error,
          cancellationUncertain: _uncertainCancellation,
          message: accepted || cancelled
              ? 'Yêu cầu hủy vé đã được xác nhận. Việc hoàn tiền cần được kiểm tra riêng.'
              : null,
        ),
      );
    } finally {
      _mutationInFlight = false;
    }
  }

  @override
  Future<void> close() async {
    invalidate();
    _request++;
    _retry = null;
    await _ownerChanges.cancel();
    await _invalidations.cancel();
    return super.close();
  }
}
