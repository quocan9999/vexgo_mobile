import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/data/models/notification_model.dart';
import 'package:vexgo_app/data/models/point_transaction_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/data/repositories/notification_repository.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_bloc.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_event.dart';
import 'package:vexgo_app/features/user/notification/bloc/notification_state.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_event.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  UserModel? user;

  FakeAuthRepository({this.user});

  @override
  Future<UserModel?> getCurrentUser() async => user;

  @override
  Future<UserModel> login({required String phone, required String password}) async {
    user = UserModel(
      taiKhoanId: 101,
      maKhachHang: 'KH00101',
      hoTen: 'Nguyễn Văn Test',
      soDienThoai: phone,
      email: 'test@vexgo.vn',
      diemTichLuy: 1200,
      hangThanhVien: 'VÀNG',
      diemToiHangTiepTheo: 3000,
    );
    return user!;
  }

  @override
  Future<void> sendOtp({required String phone}) async {}

  @override
  Future<UserModel> verifyOtpAndRegister({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
  }) async {
    if (otp != '123456') {
      throw Exception('Mã OTP không chính xác hoặc đã hết hạn');
    }
    user = UserModel(
      taiKhoanId: 102,
      maKhachHang: 'KH00102',
      hoTen: fullName,
      soDienThoai: phone,
      diemTichLuy: 0,
      hangThanhVien: 'BẠC',
      diemToiHangTiepTheo: 1000,
    );
    return user!;
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    user = updatedUser;
    return user!;
  }

  @override
  Future<UserModel> redeemPoints({
    required int pointsToRedeem,
    required String rewardTitle,
  }) async {
    if (user == null || user!.diemTichLuy < pointsToRedeem) {
      throw Exception('Điểm tích lũy không đủ');
    }
    final updatedPoints = user!.diemTichLuy - pointsToRedeem;
    final newTx = PointTransactionModel(
      id: 'TX_TEST',
      title: 'Đổi: $rewardTitle',
      points: pointsToRedeem,
      type: PointTransactionType.redeem,
      createdAt: DateTime.now(),
    );
    user = user!.copyWith(
      diemTichLuy: updatedPoints,
      pointHistory: [newTx, ...user!.pointHistory],
    );
    return user!;
  }

  @override
  Future<void> logout() async {
    user = null;
  }
}

class FakeNotificationRepository implements NotificationRepository {
  List<NotificationModel> list;

  FakeNotificationRepository(this.list);

  @override
  Future<List<NotificationModel>> getNotifications() async => list;

  @override
  Future<void> markAsRead(String id) async {
    list = list.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  @override
  Future<void> markAllAsRead() async {
    list = list.map((n) => n.copyWith(isRead: true)).toList();
  }
}

void main() {
  group('AuthBloc & Membership Loyalty Tests', () {
    late FakeAuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      authRepo = FakeAuthRepository(
        user: const UserModel(
          taiKhoanId: 1,
          maKhachHang: 'KH00001',
          hoTen: 'Nguyễn Văn An',
          soDienThoai: '0901234567',
          email: 'an.nguyen@email.com',
          cccd: '079201001234',
          ngaySinh: '1995-05-15',
          diemTichLuy: 1450,
          hangThanhVien: 'VÀNG',
          diemToiHangTiepTheo: 3000,
        ),
      );
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    test('Initial state is unauthenticated before check', () {
      expect(authBloc.state.status, AuthStatus.initial);
      expect(authBloc.state.isAuthenticated, false);
    });

    test('CheckAuthStatusEvent loads current user and marks authenticated', () async {
      authBloc.add(const CheckAuthStatusEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) {
            return s.status == AuthStatus.authenticated &&
                s.user?.hoTen == 'Nguyễn Văn An' &&
                s.user?.tier == MembershipTier.gold &&
                s.user?.diemTichLuy == 1450;
          }),
        ]),
      );
    });

    test('LoginWithPhoneEvent succeeds and updates user info', () async {
      authBloc.add(const LoginWithPhoneEvent(phone: '0988776655', password: 'password123'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.soDienThoai == '0988776655' &&
              s.successMessage?.contains('Đăng nhập thành công') == true),
        ]),
      );
    });

    test('RequestRegisterOtpEvent initiates OTP verification flow', () async {
      authBloc.add(const RequestRegisterOtpEvent(
        phone: '0912345678',
        fullName: 'Trần Văn Mới',
        password: 'pass',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.otpRequired &&
              s.pendingPhone == '0912345678' &&
              s.successMessage?.contains('0912345678') == true),
        ]),
      );
    });

    test('VerifyOtpAndRegisterEvent with incorrect OTP fails with error', () async {
      authBloc.add(const VerifyOtpAndRegisterEvent(
        phone: '0912345678',
        otp: '999999',
        fullName: 'Trần Văn Mới',
        password: 'pass',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.contains('OTP không chính xác')),
        ]),
      );
    });

    test('VerifyOtpAndRegisterEvent with valid OTP succeeds and logs in', () async {
      authBloc.add(const VerifyOtpAndRegisterEvent(
        phone: '0912345678',
        otp: '123456',
        fullName: 'Trần Văn Mới',
        password: 'pass',
      ));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.hoTen == 'Trần Văn Mới' &&
              s.user?.hangThanhVien == 'BẠC'),
        ]),
      );
    });

    test('UpdateProfileEvent updates personal info correctly', () async {
      // First ensure authenticated
      authBloc.add(const CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

      final currentUser = authBloc.state.user!;
      authBloc.add(UpdateProfileEvent(currentUser.copyWith(
        hoTen: 'Nguyễn Văn An Cập Nhật',
        email: 'an.updated@vexgo.vn',
        cccd: '079201009999',
        ngaySinh: '1995-10-20',
      )));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.hoTen == 'Nguyễn Văn An Cập Nhật' &&
              s.user?.email == 'an.updated@vexgo.vn' &&
              s.user?.cccd == '079201009999' &&
              s.successMessage?.contains('thành công') == true),
        ]),
      );
    });

    test('RedeemPointsEvent deducts points and appends to history', () async {
      // First ensure authenticated
      authBloc.add(const CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);

      authBloc.add(const RedeemPointsEvent(
        points: 100,
        rewardTitle: 'Voucher 50.000đ',
      ));

      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.authenticated &&
              s.user?.diemTichLuy == 1350 &&
              s.user?.pointHistory.first.title.contains('Voucher 50.000đ') == true &&
              s.successMessage?.contains('thành công') == true),
        ]),
      );
    });

    test('ToggleLanguageEvent and TogglePushNotificationEvent update preferences', () async {
      authBloc.add(const ToggleLanguageEvent('en'));
      await expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((s) => s.language == 'en')),
      );

      authBloc.add(const TogglePushNotificationEvent(false));
      await expectLater(
        authBloc.stream,
        emits(predicate<AuthState>((s) => s.pushEnabled == false)),
      );
    });

    test('LogoutEvent clears user state to unauthenticated', () async {
      authBloc.add(const LogoutEvent());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          predicate<AuthState>((s) => s.status == AuthStatus.loading),
          predicate<AuthState>((s) =>
              s.status == AuthStatus.unauthenticated &&
              s.user == null &&
              s.successMessage?.contains('đăng xuất') == true),
        ]),
      );
    });
  });

  group('NotificationBloc Tests', () {
    late FakeNotificationRepository notifRepo;
    late NotificationBloc notifBloc;

    final initialList = [
      NotificationModel(
        id: 'NOTIF_1',
        title: 'Chuyến xe sắp khởi hành',
        message: 'Chuyến xe Sài Gòn - Đà Lạt khởi hành lúc 23:00 tối nay.',
        category: NotificationCategory.trip,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
        ticketCode: 'VX-782910',
      ),
      NotificationModel(
        id: 'NOTIF_2',
        title: 'Khuyến mãi hè 20%',
        message: 'Nhập mã HE2026 giảm 20% tối đa 50K.',
        category: NotificationCategory.promo,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
        voucherCode: 'HE2026',
      ),
      NotificationModel(
        id: 'NOTIF_3',
        title: 'Cập nhật điều khoản',
        message: 'VexGo nâng cấp chính sách tích điểm VIP.',
        category: NotificationCategory.system,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];

    setUp(() {
      notifRepo = FakeNotificationRepository(List.from(initialList));
      notifBloc = NotificationBloc(notificationRepository: notifRepo);
    });

    tearDown(() {
      notifBloc.close();
    });

    test('LoadNotificationsEvent loads list and calculates unread count (2 unread)', () async {
      notifBloc.add(const LoadNotificationsEvent());
      await expectLater(
        notifBloc.stream,
        emitsInOrder([
          predicate<NotificationState>((s) => s.status == NotificationStatus.loading),
          predicate<NotificationState>((s) =>
              s.status == NotificationStatus.loaded &&
              s.notifications.length == 3 &&
              s.unreadCount == 2),
        ]),
      );
    });

    test('ChangeNotificationTabEvent filters items by category tab', () async {
      notifBloc.add(const LoadNotificationsEvent());
      await notifBloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

      // Tab 1: Trip
      notifBloc.add(const ChangeNotificationTabEvent(1));
      await expectLater(
        notifBloc.stream,
        emits(predicate<NotificationState>((s) =>
            s.activeTabIndex == 1 &&
            s.filteredNotifications.length == 1 &&
            s.filteredNotifications.first.id == 'NOTIF_1')),
      );

      // Tab 2: Promo
      notifBloc.add(const ChangeNotificationTabEvent(2));
      await expectLater(
        notifBloc.stream,
        emits(predicate<NotificationState>((s) =>
            s.activeTabIndex == 2 &&
            s.filteredNotifications.length == 1 &&
            s.filteredNotifications.first.id == 'NOTIF_2')),
      );
    });

    test('MarkNotificationAsReadEvent updates single item and decrements unread count', () async {
      notifBloc.add(const LoadNotificationsEvent());
      await notifBloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

      notifBloc.add(const MarkNotificationAsReadEvent('NOTIF_1'));
      await expectLater(
        notifBloc.stream,
        emits(predicate<NotificationState>((s) =>
            s.unreadCount == 1 &&
            s.notifications.firstWhere((n) => n.id == 'NOTIF_1').isRead == true)),
      );
    });

    test('MarkAllNotificationsAsReadEvent sets all to read and unread count to 0', () async {
      notifBloc.add(const LoadNotificationsEvent());
      await notifBloc.stream.firstWhere((s) => s.status == NotificationStatus.loaded);

      notifBloc.add(const MarkAllNotificationsAsReadEvent());
      await expectLater(
        notifBloc.stream,
        emits(predicate<NotificationState>((s) =>
            s.unreadCount == 0 &&
            s.notifications.every((n) => n.isRead == true))),
      );
    });
  });
}
