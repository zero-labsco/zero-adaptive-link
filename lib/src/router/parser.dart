import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Parses [RouteInformation] into a plain location string (the router's
/// configuration type).
/// 将 [RouteInformation] 解析为纯 location 字符串（路由的配置类型）。
///
/// The location is the full path plus query, e.g. `/products/42?tab=specs`.
/// location 为完整路径加 query，例如 `/products/42?tab=specs`。
class ZeroRouteInformationParser extends RouteInformationParser<String> {
  /// Create the parser. / 创建解析器。
  const ZeroRouteInformationParser();

  @override
  Future<String> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    // Web hash strategy: the location lives in the fragment (`/#/products/42`).
    // Web hash 策略：location 位于 fragment 中（`/#/products/42`）。
    var location = uri.fragment.isNotEmpty ? uri.fragment : uri.path;
    if (uri.query.isNotEmpty) {
      location = '$location?${uri.query}';
    }
    if (location.isEmpty) {
      location = '/';
    }
    return SynchronousFuture<String>(location);
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    final uri = Uri.parse(configuration);
    // Restore as a fragment URI so the provider writes the hash back.
    // 以 fragment URI 形式还原，使 provider 回写 hash。
    return RouteInformation(uri: uri);
  }
}
