import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('SlidingPanes', () {
    testWidgets('renders a single column for one child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SlidingPanes(children: [Text('only')])),
      );
      expect(find.text('only'), findsOneWidget);
    });

    testWidgets('renders both columns for two children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SlidingPanes(children: [Text('master'), Text('detail')]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('master'), findsOneWidget);
      expect(find.text('detail'), findsOneWidget);
    });

    testWidgets('custom paneBuilder wraps each pane', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SlidingPanes(
            paneBuilder: (context, pane, isLeft) => Card(
              child: Padding(padding: const EdgeInsets.all(4), child: pane),
            ),
            children: const [Text('master'), Text('detail')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('custom resizeHandleBuilder is used', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SlidingPanes(
            resizeHandleBuilder: (context, isHovered) =>
                const SizedBox(width: 4, child: Text('handle')),
            children: const [Text('master'), Text('detail')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('handle'), findsOneWidget);
    });

    testWidgets('side flips the master/detail horizontal order', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 100,
            child: SlidingPanes(
              children: const [Text('master'), Text('detail')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Default: master on the left, detail on the right.
      // 默认：master 在左，detail 在右。
      expect(
        tester.getTopLeft(find.text('master')).dx,
        lessThan(tester.getTopLeft(find.text('detail')).dx),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 100,
            child: SlidingPanes(
              side: SlidingPanesSide.left,
              children: const [Text('master'), Text('detail')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Mirrored: master on the right, detail on the left.
      // 镜像：master 在右，detail 在左。
      expect(
        tester.getTopLeft(find.text('master')).dx,
        greaterThan(tester.getTopLeft(find.text('detail')).dx),
      );
    });

    testWidgets('maxLeftPaneWidth caps the master pane on a wide layout', (
      tester,
    ) async {
      // Widen the test surface: a plain `SizedBox` would be clamped to the
      // default 800x600 view and the ultra-wide case would never be exercised.
      // 加宽测试视口：仅用 `SizedBox` 会被默认 800x600 视口夹住，超宽场景
      // 根本测不到。
      final oldSize = tester.view.physicalSize;
      final oldDpr = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = oldSize;
        tester.view.devicePixelRatio = oldDpr;
      });
      tester.view.physicalSize = const Size(1600, 400);
      tester.view.devicePixelRatio = 1.0;

      // Measures where the detail pane starts for a given ceiling.
      // 测量给定上限下 detail pane 的起始位置。
      Future<double> detailLeft(double? ceiling) async {
        await tester.pumpWidget(
          MaterialApp(
            home: SlidingPanes(
              leftPaneFraction: 0.4,
              maxLeftPaneWidth: ceiling,
              children: const [Text('master'), Text('detail')],
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getTopLeft(find.text('detail')).dx;
      }

      // No ceiling: the master takes 40% of 1600 (~640px).
      // 无上限：master 占 1600 的 40%（约 640px）。
      expect(await detailLeft(null), greaterThan(600));
      // With a ceiling the master stops at 300px and the detail moves left.
      // 设上限后 master 停在 300px，detail 随之左移。
      expect(await detailLeft(300), lessThan(350));
    });

    testWidgets('drag follows the pointer by its true travel', (tester) async {
      // The handle moves with the pane during the drag, so a local-position
      // delta would feed back and stall it. Only the global pointer travel
      // makes the fraction track the drag (regression for the drift bug).
      // handle 拖拽时随 pane 移动，局部坐标会自我反馈而卡住；只有全局指针位移
      // 能让比例真正跟随拖拽（漂移 bug 的回归测试）。
      double? lastFraction;
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 100,
            child: SlidingPanes(
              leftPaneFraction: 0.4,
              onLeftPaneFractionChanged: (f) => lastFraction = f,
              children: const [Text('master'), Text('detail')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final handle = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onHorizontalDragStart != null,
      );
      final center = tester.getCenter(handle);
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      // Usable width ≈ 800 - 4 (handle) = 796; an 80px drag grows the master
      // fraction by ~0.10, so 0.4 → ~0.50. A stalled (local-position) pane
      // would stay near 0.4.
      // 可用宽 ≈ 800 - 4（分割线）= 796；右拖 80px 应使 master 占比增 ~0.10，
      // 即 0.4 → ~0.50。卡顿（局部坐标）实现会停在 ~0.4。
      expect(lastFraction, isNotNull);
      expect(lastFraction!, greaterThan(0.44));
      expect(lastFraction!, lessThan(0.6));
    });
  });

  group('Breadcrumbs', () {
    testWidgets('renders items with separators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Breadcrumbs(items: ['/products', '/products/42']),
        ),
      );
      expect(find.text('/products'), findsOneWidget);
      expect(find.text('/products/42'), findsOneWidget);
      expect(find.text('›'), findsOneWidget);
    });

    testWidgets('reports the tapped index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Breadcrumbs(
            items: const ['/products', '/products/42'],
            onNavigate: (index) => tapped = index,
          ),
        ),
      );
      await tester.tap(find.text('/products'));
      expect(tapped, 0);
    });
  });
}
