import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('public API surface', () {
    test('barrel exports the documented entry points', () {
      // Smoke-check that every contract-level symbol is reachable through the
      // barrel (consumers must not import lib/src/).
      // 验证所有合同级符号都能经 barrel 访问（消费者不得 import lib/src/）。
      expect(ZeroLink, isNotNull);
      expect(ZeroNav, isNotNull);
      expect(ZeroRouter, isNotNull);
      expect(ZeroRoute, isNotNull);
      expect(ZeroShell, isNotNull);
      expect(ZeroTab, isNotNull);
      expect(ZeroShellChrome, isNotNull);
      expect(ZeroShellScope, isNotNull);
      expect(ZeroShellState, isNotNull);
      expect(ZeroPaneScope, isNotNull);
      expect(ZeroRouteState, isNotNull);
      expect(ZeroRouteMatch, isNotNull);
      expect(MatchList, isNotNull);
      expect(ZeroRouteMatcher, isNotNull);
      expect(ZeroRouteInformationParser, isNotNull);
      expect(ZeroRouterDelegate, isNotNull);
      expect(Breakpoints, isNotNull);
      expect(BreakpointClass, isNotNull);
      expect(SlidingPanes, isNotNull);
      expect(SlidingPane, isNotNull);
      expect(SlidingPaneBuilder, isNotNull);
      expect(SlidingResizeHandleBuilder, isNotNull);
      expect(Breadcrumbs, isNotNull);
      expect(ZeroRouteBuilder, isNotNull);
      expect(ZeroTitleBuilder, isNotNull);
      expect(ZeroRouteRedirect, isNotNull);
      expect(ZeroRouterRedirect, isNotNull);
      expect(ZeroExitHook, isNotNull);
      expect(ZeroShellBuilder, isNotNull);
      expect(ZeroBreadcrumbsBuilder, isNotNull);
      expect(ZeroErrorBuilder, isNotNull);
    });

    test('Breakpoints default thresholds are 600 / 840', () {
      const breakpoints = Breakpoints();
      expect(breakpoints.compactMaxWidth, 600);
      expect(breakpoints.expandedMinWidth, 840);
    });
  });
}
