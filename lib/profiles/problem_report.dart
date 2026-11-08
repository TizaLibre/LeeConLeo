import '../core/logging/item_event.dart';

abstract final class ProblemReport {
  static const subject = 'Lee con Leo: problema';

  static Uri mailto({
    required String email,
    required String version,
    required String platform,
    ItemEvent? lastAnswer,
  }) {
    final body = [
      'Cuéntanos qué pasó:',
      '',
      '',
      '',
      '---',
      'Versión: $version',
      'Dispositivo: $platform',
      if (lastAnswer != null) 'Último juego: ${lastAnswer.stepId} / ${lastAnswer.activityId}',
    ].join('\n');
    return Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
  }
}
