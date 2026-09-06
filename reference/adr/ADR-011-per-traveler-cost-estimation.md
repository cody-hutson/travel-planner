# ADR-011: Per-traveler cost estimation — a new in-model class, and the one field the entry marker admits

- **Status:** Accepted (2026-09-02)
- **Deciders:** repo maintainer
- **Driving work:** the per-traveler cost-estimation milestone. This record is the prerequisite
  architecture decision that work's first acceptance criterion requires.
- **What this record is not.** It decides where a cost estimate lives, what an entry marker may
  carry, and how coverage is counted. **It specifies no estimation method** — no conversion, no
  rounding policy beyond the one the field grammar states, no per-traveler allocation rule for a
  group-total figure. Those are the estimating slice's, and a reader looking for them is looking in
  the wrong document. `reference/data-architecture.md` § 11 already bars metric formulas from the
  model, and this record does not relax that boundary; it fixes the **shape** the estimate is
  written in.

## Context

The engine researches priced things and has never carried a price anywhere a machine can read. Four
classes' prompts write a money value into entry prose — `**Price:**` in `outputs/food-list.md`,
`**Price range:**` in `outputs/nightlife-list.md`, `**Cost:**` in `outputs/transport-brief.md` — and
`outputs/activities-list.md` researches price without declaring a label for it. Measured on the
merged tree: `examples/tokyo-2026/outputs/food-list.md` carries **42** `**Price:**` lines. Every one
of them is prose, keyed to nothing, readable only by a person.

`reference/data-architecture.md` § 4.5 rule 2 is what stands between that prose and a machine
reading: **"The marker carries the entity key and nothing else."** The rule is deliberate and it is
good — it is what has kept the entry marker from accreting a display name, a zone, a duration and a
booking posture across five migration slices. Six files state it verbatim, and three agent prompts
name a price or a cost among the values it bars.

So a cost estimate is not a feature that can be added beside the model. It requires either a home
that reads prose, or an amendment to the one rule the model has been most careful about. This record
takes the second, and states what earns it.

**A second constraint shapes every answer below, and it is not a limitation to route around.**
`examples/tokyo-2026/` is pinned by content address in § 10's `frozen-witness-digest` fence and
asserted in both directions by `scripts/test-artifact-schema.sh` group `FW`. Its 42 priced entries
therefore **cannot** gain a cost field. Whatever this record decides, the first thing the estimate
does on the tracked corpus is read zero prices — so the zero-reading branch is not an edge case to
handle later. It is the shipping behaviour.

## Decision drivers

- **The marker rule's value is its narrowness.** Any amendment that opens the marker to "the fields
  a class finds useful" destroys it. An amendment that admits exactly one field, with a stated
  grammar and a stated reason, does not.
- **A cost estimate that cannot say *I could not tell* is worse than no estimate.** A total of `0`
  over an unreadable corpus is a confident wrong answer. § 5.4 already fixes this shape one layer
  down, for the publish guard, in terms: *a parsed-and-empty class must stay distinguishable from a
  class that could not be computed.*
- **`internal-hard` is a real boundary, not a caution label.** § 5.1 defines it as *never rendered
  and carrying values that must not reach a rendered page in any form, including anonymized*. A cost
  figure the group will discuss is not that; a cost figure carrying *why* is.
- **No new roster.** § 4.3's no-double-home rule and § 5.3's *computed, never enumerated* are the
  corpus's two standing defences against a maintained list drifting from the thing it lists. An
  amendment that ships a hand-maintained set of priced classes would create exactly that.

## Options considered

| Option | Why not |
|---|---|
| **Fold cost into C14 `outputs/satisfaction-metrics.md`** | C14 is `publish: internal-hard` — *never rendered in any form, including anonymized* (§ 5.1). A per-traveler cost figure is meant to be shown to that traveler. Folding it in forces either widening `internal-hard` or carving a per-field exception inside it, and § 5.1 admits neither. C14 is also `section-owned` between two writers, so a third concern lands in a file whose write split is already the corpus's most carefully argued. **Rejected.** |
| **Fold cost into C15 `outputs/final-itinerary.md`** | C15 is `publish: bound` and `versioned`. A cost estimate placed there reaches a rendered page by its host's class, and freezes into every `final-itinerary-v<N>.md` sibling — pinning a projection that holds no independent state inside an artifact whose lifecycle exists to preserve state. It is also the corpus's most narrative artifact, which `ADR-009` Decision 3 and `reference/site-layout-spec.md`'s Day-Header Content Contract both protect from structuring. **Rejected.** |
| **A new class, `outputs/cost-estimate.md`** | Keeps the projection regenerable and off the page. **Taken.** |
| **Read the prose money lines directly, no marker change** | A parser over `**Price:** ¥500–2,000/person` is a prose parser inside a data contract. It has no key to attach its answer to, so it cannot say which venue a figure belongs to; § 3.3 already measured display-name matching and rejected it as the join. **Rejected.** |
| **Widen the marker generally — admit any class-declared field** | Destroys the rule. Every value the six schemas currently bar becomes admissible by the same argument. **Rejected.** |
| **Admit `cost:` only in the classes that declare a money label today** | Requires a maintained roster of priced classes, which § 4.3 and § 5.3 both forbid; and it breaks C18. **Rejected — see Decision 4.** |

## Decision

### 1. C21 `outputs/cost-estimate.md` is a new in-model class

`hub` · `rebuilt-each-synthesis` · `derived` · `internal` · entities Traveler, Venue, Leg.

The enumeration moves from **26 to 27** — 21 in-model, 6 out — and the out-of-model dispositions
renumber from C21–C26 to **C22–C27**. `reference/data-architecture.md` § 1.1 carries the row and the
rejection of C14 and C15; `reference/schemas/cost-estimate.md` carries the shape.

**`rebuilt-each-synthesis` is the lifecycle because the artifact holds no independent state.** Every
figure in it is derived from a cost signal another class masters. Preserving it across a pass would
only let it drift from the entries it projects — which is the same reason § 1.1 gives for C14 and
C17. It lands in § 7.6's **self-upgrading** row and adds nothing to the upgrade residue.

### 2. The writer is `hub`, singular, and no spoke gains a read or a write

The estimate ranges over five classes' entries. Only one writer in the engine reads all of them, and
it is the same writer that already mints `ven-<token>` and builds the two reference files before the
itinerary. A spoke writing it would need to read its siblings' outputs, which no spoke does.

**`agents/04-transport.md` § *Input* item 7 is deliberately not widened.** It reads
`outputs/traveler-model.md` *for the depth signal and for nothing else*, and that narrowing is
load-bearing: the item's own text records that a `[THIRD-PARTY]` entry carries needs only and no
journey facet, so a wider read would let a real passenger be dropped from a stream being priced. A
cost estimate is not a depth signal. The bound stands.

### 3. § 4.5 rule 2 is amended to admit one optional cost field, in the fenced form only

The rule now reads: **the marker carries the entity key, and — in the fenced form only — an optional
normalized cost. Nothing else.** The grammar is in `reference/data-architecture.md` § 4.5.1:

```
cost: <amount> <currency> <basis>
```

`amount` a non-negative integer, the **low bound** of a range; `currency` an ISO 4217 alpha-3 code,
never a conversion; `basis` one of `per-person` | `group-total`. The degenerate value is
`cost: undetermined`, per rule 3.

**The basis enum is read off the corpus rather than minted.** `agents/04-transport.md` §
*Output Format* already writes every stream as `[Local] / [USD] per person, [Local] / [USD] group
total`. The two bases exist; this names them.

**The declared-key-column form (C10, C11, C13) is untouched.** A table already has columns, so a cost
belonging to a table-shaped class is a column of that table and needs no marker grammar to carry it.

**The `artifact-entry` fence info-string is untouched.** § 4.5 gives its ownership to the
venue-identity migration. A cost line sits *inside* the fence; the fence's opening token is not this
record's to set, and this record does not set it.

**The double-home question is answered rather than skirted.** The prose money line stays, unchanged
and unmoved — rule 1 forbids moving it. The two are not the same value: the prose carries a range in
a local currency with a human unit and any caveat the writer attached; the marker carries a single
normalized scalar with a declared basis. The marker is derivable from the prose and the prose is not
derivable from the marker, so the marker is a **projection** and the prose remains the master.
**That they correspond is a declared gap** — the same status, and the same words,
`reference/data-architecture.md` § 4.4 already gives the inline provenance marks against the
`provenance:` key. Nothing in this repository reads a prose money line against a `cost:` value, and
this record adds nothing that does.

**No agent prompt emits the field on this commit.** Every prompt touched here says so in terms. The
grammar lands first so a marker carrying a cost is read rather than treated as out of grammar; the
emitters are the estimating slice's.

### 4. The sub-decision: C8 and C18 inherit the widened grammar — and only C18 enters the denominator

**This is the one question the brief left open, and it separates into two questions that have
different answers.**

**Grammar admission — both, by form.** Every class in § 4.5's **fenced** row admits the field: C5,
C6, C7, C8, C9, C18. Three reasons, and the third decides it on its own.

1. **§ 4.5 assigns marker form per class *shape*.** A cost carve-out keyed on which classes happen to
   be priced would be the first per-class exception in a rule whose entire construction is
   form-scoped. § 4.5's own secondary-table bullet already refuses the neighbouring move for the
   same reason — *giving one class both forms would make the marker a property of a surface rather
   than of a class* — and a per-class field allowance is that same mistake one level down.
2. **A roster is a second home.** Restricting admission to the priced classes requires a maintained
   list of them. § 4.3 forbids a second home for a fact, and § 1.1's Primary-entities column already
   carries the one this list would restate.
3. **C18 makes the restricted option incorrect, not merely inelegant.** C18 is the **residual**
   class — the arm that gives any `outputs/*.md` no named class claims a schema to resolve against.
   A targeted re-run of the food agent writes exactly the shape C6 writes and resolves to C18 by the
   longest-literal-pattern rule. Under a priced-class roster that file is **out of grammar at the one
   moment the residual exists to catch it.** A residual can never admit less than the classes it
   stands in for.

**Admission is not obligation.** C8's field is admitted and will not be used: a Day has no purchase,
`agents/03-scheduling.md` is unchanged in what it writes, and its schema and prompt both record the
non-use as stated rather than as an omission a later slice reads as an oversight. **Uniform admission
with an optional field is strictly less surface than non-uniform admission with an allowlist**,
because the allowlist is itself a surface that must be maintained and enforced.

**Denominator membership — C18 yes, C8 no, by entity.** The estimate's denominator selects **every
class whose § 1.1 Primary-entities cell names `Venue` or `Leg`**: C5, C6, C7, C9, C18. C8's cell
names Day, Block and Signal, so it is excluded. Counting six Days in the denominator of a cost
estimate would inflate it with entries that structurally cannot be priced, and the coverage ratio
would read as poor forever.

**The two answers are on different axes and are not in tension.** Admission is about what a marker
may *say*; the denominator is about what an estimate *ranges over*. Reading the denominator out of
§ 1.1's own column keeps it computed rather than enumerated (§ 5.3's move, applied here), so a class
that later gains a priced entity enters with no edit to any rule.

### 5. Coverage is two counts and a verdict, and the pattern is the corpus's own

`reference/schemas/cost-estimate.md` declares three required per-class fields:
`cost-bearing-items` (M), `priced-items` (N), and `coverage: measured | unverifiable`.

**The independence of M from N is the whole design.** If M were *the entries carrying a cost line*,
then N = M by construction, the ratio would be 1 on every run, and the field would report complete
coverage forever — a number that cannot fail is not a measurement. So M is computed from the class
model (Decision 4) and N from the reading.

**That argument was not invented here, and the honest thing is to say so.**
`agents/06-validator.md` § *Marker coverage* already runs it, for its `E of T` anchor-meal tally,
and states the counterfactual in terms: *"were T instead the count of entries carrying an eligibility
line, E and T would be equal by construction, the ratio would read `T of T` on every file, and a
missing line would make the coverage read better rather than worse."* This decision **reuses** that
shape rather than re-deriving it, which is also why **M counts markers and never `###` headings or
ordinals** — the same rule that section already applies, so a class's two coverage measurements agree
on what an entry is.

**Reading that section supplied a limb this decision was missing.** It carries a third case:
*"where the file carries entries but no markers at all, T is not measurable: report `unverifiable`
and name the condition — never read a marker-less file as `0 of 0`."* A two-field design cannot
express it: `cost-bearing-items: 0` would assert an empty class where the truth is a failed read —
the exact absence-versus-zero collapse this class exists to prevent, re-created inside the field that
prevents it. Hence the third field. **The limb is reachable rather than theoretical:** under § 7.2's
tolerant read a pre-migration artifact in a user's git-ignored `trips/` carries no markers at all, and
`examples/tokyo-2026/` is exactly that shape and pinned so it can never stop being.

**The rendering rule:**

| State | The estimate renders |
|---|---|
| `coverage: unverifiable` | **`undetermined`**, no total, **and the condition named** |
| `measured`, `N = 0` | **`undetermined`**, and no total |
| `measured`, `0 < N < M` | a total **carrying its own `N of M` coverage**, never presented as complete |
| `measured`, `N = M` | a total, **and still `N of M`** — a reader cannot otherwise distinguish full coverage from a denominator that was never computed |

**`N = 0 ⇒ undetermined` is § 5.4's distinction applied one layer up.** A total of `0` reports *this
trip costs nothing*; the truth is *nothing was readable*, and the number alone cannot tell them
apart. That is the fail-open § 5.4 refuses at the publish guard, re-created in an artifact.

**All three fields are `required` for the reason `validation-report.md` gives for `critical-count`:**
a `rebuilt-each-synthesis` artifact always carries them, so `0` is a measurement and an absent value
is an `A3` violation rather than an ambiguous read. Absence-versus-zero is resolved at the schema
instead of at every reader.

**Requiring all three forces a convention on the `unverifiable` limb, and this record states it
rather than leaving the writer to invent one.** Under `coverage: unverifiable` the counts are not
computable — that is what the verdict means — yet both are `required integer` with no
conditional-optional arm and no sentinel, so a writer **must** emit an integer for each. The
convention is **`cost-bearing-items: 0` and `priced-items: 0`, neither of them a measurement**, and
the reading rule that makes it safe is **read the pair only when `coverage: measured`.** That is not
the collapse this decision exists to prevent: the collapse belongs to a *two-field* artifact, where
`0` is the whole answer and nothing distinguishes an empty class from a failed read. Here the third
field **is** the distinguisher, which is the entire argument for adding it. Making the counts
conditionally optional was the alternative and it is **rejected**: an optional field makes absence
and zero ambiguous at every reader, re-creating the problem one field over rather than resolving it
at the schema. `reference/schemas/cost-estimate.md` carries the convention in full.

**Three per-class fields is one more than any existing class declares, and it is warranted rather
than convenient.** Measured across the corpus: C19 `reference/schemas/travel-site.md` declares two
(`coordination-state`, `coordination-since`), C17 and C20 declare one each, and the other seventeen
declare none. Each of these three answers a question the other two cannot: M *what could have been
read*, N *what was*, `coverage` *whether the pair is a measurement at all*. Dropping any one
re-creates an ambiguous zero.

**No money figure reaches frontmatter.** A total fails § 4.2's boundary test on question 2 — two
correct writers rounding or bounding differently do not produce the same characters — and on question
3, because nothing in the corpus branches on a trip's cost.

### 6. `provenance: derived`, `publish: internal`, with a stated bound and a stated tripwire

**The derivation bound.** The estimate may carry a traveller's **`## Group` roster name and a money
figure, and nothing else** drawn from any per-traveler source. **No value is copied out of a
`[THIRD-PARTY]` entry** — not attributed, not anonymized, not paraphrased. That entry class exists
for a person who did not supply their own data and cannot consent to it (`ADR-006`), and the bound is
what keeps `internal` honest rather than merely declared.

**The escalation tripwire.** If a value in this artifact ever carries a **need- or desire-derived
justification string** — text saying which constraint or want a figure serves — the artifact holds a
projection of C12's content, and **the class moves to `internal-hard` and takes a row in
`reference/site-layout-spec.md` § 9.1's `publish-contract-artifacts` fence.** § 5.1's two classes
differ on exactly that axis. A roster name beside a number does not meet the `internal-hard` bar; a
roster name beside a number beside a reason does.

**Reconciliation with `ADR-004` — the bound's polarity is what does the work, not its coverage.**
`ADR-004` § 1 confines a traveller's contact method and emergency contact to the git-ignored `trips/`
working directory and states the non-publication guarantee as a **denial**: those fields are *never*
written to the published artifact or to `trip-context.md`. A denial is only enforceable against a set
someone enumerates, and `ADR-004` § 2 enumerates a **minimum** field set — a contact method plus one
emergency contact — not a maximum. C21 is a location `ADR-004` does not name, because it did not
exist when that record was written: a new `outputs/*.md` is neither the published artifact nor
`trip-context.md`, so nothing in `ADR-004`'s own wording reaches it. **This record does not rely on
that silence.** The derivation bound above is written in the opposite polarity — an **allowlist of
exactly two things**, a `## Group` roster name and a money figure — so every `ADR-004` field is
outside C21 by construction rather than by a rule that had to anticipate it, and so is every field a
later slice adds under that record's follow-on build slices. A contact method is not a roster name and
not a money figure; it is barred by the same clause that bars a shoe size. **The one place the two
records genuinely differ is enforcement, and it is stated rather than smoothed.** `ADR-004` § 4 makes
its guarantee *fail-closed* — a validator check plus a build-time exclusion — while C21 ships with
nothing that reads its body at all (see Consequences). The bound is therefore **declared and
unenforced today**, which is exactly the status § 4.5.1's own correspondence gap carries, and it is
sound only because **C21 has no producer**: nothing writes the file, so there is no write for a check
to grade. `ADR-004`'s enforcement pattern becomes owed at the moment the estimating slice supplies a
writer, and that slice inherits the obligation from this paragraph rather than discovering it.

**Reconciliation with `ADR-008` — this record adds no value the guard would have to match.**
`ADR-008`'s `verify_publishable_content` is a predicate over the **published file** on the
`--plaintext` limb, sourced from `nonpublishable_values`, which reads `outputs/traveler-model.md` and
the per-traveler profiles. C21 is neither of those, so the guard **gains no source and loses no
coverage** from this change: nothing here widens `nonpublishable_values`, adds a class member, or
touches either publish limb. `publish: internal` closes the other direction — the site build never
reads C21, so no byte of it reaches the render the guard certifies. **The question `ADR-008` actually
forces is sharper than either of those, and it is why the bound is drawn where it is.** C21 could, in
principle, manufacture a class value on a path the guard cannot see: a money figure paired with a
*reason* is a projection of a `[THIRD-PARTY]` need, and `ADR-008`'s own coverage boundary — residual
8(a), and residual 2's value arm — records that a short, common-vocabulary need value is **not
reliably keyable by string matching** and is deliberately left on the fail-open side. A need that
reached a rendered page *through* a cost estimate would land in precisely the blind spot that document
declines to claim as covered. So the bound bars the justification string **outright**, at the artifact,
rather than letting a value travel and trusting a matcher `ADR-008` has already measured as partial.
**The escalation tripwire is the same argument in structural form.** `ADR-008`'s three-layer table
names a declared field attribute — layer 3 — as the only mechanism that settles the class *by
construction* rather than *by detection*, and the tripwire is that shape: a `publish:` class change
plus a § 9.1 fence row, not a new string for a matcher to find. A C21 that ever carries a reason
leaves the guard's blind spot by **changing its own declaration**, which is the move `ADR-008` says is
the only one that works.

**Under `internal`, no fence row is owed today, and that is checkable rather than asserted.**
`scripts/test-artifact-schema.sh` group `PB` derives its class selector **from the fence**, and § 9.1
declares only `bound` and `internal-hard` rows. An `internal` class is outside PB's selector by
construction; a row added for it now would make PB report an unmatched fence entry — the group's
`only-in-fence` failure direction. **The escalation above is what would earn the row**, which is why
the tripwire names the fence rather than leaving a later author to discover it.

### 7. The witness is degenerate, declared `witness:`, and lives outside the frozen tree

`examples/data-architecture-demo/outputs/cost-estimate.md` — every field label present with
declared-absent values, `cost-bearing-items: 17`, `priced-items: 0`, `coverage: measured`, total
`undetermined`.

**It witnesses `measured`, not `unverifiable`, and the difference is the point.** Every entry-bearing
file in that fixture carries markers, so M is a real count and the zero is a measurement.
`examples/tokyo-2026/` is the other case — 42 priced entries, no markers, pinned — and an estimate
over that trip would read `unverifiable`. Both render `undetermined` and they are not the same
finding.

**It declares `witness:` and never `no-witness-because:`.** The distinction is not cosmetic: the
class *has* a tracked instance, and what that instance witnesses is the `undetermined` branch. A
clause would have said the class has no witness, which is false — and `reference/schemas/README.md`
records that a clause naming a *condition* is pending while only one naming a *property* is terminal.
Neither applies; the class is witnessed.

**The degenerate branch being the witnessed one is the right way round.** That fixture ships no
prices by its own § *Depth* rule, so it can witness the zero-reading branch and could not witness a
populated one. The branch that is hardest to get right is the one with a fixture behind it.

**No file is added under `examples/tokyo-2026/`.** Group `FW` asserts that tree's path set in both
directions, so a file added there fails as loudly as a file whose bytes moved. That tree is the
regression witness; it is not where new fixtures go.

### 8. `agents/02-food.md` declares `**Price:**`, matching its own realized entries

The prompt declared `**Price range:**`; every one of the **42** realized entries in
`examples/tokyo-2026/outputs/food-list.md` writes `**Price:**`. The prompt is the outlier and it moves
to match — the frozen instances could not move if the decision had gone the other way, and the
realized form is the one every consumer has actually met.

**`agents/07-nightlife.md` keeps `**Price range:**`.** The two labels genuinely differ in what they
carry, the prose labels are not a machine surface, and § 4.5 rule 1 does not move body structure to
tidy it. **What unifies them is the marker's single `cost:` token**, which is one of the things the
amendment buys.

**Two consumers read the old label and are reconciled with it** —
`agents/06-validator.md`'s superseded-entry price check and `reference/data-model.md`'s venue-entry
join. Both are re-stated **label-neutrally**, naming each class's own declared label rather than one
spelling. The validator's reference was **already wrong** for the frozen tokyo-2026 food-list, which
has written `**Price:**` since before this record; the reconciliation fixes a live defect as well as
one this record would have introduced.

### 9. Reversibility and confidence

| Element | Reversibility | Confidence |
|---|---|---|
| C21 as a class | **CHEAP** — delete the row, the schema and the witness; nothing consumes it yet | HIGH |
| The § 4.5 rule 2 amendment | **MODERATE** — reversible while no writer emits the field, which is the state this record ships in; expensive once markers in users' git-ignored `trips/` carry cost lines | HIGH |
| C8/C18 inheritance | **CHEAP** — narrowing the admission later is a prose change while nothing emits | MEDIUM — the reasoning is sound and the residual argument is decisive, but no fixture exercises a populated C18 cost line |
| `publish: internal` | **CHEAP** in the escalation direction — the tripwire names the exact move | HIGH |
| `agents/02-food.md` label | **CHEAP** — one line | HIGH |

**The moderate tier is the reason the emitters are deliberately not in this change.** The amendment is
cheap to reverse for exactly as long as no writer emits the field. Landing the grammar and the
emitters together would spend that window in one commit.

## Consequences

- **The marker rule is no longer absolute, and every restatement of it had to move.** Measured on the
  merge base: **five schemas and five agent prompts** stated *the marker carries the entity key and
  nothing else* — C5's, C6's, C7's, C8's and C9's schemas, and the five spoke prompts that write
  them. **`reference/schemas/targeted-research.md` did not**, and that absence is the finding inside
  the finding: C18 is the residual class whose existence decides Decision 4, and the rule it inherits
  had never been written down in its own schema. It gains the statement here — a home **added**
  rather than repaired, which is why the schema count is five and the reconciled-file count is not.
  Two further restatements sit outside those ten and are reconciled with them:
  `examples/data-architecture-demo/outputs/venue-matrix.md`, which restates the rule as a fixture
  note, and `reference/data-architecture.md` itself, which is the rule's own home (§ 4.5 rule 2) and
  restates it twice more inside itself. **That a rule stated once had ten restatements outside its own
  document is itself the finding:** the amendment cost more edits than the decision did.
- **Coverage on the tracked corpus is `0 of 17`, and it stays there.** The frozen tree's 42 priced
  entries cannot gain markers, and the demo fixture ships no prices. **A future reader must not read
  that zero as a defect** — it is the freeze and the fixture rule working as designed.
- **C21 is declared and unproduced**, the position C18 already occupies. `reference/data-architecture.md`
  § 7.6's self-upgrading row covers it: the hub emits it at the current version on the first pass that
  writes one, and there is no older instance to migrate.
- **Nothing validates the body.** The gate reads the fence and grades frontmatter. `cost-bearing-items`
  is checked as an integer and never against the entries it counts; the `undetermined` rendering rule
  is prose no finding code reaches. Fixture invariant **F10** in
  `examples/data-architecture-demo/README.md` is where that agreement is asserted, in the same
  prose-not-script form F2, F4 and F6 already take, and for the same stated reason.
- **The estimating slice inherits three named questions this record does not answer:** how a
  `group-total` figure allocates across travellers, whether a range's low bound is the right
  normalization once real ranges are read, and whether a converted figure ever earns a home. Each is a
  method question, and § 11 keeps methods out of the model.

## References

- `reference/data-architecture.md` § 1.1 (the C21 row and the C14/C15 rejections) · § 4.5 rule 2 and
  § 4.5.1 (the amendment and the field grammar) · § 5.1 (`internal` vs `internal-hard`) · § 5.4 (the
  parsed-and-empty distinction this record applies one layer up) · § 10 (the frozen witness)
- `reference/schemas/cost-estimate.md` — the class's shape, the coverage pair, the rendering rule
- `reference/adr/ADR-004-contact-emergency-privacy.md` — the per-traveler privacy model Decision 6
  reconciles against: its § 1 storage confinement and § 2 minimum field set, and the § 4 fail-closed
  enforcement C21 owes only once it has a producer
- `reference/adr/ADR-006-third-party-data-capture.md` — the bound Decision 6 rests on
- `reference/adr/ADR-008-publish-content-guard.md` — the publish-path content guard Decision 6
  reconciles against: the class source this record does not widen, and the coverage boundary
  (residual 2's value arm, residual 8(a)) whose fail-open side is why the justification string is
  barred at the artifact rather than left to the matcher
- `reference/adr/ADR-009-data-architecture.md` — the model this record amends
- `reference/site-layout-spec.md` § 9.1 — the fence the escalation tripwire names
