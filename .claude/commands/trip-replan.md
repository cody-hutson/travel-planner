---
description: Change the plan structure. Re-runs only affected agents.
argument-hint: [agent-key ...] [what to change]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Task, Edit, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*)]
---

# Planning change

Changes the structure of a plan that already exists — swap two days, add a day
trip, reschedule an afternoon, replace a booked-out venue. **Only the agents you
name re-run**, then the hub patches the itinerary and the validator re-checks
what changed.

## Agents available

!`ls -1 "${CLAUDE_PROJECT_DIR}/agents"`

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"`

## Resolved trip and mode

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md`

## Existing outputs

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"/*/outputs`

## What was asked for

Full arguments: `$ARGUMENTS`

## The agent keys

The valid keys are **derived from the first block, not listed here**: take each
filename, drop the `.md`, and drop a leading two-digit `NN-` prefix where there
is one. So `05-hub-planner.md` yields `hub-planner`, and
`destination-ideation.md` yields `destination-ideation`. Nothing that is not in
that block is a key.

Read the arguments positionally. The **leading run** of tokens that are members
of the derived set are the spokes to re-run. The **first token that is not a
member ends that run**, and everything from there on is the change being asked
for.

So `food scheduling move the Day 3 dinner later` re-runs the food and scheduling
agents against that change; `move the Day 3 dinner later` names no spoke at all.

**Matching a key is a lookup, never a classification.** Compare each leading
token literally against the derived set. Do not read the request text to decide
which agent it implies.

## When no spoke is named

Naming no spoke is a valid invocation, not a missing argument — and not a reason
to ask which agent was meant.

Run the fixed chain the modes table already prescribes for a change to an
existing plan: **the hub patches the itinerary, then the validator re-checks the
changed days.** No spoke re-runs.

Before dispatching it, say so plainly: name the chain being run, and print the
available keys, so a change that did want a spoke is visibly one token away.
That is a disclosure, not a confirmation prompt — say it and carry on; do not
wait for an answer.

## Resolve before dispatching

`trips/README.md` is a tracked signpost, not a trip. Every other entry in the
second block is a trip directory.

Resolve exactly one case below, in order. Every case that says stop, stops —
nothing is dispatched, nothing is written.

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
values. Stop — the modes table governs what each agent is meant to produce.

### Exactly one trip, mode set

Proceed.

## What to read

`CLAUDE.md` is already loaded — its agent roster and its modes table are in
context.

Read `trip-context.md` and `trip-log.md` for the resolved trip, the prompt file
under `agents/` for every agent this run dispatches, and the outputs the
dispatch actually needs — enumerated from the fourth block rather than guessed
at. That is what the request-type context table assigns this row:
`trip-context.md`, `trip-log.md`, and the relevant outputs.

Do not read `travelers/`, and do not read the site HTML.

## Dispatch

1. **Record the change** in the `## Mode` notes of `trip-context.md`. That is an
   orchestrator note about what is being changed and why. No activity, food, or
   itinerary content goes into that file — those have their own homes.
2. **Dispatch in order:** each declared spoke, then the hub planner, then the
   validator. Every one is a `Task` call with `model: "opus"`, passing the agent
   prompt file's content as that agent's instructions.

Pass `outputs/event-status.md` to the hub. **Do not evaluate event status
yourself.** Only `planned` events change freely; `locked` and `firmed` are
preserved unless the user has named them; an `option` is never promoted into a
primary slot on its own. Those rules are the hub's to apply — this command's job
is to make sure the hub has the file that carries them.

## Persist

Follow the output-versioning rules already in `CLAUDE.md`:

- Spoke outputs **append** under a new dated section header. Nothing already in
  them is deleted or rewritten.
- `final-itinerary.md` is replaced, and **the version it replaces is preserved
  first**: read the current file, write its content to the next free
  `final-itinerary-v<N>.md`, then write the new synthesis. Preserve it by
  reading and writing — this command carries no tool that copies files, and it
  does not need one.
- `links-reference.md` and `venue-matrix.md` are rebuilt by the hub each
  synthesis pass, not appended to.
- `event-status.md` is updated in place by the hub and survives the re-plan. It
  is never rebuilt from scratch and never versioned.

Then append a session entry to `trip-log.md` per the Session Protocol: the
change made and why, which agents re-ran, what was rejected, and what is still
open.

This command never runs `scripts/publish-trip-site.sh` in any form, and never
sets `ALLOW_PLAINTEXT`.
