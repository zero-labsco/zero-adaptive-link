import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:zero_adaptive_link/src/nav/zero_nav.dart';

/// A declarative tap target whose behavior adapts to the window width.
/// 声明式点击目标，行为随窗口宽度自适应。
///
/// The same `location` behaves differently per width:
/// 同一个 `location` 在不同宽度下表现不同：
///
/// - compact / medium: `Navigator.push` a new page;
///   compact / medium：push 一个新页面；
/// - expanded: expand or update the right sidebar pane;
///   expanded：展开或更新右侧侧栏 pane；
/// - target pane already visible: focus it (no duplicate expansion).
///   目标 pane 已可见：聚焦它（不重复展开）。
///
/// Uses `GestureDetector + MouseRegion` (hand cursor on web / desktop) and does
/// not require a Material ancestor.
/// 使用 `GestureDetector + MouseRegion`（web / 桌面显示手型光标），不强制
/// Material 祖先。
class ZeroLink extends StatelessWidget {
  /// Create the link. / 创建该链接。
  const ZeroLink({
    required this.location,
    required this.child,
    this.onTap,
    this.cursor,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  /// The target location. / 目标 location。
  final String location;

  /// The tappable content. / 可点击内容。
  final Widget child;

  /// Overrides the default behavior (open [location]).
  /// 覆盖默认行为（打开 [location]）。
  final VoidCallback? onTap;

  /// Cursor override; defaults to a hand cursor on web / desktop.
  /// 光标覆盖；默认为 web / 桌面的手型光标。
  final MouseCursor? cursor;

  /// Hit test behavior of the gesture detector.
  /// 手势探测器的命中测试行为。
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor ?? _defaultCursor(),
      child: GestureDetector(
        behavior: behavior,
        onTap: onTap ?? () => ZeroNav.of(context).open(location),
        child: child,
      ),
    );
  }

  MouseCursor _defaultCursor() {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return SystemMouseCursors.click;
    }
    return MouseCursor.defer;
  }
}
