import 'dart:convert';
import 'dart:io';

import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/letter_shape.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';
import 'package:lee_con_leo/utils/spanish/sound_key_encoder.dart';
import 'package:lee_con_leo/utils/spanish/syllabifier.dart';
import 'package:yaml/yaml.dart';

import 'content_paths.dart';
import 'utils/yaml_to_dart.dart';

class YamlContentReader {
  const YamlContentReader({
    this.syllabifier = const Syllabifier(),
    this.soundKeyEncoder = const SoundKeyEncoder(),
  });

  final Syllabifier syllabifier;
  final SoundKeyEncoder soundKeyEncoder;

  ContentBundle read() => ContentBundle(
    words: [for (final entry in _readList(ContentPaths.words)) _toWord(entry)],
    stages: [for (final entry in _readList(ContentPaths.path)) PathStage.fromJson(entry)],
    prompts: PromptLibrary.fromJson(
      _readMap(ContentPaths.prompts),
      clips: _promptClips(),
      beats: _promptBeats(),
    ),
    letters: {
      for (final file in _yamlFiles(ContentPaths.letters))
        _baseName(file): LetterShape.fromJson(_load(file.path) as Map<String, dynamic>),
    },
    syllables: {
      for (final file in _yamlFiles(ContentPaths.syllables))
        _baseName(file): LetterShape.parseStrokes(
          (_load(file.path) as Map<String, dynamic>)['strokes'],
        ),
    },
  );

  List<File> _yamlFiles(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return const [];
    return [
      for (final file in dir.listSync().whereType<File>())
        if (file.path.endsWith(_yamlExtension)) file,
    ]..sort((a, b) => a.path.compareTo(b.path));
  }

  static const _yamlExtension = '.yaml';

  String _baseName(File file) {
    final name = file.uri.pathSegments.last;
    return name.substring(0, name.length - _yamlExtension.length);
  }

  Map<String, List<double>> _promptBeats() {
    final manifest = File(ContentPaths.manifest);
    if (!manifest.existsSync()) return const {};
    final clips =
        (jsonDecode(manifest.readAsStringSync()) as Map<String, dynamic>)['clips'] as List;
    return {
      for (final clip in clips.cast<Map<String, dynamic>>())
        if (clip['beats'] case final List beats)
          PromptLibrary.clipKey(clip['promptId'] as String, clip['index'] as int): [
            for (final beat in beats) (beat as num).toDouble(),
          ],
    };
  }

  Map<String, String> _promptClips() {
    final dir = Directory('${ContentPaths.audio}/${ContentPaths.promptClipsDir}');
    if (!dir.existsSync()) return const {};
    final names = [
      for (final file in dir.listSync().whereType<File>())
        if (file.path.endsWith(ContentPaths.clipExtension)) file.uri.pathSegments.last,
    ]..sort();
    return {
      for (final name in names)
        name.substring(0, name.length - ContentPaths.clipExtension.length):
            '${ContentPaths.promptClipsDir}/$name',
    };
  }

  Word _toWord(Map<String, dynamic> entry) {
    final text = entry['text'] as String;
    final syllables = (entry['syllables'] as List?)?.cast<String>() ?? syllabifier.split(text);
    final sounds =
        (entry['sounds'] as List?)?.cast<String>() ?? soundKeyEncoder.encodeAll(syllables);
    return Word.fromJson({...entry, 'syllables': syllables, 'sounds': sounds});
  }

  List<Map<String, dynamic>> _readList(String path) =>
      (_load(path) as List? ?? const []).cast<Map<String, dynamic>>();

  Map<String, dynamic> _readMap(String path) => (_load(path) as Map<String, dynamic>?) ?? {};

  Object? _load(String path) => yamlToDart(loadYaml(File(path).readAsStringSync()));
}
