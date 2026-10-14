/// Adaptive navigation for Flutter: one `onTap`, the right behavior everywhere.
/// Flutter 的自适应导航：同一套 `onTap`，在任意平台都做出正确行为。
///
/// Write a single tap target with [ZeroLink] (or call [ZeroNav] imperatively)
/// and the plugin decides by window width: compact / medium push a new page,
/// expanded expands or updates the right sidebar pane (master-detail).
/// 用 [ZeroLink] 写一套点击目标（或用 [ZeroNav] 命令式调用），插件按窗口宽度
/// 决策：compact / medium push 新页面，expanded 展开或更新右侧侧栏 pane
/// （master-detail）。
///
/// Locations are URL-addressable and deep-linkable; on the web the hash
/// strategy (`/#/products/42`) keeps browser back, refresh and deep links on
/// the same location pipeline as in-app navigation.
/// location 可被 URL 表达且可深链；Web 上 hash 策略（`/#/products/42`）让浏览器
/// 返回、刷新、深链与应用内导航走同一条 location 管道。
///
/// Zero runtime dependencies; pure Dart (no platform channels).
/// 零运行时第三方依赖；纯 Dart（无 platform channel）。
library;

export 'src/layout/breakpoints.dart' show Breakpoints, BreakpointClass;
export 'src/layout/breadcrumbs.dart' show Breadcrumbs;
export 'src/layout/sliding_pane.dart' show SlidingPane;
export 'src/layout/sliding_panes.dart'
    show
        SlidingPanes,
        SlidingPanesSide,
        SlidingPaneBuilder,
        SlidingResizeHandleBuilder;
export 'src/nav/zero_nav.dart' show ZeroNav, ZeroNavScope;
export 'src/router/delegate.dart' show ZeroRouterDelegate;
export 'src/router/match.dart' show MatchList, ZeroRouteMatch, ZeroRouteMatcher;
export 'src/router/parser.dart' show ZeroRouteInformationParser;
export 'src/router/router.dart'
    show
        ZeroBreadcrumbsBuilder,
        ZeroErrorBuilder,
        ZeroExitHook,
        ZeroRoute,
        ZeroRouteBuilder,
        ZeroRouteRedirect,
        ZeroRouter,
        ZeroRouterRedirect,
        ZeroShell,
        ZeroShellBuilder,
        ZeroTab,
        ZeroTitleBuilder;
export 'src/router/state.dart'
    show
        ZeroPaneScope,
        ZeroRouteState,
        ZeroRouteStateScope,
        ZeroShellScope,
        ZeroShellState;
export 'src/shell/shell.dart' show ZeroShellChrome;
export 'src/widgets/zero_link.dart' show ZeroLink;
