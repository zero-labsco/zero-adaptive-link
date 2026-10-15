import 'package:zero_adaptive_link/src/router/router.dart';
import 'package:zero_adaptive_link/src/router/state.dart';

/// One successful match of a location against the route table.
/// location 与路由表的一次成功匹配。
class ZeroRouteMatch {
  /// Create a match. / 创建一次匹配。
  const ZeroRouteMatch({required this.route, required this.state, this.title});

  /// The matched route definition. / 匹配到的路由定义。
  final ZeroRoute route;

  /// The evaluated route state (parameters, query, arguments).
  /// 求值后的路由状态（参数、query、arguments）。
  final ZeroRouteState state;

  /// The route title, evaluated once at match time.
  /// match 时求值一次的路由标题。
  final String? title;

  /// The actual location of this match. / 该匹配的实际 location。
  String get location => state.location;
}

/// The ordered match stack produced for a location — this *is* the page stack.
/// 一个 location 产生的有序匹配栈——它即页面栈。
class MatchList {
  /// Create a match list. / 创建匹配列表。
  const MatchList(this.matches);

  /// An empty match list. / 空匹配列表。
  const MatchList.empty() : matches = const <ZeroRouteMatch>[];

  /// The matches, outermost first. / 匹配列表，最外层在前。
  final List<ZeroRouteMatch> matches;

  /// Whether the list is empty. / 列表是否为空。
  bool get isEmpty => matches.isEmpty;

  /// Whether the list is non-empty. / 列表是否非空。
  bool get isNotEmpty => matches.isNotEmpty;

  /// Number of matches. / 匹配数量。
  int get length => matches.length;

  /// The leaf match, or `null` when empty. / 叶子匹配，空时为 `null`。
  ZeroRouteMatch? get last => matches.isEmpty ? null : matches.last;

  /// The root match, or `null` when empty. / 根匹配，空时为 `null`。
  ZeroRouteMatch? get first => matches.isEmpty ? null : matches.first;

  /// The location of the leaf match. / 叶子匹配的 location。
  String get location => matches.isEmpty ? '/' : matches.last.location;
}

/// Pure location matching against a route table. First match wins; child paths
/// are relative to their parent; `:param` matches a single path segment.
/// 针对路由表的纯 location 匹配。首个匹配获胜；子路径相对父路径；
/// `:param` 匹配单个路径片段。
class ZeroRouteMatcher {
  const ZeroRouteMatcher._();

  /// Split a path or pattern into non-empty segments.
  /// 将路径或 pattern 拆分为非空片段。
  static List<String> splitSegments(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).toList();
  }

  /// Join a parent pattern with a (relative) child path.
  /// 将父 pattern 与（相对的）子路径拼接。
  static String joinPattern(String prefix, String path) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    if (cleaned.isEmpty) {
      return prefix;
    }
    return prefix == '/' ? '/$cleaned' : '$prefix/$cleaned';
  }

  /// Match [location] against [routes], returning the ordered match stack or
  /// `null` when nothing matches.
  /// 将 [location] 与 [routes] 匹配，返回有序匹配栈；无匹配时返回 `null`。
  static MatchList? match(
    List<ZeroRoute> routes,
    String location, {
    Object? arguments,
  }) {
    final normalized = location.isEmpty ? '/' : location;
    final uri = Uri.parse(normalized);
    final segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final query = uri.queryParameters;
    final matches = _matchTree(
      routes: routes,
      segments: segments,
      patternPrefix: '/',
      actualPrefix: '/',
      inheritedParams: const <String, String>{},
      query: query,
      arguments: arguments,
    );
    return matches == null ? null : MatchList(matches);
  }

  static List<ZeroRouteMatch>? _matchTree({
    required List<ZeroRoute> routes,
    required List<String> segments,
    required String patternPrefix,
    required String actualPrefix,
    required Map<String, String> inheritedParams,
    required Map<String, String> query,
    required Object? arguments,
  }) {
    for (final route in routes) {
      final routeSegments = splitSegments(route.path);
      final params = Map<String, String>.from(inheritedParams);
      var consumed = 0;
      var matched = true;
      for (final patternSegment in routeSegments) {
        if (consumed >= segments.length) {
          matched = false;
          break;
        }
        if (patternSegment.startsWith(':')) {
          params[patternSegment.substring(1)] = segments[consumed];
        } else if (patternSegment != segments[consumed]) {
          matched = false;
          break;
        }
        consumed++;
      }
      if (!matched) {
        continue;
      }
      final newPatternPrefix = joinPattern(patternPrefix, route.path);
      final newActualPrefix = _joinActual(actualPrefix, segments, consumed);
      final state = ZeroRouteState(
        fullPath: newPatternPrefix,
        location: _withQuery(newActualPrefix, query),
        route: route,
        pathParameters: params,
        queryParameters: query,
        arguments: arguments,
      );
      final match = ZeroRouteMatch(
        route: route,
        state: state,
        title: route.title?.call(state),
      );
      if (consumed == segments.length) {
        return [match];
      }
      final deeper = _matchTree(
        routes: route.routes,
        segments: segments.sublist(consumed),
        patternPrefix: newPatternPrefix,
        actualPrefix: newActualPrefix,
        inheritedParams: params,
        query: query,
        arguments: arguments,
      );
      if (deeper != null) {
        return [match, ...deeper];
      }
      // The route matched a prefix but no child matched the remainder: the
      // location is not expressible by this route, so try the next sibling
      // (first match wins).
      // 该路由匹配了前缀但没有子路由匹配剩余部分：该 location 无法由本路由
      // 表达，继续尝试下一个同级路由（首个匹配获胜）。
    }
    return null;
  }

  static String _joinActual(String prefix, List<String> segments, int count) {
    var result = prefix;
    for (var i = 0; i < count; i++) {
      // Re-encode: `Uri.parse` decoded the segments, and emitting them raw
      // would rewrite the location (`/products/a%20b` → `/products/a b`) and
      // desync it from `namedLocation` (which encodes) and from the URL bar.
      // 重新编码：`Uri.parse` 会解码片段，原样拼回会改写 location
      // （`/products/a%20b` → `/products/a b`），与 `namedLocation`（会编码）
      // 和地址栏脱节。
      final segment = Uri.encodeComponent(segments[i]);
      result = result == '/' ? '/$segment' : '$result/$segment';
    }
    return result;
  }

  static String _withQuery(String path, Map<String, String> query) {
    if (query.isEmpty) {
      return path;
    }
    return '$path?${Uri(queryParameters: query).query}';
  }
}
