import 'dart:ui';

import 'package:apidash/dashbot/core/common/widgets/dashbot_action_buttons/dashbot_import_now_button.dart';
import 'package:apidash/dashbot/core/constants/constants.dart';
import 'package:apidash/dashbot/core/providers/dashbot_window_notifier.dart';
import 'package:apidash/dashbot/features/chat/models/chat_action.dart';
import 'package:apidash/dashbot/features/chat/viewmodel/chat_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test_consts.dart';
import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const specJson = '''
{
  "openapi": "3.0.0",
  "info": {"title": "Sample API", "version": "1.0.0"},
  "servers": [{"url": "https://api.apidash.dev"}],
  "paths": {
    "/users": {
      "get": {
        "responses": {"200": {"description": "OK"}}
      }
    }
  }
}
''';

  group('DashbotImportNowButton', () {
    testWidgets('hides dashbot window, shows picker, applies selected ops',
        (tester) async {
      const action = ChatAction(
        action: 'import_now_openapi',
        target: 'httpRequestModel',
        value: {'sourceName': 'Sample', 'content': specJson},
        actionType: ChatActionType.other,
        targetType: ChatActionTarget.httpRequestModel,
      );

      late TestChatViewmodel notifier;
      late RecordingDashbotWindowNotifier windowNotifier;
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(1600, 1200);
      binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        binding.window.clearPhysicalSizeTestValue();
        binding.window.clearDevicePixelRatioTestValue();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatViewmodelProvider.overrideWith((ref) {
              notifier = TestChatViewmodel(ref);
              return notifier;
            }),
            dashbotWindowNotifierProvider.overrideWith((ref) {
              windowNotifier = RecordingDashbotWindowNotifier();
              return windowNotifier;
            }),
          ],
          child: MaterialApp(
            theme: kThemeDataLight,
            home: Scaffold(
              body: DashbotImportNowButton(action: action),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Import Now'));
      await tester.pumpAndSettle();

      // Dialog should be shown; tap Import to accept default selection
      final importFinder = find.text('Import');
      expect(importFinder, findsOneWidget);
      await tester.tap(importFinder);
      await tester.pumpAndSettle();

      expect(windowNotifier.hideCalls, greaterThanOrEqualTo(1));
      expect(windowNotifier.showCalls, greaterThanOrEqualTo(1));

      expect(notifier.applyAutoFixCalls, isNotEmpty);
      final applied = notifier.applyAutoFixCalls.single;
      expect(applied.action, 'apply_openapi');
      expect(applied.field, 'apply_to_new');
      expect(applied.value, isA<Map<String, dynamic>>());
      final value = applied.value as Map<String, dynamic>;
      expect(value['url'], 'https://api.apidash.dev/users');
      expect(value['method'], 'GET');
    });
  });
}
