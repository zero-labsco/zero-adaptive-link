import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:zero_adaptive_link/src/router/router.dart';
import 'package:zero_adaptive_link/src/widgets/zero_link.dart';

/// `document.createElement` bound as a top-level interop function.
/// 顶层 interop 绑定的 `document.createElement`。
@JS('document.createElement')
external JSAny _createElement(String tag);

/// Interop view of a DOM `<a>` element. / DOM `<a>` 元素的 interop 视图。
@JS()
@staticInterop
class HTMLAnchorElement {}

/// Dart setters mapped to the element's JS properties.
/// 映射到元素 JS 属性的 Dart setter。
extension HTMLAnchorElementExtension on HTMLAnchorElement {
  external set href(String value);
  external set textContent(String value);
  external set style(String value);
}

/// A genuine DOM `<a href="#location">` rendered on the web, so links open in a
/// new tab and preview correctly in the browser. Clicking changes
/// `window.location.hash`, which the hash provider already observes — the router
/// therefore navigates without a full page reload.
/// 在 web 上渲染真正的 DOM `<a href="#location">`，使链接可在新标签打开、
/// 在浏览器中预览正常。点击改变 `window.location.hash`，而 hash provider 已
/// 在监听该变化——因此路由会导航而无需整页刷新。
///
/// Because the navigation flows through the hash URL, it always uses link /
/// push semantics (the browser owns the history entry). Use [ZeroLink] for
/// `replacement` / `popAndPush` semantics.
/// 由于导航经由 hash URL 流转，它始终使用链接 / push 语义（历史条目由浏览器
/// 掌管）。需要 `replacement` / `popAndPush` 语义请用 [ZeroLink]。
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

  /// The target location (rendered as `#location` in the href).
  /// 目标 location（在 href 中渲染为 `#location`）。
  final String location;

  /// The anchor text. / 锚点文字。
  final String label;

  /// Kept for API parity with [ZeroLink]; anchors always use link semantics.
  /// 为与 [ZeroLink] 保持 API 一致而保留；锚点始终使用链接语义。
  final ZeroLinkMode mode;

  /// Kept for API parity with [ZeroLink]; ignored by the DOM anchor.
  /// 为与 [ZeroLink] 保持 API 一致而保留；DOM 锚点忽略它。
  final int? tabIndex;

  /// Kept for API parity with [ZeroLink]; ignored by the DOM anchor.
  /// 为与 [ZeroLink] 保持 API 一致而保留；DOM 锚点忽略它。
  final Object? arguments;

  @override
  Widget build(BuildContext context) {
    final viewType = 'zero_anchor_${identityHashCode(this)}';
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final el = _createElement('a') as HTMLAnchorElement;
      el.href = ZeroRouter.canonicalHref(location);
      el.textContent = label;
      el.style = 'cursor: pointer; color: inherit; text-decoration: underline;';
      return el;
    });
    return HtmlElementView(viewType: viewType);
  }
}
