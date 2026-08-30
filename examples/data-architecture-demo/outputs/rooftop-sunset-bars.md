---
artifact: outputs/<slug>.md
schema-version: 1
trip: data-architecture-demo
writer: nightlife
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Targeted Research — Rooftop Sunset Bars

> **Illustrative, sanitized example. Not a real trip.**

**This file is an instance of the residual class C18, and its `artifact:` value is
the literal class string `outputs/<slug>.md`** — not `outputs/rooftop-sunset-bars.md`.
The angle-bracketed segment is part of the class name as
`reference/data-architecture.md` § 1.1 spells it, exactly as C16 is
`outputs/final-itinerary-v<N>.md` and C3 is `travelers/<traveler>.md`. Writing the
instance path there instead would be finding `A5`.

**Why this file resolves to C18 and not to something narrower.** Two declared
patterns could match it — C18's `examples/*/outputs/*.md`, and nothing else — and the
selector ranks matches by **literal length, longest wins**. That is what lets C18 ship
as a genuine residual class without stealing `venue-matrix.md` or `event-status.md`
from the named classes whose patterns are longer literals, and it needs no precedence
list to maintain. A file named for a topic rather than for a class lands here by
construction, which is exactly what this directory demonstrates: it holds thirteen
`outputs/*.md` files and only this one reaches C18.

## Targeted research — rooftop options for the shared sunset desire (2026-08-28)

Produced by the spoke that re-ran — nightlife — on the first pass, and appended rather
than overwriting, per the `accumulate-append` lifecycle this class carries. The desire
is held by both travellers (`outputs/traveler-model.md` § *Desire overlap*), so one
placement serves two rows of desire-coverage.

**Two of the three markers below have resolved and one never will.** All three were
born `venue: unminted` on the pass that wrote them, because a spoke runs before the hub
enumerates. The nightlife spoke's next pass (2026-08-29) resolved the two whose venues
the hub had by then minted — which is why `generated:` carries the later date while the
section header carries the earlier one. The third is the case below.

### Base Porto

```artifact-entry
venue: ven-8a34
```

Carried forward into `outputs/nightlife-list.md` and placed by the hub. **The key here
is the token the hub minted at its enumeration**, resolved into this marker by this
file's own writer on its next pass. A research list **reads** venue keys and never mints
them.

### Casa do Livro

```artifact-entry
venue: ven-1d9f
```

Carried forward as the alternative, and resolved the same way on the same pass.

### A third candidate, considered and not carried forward

```artifact-entry
venue: unminted
```

**This is the degenerate case, and it is here deliberately.** A candidate this spoke
looked at and did not carry forward is **not in the venue set the hub enumerates**, so
the hub never mints a token for it — and the marker declares `venue: unminted` rather
than being omitted, carrying an empty value, or inventing a token.

**The rationale is enumeration, not the matrix.** The mint point is the hub's **first
enumeration of the venue set, before it writes either reference file**
(`reference/data-architecture.md` § 3.3) — so what decides whether a token exists is
whether the venue is in that enumeration, not whether it reaches
`outputs/venue-matrix.md`. The matrix is written second and carries keys that already
exist; a candidate absent from the enumeration is absent from both reference files, and
absent from the mint.

**This marker is `unminted` permanently, and that is a recorded disposition rather than
a defect.** `unminted` is a **converging** state, not an instantaneous one — a marker
converges on the pass after the hub mints its venue's key. This one has no key to
converge on and never will, because nothing carried the venue forward. The other two
markers above show the converging case in its resolved end state; the second dated
section of `outputs/activities-list.md` shows it mid-flight.

**The validator counts a still-`unminted` mention as its own venue**
(`agents/06-validator.md` § *What You Audit*), so the two-appearance cap **over-counts**
rather than passing silently on a merge nobody made. That asymmetry is deliberate: a
wrong merge hides a cap violation invisibly, while a wrong split is visible. This entry
is one such mention, and it costs the cap nothing here because no venue in this plan is
near it.

**A declared absence is not a default.** `venue: unminted` says the entity exists and
its key does not — a different fact from *there is no entity here*, the case the
*Live fado* entry in `outputs/nightlife-list.md` shows by carrying **no block at all**.
An omitted marker and an `unminted` one are not interchangeable, and a fixture that
showed only one of them would leave a reader to guess which shape the other case takes.

Detail on the candidates is deliberately thin — see `README.md` § *Depth*.
