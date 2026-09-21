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
§ *Decision* 6 and holds for every count in this record.

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
