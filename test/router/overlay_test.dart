// The overlay (fullscreen) stack: its futures must never leak, deep links must
// fall back to the tab's default route, and exit hooks must veto pops.
// 覆盖（fullscreen）栈：其 Future 绝不能泄漏、深链必须回退到 tab 默认路由、
// 退出钩子必须能否决 pop。
// ignore_for_file: unawaited_futures

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fullscreen overlay stack', () {
    test('push opens the overlay and pop completes the future', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');

      final future = delegate.pushNamed('/home/preview');
      await _flush();
      expect(delegate.location, '/home/preview');
      expect(delegate.canPop, isTrue);

      delegate.pop('closed');
      expect(await future, 'closed');
      expect(delegate.location, '/home');
      expect(delegate.canPop, isFalse);
    });

    test('a subsequent push completes the discarded overlay future', () async {
      // Regression: `_overlayStack.clear()` used to drop the entries without
      // completing their futures, so `await pushNamed('/home/preview')` hung
      // forever once another navigation replaced the overlay.
      // 回归：`_overlayStack.clear()` 过去直接丢弃条目而不补完 Future，
      // 一旦其它导航替换掉覆盖层，`await pushNamed('/home/preview')` 会永久挂起。
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');

      final done = Completer<Object?>();
      delegate.pushNamed('/home/preview').then(done.complete);
      await _flush();
      expect(delegate.location, '/home/preview');

      delegate.pushNamed('/other');
      await _flush();
      expect(delegate.location, '/other');
      expect(await done.future, isNull);
    });

    test('a deep link completes the discarded overlay future', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');

      final done = Completer<Object?>();
      delegate.pushNamed('/home/preview').then(done.complete);
      await _flush();

      // An external navigation (deep link / browser back) replaces the stacks.
      // 外部导航（深链 / 浏览器返回）会替换整个栈。
      await delegate.setNewRoutePath('/other');
      expect(delegate.location, '/other');
      expect(await done.future, isNull);
    });

    test(
      'an unmatched location completes the discarded overlay future',
      () async {
        final router = _buildRouter();
        final delegate = router.routerDelegate as ZeroRouterDelegate;
        await delegate.setNewRoutePath('/home');

        final done = Completer<Object?>();
        delegate.pushNamed('/home/preview').then(done.complete);
        await _flush();

        await delegate.setNewRoutePath('/nope');
        expect(delegate.location, '/nope');
        expect(await done.future, isNull);
        expect(delegate.canPop, isFalse);
      },
    );

    test(
      'a deep link to a fullscreen leaf keeps the tab route beneath',
      () async {
        final router = _buildRouter();
        final delegate = router.routerDelegate as ZeroRouterDelegate;
        await delegate.setNewRoutePath('/home');

        // `/home/preview` is a fullscreen leaf: the tab stack must fall back to
        // the tab's default route instead of ending up empty.
        // `/home/preview` 是 fullscreen 叶子：tab 栈必须回退到该 tab 的默认
        // 路由，而不是变空。
        await delegate.setNewRoutePath('/home/preview');
        expect(delegate.location, '/home/preview');
        delegate.pop();
        expect(delegate.location, '/home');
        expect(delegate.canPop, isFalse);
      },
    );

    test(
      'pushReplacementNamed over an overlay replaces it and settles it',
      () async {
        final router = _buildRouter();
        final delegate = router.routerDelegate as ZeroRouterDelegate;
        await delegate.setNewRoutePath('/home');

        final done = Completer<Object?>();
        delegate.pushNamed('/home/preview').then(done.complete);
        await _flush();

        delegate.pushReplacementNamed('/other');
        await _flush();
        expect(delegate.location, '/other');
        // The replaced overlay's future settles instead of leaking.
        // 被替换的覆盖层的 Future 得以补完，不再泄漏。
        expect(await done.future, isNull);
      },
    );

    // NOTE: `maybePop` / `popRoute` consult the mounted root navigator first
    // (so `PopScope` and in-page dialogs win), which needs a widget harness —
    // those paths are covered in `test/widgets/fullscreen_overlay_test.dart`.
    // 注意：`maybePop` / `popRoute` 先询问已挂载的根 navigator（让
    // `PopScope` 与页内 dialog 优先），需要 widget 测试环境——这些路径在
    // `test/widgets/fullscreen_overlay_test.dart` 中覆盖。
    test('popRoute at the bottom hands the request to the shell', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      // No navigator is mounted in this harness, so the request is unhandled
      // (in an app the shell route's PopScope would decide).
      // 本测试没有挂载 navigator，请求无人处理（在真实应用中由 shell route
      // 的 PopScope 决定）。
      expect(await delegate.popRoute(), isFalse);
      expect(delegate.location, '/home');
    });
  });

  group('onExit hooks', () {
    test('a vetoing onExit blocks maybePop', () async {
      final router = ZeroRouter(
        initialLocation: '/home',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/home', builder: _page),
                  ZeroRoute(path: '/other', builder: _page),
                  ZeroRoute(
                    path: '/guarded',
                    onExit: () async => false,
                    builder: _page,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      delegate.pushNamed('/guarded');
      await _flush();
      expect(delegate.location, '/guarded');

      expect(await delegate.maybePop(), isTrue);
      // `true` means "handled" — the pop was vetoed, so nothing moved.
      // `true` 表示「已处理」——pop 被否决，位置未变。
      expect(delegate.location, '/guarded');
    });

    test('a vetoing onExit blocks popRoute', () async {
      final router = ZeroRouter(
        initialLocation: '/home',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/home', builder: _page),
                  ZeroRoute(
                    path: '/guarded',
                    fullscreen: true,
                    onExit: () async => false,
                    builder: _page,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      delegate.pushNamed('/guarded');
      await _flush();
      expect(await delegate.popRoute(), isTrue);
      expect(delegate.location, '/guarded');
    });

    test('an allowing onExit lets the pop through', () async {
      final router = ZeroRouter(
        initialLocation: '/home',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/home', builder: _page),
                  ZeroRoute(
                    path: '/guarded',
                    onExit: () async => true,
                    builder: _page,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/home');
      delegate.pushNamed('/guarded');
      await _flush();
      // No navigator is mounted, so the delegate's declarative fallback runs
      // and reports the pop as handled.
      // 没有挂载 navigator，走 delegate 的声明式回退路径，并报告 pop 已处理。
      expect(await delegate.maybePop(), isTrue);
      expect(delegate.location, '/home');
    });
  });

  group('configuration asserts', () {
    test('an empty route table fails with the friendly assert', () {
      expect(
        () => ZeroRouter(initialLocation: '/', routes: <ZeroShell>[]),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('At least one ZeroShell is required'),
          ),
        ),
      );
    });

    test('multiple shells fail with the friendly assert', () {
      ZeroShell shell() => ZeroShell(
        builder: (context, shell, child) => child,
        tabs: const [
          ZeroTab(
            routes: [ZeroRoute(path: '/a', builder: _page)],
          ),
        ],
      );
      expect(
        () => ZeroRouter(initialLocation: '/', routes: [shell(), shell()]),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('Exactly one ZeroShell is supported'),
          ),
        ),
      );
    });

    test('a shell without tabs fails with the friendly assert', () {
      expect(
        () => ZeroRouter(
          initialLocation: '/',
          routes: [
            ZeroShell(
              builder: (context, shell, child) => child,
              tabs: const <ZeroTab>[],
            ),
          ],
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('at least one ZeroTab'),
          ),
        ),
      );
    });

    test('a tab without routes fails with the friendly assert', () {
      expect(
        () => ZeroRouter(
          initialLocation: '/',
          routes: [
            ZeroShell(
              builder: (context, shell, child) => child,
              tabs: const [ZeroTab(routes: <ZeroRoute>[])],
            ),
          ],
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('at least one ZeroRoute'),
          ),
        ),
      );
    });
  });
}

ZeroRouter _buildRouter() {
  return ZeroRouter(
    initialLocation: '/home',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => child,
        tabs: [
          ZeroTab(
            routes: [
              ZeroRoute(
                path: '/home',
                builder: _page,
                // A fullscreen LEAF under `/home`, so `/home/preview` is both
                // a push target and a deep link.
                // `/home` 下的 fullscreen 叶子，因此 `/home/preview` 既是
                // push 目标也是深链目标。
                routes: [
                  ZeroRoute(path: 'preview', fullscreen: true, builder: _page),
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

Future<void> _flush() => Future<void>.delayed(Duration.zero);

Widget _page(BuildContext context, ZeroRouteState state) =>
    const SizedBox.shrink();
