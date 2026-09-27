# ADR-031: The site's phase model — the resolved state drives its shape through one render table, and what each state's build renders

- **Status:** Accepted (2026-09-27)
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries its shape driver and its map; *References* lists the card's other records. The milestone's
  other cards are [the private-site record](ADR-030-what-the-private-site-may-show.md) (#1242) and
  [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after
  [the private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because this record's pre-plan rows render values that
  record admits. The flip is the maintainer's, taken at
  this milestone's close, and it moves both halves of a two-artifact state: the `Status:` line
  above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **how the site renders in each phase of a trip**: what drives its
  shape, and which artifacts each state's build renders and where.
- **What this record is not.** It decides rendering, not reach. What a channel may carry is
  `ADR-026`'s, what the private site may show is the private-site record's, and what of a
  traveller's contact and emergency details the group sees is the contact and emergency record's.
  It builds nothing, and in this release it changes no `publish:` value, no fence line and no
  per-verb requirement row: every change it decides lands in a later slice.
- **How it was decided.** In the first two design passes on the card's design sub-task #1388: the
  first decided the shape driver and the plan-phase cells, and the second the pre-plan rows. The
  operator's decisions D-1, D-2 and D-4 followed the second pass, and the milestone's fit review and
  scope lock, CR-2, are recorded on #1369. The contact and emergency record's carrier, decided on
  #1546 as decision K, is placed in this record's render table by citation. The card's one record
  was split by topic under the operator's R2, recorded on #1369, with no decision changed.

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

**This record answers the second limb's shape half**: that the build does not read the mode where it
runs. [The site-admission record](ADR-034-site-build-admission.md) answers that limb's other half,
that the build does not run in IDEATION; the first limb is [the round-trip contract
record](ADR-032-site-round-trip-contract.md)'s, and the third [the section-ceiling
record](ADR-033-site-section-ceiling.md)'s.

**What the live target establishes.** Every fact below was read live at `8b2ac05`, the base of this
release.

- **The build already holds the resolved state.** `/trip` declares `contract-depth: G8`, and the
  `site` row names mode and destination values, so `G5`, `G6` and `G7` run before the verb body and
  the resolution record carries `trip.mode` and `trip.destination`. `CLAUDE.md` § *What the contract
  returns* says downstream verbs branch on these fields instead of re-deriving them. **A render driven
  by mode therefore needs no new read.**
- **Both publish limbs ship one page.** `scripts/publish-trip-site.sh` resolves one rendered page in
  `cmd_publish`; the `--plaintext` limb publishes it as it is and the encrypted limb encrypts it.

**Precedents this record reuses rather than mints.**

| Precedent | Where | What it already decided |
|---|---|---|
| Split-Day | `reference/site-layout-spec.md` § 3 | it replaced a page per subgroup with a region inside one day: the catalog has rejected pages per unit once |
| Coordination Notice | the same § 3 | site-additive scaffolding that no § 9 table carries, and that is not emitted when empty |
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
| C | A new card type | **rejected by the ceiling** ([the section-ceiling record](ADR-033-site-section-ceiling.md)): Q3 finds the schedule entry |

### How the values the group may see reach the page

| | Option | Disposition |
|---|---|---|
| **A** | **`bound` carriers only** | **chosen** — the trip context, the shortlist, the itinerary, the group snapshot and the group contacts file |
| B | The traveller file made `bound`, with a field fence | **rejected.** A wider read surface for less coverage, and the build would parse hand-edited files carrying values that are out |
| C | A derived, `bound` projection of the shared details | **taken as the group snapshot** ([the group-snapshot record](ADR-037-group-snapshot.md)), by the operator's D-3 |
| D | The build reads the traveller model's fields under a field-keyed exception | **rejected.** It is the field-keyed mechanism of the private-site card's fourth design pass, which that record does not carry forward, and it contradicts the contract [the round-trip contract record](ADR-032-site-round-trip-contract.md) decides |

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

**The refresh obligation this shape creates** is named here and its policy set in
[the site-transitions record](ADR-035-site-transitions-and-refresh.md). A change of
state is a change of shape, so the published render is out of date until it is rebuilt **and**
republished. A rebuild is already observable: the Mode line lives in `trip-context.md`, a declared
input of `site`, so `itinerary-to-build` reads `BEHIND` after any `/trip-record mode`. Automating a
rebuild or a republish belongs to the living-site milestone.

### 2. The map — what each state's build renders, and where

The map is indexed on what each state's build **renders**, never on which artifacts exist.

**One row per state.**

| State σ | The build | What it renders | § 9.3 artifact exclusions for the state |
|---|---|---|---|
| IDEATION × UNDECIDED (*No destination yet*) | RUN | the trip context → the hero, pre-plan variant · the shortlist → the shortlist section · the group snapshot → its section · the group contacts file → its section | the itinerary, the links reference, the venue matrix, the event status |
| IDEATION × DECIDED (*Destination in play*) | RUN | the trip context → the hero, pre-plan variant naming the destination in play · the group snapshot → its section · the group contacts file → its section | the shortlist, and the itinerary, the links reference, the venue matrix, the event status |
| DISCOVERY, ENRICHMENT, ITERATION or RESEQUENCING × DECIDED | RUN | the plan-phase shape below, and the group contacts file → its section | the shortlist and the group snapshot |
| a plan mode × UNDECIDED | a declared non-row: the verb's own stop ([the site-admission record](ADR-034-site-build-admission.md)) | — | — |
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

**The group contacts rows** are the contact and emergency record's carrier, placed here by citation
to [that record](ADR-038-contact-emergency-group-visibility.md). The ceiling returns a section for
it ([the section-ceiling record](ADR-033-site-section-ceiling.md)), which renders in every state the
site builds — both IDEATION rows and the four plan modes — and takes no § 9.3 row, because nothing
of it is excluded in any built state. For each traveller who filed their own form it carries their
in-trip contact, when they chose to share it, and their emergency line in one of three states: the
contact's name, shown only on the traveller's attestation that the contact agreed, with a note that
the organizer holds how to reach them; *on file with the organizer*; or *no emergency contact on
file*. The way to reach an emergency contact and the relationship are never shown. Its three states
follow the snapshot's rule: present with entries → rendered; present with none → a neutral declared
empty state; absent → a degraded read, with the remedy `/trip-record travelers`. What the file
carries, who writes it and why each line holds are that record's. **The organizer line** — who to
tell if something happens — is not a section: it is a field of the hero, rendered from the `##
Group` roster alone in every state the site builds, under the content rules that record states.

**The § 9.3 rows.**

| Excluded | Where | Why |
|---|---|---|
| the destination shortlist | IDEATION × DECIDED, and every plan mode | the destination is recorded, so the ideation question is answered; its producer no longer refreshes it; and a rendered ranking beside the chosen destination would be a second source for *where* |
| the itinerary, the links reference, the venue matrix, the event status | both IDEATION rows | IDEATION's shape is pre-plan; a plan artifact left from an earlier phase is superseded by the declared return |
| the group snapshot | every plan mode | once a plan exists, the plan answers when, from where, where the group stays and at what pace; the snapshot is produced only in IDEATION, so it is no longer refreshed; and a stated preference beside the decided plan would re-open settled choices |
| `Handoff to DISCOVERY`, an element of the shortlist | wherever the shortlist renders | an instruction to whoever operates the engine, not reader content |

**The IDEATION rows in detail.** Both rows cite [the private-site
record](ADR-030-what-the-private-site-may-show.md) as the ground of what they may render.

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
  value, the group snapshot by its population rule
  ([the group-snapshot record](ADR-037-group-snapshot.md)'s G-2), the group contacts file by its own, and the
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
shortlist's class — are both lifted by Wave-1 edits that
[the site-admission record](ADR-034-site-build-admission.md) and this record decide, and `/trip-publish update`
already admits any mode and any destination. The no-form branch does not arise, and that criterion
needs no revisit.

### 3. Conformance to `ADR-025` and `ADR-026`

| Accepted decision | How this record conforms |
|---|---|
| `ADR-026` § 4, production-gating | Mode conditions what each state's build renders, through one render table. Reach is unchanged in every state, and no state is inferred from which files exist |
| `ADR-026` § 3, `may-carry` | Nothing crosses CH-1 that the class and the private-site record's verdict do not admit in every state. The render is limb-blind. No redaction step is added: the concealed block is a reduced form the build produces |
| `ADR-026` § 5, the R-rule | The build emits no value `may-carry` denies. The traveller file, the model and the person record are never read |
| `ADR-026` §§ 1–2, the channel-set | No channel is added: one page and one ciphertext, on both limbs |
| `ADR-026`'s `ARCHIVED` overlay | No render in `ARCHIVED`: a declared non-row |
| `ADR-025` § 3, the carry rule and never-carries | Rendering carries no class across a boundary. Never-carry 2 holds for every value outside the private-site record's IN list, as that record reads it |
| `ADR-025` § 4, the render prohibition | Unchanged for values that are out. IN values reach the private page only as the private-site record admits |
| `ADR-025` § 4 and `ADR-010` § 4, the inference of who filed | Governed by the private-site record's pointers into both sections, which carry the sentence on it. This record relies on that sentence and restates none of it |

**No divergence from a decision is intended.** Two claims in `ADR-026` — § 3's composition of the
render and § 4's sentence on IDEATION — describe the build as it stood when that record was written,
and this release adds a dated pointer to `ADR-026` recording what this record, [the site-admission
record](ADR-034-site-build-admission.md) and [the group-snapshot record](ADR-037-group-snapshot.md)
decide.

## Consequences

**Positive**

- **#1241's shape and IDEATION criteria are met**, and the site follows every declared state except
  `UNSET`: a trip can move back and forth between *No destination yet* and *Destination in play*, and
  into planning, with the page following.
- **The page before a plan carries what the group needs to coordinate** — who can travel when, from where
  and how each likes to travel, in the group snapshot — and *Destination in play* is no longer the hero
  alone. Every item on the private-site record's IN list has a rendered home before a plan, or a named
  reason why not.
- **In a plan mode a traveller sees today's site, plus the group contacts section.**
- **The shortlist's refusal keeps its purpose**: one source for a chosen destination.
- **The concealed occasion has a whole-page rule**: every component that could identify the event is
  bound by it.

**Costs and residuals, stated rather than smoothed**

- **The site follows the operator's declaration**, not the group's conversation.
- **The plan modes share one shape**, so the shape criterion hinges on IDEATION.
- **The concealed block lists its attendees**, by the private-site record's decided form, so a block
  whose attendee list leaves one traveller out can itself tell that traveller something is planned. That
  is a residual of the decided form, not re-opened here.
- **New rules sit on producers** — the hub's concealment mark and naming rules, and the shortlist
  writer's filer and withhold rules — and are graded only where Wave 1 adds arms.
- **Filer status is inferable on the private page**, as the private-site record states.
- **The hub planner's IDEATION comparison has no rendered home** until its follow-on lands.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| the concealed block against the location invariant | the validator: "Every event must resolve to a map link … and render it on its card." | without the stated carve-out a concealed event would read as a broken card — a Wave-1 obligation |

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `reference/site-layout-spec.md` | § 3: the `group-shortlist`, `group-snapshot` and `group-contacts` sections, the hero's pre-plan variant, the `is-concealed` variant and the location-invariant carve-out |
| `agents/destination-ideation.md` · `reference/schemas/destination-shortlist.md` · the ideation example | `publish: bound`; the one-reader sentences; the writer's filer rule and its withhold rule for rendered reasons |
| `agents/05-hub-planner.md` | the concealment mark; naming a desire only if marked, and an occasion only if marked not private; the neutral labels the private-site record requires |
| `agents/06-validator.md` | the location carve-out |
| `CLAUDE.md` · `reference/command-reference.md` · `README.md` | the content sources and the self-descriptions |

**Three axes.** *Best practice:* one declared home per fact; reads that fail closed; a reduced form
produced at build or by the writer, never by redaction on the publish path. *Scalability:* a new
state costs one row per `bound` class. *Maintainability:* it reuses `G5`'s modes and the
`rendered | excluded` enum, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, the shape driver | **EXPENSIVE** once Wave-1 slices build on it; CHEAP while this record reads `Proposed` | HIGH on the driver; MEDIUM-HIGH on the grain |
| § 2, the map | **EXPENSIVE** once built; CHEAP while `Proposed` | HIGH for *No destination yet*; MEDIUM-HIGH for *Destination in play* |
| § 2, the carriers of the values the group may see | **MODERATE** — the rules sit on producers | MEDIUM-HIGH |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What the private site may show, the share mark and the safeguards | [the private-site record](ADR-030-what-the-private-site-may-show.md) |
| That a value that is out stays out when a `bound` artifact carries it, and the producers that owe it | [the private-site record](ADR-030-what-the-private-site-may-show.md) (D-2); this record names the ideation agent among them |
| What of a traveller's contact and emergency details the group sees, and their carrier | [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) |
| What a channel is and what it may carry | `ADR-026` |
| How the round-trip completeness contract grades what each state renders | [the round-trip contract record](ADR-032-site-round-trip-contract.md) |
| What earns a section, a region or a field | [the section-ceiling record](ADR-033-site-section-ceiling.md) |
| Which states the build admits, the page's file name and the pre-plan classes | [the site-admission record](ADR-034-site-build-admission.md) |
| What a transition does to the page, and what a traveller was shown | [the site-transitions record](ADR-035-site-transitions-and-refresh.md) |
| The group snapshot's fields, population, writer, class and production | [the group-snapshot record](ADR-037-group-snapshot.md) |
| A traveller-writeable surface | nothing here: directionality is deferred |
| The hub planner's IDEATION comparison artifact | a follow-on card |
| Whether the published artifact takes an in-model row — `ADR-026` Finding 1 | [the published-artifact record](ADR-036-published-artifact-model-row.md) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **The hero's pre-plan variant**, in the phase-aware build.
- **The shortlist's render slice**: its class edit with its § 9.1 rows in one commit, its section, its
  writer's filer and withhold rules, and the two one-reader sentences. It also carries the
  private-site record's § *Decision* 7 condition, the Decision-4 supersession entry inside `ADR-009`,
  as do the group snapshot slice and the phase-aware build of [the site-admission
  record](ADR-034-site-build-admission.md): whichever of the three completes the replacement — the
  first change after which an IDEATION build renders the shortlist or the group snapshot — records the
  entry.
- **The concealed occasion**: the variant, the carve-outs, the mark and its joins.
- **The group contacts section**, placed as § 2 states, in the contact and emergency record's slices.
- **Routed, not Wave 1's by this record:** the hub's IDEATION comparison artifact.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The private-site record](ADR-030-what-the-private-site-may-show.md) — the verdict every IDEATION cell
  cites, its lists, its share mark, its concealed occasion, and its safeguards 1 to 7.
- [The contact and emergency record](ADR-038-contact-emergency-group-visibility.md) — the carrier this
  record places in every state.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [ADR-026](ADR-026-channel-architecture.md) — § 4's production-gating, which this record applies; § 3's
  `may-carry`; §§ 1–2's channel-set; and its `ARCHIVED` overlay.
- [ADR-025](ADR-025-engagement-model-over-time.md) — the carry rule and never-carry 2, and § 4's render
  prohibition.
- [ADR-008](ADR-008-publish-content-guard.md) — the one-render, two-limb publish guard.
- [ADR-009](ADR-009-data-architecture.md) — § 4.4's fail-closed paths.
- [ADR-010](ADR-010-per-traveler-approval-collection.md) — § 4, read through the private-site record's
  pointer.
- `reference/site-layout-spec.md` — § 3's catalog, § 7 and § 8.
- `reference/schemas/destination-shortlist.md` — the shortlist's heading grain and its read-back
  refusals.
- `CLAUDE.md` — § *Modes*, § *Resolving a trip* (`G5` and `G6`, *What the contract returns*) and
  § *Travel Site Generation*.
- `skills/trip/SKILL.md` — § *ideas*.
- `agents/destination-ideation.md`, `agents/05-hub-planner.md` and `agents/06-validator.md` — the
  producers and the auditor these decisions bind.
- `templates/trip-context.template.md` — the roster.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the first and second passes and
  the operator's D-1, D-2 and D-4; the joint source-binding step, #1383; the plan, its surface map, the
  fit review, CR-2 and R2 on #1369; the carrier and its decisions on #1546; and the Wave-1 working
  notes this record's build detail moved to, on #1392.
