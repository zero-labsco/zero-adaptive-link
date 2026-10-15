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
    // The outer query only applies to a path-style location. With the hash
    // strategy the app's own query already sits inside the fragment
    // (`/#/products/42?tab=1`), and the query outside the hash belongs to the
    // host page — merging it would inject unrelated parameters into the
    // location (`/?utm=x#/products/42` must not become `/products/42?utm=x`).
    // 外层 query 仅对路径式 location 生效。hash 策略下应用自身的 query 已在
    // fragment 内（`/#/products/42?tab=1`），hash 之外的 query 属于宿主页面——
    // 合并它会向 location 注入无关参数（`/?utm=x#/products/42` 不应变成
    // `/products/42?utm=x`）。
    if (uri.fragment.isEmpty && uri.query.isNotEmpty) {
      location = '$location?${uri.query}';
    }
    if (location.isEmpty) {
      location = '/';
    }
    return SynchronousFuture<String>(location);
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    // The configuration is a plain location (`/products/42?tab=specs`); the
    // provider re-adds the `#` when it writes the hash back, so the URI must
    // NOT carry a fragment here (a fragment would be parsed back out as the
    // location and double-wrap the hash).
    // configuration 是纯 location（`/products/42?tab=specs`）；provider 回写
    // hash 时会自己加上 `#`，因此这里绝不能带 fragment（否则会被重新解析为
    // location，导致 hash 双重包裹）。
    final uri = Uri.parse(configuration);
    return RouteInformation(uri: uri);
  }
}
