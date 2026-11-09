import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/core/localization/client_labels.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/core/utils/currency_formatter.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/l10n/app_localizations.dart';
import 'package:vexgo_app/data/repositories/booking_repository.dart';
import 'package:vexgo_app/data/repositories/seat_repository.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_bloc.dart';
import 'package:vexgo_app/features/user/booking/bloc/booking_flow_state.dart';
import 'package:vexgo_app/features/user/booking/presentation/steps/step_4_passenger_info.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/presentation/screens/profile_screen.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

class _Seats implements SeatRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Bookings implements BookingRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget localized(Widget child) => ValueListenableBuilder<Locale>(
  valueListenable: LocaleController.instance,
  builder: (_, locale, _) => MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: child,
  ),
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    LocaleController.instance.resetForTesting();
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.isDemoMode = false;
  });
  tearDown(() {
    LocaleController.instance.resetForTesting();
    TokenStorage.resetStorageAdapter();
  });
  test(
    'saved choice, unsupported preference and rapid changes have deterministic results',
    () async {
      final controller = LocaleController.instance;
      await controller.restore();
      expect(controller.value.languageCode, 'vi');
      await controller.select('en');
      controller.value = const Locale('vi');
      await controller.restore();
      expect(controller.value.languageCode, 'en');
      await Future.wait([
        controller.select('vi'),
        controller.select('en'),
        controller.select('vi'),
      ]);
      expect(
        (await SharedPreferences.getInstance()).getString(
          LocaleController.preferenceKey,
        ),
        'vi',
      );
      await expectLater(controller.select('fr'), throwsArgumentError);
      await (await SharedPreferences.getInstance()).setString(
        LocaleController.preferenceKey,
        'fr',
      );
      await controller.restore();
      expect(controller.value.languageCode, 'vi');
    },
  );
  test(
    'ARB locale keys and placeholder sets agree; no blank English messages',
    () {
      final vi =
          jsonDecode(File('lib/l10n/app_vi.arb').readAsStringSync())
              as Map<String, dynamic>;
      final en =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final names = vi.keys.where((k) => !k.startsWith('@')).toSet();
      expect(en.keys.where((k) => !k.startsWith('@')).toSet(), names);
      for (final name in names) {
        expect((en[name] as String).trim(), isNotEmpty, reason: name);
        final pattern = RegExp(r'\{p\d+\}');
        expect(
          pattern.allMatches(en[name]).map((m) => m.group(0)).toSet(),
          pattern.allMatches(vi[name]).map((m) => m.group(0)).toSet(),
          reason: name,
        );
      }
    },
  );
  test(
    'locale changes formatting but not money amount or validation rules',
    () async {
      final date = DateTime(2026, 11, 9);
      expect(DateFormatter.formatFullDate(date), startsWith('Thứ 2'));
      expect(CurrencyFormatter.format(260000), contains('260.000'));
      await LocaleController.instance.select('en');
      expect(DateFormatter.formatFullDate(date), startsWith('Monday'));
      expect(CurrencyFormatter.format(260000), contains('260,000'));
      expect(CurrencyFormatter.format(260000), contains('VND'));
      expect(
        Step4PassengerInfo.validatePhone('invalid'),
        contains('Invalid phone'),
      );
      expect(Step4PassengerInfo.validatePhone('0912345678'), isNull);
      expect(Step4PassengerInfo.validatePhone('+84912345678'), isNull);
    },
  );
  testWidgets(
    'Account language picker changes immediately and remembers the selection',
    (tester) async {
      final auth = AuthBloc(authRepository: FakeAuthRepository());
      addTearDown(auth.close);
      await tester.pumpWidget(
        localized(
          BlocProvider.value(value: auth, child: const ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ngôn ngữ'));
      await tester.tap(find.text('Ngôn ngữ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsNothing);
      expect(auth.state.user, isNull);
      await tester.pump();
      await tester.runAsync(() => LocaleController.instance.pendingWrites);
      expect(
        (await SharedPreferences.getInstance()).getString(
          LocaleController.preferenceKey,
        ),
        'en',
      );
      await tester.ensureVisible(find.text('Language'));
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tiếng Việt'));
      await tester.pumpAndSettle();
      expect(find.text('Tài khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'live language change preserves actual passenger controllers and draft payload',
    (tester) async {
      final bloc = BookingFlowBloc(
        seatRepository: _Seats(),
        bookingRepository: _Bookings(),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        localized(
          Scaffold(
            body: Step4PassengerInfo(
              state: const BookingFlowState(),
              bloc: bloc,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final name = find.byKey(const ValueKey('passenger-name-input'));
      await tester.enterText(name, 'Nguyễn Văn An');
      await tester.pump();
      final field = tester.widget<TextFormField>(name);
      final controller = field.controller!;
      final before = bloc.state.passengerName;
      final persisted = LocaleController.instance.select('en');
      await tester.pumpAndSettle();
      await tester.runAsync(() => persisted);
      expect(
        identical(tester.widget<TextFormField>(name).controller, controller),
        isTrue,
      );
      expect(controller.text, 'Nguyễn Văn An');
      expect(bloc.state.passengerName, before);
      expect(
        find.textContaining('Full name', findRichText: true),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'only known local enum labels translate; user/server text remains intact',
    (tester) async {
      await LocaleController.instance.select('en');
      await tester.pumpWidget(
        localized(
          Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(localizedClientLabel(context, 'Chờ tiếp nhận')),
                  Text(
                    localizedClientLabel(
                      context,
                      'Nội dung riêng của nhà xe Hoa Mai',
                    ),
                  ),
                  Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Waiting for support'), findsOneWidget);
      expect(find.text('Nội dung riêng của nhà xe Hoa Mai'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    },
  );
  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('English account remains usable at $size with 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await LocaleController.instance.select('en');
      final auth = AuthBloc(authRepository: FakeAuthRepository());
      addTearDown(auth.close);
      await tester.pumpWidget(
        localized(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(2),
            ),
            child: BlocProvider.value(
              value: auth,
              child: const ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Version 1.0.0'), 100);
      expect(tester.takeException(), isNull);
    });
  }
}
