---
description: Take a trip's site offline, archive a concluded trip, or reopen an archived one. Never deletes trip content.
argument-hint: <verb> [--trip <slug>]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(date:*), Bash(scripts/publish-trip-site.sh unpublish:*), Read, Edit
disallowed-tools: [Bash(scripts/publish-trip-site.sh publish:*), Bash(scripts/publish-trip-site.sh update:*), Bash(scripts/publish-trip-site.sh rotate:*), Bash(scripts/publish-trip-site.sh list:*), Bash(scripts/publish-trip-site.sh status:*), Bash(bash:*), Bash(sh:*), Write, NotebookEdit]
---

# /trip-decommission

`/trip-decommission <verb> [--trip <slug>]`

The verb is the one the user typed. Nothing in this file supplies a verb they did not type, and
nothing in it reads the wording of the request to decide one.

**The frontmatter above, and what each grant is held for.** Every grant is held for a use a section
below names, per `ADR-007` §2 bound 2, and no grant is taken without one.

| Grant | The use that holds it |
|---|---|
| `Bash(ls:*)` | the listing block below |
| `Bash(grep:*)` | the record block below, which reads the lifecycle, the mode and the destination by value |
| `Bash(date:*)` | `archive`'s closing log entry is dated from a `date +%F` tool call **in the body**, never as a further pre-execution block — the shipped convention `/trip-new` and `/trip-record log` already take, and required here because the header block below fixes how many pre-execution blocks this file carries and it already carries all of them |
| `Bash(scripts/publish-trip-site.sh unpublish:*)` | `temporary` and `archive` invoke the `unpublish` arm, with the pages-only flag, both fixed in this file. **The grant is the arm, not the script** — `ADR-007` §1 is one authorization per function, and a script-wide grant would authorize every arm of the dispatch table at once |
| `Read` | `archive` and `reopen` read `trip-context.md` to locate the lifecycle marker line or its anchor; `archive` reads `trip-log.md` to confirm the append target exists |
| `Edit` | `archive` inserts the marker line and appends the closing entry; `reopen` changes the marker's value |

**The denials, and what each one establishes — which is narrower than "enforced".**
`allowed-tools` is a turn-scoped pre-approval grant and enforces nothing. `disallowed-tools`
**removes the named tools from the pool**, which is a real restriction and the only control this file
holds over which tools a turn may call — but it is turn-scoped in the same way, and `ADR-007`'s
Context names a **permission-settings deny rule** as what durable blocking would need, which this
repo does not ship. **It is not the only control this file relies on**, and saying it was would be
falsified further down this same file: § *The closing entry* and § *Deleting the trip's public repo*
both rest on the push-time contract guard, and `temporary` and the hand-off both rest on the
script's own scope check and typed confirmation. **So every denial below is read as what its entry
names, never as a general property of the action that entry is about.**

- **Every publish-script arm this command does not own is denied by name** — `publish`, `update`,
  `rotate`, `list` and its `status` alias. `ADR-007` §1 is **one authorization per function**, so the
  grant above is the `unpublish` arm rather than the script: a script-wide grant would authorize the
  whole dispatch table at once, which is the privilege union that ADR rejects. **The arms are denied
  individually rather than described**, because a boundary carried in prose is asserted while a
  `disallowed-tools` entry removes the named tool from the pool.
- **What an entry names is a command pattern, and the path in it is part of the name — so the
  spelling is load-bearing, and here is the residual.** All five denials, and the `unpublish` grant,
  spell the script **repo-relative**. This file addresses repo paths in its two pre-execution blocks
  in the **absolute** form, through `${CLAUDE_PROJECT_DIR}` — so both spellings of a repo path live
  in this file, and for the script entries they are **not interchangeable**. For `Bash(ls:*)` and
  `Bash(grep:*)` the path is only an argument and the entry names the binary, so the form does not
  matter there; for the script entries **the path *is* the name**, and nothing in this repo
  establishes that an entry naming one spelling reaches an invocation written in the other. **Every
  invocation this file makes is written repo-relative, exactly as the entries spell it** — the
  `temporary` invocation, `archive` step 2 and the hand-off all do, and a later slice must not depart
  from it. **That pinning is a rule this file follows; the entries cover the spelling they name and
  no more.** The same pattern-naming governs `allowed-tools`, so an invocation in the other spelling
  would sit outside the **grant** as well — not thereby forbidden, since a tool left off that list
  routes through the usual permission settings, but not pre-approved either.
- `Bash(bash:*)`, `Bash(sh:*)` — denied so the two interpreters that would most obviously re-enter
  the script under a different first token are removed from the pool. **What this pair establishes is
  its two names and no more, and it is not what closes the arms** — the per-arm entries do that, and
  each is listed. **The wrapper route is wider than the pair, and the remainder is a named residual.**
  An alias is expanded after the command text is matched, so a command-prefix entry never sees it;
  and a third interpreter, or `env`, `xargs`, `command`, or a generated command line whose first
  token is neither `bash` nor `sh`, is a name these two entries do not carry. **Standing rule 2
  covers the remainder, and it covers it as a rule this file follows rather than as a property these
  entries guarantee.**

**What the frontmatter does *not* enforce, stated plainly rather than claimed.** `unpublish` is one
arm and this command owns one **form** of it — the pages-only takedown. **A per-arm denial cannot
express a flag's presence inside an arm it grants**, so *never passes `--yes`* and *never takes the
deleting default* are **rules this file follows, not properties the frontmatter guarantees.** They
rest on the fixed invocation in each verb section and on the argument string never being forwarded.
The mechanical check that would grade them reads the command directory for publish-flag literals and
does not exist at this revision; until it does, this residual is named rather than covered. **No
prohibition in this file is justified by what the frontmatter omits — omission is not prohibition.**
- `Write`, `NotebookEdit` — **what these two entries establish is that the two whole-file write
  primitives are out of the pool, and that is all they establish.** **This command creates no file
  and no directory** and overwrites none: every path it touches must already exist, and a missing one
  is a stop, never a create. That conduct serves `ADR-007` §2 bound 5, whose class is **IRREVERSIBLE**
  because `trips/` is git-ignored and carries no history. **The entries do not close creation or
  overwriting in general** — standing rule 6 names what is left over and why. **The bound is met by
  rule; these two entries only narrow what the rule has to carry.**

**`Read` and `Edit` are file-general and the frontmatter does not bound them, so the bound is a rule
this file follows.** `Read` could reach `trips/<slug>/.passphrase`; `Edit` could reach a file
`temporary` disclaims. That neither happens is stated per verb, in each section's `**Reads:**` line
and in its *Never* paragraph, exactly as `ADR-007` requires: a command's conduct is written as a rule
the command follows, never as a property its frontmatter guarantees. **Nothing in this file argues
that this command cannot do something because a grant is absent, and nothing argues it may because a
grant is present.**

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
| temporary | ACTIVE | any | any | G8 |
| archive | ACTIVE | any | any | G8 |
| reopen | ARCHIVED | any | any | G8 |
```

The block above is this file's contract declaration. The requirement table sits **inside** it
because the fence the contract publishes lists that table as one of the block's own fields, so the
table-inside form is the rendering the canonical states.

**Frozen.** The citation line, byte-for-byte. `contract-depth: G8` as a **bare** token on its own
line — a code-span rendering of that line is graded as an *absent* declaration, so the tolerance for
a code span belongs to a depth **cell** and never to this line. `population-role: RESOLVE`. The
fence tag. The table's five columns, their order, and their header row.

**Why the cells read as they do, since three of them carry the whole mechanism of this command.**

- **`lifecycle` is declared only on `reopen`.** `temporary` and `archive` leave that cell at G7's
  `ACTIVE` default. This is the whole mechanism by which an archived trip stops resolving as active
  for **every existing and every future verb of every command**, with no edit to the contract and no
  edit to any sibling file: a verb that declares `ANY` keeps working, and a verb that leaves the cell
  defaulted refuses. Nothing else has to change for that to hold.
- **`mode` and `destination` read `any`, and `any` is load-bearing here rather than lazy.** A cell
  reading `any` admits the non-nominal state its own gate can yield — `UNSET` from G5, `UNDECIDED`
  from G6. Both are needed: the most common non-post-trip archive is an abandoned IDEATION trip
  whose destination was never decided and whose mode may never have been set, and a row naming
  values would make this command refuse exactly the trip it exists to conclude. `reopen` reads `any`
  for the same reason, and for one more — the trip whose mode is `UNSET` is the one a reopen is most
  likely to precede.
- **A verb absent from the table is `REFUSE`, never `RUN`, so the set is closed.** In particular
  **no row of the table above carries a `delete` verb**: the repo delete is `ADR-007` §4 row 10,
  `EXCLUDED` for `ADR-007 §2`, and it reaches the operator as a hand-off render rather than as a
  verb. A typed `delete` therefore lands in § *When the token is not a verb of this command*.

**Extension point.** One table row per verb a later slice implements, appended below the rows
already there, with that verb's own `## <verb>` section.

## What the blocks above are

The ladder the header cites is stated in one place and is not restated here. The blocks above have
already run, and **their output is the whole of the trip state this file resolves against** — the
population from the listing block, and the lifecycle, the mode and the destination by value from the
record block. No verb re-runs either block, and no verb re-derives what they already carry.

**The header block above fixes how many pre-execution blocks this file carries, and it already
carries all of them** — no verb and no later slice adds another. A block this file does not already
carry is a conformance failure on push whatever a verb section says, and a date a verb needs is
taken as a tool call in its own body, the way `/trip-new` and `/trip-record log` take theirs.

**The read-scope ceiling is a principle, not a path list: every verb reads exactly what its own
`**Reads:**` line names, and nothing else.** Silence is a prohibition here rather than a gap — a read
this file performs that no section names is out of scope, whether or not a list would have permitted
it. Each `## <verb>` section opens with that line, before any procedure, and a read a reader would
expect and the verb does **not** perform is stated as a negative with its reason, so the next author
does not add it back.

## Standing clause — binding every verb of this command, present and future

This clause sits outside every verb section on purpose: a rule written inside one verb protects only
the verbs that existed when it was written.

1. **Never sets `ALLOW_PLAINTEXT`, and never passes `--yes` to `unpublish`.** `ADR-007` §2 bound 3,
   which is not negotiable by a later slice. The subcommand and the flag each invoking verb passes
   are fixed in this file; **the verb's argument string is never forwarded to the script**, so no
   user-supplied token can become a script flag. **This rule is followed, not enforced** — a per-arm
   denial cannot express a flag inside an arm this file grants, and the frontmatter section above
   names that residual rather than covering it.
2. **Reaches the publish script only by its own path, spelled repo-relative exactly as the
   frontmatter entries spell it.** Never through `bash` or `sh`, never through a wrapper, an alias or
   a generated command line, and never through a second spelling of the script's own path.
   `disallowed-tools` carries **two** members of that list — it removes `bash` and `sh` from the
   pool. **The rest of this rule — the alias, the other interpreters, and the path spelling — is
   followed, not enforced**, and the frontmatter section above names each as a residual rather than
   covering it.
3. **Never publishes, and never re-publishes.** No verb here runs `publish`, `update`, `rotate` or
   `list` — nor `status`, which is `list` reached under a second name. **Each of those five arms is
   denied by name in `disallowed-tools`, in the repo-relative spelling, so for that spelling this
   rule is carried by an entry rather than by prose alone.** The spelling residual named above is the
   remainder of it. Where publishing is what the user wants, name `/trip-publish` and stop.
4. **Never reads, writes, moves, prints or removes `trips/<slug>/.passphrase`**, and never renders
   its contents in any output, including a refusal. Reading it would put the secret into the session
   transcript, which is the failure the publish exclusions exist to avoid.
5. **Never overwrites and never deletes existing trip content.** `ADR-007` §2 bound 5, and `trips/`
   is git-ignored, so a clobber is recoverable from nothing — not from a revert, not from the repo,
   not from the log. `Edit` is used on exactly two admitted shapes: **changing only the named field's
   line**, and **appending under a new section where no existing line changes**. Removing a line,
   rewriting a file, reordering it, merging into a prior unit or deleting one is neither.
6. **Creates nothing.** No file, no directory. Every path this command touches must already exist; a
   missing one is a stop that names the path and names the repair, and the repair is named rather
   than run. **`Write` and `NotebookEdit` are denied, which removes those two primitives — it does
   not establish that no create path exists.** `Bash(ls:*)`, `Bash(grep:*)` and `Bash(date:*)` are
   granted and sit outside every denial, and a redirection on any of the three would create a file.
   **So *creates nothing* is a rule this file follows** — held by each verb's fixed invocation set
   and by its own `**Reads:**` and *Never* lines, not by the denials. **That residual is named here
   rather than covered**, and it is why this is written as a rule at all.
7. **Writes only under `trips/<slug>/`**, where `<slug>` is `trip.slug` exactly as `E1` spelled it.
   No path is ever built from the `--trip` value.
8. **Never asserts a conclusion about trip state that no gate and no script observed.** § *The
   stop-message rule* below is where this one is worked out, because it is the rule that binds this
   command hardest.

**Extension rule.** A later slice may append a numbered rule **only** where it genuinely binds every
verb of this command, present and future, and must say in its own design that it did so and why. A
rule that binds only that slice's own verbs goes inside those verb sections.

## Selecting the verb

A literal lookup. Every step is lexical and the last has a terminal else-branch, which is what
separates a lookup from a classification.

1. Take `$ARGUMENTS` as a literal string.
2. Remove `--trip` together with the value that follows it, from wherever in the string it appears —
   it is accepted in any position. `--trip` is a contract-level token: it is removed **before** the
   verb is selected, it is passed to **no** verb, and it is **never** a path component. **A `--trip`
   with no value after it is a malformed invocation** — say that `--trip` was given without a slug,
   and stop. That refusal happens before the gate ladder runs, so it sets no `trip.resolution` and no
   `trip.stop_gate`, and it asserts nothing about whether a trip exists, which trip is active, or
   what mode it is in.
3. The verb is the first remaining whitespace-delimited token, ASCII-case-folded. **If no token
   remains, no verb was typed** — go to § *When no verb was typed*.
4. **Strip at most one leading `--` from that token.** See the divergence note below.
5. Match the result by **exact string equality** against the `verb` column of the requirement table
   in this file, read live from the block already in context. Not a prefix match, not a nearest
   match, not a fuzzy match, not a substring match. A token matching no cell goes to § *When the
   token is not a verb of this command*.
6. Everything after the verb token is that verb's argument string. It is not interpreted here, and
   it is never forwarded to the publish script.

Never infer the verb from the wording of the request, from the trip's mode, from which files exist,
or from anything other than the token step 3 produced.

**The `--`-strip in step 4 is a divergence from the shipped consumers and is declared as one.** The
dispositions are spelled `--temporary`, `--archive` and `--reopen` where this command was specified,
while the `verb` column takes bare tokens and this file's headings key on them. One total,
deterministic, order-fixed normalisation reconciles both without making the lookup any less lexical:
**it changes the spelling accepted, never the set recognised.** `--archive`, `archive` and
`--ARCHIVE` reach the same row. `arch`, `--archiv`, `---archive` and `--archive=x` all reach § *When
the token is not a verb of this command*, and **no near-match suggestion is offered on that branch**.

**The set this command recognises and the set it implements are the same set**, read live from the
same rows of the requirement table above. So this file carries no *recognised but not implemented at
this revision* branch — that branch has nothing to select — and a later slice must not add one.
`ADR-007` §3 fixes the direction: to add or change a request type, add or change the command first.

**The refusal branches of this file are these, and they are different renders:** the
`--trip`-without-a-value refusal in step 2 above; § *When no verb was typed*; § *When the token is
not a verb of this command*; and § *When the resolved state does not serve the verb*. Collapsing any
two of them is a defect.

## When no verb was typed

`/trip-decommission` on its own is **not** a default; it is a refusal. Say that no verb was given,
print the verbs of this command read live from this file's own requirement table, and stop. Select
no verb, and do not fall back to one.

`/trip` defaults a bare invocation to `status` because `status` is read-only. **Every verb of this
command has an out-of-repo effect or a file effect, and a command with effects never picks one for
you.**

This refusal happens before the gate ladder runs, so it sets no `trip.resolution` and no
`trip.stop_gate`, and it asserts nothing about whether a trip exists, which trip is active, what mode
it is in, or whether anything is published.

## When the token is not a verb of this command

Render exactly three things and nothing else:

1. The token, verbatim, as the user typed it.
2. The verbs of this command, read live from this file's own requirement table — not from a list
   written into this file.
3. One sentence stating that that table is the whole of this command's verb set at this revision.

Then stop. Do not guess. **Do not offer a near-match suggestion — no "did you mean"** — a suggestion
is a classification with an extra step and a reflexive accept, on the least-inspected path in this
file. Do not fall back to any other verb of this command, and do not infer a verb from the wording of
the request.

**A typed `delete` lands here**, because the repo delete is not a verb of this command. This render
does not carry the hand-off: it renders the three things above and stops. The hand-off is named in
`temporary`'s and `archive`'s own output, and a user who typed `delete` reaches it by asking. That is
`ADR-007` §4 row 10's disposition rendered honestly rather than smuggled back in as a verb.

This refusal happens before the gate ladder runs, so it sets no `trip.resolution` and no
`trip.stop_gate`: those are outputs of a ladder that did not run, and giving this refusal a gate id
would widen the contract's field set. Say nothing about whether a trip exists, which trip is active,
what mode it is in, or whether anything is published.

## When the resolved state does not serve the verb

This is the G7 render. It happens after the ladder has run, so it carries `trip.stop_gate: G7`.

- **`REDIRECT`** — name the command that does serve the request, and stop.
- **`REFUSE`** — name why the resolved state does not serve the verb, taking the reason from that
  verb's own row of the requirement table, and stop.

**The reason is derived from the resolved verb's own row, and never from a universal over the
table.** Read that row live; the cell whose declared value the resolved record does not satisfy **is**
the reason, and the render names **that cell, the value the row declares, and the value the ladder
resolved** — those three and no more. **Nothing here states what any other row declares**, because
that is a closed enumeration of a set this table's own extension point grows, and it is false the
first time a slice appends a row.

Refusals of this shape carry their own remedy, taken from the cell that was not satisfied:

- The trip is `ARCHIVED` and the verb's row leaves `lifecycle` at its `ACTIVE` default → say the trip
  is archived, name the cell and the two values, and name **`/trip-decommission reopen`** as what
  returns it to `ACTIVE`.
- The trip is `ACTIVE` and the verb's row declares `lifecycle: ARCHIVED` → say the trip is active,
  name the cell and the two values, and name **`/trip-decommission archive`** as what concludes it.

Which verbs run on an archived trip is read **live from the `lifecycle` column of the table above**,
never from a sentence in this file naming a set.

## The stop-message rule, and the defences this command carries

`CLAUDE.md` § *Resolving a trip* states the rule: a STOP **names what could not be established and
the remedy**, and **never asserts a conclusion about trip state that the gate did not observe.** The
contract names this command's own shape as the forbidden one — *"Nothing is published, so there is
nothing to take offline"*, a conclusion about publication state derived from a directory listing that
may have failed. It binds every render of this file, not only the ones the contract types as stops.

**Defence 1 — this command never derives publication state.** It does not probe for
`trips/<slug>/.publish`, does not read `trips/<slug>/.passphrase`, does not read
`trips/<slug>/.publish-slug`, and lists nothing in order to decide whether to act. It runs the
idempotent script, or it hands off.

**Defence 2 — the script's own output is evidence; this command's inference is not.** Where the
script reports an outcome it observed through a real API call, relay it **as the script's
observation, attributed to it**. Add nothing, and draw no conclusion beyond what it says.

**Defence 3 — the no-op line is the forbidden shape arriving from the script, and it is qualified
rather than relayed.** `unpublish` resolves the repo through `.publish-slug`; on a name that no
longer matches a live repo it reports that there is nothing to take down and **exits successfully** —
the site stays up and the operator is told it is gone. **That is a property of the script's own
resolve-then-report path, and that path is what establishes it here.** `/trip-record .publish-slug`
is where the name it resolves is set, and is named below as the remedy — not as the basis for this
claim.

So when the script takes its no-op branch, **do not report the trip as unpublished, and do not say
nothing is published.** Say, in these terms:

- the repo the resolver named was not found — naming the repo **as the script named it**;
- **a site published under a different name is not covered by this result**, because the resolver
  reads one name and reports on that name alone;
- `/trip-record .publish-slug` is where that name is set, and re-running this verb after correcting
  it is the remedy.

That is what could not be established, and the remedy. It is not a report that the site is down.

## temporary

**Reads:** nothing beyond the blocks above. It reads no `trip-context.md`, no `trip-log.md`, no
`trips/<slug>/.publish-slug` and **no `trips/<slug>/.passphrase`**.

Takes the trip's site offline and leaves the local tree untouched.

**Invokes:** `scripts/publish-trip-site.sh`, subcommand `unpublish`, on `trips/<slug>`, with the
`--disable-pages-only` flag — and nothing else. The path is spelled **repo-relative**, exactly as the
frontmatter entries spell it. **The subcommand and the flag are fixed here**, and the verb's argument
string is **never forwarded**, so no user-supplied token can become a flag. That closes the
**caller-supplied** route to `--yes`, and it closes it **by this file's own conduct** — the
frontmatter cannot express a flag inside an arm it grants, which is the residual named above.

**Writes: nothing.** No byte of the local tree. No marker, no log entry, no file, no directory. This
is the verb's defining property and it is stated positively rather than inferred from an absent
grant: **this verb takes no `Edit`**, and the passphrase file is **not read, not written, not moved
and not removed**. **The other half of the claim belongs to the script and is established there
rather than here:** the disable-only limb returns before the one local removal `unpublish` performs,
so it touches neither the passphrase file nor `trips/<slug>/.publish`. **The claim rests on that
limb**, which is where a change to it would have to be caught.

**No additional OAuth scope, and no gate is bypassed.** The disable-only limb returns **before** the
`delete_repo` scope check and **before** the typed confirmation. Nothing is bypassed because nothing
stands on that path — which is a statement about where the limb returns, not a claim that the action
is inconsequential.

**Reversibility: CHEAP · confidence HIGH.** Name the reversal in the output: **re-enable Pages in the
repo's Settings → Pages, branch `main` / root.** It is operator-side, and this command does not
perform it.

**The residual is stated separately rather than folded into the tier.** The repo name stays public,
and already-fetched content may persist in third-party caches and clones — **a takedown is not a
retraction**, and no tier on this action reverses a disclosure that already happened.

**Report what the script reported**, per § *The stop-message rule*. On the no-op branch, take that
section's render; do not say the site is down.

**A stated consequence, because the row makes it real.** This verb's row leaves `lifecycle` at the
`ACTIVE` default, so on an archived trip it refuses at G7. `archive` has already performed this same
takedown; a site re-enabled by hand on an archived trip needs a `reopen` first. That is a consequence
of the row, said out loud rather than left to be discovered.

**Never.** Runs no other subcommand and passes no other flag. Sets no `ALLOW_PLAINTEXT`. Passes no
`--yes`. Reaches the script through no `bash` or `sh`. Reads or renders no passphrase. Writes,
creates or deletes nothing. Deletes no repo — see § *Deleting the trip's public repo*, which is named
in this verb's output as the further option and is never run from here.

## archive

**Reads:** `trips/<slug>/trip-log.md` — read **before** it is written, to confirm the append target
exists and to locate the append point at its end; `trips/<slug>/trip-context.md` — read to locate the
lifecycle marker line or, where it is absent, the title-line anchor the insert uses. Reads **no
`trips/<slug>/.passphrase`**, and reads `trips/<slug>/.publish-slug` not at all — the resolver reads
it, this verb does not, and reading it here would let this command form its own view of publication
state, which § *The stop-message rule* forbids. Dispatches no agent.

Concludes a trip: the same takedown `temporary` performs, then the lifecycle marker, then a closing
entry in the trip's log.

### Order, and the order is load-bearing

**Run these in this order. Do not reorder them.**

1. **Preconditions first, before any out-of-repo effect.** `Read` `trips/<slug>/trip-log.md`.
   **Absent → stop, and create nothing:** name the path that is missing and name
   **`/trip-new <slug>`**, whose Resume branch is the declared repair for a missing scaffold member.
   **Name it; do not run it.** No `Write` grant is taken here. This step runs first precisely so that
   a stop can never leave a site taken offline with no record of it. That stop is reached after the
   trip resolved and this verb ran, so it sets no `trip.stop_gate`, does not change
   `trip.resolution`, and renders no gate id.
2. **The takedown** — the same fixed invocation `temporary` makes:
   `scripts/publish-trip-site.sh`, subcommand `unpublish`, on `trips/<slug>`, with
   `--disable-pages-only`, and nothing else. The argument string is not forwarded. **Nothing is
   deleted:** that limb returns before the delete-scope check and the typed confirmation, and it
   touches neither the publish marker nor the passphrase file.
3. **The marker** — set `**Lifecycle:**` to `ARCHIVED`, per § *The lifecycle marker*.
4. **The closing log entry** — append it, per § *The closing entry*.

**Takedown before marker, and here is why that is load-bearing rather than tidy.** This verb's row
declares `lifecycle: ACTIVE`, so **once the marker lands, a re-run of this verb refuses at G7.**
Writing the marker first would therefore convert a failed takedown into a trap: the trip reads
archived, the site is still live, and the way back is through a verb the user did not ask for.
With the takedown first, a partial completion leaves the trip `ACTIVE` and the whole verb re-runnable,
and the script's own idempotence makes the repeat harmless. **The ordering and this row's `lifecycle`
cell agree, and they were made to agree deliberately.**

### On partial completion, say exactly what happened

Report **which steps executed and which did not**, by name. **Never report a step as done that did
not run**, and **never infer one step's outcome from another's** — a marker that was written is not
evidence that the takedown succeeded, and a takedown the script reported is not evidence that the log
entry landed. Where a step did not run, say which one and why, and say what state that leaves.

### The closing entry

**The date.** Get it by running `date +%F` as a tool call **here in the body, not as a pre-execution
block**, and use the bare `YYYY-MM-DD` form exactly as the call returned it. The reason is the
contract rather than style: § *What the blocks above are* fixes how many pre-execution blocks this
file carries and it already carries all of them, so a further one is a red check on push whatever
this section says.

**The write tool, and the shape it is taken under.** `Edit`, under standing rule 5's append shape:
the target exists, **no existing line changes**, and the entry is added at end of file. The
precondition in step 1 **is** that shape's existence probe, and it is what makes the tool reachable:
it runs before `Edit`, and on its absent branch this verb stops rather than falling through to a
create.

- **The entry's structure is `CLAUDE.md` § *trip-log.md*'s and is not restated here.** That section
  is the authority on its own fields, read live from the text already in context.
- **The entry's scale is § *Ending a session*'s.** That section's remaining disposition — skipping
  the log — is not reachable here, because the verb was typed and the decision to record is therefore
  already made.
- **Append only.** A new `## Session <YYYY-MM-DD>` section at end of file. **No existing line
  changes:** the title line is not rewritten, and no prior entry is edited, re-ordered, merged,
  deduplicated or removed. Where a section for the same date already exists, **a second one is
  appended beside it rather than merged into it** — merging edits a prior entry.
- **What it carries.** That the trip was archived; that the site was taken offline and by which
  invocation; the reversal for each — `reopen` for the marker, the Settings → Pages step for the
  site; and the residual, that the repo name stays public and cached copies may persist. It carries
  **the act and its reversal**, and never state that belongs to `trip-context.md` or to
  `outputs/event-status.md`.
- **Never invents.** An element with nothing to record is omitted rather than filled to make the
  entry look complete.

### Reversibility

**CHEAP · confidence HIGH**, for the state this verb changes: `reopen` restores the marker, and the
Pages re-enable is named in the output.

**Two elements are stated separately, because a tier on the action does not cover them.** The closing
log entry is a **permanent addition** — an append is never removed, which is what bound 5 is for.
And the marker **changes how every other verb of the whole surface resolves this trip**, which is
blast radius rather than reversal cost.

**Never.** Deletes nothing and removes no line. Runs no subcommand other than the one named in step 2
and passes no flag other than the one named there. Sets no `ALLOW_PLAINTEXT`. Passes no `--yes`.
Reads or renders no passphrase. Deletes no repo — see § *Deleting the trip's public repo*, named in
this verb's output as the further option and never run from here. Adds no heading to
`trip-context.md`, and writes no `templates/` file.

## reopen

**Reads:** `trips/<slug>/trip-context.md` — read to locate the `**Lifecycle:**` line and its current
value before that value is changed, so the outgoing value can be echoed. Reads no `trip-log.md`, no
`trips/<slug>/.publish-slug` and **no `trips/<slug>/.passphrase`**. Runs no script and dispatches no
agent.

Returns an archived trip to `ACTIVE`. Its row declares `lifecycle: ARCHIVED`, which is what lets it
run on a trip whose lifecycle the defaulted rows refuse. **Which verbs run on an archived trip is
read live from the `lifecycle` column of the table above**, never from a sentence here naming a set.

**It sets the value; it never removes the line.** `**Lifecycle:** ARCHIVED` becomes
`**Lifecycle:** ACTIVE` — an `Edit` in which **only the named field's line changes**, standing rule
5's first admitted shape.

**Why setting and removing are not the same act, when they reach the same gate result.** An absent
`**Lifecycle:**` line defaults to `ACTIVE` at G4, so removing the line would resolve the trip
identically. **Removing it is a deletion of trip content, which `ADR-007` §2 bound 5 forbids**, and
`trips/` is git-ignored, so the removed line is recoverable from nothing. It would also erase the
record that this trip was ever concluded. **Same outcome, different legality — this file takes the
legal one.** The line stays, and the trip's history stays legible.

**Echo the outgoing value and the incoming one**, both, so the change is visible in the output rather
than only in the file.

**Where the line is already `ACTIVE`, or absent.** Already `ACTIVE` → **idempotent: change nothing,
and say so.** Absent → the trip already resolves as `ACTIVE` by the contract's declared default;
**change nothing, create nothing, and say that the trip is not archived**, naming the default rather
than reporting a repair. Absence is the contract's default tested as its own case; it is **never**
read as a proxy for a value, and no branch here is predicated on it as one.

**It performs no out-of-repo act.** It does **not** re-publish and it does **not** re-enable Pages.
It **names** the Settings → Pages step as the operator's, and names **`/trip-publish`** for a rebuild.
A reopen that silently re-published would put a site back online without anyone asking.

**Reversibility: CHEAP · confidence HIGH** — `archive` is the inverse, and the closing entry
`archive` wrote stays, because an append is never removed.

**Never.** Removes no line from any file. Deletes nothing. Creates nothing. Runs no script. Sets no
`ALLOW_PLAINTEXT`. Passes no `--yes`. Reads or renders no passphrase. Writes no file other than
`trips/<slug>/trip-context.md`, and within it no line other than the `**Lifecycle:**` line.

## The lifecycle marker — shape, placement, and the constraint that keeps G4's default legitimate

**Shape.** One line: `**Lifecycle:** ARCHIVED` or `**Lifecycle:** ACTIVE`. **Bare value, no
brackets, ever.** The vocabulary is exactly G4's yielded set and nothing else — a value outside it is
never written, and a bracketed value is never written, because a bracketed value would make the field
a placeholder and hand it to `ADR-007` §2 bound 6.

**Placement.** Immediately below the trip's `# Trip Context — …` title line, separated by a blank
line, above the first `---`. The anchor is **the file's first `#` heading**, which
`templates/trip-context.template.md` carries as its own first line — so every `trip-context.md`
scaffolded from that template has one. **That template is what establishes the anchor, and the claim
is a property of it rather than a universal over the population:** a `trip-context.md` carrying no
`#` heading has no anchor, and the insert then **stops and names the missing anchor**, rather than
choosing another place or creating one.

**Why there, and why it is not a sixth mode.**

- **It is outside `## Mode`.** `Current mode:` has its own vocabulary and every resolver branches on
  it; a lifecycle value inside that block invites a sixth mode. `UNSET` already demonstrates the
  shape of a non-mode — it names the absence of a mode, holds no row in `CLAUDE.md` § *Modes*, and is
  disposed of by a requirement table rather than by the gate that yielded it. **`ARCHIVED` is the
  same shape one gate earlier:** G4 yields it, G4 does not stop on it, and G7's table disposes of it.
  The marker is a separate field on a separate line for exactly that reason.
- **It is outside every `##` block.** The preamble is not a block, so the insert collides with no
  block writer. `CLAUDE.md` § *Write ownership* assigns a block it does not list to **nobody** and
  requires a new block to get an owner in that table before it gets content. **This command adds no
  `##` heading to `trip-context.md`**, so any block census over that file or its template is
  unchanged by it.
- **The gate does not depend on the placement.** The record block's third alternation arm is anchored
  at line start and scans the whole file, so G4 finds the field wherever it sits. The anchor exists
  to make the **write** deterministic, not the read.

**The write is an insert that changes no existing line, and its cases are branches rather than one
path.** Line absent → **insert at the anchor**, changing no existing line. Line present reading
`ACTIVE` → change the value. Line present reading `ARCHIVED` → **idempotent: change nothing, and say
so.** No branch here is predicated on the field's absence *as a proxy for a value*; absence is the
contract's declared default, tested as its own case.

**The binding constraint, and this command honours it by not approaching it.**
`templates/trip-context.template.md` **must never ship a `Lifecycle:` placeholder.** The moment it
does, `ADR-007` §2 bound 6 binds the field and **G4's default inverts from *absent ⇒ `ACTIVE`* to
*absent ⇒ malformed***, which would make every trip scaffolded before this command existed read as a
broken file. **This command touches no template — and that is a rule it follows, not something its
frontmatter withholds.** `Write` is denied, but changing a file that already exists needs `Edit`, and
**`Edit` is granted and file-general**: it is exactly the tool the disclaimed action would take, and
no entry bounds where it may reach. What holds the template out is standing rule 7 — which makes
`trips/<slug>/` the only place any verb here writes — together with this section and `archive`'s and
`reopen`'s *Never* lines. **That is the named residual: `Edit`'s reach is bounded by rule, and
nothing on this surface bounds it by control.**

## Deleting the trip's public repo — the operator hand-off

**This is not a verb of this command, and it never becomes one.** `ADR-007` §4 row 10 disposes of the
default `unpublish` — the repo delete — as **EXCLUDED**, reason `ADR-007 §2`. The bound and the TTY
leg are co-extensive for this form and **the bound is the firmer basis**, so the correct output is
not a substitute mechanism. It is the hand-off below, and **this command never runs it.**

**Where this appears.** In `temporary`'s and `archive`'s own output, as the further option available
to the operator. Not in the not-a-verb refusal, which renders its three things and stops.

**The hand-off.** The command lives in `scripts/publish-trip-site.sh`. The form is its `unpublish`
subcommand on the trip's directory **without** the disable-pages-only flag — the default, which is
the deleting one. **Point the operator at `CLAUDE.md` § *Publishing to GitHub Pages*, which carries
the literal line to run**, and state, in terms:

- **It deletes the public repo, and with it the destination-and-year in the repo's name** — not only
  the site.
- **Reversibility: IRREVERSIBLE · confidence HIGH. Rollback is infeasible, and here is the
  statement:** there is no revert that reaches it, no repo left to restore from, and no log that
  recovers it. Nothing in this repository and nothing this command holds can undo it.
- It needs the `delete_repo` gh scope, which the operator grants once.
- It **prompts at a terminal for the repo name to be typed** before it proceeds, and a command this
  surface runs has no terminal.
- **This command never runs it, and never passes the yes-flag that would skip that prompt.**
- Content **may persist in third-party caches and clones regardless**, so this is not a retraction
  either.

**One mechanical constraint on the render, and it is a real hazard rather than a style note.** **No
line of this hand-off may begin with the pre-execution marker** — a backtick-fenced bang at line
start. Any such line is counted as an evidence block by the contract guard and turns this file's
prefix equality red. The bare script path goes in a code span and the flags go in prose, which is the
rendering `scripts/test-trip-resolution-contract.sh` records in its own scope constraint: it declines
to scan `CLAUDE.md` for publish-script invocations precisely so that the conforming hand-off does not
become the violation.
