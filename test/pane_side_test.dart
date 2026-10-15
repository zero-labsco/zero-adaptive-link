import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  testWidgets('paneSideListenable flips the expanded pane layout', (
    tester,
  ) async {
    final side = ValueNotifier<SlidingPanesSide>(SlidingPanesSide.right);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1440, 900)),
        child: MaterialApp.router(
          routerConfig: ZeroRouter(
            initialLocation: '/a',
            paneSideListenable: side,
            routes: [
              ZeroShell(
                builder: (context, shell, child) => child,
                tabs: [
                  ZeroTab(
                    initialLocation: '/a',
                    routes: [
                      ZeroRoute(
                        path: '/a',
                        builder: (context, state) => const Text('A'),
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

    final sliding = find.byType(SlidingPanes);
    expect(sliding, findsOneWidget);
    expect(tester.widget<SlidingPanes>(sliding).side, SlidingPanesSide.right,
        reason: 'starts on the right');

    side.value = SlidingPanesSide.left;
    await tester.pumpAndSettle();

    expect(tester.widget<SlidingPanes>(sliding).side, SlidingPanesSide.left,
        reason: 'listener should flip the layout to the left');
  });
}
