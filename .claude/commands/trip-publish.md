---
description: The publish surface. Re-publishes an already-public trip site after edits, and lists what is published. Never creates a repo, never rotates, never takes a site down, never publishes plaintext.
argument-hint: <verb> [--trip <slug>]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Bash(test:*), Bash(scripts/publish-trip-site.sh update:*), Bash(scripts/publish-trip-site.sh list:*)
disallowed-tools: [Bash(scripts/publish-trip-site.sh publish:*), Bash(scripts/publish-trip-site.sh rotate:*), Bash(scripts/publish-trip-site.sh unpublish:*), Bash(scripts/publish-trip-site.sh status:*), Bash(bash:*), Bash(sh:*), Read, Write, Edit, NotebookEdit]
---

# /trip-publish

`/trip-publish <verb> [--trip <slug>]`

The verb is the one the user typed. Nothing in this file supplies a verb they did not
type, and nothing in it reads the wording of the request to decide one.

## Why this is its own file

**What `disallowed-tools` does at runtime is contested, and this file does not settle it.**
Two accounts ship in this repo and they are not compatible.
`reference/adr/ADR-007-command-entry-point.md` § Context says the field *removes the named
tools from the pool* — a real restriction. The trip-resolution contract workflow's
scope note says the opposite where it matters: `allowed-tools` and `disallowed-tools` are a
turn-scoped pre-approval grant and **every tool stays callable**, adding that a green check
there is not a privilege guarantee and must not be read as one. **Nothing in this repo
arbitrates**, because nothing in it reads the field: it appears in the five command files,
in that workflow comment and in the ADR, and in none of them as something a check parses.

What the two accounts **agree** on is all this file relies on. The declaration is
turn-scoped and clears at the next message; a tool left off `allowed-tools` is not thereby
forbidden, it routes through the usual permission settings instead. **Omission is not
prohibition** under either account. And durable blocking would need a permission-settings
deny rule — a different artifact, and one this release does not ship.

**So this file's conduct is written as rules it follows, never as a property its
frontmatter guarantees**, and that is what keeps it sound under either account: every claim
below holds without the disputed one being true.

**Each claim here about what this command will not do is labelled by what establishes it,
and the two bases are not interchangeable.** A claim resting on a **rule this file
follows** holds because the file says so, and nothing but the file says so. A claim that
*also* has a `disallowed-tools` entry behind it names that entry as a **declared**
restriction — one whose runtime force this repo does not establish, and which is therefore
offered as corroboration rather than as the thing that makes the claim true. What is never
claimed is the third thing: a prohibition inferred from a grant left out. Where this file's
reach is bounded by omission alone, it says *unlisted*, not *denied*.

That is why the publish surface is a separate file rather than a rule written inside
`/trip`. A rule written inside one file cannot partition anything **across** files — only
the per-file declarations can, because they are the only per-file thing there is to differ.
What a runtime does with those declarations is the contested question above; the partition
is a property of the declarations either way, which is why it is stated as one. **This file
holds the publish half of it, and that half is observable right here:** it reaches the
publish script and names every content-mutating tool in its `disallowed-tools`. The editing
half is a **requirement on the files that
hold it** — each denies the arms of the publish script it does not own, and both shell
wrappers. It is stated as a requirement rather than as an observation about those files,
because a sibling's frontmatter can change without this file changing, and a claim this
file makes about another file's declarations is a claim it cannot keep true.

One file could not hold both halves and still do either job, so folding a publishing verb
into `/trip` would put `plan`, `replan`, `research` and `site` on the same side of a
per-file control as a push to a live public site. **The separation is the control**, and it
is the reason this file exists — not a convenience. It is a *declared* partition, turn-scoped
like every grant and denial on this surface rather than a durable guarantee: what it removes
is the case where one file's declared set spans both jobs at once.

### What each grant is held for

| Grant | The use that holds it |
|---|---|
| `Bash(ls:*)` | the trip-listing evidence block below, which the declared `contract-depth` requires |
| `Bash(grep:*)` | the trip-record evidence block below, which the declared `contract-depth` requires |
| `Bash(test:*)` | `update`'s passphrase precondition. Chosen because it is the narrowest primitive that answers *present and readable*, and because it **never opens the path it names** — it answers by exit status, so no file's contents reach any channel. A malformed invocation can still put a usage diagnostic on stderr; that names an operand, never a file's contents |
| `Bash(scripts/publish-trip-site.sh update:*)` | `update`'s single invocation |
| `Bash(scripts/publish-trip-site.sh list:*)` | `list`'s single invocation |

**Denied, not merely unlisted:** `Read`, `Write`, `Edit`, `NotebookEdit`. Nothing here
writes a file or edits one, and that rests on those denials — unlisted would prohibit
nothing.

**Two bounds rest on a rule instead, and are marked as rules rather than dressed as
denials.** This command **dispatches no agent**: the agent-dispatch tool is neither granted
nor denied on this surface, so the deny grammar does not reach it and no denial is claimed
for it — the bound is that no construct below dispatches one. Likewise it runs no `date`,
no `mkdir` and no primitive outside the grant table above: those are *unlisted*, which
pre-approves nothing and forbids nothing, so the bound is again the file's own text.

**One grant does read file contents, and this file states that rather than denying it.**
The trip-record evidence block below greps `trip-context.md` and emits the lines it
matched. That is reading a file's contents — by design, at the depth the contract requires,
and it is why no blanket "nothing here reads a file" claim appears anywhere in this file.
What is ruled out is narrower, and is stated as the rule it is: no construct here directs
that grant, or any other content-emitting primitive, at a passphrase path.

### The deny set, as a rule rather than a list

The denied arms are **every arm of the dispatch `case` in `scripts/publish-trip-site.sh`
whose body reaches a `cmd_*` function, minus the verbs of this file's requirement table**,
with each alternation split into its literal tokens so an aliased arm is denied under
every token that reaches it. Read the dispatch and the table when you need the set: it is
stated as a derivation rather than as a count or a census, so the correct set is always
**re-derivable** from live sources and never goes stale as a written-down number.

**Re-deriving it is not automatic, and this file does not claim it is.** `disallowed-tools`
is a static list in the frontmatter above; nothing compares it to the dispatch. The
trip-resolution contract suite puts runtime privilege out of scope by name, and no check in
this repo reads a `disallowed-tools` line at all. So the day the script grows an arm, the
rule says what the new deny set is — and an editor still has to apply it. The Extension rule
below is where that obligation is written, and it is the whole of what carries it.

`status` is denied under that rule as the script's alias for
`list`, while this file implements the literal `list`; a `status` token also collides with
a different command's verb.

The shell wrappers this surface denies are denied here alongside the arms, because a
wrapper routes around a per-arm denial — denying one arm is worth nothing if the same
command line can be reached through `bash` or `sh`.

**What the deny set does not close, stated rather than papered over.** An enumerated
`disallowed-tools` cannot be closed over every content-emitting primitive, and the wrapper
denial is itself an enumeration — a shell outside the set this surface denies is not
denied by it.

**Nor does the allow side supply a closure to make up for it.** By this section's own rule,
a closed grant list forbids nothing: a primitive left off it routes through the permission
settings rather than being blocked. What the grant table delivers is a closed
**declaration**, not a closure — every primitive this file intends to use is named there,
so a use outside it is a departure from the file rather than something the file quietly
permits. The grep grant, which the contract's prefix equality forces this file to hold at
its declared depth, is structurally capable of emitting a file's contents. That residual is
bounded by a rule rather than by a denial — no construct in this file directs a
content-emitting primitive at a passphrase path.

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`

## Trip records

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*|^\*\*Lifecycle:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md 2>&1`

## Contract header

```
Contract: CLAUDE.md § Resolving a trip
contract-depth: G8
population-role: RESOLVE
```

| verb | lifecycle | mode | destination | depth |
|---|---|---|---|---|
| update | ACTIVE | any | any | G8 |
| list | ANY | any | any | G0 |

The ladder this cites is stated in one place and is not restated here. The blocks above
have already run; their output is the whole of the trip state this file has read and the
whole of the trip state it needs. Do not read `trip-context.md` in full, and do not read
`trip-log.md` or anything under `outputs/` — a rule this file follows, and `Read` is
denied here besides.

Each pre-executed block above is a tool grant this file has to hold, and each is held for
a use the table above names: the listing block for `Bash(ls:*)`, and the record block for
`Bash(grep:*)`, which reads the lifecycle, the mode and the destination by value. No grant
here is speculative and none is unused.

**`contract-depth` is the maximum depth over the table, not a per-verb claim.** `list`
declares `G0` on its own row while this file declares `G8`; the maximum over the table is
`G8`, so the declaration is consistent with the row that differs from it.

**Depth `G0` scopes what `list` reads. It does not exempt `list` from G1 or G2**, which
bind every command in this surface, this one included. `G0` says the verb needs no trip
record — not that the ladder does not run for it. `list` therefore takes G1's
listing-trustworthiness check and G2's population dispositions exactly as the contract
states them for a `population-role: RESOLVE` consumer, the `--trip` rule included. Read
that as the contract's disposition rendered, never as a behaviour this verb owns.

**Why every state cell is declared rather than defaulted.** An undeclared `lifecycle`
reads `ACTIVE` under G7's default. `list` is repo-wide, so a defaulted `ACTIVE` would be a
requirement it never meant to state; it declares `ANY` explicitly instead. `update`
declares `ACTIVE` explicitly for the opposite reason — an archived trip must stop
re-publishing, and stating it in the row is what makes the refusal name a cell rather than
lean on a default.

**Why `update` declares `destination: any`.** Its real precondition is that a site exists
and this trip is already published, which is stronger and more precise than *a destination
is decided*, and it is checked where it belongs — see `update` below. A `destination`
requirement here would be a second, weaker guard for the same failure, and it would refuse
a legitimate case: a site built and already published while the destination line is still
bracketed.

## Standing clause — binding every verb of this command, present and future

This clause sits outside every verb section on purpose: a rule written inside one verb
protects only the verbs that existed when it was written.

1. **This command reaches only the arms its requirement table names.** It never invokes
   `publish`, `rotate` or `unpublish`, in any form — not directly, not through `bash` or
   `sh`, not through any other wrapper, alias or generated command line. The direct route
   and the `bash`/`sh` routes are **denied**; everything past them is a **rule this file
   follows**, because the wrapper denial is an enumeration and a shell outside it is not
   denied — as the deny-side residual above states rather than papers over.
2. **It never sets `ALLOW_PLAINTEXT`, and never passes `--yes` to `unpublish`.** Those are
   the flags that convert a refusal into a silent pass for a non-interactive caller, and
   `reference/adr/ADR-007-command-entry-point.md` § 2 states that bound is not negotiable
   by a later slice.
3. **It never sets `STATICRYPT_PASSWORD`.** A secret set on the invocation sits in the
   command text itself, which is the disclosure the same ADR's § 4 admission rule names
   when it excludes a secret supplied as a command-line argument.
4. **It never reads, prints, echoes, logs, stores or reproduces a passphrase value, and
   never substitutes one.** No construct in this file directs a content-emitting primitive
   at a passphrase path; what touches such a path is the presence-and-readability
   predicate below, which answers by exit status and never opens the file it names. A
   refusal names the path and the variable — never a value, never a substitute, never a
   length, never a prefix.
5. **It writes, creates and deletes no trip content** — nothing this repo treats as the
   trip's own record. It introduces no field, so it claims no row in `CLAUDE.md` → *Write
   ownership — trip-context.md, block by block*. **This rule is scoped to trip content
   rather than to the `trips/` path, because the arm this file owns is not inert under
   that path:** the script's `update` arm removes and re-creates the per-trip scratch
   clone at `trips/<slug>/.publish/` and copies the re-encrypted page into it. That
   directory is a git-ignored scratch clone rather than trip content, which is why it does
   not cross `reference/adr/ADR-007-command-entry-point.md` § 2's bound against
   overwriting existing trip content — but it *is* a write under `trips/`, so a rule
   phrased by path would be false the first time this command ran.
6. **It creates no per-trip GitHub repository and takes no site down.** Repo creation and
   Pages-enabling belong to the `publish` arm, takedown to `unpublish`; both are denied.
   The local clone the `update` arm makes under `trips/` is the scratch working copy rule 5
   names, not a repository this command creates.
7. **It never branches on freshness**, and adds no gate that blocks on it. G8 is reserved
   and report-only, and the contract records the reason: an unconditional
   render-newer-than-model gate refuses every correct publish rather than more of them.

**Extension rule.** A later slice may append a numbered rule above only where it genuinely
binds every verb of this command, present and future, and must say so in its own design; a
rule binding only that slice's verbs goes in that verb's own section. Adding a verb adds a
row to the requirement table, appended below the rows already there. `allowed-tools` grows
by union only, and only where the adding slice's own design names the verb that needs the
grant. **Any arm of the script that is not that slice's verb is added to the deny set in
the same edit** — the deny rule above is stated as a derivation so that the correct set is
*computable* rather than recalled. Computing it is not the same as applying it: applying it
is an editorial step, no check fails if it is skipped, and this sentence is the whole of
what carries the obligation.

## Selecting the verb

A literal lookup. Every step below is lexical, and the last one has a terminal
else-branch, which is what separates a lookup from a classification.

1. Take `$ARGUMENTS` as a literal string.
2. Remove `--trip` together with the value that follows it, from wherever in the string it
   appears — it is accepted in any position. `--trip` is a contract-level token: it is
   removed before the verb is selected and it is passed to no verb. A `--trip` with no
   value after it is a malformed invocation — say that `--trip` was given without a slug,
   and stop.
3. The verb is the first remaining whitespace-delimited token, ASCII-case-folded.
4. Match that token by **exact string equality** against the `verb` column of this file's
   requirement table, read live from the table above. Not a prefix match, not a nearest
   match, not a fuzzy match, not a substring match.
5. Everything after the verb token is that verb's argument string. Do not interpret it
   here and do not forward it: no row of the table above declares an argument, so a
   trailing token is reported and stops the invocation rather than being passed on.

**This command has no default verb.** If no token remains after step 2, name the verbs of
the table above, read live, and stop. A defaulted verb here would supply an action the
user did not type, on a surface where a candidate for the default pushes to a live public
site.

Never infer the verb from the wording of the request, from the trip's mode, from which
files exist, or from anything other than the token step 3 produced.

`trip.slug` is the directory name exactly as `E1` spelled it. The `--trip` value is a
selector matched against the members `E1` listed — it is never a path component, and no
path is ever built from it on this command.

**`--trip` does not filter `list`.** On `list` it still constrains G2 exactly as the
contract states, and it still does not change what `list` prints: `list` is repo-wide and
the script takes no argument for it. That asymmetry is stated here so a reader does not
expect a filtered inventory.

## When the token is not a verb of this command

This refusal happens before the gate ladder runs — before its first gate — so no trip
state has been established and none is asserted. It sets no `trip.resolution` and no
`trip.stop_gate`: those are outputs of a ladder that did not run. Say nothing about
whether a trip exists, which trip is active, or what mode it is in.

Render exactly this, and nothing else:

1. The token, verbatim, as the user typed it.
2. The verbs of the table above, read live from that table rather than from a list written
   into this section.
3. Stop.

Do not guess. Do not offer a near-match suggestion — no "did you mean" — for a suggestion
is a classification with an extra step and a reflexive accept, on the least inspected path
in this file. Do not fall back to any other command's verb, and do not infer a verb from
the wording of the request.

The recognition set here is closed for a second reason as well, and the two are
independent: a verb absent from the requirement table is `REFUSE` under G7's default, so a
token that somehow reached the ladder without a row cannot `RUN` there either. A verb a
later slice adds lands in the table or does not run.

## update

**What it is.** Re-encrypt an already-published trip site and push only ciphertext to the
per-trip repo that already exists. It creates no per-trip GitHub repo, which is what keeps
it clear of the repo-creation reason that excludes the first publish.

**The passphrase stop is verb selection, not output filtering.** The script paths that
write a passphrase to standard output belong to arms this file denies. The arms this file
owns emit none — `update`'s completion line names only the URL, and `list` prints an
inventory table. Because the emitting paths are unreachable from here, **there is no
passphrase value for a filter to miss**. Nothing in this file filters output for a secret,
because nothing in it can produce one.

### Precondition — before any invocation is constructed

Run each limb below and let it pass first. Each uses `test`, which answers by exit status
and never opens the path it names, so no file's contents reach any channel. Run no limb
through any other primitive.

**(i) The trip's passphrase file is present and readable.**

```
test -r "trips/<slug>/.passphrase"
```

with `<slug>` replaced by `trip.slug`. A non-zero exit is a **refusal, and it stops.** Say:
that the trip's passphrase file at that path is absent or unreadable; that `update` would
otherwise mint a fresh passphrase, overwrite that file, re-encrypt and push while printing
nothing, locking out everyone holding the previous one; and that the remedy is to restore
the file and its readability before re-running. Name the path. Name no value, no
substitute, no length, no prefix.

`reference/adr/ADR-007-command-entry-point.md` § 4 names that fall-through as the residual
whose mitigation "is in the command, not in the script", and this limb is that mitigation.
It is also what keeps `update` clear of the same ADR's § 2 bound against overwriting
existing trip content: an existing-but-unreadable passphrase file is existing trip
content, and the fall-through overwrites it.

**(ii) The passphrase environment override is unset. This limb is an addition beyond the
mitigation § 4 names, and it is stated as one.**

```
test -z "${STATICRYPT_PASSWORD:-}"
```

A non-zero exit is a **refusal, and it stops.** The override outranks the file in the
script's resolution order, so limb (i) passes while `update` re-encrypts and pushes under
the override and the trip's saved passphrase still holds the previous value — a silent
re-key that limb (i) cannot catch, because limb (i) passes. This command must never read a
passphrase value at all, so it cannot compare them; the safe branch is to refuse and hand
off. Say:
that `STATICRYPT_PASSWORD` is set in this environment; that `update` would re-key the
published site under it; and that where that is the intent, the operator runs the update
themselves in their own terminal. Name the variable. Name no value, no substitute, no
length, no prefix.

### Ordering

Precondition → invocation → report. Nothing is invoked before every limb passes.

### Invocation

```
scripts/publish-trip-site.sh update trips/<slug>
```

with `<slug>` replaced by `trip.slug`. Run it from the repo root.

**When the trip was never published**, the script refuses before the passphrase is
touched: it resolves the per-trip clone before it resolves the passphrase, so it creates no
repository, pushes nothing, mints no passphrase, and its own message names the remedy — a
first publish. (Resolving the clone does clear a stale scratch clone first; that is rule
5's scope, and it is not a publish.) This verb relies on that refusal rather than
duplicating it; a second, weaker pre-check would be a guard for a failure the script
already guards precisely.

A first publish is not a verb of this file, so render the named remedy as an **operator
hand-off**: point at `CLAUDE.md` → *Publishing to GitHub Pages*, print that section's
publish command for the operator to run in their own terminal, with `trip.slug`
substituted for the placeholder trip directory, and stop. **Print the line** — a hand-off
that names a section and leaves the operator with nothing runnable has failed, the same
standard the plaintext hand-off below is held to. **Rendering a command line for the
operator is not constructing an invocation**, and the two must not be collapsed: what is
forbidden is running it, routing it through any primitive, or offering `publish` as a verb
of this command. Do not do those. Do print the line.

**When the resolved trip is `ARCHIVED`**, the row above declares `lifecycle: ACTIVE`, so
G7 disposes `REFUSE`: name the cell the resolved state does not satisfy and the value the
ladder resolved, and stop. Do not re-publish an archived trip.

### Report

Report what the script reported, and add no conclusion it did not make. On success its
completion line names the live URL. If its pre-push guard aborts, say that nothing was
pushed and name what the script named — a guard abort is not a partial publish.

## list

Repo-wide, read-only, no trip, no arguments, depth `G0` on its own row. It reports each
trip with its repo, status, published and edited dates, and the stale flag, exactly as the
script emits them.

### Invocation

```
scripts/publish-trip-site.sh list
```

Run it from the repo root: the script scans `./trips/` and refuses elsewhere, and it takes
no argument.

**Freshness is report-only.** Render the stale column as the script emits it, including
its indeterminate value. No verb of this file branches on it, and `update` does not
require staleness — re-publishing unchanged content is legal. It is not inert, though: it
pushes a commit, and `reference/adr/ADR-007-command-entry-point.md` § 4 records that
commit's timestamp as a metadata residual no revert reaches.

### Never assert a publication state that was not observed

Distinct cases, and they are distinct branches.

- **A G1 STOP** — the listing canary absent from the first evidence block. Render the STOP
  and its remedy in the contract's terms for that gate. Render no inventory, render no
  empty inventory, and say nothing at all about whether anything is published. A
  conclusion about publication state drawn from a directory listing that may have failed
  is the shape the contract's stop-message rule forbids by name, and a repo-wide
  inventory is where that shape is most tempting.
- **The script's degraded mode** — the GitHub CLI unavailable or unauthenticated. The
  script warns and leaves the publish-state columns indeterminate rather than negative.
  Keep *not published* and *could not determine* apart, and never collapse the
  indeterminate marker into a negative. Report the warning the script printed, so the
  reader knows which columns were not established.

## When a plaintext publish is what the user wants

This file has no plaintext verb and no plaintext flag, and every publish form is denied
here. It never sets `ALLOW_PLAINTEXT` — `reference/adr/ADR-007-command-entry-point.md`
§ 2, and that bound is not negotiable by this file.

The reason is the charter's own, and it is not that the branch is merely risky. The
confirmation on that branch is gated on stdin being a terminal, and a command Claude runs
never has one — so setting the variable does not confirm non-interactively, it **skips the
confirmation entirely**. The charter also records that the plaintext branch does not run
the pre-push ciphertext guard, running a content guard instead.

So this is an operator action. The hand-off: point at `CLAUDE.md` → *Publishing to GitHub
Pages* → the opt-out paragraph, **print that paragraph's command for the operator to run
in their own terminal**, with `trip.slug` substituted for the placeholder trip directory,
say why an agent cannot run it, and stop. Print the line — a hand-off that names a section
and leaves the operator with nothing runnable has failed. Do not run it, and do not carry
a second copy of it here: that paragraph is its one home.
