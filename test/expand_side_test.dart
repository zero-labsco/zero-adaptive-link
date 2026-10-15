import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';

void main() {
  testWidgets('Expand left/right flips the pane side in the example', (
    tester,
  ) async {
    // The preview bar is wide; give the test surface enough room so the
    // "Expand" segmented button is on-screen and tappable.
    // 预览条较宽，给测试窗口足够宽度让 Expand 按钮在屏内可点。
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    // Select a wide (expanded) width preset so the pane layout is used.
    // 选一个宽（expanded）宽度预设，使 pane 布局生效。
    await tester.tap(find.widgetWithText(ChoiceChip, 'Desktop'));
    await tester.pumpAndSettle();

    // Open a ticket so we have two panes (master + detail).
    // 点开一个工单，得到两栏（master + detail）。
    await tester.tap(find.byType(ZeroLink).first);
    await tester.pumpAndSettle();

    final sliding = find.byType(SlidingPanes);
    expect(sliding, findsOneWidget);
    final before = tester.widget<SlidingPanes>(sliding).side;
    expect(
      before,
      SlidingPanesSide.right,
      reason: 'default side should be right',
    );

    final segBefore = tester
        .widget<SegmentedButton<SlidingPanesSide>>(
          find.byType(SegmentedButton<SlidingPanesSide>),
        )
        .selected;
    expect(segBefore, {
      SlidingPanesSide.right,
    }, reason: 'segmented button should start on right');

    // Tap "Expand left" in the preview bar. / 点预览条的 Expand left。
    await tester.tap(find.text('Expand left'));
    await tester.pumpAndSettle();

    final segAfter = tester
        .widget<SegmentedButton<SlidingPanesSide>>(
          find.byType(SegmentedButton<SlidingPanesSide>),
        )
        .selected;
    final after = tester.widget<SlidingPanes>(sliding).side;
    expect(segAfter, {
      SlidingPanesSide.left,
    }, reason: 'segmented button should move to left');
    expect(
      after,
      SlidingPanesSide.left,
      reason: 'tapping Expand left should flip the side',
    );
  });
}
