// Pane transition coverage: the first expand slides in, a deeper push shifts
// the viewport left by one column, a pop shifts it back, a collapse keeps the
// exiting detail mounted, and page state survives a breakpoint crossing via
// the stable `pageKey` handoff.
// pane 转场覆盖：首次展开滑入、更深层级 push 使视口左移一列、pop 反向移回、
// 收起期间退出中的 detail 保持挂载，以及页面状态借助稳定的 `pageKey` 交接
// 在跨越断点后保留。
// ignore_for_file: unawaited_futures

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  testWidgets('the first pane expansion slides the detail in', (tester) async {
    await _pumpAt(tester, 1000);
    // The placeholder is showing; no detail yet. / 展示的是占位内容，尚无详情。
    expect(find.text('detail-body-42'), findsNothing);

    await tester.tap(find.text('Product 42'));
    // Mid-animation (slideDuration defaults to 280ms): the detail is still
    // (partly) beyond its resting position (~402px on a 1000px window).
    // 动画进行中（slideDuration 默认 280ms）：detail 尚未到位（1000px 窗口
    // 下静止位置约 402px）。
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      tester.getTopLeft(find.text('detail-body-42')).dx,
      greaterThan(500),
      reason: 'the detail pane should be mid-slide, not already in place',
    );

    await tester.pumpAndSettle();
    expect(find.text('detail-body-42'), findsOneWidget);
  });

  testWidgets('a deeper push keeps the replaced master mounted mid-shift', (
    tester,
  ) async {
    await _pumpAt(tester, 1000);
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    nav.open('/products/41');
    await tester.pumpAndSettle();
    nav.open('/products/42');
    await tester.pumpAndSettle();

    // Push a third level: [41, 42] -> [42, 43]. The replaced master (41)
    // stays mounted while the viewport slides left by one column.
    // 推入第三级：[41, 42] -> [42, 43]。被替换的 master（41）在视口左移
    // 一列期间保持挂载。
    nav.open('/products/43');
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.text('detail-body-41'),
      findsOneWidget,
      reason: 'the exiting master should still be mounted mid-shift',
    );
    expect(
      find.text('detail-body-43'),
      findsOneWidget,
      reason: 'the new detail should be sliding in',
    );

    await tester.pumpAndSettle();
    expect(find.text('detail-body-41'), findsNothing);
    expect(find.text('detail-body-42'), findsOneWidget);
    expect(find.text('detail-body-43'), findsOneWidget);
    expect(nav.location, '/products/43');
  });

  testWidgets('a pop shifts the viewport back by one column', (tester) async {
    await _pumpAt(tester, 1000);
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    nav.open('/products/41');
    await tester.pumpAndSettle();
    nav.open('/products/42');
    await tester.pumpAndSettle();
    expect(nav.location, '/products/42');

    // Pop: [41, 42] -> [41]... wait, the stack is [products, 41, 42], so the
    // panes become [products, 41] — the old master (41) becomes the detail.
    // pop：栈为 [products, 41, 42]，pane 变为 [products, 41]——旧 master（41）
    // 成为 detail。
    expect(await nav.maybePop(), isTrue);
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.text('detail-body-42'),
      findsOneWidget,
      reason: 'the exiting detail should still be mounted mid-shift',
    );

    await tester.pumpAndSettle();
    expect(find.text('detail-body-42'), findsNothing);
    expect(find.text('detail-body-41'), findsOneWidget);
    expect(nav.location, '/products/41');
  });

  testWidgets('a collapse keeps the exiting detail mounted mid-animation', (
    tester,
  ) async {
    await _pumpAt(tester, 1000);
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    nav.open('/products/42');
    await tester.pumpAndSettle();
    expect(find.text('detail-body-42'), findsOneWidget);

    expect(await nav.maybePop(), isTrue);
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      find.text('detail-body-42'),
      findsOneWidget,
      reason: 'the exiting detail should still be mounted mid-collapse',
    );

    await tester.pumpAndSettle();
    expect(find.text('detail-body-42'), findsNothing);
    expect(nav.location, '/products');
  });

  testWidgets('page state survives a compact -> expanded crossing', (
    tester,
  ) async {
    final router = await _pumpAt(tester, 400, returnRouter: true);

    // Push the detail page and bump its counter.
    // push 详情页并点击计数器。
    await tester.tap(find.text('Product 42'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('count:0'));
    await tester.pumpAndSettle();
    expect(find.text('count:1'), findsOneWidget);

    // Cross to expanded with the SAME router: the pane layout replaces the
    // branch navigator, and the keyed page subtree must move, not reset.
    // 用同一个路由跨越到 expanded：pane 布局取代 branch navigator，带键的
    // 页面子树必须移动而非重置。
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1000, 900)),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('count:1'), findsOneWidget);
    expect(find.text('detail-body-42'), findsOneWidget);
    // The master pane is still there too. / master pane 也仍在。
    expect(find.text('Product 41'), findsOneWidget);
  });

  testWidgets('page state survives an expanded -> compact crossing', (
    tester,
  ) async {
    final router = await _pumpAt(tester, 1000, returnRouter: true);

    await tester.tap(find.text('Product 42'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('count:0'));
    await tester.pumpAndSettle();
    expect(find.text('count:1'), findsOneWidget);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 900)),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('count:1'), findsOneWidget);
  });

  testWidgets('ZeroRouteState.pageKey is a stable per-page GlobalKey', (
    tester,
  ) async {
    GlobalKey? firstKey;
    GlobalKey? secondKey;
    await _pumpAt(
      tester,
      400,
      onDetailBuilt: (state) {
        firstKey ??= state.pageKey;
        secondKey = state.pageKey;
      },
    );
    await tester.tap(find.text('Product 42'));
    await tester.pumpAndSettle();

    expect(firstKey, isA<GlobalKey>());
    expect(secondKey, isA<GlobalKey>());
    expect(
      firstKey,
      same(secondKey),
      reason: 'the same state instance must expose the same key',
    );
  });

  testWidgets('ZeroNav.goTab switches tabs imperatively', (tester) async {
    await _pumpAt(tester, 400, twoTabs: true);
    final nav = ZeroNav.of(tester.element(find.byType(Navigator).first));
    expect(nav.currentTabIndex, 0);
    expect(nav.location, '/products');

    nav.goTab(1);
    await tester.pumpAndSettle();
    expect(nav.currentTabIndex, 1);
    expect(nav.location, '/cart');

    // With an initial location the target tab resets to it.
    // 指定 initialLocation 时目标 tab 重置到该 location。
    nav.goTab(0, initialLocation: '/products/42');
    await tester.pumpAndSettle();
    expect(nav.currentTabIndex, 0);
    expect(nav.location, '/products/42');
  });

  testWidgets('SlidingPanes renders the placeholder as the detail column', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: SizedBox(
            width: 800,
            height: 100,
            child: SlidingPanes(
              placeholder: Text('empty'),
              children: [Text('master')],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('master'), findsOneWidget);
    expect(find.text('empty'), findsOneWidget);
    // The placeholder column sits to the right of the master.
    // 占位列位于 master 右侧。
    expect(
      tester.getTopLeft(find.text('empty')).dx,
      greaterThan(tester.getTopLeft(find.text('master')).dx),
    );
  });
}

/// Pumps the demo router at [width]; returns the router when [returnRouter].
/// 以 [width] 宽度挂载演示路由；[returnRouter] 为 true 时返回路由实例。
Future<ZeroRouter?> _pumpAt(
  WidgetTester tester,
  double width, {
  bool returnRouter = false,
  bool twoTabs = false,
  ValueChanged<ZeroRouteState>? onDetailBuilt,
}) async {
  final router = _buildRouter(twoTabs: twoTabs, onDetailBuilt: onDetailBuilt);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width, 900)),
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return returnRouter ? router : null;
}

ZeroRouter _buildRouter({
  bool twoTabs = false,
  ValueChanged<ZeroRouteState>? onDetailBuilt,
}) {
  return ZeroRouter(
    initialLocation: '/products',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => Scaffold(body: child),
        tabs: [
          ZeroTab(
            initialLocation: '/products',
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
                        child: const ListTile(title: Text('Product 42')),
                      ),
                      ZeroLink(
                        location: '/products/43',
                        child: const ListTile(title: Text('Product 43')),
                      ),
                    ],
                  ),
                ),
                routes: [
                  ZeroRoute(
                    path: ':id',
                    builder: (context, state) {
                      onDetailBuilt?.call(state);
                      return _CounterDetail(
                        key: ValueKey('detail-${state.pathParameters['id']}'),
                        id: state.pathParameters['id']!,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          if (twoTabs)
            ZeroTab(
              initialLocation: '/cart',
              routes: [ZeroRoute(path: '/cart', builder: _page)],
            ),
        ],
      ),
    ],
  );
}

/// A detail page whose counter proves element state survived a rebuild /
/// reparent. / 以计数器证明元素状态在重建 / 重挂载后留存的详情页。
class _CounterDetail extends StatefulWidget {
  const _CounterDetail({required this.id, super.key});

  final String id;

  @override
  State<_CounterDetail> createState() => _CounterDetailState();
}

class _CounterDetailState extends State<_CounterDetail> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail ${widget.id}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('detail-body-${widget.id}'),
            GestureDetector(
              onTap: () => setState(() => count++),
              child: Text('count:$count'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _page(BuildContext context, ZeroRouteState state) =>
    const Scaffold(body: Center(child: Text('Cart')));
