import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/ticket_model.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/features/user/booking/presentation/screens/booking_success_screen.dart';
import 'package:vexgo_app/features/user/my_bookings/bloc/my_tickets_bloc.dart';
import 'qa/qa_fixtures.dart';

// Contract-shaped paid ticket fixtures, not live booking/email delivery proof.
const longCode = 'HM-PDV-0123456789ABCDEF0123456789ABCD-VE-01';
TicketModel paidTicket(String email) =>
    TicketModel.fromJson({
      ...qaTicketJson(),
      'ticketCode': longCode,
      'passengerEmail': email,
    }).copyWith(
      passenger: PassengerInfo(
        fullName: qaPassenger.fullName,
        phone: qaPassenger.phone,
        email: email,
      ),
    );

void main() {
  setUp(() {
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final width in [320.0, 360.0]) {
    for (final email in ['', 'qa@example.invalid']) {
      testWidgets(
        'long code fits ${width.toInt()}dp, copies in full, no email claim (${email.isEmpty ? 'empty' : 'provided'} email)',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? copied;
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            (call) async {
              if (call.method == 'Clipboard.setData') {
                copied = (call.arguments as Map)['text'] as String;
              }
              return null;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(SystemChannels.platform, null),
          );
          final owner = MyTicketsBloc(
            authenticated: false,
            bookingRepository: MockBookingRepository(),
          )..setSession(null);
          addTearDown(owner.close);
          await tester.pumpWidget(
            BlocProvider.value(
              value: owner,
              child: MaterialApp(
                home: BookingSuccessScreen(ticket: paidTicket(email)),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(QrImageView), findsOneWidget);
          expect(find.text(longCode), findsOneWidget);
          expect(tester.getSize(find.text(longCode)).height, greaterThan(30));
          final copy = find.byTooltip('Sao chép mã vé');
          await tester.ensureVisible(copy);
          final rect = tester.getRect(copy);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
          await tester.tap(copy);
          await tester.pumpAndSettle();
          expect(copied, longCode);
          expect(
            find.text('Đã sao chép mã vé vào bộ nhớ tạm!'),
            findsOneWidget,
          );
          final instructions = find.text(
            'Lưu mã vé và số điện thoại đã dùng khi đặt vé để tra cứu vé không cần đăng nhập.',
          );
          await tester.ensureVisible(instructions);
          await tester.pumpAndSettle();
          expect(instructions, findsOneWidget);
          expect(find.textContaining('đã được gửi'), findsNothing);
          expect(find.textContaining('email'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    '320dp with enlarged text and multiple issued tickets has no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final owner = MyTicketsBloc(
        authenticated: false,
        bookingRepository: MockBookingRepository(),
      )..setSession(null);
      addTearDown(owner.close);
      final first = paidTicket('');
      final second = first.copyWith(
        id: '92',
        ticketCode: 'HM-PDV-0123456789ABCDEF0123456789ABCD-VE-02',
        seats: ['A02'],
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: owner,
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child!,
            ),
            home: BookingSuccessScreen(ticket: first, tickets: [first, second]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Về trang chủ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
