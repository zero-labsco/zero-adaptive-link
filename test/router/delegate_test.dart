// The push verbs intentionally return futures completed by `pop(result)`;
// the state machine tests fire them without awaiting.
// push 系动词刻意返回由 `pop(result)` 完成的 Future；状态机测试采用触发后不等候。
// ignore_for_file: unawaited_futures

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  // GlobalKey.currentState (used by maybePop/popRoute) needs a binding.
  // GlobalKey.currentState（maybePop/popRoute 使用）需要 binding。
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ZeroRouterDelegate state machine', () {
    test('setNewRoutePath resolves the location', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products/42');
      expect(delegate.currentConfiguration, '/products/42');
      expect(delegate.location, '/products/42');
    });

    test('pushNamed appends and pop unwinds', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      expect(delegate.currentConfiguration, '/products');

      final future = delegate.pushNamed('/products/42');
      await _flush();
      expect(delegate.currentConfiguration, '/products/42');
      expect(delegate.canPop, isTrue);

      delegate.pop('done');
      expect(delegate.currentConfiguration, '/products');
      expect(await future, 'done');
      expect(delegate.canPop, isFalse);
    });

    test('pushNamedAndRemoveUntil keeps only the kept root', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      delegate.pushNamed('/products/41');
      await _flush();
      delegate.pushNamed('/products/42');
      await _flush();
      expect(delegate.currentConfiguration, '/products/42');

      delegate.pushNamedAndRemoveUntil('/cart', (match) => false);
      await _flush();
      expect(delegate.currentConfiguration, '/cart');
    });

    test('popUntil stops at the matching location', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      delegate.pushNamed('/products/41');
      await _flush();
      delegate.pushNamed('/products/42');
      await _flush();
      delegate.popUntil((match) => match.location == '/products');
      expect(delegate.currentConfiguration, '/products');
    });

    test('maybePop at the tab root is a no-op', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      expect(await delegate.maybePop(), isFalse);
      expect(delegate.currentConfiguration, '/products');
    });

    test('maybePop removes the top entry', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      delegate.pushNamed('/products/42');
      await _flush();
      expect(await delegate.maybePop(), isTrue);
      expect(delegate.currentConfiguration, '/products');
    });

    test('pushNamed is idempotent for the current location', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products/42');
      delegate.pushNamed('/products/42');
      await _flush();
      expect(delegate.currentConfiguration, '/products/42');
    });

    test('pushReplacementNamed swaps the top entry', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      delegate.pushNamed('/products/41');
      await _flush();
      delegate.pushReplacementNamed('/products/42');
      await _flush();
      expect(delegate.currentConfiguration, '/products/42');
      delegate.pop();
      expect(delegate.currentConfiguration, '/products');
    });

    test('goTab switches tabs and syncs the location', () async {
      final router = _buildRouter();
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/products');
      expect(delegate.currentTabIndex, 0);

      delegate.goTab(1);
      expect(delegate.currentTabIndex, 1);
      expect(delegate.currentConfiguration, '/cart');

      delegate.goTab(0);
      expect(delegate.currentTabIndex, 0);
      expect(delegate.currentConfiguration, '/products');
    });

    test('router redirect rewrites the location', () async {
      final router = ZeroRouter(
        initialLocation: '/login',
        redirect: (location) => location == '/secret' ? '/login' : null,
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: const [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/login', builder: _page),
                  ZeroRoute(path: '/secret', builder: _page),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/secret');
      expect(delegate.currentConfiguration, '/login');
    });

    test('redirect loop exceeding the limit lands on the error page', () async {
      final router = ZeroRouter(
        initialLocation: '/a',
        redirectLimit: 3,
        redirect: (location) => '/b',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: const [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/a', builder: _page),
                  ZeroRoute(path: '/b', builder: _page),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/a');
      // The requested location is preserved; the stack holds the error page.
      expect(delegate.currentConfiguration, '/a');
    });

    test('namedLocation builds parameterized locations', () async {
      final router = ZeroRouter(
        initialLocation: '/products',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: const [
              ZeroTab(
                routes: [
                  ZeroRoute(
                    path: '/products',
                    name: 'products',
                    builder: _page,
                    routes: [
                      ZeroRoute(path: ':id', name: 'product', builder: _page),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      expect(
        delegate.namedLocation('product', pathParameters: {'id': '42'}),
        '/products/42',
      );
      expect(
        delegate.namedLocation(
          'product',
          pathParameters: {'id': '42'},
          queryParameters: {'tab': 'specs'},
        ),
        '/products/42?tab=specs',
      );
      expect(delegate.namedLocation('missing'), isNull);
    });

    test('route-level redirect rewrites the location', () async {
      final router = ZeroRouter(
        initialLocation: '/new',
        routes: [
          ZeroShell(
            builder: (context, shell, child) => child,
            tabs: [
              ZeroTab(
                routes: [
                  ZeroRoute(path: '/new', builder: _page),
                  ZeroRoute(
                    path: '/old',
                    redirect: (state) => '/new',
                    builder: _page,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final delegate = router.routerDelegate as ZeroRouterDelegate;
      await delegate.setNewRoutePath('/old');
      expect(delegate.currentConfiguration, '/new');
    });
  });
}

/// Flush pending microtasks so async navigation applies.
/// 冲刷待处理的微任务，使异步导航生效。
Future<void> _flush() => Future<void>.delayed(Duration.zero);

ZeroRouter _buildRouter() {
  return ZeroRouter(
    initialLocation: '/products',
    routes: [
      ZeroShell(
        builder: (context, shell, child) => child,
        tabs: const [
          ZeroTab(
            routes: [
              ZeroRoute(
                path: '/products',
                builder: _page,
                routes: [ZeroRoute(path: ':id', builder: _page)],
              ),
            ],
          ),
          ZeroTab(
            routes: [ZeroRoute(path: '/cart', builder: _page)],
          ),
        ],
      ),
    ],
  );
}

Widget _page(BuildContext context, ZeroRouteState state) =>
    const SizedBox.shrink();
