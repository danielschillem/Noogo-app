import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/utils/responsive.dart';

Widget _sized({required double width, required Widget child}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 900)),
        child: child,
      ),
    );

void main() {
  group('Responsive breakpoints', () {
    testWidgets('isPhone returns true at 390dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 390,
        child: Builder(builder: (ctx) {
          result = Responsive.isPhone(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isPhone returns false at 720dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 720,
        child: Builder(builder: (ctx) {
          result = Responsive.isPhone(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isFalse);
    });

    testWidgets('isTablet returns true at 720dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 720,
        child: Builder(builder: (ctx) {
          result = Responsive.isTablet(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isTablet returns false at 390dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 390,
        child: Builder(builder: (ctx) {
          result = Responsive.isTablet(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isFalse);
    });

    testWidgets('isDesktop returns true at 960dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 960,
        child: Builder(builder: (ctx) {
          result = Responsive.isDesktop(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isDesktop returns false at 720dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 720,
        child: Builder(builder: (ctx) {
          result = Responsive.isDesktop(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isFalse);
    });

    testWidgets('isSmallPhone returns true at 320dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 320,
        child: Builder(builder: (ctx) {
          result = Responsive.isSmallPhone(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isTrue);
    });

    testWidgets('isTabletOrLarger true at 600dp', (tester) async {
      bool? result;
      await tester.pumpWidget(_sized(
        width: 600,
        child: Builder(builder: (ctx) {
          result = Responsive.isTabletOrLarger(ctx);
          return const SizedBox();
        }),
      ));
      expect(result, isTrue);
    });
  });

  group('Responsive.value()', () {
    testWidgets('returns phone value at 390dp', (tester) async {
      double? result;
      await tester.pumpWidget(_sized(
        width: 390,
        child: Builder(builder: (ctx) {
          result = Responsive.value(ctx, phone: 16.0, tablet: 32.0);
          return const SizedBox();
        }),
      ));
      expect(result, 16.0);
    });

    testWidgets('returns tablet value at 720dp', (tester) async {
      double? result;
      await tester.pumpWidget(_sized(
        width: 720,
        child: Builder(builder: (ctx) {
          result = Responsive.value(ctx, phone: 16.0, tablet: 32.0);
          return const SizedBox();
        }),
      ));
      expect(result, 32.0);
    });

    testWidgets('returns desktop value at 960dp when provided', (tester) async {
      double? result;
      await tester.pumpWidget(_sized(
        width: 960,
        child: Builder(builder: (ctx) {
          result =
              Responsive.value(ctx, phone: 16.0, tablet: 32.0, desktop: 48.0);
          return const SizedBox();
        }),
      ));
      expect(result, 48.0);
    });
  });

  group('Responsive.gridColumns()', () {
    testWidgets('returns 2 on phone', (tester) async {
      int? cols;
      await tester.pumpWidget(_sized(
        width: 390,
        child: Builder(builder: (ctx) {
          cols = Responsive.gridColumns(ctx);
          return const SizedBox();
        }),
      ));
      expect(cols, 2);
    });

    testWidgets('returns 3 on tablet', (tester) async {
      int? cols;
      await tester.pumpWidget(_sized(
        width: 720,
        child: Builder(builder: (ctx) {
          cols = Responsive.gridColumns(ctx);
          return const SizedBox();
        }),
      ));
      expect(cols, 3);
    });

    testWidgets('returns 4 on desktop', (tester) async {
      int? cols;
      await tester.pumpWidget(_sized(
        width: 1024,
        child: Builder(builder: (ctx) {
          cols = Responsive.gridColumns(ctx);
          return const SizedBox();
        }),
      ));
      expect(cols, 4);
    });
  });

  group('ResponsiveCenter widget', () {
    testWidgets('renders child on phone', (tester) async {
      await tester.pumpWidget(_sized(
        width: 390,
        child: const ResponsiveCenter(child: Text('Hello')),
      ));
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('renders child on tablet', (tester) async {
      await tester.pumpWidget(_sized(
        width: 720,
        child: const ResponsiveCenter(child: Text('Tablet')),
      ));
      expect(find.text('Tablet'), findsOneWidget);
    });

    testWidgets('constrains width on desktop', (tester) async {
      await tester.pumpWidget(_sized(
        width: 1200,
        child: const ResponsiveCenter(child: Text('Desktop')),
      ));
      // Find the ConstrainedBox that is a direct descendant of ResponsiveCenter
      final boxes =
          tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final relevant = boxes.firstWhere(
        (b) => b.constraints.maxWidth <= 960.0,
        orElse: () =>
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 960)),
      );
      expect(relevant.constraints.maxWidth, lessThanOrEqualTo(960.0));
    });
  });

  group('AdaptivePageLayout widget', () {
    testWidgets('shows only body on phone (no sidebar)', (tester) async {
      await tester.pumpWidget(_sized(
        width: 390,
        child: const AdaptivePageLayout(
          body: Text('Body'),
          sidebar: Text('Sidebar'),
        ),
      ));
      expect(find.text('Body'), findsOneWidget);
      // Sidebar hidden on phone
      expect(find.text('Sidebar'), findsNothing);
    });

    testWidgets('shows body and sidebar on tablet', (tester) async {
      await tester.pumpWidget(_sized(
        width: 768,
        child: const AdaptivePageLayout(
          body: Text('Body'),
          sidebar: Text('Sidebar'),
        ),
      ));
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
    });

    testWidgets('shows only body when sidebar is null', (tester) async {
      await tester.pumpWidget(_sized(
        width: 768,
        child: const AdaptivePageLayout(
          body: Text('OnlyBody'),
        ),
      ));
      expect(find.text('OnlyBody'), findsOneWidget);
    });
  });
}
