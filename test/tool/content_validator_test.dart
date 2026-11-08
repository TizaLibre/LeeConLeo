import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/content/models/letter_shape.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';
import 'package:lee_con_leo/core/content/models/path_stage.dart';
import 'package:lee_con_leo/core/content/models/path_step.dart';
import 'package:lee_con_leo/core/content/models/prompt_library.dart';
import 'package:lee_con_leo/core/content/models/word.dart';

import '../../tool/src/validation/rules/activity_intros_rule.dart';
import '../../tool/src/validation/rules/blend_steps_rule.dart';
import '../../tool/src/validation/rules/build_word_steps_rule.dart';
import '../../tool/src/validation/rules/clap_steps_rule.dart';
import '../../tool/src/validation/rules/known_activities_rule.dart';
import '../../tool/src/validation/rules/letter_steps_rule.dart';
import '../../tool/src/validation/rules/path_images_rule.dart';
import '../../tool/src/validation/rules/picture_sound_steps_rule.dart';
import '../../tool/src/validation/rules/place_size_rule.dart';
import '../../tool/src/validation/rules/prompt_clips_rule.dart';
import '../../tool/src/validation/rules/stage_tints_rule.dart';
import '../../tool/src/validation/rules/syllable_steps_rule.dart';
import '../../tool/src/validation/rules/syllables_match_text_rule.dart';
import '../../tool/src/validation/rules/unique_ids_rule.dart';

ContentBundle _bundle({List<Word> words = const [], List<PathStep> steps = const []}) =>
    ContentBundle(
      words: words,
      stages: [PathStage(stage: 0, name: 'test', steps: steps)],
      prompts: const PromptLibrary({}),
    );

void main() {
  test('flags syllables that do not spell the word', () {
    final bundle = _bundle(
      words: [
        const Word(text: 'mano', syllables: ['ma', 'mo'], sounds: ['ma', 'mo']),
      ],
    );
    expect(const SyllablesMatchTextRule().check(bundle).single.isError, isTrue);
  });

  test('flags duplicate words and steps', () {
    const word = Word(text: 'sol', syllables: ['sol'], sounds: ['sol']);
    const step = PathStep(id: 'a', activities: []);
    final bundle = _bundle(words: [word, word], steps: [step, step]);
    expect(const UniqueIdsRule().check(bundle), hasLength(2));
  });

  test('flags unknown activity ids', () {
    final bundle = _bundle(
      steps: [
        const PathStep(id: 'a', activities: ['letter.meet', 'letter.dance']),
      ],
    );
    final issues = const KnownActivitiesRule().check(bundle).toList();
    expect(issues.single.message, contains('letter.dance'));
  });

  test('flags step icons that do not exist', () {
    final bundle = _bundle(
      steps: [
        const PathStep(id: 'up-down', activities: [], icon: 'steps/up_down.svg'),
        const PathStep(id: 'lost', activities: [], icon: 'steps/missing.svg'),
        const PathStep(id: 'a', activities: []),
      ],
    );
    final issues = const PathImagesRule().check(bundle).toList();
    expect(issues.single.message, contains('lost'));
  });

  test('flags stage scenes that do not exist', () {
    const bundle = ContentBundle(
      words: [],
      stages: [
        PathStage(stage: 0, name: 'ok', scene: 'scenes/meadow.svg', steps: []),
        PathStage(stage: 1, name: 'lost', scene: 'scenes/missing.svg', steps: []),
      ],
      prompts: PromptLibrary({}),
    );
    final issues = const PathImagesRule().check(bundle).toList();
    expect(issues.single.message, contains('stage 1'));
  });

  test('flags clips without a prompt and phrases without a clip', () {
    const bundle = ContentBundle(
      words: [],
      stages: [],
      prompts: PromptLibrary(
        {
          'feedback.correct': ['¡Muy bien!', '¡Súper!'],
        },
        clips: {
          'feedback.correct.0': 'prompts/feedback.correct.0.m4a',
          'feedback.correct.5': 'prompts/feedback.correct.5.m4a',
        },
      ),
    );
    final issues = const PromptClipsRule().check(bundle).toList();

    expect(issues.every((issue) => issue.isError), isTrue);
    expect(issues.map((issue) => issue.message), [
      contains('feedback.correct.5'),
      contains('"feedback.correct.1" has no recorded clip'),
    ]);
  });

  test('flags stage tints that are not colors', () {
    const bundle = ContentBundle(
      words: [],
      stages: [
        PathStage(stage: 0, name: 'ok', tint: '#EEF7E4', steps: []),
        PathStage(stage: 1, name: 'bad', tint: 'green', steps: []),
      ],
      prompts: PromptLibrary({}),
    );
    final issues = const StageTintsRule().check(bundle).toList();
    expect(issues.single.message, contains('green'));
  });

  group('letter steps', () {
    ContentBundle letterBundle({
      String? word = 'abeja',
      Map<String, LetterShape> letters = const {},
      Map<String, List<String>> prompts = const {},
    }) => ContentBundle(
      words: const [
        Word(
          text: 'abeja',
          syllables: ['a', 'be', 'ja'],
          sounds: ['a', 'be', 'ja'],
          image: 'x.svg',
        ),
        Word(text: 'ala', syllables: ['a', 'la'], sounds: ['a', 'la']),
      ],
      stages: [
        PathStage(
          stage: 2,
          name: 'vocales',
          steps: [
            PathStep(
              id: 'a',
              grapheme: 'a',
              word: word,
              activities: const ['letter.meet', 'letter.trace', 'letter.find'],
            ),
          ],
        ),
      ],
      prompts: PromptLibrary(prompts),
      letters: letters,
    );

    const shape = LetterShape(
      lower: [
        [Point(0.0, 0.0), Point(0.0, 10.0)],
      ],
      upper: [
        [Point(0.0, 0.0), Point(5.0, 10.0)],
      ],
    );
    const prompts = {
      'letter.meet.a': ['Esta es la a.'],
      'letter.meet.a.upper': ['Toca la a mayúscula.'],
      'letter.meet.a.lower': ['Toca la a minúscula.'],
      'letter.meet.a.upper.show': ['Esta es la a mayúscula.'],
      'letter.meet.a.lower.show': ['Y esta es la a minúscula.'],
      'letter.trace.a.lower': ['Repasa la a minúscula.'],
      'letter.trace.a.upper': ['Repasa la a mayúscula.'],
      'letter.find.a': ['Revienta las a.'],
    };

    test('a complete letter step passes', () {
      final bundle = letterBundle(letters: const {'a': shape}, prompts: prompts);
      expect(const LetterStepsRule().check(bundle), isEmpty);
    });

    test('flags missing prompts and stroke data', () {
      final issues = const LetterStepsRule().check(letterBundle()).map((i) => i.message).toList();

      expect(issues, hasLength(9));
      expect(issues, contains(contains('"letter.find.a"')));
      expect(issues, contains(contains('no stroke data for "a"')));
    });

    test('flags a meet word that is missing or has no picture', () {
      final noPicture = letterBundle(word: 'ala', letters: const {'a': shape}, prompts: prompts);
      final unknown = letterBundle(word: 'oso', letters: const {'a': shape}, prompts: prompts);

      expect(const LetterStepsRule().check(noPicture).single.message, contains('no image'));
      expect(
        const LetterStepsRule().check(unknown).single.message,
        contains('not in the word bank'),
      );
    });
  });

  group('starts with steps', () {
    Word pictured(String text, List<String> sounds, {bool hasAudio = true}) => Word(
      text: text,
      syllables: sounds,
      sounds: sounds,
      image: 'words/$text.svg',
      audio: hasAudio ? 'words/$text.m4a' : null,
    );

    ContentBundle bundle(
      List<Word> words, {
      List<String> sounds = const ['a'],
      bool hasPrompt = true,
    }) => ContentBundle(
      words: words,
      stages: [
        PathStage(
          stage: 2,
          name: 'vocales',
          steps: [
            PathStep(id: 'a', sounds: sounds, activities: const ['syllables.starts_with']),
          ],
        ),
      ],
      prompts: PromptLibrary({
        if (hasPrompt) 'syllables.starts_with.a': ['¿Qué dibujo empieza con, a?'],
      }),
    );

    final complete = [
      pictured('abeja', ['a', 'be', 'ja']),
      pictured('oso', ['o', 'so']),
      pictured('uva', ['u', 'ba']),
      pictured('mesa', ['me', 'sa']),
    ];

    test('a step with a sound, its phrase and enough pictures passes', () {
      expect(const PictureSoundStepsRule().check(bundle(complete)), isEmpty);
    });

    test('flags a missing phrase, too few pictures and pictures without audio', () {
      final issues = const PictureSoundStepsRule()
          .check(
            bundle([
              pictured('abeja', ['a', 'be', 'ja']),
              pictured('oso', ['o', 'so'], hasAudio: false),
            ], hasPrompt: false),
          )
          .map((issue) => issue.message)
          .toList();

      expect(issues, [
        contains('"oso": a word with a picture needs audio'),
        contains('missing prompt "syllables.starts_with.a"'),
        contains('fewer than 3 pictures'),
      ]);
    });

    test('flags a step without a sound or without a matching picture', () {
      expect(
        const PictureSoundStepsRule().check(bundle(complete, sounds: const [])).single.message,
        contains('needs a sound'),
      );
      expect(
        const PictureSoundStepsRule().check(bundle(complete.skip(1).toList())).single.message,
        contains('no word with a picture starts with any of a'),
      );
    });

    group('ends with', () {
      ContentBundle endsWith(List<Word> words, {bool hasPrompt = true}) => ContentBundle(
        words: words,
        stages: const [
          PathStage(
            stage: 4,
            name: 'bosque',
            steps: [
              PathStep(id: 'ma', sounds: ['ma', 'mu'], activities: ['syllables.ends_with']),
            ],
          ),
        ],
        prompts: PromptLibrary({
          if (hasPrompt) 'syllables.ends_with.ma': ['¿Qué dibujo termina con, ma?'],
        }),
      );

      final words = [
        ...complete,
        pictured('puma', ['pu', 'ma']),
      ];

      test('asks only the sounds some picture ends with', () {
        expect(const PictureSoundStepsRule().check(endsWith(words)), isEmpty);
        expect(
          const PictureSoundStepsRule().check(endsWith(words, hasPrompt: false)).single.message,
          contains('missing prompt "syllables.ends_with.ma"'),
        );
      });

      test('flags a step where no picture ends with any sound', () {
        expect(
          const PictureSoundStepsRule().check(endsWith(complete)).single.message,
          contains('no word with a picture ends with any of ma, mu'),
        );
      });
    });
  });

  group('syllable steps', () {
    const strokes = [
      [Point(0.0, 0.0), Point(10.0, 10.0)],
    ];

    ContentBundle syllableBundle({
      List<String> sounds = const ['ma', 'me'],
      Map<String, List<List<Point<double>>>> syllables = const {'ma': strokes, 'me': strokes},
      bool hasPrompts = true,
    }) => ContentBundle(
      words: const [],
      stages: [
        PathStage(
          stage: 4,
          name: 'bosque',
          steps: [
            PathStep(
              id: 'ma',
              sounds: sounds,
              activities: const ['syllables.meet', 'syllables.trace', 'syllables.find'],
            ),
          ],
        ),
      ],
      prompts: PromptLibrary({
        if (hasPrompts)
          for (final sound in sounds) ...{
            'syllables.meet.$sound': ['meet'],
            'syllables.meet.$sound.choose': ['choose'],
            'syllables.trace.$sound': ['trace'],
            'syllables.find.$sound': ['find'],
          },
      }),
      syllables: syllables,
    );

    const rule = SyllableStepsRule(checkClips: false);

    test('a step with its phrases and strokes passes', () {
      expect(rule.check(syllableBundle()), isEmpty);
    });

    test('flags missing phrases, missing strokes and single sounds', () {
      expect(
        rule.check(syllableBundle(hasPrompts: false)).map((issue) => issue.message),
        hasLength(8),
      );
      expect(
        rule.check(syllableBundle(syllables: const {'ma': strokes})).single.message,
        contains('no stroke data for "me"'),
      );
      expect(
        rule.check(syllableBundle(sounds: const ['ma'])).single.message,
        contains('two or more sounds'),
      );
    });
  });

  group('build word steps', () {
    const mapa = Word(
      text: 'mapa',
      syllables: ['ma', 'pa'],
      sounds: ['ma', 'pa'],
      image: 'words/mapa.svg',
      audio: 'words/mapa.m4a',
    );

    ContentBundle buildBundle({List<Word> words = const [mapa], bool hasPrompts = true}) =>
        ContentBundle(
          words: words,
          stages: const [
            PathStage(
              stage: 4,
              name: 'bosque',
              steps: [
                PathStep(id: 'ma', sounds: ['ma', 'me'], activities: []),
                PathStep(id: 'pa', sounds: ['pa', 'pe'], activities: ['syllables.build_word']),
              ],
            ),
          ],
          prompts: PromptLibrary({
            if (hasPrompts) 'syllables.build_word.mapa': ['build mapa'],
          }),
        );

    const rule = BuildWordStepsRule();

    test('a step with a word made of known syllables and its phrase passes', () {
      expect(rule.check(buildBundle()), isEmpty);
    });

    test('blending needs the ask phrase and the split phrase of every word', () {
      ContentBundle blendBundle(Map<String, List<String>> phrases) => ContentBundle(
        words: const [mapa],
        stages: const [
          PathStage(
            stage: 4,
            name: 'bosque',
            steps: [
              PathStep(id: 'ma', sounds: ['ma', 'me'], activities: []),
              PathStep(id: 'pa', sounds: ['pa', 'pe'], activities: ['syllables.blend']),
            ],
          ),
        ],
        prompts: PromptLibrary(phrases),
      );

      expect(
        const BlendStepsRule().check(
          blendBundle({
            'syllables.blend.ask': ['ask'],
            'listening.clap.mapa': ['Ma... pa.'],
          }),
        ),
        isEmpty,
      );
      expect(const BlendStepsRule().check(blendBundle({})).map((issue) => issue.message), [
        contains('syllables.blend.ask'),
        contains('listening.clap.mapa'),
      ]);
    });

    test('flags a missing phrase and a step with no word to build', () {
      expect(
        rule.check(buildBundle(hasPrompts: false)).single.message,
        contains('missing prompt "syllables.build_word.mapa"'),
      );
      const humo = Word(
        text: 'humo',
        syllables: ['hu', 'mo'],
        sounds: ['u', 'mo'],
        image: 'words/humo.svg',
        audio: 'words/humo.m4a',
      );
      expect(
        rule.check(buildBundle(words: const [humo])).single.message,
        contains('no word with a picture'),
      );
    });
  });

  test('a clapping step needs the ask phrase and a split phrase for every word', () {
    const sol = Word(
      text: 'sol',
      syllables: ['sol'],
      sounds: ['sol'],
      image: 'words/sol.svg',
      audio: 'words/sol.m4a',
    );
    ContentBundle clapBundle(Map<String, List<String>> phrases) => ContentBundle(
      words: const [sol],
      stages: const [
        PathStage(
          stage: 2,
          name: 'vocales',
          steps: [
            PathStep(id: 'o', sounds: ['o'], activities: ['listening.clap']),
          ],
        ),
      ],
      prompts: PromptLibrary(phrases),
    );

    expect(
      const ClapStepsRule().check(
        clapBundle({
          'listening.clap.ask': ['ask'],
          'listening.clap.sol': ['Sol.'],
        }),
      ),
      isEmpty,
    );
    expect(const ClapStepsRule().check(clapBundle({})).map((issue) => issue.message), [
      contains('listening.clap.ask'),
      contains('listening.clap.sol'),
    ]);
  });

  test('every game a step lists needs an intro phrase', () {
    final bundle = ContentBundle(
      words: const [],
      stages: const [
        PathStage(
          stage: 2,
          name: 'vocales',
          steps: [
            PathStep(id: 'a', activities: ['letter.meet', 'letter.find']),
          ],
        ),
      ],
      prompts: const PromptLibrary({
        'letter.meet.intro': ['¡Hola!'],
      }),
    );
    expect(
      const ActivityIntrosRule().check(bundle).single.message,
      contains('missing prompt "letter.find.intro"'),
    );
  });

  test('flags places with no steps or too many to fit one screen', () {
    PathStage place(String name, int steps) => PathStage(
      stage: 4,
      name: name,
      steps: [for (var i = 0; i < steps; i++) PathStep(id: '$name-$i', activities: const [])],
    );
    final bundle = ContentBundle(
      words: const [],
      stages: [place('ok', 6), place('empty', 0), place('long', 7)],
      prompts: const PromptLibrary({}),
    );

    final issues = const PlaceSizeRule().check(bundle).map((issue) => issue.message).toList();
    expect(issues, [contains('"empty" has no steps'), contains('"long" has 7 steps')]);
  });
}
