# ADR-056: What a verb reads before it acts — the contract its citation line names, once per invocation; the charter on the step that names it; a dispatch roster counted one hop out

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1178, in the *The first-verb read carries only what every session needs*
  milestone. The repository's maintainer ruled, at that milestone's collective review, that the card
  ships as written — every verb's `Contract:` line names the trip-resolution contract's new home,
  `reference/trip-resolution.md` — that the load-class rule is repaired in the same change, and that
  a record opens it. This record states what that ruling decides, with each premise measured again
  at `9c357e5`.
- **What this record is.** A decision about **what a verb reads before it acts**: the file it reads
  once per invocation, when it opens the charter, how the load-class rule keeps counting the
  dispatch roster once the charter is no longer that file, and how a verb reaches the operator lines
  it prints. It is addressed to whoever edits a verb's citation line or its reads,
  `reference/load-class-model.md` § 4, or group K of `scripts/test-corpus-hygiene.sh`.
- **What this record is not.** It does not decide how a verb installed the way the README documents
  reaches a file it reads (§ *Decision* 6), and it changes no gate of the ladder, no evidence entry
  and no verb's requirement table.

## Context

**The citation line is two things at once.** A verb's contract header opens with a citation line,
held byte-identical across the command files by `scripts/test-trip-resolution-contract.sh`. The
line is the verb's pointer to the gate ladder, and it is also the input to clause 2 of
`reference/load-class-model.md` § 4: a file named on it is `first-read`, the class a named constant
bounds. At `9c357e5` the line names `CLAUDE.md`, so the charter is the one `first-read` file.

**The ladder now has a home of its own, and re-pointing the line moves three things.** Measured with
the classifier `scripts/test-corpus-hygiene.sh` carries, over a tree with the section moved and every
citation re-pointed:

- the contract file becomes the one `first-read` file;
- the charter falls to `on-demand`;
- under clause 4 as it stood — a roster counts only where a file of the first three classes carries
  it — every agent prompt the roster names falls to `on-demand` with the charter, the `dispatched`
  class holds no file, and the required check fails on `K5`.

**The section argued its own placement, and its next sentence withdrew the argument.** It said it
added *"no per-invocation read"* and *"cannot be silently skipped"*, because `CLAUDE.md` is
auto-loaded — then that an installed consumer *"cannot assume this section is in context"*. Both
properties held only where the repository is the workspace.

**The two postures differ in what reaches a verb unread.** Where the repository is the workspace,
the harness loads the charter at the start of every session. Where the engine is installed, nothing
is loaded: a verb opens what it reads at the engine root. On Claude Code 2.1.280, in a fresh session
of an engine installed as the README documents, a verb's read of the charter by its locator did not
run: `Read` resolved the locator lexically, to a folder with no charter, and a shell read resolved it
and was refused (*References*). `ADR-051` recorded the same harness from the other side: in print
mode, no verb read the charter in any run measured.

**One verb holds no `Read`.** `/trip-publish` denies it, and reads the one file it reads, the data-root
pointer, with `grep`. It prints three kinds of
operator line — the first publish, a key remedy, the plaintext opt-out — from
`CLAUDE.md` § *Publishing to GitHub Pages*, where they have one home, and it has them only because
the charter is in context. Once the ladder leaves the charter, the same verb has no declared way to
read the ladder either. `/trip-decommission` prints the deleting takedown line from the same section,
and holds `Read`.

## Decision drivers

- **DD1. A read is declared where it is made.** `reference/load-class-model.md` § 6: a read no file
  states is not an edge, and the remedy is to state it.
- **DD2. One home for each rule.** The ladder and the operator lines are stated once and cited.
- **DD3. The model must not overstate or understate a read.** The constant bounds the read every
  verb makes; a class does not empty because the file carrying its roster moved down a class.
- **DD4. Minimum privilege.** `ADR-007` § 2: a command's `allowed-tools` is the minimum for its
  function.
- **DD5. What is read is decided apart from how an installed verb reaches it.** Reach is measured
  not to work today, and nothing decided here waits on it.

## Options considered

**The read a verb makes once per invocation.**

- **Selected: the contract file alone, and the charter on the step that names it** (Decision 1).
- **Both files on the citation line.** Rejected: both become `first-read`, `K7` holds each such row
  equal to one constant, and one constant cannot bound the contract file and a charter much larger
  than it without bounding nothing. The verb would read both, so nothing is saved.
- **The citation line keeps naming the charter, which keeps a pointer under the old heading.**
  Rejected by the maintainer's ruling, and on its own costs: every verb makes two reads, the line
  names a pointer, and the constant bounds the charter rather than the ladder every verb reads.

**Keeping the dispatch roster counted.**

- **Selected: one hop, by the rule's own term *names*** (Decision 2).
- **One hop by *cites* only.** Rejected. It classes the tree as the selected rule does, but *names*
  is the term clause 5 already uses for what an instruction reaches, and a verb naming the directory
  that holds a roster reaches it as surely as one naming the file: a fixture doing that reads
  `dispatched` under the selected rule and not under this one.
- **A roster counts wherever it stands.** Rejected. It also classes the tree as the selected rule
  does, but a roster in a document nothing that dispatches reaches — a worked example, a table in a
  record — would make its prompts `dispatched`. A fixture whose roster is cited only from `README.md`,
  and one whose roster is two hops out, each fail `K5` under the selected rule and not under this one.
- **Stop failing an empty class.** Rejected: `K5` is the finding that exposed the move's
  consequence, and a class whose instrument binds and which holds nothing is what it exists to report.
- **Move the roster into the contract file, or into each verb that dispatches.** Rejected: the roster
  is dispatch knowledge, not resolution, and a copy per verb is a second statement of it.

**How the operator lines reach the verbs that print them.**

- **Selected: a declared read on the branch that prints the line, the lines staying where they are**
  (Decision 4).
- **Move the lines into the contract file.** Rejected: every verb would pay their bytes on every
  read, for lines two verbs print on a refusal.
- **Restate the lines in the verb's own file, or in a file bundled beside it.** Rejected: group F of
  `scripts/test-command-taxonomy.sh` fails a first-publish, rotation, plaintext or deleting line in
  any file under `skills/`, and the verb's own text names that paragraph as the line's one home.

**How `/trip-publish` reads the contract file** — the one choice here the maintainer ruled on
separately, at the design review, on the measurement below.

- **Selected: a `Read` grant naming the contract path, with the blanket `Read` denial dropped**
  (Decision 5).
- **Read it through the `grep` grant the verb already holds**, as it already reads the data-root
  pointer. Rejected, on a measured truncation: a whole-file `grep -h ''` of the contract file, about
  38 KB, came back as a preview of about 2 KB, the rest saved to a file the verb, holding no `Read`,
  could not open. Reading the file in pieces by its anchors instead would tie the verb to the
  contract's layout, and miss each paragraph no anchor marks.
- **Keep the denial, and read nothing.** Rejected: in the workspace posture the verb would lose the
  ladder it has today.

## Decision

**1. A verb reads the contract file its citation line names, `reference/trip-resolution.md`, once
per invocation, before it acts, in both postures.** `CLAUDE.md` § *Step 2* assigns that read to every
verb's scope. The charter is not a verb's per-invocation read: a verb opens it on a step that names
one of its sections — in context when the repository is the workspace, otherwise at the engine root —
and the guided-entry surface reads § *Step 1* live when it routes a request.

- **Workspace.** The harness loads the charter, and every verb also reads the contract file: one
  read the workspace form did not make before.
- **Installed.** The contract file is the one read every verb makes on every invocation. A verb whose
  step names a charter section opens the charter there; `/trip` names § *Step 1*'s `Command` column
  on every invocation, so it makes two reads per invocation in this posture.
- **"Cannot be silently skipped" holds in neither posture.** What stands in its place is a declared,
  ordered read: the citation line, and each verb's instruction to resolve the data root before it
  reads anything.

**2. Clause 4 of `reference/load-class-model.md` § 4 counts a dispatch roster that a file of the first
three classes carries, or that a file one of them names carries** — one hop, and never a chain.

**3. `CH_FIRST_READ_CEILING` binds the contract file**, and that file's row in
`reference/size-fence.md` equals the constant. The charter's row is an ordinary `on-demand` ceiling.

**4. A verb that prints an operator line from `CLAUDE.md` § *Publishing to GitHub Pages* reads that
line there, on the branch that prints it** — in context when the repository is the workspace,
otherwise from the engine root — and the lines stay in that section. `/trip-decommission` reads it
with `Read`. `/trip-publish` takes the one line with its `grep` grant, and its `update` verb's
`**Reads:**` line names that read.

**5. `/trip-publish` reads the contract file with a `Read` grant that names that path, and no longer
denies `Read`** — the maintainer's ruling between this and the `grep` read under *Options
considered*. That it reads no trip file in full stays its own stated rule, as it always was; it is
no longer backed by a denial. The data-root pointer it still reads with `grep`, as the contract
directs a verb without a `Read` grant for that path.

**6. Declined: how an installed verb reaches a file it reads.** Whether the engine root is admitted
to the allowed directories, or a verb names its files by a locator that resolves through the link,
is a question already recorded on its own work item (*References*). Nothing decided above depends on
its answer.

**7. `ADR-007` § 2's first bound is neither amended nor superseded.** It bounds a scoped invocation to
the context its Step-2 row assigns, and § *Step 2* now assigns the contract read, so it holds as
written. `ADR-021`'s consequence paragraph after the Q-5 bullet, which read that bound as *"no
per-invocation read"* binding the workspace form, is corrected by amendment.

## Consequences

**Class changes, measured with the suite's classifier at `9c357e5` and on a tree with the move
applied.**

- Before the move, the hop changes no file's class, and at the commit that declared the classes it
  reproduces the recorded classification.
- With the move, the only files that change class are `CLAUDE.md`, from `first-read` to `on-demand`,
  and `reference/trip-resolution.md`, new, as `first-read`. `dispatched` keeps every prompt it held.

**What becomes false, and is corrected where it stands.**

- The contract's own opening paragraph, which argued its placement from auto-load.
- `reference/load-class-model.md` § 2, which said the charter is read once per invocation by a verb,
  and § 3's `first-read` row, which named the guided-entry surface's read as that class's.
- `reference/size-fence.md` and the constant's comment, which named the charter as the `first-read`
  file.
- Every sentence in a verb file calling a charter read *"the one read the installed form adds"*.
- `/trip-publish`'s statement that `Read` is denied, its `update` verb's *"no path of its own"*, and
  the contract's own sentence that `/trip-publish` denies `Read` (Decision 5).
- `ADR-021`'s consequence paragraph (Decision 7).

**The constant bounds the read every verb makes, not everything a verb reads.** `/trip` opens the
charter on every invocation in the installed posture, and that read is bounded by the charter's own
row, not by the constant.

**Where the bytes go.** In the workspace posture no verb reads less: it pays the contract read beside
the auto-loaded charter, and the saving is in every session that resolves no trip, which no longer
carries the ladder. In the installed posture the read every verb makes falls from the charter to the
contract file, and a verb that opens the charter pays that read as well.

**A grant on the publish surface changes shape.** `/trip-publish` trades a turn-scoped removal of
`Read` for a pre-approval of one path. A read of any other path is routed through the permission
settings rather than removed, so in a permissive mode the bound on what it reads rests on its text.

**What this record does not establish.** No suite observes a session walking the ladder, and in the
installed posture the read decided here is declared and not observed: the measurement above found
the charter read not running, and nothing indicates the contract read fares differently.

**The couplings.** The citation line's re-point, clause 4's hop with its classifier, and the
constant with the contract file's row cannot land apart: between them the required check fails on
`K5` or `K7`. The hop can land first, alone, because it changes no class before the move.

**Reversibility.** MODERATE. The text and the classifier revert together; the cost is that every
citation re-pointed to the contract file is re-pointed back.

## References

- `reference/load-class-model.md` — § 2, § 3's `first-read` row, § 4 clause 4 and its limits
  paragraph, § 6
- `reference/size-fence.md` — *The first-verb read is held twice*
- `scripts/test-corpus-hygiene.sh` — group K, `CH_FIRST_READ_CEILING`, the classifier and its
  control arms
- `reference/trip-resolution.md` — § *Resolving a trip*
- `CLAUDE.md` — § *Step 2*, § *Publishing to GitHub Pages*, § *Dispatching agents*
- `skills/trip-publish/SKILL.md`, `skills/trip-decommission/SKILL.md` — the operator hand-offs and
  their reads
- `scripts/test-command-taxonomy.sh` — group F
- `reference/adr/ADR-007-command-entry-point.md` — § 2
- `reference/adr/ADR-021-installable-capability.md` — § *Decision* 1, and the consequence paragraph
  after the Q-5 bullet
- `reference/adr/ADR-051-a-verb-runs-until-it-asks.md` — *Options considered*, option C's measurement
- Work items this record's decision touches:
  - #1178 — the card whose citation-line re-point this record governs
  - #1657 — the measurement that an installed verb's charter read does not run in a fresh session,
    and the open question of how an installed verb reaches the files it reads
  - #2432 — the collective review where the repository's maintainer ruled that the card ships as
    written and that the load-class rule is repaired in the same change
  - #2437 — the design review where the maintainer ruled how `/trip-publish` reads the contract
    file (Decision 5), on the truncation measured there
