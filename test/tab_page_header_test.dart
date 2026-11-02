import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/widgets/tab_page_header.dart';

void main() {
  testWidgets('Detail header retains native back navigation', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        home: const Scaffold(body: Text('Root')),
      ),
    );
    key.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          appBar: TabPageHeader(title: 'Chi tiết vé xe', showBackButton: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Root'), findsOneWidget);
    expect(find.text('Chi tiết vé xe'), findsNothing);
  });

  testWidgets(
    'Root-tab header respects status inset and keeps large-text action tappable without a back button',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var reads = 0;
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          home: const SizedBox(),
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 740),
              padding: EdgeInsets.only(top: 32),
              textScaler: TextScaler.linear(2),
            ),
            child: child!,
          ),
        ),
      );
      key.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: TabPageHeader(
              title: 'Thông báo',
              actions: [
                TabHeaderAction(
                  label: 'Đọc tất cả',
                  icon: Icons.done_all_rounded,
                  onPressed: () => reads++,
                ),
              ],
            ),
            body: const Text('Nội dung'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsNothing);
      final action = find.byTooltip('Đọc tất cả');
      final actionRect = tester.getRect(
        find.ancestor(of: action, matching: find.byType(IconButton)).first,
      );
      expect(actionRect.top, greaterThanOrEqualTo(32));
      expect(actionRect.width, greaterThanOrEqualTo(48));
      expect(actionRect.height, greaterThanOrEqualTo(48));
      expect(
        tester.getRect(find.text('Nội dung')).top,
        greaterThanOrEqualTo(actionRect.bottom),
      );
      await tester.tap(action);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
