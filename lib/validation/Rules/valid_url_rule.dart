
import 'dart:ui';

import 'package:apidash_core/apidash_core.dart';
import '../abstract_rule.dart';

class ValidURLRule extends Rule<HttpRequestModel>{

  ValidURLRule(VoidCallback onRuleBroken) {
    this.onRuleBroken = onRuleBroken;
  }

  @override
  bool validate(HttpRequestModel model) {
    return model.url.trim().isNotEmpty;
  }

}