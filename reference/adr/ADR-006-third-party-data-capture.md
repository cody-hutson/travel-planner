# ADR-006: Third-party data capture — consent and attribution for party members without a profile

- **Status:** Accepted (2026-08-21)
- **Deciders:** repo maintainer
- **Driving work:** the design gate for #119 (no home for the needs of a party member who has no profile) and for Option A of #120 (a plural-aware `Passport` field); extends the PII precedent set by [ADR-004](ADR-004-contact-emergency-privacy.md); relates to the intake epic #69, which kept per-traveler detail out of the form.

## Context

`Party` captures **who** travels with you. Nothing captures **their** constraints.

The v0.8.0 AC1 cold-assistant attestation surfaced the gap with a concrete case: a party
member with a 20-minute walking limit and an afternoon rest floor — the two most
plan-breaking inputs in that group — had nowhere to go. The assistant filed them under the
filler's own `## Needs` blocks with the party member's name attached, which makes them read
as the filler's own constraints and duplicates them if that person later files a profile.

The form is explicit that this is the wrong shape: *"Everything here is your individual
view"* (`templates/traveler-intake.template.md`), and each need is *"your personal stake in
a trip-level"* rule. A constraint belonging to someone else has no valid home in a
one-form-one-traveler document.

**The problem is not storage — it is consent and attribution.** Three constraints already
bind this space:

1. **ADR-004 rejected the intake form as a home for personal detail**, and bound capture to
   explicit traveler opt-in. A party member who has no profile cannot opt in; someone else
   is speaking for them.
2. **The data class is more sensitive than what the form already carries.** `Party` holds a
   coarse roster line ("my dad, 78"). A mobility limit and a rest floor are health data, and
   needs flow upward into trip-level `Hard Constraints`, which reach the planner and can
   reach rendered output.
3. **An existing seam partly answers this.** The enrichment agent already reconciles
   travelers without a usable profile by falling back to operator-provided needs and desires,
   *marked as operator-provided* — on the principle that an absent profile means **unknown**,
   never **no constraints**. Whether that seam is the right home for third-party constraints,
   and whether it satisfies the consent question at all, is undecided.

**Two data classes, one consent question.** A milestone-readiness pre-flight found the same
question arriving from a second direction. #120 (`Passport` is singular while `Party` is plural)
can be resolved either by scoping the field explicitly to the person filling the form, or by
making it **plural-aware** — which would capture *issuing country and validity for party members*.
That is third-party **identity** data rather than a health constraint, but it is the same consent
problem: recording personal data about someone who has no profile and cannot opt in. It has no
covering record today — ADR-004 decides contact and emergency info and treats passport as its
consistency *anchor*, not its subject; the template's own guidance scopes the field to *"your
nationality and your document's dates"*.

This ADR therefore covers **both classes**, and may answer them **differently**:

| Class | Example | Driving card |
|---|---|---|
| **Constraints** (needs) | a 20-minute walking limit, an afternoon rest floor | #119 |
| **Identity** (logistics facets) | issuing country and validity for a party member | #120, Option A only |

The classes are not equally sensitive — a mobility limit is health data, while a nationality is
already captured coarsely for the form's own filler under the passport precedent. A decision that
permits one and refuses the other is a legitimate outcome; what is not legitimate is leaving
either undecided while a card that depends on it enters a release.

Doing nothing has a cost the attestation already measured: the group's most plan-breaking
inputs never reach the planner, and the itinerary breaks on the ground.

## Decision drivers

- **Consent integrity** — ADR-004 bound capture to explicit traveler opt-in. A proxy-authored
  constraint has no opt-in by construction. Either the model provides one, or it states why
  this data class does not require one.
- **Attribution correctness** — the constraint must reach the planner *once*, attached to the
  right person, and must not duplicate when that person later files their own profile.
- **Privacy-by-construction** — nothing private in the published artifact, consistent with the
  ADR-002 publish guard and ADR-004 § 4's fail-closed non-publication guarantee.
- **Planning fidelity** — a constraint that never reaches the planner is not a privacy win;
  it is a plan that fails a real traveler.
- **Minimal surface** — consistent with the passport precedent: capture coarsely, only what
  planning needs, never more.

## Options considered

**1. Status quo — no home.** The filler either omits the constraint or misfiles it under
their own needs. Rejected on evidence: the attestation shows this produces both outcomes, and
the misfiled variant corrupts attribution and duplicates later.

**2. Capture in the intake form as a per-party-member needs block.** A new repeatable block
under `## Needs` keyed to a `Party` entry. Directly contradicts ADR-004's rejected Option 2
(personal detail in the intake form) and offers no opt-in path for the person described. It
also breaks the form's stated one-form-one-traveler invariant.

**3. Extend the enrichment operator-provided fallback.** The organizer records the constraint
through the existing operator-provided path in `agents/00-enrichment.md`, marked with its
provenance, living only in the git-ignored `trips/` working dir. No new capture surface in the
form; no change to what is published. Reconciliation and de-duplication already exist on this
path, which is where the *"exactly once"* requirement is satisfied. Open question: whether
provenance-marking alone is a sufficient consent posture for health data about a third party.

**4. Proxy profile.** The party member gets a thin profile file authored on their behalf,
explicitly marked proxy-authored, carrying a consent attestation from the filler ("I have this
person's agreement to record these constraints"). Strongest consent posture and cleanest
attribution — a real identity to reconcile against — at the cost of a new artifact type and a
consent claim the system cannot verify.

## Decision

**Accepted 2026-08-21.** Answered per data class, as the Context requires. The two classes are
decided **differently**: constraints are capturable on a non-publishable surface; identity is not
capturable at all.

### Constraints (a party member's needs) — CAPTURE PERMITTED, via Option 3

**Q1 — yes**, third-party constraint data may be captured without that person's own opt-in, on a
surface that cannot be published. ADR-004's opt-in requirement is scoped to capture that reaches a
*published* artifact; the consent hazard it guards against does not arise where the value cannot be
published by construction. Refusing capture outright was rejected on measured evidence: the v0.8.0
attestation showed the group's two most plan-breaking inputs never reaching the planner, which is a
plan that fails a real traveler rather than a privacy win.

**Q2 — Option 3.** The organizer records the constraint through the existing operator-provided path
in `agents/00-enrichment.md`, marked with its provenance, resident only in the git-ignored `trips/`
working directory. No new capture surface; reconciliation and de-duplication reuse the seam where
the *"exactly once"* requirement is already satisfied.

**Option 4 (proxy profile) rejected**, notwithstanding its more explicit consent story. A proxy
profile creates a **durable identity artifact for a person who never asked for one**, backed by an
attestation the system cannot verify. Fewer durable records about a non-consenting person is the
better privacy posture; an unverifiable consent claim records the appearance of consent rather than
consent itself. **Option 2 rejected** — ADR-004's rejected option stays rejected. **Option 1
rejected** on the evidence above.

**Provenance-marking documents that a constraint is second-hand. It does not establish consent, and
must not be described as though it does.**

**Amendment (2026-09-03, Thursday) — the durable record Option 3 creates is named, bounded, and given
a delete path.** The decision above is unchanged: Option 3 stands, Option 4 stays rejected, and
identity capture stays refused. What is corrected is an omission. Option 4 was rejected partly on the
comparison that *"fewer durable records about a non-consenting person is the better privacy posture"* —
and **the Option 3 accepted here creates a durable record of its own, which this ADR never named and
gave no way to delete.** That record is the party member's `## <Name>` entry in that trip's
`outputs/traveler-model.md`. Because that person has no source file by design, the enrichment agent
**preserves that entry verbatim across every regeneration** rather than re-deriving it — the model the
engine last wrote is *"the only surviving record of what the operator stated."* Three corrections
follow, and **none of them widens the data class or adds a capability**:

1. **The record exists and is named** — that carried-forward entry. It is a *record*, not a
   projection; the engine's own text says the derived model *"remains that entry's record rather than
   its authority."*
2. **Its bound is stated** — **trip-scoped**, resident only in the git-ignored working directory,
   non-publishable under Q3 below, and **never promoted to a cross-trip record**. A cross-trip person
   record for a `[THIRD-PARTY]` party member is **Option 4 at a wider scope** — a durable identity
   artifact for a person who never asked for one, now linking them across trips — and every ground
   given for rejecting Option 4 is *stronger* at that scope, so it is refused, not permitted.
3. **It acquires a delete path.** An erasure verb reaches it by **substitution**, never by
   regeneration, because regeneration reproduces it verbatim by design.

**This strengthens the consent posture rather than relaxing it**: it stops this ADR resting on a
records-minimization comparison its own accepted option partly defeats, and gives the record it forgot
a way to be deleted. **The needs-only boundary and the consent language above are untouched.**

**One over-statement, corrected because it is attributed here.** The absolute phrasing *"no durable
artifact of any kind"* appears in `agents/00-enrichment.md` and `.claude/commands/trip-record.md`, both
citing this ADR. **This ADR does not say that, and as written the claim is false** — the entry has no
*file*, and its durable record is the carried-forward model entry above. Those two surfaces are
corrected on their own cards; the claim is disowned here so it is not re-derived from this record.
Recorded by `ADR-012`, which ratified the amendment.

### Identity (a party member's issuing country and validity) — CAPTURE REFUSED

**Q1 — no.** ADR-004's opt-in requirement extends to third-party identity data. It is not captured
in the intake form, in the enrichment fallback, or on any other surface.

This ratifies a resolution that has already shipped. #120 resolved in **v0.9.1** to Option B: the
`Passport` field is scoped explicitly to the person filling the form — *"**Yours alone — not your
party's**"* — and the template directs anyone else whose entry requirements need checking to file a
profile of their own, stating that otherwise *"their passport isn't recorded anywhere."* **Option A
(a plural-aware field) is foreclosed by that shipped resolution**, not merely declined here.

### Q3 — Published output: nothing third-party-sourced is published

A third-party-sourced constraint **shapes the plan but is never rendered**. It may inform scheduling
— pacing, rest blocks, walking distances, venue selection — and **must not appear as stated text in
any published artifact, in attributed or anonymized form**.

**Anonymization is explicitly insufficient.** In a small named party, *"one traveler needs an
afternoon rest"* discloses health data about an identifiable person; stripping the name does not
strip the identification.

This **extends ADR-004 § 4's fail-closed non-publication guarantee** — previously scoped to
contact/emergency fields — to cover third-party-sourced needs. Any future permissive answer here
requires an equivalent guard and a superseding ADR.

### Q4 — #93 is UNBOUND

Because identity capture is refused, party passports are captured nowhere. #93 (per-traveler
entry-requirements determination) resolves per-traveler **only for travelers who have filed their own
profile**, from country + validity on their own form. No dependency on this ADR remains.

## Consequences

Final, for the decision above.

**Positive**

- No new capture surface in the intake form; ADR-004's rejected option stays rejected.
- Constraints inherit the git-ignored working-dir boundary, so nothing new becomes publishable.
- Reconciliation and de-duplication reuse an existing path rather than a parallel one.

**Trade-offs**

- The constraint depends on the organizer recording it, so it is only as reliable as that step.
- Provenance-marking documents that a constraint is second-hand; it does not establish consent.
- Question 3 is answered restrictively, so the non-publication boundary holds by construction.
  Any future permissive answer requires a guard equivalent to ADR-004 § 4's and a superseding ADR.
- Refusing identity capture means a party member's entry requirements are not determined unless
  they file their own profile. This is the accepted cost of the opt-in boundary.
- **(Amended 2026-09-03, Thursday.)** Option 3 leaves the party member one durable record — the
  carried-forward `## <Name>` entry in that trip's `outputs/traveler-model.md`, preserved verbatim
  because there is no source file to re-derive it from. It is **trip-scoped, git-ignored,
  non-publishable, never promoted cross-trip, and deletable by substitution**. It was created by the
  original decision and simply not named; naming it is what makes it reachable by a delete path. See
  the amendment in § *Decision*.

**Released by this ADR**

- **#119 — unblocked.** Its scope is now determined: implement the Option 3 path in
  `agents/00-enrichment.md` with provenance-marking, no intake-form change, and no publication.
  The card was written against a wider option space and **must be re-scoped and re-triaged before
  it is bundled** — it carries `status: approved`, not `status: bundled`, and has not passed a
  Stage 3 Bundle in any milestone.
- **#120 — moot.** Shipped in v0.9.1 via Option B; Option A is foreclosed by events. This ADR's
  gating clause over #120 is discharged, not merely satisfied.
