import 'package:flutter/material.dart';

import 'theme.dart';

/// A circular avatar showing the customer's initials — no emoji, no gradient.
/// 显示客户首字母的圆形头像——无 emoji、无渐变。
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({required this.initials, this.size = 36, super.key});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.pineTint,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: AppColors.pine,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// A small filled dot used as a status indicator.
/// 用作状态指示的小实心点。
class StatusDot extends StatelessWidget {
  const StatusDot({required this.color, this.size = 7, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}

/// A small label chip with a hairline border — no glow, no gradient fill.
/// 带发丝边框的小标签——无发光、无渐变填充。
class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    this.color = AppColors.slate,
    this.background = AppColors.slateTint,
    super.key,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// An uppercase section label. / 大写的分组标题。
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 0.9,
      ),
    );
  }
}

/// A calm empty state: an outlined icon plus one short line of copy.
/// 克制的空状态：一个线性图标加一句简短说明。
class EmptyHint extends StatelessWidget {
  const EmptyHint({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: AppColors.hairline),
          const SizedBox(height: 12),
          Text(title, style: kSubjectStyle.copyWith(color: AppColors.muted)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: kCaptionStyle),
          ],
        ],
      ),
    );
  }
}

/// A label / value row used for profile and plan details.
/// 用于资料与套餐详情的「标签 / 取值」行。
class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: kSnippetStyle)),
          Expanded(child: Text(value, style: kSubjectStyle)),
        ],
      ),
    );
  }
}
