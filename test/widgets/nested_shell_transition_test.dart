// Reproduces the example app flow that crashed with
// `_InactiveElements.remove`'s `_elements.contains(element)` assertion:
// switching between an ordinary tab and a nested-shell-hosting tab at expanded
// width, so SlidingPanes transitions move subtrees carrying GlobalKeys.
// 复现示例 app 的崩溃流程：expanded 宽度下在普通 tab 与嵌套 shell tab 间切换，
// SlidingPanes 转场会搬运携带 GlobalKey 的子树。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

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

Future<ZeroRouter> _pumpApp(WidgetTester tester) async {
  final router = ZeroRouter(
    initialLocation: '/inbox',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goTab,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.inbox),
                    label: Text('Inbox'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
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
                path: '/inbox',
                builder: (context, state) => Center(
                  child: ZeroLink(
                    location: '/inbox/1',
                    child: const Text('Open ticket'),
                  ),
                ),
                routes: [
                  ZeroRoute(
                    path: ':id',
                    builder: (context, state) => Center(
                      child: Text('Ticket ${state.pathParameters['id']}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      data: MediaQueryData(size: const Size(1051, 700)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  group('nested shell transitions at expanded width', () {
    testWidgets('switching from a 1-pane tab to the nested tab', (
      tester,
    ) async {
      await _pumpApp(tester);
      expect(find.text('Open ticket'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Profile content'), findsOneWidget);
      expect(find.text('Open ticket'), findsNothing);
    });

    testWidgets('switching from a 2-pane tab to the nested tab', (
      tester,
    ) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Open ticket'));
      await tester.pumpAndSettle();
      expect(find.text('Ticket 1'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Profile content'), findsOneWidget);
      expect(find.text('Ticket 1'), findsNothing);
    });

    testWidgets('round trip: nested tab back to the ordinary tab', (
      tester,
    ) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Profile content'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Account content'), findsOneWidget);

      await tester.tap(find.text('Inbox'));
      await tester.pumpAndSettle();
      expect(find.text('Open ticket'), findsOneWidget);
      expect(find.text('Account content'), findsNothing);
    });
  });
}
