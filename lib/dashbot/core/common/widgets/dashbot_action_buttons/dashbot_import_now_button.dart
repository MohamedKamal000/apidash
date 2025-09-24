import 'package:flutter/material.dart';
import 'package:openapi_spec/openapi_spec.dart';

import '../../../../features/chat/models/chat_models.dart';
import '../../../../features/chat/view/widgets/openapi_operation_picker_dialog.dart';
import '../../../../features/chat/viewmodel/chat_viewmodel.dart';
import '../../../providers/dashbot_window_notifier.dart';
import '../../../services/openapi_import_service.dart';
import '../dashbot_action.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashbotImportNowButton extends ConsumerWidget with DashbotActionMixin {
  @override
  final ChatAction action;
  const DashbotImportNowButton({super.key, required this.action});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      icon: const Icon(Icons.playlist_add_check, size: 16),
      label: const Text('Import Now'),
      onPressed: () async {
        try {
          OpenApi? spec;
          String? sourceName;
          final overlayNotifier =
              ref.read(dashbotWindowNotifierProvider.notifier);
          final chatNotifier = ref.read(chatViewmodelProvider.notifier);
          if (action.value is Map<String, dynamic>) {
            final map = action.value as Map<String, dynamic>;
            sourceName = map['sourceName'] as String?;
            if (map['spec'] is OpenApi) {
              spec = map['spec'] as OpenApi;
            } else if (map['content'] is String) {
              spec =
                  OpenApiImportService.tryParseSpec(map['content'] as String);
            }
          }
          if (spec == null) return;

          final servers = spec.servers ?? const [];
          final baseUrl = servers.isNotEmpty ? (servers.first.url ?? '/') : '/';
          overlayNotifier.hide();
          final selected = await showOpenApiOperationPickerDialog(
            context: context,
            spec: spec,
            sourceName: sourceName,
          );
          overlayNotifier.show();
          if (selected == null || selected.isEmpty) return;
          for (final s in selected) {
            final payload = OpenApiImportService.payloadForOperation(
              baseUrl: baseUrl,
              path: s.path,
              method: s.method,
              op: s.op,
            );
            await chatNotifier.applyAutoFix(ChatAction.fromJson({
              'action': 'apply_openapi',
              'actionType': 'apply_openapi',
              'target': 'httpRequestModel',
              'targetType': 'httpRequestModel',
              'field': 'apply_to_new',
              'value': payload,
            }));
          }
        } catch (_) {}
      },
    );
  }
}
