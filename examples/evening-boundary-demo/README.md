# Evening-Boundary Demo — the three-way primary-draw split

**Illustrative, sanitized example. Not a real trip.** Placeholder people, a placeholder
destination, placeholder venues. No real bookings, no external links, no prices and no
opening hours.

A minimal worked example of the **three-way evening ownership boundary** that
`agents/07-nightlife.md` states and `agents/01-activities.md` mirrors: a venue in the
evening belongs to the spoke matching its **primary draw** — the reason to go — and is
**cross-referenced, never duplicated** by the other.

It exists because the boundary shipped with no compliant worked instance. The one
worked example the repository points readers to,
[`examples/tokyo-2026/`](../tokyo-2026/), routes its evening venues the other way, and
that fixture is a frozen regression witness that is not edited in place. So the
compliant instance is authored here instead — the move
`reference/data-architecture.md` § 10 names: *migration adds new fixtures that
instantiate the schema; it does not rewrite the witness.*

## What it shows

Six evening entries, split **2 Activities / 2 Food / 2 Nightlife**, plus the two
cross-spoke conditions in **opposite directions**:

- a venue whose primary draw **reassigns it from Food to Nightlife**, and
- a venue carried **once** under its primary draw and **cross-referenced** by the other
  spoke in prose rather than duplicated as a second entry.

## The six evening entries and their owners

Every entry is load-bearing; none is filler. The **Role** column is what makes the
allocation arithmetic visible rather than something a reader has to reconstruct — the
2/2/2 split and the two cross-spoke conditions are satisfied by the same six rows, not
by two independent allocations that happen to sum.

| # | Entry | Its stated draw | Owner | Fenced entry lives in | Role |
|---|---|---|---|---|---|
| 1 | Vico delle Lanterne — a stepped lane of ~40 two-table bars, almost no food | drinking, and the exploration itself | **Nightlife** | `outputs/nightlife-list.md` § *Alley Micro-Bars* | calibration referent — the alley verdict |
| 2 | Cantina del Molo — a cellar that pours by the glass and plates a little food | drinking | **Nightlife** | `outputs/nightlife-list.md` § *Cocktail & Wine Bars* | **reassigned Food → Nightlife**; named in prose, unfenced, by `outputs/food-list.md` |
| 3 | Galleria dei Fornai — a grill taverna under an arcade, where the food comes to the table | a meal | **Food** | `outputs/food-list.md` § *Occasion Dinners* | calibration referent — the arches verdict; **and the cross-referenced venue**, named in prose, unfenced, by `outputs/nightlife-list.md` |
| 4 | Vicolo dei Cuoppi — a fried-snack stall lane with stools where you sit and eat | a meal | **Food** | `outputs/food-list.md` § *Casual / Convenience* | calibration referent — the stall-lane verdict |
| 5 | Belvedere del Faro — a floodlit waterfront belvedere, seen after dark | a sight | **Activities** | `outputs/activities-list.md` § *Evening & Mixed-Group Options* | calibration referent — the crossing verdict |
| 6 | Teatro di Cortile — an open-courtyard evening performance | a scheduled event that happens to occur after dark | **Activities** | `outputs/activities-list.md` § *Evening & Mixed-Group Options* | the **second limb** of the Activities rule, which is why a sight and a scheduled event are not the same verdict reached twice |

Rows 1, 3, 4 and 5 are the four referents `agents/07-nightlife.md`'s ownership
calibration table needs. **That table is anonymized** — it describes its venues and
names none — so the coupling is semantic: each of its four verdicts (Nightlife / Food /
Food / Activities) resolves to exactly one row above. **Stated draw alone does not get
there.** The *Its stated draw* column is written in that table's own vocabulary, and it
settles the Nightlife verdict and the Activities verdict; but both **Food** verdicts read
*a meal* and tie rows 3 and 4, and *Owner* ties them too. The *Role* column separates
them — it labels each of the four with a token from that table's own description (*the
alley / arches / stall-lane / crossing verdict*) — and *Role* is the column that
**governs**. The *Entry* description separates the same two independently and corroborates
rather than competes. Both routes are stated so the resolution is checkable by a reader
rather than asserted here.

Row 6 exists because `agents/07-nightlife.md` rule 3 hands Activities **two** limbs — *a
sight, a view,* **or** *a scheduled event that happens to occur after dark* — and a
fixture carrying only the first would leave the second undemonstrated while still
reading as 2 Activities.

## Why the fence discipline is the thing to read, and what does not read it

Each of the six venues carries a fenced `artifact-entry` block in **exactly one** list.
A cross-reference is **prose with no fence**, because a fence would make it a second
*entry* for one venue — the duplication the boundary forbids. That is what makes
*cross-referenced, never duplicated* structurally true here rather than merely stated.

**No CI check reads it.** `scripts/validate-artifacts.sh` emits no entry-marker finding
code — `reference/schemas/food-list.md` says so in terms: *"Declared here, validated by
nothing in this release."* And group `VI` in `scripts/test-artifact-schema.sh` binds on
`venue: ven-<token>`; every marker in this fixture declares `venue: unminted`, which that
pattern does not match, so `VI` contributes **no verdict about this fixture in either
direction**. Stated plainly, so a green check on this commit is not mistaken for
conformance to the rule this fixture exists to show.

## Internal consistency (E1–E4)

**These are this fixture's real acceptance criteria, and no CI check can reach them.**
The schema gate validates frontmatter; it never reads a body. They are asserted here so
a later editor knows what to preserve, and so a reader has something to grade instead of
a check that cannot discriminate.

| # | Invariant | How it is checked |
|---|---|---|
| E1 | The six evening entries split **2 Activities / 2 Food / 2 Nightlife** by owner. | count the fenced `artifact-entry` blocks per file: 2 / 2 / 2 |
| E2 | Every one of the six venues carries an `artifact-entry` fence in **exactly one** list; its cross-reference in the other list is prose and carries **no fence**. | set difference over the fenced blocks and the prose mentions, both directions |
| E3 | Each of the four ownership verdicts in `agents/07-nightlife.md`'s calibration table resolves to **exactly one** row of the table above. | the four verdicts, read against the *Its stated draw* and *Owner* columns first — neither separates the two **Food** verdicts, which tie rows 3 and 4 — then against the *Role* column, which labels each of the four with a token from that table's own description of the venue and is the discriminator that **governs**. The *Entry* description separates the same two independently: a corroborating route, not a competing one, and where the two disagree *Role* governs, because it states the binding rather than inferring it. |
| E4 | Every file carries its writer's **full declared section set**, under the writer's own names, with a stated *not exercised* where this fixture has no fact. | three files, read against each agent prompt's `## Output Format` |

E2 is the one a schema gate structurally cannot reach, and it is also the one this
fixture exists for. That is why this list is prose here rather than a script somewhere:
writing it as a script would imply the script runs.

## Depth

**Deliberately minimal, on a declared rule rather than by accident.** This fixture
demonstrates a **spoke-side ownership rule** — a decision each research spoke makes
before the hub enumerates anything — so it ships the three research lists and nothing
downstream of them.

Absent on purpose, and named rather than left to be inferred from a missing file:

- **No itinerary, no `outputs/links-reference.md`, no `outputs/venue-matrix.md`, no
  `outputs/event-status.md`, no `outputs/validation-report.md`.** Every one of those is
  written by the hub or the validator, both of which run *after* the ownership decision
  this fixture is about. `examples/data-architecture-demo/` is the worked example for
  the hub's shape; this one is the worked example for the boundary that precedes it.
- **No `trip-context.md`, no `travelers/`, no `outputs/traveler-model.md`** — the inputs
  each spoke prompt reads before it researches. They are absent because nothing in the
  boundary depends on them: the primary-draw rule reads the **venue**, never the
  traveller. A reader should therefore take the six entries as the output of a research
  pass whose inputs are out of frame, not as a pass that ran without them. The one place
  the inputs would bite is the nightlife desire gate, so `outputs/nightlife-list.md`
  states its gate resolution in prose rather than leaving it to be inferred.
- **Every marker reads `venue: unminted`.** The token is minted by the hub at its first
  enumeration of the venue set, which is downstream of all three writers here, and this
  fixture runs no hub. `unminted` is a **declared absence, never a default value**
  (`reference/data-architecture.md` § 4.5 rule 3).
- **No prices, no opening hours, no addresses, no external links, no real bookings.**
  Labels the prompts require but this fixture has no fact for carry a stated
  *not exercised* rather than an invented value. **Depth governs content, not the
  writer's declared section set** — every file carries all of its writer's sections,
  under the writer's own names, thin where there is nothing to put in one.

## Relation to `examples/tokyo-2026/`

The Tokyo example predates this boundary. Its `outputs/activities-list.md` carries an
`## Evening / Nightlife (Mixed Group)` section holding six entries, all under Activities;
under the shipped rule those six split across the three spokes, and two of its venues are
claimed by both the activities and the food lists. **That example is not corrected in
place.** It is a byte-identical regression witness, pinned by content address in
`reference/data-architecture.md` § 10 and asserted on every push, so the compliant
instance is authored here and the repository-root [`README.md`](../../README.md) points a
reader from one to the other.

## Files

- [`outputs/activities-list.md`](outputs/activities-list.md) — C5. Entries 5 and 6.
- [`outputs/food-list.md`](outputs/food-list.md) — C6. Entries 3 and 4, plus the prose
  mention of entry 2. This is also class C6's declared **witness**: before it, the only
  tracked `food-list.md` in the repository was the one inside the frozen Tokyo tree.
- [`outputs/nightlife-list.md`](outputs/nightlife-list.md) — C7. Entries 1 and 2, plus
  the prose cross-reference to entry 3.

Destination: Naples, Italy — chosen because no other fixture uses it, and because all
four calibration referents exist there natively as venue *types*.
