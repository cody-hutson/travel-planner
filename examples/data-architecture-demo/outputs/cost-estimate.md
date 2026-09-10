---
artifact: outputs/cost-estimate.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal
generated: 2026-09-10
cost-bearing-items: 17
priced-items: 11
coverage: measured
---

# Cost Estimate

> **Illustrative, sanitized example. Not a real trip.** Every currency value below is
> **synthetic** — see `README.md` § *Depth*.

**Depth: tier 1 — no tracked instance of this class existed anywhere before this
fixture.** What it exercises is the **`0 < N < M` limb**: a total rendered together with
its own coverage caveat, never presented as complete. That is the limb where a total and
a caveat must appear side by side, so it exercises strictly more of the rendering rule
than the others, and it is the shipping behaviour of any real trip.

**This instance used to witness the `N = 0` limb**, and the change is deliberate rather
than a loss. `README.md` § *Depth* narrows its no-prices clause to *no **sourced**
prices — synthetic currency values only, where a class's own rule cannot be exercised
without one*, which is what lets the entry-bearing files here carry money at all.
`reference/schemas/cost-estimate.md` records which limbs stay unwitnessed and why.

## Coverage

**`priced-items: 11` against `cost-bearing-items: 17`** — the per-class table below sums
to both, so neither number is asserted here without a basis beside it: the markers are
10 + 2 + 2 + 3 = 17, and those carrying a readable cost signal are 7 + 1 + 2 + 1 = 11.

| Class | Entries | Priced | Why |
|---|---|---|---|
| C5 `outputs/activities-list.md` | 10 | 7 | `**Entry cost:**` on every entry. The three anchor meals declare `cost: undetermined` — an anchor meal has no admission, and its money value is C6's `**Price:**` master |
| C6 `outputs/food-list.md` | 0 | 0 | **Absent from this fixture** by the § *Depth* rule; its witness is `examples/evening-boundary-demo/` |
| C7 `outputs/nightlife-list.md` | 2 | 1 | `**Price range:**` declared on both. One carries a range, the other a tier holding no numeral and therefore `cost: undetermined` |
| C9 `outputs/transport-brief.md` | 2 | 2 | Both streams priced. The arrival marker is `per-person` and the departure marker is `group-total`, read off which bases each label states |
| C18 `outputs/rooftop-sunset-bars.md` | 3 | 1 | The residual class. The carried-forward rooftop is priced; the alternative and the never-carried candidate declare `undetermined` |

**The denominator is computed, not counted by hand.** `reference/data-architecture.md`
§ 4.5.1 fixes it: M ranges over the entries of every class whose § 1.1 Primary-entities
cell names `Venue` or `Leg`. C8 `outputs/scheduling-framework.md` is excluded by that
rule — its six day entries are Days, and a Day has no purchase — which is why its
markers are absent from the table above rather than listed with a zero. Its markers
correctly carry **no `cost:` line at all**, which from this release is the shape that
means *this writer does not yet emit cost*, and `agents/03-scheduling.md` records that
as a stated non-use rather than a deferral.

**An entry is a marker, and this fixture already fixes what that means.** M counts
`artifact-entry` blocks, not `###` headings — the same rule `agents/06-validator.md`
§ *Marker coverage* applies to its own `T`. `outputs/nightlife-list.md` carries three
headings and two markers: its *Live fado* section is a want recorded as uncovered and
declares in terms that it carries no block *because there is no entity to key*.

**This pair measures the corpus, and the per-traveller pair below measures a plan.
Neither is inferred from the other.** `cost-bearing-items` / `priced-items` is
**placement-blind**: it asks how much of this trip's cost-bearing research was made
machine-readable, whether or not any of it was placed. `P of Q` in the per-traveller
table asks how much of **one traveller's own plan** was readable. The two disagree here,
and the disagreement is real rather than an artefact:

- `ven-b5e0` Café Majestic is **priced and charged to nobody** — the standing bailout,
  which `outputs/event-status.md` records as never placed and holding no event.
- `ven-8a34` Base Porto is **counted twice and charged once** — it carries a marker in
  `outputs/nightlife-list.md` and another in `outputs/rooftop-sunset-bars.md`, two
  mentions of one venue, and the traveller is charged for the **placement**, which
  `outputs/venue-matrix.md` holds once.

**`coverage: measured` is the load-bearing field on this instance, and the other value
would have been wrong.** Every entry-bearing file in this trip carries markers, so M is a
real count. The other branch, `unverifiable`, is for a file that presents entries and no
markers at all, where `0` would assert an empty class over a failed read.
**`examples/tokyo-2026/` is that case** — its priced entries carry no markers, it predates
the migration, and § 10 pins it — so an estimate over *that* trip would read
`unverifiable`. This one reads `measured`, and the field is what keeps them apart.

## Estimate

**Total: €270 – €300** for the party (≈ $297 – $330 at the €1 ≈ $1.10 rate
`trip-context.md` § *Destination Baseline* declares).

**The total is a range and not a figure**, because § 4.5.1 fixes the marker's `amount`
as a **low bound**: the floor is summed from the markers, and the ceiling is read from
each priced entry's own prose money line. Two entries carry a range on this trip, and the
€30 of spread above the floor is split between them rather than owed to either:
`ven-93d7` Serralves runs €20–24 and supplies €12 of it, and `ven-8a34` Base Porto runs
€12–18 and supplies the larger €18. Every other priced entry carries a point value, so it
contributes to the floor and nothing above it. The split is checkable without leaving this
file: the category table below runs Activities / admission €84 → €96 and Nightlife
€36 → €54, and an €18 spread cannot originate in an Activities entry.

| Traveler | Committed | On-the-ground | Estimate | Coverage | Basis |
|----------|-----------|---------------|----------|----------|-------|
| Alex | €20 – €26 | €20 – €24 | **€90 – €100** | 9 of 12 | All 4 days; the two legs sit outside C13 and are added flat |
| Robin | €20 – €26 | €20 – €24 | **€90 – €100** | 9 of 12 | as above |
| Sam | €20 – €26 | €20 – €24 | **€90 – €100** | 9 of 12 | as above; roster name only, no profile read |

**Why the rows are identical, and why that is a measurement rather than a shortcut.**
Presence is **read** from `trip-context.md` § *Per-Traveler Planning Days [DERIVED]* and
never re-derived here. That block gives every traveller the same window, `May 14–17`; the
roster block records no subgroup note; and the party moves together — so the charged item
set is the same for each. On a trip where those windows diverged the rows would too, and
`examples/two-origin-demo/` is the shape where they do.

**`9 of 12` is each traveller's own pair, and it is not the frontmatter pair.** `Q` is
that traveller's cost-bearing **placed** items — ten events plus two legs — and `P` is
those whose marker carries a readable cost. The three that do not are the anchor meals.
Without a per-traveller denominator, a per-traveller `undetermined` would be
indistinguishable from a per-traveller zero.

| Category | Floor | Ceiling | Priced items | Basis |
|---|---|---|---|---|
| Transport | €150 | €150 | 2 | One `per-person` marker charged to each of three travellers, plus one `group-total` divided across the three passengers its stream names |
| Activities / admission | €84 | €96 | 6 | `per-person` × 3. Four of the six are `free`, which is a **value** contributing `0` and not an absence |
| Nightlife | €36 | €54 | 1 | `per-person` × 3 |
| Food | `undetermined` | `undetermined` | 0 | All three anchor meals carry `cost: undetermined`. **Not `0`** — this trip's food is not free, it is unread |

**The `unallocated` line is empty on this trip, and it is declared rather than passed
over.** The one `group-total` here is the departure leg, whose `**Passengers:**` line
names its own participant set, so it divides. Had that set not been resolvable the figure
would **not** have been divided by the roster — it would appear on a named
`unallocated group-total` line instead, and no traveller's estimate would carry it.

**Excluded: `evt-9e34` Casa do Livro, the Saturday `option`.** An `option` is never a
primary placement, so it is outside every traveller's charged set. It is named here
rather than dropped silently, and it carries `cost: undetermined` in both of its markers
in any case.

## Commitment split

**Committed: €20 – €26 per traveller** — from the two `outputs/event-status.md` rows
reading `locked`: `evt-3f9a` Livraria Lello and `evt-5ab8` Base Porto.

**On-the-ground: €20 – €24 per traveller** — the `firmed` and `planned` rows.
`evt-1d60` Mercado do Bolhão is the `firmed` one, and it sits here rather than under
*Committed*: group-settled is not booked.

**A committed item may still be paid at the venue; this split records what is booked,
not what is paid.** Both `locked` rows on this trip are exactly those cases — *Timed
entry held* is a purchase already made, and *Table held* is a reservation payable on the
night. `outputs/event-status.md` cannot tell them apart because C13 records commitment
and holds no payment state, so a split labelled *prepaid* would over-claim on a row of
its own.

**€50 per traveller sits outside this split, and naming it is the honest reading.** The
two flights are **Leg** entities; C13 keys **Events**. A leg therefore carries no C13
status at all, so it can be neither committed nor on-the-ground under a partition drawn
from that file. The two limbs above sum to €40 – €50 and the traveller's estimate is
€90 – €100; the difference is the transport, added flat and accounted for here rather
than folded into a limb it does not belong to.

## Pre-trip recommendation

**Budget** ≈ **€90 – €100** per traveller (≈ $99 – $110).

**Preload** ≈ **€4** per traveller on the rechargeable city transit card
`outputs/transport-brief.md` § *Payment & Transit Card Setup* names. That is the
apportioned figure from § *Pass Assessment*, whose verdict is **no pass**: two journeys
at €2 against an €18 card. Where a verdict recommended the pass, this line would carry
the card price instead.

**Carry** — **`undetermined`** in cash, and the condition is this: the cash-preferred
contexts `trip-context.md` § *Destination Baseline* names are the market-hall stalls and
small counter orders, and every entry this trip places in those contexts is one of the
three anchor meals carrying `cost: undetermined`. There is no readable spend to size an
allowance from, and there is no default cash figure to fall back on.

**Unpriced remainder: 3 of each traveller's 12 charged items.** It is reported in **item
count** and never converted to a currency amount — a money figure standing in for
something nobody read would be invention with a decimal point on it. This is the
contingency driver: the €90 – €100 above is a floor-and-ceiling over what *was* readable.

**Comparison, and not a source: `trip-context.md` § *Budget Posture* declares an overall
tier of *mid*, meals *comfortable rather than cheap*, and one paid museum expected.**
Nothing above is derived from that block and none of it is summed into any total. It is
declared **willingness** to spend; filling an unreadable item from it would hand the
operator their own number back as an estimate.

**Assumptions, one line each.**

- The USD projections use the €1 ≈ $1.10 rate the trip declares, which is synthetic on
  this fixture. Where no rate were declared, no projection would be rendered at all.
- Preload covers the legs this brief prices and the pass model. § *Point-to-Point Transit
  Matrix* carries no entry marker and its rows carry no key, so unkeyed hops are not in
  the figure.
- The `group-total` departure leg divides equally across the three passengers its own
  stream names, not across the roster.
- The ceiling is read from prose money lines. It is **not machine-checkable**, and no
  file here asserts that a prose line and a marker agree.

**`undetermined` is not zero, and the difference is the reason this artifact exists.** A
food total of `0` would say the meals on this trip cost nothing. What is true is that
nothing priced them. `reference/data-architecture.md` § 5.4 protects that distinction at
the publish guard — *a parsed-and-empty class must stay distinguishable from a class that
could not be computed* — and every `undetermined` above is the same distinction one layer
up.

**The roster names above are the whole of what this artifact takes from any per-traveler
source.** The derivation bound in `reference/schemas/cost-estimate.md` admits a `## Group`
roster name and a money figure and nothing else; **no value is copied out of a
`[THIRD-PARTY]` entry** in any form. Sam is this fixture's operator-provided roster member
and appears here by name only, with no need, no desire and **no justification string
beside the figure** — which is what keeps this class `publish: internal` rather than
tripping the `internal-hard` escalation that schema declares.
