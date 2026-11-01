import 'dart:convert';
import 'dart:io';

import '../content_paths.dart';
import '../voice/recording_list.dart';
import '../yaml_content_reader.dart';
import 'content_command.dart';

class VoiceCommand implements ContentCommand {
  const VoiceCommand({this.reader = const YamlContentReader()});

  static const redoFlag = '--redo=';

  final YamlContentReader reader;

  @override
  String get name => 'voice';

  @override
  String get usage =>
      'voice [--redo=a,b]    list missing recordings in ${ContentPaths.toRecord} for the voice notebook';

  @override
  int run(List<String> arguments) {
    final redo = {
      for (final argument in arguments)
        if (argument.startsWith(redoFlag)) ...argument.substring(redoFlag.length).split(','),
    };
    final list = RecordingList.missing(
      reader.read(),
      hasAudio: (path) => File('${ContentPaths.audio}/$path').existsSync(),
      recordedTexts: _recordedTexts(),
      redo: redo,
    );
    File(ContentPaths.toRecord)
      ..createSync(recursive: true)
      ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(list.toJson())}\n');
    print(
      list.isEmpty
          ? 'Nothing to record'
          : 'Wrote ${ContentPaths.toRecord}: ${list.phrases.length} phrases, '
                '${list.words.length} words, ${list.sounds.length} sounds to record',
    );
    return 0;
  }

  static Map<String, String> _recordedTexts() {
    final manifest = File(ContentPaths.manifest);
    if (!manifest.existsSync()) return const {};
    final clips =
        (jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>)['clips'] as List;
    return {
      for (final clip in clips.cast<Map<String, dynamic>>())
        '${clip['promptId']}.${clip['index']}': clip['text'] as String,
    };
  }
}
