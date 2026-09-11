# ADR-018: Cost estimation method — the commitment axis, the C13 read edge, and ADR-011's three deferred questions

- **Status:** Proposed (2026-09-10)
- **Deciders:** repo maintainer
- **Driving work:** the estimating slice of the per-traveler cost-estimation milestone — the work
  `reference/adr/ADR-011-per-traveler-cost-estimation.md` opened and handed forward.
- **What this record is.** ADR-011 fixed the **shape** a cost estimate is written in and said in terms
  that it specified no estimation **method**. This record is that method, plus one contract reading
  ADR-011 did not reach. It answers all three of the questions ADR-011 named as inherited, resolves
  the axis the estimate's commitment split is drawn on, and fixes where C21 reads a commitment signal
  from. **ADR-011 is not superseded** — no decision of its is reversed, narrowed or re-opened.
- **What this record is still not.** It states no scoring formula and no weighting.
  `reference/data-architecture.md` § 11 keeps metric formulas out of the model and this record does
  not relax that boundary either. Every rule below is a **read rule** — which surface a figure comes
  off, and what the writer does when that surface holds nothing.

## Context

ADR-011 shipped C21 `outputs/cost-estimate.md` as a declared class with a schema, a witness and a
coverage pair, and shipped it **unproduced**: the field grammar was admitted in the entry marker and
no prompt emitted it, so the one tracked estimate reads a real zero and renders `undetermined`. That
is the state the corpus has been in since, and it is the state this record ends.

Closing it needs four things ADR-011 deliberately did not supply, and one it did not see.

**The three it handed forward, in its own words:** how a `group-total` figure allocates across
travellers, whether a range's low bound is the right normalization once real ranges are read, and
whether a converted figure ever earns a home. Each is a method question, and each is answered below.

**The fourth is the money surface itself.** ADR-011 § Decision 4 admits the `cost:` field by marker
**form**, so C5 `outputs/activities-list.md` holds the grammar. But C5 declares no money label in its
entry surface — `reference/schemas/activities-list.md` says so in terms — while
`agents/01-activities.md` already **mandates researching price**: its filler-rigor clause requires
*"the same research depth as anchor activities: hours, day-of-week availability, price, walking
time"*, and its anchor/alternative clause requires alternatives to vary on *"price tier (budget /
mid / splurge)"*. A class that researches a price, admits the field, and has nowhere to write the
price down emits `undetermined` forever. C5 is also the largest contributor to the one tracked
denominator there is, so a permanently unpriced C5 makes the coverage ratio read poor on every run —
the same defect ADR-011 § Decision 4 excludes C8 to avoid, reached by a different route.

**The one it did not see is a contract reading, and the milestone framing had it backwards.** The
driving work carried a premise that on a first-synthesis pass the booked-versus-not split has **no
source**, because C13 `outputs/event-status.md` is a conditional input the hub reads only in
ITERATION and RESEQUENCING. That premise is false, and the hub's own prompt falsifies it: the hub is
the **primary writer** of C13 and *creates it if it does not yet exist*, seeding already-known
`locked` rows from `trip-context.md` § *Locked Elements* — a section whose own template examples are
*"confirmed reservation"* and *"tickets purchased"*. The commitment signal is not absent on a first
pass; it is **written by the same actor, in the same pass, minutes earlier**.

## Decision drivers

- **A method question is answered against a surface that already exists, or it is not answered.**
  Every rule below names the file and the section a figure is read from. Minting a new home for a
  rate, a norm, or a cash figure would put a second home under `reference/data-architecture.md`
  § 4.3's nose for values the trip context already declares.
- **`undetermined` is the answer when nothing was readable, and it must stay expensive to reach.**
  ADR-011 built the whole class around the parsed-and-empty versus could-not-be-computed distinction.
  A method that reaches `undetermined` over content the writer itself just produced inverts that
  distinction as surely as a total of `0` does — a false *could-not-be-computed* is exactly as wrong
  as a false zero, and for the identical reason.
- **A per-traveller figure must not acquire precision it did not measure.** Dividing a group price by
  the roster because the roster is the number to hand is invention wearing arithmetic's clothes. The
  refusal — a named unallocated line — is the load-bearing half of the allocation rule, not its
  fallback.
- **The estimate is `publish: internal` and stays there.** ADR-011 § Decision 6 draws the derivation
  bound and names the escalation that would move the class to `internal-hard`. A method is where that
  bound is either honoured or quietly crossed, so the bound is restated at the writer rather than
  left in a schema the writer does not read.
- **No roster, and no schema bump.** § 5.3's *computed, never enumerated* governs the denominator, and
  a method that added a frontmatter field would move the whole `SC`/`UF`/`CA`/`HC` assertion family
  for one derived reading.

## Options considered

Two of these are the branches the driving work framed for the C13 edge, and both are refused.

| Option | Why not |
|---|---|
| **Add C13 to the hub's unconditional required inputs** | Wrong shape, not merely costly. On DISCOVERY and ENRICHMENT that file is an **output of the pass**. The input list's own preamble reads *"Read all files fully before producing output. Do not begin pre-work until all inputs are read."* A hub required to read an input before pre-work, which creates that input during synthesis, holds a contract that cannot be satisfied on a first pass. **Rejected — see Decision 1.** |
| **Declare the committed limb degenerate on a first pass** | Its factual premise is false, as § Context measures. Rendering `undetermined` would declare *nothing was readable* over rows the hub wrote from § *Locked Elements* in the same pass. **Rejected — see Decision 1.** |
| **Render the split as prepaid versus not** | C13 has no payment state. A held restaurant table is `locked` and paid at the venue; a purchased timed entry is `locked` and paid in advance. Nothing in the corpus separates them, so the label would over-claim on every run. **Rejected — see Decision 2.** |
| **Leave C5 permanently unpriced and satisfy the money-surface requirement as a field label** | Satisfies the requirement structurally and not substantively — the category reads `undetermined` on every trip forever, and the coverage ratio reads poor forever with it. **Rejected — see Decision 9.** |
| **Read the prose money lines as the primary source, no marker** | ADR-011 rejected this and the rejection stands: a prose parser inside a data contract has **no key** to attach its answer to. What Decision 6 below does is different in kind — it reads the prose of an entry **already joined by its marker**, for the one thing only the prose holds. |
| **Build a second general fixture to witness a populated estimate** | C21 is the most downstream artifact in the engine. A fixture that witnesses a populated estimate needs a roster, per-traveller windows, a destination baseline, locked elements, entry-bearing outputs, a venue matrix, an itinerary and an event status — essentially a second copy of the general fixture, which `examples/data-architecture-demo/README.md` § *Depth* refuses in its opening sentence. **Rejected — see Decision 11.** |
| **Grade the new body rules with a validator finding code** | `scripts/validate-artifacts.sh` declares PROSE out of scope by name and its finding set is frontmatter-only. A body arm would cross a declared boundary and would need a must-fire arm running inside the synthetic tree, which is the coupling the guard suite's own header warns about. **Rejected — see Decision 12.** |

## Decision

### 1. C21's commitment source is the C13 state the hub already holds, under a declared write ordering

`outputs/cost-estimate.md` is written **after** `outputs/event-status.md` in every mode — after the
create-and-seed step on DISCOVERY and ENRICHMENT, after the read-and-update-in-place step on
ITERATION and RESEQUENCING. C21 therefore does not read C13 as an *input*; it reads the state its own
writer is holding, at a declared ordering point.

**The hub's input contract is unchanged.** No item is added to the unconditional list and the
conditional item keeps its wording. What is added is one ordering sentence, in the hub's own new
output section, where a writer reads it.

**The degenerate limb survives under its true condition.** The committed limb renders `undetermined`
only where the hub does not hold a readable C13, which is reachable in two states the corpus already
governs: the write-stop fired — an existing file declares a higher `schema-version`, the hub reports
and declines the write, and must not then assert a reading of it — or an existing file is
pre-migration and the tolerant read leaves it unresolved. **A C13 carrying no `locked` row is a
measurement**, not an absence: the limb renders a real zero and says so.

### 2. The axis is committed versus on-the-ground, never prepaid versus not

C13 records **commitment**, and the hub's own iteration text fixes the semantics: *"a newly booked
event → `locked`; a newly settled unbookable choice → `firmed`"*.

| C13 status | Limb | Why |
|---|---|---|
| `locked` | **committed** | The corpus's word for booked. |
| `firmed` | on-the-ground | Group-settled with nothing to book. Settled is not paid. |
| `planned` | on-the-ground | Not booked. |
| `option` | **excluded** | Never a primary placement. Named in the body as an excluded alternative pool, never silently dropped. |

**`locked` does not imply prepaid**, so one standing sentence travels with the split: *a committed
item may still be paid at the venue; this records what is booked, not what is paid.* A payment-state
signal does not exist anywhere in the corpus. Adding one is a schema change to a `persist-mutable`
class and is **out of scope here**, recorded in § *Follow-on build slices*.

### 3. Currency — a converted figure earns a home at the trip, and never at the marker

This is the direct answer to ADR-011's third inherited question, and the answer is **yes, at the
trip**.

`templates/trip-context.template.md` § *Destination Baseline* declares
`**Currency:** [Name, code, approximate USD rate — rate used for all agent cost estimates]`. That
clause is already a declared home for a rate, and it says what the rate is for.

- The primary total is in **local currency**, one total per distinct ISO 4217 code.
- A **USD projection** is rendered beside it **only where the trip declares a rate**, naming the rate
  and the date the baseline was enriched. Where no rate is declared the projection is **omitted**,
  never computed from an invented one.
- **No total is ever summed across currencies.**
- Preload and cash are local-currency only: a fare card is loaded in the local currency.

`reference/data-architecture.md` § 4.5.1's *never a conversion* binds the **marker**, and this
decision does not touch it. The marker keeps one normalized scalar in the currency the prose states.

### 4. A `group-total` allocates across the item's own participant set, and refuses otherwise

A `group-total` figure divides equally across the participant set of **that item**. Where the set is
not determinable, the entry is **not divided**: it lands on a named `unallocated group-total` line in
the body.

`agents/04-transport.md` writes `**Passengers:** [Travelers by their ## Group roster name]` on every
stream, and that line **is** the participant set. The prompt says why it must not be read as the
party: *"Two people landing at 06:00 from Manchester are not a group of six, and pricing them as one
is the error this section exists to prevent."* For the Venue classes the set is the party the plan
places at the item. A `per-person` figure needs no allocation at all.

**The refusal is the load-bearing half.** An undeterminable set is never divided by the roster as a
default — the same move `venue: unminted` makes, a declared absence rather than a default. Silent
division by the roster is how a per-traveller figure acquires precision nobody measured.

### 5. Presence is read, never re-derived

A traveller is charged for an item **iff** the plan places it inside that traveller's own derived
window and no subgroup note excludes them. The window is read from `trip-context.md`
§ *Per-Traveler Planning Days [DERIVED]* and is **not recomputed here**.

That block is already derived, already per-traveller, and already carries a warrant vocabulary; its
sibling § *Effective Planning Days* states the rule in terms — *"Anything that needs to know who is
present on a given day must read each traveler's own derived window … not this block."*

**This closes the arrival-day classification question by refusal rather than by adjudication.** The
estimate does not classify a partial arrival or departure day at all. Where the window's granularity
leaves a traveller's presence at an item undecidable, the item goes to the **unallocated** line and
is **named**. Under-determination becomes a visible row rather than a silent choice.

### 6. The range's floor comes from the marker, its ceiling from the prose master, and no correspondence is asserted

This is the direct answer to ADR-011's second inherited question: **the low bound is the right
floor, and it is not the whole answer.**

§ 4.5.1 fixes `amount` as *"the low bound where the entry's prose carries a range, and the point
value where it carries one"*, so a sum over markers is a true floor **by construction**. For each
entry **already joined by its marker**, the writer reads that entry's own prose money line and takes
the range's upper value. A point value, or a tier carrying no numeral, gives that entry a ceiling
equal to its floor.

**Why reading the prose here is admissible.** The option ADR-011 rejected is *"read the prose money
lines directly, no marker change"*, and its stated ground is the join — *"It has no key to attach its
answer to."* With the marker present the key exists. § 4.5.1 then says plainly that the prose is the
**master**, holding *"a range in a local currency with a human unit and any caveat the writer
attached"*, while the marker holds *"a single normalized scalar"*. Reading the master for the one
thing only the master holds is not the rejected option.

**No correspondence assertion is added, and that is deliberate.** § 4.5.1 declares as a gap that *no
file in this repository reads a prose money line against a `cost:` value*. This method adds none: it
never checks the two for agreement and never fails on a disagreement. Where they disagree, the marker
governs the floor and the prose governs only the spread above it.

**The estimate renders a range and a named unpriced remainder, never a single figure.** Where floor
equals ceiling throughout, it renders the point value **and states why** — an equality explained
rather than mistaken for precision.

### 7. Preload and cash come off the surfaces that already compute them

**Preload** is the fare-card figure `agents/04-transport.md` § *Pass Assessment* already computes,
apportioned to the traveller's present days. That section carries estimated journeys, per-journey
cost, pass cost, break-even and a verdict.

- Where the verdict **recommends the pass**, preload is the pass cost, named as such.
- Otherwise it is apportioned journeys times per-journey cost, plus that traveller's share of any
  `cost:`-bearing fare-card-payable stream.
- Where § *Pass Assessment* is absent or unexercised, preload renders **`undetermined` with the
  condition named** — never a default, never a padded guess.
- `**Recommended:** [Card or method]` from § *Payment & Transit Card Setup* is carried through, so
  the recommendation names an instrument rather than an amount alone.

**The bound is stated rather than left implied.** § *Point-to-Point Transit Matrix* is where daily
hop costs would live, and § 4.5 declares that table carries **no entry marker** and its rows carry no
key — so the preload figure states its own assumption: it covers the legs the brief prices and the
pass model, and unkeyed point-to-point hops are not in it.

**Cash** is derived from § *Destination Baseline* → `**Payment norms:**` crossed with the traveller's
category spend, plus a tipping allowance where `**Tipping culture:**` states one. Where that block is
unexercised, cash renders **`undetermined` with the condition named**. There is no default cash
figure.

**The unpriced remainder is reported beside cash as the contingency driver, in item count** — never
converted to a currency amount, which would be invention with a decimal point on it.

### 8. Budget Posture is a comparison, never a source

`trip-context.md` § *Budget Posture* carries an overall tier, a comfort range and spend priorities.
Those are declared **willingness to spend**, not observed price. Filling an unreadable item from them
returns the operator's own number to them as an estimate — circular, and the opposite of an estimate
sized to the traveller's plan.

It **may** be rendered as a labelled comparison line. It is **never summed into any total**.

### 9. C5 gains a money label, spelled `**Entry cost:**`

`agents/01-activities.md` gains one labelled line in its entry surface:

```
- **Entry cost:** local currency + approximate USD per person; `free` where there is none
  [Source date: approximate month/year or "current general knowledge"]
```

**`free` is a value, not an absence.** It contributes `cost: 0 <CUR> per-person` and counts toward
the priced reading. A value the agent could not establish carries the declared-absent form, and its
marker carries `cost: undetermined`.

The `[Source date: …]` bracket is copied from C6's `**Price:**` rather than invented, and it is what
brings the price-staleness rule within reach of C5 for the first time.

**Why this spelling.** `**Admission:**` was the first recommendation and was **overridden**:
*admission* reads as the act of entry as readily as its price, and this label's whole job is to tell
an emitter what to write. `**Entry cost:**` is unambiguous and is unused elsewhere in the corpus, so
it collides with nothing. § 4.5 rule 1 bars a **move** and not an addition, so adding a labelled line
to an entry surface is admissible; ADR-011 § Decision 8 governs label naming and keeps distinct
labels where they carry distinct things, which is what a fourth label is.

### 10. Coverage — the frontmatter pair measures the corpus, and the per-traveller reading lives in the body

**`cost-bearing-items` and `priced-items` are properties of the entry population, not of the
estimate's consumption of it.** M counts markers over the denominator classes; N counts those
carrying a readable `cost:` line — **whether or not the entry is placed**.

A consumption-keyed N would be placement-dependent and would read poor forever on any trip that
researches more than it places, which is every trip: `agents/01-activities.md` alone requires a
minimum of thirty entries plus five bailout options. That is the *"coverage ratio would read as poor
forever"* failure ADR-011 § Decision 4 excludes C8 to avoid, re-created on the axis it did not guard.

**Per-traveller coverage is a body value, and it is its own pair.** Each traveller row carries
`P of Q` — Q being that traveller's cost-bearing placed items and P those whose marker carries a
readable `cost:` — and the four rendering limbs apply per row keyed on P exactly as they apply to the
trip total keyed on N. Without a per-traveller denominator, a per-traveller `undetermined` is
indistinguishable from a per-traveller zero: the absence-versus-zero collapse the class exists to
prevent, one scope down.

**It is not a fourth frontmatter field.** ADR-011 already gives the reason about the total: *"No
field is the total … A total fails § 4.2's boundary test on question 2."* A per-traveller pair is a
vector, and § 4.4's per-class grammar is scalar-only. **No schema bump**: nothing here adds, removes
or retypes a field.

### 11. The populated limb is witnessed by extending the general fixture, under a narrowed Depth clause

`examples/data-architecture-demo/` is extended to witness `coverage: measured` with `0 < N < M`. No
second general fixture is authored.

**The fixture's own two rules are in tension and the narrower one is written for this case.**
§ *Depth* declares *"no external URLs, no opening hours, no prices, no real bookings"*, and also
declares a tier for classes with no tracked instance anywhere before that fixture — those *"get
enough content to exercise the class's own rule, because nothing else in the repository does."* C21
carries that tier and today exercises one limb of four.

The tension resolves on what the *no prices* clause is **for**: its clause-mates are all real-world
facts that would be stale or misleading in a sanitized fixture. A price on a placeholder venue in a
placeholder destination is not one of those — it is synthetic, exactly like the placeholder times,
event keys and venue names the fixture already ships, and like the price-adjacent `**Price tier:**`
value its nightlife instance already carries. What the clause withholds is a **sourced** figure.

**The narrowing is stated in § *Depth* itself**, so the fixture keeps one home for its own rule: *no
sourced prices — synthetic currency values only, where a class's own rule cannot be exercised without
one.*

**`0 < N < M` is the chosen limb** because it is the only one where a total and its coverage caveat
must be rendered together, so it exercises strictly more of the rendering rule than the others; it is
the shipping behaviour of any real trip; and it lets the fixture keep entries with no fact unpriced
and carrying `cost: undetermined`, which is itself a limb worth witnessing at entry scope.

**Two limbs are declared unwitnessed with their reasons, rather than left as silent gaps.** `N = M`
is a strictly smaller rendering than `0 < N < M`, and buying it costs a second general fixture for
one boolean. `unverifiable` is already effectively unwitnessed and this release does not regress it:
the only tracked tree that would read `unverifiable` is pinned in both directions by the freeze
declaration and can never gain a C21 instance.

### 12. The new agreements are graded by a real-tree suite group, and the validator is unchanged

Grading lands in `scripts/test-artifact-schema.sh` as a new group **`CE`**, reading the tracked tree
directly and adding **no finding code** to `scripts/validate-artifacts.sh`.

`CE` asserts that the frontmatter pair agrees with the marker population it counts, with the class set
read from § 1.1's Primary-entities column rather than enumerated in the script; that every `cost:`
line in the tracked tree matches the § 4.5.1 grammar; and that the rendering rule holds in both
directions. It carries one must-fire control arm per assertion, each mutating exactly one surface,
and its arm inventory is read from the group's own body on every run and compared in both directions
— so an assertion added without an arm is red rather than latent.

**Why not a validator finding code.** `scripts/validate-artifacts.sh` declares PROSE out of scope by
name and every code it emits is a frontmatter assertion. A body arm would cross that declared
boundary **and** would require a must-fire arm running inside the synthetic fixture tree, which is the
coupling the guard suite's header already records as having turned that group red once. The real-tree
groups are the corpus's own answer to this shape, and their header states it: each is a statement
about this commit's corpus, so each reads the tree directly and carries its own control arms.

## Consequences

- **C21 acquires a producer.** `agents/05-hub-planner.md` gains an output section for the artifact it
  has been the declared writer of while carrying no reference to it at all. That section is the
  largest single edit this record drives, and it is where every read rule above becomes an
  instruction to a writer rather than a decision in a document.
- **Four spoke prompts change what they emit**, and each states that its own no-line state is now
  historical. § 4.5.1's distinction becomes live: **no line** means *this writer does not yet emit
  cost*, and is from here true only of markers written before this change; `undetermined` means *this
  writer looked and found nothing normalizable*.
- **`agents/03-scheduling.md` is not touched, and that is a decision being honoured rather than an
  omission.** Its prompt already records a stated non-use rather than a deferral, in terms — a Day
  has no purchase, and the day key alone is that class's marker in full. C8 is outside the
  denominator by entity anyway.
- **Four schema mirrors move with their prompts.** Each restates the decline its prompt carried, and
  a mirror declining while its prompt emits would be a two-home contradiction — the failure ADR-011
  § Consequences already paid for once, when a rule stated in one document turned out to have ten
  restatements outside it. `reference/schemas/activities-list.md` also carries a sentence this record
  falsifies, that C5 is the one cost-bearing member with no money label of its own, and it moves in
  the same change.
- **The tracked coverage reading stops being zero.** ADR-011 recorded that coverage on the tracked
  corpus was `0 of 17` and *"stays there"*, on the ground that the frozen tree cannot gain markers and
  the demo fixture ships no prices. The first half stands; the second is what Decision 11 narrows, so
  the demo's N moves off zero while M does not move at all — no marker is added or removed.
- **The rendering rule acquires a grader.** `reference/schemas/cost-estimate.md` closes with a
  statement that the class is validated by nothing, which Decision 12 makes false for the mechanical
  limbs. It is rewritten in the same change and narrowed to what genuinely stays unreached: the prose
  caveats, the prose-derived ceiling, and the derivation bound.
- **The derivation bound is now stated at the writer.** ADR-011 § Decision 6 put it in a schema the
  writer does not read. The `internal-hard` escalation tripwire — a figure that acquires a need- or
  desire-derived justification string — is restated in the hub's own output section, which is what
  makes a writer meet it rather than trip it.
- **A residual this record does not close.** The ceiling is prose-derived and therefore **not
  machine-checkable**: `CE` grades the marker population and the rendering limbs, and no arm can
  grade a range's upper value against the sentence it was read from. That is why the ceiling lives in
  the body and why the coverage counts stay marker-only.
- **A second residual, stated because it bounds what a green means.** `CE` grades the tracked tree
  only. A user's git-ignored trip directory is unreachable by any check in this repository, so a real
  trip's estimate is never graded — the same posture the validator already takes over the same
  population.

## Follow-on build slices

- **A payment-state signal on C13.** Decision 2 renders the axis the corpus can support. Separating
  paid from payable needs a field C13 does not have, and adding one is a schema change to a
  `persist-mutable` class with instances already on disk. Filed as intake, not taken here.
- **A validator-agent coverage report.** `agents/06-validator.md` already owns the coverage idiom
  both § 4.5.1 and the C21 schema cite by name, and could audit C21's pair as it audits its own. That
  is new capability rather than a gap in this record, and `CE` already covers the mechanical
  assertion.
- **A command surface for the estimate.** `reference/command-reference.md` carries no cost verb and
  the estimate is a synthesis product, so none is owed by this record. A verb that surfaces it is a
  slice of its own.

## References

- `reference/adr/ADR-011-per-traveler-cost-estimation.md` — the record this one continues: the class,
  the marker amendment, the coverage pair, and the three inherited questions Decisions 3, 4 and 6
  answer
- `reference/data-architecture.md` § 1.1 (the C21 row and the Primary-entities column the denominator
  is computed from) · § 4.4 (the universal block this record does not touch) · § 4.5 rules 1 and 3 ·
  § 4.5.1 (the field grammar, the four rendering limbs, and the declared correspondence gap) · § 5.1
  (`internal` versus `internal-hard`) · § 5.3 (computed, never enumerated) · § 5.4 (the
  parsed-and-empty distinction) · § 11 (the boundary this record stays inside)
- `reference/schemas/cost-estimate.md` — the coverage pair, the rendering rule, and the derivation
  bound Decision 10 extends
- `reference/schemas/event-status.md` — the C13 status enum Decision 2 draws its axis from
- `templates/trip-context.template.md` § *Destination Baseline*, § *Per-Traveler Planning Days
  [DERIVED]*, § *Budget Posture*, § *Locked Elements* — the four declared surfaces Decisions 3, 5, 7
  and 8 read
- `reference/adr/ADR-006-third-party-data-capture.md` — the entry class the derivation bound protects
- `reference/adr/ADR-009-data-architecture.md` — the model ADR-011 amended and this record works
  inside
- `examples/data-architecture-demo/README.md` § *Depth* — the fixture rule Decision 11 narrows, and
  the invariant list where the coverage agreement is asserted
