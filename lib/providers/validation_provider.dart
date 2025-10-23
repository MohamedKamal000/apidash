import 'package:apidash/providers/terminal_providers.dart';
import 'package:apidash/terminal/enums.dart';
import 'package:apidash/validation/Rules/get_no_body_rule.dart';
import 'package:apidash/validation/Rules/valid_json_rule.dart';
import 'package:apidash/validation/Rules/valid_url_rule.dart';
import 'package:apidash/validation/abstract_rule.dart';
import 'package:apidash/validation/enums.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final validationProvider =
    StateProvider<Map<ValidationRuleType, List<Rule>>>((ref) {
  return {
    ValidationRuleType.sendRequestValidationRules: [
      ValidJsonRule((){
        final terminal = ref.read(terminalStateProvider.notifier);
        terminal.logSystem(
          category: 'validation',
          message: 'Invalid JSON in request body',
          level: TerminalLevel.error,
          tags: ['request-validation', 'invalid-json'],
        );
      }),
      ValidURLRule((){
        final terminal = ref.read(terminalStateProvider.notifier);
        terminal.logSystem(
          category: 'validation',
          message: 'Request URL is empty. Please provide a valid URL.',
          level: TerminalLevel.error,
          tags: ['request-validation', 'empty-url'],
        );
      }),
      GetWithNoBodyRule(() {
        final terminal = ref.read(terminalStateProvider.notifier);
        terminal.logSystem(
          category: 'validation',
          message:
              'GET request contains a body. This may not be supported by all servers.',
          level: TerminalLevel.warn,
          tags: ['request-validation', 'get-with-body'],
        );
      }),
    ],
  };
});
