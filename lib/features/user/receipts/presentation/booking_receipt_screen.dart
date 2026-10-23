import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../data/models/booking_receipt_model.dart';
import '../../../../data/repositories/booking_receipt_repository.dart';
import '../bloc/booking_receipt_cubit.dart';

class BookingReceiptScreen extends StatefulWidget {
  final ReceiptLookupRequest? initialRequest;
  const BookingReceiptScreen({super.key, this.initialRequest});
  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _phone;
  late final BookingReceiptCubit _reader;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final request = widget.initialRequest;
    final validRequest =
        !ApiConfig.isDemoMode &&
        (request == null ||
            request.sessionVersion == TokenStorage.sessionVersion);
    _code = TextEditingController(text: validRequest ? request?.code : null);
    _phone = TextEditingController(text: validRequest ? request?.phone : null);
    _reader = BookingReceiptCubit(context.read<BookingReceiptRepository>());
    if (!validRequest) {
      _reader.invalidate();
    } else if (_code.text.trim().isNotEmpty && _phone.text.trim().isNotEmpty) {
      _reader.lookup(_code.text, _phone.text);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _reader.state.status == ReceiptStatus.loaded) {
      _reader.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reader.close();
    _code.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _lookup() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _reader.lookup(_code.text, _phone.text);
  }

  @override
  Widget build(BuildContext context) => ApiConfig.isDemoMode
      ? const Scaffold(
          appBar: CustomAppBar(title: 'Chứng từ thanh toán'),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tra cứu chứng từ chỉ khả dụng khi kết nối hệ thống thật.',
              ),
            ),
          ),
        )
      : Scaffold(
          backgroundColor: AppColors.background,
          appBar: const CustomAppBar(title: 'Chứng từ thanh toán'),
          body: BlocConsumer<BookingReceiptCubit, BookingReceiptState>(
            bloc: _reader,
            listener: (_, state) {
              if (state.status == ReceiptStatus.invalidated) {
                _code.clear();
                _phone.clear();
              }
            },
            builder: (context, state) {
              final invalid =
                  !_reader.isCurrent ||
                  state.status == ReceiptStatus.invalidated;
              final busy = state.status == ReceiptStatus.loading;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Tra cứu chứng từ đặt vé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhập mã vé hoặc mã đặt vé và số điện thoại đặt vé. Đơn gắn tài khoản cần đăng nhập đúng tài khoản đã đặt.',
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('receipt-code'),
                          controller: _code,
                          enabled: !busy && !invalid,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'Mã vé hoặc mã đặt vé',
                          ),
                          onChanged: (_) => _reader.clear(),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Vui lòng nhập mã vé hoặc mã đặt vé.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const Key('receipt-phone'),
                          controller: _phone,
                          enabled: !busy && !invalid,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại đặt vé',
                          ),
                          onChanged: (_) => _reader.clear(),
                          validator: (value) =>
                              RegExp(
                                r'^(?:\+84|0)(?:3[2-9]|5[689]|7[06-9]|8[1-9]|9\d)\d{7}$',
                              ).hasMatch(value?.trim() ?? '')
                              ? null
                              : 'Số điện thoại không hợp lệ.',
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Tra cứu chứng từ',
                          isLoading: busy,
                          onPressed: invalid || busy ? null : _lookup,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null || invalid)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          invalid
                              ? 'Phiên đã thay đổi. Vui lòng đóng và mở lại tra cứu chứng từ.'
                              : state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  if (state.status == ReceiptStatus.failure && !invalid)
                    TextButton(
                      onPressed: _lookup,
                      child: const Text('Thử lại'),
                    ),
                  if (state.receipt != null && !invalid) ...[
                    const SizedBox(height: 20),
                    _ReceiptContent(state.receipt!),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _reader.refresh,
                      child: const Text('Cập nhật chứng từ'),
                    ),
                  ],
                ],
              );
            },
          ),
        );
}

class _ReceiptContent extends StatelessWidget {
  final BookingReceipt receipt;
  const _ReceiptContent(this.receipt);
  String display(String value) => value.isEmpty ? 'Chưa cung cấp' : value;
  String date(DateTime value) => DateFormat(
    'HH:mm dd/MM/yyyy',
  ).format(value.toUtc().add(const Duration(hours: 7)));
  Widget row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.neutral600, fontSize: 12),
        ),
        SelectableText(display(value)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đã thanh toán',
            style: TextStyle(
              color: AppColors.successDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          row('Mã đặt vé', receipt.bookingCode),
          row('Mã giao dịch', receipt.orderCode),
          row('Ngày đặt (giờ Việt Nam)', date(receipt.createdAt)),
          const Divider(),
          row('Hành khách', receipt.passengerName),
          row('Số điện thoại', receipt.passengerPhone),
          if (receipt.passengerEmail.isNotEmpty)
            row('Email', receipt.passengerEmail),
          const Divider(),
          row('Nhà xe', receipt.company),
          row('Tuyến', receipt.route),
          row('Loại xe', receipt.vehicle),
          if (receipt.departureAt != null)
            row('Khởi hành (giờ Việt Nam)', date(receipt.departureAt!)),
          row('Điểm đón', receipt.pickup),
          row('Điểm trả', receipt.dropoff),
          const Divider(),
          Text(
            'Vé trong đơn (${receipt.tickets.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final ticket in receipt.tickets)
            row(
              'Ghế ${display(ticket.seat)} • ${switch (ticket.status) {
                'DA_THANH_TOAN' => 'Đã thanh toán',
                'DA_DAT' => 'Đã đặt',
                'HOAN_TAT' || 'DA_SU_DUNG' => 'Đã sử dụng',
                'HUY' || 'DA_HUY' => 'Đã hủy',
                _ => 'Chưa xác minh trạng thái vé',
              }}',
              '${ticket.code}\n${CurrencyFormatter.format(ticket.price)}',
            ),
          if (receipt.cargo.isNotEmpty) ...[
            const Divider(),
            Text(
              'Hàng gửi kèm',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final parcel in receipt.cargo)
              row('Số lượng ${parcel.quantity}', parcel.name),
          ],
          const Divider(),
          row(
            'Tiền vé trước giảm',
            CurrencyFormatter.format(receipt.originalSubtotal),
          ),
          if (receipt.promotionCode.isNotEmpty)
            row('Mã giảm giá', receipt.promotionCode),
          row('Giảm giá', CurrencyFormatter.format(receipt.discount)),
          row(
            'Tiền vé sau giảm',
            CurrencyFormatter.format(receipt.ticketSubtotal),
          ),
          row('Phí hàng gửi kèm', CurrencyFormatter.format(receipt.cargoFee)),
          row('Tổng thanh toán', CurrencyFormatter.format(receipt.total)),
          row('Phương thức thanh toán', receipt.paymentMethod),
          const SizedBox(height: 12),
          const Text(
            'Đây là chứng từ đặt vé/thanh toán, không phải hóa đơn GTGT. Nếu cần hóa đơn GTGT, vui lòng liên hệ nhà xe. Chứng từ này không thay thế mã QR lên xe.',
            style: TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
        ],
      ),
    ),
  );
}
