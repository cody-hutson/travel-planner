---
description: Record what you know about a trip — traveler profiles, third-party needs, and the enrichment reconcile; the destination and the mode, the party, trip facts, constraints and bookings, and the per-trip publish repo name; per-event status and the session log. Writes the trip's own files; never publishes.
argument-hint: <verb> [--trip <slug>] [args...]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(date:*), Read, Write, Edit, Task
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), NotebookEdit]
---

# /trip-record

`/trip-record <verb> [--trip <slug>] [verb args...]`

The verb is the one the user typed. Nothing in this file supplies a verb they did not type, and
nothing in it reads the wording of the request to decide one.

**The frontmatter above, and what it is held for.** Each grant is held for a use a section below
names, per `ADR-007` §2 bound 2. **Two of them are the file's own**, and their set is closed by the
header block: `Bash(ls:*)` for the listing block and `Bash(grep:*)` for the record block, and
nothing else in this file uses either. **Every other grant is a verb's, and the verb section that
takes it is where its use is named** — `Read` and `Edit` by each section that probes for a file or
changes named lines in one, `Write` by each section that creates a file the trip does not have,
`Task` by each section that dispatches an agent under standing rule 6, and `Bash(date:*)` by the
section that needs a date. **Which sections those are is read from the sections, not from here.**

**Why this line names the grants and not their uses.** What a grant is held for is a property of the
verb, not of the file, and this file is written by more than one slice: a closed list of uses,
written before a later slice's verbs exist, is stale the moment one lands and is widened by every
author who meets it — the same reason § *What the blocks above are* states the read-scope ceiling as
a principle rather than a path list. The two pair, and together they make this file's grant set and
its read scope both the union of its verb sections, with no second list that can disagree with them.
It also moves the trigger for editing this line from *a new verb*, which is unbounded and is what
went stale, to *a new grant*, which is already an edit to the extension point below. **A grant no
section names is a grant with no function**, and taking one is a defect whatever this line says. No
directory-creating grant is taken, and no verb of this command creates a directory.

**Frozen.** `disable-model-invocation: true`; `argument-hint`, which is already verb-general; and
every entry of `disallowed-tools`, which denies the publish script directly and through `bash` and
`sh`.

**What `disallowed-tools` does at runtime is contested, and this file does not settle it.** Two
accounts ship in this repo and they are not compatible.
`reference/adr/ADR-007-command-entry-point.md` § *Context* says the field *removes the named tools
from the pool* — a real restriction, turn-scoped in the same way as the grant. The trip-resolution
contract workflow's own scope note says the opposite where it matters: `allowed-tools` and
`disallowed-tools` alike are a turn-scoped pre-approval grant, **every tool stays callable**, and a
green check there is not a privilege guarantee and must not be read as one. **Nothing in this repo
arbitrates**, and the reason is narrower than *nothing reads the field*.
`scripts/test-command-taxonomy.sh` does read it: its invocation classifier walks the command
directory and matches this file's `disallowed-tools:` line on the publish-script grant token that
line carries, counting it into a **tool-grant tally** — one term of a parse-coverage identity that
guard asserts and fails on. That reading is of what this file **declares**; the guard says in terms
that it takes neither account, because every assertion it makes is about a declaration and none
about what a declaration enforces. **A declaration-level reading is what leaves the runtime question
unarbitrated** — not the absence of a reader. Where else the field appears is **re-derived from the
tree rather than listed here**: the list this sentence used to carry named the five command files,
one workflow comment and the ADR, and was two short — it missed a second workflow comment and the
guard itself, which is what a written-down census does.

**What the two accounts agree on is all this file relies on.** The declaration is turn-scoped and
clears at the next message; a tool left off `allowed-tools` is not thereby forbidden — it routes
through the usual permission settings instead, so **omission is not prohibition** under either
account; and durable blocking would need a permission-settings deny rule, a different artifact and
one this release does not ship. So every *never* in this file names a **rule this file follows,
never a property its frontmatter guarantees**: standing rule 1 is what makes this command never
publish, and these entries stand beside it as a **declared** restriction whose runtime force this
repo does not establish — corroboration, not the thing that makes the claim true. That is what
freezes them, and it is what keeps the clause below sound under **either** account. **The contest is
stated once, here.** A verb section names the control it actually rests on, and does not restate it.

**Extension point — union only.** `allowed-tools` may gain a tool only where the verb that needs
it is named in the adding slice's own design, and the addition is a union: no entry is removed and
no entry is narrowed. `description` may be widened to name a later slice's verb class; it may not
be narrowed.

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`

## Trip records

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*|^\*\*Lifecycle:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md 2>&1`

## Contract header

```trip-contract-header
Contract: CLAUDE.md § Resolving a trip
contract-depth: G8
population-role: RESOLVE
```

| verb | lifecycle | mode | destination | depth |
|---|---|---|---|---|
| profile | ACTIVE | any | any | G8 |
| person | ACTIVE | any | any | G8 |
| travelers | ACTIVE | any | any | G8 |
| destination | ACTIVE | any | any | G8 |
| mode | ACTIVE | any | any | G8 |
| group | ACTIVE | any | any | G8 |
| fact | ACTIVE | any | any | G8 |
| .publish-slug | ACTIVE | any | any | G8 |
| event | ACTIVE | any | any | G8 |
| log | ACTIVE | any | any | G8 |
| link | ACTIVE | any | any | G8 |
| unlink | ACTIVE | any | any | G8 |
| promote | ACTIVE | any | any | G8 |
| erase | ANY | any | any | G8 |

The block above is this file's contract declaration, and the requirement table sits **below** it,
outside the fence, so it renders as a markdown table. The fence the contract publishes names that
table among the block's fields on a line that is **entirely a placeholder** — it describes the field
rather than rendering it — so the canonical fixes this block's field set and does not settle where
the table is drawn. The table's own bytes do not move with it: five columns, their order, and their
header row, unchanged. `scripts/test-trip-resolution-contract.sh` does not grade the placement, and
that was read out of its source rather than assumed — it opens a fence by info string at one pin and
that pin reads `CLAUDE.md`, while every assertion it makes about this file reads whole lines of it
with no fence state at all. **A checker locating this file's declared verb set by opening this fence
would see the difference**; the table's own header row is the anchor that survives the rendering.

**Frozen.** The citation line, byte-for-byte. `contract-depth: G8` as a **bare** token on its own
line — a code-span rendering of that line is graded as an *absent* declaration, so the tolerance
for a code span belongs to a depth **cell** and never to this line. `population-role: RESOLVE`. The
fence tag. The table's five columns, their order, and their header row.

**Extension point.** One table row per verb a later slice implements, appended below the rows
already there.

### How this file is extended

This file is written by more than one slice. What follows is the whole of what a later slice may
change and the shape each change takes; everything else above the first verb section is closed.

**The zone rule, and it is the one that matters most.**

> **Zone B begins at the first `##` heading whose first whitespace-delimited token, with backticks
> stripped, equals a value in the requirement table's `verb` column. Zone A is everything above
> that heading. Zone B runs to end-of-file.**

**Nothing may be appended below the last verb section.** Shared text added at the bottom of this
file lands silently inside the last author's verb section and rebinds it. Zone B is append-only:
one section per table row, one row per section, the section heading's first token is that row's
`verb` cell, and a new section goes below every section already there.

**The repair extension point — a Zone A statement that a permitted edit has falsified.** Zone A is
closed, and its own extension points nevertheless make it **falsifiable**. The falsifying edits are
not enumerated here, because a second list of them can disagree with the first: the Zone A ones are
exactly those § *What a later slice adds* excepts in its *must not change* cell, read from there;
and a **Zone B** edit falsifies Zone A too, which is why the falsifying set is wider than the set
of permitted Zone A changes — a verb section naming a use of an existing grant is the shape that
already did it. Each can make a sentence above the first verb section untrue. A zone that forbids
every edit while licensing the edits that falsify it forbids the repair of a defect it caused, and
that state was reached — an
`allowed-tools` union left the grant sentence above naming every grant but the one it had just
added, and the repair had to breach the zone to land. So the repair is a **stated extension point**,
and it takes exactly this shape:

1. **Only the clause a permitted edit made false may change**, and only that clause. A sentence that
   is merely now awkward, or that the editing author would have written differently, was not
   falsified and is not touched.
2. **The repair lands in the same act as the edit that falsified it**, and the slice's own design
   names it as a Zone A repair and cites the falsifying edit. A false statement left standing for a
   later author to find is the failure this point exists to remove.
3. **The terminal disposition is conversion, not a second repair.** A statement falsified twice is
   evidence that it enumerates a set the extension points grow: it is rewritten as **the rule that
   derives the set, never the members**, and the members come out. A statement a permitted edit
   *will* falsify may be converted pre-emptively by the slice holding this repair, which is the same
   act performed before the falsification rather than after it. A third repair of one sentence is
   not available — by then the enumeration is the defect.

   **What that bar counts, because it has already been read the wrong way.** It counts repairs of an
   **enumeration**, and a conversion that left members standing has not removed one: finishing it is
   that same conversion reaching the part it missed, not a second one, and it is available. A
   statement carrying no members is a rule, so an edit that later falsifies **it** enters at clause 1
   as a rule's first repair. Without this reading, a statement this point's own repair authored could
   be falsified by the next permitted edit with no sanctioned move left, and the point would forbid
   the repair of a defect it caused — the state the paragraph above says it exists to end.
4. **Nothing else in Zone A moves** — not the header block's declaration lines, not the evidence
   blocks, not the zone rule, and not this extension point, **with the one exception the point
   cannot do without: a defect in the point itself.** Its own prose is Zone A prose, so its own
   sentences are falsifiable by the same permitted edits, and a point that forbade its own repair
   would be the state the paragraph above describes reproduced one level up — licensing the edits
   that falsify it and then refusing the repair. So a repair *of* this point is admitted on exactly
   the terms it imposes on everything else: only the falsified clause moves, in the same act, cited
   in the slice's own design, converted rather than repaired twice. Nothing here admits a repair
   that widens what may be changed elsewhere in Zone A.

**The shape of a table row.**

| Cell | Rule |
|---|---|
| `verb` | the **bare token**, exactly as a user types it, single whitespace-delimited, ASCII-case-foldable — the token alone, never the token followed by an argument placeholder. § *Selecting the verb* matches the typed token against this column by exact string equality, so a placeholder in the cell makes the verb unmatchable |
| `lifecycle` | the value admitting exactly the trip lifecycles the verb's **own section** states a reason to serve. `ANY` or `ARCHIVED` only where that section states the reason; where it states none the cell takes the contract's declared default, and **every verb of this command writes**, so no verb of it has that reason. The rule is written rather than its output because the output is what goes stale |
| `mode` | `any` unless the verb's own section states a mode it does not serve, in which case the cell names the modes it does. A verb that must not run without a decided mode says so **in its own row**, naming what it serves, rather than by a halt at the gate that yielded the state |
| `destination` | the `mode` rule again, with one bound that is not derived and does not move: **no row of this file may gate on a decided destination.** A freshly scaffolded trip has no decided destination whatever its mode, so a destination-gated verb would refuse on a trip the taxonomy says runs the full pipeline |
| `depth` | **the value the header block's `contract-depth` line declares, read from that line.** The header fixes it, the guard grades the equality in both directions, and a value restated here would be a second declaration that can disagree with the first. Rendered **bare**, and left that way by the revision that moved this table outside the fence: a depth cell tolerates either rendering, and the guard strips a code span from the cell before it matches, so the value it reads is the same under both. **The value is never written into this table's own rule text** — hazard 3 below counts any five-column row whose fifth field normalises to a depth as a verb row, and hazard 3 forbids every other table the token outright, so this is the only table in this file that would otherwise carry it at all |

**Three hazards, and each is a silent failure rather than a loud one.** They come from how the
conformance guard reads this file, not from taste.

1. **The evidence-block counter counts every line in the whole file that begins with the
   pre-execution marker `` !` ``, and grades that count as an equality against the declared depth
   — in both directions.** No slice adds a pre-execution block, and **no slice writes a line
   beginning with that marker anywhere in this file**, including inside a fenced example. A surplus
   block is a tool grant with no function and an unconditional red check on push.
2. **The depth cell is read at field index 5 of a pipe-split row.** A sixth column moves it, the
   guard then finds no row carrying a depth and reports the requirement table **absent**, and with
   no rows found `contract-depth` goes unchecked in both directions. **The table stays exactly five
   columns.**
3. **Any pipe row anywhere in this file whose fifth field normalises to `G0`–`G8` is counted as a
   verb row.** No other five-column table in this file may carry a bare or backticked `G0`–`G8` in
   its fifth cell.

**What a later slice adds, and what it leaves alone.**

| A later slice must add | A later slice must not change |
|---|---|
| one requirement-table row per verb it implements, **every cell taking the value § *The shape of a table row* derives for it** — the cells are not restated here, because a second statement of them is a second source that can disagree with the first; a `**Reads:**` line at the head of each `## <verb>` section it appends, per § *What the blocks above are*; one `## <verb>` section per row, appended in Zone B below every section already there; `allowed-tools` additions only where a verb needs one and its own design names that verb; and, for a verb that changes a persist-mutable file, that file's own no-overwrite shape — read the file, change the named row, never regenerate it — stated inside that verb's own section | anything in Zone A except those table rows, that `allowed-tools` union, and a repair made under § *The repair extension point*; the header block's declaration lines; the evidence blocks; the table's five columns; § *What the blocks above are*; the refusal branches, except a repair or conversion made under that same point; and the standing clause, except under the Extension rule stated there |

**Binding on every later slice, without exception:** no line beginning with the pre-execution
marker anywhere in the file; no sixth column; no other five-column table with a `G0`–`G8` fifth
cell; no change to `contract-depth`; and no text below the last verb section.

## What the blocks above are

The ladder the header cites is stated in one place and is not restated here. The blocks above have
already run, and **their output is the whole of the trip state this file resolves against** — the
population from the listing block, and the lifecycle, the mode and the destination by value from
the record block. No verb re-runs either block, and no verb re-derives what they already carry.

Each block is a tool grant this file has to hold, and each is held for a use the requirement table
names: the listing block for `Bash(ls:*)`, and the record block for `Bash(grep:*)`, which reads the
lifecycle, the mode and the destination by value. Neither grant is speculative and neither is
unused. **The header block above fixes how many pre-execution blocks this file carries, and it
already carries all of them** — no slice adds another.

**The read-scope ceiling is a principle, not a path list: every verb reads exactly what its own
section names, and nothing else.** Silence is a prohibition here rather than a gap — a read this
file performs that no section names is out of scope, whether or not a list would have permitted it.

**Why a principle and not a list.** Read scope is a property of the verb, not of the file. The
verbs below read a traveler profile, an intake template, and the roster an agent reconciles
against; a later slice's verbs read the very artifact they are about to change, because a
persist-mutable file is read before its named row is written. A list frozen before those verbs were
written would either forbid them or be widened by every author who met it — and a ceiling that
every author widens is not a ceiling. Placing the obligation on the verb puts the declaration in
the hands of the author writing the read, and makes this file's whole read scope the union of its
sections rather than a second list that can disagree with them. **How a sibling command renders its
own ceiling is that command's to state, read from its file and never restated here** — a
restatement is a second source, and it goes false when that file changes with nothing here changing
to show it. This file's read scope is the union of what its verb sections name, and that union
grows as later slices land, so a list frozen at one revision would be wrong inside a single merge.

**How every verb section declares it.** Each `## <verb>` section opens with a `**Reads:**` line, as
its first line, before any procedure, in this rendering:

    **Reads:** `<path>` — <what it is read for>; `<path>` — <what it is read for>.

and, for a verb that reads nothing of its own:

    **Reads:** nothing beyond the blocks above.

What that line has to carry:

- **Every path the verb reads, named individually** — not "the trip's files", not "the relevant
  artifacts". The line **is** the section's read scope, so anything absent from it is out of scope.
- **A path read only to test whether it exists is a read, and is declared.** The probe that selects
  between `Write` and `Edit` is the control the no-overwrite rule turns on, and an undeclared probe
  hides the one read that rule depends on.
- **A template read in order to copy from it is a read.**
- **A file read before it is written is a read, and the purpose clause says why the read precedes
  the write** — which is what makes a no-regenerate rule checkable at all.
- **A directory or glob read states the directory and the selector** — `trips/<slug>/travelers/*.md`,
  never "the traveler files".
- **A read performed by an agent the verb dispatches is declared by the dispatching verb,
  attributed to the agent, on the same line.** Standing rule 6 below already requires the agent, its
  role and the single file that role writes; this puts the agent's read set in that same sentence.
  It goes in the verb's own section, so no rule is added to the standing clause and this zone is not
  reopened.
- **A read a reader would expect and the verb does not perform is stated as a negative, with its
  reason.** A negative without a reason invites the next author to add the read.

**Two boundaries the principle does not move.**

- **Naming a read never widens the contract declaration.** The evidence prefix is closed and
  machine-graded: the header's `contract-depth` fixes it, and a pre-execution block this file does
  not already carry is a conformance failure whatever a verb section says. The ceiling governs the
  reads a verb performs **in its own body, after the ladder has run**; the blocks above are fixed
  and are not a verb's to extend. A read a verb needs is taken as a tool call in its own body, the
  way `/trip-new` takes the date.
- **Naming a read never licenses a write.** Standing rules 2 and 5 bind unchanged — `Write` only
  where the target does not exist, `Edit` only where it does and only the named field's lines
  change, and only under `trips/<slug>/`. A verb that declares a read of a file it does not own has
  declared a read and nothing else.

**Frozen.** This section is not a later slice's to edit. A verb's read scope is declared in that
verb's own section.

## Standing clause — binding every verb of this command, present and future

This clause sits outside every verb section on purpose: a rule written inside one verb protects
only the verbs that existed when it was written.

1. **Never publishes.** This command never invokes `scripts/publish-trip-site.sh` — not directly,
   not through `bash` or `sh`, not through any wrapper, alias or generated command line. It never
   sets `ALLOW_PLAINTEXT`. It never passes `--yes` to `unpublish`. Where publishing is what the user
   wants, name `/trip-publish` and stop; do not reach the script from here.
2. **Never overwrites and never deletes existing trip content.** `ADR-007` §2 bound 5, and `trips/`
   is git-ignored, so a clobber is recoverable from nothing. `Write` is used on exactly one
   condition — the target path does not exist. `Edit` is used on exactly one condition — the target
   path exists and only the named field's lines change. The probe that selects between them runs
   before either tool is reached.
3. **Never invents a value.** An unanswered field is a skipped field and keeps its bracketed
   placeholder. A field the user says does not apply takes a single em dash. Those are two different
   states and this file never collapses them. A missing profile means *unknown*, never
   *no constraints*.
4. **Never treats a placeholder as evidence, and never predicates a branch on a field's absence
   where a placeholder makes that field present.** `ADR-007` §2 bound 6, both halves.
5. **Writes only under `trips/<slug>/`**, where `<slug>` is `trip.slug` exactly as `E1` spelled it.
   No path is ever built from the `--trip` value.
6. **Dispatches an agent only where a verb's own section names the agent, its role, and the single
   file that role writes.**
7. **An append into a file that exists is taken with `Edit`, and it is rule 2's third admitted
   shape rather than a stretch of its second.** Rule 2's two conditions partition the writes that
   *replace* something — `Write` where the target is absent, `Edit` where it exists and only the
   named field's lines change — and an append is neither: no existing line changes, and there is no
   named field, because the lines being written are not there yet. Read literally, that partition
   leaves an append with **no sanctioned tool at all**, which is not a narrow reading of rule 2 but
   a gap in it: an append is the write that most completely satisfies rule 2's own bound, since it
   overwrites nothing and deletes nothing, and `ADR-007` §2 names *append under a new section rather
   than rewriting* as one of the three shapes that satisfy the bound. So the shape is admitted here
   in terms: **the target exists, no existing line changes, and the write adds lines at the end of
   the file or under the block's own repeat unit.** The probe that establishes the target exists
   runs before `Edit` is reached, exactly as it does for rule 2's other two conditions. Regenerating
   the file, rewriting it from scratch, reordering it, merging into a prior unit or deleting one is
   **not** an append and takes no licence from this rule.

   **This is a widening of rule 2 and is stated as one.** It is here rather than inside one verb
   section because it binds every verb, present and future: **more than one verb of this revision
   already writes this shape** — `group` adds a roster row, `fact` appends a repeat unit, `log`
   appends a session entry — and none of them could name a tool under rule 2 as written. A rule
   admitting a tool shape for every verb that writes an append, present and future, is precisely
   what the Extension rule below reserves this clause for; buried in `log` it would protect `log`
   alone and leave every other such verb in the same gap.

8. **Names a command other than itself without asserting that command's availability.** A section
   names the command and stops. Whether that command is available, and which of its verbs are
   implemented, is a property of that command's own file and is observed there — **so no section of
   this file may state it.** A statement of it here is a second source: it goes false the moment
   that file changes, with nothing in this file changing to show it, and a reader who meets it
   cannot tell. This is the read-live discipline § *Selecting the verb* applies to this command's
   own verb set and `mode` applies to the mode vocabulary, applied to a set neither of them reaches.

   **What it bounds, and what it leaves alone.** It bounds a statement of the named command's
   **availability** — that it exists or does not, that it has shipped or has yet to, which of its
   verbs are implemented. It does **not** reach naming the command, saying whether this verb runs
   it, or citing a convention that command ships and attributing it: those are this file's own
   subject, and each is checkable against the cited file rather than going stale behind it.

   **This binds every verb, present and future, which is why it is here.** Naming a sibling command
   is not a class one slice owns: **more than one verb of this revision already names one**, and a
   rule written inside any one of them would leave every other verb free to re-acquire the habit.

9. **A write outside `trips/<slug>/` is bounded by the target's class, derived, and never by a list
   of verbs. This is a widening of rule 5 and is stated as one.** Rule 5 states this command's bound
   for **trip content**, and it holds unchanged for every byte under `trips/<slug>/`. As a universal
   over *all* writes it goes false the moment any verb of this command writes elsewhere, so the
   out-of-trip bound is stated here as the rule that **derives** the permitted target rather than as
   the single location rule 5 named.

   **The permitted target class.** A path outside `trips/<slug>/` is a permitted target only where
   it is **a durable record of one person, selected by an id the operator supplied** — never by a
   display name, never by a search, and never by any match this command computed. That derivation is
   the whole of the class. A later slice widens by **satisfying** it, not by editing this rule, which
   is what keeps the class from becoming an enumeration that every author appends their own verb to.

   **A write to a member of that class is taken on exactly these conditions, all of which must
   hold:** **(a)** the verb's own section names the exact target path; **(b)** the target was
   selected by the id rule above and by nothing else; **(c)** the write changes **one named field**
   and **creates no file, deletes no file, and removes no field**; **(d)** the operator confirmed
   against an **echoed outgoing → incoming pair** for that one field; and **(e)** the value written
   already exists in this trip, so the write **moves** a value and authors none.

   **What (c)'s three negatives are for.** They are what makes this narrow rather than rule-6-shaped:
   rule 6 delegates *whether* to the verb's own section, and this rule delegates only *which path*,
   fixing the operation class here. Record creation, merge and erasure each fail at least one of
   them, so **none takes any licence from this rule.** A later slice implementing one appends its
   own numbered rule under the Extension rule below, deriving its operation class the way this rule
   derives its target class; **until such a rule exists, no other write outside `trips/<slug>/` is
   available to any verb of this command.**

   It is here rather than inside one verb section because it binds every verb, present and future,
   and the prohibition is the half that binds hardest: a bound written inside the one verb that first
   needed it would protect that verb and leave the next slice to write the store with nothing to
   satisfy. Rule 7 is the shipped precedent for a widening landing as an append and saying so.

10. **An erasure is the one write that may delete a record and rewrite a trip, and it is bounded by
    a receipt that is total over a fixed table — never by a list of the locations someone remembered.
    This is a second widening of rule 5, taken under the Extension rule below, and rule 9 is left
    exactly as it stands.** Rule 9 derives a *target class* — one durable record, selected by an
    operator-supplied id — and then fixes an *operation class* narrow enough that erasure fails it on
    three counts at once: erasure deletes a file, it removes a field, and it changes far more than
    one. Rule 9 says so by name and reserves this append for it. **This rule derives erasure's
    operation class the way rule 9 derives its target class**, and takes rule 9's target derivation
    unchanged: the subject is still one durable record, still selected by an id the operator supplied,
    **never by a display name, never by a search, and never by any match this command computed.**

    **The operation class.** A write is a permitted erasure write only where it is **the substitution
    of one person's identifying values with a minted per-trip token, at a location named in the
    verb's own reach table, on a trip that table's own discovery step resolved** — plus the deletion
    of that person's record and of the traveller file the substitution supersedes. **Substitution is
    the whole of the mechanism; nothing here regenerates, recomposes or refreshes anything**, which
    is what lets this rule reach an archived trip when nothing else may.

    **A write under this rule is taken on exactly these conditions, all of which must hold:**
    **(a)** the location is a row of the reach table in `## erase <person-id>` — a location absent
    from that table is not reachable by omission, it is unreachable, and the receipt says so;
    **(b)** every rewritten value is replaced by the minted token or by a declared non-value, and
    **no location is emptied**; **(c)** the free-text pass is scoped to **one trip directory**, is
    word-boundary and case-sensitive, and reaches no path outside it; **(d)** the operator confirmed
    by typing the record's id at a terminal, with no flag and no non-interactive path; and
    **(e)** every location the run touched, and every location it could not, emits exactly one
    receipt row — so a partial run is a run that says it was partial.

    **What (b) and (e) are for, because they are what separate this from rule 9's shape.** Rule 9
    forbids removal outright, which is right for a verb that moves one field and wrong for one whose
    subject is removal; **(b)** replaces that prohibition with the property it was protecting — that
    no location ends up holding *nothing*, because an emptied constraint roster is a plan that grades
    compliant while no longer carrying the need it was built around. And **(e)** replaces rule 9's
    per-field echo, which cannot be offered here: the echo would be the erased value. **Totality over
    a declared table is the only confirmation shape available to an operation forbidden to name what
    it removed.**

    It is here rather than inside the verb section because the prohibition half binds every verb:
    **no other verb of this command may write a location this table names, on the ground that erasure
    already does.** A bound written inside `erase` would leave the next slice free to reach the same
    bytes by another route.

**Extension rule.** A later slice may append a numbered rule **only** where it genuinely binds every
verb of this command, present and future, and must say in its own design that it did so and why. A
rule that binds only that slice's own verbs goes inside those verb sections. Both failure modes are
real — an all-verb rule added here rebinds every other author's verbs, and a rule buried in one verb
section protects only that verb — so the choice is stated rather than left to judgement. Nothing
else in this clause is a later slice's to change.

## Selecting the verb

Frozen. A literal lookup. Every step is lexical and the last has a terminal else-branch, which is
what separates a lookup from a classification.

1. Take `$ARGUMENTS` as a literal string.
2. Remove `--trip` together with the value that follows it, from wherever in the string it appears —
   it is accepted in any position. `--trip` is a contract-level token: it is removed **before** the
   verb is selected, it is passed to **no** verb, and it is **never** a path component. **A `--trip`
   with no value after it is a malformed invocation** — say that `--trip` was given without a slug,
   and stop. That refusal happens before the gate ladder runs, so it sets no `trip.resolution` and
   no `trip.stop_gate`, and it asserts nothing about whether a trip exists, which trip is active, or
   what mode it is in.
3. The verb is the first remaining whitespace-delimited token, ASCII-case-folded. **If no token
   remains, no verb was typed** — go to § *When no verb was typed*.
4. Match that token by **exact string equality** against the `verb` column of the requirement table
   in this file, read live from the block already in context. Not a prefix match, not a nearest
   match, not a fuzzy match, not a substring match. A token matching no cell goes to § *When the
   token is not a verb of this command*.
5. Everything after the verb token is that verb's argument string. Do not interpret it here.

Never infer the verb from the wording of the request, from the trip's mode, from which files exist,
or from anything other than the token step 3 produced.

**The set this command recognises and the set it implements are the same set**, read live from the
same rows of the requirement table above. So this file carries no *"recognised but this revision
does not implement it"* branch — that branch has nothing to select — and a later slice must not add
one. `ADR-007` §3 fixes the direction: to add or change a request type, add or change the command
first. This command owning its own verb set is that stated dependency direction.

**The refusal branches are four, and they are four different renders:** the `--trip`-without-a-value
refusal in step 2 above; § *When no verb was typed*; § *When the token is not a verb of this
command*; and § *When the resolved state does not serve the verb*. Collapsing any two is a defect,
and there is no fifth.

## When no verb was typed

Frozen. `/trip-record` on its own is **not** a default; it is a refusal. Say that no verb was given,
print the verbs of this command read live from this file's own requirement table, and stop. Select
no verb, and do not fall back to one.

`/trip` defaults a bare invocation to `status` because `status` is read-only. **Every verb of this
command writes, and a write command never picks a write for you.**

This refusal happens before the gate ladder runs, so it sets no `trip.resolution` and no
`trip.stop_gate`, and it asserts nothing about whether a trip exists, which trip is active, or what
mode it is in.

## When the token is not a verb of this command

Frozen. Render exactly three things and nothing else:

1. The token, verbatim, as the user typed it.
2. The verbs of this command, read live from this file's own requirement table — not from a list
   written into this file.
3. One sentence stating that that table is the whole of this command's verb set at this revision.

Then stop. Do not guess. **Do not offer a near-match suggestion — no "did you mean"** — a suggestion
is a classification with an extra step and a reflexive accept, on the least-inspected path in this
file. Do not fall back to any other verb of this command, and do not infer a verb from the wording
of the request.

This refusal happens before the gate ladder runs, so it sets no `trip.resolution` and no
`trip.stop_gate`: those are outputs of a ladder that did not run, and giving this refusal a gate id
would widen the contract's field set. Say nothing about whether a trip exists, which trip is active,
or what mode it is in.

## When the resolved state does not serve the verb

Frozen. This is the G7 render. It happens after the ladder has run, so it carries
`trip.stop_gate: G7`.

- **`REDIRECT`** — name the command that does serve the request, and stop.
- **`REFUSE`** — name why the resolved state does not serve the verb, taking the reason from that
  verb's own row of the requirement table, and stop.

**The reason is derived from the resolved verb's own row, and never from a universal over the
table.** Read that row live; the cell whose declared value the resolved record does not satisfy
**is** the reason, and the render names that cell, the value the row declares and the value the
ladder resolved. Nothing here states what every row of the table happens to declare: that is a
closed enumeration of a set the requirement table's own extension point grows, and it is false the
first time a slice appends a row § *The shape of a table row* already admits — a `lifecycle` naming
`ANY` or `ARCHIVED`, or a `mode` or `destination` cell naming values. Where the unsatisfied cell is
`lifecycle`, the render says the trip is archived and names `/trip-decommission`.

## profile <name>

**Reads:** `trips/<slug>/travelers/` — the **directory-presence probe**, taken with `Read` on the directory path itself and read only to establish whether the directory is there, which § *What the blocks above are* names as a read and requires declared; `trips/<slug>/travelers/*.md` — **the entry names alone, no file opened**, the denominator of the collision check below, named separately from the probe above because the read-scope ceiling names a glob by its directory *and* its selector and because a stem is not what a presence probe consumes; `trips/<slug>/travelers/<file>.md` — the file-existence probe that selects create from edit, and the outgoing content on the edit route; `templates/traveler-intake.template.md` — the interview script on route 1 and the copy source on route 2; `reference/data-architecture.md` — § 3.2, read at invocation for the canonical traveler key the collision check normalizes with, cited live rather than copied so that the trip side and the store side hold **one** identity relation between them. Does not read `trip-context.md`, in either direction. **Takes no `Bash(ls:*)` use:** § *The frontmatter above* closes that grant to the listing block by name, and the listing block lists `trips/` — the parent — so it observes that this trip exists and nothing about what is inside it.

The traveler-document verb. It creates a profile that does not exist and edits one that does, and
the branch is selected by a probe rather than by a tool grant.

**Filename.** Reuse the transform `/trip-new` already applies to the roster's `Traveler file` cell,
verbatim, and invent no second rule: lowercase the name, replace every run of characters outside
`A-Za-z0-9._-` with a single `-`, then trim leading and trailing `-`. The output is a single path
segment by construction, because that charset excludes `/` and `\`. The `Person` name is carried
**verbatim**; only the filename is transformed. **An empty result is refused** — say which name
needs a filename, and stop.

**Three checks, in this order, and the order is the whole of the control.**

**1 — The directory-presence probe, and it runs first.** `Read` `trips/<slug>/travelers/`. **Absent
→ stop**, say so, and name `/trip-new <slug>`, whose Resume branch is the declared repair path for a
trip scaffolded before that directory was part of the scaffold. No directory-creating grant is taken
and this verb creates no directory.

**2 — The collision check, and it runs before the file probe because the file probe is what it
defeats.** The predicate is the **canonical traveler key** of `reference/data-architecture.md`
§ 3.2, **read live from that section and never re-authored here** — a second implementation of it
would be a second source of truth for who is who, and the two would drift with nothing arbitrating.
Compute that key over the stems of `trips/<slug>/travelers/*.md` and over the `<name>` this
invocation was given; the check fires where a stem's key equals the name's. Reading **stems** rather
than the files is sound by § 3.2's own filename-correspondence rule, which requires a stem's key to
equal its entry's key, and it is what keeps this check on paths and out of profile content.

**The predicate is not the filename, and that is the whole reason this check exists.** The filename
transform above replaces a run of out-of-charset characters with a single `-`; § 3.2's key
**removes** every non-`[a-z0-9]` character. They are not the same partition. `Alex Smith` and
`AlexSmith` produce **two different filenames and one key** — so a file-existence probe sees two
unrelated paths, takes the create branch on both, and § 3.2's *"uniqueness is asserted over this
key"* is violated with nothing having overwritten anything. A collision check written on the
filename passes on exactly the cases the publish guard's own key already fails on.

**The remedy is two branches, and the absence of a third is load-bearing.**

| The key already present belongs to | What happens |
|---|---|
| **the same traveler** — including a pure casing or punctuation variant of a name already here | continue to the **edit** route on the existing file. Nothing is created, nothing is renamed, and this is not a refusal |
| **a different person who shares the name** | **stop.** State the collision, name the existing file whose stem holds the key, and ask the operator to disambiguate the display name — which changes the key. **This verb never mints a suffix**, and § 3.2 says why: *"a minted suffix is a surrogate key wearing a natural key's clothes, and it would break the correspondence"* |

**There is no third branch, and it is stated because a reader who knows the store's remedy will look
for one.** `reference/schemas/person-record.md` admits *create anyway with the collision
acknowledged* as a third remedy on the durable store, and it can: that store's key is a
**surrogate**, so two records sharing a display name still carry two ids and co-exist safely. Here
the key is **natural** — § 3.2 asserts uniqueness over it and types the same-name case as a hard
stop — so two live travelers under one key is not a state this verb may reach, and the branch that
would reach it is absent rather than merely unmentioned.

**It never resolves the collision itself and it never silently overwrites.** The verb states the
collision and stops for the operator. **Similarity is computed nowhere**: the predicate is exact
equality after § 3.2's normalization, never a distance and never a fuzzy match, and **no near-match
is offered** — the posture § *When the token is not a verb of this command* already takes, for the
same reason, on the same shape of guess.

**3 — The file-existence probe, reached only once the directory is observed present and the
collision check has passed.** `Read` `trips/<slug>/travelers/<file>.md`. Readable → **edit**. Not
readable → **create**. This probe is the control that makes standing rule 2 operative, and it is the
**whole** of that control: what the frontmatter does at runtime is the contested question § *The
frontmatter above* records, and nothing here rests on it either way.

**The precedence, stated rather than left to the order of the paragraphs.** **An absent directory
wins over whatever either check below it would have said**, and neither the collision check nor the
file probe is consulted at all until the directory is observed present. It is stated because the two
conditions are **indistinguishable in the file probe's outcome**: a readable directory holding no
such file and an absent directory both make `trips/<slug>/travelers/<file>.md` unreadable, so a file
probe that ran first would read a missing scaffold as *not readable*, take the **create** branch, and
reach `Write` — creating the directory this verb has no grant to create, on the one path the design
rejected. Running the directory probe second, or naming the branch without ordering it, is that
same defect written in a different order.

**The collision check's precedence has the same shape and the same cause, one layer in.** A key
already held and a file already present are likewise indistinguishable in the file probe's outcome
on the case that matters: two display names normalizing to one key produce two different paths, so
the file probe reports *not readable*, takes the **create** branch, and writes a second file under a
key § 3.2 permits only one of — the silent overwrite this check exists to stop, reached by the very
probe that looks like it is guarding against it. Running the collision check after the file probe,
or naming the branches without ordering them, is that same defect written in a different order.

**Create — three routes, offered in this order. The order is the corpus's and none may be dropped.**

1. **Walk through it here.** Run the interview using the template's own *Assistant — how to run this
   interview* and *Assistant — the sections, in order* as the script; the template is the authority
   on its own questions and this file does not restate them. About two to three minutes for the
   starred fields. Then `Write` the file. **Only the content above the line-initial
   `# END OF PROFILE` heading is the profile** — the guide below it is instructions for whoever is
   helping, never content. Match that heading **line-initially**: the same string also appears as
   inline code inside a bullet further down the template, and a substring match takes the wrong one.
2. **Fill it in themselves.** `Read` the template, `Write` it to the path unmodified, then tell them
   the path and the end-of-profile rule. A file of unfilled placeholders is a legitimate state, and
   the enrichment agent's blank-profile branch handles it exactly as it handles a missing one.
3. **Send it to someone who is not here.** Hand them the whole template file plus the one line the
   guide at the bottom of it gives them; they paste it into any assistant and return a block, which
   is saved to the path. **No file is created at hand-off** — the file appears when the block
   returns, and that return is a create if the path is absent and an edit if it is not. On a group
   trip this is how most travelers will do it, so **this route is never dropped.**

**Edit — an existing profile, field-scoped.**

1. `Read` the file.
2. Name the field or fields that are changing, and **echo the outgoing value verbatim** before
   writing.
3. `Edit` — only those field lines change. Every other byte is unchanged, and nothing below
   `# END OF PROFILE` is touched.
4. Confirm the write.
5. **Name `/trip-record travelers`** as the reconcile step. Name it; **do not run it** — an agent
   dispatch on a one-line change is heavier than the change, and both verbs live in this one command
   rather than at the ends of a chain.

An unanswered field keeps its bracketed placeholder; a field the user says does not apply takes a
single em dash. **Never write a bracketed placeholder as though it were an answer.**

**What this verb does not do.** It does not read `trip-context.md` and it does not write it — not
the `## Group` roster, not `- **Total travelers:**`, in either direction. Keeping the roster in step
is `/trip-record group`'s job, and this verb names it without running it. Reading the roster to
cross-check the `Traveler file` cell was rejected deliberately, and the reason is the point of the
negative: it introduces a second source for a filename that is already deterministic, and a
disagreement branch with no resolution.

## person <name>

**Reads:** nothing of its own. Dispatches `agents/00-enrichment.md` in the same reconciler role `travelers` dispatches, which reads `trips/<slug>/travelers/*.md`, `trips/<slug>/trip-context.md` and `trips/<slug>/outputs/traveler-model.md` — the model it is about to replace, read before that write because that read is what carries the `[THIRD-PARTY]` entry forward, and that entry has no source file to be re-derived from; and writes `outputs/traveler-model.md` alone.

The operator-provided third-party case: a party member who will never file a profile, whose needs
the operator supplies.

**Creates no file, anywhere** — no `travelers/<name>.md`, no proxy profile, no consent attestation.
The entry's durable record is the carried-forward model entry, trip-scoped and deletable. `ADR-006`
rejected the proxy profile precisely because it would create a durable identity artifact for a person
who never asked for one; it does not claim the entry leaves no trace.

- **Needs only.** The entry carries needs and nothing else. **A desire offered for a third party is
  refused**, and the refusal says why: `ADR-006` grants a party member exactly the needs class, and
  there is no default-allow outside it. **Identity data is refused** — passport, issuing country,
  validity — which `ADR-006` types as *capture refused* rather than merely undesirable. No lifecycle
  facet is populated on their behalf, and the bound is the entry **class** rather than a field list,
  so a facet a later release adds is bounded by it too.
- **Two marks, answering two different questions.** `[OPERATOR-PROVIDED]` records **who supplied the
  value**; `[THIRD-PARTY]` records that **the person described is not the person who spoke**.
  `[THIRD-PARTY]` is the non-publication key every downstream guard binds to, so it is present on
  every value sourced this way. The two marks are **orthogonal**: an operator relaying a first-party
  traveler's own needs produces `[OPERATOR-PROVIDED]` alone.
- **Never escalates.** The need never signals adding a constraint to `trip-context.md`, and the
  person is never added to any constraint's `Applies to:` roster. It may link to an existing
  governing constraint; it never creates one. This is the stated exception to link-don't-copy, and
  the reason is that `trip-context.md` is publish-bound.
- **Never published**, in attributed or in anonymized form. In a small named party, stripping the
  name does not strip the identification.
- **Never invented.** No operator input, no entry — not a blank one, not a `PROFILE MISSING` one. A
  `Party:` string on its own yields no entry, and a nameless party value yields none either, because
  the name arrives with the needs or there is nothing to key an entry to.
- **Provenance-marking records that a value is second-hand. It does not establish the described
  person's consent, and is never written or described as though it does.**

**How it lands.** `ADR-006` chose the option that adds no new capture surface, so this verb captures
the needs and dispatches the enrichment reconcile named on the `Reads:` line above, supplying them
as the operator-provided stand-in. **The enrichment agent writes the entry; this command does not.**

**Durability, stated rather than hidden.** The entry lives only in `outputs/traveler-model.md`,
which is `[DERIVED]` and rebuilt from source files — with this entry class **stated as an
exception**, because by design there is no source file for this person. A conforming reconcile
therefore **carries the entry forward verbatim rather than dropping it**, and that carry is the
mechanism. Re-running this verb re-supplies the needs and remains the **backstop** if a reconcile
ever does drop it — reached on that evidence, never as routine upkeep: a re-run is a fresh operator
statement, `agents/00-enrichment.md` emits an update signal for one, and on an entry that is still
there that signal is a replanning trigger for a change nobody made.

## travelers

**Reads:** nothing of its own. Dispatches `agents/00-enrichment.md` in its reconciler role — never the `[ENRICH]` research role — which reads `trips/<slug>/travelers/*.md`, `trips/<slug>/trip-context.md` and `trips/<slug>/outputs/traveler-model.md` — the model it is about to replace, read before that write because that read is what carries the `[THIRD-PARTY]` entry forward, and that entry has no source file to be re-derived from; and writes `outputs/traveler-model.md` alone.

**Enrichment alone, in its reconciler role.** The dispatch names the agent prompt, the role, and the
one file that role writes, exactly as the `Reads:` line above states them; standing rule 6 is what
obliges that naming.

**The research role is not run.** Running it would write `[ENRICH]` fields into `trip-context.md` —
fields § *Write ownership* assigns to the enrichment agent, so **no verb of this command writes a
byte of one**, and that rule is the whole of what establishes it. The web tools that role needs are
merely **unlisted** here, which is not the same as denied and establishes nothing on its own.
`CLAUDE.md`'s *"ownership follows the writer, not the caller"* is an attribution rule and holds
vacuously here; it is not a mandate to run the research role.

**Render the `## Update signals` block enrichment produced, then name the next verb by signal class
— without running it.** Four classes:

| Signal class | What this verb names | Why it does not run it |
|---|---|---|
| a changed need | `/trip replan`, naming the spokes the need touches | dispatching a planning pipeline is a different request type with its own command and its own permissions |
| a changed desire | `/trip replan`, with no spoke named | the same |
| a changed journey facet | `### Per-Traveler Planning Days [DERIVED]` is **stale** — report it and **name no command** | that block has **no writer** in `CLAUDE.md` § *Write ownership*, so its staleness is reported and never repaired in place |
| `PROFILE MISSING` | `/trip-record profile <name>` | the profile is the operator's to collect |

**The denominator is the roster, never the directory.** `travelers/` ships empty and stays empty
until a profile is filled, so a file count under it reads a real group as zero. This verb counts
nothing itself: it renders what enrichment produced, and enrichment takes the `## Group` roster and
`- **Total travelers:**` from `trip-context.md` as the party. A `- **Total travelers:**` that
legitimately exceeds the **named-traveler count** `group` defines is a real state and is never
reported as a defect.

## destination <value...>

**Reads:** `trips/<slug>/trip-context.md` — the `## Destination` block and the title line, read before they are written because standing rule 2 confines the `Edit` to the lines being changed and standing rule 4 tests a placeholder by value, and because a destination already decided is echoed from that value before it is replaced. Does not read `outputs/destination-shortlist.md` — the chosen value arrives as this verb's argument, and reading the shortlist would give that value a second source. Dispatches no agent.

The verb that performs the destination hand-off. `agents/destination-ideation.md` ends by saying it
never writes a destination into `trip-context.md` itself, and `/trip ideas` produces the shortlist
and names this step without performing it. This is the step they name.

**Argument.** Everything after the verb token, trimmed, is the primary destination value, and it is
written **verbatim**. It is never normalised, expanded, spell-corrected or resolved against a
gazetteer — standing rule 3 forbids inventing a value, and expanding `Lisbon` to `Lisbon, Portugal`
invents one. Never take the destination from the trip's slug, from the shortlist, from the
conversation's drift, or from the title line. **An empty argument is this verb's own refusal** — say
that no destination was given, and stop.

**What it writes.**

| Target | Rule |
|---|---|
| `- **Primary destination:**` | the argument value, verbatim |
| `- **Secondary destinations:**` and `- **Neighborhood base:**` | written only where the user states them in the same act; otherwise left exactly as they stand |
| the title line | its destination token only |

`trips/<slug>/trip-context.md` is the only path this verb writes, and those are the only targets in
it. In particular it does not write `Current mode` or `Mode notes` — that is `mode`'s act, and §
*Write ownership* binds the basis for a mode to the act that changes the cell. It writes no
`[ENRICH]` field and no `[DERIVED]` block.

**Why this verb owns the title line.** § *Write ownership* bundles the title line with the roster
and the traveler count because those are the fields `/trip-new` seeds, and that row names a
**writer** rather than a verb — so the split inside this command is made by subject. The title
line's only variable content is a destination, a month and a year, and the destination is the only
one of those three this verb establishes. Leaving `# Trip Context — [DESTINATION] …` bracketed once
a destination is decided is the state standing rule 4 exists to prevent, on the line every reader
sees first. **The month and the year are left exactly as they stand** unless the user states them in
the same act, and `group` does not write this line.

**Changing a destination that is already decided.** Legal — a group may change its mind — and it is
the branch that costs something, so it is stated rather than assumed.

1. **Echo the outgoing value verbatim** before writing anything.
2. Write the new value.
3. Say that **every `[ENRICH]`-tagged block is now research for the previous destination** — the tag
   is the selector, read from the file rather than listed here — and **name the refresh, without
   running it.** An `[ENRICH]` block has a writer: § *Write ownership* names the enrichment agent,
   and `CLAUDE.md`'s agent roster names a destination change as a condition for dispatching it, so
   **the command to name is read live from that roster** rather than listed here. Naming nothing is
   the shape § *Write ownership* fixes for a block whose writer does not exist, and this is not one.
4. Say that **the trip directory does not change.** `trip.slug` is the directory name exactly as
   `E1` spelled it, no verb of this command renames a directory, and a trip scaffolded as
   `lisbon-2027` that becomes Porto keeps its folder name. **The title line and the slug are allowed
   to disagree** — the slug is a folder name and the title is content.

**The mode hand-off, named and not performed.** Where the resolved `trip.mode` is `IDEATION`, name
**`/trip-record mode DISCOVERY`** with the value filled in, and say that this verb does not run it —
`/trip-new` names the same hand-off in the same order, so the two surfaces agree. **No other value
of `trip.mode` reaches this naming**, `UNSET` included, because the mode is a different act resting
on a different evidence class, and § *Write ownership* binds that evidence to whoever changes the
cell.

**What it never infers.** Nothing here reads a mode as evidence about a destination. `/trip-new`
writes no `- **Primary destination:**` in any mode — a destination it was told still reaches that
command's title line and its `Mode notes`, both of which it owns — so a freshly scaffolded trip
carries `trip.destination` as `UNDECIDED` whatever its mode, which is why `/trip-new` names this
verb from its `DISCOVERY` branch as well as its `IDEATION` one.

**It does not dispatch Destination Ideation.** That dispatch is `/trip ideas`'s, and making it here
would be a different request type with its own command and its own permissions.

## mode <MODE>

**Reads:** `trips/<slug>/trip-context.md` — the `## Mode` block, read before it is written because `Current mode` and `Mode notes` are replaced in one act, standing rule 2 confines the `Edit` to those lines, and the outgoing `Mode notes` is echoed before it is overwritten. It does **not** re-read that file to learn the trip's mode or its destination: the record block above already carries both by value, and re-deriving them is what § *What the blocks above are* forbids. It performs no read to obtain the mode value set — `CLAUDE.md` § *Modes* is auto-loaded and already in context, so consulting it is not a read this verb makes. Dispatches no agent.

**Argument.** One whitespace-delimited token, ASCII-case-folded, matched by **exact string
equality** against the mode values in the first column of `CLAUDE.md` § *Modes*, read live from the
table already in context. That set is **not written into this file** and **not counted** — the same
discipline § *Selecting the verb* applies to this command's own verb set, and it is what keeps a
mode a later release adds from needing an edit here. A token matching nothing is **this verb's own
refusal**: render the token verbatim, render the set read live, and stop. **No near-match, no *"did
you mean"*, no fallback** to another value — the reasons § *When the token is not a verb of this
command* gives hold identically here. The canonical value is written in the spelling § *Modes* uses.

**`Mode notes` is written in the same act, and its content is the operator's.** § *Write ownership*
reads *"Whoever changes `Current mode` writes `Mode notes` in the same act, naming the evidence for
the new value."* That evidence is **what the user stated in this conversation** — the same *stated,
not inferred* rule `/trip-new` applies to the starting mode, so it is a shipped convention rather
than a new one. It is **never** inferred from the destination, from which files exist, from the
request's wording, or from the mode being requested. Where the user stated no basis, **ask once** —
one question, not a questionnaire. Where they decline, **write nothing and say so**: a `Mode notes`
recording that no basis was given is a record of a decision nobody made, and § *Write ownership*
makes the basis part of the write rather than a courtesy attached to it.

**An unchanged value is a no-op.** Where the requested value equals the resolved `trip.mode`, write
nothing and say why: the `Mode notes` already in the file is the record of the act that set the
value, and replacing it with a restatement would overwrite the evidence for a transition this act
did not make. **`UNSET` is not one of the values § *Modes* carries**, so a `trip.mode` of `UNSET`
equals no requested value, this branch never fires on it, and the write proceeds — which is what
makes this verb reach a mode field that has never held a value.

**The undecided-destination report.** Where the requested mode is **not `IDEATION`** and
`trip.destination` reads `UNDECIDED`, say so, name **`/trip-record destination`**, and then **write
the mode anyway**. `IDEATION` is the value § *Modes* describes as nothing decided, read from that
description rather than counted here, so the test needs no ordering over the set and invents none.
**This is a report and not a gate.** This verb's
row constrains `destination` at `any`; there is no branch here that declines to write a mode on
account of a destination, and none may be added. The inference runs one way only: this verb may read
`trip.destination` and say it is `UNDECIDED`; nothing here reads a mode as evidence that a
destination was decided.

**How this verb and § *Write ownership*'s carve-out coexist — the partition is observability.** The
carve-out admits exactly the procedures it enumerates — **read that enumeration live from § *Write
ownership*** rather than from here — to write `Current mode`, and it carries its own admission test:
*the transition is observable from the artifact that procedure just produced, and is announced in
the same output.* That test draws the line.

| Path | What it covers, and the evidence it rests on |
|---|---|
| the carve-out | a transition the acting procedure's own completed artifact makes observable and that it announces in the same output — the evidence is the artifact it just wrote |
| this verb | every other transition — the evidence is a statement only the operator can make: the group picked, the flights are booked, we want the days reordered before anything runs |

The two are complements: together they are total, and they do not overlap, because a transition
either is observable in an artifact an enumerated procedure just produced or it is not. **Neither
becomes the silent default**, and these are the properties that stop it. This verb never fires
unless the user typed it, because § *Selecting the verb* supplies no verb nobody typed, so it cannot
become an implicit finaliser of somebody else's work. The carve-out never fires unless an enumerated
procedure completed work that makes the transition observable and announced it. The no-op above
stops a manual invocation after an announced transition from overwriting the announced basis with a
weaker one. And **this verb neither dispatches a planning procedure nor is dispatched by one** —
nothing here instructs an enumerated procedure to call this verb instead of writing the cell itself,
which is the hand-off failure the carve-out exists to prevent.

**What it writes.** `Current mode` and `Mode notes` in `trips/<slug>/trip-context.md`, and nothing
else in that file or in any other. It writes no `[ENRICH]` field and no `[DERIVED]` block.

**A live consequence worth stating.** `ITERATION` and `RESEQUENCING` become reachable through this
verb. Behaviours that branch on them — the hub's equity-aware disruption recovery, the validator's
recovery-equity check and its full pass after a resequence, and the scheduler's mode-gated reads —
begin to execute. That is the point of the verb, and it is also a risk: shipping the writer does not
test the readers.

## group [<name>]

**Reads:** `trips/<slug>/trip-context.md` — the whole of `## Group`, read before it is written because the presence probe on the roster's `Person` column selects adding a row from editing one, the table's own header row fixes the shape a new row is written in, the disposition for `- **Total travelers:**` is chosen from that field's current value, and a row being removed is echoed verbatim before it goes. Reads nothing under `trips/<slug>/travelers/` — the roster is the traveler denominator and a file count there is not, for the reason stated below. Dispatches no agent.

**Scope — the whole of `## Group`:** the roster table, `- **Total travelers:**`, `- **Travel
mode:**` and `- **Subgroup notes:**`. § *Write ownership* names the roster and the traveler count on
one row, and the remaining members of the block fall to its default row; those rows name the same
writer, so which verb serves them is this command's call, and the party is one subject. A user asked
to route `- **Travel mode:**` to a different verb from the roster would not guess it, and the
boundary would sit inside one section for no gain.

**Branch selection.**

- **No argument** — render the roster and `- **Total travelers:**` exactly as they stand, and ask
  what changes. **Write nothing** until the user names a change. This is the read-and-ask entry, and
  it is also the only path to a removal.
- **A name** — a **presence probe** on the roster's `Person` column, matched trimmed and
  ASCII-case-folded, **over the named rows only**: a row whose `Person` cell is a placeholder is
  skipped before the match, per the placeholder rule below. Present → **edit that row**. Absent →
  **add a row**. The probe runs before either write tool is reached and is the whole of the control,
  which is the same control `profile` rests on; nothing here rests on the frontmatter, whose runtime
  force § *The frontmatter above* records as contested.

**Adding a row — the append shape standing rule 7 admits**, reached once the read named above has
established the file and the presence probe has selected this branch. `Person` carries the name
**verbatim**. `Traveler file` is `travelers/<file>.md`,
where `<file>` is `/trip-new`'s transform reused verbatim and attributed to it — lowercase the name,
replace every run of characters outside `A-Za-z0-9._-` with a single `-`, then trim leading and
trailing `-`. It is invented nowhere: it is the transform that already wrote the roster's cells at
scaffold, and a second rule here would make this command disagree with the pointer the intake
hand-off rests on. An empty result leaves the cell bracketed and names which name needs a filename.
`Role / Relationship` takes what the user stated and otherwise keeps the template's bracketed
placeholder. **The row is written in the shape the file's own header row declares, and the header
row is never rewritten** — a roster carrying a legacy third column in place of `Traveler file` is a
real state, and re-heading the table would delete content this command does not own. **Name the
divergence; do not repair it.**

**The named-traveler count — one definition, and every disposition below counts with it.** A
roster row's `Person` cell is tested by **value** against the placeholder predicate § *Resolving a
trip* states field-general: **a trimmed value beginning with `[` and ending with `]` is a
placeholder, never a name.** The **named-traveler count is the number of roster rows whose `Person`
cell is not a placeholder** — the count of names, which is what `/trip-new` derives the field from
and is the semantics this section carries forward. **It is never the roster's row count.** The two
are equal only on a roster whose placeholder rows have all been resized away, and `/trip-new`
resizes them only when the user answered: **on an unanswered scaffold it leaves the template's
`[Name]` rows exactly as they stand**, so the row count on a real trip routinely exceeds the party
by however many of them the template still carries. Counting rows there would write a party as that
party plus every placeholder row, which is `ADR-007` §2 bound 6 — a placeholder read as evidence —
reached by arithmetic instead of by a branch. Standing rule 4 binds it in this file for the same
reason.

**Placeholder rows are unreachable as evidence anywhere in this verb**, not only in the count. A row
whose `Person` cell is a placeholder **satisfies no presence probe** — it is never *present* for any
name the user types, so it never selects the edit route and is never edited as though it were
somebody's row; it **enters no count and no comparison** in the table below; and it is **never
removed by this verb**, because removal is predicated on a named person who is not travelling and a
placeholder names nobody. It stays exactly as it stands, which is the state `/trip-new` left and
this verb does not own.

**`- **Total travelers:**` reconciliation — a decision over the states the field can be in, never a
silent adjustment.** The rules are `/trip-new`'s, carried forward: a stated total wins where one is
given, the named-traveler count otherwise, the two may legitimately differ, and **the roster is
never padded with placeholder rows to reach a total**, because a `[Name]` row is indistinguishable
from a real traveler with a missing profile.

| State of the field after the change | Disposition |
|---|---|
| a bracketed placeholder | write the named-traveler count |
| the user stated a total in this act | write the stated total |
| a number greater than or equal to the named-traveler count | leave it — the named person was already inside the count |
| a number less than the named-traveler count | say so and **ask**; write neither value until the user settles it |
| a removal, and the field equalled the pre-removal named-traveler count | decrement it |
| a removal, and the field exceeded that count | leave it, and say the unnamed remainder grew by one |

**The traveler denominator is the roster and `- **Total travelers:**`, never a file count under
`travelers/`.** That directory ships empty and stays empty until a profile is filled, so a file
count reads a real group as zero; the roster is the input `agents/00-enrichment.md`'s `PROFILE
MISSING` branch, `### Per-Traveler Planning Days [DERIVED]` and the satisfaction layer all read. **A
`- **Total travelers:**` that legitimately exceeds the named-traveler count is a real state and is
never reported as a defect** — a stated total may carry a member the roster has no name for.

**A `[THIRD-PARTY]` party member gets no roster row, and is not counted in `- **Total travelers:**`
either.** `## Group` is publish-bound and so is every other field of `trip-context.md`, and
`CLAUDE.md` states that a `[THIRD-PARTY]` value **never escalates into `trip-context.md`** and must
not appear in any publish-bound artifact **in attributed *or* anonymized form**. The count is not
the exception it looks like. Stripping the name is exactly what anonymizing is, and `person` states
the consequence thirty lines above this one: *in a small named party, stripping the name does not
strip the identification.* A total of five over four named rows publishes that a fifth party member
exists and is not one of the four — an unnamed person, identified by subtraction, in the file the
site build reads. That is the anonymized half of the bound, and it is the half `person` already
rules out, so this verb agrees with `person` rather than rebutting it. A roster row would also
assert a `travelers/<name>.md` for someone who has filed nothing, and the only way that file reaches
existence for them is the **proxy-authored** profile `ADR-006` rejected — a durable identity
artifact for a person who never asked for one. What that ADR contemplates instead is the profile
that person files themselves, which this verb neither creates nor forecloses.

**Where the honest denominator lives instead.** The party denominator needs-compliance and
desire-coverage grade against is the entry set of `outputs/traveler-model.md`, which carries the
`[OPERATOR-PROVIDED]` + `[THIRD-PARTY]` entry — **carried forward verbatim across a reconcile rather
than re-derived**, which is what lets that home hold an entry with no source file, and is the same
reading `person` § *Durability* states — which `CLAUDE.md` states the site build **excludes**, and
which the hub applies as a hard bound before any objective. That member reaches it through
`person`'s dispatch, not through a number in a publish-bound file — so honesty is preserved in the
artifact that can hold it and is not bought in the one that cannot. `person` records such a member's
needs and creates no file anywhere; this verb records roster rows and the count in `trip-context.md`.
**They meet at exactly this cell and nowhere else**, which is why it is stated here rather than left
to the reader: a difference between the total and the named-traveler count is never reported as a
defect to reconcile, and **it is never produced by a `[THIRD-PARTY]` member.** Where the user asks
for one to be added to the party, name **`/trip-record person <name>`** and **do not run it**.

**Removing a row.** Only from the no-argument render, or where the user names the person and states
that they are not travelling. **Echo the whole row verbatim before writing** — the removed bytes
survive in the transcript, which is what standing rule 2's bound asks of a write that will not
preserve what it replaces. Remove **only that row**. **Never delete anything under `travelers/`**:
that file is Layer-1 source and this verb has no delete path to it. Then name where the person may
still appear, without touching either place: `outputs/traveler-model.md`, until `/trip-record
travelers` reconciles it, and any constraint's `Applies to:` line, which is `fact`'s.

**After any roster change.** Report `### Per-Traveler Planning Days [DERIVED]` as **stale** and
**name no command** — that block has no writer in § *Write ownership*, so its staleness is reported
and never repaired in place, and this verb writes zero bytes of it. Name **`/trip-record
travelers`** as the reconcile, and **do not run it**: an agent dispatch on a one-line change is
heavier than the change, which is the same call `profile` makes.

**What it writes.** The `## Group` block of `trips/<slug>/trip-context.md`, and nothing else in that
file or in any other. It writes no `[ENRICH]` field, no `[DERIVED]` block, and not the title line.

## fact <statement>

**Reads:** `trips/<slug>/trip-context.md` — the one block the statement routes to, read before it is written because standing rule 4 tests a placeholder by value and so separates a fill from a replacement, because an outgoing value is echoed verbatim before it is replaced, and because a new repeat unit is appended under the units already in that block without renumbering or rewriting them. Reads no other block of that file. Reads `outputs/event-status.md` not at all — that file is `/trip-record event`'s, and reading it here would give `## Locked Elements` a second source it does not write. Dispatches no agent.

**The default-row verb.** § *Write ownership*'s default row assigns every untagged field not named
on another row to this command; inside this command those fields are this verb's, except the ones
`destination`, `mode` and `group` name. `## Locked Elements` and `## Current Itinerary Status` are
named to this command on their own row, and they are this verb's too.

**Three ordered steps, and the first is the one that matters.**

**1 — The admission test, before anything else.** *Would the next synthesis pass regenerate the
bytes I am about to write?* That is § *Write ownership*'s own test — *if the next synthesis pass
would regenerate those bytes, they do not belong in this file at all* — made decidable. **Yes → this
is not a fact.** Name the procedure verb that owns it, and **stop**. A restaurant choice lives in
`outputs/final-itinerary.md`, which is versioned, and in `outputs/venue-matrix.md` and
`outputs/links-reference.md`, which are rebuilt on every synthesis; writing it here is not a small
change, it is a change with a deletion already scheduled. The adjacent things that **are** facts:
the dietary need that made the restaurant wrong, which is `profile`'s; the reservation that got
confirmed, which is `/trip-record event`'s; and the hard constraint it violated, which is this
verb's.

**2 — The ownership route.** Which block does the statement land in? A block another writer owns is
**named, not written**.

| Block class | Route |
|---|---|
| `[ENRICH]`-tagged | the enrichment agent's (`agents/00-enrichment.md`). Name it and write nothing — this verb writes no `[ENRICH]` field |
| `[DERIVED]` | **no writer exists.** Report staleness and **name no command**; this verb writes zero bytes of such a block |
| `**Lifecycle:**` | `/trip-decommission`'s — name it and stop. An absent line is the contract's declared default rather than a gap to fill. This verb never writes it |
| `## Destination`, `## Mode` and `## Group` | a sibling verb of this same command — name it and stop |
| `## Locked Elements`, `## Current Itinerary Status`, and every other untagged field | **this verb writes it** |

Ownership follows the block and not the command: this verb does not write `## Destination` or
`Current mode` merely because they sit in the same file under the same command. One block with more
than one writer is the seam this partition exists to avoid, and it would let a mode reach the file
without the evidence § *Write ownership* binds to it.

**3 — Ambiguity, and the zero case is its own branch.** A statement that does not resolve to exactly
one block resolves either to more than one or to none, and those are two different renders. **More
than one: ask once, naming them.** **None: say that no block of `trip-context.md` owns the
statement, name none, and stop** — the ask has no candidates to offer, and this verb may not create
the block that would be the answer, so the refusal *is* the terminal disposition rather than a
question with nothing in it. This verb never collapses the two. **Never write to more than one
block** to be safe. And **never create a new `##`
block** — § *Write ownership* assigns a block it does not list to nobody, and requires that *a new
block gets an owner in this table before it gets content*, so a command that created blocks would
make that table a description of the past. Adding a `### [Constraint Name]` block under `## Hard
Constraints`, a `#### Origin <letter>` block under `### Additional origins`, or a row under `##
Possible Day Trips` is an **instance of a unit the template already defines** and is not creating a
block.

**Write shapes.**

- **A bracketed placeholder becoming a value is a fill**, not a replacement — the placeholder is the
  form, not content. Write it.
- **A value becoming a different value is a replacement.** **Echo the outgoing value verbatim before
  writing**, and change only that field's lines.
- **A new unit is appended**, which is the shape **standing rule 7** admits and the tool it names,
  under the block's own repeat unit — a `### [Constraint Name]` block
  under `## Hard Constraints`, a `#### Origin <letter>` block under `### Additional origins`, a row
  under `## Possible Day Trips` — and **no neighbouring unit is renumbered, reordered or
  rewritten**. A new `### [Constraint Name]` block is written with **all of the template's fields
  present**, the unanswered ones keeping their bracketed placeholders.
- **A removal** names the unit, **echoes it verbatim before writing**, removes no more than the
  named unit, and **never removes a whole `##` block**.
- An unanswered field keeps its bracketed placeholder and a field that does not apply takes a single
  em dash — the distinction standing rule 3 draws, and this verb never collapses it. *"None
  identified"* under `## Hard Constraints` is written only where the user confirms it, because the
  template asks for that confirmation.

**Link, don't copy.** A trip-level constraint lives in this file; the personal detail behind one
traveler's need lives in that traveler's own `travelers/<name>.md`, and the link between them is the
enrichment agent's, recorded through `Applies to:`. **This verb never copies a traveler's need text
into a constraint**, and it writes no per-traveler desire detail, no per-event status and no
satisfaction metric into this file — those have their own homes. **A `[THIRD-PARTY]` subject is
never added to a constraint's `Applies to:` line**, for the publish-bound reason that also keeps
them off the roster. After a new trip-level constraint, name **`/trip-record travelers`** as the
reconcile that establishes the link, and **do not run it**.

**`## Locked Elements` — the seam with `/trip-record event`.** This block is the trip-level **human
summary**, operator-maintained and not `[ENRICH]`-tagged. `outputs/event-status.md` is the
**structured source of truth** for the scheduler, the hub and the validator, and where the two could
drift the structured table is authoritative for those readers and this note is the summary.
**Writing a note here changes no event's status**, and **this verb never writes
`outputs/event-status.md`** — that is `/trip-record event`'s, and it is where an event's status is
recorded. One direction does run and is worth stating: the enrichment agent may **read** `## Locked
Elements` once, at setup, to seed initial `locked` rows. Say that; do not act on it.

**Cross-block consequences — named, never performed.**

| What was recorded | What this verb names |
|---|---|
| a booked transport or lodging anchor — a confirmation code, a flight leg, an accommodation booking status | **`/trip-record mode ENRICHMENT`**, and it does not run it: the mode is another row's cell and its evidence belongs to that act, not this one |
| a changed or added flight leg, or a new `#### Origin <letter>` block | `### Effective Planning Days` and `### Per-Traveler Planning Days` are **stale**. **Name no command** |
| a new trip-level constraint | **`/trip-record travelers`**, and it does not run it — travelers' needs link to the constraint, and the link is the enrichment agent's |
| an event that is now fixed | **`/trip-record event`**, and it does not run it — the note here is the summary, the row there is the truth |

More than one row may fire on one statement: a newly booked flight leg is both an anchor and a
change to the planning-day inputs.

`## Current Itinerary Status` carries the template's guidance that it is used in `ITERATION` and
`RESEQUENCING` and left blank in `IDEATION` or `DISCOVERY`. That is guidance: **this verb does not
gate on the mode** — name the mismatch and write what the user asked for.

**What it writes.** Blocks of `trips/<slug>/trip-context.md`, and nothing else in that file or in
any other. It names the enrichment agent and dispatches none, so the corpus's *ownership follows the
writer, not the caller* rule has nothing to exclude on this verb's behalf.

## .publish-slug <name>

**Reads:** `trips/<slug>/.publish-slug` — the existence probe that selects creating the file from replacing it, and, on the replace route, the outgoing value read before it is overwritten, so that it can be echoed and so the reversal has something to restore. Reads `trip-context.md` not at all — nothing in it is this verb's subject. **Reads no `.passphrase`**: reading it would put the secret into the session transcript, which is the failure the publish exclusions exist to avoid. Runs no script and dispatches no agent.

**The one file this verb writes, and it is not `trip-context.md`.** The target is
`trips/<slug>/.publish-slug` — under `trips/<slug>/` per standing rule 5, where `<slug>` is
`trip.slug` exactly as `E1` spelled it. That path lies **outside § *Write ownership*'s scope**,
which is `trip-context.md` block by block; `CLAUDE.md` § *Publishing to GitHub Pages* already
assigns its author — *put the bare repo name in `trips/<destination>-<year>/.publish-slug`* — and
this verb is that author acting through a command, exactly as § *Write ownership* assigns `## Locked
Elements` to *the operator, through `/trip-record`*.

**Why this is not a publish-boundary crossing.** It runs no subcommand of
`scripts/publish-trip-site.sh`, dispatches no agent, touches no credential and has no out-of-repo
effect at write time. What it gives an operator is an addressable way to set the repo name
**before** anything is published. **Standing rule 1 is what establishes that**, and it is untouched;
every entry of `disallowed-tools` is unchanged too and stands beside it as a **declared**
restriction — corroboration, on the terms § *The frontmatter above* states, rather than the thing
that makes the claim true.

**Validation — two conjuncts, and they are strict for opposite reasons.**

1. **Charset.** Non-empty, and every character in `A-Za-z0-9._-`. This mirrors `slug_for()` in
   `scripts/publish-trip-site.sh`, whose rejection case is exactly `''|*[!A-Za-z0-9._-]*`, and it is
   attributed to that function rather than presented as new. **`/trip-new`'s first-character anchor
   is deliberately not applied here.** That anchor exists because a slug becomes a directory name
   and `.` and `..` are the segments that traverse; this value is a **GitHub repo name** and never a
   path component, so the anchor has no purchase — and applying it would make this command refuse
   values the resolver accepts, which is a disagreement with the resolver rather than a guard.
2. **Whitespace is refused**, even though `slug_for()` accepts it. That function reads the file
   through `tr -d '[:space:]'`, which **deletes** whitespace rather than trimming or rejecting it,
   so `my repo` resolves to `myrepo` and publishes to a repo the operator never typed, with nothing
   saying so. The two calls go opposite ways on purpose, and the reason is the difference between
   the two failure shapes: the resolver **accepts** a leading dot, so refusing it would be this
   command disagreeing with the resolver; the resolver **silently transforms** whitespace, so
   accepting it would be this command writing a value that is not the one it validated.

A value failing either conjunct is **this verb's own refusal**: say what was rejected and why, state
the shape, ask for a corrected value, and **write nothing**. A rejected value is never repaired by
guessing, and this verb **generates no name of its own** — the operator chooses it, and standing
rule 3 forbids inventing one.

**File shape — exactly one line.** The bare name and a trailing newline, matching what
`ensure_opaque_slug()` writes. **No comment line, no second line, no markdown.** `slug_for()` reads
the whole file through that whitespace delete, so **a second line is concatenated into the slug**
rather than ignored — a header comment would silently become part of the repo name.

**Create versus replace, selected by an existence probe.** `Read` the target path; the probe runs
before either write tool is reached. Not readable → **create** with `Write`, which is standing rule
2's one condition for it. Readable → **replace**, and only after all four of these:

1. **Echo the outgoing value verbatim.**
2. Say that a site already published under the outgoing value stops being reachable: `update`,
   `rotate` and `unpublish` all resolve the repo through this file, and **`unpublish` on a name that
   no longer matches a live repo reports that there is nothing to take down and exits successfully**
   — the site stays up and the operator is told it is gone. That is the shape the contract's
   stop-message rule forbids, arriving from the script rather than from a gate.
3. Name the reversal — **restore the outgoing value**. Reversibility **CHEAP**, and cheap only
   because step 1 preserved it.
4. **Ask once**, then write. This verb cannot observe whether the trip is published — it reads no
   `.passphrase` and it runs no script — so it does not assert that the trip is unpublished. It says
   what it could not establish, and lets the operator answer.

**One more consequence to state.** A `.publish-slug` that already exists makes an **opaque** publish
keep the chosen name rather than generating a random one: `ensure_opaque_slug()` returns early when
the file is non-empty, and says so. An operator who set a memorable name and later wants opacity
removes or replaces the file first.

**Never.** Runs no subcommand of `scripts/publish-trip-site.sh` — not directly, not through `bash`
or `sh`. Reads no `.passphrase`. Sets no `ALLOW_PLAINTEXT`. Passes no `--yes` to `unpublish`.
Generates no name of its own. Writes no path other than `trips/<slug>/.publish-slug`. Where
publishing itself is what the user wants, name `/trip-publish` and stop; where taking a site down is
what they want, name `/trip-decommission` and stop.

## event <id> <state>

**Reads:** `trips/<slug>/outputs/event-status.md` — the row `<id>` names, read **before** it is written because that file is persist-mutable: the read is what locates the one row, supplies its outgoing `Status` for the echo, and makes the never-regenerate shape below checkable rather than merely asserted; `reference/data-model.md` — § *The Per-Event Status Model*, read at invocation for the transitions it names and for the table shape this section cites instead of rendering. Reads `trips/<slug>/trip-context.md` not at all — `## Locked Elements` is the trip-level human summary and `/trip-record fact`'s, and reading it here would give an event's status a second source. It performs no read to obtain the status vocabulary: `CLAUDE.md` § *Key Rules* is auto-loaded and already in context, so consulting it is not a read this verb makes. Dispatches no agent.

The per-event status verb. It changes the `Status` cell of one named row of
`trips/<slug>/outputs/event-status.md` and recomputes that row's derived needs-booking cell. It
authors no other cell, creates no row, creates no file, and deletes no row.

**The discriminator, stated first because every refusal below rests on it.** This verb records a
status change that **has already happened**, or that the user is deliberately making to the record.
It never *requests* a planning change. A booking that fell through, a table that was held, a museum
morning the group settled — those are facts about the world. A wish to re-open a settled event is a
request to the plan: name **`/trip replan`**, naming the event, and stop. Naming is the whole of
this verb's part in that; **it does not run it.**

**Every refusal in this section is in-verb and post-resolution.** Each one is reached after the trip
resolved and this verb ran, so **none of them is a branch of the shell**: none sets
`trip.stop_gate`, none changes `trip.resolution`, and none renders a gate id.

**Argument grammar.** The argument string is an event id followed by a state, and nothing after it.

- **A part missing** — say **which** part was not given, and stop.
- **Anything after the state** — say the invocation is malformed, and name **`/trip-record log`** as
  where a reason for the change belongs. The signature carries no note field, so absorbing trailing
  text into `Notes` would invent a shape standing rule 3 forbids and would make `Notes` a free-text
  field with two writers. Name `log`; **do not run it.**

**`<id>` is matched by exact, case-sensitive string equality** against the `Event ID` column. Not a
prefix match, not a nearest match, not a fuzzy match, not a substring match, and **no near-match
suggestion — no *"did you mean"*** — the reasons § *When the token is not a verb of this command*
gives hold identically here, and this is a path that writes. No glob, no wildcard, no `all`, no day
selector, no *"the option on Day 3"*: **one row per invocation.** The case-**sensitivity** is a
deliberate departure from the verb lookup's case-folding rather than an oversight, and the reason is
the difference between the two keys: the verb vocabulary is closed and lowercase, whereas the Event
ID is declared **opaque**, so folding it could collide two distinct keys. Being opaque it is also
**day-independent** — no day is read out of it and none is written into it, the `Day` column carries
the day, and this verb does not touch that column.

**`<state>` is ASCII-case-folded and matched by exact string equality against the per-event status
vocabulary `CLAUDE.md` § *Key Rules* fixes**, read live from the text already in context. That
vocabulary is **not written into this file** and **not counted** — the same discipline § *Selecting
the verb* applies to this command's own verb set, and it is what keeps a status a later release adds
from needing an edit here. A token matching nothing is **this verb's own refusal**: render the token
verbatim, render the vocabulary read live, and stop. No near-match, no fallback.

**Probes, in this order, before any write tool is reached.**

1. `Read` `trips/<slug>/outputs/event-status.md`. **Absent → stop, and create nothing.** That file
   is created by whichever agent first writes it — the enrichment agent's setup seed, or the hub on
   the first full synthesis — and this command is in neither role; it is not a scaffold member of
   `/trip-new` either. Name the path, say that it appears when the plan is first synthesised, and
   name the repair `reference/data-model.md` § *Bootstrap — who creates `event-status.md`* states —
   **`/trip plan`** where the resolved mode admits it, and the mode-recording step first where it
   does not. **Do not run it**, and stop. Naming a verb is not writing the file: this verb stays
   outside the creator set that section fixes.
2. **A row carrying `<id>`. None → stop, naming the id verbatim.** This verb never creates a row:
   minting an Event ID is the hub's act on first placement, and a status row for an event the
   itinerary has not placed is the inverse of the ghost row the model forbids.
3. **The id is unique. More than one row carries it → stop**, naming the id and that it appears more
   than once, and **pick neither.** The id is the cross-run join key, so a duplicate is a corrupt
   file rather than a choice, and selecting one silently would resolve a conflict the file itself
   records.
4. **Already in the requested state → say so and write nothing.** A no-op write to a persist-mutable
   file is still a write, and what makes that file worth reading is that a write in it means
   something changed.

**Admissibility is cited, never enumerated.** A transition is admitted exactly when
`reference/data-model.md` § *The Per-Event Status Model* names it, read at invocation. **This file
enumerates no transition set of its own**, and the reason is stated rather than left to taste: the
state machine is the data model's to define, and a set copied into a command is a frozen denominator
that refuses a legitimate transition the moment the model gains an edge. A pair that section does
not name is **this verb's own refusal**: render the requested edge verbatim, name that section, and
stop — and where what the user wants is a change to the plan rather than a record of one, name
**`/trip replan`**, and **do not run it.**

**What a transition obliges, and what it does not.** These are consequences, not admissibility:
naming what a transition obliges declares nothing about whether it runs, which stays the model's to
say. Each class below is named, never counted.

**`option → planned` — a deliberate user instruction, never automatic.** The verb *is* that
instruction: the user names the opaque id and names the target state. This verb never selects an
option to promote, never promotes because a primary slot fell vacant, never promotes by day, and
never promotes in bulk.

- *Obliges:* the row's `Status` becomes the state the user named, and the derived needs-booking cell
  recomputes — so a backup carrying `requires booking? = yes` immediately reads as needing a
  booking, which is the flag taking effect on promotion exactly as the corpus states it.
- *Does not oblige:* **the primary slot is not re-pointed.** A promotion in the corpus is a re-point
  plus a flip, and this verb performs the flip half alone, because the itinerary is the hub's
  artifact and this verb dispatches nothing. Until the next synthesis `outputs/venue-matrix.md`
  still shows the event as an alternative — a disagreement that is **reported here and never
  repaired here**, because that file is rebuilt on every synthesis and a hand repair to a rebuilt
  artifact is a change with a deletion already scheduled. Where the slot is what the user wants
  re-pointed, name **`/trip replan`**, **do not run it**, and stop.

**`option → locked` — promoting and settling in one act, and it carries both.** The model names this
edge, so what it obliges is the union of the classes it spans and nothing new.

- *Obliges:* the row's `Status` becomes `locked` and the derived needs-booking cell recomputes — a
  backup carrying `requires booking? = yes` therefore never surfaces as needing one, because the
  booking is what this transition records.
- *Does not oblige:* **the primary slot is not re-pointed**, for the reason the promotion class above
  gives and with the same disposition — report the `outputs/venue-matrix.md` disagreement, never
  repair it here, and where the slot is what the user wants re-pointed name **`/trip replan`**, **do
  not run it**, and stop. **`Requires booking?` and `## Locked Elements` are untouched**, for the
  reason the settling class below gives.

**The fall-through, so a class this section has not written is never a refusal.** An edge
`reference/data-model.md` § *The Per-Event Status Model* names and this section does not class takes
the union of the classes it spans, and where it spans none it takes the general rules alone:
`Status` is the authored cell, the derived needs-booking cell recomputes by the corpus's predicate,
no other cell is written, and nothing is dispatched. Admissibility stays that section's — this one
states consequences only — so a missing class costs the user the warning, never the transition.

**`planned → locked` and `planned → firmed` — settling.** Which one applies is a fact about whether
a reservation sits behind the event, not a preference, and **this verb never chooses between them**
— the user names the state.

- *Obliges:* the event moves from open-to-iteration to preserved, and drops out of the needs-booking
  set by the recompute below.
- *Does not oblige:* **`Requires booking?` is untouched.** It is a property of the event's kind
  rather than of its status, and **no verb of this command writes it.** A `firmed` row carrying
  `requires booking? = yes` is therefore neither refused nor tidied up: the flag stays true, stops
  surfacing, and surfaces again if the event returns to `planned`. `## Locked Elements` is not
  written either — that block is the trip-level summary and `/trip-record fact`'s, so where a
  settled event should read that way in the summary too, **name that verb and do not run it.**

**`locked → planned` — the fall-through, and a named trigger.** A cancelled reservation, a sold-out
ticket, a withdrawn hold. This is the class whose consequence reaches past its own row, so both
directions are stated.

- *Obliges, in the file:* the event re-opens to iteration and its booking question reopens — the
  derived cell recomputes to `yes` where `requires booking? = yes`.
- *Obliges, beyond the file:* the trip now carries the **disruption-recovery trigger** § *Modes*
  names, so the hub's equity-aware recovery and the validator's recovery-equity check belong to the
  next planning pass. Name **`/trip replan`**, and **do not run it.** Name **`/trip-record log`** as
  well, and do not run it: *why* a
  booking fell through is exactly what the log carries, and the status table has no field for it.
- *Does not oblige:* it does not dispatch the hub, does not re-run an agent, and does not patch the
  itinerary. **It does not write `Current mode`.** The regression triggers the *recovery*; the mode
  value is a separate fact resting on a separate evidence class, and inside this command
  **`/trip-record mode`** is its writer — named here, not run. It also does not delete the row:
  deletion is predicated on the event being removed from the itinerary, which this verb neither
  performs nor observes, and a row deleted while its event remains is worse than the ghost row the
  rule forbids. It touches no `Day`, `Time`, `Event`, `Requires booking?` or `Notes` cell.

**The one derived cell, and why writing it is not authoring it.** `Status` is the only **authored**
cell any invocation of this verb writes. The row's needs-booking cell is **recomputed**, by the
corpus's stated predicate — `planned` **and** `requires booking? = yes` — and by no other rule; the
corpus calls that column computed rather than authored and states the recompute as a consequence of
the transition itself. The tradeoff is stated rather than hidden: the same passage also says the hub
recomputes the cell whenever it touches a row, which can be read as an exclusive grant. **The
narrower reading is taken** — an obligation stated, not a monopoly — because the alternative writes
a known falsehood into the file the scheduler, the hub and the validator all read, in exactly the
case where the falsehood costs most: a reopened booking reading as needing none.

**Why this verb may write a file the pipeline also writes, and why that permission reaches nothing
else.** The permission comes from that file's **persist-mutable** lifecycle rather than from any
count of its writers: synthesis *reads* existing status and never regenerates it, so a flip made by
hand survives the next pass — an exception the lifecycle predicts, not an exception to the rule.
**Every other artifact the pipeline produces is rebuilt, versioned or appended**, so a hand edit to
`outputs/venue-matrix.md`, `outputs/traveler-model.md`, `outputs/satisfaction-metrics.md` or
`outputs/final-itinerary.md` is a change with a deletion already scheduled, and this verb earns no
licence to make one.

**The no-overwrite shape that follows, and it binds this verb rather than the standing clause.**
`Read` the file; `Edit` the named row in place; **never regenerate it.** Never rewrite the file from
scratch, never append a dated section — that is the accumulate pattern and this file is not it —
never version it, and never create it. Standing rule 2's condition for `Edit` is met in its own
terms: the target exists, and only the named row's line changes.

**What it never does.** It writes **zero bytes of `trip-context.md`** — not `## Locked Elements`,
not `## Current Itinerary Status`, not `Current mode`, in either direction.
`trips/<slug>/outputs/event-status.md` is the only path it writes, built from `trip.slug` exactly as
`E1` spelled it and never from a `--trip` value, which this verb does not consume. It takes no
`Write` grant, creates no file and no directory, dispatches no agent, and runs no script. And it
**never reads a decided destination out of the existence of an event-status file** — that a
synthesis has run says nothing about `## Destination`. Neither the mode nor the destination is a
condition of this verb: its row reads `any` in both cells, so a trip whose mode has never been set
and whose destination is undecided reaches it and runs.

## log

**Reads:** `trips/<slug>/trip-log.md` — read **before** it is written, to confirm the target is the trip's log and to locate the append point at its end; the read never decides the entry's content, which comes from the session, and it never re-opens a prior entry. Reads `trips/<slug>/trip-context.md` not at all — a constraint the session surfaced belongs to that file and is `/trip-record fact`'s, and reading it here would let the log become a second source for a fact whose reasoning is the only part it carries. Reads `trips/<slug>/outputs/event-status.md` not at all — an event's status is `/trip-record event`'s. It performs no read to obtain the entry's structure or its scale: `CLAUDE.md` § *trip-log.md* and § *Ending a session* are auto-loaded and already in context, so consulting them is not a read this verb makes. Dispatches no agent.

The session-entry verb. It appends one entry to `trips/<slug>/trip-log.md` — the file § *Session
Protocol* makes the session bridge — and does nothing else.

**A named home for an act that stays available conversationally.** `/trip-new` creates this file as
a scaffold member with the setup entry, and its Resume branch declines to append another, saying in
terms that session logging is already covered by the existing request types. This verb gives that
act a typed home without displacing the conversational path: it is not heavier than asking, because
a free-form request already resolves through the same ladder — this simply types it. **Nothing here
makes a log entry mandatory**, and a session logged by asking rather than by typing is not an
omission.

**Argument.** This verb requires no positional argument. Any remaining argument string is the
entry's **topic**, and never its body: the body is composed from the session, and a one-line
argument is not a session.

**The date.** Get it by running `date +%F` as a tool call **here in the body, not as a pre-execution
block**, and use the bare `YYYY-MM-DD` form exactly as the call returned it. The reason is the
contract rather than style: § *What the blocks above are* fixes how many pre-execution blocks this
file carries and it already carries all of them, so a further one is a red check on push whatever
this section says. `Bash(date:*)` is the grant this call takes, and `/trip-new` already takes its
own date this way for the same stated reason — a shipped convention rather than a new one.

**Precondition.** `Read` `trips/<slug>/trip-log.md`. **Absent → stop, and create nothing:** say
which path is missing and name **`/trip-new <slug>`**, whose Resume branch is the declared repair
path for a missing scaffold member. Name it; **do not run it.** No `Write` grant is taken here, and
this verb creates no file and no directory. That stop is reached after the trip resolved and this
verb ran, so it sets no `trip.stop_gate`, does not change `trip.resolution`, and renders no gate id.

**The write tool, and the standing rule it is taken under.** `Edit`, under **standing rule 7** — the
append shape: the target exists, no existing line changes, and the entry is added at end of file.
The precondition above **is** rule 7's existence probe, and it is what makes the tool reachable: it
runs before `Edit`, and on its absent branch this verb stops rather than falling through to `Write`.
Rule 2's own two conditions are cited and neither is met, which is why rule 7 exists rather than
this section reading one of them loosely: **`Write`** is out because it is admitted only where the
target is absent, and this verb stops there and disclaims it in terms; **`Edit`**'s rule-2 condition
speaks of *only the named field's lines* changing, and an append has no named field, because the
lines it writes are not in the file yet. Stretching that clause to cover an append would make it
cover any addition to any file and would leave the sibling `## event` — which meets rule 2's `Edit`
condition literally, and says so — resting on a condition that no longer discriminates. The
widening is stated in the standing clause where it binds every verb, not asserted here.

**Shape and content.**

- **The entry structure is `CLAUDE.md` § *trip-log.md*'s and is not restated here** — the same
  discipline `profile` applies to the intake template's questions. That section is the authority on
  its own fields, read live from the text already in context.
- **The entry's scale is § *Ending a session*'s:** a quick edit gets a one-liner, a planning session
  gets the full register. That section's remaining disposition — skipping the log — **is not
  reachable here**, because the verb was typed and the decision to log is therefore already made.
- **Append only.** A new `## Session <YYYY-MM-DD>` section at end of file, carrying the
  `— <topic>` suffix shape `/trip-new`'s setup entry uses when a topic was supplied. **No existing
  line changes:** the title line is not rewritten, and no prior entry is edited, re-ordered, merged,
  deduplicated or removed. Where a section for the same date already exists, **a second one is
  appended beside it rather than merged into it** — merging edits a prior entry, and a running
  register legitimately holds more than one entry for a date.
- **Never invents.** The content comes from the session. An element with nothing to record is
  **omitted**, following the omit-the-line convention `/trip-new`'s setup entry already uses;
  standing rule 3 binds unchanged, and an empty element is never filled to make the entry look
  complete.

**The boundary that keeps the log from becoming a rival source. There are two seams, not one, and
the second is the one the scale rule opens.** At both, the log carries **why a choice was made** and
never the state itself; it is link-don't-copy applied to the two places a session entry could
quietly become a second source.

**Seam 1 — a constraint.** A constraint that surfaced in a session is recorded here as **a decision
and its reasoning** — what was chosen, and why. The constraint itself belongs to `trip-context.md`
§ *Hard Constraints*, which is **`/trip-record fact`**'s: name it, and **do not run it.**

**Seam 2 — the state of the plan, which this verb reaches by binding its scale to § *Ending a
session*.** That section's full register carries the element *"Current state of the plan (what's
solid, what's still open)"*, and written as free text that element is a **rival to two structured
homes at once**: `outputs/event-status.md`, the per-event source of truth for the scheduler, the hub
and the validator, which is **`/trip-record event`**'s; and `trip-context.md` § *Current Itinerary
Status*, the trip-level human summary, which is **`/trip-record fact`**'s. This verb is the one that
will actually compose the narrative, so it is the one that has to hold the line. **Neither the
guard nor this verb's criterion can observe this seam** — an entry is free text and every rendering
of it is well-formed — so the discipline is stated here and rests on nothing else.

**What the element carries here, and what it does not.** It carries **what was decided this session
and why, and what the session left open and why** — the reasoning, which is exactly what neither
structured home holds. It does **not** carry an event's status, an Event ID, a per-event booking
state, or a restatement of what those files say; a settled event is `event`'s row and a trip-level
summary of the plan's standing is `fact`'s block. **Where the session actually changed a status or
the trip-level summary, name the verb that owns it** — **`/trip-record event`** for the row,
**`/trip-record fact`** for § *Current Itinerary Status* — and **do not run either.** An entry that
would read as a status record if the two structured files were deleted has crossed the seam: the
test is whether removing the log leaves any reader worse off about *state* rather than about
*reasoning*.

**What it never does.** It writes no byte of `trip-context.md` and no byte of
`outputs/event-status.md`; `trips/<slug>/trip-log.md` is the only path it writes, built from
`trip.slug` exactly as `E1` spelled it and never from a `--trip` value, which this verb does not
consume. It creates no file and no directory, overwrites and reorders no existing entry, dispatches
no agent, runs no script, and **never runs `/trip-record event`** — recording that a status changed
is that verb's act, and this one records why it changed. Neither the mode nor the destination is a
condition of it: its row reads `any` in both cells, and nothing here reads a mode as evidence or
infers a destination from which files exist.

## link <name> <person-id>

**Reads:** `trips/<slug>/travelers/` — the **directory-presence probe**, taken with `Read` on the directory path itself and read only to establish whether the directory is there; `trips/<slug>/travelers/<file>.md` — the file-existence probe that establishes the target is there, its frontmatter, read **before** it is written because a reference already present is echoed before it is replaced, and **its declared body fields**, read for the survey below and read before the write because the survey precedes it; `people/<person-id>.md` — the existence probe that establishes the reference **resolves before it is written**, the H1 line, read so the confirmation can name the person the id resolves to, and **its declared body fields**, read for that same survey; the **outgoing** record on the one branch where the file already carries a resolving `person:` naming a different id — its declared body fields alone, because the survey's pre-link side is composed against the record this trip references **now** rather than against an assumed absence; and `reference/data-model.md` § *The classification* and § *The lattice*, read live for each field's class and scope and **never re-authored here**, the same live-read `## profile <name>`'s collision check already takes for its own predicate. **The minimality the widened surface replaces is preserved in the one form that survives a survey: no value read here is written anywhere, on either side, by this verb.** Does not enumerate the store, and does not read `trip-context.md` in either direction. Dispatches no agent.

The reference verb. It writes the one frontmatter field that points this trip's traveler file at a
durable person record, and it writes nothing else anywhere.

**Filename.** The `<name>` is put through the same transform `## profile <name>` applies, cited
rather than restated, and the collision check there is not repeated here: this verb never creates a
traveler file, so it cannot reach the state that check exists to stop.

**Two probes, in `profile`'s order and for the identical reason.** `Read`
`trips/<slug>/travelers/` first: **absent → stop**, say so, and name `/trip-new <slug>`. Only then
`Read` `trips/<slug>/travelers/<file>.md`. The order is stated because the two conditions are
indistinguishable in the file probe's outcome, exactly as § `profile` sets out; a file probe running
first would take a create branch this verb does not have.

**This verb never creates the traveler file.** Absent → refuse, and name `/trip-record profile
<name>`. That verb's route 2 already writes the template unmodified and says in terms that a file of
unfilled placeholders is a legitimate state, so the create path exists and has exactly one home. A
`link` that minted a frontmatter-and-heading file would author a second shape of this class that no
schema check has seen, and would duplicate a write that is already someone's.

**The write is one frontmatter key.** `person: psn-<token>` on
`trips/<slug>/travelers/<traveler>.md`. **This is standing rule 2's `Edit` condition and not rule
7's append** — the target exists and only the named field's lines change, the named field being
`person:` and its line count moving 0 → 1 or 1 → 1. No new standing rule is owed here and none is
taken. `reference/schemas/traveler-profile.md` declares the field `optional` and it carries no
placeholder, so standing rule 3 is not engaged: **absence is a real state rather than a gap**, and
it is every existing traveler file's shipped condition.

**Refusals, in evaluation order.**

| Condition | What happens |
|---|---|
| `trips/<slug>/travelers/` absent | stop; name `/trip-new <slug>` |
| the traveler file absent | refuse and write nothing; name `/trip-record profile <name>` |
| `<person-id>` resolves to no record | **refuse and write nothing**, naming the store path. Writing it anyway would author a well-formed reference resolving to nothing, which `reference/data-model.md` types as **a defect** — and it would be a defect this command authored rather than found |
| the file already carries a `person:` naming a **different** id | **echo the outgoing value verbatim**, say that this **repoints** rather than adds, and require confirmation before writing |
| the file already carries that same id | say so and write nothing |

**The survey — run before the write, and derived from the lattice rather than enumerated.**
`reference/data-model.md` already computes, totally and deterministically, what the file and the
record each contribute to a composed field. This verb adds no rule to that computation. It runs it
**twice** — once for the state the file is in, once for the state the write would create — and
reports the difference, at a moment when nothing has been written.

- **The pre-link side is composed against the bearer state the file is actually in**, one of the
  seven that section declares, read from this file's own frontmatter and, where that frontmatter
  already carries a resolving reference, from the record it names. **It is not assumed to be the
  no-reference case.** A file carrying no `person:` key genuinely is that case, and its pre-link
  side is the traveller file field for field; a file being **repointed** already draws on the
  outgoing record, and so does its pre-link side.
- **The post-link side is composed with this invocation's record available**, which is the state
  the write would create and nothing else.

**A field enters the survey where either its composed value changes or its disposition changes, and
both limbs are load-bearing.** The data model defines two functions over a field, and they take
different arguments: the value function consumes the field's class, the trip-side value,
availability, the record-side value and the field's scope, while the report function consumes the
**un-collapsed** bearer state rather than the three-valued projection of it. Neither limb subsumes
the other. A sanctioned `DEFAULT` override composes to the trip's own value on **both** sides, so
it moves no value at all and is reached only by the disposition limb — and that population is the
one this card's first acceptance criterion is mostly about. A field this trip leaves unstated
carries no disposition, and on a repoint changes hands silently, so it is reached only by the value
limb.

**Deriving the survey this way is what makes it total over the repoint**, and the repoint is the
branch a fixed row set keyed to *"no reference, then one"* is silent on. The fourth refusal row
above ships that branch explicitly: both the outgoing and the incoming record are real, every field
this trip leaves unstated changes hands, and the needs union **loses every block the outgoing record
supplied**. *"Linking a person is never a destructive act"* is a property of arriving from **no**
reference; it is not a property of replacing one, and reading it as though it were is how that loss
stays invisible. Composing the pre-link side from the bearer state the file is actually in costs no
new rule and covers, without one: the repoint, a reference followed through a single merge hop, a
re-link of the same id — which changes nothing on either side and so surveys empty — and a
reference that today resolves to nothing, where this trip's own answers are being retained only
because the record side was never read.

**The adjudicable set is the part of that difference the operator can resolve either way**, and it
is selected by the field's own class rather than by a list kept in this section: a **slot**-scoped
person-class field this trip answers, whose claim the record's answer displaces; and a `DEFAULT`
override that differs from the record's value. **Everything else the survey reports is reported and
not adjudicated**, and the omission is deliberate rather than an oversight — a **block**-scoped
person-class field composes to a union and a union cannot contradict itself, an override equal to
the record's value costs one report line and nothing else, and a field this trip never answered is
inheriting rather than losing. Manufacturing a decision that has no losing branch is not thoroughness.

**One count is mandatory output rather than a courtesy.** Where this invocation replaces a resolving
reference, the survey names **how many** fields stop drawing on the outgoing record — **a count,
never the values**. This is `## unlink <name>`'s rule arriving at the other end of the same edge:
that verb must name how many fields stop being composed when a reference is removed, and a repoint
removes one in the same breath as it adds another. **The count line stays a magnitude, and render
rule 2 below does not widen it** — the two outputs have different subjects. The count is an
aggregate over every field losing the outgoing record, most of which this trip never answered and
so cannot adjudicate; the pair is rendered per **adjudicable** row. Where one field is in both
populations it takes its pair as a survey row, and the count line still carries no value.

**Three render rules, and they are what keep the survey a survey.** `reference/data-model.md`
§ *One-way* forbids not only a write to the store but a **solicitation** of one, and names the
prohibited shape verbatim: a prompt of the form *"the record says X, this trip says Y — promote?"*
emitted per diverging field, which leaves every resulting write human-confirmed while the record
drifts toward whatever the most recent trip said. This survey sits inside the one path that section
sanctions — an explicit act the operator initiated at the command surface — and these three are
what keep it there.

1. **No row carries a verb, an offer, or a suggested action.** The resolution verb is named once for
   the whole set, in this verb's own confirmation, and the paragraph below that names it is
   unchanged by the survey rather than repeated inside it.
2. **The survey renders the pair of values in disagreement, for each adjudicable field, and that
   pair reaches the operator and nothing else.** What the gate asks is whether to link, and a field
   label alone does not answer it: *Passport* says **where** the two sources disagree without saying
   **what** the disagreement is, and the two branches of this decision differ precisely in which
   value the trip ends up planning on. **The pair is the pre-link composed value and the post-link
   composed value**, taken from the two compositions this survey already runs rather than from the
   file and the record directly. On a file carrying no reference those are exactly the file's value
   and the record's value; on a repoint they are the outgoing record's and the incoming record's,
   which is what keeps the pair total over the same branch the adjudicable set is derived to cover.
   A side that is unstated renders as the model's own `UNKNOWN` rather than as a blank or a second
   minted sentinel.

   **The pair is never written into the persisted report.** `reference/data-model.md` § *The report
   — where it lands, and what it never says* forbids restating conflicting values, and its subject
   is **the report**, which that same section lands in the `## Update signals [DERIVED]` block of
   `outputs/traveler-model.md`. Each of its three grounds is a property of that persisted artifact:
   the publish guard matches a label prefix against files, an erasure reaches a copy by address, and
   *link, don't copy* is about a value acquiring a second durable home. **A rendered confirmation
   acquires no address, is scanned by no guard, and is a copy of nothing** — and this verb writes no
   report at all, its whole on-disk effect being one frontmatter line. That report goes on naming
   fields without their values, and nothing here changes what the enrichment agent writes into it.
   Standing rule 9(d) requires the echoed outgoing → incoming pair at exactly this surface, and
   `## promote <name> <field-label>` echoes the same pair for one field at the moment of that one
   write. **The two rules govern different surfaces, and both hold as written.**

   **Rendering the values does not make this a solicitation, and rule 1 is what keeps it from
   becoming one.** The shape § *One-way* names is the value pair **carrying an offer** — the form
   *"the record says X, this trip says Y; promote?"* — emitted per diverging field by a composition
   pass. The offer is the load-bearing half of that prohibition; rule 1 forbids it and is unchanged,
   rule 3 denies the repetition, and § *One-way* names the command surface as the one place a
   promotion is legitimately initiated. **The field label is separated from its values by a dash
   rather than a colon**, so no rendered line mints the `Passport:` shape the publish selector
   matches — which costs nothing here, and keeps a line pasted elsewhere from arriving as a value
   that selector was built to catch.
3. **Nothing schedules this.** It runs once, on a token the operator typed. No pass, no synthesis
   and no enrichment emits it, and the drift § *One-way* describes needs a repeating prompt this
   verb does not have.

**What this verb's reconciliation writes, stated as a prohibition in both directions, because the
tempting move is the opposite one on each side.**

> **This verb's reconciliation reads both records and writes neither, and it performs no resolution
> of its own in either direction.** It takes no licence from standing rule 9, names no path under
> `people/`, and has no branch that reaches one: every record-side resolution it surfaces is
> executed by `## promote <name> <field-label>`, one field per invocation, as a separate act the
> operator types. **And it does not perform the trip-side removal either.** Where the record's
> answer is the one to keep, the survey names the equivalence class — delete the line, blank it,
> or write a single em dash — **and does not do it**, which is the posture `promote` already ships
> for the identical act one field at a time. **A batched apply is not a convenience this verb
> withholds.** Store-ward it is a write with no sanctioned tool shape, because standing rule 9's
> conditions are conjunctive and fix the granularity at one named field with one echoed pair, and
> widening that is an amendment to the standing clause under the Extension rule rather than a
> feature of this section. Trip-ward the rule 9 argument does not reach at all — that rule bounds
> only writes outside `trips/<slug>/` — and the bar is the sharper one instead: a multi-field
> deletion in a human-authored, git-ignored tree, where a wrong deletion is recoverable from
> nothing while leaving a line costs one report line per pass.

**The property this protects, cited as what was ratified rather than as a mechanism.**
`reference/adr/ADR-006-third-party-data-capture.md` ratifies **attribution correctness** — a
constraint must reach the planner *once*, attached to the right person, and **must not duplicate
when that person later files their own profile**. That is a property of the outcome. **The record
prescribes no merge-and-drop mechanism, and no rule of it names one**, so a design that cited one
would be resting on a sentence that is not there. This verb satisfies the property the way the rest
of this command already does: by performing no merge at all, in either direction, and by leaving
every resolution a separately typed, individually confirmed act.

**Confirmation posture: CHEAP where the survey is empty, and a gate where it is not.** Where the
survey finds nothing, name the record the id resolved to — the id and its display name — and
write, exactly as this verb has always done. The act is reversible in one step by `/trip-record
unlink`, and confirmation weight tracks the tier rather than being uniform. **Two branches confirm,
and they confirm for different reasons.** The **repoint** confirms because it replaces a resolved
reference whose outgoing value is not otherwise recoverable — the same reason `.publish-slug` and
`mode` echo before writing. **A non-empty survey confirms because the gate is what makes abandoning
free**: it is placed **before** the write rather than after it, so declining writes nothing, on
either side, and both files are byte-identical to what they were. The reason is not reversibility,
which `unlink` already supplies — it is that a resolving reference changes which source a field
composes from, and a verb that wrote first would have moved that before the operator saw it.

**The gated branch refuses a non-interactive run**, on `promote`'s stated ground that a confirmation
nobody can give is not a confirmation. **The clean branch does not refuse**, and that split is the
whole of the compatibility guarantee: a traveller file that surveys empty takes the posture this
verb shipped, so nothing that runs today acquires a gate.

**After a confirmed write, this verb re-reads the frontmatter and says whether `person:` landed.**
It is one read the verb already holds, and it costs no rule. The gate moved consent in front of the
write, which leaves exactly one step that can still fail after the operator has agreed to it — and
without the read-back a failed write is indistinguishable from a successful one, since the survey
this verb just rendered describes the state it was **going** to create. Report the observed
post-state, never the intended one.

**What the confirmation also says, once, and never per field.** That this trip's own answers stay
trip-local, and that `/trip-record promote` is how the operator makes one of them durable. **This is
the only place in this command where that verb is named as an offer**, and it is named at a moment
the operator initiated. No rendered report pairs a field with an invitation to promote it — see
§ `promote` below, where the prohibition is stated and grounded.

**On-disk effect:** exactly one line added or changed inside one frontmatter fence in one file under
`trips/<slug>/`. **Nothing else.** No roster row, no `- **Total travelers:**`, no byte of
`trip-context.md`, no byte of the store, and no derived model — the model is the enrichment agent's,
reached by naming `/trip-record travelers` and **not running it**, exactly as `profile`'s edit route
does.

**Failure modes.** *(a)* An id taken from a stale note resolves to a **merge stub**. The reference is
valid and resolves through one redirect hop, so this verb accepts it and the confirmation names the
**survivor** rather than the stub — otherwise the operator cannot tell they linked through a merge.
*(b)* A `[THIRD-PARTY]` party member cannot be linked, and the bar is **structural rather than a
rule**: `## person <name>` creates no file anywhere for that entry class, so there is no
reference-bearing file to write to. Should a later slice ever declare a second, file-less bearer,
this stops being a consequence and becomes a rule someone has to write. *(c)* Two travelers on two
different trips pointing at one record is **not** a collision and is refused nowhere: two trips, one
person, which is the whole point of the store.

## unlink <name>

**Reads:** `trips/<slug>/travelers/` — the **directory-presence probe**; `trips/<slug>/travelers/<file>.md` — the file-existence probe and its frontmatter, read **before** the write because the outgoing reference is echoed verbatim before it is removed. **Reads no person record and probes no store path at all**, and that negative is deliberate rather than an omission: whether the record still exists is irrelevant to detaching from it, a probe would make this verb's behaviour depend on a state it does not change, and the absence of any store read is what lets this verb be the repair path for a reference that resolves to nothing. Dispatches no agent.

The detach verb. It removes the one frontmatter field `link` wrote, and **the person record is not
its subject in any sense** — it holds no store write, takes no store read, and has no path that
reaches one.

**What this verb says, and it is required output rather than a courtesy.** In its own render:
**the person record is untouched and still exists; every other trip that references it is
unaffected; and re-running `link` with the same id restores this trip's reference exactly.** It is
mandatory because the operator's mental model at that moment is *"I am removing this person"*, and
the corpus already carries the precedent for exactly this shape in `## group [<name>]` — *"**Never
delete anything under `travelers/`**"* stated in the verb whose act would otherwise read as a
deletion. **A third act is neither of these two:** taking someone off the trip is `group`'s, which
edits the roster and never this field; deleting the person is `## erase <person-id>`, which deletes
the record itself and rewrites every trip that referenced it.

**What it writes, stated as a prohibition because the tempting move is the opposite one.**

> **This verb removes the `person:` line and writes nothing else. It writes no `per-` token, no
> `[ERASED]` mark, no marker of any kind, and it never touches the display name, the title line, or
> the roster. Its post-state is byte-identical to a traveler file that never linked anyone.**

**Why a marker would be a defect rather than a convenience.** `reference/data-model.md` separates a
trip that never linked from a trip whose record was erased on a **conjunction**, not on this field:
absence of `person:` is *necessary but not sufficient*, and the second conjunct is positive
`[ERASED]` evidence that erasure produces by substituting the derived model's entry heading. Both
operations remove this line; only erasure leaves that witness. **A marker written here moves this
verb's post-state toward the erased one**, and if the two ever agree, an erasure reads as a trip that
never linked anyone — with **every composed value byte-identical either way**, so nothing
value-shaped detects it and the build stays green. The whole discriminator is carried by evidence
this verb must not write, which is why the rule is a prohibition and not a preference.

**Removal, not blanking, and the reason is sharper than the field being optional.** A `person:`
present with no value risks reading as **malformed**, which the bearer states type as a **defect** —
so a deliberate, reversible detach would surface as an error. Removal lands in the not-referencing
state, which is exactly what it is, and which is the shipped condition of every traveler file
written before the store existed.

**A second discriminator falls out of the tiers, and its direction is inverted on purpose.** This
verb **echoes the outgoing `person:` value verbatim** before removing it — the shape `group`, `mode`,
`destination` and `.publish-slug` all ship so that a change is reversible. An erasure must never echo
an erased value. **Same absence on disk, opposite interaction contracts**, and each falls out of its
own reversibility tier rather than being asserted.

**Confirmation posture: CHEAP — echo, then write, no gate.** Reversible in one step by `link` with
the echoed id.

**One consequence the render must state, because it is real and otherwise silent.** After a detach
the composed source loses the record's contribution: every field this trip left unstated stops
falling back to the record's answer, so **a need the record supplied stops reaching the plan**. The
verb names **how many** fields stop being composed — **a count, never the values**, because no
person-sourced content belongs in a rendered line — and names `/trip-record travelers` as the
reconcile step **without running it**.

**Failure modes.** *(a)* No `person:` present → say so and write nothing. This is **not** an error
state; it is the default condition of the class. *(b)* A malformed or unresolvable `person:` →
**this verb still succeeds.** It is the repair path for a reference that resolves to nothing, and it
needs no store read in order to be one. *(c)* Invoked in the belief that it removes the traveler from
the trip → the survival statement above, plus naming `/trip-record group`, is the whole mitigation,
and is why that statement is mandatory output rather than optional.

**What it never writes.** No byte of `trip-context.md` — not the roster, not `- **Total
travelers:**`. No byte under `people/`. No derived model. No file is created and none is deleted;
`trips/<slug>/travelers/<traveler>.md` is the only path it touches, built from `trip.slug` exactly as
`E1` spelled it and never from a `--trip` value, which this verb does not consume.

## promote <name> <field-label>

**Reads:** `trips/<slug>/travelers/<file>.md` — the `person:` reference and the named field's outgoing value, read **before** the write because both are echoed; `people/<person-id>.md` — the record that reference resolves to: its H1, so the confirmation names the person, **and the named field's line alone**, read before it is written because the outgoing record value is echoed for the operator to confirm against. **No other field of the record is read.** Does not enumerate the store. Dispatches no agent, and takes no `Bash(date:*)` use — see the timestamp negative below.

The promotion verb, and **the only verb of this command that writes outside `trips/<slug>/`.** It
moves one value the operator already wrote in this trip into the durable record this trip
references. **One traveler, one field, one invocation** — never in bulk, because silently choosing
between two allergy or two mobility values is the identity defect the store exists to prevent,
reproduced at field granularity, and a bulk promote makes that choice by omission. The echoed
outgoing → incoming pair also stops being readable at N fields.

**The standing rule this write is taken under is rule 9**, and this section discharges each of its
conditions by name: **(a)** the target path is `people/<person-id>.md`; **(b)** the record is
selected by the id already in the traveler file's `person:` field, which the operator supplied when
they linked — no name is matched and no search is run; **(c)** exactly one named body field changes,
no file is created or deleted and no field is removed; **(d)** the operator confirms against the
echoed outgoing → incoming pair below; **(e)** the value written is already in this trip, so this
verb **moves** a value and authors none.

**It is a distinct operation, not an exception, and writing it as one would be the defect.** Two
prohibitions bind the store and they bind different things. `reference/data-model.md` § *One-way*
bounds **what may cause a write** — no value flows trip-side into the record *as a consequence of
composition* — and this verb's cause is a token the operator typed, not a composition pass. The
store's own write rule bounds **who may write** — no agent authors a value in a record — and this
verb is not an agent. The enumeration of permitted **mechanical** writes, none of which authors a
value, does not reach it either: this verb authors nothing and is outside that enumeration's subject
matter. **Recording it as an exception would make the store's write rule read as negotiable**, which
is the property that rule exists to deny.

**What it writes.** Exactly **one body line** in `people/<person-id>.md`. The record's values are
body fields, so this verb never touches its frontmatter fence, never `merged-into:`, never the title
line, and never a field the record's own form does not declare.

**Refusals, in evaluation order. Every one of them writes nothing.**

| Condition | What happens |
|---|---|
| the traveler file carries no `person:` | refuse; name `/trip-record link` |
| the `person:` resolves to nothing | refuse; name `/trip-record unlink` as the repair path for a reference that resolves to nothing |
| the reference resolves to a **merge stub** | refuse and **name the survivor**. Writing through a stub writes a record that is already dead, and resolving the stub first is what keeps redirect depth at one hop |
| `<field-label>` is not a declared field of the record's own form | refuse, print the fields the form declares, and **offer no near-match**. § *When the token is not a verb of this command* is the shipped posture for this shape: a suggestion is a classification with a reflexive accept |
| `<field-label>` is the display name or the title line | **refuse, always, with no branch.** The normalized title line is the store's own collision key, so changing it changes the record's identity. That is a **rename**, not a promotion, and a rename is not a verb of this command |
| the trip-side value is not answered — absent, blank, a single em dash, or a surviving bracketed placeholder | refuse; there is nothing to promote. **`none` is an answer** and *is* promotable: the intake form makes it the one place `none` stands in for the em dash, and a promote that dropped it would turn a stated *"I have none"* into *"not asked yet"* in a durable, cross-trip record |
| the trip-side value carries `[THIRD-PARTY]` | refuse. Today no such value can reach this verb, because that entry class has no file to bear a reference — the rule is written anyway, because that consequence holds only while the bearer set stays as it is, and because a durable cross-trip record for a person who never asked for one is the exact artifact `ADR-006` refused |
| the run is non-interactive | refuse. The tier is MODERATE and the effect is durable and cross-trip; a confirmation nobody can give is not a confirmation |
| the record's value already equals the trip's | say so and write nothing — a redundant override, not a promotion |

**`[OPERATOR-PROVIDED]` is carried, not refused.** The store admits a value the operator relayed from
the person's own statement, so the mark is not a bar. It **travels with the value** into the record,
at field granularity, through the inline mark the value already carries — the provenance line
`profile` and `person` draw is preserved by that mechanism rather than by a second declaration, and
no record-level field is written to record it.

**On-disk effect:** exactly one body line in one file under `people/`. **The trip file is not
touched.** There is no fan-out: this session writes one trip's model and no other, and every other
trip that references the record absorbs the new value at its own next pass.

**A stated consequence, because it is real and silent.** After a promote, this trip's own line and
the record agree, so that field reports as a **redundant override** on every subsequent pass until
the operator removes the trip-side line. The verb **says so** and names the equivalence class —
delete the line, blank it, or write a single em dash — and **does not do it.** The line is
human-authored in a git-ignored tree, so a wrong deletion is recoverable from nothing, while leaving
it costs one report line per pass: reporting is CHEAP and deleting is IRREVERSIBLE, and that
asymmetry decides it.

**Timestamp negative.** This verb writes **no** last-written field and takes no `Bash(date:*)` use.
The record's dominant write path is a human editing it in an editor, which no command observes, so a
stamp maintained only here would read as authoritative while being routinely stale.

**Reversibility: MODERATE, confidence HIGH.** The outgoing record value is echoed before the write
and can be re-entered by hand. It is not CHEAP — the store is git-ignored, so there is no revert, and
the change is visible to every other trip referencing that record. It is not IRREVERSIBLE — nothing
is deleted, no record ceases to exist, and no identity is destroyed, which is the line separating
this verb from an erasure.

**This verb is never reached from a report, and that is a bound on every emission this command
makes.** No rendered line — in the `## Update signals` block, in any partition of it, or anywhere
else — pairs a field with an offer to promote it, and no pass suggests running this verb. A prompt
of the shape *"the record says X, this trip says Y — promote?"* would leave every resulting write
human-confirmed and would satisfy the store's no-agent-writes rule **literally** while defeating it
in practice, the record drifting toward whatever the most recent trip said one click at a time. The
shipped precedent for reporting without naming a command is already in `## travelers`, whose
changed-journey-facet class reports staleness and **names no command**. **Discovery is handled once,
non-field-specifically, in `link`'s own confirmation**, at a moment the operator initiated — one
naming, in one place, is not a solicitation.

## erase <person-id>

**Reads:** `people/<person-id>.md` — the file-existence probe and its frontmatter, to resolve the id and to detect a `merged-into:` stub; `people/` — the store listing, for the stub sweep in step 3 and for the collision check; `trips/` — the trip listing; `trips/*/travelers/*.md` — the frontmatter of every traveller file on every trip, which is the discovery step and the **only** way a trip enters this run's scope; and, for each trip that discovery resolved, that trip's own `trip-context.md`, `trip-log.md`, `travelers/` and `outputs/` in full, because a substitution has to read a value to replace it. **Reads no trip discovery did not resolve** — except the residual scan below, which reads other trips' bodies and **writes none of them**. Dispatches no agent.

The erasure verb. A person asked to be deleted; this removes their record and the values that were copied out of it, everywhere those copies can still be found. **It is the only irreversible operation on this command surface, and the only one that writes an archived trip.**

**What this verb is not.** It is not `unlink`, which detaches one trip from a record and leaves both intact. It is not `group`, which takes someone off a trip and never touches `travelers/`. Those two are reversible and this is not, and the render says which one is running before anything is written.

### Erasure substitutes; it never regenerates

**Every location below is rewritten by replacing a value, and nothing in this verb rebuilds an artifact from its sources.** That is not a stylistic preference — it is what makes the operation correct on the artifacts that hold the most occurrences.

Regeneration reaches only the `rebuilt-each-synthesis` classes. A display name also rests in `versioned` classes, which a re-synthesis does not clean but supersedes; in `accumulate-append` classes; and in `researched` classes, which `reference/data-architecture.md` § 4.4 declares hold *"independent state"* and are *"not a regenerable projection"*. **A design that regenerates the derived model has covered one class and left the rest standing.**

It is also what lets this verb run on an archived trip at all. `CLAUDE.md` § *Archived trips — what the freeze binds* freezes **derivation**, not bytes, and names erasure its one exception on exactly this ground: a redaction composes nothing, so there is nothing for the freeze to forbid. **On an archived trip, substitute is unconditional — the `regenerate` branch is never selected, and this verb never sets the `**Lifecycle:**` marker in either direction.**

### The token, and how it is minted

Erasure mints **one token per (person × trip)**, of the shape `per-<token>` where `<token>` is four lowercase hex digits.

**Per trip, never per person, and the cost is accepted.** A single token reused across a person's trips is a stable cross-trip pseudonym for someone who asked to be deleted, and it discloses that the same person travelled on each of them. The diagnostic loss — no run can prove two tombstones were once one person — is the point rather than a regression, and `reference/adr/ADR-012-people-library.md` records it as decided. **Do not correlate tokens across trips to sharpen a message.**

**The mint is collision-checked inside the trip, and re-mints on collision.** Before writing, derive the candidate's key the way the roster's own reconciler does — lowercase, then strip every character outside `[a-z0-9]`, giving `per<token>` — and compare it against the key of every other row of that trip's roster. On a match, mint again. Four hex digits give 65,536 values so this terminates immediately in practice, and it must exist anyway: a key collision makes the reconciler **stop for the whole trip** and report both names, which would print a surviving traveller's name beside an erased one.

**The token is safe to write into a rendered artifact, and nothing else here is.** `## per-<token> [ERASED]` parses as an ordinary entry: the publish guard's `clean()` strips a bracketed span as metadata before matching, `[ERASED]` is not a declared entry selector, and the literal `per` prefix survives the key strip so the key is never empty and never a reserved word.

> **`[ERASED]` must never be added to the `publish-contract-values` fence in `reference/data-architecture.md` § 5.6** — not as an `entry` selector, not as a `field` selector, at any scope. The tombstone is required in a `publish: bound` rendered artifact, so declaring it non-publishable would abort **every subsequent publish of every trip carrying one**, permanently and with no remedy short of un-erasing. The fence's fail-closed abort does not catch this, because the value is there legitimately. **This verb's correct action on § 5.6 is to change nothing, and that non-action is recorded here so a later reader does not read the omission as an oversight.**

### Step 1 — resolve, and refuse before anything else

`<person-id>` is the record's id. **A display name is never accepted**, and no name is matched, searched for or computed against the store.

| Condition | What happens |
|---|---|
| `<person-id>` is absent, or is not of the id's declared shape | refuse; print the shape and **offer no near-match** — a suggestion here is a classification with a reflexive accept, on an irreversible act |
| the id resolves to nothing | refuse; say the record does not exist and **name nothing else** — a "did you mean" over a store of real people is a disclosure |
| the id resolves to a **merge stub** | refuse and **name the survivor's id**. Erasing through a stub erases a record that is already dead and leaves the live one standing |
| the roster row of any resolved trip already carries `per-[0-9a-f]{4}` in column 1 | **`ALREADY-ERASED`** — see idempotency below. Not a refusal, and not a second erasure |
| `trips/` could not be listed, or the store could not be listed | refuse and write nothing. **An empty read is not an empty class**; a run that cannot enumerate its scope cannot bound its own reach |

**Idempotency keys on the authority, not on the model.** The predicate is **column 1 of that trip's roster row matching `per-[0-9a-f]{4}`**. Where it holds, the person is already erased on that trip: **mint nothing, write nothing, change zero bytes**, and emit `ALREADY-ERASED` on every row of that trip's receipt. Keying the predicate on the derived model instead would re-derive it from a stale projection and mint a *second* token, leaving the roster and the model disagreeing about which tombstone is current — on a trip with nothing left to reconcile them against.

### Step 2 — discovery, and the residue it cannot find

Discovery is a frontmatter read of `person:` over every `trips/*/travelers/*.md`, plus the `merged-into:` stubs that redirect to this record. **That is the whole of it, and it is a forward scan holding no persisted state**, so nothing can be stale relative to the files.

**Three residues discovery cannot reach by id, named here rather than hedged:**

| Residue | Why the id cannot find it | Disposition |
|---|---|---|
| a trip this person was **unlinked** from | `unlink` removes the reference and writes no marker, so that trip's post-state is byte-identical to a trip that never linked anyone. Its roster row, model entry and itinerary occurrences all remain, and **no edge connects them to this id** | **reported by the residual scan**, never rewritten; plus `--also-trip <slug>`, which adds a named trip to the run's scope |
| anything **published** | a repository, a Pages site, a cache, a clone. Re-publishing adds a commit; it removes none | **`UNREACHABLE`**, carrying the repo and the count |
| a value **promoted** into the record from a trip | the record is deleted, but the trip keeps the value it promoted | swept as ordinary trip data on a resolved trip; unreachable on one discovery did not resolve |

**`unlink` narrows this verb's reach, and that is a property of the two verbs rather than a defect in either.** The detach is CHEAP and reversible and writes no marker — correct for what it is — and the cost lands here. Say so in the render; do not imply the sweep was total.

### Step 3 — the reach table

**The receipt is total over this table.** Every **REACH** and every **REPORT** row emits **exactly one** row on every run. **OUT** rows emit none, and a caller checks "no row" against this list rather than inferring it from silence. A location can therefore only be missing from a receipt **by being missing from this table**, which moves "silently partial" from a failure the implementation can have to one only this table can have.

Outcome tokens are `ERASED` · `TOMBSTONED` · `UNREACHABLE` · `ALREADY-ERASED` · `n/a` · `UNDETERMINED`. **`UNDETERMINED` is never a pass.**

Locations are named **by path, never by an artifact-class ordinal.** That enumeration renumbered mid-milestone when a class was inserted ahead of the person store, and six ordinal citations in this milestone's own working notes came to name the wrong class — three of them across the in-model boundary. A path does not do that.

| # | Location | Disp. | What happens |
|---|---|---|---|
| **1** | `trip-context.md` § *Group* — **column 1 of the roster table** | REACH | substitute the cell. **The row survives.** Written **first** — see the ordering below |
| **2** | § *Group* roster — the traveller-file cell, **where that column exists** | REACH | repoint to `travelers/per-<token>.md`. Where the roster has no such column, emit **`n/a`** and name the column set. **Never a silent skip** |
| **3** | § *Group* roster — **any other cell of that person's row** | REACH | **substitute the whole cell** to `—`. These are free-text descriptions *of the person*, not join keys; replacing only the name inside one leaves a description of the erased person standing under a tombstone, which reads as anonymised when it is not |
| **4** | § *Group* — **the prose sub-fields**, whatever they are | REACH | substitute every occurrence of the subject token **between the `## Group` heading and the next `## ` heading**. Defined by **block extent, not by a field list**: nothing in the corpus enumerates these sub-fields, so any list written here is stale the first time an operator adds one |
| **5** | § *Group* — `- **Total travelers:**` | REACH | **unchanged.** Erasure does not reduce the party — the person travelled |
| **6** | § *Hard Constraints* / § *Dietary & Health* — `Applies to:` values | REACH | substitute the name. **Never empty the list** |
| **7** | the constraint **description text** | **REPORT** | **not swept.** A trip-level fact the person does not own. Name each constraint whose only `Applies to:` was the subject, by section and heading |
| **8** | `travelers/<traveler>.md` — the file | REACH | **rewritten to the token's stem** and the old path removed. See § *What the traveller file becomes* |
| **9** | `travelers/<traveler>.md` — frontmatter `person:` | REACH | **removed, not substituted.** The field is optional and its absence is that file's pre-existing normal state; the derived model cannot take removal, and the pairing is what makes the tombstoned-versus-dangling discriminator structural |
| **10** | `outputs/traveler-model.md` — the entry heading | REACH | substitute to `## per-<token> [ERASED]`, keeping any marks the entry already carried. **This is the only location that takes the `[ERASED]` mark** |
| **11** | `outputs/destination-shortlist.md` · `links-reference.md` · `venue-matrix.md` · `satisfaction-metrics.md` · `validation-report.md` · `cost-estimate.md` | REACH | substitute |
| **12** | `outputs/activities-list.md` · `food-list.md` · `nightlife-list.md` · `scheduling-framework.md` · `transport-brief.md` · targeted-research outputs · `change-summary.md` | REACH | **substitute only — never regenerate.** `accumulate-append`, and the research outputs hold independent state nothing upstream reconstructs |
| **13** | `outputs/final-itinerary.md` **and every** `final-itinerary-v<N>.md` | REACH | substitute in **every** version. A `versioned` class is only checkable across the whole glob |
| **14** | `outputs/event-status.md` | REACH | substitute. `persist-mutable`; **no row is deleted** — a removed row is a lost booking state, not a redaction |
| **15** | `trip-log.md` | REACH | substitute, **as a declared exception** to never re-opening a prior entry, and append one entry naming the act and **no value** |
| **16** | `engine-learnings.md` | **REPORT** | **cannot be swept — no declared writer, no lifecycle, no schema.** Emit `UNREACHABLE` with the path and the occurrence count |
| **17** | `outputs/<dest>-travel-site.html` and its secondary renders | REACH | delete. On an active trip the site is rebuilt from cleaned sources; on an archived trip it stays deleted, because the site was already taken offline when the trip was concluded |
| **18** | `trips/<slug>/.publish/`, including its own `.git` | REACH | remove the directory — the same act the publish script's takedown arm already performs |
| **19** | **the published repository, its Pages site, its git history, and every cache or clone** | **REPORT** | **structurally unreachable.** Emit `UNREACHABLE` carrying the repo, the commit count and the hand-off |
| **20** | `.passphrase` · `.publish-slug` · `outputs/.staticrypt.json` · `.published-itinerary` · `.change-confirmed` | OUT | control files, declared to hold no person data |
| **21** | this repository's own git history | OUT | the only path ever committed under `trips/` is its `README.md` |
| **22** | `examples/**` | OUT | **and must not be swept.** These are CI witnesses, and every profile in them ships *"Illustrative, sanitized example. Not a real person."* |
| **23** | `analysis/**` | **REPORT** | name the tree; do not sweep |
| **24** | the session transcript | **REPORT** | name it — and **never echo a subject value**, which is the act that would put one there |
| **25** | `.claude/worktrees/**` | OUT | git worktrees do not materialise ignored paths |
| **26** | **merge stub, subject as loser** — `people/<subject>.md` rewritten as a stub | REACH | **delete it.** It holds the subject's complete pre-merge body |
| **27** | **merge stub, subject as survivor** — a stub filed under *another* person's id | REACH | **redact the subject's pre-merge values from that stub**, preserving its redirect and the other person's data. **Never delete it** |
| **28** | **merge stub whose `merged-into:` names the deleted record** | REACH | repoint the redirect at the tombstone. **Never delete it** — redirect depth is pinned at one hop, so a deleted stub strands every referrer as `MALFORMED` rather than resolving |
| **29** | `people/<person-id>.md` — the record | REACH | **delete the file.** No stub is left in the store |

**The table carries 29 rows — 20 REACH, 5 REPORT and 4 OUT — numbered contiguously.** Rows 1–28 are the locations a copy of the person's data can reach; row 29 is the record itself and is written last. **That accounting is graded against the table by `scripts/test-artifact-schema.sh` arm `ER14`**, in every term and in both directions, because the receipt's totality rests on this table being the whole population and a bare numeral is the one part of that claim nothing was checking: a row can be added while the figure beside it stays, and a reader checking the figure then reads a confirmation where a widening happened. Re-state the accounting in the same commit as the row. `people/README.md` is **not** a location: it is a tracked signpost carrying no person data, and keeping it that way is a property of the store rather than a thing this verb checks.

### What the traveller file becomes

**The file is rewritten rather than field-edited, and the difference is the whole of the override sweep.** A trip-local override is a divergent copy of a durable field sitting in this file; a field-by-field pass would have to enumerate the durable field set and would silently miss the field no schema declares. Rewriting the file reaches every override, including ones nothing enumerates.

**Rewritten, not replaced with a marker.** The result is a file of the same declared shape, at stem `per-<token>`, in which:

- the title line and the name field carry **the token**;
- every answered personal value is the form's own **not-answered** sentinel — a single em dash — which is the state the composition rules already read as *unanswered*, so no reader needs to learn a new one;
- the **needs and desires, and the `Applies to:` link into the trip's constraints, survive verbatim**;
- the frontmatter carries **no `person:` key**;
- there is **no `[ERASED]` mark**. The bearer's tombstone-ness is carried structurally — a tombstone has no reference field left to dangle — and the positive mark lives in the derived model.

> **The need surviving is deliberate and is the second half of "never empty the list".** Erasure removes a person's identifying values, not the constraint structure the plan was built on. Dropping the need here, or emptying the `Applies to:` roster it points at, turns a concluded plan into one that grades as **compliant** while no longer carrying the need it was built around. That failure is silent, and it is worse than the leak it would be trading against.

### The order of writes, and why it is not tidiness

> **1.** row 1 — the roster cell. **2.** rows 2–4 — the rest of § *Group*. **3.** rows 8–9 — the traveller file and its reference field. **4.** row 6 — `Applies to:`. **5.** row 10 — the derived model. **6.** rows 11–15, 17 — the remaining derived and accumulated artifacts. **7.** row 18 — the publish staging clone. **8.** rows 26–29 — the store.

**The roster is written first because it is the name authority.** `agents/00-enrichment.md` § *Traveler identity* states it: the roster cell is the authoritative display name, the model heading and the traveller-file stem are **projections** of it, and where a projection disagrees *"the roster is right and the projection is the defect"* — the reconciler converges the projection onto the roster and is forbidden to repair by rewriting the roster.

**So the two orders are not two implementations of one design; one of them is the resurrection bug.** A run interrupted after step 1 leaves the roster tombstoned and the projections stale, and the next pass **converges them onto the tombstone** — the run is self-healing. A run interrupted under the reverse order leaves the projections tombstoned and the authority still carrying the name, and the next pass **restores the name into every projection it just cleaned**. A model-only erasure is not merely incomplete: it is undone *by instruction*.

**This is also what closes the reopen path.** `/trip-decommission reopen` returns the marker to `ACTIVE` and the next pass re-enumerates the party **from the roster**. The entry class with no traveller file — a party member whose needs the operator supplied — has no source-side substitution to carry it, so a roster left un-swept resurrects them on the first pass after a reopen. **The roster write is what makes the archived erasure hold.**

**The store is written last, for the same reason inverted.** While `people/<person-id>.md` exists a re-run can re-derive the whole sweep from it. Deleting it first strands a partial run with no source of truth for what it was erasing.

### The two-phase sweep, and why a name is not a safe pattern

**Phase A — structural loci.** Rows 1, 2, 3, 5, 6, 8, 9, 10, 26–29. Each is a named cell, heading, field or path, addressed **by position**. Phase A never pattern-matches a name; it rewrites a located slot.

**Phase B — bounded free-text.** Rows 4, 6, 11–15, 17. **Word-boundary, case-sensitive, and scoped to one trip directory per pass.**

> **Never repository-wide, and never case-folded.** A display name is frequently an ordinary English word. Measured on this repository's own working tree, one live four-character display name occurs **5 times inside its trip, 130 times across the repository, and 4,395 times case-folded** — and every one of those outside occurrences is legitimate prose. A repo-wide or case-insensitive replace does not fail loudly; it corrupts the corpus silently. `examples/**`, `analysis/**`, `agents/**`, `reference/**`, `scripts/**`, `templates/**` and the repository root are outside Phase B **by construction**, not by an exclusion list that a later path could slip past.

**Case-sensitivity is a decision with a stated cost.** A name written by hand in a different case inside a research list is missed. That miss is **detected rather than hidden**: the residual scan reports it as a candidate.

### The residual scan

**Run before Phase A rewrites anything**, and emitted as a distinct `CANDIDATES` block below the receipt.

It scans the trip roots discovery did **not** resolve for the subject's display name, word-boundary and case-sensitive, and reports **path and occurrence count only**. **It substitutes nothing there, ever.** This is what turns the unlink residue from "somewhere" into an enumerated list.

**They are candidates, not findings, and the distinction is measured rather than cautious.** A name match outside its own trip is weak evidence: the same measurement that forces Phase B's scope bound shows an ordinary-word name occurring 26 times outside its trip for every occurrence inside it. Reporting these as findings would train the operator to ignore the block.

### The confirmation

> **`erase <person-id>` → the dry-run reach report → the prompt names the record's display name and id → a typed confirmation of **the id** at a terminal → execute.**
>
> **There is no `--yes`. There is no non-interactive path. There is deliberately no flag to skip it.**

**The prompt echoes the display name; the typed token is the id.** Those are two separate halves and they answer two different failures.

**Echoing the name closes the mis-target.** An id is opaque: where two co-travellers on the same trips each hold a record, nothing in `psn-3c7e` distinguishes them, and an operator who transposed two ids at the shell would confirm the wrong erasure with no second signal. The prompt therefore names the record it is about to erase — display name **and** id — before it will accept anything. This is the standard shape for an irreversible operation: **show what is about to be destroyed, and require a token to proceed.**

**Typing the id, never the name, closes the other one.** The operator never types an erased value, so the confirmation does not build the habit of typing people's names at prompts, and no personal data enters the shell's history. That was the original objection to naming the subject here and it is preserved intact — what changed is that it was being answered by *withholding the name from the operator*, which pays for it with the one mis-targeting this gate cannot otherwise stop.

**On the transcript.** The name appears once, in the prompt, at a moment when the operator has just read a dry-run reach report for that person and has their record open. It is not new information at that point. Erasure substitutes the display name **in artifacts**; a terminal prompt is not an artifact, and treating it as one bought secrecy the operator did not need at a cost the person being erased would not have chosen.

`unlink` echoes its outgoing reference because it is reversible and the operator may want to re-link. This verb echoes its subject for the opposite reason — because it is not.

**What the gate catches, and what it still does not.** The echoed name catches a run aimed at the wrong **person** — the failure an id alone cannot see. The typed id catches a run aimed at the wrong **record** where two people share a display name, which a name alone cannot see. The two halves are complementary, and each covers the other's blind spot.

**What remains uncaught:** an operator who reads the echoed name, recognises it, and confirms anyway — a deliberate erasure of the intended person, which is the operation working. Beyond that, a record whose display name is itself wrong will echo the wrong name and confirm against a correct id; the reach report above the prompt is what narrows that, and it names paths and occurrence counts rather than people.

**Why the gate is stronger than the nearest precedent's.** The publish script's takedown arm types the *subject identifier* and accepts a flag to skip the prompt, because a deleted repository can be re-published. Its typed identifier would here be the person's name, and its escape hatch would be a scripted irreversible erasure. This verb takes instead the shape the script reserves for the confirmation it will not let anyone skip.

**The cost, stated rather than buried: erasure cannot be scripted, batched, or run in CI.** That is the correct trade for the one irreversible operation on this surface, and it is the trade the corpus already made for a reversible one.

### The receipt

One row per **REACH** and per **REPORT** location, every run: **location · disposition · outcome · occurrence count**, and for `UNREACHABLE` the concrete path or URL. **No row carries a value.** Then the `CANDIDATES` block, then the hand-off for row 19.

**A second run emits `ALREADY-ERASED` on every row and changes zero bytes.**

### The standing rule this write is taken under is rule 10

This section discharges each of its conditions by name. **(a)** every location written is a row of the table above, and the receipt is total over it; **(b)** every rewritten value becomes the minted token or the form's declared not-answered sentinel, and **no location is emptied** — rows 5 and 6 are the two that would otherwise be, and both are pinned; **(c)** Phase B is scoped to one trip directory, word-boundary and case-sensitive, and reaches no path outside it; **(d)** the operator types the record's id at a terminal, with no flag and no non-interactive path; **(e)** every location emits exactly one receipt row, including `n/a` for the absent roster column and `UNREACHABLE` for the four locations nothing local reaches.

**Rule 9 is untouched.** Its target derivation is taken unchanged and its operation class is not widened — erasure fails it on three counts, which is why rule 10 exists rather than an exception inside rule 9.

### What this verb must never converge with

`unlink` and this verb **both remove the `person:` line**, so field-absence alone discriminates nothing. The corpus separates a trip that never linked anyone from a trip whose person was erased on a **conjunction**: the field is gone **and** the derived model carries an entry keyed `per-[0-9a-f]{4}` and marked `[ERASED]`.

**Only this verb writes the second conjunct.** If this verb's post-state ever converges with the detach's — by dropping the roster tombstone, by removing the roster row, or by not marking the model entry — then a real erasure reads as a trip that never linked anyone, **every composed value is byte-identical either way, and nothing value-shaped detects it.** The build stays green while the detection is gone. The three properties that keep them apart are each checkable: the roster row **survives here and is removed by `group`**; the traveller-file stem is **the token here and the display name there**; and the model entry carries a mark that no other operation writes.

**Reversibility: IRREVERSIBLE, confidence HIGH.** `trips/` and `people/` are git-ignored, so there is no earlier version to restore from; the `researched` artifacts hold independent state nothing upstream reconstructs; and the published surface is beyond every local act. Rollback is not merely expensive here — it does not exist, and the confirmation is shaped around that rather than around the size of the change.
