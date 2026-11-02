import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/repositories/public_promotion_repository.dart';
import 'package:vexgo_app/features/user/home/presentation/widgets/available_offers_section.dart';
import 'package:vexgo_app/features/user/app_info/presentation/screens/app_information_screen.dart';

Map<String, dynamic> offer(String code) => {
  'code': code,
  'name': 'Ưu đãi $code',
  'discountType': 'PHAN_TRAM',
  'discountValue': '10.00',
  'maxDiscount': '30000.00',
  'minimumTicketAmount': '100000.00',
  'startsOn': '2026-11-01',
  'endsOn': '2026-11-30',
};

class _Offers extends PublicPromotionRepository {
  final a = Completer<List<PublicPromotion>>(),
      b = Completer<List<PublicPromotion>>();
  @override
  Future<List<PublicPromotion>> getAvailable(int companyId) =>
      companyId == 1 ? a.future : b.future;
}

class _RetryOffers extends PublicPromotionRepository {
  int calls = 0;
  @override
  Future<List<PublicPromotion>> getAvailable(int companyId) async {
    if (calls++ == 0) throw StateError('Offline');
    return [];
  }
}

const companies = [
  OperatorModel(id: '1', name: 'Nhà xe A', shortName: 'A'),
  OperatorModel(id: '2', name: 'Nhà xe B', shortName: 'B'),
];
void main() {
  test(
    'Public promotions use scoped GET and preserve decimal conditions; empty stays empty',
    () async {
      var calls = 0;
      final repo = PublicPromotionRepository(
        client: ApiClient(
          httpClient: MockClient((r) async {
            expect(r.method, 'GET');
            expect(r.url.path.endsWith('/promotions/available'), isTrue);
            expect(r.url.queryParameters, {'nhaXeId': '3'});
            expect(r.headers.containsKey('Authorization'), isFalse);
            return http.Response(
              jsonEncode({
                'data': calls++ == 0 ? [offer('SAVE')] : [],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );
      final result = await repo.getAvailable(3);
      expect(result.single.maxDiscount, 30000);
      expect(result.single.minimumTicketAmount, 100000);
      expect(await repo.getAvailable(3), isEmpty);
    },
  );
  test(
    'Malformed discount conditions fail instead of displaying an invented offer',
    () {
      expect(
        () => PublicPromotion.fromJson({
          ...offer('BAD'),
          'minimumTicketAmount': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => PublicPromotion.fromJson({
          ...offer('BAD'),
          'discountType': 'UNKNOWN',
        }),
        throwsFormatException,
      );
      expect(
        () =>
            PublicPromotion.fromJson({...offer('BAD'), 'endsOn': '2026-02-30'}),
        throwsFormatException,
      );
    },
  );
  testWidgets('Switching companies never displays the previous late response', (
    tester,
  ) async {
    final repo = _Offers();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AvailableOffersSection(
              operators: companies,
              repository: repo,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Nhà xe B').last);
    await tester.pump(const Duration(milliseconds: 300));
    repo.b.complete([PublicPromotion.fromJson(offer('B'))]);
    await tester.pumpAndSettle();
    expect(find.text('Ưu đãi B'), findsOneWidget);
    repo.a.complete([PublicPromotion.fromJson(offer('A'))]);
    await tester.pumpAndSettle();
    expect(find.text('Ưu đãi A'), findsNothing);
    expect(find.text('Ưu đãi B'), findsOneWidget);
  });
  testWidgets('Offer fetch failure can retry to an honest empty state', (
    tester,
  ) async {
    final repo = _RetryOffers();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AvailableOffersSection(
              operators: [companies.first],
              repository: repo,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa tải được ưu đãi của nhà xe này.'), findsOneWidget);
    await tester.tap(find.text('Thử lại ưu đãi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Hiện chưa có ưu đãi đang mở cho nhà xe này.'),
      findsOneWidget,
    );
    expect(repo.calls, 2);
  });

  testWidgets(
    'Guide opens from home and information pages remain usable with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: BookingGuideSection()),
          ),
        ),
      );
      await tester.tap(find.text('Xem hướng dẫn đặt vé'));
      await tester.pumpAndSettle();
      expect(find.text('Hướng dẫn sử dụng'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('4. Thanh toán và nhận vé'),
        120,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('4. Thanh toán và nhận vé'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Làm theo thông tin ngân hàng'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
