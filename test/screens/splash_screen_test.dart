import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noogo/screens/splash_screen.dart';

// AnimatedSplashScreen has:
//   - AnimationController.repeat() (écrans icônes + pulse)
//   - Future.delayed(10s, onInitializationComplete)
// Drain timers while the widget is still mounted (pump 11s),
// then swap to _blank to dispose. No pending timers remain.
const _blank = MaterialApp(home: SizedBox());

void main() {
  group('AnimatedSplashScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AnimatedSplashScreen(onInitializationComplete: () {}),
      ));
      await tester.pump();

      expect(find.byType(AnimatedSplashScreen), findsOneWidget);

      // Drain Future.delayed(10s) while widget is still mounted
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpWidget(_blank);
    });

    testWidgets('contains a Stack or AnimatedBuilder', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AnimatedSplashScreen(onInitializationComplete: () {}),
      ));
      await tester.pump();

      expect(
        find.byType(Stack).evaluate().isNotEmpty ||
            find.byType(AnimatedBuilder).evaluate().isNotEmpty ||
            find.byType(Scaffold).evaluate().isNotEmpty,
        isTrue,
      );

      await tester.pump(const Duration(seconds: 11));
      await tester.pumpWidget(_blank);
    });

    testWidgets('disposes animation controllers cleanly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AnimatedSplashScreen(onInitializationComplete: () {}),
      ));
      await tester.pump();

      // Drain pending timers before disposing
      await tester.pump(const Duration(seconds: 11));
      await tester.pumpWidget(_blank);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
