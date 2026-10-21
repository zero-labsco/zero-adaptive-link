import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

import 'pages.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  runApp(const ExampleApp());
}

/// One of the width presets used to verify the three behaviors.
/// 用于验证三种行为的宽度预设之一。
@immutable
class WidthPreset {
  const WidthPreset(this.label, this.width);

  final String label;
  final double width;
}

const List<WidthPreset> kWidthPresets = [
  WidthPreset('Phone 480', 480),
  WidthPreset('Foldable 720', 720),
  WidthPreset('Tablet 1023', 1023),
  WidthPreset('Desktop', 1440),
];

/// Publishes the simulated viewport width to the shell builder so the demo can
/// also visually frame the content.
/// 向 shell builder 发布模拟的视口宽度，使演示同时能在视觉上框住内容。
class ExampleFrameScope extends InheritedWidget {
  const ExampleFrameScope({
    required this.simulatedWidth,
    required super.child,
    super.key,
  });

  final double? simulatedWidth;

  static double? maybeWidthOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ExampleFrameScope>()
        ?.simulatedWidth;
  }

  @override
  bool updateShouldNotify(ExampleFrameScope oldWidget) =>
      simulatedWidth != oldWidget.simulatedWidth;
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  double? _simulatedWidth;
  final ValueNotifier<SlidingPanesSide> _paneSide =
      ValueNotifier<SlidingPanesSide>(SlidingPanesSide.right);
  bool _loggedIn = false;

  late final ZeroRouter _router = ZeroRouter(
    initialLocation: '/inbox',
    // Auth redirect: /you/billing requires being signed in.
    // 登录态重定向：/you/billing 需要先登录。
    redirect: (location) {
      if (!_loggedIn && location.startsWith('/you/billing')) {
        return '/login?from=${Uri.encodeQueryComponent(location)}';
      }
      return null;
    },
    paneSideListenable: _paneSide,
    paneBuilder: (context, pane, isLeft) => _PaneFrame(child: pane),
    placeholder: const _EmptyDetailPane(),
    routes: [
      ZeroShell(
        builder: _buildShell,
        tabs: [
          ZeroTab(
            initialLocation: '/inbox',
            routes: [
              ZeroRoute(
                path: '/inbox',
                title: (state) => 'Inbox',
                builder: buildInboxList,
                routes: [
                  ZeroRoute(
                    path: ':id',
                    title: (state) => 'Ticket #${state.pathParameters['id']}',
                    builder: _buildTicketDetail,
                    routes: [
                      ZeroRoute(
                        path: 'attachment',
                        fullscreen: true,
                        opaque: false,
                        barrierColor: const Color(0x99000000),
                        barrierDismissible: true,
                        title: (state) => 'Attachment',
                        builder: buildAttachmentPreview,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ZeroTab(
            initialLocation: '/customers',
            routes: [
              ZeroRoute(
                path: '/customers',
                title: (state) => 'Customers',
                builder: buildCustomers,
              ),
            ],
          ),
          ZeroTab(
            initialLocation: '/you',
            routes: [
              ZeroRoute(
                path: '/you',
                title: (state) => 'You',
                builder: _buildYou,
                routes: [
                  ZeroRoute(
                    path: 'billing',
                    title: (state) => 'Billing',
                    builder: buildBilling,
                  ),
                ],
              ),
              ZeroRoute(
                path: '/login',
                title: (state) => 'Sign in',
                builder: _buildLogin,
              ),
            ],
          ),
          ZeroTab(
            initialLocation: '/settings',
            routes: [
              ZeroRoute(
                path: '/settings',
                title: (state) => 'Settings',
                // Host a nested shell: this route renders the inner shell as its
                // child. The inner shell owns its own Profile / Account tabs and
                // re-resolves from the same location stack, so deep links like
                // /settings/account restore the outer tab and the nested one.
                // 承载一个嵌套 shell：本路由把内层 shell 作为 child 渲染。内层
                // shell 拥有自己的 Profile / Account tab，并从同一份 location 栈
                // 重新解析，因此 /settings/account 这样的深链会同时恢复外层与内层
                // tab。
                shell: ZeroShell(
                  builder: _buildSettingsShell,
                  tabs: [
                    ZeroTab(
                      initialLocation: '/settings/profile',
                      routes: [
                        ZeroRoute(
                          path: '/profile',
                          title: (state) => 'Profile',
                          builder: buildProfile,
                        ),
                      ],
                    ),
                    ZeroTab(
                      initialLocation: '/settings/account',
                      routes: [
                        ZeroRoute(
                          path: '/account',
                          title: (state) => 'Account',
                          builder: buildAccount,
                        ),
                      ],
                    ),
                  ],
                ),
                shellBuilder: (context, state, child) => child,
              ),
            ],
          ),
        ],
      ),
    ],
  );

  Widget _buildTicketDetail(BuildContext context, ZeroRouteState state) {
    final id = state.pathParameters['id']!;
    return buildTicketDetail(context, state, (text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reply sent to ticket #$id')));
    });
  }

  Widget _buildYou(BuildContext context, ZeroRouteState state) {
    return buildYou(context, state, _loggedIn);
  }

  Widget _buildLogin(BuildContext context, ZeroRouteState state) {
    return buildLogin(context, state, () => setState(() => _loggedIn = true));
  }

  // ------------------------------------------------------------ shell ----

  Widget _buildShell(BuildContext context, ZeroShellState shell, Widget child) {
    const railDestinations = [
      NavigationRailDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: Text('Inbox'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: Text('Customers'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('You'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
    const barDestinations = [
      NavigationDestination(
        icon: Icon(Icons.inbox_outlined),
        selectedIcon: Icon(Icons.inbox),
        label: 'Inbox',
      ),
      NavigationDestination(
        icon: Icon(Icons.business_outlined),
        selectedIcon: Icon(Icons.business),
        label: 'Customers',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'You',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
    if (shell.isCompact) {
      return ZeroShellChrome(
        bottomNavigationBar: (context) => NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goTab,
          destinations: barDestinations,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.pineTint,
        ),
        child: _framed(child),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: shell.goTab,
            destinations: railDestinations,
            backgroundColor: AppColors.paper,
            selectedIconTheme: const IconThemeData(color: AppColors.pine),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.pine,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedIconTheme: const IconThemeData(color: AppColors.muted),
            unselectedLabelTextStyle: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
            labelType: NavigationRailLabelType.all,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: _framed(child)),
        ],
      ),
    );
  }

  /// The nested Settings shell: a second, inner tab set (Profile / Account) that
  /// lives inside the `/settings` route. On compact it shows a top tab bar so it
  /// does not collide with the outer bottom bar; on medium / expanded it shows a
  /// secondary rail beside its content.
  /// 嵌套的 Settings shell：位于 `/settings` 路由内部的第二层 tab 组（Profile /
  /// Account）。compact 下用顶部 tab 条以避免与外层底栏冲突；medium / expanded
  /// 下在其内容旁显示二级 rail。
  Widget _buildSettingsShell(
    BuildContext context,
    ZeroShellState shell,
    Widget child,
  ) {
    if (shell.isCompact) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: _SettingsTabBar(shell: shell),
          ),
        ),
        body: child,
      );
    }
    return Row(
      children: [
        NavigationRail(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: shell.goTab,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: Text('Profile'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.account_box_outlined),
              selectedIcon: Icon(Icons.account_box),
              label: Text('Account'),
            ),
          ],
          labelType: NavigationRailLabelType.all,
          backgroundColor: AppColors.surface,
          selectedIconTheme: const IconThemeData(color: AppColors.pine),
          selectedLabelTextStyle: const TextStyle(
            color: AppColors.pine,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedIconTheme: const IconThemeData(color: AppColors.muted),
          unselectedLabelTextStyle: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: child),
      ],
    );
  }

  /// Frames the content to the simulated width so the demo looks like the
  /// selected device class.
  /// 将内容框到模拟宽度，使演示看起来像所选的设备档位。
  Widget _framed(Widget child) {
    final width = ExampleFrameScope.maybeWidthOf(context);
    if (width == null) {
      return child;
    }
    return ColoredBox(
      color: AppColors.paper,
      child: Center(
        child: SizedBox(width: width, child: child),
      ),
    );
  }

  // ------------------------------------------------------------- build ----

  @override
  Widget build(BuildContext context) {
    return ExampleFrameScope(
      simulatedWidth: _simulatedWidth,
      child: _SimulatedMediaQuery(
        width: _simulatedWidth,
        child: MaterialApp.router(
          title: 'zero_adaptive_link example',
          theme: buildAppTheme(),
          routerConfig: _router,
          // Debug-only corner ribbon; a demo does not need the visual noise
          // (and it never appears in release builds anyway).
          // 仅 debug 构建显示的角标；演示不需要这份视觉噪音（release 本就不显示）。
          debugShowCheckedModeBanner: false,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            // The preview strip is a plain `Material`, not an `AppBar`, so it
            // does not reserve the status bar by itself — without this the
            // system status bar paints an opaque band over it on mobile.
            // 预览条是普通 `Material` 而非 `AppBar`，不会自己避让状态栏——
            // 不设置的话移动端的系统状态栏会在它上面压出一条不透明黑带。
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: AppColors.paper,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: ColoredBox(
              // Paper behind everything: nothing above the builder paints a
              // background, so uncovered corners would otherwise show Flutter's
              // raw black surface.
              // 全局铺纸色：builder 之上没有任何背景绘制，未覆盖到的角落
              // 会露出 Flutter 的原始黑色表面。
              color: AppColors.paper,
              child: Column(
                // Stretch the preview strip to the full window width — the
                // horizontally scrollable row only takes its content width and
                // would otherwise sit centered with raw gaps at both ends.
                // 让预览条铺满窗口宽度——横向滚动的行只占内容宽度，否则会
                // 居中且两端露出底色。
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SafeArea(
                    bottom: false,
                    child: _PreviewBar(
                      simulatedWidth: _simulatedWidth,
                      paneSide: _paneSide,
                      onSelected: (width) =>
                          setState(() => _simulatedWidth = width),
                      onPaneSideChanged: (side) => _paneSide.value = side,
                    ),
                  ),
                  Expanded(child: child!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overrides the MediaQuery size while a width preset is active.
/// 宽度预设生效时覆盖 MediaQuery 尺寸。
class _SimulatedMediaQuery extends StatelessWidget {
  const _SimulatedMediaQuery({required this.width, required this.child});

  final double? width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final preset = width;
    if (preset == null) {
      return child;
    }
    final view = PlatformDispatcher.instance.implicitView;
    final base = view == null
        ? const MediaQueryData()
        : MediaQueryData.fromView(view);
    return MediaQuery(
      data: base.copyWith(size: Size(preset, base.size.height)),
      child: child,
    );
  }
}

/// The demo control strip: it drives the simulated width and the pane side.
/// It is a demo tool, not product chrome, so it stays visually quiet.
/// 演示控制条：驱动模拟宽度与 pane 展开方向。它是演示工具而非产品界面，
/// 因此保持视觉低调。
class _PreviewBar extends StatelessWidget {
  const _PreviewBar({
    required this.simulatedWidth,
    required this.paneSide,
    required this.onSelected,
    required this.onPaneSideChanged,
  });

  final double? simulatedWidth;
  final ValueListenable<SlidingPanesSide> paneSide;
  final ValueChanged<double?> onSelected;
  final ValueChanged<SlidingPanesSide> onPaneSideChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDim,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const TagChip(label: 'preview', color: AppColors.muted),
              const SizedBox(width: 10),
              const Text('Width:', style: kCaptionStyle),
              const SizedBox(width: 6),
              for (final preset in kWidthPresets)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: simulatedWidth == preset.width,
                    onSelected: (_) => onSelected(preset.width),
                    labelStyle: kCaptionStyle,
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.pineTint,
                    side: const BorderSide(color: AppColors.hairline),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              TextButton(
                onPressed: () => onSelected(null),
                child: const Text('Window'),
              ),
              const SizedBox(width: 14),
              const Text('Expand:', style: kCaptionStyle),
              const SizedBox(width: 6),
              // The bar must *listen* to the notifier, not just read it once:
              // otherwise the SegmentedButton keeps a stale selection and
              // tapping the stale-selected segment is a no-op.
              // 这里必须*监听* notifier 而不仅是读一次：否则 SegmentedButton
              // 会保留过期的选中态，再点「已选中」的那一段就成了空操作。
              ValueListenableBuilder<SlidingPanesSide>(
                valueListenable: paneSide,
                builder: (context, side, _) =>
                    SegmentedButton<SlidingPanesSide>(
                      selected: {side},
                      onSelectionChanged: (selected) =>
                          onPaneSideChanged(selected.first),
                      style: SegmentedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        selectedBackgroundColor: AppColors.pineTint,
                        foregroundColor: AppColors.inkSoft,
                        selectedForegroundColor: AppColors.pine,
                        side: const BorderSide(color: AppColors.hairline),
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment<SlidingPanesSide>(
                          value: SlidingPanesSide.right,
                          label: Text('Expand right'),
                        ),
                        ButtonSegment<SlidingPanesSide>(
                          value: SlidingPanesSide.left,
                          label: Text('Expand left'),
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact-only top tab bar for the nested Settings shell.
/// 嵌套 Settings shell 在 compact 下专用的顶部 tab 条。
class _SettingsTabBar extends StatelessWidget {
  const _SettingsTabBar({required this.shell});

  final ZeroShellState shell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        SegmentedButton<int>(
          selected: {shell.currentIndex},
          onSelectionChanged: (selected) => shell.goTab(selected.first),
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.surface,
            selectedBackgroundColor: AppColors.pineTint,
            foregroundColor: AppColors.inkSoft,
            selectedForegroundColor: AppColors.pine,
            side: const BorderSide(color: AppColors.hairline),
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(value: 0, label: Text('Profile')),
            ButtonSegment(value: 1, label: Text('Account')),
          ],
        ),
      ],
    );
  }
}

/// A quiet surface for each pane: hairline border, no shadow, no gradient.
/// 每个 pane 的克制表面：发丝边框、无阴影、无渐变。
class _PaneFrame extends StatelessWidget {
  const _PaneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: child,
        ),
      ),
    );
  }
}

class _EmptyDetailPane extends StatelessWidget {
  const _EmptyDetailPane();

  @override
  Widget build(BuildContext context) {
    return const EmptyHint(
      icon: Icons.forum_outlined,
      title: 'No ticket selected',
      subtitle: 'Pick a thread and it opens here.',
    );
  }
}
