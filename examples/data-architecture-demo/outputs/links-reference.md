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
marker — the same form C11 and C13 use.

**Where the keys come from, stated in the direction the decision fixed.** The hub
mints `ven-<token>` at **its first enumeration of the venue set — before it writes
either reference file** (`agents/05-hub-planner.md` § *Pre-Work: Build Reference
Artifacts First*). Pre-Work writes **this file first** and `outputs/venue-matrix.md`
second, so this file **receives** its keys from that enumeration rather than reading
them from the matrix. The mint point is fixed against the enumeration and not against
an artifact for exactly this reason: minting at the matrix would leave the link
file — the one-URL-per-venue SSOT that `reference/adr/ADR-005-location-invariant.md`'s
location invariant resolves against — keyless at the moment it is written.

| Venue key | Venue | Appears as | Day |
|-----------|-------|-----------|-----|
| `ven-7b2e` | Livraria Lello | `EV-3f9a` | May 14 (Thu) |
| `ven-c41a` | Jardins do Palácio de Cristal | `EV-8c21` | May 14 (Thu) |
| `ven-3c17` | Tasca do Bairro | `EV-7a05` | May 14 (Thu) |
| `ven-2f68` | Mercado do Bolhão | `EV-1d60` | May 15 (Fri) |
| `ven-93d7` | Serralves | `EV-b47e` | May 15 (Fri) |
| `ven-a90d` | Casa de Pasto Central | `EV-6e2b` | May 16 (Sat) |
| `ven-e05b` | Miradouro da Vitória | `EV-c052` | May 16 (Sat) |
| `ven-8a34` | Base Porto | `EV-5ab8` | May 16 (Sat) |
| `ven-1d9f` | Casa do Livro | `EV-9e34` | May 16 (Sat) — alternative |
| `ven-5e6b` | Padaria São Bento | `EV-d1c8` | May 17 (Sun) |
| `ven-6c72` | Ribeira riverside | `EV-2f77` | May 17 (Sun) |
| `ven-b5e0` | Café Majestic | *(bailout — no event)* | May 14 (Thu), May 16 (Sat) |

**Twelve rows, twelve distinct keys, twelve distinct display names** — one row per
venue and one key per row, matching `outputs/venue-matrix.md` row for row. The two
files are rebuilt in the same pass from the same placement set, so a disagreement
between them would mean one of the two was stale.

**This file is the venue registry**, so a `ven-<token>` appearing anywhere else — in a
research list's `artifact-entry` fence, in the matrix, in the itinerary — and *not*
resolving to a row here is the referencing-key-without-a-row condition. Every key used
anywhere in this fixture appears above.

**Three of these venues carry a registry row while their research markers still read
`unminted`.** `ven-3c17`, `ven-a90d` and `ven-5e6b` were enumerated and minted at this
pass; the entries that researched them are in the second dated section of
`outputs/activities-list.md` and resolve on that spoke's next run. That is not a
disagreement between the two files — it is the mint window
`reference/data-architecture.md` § 3.3 describes, seen from the side that already has
the keys. **It is also why the key is not the join basis:** the hub reached those three
places through its five-rung identity procedure, from mentions that carried no token.

`ven-b5e0` carries no Event ID because it is never placed: it is the standing bailout,
reached only if a block is rained or heated off. A registry row without an event is
the correct shape for that, and inventing an event to fill the cell would put a
placement in the plan that the plan does not make.
