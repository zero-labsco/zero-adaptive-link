import 'package:flutter/material.dart';

import 'package:zero_adaptive_link/src/router/state.dart';

/// A destination for [ZeroNavigationChrome]. / [ZeroNavigationChrome] 的一个目标项。
class ZeroNavigationDestination {
  /// Create a destination. / 创建目标项。
  const ZeroNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });

  /// The icon shown when the destination is unselected.
  /// 未选中时显示的图标。
  final Widget icon;

  /// The icon shown when the destination is selected (defaults to [icon]).
  /// 选中时显示的图标（默认同 [icon]）。
  final Widget? selectedIcon;

  /// The destination label. / 目标项标签。
  final String label;
}

/// A responsive shell chrome that switches between a [NavigationRail] (expanded)
/// and a bottom [NavigationBar] (compact / medium) from the window width, so
/// applications no longer hand-wire the two themselves.
/// 响应式 shell chrome：根据窗口宽度在 [NavigationRail]（expanded）与底部
/// [NavigationBar]（compact / medium）之间自动切换，应用无需再手写两种。
///
/// Place it in your `ZeroShell.builder`: it reads the active tab from
/// [ZeroShellScope] and calls `goTab` on tap, and lays [child] out next to the
/// rail (expanded) or above the bar (compact / medium).
/// 放入 `ZeroShell.builder` 即可：它从 [ZeroShellScope] 读取当前 tab，点击时
/// 调用 `goTab`，并把 [child] 排布在 rail 旁（expanded）或 bar 之上
/// （compact / medium）。
///
/// ```dart
/// ZeroShell(
///   builder: (context, shell, child) => ZeroNavigationChrome(
///     destinations: [
///       ZeroNavigationDestination(icon: Icon(Icons.home), label: 'Home'),
///       ZeroNavigationDestination(icon: Icon(Icons.list), label: 'List'),
///     ],
///     child: child,
///   ),
///   tabs: [...],
/// )
/// ```
class ZeroNavigationChrome extends StatelessWidget {
  /// Create the chrome. / 创建该 chrome。
  const ZeroNavigationChrome({
    super.key,
    required this.destinations,
    this.child,
  });

  /// The tab destinations. / 各个 tab 目标项。
  final List<ZeroNavigationDestination> destinations;

  /// The branch content handed to `ZeroShell.builder` (the navigator / panes).
  /// `ZeroShell.builder` 传入的 branch 内容（navigator / panes）。
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final shell = ZeroShellScope.of(context);
    final index = shell.currentIndex;
    void onSelect(int i) => shell.goTab(i);
    if (shell.isExpanded) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: onSelect,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon ?? d.icon,
                  label: Text(d.label),
                ),
            ],
          ),
          if (child != null) Expanded(child: child!),
        ],
      );
    }
    return Column(
      children: [
        if (child != null) Expanded(child: child!),
        NavigationBar(
          selectedIndex: index,
          onDestinationSelected: onSelect,
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon ?? d.icon,
                label: d.label,
              ),
          ],
        ),
      ],
    );
  }
}
