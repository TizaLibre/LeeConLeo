import 'dart:math';

import 'package:flutter_riverpod/misc.dart';

import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/letter_shape.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';
import 'package:lee_con_leo/core/profiles/in_memory_profile_store.dart';
import 'package:lee_con_leo/core/profiles/profile.dart';
import 'package:lee_con_leo/core/profiles/profile_providers.dart';

const testPrompts = PromptLibrary({
  'feedback.correct': ['correct'],
  'feedback.retry': ['retry'],
  'feedback.hint': ['hint'],
  'reward': ['reward'],
  'home.intro': ['home intro'],
  'home.locked': ['home locked'],
  'home.finished': ['home finished'],
  'writing.locked': ['writing locked'],
  'step.intro': ['step intro'],
  'step.done': ['step done'],
  'step.locked': ['step locked'],
  'profiles.intro': ['profiles intro'],
  'review.intro': ['review intro'],
  'stickers.intro': ['stickers intro'],
  'stickers.new': ['new sticker'],
  'spatial.up_down.intro': ['intro'],
  'spatial.up_down.up': ['say up'],
  'spatial.up_down.down': ['say down'],
  'spatial.left_right.intro': ['intro'],
  'spatial.left_right.left': ['say left'],
  'spatial.left_right.right': ['say right'],
  'spatial.positions.intro': ['intro'],
  'spatial.positions.over': ['say over'],
  'spatial.positions.under': ['say under'],
  'spatial.positions.between': ['say between'],
  'letter.meet.intro': ['intro'],
  'letter.meet.a': ['meet a'],
  'letter.meet.a.upper': ['say upper'],
  'letter.meet.a.lower': ['say lower'],
  'letter.meet.a.upper.show': ['show upper'],
  'letter.meet.a.lower.show': ['show lower'],
  'letter.trace.intro': ['intro'],
  'letter.trace.a.lower': ['trace a'],
  'letter.trace.a.upper': ['trace A'],
  'letter.find.intro': ['intro'],
  'letter.find.a': ['find a'],
  'syllables.starts_with.intro': ['intro'],
  'syllables.starts_with.a': ['starts a'],
}, clips: testClips);

const testClips = {
  'feedback.retry.0': 'prompts/feedback.retry.0.m4a',
  'spatial.up_down.up.0': 'prompts/spatial.up_down.up.0.m4a',
};

const testTint = '#EEF7E4';

const testContent = ContentBundle(
  words: [
    Word(text: 'mano', syllables: ['ma', 'no'], sounds: ['ma', 'no']),
    Word(
      text: 'abeja',
      syllables: ['a', 'be', 'ja'],
      sounds: ['a', 'be', 'ja'],
      image: testImage,
      audio: 'words/abeja.m4a',
    ),
    Word(
      text: 'oso',
      syllables: ['o', 'so'],
      sounds: ['o', 'so'],
      image: 'words/oso.svg',
      audio: 'words/oso.m4a',
    ),
    Word(
      text: 'uva',
      syllables: ['u', 'va'],
      sounds: ['u', 'ba'],
      image: 'words/uva.svg',
      audio: 'words/uva.m4a',
    ),
    Word(
      text: 'mesa',
      syllables: ['me', 'sa'],
      sounds: ['me', 'sa'],
      image: 'words/mesa.svg',
      audio: 'words/mesa.m4a',
    ),
  ],
  stages: [
    PathStage(
      stage: 0,
      name: 'Leo explora',
      scene: 'scenes/meadow.svg',
      tint: testTint,
      steps: [
        PathStep(id: 'up-down', icon: 'steps/up_down.svg', activities: ['spatial.up_down']),
        PathStep(id: 'left-right', activities: ['spatial.left_right']),
        PathStep(id: 'positions', activities: ['spatial.positions']),
        PathStep(
          id: 'a',
          grapheme: 'a',
          sounds: ['a'],
          word: 'abeja',
          activities: ['letter.meet', 'letter.trace', 'letter.find', 'syllables.starts_with'],
        ),
        PathStep(id: 'e', grapheme: 'e', sounds: ['e'], activities: ['letter.find']),
      ],
    ),
  ],
  prompts: testPrompts,
  letters: {'a': testLetter},
);

const testImage = 'words/abeja.svg';

const testLetter = LetterShape(
  lower: [
    [Point(0.0, 0.0), Point(0.0, 100.0)],
    [Point(0.0, -40.0)],
  ],
  upper: [
    [Point(0.0, 0.0), Point(50.0, 50.0), Point(100.0, 0.0)],
  ],
);

const testProfile = Profile(id: 1, nickname: 'Ana', avatar: 'words/oso.svg');

Override singleProfile() =>
    profileStoreProvider.overrideWithValue(InMemoryProfileStore(const [testProfile]));
