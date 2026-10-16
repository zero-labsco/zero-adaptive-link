// Regression tests for the navigation state machine fixes: the async
// resolution race (the last requested location must win) and
// `pushReplacementNamed` at a branch root (replace, not stack).
// 导航状态机修复的回归测试：异步解析竞态（最后请求的 location 必须获胜）
// 与 `pushReplacementNamed` 位于 branch 根节点时（替换而非压栈）。
// ignore_for_file: unawaited_futures

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('async resolution race', () {
    test(
      'the last requested location wins over a slower earlier one',
      () async {
        final router = ZeroRouter(
          initialLocation: '/home',
          routes: [
            ZeroShell(
              builder: (context, shell, child) => child,
              tabs: [
                ZeroTab(
                  initialLocation: '/home',
                  routes: [
                    ZeroRoute(path: '/home', builder: _page),
                    ZeroRoute(
                      path: '/slow',
                      // A slow async route redirect: the resolution of `/slow`
                      // lands AFTER `/fast` has already been applied.
                      // 慢速异步路由重定向：`/slow` 的解析落地晚于已应用的
                      // `/fast`。
                      redirect: (state) async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 50),
                        );
                        return null;
                      },
                      builder: _page,
                    ),
                    ZeroRoute(path: '/fast', builder: _page),
                  ],
                ),
              ],
            ),
          ],
        );
        final delegate = router.routerDelegate as ZeroRouterDelegate;
        await delegate.setNewRoutePath('/home');

        // Fire slow first, fast second. / 先发慢的，再发快的。
        delegate.pushNamed('/slow');
        delegate.pushNamed('/fast');
        await Future<void>.delayed(const Duration(milliseconds: 150));

        expect(
          delegate.location,
          '/fast',
          reason: 'the last requested location must win, not the slow one',
        );
      },
    );

    test('external navigations keep their order too', () async {
      final router = ZeroRouter(
        initialLocation: '/home',
        redirect: (location) async {
          if (location == '/slow') {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          return null;
        },
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: [
              ZeroTab(
                initialLocation: '/home',
                routes: [
                  ZeroRoute(path: '/home', builder: _page),
                  ZeroRoute(path: '/slow', builder: _page),
                  ZeroRoute(path: '/fast', builder: _page),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');

      final slow = delegate.setNewRoutePath('/slow');
      final fast = delegate.setNewRoutePath('/fast');
      await Future.wait([slow, fast]);

      expect(delegate.location, '/fast');
    });
  });

  group('pushReplacementNamed at the branch root', () {
    test('replaces the root entry instead of stacking on it', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      expect(delegate.canPop, isFalse);

      // `/other` is a TOP-LEVEL sibling of the root: replacing the root must
      // swap it out, leaving a single-entry stack.
      // `/other` 是根的顶层兄弟路由：替换根必须把它换掉，只留单条目栈。
      delegate.pushReplacementNamed('/other');
      await _flush();
      expect(delegate.location, '/other');
      // A replacement leaves a single-entry stack: nothing left to pop.
      // 替换之后是单条目栈：无可再 pop 的内容。
      expect(delegate.canPop, isFalse);

      // Popping at the (replaced) root is a no-op.
      // 在（被替换的）根节点 pop 是 no-op。
      delegate.pop();
      expect(delegate.location, '/other');
    });

    test('a nested target keeps its parent chain (as a push would)', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');

      // `/home/detail` inherently expresses as ['/home', '/home/detail'], so
      // the root stays as the parent and popping returns to it.
      // `/home/detail` 天然表达为 ['/home', '/home/detail']，根作为父级保留，
      // pop 后回到它。
      delegate.pushReplacementNamed('/home/detail');
      await _flush();
      expect(delegate.location, '/home/detail');
      expect(delegate.canPop, isTrue);

      delegate.pop();
      expect(delegate.location, '/home');
    });

    test('above the root it still swaps only the top entry', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      delegate.pushNamed('/home/one');
      await _flush();
      delegate.pushReplacementNamed('/home/two');
      await _flush();
      expect(delegate.location, '/home/two');
      expect(delegate.canPop, isTrue);

      delegate.pop();
      expect(delegate.location, '/home');
    });
  });

  group('named route registration', () {
    test('duplicate route names fail with the friendly assert', () {
      expect(
        () => ZeroRouter(
          initialLocation: '/a',
          routes: [
            ZeroShell(
              builder: (context, shell, child) => child,
              tabs: const [
                ZeroTab(
                  routes: [
                    ZeroRoute(path: '/a', name: 'dup', builder: _page),
                    ZeroRoute(path: '/b', name: 'dup', builder: _page),
                  ],
                ),
              ],
            ),
          ],
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('Duplicate route name'),
          ),
        ),
      );
    });
  });
}

/// Flush pending microtasks so async navigation applies.
/// 冲刷待处理的微任务，使异步导航生效。
Future<void> _flush() => Future<void>.delayed(Duration.zero);

Widget _page(BuildContext context, ZeroRouteState state) =>
    const SizedBox.shrink();

ZeroRouter _buildRouter() {
  return ZeroRouter(
    initialLocation: '/home',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => child,
        tabs: [
          ZeroTab(
            initialLocation: '/home',
            routes: [
              ZeroRoute(
                path: '/home',
                builder: _page,
                routes: [
                  ZeroRoute(path: 'one', builder: _page),
                  ZeroRoute(path: 'two', builder: _page),
                  ZeroRoute(path: 'detail', builder: _page),
                ],
              ),
              ZeroRoute(path: '/other', builder: _page),
            ],
          ),
        ],
      ),
    ],
  );
}
