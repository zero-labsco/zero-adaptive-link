# Zero Adaptive Link

**One tap. Every platform does the right thing.**

Adaptive navigation for Flutter: write **one `onTap`** and the plugin decides by window width whether to push a new page (mobile) or expand a sidebar pane (web and desktop). URL-addressable, deep-linkable, zero runtime dependencies.

**一套 `onTap`，任意平台都做出正确行为。**

Flutter 的自适应导航：只写**一套 `onTap`**，插件按窗口宽度决定移动端推入新页面、Web 与桌面端展开侧栏 pane。URL 可寻址、可深链、零运行时依赖。

## ✨ Features / 功能特性

| Feature | Description |
|---------|-------------|
| **One onTap** | `ZeroLink` or `ZeroNav` — the same tap adapts per width / 同一套点击按宽度自适应 |
| **Window-width breakpoints** | 600 / 840 by window width, not device type / 断点按窗口宽度而非设备类型 |
| **Master-detail panes** | Slide-in detail, parallax master, draggable resize handle / detail 右滑入、master 视差、可拖拽分割线 |
| **Idempotent focus** | Tapping a visible pane focuses it / 点击已可见 pane 时聚焦而非重复展开 |
| **Deep links** | Hash strategy on web, browser back works / Web hash 策略，浏览器返回可用 |
| **Declarative route table** | Nested routes, `:param`, redirects, `onExit`, fullscreen / 嵌套路由、参数、重定向、退出钩子、全屏覆盖 |
| **Nested shells** | A `ZeroRoute` hosts its own `ZeroShell` via `shell` + `shellBuilder` / 路由可通过 `shell` + `shellBuilder` 承载自己的 `ZeroShell` |
| **Real web anchors** | `ZeroAnchor` renders a genuine DOM `<a href>`; `canonicalHref` shares it / `ZeroAnchor` 渲染真正的 DOM `<a href>`；`canonicalHref` 返回可分享链接 |
| **Scroll & focus restoration** | Offsets and focus survive breakpoint crossings and history / 滚动偏移与焦点跨断点、跨历史保留 |
| **Navigator-shaped verbs** | `pushNamed` / `pop` / `maybePop` / `popUntil` / `canPop` / 与 Navigator 同名同签名 |
| **Zero runtime deps** | Pure Dart, no platform channels / 纯 Dart，无 platform channel |
| **Layout standalone** | `SlidingPanes` / `SlidingPane` / `Breadcrumbs` usable alone / 布局组件可单独使用 |

## 🚀 Quick start / 快速开始

```dart
import 'package:flutter/material.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() => runApp(MaterialApp.router(routerConfig: myRouter));

// Declarative: wrap any tappable widget. / 声明式：包裹任意可点击组件。
final tile = ZeroLink(
  location: '/products/42',
  child: const ListTile(title: Text('Product 42')),
);

// Imperative: from any callback. / 命令式：任意回调中均可使用。
void open(BuildContext context) => ZeroNav.of(context).open('/products/42');
```

## 📚 Table of Contents / 目录

| Page | Description |
|------|-------------|
| [Getting Started](Getting-Started) | 60-second integration / 60 秒接入 |
| [Installation](Installation) | pub.dev & GitHub / 安装方式 |
| [Usage](Usage) | `ZeroLink` / `ZeroNav` entry points / 两种入口 |
| [Adaptive Behavior](Adaptive-Behavior) | Behavior matrix, breakpoints, pane semantics / 行为矩阵、断点、pane 语义 |
| [Route Table](Route-Table) | `ZeroRoute` / `ZeroShell` / `ZeroTab` / 路由表 |
| [Navigation](Navigation) | Verbs, pop semantics, exit confirmation / 导航动词、pop 语义、退出确认 |
| [Layout Without Router](Layout-Without-Router) | `SlidingPanes` standalone / 单独使用布局组件 |
| [FAQ](FAQ) | Cross-breakpoint rebuilds, overlays, hash strategy / 跨断点重建、覆盖层、hash 策略 |

## 🔗 Links / 链接

- [GitHub](https://github.com/zero-labsco/zero-adaptive-link)
- [Official Website](https://www.zerolabsco.com/)
- [pub.dev](https://pub.dev/packages/zero_adaptive_link)

## 📄 License / 许可证

This project is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

本项目采用 Mozilla Public License 2.0 (MPL-2.0) 许可证。

This plugin is provided "as is", without warranty of any kind. The author assumes no responsibility or liability for the functionality, security, or any consequences arising from the use of modified versions or derivative projects.

本插件按"原样"提供，不提供任何担保。作者不对修改版或衍生项目的功能、安全性及任何使用后果承担责任。
