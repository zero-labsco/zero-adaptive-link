/// Exposes the platform-appropriate [RouteInformationProvider] factory.
/// 导出平台适配的 [RouteInformationProvider] 工厂。
///
/// Web uses the hash URL strategy (`/#/products/42`) so GitHub Pages needs no
/// 404 fallback; native platforms use the platform provider.
/// Web 使用 hash URL 策略（`/#/products/42`），GitHub Pages 无需 404 fallback；
/// 原生平台使用平台 provider。
library;

export 'route_information_provider_web.dart'
    if (dart.library.io) 'route_information_provider_native.dart';
