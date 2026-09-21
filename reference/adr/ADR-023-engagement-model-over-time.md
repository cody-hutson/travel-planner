# ADR-023: The engagement model over time — the axis the engine already computes, what carries across a boundary, and identity continuity

- **Status:** Proposed (2026-09-21)
- **Deciders:** repo maintainer
- **Driving work:** the time slice of the *traveller journey* milestone. This record is that
  milestone's second head decision gate, standing beside `ADR-022` in the shape
  `ADR-012-people-library.md`, `ADR-016-reusable-groups.md` and
  `ADR-021-installable-capability.md` already ship: it lands before any feature slice and
  settles the cross-cutting question each of them would otherwise answer separately — what a
  traveller's arc **is**, what crosses a boundary in it, and how one traveller is recognised
  as the same person on either side.
- **What this record is.** A decision about **time**, where `ADR-022` decides **reach**.
  `**Current mode:**` resolves through `G5` and `**Lifecycle:**` through `G4`, and **neither
  field's subject is a person**. Four capabilities each decide a piece of time locally and
  correctly — the interview's session lifecycle, the post-trip memory, the approval's validity,
  and the site's per-phase shape — and none of them can state a boundary, because no boundary is
  declared. This record declares the boundaries and the axis they are boundaries of.
- **What this record is not.** It **runs nothing new**. The classification it names is computed
  today, on every synthesis, by an agent that already runs; this record supplies a name, a closed
  value set, a declared class and a stated domain, and adds **no field, no writer, no verb, no
  schema and no store**. It **widens nothing**: `internal-hard` is unwidened at its live
  membership, `ADR-006`'s third-party prohibition is unwidened, `ADR-014`'s refusal is unreopened,
  and `ADR-002`'s no-standing-server constraint is upheld with no supersession proposed. It
  **declares no relation membership** and **adds no gate**.
- **Scope taken, and scope left.** This record takes the **journey-wide** half: the axis, the
  boundaries, the join keys, the observation bound and the staleness family. Every phase-local
  decision already in flight keeps its own scope — what an interview decides about session
  lifecycle, what the post-trip memory decides about its entity home, and what the approval
  slices decide about validity are **phase-local and assert no journey-wide meaning**, which is
  the seam those cards already carry.
- **The status flip is named here, because nothing grades it.** Moving this record from
  `Proposed` to `Accepted` is the maintainer's, taken at this milestone's close, and it moves
  **both** halves of a two-artifact state: the `Status:` line above, and this record's `Status`
  cell in `reference/adr/README.md`. No required check here grades either half or their
  agreement, so the obligation travels with this line rather than with a gate — the same
  two-step `ADR-010` and `ADR-019` each used, and the same divergence `ADR-021` repaired when a
  predecessor's file was flipped and its index cell was left behind.

## Context

**The engine has a phase variable and it is the planner's.** `**Current mode:**` resolves over
the five planner modes through `G5`, with `UNSET` a legal state `G5` declares *is not a sixth
mode*; `**Lifecycle:**` resolves through `G4` over `ACTIVE` and `ARCHIVED`. Both are **trip-scoped
scalars**, and a trip has N roster members. Neither field's subject is a person, so neither can
carry a per-traveller state — which is the whole of why the traveller's arc needed a record of its
own rather than a reading of an existing field.

**The absence showed up as four independent decisions about time**, each correct inside its own
scope and none able to state a boundary: an interview's session lifecycle and resumption; whether
a trip's outcomes survive the trip, and what carries; whether an approval is still valid after the
plan changes; and whether a site's shape changes as the trip advances. A boundary nobody declares
is a boundary every capability re-derives, differently.

**The axis already ships, unnamed, and so does its denominator. That finding changes this
record's job.** `agents/00-enrichment.md` § *Missing or blank profile — operator fallback, not a
hard failure* enumerates **every** roster member and assigns each one a branch: reconciled from
their own profile; **fallback**, where the operator supplied the needs and the entry is marked
`[OPERATOR-PROVIDED]`; or **flagged-gap**, where the entry carries `**Source:** none` and a
`PROFILE MISSING` marker — under the standing instruction to *"write the traveler into
`outputs/traveler-model.md` with an explicit gap marker rather than omitting them silently."* The
same prompt names the domain in the corpus's own words, at `agents/00-enrichment.md`:894 —
*"**The roster is the name authority.** The `Person` cell of the `## Group` roster in
`trip-context.md` is the authoritative display name for every person the model knows about — the
same roster you already take as the party and as **the profile-gap denominator**."* And the
shipped fixture carries the result as a table with a **`Branch`** column.

**So this record does not choose an axis. It names one that runs today**, closes its value set,
declares its class, states its domain, and says what it may not do. That is a materially smaller
and more defensible record than a record inventing a new state would be — and it repairs, by
construction, the defect an earlier draft of this design carried: an axis defined over
`travelers/<t>.md` plus the `person:` edge sends every file-less traveller to the bottom value and
reports a person whose needs the engine actually holds as having supplied nothing. The branch
classification exists **precisely** to handle the file-less cases, so grounding on it cannot
reproduce that error.

**One class fact bounds every render clause before any option is weighed.** C12 is
`publish: internal-hard` — `reference/data-architecture.md`:770 reads *"never rendered **and**
carrying values that must not reach a rendered page **in any form, including anonymized**. Exactly
C12, C14, C22 and C23."* The axis lives in C12, so it is **locally readable and unrenderable**.
That is a class fact, not a policy choice, and it is why § *Decision* 4's render ceiling is a
boundary rather than a threshold.

**And one shipped vocabulary bounds the staleness half.** `skills/trip/SKILL.md` § *The freshness
report* already ships a `G8` relation family with a closed verdict set, an exact-token comparison
rule, a render-every-relation rule and a self-guard against a disposition column. An earlier draft
of § *Decision* 5 minted a second family beside it. It does not; it reuses that one verbatim.

**Baseline.** Every corpus fact in this record was read live at `edadfa9`, the merge of pull
request #1187 and the commit this release branched from. Census probed at `edadfa9`: **156**
tracked files, **130** tracked `.md`, **24** under `reference/schemas/`. Counts are authored to
`ADR-013` form **F1**, anchored measurement; the measurement convention is stated once in
§ *Decision* 7 and holds for every count in this record.

## Decision drivers

- **Name what already runs; do not mint beside it.** The strongest form of *reuse over
  re-implementation*. This record withdraws a five-value staleness vocabulary and a two-predicate
  definition because the corpus already carries both jobs. Minting beside a shipped mechanism
  creates a second thing to keep true and a second thing to grade.
- **A name is not a proposal until it is measured — and a census is not the whole measurement.**
  One candidate this design carried measures **0 / 0** as a token and is still wrong, because the
  corpus carries a **reservation clause** binding the word to one event and ships a guard
  implementing it. Measure the token, then read the clause. A second candidate measured clean as
  a compound and collides badly as a bare code, which is a different failure of the same
  discipline and is recorded in § *Decision* 6 with both arms.
- **Declare the class, then inherit its bounds.** `G8` is a *class*, not a field. Taking that
  branch explicitly inherits report-only, never-gates, consumer-declared membership and a shipped
  mechanical self-guard — all already argued and enforced. What a record may not do is call the
  axis *a resolution* while forbidding the mechanism that would resolve it.
- **Express only what the engine can observe.** `ADR-002`, `ADR-003` § 3 and `ADR-010` § 2 each
  independently remove every traveller-side observation surface. A definition of *engaged* that
  needs a traveller-side signal is unresolvable by construction, and saying so is more useful than
  a definition nothing can evaluate.
- **Fail safe at the right granularity.** An **entry-scoped** gap and a **field-scoped** gap are
  different gaps, and the corpus already says so. A read-failure value that fires on a store
  nobody referenced would make one traveller resolve differently on two machines.
- **Absence never reads as a negative.** An unrecorded state is `unknown`, never a decision the
  traveller made. The corpus fixes this for prior-visit familiarity; it holds unchanged at this
  layer, and it is why the bottom value means *the engine holds nothing sourced* rather than
  *this person declined*.
- **Monotonicity where it can be had, honesty where it cannot.** This axis is **not** monotone,
  so the no-audit-owed argument `ADR-015` makes for its own axis does not transfer. Saying that
  plainly costs one sentence and prevents a later slice inheriting a guarantee that was never
  granted.

## Options considered

Release class `novel`; each of the seven decisions carries its own option set and none are
merged. Every rejection is grounded on a corpus fact read live at `edadfa9`, and the option sets
include the genuine null option where one exists. Four options below are marked **withdrawn**
rather than rejected: each was recommended by an earlier pass of this design and lost to a
measurement or a counter-example taken afterwards. They are recorded with their reasons, because
a later reader must be able to see that the option was held and why it fell.

### Decision 1 — What axis is the traveller's arc

**Option 1A — the arc *is* the planner's five modes.** **Rejected three ways, independently.**
*Cardinality:* `trip.mode` is a one-valued trip-scoped field and a trip has N roster members, so
it cannot carry an N-valued per-traveller state. *Jurisdiction:* measured across every per-verb
requirement table in the corpus as of `edadfa9` — of the verb rows that exist, only the `/trip`
synthesis verbs name a mode at all, and **not one verb that reaches a person gates on mode**:
`/trip-publish update`, the verb that puts the site in front of a traveller, is `mode: any`, and
every `/trip-record` verb is `mode: any`. *The corpus's own words:* the archived fixture reads
*"The mode records where planning stopped, not where the trip is now."*

**Option 1B — a projection of the five modes.** **Rejected, and it is the weaker of the two.** A
total `mode → arc` map assigns every traveller the same value, so it carries **zero information
about its own subject**: one who answered everything and one who answered nothing project
identically. It also makes a traveller's state a function of the planner's activity, which is
the category error the driving card names.

**Option 1C — a new stored per-traveller field.** **Rejected on three independent grounds.** It
is a **shadow SSOT** for something the composed source already determines. Its **writer** is
wrong: those files' write-ownership cell is `human`, so a machine value there is exactly the
class violation the write-ownership layering exists to prevent. And its **staleness fails in the
worst direction** — a stored value reads *this person is on record* after the entry it described
has gone.

**Option 1D — an independent axis defined over `travelers/<t>.md` plus the `person:` edge.**
**Withdrawn.** Right verdict, wrong domain, and the defect is not cosmetic: a domain keyed on
the traveller **file** sends every file-less kind to the bottom value, and so reports a person
whose needs the engine actually holds — an `[OPERATOR-PROVIDED]` entry with content — as having
supplied nothing. This was this design's own earlier recommendation and it is recorded as held.

**Option 1E — declare no axis; leave each capability its local reading.** The genuine null
option, and it is the driving card's premise restated. **Rejected**: four capabilities already
read the same identity across time and no two agree, which is the condition a missing layer
produces rather than a condition more local care would fix.

**Option 1F — the classification the engine already computes.** **← RECOMMENDED.** Stated in
§ *Decision* 1. It repairs 1D's defect **by construction**, because the branch classification
exists precisely to handle the file-less cases, and it grounds the axis on something that runs
today rather than something this record would be asking to be built.

### Decision 2 — What carries across a boundary

**Option 2A — a carry rule per capability.** **Rejected.** It is the status quo with names on
it, and it cannot state what happens when two capabilities cross the same boundary in one pass.

**Option 2B — carry everything unless a rule names it.** **Rejected, and it fails safe in the
wrong direction.** The default that matters here is a privacy default: an unnamed value carried
into a render is the failure `internal-hard` exists to prevent, and a permissive default makes
every future artifact class a silent widening.

**Option 2C — enumerate carry per artifact class per boundary.** **Rejected.** It is a second
home for an assignment the class table already makes, and a second home drifts from the first.
The architecture reference's own § 5.3 is titled *computed, never enumerated*, and this is the
same argument one axis over.

**Option 2D — one rule over the class table's existing columns, plus a closed never-carry set.**
**← RECOMMENDED.** Stated in § *Decision* 3. It adds no column and no table: the rule reads the
`lifecycle` and `publish:` columns that already ship, and the never-carry set is the short list
of cases where reading those columns is not enough.

**A fourth boundary is admitted, and it is the one an earlier pass omitted.** That pass wrote
*"exactly three"* and left out **re-synthesis** — the one carry event the corpus actually
adjudicates, in full, with three named behaviours and a fixture-completeness rule attached. The
omission mattered because the approval slice, the driving card's own motivating case, crosses
precisely that boundary; the earlier pass's claim that the four capabilities acquire a shared
name for its scope was therefore false for the capability that most needed one.

### Decision 3 — Identity continuity across a boundary

**Option 3A — mint a journey-wide traveller identifier.** **Rejected.** It is a fourth key
beside three that already work, it has no writer, and it would have to be minted for subjects the
engine is forbidden to individuate at a render.

**Option 3B — a render-side pseudonym or a per-traveller receipt.** **Rejected, and foreclosed
by name rather than on balance.** `ADR-010` § 4 forecloses the anonymized projection in terms: a
signal that lets a reader tell *which* traveller acted is an anonymized projection of a C12 value,
and C12 is `internal-hard`. Not a name, not a handle, not a stable pseudonym, not a receipt.

**Option 3C — three join keys, one per boundary that has one, and none at the render.**
**← RECOMMENDED.** Stated in § *Decision* 4. Each key already ships; what this record adds is
the statement of **which boundary each one crosses** and, more usefully, **which boundaries have
no key at all and permanently will not**.

### Decision 4 — What *engaged* means, and how it is observed

The constraint here is measured rather than assumed: **the engine observes no traveller act**, by
three independent shipped decisions — `ADR-002` (no standing server), `ADR-003` § 3 (notification
is pull-based, with nothing reporting the open) and `ADR-010` § 2 (*"No mechanism running there
can be enforced against its owner"*).

**Option 4A — a behavioural definition: engaged means the traveller did something.**
**Rejected, unresolvable by construction.** Every surface that could observe the act is removed
by one of the three decisions above, so adopting it would require an `ADR-002` supersession this
record does not argue for.

**Option 4B — an organizer attestation.** **Rejected.** It fails `ADR-010` § 2's unforgeability
floor, which requires the verifier to hold strictly less than the signer; here the organizer is
both.

**Option 4C — a per-traveller render receipt.** **Rejected**, and it is Option 3B under another
name — foreclosed by `ADR-010` § 4.

**Option 4D — leave it a per-phase local signal.** **Rejected, the driving card's premise.**

**Option 4E — two floors on the axis, with depth carried separately.** **← RECOMMENDED.**
Stated in § *Decision* 5. An earlier pass folded *is there anything on record* and *is there
enough on record* into one predicate, which is why a reviewer could show the composition bit inert
for the only declared consumer. Splitting them is the repair: one floor is a comparison on this
axis, the other is a consumer-declared count over `ANSWERED()` and is not this axis's business.

### Decision 5 — Staleness

**Option 5A — a blocking staleness gate.** **Rejected, foreclosed in terms.** `G8` states that
*no gate may be added that blocks on freshness*, and the shipped report's missing fifth column is
the mechanical form of that prohibition. Independently, `ADR-010` § 2's ceiling means the engine
could not enforce the gate against the organizer in any case.

**Option 5B — a stored `shown-at` / `approved-at` stamp.** **Rejected.** A second home for an
ordering the artifacts already carry, refused in advance by the replan protocol, and needing a
writer in a file whose writer is the subject.

**Option 5C — staleness per capability.** **Rejected, the driving card's premise.**

**Option 5D — a new three-valued staleness family.** **Withdrawn; this was an earlier pass's
recommendation**, on two independent defects. *Redundancy:* the family, the arity, the
report-only rule and the three-absences discipline all already ship. *A reserved word:* the
enrichment prompt reserves *supersession* for **the provenance transition** — *"borrowing it for
an ordinary composed value asks a control built for one event to adjudicate another"* — and that
control ships. Under this record's own § *Decision* 1 the provenance transition **is** an axis
edge, so the borrowed token would put one word on two of this record's own objects. **The token
itself measures 0 occurrences on 0 files at `edadfa9`**, which is exactly why a census-only probe
passes it: the collision is in the reservation clause, not in the count.

**Option 5E — reuse the shipped `G8` verdict triple verbatim.** **← RECOMMENDED.** Stated in
§ *Decision* 6. It mints nothing, inherits the exact-token comparison rule, the
render-every-relation rule and the no-disposition-column self-guard, and leaves the shipped
family's **declared boundary** intact rather than quietly widening it.

### Decision 6 — The names

The option set here is a measurement, not an argument, and it is reported in § *Decision* 7 with
its instrument stated. Four candidates carried by earlier passes of this design were **withdrawn
on measurement** rather than on taste. One further candidate is withdrawn on a measurement **no
earlier pass took**, and it is the sharpest finding of this pass: the four boundary codes the
design proposed are short bare codes, and three of the four collide heavily with unrelated
subjects already in the corpus.

### Decision 7 — How the two records agree

**Option 7A — keep the planner-mode axis and add this one alongside.** **Withdrawn**, rejected
three ways: the artifact-availability claim it rests on is **unsupported** in the corpus and the
charter forbids the inference in terms (*"**Never infer a mode** — … not from which files
exist"*); the sibling's own seam arithmetic priced the retained index at zero for two of its
three members; and the cross-record assertion cannot pass while one record's fence carries a
second token set.

**Option 7B — two independent axes, agreement asserted only in prose.** **Rejected.** It makes
the cross-record criterion unfalsifiable at the structural level, when the whole point of that
criterion is that the two records be checkable against each other.

**Option 7C — the axis as a literal third column in the sibling's reach table.** **Adopted in
substance, amended in form** — not wrong, **degenerate**. Its values stand in a one-to-one
correspondence with that table's row keys, and a column in one-to-one correspondence with the row
key **is** the row key under another name.

**Option 7D — one partition under two names, joined on the row key.** **← RECOMMENDED.**
Stated in § *Decision* 8. It preserves 7C's substance in full and drops the degeneracy, and what
the axis genuinely contributes is then visible rather than buried: its **sixth value**, which has
no subject-kind counterpart, and its **transition structure**, which is why a row's occupancy is
a present reading rather than a property of the person.

## Decision

### 1. The arc is an independent axis, it already ships unnamed, and it is `G8`-class

> **`engagement(t)`**, for `t` a member of the roster defined in § *Decision* 2, is the
> **provenance class of that person's C12 entry** — widened below by the roster-only state and
> above by the composition edge. It is **not** the planner's five modes and **not** a projection
> of them.

**Its evaluator and its carrier both ship today, and the record names them rather than implying
them.** The **evaluator is the enrichment agent**, whose *Missing or blank profile* branch already
assigns every roster member one of these states on every synthesis; the **carrier is C12**, where
that assignment is already written. Nothing is added — no field, no writer, no verb, no schema,
no store. What this record adds is the name, the closed value set, and the bounds below.

**The class is `G8`, taken as an explicit branch rather than left to be inferred.**

> `engagement(t)` is **`G8`-class**: evaluated **after** resolution, **report-only**, with
> **consumer-declared membership**. It **never changes `trip.resolution`**, **no gate may be
> added that blocks on it**, it is **not graded by `G7`**, and it **may not enter the resolution
> contract's return as a new field without arguing for one** — which this record does not do.

That branch is taken because the alternative is incoherent: a record may not call the axis *a
resolution* while forbidding the mechanism that would resolve it. Taking it also inherits a
**shipped mechanical self-guard** — the freshness relation table *"never gains a fifth column …
**no disposition column**: there is nowhere in it for a verdict to be turned into a `RUN`, a
`REDIRECT` or a `REFUSE`."* **A declared axis that cannot be turned into a disposition is the
strongest available form of *never gates*, enforced by the shape of a table rather than by a
sentence.**

**The axis declaration.** The fence below is the declaration this record and its sibling are
graded against; it is the corpus's own declared-set device, already shipping in seven instances
(`publish-contract-values`, `publish-contract-artifacts`, `count-assertion-digest`,
`frozen-witness-digest`, `horizon-verdict-cases`, `trip-contract-evidence`,
`trip-contract-header`) and reused here rather than minted.

```phase-axis-declaration
# axis-orientation: rows
# axis-name: engagement
# governed-table: Decision 1 -> "The engagement axis and its six values"
# row-key-column: 1
# header-rows: 2
# difference-from-channel-record: ENGAGEMENT-UNDETERMINED
# axis-token              subject-kind
PERSON-LINKED             K1
SELF-STATED               K2
OPERATOR-STATED           K3a
THIRD-PARTY-STATED        K3b
UNSOURCED                 K4
ENGAGEMENT-UNDETERMINED   NO-SUBJECT-KIND
```

Two columns, both required, whitespace-separated; a line whose first non-blank character is `#` is
a comment and is ignored. The fence declares **six** axis tokens. **`axis-orientation: rows` is
load-bearing and is why no leading-column count appears here:** the axis tokens are **row keys** of
the table below, so a comparator extracting column *headers* would read that table's attribute
labels and diverge on a conformant record. A superseded specification of this criterion instructed
a leading-column count, which presupposes a column orientation neither record carries; it is
deliberately not carried, and `row-key-column` with `header-rows` is its orientation-correct
analogue. **Both records declare `rows`**, and that agreement is what makes the cross-record
assertion evaluable at all.

**`NO-SUBJECT-KIND` is a declared vacancy, not a placeholder.** The sixth token is precisely the
one with no subject-kind counterpart in the sibling's set, so the fence states that vacancy as a
literal rather than as punctuation a parser would have to interpret. It is the machine-readable
form of the named difference in § *Decision* 8.

**The engagement axis and its six values.** Row keys are compound where a counterpart exists: the
axis token and its subject kind, either side of the `≡` marker, both declared in the fence above.
The sixth row key is not compound, and that is the difference itself.

| Axis value | Shipped condition | Authored by | Model-entry class |
|---|---|---|---|
| **`PERSON-LINKED` ≡ K1** | `SELF-STATED` **and** frontmatter carrying `person: q`, resolving under `closure(p)` at one hop | the subject, across trips | `first-party` + C22 |
| **`SELF-STATED` ≡ K2** | a C12 entry projected from the person's own `travelers/<t>.md` | the subject | `first-party` |
| **`OPERATOR-STATED` ≡ K3a** | a C12 entry marked `[OPERATOR-PROVIDED]` **alone** | the operator, about a person who **may still file** | `operator-provided-only` |
| **`THIRD-PARTY-STATED` ≡ K3b** | a C12 entry marked `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` | the operator, about a person who **will never file** | `both-marks` |
| **`UNSOURCED` ≡ K4** | a roster row with no C12 entry, **or** a flagged-gap entry — `**Source:** none`, a `PROFILE MISSING` marker | nobody | — |
| **`ENGAGEMENT-UNDETERMINED`** | a read **this entry attempted** could not be completed | — | — |

**The value set closes over a live arbiter rather than over a preference.** `CLAUDE.md` states
*"Erasure must reach every model-entry class, and there are **exactly three**"* —
`first-party`, `operator-provided-only` (**dropped** under regeneration, having no source to
re-derive from) and `both-marks` (**carried forward verbatim**, the erasure silently undone) —
adding that *"the two file-less classes fail in **opposite** directions."* Those three, plus the
roster-only state below them and the composed state above, **yield five subject kinds in agreement
with `ADR-022` by construction rather than by negotiation**, and the read-failure value makes six.
An earlier pass of this design asserted four, by merging `operator-provided-only` into
`both-marks` — which are precisely the two classes the charter says fail in opposite directions,
so the merge was not a simplification but the erasure of the distinction that matters most.

**Four structural properties, each checkable rather than asserted.**

- **A partition with two ordered edges, not a lattice and not a sequence.** `OPERATOR-STATED`,
  `THIRD-PARTY-STATED` and `SELF-STATED` are **mutually exclusive by their marks** — an entry
  carries `[OPERATOR-PROVIDED]` alone, both marks, or neither — so they partition. Exactly two
  edges are ordered: `UNSOURCED` below the three, and `SELF-STATED` below `PERSON-LINKED`, because
  composition strictly adds. `THIRD-PARTY-STATED` is **terminal**, by `ADR-014`'s refusal.
- **The read-failure value sits outside the order.** No comparison is defined on
  `ENGAGEMENT-UNDETERMINED`, which is the right answer rather than a gap: a value meaning *the
  read did not complete* has nothing to be greater or less than. An earlier pass left it unplaced
  in a proposed `≥` relation; under a partition there is no `≥` for it to be undefined on.
- **The two ordered edges are different *kinds* of edge, and the corpus says which.** The
  mark-moving edges are **provenance changes**, shipped in full — *"supersede, do not merge… both
  marks are removed… an **update signal** is emitted."* The `SELF-STATED → PERSON-LINKED` edge is
  explicitly **not** one: *"composition precedence between two **first-party** values with no
  provenance mark on either side — not a supersession of a declared entry class, and not a
  provenance change."* **So the composition edge is not inert** — it is the one edge that moves no
  mark, and naming it correctly is what keeps the publish guard's supersession check from being
  asked to adjudicate it.
- **Not monotone.** A person can move down as well as up — an entry is dropped, a link is removed
  — so `ADR-015`'s no-audit-owed argument does not transfer to this axis and is not claimed.

**What the axis is not a measure of.** It is **not** interest, participation or effort. It answers
*on what basis does the engine hold this person, and who authored it*. Someone who read every word
and filled nothing in reads `UNSOURCED`, and that is correct: an axis reporting otherwise would be
inventing.

### 2. The domain is the profile-gap denominator, and a free-text mention sits outside it

> The domain of `engagement(t)` is the **`Person` cells of the `## Group` roster** — the corpus's
> own **profile-gap denominator** — under the canonical traveller key `reference/data-architecture.md`
> § 3.2 already fixes: *"the `## <Name>` heading text, lowercased, with every non-`[a-z0-9]`
> character removed"*. **Every roster member is individuated, so every roster member has a value**,
> including one with no file and no operator input, who reads `UNSOURCED`.

**The defined term is *the profile-gap denominator*, with the heading reference as its gloss on
first use.** That phrase is the corpus's own role-phrase for this exact set, in the clause this
record grounds on; the heading reference names the physical location. Two names for one object is
a cost this record's own § *Decision* 7 principle names, so one of them is the term and the other
is the gloss, rather than both being used interchangeably.

**A free-text party mention is outside the domain, and that is a decision rather than a gap.** The
shipped intake prompt's own examples are *"two kids, 6 and 9"* and *"my dad, 78, travelling on my
booking"* — no name, no key, no individuating token. The function therefore has **no argument**
there. **This is not the read-failure value**: the read completes; it is the *domain* that is
underivable. The corpus reaches the same conclusion in its own voice — *"**Never invented from a
`Party:` string.** A `Party:` value with no operator-supplied needs yields **no entry**… the name
arrives **with** the needs, from the operator, or there is nothing to key an entry on."*

**The entry event and the entry value are both named.** When the operator supplies that person's
needs, the name arrives with them, a `## <Name>` C12 entry appears, and the person enters the
domain at **the value their marks decide** — `OPERATOR-STATED` where the operator relays a
first-party traveller's own needs, `THIRD-PARTY-STATED` where the subject will never file. The two
marks are orthogonal, so entry is **mark-determined, never party-determined**, and this is
`ADR-014`'s already-accepted intake cost rather than a new one.

### 3. Four boundaries, one carry rule, and five never-carries

> A **phase boundary** is one of exactly four, and they are named rather than numbered bare:
>
> - **`EB-0` re-synthesis** — a synthesis pass regenerates the derived model.
> - **`EB-1` the axis** — a traveller's `engagement(t)` value moves along one of the two edges.
> - **`EB-2` trip** — one trip ends and another begins for the same person.
> - **`EB-3` lifecycle** — a trip moves between `ACTIVE` and `ARCHIVED`.

**`EB-0` is the boundary an earlier pass omitted, and it is not a new rule.** The charter already
states and grades it: the three model-entry classes behave in three different ways under a
regeneration — `first-party` **re-derived**, `operator-provided-only` **dropped**, `both-marks`
**carried forward verbatim** — and *"any fixture standing as the worked example of this rule must
exercise all three."* `EB-0`'s row **is** those three behaviours, never collapsed.

> **The carry rule.** A class carries across a boundary **iff the boundary does not change that
> class's own declared scope.** The rule reads the columns the artifact-class table already
> carries — `lifecycle` and `publish:` — and adds none.

**Five never-carries, and each is a class fact rather than a policy.**

| # | What never carries | Across | Why |
|---|---|---|---|
| 1 | every `rebuilt-each-synthesis` class | `EB-0` | regeneration is its declared scope; carrying it would be the shadow-state defect its own class name forecloses |
| 2 | C12 and C14 to any render, **in any form including anonymized** | every boundary | `internal-hard`, at its live membership — **C12, C14, C22 and C23** |
| 3 | a `both-marks` entry | `EB-2`, **permanently** | `ADR-014`'s cross-trip consent refusal closes rather than defers |
| 4 | a `DEST`-class field value | `EB-2` | its declared scope is one destination |
| 5 | a value of this axis itself | every boundary | it is a **present reading**, re-derived each synthesis, never a stored state to carry |

**Never-carry 2 is quoted at its live membership deliberately.** `reference/data-architecture.md`:770
reads *"never rendered **and** carrying values that must not reach a rendered page **in any form,
including anonymized**. Exactly C12, C14, C22 and C23."* **C22 is the durable person record and
C23 the group record**, both cross-trip and both `internal-hard` — so a two-member statement of
this limb would omit from a **privacy** rule exactly the two classes that outlive the trip. An
Accepted record in this corpus block-quotes that limb at a stale two-member membership; it is
recorded as a finding of this release in § *Findings and observations carried* and is **not**
inherited here.

**Never-carry 5 is the one a later slice is most likely to want to break**, because a stored value
is cheaper than a re-derivation. The cost of storing it is the whole of Option 1C: a shadow SSOT,
a writer in a file whose writer is the subject, and a staleness that fails toward *on record*.

### 4. Three join keys, one prohibition, and two kinds permanently unreachable

> **`EB-0`** — the normalized traveller key within a trip. **`EB-2`** — `person: psn-<token>`,
> inverted under `closure(p)` at one hop. **`EB-3`** — unchanged; the lifecycle boundary moves no
> identity. **At the render boundary there is no join key, none may be minted, and that is
> permanent.**

**The render prohibition is a class boundary, not a threshold.** `ADR-010` § 4 forecloses the
anonymized projection by name: a signal letting a reader tell *which* traveller acted is an
anonymized projection of a C12 value. Not a name, not a handle, not a stable pseudonym, not a key
fingerprint, not a per-traveller receipt. **At a render the only admissible signal is an aggregate
count paired with a content digest** — the escape `ADR-010` § 4 itself names, *detectability does
not require identity*.

**Which kinds are reachable across `EB-2`, stated positively because silence here reads as
coverage.**

| Axis value ≡ kind | Reference bearer | Across `EB-2` | Reachable? |
|---|---|---|---|
| **`PERSON-LINKED` ≡ K1** | the surrogate key | **yes** — `closure(p)`, one hop | **yes** |
| **`SELF-STATED` ≡ K2** | the path | **no** — trip-local by construction | **yes**, within the trip |
| **`OPERATOR-STATED` ≡ K3a** | **none today** | **no** — dropped by regeneration | **no — and not permanently** |
| **`THIRD-PARTY-STATED` ≡ K3b** | **none exists — a named gap** | **never** — `ADR-014`, permanently | **no — permanently** |
| **`UNSOURCED` ≡ K4** | the roster cell, identity only | **never** — no bearer to invert | **no — permanently** |

> **Two kinds are permanently unreachable — `THIRD-PARTY-STATED` and `UNSOURCED` — and a third,
> `OPERATOR-STATED`, is *presently* unreachable and may cease to be.** An earlier pass of this
> design wrote *"structurally empty, permanently"* across three kinds and thereby froze one that
> is **awaiting** a source rather than structurally without one. `ADR-014` does not close
> `OPERATOR-STATED`, and the shipped fixture says so in terms: a party member *"has simply not
> filed a profile yet, so the entry is a placeholder for a source that **may still arrive**.
> `[THIRD-PARTY]` marks a person who will never file one."* The narrowing is the correction; the
> un-freezing is its point, because *"this kind may still file"* is a claim about an **edge**, not
> about a row.
