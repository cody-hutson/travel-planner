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

## Options considered

Each option set names what was selected and the ground on which every other option was killed. The
selections are stated in full in § *Decision*.

### D-1 — Who writes the trip window

**Selected: C, `/trip-record`** — the command whose verbs already record the trip window's inputs,
recomputing the affected lines in the same act (Decision 1).

- **A — the enrichment agent's reconciler role.** Rejected. The reference month resolves the trip
  term from the title line and the trip window and says of both *"composition writes neither"*
  (`reference/data-model.md` § *The reference month*), and `ADR-015` decision 1 adopts that
  resolution (`reference/adr/ADR-015-durable-field-validity-horizon.md`:156-158). Making the
  reconciler the trip window's writer changes what an `Accepted` decision rests on, which needs a
  supersession outside this release. It would also put synthesis-written bytes in the trip file,
  against the writer table's regeneration test.
- **A′ — the trip window moved into the traveller model.** Rejected. `ADR-015` decision 1 reads the
  trip window from `trip-context.md`, and the trip window is trip-level rather than a projection of
  any one traveller.
- **B — the enrichment agent's research role.** Rejected. It is a synthesis leg writing computed
  bytes into the trip file, against the regeneration test, and it loses on dispatch: `/trip replan`
  runs enrichment only on a profile trigger, and `/trip reorder` never runs it
  (`skills/trip/SKILL.md`:731-733, `:808`).
- **B′ — `fact` dispatching an agent to recompute.** Rejected. `fact` dispatches no agent
  (`skills/trip-record/SKILL.md`:1280), and a dispatch would bring a synthesis writer back to the
  same bytes.
- **D — the hub.** Rejected. The hub runs after the spokes that read the trip window
  (`CLAUDE.md` § *Dispatching agents*), so they would read the previous pass's value, and its write
  would be a synthesis write into the trip file.
- **E — a new verb.** Rejected on blast radius: a new command-surface entry to recompute lines the
  recording verb already holds.
- **F — a script.** Rejected: the writer table names commands, one agent and the operator as
  writers, and no script.
- **G — no owner.** Rejected: that is row 4's standing exception, which row 9 forbids.

### D-2 — Where each traveller's window lives

**Selected: W3 — a new presence class, `outputs/traveler-presence.md`,** written by the enrichment
agent's reconciler role and rebuilt on every pass (Decision 2).

- **W1 — lines on the traveller model's entries.** Rejected: it needs `ADR-011` decision 2
  superseded, because it widens transport's read of that file past the depth signal (fact 4 of
  § *Context*).
- **W2 — the reconciler writes the block inside `trip-context.md`.** Rejected. It stands only on
  named exceptions to four live rules — the writer table's regeneration test (`CLAUDE.md`
  § *Write ownership*), `fact`'s admission ground built on it (`skills/trip-record/SKILL.md`:1289-1291),
  the trip file's `persist-mutable` lifecycle (`reference/data-architecture.md`:932), and the
  enrichment prompt's bar on writing journey facets into the trip file
  (`agents/00-enrichment.md`:169-172). The trip file is on `/trip site`'s `**Reads:**` line, which is
  the source side of the `itinerary-to-build` freshness relation (`skills/trip/SKILL.md`:334), so
  every reconcile pass would read the published site as `BEHIND` when nothing it renders had changed.
  And it writes travellers' names into `## Logistics`, which erasure does not reach.
- **W4 — `/trip-record` writes the block**, copying the values the reconciler published or deriving
  them itself. Rejected: the copy gives the window a second home, and the derivation gives it a
  second composer beside the reconciler.
- **W5 — the reconciler declared outside synthesis**, so that its write escapes the regeneration
  test. Excluded at the design's first review, because the corpus places the reconciler inside
  synthesis: it rebuilds the traveller model on every pass (`reference/data-architecture.md`:69,
  § 6), and `/trip plan` runs it as the pipeline's first leg (`CLAUDE.md` § *Dispatching agents*;
  `skills/trip/SKILL.md`:665-672).
- **W6 — the block retired, and each reader derives the window.** Rejected: it breaks the readers'
  *read, never re-derived* posture (`ADR-018` decision 5; DD4).
- **W7 — a downstream writer, the hub or scheduling, at synthesis.** Rejected: every chain runs
  transport and scheduling before the hub (`skills/trip/SKILL.md`:811; `CLAUDE.md`
  § *Dispatching agents*), so a hub write is read stale by construction, and a synthesis write into
  the trip file breaks the regeneration test.

| Option | Reversibility | Confidence | What it costs |
|---|---|---|---|
| **W3 — the presence class** | MODERATE while `Proposed`; EXPENSIVE once `Accepted` | MEDIUM-HIGH | all additive: a class row, a schema, a witness, an erase row, and the reader re-points |
| W2 — the block, written by the reconciler | the same | MEDIUM | the exceptions to four live rules above |
| W1 — lines on the model, with a supersession | EXPENSIVE | HIGH on lifecycle fit, LOW on proportion | a supersession of `ADR-011` decision 2 |

### D-3 — Whether the enrichment contract widens

**Selected: (vi) — the reconciler's write set widens by one rebuilt file, the presence file.** The
`[ENRICH]`-only contract on `trip-context.md` does not widen, and the research role widens nowhere
(Decision 4).

- **(i) The reconciler owns both blocks in the trip file.** Rejected: the trip-window half breaks
  *"composition writes neither"*, which `ADR-015` decision 1 adopts, so it needs a supersession, and
  it puts synthesis bytes in the trip file (D-1, A).
- **(ii) Both roles widen.** Rejected: the research-role half is a synthesis leg writing computed
  bytes into the trip file, and it loses on dispatch (D-1, B).
- **(iii) The window stays in the trip file, written by the reconciler.** Rejected: this is W2
  (D-2).
- **(iv) `/trip-record`, or a new verb, owns the window in the trip file.** Rejected: a second home,
  a second composer or a new verb (D-2, W4; D-1, E).
- **(v) The window lives as lines on the model.** Rejected: this is W1, which only a supersession of
  `ADR-011` decision 2 admits.

`reference/data-model.md` § *Determinism*'s obligation O1 is the ground for none of these
rejections (DD2).

### D-4 — When each block is repaired

**Selected: the trip window in the act that records a change to one of its inputs, line by line;
each traveller's window on every reconciler pass, by a rebuild** (Decision 3). *"Staleness is
reported, never repaired in place"* survives for neither block; its descendant is the routing in
Decision 6.

- **Repair on the next synthesis pass.** Rejected for the trip window: the pass that would repair it
  is a synthesis leg writing the trip file (D-1, B and D). For each traveller's window it is the
  selected shape, because the pass itself rebuilds the presence file.
- **Report, and never repair.** Rejected: that is row 4's standing exception, which row 9 forbids once
  a block has content.

The precedent for repair in the act is `event`, which recomputes a derived cell in the act that
changes its input (DD1).

### D-5 — What records provenance

**Selected: `Last derived:` retires with the per-traveller block; each window's provenance is the
presence file's `generated:`; the trip window carries none** (Decision 5).

- **Keep a `Last derived:` line.** Rejected: it would date a block that no longer holds the window,
  while the presence file's frontmatter dates every pass that writes it.
- **Give the trip window a date line.** Rejected: the trip window is repaired in the act that changes
  its input, and a date line would be read by nothing — the freshness family observes order, never
  time (`skills/trip/SKILL.md`:301).

### D-6 — Whether the two blocks share a row

**Selected: the blocks do not share a row** (§ *Decision*, before Decision 1). The one-row shape
recorded a shared *absence* of a writer. The two blocks now have different writers, lifecycles and homes, and one row
would assert a single writer for blocks that share none.

### D-7 — The event that ends the exclusion, per region

**Selected: per region, the change that settles the region's writer** — for the trip window, the
change that names `/trip-record` in `CLAUDE.md` § *Write ownership*; for the per-traveller block,
the change that removes it from the template (Decision 10).

- **This record's merge, or its ratification.** Rejected: neither changes the table or the
  template, and `ADR-024` decision 2D makes a region's declared writer the writer the table declares
  (`reference/adr/ADR-024-form-contract-writer-boundary.md` § *2. How a boundary is declared*).
  Ending the exclusion on this record's merge would admit a region the table still says nobody may
  write.

### D-8 — Where the rules live

**Selected** (Decision 11): the trip window's derivation, with its per-line inputs, stays in the
template beside the block; the presence file's labels, vocabulary, derivation rules, value shapes and
by-reference forms go in a section appended below the end of `reference/data-model.md`; and
§ *Presence* cites that section and the file. The placements this rules out:

- **The per-traveller rules kept in the template.** The block they describe retires from it.
- **The rules inserted into § *Presence*.** `ADR-009`'s ordering rule admits no net insertion above
  the end of data-model's worked example, and edits there only in place at equal line count
  (`reference/adr/ADR-009-data-architecture.md`:342-348).

### D-9 — The hotel-departure time

**Selected: it stays prose and is not an input of the trip window** (Decision 3). The departure line
loses its hotel clause, and scheduling ends the departure day's usable window at transport's
published `Recommended hotel departure:` (`agents/04-transport.md`:584).

- **The time read as an input.** Rejected: its only home in the trip file is a leg set's
  `- **Notes:**` prose, and a recompute parses nothing out of undeclared prose and estimates nothing
  (Decision 7).

### D-10 — How the trip window's recompute is admitted

**Selected: a numbered widening of the standing clause, appended as rule 15** (Decision 7) — not an
exception written inside `fact`.

- **A verb-local exception in `fact`.** Rejected: the rule's trigger is the input, not the verb.
  Written into `fact`, it would leave the next verb that records such an input without a tool — the
  failure the standing clause's Extension rule names for a rule buried in one verb section
  (`skills/trip-record/SKILL.md`:678-683).

### D-11 — What keys a presence entry

**Selected: the `## Group` roster's display name, as `## <Name>`** (Decision 2).

- **A person token (`psn-<token>`).** Rejected. `ADR-012` decision 3 puts `person:` on
  `travelers/<traveler>.md` *"and on no other class"*, and binds that the person key is not a
  trip-internal join basis (`reference/adr/ADR-012-people-library.md`:1110, `:1127-1129`), so keying
  by it needs a supersession. It is not total either: the field is optional and its absence is the
  normal state of every traveller file (`:1112-1116`), and a fallback entry has no file at all. A
  second in-trip location for a cross-trip id is also the widening `ADR-016` refused as its option
  O7 (`reference/adr/ADR-016-reusable-groups.md`:103-111).
- **A key only the model can resolve** — an ordinal, or a position. Rejected: every reader would
  have to read `outputs/traveler-model.md` to learn who an entry is, which reopens the closed read
  scopes this design exists to keep closed.

### D-12 — How erasure reaches the presence file

**Selected: a positional reach row in Phase A** (Decision 9).

- **A Phase B word-boundary sweep of the file.** Rejected: a display name that is also a month word
  would rewrite co-travellers' window values, which the fixtures write as dates such as
  `May 14 (Thu)` and `Apr 9, ~1:00 PM` (`examples/data-architecture-demo/trip-context.md`:57;
  `examples/two-origin-demo/trip-context.md` § *Per-Traveler Planning Days [DERIVED]*). That is the
  ordinary-word hazard erase's own measurement names (`skills/trip-record/SKILL.md`:2302).

### D-13 — The exit when a trip has no presence file yet

**Selected: the readers' report** (Decision 12): a reader that finds no presence file says the
windows are not yet derived, and names `/trip-record travelers`.

- **A per-trip reconcile run by the build slice.** Rejected: unreachable. Operator trips live under
  the data root the operator's pointer names, outside the repository (`CLAUDE.md`
  § *Resolving a trip*, `G0-root`), so a build slice can only name a reconcile.
- **A fallback to the legacy block.** Rejected: it would give the unowned block a reader again, and
  it covers legacy trips only.
- **A stop.** Not available: freshness is report-only, and no gate may be added that blocks on it
  (`CLAUDE.md` § *Resolving a trip*, `G8`, `:369`).

### D-14 — How the reconciler's second file is admitted

**Selected: rule 16, appended as a widening of rule 6, with rule 6 left exactly as it stands**
(Decision 8).

- **An edit to rule 6.** Not admitted: the standing clause takes appended rules, not edits
  (`skills/trip-record/SKILL.md`:678-683), and rule 6's restatement in § *What the blocks above are*
  is frozen (`:324-325`, `:344`).
