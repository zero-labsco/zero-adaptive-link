import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('ZeroRouteMatcher', () {
    final routes = <ZeroRoute>[
      ZeroRoute(
        path: '/products',
        builder: _routePage('products'),
        routes: [ZeroRoute(path: ':id', builder: _routePage('detail'))],
      ),
      ZeroRoute(path: '/cart', builder: _routePage('cart')),
    ];

    test('matches a nested location into an ordered stack', () {
      final matched = ZeroRouteMatcher.match(routes, '/products/42');
      expect(matched, isNotNull);
      expect(matched!.length, 2);
      expect(matched.matches[0].location, '/products');
      expect(matched.matches[1].location, '/products/42');
      expect(matched.location, '/products/42');
    });

    test('extracts path parameters', () {
      final matched = ZeroRouteMatcher.match(routes, '/products/42')!;
      expect(matched.last!.state.pathParameters, {'id': '42'});
    });

    test('extracts query parameters', () {
      final matched = ZeroRouteMatcher.match(routes, '/cart?coupon=SAVE')!;
      expect(matched.last!.state.queryParameters, {'coupon': 'SAVE'});
      expect(matched.last!.state.location, '/cart?coupon=SAVE');
      expect(matched.last!.state.uri.queryParameters, {'coupon': 'SAVE'});
    });

    test('first match wins', () {
      final ambiguous = <ZeroRoute>[
        ZeroRoute(path: '/:id', builder: _routePage('first')),
        ZeroRoute(path: '/products', builder: _routePage('second')),
      ];
      final matched = ZeroRouteMatcher.match(ambiguous, '/products')!;
      expect(matched.first!.route.builder, isNot(_routePage('second')));
      expect(matched.length, 1);
    });

    test('returns null for unmatched locations', () {
      expect(ZeroRouteMatcher.match(routes, '/unknown'), isNull);
      expect(ZeroRouteMatcher.match(routes, '/products/42/reviews'), isNull);
    });

    test('child paths are relative to the parent', () {
      final matched = ZeroRouteMatcher.match(routes, '/products/42')!;
      expect(matched.last!.state.fullPath, '/products/:id');
    });

    test('a leading slash on a child path stays relative', () {
      final nested = <ZeroRoute>[
        ZeroRoute(
          path: '/a',
          builder: _routePage('a'),
          routes: [ZeroRoute(path: '/b', builder: _routePage('b'))],
        ),
      ];
      final matched = ZeroRouteMatcher.match(nested, '/a/b')!;
      expect(matched.length, 2);
      expect(matched.last!.state.fullPath, '/a/b');
    });

    test('evaluates the route title once at match time', () {
      final titled = <ZeroRoute>[
        ZeroRoute(
          path: '/products/:id',
          title: (state) => 'Product ${state.pathParameters['id']}',
          builder: _routePage('detail'),
        ),
      ];
      final matched = ZeroRouteMatcher.match(titled, '/products/7')!;
      expect(matched.last!.title, 'Product 7');
    });

    test('empty location normalizes to /', () {
      final root = <ZeroRoute>[
        ZeroRoute(path: '/', builder: _routePage('root')),
      ];
      expect(ZeroRouteMatcher.match(root, ''), isNotNull);
    });

    test('percent-encoded segments round-trip unchanged', () {
      // Regression: `Uri.parse` decodes path segments, and re-emitting them
      // raw rewrote the location (`/products/a%20b` → `/products/a b`),
      // desyncing it from `namedLocation` (which encodes) and from the URL.
      // 回归：`Uri.parse` 会解码路径片段，原样拼回会改写 location
      // （`/products/a%20b` → `/products/a b`），与 `namedLocation`（会编码）
      // 和 URL 脱节。
      final matched = ZeroRouteMatcher.match(routes, '/products/a%20b')!;
      expect(matched.last!.location, '/products/a%20b');
      expect(matched.last!.state.pathParameters['id'], 'a b');

      // An encoded slash stays inside one segment and stays encoded.
      // 编码的斜杠仍属于单个片段，且保持编码。
      final slashed = ZeroRouteMatcher.match(routes, '/products/a%2Fb')!;
      expect(slashed.last!.location, '/products/a%2Fb');
      expect(slashed.last!.state.pathParameters['id'], 'a/b');

      // Non-ASCII parameters survive the round-trip too.
      // 非 ASCII 参数同样可以往返。
      final unicode = ZeroRouteMatcher.match(routes, '/products/%E4%B8%AD')!;
      expect(unicode.last!.location, '/products/%E4%B8%AD');
      expect(unicode.last!.state.pathParameters['id'], '中');
    });

    test('joinPattern joins relative child paths', () {
      expect(ZeroRouteMatcher.joinPattern('/', 'products'), '/products');
      expect(ZeroRouteMatcher.joinPattern('/products', ':id'), '/products/:id');
      expect(ZeroRouteMatcher.joinPattern('/products', '/x'), '/products/x');
      expect(ZeroRouteMatcher.joinPattern('/', '/'), '/');
    });
  });
}

ZeroRouteBuilder _routePage(String name) {
  return (context, state) => Text(name);
}
