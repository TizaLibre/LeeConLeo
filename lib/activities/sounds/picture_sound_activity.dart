import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../core/content/models/spoken_line.dart';
import '../../core/content/models/word.dart';
import '../../core/content/picture_sound_game.dart';
import '../../core/content/sound_position.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'picture_sound_view.dart';

class PictureItem extends ActivityItem {
  const PictureItem({
    required super.id,
    required super.target,
    required super.promptId,
    required super.options,
    required super.optionNames,
    required this.sound,
    required this.images,
    this.showsSound = true,
  });

  final String sound;
  final Map<String, String> images;
  final bool showsSound;
}

class PictureSoundActivity implements ActivitySpec {
  const PictureSoundActivity._(this.game);

  static const startsWith = PictureSoundActivity._(PictureSoundGame.startsWith);
  static const endsWith = PictureSoundActivity._(PictureSoundGame.endsWith);
  static const contains = PictureSoundActivity._(PictureSoundGame.contains);
  static const sameSound = PictureSoundActivity._(PictureSoundGame.sameSound);

  final PictureSoundGame game;

  SoundPosition get position => game.position;

  @override
  String get id => game.activityId;

  static const rounds = 4;
  static const choices = 4;

  List<String> askedSounds(ActivityContext context) {
    final pictures = SoundPosition.pictured(context.content.words);
    return [
      for (final sound in context.step.sounds)
        if (pictures.any((word) => game.matches(word, sound))) sound,
    ];
  }

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final random = context.random;
    final sounds = askedSounds(context);
    final pictures = SoundPosition.pictured(context.content.words);
    final ordered = _fill(sounds, random);
    final targets = {
      for (final sound in sounds)
        sound: pictures.where((word) => game.matches(word, sound)).toList()..shuffle(random),
    };
    final unlike = pictures
        .where((word) => !context.step.sounds.any((sound) => game.resembles(word, sound)))
        .toList();
    final asked = <String, int>{};
    final items = <ActivityItem>[];
    for (final (round, sound) in ordered.indexed) {
      final turn = asked[sound] = (asked[sound] ?? -1) + 1;
      final matches = targets[sound]!;
      final others = [...unlike]..shuffle(random);
      items.add(
        _item(round, sound, matches[turn % matches.length], others.take(choices - 1), random),
      );
    }
    return items;
  }

  List<String> _fill(List<String> sounds, Random random) {
    if (sounds.isEmpty) return const [];
    final count = max(rounds, sounds.length);
    final ordered = <String>[];
    while (ordered.length < count) {
      ordered.addAll([...sounds]..shuffle(random));
    }
    return ordered.take(count).toList();
  }

  PictureItem _item(
    int round,
    String sound,
    Word target,
    Iterable<Word> distractors,
    Random random,
  ) {
    final words = [target, ...distractors]..shuffle(random);
    return PictureItem(
      id: '$round-${target.text}',
      target: target.text,
      promptId: game.promptId(sound),
      sound: sound,
      options: [for (final word in words) word.text],
      optionNames: {for (final word in words) word.text: SpokenLine(word.text, clip: word.audio)},
      images: {for (final word in words) word.text: word.image!},
      showsSound: game.showsSound,
    );
  }

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      PictureSoundView(item: item as PictureItem, controller: controller);
}
