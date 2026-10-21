// Widget-level coverage for nested shells: a top-level route that hosts a
// `ZeroShell` via `ZeroRoute.shell` renders the nested shell inside it, switches
// its own tabs, deep-links, and pops within its own stack.
// 嵌套 shell 的 widget 级覆盖：顶层路由通过 `ZeroRoute.shell` 承载 `ZeroShell`，
// 并在其内部渲染嵌套 shell、切换自身 tab、深链、以及在本栈内 pop。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

/// A nested shell with two tabs, "Profile" and "Account".
/// 含两个 tab「Profile」「Account」的嵌套 shell。
ZeroShell _nestedShell() => ZeroShell(
  builder: (context, shell, child) => Scaffold(
    body: Row(
      children: [
        NavigationRail(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goTab,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profile'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.account_box),
              label: Text('Account'),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    ),
  ),
  tabs: [
    ZeroTab(
      routes: [
        ZeroRoute(
          path: '/profile',
          builder: (context, state) =>
              const Center(child: Text('Profile content')),
        ),
      ],
    ),
    ZeroTab(
      routes: [
        ZeroRoute(
          path: '/account',
          builder: (context, state) =>
              const Center(child: Text('Account content')),
        ),
      ],
    ),
  ],
);

/// The same nested shell, but with each tab declaring an absolute
/// `initialLocation` (the shape the example app uses).
/// 同一个嵌套 shell，但每个 tab 都声明绝对 `initialLocation`（示例 app 的用法）。
ZeroShell _nestedShellWithInitialLocations() => ZeroShell(
  builder: (context, shell, child) => Scaffold(
    body: Row(
      children: [
        NavigationRail(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goTab,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profile'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.account_box),
              label: Text('Account'),
            ),
          ],
        ),
        Expanded(child: child),
      ],
    ),
  ),
  tabs: [
    ZeroTab(
      initialLocation: '/settings/profile',
      routes: [
        ZeroRoute(
          path: '/profile',
          builder: (context, state) =>
              const Center(child: Text('Profile content')),
        ),
      ],
    ),
    ZeroTab(
      initialLocation: '/settings/account',
      routes: [
        ZeroRoute(
          path: '/account',
          builder: (context, state) =>
              const Center(child: Text('Account content')),
        ),
      ],
    ),
  ],
);

Future<ZeroRouter> _pumpNested(
  WidgetTester tester, {
  required double width,
  String initialLocation = '/settings',
}) async {
  final router = ZeroRouter(
    initialLocation: initialLocation,
    routes: [
      ZeroShell(
        builder: (context, shell, child) => Scaffold(body: child),
        tabs: [
          ZeroTab(
            routes: [
              ZeroRoute(
                path: '/settings',
                shell: _nestedShell(),
                shellBuilder: (context, state, child) => Scaffold(body: child),
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

String _location(WidgetTester tester) =>
    ZeroNav.of(tester.element(find.byType(Navigator).first)).location;

void main() {
  group('nested shell', () {
    testWidgets('renders the nested shell with its default tab', (
      tester,
    ) async {
      await _pumpNested(tester, width: 400);
      // The nested shell chrome and its default (Profile) content are present.
      // 嵌套 shell 的 chrome 与其默认（Profile）内容都出现。
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Profile content'), findsOneWidget);
      expect(_location(tester), '/settings/profile');
    });

    testWidgets('goTab switches the nested shell tab', (tester) async {
      await _pumpNested(tester, width: 400);
      expect(find.text('Profile content'), findsOneWidget);

      // Tap the nested shell's "Account" destination.
      // 点击嵌套 shell 的「Account」目标。
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();

      expect(find.text('Account content'), findsOneWidget);
      expect(find.text('Profile content'), findsNothing);
      expect(_location(tester), '/settings/account');
    });

    testWidgets('deep link lands on the requested nested tab', (tester) async {
      await _pumpNested(
        tester,
        width: 400,
        initialLocation: '/settings/account',
      );
      expect(find.text('Account content'), findsOneWidget);
      expect(_location(tester), '/settings/account');
    });

    testWidgets('popping a nested tab returns to the nested default', (
      tester,
    ) async {
      await _pumpNested(
        tester,
        width: 400,
        initialLocation: '/settings/account',
      );
      expect(_location(tester), '/settings/account');

      final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
      // `pop` of the nested Account entry drops back to the Profile tab.
      // 嵌套 Account 条目的 `pop` 回落到 Profile tab。
      nav.pop();
      await tester.pumpAndSettle();

      expect(_location(tester), '/settings/profile');
      expect(find.text('Profile content'), findsOneWidget);
      expect(find.text('Account content'), findsNothing);
    });

    testWidgets('nested tabs may declare an absolute initialLocation', (
      tester,
    ) async {
      // Regression guard: a nested tab's `initialLocation` is a *full* location
      // (`/settings/profile`) while its routes are authored relative to the host
      // (`/profile`). Descending into the default tab used to leak the host's own
      // segments into the child pattern, so the tab failed to match and the
      // shell's stack stayed empty (the example then navigated to '/').
      // 回归防护：嵌套 tab 的 `initialLocation` 是*完整* location
      // （`/settings/profile`），而其路由是相对宿主书写的（`/profile`）。下钻默认
      // tab 时曾把宿主自身的段混进子级 pattern，导致该 tab 匹配失败、shell 的栈
      // 为空（示例中表现为导航到 '/'）。
      final router = ZeroRouter(
        initialLocation: '/settings',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => Scaffold(body: child),
            tabs: [
              ZeroTab(
                routes: [
                  ZeroRoute(
                    path: '/settings',
                    shell: _nestedShellWithInitialLocations(),
                    shellBuilder: (context, state, child) =>
                        Scaffold(body: child),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1100, 900)),
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile content'), findsOneWidget);
      expect(_location(tester), '/settings/profile');

      // Switching nested tabs still resolves through the registered location.
      // 切换嵌套 tab 仍能通过注册的 location 解析。
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Account content'), findsOneWidget);
      expect(_location(tester), '/settings/account');
    });

    testWidgets('renders the nested shell on expanded widths', (tester) async {
      await _pumpNested(tester, width: 1100);
      // Expanded shows the nested shell chrome and the default content.
      // expanded 下展示嵌套 shell 的 chrome 与默认内容。
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Profile content'), findsOneWidget);
      expect(_location(tester), '/settings/profile');

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Account content'), findsOneWidget);
      expect(_location(tester), '/settings/account');
    });
  });
}
