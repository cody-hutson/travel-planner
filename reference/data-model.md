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
| **Per-event status** | `outputs/event-status.md` | **Hub (primary writer)**; enrichment seeds initial `locked` rows on setup; validator reads only | Derived, persist-mutable | Per-event state must **persist across synthesis re-runs**. It cannot live in `trip-context.md` (banned itinerary content) nor in `venue-matrix.md` (rebuilt every synthesis — status would be wiped). A dedicated persistent artifact is the iteration-protection source of truth. |
| **Satisfaction metrics** | `outputs/satisfaction-metrics.md` | Hub + validator (**section-owned** — see Write Split) | Derived | The coverage view. Two writers, but **never clobbering**: each owns distinct sections and read-merge-writes only its own. Formulas are out of scope here — this document only fixes *where the numbers live* and *who owns which section*, not how they are computed. |

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

*(This block is a deliberately simplified illustration of the link-don't-copy rule — the per-traveler file follows the fuller `Category:` / `Specific:` / `Applies to:` shape defined in The Needs-vs-Desires Model below.)*

Trip-context owns the trip-level constraint — note its name and description cover **both** the stair limit and the continuous-walking ceiling, so the per-traveler walking-distance need links to it without a name/description mismatch:

```markdown
## Hard Constraints

### Limited stair & walking tolerance
- Description: Cannot manage long or repeated stair climbs or long continuous walks; step-free routing and short walking legs with sit-down breaks required.
- Applies to: Jordan
- Practical impact: Venues must have step-free access or a lift; keep continuous walking legs short; avoid stations that are stairs-only.
- Bailout requirement: No
```

Jordan's own source file owns the personal *specifics* of that need — and points at the constraint rather than restating it:

```markdown
# Traveler — Jordan

## Needs
- Mobility: prefers fewer than ~15 minutes continuous walking before a sit-down break.
  Applies to: Hard Constraints → "Limited stair & walking tolerance"

## Desires
- Would love one slow museum morning over a packed sightseeing day.
- Strong interest in local markets; happy to skip nightlife.
```

The enrichment agent reconciles the two into the derived model — carrying the *link*, not a second copy of the constraint:

```markdown
# Traveler Model [DERIVED]

## Jordan
- Need → Hard Constraints "Limited stair & walking tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, sit-down breaks.
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
- **Overlap** — which **other** travelers share this desire (by name), or `solo` if no one else lists it. This is the **desire-overlap signal**: it surfaces where the group already agrees. The match rule the enrichment agent applies is: **two desires overlap when they share a theme tag after case/stem normalization (the deterministic spine), OR when enrichment judges them the same desire in plain-language sense (the augment).** The tag-spine is the reproducible part; the sense-match is the judged augment that catches agreement the tags missed. Because tags are free-text and judgment varies, the signal is **advisory and may shift between refreshes** until the group's tags are normalized — it surfaces likely agreement, it does not certify it. A traveler authoring their own file may leave Overlap blank or note who they *think* shares it; the derived model carries the reconciled answer.

> **Priority tiers are structural labels, not numeric weights.** `anchor` / `wish` / `nice-to-have` rank a traveler's desires by importance so a later capability knows what matters most — they are **not** scores, weights, or coverage percentages, and nothing in this layer multiplies, sums, or optimizes against them. The tier says "this matters more than that"; it does **not** say "this is worth 0.8". How a future capability *balances* desires across the group, or *measures* how well a plan satisfies them, is out of scope here (see What This Document Does Not Define). This document defines the structure the tiers live in; it does not define any math over them.

### Worked example — a per-traveler file

Jordan's `travelers/Jordan.md`, written out in the full model (extending the smaller illustration in the Reconciliation Rule above):

```markdown
# Traveler — Jordan

## Needs
- Category: Mobility
  Specific: prefers fewer than ~15 minutes continuous walking before a sit-down break; step-free routing.
  Applies to: Hard Constraints → "Limited stair & walking tolerance"
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
- Need → Hard Constraints "Limited stair & walking tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, step-free.
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
| **Derived — status & metrics** | (derived) | Status: hub (primary writer), enrichment seeds initial `locked` rows, validator reads only · Metrics: hub + validator, **section-owned** (no clobber) | `outputs/event-status.md`, `outputs/satisfaction-metrics.md` |
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

So the substrate adds a fourth lifecycle pattern — **persist-mutable**: a single file, updated in place, that persists across re-runs and is *read* (never blindly overwritten) by synthesis. Persist-mutable is not append-only: rows are mutated in place, and a row is **deleted** in the one case where its event is removed from the itinerary (see Orphan removal below) so no ghost row lingers. The other two new artifacts fit the existing **rebuilt** pattern (b) because they are pure derived projections of authoritative inputs.

---

## The Per-Event Status Model

The lifecycle classification above fixes *where* per-event status lives (`outputs/event-status.md`) and *how* it behaves over re-runs (persist-mutable). This section fixes *what* it holds: the structured per-event state that supersedes the coarse free-text `## Locked Elements` precursor in `trip-context.md`, and from which the hub, the scheduler, and the validator read whether an event is open to change and whether it still needs a booking.

Every event the itinerary places — an anchor activity, an anchor meal, a day trip, a fixed reservation — carries **exactly one** status. The status is the per-event answer to two questions a planning pass keeps asking: *is this event open to change?* and *does this event still need a booking?*

### The four statuses

| Status | Booking | Open to iteration? | Meaning |
|--------|---------|--------------------|---------|
| **planned** | not booked — may still need a reservation | **yes** — freely tweakable | The working state. The event is a current pick the engines iterate toward `locked`. Resequencing and iteration may move, replace, or re-time it. |
| **locked** | booked / confirmed | **no** — preserved | A reservation is made (a held dinner table, a purchased day-trip ticket, a confirmed hotel). Not re-litigated; iteration leaves it untouched unless the user names it. |
| **firmed** | none needed | **no** — preserved | A decided event with nothing to book (a free landmark walk the group has settled on, a fixed rest morning). Protected from churn so iteration does not keep re-opening a settled choice — but there is no reservation behind it. |
| **option** | nothing to book *while it is an option* — though it **may carry `requires booking? = yes`** (a bookable backup, e.g. a restaurant alternative that would need a reservation if chosen) | n/a — not a primary slot | A backup / alternative held against a primary slot — exactly the engine's existing **alternative** (or **bailout**) concept, now status-tracked. It is never a primary pick, so it is never auto-promoted into one; it is the pool iteration draws *from*, not a slot iteration protects. An `option` never *shows* as "needs booking" because the derivation requires `status = planned` — but its `requires booking?` flag is real and **takes effect on promotion**: when it flips to `planned`, a `requires booking? = yes` option immediately reads as needs-booking. |

The distinction `firmed` draws that the old free-text list could not: an event can be **decided and protected** without being **booked**. `locked` and `firmed` are both preserved across iteration; they differ only on whether a reservation sits behind them — which is exactly the booking-readiness axis below.

**Status transitions, including the cancellation edge.** Status moves forward as an event is decided and booked — `planned → locked` (a working pick gets a reservation), `planned → firmed` (an unbookable pick is settled), and a deliberate `option → planned` / `option → locked` on an explicit promotion (below). It also moves **backward**: a booked event can fall through — a cancelled reservation, a sold-out ticket, a withdrawn hold — so the reverse edge **`locked → planned`** is part of the model. When a `locked` event regresses to `planned`, it re-opens to iteration and its booking question reopens (the derived "needs booking" recomputes to `yes` if `requires booking? = yes`). This is the only way a preserved event becomes movable again without the user explicitly naming it: the booking behind it ceased to hold.

### Field shape — one enum plus a `requires booking?` flag

Status drives two *orthogonal* things: **change-protection** (is the event open to iteration?) and **booking-readiness** (does it still need a reservation?). The field shape has to carry both without letting them drift apart. Two shapes were considered:

- **(a) A single four-value `status` enum, plus a separate `requires booking?` boolean** — needs-booking is *derived* from the two (`needs booking` ⇔ `status = planned` **and** `requires booking? = yes`).
- **(b) Two independent fields** — a change-protection state *and* a booking state, tracked separately per event.

**Decision: shape (a) — a single `status` enum (`planned` / `locked` / `firmed` / `option`) plus a `requires booking?` flag.** Rationale:

1. **"Exactly one status per event" is the literal field.** The acceptance criterion is that every event carries exactly one status. A single enum *is* that one status — unambiguous to read, to audit, and to render. Two independent fields reintroduce the question "which field is *the* status?", and make "exactly one" something you have to reconstruct rather than read.
2. **The booking axis is not symmetric across the enum — so a full second field would be mostly derivable.** Only `planned` has a **live** booking question: `locked` is already booked, `firmed` has nothing to book, and an `option` — even one whose `requires booking? = yes` (a bookable backup) — has no *active* booking obligation while it is held as an alternative (its flag takes effect only on promotion to `planned`). So across the enum the *active* needs-booking decision lives at exactly one value. A single `requires booking?` boolean — which only *surfaces* a booking while `status = planned` — captures the one residual degree of freedom there: a `planned` activity that needs no reservation (a walk-up) versus a `planned` restaurant that needs one but has not made it yet. The flag itself is a property of the event's kind and is carried on every status (so it is ready when an `option` is promoted); the derivation just gates *when it surfaces* to `planned`.
3. **Change-protection is fully determined by the enum — no second field needed for it.** `planned` is open; `locked` / `firmed` / `option` are preserved. The protection axis reads straight off the enum, so the only thing the second field has to encode is the booking residual — which is the boolean, not a parallel state machine.
4. **Both derived views fall out cleanly.** "Needs booking" and "all events locked" (below) are simple predicates over `status` + `requires booking?`. Nothing has to reconcile two state fields that could contradict each other (shape (b) admits nonsense like "open to change but booked").

`requires booking?` is a property of the event's *kind* (a restaurant table, a timed ticket, a hotel → `yes`; a public-park walk, a self-guided wander → `no`), not of its current status. It is set once when the event enters the model and rarely changes; `status` is what moves as the event is iterated and then booked.

> **No optimization here.** Status and the booking flag are *state*, not scores. Nothing in this layer ranks events by status, weights `anchor` desires against `locked` events, or optimizes a schedule against the status field. Status records *what has been decided and booked*; it does not compute *what should be*. Scheduling-optimization and ranking logic are out of scope (see What This Document Does Not Define).

### `outputs/event-status.md` shape

A flat per-event table, one row per event, keyed by a stable **Event ID** plus the day the event currently sits on. The Event ID is **opaque and day-independent** — **minted by the hub on first placement** and stable across every re-run — and it is the **cross-run join key** that lets a re-synthesis match a row to the same event. It must **not** encode the day (the `Day` column carries that): resequencing routinely moves an event to a different day, so a day-encoded ID would either lie or force a churned key. The illustrative IDs below (`evt-01`, …) are opaque on purpose; real IDs may be any opaque token but **must** be day-independent. Updated **in place** (persist-mutable): a re-synthesis *reads* this file to know what to preserve, and writes back only the rows whose status actually changed.

```markdown
# Event Status [persist-mutable]

> One row per placed event. Exactly one status each.
> Iteration changes only `planned` rows; `locked` / `firmed` are preserved unless the user names them.
> `option` rows are alternatives/bailouts — never auto-promoted into a primary slot.

| Event ID | Event | Day | Status | Requires booking? | Needs booking (derived) | Notes |
|----------|-------|-----|--------|-------------------|-------------------------|-------|
| evt-01 | Riverside izakaya (anchor dinner) | Day 2 | locked  | yes | no  | Table held 7:30 PM |
| evt-02 | Hillside museum morning           | Day 3 | firmed  | no  | no  | Group-settled; nothing to book |
| evt-03 | Market hall lunch                 | Day 3 | planned | yes | yes | Needs a reservation — not yet booked |
| evt-04 | Old-town self-guided wander       | Day 4 | planned | no  | no  | Walk-up; no booking needed |
| evt-05 | Noodle counter (Day 3 lunch alt)  | Day 3 | option  | no  | no  | Backup for evt-03; alternative pool |
```

> **Event ID is opaque and day-independent.** The IDs above carry no day (the `Day` column does). `evt-05`'s note references its primary by ID (`evt-03`), not by a day-coded name — so when resequencing moves either event to another day, the join key and the cross-reference both still hold.

The `Needs booking (derived)` column is shown for human scannability but is **computed, not authored**: it is `yes` exactly when `Status = planned` **and** `Requires booking? = yes`. A writer never sets it by hand; the hub recomputes it whenever it touches a row. (The examples use the public Pat / Jordan / Sam persona set.)

### How booking-readiness and "all events locked" derive

Both site readiness surfaces and the validator's booking check read these predicates off the table — they are not separately authored state:

- **"needs booking"** for an event ⇔ `status = planned` **and** `requires booking? = yes`. By construction, `firmed`, `locked`, and `option` events *never* surface as "needs booking" — `firmed` has nothing to book, `locked` is already booked, and an `option` is not a primary slot (so even a `requires booking? = yes` backup stays silent until it is promoted to `planned`).
- **"all events locked"** ⇔ there is **no** event with `status = planned` **and** `requires booking? = yes` (i.e. no outstanding *planned-needs-booking* event remains). It does **not** require every event to be literally `locked`: a trip of `firmed` and `option` events with no open bookings is legitimately "all booked / nothing outstanding". Phrased over the derived view: *all events locked* ⇔ the "needs booking" set is empty.

This is the precise sense in which the booking checklist can show "everything booked" while the itinerary still contains `firmed` and `option` events — the checklist tracks the *needs-booking* set, which those statuses are not in.

### Orphan removal — the one deletion persist-mutable permits

Persist-mutable means rows are updated in place rather than wiped — but it is **not** append-only. There is exactly one case where a row is **deleted**: when an event is removed from the itinerary entirely (dropped on an iteration, replaced and not retained as an `option`), its row is **deleted from `event-status.md`**. A removed event must not leave a ghost row behind: a lingering `planned`-needs-booking row would corrupt the "needs booking" set (surfacing a booking for an event that no longer exists), and a lingering row would also distort the "all events locked" predicate. Deletion of a removed event's row is therefore the correct in-place mutation, not a violation of persistence — persistence protects the status of events that *remain*; it does not preserve events that are gone. (A demotion is different from a deletion: an event the planner keeps as a backup becomes an `option` row, not a deleted one. Only genuine removal deletes.)

### How `option` reuses the existing alternatives / bailouts concept

`option` introduces **no new concept** — it is the status that the engine's *existing* alternatives and bailouts already are, now tracked in the same place as every other event:

- The scheduler's **alternatives** (the per-day options that vary on price and effort) and its **bailout** (the named indoor escape for a 3+ hour outdoor block) are, in status terms, `option` events. They are held against a primary slot; they are not the primary pick.
- Because an `option` is by definition *not a primary slot*, iteration and resequencing **never auto-promote** it into one. Promotion is a deliberate act — the user (or the hub on an explicit instruction) re-points a primary slot at an option, which flips that event's status from `option` to `planned` (or straight to `locked` if booked at the same time). Absent that explicit act, an `option` stays an alternative across every re-run.
- The venue-matrix's `Alt` and `B` cells and the event-status `option` rows describe the *same* events from two angles: the matrix is rebuilt each synthesis to show *current placement*; the status table persists to record *what has been decided*. They must agree — an event marked `option` in status should appear as `Alt`/`B` (never `A`) in the matrix.

So `option` is the bridge between the satisfaction layer's status model and the engine's long-standing alternative/bailout architecture — one vocabulary, not two.

### Superseding the `## Locked Elements` precursor

`trip-context.md` keeps its coarse `## Locked Elements` and `## Current Itinerary Status` notes as **trip-level** human-readable context — they remain the sacred file's plain-language summary of "what's fixed". These free-text notes are **operator-maintained** — the planner's own human summary, not an agent-written field: they are not `[ENRICH]`-tagged, so the enrichment agent does **not** write or maintain them (its contract is `[ENRICH]`-only). The **structured, per-event source of truth** for the three consumers (scheduler, hub, validator) is `outputs/event-status.md`:

| Free-text precursor (`trip-context.md`) | Structured layer (`outputs/event-status.md`) |
|------------------------------------------|----------------------------------------------|
| "Day 4 dinner: Riverside izakaya, 7 PM confirmed reservation" | a row `evt-11 … Day: 4, Status: locked, Requires booking?: yes` |
| "Day 2: day trip — tickets purchased" | a row `evt-12 … Day: 2, Status: locked, Requires booking?: yes` |
| "Hotel confirmed — no alternatives needed" | a row `evt-13 … Day: —, Status: locked, Requires booking?: yes` |
| "Day 3 museum morning — group settled, nothing to book" | a row `evt-14 … Day: 3, Status: firmed, Requires booking?: no` |

The free-text list says *that* something is fixed; the structured layer says *which event*, *under which status*, and *whether a booking sits behind it* — the detail the consumers need and the free-text list cannot carry. Per the link-don't-copy rule, the structured layer does not restate the trip-level constraint text; it tracks the *event's* state. Where the two could drift, the structured table is authoritative for the three consumers and the free-text note is the human summary.

> **Write ownership — primary-writer decision (row-level split confirmed at the control-flow gate).** The primary-writer roles for `event-status.md` are **decided here**, not deferred:
> - The **hub is the primary writer.** It writes status during synthesis and patching — it is the agent that places events, books them, and settles them (`planned` → `locked` / `firmed`), and it owns creation of the file (below).
> - The **validator reads it and writes nothing to it.** It audits status against the itinerary and routes any mismatch to the hub's remediation list; it never mutates a status row.
> - The **enrichment agent may seed initial `locked` rows** from the trip-context `## Locked Elements` notes on setup (a one-time bootstrap seeding of already-known fixed events). This is the only writer role beyond the hub, and it is setup-only.
>
> What remains the control-flow contract's call is the **precise row-level write split** — exactly which agent touches which row in which pass. The *primary-writer roles* above (hub = primary writer, validator = read-only, enrichment = initial-seed only) are settled at this layer; the row-level sequencing is confirmed at the control-flow gate.

### Bootstrap — who creates `event-status.md`

The **hub creates `outputs/event-status.md` on the first full synthesis** (DISCOVERY / ENRICHMENT mode) **if it does not already exist**, seeding any already-known `locked` events (a held reservation, a purchased ticket, a confirmed hotel) — including any `locked` rows the enrichment agent seeded from `## Locked Elements` on setup. On every subsequent pass the file already exists, so the hub **reads it, then updates it in place** (never re-creates it). This is the persist-mutable contract's creation edge: created once, on first synthesis; read-then-updated thereafter; never regenerated from scratch.

---

## Forward Connection — Profile Edits as a Replanning Trigger

Because each per-traveler file is independently editable, the system gains a capability the old free-text model could not offer: **change detection on traveler preferences.**

The enrichment agent can diff each `travelers/<traveler>.md` against the snapshot it last processed. When a file has changed — a new desire, a revised need, a dropped preference — the agent emits an **update signal**. That signal is a candidate **replanning trigger**: a changed preference can warrant an equity-aware re-plan, alongside the existing missed-booking trigger derived from event status.

This document describes the *capability* and the *data condition* that produces it (an edited source file, detected by diffing against the last-processed snapshot). The replanning behavior the signal triggers — when to re-plan, and how to balance the group fairly — is owned by the replanning capability, not by this substrate. The substrate's job is only to make the signal detectable and to carry it.

---

## Satisfaction Metrics

The storage-homes table fixes *where* the coverage view lives (`outputs/satisfaction-metrics.md`) and *how* it behaves over re-runs (rebuilt/refreshed — pattern (b), a snapshot recomputed from the current itinerary and traveler model). This section fixes *what* it holds: the **named dimension set** the validator and hub track for a trip, each dimension's **type**, and the artifact's **shape**.

It defines the **measurable surface** only. It does **not** define how any balance dimension is scored — no formula, no weight, no threshold, no ranking math. That boundary is deliberate and load-bearing: per the document's own rule, nothing in the satisfaction layer optimizes yet, and "how a coverage number is computed is out of scope." This section names *what is measured and what kind of signal each is*; the scoring of the balance dimensions is **left to design**.

### Three metric types

Every dimension is exactly one of three types. The type — not a number — is what this layer fixes:

| Type | What it answers | Verdict it yields |
|------|-----------------|-------------------|
| **pass/fail** | Is a hard gate honored? | `pass` / `fail` — a binary gate. A `fail` means the plan is *broken* on that dimension, not merely sub-optimal. |
| **covered / not** | Is a specific want met by the plan at all? | `covered` / `not covered` — a boolean presence check. Not a degree, not a percentage. |
| **balance signal** | Is something distributed or present in healthy measure across the trip? | A named signal to *track* — its meaning is defined here; **how it is scored is left to design**. No verdict enum is fixed at this layer. |

The split mirrors the needs-vs-desires model: a **need** bounds the solution (so its metric is a hard **pass/fail** gate), and a **desire** is optimized within the bounds (so its baseline metric is **covered / not** — was it met at all — with the *quality* of the optimization being a **balance signal** left to design). pass/fail and covered/not are *fully defined* here — they are determinable from the itinerary, the traveler model, and the per-event status today. The balance signals are *named and given meaning* here, but their scoring is the design boundary.

### The dimension set

Five dimensions make up the satisfaction coverage view. Each is named, typed, and given a definition — and for the balance signals, an explicit note that the scoring is deferred.

| Dimension | Type | Granularity | What it measures | Scoring |
|-----------|------|-------------|------------------|---------|
| **Needs-compliance** | **pass/fail** | per need × per applicable day | Every traveler **need** (the four categories — heat tolerance, mobility, dietary/health, required rest) is honored on every day that need applies to. A hard gate, evaluated per need per applicable day: each (need, applicable-day) pair is `pass` or `fail`. This is the structured metric form of the existing every-day hard-constraint audit (see Reconciliation below) — **not** a balance score. | Fully defined: it is a pass/fail gate. No formula needed — a need is either honored that day or it is not. |
| **Desire-coverage** | **covered / not** | per traveler × per desire | Each traveler's **desires** (the anchors and wishes from their source file) are either met by the plan or not. A boolean presence check per desire, reported per traveler. | Fully defined: a desire is `covered` or `not covered`. No degree, weight, or percentage — that would be scoring, which is out of scope. |
| **Group-equity** | **balance signal** | per trip (across travelers) | Whether the plan serves the travelers *evenly* — that no traveler is systematically over- or under-served relative to the group. A balance signal across travelers' coverage. | **Left to design.** This layer names the signal and its meaning; it does **not** define how evenness is measured, what counts as "systematically under-served", or any fairness threshold. |
| **Experience axes** | **balance signal** | per trip (optionally per day) | Whether the trip carries a healthy measure of four experiential qualities: **creativity**, **fun**, **excitement**, and **newness**. Four named balance signals, tracked so a later capability can read the trip's experiential shape. | **Left to design — and note these axes have no upstream data source in the substrate today** (unlike needs and desires, nothing in the per-traveler files or the itinerary yet grounds them), so a later capability must define **both their source and their scoring**; today they are named, ungrounded, and `(left to design)`. |
| **Rest-recovery balance** | **balance signal** | per trip (across days) | Whether recovery is adequate relative to activity intensity — enough rest/downtime against the demand the plan places on the group. A balance signal over the activity-vs-recovery rhythm. | **Left to design.** Note the seam: the **required-rest** *need* is a hard pass/fail gate under needs-compliance (a non-negotiable rest floor honored or not); **rest-recovery balance** is the softer, trip-wide *signal* of whether the overall rhythm is healthy beyond that floor. The floor is gated; the balance is a signal whose scoring is deferred. |

> **The line this section holds.** Needs-compliance and desire-coverage are *defined to completion* because pass/fail and covered/not are determinable facts about a plan — no math is invented to produce them. Group-equity, the four experience axes, and rest-recovery balance are *defined as named balance signals with stated meaning*, but their scoring is **left to design** — consistent with "nothing optimizes yet". If a future reader is tempted to add a weight, a percentage, or a ranking to any balance signal, that belongs to a later optimization capability, not to this substrate.

### A need's applicable-day set — how it is derived

Needs-compliance is evaluated *per need per applicable day*, so the **applicable-day set** for each need must be defined. It is derived from the **governing trip-context constraint** the need links to (via "Applies to"): a need applies on exactly the days — and within the time blocks — that its constraint governs. Read it off the constraint's `Time blocks affected` / `Applies to` fields (and the scheduling framework's per-constraint day impact):

- A **constant-applicability** need — one whose constraint holds every day regardless of plan (a mobility limit, a dietary/health restriction) — applies on **all days**.
- A **conditional** need — one whose constraint only bites under certain conditions (a heat ceiling that applies on hot or outdoor-afternoon days; a required-rest floor that applies on its scheduled rest days) — applies on **its applicable subset** only.

This reconciles the language elsewhere that the audit runs "every day": the audit runs **every day the constraint applies** — which is all days for constant-applicability needs and the applicable subset for conditional needs. It is never "every calendar day unconditionally" for a conditional need (a heat ceiling is not *failed* on a cool indoor day it never governed). This rule is stated **here once**; the hub and validator cite it and do not redefine it.

> **Desire-coverage is typed per tier — a missed anchor is not a missed nice-to-have.** Coverage is `covered` / `not covered` reported **per desire, carrying that desire's priority tier**. The tier travels with the verdict on purpose: a `not covered` **anchor** is a categorically more significant outcome than a `not covered` **nice-to-have**, and a later scorer must not flatten the two into one undifferentiated "coverage %". This layer keeps them distinct by reporting the tier alongside each verdict; it does **not** weight them (that would be scoring) — it just refuses to lose the distinction.

### Write split — section ownership (two writers, never clobbering)

`satisfaction-metrics.md` has **two** writers — the hub and the validator — and the naive "each writes the file fresh" would have the second writer **clobber** the first. The substrate forbids that with **section ownership**: each agent owns specific sections and **reads-merges-writes only its own**, never wiping the other's:

| Section | Owner | Why |
|---------|-------|-----|
| **Desire-coverage** (covered / not, per traveler × per desire) | **Hub** | The hub builds the itinerary, so it holds the coverage read — which anchors/wishes the plan it just produced actually meets. |
| **Balance signals** (group-equity, the four experience axes, rest-recovery balance — all `(left to design)`) | **Hub** | Emitted alongside the hub's coverage read; named and tracked, never scored. |
| **Needs-compliance** (pass/fail, per need × per applicable day) | **Validator** | This is the *recorded form of the validator's every-day constraint audit*; the validator is its natural owner (and the hub's own audit must agree with it). |
| **Needs ↔ constraint agreement check** | **Validator** | The validator owns the reconciliation that every needs-compliance `fail` is a constraint Critical (see Reconciliation below). |

The rule each writer follows: **read the current file, replace only your own section(s), write the merged whole back** — never regenerate the file from scratch, never touch a section you do not own. The artifact is still rebuilt/refreshed each synthesis (pattern (b)) — *each section* is refreshed by its owner from authoritative inputs — but the refresh is per-section, so the two writers compose into one file instead of overwriting each other. (If a future control-flow design prefers a single writer, the clean alternative is to make the **validator the sole writer** and have the hub pass its coverage read in as an input — but the section-ownership split above is the decided model for this substrate.)

### `outputs/satisfaction-metrics.md` shape

A `[DERIVED]` artifact, rebuilt/refreshed from the current itinerary and the current `outputs/traveler-model.md` (it carries no independent state — its inputs are authoritative, so regeneration is safe). It records each dimension at its natural granularity: needs-compliance per need per applicable day, desire-coverage per traveler per desire, and the balance signals named with their value **left to design** (shown as `(left to design)` rather than a number).

```markdown
# Satisfaction Metrics [DERIVED]

> Rebuilt/refreshed from the current itinerary + outputs/traveler-model.md.
> pass/fail and covered/not are determinable today; balance-signal scoring is left to design.
> Persona names follow the public Pat / Jordan / Sam set.

## Needs-compliance — pass/fail, per need × per applicable day
> Each traveler need honored on every day it applies to. A `fail` means the plan is broken on that day.

| Traveler | Need (category) | Applicable days | Per-day verdict | Overall |
|----------|-----------------|-----------------|-----------------|---------|
| Pat    | Heat tolerance (afternoon ceiling) | D1, D3, D4 | D1 pass · D3 pass · D4 pass | pass |
| Jordan | Mobility (step-free, walking ceiling) | all days | D1 pass · D2 pass · D3 **fail** · D4 pass | **fail** |
| Jordan | Required rest (slow start every other day) | D2, D4 | D2 pass · D4 pass | pass |
| Sam    | Dietary/health (allergy) | all days | all pass | pass |

## Desire-coverage — covered / not, per traveler × per desire
> Each anchor/wish met by the plan or not. Boolean presence — not a degree.

| Traveler | Desire | Priority tier | Covered? |
|----------|--------|---------------|----------|
| Jordan | Slow museum morning | anchor | covered |
| Jordan | Local markets       | wish   | covered |
| Pat    | Local market        | anchor | covered |
| Pat    | Relaxed museum morning | wish | covered |
| Sam    | One standout food experience | anchor | covered |

## Balance signals — named; scoring left to design
> These are signals to track, not scores. How each is measured is a later-capability decision.

| Balance dimension | Granularity | Value |
|-------------------|-------------|-------|
| Group-equity | per trip (across travelers) | (left to design) |
| Experience axis — creativity | per trip | (left to design) |
| Experience axis — fun | per trip | (left to design) |
| Experience axis — excitement | per trip | (left to design) |
| Experience axis — newness | per trip | (left to design) |
| Rest-recovery balance | per trip (across days) | (left to design) |
```

The pass/fail and covered/not tables carry real verdicts because they are determinable from the plan. The balance-signals table carries `(left to design)` in every value cell on purpose: the dimensions are *named and tracked*, their scoring is *not yet defined*. (The metrics examples use the public Pat / Jordan / Sam persona set.)

### Reconciliation — needs-compliance is the existing every-day audit, made structured

The system already holds the rule **"hard constraints are audited every day they apply"**: the hub checks every applicable day against every hard constraint, and the validator double-checks. **Needs-compliance does not introduce a new rule — it is the structured metric form of that existing audit.** Each traveler need links (per the Reconciliation Rule) to a governing `trip-context.md` constraint; needs-compliance records, per need per applicable day (the applicable-day set derived as defined above), whether that constraint was honored — the same check the constraint-compliance audit already performs, now emitted as a per-need-per-day pass/fail record rather than only a prose finding.

**The agreement is a forward implication, not an equivalence.** Every needs-compliance `fail` **is** a constraint-compliance Critical — a per-traveler need is broken exactly when the constraint it links to is violated, so a `fail` always has a Critical counterpart. The converse does **not** hold: a constraint Critical need **not** have a needs-compliance counterpart. A trip-level or group constraint with no per-traveler *need* linking to it (a destination-wide rule, a group-level non-negotiable that no individual traveler's need points at) produces a constraint Critical with **no** needs-compliance row — by design, because needs-compliance is keyed to per-traveler needs and that constraint has none. So: *needs-compliance `fail` ⇒ constraint Critical* (always); *constraint Critical ⇒ needs-compliance `fail`* (only when a per-traveler need links to that constraint). The validator must not enforce the reverse as an invariant — an unlinked constraint Critical with no needs-compliance row is correct, not a discrepancy. The metric is the audit's *recorded shape* for the per-traveler-need slice, not a second, competing judgement.

---

## What This Document Does Not Define

To keep the substrate boundary clear:

- **No metric formulas or scoring math.** `satisfaction-metrics.md` has a *home* here, and the Satisfaction Metrics section above names and types every dimension — but how any **balance signal** (group-equity, the experience axes, rest-recovery balance) is *scored* is out of scope. pass/fail and covered/not are determinable facts; the balance scoring is left to design.
- **No optimization or ranking logic.** Nothing in the satisfaction layer optimizes yet. The engines *read* the derived model; this document does not specify what they do with it.
- **No replanning policy.** The update signal is defined as a data condition; the decision to re-plan and the fairness logic live with the replanning capability.
- **No control-flow / consumption sequencing.** Who runs when, and how the hub consumes these artifacts in a pipeline pass, is governed by the control-flow contract, not this data-architecture document.

This file is the **data** contract. Behavior contracts live with their respective agents and capabilities.
