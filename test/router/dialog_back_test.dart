// Regression: framework routes (dialogs / sheets) live on the ROOT navigator
// above the shell route. Back requests must pop them BEFORE any of our own
// pages — consulting the branch navigator first used to pop the page beneath
// an open dialog and leave it floating.
// 回归：框架级路由（dialog / sheet）位于 root navigator、处于 shell route 之
// 上。返回请求必须先于我们自己的页面 pop 它们——此前先询问 branch navigator
// 会 pop 掉对话框下方的页面，让对话框悬浮原地。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('dialog vs back', () {
    testWidgets('system back dismisses the dialog, not the page', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);
      expect(find.text('dialog'), findsOneWidget);

      expect(await delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/detail');
    });

    testWidgets('Escape dismisses the dialog, not the page', (tester) async {
      await _pumpApp(tester);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);
      expect(find.text('dialog'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/detail');
    });

    testWidgets('maybePop dismisses the dialog, not the page', (tester) async {
      await _pumpApp(tester);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/detail');
    });

    testWidgets('popFrom inside the dialog dismisses the dialog', (
      tester,
    ) async {
      await _pumpApp(tester);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);
      expect(find.text('dialog'), findsOneWidget);

      ZeroNav.of(
        tester.element(find.text('dialog')),
      ).popFrom(tester.element(find.text('dialog')));
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/detail');
    });

    testWidgets('maybePopFrom inside the dialog dismisses the dialog', (
      tester,
    ) async {
      await _pumpApp(tester);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(
        await ZeroNav.of(
          tester.element(find.text('dialog')),
        ).maybePopFrom(tester.element(find.text('dialog'))),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/detail');
    });

    testWidgets('back after the dialog is gone pops the page', (tester) async {
      final router = await _pumpApp(tester);
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      await _openDialog(tester);

      expect(await delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);

      expect(await delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(nav.location, '/home');
    });

    testWidgets('a dialog over a fullscreen overlay pops the dialog first', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      // `/home/preview` is a fullscreen overlay page.
      // `/home/preview` 是 fullscreen 覆盖页。
      nav.open('/home/preview');
      await tester.pumpAndSettle();
      expect(nav.location, '/home/preview');

      // Open a dialog FROM the overlay page (root navigator, above it).
      // 从覆盖页打开对话框（root navigator，位于其上方）。
      showDialog(
        context: tester.element(find.text('preview')),
        builder: (context) => const AlertDialog(content: Text('dialog')),
      );
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);

      expect(await delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsNothing);
      expect(nav.location, '/home/preview');
    });
  });
}

Future<ZeroRouter> _pumpApp(WidgetTester tester) async {
  final router = _buildRouter();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(size: Size(400, 900)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _openDialog(WidgetTester tester) async {
  // The detail page is on top; both pages are mounted, so take the last.
  // detail 页在上层；两个页面同时挂载，取最后一个。
  showDialog(
    context: tester.element(find.text('open-dialog').last),
    builder: (context) => const AlertDialog(content: Text('dialog')),
  );
  await tester.pumpAndSettle();
}

ZeroRouter _buildRouter() {
  return ZeroRouter(
    initialLocation: '/home',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => Scaffold(body: child),
        tabs: [
          ZeroTab(
            initialLocation: '/home',
            routes: [
              ZeroRoute(
                path: '/home',
                builder: (context, state) => Scaffold(
                  body: ListView(
                    children: [
                      Builder(
                        builder: (context) => ListTile(
                          title: const Text('open-dialog'),
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) =>
                                const AlertDialog(content: Text('dialog')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                routes: [
                  ZeroRoute(
                    path: 'detail',
                    builder: (context, state) => Scaffold(
                      body: ListView(
                        children: const [ListTile(title: Text('open-dialog'))],
                      ),
                    ),
                  ),
                  ZeroRoute(
                    path: 'preview',
                    fullscreen: true,
                    builder: (context, state) =>
                        const Center(child: Card(child: Text('preview'))),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
