---
artifact: outputs/venue-matrix.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: bound
generated: 2026-08-29
---

# Venue Matrix

> **Illustrative, sanitized example. Not a real trip.**

Built by the hub **before** the day-by-day itinerary, not after. Its job is to make
the deduplication rule checkable before any day is written.

**The rule:** no venue appears as an anchor on one day and an alternative on
another, and no venue exceeds **2 appearances** in total.

| Venue | Day(s) | Role(s) | Appearances |
|-------|--------|---------|-------------|
| Livraria Lello | May 14 (Thu) | anchor | 1 |
| Jardins do Palácio de Cristal | May 14 (Thu) | anchor | 1 |
| Serralves | May 15 (Fri) | anchor | 1 |
| Mercado do Bolhão | May 15 (Fri) | anchor | 1 |
| Miradouro da Vitória | May 16 (Sat) | anchor | 1 |
| Base Porto | May 16 (Sat) | anchor | 1 |
| Casa do Livro | May 16 (Sat) | alternative | 1 |
| Ribeira riverside | May 17 (Sun) | anchor | 1 |
| Café Majestic | May 14 (Thu), May 16 (Sat) | alternative, alternative | **2** |

**Café Majestic is the row that exercises the rule rather than merely obeying it.**
It appears twice, which is the cap and not a violation, and it holds the **same**
role both times. The forbidden shape is not "twice" — it is anchor on one day and
alternative on another, which would quietly demote a venue the plan had already
promised. Every other venue here sits at one appearance, so without this row the
matrix would be consistent with a rule that simply said "never repeat a venue", and
would not distinguish that rule from the one the engine actually applies.

**Bailout coverage.** `HC-2` requires any outdoor block that would sit in direct sun
between 13:00 and 16:00 to carry a named indoor bailout. Café Majestic is the
bailout for both such blocks, which is why it is the venue that reaches the cap.
