# Data Model — The Satisfaction Layer

The satisfaction layer's specialization of the engine-wide data architecture in `reference/data-architecture.md`. It defines **where each new piece of satisfaction data lives, what shape it takes, who writes it, how it flows, and how it reconciles** with the existing `trip-context.md` — so every satisfaction slice builds to one decision rather than re-deciding storage independently.

This document governs the data **substrate** only — storage homes, artifact shapes, write ownership, and reconciliation, plus this layer's own lifecycle *assignments* against the classes defined in `reference/data-architecture.md` § *Lifecycle Classes*. It deliberately does **not** define metric formulas, scoring algorithms, or any optimization logic, and it does not define the lifecycle classes themselves. Nothing in the satisfaction layer optimizes yet; this is the foundation those later capabilities will read from.

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
| **Per-traveler source files** | `trips/<destination>-<year>/travelers/<traveler>.md` | Human (the traveler / planner) | Layer 1 — human-authored | Keeps heavy per-traveler detail out of sacred `trip-context.md`; enables async per-traveler authoring (each traveler fills/edits on their own time); makes each file an independent **change surface** (see Forward Connection). Filled from `templates/traveler-intake.template.md`. |
| **Derived traveler model** | `outputs/traveler-model.md` | Enrichment agent | Derived `[DERIVED]` | The reconciled, machine-usable projection of all per-traveler files — each read as its **composed** source, the file together with the durable person record it references, per § *Composition — the trip-side read of a durable record*; a file carrying no reference composes to itself — **plus** the desire-overlap signal, and **plus one stated exception**: the `[THIRD-PARTY]` entry admitted through the operator fallback, whose subject has no source file by design (see the stated exception under **Needs**), is *carried forward verbatim* across a refresh rather than projected from a file. One place the engines and hub read instead of parsing N source files. |
| **Per-event status** | `outputs/event-status.md` | **Hub (primary writer)**; enrichment seeds initial `locked` rows on setup; validator reads only | Derived, persist-mutable | Per-event state must **persist across synthesis re-runs**. It cannot live in `trip-context.md` (banned itinerary content) nor in `venue-matrix.md` (rebuilt every synthesis — status would be wiped). A dedicated persistent artifact is the iteration-protection source of truth. |
| **Satisfaction metrics** | `outputs/satisfaction-metrics.md` | Hub + validator (**section-owned** — see Write Split) | Derived | The coverage view. Two writers, but **never clobbering**: each owns distinct sections and read-merge-writes only its own. Formulas are out of scope here — this document only fixes *where the numbers live* and *who owns which section*, not how they are computed. |

> **Sacred rule, restated for this layer.** No per-traveler desire detail, no per-event status, and no metrics go **into** `trip-context.md`. The per-traveler *needs* still reconcile **against** the trip-level constraints in `trip-context.md` (see Reconciliation) — but by *link*, never by copy, and the satisfaction artifacts above are their homes.

### Per-traveler source file — what it owns

Each `trips/<destination>-<year>/travelers/<traveler>.md` is one traveler's own file, authored from `templates/traveler-intake.template.md`. It owns:

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

*(This block is a deliberately simplified illustration of the link-don't-copy rule — the per-traveler file follows the fuller `Category:` / `Specific:` / `Applies to:` shape defined in The Per-Traveler Model below. Every fence here shows an artifact's **body only**: each of these artifacts also carries frontmatter, elided throughout this document — see § *Serialization — the satisfaction-layer projection*.)*

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

## The Per-Traveler Model

The reconciliation rule above fixes *how* per-traveler data links back to the trip-level constraints. This section fixes *what* a per-traveler file actually holds.

The file is the **individual traveler's preferences only** — what *they* want, need, and prefer. It never holds group-level data: the pipeline aggregates these N individual files into a group view, and any splits or side-bars are pipeline-derived (see the scaling story and forward-hooks below), **never authored in the individual file.**

Its load-bearing structure is the **needs-vs-desires** distinction — every file separates a traveler's **needs** from their **desires** — and around that core it captures a handful of additional **lifecycle facets** (party, destination leanings, dates, journey & origin, accommodation, budget appetite, travel style, interests, people dynamics) so one file can serve a trip from first idea through enrichment.

**The governing definition (the needs-vs-desires core):**

> **A need is a constraint that bounds the solution. A desire is an objective optimized within those bounds.**

A need is non-negotiable — the plan is either inside it or it is broken (a heat ceiling, a mobility limit, an allergy, a required rest window). A desire is a want the plan tries to satisfy as well as it can, given the bounds the needs set — but a missed desire is a worse plan, not a broken one. Needs draw the box; desires are what the trip optimizes for *inside* the box.

This is the same need-vs-want split the original system already half-expresses — needs as `## Hard Constraints` / `## Dietary & Health`, wants scattered through free-text "Key Characteristics". The satisfaction layer makes it explicit, per-traveler, and structured.

### Needs

A need is the traveler's personal stake in a trip-level constraint. The constraint itself is trip-level and lives in `trip-context.md` (the SSOT); the traveler's *need* is the personal specific behind it — and it **links** to the governing constraint rather than restating it (per the Reconciliation Rule above).

Needs cover the categories below. Every per-traveler need falls under one:

| Need category | What it bounds | Governing trip-context constraint it links to |
|---------------|----------------|-----------------------------------------------|
| **Heat** | The outdoor-exposure ceiling — how much heat / sun / humidity this traveler can take, and for how long | `## Hard Constraints` (the heat / climate constraint) |
| **Mobility** | The movement envelope — walking distance, stairs, standing time, terrain, rest-break cadence | `## Hard Constraints` (the mobility / accessibility constraint) and `## Dietary & Health` → mobility notes |
| **Dietary-health** | The food-and-health boundary — allergies, restrictions, medical needs, pacing limits | `## Dietary & Health` (and any `## Hard Constraints` block that encodes a health non-negotiable) |
| **Rest** | The recovery floor — the rest this traveler must get (a slow morning, a mid-day break, an early night) for the rest of the plan to hold | `## Hard Constraints` (a rest / pacing constraint) — add one if the rest need is non-negotiable and none exists yet |
| **Budget cap** | A hard personal spend ceiling — a per-day or per-trip limit the plan must not exceed for this traveler | `## Budget Posture` (the trip-level budget; the per-traveler cap refines it, never duplicates it) |
| **Timing** | A fixed time boundary — a hard curfew, an early-night requirement, a must-be-back-by, a fixed arrival / departure window | `## Hard Constraints` (a timing / curfew constraint) |
| **Sensory** | A sensory or medical sensitivity beyond diet — noise, crowds, sun-as-medical, altitude — that bounds where or when this traveler can go | `## Hard Constraints` and/or `## Dietary & Health` (the governing health / sensory note) |
| **Other** | Any non-negotiable that does not fit the categories above | the relevant `## Hard Constraints` block (add one if none exists yet) |

The field shape for a single need:

- **Category** — one of the categories above.
- **Specific** — the personal detail behind the need: the *how much*, the *what exactly*, the personal context. This is what the per-traveler file owns and the constraint block does not.
- **Applies to** — the link to the governing `trip-context.md` constraint, written as `<Section> → "<Constraint name>"`. This is the link, **never a copy** of the constraint text.

> If a traveler states a need with no governing trip-level constraint yet (e.g. a required-rest floor the trip has not captured as a constraint), that is a signal to add the constraint to `trip-context.md` — the SSOT — and then link to it. The per-traveler file never becomes the de-facto home for a trip-level constraint.
>
> **Stated exception — a third-party-sourced need does not escalate.** A need captured for a **party member who has no profile of their own** — supplied by the operator and marked `[OPERATOR-PROVIDED]` + `[THIRD-PARTY]`, per `agents/00-enrichment.md` — is the one case where the rule above does **not** apply. Such a need **never** signals adding a constraint to `trip-context.md`, and the person is **never** added to an existing constraint's `**Applies to:**` roster. **Its home is `outputs/traveler-model.md`**, which the hub applies as a hard bound before any objective and which the site build treats as an intentional exclusion. The reason the exception exists: `trip-context.md` is publish-bound and rendered, so escalating this need would publish health data about a person who was never able to consent to it — which ADR-006 forbids in attributed **or** anonymized form, since in a small named party stripping the name does not strip the identification. The constraint shapes the plan; it is never rendered. The cost is accepted and real: such a need is invisible in `trip-context.md`, so the plan carries a bound whose reason the published artifact does not explain.

### Desires

A desire is something the traveler wants out of the trip — an activity, a food experience, or a more general wish about pace and feel. Unlike a need, it carries a **priority tier** and an **overlap** signal, and it is owned outright by the traveler's own file (it links to nothing — there is no trip-level "desire constraint").

The field shape for a single desire:

- **Desire** — what the traveler wants (the want-to-do, the would-love-to-see, the kind of day they hope for).
- **Priority tier** — exactly one of:
  - **anchor** — a desire the traveler would be genuinely disappointed to miss; the trip should be built to land it.
  - **wish** — a real want the trip should try hard to include, but which can yield to a need or to another traveler's anchor.
  - **nice-to-have** — a bonus; pleasant if it fits, no loss if it does not.
- **Recurrence** *(optional)* — exactly one of:
  - **one-off** — a single occasion somewhere in the trip. One placement satisfies it.
  - **daily** — a want the plan honors on every day of its **honored-day set** — see *A recurring desire's honored-day set — how it is derived* below — never the full trip-day set, and never a rule that depends on the destination.

  Omit the line, or leave it `—`, when the desire is one-off: an unstated recurrence is planned as `one-off`. This is the one field where *not stated* and a stated value coincide in effect, and it is safe **only** because the two produce the same plan — silence never manufactures a daily obligation. (Contrast `Been here before?`, where an unanswered field must read *unknown* and never `never`, because there the two readings calibrate depth in opposite directions.)
- **Theme tag(s)** *(optional)* — one or more free-text tags grouping the desire by kind (e.g. `food`, `markets`, `museums`, `nightlife`, `nature`, `slow-pace`). Tags are how desires across travelers are matched for overlap; they are descriptive labels, not categories the traveler must pick from.
- **Overlap** — which **other** travelers share this desire (by name), or `solo` if no one else lists it. This is the **desire-overlap signal**: it surfaces where the group already agrees. The match rule the enrichment agent applies is: **two desires overlap when they share a theme tag after case/stem normalization (the deterministic spine), OR when enrichment judges them the same desire in plain-language sense (the augment).** The tag-spine is the reproducible part; the sense-match is the judged augment that catches agreement the tags missed. Because tags are free-text and judgment varies, the signal is **advisory and may shift between refreshes** until the group's tags are normalized — it surfaces likely agreement, it does not certify it. A traveler authoring their own file may leave Overlap blank or note who they *think* shares it; the derived model carries the reconciled answer.

> **Priority tiers are structural labels, not numeric weights.** `anchor` / `wish` / `nice-to-have` rank a traveler's desires by importance so a later capability knows what matters most — they are **not** scores, weights, or coverage percentages, and nothing in this layer multiplies, sums, or optimizes against them. The tier says "this matters more than that"; it does **not** say "this is worth 0.8". How a future capability *balances* desires across the group, or *measures* how well a plan satisfies them, is out of scope here (see What This Document Does Not Define). This document defines the structure the tiers live in; it does not define any math over them.

> **Recurrence is orthogonal to priority tier, and it is a cadence on the want, not on a venue.** The two axes are independent: a daily want may be an `anchor`, a `wish`, or a `nice-to-have`, and a one-off want may be any of the three. Recurrence is **not** a fourth tier and adds nothing to the tier enum, which stays closed at three. It is also not a licence to repeat a place — a recurring desire recurs as a **slot**, and every venue that fills it obeys the two-appearance cap the venue matrix enforces (`CLAUDE.md` → Key Rules, *Venue deduplication*). A week of morning ritual stops is a week of that kind of stop, not seven visits to one address. And a recurring desire is still a desire: it never becomes the day's structural anchor event or anchor meal, whatever its tier.

### Lifecycle facets

Needs and desires are the structural core — but a traveler's preferences span a trip's whole lifecycle, from "where should we even go?" through "what must this day work around?". The per-traveler **composed source** therefore carries nine additional **lifecycle facets** around the needs/desires core. **The facet set spans both intake forms since the split** — some labels are asked on the trip form and some on the durable one, and a traveler composing without a reference has all of theirs in the trip file. Which form asks which label is § *Field Scope* below and is not restated here or in the table's own rows, so this section stays a statement of the facet set rather than a second copy of the partition. Each is the individual's own view; each is captured as data only (nothing here scores, optimizes, or computes a group result — see the forward-hooks). Several **link** to trip-level data rather than duplicating it, per the one-source-per-fact rule above. **All nine are first-party only.** Each facet is a traveler's own statement about themselves, read off the profile they filled in — so none is ever populated on a `[THIRD-PARTY]` entry: the party member admitted to `outputs/traveler-model.md` through the operator fallback carries **needs only**, and carries no facet at all. The bound is the entry class, not a list of fields, so it holds for every facet below and for any facet a later release adds — ADR-006 grants a party member exactly one class, their needs, and there is no default-allow outside it.

> **`Documents:` on `outputs/traveler-model.md` is derived content, not a lifecycle facet.** The per-traveler document set the enrichment agent derives (`agents/00-enrichment.md` § *Derive the per-traveler document set*) is computed from a traveler's facets plus researched entry policy — it is not a statement the traveler made about themselves, so it is not a facet and the facet count above is unchanged by it. It is bounded on its own terms rather than by the first-party rule stated above: no `Documents:` line is emitted on a `[THIRD-PARTY]` entry at all, and a first-party traveler with no filed profile carries it as `unknown` rather than not at all. Reading it as a facet would put a derived value under a rule written for stated ones.

| Facet | Field shape (the labels) | Role | Links to (one source per fact) |
|-------|--------------------------|------|--------------------------------|
| **Party** | `Party:` | Who is travelling with this traveler and will not fill in a form of their own (a child and their age, a partner who is not filing separately). Their own view of who they are responsible for — never the group roster. **A party member's own needs do have a home:** where the operator supplies them, that person is admitted to `outputs/traveler-model.md` as exactly one `## <Name>` entry marked `[OPERATOR-PROVIDED]` + `[THIRD-PARTY]` — **needs only**, no file of their own anywhere, no entry at all without operator input, and never escalated into `trip-context.md` (see the stated exception under **Needs** above). | **Links to** trip-context `## Group` — it refines, never replaces, the trip-level roster; the trip-level Group stays the SSOT. Projects from the template's `## About you` section. |
| **Destination leanings** | `Would love:` · `Rather skip:` · `Trip vibe:` | The traveler's wishlist for *where* to go, for when no destination is fixed yet. | Aggregated by the pipeline into a group destination shortlist (forward-hook below) — the individual file holds only this traveler's leanings, never the shortlist. |
| **Dates & availability** | `Can travel:` · `Blackout:` · `Trip length:` | When this traveler can travel, and for how long. | **Links to** the trip's Logistics once dates are set — it refines, never overrides, the trip-level dates; it is not copied into `trip-context.md`. |
| **Journey & origin** | `Leaving from:` · `Arrive / leave:` · `Journey comfort:` · `Passport:` *(country + validity only — never a number)* | Where this traveler sets out from, whether their arrival or departure differs from the group's, and what they can tolerate in transit. | **Links to** trip-context `## Logistics` — it refines, never replaces, the trip-level travel plan; it is not copied into `trip-context.md`. Projects from the template's `## Getting there & back` section. **The trip level owns origins, not travelers.** `## Logistics` carries one `#### Origin <letter>` block under `### Additional origins` per **additional** departure origin, never one per traveler — cardinality is `O(origins)`, not `O(travelers)`. Travelers attach to an origin by their `## Group` roster name only, so a party of six leaving from two countries adds one block and not five — the anchor origin (`Origin A`) is the unlabelled Outbound/Return pair, never an added block; `Leaving from:`, journey comfort and passport stay per-traveler and are never copied into `## Logistics` — which source holds them for a given traveler is § *Field Scope*'s to say, not this row's. |
| **Accommodation** | `Lodging style:` · `Rooming:` | The traveler's personal lean on where to stay and how to room — the must-haves behind a booking, not the booking itself. | **Links to** trip-context `## Accommodation` — it refines, never replaces, the trip-level booking; the trip-level section stays the SSOT. Projects from the template's `## Where you stay` section. |
| **Budget appetite** | `Comfort range:` · `Splurge appetite:` | The traveler's personal spend lean — day-to-day comfort and what they'd pay up for. | **Links to** trip-context `## Budget Posture` — it refines, never replaces, the trip-level budget; the trip-level posture stays the SSOT. |
| **Travel style & pace** | `Pace:` · `Day rhythm:` · `Novelty vs comfort:` · `Planning style:` | How the traveler likes a trip to feel day-to-day. | Owned by the file (a soft personal signal); no trip-level twin. |
| **Interests & tastes** | `Interests:` · `Cuisine appetite:` · `Been here before?:` · `Already done:` | Broad leanings and prior experience — a soft selection signal, looser than the ranked Desires. `Been here before?` is a closed enum (`never` / `once` / `a few times` / `know it well`) that calibrates recommendation **depth** for the activities and food agents; an unanswered field reads **unknown**, never `never`. | Owned by the file; distinct from (not a duplicate of) the specific tiered Desires; no trip-level twin. **This facet splits on scope, and the split is field-granular rather than facet-wide:** `Been here before?` and `Already done` name *this destination*, so they are meaningful only relative to it and do not travel to another trip, while `Interests` and `Cuisine appetite` are durable statements about the traveler and do travel. See *Field Scope — person-scoped, trip-scoped* below. |
| **People dynamics & togetherness** | `Group time:` · `Split off with:` · `Solo, I'd:` · `Whole-group moments:` | The traveler's own view on together-time vs. own-time, and which moments must include everyone. | Owned by the file as an *individual* view; the pipeline reads it (with desire-overlap and interest divergence) to derive any side-bars — the individual file never authors a split. `Whole-group moments` bounds that derivation (see forward-hook). |

> **Depth calibration is coverage, not a score.** `Been here before?` is read by `agents/01-activities.md`, `agents/02-food.md` and `agents/04-transport.md` to calibrate how obvious or deep a candidate set runs. A mixed party does **not** average to a middle depth: the set carries both the essentials a first-timer would regret missing and at least one less-obvious candidate for each traveler who has been here before. Where one depth is unrepresented in the party, the set leans wholly that way; where a traveler's answer is unknown, they contribute no depth signal in either direction. Nothing here weights, ranks or scores travelers against each other — consistent with this document's own rule that nothing in this layer optimizes.

These facets do not relax the needs-vs-desires core or the link-don't-copy rule — they extend the same individual-only, one-source-per-fact model across the trip lifecycle. **Lifecycle note:** the file spans **IDEATION → ENRICHMENT** — a traveler fills the facets relevant to their trip's current stage (destination leanings matter most before a destination is picked; dates/budget/needs matter once it is), leaving the rest blank.

### Presence — a traveler's present-day set

Several consumers need to know whether a traveler is *at the destination* on a given day: the scheduler places whole-group anchors, the validator grades needs per applicable day and gates nightlife per night, and the hub mirrors the needs audit. The rule is stated **here once**; every consumer cites it and none re-derives it.

**A traveler's present-day set** is the set of trip days on which both limbs hold:

- **In their window** — the day falls inside that traveler's own effective window in `trip-context.md` `## Logistics` → `### Per-Traveler Planning Days [DERIVED]`. That block is the one home for the window; take its values as published. The window is the derived block, **never** the raw `Arrive / leave:` profile field — a traveler whose window basis is `ASSERTED-SAME` tracks a group rebooking while an `ASSERTED-DIFFERENT` window stays pinned, so the raw field and the derived window diverge exactly when it matters.
- **Available that day** — their `Can travel:` / `Blackout:` facets in `outputs/traveler-model.md` do not exclude it.

**A partial day is a whole day to this predicate.** A day the traveler's effective window reaches for **any part of it** — an arrival day from their arrival instant, a departure day up to their departure instant — is **in their window**; only a day the window does not reach at all is outside it. This is the reading the derived block already publishes: it counts a traveler's full **and** partial days together as their effective planning days, and a partial day is a real planning window rather than a fraction of one. **There is no coverage threshold** — a fraction of a day is never a fraction of a membership.

A day failing either limb is **not** in the set. The two failures differ and the distinction is carried, never flattened: **absent** (outside the window — not at the destination) versus **unavailable** (inside the window but excluded that day — here and not free). Only *unavailable* has a parallel track worth planning.

**The window limb is separately named, because grading keys off it alone.** A traveler's **at-destination day set** is the days satisfying the **first limb only** — the days they are at the destination, free that day or not. This is not a second predicate competing with the one above: it is that predicate's window limb, named here so each consumer cites the reading its own job needs instead of re-deriving one. Which reading a consumer takes is fixed here, not chosen locally:

- **Placement reads the present-day set — both limbs.** Deciding *where a thing goes* — a whole-group anchor, the standing slot of a recurring desire, an applicable nightlife night — needs the traveler there **and** free. A slot placed on a day someone is excluded is a slot nobody can take, so a placement that ignored the availability limb would plan for an empty chair.
- **Needs-grading reads the at-destination day set — the window limb.** Deciding *whether a hard constraint is audited* needs only that the plan is doing something with that traveler that day. An **unavailable** traveler is at the destination and carries a full parallel track, so their needs bound that track exactly as they bound the main one — dropping their grade would leave the parallel track unaudited, the mirror of the every-calendar-day defect this rule exists to prevent. **Absent** is the only presence failure that removes a grade: there is no plan-day to honor or to breach.

> **An assumed window never trims a grade.** Where a traveler's `Window basis` is `UNKNOWN`, the block marks the window *(assumed)* and any presence or absence read from it is an assumption, not a fact. On such a traveler, treat every trip day as present for grading and carry the *(assumed)* marking into anything that cites the set. A hard gate is never dropped on a guess.

> **No presence data means every day, never no days.** A subject with no `### Per-Traveler Planning Days [DERIVED]` row and no availability facets has **no derivable window and no derivable availability** — the `[THIRD-PARTY]` party member admitted on needs only, who by design carries no facet at all, is exactly this case. Their at-destination day set is **every trip day**, so their needs are graded on every day the constraint factor admits. Absence of presence data is not evidence of absence, and reading it as an empty set would silently drop the **only** audit surface such a need has: it also has no governing trip-level constraint, so nothing would raise a Critical in its place either. This is the same fail-closed reading as the assumed window above — less data, not different data — and it grants no facet to that person, only a grading default.

> **This predicate is day-granular, and it settles membership only.** It says which days a traveler is present on; it never says what can be placed within one. Where an obligation is scoped to a **time block** — a constraint that reaches only an afternoon, a recurring desire that names a morning — whether that block exists inside a traveler's partial day is decided by **that obligation's own factor**, exactly as a need's applicable days are the constraint's days intersected with this set. The day stays in the set either way: a time block a traveler's window does not contain narrows what that obligation reaches, never whether the traveler is present.

On a trip where every traveler shares the group's window and no blackout applies, every traveler's present-day set is the full trip-day set, and nothing that cites this rule changes behavior. **The grading no-op is wider, and the window alone bounds it:** because needs-grading reads the at-destination day set, a blackout never moves a grade. On any trip where every traveler shares the group's window, every need is graded on exactly the days it was graded on before the presence factor existed — blackouts or not.

### Worked example — a per-traveler file

Jordan's `travelers/Jordan.md`, written out in the full model — **body only**, its frontmatter elided as everywhere in this document — extending the smaller illustration in the Reconciliation Rule above:

```markdown
# Traveler — Jordan

## Needs
- Category: Mobility
  Specific: prefers fewer than ~15 minutes continuous walking before a sit-down break; step-free routing.
  Applies to: Hard Constraints → "Limited stair & walking tolerance"
- Category: Rest
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
- Desire: a morning ritual stop — a café or bakery — before the day starts.
  Priority tier: wish
  Recurrence: daily
  Theme tag(s): food
  Overlap: solo
```

Pat's `travelers/Pat.md` — **body only**, frontmatter elided as above — shares two of those desires, which is what produces the overlap:

```markdown
# Traveler — Pat

## Needs
- Category: Heat
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

The enrichment agent reconciles both files into `outputs/traveler-model.md` — **body only**, frontmatter elided as above, linking each need to its constraint and carrying the computed overlap signal:

```markdown
# Traveler Model [DERIVED]

## Jordan
- Need → Hard Constraints "Limited stair & walking tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, step-free.
- Need → Hard Constraints "Daily pacing floor" (Applies to: Jordan); specific: slow start every other day.
- Desire (anchor): slow museum morning [museums, slow-pace] — shared with Pat.
- Desire (wish): local markets [markets, food] — shared with Pat.
- Desire (nice-to-have): standout coffee [food] — solo.
- Desire (wish, daily): morning ritual stop [food] — solo.

## Pat
- Need → Hard Constraints "Afternoon heat ceiling" (Applies to: Pat); specific: shade/indoors by early afternoon above ~82°F.
- Desire (wish): relaxed museum morning [museums, slow-pace] — shared with Jordan.
- Desire (anchor): local market [markets, food] — shared with Jordan.

## Desire overlap
- museums / slow-pace morning: Jordan (anchor), Pat (wish)
- local markets: Jordan (wish), Pat (anchor)
```

Each constraint still lives once in `trip-context.md`; each traveler's specifics and desires live once in their own file; the derived model references all of it and adds the cross-traveler overlap. No fact has two owners — and nothing here scores, weights, or optimizes; it is structure only.

### How the model scales

The per-traveler model scales along four dimensions. The first three are about how *one* traveler's data grows; the fourth — **Across** — is how *N* individual files compose into a group, and it is the dimension the satisfaction layer adds.

| Dimension | What grows | How the model absorbs it |
|-----------|-----------|--------------------------|
| **Out** (more travelers) | More people on the trip | One more `travelers/<traveler>.md` file — each traveler is an independent change surface; the enrichment agent reconciles however many exist. |
| **Up** (richer per traveler) | More needs / desires / facets per person | Repeatable need and desire blocks ("add as many as you like"); the lifecycle facets fill in as the trip firms up. |
| **Over-time** (across the lifecycle) | The trip moves IDEATION → ENRICHMENT | The same file spans the lifecycle — destination leanings early, dates/needs/budget later; a traveler fills the stage-relevant parts. |
| **Across** (individual ⇄ group) | N individuals become one group view | **The aggregation/decomposition seam.** N individual files **aggregate into a group view** via the **desire-overlap signal** (the default — where the group already agrees), and **decompose into side-bars** via **people-dynamics + desire-overlap + interest divergence** (the exception — where a sub-group's time diverges). Both directions are **pipeline-derived from the individual files** — neither is ever authored in an individual file. |

The **Across** dimension is why the file is kept strictly individual: aggregation and decomposition are only sound if each input is one person's unmixed view. The moment a split were written into an individual file, the group derivation would be reasoning over pre-mixed data.

### Forward-hooks — captured now, computed later

Two group-level capabilities are **enabled** by the data this layer captures but **not built in the individual-file layer** — consistent with the document's deferred items ("nothing optimizes yet"). Both are **pipeline-derived and live nowhere in the individual file**. Hook (a) is now **realized** in the pipeline (see below); hook (b) remains **left to design**:

- **(a) Group destination recommendation.** From the aggregated **destination leanings** (`Would love:` / `Rather skip:` / `Trip vibe:` across all travelers), the pipeline derives a group destination shortlist — **realized** by `agents/destination-ideation.md` (equity-weighted coverage: love-count adjusted so every traveler is represented, `Rather skip` as a hard veto, `Trip vibe` as rationale), which writes `outputs/destination-shortlist.md` as a recommendation the group decides from. This individual-file layer still only captures the per-traveler leanings; it does **not** rank destinations, score fit, or pick one — the aggregation lives in the ideation agent, never in the individual file.
- **(b) Side-bar / group-split computation.** From **people-dynamics** (`Group time:` / `Split off with:` / `Solo, I'd:`) combined with the **desire-overlap signal** and **interest divergence**, the pipeline can later compute side-bars — who does what together at the **single / small-group / full-group** granularity. The computation is **bounded by each traveler's `Whole-group moments`**: a moment a traveler marks whole-group is a constraint the split must respect (that traveler is not peeled off then). This layer captures the inputs; it does **not** compute any split, assign anyone to a sub-group, or schedule a side-bar.

Both hooks are the **Across** dimension's forward edge: the individual files hold the inputs; the *group* result is a later pipeline capability, not a stored field.

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

1. **Reader / reconciler of human input.** It reads every `travelers/<traveler>.md` **as its composed source** — the file together with the durable person record it references, per § *Composition — the trip-side read of a durable record*, which for a file carrying no reference is that file and nothing else, with no store read attempted — links each need to the governing `trip-context.md` constraint, computes the desire-overlap signal, and writes the result to `outputs/traveler-model.md` as `[DERIVED]`. **Its write set is unchanged: the source set widens, the write set does not.** **It also reads the model it is about to replace**, solely to carry the `[THIRD-PARTY]` entry admitted through the operator fallback forward verbatim — that entry has **no source file by design** (see the stated exception under **Needs**), so the model it last wrote is the only surviving record of it. That read grants no authoring: it does not author the source files and does not edit a traveler's desires.
2. **Writer of trip-context `[ENRICH]` rollups (unchanged).** Its existing `[ENRICH]`-only contract on `trip-context.md` is untouched — weather, baseline, events, transit access, and the other `[ENRICH]` fields still behave exactly as before.

The derived traveler model is the **feed**: the engines and the hub read `outputs/traveler-model.md`, and it is the input from which the event-status and metrics homes are populated. Engines and hub do **not** parse the raw per-traveler files.

---

## Field Scope — person-scoped, trip-scoped

*Who Writes What* above answers **who authors a field**. This section answers a different question about the same fields: **how long an answer lives, and which trip it belongs to.** A traveler filling in the intake form today answers some questions once — an allergy, a passport's issuing country, a standing preference for slow mornings — and answers others afresh for every trip: this trip's dates, this trip's group, this trip's occasion. Re-asking the durable ones on every trip is the intake barrier that a person-scoped store exists to remove.

**This axis is orthogonal to publishability.** `reference/data-architecture.md` § *5.2 Field classification* partitions fields into `publishable` / `non-publishable` — what may leave the machine. This partitions them by **scope** — how far an answer travels. A field carries exactly one class on each axis independently, and neither implies the other.

Every field carries exactly one of four classes:

| Class | Meaning |
|---|---|
| **`PERSON`** | Durable, and **not overridable per trip**. Silent per-trip divergence would be a safety or integrity defect. |
| **`DEFAULT`** | Durable, and **overridable per trip**. The durable answer is the starting point; a trip may legitimately diverge. |
| **`TRIP`** | Scoped to one trip. Its subject is this trip's dates, group, bookings or occasion. |
| **`DEST`** | Scoped to one destination. Unchanged by which trip goes there. |

> **"Person-scoped" means `PERSON` ∪ `DEFAULT` — both are sourced from the durable record and neither is re-asked.** The two differ only in whether a trip may carry a divergent value. Reading "person-scoped" as class `PERSON` alone is a narrower claim than this partition makes and undercounts the durable set sevenfold.

### The denominator — what counts as a field

A **field** is a distinct `(section, label)` pair rendered as a body bullet of the form `- [⭐ ]**<Label>:**` **above** the `<!-- PROFILE-END -->` sentinel of **either** intake form — `templates/traveler-intake.template.md` (the trip form) or `templates/person-intake.template.md` (the durable person form). **Both, because the intake is split and either form alone is half the question set.** The two emit **disjoint** label sets, so their union is a plain sum with nothing double-counted. Repeated blocks (`Needs` ×3, `Desires` ×3) are **one** field each — the form's own instruction is *"add as many as you like and delete the rest"*, so block count is user data, not schema. **A label inside such a repeated block is `block`-scoped; every other label is `slot`-scoped.** That is the `Scope` column below and the axis `K3`/`K4` and `MALFORMED-SLOT` branch on — stated here as a rule rather than left to be inferred from this paragraph two sections later.

| Population | Disposition |
|---|---|
| Raw field bullets in the body | Includes repeated blocks — **not** the denominator |
| **Distinct labelled fields** | **The denominator.** Every one classified below |
| Unlabelled free-text tail (`## Anything else`) | An answerable slot with no label. **Classified** below, so no slot is silently unscoped |
| Frontmatter keys | **Out of scope, deliberately.** The template: *"The fence above is **not a field you fill in** … Its values are facts about the artifact class, not answers to a question."* |
| The `# Your Travel Profile — [Name]` H1 | The `Name` field's **only** rendering — post-split it is the title line of the person form and a bullet in neither form. Classified below, and outside the bullet-derived count |
| `Applies to` — never asked, computed | Removed from the trip form's body as a pointless blank for a computed value. Still a field and still classified below, so the slot is not silently unscoped, and likewise outside the bullet-derived count |

**The denominator is stated as a rule, not as a number.** A literal count in prose goes stale the first time a form gains or drops a line; the rule above does not — **provided it names every form that renders a field**, which is the failure mode the split demonstrated rather than a hypothetical one. Applied to the two shipped forms the rule measures **36 distinct labelled bullets — 19 on the trip form, 17 on the person form, disjoint.** The classification table below carries **39 rows**, and the difference is exactly the two labels that are fields but not bullets: **`Name`**, borne by the H1 title line, and **`Applies to`**, never asked because it is computed. **36 bullets + `Name` + `Applies to` = 38 labelled fields, + 1 unlabelled free-text slot = 39 answerable slots.** Every number here is reproducible from the two forms and the table rather than asserted, and the reconciliation is written out so that a future form change **moves a countable that can be re-derived** instead of silently invalidating one that cannot.

### The classification — every answerable slot, exactly one class

`Ovr?` = may a trip carry a divergent value? `N` = no (a schema violation). `Y` = yes, and the divergence is reported. `n/a` = there is no durable value beneath it to override.

`Scope` = how many times the label may legitimately occur in one file. **`slot`** = at most once, so a second occurrence is `MALFORMED-SLOT`. **`block`** = the label belongs to a repeated block (`Needs`, `Desires`), so repetition is **user data, not a defect** — the same reading the denominator rule above already applies when it counts a repeated block as one field. **Scope is a property of the field, total over all 39 rows, and it is the axis `K3`/`K4` and `MALFORMED-SLOT` branch on.**

| # | Field | Section | Class | Ovr? | Scope | Rationale |
|---|---|---|---|---|---|---|
| 1 | `Name` | About you | **DEFAULT** | Y | `slot` | **Borne by the person form's H1 title line, not by a bullet — and therefore starred in neither form** (see *The starred pass* below). The person record holds the canonical name; **`trip-context.md` § Group is the per-trip display-name authority** (see *The display name has one authority* below). A trip legitimately renders "Mom" where the record says "Pat" — that is DEFAULT semantics, not a defect |
| 2 | `Relationship` | About you | **TRIP** | n/a | `slot` | *"how you fit in **the group**"* — stated relative to this trip's group; a different group reframes it |
| 3 | `Party` | About you | **TRIP** | n/a | `slot` | Who is travelling **on this trip** without their own form. `reference/adr/ADR-006-third-party-data-capture.md` bounds their data to needs-only; that boundary is preserved, not widened |
| 4 | `Would love` | Destination leanings | **DEFAULT** | Y | `slot` | A standing wishlist worth carrying; a trip may override for its own shortlist |
| 5 | `Rather skip` | Destination leanings | **DEFAULT** | Y | `slot` | As above, the negative half of the same lean |
| 6 | ⭐ `Trip vibe` | Destination leanings | **TRIP** | n/a | `slot` | *"The kind of trip **you're after**"* — beach this time, city next |
| 7 | ⭐ `Can travel` | Dates & availability | **TRIP** | n/a | `slot` | Windows for this trip |
| 8 | `Blackout` | Dates & availability | **TRIP** | n/a | `slot` | Dated to this trip's window |
| 9 | `Trip length` | Dates & availability | **TRIP** | n/a | `slot` | *"How long feels right"* **for this trip**; the facet links to trip Logistics once dates are set |
| 10 | ⭐ `Leaving from` | Getting there & back | **DEFAULT** | Y | `slot` | A home airport is durable and **does** change (you move; you are already abroad). The trip level owns origins — travelers attach to an origin by roster name |
| 11 | `Arrive / leave` | Getting there & back | **TRIP** | n/a | `slot` | This trip's arrival and departure, relative to this trip's group booking |
| 12 | `Journey comfort` | Getting there & back | **DEFAULT** | Y | `slot` | A standing transit tolerance. A trip that books a red-eye is a **worse** trip, not a broken one. A medical transit limit is authored as a **Need**, which is `PERSON` |
| 13 | `Passport` | Getting there & back | **PERSON** | **N** | `slot` | Issuing country and validity. **Silent per-trip divergence checks entry requirements against the wrong nationality** — an integrity defect. Decay is handled by the record's own validity horizon, never by a per-trip override |
| 14 | ⭐ `Lodging style` | Where you stay | **DEFAULT** | Y | `slot` | A durable lean ("rental with a kitchen") that a trip may override. A step-free requirement is a **Need** |
| 15 | `Rooming` | Where you stay | **TRIP** | n/a | `slot` | *"happy to share with Sam"* — names this trip's group |
| 16 | ⭐ `Comfort range` | Budget appetite | **DEFAULT** | Y | `slot` | A durable spend lean; a trip may legitimately run leaner or richer |
| 17 | `Splurge appetite` | Budget appetite | **DEFAULT** | Y | `slot` | As above |
| 18 | `Category` | Needs | **PERSON** | **N** | `block` | Types the need and routes its constraint link. Silent divergence mis-routes a non-negotiable to the wrong trip constraint |
| 19 | ⭐ `Specific` | Needs | **PERSON** | **N** | `block` | The allergy, the heat ceiling, the mobility limit. **The canonical `PERSON` field** |
| 20 | `Applies to` | Needs | **TRIP** | n/a | `block` | **Never asked — computed.** The need→constraint edge, recomputed per trip by enrichment. See *The `Needs` split* below |
| 21 | ⭐ `Desire` | Desires | **TRIP** | n/a | `block` | Anchored to this destination and occasion (*"explore the local markets"*). Its source of truth is the trip's own traveler file; a later trip-history capability may pre-fill it, and the trip file stays authoritative |
| 22 | `Priority tier` | Desires | **TRIP** | n/a | `block` | Ranks a TRIP-class desire; cannot outlive its subject |
| 23 | `Recurrence` | Desires | **TRIP** | n/a | `block` | As above |
| 24 | `Theme tag(s)` | Desires | **TRIP** | n/a | `block` | As above |
| 25 | `Overlap` | Desires | **TRIP** | n/a | `block` | **Never asked — computed.** Who else on **this trip** shares it. Symmetric with `Applies to` |
| 26 | ⭐ `Pace` | Travel style & pace | **DEFAULT** | Y | `slot` | A durable lean that a trip may override (a packed city break, then a slow beach week) |
| 27 | `Day rhythm` | Travel style & pace | **DEFAULT** | Y | `slot` | Whether they are a morning person — durable, and jet lag makes it legitimately overridable |
| 28 | `Novelty vs comfort` | Travel style & pace | **DEFAULT** | Y | `slot` | Durable lean, trip-adjustable |
| 29 | `Planning style` | Travel style & pace | **DEFAULT** | Y | `slot` | Durable lean, trip-adjustable |
| 30 | ⭐ `Interests` | Interests & tastes | **DEFAULT** | Y | `slot` | Durable ("museums, food & markets") and **not** destination-scoped |
| 31 | `Cuisine appetite` | Interests & tastes | **DEFAULT** | Y | `slot` | *"How you eat **when you travel**"* — durable by its own wording. Not destination-scoped |
| 32 | `Been here before?` | Interests & tastes | **DEST** | n/a | `slot` | *"How well you already know **this destination**"* — closed enum; unanswered reads **unknown**, never `never` |
| 33 | `Already done` | Interests & tastes | **DEST** | n/a | `slot` | *"Anything you've already seen or eaten **here**"*. A later trip-history capability would *supplement* these two, never replace them |
| 34 | `Group time` | People dynamics | **TRIP** | n/a | `slot` | How much of **this trip** as a group — the answer depends on who this group is |
| 35 | `Split off with` | People dynamics | **TRIP** | n/a | `slot` | Names this trip's group members |
| 36 | `Solo, I'd` | People dynamics | **DEFAULT** | Y | `slot` | A personal want with no group referent (*"find a quiet café and read"*) — the one field in this section that survives a change of group |
| 37 | `Whole-group moments` | People dynamics | **TRIP** | n/a | `slot` | *"every dinner", "the day trip", "the first night"* — references this trip's itinerary shape |
| 38 | `Special occasion?` | Anything else | **TRIP** | n/a | `slot` | *"Is **the trip** marking anything"* — the subject is the trip |
| 39 | *(unlabelled free-text tail)* | Anything else | **TRIP** | n/a | `slot` | Unstructured and unparseable. **Fail-safe disposition:** a durable store must not silently carry forward free text that may be trip-specific, and it is the highest-risk copy for privacy. Explicit, not an omission |

**Totals — `PERSON` 3 · `DEFAULT` 15 · `TRIP` 18 · `DEST` 2 across the labelled fields**, plus the free-text slot as `TRIP`. **Scope totals — `slot` 31 · `block` 8**, the eight being the three `Needs` and five `Desires` labels. Every slot carries exactly one class **and exactly one scope**; none carries two of either, and none is unclassified. **Sum the class column and assert equality with the row count the denominator rule above reconciles — never with a literal restated here.**

> **`Passport` acquires a third artifact scope, and the publish guard must follow it.** `Passport` is `PERSON`, so it lives in the durable person record as well as in a trip's traveler file. Per `reference/data-architecture.md` § 5.2 the non-publishable fence *does not inherit* — it is one row per field **per artifact scope** — so the person-record scope needs its **own** non-publishable row. A missing row there is fail-open on a passport.

### The decision rule for mixed cases — four ordered tests, first match wins

Deterministic and re-runnable: apply the tests in order and stop at the first match.

- **T1 — Whose statement is it?** If the value's *subject* is this trip (its dates, its group, its bookings, its occasion) → **TRIP**. If the subject is this destination, and the answer would be unchanged by which trip goes there → **DEST**.
- **T2 — Is it answered, or computed?** A field the traveler is never asked is an **edge into this trip's graph**, recomputed per trip. Two fields qualify, and post-split the forms say so in two different ways. `Overlap` is still rendered and still unasked — the trip form's guide states *"**One field is never asked about.** Leave **Overlap** blank. The planner works it out."* — while `Applies to` is no longer rendered at all: the split removed its blank slot as pointless for a computed value, which is the same verdict carried one step further. Both are **TRIP by construction** and neither can be DEFAULT: there is no durable value to override.
- **T3 — Would silent divergence be a *defect* or a *choice*?** This is the `PERSON`/`DEFAULT` discriminator, and it is a **safety** test:
  - **PERSON** — silent per-trip divergence is a safety or integrity defect. The plan could violate a real boundary or misidentify a legal document.
  - **DEFAULT** — divergence is a legitimate planning choice; being wrong costs a worse trip, not a broken one.

  This is not an invented threshold. It is the line the template already draws in its own preamble: *"A plan that breaks a need is broken … A missed desire is a worse trip, not a broken one."*
- **T4 — Fail-safe default.** A slot that reaches T4 unresolved is **TRIP**. A wrong TRIP classification costs one re-asked question; a wrong PERSON/DEFAULT classification silently carries a person's data into a trip they did not intend it for. **The cheap error is the safe one.**

**T3 loses no expressiveness.** Every preference has a safety-shaped twin already available: the `Needs` block. `Journey comfort: "no red-eyes"` is DEFAULT; a medical transit limit is authored as a Need and is PERSON. **The classification does not decide how severe a fact is — the author does, by choosing which section to write it in.** That is why T3 can be strict without forcing anyone to under-state a real constraint.

### Composition and resolution — which source is authoritative

| Class | Authoritative source | Must **not** carry it | Both carry it → | Unresolvable → |
|---|---|---|---|---|
| **PERSON** | the person record | the trip's `travelers/<traveler>.md` | **REFUSE and REPORT.** A trip-side `PERSON` value is a **schema violation, not an override**. Resolution reads the record; the validator raises the divergence and never silently prefers one — silent precedence is exactly how the class collapses into `DEFAULT` | `UNKNOWN`, never an empty set |
| **DEFAULT** | the person record **unless** the trip file carries the field, in which case **the trip file wins for that trip** | — (both may legitimately carry it) | **Trip wins, and the divergence is reported.** A trip value **equal** to the record's is a *redundant* override → reported `REDUNDANT-OVERRIDE` and **left in place**. Nothing removes it: composition reports and does not normalise, and the trip-side line goes only when a human takes it out (§ *The override lifecycle*) | `UNKNOWN`, never an empty set |
| **TRIP** | the trip's `travelers/<traveler>.md`; for the constraint half, `trip-context.md` § Hard Constraints / § Dietary & Health | the person record | **REFUSE and REPORT.** A `TRIP` field in the person record is a schema violation | `UNKNOWN`, never an empty set |
| **DEST** | the trip's `travelers/<traveler>.md` | the person record — a later trip-history capability may supply a *suggestion*, never an authority | **Trip wins.** Direct entry stays available and stays authoritative for the trip | `UNKNOWN`, never an empty set |

**The rule that makes DEFAULT cheap: a trip carries a `DEFAULT` field only when it diverges.** Absence on the trip side means *use the durable value* — which **is** `link, don't copy` applied across the trip boundary. So 15 `DEFAULT` fields do **not** mean 15 copied values per trip; they mean 15 optional divergence lines, empty in the common case. This keeps the redundant-override surface proportional to actual divergence rather than to the class size, and it bounds the override-copy sweep an erasure pass must perform to the fields that actually diverged.

> **"Carries the field" is answered-ness, not line-presence** — the shipped form never omits a line, so a line-presence reading makes every skipped field look like a divergence. The predicate, the rules that consume it, and what each row of the table above means mechanically are in § *Composition — the trip-side read of a durable record* below. **This table assigns the authoritative source per class; that section is the mechanism, and neither restates the other.**

### `PERSON` is not overridable — and it is enforced by absence

*If a `PERSON` field were overridable, the class would be `DEFAULT` and durability would mean nothing.* That is right, and it is a **tautology, not a mechanism** — a tautology cannot stop anyone from adding an override slot later.

**The mechanism is structural: once the intake form is split, the trip form does not carry `PERSON` fields.** There is no slot to fill, so there is nothing to police. The class cannot collapse via a per-trip need override, because the override has nowhere to live. Two checkable consequences:

1. The trip form emits **zero** `PERSON`-class field bullets.
2. The person form emits **zero** `TRIP`- and `DEST`-class field bullets — the converse assertion, and the one `reference/schemas/person-record.md` actually ships: *"What is owed is the negative assertion, not a rule: the durable form emits zero `TRIP`/`DEST` labels."*

**The grading is done by the forms, not by the schema fences.** Neither schema carries body-shape rules for these labels and neither is meant to: both fences are **frontmatter-only**, deliberately, because — as the person-record schema states — *"a `field Passport:` line here would declare a passport a machine-readable frontmatter key, which is both wrong by the boundary test and a worse privacy shape."* The partition is therefore **measurable as two counted zeros over the two shipped forms** — no `PERSON` label on the trip form, no `TRIP` or `DEST` label on the person form — which is a stronger *property* than a fence rule would give, because it holds over the artifact a human actually fills in. **No suite computes it today** — the two zeros are measurable, and were measured, but nothing re-measures them on change. That gap is named here rather than closed. A **schema-bearing** home for the person record remains load-bearing for the record's *shape*; it is simply not what enforces this partition.

### A need that applies to one trip only

A need that applies to one trip only is a **trip-level hard constraint** in `trip-context.md` `## Hard Constraints`, whose `Applies to:` line names the traveler. It is **never** a per-trip override of a `PERSON` field, and it needs no new mechanism.

The authoring path already works end-to-end. The traveler writes the trip-only need in that trip's `travelers/<traveler>.md` `Needs` block, which is trip-scoped by construction. Enrichment links it; where no governing constraint exists, the template already states *"an agent flags it so it can be added."* It stays trip-local unless **explicitly promoted** to the durable record, and promotion is explicit and confirmed, never inferred — so a trip-only need never reaches the durable store by accident.

> **The two `Applies to` fields are inverse edges sharing a label. Do not conflate them.**
>
> | Where | Direction | Value shape |
> |---|---|---|
> | `travelers/<traveler>.md` § Needs | need **→** constraint | `Hard Constraints → "Afternoon heat ceiling"` |
> | `trip-context.md` § Hard Constraints | constraint **→** people | `Pat (primary), entire group (general)` |

### The `Needs` split — the durable half and the link half

The need is durable; its link to a trip is not. The split falls on `Applies to`:

- `Category` + `Specific` are **PERSON** — the durable half.
- `Applies to` is **TRIP** — the link half, and per the template it is **never authored at all**.

The § *Reconciliation Rule* above already assigns that link to the enrichment agent: *"The **link** between a traveler's need and the trip-level constraint … Established by the enrichment agent … **never by copying the constraint text**."* So a durable tree-nut allergy carried to a different trip binds to *that* trip's constraint through the existing reconciler. **Nothing new is required beyond writing the split down.**

### The starred pass — what a returning traveler is re-asked

The forms star the highest-value fields, at most one per section — **9 stars, 6 on the person form and 3 on the trip form.** Under this partition the starred set splits **6 library-sourced / 3 re-asked**, the measure of the intake barrier this classification removes: a returning traveller's starred pass is **9 → 3**.

| Re-asked each trip (**3**) | Library-sourced (**6**) |
|---|---|
| ⭐ `Trip vibe` (TRIP) · ⭐ `Can travel` (TRIP) · ⭐ `Desire` (TRIP) | ⭐ `Leaving from` (DEFAULT) · ⭐ `Lodging style` (DEFAULT) · ⭐ `Comfort range` (DEFAULT) · ⭐ `Specific` (PERSON) · ⭐ `Pace` (DEFAULT) · ⭐ `Interests` (DEFAULT) |

> **`Name` appears in neither column, and the split is why.** It was starred while the intake was one form; the person form now carries the name as its **H1 title line** rather than as a bullet, so it is starred nowhere and the star total is 9 rather than 10. It remains `DEFAULT` and remains library-sourced — a returning traveller is **not** re-asked it — but it is not part of the *starred* pass, which is what makes that pass 9 → 3 rather than 10 → 3. **`scripts/test-artifact-schema.sh` group `ST` gates the per-form star counts and reads 6 and 3**; this section now agrees with the gate rather than contradicting it.

**The split is graded on `PERSON` ∪ `DEFAULT`, not on class `PERSON`.** Under the narrow reading only one starred field (`Specific`) is `PERSON`, and the intake-barrier claim reads as failed against a correct classification.

---

## Composition — the trip-side read of a durable record

*Field Scope* above assigns each field a class and names, per class, **which source is authoritative**. This section is the **mechanism** that assignment describes: given a traveller file and the durable person record it may reference, what value does the trip plan on, and what is reported. It extends § *Reconciliation Rule — One Source Per Fact* across the trip boundary — *link, don't copy* applied to a fact whose owner lives outside this trip — and it restates neither that rule nor the class assignment above.

`reference/adr/ADR-012-people-library.md` is authoritative for the decisions; `reference/schemas/person-record.md` for the record's shape; `reference/schemas/traveler-profile.md` for the reference field. **This section owns the composition rules and nothing else.**

> **The whole of it in one sentence: composition is decided by field class first, answered-ness second, and the class of a trip that carries no reference at all is the identity case — a traveller file with no `person:` field composes to itself, byte for byte, with no store read attempted.**

### `ANSWERED()` — the presence predicate the lattice rests on

> **`ANSWERED(v)` is false when the slot is ABSENT, BLANK, exactly `—`, or a surviving `[bracketed placeholder]`. It is true otherwise. Those four falses are one equivalence class: UNSTATED.**

Every member is the engine's own shipped equivalence rather than a new one:

| Member | Where the engine already says so |
|---|---|
| absent · blank · em-dashed | `agents/00-enrichment.md`: *"an absent, blank or em-dashed line is `one-off`"*; *"A blank or em-dashed field … is `unknown`, never `never`"* |
| a leftover `[bracketed placeholder]` | `templates/traveler-intake.template.md`: *"a leftover `[bracketed placeholder]` reads as unanswered, exactly like an empty line"* |

**The predicate is answered-ness, never line-presence, and the difference is the majority case rather than an edge.** The intake form **never omits a line** — *"keep the line and put a single em dash where the answer would go"*, and *"skipping a section never removes it from the output."* A line-presence test therefore reads every skipped field as an answer, which is the wrong verdict for most of the form: measured over the two shipped traveller fixtures, **26 of 30 `DEFAULT` bullets carry a line and no answer**, and only 4 carry a value.

**`none` is ANSWERED, uniformly.** The form makes it a deliberate answer — *"this is the one place `none` is used instead of the em dash: everywhere else an em dash means 'no answer', but for needs the difference between 'I have none' and 'not asked yet' is load-bearing."* Its *"I have none"* reading is a `Needs`-scoped semantic downstream of this predicate, never a presence question, which is what keeps `ANSWERED()` section-independent and therefore total.

> **Do NOT reuse `scripts/publish-trip-site.sh`'s `stated()` as this predicate.** `stated()` returns 0 for `na`, `nil`, **`none`**, `tbd`, `unknown`, `unspecified` and `notstated`. It is correct for its own job — deciding whether a value is a *publishable string* — and wrong for this one. The reuse is the obvious move: it type-checks, it passes every existing test, and it silently converts *"I have no needs"* into *"not asked yet"*, inverting the one distinction the form calls load-bearing. **Two predicates, two purposes, one shared vocabulary; they legitimately disagree on seven tokens.** Assert both in one test, or the divergence is asserted nowhere.

**`ANSWERED()` is an instance property; presence is a document property. They share the word *present* and answer different questions.** *What the form asks* — the labelled-field denominator above, its four-class partition and the starred-pass split — is keyed on the **presence of a bullet in the template**, correctly and unchangedly, because a form asks a question by carrying its line. *Whether this traveller supplied a value* is keyed on `ANSWERED()`. **Composition lives wholly on the instance side.** Applying the instance predicate to the document question scores the blank intake form at zero answers, which would read as a form that asks no questions — so the over-application is measurable rather than hypothetical.

**The record side is three-valued, because a horizon is a third state:** `UNSTATED` · `ANSWERED` · `EXPIRED` (a `[VALID-THROUGH YYYY-MM]` mark whose horizon is earlier than `strftime('%Y-%m')`).

> **Conflict detection keys on *statedness*; composition keys on *usability*.** An `EXPIRED` value is **stated** — so it is a real second owner and contests a trip-side value — and **not usable**, so it composes to `UNKNOWN` and is reported. It is never silently used, because a plan would then check entry requirements against a lapsed document, and never silently dropped, because a vanished constraint reads as compliance.

### The bearer states — seven, and five need no store read

The reference is borne by the traveller file alone. **Five of the seven states are dispositions of that file and are decided with no store read at all**; only two touch the store.

| # | Bearer state | Observed | Store read? | Availability `A` | Defect? |
|---|---|---|---|---|---|
| **L1** | `NOT-REFERENCING` | no `person:` key, and no tombstone evidence | **none** | `ABSENT-BY-DESIGN` | no — **the default path** |
| **L2** | `TOMBSTONED` | no `person:` key **and** a derived-model entry keyed `per-[0-9a-f]{4}` carrying `[ERASED]` | **none** | `ABSENT-BY-DESIGN` | no — declared and intentional |
| **L3** | `RESOLVED` | `person:` names a live record | yes, succeeds | `AVAILABLE` | no |
| **L4** | `REDIRECTED` | `person:` names a `merged-into:` stub, followed one hop | yes, succeeds | `AVAILABLE` | no |
| **L5** | `DANGLING` | a well-formed `person:` resolving to nothing | attempted, fails | `UNRESOLVED` | **yes** |
| **L6** | `MALFORMED` | the value is not `psn-<token>`, or the key is duplicated, or a second `merged-into:` hop | not attempted | `UNRESOLVED` | **yes** |
| **L7** | `STORE-UNREADABLE` | the store is absent or unlistable **and** a `person:` key is present | attempted, fails | `UNRESOLVED` | maybe |

**L7 must not degrade L1.** An unreadable store leaves a trip carrying **no** reference entirely unaffected — no read is attempted, so there is nothing to fail. Without that clause the first unreadable store would break every trip in the working directory rather than the ones that reference a record.

**Store-root resolution: `<trip-root>/people/` when that directory exists, otherwise `<repo-root>/people/`. Two steps, deterministic, terminating; no upward search.** The rule is forced by the store's own ignore boundary rather than chosen on style. `.gitignore` carries `/people/*` **rooted**, so the repo-root store does not exist in a fresh checkout: a fixture that fell through to it would resolve `RESOLVED` on an author's machine, where an operator store exists, and `DANGLING` in CI — **a witness whose verdict depends on the operator's private working directory is not a witness**, and a CI run would read operator data if any happened to be present. An upward search is rejected for a second reason: it is non-deterministic when both roots exist, which reintroduces exactly the order-dependence the next-but-one subsection forbids.

**The eighth case has no bearer at all.** A derived-model entry with **no source file and no reference** is `EXCLUDED-BY-DESIGN` — neither file-less class receives a record or a bearer — decided with no store read, and it **must never be reported as `DANGLING`**: there is no reference to dangle. It is a row of the *entry* disposition table, not a cell of the lattice, and that placement is the point.

### The lattice — class first, then answered-ness

**Arguments**, five, each typed and each single-valued:

- `C` — the field's class, from the classification table above.
- `p` — the trip-side value if `ANSWERED`, else `⊥`.
- `A` — availability ∈ {`AVAILABLE`, `ABSENT-BY-DESIGN`, `UNRESOLVED`}, the three-valued projection of the bearer state.
- `r` — the record-side value if `A = AVAILABLE` **and** the record's slot is `ANSWERED`, else `⊥`.
- `s` — the field's **scope** ∈ {`slot`, `block`}, read from the `Scope` column of the classification table above. It is a property of the field, not of the instance, and is single-valued for every field by construction. `K3`/`K4` and `MALFORMED-SLOT` are the only consumers.

**Six rules. Branch on `C` first; consult answered-ness only where the class admits divergence.**

| # | Guard | Composed value `V(f)` | Winning source |
|---|---|---|---|
| **K1** | `C ∈ {TRIP, DEST}` | `p` if `p ≠ ⊥`, else `UNKNOWN` | **the trip, always.** The record is not their authoritative source; `A` and `r` are never read |
| **K2** | `C = PERSON` ∧ `A ≠ AVAILABLE` | `p` if `p ≠ ⊥`, else `UNKNOWN` | **the trip, as sole source.** There is no second owner, and the trip's own value is **retained** — under `UNRESOLVED` because the record side is undetermined rather than empty. **This rule states no report.** A value rule decides a value; the report keys on the un-collapsed bearer state and never on `A` — see § *The discriminator that must not collapse* |
| **K3** | `C = PERSON` ∧ `A = AVAILABLE` ∧ the field is **slot-scoped** | `r` if `r ≠ ⊥`, else `UNKNOWN` | **the record, unconditionally.** A trip-side value is never composed; where `p ≠ ⊥` it is additionally reported `CLASS-VIOLATION` |
| **K4** | `C = PERSON` ∧ `A = AVAILABLE` ∧ the field is **block-scoped** | the **union** — see the overlay below | **both, without either overriding.** Every trip-side block is reported `CLASS-VIOLATION` |
| **K5** | `C = DEFAULT` ∧ `p ≠ ⊥` | `p` | **the trip.** The one sanctioned override; reported `DIVERGENT` or `REDUNDANT-OVERRIDE` |
| **K6** | `C = DEFAULT` ∧ `p = ⊥` | `r` if `r ≠ ⊥`, else `UNKNOWN` | **the record**, or nothing |

> **A trip-side `PERSON` value is a schema violation, not an override — REFUSE and REPORT.** Silent precedence in either direction is exactly how the class collapses into `DEFAULT`. **Answered-ness does not rescue this class**, and the reason is measured rather than argued: on the two shipped traveller fixtures the `PERSON`-class bullets are present *and answered* on the trip side **today** — **10 bullets, 8 of them answered**. Both are legacy files authored against the unsplit form, and § 7.6 guarantees such files are never upgraded, so **this population does not shrink when the form splits** — which is precisely why the rule cannot be founded on the split having happened. It has: the shipped trip form emits zero `PERSON`-class bullets, and these fixtures still carry ten. Under a presence predicate *or* a naive answered-ness predicate those bullets read as overrides and the safety class goes silent on a person edit. **`DEFAULT` is the one class the answered-ness predicate actually changes.**

**Answered-ness still does work inside `PERSON`, and it is a different job.** It decides whether there is a **claim to report** (K3's `CLASS-VIOLATION` fires only where `p ≠ ⊥`), never which source **wins** (K3 returns `r` either way). Reading `Passport: —` on a referencing trip is not a violation of anything: an em dash is a skipped field, and skipping is what the form instructs.

**Why `K3` discards an answered trip-side value where `K2` retains one.** The two rules look asymmetric and are not: they differ on whether the authoritative source was **consulted**. Under `K3` the reference resolved and the record's slot is `UNSTATED` — the authority has been read and holds no value, so `UNKNOWN` *is* that authority's answer, and composing `p` instead would let answered-ness select a source inside `PERSON`, which is the one thing this class forbids. Under `K2` with `A = UNRESOLVED` the record side is **undetermined rather than empty** — nothing was read at all — so discarding the trip's value would let a mistyped `person:` key silently delete a real constraint. The discriminator is *consulted-and-silent* versus *never consulted*, not *answered* versus *unanswered*. **This is also the limit of *"linking a person is never a destructive act"***: that property belongs to the `Needs` union under `K4`, where two needs are two instances and nothing is displaced. On a **slot**-scoped field the record is the sole owner of one fact, so `K3` composes `UNKNOWN` and marks it `[CONTESTED]` — the trip-side claim is preserved *in the report*, which is where a claim the class refuses belongs.

**Totality — by construction and by count.** The cell space is `5 class-and-scope kinds × 2 trip-side states × 11 library configurations` = **110**. The five kinds are `TRIP`, `DEST`, `DEFAULT`, `PERSON` **slot**-scoped and `PERSON` **block**-scoped — **field scope is a declared axis, not a free variable** — and it refines `PERSON` alone because `K3`/`K4` are the only guards that read `s`; the other three kinds are scope-uniform, their rules covering both scope values, so each is one kind rather than two. The 11 library configurations = the 5 bearer states carrying no record side (L1, L2, L5, L6, L7) + the 2 that do (L3, L4) × the 3 record-side states. `K1` covers `2 × 2 × 11 = 44`; `K2` covers `2 × 2 × 5 = 20`; `K3` and `K4` cover `1 × 2 × 6 = 12` each; `K5` and `K6` cover `1 × 1 × 11 = 11` each. **44 + 20 + 12 + 12 + 11 + 11 = 110.** The guards are mutually exclusive — `K1` takes two kinds whole, `K2` takes **both** `PERSON` kinds wherever `A ≠ AVAILABLE`, `K3`/`K4` split the two `PERSON` kinds wherever `A = AVAILABLE`, and `K5`/`K6` partition `DEFAULT` on `p` — and jointly exhaustive, because every slot carries exactly one class **and** exactly one scope. **No cell is unreached and no cell is reached twice.**

> **Every term above is counted at the same granularity, and that is the load-bearing property of the proof.** Counting `K2` over an unrefined `PERSON` while writing `K3 ∪ K4` as a single term collapses — for the length of that one term — precisely the distinction the two rules exist to draw, and the sum then re-adds correctly against a space smaller than the one the rules actually range over. **An arithmetic check passes and the proof does not.** A totality claim whose terms are taken at two granularities establishes nothing about either, which is why scope is carried as an axis here rather than mentioned as a property in the prose of one rule.

**Unresolvable is always the literal `UNKNOWN`, never an empty set**, and the token is sanctioned rather than merely chosen: the publish guard's `stated()` excludes `unknown` **by name**, so a guarded field composed to `UNKNOWN` is already outside the publishable value set. Any other sentinel would enter that set as a real string and abort publishes wherever it appeared in rendered output.

### Determinism — three obligations, and the third is where a design goes quietly order-dependent

- **O1 — no rule names a sequence.** No guard above refers to a first source, a last writer, file order or mtime. `V` is a pure function of five typed arguments. **This is checkable by reading the table: a rule mentioning a traversal is a defect.**
- **O2 — the arguments are computed independently.** `p` comes from the trip file's parse and `r` from the record's; neither parse consults the other's outcome. `A` depends on the trip file's frontmatter and then the store, in that order, and is single-valued.
- **O3 — every argument is single-valued.** A **slot-scoped label appearing twice in one file makes `p` a set**, so *"the trip value"* is undefined and any implementation resolves it by position. **Typed `MALFORMED-SLOT` → `UNKNOWN`, and reported. Never first-wins, never last-wins**, both of which are order-dependent by definition. This is a forward guarantee rather than a repair: there are **no** slot-scoped duplicates in the shipped form-shaped files today, and C3 is never upgraded, so a hand-introduced one would persist indefinitely.

### The `Needs` overlay — union, because two needs never contradict

`Passport` is **slot-scoped** and single-valued: a divergence is a genuine conflict over one fact, and *which nationality do entry requirements check against?* has one answer. `Category` and `Specific` are **block-scoped**: a record need and a trip need are two **instances**, not two claimants on one slot.

> **`V(Needs) = record blocks ∪ trip blocks`, deduplicated on `(Category, trim(Specific))`. Every trip-side block is reported `CLASS-VIOLATION`. There is no contested branch for needs — a union cannot contradict itself.** `none` is absorbing-identity: dropped from a union containing any real need, and a union that is exactly `{none}` composes to *declares no needs*.

**Union rather than record-wins, and record-wins is the unsafe branch.** A legacy trip whose traveller file carries a tree-nut allergy, then given a reference by hand or by a partial migration, would have that allergy **deleted from the composed source** under record-wins — and the plan would then grade compliant. That is the failure this whole mechanism exists to prevent, arriving through its front door. **Union is the only branch under which linking a person is never a destructive act**, and it is what makes a later reconcile-on-link pass a remedy rather than a precondition. The record still governs unconditionally in the sense that matters: every record need is in the composed set, no record need is ever displaced, and a record edit always reaches the trip.

**Under `K2` with `A = UNRESOLVED` the trip's own blocks are likewise retained.** A dangling reference means the record side is *undetermined*, never *absent*: composing the empty set there would read a typo as **no constraints**, which is precisely the reading the reference states are typed to forbid.

### Class enforcement — the report predicate, and why it does not break the tolerant read

> **A `CLASS-VIOLATION` is reported when a field is `PERSON`-class **and** `ANSWERED` in the trip file **and** the bearer carries a reference with `A = AVAILABLE`.** Three conjuncts.

Drop the third and the report fires on **every trip already on disk**: all three `PERSON` labels are present in both shipped traveller fixtures right now. **With no reference there is no second owner, so there is nothing to override, nothing to report, and no store read.** That is not a carve-out bolted onto the rule — it *is* the compatibility guarantee, stated as the rule's own scope.

**Enforcement lives in the value function, not in the report.** `K3` composes the record's value and `K4` composes a union; in neither does a trip-side `PERSON` value become the composed value by overriding a record. **So the override is structurally not silent whether or not anyone reads the report** — which is what makes this mechanism independent of an agent remembering to look. It is the second of two mechanisms covering different populations: § *`PERSON` is not overridable — and it is enforced by absence* above closes the new form by giving the override nowhere to live, and this closes every legacy file that § 7.6 guarantees will never be upgraded.

### The report — where it lands, and what it never says

**The report goes into the existing `## Update signals [DERIVED]` block of `outputs/traveler-model.md`.**

> **Do NOT add a `##` heading to that artifact.** Any `##` heading whose normalized key is not on the declared reserved list is **counted as a person** — a phantom entry, which is what keeps the `entries == 0` fail-closed sentinel from firing on a model that has drifted. The list holds exactly two members and lives in three coupled homes: § *Reserved keys* below, the guard constant in `scripts/publish-trip-site.sh`, and the heading itself. A `## Composition conflicts` heading would therefore inflate the entry count with a phantom person, require a three-home coupled edit, and change the model's shape for every consuming agent — none of which composition needs. **The model's heading set is unchanged by composition.**

One line per (traveller × field), in the block that already exists:

```
- <Traveller>: <Field label> — <DISPOSITION>; <remedy>.
```

| Disposition | Fires when | Defect? |
|---|---|---|
| `CLASS-VIOLATION` | a `PERSON` field is answered trip-side while the reference resolves | yes — remedy: move the value into the record |
| `DIVERGENT` | a `DEFAULT` override differs from the record's value | no — the sanctioned override, surfaced |
| `REDUNDANT-OVERRIDE` | a `DEFAULT` override equals the record's value | no — the line can be removed |
| `EXPIRED` | the record's value carries a lapsed `[VALID-THROUGH]` horizon | yes — remedy: refresh the record |
| `MALFORMED-SLOT` | a slot-scoped label occurs twice in one traveller file | yes |
| `DANGLING` · `MALFORMED` · `STORE-UNREADABLE` | the corresponding bearer state | yes / yes / maybe |
| `TOMBSTONED` | the bearer's record was erased | no — informational |

**Equality for `REDUNDANT-OVERRIDE` is trim-only and byte-exact:** two values are equal iff identical after stripping leading and trailing whitespace. No case folding, no punctuation normalisation, no similarity. The identity normalizer above is wrong by domain — it is built for keys, and folding prose with it would equate *"no red-eyes"* with *"no red eyes"*. The choice is settled by error asymmetry: a **narrower** equality under-reports redundancy, costing one un-normalised line that is still reported as `DIVERGENT` and still visible, while a **wider** one authorises deleting a line that was a real override, which is silent data loss in a human-authored Layer-1 file. **The cheap error is the safe one**, and trim-only is the only relation a reviewer can verify by eye — which matters for a rule whose output authorises a deletion. **`REDUNDANT-OVERRIDE` never fires against an `EXPIRED` record value**: equality with a lapsed value would authorise removing a live trip-side line in favour of one already known to be unusable.

> **The report NEVER restates the conflicting values.** Three independent grounds, any one dispositive. **(1) Publishability** — `Passport` is matched as a label prefix followed by a colon against both the traveller file and the derived model, so a report line written as `- **Passport:** …` would put a value into the non-publishable class under a heading nobody expected, while a value written in a shape the selector misses would escape it entirely. Naming the field without its value is safe under both readings. **(2) Erasure reach** — a quoted value is a **new copy of person data in a new location**, widening the set an erasure must reach by content rather than by address. **(3) Link, don't copy** — both values already have homes, and quoting them is the copy this whole design exists to eliminate.

**One new field-scoped mark, and only where `UNKNOWN` would be ambiguous.** A consumer reading `Passport: UNKNOWN` cannot tell *a claim was refused* from *nobody ever answered*, and the two have different remedies. Where `V` is `UNKNOWN` **and** a refused trip-side `PERSON` claim exists, the composed field carries a suffix mark:

```
- **Passport:** UNKNOWN [CONTESTED]
```

The mark is invisible to the publish guard by construction: `clean()` strips bracketed spans as metadata before matching, and `stated()` then excludes `unknown` by name. `[ENRICH]` is the shipped precedent for a field-scoped mark that is not a declared selector. **No mark is written where the composed value is the record's** — the value is unambiguous and correct there, and the report line carries the diagnosis. `EXPIRED` reuses the record schema's own `[VALID-THROUGH]` rather than minting a second token for one condition.

> **Corollary prohibition: `[CONTESTED]` must NEVER be added to the `publish-contract-values` fence in `reference/data-architecture.md` § 5.6.** An `entry` selector is matched as a literal substring of the entry heading **and** of each raw value line, so declaring it would make every value in a contested traveller's entry non-publishable and abort that trip's publishes permanently. It is a diagnostic mark, not a publishability class — the same trap `[ERASED]` carries, at a second address.

### The no-reference path is the identity case, not an exception

> **`L1 NOT-REFERENCING` is the identity of the lattice, and compatibility is discharged by showing that rather than by promising it.**

Substitute the **bearer state** `L1 NOT-REFERENCING` — which projects to `A = ABSENT-BY-DESIGN` and makes `r = ⊥` by construction — and every rule collapses into today's read. **The substitution is the bearer state, not the projection**, because `L2 TOMBSTONED` shares the projection and does not share the report:

| Rule | Under `L1 NOT-REFERENCING` | Against today |
|---|---|---|
| K1 | `p` if stated, else `UNKNOWN` | identical |
| K2 | `p` if stated, else `UNKNOWN`; **no report — because the bearer state is `L1`**, not because `A` is `ABSENT-BY-DESIGN`. `L2 TOMBSTONED` takes the same row and the same value, and reports `TOMBSTONED`, informational | identical — this is the branch every `PERSON` field of every existing trip takes |
| K3 · K4 | unreachable — both guards require `A = AVAILABLE` | n/a |
| K5 | `p` | identical |
| K6 | `UNKNOWN` | identical — an unanswered field already reads unknown |

**The composed source equals the traveller file, field for field.** No store read is attempted, no report line is emitted, no mark is written. **The path is not a branch an implementation must remember to take — it is what the lattice already computes when `r` is `⊥`.** That is the difference between a tolerant read and a compatibility shim, and it is why *no pre-existing trip requires migration* is a property of the rules rather than a test case.

Three consequences a check can grade: a trip with no `person:` field anywhere performs **zero** store reads; an absent or unreadable store changes nothing for such a trip; and the two shipped traveller fixtures compose to themselves unchanged, which is what makes them the witness for this path.

### The discriminator that must not collapse — a projection boundary

Three states share the observable *"the composed source has no library value"*, and flattening any two of them is undetectable by any test that only inspects composed values.

| State | Bearer observation | `A` | Report | Defect? |
|---|---|---|---|---|
| `NOT-REFERENCING` | no `person:` key, no tombstone evidence | `ABSENT-BY-DESIGN` | **none** | no |
| `TOMBSTONED` | no `person:` key **and** a model entry keyed `per-[0-9a-f]{4}` carrying `[ERASED]` | `ABSENT-BY-DESIGN` | `TOMBSTONED`, informational | no |
| `DANGLING` | a well-formed `person:` resolving to nothing | `UNRESOLVED` | `DANGLING`, verdict `UNDETERMINED` | **yes** |

> **The value function consumes the three-valued `A`. The report function consumes the un-collapsed seven-state bearer verdict. `A` is a projection *for the value function only* and must never be the report function's input.**

`NOT-REFERENCING` and `TOMBSTONED` agree on `A` **deliberately**, because their composed values genuinely are identical, and they differ only in the report. Feed the report `A` instead of the bearer state and **an erasure becomes indistinguishable from a trip that never linked anyone.**

**The discriminator is a conjunction, not a field test, and this is where it silently dies.** Absence of the `person:` key is **necessary but not sufficient** for `TOMBSTONED` — erasure removes the key, and a trip that never linked anyone never had one. The second conjunct is the **positive `[ERASED]` evidence**: erasure *removes* the reference field and *substitutes* the derived model's entry heading, because the two locations have opposite absence semantics — removal is safe in the traveller file, where the field is optional and absence is that file's pre-existing normal state, and unsafe in the model, where a stripped heading yields the empty key and hard-stops the reconciler. **An implementation that tests only *"is there a `person:` field?"* reports every unlinked legacy trip as `TOMBSTONED`, or every erasure as `NOT-REFERENCING` — and every composed value is byte-identical either way, so the build stays green.** A composition that normalises both absences to the same state has removed the detection, not simplified it.

**Two prohibitions carried forward.** The tombstone detector is **shape-anchored `per-[0-9a-f]{4}`**, never a bare `per-` substring, which matches hundreds of ordinary English distributives across the corpus. And **no cross-trip correlation of `per-<token>` tombstones**, even to sharpen a diagnostic: the token is minted per (person × trip) precisely to destroy that edge, and re-establishing it to improve an error message reintroduces the linkage erasure exists to remove.

### The override lifecycle

**Set.** An override is written by a human into the trip's `travelers/<traveler>.md` — a `DEFAULT` label given an answer. No agent authors one and no command creates one as a side effect.

**Observe.** `K5` selects it and the report carries `DIVERGENT` or `REDUNDANT-OVERRIDE`. **Composition reports; it does not normalise** — removing a redundant line needs the record's pre-edit value, which composition does not hold.

**Remove.** **Removing an override means moving the trip-side slot from `ANSWERED` to `UNSTATED` — by any member of the equivalence class: deleting the line, blanking it, or writing `—`, which is what the form's own instruction produces.** `V` then falls from `K5` to `K6` and returns the record's value. *With no other effect* is provable rather than asserted: `V(f)` depends only on `(C, p, A, r, s)` — and `s` is field-intrinsic, fixed by the field's own row — so changing `p` for one field changes no argument of any other field. No write to the record, no change to the reference, no change to any sibling field. The one observable side effect is that the field's report line disappears — which is the point.

### One-way — composition never writes the store

> **Composition reads the record and writes the trip. It never writes the store, and it never solicits a write to it. Promotion of a trip value into the record is an explicit, confirmed human act initiated through the command surface — never a side effect of, and never prompted by, composition, enrichment or synthesis.**

**The prohibition on *soliciting* is the load-bearing half, and it is not implied by the rule that no agent writes the record.** A composition pass that emitted a confirm prompt on every `DEFAULT` divergence — *"the record says `balanced`, this trip says `relaxed`; promote?"* — would leave every resulting write human-confirmed, and would satisfy the no-agent-writes rule **literally** while defeating it in practice: the record drifts toward whatever the most recent trip said, one click at a time. The two clauses bound different things — *who may write* and *what may cause a write* — and only together do they keep one trip's local choice from rewriting a durable fact.

**A need that applies to one trip only** is unchanged by any of this and routes exactly as § *A need that applies to one trip only* above already states — to a trip-level hard constraint in `trip-context.md`, never to a per-trip override of a `PERSON` field. Once the intake form is split the trip form carries no `PERSON` slot for such an override to occupy, so the route is enforced structurally at the authoring layer as well. A trip-only need written into a legacy `## Needs` block on a referencing traveller file is `K4`: **retained** in the composed source, so the plan still sees it, and **reported**, with the remedy naming the trip-level constraint. Fail-safe first, corrective second — and the two `Applies to` fields stay the inverse edges § *A need that applies to one trip only* warns they are.

---

## Data Flow

```
templates/traveler-intake.template.md          (the per-traveler intake form)
        │  copied per traveler, filled by hand
        ▼
trips/[dest-year]/travelers/<traveler>.md       (Layer 1 — human-authored, one file per traveler)
        │  enrichment agent reads + reconciles (link to trip-context constraints, never copy)
        │  ┌─ it ALSO reads the prior revision of the model below before replacing it, and
        │  │  carries the [THIRD-PARTY] entry forward verbatim — that entry has no source
        │  │  file by design, so that prior revision is its only surviving record
        ▼  │
outputs/traveler-model.md  [DERIVED]            (reconciled model + desire-overlap signal)
        │◀─┘  prior revision in, rewritten model out — the read grants no authoring
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

**The lifecycle classes are defined once, in `reference/data-architecture.md` § *Lifecycle Classes*.** That document is the engine-wide home for the class set — `accumulate-append`, `rebuilt-each-synthesis`, `versioned`, `persist-mutable`, `output` — and for what each class means. **This section does not restate those definitions.** It records the two things the engine-wide document defers to this one: the **satisfaction layer's own class assignments**, and the derivation that produced `persist-mutable`.

`CLAUDE.md` § *Output Versioning* cites the same home for the same set, in its § *Satisfaction-layer artifacts* subsection — which says in terms that it assigns and does not define. **The rest of that section still states the engine's default-and-exception model in its own words, and correctly so:** it is a live input, read by `reference/data-architecture.md` § *Lifecycle Classes*' own absence rule and by `.claude/commands/trip.md`'s `/trip research` agent-key derivation. One definition; this document cites it and restates nothing, and `CLAUDE.md` both cites it and states behaviour the engine reads back.

The satisfaction artifacts take these classes:

| New artifact | Lifecycle | How it behaves | Closest existing pattern |
|--------------|-----------|----------------|--------------------------|
| `outputs/event-status.md` | **persist-mutable** | Updated **in place** as events change status. **Survives every re-synthesis** — never wiped, never regenerated from scratch. It is the iteration-protection source of truth: the record of what has already been booked / locked / fallen-through must outlive any single planning pass. | None — see below |
| `outputs/traveler-model.md` | `rebuilt-each-synthesis` | A derived projection. The enrichment agent refreshes it from the **current** per-traveler source files whenever those change. Every entry projected from a `travelers/<traveler>.md` file carries no independent state of its own — that source file is authoritative — so regenerating it is safe. **One stated per-entry exception:** the `[THIRD-PARTY]` entry admitted through the operator fallback has **no source file by design** (see the stated exception under **Needs**), so it is **carried forward verbatim** across a refresh rather than re-derived — the operator's statement remains its authority, and this model is the only surviving record of it. The classification is unchanged: the artifact is still rebuilt from source, with that one entry class preserved. | rebuilt-each-synthesis |
| `outputs/satisfaction-metrics.md` | `rebuilt-each-synthesis` | Recomputed by the validator + hub from the **current** itinerary and the current traveler model. A snapshot of coverage at synthesis time; safe to regenerate because its inputs are authoritative. | rebuilt-each-synthesis |

### Why `persist-mutable` exists — the derivation

`outputs/event-status.md` matches **none** of the three classes that preceded it — each read as `reference/data-architecture.md` § *Lifecycle Classes* defines it — and the distinction is load-bearing. This is the reasoning that produced the class; the class itself is defined there, not here.

- **Not `accumulate-append`.** Old status is *mutated*, not preserved as history. When an event goes from "to book" to "booked", the record changes; we do not keep a dated log of every status it ever held.
- **Not `rebuilt-each-synthesis`** — and this is the critical difference. The whole reason status cannot live in `venue-matrix.md` is that a rebuilt artifact is regenerated each synthesis. Status must **survive** the synthesis, not be recomputed by it. A re-synthesis reads existing status; it does not overwrite it.
- **Not `versioned`.** There are no `event-status-v1.md` / `v2.md` snapshots. There is one living file, mutated in place.

That is why `persist-mutable` exists. Its definition lives in the engine-wide home; what this section records is the argument that forced it, kept beside its subject artifact. One rider belongs here because it is satisfaction-layer-specific: `persist-mutable` is **not** append-only — rows are mutated in place, and a row is **deleted** in the one case where its event is removed from the itinerary (see Orphan removal below), so no ghost row lingers. The other two satisfaction artifacts take `rebuilt-each-synthesis` — the *Closest existing pattern* column above is where that mapping is recorded — because they are pure derived projections of authoritative inputs.

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

### Intent is carried by reference, not by copy

The note above says what this layer does not **compute**. This section says what it does not **hold**. An event's *intent* — the standard it was chosen against, as distinct from what has been decided and booked — is not a status field and is not stored on the row. It is carried by **reference**: each intent attribute is mastered somewhere else, and an event reaches it through keys this model already has.

| Intent attribute | Where it is mastered |
|------------------|----------------------|
| **`price tier`** | `trip-context.md` § *Budget Posture* — its `Overall tier` and the `Meals:` splurge appetite. Refined per traveler by `travelers/<traveler>.md` § *Budget appetite* → `Splurge appetite`, which is that traveler's own lean on the trip-level posture and never a replacement for it. A traveler's `Budget cap` need is governed by that same section (§ *Needs*, the Need-category table above), so the personal spend bound and the trip-level price tier share one home instead of sitting in two. |
| **`subgroup`** | The hub's placement record — who a given event is for on a day that divides the party. `reference/site-layout-spec.md` governs how that renders: a split day carrying one Parallel Track block per track, each track labelled with its members verbatim. |
| **hard constraints** | `trip-context.md` § *Hard Constraints* — the heat, mobility, rest, timing and sensory non-negotiables the Need-category table above routes there. |

**The joins already exist.** The `Venue` column carries the venue's `ven-<token>` and is *a reference, not this table's key* (below) — it resolves to that venue's researched entry, which carries that entry's own money line — `Price` in `outputs/food-list.md`, `Price range` in `outputs/nightlife-list.md`, `Cost` in `outputs/transport-brief.md`, each per its writing agent's declaration. The desire an event serves resolves through `outputs/traveler-model.md`, the derived per-traveler projection the hub and the validator already read. This section adds no key and asks for none.

**Why the prior value is still recoverable after a replan — by construction, not by anything added here.** The research lists are `accumulate-append` (`reference/data-architecture.md`, class 6 `outputs/food-list.md`), and `CLAUDE.md` § *Output Versioning* binds the rule directly: agent outputs accumulate, they do not overwrite, previous research is **never** deleted, and a re-source appends a dated section rather than editing what it supersedes. So the superseded entry and its price range are still in the file once the replacement lands. The itinerary is `versioned` (class 15), so the pre-replan placement is on disk too. Intent survives a replan because of the lifecycle classes this architecture already chose — not because the status model started carrying a copy of it.

**Two fences, because this is the easiest section in the document to over-read.** *Nothing here is a score or a bound.* A price tier is a **desire** attribute — optimized within the bounds, never a bound — the same rule `agents/06-validator.md` states for a missed nightlife desire. A `Budget cap` need is the opposite kind of thing: a hard personal spend ceiling, and it stays a bound wherever it is audited. Naming them side by side promotes neither and demotes neither. *And this section adds no field, no column and no writer.* The creation edge in § *Bootstrap* and the primary-writer roles recorded with it are untouched; carriage by reference is a statement about where facts live, never a change to who writes them.

### `outputs/event-status.md` shape

A flat per-event table, one row per event, keyed by a stable **Event ID** plus the day the event currently sits on — shown below **body only**, its frontmatter elided as everywhere in this document. The Event ID is **opaque and day-independent** — **minted by the hub on first placement** and stable across every re-run — and it is the **cross-run join key** that lets a re-synthesis match a row to the same event. It must **not** encode the day (the `Day` column carries that): resequencing routinely moves an event to a different day, so a day-encoded ID would either lie or force a churned key. The illustrative IDs below (`evt-01`, …) are opaque on purpose; real IDs may be any opaque token but **must** be day-independent. The `Venue` column alongside it is a *reference*, not this table's key: it carries the venue's `ven-<token>` so an event resolves to its link by key rather than by name (see § *Venue identity in the satisfaction substrate* below). Updated **in place** (persist-mutable): a re-synthesis *reads* this file to know what to preserve, and writes back only the rows whose status actually changed.

```markdown
# Event Status

> One row per placed event. Exactly one status each.
> Iteration changes only `planned` rows; `locked` / `firmed` are preserved unless the user names them.
> `option` rows are alternatives/bailouts — never auto-promoted into a primary slot.

| Event ID | Venue | Event | Day | Time | Status | Requires booking? | Needs booking (derived) | Notes |
|----------|-------|-------|-----|------|--------|-------------------|-------------------------|-------|
| evt-01 | ven-04 | Riverside izakaya (anchor dinner) | Day 2 | 19:30 | locked  | yes | no  | Table held |
| evt-02 | ven-11 | Hillside museum morning           | Day 3 | 10:00 | firmed  | no  | no  | Group-settled; nothing to book |
| evt-03 | ven-07 | Market hall lunch                 | Day 3 | 12:30 | planned | yes | yes | Needs a reservation — not yet booked |
| evt-04 | ven-19 | Old-town self-guided wander       | Day 4 | 15:00 | planned | no  | no  | Walk-up; no booking needed |
| evt-05 | ven-23 | Noodle counter (Day 3 lunch alt)  | Day 3 | 12:30 | option  | no  | no  | Backup for evt-03; alternative pool |
```

> **Event ID is opaque and day-independent.** The IDs above carry no day (the `Day` column does). `evt-05`'s note references its primary by ID (`evt-03`), not by a day-coded name — so when resequencing moves either event to another day, the join key and the cross-reference both still hold.

**`Time` is a column, not a note.** The clock time an event sits at is **placement** — the same kind of fact as `Day`, decided by the same act, recorded by the same writer, and preserved or moved by exactly the same status rule. It lived in `Notes` as free text until a consumer needed to compare it: a re-bake that moves a dinner from 19:00 to 20:00 on the same day changes nothing else on the row, so a change summary derived from structured artifacts (`agents/05-hub-planner.md` § *Output: outputs/change-summary.md*) could not see the shift at all, and the only surface that carried it — `outputs/final-itinerary.md` — is the prose the summary exists to stop diffing. The value is a **24-hour local clock start time** (`19:30`), or `—` for an event the plan deliberately leaves untimed; a duration or a window belongs in `Notes`, because what makes a re-timing one row rather than two is a comparison over one start.

**This is placement, not intent.** § *Intent is carried by reference, not by copy* holds that the standard an event was *chosen against* — its price tier, its subgroup, the hard constraints it answers — is mastered elsewhere and reached through keys this table already has. A time is on the other side of that line: it is *what has been decided*, which is the half this table was built to hold, and it is mastered here because nothing else masters it.

**And it never joins the key.** `Event ID` remains this table's only key, and `Time` is an attribute compared *within* a matched key. Fold the time into the identity and a re-timed event becomes a *different* event: a keyed difference would then report a drop and an unrelated addition where one move happened — two rows about one thing, which reads worse to a group than the silence it replaced, not better.

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
| "Day 4 dinner: Riverside izakaya, 7 PM confirmed reservation" | a row `evt-11 … Day: 4, Time: 19:00, Status: locked, Requires booking?: yes` |
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

**Whichever agent first writes `outputs/event-status.md` creates it** — the enrichment agent's setup seed (when `## Locked Elements` already names fixed events at setup), or, absent any seed, the **hub on the first full synthesis** (DISCOVERY / ENRICHMENT mode). Each writes only **if the file does not already exist**, so the order is safe — no double-create, no wipe: if enrichment seeded it, the hub finds it and reads-then-updates; if not, the hub creates it, seeding any already-known `locked` events (a held reservation, a purchased ticket, a confirmed hotel). On every subsequent pass the file already exists, so the hub **reads it, then updates it in place** (never re-creates it). The **hub owns the file thereafter.** This is the persist-mutable contract's creation edge: created once, by the first writer; read-then-updated by the hub thereafter; never regenerated from scratch.

**When neither writer has run.** A trip whose plan is synthesised but whose `outputs/event-status.md` was never created — one planned before this substrate existed, or one whose first synthesis predates it — is **detected, not repaired in place**. `agents/06-validator.md` § *Per-event status presence* reports the absence as a **Warning**, and the repair is a full synthesis that reaches the creation edge above rather than any new write. **Which repair is available depends on the trip's mode, because the creation edge does.** In **`DISCOVERY`** or **`ENRICHMENT`**, name **`/trip plan`** — the resolution contract admits that verb in those modes, and its hub dispatch reaches the edge stated above. In **`ITERATION`** or **`RESEQUENCING`** the hub does not create the file at all, so **no single verb repairs the absence there**: the trip's mode has to be recorded through **`/trip-record mode`** before a synthesis can reach the edge — the same shape `CLAUDE.md`'s G5 gives a verb that refuses on `UNSET` and carries the remedy in its own refusal. **The repair runs *through* the existing creator set and never adds to it** — naming a verb is not writing the file, no reader of this document becomes a writer of it, and the two-writer creation order above, with its no-double-create and no-wipe guarantee, is unchanged.

---

## Forward Connection — Profile Edits as a Replanning Trigger

Because each per-traveler file is independently editable, the system gains a capability the old free-text model could not offer: **change detection on traveler preferences.**

The enrichment agent can diff each `travelers/<traveler>.md` against the snapshot it last processed. When a file has changed — a new desire, a revised need, a dropped preference — the agent emits an **update signal**. That signal is a candidate **replanning trigger**: a changed preference can warrant an equity-aware re-plan, alongside the existing missed-booking trigger derived from event status.

This document describes the *capability* and the *data condition* that produces it (an edited source file, detected by diffing against the last-processed snapshot). The replanning behavior the signal triggers — when to re-plan, and how to balance the group fairly — is owned by the replanning capability — `reference/replan-protocol.md` — not by this substrate. The substrate's job is only to make the signal detectable and to carry it.

---

## Satisfaction Metrics

The storage-homes table fixes *where* the coverage view lives (`outputs/satisfaction-metrics.md`) and *how* it behaves over re-runs (rebuilt-each-synthesis, a snapshot recomputed from the current itinerary and traveler model). This section fixes *what* it holds: the **named dimension set** the validator and hub track for a trip, each dimension's **type**, and the artifact's **shape**.

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

Six dimensions make up the satisfaction coverage view. Each is named, typed, and given a definition — and for the balance signals, an explicit note that the scoring is deferred.

| Dimension | Type | Granularity | What it measures | Scoring |
|-----------|------|-------------|------------------|---------|
| **Needs-compliance** | **pass/fail** | per need × per applicable day | Every traveler **need** (per its category — see the Needs table) is honored on every day that need applies to. A hard gate, evaluated per need per applicable day: each (need, applicable-day) pair is `pass` or `fail`. This is the structured metric form of the existing every-day hard-constraint audit (see Reconciliation below) — **not** a balance score. | Fully defined: it is a pass/fail gate. No formula needed — a need is either honored that day or it is not. |
| **Desire-coverage** | **covered / not** | per traveler × per desire (× per honored day for a desire marked `Recurrence: daily`) | Each traveler's **desires** (the anchors and wishes from their source file) are either met by the plan or not. A boolean presence check per desire, reported per traveler. A desire marked `Recurrence: daily` is measured on **every day of that traveler's honored-day set** and is met only when every one of those days carries it. | Fully defined: a desire is `covered` or `not covered`. No degree, weight, or percentage — that would be scoring, which is out of scope. A recurring desire's per-day reading is a **set of booleans**, not a ratio — reporting which days were met is not the same as scoring how many. |
| **Group-equity** | **balance signal** | per trip (across travelers) | Whether the plan serves the travelers *evenly* — that no traveler is systematically over- or under-served relative to the group. A balance signal across travelers' coverage. | **Left to design.** This layer names the signal and its meaning; it does **not** define how evenness is measured, what counts as "systematically under-served", or any fairness threshold. |
| **Experience axes** | **balance signal** | per trip (optionally per day) | Whether the trip carries a healthy measure of four experiential qualities: **creativity**, **fun**, **excitement**, and **newness**. Four named balance signals, tracked so a later capability can read the trip's experiential shape. | **Left to design — and note these axes have no upstream data source in the substrate today** (unlike needs and desires, nothing in the per-traveler files or the itinerary yet grounds them), so a later capability must define **both their source and their scoring**; today they are named, ungrounded, and `(left to design)`. |
| **Rest-recovery balance** | **balance signal** | per trip (across days) | Whether recovery is adequate relative to activity intensity — enough rest/downtime against the demand the plan places on the group. A balance signal over the activity-vs-recovery rhythm. | **Left to design.** Note the seam: the **required-rest** *need* is a hard pass/fail gate under needs-compliance (a non-negotiable rest floor honored or not); **rest-recovery balance** is the softer, trip-wide *signal* of whether the overall rhythm is healthy beyond that floor. The floor is gated; the balance is a signal whose scoring is deferred. |
| **Meal-variety concentration** | **balance signal** | per day | Whether the day's meals concentrate in a single convenience-format category rather than ranging across formats. A balance signal over meal-format spread. | **Left to design.** Note the seam: the **per-category anchor cap** is a hard selection-time rule the food agent enforces (`agents/02-food.md` → Convenience-format anchor discipline); **meal-variety concentration** is the softer, per-day *signal* of whether the resulting spread is healthy beyond that cap. The cap is gated; the balance is a signal whose scoring is deferred. |

> **The line this section holds.** Needs-compliance and desire-coverage are *defined to completion* because pass/fail and covered/not are determinable facts about a plan — no math is invented to produce them. Group-equity, the four experience axes, rest-recovery balance, and meal-variety concentration are *defined as named balance signals with stated meaning*, but their scoring is **left to design** — consistent with "nothing optimizes yet". If a future reader is tempted to add a weight, a percentage, or a ranking to any balance signal, that belongs to a later optimization capability, not to this substrate.

### A need's applicable-day set — how it is derived

Needs-compliance is evaluated *per need per applicable day*, so the **applicable-day set** for each need must be defined. It is derived from the **governing trip-context constraint** the need links to (via "Applies to"): a need applies on exactly the days — and within the time blocks — that its constraint governs. Read it off the constraint's `Time blocks affected` / `Applies to` fields (and the scheduling framework's per-constraint day impact):

The set has two factors, and a day is applicable only when **both** admit it:

- **Constraint factor** — the days the governing constraint governs.
  - A **constant-applicability** need — one whose constraint holds every day regardless of plan (a mobility limit, a dietary/health restriction) — is admitted on **every day of the trip**.
  - A **conditional** need — one whose constraint only bites under certain conditions (a heat ceiling that applies on hot or outdoor-afternoon days; a required-rest floor that applies on its scheduled rest days) — is admitted on **its applicable subset** only.
- **Presence factor** — the traveler's **at-destination day set**, per *Presence — a traveler's present-day set* above. A need is never graded on a day its traveler is not at the destination: there is no plan-day to honor or to breach. It is the **window limb**, never the full present-day set — an *unavailable* traveler is at the destination and carries a parallel track, so their needs are graded that day.

So: **applicable days = the constraint's days ∩ the traveler's at-destination day set.**

This reconciles the language elsewhere that the audit runs "every day": the audit runs **every day the constraint applies to a traveler who is there** — every day that traveler is at the destination for a constant-applicability need, and the intersection of the subset with those days for a conditional one. It is never "every calendar day unconditionally" (a heat ceiling is not *failed* on a cool indoor day it never governed, and a mobility limit is not *failed* on a day its traveler had not yet arrived). This rule is stated **here once**; the scheduler, hub and validator cite it and do not redefine it.

> **Render the trim; never let it read as a conditional.** When presence narrows a need's applicable days, the `Applicable days` cell names the trimmed set **and** its reason — `D2–D4 (at destination D2–D4)` — so a reader can tell a presence trim from a constraint subset. An unnamed absence is the failure `agents/03-scheduling.md` already exists to prevent; a silently trimmed grade is that same failure at the metrics surface.

> **Desire-coverage is typed per tier — a missed anchor is not a missed nice-to-have.** Coverage is `covered` / `not covered` reported **per desire, carrying that desire's priority tier**. The tier travels with the verdict on purpose: a `not covered` **anchor** is a categorically more significant outcome than a `not covered` **nice-to-have**, and a later scorer must not flatten the two into one undifferentiated "coverage %". This layer keeps them distinct by reporting the tier alongside each verdict; it does **not** weight them (that would be scoring) — it just refuses to lose the distinction.

> **A recurring desire is covered only on the days it is honored.** A desire whose `Recurrence` is `daily` carries a coverage reading **per day of that traveler's honored-day set** — see *A recurring desire's honored-day set — how it is derived* below; it is not re-derived here and it is never read against the full trip-day set. The desire is `covered` overall **only when every one of those days carries it**; a partial run is `not covered` with the missed days named. A partial is **not** a third verdict value and **not** a percentage — the enum stays closed at `covered` / `not covered`. And the severity is unchanged: a partly-honored recurring anchor is a worse plan, never a broken one, so it never becomes a needs-compliance failure.

### A recurring desire's honored-day set — how it is derived

A desire marked `Recurrence: daily` is honored on a **set of days**, and both the supply of candidates and the coverage reading are measured against that set — so the set must be defined. It has two factors, and a day is honored only when **both** admit it:

- **Presence factor** — the traveler's **present-day set**, per *Presence — a traveler's present-day set* above. Placement reads both limbs, so this is the full set and not the window limb alone: a slot placed on a day someone is excluded is a slot nobody can take. It is read there and is not re-derived here.
- **Desire factor** — where the desire names a **time block**, the days on which that block falls inside the traveler's own window. Where the desire names no time block, this factor admits every day.

So: **honored days = the traveler's present-day set ∩ the days the desire's own time block reaches.**

**This narrows membership where a need's applicable-day set does not, and the difference is deliberate.** A need's grade is a hard gate, so removing a day would remove an audit — which is why a need carries its time-block scope alongside its day set rather than folded into it. A recurring desire is capped at **Warning** and is never a needs-compliance failure, so a day the desire is not owed on can leave the set without dropping any gate. The presence predicate itself is untouched: the day stays in the traveler's present-day set, and only this desire's obligation is trimmed.

**Render the trim; never let it read as a conditional.** A day trimmed by the desire factor carries a reading that names the trim and its reason — `D2 covered · D3 — (morning block not reached) · D4 covered` — never silence, and never the *"no reading at all"* an **absent** day carries. Absent, unavailable and present-but-out-of-block are three different states and the distinction is carried, not flattened.

Where a desire names no time block, the honored-day set and the present-day set are the same set, and nothing that cites this rule changes behavior.

This rule is stated **here once**; the scheduler, hub, validator and supplier agents cite it and do not re-derive it.

### Write split — section ownership (two writers, never clobbering)

`satisfaction-metrics.md` has **two** writers — the hub and the validator — and the naive "each writes the file fresh" would have the second writer **clobber** the first. The substrate forbids that with **section ownership**: each agent owns specific sections and **reads-merges-writes only its own**, never wiping the other's:

| Section | Owner | Why |
|---------|-------|-----|
| **Desire-coverage** (covered / not, per traveler × per desire) | **Hub** | The hub builds the itinerary, so it holds the coverage read — which anchors/wishes the plan it just produced actually meets. |
| **Balance signals** (group-equity, the four experience axes, rest-recovery balance, meal-variety concentration — all `(left to design)`) | **Hub** | Emitted alongside the hub's coverage read; named and tracked, never scored. |
| **Needs-compliance** (pass/fail, per need × per applicable day) | **Validator** | This is the *recorded form of the validator's every-day constraint audit*; the validator is its natural owner (and the hub's own audit must agree with it). |
| **Needs ↔ constraint agreement check** | **Validator** | The validator owns the reconciliation that every needs-compliance `fail` is a constraint Critical (see Reconciliation below). |
| **Frontmatter block** (the universal fields — `reference/data-architecture.md` § *Universal frontmatter*) | **Validator** | One writer, so the block needs no merge rule at all. The validator authors and refreshes it; the hub carries it through its read-merge-write and preserves it byte-for-byte, never authoring it. The class declares **no per-class field**, so no field is written by both — the partition is total and disjoint by construction, which is what keeps the two-writer split out of YAML. |

The rule each writer follows: **read the current file, replace only your own section(s), write the merged whole back** — never regenerate the file from scratch, never touch a section you do not own. The artifact is still rebuilt-each-synthesis — *each section* is refreshed by its owner from authoritative inputs — but the refresh is per-section, so the two writers compose into one file instead of overwriting each other. (If a future control-flow design prefers a single writer, the clean alternative is to make the **validator the sole writer** and have the hub pass its coverage read in as an input — but the section-ownership split above is the decided model for this substrate.)

### `outputs/satisfaction-metrics.md` shape

A `[DERIVED]` artifact, rebuilt-each-synthesis from the current itinerary and the current `outputs/traveler-model.md` (it carries no independent state — its inputs are authoritative, so regeneration is safe). It records each dimension at its natural granularity: needs-compliance per need per applicable day, desire-coverage per traveler per desire, and the balance signals named with their value **left to design** (shown as `(left to design)` rather than a number).

```markdown
---
artifact: outputs/satisfaction-metrics.md
schema-version: 1
trip: <trip-slug>
writer: [hub, validator]
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal-hard
generated: <YYYY-MM-DD>
---

# Satisfaction Metrics [DERIVED]

> Recomputed from the current itinerary + outputs/traveler-model.md. Lifecycle and
> provenance are declared in the frontmatter above and are not restated here.
> pass/fail and covered/not are determinable today; balance-signal scoring is left to design.
> Persona names follow the public Pat / Jordan / Sam set.

## Needs-compliance — pass/fail, per need × per applicable day
> Each traveler need honored on every day it applies to. A `fail` means the plan is broken on that day.

| Traveler | Need (category) | Applicable days | Per-day verdict | Overall |
|----------|-----------------|-----------------|-----------------|---------|
| Pat    | Heat tolerance (afternoon ceiling) | D1, D3, D4 | D1 pass · D3 pass · D4 pass | pass |
| Jordan | Mobility (step-free, walking ceiling) | all days | D1 pass · D2 pass · D3 **fail** · D4 pass | **fail** |
| Jordan | Required rest (slow start every other day) | D2, D4 | D2 pass · D4 pass | pass |
| Sam    | Dietary/health (allergy) | D2–D4 (at destination D2–D4) | D2 pass · D3 pass · D4 pass | pass |

## Desire-coverage — covered / not, per traveler × per desire
> Each anchor/wish met by the plan or not. Boolean presence — not a degree. A desire
> marked `Recurrence: daily` reads per day across that traveler's honored days.

| Traveler | Desire | Priority tier | Per-day coverage | Covered? |
|----------|--------|---------------|------------------|----------|
| Jordan | Slow museum morning | anchor | — | covered |
| Jordan | Local markets       | wish   | — | covered |
| Pat    | Local market        | anchor | — | covered |
| Pat    | Relaxed museum morning | wish | — | covered |
| Sam    | One standout food experience | anchor | — | covered |
| Sam    | Morning ritual stop | wish | D2 covered · D3 not covered · D4 covered (present D2–D4) | not covered |

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
| Meal-variety concentration | per day | (left to design) |
```

The pass/fail and covered/not tables carry real verdicts because they are determinable from the plan. The balance-signals table carries `(left to design)` in every value cell on purpose: the dimensions are *named and tracked*, their scoring is *not yet defined*. (The metrics examples use the public Pat / Jordan / Sam persona set.)

### Reconciliation — needs-compliance is the existing every-day audit, made structured

The system already holds the rule **"hard constraints are audited every day they apply"**: the hub checks every applicable day against every hard constraint, and the validator double-checks. **Needs-compliance does not introduce a new rule — it is the structured metric form of that existing audit.** Each traveler need links (per the Reconciliation Rule) to a governing `trip-context.md` constraint; needs-compliance records, per need per applicable day (the applicable-day set derived as defined above), whether that constraint was honored — the same check the constraint-compliance audit already performs, now emitted as a per-need-per-day pass/fail record rather than only a prose finding.

**The agreement is a forward implication, not an equivalence.** Every needs-compliance `fail` **is** a constraint-compliance Critical — a per-traveler need is broken exactly when the constraint it links to is violated, so a `fail` always has a Critical counterpart. The converse does **not** hold: a constraint Critical need **not** have a needs-compliance counterpart. A trip-level or group constraint with no per-traveler *need* linking to it (a destination-wide rule, a group-level non-negotiable that no individual traveler's need points at) produces a constraint Critical with **no** needs-compliance row — by design, because needs-compliance is keyed to per-traveler needs and that constraint has none. So: *needs-compliance `fail` ⇒ constraint Critical* (always); *constraint Critical ⇒ needs-compliance `fail`* (only when a per-traveler need links to that constraint). The validator must not enforce the reverse as an invariant — an unlinked constraint Critical with no needs-compliance row is correct, not a discrepancy. The metric is the audit's *recorded shape* for the per-traveler-need slice, not a second, competing judgement.

---

## What This Document Does Not Define

To keep the substrate boundary clear:

- **No metric formulas or scoring math.** `satisfaction-metrics.md` has a *home* here, and the Satisfaction Metrics section above names and types every dimension — but how any **balance signal** (group-equity, the experience axes, rest-recovery balance, meal-variety concentration) is *scored* is out of scope. pass/fail and covered/not are determinable facts; the balance scoring is left to design.
- **No optimization or ranking logic.** Nothing in the satisfaction layer optimizes yet. The engines *read* the derived model; this document does not specify what they do with it.
- **No group destination recommendation *in this layer*.** Per-traveler destination leanings are *captured* (forward-hook (a)); aggregating them into a ranked group shortlist is **realized downstream** in `agents/destination-ideation.md` (which recommends — the group still makes the pick), never in this individual-file substrate.
- **No side-bar / group-split computation.** Per-traveler people-dynamics, desire-overlap, and interest divergence are *captured* (forward-hook (b)); computing any single / small-group / full-group split from them, bounded by `Whole-group moments`, is left to design and is not computed here. No split is ever stored in an individual file.
- **No replanning policy.** The update signal is defined as a data condition; the decision to re-plan and the fairness logic live with the replanning capability — `reference/replan-protocol.md`.
- **No control-flow / consumption sequencing.** Who runs when, and how the hub consumes these artifacts in a pipeline pass, is governed by the control-flow contract, not this data-architecture document.

This file is the **data** contract. Behavior contracts live with their respective agents and capabilities.

---

## Relationship to the Engine-Wide Data Architecture

The engine-wide data model is `reference/data-architecture.md`. **This document is the
satisfaction-layer specialization of it** — the deep model for the satisfaction substrate
(`outputs/traveler-model.md`, `outputs/event-status.md`, `outputs/satisfaction-metrics.md` and the
per-traveler source files), together with the reconciliation, presence and metric rules that hold
that layer together.

**Where the two overlap, the engine-wide document is authoritative for the *shape* and this document
is authoritative for the *satisfaction layer's own content*.** Concretely:

| Question | Answered by |
|---|---|
| Which artifact classes exist across the whole engine, and which are out of the model | `reference/data-architecture.md` |
| Which entities take surrogate keys and which take natural keys, by what rule | `reference/data-architecture.md` |
| What is serialized as frontmatter versus what stays prose, and how each artifact is versioned | `reference/data-architecture.md` |
| The canonical lifecycle-class tokens and their definitions | `reference/data-architecture.md` § *Lifecycle Classes* |
| Which values may reach a published page, and how that class is computed | `reference/data-architecture.md` § *Publishability* |
| The needs-vs-desires model, the lifecycle facets, and the link-don't-copy reconciliation | **this document** |
| A traveler's present-day set, a need's applicable-day set, and a recurring desire's honored-day set | **this document** |
| The four event statuses, the booking-readiness derivation, and the orphan-removal rule | **this document** |
| The satisfaction metric dimensions, their types, and the section-ownership write split | **this document** |

The scope declared at the top of this document is unchanged: it governs the satisfaction **substrate**
and still defines no metric formula, no scoring, and no optimization logic. The engine-wide document
inherits that boundary rather than relaxing it.

---

## Publishability — the satisfaction-layer projection

Two rules stated elsewhere in this document bound what may leave the satisfaction layer:

- § *Lifecycle facets* — **"The bound is the entry class, not a list of fields, so it holds for
  every facet below and for any facet a later release adds ... there is no default-allow outside
  it."**
- § *Needs*, the stated exception — a third-party-sourced need **never** escalates into
  `trip-context.md` and its subject is **never** added to a constraint's `Applies to:` roster,
  because `trip-context.md` is publish-bound and rendered.

**Both are now declared, once, in `reference/data-architecture.md` § *Publishability*** — as the
`publish-contract-values` fence, which the publish-path guard reads and holds no copy of. The
statements above are this document's satisfaction-layer **specialization** of that declaration, not
a second home for it: they say what the bound means for the derived model and the per-traveler
files, and the declaration says which fields and entry classes are in class engine-wide.

**Where the two could disagree, the declaration governs membership and this document governs the
satisfaction layer's own content** — the same split § *Relationship to the Engine-Wide Data
Architecture* above already fixes for every other overlap. Adding a member of the non-publishable
class is a row in that fence; it is not an edit here and it is not an edit to any shell script.

**Citation form.** The two rules above are cited by **section name** from the guard scripts that
consume them, not by line number. A line citation into a living document goes stale on the next
insertion and does so silently — nothing in CI resolves a `file.md:NNN` reference — so the citing
side names the section and the section keeps its name.

---

## Traveler identity — the satisfaction-layer projection

The identity rule for the Traveler entity is stated engine-wide in `reference/data-architecture.md`
§ *3.2 Traveler — natural key*, and that document is authoritative for it. **This section is the
satisfaction layer's own instance of that rule** — the same split § *Relationship to the
Engine-Wide Data Architecture* above already fixes for every other overlap. It supplies the
**reserved-key list** that § 3.2 requires
the schema to carry, and it states the four cases the correspondence rule does not reach. It
authors **no second key and no second filename transform**: both are quoted from the code that
already runs them, which is the whole point of choosing a natural key here.

### The key is computed in two steps, and both are load-bearing

The canonical traveler key is the rule executing in `scripts/publish-trip-site.sh`, function
`nonpublishable_values`, in the branch that handles a `## <Name>` heading of the derived model:

```awk
nm  = clean(head)
key = tolower(nm); gsub(/[^a-z0-9]/, "", key)
```

1. **`clean(head)`** — every bracketed span becomes a space and markdown emphasis is stripped.
2. **fold and strip** — lowercase, then delete every character outside `[a-z0-9]`.

**Uniqueness is asserted over this key, never over the display name.**

**The compressed one-step form omits the first step.** `reference/data-architecture.md` § 3.2 and
`reference/adr/ADR-009-data-architecture.md` Decision 2.2 each state step 2 alone. Read literally,
that form keys `## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]` to `quilloperatorprovidedthirdparty`
where the code yields `quill` — so the compressed statement and the code disagree on **exactly the
provenance-marked entry class the publish guard exists to protect**. The running code is
authoritative. Stating both steps is additive to the engine-wide rule and contradicts no decision
in it.

The guard is cited here by **function name and quotation rather than by line number**, for the
reason § *Publishability — the satisfaction-layer projection* → *Citation form* already gives in
the other direction: a line anchor into a living file goes stale on the next insertion above it,
silently, and nothing in CI resolves one.

### Filename correspondence is a theorem, not a rule to enforce

The filename transform is stated once, in `.claude/commands/trip-new.md` § *Travelers — count and names* (the
roster's `Traveler file` cell), and reused verbatim and attributed by
`.claude/commands/trip-record.md` on both its profile-create and its roster-append paths:

> lowercase the name, replace every run of characters outside `A-Za-z0-9._-` with a single `-`,
> then trim leading and trailing `-`.

**Its restatement sites are closed, and this is the list.** Two of the three documented intake
routes hand the saving to a person rather than to a command — the self-serve copy and the portable
hand-off — so `templates/traveler-intake.template.md` states the transform to the human executing
each of them, once per route, in the *"How to use it"* block and in the assistant hand-off at the
foot of the form. Those two are guidance for a human keystroke, not a second normative home: a
change to the rule is an edit to `.claude/commands/trip-new.md` § *Travelers — count and names* and then to the four
sites listed in this paragraph.

Write `derive(P)` for that transform and `normalize(P)` for the two-step key above. Then for every
display name `P`:

> **`normalize(derive(P)) == normalize(P)`**

`derive` lowercases, maps every forbidden run to `-`, and preserves only `A-Za-z0-9`, `.`, `_` and
`-`. `normalize` then removes case plus every character outside `[a-z0-9]` — which is exactly `.`,
`_`, `-` and whatever `derive` had already removed. The surviving ordered alphanumerics are
identical on both sides.

**So the correspondence holds by construction for every name the derivation touched, and needs no
enforcement.** What needs stating is the complement — the four cases the equality does not reach.

### The display name has one authority — the `## Group` roster

> The **`Person` cell of the `## Group` roster in `trip-context.md` is the authoritative display
> name** for every person the model knows about. The `## <Name>` heading in
> `outputs/traveler-model.md` and the stem of `travelers/<file>.md` are both **projections** of it.
> Where a projection disagrees with the roster, **the roster is right and the projection is the
> defect**: the reconciler reports the divergence and never repairs it by rewriting the roster.

This records an authority the command surface already asserts rather than deciding a new one.
`.claude/commands/trip-record.md` states that *"the denominator is the roster, never the
directory"* and that enrichment takes the `## Group` roster and `- **Total travelers:**` from
`trip-context.md` as the party; `.claude/commands/trip-new.md` calls the roster *"the
**denominator** for profile-gap detection"* with *"no second source for it"*.

Two properties make it the only candidate that works, and neither is convenience. It is **total
over the entry population**: the two entry classes that have no file at all — `[THIRD-PARTY]` and
`PROFILE MISSING` — still have a roster row, and those are precisely the classes the publish guard
is built around, whereas a profile's own title line and a filename stem both fail there. And the
roster row is the **only surface in the engine carrying the display name (`Person`, verbatim) and
the derived path (`Traveler file`) as a pair**, so the correspondence has exactly one checkable
site and the check is within one row rather than a join across files.

### The four cases the correspondence does not reach

These four are the **complete complement** of the equality above, not a sample of it.

| # | Case | Detected where | Disposition |
|---|---|---|---|
| **C1** | **Underived stem.** A profile saved by a route that never applied the transform — the self-serve copy or the portable hand-off — whose stem normalizes to something other than the roster `Person`'s key. | Reconciler, per roster row | **Report, never rename.** Name the roster `Person`, the observed file and both keys, and treat the traveler as **unresolved** — *not* as `PROFILE MISSING`. `travelers/<traveler>.md` is human-authored Layer 1 (§ *Who Writes What — Field Layering*), so renaming it is a write the reconciler does not hold. |
| **C2** | **Empty key.** `normalize(P)` is the empty string — a display name carrying no ASCII alphanumerics. | Reconciler, and intake where it runs | **Hard stop, with the name quoted.** The key is not merely non-unique here, it is **absent**: two such travelers collide at `""`, and `derive(P)` is empty too, so no filename exists for the key to correspond to. The command surface already refuses an empty *derivation* on the create path; this extends the same refusal to the *key*. |
| **C3** | **Reserved-key collision.** `normalize(P)` equals a declared reserved key (below). | Reconciler, and intake where it runs | **Hard stop at intake; refuse the entry at reconcile.** Admitting it is the fail-open: the guard's parse suppresses the entry, so its values never enter the non-publishable class at all. |
| **C4** | **Two display names, one key.** Distinct `Person` values whose keys are equal — `Sam B.` and `Sam. B` both key to `samb`. | Reconciler only — it is a property of the **set**, and the reconciler is the one component that holds the set | **Hard stop, both names quoted; the operator disambiguates the display name.** The engine **never mints a suffix**: a minted suffix is a surrogate key wearing a natural key's clothes, and it would break the correspondence above by construction. |

**C2 is decided here and cited upstream.** The key normalization itself carries no empty guard, and
neither § 3.2 nor ADR-009 Decision 2.2 states the rule — each now names the degenerate point and
cites this case for it, which is the split those documents already take for the four cases. Without
C2 the natural key would be neither total nor injective, and *"uniqueness is asserted over this
key"* would be unsatisfiable at the degenerate point; C2 is what makes that assertion total.

### Reserved keys

> **A reserved key is the normalized key of any `##` heading that the derived model's own shape
> defines as a structural section rather than a person.** The list is therefore *derived from the
> model rather than maintained beside it*: a slice that adds a structural section to
> `outputs/traveler-model.md` adds its key here in the same edit.
>
> **Reserved keys, at this schema version:**
>
> | Reserved key | Heading it normalizes | Where that heading is defined |
> |---|---|---|
> | `updatesignals` | `## Update signals [DERIVED]` | `agents/00-enrichment.md` § *Profile-change detection* |
> | `desireoverlap` | `## Desire overlap` | § *Worked example — a per-traveler file* above |
>
> **No traveler may carry a display name whose key is reserved.** Intake rejects the name and asks
> for a disambiguated one; the reconciler refuses the entry and reports it (C3).

**What the guard consumes today, stated so the gap is not mistaken for coverage.** The publish
guard's derived-model parse reads **this whole list** rather than one hardcoded literal:
`_GUARD_RESERVED_KEYS` holds both members space-padded, and the heading branch matches a normalized
key against it whole. `## Desire overlap` is therefore treated as the structural section it is and
no longer counted as a **person** — case **L11c** in `scripts/test-publish-guard.sh` pins that,
and pins why it mattered: a structural section counted as a person is a phantom entry, and a
phantom entry keeps the `entries == 0` fail-closed sentinel from firing on a model that has drifted
to carry no recognisable person at all.

**What the widening did not buy, measured rather than assumed.** Reserving a key *suppresses* the
field and entry limbs beneath it, so the gap that suppression opens now spans both declared keys
rather than one. Three cases pin it: **L11a** — a declared *field* value under a reserved heading
reaches the render with no backstop of any kind; **L11b** — a suppressed *entry* mark is
backstopped only while no other entry produced a record; **L11d** — the second reserved heading has
L11a's shape exactly. **All three are guard behaviour and are not changed by this section**, which
declares the rule and places the reachable half of the enforcement at the reconciler — the only
component that holds the entry set.

**The intake half is declared and currently unowned, and it is the remaining half.** § 3.2 requires
intake to reject a reserved-key collision. Both intake commands are read-only inputs to this rule
rather than editors of it, so C2 and C3 are enforced at the reconciler and the intake obligation is
recorded here rather than dropped. **No intake command was changed by the release that landed this
list** — the reserved-key hard stop at intake has not shipped, and a claim that it has should be
read against `.claude/commands/trip-new.md` itself.

---

## Serialization — the satisfaction-layer projection

Every artifact this document models carries **YAML frontmatter as its first bytes**, and every
worked example above shows the **body only**. The engine-wide model — the format, the field set,
the frontmatter/body boundary test, the publishability classes and the version contract — is stated
engine-wide in `reference/data-architecture.md` → "Universal frontmatter" and → "Tolerant read", and
the per-class values for `writer`, `lifecycle`, `provenance` and `publish` are that document's § 1.1
class enumeration. **This section restates none of them**, and carries no second copy of that table:
the split is the one § *Relationship to the Engine-Wide Data Architecture* above already fixes, and
a satisfaction-layer copy of a per-class value would be exactly the second home this document exists
to prevent.

Three things are this layer's own, and are stated here because nothing else states them:

- **A worked example in this document shows the body and elides the frontmatter, always.** That
  holds for the three fences under § *Reconciliation Rule — One Source Per Fact*, for the three
  under § *Worked example — a per-traveler file*, for the shape fence under § *`outputs/event-status.md` shape*, and for any fence a later slice adds. Each of
  those sites now says so at the point of use; this is the rule those notes point at.
- **The body shape is unchanged by the frontmatter.** Frontmatter is *prepended* — no heading
  moves, no field label changes, and the `## <Name>` entry key, the `Applies to:` link form and the
  inline `[DERIVED]` / `[THIRD-PARTY]` / `[ENRICH]` / `[OPERATOR-PROVIDED]` marks are all exactly as
  this document already specifies them. The frontmatter declares provenance for the artifact and the
  marks carry it per value: two granularities of one fact, never two homes for it.
- **`travelers/<traveler>.md` is the one artifact here that is never engine-written, and it is
  therefore never engine-upgraded.** A traveler's own file carrying no `schema-version` is
  permanently valid and is read exactly as it always was
  (`reference/data-architecture.md` → "The compatibility guarantee"). An absent fence there is not a
  gap to fill and not a `PROFILE MISSING` case.

---

## Venue identity in the satisfaction substrate

The venue key itself is engine-wide and is **not defined here**: it is
`ven-<token>`, opaque, minted by the hub, and stated once in
`reference/data-architecture.md` → "Venue — surrogate key, forced by measured
evidence". What is this layer's own is what the key does to the per-event table
above, and that is stated here because nothing else states it.

**`event-status.md` carries two identifiers, and they answer different
questions.** `Event ID` is the row's own key — the cross-run join key, opaque and
day-independent, unchanged by this or any later section. `Venue` is a
**reference** to a different entity: the `ven-<token>` of the venue the event
places. One keys the row; the other resolves what the row points at. Neither
substitutes for the other, and the `Event ID` convention is not altered by the
`Venue` column's existence.

**The `Venue` column is what makes the location invariant computable.**
`reference/adr/ADR-005-location-invariant.md` § 3 requires every event to resolve
to a link in `outputs/links-reference.md`, and treats an event that does not as a
Critical finding. Before the key, that resolution was a match between two display
strings written by two different agents at two different times — and this repo
already carries one venue under two names on a single maps URL, so the match was
never sound. With the key on both sides the check is a **set difference over
opaque tokens**: the unresolvable set is exactly the event rows whose `Venue` key
appears in no `links-reference.md` row. That is a decidable question, and it is
the same question the ADR was already asking.

**`Venue` is required on every row, and the empty case is an error rather than a
declared absence.** An itinerary element that names no navigable venue is not an
event — ADR-005 § 1 puts transit connectors outside the event population because
they describe movement *between* destinations — so such an element belongs in the
day's notes and never as a row here. Keeping the column required is what
preserves the distinction between *unresolvable* and *no venue*: a nullable key
would collapse the two, and the invariant would stop being able to tell a broken
link from an element that never had one.

**The day relation does not move here.** Which venue sits on which day, and the
two-appearance cap over it, stay in `outputs/venue-matrix.md`, which
`reference/site-layout-spec.md` § 9.1 already names as that fact's single
authority. The `Day` column above records where an event currently sits; it is
not a second home for the placement matrix.
