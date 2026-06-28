# Travel Planner

A multi-agent trip planning system. Seven specialized agents research, plan, validate, and produce travel itineraries.

## Folder Structure

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Operating instructions for Claude Code |
| `agents/` | Behavioral definitions for the 7 agents (enrichment, activities, food, scheduling, transport, hub-planner, validator) |
| `templates/` | `trip-context.template.md` — copy this when starting a new trip |
| `reference/` | `site-layout-spec.md` — implementation spec for the published travel site |
| `scripts/` | `publish-trip-site.sh` — encrypt + privately publish a trip site; `test-publish-guard.sh` — guard regression tests |
| `examples/` | Worked examples (sanitized real trips). See `examples/tokyo-2026/` |
| `trips/` | Per-trip working directories (git-ignored — never published) |

## Install

This is a [Claude Code](https://claude.com/claude-code) project — there's nothing to build or install into your system. You clone it and open it in Claude Code, which drives the planning flow per [`CLAUDE.md`](CLAUDE.md). It works the same in the **desktop app** and the **CLI**.

### Prerequisites

**To plan a trip:**

- [Claude Code](https://claude.com/claude-code) — desktop app or CLI
- `git` — to clone this repo

**To publish a trip site** (optional — only when you want to share a finished itinerary):

- [Node.js](https://nodejs.org) — provides `npx`, which runs StatiCrypt (`staticrypt@3.5.4`) for encrypt-at-publish
- [`gh`](https://cli.github.com) (GitHub CLI), authenticated — run `gh auth login` once

### Install steps

```bash
git clone https://github.com/cody-hutson/travel-planner
cd travel-planner
```

Then open the folder in Claude Code:

- **Desktop app** — open the `travel-planner` folder
- **CLI** — run `claude` from inside the `travel-planner` directory

Tell Claude you want to plan a trip and the conversation takes over. Each trip lives in `trips/<destination>-<year>/`: `trip-context.md` is the source of truth, `trip-log.md` bridges multiple planning sessions, and `outputs/` accumulates agent artifacts.

### Verify

Confirm the engine cloned intact:

```bash
ls agents/        # 7 agent definitions
head -1 CLAUDE.md # operating instructions present
```

If you intend to publish, confirm the publish toolchain is ready:

```bash
node --version    # Node.js present (provides npx → StatiCrypt)
gh auth status    # GitHub CLI authenticated
```

## Agent Roster

| Agent | Role |
|---|---|
| Enrichment | Destination specialist — fills in trip-context `[ENRICH]` fields |
| Activities | Activity finder — produces `activities-list.md` |
| Food | Food writer — produces `food-list.md` |
| Scheduling | Itinerary architect — produces `scheduling-framework.md` |
| Transport | Logistics — produces `transport-brief.md` |
| Hub Planner | Synthesis director — produces final itinerary + reference files |
| Validator | Pre-departure audit — produces `validation-report.md` |

Full agent dispatch protocol, mode definitions, output versioning rules, and site generation guidance are in [`CLAUDE.md`](CLAUDE.md).

## Publishing a Trip Site

When an itinerary is ready, Claude produces a single self-contained HTML file and publishes it **private-by-default** — the site is encrypted (StatiCrypt, AES-256-CBC + HMAC-SHA256) before anything reaches the web, and only the ciphertext is pushed to a per-trip public GitHub repo with Pages. Visitors get a passphrase prompt and decrypt in-browser, so free hosting still works and the plaintext itinerary never leaves your machine.

```bash
scripts/publish-trip-site.sh publish trips/<destination>-<year>   # encrypt + publish
scripts/publish-trip-site.sh update  trips/<destination>-<year>   # re-publish after edits
scripts/publish-trip-site.sh rotate  trips/<destination>-<year>   # change the passphrase
```

The passphrase is saved to `trips/<destination>-<year>/.passphrase` (git-ignored) — share it over a private channel. Security rests on passphrase strength plus a 600k-iteration KDF (the published bytes are public ciphertext, not an access-controlled page), so use a strong one. Note: the per-trip repo name (`<destination>-<year>-trip`) is public, so the destination and year are visible even though the itinerary is encrypted — put a different name in `trips/<destination>-<year>/.publish-slug` to publish to a custom or pre-existing repo (a shared, shorter, or opaque name). To publish fully public instead, pass `--plaintext` (with `ALLOW_PLAINTEXT=1` for non-interactive runs). Full flow in [`CLAUDE.md`](CLAUDE.md).

## License

[Business Source License 1.1](LICENSE) — permits non-production / personal / educational / internal-business use; commercial offerings require alternative licensing arrangements (contact the owner). Automatic conversion to Apache License 2.0 on 2030-05-27.
