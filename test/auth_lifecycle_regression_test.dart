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
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/auth_modal_sheet.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

const profile = UserModel(
  taiKhoanId: 42,
  maKhachHang: 'KH42',
  hoTen: 'Account',
  soDienThoai: '+84912345678',
  email: 'account@example.com',
  diemTichLuy: 725,
);
const profileJson = {
  'accountId': 42,
  'customerCode': 'KH42',
  'fullName': 'Account',
  'phoneNumber': '+84912345678',
  'email': 'account@example.com',
  'citizenId': '079201001234',
  'dateOfBirth': '1995-05-15',
  'loyaltyPoints': 725,
  'phoneVerified': true,
};
http.Response reply(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

class DeferredAuth extends FakeAuthRepository {
  Completer<UserModel>? pendingLogin;
  Completer<UserModel>? pendingUpdate;
  Completer<String>? pendingOtp;
  bool failUpdate = false;
  String? password;
  DeferredAuth() : super(user: profile);
  @override
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    this.password = password;
    return pendingLogin == null ? profile : pendingLogin!.future;
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    if (failUpdate) throw Exception('offline');
    return pendingUpdate == null ? updatedUser : pendingUpdate!.future;
  }

  @override
  Future<String> sendOtp({required String phone}) async =>
      pendingOtp == null ? 'challenge' : pendingOtp!.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() {
    TokenStorage.resetStorageAdapter();
    ApiConfig.resetBaseUrl();
  });
  group('HTTP backend-shaped auth contract fixtures', () {
    for (final register in [false, true]) {
      test(
        '${register ? 'register' : 'login'} fetches full /me rather than session summary',
        () async {
          final paths = <String>[];
          final remote = AuthRemoteDataSourceImpl(
            client: ApiClient(
              httpClient: MockClient((request) async {
                paths.add(request.url.path);
                if (request.url.path.endsWith('/verify-otp')) {
                  return reply({'otpProof': 'proof'});
                }
                if (request.url.path.endsWith('/me')) {
                  expect(request.headers['Authorization'], 'Bearer access');
                  return reply(profileJson);
                }
                return reply({
                  'accessToken': 'access',
                  'refreshToken': 'refresh',
                  'user': {
                    'accountId': 42,
                    'fullName': 'Summary',
                    'phoneNumber': '+84912345678',
                  },
                });
              }),
            ),
          );
          final user = register
              ? await remote.verifyOtpAndRegister(
                  phone: '0912345678',
                  otp: '987654',
                  fullName: 'Account',
                  password: ' password ',
                  challengeId: 'challenge',
                )
              : await remote.login(phone: '0912345678', password: ' password ');
          expect(user.email, 'account@example.com');
          expect(user.diemTichLuy, 725);
          expect(user.cccd, '079201001234');
          expect(user.daXacThucSoDienThoai, true);
          expect(paths.last, endsWith('/me'));
        },
      );
    }
    test(
      'missing token payload fails without synthesizing authenticated profile',
      () async {
        final remote = AuthRemoteDataSourceImpl(
          client: ApiClient(
            httpClient: MockClient((r) async => reply({'user': profileJson})),
          ),
        );
        await expectLater(
          remote.login(phone: '0912345678', password: 'x'),
          throwsFormatException,
        );
        expect(await TokenStorage.getAccessToken(), isNull);
      },
    );
    test('OTP response without challenge fails', () async {
      final remote = AuthRemoteDataSourceImpl(
        client: ApiClient(httpClient: MockClient((r) async => reply({}))),
      );
      await expectLater(
        remote.sendOtp(phone: '0912345678'),
        throwsFormatException,
      );
    });
    test('logout clears locally before remote request completes', () async {
      await TokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
      final arrived = Completer<void>();
      final finish = Completer<http.Response>();
      final remote = AuthRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient((r) {
            expect(jsonDecode(r.body)['refreshToken'], 'r');
            arrived.complete();
            return finish.future;
          }),
        ),
      );
      final logout = remote.logout();
      await arrived.future;
      expect(await TokenStorage.getAccessToken(), isNull);
      expect(await TokenStorage.getRefreshToken(), isNull);
      finish.complete(http.Response('', 204));
      await logout;
    });
    test('delayed login response after logout cannot save tokens', () async {
      final response = Completer<http.Response>();
      final remote = AuthRemoteDataSourceImpl(
        client: ApiClient(httpClient: MockClient((r) => response.future)),
      );
      final login = remote.login(phone: '0912345678', password: 'x');
      final assertion = expectLater(login, throwsStateError);
      await Future<void>.delayed(Duration.zero);
      await remote.logout();
      response.complete(reply({'accessToken': 'old', 'refreshToken': 'old-r'}));
      await assertion;
      expect(await TokenStorage.getAccessToken(), isNull);
    });
    test(
      'delayed /me after token invalidation cannot return old profile',
      () async {
        await TokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
        final response = Completer<http.Response>();
        final started = Completer<void>();
        final remote = AuthRemoteDataSourceImpl(
          client: ApiClient(
            httpClient: MockClient((r) {
              started.complete();
              return response.future;
            }),
          ),
        );
        final request = remote.getCurrentUser();
        final assertion = expectLater(
          request,
          throwsA(anyOf(isA<StateError>(), isA<UnauthorizedException>())),
        );
        await started.future;
        await TokenStorage.clearTokens();
        response.complete(reply(profileJson));
        await assertion;
      },
    );
    test(
      'profile patch sends explicit null to clear optional fields',
      () async {
        await TokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
        final remote = AuthRemoteDataSourceImpl(
          client: ApiClient(
            httpClient: MockClient((r) async {
              final body = jsonDecode(r.body) as Map;
              expect(body.containsKey('email'), true);
              expect(body['email'], isNull);
              expect(body['citizenId'], isNull);
              expect(body['dateOfBirth'], isNull);
              return reply(profileJson);
            }),
          ),
        );
        await remote.updateProfile(fullName: 'Account');
        expect(
          profile.copyWith(email: null, cccd: null, ngaySinh: null).email,
          isNull,
        );
      },
    );
  });
  group('Repository/BLoC lifecycle', () {
    test('profile failure preserves authenticated user', () async {
      final repo = DeferredAuth()..failUpdate = true;
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const CheckAuthStatusEvent());
      await bloc.stream.firstWhere((s) => s.isAuthenticated);
      bloc.add(UpdateProfileEvent(profile));
      final state = await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.failure,
      );
      expect(state.isAuthenticated, true);
      expect(state.user, profile);
    });
    test('late profile update after logout is discarded', () async {
      final repo = DeferredAuth()..pendingUpdate = Completer<UserModel>();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const CheckAuthStatusEvent());
      await bloc.stream.firstWhere((s) => s.isAuthenticated);
      bloc.add(UpdateProfileEvent(profile));
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.loading);
      bloc.add(const LogoutEvent());
      await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.unauthenticated,
      );
      repo.pendingUpdate!.complete(profile);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.user, isNull);
    });
    test(
      'terminal token invalidation clears authenticated UI synchronously',
      () async {
        final bloc = AuthBloc(authRepository: DeferredAuth());
        addTearDown(bloc.close);
        bloc.add(const CheckAuthStatusEvent());
        await bloc.stream.firstWhere((s) => s.isAuthenticated);
        await TokenStorage.clearTokens();
        expect(bloc.state.user, isNull);
      },
    );
    test('registration completion reports no fabricated points', () async {
      final bloc = AuthBloc(authRepository: DeferredAuth());
      addTearDown(bloc.close);
      bloc.add(
        const VerifyOtpAndRegisterEvent(
          phone: '0912345678',
          otp: '123456',
          fullName: 'A',
          password: 'x',
        ),
      );
      final s = await bloc.stream.firstWhere((s) => s.isAuthenticated);
      expect(s.successMessage, isNot(contains('100')));
    });
  });
  testWidgets('login waits for response and preserves password whitespace', (
    tester,
  ) async {
    final repo = DeferredAuth()..pendingLogin = Completer<UserModel>();
    final bloc = AuthBloc(authRepository: repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(home: Scaffold(body: AuthModalSheet())),
      ),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '0912345678');
    await tester.enterText(fields.at(1), ' password ');
    await tester.tap(find.text('ĐĂNG NHẬP NGAY'));
    await tester.pump();
    expect(repo.password, ' password ');
    expect(find.byType(AuthModalSheet), findsOneWidget);
    repo.pendingLogin!.completeError(Exception('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(AuthModalSheet), findsOneWidget);
    expect(find.text('offline'), findsWidgets);
  });
  testWidgets(
    'failed OTP request stays on registration form with no demo OTP hint',
    (tester) async {
      final repo = DeferredAuth()..pendingOtp = Completer<String>();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: AuthModalSheet(initialIsRegister: true)),
          ),
        ),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Account');
      await tester.enterText(fields.at(1), '0912345678');
      await tester.enterText(fields.at(2), 'password');
      await tester.tap(find.text('TIẾP TỤC (XÁC THỰC OTP)'));
      await tester.pump();
      repo.pendingOtp!.completeError(Exception('offline'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Gửi lại mã OTP'), findsNothing);
      expect(find.textContaining('Gợi ý mã thử nghiệm'), findsNothing);
    },
  );
}
