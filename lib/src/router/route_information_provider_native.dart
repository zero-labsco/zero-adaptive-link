import 'package:flutter/widgets.dart';

/// Create the platform route information provider (native platforms).
/// 创建平台 route information provider（原生平台）。
RouteInformationProvider createZeroRouteInformationProvider(
  String initialLocation,
) {
  return PlatformRouteInformationProvider(
    initialRouteInformation: RouteInformation(
      uri: Uri.parse(initialLocation.isEmpty ? '/' : initialLocation),
    ),
  );
}
