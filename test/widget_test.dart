// Smoke test for XplooriaApp — verifies the app starts without crashing.
// Firebase-dependent providers cannot be exercised in unit tests without mocks,
// so we only assert that the material app mounts a scaffold (via the router).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xplooria/main.dart';

void main() {
  testWidgets('XplooriaApp mounts inside ProviderScope without throwing',
      (WidgetTester tester) async {
    // XplooriaApp requires a ProviderScope ancestor.
    await tester.pumpWidget(
      const ProviderScope(child: XplooriaApp()),
    );

    // If the widget tree builds without errors the test passes.
    // A MaterialApp should be present somewhere in the tree.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
