---
description: Record what you know about a trip — traveler profiles, third-party needs, and the enrichment reconcile. Writes the trip's own files; never publishes.
argument-hint: <verb> [--trip <slug>] [args...]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Write, Edit, Task
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), NotebookEdit]
---

# /trip-record

`/trip-record <verb> [--trip <slug>] [verb args...]`

The verb is the one the user typed. Nothing in this file supplies a verb they did not type, and
nothing in it reads the wording of the request to decide one.

**The frontmatter above, and what it is held for.** Each grant is held for a use a section below
names, per `ADR-007` §2 bound 2: `Bash(ls:*)` for the listing block and `Bash(grep:*)` for the
record block, and nothing else in this file uses either; `Read` for the traveler profile this
command probes for and edits and for the intake template it copies from; `Write` for a profile
that does not exist; `Edit` for a named field in a profile that does; `Task` for the enrichment
dispatch the verbs below name. No directory-creating grant is taken, and no verb of this command
creates a directory.

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
