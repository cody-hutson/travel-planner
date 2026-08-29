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
| `travelers/alex.md` · `travelers/robin.md` | C3 | 1 | needs vs desires; tier and recurrence orthogonal; `Applies to:` links rather than copies; the traveller's name in the **title line**, never in frontmatter. Two files for three roster members — Sam's absence is the operator-fallback branch |
| `outputs/activities-list.md` | C5 | 2 | migrated shape only |
| `outputs/nightlife-list.md` | C7 | 1 | the desire gate resolving *open*; alternatives varying on two axes |
| `outputs/scheduling-framework.md` | C8 | 2 | a spoke emitting a signal, not synthesizing |
| `outputs/transport-brief.md` | C9 | 2 | migrated shape only |
| `outputs/links-reference.md` | C10 | 2 | rebuilt before the itinerary, with `venue-matrix.md` |
| `outputs/venue-matrix.md` | C11 | 1 | the dedup cap, and the anchor/alternative rule it is **not** the same as |
| `outputs/traveler-model.md` | C12 | 1 | `[DERIVED]` projection; the desire-overlap signal |
| `outputs/event-status.md` | C13 | 1 | all four status values; opaque day-independent Event ID; derived needs-booking |
| `outputs/satisfaction-metrics.md` | C14 | 1 | the one declared non-scalar (`writer: [hub, validator]`); section ownership; the six dimensions with their types |
| `outputs/final-itinerary.md` | C15 | 2 | `versioned`, current pass |
| `outputs/final-itinerary-v1.md` | C16 | 1 | the frozen sibling as its **own class**, `publish: internal` where C15 is `bound` |
| `outputs/validation-report.md` | C17 | 1 | the one per-class field, `critical-count`, agreeing with the body |
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
  links are **not** reproduced — `examples/tokyo-2026/` is the worked example for
  content, and this one is the worked example for shape.

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
  it before tripping it.
- **C19 `outputs/<destination>-travel-site.html` — cannot have a tracked instance.**
  `reference/site-layout-spec.md` declares the site source *"Source file (plaintext,
  stays local, git-ignored)"*. A tracked witness would contradict the spec that
  governs the artifact. C19's `no-witness-because:` records that as a **decided
  disposition**, not a pending gap.
- **C4 `outputs/destination-shortlist.md` — already witnessed elsewhere.**
  `examples/ideation-demo/` holds the migrated instance, and a shortlist belongs to
  `IDEATION`, before a destination is chosen. This trip has one, so a shortlist here
  would contradict the fixture's own mode.

## Internal consistency (F1–F8)

**These are the fixture's real acceptance criteria, and no CI check can reach them.**
The schema gate validates frontmatter; it never reads a body, so a fixture whose
artifacts disagree with each other passes every check and teaches a wrong shape
anyway. They are asserted here so a later editor knows what to preserve.

| # | Invariant | How it is checked |
|---|---|---|
| F1 | Every artifact's `trip:` is `data-architecture-demo`. | 17 files, one grep |
| F2 | Every `ven-<token>` in `venue-matrix.md`, `event-status.md`, `final-itinerary.md` and the research lists resolves to exactly one row in `links-reference.md`. | set difference, both directions |
| F3 | `links-reference.md` has **one row per venue and one key per row** — no key on two rows, no display name on two rows. | the registry probe |
| F4 | Every Event ID in `final-itinerary.md` (itinerary and booking checklist) appears in `event-status.md`, and every `event-status.md` row's venue key resolves under F2. | join |
| F5 | `Needs booking (derived)` = `yes` **iff** `Status = planned` **and** `Requires booking? = yes`, on every row. | truth table |
| F6 | Every traveller in `traveler-model.md` appears in `trip-context.md § Group`; every `travelers/<f>.md` stem resolves to a model entry; **Sam has a model entry and no profile file**. | 3 travellers, 2 files |
| F7 | Every desire in `satisfaction-metrics.md § Desire-coverage` traces to a desire stated in a `travelers/*.md`, or to a declared-absent entry. | join |
| F8 | No venue key appears more than **twice** in `venue-matrix.md`, counting distinct `A`/`Alt` roles, and the one that appears twice is flagged `!`. | count |

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

`ven-<token>` is **minted once**, by the hub, in `venue-matrix.md`; every other file
reads it. Three cases are shown deliberately, because they are three different facts
and only one of them is obvious:

- a **minted** key, in every placed entry;
- **`venue: unminted`** in `rooftop-sunset-bars.md` — a candidate never carried into
  the matrix, so no token was ever minted. A declared absence, never a default;
- **no marker at all** on the *Live fado* entry in `nightlife-list.md` — there is no
  venue, so there is no entity to key.

**None of this is validated by anything.** The fence grammar admits no entry construct
and the validator emits no entry-marker finding code, so a green schema check says
nothing about marker conformance. The markers are here because the fixture's job is to
show the migrated shape, and for these classes the marker is part of it.

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
  gives the site six named levels; **this fixture declares no energy level for any
  day**, because C8 is tier 2 here. The figure uses the § 2 palette to show the
  *mechanism* — per-day colour coding — and names no level, so it asserts nothing
  about which day is which.
- **The accent colour.** `--accent` / `--accent-deep` are per-trip values chosen at
  site-build time, not fixture data; § 2 says so in the token block itself. The figure
  uses an azulejo blue on the reasoning `CLAUDE.md` § *Design Principles* gives for
  Portugal.

One deviation from § 4 *Desktop* is also deliberate: its third column is **food**, and
this fixture ships **no** `outputs/food-list.md` (C6 is absent on purpose, above). The
figure's third column therefore carries the Saturday night card beside the standing
bailout café, and is labelled *food · night*. Inventing restaurants to fill a column
would have put content in the figure that the fixture does not have.
