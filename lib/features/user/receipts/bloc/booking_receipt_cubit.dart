import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../data/models/booking_receipt_model.dart';
import '../../../../data/repositories/booking_receipt_repository.dart';

enum ReceiptStatus { initial, loading, loaded, failure, invalidated }

class BookingReceiptState {
  final ReceiptStatus status;
  final BookingReceipt? receipt;
  final String? error;
  const BookingReceiptState(this.status, {this.receipt, this.error});
}

class BookingReceiptCubit extends Cubit<BookingReceiptState> {
  final BookingReceiptRepository repository;
  late final StreamSubscription<void> _invalidations;
  final int _session = TokenStorage.sessionVersion;
  int _request = 0;
  String? _code;
  String? _phone;
  BookingReceiptCubit(this.repository)
    : super(const BookingReceiptState(ReceiptStatus.initial)) {
    _invalidations = TokenStorage.sessionChanges.listen((_) => invalidate());
  }
  bool get isCurrent => _session == TokenStorage.sessionVersion;
  void clear() {
    if (!isCurrent) {
      invalidate();
      return;
    }
    _request++;
    _code = null;
    _phone = null;
    emit(const BookingReceiptState(ReceiptStatus.initial));
  }

  void invalidate() {
    if (isClosed) return;
    _request++;
    _code = null;
    _phone = null;
    emit(
      const BookingReceiptState(
        ReceiptStatus.invalidated,
        error: 'Phiên đã thay đổi. Vui lòng đóng và mở lại tra cứu chứng từ.',
      ),
    );
  }

  Future<void> lookup(String code, String phone) async {
    if (isClosed) return;
    if (!isCurrent) {
      invalidate();
      return;
    }
    final request = ++_request;
    _code = code.trim();
    _phone = phone.trim();
    emit(const BookingReceiptState(ReceiptStatus.loading));
    try {
      final receipt = await repository.lookup(code: _code!, phone: _phone!);
      if (isClosed || request != _request) return;
      if (!isCurrent) {
        invalidate();
        return;
      }
      emit(BookingReceiptState(ReceiptStatus.loaded, receipt: receipt));
    } catch (error) {
      if (isClosed || request != _request) return;
      if (!isCurrent) {
        invalidate();
        return;
      }
      final message = switch (error) {
        ReceiptUnavailable() => error.message,
        UnauthorizedException() =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        ApiException() when error.statusCode == 403 =>
          'Đơn này thuộc tài khoản khác. Vui lòng đăng nhập đúng tài khoản đặt vé.',
        ApiException() when error.statusCode == 404 =>
          'Không tìm thấy chứng từ hoặc mã/số điện thoại không khớp.',
        NetworkException() => 'Không thể kết nối máy chủ. Vui lòng thử lại.',
        _ =>
          'Chưa thể tải chứng từ hợp lệ. Vui lòng kiểm tra thông tin và thử lại.',
      };
      emit(BookingReceiptState(ReceiptStatus.failure, error: message));
    }
  }

  Future<void> refresh() {
    final code = _code, phone = _phone;
    if (code == null || phone == null) return Future.value();
    return lookup(code, phone);
  }

  @override
  Future<void> close() async {
    _request++;
    _code = null;
    _phone = null;
    await _invalidations.cancel();
    return super.close();
  }
}
