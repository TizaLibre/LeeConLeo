# 2. Learning path

## Stages

```
Stage 0  Spatial concepts        up/down, left/right, over/under, between, in/out
Stage 1  Listening               syllable clapping, rhymes, "same first sound?"  (no letters yet)
Stage 2  Vowels                  a  e  i  o  u   (single vowels — new in 2.0)
Stage 3  Vowel combinations      ai au ei eu oi ... ("ay", "oye", "au")  (the 2014 starting point)
Stage 4  Direct syllables        consonant + vowel: ma me mi mo mu, pa pe ...  (Silabario order)
Stage 5  Inverse syllables       am em im om um, al el ..., as es ...
Stage 6  Special graphemes       ch, ll, rr, ñ, qu (que/qui), gue/gui, güe/güi, soft c (ce/ci), soft g (ge/gi), silent h
Stage 7  Blends ("trabadas")     bl br cl cr dr fl fr gl gr pl pr tr
Stage 8  Words and sentences     read a word → match it to a picture → read a short sentence
```

Stage 1 runs **alongside** stages 2–4 as review and warm-up games. It isn't a gate
the child has to pass first.

Stage 3 comes **after** the first consonants, not before them: following the MINEDUC
guide, vowel combinations are an advanced step, so the path goes from the vowels
straight to *m p l d s*.

### Why single vowels first

In 2014 the map started at "ao". A child who doesn't know "a" or "o" on their own
gets two unknowns at once. The Silabario itself starts from single vowels, and they
are also the pieces of every syllable after that.

## Consonant order

The working order for the first consonants, still to be confirmed with teachers or a
Silabario edition:

```
m p l s t d n ñ f
```

It starts the same as the 2014 order and brings *t* and *n* forward, as proposed
below. The 2014 order, which teachers chose because children know these letters best:

```
m p l d s b c(ca co cu) f g(ga go gu) h j k n r t v w x y z
```

Proposed changes, **to be validated with teachers**:

| Change | Reason |
|---|---|
| Move **t** and **n** right after s | Very common in first words (*tomate, nene, mono*), and their sounds are clear |
| Move **k, w, x** to the end | Rare in children's vocabulary, and many of their syllables had no pictures in 2014 |
| Split **c** and **g** by sound | *ca co cu* belongs in stage 4. *ce ci* (sounds like /s/) and *ge gi* (sounds like /x/, "j") go to stage 6 |
| **h** in stage 6, taught as "the silent letter" | *ha* sounds like *a*. Treating it as a regular consonant confuses children |
| **r:** teach the soft *r* inside words (*pera*); the strong *r* at the start of words (*ratón*) and *rr* come later | These are two different sounds written with the same letter |
| Add **ñ, ch, ll** | Missing in 2014, and very common in Chilean words (*niño, chancho, llave*) |

The order lives in a content file (`path.yaml`, see
[05](05-content-and-assets.md)), so a teacher or a fork can reorder it without
touching code.

## How sounds are modelled

Every syllable and word carries a **sound key** for Chilean Spanish. Activities
compare sound keys, not spellings.

| Written | Sound key | Consequence |
|---|---|---|
| ce, ci / se, si / ze, zi | `se`, `si` | Seseo: *cielo* and *silla* **both** start with the /si/ sound |
| ge, gi / je, ji | `je`, `ji` | *gente* and *jefe* share a starting sound |
| ha, he ... | `a`, `e` ... | *helado* starts with the /e/ sound |
| ba / va | `ba` | *vaca* and *barco* share a starting sound |
| ya / lla | `ya` | Yeísmo: *llave* and *yate* share a starting sound |
| que, qui / ke, ki | `ke`, `ki` | |

Rules that follow from this:

- **Correct answers:** "Starts with the /si/ sound" accepts *silla* and *cielo*.
  "Starts with the letters *si*" accepts only *silla*. Early stages use the
  *sound* version, and stage 6 uses the *spelling* version to teach the difference.
- **Distractors:** a wrong option must never share the sound key being tested. This
  prevents unfair questions (in 2014, *mani* could appear as a distractor for "mi").

## Mastery and review

- A step is **mastered** at ≥ 80 % correct over the last 10 tries, with tries in at
  least 2 sessions. A try is the first answer to an item (retries after a mistake don't
  count), and a session is one launch of the app.
- A step is finished once each of its games has been played to the end once, whatever
  the score, and that unlocks the next one. A mastered step shows a
  medal on its stone. The child can always replay earlier steps.
- **Review:** optional, from a button in the stickers album once a step is mastered.
  It plays 3 quick items from the mastered steps, taken from those steps' own games
  (tracing excluded). Steps with more mistakes among their last 10 tries come back more
  often. Review answers count towards the step they came from.
- When a child fails the same step repeatedly (3 sessions below 50 %), the app
  suggests an easier related activity and flags the step in the teacher view. It
  does not lock the child out.
