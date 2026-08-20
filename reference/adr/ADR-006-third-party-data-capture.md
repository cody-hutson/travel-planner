# ADR-006: Third-party data capture — consent and attribution for party members without a profile

- **Status:** Proposed (2026-08-20)
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

**Not yet decided — this ADR is `Proposed`.** It gates #119 outright, and gates Option A of
#120; neither may enter a release until these questions are settled. Four questions, answered
**per data class** (constraints and identity may be decided differently):

1. **May third-party data of this class be captured at all** without that person's own opt-in,
   or does ADR-004's opt-in requirement extend to it? Answer once for **constraints** and once
   for **identity**.
2. **If yes, where** — the enrichment operator-provided fallback (Option 3), or a proxy profile
   with an explicit consent attestation (Option 4)? A permissive answer for identity alone may
   also be satisfied by the intake form itself, since the passport precedent already lives there
   for the filler; that is the one case where Option 2 is not automatically foreclosed.
3. **What reaches published output?** Needs flow into trip-level `Hard Constraints`. Whether a
   third-party-sourced value may appear there — and in what form — needs an explicit answer,
   because ADR-004 § 4's non-publication guarantee is scoped to contact/emergency fields and
   covers neither class today.
4. **Does a permissive identity answer bind #93?** Per-traveler entry-requirements determination
   consumes "country + validity only — never passport numbers or other PII". If party passports
   are captured anywhere, #93's per-traveler resolution depends on where.

**[RECOMMENDED]** Option 3, extended with a provenance marker, on three grounds: it composes
with a seam that already exists rather than adding a capture surface; it keeps the intake form
unchanged, so ADR-004's rejected option is not reopened; and it inherits the git-ignored
working-dir boundary, so question 3 resolves conservatively by default. Option 4 is the better
answer if the maintainer judges that an unverifiable consent attestation is still worth
recording explicitly. This recommendation is not a decision — it awaits ratification.

## Consequences

Stated conditionally, for the recommended option; to be finalized when the decision is made.

**Positive**

- No new capture surface in the intake form; ADR-004's rejected option stays rejected.
- Constraints inherit the git-ignored working-dir boundary, so nothing new becomes publishable.
- Reconciliation and de-duplication reuse an existing path rather than a parallel one.

**Trade-offs**

- The constraint depends on the organizer recording it, so it is only as reliable as that step.
- Provenance-marking documents that a constraint is second-hand; it does not establish consent.
- If question 3 is later answered permissively, the non-publication boundary must be revisited
  with a guard equivalent to ADR-004 § 4's.

**Blocked on this ADR**

- #119 — remains out of a release milestone until this ADR reaches `Accepted`.
- #120, **Option A only** — the card itself is not blocked. Its Stage-5 fork may resolve to
  Option B (state the field's singular scope) at any time, which introduces no third-party
  capture and needs nothing from this ADR.
