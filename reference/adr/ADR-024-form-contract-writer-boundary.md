# ADR-024: The form contract's writer boundary — the owned region as the unit, a key of region and condition, and an exclusion that executes rather than amends

- **Status:** Proposed (2026-09-20)
- **Deciders:** repo maintainer
- **Driving work:** the *contract learns about writers* milestone. This record is that milestone's
  single gating decision. It runs parallel to the build slices and gates only the trip-context
  surface, in the shape the preceding milestone's two Wave-0 records already ship: it lands before
  any feature slice and settles a cross-cutting question every slice would otherwise answer
  separately.
- **What this record is.** A decision about **how the form contract expresses a writer boundary**,
  so a form with several owners can conform: what the unit of conformance is and what keys it, how a
  boundary is declared and how a region's extent is expressed, how an out-of-region write becomes a
  detectable defect, what the version axis does, what the assertion surface becomes, and what
  happens to a region no writer owns. Its subject is a **partition and its declaration** — never the
  text that would implement one.
- **What this record is not. It decides no conduct and no session behaviour.** It decides no
  lifecycle, no resumption, no write cadence, no sequencing, no proxy-vs-self rule, no
  conversational-integrity rule and no modality contract. Those belong to the interview session
  model, and this record neither quotes nor predicts a clause of it. Where the two must meet they
  meet at what a conforming form **exposes**, and this record says nothing about what a session does
  with it.
- **What this record does not ship.** It **binds** `templates/`, `skills/`, `CLAUDE.md` and
  `scripts/test-artifact-schema.sh`; it **edits none of them**. Binding is not editing. The
  governing prior record declined to grow the contract's writer partition before a conformant
  consumer existed, and that premise is still literally true — measured below, the contract's fence
  occurs **once, in one file, and that file is the record that declared it**. This record decides
  the partition. A later slice ships it.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the operator's, taken at this milestone's close, and it moves **both** halves of
  a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md). No required check here grades either half or their agreement, so the
  obligation travels with this line rather than with a gate.

## Context

**One fence per form presumes one writer per form.** The governing prior record makes a form
interviewable if and only if it carries, above its boundary, exactly one fenced `intake-form` block.
That holds for the two classes the contract was designed against: both shipped guided forms declare
`writer: human` and are owned end to end by the person filling them in.

**It does not hold for the trip form, which is block-owned.** `CLAUDE.md` § *Write ownership* gives
`trip-context.md` a per-block writer table — the roster to one command at creation and another
thereafter, the mode fields to a five-procedure set, the `[ENRICH]` fields to the enrichment agent,
the `[DERIVED]` blocks to **no writer at all**, and a block the table does not list to nobody.
**Measured at `5d2571c`:** a table-row parser over that section reads **9 data rows** — 11 pipe-lines
in the section, less one header and one separator. The same parser reads 126 pipe-lines across the
whole of `CLAUDE.md`, so the extractor is live rather than returning an incidental number.

**The load-bearing structural fact is that ownership here is a tree with inheritance and override,
not a partition.** Measured at the same commit, in `templates/trip-context.template.md`:

- Two `[ENRICH]` sub-blocks sit **nested inside** a human-owned section — `### Transit Access` and
  `### Walkable Proximity`, both under `## Accommodation`. Their writer is not their parent's.
- Two `[DERIVED]` sub-blocks sit nested the same way — `### Effective Planning Days` and
  `### Per-Traveler Planning Days`, both under `## Logistics`.
- One heading literal **repeats**: `### [Constraint Name]` occurs twice, byte-identically, and the
  form instructs its filler *"Add or remove blocks as needed."* — so the instance count is authored
  by a human at fill time, not by the form.
- One row's writer is a function of **lifecycle condition** rather than of the region alone: the
  roster block is written by one command at creation and a different one thereafter.

That single fact eliminates two of the three boundary mechanisms the problem statement proposed, and
is why the key this record settles carries a second dimension.

**The size of the surface, stated with its basis rather than inherited.** The figure this milestone
was opened on was not re-derivable: it counted a term with no corpus definition, and three candidate
readings produce three different numbers. **The instrument used throughout this record is stated
once and used everywhere: a _field_ is a bullet whose leading content is a bold label terminated by
a colon — a line matching `- **<Label>:**`.** Under that instrument, at `5d2571c`:

| Form | Lines | Fields | Fields carrying a bracketed placeholder |
|---|---|---|---|
| `templates/trip-context.template.md` | 418 | **86** | 71 |
| `templates/traveler-intake.template.md` | 388 | 26 | 25 |
| `templates/person-intake.template.md` | 324 | 15 | 15 |
| **Totals** | — | **127** | **111** |

So the trip form carries `86 / 127` of the fields across the three forms — **67.7 %** — or
`71 / 111` = **64.0 %** under the stricter reading that counts only a field whose placeholder is
bracketed. **Both readings are reported rather than one being chosen silently**, because the two
answer different questions and the looser one is the one a coverage claim usually means. The control
arm for the instrument is the same file's 40 plain, non-bold-label bullets, which the field key does
not see and must not.

**The contract has never met a block-owned surface, so its generality is asserted rather than
demonstrated — and this record does not change that.** Probed at `5d2571c` over the 152 tracked
`.md`, `.sh` and `.yml` files: the line-initial fence opener occurs **once, in one file**, and that
file is the prior record's own worked example. **Zero** occurrences across `templates/`, `skills/`
and `scripts/`. The control arm is `^lifecycle:` over the identical instrument and population, which
returns **52 files** — so the probe discriminates and the zero is a finding rather than a broken
instrument.

## Decision drivers

1. **A boundary both readers compute identically.** The interviewer and the assertion suite must
   resolve the same extent from the document alone, with no second home for the region vocabulary.
2. **The fence count must stay a property of the form, not of the filled artifact.** A form whose
   filler is invited to duplicate a block cannot have a per-region fence without making conformance
   undecidable on the blank template.
3. **An out-of-region write must be detectable, not conventional.**
4. **No new vocabulary where the corpus already carries one.** The markers and the inheritance rule
   exist; a contract that re-declares them creates a second home for a fact.
5. **The two shipped guided forms must not churn.** They were made conformant by the immediately
   preceding release; re-editing them is cost with no defect to fix.
6. **A later ownership decision must not cost a supersession.** An Accepted record here is
   immutable as to its decisions, and the amendment clause admits narrowing a coverage statement
   while admitting no widening.

## Options considered

Six decisions, each weighed as its own option space. The matrices are inline in § *Decision*
below rather than gathered here, because the ground for rejecting an option in one decision is
frequently a consequence carried from another, and separating them would break that chain.

## Decision

### 1. The unit of conformance, and the key that identifies it

**The unit of conformance is the _owned region_, keyed by `(region × condition)`, with the whole
form as the degenerate case.**

This decision has two limbs. They are folded into one decision rather than split into two, because
the key is an attribute of the unit and not a separate object: under the whole-form unit the key
question is meaningless, and under two parallel contracts it would have to be answered twice. A
decision naming a unit without naming what identifies it has not finished.

**Limb A — the unit.**

| Option | Verdict |
|---|---|
| **1A** Whole form — the status quo | **Rejected** |
| **1B** Owned region, whole-form as its degenerate case | **ADOPTED** |
| **1C** Two parallel contracts — one per form, one for block-owned artifacts | **Rejected** |

**Ground for 1B.** It *subsumes* 1A at zero cost: a form whose single region spans the file and
whose writer is `human` is exactly today's contract. Both shipped guided forms therefore stay
conforming with **zero edits**, which is what makes this record's migration answer *there is none*.

*Rejected — 1A, and the ground is impossibility rather than expense.* The prior record's conformance
question 5 requires `writer:` to be `human` **and** no field marked `[DERIVED]` or `[ENRICH]`. At
`5d2571c` the trip form carries 23 fields under `[ENRICH]` headings and 7 under `[DERIVED]`
headings. Whole-form conformance for it is definitionally unreachable, not merely costly.

*Rejected — 1C.* A second contract means a second conformance arm, a second version axis and a
second seam. It is also the shape the assertion surface has already rejected one level down: that
suite's own comment records that a class-to-form map "was NOT taken, because it would be a second
place the class vocabulary lives and would make that one line two". Authoring a second contract here
would repeat that defect at the contract layer.

**Limb B — the key.**

| Option | Verdict |
|---|---|
| **1D** Key on region alone | **Rejected** |
| **1E** Key on `(region × condition)` | **ADOPTED** |

**Ground for 1E, and it is measured rather than anticipated.** Two of the nine writer rows name
*several* writers for one block, disambiguated by lifecycle condition: the roster block is written
by one command **at creation** and a different one **thereafter**, and the mode fields are written by
a five-procedure set under a named carve-out. A key on region alone cannot express either. It would
resolve the roster block to two writers simultaneously and be forced to pick one, which is a wrong
answer returned confidently — the same failure mode the prior record's join-key measurement rejected
when a label-only key mis-resolved a colliding label.

*Rejected — 1D.* It is the assumption every candidate mechanism in the problem statement carried,
and the corpus falsifies it on two of nine rows. Keeping it would push the condition axis into the
interviewer as an undeclared convention, which is exactly what decision 3 refuses.

**What the condition is, stated so the key is decidable.** A **condition** is a predicate over state
the contract can already resolve — the artifact's existence at the moment of the write, and the
lifecycle value the resolution contract returns. It is **not** a free-text qualifier and **not** a
procedure name: a region whose writer varies by something the resolution contract does not return is
not keyed, it is undecidable, and it falls to decision 6.

**Consequence carried into 2, 3 and 5** rather than re-decided there: extent must address a region
*in a tree*, so a single-cut boundary does not generalize; detectability is a *region-membership*
predicate rather than a file predicate; and the arm grades per region while registering per form.

### 2. How a boundary is declared

| Option | Verdict |
|---|---|
| **2A** One fence per owned region | **Rejected** |
| **2B** One fence carrying a scope key naming regions | **Rejected** |
| **2C** Declared permanent exclusion of block-owned surfaces | **Rejected — price stated** |
| **2D** One fence; extent is the heading tree, marker-override with parent-inheritance | **ADOPTED** |

**Ground for 2D — it declares no new vocabulary.** The markers already exist and are already
load-bearing: `[DERIVED]` and `[ENRICH]` live in heading text and the writer table is keyed on
exactly those markers. The inheritance rule is *already stated* in that table — an untagged `###` or
`####` sub-block inherits its parent `##` section's row. So the fence gains a key that is an
**address** pointing at the writer table, never an enumeration, which is what the prior record's
D2.2 requires when it says the declaration points and never copies. The fence count stays exactly
one.

**Extent, expressed so both readers compute it identically.** A region's extent is **the heading and
everything beneath it until the next heading of equal or higher level**. That is ordinary markdown
containment, computed from the document alone. No grammar is invented and no second home is created.
Resolution under this rule is checked against the two structures that motivated it: the repeating
constraint blocks are both untagged, so both inherit their parent section's row and resolve
identically; the nested `[ENRICH]` and `[DERIVED]` sub-blocks carry their own marker, which overrides
the parent.

*Rejected — 2A, because the fence count stops being a property of the form.* The `### [Constraint
Name]` heading ships twice under byte-identical text and the form invites its filler to add or remove
such blocks. A fence per region therefore makes the fence count a property of the *filled artifact*,
breaking the prior record's conformance question 1 and making conformance undecidable on the blank
template. It also puts a fence *inside* a region a person is filling in, against that record's own
statement that the fence is not a field you fill in.

*Rejected — 2B, on two independent grounds.* It puts the region vocabulary in the fence *and* the
heading text in the document, which is a second home for one fact. And it cannot address what it
must: the two repeating constraint headings are identical literals, so a text-keyed scope key cannot
distinguish them, and the mode fields are **not bullets** — measured at `5d2571c`, that section
carries 0 field-shaped bullets and 2 line-initial bold fields — so a key resolving to a bullet set
finds nothing there at all.

*Rejected — 2C, and the price is stated as the problem statement requires.* Excluding block-owned
surfaces wholesale puts **86 of 127 fields — 67.7 %** — permanently out of reach, or **71 of 111 —
64.0 %** under the bracketed-placeholder reading. It forecloses the milestone's stated coverage goal,
and it is the only option that leaves the prior record's cost claim permanently undemonstrated on a
dissimilar form, which is the value basis this record was opened on.

### 3. How an interviewer knows what it may write

| Option | Verdict |
|---|---|
| **3A** Convention in skill prose | **Rejected** |
| **3B** Pre-write predicate in the interviewer only | **Rejected** |
| **3C** Post-hoc assertion arm only | **Rejected** |
| **3D** 3B as the mechanism **and** 3C as the assertion | **ADOPTED** |

**Ground.** The requirement is that an out-of-region write be a detectable defect rather than a
convention, which forecloses 3A outright.

*Rejected — 3B alone*, because it is self-referential validation: the only evidence that the
interviewer respected the boundary is the interviewer's own claim.

*Rejected — 3C alone*, because it gives the interviewer no rule to follow, and over a human-filled
artifact it cannot distinguish an engine write from a human one.

**The shape 3D takes is already in the corpus.** The prior record's D5.5 is a **must-fire negative
arm**: it inserts a field-shaped line below the boundary and *requires the refusal to fire*. This
decision is that shape lifted one level — insert a write into a region whose writer is not the
interviewer, and require the refusal. That is this repository's own Discriminating-Evidence Rule,
which the assertion suite states in its own words: a PASS may never be reached on a branch a
degenerate outcome also reaches.

### 4. The version axis

| Option | Verdict |
|---|---|
| **4A** A version bump; v1 forms remain conforming; no migration | **ADOPTED** |
| **4B** A bump with migration; v1 retired | **Rejected** |
| **4C** No bump — the region model is a compatible extension | **Rejected** |

**Ground for 4A, and this is the answer to the migration question.** Under decision 1 a v1 form *is*
the degenerate case, so both guided forms remain conforming **unedited**. **There is no migration.**
A mixed-version corpus means one arm with a version branch, not two arms: a v1-declared form is
graded on exactly the prior record's six questions, and a v2-declared form additionally gets the
region questions.

*Rejected — 4B.* It requires editing two forms that are conformant and were *made* so by the
immediately preceding release — churn with no defect to fix, and it re-opens that record's
standardization decisions.

*Rejected — 4C, and this is the subtle one.* 4C is *technically available* precisely because decision
1 makes v1 the degenerate case. But the version axis exists, in the prior record's own words, so that
a skill and a form can disagree **detectably rather than silently**. Without a bump, a v1-only skill
reading a v2 block-owned form reads `writer:` as a form-global value and writes anywhere — the exact
silent disagreement the axis was authored to prevent. **The bump is load-bearing precisely because
the two shipped forms do not change.**

**This limb is not severable, and it was tested for severability rather than assumed into the
record.** Its option space is a *function of* decision 1 — 4C is on the table only because 1B makes
v1 degenerate, and under 1A or 1C the question has a different option set entirely. One of its three
options falls to a single measured fact. It looks severable only because it is the cheapest limb,
costing no edits anywhere, and **cheap is not independent**.

### 5. What the assertion surface becomes

| Option | Verdict |
|---|---|
| **5A** Per form | **Rejected** |
| **5B** Per region, with regions named in the script | **Rejected** |
| **5C** Per region, registered per form, region set **discovered** from the document | **ADOPTED** |

**Ground for 5C.** The region set is computable from the heading tree by decision 2's extent rule, so
discovering it costs the arm nothing and keeps the region vocabulary in exactly one place — the
document.

*Rejected — 5A*, because a single bit over nine differently-owned rows cannot say *which* region
failed: a form conformant on eight of nine rows reads identically to one conformant on none.

*Rejected — 5B*, because it is the class-to-form map the assertion surface has already rejected one
level down, reproduced at the region layer. An arm naming regions puts region vocabulary in the
script beside the form's own declaration, and a record recommending it would stand in direct conflict
with the arm it must land in.

**The control arm, because an arm without one grades nothing.** Two arms, both required: a
**sensitivity arm**, where the same probe over a conformant region returns green; and a **must-fire
negative arm**, where a field-shaped bullet inserted under a no-writer heading drives the conformance
verdict red.

**A mechanical constraint this decision places on decision 6.** The suite reduces by any-fail and,
under its strict skip mode, an undeclared skip also fails. Combined with the empty-population clause
of the Discriminating-Evidence Rule, this means decision 6's exclusion must be a **declared exclusion
the arm reports**, never a silent omission from the population. An excluded region that simply
vanishes is precisely the degenerate pass that rule forbids.

### 6. Regions no writer owns

| Option | Verdict |
|---|---|
| **6A** Unconditional exclusion | **Rejected** |
| **6B** Conditional exclusion | **ADOPTED** |
| **6C** Take it as a dependency and block on the ownership record | **Rejected** |

**The decision, stated so it executes rather than needing amendment.** *A region with no declared
writer is outside the contract until an owner is decided; when one is, the region enters by the rule
already stated in this record.* No edit to this record is required when that happens, and none is
permitted to be necessary.

**Ground, and it rests on this repository's own amendment clause read live.** `README.md` permits an
Accepted record to be edited in place to correct a claim it got wrong, **narrow** a scope or coverage
statement, or repair a citation whose target has moved — three permitted acts, and **widening a
coverage statement is not among them**. So under 6A, admitting these regions once an owner lands is a
*widening*: not an available amendment, therefore a supersession, which is the expensive path this
milestone's reversibility line already names. Under 6B the later admission is the decision
**executing as written**, at no ADR cost at all.

**6B is not an invention — the governing table already uses its shape for these exact blocks.** The
`[DERIVED]` row reads, verbatim: *"Until an owner is decided these blocks are read-only to every
command, `/trip-record` included; staleness is reported, never repaired in place."* The trip-context
template states the same disposition in its own durable prose, documenting the no-writer state as
**stable-and-reported** rather than as a gap — so this exclusion *describes the engine's documented
behaviour* rather than creating a hole.

*Rejected — 6C.* It blocks this milestone's gating decision on a different milestone, inverting their
order, and it leaves the interviewer with no rule for these regions in the interim.

**The price of 6B, stated precisely — and it is not the coverage figure from § Context.** This
exclusion costs **7 of 86 fields — 8.1 %** of the trip form: the two `[DERIVED]` sub-blocks, carrying
5 and 2 fields. The 67.7 % figure belongs to **decision 2's option 2C**, a wholesale exclusion of
block-owned surfaces, which is a different exclusion entirely. The two are frequently conflated and
this record does not conflate them.

**The second writerless row is disposed of too, and it is structurally different.** The row covering
*a block not listed above* is also writerless, but it has **no extent** — it is a rule about future
blocks, not a region in the document. 6B's clause reaches it by construction, since that row's own
condition already reads that a new block gets an owner in the table before it gets content.

## The nine rows — which become interviewable and which do not

**This is the record's falsifiable prediction. It is not a demonstration.** Every verdict below is
derived from the decisions above applied to the writer table; none of them has been executed, because
no conformant consumer exists to execute them. A later slice that builds the consumer either
reproduces this table or falsifies it.

**Method, so the column is re-derivable.** Each field in `templates/trip-context.template.md` at
`5d2571c` is attributed to its nearest enclosing heading, then rolled up to a writer row by the
table's own inheritance rule — an untagged sub-block inherits its parent section's row, a marked
sub-block takes its marker's row. The column sums to 86, which is the file total under the same
instrument.

| # | Row | Writer | Fields | Interviewable? |
|---|---|---|---|---|
| 1 | Title line · roster · total travelers | one command at creation; another thereafter | 3 | **CONDITIONAL** — yes after creation; no at creation, where the roster is derived rather than asked. The clearest case for the `(region × condition)` key |
| 2 | Mode fields — current mode, mode notes | a five-procedure set | 0 | **NO** — two independent grounds: the writer is a procedure set, **and** the fields are not bullets, so the contract's field key cannot see them |
| 3 | `[ENRICH]` fields, 5 named blocks | the enrichment agent | 23 | **NO** — agent-owned; conformance question 5 refuses it. The two nested sub-blocks carry 0 fields, so the exclusion costs nothing beyond the three top-level blocks |
| 4 | `[DERIVED]` blocks, 2 | **no writer exists** | 7 | **NO** — excluded, *conditionally*, per decision 6 |
| 5 | Destination | the record command | 3 | **YES** |
| 6 | Locked elements · current itinerary status | the operator, through the record command | 5 | **YES** — the row names the operator explicitly |
| 7 | The lifecycle marker line | the decommission command | 0 | **NO** — **the line is absent from the template entirely**; it is an instance-only, command-written marker with no extent in the form |
| 8 | Every untagged field not named above | the record command | 45 | **YES** — the default row; human source |
| 9 | A block not listed above | **nobody** | n/a | **NO** — no extent to interview; decision 6's clause reaches it by construction |

**Totals, reconciled:** interviewable `3 + 5 + 45 = 53`; conditional `3`; not interviewable
`0 + 23 + 7 + 0 = 30`. `53 + 3 + 30 = 86`, the file total. So **53 of 86 fields — 61.6 %** — are
predicted interviewable outright, **3 — 3.5 %** conditionally, and **30 — 34.9 %** not.

**Row 7's zero carries its control arm.** The lifecycle marker occurs **0 times** at line-initial
position in the template. The same instrument over the 5 example `trip-context.md` files returns
**1** occurrence, in the archived demo — so the probe discriminates, and the template's zero is the
finding that this marker has no extent in the form rather than a broken search.

## Consequences

### Blast radius

**Structural by reach, cosmetic by edit.** The decision binds four surfaces simultaneously — which is
what makes it cross-cutting rather than local — and edits none of them.

| Surface bound | Edited by this record? |
|---|---|
| `templates/` — every form | **No** |
| `skills/` — the interviewer | **No** |
| `CLAUDE.md` — the writer table | **No** |
| `scripts/test-artifact-schema.sh` — the conformance arm | **No** |

Downstream: every future interviewable surface. **Failure at 2am: none** — a decision record runs
nothing. The cost of getting it wrong is paid later, by forms built against a contract that cannot
express what they are.

### What this buys, stated as the surfaces it leaves untouched

Both shipped guided forms remain conforming with zero edits, because decision 1 makes the whole form
the degenerate case of the owned region. The fence count stays exactly one per form, because decision
2 makes extent a property of the heading tree rather than of a fence per region. No new vocabulary
enters the corpus, because the markers and the inheritance rule the key addresses already exist and
are already load-bearing.

### Two facts a smaller-looking reading would hide

**The version bump is load-bearing precisely because nothing visibly changes.** A reader comparing the
two guided forms before and after will find them byte-identical and may conclude the bump is
ceremonial. It is what lets a v1-only skill detect that it is reading a shape it does not understand,
instead of reading a form-global writer and writing anywhere.

**The coverage figure and the exclusion price are different numbers about different things.** 67.7 %
is what a wholesale exclusion of block-owned surfaces would cost. 8.1 % is what this record's actual
exclusion costs. Attaching the first to the second overstates the price of decision 6 by roughly
eightfold.

### The honesty constraint

**This record establishes a falsifiable prediction, not a demonstration, and it cannot do otherwise.**
A decision record runs nothing; there is no conformant consumer to price against — measured above,
the fence occurs once in the corpus and that occurrence is the deciding record's own worked example;
and conformance for this surface is cut *after* this record closes. Nothing here should be read as
evidence that the contract's generality has been demonstrated on a dissimilar form.

**Where the prediction gets tested.** In the first build slice that makes the trip form a conformant
consumer — the slice that authors the fence into the template, teaches the interviewer decision 3's
pre-write predicate, and lands decision 5's discovered-region arm with both its control arms. That
slice grades the nine-row table row by row. A row whose realized verdict differs from the prediction
above falsifies this record's reading of that row, and is a finding about this record rather than a
defect in the slice.

**The prior record's own honest residual stands unchanged and is restated rather than softened:** the
contract makes conduct free and leaves classification exactly as expensive as it was. Nothing here
removes a classification row, and for this artifact that is a row for nearly every label it carries.

### Reversibility summary

**EXPENSIVE · confidence MEDIUM.** A published contract is a thing forms build against; reversing it
re-opens every conformance that assumed it, and an Accepted record here is immutable as to its
decisions and supersede-only. Two properties deliberately lower the cost of being wrong without
lowering the tier: decision 1's degenerate case means a reversal does not churn the shipped forms, and
decision 6's conditional form means the one change most likely to arrive — an owner for the derived
blocks — executes this record rather than amending it.

## Residuals

| Id | Residual | Owner |
|---|---|---|
| **R1** | The conformance arm the prior record specifies has not shipped. Decision 5 designs against a *specified but unbuilt* arm, and takes it as a named dependency rather than a blocker | the build slice that makes the trip form a conformant consumer |
| **R2** | The mode fields are invisible to the contract's field key regardless of ownership, because they are not bullets. Decision 1's key does not fix this and does not claim to | declared limitation of this record; no owner required, and it is row 2's second independent ground |
| **R3** | Classification rows remain the irreducible cost — one per new label, which for this artifact is nearly every label it carries | the data model, as the prior record already states; unchanged here |
| **R4** | A region whose writer varies by something the resolution contract does not return is undecidable under decision 1's key and falls to decision 6's clause. No such region exists today; the rule is stated so the first one is routed rather than improvised | the build slice that first encounters one |
| **R5** | The nine-row table is a prediction and no gate grades it until the consumer slice lands. Until then a wrong row is invisible | the consumer slice, which grades it row by row |

## References

- [`README.md`](README.md) — the ADR convention, the status lifecycle, and the amendment clause
  whose permitted-acts list is decision 6's ground
- [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) — the governing prior record:
  the one-fence rule this record generalizes, the six conformance questions, the declaration-points-
  never-copies rule, the version axis, the must-fire negative arm, and the scope call that named this
  surface the first consumer after
- [`ADR-022`](ADR-022-interview-session-model.md) — the session model. This record decides no conduct
  and no session behaviour; that is this record's boundary with it
- [`ADR-019`](ADR-019-discriminating-evidence-rule.md) — the standard decision 3's must-fire arm and
  decision 5's control arms are written to
- [`ADR-013`](ADR-013-count-assertion-basis.md) — the convention every count in this record is
  authored to; the measurements here are anchored to a named commit and their arithmetic is
  reconciled inline
- [`ADR-007`](ADR-007-command-entry-point.md) — the command surface whose verbs the writer table names
- `CLAUDE.md` § *Write ownership* — the nine-row per-block writer table this record partitions, and
  the inheritance rule decision 2's extent expression reuses
- `templates/trip-context.template.md` — the block-owned surface every measurement in this record is
  taken over
- `scripts/test-artifact-schema.sh` — the suite decision 5's arm lands in, and the source of the
  any-fail reduction and strict-skip constraint that binds decision 6

## Follow-on build slices

1. **The consumer slice** — author the fence into the trip-context template, carrying the region key
   as an address into the writer table. Grades the nine-row table and either reproduces or falsifies
   it.
2. **The interviewer slice** — decision 3's pre-write region-membership predicate in the interviewer,
   with its refusal.
3. **The assertion slice** — decision 5's discovered-region arm, with its sensitivity arm and its
   must-fire negative arm, and decision 6's declared-and-reported exclusion.
4. **The version slice** — the `form-version:` branch in the conformance arm, so a v1-declared form
   and a v2-declared form are graded on their own question sets.
