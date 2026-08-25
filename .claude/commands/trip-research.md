---
description: Research one topic with its agent. Appends to existing output.
argument-hint: [agent-key] [what to research]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Task, Edit, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*)]
---

# Targeted research

Dispatches one agent against one topic and appends what it finds to that agent's
own output file. **You name the agent.** It is never inferred from how the
request is worded, and no other agent runs.

## Agents available

!`ls -1 "${CLAUDE_PROJECT_DIR}/agents"`

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"`

## Resolved trip and mode

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md`

## Existing outputs

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"/*/outputs`

## What was asked for

- Agent key: `$1`
- Full arguments: `$ARGUMENTS`

The key is the first whitespace-delimited token. The research request is
everything after it.

## The agent key

The valid keys are **derived from the first block, not listed here**: take each
filename, drop the `.md`, and drop a leading two-digit `NN-` prefix where there
is one. So `05-hub-planner.md` yields `hub-planner`, and
`destination-ideation.md` yields `destination-ideation`. Nothing that is not in
that block is a key.

Deriving them means a tenth agent added to `agents/` is addressable the day it
lands, with no edit here and no second list to fall out of date.

**Matching a key is a lookup, never a classification.** Compare the token
literally against the derived set. Do not read the request text to decide which
agent it implies, and do not accept a near miss as the key it resembles.

## Resolve before dispatching

`trips/README.md` is a tracked signpost, not a trip. Every other entry in the
second block is a trip directory.

Resolve exactly one case below, in order. Every case that says stop, stops —
nothing is dispatched, nothing is written.

### No key, or a key that is not in the set

Say which token was not recognised, print the valid keys exactly as the first
block yields them, and stop. Never guess the agent, and never fall back to
running the whole pipeline.

### No trip yet

The third block produced no `Current mode:` or `Primary destination:` line —
either no trip directory exists, or the pattern matched nothing.

Say plainly that no trip exists yet, and name `/trip-new` as the command that
creates one. Stop.

### More than one trip

The third block carries more than one path prefix.

List each resolved trip with its destination and its mode, then ask which one
the user means. Do not guess, and do not pick the most recently modified.

### A trip whose mode is unset

A path prefix appears in the third block but carries no `Current mode:` line.

Name the trip, say its mode is unset, and point at
`templates/trip-context.template.md` for the field's shape and its permitted
values. Stop — the modes table governs what a spoke is meant to produce, so a
spoke dispatched without a mode is producing against nothing.

### Exactly one trip, mode set, key valid

Proceed.

## What to read

`CLAUDE.md` is already loaded — its agent roster is in context. Use the roster's
`Output File` column to resolve **the one** output file this key writes.

Read exactly these four things:

1. `trip-context.md` for the resolved trip.
2. `trip-log.md` for the resolved trip.
3. The one output file the roster names for this key.
4. The key's own prompt file under `agents/`.

**Read no other output file, and do not read `travelers/` or the site HTML.**
Targeted research is a scoped request, and the request-type context table scopes
its read to exactly those files. Reading the whole trip state here is the
over-read this command exists to remove — one output file, not all of them.

If the fourth block shows the roster's output file is not there yet, say so and
create it as part of the dispatch below. **Do not escalate to `/trip-plan`** — a
first research pass on a topic is not a reason to run the full pipeline.

## Dispatch

State three things before dispatching: the trip, the agent the key resolved to,
and the one output file being appended to.

Then make **one** `Task` call with `model: "opus"`, passing the agent prompt
file's content as that agent's instructions and the files above as its context.
Pass the request text through as the targeted prompt — do not re-scope it into a
broader question than the one asked.

One key, one agent, one call. This command does not chain into the hub planner
and does not run the validator.

## Persist

Follow the output-versioning rules already in `CLAUDE.md`:

- **Append** to the existing output file under a new dated section header naming
  what this pass covered. Never delete or rewrite what is already there — the
  hub reads the full accumulated file, and earlier entries stay as context and
  alternatives.
- Where the file was absent, create it with that same dated section header.

Then append a session line to `trip-log.md`, scaled to the session per the
Session Protocol: what was researched, which agent produced it, and anything the
user decided or ruled out along the way.

This command never runs `scripts/publish-trip-site.sh` in any form, and never
sets `ALLOW_PLAINTEXT`.
