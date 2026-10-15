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
  }) : super(settings: page);

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
  }) : _paneSide = paneSide,
       _leftPaneFraction = initialLeftPaneFraction,
       _shell = routes.first {
    assert(routes.isNotEmpty, 'At least one ZeroShell is required.');
    // A listenable side flips the expanded layout at runtime (no rebuild).
    // 可监听的 side 在运行时切换展开方向（无需重建路由）。
    final listenable = paneSideListenable;
    if (listenable != null) {
      _paneSideListener = () => paneSide = listenable.value;
      listenable.addListener(_paneSideListener!);
    }
    for (var t = 0; t < _shell.tabs.length; t++) {
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

  final ZeroShell _shell;

  /// The [paneSideListenable] listener, kept so it can be removed in [dispose].
  /// 保存 [paneSideListenable] 的 listener，以便在 [dispose] 中移除。
  VoidCallback? _paneSideListener;
  final List<List<_StackEntry>> _tabStacks = [];
  final List<_StackEntry> _overlayStack = [];
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {};
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  final Map<String, String> _namedRoutes = {};

  int _currentTab = 0;
  String _location = '/';
  double _leftPaneFraction;
  BreakpointClass _widthClass = BreakpointClass.expanded;
  SlidingPanesSide _paneSide = SlidingPanesSide.right;
  late ZeroShellState _shellState;
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
    final resolution = await _resolve(normalized, preferredTab: forceTab);
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
      _overlayStack.clear();
    } else {
      final stack = _tabStacks[tabIndex];
      for (final match in tabMatches) {
        stack.add(_createEntry(match, isRoot: false));
      }
      _overlayStack.clear();
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
    _overlayStack.clear();
    _location = location;
    if (_locationNotifier.value != _location) {
      _locationNotifier.value = _location;
    }
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
  Future<Object?> pushNamed(String location, {Object? arguments}) async {
    final normalized = location.isEmpty ? '/' : location;
    final resolution = await _resolve(normalized, arguments: arguments);
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
  Future<Object?> pushReplacementNamed(
    String location, {
    Object? result,
    Object? arguments,
  }) async {
    if (_overlayStack.isEmpty && _tabStacks[_currentTab].length > 1) {
      final removed = _tabStacks[_currentTab].removeLast();
      if (!removed.completer.isCompleted) {
        removed.completer.complete(result);
      }
    }
    return pushNamed(location, arguments: arguments);
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
  }) {
    return pushReplacementNamed(location, result: result, arguments: arguments);
  }

  /// Pop the top entry of the current stack. / pop 当前栈的栈顶条目。
  void pop([Object? result]) {
    if (_overlayStack.isNotEmpty) {
      _popOverlay(result);
      return;
    }
    final stack = _tabStacks[_currentTab];
    if (stack.length <= 1) {
      return;
    }
    final removed = stack.removeLast();
    if (!removed.completer.isCompleted) {
      removed.completer.complete(result);
    }
    _syncLocation();
    notifyListeners();
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

  /// Consult the top page's `PopScope`, then the route's `onExit`, then pop.
  /// 先问顶层页面 `PopScope`，再问路由 `onExit`，最后 pop。
  ///
  /// A no-op at the bottom of the stack.
  /// 栈底为 no-op。
  Future<bool> maybePop([Object? result]) async {
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

  void _popTopOfCurrentTab([Object? result]) {
    final stack = _tabStacks[_currentTab];
    if (stack.length <= 1) {
      return;
    }
    final removed = stack.removeLast();
    if (!removed.completer.isCompleted) {
      removed.completer.complete(result);
    }
    _syncLocation();
    notifyListeners();
  }

  /// Pop within the layer that encloses [context] (dialog / sheet / page);
  /// other pages are unaffected.
  /// 在包裹 [context] 的层（dialog / sheet / page）内 pop；不影响其它页面。
  void popFrom(BuildContext context, [Object? result]) {
    final nav = Navigator.maybeOf(context);
    if (nav == null) {
      return;
    }
    if (nav == _rootNavigatorKey.currentState) {
      if (_overlayStack.isNotEmpty) {
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
    _shellState = ZeroShellState(
      currentIndex: _currentTab,
      isCompact: _widthClass == BreakpointClass.compact,
      isMedium: _widthClass == BreakpointClass.medium,
      isExpanded: _widthClass == BreakpointClass.expanded,
      goTab: goTab,
      leftPaneFraction: _leftPaneFraction,
    );
    return ZeroShellScope(
      state: _shellState,
      child: Navigator(
        key: _rootNavigatorKey,
        pages: <Page<Object?>>[
          _ShellPage(delegate: this),
          for (final entry in _overlayStack) entry.page,
        ],
        onDidRemovePage: _onDidRemovePage,
      ),
    );
  }

  /// Builds the shell content (inside the root navigator's shell route).
  /// 构建 shell 内容（位于根 navigator 的 shell route 之内）。
  Widget buildShellContent(BuildContext context) {
    final child = _buildShellChild(context);
    final content = _shell.builder(context, _shellState, child);
    if (!escapePops) {
      return content;
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
        child: content,
      ),
    );
  }

  Widget _buildShellChild(BuildContext context) {
    final stack = _tabStacks[_currentTab];
    if (_widthClass == BreakpointClass.expanded) {
      return _buildPanes(context, stack);
    }
    return _buildBranchNavigator(context, stack);
  }

  Widget _buildBranchNavigator(BuildContext context, List<_StackEntry> stack) {
    return Navigator(
      key: _navigatorKeyFor(_currentTab),
      pages: <Page<Object?>>[for (final entry in stack) entry.page],
      onDidRemovePage: _onDidRemovePage,
    );
  }

  Widget _buildPanes(BuildContext context, List<_StackEntry> stack) {
    final visible = stack.length >= 2 ? stack.sublist(stack.length - 2) : stack;
    final panes = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      panes.add(_buildPaneContent(context, visible[i], i == 0));
    }
    if (visible.length == 1) {
      panes.add(_placeholderFor(context, _currentTab));
    }
    final paneView = SlidingPanes(
      leftPaneFraction: _leftPaneFraction,
      maxLeftPaneWidth: maxLeftPaneWidth,
      side: _paneSide,
      slideDuration: slideDuration,
      slideCurve: slideCurve,
      resizeHandleWidth: resizeHandleWidth,
      resizeHandleBuilder: resizeHandleBuilder,
      paneBuilder: paneBuilder,
      onLeftPaneFractionChanged: (fraction) {
        _leftPaneFraction = fraction;
      },
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
          child: _buildBreadcrumbs(context, stack),
        ),
        Expanded(child: paneView),
      ],
    );
  }

  Widget _placeholderFor(BuildContext context, int tabIndex) {
    return _tabs[tabIndex].placeholder ??
        placeholder ??
        _defaultPlaceholder(context);
  }

  Widget _defaultPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Icon(Icons.article_outlined, size: 48, color: theme.disabledColor),
    );
  }

  Widget _buildPaneContent(
    BuildContext context,
    _StackEntry entry,
    bool isMaster,
  ) {
    final match = entry.match;
    final pane = ZeroRouteStateScope(
      state: match.state,
      child: ZeroPaneScope(
        title: match.title,
        child:
            match.route.builder?.call(context, match.state) ??
            const SizedBox.shrink(),
      ),
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
  }) {
    final match = entry.match;
    final route = match.route;
    final content = ZeroRouteStateScope(
      state: match.state,
      child: ZeroPaneScope(
        title: null,
        child:
            route.builder?.call(context, match.state) ??
            const SizedBox.shrink(),
      ),
    );
    if (entry.isOverlay) {
      return content;
    }
    final bottomBar = chromeBottomNavigationBarOf(context);
    final showChrome =
        bottomBar != null && (isBranchRoot || !route.hidesBottomBarWhenPushed);
    if (!showChrome) {
      return content;
    }
    return Scaffold(body: content, bottomNavigationBar: bottomBar(context));
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
