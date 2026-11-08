# 4. Architecture

## Stack

| Concern | Choice | Why |
|---|---|---|
| Framework | **Flutter** (stable channel) | One codebase for Android + iOS, with web possible later. Smooth touch and custom drawing |
| Game-like activities | **Flame** | Runner, drag scenes, particle feedback. Embedded as widgets inside normal Flutter screens |
| State | **Riverpod** | Testable, no global singletons |
| Navigation | **go_router** | Map → unit → activity, with deep links for testing |
| Local storage | **drift** (SQLite) | Profiles, progress and the event log. Queryable for the teacher view and CSV export |
| Audio | **just_audio** (speech), **flame_audio** (effects) | Short clips, low latency, preloading per activity |
| Localization | Flutter `intl` / ARB | Adult-facing UI only (settings, teacher view). Child-facing prompts are audio |

Package choices get re-checked for maintenance status when the project starts.

## Platforms and layout

- **Android and iOS** from milestone 1. **Web** once the core is stable (useful for
  demos and Chromebooks).
- **Phones and tablets, portrait and landscape.** Layouts are built on a "play
  area", a square-ish region scaled to the screen, plus side or bottom rails for
  the controls. No hardcoded pixel offsets (the 2014 code had values like `-252`
  and `-64`).
- **Touch targets at least 64 dp** for children (above the usual 48 dp minimum).
- Minimum supported versions follow Flutter's defaults. The Android target SDK
  follows Google Play's current requirement.

## Project structure

```
lib/
  app/              routing, theme, app shell, shared widgets
  core/
    audio/          prompt player, preload, "listen again"
    content/        content models + loader (reads the generated JSON bundle)
    progress/       mastery rules, spaced review, unlock logic
    logging/        event log, observation mode, CSV export
    profiles/       child profiles, parental gate
  activities/
    common/         activity frame: intro → items → feedback → reward
    spatial/        up_down, left_right, positions, follow_path
    listening/      clap_syllables, rhymes, same_sound, blend
    letter/         meet, trace, find
    syllables/      starts_with, ends_with, build_word, circle_it
    reading/        read_and_match, leo_reads
    runner/         Flame game
  map/              world map, sticker album
  utils/            pure helpers (Spanish syllables, sound keys)
content/            source YAML (see 05) — edited by humans
tool/               content build + validation (Dart CLI)
assets/             generated bundle, images, audio, fonts
test/               unit, widget, golden tests
```

### The activity contract

Every activity is built on the same pieces. That keeps the common frame
consistent and makes new activities cheap to add:

```dart
abstract interface class ActivitySpec {
  String get id;
  List<ActivityItem> buildItems(ActivityContext context);
  Widget buildItemView(ActivityItem item, ItemController controller);
}
```

- `ActivityContext` gives the activity the content bundle, the current step and a
  `Random`.
- `ItemController` is the only thing an item view talks to: `answer(value)` and
  `isHintActive`.
- `ActivitySession` runs the shared frame (intro, items, feedback, hints, reward,
  logging), so a new activity only builds its items and its view.
- Intro prompts follow the convention `<activityId>.intro` in `prompts.yaml`.

`buildItems` **generates** rounds from the word bank, using sound keys and
distractor rules. The 2014 approach of hand-writing one text file per syllable
and activity (about 430 files) goes away.

## Observation mode and data

- **Always on (local only):** the event log that feeds mastery and review, saved in
  SQLite (`lib/core/storage/app_database.dart`) per profile, with the profiles and their
  finished steps. On the web it all stays in memory for now.
- **Profiles:** a nickname and an avatar (one of the animal pictures). With several
  profiles the app opens on a picture-only picker; with one it goes straight to the
  map. The child's avatar on the map hands over to someone else. Adding and deleting
  profiles sits behind the parental gate (a sum written in words).
- **Problem reports:** *Reportar un problema* in the adult zone opens the adult's email
  app (`url_launcher`, `mailto:`) with a draft carrying the app version, the device's
  system and the last game played. Nothing is sent by the app itself, so it still needs
  no internet permission.
- **Observation mode (opt-in, behind the parental gate):** adds session markers
  and an observer note field, and **exports CSV** through the system share sheet.
- **Event row:** `timestamp, profileNick, sessionId, stage, step, activity, itemId,
  target, answer, correct, responseMs, hintUsed, attempts`.
- **Teacher view:** per profile, mastered steps, accuracy per step, the most common
  confusions (for example *b ↔ d*), and time played.
- **Privacy:** no network calls, no analytics SDKs, no advertising IDs. Profile =
  nickname + avatar. Designed to meet the Google Play Families policy and the Apple
  Kids category, and to be easy to explain to schools under Chilean data-protection
  law. Get a legal review of the privacy text before publishing.

## Quality

- **Content validation** (`dart run tool/content.dart validate`) fails the build
  when something is missing or wrong:
  - every phrase has its recorded clip, and every word has a picture, audio, a syllable split and
    a sound key
  - every asset appears in `CREDITS`
  - no generated round has fewer than 4 valid options
- **Tests:**
  - unit tests for mastery, distractor generation and sound keys
  - widget tests for the activity frame
  - golden tests for phone and tablet layouts
- **CI (GitHub Actions):** on every PR, in parallel: format, analyze, content validation
  (`build --check` validates first) and tests; and an Android APK and an iOS build (no
  signing). A new push to a PR cancels its running checks.
- **Releases:** GitHub Releases (APK), Google Play, App Store. F-Droid is worth
  considering because the app has no proprietary dependencies.
