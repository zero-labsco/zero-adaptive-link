# Changelog

## 0.2.0

### Fixed / 修复

- Fixed `ZeroRoute.barrierDismissible` being silently ignored: the value was captured into the route config but never passed to `PageRoute`, whose private final field defaults to `false`. Tapping the barrier of a fullscreen route with `barrierDismissible: true` now dismisses it, as documented.
  - 修复 `ZeroRoute.barrierDismissible` 被静默忽略：该值被采集进路由配置，却从未传给 `PageRoute`——父类的私有 final 字段默认 `false`。现在点击 `barrierDismissible: true` 的 fullscreen 路由屏障会如文档所述关闭它。
- Fixed `ZeroRoute.fullscreenDialog` being silently ignored for the same reason: the created route now reports `fullscreenDialog == true`, so the full-screen dialog transition applies and the back-swipe gesture is disabled.
  - 修复 `ZeroRoute.fullscreenDialog` 因同样原因被静默忽略：创建的 route 现在报告 `fullscreenDialog == true`，全屏对话框转场生效，侧滑返回被禁用。
- Fixed a leaked `pushNamed` future for fullscreen routes: clearing the overlay stack (a new push, a deep link, or an unmatched location while an overlay was open) dropped the entries without completing their futures, so `await ZeroNav.open(...)` hung forever. Every discarded overlay entry's future is now completed with `null`.
  - 修复 fullscreen 路由 `pushNamed` Future 泄漏：清空覆盖栈（覆盖层打开时再次 push、收到深链、或 location 失配）会丢弃条目而不补完其 Future，`await ZeroNav.open(...)` 因此永久挂起。现在每个被遗弃的覆盖层条目的 Future 都会以 `null` 补完。
- Fixed percent-encoded path parameters being rewritten by matching: `Uri.parse` decodes path segments and the matcher re-emitted them raw, so `/products/a%20b` became the location `/products/a b` (desyncing the URL bar, `namedLocation` and push de-duplication). Segments are now re-encoded, and locations round-trip unchanged.
  - 修复匹配过程改写百分号编码的路径参数：`Uri.parse` 会解码路径片段，而 matcher 原样拼回，导致 `/products/a%20b` 的 location 变成 `/products/a b`（与地址栏、`namedLocation`、push 去重脱节）。现在片段会重新编码，location 往返不变。
- Fixed bare `StateError: No element` crashes for degenerate configurations: an empty `routes` list threw before the `assert` could run, and an empty `ZeroTab` crashed the first `goTab` / deep-link fallback. All three cases now fail with friendly asserts (`At least one ZeroShell is required`, `Exactly one ZeroShell is supported in 0.x`, `at least one ZeroTab`, `at least one ZeroRoute`).
  - 修复退化配置下的裸 `StateError: No element` 崩溃：空 `routes` 列表会在 `assert` 执行前就抛错，空 `ZeroTab` 会在首次 `goTab` / 深链回退时崩溃。这三种情况现在都会给出友好断言（`At least one ZeroShell is required`、`Exactly one ZeroShell is supported in 0.x`、`at least one ZeroTab`、`at least one ZeroRoute`）。
- Fixed the web hash parser merging the host page's query into the location: `/?utm_source=x#/products/42` used to become `/products/42?utm_source=x`. The query inside the fragment (the app's own) is still kept.
  - 修复 Web hash 解析器把宿主页面的 query 合并进 location：`/?utm_source=x#/products/42` 过去会变成 `/products/42?utm_source=x`。fragment 内部的 query（应用自身的）仍会保留。
- Fixed the misleading `restoreRouteInformation` doc comment (it claimed to restore a fragment URI; the URI must stay fragment-free so the provider re-adds the `#`).
  - 修正 `restoreRouteInformation` 误导性的文档注释（它声称还原为 fragment URI；URI 必须不带 fragment，由 provider 重新加上 `#`）。

### Changed / 优化

- The Escape shortcut (`escapePops`, on by default) now wraps the root navigator instead of the shell content, so it also reaches fullscreen overlay pages — which render above the shell route and could never see a `Shortcuts` ancestor inside it.
  - Escape 快捷键（`escapePops`，默认开启）现在包裹根 navigator 而非 shell 内容，因此也能作用于 fullscreen 覆盖页——它们渲染在 shell route 之上，看不到其内部的 `Shortcuts` 祖先。
- `ZeroShellState` is now reused across rebuilds when none of its observable fields changed, so an unrelated delegate rebuild no longer notifies every shell-scope dependent.
  - `ZeroShellState` 现在在可观察字段均未变化时跨重建复用，delegate 的不相关重建不再通知所有 shell scope 依赖者。
- The resize handle drag no longer misreads a drag started at global x == 0 as "not dragging" (which let a widget update overwrite the fraction mid-drag); a dedicated flag tracks the gesture.
  - 拖拽分割线不再把在全局 x == 0 处开始的拖拽误判为「未在拖拽」（组件更新会在拖拽中途覆盖比例）；改用专用标志跟踪手势。

### Added / 新增

- Added `SlidingPanes.onLeftPaneFractionDragEnd`: a once-per-drag commit callback, wired by `ZeroRouter` to a single rebuild so `ZeroShellState.leftPaneFraction` catches up after a handle drag (live dragging still streams through `onLeftPaneFractionChanged`).
  - 新增 `SlidingPanes.onLeftPaneFractionDragEnd`：每轮拖拽触发一次的提交回调，由 `ZeroRouter` 接入一次重建，使 `ZeroShellState.leftPaneFraction` 在拖拽分割线后跟上（实时拖拽仍走 `onLeftPaneFractionChanged` 逐帧回调）。

## 0.1.3

### Fixed / 修复
- Fixed `paneSideListenable` being a no-op at runtime: the delegate's listener closure assigned the new side to the `paneSide` *constructor parameter* (which shadows the instance setter of the same name) instead of the instance setter, so `_paneSide` never updated and the expanded layout never flipped when the listenable changed. The example's "Expand left / right" toggle now actually mirrors the detail pane. Added regression tests (`test/pane_side_test.dart`, `test/expand_side_test.dart`).
  - 修复 `paneSideListenable` 运行时无效：delegate 的 listener 闭包把新 side 赋给了同名的 `paneSide` **构造形参**（遮蔽了实例 setter），而不是实例 setter，导致 `_paneSide` 永远不更新、展开布局在 listenable 变化时从不翻转。示例里的「Expand left / right」切换现在能真正镜像 detail pane。新增回归测试（`test/pane_side_test.dart`、`test/expand_side_test.dart`）。

## 0.1.2

### Fixed / 修复
- Fixed the resize-handle drag stalling / drifting: the gesture now tracks the pointer's true travel (`globalPosition`) instead of its position relative to the handle, which moves with the pane during the drag.
  - 修复拖拽分割线卡顿 / 漂移：手势改用指针的真实行程（`globalPosition`）而非相对 handle 的局部坐标——后者会在拖拽时随 pane 移动而自我反馈。
- Fixed a listener leak: the `paneSideListenable` listener registered by `ZeroRouterDelegate` is now removed in `dispose`, so a long-lived listenable no longer holds the delegate after disposal (which could fire `notifyListeners` on a dead object).
  - 修复监听器泄漏：`ZeroRouterDelegate` 注册的 `paneSideListenable` listener 现在会在 `dispose` 中移除，长生命周期的 listenable 不再在 delegate 销毁后持有它（避免对已销毁对象触发 `notifyListeners`）。

## 0.1.1

### Fixed / 修复
- Fixed the published package links: `homepage` and `repository` now point at the GitHub repository (`zero-adaptive-link`), and `documentation` points at the GitHub Pages site, so the links shown on pub.dev resolve instead of returning 404.
  - 修复已发布包的链接：`homepage` 与 `repository` 现在指向 GitHub 仓库（`zero-adaptive-link`），`documentation` 指向 GitHub Pages 站点，pub.dev 上展示的链接可正常访问而不再返回 404。
- Fixed the documentation site's `basePath` and `assetPrefix` to match the Pages project path, so the site's CSS and JavaScript load instead of 404-ing (which left the pages unstyled).
  - 修复文档站的 `basePath` 与 `assetPrefix` 以匹配 Pages 项目路径，使站点的 CSS 与 JavaScript 能正常加载而不再 404（此前会导致页面无样式）。

## 0.1.0

### Added / 新增
- Added the `ZeroLink` widget: one declarative tap target whose behavior adapts to the window width — push a new page on compact / medium, expand or update the right sidebar pane on expanded, and focus an already visible pane instead of duplicating it.
  - 新增 `ZeroLink` 组件：一套声明式点击目标，行为随窗口宽度自适应——compact / medium 推入新页面，expanded 展开或更新右侧侧栏 pane，目标 pane 已可见时聚焦而非重复展开。
- Added `ZeroNav`, the imperative entry point with the same verbs as `NavigatorState` (`pushNamed`, `pushReplacementNamed`, `pushNamedAndRemoveUntil`, `popAndPushNamed`, `pop`, `maybePop`, `popFrom`, `maybePopFrom`, `popUntil`, `canPop`), plus `namedLocation` and `refresh` helpers.
  - 新增 `ZeroNav` 命令式入口，导航动词与 `NavigatorState` 同名同签名（`pushNamed`、`pushReplacementNamed`、`pushNamedAndRemoveUntil`、`popAndPushNamed`、`pop`、`maybePop`、`popFrom`、`maybePopFrom`、`popUntil`、`canPop`），并提供 `namedLocation` 与 `refresh` 辅助方法。
- Added the declarative route table: `ZeroRouter`, `ZeroShell`, `ZeroTab` and `ZeroRoute` with nested routes, `:param` segments, `name`, `title`, route-level and router-level `redirect` (with a `redirectLimit` of 5), `onExit`, `fullscreen` / `fullscreenDialog`, `opaque`, `barrierColor`, `barrierDismissible`, `transitionsBuilder` and `errorBuilder`.
  - 新增声明式路由表：`ZeroRouter`、`ZeroShell`、`ZeroTab` 与 `ZeroRoute`，支持嵌套路由、`:param` 片段、`name`、`title`、路由级与路由表级 `redirect`（`redirectLimit` 默认 5）、`onExit`、`fullscreen` / `fullscreenDialog`、`opaque`、`barrierColor`、`barrierDismissible`、`transitionsBuilder` 与 `errorBuilder`。
- Added the master-detail pane semantics: `SlidingPanes` (1/2 columns, slide-in detail with parallax master, draggable resize handle), `SlidingPane`, `Breadcrumbs`, `Breakpoints` and `BreakpointClass` — all usable without the router.
  - 新增 master-detail pane 语义：`SlidingPanes`（单列 / 双列、detail 右滑入带 master 视差、可拖拽分割线）、`SlidingPane`、`Breadcrumbs`、`Breakpoints` 与 `BreakpointClass`——均可脱离路由单独使用。
- Added configurable pane expansion direction: `SlidingPanesSide` plus the `side` / `paneSide` / `paneSideListenable` options, so the detail pane expands to the right (default, master on the left) or to the left (master on the right) — and `paneSideListenable` flips it at runtime without rebuilding the router.
  - 新增可配置的展开方向：`SlidingPanesSide` 及 `side` / `paneSide` / `paneSideListenable` 选项，使 detail pane 可向右（默认，master 在左）或向左（master 在右）展开；`paneSideListenable` 可在运行时切换而无需重建路由。
- Added configurable pane sizing: `leftPaneFraction` on `ZeroRouter` (the initial master pane fraction, previously fixed at `0.4`) and `maxLeftPaneWidth` on `ZeroRouter` / `SlidingPanes` — a pixel ceiling so the master pane still scales with the window but stops at a sane width on ultra-wide displays, with the detail pane absorbing the remainder. The ceiling applies to dragging too.
  - 新增可配置的 pane 尺寸：`ZeroRouter` 上的 `leftPaneFraction`（master pane 初始占比，此前固定 `0.4`）与 `ZeroRouter` / `SlidingPanes` 上的 `maxLeftPaneWidth`——像素上限，使 master pane 仍随窗口缩放，但在超宽屏上停在合理宽度，剩余空间由 detail pane 吸收；拖拽同样受该上限约束。
- Added window-width breakpoints (`600` / `840`) decoupled from the device type, so foldables, small desktop windows and browser zoom all classify correctly.
  - 新增基于窗口宽度的断点（`600` / `840`），与设备类型解耦，折叠屏、桌面小窗与浏览器缩放都能正确归类。
- Added URL addressability and deep links: every screen is in the route table, the web defaults to the hash strategy (`/#/products/42`) so GitHub Pages needs no 404 fallback, and browser back, refresh and deep links share the same location pipeline as in-app navigation.
  - 新增 URL 可寻址与深链：每个页面都入表，Web 默认 hash 策略（`/#/products/42`），GitHub Pages 无需 404 fallback；浏览器返回、刷新、深链与应用内导航走同一条 location 管道。
- Added `ZeroShellChrome` for the compact bottom `NavigationBar` rendered inside branch pages, so modal bottom sheets opened with `useRootNavigator: false` can cover it; pushed pages hide it by default (`hidesBottomBarWhenPushed`).
  - 新增 `ZeroShellChrome`：compact 底部 `NavigationBar` 渲染进 branch 页面内部，`useRootNavigator: false` 打开的 bottom sheet 可覆盖它；push 的页面默认隐藏底部栏（`hidesBottomBarWhenPushed`）。
- Added `ZeroShellScope`, `ZeroShellState`, `ZeroPaneScope`, `ZeroRouteState` and `ZeroRouteStateScope` for reading shell state, pane titles, path / query parameters and arguments from anywhere in the tree.
  - 新增 `ZeroShellScope`、`ZeroShellState`、`ZeroPaneScope`、`ZeroRouteState` 与 `ZeroRouteStateScope`，可在树中任意位置读取 shell 状态、pane 标题、路径 / 查询参数与 arguments。
- Added `ZeroNav.locationListenable`, a `ValueListenable<String>` for reactive UI via `ValueListenableBuilder` (zero runtime dependencies, no signals).
  - 新增 `ZeroNav.locationListenable`：`ValueListenable<String>`，可通过 `ValueListenableBuilder` 做响应式 UI（零运行时依赖，不用 signals）。
