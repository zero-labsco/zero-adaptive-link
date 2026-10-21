// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  testWidgets('ZeroAnchor navigates like ZeroLink (native fallback)', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Open products'));
    await tester.pumpAndSettle();
    expect(ZeroNav.of(_ctx(tester)).location, '/products');
  });

  test('ZeroRouter.canonicalHref prepends the hash', () {
    expect(ZeroRouter.canonicalHref('/products/42'), '#/products/42');
  });
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(400, 900)),
      child: MaterialApp.router(
        routerConfig: ZeroRouter(
          initialLocation: '/',
          routes: [
            ZeroShell(
              builder: (context, shell, child) => Scaffold(body: child),
              tabs: [
                ZeroTab(
                  routes: [
                    ZeroRoute(
                      path: '/',
                      builder: (context, state) => ListView(
                        children: [
                          ZeroAnchor(
                            location: '/products',
                            label: 'Open products',
                          ),
                          ZeroLink(
                            location: '/products',
                            child: const ListTile(title: Text('Also open')),
                          ),
                        ],
                      ),
                    ),
                    ZeroRoute(
                      path: '/products',
                      builder: (context, state) =>
                          const Center(child: Text('Products page')),
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

BuildContext _ctx(WidgetTester tester) =>
    tester.element(find.byType(Navigator).first);
