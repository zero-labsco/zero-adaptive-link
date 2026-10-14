import 'package:flutter/material.dart';

/// Design tokens for the example app.
/// 示例应用的设计变量。
///
/// Deliberately restrained: one accent, hairline rules, no gradients and no
/// glow — the point of this app is to show what the plugin does, not to
/// decorate the demo.
/// 刻意克制：单一强调色、发丝级分隔线、无渐变无发光——本应用的重点是展示插件
/// 行为，而不是装饰演示。
class AppColors {
  const AppColors._();

  /// Warm paper background. / 暖纸质背景。
  static const paper = Color(0xFFF5F3EE);

  /// Raised surface. / 抬升的表面。
  static const surface = Color(0xFFFFFFFF);

  /// Recessed surface (rails, toolbars). / 下沉表面（导航栏、工具条）。
  static const surfaceDim = Color(0xFFEBE8E0);

  /// Primary text. / 主文本。
  static const ink = Color(0xFF16181A);

  /// Secondary text. / 次级文本。
  static const inkSoft = Color(0xFF4A4F52);

  /// Captions and meta text. / 说明与元信息文本。
  static const muted = Color(0xFF78736B);

  /// Hairline rules. / 发丝分隔线。
  static const hairline = Color(0xFFE2DED5);

  /// Primary accent (deep pine). / 主强调色（深松绿）。
  static const pine = Color(0xFF1F4E43);

  /// Accent tint background. / 强调色淡底。
  static const pineTint = Color(0xFFE6EDEA);

  /// Secondary accent (clay), reserved for urgency. / 次级强调色（陶土），仅用于紧急。
  static const clay = Color(0xFFB4552F);

  /// Clay tint background. / 陶土淡底。
  static const clayTint = Color(0xFFF7E9E2);

  /// Neutral badge colour. / 中性徽标色。
  static const slate = Color(0xFF42596B);

  /// Neutral badge tint. / 中性徽标淡底。
  static const slateTint = Color(0xFFE9EDF1);
}

/// Headline style used by page titles. / 页面标题使用的标题样式。
const TextStyle kTitleStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
  letterSpacing: -0.2,
);

/// Body style for ticket subjects. / 工单主题的正文字体。
const TextStyle kSubjectStyle = TextStyle(
  fontSize: 14.5,
  fontWeight: FontWeight.w600,
  color: AppColors.ink,
  height: 1.3,
);

/// Secondary line style. / 次级行样式。
const TextStyle kSnippetStyle = TextStyle(
  fontSize: 13,
  color: AppColors.muted,
  height: 1.35,
);

/// Small caption style. / 小号说明样式。
const TextStyle kCaptionStyle = TextStyle(
  fontSize: 11.5,
  color: AppColors.muted,
  height: 1.3,
);

/// Builds the app theme. / 构建应用主题。
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.pine,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.pine,
        onPrimary: Colors.white,
        secondary: AppColors.clay,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.surfaceDim,
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    canvasColor: AppColors.paper,
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
      space: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: kTitleStyle,
      iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.pine),
    ),
  );
}

/// A hairline placed under an app bar (an `AppBar.bottom` slot, so it must
/// report its own preferred size).
/// 置于 AppBar 下方的发丝线（用于 `AppBar.bottom`，因此需自报 preferredSize）。
class AppBarRule extends StatelessWidget implements PreferredSizeWidget {
  const AppBarRule({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.hairline);
  }
}

/// The wordmark and geometric mark shown in rails and headers.
/// 导航栏与页头中显示的字标与几何标记。
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 22, this.showWordmark = true, super.key});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size, size), painter: _MarkPainter()),
        if (showWordmark) ...[
          SizedBox(width: size * 0.4),
          Text(
            'Dispatch',
            style: TextStyle(
              fontSize: size * 0.74,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Two offset rounded bars — a stylised running-tally mark.
/// 两条错位圆角竖条——风格化的累计标记。
class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.pine;
    final barWidth = size.width * 0.26;
    final radius = Radius.circular(barWidth / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.06, barWidth, size.height * 0.94),
        radius,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width - barWidth,
          size.height * 0.34,
          barWidth,
          size.height * 0.66,
        ),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter oldDelegate) => false;
}
