import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'my_tickets_bloc.dart';
import 'my_tickets_event.dart';

enum TicketReadStatus { initial, loading, loaded, failure, invalidated }

class TicketReadState {
  final TicketReadStatus status;
  final TicketModel? ticket;
  final String? error;
  const TicketReadState(this.status, {this.ticket, this.error});
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
  TicketReadCubit({required this.owner})
    : super(const TicketReadState(TicketReadStatus.initial)) {
    _session = owner.sessionGeneration;
    _tokenVersion = TokenStorage.sessionVersion;
    _ownerChanges = owner.stream.listen((_) {
      if (!_isCurrent) invalidate();
    });
    _invalidations = TokenStorage.sessionInvalidations.listen(
      (_) => invalidate(),
    );
  }

  bool get _isCurrent =>
      owner.sessionGeneration == _session &&
      TokenStorage.sessionVersion == _tokenVersion;

  void invalidate() {
    if (isClosed || state.status == TicketReadStatus.invalidated) return;
    _request++;
    _retry = null;
    emit(
      const TicketReadState(
        TicketReadStatus.invalidated,
        error: 'Phiên đã thay đổi. Vui lòng mở lại thông tin vé.',
      ),
    );
  }

  Future<void> loadTicket(TicketModel initial) {
    _expectedId = initial.id;
    _expectedCode = initial.ticketCode;
    _isPublic = owner.state.requiresLogin && !ApiConfig.isDemoMode;
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
    _expectedId = null;
    _expectedCode = ticketCode.trim();
    _isPublic = true;
    final phone = phoneNumber.trim();
    _retry = () => owner.bookingRepository.lookupTicket(
      ticketCode: ticketCode.trim(),
      phoneNumber: phone,
    );
    return refresh();
  }

  Future<void> refresh() async {
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
      const supported = [
        'DA_DAT',
        'DA_THANH_TOAN',
        'DA_SU_DUNG',
        'HOAN_THANH',
        'HUY',
        'DA_HUY',
        'HET_HAN',
        'UPCOMING',
        'COMPLETED',
        'CANCELLED',
      ];
      if (!ApiConfig.isDemoMode &&
          !supported.contains(ticket.rawStatus?.toUpperCase())) {
        throw StateError(
          'Trạng thái vé chưa được hỗ trợ. Vui lòng liên hệ nhà xe.',
        );
      }
      emit(TicketReadState(TicketReadStatus.loaded, ticket: ticket));
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
        ),
      );
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
