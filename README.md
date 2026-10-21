# Zero Adaptive Link

<div align="center">

<strong>English</strong> &nbsp;|&nbsp; <a href="README_zh.md">简体中文</a>

</div>

Adaptive navigation for Flutter: write **one `onTap`** and the plugin does the right thing at every window width — push a new page on mobile, expand a sidebar pane on web and desktop. URL-addressable, deep-linkable, zero runtime dependencies.

[![pub version](https://img.shields.io/pub/v/zero_adaptive_link.svg)](https://pub.dev/packages/zero_adaptive_link)
[![pub points](https://img.shields.io/pub/points/zero_adaptive_link.svg)](https://pub.dev/packages/zero_adaptive_link/score)
[![CI](https://github.com/zero-labsco/zero-adaptive-link/actions/workflows/ci.yml/badge.svg)](https://github.com/zero-labsco/zero-adaptive-link/actions/workflows/ci.yml)
[![License: MPL-2.0](https://img.shields.io/badge/License-MPL--2.0-blue.svg)](https://github.com/zero-labsco/zero-adaptive-link/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-green.svg)](https://pub.dev/packages/zero_adaptive_link)
[![Flutter](https://img.shields.io/badge/Flutter-✓-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-✓-0175C2?logo=dart)](https://dart.dev)
[![Style: effective dart](https://img.shields.io/badge/style-effective_dart-40c4ff.svg)](https://pub.dev/packages/effective_dart)

> **🔔 Upgrade recommended:** `0.5.0` adds nested `ZeroShell` (a `ZeroRoute` can host its own tabs / panes via `ZeroRoute.shell` + `shellBuilder`), real web `<a href>` anchors so links open in a new tab and preview correctly, and scroll & focus restoration across breakpoint crossings and browser history. It also keeps `ZeroLink` accessible, `ZeroRouter.onNavigation`, `ZeroRoute.loader`, swipe-to-dismiss, `ZeroNavigationChrome`, branch breadcrumbs, and explicit `preferredTab` / `ZeroLink.tabIndex`. All users are encouraged to upgrade to the latest version (`^0.5.0`).

🌐 **[Official Website](https://www.zerolabsco.com/)** &nbsp;·&nbsp; 📦 **[View on pub.dev](https://pub.dev/packages/zero_adaptive_link)** &nbsp;·&nbsp; 🔗 **[View on GitHub](https://github.com/zero-labsco/zero-adaptive-link)**

---

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
  - [One onTap, Every Width](#one-ontap-every-width)
  - [Route Table](#route-table)
  - [Navigation Verbs](#navigation-verbs)
  - [Layout Without the Router](#layout-without-the-router)
- [API Reference](#api-reference)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **One `onTap`, every width** — wrap any tappable widget with `ZeroLink` (or call `ZeroNav` imperatively); the plugin decides by **window width**, not device type, so foldables, small desktop windows and browser zoom all behave correctly.
- **Breakpoints by window width** — `< 600` compact pushes a page, `600 – 839` medium pushes a page (single column), `>= 840` expanded expands or updates the right sidebar pane.
- **Master-detail pane semantics** — the detail pane slides in from the side set by `paneSide` (right by default, or left to mirror the layout: master on the right, detail from the left); a draggable resize handle splits the two columns; three or more columns are deliberately out of scope.
- **Animated pane transitions** — the detail pane slides in on its first expansion, a deeper push slides the viewport left by one column (the replaced master exits, the new pair slides in), and a pop slides it back.
- **State survives width changes** — pages and expanded panes hand the same subtree over in the same frame when the window crosses a breakpoint, so scroll offsets and text input do not reset; the stable key is exposed as `ZeroRouteState.pageKey`.
- **Expand left or right** — pick `SlidingPanesSide.right` (master on the left) or `SlidingPanesSide.left` (master on the right) via `paneSide`, and flip it at runtime with `paneSideListenable` without rebuilding the router.
- **Pane sizing with a ceiling** — set `leftPaneFraction` for the initial split and `maxLeftPaneWidth` so the master pane still scales with the window but stops at a sane width on ultra-wide displays (the detail pane absorbs the remainder; dragging respects the ceiling too).
- **Idempotent focus** — tapping an already visible pane focuses it instead of stacking a duplicate.
- **URL-addressable and deep-linkable** — every screen is in the route table, so its URL can express it; on the web the hash strategy (`/#/products/42`) keeps browser back, refresh and deep links on the same location pipeline as in-app navigation (GitHub Pages needs no 404 fallback).
- **Declarative route table** — nested routes, `:param` segments, route names, titles, router-level and route-level redirects, `onExit` hooks, `fullscreen` / `fullscreenDialog` overlays, custom transitions and an `errorBuilder`.
- **Navigator-shaped verbs** — `pushNamed` / `pop` / `maybePop` / `popUntil` / `canPop` and friends share their names and signatures with `NavigatorState`, so migration costs nothing.
- **Compact chrome that behaves** — the bottom `NavigationBar` is rendered inside branch pages, so a bottom sheet opened with `useRootNavigator: false` covers it; the system back button closes the sheet first.
- **Zero runtime dependencies** — pure Dart, no platform channels, no native code; `ValueNotifier` / `InheritedWidget` only.
- **Layout without the router** — `SlidingPanes`, `SlidingPane` and `Breadcrumbs` are public and usable on their own.

---

## Screenshots

> Screenshots are not captured yet. Run the example (`cd example && flutter run -d chrome`) and use the width preset chips (Phone 480 / Foldable 720 / Tablet 1023 / Desktop) to see all three behaviors side by side.
>
> 截图尚未采集。运行示例（`cd example && flutter run -d chrome`）并通过宽度预设 chips（Phone 480 / Foldable 720 / Tablet 1023 / Desktop）即可并排查看三种行为。

---

## Installation

### Pub.dev (Recommended)

```yaml
dependencies:
  zero_adaptive_link: ^0.5.0
```

### GitHub

```yaml
dependencies:
  zero_adaptive_link:
    git:
      url: https://github.com/zero-labsco/zero-adaptive-link.git
      ref: release/v0.5.0   # replace 0.5.0 with the version you need
```

---

## Usage

### One onTap, Every Width

```dart
import 'package:flutter/material.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() => runApp(MaterialApp.router(routerConfig: myRouter));

// Declarative: wrap any tappable widget. / 声明式：包裹任意可点击组件。
final listTile = ZeroLink(
  location: '/products/42',
  child: const ListTile(title: Text('Product 42')),
);

// Imperative: from any callback. / 命令式：任意回调中均可使用。
void openProduct(BuildContext context) {
  ZeroNav.of(context).open('/products/42');
}
```

The same tap behaves differently per width:

| Window width | Class | `onTap` behavior |
| --- | --- | --- |
| `< 600` | compact | push a new page (classic Navigator stack) |
| `600 – 839` | medium | push a new page (single column, different shell chrome) |
| `>= 840` | expanded | expand / update the right sidebar pane (master-detail) |

### Route Table

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

Rules: child paths are relative to their parent; `:param` matches a single path segment; the first match wins; every page must be in the table so its URL can express it.

### Navigation Verbs

```dart
final nav = ZeroNav.of(context);

nav.open('/products/42');                       // adaptive push / pane expand
await nav.pushNamedAndRemoveUntil('/cart', (match) => false);
nav.maybePop();                                 // PopScope first, then onExit
nav.popUntil((match) => match.location == '/products');
nav.location;                                   // '/products/42'
nav.locationListenable;                         // ValueListenable<String>
```

### Layout Without the Router

```dart
SlidingPanes(children: [masterPane, detailPane]);   // 1/2 columns
Breadcrumbs(items: ['/products', '/products/42'], onNavigate: (i) => …);
```

The detail pane expands to the right by default. Mirror the layout — master on
the right, detail sliding in from the left — with `side`:

```dart
SlidingPanes(
  side: SlidingPanesSide.left,   // master on the right
  maxLeftPaneWidth: 360,         // stop growing on ultra-wide windows
  children: [masterPane, detailPane],
);
```

With the router, set `paneSide` on `ZeroRouter` (or drive it live via
`paneSideListenable`) to flip the expanded layout at runtime, and
`leftPaneFraction` / `maxLeftPaneWidth` to control the split.

默认 detail pane 向右展开。要镜像布局——master 在右、detail 从左滑入——用
`side`；用 `maxLeftPaneWidth` 可让 master 在超宽窗口停止变宽：

```dart
SlidingPanes(
  side: SlidingPanesSide.left,   // master 在右
  maxLeftPaneWidth: 360,         // 超宽窗口不再继续变宽
  children: [masterPane, detailPane],
);
```

配合路由时，在 `ZeroRouter` 上设置 `paneSide`（或用 `paneSideListenable`
实时驱动）切换展开方向，并用 `leftPaneFraction` / `maxLeftPaneWidth`
控制分栏比例。

---

## API Reference

### ZeroLink

| Parameter | Type | Description |
|-----------|------|-------------|
| `location` | `String` | Target location |
| `child` | `Widget` | The tappable content |
| `onTap` | `VoidCallback?` | Overrides the default open behavior |
| `cursor` | `MouseCursor?` | Defaults to a hand cursor on web / desktop |

### ZeroNav

| Member | Description |
|--------|-------------|
| `open(location)` | Adaptive push / pane expand |
| `pushNamed` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` / `popAndPushNamed` | Navigator-shaped verbs |
| `pop` / `maybePop` / `popFrom` / `maybePopFrom` / `popUntil` / `canPop` | Pop verbs |
| `namedLocation(name, pathParameters:, queryParameters:)` | Build a location from a named route |
| `refresh()` | Re-run redirects (e.g. after an auth change) |
| `location` / `locationListenable` | Current location, plus a listenable for reactive UI |

### ZeroRoute

| Parameter | Type | Description |
|-----------|------|-------------|
| `path` | `String` | Pattern relative to the parent (`:param` supported) |
| `name` | `String?` | Name for `namedLocation` |
| `builder` | `Widget Function(BuildContext, ZeroRouteState)` | Page content |
| `title` | `String Function(ZeroRouteState)?` | Evaluated once at match time |
| `redirect` | `FutureOr<String?> Function(ZeroRouteState)?` | Route-level redirect |
| `onExit` | `FutureOr<bool> Function()?` | Veto hook consulted before popping |
| `fullscreen` / `fullscreenDialog` | `bool` | Cover the shell at any width |
| `hidesBottomBarWhenPushed` | `bool` | Hide the compact bottom bar (default `true`) |
| `opaque` / `barrierColor` / `barrierDismissible` | — | Modal route properties |
| `transitionsBuilder` | `RouteTransitionsBuilder?` | Custom page transitions |
| `routes` | `List<ZeroRoute>` | Nested routes |

### Breakpoints

| Field | Default | Meaning |
|-------|---------|---------|
| `compactMaxWidth` | `600` | Below → compact |
| `expandedMinWidth` | `840` | At or above → expanded |

---

## Contributing

Contributions are welcome! Please read the [Contributing Guidelines](CONTRIBUTING.md) before submitting issues or pull requests.

- 🐛 [Report a Bug](https://github.com/zero-labsco/zero-adaptive-link/issues/new?template=bug_report.md)
- 💡 [Request a Feature](https://github.com/zero-labsco/zero-adaptive-link/issues/new?template=feature_request.md)
- 💬 [Join Discussions](https://github.com/zero-labsco/zero-adaptive-link/discussions)
- 📖 [Contributing Guide](CONTRIBUTING.md)

---

## License

Copyright (c) 2026 Zero Labs Co. (AmisKwok). This project is licensed under the **Mozilla Public License 2.0 (MPL-2.0)** — see the [LICENSE](LICENSE) file for details. The copyright notice and additional statements (no warranty, no endorsement) live in [NOTICE](NOTICE).

- **Commercial use is allowed.** Use, modification and closed-source distribution are permitted.
- **Modified the plugin?** The files you modified must be published in source form under MPL-2.0. Your own app does **not** need to be open-sourced.
- **Used it unmodified?** No source disclosure is required.
- **No endorsement.** "Zero Labs Co.", "zero_adaptive_link", the logo / mascot artwork, and the author's name (AmisKwok) may not be used to endorse or promote derived products, or to imply sponsorship or affiliation, without prior written permission.
- **No warranty, no liability.** The copyright holder provides no warranty and accepts no liability for any modified or derivative version; modified versions must be clearly marked as modified.

This plugin is provided "as is", without warranty of any kind. The author assumes no responsibility or liability for the functionality, security, or any consequences arising from the use of modified versions or derivative projects.
