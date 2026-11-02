import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/picture_sound_game.dart';
import 'package:lee_con_leo/core/content/sound_position.dart';

import '../validation_issue.dart';
import '../validation_rule.dart';

class PictureSoundStepsRule implements ValidationRule {
  const PictureSoundStepsRule({this.distractors = 3});

  final int distractors;

  @override
  Iterable<ValidationIssue> check(ContentBundle bundle) sync* {
    final pictured = SoundPosition.pictured(bundle.words);
    final used = PictureSoundGame.values.where(
      (game) => bundle.steps.any((step) => step.activities.contains(game.activityId)),
    );
    if (used.isEmpty) return;
    for (final word in pictured.where((word) => word.audio == null)) {
      yield ValidationIssue.error('"${word.text}": a word with a picture needs audio');
    }
    for (final game in used) {
      for (final step in bundle.steps.where((step) => step.activities.contains(game.activityId))) {
        yield* _checkStep(bundle, step, game);
      }
    }
  }

  Iterable<ValidationIssue> _checkStep(
    ContentBundle bundle,
    PathStep step,
    PictureSoundGame game,
  ) sync* {
    final position = game.position;
    final pictured = SoundPosition.pictured(bundle.words);
    final label = position.label;
    if (step.sounds.isEmpty) {
      yield ValidationIssue.error('step "${step.id}": ${game.activityId} needs a sound');
      return;
    }
    final asked = <String>[];
    for (final sound in step.sounds) {
      if (!pictured.any((word) => game.matches(word, sound))) continue;
      asked.add(sound);
      final prompt = game.promptId(sound);
      if (!bundle.prompts.contains(prompt)) {
        yield ValidationIssue.error('step "${step.id}": missing prompt "$prompt"');
      }
      if (pictured.where((word) => !game.resembles(word, sound)).length < distractors) {
        yield ValidationIssue.error(
          'step "${step.id}": fewer than $distractors pictures that do not $label with "$sound"',
        );
      }
    }
    if (asked.isEmpty) {
      yield ValidationIssue.error(
        'step "${step.id}": no word with a picture $label with any of ${step.sounds.join(', ')}',
      );
    }
  }
}
