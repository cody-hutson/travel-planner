---
description: Build the travel site for this trip from the current plan. Generates a site; never patches one, never publishes one.
argument-hint: [design direction]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), Edit, NotebookEdit]
---

# Site generation

Builds the trip's travel site: one self-contained HTML file, designed for this
destination, assembled from the plan as it currently stands.

**It generates.** It does not patch an existing site, and it does not publish
one. Both of those are different request types with their own rules, and this
command names them rather than doing them.

Takes an optional `[design direction]` — `warmer tones`, `more editorial`, `less
dense`. The argument frames the aesthetic. It is text: it is never executed, it
does not select the trip, and it does not widen what this command reads.

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"`

## Resolved trip and mode

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md`

## Existing outputs

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips"/*/outputs`

## Resolve before building

All three blocks above have already run and their output is above. Resolve the
trip from them — do not list `trips/` again, and do not open a trip's files to
work out which one is meant.

`trips/README.md` is a tracked signpost, not a trip. Every other entry in the
first block is a trip directory.

**The resolving field here is `Primary destination`, not the mode.** A site is
built for a destination and its filename carries that destination, so a trip
without one has no subject and no filename. The mode does not gate this command:
a site is built from whatever the plan currently holds, at any mode.

**Read that field's value, never its presence.** `trip-context.md` is scaffolded
from the template, so a trip that has settled nothing still carries the line — it
reads `[City, Country]`. A bracketed value means the destination is unset;
anything else is a destination. Resolving on the line's presence takes a
scaffolded trip past the case below and builds site content out of placeholder
text. Binding rule: `reference/adr/ADR-007-command-entry-point.md` § 2.

Resolve exactly one case below, in order. Every case that says stop, stops —
nothing is read further and nothing is written.

### No trip yet

The second block produced no `Current mode:` or `Primary destination:` line —
either no trip directory exists, or the pattern matched nothing.

Say plainly that no trip exists yet, and name `/trip-new` as the command that
creates one. Stop.

### More than one trip

The second block carries more than one path prefix.

List each resolved trip with its destination, then ask which one the user means.
Do not guess, and do not pick the most recently modified.

### A trip with no destination set

A path prefix appears in the second block and its `Primary destination:` line
still reads the template's bracketed placeholder — or the line is missing
altogether.

Name the trip, say the destination is unset, and point at `trip-context.md` as
the file that carries it. Stop — there is no destination to design for and no
name to write the file under.

### Exactly one trip, with a destination

Proceed. Name the resolved mode in passing, so the user knows which stage of the
plan the site is being built from, then continue.

## What this command reads

Four content sources, and they are the whole of the trip content this command
reads:

| Source | What it supplies |
|---|---|
| `outputs/final-itinerary.md` | primary content — the days and what is in them |
| `outputs/links-reference.md` | venue URLs, for maps and links |
| `outputs/venue-matrix.md` | day assignments |
| `trip-context.md` | group, dates and constraints, for the hero |

**Read those four and stop there.** Do not read `trip-log.md`. Do not read
`food-list.md`, `activities-list.md`, `nightlife-list.md`,
`scheduling-framework.md`, `transport-brief.md`, `validation-report.md`,
`traveler-model.md`, `event-status.md` or `satisfaction-metrics.md` — that
research reaches the site through `final-itinerary.md`, which is where the hub
already resolved it. Do not read `travelers/`: those files hold personal detail
that is never published, and the site is a publish-bound artifact.

The third block above already names which of these exist. Use it rather than
probing for them.

### When a source is missing

- **`final-itinerary.md` absent** — there is no plan to render. Say so, name
  `/trip-plan` as the command that produces one, and stop. Do not assemble a
  site out of the research files instead.
- **`links-reference.md` or `venue-matrix.md` absent** — say which one, and build
  without it. Maps and day assignments are degraded, not fatal; the itinerary
  still carries the days.
- **`trip-context.md` absent** — the trip is malformed. Say so and stop.

## The build

`CLAUDE.md` is already loaded. Its *Travel Site Generation* section — the design
principles, what a good site includes, and the build steps — is in context, and
it is the authority on what to produce. Follow it rather than restating it here.

Two repo-level references it points at, neither of which is trip content:

- `reference/site-layout-spec.md` — the implementation specification: responsive
  architecture, viewport-fit logic, the card system, booking indicators, and the
  mobile and desktop interaction patterns. **Read it, and follow it.**
- The *Site References* table — previous trip sites that set the quality bar.
  Read the one it names as design inspiration, not as a template to copy. Match
  or exceed it, and give this destination its own aesthetic.

Then design the destination's palette, its CSS-art landmark visuals and its
typography, and build the whole site as one self-contained HTML file — CSS
inline, Leaflet for maps, no build step and no framework. Fold the
`[design direction]` argument in here if one was given.

Write it to `outputs/<destination>-travel-site.html` in the resolved trip,
under the trip's own destination name.

## When a site already exists

The third block shows whether the trip already has a
`<destination>-travel-site.html`. If it does, resolve which of these the user
wants **before writing anything** — the two paths are not interchangeable.

**A rebuild — this command.** The plan has moved on enough that the site should
be built again from the current sources. Say plainly, before writing, that a
rebuild replaces the file, and that any design tweak that lives only in the
existing HTML and not in the plan will not survive it. Then build, and write.

**A patch — not this command.** Where the itinerary changed and the user wants
those changes reflected in the site they already have, the rule is to patch the
affected sections rather than regenerate, so approved design work survives and
the round-trip completeness check still holds. That is the *Updating the site*
procedure and it is a direct edit of the HTML. **This command does not patch**,
does not read the existing site, and does not edit it. Name the path and hand it
back.

**A visual tweak — also not this command.** "Make the colors warmer" against a
site that already exists is a site tweak: read that file, edit it, done. Do not
rebuild a site to change a colour.

The distinction is worth stating plainly, because getting it backwards is
expensive in both directions: a bespoke rebuild is a large piece of creative
work, and a patch is a small edit.

## Afterwards

Say what was built, name the file that was written, and state which of the four
sources were present and which were missing.

**This command does not write `trip-log.md`.** Its assigned read does not include
the log, and the built file is its own visible record. Where a build carried
decisions worth keeping, that is a context update and it is logged as one.

Then name what comes next without doing it: iterating on the design is a site
tweak, and putting the site online is a publish.

## Publishing

Publishing is a separate request type with its own rules, and this command
follows them rather than restating them.

This command never runs `scripts/publish-trip-site.sh` in any form, in any
subcommand, under any flag, and never sets `ALLOW_PLAINTEXT`. It produces the
HTML and stops there. Where the user wants the site online, hand off to the
publish request type — the publish rules govern who runs it and how.
