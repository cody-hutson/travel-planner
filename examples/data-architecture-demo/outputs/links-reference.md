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
URLs at all**, because a tracked worked example that shipped live links would
acquire a maintenance surface that rots without any check noticing.
`examples/tokyo-2026/outputs/links-reference.md` is the worked example for the full
shape. See `README.md` § *Depth*.

**`rebuilt-each-synthesis`, and built *before* the day-by-day itinerary** — together
with `outputs/venue-matrix.md`, which is what makes the deduplication rule checkable
ahead of the first day being written rather than after.

| Venue | Appears as | Day |
|---|---|---|
| Livraria Lello | `EV-3f9a` | May 14 (Thu) |
| Jardins do Palácio de Cristal | `EV-8c21` | May 14 (Thu) |
| Mercado do Bolhão | `EV-1d60` | May 15 (Fri) |
| Serralves | `EV-b47e` | May 15 (Fri) |
| Miradouro da Vitória | `EV-c052` | May 16 (Sat) |
| Base Porto | `EV-5ab8` | May 16 (Sat) |
| Casa do Livro | `EV-9e34` | May 16 (Sat) — alternative |
| Ribeira riverside | `EV-2f77` | May 17 (Sun) |
| Café Majestic | *(alternative)* | May 14 (Thu), May 16 (Sat) |

Nine venues, matching `outputs/venue-matrix.md` row for row. The two files are
rebuilt in the same pass from the same placement set, so a disagreement between them
would mean one of the two was stale.
