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
