# ADR-030: The site's phase model and surface contract — what drives its shape, the render table across the phases, and the section ceiling

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after this record is accepted. It is one of
  three records of the *The site serves every phase: the founding decision* milestone, beside
  [the private-site record](ADR-029-what-the-private-site-may-show.md) (#1242) and
  [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after
  [the private-site record](ADR-029-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because this record's pre-plan rows render values that
  record admits. The flip is the maintainer's, taken at this milestone's close, and it moves both
  halves of a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  `reference/adr/README.md`.
- **What this record is.** A decision about **how the site renders in each phase of a trip**: what
  drives its shape, which artifacts each state's build renders and where, how the round-trip
  completeness contract extends past the itinerary, what earns a section, how the build verb admits
  the pre-plan states, what happens to earlier-phase content at a transition, and the group snapshot
  that carries the group's shared details before a plan exists.
- **What this record is not.** It decides rendering, not reach. What a channel may carry is
  `ADR-026`'s, what the private site may show is the private-site record's, and what of a
  traveller's contact and emergency details the group sees is the contact and emergency record's.
  It builds nothing, and in this release it changes no `publish:` value, no fence line and no
  per-verb requirement row: every change it decides lands in a later slice.
- **How it was decided.** In three design steps on the card's design sub-task #1388: a first pass
  (the shape driver, the completeness contract, the ceiling, the plan-phase cells), a second pass
  (the pre-plan rows, the admission, the transitions), and a scoped step for the group snapshot. The
  operator's decisions D-1 to D-4 sit between the second pass and the snapshot step, and the
  milestone's fit review and scope lock, CR-2, are recorded on #1369. The contact and emergency
  record's carrier, decided on #1546 as decision K, is placed in this record's render table by
  citation, and decision Q, recorded on #1385, binds the group snapshot's writer through the
  private-site record's safeguard 7.

## Context

**The site's component catalog has one phase in it, and nothing reads the phase at build time.**
Three facts frame the gap without being it. The engine carries a phase variable, `Current mode`, over
five values, written by `/trip-record mode` (`CLAUDE.md` § *Modes*). The publish verb is already
phase-blind and destination-blind: `/trip-publish update` admits any mode and any destination. And
the site carries a governed single-sourcing contract with a completeness obligation
(`reference/site-layout-spec.md` § 9.1 to § 9.5).

**The gap has three limbs.**

1. **The completeness obligation does not reach a pre-plan artifact, and its class keeps one off the
   site.** § 9.2 is scoped over `outputs/final-itinerary.md`. What excludes the destination shortlist
   today is its class: `outputs/destination-shortlist.md` is `internal`, never rendered
   (`reference/data-architecture.md` § 5.1). Giving it a home is a class change as well as an
   extension of § 9.2.
2. **The build does not run in IDEATION, and does not read the mode where it runs.** The `site` verb's
   requirement row admits the four plan modes with a decided destination only. `ADR-026`
   § *Decision* 4 names this as the one place mode bites on the site channel. Where the build runs, a
   site built in DISCOVERY and one built in ITERATION render the same shape, differing only in fill.
3. **Nothing bounds surface growth.** No rule states what earns a section rather than a field on an
   existing one, so every new artifact class is an unbounded negotiation; #87 is the downstream
   symptom.

**What the live target establishes.** Every fact below was read live at `8b2ac05`, the base of this
release.

- **The build already holds the resolved state.** `/trip` declares `contract-depth: G8`, and the
  `site` row names mode and destination values, so `G5`, `G6` and `G7` run before the verb body and
  the resolution record carries `trip.mode` and `trip.destination`. `CLAUDE.md` § *What the contract
  returns* says downstream verbs branch on these fields instead of re-deriving them. **A render driven
  by mode therefore needs no new read.**
- **The completeness walk covers only the itinerary, by construction.** `scripts/check-round-trip.sh`
  binds one fence tag, `round-trip-contract-elements`, and one grammar region, the hub planner's
  itinerary grammar. Its contract half is graded on the tracked tree by group `W` of
  `scripts/test-artifact-schema.sh`, a required check.
- **Both publish limbs ship one page.** `scripts/publish-trip-site.sh` resolves one rendered page in
  `cmd_publish`; the `--plaintext` limb publishes it as it is and the encrypted limb encrypts it.
- **The organizer-confirm gate keys on the visible text of the whole render**, less the coordination
  band and the render's declaration block.
- **The freshness relation already watches the Mode line.** `itinerary-to-build`, inside
  `trip.freshness`, reads its source side from the paths the `site` verb's **Reads:** line declares,
  and `/trip-record mode` writes the Mode line into `trip-context.md`, one of them.

**Precedents this record reuses rather than mints.**

| Precedent | Where | What it already decided |
|---|---|---|
| Split-Day | `reference/site-layout-spec.md` § 3 | it replaced a page per subgroup with a region inside one day: the catalog has rejected pages per unit once |
| Coordination Notice | the same § 3 | site-additive scaffolding that no § 9 table carries, and that is not emitted when empty |
| Nightlife decline | the same spec, § 9.2 | rendered through the existing band, with no new card type |
| Structural-gap boundary | the same spec, § 9.5 | a new component is built only for an element no component can represent |
| The presence class | `ADR-028` § 2 | an `internal` class takes no fence row and no § 9.3 row: the class alone excludes it |
| Production-gating | `ADR-026` § 4 | mode conditions production, never reach, and is never an artifact-availability axis |
| The shortlist's own schema | `reference/schemas/destination-shortlist.md` | it carries no entry marker, and no consumer branches on a candidate-level value |

**The inputs this record is bound by.** The private-site record's verdict — what the group may see,
the share mark, the concealed occasion and the seven safeguards — and the contact and emergency
record's carrier are inputs here, cited rather than restated. The milestone's surface map, recorded
on #1369, fixed the closed list of what this record still had to decide.

## Decision drivers

1. **`ADR-026` § 4 binds.** Mode conditions production and never reach, and it is never inferred from
   which files exist.
2. **#1241's acceptance criteria.** Completeness per mode, checkable by the walk; shape as a function
   of the declared mode; and a ceiling that returns a yes or a no.
3. **A value's bound is the same in every mode**, as the joint source-binding step of this milestone
   (#1383) fixed it.
4. **The publish surface is fixed.** One self-contained file (`reference/site-layout-spec.md` § 8),
   guarded by one ciphertext check over one render (`ADR-008`), with one passphrase per repository.
   This record decides rendering, not reach.
5. **One declared home per fact, graded by an existing suite** — the corpus pattern of groups `PB`,
   `W` and `MG`. A rule nobody grades is the defect group `W` was built to close.
6. **Reuse the shipped vocabulary** — the mode set `G5` declares, the cell grammar of `G7`, and the
   `rendered | excluded` enum — as `ADR-025` did when it withdrew a minted staleness vocabulary.
7. **Fail closed.** An empty read is not an empty class (`ADR-009` § *Decision* 4.4).
8. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
9. **The private-site record's verdict** — its lists, its share mark, its concealed occasion and its
   safeguards — binds every cell of the map.
10. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

*Authored in the commits that follow on this release branch.*

## Decision

*Authored in the commits that follow on this release branch.*

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
