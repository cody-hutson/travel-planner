# Changelog

All notable changes to the travel-planner engine are documented here. The format
follows Keep a Changelog; versions follow Semantic Versioning.

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
