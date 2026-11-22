# ADR-049: What a rebuild owes — `ADR-007` § 2 bound 5 read per unit: a unit no surviving input can rebuild is preserved or named before the write, a unit rebuilt from surviving inputs owes nothing, and erasure is the bound's one exception

- **Status:** Accepted (2026-11-21)
- **Deciders:** repo maintainer
- **Driving work:** #1493, in the *Each traveller's planning-day window has one home* milestone.
  Its direction was settled at the backlog review of 2026-10-24 (Saturday), and this record
  transcribes it, with the cases that milestone's design measured since.
- **What this record is.** A decision about **which content a command that replaces a derived
  artifact must protect**, and about the one operation that may remove trip content the bound
  otherwise protects. It is addressed to whoever writes or edits a verb that dispatches a
  rebuild, or an agent prompt that performs one.
- **What this record is not.** It builds nothing: it edits no verb, prompt, table row, class row,
  schema or other record. It names, under § *Consequences*, the surfaces its reading makes false.

## Context

**Bound 5 is one sentence with two readings, and the corpus takes both.** `ADR-007` § 2's fifth
bound forbids a command to overwrite or delete existing trip content, because a trip's working
tree is git-ignored and nothing could restore a clobber. Where a derived artifact genuinely must
be replaced, it admits two shapes: preserve the version being replaced first, or *say before
writing what will not survive*.

- **Read per class**, the step is owed whenever a dispatched agent replaces any
  `rebuilt-each-synthesis` file. `/trip`'s § *check* reads it that way: a `check` that wrote
  `outputs/validation-report.md` *"would owe the preserve-or-announce step bound 5 requires"*.
- **Discharged per artifact**, the corpus performs the step in three places and no others:
  `/trip plan` preserves the replaced `outputs/final-itinerary.md` as its numbered predecessor;
  `ADR-028` § 2 gives the presence file a rebuild announce; and `ADR-037` declines the announce
  for the group snapshot and routes the question here.
- **Declared safe per class**, `reference/data-architecture.md` § 6 says a
  `rebuilt-each-synthesis` class is *"Safe to regenerate because it holds no independent
  state"* — and in the same section records the one entry class for which that is false.

**The class-wide reading announces nothing real, and the per-class exemption is false in one
place.** Measured at `fe637d8` over § 6's `rebuilt-each-synthesis` members — C4, C10, C11, C12,
C14, C17 and C21 — and the two classes decided and not yet built that take the same lifecycle,
the presence file (`ADR-028` § 2) and the group snapshot (`ADR-037`), every unit a rebuild writes
is written again from inputs still on disk, with one exception:

| Class | Unit the writer emits | Written again by the rebuild from |
|---|---|---|
| C4 destination shortlist | a candidate | the travellers' own files |
| C10, C11 the hub's reference files | a venue row, with its key | the spokes' accumulated outputs; the key is reused from a spoke's resolved entry marker or from the outgoing reference file, which the hub reads before it rebuilds (`agents/05-hub-planner.md`, *reuse the keys already there*) |
| C12 the traveller model | a `first-party` entry | its traveller file, composed with any record it references |
| C12 | a `both-marks` entry (`[OPERATOR-PROVIDED]` and `[THIRD-PARTY]`) | the outgoing model itself: the reconciler reads it and carries the entry forward verbatim |
| C12 | **an `operator-provided-only` entry (`[OPERATOR-PROVIDED]` alone)** | **none.** The rebuild drops it (`agents/00-enrichment.md`, the fallback branch), and the operator's statement survives nowhere else (§ 6's note on C12) |
| C14, C17, C21 | a metric, a finding, a cost line | the itinerary, the traveller model and the spoke outputs they are computed from |
| the presence file | a traveller's entry | the roster and the files the pass reads (`ADR-028` § 2, *Lifecycle*) |
| the group snapshot | a member's entry | that member's own traveller file (`ADR-037`, *The population*) |

Content written into a rebuilt file by anything other than its declared writer is not a unit of
that file: a writer not named for a block does not write it (`CLAUDE.md` § *Write ownership*),
and the corpus already tells the operator that a hand edit to such a file is a change with a
deletion already scheduled.

**Erasure removes trip content and no record admits it against the bound.** Bound 5 is stated
as *"not negotiable by a later slice"*. `/trip-record`'s erasure rule states every substitution
and deletion it makes as an exception to its own rule 2, which restates the bound, and admits
them *"by this rule"*. `ADR-012` decides erasure's reach and its substitute-never-regenerate
mechanism and never names bound 5. So the exception is in force in the verb and recorded in no
decision.

## Decision drivers

- **DD1. The harm bound 5 names is a loss nothing can restore.** A step that fires where nothing
  is lost spends the operator's attention on the wrong event.
- **DD2. One reading across every class and every verb**, decided by a test rather than by a list
  of classes, so a class or unit kind added later is decided with no edit here (`CLAUDE.md`
  § *Rules over an enumeration*).
- **DD3. Showing a group what changed already has a home**: `outputs/change-summary.md`, which the
  hub writes on every re-bake.
- **DD4. An exception to a non-negotiable bound is a decision**, and belongs in a record.
- **DD5. The record decides and does not build.**

## Options considered

**Selected: the card's second option, read per unit rather than per class** (Decision 1).

- **Option 1 — every class a dispatching verb replaces announces what will not survive, changed
  lines and removed entries, at every verb that dispatches the rebuild.** Rejected. For content
  that re-derives it announces the loss of nothing; it fires on every `plan` run, whose pipeline
  rebuilds several such classes; and it repeats at file grain what the change summary already
  shows the group.
- **Option 2 read per class — the classes whose regeneration is safe are declared outside the
  bound, with the ground stated once.** Rejected. Its ground is false for the traveller model:
  § 6's own note records that a rebuild drops the `operator-provided-only` entry, which nothing
  else holds.
- **Erasure, option E1 — a bare amendment of `ADR-007`.** Not available. An amendment may record
  a supersession taken elsewhere and may never take a decision itself (`reference/adr/README.md`
  § *Convention*), and no record supersedes the bound for erasure: `ADR-012` does not name it.
- **Erasure, option E2 — leave the verb's rule admitting the exception on its own authority.**
  Rejected. It keeps a bound the corpus calls non-negotiable negotiated by a slice, with no record
  to say why.

## Decision

**1. Bound 5 protects content that no surviving input can rebuild, and the test is per unit.** A
unit is the smallest piece a writer emits whole — an entry, a row, a line. A rebuild that writes a
unit again from inputs still on disk owes nothing for it. A unit with no surviving source is
preserved, or named before the write; a unit the rebuild removes is named exactly as a changed one
is. Naming says what the unit holds, whose it is, and how to keep it. A class whose every unit
re-derives owes nothing as a class, whatever its lifecycle token.

**2. Today the test admits one unit: the `operator-provided-only` entry in
`outputs/traveler-model.md`.** Every other unit in the population measured under § *Context*
re-derives. That list is the measurement at this record's baseline, not the rule: a unit kind or a
class added later is decided by Decision 1.

**3. Showing what changed is the change summary's job, not this bound's.** `ADR-028`'s
presence-file announce stands unamended: it announces every changed line and every removed entry,
which is more than this bound requires of a file whose every entry re-derives. The group snapshot,
whose announce `ADR-037` declined and routed here, owes none under this bound, for the same
reason, and its erasure is Decision 5's.

**4. In a run nobody can answer, naming is a report.** Naming asks nothing, so it is compatible
with the rule `ADR-051` decides: where a verb's section names a unit and writes without asking, the
write runs in that turn and the naming stands in the run's output. Where a verb's section asks
before such a write — whether to keep the unit, say — `ADR-051` governs that stop. This record
decides neither which a given verb does.

**5. Erasure is bound 5's one exception.** An erasure substitutes and deletes trip content because
the person asked for that content to go; preserving it or echoing it would defeat the act
(`ADR-012`). This record supersedes `ADR-007` § 2 bound 5 **in part, as far as it reaches the
erasure operation and no other**; the rest of the bound, and every other part of `ADR-007`, stands.
The supersession takes effect when this record is set `Accepted`, and is recorded in `ADR-007` in
the change that sets it: the `Status:` line, an inline marker at the bound, and a closing
`## Amendment history` entry.

## Consequences

**What becomes false, measured at `fe637d8`.** This record builds none of it.

- **`skills/trip/SKILL.md` § *Standing clause*.** Its bound-5 paragraph closes: *"Regenerating a
  file, rewriting it from scratch, reordering it or deleting a unit of it is none of these shapes
  and takes no licence from them."* A rebuild of re-derivable units is outside the bound, not an
  unlicensed shape.
- **`skills/trip/SKILL.md` § *check*.** *"would owe the preserve-or-announce step bound 5
  requires"*: a validation report re-derives, so a `check` that wrote it would owe nothing.
- **Every verb that dispatches the reconciler's rebuild of `outputs/traveler-model.md`** —
  `/trip plan`, whose § *Dispatches* line sends the reconciler first; `/trip replan`, where a
  changed profile triggered it; `/trip-record travelers` and `/trip-record person`; and
  `/trip-record group` on a removal. None names an `operator-provided-only` entry before the
  rebuild drops it.
- **`agents/00-enrichment.md`.** The reconciler dispatch *"writes `outputs/traveler-model.md` and
  nothing else"*, and the fallback branch states that an `[OPERATOR-PROVIDED]`-only entry is not
  carried forward; neither reports the dropped entry to the verb that must name it.
- **`reference/data-architecture.md` § 6.** The `rebuilt-each-synthesis` row's *"Safe to
  regenerate"* ground, and its note on C12, which records the drop and states no obligation.
- **`skills/trip-record/SKILL.md`'s erasure rule**, which admits its exception to rule 2 *"by this
  rule"*; once this record is `Accepted`, the admission is this record's.
- **`ADR-037`**, whose rebuild-announce paragraph and two table cells name the class-wide question
  `ADR-028` routed: their target is this record.
- **`ADR-028` § 2's ground for the presence file's announce.** It grounds the announce in bound 5's
  *say before writing what will not survive*. The announce stands by `ADR-028`'s own decision, and
  Decision 3 re-grounds it; no decision of either record changes.

**Unchanged:** every decision of `ADR-028`, the presence file's announce included; `ADR-012`;
`CLAUDE.md` § *Archived trips — what the freeze binds*; and `CLAUDE.md` § *Output Versioning*'s
traveller-model bullet, whose *"regeneration is safe"* is stated of entries projected from a source.

**The loss path stays open.** A re-plan can still drop a need the operator relayed without saying
so. Closing it is a build this record does not perform.

**Reversibility.** CHEAP while `Proposed`. Once `Accepted`, the reading is supersede-only, and its
cost is additive: a naming step at the verbs above.

## References

- `reference/adr/README.md` — § *Convention*: the amendment boundary and the partial-supersession
  form Decision 5 uses
- `reference/adr/ADR-007-command-entry-point.md` — § 2, bound 5
- `reference/adr/ADR-012-people-library.md` — erasure's reach and mechanism
- `reference/adr/ADR-028-derived-planning-day-block-owners.md` — § 2, the presence file's announce
  and the routed question
- `reference/adr/ADR-037-group-snapshot.md` — the snapshot's lifecycle and its declined announce
- `reference/adr/ADR-051-a-verb-runs-until-it-asks.md` — what a run nobody can answer writes
- `reference/data-architecture.md` — § 6 and its note on C12
- `CLAUDE.md` — § *Write ownership*, § *Rules over an enumeration*, § *Output Versioning*
- `skills/trip/SKILL.md`, `skills/trip-record/SKILL.md`, `agents/00-enrichment.md`
