import 'package:flutter/material.dart';

/// A horizontal breadcrumb bar: an `InkWell + Text` row for navigating back up
/// the page stack.
/// 横向面包屑栏：由 `InkWell + Text` 组成的一行，用于向上导航页面栈。
///
/// Usable without any router: feed it plain labels.
/// 无需路由即可使用：直接传入普通标签。
class Breadcrumbs extends StatelessWidget {
  /// Create a breadcrumb bar from [items].
  /// 由 [items] 创建面包屑栏。
  const Breadcrumbs({
    required this.items,
    this.onNavigate,
    this.separator = '›',
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.style,
    super.key,
  });

  /// The breadcrumb labels, outermost first. / 面包屑标签，最外层在前。
  final List<String> items;

  /// Called with the tapped index; typically pops the stack to that location.
  /// 点击时回调下标；通常用于将栈弹回该位置。
  final ValueChanged<int>? onNavigate;

  /// Text shown between items. / 条目之间的分隔文本。
  final String separator;

  /// Outer padding of the bar. / 面包屑栏的外边距。
  final EdgeInsetsGeometry padding;

  /// Text style override. / 文本样式覆盖。
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final textStyle = style ?? DefaultTextStyle.of(context).style;
    // Own Material ancestor so the InkWell row also works standalone.
    // 自带 Material 祖先，使 InkWell 行也可独立使用。
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(separator, style: textStyle),
                  ),
                InkWell(
                  onTap: onNavigate == null ? null : () => onNavigate!(i),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(items[i], style: textStyle),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
