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

  test('keeps the query that lives inside the hash fragment', () async {
    // Hash strategy: the app's query is part of the fragment, so it must
    // survive parsing (`/#/products/42?tab=specs`).
    // hash 策略：应用自身的 query 是 fragment 的一部分，必须能被解析出来
    // （`/#/products/42?tab=specs`）。
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/#/products/42?tab=specs')),
    );
    expect(result, '/products/42?tab=specs');
  });

  test('ignores the host page query when a hash fragment is present', () async {
    // The query outside the hash belongs to the host page; merging it would
    // inject unrelated parameters into the location.
    // hash 之外的 query 属于宿主页面；合并它会向 location 注入无关参数。
    final result = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/?utm_source=twitter#/products/42')),
    );
    expect(result, '/products/42');
  });
}
