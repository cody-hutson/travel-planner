# ADR-003: Group coordination — change representation, approval workflow, notification, privacy

- **Status:** Accepted (2026-07-12)
- **Deciders:** repo maintainer
- **Driving work:** the group-coordination epic (#77); this ADR is its milestone-head design gate (#86).

## Context

The living-site auto-republish path (#85, ADR-002) fires on a group-approved plan change,
but the mechanism for *proposing, approving, and notifying* a change was undesigned. Two
constraints shape the whole design:

1. **The site is static, encrypted, and server-less** — published ciphertext on GitHub Pages,
   with no backend to collect votes or push notifications.
2. **Trip detail lives only in the encrypted artifact** — so the coordination channel must
   not expose more than the site already does.

These choices must be decided once before build slices are cut under the coordination epic.

## Decision drivers

- **No backend** — there is no server to collect per-traveler approvals or push alerts.
- **Privacy** — the coordination channel must not widen exposure beyond the encrypted site.
- **Preserve privacy-by-construction** (ADR-002) — no server, no cloud secret.
- **Low ceremony** — this is a personal group-trip tool, not an enterprise approval system.

## Options considered

1. **System-enforced multi-party voting** — a backend collects and counts each traveler's
   approval. Rejected for v1: requires a backend, breaking the server-less /
   privacy-by-construction model. **Retained as a future direction** (#88).
2. **Silent re-bake** — republish on any change with no approval. Rejected: the point is
   group consensus before a shared plan is overwritten.
3. **Organizer-mediated, out-of-band approval.** Chosen — see below.

## Decision

### 1. Change representation

The local build emits a plain-language **before/after change summary** (what moved, dropped,
or was added), carrying no more detail than the site already encrypts. The organizer shares it.

### 2. Approval workflow — organizer-mediated

The organizer (who owns the Mac mini and the plaintext) shares the change summary, the group
approves through their own channel (out-of-band), and the organizer **confirms → the republish
path (#85) fires**. Republish gates on the organizer's confirmation, **not** a system-counted
quorum. On rejection, the current published plan holds. The tool does what only it can —
represent the change and gate the republish — and the humans do the consensus.

### 3. Notification — pull-based

The published site shows a **"change pending / recently updated" state on next open**; the
organizer optionally nudges the group out-of-band. No push infrastructure, no server.

### 4. Privacy

The change summary and the notification never carry more than the encrypted site already does;
nothing new reaches a public or third-party surface.

## Consequences

**Positive**

- Server-less and privacy-by-construction are preserved; the design matches the mechanism to
  the static-site constraint (as ADR-002 put the secret on the local host).
- Low ceremony; the organizer already holds the plaintext, so mediation adds no new trust boundary.

**Trade-offs**

- Approval is **not system-enforced** — it relies on the organizer to honor group consensus.
- Async approvals are not tracked by the tool (they happen out-of-band).
- System-collected, per-traveler approval is deferred to a future enhancement (#88), which would
  require revisiting the server-less model.

## Follow-on build slices (out of scope for this ADR; tracked under the coordination epic)

- Change-summary generator (before/after, privacy-bounded).
- Site "change pending / recently updated" state on open.
- Organizer-confirm → republish wiring (composes with #85).
- Individual-channel approval collection — the future v2 direction (#88).

## References

- Coordination epic (#77) and its design gate (#86).
- Living-site republish trigger (#85) and ADR-002 (privacy model + local build).
- Future direction: individual-channel approval collection (#88).
