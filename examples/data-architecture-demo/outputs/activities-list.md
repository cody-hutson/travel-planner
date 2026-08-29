---
artifact: outputs/activities-list.md
schema-version: 1
trip: data-architecture-demo
writer: activities
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Activities List — Porto

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**Depth: tier 2 — the migrated-shape minimum.** `examples/tokyo-2026/outputs/activities-list.md`
is the worked example for this class's *content*; this file exists to carry the
migrated frontmatter and to stay consistent with the rest of this fixture. See
`README.md` § *Depth*.

## Initial Research (2026-08-29)

| Venue | Placed as | Booking | Access (`HC-1`) | Shade (`HC-2`) |
|---|---|---|---|---|
| Livraria Lello | `EV-3f9a` | advance | level | indoor |
| Jardins do Palácio de Cristal | `EV-8c21` | open | level paths | shaded, and after 16:00 |
| Serralves | `EV-b47e` | advance | lift | indoor |
| Mercado do Bolhão | `EV-1d60` | walk-up | level | covered |
| Miradouro da Vitória | `EV-c052` | open | level approach | after 16:00 |
| Ribeira riverside | `EV-2f77` | open | level | morning |
| Café Majestic | *(alternative)* | walk-up | level | indoor — the `HC-2` bailout |

Every row clears `HC-1`, which is a constraint on **routing**, not on venue choice —
a stepped approach would have excluded a venue this list could otherwise carry.
