import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vexgo_app/core/network/api_client.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/datasources/remote/auth_remote_data_source.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/change_password_dialog.dart';

const user = UserModel(
  taiKhoanId: 42,
  maKhachHang: 'KH42',
  hoTen: 'Test',
  soDienThoai: '0901234567',
);

class PasswordRepository extends MockAuthRepository {
  final result = Completer<String>();
  int calls = 0;
  String? oldValue;
  String? newValue;
  @override
  Future<UserModel?> getCurrentUser() async => user;
  @override
  Future<void> logout() async {}
  @override
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    calls++;
    oldValue = oldPassword;
    newValue = newPassword;
    return result.future;
  }
}

Future<AuthBloc> authenticated(PasswordRepository repository) async {
  final bloc = AuthBloc(authRepository: repository);
  final ready = bloc.stream.firstWhere((state) => state.isAuthenticated);
  bloc.add(const CheckAuthStatusEvent());
  await ready;
  return bloc;
}

http.Response response(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    await TokenStorage.saveTokens(
      accessToken: 'test-access',
      refreshToken: 'test-refresh',
    );
  });
  tearDown(TokenStorage.resetStorageAdapter);

  test(
    'real repository sends exact protected password contract without trimming',
    () async {
      final remote = AuthRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient((request) async {
            expect(request.method, 'POST');
            expect(request.url.path.endsWith('/auth/change-password'), isTrue);
            expect(request.headers['authorization'], 'Bearer test-access');
            expect(jsonDecode(request.body), {
              'oldPassword': ' old pass ',
              'newPassword': ' new pass ',
            });
            return response({
              'data': {'message': 'Đổi mật khẩu thành công.'},
            });
          }),
        ),
      );
      final repository = RealAuthRepository(remoteDataSource: remote);
      expect(
        await repository.changePassword(
          oldPassword: ' old pass ',
          newPassword: ' new pass ',
        ),
        'Đổi mật khẩu thành công.',
      );
    },
  );

  test('HTTP 400 and unconfirmed HTTP 200 cannot become success', () async {
    for (final status in [400, 200]) {
      final remote = AuthRemoteDataSourceImpl(
        client: ApiClient(
          httpClient: MockClient(
            (_) async => response(
              status == 400 ? {'message': 'INVALID_OLD_PASSWORD'} : {},
              status,
            ),
          ),
        ),
      );
      await expectLater(
        remote.changePassword(oldPassword: 'old-pass', newPassword: 'new-pass'),
        throwsA(anything),
      );
    }
  });

  test(
    'duplicate submission blocked; network failure retains authenticated user',
    () async {
      final repository = PasswordRepository();
      final bloc = await authenticated(repository);
      addTearDown(bloc.close);
      bloc.add(
        const ChangePasswordEvent(
          oldPassword: 'old-pass',
          newPassword: 'new-pass',
        ),
      );
      bloc.add(
        const ChangePasswordEvent(
          oldPassword: 'old-pass',
          newPassword: 'new-pass',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 1);
      expect(bloc.state.passwordChangeStatus, PasswordChangeStatus.submitting);
      final failed = bloc.stream.firstWhere(
        (state) => state.passwordChangeStatus == PasswordChangeStatus.failure,
      );
      repository.result.completeError(Exception('Mất mạng'));
      await failed;
      expect(bloc.state.user, user);
      expect(bloc.state.isAuthenticated, isTrue);
      expect(bloc.state.passwordChangeError, contains('Mất mạng'));
    },
  );

  test(
    'logout discards late password result without restoring private session',
    () async {
      final repository = PasswordRepository();
      final bloc = await authenticated(repository);
      addTearDown(bloc.close);
      bloc.add(
        const ChangePasswordEvent(
          oldPassword: 'old-pass',
          newPassword: 'new-pass',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final loggedOut = bloc.stream.firstWhere(
        (state) => !state.isAuthenticated,
      );
      bloc.add(const LogoutEvent());
      await loggedOut;
      repository.result.complete('Đổi mật khẩu thành công.');
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.user, isNull);
      expect(bloc.state.passwordChangeStatus, PasswordChangeStatus.idle);
    },
  );

  test(
    'UTF-8 byte limit checked before request and event text redacts secrets',
    () async {
      final repository = PasswordRepository();
      final bloc = await authenticated(repository);
      addTearDown(bloc.close);
      final failed = bloc.stream.firstWhere(
        (state) => state.passwordChangeStatus == PasswordChangeStatus.failure,
      );
      final event = ChangePasswordEvent(
        oldPassword: 'secret-old',
        newPassword: List.filled(25, 'ệ').join(),
      );
      expect(event.toString(), isNot(contains('secret-old')));
      bloc.add(event);
      await failed;
      expect(repository.calls, 0);
    },
  );

  testWidgets(
    'dialog waits for server, keeps errors and preserves password whitespace',
    (tester) async {
      final repository = PasswordRepository();
      final bloc = await authenticated(repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: const MaterialApp(
            home: Scaffold(body: ChangePasswordDialog()),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('Mật khẩu hiện tại')),
        ' old pass ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('Mật khẩu mới')),
        ' new pass ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('Xác nhận mật khẩu mới')),
        ' new pass ',
      );
      await tester.tap(find.text('Lưu mật khẩu'));
      await tester.pump();
      expect(repository.oldValue, ' old pass ');
      expect(repository.newValue, ' new pass ');
      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repository.result.completeError(Exception('Mật khẩu cũ không đúng'));
      await tester.pump();
      expect(find.text('Mật khẩu cũ không đúng'), findsOneWidget);
      expect(find.byType(ChangePasswordDialog), findsOneWidget);
      expect(find.text('Đổi mật khẩu thành công.'), findsNothing);
    },
  );

  for (final outcome in ['account switch', 'logout', 'success']) {
    testWidgets('covered password dialog removes its own route on $outcome', (
      tester,
    ) async {
      final repository = PasswordRepository();
      final bloc = await authenticated(repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => ChangePasswordDialog.show(context),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('Mật khẩu hiện tại')),
        'old-pass',
      );
      if (outcome == 'success') {
        await tester.enterText(
          find.byKey(const ValueKey('Mật khẩu mới')),
          'new-pass',
        );
        await tester.enterText(
          find.byKey(const ValueKey('Xác nhận mật khẩu mới')),
          'new-pass',
        );
        await tester.tap(find.text('Lưu mật khẩu'));
        await tester.pump();
        expect(repository.calls, 1);
      }

      final dialogContext = tester.element(find.byType(ChangePasswordDialog));
      showDialog<void>(
        context: dialogContext,
        builder: (context) => AlertDialog(
          content: const Text('Independent modal'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close independent modal'),
            ),
          ],
        ),
      );
      // Bounded pumps: the submitting form contains an indeterminate spinner.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      if (outcome == 'account switch') {
        // Fixture session transition without changing a real account.
        // ignore: invalid_use_of_visible_for_testing_member
        bloc.emit(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              taiKhoanId: 43,
              maKhachHang: 'KH43',
              hoTen: 'Second account',
              soDienThoai: '0901234568',
            ),
          ),
        );
      } else if (outcome == 'logout') {
        bloc.add(const LogoutEvent());
      } else {
        repository.result.complete('Đổi mật khẩu thành công.');
      }
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordDialog), findsNothing);
      expect(find.text('Independent modal'), findsOneWidget);
      expect(repository.calls, outcome == 'success' ? 1 : 0);
      expect(
        find.text('Đổi mật khẩu thành công.'),
        outcome == 'success' ? findsOneWidget : findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Close independent modal'));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(ChangePasswordDialog), findsNothing);
    });
  }

  testWidgets('dialog closes only after confirmed server success', (
    tester,
  ) async {
    final repository = PasswordRepository();
    final bloc = await authenticated(repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ChangePasswordDialog.show(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('Mật khẩu hiện tại')),
      'old-pass',
    );
    await tester.enterText(
      find.byKey(const ValueKey('Mật khẩu mới')),
      'new-pass',
    );
    await tester.enterText(
      find.byKey(const ValueKey('Xác nhận mật khẩu mới')),
      'new-pass',
    );
    await tester.tap(find.text('Lưu mật khẩu'));
    await tester.pump();
    expect(find.byType(ChangePasswordDialog), findsOneWidget);
    repository.result.complete('Đổi mật khẩu thành công.');
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordDialog), findsNothing);
    expect(find.text('Đổi mật khẩu thành công.'), findsOneWidget);
  });
}
