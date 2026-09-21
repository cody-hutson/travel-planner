# ADR-024: The channel architecture — what a channel is, the channel-set, what each may carry, and the crossing model

- **Status:** Proposed (2026-09-21)
- **Deciders:** repo maintainer
- **Driving work:** the architecture slice of the *traveller journey* milestone. This record is
  that milestone's **head decision gate**, in the shape `ADR-012-people-library.md`,
  `ADR-016-reusable-groups.md` and `ADR-021-installable-capability.md` already ship: it lands
  before any feature slice and settles the cross-cutting question each of them would otherwise
  answer separately — what a channel *is*, and what may cross one.
- **What this record is.** A decision about **how a traveller is reached**. `ADR-009` and
  `reference/data-architecture.md` govern what the engine *knows*; § 5.1 of that reference
  answers *what may be carried where* with a closed four-value class enum that every artifact
  resolves against. There is no counterpart for reach. The published site came from one trip,
  the approval transport from one need, the intake form from one template. Each is
  architecturally sound alone; none was designed against the others, and no tracked file states
  what a channel is or what one may carry.
- **What this record is not.** It **widens nothing**. Every carry verdict it returns is the
  verdict the shipped publish guard already returns, because the denial half of its predicate
  *is* that guard's own declared fence, read rather than re-declared. `internal-hard` is
  unwidened; `ADR-006`'s third-party prohibition is unwidened; `ADR-002`'s no-standing-server
  constraint is upheld and no supersession is proposed. It also selects **no approval
  mechanism** — the inbound approval return is recorded as a typed vacancy and remains #718's.
- **Scope taken from #718, and scope left there.** #718's own body criticises its predecessor
  for *specifying a verifier before knowing the channel — solves step two first*. Choosing the
  approval channel before defining what a channel is commits that same error one level up. This
  record takes the **channel-roster half**; #718 retains every approval-specific decision.
- **The status flip is named here, because nothing grades it.** Moving this record from
  `Proposed` to `Accepted` is the maintainer's, taken at this milestone's close, and it moves
  **both** halves of a two-artifact state: the `Status:` line above, and this record's `Status`
  cell in `reference/adr/README.md`. No required check here grades either half or their
  agreement, so the obligation travels with this line rather than with a gate — the same
  two-step `ADR-010` and `ADR-019` each used, and the same divergence `ADR-021` repaired when a
  predecessor's file was flipped and its index cell was left behind.

## Context

**The absence is measurable, and it is an absence of a *definition*, not of machinery.** Across
the 156 tracked files at the baseline below, `channel` occurs on **82 lines in 14 files** and
not once as a definition. It carries three unrelated senses: an internal record stream
(`scripts/test-command-taxonomy.sh`, the largest single concentration, with no person involved);
an information-egress surface (`CLAUDE.md`, `skills/trip-publish/SKILL.md`); and a
human-carried path (`ADR-003`, `ADR-010`, `ADR-014`, `README.md`,
`scripts/publish-trip-site.sh`). The word is doing three jobs and arbitrating none of them.

**Four surfaces carry a person on the far side, as of `edadfa9`.** The published site, the intake
surface, the command surface, and the approval transport. Three of the four are governed in
detail and the fourth is a declared placeholder — `ADR-010` states, in terms, that *"'Out-of-band' is a
placeholder"* (`reference/adr/ADR-010-per-traveler-approval-collection.md`:230), inherited
unimproved from `ADR-003` § *Decision 2*. What no record states is whether these four are the
same *kind* of thing.

**Three consequences follow today, and they are not one consequence.** Whether the site may
carry traveller-attributed content is inherited from a class calibrated to the plaintext limb.
Which channel carries an approval, and what a traveller does in it, was scoped when messaging
was the only channel in question. Whether an interview may be conducted by voice is a channel
property decided inside one phase. Each is a reach question answered locally.

**The rule that should arbitrate has no home.** *The engine never invents* is restated
independently in `ADR-015` §§ 6–7 and in three open slices, and the restatement count across
the corpus is the signature of a missing layer rather than of emphasis. A rule with eight
authors has no arbiter.

**What this record composes against, and what it does not.** It composes against
`reference/data-architecture.md` § 5.1's artifact-class enum, § 5.3's two-granularity union,
and § 5.6's declared `publish-contract-values` fence with its four queried
`(limb, artifact-scope)` pairs. It depends on **nothing in § 5.2**, whose field-classification
half is a declared gap; closing or not closing that gap changes no decision here.

**The axis this record indexes on already ships, unnamed.** `agents/00-enrichment.md`
§ *Missing or blank profile* assigns **every** roster member one of a small set of branches and
writes the result into `outputs/traveler-model.md`; `:891-894` names the domain in the corpus's own
words — *"the same roster you already take as the party and as the profile-gap denominator."* So
the question this record's reach table faced was never *choose an index*. It was **declare a
join** to a classification the engine already computes,
and give it a name. The name is decided in § *Decision* 6 under a measure-before-adopting
constraint, and every identifier this record mints carries its measured collision inline.

**Baseline.** Every corpus fact in this record was read live at `edadfa9`, the merge of
pull request #1187. Census probed at `edadfa9`: **156** tracked files, **137** tracked
`md`·`sh`·`html`, **130** tracked `.md`, **24** under `reference/schemas/`. Counts are authored to `ADR-013` form **F1**
(anchored measurement); the measurement convention is stated once in § *Decision* 6 and holds
for every count in this record.

## Decision drivers

- **A definition must be able to refuse a candidate.** A definition that admits everything
  proposed to it is decoration. The test in § *Decision* 1 changes one of the three answers the
  driving card assumed, and adds a fourth candidate the card did not have.
- **Reuse the composition rule the corpus already has — including its granularity.** § 5.3
  settled *per-artifact versus per-field* as **both, composing by union, never by override**,
  and its own second sentence predicts what happens to a model that borrows the union and drops
  the granularity: *"A per-field-only model cannot express an entry-scoped denial, and a
  per-artifact-only model cannot express a single non-publishable field inside a publish-bound
  artifact."* Two successive drafts of this record's carry rule dropped the granularity and
  each had to hand-carve the one denial it most needed. The fence already computes it.
- **Name the object that actually crosses.** A carry rule that names the build's *inputs* is a
  rule about the build, not about the crossing. The object that crosses CH-1 is neither the
  `bound` artifacts § 9.1 names nor the local render.
- **Type the arity before typing the subject.** Both defects this record's carry rule went
  through were the same defect: a **relation** typed as a **property**. Re-typing the subject
  while leaving the arity wrong relocates a defect one layer along instead of closing it.
- **Fail closed, and keep fail-closed where the corpus puts it.** Every enforcement surface
  here resolves an unknown against the guarded reading — § 5.4's five UNDETERMINED paths,
  § 5.6's sixth, `verify_ciphertext`, `ADR-007` § 2. But fail-closed is a property of the
  **call site**, not of the predicate: `verify_publishable_content` is three-valued precisely so
  that a HIT stays distinguishable from an UNDETERMINED, and the call site collapses both into
  one abort. A model that makes an undefined limb *mean* deny has moved the guarantee into the
  wrong layer and cannot express § 5.4's own requirement that *"a parsed-and-empty class must
  stay distinguishable from a class that could not be computed."*
- **Build the axis; assert nothing on it.** `internal-hard` holds. Its widening is #1242's, for
  one channel, and this record's answer does not widen it.
- **Measure a name before minting it.** An unmeasured identifier is not a proposal. Three
  identifiers proposed during this record's design were withdrawn on measurement, one of them
  after a measurement the design had not taken.
- **Decide what the evidence supports and no more.** Where the evidence runs out — at the
  inbound approval return, and at the crossing artifact's missing class — this record **types
  the gap** rather than filling it, and records it as a finding rather than assuming it away.

## Options considered

Release class `novel`; each of the six decisions carries its own option set and none are merged.
Every rejection is grounded on a corpus fact read live at `edadfa9`, and the option sets include
the genuine null option where one exists. Three options below are marked **withdrawn** rather
than rejected: each was recommended by an earlier pass of this design and lost to a measurement
or a counter-example taken afterwards. They are recorded with their reasons, because a later
reader must be able to see that the option was held and why it fell.

### Decision 1 — What a channel is

**Option 1A — any surface on which engine content meets a person.** **Rejected.** It has no
refusal power: nothing proposed to it is ever *not* a channel, so the set cannot be closed and
*what admits a fourth* has no answer. A definition that cannot refuse is a restatement of the
question.

**Option 1B — a transport the engine does not control.** **Rejected, instructively.** It excludes
the published site — the surface this repository has the most machinery for — and it inverts the
interesting property. A channel-set exists to state what may cross; a surface the engine does not
control is precisely the one about which nothing can be stated.

**Option 1C — refuse to define; decide carry per artifact; close the question as mis-framed.** The
genuine null option, and it is rejected on two grounds rather than dismissed. First, `publish:` is
defined **against the render** — § 5.1's own vocabulary is *"never rendered"* and *"a rendered
page"* — so it is silent on every surface that renders nothing, which is two of the three members
below. Second, *the engine never invents* is restated independently across the corpus with no
single home, and a rule restated by many authors with no arbiter is the signature of a missing
layer, not of emphasis.

**Option 1D — a three-limb test, with the crossing point as the discriminating limb.**
**← RECOMMENDED.** Stated in § *Decision* 1. It refuses two of the four candidates in hand, which
is the property 1A lacked, and it resolves the three shipped senses of `channel` with no rename.

**Option 1E — rename the concept to *reach surface*, leaving `channel` to its existing senses.**
**Rejected on measurement.** Probed at `edadfa9`, `reach` occurs on **470 lines in 81 files** of
156 — it would trade an 82-line overload for a 470-line one — and it is additionally a closed-enum
value in `ADR-012`. The adopt-and-disambiguate path in 1D costs one paragraph; the rename costs a
reference cascade over every file carrying the token, and lands on a worse one.

**Withdrawn from an earlier pass of this design: the claim that the egress sense and the
human-carried sense *contradict* each other on the passphrase.** Read live,
`skills/trip-publish/SKILL.md`:319-323 scopes its standing rule to **the command** — *"the object
of this rule is the value, not the path"* — while `scripts/publish-trip-site.sh` addresses **the
operator**. Two statements about different agents are not a contradiction, and the corpus states
the reconciliation itself at `:249-252`: *"Both statements are true; they are about **different
objects**, and the file's error was letting one answer the other's question."* The **overload** is
real and remains the reason a definition is needed; the **collision** was manufactured. This
strengthens 1D rather than weakening it — the discrimination method 1D uses is the one the corpus
already applies to itself.

### Decision 2 — The channel-set, and what admits a fourth

**Option 2A — the surfaces the driving card named — site, approval transport, interview.**
**Rejected by Decision 1.** It seats a member whose carry cell cannot be filled, because the
approval transport fails L2 against a declared placeholder. That is the *step-two-first* error the
card itself diagnoses one level up.

**Option 2B — two members; the approval transport as a vacancy.** **Rejected as incomplete.** With
only the site and the intake surface, the operator-mediated inbound path is nowhere represented,
which claims two subject kinds are unreachable in a sense stronger than the corpus supports and
hides where their data actually comes from.

**Option 2C — three members plus one *undivided* vacancy.** **Withdrawn.** It over-determines a
declared placeholder and mis-sizes what #718 inherits. Both halves were confirmed live: the
outbound notice is already shipped by an Accepted clause, and the inbound return's L2 is
`UNDETERMINED` rather than determinately false.

**Option 2D — index the set by direction.** **Rejected on an inherited constraint.**
Directionality is deferred for this milestone, and a set keyed on direction is an input-path model
in all but name. Direction is a **column** here, never the key.

**Option 2E — three members and two typed vacancy rows, one of them discharged.**
**← RECOMMENDED.** Stated in § *Decision* 2. Splitting the vacancy matters rather than being a
nicety: undivided, a later reader could conclude that *no approval content may cross to a
traveller on any channel*, which contradicts a shipped Decision clause of an Accepted record.
Recording the discharged half is also what stops #718 re-deriving it.

### Decision 3 — What each channel may carry

**Option 3A — carry is a property of the channel.** **Rejected.** It contradicts a shipped fact
that `scripts/test-artifact-schema.sh` group `PB` already asserts in both directions, and it
re-homes a decision that has a home in § 5.1.

**Option 3B — carry is a property of the artifact; no channel axis.** **Rejected.** `publish:` is
written against the render and returns no verdict for the two members that render nothing.

**Option 3C — the pair, enumerated as a matrix.** 23 in-model classes × 3 channels. **Rejected.**
It is a second home for § 5.1's assignment, and a second home drifts from the first. § 5.3's own
title is *computed, never enumerated*.

**Option 3D — the pair as a two-sided conjunction of the artifact's `publish:` class and the
channel's declared reach.** **Withdrawn, and it had to be withdrawn rather than repaired**, on
three findings each verified live. Its limb 1 was the very operand it used to reject 3B, so under
a fail-closed reading it would make the two non-rendering members carry nothing — contradicting
this record's own reach table. It never named the artifact that crosses, and so stated no verdict
for the site at all. And it hand-carved the one denial § 5.6's fence already computes, which was
the tell that the granularity had been dropped.

**Option 3E — a denial computed from § 5.3's union at both granularities, conjoined with the
channel's declared envelope.** **← RECOMMENDED, and the recommendation survived a re-typing that
the first form of it did not.** As first written, 3E made the denial's subject a bare **value**,
on the reasoning that a value-scoped subject is what makes the rule defined on the two
non-rendering members. That reasoning does not hold, and the corpus says why in one sentence:
§ 5.2 at `:779-780` states the shipped fence *"does **not** inherit — it carries one row per field
**per artifact scope**, so a passport value is non-publishable in C3 **and** in C12 by **two
rows**, not from a single declaration carried into both."* A model whose subject is a value cannot
express *the same value, a separate row per scope*. The fence is keyed
`(limb, artifact-scope)` by construction, and § 5.6 at `:829` names the arity outright — *"The
evaluator asks exactly **four** `(limb, artifact-scope)` questions."*

So the recommendation stands and its **typing** changed: the denial is a **relation**, not a
property, on both sides. Both of this rule's rejected drafts were the same defect — a relation
typed as a property — and re-typing the *subject* while leaving the *arity* wrong relocates the
defect one layer along rather than closing it. The corrected clause is § *Decision* 3.

### Decision 4 — How a traveller is reached at each phase

**Option 4A — index the reach table on the planner's five modes.** **WITHDRAWN, and recorded as
withdrawn with its reason**, because a later reader must be able to see it was held. An earlier
pass recommended it as a working default on a build-order argument, while that same pass's own
seam table priced the re-index at **zero** for two of the three members and *"not indexed on any
phase axis"* for the third. **An index no cell varies with is a column header, not an index.** The
jurisdiction question was then measured independently across every per-verb requirement table in
the corpus: of **38** verb rows, **6** name a mode and all six are `/trip` synthesis verbs, **30**
read `any`, and **2** do not read mode at all. **Not one verb that reaches a person gates on
mode** — `/trip-publish update`, the verb that puts the site in front of a traveller, is
`mode: any` at `skills/trip-publish/SKILL.md`:202, and all 22 `/trip-record` verbs are
`mode: any`. Mode has no jurisdiction over the subject, so it cannot be the index whatever its
cardinality.

**Option 4B — index on publication state and lifecycle instead.** Its **substance** is adopted;
its **form** is not. These are **conditions**, not an index: publication state governs the
published site alone, and indexing all rows on it would leave the other two members indexed on an
axis silent about them. Promoted from a second column on one row to a first-class condition.

**Option 4C — wait for the sibling record's axis and index on that.** **Rejected.** It converts a
stated seam into a blocking dependency between two records the plan declares parallelizable.
Superseded in any case: the axis was decided jointly, which is what the option was reaching for.

**Option 4D — (subject kind × channel), no phase columns, resolved against three named
conditions.** Adopted **with one measured amendment**, which is 4E.

**Option 4E — the same, with the third condition replaced by a declared join plus the
read-failure arm.** **← RECOMMENDED.** The finding that forces it: the axis values and this
record's subject kinds stand in a **one-to-one correspondence** on all five of the values this
record carries. A condition in one-to-one correspondence with the row key **is** the row key under
another name, and carrying it as a third column would reproduce *an index no cell varies with is a
column header* inside the very clause written to repair that defect. The repair preserves the
substance in full and drops the degeneracy: the two records are declared to index **one partition
under two names, joined on the row key**, and what the axis genuinely contributes is its **sixth
value** — the read-failure arm, which has no subject-kind counterpart. That is a real condition,
and it is carried as a **table-level fail-closed clause** rather than as a row or a column,
because a value meaning *the row could not be selected* cannot modify a row.

### Decision 5 — The read/write asymmetry per channel

**Option 5A — one invariant, channel-independent.** **Rejected.** It cannot express the
intersection case, and it gives a reviewer nothing to check on any particular channel.

**Option 5B — genuinely per-channel invariants.** **Rejected.** It is what the corpus does today,
and the result is the same rule restated by eight authors with no arbiter.

**Option 5C — two rules, both channel-level; the observable test per channel.**
**← RECOMMENDED.** Stated in § *Decision* 5. `ADR-015` clause 7 sits at the intersection — a
report line is an engine→human **emission** whose prohibition exists to protect **authorship** —
which is why that record needed a subsection titled *"Why clause 7 is not a carve-out."* Under a
one-rule model that subsection is unexplainable, which is the positive evidence for two.

**Option 5D — fold both rules into the carry rule and the existing `writer:` field.**
**Rejected.** `writer: human` says who may write the **file**. It says nothing about whether an
engine-composed *question* may supply the answer the human types, which is the whole of the
failure the write rule exists to prevent. Authorship of content and authorship of a file are
different objects.

### Decision 6 — The names

The option set here is a measurement, not an argument, and it is reported in § *Decision* 6 with
its instrument stated. Three candidates carried by earlier passes of this design were
**withdrawn on measurement** rather than on taste, and one was withdrawn on a measurement no
earlier pass had taken. One further candidate was rejected on a structural property rather than a
count: a token that is a **prefix of another token in the same set** cannot be measured
independently of it, which is a defect in the set rather than in either name.

## Decision

### 1. A channel is a surface satisfying three limbs

> A surface is a **channel** when all three hold:
>
> - **L1** — a person is on the far side.
> - **L2** — the engine governs the crossing, via a named engine-side act declared in a tracked
>   file.
> - **L3** — the crossing point is **guardable**: a single place where a predicate can be
>   evaluated **before** content crosses.

L3 is the discriminating limb, and it is what makes the definition able to refuse. Applied to
every candidate in hand:

| Candidate | L1 | L2 | L3 | Verdict |
|---|---|---|---|---|
| The published site | yes | yes — `/trip-publish`, and the build | yes — the pre-push guard; `ADR-008`'s two limbs | **channel** |
| The intake surface | yes | yes — the artifact write | yes — `scripts/validate-artifacts.sh` + the schema suite | **channel** |
| The command surface | yes — the operator | yes — every verb | yes — `ADR-007` § 2's six bounds, per-verb `allowed-tools` | **channel** |
| The **inbound approval return** | yes | **UNDETERMINED** — the transport is a declared placeholder | undecidable against a placeholder | **not a member — a typed vacancy** |
| An internal record stream | **no** | — | — | **not a channel** |

**The three shipped senses of `channel` resolve with no rename.** The internal record stream fails
L1. The human-carried sense — *"their own channel"* — fails L2 and is an **operator-mediated
crossing**, not a channel. The egress sense is not a competitor at all: it is this model's own
`observers` axis, named in § *Decision* 3. **No edit is required to `ADR-003`, `ADR-010`,
`ADR-014`, `README.md`, `scripts/publish-trip-site.sh`, `CLAUDE.md` or either skill**, and none is
made.

### 2. The channel-set is three members and two typed vacancy rows, one of them discharged

| id | Channel | Far side | Direction | Crossing point / guard |
|---|---|---|---|---|
| **CH-1** | The published site | a passphrase-holding traveller | engine → traveller | the publish step; `verify_ciphertext` on the encrypted limb, `verify_publishable_content` on the `--plaintext` limb |
| **CH-2** | The intake surface | the traveller themselves | traveller → engine | the artifact write; `scripts/validate-artifacts.sh` + the schema suite |
| **CH-3** | The command surface | the **operator** | operator ↔ engine | the verb invocation; `ADR-007` § 2's six bounds, per-verb `allowed-tools` |
| **V-1** | *approval notice, outbound* | *a traveller* | *engine → traveller* | **DISCHARGED — it crosses on CH-1.** `ADR-003` § 3 ships it: *"The published site shows a **'change pending / recently updated' state on next open**"* (`:53`) |
| **V-2** | *approval return, inbound* | *a traveller* | *traveller → engine* | **VACANCY. L2 UNDETERMINED** — `ADR-010`:230, *"'Out-of-band' is a placeholder."* This is #718's work |

**Why the vacancy verdict survives its own re-typing.** The admission test requires all three
limbs to **hold**, and a limb that cannot be evaluated does not hold. So the approval transport is
not a channel-set member under either reading. What changed is the **ground** — `UNDETERMINED`
rather than determinately false — and the **scope**: only the inbound return is vacant.

**V-1's discharge stands on a schema-declared field pair, not on an unchosen candidate.** The
coordination state is carried by two `optional` per-class fields of the crossing artifact's own
schema (§ *Decision* 3), whose declared purpose at `reference/schemas/travel-site.md`:32 is *"the
coordination state ADR-003 § Decision 3 makes pull-based"*, with
`reference/site-layout-spec.md` § 3's Coordination Notice named there as the consumer whose
three-way branch *is* the state, and with regression coverage in
`scripts/test-publish-guard.sh` group `T`. **`ADR-010`'s Candidate C is deliberately not cited
here.** That candidate describes **inbound** token production, `:248-251` records it and its
sibling **as candidates** — *"Choosing between them requires the channel"* — and V-1 is the
**outbound** notice. Leaning on it would borrow a candidate for the half it does not address, and
under the discharge above V-1 does not need it. It is left where it is, for #718.

**What admits a fourth member.** All four must hold: **(1)** L1–L3 of § *Decision* 1; **(2)** its
`audience` and `observers` values declared in the same change; **(3)** its `W-test` and `R-test`
declared in the same change; **(4)** admission by **amendment to this record or by a superseding
record** — never by a slice, and never as a side effect of building something.

### 3. Carry is a relation, not a property, on both sides — and each side is typed over the artifacts its guard actually queries

> **`may-carry(v, A, CH) = ¬denied(v, A) ∧ carry-envelope(CH) admits v`**
>
> **`denied(v, A)`** is `reference/data-architecture.md` § 5.3's union — *"non-publishable class =
> { every value of a field declared `non-publishable` } ∪ { every value of an entry whose
> `provenance` is `third-party` }"* (`:786-787`) — read from § 5.6's `publish-contract-values`
> fence and **from nowhere else**, and **defined only on the four `(limb, artifact-scope)` pairs
> that fence's evaluator queries**: `entry` and `field` against `outputs/traveler-model.md` (C12),
> and `field` against `travelers/<traveler>.md` (C3) and `people/<person>.md` (C22). It is
> **three-valued**:
>
> | Return | When |
> |---|---|
> | **HIT** | `v` is a value of a field or entry the fence marks at a queried pair |
> | **CLEAN** | the pairs were queried and `v` is not in the class |
> | **UNDETERMINED** | the class could not be computed (§ 5.4's five paths, § 5.6's sixth), **or** `A` is not a queried pair — § 5.6's declared gap, *"A row naming any other pair is presently a code change… the guard aborts the publish as UNDETERMINED"*, graded by `scripts/test-publish-guard.sh` case **L10c** |
>
> **Off the four pairs `may-carry` returns UNDETERMINED — not `admit`, and not `deny`.**
> Fail-closed is preserved where the corpus puts it: at the **call site**, which collapses HIT and
> UNDETERMINED into one abort (`scripts/publish-trip-site.sh`:2679-2680, whose message names both
> causes — *"carries content that must not be published, **or** the non-publishable class could
> not be determined"*). A channel with no publish call site inherits no verdict from this model
> and takes its bound from its own rule.
>
> **`carry-envelope`** is the channel's declared (`audience`, `observers`) pair. A denial from
> either side is dispositive; **neither side overrides the other.**
>
> **CH-1 — what crosses, and what the guard asserts.** The object that crosses is the
> **published artifact `P` at `<trip_dir>/.publish/index.html`**
> (`reference/site-layout-spec.md` § 8:671-673; `scripts/publish-trip-site.sh`:2666). **`P`
> carries no § 1.1 artifact class** — recorded as a finding of this release in § *Findings
> carried*, not assumed away. The local render **C19 stays local and git-ignored** (`:670`,
> *"Source file (plaintext, stays local, git-ignored)"*) and is the **second operand** of CH-1's
> guard, never its subject.
>
> | CH-1 limb | Predicate (declared at) | What it asserts |
> |---|---|---|
> | encrypted (default) | `verify_ciphertext(P, C19, boilerplate)` — declared `scripts/publish-trip-site.sh`:2232, contract `:2214` | `P` is verified ciphertext **of** C19 — a structural near-empty-visible-text proof plus a token backstop; *"MUST be FAIL-CLOSED: return 0 only when the output is provably safe"* (`:2210-2211`) |
> | `--plaintext` (`ADR-008` opt-out) | `verify_publishable_content(C19, trip_dir)` — declared `scripts/publish-trip-site.sh`:**1924**, contract `:1906-1914` | no value of the class computed over the four queried pairs in `trip_dir` appears in the render, which this limb then copies to `P` byte-for-byte (`:2687`) |
>
> Both are **relations**. `verify_ciphertext`'s self-check at `:2237` makes the point
> unarguable — *"never certify the source file as its own ciphertext"* — so a model naming C19 as
> the crossing object names the operand the guard exists to hold `P` **apart from**.
>
> **`P`'s content, stated as a composition rather than a subtraction.**
>
> **`C19 = render(C1, C10, C11, C13, C15) ⊎ { coordination-state, coordination-since }`**, and
> **`P = StatiCrypt(C19)`** on the encrypted limb, **`P = C19`** on the `--plaintext` limb.
>
> - The `bound` artifacts § 9.1 names are the build's **read set**, not its carried content.
>   `reference/schemas/travel-site.md`:37 says so directly: the `publish-contract-artifacts`
>   fence *"is a declaration of which artifacts the site build may **read** — not of what a
>   render carries."*
> - **`coordination-state: optional enum [none|pending|updated]`** and **`coordination-since:
>   optional date`** are C19's own **per-class schema fields**
>   (`reference/schemas/travel-site.md`:28-29), not a render of any `bound` input. They are what
>   carries V-1's outbound notice inside the bytes that were pushed.
> - **There is no `minus denied(v)`.** No redaction step exists anywhere on the publish path —
>   the guard **aborts the whole publish** (`|| die`, `:2680`), and § 5.5 disclaims the
>   capability a subtraction would imply: *"Keying the guard to a declared attribute makes the
>   class **sourced**, not **complete**."* The R-test is an **abort gate over the whole
>   artifact**, never a filter that removes values from it. A slice reading *minus* would build a
>   redaction step this corpus does not have.
>
> **CH-2 and CH-3.** No render, no queried pair — so `may-carry` is **UNDETERMINED** and this
> model asserts nothing about them. Their bounds exist and come from elsewhere: CH-2's is the
> **W-rule** of § *Decision* 5, an authorship rule that needs no denial set at all; CH-3's is
> `ADR-007` § 2's privilege boundary. **Widening § 5.6's fence to reach them is out of scope for
> this record** and would close, by fiat, a gap § 5.6 keeps deliberately visible.
>
> **Still inert.** Every verdict this clause returns at `edadfa9` is the corpus's own, because
> `denied` **is** the shipped fence read rather than re-declared, and the queried-pair
> restriction **is** the shipped evaluator's. `internal-hard` is unwidened — it remains
> *"never rendered **and** carrying values that must not reach a rendered page **in any form,
> including anonymized**. Exactly C12, C14, C22 and C23"* (`reference/data-architecture.md`:770).
> **#1242 is the only card that may move a cell.**

**Why three-valued does not weaken fail-closed.** The corpus's own shape is a **three-valued
predicate with binary fail-closed enforcement at the call site**, and it says why in terms:
*"Three return codes where `verify_ciphertext` has two, because the test suite has to be able to
tell a HIT from an UNDETERMINED: under a binary contract a guard that aborted for the WRONG REASON
would still pass its own tests. The call site collapses both to one die, so `cmd_publish`
behaviour stays binary; only the tests read the distinction."* An earlier draft of this clause
collapsed those two layers and concluded that an undefined limb must *mean* deny. It does not. It
means the model returns no verdict, and the call site — where there is one — refuses. § 5.4 at
`:809-811` requires exactly this separation: *"A parsed-and-empty class must stay distinguishable
from a class that **could not be computed**."*

**Every fail-closed path survives, and this clause adds two.** § 5.4's five UNDETERMINED paths are
untouched and are now quoted in this record's own support. § 5.6's sixth — an unreadable or
zero-row fence returns `2` and the publish aborts — is untouched. `verify_ciphertext` is
untouched and is, for the first time, named as the relation its own contract declares.
`ADR-007` § 2 is untouched. **Added:** § 5.6's declared-gap clause — the unqueried-pair abort — with
its shipped test case `L10c`, and `verify_publishable_content`'s three-code contract with the
call-site collapse.
The clause **removes no fail-closed path**. The one thing it removes is an inference the corpus
does not license.

**The two channel axes, declared worst-case.**

| Axis | Values | What it states |
|---|---|---|
| **`audience`** | `operator` · `party` · `world` | who can **read** the content |
| **`observers`** | `none-beyond-audience` · `third-party` | who can **see the bytes**, whether or not they can read them — the corpus's egress sense, named |

| Channel | `audience` | `observers` | Why |
|---|---|---|---|
| **CH-1** encrypted limb | `party` | `world` | the ciphertext sits in a **public** repository and is world-fetchable |
| **CH-1** `--plaintext` limb | `world` | `world` | the opt-out from the privacy default (`ADR-008`) |
| **CH-2** | `party` | `third-party` | worst case is an interview conducted through an assistant whose history retains the transcript |
| **CH-3** | `operator` | `third-party` | the same worst case — which is why `skills/trip-publish/SKILL.md`'s standing rule on the passphrase **value** exists |

**The residual, stated rather than smoothed over.** An inert axis is a shape a later reader could
mistake for a permission. The mitigation is this sentence: **#1242 is the only card that may move
a cell, and it moves one.** That is the same device § 5.6 already uses for the tombstone it
records so that nobody re-derives it.

### 4. Reach is one crossing or two, and the engine's claims are about the first only

**The subject set is five,** and the arbiter is live rather than negotiated. `CLAUDE.md`:123-133
states *"Erasure must reach every model-entry class, and there are **exactly three**"* —
`first-party`, `operator-provided-only` (**dropped** under regeneration, having no source to
re-derive from) and `both-marks` (**carried forward verbatim**, the erasure silently undone) —
adding that *"the two file-less classes fail in **opposite** directions."* Those three, plus the
roster-only and the cross-trip-composed states, yield five:

| Subject kind | What the engine holds | `CLAUDE.md`:123 class |
|---|---|---|
| **K1** | a trip traveller file **and** a durable person record reached through `person:` | `first-party` + C22 |
| **K2** | a trip traveller file | `first-party` |
| **K3a** | a C12 entry marked `[OPERATOR-PROVIDED]` alone | `operator-provided-only` |
| **K3b** | a C12 entry marked `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` | `both-marks` |
| **K4** | a roster row, and nothing sourced — see the arms below | — |

**The axis declaration.** The engagement axis is decided in the sibling record and is **joined**
here rather than re-derived. The fence below is the declaration both records are graded against;
it is the corpus's own declared-set device, which already ships in seven instances
(`publish-contract-values`, `publish-contract-artifacts`, `count-assertion-digest`,
`frozen-witness-digest`, `horizon-verdict-cases`, `trip-contract-evidence`,
`trip-contract-header`).

```phase-axis-declaration
# axis-orientation: rows
# axis-name: engagement
# governed-table: Decision 4 -> "The reach table"
# row-key-column: 1
# header-rows: 2
# difference-from-engagement-record: ENGAGEMENT-UNDETERMINED
# subject-kind   axis-token
K1               PERSON-LINKED
K2               SELF-STATED
K3a              OPERATOR-STATED
K3b              THIRD-PARTY-STATED
K4               UNSOURCED
```

Two columns, both required, whitespace-separated; a line whose first non-blank character is `#` is
a comment and is ignored. The fence declares **five** axis tokens. **`axis-orientation: rows` is
load-bearing and is why no leading-column count appears here:** the axis tokens are **row keys**,
so a comparator extracting column *headers* would read this table's direction labels and diverge
on a conformant record. A superseded specification of this criterion instructed a leading-column
count, which presupposes the column orientation the axis decision deleted; it is deliberately not
carried, and `row-key-column` with `header-rows` is its orientation-correct analogue.

**The difference from the sibling's set is named, and it is exactly one token.** The engagement
record declares **six** tokens; this record declares **five**; the difference is
`ENGAGEMENT-UNDETERMINED` **and nothing else**. That token is this record's **read-failure**
value, and it is carried **as a table-level fail-closed clause below the reach table — not as a
row and not as a column.** That is what makes the difference a legitimate subset relation rather
than an omission.

**Why the axis enters through the row key rather than as a third column.** Its five values stand in
a **one-to-one correspondence** with the five subject kinds above — `K4 ≡ UNSOURCED`,
`K3a ≡ OPERATOR-STATED`, `K3b ≡ THIRD-PARTY-STATED`, `K2 ≡ SELF-STATED`, `K1 ≡ PERSON-LINKED` —
because addressability is a property of the subject and the rows **are** the subjects. A column in
one-to-one correspondence with the row key is the row key under another name, and this record's own
§ *Options considered* 4A rejects a column no cell varies with. So the two records are declared to
index **one partition under two names, joined on the row key**. The agreement is therefore
**structural** — a single partition declared in both — rather than two records having been handed
the same string.

**The reach table.** Row keys are compound: the subject kind and its axis token, either side of
the `≡` marker, both declared in the fence above. **No phase columns.** The cell grammar splits
because the far sides differ.

| Subject kind | in — *first crossing* | in — *subject crossed?* | out — to the subject |
|---|---|---|---|
| **K1 ≡ PERSON-LINKED** | **CH-2**, direct | **yes** | **CH-1**, iff published |
| **K2 ≡ SELF-STATED** | **CH-2**, direct | **yes** | **CH-1**, iff published |
| **K3a ≡ OPERATOR-STATED** | **CH-3**, operator-mediated | **never crossed** | **none** |
| **K3b ≡ THIRD-PARTY-STATED** | **CH-3**, operator-mediated | **never crossed** | **none** |
| **K4 ≡ UNSOURCED** | **CH-3**, operator-mediated — **identity only** | **never crossed** | **none** |

> **Table-level fail-closed clause — the read-failure arm.** Where **a read this entry attempted
> could not be completed** — the roster, the derived model, or the person store this entry's own
> `person:` line references — the axis returns `ENGAGEMENT-UNDETERMINED` and **every cell of this
> table is UNDETERMINED rather than its nominal value.** The trigger is **entry-scoped, never
> machine-scoped**: a field composing `UNKNOWN` is not it, and a store nobody referenced is not it.
> A traveller file carrying no `person:` line attempts no store read, so *"that traveller is
> entirely unaffected, on every trip."* That limb is the corpus's and is not minted here —
> `agents/00-enrichment.md` states it in those words, and without it the first unreadable store
> would *"break every trip in the working directory rather than the ones that actually reference a
> record."* The undetermined reading is stated here, once, for the whole table rather than as a row
> or a column, because a value meaning *the row could not be selected* cannot modify a row — there
> is no row to modify. This lands the arm in the same fail-closed family as § 5.4's five
> UNDETERMINED paths and § 5.6's sixth.

**Why the cell grammar splits.** An earlier draft wrote a single `in: operator` cell, which reads
as an affirmative reach verdict on a row whose subject is not the operator — while this record's own
rule is that every claim the engine makes is about the **first** crossing. CH-1 and CH-2 face a
traveller; CH-3 faces the operator. One grammar across both far sides cannot say which, so the
two-crossing caveat now travels **with the row** instead of in prose above the table.

**Two subject kinds are reached through the operator, not three.** K3a and K3b are the subjects
reached *through* CH-3. **K4's CH-3 cell carries identity only** — its `## Group` roster row is
written by `/trip-new` at creation and by `/trip-record` thereafter — which is the operator
entering a **name**, not the subject being reached.

**K4 splits, and the split is the point.** *Roster row only* is a **strict containment** in
`UNSOURCED`, not an identity, because the engine's flagged-gap branch **writes a C12 entry with
content**. `K4 = K4a ⊎ K4b`, and the union is what restores the one-to-one correspondence the seam
needs:

| Arm | Shipped condition | C12 entry? | out — to the subject |
|---|---|---|---|
| **K4a** | a roster row and no C12 entry at all | no | **none** |
| **K4b** | a roster row with a **flagged-gap** C12 entry: `**Source:** none`, a `PROFILE MISSING` marker, and a `Trip-level facets` block carrying `Origin` at basis `UNKNOWN` (`agents/00-enrichment.md`:669-691) | **yes, with content** | **none** |

**The outbound `none` is grounded on the class of the carrier, not on absence of content** — which
is the only ground true of **both** arms. C12 is `internal-hard`
(`reference/data-architecture.md`:770), so nothing in either state crosses CH-1 whatever the entry
holds. **It is deliberately not cited to `CLAUDE.md`:557's *"no entry at all without operator
input"***: that clause closes the sentence defining the **third** fallback branch — the
`[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` population, which is **K3b**, whose row is not
`none`. And it is **not** cited to `ADR-014` § 1, whose population reads live at `:26-30` as the
same both-marks class — *"a person admitted to a trip's `outputs/traveler-model.md` as a single
`## <Name>` heading marked `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]`"*. A citation that bites
equally on a row with a different verdict cannot be what distinguishes this one. The re-grounding
matters for the reason the clause exists at all: it
is there to stop a later slice proposing to close the gap, and it can only do that if it is true
for the right reason. **A slice that supplies K4's needs converts that person to K3b** — which
this record says *is* reached, through the operator.

**Mode's role, in one sentence, and it does not index anything.**

> Mode conditions the **production** of a channel's content and never indexes its reach:
> `/trip site` is `DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING` in its own requirement row
> (`skills/trip/SKILL.md`:73) and so builds no site in `IDEATION`, which is the single instance
> that bites on CH-1 — while `/trip-publish update` is `mode: any` (`:202`) and every
> `/trip-record` verb is `mode: any`.

**And mode is explicitly *not* an artifact-availability axis.** The corpus nowhere states that
claim, and `CLAUDE.md`:355 forbids the inference in terms: *"**Never infer a mode** — not from the
destination, not from which files exist, not from the request's wording."* Corroborated
structurally: the destination shortlist is `internal` and `rebuilt-each-synthesis`, so once
produced it persists on disk in every later mode; what a mode change alters is whether it is
*refreshed*, never whether it exists. `production-gating` is the accurate label.

**The `ARCHIVED` overlay.** CH-1 → **none**, the site is offline. CH-2 → **writable but inert** —
*"the freeze binds derivation, not bytes."* CH-3 → **one operation only**, erasure, **by
substitution, never by regeneration**, which is the mechanism `CLAUDE.md`:125 calls *"the whole of
the rule."*

### 5. Two rules, both channel-level; the observable test per channel

> **W-rule** — the engine never **authors** a traveller's own statement about themselves.
> **R-rule** — the engine never **emits** a value `may-carry` denies.
>
> Both bind every channel. **What is per-channel is the observable test**, and every member
> carries one of each. **A channel with no stated test is unenforced regardless of the rule.**

| Channel | **W-test** | **R-test** | Enforcement strength today |
|---|---|---|---|
| **CH-1** | **N/A — no inbound limb exists.** Stated as N/A rather than invented, so adding one becomes a visible change to this record | `verify_ciphertext` on the encrypted limb; `verify_publishable_content` on the `--plaintext` limb — both grading the relation between `P` and C19 | **shipped shell predicates + regression suite** |
| **CH-2** | a prompt may name a field and a remedy; it may **never carry, quote, or offer a candidate value**. **Silence is not assent** in a spoken modality | what is said aloud is bounded — needs include medical facts, and a spoken interview is audible to a room | **prose** |
| **CH-3** | provenance-marking records that a value is **second-hand** and **never establishes consent** (`ADR-006`) | the standing rule on the passphrase **value**; `ADR-007` § 2 — no command may set `ALLOW_PLAINTEXT`, none may pass `--yes` to `unpublish` | **prose bounds + per-verb `allowed-tools`** |

**Why two rules rather than one.** `ADR-015` clause 7 sits at the intersection: a report line is an
engine→human **emission** whose prohibition exists to protect **authorship**. That is why that
record needed a subsection titled *"Why clause 7 is not a carve-out."* A one-rule model cannot
explain that subsection; a two-rule model predicts it.

**The residual, recorded rather than smoothed over.** The three R-tests are enforced at
**materially different strengths** — one pair of shell predicates with their own regression suite,
and two prose. Closing that is not this record's work. Stating it is what lets a reader see that
the claim is checked on CH-1 and unchecked on CH-2 and CH-3.

### 6. The names, each with its measured collision

**The measurement convention, stated once, because it is the whole of the instrument.**
**Occurrences** = every regex match, counting multiple matches on one line separately. **Lines** =
distinct matching lines. **Files** = distinct files with at least one match. **Every count in this
record is reported as `lines / files`, case-sensitive, `\b`-anchored, over the 156 tracked files
at `edadfa9`**, measured by `python3` file reads with explicit patterns — never by `grep`, whose
local build is `ugrep` and can return a plausible zero on a pattern it rejects. Stating the
convention is not ceremony: three readers of this design derived three different numbers for the
same tokens because the instrument was described and never specified. **This basis re-derives
every figure the earlier passes reported** — `reach` 470/81, `roster` 367/47, `hop` 31/13,
`stated(` 15/4, `addressable` 11/8 — five independent reproductions, which is the evidence that
the instrument rather than the corpus was the source of the disagreement.

**Control arms on this exact instrument and population, probed at `edadfa9`.** Sensitivity:
`publish:` **167 / 88**, `internal-hard` **93 / 48**, `person:` **121 / 21**, `UNDETERMINED`
**137 / 16** — every arm non-zero. Specificity: `\bzzq-not-a-token\b` **0 / 0**,
`\bengagementzzq\w*` **0 / 0**. **Every zero below is therefore a measurement rather than a failed
read**, and each proposed zero carries a
**reciprocal root arm** so a bare-token zero cannot hide a non-zero root.

| Identifier | Literal pattern | lines / files | Reciprocal root arm → observed | Verdict |
|---|---|---|---|---|
| **`engagement`** (axis name) | `\bengagement\b` | **3 / 1** | `\bengag\w*` → **9 / 4** | **ADOPT.** All three bare matches are one sense and it is *this* domain: `ADR-010`:238, :368 and :382 each name the milestone *Group approval engagement layer*, and `:368` names #718 as its head gate — the scope this record takes half of. The six further root matches are the **verb** *engage(s)/engaged* — *"standing rule 3 is not engaged"* — a different part of speech with no noun sense available to confuse |
| `engagement(t)` (predicate) | `\bengagement\s*\(` | **0 / 0** | the bare arm above is the reciprocal | adopt |
| **`UNSOURCED`** | `\bUNSOURCED\b` | **0 / 0** | `\bunsourc\w*` → **0 / 0** | adopt — clean on both arms |
| **`OPERATOR-STATED`** | `\bOPERATOR-STATED\b` | **0 / 0** | `\boperator[- ]stat\w*` → **7 / 4** | adopt. The root is a **same-domain precedent**, not a collision: `ADR-006`:139 and `ADR-012`:1291 both quote *"the only surviving record of what the operator stated"* — this exact state, in the corpus's own words |
| **`THIRD-PARTY-STATED`** | `\bTHIRD-PARTY-STATED\b` | **0 / 0** | `\bthird[- ]party[- ]stat\w*` → **0 / 0** | adopt |
| **`SELF-STATED`** | `\bSELF-STATED\b` | **0 / 0** | `\bself[- ]stat\w*` → **0 / 0** | adopt |
| **`PERSON-LINKED`** | `\bPERSON-LINKED\b` | **0 / 0** | `\bperson[- ]link\w*` → **0 / 0** | adopt. Names the mechanism — the `person:` frontmatter edge, whose own arm fires at **121 / 21** |
| **`ENGAGEMENT-UNDETERMINED`** | `\bENGAGEMENT-UNDETERMINED\b` | **0 / 0** | `\bUNDETERMINED\b` → **137 / 16** | adopt. The root is a **same-sense precedent** — the shipped guard's *could not be computed* — which is exactly this value's meaning, so the echo is correct rather than confusing |
| `audience` | `\baudience\b` | **0 / 0** | `\baudiences?\b` → **1 / 1** | adopt. The single root match is `CHANGELOG.md`:1656, *"the three audiences it has"* — a different subject, in the one file this release must also write into |
| `observers` | `\bobservers\b` | **1 / 1** | `\bobserver\w*` → **1 / 1** | adopt. `ADR-010`:96 — *"Those are different exposures with different observers"* — the **same sense** this axis names |
| `may-carry` | `\bmay-carry\b` | **0 / 0** | `\bmay[- ]carr\w*` → **26 / 20** | adopt. The root is the ordinary modal phrase *may carry*; the **hyphenated** token is the identifier, and bare `carry` is far larger still |
| `carry-envelope` | `\bcarry-envelope\b` | **0 / 0** | `\bcarry[- ]envelop\w*` → **0 / 0** | adopt |
| `channel-set` | `\bchannel-set\b` | **0 / 0** | `\bchannel[- ]set\w*` → **1 / 1** | adopt. The single root match is `ADR-010`:293, *"the channel **sets** what a copy/paste actually costs"* — the **verb**, not this compound noun |
| `vacancy` | `\bvacancy\b` | **0 / 0** | `\bvacanc\w*` → **0 / 0** | adopt |
| `W-rule` · `R-rule` · `W-test` · `R-test` | `\bW-rule\b` · `\bR-rule\b` · `\bW-test\b` · `\bR-test\b` | **0 / 0** each | `\b[WR][- ]rule\w*` → **0 / 0**; `\b[WR][- ]test\w*` → **0 / 0** | adopt |
| `direct-crossing` | `\bdirect-crossing\b` | **0 / 0** | `\bdirect[- ]cross\w*` → **0 / 0** | adopt |
| `phase-axis-declaration` | `phase-axis-declaration` | **0 / 0** | — (a fence language, matched literally) | adopt |
| `channel` | `\bchannel\b` | **82 / 14** | — | **retained by deliberate disambiguation** (§ *Decision* 1), the rename having measured worse |

**Withdrawn, and not to be re-minted.**

| Candidate | Literal pattern | lines / files | Why withdrawn |
|---|---|---|---|
| `reach` | `\breach\b` | **470 / 81** | 52% of the population, and **`REACH` is already a closed-enum value** — `ADR-012`:294-296's reach-set disposition axis, `REACH` · `REPORT` · `OUT` |
| `roster` | `\broster\b` | **367 / 47** | the sibling record grounds the axis **domain** on the `## Group` roster; two records merging in one release would bind the token to two objects |
| `hop` | `\bhop\b` | **31 / 13** | two live senses — a transport leg and a redirect hop — and the second is itself a path-length sense |
| `stated(` | `\bstated\s*\(` | **15 / 4** | collides with a shipped predicate, and `agents/00-enrichment.md`:651 forbids conflating it with the predicate the proposal was defined on |
| `addressable` | `\baddressable\b` | **11 / 8** | `ADR-007` and `README.md` gloss `skills/` as *the addressable surface* — a different subject. (The abstract noun `addressability` measures **0 / 0**; the **root** is the honest arm, and it is the one reported) |
| `COMPOSED` | `\bCOMPOSED\b` | **0 / 0** | **withdrawn on its root arm, not its bare count.** `\bcompos\w*` → **286 / 40**, and this record's own prose uses *composed* and *composition* throughout, because composition is the people library's own verb. An all-caps enum token a reader cannot distinguish from the surrounding English is not a usable token. Replaced by `PERSON-LINKED` |
| `SELF-STATED-LINKED` | `\bSELF-STATED-LINKED\b` | **0 / 0** | **rejected on structure, not on a count.** It contains `SELF-STATED`, another token of the same set, so a `\b`-anchored probe for the shorter token matches inside the longer one and neither can be measured independently. A containment check over the adopted set returns **0 pairs**; the same check on this rejected pair returns **1**, so the check is demonstrated rather than asserted |

## Consequences

**Positive**

- **One definition becomes the arbiter for a rule that had eight authors**, without editing any of
  them. *The engine never invents* is now the W-rule and the R-rule, and every channel carries an
  observable test for each.
- **Decision 3 is evaluable, and its *changes-no-verdict* claim is checked rather than stipulated.**
  `denied` **is** the shipped fence read rather than re-declared, and the queried-pair restriction
  **is** the shipped evaluator's, so the model structurally cannot return a verdict the guard does
  not already return.
- **The object that crosses CH-1 is named**, so CH-1's R-test grades an object this record
  identifies — and it is named as a **relation**, which is what both of its predicates actually are.
- **`ADR-010` § 6's placeholder becomes a typed vacancy with a stated discharge condition, and half
  of it is marked already discharged.** #718 inherits a half-solved problem with the solved half
  named and its evidence cited.
- **Two records index one partition, declared in both and joined on the row key.** The seam is
  structural rather than nominal, which is what makes it gradeable at all.
- **#1242 remains a one-cell change**, and this record names it as the only card that may move a
  cell.
- **The measurement convention is now specified rather than described**, and it re-derives every
  identifier figure this release's earlier passes reported.

**Trade-offs**

- **The vocabulary differs from the driving card's.** A reader following the thread will meet more
  than one name for the same object, because three candidates were withdrawn on measurement after
  the card was written. The withdrawals are recorded in § *Decision* 6 with their counts, which is
  the mitigation available.
- **`may-carry` is three-valued, and a binary consumer of it is a defect.** Any slice grading
  against it must handle UNDETERMINED as an outcome distinct from both admit and deny. This is
  stated here because a binary reading is the easy mistake and it fails toward *admit*.
- **Three R-tests at three enforcement strengths.** Named in § *Decision* 5, closed nowhere.
- **K4's row will still read as a defect to someone.** That is precisely why it is written down,
  split into its arms, and grounded on the one fact true of both.
- **The record carries a finding it does not repair** — the crossing artifact's missing class. A
  reader who expects a head decision gate to close everything it finds will read that as
  incomplete; the alternative was to amend a section this record does not own.

**Neutral, and explicitly unchanged**

- `ADR-002` upheld. Nothing here needs a standing server, and no supersession is proposed.
- `internal-hard` unwidened, at its live four-member membership — **C12, C14, C22 and C23**.
  `ADR-006`'s third-party prohibition unwidened; the denial is now **computed** from § 5.6 rather
  than asserted by hand, which is strictly no looser and one fewer hand-written exception.
- The archived-trip freeze binds unchanged; erasure remains the one exception, by substitution.
- **No dependency on § 5.2.** Its declared field-classification gap changes no decision here.
- **No file moves and no renames.** One file is added.

## Findings and observations carried

These are recorded rather than repaired. Each names its disposition, so a later reader can tell a
deliberate carry from an oversight.

**1. The crossing artifact has no § 1.1 class. This is a finding of this release.** Probed at
`edadfa9`: § 1.1 carries **23** class rows and **none** is under `.publish/` — subject arm
`\.publish` over the 23 rows' path column → **0 / 23**, with an in-table sensitivity arm
(`outputs/`) firing at **18 / 23** and a corpus-wide arm (`\.publish\b`) firing at **15 files**, so
the zero is a measurement, not a dead reader. **Disposition:** not repaired here, on two grounds.
This record does not own § 1.1, and the artifact is fully governed on the path that produces it by two fail-closed pre-push
predicates. It is a gap in the class table's **coverage of the trust boundary**, and it belongs to
whichever card next amends § 1.1.

**2. The axis ships unnamed, but its six-value partition does not ship exercised.** Both this record
and its sibling ground the axis on a classification the engine already computes. Probed at
`edadfa9`, the shipped worked-example evidence is a single fixture table —
`examples/data-architecture-demo/outputs/traveler-model.md`:48-52, columns *Roster member · Source
file · Entry · Branch* — carrying, as of `edadfa9`, the observed `Branch` values `normal` and
`[OPERATOR-PROVIDED]` and no others. `normal` merges `SELF-STATED` with `PERSON-LINKED`, and
`[OPERATOR-PROVIDED]` merges `OPERATOR-STATED` with `THIRD-PARTY-STATED` — **the second is exactly
the merge `CLAUDE.md`:130 says fails in opposite directions.** The other fixture carries **no
`Branch` column at all**, and `K4b`'s flagged-gap arm is unexercised: probed at `edadfa9`,
`PROFILE MISSING` measures **0 lines / 0 files across the 53 files under `examples/`**, against
sensitivity arms `[OPERATOR-PROVIDED]` **13 / 5** and `[THIRD-PARTY]` **10 / 5** on the same
instrument and population, and a reciprocal arm of **20 / 7** over the whole tracked tree — so the
marker is *specified* in the corpus and *never demonstrated* in a fixture. **Disposition: recorded
as an observation, and the axis decision stands.** *"The axis already ships"* is sound as *a classification exists*; it is
**not** measured as *this five-value partition ships*. `CLAUDE.md`:131-133 governs fixture
completeness and is the surface that would close it — *"Any fixture standing as the worked example
of this rule must exercise all three, and dropping one is a change to this rule, not a change to a
fixture."*

**3. The crossing artifact's per-class field pair can have no witness fixture, terminally.**
`reference/schemas/travel-site.md`:41 records the `no-witness-because:` clause as **terminal rather
than pending**, because the site source *"stays local and git-ignored"* and so there is no tracked
instance to point at and there will not be one. `scripts/test-publish-guard.sh` group `T` stands in
as a coupling test. **Disposition: recorded.** It is the same shape as finding 2 on a different
surface, and reading it as a shortfall would invite the wrong repair — committing a site file to
satisfy a gate.

**4. One citation in this design's own inputs did not reproduce, and the live value governs.**
`verify_publishable_content` is declared at **`scripts/publish-trip-site.sh`:1924**. An input to
this record cited `scripts/test-publish-guard.sh`:4289, which reads live as the **S10 PASS
message** — a line that *names* the function rather than declaring it. **Disposition:** the live
location is carried in § *Decision* 3 and the divergence is reported rather than resolved to the
cited value.

**5. An Accepted record block-quoted the never-carry class at a stale two-member membership, and
this release corrected it.** When this record was written, `ADR-010`:186-187 quoted `internal-hard`
as *"Exactly C12 and C14"* where `reference/data-architecture.md`:770 reads *"Exactly C12, C14, C22
and C23."* **Disposition: observed here and not edited here** — it was amendment-class work already
in this release's scope, and the change that owns that file has since made it: that block quote now
carries the live set, with a dated amendment in `ADR-010` recording the correction. It is noted
because § *Decision* 3 turns on the current membership, and **this record quoted the live
four-member set** rather than inheriting the stale one, so the correction landing changed no clause
here.

## Follow-on build slices

- **#718 — the inbound approval return (V-2).** Inherits a vacancy whose L2 is `UNDETERMINED`
  against a declared placeholder, with the **outbound** half already discharged and its evidence
  named, so it is not re-derived. `ADR-010`'s two recorded candidates remain candidates.
- **#1242 — the one cell that may move.** Argued for one channel, against `internal-hard`, and it
  does not widen the channel-set's answer on its own.
- **A § 1.1 row for the published artifact.** Finding 1. Owned by whichever card next amends § 1.1.
- **A fixture that exercises the unsourced arm.** Finding 2, against `CLAUDE.md`:131-133's fixture
  completeness rule.
- **An observable test worth the name on CH-2 and CH-3.** The § *Decision* 5 residual: two of the
  three R-tests are prose.

## References

- [ADR-002](ADR-002-living-site-refresh.md) — the secret model and the no-standing-server
  constraint, upheld here and not superseded.
- [ADR-003](ADR-003-group-coordination.md) — §§ 1–4, and **§ 3's pull-based notice** at `:53`,
  which is what discharges V-1.
- [ADR-006](ADR-006-third-party-data-capture.md) — a `[THIRD-PARTY]` value is never published in
  attributed or anonymized form, and provenance-marking never establishes consent. Unwidened.
- [ADR-007](ADR-007-command-entry-point.md) — § 2's privilege boundary, which is CH-3's R-test.
- [ADR-008](ADR-008-publish-content-guard.md) — the two-limb publish guard, and the `--plaintext`
  opt-out whose `audience` this record declares `world`.
- [ADR-009](ADR-009-data-architecture.md) — the data architecture this record is the reach
  counterpart to.
- [ADR-010](ADR-010-per-traveler-approval-collection.md) — transport over server, the attestation
  ceiling, and the unnamed channel. §§ 4, 6, 7; `:230`'s placeholder; `:248-251`'s candidates,
  which stay candidates.
- [ADR-012](ADR-012-people-library.md) — cross-trip person identity and the `person:` edge that
  distinguishes `PERSON-LINKED`; `:294-296`'s reach-set disposition enum, on which the `reach`
  withdrawal turns.
- [ADR-013](ADR-013-count-assertion-basis.md) — every count in this record is authored to form
  **F1**, anchored measurement.
- [ADR-014](ADR-014-cross-trip-consent-refusal.md) — § 1's population is `K3b`, `:26-30`. Cited
  for that row and deliberately **not** for `K4`.
- [ADR-015](ADR-015-durable-field-validity-horizon.md) — §§ 6–7, and clause 7, which sits at the
  W-rule/R-rule intersection and is the positive evidence for two rules rather than one.
- [ADR-021](ADR-021-installable-capability.md) — the two-artifact `Status:` obligation this record
  inherits, and the divergence it repaired.
- [ADR-025](ADR-025-engagement-model-over-time.md) — **the engagement axis this record joins.** It
  declares the axis, its six values, and the read-failure value `ENGAGEMENT-UNDETERMINED` that is
  the single named difference between its token set and this record's five. The citation is mutual
  and must not be dropped: neither record's axis declaration is gradeable without the other's. It
  was carried by number while that record was unauthored, because its kebab title was its own to
  choose and a guessed filename would have shipped a dead link; the link form lands here in the
  same change that authors both index rows.
- `reference/data-architecture.md` — §§ 1.1, 5.1, **5.3**, 5.4, 5.5, **5.6** with its
  `publish-contract-values` fence, its four queried `(limb, artifact-scope)` pairs, and its
  declared gap.
- `reference/site-layout-spec.md` — § 3's Coordination Notice, § 8's file structure (`:670-673`),
  and §§ 9, 9.1's `publish-contract-artifacts` fence.
- `reference/schemas/travel-site.md` — `:28-29` the per-class field pair, `:32` their declared
  purpose, `:37` the read-not-carried distinction, `:41` the terminal no-witness clause.
- `scripts/publish-trip-site.sh` — `:1924` and `:1906-1914` (`verify_publishable_content` and its
  three-code contract), `:2214`/`:2232`/`:2237` (`verify_ciphertext`, its contract and its
  self-check), `:2666`, `:2679-2680`, `:2687`, `:2695`, `:2698`.
- `scripts/test-publish-guard.sh` — case **L10c** at `:1123`, the unqueried-pair abort; group `T`,
  the coordination-state coupling test.
- `agents/00-enrichment.md` — § *Missing or blank profile* (`:654-691`), the branch set and the
  flagged-gap arm that splits `K4`; `:651` on `stated()` versus `ANSWERED()`; `:891-894`,
  the profile-gap denominator.
- `CLAUDE.md` — `:123-133` the three model-entry classes and the fixture-completeness rule; `:355`
  *never infer a mode*; § *Modes*, § *Archived trips*, § *Write ownership*; the standing rule on
  the passphrase value.
- `skills/trip/SKILL.md`:73 and `skills/trip-publish/SKILL.md`:202 — the requirement rows that
  make mode production-gating rather than reach-indexing.
