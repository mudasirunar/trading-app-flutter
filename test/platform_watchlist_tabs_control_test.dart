import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trading_app/core/widgets/platform_watchlist_tabs_control.dart';

void main() {
  group('PlatformWatchlistTabsControl Tests', () {
    testWidgets('Renders Android Liquid Glass tabs by default', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => PlatformWatchlistTabsControl(
                selectedIndex: selected,
                onTabSelected: (index) {
                  setState(() => selected = index);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlatformWatchlistTabsControl), findsOneWidget);
      expect(find.text('My Watchlists'), findsOneWidget);
      expect(find.text('All Markets'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.language_rounded), findsOneWidget);

      // Tap on 'All Markets'
      await tester.tap(find.text('All Markets'));
      await tester.pumpAndSettle();

      expect(selected, 1);

      // Tap back on 'My Watchlists'
      await tester.tap(find.text('My Watchlists'));
      await tester.pumpAndSettle();

      expect(selected, 0);
    });

    testWidgets('Drag physics updates selected tab', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, setState) => PlatformWatchlistTabsControl(
                    selectedIndex: selected,
                    onTabSelected: (index) {
                      setState(() => selected = index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag horizontally to right
      await tester.drag(find.byType(PlatformWatchlistTabsControl), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(selected, 1);
    });

    testWidgets('Drag into wall boundary triggers impulse and settles correctly', (tester) async {
      int selected = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: StatefulBuilder(
                  builder: (context, setState) => PlatformWatchlistTabsControl(
                    selectedIndex: selected,
                    onTabSelected: (index) {
                      setState(() => selected = index);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag aggressively to left wall
      final gesture = await tester.startGesture(tester.getCenter(find.byType(PlatformWatchlistTabsControl)));
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump(const Duration(milliseconds: 100));
      // Hold finger at wall
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selected, 0);
    });

    testWidgets('Mounts UiKitView on iOS platform without assertion error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: PlatformWatchlistTabsControl(
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PlatformWatchlistTabsControl), findsOneWidget);
      expect(find.byType(UiKitView), findsOneWidget);
    });
  });
}
