import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity_registry.dart';
import 'common/activity_spec.dart';
import 'letters/find_activity.dart';
import 'listening/clap_activity.dart';
import 'letters/meet_activity.dart';
import 'letters/trace_activity.dart';
import 'review/review_activity.dart';
import 'sounds/picture_sound_activity.dart';
import 'spatial/direction_activity.dart';
import 'spatial/positions_activity.dart';
import 'syllables/blend_activity.dart';
import 'syllables/build_word_activity.dart';
import 'syllables/syllable_find_activity.dart';
import 'syllables/syllable_meet_activity.dart';
import 'syllables/syllable_trace_activity.dart';
import 'writing/write_word_activity.dart';

final _games = <ActivitySpec>[
  DirectionActivity.upDown,
  DirectionActivity.leftRight,
  const PositionsActivity(),
  const ClapActivity(),
  PictureSoundActivity.sameSound,
  const MeetActivity(),
  const TraceActivity(),
  const FindActivity(),
  const SyllableMeetActivity(),
  const SyllableTraceActivity(),
  const SyllableFindActivity(),
  PictureSoundActivity.startsWith,
  PictureSoundActivity.endsWith,
  PictureSoundActivity.contains,
  const BlendActivity(),
  const BuildWordActivity(),
];

final activityRegistryProvider = Provider<ActivityRegistry>(
  (ref) => ActivityRegistry([..._games, const WriteWordActivity(), ReviewActivity(_games)]),
);
