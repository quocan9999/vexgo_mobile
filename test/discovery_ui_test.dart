import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_card.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/date_selector_strip.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/quick_filter_bar.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/models/trip_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/home/presentation/screens/home_screen.dart';
import 'package:vexgo_app/features/user/search_trips/data/models/trip_filter_model.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_filter_sheet.dart';

class _Trips implements TripRepository {
  bool fail = false;
  @override
  Future<List<CityModel>> getCities() async {
    if (fail) throw Exception('offline');
    return const [
      CityModel(
        id: 'HCM',
        name: 'TP. Hồ Chí Minh',
        region: '',
        isPopular: true,
      ),
      CityModel(id: 'DL', name: 'Đà Lạt', region: '', isPopular: true),
    ];
  }

  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => [];
  @override
  Future<List<OperatorModel>> getOperators() async => [];
  @override
  Future<List<TripModel>> searchTrips({
    required String fromCityId,
    required String toCityId,
    String? date,
  }) async => [];
  @override
  Future<TripModel?> getTripById(String id) async => null;
}

void main() {
  for (final config in [
    (320.0, 740.0, 1.0),
    (320.0, 740.0, 2.0),
    (640.0, 360.0, 1.0),
  ]) {
    testWidgets('Home reflows ${config.$1}x${config.$2} text ${config.$3}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepositoryProvider<TripRepository>(
          create: (_) => _Trips(),
          child: MaterialApp(
            builder: (_, child) => MediaQuery(
              data: MediaQueryData(
                size: Size(config.$1, config.$2),
                textScaler: TextScaler.linear(config.$3),
              ),
              child: child!,
            ),
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn đi đâu?'), findsOneWidget);
      await tester.ensureVisible(find.text('Tìm chuyến'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('HELLOVEXGO'), findsNothing);
    });
  }

  testWidgets(
    'Trip card and filters reflow at large text and select the same trip',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixtures =
          jsonDecode(await rootBundle.loadString('assets/mock_data/trips.json'))
              as List;
      final trip = TripModel.fromJson(
        Map<String, dynamic>.from(fixtures.first),
      );
      TripModel? chosen;
      await tester.pumpWidget(
        MaterialApp(
          home: DiscoveryTheme(
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 740),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      DateSelectorStrip(
                        selectedDate: DateTime.now(),
                        onDateSelected: (_) {},
                        minPrice: trip.discountPrice,
                      ),
                      QuickFilterBar(
                        currentFilter: const TripFilterModel(),
                        currentSort: TripSortType.earliest,
                        onOpenFilterSheet: () {},
                        onOpenSortSheet: () {},
                        onFilterChanged: (_) {},
                      ),
                      TripCard(trip: trip, onSelect: (value) => chosen = value),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Chọn chuyến'));
      await tester.tap(find.text('Chọn chuyến'));
      expect(chosen, same(trip));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Retry recovers Home without losing the header', (tester) async {
    final repo = _Trips()..fail = true;
    await tester.pumpWidget(
      RepositoryProvider<TripRepository>.value(
        value: repo,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bạn muốn đi đâu?'), findsOneWidget);
    expect(find.text('Chưa tải được dữ liệu tìm chuyến'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tìm chuyến'), findsOneWidget);
    expect(find.text('Chưa tải được dữ liệu tìm chuyến'), findsNothing);
  });

  testWidgets('Swap preserves the search navigation payload', (tester) async {
    GoRouterState? submitted;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: '/search-trips',
          builder: (_, state) {
            submitted = state;
            return const Scaffold(body: Text('Search opened'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<TripRepository>(
        create: (_) => _Trips(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.swap_vert_rounded));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tìm chuyến'));
    await tester.tap(find.text('Tìm chuyến'));
    await tester.pumpAndSettle();
    expect(submitted!.uri.queryParameters['fromCityId'], 'DL');
    expect(submitted!.uri.queryParameters['toCityId'], 'HCM');
    expect((submitted!.extra as Map)['ticketCount'], 1);
  });

  testWidgets('Filter sheet returns selected values to the existing flow', (
    tester,
  ) async {
    TripFilterModel? result;
    await tester.pumpWidget(
      MaterialApp(
        home: DiscoveryTheme(
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await TripFilterSheet.show(
                    context,
                    initialFilter: const TripFilterModel(),
                    availableOperators: const ['QA operator'],
                    availableVehicleTypes: const ['QA vehicle'],
                    availableAmenities: const ['WiFi'],
                  );
                },
                child: const Text('Open filters'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buổi sáng (06:00 - 12:00)'));
    await tester.tap(find.text('ÁP DỤNG BỘ LỌC'));
    await tester.pumpAndSettle();
    expect(result!.selectedTimeSlots, [TimeSlot.morning]);
  });
}
