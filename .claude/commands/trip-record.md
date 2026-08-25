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
`sh`. That denial is the **enforced** half of the standing clause below — `allowed-tools` is a
turn-scoped pre-approval grant and enforces nothing.

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
```

The block above is this file's contract declaration. The requirement table sits **inside** it
because the fence the contract publishes lists that table as one of the block's own fields, so the
table-inside form is the rendering the canonical states. The cost is that the table does not render
as markdown, and it is accepted: this is a declaration read by a model and by a parser, not a table
read by a browser. The info string names the block, so it can be located by the same primitive that
locates the canonical.

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

**The shape of a table row.**

| Cell | Rule |
|---|---|
| `verb` | the **bare token**, exactly as a user types it, single whitespace-delimited, ASCII-case-foldable — the token alone, never the token followed by an argument placeholder. § *Selecting the verb* matches the typed token against this column by exact string equality, so a placeholder in the cell makes the verb unmatchable |
| `lifecycle` | `ACTIVE` on every row of this slice. `ANY` or `ARCHIVED` only where the verb has a stated reason to serve an archived trip, and a write verb does not |
| `mode` | `any` on every row of this slice |
| `destination` | `any` on every row of this slice. **No row of this file may gate on a decided destination.** A freshly scaffolded trip has no decided destination whatever its mode, so a destination-gated verb would refuse on a trip the taxonomy says runs the full pipeline |
| `depth` | `G8` on every row, rendered **bare**. A depth cell elsewhere in the surface tolerates a code span, but this table sits inside a fence where backticks are literal, so it follows the in-fence convention `/trip-new` already ships. The header's `contract-depth` must equal the maximum depth cell in this file, and the contract fixes this command at `G8` |

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
| one requirement-table row per verb it implements, `ACTIVE / any / any / G8`, its `verb` cell a bare token; a `**Reads:**` line at the head of each `## <verb>` section it appends, per § *What the blocks above are*; one `## <verb>` section per row, appended in Zone B below every section already there; `allowed-tools` additions only where a verb needs one and its own design names that verb; and, for a verb that changes a persist-mutable file, that file's own no-overwrite shape — read the file, change the named row, never regenerate it — stated inside that verb's own section | anything in Zone A except those table rows and that `allowed-tools` union; the header block's declaration lines; the evidence blocks; the table's five columns; § *What the blocks above are*; the refusal branches; and the standing clause, except under the Extension rule stated there |

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
sections rather than a second list that can disagree with them. `/trip` states its ceiling as a
closed list of paths, stated for the file rather than per verb; this file's read scope is the union
of what its verb sections name, and that union grows as later slices land, so the same rendering
would be wrong inside a single merge.

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
   wants, name `/trip-publish`, **which does not exist at this revision**, and stop; do not reach
   the script from here.
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

Every row of that table declares `lifecycle: ACTIVE` and constrains neither `mode` nor
`destination`, so the `REFUSE` reachable in this file at this revision is an archived trip: say that
the trip is archived, and name `/trip-decommission`, **which does not exist at this revision**.

## profile <name>

**Reads:** `trips/<slug>/travelers/<file>.md` — the existence probe that selects create from edit, and the outgoing content on the edit route; `templates/traveler-intake.template.md` — the interview script on route 1 and the copy source on route 2. Does not read `trip-context.md`, in either direction.

The traveler-document verb. It creates a profile that does not exist and edits one that does, and
the branch is selected by a probe rather than by a tool grant.

**Filename.** Reuse the transform `/trip-new` already applies to the roster's `Traveler file` cell,
verbatim, and invent no second rule: lowercase the name, replace every run of characters outside
`A-Za-z0-9._-` with a single `-`, then trim leading and trailing `-`. The output is a single path
segment by construction, because that charset excludes `/` and `\`. The `Person` name is carried
**verbatim**; only the filename is transformed. **An empty result is refused** — say which name
needs a filename, and stop.

**The existence probe selects the branch.** `Read` `trips/<slug>/travelers/<file>.md`. Readable →
**edit**. Not readable → **create**. This probe is the control that makes standing rule 2 operative;
the tool grants are pre-approval and enforce nothing.

**If `travelers/` itself is absent** — a trip scaffolded before that directory was part of the
scaffold — stop, say so, and name `/trip-new <slug>`, whose Resume branch is the declared repair
path for exactly this. No directory-creating grant is taken and this verb creates no directory.

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

**Reads:** nothing of its own. Dispatches `agents/00-enrichment.md` in the same reconciler role `travelers` dispatches, which reads `trips/<slug>/travelers/*.md` and `trips/<slug>/trip-context.md` and writes `outputs/traveler-model.md` alone.

The operator-provided third-party case: a party member who will never file a profile, whose needs
the operator supplies.

**Creates no file, anywhere** — no `travelers/<name>.md`, no proxy profile, no consent attestation,
no durable artifact of any kind. `ADR-006` rejected the proxy profile precisely because it would
create a durable identity artifact for a person who never asked for one.

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
which is `[DERIVED]` and rebuilt from source files — and by design there is no source file for this
person. Re-running this verb re-supplies the needs, so if a later reconcile drops the entry, this
verb restores it.

## travelers

**Reads:** nothing of its own. Dispatches `agents/00-enrichment.md` in its reconciler role, which reads `trips/<slug>/travelers/*.md` and `trips/<slug>/trip-context.md` and writes `outputs/traveler-model.md` alone — never the `[ENRICH]` research role.

**Enrichment alone, in its reconciler role.** The dispatch names the agent prompt, the role, and the
one file that role writes, exactly as the `Reads:` line above states them; standing rule 6 is what
obliges that naming.

**The research role is not run.** That role needs web tools this command does not grant, and running
it would write `[ENRICH]` fields into `trip-context.md`, **of which this slice writes zero bytes.**
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
legitimately exceeds the roster's rows is a real state and is never reported as a defect.

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
   is the selector, read from the file rather than listed here — and **name no command for the
   refresh**, saying plainly that no verb of this surface refreshes them at this revision. Reporting
   staleness while naming nothing is the shape § *Write ownership* already fixes for a block whose
   writer does not exist.
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
writes no destination in any mode, so a freshly scaffolded trip carries `trip.destination` as
`UNDECIDED` whatever its mode — which is why `/trip-new` names this verb from its `DISCOVERY` branch
as well as its `IDEATION` one.

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
the mode anyway**. `IDEATION` is the one mode § *Modes* describes as nothing decided, so the test
needs no ordering over the set and invents none. **This is a report and not a gate.** This verb's
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
  ASCII-case-folded. Present → **edit that row**. Absent → **add a row**. The probe runs before
  either write tool is reached; `allowed-tools` is a pre-approval grant and enforces nothing, which
  is the same control `profile` rests on.

**Adding a row.** `Person` carries the name **verbatim**. `Traveler file` is `travelers/<file>.md`,
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

**`- **Total travelers:**` reconciliation — a decision over the states the field can be in, never a
silent adjustment.** The rules are `/trip-new`'s, carried forward: a stated total wins where one is
given, the count of names otherwise, the two may legitimately differ, and **the roster is never
padded with placeholder rows to reach a total**, because a `[Name]` row is indistinguishable from a
real traveler with a missing profile.

| State of the field after the change | Disposition |
|---|---|
| a bracketed placeholder | write the roster's row count |
| the user stated a total in this act | write the stated total |
| a number greater than or equal to the row count | leave it — the named person was already inside the count |
| a number less than the row count | say so and **ask**; write neither value until the user settles it |
| a removal, and the field equalled the pre-removal row count | decrement it |
| a removal, and the field exceeded that count | leave it, and say the unnamed remainder grew by one |

**The traveler denominator is the roster and `- **Total travelers:**`, never a file count under
`travelers/`.** That directory ships empty and stays empty until a profile is filled, so a file
count reads a real group as zero; the roster is the input `agents/00-enrichment.md`'s `PROFILE
MISSING` branch, `### Per-Traveler Planning Days [DERIVED]` and the satisfaction layer all read. **A
`- **Total travelers:**` that legitimately exceeds the roster's rows is a real state and is never
reported as a defect.**

**A `[THIRD-PARTY]` party member gets no roster row, and is counted in `- **Total travelers:**`.**
`## Group` and every constraint's `Applies to:` line are publish-bound, and `CLAUDE.md` states that
a `[THIRD-PARTY]` value never escalates into `trip-context.md` and must not appear in any
publish-bound artifact in attributed or anonymized form. A roster row would also assert a
`travelers/<name>.md` that `ADR-006` forbids ever existing. The **count** is a different thing: it
is not attributed data about a person, the party denominator has to be honest for needs-compliance
and desire-coverage to have anything to grade against, and a total exceeding the roster is already a
legitimate state. `person` records such a member's needs and creates no file anywhere; this verb
records roster rows in `trip-context.md`. **They do not meet**, and the difference between the total
and the rows is never reported as a defect to reconcile.

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
| `**Lifecycle:**` | `/trip-decommission`'s, **which does not exist at this revision**, so nothing writes that field until it ships and an absent line is the contract's declared default rather than a gap to fill. This verb never writes it |
| `## Destination`, `## Mode` and `## Group` | a sibling verb of this same command — name it and stop |
| `## Locked Elements`, `## Current Itinerary Status`, and every other untagged field | **this verb writes it** |

Ownership follows the block and not the command: this verb does not write `## Destination` or
`Current mode` merely because they sit in the same file under the same command. One block with more
than one writer is the seam this partition exists to avoid, and it would let a mode reach the file
without the evidence § *Write ownership* binds to it.

**3 — Ambiguity.** A statement that does not resolve to exactly one block: **ask once, naming the
candidate blocks.** **Never write to more than one block** to be safe. And **never create a new `##`
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
- **A new unit is appended** under the block's own repeat unit — a `### [Constraint Name]` block
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
**before** anything is published. Standing rule 1 and every entry of `disallowed-tools` are
untouched and unrelaxed.

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
publishing itself is what the user wants, name `/trip-publish`, **which does not exist at this
revision**, and stop; where taking a site down is what they want, name `/trip-decommission`, **which
does not exist at this revision**, and stop.

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
   `/trip-new` either, so there is no repair path to name here. Name the path, say that it appears
   when the plan is first synthesised, and stop.
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
**`/trip replan`** and **do not run it.**

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
  next planning pass. Name **`/trip replan`** and **do not run it.** Name **`/trip-record log`** as
  well, and do not run it: *why* a booking fell through is exactly what the log carries, and the
  status table has no field for it.
- *Does not oblige:* it does not dispatch the hub, does not re-run an agent, and does not patch the
  itinerary. **It does not write `Current mode`.** The regression triggers the *recovery*; the mode
  value is a separate fact resting on a separate evidence class, and inside this command
  **`/trip-record mode`** is its writer — named here, not run. It also does not delete the row:
  deletion is predicated on the event being removed from the itinerary, which this verb neither
  performs nor observes, and a row deleted while its event remains is worse than the ghost row the
  rule forbids. It touches no `Day`, `Event`, `Requires booking?` or `Notes` cell.

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

**The boundary that keeps the log from becoming a rival source.** A constraint that surfaced in a
session is recorded here as **a decision and its reasoning** — what was chosen, and why. The
constraint itself belongs to `trip-context.md` § *Hard Constraints*, which is **`/trip-record
fact`**'s: name it, and **do not run it.** This is link-don't-copy at the one seam where a session
entry could quietly become a second source — the log carries what `trip-context.md` cannot, which is
why a choice was made, and never the fact itself.

**What it never does.** It writes no byte of `trip-context.md` and no byte of
`outputs/event-status.md`; `trips/<slug>/trip-log.md` is the only path it writes, built from
`trip.slug` exactly as `E1` spelled it and never from a `--trip` value, which this verb does not
consume. It creates no file and no directory, overwrites and reorders no existing entry, dispatches
no agent, runs no script, and **never runs `/trip-record event`** — recording that a status changed
is that verb's act, and this one records why it changed. Neither the mode nor the destination is a
condition of it: its row reads `any` in both cells, and nothing here reads a mode as evidence or
infers a destination from which files exist.
