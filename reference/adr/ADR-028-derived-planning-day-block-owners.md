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

**Three records rest on the no-writer state, and erasure's reach stops short of the block.**

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
   when a profile changes"* (the template's § *Per-Traveler Planning Days [DERIVED]*). Its
   per-traveller inputs are the travellers' composed journey facets, which the enrichment agent's
   reconciler role alone reads and reconciles (`reference/data-architecture.md`:69;
   `agents/00-enrichment.md`:52-57). The trip
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
with later edits, so where other releases were editing in parallel — `CLAUDE.md`'s
§ *Write ownership*, § *Resolving a trip* and Key Rules, `templates/trip-context.template.md` and
`reference/data-model.md` — the locator is a section or a label rather than a line.

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
recorded a shared *absence* of a writer. The two blocks now have different writers, lifecycles and
homes, and one row would assert a single writer for blocks that share none.

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
  (`CLAUDE.md` § *Resolving a trip*, gate `G8`).

### D-14 — How the reconciler's second file is admitted

**Selected: rule 16, appended as a widening of rule 6, with rule 6 left exactly as it stands**
(Decision 8).

- **An edit to rule 6.** Not admitted: the standing clause takes appended rules, not edits
  (`skills/trip-record/SKILL.md`:678-683), and rule 6's restatement in § *What the blocks above are*
  is frozen (`:324-325`, `:344`).

## Decision

**Two owners, each in the form the card's AC-1 names, and a row each.**

- **The trip window,** `### Effective Planning Days`, stays in `trip-context.md`. Its owner is a
  write-ownership row naming `/trip-record` (Decision 1).
- **Each traveller's window** moves out of that file into `outputs/traveler-presence.md`. Its owner
  is that class's writer row in `reference/data-architecture.md` § 1.1 — the enrichment agent, in
  its reconciler role — together with the lines it publishes there (Decision 2).
- **The two blocks do not share a row.** The one-row shape recorded a shared absence of a writer,
  and the two now differ in writer, lifecycle and home (D-6).
- **No Layer 1 — human source field changes writer.** Both writes are computed. The trip window keeps
  *Do not manually edit*. The presence file is derived and rebuilt. Readers still read published
  values, and only the window's address moves. Resolving a by-reference cell means reading the trip
  window's published line.

**The numbers in the verbatim texts below are this revision's.** Rule 15, rule 16 and reach row 31
are the next free numbers in their enumerations at `54586fd`. Both enumerations are append-only
(`skills/trip-record/SKILL.md`:678-683, `:2268`), so the slice that appends each derives its number
at its own base — exactly as the slice that adds the class row derives the class ordinal — and
carries the number it derives into every text below that names it, including the trip window's row
in Decision 1.

### 1. The trip window's owner — its row, verbatim

> | Block | Writer | Condition |
> |-------|--------|-----------|
> | `[DERIVED]` — `### Effective Planning Days` | `/trip-record` | Computed, never authored: each of its lines is recomputed in place, or reported as not recomputable, naming the unreadable input's label, in the same act, by any invocation that records a change to one of that line's declared inputs — the anchor origin's `### Outbound` or `### Return` legs as the template declares them, or `## Accommodation`'s `Check-in time:` or `Check-out time:` — under standing rule 15, and no line is rewritten on account of an input the act did not change. A statement about the block's own values records the input it derives from. |

It replaces the trip window's half of row 4. The per-traveller half leaves the table with its block
(Decision 10).

### 2. The presence class — `outputs/traveler-presence.md`

**This class's writer row is each traveller's window's owner row.**

#### Identity

- **Path:** `outputs/traveler-presence.md`, trip-relative, one file per trip. The name pairs it with
  the traveller model, whose writer, lifecycle and key entity it shares, and names the predicate it
  feeds (`reference/data-model.md` § *Presence*). Probed at `54586fd`, no tracked file carries the
  name and no `traveler-*` glob exists.
- **The row**, for the slice that adds it, which derives the class ordinal at its own base:

  | C | Class | W (exactly one) | L | Prov | P | Primary entities |
  |---|---|---|---|---|---|---|
  | *the next in-model ordinal* | `outputs/traveler-presence.md` | enrichment | `rebuilt-each-synthesis` | `derived` | `internal` | Traveler, Day |

- **The class is named by path, never by ordinal,** because the enumeration's numbering moves. That
  is `ADR-012`'s rule, reused by `ADR-016` (`reference/adr/ADR-016-reusable-groups.md`:138-140). The
  corpus inserts a new in-model class at the next in-model ordinal and renumbers the out-of-model
  dispositions after it, as `ADR-011` did (`reference/adr/ADR-011-per-traveler-cost-estimation.md`:74-76)
  and as `ADR-016` chose over appending past the closed set (`reference/adr/ADR-016-reusable-groups.md`:113-123).
- **Primary entities — Traveler, Day.** § 2 of the data architecture names presence as the Traveler
  N—M Day relation (`reference/data-architecture.md`:180, `:188`). Origin appears only as a warrant
  token; no origin letter is written.
- **Lifecycle — `rebuilt-each-synthesis`.** The file is rebuilt whole on every reconciler pass, and
  never on an `ARCHIVED` trip. § 6's reason holds for it without the traveller model's per-entry
  exception (`reference/data-architecture.md`:935-955): every entry re-derives from the roster and the
  files the pass reads, a `PROFILE MISSING` or `[OPERATOR-PROVIDED]` entry has `UNKNOWN` bases by
  rule, and no `[THIRD-PARTY]` entry exists to carry forward. It lands in § 7.6's self-upgrading row.
- **Writer — `enrichment`, reconciler role only.** Its frontmatter is the traveller model's
  (`agents/00-enrichment.md`:1050-1061), with `artifact: outputs/traveler-presence.md` and
  `publish: internal`; `generated:` is the date of the pass.
- **Provenance — `derived`:** *"A projection of authoritative inputs. It holds no independent state"*
  (`reference/data-architecture.md`:489).
- **A new class, because the model's seam cannot be extended here.** Extending the model's per-entry
  derived-line seam would narrow `ADR-011` decision 2's bound on transport's read of that file
  (fact 4 of § *Context*), and only a supersession may narrow a decision
  (`reference/adr/README.md`:26-27). Adding a class supersedes nothing: `ADR-009`'s first decision
  gives `reference/data-architecture.md` ownership of the enumeration
  (`reference/adr/ADR-009-data-architecture.md`:323-326) — a topology, not a membership list — and
  `ADR-011`, `ADR-012` and `ADR-016` each added an in-model class through a new record, a § 1.1 row
  and a schema, with `ADR-009` still `Accepted` at `54586fd`.

#### Publishability — `internal`, not `internal-hard`

- **What the file holds:** roster display names, warrant tokens, local instants, day counts and a
  zone delta. None of it is in § 5.3's non-publishable class: the file carries neither of the fields
  § 5.6 declares, `Passport` and `Documents` (`reference/data-architecture.md`:844-848), and its
  population rule admits no `[THIRD-PARTY]` entry. Each value is a publishable field by default
  (§ 5.2, `:775`), and the same values sit today in `trip-context.md`, which is `publish: bound`
  (`:58`).
- **`internal-hard` is not earned.** § 5.1 reserves it for values that must not reach a page *"in any
  form, including anonymized"* (`reference/data-architecture.md`:769-770). `ADR-011` draws the same
  line: a name beside a figure is `internal`, and a name beside a reason is `internal-hard`
  (`reference/adr/ADR-011-per-traveler-cost-estimation.md`:251-256).
- **It takes no fence row.** Group `PB` expects exactly the § 1.1 rows whose class the
  `publish-contract-artifacts` fence declares, and that fence declares only `bound` and
  `internal-hard` (`reference/site-layout-spec.md`:722-738; `scripts/test-artifact-schema.sh`:1720).
  An `internal` class takes no row there, as the cost estimate takes none
  (`reference/adr/ADR-011-per-traveler-cost-estimation.md`:301-306), and nothing in the site
  specification's § 9.3 exclusions either.
- **Not a site input.** `/trip site` reads `trip-context.md` for *"the group, dates and trip-level
  constraints the hero and overview render, and no other block"* (`skills/trip/SKILL.md`:998-1001) —
  no per-traveller window — so the page does not change. The file stays off `site`'s `**Reads:**`
  line, which is the source side of the `itinerary-to-build` freshness relation (`:334`); on that
  line, every reconcile pass would raise a false `BEHIND`.
- **The tripwire, in `ADR-011` decision 6's form.** If a value in the file ever carries a need- or
  desire-derived justification, or anything drawn from a `[THIRD-PARTY]` entry, the class moves to
  `internal-hard` and takes a row in the `publish-contract-artifacts` fence.

#### Keying — the roster name

- **The key is `## <Name>`, the `## Group` roster's display name.** Its normalized form is the
  Traveler natural key (`reference/data-architecture.md`:237-243). Identity is decided *"by a rule
  applied once per entity, never case-by-case per artifact"* (`:211`), and presence is a Traveler
  relation. The roster is the name authority (`skills/trip-record/SKILL.md`:2288), so a reader joins
  on a key it already holds, without reading the traveller model.
- **A person token, and any key only the model can resolve, are barred** (D-11).
- **The privacy cost:** a traveller's name gains one location, and Decision 9's reach row reaches it.

#### Content

- **H1:** `# Traveler Presence [DERIVED]`. Every `##` heading is an entry — there is no reserved key
  and no collapse line — so a reader has one shape to branch on.
- **Population:** every roster member whose model entry is first-party — projected from a traveller
  file, or a `PROFILE MISSING` or `[OPERATOR-PROVIDED]`-only fallback — and **never** a member whose
  entry carries `[THIRD-PARTY]`. The wording holds whether or not a third-party member ever holds a
  roster row. **From the next rebuild after an erasure**, an erased member's entry is
  `## per-<token>`, with `UNKNOWN` bases and by-reference cells. On an `ARCHIVED` trip no rebuild
  runs — erasure substitutes and never regenerates — so the lines keep their pre-erasure values under
  the token heading.
- **The lines,** each whole on its label's line, in this order: `- **Window basis:**`,
  `- **Origin basis:**`, `- **Effective window (local):**`, `- **Full + partial:**`,
  `- **Timezone delta:**`. A basis line takes one warrant token. `Window basis` governs the window and
  the count; `Origin basis` governs the delta.
- **By reference.** A cell governed by `ASSERTED-SAME` or `UNKNOWN` reads `the trip-level window`,
  `the trip-level total` or `the trip-level delta`, with ` (assumed)` under `UNKNOWN`. Only
  `ASSERTED-DIFFERENT` carries a value, in the shapes the template's per-traveller table declares
  today (`templates/trip-context.template.md` § *Per-Traveler Planning Days [DERIVED]*). A reference
  resolves to the trip window's published lines, which are read and never re-derived.
- **The allowlist bound.** An entry carries its heading and these lines, and nothing else drawn from
  any per-traveller source. An `ASSERTED-DIFFERENT` statement that does not resolve to instants takes
  the line's bracketed placeholder, and the reconciler raises a `VERIFY` in the traveller model's
  `## Update signals` block that names the field label and never quotes the statement — prohibition
  2 of that block (`agents/00-enrichment.md`:516-521). A statement's text is never written onto a
  window line; the free-text path it arrives by is the intake form's `Arrive / leave:`
  (`templates/traveler-intake.template.md`:113).
- **The rebuild announces what will not survive.** Before writing, the reconciler reads the file it
  replaces and states everything that will not survive the rebuild: every line whose value changes,
  outgoing then incoming, and every entry the rebuild removes — a member who has left the roster, for
  one. That is `ADR-007` § 2 bound 5's *say before writing what will not survive*
  (`reference/adr/ADR-007-command-entry-point.md`:330-337), and `/trip`'s standing clause puts the
  obligation on the verb that dispatches a replacement (`skills/trip/SKILL.md`:193-201, `:928-931`).
  **The announce is surfaced at every verb that dispatches the rebuild:** `/trip-record travelers`,
  `/trip-record person`, `/trip plan`, and `/trip replan` when a changed profile triggered it.
- **The class-wide question is routed, not decided here.** Read this way, bound 5 reaches every
  `rebuilt-each-synthesis` class a dispatched agent replaces — the traveller model rebuilt in the same
  pass, and the hub's and the validator's rebuilds that `plan` replaces — while the data architecture
  calls such regeneration safe (`reference/data-architecture.md`:489, `:930`). Whether those classes
  owe the same announce is routed outside this release; this record decides it for the presence file
  alone.

### 3. Inputs, triggers and repair

**The trip window.** Its inputs are declared per line:

- the arrival line ← the final anchor `### Outbound` leg's `Arrives:`, and `Check-in time:`;
- the departure line ← the first anchor `### Return` leg's `Departs:`, and `Check-out time:`;
- the full-days line ← those two dates;
- the total line ← every input of the arrival, departure and full-days lines;
- the delta line ← the anchor legs' timezone annotations.

The hotel-departure time is not an input (D-9). *Trigger:* an act that records a change to a line's
input. *Repair:* that line, in that act, under rule 15 (Decision 7).

**Each traveller's window.** *Inputs:* the `## Group` roster; each member's composed `Leaving from:`
and `Arrive / leave:`, and whether they have a profile at all; `### Additional origins`; the anchor
legs and trip dates an `ASSERTED-DIFFERENT` statement resolves against; `Check-in time:` and
`Check-out time:`. *Trigger:* every reconciler pass. *Repair:* the rebuild, which announces what it
replaces (Decision 2).

**What reaches which.** A destination change reaches neither. A change of dates reaches the trip
window only through its legs. A roster change, or a change to an origin other than the anchor,
reaches each traveller's window only. Check-in and check-out reach both.

*"Staleness is reported, never repaired in place"* survives for neither block; its descendant is
Decision 6.

### 4. The enrichment contract

**The reconciler's write set widens by one rebuilt file, the presence file.** The `[ENRICH]`-only
contract on `trip-context.md` does not widen, and the research role widens nowhere (D-3).

**Not widened, on purpose: the enrichment row's `Output File` cell** in `CLAUDE.md`'s agent roster
(`:294`). A path under `outputs/` in that cell enters `/trip research`'s agent-key filter
(`skills/trip/SKILL.md`:877-880). The presence file is declared where the cost estimate is — in
`reference/data-architecture.md` § 1.1 and in `CLAUDE.md`'s File Structure tree — and not in
§ *Output Versioning*, whose absence rule yields to § 1.1 (`reference/data-architecture.md`:985-1005).

### 5. Provenance

**`Last derived:` retires with the per-traveller block.** Each window's provenance is the presence
file's `generated:` — the date of the pass, written on every rebuild. A `generated:` older than the
newest input change means no rebuild has run since. That is never a defect and never a gate, because
the surface that changed the input already said so (Decision 6). **The trip window carries none:** its
repair happens in the act that changes its input, and a date line would be read by nothing
(`skills/trip/SKILL.md`:301).

### 6. Staleness and routing

*"Staleness is reported, never repaired in place"* survives for neither artifact.

- Until the next rebuild, every surface that changes an input of a traveller's window and does not
  dispatch the reconciler says in its own output that the presence file is behind, and names
  `/trip-record travelers`.
- Those inputs are: the roster; a member's composed `Leaving from:` or `Arrive / leave:`, or whether
  they have a profile at all; an `### Additional origins` block; an anchor leg; check-in or
  check-out; the trip dates.
- An input of the trip window is recorded through `/trip-record fact`.

### 7. Standing rule 15, appended by the later slice, verbatim

> 15. **Recomputing a `[DERIVED]` block's lines in the act that records one of their declared inputs
> is rule 2's fourth admitted shape, and it is stated as a widening of rule 2; rule 7, the earlier
> widening of rule 2, is left exactly as it stands.** Where a verb writes a value the template
> declares as an input of a `[DERIVED]` block that `CLAUDE.md` § *Write ownership* assigns to this
> command, the same act recomputes, by the derivation the template states and no other and from the
> inputs as they stand after the write, **only the lines of that block whose declared inputs include
> a value this act changed**; it never rewrites a line on account of an input it did not change,
> whatever that line holds. A recomputed line takes its bracketed placeholder (rule 3) only where an
> input this act changed cannot be read in the shape the template declares; where an unchanged input
> of that line cannot be so read, the line is left byte-identical and the verb says it could not
> recompute it, naming that input's label. Nothing is parsed out of undeclared prose and nothing is
> estimated. Before writing, the verb echoes every line it replaces, outgoing then incoming —
> `ADR-007` § 2 bound 5's *say before writing what will not survive*. **A `[DERIVED]` block is a
> derived artifact in that bound's sense:** each of its lines is computed from declared inputs held
> in the same file, holds no independent state and can be recomputed from them at any time, which is
> the property `derived` provenance names, and the echo preserves what a replaced line held. **Its
> extent is its derived lines** — the bullet lines the template declares beneath the block's
> heading — and never the heading, its tag or the blockquote prose above those lines. It reads the
> blocks holding the declared inputs and no others. A statement about the derived block's own values
> is recorded as the input it derives from. **It binds every verb, present and future,** because its
> trigger is the input and not the verb: a rule placed in `fact` would leave the next verb that
> records such an input without a tool.

### 8. Standing rule 16, appended by the later slice, verbatim

> 16. **Dispatching a role that writes more than one file is stated as a widening of rule 6, and
> rule 6 is left exactly as it stands.** Where the role a verb dispatches writes more than one file,
> the verb's own section names the agent, its role and every file that role writes, on the same
> line; a write the section does not name is out of scope exactly as rule 6 makes it. The role's
> reads, a read that precedes a replacing write among them, are declared where § *What the blocks
> above are* already requires them: in the dispatching verb's own section. **It binds every verb,
> present and future,** because the write set belongs to the role and every verb that dispatches the
> role meets it: in this revision the enrichment agent's reconciler role writes the traveller model
> and the presence file, and more than one verb of this revision dispatches that role.

### 9. The erase reach row, appended by the later slice, verbatim

> | # | Location | Disp. | What happens |
> |---|---|---|---|
> | **31** | `outputs/traveler-presence.md` — the entry heading | REACH | substitute to `## per-<token>`, **without** the `[ERASED]` mark, which stays the model's alone. The lines beneath it carry no name by the writer's own bound, so no free-text pass runs over them. Where the trip has no presence file, emit **`n/a`** and name the absent file; where the file holds no entry for the subject, emit **`n/a`** and name the population rule that admits none. **Never a silent skip** |

**Its coupling, stated as a fact.** No instance of the presence file holds a name before this row
exists. The table's accounting, the Phase A list and the write order take the row in the same
change, and no arm ties the reach table to the class enumeration. What moves with the row, named so
the change carries all of it:

- **The accounting is two sentences, not one.** The tally group `ER14` grades against the table
  (`scripts/test-artifact-schema.sh`:7047-7095) moves; so does the sentence after it — *"Rows 1–28
  and row 30 are the locations a copy of the person's data can reach"*
  (`skills/trip-record/SKILL.md`:2266) — which no arm grades and which the new row makes false.
- **The row joins Phase A** (`:2298`) **and step 5 of the write order** (`:2286`), beside row 10, and
  step 5 keeps row 10 as its first row reference: `ER12` finds the model's write step by the first
  `row N` in each step (`scripts/test-artifact-schema.sh`:6982-6996, `:7002`).
- **Row 10 stays the only `[ERASED]` site.** That single site is `ER8`'s claim — the mark lives on the
  derived model's entry heading *"and NOWHERE ELSE"* (`scripts/test-artifact-schema.sh`:7344-7345) —
  and `ER8` pairs only bearer files with model entries (`:7353-7375`), so it cannot see a presence
  file. The new row's substitution and its bare token are therefore conduct (§ *Consequences*,
  § *What nothing grades*).

**Phase A, positional, written at step 5 beside row 10.** The heading is a projection of the roster
cell written at step 1, so the authority-first order `ER12` grades holds
(`scripts/test-artifact-schema.sh`:6970-7013). The file is kept out of Phase B on purpose (D-12): its
lines stay name-free because the writer's own bound says so, not because a sweep catches them.

**Why it can be ordered:** the file does not exist yet. The `## Logistics` gap stays routed outside
this release, and this record writes no name there.

### 10. The event, verbatim

> For `### Effective Planning Days`, `ADR-024` decision 6's conditional exclusion ends — and the
> region enters the contract by that record's own rules — at the change that names its writer in
> `CLAUDE.md` § *Write ownership*. Decision 2D makes the fence key an address pointing at that table,
> so a region's declared writer is the writer the table declares. For `### Per-Traveler Planning Days`
> the exclusion ends with the region, at the change that removes it from the template; until then the
> table declares no writer for it and decision 6 keeps it outside. This record's merge and its
> ratification change neither the table nor the template. Deciding an owner does not authorize a
> write: until the table names one, *"A writer not named for a block does not write it"* keeps
> Effective unwritable.

### 11. Where the rules live

- The trip window's derivation, with its per-line inputs, stays in the template.
- The presence file's labels, vocabulary, derivation rules, value shapes and by-reference forms go in
  a section appended below the end of `reference/data-model.md`.
- § *Presence* cites that section and the file, and it is edited only in place at equal line count —
  `ADR-009`'s ordering rule (`reference/adr/ADR-009-data-architecture.md`:342-348).

### 12. Readers and the transition

**The four readers read each window from the presence file, as read-never-re-derived.** What each
re-points, and what stays byte-identical:

| Reader | Re-points | Stays byte-identical |
|---|---|---|
| scheduling | the presence pointer (`agents/03-scheduling.md`:39-42); input item 4 (`:314-319`); the Day-key sentence (`:489-491`); the cross-reference inside the model read's first bullet (`:345-347`), which names where the *other* limb comes from | *"two reads, and only these two"* (`:344`), and both reads |
| transport | input item 3 (`agents/04-transport.md`:188-190); the membership sentence that follows item 7's scope (`:206-210`), below — item 7's bytes change there, its read of the model does not | item 7's read scope, *"for the depth signal and for nothing else"* (`:202-205`) |
| hub | the presence read in § *What you read* (`agents/05-hub-planner.md`:1009-1010); the Presence row (`:1108`); step 5 (`:1134`) | *"`outputs/traveler-model.md` is not read into this artifact"* (`:1018-1020`), and the carry bound |
| validator | the window limb (`agents/06-validator.md`:620-621); the input list gains the file as an appended item, with nothing renumbered | input item 8 (`:842-844`) |
| data-model § *Presence* | each line of the section that names the per-traveller block — the trip-day set's scope, the window's one-home sentence, the window limb, the partial-day reading, the assumed-window paragraph and the no-presence-data paragraph — edited in place, one physical line each, at equal line count (`ADR-009`'s ordering rule); the no-presence-data paragraph carries the no-entry default below | every rule the section states |

**Transport's membership sentence.** Today it reads *"Stream membership comes from `## Logistics`
and the `## Group` roster, never from here: …"*. After the re-point it reads *"Stream membership
comes from `## Logistics`, the `## Group` roster and item 3's windows in
`outputs/traveler-presence.md`, never from here: …"*, and the rest stays verbatim. It changes because
`## Logistics` covered item 3 only while the block sat inside it. The `[THIRD-PARTY]` ground still
holds: *here* is still the model, and its scope is unchanged. The new source cannot drop a real
passenger — it never carries a `[THIRD-PARTY]` entry and writes no origin, and a roster member with
no entry reads under the no-entry default, on their origin's booking — so the window limb can take
out only a first-party traveller who stated a different window.

**A subject with no entry has no derivable window.** For the window limb they are present every trip
day, read as an assumption exactly as an `UNKNOWN` basis is. That covers a `[THIRD-PARTY]` member by
rule, a roster member added since the last pass, and anyone on a trip whose presence file does not
yet exist.

**Where the file itself is absent, the reader says the windows are not yet derived, and names
`/trip-record travelers`.** The exit is a report rather than a stop because freshness is report-only:
`G8` never changes a resolution, and no gate may be added that blocks on freshness (`CLAUDE.md`
§ *Resolving a trip*, gate `G8`). **A placement reader carries `(assumed)` into whatever it places under
that default** — the whole-group anchor scheduling places, the stream transport sizes and prices — as
§ *Presence* already requires of anything that cites the set under an assumed window.

### 13. Limits

- Each writer touches its own block, file or lines and nothing else.
- Only first-party roster entries get presence lines, and only the declared labels are written: no
  facet, passport, documents or engagement-axis value.
- Nothing is written on an `ARCHIVED` trip except erasure's substitution.
- An unanswered or unresolved input takes a placeholder, `UNKNOWN` or `(assumed)`, never an estimate.
- Deciding is not authorizing.

## Consequences

### What becomes false or is re-grounded, surface by surface

Each paragraph says what becomes false, or is re-grounded, **when the named change lands**. None of
them is a schedule.

**`CLAUDE.md`.** Row 4 of § *Write ownership* becomes the trip window's row alone, naming
`/trip-record` (Decision 1), and its *"read-only to every command"* and *"staleness is reported,
never repaired in place"* become false. The per-traveller half leaves the table with its block, and
row 9 needs nothing. The table's opening paragraph and its `[ENRICH]` row, the Key Rules bullets
that the enrichment agent writes only the `[ENRICH]` fields (*trip-context.md is sacred*) and that
name the satisfaction-layer homes (*Satisfaction-layer homes*), and § *Output Versioning* stay true,
because the roster's enrichment `Output File` cell (`CLAUDE.md`:294) is not widened (Decision 4). The File Structure tree gains the file, as it carries
`outputs/cost-estimate.md`. Step 1's context-update and booked-what rows (`:195`, `:219`) become
incomplete for an input of the trip window: only `fact` keeps the block true.

**`skills/trip/SKILL.md`'s dispatch sentences.** `/trip plan` dispatches each agent *"each writing
exactly the file or files that row names and nothing else"* (`skills/trip/SKILL.md`:669-672). The
roster's enrichment row names only the `[ENRICH]` fields (`CLAUDE.md`:294), while the reconciler
writes `outputs/traveler-model.md`, so that sentence is already false at `54586fd`, independently of
this record. This record adds a second unnamed write — the presence file — as a consequence of its own
decision not to widen that cell. Beside it, `/trip replan` attributes a profile-triggered enrichment
leg (`:731-733`) that its own *Dispatches* sentence omits (`:735-737`), a gap of the same class that
the presence file inherits. Rule 16 binds `/trip-record`'s verbs only and does not reach these
sentences, although its reason — the write set belongs to the role — reaches them equally.

**`agents/00-enrichment.md`.** False when the writer emits: the collapse-line count and vocabulary
pointer (`:213-218`); the report-and-name-no-command limb (`:229-240`); *"derived model out"*
(`:303`); and *"the one artifact you write in your own name"* (`:1039`). It gains the presence
emission and its announce in its Output section (`:1026-1028`), and a frontmatter block. It stays true
at `:61-63`, `:67-69`, `:169-172` and `:310`.

**`agents/03-scheduling.md`.** It re-points as Decision 12's table states, and its day shape changes
too: input item 3 (`:311-313`) ends the departure day's usable window at the anchor stream's
`Recommended hotel departure:` (`agents/04-transport.md`:584), under the absent-brief rule
(`:338-341`). That value is current under `reorder`, whose chain runs transport before scheduling
(`skills/trip/SKILL.md`:808, `:811`), and under `plan`, which dispatches in the pipeline order; it is
as last written under a `replan` whose coupling conditions admit scheduling alone (`:745`); and under
`research` it is the previous value or none (`:871`), which scheduling then says.

**`agents/04-transport.md`, `agents/05-hub-planner.md` and `agents/06-validator.md`** re-point as
Decision 12's table states, and their closed scopes stay byte-identical.

**`templates/trip-context.template.md`.** § *Per-Traveler Planning Days [DERIVED]* retires, and its
rules move to data-model (Decision 11). The scope notes that point at it — the one closing
§ *Additional origins* and the one inside the trip window's block — re-point, keeping the words
`ADR-018` quotes, *"must read each traveler's own derived window"* and *"not this block"*
(`reference/adr/ADR-018-cost-estimation-method.md`:166-167). The trip window's *"Computed from
flight data"* note declares its per-line inputs, and its departure line loses its hotel clause (D-9).
**The preamble becomes true** — *"Layer 1 (user-provided) and `[DERIVED]` fields are completed before
any agent runs"* — because the one `[DERIVED]` block left in the file is completed by a recording
command.

**`reference/data-model.md`.** § *Presence* re-points in place (Decision 12). In § *Who Writes What —
Field Layering*, the derived-reconciled row gains the file; *"Its write set is unchanged: the source
set widens, the write set does not"* becomes false; and *"The derived traveler model is the
**feed**"* becomes incomplete for presence. § *The reference month*'s quotation of the departure
line's gloss is corrected in place when the hotel clause leaves the template, and `ADR-015` decision
1 is untouched. A section is appended at the end — labels, vocabulary, derivation, value shapes and
by-reference forms. *"Composition writes neither"* and the reserved list stay true.

**`reference/data-architecture.md`.** It gains the class row, with § 1.2 renumbered after it; the
class's § 6 membership; § 7.6's self-upgrading row; and a § 9 row. Its count sites move with them. The
trip file's row, the traveller model's row, § 5.1's `internal-hard` set and § 5.6 are unchanged.

**`scripts/validate-artifacts.sh` and `reference/schemas/`.** `VA_CLASS_HEADING` moves with the
§ 1.1 heading (`scripts/validate-artifacts.sh`:139), and the pair is graded by arms `HC1` and `HC2`
(`scripts/test-artifact-schema.sh`:593-625). A schema and a witness land with the row. The witness
goes in the two-origin example, whose trip file exercises every basis on both axes
(`examples/two-origin-demo/trip-context.md` § *Per-Traveler Planning Days [DERIVED]*).

**`skills/trip-record/SKILL.md` — the standing clause** gains rules 15 and 16. Rules 2, 6, 7 and 14,
and the frozen § *What the blocks above are*, stay true as written.

**`skills/trip-record/SKILL.md` — `fact`.** Its *Reads:* line (`:1280`), its `[DERIVED]` route
(`:1306`), its one-block rule (`:1321-1322`) and its cross-block row that names no command (`:1372`)
become false, and rule 15 admits each change. Its admission test (`:1289-1298`) stays true. **What
rule 15 does not promise through `fact`:** `fact`'s write shapes (`:1330-1344`) do not require an
input of the trip window to be written in the shape the template declares, so where an operator
states a changed leg in prose, the line that input feeds takes its bracketed placeholder. Through
`fact`, a populated line takes its placeholder only when the input the operator changed does not
resolve.

**`skills/trip-record/SKILL.md` — `travelers` and `person`.** Their *Reads:* lines' *"writes
`outputs/traveler-model.md` alone"* (`:933`, `:981`) and `travelers`' *"the one file that role
writes"* (`:983-985`) become false; rule 16 names both files; and the *Reads:* lines gain the read of
the presence file before it is replaced. `travelers`' changed-journey-facet row (`:1001`) becomes:
rebuilt — render what the rebuild replaced, every changed line and every removed entry, and name
`/trip replan` as the changed-need row does. `person` surfaces the same announce, because it
dispatches the same rebuild (Decision 2).

**`skills/trip-record/SKILL.md` — its other verbs.** `profile`, `group`, `link`, `unlink` and
`extract` already name `/trip-record travelers`; `group-expand`, `destination`, and `fact` for a leg
or an origin gain it; and `promote`'s precedent — `travelers`' changed-journey-facet class, which
names no command (`:2162-2163`) — is lost.

**`skills/trip-record/SKILL.md` — `erase`.** The reach row, with its accounting, its Phase A entry
and its step (Decision 9). Row 10 stays the only `[ERASED]` site, and the `## Logistics` gap stays
routed outside this release.

**`skills/trip-new/SKILL.md`.** Its account of the per-traveller block as a roster input
(`:434-436`) re-points, and its collapse sentence goes. Its bound that it writes no `[DERIVED]` block
(`:500-502`) stays true, but its ground — *"the `[DERIVED]` blocks to no writer at all"* — becomes
false.

**`skills/trip/SKILL.md`.** The freshness family is not extended: the presence file is on no
relation's source side (Decision 2). The attributed reads of `plan`, `replan`, `reorder` and `check`
(`:665-669`, `:729-735`, `:802-807`, `:914-916`) gain the file, and `research` cites its spoke's
prompt for its reads (`:864-870`), so it gains the file through the prompts. `/trip plan` and a
profile-triggered `/trip replan` surface the rebuild's announce (Decision 2).

**`ADR-015`.** Its no-writer ground (`reference/adr/ADR-015-durable-field-validity-horizon.md`:84-88,
`:98`, `:335-337`) becomes false for the trip window when its row lands. Decision 1 stands. The year
question that ground closed — whether the trip window could carry a year and serve as a source of the
trip term — opens again, because the block now has a producer.

**`ADR-018` decision 5.** Its address (`reference/adr/ADR-018-cost-estimation-method.md`:161-163)
becomes a citation whose target moved, correctable in place by amendment
(`reference/adr/README.md`:18-20). *"Read, never re-derived"* is unchanged.

**`ADR-011` decisions 2 and 6, and `ADR-012` decision 3,** are untouched (the reading below; D-11).

**`ADR-024`, `ADR-025` and the planned work that rests on the no-writer state.** `ADR-024` decision
6 executes per region (Decision 10). Its interviewability table's row 4 keeps its NO
(`reference/adr/ADR-024-form-contract-writer-boundary.md`:374), the ground moving to `ADR-023`'s
conformance question 5 for the trip window, and its reconciled totals (`:381-384`) describe the
commit they were measured at. *"Has no writer"*, in `ADR-025`'s finding 4, becomes false, and that
finding's disposition stands (`reference/adr/ADR-025-engagement-model-over-time.md`:823-827). The
planned trip-context conformance slice's declared exclusion of the `[DERIVED]` regions holds until
the trip window's row is rewritten and is then re-grounded — still NO, on question 5 — and for the
per-traveller block it ends when the region leaves the form. The planned classification backfill's
exclusion ground for row 4 moves to question 5 in the same way. The template's *Recompute trigger*
label leaves with its block, and the mechanism it named becomes the presence file's rebuild.
§ *References* names each planned item.

**Legacy trip files.** A trip file carrying the old per-traveller block keeps an unowned, unread
block whose names erasure does not reach today. This record does not widen that.

**The rest of the consumer set, named so that the set closes.**

- `reference/replan-protocol.md` reads the trip window's arrival line for the trip's first day
  (`:31-34`). The line and its input are unchanged, so it stays true.
- The worked examples built to show the per-traveller block — `examples/two-origin-demo/`,
  `examples/single-origin-demo/`, and the block and its commentary in
  `examples/data-architecture-demo/` — describe a block the retirement removes, so each becomes false
  when the retirement lands. `examples/tokyo-2026/` carries the trip window alone and stays as it is.
- `reference/adr/ADR-027-post-trip-preference-memory.md` names this ownership decision as a sibling
  premise and takes no `[DERIVED]` dependence, so nothing in it moves.
- Past `CHANGELOG.md` entries describe the releases that shipped them.

### The couplings — three landing sets

The consequences above land in three sets. Each set is forced by a rule live at `54586fd`, and each is
a coupling, not a schedule: it says what lands together, or no earlier than something else, and never
when.

1. **Scaffold — may land first.**
   - The class row, with § 1.2's renumber, and the § 1.1 heading moving together with
     `VA_CLASS_HEADING` (arms `HC1` and `HC2`).
   - The schema and the witness, together. Until the schema lands, the residual targeted-research
     class claims the file — its selector is `trips/*/outputs/*.md`
     (`reference/schemas/targeted-research.md`:11-12) — the witness included, and erase's row 12
     would then sweep it in Phase B, which is the month-word hazard the new reach row exists to avoid.
   - The reach row, with its accounting, the Phase A list and step 5, keeping row 10 first in step 5
     for `ER12` (Decision 9).
   - The witness lands with the reach row or after it. It is an instance that holds names, so the
     row's own coupling — no instance holds a name before the row exists — orders it, even though
     `examples/**` is outside erasure's reach (`skills/trip-record/SKILL.md`:2256).
2. **Cutover — one change.**
   - The writer's first emission of the presence file.
   - Rule 16, with `person`'s and `travelers`' *Reads:* lines and `travelers`' naming sentence
     (`skills/trip-record/SKILL.md`:933, `:981`, `:983-985`).
   - The enrichment prompt's *"the one artifact you write in your own name"* and *"derived model
     out"* (`agents/00-enrichment.md`:1039, `:303`).
   - Data-model's write-set sentence, and § *Presence*.
   - The four readers, with transport's membership sentence.
   - The rebuild's announce, surfaced at every dispatching verb.

   **Why these land as one change.** Rule 6 forbids the second file before rule 16 exists. Rule 16's
   own supporting fact is false before the second file exists. The verb lines and the enrichment
   sentences go false the moment it does. And data-model promises that every consumer cites the
   presence rule and none re-derives it, with one home for the window (§ *Presence*) — which holds at
   every commit only if the writer and the re-points land together. No script or workflow quotes rule
   6 or those verb lines, so none of this is graded.
3. **Retire — no earlier than the cutover.** The template's per-traveller block, and the
   per-traveller half of row 4.

### The per-trip transition

An `ACTIVE` trip whose presence file does not exist yet reads under data-model's no-entry default:
the reader says the windows are not yet derived and names `/trip-record travelers` (Decision 12). A
`plan` rebuilds the file first, because its enrichment leg reads the traveller files before any spoke
runs (`skills/trip/SKILL.md`:665-666). The transition binds the presence class exactly as it bound the
model-lines option, W1.

### The reading of `ADR-011` this record takes

**Each clause of `ADR-011` decision 2 binds as far as its own stated ground reaches** — the method
that already set W1 aside.

1. **The path read is conceded.** A read of a path is any filesystem observation, and is what a
   `Reads:` line declares (`CLAUDE.md`:249). Transport and scheduling read a file they did not read
   before: today transport reads `trip-context.md` fully (`agents/04-transport.md`:182, `:188-190`)
   and scheduling's item 4 reads the block there (`agents/03-scheduling.md`:314-319); after the
   re-point both read `outputs/traveler-presence.md`.
2. **The heading clause reaches the estimate's writer.** *"The writer is `hub`, singular, and no
   spoke gains a read or a write"* (`reference/adr/ADR-011-per-traveler-cost-estimation.md`:83) is
   grounded only in the paragraph beneath it — a spoke *writing the estimate* would need its
   siblings' outputs (`:85-87`). The record states its own scope, deciding *"where a cost estimate
   lives, what an entry marker may carry, and how coverage is counted"* (`:7-8`), and the heading's
   one restatement in the corpus scopes it in terms: *"No spoke gains a read or a write here"*
   (`reference/schemas/cost-estimate.md`:79).
3. **The item-7 paragraph reaches a wider read of the traveller model.** Its ground is
   purpose-independent but file-scoped: a transport read of `outputs/traveler-model.md` past the
   depth signal could drop a `[THIRD-PARTY]` passenger from a stream being priced (`:89-93`). That is
   what bars W1, and it still does.
4. **The presence file is neither.** It is not the estimate's writer, and it is not a read of the
   traveller model. The hazard `:89-93` names is designed out rather than avoided: the file never
   carries a `[THIRD-PARTY]` entry, and a member with no entry stays on their origin's booking under
   the no-entry default, which data-model already declares normal for such a member (§ *Presence*,
   its no-presence-data paragraph).
5. **This record does not rely on `:87`'s *"which no spoke does"*.** It was inexact on the day
   `ADR-011` was accepted: at `571285e` scheduling already read a sibling spoke's output,
   `outputs/transport-brief.md` (`agents/03-scheduling.md`:333 at that commit).

No decision of `ADR-011` changes, so nothing is amended and nothing is superseded
(`reference/adr/README.md`:15-17, `:26-27`). The residual — a later reading of the heading clause as
barring any new spoke file read — is carried in § *Residuals*; on this ground its confidence rises
from medium-high toward high.

### What nothing grades

These remain conduct until a later slice arms them:

- the population rule and the allowlist bound, including the no-name property of the lines;
- the by-reference rule;
- rule 15's line scope, its extent and its echo;
- rule 16's naming;
- the rebuild's announce;
- the reach row landing no later than the first emission;
- the reach row's substitution and its bare token — `ER8` cannot see a presence file (Decision 9);
- the readers' report.

**One exception is graded.** Group `HZ` reads the trip window's `Departure day` line, and arm `HZ10`
grades the month it resolves (`scripts/test-artifact-schema.sh`:8921-8930, `:9040-9050`), so the
reshape keeps that line's date head and its label.

### What is retained, what changes, and what is not extended

- **Retained:** one writer per block, because the table's opening rule holds for every block; the
  `[ENRICH]`-only contract, because no byte of the trip file becomes the agent's; and the lifecycle
  vocabulary, because the class takes an existing token.
- **Changed:** the one-row shape, because the two blocks now differ in writer, lifecycle and home; and
  the reconciler's single-file write set, widened by appended rule 16 while rule 6 stays as written.
- **Not extended:** the model's per-entry seam. The class is new because extending that seam is not
  possible within this release (fact 4 of § *Context*).
- **Weighed on three axes:** best practice — one home per fact and one writer per file; scalability —
  the lines grow with the first-party roster and are rebuilt rather than accumulated; and
  maintainability — the vocabulary has one home, and every reader cites it.

### Reversibility

**EXPENSIVE, confidence MEDIUM-HIGH.** Once `Accepted`, this record is supersede-only as to its
decisions; while it is `Proposed`, revising it is CHEAP. Its costs are additive — a class row, a
schema, a witness, a reach row and the reader re-points — and this record pays none of them.

## Residuals

- **A hand edit to an input of the trip window outside the command surface** leaves the trip window
  behind it: rule 15 binds verbs, not editors.
- **A hand edit to a traveller file or a person record**, and `promote`'s cross-trip reach, change a
  window's input with no verb to report it until the next rebuild.
- **The stale-present window.** Chains with no enrichment leg — `replan` without a profile trigger,
  `reorder`, `check` and `research` (`skills/trip/SKILL.md`:731-733, `:808`, `:871`, `:916`) — read
  the last rebuild after an input changed. The guard is the in-act report (Decision 6). A
  reconcile-first leg is not decided, and it stays the named structural fix.
- **The placement cost of the no-entry default over a legacy pinned window.** Take an `ACTIVE`
  multi-origin trip whose legacy block pins a late `ASSERTED-DIFFERENT` arrival, worked with `reorder`
  or with `replan` without a profile trigger before any rebuild. The readers find no presence file and
  read every member as present every trip day, so transport sizes and prices the anchor stream with
  that traveller on it, and scheduling can place a whole-group anchor on a day they are not there.
  *Every day* is the fail-closed direction for a needs grade but the fail-open direction for *"a slot
  nobody can take"* (`reference/data-model.md` § *Presence*). A stop is not available, because
  freshness is report-only (`G8`), so the report and the `(assumed)` a placement reader carries are the
  exit, and the reconcile-first leg is the structural fix.
- **A line with a changed input and an unreadable unchanged one keeps its prior value until that
  input is recorded in the declared shape.** Rule 15 leaves such a line byte-identical and says so
  only in the act's output, so the file carries no mark of it. The worked example
  `examples/data-architecture-demo/trip-context.md` has that shape: its legs are `- **Date:**` bullets
  under populated trip-window lines (`:44-60`), so a recorded change of check-out would leave its
  departure and total lines computed from the old value.
- **A pinned traveller's partial-day count trails check-in and check-out until the next pass.**
- **The year question, now reachable** (`ADR-015`, above).
- **Legacy blocks, and the `## Logistics` reach gap,** both routed outside this release, and the
  `## Update signals` block's reach, routed beside them (DD7).
- **The altitude cost.** The presence class sits beside the model's seam rather than extending it.
  Folding it in later is the supersession path.
- **A later reading of `ADR-011` decision 2's heading clause as barring any new spoke file read.**
  This record states the reading it takes (§ *Consequences*); a reader who takes the other would count
  the moved address as a gained read.

## References

- `reference/adr/README.md` — the convention, the status lifecycle, and the amendment boundary the
  reading of `ADR-011` rests on
- `reference/adr/ADR-007-command-entry-point.md` — § 2 bound 5, which rule 15's echo and the
  rebuild's announce satisfy
- `reference/adr/ADR-009-data-architecture.md` — the enumeration's ownership, and data-model's
  ordering rule
- `reference/adr/ADR-011-per-traveler-cost-estimation.md` — decisions 1, 2 and 6: the
  class-insertion precedent, the bound on transport's model read, and the tripwire's form
- `reference/adr/ADR-012-people-library.md` — decision 3: the person key's single location
- `reference/adr/ADR-015-durable-field-validity-horizon.md` — the no-writer ground, and the
  reference month its decision 1 adopts
- `reference/adr/ADR-016-reusable-groups.md` — options O7 and O8, and naming a class by path
- `reference/adr/ADR-018-cost-estimation-method.md` — decision 5: presence read, never re-derived
- `reference/adr/ADR-023-interviewer-authored-home-and-form-contract.md` — conformance question 5,
  which refuses any field marked `[DERIVED]`
- `reference/adr/ADR-024-form-contract-writer-boundary.md` — decision 6, which this record executes
  per region
- `reference/adr/ADR-025-engagement-model-over-time.md` — finding 4
- `reference/adr/ADR-027-post-trip-preference-memory.md` — names this decision as a sibling premise
- `CLAUDE.md` — § *Write ownership*, the agent roster, § *Step 2* on what a read is,
  § *Resolving a trip* (`G0-root`, `G8`), § *Dispatching agents*, and the File Structure tree
- `agents/00-enrichment.md`, `agents/03-scheduling.md`, `agents/04-transport.md`,
  `agents/05-hub-planner.md`, `agents/06-validator.md`
- `templates/trip-context.template.md`, `templates/traveler-intake.template.md`
- `reference/data-architecture.md`, `reference/data-model.md`, `reference/replan-protocol.md`,
  `reference/site-layout-spec.md`
- `reference/schemas/targeted-research.md`, `reference/schemas/cost-estimate.md`
- `skills/trip-record/SKILL.md`, `skills/trip/SKILL.md`, `skills/trip-new/SKILL.md`
- `scripts/test-artifact-schema.sh`, `scripts/validate-artifacts.sh`,
  `scripts/test-adr-conformance.sh`, `.github/workflows/adr-conformance.yml`
- `examples/data-architecture-demo/trip-context.md`, `examples/two-origin-demo/trip-context.md`,
  `examples/single-origin-demo/`, `examples/tokyo-2026/`
- Work items this record's decision touches:
  - #1202 — this record's card: who owns the `[DERIVED]` blocks, on what trigger, and whether the
    enrichment contract widens
  - #1352 — the planned trip-context conformance slice, whose declared exclusion of the `[DERIVED]`
    regions this record re-grounds
  - #1356 — the planned classification backfill, whose exclusion of the `[DERIVED]` row moves to
    `ADR-023`'s conformance question 5
  - #1337 — the template's *Recompute trigger* label, which leaves with its block
  - #1360 — the proposal that decision records carry no planning content; this record states
    consequences and schedules none
