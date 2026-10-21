// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('scroll & focus restoration', () {
    testWidgets('scroll offset restores when returning to a tab', (
      tester,
    ) async {
      final controller = ScrollController();
      await _pump(tester, controller);

      // Scroll the list down. / 向下滚动列表。
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final afterScroll = controller.offset;
      expect(afterScroll, greaterThan(0));

      // Leave the tab and come back — the page subtree is unmounted and
      // remounted, so the offset must come back from PageStorage.
      // 离开该 tab 再返回——页面子树被卸载后重新挂载，偏移须从 PageStorage 取回。
      final nav = ZeroNav.of(_ctx(tester));
      nav.goTab(1);
      await tester.pumpAndSettle();
      nav.goTab(0);
      await tester.pumpAndSettle();

      expect(controller.offset, afterScroll);
    });

    testWidgets('ZeroRouteState.restorationId equals the location', (
      tester,
    ) async {
      await _pump(tester, ScrollController());
      final state = ZeroRouteState.of(
        tester.element(find.text('Item 0').first),
      );
      expect(state.restorationId, state.location);
    });
  });
}

Future<void> _pump(WidgetTester tester, ScrollController controller) async {
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
                        // Opt in to scroll restoration via the route's id.
                        // 用 route 的 id 参与滚动恢复。
                        key: PageStorageKey<String>(state.restorationId),
                        controller: controller,
                        children: [
                          for (var i = 0; i < 50; i++)
                            ListTile(title: Text('Item $i')),
                          ZeroLink(
                            location: '/detail',
                            child: const ListTile(title: Text('Go detail')),
                          ),
                        ],
                      ),
                    ),
                    ZeroRoute(
                      path: '/detail',
                      builder: (context, state) =>
                          const Center(child: Text('Detail')),
                    ),
                  ],
                ),
                ZeroTab(
                  routes: [
                    ZeroRoute(
                      path: '/',
                      builder: (context, state) =>
                          const Center(child: Text('Tab two')),
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
