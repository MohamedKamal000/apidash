import 'dart:ui';

import 'package:apidash_core/apidash_core.dart';

import '../abstract_rule.dart';

class ValidJsonRule extends Rule<HttpRequestModel> {
  ValidJsonRule(VoidCallback onRuleBroken) {
    this.onRuleBroken = onRuleBroken;
  }

  @override
  bool validate(HttpRequestModel model) {

    if (model.method == HTTPVerb.get){
      return true; // don't need to check for GET requests
    }

    bool firstCheck =
        model.body != null &&
        model.body!.trim().isNotEmpty &&
        model.bodyContentType == ContentType.json;
    if (firstCheck) {
      try {
        kJsonDecoder.convert(model.body!);
        return true;
      } catch (e) {
        return false;
      }
    }

    return false;
  }
}
