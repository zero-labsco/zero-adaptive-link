import 'package:flutter/material.dart';

import 'package:zero_adaptive_link/src/nav/zero_nav.dart';
import 'package:zero_adaptive_link/src/router/state.dart';

/// A back control that adapts to the layout: it collapses the detail pane on
/// expanded widths and pops the current entry otherwise. It is only visible when
/// there is something to go back to.
/// 随布局自适应的返回控件：expanded 下收起 detail pane，否则 pop 当前条目。
/// 仅当可返回时显示。
///
/// Drop it into an `AppBar.leading` (or anywhere inside a route) — it reads the
/// surrounding [ZeroNav] / [ZeroShellScope] and is a no-op when used outside a
/// router. / 把它放进 `AppBar.leading`（或路由内的任意位置）即可——它读取
/// 周围的 [ZeroNav] / [ZeroShellScope]，在 router 之外使用时为空。
class ZeroBackButton extends StatelessWidget {
  /// Create the adaptive back button. / 创建自适应返回按钮。
  const ZeroBackButton({super.key, this.color});

  /// Override the icon color. / 覆盖图标颜色。
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final nav = ZeroNav.maybeOf(context);
    if (nav == null) {
      return const SizedBox.shrink();
    }
    final shell = ZeroShellScope.maybeOf(context);
    final isExpanded = shell?.isExpanded ?? false;
    final detailOpen = nav.isDetailOpen;
    final visible = isExpanded ? detailOpen : nav.canPop;
    if (!visible) {
      return const SizedBox.shrink();
    }
    return BackButton(
      color: color,
      onPressed: () async {
        if (isExpanded && detailOpen) {
          nav.hideDetail();
        } else {
          await nav.maybePop();
        }
      },
    );
  }
}
