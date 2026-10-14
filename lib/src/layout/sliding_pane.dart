import 'package:flutter/material.dart';

/// A single pane surface, typically used as a child of [SlidingPanes].
/// 单个 pane 表面，通常作为 [SlidingPanes] 的子组件使用。
///
/// Usable on its own (no router required): when a pane is wide it renders as a
/// raised card, when narrow it stays flat.
/// 可单独使用（无需引入路由）：pane 较宽时呈现为卡片，较窄时保持扁平。
class SlidingPane extends StatelessWidget {
  /// Create a pane surface wrapping [child].
  /// 创建包裹 [child] 的 pane 表面。
  const SlidingPane({
    required this.child,
    this.elevation,
    this.margin,
    this.borderRadius,
    this.color,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// The pane content. / pane 内容。
  final Widget child;

  /// Card elevation; defaults to a subtle `1`. / 卡片高程，默认为轻微的 `1`。
  final double? elevation;

  /// Outer margin of the pane. / pane 的外边距。
  final EdgeInsetsGeometry? margin;

  /// Corner radius of the pane surface. / pane 表面的圆角。
  final BorderRadius? borderRadius;

  /// Background color of the pane surface. / pane 表面的背景色。
  final Color? color;

  /// How to clip the pane content. / pane 内容的裁剪方式。
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.all(6),
      child: Material(
        elevation: elevation ?? 1,
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }
}
