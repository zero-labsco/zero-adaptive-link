// Widget-level coverage for the fullscreen overlay stack, the modal route
// properties that must reach `PageRoute` (`barrierDismissible`,
// `fullscreenDialog`), the Escape shortcut, placeholders and breadcrumb
// navigation.
// fullscreen 覆盖栈、必须送达 `PageRoute` 的模态路由属性
// （`barrierDismissible`、`fullscreenDialog`）、Escape 快捷键、占位内容与
// 面包屑导航的 widget 级覆盖。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('fullscreen overlay routes', () {
    testWidgets('barrierDismissible: tapping the barrier dismisses', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400, barrierDismissible: true);
      await _openPreview(tester);
      expect(find.text('preview'), findsOneWidget);
      expect(_location(tester), '/home/preview');

      // The preview content is a small card, so the corner is bare barrier.
      // 预览内容是一张小卡片，角落处即裸露的屏障。
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('preview'), findsNothing);
      expect(_location(tester), '/home');
    });

    testWidgets('barrierDismissible false (default): the tap is inert', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400);
      await _openPreview(tester);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.text('preview'), findsOneWidget);
      expect(_location(tester), '/home/preview');
    });

    testWidgets('a non-opaque overlay keeps the shell visible behind', (
      tester,
    ) async {
      await _pumpApp(tester, width: 1000);
      await _openPreview(tester);
      // The shell (rail) is painted below the overlay, not removed.
      // shell（rail）绘制在覆盖层之下，而非被移除。
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('preview'), findsOneWidget);
    });

    testWidgets('fullscreenDialog reaches the created route', (tester) async {
      PageRoute<dynamic>? captured;
      await _pumpApp(
        tester,
        width: 400,
        onDialogBuilt: (route) => captured = route,
      );
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/dialog');
      await tester.pumpAndSettle();
      expect(find.text('dialog'), findsOneWidget);
      expect(
        captured?.fullscreenDialog,
        isTrue,
        reason: 'ZeroRoute.fullscreenDialog must reach PageRoute',
      );
    });

    testWidgets('maybePop pops the overlay before the branch stack', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(nav.location, '/home/detail');

      await _openPreview(tester);
      expect(nav.location, '/home/preview');

      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(nav.location, '/home/detail');
      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(nav.location, '/home');
    });

    testWidgets('popRoute pops the overlay first', (tester) async {
      final router = await _pumpApp(tester, width: 400);
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await _openPreview(tester);
      expect(delegate.location, '/home/preview');
      expect(await delegate.popRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(delegate.location, '/home');
    });

    testWidgets('Escape dismisses an open overlay', (tester) async {
      await _pumpApp(tester, width: 400);
      await _openPreview(tester);
      expect(find.text('preview'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('preview'), findsNothing);
      expect(_location(tester), '/home');
    });

    testWidgets('Escape pops a pushed page and is a no-op at the root', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));

      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('detail'), findsNothing);
      expect(nav.location, '/home');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(nav.location, '/home');
    });
  });

  group('shell integration', () {
    testWidgets('tab-level placeholder overrides the shell placeholder', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        width: 1000,
        shellPlaceholder: const Text('shell placeholder'),
        tabPlaceholder: const Text('tab placeholder'),
      );
      expect(find.text('tab placeholder'), findsOneWidget);
      expect(find.text('shell placeholder'), findsNothing);

      // With a detail open the placeholder is replaced by the detail pane.
      // 打开 detail 后占位内容被 detail pane 替换。
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(find.text('tab placeholder'), findsNothing);
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('the shell placeholder is used when the tab has none', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        width: 1000,
        shellPlaceholder: const Text('shell placeholder'),
      );
      expect(find.text('shell placeholder'), findsOneWidget);
    });

    testWidgets('the default placeholder shows when none is configured', (
      tester,
    ) async {
      await _pumpApp(tester, width: 1000);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('hidesBottomBarWhenPushed false keeps the compact chrome', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400, useChrome: true, hideBar: false);
      expect(find.byType(NavigationBar), findsOneWidget);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('hidesBottomBarWhenPushed true (default) hides it', (
      tester,
    ) async {
      await _pumpApp(tester, width: 400, useChrome: true);
      expect(find.byType(NavigationBar), findsOneWidget);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('breadcrumb tap pops back to that level', (tester) async {
      await _pumpApp(tester, width: 1000);
      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      nav.open('/home/detail');
      await tester.pumpAndSettle();
      expect(find.text('/home/detail'), findsOneWidget);

      await tester.tap(find.text('/home'));
      await tester.pumpAndSettle();
      expect(nav.location, '/home');
      expect(find.text('/home/detail'), findsNothing);
    });

    testWidgets('arguments reach the route state', (tester) async {
      await _pumpApp(tester, width: 400);
      // The home page pushes with arguments; the detail page prints them.
      // 首页带 arguments push；detail 页将其显示出来。
      await tester.tap(find.text('push-args'));
      await tester.pumpAndSettle();
      expect(find.text('args:payload-7'), findsOneWidget);
    });

    testWidgets('a redirect loop renders the error builder', (tester) async {
      await _pumpApp(
        tester,
        width: 400,
        initialLocation: '/a',
        redirect: (location) => location == '/a' ? '/b' : '/a',
      );
      // `setInitialRoutePath` forces the resolution, so the limit is exceeded
      // and the error builder takes over (the location is preserved).
      // `setInitialRoutePath` 会强制执行解析，跳数超限后 errorBuilder 接管
      // （location 保持原值）。
      expect(find.text('error:/a'), findsOneWidget);
    });
  });
}

Future<ZeroRouter> _pumpApp(
  WidgetTester tester, {
  required double width,
  String initialLocation = '/home',
  ZeroRouterRedirect? redirect,
  bool barrierDismissible = false,
  bool useChrome = false,
  bool hideBar = true,
  Widget? shellPlaceholder,
  Widget? tabPlaceholder,
  ValueChanged<PageRoute<dynamic>>? onDialogBuilt,
}) async {
  final router = ZeroRouter(
    initialLocation: initialLocation,
    redirect: redirect,
    errorBuilder: (context, location) => Text('error:$location'),
    placeholder: shellPlaceholder,
    routes: [
      ZeroShell(
        builder: (context, shell, child) {
          if (shell.isCompact) {
            if (!useChrome) {
              return Scaffold(body: child);
            }
            return ZeroShellChrome(
              bottomNavigationBar: (context) => NavigationBar(
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.list), label: 'Home'),
                  NavigationDestination(
                    icon: Icon(Icons.settings),
                    label: 'Other',
                  ),
                ],
                selectedIndex: 0,
              ),
              child: Scaffold(body: child),
            );
          }
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.list),
                      label: Text('Home'),
                    ),
                  ],
                  selectedIndex: 0,
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
        tabs: [
          ZeroTab(
            initialLocation: '/home',
            placeholder: tabPlaceholder,
            routes: [
              ZeroRoute(
                path: '/home',
                builder: (context, state) => Scaffold(
                  body: ListView(
                    children: [
                      ZeroLink(
                        location: '/home/detail',
                        child: const ListTile(title: Text('open-detail')),
                      ),
                      ZeroLink(
                        location: '/home/preview',
                        child: const ListTile(title: Text('open-preview')),
                      ),
                      Builder(
                        builder: (context) => ListTile(
                          title: const Text('push-args'),
                          onTap: () => ZeroNav.of(
                            context,
                          ).pushNamed('/home/detail', arguments: 'payload-7'),
                        ),
                      ),
                    ],
                  ),
                ),
                routes: [
                  ZeroRoute(
                    path: 'detail',
                    hidesBottomBarWhenPushed: hideBar,
                    builder: (context, state) => Center(
                      child: Text(
                        state.arguments == null
                            ? 'detail'
                            : 'args:${state.arguments}',
                      ),
                    ),
                  ),
                  ZeroRoute(
                    path: 'preview',
                    fullscreen: true,
                    opaque: false,
                    barrierColor: const Color(0x66000000),
                    barrierDismissible: barrierDismissible,
                    builder: (context, state) =>
                        const Center(child: Card(child: Text('preview'))),
                  ),
                  ZeroRoute(
                    path: 'dialog',
                    fullscreenDialog: true,
                    builder: (context, state) {
                      final route =
                          ModalRoute.of(context) as PageRoute<dynamic>;
                      onDialogBuilt?.call(route);
                      return const Center(child: Text('dialog'));
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> _openPreview(WidgetTester tester) async {
  final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
  nav.open('/home/preview');
  await tester.pumpAndSettle();
}

String _location(WidgetTester tester) =>
    ZeroNav.of(tester.element(find.byType(Navigator).first)).location;
