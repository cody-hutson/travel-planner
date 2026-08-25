---
description: The trip entry point. Resolves the trip, then runs the verb you typed. Read-only at this revision.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*)
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), Write, Edit, NotebookEdit]
---

# /trip

`/trip [verb] [--trip <slug>] [verb args...]`

The verb is the one the user typed. Nothing in this file supplies a verb they did not
type, and nothing in it reads the wording of the request to decide one.

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
| status | ANY | any | any | G8 |

The ladder this cites is stated in one place and is not restated here. The blocks above
have already run; their output is the whole of the trip state this file has read and the
whole of the trip state it needs. Do not read `trip-context.md` in full, and do not read
`trip-log.md` or anything under `outputs/`.

Each pre-executed block above is a tool grant this file has to hold, and each is held for
a use the table above names: the listing block for `Bash(ls:*)`, and the record block for
`Bash(grep:*)`, which reads the lifecycle, the mode and the destination by value. Neither
grant is speculative and neither is unused.

## Standing clause — binding every verb of this command, present and future

This clause sits outside every verb section on purpose: a rule written inside one verb
protects only the verbs that existed when it was written.

`/trip` never publishes. It never invokes `scripts/publish-trip-site.sh` — not directly,
not through `bash` or `sh`, not through any wrapper, alias or generated command line. It
never sets `ALLOW_PLAINTEXT`. It never passes `--yes` to `unpublish`. Where publishing is
what the user wants, name `/trip-publish` and stop; do not reach the script from here.

This file writes nothing, creates nothing and deletes nothing. It introduces no field, so
it claims no row in `CLAUDE.md` → *Write ownership — trip-context.md, block by block*.

## Selecting the verb

A literal lookup. Every step below is lexical, and the last one has a terminal
else-branch, which is what separates a lookup from a classification.

1. Take `$ARGUMENTS` as a literal string.
2. Remove `--trip` together with the value that follows it, from wherever in the string it
   appears — it is accepted in any position. `--trip` is a contract-level token: it is
   removed before the verb is selected and it is passed to no verb. A `--trip` with no
   value after it is a malformed invocation — say that `--trip` was given without a slug,
   and stop.
3. The verb is the first remaining whitespace-delimited token, ASCII-case-folded. If no
   token remains, the verb is `status`.
4. Match that token by **exact string equality** against the recognition set: the verbs of
   this command named in `CLAUDE.md` → Step 1, in the `Command` column, whose cells render
   as `` `/trip <token>` ``. Read that column now, from the table already in context. Not a
   prefix match, not a nearest match, not a fuzzy match, not a substring match.
5. Everything after the verb token is that verb's argument string. Do not interpret it
   here.

Never infer the verb from the wording of the request, from the trip's mode, from which
files exist, or from anything other than the token step 3 produced.

The recognition set and the set this file implements are read from different places and
are not the same set. The recognition set is `CLAUDE.md`'s Step-1 `Command` column; the
set this file implements is the requirement table above. Both are read live, so a verb that is
recognised but not yet implemented is a fact this file reports rather than a fact it
records, and neither set is written down here as a number.

`trip.slug` is the directory name exactly as `E1` spelled it. The `--trip` value is a
selector matched against the members `E1` listed — it is never a path component, and no
path is ever built from it on this command.

## When the token is not a verb of this command

This refusal happens before the gate ladder runs — before its first gate — so no trip
state has been established and none is asserted. It sets no `trip.resolution` and no
`trip.stop_gate`: those are outputs of a ladder that did not run, and giving this refusal
a gate id would widen the contract's field set. Say nothing about whether a trip exists,
which trip is active, or what mode it is in.

Render exactly this, and nothing else:

1. The token, verbatim, as the user typed it.
2. The verbs of this command, read live from Step 1's `Command` column — not from a list
   written into this file.
3. Stop.

On this path, do not guess. Do not offer a near-match suggestion — no "did you mean" — for
a suggestion is a classification with an extra step and a reflexive accept, on the least
inspected path in this file. Do not fall back to any pipeline verb. Do not infer a verb
from the wording of the request.

## When the verb is recognised but this revision does not implement it

A distinct outcome from the one above, and it must not be collapsed into it. The token
matched the recognition set, and it names no row of the requirement table in this file.

Name the verb, say that it is recognised and that this file does not implement it at this
revision, and stop. Do not give a reason drawn from the resolved trip state: the resolved
state is not why, and naming it would be a false reason.

## status

Read-only, and read-only as a rule this verb follows. It writes nothing, dispatches no
agent, runs no script, and reads nothing beyond the pre-executed blocks above.

`status` is exactly two renders, mutually exclusive, selected by `trip.resolution`.

**`STOPPED`** — render the stop the contract produced: what could not be established, and
the remedy, in the terms the contract states for the gate that stopped. Add nothing,
interpret nothing, and assert no conclusion the gate did not observe.

The listing of trips on an ambiguous population is one of these renders. It is the
contract's own trip-population disposition, rendered — not a behaviour `status` owns. So
are the create pointer on an empty population, and the refusal when a supplied `--trip`
matched no member or matched more than one. Every command in this surface renders these
identically, because they belong to the contract rather than to any verb.

**`RESOLVED`** — render, in this order:

1. The trip: `trip.slug` and `trip.destination`.
2. `trip.lifecycle`.
3. `trip.mode`, with one line on what that mode covers.
4. The verb index, below.

`trip.freshness` is empty at this revision, so render nothing from it. When it carries
entries, `status` is where they are reported.

### The verb index

Evaluate the requirement table in this file against the resolved record, using the same
predicate the dispatch above uses. Read this file's own table — do **not** derive the
index from `CLAUDE.md`'s Modes table and do **not** derive it from the agent roster. Those
answer which agents run, not which verbs this command runs; joining them would produce an
advisory list that can disagree with what the verbs actually do. Reading the same rows the
dispatch reads is what makes it impossible for the index to advertise a verb that then
refuses.

Order:

1. The rows that `RUN` for this resolved record — lead with them. That is the answer to
   "what can I do next".
2. The rows that `REDIRECT`, each naming the command it redirects to.
3. The rows that `REFUSE`, each with the reason from its own row, so the index never goes
   silent on a verb this file's table declares.

Then name the Step-1 rows whose `Command` cell carries an `EXCLUDED:` marker, read live
from that table rather than listed here — those are the actions to just ask for, and they
are stated rather than left as a gap.

The index spans this file's table, which at this revision is narrower than the taxonomy: a
verb Step 1 declares and this file does not implement holds no row here, so the index does
not list it. That is not the surface going silent on the verb — typing it reaches *When the
verb is recognised but this revision does not implement it*, above — it is the index
declining to advertise what this file does not implement.

`status` declares `lifecycle: ANY` deliberately, rather than leaving that cell to its
default. Orientation is precisely what an archived trip still needs — it is where the
reopen path gets named — and a `status` that stopped resolving the moment a trip was
archived would withhold the answer at the one moment the user most needs it.
