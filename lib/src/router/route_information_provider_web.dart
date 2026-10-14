import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// Top-level `window.location.hash` accessor.
/// 顶层 `window.location.hash` 访问器。
@JS('window.location.hash')
external String get _windowHash;

/// `window.history.pushState(state, unused, url)`.
@JS('window.history.pushState')
external void _pushState(JSAny? data, String unused, String url);

/// `window.history.replaceState(state, unused, url)`.
@JS('window.history.replaceState')
external void _replaceState(JSAny? data, String unused, String url);

/// `window.addEventListener(type, listener)`.
@JS('window.addEventListener')
external void _addEventListener(String type, JSAny? listener);

/// `window.removeEventListener(type, listener)`.
@JS('window.removeEventListener')
external void _removeEventListener(String type, JSAny? listener);

/// A [RouteInformationProvider] implementing the web hash URL strategy:
/// locations live in `window.location.hash` (`/#/products/42`).
/// 实现 Web hash URL 策略的 [RouteInformationProvider]：
/// location 存放在 `window.location.hash` 中（`/#/products/42`）。
///
/// Writes use `history.pushState` / `replaceState`, which do not fire
/// `hashchange` — so in-app navigations never echo back as a second route
/// change. Incoming changes (browser back / forward, manual URL edits) are
/// observed via `popstate` and `hashchange`.
/// 写入使用 `history.pushState` / `replaceState`，不会触发 `hashchange`——
/// 因此应用内导航不会回环成第二次路由变更。传入变更（浏览器前进后退、手动编辑
/// URL）通过 `popstate` 与 `hashchange` 监听。
class ZeroHashRouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  /// Create the provider. [initialLocation] is the fallback when the browser
  /// opens at `/` (an existing hash always wins).
  /// 创建 provider。[initialLocation] 是浏览器打开时为 `/` 的回退值
  /// （已存在的 hash 始终优先）。
  ZeroHashRouteInformationProvider({required String initialLocation})
    : _value = RouteInformation(
        uri: Uri.parse(_resolveInitialLocation(initialLocation)),
      ) {
    _listener = _handleUrlChange.toJS;
    _addEventListener('popstate', _listener);
    _addEventListener('hashchange', _listener);
  }

  RouteInformation _value;
  JSAny? _listener;
  bool _firstReport = true;

  static String _resolveInitialLocation(String fallback) {
    final hash = readHash();
    if (hash.isEmpty || hash == '/') {
      return fallback.isEmpty ? '/' : fallback;
    }
    return hash;
  }

  /// Read the current location from `window.location.hash`.
  /// 从 `window.location.hash` 读取当前 location。
  static String readHash() {
    final hash = _windowHash;
    if (hash.isEmpty) {
      return '/';
    }
    return hash.startsWith('#') ? hash.substring(1) : hash;
  }

  void _handleUrlChange(JSAny event) {
    final location = readHash();
    final uri = Uri.parse(location);
    if (_value.uri == uri) {
      return;
    }
    _value = RouteInformation(uri: uri);
    notifyListeners();
  }

  @override
  RouteInformation get value => _value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final url = '#${routeInformation.uri}';
    if (_windowHash != url) {
      // The very first report is the post-redirect initial configuration;
      // replace so a redirected deep link does not leave a stray entry.
      // 第一次上报是重定向后的初始配置；用 replace，避免深链重定向
      // 残留多余的历史条目。
      final replace =
          _firstReport ||
          type == RouteInformationReportingType.neglect ||
          type == RouteInformationReportingType.none &&
              _value.uri == routeInformation.uri;
      if (replace) {
        _replaceState(null, '', url);
      } else {
        _pushState(null, '', url);
      }
    }
    _firstReport = false;
    _value = routeInformation;
  }

  @override
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      _removeEventListener('popstate', listener);
      _removeEventListener('hashchange', listener);
      _listener = null;
    }
    super.dispose();
  }
}

/// Create the hash-strategy provider (web).
/// 创建 hash 策略 provider（Web）。
RouteInformationProvider createZeroRouteInformationProvider(
  String initialLocation,
) {
  return ZeroHashRouteInformationProvider(initialLocation: initialLocation);
}
