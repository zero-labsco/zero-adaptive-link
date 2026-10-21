import 'package:flutter/widgets.dart';
import 'package:zero_adaptive_link/src/widgets/zero_link.dart';

/// Non-web fallback: a `ZeroAnchor` is simply a [ZeroLink].
/// 非 web 回退：ZeroAnchor 就是 ZeroLink。
class ZeroAnchor extends StatelessWidget {
  /// Create the anchor. / 创建锚点。
  const ZeroAnchor({
    required this.location,
    required this.label,
    this.mode = ZeroLinkMode.push,
    this.tabIndex,
    this.arguments,
    super.key,
  });

  /// The target location. / 目标 location。
  final String location;

  /// The anchor text. / 锚点文字。
  final String label;

  /// How the link opens (passed through to [ZeroLink]).
  /// 打开方式（透传给 [ZeroLink]）。
  final ZeroLinkMode mode;

  /// Open [location] in this tab specifically. / 在指定 tab 打开 [location]。
  final int? tabIndex;

  /// Arguments forwarded to the navigation verbs. / 透传给导航动词的参数。
  final Object? arguments;

  @override
  Widget build(BuildContext context) => ZeroLink(
    location: location,
    mode: mode,
    tabIndex: tabIndex,
    arguments: arguments,
    child: Text(label),
  );
}
