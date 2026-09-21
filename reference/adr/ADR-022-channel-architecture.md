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
