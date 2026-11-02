# 3. Activities

## What happens to each 2014 activity

| 2014 activity | Decision | Becomes |
|---|---|---|
| Vertical (up/down) | **Keep**, spoken | Spatial: *Up / down* |
| Horizontal: tap, drag | **Keep**, spoken | Spatial: *Left / right* |
| Horizontal: tilt | **Drop** | Not every device has the sensor, it's awkward in class, and it adds nothing to reading |
| Between (tables) | **Keep and extend**, and give it an end | Spatial: *Over / under / between / in / out* |
| Platform runner | **Reinvent** | *Leo runs*: catch the syllable you hear |
| Introduction | **Keep** | Letter sequence, step 1: *Meet* |
| Stitch (dots) | **Merge** | Letter sequence, step 2: *Trace* |
| Paint (free coloring) | **Merge** | Coloring becomes the reward at the end of *Trace* |
| Tap (bubbles on the shape) | **Change** | Letter sequence, step 3: *Find* (pop the right letter among lookalikes) |
| Starts with | **Keep** | *Starts with* |
| Ends with | **Keep** | *Ends with* |
| Join starts / ends with | **Merge** | A second way to play *Starts with / Ends with* (drag a line instead of tapping) |
| Wrap (circle inside words) | **Keep, later stage** | *Circle it*: find the syllable inside words. A curated child vocabulary replaces the 52,787-word adult list, and each word has a picture and audio |

## Step screen

Each letter or syllable is one stone on the map. Tapping it opens the step screen:
the letter or syllables on top, and one big card per game with an icon, in the order
`path.yaml` lists them (listening, then letters, then syllables). Every card is open;
the suggested next one pulses, and a star marks the ones already played. A step with a
single game skips this screen and opens the game directly.
Once every game of the step was played, Leo says so and a pulsing arrow in the bottom right corner takes the child
to the next step (or back to the map after the last one).

## Common frame for every activity

Every activity follows the same frame, so children learn it once:

1. **Leo explains** (audio), and an animated hand shows the first move until the
   child touches the screen.
2. **The child plays** 5–8 items.
3. **Feedback on every item:** a sound, an animation and a short spoken phrase.
   After 2 errors on an item, a hint: the correct option glows and the hand shows
   the move again.
4. **Reward:** a sticker or a star, then back to the step screen.
5. **Logging:** every item records `{activity, item, answer, correct, ms, hintUsed}`
   (see [04](04-architecture.md)).

Always on screen: a large **"listen again"** button (Leo's face) and a **back to
map** button.

## Activity catalogue

### Stage 0: spatial

| Activity | Mechanic | Example prompt |
|---|---|---|
| *Up / down* | Tap the right arrow, then drag Leo up or down | "¡Lleva a Leo **arriba**!" |
| *Left / right* | Same, left and right. Later: "which way does the arrow point?" to prepare for left-to-right reading | "¿Hacia dónde mira el perrito?" |
| *Over, under, between* | Drag an object into position in a scene | "Pon la pelota **entre** las mesas" |
| *In / out* | Drag objects into or out of a box | |
| *Follow the path* (new) | Trace a path with a finger from left to right, top to bottom | Builds the direction of reading and writing |

### Stage 1: listening (phonological awareness)

| Activity | Mechanic |
|---|---|
| *Clap the syllables* | See a picture and hear its word, tap the clapping hands once per syllable (*ma-ri-po-sa* → 4), then the check. Each tap adds a dot and sounds a clap; a wrong count clears them, and the hint shows the right number of empty dots. On the first word, and as the hint, Leo shows how first ("¡Mira cómo aplaudo!"): he says the word split up and claps on each syllable (silently, so his voice stays clear), with a blue dot and the hands button bouncing, then says "¡Ahora tú!". When right, Leo says the word split up while clapping along. Words start with the step's sounds when there are enough, rotating 1–4 syllables |
| *Rhymes* | Hear two words, tap the happy or sad face |
| *Same sound* | Hear a sound, pick the picture that starts with it. *Starts with* without the written card, using the same questions. Like every picture game, a word only counts when it is both said and written with the sound (*humo* is not a *u* word, *cebra* is not a *se* word), and pictures that sound or look like the answer are never the wrong options |
| *Blend the sounds* | Leo says "Junta los pedacitos… ma… pa" while the written syllables appear one by one, and the child picks the picture among 3 (*mapa*). A wrong picture is named. Words follow the *Build the word* rule, so it runs on syllable steps from pa on, just before *Build the word* |

### Letter sequence (for each vowel and consonant)

| Step | Mechanic |
|---|---|
| *Meet* | Leo says the letter's name, an example syllable and a word ("eme… **ma**… **ma**no"). Printed and school-cursive forms, upper and lower case |
| *Trace* | Follow the strokes in the correct order with a finger: a glowing start point (children may not know numbers yet), arrows, and a path that fills in as the finger moves. Tolerance adapts to age. Finishing unlocks coloring the letter |
| *Find* | Letters float as bubbles. Pop every target letter, avoiding lookalikes (b/d, p/q, m/n) |

### Syllable sequence (for each consonant, after its letter)

Follows the Silabario: the consonant is never sounded alone, it is read joined to a
vowel, first in order (*ma me mi mo mu*), then mixed, then written.

| Step | Mechanic |
|---|---|
| *Meet* | Leo joins the letters one syllable at a time ("La, eme, y la, a, juntas dicen, ma"), showing *m + a* above the written *ma*. Then three mixed rounds: "¿Dónde dice, mo?" among three syllables of the family. A wrong tap speaks that syllable |
| *Trace* | Write three syllables of the family in joined cursive, as one stroke from the consonant into the vowel |
| *Find* | Syllable bubbles, in lower case or capitalized (*mo*, *Mo*). Pop the target, among others of the same family (*ma*, *mu*) and of other families |
| *Starts with*, *Ends with* | The listening games below, with the written syllable shown above the pictures |
| *Build the word* | The word games below, from the second consonant on |

### Syllables and words

| Activity | Mechanic |
|---|---|
| *Starts with* | Hear a syllable and see it written, and 4 pictures appear. Tap (or drag a line to) the one that starts with it. Tapping a picture speaks its name |
| *Ends with* | Same, with the ending |
| *Contains* | Same, with the syllable anywhere in the word (*piña* has *ña*). Carries steps like *ñ*, whose syllables rarely start a word |
| *Build the word* (new) | A picture and its spoken word. Drag or tap syllable tiles into the slots in order (*ma + pa*), among two extra syllables of the family. A wrong tile speaks that syllable. Words use only syllables already taught and at least one of the step's own |
| *Write the word* (new) | Free practice from the pencil button on the map, open once a word can be written (from pa on). Leo says a word, its picture shows, and the child writes it freehand over the faint word in *letra ligada*, on lined paper. The ink is graded against the word: how much of it was covered and how much ink stayed on it, from 0 to 3 stars. No star wipes the ink for another try, and after two tries any writing passes. Answers are logged under `writing`, apart from the path steps. After the last step of the path, Leo celebrates and invites the child to keep writing |
| *Circle it* | Circle the target syllable inside written words. Stage 5 and after |
| *Read and match* (new) | Read a word and match it to one of 3 pictures. Stage 8 |
| *Leo reads* (new) | Short sentence ("Mi mamá me mima") plus 3 pictures. Pick the one that matches. Stage 8 |

### *Leo runs* (the runner, reinvented)

A side-scrolling runner built with Flame. Leo hears a target syllable ("¡Atrapa
**pa**!"). Syllable balloons come along the path: swipe up to jump and catch the
right ones, swipe down to duck under the wrong ones. Speed and distractor
similarity adapt to accuracy. It keeps the 2014 gamification idea, and now the
child reads while playing. It unlocks as a reward after each consonant group.

## Motivation layer

- **Map:** Leo travels through places (meadow, beach, forest, mountains…), one
  screen each with a few steps. The child swipes between places like pages.
- **Stickers:** a collectible album, one sticker per mastered step: the step's icon,
  its key word, or for a syllable step the first picture that starts with its syllable.
  The reward screen shows a new sticker when the step becomes mastered, and the album
  opens from the map.
- **No punishment:** no lives lost, no timers in learning activities (the runner
  is the only timed game, and it's optional).

## Later ideas (not in the first roadmap)

- **Read aloud:** the child says the syllable and on-device speech recognition
  checks it. Children's speech is hard to recognize, and this needs privacy review,
  so it stays experimental and offline only.
- **Teacher-made word lists** loaded from a file.
- Mapuzungun or other language packs, through the same content format.
