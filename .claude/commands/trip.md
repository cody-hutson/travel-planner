---
description: Where the trip stands and what you can do next. Read-only; changes nothing.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*)
disallowed-tools: [Write, Edit, NotebookEdit]
---

# Trip orientation

Takes no arguments. Resolves the active trip and its mode, then states what is
available and what comes next. It changes nothing: no file is written, no agent
is dispatched, no script is run.

## Trips in this repo

!`ls -1 ${CLAUDE_PROJECT_DIR}/trips`

## Resolved trip and mode

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*' ${CLAUDE_PROJECT_DIR}/trips/*/trip-context.md`

## What to do with this

Both blocks above have already run and their output is above. **That output is
the whole of the trip state you have read, and it is the whole of the trip state
you need.** Do not read `trip-context.md` in full, and do not read `trip-log.md`
or anything under `outputs/`. Orientation is trip and mode, not trip state.

`trips/README.md` is a tracked signpost, not a trip. Every other entry in the
first block is a trip directory.

Resolve exactly one case from the second block, then render it.

### No trip yet

The second block produced no `Current mode:` or `Primary destination:` line —
either no trip directory exists, or the pattern matched nothing.

Say plainly that no trip exists yet, and name `/trip-new` as the command that
creates one. Do not offer to scaffold a trip from here.

### Exactly one trip

Every line of the second block shares one path prefix.

State, in this order:

1. The trip — its directory name and its `Primary destination` value.
2. Its `Current mode`, with one line on what that mode covers.
3. What is available next, per **Naming what is available** below.

Resolve all three without asking the user to name the trip or the mode.

### More than one trip

The second block carries more than one path prefix.

List each resolved trip with its destination and its mode, then ask which one
the user means. Do not guess, and do not pick the most recently modified.

### A trip whose mode is unset

A path prefix appears in the second block but carries no `Current mode:` line.

Name the trip, say its mode is unset, and point at
`templates/trip-context.template.md` for the field's shape and its permitted
values. Never infer a mode from the destination, the outputs, or anything else.

## Naming what is available

`CLAUDE.md` is already loaded — its request-type table, its agent roster and its
modes table are all in context. **Name them from context. Do not read the file
again.**

Name the request types that are available and the agents that serve them:

- Where a request type is served by a command, name that command.
- Where it is not, describe the action from the type's own row.
- Where a type is served by an agent, name the agent as the roster names it.

Then use the resolved mode to say which of those are in scope right now — the
modes table states what each mode runs. Lead with those; keep the rest brief.

## Publishing

The publish request types govern here, and this command follows them rather than
restating them:

- Where a publish type is served by a command, name that command.
- Where a publish type is marked as excluded, print the matching terminal command
  from the `Publishing to GitHub Pages` section for the operator to run
  themselves, and say why it is theirs to run rather than yours.

This command never runs `scripts/publish-trip-site.sh` in any form, and never
sets `ALLOW_PLAINTEXT`.
