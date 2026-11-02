import 'package:lee_con_leo/core/content/activity_ids.dart';
import 'package:lee_con_leo/core/content/clap_words.dart';
import 'package:lee_con_leo/core/content/listening_prompt_ids.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';

import '../validation_issue.dart';
import '../validation_rule.dart';

class ClapStepsRule implements ValidationRule {
  const ClapStepsRule();

  @override
  Iterable<ValidationIssue> check(ContentBundle bundle) sync* {
    if (!bundle.steps.any((step) => step.activities.contains(ActivityIds.clap))) return;
    if (!bundle.prompts.contains(ListeningPromptIds.clapAsk)) {
      yield ValidationIssue.error('missing prompt "${ListeningPromptIds.clapAsk}"');
    }
    final words = ClapWords.all(bundle.words);
    if (words.isEmpty) yield ValidationIssue.error('no word with a picture and audio to clap');
    for (final word in words) {
      final prompt = ListeningPromptIds.clapSplit(word.text);
      if (!bundle.prompts.contains(prompt)) {
        yield ValidationIssue.error('"${word.text}": missing prompt "$prompt"');
        continue;
      }
      final key = PromptLibrary.clipKey(prompt, 0);
      final beats = bundle.prompts.beats[key] ?? const [];
      if (bundle.prompts.clips.containsKey(key) && beats.length != word.syllables.length) {
        yield ValidationIssue.error(
          '"$key": ${beats.length} claps timed for ${word.syllables.length} syllables '
          '(run "dart run tool/content.dart beats")',
        );
      }
    }
  }
}
