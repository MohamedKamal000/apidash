import 'package:apidash/validation/abstract_rule.dart';

bool validateRuleSet<Model>(List<Rule<Model>> rules, Model model) {
  for (var rule in rules) {
    if (!rule.validate(model)) {
      rule.onRuleBroken!();
      return false;
    }
  }
  return true;
}
