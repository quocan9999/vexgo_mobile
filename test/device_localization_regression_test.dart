import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vexgo_app/core/localization/locale_controller.dart';
import 'package:vexgo_app/core/utils/date_formatter.dart';
import 'package:vexgo_app/core/widgets/flat_filter_bar.dart';
import 'package:vexgo_app/features/user/ai_chatbot/presentation/widgets/ai_chatbot_suggestions_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'VexGoJakarta',
    )..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'))).load();
  });
  tearDown(() => LocaleController.instance.resetForTesting());
  test('Duration and deployed AI categories follow the selected locale', () {
    LocaleController.instance.value = const Locale('en');
    expect(DateFormatter.formatDuration(420), '7 hr');
    expect(DateFormatter.formatDuration(425), '7 hr 5 min');
    expect(DateFormatter.formatDuration(25), '25 min');
    expect(
      DateFormatter.formatDuration(null, fallback: 'server duration'),
      'server duration',
    );
    expect(AiChatbotSuggestionsView.categoryLabel('QUY_DINH'), 'Policies');
    expect(AiChatbotSuggestionsView.categoryLabel('TIM_CHUYEN'), 'Bus trips');
    expect(LocaleController.strings.uiDone, 'Done');
    expect(
      LocaleController.strings.uiSelectUpToSeatsPerBooking('5'),
      contains('5 seats'),
    );
    LocaleController.instance.value = const Locale('vi');
    expect(DateFormatter.formatDuration(425), '7 giờ 5 phút');
    expect(LocaleController.strings.uiDone, 'Xong');
  });
  for (final width in [320.0, 360.0, 384.0, 400.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('English counted ticket tabs fit ${width}dp at ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'VexGoJakarta'),
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => FlatFilterBar(
                    selectedIndex: selected,
                    onChanged: (index) => setState(() => selected = index),
                    options: const [
                      FlatFilterOption(
                        'Upcoming',
                        count: 5,
                        key: Key('upcoming'),
                      ),
                      FlatFilterOption(
                        'Past trips',
                        count: 99,
                        key: Key('past'),
                      ),
                      FlatFilterOption(
                        'Cancelled',
                        count: 4,
                        key: Key('cancelled'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const Key('cancelled')));
        await tester.tap(find.byKey(const Key('cancelled')));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byKey(const Key('cancelled'))).height,
          greaterThanOrEqualTo(48),
        );
      });
    }
  }
}
