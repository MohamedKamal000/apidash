
import 'dart:ui';

abstract class Rule<Model>{
  bool validate(Model m);
  VoidCallback? onRuleBroken;
}