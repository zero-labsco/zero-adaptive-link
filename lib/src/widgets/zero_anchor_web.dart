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

const String _anchorStyle =
    'cursor: pointer; color: inherit; text-decoration: underline;';

/// A genuine DOM `<a href="#location">` rendered on the web, so links open in a
/// new tab and preview correctly in the browser. Clicking changes
/// `window.location.hash`, which the hash provider already observes — the router
/// therefore navigates without a full page reload.
/// 在 web 上渲染真正的 DOM `<a href="#location">`，使链接可在新标签打开、
/// 在浏览器中预览正常。点击改变 `window.location.hash`，而 hash provider 已
/// 在监听该变化——因此路由会导航而无需整页刷新。
///
/// The view factory is registered **once per mounted state** (not once per
/// build) and the element is updated in place through [HTMLAnchorElement].
/// `dart:ui_web` offers no unregister API, so re-registering on every build
/// would either assert on a duplicate `viewType` or leak factories forever.
/// view factory **每个挂载的 State 只注册一次**（而非每次 build），并通过
/// [HTMLAnchorElement] 原地更新元素。`dart:ui_web` 没有注销 API，每次 build
/// 重新注册要么因重复 `viewType` 断言，要么永久泄漏 factory。
///
/// A hash URL can only express link / push semantics. When `mode`, `tabIndex`
/// or `arguments` ask for something else, the widget falls back to [ZeroLink]
/// so web and native behave identically.
/// hash URL 只能表达链接 / push 语义。当 `mode`、`tabIndex` 或 `arguments`
/// 要求其它语义时，组件回退到 [ZeroLink]，使 web 与原生行为一致。
class ZeroAnchor extends StatefulWidget {
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

  /// How the link opens; only [ZeroLinkMode.push] can use a DOM anchor.
  /// 打开方式；只有 [ZeroLinkMode.push] 能使用 DOM 锚点。
  final ZeroLinkMode mode;

  /// Open [location] in this tab specifically; falls back to [ZeroLink].
  /// 在指定 tab 打开 [location]；此时回退到 [ZeroLink]。
  final int? tabIndex;

  /// Arguments forwarded to [ZeroLink] when the DOM anchor cannot express
  /// the request. / 当 DOM 锚点无法表达该请求时透传给 [ZeroLink] 的参数。
  final Object? arguments;

  @override
  State<ZeroAnchor> createState() => _ZeroAnchorState();
}

class _ZeroAnchorState extends State<ZeroAnchor> {
  late final String _viewType = 'zero_anchor_${identityHashCode(this)}';
  HTMLAnchorElement? _element;

  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final el = _createElement('a') as HTMLAnchorElement;
      el.href = ZeroRouter.canonicalHref(widget.location);
      el.textContent = widget.label;
      el.style = _anchorStyle;
      return _element = el;
    });
  }

  @override
  void didUpdateWidget(covariant ZeroAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final el = _element;
    if (el == null) {
      return;
    }
    if (oldWidget.location != widget.location) {
      el.href = ZeroRouter.canonicalHref(widget.location);
    }
    if (oldWidget.label != widget.label) {
      el.textContent = widget.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode != ZeroLinkMode.push ||
        widget.tabIndex != null ||
        widget.arguments != null) {
      return ZeroLink(
        location: widget.location,
        mode: widget.mode,
        tabIndex: widget.tabIndex,
        arguments: widget.arguments,
        child: Text(widget.label),
      );
    }
    return HtmlElementView(
      viewType: _viewType,
      key: ValueKey<String>(_viewType),
    );
  }
}
