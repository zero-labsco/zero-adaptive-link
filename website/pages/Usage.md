# Usage / 使用

## Two entry points / 两种入口

### Declarative: `ZeroLink` / 声明式

```dart
ZeroLink(
  location: '/products/42',
  child: const ListTile(title: Text('Product 42')),
);
```

`ZeroLink` wraps its child in `GestureDetector + MouseRegion` (hand cursor on web / desktop) and does not require a Material ancestor. Pass `onTap` to override the default open behavior.

`ZeroLink` 用 `GestureDetector + MouseRegion` 包裹子组件（web / 桌面显示手型光标），不强制 Material 祖先。传 `onTap` 可覆盖默认行为。

### Imperative: `ZeroNav` / 命令式

```dart
ZeroNav.of(context).open('/products/42');
ZeroNav.of(context).location;                    // '/products/42'
ZeroNav.of(context).canPop;                      // true when a pop would remove something
```

`ZeroNav.of(context)` must be called below a `ZeroRouter`; use `ZeroNav.maybeOf(context)` when the router is optional.

`ZeroNav.of(context)` 必须在 `ZeroRouter` 之下调用；路由可选时用 `ZeroNav.maybeOf(context)`。

## The `onTap` decision flow / `onTap` 决策流

```text
tap ZeroLink(location)
  │
  ├─ window width < 600   (compact)  → Navigator.push a new page
  ├─ window width 600–839 (medium)   → Navigator.push a new page (single column)
  └─ window width >= 840  (expanded) → expand / update the right pane
                                       └─ pane already visible → focus it (idempotent)
```

## Reading route state / 读取路由状态

```dart
// Inside a matched page (no BuildContext needed for the title)
ZeroRouteState.of(context).pathParameters;   // {'id': '42'}
ZeroRouteState.of(context).queryParameters;  // {'tab': 'specs'}
ZeroRouteState.of(context).arguments;        // navigation-time extras
ZeroRouteState.of(context).fullPath;         // '/products/:id'
ZeroRouteState.of(context).uri;              // Uri with query

// Shell state from anywhere / 任意位置读取 shell 状态
ZeroShellScope.maybeOf(context)?.isExpanded;
ZeroShellScope.maybeOf(context)?.currentIndex;
ZeroShellScope.maybeOf(context)?.goTab(1, initialLocation: '/cart');

// Pane title (non-null only inside two-column panes)
ZeroPaneScope.maybeOf(context)?.title;
```

## Reactive UI / 响应式 UI

```dart
ValueListenableBuilder<String>(
  valueListenable: ZeroNav.of(context).locationListenable,
  builder: (context, location, child) => Text(location),
);
```

## Compact chrome / compact 底部栏

```dart
ZeroShell(
  builder: (context, shell, child) => shell.isCompact
      ? ZeroShellChrome(
          bottomNavigationBar: (context) => NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: shell.goTab,
            destinations: const [ /* … */ ],
          ),
          child: child,
        )
      : Row(children: [NavigationRail(/* … */), Expanded(child: child)]),
  tabs: [ /* … */ ],
)
```

The bar is rendered **inside** branch pages, so a modal bottom sheet opened with `useRootNavigator: false` covers it, and the system back button closes the sheet first. Pushed pages hide the bar by default (`hidesBottomBarWhenPushed: true`, can be turned off per route).

底部栏渲染进 branch 页面**内部**，因此 `useRootNavigator: false` 打开的 bottom sheet 可覆盖它，系统返回键先关闭 sheet。push 的页面默认隐藏底部栏（`hidesBottomBarWhenPushed: true`，可按路由关闭）。

## Fullscreen overlays / 全屏覆盖层

```dart
ZeroRoute(
  path: 'preview',
  fullscreen: true,          // covers the shell (including its chrome) at any width
  opaque: false,             // translucent
  barrierColor: Color(0x99000000),
  barrierDismissible: true,  // tap the barrier to dismiss
  builder: (context, state) => const PreviewPage(),
)
```

`fullscreen` / `fullscreenDialog` routes sit on a root navigator above the shell, so they cover the rail / bottom bar at every width.

`fullscreen` / `fullscreenDialog` 路由位于 shell 之上的根 navigator，因此在任何宽度下都能覆盖 rail / 底部栏。
