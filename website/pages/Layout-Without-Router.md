# Layout Without Router / 脱离路由使用布局

`SlidingPanes`, `SlidingPane` and `Breadcrumbs` are public widgets usable on their own — you do not need a `ZeroRouter` for a two-column layout.

`SlidingPanes`、`SlidingPane` 与 `Breadcrumbs` 均为公开组件，可单独使用——双列布局无需引入 `ZeroRouter`。

## `SlidingPanes` / 双列滑动布局

```dart
SlidingPanes(
  children: [masterPane, detailPane],
  leftPaneFraction: 0.4,                     // 0.15 – 0.85
  slideDuration: const Duration(milliseconds: 280),
  slideCurve: Curves.easeOutCubic,
  resizeHandleWidth: 4,
  resizeHandleBuilder: (context, isHovered) => const SizedBox(width: 4),
  paneBuilder: (context, pane, isLeft) => Card(child: pane),
  onLeftPaneFractionChanged: (fraction) => …,        // per drag frame / 逐帧
  onLeftPaneFractionDragEnd: (fraction) => …,        // once per drag / 每轮拖拽一次
)
```

- One child → a single column; two children → master-detail.
  一个子组件为单列；两个为 master-detail。
- Growing from one to two children slides the detail in from the side set by `side` while the master yields the opposite side; shrinking reverses the animation.
  从 1 个变为 2 个时 detail 从 `side` 指定的一侧滑入、master 让出相反一侧；变回 1 个时动画反向。
- The detail expands to the **right** by default (`side: SlidingPanesSide.right`, master on the left). Set `side: SlidingPanesSide.left` to mirror the layout — master on the right, detail slides in from the left.
  默认 detail 向**右**展开（`side: SlidingPanesSide.right`，master 在左）。设 `side: SlidingPanesSide.left` 可镜像布局——master 在右、detail 从左滑入。
- The default `paneBuilder` renders a card when the pane is wide and a flat surface when narrow.
  默认 `paneBuilder`：pane 较宽时呈现为卡片，较窄时保持扁平。
- Drag the resize handle to change `leftPaneFraction`.
  `onLeftPaneFractionChanged` streams per frame; `onLeftPaneFractionDragEnd`
  fires once with the final fraction (the commit point).
  拖拽分割线调整 `leftPaneFraction`。`onLeftPaneFractionChanged` 逐帧回调；
  `onLeftPaneFractionDragEnd` 只触发一次并带最终比例（提交点）。

```dart
SlidingPanes(
  side: SlidingPanesSide.left,   // master on the right, detail from the left
  maxLeftPaneWidth: 360,         // stop growing on ultra-wide windows
  children: [masterPane, detailPane],
)
```

`leftPaneFraction` scales the master pane with the window (0.15 – 0.85);
`maxLeftPaneWidth` optionally caps it in pixels, so on an ultra-wide window the
detail pane absorbs the remainder instead of both columns stretching. Dragging
the resize handle respects the ceiling too.

`leftPaneFraction` 让 master pane 随窗口缩放（0.15 – 0.85）；`maxLeftPaneWidth`
可用像素为其设上限，这样在超宽窗口上由 detail pane 吸收剩余空间，而不是两栏
一起被拉宽。拖拽分割线同样受该上限约束。

With the router, set `paneSide` on `ZeroRouter` (or drive it live with `paneSideListenable`) to flip the expanded layout at runtime, and `leftPaneFraction` / `maxLeftPaneWidth` to control the split.

配合路由时，在 `ZeroRouter` 上设置 `paneSide`（或用 `paneSideListenable` 实时驱动）切换展开方向，并用 `leftPaneFraction` / `maxLeftPaneWidth` 控制分栏比例。

## `SlidingPane` / 单个 pane 表面

```dart
SlidingPane(
  elevation: 1,
  margin: const EdgeInsets.all(6),
  borderRadius: BorderRadius.circular(12),
  child: myPaneContent,
)
```

## `Breadcrumbs` / 面包屑栏

```dart
Breadcrumbs(
  items: ['/products', '/products/42'],
  onNavigate: (index) => popTo(index),
  separator: '›',
)
```

An `InkWell + Text` row that reports the tapped index; it brings its own transparent `Material` ancestor, so it works standalone.

由 `InkWell + Text` 组成的一行，回调被点击的下标；自带透明 `Material` 祖先，可独立使用。

## `Breakpoints` / 断点

```dart
const breakpoints = Breakpoints(); // 600 / 840
breakpoints.classify(width);       // BreakpointClass.compact / medium / expanded
```
