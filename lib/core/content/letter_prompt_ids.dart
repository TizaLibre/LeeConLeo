import 'activity_ids.dart';
import 'models/letter_shape.dart';

abstract final class LetterPromptIds {
  static String meet(String grapheme) => '${ActivityIds.meet}.$grapheme';

  static String meetCase(String grapheme, LetterCase letterCase) =>
      '${meet(grapheme)}.${letterCase.name}';

  static String meetShow(String grapheme, LetterCase letterCase) =>
      '${meetCase(grapheme, letterCase)}.show';

  static String trace(String grapheme, LetterCase letterCase) =>
      '${ActivityIds.trace}.$grapheme.${letterCase.name}';

  static String find(String grapheme) => '${ActivityIds.find}.$grapheme';

  static List<String> requiredFor(String activityId, String grapheme) => switch (activityId) {
    ActivityIds.meet => [
      meet(grapheme),
      for (final c in LetterCase.values) ...[meetCase(grapheme, c), meetShow(grapheme, c)],
    ],
    ActivityIds.trace => [for (final c in LetterCase.values) trace(grapheme, c)],
    ActivityIds.find => [find(grapheme)],
    _ => const [],
  };
}
