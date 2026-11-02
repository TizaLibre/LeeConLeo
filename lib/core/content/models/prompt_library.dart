import 'dart:math';

import 'spoken_line.dart';

class PromptLibrary {
  const PromptLibrary(this.phrases, {this.clips = const {}, this.beats = const {}});

  factory PromptLibrary.fromJson(
    Map<String, dynamic> json, {
    Map<String, String> clips = const {},
    Map<String, List<double>> beats = const {},
  }) => PromptLibrary(
    {for (final entry in json.entries) entry.key: (entry.value as List).cast<String>()},
    clips: clips,
    beats: beats,
  );

  static Map<String, List<double>> beatsFromJson(Map<String, dynamic>? json) => {
    for (final entry in (json ?? const {}).entries)
      entry.key: [for (final beat in entry.value as List) (beat as num).toDouble()],
  };

  final Map<String, List<String>> phrases;
  final Map<String, String> clips;
  final Map<String, List<double>> beats;

  static String clipKey(String id, int index) => '$id.$index';

  bool contains(String id) => phrases.containsKey(id);

  SpokenLine line(String id, Random random) {
    final options = phrases[id];
    if (options == null || options.isEmpty) return const SpokenLine('');
    final index = random.nextInt(options.length);
    final key = clipKey(id, index);
    return SpokenLine(options[index], clip: clips[key], beats: beats[key] ?? const []);
  }

  String pick(String id, Random random) => line(id, random).text;

  Map<String, dynamic> toJson() => phrases;
}
