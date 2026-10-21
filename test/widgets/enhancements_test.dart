// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('0.4.0 enhancements', () {
    testWidgets('onNavigation fires after a navigation', (tester) async {
      final seen = <String>[];
      await _pump(tester, 400, onNavigation: seen.add);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(seen, contains('/products/42'));
    });

    testWidgets('showDetail / hideDetail / isDetailOpen (expanded)', (
      tester,
    ) async {
      await _pump(tester, 1000);
      final nav = ZeroNav.of(_ctx(tester));
      expect(nav.isDetailOpen, isFalse);

      // `showDetail` returns a future completed by `pop`, so fire it and settle
      // instead of awaiting it (the same pattern as the existing harness).
      // `showDetail` 返回由 pop 完成的 Future，因此触发后 pumpAndSettle 而非
      // await（与现有测试一致）。
      nav.showDetail('/products/42');
      await tester.pumpAndSettle();
      expect(nav.isDetailOpen, isTrue);
      expect(nav.location, '/products/42');

      nav.hideDetail();
      await tester.pumpAndSettle();
      expect(nav.isDetailOpen, isFalse);
      expect(nav.location, '/products');
    });

    testWidgets('ZeroLink mode=replacement replaces the root entry', (
      tester,
    ) async {
      await _pump(tester, 400);
      await tester.tap(find.text('Go replacement'));
      await tester.pumpAndSettle();
      final nav = ZeroNav.of(_ctx(tester));
      expect(nav.location, '/about');
      // A top-level route replaces the root, so the stack stays at one entry.
      // 顶层路由替换了根，因此栈仍只有一项。
      expect(nav.canPop, isFalse);
    });

    testWidgets('preferredTab opens a location in the chosen tab', (
      tester,
    ) async {
      await _pump(tester, 400);
      final nav = ZeroNav.of(_ctx(tester));
      // Fire (don't await) — the future completes only on pop.
      // 触发即可（勿 await），该 Future 仅在 pop 时完成。
      nav.open('/cart', preferredTab: 1);
      await tester.pumpAndSettle();
      expect(nav.location, '/cart');
      expect(find.text('Cart root'), findsOneWidget);
    });

    testWidgets('breadcrumbs render on the branch at compact too', (
      tester,
    ) async {
      await _pump(tester, 400, showBreadcrumbsOnBranch: true);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      // Both the master and the matched segment show.
      // master 与命中段均显示。
      expect(find.text('/products'), findsWidgets);
      expect(find.text('/products/42'), findsWidgets);
    });

    testWidgets(
      'ZeroNavigationChrome shows a rail on expanded, a bar on compact',
      (tester) async {
        await _pump(tester, 1000, useChrome: true);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        await _pump(tester, 400, useChrome: true);
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      },
    );

    testWidgets('ZeroLink exposes a semantics label', (tester) async {
      await _pump(tester, 400);
      final node = tester.getSemantics(find.text('Product 42'));
      expect(node.label, contains('Open product 42'));
    });

    testWidgets('ZeroRoute.loader resolves data before the page builds', (
      tester,
    ) async {
      await _pumpLoader(tester, 400);
      // The loader resolves on the next frame; the spinner is replaced by the
      // resolved value. / loader 在下一帧解析；spinner 被解析结果替换。
      await tester.pumpAndSettle();
      expect(find.text('loaded:42'), findsOneWidget);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  double width, {
  void Function(String)? onNavigation,
  bool showBreadcrumbsOnBranch = false,
  bool useChrome = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(
        routerConfig: _buildRouter(
          onNavigation: onNavigation,
          showBreadcrumbsOnBranch: showBreadcrumbsOnBranch,
          useChrome: useChrome,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);

ZeroRouter _buildRouter({
  void Function(String)? onNavigation,
  bool showBreadcrumbsOnBranch = false,
  bool useChrome = false,
}) {
  return ZeroRouter(
    initialLocation: '/products',
    showBreadcrumbsOnBranch: showBreadcrumbsOnBranch,
    onNavigation: onNavigation,
    errorBuilder: (context, location) => Text('error:$location'),
    routes: [
      ZeroShell(
        builder: (context, shell, child) {
          if (useChrome) {
            return ZeroNavigationChrome(
              destinations: const [
                ZeroNavigationDestination(
                  icon: Icon(Icons.list),
                  label: 'Products',
                ),
                ZeroNavigationDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Cart',
                ),
              ],
              child: child,
            );
          }
          return shell.isExpanded
              ? Row(
                  children: [
                    NavigationRail(
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.list),
                          label: Text('Products'),
                        ),
                      ],
                      selectedIndex: shell.currentIndex,
                    ),
                    Expanded(child: child),
                  ],
                )
              : Scaffold(body: child);
        },
        tabs: [
          ZeroTab(
            routes: [
              ZeroRoute(
                path: '/products',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Products')),
                  body: ListView(
                    children: [
                      ZeroLink(
                        location: '/products/41',
                        semanticLabel: 'Open product 41',
                        child: const ListTile(title: Text('Product 41')),
                      ),
                      ZeroLink(
                        location: '/products/42',
                        semanticLabel: 'Open product 42',
                        child: const ListTile(title: Text('Product 42')),
                      ),
                      ZeroLink(
                        location: '/about',
                        mode: ZeroLinkMode.replacement,
                        semanticLabel: 'Go replacement',
                        child: const ListTile(title: Text('Go replacement')),
                      ),
                    ],
                  ),
                ),
                routes: [
                  ZeroRoute(
                    path: ':id',
                    builder: (context, state) => Scaffold(
                      appBar: AppBar(
                        title: Text('Detail ${state.pathParameters['id']}'),
                      ),
                      body: Center(
                        child: Text('Detail ${state.pathParameters['id']}'),
                      ),
                    ),
                  ),
                ],
              ),
              ZeroRoute(
                path: '/about',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('About'))),
              ),
            ],
          ),
          ZeroTab(
            routes: [
              ZeroRoute(
                path: '/cart',
                builder: (context, state) => Scaffold(
                  appBar: AppBar(title: const Text('Cart')),
                  body: const Center(child: Text('Cart root')),
                ),
                routes: [
                  ZeroRoute(
                    path: 'item',
                    builder: (context, state) =>
                        const Center(child: Text('Cart item')),
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

Future<void> _pumpLoader(WidgetTester tester, double width) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(
        routerConfig: ZeroRouter(
          initialLocation: '/loader/42',
          errorBuilder: (context, location) => Text('error:$location'),
          routes: [
            ZeroShell(
              builder: (context, shell, child) => Scaffold(body: child),
              tabs: [
                ZeroTab(
                  routes: [
                    ZeroRoute(
                      path: '/loader/:id',
                      loader: (state) async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 50),
                        );
                        return 'loaded:${state.pathParameters['id']}';
                      },
                      builder: (context, state) =>
                          Center(child: Text('${state.data}')),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
