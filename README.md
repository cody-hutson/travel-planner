# Travel Planner

A multi-agent trip planning system. Nine specialized agents research, plan, validate, and produce travel itineraries.

## Folder Structure

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Operating instructions for Claude Code |
| `agents/` | Behavioral definitions for the 9 agents (destination-ideation, enrichment, activities, food, nightlife, scheduling, transport, hub-planner, validator) |
| `templates/` | `trip-context.template.md` — copy this when starting a new trip. `traveler-intake.template.md` — one per traveler; a self-guiding profile of what each person needs and wants |
| `reference/` | `data-model.md` — how trip and per-traveler data is structured and reconciled; `site-layout-spec.md` — implementation spec for the published travel site; `adr/` — architecture decision records |
| `scripts/` | `publish-trip-site.sh` — encrypt + privately publish a trip site; `test-publish-guard.sh` — guard regression tests |
| `examples/` | Worked examples (sanitized real trips). See `examples/tokyo-2026/` |
| `trips/` | Per-trip working directories — contents git-ignored, never published; only its `README.md` signpost is tracked |

## Install

This is a [Claude Code](https://claude.com/claude-code) project — there's nothing to build or install into your system. You clone it and open it in Claude Code, which drives the planning flow per [`CLAUDE.md`](CLAUDE.md). It works the same in the **desktop app** and the **CLI**.

### Prerequisites

**To plan a trip:**

- [Claude Code](https://claude.com/claude-code) — desktop app or CLI
- `git` — to clone this repo

**To publish a trip site** (optional — only when you want to share a finished itinerary):

- [Node.js](https://nodejs.org) — provides `npx`, which runs StatiCrypt (`staticrypt@3.5.4`) for encrypt-at-publish
- [`gh`](https://cli.github.com) (GitHub CLI), authenticated — run `gh auth login` once

### What running this costs

Not what the trip costs — what the *engine* costs to run. Planning happens inside Claude Code, so what you spend is model usage on whatever Claude Code plan you already have. This repo can't see your billing and collects no usage data, so what follows is an order of magnitude, not a price; any figure printed here would be wrong the next time plans or model pricing moved.

Nearly all of it is agent dispatches, and [`CLAUDE.md`](CLAUDE.md) already sorts every request by how many it needs. **Building the first full plan is the expensive operation** — the whole pipeline runs (enrichment, five research agents, the hub planner, the validator, plus a remediation pass if the validator finds something critical), several of those agents do live web research, and all of them run on the top model tier, which is a deliberate choice rather than a place the engine economizes. Treat it as one sitting, not a background job. The first site build is a second pass of the same kind — a bespoke design artifact, not a template fill.

**Everything after that is one to two orders of magnitude cheaper**, and it is what an active trip actually consumes. A direct edit, a quick lookup or a site tweak dispatches no agents at all; Claude reads the one file and changes it. Targeted research ("more dinner options near the hotel") dispatches a single agent and appends to what is already there. A structural change, like swapping two days, re-runs only the affected agents plus a hub patch. Updating a published site patches the affected sections instead of regenerating them, and the publish step itself is shell plus `npx` — no model in the loop.

The gap is deliberate: the operating instructions make the lightest action that matches the intent the default, so re-running the food agent to fix a typo is something the engine is explicitly told not to do. What genuinely varies is how much research a destination needs and how many rounds you iterate before a plan feels right — both scale that first pass; neither changes the ratio.

### Install steps

```bash
git clone https://github.com/cody-hutson/travel-planner
cd travel-planner
```

Then open the folder in Claude Code:

- **Desktop app** — open the `travel-planner` folder
- **CLI** — run `claude` from inside the `travel-planner` directory

Start a trip with `/trip-new` — it scaffolds the trip directory, `outputs/`, `travelers/`, `trip-context.md` and `trip-log.md`, then walks you through the details. Every session after that opens with `/trip`, which resolves the active trip and its mode and says what's available next. Each trip lives in `trips/<destination>-<year>/`: `trip-context.md` is the source of truth, `trip-log.md` bridges multiple planning sessions, `travelers/` holds one profile per person, and `outputs/` accumulates agent artifacts.

### Traveler profiles

Each person travelling gets their own profile, copied from `templates/traveler-intake.template.md` into `trips/<destination>-<year>/travelers/`. It captures what someone **needs** (the constraints a plan has to stay inside — heat, mobility, diet, rest) separately from what they **want** (desires the plan tries to land within those bounds), plus their leanings, dates, budget, journey, lodging and party.

The form is **self-guiding**: a ⭐-marked set of about ten fields gives a two-to-three minute first pass, and an interview appendix travels with the file — hand the whole thing to any assistant, say "help me fill this out," and it interviews you section by section and returns just the completed profile. Nothing is compulsory; a missing profile is handled as *unknown*, never as *no constraints*.

Profiles carry real personal detail, so they live only in the git-ignored `trips/` working directory and are never published.

### Verify

Confirm the engine cloned intact:

```bash
ls agents/            # 9 agent definitions
ls .claude/commands/  # 9 command definitions
head -1 CLAUDE.md     # operating instructions present
```

If you intend to publish, confirm the publish toolchain is ready:

```bash
node --version    # Node.js present (provides npx → StatiCrypt)
gh auth status    # GitHub CLI authenticated
```

## Agent Roster

| Agent | Role |
|---|---|
| Destination Ideation | Turns the group's leanings into a ranked shortlist — produces `destination-shortlist.md` |
| Enrichment | Destination specialist — fills in trip-context `[ENRICH]` fields; reconciles traveler profiles into `traveler-model.md` |
| Activities | Activity finder — produces `activities-list.md` |
| Food | Food writer — produces `food-list.md` |
| Nightlife | Going-out curator — produces `nightlife-list.md`; desire-gated, never force-scheduled |
| Scheduling | Itinerary architect — produces `scheduling-framework.md` |
| Transport | Logistics — produces `transport-brief.md` |
| Hub Planner | Synthesis director — produces final itinerary + reference files |
| Validator | Pre-departure audit — produces `validation-report.md`; enforces the fail-closed checks, including that no non-publishable profile field reaches a published artifact |

Full agent dispatch protocol, mode definitions, output versioning rules, and site generation guidance are in [`CLAUDE.md`](CLAUDE.md).

## Publishing a Trip Site

When an itinerary is ready, Claude produces a single self-contained HTML file and publishes it **private-by-default** — the site is encrypted (StatiCrypt, AES-256-CBC + HMAC-SHA256) before anything reaches the web, and only the ciphertext is pushed to a per-trip public GitHub repo with Pages. Visitors get a passphrase prompt and decrypt in-browser, so free hosting still works and the plaintext itinerary never leaves your machine.

```bash
scripts/publish-trip-site.sh publish   trips/<destination>-<year>            # encrypt + publish
scripts/publish-trip-site.sh publish   trips/<destination>-<year> --opaque   # ...with an opaque repo name
scripts/publish-trip-site.sh update    trips/<destination>-<year>            # re-publish after edits
scripts/publish-trip-site.sh rotate    trips/<destination>-<year>            # change the passphrase
scripts/publish-trip-site.sh list                                           # inventory every trip's publish state
scripts/publish-trip-site.sh unpublish trips/<destination>-<year>           # take the site down (deletes the repo)
```

The passphrase is saved to `trips/<destination>-<year>/.passphrase` (git-ignored) — share it over a private channel. Security rests on passphrase strength plus a 600k-iteration KDF (the published bytes are public ciphertext, not an access-controlled page), so use a strong one.

**Metadata privacy.** By default the per-trip repo is named `<destination>-<year>-trip` and is public, so the destination and year are visible even though the itinerary is encrypted (commit timestamps also reveal when you publish). Pass `--opaque` to name the repo with a random token instead (e.g. `trip-a1b2c3d4e5`); it's saved to `.publish-slug`, so `update`/`rotate`/`unpublish` resolve the same repo. You can still set your own name in `trips/<destination>-<year>/.publish-slug` (a shared, shorter, or custom name).

**Lifecycle.** `list` prints a read-only inventory of every trip under `trips/` — repo, live URL, and a stale flag when your local build is newer than what's deployed. It runs without `gh`; the publish-state columns stay blank until you `gh auth login`. `unpublish` takes a site down: by default it deletes the per-trip repo (irreversible; needs the `delete_repo` gh scope and a typed confirmation), or `--disable-pages-only` keeps the repo and just takes the site offline (reversible). Takedown does not guarantee removal from third-party caches or clones.

To publish fully public instead, run `scripts/publish-trip-site.sh publish trips/<destination>-<year> --plaintext` yourself in a terminal — it asks you to type `PUBLISH` to confirm, and that confirmation is the only guard on the unencrypted path. Full flow in [`CLAUDE.md`](CLAUDE.md).

## License

[Business Source License 1.1](LICENSE) — permits non-production / personal / educational / internal-business use; commercial offerings require alternative licensing arrangements (contact the owner). Automatic conversion to Apache License 2.0 on 2030-05-27.
