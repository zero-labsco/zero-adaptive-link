import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:zero_adaptive_link/src/nav/zero_nav.dart';

/// How a [ZeroLink] opens its [ZeroLink.location].
/// [ZeroLink] 打开其 [ZeroLink.location] 的方式。
enum ZeroLinkMode {
  /// Push a new entry (`ZeroNav.open`). / 压入新条目（`ZeroNav.open`）。
  push,

  /// Replace the current entry (`ZeroNav.pushReplacementNamed`).
  /// 替换当前条目（`ZeroNav.pushReplacementNamed`）。
  replacement,

  /// Pop, then push (`ZeroNav.popAndPushNamed`).
  /// 先 pop 再 push（`ZeroNav.popAndPushNamed`）。
  popAndPush,
}

/// The intent activated by Enter / Space on a focused [ZeroLink].
/// 聚焦的 [ZeroLink] 上由 Enter / Space 触发的 Intent。
class _ZeroLinkActivateIntent extends Intent {
  const _ZeroLinkActivateIntent();
}

/// A declarative tap target whose behavior adapts to the window width.
/// 声明式点击目标，行为随窗口宽度自适应。
///
/// The same [location] behaves differently per width:
/// 同一个 [location] 在不同宽度下表现不同：
///
/// - compact / medium: `Navigator.push` a new page;
///   compact / medium：push 一个新页面；
/// - expanded: expand or update the right sidebar pane;
///   expanded：展开或更新右侧侧栏 pane；
/// - target pane already visible: focus it (no duplicate expansion).
///   目标 pane 已可见：聚焦它（不重复展开）。
///
/// It is keyboard- and screen-reader-accessible (focusable, Enter / Space
/// activates, exposed as a button with [semanticLabel]) and does not require a
/// Material ancestor. The hand cursor is unchanged on web / desktop.
/// 它支持键盘与屏幕阅读器（可聚焦、Enter / Space 激活、以按钮角色配合
/// [semanticLabel] 暴露），且不需要 Material 祖先。web / 桌面的手型光标保持不变。
class ZeroLink extends StatelessWidget {
  /// Create the link. / 创建该链接。
  const ZeroLink({
    required this.location,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.mode = ZeroLinkMode.push,
    this.tabIndex,
    this.arguments,
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

  /// Spoken / braille label for screen readers.
  /// 供屏幕阅读器朗读 / 点字的标签。
  final String? semanticLabel;

  /// How [location] is opened; defaults to [ZeroLinkMode.push].
  /// 打开 [location] 的方式，默认 [ZeroLinkMode.push]。
  final ZeroLinkMode mode;

  /// Open [location] in this tab specifically (maps to `preferredTab`). When
  /// `null` the router picks the tab as usual.
  /// 在指定 tab 打开 [location]（对应 `preferredTab`）。`null` 时由路由照常选择。
  final int? tabIndex;

  /// Arguments forwarded to the navigation verbs. / 透传给导航动词的参数。
  final Object? arguments;

  /// Cursor override; defaults to a hand cursor on web / desktop.
  /// 光标覆盖；默认为 web / 桌面的手型光标。
  final MouseCursor? cursor;

  /// Hit test behavior of the gesture detector.
  /// 手势探测器的命中测试行为。
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: cursor ?? _defaultCursor(),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): _ZeroLinkActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): _ZeroLinkActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        _ZeroLinkActivateIntent: CallbackAction<_ZeroLinkActivateIntent>(
          onInvoke: (_) {
            _activate(context);
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: behavior,
        onTap: onTap ?? () => _activate(context),
        child: Semantics(
          button: true,
          link: true,
          label: semanticLabel,
          child: child,
        ),
      ),
    );
  }

  void _activate(BuildContext context) {
    final nav = ZeroNav.of(context);
    switch (mode) {
      case ZeroLinkMode.push:
        nav.open(location, arguments: arguments, preferredTab: tabIndex);
      case ZeroLinkMode.replacement:
        nav.pushReplacementNamed(
          location,
          arguments: arguments,
          preferredTab: tabIndex,
        );
      case ZeroLinkMode.popAndPush:
        nav.popAndPushNamed(
          location,
          arguments: arguments,
          preferredTab: tabIndex,
        );
    }
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
