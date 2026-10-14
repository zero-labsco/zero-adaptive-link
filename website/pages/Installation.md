# Installation / 安装

## From pub.dev (Recommended) / 从 pub.dev 安装（推荐）

```yaml
dependencies:
  zero_adaptive_link: ^__ZAL_VERSION__
```

Then run:

```bash
flutter pub get
```

## From GitHub / 从 GitHub 安装

```yaml
dependencies:
  zero_adaptive_link:
    git:
      url: https://github.com/zero-labsco/zero_adaptive_link.git
      ref: release/v__ZAL_VERSION__   # replace __ZAL_VERSION__ with the version you need
```

## Platform support / 平台支持

| Platform | Supported |
|----------|-----------|
| Android | ✅ |
| iOS | ✅ |
| Web | ✅ (hash URL strategy by default / 默认 hash 策略) |
| Windows / macOS / Linux | ✅ |

The plugin is **pure Dart**: there are no `android/` or `ios/` directories, no method channels, and no additional platform setup.

本插件为**纯 Dart**：没有 `android/` 或 `ios/` 目录、没有 method channel、无需额外平台配置。

## Requirements / 环境要求

- Flutter `>= 3.3.0`
- Dart SDK `>= 3.11.0 < 4.0.0`
- Zero runtime third-party dependencies / 零运行时第三方依赖

## Verifying the installation / 验证安装

Run the bundled example:

```bash
git clone https://github.com/zero-labsco/zero_adaptive_link.git
cd zero_adaptive_link/example
flutter run -d chrome
```

Use the width preset chips (Phone 480 / Foldable 720 / Tablet 1023 / Desktop) to switch widths and verify all three behaviors.

使用宽度预设 chips（Phone 480 / Foldable 720 / Tablet 1023 / Desktop）切换宽度，验证三种行为。
