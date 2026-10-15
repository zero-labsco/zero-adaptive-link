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
/// Usable without any router: feed it plain widgets.
/// 无需路由即可使用：直接传入普通组件。
class SlidingPanes extends StatefulWidget {
  /// Create a sliding pane layout with one or two [children].
  /// 使用 1 个或 2 个 [children] 创建滑动 pane 布局。
  const SlidingPanes({
    required this.children,
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

  /// Fraction of the width taken by the master pane (0.15 – 0.85), regardless
  /// of which side it sits on.
  /// master pane 占据的宽度比例（0.15 – 0.85），不随其所在左右侧改变。
  final double leftPaneFraction;

  /// Optional pixel ceiling for the master pane. / master pane 的可选像素上限。
  ///
  /// The pane still scales with [leftPaneFraction], but never grows past this
  /// width — on an ultra-wide window the detail pane absorbs the remainder
  /// instead of both columns stretching. `null` (the default) means no ceiling.
  /// pane 仍按 [leftPaneFraction] 缩放，但绝不超过该宽度——在超宽窗口上由
  /// detail pane 吸收剩余空间，而不是两栏一起被拉宽。`null`（默认）表示不设上限。
  final double? maxLeftPaneWidth;

  /// Which side the detail pane expands toward. / detail pane 展开所朝向的一侧。
  ///
  /// Defaults to [SlidingPanesSide.right] (master on the left).
  /// 默认 [SlidingPanesSide.right]（master 在左）。
  final SlidingPanesSide side;

  /// Duration of the pane slide animation. / pane 滑动动画时长。
  final Duration slideDuration;

  /// Curve of the pane slide animation. / pane 滑动动画曲线。
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
  /// 用户松开分割线时回调一次。实时拖拽只需要逐帧的
  /// [onLeftPaneFractionChanged]；本回调是「提交点」，监听者可每轮拖拽只
  /// 反应一次（例如把比例发布给应用其余部分），而非每帧一次。
  final ValueChanged<double>? onLeftPaneFractionDragEnd;

  @override
  State<SlidingPanes> createState() => _SlidingPanesState();
}

class _SlidingPanesState extends State<SlidingPanes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _revealController = AnimationController(
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
  List<Widget> _exitingChildren = const [];

  @override
  void initState() {
    super.initState();
    _fraction = widget.leftPaneFraction;
    if (widget.children.length >= 2) {
      _exitingChildren = widget.children;
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SlidingPanes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slideDuration != oldWidget.slideDuration) {
      _revealController.duration = widget.slideDuration;
    }
    if (widget.children.length >= 2) {
      _exitingChildren = widget.children;
      if (oldWidget.children.length < 2) {
        _revealController.forward();
      }
    } else if (oldWidget.children.length >= 2) {
      // Keep the exiting panes mounted while the reverse animation plays.
      // 反向动画播放期间保持退场 pane 挂载。
      _exitingChildren = oldWidget.children;
      _revealController.reverse();
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
    final reveal = _revealController.value;
    if (count == 1 && reveal <= 0) {
      return _wrapPane(context, widget.children[0], masterIsLeft);
    }

    final master = widget.children[0];
    final detail = count >= 2
        ? widget.children[1]
        : (_exitingChildren.length >= 2 ? _exitingChildren[1] : null);
    if (detail == null) {
      return _wrapPane(context, master, masterIsLeft);
    }

    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        final t = widget.slideCurve.transform(_revealController.value);
        return LayoutBuilder(
          builder: (context, constraints) {
            _totalWidth = constraints.maxWidth;
            final total = constraints.maxWidth;
            final handleWidth = widget.resizeHandleWidth;
            final masterWidth = _masterWidthFor(total - handleWidth, _fraction);
            final detailWidth = total - handleWidth - masterWidth;
            final masterChild = _wrapPane(context, master, masterIsLeft);
            final detailChild = _wrapPane(context, detail, !masterIsLeft);
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
          },
        );
      },
    );
  }
}
