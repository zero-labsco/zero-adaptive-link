import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'sliding_pane.dart';

/// Which side the detail pane expands toward in a [SlidingPanes].
/// [SlidingPanes] 中 detail pane 展开所朝向的一侧。
///
/// `right` keeps the master on the left and slides the detail in from the
/// right (the default); `left` mirrors it — master on the right, detail slides
/// in from the left.
/// `right` 让 master 居左、detail 从右滑入（默认）；`left` 则镜像——master 居右、
/// detail 从左滑入。
enum SlidingPanesSide {
  /// Master on the left, detail slides in from the right.
  /// master 在左，detail 从右滑入。
  right,

  /// Master on the right, detail slides in from the left.
  /// master 在右，detail 从左滑入。
  left,
}

/// Signature for wrapping each pane of a [SlidingPanes].
/// 包裹 [SlidingPanes] 每个 pane 的回调签名。
///
/// [isLeft] is `true` when this pane is physically positioned on the left side
/// of the layout — the master when [SlidingPanes.side] is
/// [SlidingPanesSide.right], the detail when it is [SlidingPanesSide.left].
/// [isLeft] 为 `true` 表示该 pane 在布局中物理上位于左侧——当 [SlidingPanes.side]
/// 为 [SlidingPanesSide.right] 时是 master，为 [SlidingPanesSide.left] 时是 detail。
typedef SlidingPaneBuilder =
    Widget Function(BuildContext context, Widget pane, bool isLeft);

/// Signature for the draggable resize handle between the two panes.
/// 两个 pane 之间可拖拽分割线的回调签名。
typedef SlidingResizeHandleBuilder =
    Widget Function(BuildContext context, bool isHovered);

/// A one-or-two column sliding layout (master-detail).
/// 单列 / 双列滑动布局（master-detail）。
///
/// When [children] grows from one to two entries the detail pane slides in from
/// the side set by [side] (right by default) while the master pane yields the
/// opposite side; when it shrinks back the animation reverses. Set [side] to
/// [SlidingPanesSide.left] to mirror the layout — master on the right, detail
/// slides in from the left. Three or more columns are out of scope for v0.1.0.
/// 当 [children] 从 1 个变为 2 个时，detail pane 从 [side] 指定的一侧（默认右侧）
/// 滑入、master pane 让出相反一侧；变回 1 个时动画反向。将 [side] 设为
/// [SlidingPanesSide.left] 可镜像布局——master 在右、detail 从左滑入。三列及以上
/// 不在 v0.1.0 范围内。
///
/// When the **master** is replaced while two columns are shown (a deeper push:
/// the old detail becomes the new master), the viewport slides left by one
/// column — the replaced master exits on the master side while the new pair
/// slides in from the detail side. Give the pane children stable keys (e.g.
/// `KeyedSubtree(key: ValueKey(location), child: pane)`) to opt in; without
/// keys the replacement happens in place. Replacing only the **detail** (e.g. a
/// `pushReplacementNamed` on the top page) always updates in place.
/// 当双列展示期间 **master** 被替换（更深层级 push：旧 detail 成为新 master）时，
/// 视口整体左移一列——被替换的 master 向 master 侧退出，新的一对从 detail 侧滑入。
/// 为 pane children 提供稳定键（如 `KeyedSubtree(key: ValueKey(location), child: pane)`）
/// 即可启用该转场；无键时替换原地发生。仅替换 **detail**（如对栈顶页面
/// `pushReplacementNamed`）始终原地更新。
///
/// Usable without any router: feed it plain widgets.
/// 无需路由即可使用：直接传入普通组件。
class SlidingPanes extends StatefulWidget {
  /// Create a sliding pane layout with one or two [children].
  /// 使用 1 个或 2 个 [children] 创建滑动 pane 布局。
  const SlidingPanes({
    required this.children,
    this.placeholder,
    this.leftPaneFraction = 0.4,
    this.maxLeftPaneWidth,
    this.side = SlidingPanesSide.right,
    this.slideDuration = const Duration(milliseconds: 280),
    this.slideCurve = Curves.easeOutCubic,
    this.resizeHandleWidth = 4,
    this.resizeHandleBuilder,
    this.paneBuilder,
    this.onLeftPaneFractionChanged,
    this.onLeftPaneFractionDragEnd,
    super.key,
  });

  /// The pane contents: one entry for a single column, two for master-detail.
  /// pane 内容：1 个为单列，2 个为 master-detail。
  final List<Widget> children;

  /// Rendered as the detail column while [children] has a single entry (an
  /// empty-detail hint, for instance). Keep it free of a `Key`: the key of the
  /// second child is how the layout tells an expand / collapse (placeholder ↔
  /// detail) from a plain rebuild.
  /// 当 [children] 只有一个条目时作为 detail 列渲染（例如空详情提示）。请勿为它
  /// 设置 `Key`：布局正是通过第二个 child 的键来区分展开 / 收起（占位内容 ↔
  /// 详情）与普通重建的。
  final Widget? placeholder;

  /// Fraction of the width taken by the master pane (0.15 – 0.85), regardless
  /// of which side it sits on.
  /// master pane 占据的宽度比例（0.15 – 0.85），不随其所在左右侧改变。
  final double leftPaneFraction;

  /// Optional pixel ceiling for the master pane. / master pane 的可选像素上限。
  ///
  /// The pane still scales with [leftPaneFraction], but never grows past this
  /// width — on an ultra-wide window the detail pane absorbs the remainder
  /// instead of both columns stretching. `null` (the default) means no ceiling.
  /// pane 仍按 [leftPaneFraction] 缩放，但绝不超过该宽度——超宽窗口上由
  /// detail pane 吸收剩余空间，而不是两栏一起被拉宽。`null`（默认）表示不设上限。
  final double? maxLeftPaneWidth;

  /// Which side the detail pane expands toward. / detail pane 展开所朝向的一侧。
  ///
  /// Defaults to [SlidingPanesSide.right] (master on the left).
  /// 默认 [SlidingPanesSide.right]（master 在左）。
  final SlidingPanesSide side;

  /// Duration of the pane slide animation. / pane 滑动时长。
  final Duration slideDuration;

  /// Curve of the pane slide animation. / pane 滑动曲线。
  final Curve slideCurve;

  /// Hit width of the resize handle. / 分割线的命中宽度。
  final double resizeHandleWidth;

  /// Builder for the resize handle; defaults to a rounded animated bar.
  /// 分割线构建器，默认为圆角动画条。
  final SlidingResizeHandleBuilder? resizeHandleBuilder;

  /// Builder wrapping each pane; defaults to a card when the pane is wide and a
  /// flat surface when narrow.
  /// 包裹每个 pane 的构建器，默认为「宽卡片 / 窄扁平」。
  final SlidingPaneBuilder? paneBuilder;

  /// Called while the user drags the resize handle.
  /// 拖拽分割线时持续回调。
  final ValueChanged<double>? onLeftPaneFractionChanged;

  /// Called once when the user releases the resize handle. Live dragging only
  /// needs the per-frame [onLeftPaneFractionChanged]; this callback is the
  /// commit point, so a listener can react once per drag instead of per frame
  /// (e.g. republishing the fraction to the rest of the app).
  /// 用户松开分割线时回调一次。实时拖拽只需要逐帧的 [onLeftPaneFractionChanged]；
  /// 本回调是「提交点」，监听者可每轮拖拽只反应一次（例如把比例发布给应用其余
  /// 部分），而非每帧一次。
  final ValueChanged<double>? onLeftPaneFractionDragEnd;

  @override
  State<SlidingPanes> createState() => _SlidingPanesState();
}

class _SlidingPanesState extends State<SlidingPanes>
    with TickerProviderStateMixin {
  /// Drives the expand (0 → 1) and collapse (1 → 0) of the detail column.
  /// 驱动 detail 列的展开（0 → 1）与收起（1 → 0）。
  late final AnimationController _revealController = AnimationController(
    vsync: this,
    duration: widget.slideDuration,
    value: 1,
  );

  /// Drives the master-replacement shift (0 → 1): the viewport slides left by
  /// one column. / 驱动 master 替换的水平转场（0 → 1）：视口整体左移一列。
  late final AnimationController _shiftController = AnimationController(
    vsync: this,
    duration: widget.slideDuration,
    value: 1,
  );

  double _fraction = 0.4;
  double _totalWidth = 0;
  double _dragStartFraction = 0.4;
  double _dragStartX = 0;
  bool _dragActive = false;
  bool _hoveringHandle = false;

  /// The detail pane kept mounted while a collapse animation plays (its entry
  /// already left the stack). / 收起动画播放期间保持挂载的 detail pane
  /// （其条目已离开栈）。
  Widget? _exitingDetail;

  /// The replaced master pane kept mounted while a shift animation plays.
  /// 水平转场播放期间保持挂载的被替换 master pane。
  Widget? _exitingMaster;

  @override
  void initState() {
    super.initState();
    _fraction = widget.leftPaneFraction;
    // Retire the exiting panes once their animation finishes: leaving them
    // mounted would keep defunct page subtrees (and their GlobalKeys) alive
    // forever. / 动画结束后即退下还在挂载的 pane：一直挂着会让已失效的页面
    // 子树（及其 GlobalKey）永不释放。
    _revealController.addStatusListener(_onRevealStatusChanged);
    _shiftController.addStatusListener(_onShiftStatusChanged);
  }

  void _onRevealStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _exitingDetail != null) {
      setState(() => _exitingDetail = null);
    }
  }

  void _onShiftStatusChanged(AnimationStatus status) {
    // Both shift directions retire their exiting pane on completion: the
    // push keeps the replaced master, the pop the exiting detail.
    // 两个方向的水平转场都在完成时退下退出中的 pane：push 保留被替换的
    // master，pop 保留退出中的 detail。
    if (status == AnimationStatus.completed &&
        (_exitingMaster != null || _exitingDetail != null)) {
      setState(() {
        _exitingMaster = null;
        _exitingDetail = null;
      });
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidingPanes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slideDuration != oldWidget.slideDuration) {
      _revealController.duration = widget.slideDuration;
      _shiftController.duration = widget.slideDuration;
    }
    final oldCount = oldWidget.children.length;
    final newCount = widget.children.length;
    // The key of the second child is the detail-pane identity: `null` means
    // "no detail" (a single column, or the placeholder column). Standalone
    // children without keys therefore never trigger a transition — which is
    // the safe default.
    // 第二个 child 的键即 detail pane 的身份标识：`null` 表示「无详情」
    // （单列，或占位列）。因此未加键的独立使用方永远不会触发转场——这是
    // 安全的默认行为。
    final oldDetailKey = oldCount >= 2 ? oldWidget.children[1].key : null;
    final newDetailKey = newCount >= 2 ? widget.children[1].key : null;
    final oldMasterKey = oldCount >= 1 ? oldWidget.children[0].key : null;
    final newMasterKey = newCount >= 1 ? widget.children[0].key : null;

    if (newCount >= 2 &&
        (oldCount < 2 ||
            oldDetailKey != newDetailKey && oldDetailKey == null)) {
      // Expand: the detail column appeared. Start hidden so the slide plays
      // (the controller starts at 1, so a bare `forward()` would be a no-op).
      // 展开：detail 列出现。从隐藏状态开始，滑动才能播放（controller 初始
      // 为 1，直接 `forward()` 是空操作）。
      // Controllers first: their status listeners may retire stale exiting
      // panes, and that must happen before the fields are reassigned.
      // 先动控制器：其状态监听器会清掉过期的退出中 pane，必须发生在字段
      // 重新赋值之前。
      _shiftController.value = 1;
      _revealController.value = 0;
      _exitingMaster = null;
      _exitingDetail = null;
      _revealController.forward();
    } else if (oldCount >= 2 &&
        (newCount < 2 || newDetailKey == null && oldDetailKey != null)) {
      // Collapse: the detail column went away. Keep the exiting detail
      // mounted for the reverse animation — unless the surviving master IS
      // that detail (same key), which would mount its GlobalKey twice.
      // 收起：detail 列消失。保持退出中的 detail 挂载以播放反向动画——除非
      // 存留的 master 就是该 detail（同键），那会让它的 GlobalKey 被挂载两次。
      _exitingMaster = null;
      _shiftController.value = 1;
      final detailIsNewMaster =
          newMasterKey != null && newMasterKey == oldDetailKey;
      _exitingDetail = detailIsNewMaster ? null : oldWidget.children[1];
      _revealController.reverse();
    } else if (newCount >= 2 &&
        oldCount >= 2 &&
        newDetailKey != null &&
        oldDetailKey != null &&
        newMasterKey != oldMasterKey) {
      // Both columns kept showing but the master moved: a one-column shift of
      // the viewport. The direction follows the stack semantics.
      // 双列保持不变但 master 发生了移动：视口整体平移一列。方向遵循栈的语义。
      _revealController.value = 1;
      _shiftController.value = 0;
      if (newMasterKey == oldDetailKey) {
        // Deeper push: the old detail became the new master. The replaced
        // master exits on the master side while the new pair slides in from
        // the detail side. / 更深层级 push：旧 detail 成为新 master。被替换的
        // master 向 master 侧退出，新的一对从 detail 侧滑入。
        _exitingDetail = null;
        _exitingMaster = oldWidget.children[0];
        _shiftController.forward();
      } else if (newDetailKey == oldMasterKey) {
        // Pop: the old master became the new detail — the mirror image, the
        // viewport slides back by one column. / 弹出一层：旧 master 成为新
        // detail——镜像转场，视口反向平移一列。
        _exitingMaster = null;
        _exitingDetail = oldWidget.children[1];
        _shiftController.forward();
      } else {
        // Both panes replaced wholesale (an external navigation): update in
        // place. / 两个 pane 被整体替换（外部导航）：原地更新。
        _exitingMaster = null;
        _exitingDetail = null;
      }
    } else {
      _exitingMaster = null;
      _exitingDetail = null;
    }
    if (!_dragging && widget.leftPaneFraction != oldWidget.leftPaneFraction) {
      _fraction = widget.leftPaneFraction;
    }
  }

  // A separate flag instead of `_dragStartX != 0`: starting a drag at global
  // x == 0 (possible when the master pane sits on the left edge) would
  // otherwise read as "not dragging" and let a widget update overwrite the
  // fraction mid-drag.
  // 用独立标志而非 `_dragStartX != 0`：在全局 x == 0 处开始拖拽（master 贴在
  // 左边缘时可能出现）会被误判为「未在拖拽」，组件更新会在拖拽中途覆盖比例。
  bool get _dragging => _dragActive;

  /// Resolves the master pane width, applying both the fraction clamp and the
  /// optional pixel ceiling — the single source of truth shared by the layout
  /// and the drag handler, so dragging can never push past the ceiling.
  /// 解析 master pane 宽度，同时应用比例夹取与可选像素上限——布局与拖拽共用
  /// 这一处实现，因此拖拽绝不会越过上限。
  double _masterWidthFor(double usable, double fraction) {
    if (usable <= 0) {
      return 0;
    }
    final cap = widget.maxLeftPaneWidth;
    final fractionUpper = usable * 0.85;
    final upper = cap == null ? fractionUpper : math.min(fractionUpper, cap);
    final lower = math.min(usable * 0.15, upper);
    return (usable * fraction.clamp(0.15, 0.85)).clamp(lower, upper);
  }

  void _onDragStart(DragStartDetails details) {
    // Use the global pointer position: the handle moves with `_fraction`
    // during the drag, so a local position would feed back on itself and make
    // the pane lag / drift. The global delta is the true pointer travel.
    // 使用全局指针坐标：拖拽时 handle 随 `_fraction` 移动，局部坐标会自我反馈
    // 导致 pane 卡顿 / 漂移。全局位移才是真实指针行程。
    _dragStartX = details.globalPosition.dx;
    _dragStartFraction = _fraction;
    _dragActive = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_totalWidth <= 0) {
      return;
    }
    final usable = _totalWidth - widget.resizeHandleWidth;
    if (usable <= 0) {
      return;
    }
    // Dragging away from the master grows it; the sign flips when the master
    // sits on the right.
    // 向远离 master 的方向拖拽使其变宽；master 在右时方向相反。
    final sign = widget.side == SlidingPanesSide.right ? 1.0 : -1.0;
    final desired =
        _dragStartFraction * usable +
        sign * (details.globalPosition.dx - _dragStartX);
    final fraction = _masterWidthFor(usable, desired / usable) / usable;
    setState(() {
      _fraction = fraction;
    });
    widget.onLeftPaneFractionChanged?.call(fraction);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _dragStartX = 0;
      _dragActive = false;
    });
    widget.onLeftPaneFractionDragEnd?.call(_fraction);
  }

  Widget _wrapPane(BuildContext context, Widget pane, bool isLeft) {
    final builder = widget.paneBuilder;
    if (builder != null) {
      return builder(context, pane, isLeft);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 320) {
          return SlidingPane(child: pane);
        }
        return pane;
      },
    );
  }

  Widget _buildHandle(BuildContext context) {
    final builder = widget.resizeHandleBuilder;
    final Widget visual = builder != null
        ? builder(context, _hoveringHandle)
        : _buildDefaultHandle(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: visual,
    );
  }

  Widget _buildDefaultHandle(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hoveringHandle = true),
      onExit: (_) => setState(() => _hoveringHandle = false),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _hoveringHandle ? 3 : 2,
          height: _hoveringHandle ? 48 : 32,
          decoration: BoxDecoration(
            color: _hoveringHandle
                ? theme.colorScheme.primary
                : theme.dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }
    final masterIsLeft = widget.side == SlidingPanesSide.right;
    final master = widget.children[0];

    // The detail column: the live detail, the exiting detail mid-collapse, or
    // the placeholder — in that order of availability.
    // detail 列：实时详情、收起动画退出中的详情、占位内容——按可用性取此顺序。
    Widget? detail;
    if (count >= 2) {
      detail = widget.children[1];
    } else if (_revealController.value > 0 && _exitingDetail != null) {
      detail = _exitingDetail;
    } else {
      detail = widget.placeholder;
    }
    if (detail == null) {
      return _wrapPane(context, master, masterIsLeft);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _shiftController]),
      builder: (context, _) {
        final reveal = widget.slideCurve.transform(_revealController.value);
        final shift = widget.slideCurve.transform(_shiftController.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            _totalWidth = constraints.maxWidth;
            final total = constraints.maxWidth;
            final handleWidth = widget.resizeHandleWidth;
            final masterWidth = _masterWidthFor(total - handleWidth, _fraction);
            final detailWidth = total - handleWidth - masterWidth;
            final masterChild = _wrapPane(context, master, masterIsLeft);
            final detailChild = _wrapPane(context, detail!, !masterIsLeft);
            final exitingMaster = _exitingMaster;
            final exitingDetail = _exitingDetail;
            if (shift < 1 && count >= 2) {
              if (exitingMaster != null) {
                // Deeper push: the replaced master exits on the master side.
                // 更深层级 push：被替换的 master 向 master 侧退出。
                return _buildPushShiftLayout(
                  context: context,
                  masterIsLeft: masterIsLeft,
                  total: total,
                  handleWidth: handleWidth,
                  masterWidth: masterWidth,
                  detailWidth: detailWidth,
                  t: shift,
                  masterChild: masterChild,
                  detailChild: detailChild,
                  exitingMaster: exitingMaster,
                );
              }
              if (exitingDetail != null) {
                // Pop: the exiting detail slides out on the detail side.
                // 弹出一层：退出中的 detail 向 detail 侧滑出。
                return _buildPopShiftLayout(
                  context: context,
                  masterIsLeft: masterIsLeft,
                  total: total,
                  handleWidth: handleWidth,
                  masterWidth: masterWidth,
                  detailWidth: detailWidth,
                  t: shift,
                  masterChild: masterChild,
                  detailChild: detailChild,
                  exitingDetail: exitingDetail,
                );
              }
            }
            return _buildRevealLayout(
              context: context,
              masterIsLeft: masterIsLeft,
              total: total,
              handleWidth: handleWidth,
              masterWidth: masterWidth,
              detailWidth: detailWidth,
              t: reveal,
              masterChild: masterChild,
              detailChild: detailChild,
            );
          },
        );
      },
    );
  }

  /// The resting / expand / collapse layout: `t == 1` is the final two-column
  /// arrangement, `t == 0` is the master filling the whole width.
  /// 静止 / 展开 / 收起布局：`t == 1` 为最终双列，`t == 0` 为 master 占满宽度。
  Widget _buildRevealLayout({
    required BuildContext context,
    required bool masterIsLeft,
    required double total,
    required double handleWidth,
    required double masterWidth,
    required double detailWidth,
    required double t,
    required Widget masterChild,
    required Widget detailChild,
  }) {
    final handle = Opacity(opacity: t, child: _buildHandle(context));
    if (masterIsLeft) {
      // Master on the left; detail slides in from the right.
      // master 在左；detail 从右滑入。
      final leftWidth = total + (masterWidth - total) * t;
      final rightOffset = (1 - t) * detailWidth;
      return Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: leftWidth,
            child: masterChild,
          ),
          Positioned(
            left: leftWidth,
            top: 0,
            bottom: 0,
            width: handleWidth,
            child: handle,
          ),
          Positioned(
            left: leftWidth + handleWidth + rightOffset,
            top: 0,
            bottom: 0,
            width: detailWidth,
            child: ClipRect(child: detailChild),
          ),
        ],
      );
    }
    // Master on the right; detail slides in from the left.
    // master 在右；detail 从左滑入。
    final masterLeft = (detailWidth + handleWidth) * t;
    final detailLeft = -detailWidth * (1 - t);
    return Stack(
      children: [
        Positioned(
          left: detailLeft,
          top: 0,
          bottom: 0,
          width: detailWidth,
          child: ClipRect(child: detailChild),
        ),
        Positioned(
          left: masterLeft - handleWidth,
          top: 0,
          bottom: 0,
          width: handleWidth,
          child: handle,
        ),
        Positioned(
          left: masterLeft,
          top: 0,
          bottom: 0,
          width: total - masterLeft,
          child: masterChild,
        ),
      ],
    );
  }

  /// The deeper-push layout: the whole viewport slides left (or right, when
  /// the master sits on the right) by one column — the replaced master exits
  /// on its side while the new pair slides in from the detail side.
  /// 更深层级 push 布局：整个视口左移（master 在右时右移）一列——被替换的
  /// master 向自己一侧退出，新的一对从 detail 一侧滑入。
  ///
  /// At `t == 0` the arrangement is pixel-identical to the pre-push state (the
  /// new master sits exactly where the old detail sat, at the detail column's
  /// width), so the slide starts seamlessly.
  /// `t == 0` 时布局与 push 前逐像素一致（新 master 正落在旧 detail 的位置，
  /// 宽度亦为 detail 列宽），滑动因此无缝起始。
  Widget _buildPushShiftLayout({
    required BuildContext context,
    required bool masterIsLeft,
    required double total,
    required double handleWidth,
    required double masterWidth,
    required double detailWidth,
    required double t,
    required Widget masterChild,
    required Widget detailChild,
    required Widget exitingMaster,
  }) {
    final handle = Opacity(opacity: t, child: _buildHandle(context));
    final exiting = Opacity(
      opacity: 1 - t,
      child: ClipRect(child: exitingMaster),
    );
    // The travelling pane morphs from the detail column width to the master
    // column width (or back), so both ends of the slide line up exactly.
    // 移动中的 pane 宽度从 detail 列宽渐变到 master 列宽（或反向），
    // 使滑动两端精确衔接。
    final travellingWidth = masterWidth + (detailWidth - masterWidth) * (1 - t);
    if (masterIsLeft) {
      final masterLeft = (masterWidth + handleWidth) * (1 - t);
      final detailLeft = masterWidth + handleWidth + detailWidth * (1 - t);
      return Stack(
        children: [
          Positioned(
            left: -masterWidth * t,
            top: 0,
            bottom: 0,
            width: masterWidth,
            child: exiting,
          ),
          Positioned(
            left: masterLeft,
            top: 0,
            bottom: 0,
            width: travellingWidth,
            child: masterChild,
          ),
          Positioned(
            left: masterLeft + travellingWidth,
            top: 0,
            bottom: 0,
            width: handleWidth,
            child: handle,
          ),
          Positioned(
            left: detailLeft,
            top: 0,
            bottom: 0,
            width: detailWidth,
            child: ClipRect(child: detailChild),
          ),
        ],
      );
    }
    // Mirrored: the new master starts in the detail column (left) and slides
    // right; the replaced master exits to the right.
    // 镜像：新 master 从 detail 列（左）出发向右滑到位；被替换的 master 向右退出。
    final masterFinalLeft = detailWidth + handleWidth;
    final masterLeft = masterFinalLeft * t;
    final detailLeft = -detailWidth * (1 - t);
    return Stack(
      children: [
        Positioned(
          left: detailLeft,
          top: 0,
          bottom: 0,
          width: detailWidth,
          child: ClipRect(child: detailChild),
        ),
        Positioned(
          left: masterLeft - handleWidth,
          top: 0,
          bottom: 0,
          width: handleWidth,
          child: handle,
        ),
        Positioned(
          left: masterLeft,
          top: 0,
          bottom: 0,
          width: travellingWidth,
          child: masterChild,
        ),
        Positioned(
          left: masterFinalLeft + masterWidth * t,
          top: 0,
          bottom: 0,
          width: masterWidth,
          child: exiting,
        ),
      ],
    );
  }

  /// The pop layout — the mirror image of [_buildPushShiftLayout]: the
  /// viewport slides back by one column. The exiting detail slides out on the
  /// detail side, the new master slides in from the master side, and the new
  /// detail (the old master) travels from the master position to the detail
  /// position, morphing its width on the way.
  /// 弹出一层的布局——[_buildPushShiftLayout] 的镜像：视口反向平移一列。
  /// 退出中的 detail 向 detail 一侧滑出，新 master 从 master 一侧滑入，新
  /// detail（即旧 master）从 master 位置移动到 detail 位置，宽度随之渐变。
  ///
  /// At `t == 0` the arrangement is pixel-identical to the pre-pop state.
  /// `t == 0` 时布局与 pop 前逐像素一致。
  Widget _buildPopShiftLayout({
    required BuildContext context,
    required bool masterIsLeft,
    required double total,
    required double handleWidth,
    required double masterWidth,
    required double detailWidth,
    required double t,
    required Widget masterChild,
    required Widget detailChild,
    required Widget exitingDetail,
  }) {
    final handle = Opacity(opacity: t, child: _buildHandle(context));
    final exiting = Opacity(
      opacity: 1 - t,
      child: ClipRect(child: exitingDetail),
    );
    final travellingWidth = detailWidth + (masterWidth - detailWidth) * (1 - t);
    if (masterIsLeft) {
      // The new detail starts in the master column and slides right; the new
      // master enters from the left edge; the exiting detail leaves right.
      // 新 detail 从 master 列出发向右滑到位；新 master 从左边缘滑入；
      // 退出中的 detail 向右离场。
      final masterLeft = -masterWidth * (1 - t);
      final detailLeft = (masterWidth + handleWidth) * t;
      return Stack(
        children: [
          Positioned(
            left: masterLeft,
            top: 0,
            bottom: 0,
            width: masterWidth,
            child: masterChild,
          ),
          Positioned(
            left: detailLeft - handleWidth,
            top: 0,
            bottom: 0,
            width: handleWidth,
            child: handle,
          ),
          Positioned(
            left: detailLeft,
            top: 0,
            bottom: 0,
            width: travellingWidth,
            child: detailChild,
          ),
          Positioned(
            left: masterWidth + handleWidth + detailWidth * t,
            top: 0,
            bottom: 0,
            width: detailWidth,
            child: exiting,
          ),
        ],
      );
    }
    // Mirrored: the new detail starts in the master column (right) and slides
    // left; the new master enters from the right edge; the exiting detail
    // leaves left. / 镜像：新 detail 从 master 列（右）出发向左滑到位；新
    // master 从右边缘滑入；退出中的 detail 向左离场。
    final masterFinalLeft = detailWidth + handleWidth;
    final masterLeft = masterFinalLeft + (total - masterFinalLeft) * (1 - t);
    final detailLeft = masterFinalLeft * (1 - t);
    return Stack(
      children: [
        Positioned(
          left: -detailWidth * t,
          top: 0,
          bottom: 0,
          width: detailWidth,
          child: exiting,
        ),
        Positioned(
          left: masterLeft,
          top: 0,
          bottom: 0,
          width: masterWidth,
          child: masterChild,
        ),
        Positioned(
          left: detailLeft + travellingWidth,
          top: 0,
          bottom: 0,
          width: handleWidth,
          child: handle,
        ),
        Positioned(
          left: detailLeft,
          top: 0,
          bottom: 0,
          width: travellingWidth,
          child: detailChild,
        ),
      ],
    );
  }
}
