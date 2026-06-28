# Traveler — [Name]

> One file per traveler. This is *your* profile — your needs and your wants for the trip.
> Copy this template to `trips/[destination-year]/travelers/<your-name>.md`, fill it in,
> and edit it anytime; the plan re-reads it when it changes.
> It lives in the git-ignored `trips/` working dir and is **never published** — fill in your
> real specifics here. Replace every `[bracketed placeholder]` with your own detail; delete
> any need block that does not apply to you. Leave the placeholders as-is if you have nothing
> to add for a section.
>
> Two parts, and the difference matters:
> - **Needs** are non-negotiable — the boundary the plan must stay inside (a heat ceiling, a
>   mobility limit, an allergy, a rest floor). A plan that breaks a need is broken.
> - **Desires** are what you *want* — the plan optimizes for them inside the bounds your needs
>   set. A missed desire is a worse plan, not a broken one.
>
> Placeholders only in this template — no real personal data in the template file itself.

---

## Needs

> Must-satisfy boundaries. Each need is your personal stake in a trip-level constraint that
> lives in `trip-context.md` — so each need **points at** that constraint via "Applies to"
> rather than restating it. Fill in the personal *specific* (the how-much, the what-exactly);
> the constraint text itself stays in `trip-context.md`. Four categories — keep the ones that
> apply to you, delete the rest.
>
> If you have a real need with no matching constraint in `trip-context.md` yet (e.g. a rest
> floor the trip hasn't captured), still write it here — the enrichment agent flags it so the
> constraint can be added to `trip-context.md`. Don't let this file become the home for a
> trip-level constraint.

### Heat tolerance
> Your outdoor-exposure ceiling — how much heat / sun / humidity you can take, and for how long.

- **Category:** Heat tolerance
- **Specific:** [The personal detail — e.g., "fades fast above ~82°F / 28°C in direct sun; needs shade or indoors by early afternoon on hot days." Leave as-is if heat is not a need for you, or delete this block.]
- **Applies to:** [Link to the governing trip-context constraint, written as `Hard Constraints → "<Constraint name>"` — e.g., `Hard Constraints → "Afternoon heat ceiling"`. Leave blank if no matching constraint exists yet; the enrichment agent will flag it.]

### Mobility
> Your movement envelope — walking distance, stairs, standing time, terrain, rest-break cadence.

- **Category:** Mobility
- **Specific:** [The personal detail — e.g., "prefers fewer than ~15 minutes continuous walking before a sit-down break; step-free routing." Delete this block if mobility is not a need for you.]
- **Applies to:** [`Hard Constraints → "<Constraint name>"` and/or `Dietary & Health → mobility notes` — e.g., `Hard Constraints → "Limited stair tolerance"`. Leave blank if none exists yet.]

### Dietary / health
> Your food-and-health boundary — allergies, restrictions, medical needs, pacing limits.

- **Category:** Dietary / health
- **Specific:** [The personal detail — e.g., "tree-nut allergy; carries an epi-pen; needs nut-free confirmation before any tasting menu." Delete this block if you have no dietary/health need.]
- **Applies to:** [`Dietary & Health` (and/or a `Hard Constraints` block that encodes a health non-negotiable) — e.g., `Dietary & Health → "Allergies"`. Leave blank if none exists yet.]

### Required rest
> Your recovery floor — the rest you must get (a slow morning, a mid-day break, an early night)
> for the rest of the plan to hold.

- **Category:** Required rest
- **Specific:** [The personal detail — e.g., "needs one slow start (no fixed plan before ~10:00) every other day to keep pace the rest of the trip." Delete this block if you have no required-rest floor.]
- **Applies to:** [`Hard Constraints → "<Constraint name>"` — e.g., `Hard Constraints → "Daily pacing floor"`. If your rest need is non-negotiable and the trip has no rest/pacing constraint yet, leave blank — the enrichment agent flags it so one can be added.]

> Add or remove need blocks as needed. Each need is exactly one of the four categories above.

---

## Desires

> What you want out of the trip — the want-to-do, the would-love-to-see, the kind of day you
> hope for. Unlike a need, a desire is owned entirely by this file (it links to nothing) and
> carries a **priority tier** so the plan knows what matters most to you.
>
> Repeat the entry shape below for each desire — add as many as you like, delete the spares.
> Fill in the **Desire** and pick exactly one **Priority tier**; theme tags are optional.

- **Desire:** [What you want — e.g., "a slow museum morning rather than a packed sightseeing sprint."]
- **Priority tier:** [Exactly one of:
    - **anchor** — you'd be genuinely disappointed to miss this; the trip should be built to land it.
    - **wish** — a real want the trip should try hard to include, but which can yield to a need or to another traveler's anchor.
    - **nice-to-have** — a bonus; pleasant if it fits, no loss if it doesn't.]
- **Theme tag(s):** [*(optional)* one or more free-text tags grouping the desire by kind — e.g., `museums, slow-pace`, `markets, food`, `nature`, `nightlife`. Tags are how desires are matched across travelers for overlap; they're descriptive labels, not a fixed list to choose from. Leave blank if none.]
- **Overlap:** [*(leave blank — you don't fill this in)* The enrichment agent computes which **other** travelers share this desire (or `solo` if no one else lists it) by matching across all profiles. If you already know someone shares it, you may note who you *think* shares it — but the reconciled answer is computed, not authored here.]

- **Desire:** [Second desire — e.g., "explore local markets."]
- **Priority tier:** [anchor / wish / nice-to-have]
- **Theme tag(s):** [*(optional)* — e.g., `markets, food`]
- **Overlap:** [*(leave blank — computed by enrichment)*]

- **Desire:** [Third desire — e.g., "one standout coffee place."]
- **Priority tier:** [anchor / wish / nice-to-have]
- **Theme tag(s):** [*(optional)* — e.g., `food`]
- **Overlap:** [*(leave blank — computed by enrichment)*]

> Add or remove desire entries freely. There is no trip-level "desire constraint" — desires
> are yours alone. Priority tiers are priority *labels* (this matters more than that), not
> numeric weights or scores — nothing optimizes against them yet.
