# Travel Planner — Multi-Agent Trip Planning System

## What This Is

A multi-agent trip planning system. Nine specialized agents research, plan, validate, and produce travel itineraries. The agent prompts in `agents/` define deep behavioral profiles — destination specialist, food writer, nightlife curator, itinerary architect, logistics expert, synthesis director, and pre-departure auditor. Each produces a structured artifact. The hub synthesizes all artifacts into a final itinerary. The validator audits it before it's acted on.

## Agent Model Requirement

**All agent dispatches use Opus 4.6 (1M context) with maximum thinking budget. No exceptions.** When spawning agents via the Agent tool, always use `model: "opus"`. The quality of the research and synthesis depends on the model — this is not a place to economize.

---

## Session Protocol

Trip planning spans multiple chats over days or weeks. Files are the memory. Every session follows this protocol.

### Starting a session (any chat that touches a trip)

1. Read this `CLAUDE.md` (auto-loaded)
2. Read `trips/<destination>-<year>/trip-context.md` — the source of truth for what's planned
3. Read `trips/<destination>-<year>/trip-log.md` — the decision history and session bridge
4. Scan `trips/<destination>-<year>/outputs/` — know what exists and what's been produced

This is 30 seconds of file reads that prevents 10 minutes of "where were we?"

**Trip-directory placeholder.** Wherever these docs write `<destination>-<year>` — here, in the README, in the templates and in the agent prompts — substitute the trip's own folder name, as in `trips/tokyo-2026/`. Angle brackets mark a value you replace, following the `usage:` grammar in `scripts/publish-trip-site.sh`: angle for a required value, square for an optional element.

### Ending a session

**Scale the log entry to the session.** A quick site edit doesn't need a full decision register. A planning session with 5 decisions does.

- **Quick edits / lookups:** One-line entry in trip-log.md noting what was changed. Or skip the log entirely if the change is trivially visible in the file diff.
- **Planning sessions (decisions made, options discussed):** Full entry:
  - Decisions made this session (and rationale)
  - Options discussed and rejected (and why — this prevents re-litigating)
  - Any new preferences or constraints surfaced
  - What the user wants to do next
  - Current state of the plan (what's solid, what's still open)

### trip-log.md

Created alongside trip-context.md when a trip starts. Running decision register that grows across sessions. Structure:

```markdown
# Trip Log — [Destination] [Year]

## Session [Date]
**Topics:** [what was discussed]
**Decisions:**
- [Decision — rationale]
**Rejected:**
- [Option — why it was rejected]
**Next steps:** [what the user wants to do next session]
**Open questions:** [unresolved items]
```

This file is the primary session bridge. It captures what trip-context.md does not hold field by field: the reasoning behind choices, the options that were considered, and the conversational context that informs future decisions. The one field-scoped exception is Mode notes, which records the evidence for the current mode in the act that sets it; the log records why the session reached that decision and never restates that evidence line.

---

## Output Versioning — Never Lose Agent Work

**Agent outputs accumulate. They do not overwrite.**

When an agent re-runs (e.g., food agent runs again after the user asks for more options):
- **Append** new content to the existing output file with a dated section header
- **Never delete** previous research — the hub reads the full accumulated file
- Previous entries remain as context, alternatives, and history

Example: `food-list.md` after three sessions:
```markdown
# Food List — Lisbon

## Initial Research (2026-04-10)
[35 entries from first run]

## Targeted Update — Dinner Options Near Bairro Alto (2026-04-15)
[8 new entries addressing user's request for more dinner variety]

## Replacement Options — Day 3 Lunch (2026-04-18)
[4 alternatives after user rejected the original Day 3 lunch pick]
```

**Exception:** The hub's `final-itinerary.md` IS replaced on each synthesis (it's the assembled output, not research). But it uses version numbering: v1, v2, etc. Previous versions are preserved as `final-itinerary-v1.md`, `final-itinerary-v2.md`.

**Exception:** `links-reference.md` and `venue-matrix.md` are rebuilt by the hub on each synthesis pass (they reflect the current state of the itinerary, not research history).

### Satisfaction-layer artifacts

The satisfaction layer adds three `outputs/*.md` artifacts with their own lifecycles. Full rationale: `reference/data-model.md`.

- **`event-status.md` — persist-mutable (a fourth pattern).** Updated **in place** as events change status, and it **survives every re-synthesis** — never appended-with-history, never rebuilt from scratch, never versioned. It is the iteration-protection source of truth: a re-synthesis *reads* existing status, it does not overwrite it. This is the one artifact that must outlive a planning pass. The **hub is the primary writer** and owns it; the file is **created by whichever agent first writes it** — the enrichment agent's setup seed (from `## Locked Elements`), or the hub on the first full synthesis if no seed exists (the validator only reads it). Persist-mutable is not append-only — a row is **deleted** in the one case where its event is removed from the itinerary, so no ghost row lingers.
- **`traveler-model.md` — rebuilt/refreshed.** A `[DERIVED]` projection. The enrichment agent refreshes it from the current per-traveler source files (`travelers/<traveler>.md`) whenever those change. Every entry projected from a `travelers/<traveler>.md` file holds no independent state — that source file is authoritative — so regeneration is safe. **One stated per-entry exception:** the `[THIRD-PARTY]` entry admitted through the operator fallback has no source file by design, so it is carried forward verbatim rather than re-derived. The classification is unchanged.
- **`satisfaction-metrics.md` — rebuilt/refreshed.** Recomputed from the current itinerary and traveler model. A coverage snapshot at synthesis time; safe to regenerate because its inputs are authoritative. Two writers, **section-owned** so they never clobber: the **hub** owns the desire-coverage + balance-signal sections, the **validator** owns the needs-compliance + agreement-check sections, each read-merge-writing only its own.

---

## How to Use This (Claude Code as Primary Interface)

The user interacts conversationally. **Classify the intent before acting.** Not every request needs an agent. Most requests in an active trip are direct edits or quick lookups.

### Step 1: Classify the request

Before doing anything, determine what kind of request this is:

| Type | Signal | Action | Example | Command |
|------|--------|--------|---------|---------|
| **Orientation** | User is starting a session, or asks where the trip stands and what to do next | Resolve the active trip and its mode; state what is available and what comes next. Read-only — it mutates nothing. | "Where are we?", "What's the status?", "What can I do next?" | `/trip status` |
| **Direct edit** | User wants a specific change to an existing file | Read the file, make the edit, done. No agents. **While the trip is ACTIVE** — on an ARCHIVED trip the lightest-weight action is not the edit; `/trip-decommission reopen` comes first. | "Update the emojis on the site", "Fix the typo in Day 3", "Change the dinner time to 8 PM" | EXCLUDED: lightest-weight-action |
| **Quick lookup** | User asks about existing plan content | Read the relevant file(s), answer. No agents. **While the trip is ACTIVE** — on an ARCHIVED trip say so and name `/trip-decommission reopen`. | "What's our Day 5 plan?", "What still needs booking?", "What hotel are we at?" | EXCLUDED: lightest-weight-action |
| **Site tweak** | User wants visual/design changes to the HTML | Read the site HTML, edit directly. No agents. **While the trip is ACTIVE** — on an ARCHIVED trip the site is offline and the edit is not the next move; `/trip-decommission reopen` comes first. | "Make the colors warmer", "Add a section for packing list", "Fix the map on Day 2" | EXCLUDED: lightest-weight-action |
| **Context update** | User shares new information (booking, date change, preference) | Update trip-context.md and/or trip-log.md. No agents unless the change cascades. **While the trip is ACTIVE** — on an ARCHIVED trip `/trip-decommission reopen` comes first. | "We booked the hotel", "Mom can't do stairs", "Add a traveler's food allergy" | EXCLUDED: lightest-weight-action |
| **Destination ideation** | User is exploring where to go and no destination is chosen yet | Turns the group's leanings into a ranked shortlist (`outputs/destination-shortlist.md`) for the group to decide from. | "Where should we go?", "Give us some options for spring" | `/trip ideas` |
| **Targeted research** | User wants new options or deeper research on a specific topic | The relevant spoke agent produces targeted research on the topic and appends it to the existing output file. | "Find more dinner options near Bairro Alto", "What indoor activities exist near the hotel?" | `/trip research` |
| **Planning change** | User wants to change the itinerary structure (swap days, add a day trip, reschedule) | Mode notes in trip-context.md are updated. Only affected agents re-run. Hub patches itinerary. Only `planned` events change freely; `locked`/`firmed` events are preserved unless the user names them (see Key Rules → per-event status). | "Swap Day 3 and Day 4", "Replace the afternoon on Day 5 with something indoor" | `/trip replan` |
| **Day resequencing** | User wants the same selections kept but the days reordered | Mode advances to RESEQUENCING and is announced — see Modes for what runs. Only `planned` events move. | "Reorder the days", "Same plan, different day order" | `/trip reorder` |
| **Full pipeline** | User wants the initial plan built or a full re-plan | Runs the full agent pipeline (enrichment → spokes → hub → validator) | "Build the itinerary", "Start fresh on the plan" | `/trip plan` |
| **Plan audit** | User wants the existing plan checked without changing it | Runs the Validator alone against the current itinerary and reports findings. No spokes, no hub, no edits. | "Does the plan hold up?", "Check the itinerary for problems" | `/trip check` |
| **Site generation** | User wants the travel site built or rebuilt | See Travel Site Generation section | "Build the site", "Create the travel page" | `/trip site` |
| **Publish** | User wants to push to GitHub | See Publishing section | "Publish this", "Push to GitHub" | `/trip-publish update` |
| **New trip** | User wants to start a trip that does not exist yet | Scaffold the trip directory and its members and set the starting mode from what the user stated. Resumes, repairing only what is missing, when the slug already exists. | "Start planning Lisbon 2027", "New trip to Tokyo" | `/trip-new` |
| **Traveler profile** | User wants to create or update a traveler's own profile | Create the profile that does not exist, edit the one that does. Never invent a field — an unanswered field is a skipped field. | "Add Dana's profile", "Update my dietary needs" | `/trip-record profile` |
| **Third-party traveler** | A party member who will never file a profile, whose needs the operator supplies | Record the third-party entry and reconcile the derived traveler model. | "Add Mom — she can't do stairs", "Record Sam's constraints for him" | `/trip-record person` |
| **Roster reconciliation** | Traveler files changed and the derived model is behind them | Enrichment alone, in its reconciler role — never the research role. | "Re-sync the traveler model", "The profiles changed" | `/trip-record travelers` |
| **Destination hand-off** | The group has chosen a destination from the shortlist | Write the chosen destination into `trip-context.md`. The ideation agent never writes it itself. | "We picked Lisbon", "Go with option 2" | `/trip-record destination` |
| **Mode change** | The trip has moved to a different phase, or the mode is unset | Replace `Current mode` and `Mode notes` in one act, echoing the outgoing notes. This is the remedy an unset mode's refusal names. | "We've booked flights", "Set the mode to ITERATION" | `/trip-record mode` |
| **Group roster** | A traveler joins or leaves, or the party's shape changes | Edit the whole of `## Group` — roster table, total travelers, travel mode, subgroup notes. | "Sam's not coming", "Add two more people" | `/trip-record group` |
| **Trip fact capture** | User states a fact belonging in `trip-context.md` that no other verb owns | Route the statement to its block and write it there. The default-row verb. | "We booked the hotel", "Budget is 3000 euros" | `/trip-record fact` |
| **Publish slug** | User wants to set or change the published site's repo name | Create or replace `trips/<slug>/.publish-slug`, echoing the outgoing value so the change is reversible. | "Publish it as lisbon-trip", "Change the site name" | `/trip-record .publish-slug` |
| **Event status** | A placed event is booked, cancelled, or its hold changes | Change one named row's `Status` cell and recompute that row's derived needs-booking cell. Creates no row and no file. | "We booked the Belem tour", "The 8pm table fell through" | `/trip-record event` |
| **Session log entry** | A session's reasoning, options considered, or context belongs in the record | Append one entry to `trip-log.md`. Never re-opens a prior entry. | "Log what we decided", "Note why we skipped Sintra" | `/trip-record log` |
| **Published inventory** | User asks what is published, across trips | Report the published sites the script resolves. Needs no trip resolved. | "What's published?", "Which trips have sites?" | `/trip-publish list` |
| **Temporary takedown** | User wants the site offline but the trip kept | Disable Pages. The local tree is untouched and no marker is written. | "Take the site down for now", "Hide it temporarily" | `/trip-decommission temporary` |
| **Trip conclusion** | The trip is over and should be concluded | The takedown, then the lifecycle marker, then a closing log entry — in that order, and the order is load-bearing. | "The trip's done", "Archive Lisbon 2026" | `/trip-decommission archive` |
| **Trip reopen** | An archived trip needs to be worked on again | Return `**Lifecycle:**` to `ACTIVE`, echoing the outgoing value. | "Reopen Lisbon", "I need to change the archived trip" | `/trip-decommission reopen` |

**The default is the lightest-weight action that matches the intent.** Direct edits are direct edits. Don't dispatch agents to change an emoji. Don't re-run the food pipeline to fix a typo in a restaurant name. Don't re-synthesize the itinerary to update a booking confirmation code.

**When in doubt, ask.** "Do you want me to just edit that in the site, or should I re-run the food agent for new options?" is better than guessing wrong and re-running the whole pipeline.

### Step 2: Read context (scaled to the request)

**What a read is.** A read of a **PATH** is any filesystem observation — existence, readability, a directory probe — and is what a `Reads:` line declares. A read of a **VALUE** is contents reaching a channel, and is what Key Rules' standing rule 4 forbids. **The scope this table assigns is path scope**; no row of it names a value, and none can, because its unit is a path.

**Where the scope is declared.** For every command verb, the assignment is that verb's own `**Reads:**` line in its command file. **This table does not restate them** — a second statement of a read scope drifts from the first and nothing arbitrates it, which is the direction `ADR-007` §3 fixes. It assigns by citation, the way § *Resolving a trip* is cited rather than copied.

| Request | Read scope | Class |
|---|---|---|
| `/trip status` · `/trip-publish list` · `/trip-decommission temporary` | that verb's `**Reads:**` line | none beyond the pre-executed blocks |
| `/trip plan` · `replan` · `reorder` · `research` · `check` · `ideas` | that verb's `**Reads:**` line, **including its attributed-agent clause** | own + attributed-agent |
| `/trip site` | that verb's `**Reads:**` line | own |
| `/trip-record person` · `travelers` | that verb's `**Reads:**` line — the verb reads nothing of its own; the reconciler it dispatches reads | own + attributed-agent |
| `/trip-record profile` · `destination` · `mode` · `group` · `fact` · `.publish-slug` · `event` · `log` | that verb's `**Reads:**` line | own |
| `/trip-publish update` | that verb's `**Reads:**` line — a presence-and-readability probe is a read of the **path**, never of the value | own |
| `/trip-decommission archive` · `reopen` | that verb's `**Reads:**` line | own |
| `/trip-new` | **not yet declared** — that file carries no `**Reads:**` line; its reads are stated across its Gate and Create/Resume sections. **This row is a declared gap, not an assignment.** | own |
| Direct edit · Site tweak | just the file being edited | own |
| Quick lookup | the relevant output file(s) | own |
| Context update | `trip-context.md` | own |

Don't read the entire trip state for a CSS color change. Do read the full state when making planning decisions.

### Starting a new trip

When the user wants to plan a trip:
1. Create `trips/<destination>-<year>/`, `trips/<destination>-<year>/outputs/`, `trips/<destination>-<year>/travelers/`
2. Copy `templates/trip-context.template.md` to `trips/<destination>-<year>/trip-context.md`
3. Create `trips/<destination>-<year>/trip-log.md` with initial session entry
4. Fill in trip-context through conversation — ask the user questions, don't make them edit markdown
5. Set the mode based on what's known (IDEATION if exploring, DISCOVERY if destination picked, ENRICHMENT if flights/hotel booked)
6. Set up traveler intake — one profile per person at `trips/<destination>-<year>/travelers/<name>.md`, from `templates/traveler-intake.template.md`. Offer the assisted interview first, the self-serve copy second, and the portable hand-off third for travellers who aren't at this machine. Never invent a field — an unanswered field is a skipped field, and a missing profile is handled as *unknown*, never as *no constraints*.
7. In IDEATION with no destination yet, name **`/trip ideas`** as the next move — it turns the group's leanings into a ranked shortlist (`outputs/destination-shortlist.md`) for the group to decide from. Name it; do not dispatch **Destination Ideation** from here — dispatching an agent is a different request type with its own command and its own permissions. Once the group picks, the hand-off is two named invocations, in this order: **`/trip-record destination <chosen>`**, then **`/trip-record mode DISCOVERY`**.

### Dispatching agents (only when classification calls for it)

Read the relevant agent prompt from `agents/<name>.md` (see the roster below) and use it as context when producing that agent's output. For research-heavy agents (enrichment, validator), use web search. Always dispatch with Opus 4.6 1M, max thinking budget.

**Agent roster:**

| Agent | Prompt File | Output File | When to dispatch |
|-------|------------|-------------|-----------------|
| Destination Ideation | `agents/destination-ideation.md` | `outputs/destination-shortlist.md` | IDEATION with no destination chosen yet — aggregate travelers' leanings into a ranked group shortlist |
| Enrichment | `agents/00-enrichment.md` | Updates `trip-context.md` [ENRICH] fields | New trip setup, destination/hotel change |
| Activities | `agents/01-activities.md` | `outputs/activities-list.md` | User wants activity research or replacements |
| Food | `agents/02-food.md` | `outputs/food-list.md` | User wants food research or replacements |
| Nightlife | `agents/07-nightlife.md` | `outputs/nightlife-list.md` | User wants going-out research, or a full pipeline where a present traveler holds a nightlife/evening desire — the spoke resolves its own desire gate and writes a gate-result stub when nobody does |
| Scheduling | `agents/03-scheduling.md` | `outputs/scheduling-framework.md` | Structural schedule changes, resequencing |
| Transport | `agents/04-transport.md` | `outputs/transport-brief.md` | Transport questions requiring research |
| Hub Planner | `agents/05-hub-planner.md` | `outputs/links-reference.md`, `outputs/venue-matrix.md`, `outputs/final-itinerary.md`, `outputs/event-status.md` (primary writer), `outputs/satisfaction-metrics.md` (desire-coverage + balance sections) | Full synthesis or itinerary restructuring — **runs and reconciles the three optimizer engines** (routing vs. desire-coverage vs. experiential arc) into one itinerary, needs applied as hard constraints first (R1–R4) |
| Validator | `agents/06-validator.md` | `outputs/validation-report.md`, `outputs/satisfaction-metrics.md` (needs-compliance + agreement-check sections; reads `event-status.md`, never writes it) | After hub produces/updates itinerary |

**Pipeline flow (full pipeline only):** Enrichment → Spokes (parallel if possible) → Hub → Validator → Remediation (if criticals found). The Hub step is where the three optimizer-engine signals are **reconciled** into one itinerary — needs first as hard constraints, then routing / desire-coverage / experiential arc resolved by a documented policy (R3); the spokes only emit signals, they do not synthesize.

**For Agent tool calls:** Pass the agent's prompt file content as the agent's instructions. Include the trip-context.md, trip-log.md (for decision context), and any required input files as context. Write the output to the correct file path, following the output versioning rules.

### Modes

Read `trip-context.md` → Mode section to determine what's in scope.

| Mode | What's happening | What runs |
|------|-----------------|-----------|
| IDEATION | Exploring options, nothing decided | **No destination yet:** Destination Ideation aggregates travelers' leanings into a ranked group shortlist (`outputs/destination-shortlist.md`) to decide from. **Destination in play:** Activities, Food, Nightlife, Scheduling, Transport produce overview-level output; Hub compares options. Validator skipped. |
| DISCOVERY | Destination picked, nothing booked | Full pipeline. All agents run. |
| ENRICHMENT | Flights/hotel confirmed | Full pipeline. Agents plan around fixed anchors. |
| ITERATION | Existing plan, user wants changes — including a **disruption recovery**, triggered two ways: an event regressing `locked → planned` in `event-status.md` (a missed booking / cancelled hold) **or** a changed-profile delta (the enrichment agent's update signal that a traveler edited their file). | Only affected agents re-run. Hub patches itinerary. Validator re-checks changed days. Status honored: only `planned` events change freely; `locked`/`firmed` are preserved unless the user names them; `option` events stay alternatives. On a disruption recovery the hub runs its **equity-aware recovery** (per-traveler loss distribution → prioritize hardest-hit → re-run affected engines, needs preserved → regroup gaps under a coherent theme), and the validator runs its **recovery-equity check** (losses not concentrated; needs still hold). |
| RESEQUENCING | Keep selections, reorder days | Scheduling re-runs. Hub resequences. Validator checks new day-of-week assignments. Only `planned` events move; `locked`/`firmed` are fixed anchors; `option` events are not promoted into primary slots. |

### Resolving a trip

Every invocation that operates on a trip — a command, or a free-form request in chat — resolves it here, through one ordered gate ladder. **This section is the single normative statement of that ladder.** No command file, agent prompt or reference doc restates it; a consuming command file carries only the evidence blocks below plus a header block citing this section. `CLAUDE.md` is auto-loaded, so this text is already in context when a command body runs: it adds **no per-invocation read** (`ADR-007` §2, bound 1) and cannot be silently skipped.

**The canonical evidence list — declared once, here.** A consumer carries a **contiguous prefix** of it, byte-identical, from `E1` — and **exactly** the prefix its declared `contract-depth` requires, never a longer one; the exactness rule is stated with its reason below. `scripts/test-trip-resolution-contract.sh` extracts this list from this section, holds no copy of it, and asserts every consumer against it, so a divergent copy is a red check rather than a latent defect.

```trip-contract-evidence
E1  !`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`
E2  !`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*|^\*\*Lifecycle:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md 2>&1`
```

`2>&1` is **mandatory** on every entry, for a stated reason rather than an assumed one. It is **not** what makes G1's canary work — the canary fires on an empty block too, because `README.md` is not a line of an empty block. It is what makes a STOP **diagnosable**, and what removes any dependence on whether `!` pre-execution captures stderr by default, which this repo has not established. **E2 is expected to be error-shaped when the trip population is zero** — the glob does not expand and `grep` errors — so **when G2 resolves a zero population, E2 carries no information and is never read.** Grants are `Bash(ls:*)` for E1 and `Bash(grep:*)` for E2 and nothing wider (`ADR-007` §2, bound 2); `/trip-new` carries the E1-only prefix and correctly stays at `Bash(ls:*)`.

**The placeholder predicate — stated once, field-general.** A field whose **trimmed value begins with `[` and ends with `]` is a placeholder**, never an answer. It is applied by name to `**Current mode:**`, to `- **Primary destination:**`, and to any field a later slice adds. A placeholder is tested **by value**. **A missing line is a different condition — malformed — and is never the same branch** (`ADR-007` §2, bound 6, both halves).

**The gate ladder**, strictly ordered. **G1 and G2 bind all five commands** — `/trip`, `/trip-new`, `/trip-record`, `/trip-publish` and `/trip-decommission`. G3 and G4 bind any invocation operating on an **existing** trip. G5–G7 are per-verb. G8 is post-resolution.

- **G1 — listing trustworthiness.** `trips/README.md` is the only tracked file under `trips/`, so a healthy repo always lists it. **`README.md` must appear as an exact trimmed line of E1** — an exact line, not a substring, because a substring test also matches a trip directory whose name contains `README.md`. Absent → **STOP**: say plainly that the trip listing could not be read, name `trips/` as the directory that could not be listed, and **do not conclude that no trip exists — that conclusion is forbidden here.** An empty or error-shaped block is not evidence of an empty `trips/`. The `.gitignore` invariant the canary rests on (`trips/*` plus `!trips/README.md`) is itself guarded by `scripts/test-publish-guard.sh` **group K**.
- **G2 — trip population.** `trips[]` is **the lines of E1 minus the `README.md` line** — derived from E1, never from E2. Three terminal branches: **`0`** → name `/trip-new` as the way to create one, and **STOP**; **`1`** → that trip resolves; **`many`** → list each with its destination and mode from E2 and **ask which**, never guessing and never picking the most recently modified. **Where `--trip <slug>` was supplied it constrains the outcome rather than hinting at it: no member resolves unless it is the one named.** That rule is stated once, here, rather than inside each branch — the same constraint holds at every population, so no branch carries a copy of it to drift out of agreement with the others. Three outcomes: **exactly one member matches, case-folded** → that member resolves without asking, whatever the population; **more than one matches** → **STOP**, naming the supplied value and the members it matched; **none matches** → **STOP**, naming the supplied value and listing the members observed — unless `trips[]` is empty, where the **`0`** branch's own message and remedy already say everything a listing could. **Falling through to a branch is forbidden here**, and preventing it is what the rule is for: on a population of **`1`** the fall-through resolves the trip that is present while the user named a different one — the user named a trip and was silently given another, with no gate observing the conflict — and on **`many`** it re-asks a question the user has already answered. A `--trip` that cannot be honoured is a conflict the gate **did** observe, so it is typed as a STOP rather than reconciled into a resolution. `--trip <slug>` is a **contract-level token every command accepts and no verb may consume**, reserved here so adding it later is not an edit to five files. G2's dispositions are **declared per command, not improvised per file**, by `population-role`: **`RESOLVE`** is the default and the role of four commands, taking the three branches and the `--trip` rule exactly as written; **`CREATE`** is **`/trip-new` alone, the single declared exception** — it takes **no disposition from G2**, neither a branch nor the `--trip` rule, because `trips[]` is a collision set, `0` is its normal path, `many` is not an ask, and a `--trip` naming a slug no member carries is its ordinary input rather than a conflict. **That exception is bounded to G2's dispositions and reaches nothing else in this section:** a `CREATE` consumer carries the same header block, the same per-verb requirement table and the same `contract-depth` equality as every other consumer.
- **G3 — context integrity.** The resolved trip's path prefix must appear in E2. Absent → **STOP**: say that the trip's `trip-context.md` is missing or unreadable, and name the path. **This is the malformed condition, and it is never the same branch as any placeholder condition** (`ADR-007` §2, bound 6, second half).
- **G4 — lifecycle.** The `**Lifecycle:**` value for the resolved prefix, carried by E2's third alternation arm as a line in `trip-context.md`. Yields **`trip.lifecycle` ∈ {`ACTIVE`, `ARCHIVED`}**, and **an absent `**Lifecycle:**` line defaults to `ACTIVE`.** G4 does not itself stop: **an `ARCHIVED` trip does not resolve as active for any verb that does not declare `lifecycle: ARCHIVED` or `lifecycle: ANY`** in G7's table, and the disposition comes from that table. **Binding constraint: `templates/trip-context.template.md` must never ship a `Lifecycle:` placeholder.** The moment the field ships bracketed, bound 6 binds it and this default inverts from *absent ⇒ ACTIVE* to *absent ⇒ malformed*; absence is a legitimate default here only because no placeholder masks it.
- **G5 — mode, by value.** The `**Current mode:**` value for the resolved prefix. Four dispositions, and they are four different branches: **line absent** → **malformed, STOP**; **value is a placeholder** → **`UNSET`**, a legal state and **not** a stop; **value is one of the five modes** (IDEATION / DISCOVERY / ENRICHMENT / ITERATION / RESEQUENCING) → resolved; **anything else** → **unrecognised, STOP**. **The placeholder branch is the only one of the four that does not stop.** G5 does not dispose of `UNSET` at all: **an `UNSET` mode does not serve any verb whose G7 row does not admit it**, and the disposition comes from that table — the same shape G4 gives `ARCHIVED` and G6 gives `UNDECIDED`. **A verb that refuses on `UNSET` carries the remedy in its own refusal**, pointing at `templates/trip-context.template.md` for the field's shape and permitted values and naming `/trip-record mode` as what sets it. That is what makes the remedy reachable at all: `/trip-record` declares `contract-depth: G8` and so runs this gate, and `/trip-new`'s Resume branch repairs no existing `trip-context.md` — a halt at this gate would leave a bracketed mode a dead end for the whole surface, with the named remedy stopped by the very gate it exists to clear. **`UNSET` is not a sixth mode**: it names the absence of one, it holds no row in § *Modes*, and a verb reporting it says the mode is unset rather than describing what it covers. **Never infer a mode** — not from the destination, not from which files exist, not from the request's wording.
- **G6 — destination, by value.** The `- **Primary destination:**` value for the resolved prefix. Three dispositions, and the first two are not the same branch: **line absent** → **malformed, STOP**; **value is a placeholder** → **`UNDECIDED`**, a legal state and **not** a stop; **value is anything else** → decided.
- **G7 — mode-serves-verb.** A lookup in the consuming file's own per-verb requirement table, whose columns are **`verb` · `lifecycle` · `mode` · `destination` · `depth`**. Three dispositions: **`RUN`**; **`REDIRECT`** + stop, naming the command that does serve the request; **`REFUSE`** + stop, naming why the resolved state does not serve the verb. Three defaults carry the anti-drift weight — **a verb absent from the table is `REFUSE`, never `RUN`**, so the set is closed and a verb added by a later slice lands in the table or does not run; **an undeclared `lifecycle` is `ACTIVE`**, which is what makes an archived trip stop resolving as active for every existing and every future verb with no edit to this section; and **a requirement cell reading `any` admits the non-nominal state its own gate can yield — `UNSET` from G5, `UNDECIDED` from G6 — while a cell naming values admits only the values it names**, which is how `lifecycle: ANY` already reads `ARCHIVED`, and which is where a verb that must not run without a decided mode or destination says so: in its own row, naming what it serves, rather than by a halt at the gate that yielded the state. **`destination` is its own column rather than folded into `mode`** because at least one verb gates on destination and not on mode, so a single axis cannot express the surface.
- **G8 — derived-state freshness.** **Reserved, and report-only.** It is evaluated **after** resolution; it **never changes `trip.resolution`**; and **no gate may be added that blocks on freshness.** That is not a preference — this repo already recorded that an unconditional render-newer-than-model gate refuses every correct publish rather than more of them, and ends as a workaround rather than a guard. `trip.freshness` is a list of `(relation, verdict)` pairs. **Which relations a consumer evaluates is that consumer's own declaration**, made the way its per-verb requirement table is made; this section fixes their shape and the report-only rule above, never their membership.

**What the contract returns.** Resolution produces a typed record; downstream verbs branch on these fields instead of re-deriving them.

| Field | Values |
|---|---|
| `trip.resolution` | `RESOLVED` \| `STOPPED` |
| `trip.stop_gate` | the gate id that stopped, when `STOPPED` |
| `trip.slug` | the directory name **exactly as E1 spelled it** |
| `trip.path` | `trips/<slug>` |
| `trip.lifecycle` | `ACTIVE` \| `ARCHIVED` |
| `trip.mode` | one of the five \| `UNSET` — never a guess |
| `trip.destination` | the value \| `UNDECIDED` |
| `trip.freshness` | the `(relation, verdict)` pairs the consuming file declares |

**Every STOP is typed** with the gate id that produced it, in `trip.stop_gate`. **The stop-message rule:** a STOP **names what could not be established and the remedy**, and **never asserts a conclusion about trip state that the gate did not observe.** "Nothing is published, so there is nothing to take offline" is the shape this rule forbids — a conclusion about publication state derived from a directory listing that may have failed.

**How a command consumes this.** A command file carries the evidence prefix, then a fixed contract header block, then its verb-specific text. The header block's first line is the **citation line**, byte-identical across all five files:

```trip-contract-header
Contract: CLAUDE.md § Resolving a trip
contract-depth: <G0-G8, the deepest gate this file runs>
population-role: <RESOLVE or CREATE>
<the per-verb requirement table: verb · lifecycle · mode · destination · depth>
```

**`contract-depth` fixes the prefix a file carries, exactly.** Depth `G3` or deeper carries `E1 E2`; depth `G1`–`G2` carries `E1` alone; depth `G0` needs no trip and carries neither. The requirement is an **equality, not a minimum**: a file carrying **more** of the list than its declared depth requires is exactly as non-conforming as one carrying less, and `scripts/test-trip-resolution-contract.sh` grades both directions. The reason is `ADR-007` §2 bound 2 — every block a file carries is a grant it must hold, so a `G1`–`G2` consumer that quietly acquires `E2` needs `Bash(grep:*)` for a function it does not have, and `/trip-new`'s narrower `Bash(ls:*)` grant is only true while its prefix is `E1` **and nothing else**. Exactness is also what keeps byte-identity total: with no remainder past the declared length, **every** block a consumer carries is compared against the canonical rather than only a leading portion of them. `contract-depth` equals the maximum depth in that file's own verb table, whose **depth cell is the bare token `G0`–`G8`, optionally rendered as a code span** — `G8` and `` `G8` `` are the same value, which is how the consumer table below already renders them. **That tolerance is the depth cell's alone.** The header block's own `contract-depth:` line takes the **bare token and nothing else**; `` contract-depth: `G8` `` is not a depth declaration and is graded as an absent one. The asymmetry follows the rendered example each surface is copied from — the header block from the `trip-contract-header` fence above, which renders every one of its fields bare, and a verb table from the consumer table below, which renders every depth value as a code span — and it is stated here rather than left to be discovered. It is also what keeps the header block byte-exact: its citation line is asserted identical across all five files and `population-role:` admits `RESOLVE` or `CREATE` and no other rendering, so tolerating a second rendering of one field alone would make that block's discipline field-dependent for no gain. The five consumers:

| Command | `contract-depth` | `population-role` | Prefix | Note |
|---|---|---|---|---|
| `/trip-new` | `G2` | `CREATE` | `E1` | Its subject is a trip that does not exist, so G3 does not apply; keeps the narrower `Bash(ls:*)` grant |
| `/trip <verb>` | `G8` | `RESOLVE` | `E1 E2` | |
| `/trip-record` | `G8` | `RESOLVE` | `E1 E2` | |
| `/trip-publish` | `G8` | `RESOLVE` | `E1 E2` | its repo-wide listing verb declares depth `G0` on its own row — that verb needs no trip |
| `/trip-decommission` | `G8` | `RESOLVE` | `E1 E2` | its reopen verb declares `lifecycle: ARCHIVED` |

Duplicating the evidence blocks and the citation line is **forced by the platform** — the `!` mechanism fires only in a command file's own body and there is no include directive — so it is made safe by assertion rather than avoided. **No normative text is duplicated anywhere**, and the bytes that are duplicated are machine-asserted byte-identical on every push.

---

## Travel Site Generation

The travel site is a **bespoke creative artifact** — not a template fill. Each trip gets a unique site with destination-specific design, color theming, and visual identity. The site grows as the trip plan evolves.

### Design Principles

- **Destination-specific aesthetic.** Every site reflects its destination: color palette, landmark visuals, typography mood. Tokyo got Japanese red (`#BC002D`) with kana characters and torii-gate gradients. Lisbon would get Portuguese blue/azulejo tones. Paris would get something else entirely.
- **Editorial luxury quality.** High-end travel magazine feel. Not a data dump — a designed experience you'd want to browse on your phone at the airport.
- **Functional on the ground.** Sticky navigation, collapsible days, Google Maps links on every venue, booking checklist with progress tracking. It's a planning tool AND a reference tool during the trip.
- **Grows with the plan.** The site isn't generated once at the end. It's created when there's enough content and updated as the plan evolves. Early versions may be lighter. Final versions are comprehensive.

### What a good site includes

Based on the quality bar established by previous trips:
- Hero section with destination name, dates, group, key stats
- Trip overview dashboard with booking action tags per day
- Sticky day navigation with energy-level color coding and sub-text
- **Desktop: one day per viewport** — 4-column grid (schedule · highlights · food · map), auto-expand/collapse to fit any screen size
- **Mobile: progressive disclosure** — one day at a time, bottom nav, collapsible sections
- **Tablet: 3-column fallback** — map goes full-width at bottom
- Per-day sections: schedule timeline, featured stop cards (side-by-side, compact/expandable), food cards, transport notes
- **Booking status indicators** on every card (advance/ahead/walkup/open)
- **Transport field** on every card (mode + time from hotel)
- **Featured card enrichments**: insider tips, best timing, group-fit tags
- Heat/weather zone visualizations where relevant
- Leaflet maps in dedicated grid column (desktop) or tap-to-show (mobile)
- Interactive booking checklist sorted by action date with booking window rules
- Collapsible prep-boxes, transport-boxes, and warn-boxes on desktop
- Responsive across all screen sizes — viewport-fit JS adapts automatically
- CSS-art landmark visuals (not stock photos — pure CSS/SVG)
- Print styles (hide nav, maps, toggles; single-column)
- See `reference/site-layout-spec.md` for full implementation specification

### How to build it

When the user says "build the site" or "create the travel site":

1. **Read the content sources:**
   - `outputs/final-itinerary.md` (primary content)
   - `outputs/links-reference.md` (all venue URLs for maps/links)
   - `outputs/venue-matrix.md` (day assignments)
   - `trip-context.md` (group info, dates, constraints for the hero)

2. **Read reference sites for quality standard:**
   - Check the Site References section below for previous trip sites
   - Use them as design inspiration — not as templates to copy
   - Match or exceed the quality bar; adapt the aesthetic to the new destination

3. **Design the destination aesthetic:**
   - Choose a color palette that evokes the destination
   - Design CSS-art landmark visuals specific to the location
   - Select typography that fits the mood (editorial, elegant, destination-appropriate)

4. **Build the full HTML site** as a single self-contained file:
   - All CSS inline (no external stylesheets except Google Fonts)
   - Leaflet.js for maps (CDN link is fine)
   - No build step, no framework — one HTML file that works offline
   - Write to `outputs/[destination]-travel-site.html`
   - **Follow `reference/site-layout-spec.md`** for responsive architecture, viewport-fit logic, card system, booking indicators, and mobile/desktop interaction patterns

5. **Iterate with the user.** The first version won't be final. Expect:
   - Color tweaks ("more muted", "warmer tones")
   - Content additions as the plan evolves
   - Section reordering
   - New features for this specific trip

### Updating the site

When the itinerary changes (iteration mode, new bookings, swapped venues):
- Read the current site HTML
- Patch the affected sections — don't regenerate from scratch
- Preserve any design tweaks the user already approved
- After patching, run the round-trip completeness check (see `reference/site-layout-spec.md` §9 Plan/Site Single-Sourcing & Round-Trip Fidelity): every element in `final-itinerary.md` — every day and **every track of a split day** — still resolves to a rendered component or a named exclusion, so a patch never silently drops plan detail.

### Publishing to GitHub Pages

**Published trip sites are private-by-default.** A trip itinerary — dates, lodging, who you're travelling with — must not be world-readable. The publish flow encrypts the site before anything reaches the public per-trip repo, so only ciphertext is ever pushed. Free public Pages hosting still works because decryption happens client-side, in the viewer's browser, after they enter the passphrase.

When the user says "publish this" or "put this on GitHub", run:

```bash
scripts/publish-trip-site.sh publish trips/<destination>-<year>
```

That one command:
1. Encrypts `outputs/[destination]-travel-site.html` with StatiCrypt (AES-256-CBC + HMAC-SHA256, 600k PBKDF2-SHA256) into a passphrase-gated `index.html`.
2. Runs a fail-closed **pre-push guard** that refuses to push unless the output is verified ciphertext with no plaintext itinerary tokens.
3. Creates the per-trip **public** repo and pushes **only the ciphertext**, using a no-reply commit identity (never the user's email).
4. Enables Pages and prints the live URL plus the passphrase.

If the pre-push guard aborts, **nothing was published** — the error names what failed; rebuild the site and re-run.

**Passphrase.** If `$STATICRYPT_PASSWORD` is set it is used; otherwise a strong one is generated and saved to `trips/<destination>-<year>/.passphrase` (git-ignored, never published). Share it over a private channel — anyone with the passphrase can view the site; without it, the page is just a prompt.

**Repo name.** By default the per-trip repo is `<destination>-<year>-trip`. Pass `--opaque` to `publish` to name it with a random token instead (`trip-<hex>`, no destination/year); the name is saved to `.publish-slug` so every later command resolves the same repo. To publish to a custom or pre-existing repo — a shorter shared name or an existing site — put the bare repo name in `trips/<destination>-<year>/.publish-slug` (git-ignored). `publish`/`update`/`rotate`/`list`/`unpublish` all resolve it the same way.

**Site is live at:** `https://<github-username>.github.io/<destination>-<year>-trip/` — the URL shows a passphrase prompt, not the itinerary.

**Updating after edits** (re-encrypt and re-publish only ciphertext):
```bash
scripts/publish-trip-site.sh update trips/<destination>-<year>
```

**Rotating the passphrase** (e.g. after sharing with someone who should no longer keep access):
```bash
scripts/publish-trip-site.sh rotate trips/<destination>-<year>
```
Rotation re-encrypts under a new passphrase and re-publishes; previously-shared viewers must re-receive the new one.

**Listing published sites** (read-only — never writes, encrypts, or pushes):
```bash
scripts/publish-trip-site.sh list
```
Prints every trip under `trips/` with its repo, live URL (or "not published"), last-published vs last-edited, and a **stale** flag when your local build is newer than what's deployed.

**Taking a site down:**
```bash
scripts/publish-trip-site.sh unpublish trips/<destination>-<year>                      # delete the repo (default)
scripts/publish-trip-site.sh unpublish trips/<destination>-<year> --disable-pages-only # keep repo, site offline
```
The default **deletes** the per-trip repo — removing the site *and* the destination/year in its name. Deletion is irreversible, needs the `delete_repo` gh scope (grant once with `gh auth refresh -h github.com -s delete_repo`), and prompts you to type the repo name to confirm. `--disable-pages-only` instead disables Pages and keeps the repo (reversible). Either way `unpublish` is idempotent (a no-op if the site is already gone), and content may persist in third-party caches or clones after takedown.

**Opting out** — publish the itinerary fully public and unencrypted — is explicit, requires confirmation, and is **an operator action, never a Claude action**. Run it yourself in a terminal:
```bash
scripts/publish-trip-site.sh publish trips/<destination>-<year> --plaintext
```
The script prompts you to type `PUBLISH` to confirm.

> **Claude must not set `ALLOW_PLAINTEXT`.** That variable exists so an operator can run the script from their own non-interactive automation. It is not a way for Claude to proceed past the prompt. The confirmation is gated on stdin being a terminal, and **a command Claude runs never has one** — so setting the variable does not "confirm non-interactively", it skips the confirmation entirely. The plaintext branch is also the one branch that does **not** run the pre-push ciphertext guard — it runs a *content* guard instead: the publish refuses if a traveler's Passport value or a `[THIRD-PARTY]`-marked value has reached the rendered page, and refuses equally when it cannot determine whether one has (`verify_publishable_content`; `reference/adr/ADR-008-publish-content-guard.md`). That guard and the typed confirmation are the two controls standing on this branch. Where a plaintext publish is what the user wants, **print the command above for them to run** and say why; do not run it. Binding rule: `reference/adr/ADR-007-command-entry-point.md` § 2.

> **What "private" means here.** The published bytes are world-fetchable ciphertext; security rests on passphrase strength plus the 600k-iteration KDF, not on access control — anyone can download the file and attempt an offline guess. Use a strong passphrase. This is privacy-by-construction (a fresh repo, only ciphertext ever committed), not an identity-gated ACL.
>
> **What still leaks (metadata).** By default the per-trip repo is named `<destination>-<year>-trip` and is public, so the destination and year show on your GitHub profile even though the itinerary itself is encrypted; commit timestamps reveal when you publish. Only the itinerary *content* is protected — not the fact that the trip exists. Pass `--opaque` at publish (or set a custom name in `trips/<destination>-<year>/.publish-slug`) to keep destination/year out of the repo name; commit timestamps still reveal publish activity.
>
> **Trust boundary.** Encryption runs via `npx staticrypt` (pinned to an exact version); your passphrase is passed to that package at publish time, so you are trusting the pinned StatiCrypt release and the npm supply chain.
>
> The trip repo is independent from this engine repo — a standalone public repo containing only the encrypted `index.html`. The plaintext itinerary, agent outputs, and `.passphrase` stay in the git-ignored `trips/` working dir and are never published.

### Site References

Previous trip sites that set the quality bar. Read these when building a new site. Each establishes a different destination aesthetic while maintaining the same editorial quality standard.

| Trip | Itinerary Source | Design Notes |
|------|------------------|-------------|
| Tokyo 2026 (worked example) | [`examples/tokyo-2026/outputs/final-itinerary.md`](examples/tokyo-2026/outputs/final-itinerary.md) | Japanese red (#BC002D), Bebas Neue + DM Serif Display + Karla fonts, CSS-art landmark visuals, Leaflet maps, interactive booking checklist, energy-level nav, 3-column day layout, scroll animations, heat zone strips |

> The published HTML for each trip lives in its own standalone public repo (per the publishing section above), not in the engine repo. The example above is the markdown source set; the rendered HTML is produced fresh from those sources per trip.
>
> As more trip examples are added, append them here. Each becomes a reference for future sites — an expanding library of design patterns and destination aesthetics.

---

## Key Rules (From Agent Design)

These are encoded in the agent prompts but worth knowing as the orchestrator:

- **trip-context.md is sacred.** No activity lists, food picks, or itinerary content goes in this file. No per-traveler desire detail, no per-event status, and no satisfaction metrics go in it either — those have their own homes (see below). **Of the agents, only the enrichment agent writes it, and only the `[ENRICH]` fields** — but agents are not its only writers, so write access is granted per block, not per file: see *Write ownership* below.
- **Per-traveler data lives in separate files.** Each traveler's needs and desires live in `trips/<destination>-<year>/travelers/<traveler>.md` — human-authored, independently editable, one file per traveler, **filled from the blank intake form at `templates/traveler-intake.template.md`** (copied once per traveler). The enrichment agent reads and reconciles them into `outputs/traveler-model.md` (`[DERIVED]`); it does not author the source files. Keeps heavy per-traveler detail out of sacred trip-context.md and makes each file a change surface. Each file separates **needs** (constraints that bound the solution — e.g. heat, mobility, dietary-health, rest, budget, timing, sensory) from **desires** (wants optimized within those bounds, each carrying a structural priority tier of anchor/wish/nice-to-have, an optional recurrence of one-off or daily, optional theme tags, and a desire-overlap signal); the tier is a priority label, not a numeric weight, and recurrence is orthogonal to it — a daily want may be an anchor, a wish, or a nice-to-have — nothing optimizes yet. A daily recurrence is a cadence on the want, never an exemption from the venue-deduplication cap below. The template spans the trip lifecycle (IDEATION → ENRICHMENT), capturing the individual's party, destination leanings, dates, journey & origin, accommodation, budget appetite, travel style, interests, and people dynamics through to needs and desires — all the individual's own view; group destination shortlists and any side-bar splits are pipeline-derived, never authored in the individual file (see `reference/data-model.md`). The flow is **intake template → filled per-traveler profile (human, in the git-ignored `trips/`) → enrichment reconciles → `outputs/traveler-model.md`**; filled profiles carry real personal detail and so live only in the git-ignored working dir — they never go in trip-context.md and are never published. A **missing or blank profile is handled by operator fallback, not a hard failure**: the enrichment agent reconciles everyone who has a usable profile, falls back to operator-provided needs/desires for the gap (marked as operator-provided), and otherwise records a flagged `PROFILE MISSING` gap and continues — an absent profile means *unknown*, never *no constraints*. A **third fallback branch covers a party member who will never file a profile at all**: where the operator supplies that person's needs, they are admitted to `outputs/traveler-model.md` as exactly one `## <Name>` entry marked `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` — needs only, no file created for them anywhere, and no entry at all without operator input. A `[THIRD-PARTY]` value is **never published**: it never escalates into trip-context.md (it triggers no new constraint and its subject is never added to a constraint's `Applies to:` line) and must not appear in any publish-bound artifact in attributed *or* anonymized form — it shapes the plan solely through `outputs/traveler-model.md`, which the site build excludes and the hub applies as a hard bound before any objective; provenance-marking records only that a value is second-hand and never establishes the described person's consent (`reference/adr/ADR-006-third-party-data-capture.md`). Full model: `reference/data-model.md`.
- **Satisfaction-layer homes.** Per-event status → `outputs/event-status.md` (persists across re-runs). Coverage metrics → `outputs/satisfaction-metrics.md`. Derived per-traveler model + desire-overlap → `outputs/traveler-model.md`. None of these belong in trip-context.md or in the rebuilt venue-matrix.md. Full data architecture: `reference/data-model.md`.
- **Satisfaction metrics — define the dimensions, not the scoring.** `outputs/satisfaction-metrics.md` tracks six named coverage dimensions, each of a fixed type — emitted by the hub (per-traveler coverage read) and the validator (audit report), never scored at this layer. **Needs-compliance** is **pass/fail** per need per applicable day (each need category honored every day it applies — the applicable days being the days its governing constraint governs **intersected with that traveler's at-destination day set**, so no need is graded on a day its traveler was not at the destination; the structured, recorded form of the every-applicable-day hard-constraint audit, *not* a balance score). Its agreement with constraint-compliance is **forward-only**: every needs-compliance `fail` is a constraint Critical, but a trip-level/group constraint with no linked per-traveler need yields a constraint Critical with no needs-compliance row by design. **Desire-coverage** is **covered / not** per traveler per desire (each anchor/wish met by the plan or not — a boolean, not a degree). **Group-equity**, the four **experience axes** (creativity, fun, excitement, newness), **rest-recovery balance**, and **meal-variety concentration** (per day) are named **balance signals** to track — their scoring (formulas, weights, thresholds) is **left to design**, since nothing in the satisfaction layer optimizes yet. Full dimension set, types, and artifact shape: `reference/data-model.md` → Satisfaction Metrics.
- **Per-event status — only `planned` changes freely.** Every placed event carries exactly one status in `outputs/event-status.md`: `planned` (working state, open to iteration, may still need a booking), `locked` (booked/confirmed, preserved), `firmed` (settled with nothing to book, preserved), or `option` (an alternative/bailout — never a primary slot). Iteration and resequencing change only `planned` events; `locked`/`firmed` are preserved unless the user names them; an `option` is never auto-promoted into a primary slot (that is a deliberate user act). A booking that falls through regresses `locked → planned` (the event re-opens and its booking question reopens), and an event removed from the itinerary has its row **deleted** (the one deletion persist-mutable permits — no ghost row). The **Event ID is opaque and day-independent** (the hub mints it on first placement; it is the cross-run join key and must not encode the day). "Needs booking" derives from status — `planned` **and** `requires booking? = yes` — so `firmed`/`locked`/`option` never read as "needs booking" (an `option` may still carry `requires booking? = yes` as a bookable backup; its flag takes effect only on promotion to `planned`), and "all events locked" means no `planned`-needs-booking event remains. This structured per-event layer supersedes the coarse free-text `## Locked Elements` notes in trip-context.md (which stay as the **operator-maintained** trip-level human summary, not an agent-written field) as the source of truth for the scheduler, hub, and validator. Field-shape decision and full model: `reference/data-model.md`.
- **Engine producer/consumer convention (R1–R4).** The three optimizer engines (geographic routing, experience, attention) each **produce** their objective as a signal in their own host agent's output file — no engine writes synthesis logic into `agents/05-hub-planner.md` (R1); each output file keeps **one writer**, so engines sharing a file serialize on it (R2); the **hub consumes and reconciles all three exactly once**, in the "Spoke conflict protocol" objective-reconciliation clause — engines only append their signal to the hub's Required inputs, never editing the synthesis flow (R3); and the **validator consumes too**, adding audit checks to `agents/06-validator.md` under the same read-only pattern, never hub edits (R4). Full convention: `reference/data-model.md` and the hub's objective-reconciliation clause.
- **Link, don't copy — one source per fact.** Trip-level constraints stay in trip-context.md `## Hard Constraints` / `## Dietary & Health` (the constraint SSOT). Per-traveler files own per-traveler desires and need-specifics. The enrichment agent *links* a traveler's need to the governing constraint via "Applies to" — it never duplicates the constraint text. A fact has exactly one owner.
- **Venue deduplication.** No venue appears as an anchor on one day and an alternative on another. Max 2 appearances total across the full itinerary. The hub builds venue-matrix.md to enforce this BEFORE writing the itinerary.
- **Hub builds reference files first.** links-reference.md and venue-matrix.md are built before the day-by-day itinerary — not after.
- **Every 3+ hour outdoor block needs a bailout.** A named indoor venue with address, walking distance, and hours. Not a suggestion to "find somewhere nearby."
- **Alternatives must vary on two axes.** Price tier AND effort level. Three options at the same price and walk-in status provide no real choice.
- **Hard constraints are audited every day.** The hub checks. The validator double-checks. A constraint violation in the final output is a system failure.
- **Closure days matter.** Every venue needs a day-of-week closure check against the day it's scheduled. The validator catches these but the spoke agents should note them.

### Write ownership — trip-context.md, block by block

One writer per block. A writer not named for a block does not write it — not "usually not", and not "unless the change is small". Route by the block the bytes land in, never by the size or the subject of the change; if the next synthesis pass would regenerate those bytes, they do not belong in this file at all.

| Block | Writer | Condition |
|-------|--------|-----------|
| Title line · `## Group` roster · `Total travelers` | `/trip-new` at creation; `/trip-record` thereafter | `/trip-new` writes this file **only when creating it**. On an existing trip it leaves the file alone and re-derives nothing. |
| `## Mode` → `Current mode` and `Mode notes` | `/trip-new` at creation · `/trip-record` · `/trip plan`, `/trip replan` and `/trip reorder` (carve-out below) | Whoever changes `Current mode` writes `Mode notes` in the same act, naming the evidence for the new value. |
| `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | the enrichment agent | `[ENRICH]`-only, whichever command dispatched it. Contract: `agents/00-enrichment.md`. Layering: `reference/data-model.md` → *Who Writes What*. |
| `[DERIVED]` blocks — `### Effective Planning Days`, `### Per-Traveler Planning Days` | **no writer exists** | Not a gap to fill opportunistically. The template forbids manual editing and the enrichment agent declines the write in terms. Until an owner is decided these blocks are read-only to every command, `/trip-record` included; staleness is reported, never repaired in place. |
| `## Destination` | `/trip-record` | `/trip ideas` produces the shortlist and **names** this step; it never writes the destination itself. |
| `## Locked Elements` · `## Current Itinerary Status` | the operator, through `/trip-record` | The trip-level human summary. `outputs/event-status.md` is the structured source of truth for the scheduler, hub and validator; enrichment may *read* these notes to seed initial `locked` rows and never authors them. |
| `**Lifecycle:**` — the lifecycle marker line | `/trip-decommission` | A command-written lifecycle marker, not a Layer-1 human field — named here so the untagged-field row below does not claim it, and `/trip-record` never writes it. Its `archive` verb writes the field; its `reopen` verb returns it to `ACTIVE` rather than removing the line. An absent line is the contract's declared default rather than a gap to fill opportunistically (`§ Resolving a trip`, G4). |
| every untagged field **not named above** | `/trip-record` | Layer 1 — human source. The default row. An untagged `###` or `####` sub-block inherits its parent `##` section's row. |
| a block not listed above | nobody | A new block gets an owner in this table before it gets content. |

**Ownership follows the writer, not the caller.** A command that dispatches an agent does not acquire that agent's blocks: `/trip-record travelers` runs enrichment, and the `[ENRICH]` fields enrichment then writes are still enrichment's.

**Carve-out — the mode field, and only the mode field.** Exactly three procedures may write it — `/trip plan`, `/trip replan` and `/trip reorder`, an enumeration and not a class such as "the planning verbs". Each may advance `Current mode` to the value its own completed work makes observable, and must say so in its own output. They write nothing else in this file. The carve-out exists because nothing in the previous command surface ever wrote `ITERATION` or `RESEQUENCING`: a trip stayed in `DISCOVERY`, and three behaviours that branch on the later modes — the hub's equity-aware disruption recovery, the validator's recovery-equity check, and the validator's full pass on all days after a resequence — never fired, silently, because `DISCOVERY` is a legal mode. A transition only the acting procedure can observe is a transition only it can record. Any other procedure wanting this cell names `/trip-record` instead; the test for admitting one is that the transition is observable from the artifact that procedure just produced, and is announced in the same output.

**`outputs/event-status.md` is the one file a procedure and a document edit both write.** Its lifecycle is persist-mutable: synthesis *reads* existing status and never regenerates it, so a human flip survives the next pass. The hub is its primary writer (the enrichment agent may seed initial `locked` rows once at setup; the validator reads it and never writes), and the user writes it through `/trip-record`. Every other file the pipeline produces is rebuilt, versioned or appended — a hand edit to one of those is a change with a deletion already scheduled. This is an exception the lifecycle predicts, not an exception to the rule.

## File Structure

```
travel-planner/
├── CLAUDE.md                 ← you are here
├── agents/                   ← agent behavioral definitions (the knowledge base)
│   ├── 00-enrichment.md
│   ├── 01-activities.md
│   ├── 02-food.md
│   ├── 03-scheduling.md
│   ├── 04-transport.md
│   ├── 05-hub-planner.md
│   ├── 06-validator.md
│   ├── 07-nightlife.md
│   └── destination-ideation.md
├── examples/                 ← worked examples, sanitized: tokyo-2026, ideation-demo, two-origin-demo
├── reference/                ← engine reference specs
│   ├── adr/                       ← architecture decision records (one file per decision)
│   ├── data-model.md              ← satisfaction-layer data architecture (storage homes, reconciliation, lifecycle)
│   └── site-layout-spec.md        ← travel-site responsive/layout specification
├── scripts/                  ← publish-trip-site.sh (private publish) + test-publish-guard.sh
├── templates/
│   ├── trip-context.template.md
│   └── traveler-intake.template.md   ← per-traveler profile form (blank; copied per traveler into the git-ignored trips/.../travelers/)
└── trips/                    ← ships with README.md only; all trip content git-ignored
    ├── README.md             ← tracked signpost (the one tracked file under trips/)
    └── <destination>-<year>/ ← one folder per trip
        ├── trip-context.md            ← source of truth for the trip
        ├── trip-log.md                ← decision history, session bridge
        ├── travelers/                 ← per-traveler source files (gitignored), one .md per traveler — human-authored
        └── outputs/
            ├── destination-shortlist.md ← ranked group shortlist (IDEATION, pre-destination)
            ├── activities-list.md     ← accumulates across sessions
            ├── food-list.md           ← accumulates across sessions
            ├── nightlife-list.md      ← accumulates across sessions
            ├── scheduling-framework.md
            ├── transport-brief.md
            ├── links-reference.md     ← rebuilt by hub each synthesis
            ├── venue-matrix.md        ← rebuilt by hub each synthesis
            ├── traveler-model.md      ← [DERIVED] reconciled per-traveler model + desire-overlap (rebuilt from source files)
            ├── event-status.md        ← per-event status — persist-mutable, survives re-runs
            ├── satisfaction-metrics.md ← coverage metrics (validator + hub)
            ├── final-itinerary.md     ← current version (previous versions preserved as v1, v2...)
            ├── validation-report.md
            └── [destination]-travel-site.html   ← bespoke, Claude-generated
```
