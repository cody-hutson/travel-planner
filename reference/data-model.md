# Data Model — The Satisfaction Layer

The canonical data-architecture document for the satisfaction layer. It defines **where each new piece of satisfaction data lives, what shape it takes, who writes it, how it flows, and how it reconciles** with the existing `trip-context.md` — so every satisfaction slice builds to one decision rather than re-deciding storage independently.

This document governs the data **substrate** only — storage homes, artifact shapes, write ownership, lifecycle, and reconciliation. It deliberately does **not** define metric formulas, scoring algorithms, or any optimization logic. Nothing in the satisfaction layer optimizes yet; this is the foundation those later capabilities will read from.

---

## The Problem This Solves

The satisfaction layer introduces structured data the original model has no home for:

- **Per-traveler needs and desires** — today this is free text in `trip-context.md` → `## Group` "Key Characteristics", with needs split across `## Hard Constraints` ("Applies to") and the flat `## Dietary & Health` lists. There is no per-traveler structured layer.
- **Per-event status** — today this is coarse free text in `## Locked Elements`. There is no per-event structured layer, and status must *persist* across synthesis re-runs.
- **Satisfaction metrics** — a coverage view the validator and hub need, with no home at all.

`trip-context.md` is **sacred**: activity lists, food picks, and itinerary content never appear in it. None of the new data above belongs there either. This document homes each piece elsewhere while keeping `trip-context.md` the trip-level constraint source of truth.

---

## Storage Homes

Five artifacts make up the satisfaction substrate. Per-traveler source files are **human-authored Layer-1 input**; the three `outputs/` artifacts are **derived** — written by agents, never by hand.

| Artifact | Path | Writer | Layer | Rationale |
|----------|------|--------|-------|-----------|
| **Per-traveler source files** | `trips/[destination-year]/travelers/<traveler>.md` | Human (the traveler / planner) | Layer 1 — human-authored | Keeps heavy per-traveler detail out of sacred `trip-context.md`; enables async per-traveler authoring (each traveler fills/edits on their own time); makes each file an independent **change surface** (see Forward Connection). Filled from `templates/traveler-intake.template.md`. |
| **Derived traveler model** | `outputs/traveler-model.md` | Enrichment agent | Derived `[DERIVED]` | The reconciled, machine-usable projection of all per-traveler files **plus** the desire-overlap signal. One place the engines and hub read instead of parsing N source files. |
| **Per-event status** | `outputs/event-status.md` | Enrichment / hub (per the control-flow contract) | Derived, persist-mutable | Per-event state must **persist across synthesis re-runs**. It cannot live in `trip-context.md` (banned itinerary content) nor in `venue-matrix.md` (rebuilt every synthesis — status would be wiped). A dedicated persistent artifact is the iteration-protection source of truth. |
| **Satisfaction metrics** | `outputs/satisfaction-metrics.md` | Validator + hub | Derived | The coverage view, written and read by the validator and hub. Formulas are out of scope here — this document only fixes *where the numbers live*, not how they are computed. |

> **Sacred rule, restated for this layer.** No per-traveler desire detail, no per-event status, and no metrics go **into** `trip-context.md`. The per-traveler *needs* still reconcile **against** the trip-level constraints in `trip-context.md` (see Reconciliation) — but by *link*, never by copy, and the satisfaction artifacts above are their homes.

### Per-traveler source file — what it owns

Each `trips/[destination-year]/travelers/<traveler>.md` is one traveler's own file, authored from `templates/traveler-intake.template.md`. It owns:

- **That traveler's desires** — what they personally want out of the trip (the want-to-do, the would-love-to-see, the energy and pace they prefer).
- **That traveler's need specifics** — the personal detail behind a need (the *how much*, the *what exactly*, the personal context) that does not belong in a trip-level constraint block.

It does **not** redefine the trip-level constraint. A traveler's *need* points at the trip-context constraint that governs it; the constraint itself stays in `trip-context.md`.

---

## Reconciliation Rule — One Source Per Fact

**The governing rule: link, don't copy. One source per fact.**

| Fact type | Single source of truth | Who reconciles |
|-----------|------------------------|----------------|
| Trip-level **constraint** (the non-negotiable, the dietary/health restriction, the mobility limit) | `trip-context.md` → `## Hard Constraints` / `## Dietary & Health` | Stays put — the enrichment agent never moves it |
| Per-traveler **desire** | The traveler's own `travelers/<traveler>.md` | Owned by the source file |
| Per-traveler **need specific** (the personal detail behind a constraint) | The traveler's own `travelers/<traveler>.md` | Owned by the source file |
| The **link** between a traveler's need and the trip-level constraint it falls under | Established by the enrichment agent, recorded in `outputs/traveler-model.md` | Enrichment agent, via "Applies to" — **never by copying the constraint text** |

The enrichment agent is the reconciler. When it reads the per-traveler files, it **links** each traveler's need to the relevant `trip-context.md` constraint via that constraint's "Applies to" — it does not duplicate the constraint into the traveler file or into the derived model. If the constraint text changes, it changes in exactly one place.

### Concrete illustration

Trip-context owns the trip-level constraint:

```markdown
## Hard Constraints

### Limited stair tolerance
- Description: Cannot manage long or repeated stair climbs; step-free routing required.
- Applies to: Jordan
- Practical impact: Venues must have step-free access or a lift; avoid stations that are stairs-only.
- Bailout requirement: No
```

Jordan's own source file owns the personal *specifics* of that need — and points at the constraint rather than restating it:

```markdown
# Traveler — Jordan

## Needs
- Mobility: prefers fewer than ~15 minutes continuous walking before a sit-down break.
  Applies to: Hard Constraints → "Limited stair tolerance"

## Desires
- Would love one slow museum morning over a packed sightseeing day.
- Strong interest in local markets; happy to skip nightlife.
```

The enrichment agent reconciles the two into the derived model — carrying the *link*, not a second copy of the constraint:

```markdown
# Traveler Model [DERIVED]

## Jordan
- Need → Hard Constraints "Limited stair tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, sit-down breaks.
- Desires: slow museum morning; local markets; low nightlife appetite.
```

The constraint exists once (in `trip-context.md`). Jordan's personal specifics exist once (in `Jordan.md`). The derived model **references** both. No fact has two owners.

---

## The Needs-vs-Desires Model

The reconciliation rule above fixes *how* per-traveler data links back to the trip-level constraints. This section fixes *what* a per-traveler file actually holds: the structure that separates a traveler's **needs** from their **desires**. Every per-traveler source file is organized around this one distinction.

**The governing definition:**

> **A need is a constraint that bounds the solution. A desire is an objective optimized within those bounds.**

A need is non-negotiable — the plan is either inside it or it is broken (a heat ceiling, a mobility limit, an allergy, a required rest window). A desire is a want the plan tries to satisfy as well as it can, given the bounds the needs set — but a missed desire is a worse plan, not a broken one. Needs draw the box; desires are what the trip optimizes for *inside* the box.

This is the same need-vs-want split the original system already half-expresses — needs as `## Hard Constraints` / `## Dietary & Health`, wants scattered through free-text "Key Characteristics". The satisfaction layer makes it explicit, per-traveler, and structured.

### Needs

A need is the traveler's personal stake in a trip-level constraint. The constraint itself is trip-level and lives in `trip-context.md` (the SSOT); the traveler's *need* is the personal specific behind it — and it **links** to the governing constraint rather than restating it (per the Reconciliation Rule above).

Needs cover four categories. Every per-traveler need falls under one:

| Need category | What it bounds | Governing trip-context constraint it links to |
|---------------|----------------|-----------------------------------------------|
| **Heat tolerance** | The outdoor-exposure ceiling — how much heat / sun / humidity this traveler can take, and for how long | `## Hard Constraints` (the heat / climate constraint) |
| **Mobility** | The movement envelope — walking distance, stairs, standing time, terrain, rest-break cadence | `## Hard Constraints` (the mobility / accessibility constraint) and `## Dietary & Health` → mobility notes |
| **Dietary / health** | The food-and-health boundary — allergies, restrictions, medical needs, pacing limits | `## Dietary & Health` (and any `## Hard Constraints` block that encodes a health non-negotiable) |
| **Required rest** | The recovery floor — the rest this traveler must get (a slow morning, a mid-day break, an early night) for the rest of the plan to hold | `## Hard Constraints` (a rest / pacing constraint) — add one if the rest need is non-negotiable and none exists yet |

The field shape for a single need:

- **Category** — one of the four above.
- **Specific** — the personal detail behind the need: the *how much*, the *what exactly*, the personal context. This is what the per-traveler file owns and the constraint block does not.
- **Applies to** — the link to the governing `trip-context.md` constraint, written as `<Section> → "<Constraint name>"`. This is the link, **never a copy** of the constraint text.

> If a traveler states a need with no governing trip-level constraint yet (e.g. a required-rest floor the trip has not captured as a constraint), that is a signal to add the constraint to `trip-context.md` — the SSOT — and then link to it. The per-traveler file never becomes the de-facto home for a trip-level constraint.

### Desires

A desire is something the traveler wants out of the trip — an activity, a food experience, or a more general wish about pace and feel. Unlike a need, it carries a **priority tier** and an **overlap** signal, and it is owned outright by the traveler's own file (it links to nothing — there is no trip-level "desire constraint").

The field shape for a single desire:

- **Desire** — what the traveler wants (the want-to-do, the would-love-to-see, the kind of day they hope for).
- **Priority tier** — exactly one of:
  - **anchor** — a desire the traveler would be genuinely disappointed to miss; the trip should be built to land it.
  - **wish** — a real want the trip should try hard to include, but which can yield to a need or to another traveler's anchor.
  - **nice-to-have** — a bonus; pleasant if it fits, no loss if it does not.
- **Theme tag(s)** *(optional)* — one or more free-text tags grouping the desire by kind (e.g. `food`, `markets`, `museums`, `nightlife`, `nature`, `slow-pace`). Tags are how desires across travelers are matched for overlap; they are descriptive labels, not categories the traveler must pick from.
- **Overlap** — which **other** travelers share this desire (by name), or `solo` if no one else lists it. This is the **desire-overlap signal**: it surfaces where the group already agrees. The enrichment agent computes it by matching desires across all per-traveler files (by theme tag and plain-language sense) — a traveler authoring their own file may leave it blank or note who they *think* shares it; the derived model carries the reconciled answer.

> **Priority tiers are structural labels, not numeric weights.** `anchor` / `wish` / `nice-to-have` rank a traveler's desires by importance so a later capability knows what matters most — they are **not** scores, weights, or coverage percentages, and nothing in this layer multiplies, sums, or optimizes against them. The tier says "this matters more than that"; it does **not** say "this is worth 0.8". How a future capability *balances* desires across the group, or *measures* how well a plan satisfies them, is out of scope here (see What This Document Does Not Define). This document defines the structure the tiers live in; it does not define any math over them.

### Worked example — a per-traveler file

Jordan's `travelers/Jordan.md`, written out in the full model (extending the smaller illustration in the Reconciliation Rule above):

```markdown
# Traveler — Jordan

## Needs
- Category: Mobility
  Specific: prefers fewer than ~15 minutes continuous walking before a sit-down break; step-free routing.
  Applies to: Hard Constraints → "Limited stair tolerance"
- Category: Required rest
  Specific: needs one slow start (no fixed plan before ~10:00) every other day to keep pace the rest of the trip.
  Applies to: Hard Constraints → "Daily pacing floor"

## Desires
- Desire: a slow museum morning rather than a packed sightseeing sprint.
  Priority tier: anchor
  Theme tag(s): museums, slow-pace
  Overlap: Pat
- Desire: explore local markets.
  Priority tier: wish
  Theme tag(s): markets, food
  Overlap: Pat
- Desire: one standout coffee place.
  Priority tier: nice-to-have
  Theme tag(s): food
  Overlap: solo
```

Pat's `travelers/Pat.md` shares two of those desires — which is what produces the overlap above:

```markdown
# Traveler — Pat

## Needs
- Category: Heat tolerance
  Specific: fades fast above ~82°F / 28°C in direct sun; needs shade or indoors by early afternoon on hot days.
  Applies to: Hard Constraints → "Afternoon heat ceiling"

## Desires
- Desire: a relaxed museum morning.
  Priority tier: wish
  Theme tag(s): museums, slow-pace
  Overlap: Jordan
- Desire: wander a local market.
  Priority tier: anchor
  Theme tag(s): markets, food
  Overlap: Jordan
```

The enrichment agent reconciles both files into `outputs/traveler-model.md` — linking each need to its constraint and carrying the computed overlap signal:

```markdown
# Traveler Model [DERIVED]

## Jordan
- Need → Hard Constraints "Limited stair tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, step-free.
- Need → Hard Constraints "Daily pacing floor" (Applies to: Jordan); specific: slow start every other day.
- Desire (anchor): slow museum morning [museums, slow-pace] — shared with Pat.
- Desire (wish): local markets [markets, food] — shared with Pat.
- Desire (nice-to-have): standout coffee [food] — solo.

## Pat
- Need → Hard Constraints "Afternoon heat ceiling" (Applies to: Pat); specific: shade/indoors by early afternoon above ~82°F.
- Desire (wish): relaxed museum morning [museums, slow-pace] — shared with Jordan.
- Desire (anchor): local market [markets, food] — shared with Jordan.

## Desire overlap
- museums / slow-pace morning: Jordan (anchor), Pat (wish)
- local markets: Jordan (wish), Pat (anchor)
```

Each constraint still lives once in `trip-context.md`; each traveler's specifics and desires live once in their own file; the derived model references all of it and adds the cross-traveler overlap. No fact has two owners — and nothing here scores, weights, or optimizes; it is structure only.

---

## Who Writes What — Field Layering

The satisfaction layer preserves the system's **one-writer-per-file** convention. The novelty is that for the per-traveler source files, the *writer is the human* — which is exactly why separate files were chosen: each traveler can own and edit their own file independently.

| Layer | Tag | Written by | Files |
|-------|-----|-----------|-------|
| **Layer 1 — human source** | (untagged human input) | The traveler / planner, by hand | `travelers/<traveler>.md` |
| **Derived — reconciled** | `[DERIVED]` | The enrichment agent (as reader / reconciler) | `outputs/traveler-model.md` |
| **Derived — status & metrics** | (derived) | Enrichment / hub (status) · validator + hub (metrics) | `outputs/event-status.md`, `outputs/satisfaction-metrics.md` |
| **Enrichment rollups in trip-context** | `[ENRICH]` | The enrichment agent (unchanged) | `trip-context.md` `[ENRICH]` fields |

Two roles for the enrichment agent, kept distinct:

1. **Reader / reconciler of human input.** It reads every `travelers/<traveler>.md`, links each need to the governing `trip-context.md` constraint, computes the desire-overlap signal, and writes the result to `outputs/traveler-model.md` as `[DERIVED]`. It does not author the source files and does not edit a traveler's desires.
2. **Writer of trip-context `[ENRICH]` rollups (unchanged).** Its existing `[ENRICH]`-only contract on `trip-context.md` is untouched — weather, baseline, events, transit access, and the other `[ENRICH]` fields still behave exactly as before.

The derived traveler model is the **feed**: the engines and the hub read `outputs/traveler-model.md`, and it is the input from which the event-status and metrics homes are populated. Engines and hub do **not** parse the raw per-traveler files.

---

## Data Flow

```
templates/traveler-intake.template.md          (the per-traveler intake form)
        │  copied per traveler, filled by hand
        ▼
trips/[dest-year]/travelers/<traveler>.md       (Layer 1 — human-authored, one file per traveler)
        │  enrichment agent reads + reconciles (link to trip-context constraints, never copy)
        ▼
outputs/traveler-model.md  [DERIVED]            (reconciled model + desire-overlap signal)
        │  read by ...
        ├────────────► engines        (read the model; nothing optimizes yet)
        ├────────────► hub            (coverage view)
        │
        ├──► outputs/event-status.md            (per-event status — persist-mutable, survives re-runs)
        └──► outputs/satisfaction-metrics.md    (coverage metrics — validator + hub)

  trip-context.md  ## Hard Constraints / ## Dietary & Health
        ▲  referenced by "Applies to" links — the trip-level constraint SSOT, never copied into the above
```

The chain in one line: **intake template → per-traveler source file (human) → enrichment reconciles → derived traveler model (`[DERIVED]`, model + overlap) → engines + hub read it**; per-event status lives in `outputs/event-status.md`; metrics live in `outputs/satisfaction-metrics.md`; all of it links back to — never copies — the trip-level constraints in `trip-context.md`.

---

## Artifact Lifecycle Classification

The original system defines an **Output Versioning** model for `outputs/*.md`. Each new satisfaction artifact must be classified against it so re-runs neither lose state nor accumulate stale duplicates. The existing patterns are:

- **(a) Accumulate-append-with-dated-sections** — research outputs (e.g., `food-list.md`, `activities-list.md`). Each re-run appends a dated section; nothing is deleted.
- **(b) Rebuilt-each-synthesis** — `venue-matrix.md`, `links-reference.md`. Reflect the *current* itinerary state; regenerated from scratch on every synthesis pass.
- **(c) Versioned** — `final-itinerary.md` → `v1`, `v2`, ... Each synthesis produces a new numbered version; prior versions are preserved as files.

The new artifacts classify as follows:

| New artifact | Lifecycle | How it behaves | Closest existing pattern |
|--------------|-----------|----------------|--------------------------|
| `outputs/event-status.md` | **persist-mutable** (new — fourth pattern) | Updated **in place** as events change status. **Survives every re-synthesis** — never wiped, never regenerated from scratch. It is the iteration-protection source of truth: the record of what has already been booked / locked / fallen-through must outlive any single planning pass. | None — see below |
| `outputs/traveler-model.md` | rebuilt / refreshed from source | A derived projection. The enrichment agent refreshes it from the **current** per-traveler source files whenever those change. It carries no independent state of its own — the source files are authoritative — so regeneration is safe. | (b) rebuilt-each-synthesis |
| `outputs/satisfaction-metrics.md` | rebuilt / refreshed from inputs | Recomputed by the validator + hub from the **current** itinerary and the current traveler model. A snapshot of coverage at synthesis time; safe to regenerate because its inputs are authoritative. | (b) rebuilt-each-synthesis |

### `event-status.md` is genuinely a new fourth pattern

It is **not** any of the three existing patterns, and the distinction is load-bearing:

- It is **not (a) accumulate-append** — old status is *mutated*, not preserved as history. When an event goes from "to book" to "booked", the record changes; we do not keep a dated log of every status it ever held.
- It is **not (b) rebuilt-each-synthesis** — and this is the critical difference. The whole reason it cannot live in `venue-matrix.md` is that rebuilt artifacts are *wiped and regenerated* each synthesis. Status must **survive** the synthesis, not be recomputed by it. A re-synthesis reads existing status; it does not overwrite it.
- It is **not (c) versioned** — there are no `event-status-v1.md` / `v2.md` snapshots. There is one living file, mutated in place.

So the substrate adds a fourth lifecycle pattern — **persist-mutable**: a single file, updated in place, that persists across re-runs and is *read* (never blindly overwritten) by synthesis. The other two new artifacts fit the existing **rebuilt** pattern (b) because they are pure derived projections of authoritative inputs.

---

## Forward Connection — Profile Edits as a Replanning Trigger

Because each per-traveler file is independently editable, the system gains a capability the old free-text model could not offer: **change detection on traveler preferences.**

The enrichment agent can diff each `travelers/<traveler>.md` against the snapshot it last processed. When a file has changed — a new desire, a revised need, a dropped preference — the agent emits an **update signal**. That signal is a candidate **replanning trigger**: a changed preference can warrant an equity-aware re-plan, alongside the existing missed-booking trigger derived from event status.

This document describes the *capability* and the *data condition* that produces it (an edited source file, detected by diffing against the last-processed snapshot). The replanning behavior the signal triggers — when to re-plan, and how to balance the group fairly — is owned by the replanning capability, not by this substrate. The substrate's job is only to make the signal detectable and to carry it.

---

## What This Document Does Not Define

To keep the substrate boundary clear:

- **No metric formulas or scoring math.** `satisfaction-metrics.md` has a *home* here; how a coverage number is computed is out of scope.
- **No optimization or ranking logic.** Nothing in the satisfaction layer optimizes yet. The engines *read* the derived model; this document does not specify what they do with it.
- **No replanning policy.** The update signal is defined as a data condition; the decision to re-plan and the fairness logic live with the replanning capability.
- **No control-flow / consumption sequencing.** Who runs when, and how the hub consumes these artifacts in a pipeline pass, is governed by the control-flow contract, not this data-architecture document.

This file is the **data** contract. Behavior contracts live with their respective agents and capabilities.
