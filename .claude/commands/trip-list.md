---
description: Inventory every trip and whether its site is published, live and current. Read-only; changes nothing, locally or on GitHub.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(scripts/publish-trip-site.sh list:*)
disallowed-tools: [Bash(scripts/publish-trip-site.sh publish:*), Bash(scripts/publish-trip-site.sh update:*), Bash(scripts/publish-trip-site.sh rotate:*), Bash(scripts/publish-trip-site.sh unpublish:*), Bash(bash:*), Bash(sh:*), Write, Edit, NotebookEdit]
---

# Published-site inventory

Takes no arguments. Lists every trip in this repo alongside its per-trip repo
name, whether a site is live, when it was published, when the local build was
last edited, and whether the live site has fallen behind.

**It reads.** No file is written, nothing is pushed, no repo is created, changed
or deleted, and no passphrase is read, generated or printed. This is the one
command in the publish family whose effect on the world is nothing at all.

## Trips in this repo

!`ls -1 ${CLAUDE_PROJECT_DIR}/trips 2>&1`

## The invocation

Run exactly this, once:

```
scripts/publish-trip-site.sh list
```

**Run it from the repo root.** The subcommand scans `./trips/` relative to the
working directory and refuses with a clear message if `./trips` does not resolve
there — it is not a failure of the trip, it means the command ran somewhere
else. The block above resolves the project directory explicitly; if its output
and the working directory disagree, say so rather than retrying blind.

It takes no arguments. Do not pass it a trip directory, and do not run it once
per trip — one invocation covers the whole repo.

## What the output means

Six columns, and two of them are the ones worth reading carefully:

| Column | Reading |
|---|---|
| `TRIP` | the trip directory under `trips/` |
| `REPO` | the per-trip public repo name this trip publishes to |
| `STATUS` | `live` · `not published` · `-` when GitHub could not be reached |
| `PUBLISHED` | the date of the newest commit on the live site |
| `EDITED` | the date the local site build was last written |
| `STALE` | `⚠ stale` when the local build is newer than what is live |

`-` in `STATUS` and `STALE` means **indeterminate**, not negative. Report it that
way. A trip whose publish state could not be determined is not a trip that is
unpublished, and saying so would be a fabricated fact.

## Cases to resolve from the output

**No trips.** The subcommand says so plainly. Name `/trip-new` as the command
that creates one and stop.

**GitHub unreachable or unauthenticated.** The subcommand warns and still prints
the local inventory, with the three GitHub-derived columns blank. Say which half
of the answer is missing and name `gh auth login` as what restores it. Do not
present the local half as the whole picture.

**A trip marked `⚠ stale`.** The live site is behind the local build. Name
`/trip-update` as the command that re-publishes it, and stop there — that is a
different request and it is not this command's to make.

**A trip with no site built yet.** `EDITED` is blank. Name `/trip-site` as the
command that builds one.

## What this command never does

It never runs any other subcommand of the publish script. First publish,
passphrase rotation and repo deletion are **declared exclusions** of the command
surface — `reference/adr/ADR-007-command-entry-point.md` §4 records each form
with its reason, and the surface declines those forms rather than substituting
itself for a human at a terminal. Where one of them is the intent, the terminal
handoff still applies: run the script yourself, from the repo root.

It also never reads trip content. Its assigned context is the trip directory
path and nothing inside it — no `trip-context.md`, no itinerary, no traveler
profiles. The inventory it prints comes from the subcommand, not from opening
files.

## Afterwards

Present the table as it came back, then say in one line what stands out — a
stale site, a trip with no site, a publish state that could not be resolved.
Name the command that would address it. Do not run it.
