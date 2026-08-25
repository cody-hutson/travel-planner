---
description: Run the full agent pipeline for this trip.
argument-hint: [what to build or re-plan]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Task, Edit, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*)]
---

# Full pipeline

Builds the plan, or rebuilds it from scratch. Runs the whole pipeline in order:
**enrichment, then the spokes, then the hub, then the validator, then
remediation if the validator returns criticals.**

**Takes no agent keys.** The pipeline is fixed, and which spokes run inside it
follows from the trip's mode — never from how the request is worded. To re-run a
named agent against a change, use `/trip-replan`. To research one topic, use
`/trip-research`.

## Agents available

!`ls -1 "${CLAUDE_PROJECT_DIR}/agents"`

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"`

## Resolved trip and mode

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md`

## Existing outputs

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"/*/outputs`

## Traveler profiles

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"/*/travelers`

## What was asked for

Full arguments: `$ARGUMENTS`

Treat this as the framing for the run — what the user wants built, or what
prompted the rebuild. It does not select agents.

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
values. Stop — the mode is what selects the spoke set below, so there is nothing
to run until it is set.

### A mode this command does not serve

The resolved mode is `ITERATION` or `RESEQUENCING`.

Both are changes to a plan that already exists — the hub patches, it does not
re-synthesize from scratch. Say which mode the trip is in, say that this command
runs the whole pipeline and the mode calls for a patch instead, and name
`/trip-replan`. Stop.

### Exactly one trip, in a mode this command serves

Proceed.

## Which spokes run

**The resolved mode from the third block decides the spoke set, and nothing
else.** Do not read the request text to widen or narrow it. The modes table in
`CLAUDE.md` is already in context and is the authority on what each mode covers;
what follows is which agents that means dispatching here.

| Resolved mode | What runs |
|---|---|
| `IDEATION`, with `Primary destination` still reading its bracketed placeholder | Destination Ideation only — it aggregates the travelers' leanings into a ranked group shortlist for the group to decide from. No other agent runs, and the validator is skipped. |
| `IDEATION`, with `Primary destination` carrying a real destination | Activities, Food, Nightlife, Scheduling and Transport at overview level; the hub compares the options rather than committing to one. Validator skipped. |
| `DISCOVERY` | Every agent. Full pipeline. |
| `ENRICHMENT` | Every agent. Full pipeline, planning around the confirmed flights and lodging as fixed anchors. |

**Read that field's value, never its presence.** `/trip-new` scaffolds
`trip-context.md` from the template, so a trip that has settled nothing still
carries the line — it reads `[City, Country]`. Testing for a missing line finds it
present, takes the second row, and plans five spokes against placeholder text
while the one agent that branch exists to run never fires. A bracketed value is
the placeholder; anything else is a destination. Binding rule:
`reference/adr/ADR-007-command-entry-point.md` § 2.

Where the shortlist branch runs and the group then picks a destination, that is
a new invocation, not a continuation: set the destination, switch the mode to
`DISCOVERY`, and run this command again.

## Traveler profiles

The fifth block shows the per-traveler source files the enrichment agent
reconciles into the derived traveler model.

Where it shows none, or fewer than the trip has travelers, **say so before
dispatching and carry on** — a missing profile is a first-class path, not a
failure. Name `templates/traveler-intake.template.md` as the form a traveler
fills in, and state that enrichment will reconcile everyone who has a usable
profile, take operator-provided needs for any gap the user supplies, and
otherwise record a flagged gap and continue.

**An absent profile means unknown, never no constraints.** Do not treat a
traveler without a file as a traveler without needs.

## What to read

`CLAUDE.md` is already loaded — its agent roster, its modes table and its key
rules are in context.

Read `trip-context.md` and `trip-log.md` for the resolved trip, the prompt file
under `agents/` for every agent this run dispatches, and the outputs the
dispatch needs — enumerated from the fourth block rather than guessed at. That
is what the request-type context table assigns this row: `trip-context.md`,
`trip-log.md`, and the relevant outputs.

Do not read the site HTML. The enrichment agent reads `travelers/` as part of
its own job; that is its read, not a preload to do here.

## Dispatch

Run the stages in order, each as a `Task` call with `model: "opus"`, passing the
agent prompt file's content as that agent's instructions:

1. **Enrichment** — fills the `[ENRICH]` fields in `trip-context.md` and
   refreshes the derived traveler model from the per-traveler files.
2. **The spokes for the resolved mode**, in parallel where nothing serializes
   them.
3. **The hub planner** — builds the reference files first, then the day-by-day
   itinerary, reconciling the optimizer signals the spokes emitted. Pass it
   `outputs/event-status.md`; it is the primary writer of that file and the
   per-event rules are its to apply, not this command's.
4. **The validator**, except in the modes above that skip it.
5. **Remediation**, only where the validator returns criticals — re-dispatch the
   agents whose output the criticals name, then re-run the hub and the validator
   over what changed.

## Persist

Follow the output-versioning rules already in `CLAUDE.md`:

- Spoke outputs **append** under a new dated section header, and create the file
  where the fourth block showed it absent.
- `final-itinerary.md` is replaced, and **the version it replaces is preserved
  first**: read the current file, write its content to the next free
  `final-itinerary-v<N>.md`, then write the new synthesis. Preserve it by
  reading and writing — this command carries no tool that copies files, and it
  does not need one.
- `links-reference.md` and `venue-matrix.md` are rebuilt by the hub each
  synthesis pass, not appended to.
- `event-status.md` is updated in place and survives the run. A re-synthesis
  reads existing status; it does not overwrite it.

Then append a full session entry to `trip-log.md` per the Session Protocol — a
pipeline run is a planning session, so it earns the full entry: decisions and
their rationale, options rejected and why, new constraints surfaced, what the
user wants next, and what is still open.

This command never runs `scripts/publish-trip-site.sh` in any form, and never
sets `ALLOW_PLAINTEXT`. Building the site is `/trip-site`; publishing it is its
own request type, and the publish rules govern who runs it.
