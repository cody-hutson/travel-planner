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
