---
artifact: outputs/links-reference.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: bound
generated: 2026-08-29
---

# Links Reference

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 2 — the migrated-shape minimum.** A real links-reference carries a map
link and an official URL per venue. **This fixture deliberately carries no external
URLs at all**, because a tracked worked example that shipped live links would acquire
a maintenance surface that rots without any check noticing.
`examples/tokyo-2026/outputs/links-reference.md` is the worked example for the full
shape. The **structure** — one row per venue, one key per row — is reproduced exactly,
because that is what the registry invariant is about. See `README.md` § *Depth*.

**`rebuilt-each-synthesis`, and built *before* the day-by-day itinerary** — together
with `outputs/venue-matrix.md`, which is what makes the deduplication rule checkable
ahead of the first day being written rather than after.

**Entry marker: a declared key column.** C10 is table-shaped, so `Venue key` is the
marker — the same form C11 and C13 use. The keys are **read** from
`outputs/venue-matrix.md`, never minted here; the hub mints them once, when it builds
the matrix.

| Venue key | Venue | Appears as | Day |
|-----------|-------|-----------|-----|
| `ven-7b2e` | Livraria Lello | `EV-3f9a` | May 14 (Thu) |
| `ven-c41a` | Jardins do Palácio de Cristal | `EV-8c21` | May 14 (Thu) |
| `ven-2f68` | Mercado do Bolhão | `EV-1d60` | May 15 (Fri) |
| `ven-93d7` | Serralves | `EV-b47e` | May 15 (Fri) |
| `ven-e05b` | Miradouro da Vitória | `EV-c052` | May 16 (Sat) |
| `ven-8a34` | Base Porto | `EV-5ab8` | May 16 (Sat) |
| `ven-1d9f` | Casa do Livro | `EV-9e34` | May 16 (Sat) — alternative |
| `ven-6c72` | Ribeira riverside | `EV-2f77` | May 17 (Sun) |
| `ven-b5e0` | Café Majestic | *(alternative — no event)* | May 14 (Thu), May 16 (Sat) |

**Nine rows, nine distinct keys, nine distinct display names** — one row per venue and
one key per row, matching `outputs/venue-matrix.md` row for row. The two files are
rebuilt in the same pass from the same placement set, so a disagreement between them
would mean one of the two was stale.

**This file is the venue registry**, so a `ven-<token>` appearing anywhere else — in a
research list's `artifact-entry` fence, in the matrix, in the itinerary — and *not*
resolving to a row here is the referencing-key-without-a-row condition. Every key used
anywhere in this fixture appears above.

`ven-b5e0` carries no Event ID because it is never placed: it is the standing bailout,
reached only if a block is rained or heated off. A registry row without an event is
the correct shape for that, and inventing an event to fill the cell would put a
placement in the plan that the plan does not make.
