import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:zero_adaptive_link/src/router/delegate.dart';
import 'package:zero_adaptive_link/src/router/match.dart';

/// Inherited widget publishing the [ZeroRouterDelegate] for `ZeroNav.of`.
/// 为 `ZeroNav.of` 发布 [ZeroRouterDelegate] 的 InheritedWidget。
class ZeroNavScope extends InheritedWidget {
  /// Create the scope. / 创建该 scope。
  const ZeroNavScope({required this.delegate, required super.child, super.key});

  /// The published delegate. / 被发布的 delegate。
  final ZeroRouterDelegate delegate;

  @override
  bool updateShouldNotify(ZeroNavScope oldWidget) =>
      delegate != oldWidget.delegate;
}

/// The imperative entry point: the same navigation verbs as `NavigatorState`,
/// dispatched to whatever behavior the current window width requires.
/// 命令式入口：与 `NavigatorState` 同名的导航动词，按当前窗口宽度分派到
/// 对应的行为。
///
/// ```dart
/// ZeroNav.of(context).open('/products/42');
/// ```
class ZeroNav {
  ZeroNav._(this._delegate);

  final ZeroRouterDelegate _delegate;

  /// Read the nav for the nearest router; throws when none is above.
  /// 读取最近的路由对应的 nav；上方无路由时抛出异常。
  static ZeroNav of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZeroNavScope>();
    assert(
      scope != null,
      'ZeroNav.of() must be called below a ZeroRouter. '
      'ZeroNav.of() 必须在 ZeroRouter 之下调用。',
    );
    return ZeroNav._(scope!.delegate);
  }

  /// Read the nav if available, else `null`. / 可用则读取，否则返回 `null`。
  static ZeroNav? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZeroNavScope>();
    return scope == null ? null : ZeroNav._(scope.delegate);
  }

  /// The current location. / 当前 location。
  String get location => _delegate.location;

  /// A listenable location for reactive UI.
  /// 供响应式 UI 监听的 location。
  ///
  /// ```dart
  /// ValueListenableBuilder<String>(
  ///   valueListenable: ZeroNav.of(context).locationListenable,
  ///   builder: (context, location, child) => Text(location),
  /// )
  /// ```
  ValueListenable<String> get locationListenable =>
      _delegate.locationListenable;

  /// The active tab index. / 当前 tab 下标。
  int get currentTabIndex => _delegate.currentTabIndex;

  /// Switch tabs, optionally resetting the target tab to [initialLocation].
  /// 切换 tab，可用 [initialLocation] 重置目标 tab。
  ///
  /// Mirrors `ZeroShellState.goTab` for imperative callers.
  /// 与 `ZeroShellState.goTab` 等价，供命令式调用方使用。
  void goTab(int index, {String? initialLocation}) =>
      _delegate.goTab(index, initialLocation: initialLocation);

  /// Whether a pop would remove something. / pop 是否会移除某些内容。
  bool get canPop => _delegate.canPop;

  /// Open a location with the adaptive behavior for the current width.
  /// 按当前宽度的自适应行为打开一个 location。
  Future<Object?> open(String location, {Object? arguments}) {
    return _delegate.pushNamed(location, arguments: arguments);
  }

  /// Push a location; the returned future is completed by `pop(result)`.
  /// push 一个 location；返回的 Future 由 `pop(result)` 完成。
  Future<Object?> pushNamed(String location, {Object? arguments}) {
    return _delegate.pushNamed(location, arguments: arguments);
  }

  /// Replace the top entry with a location. / 用 location 替换栈顶条目。
  Future<Object?> pushReplacementNamed(
    String location, {
    Object? result,
    Object? arguments,
  }) {
    return _delegate.pushReplacementNamed(
      location,
      result: result,
      arguments: arguments,
    );
  }

  /// Push a location after removing entries until [predicate] holds.
  /// 移除条目直到 [predicate] 成立后 push 一个 location。
  Future<Object?> pushNamedAndRemoveUntil(
    String location,
    bool Function(ZeroRouteMatch) predicate, {
    Object? arguments,
  }) {
    return _delegate.pushNamedAndRemoveUntil(
      location,
      predicate,
      arguments: arguments,
    );
  }

  /// Pop the current entry and push a location.
  /// pop 当前条目并 push 一个 location。
  Future<Object?> popAndPushNamed(
    String location, {
    Object? result,
    Object? arguments,
  }) {
    return _delegate.popAndPushNamed(
      location,
      result: result,
      arguments: arguments,
    );
  }

  /// Pop the top entry, completing its push future with [result].
  /// pop 栈顶条目，以 [result] 完成其 push Future。
  void pop([Object? result]) => _delegate.pop(result);

  /// Consult the top page's `PopScope`, then the route's `onExit`, then pop.
  /// 先问顶层页面 `PopScope`，再问路由 `onExit`，最后 pop。
  Future<bool> maybePop([Object? result]) => _delegate.maybePop(result);

  /// Pop within the layer that encloses [context]. / 在包裹 [context] 的层内 pop。
  void popFrom(BuildContext context, [Object? result]) =>
      _delegate.popFrom(context, result);

  /// [maybePop] within the layer that encloses [context].
  /// 限定在包裹 [context] 的层内的 [maybePop]。
  Future<bool> maybePopFrom(BuildContext context, [Object? result]) =>
      _delegate.maybePopFrom(context, result);

  /// Pop entries until [predicate] holds for the top entry.
  /// 持续 pop 直到栈顶条目满足 [predicate]。
  void popUntil(bool Function(ZeroRouteMatch) predicate) =>
      _delegate.popUntil(predicate);

  /// Build a location from a named route, or `null` when the name is unknown.
  /// 由命名路由构建 location；名称未知时返回 `null`。
  String? namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    return _delegate.namedLocation(
      name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
    );
  }

  /// Re-run redirects for the current location (e.g. after an auth change).
  /// 对当前 location 重跑重定向（例如登录态变化后）。
  Future<void> refresh() => _delegate.refresh();
}
