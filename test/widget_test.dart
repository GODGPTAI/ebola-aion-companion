import 'package:ebola_aion_companion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Shows all four EBOLA glass models', (tester) async {
    await tester.pumpWidget(const EbolaApp());
    expect(find.text('EBOLA AION'), findsOneWidget);
    expect(find.text('EBOLA G1 Everyday'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('EBOLA G4 Sport Pro'), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('EBOLA G4 Sport Pro'), findsOneWidget);
  });
}
