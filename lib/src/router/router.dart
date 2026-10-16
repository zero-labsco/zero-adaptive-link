import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:zero_adaptive_link/src/layout/breakpoints.dart';
import 'package:zero_adaptive_link/src/layout/sliding_panes.dart';
import 'package:zero_adaptive_link/src/router/delegate.dart';
import 'package:zero_adaptive_link/src/router/match.dart';
import 'package:zero_adaptive_link/src/router/parser.dart';
import 'package:zero_adaptive_link/src/router/route_information_provider.dart';
import 'package:zero_adaptive_link/src/router/state.dart';

/// Builds the page content of a matched route.
/// 构建已匹配路由的页面内容。
typedef ZeroRouteBuilder =
    Widget Function(BuildContext context, ZeroRouteState state);

/// Computes a route title once, at match time, without a `BuildContext`.
/// 在 match 时求值一次、不依赖 `BuildContext` 的路由标题。
typedef ZeroTitleBuilder = String Function(ZeroRouteState state);

/// Route-level redirect: return a new location to redirect to, or `null` to
/// continue matching.
/// 路由级重定向：返回新 location 进行重定向，返回 `null` 继续匹配。
typedef ZeroRouteRedirect = FutureOr<String?> Function(ZeroRouteState state);

/// Router-level redirect: return a new location to redirect to, or `null` to
/// continue matching.
/// 路由级重定向：返回新 location 进行重定向，返回 `null` 继续匹配。
typedef ZeroRouterRedirect = FutureOr<String?> Function(String location);

/// Exit hook consulted before a route may be popped. Return `false` to veto.
/// pop 前被询问的退出钩子，返回 `false` 表示阻止。
typedef ZeroExitHook = FutureOr<bool> Function();

/// Renders the shell layout. [child] is the branch content (a Navigator on
/// compact / medium, the pane viewport on expanded).
/// 渲染 shell 布局。[child] 为 branch 内容（compact / medium 为 Navigator，
/// expanded 为 pane 视口）。
typedef ZeroShellBuilder =
    Widget Function(BuildContext context, ZeroShellState shell, Widget child);

/// Default breadcrumb bar: an `InkWell + Text` row over the match stack.
/// 默认面包屑栏：匹配栈上的 `InkWell + Text` 行。
typedef ZeroBreadcrumbsBuilder =
    Widget Function(BuildContext context, List<ZeroRouteMatch> matches);

/// One entry of the route table. Every screen must be in the table so its URL
/// can express it — that is why there is no non-named `push(Route)`.
/// 路由表的一条记录。每个页面都必须入表，URL 才能表达它——因此没有非命名的
/// `push(Route)`。
class ZeroRoute {
  /// Create a route entry. / 创建一条路由记录。
  const ZeroRoute({
    required this.path,
    this.name,
    this.builder,
    this.title,
    this.redirect,
    this.onExit,
    this.fullscreen = false,
    this.fullscreenDialog = false,
    this.hidesBottomBarWhenPushed = true,
    this.opaque = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.transitionsBuilder,
    this.routes = const <ZeroRoute>[],
  });

  /// Path pattern relative to the parent (e.g. `/products`, `:id`).
  /// 相对父路径的 pattern（例如 `/products`、`:id`）。
  final String path;

  /// Optional name for `namedLocation(...)`. / 可选名称，用于 `namedLocation(...)`。
  final String? name;

  /// Page content builder. / 页面内容构建器。
  final ZeroRouteBuilder? builder;

  /// Title evaluated once at match time (breadcrumbs, pane headers).
  /// match 时求值一次的标题（面包屑、pane 头部）。
  final ZeroTitleBuilder? title;

  /// Redirect consulted when this route matches. / 该路由匹配时询问的重定向。
  final ZeroRouteRedirect? redirect;

  /// Exit hook consulted before this route may be popped.
  /// 该路由被 pop 前询问的退出钩子。
  final ZeroExitHook? onExit;

  /// Cover the whole shell (including its chrome) at any width.
  /// 在任何宽度下覆盖整个 shell（含其 chrome）。
  final bool fullscreen;

  /// Present as a full-screen dialog (close affordance instead of back).
  /// 以全屏对话框形式呈现（关闭手势而非返回）。
  final bool fullscreenDialog;

  /// Hide the compact bottom bar when this route is pushed on a branch root.
  /// 该路由被 push 到 branch root 之上时隐藏 compact 底部栏。
  final bool hidesBottomBarWhenPushed;

  /// Whether the route is opaque. / 该路由是否不透明。
  final bool opaque;

  /// Modal barrier color. / 模态屏障颜色。
  final Color? barrierColor;

  /// Whether tapping the barrier dismisses the route. / 点击屏障是否关闭该路由。
  final bool barrierDismissible;

  /// Custom page transitions. / 自定义页面转场。
  final RouteTransitionsBuilder? transitionsBuilder;

  /// Nested routes, matched relative to this route's path.
  /// 嵌套路由，相对该路由路径匹配。
  final List<ZeroRoute> routes;
}

/// One branch (tab) of the shell. / shell 的一个 branch（tab）。
class ZeroTab {
  /// Create a tab with its route table. / 以路由表创建 tab。
  ///
  /// [routes] must be non-empty: an empty tab has no default location to fall
  /// back to. The check lives in [ZeroRouterDelegate] because a `const`
  /// constructor's initializer list cannot call `routes.isNotEmpty` (instance
  /// getters are not constant expressions).
  /// [routes] 不能为空：空 tab 没有可回退的默认 location。该校验放在
  /// [ZeroRouterDelegate]，因为 `const` 构造函数的初始化列表无法调用
  /// `routes.isNotEmpty`（实例 getter 不是常量表达式）。
  const ZeroTab({required this.routes, this.initialLocation, this.placeholder});

  /// The route table of this tab. / 该 tab 的路由表。
  final List<ZeroRoute> routes;

  /// Location used when switching to this tab without an explicit one.
  /// 切换到该 tab 且未显式指定时使用的 location。
  final String? initialLocation;

  /// Placeholder for the empty right pane; takes priority over the shell's.
  /// 空右 pane 的占位内容，优先于 shell 级占位内容。
  ///
  /// Keep it free of a `Key`: the layout tells an expand / collapse
  /// (placeholder ↔ detail) from a plain rebuild by the second pane's key.
  /// 请勿为其设置 `Key`：布局通过第二个 pane 的键区分展开 / 收起
  /// （占位内容 ↔ 详情）与普通重建。
  final Widget? placeholder;
}

/// The single top-level shell. Exactly one shell is supported in v0.1.0.
/// 唯一的顶层 shell。v0.1.0 仅支持一个 shell。
class ZeroShell {
  /// Create the shell. / 创建 shell。
  ///
  /// [tabs] must be non-empty; the check runs in [ZeroRouterDelegate] (a
  /// `const` initializer list cannot evaluate `tabs.isNotEmpty`).
  /// [tabs] 不能为空；该校验在 [ZeroRouterDelegate] 中执行（`const` 初始化
  /// 列表无法求值 `tabs.isNotEmpty`）。
  const ZeroShell({
    required this.builder,
    required this.tabs,
    this.placeholder,
  });

  /// Builds the shell layout around [child]. / 围绕 [child] 构建 shell 布局。
  final ZeroShellBuilder builder;

  /// The shell's tabs. / shell 的 tab 列表。
  final List<ZeroTab> tabs;

  /// Shell-level placeholder for the empty right pane.
  /// shell 级空右 pane 占位内容。
  ///
  /// Keep it free of a `Key`: the layout tells an expand / collapse
  /// (placeholder ↔ detail) from a plain rebuild by the second pane's key.
  /// 请勿为其设置 `Key`：布局通过第二个 pane 的键区分展开 / 收起
  /// （占位内容 ↔ 详情）与普通重建。
  final Widget? placeholder;
}

/// The router configuration handed to `MaterialApp.router(routerConfig: ...)`.
/// 传给 `MaterialApp.router(routerConfig: ...)` 的路由配置。
///
/// One `onTap` behaves correctly at every width: compact / medium push a new
/// page, expanded expands or updates the right sidebar pane.
/// 同一套 `onTap` 在任意宽度下都做出正确行为：compact / medium push 新页面，
/// expanded 展开或更新右侧侧栏 pane。
class ZeroRouter extends RouterConfig<String> {
  /// Create the router. / 创建路由。
  ZeroRouter({
    required List<ZeroShell> routes,
    this.initialLocation = '/',
    this.redirect,
    this.redirectLimit = 5,
    this.errorBuilder,
    this.breakpoints = const Breakpoints(),
    this.slideDuration = const Duration(milliseconds: 280),
    this.slideCurve = Curves.easeOutCubic,
    this.paneBuilder,
    this.paneSide = SlidingPanesSide.right,
    this.paneSideListenable,
    this.leftPaneFraction = 0.4,
    this.maxLeftPaneWidth,
    this.resizeHandleBuilder,
    this.resizeHandleWidth = 4,
    this.placeholder,
    this.showBreadcrumbs = true,
    this.escapePops = true,
    this.breadcrumbsBuilder,
    RouteInformationProvider? routeInformationProvider,
    RouteInformationParser<String>? routeInformationParser,
  }) : _providedRouteInformationProvider = routeInformationProvider,
       _providedRouteInformationParser = routeInformationParser,
       super(
         routerDelegate: ZeroRouterDelegate(
           routes: routes,
           initialLocation: initialLocation,
           redirect: redirect,
           redirectLimit: redirectLimit,
           errorBuilder: errorBuilder,
           breakpoints: breakpoints,
           slideDuration: slideDuration,
           slideCurve: slideCurve,
           paneBuilder: paneBuilder,
           paneSide: paneSideListenable?.value ?? paneSide,
           paneSideListenable: paneSideListenable,
           initialLeftPaneFraction: leftPaneFraction,
           maxLeftPaneWidth: maxLeftPaneWidth,
           resizeHandleBuilder: resizeHandleBuilder,
           resizeHandleWidth: resizeHandleWidth,
           placeholder: placeholder,
           showBreadcrumbs: showBreadcrumbs,
           escapePops: escapePops,
           breadcrumbsBuilder: breadcrumbsBuilder,
         ),
         backButtonDispatcher: RootBackButtonDispatcher(),
       );

  final RouteInformationProvider? _providedRouteInformationProvider;
  final RouteInformationParser<String>? _providedRouteInformationParser;
  RouteInformationProvider? _lazyRouteInformationProvider;
  RouteInformationParser<String>? _lazyRouteInformationParser;

  /// Web defaults to the hash strategy (`/#/products/42`) so GitHub Pages
  /// needs no 404 fallback; native uses the platform provider. Created lazily
  /// so constructing a `ZeroRouter` never touches `WidgetsBinding`.
  /// Web 默认 hash 策略（`/#/products/42`），GitHub Pages 无需 404 fallback；
  /// 原生平台使用平台 provider。惰性创建，使构造 `ZeroRouter` 不触碰
  /// `WidgetsBinding`。
  @override
  RouteInformationProvider? get routeInformationProvider {
    return _providedRouteInformationProvider ??
        (_lazyRouteInformationProvider ??= createZeroRouteInformationProvider(
          initialLocation,
        ));
  }

  @override
  RouteInformationParser<String>? get routeInformationParser {
    return _providedRouteInformationParser ??
        (_lazyRouteInformationParser ??= const ZeroRouteInformationParser());
  }

  /// The location used when the platform has no initial route (`/` or empty).
  /// 平台无初始 route（`/` 或空）时使用的 location。
  final String initialLocation;

  /// Router-level redirect, consulted for every location.
  /// 路由级重定向，对每个 location 生效。
  final ZeroRouterRedirect? redirect;

  /// Maximum redirect hops before [errorBuilder] takes over (default 5).
  /// 进入 [errorBuilder] 前允许的最大重定向跳数（默认 5）。
  final int redirectLimit;

  /// Rendered when no route matches or the redirect limit is exceeded.
  /// 无路由匹配或重定向超限时渲染的内容。
  final ZeroErrorBuilder? errorBuilder;

  /// Window-width breakpoints. / 窗口宽度断点。
  final Breakpoints breakpoints;

  /// Pane slide duration. / pane 滑动时长。
  final Duration slideDuration;

  /// Pane slide curve. / pane 滑动曲线。
  final Curve slideCurve;

  /// Wraps each pane. / 包裹每个 pane。
  ///
  /// Caveat: panes are clipped to their column, so a dropdown menu, tooltip
  /// or dialog opened from inside a pane is clipped too unless it uses the
  /// root navigator (`useRootNavigator: ZeroPaneScope.maybeOf(context) != null`).
  /// 注意：pane 会被裁剪到其列内，因此从 pane 内部打开的下拉菜单、tooltip 或
  /// 对话框同样会被裁剪，除非使用 root navigator
  /// （`useRootNavigator: ZeroPaneScope.maybeOf(context) != null`）。
  final SlidingPaneBuilder? paneBuilder;

  /// Which side the detail pane expands toward when the layout is expanded.
  /// 展开时 detail pane 朝向的一侧。
  ///
  /// Defaults to [SlidingPanesSide.right] (master on the left).
  /// 默认 [SlidingPanesSide.right]（master 在左）。
  final SlidingPanesSide paneSide;

  /// Optional listenable that flips [paneSide] at runtime without rebuilding the
  /// router (e.g. a "expand left / right" toggle).
  /// 可选的监听对象，在运行时切换 [paneSide] 而无需重建路由（如「向左 / 向右
  /// 展开」开关）。
  final ValueListenable<SlidingPanesSide>? paneSideListenable;

  /// Initial fraction of the pane area taken by the master pane (0.15 – 0.85).
  /// master pane 初始占用的 pane 区域比例（0.15 – 0.85）。
  ///
  /// The user can still drag the resize handle to change it at runtime.
  /// 用户仍可在运行时拖拽分割线改变它。
  final double leftPaneFraction;

  /// Optional pixel ceiling for the master pane. The pane still scales with
  /// [leftPaneFraction], but never grows past this width, so on an ultra-wide
  /// window the detail pane absorbs the remainder instead of both columns
  /// stretching. `null` (the default) means no ceiling.
  /// master pane 的可选像素上限。pane 仍按 [leftPaneFraction] 缩放，但绝不超过
  /// 该宽度——超宽窗口上由 detail pane 吸收剩余空间，而不是两栏一起被拉宽。
  /// `null`（默认）表示不设上限。
  final double? maxLeftPaneWidth;

  /// Builds the pane resize handle. / 构建 pane 分割线。
  final SlidingResizeHandleBuilder? resizeHandleBuilder;

  /// Hit width of the pane resize handle. / pane 分割线命中宽度。
  final double resizeHandleWidth;

  /// Shell-level placeholder for the empty right pane.
  /// shell 级空右 pane 占位内容。
  final Widget? placeholder;

  /// Master switch for the breadcrumb bar. / 面包屑栏总开关。
  final bool showBreadcrumbs;

  /// Whether the Escape key pops one level. / Escape 键是否退一级。
  final bool escapePops;

  /// Custom breadcrumb bar. / 自定义面包屑栏。
  final ZeroBreadcrumbsBuilder? breadcrumbsBuilder;
}

/// Renders the error page for an unmatched location.
/// 渲染未匹配 location 的错误页。
typedef ZeroErrorBuilder =
    Widget Function(BuildContext context, String location);
