# ADR-027: Post-trip preference memory — outcomes resolved where they were measured, a group view over the trips the operator confirms, one durable dislike field, and no group slot

- **Status:** Proposed (2026-09-24)
- **Deciders:** repo maintainer
- **Driving work:** the *Post-trip preference memory: the founding decision* milestone. This record
  is its single head decision gate, landing before any feature slice in the shape `ADR-012`,
  `ADR-016` and `ADR-025` already ship.
- **What this record is, and is not.** It decides; it builds nothing. In this release it adds no
  class, no store, no writer, no reach row and no verb. It specifies one person-record field and the
  read-only slices that follow.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the maintainer's, taken at this milestone's close. It moves both halves of a
  two-artifact state: the `Status:` line above, and this record's `Status` cell in
  `reference/adr/README.md`.

## Context

**What ships, read live.** Every option below is bounded by what already ships, and this record
changes none of it.

- **C14, `outputs/satisfaction-metrics.md`, is a coverage snapshot.** It is
  `rebuilt-each-synthesis`, `derived` and `internal-hard`, and it is section-owned: the hub owns
  desire coverage and the validator owns needs compliance. `CLAUDE.md` calls it *"A coverage
  snapshot at synthesis time"*. Desire coverage is `covered` / `not covered`, per traveller per
  desire, with the priority tier carried beside each verdict (`reference/data-model.md`
  § *Satisfaction Metrics*).
- **An archived trip receives no derivation.** The freeze *"binds derivation, not bytes"*, and
  erasure is the one operation that writes to an archived trip (`CLAUDE.md` § *Archived trips —
  what the freeze binds*).
- **`history(p)` is a resolution, not a record.** `ADR-017` § 1 defines it as the trips whose
  traveller frontmatter carries `person: q`, `q ∈ closure(p)`, at one hop. Nothing is stored,
  *"reading is not derivation"* (§ 2), and the destination match is the operator's, made from
  presented candidates with *"no threshold anyone has to defend"* (O7).
- **The person record, C22, is written by its subject.** It is `writer: human`, and *"No agent
  writes a value into this file"* (`reference/schemas/person-record.md`).
- **The group record, C23, holds references only.** It has *"no free-text section"*, and the group
  id is recorded in no trip — *"What is recorded nowhere: the group id"* (`ADR-016` §§ 3–4).
- **Erasure is a table, and its accounting is graded.** The reach table in
  `skills/trip-record/SKILL.md` § `erase` carries its own accounting sentence — at `b199dc1`,
  21 + 5 + 4 = 30 rows (REACH, REPORT and OUT) — and `ER14` grades it against the table in both
  directions.

**The epic's three absences.** The engine computes desire coverage per traveller on every synthesis
and keeps it only as a trip output, because the class inventory carries no post-trip artifact of
any kind. No field at any scope holds a stated dislike. And the group record has no slot for how a
party travels together — by construction, in its schema.

**The operator's scope decisions are inputs, not open questions.** They were set on 2026-09-19
(Saturday): memory is **both person- and group-scoped**; it captures **both measured outcomes and
stated dislikes**; capture is **at archive**; and the posture is **offer-only — the human writes**.
The third was re-confirmed on 2026-09-23 (Wednesday) as intent rather than mechanism: a trip's
outcomes survive the trip as they stood when it closed, and how they survive is this record's to
decide.

**The inherited constraints.** `ADR-014` stands: no durable cross-trip artifact is created for a
`[THIRD-PARTY]` party member, and that refusal is closed rather than deferred. `ADR-015` clauses
6–7 govern the person record — no mechanical write, and a prompt may name a field and a remedy but
never a candidate value. The archived-trip freeze binds derivation. `internal-hard` holds at its
live membership. And the capability is both person- and group-scoped, and offer-only.

**Conformance is owed to the two journey records, as written.** `ADR-025` declares the trip
boundary `EB-2` and the lifecycle boundary `EB-3` this capability crosses, one carry rule over the
class table, and the join key this slice may use; `ADR-026` declares the channel-set this
capability's renders sit on. Both are Accepted and immutable as to their decisions, so this record
conforms to them rather than re-deciding anything they settle (§ 7).

**Two live facts shape the design.** C14 is a synthesis-time snapshot: it records whether the plan,
when it was last synthesized, covered a desire, and nothing that happened on the trip. And
`Rather skip` is a destination veto — destination ideation reads it as a hard filter, *"Apply
vetoes (`Rather skip` = hard filter)"* (`agents/destination-ideation.md` § *Method —
equity-weighted coverage*, step 2) — so a dislike of a kind of outing needs a home of its own
rather than a second meaning for that label.

**Baseline.** Every corpus fact in this record was read live at `b199dc1`, the commit this release
branched from. Counts are authored to `ADR-013`'s admitted forms — anchored to that commit, or
written out as arithmetic — and none is left without a basis.

## Decision drivers

- **Conform before superseding.** Take a design that reverses no Accepted decision unless a reason
  beyond convenience exists (`reference/adr/README.md` § *Convention*).
- **One source per fact.** A coverage verdict lives in the trip that measured it. A second home
  drifts with nothing to arbitrate (`CLAUDE.md` § *Key Rules*, *link, don't copy*).
- **Erasure stays total and computable.** Every durable location created is a reach row, and every
  location read is either a reach row or not person data.
- **The freeze binds derivation.** Reading an archived trip is a read.
- **Consent-safe by construction, argued per half.** Only a person-linked traveller carries a key
  across `EB-2` (`ADR-025` § 4), so the measured reads cannot reach a `[THIRD-PARTY]` member. No
  stated half exists that would need an argument of its own.
- **Offer-only: the human writes.** Inherited, and it binds both scopes.
- **Reuse over re-implementation — checked at the condition, not at the token.** Reuse
  `history(p)`, `ADR-017`'s terminal tokens and its candidate-confirmation shape, `ADR-025`'s
  verdict triple and the shipped report grammar. A reused token is printed only where the reusing
  surface's condition implies the meaning its source gives it, so § 1 and § 2 write each condition
  beside its token.
- **Absence never reads as a negative.** An unrecorded outcome is *unknown*, and an empty candidate
  list is not *this party never travelled together*.
- **A view is not a memory, and this record must not claim it is.** A group-scoped read of
  individuals' rows does not become party-owned by being scoped to a group.
- **The smallest reversible commitment.** A design that stores nothing has nothing to migrate.

## Options considered

Release class `novel`. Each choice with more than one candidate is generated, narrowed and then
weighed. Where the operator bound a choice at the design gate on 2026-09-24 (Thursday), the bound
option is stated with its grounds and is not re-litigated. Every ground is a corpus fact read live
at `b199dc1`.

### A — Outcome retention

**Generated.**

- **A1** — carry outcomes into the person record, C22.
- **A2** — *Carry*: harvest them into a new class at archive, ahead of the freeze.
- **A3** — keep a copy inside the trip.
- **A4** — *Resolve*: read them in place from each archived trip.
- **A5** — *Resolve* behind a cache.

**Narrowed.**

- **A1 is refused on an inherited constraint.** `ADR-015` clause 6 says *"No mechanical write is
  added"*, and C22's permitted writes are *"none authoring a value"*.
- **A3 answers nothing.** A copy that lives in the trip dies with the trip.
- **A5 is refused on `ADR-012` O10's ground** — *"Staleness is fatal and undetectable"* — because a
  cache is a persisted `history` result.
- **The survivors are A2 and A4.**

| Criterion | **A2 — *Carry*** | **A4 — *Resolve*** |
|---|---|---|
| New in-model class | **Yes.** It becomes C24, and out-of-model C24–C29 renumber to C25–C30 on `ADR-016` O8's precedent; `reference/data-architecture.md` § 1.1's class-count heading, its *"closed at 29"*, and the `VA_CLASS_HEADING` literal in `scripts/validate-artifacts.sh` all move | none |
| Writer | a new engine writer on `/trip-decommission archive` | none |
| `internal-hard` | **Widens to a fifth member.** At `b199dc1` the block quote *"Exactly C12, C14, C22 and C23"* recurs in `reference/data-architecture.md`, `ADR-010`, `ADR-025` and `ADR-026`, and the phrase *"the fourth member"* in `reference/data-architecture.md`, `ADR-010`, `ADR-016` and `reference/schemas/group-record.md`; every one of them moves | unchanged |
| Store | a fifth rooted-ignore store: a signpost, a schema, a witness, a coverage row and a publish-guard group | none |
| Erase reach | a new reach row, plus an `ER14` restatement | **no row** — row 11 already substitutes inside C14 |
| `/trip-decommission` | breaks standing rule 6 (*"Creates nothing"*) and rule 7 (*"Writes only under `trips/<slug>/`"*); widens `archive`'s **Reads:** beyond `trip-log.md` and `trip-context.md`; falsifies `CLAUDE.md`'s *"`/trip-decommission archive` moves nothing"* | unchanged |
| `ADR-025` § 3, the carry rule | **Conforms.** A new cross-trip class carries across `EB-2` under the rule, because that boundary does not change its declared scope, and C14's own values stay trip-scoped. `ADR-025`'s *Scope taken, and scope left* leaves *"what the post-trip memory decides about its entity home"* phase-local, and so leaves it to this record | **Conforms** — nothing carries |
| `ADR-017` § 1 | **Not reached by AC-7.** Its *"No resolution result is persisted anywhere"* is scoped to `history(p)`. Whether a per-person store with trip provenance would reverse it is a supersession question this record does not have to answer, because it takes A4 | it **is** `history(p)`, narrowed |
| One source per fact | a second home for C14 values, keeping outcomes attributed to a person after an unlink or after the trip is deleted, with nothing to reconcile the two — `ADR-012` O10's staleness class, as a cost | one home |
| Freeze | the harvest must land before the marker, adding a step to a verb whose order `CLAUDE.md` calls *"load-bearing"* | a read of a frozen file |
| Consent (`ADR-014`) | holds, if keyed by `psn-` id | holds by construction: only person-linked travellers are reached |
| Merge, unlink, reopen | needs re-keying and replace-by-trip semantics, and an unlinked trip's copy survives | inherited: `closure(p)`; the unlink blind spot is erasure's own (`ADR-017` § 6) |
| Hand-deleted trip folder | **Outcomes survive** — the one criterion A2 wins, and also a privacy cost | outcomes go with the trip |
| Read cost | a store read | `O(ΣK)` frontmatter reads plus a body read per reached trip; academic at household scale (`ADR-017` § *Costs and residual risks*) |
| Schema evolution | a second schema to evolve | the archived C14 is read tolerantly (`reference/data-architecture.md` §§ 7.2 and 7.5) |
| Reversibility | EXPENSIVE once operator stores exist | CHEAP |

**Chosen: A4, *Resolve*.** A2 wins one criterion and costs a class, a writer, a store, a reach row,
an `archive` change and a second home. No Accepted record forecloses A2 — the matrix decides it,
and the operator carried the choice forward at the design gate.

### B — Group scope

The option set, and where each option fell:

- **B1, B3 and B4 — slot or live-binding designs that compose group values into trips.**
  **Rejected** on the reversals they force: of `ADR-016` § 4, whose expansion writes the group id
  into no trip and leaves no residue there, and of `ADR-025` § 4, whose join keys carry no group key
  across `EB-2`.
- **B2 — a slot on C23, consumed at the offer.** **Not taken, and kept as the way back in.** It
  reverses `ADR-016` § 3, and § 2 below prices it.
- **B5 — members' records only.** **Not taken.** A person record holds no measured outcome, and
  A1's refusal keeps it that way, so a group reading built on records alone reads nothing a trip
  measured. The chosen view keeps its one property, that every row belongs to one member, and takes
  the rows from the trips that measured them.
- **B6 — containment over current members, plus a stated half read from the party-level blocks of
  their joint trips.** **Withdrawn.** Containment keys the view on today's membership, so a
  membership edit rewrites which trips count; the party-level blocks carry mixed subjects that no
  reach row names; and reading them as the party's memory re-reads the group criterion rather than
  meeting it (§ 2's grounds).
- **The chosen shape — a view over the trips the operator confirms**, bound by the operator at the
  design gate. Its sub-choices were generated and narrowed here:

| Sub-choice | Candidates | Chosen, and why |
|---|---|---|
| **Candidacy** | (i) containment over current members · (ii) a similarity threshold · (iii) the operator types trip slugs freely · (iv) archived trips on which at least two current members are linked, confirmed by the operator | **(iv).** (i) keys the view on today's membership. (ii) is what `ADR-017` O7 refuses. (iii) offers the operator no evidence. The floor is definitional rather than a threshold anyone defends: a trip with one linked member is that member's own history, which the person view already covers |
| **Party size shown** | the roster's data-row count · `- **Total travelers:**` · both | **The data-row count.** The roster is *"the name authority"* and *"the profile-gap denominator"* (`agents/00-enrichment.md`; `ADR-025` § 2). A `Total travelers` value that *"legitimately exceeds the named-traveler count"* is a real state (`skills/trip-record/SKILL.md` § `group`), and its unnamed members carry no key, so no comparison with `k` is possible |
| **What each candidate line carries** | slug · + destination string · + names | **Slug, `k of n` and roster size only.** The slug already carries the destination and year by convention. The `Primary destination` line is in no reach row, so printing it would widen the transcript residual. Names are never printed |
| **What the view shows** | per-desire rows · tier × verdict tallies per member per trip · a party total | **Tallies per member per trip.** Prior desire text is never quoted (`ADR-015` clause 7). A party-level total would be group-owned memory by another name, and it is a number the metric layer declines to compute (*"No degree, weight, or percentage"*) |
| **Choosing the group** | the operator names it · derived from `t₀` · both | **Both, and the engine never chooses.** A named `<group-id>` runs. With no argument, every qualifying group is listed by id and member count — never by display name — and the view stops |

### C — The `Dislikes` field

| Sub-choice | Candidates | Chosen, and why |
|---|---|---|
| **Class and scope** | `PERSON` · `DEFAULT` · `TRIP`; `slot` · `block` | **`DEFAULT`, `slot`.** By the tests of `reference/data-model.md` § *The decision rule for mixed cases*: the subject is the person; the field is answered, not computed; and a missed preference is *"a worse trip, not a broken one"*, whose safety-shaped twin is a Need |
| **Delineation** | a bare *experiences* gloss · a list of subjects · boundaries grounded on how each sibling is consumed | **Consumer-grounded.** It is what the person would rather not be offered **at a destination**, read as a soft signal. Places are `Rather skip`, a destination veto; timing is `Day rhythm`; how full a day is `Pace`; travel days are `Journey comfort`; food is `Cuisine appetite`; anything unsafe is a Need |
| **Consumption** | a hard exclusion · a veto · a soft per-traveller signal | **Soft and per-traveller.** It never removes a destination or a candidate for the party, never gates the validator, and is never scored. A traveller's own `Desire` on this trip governs over their `Dislikes` where the two name the same thing |
| **Marker** (`ADR-023` D2.4) | `closed` · `open` | **`open`.** The examples are suggestive, and any kind of outing is a legitimate answer |

**Where a composed change to the field routes is not a sub-choice of this record.** § 3 states the
unrouted posture and names the pending decision that owns it.

**Widening `Interests` to carry both polarities — rejected.** The operator's decision at the design
gate binds a new field, and the rejection also stands on three grounds of its own:

1. **The corpus already chose a separate label for the negative half of a lean.** The
   classification row for `Rather skip` calls it *"the negative half of the same lean"*, beside
   `Would love` in the same section. `Dislikes` beside `Interests` is that shape.
2. **The precedent offered for widening does not carry over.** It is `Cuisine appetite`, which
   already asks for *"specific loves & avoids"* in one value — but that field is unstarred and has
   no menu, while `Interests` is its section's one starred field, and its bracket says *"Copy across
   the ones that spark from the list above"*.
3. **The widening's advantages largely fall away under `admissible`.** `HZ2` is unchanged for a
   new admissible field too, and the router gap and the `[DERIVED]`-block dependence were
   properties of `required`. What remains is one label and the Wave-1b cascade that
   § *Follow-on build slices* names.

### D — Offer-only, per writer class

- **Person record.** Inherited — `ADR-015` clauses 6–7 — so no options are generated.
- **Group record.** An operator-written preference on C23 presupposes a slot, which § 2 declines.
  An engine-written derived memory is not offer-only. A remedy written into a trip's party-level
  blocks is withdrawn with the stated half. **Chosen: nothing writes a group preference, because
  none exists in this capability.**

### E — Precedence typing

| Candidate | Verdict |
|---|---|
| Claim the operands satisfy the clause, because "the kind is the same" | **Refused.** It redefines *kind* by effect, where `ADR-025` § 1 types its edges by operands |
| Re-type the rule as something other than composition precedence | **Refused.** AC-4 requires the rule to be typed as `ADR-025`'s composition-precedence edge |
| **A named extension** | **Chosen.** It keeps every property the clause states except the first-party condition, which it names as unmet, and it adds no edge to the engagement axis |

### F — The freshness relation

| Sub-choice | Candidates | Chosen |
|---|---|---|
| Vocabulary | a new family · the shipped triple | **The shipped `CURRENT` / `BEHIND` / `UNDETERMINED` triple, verbatim** — `ADR-025` § 6, and its own option 5E |
| Placement | inside `trip.freshness` · in the rendering verb's own report | **In the verb's own report.** The operands belong to another trip, and `trip.freshness` is a property of *"the resolved trip's own artifacts"* (`skills/trip/SKILL.md` § *The freshness report*) |
| Source side | a rule reading the whole section · an explicit list · a rule pinned to one sentence | **Pinned to one sentence:** the one in `reference/data-model.md` § *Three metric types* that names what coverage is *"determinable from"*. The same section names C14's inputs elsewhere with a narrower membership, so a rule reading the section at large could land on either |
| Arrival | with the offer · with the first wave that renders a retained verdict | **With the first wave that renders** — the operator's decision at the scope lock on 2026-09-24 (Thursday). A render that carries a retained verdict carries its relation verdict from the first slice that renders one (W1a-0) |
| Name | `plan-to-coverage` | the shipped `<source>-to-<derived>` shape. The token and its root arms `plan-to-` and `-to-coverage` measure 0 / 0 at `b199dc1`, against shipped siblings `itinerary-to-build` and `research-to-placement` that fire |
