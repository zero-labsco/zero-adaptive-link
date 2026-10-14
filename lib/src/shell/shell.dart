import 'package:flutter/widgets.dart';

import 'package:zero_adaptive_link/src/router/state.dart';

/// Publishes the compact bottom-bar builder to the branch pages.
/// 向 branch 页面发布 compact 底部栏构建器。
class _ChromeScope extends InheritedWidget {
  /// Create the scope. / 创建该 scope。
  const _ChromeScope({required this.bottomNavigationBar, required super.child});

  /// The bottom navigation bar builder. / 底部导航栏构建器。
  final WidgetBuilder bottomNavigationBar;

  @override
  bool updateShouldNotify(_ChromeScope oldWidget) =>
      bottomNavigationBar != oldWidget.bottomNavigationBar;
}

/// Read the compact bottom-bar builder published by [ZeroShellChrome], if any.
/// 读取 [ZeroShellChrome] 发布的 compact 底部栏构建器（若有）。
WidgetBuilder? chromeBottomNavigationBarOf(BuildContext context) {
  return context
      .dependOnInheritedWidgetOfExactType<_ChromeScope>()
      ?.bottomNavigationBar;
}

/// Container for the compact bottom `NavigationBar`.
/// compact 底部 `NavigationBar` 的容器。
///
/// Wrap the shell's `child` with it on compact widths and the plugin renders
/// the bar **inside** the branch pages, so a modal bottom sheet opened with
/// `useRootNavigator: false` covers it. On medium / expanded widths this widget
/// is a pass-through and the host chrome is kept.
/// 在 compact 宽度下用它包裹 shell 的 `child`，插件会把底部栏渲染进 branch
/// 页面**内部**，从而让 `useRootNavigator: false` 打开的 bottom sheet 可以覆盖
/// 它。在 medium / expanded 宽度下本组件直接透传，保留宿主 chrome。
///
/// ```dart
/// ZeroShell(
///   builder: (context, shell, child) => shell.isCompact
///       ? ZeroShellChrome(
///           bottomNavigationBar: (context) => NavigationBar(…),
///           child: child,
///         )
///       : Row(children: [NavigationRail(…), Expanded(child: child)]),
///   tabs: […],
/// )
/// ```
class ZeroShellChrome extends StatelessWidget {
  /// Create the chrome container. / 创建该 chrome 容器。
  const ZeroShellChrome({
    required this.child,
    this.bottomNavigationBar,
    super.key,
  });

  /// The shell child (usually the branch navigator).
  /// shell 的 child（通常是 branch navigator）。
  final Widget child;

  /// The bottom navigation bar, a `WidgetBuilder` so it can read
  /// `ZeroShellScope` for the selected index.
  /// 底部导航栏，使用 `WidgetBuilder` 以便读取 `ZeroShellScope` 的选中下标。
  final WidgetBuilder? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final shell = ZeroShellScope.maybeOf(context);
    final bar = bottomNavigationBar;
    if (bar == null || shell == null || !shell.isCompact) {
      return child;
    }
    return _ChromeScope(bottomNavigationBar: bar, child: child);
  }
}
