# Zero Adaptive Link 零感·自适应链接

<div align="center">

<a href="README.md">English</a> &nbsp;|&nbsp; <strong>简体中文</strong>

</div>

Flutter 的自适应导航：只写**一套 `onTap`**，插件按窗口宽度做出正确行为——移动端推入新页面，Web 与桌面端展开侧栏 pane。URL 可寻址、可深链、零运行时依赖。

[![pub version](https://img.shields.io/pub/v/zero_adaptive_link.svg)](https://pub.dev/packages/zero_adaptive_link)
[![pub points](https://img.shields.io/pub/points/zero_adaptive_link.svg)](https://pub.dev/packages/zero_adaptive_link/score)
[![CI](https://github.com/zero-labsco/zero-adaptive-link/actions/workflows/ci.yml/badge.svg)](https://github.com/zero-labsco/zero-adaptive-link/actions/workflows/ci.yml)
[![License: MPL-2.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://github.com/zero-labsco/zero-adaptive-link/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-green.svg)](https://pub.dev/packages/zero_adaptive_link)
[![Flutter](https://img.shields.io/badge/Flutter-✓-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-✓-0175C2?logo=dart)](https://dart.dev)
[![Style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart)

> **🔔 推荐升级：** `0.3.1` 修复了 `ZeroNav.popFrom(context)` 在 expanded 宽度下让应用空白的问题——该宽度下 pane 上下文解析到 root navigator，旧守卫会 pop 掉 shell route 而非收起 detail pane。`popFrom` 现在与 `maybePop` / `maybePopFrom` 一致：优先关闭框架级路由与 overlay 页，仅当没有可关闭的命令式路由时才走声明式 tab pop。建议所有用户升级到最新版本（`^0.3.1`）。

🌐 **[官方网站](https://www.zerolabsco.com/)** &nbsp;·&nbsp; 📦 **[pub.dev 页面](https://pub.dev/packages/zero_adaptive_link)** &nbsp;·&nbsp; 🔗 **[GitHub 仓库](https://github.com/zero-labsco/zero-adaptive-link)**

---

## 目录

- [功能特性](#功能特性)
- [截图](#截图)
- [安装](#安装)
- [使用](#使用)
  - [一套 onTap，适配所有宽度](#一套-ontap适配所有宽度)
  - [路由表](#路由表)
  - [导航动词](#导航动词)
  - [脱离路由使用布局](#脱离路由使用布局)
- [API 参考](#api-参考)
- [贡献](#贡献)
- [许可证](#许可证)

---

## 功能特性

- **一套 `onTap`，适配所有宽度** —— 用 `ZeroLink` 包裹任意可点击组件（或用 `ZeroNav` 命令式调用）；插件按**窗口宽度**而非设备类型决策，折叠屏、桌面小窗、浏览器缩放都能正确行为。
- **断点按窗口宽度** —— `< 600` compact 推页面，`600 – 839` medium 推页面（单列），`>= 840` expanded 展开或更新右侧侧栏 pane。
- **master-detail pane 语义** —— detail pane 从 `paneSide` 指定的一侧滑入（默认向右、master 在左；设为向左则镜像：master 在右、detail 从左滑入）；分割线可拖拽调整两列比例；三列及以上刻意不做。
- **pane 转场动画** —— detail pane 首次展开时滑入；更深层级 push 时视口整体左移一列（被替换的 master 退出、新的一对滑入）；pop 时反向移回。
- **宽度变化状态不丢** —— 窗口跨越断点时，页面与 expanded pane 于同帧交接同一子树，滚动偏移与文本输入不会重置；稳定键以 `ZeroRouteState.pageKey` 暴露。
- **向左或向右展开** —— 通过 `paneSide` 选择 `SlidingPanesSide.right`（master 在左）或 `SlidingPanesSide.left`（master 在右）；用 `paneSideListenable` 可在运行时切换展开方向而无需重建路由。
- **带上限的 pane 尺寸** —— 用 `leftPaneFraction` 设置初始分栏比例，用 `maxLeftPaneWidth` 让 master pane 仍随窗口缩放但在超宽屏停在合理宽度（剩余空间由 detail 吸收，拖拽同样受上限约束）。
- **幂等聚焦** —— 点击已可见的 pane 时聚焦它，而不是堆叠重复 pane。
- **URL 可寻址、可深链** —— 每个页面都入表，URL 才能表达它；Web 默认 hash 策略（`/#/products/42`），浏览器返回、刷新、深链与应用内导航走同一条 location 管道（GitHub Pages 无需 404 fallback）。
- **声明式路由表** —— 嵌套路由、`:param` 片段、路由名称、标题、路由表级与路由级重定向、`onExit` 钩子、`fullscreen` / `fullscreenDialog` 覆盖层、自定义转场与 `errorBuilder`。
- **与 Navigator 同形的导航动词** —— `pushNamed` / `pop` / `maybePop` / `popUntil` / `canPop` 等与 `NavigatorState` 同名同签名，迁移零成本。
- **行为正确的 compact chrome** —— 底部 `NavigationBar` 渲染进 branch 页面内部，`useRootNavigator: false` 打开的 bottom sheet 可覆盖它；系统返回键先关闭 sheet。
- **零运行时依赖** —— 纯 Dart，无 platform channel、无原生代码；仅用 `ValueNotifier` / `InheritedWidget`。
- **脱离路由也能用布局** —— `SlidingPanes`、`SlidingPane`、`Breadcrumbs` 均为公开组件，可单独使用。

---

## 截图

> 截图尚未采集。运行示例（`cd example && flutter run -d chrome`）并通过宽度预设 chips（Phone 480 / Foldable 720 / Tablet 1023 / Desktop）即可并排查看三种行为。

---

## 安装

### Pub.dev（推荐）

```yaml
dependencies:
  zero_adaptive_link: ^0.3.1
```

### GitHub

```yaml
dependencies:
  zero_adaptive_link:
    git:
      url: https://github.com/zero-labsco/zero-adaptive-link.git
      ref: release/v0.3.1   # 将 0.3.1 替换为所需版本
```

---

## 使用

### 一套 onTap，适配所有宽度

```dart
import 'package:flutter/material.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() => runApp(MaterialApp.router(routerConfig: myRouter));

// 声明式：包裹任意可点击组件。
final listTile = ZeroLink(
  location: '/products/42',
  child: const ListTile(title: Text('Product 42')),
);

// 命令式：任意回调中均可使用。
void openProduct(BuildContext context) {
  ZeroNav.of(context).open('/products/42');
}
```

同一套点击在不同宽度下的行为：

| 窗口宽度 | 档位 | `onTap` 行为 |
| --- | --- | --- |
| `< 600` | compact | push 新页面（经典 Navigator 栈） |
| `600 – 839` | medium | push 新页面（单列，shell chrome 不同） |
| `>= 840` | expanded | 展开 / 更新右侧侧栏 pane（master-detail） |

### 路由表

```dart
final router = ZeroRouter(
  initialLocation: '/products',
  routes: [
    ZeroShell(
      builder: (context, shell, child) => shell.isExpanded
          ? Row(children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) => shell.goTab(i),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.list),
                    label: Text('Products'),
                  ),
                ],
              ),
              Expanded(child: child),
            ])
          : Scaffold(
              body: child,
              bottomNavigationBar: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) => shell.goTab(i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.list), label: 'Products'),
                ],
              ),
            ),
      tabs: [
        ZeroTab(routes: [
          ZeroRoute(
            path: '/products',
            title: (state) => 'Products',
            builder: (context, state) => const ProductListPage(),
            routes: [
              ZeroRoute(
                path: ':id',
                title: (state) => 'Product ${state.pathParameters['id']}',
                builder: (context, state) =>
                    ProductDetailPage(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ]),
      ],
    ),
  ],
);
```

规则：子路径相对父路径；`:param` 匹配单个路径片段；首个匹配获胜；每个页面必须入表，URL 才能表达它。

### 导航动词

```dart
final nav = ZeroNav.of(context);

nav.open('/products/42');                       // 自适应 push / 展开 pane
await nav.pushNamedAndRemoveUntil('/cart', (match) => false);
nav.maybePop();                                 // 先问 PopScope，再问 onExit
nav.popUntil((match) => match.location == '/products');
nav.location;                                   // '/products/42'
nav.locationListenable;                         // ValueListenable<String>
```

### 脱离路由使用布局

```dart
SlidingPanes(children: [masterPane, detailPane]);   // 单列 / 双列
Breadcrumbs(items: ['/products', '/products/42'], onNavigate: (i) => …);
```

detail pane 默认向右展开。要镜像布局——master 在右、detail 从左滑入——用 `side`：

```dart
SlidingPanes(
  side: SlidingPanesSide.left,   // master 在右
  maxLeftPaneWidth: 360,         // 超宽窗口不再继续变宽
  children: [masterPane, detailPane],
);
```

配合路由时，在 `ZeroRouter` 上设置 `paneSide`（或用 `paneSideListenable` 实时驱动）切换展开方向，并用 `leftPaneFraction` / `maxLeftPaneWidth` 控制分栏比例。

---

## API 参考

### ZeroLink

| 参数 | 类型 | 说明 |
|-----------|------|-------------|
| `location` | `String` | 目标 location |
| `child` | `Widget` | 可点击内容 |
| `onTap` | `VoidCallback?` | 覆盖默认的打开行为 |
| `cursor` | `MouseCursor?` | 默认为 web / 桌面端的手型光标 |

### ZeroNav

| 成员 | 说明 |
|--------|-------------|
| `open(location)` | 自适应 push / 展开 pane |
| `pushNamed` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` / `popAndPushNamed` | 与 Navigator 同形的导航动词 |
| `pop` / `maybePop` / `popFrom` / `maybePopFrom` / `popUntil` / `canPop` | pop 系动词 |
| `namedLocation(name, pathParameters:, queryParameters:)` | 由命名路由构建 location |
| `refresh()` | 重跑重定向（例如登录态变化后） |
| `location` / `locationListenable` | 当前 location，以及供响应式 UI 使用的 listenable |

### ZeroRoute

| 参数 | 类型 | 说明 |
|-----------|------|-------------|
| `path` | `String` | 相对父路径的 pattern（支持 `:param`） |
| `name` | `String?` | 供 `namedLocation` 使用的名称 |
| `builder` | `Widget Function(BuildContext, ZeroRouteState)` | 页面内容 |
| `title` | `String Function(ZeroRouteState)?` | match 时求值一次 |
| `redirect` | `FutureOr<String?> Function(ZeroRouteState)?` | 路由级重定向 |
| `onExit` | `FutureOr<bool> Function()?` | pop 前询问的否决钩子 |
| `fullscreen` / `fullscreenDialog` | `bool` | 在任何宽度下覆盖 shell |
| `hidesBottomBarWhenPushed` | `bool` | push 时隐藏 compact 底部栏（默认 `true`） |
| `opaque` / `barrierColor` / `barrierDismissible` | — | 模态路由属性 |
| `transitionsBuilder` | `RouteTransitionsBuilder?` | 自定义页面转场 |
| `routes` | `List<ZeroRoute>` | 嵌套路由 |

### Breakpoints

| 字段 | 默认值 | 含义 |
|-------|---------|-------|
| `compactMaxWidth` | `600` | 低于该宽度为 compact |
| `expandedMinWidth` | `840` | 大于等于该宽度为 expanded |

---

## 贡献

欢迎贡献！提交 issue 或 pull request 前请先阅读[贡献指南](CONTRIBUTING.md)。

- 🐛 [报告 Bug](https://github.com/zero-labsco/zero-adaptive-link/issues/new?template=bug_report.md)
- 💡 [提出功能需求](https://github.com/zero-labsco/zero-adaptive-link/issues/new?template=feature_request.md)
- 💬 [参与讨论](https://github.com/zero-labsco/zero-adaptive-link/discussions)
- 📖 [贡献指南](CONTRIBUTING.md)

---

## 许可证

Copyright (c) 2026 Zero Labs Co. (AmisKwok)。本项目采用 **Mozilla Public License 2.0 (MPL-2.0)** 许可证——详见 [LICENSE](LICENSE) 文件。版权声明与附加声明（无担保、无背书）见 [NOTICE](NOTICE)。

- **允许商业使用。** 使用、修改与闭源分发均被允许。
- **修改了插件？** 被修改的文件必须以 MPL-2.0 开源形式发布。你自己的应用**无需**开源。
- **未修改直接使用？** 无需公开源代码。
- **无背书。** 未经事先书面许可，"Zero Labs Co."、"zero_adaptive_link"、logo / 吉祥物美术作品以及作者姓名（AmisKwok）不得用于为衍生品背书或暗示赞助 / 隶属关系。
- **无担保、无责任。** 版权持有人不对任何修改版或衍生版提供担保或承担责任；修改版必须明确标注已被修改。

本插件按"原样"提供，不提供任何担保。作者不对修改版或衍生项目的功能、安全性及任何使用后果承担责任。
