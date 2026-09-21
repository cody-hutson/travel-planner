# ADR-022: The channel architecture — what a channel is, the channel-set, what each may carry, and the crossing model

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

**Four surfaces carry a person on the far side.** The published site, the intake surface, the
command surface, and the approval transport. Three of the four are governed in detail and the
fourth is a declared placeholder — `ADR-010` states, in terms, that *"'Out-of-band' is a
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
writes the result into `outputs/traveler-model.md`; `:891` names the domain in the corpus's own
words — *the profile-gap denominator*. So the question this record's reach table faced was never
*choose an index*. It was **declare a join** to a classification the engine already computes,
and give it a name. The name is decided in § *Decision* 6 under a measure-before-adopting
constraint, and every identifier this record mints carries its measured collision inline.

**Baseline.** Every corpus fact in this record was read live at `edadfa9`, the merge of
pull request #1187. Census: **156** tracked files, **137** tracked `md`·`sh`·`html`, **130**
tracked `.md`, **24** under `reference/schemas/`. Counts are authored to `ADR-013` form **F1**
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
  rule about the build, not about the crossing. The object that crosses CH-1 is neither the five
  `bound` artifacts nor the local render.
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
**Rejected on measurement.** `reach` occurs on **470 lines in 81 files** of 156 — it would trade
an 82-line overload for a 470-line one — and it is additionally a closed-enum value in `ADR-012`.
The adopt-and-disambiguate path in 1D costs one paragraph; the rename costs a reference cascade
across 14 files and lands on a worse token.

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

**Option 2A — the three surfaces the driving card named: site, approval transport, interview.**
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
express *the same value, two rows, because two scopes*. The fence is keyed
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
