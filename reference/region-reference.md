# Region Reference

Every region of every block-owned form, each resolved to the row of its writer table that it answers
to, and the verdict that row gives the command conducting the form's interview. It exists because
`/trip-record interview` cannot run the suite that computes those verdicts, and must still know, before
it writes a field, whether the field's region is one the table gives it. It reads this file instead of
resolving the table itself, so the engine resolves the table in one place — the suite — and this file
is that resolution's output.

**The table below is derived. Do not restate it.** Its rows are recomputed from each block-owned form
and the writer table its `write-ownership:` key addresses on every run of
`scripts/test-artifact-schema.sh`, and compared against what is committed here; a divergence fails the
run, and the suite prints the block it expected. The computation is the suite's `ft_regions`, the
reader the suite also grades each form's region contract with, and no sentence here restates its rules.
Prose here explains how to *read* the table; the table is what says what is in it.

## How to read it

| Column | What it carries | Where it comes from |
|---|---|---|
| **Form** | The block-owned form a row belongs to, repository-relative | the forms the suite declares for its conformance arm |
| **Writer table** | The table that form's `write-ownership:` key addresses — a file, then a section | the form's `intake-form` block |
| **This command** | The command the table's default row names: the one that conducts the form's interview | the table's default row |
| **Line** · **Through** | The region's heading line in the form, and the last line of its extent | the form |
| **Region** | The heading as the form carries it, its level included | the form |
| **Resolved** | How the region reached its row — `named`, `marker`, `inherits` or `default` | the resolution `reference/adr/ADR-024-form-contract-writer-boundary.md` decision 2 states |
| **Row** · **Block** | The row it reached, by number and by that row's `Block` cell | the writer table |
| **Verdict** | What that row gives this command in that region, and its ground | the row's `Block` and `Writer` cells, read by the suite |
| **Holds for this command** | For a `CONDITIONAL` region, the condition of each clause of its row that names this command alone; a dash otherwise | the row's `Writer` cell, read by the suite |

A region's extent is its heading and every line beneath it until the next heading of the same or a
higher level, so a line of the form sits in the region whose heading is nearest above it. The title
line, and a line above the form's first region, sit in none. A verdict of `UNRESOLVED` means the form
and its table disagree about that region; the suite's conformance arm fails the form in that case, so a
committed table carries one only on a tree that is already red.

**What reads it.** `/trip-record interview`, on a block-owned form, declared on that verb's `**Reads:**`
line in `skills/trip-record/SKILL.md`. What a verdict lets it do, and how it reads a `CONDITIONAL` region,
is that verb's conduct, stated in `skills/trip-record/interview-conduct.md`; this file carries no
conduct.

## The regions

<!-- region-contract: derived — regenerate by running scripts/test-artifact-schema.sh -->
| Form | Writer table | This command |
|---|---|---|
| `templates/trip-context.template.md` | `CLAUDE.md` § Write ownership — trip-context.md | `/trip-record` |

| Form | Line | Through | Region | Resolved | Row | Block | Verdict | Holds for this command |
|---|---|---|---|---|---|---|---|---|
| `templates/trip-context.template.md` | 37 | 48 | `## Mode` | named | 2 | `## Mode` → `Current mode` and `Mode notes` | NO (writer-set) | — |
| `templates/trip-context.template.md` | 49 | 56 | `## Destination` | named | 5 | `## Destination` | YES (interviewer) | — |
| `templates/trip-context.template.md` | 57 | 160 | `## Logistics` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 71 | 77 | `### Outbound` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 78 | 84 | `### Return` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 85 | 118 | `### Additional origins` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 95 | 118 | `#### Origin B — [City, Country ([airport code])]` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 119 | 160 | `### Effective Planning Days [DERIVED]` | named | 4 | `[DERIVED]` — `### Effective Planning Days` | NO (marked) | — |
| `templates/trip-context.template.md` | 161 | 180 | `## Accommodation` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 171 | 174 | `### Transit Access [ENRICH]` | named | 3 | `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | NO (marked) | — |
| `templates/trip-context.template.md` | 175 | 180 | `### Walkable Proximity [ENRICH]` | named | 3 | `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | NO (marked) | — |
| `templates/trip-context.template.md` | 181 | 202 | `## Group` | named | 1 | Title line · `## Group` roster · `Total travelers` | CONDITIONAL (condition) | thereafter |
| `templates/trip-context.template.md` | 203 | 234 | `## Hard Constraints` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 212 | 221 | `### [Constraint Name]` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 222 | 234 | `### [Constraint Name]` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 235 | 245 | `## Soft Preferences` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 246 | 257 | `## Trip Style` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 258 | 267 | `## Budget Posture` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 268 | 282 | `## Dietary & Health` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 283 | 296 | `## Weather Context [ENRICH]` | named | 3 | `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | NO (marked) | — |
| `templates/trip-context.template.md` | 297 | 309 | `## Destination Baseline [ENRICH]` | named | 3 | `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | NO (marked) | — |
| `templates/trip-context.template.md` | 310 | 323 | `## Events & Calendar [ENRICH]` | named | 3 | `[ENRICH]` fields — `### Transit Access`, `### Walkable Proximity`, `## Weather Context`, `## Destination Baseline`, `## Events & Calendar` | NO (marked) | — |
| `templates/trip-context.template.md` | 324 | 331 | `## Possible Day Trips` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 332 | 343 | `## Locked Elements` | named | 6 | `## Locked Elements` · `## Current Itinerary Status` | YES (interviewer) | — |
| `templates/trip-context.template.md` | 344 | 357 | `## Current Itinerary Status` | named | 6 | `## Locked Elements` · `## Current Itinerary Status` | YES (interviewer) | — |
| `templates/trip-context.template.md` | 358 | 385 | `## Validation Requirements` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 364 | 367 | `### Known Closure Risks` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 368 | 371 | `### Reservation Status to Confirm` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 372 | 375 | `### Price Staleness Flags` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 376 | 379 | `### Travel Restriction Checks` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 380 | 385 | `### Venue Deduplication Watch` | inherits | 8 | every untagged field **not named above** | YES (interviewer) | — |
| `templates/trip-context.template.md` | 386 | 398 | `## Notes for All Agents` | default | 8 | every untagged field **not named above** | YES (interviewer) | — |
<!-- /region-contract -->

## Where this fits

The writer table owns the verdicts — a block's writer is decided there, and
`reference/adr/ADR-024-form-contract-writer-boundary.md` decides how a region reaches its row — so a
restatement of them anywhere else is a surface that drifts. This file is a restatement, and it is
committed only because it is *derived and asserted* rather than remembered: the suite that grades each
form's region contract recomputes the region above and fails on a divergence, the posture
`reference/command-reference.md` already takes for the command surface.

**When the writer table or a block-owned form changes**, edit the table or the form. Run
`./scripts/test-artifact-schema.sh`; it will fail on the stale region here and print the replacement
block. Paste it in. An edit that moves a row's verdict also fails the suite's pin of that row, and the
pin is updated in the same change as a decision about the table rather than as a paste. Nothing in this
file is maintained by hand except the prose.
