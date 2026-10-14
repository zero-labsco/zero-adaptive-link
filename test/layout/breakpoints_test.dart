import 'package:flutter_test/flutter_test.dart';
import 'package:zero_adaptive_link/zero_adaptive_link.dart';

void main() {
  group('Breakpoints', () {
    const breakpoints = Breakpoints();

    test('below 600 is compact', () {
      expect(breakpoints.classify(0), BreakpointClass.compact);
      expect(breakpoints.classify(399), BreakpointClass.compact);
      expect(breakpoints.classify(599.9), BreakpointClass.compact);
    });

    test('600 – 839 is medium', () {
      expect(breakpoints.classify(600), BreakpointClass.medium);
      expect(breakpoints.classify(720), BreakpointClass.medium);
      expect(breakpoints.classify(839.9), BreakpointClass.medium);
    });

    test('840 and above is expanded', () {
      expect(breakpoints.classify(840), BreakpointClass.expanded);
      expect(breakpoints.classify(1000), BreakpointClass.expanded);
      expect(breakpoints.classify(3840), BreakpointClass.expanded);
    });

    test('custom thresholds are honored', () {
      const custom = Breakpoints(compactMaxWidth: 500, expandedMinWidth: 900);
      expect(custom.classify(499), BreakpointClass.compact);
      expect(custom.classify(500), BreakpointClass.medium);
      expect(custom.classify(899), BreakpointClass.medium);
      expect(custom.classify(900), BreakpointClass.expanded);
    });
  });
}
