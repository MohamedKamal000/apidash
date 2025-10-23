import 'dart:ui';

import 'package:apidash/validation/abstract_rule.dart';
import 'package:apidash_core/apidash_core.dart';

class GetWithNoBodyRule extends Rule<HttpRequestModel> {

  GetWithNoBodyRule(VoidCallback onRuleBroken){
    this.onRuleBroken = onRuleBroken;
  }

  @override
  bool validate(HttpRequestModel model) {
    return model.method == HTTPVerb.get && model.body == null ||
        model.body!.trim().isEmpty;
  }

}
