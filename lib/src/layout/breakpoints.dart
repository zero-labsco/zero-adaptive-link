import 'package:flutter/widgets.dart';

/// The three adaptive layout classes derived from window width.
/// 由窗口宽度推导出的三种自适应布局档位。
enum BreakpointClass {
  /// `< compactMaxWidth`: push a new page (classic Navigator stack).
  /// `< compactMaxWidth`：push 新页面（经典 Navigator 栈）。
  compact,

  /// `compactMaxWidth – expandedMinWidth`: push a new page (single column,
  /// different shell chrome).
  /// `compactMaxWidth – expandedMinWidth`：push 新页面（单列，shell chrome 不同）。
  medium,

  /// `>= expandedMinWidth`: expand / update the right sidebar pane
  /// (master-detail).
  /// `>= expandedMinWidth`：展开 / 更新右侧侧栏 pane（master-detail）。
  expanded,
}

/// Window-width breakpoints that drive adaptive navigation.
/// 驱动自适应导航的窗口宽度断点。
///
/// Classification is based on the **window width**, deliberately decoupled from
/// the device type, so foldables, small desktop windows and browser zoom all
/// classify correctly.
/// 档位判定依据是「窗口宽度」（与设备类型刻意解耦），折叠屏、桌面小窗、浏览器缩放都能正确归类。
@immutable
class Breakpoints {
  /// Create breakpoints with the given thresholds.
  /// 使用给定阈值创建断点。
  const Breakpoints({this.compactMaxWidth = 600, this.expandedMinWidth = 840});

  /// Widths below this value are [BreakpointClass.compact].
  /// 低于该宽度为 [BreakpointClass.compact]。
  final double compactMaxWidth;

  /// Widths at or above this value are [BreakpointClass.expanded].
  /// 大于等于该宽度为 [BreakpointClass.expanded]。
  final double expandedMinWidth;

  /// Classify a window width into a [BreakpointClass].
  /// 将窗口宽度判定为 [BreakpointClass]。
  BreakpointClass classify(double width) {
    if (width < compactMaxWidth) {
      return BreakpointClass.compact;
    }
    if (width >= expandedMinWidth) {
      return BreakpointClass.expanded;
    }
    return BreakpointClass.medium;
  }
}
