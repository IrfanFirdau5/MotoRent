import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motorent/main.dart';

void main() {
  testWidgets('MotoRent app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MotoRentApp());

    // Verify that the app loads with the vehicle listing page
    expect(find.text('Browse Vehicles'), findsOneWidget);
    
    // Verify that the filter icon is present
    expect(find.byIcon(Icons.filter_list), findsOneWidget);
  });

  testWidgets('Vehicle listing page displays correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MotoRentApp());
    
    // Wait for the loading to complete
    await tester.pumpAndSettle();
    
    // Verify that vehicles are displayed (mock data should load)
    // The mock data contains vehicle cards
    expect(find.byType(Card), findsWidgets);
  });

  testWidgets('Filter button opens filter dialog', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MotoRentApp());
    
    // Wait for initial load
    await tester.pumpAndSettle();
    
    // Tap the filter button
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();
    
    // Verify filter dialog appears
    expect(find.text('Filter Vehicles'), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text('Price Range (per day)'), findsOneWidget);
    expect(find.text('Availability'), findsOneWidget);
  });
}