import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:vexgo_app/features/user/support_chat/presentation/widgets/support_chat_composer.dart';
import 'support_chat_regression_test.dart' as fixture;

class TestAuthBloc extends AuthBloc {
  TestAuthBloc() : super(authRepository: MockAuthRepository());

  void setSession(int? accountId) {
    // ignore: invalid_use_of_visible_for_testing_member
    emit(
      accountId == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(
              status: AuthStatus.authenticated,
              user: UserModel(
                taiKhoanId: accountId,
                maKhachHang: 'KH$accountId',
                hoTen: 'Người dùng $accountId',
                soDienThoai: '090123456$accountId',
              ),
            ),
    );
  }
}

void main() {
  setUpAll(() async {
    final fontFile = File('assets/fonts/PlusJakartaSans.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final loader = FontLoader('VexGoJakarta')
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
    }
  });

  late fixture.FakeRepository repository;
  late fixture.FakeSocket socket;
  late SupportChatCubit cubit;
  late TestAuthBloc authBloc;

  setUp(() async {
    ApiConfig.isDemoMode = false;
    repository = fixture.FakeRepository();
    socket = fixture.FakeSocket();
    authBloc = TestAuthBloc()..setSession(7);
    cubit = SupportChatCubit(
      repository: repository,
      socket: socket,
      accessToken: () async => 'test-token',
      sessionVersion: () => 0,
    );
    cubit.setSession('7');
    await cubit.activate();
  });

  tearDown(() async {
    await authBloc.close();
    await cubit.close();
  });

  Widget buildApp({
    double textScale = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<SupportChatCubit>.value(value: cubit),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'VexGoJakarta'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child!,
        ),
        home: const SupportChatScreen(),
      ),
    );
  }

  Future<void> pumpView(
    WidgetTester tester, {
    double textScale = 1.0,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      buildApp(textScale: textScale, viewInsets: viewInsets),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final keepConversation in [true, false]) {
    testWidgets(
      'landscape keyboard confirmation can ${keepConversation ? 'keep draft and focus' : 'close after confirmation'}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(640, 360);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await cubit.select(fixture.fixtureConversation(1));
        await pumpView(
          tester,
          textScale: 2,
          viewInsets: const EdgeInsets.only(bottom: 160),
        );
        final composerFinder = find.byKey(const ValueKey('chat-composer'));
        await tester.enterText(composerFinder, 'Giữ bản nháp này');
        final composer = tester.widget<TextField>(composerFinder);
        composer.controller!.selection = const TextSelection.collapsed(
          offset: 4,
        );
        final editorBefore = tester.state<EditableTextState>(
          find.descendant(
            of: composerFinder,
            matching: find.byType(EditableText),
          ),
        );
        expect(editorBefore.widget.focusNode.hasFocus, isTrue);

        await tester.tap(find.byTooltip('Kết thúc hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(editorBefore.widget.focusNode.hasFocus, isFalse);
        expect(repository.closeCalls, 0);
        expect(find.byKey(const ValueKey('chat-composer')), findsNothing);

        // Updating hidden history must not mark its messages read while the
        // confirmation replaces the active transcript.
        repository.records[1] = [fixture.message(81, sender: 8)];
        await cubit.refresh();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(repository.readCalls.expand((ids) => ids), isNot(contains(81)));

        final action = find.text(
          keepConversation ? 'Giữ hội thoại' : 'Kết thúc',
        );
        await tester.ensureVisible(action);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(action);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        if (keepConversation) {
          expect(repository.closeCalls, 0);
          final editorAfter = tester.state<EditableTextState>(
            find.descendant(
              of: composerFinder,
              matching: find.byType(EditableText),
            ),
          );
          expect(identical(editorBefore, editorAfter), isTrue);
          expect(editorAfter.widget.focusNode.hasFocus, isTrue);
          expect(composer.controller!.text, 'Giữ bản nháp này');
          expect(composer.controller!.selection.baseOffset, 4);
          expect(
            tester.getBottomRight(find.byTooltip('Gửi tin nhắn')).dy,
            lessThanOrEqualTo(200),
          );
          expect(repository.readCalls.expand((ids) => ids), contains(81));
        } else {
          expect(repository.closeCalls, 1);
          expect(cubit.state.selected!.closed, isTrue);
          expect(composerFinder, findsNothing);
        }
      },
    );
  }

  testWidgets(
    'send target remains at least 48dp in normal and dense composer',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      for (final dense in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SupportChatComposer(
                controller: controller,
                isDense: dense,
                onChanged: (_) {},
                onSend: () {},
              ),
            ),
          ),
        );
        final size = tester.getSize(find.byTooltip('Gửi tin nhắn'));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }
    },
  );

  group('Group 1: Guest & Login Gate Tests', () {
    testWidgets(
      'Guest / unauthenticated view renders greeting, login CTA, and no conversation cards',
      (tester) async {
        authBloc.setSession(null);
        cubit.setSession(null);
        await pumpView(tester);

        expect(
          find.text('Đăng nhập để trò chuyện với nhà xe.'),
          findsOneWidget,
        );
        expect(find.text('Đăng nhập'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
      },
    );

    testWidgets('Demo mode renders online-service requirement', (tester) async {
      ApiConfig.isDemoMode = true;
      await pumpView(tester);

      expect(
        find.text('Chat cần kết nối máy chủ ở chế độ trực tuyến.'),
        findsOneWidget,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
    });
  });

  group('Group 2: Conversation List & Company Picker Tests', () {
    testWidgets(
      'Empty conversation list displays empty state message and new conversation CTA',
      (tester) async {
        repository.onConversations = (page) async => const ChatPage([], 0);
        await cubit.loadConversations();
        await pumpView(tester);

        expect(
          find.text(
            'Bạn chưa có hội thoại nào. Chọn “Hội thoại mới” để liên hệ nhà xe.',
          ),
          findsOneWidget,
        );
        expect(find.text('Hội thoại mới'), findsOneWidget);
      },
    );

    testWidgets(
      'Conversation list renders cards with long company name, 2-line preview, and status badge without overflow',
      (tester) async {
        repository.onConversations = (page) async => ChatPage([
          const ChatConversation(
            id: 1,
            companyId: 1,
            companyName:
                'Công ty Cổ phần Xe khách Phương Trang FUTA Bus Lines Chi nhánh Miền Nam',
            status: 'DANG_XU_LY',
            title: 'Hỗ trợ chuyến đi',
            preview:
                'Dạ em muốn hỏi xe xuất bến lúc mấy giờ ạ? Em đang ở bến xe Miền Tây đợi.',
          ),
          const ChatConversation(
            id: 2,
            companyId: 2,
            companyName: 'Nhà xe Thành Bưởi',
            status: 'DA_DONG',
            title: 'Hỏi vé',
            preview: 'Cảm ơn nhà xe đã hỗ trợ nhiệt tình!',
          ),
        ], 1);
        await cubit.loadConversations();
        await pumpView(tester);

        expect(
          find.textContaining('Phương Trang FUTA Bus Lines'),
          findsOneWidget,
        );
        expect(find.text('Đang hỗ trợ'), findsOneWidget);
        expect(find.text('Đã kết thúc'), findsOneWidget);
        expect(
          find.textContaining('Dạ em muốn hỏi xe xuất bến lúc mấy giờ'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Pagination triggers loadConversations(more: true) when tapping load more',
      (tester) async {
        int pageRequested = 1;
        repository.onConversations = (page) async {
          pageRequested = page;
          return ChatPage([fixture.fixtureConversation(1)], 3);
        };
        await cubit.loadConversations();
        await pumpView(tester);

        expect(find.text('Tải thêm hội thoại'), findsOneWidget);
        await tester.tap(find.text('Tải thêm hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(pageRequested, 2);
      },
    );

    testWidgets(
      'Company picker displays companies, taps to start conversation, and closes picker',
      (tester) async {
        await pumpView(tester);

        expect(find.text('Hội thoại mới'), findsOneWidget);
        await tester.tap(find.text('Hội thoại mới'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Chọn nhà xe'), findsOneWidget);
        expect(find.text('Nhà xe 1'), findsOneWidget);
        expect(find.text('Mở hoặc tiếp tục hội thoại'), findsOneWidget);

        // Tap company to start conversation
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
      },
    );
  });

  group('Group 3: Transcript & Message Delivery UX Tests', () {
    testWidgets(
      'Transcript renders own message, staff message with badge, and system message',
      (tester) async {
        repository.records[1] = [
          fixture.message(10, sender: 7), // own message (sender 7 == session 7)
          fixture.message(
            11,
            sender: 8,
          ), // staff message (sender 8 != session 7)
          ChatMessage.fromJson({
            ...fixture.messageJson(12, sender: 99),
            'loaiNguoiGui': 'HE_THONG',
            'noiDung': 'Nhân viên đã tiếp nhận yêu cầu hỗ trợ.',
          }),
        ];

        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Nội dung 10'), findsOneWidget);
        expect(find.textContaining('Đã gửi'), findsOneWidget);

        expect(find.text('Nội dung 11'), findsOneWidget);
        expect(find.text('Nhân viên hỗ trợ'), findsOneWidget);

        expect(
          find.text('Nhân viên đã tiếp nhận yêu cầu hỗ trợ.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Image message type displays [Hình ảnh] prefix correctly', (
      tester,
    ) async {
      repository.records[1] = [
        ChatMessage.fromJson({
          ...fixture.messageJson(15, sender: 8),
          'loaiTinNhan': 'HINH_ANH',
          'noiDung': 'https://example.com/ticket.jpg',
        }),
      ];

      await pumpView(tester);
      await tester.tap(find.text('Nhà xe 1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('[Hình ảnh] https://example.com/ticket.jpg'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Sending status displays "Đang gửi…" and failed status displays "Chưa xác nhận gửi" with retry button',
      (tester) async {
        repository.records[1] = [
          ChatMessage(
            id: 101,
            conversationId: 1,
            senderId: 7,
            clientId: 'client-sending-1',
            content: 'Tin nhắn đang gửi đi...',
            senderType: 'KHACH_HANG',
            createdAt: DateTime.parse('2026-10-28T10:00:00Z'),
            delivery: ChatDelivery.sending,
          ),
          ChatMessage(
            id: 102,
            conversationId: 1,
            senderId: 7,
            clientId: 'client-failed-1',
            content: 'Tin nhắn bị mất mạng',
            senderType: 'KHACH_HANG',
            createdAt: DateTime.parse('2026-10-28T10:01:00Z'),
            delivery: ChatDelivery.failed,
          ),
        ];

        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Tin nhắn đang gửi đi...'), findsOneWidget);
        expect(find.textContaining('Đang gửi…'), findsOneWidget);

        expect(find.text('Tin nhắn bị mất mạng'), findsOneWidget);
        expect(find.textContaining('Chưa xác nhận gửi'), findsOneWidget);
        expect(find.text('Thử gửi lại'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Thử gửi lại'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'Load older messages button appears when hasOlder is true and triggers fetch',
      (tester) async {
        repository.records[1] = List.generate(
          30,
          (i) => fixture.message(i + 1, sender: 7),
        );

        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // State hasOlder is true
        expect(cubit.state.hasOlder, isTrue);

        // Scroll to the end of reversed list to see the header button
        final list = tester.widget<ListView>(find.byType(ListView));
        list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Tải tin nhắn trước'), findsOneWidget);

        await tester.tap(find.text('Tải tin nhắn trước'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(repository.messageCalls.length, greaterThanOrEqualTo(2));
      },
    );
  });

  group('Group 4: Realtime & Session Safety Tests', () {
    testWidgets(
      'Typing indicator displays "Nhân viên đang nhập…" when staff is typing',
      (tester) async {
        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Nhân viên đang nhập…'), findsNothing);

        await tester.runAsync(() async {
          socket.incoming('support.typing', {
            'cuocTroChuyenId': 1,
            'taiKhoanId': 8,
            'isTyping': true,
          });
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Nhân viên đang nhập…'), findsOneWidget);
      },
    );

    testWidgets('Reconnect banner appears when socket is disconnected', (
      tester,
    ) async {
      socket.ready = false;
      await pumpView(tester);

      expect(find.textContaining('Realtime đang kết nối lại'), findsOneWidget);
    });

    testWidgets(
      'Confirm close banner appears on stop action, cancel dismisses, and confirm dispatches close',
      (tester) async {
        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Open confirm close
        await tester.tap(find.byTooltip('Kết thúc hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(
            'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.',
          ),
          findsOneWidget,
        );
        expect(find.text('Giữ hội thoại'), findsOneWidget);
        expect(find.text('Kết thúc'), findsOneWidget);

        // Cancel
        await tester.tap(find.text('Giữ hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(
            'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.',
          ),
          findsNothing,
        );
        expect(repository.closeCalls, 0);

        // Open again and confirm
        await tester.tap(find.byTooltip('Kết thúc hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Kết thúc'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(repository.closeCalls, 1);
        expect(find.text('Đã kết thúc'), findsOneWidget);
        expect(find.byKey(const ValueKey('chat-composer')), findsNothing);
      },
    );
  });

  group('Group 5: Responsive, Text Scale & Review Probes Tests', () {
    testWidgets(
      'Standard phone (390x844, 1.0x text scale) renders conversation list and transcript cleanly',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpView(tester, textScale: 1.0);
        expect(find.text('Chat với nhà xe'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Compact narrow phone (320x740, 2.0x text scale) renders without RenderFlex overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        repository.records[1] = [
          fixture.message(1, sender: 7),
          fixture.message(2, sender: 8),
        ];

        await pumpView(tester, textScale: 2.0);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Nội dung 1'), findsOneWidget);
        expect(find.text('Nội dung 2'), findsOneWidget);
        expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'F01 Review Probe: close confirmation fits 320dp at text scale 2 without overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await cubit.select(fixture.fixtureConversation(1));
        await pumpView(tester, textScale: 2.0);

        await tester.tap(find.byTooltip('Kết thúc hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.text(
            'Kết thúc hội thoại này? Bạn có thể mở hội thoại mới sau đó.',
          ),
          findsOneWidget,
        );
        expect(find.text('Giữ hội thoại'), findsOneWidget);
        expect(find.text('Kết thúc'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Verify actions are clickable without overflow
        await tester.tap(find.text('Giữ hội thoại'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'F02 Review Probe: landscape transcript remains usable with actual 160dp keyboard inset at text scale 2',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(640, 360);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await cubit.select(fixture.fixtureConversation(1));
        await pumpView(
          tester,
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 160),
        );

        expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(
          tester.getBottomRight(find.byTooltip('Gửi tin nhắn')).dy,
          lessThanOrEqualTo(200),
        );
      },
    );

    testWidgets(
      'Landscape phone with open keyboard (640x360, 2.0x text scale) renders without overflow',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(640, 360);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpView(
          tester,
          textScale: 2.0,
          viewInsets: const EdgeInsets.only(bottom: 160),
        );
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byKey(const ValueKey('chat-composer')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Composer preserves draft across orientation change (320x740 -> 640x360)',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 740);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);

        await pumpView(tester);
        await tester.tap(find.text('Nhà xe 1'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.enterText(
          find.byKey(const ValueKey('chat-composer')),
          'Nội dung nháp kiểm tra xoay màn hình',
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Rotate to landscape
        tester.view.physicalSize = const Size(640, 360);
        await tester.pump(const Duration(milliseconds: 300));

        final composer = tester.widget<TextField>(
          find.byKey(const ValueKey('chat-composer')),
        );
        expect(
          composer.controller!.text,
          'Nội dung nháp kiểm tra xoay màn hình',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
