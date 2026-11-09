import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/api_exceptions.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/repositories/password_recovery_repository.dart';
import 'package:vexgo_app/features/user/profile/presentation/screens/forgot_password_screen.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/auth_modal_sheet.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

http.Response reply(Object value, [int code = 200]) => http.Response(
  jsonEncode(value),
  code,
  headers: {'content-type': 'application/json'},
);
Map<String, Object> challenge({bool expired = false, bool resend = false}) => {
  'challengeId': 'e82e184a-84cf-4b1b-b0aa-593885779451',
  'expiresAt': DateTime.now()
      .toUtc()
      .add(Duration(minutes: expired ? -1 : 5))
      .toIso8601String(),
  'resendAfter': DateTime.now()
      .toUtc()
      .add(Duration(seconds: resend ? -1 : 60))
      .toIso8601String(),
};
Map<String, Object> proof({bool expired = false}) => {
  'otpProof': 'opaque-single-use-proof',
  'expiresAt': DateTime.now()
      .toUtc()
      .add(Duration(minutes: expired ? -1 : 10))
      .toIso8601String(),
};
PasswordRecoveryRepository repo(
  Future<http.Response> Function(http.Request) handler,
) => PasswordRecoveryRepository(
  client: ApiClient(httpClient: MockClient(handler)),
);
Future<void> host(
  WidgetTester t,
  PasswordRecoveryRepository repository, {
  String phone = '0912345678',
}) async {
  await t.pumpWidget(
    MaterialApp(
      home: ForgotPasswordScreen(initialPhone: phone, repository: repository),
    ),
  );
}

Future<void> tap(WidgetTester t, String text) async {
  final finder = find.text(text).last;
  await t.ensureVisible(finder);
  await t.tap(finder);
  await t.pumpAndSettle();
}

Future<void> otpStep(WidgetTester t) => tap(t, 'Yêu cầu mã OTP');
Future<void> passwordStep(WidgetTester t) async {
  await otpStep(t);
  await t.enterText(find.byType(TextFormField), '123456');
  await tap(t, 'Xác nhận OTP');
}

Future<void> passwords(WidgetTester t, String value) async {
  await t.enterText(find.byType(TextFormField).at(0), value);
  await t.enterText(find.byType(TextFormField).at(1), value);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
  });
  tearDown(TokenStorage.resetStorageAdapter);
  test(
    'exact public contract, normalization, envelope and no session writes',
    () async {
      final calls = <http.Request>[];
      final repository = repo((r) async {
        calls.add(r);
        expect(r.headers.containsKey('Authorization'), false);
        expect(r.url.query, isEmpty);
        return reply({
          'data': r.url.path.endsWith('request-otp')
              ? challenge()
              : r.url.path.endsWith('verify-otp')
              ? proof()
              : {'message': 'ok'},
        });
      });
      final version = TokenStorage.sessionVersion;
      final c = await repository.request(' 0912345678 ');
      final p = await repository.verify('+84912345678', c, '123456');
      await repository.reset('0912345678', p, ' 12345678 ');
      expect(calls.map((r) => r.url.path), [
        '/api/v1/auth/forgot-password/request-otp',
        '/api/v1/auth/forgot-password/verify-otp',
        '/api/v1/auth/forgot-password/reset',
      ]);
      expect(jsonDecode(calls[0].body), {'phoneNumber': '+84912345678'});
      expect(jsonDecode(calls[1].body), {
        'phoneNumber': '+84912345678',
        'challengeId': c.id,
        'otp': '123456',
      });
      expect(jsonDecode(calls[2].body), {
        'phoneNumber': '+84912345678',
        'otpProof': p.value,
        'newPassword': ' 12345678 ',
      });
      expect(TokenStorage.sessionVersion, version);
      expect(TokenStorage.currentToken, isNull);
    },
  );
  test(
    'invalid phone/OTP/UTF8 passwords and malformed deadlines fail closed',
    () async {
      var count = 0;
      final repository = repo((_) async {
        count++;
        return reply({
          'challengeId': 'id',
          'expiresAt': 'not-date',
          'resendAfter': '2026-11-07',
        });
      });
      await expectLater(repository.request('1234'), throwsFormatException);
      expect(count, 0);
      await expectLater(
        repository.request('0912345678'),
        throwsFormatException,
      );
      expect(PasswordRecoveryRepository.validatePassword('a' * 7), isNotNull);
      expect(PasswordRecoveryRepository.validatePassword('a' * 72), isNull);
      expect(PasswordRecoveryRepository.validatePassword('a' * 73), isNotNull);
      expect(PasswordRecoveryRepository.validatePassword('ế' * 25), isNotNull);
      await expectLater(
        repository.verify(
          '0912345678',
          RecoveryChallenge('c', DateTime.now(), DateTime.now()),
          '12345x',
        ),
        throwsFormatException,
      );
      expect(count, 1);
    },
  );
  test(
    'server rejection propagates without fallback or automatic retry',
    () async {
      var calls = 0;
      final repository = repo((_) async {
        calls++;
        return reply({
          'error': 'PHONE_NOT_REGISTERED',
          'message': 'Số điện thoại chưa được đăng ký tài khoản.',
        }, 404);
      });
      await expectLater(
        repository.request('0912345678'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.errorCode,
            'code',
            'PHONE_NOT_REGISTERED',
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test('malformed reset success is not accepted as completion', () async {
    final repository = repo((_) async => reply({'unexpected': true}));
    await expectLater(
      repository.reset(
        '0912345678',
        RecoveryProof('proof', DateTime.now().add(const Duration(minutes: 10))),
        '12345678',
      ),
      throwsFormatException,
    );
  });
  testWidgets(
    'successful journey requires confirmation, stays logged out and clears secrets',
    (t) async {
      var resets = 0;
      await host(
        t,
        repo((r) async {
          if (r.url.path.endsWith('request-otp')) return reply(challenge());
          if (r.url.path.endsWith('verify-otp')) return reply(proof());
          resets++;
          return reply({'message': 'ok'});
        }),
      );
      await passwordStep(t);
      await passwords(t, '12345678');
      await t.enterText(find.byType(TextFormField).at(1), 'different');
      await tap(t, 'Đặt lại mật khẩu');
      expect(resets, 0);
      expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
      await t.enterText(find.byType(TextFormField).at(1), '12345678');
      await tap(t, 'Đặt lại mật khẩu');
      expect(resets, 1);
      expect(find.text('Đặt lại mật khẩu thành công'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(TokenStorage.currentToken, isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'wrong OTP stays on OTP, resend replaces challenge and clears input',
    (t) async {
      var requests = 0;
      var verifies = 0;
      String? id;
      await host(
        t,
        repo((r) async {
          if (r.url.path.endsWith('request-otp')) {
            requests++;
            return reply({
              ...challenge(resend: true),
              'challengeId': 'challenge-$requests',
            });
          }
          verifies++;
          id = jsonDecode(r.body)['challengeId'];
          return reply({
            'error': 'OTP_INVALID',
            'message': 'Mã OTP không hợp lệ.',
          }, 400);
        }),
      );
      await otpStep(t);
      await t.enterText(find.byType(TextFormField), '123456');
      await tap(t, 'Xác nhận OTP');
      expect(find.text('Mã OTP không hợp lệ.'), findsOneWidget);
      expect(id, 'challenge-1');
      await tap(t, 'Gửi lại mã OTP');
      expect(requests, 2);
      expect(
        t.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        isEmpty,
      );
      await t.enterText(find.byType(TextFormField), '654321');
      await tap(t, 'Xác nhận OTP');
      expect(id, 'challenge-2');
      expect(verifies, 2);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('expired OTP cannot verify and cooldown prevents early resend', (
    t,
  ) async {
    var calls = 0;
    await host(
      t,
      repo((_) async {
        calls++;
        return reply(challenge(expired: true));
      }),
    );
    await otpStep(t);
    await t.enterText(find.byType(TextFormField), '123456');
    await tap(t, 'Xác nhận OTP');
    expect(calls, 1);
    expect(find.textContaining('Mã OTP đã hết hạn'), findsOneWidget);
    expect(
      t
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Gửi lại mã sau 60 giây'),
          )
          .onPressed,
      isNull,
    );
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('proof expiry requires new OTP and never submits password', (
    t,
  ) async {
    var calls = 0;
    await host(
      t,
      repo((r) async {
        calls++;
        return reply(
          r.url.path.endsWith('request-otp')
              ? challenge()
              : proof(expired: true),
        );
      }),
    );
    await passwordStep(t);
    await passwords(t, '12345678');
    await tap(t, 'Đặt lại mật khẩu');
    expect(calls, 2);
    expect(find.text('Yêu cầu mã OTP'), findsOneWidget);
    expect(find.textContaining('Xác thực đã hết hạn'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'uncertain reset never reports success or replays consumed proof',
    (t) async {
      var resets = 0;
      await host(
        t,
        repo((r) async {
          if (r.url.path.endsWith('request-otp')) return reply(challenge());
          if (r.url.path.endsWith('verify-otp')) return reply(proof());
          resets++;
          throw http.ClientException('offline');
        }),
      );
      await passwordStep(t);
      await passwords(t, '12345678');
      await tap(t, 'Đặt lại mật khẩu');
      expect(resets, 1);
      expect(find.text('Đặt lại mật khẩu thành công'), findsNothing);
      expect(
        find.textContaining('hãy thử đăng nhập bằng mật khẩu mới'),
        findsOneWidget,
      );
      expect(find.text('Yêu cầu mã OTP'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('single flight and late response after route disposal', (
    t,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    await host(
      t,
      repo((_) {
        calls++;
        return pending.future;
      }),
    );
    await t.tap(find.text('Yêu cầu mã OTP'));
    await t.pump();
    await t.tap(find.byType(FilledButton));
    await t.pump();
    expect(calls, 1);
    await t.pumpWidget(const SizedBox());
    pending.complete(reply(challenge()));
    await t.pump();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'session replacement clears mounted recovery and discards late proof',
    (t) async {
      final pending = Completer<http.Response>();
      await host(
        t,
        repo(
          (r) async => r.url.path.endsWith('request-otp')
              ? reply(challenge())
              : pending.future,
        ),
      );
      await otpStep(t);
      await t.enterText(find.byType(TextFormField), '123456');
      await t.tap(find.text('Xác nhận OTP'));
      await t.pump();
      await TokenStorage.saveTokens(
        accessToken: 'other',
        refreshToken: 'other-refresh',
      );
      await t.pump();
      pending.complete(reply(proof()));
      await t.pumpAndSettle();
      expect(find.text('Đặt mật khẩu mới'), findsNothing);
      expect(
        t.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('Phiên đã thay đổi'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('narrow landscape large text with keyboard remains scrollable', (
    t,
  ) async {
    t.view.reset();
    t.view.physicalSize = const Size(640, 360);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(
            textScaler: const TextScaler.linear(2),
            viewInsets: const EdgeInsets.only(bottom: 120),
          ),
          child: child!,
        ),
        home: ForgotPasswordScreen(
          repository: repo((_) async => reply(challenge())),
          initialPhone: '0912345678',
        ),
      ),
    );
    await otpStep(t);
    await t.enterText(find.byType(TextFormField), '123456');
    await t.ensureVisible(find.text('Xác nhận OTP'));
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('successful return supplies recovery phone to login route', (
    t,
  ) async {
    String? returned;
    final repository = repo(
      (r) async => reply(
        r.url.path.endsWith('request-otp')
            ? challenge()
            : r.url.path.endsWith('verify-otp')
            ? proof()
            : {'message': 'ok'},
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                returned = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => ForgotPasswordScreen(
                      repository: repository,
                      initialPhone: '0912345678',
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tap(t, 'Open');
    await passwordStep(t);
    await passwords(t, '12345678');
    await tap(t, 'Đặt lại mật khẩu');
    await tap(t, 'Về đăng nhập');
    expect(returned, '0912345678');
    expect(find.text('Open'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'login sheet exposes recovery entry and restores login on return',
    (t) async {
      final bloc = AuthBloc(authRepository: FakeAuthRepository());
      addTearDown(bloc.close);
      await t.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: AuthModalSheet()),
          ),
        ),
      );
      await tap(t, 'Quên mật khẩu?');
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(find.text('Đăng nhập VexGo'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump();
    },
  );
}
