import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  const parser = ZeroRouteInformationParser();

  test('parses a path location', () async {
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/products/42')),
    );
    expect(result, '/products/42');
  });

  test('keeps query parameters', () async {
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/products/42?tab=specs')),
    );
    expect(result, '/products/42?tab=specs');
  });

  test('reads the hash strategy fragment', () async {
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/#/products/42')),
    );
    expect(result, '/products/42');
  });

  test('empty path becomes /', () async {
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('')),
    );
    expect(result, '/');
  });

  test('restores a location into route information', () {
    final info = parser.restoreRouteInformation('/products/42?tab=specs');
    expect(info, isNotNull);
    expect(info!.uri.toString(), '/products/42?tab=specs');
  });
}
