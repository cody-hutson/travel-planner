# ADR-002: Living-site refresh — secret model, client-side ambient data, 0-plaintext-leak under automation

- **Status:** Accepted (2026-07-12)
- **Deciders:** repo maintainer
- **Driving work:** the Living-site epic (#60); this ADR is its milestone-head security gate (#66). The "establish the ADR-home convention" item from #66 is satisfied by ADR-001 and is not repeated here.

## Context

travel-planner publishes each trip as StatiCrypt ciphertext (AES-256-CBC + HMAC-SHA256,
600k PBKDF2) to a per-trip **public** GitHub Pages repo. The plaintext itinerary lives only
in the git-ignored local `trips/` working dir — never committed, never in history. Privacy
is "by construction": the published artifact is world-fetchable ciphertext, and the privacy
guarantee reduces to passphrase strength × KDF cost. A fail-closed pre-push guard
(`verify_ciphertext` in `scripts/publish-trip-site.sh`) blocks any plaintext leak.

The Living-site epic wants the published site to stay current (weather, sunset, hours,
transit) and to re-publish when the plan changes. Scheduled/unattended re-encryption changes
the secret and publish path and is security-critical — it runs with no human in the loop — so
the secret model and the 0-plaintext-leak invariant must be decided before any build slice.

The operative privacy line: **trip details must never be accessible to the public — only to
travelers.** Two distinct guarantees follow, and they are decided separately below:

1. the **build process** must never handle private data anywhere but locally; and
2. the **runtime page** must not leak itinerary specifics to third parties.

## Decision drivers

- Preserve "privacy by construction" — no plaintext, and nothing decryptable, in any cloud location.
- The freshness need is "current when refreshed," not "live to the minute" — the itinerary
  re-publishes on an event, not a timer.
- The build host is an always-on local Mac mini, so local scheduling is reliable, not best-effort.
- Efficiency — avoid a standing server, and avoid re-baking for data the page can fetch itself.

## Options considered

1. **Cloud scheduler (GitHub Actions cron) re-encrypts + republishes.** Rejected: requires the
   plaintext itinerary *and* the passphrase to reach CI — either committing plaintext (breaks
   the core invariant) or a cloud secret store (a new attack surface and a decryptable secret
   in the cloud). Violates the privacy line.
2. **Local scheduled re-bake of everything, including weather/hours.** Workable but wasteful —
   re-bakes and re-encrypts the whole site on a timer to refresh ambient data the page could
   fetch itself. Higher compute/token cost and more frequent pushes.
3. **Local build owns encryption; the page fetches ambient data client-side; re-publish is
   event-driven.** Chosen — see below.

## Decision

### 1. Secret model — local build, no cloud secret

All encryption and publishing runs on the always-on local Mac mini. The passphrase stays local
— recommended in the macOS Keychain (encrypted at rest, ACL-scoped) rather than the chmod-600
`.passphrase` file, so an unattended run has a non-interactive but not-plaintext-on-disk secret.
GitHub push uses the existing `gh` auth and the enforced no-reply commit identity. **No secret
and no plaintext ever reside in any cloud location.**

### 2. Living data — client-side, city-ambient only

The published (decrypted-in-browser) page fetches live data client-side, scoped to
**city-ambient data only**: weather, sunset/daylight, and local time, keyed by city or
coordinates. Everything venue- or route-specific (hours, "open now", reservations, transit
legs) stays **baked inside the ciphertext**. Rationale: a client-side fetch is visible to the
API provider and the network, so a city-level query reveals at most the destination (which a
passphrase-holding traveler already knows), whereas a venue- or route-level query would reveal
itinerary specifics to a third party. Itinerary detail therefore never leaves the encrypted
artifact.

### 3. Auto-republish trigger — event-driven, not a timer

Re-publish fires on an **async traveler-update / plan-change event**, not on a weather/hours
timer (those are handled client-side per Decision 2). The flow: a plan change is proposed and
group-approved (the approval mechanism is out of scope for this ADR — tracked in #77), then the
Mac mini re-bakes the site from local plaintext, re-encrypts, runs the pre-push guard, and
pushes ciphertext. Event-driven republish keeps pushes rare and meaningful.

### 4. 0-plaintext-leak invariant under automation

The fail-closed pre-push guard runs before every push, unattended runs included. On any guard
failure the automated run **aborts the push**, leaves the prior ciphertext live (a stale-but-safe
published state), and alerts the operator — it never falls back to publishing plaintext. The
`--plaintext` opt-out is **hard-disabled in the automated path**; it remains available only for
an explicit interactive invocation. A regression test covers the automated path (guard fires;
plaintext path refused).

### 5. ADR-home convention

Established by ADR-001 (`reference/adr/`); this ADR consumes it. No separate convention work is required.

## Consequences

**Positive**

- Every existing invariant is preserved: no plaintext or decryptable secret in any cloud; the
  build process handles only local plaintext; the published repo is ciphertext-only.
- Client-side ambient data gives a "living" feel with no re-bake and no standing server —
  efficient in tokens and compute.
- Event-driven republish makes each push a meaningful, group-approved change rather than timer noise.
- The guard's fail-closed posture carries into automation unchanged; a failure degrades to
  "stale but safe," never to a leak.

**Trade-offs**

- Baked data is "current when refreshed," not live-to-the-minute (venue hours change only on
  republish). Accepted per the freshness priority.
- A client-side ambient fetch still reveals the destination *city* to the weather/time API
  provider. Accepted as low-sensitivity; venue/route specifics are deliberately excluded to keep
  this bounded.
- Refresh depends on the Mac mini being powered and online. Accepted — it is an always-on host by design.
- Keychain-based retrieval is macOS-specific; a future non-mac build host would need an
  equivalent secret store (noted, not solved here).

## Follow-on build slices (out of scope for this ADR; tracked under the Living-site epic)

- Client-side ambient-data widget (weather / sunset / local time) in the site render, city-keyed.
- The event-driven local re-bake → re-encrypt → guarded push path, plus its regression test.
- Keychain-backed passphrase retrieval for the non-interactive path.
- Group approval for plan changes gating the republish — tracked in #77, upstream of the trigger.

## References

- Living-site epic (#60) and its milestone-head security gate (#66).
- Group-approval-for-plan-changes gap (#77) — gates the republish trigger.
- Current model: `scripts/publish-trip-site.sh` (StatiCrypt encryption, passphrase resolution,
  the `verify_ciphertext` guard), `scripts/test-publish-guard.sh` (guard regression tests), `SECURITY.md`.
- ADR-001 (`reference/adr/README.md`) — established the ADR convention.
