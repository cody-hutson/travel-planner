---
artifact: outputs/cost-estimate.md
schema-version: 1
trip: data-architecture-demo
writer: hub
lifecycle: rebuilt-each-synthesis
provenance: derived
publish: internal
generated: 2026-08-29
cost-bearing-items: 17
priced-items: 0
coverage: measured
---

# Cost Estimate

> **Illustrative, sanitized example. Not a real trip.**

**Depth: tier 1 — no tracked instance of this class existed anywhere before this
fixture.** See `README.md` § *Depth*. What it exercises is not a populated estimate
but the opposite: this is the **degenerate instance**, in `reference/data-architecture.md`
§ 4.5 rule 3's own sense — every field label the class carries is present, with
declared-absent values, so a consumer reads *unknown* rather than inferring from a
missing label.

**Why the degenerate case is the one worth witnessing here.** This fixture ships no
prices, by its own § *Depth* rule — "no external URLs, no opening hours, no prices,
no real bookings and a placeholder destination". That is not a limitation being worked
around; it is the exact state the class's hardest branch describes, and it is the
branch a populated fixture could not show. `reference/schemas/cost-estimate.md`
§ *The rendering rule* names it: **`N = 0` ⇒ `undetermined`, never a total of zero.**

## Coverage

**17 of the entries in this trip carried no readable cost signal — `priced-items: 0`
against `cost-bearing-items: 17`.**

| Class | Entries | Priced | Why |
|---|---|---|---|
| C5 `outputs/activities-list.md` | 10 | 0 | This fixture's entries carry no money label at all; `agents/01-activities.md` § *Output Format* declares none |
| C6 `outputs/food-list.md` | 0 | 0 | **Absent from this fixture** by the § *Depth* rule; its witness is `examples/evening-boundary-demo/`, whose two entries declare `**Price range:** *not exercised*` |
| C7 `outputs/nightlife-list.md` | 2 | 0 | `**Price range:**` declared by `agents/07-nightlife.md`, unpopulated here |
| C9 `outputs/transport-brief.md` | 2 | 0 | `**Cost:**` declared by `agents/04-transport.md`, unpopulated here |
| C18 `outputs/rooftop-sunset-bars.md` | 3 | 0 | The residual class; none of its three candidates carries a money label |

**The denominator is computed, not counted by hand.** `reference/data-architecture.md`
§ 4.5.1 fixes it: M ranges over the entries of every class whose § 1.1 Primary-entities
cell names `Venue` or `Leg`. C8 `outputs/scheduling-framework.md` is excluded by that
rule — its six day entries are Days, and a Day has no purchase — which is why its
markers are absent from the table above rather than listed with a zero.

**An entry is a marker, and this fixture already fixes what that means.** M counts
`artifact-entry` blocks, not `###` headings — the same rule `agents/06-validator.md`
§ *Marker coverage* applies to its own `T`. `outputs/nightlife-list.md` carries three
headings and two markers: its *Live fado* section is a want recorded as uncovered and
declares in terms that it carries no block *because there is no entity to key*. A
non-entity is not an item this trip could pay for, so the count that already excludes it
is the right one — and the two counts differing here is what makes the choice visible
rather than incidental.

**`coverage: measured` is the load-bearing field on this instance, and the other value
would have been wrong.** Every entry-bearing file in this trip carries markers, so M is
a real count and `priced-items: 0` is a **measurement** — nothing here was priced. The
other branch, `unverifiable`, is for a file that presents entries and no markers at all,
where `0` would assert an empty class over a failed read. **`examples/tokyo-2026/` is
that case**: its 42 `**Price:**` entries carry no markers, it predates the migration, and
§ 10 pins it — so an estimate over *that* trip would read `unverifiable` and this one
reads `measured`. Both render `undetermined`; they are not the same finding, and the
field is what keeps them apart.

**No entry in this fixture carries a `cost:` line in its marker**, and under § 4.5.1
that is the field being **optional** rather than an absence being declared. `cost:
undetermined` would say *this writer looked and found nothing normalizable*; no line at
all says *this writer does not yet emit cost*, which is the true state — no agent prompt
emits the field on this commit.

## Estimate

**Total: `undetermined`.**

**Per traveler: `undetermined` for all three.**

| Traveler | Estimate | Basis |
|---|---|---|
| Alex | `undetermined` | 0 of 17 cost-bearing items readable |
| Robin | `undetermined` | 0 of 17 cost-bearing items readable |
| Sam | `undetermined` | 0 of 17 cost-bearing items readable |

**`undetermined` is not zero, and the difference is the reason this artifact exists.**
A total of `0` would say this trip costs nothing. What is true is that nothing was
readable. `reference/data-architecture.md` § 5.4 protects that distinction at the
publish guard — *a parsed-and-empty class must stay distinguishable from a class that
could not be computed* — and this row is the same distinction one layer up.

**The roster names above are the whole of what this artifact takes from any
per-traveler source.** The derivation bound in `reference/schemas/cost-estimate.md`
admits a `## Group` roster name and a money figure and nothing else; **no value is
copied out of a `[THIRD-PARTY]` entry** in any form. Sam is this fixture's
operator-provided roster member and appears here by name only, with no need, no desire
and no justification string beside the figure — which is what keeps this class
`publish: internal` rather than tripping the `internal-hard` escalation that schema
declares.
