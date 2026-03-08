import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amitflow_flutter_gsoc2026/controllers/ssh_controller.dart';
import 'package:amitflow_flutter_gsoc2026/controllers/settings_controller.dart';
import 'package:amitflow_flutter_gsoc2026/controllers/lg_controller.dart';
import 'package:amitflow_flutter_gsoc2026/main.dart';

void main() {
  testWidgets('HomeScreen renders LG Controller title', (WidgetTester tester) async {
    final settingsController = SettingsController();
    final sshController = SSHController();
    final lgController = LGController(
      sshController: sshController,
      settingsController: settingsController,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MyApp(
          sshController: sshController,
          settingsController: settingsController,
          lgController: lgController,
        ),
      ),
    );

    expect(find.text('LG CONTROLLER'), findsOneWidget);
    expect(find.text('Liquid Galaxy Console'), findsOneWidget);
  });
}
