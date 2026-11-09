import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/app/routes.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/l10n/app_localizations.dart';
import 'package:vexgo_app/data/models/city_model.dart';
import 'package:vexgo_app/data/models/operator_model.dart';
import 'package:vexgo_app/data/models/popular_route_model.dart';
import 'package:vexgo_app/data/repositories/trip_repository.dart';
import 'package:vexgo_app/features/user/home/bloc/home_bloc.dart';
import 'package:vexgo_app/features/user/home/presentation/widgets/search_form_card.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

class _Trips implements TripRepository {
  @override
  Future<List<CityModel>> getCities() async => const [
    CityModel(
      id: 'hcm',
      name: 'TP. Hồ Chí Minh',
      region: 'Miền Nam',
      isPopular: true,
      stations: [],
      backendValue: 'TP.HCM',
    ),
    CityModel(
      id: 'dalat',
      name: 'Đà Lạt',
      region: 'Tây Nguyên',
      isPopular: true,
      stations: [],
      backendValue: 'Đà Lạt',
    ),
  ];
  @override
  Future<List<PopularRouteModel>> getPopularRoutes() async => [];
  @override
  Future<List<OperatorModel>> getOperators() async => [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTesting();
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  tearDown(() {
    LocaleController.instance.resetForTesting();
    TokenStorage.resetStorageAdapter();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'real router Home/Account switches locale at 320dp, scale $scale, preserving search',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final auth = AuthBloc(authRepository: FakeAuthRepository());
        addTearDown(auth.close);
        AppRoutes.router.go(AppRoutes.home);
        await tester.pumpWidget(
          RepositoryProvider<TripRepository>.value(
            value: _Trips(),
            child: BlocProvider.value(
              value: auth,
              child: ValueListenableBuilder<Locale>(
                valueListenable: LocaleController.instance,
                builder: (_, locale, _) => MaterialApp.router(
                  routerConfig: AppRoutes.router,
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(SearchFormCard));
        final home = context.read<HomeBloc>();
        final departure = home.state.departureCity;
        final destination = home.state.destinationCity;
        final date = home.state.departureDate;
        await LocaleController.instance.select('en');
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('My tickets'), findsOneWidget);
        expect(find.text('Shipments'), findsOneWidget);
        expect(find.text('Find trips'), findsOneWidget);
        expect(find.text('Đà Lạt'), findsWidgets);
        expect(identical(context.read<HomeBloc>(), home), isTrue);
        expect(home.state.departureCity, departure);
        expect(home.state.destinationCity, destination);
        expect(home.state.departureDate, date);
        await tester.tap(find.text('Account').last);
        await tester.pumpAndSettle();
        expect(find.text('Language'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await LocaleController.instance.select('vi');
        await tester.pumpAndSettle();
        expect(find.text('Tài khoản'), findsWidgets);
        AppRoutes.router.go(AppRoutes.home);
        await tester.pumpAndSettle();
        expect(home.state.departureCity, departure);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
