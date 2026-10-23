import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vexgo_app/core/design/discovery_theme.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_card.dart';
import 'package:vexgo_app/features/user/search_trips/presentation/widgets/trip_detail_sheet.dart';
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
  TripModel? tripToReturn;
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
  Future<TripModel?> getTripById(String id) async {
    if (fail) throw Exception('offline');
    return tripToReturn;
  }
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

  testWidgets(
    'Round trip toggle switch enables return date picker when on and hides it when off',
    (tester) async {
      await tester.pumpWidget(
        RepositoryProvider<TripRepository>(
          create: (_) => _Trips(),
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tra cứu vé và xem vé của tôi'), findsNothing);
      expect(find.text('Hôm nay'), findsNothing);
      expect(find.text('Ngày mai'), findsNothing);

      expect(find.text('Khứ hồi'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect((tester.widget(switchFinder) as Switch).value, isFalse);

      expect(find.text('Ngày đi'), findsOneWidget);
      expect(find.text('Ngày về'), findsNothing);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect((tester.widget(switchFinder) as Switch).value, isTrue);
      expect(find.text('Ngày đi'), findsOneWidget);
      expect(find.text('Ngày về'), findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect((tester.widget(switchFinder) as Switch).value, isFalse);
      expect(find.text('Ngày đi'), findsOneWidget);
      expect(find.text('Ngày về'), findsNothing);
    },
  );

  testWidgets('TripCard disables CTA button when sold out', (tester) async {
    const soldOutTrip = TripModel(
      id: 'trip_sold_out',
      operatorId: 'op_1',
      operatorName: 'Phương Trang',
      vehicleType: 'Limousine 34 giường',
      fromCityId: 'HCM',
      fromCityName: 'TP. Hồ Chí Minh',
      toCityId: 'DL',
      toCityName: 'Đà Lạt',
      departureTime: '08:00',
      arrivalTime: '14:00',
      duration: '6 giờ',
      pickupPoint: 'Bến xe Miền Tây',
      pickupAddress: '395 Kinh Dương Vương, An Lạc, Bình Tân',
      dropoffPoint: 'Bến xe Đà Lạt',
      dropoffAddress: '01 Tô Hiến Thành, Phường 3, Đà Lạt',
      originalPrice: 300000,
      discountPrice: 280000,
      availableSeats: 0,
      totalSeats: 34,
      seatLayoutType: 'standard',
      rating: 4.8,
      reviewCount: 120,
      amenities: ['wifi'],
      images: [],
      pickupPoints: [],
      dropoffPoints: [],
    );

    bool wasSelected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripCard(
            trip: soldOutTrip,
            onSelect: (_) => wasSelected = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuyến xe đã hết chỗ'), findsOneWidget);
    final buttonFinder = find.byType(DiscoveryButton);
    expect(buttonFinder, findsOneWidget);
    final buttonWidget = tester.widget<DiscoveryButton>(buttonFinder);
    expect(buttonWidget.onPressed, isNull);

    await tester.tap(buttonFinder, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(wasSelected, isFalse);
  });

  testWidgets('TripDetailSheet shows error state with retry and close', (
    tester,
  ) async {
tester.view.physicalSize = const Size(320, 640);
tester.view.devicePixelRatio = 1;
addTearDown(tester.view.resetPhysicalSize);
addTearDown(tester.view.resetDevicePixelRatio);
    const baseTrip = TripModel(
      id: 'trip_detail_test',
      operatorId: 'op_1',
      operatorName: 'Phương Trang',
      vehicleType: 'Limousine 34 giường',
      fromCityId: 'HCM',
      fromCityName: 'TP. Hồ Chí Minh',
      toCityId: 'DL',
      toCityName: 'Đà Lạt',
      departureTime: '08:00',
      arrivalTime: '14:00',
      duration: '6 giờ',
      pickupPoint: 'Bến xe Miền Tây',
      pickupAddress: '395 Kinh Dương Vương, An Lạc, Bình Tân',
      dropoffPoint: 'Bến xe Đà Lạt',
      dropoffAddress: '01 Tô Hiến Thành, Phường 3, Đà Lạt',
      originalPrice: 300000,
      discountPrice: 280000,
      availableSeats: 10,
      totalSeats: 34,
      seatLayoutType: 'standard',
      rating: 4.8,
      reviewCount: 120,
      amenities: ['wifi'],
      images: [],
      pickupPoints: [],
      dropoffPoints: [],
    );

    final repo = _Trips()..fail = true;

    await tester.pumpWidget(
      RepositoryProvider<TripRepository>.value(
        value: repo,
        child: MaterialApp(
          builder: (_, child) => MediaQuery(data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)), child: child!),
          home: Scaffold(
            body: TripDetailSheet(trip: baseTrip, onSelectTrip: (_) {}),
          ),
        ),
      ),
    );

    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Không thể tải chi tiết chuyến').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải chi tiết chuyến'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);

    repo.fail = false;
    repo.tripToReturn = baseTrip;
    await tester.tap(find.text('Thử lại'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Tiện ích').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải chi tiết chuyến'), findsNothing);
    expect(find.text(baseTrip.operatorName), findsOneWidget);
  });

  testWidgets('TripDetailSheet shows empty state for amenities when empty', (
    tester,
  ) async {
tester.view.physicalSize = const Size(320, 640);
tester.view.devicePixelRatio = 1;
addTearDown(tester.view.resetPhysicalSize);
addTearDown(tester.view.resetDevicePixelRatio);
    const noAmenitiesTrip = TripModel(
      id: 'trip_no_amenities',
      operatorId: 'op_1',
      operatorName: 'Phương Trang',
      vehicleType: 'Limousine 34 giường',
      fromCityId: 'HCM',
      fromCityName: 'TP. Hồ Chí Minh',
      toCityId: 'DL',
      toCityName: 'Đà Lạt',
      departureTime: '08:00',
      arrivalTime: '14:00',
      duration: '6 giờ',
      pickupPoint: 'Bến xe Miền Tây',
      pickupAddress: '395 Kinh Dương Vương, An Lạc, Bình Tân',
      dropoffPoint: 'Bến xe Đà Lạt',
      dropoffAddress: '01 Tô Hiến Thành, Phường 3, Đà Lạt',
      originalPrice: 300000,
      discountPrice: 280000,
      availableSeats: 10,
      totalSeats: 34,
      seatLayoutType: 'standard',
      rating: 4.8,
      reviewCount: 120,
      amenities: [],
      images: [],
      pickupPoints: [],
      dropoffPoints: [],
    );

    final repo = _Trips()..tripToReturn = noAmenitiesTrip;

    await tester.pumpWidget(
      RepositoryProvider<TripRepository>.value(
        value: repo,
        child: MaterialApp(
          builder: (_, child) => MediaQuery(data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(2)), child: child!),
          home: Scaffold(
            body: TripDetailSheet(trip: noAmenitiesTrip, onSelectTrip: (_) {}),
          ),
        ),
      ),
    );

    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Tiện ích').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiện ích'));
    await tester.pumpAndSettle();

    expect(
      find.text('Chưa có thông tin tiện ích cho chuyến xe này'),
      findsOneWidget,
    );
  });

  testWidgets(
    'TripDetailSheet in landscape 640x360 with text 2.0 scrolls content and CTA remains accessible',
    (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const baseTrip = TripModel(
        id: 'trip_landscape_test',
        operatorId: 'op_1',
        operatorName: 'Phương Trang',
        vehicleType: 'Limousine 34 giường',
        fromCityId: 'HCM',
        fromCityName: 'TP. Hồ Chí Minh',
        toCityId: 'DL',
        toCityName: 'Đà Lạt',
        departureTime: '08:00',
        arrivalTime: '14:00',
        duration: '6 giờ',
        pickupPoint: 'Bến xe Miền Tây',
        pickupAddress: '395 Kinh Dương Vương, An Lạc, Bình Tân',
        dropoffPoint: 'Bến xe Đà Lạt',
        dropoffAddress: '01 Tô Hiến Thành, Phường 3, Đà Lạt',
        originalPrice: 300000,
        discountPrice: 280000,
        availableSeats: 10,
        totalSeats: 34,
        seatLayoutType: 'standard',
        rating: 4.8,
        reviewCount: 120,
        amenities: ['WiFi tốc độ cao', 'Nước uống miễn phí', 'Cổng sạc USB'],
        images: ['https://example.com/bus1.jpg', 'https://example.com/bus2.jpg'],
        pickupPoints: [],
        dropoffPoints: [],
      );

      final repo = _Trips()..tripToReturn = baseTrip;
      TripModel? selectedTrip;

      await tester.pumpWidget(
        RepositoryProvider<TripRepository>.value(
          value: repo,
          child: MaterialApp(
            home: DiscoveryTheme(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(640, 360),
                  textScaler: TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: TripDetailSheet(
                    trip: baseTrip,
                    onSelectTrip: (t) => selectedTrip = t,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.text('Tiện ích').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final ctaFinder = find.text('CHỌN CHUYẾN NÀY');
      expect(ctaFinder, findsOneWidget);

      final scrollableFinder = find.byType(Scrollable);
      expect(scrollableFinder, findsWidgets);

      await tester.drag(find.byType(ListView).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Tiện ích'));
      await tester.pumpAndSettle();
      expect(find.text('WiFi tốc độ cao'), findsOneWidget);

      await tester.tap(find.text('Đón / Trả'));
      await tester.pumpAndSettle();
      expect(find.text(baseTrip.pickupPoint), findsOneWidget);

      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();
      expect(selectedTrip, equals(baseTrip));
    },
  );
}
