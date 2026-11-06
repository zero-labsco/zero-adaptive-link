// Regressions for the 0.6.0 audit findings.
// 0.6.0 审查问题的回归测试。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('matcher, state and URL', () {
    test('raw query and a literal + round-trip unchanged', () {
      final matches = ZeroRouteMatcher.match(<ZeroRoute>[
        ZeroRoute(
          path: '/products',
          routes: <ZeroRoute>[ZeroRoute(path: ':id')],
        ),
      ], '/products/a+b?flag&a=1&a=2&x=a%20b');
      expect(matches, isNotNull);
      expect(matches!.length, 2);
      // Ancestors stay query-free, so a query change keeps its common prefix.
      expect(matches.first!.location, '/products');
      expect(matches.last!.location, '/products/a+b?flag&a=1&a=2&x=a%20b');
      expect(matches.last!.state.queryParameters['x'], 'a b');
    });

    test('copyWith preserves the handoff pageKey', () {
      final state = ZeroRouteState(fullPath: '/a', location: '/a');
      final copy = state.copyWith(data: 42, location: '/a?q=1');
      expect(copy.pageKey, same(state.pageKey));
      expect(copy.data, 42);
      expect(copy.location, '/a?q=1');
    });

    test('canonicalHref escapes fragment hazards', () {
      expect(ZeroRouter.canonicalHref('/products/42'), '#/products/42');
      expect(
        ZeroRouter.canonicalHref('/products/42?tab=1'),
        '#/products/42?tab=1',
      );
      expect(ZeroRouter.canonicalHref('/a b'), '#/a%20b');
    });
  });

  group('navigation regressions', () {
    testWidgets('a query-only navigation keeps the stack depth', (
      tester,
    ) async {
      await _pump(tester, _router(), 400);
      final nav = ZeroNav.of(_ctx(tester));

      nav.open('/home/detail?tab=specs');
      await tester.pumpAndSettle();
      expect(nav.location, '/home/detail?tab=specs');
      expect(_maxPageCount(tester), 2);

      nav.open('/home/detail?tab=reviews');
      await tester.pumpAndSettle();
      expect(nav.location, '/home/detail?tab=reviews');
      expect(_maxPageCount(tester), 2);

      nav.pop();
      await tester.pumpAndSettle();
      expect(nav.location, '/home');
    });

    testWidgets('openFullscreen puts the leaf on the root navigator', (
      tester,
    ) async {
      await _pump(tester, _router(), 400);
      final nav = ZeroNav.of(_ctx(tester));

      final future = nav.openFullscreen('/home/detail');
      await tester.pumpAndSettle();
      expect(nav.location, '/home/detail');
      expect(
        tester.widgetList<Navigator>(find.byType(Navigator)).first.pages.length,
        2,
      );

      nav.pop();
      await tester.pumpAndSettle();
      expect(await future, isNull);
      expect(nav.location, '/home');
    });

    testWidgets('namedLocation replaces whole parameter tokens', (
      tester,
    ) async {
      await _pump(tester, _namedRouter(), 400);
      final nav = ZeroNav.of(_ctx(tester));

      expect(
        nav.namedLocation(
          'user',
          pathParameters: <String, String>{'identity': 'a b'},
        ),
        '/users/a%20b',
      );
      expect(nav.namedLocation('user'), isNull);
      expect(nav.namedLocation('unknown'), isNull);
    });

    testWidgets('nested shell route names are registered', (tester) async {
      await _pump(tester, _nestedNamedRouter(), 400);
      final nav = ZeroNav.of(_ctx(tester));
      expect(nav.namedLocation('profile'), '/settings/profile');
    });

    testWidgets('onTap override also wins for keyboard activation', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, _linkRouter(() => taps++), 400);

      // `Focus.of` resolves the detector's own node through the inherited
      // scope, so the key event bubbles through its `Shortcuts` / `Actions`.
      // `Focus.of` 通过 inherited scope 取到 detector 自身的节点，按键事件因此
      // 会冒泡经过它的 `Shortcuts` / `Actions`。
      final linkElement = tester.element(find.text('link'));
      Focus.of(linkElement).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}

int _maxPageCount(WidgetTester tester) {
  var max = 0;
  for (final navigator in tester.widgetList<Navigator>(
    find.byType(Navigator),
  )) {
    if (navigator.pages.length > max) {
      max = navigator.pages.length;
    }
  }
  return max;
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);

Future<void> _pump(WidgetTester tester, ZeroRouter router, double width) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

ZeroRouter _router() => ZeroRouter(
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
              builder: (context, state) =>
                  const Center(child: Text('home-page')),
              routes: [
                ZeroRoute(
                  path: 'detail',
                  builder: (context, state) =>
                      const Center(child: Text('detail-page')),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

ZeroRouter _namedRouter() => ZeroRouter(
  initialLocation: '/users/1',
  routes: [
    ZeroShell(
      builder: (context, shell, child) => Scaffold(body: child),
      tabs: [
        ZeroTab(
          routes: [
            ZeroRoute(
              path: '/users/:identity',
              name: 'user',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    ),
  ],
);

ZeroRouter _nestedNamedRouter() => ZeroRouter(
  initialLocation: '/settings/profile',
  routes: [
    ZeroShell(
      builder: (context, shell, child) => Scaffold(body: child),
      tabs: [
        ZeroTab(
          routes: [
            ZeroRoute(
              path: '/settings',
              builder: (context, state) => const SizedBox.shrink(),
              shell: ZeroShell(
                builder: (context, shell, child) => Scaffold(body: child),
                tabs: [
                  ZeroTab(
                    routes: [
                      ZeroRoute(
                        path: 'profile',
                        name: 'profile',
                        builder: (context, state) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

ZeroRouter _linkRouter(VoidCallback onTap) => ZeroRouter(
  initialLocation: '/home',
  routes: [
    ZeroShell(
      builder: (context, shell, child) => Scaffold(body: child),
      tabs: [
        ZeroTab(
          routes: [
            ZeroRoute(
              path: '/home',
              builder: (context, state) => ZeroLink(
                location: '/home',
                onTap: onTap,
                child: const Text('link'),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
