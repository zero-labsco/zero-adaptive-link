# FAQ / 常见问题

## Crossing the 840 boundary rebuilds page State — why? / 跨越 840 边界会重建页面 State，为什么？

The widget tree switches between the Navigator representation (compact / medium) and the viewport representation (expanded), so page State is rebuilt. Keep persistent state in the URL, an external store, or a signal — not in page-local State.

组件树会在 Navigator 形态（compact / medium）与视口形态（expanded）之间切换，因此页面 State 会重建。持久状态请放 URL、外部 store 或 signal，不要放在页面局部 State。

## Why does a bottom sheet opened with `useRootNavigator: false` cover the compact bottom bar? / 为什么 `useRootNavigator: false` 打开的 bottom sheet 能覆盖 compact 底部栏？

The bottom bar is rendered **inside** the branch pages (via `ZeroShellChrome`), so a sheet inserted into the same (branch) navigator's overlay sits above it. The system back button closes the sheet first because the sheet registers a local history entry with that route.

底部栏渲染进 branch 页面**内部**（通过 `ZeroShellChrome`），因此插入同一（branch）navigator overlay 的 sheet 位于其上方。系统返回键先关闭 sheet，因为 sheet 在该 route 上注册了局部历史条目。

## Why the hash strategy on the web? / 为什么 Web 用 hash 策略？

`/#/products/42` works on GitHub Pages without a 404 fallback, and refresh, deep links and browser back all share the same location pipeline as in-app navigation. In-app navigation uses `history.pushState` (no `hashchange` echo); browser back / forward is observed via `popstate` / `hashchange`.

`/#/products/42` 在 GitHub Pages 上无需 404 fallback 即可工作，刷新、深链与浏览器返回都与应用内导航走同一条 location 管道。应用内导航使用 `history.pushState`（不会触发 `hashchange` 回环）；浏览器前进后退通过 `popstate` / `hashchange` 监听。

## Why is the initial platform route preferred over `initialLocation`? / 为什么平台初始 route 优先于 `initialLocation`？

A deep link (`https://host/#/products/42`, an Android intent route, …) must win over the configured default, otherwise deep links would silently open the wrong screen. `initialLocation` only applies when the platform starts at `/` (or empty).

深链（`https://host/#/products/42`、Android intent route 等）必须优先于配置的默认值，否则深链会静默打开错误的页面。只有平台以 `/`（或空）启动时才使用 `initialLocation`。

## My page does not rebuild when the location changes. / 页面为什么不随 location 变化而重建？

`ZeroNav.of(context).location` is a build-time value. Subscribe with `locationListenable` for reactive UI:

`ZeroNav.of(context).location` 是构建时取值。响应式 UI 请订阅 `locationListenable`：

```dart
ValueListenableBuilder<String>(
  valueListenable: ZeroNav.of(context).locationListenable,
  builder: (context, location, child) => Text(location),
)
```

## `pushNamed` returns a future that never completes. / `pushNamed` 返回的 Future 为什么不完成？

By design: it is completed by `pop(result)`, mirroring `Navigator.pushNamed`. Do not `await` it unless you intend to wait for the pop.

这是刻意设计：它由 `pop(result)` 完成，与 `Navigator.pushNamed` 一致。除非打算等待 pop，否则不要 `await` 它。

## Can I push a route that is not in the table? / 可以 push 一个不在路由表里的 route 吗？

No. Every page must be in the table so its URL can express it (deep links, refresh, browser back). Unmatched locations render `errorBuilder`.

不可以。每个页面都必须入表，URL 才能表达它（深链、刷新、浏览器返回）。未匹配的 location 渲染 `errorBuilder`。

## Why does the system back button sometimes not exit the app? / 为什么系统返回键有时不退出应用？

At a tab root, `maybePop` is a no-op; the request then reaches the branch root / shell route's `PopScope`, and only an unhandled request exits the app. A `PopScope(canPop: false)` on the shell (or a route `onExit` returning `false`) deliberately keeps the app alive.

在 tab 根处 `maybePop` 为 no-op；请求随后到达 branch root / shell route 的 `PopScope`，只有无人处理的请求才会退出应用。shell 上的 `PopScope(canPop: false)`（或路由 `onExit` 返回 `false`）会刻意让应用保持存活。

## Are there runtime dependencies? / 有运行时依赖吗？

None. The plugin is pure Dart and uses only `ValueNotifier` / `InheritedWidget` (plus `dart:js_interop` on the web for the hash strategy).

没有。本插件为纯 Dart，仅使用 `ValueNotifier` / `InheritedWidget`（Web 上为 hash 策略额外使用 `dart:js_interop`）。
