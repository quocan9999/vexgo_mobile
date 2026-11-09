import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/data/datasources/remote/trip_remote_data_source.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/location_repository.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/home/bloc/home_bloc.dart';
import 'package:vexgo_app/features/user/home/bloc/home_event.dart';
import 'package:vexgo_app/features/user/home/bloc/home_state.dart';
import 'package:vexgo_app/features/user/home/presentation/screens/select_city_sheet.dart';
import 'package:vexgo_app/features/user/shipments/presentation/screens/shipments_host_screen.dart';
import 'package:vexgo_app/features/user/round_trip/round_trip_request.dart';
import 'standalone_shipments_ui_test.dart' show FakeShipmentRepository;

Map<String, dynamic> location(
  String id,
  String name,
  String value, {
  String kind = 'province',
  bool legacy = false,
}) => {
  'id': id,
  'name': name,
  'value': value,
  'kind': kind,
  'aliases': [name, value, if (value == 'TP.HCM') 'Sai Gon'],
  'popular': true,
  'isLegacy': legacy,
  'province': null,
};

List<Map<String, dynamic>> catalogue() => [
  location('current:province:79', 'Hồ Chí Minh mới', 'TP.HCM'),
  location('current:province:01', 'Hà Nội', 'Hà Nội'),
  location(
    'legacy:district:672',
    'Thành phố Đà Lạt',
    'Đà Lạt',
    kind: 'district',
    legacy: true,
  ),
  location(
    'station:bx-md',
    'Bến xe Miền Đông',
    'Bến xe Miền Đông',
    kind: 'station',
  ),
];

http.Response reply(Object data) => http.Response(
  jsonEncode({'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test(
    'round trip identity uses canonical API value rather than opaque ID/display name',
    () {
      final cities = catalogue()
          .take(3)
          .map(CityModel.fromLocationJson)
          .toList();
      final request = RoundTripRequest(
        origin: cities.first,
        destination: cities.last,
        departureDate: DateTime(2026, 11, 7),
        returnDate: DateTime(2026, 11, 8),
      );
      final trip = TripModel.fromJson({
        'tripId': 123,
        'route': {'origin': 'TP.HCM', 'destination': 'Đà Lạt'},
        'availableSeats': 2,
      });
      expect(request.accepts(TripLeg.outbound, trip), isTrue);
      expect(
        () => RoundTripRequest(
          origin: cities.first,
          destination: CityModel.fromLocationJson(
            location('legacy:79', 'Other label', 'TP.HCM'),
          ),
          departureDate: DateTime(2026, 11, 7),
          returnDate: DateTime(2026, 11, 8),
        ),
        throwsArgumentError,
      );
    },
  );
  test(
    'catalogue keeps canonical value, aliases/legacy and excludes station controls',
    () async {
      final repo = LocationRepository(
        client: ApiClient(
          httpClient: MockClient((r) async {
            expect(r.url.path, endsWith('/locations'));
            return reply(catalogue());
          }),
        ),
      );
      final cities = await repo.getCities();
      expect(cities, hasLength(3));
      expect(cities.first.id, 'current:province:79');
      expect(cities.first.searchValue, 'TP.HCM');
      expect(cities.last.isLegacy, isTrue);
      expect(CityModel.fromJson(cities.first.toJson()), cities.first);
      expect(() => cities.clear(), throwsUnsupportedError);
    },
  );

  test(
    'catalogue coalesces requests, expires cache and does not cache failures',
    () async {
      var calls = 0;
      var now = DateTime(2026, 11, 6);
      final gate = Completer<http.Response>();
      final repo = LocationRepository(
        now: () => now,
        client: ApiClient(
          httpClient: MockClient((r) async {
            calls++;
            if (calls == 1) return gate.future;
            if (calls == 2) return http.Response('{}', 503);
            return reply(catalogue());
          }),
        ),
      );
      final a = repo.getCities();
      final b = repo.getCities();
      gate.complete(reply(catalogue()));
      expect(await a, same(await b));
      await repo.getCities();
      expect(calls, 1);
      now = now.add(const Duration(minutes: 6));
      await expectLater(repo.getCities(), throwsException);
      await repo.getCities();
      expect(calls, 3);
    },
  );

  for (final invalid in [
    <Object>[],
    [location('x', 'City', '')],
    [location('x', 'City', 'City'), location('x', 'Other', 'Other')],
  ]) {
    test(
      'invalid/empty catalogue fails instead of using bundled locations: $invalid',
      () async {
        final repo = RealTripRepository(
          locations: LocationRepository(
            client: ApiClient(
              httpClient: MockClient((_) async => reply(invalid)),
            ),
          ),
        );
        await expectLater(repo.getCities(), throwsFormatException);
      },
    );
  }

  test(
    'opaque IDs resolve to server value for both directions; unknown ID fails closed',
    () async {
      final queries = <Map<String, String>>[];
      final client = ApiClient(
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/locations')) return reply(catalogue());
          queries.add(r.url.queryParameters);
          return reply([]);
        }),
      );
      final repo = RealTripRepository(
        remoteDataSource: TripRemoteDataSourceImpl(client: client),
      );
      await repo.searchTrips(
        fromCityId: 'current:province:79',
        toCityId: 'legacy:district:672',
      );
      await repo.searchTrips(
        fromCityId: 'legacy:district:672',
        toCityId: 'current:province:79',
      );
      expect(queries.map((q) => (q['from'], q['to'])).toList(), [
        ('TP.HCM', 'Đà Lạt'),
        ('Đà Lạt', 'TP.HCM'),
      ]);
      await expectLater(
        repo.searchTrips(fromCityId: 'current:missing', toCityId: 'DL'),
        throwsFormatException,
      );
      expect(queries, hasLength(2));
    },
  );

  testWidgets(
    'Home and shipment selectors share API catalogue and alias search',
    (tester) async {
      var catalogCalls = 0;
      final client = ApiClient(
        httpClient: MockClient((r) async {
          if (r.url.path.endsWith('/locations')) {
            catalogCalls++;
            return reply(catalogue());
          }
          return reply([]);
        }),
      );
      final repo = RealTripRepository(
        remoteDataSource: TripRemoteDataSourceImpl(client: client),
      );
      final home = HomeBloc(tripRepository: repo);
      home.add(LoadHomeDataEvent());
      await tester.pump();
      final state = home.state;
      expect(state.status, HomeStatus.success, reason: state.errorMessage);
      expect(state.departureCity?.searchValue, 'TP.HCM');
      expect(state.destinationCity?.searchValue, 'Đà Lạt');
      await tester.pumpWidget(
        RepositoryProvider<TripRepository>.value(
          value: repo,
          child: MaterialApp(
            home: ShipmentsHostScreen(repository: FakeShipmentRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shipment_from_city_selector')));
      await tester.pumpAndSettle();
      expect(find.byType(SelectCitySheet), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Sai Gon');
      await tester.pump();
      expect(find.text('Hồ Chí Minh mới'), findsOneWidget);
      expect(find.text('Thành phố Đà Lạt (địa danh cũ)'), findsNothing);
      expect(catalogCalls, 1);
      await tester.tap(find.text('Hồ Chí Minh mới'));
      await tester.pumpAndSettle();
      expect(find.byType(SelectCitySheet), findsNothing);
      expect(find.text('Hồ Chí Minh mới'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(home.close);
    },
  );
}
