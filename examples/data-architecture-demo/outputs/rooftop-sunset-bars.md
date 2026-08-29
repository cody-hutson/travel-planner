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

## Targeted Update — rooftop options for the shared sunset desire (2026-08-29)

Produced by the spoke that re-ran — nightlife — and appended rather than overwriting,
per the `accumulate-append` lifecycle this class carries. The desire is held by both
travellers (`outputs/traveler-model.md` § *Desire overlap*), so one placement serves
two rows of desire-coverage.

### Base Porto

```artifact-entry
venue: ven-8a34
```

Carried forward into `outputs/nightlife-list.md` and placed by the hub as `EV-5ab8`.
The key is the same token the matrix minted; a research list **reads** venue keys and
never mints them.

### Casa do Livro

```artifact-entry
venue: ven-1d9f
```

Carried forward as the `option`, `EV-9e34`.

### A third candidate, considered and not carried forward

```artifact-entry
venue: unminted
```

**This is the degenerate case, and it is here deliberately.** A candidate this spoke
looked at and did not carry forward never reaches `outputs/venue-matrix.md`, so the
hub never mints a token for it — and the marker declares `venue: unminted` rather than
being omitted, carrying an empty value, or inventing a token.

That distinction is the whole point of the form. `unminted` is a **declared absence**,
never a default: it says the entity exists and its key does not yet, which is a
different fact from *there is no entity here* — the case the *Live fado* entry in
`outputs/nightlife-list.md` shows by carrying **no block at all**. An omitted marker
and an `unminted` one are not interchangeable, and a fixture that showed only one of
them would leave a reader to guess which shape the other case takes.

Detail on the candidates is deliberately thin — see `README.md` § *Depth*.
