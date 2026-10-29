import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/core/network/token_storage.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/profile/presentation/screens/profile_screen.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/auth_modal_sheet.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/change_password_dialog.dart';
import 'package:vexgo_app/features/user/profile/presentation/widgets/edit_profile_dialog.dart';

class _MockProfileAuthRepo extends MockAuthRepository {
  UserModel? user;
  final List<UserModel> updateProfileCalls = [];
  int logoutCalls = 0;

  _MockProfileAuthRepo({this.user});

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    updateProfileCalls.add(updatedUser);
    user = updatedUser;
    return updatedUser;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    user = null;
  }

  @override
  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return 'Đổi mật khẩu thành công.';
  }
}

UserModel _createTestUser({
  int id = 101,
  String customerCode = 'KH00101',
  String fullName = 'Nguyễn Văn An',
  String phone = '0901234567',
  String? email = 'an.nguyen@vexgo.vn',
  String? cccd = '079200001234',
  String? dob = '1995-10-20',
  bool phoneVerified = true,
  int points = 850,
}) {
  return UserModel(
    taiKhoanId: id,
    maKhachHang: customerCode,
    hoTen: fullName,
    soDienThoai: phone,
    email: email,
    cccd: cccd,
    ngaySinh: dob,
    daXacThucSoDienThoai: phoneVerified,
    diemTichLuy: points,
  );
}

void main() {
  setUpAll(() async {
    final fontFile = File('assets/fonts/PlusJakartaSans.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final fontLoader = FontLoader('VexGoJakarta')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
    }
  });

  setUp(() {
    TokenStorage.setStorageAdapterForTesting(InMemorySecureStorageAdapter());
    ApiConfig.isDemoMode = false;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ProfileScreen Comprehensive UI Tests', () {
    late _MockProfileAuthRepo repo;
    late AuthBloc authBloc;
    late UserModel testUser;

    setUp(() {
      testUser = _createTestUser();
      repo = _MockProfileAuthRepo(user: testUser);
      authBloc = AuthBloc(authRepository: repo);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('Guest view shows greeting, login CTA, and no private data', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Page Title
      expect(find.text('Tài khoản'), findsOneWidget);

      // Guest Card
      expect(find.text('Chào mừng bạn đến với VexGo'), findsOneWidget);
      expect(
        find.text(
          'Đăng nhập để đặt vé thuận tiện và quản lý thông tin chuyến đi',
        ),
        findsOneWidget,
      );
      expect(find.text('ĐĂNG NHẬP / ĐĂNG KÝ'), findsOneWidget);

      // No private user data
      expect(find.text('Nguyễn Văn An'), findsNothing);
      expect(find.text('0901234567'), findsNothing);
      expect(find.textContaining('điểm'), findsNothing);
      expect(find.text('Đăng xuất tài khoản'), findsNothing);

      // App Info section exists
      expect(find.text('THÔNG TIN ỨNG DỤNG'), findsOneWidget);
      expect(find.text('Ngôn ngữ'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);

      // Tapping CTA opens AuthModalSheet
      await tester.tap(find.text('ĐĂNG NHẬP / ĐĂNG KÝ'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthModalSheet), findsOneWidget);
    });

    testWidgets(
      'Authenticated view displays user card, points, and clean real menu items',
      (tester) async {
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // User Header
        expect(find.text('Nguyễn Văn An'), findsOneWidget);
        expect(find.text('0901234567'), findsOneWidget);
        expect(find.text('an.nguyen@vexgo.vn'), findsOneWidget);

        // Avatar Initial
        expect(find.text('N'), findsOneWidget);

        // Real points card
        expect(find.text('Điểm tích lũy VexGo'), findsOneWidget);
        expect(find.text('850 điểm'), findsOneWidget);

        // Account management section
        expect(find.text('QUẢN LÝ TÀI KHOẢN'), findsOneWidget);
        expect(find.text('Thông tin cá nhân'), findsOneWidget);
        expect(find.text('Đổi mật khẩu'), findsOneWidget);

        // Invariants: No fake stats, no fake hotline, no fake tiers
        expect(find.text('Chuyến đã đi'), findsNothing);
        expect(find.text('Voucher'), findsNothing);
        expect(find.textContaining('1900 6067'), findsNothing);
        expect(find.textContaining('KIM CƯƠNG'), findsNothing);
        expect(find.textContaining('VÀNG'), findsNothing);
        expect(find.text('Danh sách hành khách thường xuyên'), findsNothing);
        expect(find.text('Ví Voucher & Khuyến mãi'), findsNothing);

        // App info
        expect(find.text('THÔNG TIN ỨNG DỤNG'), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);
        expect(find.text('1.0.0'), findsOneWidget);

        // Logout button is present
        expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
      },
    );

    testWidgets(
      'Missing email renders fallback text "Chưa cập nhật email" and long names wrap',
      (tester) async {
        final longUser = _createTestUser(
          fullName: 'Nguyễn Trần Trương Hoàng Long Đại Hiệp',
          email: null,
          points: 0,
        );
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: longUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Nguyễn Trần Trương Hoàng Long Đại Hiệp'),
          findsOneWidget,
        );
        expect(find.text('Chưa cập nhật email'), findsOneWidget);
        expect(find.text('0 điểm'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Logout confirmation dialog: cancel stays, confirm dispatches LogoutEvent',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap logout
        final logoutBtnFinder = find.text('Đăng xuất tài khoản');
        await tester.ensureVisible(logoutBtnFinder);
        await tester.tap(logoutBtnFinder);
        await tester.pumpAndSettle();

        // Dialog appears
        expect(
          find.text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?',
          ),
          findsOneWidget,
        );
        expect(find.text('Ở lại'), findsOneWidget);

        // Tap 'Ở lại' -> closes dialog without logout
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?',
          ),
          findsNothing,
        );
        expect(repo.logoutCalls, 0);

        // Open again and confirm logout
        await tester.tap(logoutBtnFinder);
        await tester.pumpAndSettle();

        // Tap 'Đăng xuất' button inside dialog
        final confirmBtn = find.widgetWithText(FilledButton, 'Đăng xuất');
        expect(confirmBtn, findsOneWidget);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(repo.logoutCalls, 1);
        expect(authBloc.state.isAuthenticated, isFalse);
        expect(find.text('Chào mừng bạn đến với VexGo'), findsOneWidget);
      },
    );
  });

  group('EditProfileDialog Comprehensive UI Tests', () {
    late _MockProfileAuthRepo repo;
    late AuthBloc authBloc;
    late UserModel testUser;

    setUp(() {
      testUser = _createTestUser(
        fullName: 'Trần Văn Bình',
        phone: '0987654321',
        email: 'binh.tran@vexgo.vn',
        cccd: '001200009999',
        dob: '1998-05-15',
        phoneVerified: true,
      );
      repo = _MockProfileAuthRepo(user: testUser);
      authBloc = AuthBloc(authRepository: repo);
      authBloc.emit(
        AuthState(status: AuthStatus.authenticated, user: testUser),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets(
      'Renders pre-filled values, read-only phone and verified badge',
      (tester) async {
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        EditProfileDialog.show(context, user: testUser),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.text('Chỉnh sửa thông tin cá nhân'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'Trần Văn Bình'),
          findsOneWidget,
        );
        expect(find.text('0987654321'), findsOneWidget);
        expect(find.text('Đã xác thực'), findsOneWidget);
        expect(
          find.widgetWithText(TextFormField, 'binh.tran@vexgo.vn'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, '001200009999'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(TextFormField, '1998-05-15'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Empty full name validation blocks submission', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      EditProfileDialog.show(context, user: testUser),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Clear full name
      final nameField = find.widgetWithText(TextFormField, 'Trần Văn Bình');
      await tester.enterText(nameField, '   ');
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.widgetWithText(FilledButton, 'Lưu thay đổi');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Error shown
      expect(find.text('Họ và tên không được để trống'), findsWidgets);
      expect(repo.updateProfileCalls, isEmpty);
      expect(find.byType(EditProfileDialog), findsOneWidget);
    });

    testWidgets('Valid edits dispatch UpdateProfileEvent and close dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      EditProfileDialog.show(context, user: testUser),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Update name and email
      final nameField = find.widgetWithText(TextFormField, 'Trần Văn Bình');
      await tester.enterText(nameField, 'Trần Văn Bình Mới');

      final emailField = find.widgetWithText(
        TextFormField,
        'binh.tran@vexgo.vn',
      );
      await tester.enterText(emailField, 'binh.moi@vexgo.vn');

      // Tap save
      final saveBtn = find.widgetWithText(FilledButton, 'Lưu thay đổi');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Sheet is closed
      expect(find.byType(EditProfileDialog), findsNothing);

      // Repo was called with updated fields
      expect(repo.updateProfileCalls, hasLength(1));
      final updated = repo.updateProfileCalls.first;
      expect(updated.hoTen, 'Trần Văn Bình Mới');
      expect(updated.email, 'binh.moi@vexgo.vn');
      expect(updated.soDienThoai, '0987654321'); // Phone kept unchanged
    });

    testWidgets(
      'Session safety: EditProfileDialog automatically closes on logout or account switch',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        EditProfileDialog.show(context, user: testUser),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileDialog), findsOneWidget);

        // Account switches or logs out
        authBloc.add(const LogoutEvent());
        await tester.pumpAndSettle();

        // Sheet must auto-close to avoid writing A's draft to B
        expect(find.byType(EditProfileDialog), findsNothing);
      },
    );

    testWidgets(
      'F02 Probe: EditProfileDialog retracted properly even when another modal is stacked on top and blocks draft submission',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () =>
                        EditProfileDialog.show(context, user: testUser),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(EditProfileDialog), findsOneWidget);

        // Open another modal dialog on top of the sheet
        final sheetContext = tester.element(find.byType(EditProfileDialog));
        showDialog(
          context: sheetContext,
          builder: (ctx) => const AlertDialog(title: Text('Topmost Modal')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Topmost Modal'), findsOneWidget);
        expect(find.byType(EditProfileDialog), findsOneWidget);

        // Switch account to User B while Topmost Modal is open
        final userB = _createTestUser(
          id: 999,
          customerCode: 'KH00999',
          fullName: 'User B',
          phone: '0999888777',
        );
        authBloc.emit(AuthState(status: AuthStatus.authenticated, user: userB));
        await tester.pump();
        await tester.pumpAndSettle();

        // EditProfileDialog must be retracted from the stack
        expect(find.byType(EditProfileDialog), findsNothing);
        expect(repo.updateProfileCalls, isEmpty);
      },
    );

    testWidgets(
      'F03 Probe: EditProfileDialog preserves CCCD focus and EditableTextState across viewport rotation (320x740 -> 640x360)',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);

        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: Scaffold(body: EditProfileDialog(user: testUser)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find CCCD field
        final cccdInputFinder = find.widgetWithText(TextFormField, '12 chữ số');
        expect(cccdInputFinder, findsOneWidget);
        await tester.tap(cccdInputFinder);
        await tester.pumpAndSettle();

        // Verify focused
        final editableFinder = find.descendant(
          of: cccdInputFinder,
          matching: find.byType(EditableText),
        );
        expect(editableFinder, findsOneWidget);
        final editableBefore = tester.state<EditableTextState>(editableFinder);
        expect(editableBefore.widget.focusNode.hasFocus, isTrue);

        // Rotate to landscape 640x360 (triggers breakpoint switch from Column to Row)
        tester.view.physicalSize = const Size(640, 360);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify EditableTextState is preserved and STILL focused
        final editableAfter = tester.state<EditableTextState>(
          find.descendant(
            of: cccdInputFinder,
            matching: find.byType(EditableText),
          ),
        );
        expect(identical(editableBefore, editableAfter), isTrue);
        expect(editableAfter.widget.focusNode.hasFocus, isTrue);
      },
    );
  });

  group('ChangePasswordDialog Enhanced UI Tests', () {
    late _MockProfileAuthRepo repo;
    late AuthBloc authBloc;
    late UserModel testUser;

    setUp(() {
      testUser = _createTestUser();
      repo = _MockProfileAuthRepo(user: testUser);
      authBloc = AuthBloc(authRepository: repo);
      authBloc.emit(
        AuthState(status: AuthStatus.authenticated, user: testUser),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets(
      'Password visibility toggle flips obscureText and tooltip appropriately',
      (tester) async {
        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: const MaterialApp(
              home: Scaffold(body: ChangePasswordDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially obscured
        final oldFieldFinder = find.byKey(const ValueKey('Mật khẩu hiện tại'));
        expect(oldFieldFinder, findsOneWidget);
        EditableText oldEditable = tester.widget(
          find.descendant(
            of: oldFieldFinder,
            matching: find.byType(EditableText),
          ),
        );
        expect(oldEditable.obscureText, isTrue);

        // Find visibility toggle for old password
        final toggleFinder = find.byTooltip('Hiện mật khẩu hiện tại');
        expect(toggleFinder, findsOneWidget);

        // Tap toggle
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();

        // Now visible
        oldEditable = tester.widget(
          find.descendant(
            of: oldFieldFinder,
            matching: find.byType(EditableText),
          ),
        );
        expect(oldEditable.obscureText, isFalse);
        expect(find.byTooltip('Ẩn mật khẩu hiện tại'), findsOneWidget);
      },
    );

    testWidgets(
      'F01 Probe: ChangePasswordDialog automatically revokes and clears controllers when switching account from A to B',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => ChangePasswordDialog.show(context),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();
        expect(find.byType(ChangePasswordDialog), findsOneWidget);

        // Type current password into form
        await tester.enterText(
          find.byKey(const ValueKey('Mật khẩu hiện tại')),
          'MyOldPass123',
        );
        await tester.pump();

        // User switched from A to B (authenticated user B)
        final userB = _createTestUser(
          id: 202,
          customerCode: 'KH00202',
          fullName: 'Lê Thị Bình',
          phone: '0912345678',
        );
        authBloc.emit(AuthState(status: AuthStatus.authenticated, user: userB));
        await tester.pump();
        await tester.pumpAndSettle();

        // Dialog must be revoked / closed
        expect(find.byType(ChangePasswordDialog), findsNothing);
      },
    );
  });

  group('Profile Responsive & Viewport Matrix Tests (No RenderFlex Overflows)', () {
    late _MockProfileAuthRepo repo;
    late AuthBloc authBloc;
    late UserModel testUser;

    setUp(() {
      testUser = _createTestUser(
        fullName: 'Nguyễn Huỳnh Trọng Nghĩa Cực Dài',
        email: 'nguyen.huynh.trong.nghia.chuyen.xe@vexgo.com.vn',
        points: 12500,
      );
      repo = _MockProfileAuthRepo(user: testUser);
      authBloc = AuthBloc(authRepository: repo);
      authBloc.emit(
        AuthState(status: AuthStatus.authenticated, user: testUser),
      );
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('Standard phone (390x844, 1.0x text scale) renders cleanly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Compact phone (320x740, 2.0x text scale) renders without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              theme: ThemeData(
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(fontSize: 28),
                  bodySmall: TextStyle(fontSize: 24),
                ),
              ),
              home: const MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(2.0),
                  size: Size(320, 740),
                ),
                child: ProfileScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'F04 Probe: Compact phone (320x740, 2.0x text scale inherited by overlay) renders menu and logout dialog without overflow',
      (tester) async {
        final authBloc = AuthBloc(authRepository: repo);
        addTearDown(authBloc.close);
        authBloc.emit(
          AuthState(status: AuthStatus.authenticated, user: testUser),
        );

        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: const Size(320, 740),
                  textScaler: const TextScaler.linear(2.0),
                ),
                child: child!,
              ),
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Menu rendered with no overflow
        expect(find.byType(ProfileScreen), findsOneWidget);
        expect(find.text('Tiếng Việt'), findsOneWidget);
        expect(find.text('1.0.0'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // 2. Open logout confirmation dialog (inherits 320dp and 2.0x text scale via MaterialApp.builder)
        final logoutBtnFinder = find.text('Đăng xuất tài khoản');
        await tester.ensureVisible(logoutBtnFinder);
        await tester.tap(logoutBtnFinder);
        await tester.pumpAndSettle();

        // Verify dialog is open and no overflow occurred
        expect(
          find.text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?',
          ),
          findsOneWidget,
        );
        expect(find.text('Đăng xuất'), findsWidgets);
        expect(find.text('Ở lại'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tap 'Ở lại' to dismiss cleanly
        await tester.tap(find.text('Ở lại'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản VexGo không?',
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Compact phone (320x740, 2.0x text scale) on EditProfileDialog wraps without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2.0),
                  size: Size(320, 740),
                ),
                child: Scaffold(body: EditProfileDialog(user: testUser)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditProfileDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Landscape phone with open keyboard (640x360, 2.0x text scale) scrolls without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(
                  textScaler: TextScaler.linear(2.0),
                  size: Size(640, 360),
                  viewInsets: EdgeInsets.only(bottom: 180),
                ),
                child: Scaffold(body: EditProfileDialog(user: testUser)),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditProfileDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
