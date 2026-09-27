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

### What drives the shape

| | Option | In one line | Disposition |
|---|---|---|---|
| **A** | **One site, its shape keyed on the resolved state through one render table** | the build reads the resolved mode and destination from the resolution record; a table says what that state's build renders | **chosen** |
| B | A sequence of per-phase surfaces | each phase gets its own page or repository, and a transition replaces the surface | **rejected.** It breaks the fixed publish surface — one file, one ciphertext check, one passphrase per repository; separate surfaces would be separate channels under `ADR-026` § 2; the catalog has rejected a page per unit once; and at every transition the group would lose its anchors and its checklist state |
| C | Shape driven by which files exist | render whatever has content | **rejected.** It fails #1241's shape criterion by construction and is the reading `ADR-026` § 4 and `G5` forbid: once the shortlist has a home it would render beside a chosen destination indefinitely |
| D | A declared coarse partition, pre-plan and plan | shape keyed on a derived two-value phase | **rejected, as the close rival.** It mints a partition and a mapping the corpus does not have. A to D is a table compression and CHEAP; D to A is a vocabulary split and MODERATE |
| F | One site carrying every phase, with a client-side switch | every phase is always built; the viewer picks one | **rejected.** It publishes superseded content inside every ciphertext for the trip's whole life, and hidden text is still visible text to the confirm gate |
| G | The trip's temporal horizon, before, during and after | shape keyed on time from the dates | **rejected.** It keys on something undeclared, which `G5` forbids; its useful form — today's day first during the trip — is a client-side variant, not a driver |

### The grain the driver acts at

| Option | What the state gates | Disposition |
|---|---|---|
| **Artifact** | a state's build renders an artifact whole, or not at all | **chosen.** It is the grain the class is declared at, the grain `ADR-026` § 4 gates production at, and the grain agents produce at |
| Section | a section-admission table, independent of artifacts | **rejected.** It declares a second time which component renders which element, and nothing ties a section to its source's class |
| Element | a mode column on every element-fence row | **rejected.** It permits a partially rendered artifact and splits the walk's grammar comparison |

### How the completeness contract extends

| | Option | Disposition |
|---|---|---|
| X1 | A mode column on § 9.1's fence | **rejected.** Reach would become a function of mode |
| X2 | One generalized element fence with artifact and mode columns, replacing the shipped fence | **rejected.** It changes the identity of a shipped, graded pin and moves gating to element grain |
| **X3** | **Two grains: a new artifact-grain render table, and one element fence per rendered artifact, the shipped fence untouched** | **chosen** |
| X4 | Prose only | **rejected.** A rule stated and executed nowhere is the defect group `W` names |
| X5 | A render table listing every per-trip class, `internal` ones included | **rejected.** It declares § 1.1's class a second time and goes stale with every new class |

### The section ceiling

| | Option | Disposition |
|---|---|---|
| K1 | A numeric cap on sections per state | **rejected.** Nothing grounds the number, and a cap forces the re-litigation the criterion forbids |
| K2 | One section per distinct reader question | **rejected.** A judgment per card |
| K3 | One section per artifact | **rejected.** False today: the Hero, the Overview, the Day sections and the Checklist all render itinerary elements |
| **K4** | **A four-test ladder over declared tables** | **chosen.** It reuses § 9.5's representability test and the § 9.1, § 5.1 and § 5.6 declarations, and reproduces every decided case |
| K5 | A section budget per mode | **rejected.** A budget invites spending it |

### What *Destination in play* renders

| | Option | Disposition |
|---|---|---|
| **A** | **The hero naming the destination as under consideration rather than chosen; the shortlist off the page** | **chosen** — the operator's D-4: the page moves on, and the shortlist stays on disk. The group snapshot (D-3) and the group contacts section (the carrier) join it, so the page is no longer the hero alone |
| B | Keep the shortlist as *how we got here* | **rejected.** A second, possibly stale source for *where*, from a producer that has stopped refreshing it |
| C | Declare the hub's destination comparison and render it | **rejected here, routed.** A new class, and its content is not bounded by the private-site record's lists at production |
| D | Refuse the state | **rejected.** A published shortlist page could then never be rebuilt to the declared state — a transition the site could not follow |

### The shortlist after IDEATION

| | Option | Disposition |
|---|---|---|
| **A** | **Excluded, per state, and named in § 9.3** | **chosen** |
| B | Rendered as history | **rejected.** A second source for *where*, and the client-side-switch option by another route |
| C | Collapsed to a one-line record, such as "chosen from a shortlist of three" | **rejected.** It restates the trip context's destination — a second home — and adds nothing a reader acts on |

### The concealed occasion's form

| | Option | Disposition |
|---|---|---|
| **A** | **A variant of the schedule entry, concealed at render from a mark on the itinerary's event** | **chosen** |
| B | The hub writes the event into the itinerary already concealed, with no venue | **rejected.** The event stops being bookable and trackable, because the booking status joins by venue key: either the organizer loses the booking, or the venue reaches the page through the booking status and the links anyway |
| C | A new card type | **rejected by the ceiling**: Q3 finds the schedule entry |

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

### `ADR-026` Finding 1

| | Option | Disposition |
|---|---|---|
| A | Take it: an in-model § 1.1 row for the published artifact | **rejected**, on the grounds in § 8 |
| B | Take it: an explicit § 1.2 row, split from the `.publish/` row | **left to the routed card.** It is a disposition about the trust boundary, outside this record's domain, and it changes the enumeration's closed count |
| **C** | **Decline in terms, and route** | **chosen** |
| D | Decline silently | **rejected.** That is the pattern that orphaned it |

### The transition policy, and the shown relation's observation

**Replace** is chosen. Accumulating is rejected: a second source, and a ciphertext that grows with
history. A client-side hide is rejected for the reason the client-side switch was.

| Criterion | **Content identity** (chosen) | Order (today's `list`) |
|---|---|---|
| What it measures | whether what crossed the channel is the built artifact — `ADR-025` § 6's own words | whether anything was built after the last push |
| A rebuild that changes nothing | `CURRENT` | reads stale — a false positive |
| Clocks | none; the comparison is local | the local modification time against the remote commit's date, across two machines |
| Needs the network | no | yes |
| Reuses | the confirm gate's projection and the publish script's record of the last push | the file's timestamp and the remote commit date |
| Blind to | a push made from another machine | a content-free touch that reads as change |

### How the values the group may see reach the page

| | Option | Disposition |
|---|---|---|
| **A** | **`bound` carriers only** | **chosen** — the trip context, the shortlist, the itinerary, the group snapshot and the group contacts file |
| B | The traveller file made `bound`, with a field fence | **rejected.** A wider read surface for less coverage, and the build would parse hand-edited files carrying values that are out |
| C | A derived, `bound` projection of the shared details | **taken as the group snapshot** (§ 9), by the operator's D-3 |
| D | The build reads the traveller model's fields under a field-keyed exception | **rejected.** It is the field-keyed mechanism of the private-site card's fourth design pass, which that record does not carry forward, and it contradicts § 2's contract |

### The group snapshot's writer and home

| | Option | Disposition |
|---|---|---|
| **W1** | **The enrichment agent, in its reconciler role** | **chosen.** It already reads every input and already computes who filed, so it adds no agent |
| W2 | The destination-ideation agent | **rejected.** It is skipped once a destination is set, so it cannot serve *Destination in play*; its declared read is the leaning fields only, and the shortlist's no-reader design stands |
| W3 | The site build, deriving it at render from the traveller model | **rejected.** The build reads no traveller file or model, and the model is `internal-hard` — never rendered in any form |
| W4 | A `/trip-record` verb, writing it itself | **rejected.** That verb's own writes are human source; where a derived file must be rebuilt it dispatches the reconciler or names that step, because ownership follows the writer, not the caller |
| W5 | The hub | **rejected.** It runs only in synthesis — never in *No destination yet* — and the snapshot is not plan content |
| W6 | A new agent | **rejected.** A new roster row and dispatch for a projection the reconciler already holds every input of |
| **S1** | **A new `bound` class, `outputs/group-snapshot.md`** | **chosen** — net-new, because in-place is infeasible |
| S2 | Fold it into the shortlist | **infeasible.** The shortlist renders only in *No destination yet*, its producer is skipped once a destination is set, and its schema declines per-entry fields |
| S3 | Fold it into the trip context | **infeasible.** No per-traveller desire detail goes in that file, which is block-owned, and it would give traveller answers a second, hand-edited home |
| S4 | Relax the traveller model to `bound` behind a field fence | **rejected.** The model carries values that are out, and the field-keyed mechanism is not carried forward |
| S5 | The traveller file made `bound`, with a field fence | **rejected.** It covers only the per-trip half, and the build would parse raw hand-edited files |
| S6 | Widen `ADR-028`'s presence file | **infeasible.** It is `internal` and bounded to its window lines, and its own tripwire moves it to `internal-hard` the moment it carries content derived from desires |

### The group snapshot's production and currency

| | Option | Disposition |
|---|---|---|
| **P1** | **Written only on IDEATION passes; on the `site` verb's Reads line in every state** | **chosen** — the shortlist's pattern, with no false `BEHIND`. Its costs: a mode branch in an agent, graded only once registered; and on a return to IDEATION the file on disk is as of its last IDEATION pass until reconciled, which the `mode` verb names |
| P2 | Written on every pass; the Reads line qualified by state | **rejected.** A state-qualified Reads line is a new idiom this record declined for the shortlist — two patterns for one problem. Its real merit, a file kept current across a return, is named |
| P3 | Written on every pass; the Reads line unqualified | **rejected.** A false `BEHIND` on every plan-mode reconcile — `ADR-028` § 2's own reason |
| P4 | The site verb dispatches the reconciler before building | **rejected.** The site dispatches no agent and never edits an `outputs/` file as a side effect; it would widen the verb's grants and read class |
| **R-a** | **No new freshness relation** | **chosen** — ride the named reconcile step, R1 to R3, and the declared hand-edit residual |
| R-b | A `profiles-to-snapshot` relation | **rejected under P1.** It would read `BEHIND` in every plan mode, with a remedy that cannot clear it |

### The group snapshot's smaller forks

| Fork | Chosen | Rejected, and why |
|---|---|---|
| Plan modes | excluded | rendered as a section: it re-opens the plan-mode carriers, and D-3 scopes the document to before a plan |
| A marked desire | its `Desire` text only | the whole desire block: its overlap signal would disclose unmarked desires, and its tiers invite ranking people's wants |
| Content that is out, inside a carried value | withhold the line whole | trim it: that publishes words the traveller did not write |
| The population floor | `SELF-STATED` | `ADR-025`'s default floor, `OPERATOR-STATED`: the private-site record's safeguard 3 |
| The name | `outputs/group-snapshot.md` — the operator's own term | a neutral stem such as `group-details`: it loses traceability to D-3 |

## Decision

*Authored in the commits that follow on this release branch.*

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
