// `open` / `pushNamed` return futures completed by `pop(result)`; the widget
// tests fire them and settle frames instead of awaiting.
// `open` / `pushNamed` 返回由 `pop(result)` 完成的 Future；widget 测试采用
// 触发后 pumpAndSettle 的方式。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('adaptive behavior', () {
    testWidgets('compact width pushes a new page on tap', (tester) async {
      await _pumpAt(tester, 400);
      expect(find.widgetWithText(AppBar, 'Products'), findsOneWidget);

      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsOneWidget);
      expect(ZeroNav.of(_context(tester)).location, '/products/42');
    });

    testWidgets('medium width pushes a new page on tap', (tester) async {
      await _pumpAt(tester, 720);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsOneWidget);
      expect(ZeroNav.of(_context(tester)).location, '/products/42');
    });

    testWidgets('expanded width expands a right pane on tap', (tester) async {
      await _pumpAt(tester, 1000);
      expect(find.widgetWithText(AppBar, 'Products'), findsOneWidget);
      expect(find.widgetWithText(Center, 'Detail 42'), findsNothing);

      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsOneWidget);
      expect(find.text('Product 41'), findsOneWidget);
      expect(ZeroNav.of(_context(tester)).location, '/products/42');
    });

    testWidgets('repeated tap of the same location does not add panes', (
      tester,
    ) async {
      await _pumpAt(tester, 1000);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsOneWidget);
      expect(ZeroNav.of(_context(tester)).location, '/products/42');
    });

    testWidgets('expanded pane pops on back', (tester) async {
      await _pumpAt(tester, 1000);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsOneWidget);

      final nav = ZeroNav.of(_context(tester));
      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(Center, 'Detail 42'), findsNothing);
      expect(nav.location, '/products');
    });

    testWidgets('maybePop at the tab root is a no-op', (tester) async {
      await _pumpAt(tester, 400);
      final nav = ZeroNav.of(_context(tester));
      expect(await nav.maybePop(), isFalse);
      expect(nav.location, '/products');
    });

    testWidgets('browser back semantics: pop collapses the pane stack', (
      tester,
    ) async {
      await _pumpAt(tester, 1000);
      final nav = ZeroNav.of(_context(tester));
      nav.open('/products/41');
      await tester.pumpAndSettle();
      nav.open('/products/42');
      await tester.pumpAndSettle();
      expect(nav.location, '/products/42');
      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(nav.location, '/products/41');
      expect(await nav.maybePop(), isTrue);
      await tester.pumpAndSettle();
      expect(nav.location, '/products');
    });

    testWidgets('deep link resolves through the parser', (tester) async {
      await _pumpAt(tester, 400, initialLocation: '/products/42?tab=specs');
      final detail = find.widgetWithText(Center, 'Detail 42');
      expect(detail, findsOneWidget);
      final state = ZeroRouteState.of(tester.element(detail));
      expect(state.pathParameters['id'], '42');
      expect(state.queryParameters['tab'], 'specs');
      expect(state.location, '/products/42?tab=specs');
    });

    testWidgets('ZeroLink honors a custom onTap override', (tester) async {
      var tapped = false;
      await _pumpAt(tester, 400, onTapOverride: () => tapped = true);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(ZeroNav.of(_context(tester)).location, '/products');
    });

    testWidgets('ZeroNav is readable from inside a page', (tester) async {
      await _pumpAt(tester, 1000);
      // The master pane stays visible and rebuilds via the location
      // listenable (ValueListenableBuilder).
      // master pane 保持可见，并通过 location listenable
      // （ValueListenableBuilder）重建。
      expect(find.text('nav:/products'), findsOneWidget);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.text('nav:/products/42'), findsOneWidget);
    });

    testWidgets('unmatched location renders the error builder', (tester) async {
      await _pumpAt(tester, 400, initialLocation: '/nope');
      expect(find.text('error:/nope'), findsOneWidget);
    });

    testWidgets('PopScope on the shell blocks the exit back', (tester) async {
      await _pumpAt(tester, 400, blockExit: true);
      final nav = ZeroNav.of(_context(tester));
      expect(await nav.maybePop(), isFalse);
      expect(nav.location, '/products');
    });

    testWidgets('compact chrome shows on the tab root only', (tester) async {
      await _pumpAt(tester, 400, useChrome: true);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      // hidesBottomBarWhenPushed defaults to true.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('breadcrumbs render above the panes in expanded mode', (
      tester,
    ) async {
      await _pumpAt(tester, 1000);
      await tester.tap(find.text('Product 42'));
      await tester.pumpAndSettle();
      expect(find.text('/products'), findsOneWidget);
      expect(find.text('/products/42'), findsOneWidget);
    });
  });
}

Future<void> _pumpAt(
  WidgetTester tester,
  double width, {
  String initialLocation = '/products',
  VoidCallback? onTapOverride,
  bool blockExit = false,
  bool useChrome = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(
        routerConfig: _buildRouter(
          initialLocation: initialLocation,
          onTapOverride: onTapOverride,
          blockExit: blockExit,
          useChrome: useChrome,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BuildContext _context(WidgetTester tester) {
  // The first Navigator is the root navigator built inside ZeroNavScope.
  // 第一个 Navigator 即 ZeroNavScope 内构建的根 navigator。
  return tester.element(find.byType(Navigator).first);
}

ZeroRouter _buildRouter({
  String initialLocation = '/products',
  VoidCallback? onTapOverride,
  bool blockExit = false,
  bool useChrome = false,
}) {
  return ZeroRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, location) => Text('error:$location'),
    routes: [
      ZeroShell(
        builder: (context, shell, child) {
          final content = shell.isExpanded
              ? Row(
                  children: [
                    NavigationRail(
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.list),
                          label: Text('Products'),
                        ),
                      ],
                      selectedIndex: 0,
                    ),
                    Expanded(child: child),
                  ],
                )
              : useChrome
              ? ZeroShellChrome(
                  bottomNavigationBar: (context) => NavigationBar(
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.list),
                        label: 'Products',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.shopping_cart),
                        label: 'Cart',
                      ),
                    ],
                    selectedIndex: 0,
                  ),
                  child: Scaffold(body: child),
                )
              : Scaffold(body: child);
          if (!blockExit) {
            return content;
          }
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {},
            child: content,
          );
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
                        child: const ListTile(title: Text('Product 41')),
                      ),
                      ZeroLink(
                        location: '/products/42',
                        onTap: onTapOverride,
                        child: const ListTile(title: Text('Product 42')),
                      ),
                      ListTile(
                        title: ValueListenableBuilder<String>(
                          valueListenable: ZeroNav.of(
                            context,
                          ).locationListenable,
                          builder: (context, location, child) =>
                              Text('nav:$location'),
                        ),
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
            ],
          ),
        ],
      ),
    ],
  );
}
