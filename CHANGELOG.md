# Changelog

All notable changes to the travel-planner engine are documented here. The format
follows Keep a Changelog; versions follow Semantic Versioning.

## [0.13.0] — 2026-08-23 — Publish-path content guard

Publishing a trip site has always had two paths: the default one encrypts the site
and checks the result before anything is pushed, and the opt-out one publishes it
in the clear. Only the first was checked. The path whose output is immediately
world-readable — no passphrase, anyone with the link — copied the rendered page
straight out with nothing looking at what was in it. That is the wrong way round,
and this release turns it round: the plaintext path now reads the page it is about
to publish and refuses if a traveller's passport details, or a need recorded for
someone who never filled in a profile of their own, have found their way into it.
It refuses equally when it cannot tell — an unanswerable question is treated as a
failure, not waved through. How far each of those two reaches is not the same, and
where the second one stops is written down below rather than left to be assumed.
Nothing changes for the encrypted path, which is still
the default and is still checked exactly as before.

### Added
- **The regression suite now runs on every push and pull request, and a green
  result means it actually ran (`.github/workflows/publish-guard.yml`,
  `scripts/test-publish-guard.sh`).** The suite that proves the publish guards
  work has existed for some time, but nothing ran it except a person remembering
  to. It now runs in CI. The part worth writing down is the second half of that
  sentence. The suite skips groups whose prerequisites are missing — real
  encryption needs Node, two groups need an authenticated GitHub CLI — and a
  skipped group used to count toward a pass exactly as a passing one did. Wiring
  the suite up naively would therefore have produced a green tick on a run where
  whole groups never executed, which is worse than no check at all, because it
  reads as proof. The CI run now provisions Node so the real-encryption groups
  genuinely run, treats any skip as a failure, and names the two GitHub-CLI groups
  it deliberately does not cover — so what the tick does and does not prove is
  written in the workflow file rather than assumed. Run by hand, the suite behaves
  exactly as it did before.
- **The decision, and its limits, are on the record
  (`reference/adr/ADR-008-publish-content-guard.md`).** A new architecture
  decision record covers why the existing pre-push check could not simply be
  called from one more place, which two alternatives were rejected and what killed
  each of them, and — the part most likely to be forgotten and then over-claimed —
  exactly what this guard catches and what it does not. It catches a value that
  reaches the page with the person's name stripped off, which is the case that
  matters most and the one a name-based check would miss entirely. It does not
  catch a value that was reworded on the way in. That limit is stated plainly
  rather than left to be discovered, because the guard is one layer of three and
  the other two are still doing work.

### Fixed
- **The plaintext publish path now checks what it is about to publish
  (`scripts/publish-trip-site.sh`, `scripts/test-publish-guard.sh`).** The check
  reads the page as a reader would see it and compares it against the two kinds of
  detail that must never be published: a traveller's passport country and
  validity, and any need recorded on behalf of a party member who has no profile
  of their own and so was never able to agree to it being written down. It keys on
  the traveller's own recorded values, never on words like "passport" — so a
  packing-list line telling everyone to bring theirs, and the visa and entry notes
  that belong on a published plan, are not flagged, and were never candidates to
  be. Stripping a person's name off a detail does not get it past the check, which
  is the case that motivated keying it this way. When something is found, the
  refusal names where it came from and never prints the value itself, so the check
  cannot leak what it exists to protect. If the record of who is travelling is
  missing, unreadable, out of date, or no longer in a shape the check recognises,
  the publish stops rather than proceeding on a guess; the remedy in every case is
  to publish encrypted, which is what the default already does. Nothing is pushed
  when the check refuses, and the refusal happens before the page is copied
  anywhere.

  **The check reads the whole page, not just the part you can see.** A first cut of
  this check read the page the way a browser paints it — the words a reader sees —
  while publishing copies the file itself. Those are not the same thing, and the
  gap between them was measured: a detail sitting in an HTML comment, in a page
  description, in the alt text of an image, in an inline script, in a style block,
  or in a data attribute went out unnoticed on seven of the eight places tried. Two
  of those are not even hidden — alt text and the page description are read aloud
  by screen readers and shown in every link preview. The check now reads both: what
  a reader sees, and what a reader can retrieve from the page source. What it
  deliberately ignores is the markup scaffolding itself — tag and attribute names —
  which is how it reads a page full of stylesheets and scripts without objecting to
  all of them.

  **It reads the travellers' own files, not only the summary built from them.** The
  summary of who is travelling is rebuilt from each traveller's own file whenever
  those change, so a passport recorded this morning may not be in it yet. The check
  used to read only the summary, and reported a trip as having nothing to protect
  when it plainly did. It now reads the travellers' files directly, and refuses to
  proceed at all when the summary is older than they are — an out-of-date answer is
  treated as no answer, which is the same rule the rest of this check already
  follows.

  **Two ways it used to refuse good pages, both fixed.** A party member recorded
  under an ordinary English name — Will — made every publish of that trip stop, for
  ever, with no way out that did not involve deleting the very record being
  protected. And because the check looked for a passport's country and expiry
  anywhere within twenty-five words of each other, an ordinary multi-day plan that
  mentioned, say, an Irish pub on each day under headings carrying the expiry year
  began refusing from the second day onward and never recovered. Both are corrected:
  a name made only of everyday words is no longer used as a search key, and the two
  halves of a passport must now appear in the same paragraph rather than merely
  nearby. A refusal that fires on correct pages is not a stricter check — it is one
  that gets switched off, which is worse than not having it. What each of these
  still does not catch is written down in the decision record rather than left to be
  discovered.

  **The half of the check covering party members is far wider than it was — and it
  is deliberately not complete.** Of the two
  kinds of detail this check protects, the second is a need recorded on behalf of
  someone who has no profile of their own. A first cut of it looked at two things
  and two things only: that person's name, and one particular line of their record.
  Everything else written about them was let through. That is backwards — the rule
  in the data model is that the whole entry for such a person is off limits, with
  nothing allowed out by default — and it mattered more than a missing line usually
  would, because the one line being looked for turned out to be the wrong one. It
  is the label used in a traveller's own hand-filled form, and the check was
  reading the summary built from those forms, which writes the same information
  differently. So on a real trip that half of the check could match nothing at all,
  while still reporting the page as clear. Three things are fixed together: every
  detail recorded about such a person is now checked rather than a chosen few; the
  marking that identifies them is read wherever it appears rather than only at the
  top of their entry, which matters because losing that top-line marking is a known
  mistake; and the check no longer looks for one particular label, because there is
  no agreed one to look for. Two related states now stop a publish instead of
  passing quietly: an entry whose marking has been removed while the details stayed
  behind, and a marking in the file that the check cannot tie to anything. The
  balance is kept the other way too — a need that a traveller stated about
  themselves and asked to have planned around is still allowed onto the page, as it
  always should have been.

  **Where that half stops, stated rather than left to be found.** It is wider, and
  it is not complete, and that was decided before this release shipped rather than
  discovered afterwards. Needs recorded for someone else are often very short and
  written in everyday words — "no stairs", "not in the afternoon", or simply the
  name of a category on the form. A check that works by looking for the recorded
  wording on the published page cannot use words like those as what it searches
  for, because it would then refuse every plan that happens to mention stairs or
  afternoons, on every attempt, with no way round it short of deleting the record
  being protected. A refusal like that does not make the check stricter; it makes
  it something people turn off. So a value made up entirely of everyday or
  form-vocabulary words is deliberately not used as a search term, and if such a
  value reaches the page it goes out unnoticed. A longer or more distinctive need
  is caught, and so is the person's name unless that too is an everyday word.

  There is a second reason, and it is about the records rather than the check:
  nothing in this repository shows what an entry for such a person actually looks
  like. Of forty-four worked examples across all the documentation, twelve show a
  person's entry and none of them shows one recorded this way. The check therefore
  reads whatever a line states instead of looking for an agreed layout — the right
  response to there being no agreed layout, and not the same thing as covering
  everything written about that person. Agreeing that layout, and marking on each
  detail directly whether it may be published, is a separate piece of work already
  planned; it is not something this check can settle on its own. None of this
  affects the rest: passport details are covered as described above, an
  undeterminable answer still stops the publish, and the encrypted path — the
  default — is untouched.

## [0.12.0] — 2026-08-22 — First-run experience

Four fixes aimed at the first hour with this repository, and at the release
process that publishes it. Someone who has just cloned the repo now finds the
directory their trips belong in, is told why it is empty, and gets a straight
answer from the one read-only command instead of being sent back to a directory
they are already standing in. The two documents they are most likely to read
back-to-back name that directory the same way. They can size roughly what running
the engine costs before committing to setup. Nothing about how a trip is planned
changes — this release is about arriving, not about planning.

The fourth fix is about this file. A release changelog used to be written after
the release had already merged and been tagged, as a separate commit straight to
`main` — which meant the entry never travelled inside the release it described,
and never passed the check that reads everything else. This entry is the first one
written the other way.

### Added
- **`trips/` is present on a fresh clone, with a signpost that explains it
  (`trips/README.md`, `.gitignore`).** The directory your trips live in used to
  exist only after you created a trip, so a new clone simply did not have it and
  nothing said where trips were meant to go. It now ships with a tracked README
  explaining what belongs there and why the directory looks empty. Trip data
  itself is still ignored and still never published — the signpost is the single
  tracked exception, and a CI invariant now holds both halves of that: the
  signpost stays tracked, and a trip file underneath it stays ignored.
- **The README gives an order of magnitude for what running the engine costs
  (`README.md`).** Planning a trip end to end drives a lot of model usage, and
  until now nothing said how much. There is now a stated magnitude for a first
  full plan and for the cheaper things you do repeatedly afterwards — enough to
  decide whether to start, before investing in setup. It is a magnitude, not a
  quote: actual cost moves with the model you point at it and with how large the
  trip is.
- **A written release procedure (`CONTRIBUTING.md`).** There was no document
  anywhere in the repo describing how a release is cut. There is now, and the part
  it exists to state is that the changelog entry belongs on the release branch,
  landing through the release pull request with everything else — not as a commit
  to `main` afterwards.
- **The branch-protection posture is on the record (`SECURITY.md`).** `main`
  allows its administrator to push directly, bypassing the pull-request
  requirement and every required check in one step. That was true and undocumented;
  it is now written down as a decision, with the argument on both sides, the one
  time it has been used, and the condition that should cause it to be revisited.
  The mitigation below is honest about its limit: the checks now run on a direct
  push, but running is not blocking, so what this buys is detection after the
  fact rather than prevention.

### Changed
- **One notation for the trip directory, everywhere (`CLAUDE.md`,
  `templates/traveler-intake.template.md`, `templates/trip-context.template.md`,
  `agents/00-enrichment.md`, `agents/destination-ideation.md`,
  `reference/data-model.md`, `examples/two-origin-demo/trip-context.md`).** The
  documents and the templates they point at had drifted into different ways of
  writing the same placeholder path, so a reader moving between them had to work
  out that two spellings meant one directory. Twenty-eight occurrences are now a
  single convention, and the convention is stated once rather than left to be
  inferred.

### Fixed
- **`list` works on a plain clone, and says what is actually wrong
  (`scripts/publish-trip-site.sh`).** Listing your trips is a read-only scan of a
  local directory, but it used to require GitHub authentication before it would
  run — so a new user was stopped by a login prompt for a command that never
  needed one. It also reported a missing `trips/` directory as though you were
  running from the wrong place, which sent people to fix a working directory that
  was already correct. Both are fixed: no authentication for the read-only path,
  and a missing directory is now reported as a missing directory.
- **The personal-data gate covers commits that reach `main` without a pull
  request (`.github/workflows/depersonalization.yml`).** The gate that keeps
  personal email addresses and OS home paths out of this public repository ran
  only on pull requests, so anything pushed straight to `main` was never scanned —
  which is exactly how release changelog entries used to arrive. It now runs on
  pushes to `main` as well. Adding that trigger alone would have produced the
  worse outcome of a check that runs, reports clean, and reads nothing, because a
  push carries no pull-request context to derive a range from; the gate now works
  out its range from whichever event started it, says in its own output which
  commits and how many files it read, and fails rather than reporting clean if it
  cannot work that range out at all.

## [0.11.0] — 2026-08-22 — Satisfaction metric refinements

Three refinements to the satisfaction layer, each closing a place where the
coverage view described something other than the trip as it is actually lived. A
need was graded on days its traveller had not yet arrived. A want you have every
morning could only be recorded as a want you have once. And a day's anchor meals
could all drift into the same grab-and-go format with nothing in the metrics
noticing. Nothing new is asked of a traveller at intake beyond one optional line
per desire. The first two changes are invisible on a trip where everyone shares
the group's window and nobody holds a daily want; the third changes what the food
agent offers for the anchor role on any trip.

### Added
- **A want you have every day, recorded as one
  (`templates/traveler-intake.template.md`, `agents/00-enrichment.md`,
  `agents/03-scheduling.md`, `agents/05-hub-planner.md`,
  `agents/06-validator.md`, `reference/data-model.md`).** A desire can now carry
  an optional `Recurrence:` of `one-off` or `daily` — a morning coffee before the
  day starts, a swim, an evening walk. It is a separate question from how much
  the want matters: a daily want may be an anchor, a wish or a nice-to-have, and
  neither label implies the other. Only an explicit `daily` counts; a blank or
  em-dashed line is a one-off, and the wording of a desire is never read as
  evidence of cadence. A daily want becomes a standing slot on every day that
  traveller is present — their own window, not the trip's — placed in the time
  block the desire names, and no slot is placed on a day they are away. Three
  bounds hold: it is never the day's anchor whatever its tier, it never exempts a
  venue from the two-appearance cap (so a week-long ritual is a week of that kind
  of stop, not seven visits to one address), and it yields to needs like any
  other desire. It is reported per day and counts as covered only when every
  present day carries it; a partial run is not covered, with the missed days
  named.
- **Convenience formats are capped as anchor meals, not as entries
  (`agents/02-food.md`, `agents/05-hub-planner.md`, `reference/data-model.md`,
  `CLAUDE.md`).** Grab-and-go, konbini and counter, standing-counter,
  market-stall and the other minimal-commitment formats stay welcome without
  limit as grazing, snack and casual entries — a thin casual section was always
  the anti-pattern here. What is capped is how many of them are offered for the
  **anchor** role: at most two nominations per category across the list, the
  second one intentional rather than a default. The cap is about commitment and
  format, never about effort — a walk-in counter can be a legitimate anchor and
  nothing here pushes toward reservations. Each convenience entry now states its
  anchor eligibility, the hub honors that marker without recomputing it, and a
  new anti-pattern names the drift the rule exists to catch: anchors accumulating
  as convenience formats because they are easy, cheap and always open, until the
  trip's anchor meals are three konbini runs and a standing counter.
- **A sixth coverage dimension — meal-variety concentration
  (`reference/data-model.md`, `agents/05-hub-planner.md`,
  `agents/06-validator.md`, `CLAUDE.md`).** The satisfaction view now names six
  dimensions rather than five. The new one is a per-day balance signal for
  whether a day's meals concentrate in a single convenience format instead of
  ranging across formats. It follows the same seam the rest-recovery signal
  already follows: the per-category anchor cap above is the hard selection-time
  rule, and this is the softer per-day reading of whether the resulting spread is
  healthy beyond it. Like every balance signal it is named and tracked with its
  value left to design — nothing in the satisfaction layer scores or optimizes
  yet.

### Fixed
- **A need is graded only on the days its traveller is at the destination
  (`reference/data-model.md`, `agents/06-validator.md`,
  `agents/05-hub-planner.md`, `agents/03-scheduling.md`).** A need's applicable
  days are now the days its governing constraint governs **intersected with**
  that traveller's own at-destination days, so a mobility limit is no longer
  failed on a day its traveller had not yet landed. Absence is the only presence
  failure that removes a verdict: a traveller who is at the destination but
  **unavailable** is still graded, because they are here on a parallel track and
  their needs bound that track exactly as they bound the main one. Two readings
  are named separately so each consumer cites the one its own job needs —
  placement reads presence (there **and** free), grading reads the window alone —
  and both are defined once in `reference/data-model.md`, with the scheduler, hub
  and validator citing rather than re-deriving them. The trim is always shown
  with its reason (`D2–D4 (at destination D2–D4)`) so a reader can tell a
  presence trim from a constraint subset; a silently narrowed grade is the same
  failure as an unnamed absence. Where a window is only assumed, every day is
  still graded and the *(assumed)* marking travels with it — a hard gate is never
  dropped on a guess — and a party member recorded on needs alone, who carries no
  presence data at all, is graded on every day the constraint admits rather than
  none.

## [0.10.0] — 2026-08-21 — Per-traveler facet depth

A party who leave from different places, or arrive on different days, is now
modelled as the individual people they are rather than as one representative
traveller. Five capabilities land together because each is unusable alone: a
per-traveller derivation of available time, a trip context that can hold more
than one departure origin, a scheduler and transport brief that read presence, a
familiarity signal that calibrates recommendation depth, and a home for a party
member's needs that cannot be published. The single-origin case is unchanged
throughout — the trip-level blocks still render exactly as before.

### Added
- **Per-traveller effective planning days
  (`templates/trip-context.template.md`).** A `[DERIVED]` block sits alongside
  the trip-level one, deriving each traveller's own window, timezone delta and
  partial days from their own arrival and departure rather than the group's.
  `Arrive / leave` and `Leaving from` are each classified independently as
  stated-different, stated-same-as-group, or unanswered — so a window that is
  assumed rather than asserted is marked as assumed everywhere it is used.
  Classification follows what the traveller bound their window to, never numeric
  coincidence: dates that happen to match the group's stay pinned when the group
  rebooks.
- **Additional departure origins (`templates/trip-context.template.md`).** A trip
  can carry more than one origin, each with its own legs and its own list of who
  departs on them. The section's absence is what means single-origin, so existing
  trips are untouched. Leg field labels are identical across the anchor and
  additional origins, so a consumer parses them with one rule.
- **Presence in scheduling and transport (`agents/03-scheduling.md`,
  `agents/04-transport.md`).** Whole-group anchors prefer days on which everyone
  is present; when a booked event, a hard closure or an immovable need forces one
  outside a traveller's window, the day names who is absent and which of those
  reasons forced it. Absent (not at the destination) is kept distinct from
  unavailable (present but committed elsewhere) — only the latter has a parallel
  track worth planning. Transport derives one arrival-day stream per origin.
- **Prior-visit familiarity (`templates/traveler-intake.template.md`,
  `agents/01-activities.md`, `agents/02-food.md`).** An optional, unstarred field
  on a closed scale — never / once / a few times / know it well — calibrates how
  deep recommendations pitch. The starred quick-pass stays at ten fields.
- **A home for a party member's needs (`agents/00-enrichment.md`).** Where
  someone in the party will not file a profile of their own, the organiser can
  record their needs through the existing operator-provided path, marked as
  second-hand. They reach the planner exactly once, attributed to the right
  person, and are superseded rather than duplicated if that person later files a
  profile. The intake form is unchanged: nothing new is asked.

### Changed
- **Third-party information is barred from published output
  (`agents/00-enrichment.md`, `agents/06-validator.md`,
  `reference/data-model.md`).** A need recorded on someone else's behalf shapes
  the plan — pacing, rest, walking distances, venue choice — but never appears in
  any publish-bound artifact, in attributed or anonymised form; in a small named
  party, removing the name does not remove the identification. Two escalation
  paths that would have carried such a value into the published trip file are
  closed by carve-out, so first-party escalation continues to work unchanged. The
  validator treats any leak as Critical, with no warning tier, no waiver, and an
  undetermined result failing closed. Lifecycle facets are bound to first-party
  entries by a single class-wide rule rather than a list of fields, so facets
  added by a later release inherit the bound automatically.
- **Cold-assistant guidance names the third fallback branch (`CLAUDE.md`).** An
  assistant filling the form on someone's behalf is told where a profile-less
  party member's needs belong and that they are never published — the gap that
  produced this work in the first place.

### Decisions
- **ADR-006 — third-party data capture** is ratified. Needs recorded on behalf of
  a party member without a profile may be captured on a non-publishable surface;
  identity data about that person may not be captured at all. See
  `reference/adr/ADR-006-third-party-data-capture.md`.

## [0.9.1] — 2026-08-20 — Intake form: corrective

Three corrections to the traveler intake form that 0.8.0 shipped, and two
changelog headings that were dated a day early. None of the form fixes changes
what is asked for or withdraws a claim — each closes a place where the form left
the reader to guess: **whose** passport belongs on the passport line, whether an
unbooked flight makes the arrival question moot, and which two of the starred
fields actually ask you to think.

### Fixed
- **The `Passport` line covers exactly one person
  (`templates/traveler-intake.template.md`).** The field now reads **yours alone
  — not your party's**, and the section note names where a travelling companion's
  passport belongs: their own copy of this form, saved as
  `trips/[destination-year]/travelers/<their-name>.md`, on their own line there.
  If that person will not have a profile at all, the form now says so plainly —
  their passport is not recorded anywhere — rather than leaving the reader to
  assume it was captured somewhere. The embedded interview carries the same rule,
  and needed an explicit local carve-out from its own **keep their words** rule to
  do it: narrowing a party-shaped answer — *"two of us are Canadian, one is
  Australian"* — genuinely changes the meaning, so without the carve-out a
  compliant assistant would record the party-shaped answer verbatim.
- **`Arrive / leave` is no longer gated on group flights that may not exist
  (`templates/traveler-intake.template.md`).** The field was prefixed *only if
  you're not on the group's flights*, which made it unanswerable before anything
  was booked — the ordinary state of things at intake. It now asks for this
  traveler's own arrival and departure at any booking state, and *"I'm on whatever
  the group books"* is a stated answer rather than something inferred from an
  empty field. The interview says the same and adds the rule that makes it hold:
  an empty field means **unknown**, never *no constraints*.
- **The starred quick pass says on the line where the thinking is
  (`templates/traveler-intake.template.md`).** Eight of the ten starred fields are
  a pick-from-the-list or a short phrase; two — a need and a desire — ask you to
  think, and nothing said which. Both now carry **one line is a complete first
  pass** on the line itself, each with a start-here phrasing and a sharpen-later
  phrasing, and the desire field states that an archetype from the menu above is a
  complete answer on its own. `Comfort range` gained its option set on the line —
  *keep it lean / mid-range / spend freely* — so the one starred money question is
  answerable by recognition like the rest. Nothing was retracted here; a locator
  was added.
- **`[0.8.0]` is dated to the day it was published.** The heading ran a day early
  and now reads `2026-08-19`.
- **`[0.1.0]` is dated to the day it was published.** The same defect, further
  back; the heading now reads `2026-07-01`.

### Notes
- The two heading corrections are one defect, not two: a date taken from the UTC
  timestamp rather than from the publish date as it read where the release was
  cut. A release published in the evening Central time falls on the next day in
  UTC, so the UTC reading runs a day ahead. Dates in this file are the GitHub
  Release publish date rendered in Central — this entry's own heading included.
- The **2–3 minutes** on the starred first pass is unchanged, and is an estimate
  rather than a measurement — nothing in the repo times a real fill.

## [0.9.0] — 2026-08-20 — Nightlife agent

Going out at night now has **an owner**. Cocktail bars, clubs and live-music
rooms used to fall between the Activities evening section and the Food agent, so
nightlife came out inconsistently — sometimes planned, sometimes missing, and
filed under whichever agent happened to reach for it. A dedicated nightlife agent
now researches those venues, the hub places them into the evening, and the
validator checks the nights a traveler actually asked for.

### Added
- **Nightlife research agent (`agents/07-nightlife.md`).** Owns going-out venues
  — cocktail bars, clubs, live music, late-night rooms — by the primary-draw
  test: what is the reason you go? It produces `outputs/nightlife-list.md` and
  deliberately does not schedule. Night-fit is captured in three day-independent
  fields — `Nights & hours`, `Night type`, and **`Next-morning cost`** — so a
  late night is weighed against the morning after rather than judged alone.
- **A three-depth desire gate.** The agent runs FULL (a full menu, minimum 12
  entries), LIGHT (minimum 5, weighted to low-key and non-drinking options), or
  SKIP, depending on how much nightlife the party actually wants. A SKIP still
  writes a short gate-result note, so a missing list never reads ambiguously as
  "nobody wanted it" *or* "the agent never ran".
- **A nightlife block in the day template (`agents/05-hub-planner.md`).** The
  site layout spec already described how a night card should render; nothing
  emitted one for it. Each day now carries a Nightlife block — or an explicit
  no-nightlife line with its reason, never both and never neither.
- **Per-night coverage check (`agents/06-validator.md`).** On nights a present
  traveler wants nightlife, the validator reports whether the night is covered.
  Warning and Note only, with no Critical tier, so nightlife is optimized for
  and never forced onto a trip as a required anchor.

### Changed
- **A three-way going-out boundary (`agents/01-activities.md`,
  `agents/02-food.md`).** Activities, Food and Nightlife now state the same
  partition reciprocally. If the reason to go is the drinking or the room, it is
  Nightlife; if it is the eating, it is Food; if it is a sight, a view, or a
  scheduled event that happens to fall after dark, it is Activities. A venue that
  plausibly fits two is claimed by its primary draw and cross-referenced by the
  other, never listed twice.
- **Nightlife wired into the pipeline (`CLAUDE.md`, `README.md`).** The nightlife
  agent is dispatched in the research phase after Food and before scheduling,
  `outputs/nightlife-list.md` becomes a required hub input, and night venues
  carry the Category and Reservation wiring — for a nightlife venue the
  reservation slot holds the door policy: cover, guest list, dress code, or
  walk-in — so every night card resolves to a map link like every other card.
- **First cross-spoke venue dedup rule.** When two agents propose the same place,
  one rule now decides which of them keeps it, so a venue stops appearing twice
  in one plan under two different headings.

### Notes
- The **natural-occasion** path — nightlife proposed because the trip contains a
  weekend night, a birthday or a last night, rather than because someone asked
  for it — is documented but **not yet reachable**. Nightlife driven by a stated
  desire works throughout; the occasion path is a named follow-up.
- The Tokyo worked example under `examples/` still splits its evening venues the
  old way and now disagrees with the boundary this release ships. The example is
  unchanged here and is being corrected separately.
- On a night where the group splits into parallel tracks, the day carries one
  Nightlife block rather than one per track. Split-night nightlife is a named
  follow-up.

## [0.8.0] — 2026-08-19 — Self-guiding traveler intake

The traveler profile now **guides the person filling it in** — by itself, or through
any assistant they hand it to — and captures the whole journey rather than just the
in-destination experience. A traveler arriving at a blank form gets a two-to-three
minute starred first pass, recognition menus instead of open prompts, and an embedded
interview that travels to any model family. What they enter is carried all the way
through to the derived per-traveler model.

### Added
- **Embedded portable interview (`templates/traveler-intake.template.md`).** A
  model-agnostic guide below a clear end-of-profile delimiter. Upload the whole file
  to any assistant, say "help me fill this out", and get a section-by-section
  interview — one section at a time, choices offered, "skip" always valid, nothing
  invented — followed by one clean filled profile with the guide stripped. Harmless
  to a hand-filler who leaves it in place.
- **Cold-start essentials.** Ten starred fields, one per qualifying section, each
  answerable by recognition or a short phrase. The star means *start here*, never
  *required* — a blank profile has always been an operator fallback in this engine,
  not a failure.
- **Recognition menus for Interests and Desires.** A tick-what-sparks interest
  palette and a fifteen-item desire-archetype palette, so the two most open prompts
  in the form no longer start from a blank page. The archetype wording doubles as a
  theme-tag vocabulary, which sharpens desire-overlap matching.
- **Take-off→landing coverage.** New `Getting there & back` section (`Leaving from`,
  `Arrive / leave`, `Journey comfort`, `Passport`) and `Where you stay` pair
  (`Lodging style`, `Rooming`), plus `Party` and `Special occasion?`. Each links to
  its trip-level home — Logistics, Accommodation, Group — and refines it rather than
  restating it.
- **Fail-closed passport non-publication check (`agents/06-validator.md`).** Passport
  is captured as issuing country and validity month only, never a number. The
  validator now fails the trip if either reaches the published render path, and an
  undetermined result is a failure rather than a clean pass — so the field ships with
  its guard rather than on a documented promise.

### Changed
- **Lifecycle facets: six → nine (`reference/data-model.md`).** The facet table gains
  Party, Journey & origin, and Accommodation, each with its link target; both prose
  sites that enumerate the facets now agree with the table.
- **Enrichment carry-through (`agents/00-enrichment.md`).** All nine facets carried
  with every field label quoted, `Special occasion?` carried explicitly as a
  non-facet, and the desire parse anchored on its labels so the hub and validator
  `Priority tier` columns have something to bind to.
- **Desire label `Priority:` → `Priority tier:` (`templates/traveler-intake.template.md`).**
  Aligns the form to the label the data model, hub planner, and validator already use.

### Fixed
- **Non-conformant need-category values.** The data model's worked examples used
  `Required rest` and `Heat tolerance`, neither a member of its own enum; corrected
  to `Rest` and `Heat`. The enrichment agent's category vocabulary was corrected the
  same way. The template's enum was already correct and is unchanged.

### Notes
- Six of the eighteen existing facet labels were unquoted in the enrichment
  carry-through block while that block asserted a parse-by-the-labels contract;
  repaired in passing since the block was being rewritten.
- The matching facet enumeration in `CLAUDE.md` is carried separately — see the
  release PR.

## [0.7.0] — 2026-07-26 — Faithful site rendering

The published site now renders the plan **faithfully and legibly**: every event
carries a standard, validator-gated map link; days that split the group show as
parallel labeled tracks instead of duplicate pages; day headers read as editorial
travel voice rather than AI meta-notes; and the full plan — including split tracks
— round-trips into the site with nothing silently dropped.

### Added
- **Standard map-link component + location invariant (`reference/site-layout-spec.md`).**
  One `.map-link` treatment across every card tier, sourced from
  `outputs/links-reference.md` — one venue, one URL, everywhere it appears. Every
  event card carries exactly one; transit connectors carry none.
- **Location-invariant validator gate (`agents/06-validator.md`).** A new audit —
  every itinerary event must resolve to a map (or official-site fallback) link, and
  a missing link is Critical, so a trip with a missing link fails validation.
- **Day-header content contract (`reference/site-layout-spec.md`).** Day headers are
  specified as {day theme or anchor place} + {one editorial tagline}, with a ban
  list for meta/AI phrasing, voice exemplars, and a worked before/after. The hub's
  day-header output is bound to the contract.
- **First-class split-day component (`reference/site-layout-spec.md`).** A day that
  splits the group renders as N≥2 parallel labeled track columns, each with its own
  map and named split/rejoin endpoints, from the hub's Parallel Track blocks —
  replacing the old duplicate-full-day-page treatment.
- **Plan/site single-sourcing & round-trip fidelity (spec §9).** The site is
  single-sourced from `outputs/`; every plan element resolves to a rendered
  component or a named exclusion (surjective plan→site, nothing silently dropped),
  checked at build and at every update.
- **ADR-005 — Location invariant.** Records the cross-cutting decision that the
  split-day and unification slices build on.

### Notes
- A spec/contract release — the deliverables are the site-layout spec, the
  validator, and the hub contracts; a site is generated per trip from them.
- Follow-ups noted for a later release: re-synthesizing the Tokyo worked example out
  of its legacy duplicate-page form, and wiring the day-template nightlife block
  that §9's round-trip mapping references.

## [0.6.0] — 2026-07-01 — Destination ideation

The front of IDEATION: help a group decide *where* to go before any destination
is fixed. From each traveler's individual destination leanings, the planner now
derives one ranked group shortlist to choose from — so a trip can start at "we
don't know where to go yet" instead of assuming a destination is already picked.

### Added
- **Destination Ideation agent (`agents/destination-ideation.md`)** — reads every
  traveler's destination leanings (`Would love` / `Rather skip` / `Trip vibe`) and
  writes `outputs/destination-shortlist.md`, a ranked group shortlist. Ranking is
  **equity-weighted coverage**: love-count adjusted so every traveler is
  represented near the top, `Rather skip` as a hard veto, and `Trip vibe` as the
  rationale. It recommends only — the group decides, nothing auto-picks — and hands
  off to DISCOVERY once a destination is chosen.
- **Worked example (`examples/ideation-demo/`)** — a four-traveler run showing the
  ranked shortlist, an applied veto, and the equity case (a lone-lover destination
  kept that a popularity-only ranking would drop).

### Notes
- Realizes the data model's forward-hook (a): the per-traveler files still only
  *capture* leanings; the aggregation lives in the new agent, never in an
  individual file. Enrichment and the data model were updated to point at the
  now-realized hook.
- Ships the destination-ideation seed (group destination recommendation). A fuller
  ideation flow (group shortlist → group decision → DISCOVERY handoff) remains
  documented future growth.

## [0.5.0] — 2026-07-01 — Publish-flow privacy & lifecycle

Rounds out the private-publish flow (v0.1.0) with the privacy and lifecycle
controls a real "site manager" needs: hide the destination in the repo name, see
every published site at a glance, and take a site back down.

### Added
- **Opaque repo names (`publish --opaque`)** — name the per-trip repo with a random
  token (e.g. `trip-a1b2c3d4e5`) instead of the readable `[destination]-[year]-trip`,
  so the destination and year no longer show on your public profile. The name is
  saved to `.publish-slug`, so `update`/`rotate`/`unpublish` resolve the same repo.
  Readable names stay the default (opt in per publish).
- **`list` — published-site inventory (read-only)** — one command shows every trip
  under `trips/`: its repo, live URL (or "not published"), last-published vs
  last-edited, and a **stale** flag when your local build is newer than what's
  deployed. Never writes, encrypts, or pushes.
- **`unpublish` — takedown** — take a published site down: by default it deletes the
  per-trip repo (removing the site *and* the destination/year in its name), or
  `--disable-pages-only` keeps the repo and just takes the site offline. It confirms
  before an irreversible delete, is idempotent (a no-op if already gone), and is
  honest that content may linger in third-party caches after takedown.

### Notes
- Deleting a repo needs the `delete_repo` gh scope (`gh auth refresh -h github.com -s delete_repo`);
  `unpublish` says so and offers `--disable-pages-only` as the no-extra-scope path.
- The privacy model is unchanged: published bytes are world-fetchable ciphertext
  (secret-gated by passphrase + 600k-KDF, not access-controlled). `--opaque` closes
  the repo-name metadata leak; commit timestamps still reveal publish activity.
- Regression tests extended (`test-publish-guard.sh` groups H/I/J) covering opaque
  naming, the inventory helpers, and the takedown safety gates.

## [0.4.0] — 2026-07-01 — Orchestration: equity-aware planning & replanning

The group planner that runs all three optimization engines and reconciles them
into one itinerary — and, when plans fall through or someone's wishes change,
rebuilds it fairly instead of grabbing any replacement. Built on v0.3.0's engines;
this is the layer that makes them work together for the whole group.

### Added
- **Equity-aware planning** — the planner runs the routing, experience, and
  fair-coverage engines together and reconciles where they disagree (a tight route
  vs. protecting one person's must-see vs. a needed rest day) into a single plan —
  everyone's needs applied first as hard limits, plus a per-traveler view of who is
  served and where the trip is lopsided. When the objectives collide, the tradeoff
  is named and shown, never silently dropped.
- **Equity-aware replanning ("who lost what")** — when a booking falls through, or
  a traveler edits their profile (a new must-see, a dropped wish), the planner works
  out who lost the most, rebuilds toward them first, and regroups the scattered gaps
  into one coherent thread rather than unrelated swaps — keeping everyone's needs
  intact through the recovery.
- **Side-bars / group splits** — when someone wants their own time, or interests
  diverge enough, the planner proposes single / small-group / full-group side-bars
  instead of dragging everyone along or leaving anyone out. The default stays one
  shared plan, and any moment a traveler marks whole-group is never split off.

### Notes
- The *structure* ships here; the *scoring* is deliberately deferred — how the three
  objectives rank, how "hardest-hit" and "enough divergence" are measured, and how
  gaps cluster into a theme are left to a later design pass. Nothing scores yet; the
  planner reasons with the structure and shows its work.
- Every recovery and every side-bar still honors each traveler's needs as hard
  floors — a split or a rebuild never becomes a way to slip a need violation through.

## [0.3.0] — 2026-07-01 — Optimization engines

The first engines that actually *optimize* a trip against the satisfaction
substrate. Each one works a single objective and surfaces its read for the group
planner to weigh — built on v0.2.0; the planner that runs all three and reconciles
them across the whole group comes next.

### Added
- **Geographic routing** — treats travel between stops as a real, minimizable
  cost: it orders each day so the group spends less time in transit and more time
  at the places, surfaces that cost so one plan can be compared against another,
  and spends any freed time on a single deliberate use. It never routes a traveler
  through a must-avoid (a heat window, a mobility limit).
- **Experience balance** — shapes how the trip *feels* across the days, not just
  how tiring it is: it spreads new and exciting things out instead of front-loading
  them, and avoids stacking too many big days back-to-back with no breather.
  Required rest (a real need) is always protected.
- **Fair coverage** — makes sure the plan serves everyone, not just the majority:
  a want several travelers share is an easy win, while a want only one person holds
  is protected so no one is quietly left out. It works on wants only — must-haves
  are always met.

### Notes
- These engines *surface* their objective; the group planner that runs all three
  and reconciles them (efficient routing vs. everyone's coverage vs. the trip's
  arc) is the next release — equity-aware planning.
- Every engine optimizes *within* each traveler's hard needs. Needs are floors,
  never traded away for a better score.

## [0.2.0] — 2026-06-28 — Satisfaction substrate

A structured foundation for understanding what each traveler wants and tracking
what's settled — so trips can be planned for the whole group and picked up from
any stage. Foundation only: nothing optimizes yet.

### Added
- **Per-traveler profiles** — each traveler gets their own intake form (fill it
  yourself, or have an agent walk you through it): needs (must-haves), desires
  (anchor / wish / nice-to-have), plus destination leanings, dates, budget,
  travel style, interests, and people-dynamics. All optional — fill what fits
  your trip's stage.
- **Per-event status** (`planned` / `locked` / `firmed` / `option`) — re-running
  the planner refines only what's still open and leaves booked or settled
  choices alone.
- **Satisfaction metrics** — defined dimensions: needs-compliance (pass/fail),
  desire-coverage, and balance signals for equity, experience, and rest.
- **Data-model document** — the canonical architecture for the satisfaction
  layer (storage homes, reconciliation, lifecycle).

### Changed
- Iteration and resequencing touch only `planned` events; `locked` / `firmed`
  events are preserved unless you name them, and the validator flags any
  unintended change.

### Notes
- Per-traveler data stays in private, git-ignored working files and is never
  published.
- This release is substrate — nothing optimizes yet. The optimization engines,
  equity-aware (re)planning, group side-bars, and destination ideation build on
  it next.

## [0.1.0] — 2026-07-01 — Private-by-default trip sites

- Published trip sites are encrypted client-side and private by default — only
  ciphertext is pushed to the public per-trip repo, gated by a passphrase, so a
  trip's details are never world-readable.
- A fail-closed pre-push guard refuses to publish anything but verified
  ciphertext.
