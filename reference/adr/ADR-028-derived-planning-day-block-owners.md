# ADR-028: Owners for the derived planning-day blocks — the trip window to the verb that records its inputs, and each traveller's window to a presence file the reconciler rebuilds

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *derived blocks get an owner* milestone. This record is its gating decision.
- **What this record is.** It decides the owner, inputs, repair and provenance of both derived
  planning-day projections, the class that carries each traveller's window, and the write shapes
  that admit the trip window's recompute and the reconciler's second file.
- **What this record is not.** It decides and builds nothing: it edits no prompt, table row,
  template, verb, class row, schema or other record.
- **The status flip is named here, and so is what grades it.** Moving this record from `Proposed`
  to `Accepted` is the maintainer's, taken at this milestone's close, and it moves **both** halves of
  a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  `reference/adr/README.md` — the two-step `ADR-010` and `ADR-019` each used. The halves' agreement
  **is** graded: group `IX` of `scripts/test-adr-conformance.sh` compares them on every push and
  every pull request. That check is advisory, not required — `.github/workflows/adr-conformance.yml`
  keeps its context out of branch protection — so a disagreement turns it red without blocking a
  merge. When the flip is taken, and whether the decision it ratifies still holds, nothing grades;
  that obligation travels with this line.

## Context

**Two blocks of `trip-context.md` have content and no writer, and the table that says so forbids
it.** `CLAUDE.md` § *Write ownership — trip-context.md, block by block* gives every block of the trip
file one writer. Its row 4 names the two `[DERIVED]` blocks — `### Effective Planning Days` and
`### Per-Traveler Planning Days` — and gives them **no writer exists**, on the condition *"Not a gap
to fill opportunistically. The template forbids manual editing and the enrichment agent declines the
write in terms. Until an owner is decided these blocks are read-only to every command,
`/trip-record` included; staleness is reported, never repaired in place."* Its row 9 — *a block not
listed above*, writer *nobody* — closes the table on the rule *"A new block gets an owner in this
table before it gets content."* Both blocks have content, so row 4 is a standing exception to row 9,
and nothing was scheduled to end it.

**The blocks are read, and their readers are why the answer matters.** Probed at `54586fd` over the
159 tracked `.md`, `.sh` and `.yml` files, with line wraps and blockquote prefixes normalized,
`Per-Traveler Planning Days` occurs 38 times in 21 files and `Effective Planning Days` 17 times in
12, and 23 files carry one or both. The readers among them:

- **Each traveller's window** is read by scheduling as the window limb of presence
  (`agents/03-scheduling.md`:39-42, and input item 4 at `:314-319`); by transport, so a traveller
  who does not travel on their origin's booking is not planned onto it (`agents/04-transport.md`:188-190);
  by the hub, for the cost estimate's presence (`agents/05-hub-planner.md`:1009-1010, `:1108`,
  `:1134`); and by the validator, for each night's nightlife applicability
  (`agents/06-validator.md`:620-621). `reference/data-model.md` § *Presence — a traveler's
  present-day set* makes the block the one home for a window, and `ADR-018` decision 5 reads presence
  from it and never re-derives it.
- **The trip window** is read by scheduling as the trip's baseline day shape and the source of its
  Day key (`agents/03-scheduling.md`:311-313, `:489-491`); by data-model, as the trip-day set
  (§ *Presence*) and as the departure month `M_dep` that refines the reference month (§ *The
  reference month — what a horizon is compared against*); by `reference/replan-protocol.md`, for the
  trip's first day (`:31-34`); and by group `HZ` of `scripts/test-artifact-schema.sh`, which reads its
  `Departure day` line (`:8921-8930`).
- **The rest of the population** is the template that declares the blocks, the writer table, the
  verbs that report the blocks stale (`skills/trip-record/SKILL.md`, `skills/trip-new/SKILL.md`), the
  enrichment prompt that detects the staleness and declines the write, the records that describe the
  blocks (`ADR-018`, `ADR-024`), the worked examples, and past changelog entries.

**Three records and the erasure verb rest on the no-writer state.**

- `ADR-015` rejected *"The `[DERIVED]` block's own date"* as a source of the trip term because the
  `[DERIVED]` planning-day blocks have no writer
  (`reference/adr/ADR-015-durable-field-validity-horizon.md`:84-88, `:98`), and its References rest
  the same clause on that assignment (`:335-337`).
- `ADR-024` decision 6 holds every region with no declared writer outside the form contract until an
  owner is decided, and admits it by that record's own rules when one is
  (`reference/adr/ADR-024-form-contract-writer-boundary.md` § *6. Regions no writer owns*); row 4 of
  its interviewability table carries the two blocks as excluded on exactly that ground (`:374`).
- `ADR-025`'s finding 4 records that a derived block in the trip file has no writer, and that the
  engagement axis deliberately does not become one
  (`reference/adr/ADR-025-engagement-model-over-time.md`:823-827).
- Erasure's reach table names no location in `## Logistics` (`skills/trip-record/SKILL.md`
  § *Step 3 — the reach table*), so a traveller's name in the window block's table is outside
  erasure's reach today. That gap is routed outside this release.

**The facts that decide the question, each read at the baseline below.**

1. **The window depends on the trip window.** The per-traveller block's baseline line reads
   *"Baseline inherited by ASSERTED-SAME and UNKNOWN: the trip-level window above"*
   (`templates/trip-context.template.md` § *Per-Traveler Planning Days [DERIVED]*), so two of its
   three bases take the trip window's value as their own.
2. **The trip window's inputs are declared fields.** Its lines are computed from the anchor origin's
   `### Outbound` and `### Return` legs — each leg's `Departs:` and `Arrives:` — and from
   `## Accommodation`'s `Check-in time:` and `Check-out time:` (`templates/trip-context.template.md`
   §§ *Logistics* and *Accommodation*). The hotel-departure time its departure line mentions is not
   one of them: a leg set's `- **Notes:**` line is prose, and transport publishes the recommended
   time as `Recommended hotel departure:` in its own brief (`agents/04-transport.md`:584).
3. **The window holds no independent state, and only the reconciler can derive it.** The block says
   so in terms — *"No value a traveler wrote is copied here: every cell is derived, and goes stale
   when a profile changes"* (the template's § *Per-Traveler Planning Days [DERIVED]*). Its inputs are
   the travellers' composed journey facets, which the enrichment agent's reconciler role alone reads
   and reconciles (`reference/data-architecture.md`:69; `agents/00-enrichment.md`:52-57). The trip
   file is `persist-mutable` — synthesis reads it and never regenerates it
   (`reference/data-architecture.md`:932) — and the writer table's own test sends regenerated bytes
   elsewhere: *"if the next synthesis pass would regenerate those bytes, they do not belong in this
   file at all"* (`CLAUDE.md` § *Write ownership*, its opening paragraph).
4. **The model's per-entry seam is closed within this release.** `ADR-011` decision 2 keeps
   transport's read of `outputs/traveler-model.md` *"for the depth signal and for nothing else"*,
   because a wider read could drop a `[THIRD-PARTY]` passenger from a stream being priced
   (`reference/adr/ADR-011-per-traveler-cost-estimation.md`:89-93). Only a supersession changes a
   decision of an `Accepted` record (`reference/adr/README.md`:15-17, `:26-27`), and a supersession
   is outside a release that decides and builds nothing. The window therefore cannot become lines on
   the model's entries here.
5. **"Composition writes neither" means the title line and the trip window.**
   `reference/data-model.md` § *The reference month* resolves the trip term from the title line and
   one `[DERIVED]` block of `trip-context.md`, and says of both that *"composition writes neither"*.
6. **The person key is not a trip-internal join basis**
   (`reference/adr/ADR-012-people-library.md`:1127-1129).

The corpus's own layer names are used throughout: **Layer 1 — human source** for untagged human
input, `[ENRICH]` for the enrichment agent's rollups into the trip file, and `[DERIVED]` for a
projection nobody authors (`reference/data-model.md` § *Who Writes What — Field Layering*).

**Baseline.** Every locator in this record — a path with a line number, or a path with a section —
was read live at `54586fd` (2026-09-24), the commit this record was authored against. That commit
differs from `b199dc1`, where the decision was designed, by one other record, its index row and a
changelog entry, and it moves no line cited here. A line locator is correct at that commit and moves
with later edits, so the surfaces other releases were editing in parallel — `CLAUDE.md`
§ *Write ownership*, `templates/trip-context.template.md` and `reference/data-model.md` — are cited
by section rather than by line.

## Decision drivers

- **DD1.** One writer per block (`CLAUDE.md` § *Write ownership*, its opening paragraph), and an
  owner before content (row 9). `event` already recomputes a derived cell in the act that changes its
  input (`skills/trip-record/SKILL.md`:1608-1611).
- **DD2.** Composition stays deterministic (`reference/data-model.md` § *Determinism*). Its
  obligation O1 — *no rule names a sequence* — is scoped to the guards of the composition function
  `V`, so it grades none of the options below and kills none of them.
- **DD3.** A projection that holds no independent state lives in a rebuilt class, never in the
  `persist-mutable` trip file.
- **DD4.** The card's constraints hold unchanged: the template's *do not manually edit* posture
  stands, the readers' *read, never re-derived* postures are not reopened, and no decision makes a
  Layer 1 — human source field agent-writable.
- **DD5.** The record decides and does not plan. It names what each decision makes false, and
  schedules none of it.
- **DD6.** No new verb, script or freshness relation, and one new artifact class — the presence
  class — because `ADR-011` decision 2 closes, within a release that decides and builds nothing, the
  seam the window would otherwise extend (fact 4 above).
- **DD7.** No privacy regression, claimed no wider than it holds. Every location this record adds
  that carries a name is reached by erasure before it holds one: the presence file's entry heading,
  through the reach row Decision 9 decides. No person key enters a trip artifact, and no value leaves
  its non-publishable class. **What this driver does not claim** is that no name is written where
  erasure does not reach. Decision 2's label-only `VERIFY` is a new line, keyed by the traveller's
  display name, in the model's `## Update signals` block (`agents/00-enrichment.md`:411-413) — a
  location erasure did not reach before this record and does not reach after it, because reach row
  10 covers the model's entry heading alone (`skills/trip-record/SKILL.md`:2244). The location class
  is not new; that block's reach is routed outside this release, beside the `## Logistics` gap.
