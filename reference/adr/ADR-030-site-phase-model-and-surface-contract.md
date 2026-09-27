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

### 1. What drives the shape

> **One site.** Its shape is a function of the resolved state **σ = (`trip.mode`,
> `trip.destination`)**, the fields gates `G5` and `G6` already return, through **one declared
> render table**.

- **S1 — Shape.** For σ, the build renders exactly the artifacts, and exactly the scaffolding, the
  render table admits for σ. The section and navigation set is **derived**: the components of each
  admitted artifact's rendered element types, plus the admitted scaffolding. The build takes σ from
  the resolution record it already holds. It never re-reads the Mode line, and never infers σ from
  the destination, from which files exist, or from the request.
- **S2 — Fill.** Inside the admitted shape, content comes from each section's single § 9.1 authority.
  **An admitted artifact that is absent does not shrink the shape**: the walk reads it as a degraded
  read, failing closed, never as a clean smaller site. On a healthy trip in a plan mode this cannot
  fire: the hub writes the links reference and the venue matrix before the itinerary, and the event
  status exists by the first synthesis. An authority that is present but empty renders its section's
  declared empty state, as the Booking Checklist's *all booked* state already does; scaffolding with
  nothing to say is not emitted. A non-admitted artifact that exists is not rendered and, where its
  class is `bound`, is named per state in § 9.3.
- **S3 — Reach is mode-blind.** The class (`reference/data-architecture.md` § 5.1) and `may-carry`
  (`ADR-026` § 3) decide what may be carried; σ never widens or narrows either. The render table
  decides only whether a state's build **produces** a render of an admissible artifact. No cell may
  admit, in any state, a form the class and the private-site record's verdict would not admit in every
  state.
- **S4 — Limb-blind.** The shape is keyed on σ, never on the publish limb. The render is written before
  any limb is chosen and both limbs ship that one page, so **the shape model neither needs nor supplies
  a build-time limb input.** No fill differs by limb: the public path's refusal of group-only content
  is the private-site record's safeguard 2, keyed on structure.
- **Grain.** σ acts on whole artifacts. Element dispositions inside a rendered artifact are mode-blind,
  so no element fence gains a mode column. A disposition that varies by mode would be a change to this
  rule, made only by a record and run through the ceiling. This record makes none: the hero's pre-plan
  form is a component variant, not an element disposition.

**Falsification.**

- **F1 — existence changes nothing.** Two builds in the same σ that differ only in whether some
  artifact exists show the **same** sections and navigation; the build missing an admitted artifact
  reports a degraded walk. *Under the wrong model — shape by existence — a reader would see sections
  appear and vanish with files, and the shortlist reappear beside a chosen destination.*
- **F2 — mode changes exactly what is declared.** Two builds that differ only in σ show section sets
  that differ by exactly the table's difference: nothing between any two plan modes, and the declared
  difference between IDEATION and a plan mode. *Under per-phase surfaces a reader would lose the
  surface at every transition; under a client-side switch, every earlier phase would sit inside every
  later ciphertext.*
- **What would show this model wrong:** a reader-facing need that only a separate surface can meet —
  a different audience per phase, which `ADR-026` would make a different channel — or a transition
  whose content cannot be expressed as a state row.

**The declared-phase residual.** The site follows the operator's declaration, not the group's
conversation. A group re-arguing the destination while the trip still reads DISCOVERY sees the
plan-phase site until someone runs `/trip-record mode`. `G5` forbids inferring otherwise.

**The refresh obligation this shape creates** is named here and its policy set in § 6. A change of
state is a change of shape, so the published render is out of date until it is rebuilt **and**
republished. A rebuild is already observable: the Mode line lives in `trip-context.md`, a declared
input of `site`, so `itinerary-to-build` reads `BEHIND` after any `/trip-record mode`. Automating a
rebuild or a republish belongs to the living-site milestone.

### 2. The round-trip contract, extended past the itinerary across its surfaces

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
  group snapshot's production gate is an agent-side branch and does take a row (§ 9).
- **Render-table rows name their modes explicitly.** `any` is not used: under `G7`'s grammar it admits
  `UNSET`.

### 3. The section-growth ceiling

A proposed addition goes through four tests, in order. The first test that decides returns the
disposition; only a proposal that passes all four earns a section.

| Test | The question, answered from a declared table | If it decides |
|---|---|---|
| **Q1 Source** | Does it render plan content — an element type with a § 9.1 authority? | **No → scaffolding (D1).** Admitted only under § 9.2's additive clause: no plan content, reads only what the build already reads, not emitted when empty, no navigation entry |
| **Q2 Reach** | Is every value it renders readable in every state it targets — an authority that is `bound`, not denied by the § 5.6 value fence, and admitted by `may-carry`? | **No → blocked (D0).** Not a ceiling question; it goes to the class owner or the verdict |
| **Q3 Representability** | Can an existing § 3 component carry its element type as a field, a variant, or an entry in an existing region? | **Yes → a field or variant (D2)** of that component — § 9.5's test, applied at section level |
| **Q4 Placement** | Is its element keyed to a unit an existing section already iterates over — a day, a track, a booking item? | **Yes → a region (D3)** of that section; a new component is allowed only because Q3 found none |
| — | none of the four decided | **A section (D4)**, with its render-table rows, its element-fence rows and its declared empty state |

**Mode never earns a section by itself.** A proposal whose only ground is that one mode would like the
same content shown differently is a variant, under Q3; that is why the four plan modes share one
shape. #87 consumes Q3 and Q4 as its card-type questions.

**Calibration** — the ladder reproduces every disposition the corpus already decided:

| Case | Q1 | Q2 | Q3 | Q4 | Ladder | Corpus |
|---|---|---|---|---|---|---|
| Booking Checklist | the itinerary's checklist element | `bound` | no component renders a list spanning days ordered by action date | not per-day | **D4 section** | a section |
| Split-Day | the Parallel Track | `bound` | none could | per-day | **D3 region** | a region of one day |
| Nightlife decline | a line of the itinerary | `bound` | the band carries it | — | **D2 field** | no new card type |
| Coordination Notice | no plan source | — | — | — | **D1 scaffolding** | carried by no § 9 table |

**The worked example: an ENRICHMENT *Flights & lodging* section → NO.** Q1 passes: the facts belong to
the trip context, whose § 9.1 row already feeds the hero and the overview. Q2 passes: the trip context
is `bound`, and no § 5.6 row is scoped to it. **Q3 decides**: the Overview Dashboard and the Hero's
stats grid already carry the trip context's trip-level facts. It is **a field of the Overview
Dashboard**, filled when present in any plan mode and not emitted when absent, with no section, no
render-table row and no mode gate.

**The ladder, run on this record's own additions:**

| Proposal | Q1 | Q2 | Q3 | Q4 | Result |
|---|---|---|---|---|---|
| **The destination shortlist** | its elements, with a § 9.1 authority row when it becomes `bound` | `bound` once moved; its values are in the private-site record's IN list; no § 5.6 row scopes it | no component represents a destination candidate | trip-level, not per-day | **D4: a section, `group-shortlist`** |
| **The concealed occasion** | an itinerary event | the concealed form carries only plan facts | the schedule-timeline entry can carry it | — | **D2: an `is-concealed` variant** of the schedule entry; no new card type |
| **The group snapshot** | its elements, with a § 9.1 authority row when its class lands | `bound`; every value in the private-site record's IN list; no § 5.6 row scopes it | no § 3 component carries a per-traveller record | keyed to a person, and no section iterates people | **D4: a section, `group-snapshot`** |
| **The group contacts file**, by citation to [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md) | its elements, with a § 9.1 authority row when its class lands | `bound`; every rendered value admitted by that record; the one § 5.6 row involved names a value the file never carries | no component carries a per-traveller record in every state | keyed to a traveller, and no section iterates travellers in every state | **D4: a section, `group-contacts`** |

### 4. The map — what each state's build renders, and where

The map is indexed on what each state's build **renders**, never on which artifacts exist.

**One row per state.**

| State σ | The build | What it renders | § 9.3 artifact exclusions for the state |
|---|---|---|---|
| IDEATION × UNDECIDED (*No destination yet*) | RUN | the trip context → the hero, pre-plan variant · the shortlist → the shortlist section · the group snapshot → its section · the group contacts file → its section | the itinerary, the links reference, the venue matrix, the event status |
| IDEATION × DECIDED (*Destination in play*) | RUN | the trip context → the hero, pre-plan variant naming the destination in play · the group snapshot → its section · the group contacts file → its section | the shortlist, and the itinerary, the links reference, the venue matrix, the event status |
| DISCOVERY, ENRICHMENT, ITERATION or RESEQUENCING × DECIDED | RUN | the plan-phase shape below, and the group contacts file → its section | the shortlist and the group snapshot |
| a plan mode × UNDECIDED | a declared non-row: the verb's own stop (§ 5) | — | — |
| `UNSET` × any | REFUSE, by `G7` | — | — |
| `ARCHIVED` | not served; the lifecycle cell | a declared non-row | — |

**The plan-mode rows are identical by decision**: the ceiling rejects every section specific to one
plan mode, so the only difference in shape between modes lies in IDEATION's rows. The plan-phase shape
is today's site with one section added in every plan mode: the group contacts section, which the
contact and emergency record's carrier fills.

**The plan-phase shape, class by class.**

| Class | `publish:` | In the four plan modes | Home |
|---|---|---|---|
| `trip-context.md` | `bound` | rendered | the Hero Section and the Overview Dashboard: group, dates, home base, trip-level constraints |
| `outputs/final-itinerary.md` | `bound` | rendered, and walked | element grain: `round-trip-contract-elements`, unchanged |
| `outputs/links-reference.md` | `bound` | rendered, a supporting source | every map link, and every website, tickets and booking link |
| `outputs/venue-matrix.md` | `bound` | rendered, a supporting source | day placement and de-duplication in the Day sections and the alternatives grid |
| `outputs/event-status.md` | `bound` | rendered, a supporting source | the Booking Checklist's membership, and every card's booking pill |
| `outputs/group-contacts.md` | `bound`, from the contact and emergency record's slice | rendered | the group contacts section |
| `outputs/destination-shortlist.md` | `bound`, from the render slice | excluded (state), named in § 9.3 | — |
| `outputs/group-snapshot.md` | `bound`, from its slice | excluded (state), named in § 9.3 | — |
| `travelers/<traveler>.md` · `outputs/traveler-model.md` | `internal` · `internal-hard` | excluded by class; never a build input | the traveller model's § 9.3 residual row is retained |
| `outputs/traveler-presence.md`, decided by `ADR-028` § 2 | `internal`, as declared | excluded by class, with no map edit when its slice lands | — |
| `people/<person>.md` and the group store | `internal-hard` | outside the map: not per-trip, and no build input reaches them | a value from the person record reaches a page only as its producer carries it, through the traveller model, into the shortlist, the itinerary or the group snapshot |
| the satisfaction metrics, the change summary, the log, the spoke lists, the itinerary versions, the validation report, targeted research, the cost estimate | `internal` or `internal-hard` | excluded by class | the change summary is read only for the Coordination Notice's state and date |
| scaffolding: `<sticky-navigation>` · `<coordination-notice>` · `<reference-matter>` | — | admitted | the Coordination Notice keeps § 3's rule of not emitting when empty |

**The render-table rows**, shown as a table rather than as a fence, because a fenced copy would be a
second declaring site.

| artifact | modes | destination | disposition | home |
|---|---|---|---|---|
| `trip-context.md` | DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | rendered | `hero-section` · `overview-dashboard` |
| `trip-context.md` | IDEATION | UNDECIDED, DECIDED | rendered | `hero-section`, pre-plan variant |
| `outputs/final-itinerary.md` | DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | rendered | `elements:round-trip-contract-elements` |
| `outputs/links-reference.md` | the same plan modes | DECIDED | rendered | `map-link` |
| `outputs/venue-matrix.md` | the same plan modes | DECIDED | rendered | `day-grid` · `alt-grid` |
| `outputs/event-status.md` | the same plan modes | DECIDED | rendered | `booking-checklist` |
| the itinerary, the links reference, the venue matrix, the event status | IDEATION | UNDECIDED, DECIDED | excluded | named in § 9.3 |
| `outputs/destination-shortlist.md` | IDEATION | UNDECIDED | rendered | `elements:round-trip-contract-elements-destination-shortlist` → `group-shortlist` |
| `outputs/destination-shortlist.md` | IDEATION | DECIDED | excluded | named in § 9.3 |
| `outputs/destination-shortlist.md` | the plan modes | DECIDED | excluded | named in § 9.3 |
| `outputs/group-snapshot.md` | IDEATION | UNDECIDED, DECIDED | rendered | `elements:round-trip-contract-elements-group-snapshot` → `group-snapshot` |
| `outputs/group-snapshot.md` | the plan modes | DECIDED | excluded | named in § 9.3 |
| `outputs/group-contacts.md` | IDEATION | UNDECIDED, DECIDED | rendered | `elements:round-trip-contract-elements-group-contacts` → `group-contacts` |
| `outputs/group-contacts.md` | the plan modes | DECIDED | rendered | the same |
| `<sticky-navigation>` · `<coordination-notice>` · `<reference-matter>` | the plan modes | DECIDED | rendered | their § 3 components |
| `<sticky-navigation>` · `<coordination-notice>` · `<reference-matter>` | IDEATION | UNDECIDED, DECIDED | excluded | IDEATION renders no plan: no Day sections to navigate, no plan change to announce, no front or back matter |

- The proposed tokens — `group-shortlist`, `group-snapshot`, `group-contacts`, `is-concealed` and
  the new fence names — stay proposed, and Wave 1 re-measures them at its own base.

**The group contacts rows** are the contact and emergency record's carrier, placed here by citation to
[that record](ADR-031-contact-emergency-group-visibility.md). The ceiling returns a section for it
(§ 3), which renders in every state the site builds — both IDEATION rows and the four plan modes — and
takes no § 9.3 row, because nothing of it is excluded in any built state. For each traveller who
filed their own form it carries their in-trip contact, when they chose to share it, and their
emergency line in one of three states: the contact's name, shown only on the traveller's attestation
that the contact agreed, with a note that the organizer holds how to reach them; *on file with the
organizer*; or *no emergency contact on file*. The way to reach an emergency contact and the
relationship are never shown. Its three states follow the snapshot's rule: present with entries →
rendered; present with none → a neutral declared empty state; absent → a degraded read, with the remedy
`/trip-record travelers`. What the file carries, who writes it and why each line holds are that
record's. **The organizer line** — who to tell if something happens — is not a section: it is a field
of the hero, rendered from the `## Group` roster alone in every state the site builds, under the
content rules that record states.

**The § 9.3 rows.**

| Excluded | Where | Why |
|---|---|---|
| the destination shortlist | IDEATION × DECIDED, and every plan mode | the destination is recorded, so the ideation question is answered; its producer no longer refreshes it; and a rendered ranking beside the chosen destination would be a second source for *where* |
| the itinerary, the links reference, the venue matrix, the event status | both IDEATION rows | IDEATION's shape is pre-plan; a plan artifact left from an earlier phase is superseded by the declared return |
| the group snapshot | every plan mode | once a plan exists, the plan answers when, from where, where the group stays and at what pace; the snapshot is produced only in IDEATION, so it is no longer refreshed; and a stated preference beside the decided plan would re-open settled choices |
| `Handoff to DISCOVERY`, an element of the shortlist | wherever the shortlist renders | an instruction to whoever operates the engine, not reader content |

**The IDEATION rows in detail.** Both rows cite [the private-site record](ADR-029-what-the-private-site-may-show.md)
as the ground of what they may render.

- **The hero, pre-plan variant** — a D2 variant of the Hero. It never renders a placeholder value: a
  value that begins with `[` and ends with `]` is never an answer. **With no destination recorded, its
  title comes from `trip.slug`**, the only trip-level name the engine holds in that state. With a
  destination in play, it names the destination as under consideration rather than chosen. The
  destination-specific elements of the spec's § 7 take a declared neutral default while the destination
  is undecided; their design is Wave 1's, and #87 consumes it. **The roster renders every traveller's
  name, and a relationship only for a traveller who filed their own form** — the operator's D-1. Where
  the build cannot read a filer predicate from a `bound` artifact, **it shows no relationship for
  anyone**: it fails closed. The Wave-1 item that excludes people who did not fill in their own form
  names that predicate; the group snapshot is not it, because its entries also leave out a refuser.
- **The shortlist section**, in *No destination yet* only. It renders the shortlist at the heading grain
  its schema declares, adding no entry marker:

  | Element | Disposition | Home |
  |---|---|---|
  | `Group Destination Shortlist [DERIVED]` | rendered | the section title; the frame blockquote beneath it renders as the standfirst; the `[DERIVED]` mark is provenance metadata and is not rendered |
  | `Shortlist (ranked)` | rendered | the ranked candidate entries |
  | `Vetoes applied (Rather skip)` | rendered | the vetoes, with their reasons as the writer leaves them (below) |
  | `Conflicts & coverage` | rendered | conflicts, and coverage per traveller |
  | `Handoff to DISCOVERY` | **excluded** — a § 9.3 element row | an instruction to the operator, not reader content |
  | `<artifact-frontmatter>` | excluded | the residual every element fence carries |

  **Its three states**, none inferred from existence: present with a ranking → rendered; present with an
  empty ranking → its declared empty state, the vetoes, gaps and request rendered as written; absent → a
  degraded read, never a smaller site, with the remedy `/trip ideas`.
- **The source binding, by citation.** The leanings this section renders carry one class in both
  enrichment states: the class of their source of record, `outputs/traveler-model.md`, as the
  private-site record's reach clause states it. The shortlist writer's fallback read of
  `travelers/<traveler>.md`, and the durable `people/<person>.md` fields the model carries, change only
  where the bytes come from, never the bound. The build reads none of the three; it reads the
  shortlist. The verdict admits the leanings and the shortlist on the private site, so the first of
  the three branches Step 0 named holds: the rendered form is the shortlist as its agent writes it,
  bounded by the rule on people who did not file. Neither the aggregate-only branch nor the no-home
  branch arises. On the public limb nothing personal is published: the render is limb-blind, and the
  public path's refusal of group-only content is the private-site record's.
- **The shortlist's writer owes two rules**, both Wave 1. It names only people who filed their own form,
  so a line naming a person who did not file is excluded at production. And under the private-site
  record's out-by-kind rule, `agents/destination-ideation.md` joins that record's producer list: a veto
  reason that states or implies an OUT kind is left out whole, never trimmed or reworded, while the veto
  line itself stays.
- **The hub planner's IDEATION comparison has no artifact.** `agents/05-hub-planner.md` § *Mode Behavior*
  describes an IDEATION output — a destination's appeal, its key tradeoffs, a best-fit traveller profile
  and a verdict — with no declared file: the agent names no file for it, its output format declares
  none, and no § 1.1 class matches it. The build renders artifacts only, so it has no rendered home in
  any state; the *Destination in play* row names it as not rendered, with that reason, so the absence
  is declared rather than silent. It takes no § 9.3 row and no render-table row, because it is not a
  class. Declaring one is routed to a follow-on card with two constraints: it is a new class, and its
  content is not bounded by the private-site record's lists at production — key tradeoffs routinely
  carry cost, and a best-fit profile can carry a need.

**The shortlist after IDEATION — the page moves on** (the operator's D-4). The shortlist is excluded in
IDEATION × DECIDED and in every plan mode, each state named in § 9.3 with one reason in three parts:
once a destination is recorded the question the shortlist answers is closed, and `/trip ideas` refuses
in that state; its producer, the ideation agent, is skipped once a destination is set, so a rendered
shortlist would drift; and a ranking beside the recorded destination would be a second source for
*where*. It persists on disk (`ADR-026` § *Decision* 4), and persistence is not a render. Clearing the
destination returns the trip to *No destination yet*, and the shortlist renders again: the table
follows the declared state in both directions. **No later state renders a form of a leaning wider than
IDEATION's, because no later state renders the shortlist at all.**

**The shortlist's consumer refusal, decided.** Both of its read-back refusals stand verbatim —
`/trip-record` does not read it, and `/trip ideas` never reads it back — each protecting one source for
a chosen destination. The site build becomes its one reader, of the whole file, and only while no
destination is recorded: the one state with no chosen destination for it to be a second source of. No
consumer branches on a candidate-level value, because the element fence is at heading grain and adds
no entry marker.

**How the values the group may see reach the page — by carrier.** The build reads none of
`travelers/<traveler>.md`, `outputs/traveler-model.md` or `people/<person>.md`, in any state. Each keeps
its class, and each takes no render-table row. A value on the private-site record's IN list reaches the
page only through a `bound` artifact that carries it:

| IN item | Held in | The `bound` carrier the build reads | Renders |
|---|---|---|---|
| who is coming: name, relationship | the trip context's `## Group` roster (Person · Role / Relationship) | the trip context | the hero, in every admitted state: every name, and the relationship for filers only (D-1) |
| destination leanings (`Would love`, `Rather skip`, `Trip vibe`) and the shortlist built from them | the person record and the traveller file, reconciled into the traveller model | the shortlist | the shortlist section, IDEATION × UNDECIDED only |
| dates: the trip's own | the trip context | the trip context | the hero, when set |
| dates: can travel, blackout, trip length, per traveller | the traveller file | the group snapshot | IDEATION: the group snapshot |
| arrive and leave, per traveller | the traveller file | the group snapshot | IDEATION: the group snapshot. In plan modes the booked legs render as plan content through the itinerary's trip overview |
| getting there: leaving from, journey comfort | the person record | the group snapshot; the booked origins and legs reach the itinerary as plan content | IDEATION: the group snapshot |
| where you stay: lodging style, rooming | the person record, the traveller file | the group snapshot; the booked property reaches the itinerary | IDEATION: the group snapshot |
| interests and tastes; pace and day rhythm | the person record, the traveller file | the group snapshot; the itinerary, where the plan expresses them | IDEATION: the group snapshot; plan modes: as the plan carries them |
| desires the traveller marks group-facing | the traveller file, with its share mark | the group snapshot, a marked desire's `Desire` text; the itinerary, where the plan lands one | IDEATION: the group snapshot; plan modes: as the plan carries it |
| the special occasion, marked not private | the traveller file, with its share mark | the group snapshot; the itinerary | IDEATION: the group snapshot; plan modes: where the plan carries it |

- **Desires.** A marked desire renders as its own text only in the group snapshot, in IDEATION; in plan
  modes it appears only as the plan carries it. **An unmarked desire is never named** — a rule on the
  hub's itinerary output, owed by Wave 1, because the build renders what the itinerary carries.
- **The occasion, and the concealed block.** Marked not private, it may be named where the plan carries
  it. Private, it is never named. **Private and made a trip event, it renders as the concealed block**:
  in the Day section of its day, at its time, in the schedule timeline — plan modes only, since before a
  plan there is no calendar — showing a generic title, its attendees as the roster spells them and its
  time, **and nothing else**: no venue name, description, map link or marker, booking pill, website or
  ticket link, checklist entry, or transit note naming the venue. The event stays in the itinerary with
  its venue, so it stays planned and bookable, and carries a concealment mark derived from the
  traveller's share mark. The build renders the concealed form for a marked event — a reduced form the
  build produces, where the corpus puts one, since no redaction step exists on the publish path. The
  itinerary stays the day's single authority. **The concealment binds every component that could
  identify the event** — the Booking Checklist, joined by event; booking pills; map links and markers,
  joined by venue; and links. That is a Wave-1 obligation, not a choice left open. The spec's
  location invariant, that an event names a venue and renders a map link on its card, and the
  validator's matching check gain a **stated carve-out** in Wave 1, never a silent exception: the
  concealed block names no venue, so on the page it is not an event.
- **An OUT value stays out by its kind, wherever it is carried.** This record relies on the private-site
  record's out-by-kind rule and restates none of it: the exclusion is the producer's, never a build-side
  redaction.
- **People who did not fill in their own form.** The private-site record's safeguard 3 binds every
  carrier: the shortlist at production, the itinerary where the hub already copies no `[THIRD-PARTY]`
  value, the group snapshot by its population rule (§ 9), the group contacts file by its own, and the
  roster by D-1.

**#1241's acceptance criteria through these rows.** Its shape criterion is met **existentially**: hold a
trip's destination state and flip the mode between IDEATION and any plan mode, and the section and
navigation sets differ by exactly the table's difference — IDEATION × UNDECIDED shows the hero, the
shortlist section, the group snapshot section and the group contacts section; IDEATION × DECIDED shows
the hero, the group snapshot section and the group contacts section; a plan mode shows the hero, the
overview, sticky navigation, the Day sections, the Booking Checklist, reference matter, the Coordination
Notice when its state is stated, and the group contacts section. Among the four plan modes the sets are
equal by decision, so the universal reading — every pair must differ — fails by design, and this record
says so. **Its IDEATION criterion is met by the *No destination yet* row**: a trip in IDEATION with no
destination yields a non-empty page. The contract gates that criterion names — the `site` row and the
shortlist's class — are both lifted by Wave-1 edits this record decides, and `/trip-publish update`
already admits any mode and any destination. The no-form branch does not arise, and that criterion
needs no revisit.

### 5. The build verb's admission, and the pre-plan classes

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
RESEQUENCING · any · G8`. Admission rests on [the private-site record](ADR-029-what-the-private-site-may-show.md):
an IDEATION build has something admissible to render because that record admits the leanings and the
group's shared details on the private site.

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
`outputs/<destination>-travel-site.html`, as today. Every reader already takes any `*-travel-site.html`
member, the newest first. The first build with a destination therefore **creates** a new page rather
than patching the old one (§ 6), and the IDEATION page stays on disk, unpublished by the newest-member
rule. **Its consequence for erasure:** the IDEATION page can hold the shortlist, travellers' leanings
beside their names, the group snapshot and the group contacts section, so the erasure verb's reach
must name **every** `outputs/*-travel-site.html` file — the pattern every reader already uses — not the
destination-named one alone. That is a Wave-1 condition of the slice that lands the stem rule
(CR-2 call 6), and it is why the erasure verb is named among the stem rule's consequences.

**The pre-plan classes.**

| Artifact | `publish:` | Decision |
|---|---|---|
| `outputs/destination-shortlist.md` | `internal` → **`bound`** | decided by the private-site record; the render slice lands it in one commit with its § 9.1 authority and fence rows, so group `PB` stays green |
| `outputs/group-snapshot.md` (new) | — → **`bound`** | decided by this record (§ 9); its slice lands the § 1.1 row with its § 9.1 rows in one commit |
| `outputs/group-contacts.md` (new) | — → **`bound`** | decided by the contact and emergency record |
| `travelers/<traveler>.md` | `internal` | unchanged |
| `outputs/traveler-model.md` · `people/<person>.md` | `internal-hard` | unchanged; the private-site record relaxes their IN values' bound, not their class values |
| the spoke lists | `internal` | unchanged; *Destination in play*'s overview-level spoke output has no rendered home |
| the hub's IDEATION comparison | — | no artifact, so no class |
| the render | `output` | unchanged; its source list gains the three new `bound` classes, in their slices |

**The Reads line.** The shortlist, the group snapshot and the group contacts file each join the `site`
verb's **Reads:** line in every state, with no false `BEHIND`. The shortlist's only dispatcher,
`/trip ideas`, admits IDEATION × UNDECIDED alone, and the snapshot is produced only in IDEATION (§ 9),
so each can lead `itinerary-to-build` only in a state that renders it, where `BEHIND` is true; the
group contacts file renders in every built state, so the reason does not arise for it. `ADR-028`'s
reason for keeping its own class off the line — a class rebuilt while never rendered — therefore does
not apply.

### 6. Transitions, what a traveller was shown, and the refresh obligation

**The render policy: replace, never accumulate.** A build renders exactly its state's row. Content from
a superseded phase is not rendered — not as history, not collapsed, not hidden, because hidden text still
ships inside the ciphertext.

| Transition | What the next build does | How |
|---|---|---|
| IDEATION × UNDECIDED → × DECIDED | the shortlist section goes; the hero names the destination in play; the group snapshot and the group contacts sections stay | **a create**: the file name's stem changes from the trip's slug to the destination, so the verb's existence probe misses and the first build with a destination writes a new page. The IDEATION page stays on disk, unpublished by rule, because publish and both relations take the newest page; nothing is deleted, as `ADR-007` § 2 requires, and erasure reaches both files (§ 5) |
| IDEATION × DECIDED → a plan mode | the plan-phase shape; the group snapshot section leaves; the group contacts section stays | a structural patch of the same file; the shape pass catches a leftover section |
| a plan mode → a plan mode | no change of shape | a patch |
| a plan mode → IDEATION | the plan sections go; the group snapshot section returns; the shortlist returns only if the destination was cleared | a structural patch, or for *No destination yet* the slug-named page, patched if present and created if not |
| any state → `UNSET` | no build | the published page stays at its last build |

**A published page from a superseded phase is a liability, within a bound.** From the transition until
rebuild, confirm and republish, the group sees the superseded phase. The worked instance is the stale
shortlist: the group has chosen a place, and until the site is rebuilt and republished the page still
ranks it beside the places they passed over. **The liability lasts exactly as long as the relation below
reads `BEHIND`.**

**The relation — declared outside `trip.freshness`**, as `ADR-025` § *Decision* 6 requires of a relation
whose derived side is what a traveller was shown.

| Field | Declared value |
|---|---|
| **name** | `build-to-published`, in the shipped `<source>-to-<derived>` form |
| **derived side** | what crossed the channel: the render as last pushed |
| **source side** | the newest local render, the member publish itself takes |
| **observation** | **content identity** |
| **verdicts** | the shipped family, by exact token. `CURRENT` when they are equal; `BEHIND` when they differ, naming the local render as the leading source; `UNDETERMINED` when no push is recorded, naming the published side, or when the render cannot be projected, naming the render |
| **evaluated by** | `/trip-publish list`, in its own report, labelled as outside `trip.freshness` |
| **gating** | none; report-only. The publish verb never branches on freshness |
| **cannot observe** | a push made from another machine; anything outside the projection — the coordination band and the render's declaration block — by design; materiality |

`list` computes its staleness column today by order — the local modification time against the remote
commit's date — with its own tokens. The relation takes the shipped verdicts and the identity
observation, and the `list` edit — `scripts/publish-trip-site.sh`'s `cmd_list` and
`skills/trip-publish/SKILL.md` § *list* — is Wave 1's. `list` stays read-only and never gates.

**The refresh obligation.** Automating any step of it belongs to the living-site milestone.

| Step | Trigger | Signal | Remedy |
|---|---|---|---|
| **R0 reconcile** | a traveller's form, a person record, the roster or a link changes | the verb that made the change names `/trip-record travelers` without running it | `/trip-record travelers` |
| **R1 rebuild** | a change of σ — the trip context written by `/trip-record mode` or `/trip-record destination` — or of an admitted input: the shortlist by `/trip ideas`, the group snapshot and the group contacts file by the reconcile step, the plan artifacts by planning | `itinerary-to-build` reads `BEHIND`, naming the leading source | `/trip site` |
| **R2 confirm** | a rebuild that changes the visible text | the organizer-confirm gate refuses `update` | `confirm`. This is intended under `ADR-003` § *Decision* 2, not a deadlock: `confirm` is always the organizer's, and a digest-only change needs none |
| **R3 republish** | R1 and R2 done | `build-to-published` reads `BEHIND` | `/trip-publish update` |

**A refusal, a removal or a withdrawal reaches the page through R0 to R3.** Under the private-site
record's safeguard 4 it is recorded only through a verb that runs the reconcile step, so every staleness
report shows the page as behind until the organizer's next update carries it; no publish gate is added.

**The shortlist's own staleness case.** A shortlist built from the fallback read and later overtaken by
a model rebuild changes no class. If `/trip ideas` re-runs, R1 to R3 carry the new shortlist to the
page; if it does not, the shortlist against its own inputs is observed by no relation — a declared
residual, since the shortlist is rebuilt only by its own verb.

### 7. Conformance to `ADR-025` and `ADR-026`

| Accepted decision | How this record conforms |
|---|---|
| `ADR-026` § 4, production-gating | Mode conditions what each state's build renders, through one render table. Reach is unchanged in every state, and no state is inferred from which files exist. The group snapshot, produced only in IDEATION, is one more instance |
| `ADR-026` § 3, `may-carry` | Nothing crosses CH-1 that the class and the private-site record's verdict do not admit in every state. The render is limb-blind. No redaction step is added: the concealed block is a reduced form the build produces |
| `ADR-026` § 5, the R-rule | The build emits no value `may-carry` denies. The traveller file, the model and the person record are never read |
| `ADR-026` §§ 1–2, the channel-set | No channel is added: one page and one ciphertext, on both limbs |
| `ADR-026`'s `ARCHIVED` overlay | No render in `ARCHIVED`: a declared non-row |
| `ADR-025` § 1 and § 5 | The group snapshot reads the engagement value to decide its population, at the floor `SELF-STATED`, and never stores or renders it |
| `ADR-025` § 3, the carry rule and never-carries | Rendering carries no class across a boundary. Never-carry 2 holds for every value outside the private-site record's IN list, as that record reads it; the group snapshot is rebuilt each synthesis with no carry-forward, and the axis value is never written |
| `ADR-025` § 4, the render prohibition | Unchanged for values that are out. IN values reach the private page only as the private-site record admits |
| `ADR-025` § 4 and `ADR-010` § 4, the inference of who filed | Governed by the private-site record's pointers into both sections, which carry the sentence on it. This record relies on that sentence and restates none of it |
| `ADR-025` § 6, staleness | `build-to-published` reuses the shipped verdict family and its rules, has no disposition column, is declared by its consumer, and is evaluated outside `trip.freshness` |
| `ADR-028` §§ 2, 4 and 9 | The group snapshot reuses its keying, its write-set widening and its erase-row shape |
| `ADR-006` | No third-party value enters the group snapshot, by its population rule |
| `ADR-004` | The group snapshot carries no contact or emergency value; [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md)'s carrier holds what of them the group sees |
| `ADR-003` § 2 | A transition's or a snapshot change's visible-text change reaches the group only through the organizer's `confirm` (R2) |
| `ADR-007` § 2 | Nothing is deleted at a transition; the IDEATION page stays on disk |
| `ADR-007` § 2, bound 5 | The rebuild announce is not taken for the group snapshot: the class-wide question `ADR-028` § 2 routed covers every `rebuilt-each-synthesis` file a dispatched agent replaces, and this record does not pre-decide it |

**No divergence from a decision is intended.** Two claims in `ADR-026` — § 3's composition of the render
and § 4's sentence on IDEATION — describe the build as it stood when that record was written, and this
release adds a dated pointer to `ADR-026` recording what this record decides.

### 8. `ADR-026` Finding 1 — declined, in terms, and routed

The finding asks for a § 1.1 row for the published artifact, at `<trip>/.publish/index.html`, owed by
whichever card next amends § 1.1 — which this card's slices do. **It is declined here, and routed to a
card of its own**, on four grounds, the limb-independent ones first:

1. **An in-model row would contradict an existing disposition.** § 1.2 disposes of `.publish/` out of
   the model — never traversed by any selector — and a row for the published artifact needs a selector
   inside it. This record cites that disposition by its path, never by an ordinal, because the
   out-of-model rows are renumbered by another milestone's slice.
2. **The published artifact is already governed** on the path that produces it, by two fail-closed
   pre-push predicates.
3. **This record decides the render's content per state**, not the class of the object that crosses the
   channel, which is `ADR-026` § 3's subject.
4. **A corollary on the encrypted limb only.** There the published artifact is ciphertext and cannot
   carry the universal frontmatter every in-model class requires; on `--plaintext` it is the render
   byte for byte and does carry it, which is why this ground is a corollary.

**The route** is an intake observation carrying the orphaned-assignment evidence — the assignment has
already passed two cards, `ADR-027`'s and `ADR-028`'s, that each decided a new § 1.1 class and answered
neither, and an assignment keyed on a future event that nothing checks is a standing exemption — and
the § 1.2 option: an explicit out-of-model row split from the `.publish/` row. This release makes no
§ 1.1 edit. **The new classes this milestone decides**
— the group snapshot here, the group contacts file in the contact and emergency record — are not the
published artifact, and they are what fired the milestone's re-size.

### 9. The group snapshot

**Before there is a plan, the private page gets a section about the people going.** It shows while the
group is choosing where to go, and while a place is being explored but not yet planned; once planning
starts, the plan takes over the page. For each person who filled in their own trip form it shows what
they said, in their own words — when they can travel, where they would set out from, how they like to
stay, eat and pace their days, the wants they chose to share, and the occasion the trip marks if they
said it is not private. A line appears only if the person answered it; nothing is guessed. It is the
operator's D-3, designed on #1388, and it holds G-1 to G-6 whole.

#### G-1 — What it carries

**A closed field list, every row of the private-site record's IN list disposed of by name.** Labels are
spelled exactly as the intake forms spell them; the scope is the one `reference/data-model.md`
§ *Field Scope* assigns.

| IN item | Field | Asked on | Scope | In the snapshot? | Why |
|---|---|---|---|---|---|
| who is coming — name | the roster's `Person` cell | the trip context's `## Group` | — | **no — the entry key only** | the hero renders every name from the trip context (D-1); each entry is headed by the roster display name, a projection of the roster cell, not a second statement of who is coming |
| who is coming — relationship | `Relationship` | the trip form | TRIP | **no** | for a filer the hero renders the roster's *Role / Relationship* cell (D-1); a second relationship text on the same page would give one fact a second home |
| destination leanings and the shortlist | `Would love`, `Rather skip` · `Trip vibe` | the person form · the trip form | DEFAULT · TRIP | **no** | the shortlist section carries them in *No destination yet*; D-4 takes them off the page once a destination is in play |
| dates | `Can travel`, `Blackout`, `Trip length` | the trip form | TRIP | **yes** | no rendered document carries a traveller's own window before a plan; the trip's own dates stay with the hero |
| dates — arrive and leave | `Arrive / leave` | the trip form | TRIP | **yes** | the booked legs reach the page only through the itinerary, in plan modes |
| getting there | `Leaving from`, `Journey comfort` | the person form | DEFAULT | **yes** | — |
| where you stay | `Lodging style` · `Rooming` | the person form · the trip form | DEFAULT · TRIP | **yes** | the booked property reaches the page only through the trip context and the itinerary |
| interests and tastes | `Interests`, `Cuisine appetite` | the person form | DEFAULT | **yes** | — |
| interests and tastes for this destination | `Been here before?`, `Already done` | the trip form | DEST | **yes, only while a destination is recorded** | a DEST value is scoped to one destination; with none recorded it has no referent, so the writer omits both lines — the reason `ADR-025` never-carry 4 gives across trips, applied inside one |
| pace and day rhythm | `Pace`, `Day rhythm` | the person form | DEFAULT | **yes** | — |
| desires the traveller marks group-facing | `Desire` | the trip form's desire block | TRIP | **yes — the `Desire` text of a marked desire, and nothing else of the block** | its priority tier, recurrence and theme tags are planner annotations, and its overlap signal is computed over every desire, marked or not, so carrying it would disclose unmarked desires |
| the special occasion, marked not private | `Special occasion?` | the trip form | TRIP | **yes — only when marked** | unmarked means private, and a private occasion leaves no trace: no line, no placeholder, nothing saying something is withheld |

**What a line carries.** The value the traveller model carries for that label, verbatim — carried
through, not computed. A DEFAULT field is the composed value: the person record's, unless the trip form
answers it. **A line is carried only when its value is answered** — absent, blank, an em dash, a
surviving bracketed placeholder and a lapsed horizon are not answers — and **no line carries a
bracketed mark of any kind**, provenance or horizon.

**Never carried**, named so the list is closed in both directions: `Party`, `Passport`, `Documents`,
`Comfort range`, `Splurge appetite`, the needs block (`Category`, `Specific`, `Applies to`), `Novelty vs
comfort`, `Planning style`, `Group time`, `Split off with`, `Whole-group moments`, `Solo, I'd`, the
free-text tail, update signals, divergence reports, and the engagement value itself (`ADR-025`
never-carry 5).

**The list changes only by a record decision.** A value outside it is never admitted by the writer's
judgment. That is this class's tripwire in `ADR-011` decision 6's form, inverted: the class never moves;
the list does, and only in terms.

#### G-2 — Whose data it carries

**The population.** An entry exists only for a roster member whose engagement value (`ADR-025`
§ *Decision* 1) is **`SELF-STATED` or `PERSON-LINKED`** — a traveller-model entry projected from the
person's own `travelers/<traveler>.md`, composed with their own `people/<person>.md` where it is linked.
In `ADR-025` § 5's terms the snapshot declares its floor at **`SELF-STATED`**, the stricter first-party
reading that section names for a consumer needing one.

| Engagement value | In the snapshot? | Why |
|---|---|---|
| `PERSON-LINKED` · `SELF-STATED` | yes | they filed their own form |
| `OPERATOR-STATED` | **no** | the operator relayed the values; the person did not fill in their own form (the private-site record's safeguard 3) |
| `THIRD-PARTY-STATED` | **no** | `ADR-006`; the entry carries needs only |
| `UNSOURCED` — no entry, a missing profile, or a blank form | **no** | nothing first-party is held |
| `ENGAGEMENT-UNDETERMINED` | **no**, and the pass says so | fail closed: a read that did not complete admits no one |

**Also excluded:** an erased member, on every later pass, and a traveller who has recorded a refusal
(the private-site record's safeguard 4, whose capture is Wave 1's). **An entry is written only when at
least one line survives the list, the mark rule and the withhold rule.** A non-filer, a refuser and a
filer with nothing to show all look the same — no entry — and **the page never says which**, so a
refusal is never itself disclosed. The engagement value decides the population and is never written or
rendered.

**Keying.** `## <Name>`, the `## Group` roster's display name — the Traveler natural key, as `ADR-028`
§ 2 keys the presence file. The roster is the display-name authority; a person token is never used.

**People who did not fill in their own form** (D-1). Their roster name shows through the hero, and
nothing else about them does: no entry, and — by the withhold rule — no line in anyone else's entry
that names or describes them.

**Desires and the occasion.** A desire is carried only when the traveller has marked it group-facing,
and the occasion only when it is marked not private — the private-site record's share mark, whose
representation is Wave 1's. **An absent or malformed mark reads as unmarked.**

**The withhold rule — OUT binds by kind, not by carrier.** This is D-2's "out everywhere", applied at
the one producer this record adds. **A carried line is withheld whole — never trimmed, never
paraphrased — when its value states or implies any OUT kind:**

| OUT kind | A line that would be withheld | Where the example comes from |
|---|---|---|
| a need or must-have | `Lodging style:` "hotel; need a lift rather than stairs" | the person form's own `Lodging style` example |
| money | `Rooming:` "own room if it's affordable" | the trip form's own `Rooming` example |
| a person who did not fill in their own form | `Special occasion?:` "Mum's 70th, on the Thursday", where that person is a non-filer | the trip form's own `Special occasion?` example |
| togetherness, or a split | `Rooming:` "my own room, away from Sam" | — |
| identification, or contact details | an address written into `Leaving from` | — |

**Why withhold rather than trim.** Trimming publishes words the traveller did not write, against the
reconciler's own rule that it never authors or rewrites a traveller's own words. Withholding costs
coverage and never misstates anyone; a traveller who wants the line shown can reword it, and the
notice (the private-site record's safeguard 1) is where they learn that.

#### G-3 — Who writes it, and when

**The writer: the enrichment agent, in its reconciler role only**, never its research role — one
writer, as § 1.1 requires. It already reads every input — each `travelers/<traveler>.md`, the linked
person record, `trip-context.md` and the model it replaces; it already carries every IN field into the
model by its label; and it is the one component that computes who filed, since its missing-profile
branch is `ADR-025`'s evaluator. **So the snapshot adds no read and no agent.** `ADR-028` § 4 widened
the same role's write set by the presence file, and this is the same kind of extension.

**Its source.** As designed, the snapshot is a projection of the traveller model the same pass writes,
read and never re-derived, and the reconciler's composed source stays "a value, not a file", never
materialised. **The private-site record's safeguard 7 (decision Q) re-points that input:** no agent step
that writes a file the site build reads receives a value of the non-publishable field class, so the
step that writes the snapshot reads the script-made projection of the traveller data that omits the
class, and the writing of internal files from full inputs is split from the writing of group-visible
files from the projection. **Carried to Wave 1, as conditions by citation to
[the private-site record](ADR-029-what-the-private-site-may-show.md):** the projection script; that
split; and the snapshot's writer input re-pointed to the projection. G-1's list carries no member of
that class, so what the snapshot carries is unchanged by it.

**When: production is gated on the declared mode.** The reconciler writes the snapshot **on a pass
whose resolved mode is IDEATION, in either destination state, and on no other pass.** Outside IDEATION it
leaves the file untouched on disk: not rewritten, not deleted. The mode comes from the dispatching verb's
resolved record and is never inferred. This is `ADR-026` § *Decision* 4 exactly: mode conditions
production, never reach.

**Why the gate.** The site declares the snapshot on its **Reads:** line, which is the source side of
`itinerary-to-build`. A file rewritten on plan-mode passes would raise a `BEHIND` that a rebuild clears
without changing the page — the false `BEHIND` `ADR-028` § 2 kept the presence file off that line to
avoid. Producing the snapshot only in the states that render it is the shortlist's argument, reused: it
joins the Reads line in every state, and it can lead `itinerary-to-build` only where `BEHIND` is true.
The gate is an agent-side branch on the mode, so **the Wave-1 slice registers it** in the mode-gated
behaviour register; **until that row lands, the branch is ungraded**, and this record says so.

**Lifecycle: `rebuilt-each-synthesis`.** Rebuilt whole on every IDEATION pass; never appended, never
versioned. There is no carry-forward exception: `ADR-025` never-carry 1 applies without the traveller
model's third-party carve-out, because no third-party entry can enter this file. On an `ARCHIVED`
trip no pass runs.

**The rebuild announce.** `ADR-007` § 2 bound 5's announce is **not** taken for this file. The
class-wide question `ADR-028` § 2 routed covers every `rebuilt-each-synthesis` file a dispatched agent
replaces, this one included, and this record does not pre-decide it. The change a group would see is
confirmed by the organizer at R2 before it reaches them.

**Erasure.** `/trip-record erase` reaches the snapshot directly, by a reach row the landing slice appends
at its own base in `ADR-028` § 9's shape. It **deletes the subject's entry whole**, with **no
tombstone and no token**: the roster row already carries the trip's tombstone, the file holds no
independent state, and a tokenized entry would publish an erased person's values under a pseudonym.
It **never skips silently**. The row's text is Wave 1's.

**Currency — how it stays current when a traveller edits their form.** Report-only throughout: no gate
blocks on any of it (`CLAUDE.md` G8; `/trip-publish` rule 7). The chain is R0 to R3 in § 6: the named
reconcile step rewrites the snapshot, `itinerary-to-build` reads `BEHIND`, the organizer confirms, and
`build-to-published` reads `BEHIND` until the republish. **A form edited by hand** is observed by nothing
until the next reconciler pass, whose profile-change detection catches it — a declared residual, the
one the shortlist already carries and the model carries today. **No new relation is added**.

**Safeguard 4 for this document.** A refusal, a removal from the roster or an erasure is honoured **at
the snapshot's next rebuild, by construction**: nothing is carried forward, and a refuser or a departed
member gets no entry. Erasure reaches the file at once. Reaching the published page takes R1 to R3
(§ 6), which are report-only.

#### G-4 — Its class

**`outputs/group-snapshot.md`** — writer `enrichment`, lifecycle `rebuilt-each-synthesis`, provenance
`derived`, **`publish: bound`**, primary entities Traveler and Desire. It is named by path, never by
ordinal, because the enumeration's numbering moves (`ADR-028` § 2's rule, reused). It takes a § 1.1
row; a § 9.1 authority row and a `publish-contract-artifacts` fence row, which land with the
§ 1.1 row in one commit so that group `PB` stays green; and the element fence below. Wave 1 lands
each of them and writes its text, and none is edited in this release.

**§ 5.6: no row.** The file carries no `Passport` or `Documents` field and no `[THIRD-PARTY]` entry, by
its own population rule. A row naming a pair outside those the evaluator queries would parse and then
abort every publish as `UNDETERMINED`.

**Why `bound`, and not `internal` or `internal-hard`.** It exists to be rendered, and every value in it
is IN on the private site by the private-site record's verdict. `internal-hard` is reserved for a class
whose values must not reach a rendered page in any form (`reference/data-architecture.md` § 5.1), and
the one class that holds these values that way, the traveller model, keeps that class unchanged.

**The element fence** `round-trip-contract-elements-group-snapshot`, at the label grain the class's
schema declares, graded against the writer's grammar block; its rows follow G-1's list, and their
text is Wave 1's.

#### G-5 — Where it shows

**The ladder** returns **D4, a section**, `group-snapshot` (§ 3): no § 3 component carries a
per-traveller record — the Hero is a trip-level banner with a line of names, the shortlist section is
keyed by candidate, and the Overview Dashboard is keyed by day and not admitted in IDEATION — and no
section iterates people. Mode earns nothing here: the ground is a new source artifact whose element type
no component represents, not a mode wanting content shown differently.

**Per state** (§ 4): rendered in *No destination yet* and in *Destination in play*; excluded, and named
in § 9.3, in every plan mode, which keep today's shape plus the group contacts section.

**Its three states**, none inferred from existence: present with entries → rendered; present with none
→ **the declared empty state**, a neutral line that gives no reason; absent → **a degraded read, never a
smaller site** — the walk exits degraded, the verb does not present the site as current, and the remedy
is `/trip-record travelers`. Where the section sits, its title and its frame line are Wave 1's layout
and words; the frame says it is what travellers chose to share, in their own words, and that it is not
a plan.

#### G-6 — What never happens

| Never | How it holds |
|---|---|
| **anything from the OUT list** | three layers. **The field list:** no OUT field is on it (G-1). **The population:** no non-filer, operator-relayed, third-party, erased or refusing member gets an entry (G-2). **The withhold rule:** content that is out, inside a carried value, withholds the line (G-2). Money: no `Comfort range` or `Splurge appetite`, and money in a value withholds it. Identification: no `Passport` or `Documents`. Needs: no needs block, and a need in a value withholds it. Non-filers and a traveller's `Party` entry: never carried, never named or described. Contact and emergency details: none carried, and an address or a number withholds the line; what of them the group sees is [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md)'s carrier. Planner internals and cross-trip group records: never read or carried. Unmarked desires, novelty against comfort, planning style, togetherness, *split off with*, satisfaction metrics: not on the list, and the overlap signal is excluded because it would disclose unmarked desires |
| **a public page** | the render is limb-blind, and every value in the section is group-only by construction. The private-site record's public-path refusal covers this section **by its presence alone** — a structural key, with no matching on values, which paraphrase would defeat — and no redaction step is added |
| **going live before the rotation fix** | the private-site record's fifth safeguard binds every Wave-1 slice of this document — the class, the writer and the section: none goes live before the fix for the rotation defect tracked privately ships |

**The notice couples with the snapshot.** The private-site record's safeguard 1 is how a traveller learns
what the snapshot shows, what the share mark does and why a mixed answer is left out, so it states G-1's
list, the mark rule and the withhold rule. The forms' own example answers that put content that is out
in an IN line — the person form's `Lodging style`, the trip form's `Rooming` and `Special occasion?` —
are replaced in the same edit.

## Consequences

**Positive**

- **#1241's shape and IDEATION criteria are met**, and the site follows every declared state except
  `UNSET`: a trip can move back and forth between *No destination yet* and *Destination in play*, and
  into planning, with the page following.
- **Completeness becomes checkable per state.** The walk's artifact pass runs over the `bound` set, and
  an artifact excluded by its class needs no listing. That the build reads the declared phase becomes a
  graded property through the shape pass, even though the plan modes resolve to one shape.
- **The section ceiling returns a yes or a no**, calibrated on the decided cases; #87 consumes Q3 and Q4.
- **The page before a plan carries what the group needs to coordinate** — who can travel when, from where
  and how each likes to travel, in the group snapshot — and *Destination in play* is no longer the hero
  alone. Every item on the private-site record's IN list has a rendered home before a plan, or a named
  reason why not.
- **In a plan mode a traveller sees today's site, plus the group contacts section.**
- **The stale published shortlist has a declared signal**, `build-to-published`, a remedy (R1 to R3) and
  an owner for its automation, the living-site milestone.
- **The shortlist's refusal keeps its purpose**: one source for a chosen destination.
- **The concealed occasion has a whole-page rule**: every component that could identify the event is
  bound by it.
- **New classes are cheap and forced.** A class that is not `bound` costs no map edit; a new `bound` class
  costs one row per admitted state, and the contract half turns the check red until those rows exist.
- **No new agent, no new read and no new writer role for the group snapshot**, and refusal, removal and
  erasure reach it by construction at its next rebuild, because nothing in it is carried forward.

**Costs and residuals, stated rather than smoothed**

- **The contract surface grows** by one render-table fence, a family of walker passes, two finding codes
  and their arms — each bounded, declared and graded.
- **The walker needs σ from the verb.** A standalone run without it gets only the element pass, and says
  so.
- **The site follows the operator's declaration**, not the group's conversation.
- **The plan modes share one shape**, so the shape criterion hinges on IDEATION.
- **Transitions that change visible text ask for the organizer's confirmation**, by `ADR-003`'s own
  logic; that is new behaviour.
- **The verb index lists `site` as RUN for a plan mode with no destination**, and the verb then stops —
  the declared residual `check` already carries.
- **The IDEATION page stays on disk** after the first build with a destination. It is inert by the
  newest-member rule, and erasure must reach it (§ 5).
- **Reference matter has no § 3 component**, so the shape pass cannot see it.
- **The concealed block lists its attendees**, by the private-site record's decided form, so a block
  whose attendee list leaves one traveller out can itself tell that traveller something is planned. That
  is a residual of the decided form, not re-opened here.
- **`build-to-published` cannot see a push made from another machine**, and the shortlist against its own
  inputs is observed by no relation.
- **New rules sit on producers** — the hub's concealment mark and naming rules, the shortlist writer's
  filer and withhold rules, and the reconciler's snapshot rules — and are graded only where Wave 1 adds
  arms. The snapshot's withhold rule is conduct; only its labels are graded.
- **A mode branch in an agent**, graded only once the register row lands.
- **A form edited by hand is not observed until the next reconciler pass**, and a publish in between
  shows the old entry.
- **On a return from a plan mode to IDEATION**, the snapshot on disk is as of its last IDEATION pass until
  reconciled; the `mode` verb names the step.
- **An absent snapshot makes an IDEATION build degraded** — one more step, `/trip-record travelers`,
  before a first pre-plan site.
- **Filer status is inferable on the private page**, as the private-site record states.
- **Pre-plan details leave the page when planning starts**, rooming preferences before rooms are booked
  among them; a later record can admit a field into a plan mode through the ceiling.
- **An answer given for an earlier destination cannot be detected** after the destination changes; the
  traveller's form owns it, as it does for the plan.
- **The hub planner's IDEATION comparison has no rendered home** until its follow-on lands.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| an undispositioned `bound` class — the contract half | the walker's exit contract, "Exit 0 clean, 1 findings, 2 degraded read."; graded as a group `W` arm in the required artifact-schema suite | the walker's contract run can exit with findings when a class turns `bound` without its render-table rows, and the arm's failure blocks a merge, so a class cannot become renderable without its rows for every admitted state |
| a surplus component — the instance half | the `site` verb: "This verb adds no verdict of its own and suppresses none of the script's." | a stale section left after a transition makes the verb report the site as not current; nothing else changes |
| an admitted artifact that cannot be read — the shortlist, the group snapshot or the group contacts file absent in a state that renders it | the walker's exit contract | a degraded read; the verb withholds "current"; nothing else blocks |
| the new finding codes | group `W`'s inventory: "A code added to the walker with no arm behind it is RED rather than latent" | neither code can ship ungraded |
| the stop for a plan mode with no destination | the verb index: "a verb the table admits can still stop inside its own section" | a declared residual; no aggregate changes |
| `build-to-published` reads `BEHIND` | `/trip-publish` rule 7: "It never branches on freshness, and adds no gate that blocks on it." | report-only |
| a transition's, or a snapshot change's, visible-text change | the organizer-confirm gate, whose proceed set is the organizer's own confirmation | `update` waits for `confirm` — intended under `ADR-003` |
| the concealed block against the location invariant | the validator: "Every event must resolve to a map link … and render it on its card." | without the stated carve-out a concealed event would read as a broken card — a Wave-1 obligation |
| the group snapshot joins the `bound` set | group `PB`: "the publish-bound artifact set matches the spec fence that declares it." | a § 1.1 cell landed without its fence row, or the reverse, fails a required check, so both land in one commit — by design |
| content that is out, inside a carried snapshot value | located nowhere | **unverified by design, and declared rather than asserted as fine**: no rule reads value content on the private limb; the withhold rule is conduct, and only the labels are graded |

**The non-blocking claims hold.** The walk's findings never block a build's write or a publish; the
shown relation never gates a publish; the snapshot's staleness never gates a build or a publish. The
contract half is deliberately **not** non-blocking: it gates merges through the required suite.

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `skills/trip/SKILL.md` | the `site` row; the verb's own section: the stop for a plan mode with no destination, the stem rule, the shortlist, the group snapshot and the group contacts file on the Reads line, σ passed to the walker; `plan`'s naming of the snapshot write, with its condition |
| `reference/site-layout-spec.md` | § 3: the `group-shortlist`, `group-snapshot` and `group-contacts` sections, the hero's pre-plan variant, the `is-concealed` variant and the location-invariant carve-out. § 9.1: the new authority and fence rows. § 9.2: the render-table fence and the new element fences. § 9.3: the state rows. § 9.4 and § 9.5: the three passes and the phase clause |
| `reference/data-architecture.md` | the § 1.1 rows and cells; the render's source list; § 5.1's statement of the `bound` set |
| `reference/data-model.md` · `reference/schemas/group-snapshot.md` (new) · `reference/schemas/README.md` | the snapshot's appended rules section; its schema and coverage declaration |
| `agents/destination-ideation.md` · `reference/schemas/destination-shortlist.md` · the ideation example | `publish: bound`; the one-reader sentences; the writer's filer rule and its withhold rule for rendered reasons |
| `agents/05-hub-planner.md` | the concealment mark; naming a desire only if marked, and an occasion only if marked not private; the neutral labels the private-site record requires |
| `agents/00-enrichment.md` | the group snapshot's writer contract and grammar block, gated on IDEATION, with its output-contract table; the projection split of the private-site record's safeguard 7 |
| `agents/06-validator.md` | its inline statement of the `bound` set; the location carve-out |
| `scripts/check-round-trip.sh` and group `W` of `scripts/test-artifact-schema.sh` | the per-artifact declarations, the new fences and label shapes, the IDEATION rows, the non-row, and the new finding codes with their arms |
| `scripts/test-artifact-schema.sh`, beyond group `W` | the `PB` pairing; the snapshot's label arm; group `MG`'s declared heading; the erase tally |
| `scripts/publish-trip-site.sh` `cmd_list` · `skills/trip-publish/SKILL.md` § *list* | `build-to-published` |
| `skills/trip-record/SKILL.md` | the reconcile-step namings, including on a move into IDEATION; `erase`'s reach over the group snapshot and over every page file |
| `CLAUDE.md` · `reference/command-reference.md` · `README.md` | the file-structure tree, the content sources, the walk's scope, the register row, the derived row and the self-descriptions |
| both intake templates | the notice states the snapshot's list, the mark rule and the withhold rule; the example answers that put content that is out in an IN line are replaced |
| `examples/` | a sanitized witness of the group snapshot's class |
| the literal sites of the page's file name | each one that states the write target gains the slug case; each generic example stays; the erasure verb's row is among them |

**Three axes.** *Best practice:* one declared home per fact; reads that fail closed; a reduced form
produced at build or by the writer, never by redaction on the publish path; a report-only relation;
withhold rather than rewrite a person's words. *Scalability:* a class that is not `bound` costs no edit,
a new `bound` class costs one row per admitted state, a new state one row per `bound` class, and a new
IN field one list row, one fence row and one notice line. *Maintainability:* it reuses `G5`'s modes,
`G7`'s cell grammar, the `rendered | excluded` enum, the shipped walker, the shipped verdict family, the
confirm gate's projection, the reconciler, the engagement tokens and `ADR-028`'s keying and erase-row
shape, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, the shape driver | **EXPENSIVE** once Wave-1 slices build on it; CHEAP while this record reads `Proposed` | HIGH on the driver; MEDIUM-HIGH on the grain |
| § 2, the two-grain contract | **MODERATE** — the spec, the walker and the grader can each be reverted | HIGH |
| § 3, the ceiling | **CHEAP** — rule text | HIGH |
| § 4, the map | **EXPENSIVE** once built; CHEAP while `Proposed` | HIGH for *No destination yet*; MEDIUM-HIGH for *Destination in play* |
| § 4, the carriers of the values the group may see | **MODERATE** — the rules sit on producers | MEDIUM-HIGH |
| § 5, the admission and the pre-plan classes | **EXPENSIVE** once built — a contract row | HIGH on IDEATION and `UNSET`; MEDIUM-HIGH on the plan-mode stop |
| § 6, transitions and staleness | **MODERATE** — report surfaces | HIGH on the policy; MEDIUM-HIGH on the identity observation |
| § 8, Finding 1 | **CHEAP** | HIGH |
| § 9, the group snapshot | **EXPENSIVE** once built; CHEAP while `Proposed` | HIGH on the class and placement; MEDIUM-HIGH on the production gate and its residual |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What the private site may show, the share mark and the safeguards | [the private-site record](ADR-029-what-the-private-site-may-show.md) |
| That a value that is out stays out when a `bound` artifact carries it, and the producers that owe it | [the private-site record](ADR-029-what-the-private-site-may-show.md) (D-2); this record names the ideation agent among them |
| What of a traveller's contact and emergency details the group sees, and their carrier | [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md) |
| What a channel is and what it may carry | `ADR-026` |
| The engagement axis and its boundaries | `ADR-025` |
| Scheduled refresh, re-encryption and republish | the living-site milestone |
| Per-card visual design | #87, which consumes this record's ceiling |
| A traveller-writeable surface | nothing here: directionality is deferred |
| The hub planner's IDEATION comparison artifact | a follow-on card |
| `ADR-026` Finding 1 | a routed intake observation (§ 8) |
| The rebuild announce for `rebuilt-each-synthesis` files | the class-wide question `ADR-028` § 2 routed |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **The phase-aware build**: the `site` row and its section, σ to the walker, the stem rule with the
  erasure reach over every page file, and the hero's pre-plan variant.
- **The completeness contract**: the render-table fence, the per-artifact element fences, § 9.3's state
  rows, the walker's three passes and group `W`'s arms.
- **The shortlist's render slice**: its class edit with its § 9.1 rows in one commit, its section, its
  writer's filer and withhold rules, and the two one-reader sentences.
- **The group snapshot slice**: its class, schema and rules, its writer contract, its gated production
  and register row, the dispatchers' naming, the reconcile-step namings, its section, its erase row, a
  sanitized fixture, and its writer input re-pointed to the private-site record's projection.
- **The concealed occasion**: the variant, the carve-outs, the mark and its joins.
- **`build-to-published`** in `list`.
- **The page's file-name sites**, each disposed of one by one.
- **The group contacts section**, placed as § 4 states, in the contact and emergency record's slices.
- **Routed, not Wave 1's by this record:** the hub's IDEATION comparison artifact; `ADR-026` Finding 1's
  card; and the observation that `/trip research`'s filter keeps the ideation agent out on one limb only.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The private-site record](ADR-029-what-the-private-site-may-show.md) — the verdict every IDEATION cell
  cites, its lists, its share mark, its concealed occasion, and its safeguards 1 to 7.
- [The contact and emergency record](ADR-031-contact-emergency-group-visibility.md) — the carrier this
  record places in every state.
- [ADR-026](ADR-026-channel-architecture.md) — § 4's production-gating, which this record applies; § 3's
  `may-carry`; and Finding 1, declined in § 8.
- [ADR-025](ADR-025-engagement-model-over-time.md) — the engagement axis and its floors, the carry rule
  and never-carries, § 4's render prohibition, and § 6's staleness family.
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the presence class whose class-reading
  exclusion, keying, write-set widening and erase-row shape this record reuses.
- [ADR-003](ADR-003-group-coordination.md) — § 2, the organizer's confirmation.
- [ADR-007](ADR-007-command-entry-point.md) — § 2, under which nothing is deleted at a transition.
- [ADR-008](ADR-008-publish-content-guard.md) — the one-render, two-limb publish guard.
- [ADR-009](ADR-009-data-architecture.md) — § 4.4's fail-closed paths.
- [ADR-010](ADR-010-per-traveler-approval-collection.md) — § 4, read through the private-site record's
  pointer.
- [ADR-011](ADR-011-per-traveler-cost-estimation.md) — decision 6's tripwire form, which the snapshot's
  closed list inverts.
- [ADR-006](ADR-006-third-party-data-capture.md) and [ADR-004](ADR-004-contact-emergency-privacy.md) —
  the third-party and contact boundaries the snapshot's population and field list respect.
- `reference/site-layout-spec.md` — § 3's catalog, § 7, § 8, and § 9.1 to § 9.5.
- `reference/data-architecture.md` — § 1.1's classes, § 1.2's out-of-model dispositions, § 5.1, § 5.5
  and § 5.6.
- `reference/data-model.md` — § *Field Scope*, the scopes of the labels the snapshot carries.
- `reference/schemas/destination-shortlist.md` — the shortlist's heading grain and its read-back
  refusals.
- `CLAUDE.md` — § *Modes*, § *Resolving a trip* (`G5` to `G8`, *What the contract returns*), § *Travel
  Site Generation*, and the mode-gated behaviour register.
- `skills/trip/SKILL.md` — the `site` row and section, § *ideas*, the verb index and the freshness
  report.
- `skills/trip-publish/SKILL.md` — the `update` row, rule 7 and § *list*.
- `skills/trip-record/SKILL.md` — the reconcile-step namings and the erase reach table.
- `agents/destination-ideation.md`, `agents/05-hub-planner.md`, `agents/00-enrichment.md` and
  `agents/06-validator.md` — the producers and the auditor these decisions bind.
- `templates/person-intake.template.md`, `templates/traveler-intake.template.md` and
  `templates/trip-context.template.md` — the field labels the snapshot carries, and the roster.
- `scripts/check-round-trip.sh`, `scripts/test-artifact-schema.sh` and `scripts/publish-trip-site.sh` —
  the walker, its grader, and the publish path.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the first and second passes, the
  operator's D-1 to D-4 and the group-snapshot step; the joint source-binding step, #1383; the plan, its
  surface map, the fit review and CR-2 on #1369; the carrier and its decisions on #1546; decision Q on
  #1385; and the Wave-1 working notes this record's build detail moved to, on #1392.
