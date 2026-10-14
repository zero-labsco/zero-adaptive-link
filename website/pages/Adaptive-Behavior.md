# Adaptive Behavior / 自适应行为

## Behavior matrix / 行为矩阵

| Window width | Class | `onTap` behavior |
| --- | --- | --- |
| `< 600` | compact | push a new page (classic Navigator stack) / push 新页面（经典 Navigator 栈） |
| `600 – 839` | medium | push a new page (single column, different shell chrome) / push 新页面（单列，shell chrome 不同） |
| `>= 840` | expanded | expand / update the right sidebar pane (master-detail) / 展开或更新右侧侧栏 pane（master-detail） |

## Breakpoints / 断点

```dart
class Breakpoints {
  const Breakpoints({this.compactMaxWidth = 600, this.expandedMinWidth = 840});
}
```

Classification is based on the **window width**, deliberately decoupled from the device type, so foldables, small desktop windows and browser zoom all classify correctly. Pass your own `Breakpoints` to `ZeroRouter(breakpoints: …)`.

档位判定依据是**窗口宽度**（与设备类型刻意解耦），折叠屏、桌面小窗、浏览器缩放都能正确归类。可向 `ZeroRouter(breakpoints: …)` 传入自定义断点。

The width is read from `MediaQuery` (which hosts, tests and the example's width presets can override), falling back to the layout constraints.

宽度读取自 `MediaQuery`（宿主、测试与示例的宽度预设均可覆盖），回退到布局约束。

## Pane semantics (expanded) / pane 语义（expanded）

| Scenario | Behavior |
| --- | --- |
| Target extends the current right pane (`/products` → `/products/42`) | New pane slides in from the right; the old pane shifts left / 新 pane 右滑入，旧 pane 左移 |
| Same branch, not a prefix (`/products/41` → `/products/42`) | A leaf is appended to the stack; the viewport shows the last two panes, so the right pane updates in place / 栈上追加叶子；视口只显示最后两个 pane，右 pane 原地更新 |
| Target location already visible | Focus that pane, no duplicate expansion (idempotent) / 聚焦该 pane，不重复展开（幂等） |
| `pushReplacementNamed` | The right pane is replaced in place / 右 pane 原地替换 |
| Cross-tab | Switch tabs and rebuild that tab's stack from the URL / 切换 tab，并按 URL 重建该 tab 的栈 |
| `pop` / `maybePop` | Collapse the rightmost pane; when the tab stack is exhausted, step toward the root / 收起最右 pane；tab 栈无栈可退时逐级向根退 |

`SlidingPanes` only does 1/2 columns; three or more columns are out of scope for v0.1.0.

`SlidingPanes` 只做单列 / 双列；三列及以上不在 v0.1.0 范围内。

## Cross-breakpoint rebuilds / 跨断点重建

Crossing the 840 boundary rebuilds page State (Navigator tree ↔ viewport tree). Keep persistent state in the URL, an external store, or a signal — not in page-local State — and read `Caveats` in the [FAQ](FAQ).

跨越 840 边界会重建页面 State（Navigator 树 ↔ 视口树）。持久状态请放 URL、外部 store 或 signal，不要放在页面局部 State；详见 [FAQ](FAQ) 的 Caveats。

## Customization / 定制点

| Parameter | Default | Effect |
| --- | --- | --- |
| `slideDuration` | 280ms | Pane slide duration / pane 滑动时长 |
| `slideCurve` | `Curves.easeOutCubic` | Pane slide curve / pane 滑动曲线 |
| `paneBuilder` | Card when wide, flat when narrow | Wraps each pane / 包裹每个 pane |
| `resizeHandleBuilder` | Rounded animated bar | `Widget Function(BuildContext, bool isHovered)` |
| `resizeHandleWidth` | 4 | Hit width of the handle / 分割线命中宽度 |
| `placeholder` | Outline icon | Shell-level empty right pane; `ZeroTab.placeholder` wins / shell 级空右 pane；`ZeroTab.placeholder` 优先 |
| `showBreadcrumbs` | `true` | Master switch for the breadcrumb bar / 面包屑栏总开关 |
| `breadcrumbsBuilder` | `InkWell + Text` bar | Custom breadcrumb bar / 自定义面包屑栏 |
| `escapePops` | `true` | Escape pops one level / Escape 退一级 |
| 1-column transitions | `ThemeData.pageTransitionsTheme` | No private transition hiding / 不私藏转场 |
