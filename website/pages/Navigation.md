# Navigation / 导航

All verbs share their names and signatures with `NavigatorState`.

所有导航动词与 `NavigatorState` 同名同签名。

## Verbs / 动词表

| Verb | Description |
| --- | --- |
| `pushNamed(location)` | Push; the returned future is completed by `pop(result)` / push；返回的 Future 由 `pop(result)` 完成 |
| `pushReplacementNamed(location)` | Replace the top entry in place / 原地替换栈顶条目 |
| `pushNamedAndRemoveUntil(location, predicate)` | Remove entries until `predicate` holds, then push / 移除条目直到 `predicate` 成立后 push |
| `popAndPushNamed(location)` | Pop the current entry and push / pop 当前条目并 push |
| `pop([result])` | Pop the top entry, completing its future with `result` / pop 栈顶条目，以 `result` 完成其 Future |
| `maybePop([result])` | Ask the top page's `PopScope`, then the route's `onExit`, then pop / 先问顶层页面 `PopScope`，再问路由 `onExit`，最后 pop |
| `popFrom(context)` / `maybePopFrom(context)` | Act on the layer enclosing `context` (dialog / sheet / page) / 作用于包裹 `context` 的层（dialog / sheet / page） |
| `popUntil(predicate)` | Pop until the top entry satisfies `predicate` / 持续 pop 直到栈顶满足 `predicate` |
| `canPop` | Whether a pop would remove something / pop 是否会移除某些内容 |

## Pop semantics / pop 语义

```text
maybePop()
  ├─ fullscreen overlay open → consult its onExit → pop the overlay
  ├─ tab stack deeper than root
  │    ├─ consult the top route's onExit (false → consume the request)
  │    ├─ compact / medium: the branch Navigator's maybePop (PopScope, local history)
  │    └─ expanded: the shell route's PopScope, then collapse the right pane
  └─ tab root
       ├─ consult the root route's onExit (false → consume, the app stays alive)
       ├─ the branch root / shell route's PopScope decides
       └─ nobody handles it → the app exits (SystemNavigator.pop)
```

The AppBar back button, the Android system back, the browser back button and Escape all flow through `maybePop`.

AppBar 返回、Android 系统返回、浏览器返回与 Escape 都走 `maybePop`。

## Exit confirmation / 退出确认

Put a `PopScope` on the shell builder or a tab root page:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    showDialog(
      context: context,
      // Share the shell navigator so the next system back works normally.
      // 共享 shell navigator，使下一次系统返回行为正常。
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: const Text('Leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  },
  child: child,
)
```

Compatible with Android predictive back. The root-state Escape key does not trigger it.

兼容 Android predictive back。根态 Escape 键不触发它。

## Real web anchors / 真实 web 锚点

`ZeroLink` is a widget-level link. On the web you may want a **genuine DOM `<a href>`** instead, so the browser can offer "open in new tab", "copy link address" and link previews. `ZeroAnchor` renders exactly that, while clicks still flow through the router (no full page reload).

`ZeroLink` 是组件级链接。在 web 上你可能想要**真正的 DOM `<a href>`**，让浏览器能提供「在新标签中打开」「复制链接地址」与链接预览。`ZeroAnchor` 渲染的就是它，而点击依旧经由路由（不会整页刷新）。

```dart
ZeroAnchor(
  location: '/products/42',
  label: 'Product 42',
)
```

Notes / 说明：

- `ZeroAnchor` takes a `label` (text), not a `child` widget — it maps to the anchor's `textContent`. Off-web platforms fall back to a plain `ZeroLink`, so the same code works everywhere.
  `ZeroAnchor` 接收 `label`（文本）而非 `child` 组件——它对应锚点的 `textContent`。非 web 平台会回退为普通 `ZeroLink`，因此同一份代码各端通用。
- Because navigation flows through the hash URL, an anchor always uses link / push semantics (the browser owns the history entry). Use `ZeroLink` for `replacement` / `popAndPush`.
  由于导航经由 hash URL 流转，锚点始终使用链接 / push 语义（历史条目由浏览器掌管）。需要 `replacement` / `popAndPush` 请用 `ZeroLink`。
- `ZeroRouter.canonicalHref(location)` returns the shareable hash URL for any location (`#/products/42`) — handy for "copy link" buttons and previews, including nested deep links such as `#/settings/profile`.
  `ZeroRouter.canonicalHref(location)` 返回任意 location 的可分享 hash URL（`#/products/42`）——适合「复制链接」按钮与预览，嵌套深链（如 `#/settings/profile`）同样适用。

## Browser back on the web / Web 浏览器返回

In-app navigation pushes a history entry (`history.pushState`); browser back / forward feeds a new location into the same pipeline, which rebuilds the stacks from the URL. Back collapses the rightmost pane one level at a time.

应用内导航会压入一条历史记录（`history.pushState`）；浏览器前进后退把新 location 送入同一条管道，按 URL 重建各栈。返回键逐级收起最右 pane。
