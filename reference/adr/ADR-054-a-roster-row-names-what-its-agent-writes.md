# ADR-054: A roster row names what its agent writes — the enrichment row's `Output File` cell names the presence file, as declared until the writer ships and as written after it, superseding ADR-028 Decision 4 in part

- **Status:** Accepted (2026-11-22)
- **Deciders:** repo maintainer
- **Driving work:** #1503, in the *Each traveller's planning-day window has one home* milestone.
  The repository's maintainer ruled, at the collective review of an earlier milestone, that the
  enrichment row's `Output File` cell is widened with a declared wording when the presence class
  lands, and that `ADR-028` Decision 4's partial supersession is recorded when it takes effect. This
  record transcribes that ruling, with the premise measured again at this record's baseline.
- **What this record is.** A decision about **what the enrichment row of `CLAUDE.md`'s agent roster
  names for the presence file**, `outputs/traveler-presence.md`. It is addressed to whoever edits
  that row, the reconciler's write set, or group J of `scripts/test-command-taxonomy.sh`.
- **What this record is not.** It changes no other cell of the roster, no other decision of
  `ADR-028`, and nothing about who writes the presence file, when, or what it holds.

## Context

**`ADR-028` Decision 4 kept one cell unwidened, on one ground.** The decision widens the reconciler's
write set by one rebuilt file, the presence file, and keeps the enrichment row's `Output File` cell
from naming it: *"A path under `outputs/` in that cell enters `/trip research`'s agent-key filter."*
At that record's baseline, `54586fd`, the ground held. The filter admitted a roster row whose
`Output File` cell named exactly one path under `outputs/`, and the enrichment cell named none, so a
single presence-file path would have made the enrichment agent a research spoke.

**The ground is gone, twice over, measured at `fe637d8`.**

- **Since `ead6f6c`** the cell names two paths under `outputs/`: `outputs/traveler-model.md` and
  the setup seed of `outputs/event-status.md`. A filter that admits a row naming exactly one such
  path cannot admit this row, whatever a third path does.
- **Since `f8b4464`** `/trip research` reads no `Output File` cell at all. Its key is derived from
  `reference/data-architecture.md` § 1.1: the classes whose `Prov` cell is `researched` and whose
  `L` cell is `accumulate-append`, joined to the roster through their `W` cell. The verb says so in
  terms: *"a further file named there leaves the spoke in the key."* The presence class is
  `derived` and `rebuilt-each-synthesis`, so it does not enter that key under any wording.

**A required check now holds the cell to the opposite rule.** Group J of
`scripts/test-command-taxonomy.sh`, a required check, expects every file § 1.1's `W` column assigns
to a roster agent to be named, as a code span, in that agent's `Output File` cell. Arm `J1` grades
it, and from the commit that adds the presence class to § 1.1 with writer `enrichment`, `J1` expects
the enrichment row to name `outputs/traveler-presence.md`. The group's header gives the form for a
class that lands before its writer emits it: the row names the file *"declares `outputs/<file>`, not
written before <the landing that ships its writer>"*, because the row is an instruction — `/trip`'s
dispatching verbs send each agent out *"writing exactly the file or files that row names"* — and the
landing that ships the writer rewrites the clause.

## Decision drivers

- **DD1. A decision whose ground is false does not bind the next change.** Decision 4 kept the cell
  narrow to protect `/trip research`'s key, and that key no longer reads the cell.
- **DD2. The roster row is an instruction, not a description.** A path in it sends the agent out to
  write that file, so a file named before its writer contract exists must be named as declared.
- **DD3. One source for what an agent writes.** An exception list beside group J is a second source
  for the same fact.
- **DD4. The maintainer's ruling stands unless its premise fails.** It has not.

## Options considered

**Selected: name the presence file in the cell — declared from the change that adds its class, and
written from the change that ships its writer** (Decision 1).

- **Keep Decision 4, and exempt the presence class from `J1`.** Rejected. Group J's header declines
  an exception list as a second source of truth, and the exemption would not hold: `J1`'s second limb
  reads the enrichment prompt's own frontmatter blocks, so from the change that gives the prompt the
  presence file's block, `J1` expects the file in the row whatever the exemption says.
- **Name the file bare from the change that adds its class.** Rejected. The row is the instruction a
  dispatching verb sends the agent out with, and a bare path would tell the reconciler to write a file
  whose writer contract does not exist yet — the one ordering `ADR-028` § *The couplings* forbids.
- **Hold the build until the cell's question is settled elsewhere.** Rejected. The premise is already
  gone, so holding protects nothing, and the class cannot wait on it: the presence class, its schema
  and its erase reach row land before anything writes the file (`ADR-028` § *The couplings*, the
  Scaffold set), and the class row is what `J1` reads.

## Decision

**1. The enrichment row's `Output File` cell names `outputs/traveler-presence.md`.** From the change
that adds the presence class to § 1.1 until the change that ships the reconciler's first emission of
the file, it names it in the declared form — *"declares `outputs/traveler-presence.md`, not written
before the Cutover"*, the Cutover being `ADR-028`'s name for that landing. From that change on, it
names it as a file the reconciler role rebuilds.

**2. This supersedes `ADR-028` § *Decision* 4 in part**, as far as its clause *"Not widened, on
purpose: the enrichment row's `Output File` cell"* keeps that cell from naming the presence file. The
rest of that decision — the reconciler's write set widening by the one rebuilt file, the `[ENRICH]`-only
contract and the research role widening nowhere, and where the presence file is declared — stands, and
so does every other part of `ADR-028`.

**3. The supersession is recorded in `ADR-028` in the change that widens the cell**, because it takes
effect there: the `Status:` line, an inline marker at the clause, and an entry in its closing
`## Amendment history`.

## Consequences

**What becomes false or is re-grounded, measured at `fe637d8`.**

- **`ADR-028` § *Consequences*, the `CLAUDE.md` paragraph.** It says the table's opening paragraph
  and its `[ENRICH]` row, two Key Rules bullets and § *Output Versioning* *"stay true, because the
  roster's enrichment `Output File` cell … is not widened (Decision 4)"*. That ground is false from
  the change that widens the cell. The surfaces it names stay true without it: none of them reads the
  roster cell, and `/trip research`, the one reader the ground protected, derives its key from § 1.1.
- **`ADR-028` § *Consequences*, the `skills/trip/SKILL.md` paragraph.** It says the record adds a
  second unnamed write *"as a consequence of its own decision not to widen that cell"*. From the change
  that widens the cell, the presence file is not an unnamed write: the row names it as declared while
  nothing writes it, and as written once the reconciler does.
- **The cell's declared clause and the writer's first emission cannot land apart.** The change that
  ships the writer rewrites the clause to name the file as rebuilt, because a row naming a file as
  not written while its agent writes it is the false instruction Decision 1 exists to prevent.
- **Group J's `J1` holds from the change that adds the class**, on either wording, because a code span
  in the cell is a name whatever the sentence around it says.

**Unchanged:** every other cell of the roster; `ADR-028`'s other decisions; and § 1.1, which already
names the presence class's writer.

**Reversibility.** CHEAP while `Proposed`, and the cell's wording is one line. Once `Accepted`, the
reading is supersede-only.

## References

- `reference/adr/README.md` — § *Convention*: the partial-supersession form Decision 3 uses
- `reference/adr/ADR-028-derived-planning-day-block-owners.md` — § *Decision* 4, § *Consequences*
  and § *The couplings*
- `reference/adr/ADR-050-reading-by-shape-as-a-fourth-arm.md`,
  `reference/adr/ADR-052-a-body-ends-where-the-browser-ends-it.md` — the two partial supersessions
  whose form this record follows
- `CLAUDE.md` — § *Dispatching agents*, the agent roster
- `skills/trip/SKILL.md` — § *research*, the agent key; the dispatching verbs' write sentence
- `reference/data-architecture.md` — § 1.1
- `scripts/test-command-taxonomy.sh` — group J, its header and arm `J1`
- Work items this record's decision touches:
  - #1560 — the collective review of the milestone that added group J, where the repository's
    maintainer decided that the enrichment cell is widened with the declared wording when the presence
    class lands, and that `ADR-028` Decision 4's partial supersession is recorded when it takes effect
  - #1503 — this record's card, which carries the cross-milestone notice restating that ruling
  - #1489 — the change that added group J and gave the cell its second path under `outputs/`
