# Data-Architecture Demo — the migrated artifact shape, end to end

A minimal worked example for `reference/data-architecture.md`. It exists to carry a
**versioned instance of every artifact class that can have one**, so the schema
gate's coverage declaration has something real to point at.

Not a real trip. Placeholder people, a placeholder destination, illustrative dates,
no real bookings, and no external links.

**Single-origin**, and deliberately so: `examples/two-origin-demo/` is the fixture
where the window and origin axes diverge, and this one is the degenerate case where
they cannot. Companion to `examples/ideation-demo/`, which is minimal in the same
way.

## The trip

- Destination: Porto, Portugal (placeholder)
- Window: Thu May 14 – Sun May 17, 2026 — days of week verified
- Party: three travellers — Alex and Robin, who each filed a profile, and Sam, who did
  not and whose needs are operator-provided. One origin, one booking.
- Mode: `ITERATION` — one synthesis has run and one patch has been applied, which is
  what gives the fixture both a current `final-itinerary.md` and a frozen
  `final-itinerary-v1.md` sibling

## What each file is here to demonstrate

| File | Class | Tier | What it exercises |
|---|---|---|---|
| `trip-context.md` | C1 | 2 | block-owned writer; the single-origin degenerate case |
| `trip-log.md` | C2 | 2 | `accumulate-append`; why `generated:` is optional on C1–C3 |
| `travelers/alex.md` · `travelers/robin.md` | C3 | 1 | the **template's own section and field surface**, which is what `agents/00-enrichment.md` parses; needs vs desires; tier and recurrence orthogonal; `Applies to:` links rather than copies; the traveller's name in the **title line**, never in frontmatter. Two files for three roster members — Sam's absence is the operator-fallback branch |
| `outputs/activities-list.md` | C5 | 2 | migrated shape, and the fixture's **marker-transition witness** — two dated sections, `unminted` resolving to `ven-<token>` across a pass |
| `outputs/nightlife-list.md` | C7 | 1 | the desire gate resolving *open*; alternatives varying on two axes |
| `outputs/scheduling-framework.md` | C8 | 2 | a spoke emitting **its own two** signals — routing and experience — and not synthesizing |
| `outputs/transport-brief.md` | C9 | 2 | migrated shape; the secondary transit table that carries **no** entry marker, by § 4.5's decided case |
| `outputs/links-reference.md` | C10 | 2 | rebuilt before the itinerary, with `venue-matrix.md` |
| `outputs/venue-matrix.md` | C11 | 1 | the dedup cap, the anchor/alternative rule it is **not** the same as, and the emitter's full three-role vocabulary `A` / `Alt` / `B` |
| `outputs/traveler-model.md` | C12 | 1 | `[DERIVED]` projection; the desire-overlap signal |
| `outputs/event-status.md` | C13 | 1 | all four status values; opaque day-independent Event ID; derived needs-booking |
| `outputs/satisfaction-metrics.md` | C14 | 1 | the one declared non-scalar (`writer: [hub, validator]`); section ownership; the six dimensions with their types |
| `outputs/final-itinerary.md` | C15 | 2 | `versioned`, current pass; the hub's own prose day shape, carrying **no** ID or key column — the one-way join § 4.5 records as a cost |
| `outputs/final-itinerary-v1.md` | C16 | 1 | the frozen sibling as its **own class**, `publish: internal` where C15 is `bound` |
| `outputs/validation-report.md` | C17 | 1 | the one per-class field, `critical-count`, agreeing with the body; the validator's own sixteen sections and its three-value severity scale; a check that cannot run **declared**, never passed |
| `outputs/rooftop-sunset-bars.md` | C18 | 2 | the residual class, resolved by longest-literal-pattern-wins |

## Depth

**This fixture is deliberately uneven, on a declared rule rather than by accident.**
Reproducing a full worked example for nineteen classes would put a second copy of
`examples/tokyo-2026/` in the repository, and a second copy is a second thing to
keep true.

- **Tier 1 — classes with no tracked instance anywhere before this fixture.** These
  get enough content to **exercise the class's own rule**, because nothing else in
  the repository does: the status enum and its derived needs-booking column, the six
  metric dimensions with their fixed types, the dedup cap distinguished from the
  anchor/alternative rule, the desire-overlap signal, `critical-count` agreeing with
  the findings it counts.
- **Tier 2 — classes whose only other tracked instance is inside the frozen
  `examples/tokyo-2026/` tree.** These get the **migrated-shape minimum**: correct
  frontmatter, plus the least body that keeps this fixture internally consistent.
  Per-venue research detail, addresses, opening hours, booking windows and external
  links are **not** reproduced — **except the one case the least-body clause above
  already requires**: a venue's street address is carried where the five-rung identity
  procedure needs it as **rung-2** evidence, because a merge whose warrant is missing is
  one `scripts/test-artifact-schema.sh` group **VI** grades as unwarranted, and its
  must-fire arm strips exactly those lines to prove it can. Nothing else on that list is
  exempt, and the exemption is the evidence rung 2 reads rather than location detail
  generally. `examples/tokyo-2026/` is the worked example for content, and this one is
  the worked example for shape.

**Depth governs content, not the writer's declared section set.** Tier 2 is a licence
to leave a section thin; it is never a licence to leave it out. A file whose section
names do not match the ones its agent prompt declares is not a shallow instance of the
class — it is a different shape, and shape is the one thing this fixture exists to
show. So every file below carries its writer's own sections, under its writer's own
names, with a stated *not exercised* where this fixture has no fact to put in one.
`outputs/scheduling-framework.md` and `outputs/transport-brief.md` each carry their
ten; `outputs/validation-report.md` carries its sixteen.

**A check or a field that cannot be exercised here is declared, never passed.** This
example ships no external URLs, no opening hours, no prices, no real bookings and a
placeholder destination. Several validator checks therefore have no input. Reporting
those as passes is how the earlier version of this fixture came to certify a plan that
placed no meal on any day while omitting the one check that would have caught it — so
the rule is stated here as a fixture rule rather than left to each file.

### What is absent, and why

Three classes have **no instance here**, each for its own reason. Absence is
declared rather than left to be inferred from a missing file.

- **C6 `outputs/food-list.md` — absent on purpose.** `scripts/test-artifact-schema.sh`
  uses `reference/schemas/food-list.md` as the workhorse whose **coverage
  declaration** it mutates, in four must-fire arms (`CTL-S5`, `CTL-S6`, `CTL-S7`,
  `CTL-S7b`). Each of those arms rewrites that schema's `no-witness-because:` line;
  if the line were not there the rewrite would be a no-op and the arm would stop
  testing what it names. Supplying a migrated food-list here would make C6's stated
  reason false and invite exactly that flip, so the fixture leaves the class alone
  and C6 keeps its `no-witness-because:`. **The coupling is fail-safe, not silent** —
  a flip makes those four arms go red rather than quietly pass — but it is a coupling
  between the corpus and the suite, and it is recorded here so the next author meets
  it before tripping it. **Where this fixture's food venues live instead:** the plan
  places one anchor meal on each of its four days, and the research for the three new
  ones sits in the second dated section of `outputs/activities-list.md` rather than in
  the class that would normally hold it. That is a property of the fixture and not of
  the engine, and both files say so.
- **C19 `outputs/<destination>-travel-site.html` — cannot have a tracked instance.**
  `reference/site-layout-spec.md` declares the site source *"Source file (plaintext,
  stays local, git-ignored)"*. A tracked witness would contradict the spec that
  governs the artifact. C19's `no-witness-because:` records that as a **decided
  disposition**, not a pending gap.
- **C4 `outputs/destination-shortlist.md` — already witnessed elsewhere.**
  `examples/ideation-demo/` holds the migrated instance, and a shortlist belongs to
  `IDEATION`, before a destination is chosen. This trip has one, so a shortlist here
  would contradict the fixture's own mode.

## Internal consistency (F1–F9)

**These are the fixture's real acceptance criteria, and no CI check can reach them.**
The schema gate validates frontmatter; it never reads a body, so a fixture whose
artifacts disagree with each other passes every check and teaches a wrong shape
anyway. They are asserted here so a later editor knows what to preserve.

| # | Invariant | How it is checked |
|---|---|---|
| F1 | Every artifact's `trip:` is `data-architecture-demo`. | 17 files, one grep |
| F2 | Every `ven-<token>` in `venue-matrix.md`, `event-status.md` and the research lists resolves to exactly one row in `links-reference.md`. A `venue: unminted` marker names no token and is outside the domain; `final-itinerary.md` carries no keys at all (F4). | set difference, both directions |
| F3 | `links-reference.md` has **one row per venue and one key per row** — no key on two rows, no display name on two rows. | the registry probe |
| F4 | `final-itinerary.md` carries **no** Event ID and **no** venue key — C15 holds no entries of its own (§ 4.5) — so every event it names on a day or on the booking checklist resolves to exactly one `event-status.md` row **by display title**, which is the one-way join the model records as a cost. Every `event-status.md` row's venue key resolves under F2. | join, by title one way and by key the other |
| F5 | `Needs booking (derived)` = `yes` **iff** `Status = planned` **and** `Requires booking? = yes`, on every one of the eleven rows — and exactly one row reads `yes`. | truth table |
| F6 | Every traveller in `traveler-model.md` appears in `trip-context.md § Group`; every `travelers/<f>.md` stem resolves to a model entry; **Sam has a model entry and no profile file**. | 3 travellers, 2 files |
| F7 | Every desire in `satisfaction-metrics.md § Desire-coverage` traces to a desire stated in a `travelers/*.md`, or to a declared-absent entry. | join |
| F8 | No venue key appears more than **twice** in `venue-matrix.md`, counted over the emitter's three roles `A` / `Alt` / `B`; the one key that appears twice is flagged `!` and holds the **same** role both times, which is what distinguishes the cap from the forbidden anchor/alternative split. | count |
| F9 | Every day in `final-itinerary.md` carries an anchor event **and** an anchor meal, and no day's anchor event is its nightlife entry. | 4 days, read off the day blocks |

Two further properties are asserted alongside them, because they are the ones a reader
copying this fixture would most easily get wrong: every `artifact:` is the § 1.1
**class string** and never the file's own path (four instances carry an
angle-bracketed one), and every `writer:` / `lifecycle:` / `provenance:` / `publish:`
matches that class's § 1.1 row.

**F2, F4 and F6 are the ones a schema gate structurally cannot reach** — it validates
frontmatter and never reads a body, so cross-artifact agreement is invisible to it.
That is why this list is prose here rather than a script somewhere: writing it as a
script would imply the script runs.

## Entry markers

Nine classes are entry-bearing and the model gives them **two marker forms**. This
fixture carries eight of the nine, and each form appears more than once so neither
reads as a special case.

| Form | Classes here | Key |
|---|---|---|
| Fenced `artifact-entry` block | C5, C7, C18 | `venue: ven-<token>` |
| | C8 | `day: <YYYY-MM-DD>` |
| | C9 | `leg: leg-<token>` |
| Declared key column | C10, C11 | `Venue key` |
| | C13 | `Event ID` — the precedent the model itself cites |

`ven-<token>` is **minted once, by the hub, at its first enumeration of the venue
set — before it writes either reference file.** The mint point is fixed against the
enumeration and not against an artifact: Pre-Work writes `links-reference.md` **first**
and `venue-matrix.md` second, so minting at the matrix would leave the link file — the
one-URL-per-venue SSOT the location invariant resolves against — keyless at the moment
it is written. Both reference files therefore *receive* the keys; neither mints them,
and neither reads them from the other.

**The research spokes run before that enumeration, so their markers are born
`venue: unminted` and resolve one pass late** — `unminted → ven-<token>`, performed in
place and one-way by the file's own single writer, on its next pass. **`unminted` is a
converging state, not an instantaneous one**, and on a single-pass trip that never
re-runs a spoke it never converges at all. That is a **recorded disposition, not a
defect**: the model states the cost rather than deferring it, and the fixture depicts
it rather than skipping to the end state.

**The key is a convergence optimisation and never the join basis.** The hub joins two
mentions to one place by its five-rung identity procedure **at every mint**, not only
at the first — so a fixture must not imply that venues are matched by reading tokens
off each other's files.

Four cases are shown deliberately, because they are four different facts and only one
of them is obvious:

- a **resolved** key, in every entry whose spoke has run again since the mint —
  `activities-list.md` § *Initial Research*, `nightlife-list.md`, and two of the three
  entries in `rooftop-sunset-bars.md`;
- **`venue: unminted`, converging** — the three anchor-meal entries in
  `activities-list.md` § *Targeted Update*. The hub has already minted and placed those
  three venues; the markers catch up on that spoke's next pass. This is the transition
  itself, and it is the state a first-pass trip is *always* in;
- **`venue: unminted`, permanently** — the third candidate in `rooftop-sunset-bars.md`,
  never carried forward, so never in the enumeration and never minted. A declared
  absence, never a default;
- **no marker at all** on the *Live fado* entry in `nightlife-list.md` — there is no
  venue, so there is no entity to key.

**The two `unminted` cases are the same token and different facts**, which is why both
are here. One says *not yet*; the other says *not ever*. A fixture carrying only the
resolved case would teach a state the engine cannot reach on a first pass, and would
conceal the mechanism entirely.

**None of this is validated by anything.** The fence grammar admits no entry construct
and the validator emits no entry-marker finding code, so a green schema check says
nothing about marker conformance. The markers are here because the fixture's job is to
show the migrated shape, and for these classes the marker is part of it.

## The `accumulate-append` criterion — two of six, and why

`reference/data-architecture.md` § 10 states that **a fixture that instantiates an
`accumulate-append` class should carry at least two dated sections, or that lifecycle
stays declared and unwitnessed** — and records that the criterion was met by one
instance of six, leaving the question open. It is answered here.

**Two of the six now carry two dated sections**, and they were chosen because each
witnesses something the other cannot:

| Instance | Class | Dated sections | What the second section witnesses |
|---|---|---|---|
| `trip-log.md` | C2 | 2 | accumulation as the narrative register — a second session appended, nothing rewritten |
| `outputs/activities-list.md` | C5 | 2 | accumulation **plus** the marker transition — a resolved section beside an `unminted` one, which needs two sections to exist at all |

**The other four stay at one, on the fixture's own Depth rule, and that is a decision
rather than an omission.** § 10's criterion is written against the *lifecycle*, not
against every instance of it: what it guards against is a lifecycle that is declared in
frontmatter and witnessed nowhere. Two instances witness it, and one of them witnesses
the hardest thing the lifecycle does. A third, fourth, fifth and sixth copy of the same
append would add no fact — each would be a second copy of an answer the fixture already
gives, which is the duplication § 4.3 exists to prevent and the reason
`README.md` § *Depth* refuses a second `examples/tokyo-2026/` in the first place.

Per instance:

- **`outputs/nightlife-list.md` (C7)** — its spoke *did* re-run on the second pass and
  found nothing to add, so it resolved its markers in place and appended nothing. That
  is a real and instructive outcome: **resolving a marker is not an append**, and a
  re-run that confirms has nothing to accumulate. Manufacturing a second section here
  would erase that distinction.
- **`outputs/rooftop-sunset-bars.md` (C18)** — **the class has no producer**, so there is
  no second pass to accumulate: nothing in the engine opens a slug file, so this
  instance — like every file in this directory — depicts the class rather than being
  captured from a run of it. The status is stated once, in
  `reference/schemas/targeted-research.md` → "Reachability", and cited here rather than
  restated. One dated section is what a depiction of an `accumulate-append` class needs
  to carry, and a second would be a second copy of an answer the fixture already gives.
- **`outputs/scheduling-framework.md` (C8)** and **`outputs/transport-brief.md` (C9)** —
  tier 2. Both carry their writer's full declared section set, which is the shape claim
  this fixture makes; a second dated section would add content depth, which is exactly
  what tier 2 declines and what `examples/tokyo-2026/` supplies.

**Stated here rather than left unmet.** § 10 says the criterion is open and does not
take the decision; this file takes it, for this fixture, and names the four instances
it does not apply to and why. A reader auditing the fixture against § 10 finds an
answer rather than a silent shortfall.

## `site-preview.svg` — the figure in the repo README

`site-preview.svg` renders the site design system in `reference/site-layout-spec.md`
§§ 1–3 (typography, colour architecture, component catalog), laid out per § 4
*Desktop*, against **this fixture's** own artifacts. It is embedded in the repo
`README.md` § *What it produces*.

**It is a figure, not a screenshot, and it is source, not output.** There is no build
step and no capture step: the file is edited directly. Nothing generates it and
nothing regenerates it.

### Why it is an SVG and not a screenshot — read this before adding a PNG

The obvious artifact for *"show what the engine produces"* is a screenshot. **It is
the wrong one here, for a measured reason rather than a stylistic one: this
repository's only personal-data control cannot see inside a binary.**

`.github/workflows/depersonalization.yml` scans **added diff lines**. Both of its
content arms are shaped

```
git diff --unified=0 <base>..<head> … | grep -E '^\+' | grep -v '^\+\+\+' | grep -EI "<pattern>"
```

and that pipeline is blind to a binary twice over. `git diff` emits **no content
lines** for a binary file — only `Binary files a/x and b/x differ` — so there is
nothing for `grep -E '^\+'` to match; and `grep -I` **explicitly suppresses binary
matches** even where content did reach it. Measured on a purpose-built repository in
which a PNG and an SVG carried the **identical** leak tokens: the SVG returned **1**
gate hit, the PNG returned **0**, from **0** added lines.

So a leaked email address, an OS user-home path, or a real traveller's name baked into
the pixels of a committed screenshot **passes the gate green**. Committing this
repository's first binary would open a permanent blind spot in the one control
standing between a public repo and a personal-data leak — and it would do it in the
artifact class whose whole subject is image content.

**An SVG is text.** Every string in it is a diff line the gate reads, a line a
reviewer sees in a pull request, and a line `gitleaks` walks. That is the property
being bought, and it is why the format is not a preference.

The regeneration argument closes it independently. There is **no executable site
build** in this repository — `CLAUDE.md` § *Travel Site Generation* makes the site "a
bespoke creative artifact — not a template fill", authored per trip by an agent — so
**no PNG here could ever be re-derived from tracked inputs**. A captured screenshot
would be exactly the silently-stale binary that has no way back to a source. An SVG
has no upstream to drift from: it *is* its own source.

**If you are about to add a screenshot, the answer is no.** Extend or replace this
figure instead, or open an issue proposing that the personal-data gate learn to read
binaries first.

### To regenerate, and when to revisit

**To regenerate:** edit `site-preview.svg` directly against §§ 1–3 of the layout spec
and the fixture artifacts named below.

**Revisit it when either source moves:**

| Source | What a change there means for the figure |
|---|---|
| `reference/site-layout-spec.md` §§ 1–3 | Typography, a colour token, or a component's field set changed — the figure shows the old design system |
| This fixture's `final-itinerary.md`, `event-status.md`, `venue-matrix.md`, `links-reference.md`, `activities-list.md`, `nightlife-list.md`, `trip-context.md` | A name, time, Event ID, venue key, status or count changed — the figure now disagrees with the artifacts it was drawn from |

**Nothing checks either coupling.** The schema gate validates frontmatter and never
reads a body, and this file carries no frontmatter at all; `markdown-link-check`
validates that the embed *path* resolves and never looks inside the file. Figure
staleness is caught by a reader, or not at all — which is why the trigger is written
down here rather than assumed.

### Constraints on the file itself

GitHub renders a **sanitized** copy of an SVG, so rendering it locally proves nothing.
Use presentation attributes only — `fill`, `stroke`, `font-family`, `font-size`,
`font-weight`, `text-anchor`, `opacity`. No `<style>` block, no `style=` or `class=`
attribute, no `id`-referenced defs (gradients, filters, clip-paths), no `<script>`,
`<foreignObject>`, `<use>` or `<image>`, no external font, and no
`dominant-baseline` / `alignment-baseline`. Depth comes from **layered semi-opaque
rects**, which is why the hero "gradient" is five flat bands. Generic font stacks
only: the site's three Google Fonts are CDN-loaded and unavailable to a sanitized
inline SVG, so the figure evokes the § 1 *roles* rather than the exact faces.
**Verify in the rendered pull-request view, never only locally.**

### What it is not

- **Not an artifact of the data model, and not a row of the table above.** It carries
  no frontmatter, no schema declares a `.svg` path-pattern, and the selector's
  declared arm needs an `artifact:` value it does not have — so it resolves
  `UNMATCHED` by construction, exactly as `examples/*/README.md` resolves `EXCLUDED`.
  It is deliberately absent from *What each file is here to demonstrate*, and it does
  not count toward the 17 files F1 ranges over.
- **Not a witness for C19**, and not a step toward one. C19
  (`outputs/<destination>-travel-site.html`) is a **decided** `no-witness-because:`
  above: the site source stays local and git-ignored per
  `reference/site-layout-spec.md` § 8, so no instance of that class can be tracked. A
  picture *of* the design system is not an instance of the class, and adding this file
  changes C19's disposition not at all.

### Two things the figure shows that this fixture does not state

Both are recorded so a reader does not mistake either for fixture data.

- **The per-day colour coding on the day-navigation strip.** § 2 *Energy Level Colors*
  gives the site **six named levels** — Survival / Fragile / Building / Peak /
  Selective / Comfort. This fixture declares none of them. What it does declare is the
  hub's own three-value `*Energy:*` field in each day header of
  `outputs/final-itinerary.md`, which is a different vocabulary and does not map onto
  the six. The figure uses the § 2 palette to show the *mechanism* — per-day colour
  coding — and names no level, so it asserts nothing about which day is which.
- **The accent colour.** `--accent` / `--accent-deep` are per-trip values chosen at
  site-build time, not fixture data; § 2 says so in the token block itself. The figure
  uses an azulejo blue on the reasoning `CLAUDE.md` § *Design Principles* gives for
  Portugal.

One deviation from § 4 *Desktop* is also deliberate: its third column is **food**, and
this fixture ships **no** `outputs/food-list.md` (C6 is absent on purpose, above). The
plan does place an anchor meal on every day, so the column has real content to carry —
Saturday's is `Casa de Pasto Central` — but that content is researched in
`outputs/activities-list.md` rather than in the class the column is named for. The
column therefore carries the Saturday night card beside it and is labelled
*food · night*. Inventing restaurants to fill it would still have put content in the
figure that the fixture does not have.
