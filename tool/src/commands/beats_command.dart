import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:lee_con_leo/core/content/clap_words.dart';
import 'package:lee_con_leo/core/content/listening_prompt_ids.dart';

import '../content_paths.dart';
import '../voice/beat_finder.dart';
import '../yaml_content_reader.dart';
import 'content_command.dart';

class BeatsCommand implements ContentCommand {
  const BeatsCommand({this.reader = const YamlContentReader()});

  static const redoFlag = '--redo';
  static const rate = 16000;

  final YamlContentReader reader;

  @override
  String get name => 'beats';

  @override
  String get usage =>
      'beats [--redo]        time each syllable of the clap clips into ${ContentPaths.manifest} (needs ffmpeg)';

  @override
  int run(List<String> arguments) {
    final redo = arguments.contains(redoFlag);
    final syllables = {
      for (final word in ClapWords.all(reader.read().words))
        ListeningPromptIds.clapSplit(word.text): word.syllables.length,
    };
    final file = File(ContentPaths.manifest);
    final manifest = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    var timed = 0;
    var failed = 0;
    for (final clip in (manifest['clips'] as List).cast<Map<String, dynamic>>()) {
      final count = syllables[clip['promptId']];
      if (count == null || (clip.containsKey('beats') && !redo)) continue;
      final beats = BeatFinder.onsets(_samples(clip['file'] as String), rate: rate, count: count);
      if (beats == null) {
        print('WARNING: ${clip['file']}: could not find $count syllables');
        failed++;
        continue;
      }
      clip['beats'] = beats;
      timed++;
    }
    file.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');
    print('Timed $timed clap clips${failed > 0 ? ', $failed failed' : ''}');
    return failed > 0 ? 1 : 0;
  }

  static List<int> _samples(String path) {
    final result = Process.runSync('ffmpeg', [
      '-v',
      'quiet',
      '-i',
      path,
      '-ac',
      '1',
      '-ar',
      '$rate',
      '-f',
      's16le',
      '-',
    ], stdoutEncoding: null);
    final bytes = Uint8List.fromList(result.stdout as List<int>);
    return bytes.buffer.asInt16List(0, bytes.lengthInBytes ~/ 2);
  }
}
