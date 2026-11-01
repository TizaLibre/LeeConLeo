# Lee con Leo 2.0 — Plan

Plan for rebuilding **Lee con Leo** (2014, Android tablet thesis project) as an
**open, free, multi-platform** app that helps Chilean pre-schoolers take their
first steps into reading.

The 2014 code lives in the archived repository `LeeConLeo-Legacy` (see
[07-legacy.md](07-legacy.md)).

| # | Document | What it answers |
|---|---|---|
| 1 | [Vision and principles](01-vision.md) | Who it is for, what "good" looks like, the design rules every feature must follow |
| 2 | [Learning path](02-learning-path.md) | What is taught, in what order, and how Spanish sounds are modelled |
| 3 | [Activities](03-activities.md) | Each game: goal, mechanic, feedback, what gets logged. What was kept, merged, dropped, added |
| 4 | [Architecture](04-architecture.md) | Flutter + Flame, app structure, storage, observation mode, testing |
| 5 | [Content and assets](05-content-and-assets.md) | Content format, migrating the 2014 data, pictures, audio, fonts, licensing |
| 6 | [Roadmap](06-roadmap.md) | Milestones with acceptance criteria |
| 7 | [Legacy repository](07-legacy.md) | What happens to the 2014 code |
| 8 | [Open questions](08-open-questions.md) | Decisions still pending |
| 9 | [Release](09-release.md) | Version, signing key, building for Google Play, privacy page, store checklist |

## Summary

- **Stack:** Flutter (Android + iOS first, web later), plus Flame for the game-like
  activities.
- **Audience:** children aged about 4–6, playing on phones or tablets, alone or
  guided by a teacher or parent. They can't read yet, so **the app never requires
  reading text**.
- **Pedagogy:** keep the Silabario Hispanoamericano order, add single vowels first
  and phonological-awareness games, and model syllables by *sound* (Chilean
  Spanish), not only by spelling.
- **Gamification stays, but every game trains reading.** The runner returns as
  "catch the syllable you hear".
- **Evidence built in:** an optional observation mode logs taps, errors and time
  per activity, and exports CSV for testing sessions with teachers.
- **Assets:** dedicated illustrations (SVG drawn by Claude, plus AI-generated
  images), offline TTS voices for now, and the Playwrite Chile school font.
- **Open:** code under MIT, original content under CC BY-SA 4.0, and every
  third-party asset openly licensed and credited. **None of the 2014 internet
  images or audio will be shipped.**
