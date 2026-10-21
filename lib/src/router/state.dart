import 'package:flutter/widgets.dart';
import 'package:zero_adaptive_link/src/router/router.dart';

/// The state of a matched route, available to page builders via
/// `ZeroRouteState.of(context)`.
/// 已匹配路由的状态，页面 builder 通过 `ZeroRouteState.of(context)` 获取。
///
/// Evaluated once at match time and free of `BuildContext`, so route titles can
/// be resolved without a widget tree.
/// 在 match 时求值一次且不依赖 `BuildContext`，因此路由标题无需组件树即可解析。
class ZeroRouteState {
  /// Create the immutable state of one route match.
  /// 创建一次路由匹配的不可变状态。
  ///
  /// Not `const`: every state carries a stable [pageKey] (see below), which
  /// cannot be a constant expression.
  /// 非 `const`：每个状态都携带稳定的 [pageKey]（见下），它不是常量表达式。
  ZeroRouteState({
    required this.fullPath,
    required this.location,
    this.route,
    this.pathParameters = const <String, String>{},
    this.queryParameters = const <String, String>{},
    this.arguments,
    this.data,
  }) : pageKey = GlobalKey(debugLabel: 'ZeroRoutePage:$location');

  /// Data resolved by a route's `loader`, or `null` before it resolves / when
  /// the route has no loader. Page builders read it to avoid their own
  /// `FutureBuilder`. / 由路由 `loader` 解析得到的数据；loader 未解析或路由
  /// 无 loader 时为 `null`。页面 builder 读取它即可省去自己的 `FutureBuilder`。
  final Object? data;

  /// Returns a copy with [data] replaced (the handoff [pageKey] is preserved so
  /// the breakpoint handoff still works after the loader resolves).
  /// 返回把 [data] 替换后的副本（交接用 [pageKey] 保持不变，loader 解析后
  /// 跨断点交接仍正常工作）。
  ZeroRouteState copyWith({Object? data}) => ZeroRouteState(
    fullPath: fullPath,
    location: location,
    route: route,
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    arguments: arguments,
    data: data,
  );

  /// The full route pattern that matched (e.g. `/products/:id`).
  /// 匹配到的完整路由 pattern（例如 `/products/:id`）。
  final String fullPath;

  /// The actual location (e.g. `/products/42?tab=specs`).
  /// 实际 location（例如 `/products/42?tab=specs`）。
  final String location;

  /// The matched route definition, `null` for router-level redirects.
  /// 匹配到的路由定义；路由级重定向时为 `null`。
  final ZeroRoute? route;

  /// Extracted path parameters (e.g. `{'id': '42'}`).
  /// 提取出的路径参数（例如 `{'id': '42'}`）。
  final Map<String, String> pathParameters;

  /// Extracted query parameters. / 提取出的查询参数。
  final Map<String, String> queryParameters;

  /// Extra arguments passed at navigation time. / 导航时传入的额外参数。
  final Object? arguments;

  /// A stable key for this page's content. / 该页面内容的稳定键。
  ///
  /// The plugin keys the content of every page — branch pages on compact /
  /// medium and panes on expanded alike — with this key, so the **same
  /// subtree is handed over in the same frame** when the window width crosses
  /// a breakpoint: scroll offsets, text input and other element state survive
  /// instead of resetting. Applications may read it to key their own content
  /// the same way.
  /// 插件以该键标记每个页面的内容——compact / medium 的 branch 页面与
  /// expanded 的 pane 一视同仁——从而在窗口宽度跨越断点时于**同帧**交接
  /// **同一子树**：滚动偏移、文本输入等元素状态得以保留而非重置。应用也可
  /// 读取它为自己的内容加同样的键。
  final GlobalKey pageKey;

  /// The location as a [Uri] (query included). / 带 query 的 [Uri] 形式 location。
  Uri get uri => Uri.parse(location);

  /// Read the state of the route that is currently building this context.
  /// 读取当前构建该 context 的路由状态。
  static ZeroRouteState of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ZeroRouteStateScope>();
    assert(
      scope != null,
      'ZeroRouteState.of() must be called inside a matched route page. '
      'ZeroRouteState.of() 必须在已匹配的路由页面内调用。',
    );
    return scope!.state;
  }

  /// Read the route state if available, else `null`.
  /// 若可用则读取路由状态，否则返回 `null`。
  static ZeroRouteState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ZeroRouteStateScope>()
        ?.state;
  }
}

/// Inherited widget publishing the route state to a page subtree.
/// 向页面子树发布路由状态的 InheritedWidget。
class ZeroRouteStateScope extends InheritedWidget {
  /// Create the scope. / 创建该 scope。
  const ZeroRouteStateScope({
    required this.state,
    required super.child,
    super.key,
  });

  /// The published route state. / 被发布的路由状态。
  final ZeroRouteState state;

  @override
  bool updateShouldNotify(ZeroRouteStateScope oldWidget) =>
      state != oldWidget.state;
}

/// Signature for `ZeroShellState.goTab`.
/// `ZeroShellState.goTab` 的签名。
typedef ZeroGoTabCallback = void Function(int index, {String? initialLocation});

/// The live state of the shell, handed to the shell builder and readable from
/// anywhere via `ZeroShellScope.maybeOf(context)`.
/// shell 的实时状态，传给 shell builder，也可通过
/// `ZeroShellScope.maybeOf(context)` 在任意位置读取。
class ZeroShellState {
  /// Create the shell state. / 创建 shell 状态。
  const ZeroShellState({
    required this.currentIndex,
    required this.isCompact,
    required this.isMedium,
    required this.isExpanded,
    required this.goTab,
    this.leftPaneFraction = 0.4,
  });

  /// The active tab index. / 当前 tab 下标。
  final int currentIndex;

  /// Whether the window is compact (`< 600`). / 窗口是否为 compact（`< 600`）。
  final bool isCompact;

  /// Whether the window is medium (`600 – 839`). / 窗口是否为 medium（`600 – 839`）。
  final bool isMedium;

  /// Whether the window is expanded (`>= 840`). / 窗口是否为 expanded（`>= 840`）。
  final bool isExpanded;

  /// Switch tabs, optionally resetting the target tab to [initialLocation].
  /// 切换 tab，可用 [initialLocation] 重置目标 tab。
  final ZeroGoTabCallback goTab;

  /// Fraction of the pane area taken by the master pane. / master pane 占比。
  final double leftPaneFraction;
}

/// Inherited widget publishing the [ZeroShellState] to the shell subtree.
/// 向 shell 子树发布 [ZeroShellState] 的 InheritedWidget。
class ZeroShellScope extends InheritedWidget {
  /// Create the scope. / 创建该 scope。
  const ZeroShellScope({required this.state, required super.child, super.key});

  /// The published shell state. / 被发布的 shell 状态。
  final ZeroShellState state;

  /// Read the shell state; throws when no shell is above this context.
  /// 读取 shell 状态；上方无 shell 时抛出异常。
  static ZeroShellState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ZeroShellScope>();
    assert(
      scope != null,
      'ZeroShellScope.of() must be called below a ZeroShell. '
      'ZeroShellScope.of() 必须在 ZeroShell 之下调用。',
    );
    return scope!.state;
  }

  /// Read the shell state if available, else `null`.
  /// 若可用则读取 shell 状态，否则返回 `null`。
  static ZeroShellState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ZeroShellScope>()?.state;
  }

  @override
  bool updateShouldNotify(ZeroShellScope oldWidget) =>
      state.currentIndex != oldWidget.state.currentIndex ||
      state.isCompact != oldWidget.state.isCompact ||
      state.isMedium != oldWidget.state.isMedium ||
      state.isExpanded != oldWidget.state.isExpanded ||
      state.leftPaneFraction != oldWidget.state.leftPaneFraction;
}

/// Inherited widget publishing the title of the pane that is currently
/// building. Non-null only inside the two-column (master-detail) panes; used
/// for breadcrumb labels.
/// 发布当前构建中 pane 标题的 InheritedWidget。仅在双列（master-detail）pane
/// 内非空；用于面包屑标签。
class ZeroPaneScope extends InheritedWidget {
  /// Create the scope with the pane [title] (`null` outside panes).
  /// 以 pane [title] 创建该 scope（pane 之外为 `null`）。
  const ZeroPaneScope({required this.title, required super.child, super.key});

  /// The pane title, `null` outside two-column panes.
  /// pane 标题，双列 pane 之外为 `null`。
  final String? title;

  /// Read the pane scope if inside a two-column pane, else `null`.
  /// 若处于双列 pane 内则读取该 scope，否则返回 `null`。
  static ZeroPaneScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ZeroPaneScope>();
  }

  @override
  bool updateShouldNotify(ZeroPaneScope oldWidget) => title != oldWidget.title;
}
