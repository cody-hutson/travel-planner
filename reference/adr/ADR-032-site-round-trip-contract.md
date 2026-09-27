# ADR-032: The site's round-trip contract across its rendered artifacts — two grains, one render table, and a walk in three passes

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries how its round-trip completeness contract extends past the itinerary; *References* lists
  the card's other records. The milestone's other cards are [the private-site
  record](ADR-029-what-the-private-site-may-show.md) (#1242) and [the contact and emergency
  record](ADR-031-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after [the
  private-site record](ADR-029-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because the card's pre-plan rows, in [the site phase-model
  record](ADR-030-site-phase-model.md), render values that record admits. The flip is the
  maintainer's, taken at this milestone's close, and it moves both halves of a two-artifact state:
  the `Status:` line above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **how the site's round-trip completeness contract extends past
  the itinerary**, across its surfaces in `reference/site-layout-spec.md` § 9: the contract's two
  grains, the render table's place in § 9.2, § 9.3's state column, the walk's three passes and
  § 9.5's boundary.
- **What this record is not.** It does not decide what each state renders — the render table's rows
  are [the site phase-model record](ADR-030-site-phase-model.md)'s — or what earns a section, which
  is [the section-ceiling record](ADR-033-site-section-ceiling.md)'s. It builds nothing, and in this
  release it changes no `publish:` value, no fence line and no per-verb requirement row: every
  change it decides lands in a later slice.
- **How it was decided.** In the first design pass on the card's design sub-task #1388, which decided the
  completeness contract; the milestone's fit review and scope lock, CR-2, are recorded on #1369.
  The card's one record was split by topic under the operator's R2, recorded on #1369,
  with no decision changed.

## Context

**The site carries a governed single-sourcing contract with a completeness obligation**
(`reference/site-layout-spec.md` § 9.1 to § 9.5). It stops at the itinerary:

**The completeness obligation does not reach a pre-plan artifact, and its class keeps one off the
site.** § 9.2 is scoped over `outputs/final-itinerary.md`. What excludes the destination shortlist
today is its class: `outputs/destination-shortlist.md` is `internal`, never rendered
(`reference/data-architecture.md` § 5.1). Giving it a home is a class change as well as an
extension of § 9.2.

**Terms.** σ is the resolved state, (`trip.mode`, `trip.destination`), on which [the site
phase-model record](ADR-030-site-phase-model.md) keys the site's shape through one render table;
that record's map fills the table's rows.

**What the live target establishes.** Every fact below was read live at `8b2ac05`, the base of this
release.

- **The completeness walk covers only the itinerary, by construction.** `scripts/check-round-trip.sh`
  binds one fence tag, `round-trip-contract-elements`, and one grammar region, the hub planner's
  itinerary grammar. Its contract half is graded on the tracked tree by group `W` of
  `scripts/test-artifact-schema.sh`, a required check.

**Precedents this record reuses rather than mints.**

| Precedent | Where | What it already decided |
|---|---|---|
| Structural-gap boundary | `reference/site-layout-spec.md` § 9.5 | a new component is built only for an element no component can represent |
| The presence class | `ADR-028` § 2 | an `internal` class takes no fence row and no § 9.3 row: the class alone excludes it |

**The inputs this record is bound by.** The milestone's surface map, recorded on #1369, fixed the
closed list of what this record still had to decide.

## Decision drivers

1. **#1241's acceptance criteria.** Completeness per mode, checkable by the walk; shape as a function
   of the declared mode; and a ceiling that returns a yes or a no.
2. **One declared home per fact, graded by an existing suite** — the corpus pattern of groups `PB`,
   `W` and `MG`. A rule nobody grades is the defect group `W` was built to close.
3. **Reuse the shipped vocabulary** — the mode set `G5` declares, the cell grammar of `G7`, and the
   `rendered | excluded` enum — as `ADR-025` did when it withdrew a minted staleness vocabulary.
4. **Fail closed.** An empty read is not an empty class (`ADR-009` § *Decision* 4.4).
5. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
6. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### How the completeness contract extends

| | Option | Disposition |
|---|---|---|
| X1 | A mode column on § 9.1's fence | **rejected.** Reach would become a function of mode |
| X2 | One generalized element fence with artifact and mode columns, replacing the shipped fence | **rejected.** It changes the identity of a shipped, graded pin and moves gating to element grain |
| **X3** | **Two grains: a new artifact-grain render table, and one element fence per rendered artifact, the shipped fence untouched** | **chosen** |
| X4 | Prose only | **rejected.** A rule stated and executed nowhere is the defect group `W` names |
| X5 | A render table listing every per-trip class, `internal` ones included | **rejected.** It declares § 1.1's class a second time and goes stale with every new class |

## Decision

### 1. The round-trip contract, extended past the itinerary across its surfaces

**The contract becomes two-grain**: a new **artifact grain**, indexed by state and total over the
`bound` classes, and the **element grain** as today — mode-blind, one fence per rendered artifact.

| Surface | Today | Decided |
|---|---|---|
| **§ 9.1's fence and § 1.1, held equal by group `PB`** | declares which artifacts the build may read | **retained, and mode-blind**: no mode column and no mode-qualified class. A pre-plan artifact reaches the build only through a class change that lands in § 1.1 **and** the fence in one commit; group `PB`'s pairing fails otherwise |
| **§ 9.2's obligation** | a surjection over the itinerary's elements | **two-grain** — below |
| **§ 9.3** | element exclusions only | **gains a state column.** Element rows apply in every state their artifact renders in, today's unchanged. Artifact rows name a `bound` class a state does not render, with the reason. A class excluded by its own class value is never listed. The residual row for the traveller model and the satisfaction metrics stays as it is: it belongs to the grammar comparison of the itinerary's element fence, not to the artifact grain |
| **§ 9.4's walk** | one pass, over the itinerary | **three passes, with σ as input** — below |
| **§ 9.5's boundary** | a component gap is a fast-follow | **extended to the phase dimension, and closed to reach** — below |

**§ 9.2 — the two grains.**

- **(a) Artifact grain.** A new render-table fence in § 9.2, its proposed info string
  `round-trip-contract-artifacts`. It carries one row per `bound` class and state: `rendered` with its
  home, or `excluded` and named in § 9.3. **Only `bound` classes take rows**; a class that is
  `internal`, `internal-hard` or `output` is excluded by that class, which the walk reads from § 1.1
  (`ADR-028` § 2's reading, reused). Scaffolding takes angle-bracketed rows — `<sticky-navigation>`,
  `<coordination-notice>`, `<reference-matter>` — because which scaffolding a state emits is part of
  its shape. The render table is net-new because in-place is infeasible: a mode on § 9.1's fence
  would index reach by mode, a mode on the element fence would move gating to element grain,
  and rows added to a per-verb table would be counted as verbs.
- **(b) Element grain.** `round-trip-contract-elements` stays byte-for-byte as the itinerary's fence.
  Each newly rendered artifact gets a sibling fence, `round-trip-contract-elements-<artifact-stem>`,
  graded against the grammar of the agent that produces it, at the grain that artifact's own schema
  declares. **No entry marker is ever added to an artifact to make it walkable.** Every element fence
  carries the `<artifact-frontmatter>` exclusion.

**§ 9.4 — the walk's passes.** The walker takes σ from the verb. **Without σ it refuses the artifact
and shape passes and reports them as not run — never as clean.** It never infers σ.

1. **Artifact pass.** Its contract half, on the tracked tree: every `bound` class has a row for every
   state the `site` row admits, and every row names a `bound` class, graded against § 1.1 in both
   directions as group `PB` grades the fence. Its instance half, at the verb: every artifact admitted
   for σ is readable; otherwise the read is degraded.
2. **Element pass.** Today's walk, run once per rendered artifact against that artifact's own fence.
3. **Shape pass.** The render carries no component σ does not admit. This catches the surplus
   direction; the deficit stays with the shipped finding for an unresolved element.

A patch across a change of state is a structural patch, and a section it leaves behind is the shape
pass's surplus finding.

**§ 9.5 — three cases that look alike.** An admitted component that was not placed is a build defect,
in scope. An artifact a state renders, with an element type no component represents, is a component
gap, a fast-follow; the ceiling decides whether it becomes a section, a region or a field. An artifact
whose class forbids rendering is **never a gap**: § 9.5 routes no class change, and reach moves only
through a record that lands in § 1.1 and the fence together.

**The walker, and the render table's own rules.** The walker is extended, not forked: a second
walker would split the suite's inventory and its invocation anchor. Its per-artifact declarations
and label shapes, its finding classes and their control arms, how the verb passes σ to it, and the
arms that grade the render table are Wave 1's to specify.

- **The render's own state-gating takes no row in the mode-gated behaviour register.** That register's
  declared scope is agent-side branches in agent files that carry an output contract, and the `site`
  verb dispatches no agent; the render table is the single home of the render's state-gating. The
  group snapshot's production gate is an agent-side branch and does take a row
  ([the group-snapshot record](ADR-037-group-snapshot.md)).
- **Render-table rows name their modes explicitly.** `any` is not used: under `G7`'s grammar it admits
  `UNSET`.

## Consequences

**Positive**

- **Completeness becomes checkable per state.** The walk's artifact pass runs over the `bound` set, and
  an artifact excluded by its class needs no listing. That the build reads the declared phase becomes a
  graded property through the shape pass, even though the plan modes resolve to one shape.
- **New classes are cheap and forced.** A class that is not `bound` costs no map edit; a new `bound` class
  costs one row per admitted state, and the contract half turns the check red until those rows exist.

**Costs and residuals, stated rather than smoothed**

- **The contract surface grows** by one render-table fence, a family of walker passes, two finding codes
  and their arms — each bounded, declared and graded.
- **The walker needs σ from the verb.** A standalone run without it gets only the element pass, and says
  so.
- **Reference matter has no § 3 component**, so the shape pass cannot see it.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| an undispositioned `bound` class — the contract half | the walker's exit contract, "Exit 0 clean, 1 findings, 2 degraded read."; graded as a group `W` arm in the required artifact-schema suite | the walker's contract run can exit with findings when a class turns `bound` without its render-table rows, and the arm's failure blocks a merge, so a class cannot become renderable without its rows for every admitted state |
| a surplus component — the instance half | the `site` verb: "This verb adds no verdict of its own and suppresses none of the script's." | a stale section left after a transition makes the verb report the site as not current; nothing else changes |
| an admitted artifact that cannot be read — the shortlist, the group snapshot or the group contacts file absent in a state that renders it | the walker's exit contract | a degraded read; the verb withholds "current"; nothing else blocks |
| the new finding codes | group `W`'s inventory: "A code added to the walker with no arm behind it is RED rather than latent" | neither code can ship ungraded |

**The non-blocking claims hold.** The walk's findings never block a build's write or a publish. The
contract half is deliberately **not** non-blocking: it gates merges through the required suite.

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `skills/trip/SKILL.md` | σ passed to the walker |
| `reference/site-layout-spec.md` | § 9.1: the new authority and fence rows. § 9.2: the render-table fence and the new element fences. § 9.3: the state rows. § 9.4 and § 9.5: the three passes and the phase clause |
| `scripts/check-round-trip.sh` and group `W` of `scripts/test-artifact-schema.sh` | the per-artifact declarations, the new fences and label shapes, the IDEATION rows, the non-row, and the new finding codes with their arms |
| `CLAUDE.md` · `reference/command-reference.md` · `README.md` | the walk's scope |

**Three axes.** *Best practice:* one declared home per fact; reads that fail closed. *Scalability:* a
class that is not `bound` costs no edit, and a new `bound` class costs one row per admitted state.
*Maintainability:* it reuses `G7`'s cell grammar, the `rendered | excluded` enum and the shipped
walker, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, the two-grain contract | **MODERATE** — the spec, the walker and the grader can each be reverted | HIGH |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What each state renders — the render table's rows — and σ | [the site phase-model record](ADR-030-site-phase-model.md) |
| What earns a section, a region or a field | [the section-ceiling record](ADR-033-site-section-ceiling.md) |
| The classes the build reads, and the states it admits | [the site-admission record](ADR-034-site-build-admission.md) |
| The group snapshot's element fence rows | [the group-snapshot record](ADR-037-group-snapshot.md) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **The completeness contract**: the render-table fence, the per-artifact element fences, § 9.3's state
  rows, the walker's three passes and group `W`'s arms.
- **σ to the walker**, in the phase-aware build.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The site phase-model record](ADR-030-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the presence class whose class-reading
  exclusion this record reuses.
- [ADR-009](ADR-009-data-architecture.md) — § 4.4's fail-closed paths.
- `reference/site-layout-spec.md` — § 9.1 to § 9.5.
- `reference/data-architecture.md` — § 1.1's classes and § 5.1.
- `CLAUDE.md` — § *Resolving a trip* (`G7`'s cell grammar) and the mode-gated behaviour register.
- `scripts/check-round-trip.sh` and `scripts/test-artifact-schema.sh` — the walker and its grader.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the first pass; the plan, its
  surface map, the fit review, CR-2 and R2 on #1369; and the Wave-1 working notes this record's
  build detail moved to, on #1392.
