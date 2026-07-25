# ADR-004: Traveler contact & emergency info — privacy-handling model

- **Status:** Accepted (2026-07-12)
- **Deciders:** repo maintainer
- **Driving work:** the design gate for contact/emergency capture (#75); relates to the intake epic (#69), which deferred this as a design-first follow-on.

## Context

A traveler's contact method and emergency contact would help group coordination, but they are
PII — and the intake epic (#69) deliberately kept PII out of the form (passport captured as
country + validity only, no numbers). There is no home for this data today, and ad-hoc capture
would risk leaking personal detail into published output. The model must be decided before any
capture is built.

## Decision drivers

- **Privacy-by-construction** — nothing private in the published (public) artifact.
- **Minimal surface** — capture only what coordination needs.
- **Consistency with the passport precedent** — coarse, no sensitive numbers, never published.

## Options considered

1. **No capture (status quo).** Rejected: leaves a real coordination gap (no way to reach a
   traveler or their emergency contact).
2. **Capture into the intake form / published site.** Rejected: PII in the published artifact —
   even encrypted — widens exposure and contradicts the passport precedent.
3. **Capture into the git-ignored `trips/` working dir only, organizer-visible, never published.**
   Chosen — see below.

## Decision

### 1. Storage location

Contact/emergency info lives in the git-ignored `trips/` working dir **only** — which already
holds real personal detail and is never committed or published. It is **never** written to the
published artifact or `trip-context.md`.

### 2. Minimum field set

A contact method + one emergency contact (a name and how to reach them). No more.

### 3. Consent & visibility

Captured on explicit traveler **opt-in**. **Organizer-visible** (the coordinator who runs the
build) — **not** published to the group site.

### 4. Non-publication guarantee

Enforced by a **fail-closed validator check + build-time exclusion**: the publish/render path
never reads the contact/emergency fields, and the guard treats their presence in any
publish-bound artifact as a failure (consistent with the publish guard in ADR-002).

## Consequences

**Positive**

- PII stays local and is never published; consistent with the passport precedent.
- Minimal surface; enforcement is fail-closed, like the publish guard.

**Trade-offs**

- Organizer-only visibility means a non-organizer traveler cannot see others' emergency contacts
  on the site — acceptable, since the organizer coordinates.
- The validator gains a new non-publication check to maintain.

## Follow-on build slices (out of scope for this ADR; currently unscoped)

- The `trips/`-local contact/emergency capture (fields + storage).
- The validator non-publication check for these fields.
- The intake opt-in prompt.

## References

- This gate (#75) and the intake epic that deferred it (#69).
- ADR-002 (privacy model + fail-closed publish guard) — the enforcement pattern this reuses.
- Coordination epic (#77) — a downstream consumer of contact info.
