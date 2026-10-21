import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';
import 'package:zero_adaptive_link_example/main.dart';

void main() {
  testWidgets('compact width pushes the ticket detail', (tester) async {
    await _pumpExample(tester, 400);
    expect(find.text('Inbox'), findsWidgets);
    expect(find.text('Refund still missing after return'), findsOneWidget);

    await tester.tap(find.text('Refund still missing after return'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-ticket')), findsOneWidget);
    expect(find.text('Ticket #4821'), findsOneWidget);
  });

  testWidgets('expanded width keeps the list beside the detail', (
    tester,
  ) async {
    await _pumpExample(tester, 1000);
    await tester.tap(find.text('Refund still missing after return'));
    await tester.pumpAndSettle();
    // The master list stays visible next to the detail pane.
    // master 列表与详情 pane 并排保持可见。
    expect(find.byKey(const ValueKey('page-inbox')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-ticket')), findsOneWidget);
  });

  testWidgets('width preset chips are rendered', (tester) async {
    await _pumpExample(tester, 1000);
    expect(find.text('Phone 480'), findsOneWidget);
    expect(find.text('Foldable 720'), findsOneWidget);
    expect(find.text('Tablet 1023'), findsOneWidget);
    expect(find.text('Desktop'), findsOneWidget);
  });

  testWidgets('expanded width opens the nested Settings shell', (tester) async {
    await _pumpExample(tester, 1051);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    // Diagnostics: what did the tap actually navigate to?
    // 诊断：这次点击究竟导航到了哪里？
    // Regression guard: tapping the tab once navigated to '/' because the
    // nested default tab failed to match (its `initialLocation` was treated as
    // host-relative), leaving the tab stack empty.
    // 回归防护：曾经点击该 tab 会导航到 '/'——嵌套默认 tab 匹配失败（其
    // `initialLocation` 被当作相对宿主的路径），导致该 tab 的栈为空。
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    expect(nav.location, '/settings/profile');
    expect(find.byKey(const ValueKey('page-profile')), findsOneWidget);
    expect(find.text('Shareable link'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-account')), findsOneWidget);
  });

  testWidgets('width crossing while the nested shell is open', (tester) async {
    await _pumpExample(tester, 1051);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('page-profile')), findsOneWidget);

    // Cross the compact / expanded breakpoint while the nested shell is live:
    // both shell levels hand their pageKey'd subtrees over in the same frame.
    // 嵌套 shell 处于活动状态时跨越 compact / expanded 断点：两层 shell 会
    // 在同帧交接各自带 pageKey 的子树。
    await _resize(tester, 400);
    expect(find.byKey(const ValueKey('page-profile')), findsOneWidget);

    await _resize(tester, 1051);
    expect(find.byKey(const ValueKey('page-profile')), findsOneWidget);
  });

  testWidgets('auth redirect sends /you/billing to the sign-in page', (
    tester,
  ) async {
    await _pumpExample(tester, 400);
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    nav.open('/you/billing');
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    expect(
      find.textContaining('Sign in to continue to /you/billing'),
      findsOneWidget,
    );
  });

  testWidgets('pane side toggle flips master/detail order', (tester) async {
    await _pumpExample(tester, 1440);
    await tester.tap(find.text('Refund still missing after return'));
    await tester.pumpAndSettle();
    // Pane roots carry stable keys, so the geometry assertion never depends on
    // duplicated copy (the breadcrumb bar echoes the detail title).
    // pane 根节点带稳定 key，几何断言因此不依赖会重复的文案（面包屑会复读
    // 详情标题）。
    final master = find.byKey(const ValueKey('page-inbox'));
    final detail = find.byKey(const ValueKey('page-ticket'));
    // Default (expand right): master sits on the left of the detail.
    // 默认（向右展开）：master 位于 detail 左侧。
    expect(
      tester.getTopLeft(master).dx,
      lessThan(tester.getTopLeft(detail).dx),
    );

    await _tapExpand(tester, 'Expand left');
    // Expand left: master moves to the right of the detail.
    // 向左展开：master 移到 detail 右侧。
    expect(
      tester.getTopLeft(master).dx,
      greaterThan(tester.getTopLeft(detail).dx),
    );
  });

  testWidgets('pane side can be flipped back without changing the width', (
    tester,
  ) async {
    await _pumpExample(tester, 1440);
    await tester.tap(find.text('Refund still missing after return'));
    await tester.pumpAndSettle();
    final master = find.byKey(const ValueKey('page-inbox'));
    final detail = find.byKey(const ValueKey('page-ticket'));

    await _tapExpand(tester, 'Expand left');
    expect(
      tester.getTopLeft(master).dx,
      greaterThan(tester.getTopLeft(detail).dx),
    );

    // Regression guard: the SegmentedButton used to keep a stale selection, so
    // the second tap (back to the previously selected side) did nothing until
    // the width changed and rebuilt the bar.
    // 回归防护：SegmentedButton 曾保留过期选中态，导致第二次点击（切回先前
    // 选中一侧）毫无反应，必须改变宽度重建工具条才生效。
    await _tapExpand(tester, 'Expand right');
    expect(
      tester.getTopLeft(master).dx,
      lessThan(tester.getTopLeft(detail).dx),
    );
  });
}

/// Scrolls the preview strip to [label] and taps it.
/// 将预览条滚动到 [label] 并点击。
Future<void> _tapExpand(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Re-pumps the example at a new width (the window was resized).
/// 以新宽度重建示例（相当于窗口被拉宽 / 压窄）。
Future<void> _resize(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: const ExampleApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpExample(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: const ExampleApp(),
    ),
  );
  await tester.pumpAndSettle();
}
