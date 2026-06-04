# Travel Planner

A multi-agent trip planning system. Seven specialized agents research, plan, validate, and produce travel itineraries.

## Folder Structure

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Operating instructions for Claude Code |
| `agents/` | Behavioral definitions for the 7 agents (enrichment, activities, food, scheduling, transport, hub-planner, validator) |
| `templates/` | `trip-context.template.md` — copy this when starting a new trip |
| `reference/` | `site-layout-spec.md` — implementation spec for the published travel site |
| `examples/` | Worked examples (sanitized real trips). See `examples/tokyo-2026/` |
| `trips/` | Per-trip working directories (git-ignored — never published) |

## Using with Claude Code

This is a [Claude Code](https://claude.com/claude-code) project — it works the same in the **desktop app** and the **CLI**.

1. Clone this repo
2. Open it in Claude Code:
   - **Desktop app** — open the `travel-planner` folder
   - **CLI** — `cd travel-planner && claude`
3. Tell Claude you want to plan a trip — the conversation drives the flow per `CLAUDE.md`

Each trip lives in `trips/<destination>-<year>/`. The `trip-context.md` file in that directory is the source of truth; `trip-log.md` is the session bridge across multiple planning chats; `outputs/` accumulates agent artifacts.

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

When an itinerary is ready, the hub-planner produces a single self-contained HTML file. The publish flow (in `CLAUDE.md`) pushes that file to a per-trip public GitHub repo with Pages enabled — each trip site is a separate standalone repo independent of this engine.

## License

[Business Source License 1.1](LICENSE) — permits non-production / personal / educational / internal-business use; commercial offerings require alternative licensing arrangements (contact the owner). Automatic conversion to Apache License 2.0 on 2030-05-27.
