import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/edit_profile_dialog.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/auth_modal_sheet.dart';
import 'auth_and_profile_flow_test.dart' show FakeAuthRepository;

const account = UserModel(
  taiKhoanId: 42,
  maKhachHang: 'KH42',
  hoTen: 'QA profile',
  soDienThoai: '+84901234567',
  email: 'qa@example.invalid',
);

class DeferredProfile extends FakeAuthRepository {
  DeferredProfile() : super(user: account);
  final requests = <Completer<UserModel>>[];
  final payloads = <UserModel>[];
  @override
  Future<UserModel> updateProfile(UserModel value) {
    payloads.add(value);
    final pending = Completer<UserModel>();
    requests.add(pending);
    return pending.future;
  }
}

Future<void> authenticate(AuthBloc bloc) async {
  bloc.add(const CheckAuthStatusEvent());
  await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
}

Future<void> showEditor(WidgetTester tester, AuthBloc bloc) async {
  tester.view.physicalSize = const Size(600, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    BlocProvider.value(
      value: bloc,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => EditProfileDialog.show(context, user: account),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(TokenStorage.resetStorageAdapter);

  testWidgets('OTP challenge response does not claim SMS delivery', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = AuthBloc(authRepository: FakeAuthRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(body: AuthModalSheet(initialIsRegister: true)),
        ),
      ),
    );
    Finder field(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
    );
    await tester.enterText(field('Nhập họ và tên đầy đủ'), 'QA profile');
    await tester.enterText(field('Ví dụ: 0987654321'), '0901234567');
    await tester.enterText(field('Nhập mật khẩu'), 'fixture-password');
    await tester.ensureVisible(find.text('TIẾP TỤC (XÁC THỰC OTP)'));
    await tester.tap(find.text('TIẾP TỤC (XÁC THỰC OTP)'));
    await tester.pumpAndSettle();
    expect(find.text('Xác thực mã OTP'), findsOneWidget);
    expect(find.textContaining('đã được gửi'), findsNothing);
    expect(bloc.state.successMessage, contains('được tạo'));
    expect(bloc.state.successMessage, isNot(contains('đã được gửi')));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    'save waits, retains edits after failure, and closes only after confirmed retry',
    (tester) async {
      final repo = DeferredProfile();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      await authenticate(bloc);
      await showEditor(tester, bloc);
      final email = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == 'example@gmail.com',
      );
      await tester.enterText(email, 'updated@example.invalid');
      await tester.ensureVisible(find.text('LƯU THAY ĐỔI'));
      await tester.tap(find.text('LƯU THAY ĐỔI'));
      await tester.pump();
      expect(find.byType(EditProfileDialog), findsOneWidget);
      expect(bloc.state.profileUpdateStatus, ProfileUpdateStatus.submitting);
      expect(
        tester
            .widget<PopScope>(
              find.descendant(
                of: find.byType(EditProfileDialog),
                matching: find.byType(PopScope),
              ),
            )
            .canPop,
        false,
      );
      bloc.add(UpdateProfileEvent(repo.payloads.single));
      await tester.pump();
      expect(repo.requests.length, 1);
      repo.requests.single.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileDialog), findsOneWidget);
      expect(find.textContaining('offline'), findsOneWidget);
      expect(
        tester.widget<TextField>(email).controller!.text,
        'updated@example.invalid',
      );
      expect(bloc.state.isAuthenticated, true);
      expect(bloc.state.user!.email, account.email);
      await tester.tap(find.text('LƯU THAY ĐỔI'));
      await tester.pump();
      expect(repo.requests.length, 2);
      repo.requests.last.complete(repo.payloads.last);
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileDialog), findsNothing);
      expect(bloc.state.user!.email, 'updated@example.invalid');
      expect(bloc.state.profileUpdateStatus, ProfileUpdateStatus.success);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'token invalidation closes editor and discards late profile response',
    (tester) async {
      final repo = DeferredProfile();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      await authenticate(bloc);
      await showEditor(tester, bloc);
      await tester.ensureVisible(find.text('LƯU THAY ĐỔI'));
      await tester.tap(find.text('LƯU THAY ĐỔI'));
      await tester.pump();
      await tester.runAsync(TokenStorage.clearTokens);
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileDialog), findsNothing);
      repo.requests.single.complete(account.copyWith(hoTen: 'Late data'));
      await tester.pumpAndSettle();
      expect(bloc.state.user, isNull);
      expect(bloc.state.profileUpdateStatus, ProfileUpdateStatus.idle);
      expect(bloc.state.successMessage, isNull);
    },
  );

  test(
    'mismatched server profile never replaces authenticated identity',
    () async {
      final repo = DeferredProfile();
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(bloc.close);
      await authenticate(bloc);
      bloc.add(const UpdateProfileEvent(account));
      await bloc.stream.firstWhere(
        (s) => s.profileUpdateStatus == ProfileUpdateStatus.submitting,
      );
      repo.requests.single.complete(account.copyWith(taiKhoanId: 999));
      final result = await bloc.stream.firstWhere(
        (s) => s.profileUpdateStatus == ProfileUpdateStatus.failure,
      );
      expect(result.user!.taiKhoanId, 42);
      expect(result.profileUpdateError, contains('không khớp'));
      expect(result.successMessage, isNull);
    },
  );

  test('guest or stale account payload cannot send profile mutation', () async {
    final repo = DeferredProfile();
    final bloc = AuthBloc(authRepository: repo);
    addTearDown(bloc.close);
    bloc.add(const UpdateProfileEvent(account));
    await Future<void>.delayed(Duration.zero);
    expect(repo.requests, isEmpty);
    await authenticate(bloc);
    bloc.add(UpdateProfileEvent(account.copyWith(taiKhoanId: 999)));
    await Future<void>.delayed(Duration.zero);
    expect(repo.requests, isEmpty);
  });
}
