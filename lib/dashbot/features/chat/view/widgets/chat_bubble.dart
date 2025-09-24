import 'package:apidash/dashbot/core/utils/safe_parse_json_message.dart';
import 'package:apidash_design_system/apidash_design_system.dart';
import '../../../../core/utils/dashbot_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_models.dart';
import '../../../../core/common/widgets/dashbot_action.dart';

class ChatBubble extends ConsumerWidget {
  final String message;
  final MessageRole role;
  final String? promptOverride;
  final List<ChatAction>? actions;

  const ChatBubble({
    super.key,
    required this.message,
    required this.role,
    this.promptOverride,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview =
        message.length > 100 ? '${message.substring(0, 100)}...' : message;
    debugPrint(
        '[ChatBubble] Actions count: ${actions?.length ?? 0} | msg: $preview');
    if (promptOverride != null &&
        role == MessageRole.user &&
        message == promptOverride) {
      return SizedBox.shrink();
    }
    if (message.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          children: [
            kVSpacer8,
            DashbotIcons.getDashbotIcon1(width: 42),
            kVSpacer8,
            CircularProgressIndicator.adaptive(),
          ],
        ),
      );
    }
    // Parse agent JSON when role is system and show only the "explnation" field.
    String renderedMessage = message;
    if (role == MessageRole.system) {
      try {
        final Map<String, dynamic> parsed = MessageJson.safeParse(message);
        if (parsed.containsKey('explnation')) {
          final exp = parsed['explnation'];
          if (exp is String && exp.isNotEmpty) {
            renderedMessage = exp;
          }
        }
      } catch (_) {
        // Fallback to raw message
      }
    }

    final effectiveActions = actions ?? const [];

    return Align(
      alignment: role == MessageRole.user
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (role == MessageRole.system) ...[
            kVSpacer6,
            DashbotIcons.getDashbotIcon1(width: 42),
            kVSpacer8,
          ],
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            padding: const EdgeInsets.all(12.0),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: MarkdownBody(
              data: renderedMessage.isEmpty ? " " : renderedMessage,
              selectable: true,
              styleSheet: MarkdownStyleSheet.fromTheme(
                Theme.of(context),
              ).copyWith(
                p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: role == MessageRole.user
                          ? Theme.of(context).colorScheme.surfaceBright
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          ),
          if (role == MessageRole.system) ...[
            if (effectiveActions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in effectiveActions)
                    Builder(
                      builder: (context) {
                        final w = DashbotActionWidgetFactory.build(a);
                        if (w != null) return w;
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            ADIconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: renderedMessage));
              },
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              icon: Icons.copy_rounded,
              tooltip: "Copy",
            ),
          ],
        ],
      ),
    );
  }
}
