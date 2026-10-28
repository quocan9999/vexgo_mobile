import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/network/api_config.dart';
import 'package:vexgo_app/data/models/support_chat_model.dart';
import 'package:vexgo_app/data/models/user_model.dart';
import 'package:vexgo_app/data/repositories/auth_repository.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_bloc.dart';
import 'package:vexgo_app/features/user/profile/bloc/auth_state.dart';
import 'package:vexgo_app/features/user/support_chat/bloc/support_chat_cubit.dart';
import 'package:vexgo_app/features/user/support_chat/presentation/screens/support_chat_screen.dart';
import 'support_chat_regression_test.dart' as fixture;

class WidgetAuthBloc extends AuthBloc {
  WidgetAuthBloc() : super(authRepository: MockAuthRepository());
  void session(int? account) {
    // ignore: invalid_use_of_visible_for_testing_member
    emit(
      account == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(
              status: AuthStatus.authenticated,
              user: UserModel(
                taiKhoanId: account,
                maKhachHang: 'TEST',
                hoTen: 'Test',
                soDienThoai: 'test',
              ),
            ),
    );
  }
}

void main() {
  late fixture.FakeRepository repository;
  late fixture.FakeSocket socket;
  late SupportChatCubit cubit;
  late WidgetAuthBloc auth;
  setUp(() async {
    ApiConfig.isDemoMode = false;
    repository = fixture.FakeRepository();
    socket = fixture.FakeSocket();
    auth = WidgetAuthBloc()..session(7);
    cubit = SupportChatCubit(
      repository: repository,
      socket: socket,
      accessToken: () async => 'fixture-token',
      sessionVersion: () => 0,
    );
    cubit.setSession('7');
    await cubit.activate();
  });
  tearDown(() async {
    await auth.close();
    await cubit.close();
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<SupportChatCubit>.value(value: cubit),
        ],
        child: const MaterialApp(home: SupportChatScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> remove(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets(
    'list opens transcript, sends text, persists after refresh and reopen',
    (tester) async {
      repository.onSend = (id, text, clientId) async {
        final message = ChatMessage.fromJson({
          ...fixture.messageJson(100, conversation: id, clientId: clientId),
          'noiDung': text,
        });
        repository.records[id] = [message];
        return message;
      };
      await open(tester);
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'Xin hỗ trợ chuyến đi',
      );
      await tester.tap(find.byTooltip('Gửi tin nhắn'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Xin hỗ trợ chuyến đi'), findsOneWidget);
      expect(find.textContaining('Đã gửi'), findsOneWidget);
      await tester.tap(find.byTooltip('Tải lại'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Xin hỗ trợ chuyến đi'), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Xin hỗ trợ chuyến đi'), findsOneWidget);
      expect(repository.sends.length, 1);
      await remove(tester);
    },
  );
  testWidgets(
    'mounted transcript and typed draft disappear on session change',
    (tester) async {
      repository.records[1] = [fixture.message(23, sender: 8)];
      await open(tester);
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'Bản nháp riêng',
      );
      expect(find.text('Nội dung 23'), findsOneWidget);
      auth.session(null);
      cubit.setSession(null);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nội dung 23'), findsNothing);
      expect(find.text('Bản nháp riêng'), findsNothing);
      expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
      expect(find.text('Đăng nhập để trò chuyện với nhà xe.'), findsOneWidget);
      await remove(tester);
    },
  );
  testWidgets(
    'staff realtime message renders and exact loaded ID is marked read',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      // The fixture subscription is created in setUp's real async zone.
      await tester.runAsync(() async {
        socket.incoming(
          'support.message.new',
          fixture.messageJson(60, sender: 8),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(cubit.state.messages.map((m) => m.id), [60]);
      expect(find.text('Nội dung 60'), findsOneWidget);
      expect(repository.readCalls, [
        [60],
      ]);
      await remove(tester);
    },
  );
  testWidgets('closed conversation has no composer or send button', (
    tester,
  ) async {
    repository.statuses[1] = 'DA_DONG';
    await open(tester);
    await tester.tap(find.text('Nhà xe 1'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Đã kết thúc'), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
    expect(find.byTooltip('Gửi tin nhắn'), findsNothing);
    await remove(tester);
  });
  testWidgets(
    'offscreen transcript messages remain unread until scrolled into view',
    (tester) async {
      repository.records[1] = List.generate(
        30,
        (i) => fixture.message(i + 1, sender: 8),
      );
      await open(tester);
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      final initialRead = repository.readCalls.expand((ids) => ids).toSet();
      expect(initialRead, isNotEmpty);
      expect(initialRead.contains(1), isFalse);
      expect(initialRead.length, lessThan(30));
      final list = tester.widget<ListView>(find.byType(ListView));
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.readCalls.expand((ids) => ids).contains(1), isTrue);
      await remove(tester);
    },
  );
}
