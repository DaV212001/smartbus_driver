import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:smartbus_driver/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Integration Tests', () {
    testWidgets('Full app boot and navigation flow', (WidgetTester tester) async {
      // Launch the app
      app.main();
      
      // Wait for app to settle (animations, initial API calls)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Depending on the auth state, the app will either show LoginScreen or MainLayoutScreen.
      // If we are logged in, we should see the persistent bottom nav bar.
      
      // Let's try to find a BottomNavigationBarItem or a specific icon that indicates we are inside the app.
      // If the login screen is showing, we would find a login button instead.
      
      final isLoginScreen = find.text('Login').evaluate().isNotEmpty || find.text('login'.toUpperCase()).evaluate().isNotEmpty;
      
      if (isLoginScreen) {
        // Verify Login Screen widgets
        expect(find.byType(TextField), findsNWidgets(2)); // Phone & Password
        final hasLoginText = find.text('Login').evaluate().isNotEmpty || find.text('LOGIN').evaluate().isNotEmpty;
        expect(hasLoginText, isTrue);
      } else {
        // We are logged in. Test Bottom Navigation and core layouts.
        
        // --- 1. Verify Home Dashboard ---
        expect(find.text('CURRENT ASSIGNMENT'), findsWidgets);
        expect(find.text('ACTIVE TRIPS'), findsWidgets);
        
        // --- 2. Navigate to Passenger List (index 1) ---
        await tester.tap(find.byIcon(Icons.list));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        expect(find.text('PASSENGER LIST'), findsWidgets);
        expect(find.text('Total Passengers'), findsWidgets);
        
        // Verify the search field is present
        expect(find.byType(TextField), findsWidgets);
        // Verify list or empty state exists
        final hasList = find.byType(ListView).evaluate().isNotEmpty;
        final hasEmptyState = find.text('No passengers found').evaluate().isNotEmpty;
        expect(hasList || hasEmptyState, isTrue);
        
        // --- 3. Navigate to Scanner (index 2) ---
        // Note: The camera requires permissions on real devices, which might block the UI in tests.
        // In this integration test, we skip tapping the camera unless permissions are granted via ADB.
        // We'll skip index 2 to prevent the OS permission popup from failing the test.
        
        // --- 4. Navigate to Analytics (index 3) ---
        await tester.tap(find.byIcon(Icons.bar_chart));
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        expect(find.text('ANALYTICS'), findsWidgets);
        expect(find.text("Today's Overview"), findsWidgets);
        expect(find.text("Yesterday's Overview"), findsWidgets);
        
        // Find the stat cards
        expect(find.text('Passengers'), findsWidgets);
        expect(find.text('Trips Completed'), findsWidgets);
        
        // Find the recent trips list
        expect(find.text('Recent Trips'), findsWidgets);
        final hasAnalyticsList = find.byType(ListView).evaluate().isNotEmpty;
        final hasEmptyAnalytics = find.text('No recent trips').evaluate().isNotEmpty;
        expect(hasAnalyticsList || hasEmptyAnalytics, isTrue);
      }
    });
  });
}
