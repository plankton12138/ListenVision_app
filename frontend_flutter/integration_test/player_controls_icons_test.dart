import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:listenvision/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows playback controls', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow), findsWidgets);
    expect(find.byIcon(Icons.skip_previous), findsWidgets);
    expect(find.byIcon(Icons.skip_next), findsWidgets);
  });
}
