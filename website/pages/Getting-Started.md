# Getting Started / 快速开始

## 60-second integration / 60 秒接入

```dart
import 'package:flutter/material.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() => runApp(MaterialApp.router(routerConfig: myRouter));

final myRouter = ZeroRouter(
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
          : Scaffold(body: child),
      tabs: [
        ZeroTab(routes: [
          ZeroRoute(
            path: '/products',
            builder: (context, state) => const ProductListPage(),
            routes: [
              ZeroRoute(
                path: ':id',
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

And the first link:

```dart
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView(
        children: [
          ZeroLink(
            location: '/products/42',
            child: const ListTile(title: Text('Product 42')),
          ),
        ],
      ),
    );
  }
}
```

## What happens automatically / 自动发生的事情

| Width | Behavior |
|-------|----------|
| `< 600` (compact) | Tapping pushes a new page on the Navigator stack / 点击 push 新页面 |
| `600 – 839` (medium) | Same push, single column / 同样 push，单列 |
| `>= 840` (expanded) | Tapping expands the right sidebar pane / 点击展开右侧侧栏 pane |
| Pane already visible | Focus it, no duplicate expansion / 聚焦，不重复展开 |
| Web | The URL updates (`/#/products/42`); browser back pops / URL 同步更新；浏览器返回逐级退回 |

## Next steps / 下一步

- [Installation](Installation) — detailed installation methods / 详细安装方式
- [Usage](Usage) — full usage guide / 完整使用指南
- [Adaptive Behavior](Adaptive-Behavior) — the behavior matrix / 行为矩阵
- [Route Table](Route-Table) — configuring routes / 配置路由
