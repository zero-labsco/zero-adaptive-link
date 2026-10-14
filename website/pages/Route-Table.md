# Route Table / 路由表

Every screen must be in the route table so its URL can express it — that is why there is no non-named `push(Route)`.

每个页面都必须入表，URL 才能表达它——因此没有非命名的 `push(Route)`。

## Structure / 结构

```dart
ZeroRouter(
  initialLocation: '/products',
  redirect: (location) => location == '/secret' ? '/login' : null,
  redirectLimit: 5,
  errorBuilder: (context, location) => Text('No route matches $location'),
  routes: [
    ZeroShell(
      builder: (context, shell, child) => /* … */,
      placeholder: const SizedBox.shrink(),
      tabs: [
        ZeroTab(initialLocation: '/products', placeholder: …, routes: [ /* … */ ]),
        ZeroTab(routes: [ /* … */ ]),
      ],
    ),
  ],
)
```

One `ZeroShell` is supported in v0.1.0 (no nested shells).

v0.1.0 仅支持一个 `ZeroShell`（不支持嵌套 shell）。

## `ZeroRoute` parameters / `ZeroRoute` 参数

| Parameter | Type | Description |
| --- | --- | --- |
| `path` | `String` | Pattern relative to the parent; `:param` matches one segment / 相对父路径的 pattern；`:param` 匹配单个片段 |
| `name` | `String?` | Name for `namedLocation` / 供 `namedLocation` 使用 |
| `builder` | `Widget Function(BuildContext, ZeroRouteState)` | Page content / 页面内容 |
| `title` | `String Function(ZeroRouteState)?` | Evaluated once at match time, no `BuildContext` / match 时求值一次，无 `BuildContext` |
| `redirect` | `FutureOr<String?> Function(ZeroRouteState)?` | Route-level redirect / 路由级重定向 |
| `onExit` | `FutureOr<bool> Function()?` | Veto hook consulted before popping / pop 前询问的否决钩子 |
| `fullscreen` | `bool` | Cover the shell at any width / 任何宽度下覆盖 shell |
| `fullscreenDialog` | `bool` | Present as a full-screen dialog / 以全屏对话框呈现 |
| `hidesBottomBarWhenPushed` | `bool` | Hide the compact bottom bar (default `true`) / 隐藏 compact 底部栏（默认 `true`） |
| `opaque` | `bool` | Route opacity / 路由不透明度 |
| `barrierColor` | `Color?` | Modal barrier color / 模态屏障颜色 |
| `barrierDismissible` | `bool` | Tap the barrier to dismiss / 点击屏障关闭 |
| `transitionsBuilder` | `RouteTransitionsBuilder?` | Custom transitions / 自定义转场 |
| `routes` | `List<ZeroRoute>` | Nested routes / 嵌套路由 |

## Matching rules / 匹配规则

- Child paths are relative to the parent: `:id` under `/products` matches `/products/:id`.
  子路径相对父路径：`/products` 下的 `:id` 匹配 `/products/:id`。
- The **first match wins**; a route that matches a prefix but has no matching child lets the next sibling try.
  **首个匹配获胜**；匹配了前缀但子路由未匹配剩余部分时，交由下一个同级路由尝试。
- `:param` matches exactly one path segment; the value lands in `pathParameters`.
  `:param` 只匹配单个路径片段；取值进入 `pathParameters`。
- Unmatched locations render `errorBuilder` (a default error page is used when omitted).
  未匹配的 location 渲染 `errorBuilder`（省略时使用默认错误页）。

## Redirects / 重定向

```dart
ZeroRouter(
  // Router-level: consulted for every location.
  // 路由表级：对每个 location 生效。
  redirect: (location) =>
      location.startsWith('/mine') && !loggedIn ? '/login?from=$location' : null,
  redirectLimit: 5,
  routes: [ /* … */ ],
)

ZeroRoute(
  path: '/old',
  // Route-level: consulted when this route matches.
  // 路由级：该路由匹配时询问。
  redirect: (state) => '/new',
  builder: (context, state) => const OldPage(),
)
```

Both may be async (`FutureOr<String?>`). More than `redirectLimit` hops (default 5) lands on `errorBuilder`.

两者均可为异步（`FutureOr<String?>`）。超过 `redirectLimit` 跳数（默认 5）后进入 `errorBuilder`。

## Named routes / 命名路由

```dart
ZeroRoute(path: ':id', name: 'product', builder: …)

ZeroNav.of(context).namedLocation(
  'product',
  pathParameters: {'id': '42'},
  queryParameters: {'tab': 'specs'},
); // '/products/42?tab=specs'
```

Returns `null` for an unknown name.

名称未知时返回 `null`。
