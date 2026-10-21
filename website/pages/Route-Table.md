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

## Nested shells / 嵌套 shell

A `ZeroRoute` can host another `ZeroShell` via `shell`; its `shellBuilder` receives the nested shell widget as `child` (return it as-is to render the nested shell unchanged). Route tables therefore nest arbitrarily deep: each shell derives its own active tab and renders its own tabs / panes from the same flat location stack, so a deep link such as `#/settings/profile` restores both the outer and the nested tab.

`ZeroRoute` 可通过 `shell` 承载另一个 `ZeroShell`，其 `shellBuilder` 会以嵌套 shell 组件作为 `child` 收到（原样返回即渲染该嵌套 shell）。因此路由表可任意深度嵌套：每个 shell 都从同一份扁平 location 栈推导自己的活动 tab 并渲染自身的 tabs / panes，`#/settings/profile` 这样的深链会同时恢复外层与内层 tab。

```dart
ZeroRoute(
  path: '/settings',
  shell: ZeroShell(
    builder: (context, shell, child) => /* inner rail / bar + child */,
    tabs: [
      ZeroTab(initialLocation: '/settings/profile', routes: [ /* … */ ]),
      ZeroTab(initialLocation: '/settings/account', routes: [ /* … */ ]),
    ],
  ),
  // `child` is the nested shell; return it as-is to render it unchanged.
  // `child` 即嵌套 shell；原样返回即渲染它。
  shellBuilder: (context, state, child) => child,
)
```

Two conventions to keep in mind / 需要留意的两点约定:

- A hosted route uses `shellBuilder` **instead of** `builder` — the two are mutually exclusive.
  被承载的路由使用 `shellBuilder` **而非** `builder`，二者互斥。
- A nested tab's `initialLocation` is a **full** location (`/settings/profile`), while its route paths are authored relative to the host (`/profile`).
  嵌套 tab 的 `initialLocation` 是**完整** location（`/settings/profile`），而其路由路径相对宿主书写（`/profile`）。

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
| `shell` | `ZeroShell?` | Host a nested shell inside this route / 在本路由内承载嵌套 shell |
| `shellBuilder` | `Widget Function(BuildContext, ZeroRouteState, Widget)?` | Builder for a route that hosts [shell]; `child` is the nested shell / 承载 [shell] 的路由的 builder；`child` 为嵌套 shell |

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
