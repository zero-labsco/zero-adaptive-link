import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zero_adaptive_link/src/layout/breadcrumbs.dart';
import 'package:zero_adaptive_link/src/layout/breakpoints.dart';
import 'package:zero_adaptive_link/src/layout/sliding_panes.dart';
import 'package:zero_adaptive_link/src/nav/zero_nav.dart';
import 'package:zero_adaptive_link/src/router/match.dart';
import 'package:zero_adaptive_link/src/router/router.dart';
import 'package:zero_adaptive_link/src/router/state.dart';
import 'package:zero_adaptive_link/src/shell/shell.dart';

/// The resolved outcome of a location: which tab owns it and the match stack.
/// 一个 location 的解析结果：归属 tab 与匹配栈。
class _Resolution {
  _Resolution({required this.tabIndex, required this.matchList});

  final int tabIndex;
  final MatchList matchList;
}

/// Route display configuration captured from a [ZeroRoute].
/// 从 [ZeroRoute] 提取的路由显示配置。
class _RouteConfig {
  const _RouteConfig({
    this.opaque = true,
    this.barrierColor,
    this.barrierDismissible = false,
    this.fullscreenDialog = false,
    this.transitionsBuilder,
  });

  final bool opaque;
  final Color? barrierColor;
  final bool barrierDismissible;
  final bool fullscreenDialog;
  final RouteTransitionsBuilder? transitionsBuilder;
}

/// One entry of a page stack: the match, its page and the completer that
/// finishes `pushNamed`'s future when the entry is popped.
/// 页面栈的一项：匹配、其 Page 以及该项被 pop 时完成 `pushNamed` Future 的
/// completer。
class _StackEntry {
  _StackEntry({
    required this.match,
    required this.completer,
    required this.isOverlay,
    required this.isRoot,
  });

  final ZeroRouteMatch match;
  final Completer<Object?> completer;
  final bool isOverlay;

  /// Whether this entry is the root page of a branch navigator (the only page
  /// that shows the compact bottom chrome).
  /// 是否为 branch navigator 的根页面（唯一显示 compact 底部 chrome 的页面）。
  final bool isRoot;

  late final Page<Object?> page;
}

/// The intent backing the Escape key. / Escape 键对应的 Intent。
class _EscapeIntent extends Intent {
  const _EscapeIntent();
}

/// Counts the framework routes (dialogs, bottom sheets, imperative pushes)
/// living on the root navigator. Those routes sit **above** the shell route
/// (and above any fullscreen overlay page), so a back request must pop them
/// before any of our own pages — the branch navigator below the shell cannot
/// see them, and consulting it first would pop the page beneath the dialog.
/// 统计挂在 root navigator 上的框架级路由（dialog、bottom sheet、命令式 push）。
/// 这些路由位于 shell route（及 fullscreen 覆盖页）**之上**，因此返回请求必须
/// 先于我们自己的页面 pop 它们——shell 之下的 branch navigator 看不到它们，
/// 先询问它会把对话框下方的页面 pop 掉。
class _ImperativeRouteCounter extends NavigatorObserver {
  /// How many framework routes are currently on the observed navigator.
  /// 当前被观察 navigator 上的框架级路由数量。
  int count = 0;

  /// Whether a framework route is the topmost route.
  /// 框架级路由是否为栈顶路由。
  bool get hasImperativeRoute => count > 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! Page<Object?>) {
      count++;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! Page<Object?>) {
      count--;
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings is! Page<Object?>) {
      count--;
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings is! Page<Object?>) {
      count++;
    }
    if (oldRoute?.settings is! Page<Object?>) {
      count--;
    }
  }
}

/// A [Page] rendering one matched route.
/// 渲染一个已匹配路由的 [Page]。
class _ZeroPage extends Page<Object?> {
  _ZeroPage({
    required this.entry,
    required this.delegate,
    required void Function(Object? result) onPopResult,
    super.key,
  }) : super(
         canPop: true,
         onPopInvoked: (didPop, result) {
           if (didPop) {
             onPopResult(result);
           }
         },
       );

  final _StackEntry entry;
  final ZeroRouterDelegate delegate;

  @override
  Route<Object?> createRoute(BuildContext context) {
    return _ZeroPageRoute<Object?>(
      page: this,
      builder: (context) => delegate._buildPageContent(
        context,
        entry,
        isBranchRoot: entry.isRoot,
        stack: delegate._stackContaining(entry),
      ),
      config: _RouteConfig(
        opaque: entry.match.route.opaque,
        barrierColor: entry.match.route.barrierColor,
        barrierDismissible: entry.match.route.barrierDismissible,
        fullscreenDialog: entry.match.route.fullscreenDialog,
        transitionsBuilder: entry.match.route.transitionsBuilder,
      ),
    );
  }
}

/// The route of one matched page. Default transitions come from
/// `ThemeData.pageTransitionsTheme`; a route's `transitionsBuilder` overrides
/// them.
/// 一个已匹配页面的 route。默认转场来自 `ThemeData.pageTransitionsTheme`；
/// 路由自带的 `transitionsBuilder` 可覆盖之。
class _ZeroPageRoute<T> extends PageRoute<T>
    with MaterialRouteTransitionMixin<T> {
  // ignore: prefer_const_constructors_in_immutables
  _ZeroPageRoute({
    required _ZeroPage page,
    required this.builder,
    required this.config,
  }) : super(
         settings: page,
         // `fullscreenDialog` and `barrierDismissible` MUST reach `PageRoute`
         // here: both are stored in private final fields there, so a getter
         // override cannot supply them and the defaults (`false`) would
         // silently win.
         // `fullscreenDialog` 与 `barrierDismissible` 必须在此传给
         // `PageRoute`：二者在父类中是私有 final 字段，getter 覆写无法提供，
         // 否则默认值 `false` 会静默生效。
         fullscreenDialog: config.fullscreenDialog,
         barrierDismissible: config.barrierDismissible,
       );

  final WidgetBuilder builder;
  final _RouteConfig config;

  @override
  final bool maintainState = true;

  @override
  bool get opaque => config.opaque;

  @override
  Color? get barrierColor => config.barrierColor;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitions = config.transitionsBuilder;
    if (transitions != null) {
      return transitions(context, animation, secondaryAnimation, child);
    }
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// The shell page: always the bottom route of the root navigator.
/// shell 页面：始终是根 navigator 的底部 route。
class _ShellPage extends Page<Object?> {
  // ignore: prefer_const_constructors_in_immutables
  _ShellPage({required this.delegate});

  final ZeroRouterDelegate delegate;

  @override
  Route<Object?> createRoute(BuildContext context) {
    return _ShellRoute(
      page: this,
      builder: (context) => delegate.buildShellContent(context),
    );
  }
}

class _ShellRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  // ignore: prefer_const_constructors_in_immutables
  _ShellRoute({required _ShellPage page, required this.builder})
    : super(settings: page);

  final WidgetBuilder builder;

  @override
  final bool maintainState = true;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return buildContent(context);
  }
}

/// The router delegate: owns the per-tab page stacks, the fullscreen overlay
/// stack and the current location.
/// 路由 delegate：持有各 tab 的页面栈、fullscreen 覆盖栈与当前 location。
///
/// Widget structure:
/// 组件结构：
///
/// ```text
/// Root Navigator (pages: [shell page, ...fullscreen overlay pages])
///   └─ Shell page route
///        └─ ZeroShellScope → shell.builder(child: …)
///             ├─ compact / medium: per-tab Navigator (pages from tab stack)
///             └─ expanded:         SlidingPanes over the last two matches
/// ```
class ZeroRouterDelegate extends RouterDelegate<String> with ChangeNotifier {
  /// Create the delegate for the given routes. / 为给定路由创建 delegate。
  ZeroRouterDelegate({
    required List<ZeroShell> routes,
    required this.initialLocation,
    required this.redirect,
    required this.redirectLimit,
    required this.errorBuilder,
    required this.breakpoints,
    required this.slideDuration,
    required this.slideCurve,
    required this.paneBuilder,
    required SlidingPanesSide paneSide,
    this.paneSideListenable,
    this.initialLeftPaneFraction = 0.4,
    this.maxLeftPaneWidth,
    required this.resizeHandleBuilder,
    required this.resizeHandleWidth,
    required this.placeholder,
    required this.showBreadcrumbs,
    required this.escapePops,
    required this.breadcrumbsBuilder,
    required this.showBreadcrumbsOnBranch,
    required this.restoreScrollOffset,
    required this.restoreFocus,
    required this.onNavigation,
  }) : _paneSide = paneSide,
       _leftPaneFraction = initialLeftPaneFraction {
    assert(routes.isNotEmpty, 'At least one ZeroShell is required.');
    assert(
      routes.length == 1,
      'Exactly one ZeroShell is supported in 0.x; received ${routes.length}. '
      'Extra shells are silently ignored otherwise — pass one. '
      '0.x 仅支持一个 ZeroShell；收到了 ${routes.length} 个。多出的 shell '
      '会被静默忽略——请只传一个。',
    );
    // Assigned here (not in the initializer list) so the asserts above fire
    // first: `routes.first` in the initializer list threw a bare
    // `StateError: No element` before the friendly assert could run.
    // 在此赋值（而非初始化列表），让上面的断言先执行：在初始化列表里写
    // `routes.first` 会在友好断言之前抛出裸 `StateError: No element`。
    _shell = routes.first;
    assert(
      _shell.tabs.isNotEmpty,
      'A ZeroShell needs at least one ZeroTab. '
      'ZeroShell 至少需要一个 ZeroTab。',
    );
    // A listenable side flips the expanded layout at runtime (no rebuild).
    // 可监听的 side 在运行时切换展开方向（无需重建路由）。
    //
    // The constructor also has a `paneSide` parameter, which shadows the
    // instance setter of the same name — so the closure MUST use `this.paneSide`
    // to reach the setter. Assigning to the bare `paneSide` would only write to
    // the parameter and never update `_paneSide` (the bug that made the example
    // "Expand left / right" toggle do nothing).
    // 构造函数也有一个同名的 `paneSide` 形参，会遮蔽实例 setter——因此闭包必须
    // 用 `this.paneSide` 才能命中 setter。若直接写 `paneSide` 只会赋值给形参，
    // `_paneSide` 永远不更新（这正是示例里 Expand 左右点击没反应的 bug）。
    final listenable = paneSideListenable;
    if (listenable != null) {
      _paneSideListener = () => this.paneSide = listenable.value;
      listenable.addListener(_paneSideListener!);
    }
    for (var t = 0; t < _shell.tabs.length; t++) {
      // An empty tab has no default location to fall back to; without this the
      // first `goTab` / deep-link fallback threw a bare
      // `StateError: No element` on `tabs[t].routes.first`.
      // 空 tab 没有可回退的默认 location；没有该断言，首次 `goTab` /
      // 深链回退会在 `tabs[t].routes.first` 上抛出裸
      // `StateError: No element`。
      assert(
        _shell.tabs[t].routes.isNotEmpty,
        'Every ZeroTab needs at least one ZeroRoute — an empty tab has no '
        'default location to fall back to. '
        '每个 ZeroTab 至少需要一条 ZeroRoute——空 tab 没有可回退的默认 '
        'location。',
      );
      _tabStacks.add(<_StackEntry>[]);
      _registerRouteNames(_shell.tabs[t].routes, '/');
    }
    _initSync(initialLocation);
  }

  final String initialLocation;
  final ZeroRouterRedirect? redirect;
  final int redirectLimit;
  final ZeroErrorBuilder? errorBuilder;
  final Breakpoints breakpoints;
  final Duration slideDuration;
  final Curve slideCurve;
  final SlidingPaneBuilder? paneBuilder;
  final SlidingResizeHandleBuilder? resizeHandleBuilder;
  final ValueListenable<SlidingPanesSide>? paneSideListenable;

  /// Initial fraction of the pane area taken by the master pane.
  /// master pane 初始占用的 pane 区域比例。
  final double initialLeftPaneFraction;

  /// Pixel ceiling for the master pane; `null` means no ceiling.
  /// master pane 的像素上限；`null` 表示不设上限。
  final double? maxLeftPaneWidth;
  final double resizeHandleWidth;
  final Widget? placeholder;
  final bool showBreadcrumbs;
  final bool escapePops;
  final ZeroBreadcrumbsBuilder? breadcrumbsBuilder;
  final bool showBreadcrumbsOnBranch;
  final bool restoreScrollOffset;
  final bool restoreFocus;
  final void Function(String location)? onNavigation;

  /// Shared `PageStorage` bucket for scroll restoration across breakpoint
  /// crossings and history changes (one bucket per router).
  /// 用于跨断点与历史变化恢复滚动偏移的共享 `PageStorage` 桶（每个 router 一个）。
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();

  /// The restoration id of the route that last held primary focus, so focus can
  /// return to it after a pop. / 上次持有主焦点的 route 的 restoration id，
  /// 以便 pop 后焦点能回到它。
  String? _focusedRestorationId;

  /// Records the route that currently holds primary focus.
  /// 记录当前持有主焦点的 route。
  void _noteFocus(String id) => _focusedRestorationId = id;

  late final ZeroShell _shell;

  /// The [paneSideListenable] listener, kept so it can be removed in [dispose].
  /// 保存 [paneSideListenable] 的 listener，以便在 [dispose] 中移除。
  VoidCallback? _paneSideListener;
  final List<List<_StackEntry>> _tabStacks = [];
  final List<_StackEntry> _overlayStack = [];
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {};

  /// Per-nested-shell navigator keys, keyed by the host route's location, so a
  /// nested shell keeps its own branch-navigator identity across rebuilds.
  /// 每个嵌套 shell 的 navigator 键，以宿主路由的 location 为键，使嵌套 shell
  /// 在重建间保持自身 branch-navigator 的身份。
  final Map<String, GlobalKey<NavigatorState>> _nestedNavigatorKeys = {};
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// Watches the root navigator for framework routes (dialogs / sheets).
  /// 观察 root navigator 上的框架级路由（dialog / sheet）。
  final _ImperativeRouteCounter _rootRouteCounter = _ImperativeRouteCounter();
  late final List<NavigatorObserver> _rootObservers = <NavigatorObserver>[
    _rootRouteCounter,
  ];

  /// Monotonic navigation sequence: every navigation bumps it before its
  /// asynchronous resolution and drops the result if a newer navigation has
  /// started meanwhile — otherwise a slow (async-redirect) resolution could
  /// land after a newer one and win, leaving the UI on a stale location.
  /// 单调递增的导航序号：每次导航在异步解析前递增它，若期间有更新的导航
  /// 开始则丢弃旧结果——否则慢（异步重定向）的解析可能后落地并胜出，
  /// 让界面停留在过期的 location 上。
  int _navigationGeneration = 0;
  final Map<String, String> _namedRoutes = {};

  int _currentTab = 0;
  String _location = '/';
  double _leftPaneFraction;
  BreakpointClass _widthClass = BreakpointClass.expanded;
  SlidingPanesSide _paneSide = SlidingPanesSide.right;
  ZeroShellState? _shellState;
  final ValueNotifier<String> _locationNotifier = ValueNotifier<String>('/');

  /// Which side the detail pane expands toward. Mutating it rebuilds the
  /// expanded layout (e.g. a runtime "expand left / right" toggle).
  /// detail pane 展开所朝向的一侧。赋值会重建展开布局（如运行时「向左 / 向右
  /// 展开」切换）。
  SlidingPanesSide get paneSide => _paneSide;
  set paneSide(SlidingPanesSide value) {
    if (_paneSide == value) {
      return;
    }
    _paneSide = value;
    notifyListeners();
  }

  /// The current location (path + query). / 当前 location（路径 + query）。
  String get location => _location;

  /// A listenable location for reactive UI (`ValueListenableBuilder`).
  /// 供响应式 UI 监听的 location（配合 `ValueListenableBuilder`）。
  ValueListenable<String> get locationListenable => _locationNotifier;

  /// The active tab index. / 当前 tab 下标。
  int get currentTabIndex => _currentTab;

  /// Whether a pop would remove something (overlay or a non-root page).
  /// pop 是否会移除某些内容（覆盖层或非根页面）。
  bool get canPop =>
      _overlayStack.isNotEmpty || _tabStacks[_currentTab].length > 1;

  List<ZeroTab> get _tabs => _shell.tabs;

  // ---------------------------------------------------------------- init ----

  void _registerRouteNames(List<ZeroRoute> routes, String prefix) {
    for (final route in routes) {
      final fullPath = ZeroRouteMatcher.joinPattern(prefix, route.path);
      final name = route.name;
      if (name != null) {
        assert(
          !_namedRoutes.containsKey(name) || _namedRoutes[name] == fullPath,
          'Duplicate route name "$name": registered for both '
          '${_namedRoutes[name]} and $fullPath. Route names must be unique '
          'across the whole table — the last registration silently wins '
          'otherwise. 重名路由 "$name"：同时注册到 ${_namedRoutes[name]} 与 '
          '$fullPath。路由名必须在整个路由表内唯一，否则后注册者静默生效。',
        );
        _namedRoutes[name] = fullPath;
      }
      _registerRouteNames(route.routes, fullPath);
    }
  }

  /// Synchronous best-effort init so the first build always has a stack; the
  /// full resolution (with redirects) runs via `setInitialRoutePath`.
  /// 同步尽力初始化，保证首次 build 必有栈；完整解析（含重定向）经由
  /// `setInitialRoutePath` 执行。
  void _initSync(String location) {
    final normalized = location.isEmpty ? '/' : location;
    for (var t = 0; t < _tabs.length; t++) {
      final matched = ZeroRouteMatcher.match(_tabs[t].routes, normalized);
      if (matched != null && matched.isNotEmpty) {
        _currentTab = t;
        _setTabStack(t, matched);
        _location = matched.location;
        return;
      }
    }
    _applyError(normalized);
  }

  // ------------------------------------------------------- configuration ----

  @override
  String get currentConfiguration => _location;

  @override
  Future<void> setInitialRoutePath(String configuration) {
    return _navigateTo(configuration, external: true, force: true);
  }

  @override
  Future<void> setNewRoutePath(String configuration) {
    return _navigateTo(configuration, external: true);
  }

  // ------------------------------------------------------------ navigation --

  Future<void> _navigateTo(
    String location, {
    required bool external,
    bool force = false,
    int? forceTab,
  }) async {
    final normalized = location.isEmpty ? '/' : location;
    if (!force && external && normalized == _location) {
      return; // Echo of a location we just published ourselves.
    }
    final generation = ++_navigationGeneration;
    final resolution = await _resolve(normalized, preferredTab: forceTab);
    if (generation != _navigationGeneration) {
      // A newer navigation started while this one was resolving (an async
      // redirect can take a while): drop the stale result so the last
      // requested location always wins.
      // 解析期间有更新的导航开始（异步重定向可能耗时）：丢弃过期结果，
      // 保证最后请求的 location 始终获胜。
      return;
    }
    if (resolution == null) {
      _applyError(normalized);
      return;
    }
    if (external) {
      _applyExternal(resolution);
    } else {
      _applyInternal(resolution);
    }
  }

  Future<_Resolution?> _resolve(
    String location, {
    Object? arguments,
    int? preferredTab,
  }) async {
    var current = location.isEmpty ? '/' : location;
    for (var hop = 0; hop <= redirectLimit; hop++) {
      final routerTarget = redirect == null ? null : await redirect!(current);
      if (routerTarget != null && routerTarget != current) {
        current = routerTarget;
        continue;
      }
      var redirected = false;
      for (var i = 0; i < _tabs.length; i++) {
        final t = preferredTab == null ? i : (preferredTab + i) % _tabs.length;
        final matched = ZeroRouteMatcher.match(
          _tabs[t].routes,
          current,
          arguments: arguments,
        );
        if (matched == null || matched.isEmpty) {
          continue;
        }
        final routeTarget = await _applyRouteRedirects(matched);
        if (routeTarget != null && routeTarget != current) {
          current = routeTarget;
          redirected = true;
          break;
        }
        return _Resolution(tabIndex: t, matchList: matched);
      }
      if (redirected) {
        continue;
      }
      return null; // No tab matched the location.
    }
    return null; // Redirect limit exceeded.
  }

  Future<String?> _applyRouteRedirects(MatchList matched) async {
    for (final match in matched.matches) {
      final hook = match.route.redirect;
      if (hook == null) {
        continue;
      }
      final target = await hook(match.state);
      if (target != null) {
        return target;
      }
    }
    return null;
  }

  void _applyExternal(_Resolution resolution) {
    _applyStacks(resolution.tabIndex, resolution.matchList, replace: true);
    _currentTab = resolution.tabIndex;
    _syncLocation();
    notifyListeners();
  }

  void _applyInternal(_Resolution resolution) {
    final targetLocation = resolution.matchList.location;
    if (targetLocation == _location && resolution.tabIndex == _currentTab) {
      return; // Idempotent: the target is already the current location.
    }
    if (resolution.tabIndex != _currentTab) {
      _applyExternal(resolution);
      return;
    }
    final stack = _tabStacks[_currentTab];

    // Focus an existing entry instead of pushing a duplicate.
    // 已存在的条目：聚焦而非重复 push。
    final existingIndex = stack.indexWhere(
      (entry) => entry.match.location == targetLocation,
    );
    if (existingIndex >= 0) {
      _popStackTo(stack, existingIndex + 1);
      _syncLocation();
      notifyListeners();
      return;
    }

    // Append the new entries beyond the common prefix.
    // 追加公共前缀之后的新条目。
    final common = _commonPrefixLength(stack, resolution.matchList.matches);
    final newMatches = resolution.matchList.matches.sublist(common);
    _applyStacks(_currentTab, MatchList(newMatches), replace: false);
    _syncLocation();
    notifyListeners();
  }

  /// Apply [matchList] to the tab stack and the overlay stack, splitting off a
  /// fullscreen leaf into the overlay.
  /// 将 [matchList] 应用到 tab 栈与覆盖栈，并把 fullscreen 叶子拆到覆盖栈。
  void _applyStacks(
    int tabIndex,
    MatchList matchList, {
    required bool replace,
  }) {
    final matches = matchList.matches;
    if (matches.isEmpty) {
      return;
    }
    final leaf = matches.last;
    final isFullscreen = leaf.route.fullscreen || leaf.route.fullscreenDialog;
    final tabMatches = isFullscreen
        ? matches.sublist(0, matches.length - 1)
        : matches;

    if (replace) {
      _setTabStack(
        tabIndex,
        MatchList(_underlyingMatches(tabIndex, tabMatches)),
      );
      _clearOverlay();
    } else {
      final stack = _tabStacks[tabIndex];
      for (final match in tabMatches) {
        stack.add(_createEntry(match, isRoot: false));
      }
      _clearOverlay();
    }
    if (isFullscreen) {
      _overlayStack.add(_createEntry(leaf, isOverlay: true, isRoot: false));
    }
  }

  /// The tab stack for a resolved location; falls back to the tab's default
  /// route when the leaf was a top-level fullscreen route.
  /// 解析后 location 对应的 tab 栈；当叶子是顶层 fullscreen 路由时回退到该
  /// tab 的默认路由。
  List<ZeroRouteMatch> _underlyingMatches(
    int tabIndex,
    List<ZeroRouteMatch> tabMatches,
  ) {
    if (tabMatches.isNotEmpty) {
      return tabMatches;
    }
    final fallback =
        _tabs[tabIndex].initialLocation ??
        ZeroRouteMatcher.joinPattern('/', _tabs[tabIndex].routes.first.path);
    final matched = ZeroRouteMatcher.match(_tabs[tabIndex].routes, fallback);
    return matched?.matches ?? const <ZeroRouteMatch>[];
  }

  void _applyError(String location) {
    final errorRoute = ZeroRoute(
      path: location,
      builder: (context, state) =>
          errorBuilder?.call(context, location) ??
          _defaultErrorPage(context, location),
    );
    final match = ZeroRouteMatch(
      route: errorRoute,
      state: ZeroRouteState(fullPath: location, location: location),
    );
    _setTabStack(_currentTab, MatchList([match]));
    _clearOverlay();
    _location = location;
    if (_locationNotifier.value != _location) {
      _locationNotifier.value = _location;
    }
    _fireOnNavigation();
    notifyListeners();
  }

  int _commonPrefixLength(
    List<_StackEntry> stack,
    List<ZeroRouteMatch> matches,
  ) {
    var i = 0;
    while (i < stack.length &&
        i < matches.length &&
        stack[i].match.location == matches[i].location) {
      i++;
    }
    return i;
  }

  void _setTabStack(int tabIndex, MatchList matchList) {
    final oldStack = _tabStacks[tabIndex];
    final newStack = <_StackEntry>[];
    for (var i = 0; i < matchList.matches.length; i++) {
      final match = matchList.matches[i];
      _StackEntry? existing;
      for (final entry in oldStack) {
        if (entry.match.location == match.location) {
          existing = entry;
          break;
        }
      }
      newStack.add(existing ?? _createEntry(match, isRoot: i == 0));
    }
    for (final entry in oldStack) {
      final kept = newStack.contains(entry);
      if (!kept && !entry.completer.isCompleted) {
        entry.completer.complete(null);
      }
    }
    _tabStacks[tabIndex] = newStack;
  }

  void _popStackTo(List<_StackEntry> stack, int length) {
    while (stack.length > length && stack.length > 1) {
      final removed = stack.removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(null);
      }
    }
  }

  void _syncLocation() {
    if (_overlayStack.isNotEmpty) {
      _location = _overlayStack.last.match.location;
    } else {
      final stack = _tabStacks[_currentTab];
      _location = stack.isEmpty ? '/' : stack.last.match.location;
    }
    if (_locationNotifier.value != _location) {
      _locationNotifier.value = _location;
    }
    _fireOnNavigation();
  }

  /// Fires [onNavigation] once per distinct location, after the location has
  /// settled (in-app navigation, browser back / forward, deep links, pops).
  /// 每次 location 落定后触发一次 [onNavigation]（应用内导航、浏览器前进后退、
  /// 深链、pop 均涵盖）。
  String? _lastOnNavigationLocation;
  void _fireOnNavigation() {
    final callback = onNavigation;
    if (callback == null) {
      return;
    }
    if (_lastOnNavigationLocation == _location) {
      return;
    }
    _lastOnNavigationLocation = _location;
    callback(_location);
  }

  _StackEntry _createEntry(
    ZeroRouteMatch match, {
    bool isOverlay = false,
    bool isRoot = false,
  }) {
    final completer = Completer<Object?>();
    final entry = _StackEntry(
      match: match,
      completer: completer,
      isOverlay: isOverlay,
      isRoot: isRoot,
    );
    entry.page = _ZeroPage(
      key: ValueKey('${match.location}${isOverlay ? '#overlay' : ''}'),
      entry: entry,
      delegate: this,
      onPopResult: (result) {
        if (!completer.isCompleted) {
          completer.complete(result);
        }
      },
    );
    return entry;
  }

  // ------------------------------------------------------- public verbs ----

  /// Push a location; returns a future completed by `pop(result)`.
  /// push 一个 location；返回由 `pop(result)` 完成的 Future。
  ///
  /// Returns `null` when a newer navigation superseded this one before it
  /// finished resolving.
  /// 若更新的导航在其解析完成前开始，则返回 `null`。
  Future<Object?> pushNamed(
    String location, {
    Object? arguments,
    int? preferredTab,
  }) async {
    final normalized = location.isEmpty ? '/' : location;
    final generation = ++_navigationGeneration;
    final resolution = await _resolve(
      normalized,
      arguments: arguments,
      preferredTab: preferredTab,
    );
    if (generation != _navigationGeneration) {
      // Superseded by a newer navigation; drop the stale result.
      // 被更新的导航取代；丢弃过期结果。
      return null;
    }
    if (resolution == null) {
      _applyError(normalized);
      return null;
    }
    _applyInternal(resolution);
    return _futureFor(resolution.matchList.location);
  }

  Future<Object?> _futureFor(String location) {
    final stack = _overlayStack.isNotEmpty
        ? _overlayStack
        : _tabStacks[_currentTab];
    for (final entry in stack) {
      if (entry.match.location == location) {
        return entry.completer.future;
      }
    }
    return SynchronousFuture<Object?>(null);
  }

  /// Replace the top entry with a location. / 用 location 替换栈顶条目。
  ///
  /// At a branch root (a single-entry stack) the root itself is replaced —
  /// Navigator semantics — instead of stacking the new route on top of it.
  /// 位于 branch 根节点（单条目栈）时替换根本身——与 Navigator 语义一致——
  /// 而不是把新路由压栈。
  Future<Object?> pushReplacementNamed(
    String location, {
    Object? result,
    Object? arguments,
    int? preferredTab,
  }) async {
    final normalized = location.isEmpty ? '/' : location;
    if (_overlayStack.isNotEmpty) {
      // A fullscreen overlay is showing: the replacement discards it (its
      // future is settled by the push that follows), which `pushNamed`
      // already handles. / fullscreen 覆盖层展示中：替换会丢弃它（其 Future
      // 由随后的 push 补完），`pushNamed` 已覆盖该路径。
      return pushNamed(
        normalized,
        arguments: arguments,
        preferredTab: preferredTab,
      );
    }
    final stack = _tabStacks[_currentTab];
    if (stack.length > 1) {
      final removed = stack.removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(result);
      }
      return pushNamed(
        normalized,
        arguments: arguments,
        preferredTab: preferredTab,
      );
    }
    // At the branch root there is nothing above to remove, so replace the
    // root entry itself. / 位于 branch 根节点，上方没有可移除的条目，
    // 因此替换根本身。
    final generation = ++_navigationGeneration;
    final resolution = await _resolve(
      normalized,
      arguments: arguments,
      preferredTab: preferredTab,
    );
    if (generation != _navigationGeneration) {
      return null;
    }
    if (resolution == null) {
      _applyError(normalized);
      return null;
    }
    if (resolution.tabIndex == _currentTab) {
      _applyStacks(_currentTab, resolution.matchList, replace: true);
      _syncLocation();
      notifyListeners();
    } else {
      _applyExternal(resolution);
    }
    return _futureFor(resolution.matchList.location);
  }

  /// Push a location after removing entries until [predicate] holds.
  /// 移除条目直到 [predicate] 成立后 push 一个 location。
  Future<Object?> pushNamedAndRemoveUntil(
    String location,
    bool Function(ZeroRouteMatch) predicate, {
    Object? arguments,
  }) async {
    final stack = _tabStacks[_currentTab];
    while (stack.length > 1 && !predicate(stack.last.match)) {
      final removed = stack.removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(null);
      }
    }
    return pushNamed(location, arguments: arguments);
  }

  /// Pop the current entry and push a location.
  /// pop 当前条目并 push 一个 location。
  Future<Object?> popAndPushNamed(
    String location, {
    Object? result,
    Object? arguments,
    int? preferredTab,
  }) {
    return pushReplacementNamed(
      location,
      result: result,
      arguments: arguments,
      preferredTab: preferredTab,
    );
  }

  /// Pop the top entry of the current stack. / pop 当前栈的栈顶条目。
  /// Pops the top entry of the current tab. For an ordinary route this is a plain
  /// (synchronous) truncation. When the new top is a bare shell host — which
  /// renders nothing on its own — the parent location is re-resolved so the
  /// nested default tab is re-derived. / 移除当前 tab 栈顶条目。普通路由走直接的
  /// （同步）截断；若新的栈顶是纯 shell 宿主（自身不渲染内容），则重新解析父级
  /// location 以重建其嵌套默认 tab。
  void _popToParentOfCurrentTab([Object? result]) {
    final stack = _tabStacks[_currentTab];
    if (stack.length <= 1) {
      return;
    }
    final removed = stack.removeLast();
    if (!removed.completer.isCompleted) {
      removed.completer.complete(result);
    }
    final parent = stack.isEmpty ? '/' : stack.last.match.location;
    final top = stack.isEmpty ? null : stack.last;
    if (top != null && top.match.route.shell != null) {
      // The new top is a bare shell host: re-resolve so its nested default shows.
      // 新的栈顶为纯 shell 宿主：重新解析以显示其嵌套默认 tab。
      unawaited(_navigateTo(parent, external: true, forceTab: _currentTab));
    } else {
      _syncLocation();
      notifyListeners();
    }
  }

  void pop([Object? result]) {
    if (_overlayStack.isNotEmpty) {
      _popOverlay(result);
      return;
    }
    _popToParentOfCurrentTab(result);
  }

  void _popOverlay([Object? result]) {
    if (_overlayStack.isEmpty) {
      return;
    }
    final removed = _overlayStack.removeLast();
    if (!removed.completer.isCompleted) {
      removed.completer.complete(result);
    }
    _syncLocation();
    notifyListeners();
  }

  /// Clear the overlay stack, completing every pending entry's future so a
  /// `pushNamed` caller is never left waiting on a discarded overlay page.
  /// 清空覆盖栈，并补完每个待定条目的 Future——`pushNamed` 的调用者永远不会
  /// 被遗弃的覆盖页永久挂起。
  ///
  /// Plain `clear()` leaked the completers: the pages left the navigator (so
  /// they could never be popped) while their futures stayed pending forever.
  /// 直接 `clear()` 会泄漏 completer：页面已离开 navigator（再也不会被 pop），
  /// 其 Future 却永远挂起。
  void _clearOverlay([Object? result]) {
    for (final entry in _overlayStack) {
      if (!entry.completer.isCompleted) {
        entry.completer.complete(result);
      }
    }
    _overlayStack.clear();
  }

  /// Consult the top page's `PopScope`, then the route's `onExit`, then pop.
  /// 先问顶层页面 `PopScope`，再问路由 `onExit`，最后 pop。
  ///
  /// A framework route (dialog / sheet) on the root navigator is popped first,
  /// without consulting any route hook — it encloses every page.
  /// root navigator 上的框架级路由（dialog / sheet）优先 pop，且不询问任何
  /// 路由钩子——它包裹着所有页面。
  ///
  /// A no-op at the bottom of the stack.
  /// 栈底为 no-op。
  Future<bool> maybePop([Object? result]) async {
    final rootNav = _rootNavigatorKey.currentState;
    if (rootNav != null && _rootRouteCounter.hasImperativeRoute) {
      return rootNav.maybePop(result);
    }
    if (_overlayStack.isNotEmpty) {
      if (!await _checkOnExit(_overlayStack.last.match.route.onExit)) {
        return true;
      }
      return _rootMaybePop(result);
    }
    final stack = _tabStacks[_currentTab];
    if (stack.length > 1) {
      if (!await _checkOnExit(stack.last.match.route.onExit)) {
        return true;
      }
      final branchNav = _navigatorKeyFor(_currentTab).currentState;
      if (branchNav != null) {
        return branchNav.maybePop(result);
      }
      // Expanded mode: panes are not routes, so consult the shell route's
      // PopScope (panes register with it) before popping declaratively.
      // expanded 模式：pane 不是 route，先询问 shell route 的 PopScope
      // （pane 注册于其上），再以声明式方式 pop。
      final handled = await _rootMaybePop(result);
      if (handled) {
        return true;
      }
      _popTopOfCurrentTab(result);
      return true;
    }
    return false;
  }

  void _popTopOfCurrentTab([Object? result]) =>
      _popToParentOfCurrentTab(result);

  /// Pop within the layer that encloses [context] (dialog / sheet / page);
  /// other pages are unaffected.
  /// 在包裹 [context] 的层（dialog / sheet / page）内 pop；不影响其它页面。
  void popFrom(BuildContext context, [Object? result]) {
    final nav = Navigator.maybeOf(context);
    if (nav == null) {
      return;
    }
    if (nav == _rootNavigatorKey.currentState) {
      // The root navigator hosts the shell route, our overlay pages AND
      // framework routes (dialogs / sheets). Dismiss the imperative route
      // first (a framework route or an overlay page); only when it has
      // nothing imperative to pop does the declarative tab pop apply.
      // Checking `_overlayStack` alone used to pop the page beneath an open
      // dialog; and `nav.canPop()` (the previous guard) is always true for
      // the single shell route, so on expanded widths — where no branch
      // navigator is mounted and a pane context resolves to the root
      // navigator — `nav.pop()` removed the shell route and blanked the app
      // instead of collapsing the detail pane.
      // root navigator 承载 shell route、我们的 overlay 页与框架级路由
      // （dialog / sheet）。先关闭命令式路由（框架级路由或 overlay 页）；
      // 只有当它无可关闭的命令式路由时才走声明式 tab pop。此前只判断
      // `_overlayStack` 会在对话框打开时 pop 其下方页面；而 `nav.canPop()`
      // （旧守卫）对唯一一条 shell route 永远为 true，因此在 expanded 宽度
      // （未挂载 branch navigator，pane 上下文解析到 root navigator）下
      // `nav.pop()` 会移除 shell route 让应用空白，而非收起 detail pane。
      if (_rootRouteCounter.hasImperativeRoute || _overlayStack.isNotEmpty) {
        nav.pop(result);
        return;
      }
      _popTopOfCurrentTab(result);
      return;
    }
    nav.pop(result);
  }

  /// [maybePop] restricted to the layer that encloses [context].
  /// 限定在包裹 [context] 的层内的 [maybePop]。
  Future<bool> maybePopFrom(BuildContext context, [Object? result]) async {
    final nav = Navigator.maybeOf(context);
    if (nav == null) {
      return false;
    }
    if (nav == _rootNavigatorKey.currentState) {
      // A framework route (dialog / sheet) on the root navigator encloses
      // every page: it pops first, without consulting route hooks.
      // root navigator 上的框架级路由（dialog / sheet）包裹着所有页面：
      // 优先 pop，且不询问路由钩子。
      if (_rootRouteCounter.hasImperativeRoute) {
        return nav.maybePop(result);
      }
      if (_overlayStack.isNotEmpty) {
        if (!await _checkOnExit(_overlayStack.last.match.route.onExit)) {
          return true;
        }
        return nav.maybePop(result);
      }
      if (_tabStacks[_currentTab].length > 1) {
        if (!await _checkOnExit(
          _tabStacks[_currentTab].last.match.route.onExit,
        )) {
          return true;
        }
        final handled = await nav.maybePop(result);
        if (handled) {
          return true;
        }
        _popTopOfCurrentTab(result);
        return true;
      }
      return false;
    }
    final entry = _topEntryOfNavigator(nav);
    if (entry != null && !await _checkOnExit(entry.match.route.onExit)) {
      return true;
    }
    return nav.maybePop(result);
  }

  _StackEntry? _topEntryOfNavigator(NavigatorState nav) {
    final pages = nav.widget.pages;
    if (pages.isEmpty) {
      return null;
    }
    final top = pages.last;
    for (final entry in [..._overlayStack, ..._tabStacks.expand((s) => s)]) {
      if (identical(entry.page, top)) {
        return entry;
      }
    }
    return null;
  }

  /// Pop entries until [predicate] holds for the top entry.
  /// 持续 pop 直到栈顶条目满足 [predicate]。
  void popUntil(bool Function(ZeroRouteMatch) predicate) {
    final stack = _tabStacks[_currentTab];
    while (stack.length > 1 && !predicate(stack.last.match)) {
      final removed = stack.removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(null);
      }
    }
    _syncLocation();
    notifyListeners();
  }

  /// Switch tabs, optionally resetting the target tab to [initialLocation].
  /// 切换 tab，可用 [initialLocation] 重置目标 tab。
  void goTab(int index, {String? initialLocation}) {
    if (index < 0 || index >= _tabs.length) {
      return;
    }
    if (initialLocation != null) {
      _navigateTo(
        initialLocation,
        external: true,
        force: true,
        forceTab: index,
      );
      return;
    }
    if (index == _currentTab) {
      return;
    }
    _ensureTabStack(index);
    _currentTab = index;
    _syncLocation();
    notifyListeners();
  }

  /// Open a location in the right pane programmatically — the imperative twin of
  /// a `ZeroLink` tap. On expanded it expands / updates the detail pane; on
  /// compact / medium it pushes a page.
  /// 命令式地打开右栏中的某 location（`ZeroLink` 点击的命令式孪生）。expanded
  /// 下展开 / 更新 detail pane；compact / medium 下 push 页面。
  Future<Object?> showDetail(String location, {Object? arguments}) =>
      pushNamed(location, arguments: arguments);

  /// Collapse the detail pane (or pop the top branch entry) — the inverse of
  /// [showDetail]. / 收起 detail pane（或 pop 栈顶 branch 条目）——[showDetail]
  /// 的逆操作。
  void hideDetail() => _popTopOfCurrentTab();

  /// Whether the detail pane is currently open (expanded widths only).
  /// detail pane 当前是否展开（仅 expanded 宽度）。
  bool get isDetailOpen =>
      _widthClass == BreakpointClass.expanded &&
      _tabStacks[_currentTab].length > 1;

  /// Lazily initialize a tab's stack from its default location.
  /// 按默认 location 惰性初始化某个 tab 的栈。
  void _ensureTabStack(int index) {
    if (_tabStacks[index].isNotEmpty) {
      return;
    }
    final fallback =
        _tabs[index].initialLocation ??
        ZeroRouteMatcher.joinPattern('/', _tabs[index].routes.first.path);
    final matched = ZeroRouteMatcher.match(_tabs[index].routes, fallback);
    if (matched != null && matched.isNotEmpty) {
      _setTabStack(index, matched);
    }
  }

  /// Build a location from a named route.
  /// 由命名路由构建 location。
  String? namedLocation(
    String name, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
  }) {
    final pattern = _namedRoutes[name];
    if (pattern == null) {
      return null;
    }
    var path = pattern;
    pathParameters.forEach((key, value) {
      path = path.replaceAll(':$key', Uri.encodeComponent(value));
    });
    if (queryParameters.isEmpty) {
      return path;
    }
    return '$path?${Uri(queryParameters: queryParameters).query}';
  }

  /// Re-run redirects for the current location (e.g. after an auth change).
  /// 对当前 location 重跑重定向（例如登录态变化后）。
  Future<void> refresh() async {
    await _navigateTo(_location, external: true, force: true);
  }

  Future<bool> _rootMaybePop([Object? result]) async {
    final nav = _rootNavigatorKey.currentState;
    if (nav == null) {
      return false;
    }
    return nav.maybePop(result);
  }

  Future<bool> _checkOnExit(ZeroExitHook? onExit) async {
    if (onExit == null) {
      return true;
    }
    return await onExit();
  }

  // ------------------------------------------------------------ back key ----

  @override
  Future<bool> popRoute() async {
    // Framework routes (dialogs, bottom sheets) live on the ROOT navigator
    // above the shell route (and above any overlay page) — they pop first,
    // without consulting our route hooks. The branch navigator below cannot
    // see them, and consulting it first would pop the page beneath.
    // 框架级路由（dialog、bottom sheet）位于 root navigator，处于 shell route
    // （及 overlay 页）之上，优先 pop，且不询问路由钩子。下方的 branch
    // navigator 看不到它们，先询问它会 pop 掉其下方的页面。
    final rootNav = _rootNavigatorKey.currentState;
    if (rootNav != null && _rootRouteCounter.hasImperativeRoute) {
      return rootNav.maybePop();
    }
    // Fullscreen overlay routes cover everything and pop first.
    // fullscreen 覆盖路由覆盖一切，优先 pop。
    if (_overlayStack.isNotEmpty) {
      if (!await _checkOnExit(_overlayStack.last.match.route.onExit)) {
        return true;
      }
      return _rootMaybePop();
    }
    final stack = _tabStacks[_currentTab];
    if (stack.length > 1) {
      if (!await _checkOnExit(stack.last.match.route.onExit)) {
        return true;
      }
      final branchNav = _navigatorKeyFor(_currentTab).currentState;
      if (branchNav != null) {
        return branchNav.maybePop();
      }
      final handled = await _rootMaybePop();
      if (handled) {
        return true;
      }
      _popTopOfCurrentTab();
      return true;
    }
    // Bottom of the stack: ask the root route's `onExit`, then let the branch
    // root / shell route PopScope decide; an unhandled request exits the app.
    // 栈底：先问根路由的 `onExit`，再由 branch root / shell route 的 PopScope
    // 决定；无人处理则退出应用。
    if (!await _checkOnExit(stack.first.match.route.onExit)) {
      return true;
    }
    final branchNav = _navigatorKeyFor(_currentTab).currentState;
    if (branchNav != null) {
      final handled = await branchNav.maybePop();
      if (handled) {
        return true;
      }
    }
    return _rootMaybePop();
  }

  // ---------------------------------------------------------------- build --

  GlobalKey<NavigatorState> _navigatorKeyFor(int tab) {
    return _navigatorKeys.putIfAbsent(tab, () => GlobalKey<NavigatorState>());
  }

  @override
  void dispose() {
    final listener = _paneSideListener;
    if (listener != null) {
      paneSideListenable?.removeListener(listener);
      _paneSideListener = null;
    }
    _locationNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // MediaQuery first (it can be overridden by hosts / tests / the
        // example's width presets); fall back to the layout constraints.
        // 优先使用 MediaQuery（宿主 / 测试 / 示例的宽度预设均可覆盖之）；
        // 回退到布局约束。
        final mediaWidth = MediaQuery.maybeOf(context)?.size.width;
        _widthClass = breakpoints.classify(mediaWidth ?? constraints.maxWidth);
        return ZeroNavScope(delegate: this, child: _buildRoot(context));
      },
    );
  }

  Widget _buildRoot(BuildContext context) {
    final next = ZeroShellState(
      currentIndex: _currentTab,
      isCompact: _widthClass == BreakpointClass.compact,
      isMedium: _widthClass == BreakpointClass.medium,
      isExpanded: _widthClass == BreakpointClass.expanded,
      goTab: goTab,
      leftPaneFraction: _leftPaneFraction,
    );
    // Reuse the previous instance when nothing observable changed: the shell
    // scope then notifies no dependents, so an unrelated rebuild of the
    // delegate does not rebuild the whole shell subtree.
    // 可观察字段均未变化时复用上一个实例：shell scope 不会通知任何依赖者，
    // delegate 的不相关重建因此不会带动整棵 shell 子树重建。
    final previous = _shellState;
    if (previous == null ||
        previous.currentIndex != next.currentIndex ||
        previous.isCompact != next.isCompact ||
        previous.isMedium != next.isMedium ||
        previous.isExpanded != next.isExpanded ||
        previous.leftPaneFraction != next.leftPaneFraction) {
      _shellState = next;
    }
    final navigator = ZeroShellScope(
      state: _shellState!,
      child: Navigator(
        key: _rootNavigatorKey,
        observers: _rootObservers,
        pages: <Page<Object?>>[
          _ShellPage(delegate: this),
          for (final entry in _overlayStack) entry.page,
        ],
        onDidRemovePage: _onDidRemovePage,
      ),
    );
    // The Escape shortcut wraps the ROOT navigator (not the shell content) so
    // it also reaches fullscreen overlay pages, which render above the shell
    // route and could never see a `Shortcuts` ancestor inside it.
    // Escape 快捷键包裹根 navigator（而非 shell 内容），这样也能作用于
    // fullscreen 覆盖页——它们渲染在 shell route 之上，看不到其内部的
    // `Shortcuts` 祖先。
    if (!escapePops) {
      return navigator;
    }
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _EscapeIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _EscapeIntent: CallbackAction<_EscapeIntent>(
            onInvoke: (_) {
              unawaited(maybePop());
              return null;
            },
          ),
        },
        child: navigator,
      ),
    );
  }

  /// Builds the shell content (inside the root navigator's shell route).
  /// 构建 shell 内容（位于根 navigator 的 shell route 之内）。
  Widget buildShellContent(BuildContext context) {
    return _shell.builder(context, _shellState!, _buildShellChild(context));
  }

  /// The prefix of [stack] the OUTER shell should render directly: everything
  /// up to and including the first entry that hosts a nested shell. The nested
  /// shell renders the remaining suffix itself via the host's `child`.
  /// [stack] 中「外层 shell 应直接渲染」的前缀：从开头直到（含）首个承载嵌套
  /// shell 的 entry。剩余后缀由嵌套 shell 通过宿主的 `child` 自行渲染。
  List<_StackEntry> _outerRenderStack(List<_StackEntry> stack) {
    for (var i = 0; i < stack.length; i++) {
      if (stack[i].match.route.shell != null) {
        return stack.sublist(0, i + 1);
      }
    }
    return stack;
  }

  /// The suffix of [stack] belonging to the nested shell hosted by [entry].
  /// [stack] 中属于由 [entry] 承载的嵌套 shell 的后缀。
  List<_StackEntry> _nestedSubStack(
    List<_StackEntry> stack,
    _StackEntry entry,
  ) {
    final idx = stack.indexOf(entry);
    return idx < 0 ? const <_StackEntry>[] : stack.sublist(idx + 1);
  }

  Widget _buildShellChild(BuildContext context) {
    final stack = _tabStacks[_currentTab];
    final renderStack = _outerRenderStack(stack);
    if (_widthClass == BreakpointClass.expanded) {
      return _buildPanesFor(
        context,
        _shell,
        renderStack,
        _currentTab,
        stack,
        _navigatorKeyFor(_currentTab),
        allowPlaceholder: true,
        onDismissDetail: hideDetail,
      );
    }
    return _buildBranchNavigatorFor(
      _shell,
      renderStack,
      _currentTab,
      stack,
      _navigatorKeyFor(_currentTab),
      _onDidRemovePage,
    );
  }

  /// Builds a branch `Navigator` for [shell] (compact / medium). [renderStack]
  /// is the cut prefix of [fullStack] (a nested shell stops this shell's own
  /// pages at its host, rendering the suffix itself). [onDidRemovePage] lets a
  /// nested shell pop its own location instead of the outer one.
  /// 为 [shell] 构建 branch `Navigator`（compact / medium）。[renderStack] 是
  /// [fullStack] 被截断的前缀（嵌套 shell 会在其宿主处停下、自行渲染后缀）。
  /// [onDidRemovePage] 让嵌套 shell 能 pop 自己的 location 而非外层。
  Widget _buildBranchNavigatorFor(
    ZeroShell shell,
    List<_StackEntry> renderStack,
    int currentTabIndex,
    List<_StackEntry> fullStack,
    GlobalKey<NavigatorState> navKey,
    void Function(Page<Object?>) onDidRemovePage,
  ) {
    return Navigator(
      key: navKey,
      pages: <Page<Object?>>[for (final entry in renderStack) entry.page],
      onDidRemovePage: onDidRemovePage,
    );
  }

  /// Builds the two-column panes for [shell] (expanded). See the branch
  /// navigator above for the render-stack / nested-shell conventions.
  /// 为 [shell] 构建双列 panes（expanded）。render-stack 与嵌套 shell 约定同上。
  Widget _buildPanesFor(
    BuildContext context,
    ZeroShell shell,
    List<_StackEntry> renderStack,
    int currentTabIndex,
    List<_StackEntry> fullStack,
    GlobalKey<NavigatorState> navKey, {
    bool allowPlaceholder = true,
    VoidCallback? onDismissDetail,
  }) {
    final visible = renderStack.length >= 2
        ? renderStack.sublist(renderStack.length - 2)
        : renderStack;
    final panes = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      panes.add(_buildPane(context, visible[i], fullStack, isMaster: i == 0));
    }
    // A single visible pane shows a placeholder only when it is a genuine leaf
    // (no selection yet). A shell host fills it with its own nested shell, and a
    // nested shell always shows its own content even with one entry.
    // 单个可见 pane 仅在确实是叶子（尚无选择）时才显示占位提示；shell 宿主会用
    // 自身嵌套 shell 填满它，而嵌套 shell 即便只有一项也总是展示自己的内容。
    final showPlaceholder =
        visible.length == 1 &&
        allowPlaceholder &&
        visible.first.match.route.shell == null;
    final paneView = SlidingPanes(
      leftPaneFraction: _leftPaneFraction,
      maxLeftPaneWidth: maxLeftPaneWidth,
      side: _paneSide,
      slideDuration: slideDuration,
      slideCurve: slideCurve,
      resizeHandleWidth: resizeHandleWidth,
      resizeHandleBuilder: resizeHandleBuilder,
      paneBuilder: paneBuilder,
      // The empty-detail hint rides in its own slot: as a second child it
      // would mask the 1 ↔ 2 count that drives the expand / collapse
      // transition. / 空详情提示走独立参数：作为第二个 child 会掩盖驱动
      // 展开 / 收起转场的 1 ↔ 2 计数变化。
      placeholder: showPlaceholder
          ? _placeholderForShell(context, shell, currentTabIndex)
          : null,
      onLeftPaneFractionChanged: (fraction) {
        _leftPaneFraction = fraction;
      },
      onLeftPaneFractionDragEnd: (fraction) {
        // Commit point of a handle drag: rebuild once so
        // `ZeroShellState.leftPaneFraction` catches up. Notifying per frame
        // instead would rebuild the whole shell on every drag update.
        // 拖拽分割线的提交点：只重建一次，使
        // `ZeroShellState.leftPaneFraction` 跟上。若逐帧通知，整个 shell
        // 会在每次拖拽更新时重建。
        _leftPaneFraction = fraction;
        notifyListeners();
      },
      // Swipe the detail pane left to dismiss it (expanded widths).
      // expanded 宽度下左滑 detail pane 即可收起。
      onDismissDetail: onDismissDetail,
      children: panes,
    );
    if (!showBreadcrumbs) {
      return paneView;
    }
    return Column(
      children: [
        // Material ancestor for the InkWell-based breadcrumbs.
        // 为基于 InkWell 的面包屑提供 Material 祖先。
        Material(
          type: MaterialType.transparency,
          child: _buildBreadcrumbs(context, fullStack),
        ),
        Expanded(child: paneView),
      ],
    );
  }

  /// Wraps one pane in a stable key so [SlidingPanes] can tell a rebuild
  /// (same pane, new instance) from a master replacement (deeper push) and
  /// from an expand / collapse — without the key, transitions are skipped.
  /// 为单个 pane 包裹稳定键，使 [SlidingPanes] 能区分普通重建（同一 pane、
  /// 新实例）、master 替换（更深层级 push）与展开 / 收起——无键则跳过转场。
  Widget _buildPane(
    BuildContext context,
    _StackEntry entry,
    List<_StackEntry> stack, {
    required bool isMaster,
  }) {
    return KeyedSubtree(
      key: ValueKey('pane:${entry.match.location}'),
      child: _buildPaneContent(context, entry, isMaster, stack),
    );
  }

  /// Placeholder for an empty pane of [shell] at [tabIndex], preferring the
  /// tab's placeholder, then the shell's, then a default icon.
  /// [shell] 在 [tabIndex] 处空 pane 的占位内容：优先 tab 级、再 shell 级，
  /// 最后为默认图标。
  Widget _placeholderForShell(
    BuildContext context,
    ZeroShell shell,
    int tabIndex,
  ) =>
      shell.tabs[tabIndex].placeholder ??
      shell.placeholder ??
      placeholder ??
      _defaultPlaceholder(context);

  Widget _defaultPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(Icons.article_outlined, size: 48, color: theme.disabledColor),
    );
  }

  /// Wraps [inner] with the scroll / focus restoration machinery. `PageStorage`
  /// remembers scroll offsets keyed by [ZeroRouteState.restorationId]; the focus
  /// restorer returns primary focus to the route that last held it after a pop.
  /// 用滚动 / 焦点恢复机制包裹 [inner]。`PageStorage` 以
  /// [ZeroRouteState.restorationId] 为键记住滚动偏移；焦点恢复器在 pop 后把主
  /// 焦点还给上次持有它的 route。
  Widget _wrapRestoration(ZeroRouteMatch match, Widget inner) {
    if (restoreScrollOffset) {
      inner = PageStorage(
        bucket: _pageStorageBucket,
        child: KeyedSubtree(
          key: PageStorageKey<String>(match.state.restorationId),
          child: inner,
        ),
      );
    }
    if (restoreFocus) {
      inner = _FocusRestorer(
        id: match.state.restorationId,
        initialFocusedId: _focusedRestorationId,
        onFocused: _noteFocus,
        child: inner,
      );
    }
    return inner;
  }

  /// Returns primary focus to the route that last held it after it remounts
  /// (e.g. on a pop), so history navigation does not drop focus to the body.
  /// 在某 route 重新挂载（如 pop 后）时把主焦点还给上次持有它的 route，
  /// 使历史导航不会把焦点丢到 body。
  Widget _buildPaneContent(
    BuildContext context,
    _StackEntry entry,
    bool isMaster,
    List<_StackEntry> stack,
  ) {
    final match = entry.match;
    final route = match.route;
    Widget inner;
    if (route.shell != null) {
      // A nested shell hosted by this route: build it recursively and pass it as
      // the route builder's `child`. The nested shell owns its own tabs / panes
      // over the suffix of [stack] after this entry.
      // 本路由承载的嵌套 shell：递归构建并作为路由 builder 的 `child` 传入。
      // 嵌套 shell 在「本 entry 之后的栈后缀」上拥有自己的 tabs / panes。
      final child = _buildNestedShell(
        context,
        entry,
        route.shell!,
        _nestedSubStack(stack, entry),
      );
      inner = route.shellBuilder?.call(context, match.state, child) ?? child;
    } else {
      // `pageKey` is the stable handoff key: when the window width crosses a
      // breakpoint the page content (a route on compact / medium, a pane here)
      // is rebuilt in a different subtree, and the keyed element moves in the
      // same frame instead of being recreated — scroll offsets and text input
      // survive. / `pageKey` 是稳定的交接键：窗口宽度跨越断点时页面内容
      // （compact / medium 是 route，此处是 pane）会在不同子树中重建，带键的
      // 元素于同帧移动而非重建——滚动偏移与文本输入得以保留。
      inner =
          route.builder?.call(context, match.state) ?? const SizedBox.shrink();
      if (route.loader != null) {
        // Data-driven route: resolve before building, showing the loading /
        // error widget meanwhile. / 数据驱动路由：构建前先解析，期间显示加载 /
        // 错误态。
        inner = _LoaderBridge(
          route: route,
          state: match.state,
          errorBuilder: errorBuilder,
          childBuilder: (context, state) =>
              route.builder?.call(context, state) ?? const SizedBox.shrink(),
        );
      }
    }
    inner = _wrapRestoration(match, inner);
    final pane = ZeroRouteStateScope(
      key: match.state.pageKey,
      state: match.state,
      child: ZeroPaneScope(title: match.title, child: inner),
    );
    final builder = paneBuilder;
    if (builder != null) {
      return builder(context, pane, isMaster);
    }
    return pane;
  }

  /// Builds the content of a route page (inside its route).
  /// 构建路由页面的内容（位于其 route 之内）。
  Widget _buildPageContent(
    BuildContext context,
    _StackEntry entry, {
    required bool isBranchRoot,
    required List<_StackEntry> stack,
  }) {
    final match = entry.match;
    final route = match.route;
    Widget inner;
    if (route.shell != null) {
      final child = _buildNestedShell(
        context,
        entry,
        route.shell!,
        _nestedSubStack(stack, entry),
      );
      inner = route.shellBuilder?.call(context, match.state, child) ?? child;
    } else {
      // Keyed with the same `pageKey` the expanded pane uses, so the content
      // subtree is handed over in the same frame when the width class changes.
      // 与 expanded pane 使用同一个 `pageKey`，宽度档位变化时内容子树于同帧交接。
      inner =
          route.builder?.call(context, match.state) ?? const SizedBox.shrink();
      if (route.loader != null) {
        inner = _LoaderBridge(
          route: route,
          state: match.state,
          errorBuilder: errorBuilder,
          childBuilder: (context, state) =>
              route.builder?.call(context, state) ?? const SizedBox.shrink(),
        );
      }
    }
    inner = _wrapRestoration(match, inner);
    final content = ZeroRouteStateScope(
      key: match.state.pageKey,
      state: match.state,
      child: ZeroPaneScope(title: null, child: inner),
    );
    if (entry.isOverlay) {
      return content;
    }
    final bottomBar = chromeBottomNavigationBarOf(context);
    final showChrome =
        bottomBar != null && (isBranchRoot || !route.hidesBottomBarWhenPushed);
    if (!showChrome) {
      return _withBranchBreadcrumbs(context, content);
    }
    return _withBranchBreadcrumbs(
      context,
      Scaffold(body: content, bottomNavigationBar: bottomBar(context)),
    );
  }

  /// Returns the full tab / overlay stack that currently contains [entry] (every
  /// match lives in the top-level tab stacks, including nested-shell entries).
  /// 返回当前包含 [entry] 的完整 tab / 覆盖栈（每个匹配都位于顶层 tab 栈中，
  /// 含嵌套 shell 的条目）。
  List<_StackEntry> _stackContaining(_StackEntry entry) {
    for (final stack in _tabStacks) {
      if (stack.contains(entry)) {
        return stack;
      }
    }
    if (_overlayStack.contains(entry)) {
      return _overlayStack;
    }
    return const <_StackEntry>[];
  }

  /// Stable navigator key for the nested shell hosted at [hostLocation].
  /// 寄宿于 [hostLocation] 的嵌套 shell 的稳定 navigator 键。
  GlobalKey<NavigatorState> _nestedNavigatorKeyFor(String hostLocation) =>
      _nestedNavigatorKeys.putIfAbsent(
        hostLocation,
        () => GlobalKey<NavigatorState>(),
      );

  /// The tab index of [shell] whose route table owns the first entry of
  /// [subStack]. Defaults to 0 when the sub-stack is empty.
  /// [subStack] 首个 entry 所属 [shell] 的 tab 下标；sub-stack 为空时默认 0。
  int _nestedTabIndex(ZeroShell shell, List<_StackEntry> subStack) {
    if (subStack.isEmpty) {
      return 0;
    }
    final rootRoute = subStack.first.match.route;
    final index = shell.tabs.indexWhere((t) => t.routes.contains(rootRoute));
    return index < 0 ? 0 : index;
  }

  /// Builds the recursive nested-shell widget for [shell], hosted by [hostEntry].
  /// [subStack] is the suffix of the outer stack that belongs to this shell.
  /// 为寄宿于 [hostEntry] 的 [shell] 递归构建嵌套 shell 组件。[subStack] 为外层
  /// 栈中属于本 shell 的后缀。
  Widget _buildNestedShell(
    BuildContext context,
    _StackEntry hostEntry,
    ZeroShell shell,
    List<_StackEntry> subStack,
  ) {
    final tabIndex = subStack.isEmpty ? 0 : _nestedTabIndex(shell, subStack);
    final hostLocation = hostEntry.match.location;
    // `goTab` writes a new location — the delegate re-resolves the whole (flat)
    // stack and re-renders every shell level, so a nested shell needs no private
    // state machine. / `goTab` 写入新的 location：delegate 重新解析整条（扁平）
    // 栈并渲染每一层 shell，因此嵌套 shell 无需私有状态机。
    void goTab(int index, {String? initialLocation}) {
      final tab = shell.tabs[index];
      final target =
          initialLocation ??
          ZeroRouteMatcher.joinPattern(hostLocation, tab.routes.first.path);
      unawaited(_navigateTo(target, external: true, forceTab: _currentTab));
    }

    final nestedState = ZeroShellState(
      currentIndex: tabIndex,
      isCompact: _widthClass == BreakpointClass.compact,
      isMedium: _widthClass == BreakpointClass.medium,
      isExpanded: _widthClass == BreakpointClass.expanded,
      goTab: goTab,
      leftPaneFraction: _leftPaneFraction,
    );
    final navKey = _nestedNavigatorKeyFor(hostLocation);
    final renderStack = _outerRenderStack(subStack);
    final child = _widthClass == BreakpointClass.expanded
        ? _buildPanesFor(
            context,
            shell,
            renderStack,
            tabIndex,
            subStack,
            navKey,
            allowPlaceholder: false,
            onDismissDetail: () => _navigateToNestedParent(
              hostEntry,
              subStack,
              subStack.length - 1,
            ),
          )
        : _buildBranchNavigatorFor(
            shell,
            renderStack,
            tabIndex,
            subStack,
            navKey,
            (page) => _onNestedDidRemovePage(hostEntry, subStack, page),
          );
    return ZeroShellScope(
      state: nestedState,
      child: shell.builder(context, nestedState, child),
    );
  }

  /// Navigates to the parent of the entry at [removedIndex] within [subStack],
  /// falling back to the hosting route when it is the shell's root entry.
  /// 跳转到 [subStack] 中 [removedIndex] 处条目的父级 location；若已是 shell 根
  /// entry，则回到寄宿该 shell 的路由 location。
  void _navigateToNestedParent(
    _StackEntry hostEntry,
    List<_StackEntry> subStack,
    int removedIndex,
  ) {
    final target = removedIndex <= 0
        ? hostEntry.match.location
        : subStack[removedIndex - 1].match.location;
    unawaited(_navigateTo(target, external: true, forceTab: _currentTab));
  }

  /// `onDidRemovePage` for a nested branch navigator: pops the removed page by
  /// navigating to its parent location.
  /// 嵌套 branch navigator 的 `onDidRemovePage`：通过跳转到被移除页面的父级
  /// location 来 pop。
  void _onNestedDidRemovePage(
    _StackEntry hostEntry,
    List<_StackEntry> subStack,
    Page<Object?> page,
  ) {
    for (var i = subStack.length - 1; i >= 0; i--) {
      if (identical(subStack[i].page, page)) {
        _navigateToNestedParent(hostEntry, subStack, i);
        return;
      }
    }
  }

  /// Wraps [content] with the breadcrumb bar on compact / medium when
  /// [showBreadcrumbsOnBranch] is set and the branch stack has more than one
  /// entry. / 当开启 [showBreadcrumbsOnBranch] 且 branch 栈多于一项时，在
  /// compact / medium 为 [content] 顶部加面包屑栏。
  Widget _withBranchBreadcrumbs(BuildContext context, Widget content) {
    if (!showBreadcrumbsOnBranch) {
      return content;
    }
    final stack = _tabStacks[_currentTab];
    if (stack.length <= 1) {
      return content;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          type: MaterialType.transparency,
          child: _buildBreadcrumbs(context, stack),
        ),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, List<_StackEntry> stack) {
    final builder = breadcrumbsBuilder;
    final matches = stack.map((entry) => entry.match).toList();
    if (builder != null) {
      return builder(context, matches);
    }
    return Breadcrumbs(
      items: matches.map((match) => match.title ?? match.location).toList(),
      onNavigate: (index) {
        if (index < 0 || index >= stack.length) {
          return;
        }
        _popStackTo(_tabStacks[_currentTab], index + 1);
        _syncLocation();
        notifyListeners();
      },
    );
  }

  Widget _defaultErrorPage(BuildContext context, String location) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text('No route matches $location', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- syncing ----

  void _onDidRemovePage(Page<Object?> page) {
    for (final entry in _overlayStack) {
      if (identical(entry.page, page)) {
        _overlayStack.remove(entry);
        _syncLocation();
        notifyListeners();
        return;
      }
    }
    for (var t = 0; t < _tabStacks.length; t++) {
      final stack = _tabStacks[t];
      for (var i = stack.length - 1; i >= 0; i--) {
        if (identical(stack[i].page, page)) {
          stack.removeRange(i, stack.length);
          if (t == _currentTab) {
            _syncLocation();
          }
          notifyListeners();
          return;
        }
      }
    }
  }
}

/// Resolves a route's [ZeroRoute.loader] before building the page content,
/// showing a loading / error widget meanwhile and republishing the resolved
/// [ZeroRouteState.data] to the subtree.
/// 在构建页面内容前解析路由的 [ZeroRoute.loader]，期间显示加载 / 错误态，
/// 并把解析得到的 [ZeroRouteState.data] 重新发布给子树。
class _LoaderBridge extends StatefulWidget {
  const _LoaderBridge({
    required this.route,
    required this.state,
    this.errorBuilder,
    required this.childBuilder,
  });

  final ZeroRoute route;
  final ZeroRouteState state;
  final ZeroErrorBuilder? errorBuilder;
  final Widget Function(BuildContext context, ZeroRouteState state)
  childBuilder;

  @override
  State<_LoaderBridge> createState() => _LoaderBridgeState();
}

class _LoaderBridgeState extends State<_LoaderBridge> {
  Object? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final futureOr = widget.route.loader!(widget.state);
      final data = futureOr is Future<dynamic> ? await futureOr : futureOr;
      if (!mounted) {
        return;
      }
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final builder = widget.route.loadingBuilder;
      return builder?.call(context, widget.state) ??
          const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return widget.errorBuilder?.call(context, widget.state.location) ??
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load ${widget.state.location}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
    }
    final updated = widget.state.copyWith(data: _data);
    return ZeroRouteStateScope(
      key: updated.pageKey,
      state: updated,
      child: widget.childBuilder(context, updated),
    );
  }
}

/// Returns primary focus to the route that last held it after it remounts (e.g.
/// on a pop), so browser-history navigation does not drop focus to the body.
/// 在某 route 重新挂载（如 pop 后）时把主焦点还给上次持有它的 route，
/// 使浏览器历史导航不会把焦点丢到 body。
class _FocusRestorer extends StatefulWidget {
  /// Create the restorer. / 创建恢复器。
  const _FocusRestorer({
    required this.id,
    required this.initialFocusedId,
    required this.onFocused,
    required this.child,
  });

  /// The route's restoration id. / 该 route 的 restoration id。
  final String id;

  /// The id of the route that held focus before this navigation, or `null`.
  /// 本次导航前持有焦点的 route 的 id，或 `null`。
  final String? initialFocusedId;

  /// Called when this subtree gains primary focus. / 该子树获得主焦点时调用。
  final ValueChanged<String> onFocused;

  /// The wrapped content. / 被包裹的内容。
  final Widget child;

  @override
  State<_FocusRestorer> createState() => _FocusRestorerState();
}

class _FocusRestorerState extends State<_FocusRestorer> {
  final FocusNode _node = FocusNode();

  @override
  void initState() {
    super.initState();
    // If this was the focused route, reclaim focus once the tree is laid out.
    // 若本 route 曾是焦点所在，布局完成后重新夺回焦点。
    if (widget.id == widget.initialFocusedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _node.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      onFocusChange: (focused) {
        if (focused) {
          widget.onFocused(widget.id);
        }
      },
      child: widget.child,
    );
  }
}
