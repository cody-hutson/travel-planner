# ADR-034: The site build's admission of the pre-plan states — one requirement row, a declared stop, the page's file name, and the pre-plan classes

- **Status:** Accepted (2026-09-27)
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries the build verb's admission of the pre-plan states; *References* lists the card's other
  records. The milestone's other cards are [the private-site
  record](ADR-030-what-the-private-site-may-show.md) (#1242) and [the contact and emergency
  record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after [the
  private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because the card's pre-plan rows, in [the site phase-model
  record](ADR-031-site-phase-model.md), render values that record admits. The flip is the
  maintainer's, taken at this milestone's close, and it moves both halves of a two-artifact state:
  the `Status:` line above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **how the build verb admits the pre-plan states**: the admission
  dispositions, the requirement row as Wave 1 writes it, the declared stop for a plan mode with no
  destination, the page's file name while no destination is recorded, the pre-plan classes the
  build reads, and its Reads line.
- **What this record is not.** It does not decide what each admitted state renders, which is [the
  site phase-model record](ADR-031-site-phase-model.md)'s. It builds nothing, and in this release it
  changes no `publish:` value, no fence line and no per-verb requirement row: every change it
  decides lands in a later slice.
- **How it was decided.** In the second design pass on the card's design sub-task #1388, which decided the
  admission; the milestone's fit review, which added the stem rule's transition (MG-1), and its
  scope lock, CR-2, whose sixth call makes erasure reach every page file, are recorded on #1369.
  The card's one record was split by topic under the operator's R2, recorded on #1369,
  with no decision changed.

## Context

**The build does not run in IDEATION, and does not read the mode where it runs.** The `site` verb's
requirement row admits the four plan modes with a decided destination only. `ADR-026`
§ *Decision* 4 names this as the one place mode bites on the site channel. Where the build runs, a
site built in DISCOVERY and one built in ITERATION render the same shape, differing only in fill.

**This record answers its first half**: that the build does not run in IDEATION. [The site
phase-model record](ADR-031-site-phase-model.md) answers the other half, that the build does not
read the mode where it runs.

**Terms.** σ is the resolved state, (`trip.mode`, `trip.destination`), on which [the site
phase-model record](ADR-031-site-phase-model.md) keys the site's shape.

**What the live target establishes.** Every fact below was read live at `8b2ac05`, the base of this
release.

- **The build already holds the resolved state.** `/trip` declares `contract-depth: G8`, and the
  `site` row names mode and destination values, so `G5`, `G6` and `G7` run before the verb body and
  the resolution record carries `trip.mode` and `trip.destination`. `CLAUDE.md` § *What the contract
  returns* says downstream verbs branch on these fields instead of re-deriving them. **A render driven
  by mode therefore needs no new read.**

**The inputs this record is bound by.** The milestone's surface map, recorded on #1369, fixed the
closed list of what this record still had to decide.

## Decision drivers

1. **`ADR-026` § 4 binds.** Mode conditions production and never reach, and it is never inferred from
   which files exist.
2. **Reuse the shipped vocabulary** — the mode set `G5` declares, the cell grammar of `G7`, and the
   `rendered | excluded` enum — as `ADR-025` did when it withdrew a minted staleness vocabulary.
3. **Fail closed.** An empty read is not an empty class (`ADR-009` § *Decision* 4.4).
4. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
5. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### How the admission is encoded

| | Option | Disposition |
|---|---|---|
| **A** | **One row naming the five modes and `any` destination, with the verb's own stop for a plan mode with no destination, and a declared non-row in the render table** | **chosen** — the charter's sanctioned form, with no contract change |
| B | The same row, admitting a plan mode with no destination and rendering the plan-phase shape | **rejected.** It widens the verb to a state no card asks for, and one that `plan`, `replan` and `check` refuse |
| C | Separate rows with parentheticals, a pre-plan `site` and a plan `site` | **rejected.** The taxonomy guard admits the form, but `G7`'s lookup is defined for one row per verb. The only precedent, `/trip-new`'s create and resume rows, sits at depth `G2`, where `G7` never runs, and multi-row semantics at `G7` would change `CLAUDE.md` § *Resolving a trip* |
| D | `any` in the mode cell | **rejected.** It admits `UNSET` |

### The page's file name with no destination

| | Option | Disposition |
|---|---|---|
| **A** | **The trip's slug** | **chosen.** It is the shipped per-trip stem: the publish script's `slug_for` names the repository `<dir>-trip` by default, and `trip.slug` is the directory name "exactly as E1 spelled it" (`CLAUDE.md` § *What the contract returns*) |
| B | A fixed literal, such as an ideation-named page | **rejected.** It mints a name with no gain over A |
| C | One stable stem for every state | **rejected.** It renames every existing plan-mode page, so each trip's next build misses the existence probe and regenerates, dropping approved design — the overwrite the verb's no-regenerate rule forbids |

## Decision

### 1. The build verb's admission, and the pre-plan classes

**The admission dispositions.**

| State σ | Disposition | Where it is expressed |
|---|---|---|
| IDEATION × UNDECIDED | **RUN** | the row |
| IDEATION × DECIDED | **RUN** | the row |
| a plan mode × DECIDED | **RUN**, unchanged | the row |
| a plan mode × UNDECIDED | **the verb's own declared stop**, naming the remedy: record the destination with `/trip-record destination`, or return to IDEATION with `/trip-record mode` | the verb's own section; a declared non-row of the render table, as `ARCHIVED` is |
| `UNSET` × any | **REFUSE**, carrying `G5`'s remedy: `templates/trip-context.template.md` for the field, and `/trip-record mode` to set it | the row: its mode cell names the five modes and never reads `any` |
| `ARCHIVED` | not served, unchanged | the row |

**The row, as Wave 1 writes it:** `site · ACTIVE · IDEATION, DISCOVERY, ENRICHMENT, ITERATION,
RESEQUENCING · any · G8`. Admission rests on [the private-site
record](ADR-030-what-the-private-site-may-show.md): an IDEATION build has something admissible to
render because that record admits the leanings and the group's shared details on the private site.

**Why a plan mode with no destination is a stop, not an admission.** The admitted set — IDEATION with
either destination state, plus the plan modes with a destination — is not a cross-product, and a `G7`
row is one. Nothing asks for a plan-phase site with no destination, and `plan`, `replan` and `check` all
refuse that state today. The charter sanctions the form: a verb the table admits can still stop inside
its own section. **`UNSET`**: the shape is a function of the declared mode, and `G5` forbids
inferring one — `UNSET` is not a sixth mode — so rendering any shape for it would either infer a
mode or mint a shape for a non-mode. The published page stays at its last build, and
`/trip-publish update`, which admits any mode, can still republish that build.

**The page's file name with no destination — the stem rule.** While no destination is recorded, the
render is written to `outputs/<trip.slug>-travel-site.html`; once one is recorded, to
`outputs/<destination>-travel-site.html`, as today. Every reader already takes any
`*-travel-site.html` member, the newest first. The first build with a destination therefore
**creates** a new page rather than patching the old one ([the site-transitions
record](ADR-035-site-transitions-and-refresh.md)), and the IDEATION page stays on disk, unpublished
by the newest-member rule. **Its consequence for erasure:** the IDEATION page can hold the
shortlist, travellers' leanings beside their names, the group snapshot and the group contacts
section, so the erasure verb's reach must name **every** `outputs/*-travel-site.html` file — the
pattern every reader already uses — not the destination-named one alone. That is a Wave-1 condition
of the slice that lands the stem rule (CR-2 call 6), and it is why the erasure verb is named among
the stem rule's consequences.

**The pre-plan classes.**

| Artifact | `publish:` | Decision |
|---|---|---|
| `outputs/destination-shortlist.md` | `internal` → **`bound`** | decided by the private-site record; the render slice lands it in one commit with its § 9.1 authority and fence rows, so group `PB` stays green |
| `outputs/group-snapshot.md` (new) | — → **`bound`** | decided by [the group-snapshot record](ADR-037-group-snapshot.md); its slice lands the § 1.1 row with its § 9.1 rows in one commit |
| `outputs/group-contacts.md` (new) | — → **`bound`** | decided by the contact and emergency record |
| `travelers/<traveler>.md` | `internal` | unchanged |
| `outputs/traveler-model.md` · `people/<person>.md` | `internal-hard` | unchanged; the private-site record relaxes their IN values' bound, not their class values |
| the spoke lists | `internal` | unchanged; *Destination in play*'s overview-level spoke output has no rendered home |
| the hub's IDEATION comparison | — | no artifact, so no class |
| the render | `output` | unchanged; its source list gains the three new `bound` classes, in their slices |

**The Reads line.** The shortlist, the group snapshot and the group contacts file each join the `site`
verb's **Reads:** line in every state, with no false `BEHIND`. The shortlist's only dispatcher,
`/trip ideas`, admits IDEATION × UNDECIDED alone, and the snapshot is produced only in IDEATION
([the group-snapshot record](ADR-037-group-snapshot.md)),
so each can lead `itinerary-to-build` only in a state that renders it, where `BEHIND` is true; the
group contacts file renders in every built state, so the reason does not arise for it. `ADR-028`'s
reason for keeping its own class off the line — a class rebuilt while never rendered — therefore does
not apply.

## Consequences

**Costs and residuals, stated rather than smoothed**

- **The verb index lists `site` as RUN for a plan mode with no destination**, and the verb then stops —
  the declared residual `check` already carries.
- **The IDEATION page stays on disk** after the first build with a destination. It is inert by the
  newest-member rule, and erasure must reach it (§ 1).

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| the stop for a plan mode with no destination | the verb index: "a verb the table admits can still stop inside its own section" | a declared residual; no aggregate changes |

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `skills/trip/SKILL.md` | the `site` row; the verb's own section: the stop for a plan mode with no destination, the stem rule, and the shortlist, the group snapshot and the group contacts file on the Reads line |
| `reference/data-architecture.md` | the § 1.1 rows and cells; the render's source list; § 5.1's statement of the `bound` set |
| `agents/06-validator.md` | its inline statement of the `bound` set |
| `scripts/test-artifact-schema.sh`, beyond group `W` | the `PB` pairing |
| `skills/trip-record/SKILL.md` | `erase`'s reach over every page file |
| the literal sites of the page's file name | each one that states the write target gains the slug case; each generic example stays; the erasure verb's row is among them |

**Three axes.** *Best practice:* reads that fail closed. *Maintainability:* it reuses `G5`'s modes and
`G7`'s cell grammar, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, the admission and the pre-plan classes | **EXPENSIVE** once built — a contract row | HIGH on IDEATION and `UNSET`; MEDIUM-HIGH on the plan-mode stop |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What each admitted state renders | [the site phase-model record](ADR-031-site-phase-model.md) |
| What a transition does to the page | [the site-transitions record](ADR-035-site-transitions-and-refresh.md) |
| The group snapshot's class, and the passes that produce it | [the group-snapshot record](ADR-037-group-snapshot.md) |
| The destination shortlist's class value | [the private-site record](ADR-030-what-the-private-site-may-show.md) |
| The group contacts file's class | [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **The phase-aware build**: the `site` row and its section, and the stem rule with the erasure reach
  over every page file. It also carries the private-site record's § *Decision* 7 condition, the
  Decision-4 supersession entry inside `ADR-009`, as do the shortlist's render slice and the group
  snapshot slice: the build admits IDEATION only from this slice, and the shortlist and the group
  snapshot render only there, so whichever of the three completes the replacement — the first change after which an IDEATION build
  renders the shortlist or the group snapshot — records the entry.
- **The page's file-name sites**, each disposed of one by one.
- **Routed, not Wave 1's by this record:** the observation that `/trip research`'s filter keeps the
  ideation agent out on one limb only.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The private-site record](ADR-030-what-the-private-site-may-show.md) — the verdict the admission rests on.
- [The site phase-model record](ADR-031-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [The contact and emergency record](ADR-038-contact-emergency-group-visibility.md) — the group
  contacts file, one of the pre-plan classes the build reads.
- [ADR-026](ADR-026-channel-architecture.md) — § 4's production-gating.
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — § 2's reason for keeping its own class off
  the Reads line.
- [ADR-009](ADR-009-data-architecture.md) — § 4.4's fail-closed paths.
- `reference/data-architecture.md` — § 1.1's classes and § 5.1.
- `CLAUDE.md` — § *Resolving a trip* (`G5` to `G8`, *What the contract returns*).
- `skills/trip/SKILL.md` — the `site` row and section, § *ideas* and the verb index.
- `skills/trip-record/SKILL.md` — the erase reach table.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the second pass; the fit review,
  CR-2 and R2 on #1369; and the Wave-1 working notes this record's build detail moved to, on #1392.
