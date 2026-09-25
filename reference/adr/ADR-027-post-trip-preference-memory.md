# ADR-027: Post-trip preference memory — outcomes resolved where they were measured, a group view over the trips the operator confirms, one durable dislike field, and no group slot

- **Status:** Accepted (2026-09-24)
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

## Decision

### 1. Outcome retention — resolved where it was measured

> **`outcomes(p, t₀)`** — for a person id `p` and the trip being planned `t₀`: for each trip
> `t ∈ history(p)` with `t ≠ t₀` and `lifecycle(t) = ARCHIVED`, the rows of
> `t/outputs/satisfaction-metrics.md`'s desire-coverage section whose traveller cell's key equals
> the key of the stem of `t`'s bearer file — the one `t/travelers/*.md` whose frontmatter carries
> `person: q`, `q ∈ closure(p)`. Where the point of use resolves no trip, the `t ≠ t₀` exclusion is
> vacuous.

**Terms, cited rather than restated.** `history(p)` and `closure(p)` are `ADR-017` § 1, at one hop.
The key is `reference/data-model.md` § *Traveler identity*'s two-step key; since
`normalize(derive(P)) == normalize(P)`, the stem's key equals the roster name's. `lifecycle(t)` is
`E2`'s `**Lifecycle:**` value, absent → `ACTIVE` (`G4`).

| AC-1 attribute | Decision |
|---|---|
| **Join key** | `EB-2` on `person: psn-<token>` under `closure(p)` at one hop — the key `ADR-025` names for this slice; `EB-0`, the traveller key, inside a trip. No key is minted. **Exactly one bearer per trip**, else `UNDETERMINED` (W1a-4) |
| **Trips reached** | `ARCHIVED` only, excluding `t₀`; a reopened trip is `ACTIVE`. Only `PERSON-LINKED` travellers (K1): K2–K4 have no key across `EB-2` (`ADR-025` § 4), so a `[THIRD-PARTY]` member gets no cross-trip reading, by construction |
| **What is read** | The desire-coverage section, and in it the traveller, tier and verdict cells. The section is found by header label, never by position (W1a-2). **Never** the desire's text, needs compliance, or the balance signals |
| **Freeze-safe** | Nothing of `t` is written, regenerated or re-derived (`CLAUDE.md` § *Archived trips*); `ADR-017` § 2: *"reading is not derivation"* |
| **Terminal states** | Each token with its condition, in the table below |
| **Old instances** | Read under `reference/data-architecture.md` § 7.2's tolerant read. A reader never fails on a version it does not recognise |
| **Unchanged** | `/trip-decommission archive` (it still *"moves nothing"*), C14's writers, the class table, `internal-hard`, and the reach table |

**The person view's terminal set — each token printed only under the condition beside it.**
`ADR-017` § 5 defines these tokens for its own resolution; this view reuses a token only where its
condition implies that meaning, and prints a plain line where none does.

| Output | Condition |
|---|---|
| `RESOLVED(n)` | the scan completed and reached archived trips other than `t₀` carrying `p`'s edge; `n` counts those reached trips, and each renders one of the per-trip readings below |
| *edges exist, none archived* | the scan completed, `p`'s edge sits on trips other than `t₀`, and none of them is `ARCHIVED`. A plain line: never `NO-EDGE-FOUND`, and never a count of zero |
| `NO-EDGE-FOUND` | the scan completed and **no** trip other than `t₀` carries `p`'s edge |
| `NO-REFERENCE` | the traveller the view was asked about carries no `person:` reference, so there is no edge to invert and **no scan runs** |
| `UNDETERMINED` | the store or the trip population could not be read, a bearer was present but unreadable, a reference dangled, or a stub was malformed — `ADR-017` § 5's conditions, inherited |

**Per reached trip**, exactly one of: **tier × verdict tallies**; *holds no outcome record* — the
file or its desire-coverage section is absent, or no row carries the bearer's key; or
`UNDETERMINED` — the section is unreadable, its header names none of a needed cell, or the trip
carries more than one bearer. **No state reads absence as `not covered`.**

**The wording rule, stated at the rule.** Every retained verdict is rendered as **plan coverage as
last synthesized** — whether the plan, when it was last synthesized, covered the desire. It is
never rendered as what happened on the trip, what a traveller enjoyed, or how the trip went. An
archived C14 is *"A coverage snapshot at synthesis time"* (`CLAUDE.md`), frozen at archive, and it
records nothing that happened after that synthesis. Every render also carries each reached trip's
`plan-to-coverage` verdict (W1a-0), so a snapshot that predates a later status change or plan edit
says so — and what that verdict means, and does not, is stated with the relation.

**Why A4 over A2.** The matrix in § *Options considered*, with no Accepted record foreclosing
*Carry*: it wins one criterion — a deleted trip folder's outcomes survive — and costs a class, a
writer, a store, a reach row, an `archive` change and a second home.

**Reversibility: CHEAP · confidence HIGH.**

### 2. Group memory — a view over the trips the operator confirms

> **`members(G)`** — the survivor ids of `groups/<G>.md`'s `## Members` bullets, each resolved
> through at most one `merged-into:` hop (`ADR-016` § 3's inherited resolution) and deduplicated. A
> bullet that does not resolve is reported `UNDETERMINED` by id and is not a member. `n` is the
> count of `## Members` bullets — the member count `group-list` prints — with every unresolved
> bullet among them shown as `UNDETERMINED`.
>
> **`k(t)`** = `|{ m ∈ members(G) : t ∈ history(m) }|`.
>
> **`cand(G, t₀)`** — the trips `t` with `t ≠ t₀`, `lifecycle(t) = ARCHIVED` and `k(t) ≥ 2`. Each
> candidate is rendered as its slug, `k(t) of n`, and `r(t)`, the number of data rows in `t`'s
> `## Group` roster table — and nothing else.
>
> **`confirmed(G, t₀)` ⊆ `cand(G, t₀)`** — the candidates the operator confirms were this party's
> trips. The engine offers no default selection, computes no similarity, and applies no threshold
> beyond `k(t) ≥ 2`. The confirmation lives in the session and is **never stored**.
>
> **The group view** — for each `t ∈ confirmed(G, t₀)` and each `m ∈ members(G)` with
> `t ∈ history(m)`: `m`'s rows of `outcomes(m, t₀)` on `t`, rendered under `m`'s person id as
> tier × verdict tallies. Each is worded as plan coverage as last synthesized, with `t`'s
> `plan-to-coverage` verdict. **No total is computed across members or across trips.**

- **Why `k(t) ≥ 2` is not a threshold anyone defends.** It defines *joint*. A trip with one linked
  member is that member's own history, which the person view already shows. The floor admits every
  candidate, and the operator decides each one — `ADR-017` O7's shape, where partial matching
  *"is the general case"*.
- **A membership edit.** `group-add` of someone who never travelled raises `n` and moves no `k(t)`,
  so no candidate disappears. `group-drop` can drop a trip's `k(t)` below 2, and that trip leaves
  the list. The list is recomputed and shown on every invocation, and nothing about it is stored
  (W2-1).
- **Choosing the group.** A named `<group-id>` runs. With none, every *qualifying* group — at least
  two resolvable members linked on `t₀` — is listed by **id and member count only, never by display
  name**, and the engine chooses none (W2-4). Where no trip is resolved, the group must be named.
- **Consent, argued per half.** The measured half joins only on person-linked keys, so no
  `[THIRD-PARTY]` member is reached. `r(t)` is a count that individuates no one, and erasure keeps
  the same count by design — row 5: *"Erasure does not reduce the party"*. There is no stated half,
  so there is nothing else to argue.

**The group view's terminal set — each output printed only under the condition beside it.**

| Output | Condition |
|---|---|
| `UNDETERMINED` | the trip listing or the group record cannot be read. The population canary `G1` is inherited, so an unreadable listing never becomes *no joint trips* |
| *fewer than two resolvable members* | the group resolves fewer than two members, so no scan runs, and the view says so |
| *no joint archived trip* | the scan completed, some member's edge exists, and no archived trip other than `t₀` carries edges for two or more members. A plain line — **`NO-EDGE-FOUND` is never printed while any member's edge exists** |
| `NO-EDGE-FOUND` | the scan completed and **no** member's edge exists on any trip other than `t₀` |
| `UNDETERMINED`, per candidate | that candidate's roster cannot be read, so `r(t)` is not known |
| `UNDETERMINED`, per bullet | a `## Members` bullet does not resolve; it is counted in `n` and is not a member |

None of these reads as *this party has not travelled together*.

**This record decides `ADR-017` § 9's open item for the group view, and names what it costs.** That
item asks whether resolution can run without naming a person, and leaves it undecided because
resolving every linked traveller in one pass *"multiplies the transcript surface"*. The group view
is that operation: invoked on a group id, it resolves `history(m)` for every member. **It may run —
on CH-3 only, bounded by § 4's transcript bound.** The multiplication is stated rather than
implied: the render prints one line per member per confirmed trip. On `ADR-026`'s `audience` axis
the view adds no reader — the operator already holds every archived trip's C14 locally. **On the
`observers` axis it is not free:** CH-3's `observers` value is `third-party` (`ADR-026` § 3), the
transcript of an operator session run through an assistant that retains it. That residual is
accepted, bounded to ids and tallies, and named here.

**What is declined, and what is delivered — stated in terms.** The epic's group criterion reads:
*"A group carries its own travel memory, distinct from the union of its members' — the pattern that
belongs to the party rather than to any individual in it."*

- **Declined — the party-owned half**, under the driving card's AC-2 *"met or declined"* branch.
  That is memory which belongs to the party rather than to any individual.
- **Delivered — a group-scoped *view*, not a group-owned *memory*.** It shows members' own
  measured outcomes, restricted to the trips the operator confirms were the party's. Every row in
  it belongs to one individual. **This record does not claim the view is distinct from the union of
  members' memories, and it does not claim the criterion is met.** The inherited scope decision
  (*both person- and group-scoped*) is honoured at the level of scope — a group is an argument of
  the read — not of ownership.
- **Why declined — three grounds, each read live:**
  - The only party-level surfaces are `trip-context.md`'s `## Soft Preferences`, `## Trip Style`,
    `## Budget Posture` and the `Dietary preferences` line, and they carry mixed subjects. In the
    tracked Tokyo example, `## Trip Style` names roster members and lists venues,
    `## Budget Posture` prices meals in JPY and names venues, and the `Dietary preferences` line
    restates a hard constraint.
  - No erase reach row names any of them.
  - The group record has *"no free-text section"* and *"holds no authored value"* (`ADR-016` § 3;
    `reference/schemas/group-record.md`).

  No admissible party-owned source exists, and minting one is a slot.
- **The way back in — named, priced, not taken.** It is a preference slot on C23, admitted by a
  **section-scoped supersession of `ADR-016`** (§ 8's I-A). Its price:
  - § 3 is reversed.
  - § 2's writer decision is re-grounded, because the schema's *"A group record holds no authored
    value"* is its ground, and a preference section is an authored value.
  - § 5 is extended: a reach disposition for the new section, `ER14`, and `GM3`'s *"every location
    erasure reaches on this class is inside the member section"*.
  - § 6 is extended: a write verb, and standing rule 12's operation class.
  - One Convention sentence admitting section-scoped supersession is added to
    `reference/adr/README.md`, together with a status suffix nothing grades.
  - The slice also owes § 5's divergence report below, with a computable join.

**No slot, so there is no `ADR-016` instrument (§ 8).** `ADR-016`,
`reference/schemas/group-record.md`, `groups/README.md` and `GM1`–`GM3` are untouched, and Wave 2's
four-surface change set is empty.

**Reversibility: CHEAP · confidence HIGH on conformance, MEDIUM on value.**

### 3. The Dislikes field

| Attribute | Decision |
|---|---|
| **Label** | **`Dislikes`** — the plain-plural sibling of `Interests`, sharing no leading token with `Rather skip`. As a label it measures 0 / 0 at `b199dc1`, against `Rather skip`, `Cuisine appetite` and `Interests`, which all fire |
| **Form, position** | `templates/person-intake.template.md` § `## Interests & tastes`, immediately after `Cuisine appetite`, **unstarred**: `Interests` holds that section's one star (`reference/data-model.md` § *The starred pass*) |
| **Class / `Ovr?` / Scope** | **`DEFAULT`** / **Y** / **`slot`**, by the decision rule's tests; its siblings `Interests`, `Cuisine appetite`, `Rather skip`, `Day rhythm`, `Journey comfort` and `Pace` are all `DEFAULT` / `slot` |
| **Horizon** | **`admissible`**, the operator's decision. A present `[VALID-THROUGH <YYYY-MM>]` mark is honoured (`ADR-015` clause 8); none is owed or asked for; `HZ2` is unchanged. **The epic's AC-8, honestly:** the field declares a value on the total axis, but a re-confirmation path exists only where a month is marked. An unmarked dislike composes as answered indefinitely — the trade accepted over `required` |
| **Subject, delineated** | Kinds of activity or outing the person would rather not be offered **at a destination**. It excludes **where** (`Rather skip`, a destination veto), **when** (`Day rhythm`), **how full a day is** (`Pace`), **travel days** (`Journey comfort`), **food** (`Cuisine appetite`) and **anything unsafe** (a Need, `PERSON`) |
| **Classification row** | Row 32, after `Cuisine appetite`, with rows 32–39 renumbered to 33–40. No citation of those row numbers exists at `b199dc1` |
| **Form-contract row** | `ADR-023` D2.6 Q3 key **(`Interests & tastes`, `Dislikes`)**, with the section resolved as a leading segment. `ADR-024` § 1 key **(the durable form's single owned region — the whole form, `writer: human`) × (the trivially true condition — the writer does not vary with artifact existence or lifecycle)**. D2.4 marker **`open`**. Output class `people/<person>.md` (C22) |
| **Composition** | `K5` and `K6` unchanged; `EXPIRED` and `HORIZON-UNCONFIRMED` arise only from a present mark (`ANSWERED()` clauses (i) and (ii)); no disposition is added |
| **Provenance** | Outside `## Needs`, so no `[OPERATOR-PROVIDED]`; `[THIRD-PARTY]` is refused in C22. **Always first-party** (`reference/schemas/person-record.md`) |
| **Consumption** | Carried through by label in the interests-&-tastes facet enumeration (W1b-3). A **per-traveller soft signal** in candidate selection and placement (W1b-5): never a veto for the party, never a validator gate, never scored — the epic adds no satisfaction metric, and the validator gates *"on Desires only"*. **A traveller's own `Desire` on this trip governs over their `Dislikes` where both name the same thing** |
| **Routing a composed change** | **Unrouted.** A composed `Dislikes` change — a record edit (enrichment trigger `T1`) or a lapsed voluntary mark (trigger `T7`), landing at the report's exit 1 — is reported under **no** router class, exactly as `Interests` and `Cuisine appetite` are today. The enrichment prompt's *"The mapping is total"* has no class for any interests-&-tastes facet, and the router's classes admit no fifth (*"never add a fifth"*). Where every unmapped `DEFAULT` facet routes is one decision, pending (see *References*); it decides `Dislikes` with its siblings, rather than this record deciding it alone. The report line names the field, never its value |
| **Merge** | Inherited from `ADR-012` § 1: unequal values refuse, and an expired value loses to a live one |

**Wording sources for Wave 1b.** `ADR-023` D2.3 makes the bracket the authoritative home, so Wave
1b owns the final text; these are its starting points.

- **The form bullet:** `- **Dislikes:** [open: Kinds of activity or outing you'd rather not be offered on a trip — e.g., "theme parks, big guided group tours, shopping, nightclubs". Where you'd rather not go is Rather skip; early starts and late nights are Day rhythm; how full a day gets is Pace; travel days are Journey comfort; food is Cuisine appetite; anything that would make a trip unsafe for you is a Need. Skip if nothing comes to mind.]`
  — the `open: ` head is written only once the form carries the `ADR-023` D2.4 markers (W1b-6).
  None of the examples is a sibling's bracket example, and *"shopping"* is drawn from the
  `Interests` tick list on purpose, so one vocabulary serves both polarities.
- **The classification rationale cell:** *"The negative half of `Interests` — kinds of activity or
  outing the person would rather not be offered at a destination, read as a soft signal and never
  as a veto. Durable, and a trip may legitimately diverge. Where to go is `Rather skip`, which
  destination ideation reads as a veto; when is `Day rhythm`; how full a day is `Pace`; travel days
  are `Journey comfort`; food is `Cuisine appetite`; an aversion whose breach is a safety or
  integrity defect is a **Need**."*
- **The section preamble:** *"The broad stuff you're drawn to, and anything you'd rather not be
  offered — a soft signal that helps shape what gets picked on any trip. Skip any line if nothing
  stands out."*
- **The Step-7 ask, appended:** *"Then any kind of activity or outing they'd rather not be offered —
  not places, times, pace, travel days or food, which have their own lines."*

**Reversibility: CHEAP · confidence HIGH**, becoming EXPENSIVE once operator records carry the
label, because the store is git-ignored. The consumption behaviour is Wave 1b's to build.

### 4. Offer-only, per writer class

| Writer class | Who writes | What offer-only means there |
|---|---|---|
| **Person record** (C22, `writer: human`) | The person, in an editor | **`ADR-015` clauses 6–7, unchanged**: no mechanical write, no verb, schema unedited; a prompt may name a field and a remedy and **never carry, quote or offer a candidate value**. A measured outcome's remedy is the traveller stating this trip's `Desire`; outcomes never pre-fill it, and `ADR-017` § 9's `Desire` hook stays open. A dislike's remedy is the person editing their record; the offer may say a `Dislikes` answer exists, never quote it. **No enum value is offered**, unlike `ADR-017` § 4 |
| **Group record** (C23, `writer: operator`) | **Nobody, for this capability** — there is no slot, and the party-owned half is declined; C23 stays written only by `ADR-016`'s verbs | The view is a read and offers nothing to write anywhere. Its one ask — confirming candidates — is not stored |
| **Archived trips** | Nobody | The freeze. Nothing is written |
| **The trip being planned** | Its travellers, through the ordinary authoring path | The offer writes nothing. Only a traveller's own answer lands |

**Audience per half.**

| Half | CH-2 (intake; far side the traveller; audience `party`) | CH-3 (command surface; audience `operator`) | CH-1 |
|---|---|---|---|
| Person view, `outcomes(p, t₀)` | **only when the viewer is `p`** | yes | never |
| Group view | **never** | **yes** | never |

**Transcript bound** (erase row 24; `ADR-017` § 6). A render carries slugs, member person ids,
tier × verdict tallies, `k of n`, roster sizes and relation verdicts with the operand's file name —
never a display name, a desire's text, a `Dislikes` value, a destination string or a record body.
It lives in read-only surfaces with their own `**Reads:**`, never inside `## profile`, `## history`
or enrichment (`ADR-017` O11–O13; W3-8).

**Reversibility: CHEAP · confidence HIGH.**

### 5. Person-over-group precedence

> **The rule, stated at the rule.** Where a group-scoped value and a person-scoped value bear on
> the same traveller and the same field, the person-scoped value governs for that traveller, and the
> divergence is reported — never resolved silently in either direction.

- **The operands.**
  - A *person-scoped value* is that traveller's composed value: their traveller file plus the
    record it references, under the lattice.
  - A *group-scoped value* is a value held in a labelled slot keyed to the same field, whose
    referent is the party as a whole rather than any one traveller in it.
- **The typing: composition precedence, by named extension.**
  - The defining clause (`agents/00-enrichment.md`, quoted by `ADR-025` § 1) types *"composition
    precedence between two **first-party** values with no provenance mark on either side — not a
    supersession of a declared entry class, and not a provenance change"*.
  - A group-scoped value is not first-party: its writer is the operator (`writer: operator`), and
    no traveller states it about themselves. So this rule's operands **do not satisfy the
    first-party condition, and this record says so**.
  - It keeps every other property: no mark moves, no provenance changes, no entry class is
    superseded, and the reserved word is not used. It is **not an edge of the engagement axis**,
    which keeps its two edges (`ADR-025` § 1).
- **Where it binds — at the offer, narrow.**
  - In per-traveller composition it holds by construction: the arguments of `V(f)` are `C`, `p`,
    `A`, `r` and `s`, and no group-scoped value is among them.
  - At the offer, under § 2's view, **there is no group-scoped value at all**. The group view
    carries members' own outcomes, and the party-owned half is declined. The rule therefore holds by
    absence, and **no divergence line is stated**, because no computable join exists from a group
    operand to a `Field Scope` label.
- **Carried forward.** The first slice to introduce a group-scoped value — only by § 2's way back
  in — owes the divergence report, computed by a declared join from its labelled slot to the
  `Field Scope` label with `REDUNDANT-OVERRIDE`'s trim-only, byte-exact equality — never a semantic
  classifier. The report names traveller, field and source, never either value
  (`reference/data-model.md` § *The report*), and never says *supersession*.
- **Not claimed:** that a milestone-41 law exists. Whether this rule is admitted to such a law,
  once one is stated, is not decided here.
- **Scope: narrow.** How a trip's own party-level blocks meet each traveller's values at synthesis
  is outside this rule (§ *What this record does not decide*).

**Reversibility: CHEAP · confidence HIGH.**

### 6. Erasure reach

**Locations created → reach rows.**

| # | Location created | Reach row(s), existing | What erasure does |
|---|---|---|---|
| L1 | `Dislikes` on `people/<person>.md` (C22) | **29** · **26** · **27** | Record deleted; loser stub deleted; survivor stub redacted |
| L2 | A hand-written override on `travelers/<traveler>.md` (C3) | **8** | Rewritten to the token stem; every answered personal value becomes `—` |
| L3 | The composed value in `outputs/traveler-model.md` (C12) | **10** | Heading tombstoned. `ACTIVE`: regenerated from the rewritten file. `ARCHIVED`: stays under `## per-<token> [ERASED]`, as every composed `DEFAULT` value does |

A `Dislikes` update-signal line is a new instance in C12's existing `## Update signals` block, not
a new location. That no row substitutes C12 free text beyond the entry heading is pre-existing, and
is listed under § *What this record does not decide*.

**Locations read → reach rows.** The group record's `## Members` section and the person store are
read as well as the trips; each is mapped, and so is the one part of the group record that is
deliberately **not** read.

| Read | Used for | Reach row(s) | After `erase p` |
|---|---|---|---|
| Every trip's traveller frontmatter `person:` | `history`, `k(t)` | **8**, **9** | Bearer → `per-<token>`, `person:` removed; `p` is in no closure |
| `people/` listing and closure frontmatter | `closure(p)` | **26**–**29** | Record deleted; stubs deleted, redacted or repointed |
| `groups/<G>.md` `## Members` | `members(G)`, `n`, qualifying groups | **30** | `p`'s bullet, and any stub bullet redirecting to it, removed |
| `groups/<G>.md` H1, the display name | — | **not read** | The qualifying listing prints id and member count only (§ 2), so no read reaches the name |
| C14 desire coverage — the traveller, tier and verdict cells | outcomes | **11** | Name substituted; no edge leads to the row |
| `## Group` roster, **row count only** | `r(t)` | **1**–**5** | The row survives with the token (row 1), so `r(t)` keeps counting it; `Total travelers` is unchanged too (row 5) |
| `## Group` roster, **column 1 tested for the token's shape** | the relation's erasure reading (W1a-0) | **1** | The token that row writes is what the test detects; nothing read is printed |
| `E2`'s `**Lifecycle:**` value | `lifecycle(t)` | — | Not person data |
| The order of C14 and its named source files in `t/outputs/` | `plan-to-coverage` | — | Paths and order only; erasure's own writes reorder them, which the relation reports as an order set by an erasure (W1a-0) |
| The session transcript | the render | **24** (REPORT) | Never echoes a subject value (§ 4) |

**Reach rows added or changed: none.** `ER14`'s accounting is unchanged at
21 + 5 + 4 = 30 rows (REACH, REPORT and OUT). **Nothing is unmapped in either direction.**

**The reads are erasure-complete, structurally.** After `erase p`, `history(p)` is empty (rows
8–9), `p ∉ members(G)` (row 30), and `p`'s C14 rows carry the token with no edge to them (row 11),
so no read reconstructs `p`'s outcomes or identity. **Residuals:** an unlinked trip is invisible to
these reads and to erasure alike (`ADR-017` § 6); a hand-deleted trip takes its outcomes with it;
and the transcript is REPORT-typed.

**Reversibility: MODERATE · confidence HIGH.**

### 7. Conformance to ADR-025 and ADR-026

| Accepted decision | How this design conforms |
|---|---|
| `ADR-025` § 3, the carry rule | No class carries across `EB-2`. C14 stays in its archived trip, the offer writes nothing into `t₀`, and what lands is a traveller's own answer |
| `ADR-025`'s never-carries 1–5 | (1) a read is not a carry; (2) `internal-hard` is unwidened and nothing is rendered — C14 reaches only the transcript, as tallies; (3) `both-marks` is unreachable; (4) no `DEST` value is read or printed; (5) no axis value is read or stored |
| `ADR-025` § 4, the join keys | `EB-2` on the person key and `EB-0` inside a trip; a group id is a view argument, never crossing a boundary or landing in a trip; no key at the render |
| `ADR-025` § 1, the axis | No edge is added and no value moves. § 5's named extension concerns operands outside the axis |
| `ADR-025` § 6, staleness | `plan-to-coverage` reuses the shipped triple and its rules, has no disposition column, is consumer-declared, and is evaluated **outside `trip.freshness`**, as that clause prescribes for a relation outside the boundary |
| `ADR-026` §§ 1–2, the channel-set | No channel is added. The group view is on CH-3; the person view is on CH-2, for the viewer only, and on CH-3 |
| `ADR-026` § 3, may-carry | CH-2 and CH-3 have no queried pair (`UNDETERMINED`), so their bounds come from the W-rule and `ADR-007` § 2. Nothing approaches CH-1. The group view's transcript sits on CH-3's `observers` value, `third-party` — the residual § 2 names |
| `ADR-026` § 5, the W- and R-rules | W: no traveller statement is authored, and CH-2's W-test holds — no candidate value. R: needs compliance is never read and no other traveller's row reaches CH-2, so what is *"audible to a room"* is the viewer's own tallies |
| `ADR-026`'s `ARCHIVED` overlay | Erasure is the one operation CH-3 performs *on* an archived trip; this capability performs none — it reads, as `history` does |

**No divergence is intended, so no superseding decision is raised.**

### 8. The group-slot instrument — none

**I-C is decided: there is no slot, so there is no instrument.** `ADR-016` is untouched, and this
record reverses, narrows and re-opens none of its decisions.

- **I-A — a section-scoped supersession of `ADR-016` — is the way back in**, priced in § 2: § 3
  reversed, § 2's writer decision re-grounded, §§ 5 and 6 extended, and a Convention sentence added
  to `reference/adr/README.md` so that a supersession may be section-scoped at all. A later record
  that wants a group preference slot takes this instrument and pays that price.
- **I-D — an in-place amendment of `ADR-016` — is unavailable.** `reference/adr/README.md`
  § *Convention* lets an amendment correct a claim, narrow a scope statement or repair a citation,
  and says in terms that *"What an amendment may never do is reverse, narrow or re-open a
  decision"*. Admitting a slot reverses § 3's decision, so it is the supersession path or nothing.

## Consequences

**Positive**

- **One retention mechanism — read where it was measured — so nothing migrates and a revert leaves
  no residue.**
- **No Accepted record is reversed.** `ADR-016`'s references-only property, its byte-identical
  expansion and its row-30 guarantee all hold, as does `ADR-017`'s *nothing persisted*.
- **Every read is erasure-complete by structure** (§ 6), and every location created maps to an
  existing reach row.
- **A party's joint trips become visible without anything recording that they were joint.**
- **A dislike of a kind of outing gets a home distinct from the destination veto.**
- **A retained verdict carries its freshness from the first slice that renders one**, so the
  snapshot-read-as-outcome failure is detectable wherever it could first occur.
- **`ADR-017` § 9's open item is decided for the group view, with its cost named** rather than
  left to the first slice that runs it.

**Trade-offs, stated**

- A hand-deleted trip takes its memory with it.
- Joint trips are re-confirmed on every invocation.
- The party-owned half is declined, and taking it back costs a supersession (§ 8's I-A).
- A joint trip on which fewer than two person-linked members travelled is never offered.
- Renders are tallies, never text.
- The group view reads each candidate's roster, which is wider than `history`'s ceiling.
- An unmarked dislike composes as answered indefinitely.
- A composed `Dislikes` change is reported under no router class until the pending router decision
  lands, as its siblings are.
- The group view multiplies the transcript, one line per member per confirmed trip, on an
  `observers` axis that admits a third party.
- The relation's verdict is an order among named files and nothing more, and it carries stated
  readings for an erasure, an uninterpretable pass and a tie (W1a-0).

**Risks**

| ID | Risk | Mitigation | Residual |
|---|---|---|---|
| R-A | A Wave-3 author copies `history`'s enum offer | § 4 states the difference in terms | LOW |
| R-B | A later slice caches `outcomes`, `cand` or a confirmation | *Nothing stored* is part of each definition, and `ADR-012` O10 is cited | LOW |
| R-C | A Wave-1b prompt treats `Dislikes` as a veto or a gate | W1b-5, and the validator's *"Gate on Desires only"* | LOW |
| R-D | A positional C14 read misreads the tracked witness | W1a-2, exercised by W1a-3 | LOW |
| R-E | A sibling work item moves a premise — the encrypted-limb publishability decision, the person-form contract slice, or the ownership decision for the `[DERIVED]` blocks | Nothing here reaches CH-1; W1b-6 orders this slice against the person-form contract; no new `[DERIVED]` dependence is taken | LOW |
| R-F | A count in this record or its changelog entry turns the corpus-hygiene gate red | Every count here is anchored to a commit or written out as arithmetic, and the suite runs before the branch is pushed | LOW |

**Reversibility summary.** § 1 CHEAP / HIGH · § 2 CHEAP / HIGH · § 3 CHEAP / HIGH, becoming
EXPENSIVE once operator records carry the label, because the store is git-ignored · § 4 CHEAP /
HIGH · § 5 CHEAP / HIGH · § 6 MODERATE / HIGH.

## What this record does not decide

- The verb tokens and the exact `**Reads:**` lines of the slices.
- Which command hosts the first rendering surface, and so where W1a-0's relation and grant land.
- How a trip's own party-level blocks meet each traveller's values at synthesis.
- Where a composed change to an unmapped `DEFAULT` facet routes — `Dislikes` among them.
- Admission of § 5's rule to any milestone-41 law.
- The bracket's final wording, which Wave 1b owns.
- The shipped erasure gaps this design observed and does not repair: `trip-context.md` sections no
  reach row names, names outside the entry heading in `outputs/traveler-model.md`, and the group
  display name `group-list` already prints.
- The C14 witness's desire-coverage layout, which differs from the layout its writer declares.
- The apparent tension between `ADR-017` § 4's enum offer and CH-2's W-test, which is recorded as
  observed and not verified as a defect.

Each of these has a home outside this record, listed under *References*.

## Follow-on build slices

The constraints below are defined once, here, and every section above cites them by identifier.
Wave 1a is the first wave that renders a retained verdict, so the freshness relation arrives with
it rather than with the offer.

*Wave 1a — outcome retention (the read).*

- **W1a-0 — the freshness relation, with the first wave that renders.** Wave 1a's host declares
  the `plan-to-coverage` relation, with the order observation named in its declared reads. If that
  host is `/trip-record`, the amendment to its grant sentence — *"`Bash(ls:*)` for the listing
  block and `Bash(grep:*)` for the record block, and nothing else in this file uses either"* —
  lands in the same slice. `/trip` already declares a newest-first listing, `Bash(ls:*)` with
  `-1t`, for its freshness report.
  - **The relation.** For a reached archived trip `t`, the derived side is
    `t/outputs/satisfaction-metrics.md`. The source side is pinned to the sentence in
    `reference/data-model.md` § *Three metric types* that names what coverage is *"determinable
    from"*: read at `b199dc1`, the itinerary, the traveller model and the per-event status —
    `t/outputs/final-itinerary.md`, `t/outputs/traveler-model.md` and `t/outputs/event-status.md`.
  - **The verdicts.** The shipped triple, verbatim: `CURRENT`; `BEHIND`, naming the leading
    source; `UNDETERMINED`, naming the unobservable operand. Comparison is by exact token, and
    order is observed as the shipped relations observe it. Every reached trip's verdict is
    rendered, `CURRENT` included. It is evaluated **outside `trip.freshness`**, because `t` is not
    the resolved trip, and the report says so. It is report-only.
  - **What the verdict means, and nothing more.** `CURRENT` and `BEHIND` are an order among the
    named files. Neither says a plan or a status changed after the last synthesis, and neither says
    one did not.
  - **Readings the render states rather than infers.** *Order set by an erasure* — where `t`'s
    `## Group` roster carries an erasure tombstone, column 1 matching `per-[0-9a-f]{4}`, the
    verdict reads as an order erasure's own writes set, never as a plan change. *An order the
    relation cannot interpret* — where `t`'s last pass ran no validator after its hub, as an
    IDEATION pass or a remediation leg does, the order that pass left is one the relation cannot
    interpret, and the render says so. *A tie* — on a coarse filesystem, two operands may order
    either way.
  - **The bound that remains.** The observation is of files. Every shipped verb that writes C14
    runs the hub before the validator (*"the validator reads the itinerary the hub produced"*,
    `skills/trip/SKILL.md` §§ `plan` and `replan`), and `/trip check` writes neither file, so
    outside the readings above the file tracks the last synthesis pass. A hand edit to C14 reads
    `CURRENT`. None of this can make a render say more than plan coverage as last synthesized.
- **W1a-1.** A read-only surface computes `outcomes(p, t₀)` exactly as § 1 defines it. It declares
  its own `**Reads:**` — every trip's traveller frontmatter to the closing `---`; the person store
  listing and closure frontmatter; each reached trip's C14 desire-coverage section; and the
  relation's order observation and roster tombstone test (W1a-0) — writes nothing, dispatches no
  agent, and performs no external act.
- **W1a-2.** Find the section by the heading's leading segment `Desire-coverage`, and the three
  cells by header label, accepting both shipped spellings: `Traveler` / `Traveller`,
  `Priority tier` / `Tier`, `Covered?` / `Covered`. Strip emphasis from the verdict. A header naming
  none of a needed cell reads `UNDETERMINED` for that trip. **Never read by column position, and
  never read the `Desire` cell into output.**
- **W1a-3.** A tracked archived-trip fixture with a person-linked traveller, an unlinked one and a
  frozen C14, exercising a reached row, *holds no outcome record* and `NO-REFERENCE` — the fixture
  gap this milestone's plan measured.
- **W1a-4.** Exactly one bearer per trip, or that trip reads `UNDETERMINED` — determinism, and
  single-valued arguments.
- **W1a-5.** Each view prints `ADR-017` § 5's tokens only under the conditions § 1 and § 2 write
  beside them, and no absence reads as `not covered`.

*Wave 1b — `Dislikes`.*

- **W1b-1.** The classification row with § 3's cells lands in one commit with every restatement it
  moves, each cited by file and quotation and re-read at the slice's own baseline. In
  `reference/data-model.md`: the denominator reconciliation in § *The denominator*, the totals line
  under the classification table, the `DEFAULT` count in § *Composition and resolution*, the rows
  below `Cuisine appetite` (renumbered by one), the interests-&-tastes facet line
  (*"`Interests` and `Cuisine appetite` are durable"*), and the *"sevenfold"* multiplier, restated
  as a rule rather than as a new multiplier. In `templates/person-intake.template.md`:
  *"Skip either line"*, the section preamble, the `Fields:` line and the Step-7 ask.
- **W1b-2.** The form bullet, the preamble and the Step-7 ask. **The bullet lands in the same
  commit as its row**, because the schema suite resolves fixture bullets against the live table.
- **W1b-3.** `Dislikes:` joins the interests-&-tastes enumeration in `agents/00-enrichment.md` and
  the facet table in `reference/data-model.md`. Without it the field never reaches C12.
- **W1b-4.** A composed `Dislikes` change is reported under no router class — exactly as `Interests`
  and `Cuisine appetite` are — until the pending router decision assigns a class to every unmapped
  `DEFAULT` facet at once. No fifth class is added, and the report names the field and never its
  value.
- **W1b-5.** `agents/01-activities.md` and `agents/07-nightlife.md` read it as a per-traveller soft
  signal in candidate selection, and `agents/05-hub-planner.md` respects it at placement. It is
  never a veto for the party, never a validator gate, and never scored. A traveller's own `Desire`
  governs where both name the same thing.
- **W1b-6.** The `open` marker is written once the person form carries the `ADR-023` D2.4 markers:
  whichever of this slice and the person-form contract slice lands second writes it. The `Fields:`
  line is updated only if it still exists.
- **W1b-7.** Recommended rather than required: the person-record witness gains a `Dislikes` bullet,
  so a tracked instance exercises the label.
- **W1b-8.** No `HZ2` change. `HZ1` needs the new cell to read `admissible`.
- **W1b-9.** Every numeral Wave 1b restates keeps its basis — arithmetic written out, as
  § *The denominator* already does — or its `count-assertion-digest` row moves in the same commit.

*Wave 2 — the group view.*

- **W2-1.** `cand(G, t₀)` plus operator confirmation — never containment. It is recomputed and
  shown on every invocation.
- **W2-2.** No `trip-context.md` block is read except the `## Group` roster table, and from it only
  the row count and the relation's tombstone test (W1a-0), which prints nothing it reads. `r(t)` is
  rendered per candidate.
- **W2-3.** `members(G)` and `n` per § 2, with `UNDETERMINED` per unresolved bullet and the `G1`
  canary inherited.
- **W2-4.** A named `<group-id>` runs. With none, every qualifying group is listed by id and member
  count only, and none is chosen.
- **W2-5.** No total across members or trips. No stored confirmation. No group id in any trip
  artifact. `ADR-016`, `reference/schemas/group-record.md`, `groups/README.md` and `GM1`–`GM3` are
  untouched.
- **W2-6.** Its own `**Reads:**` declares the group record's `## Members`, the person store, every
  trip's traveller frontmatter, each candidate trip's roster table, each reached trip's C14
  desire-coverage section and the relation's order observation (W1a-0) — body reads `history`
  never makes, which is why the view cannot live inside `history`.

*Wave 3 — the offer.*

- **W3-1.** The audience per half is § 4's table: the group view only where the operator is the
  audience, never into an interview or any surface whose far side is a traveller, and never on
  CH-1.
- **W3-2.** § 1's wording rule, on every render.
- **W3-3 and W3-6 are carried in W1a-0.** The relation and its host's grant arrive with the first
  wave that renders, not with the offer.
- **W3-4.** Offer-only (§ 4): name a field, the evidence and the remedy. Never quote a prior desire
  or a `Dislikes` value, and never offer an enum value.
- **W3-5.** § 4's transcript bound.
- **W3-7.** No divergence line (§ 5).
- **W3-8.** The offer is never placed inside `## profile`, `## history` or enrichment.

## References

- [`README.md`](README.md) — the ADR convention: the status lifecycle, and the amendment clause
  that makes an in-place amendment of `ADR-016` unavailable (§ 8).
- [ADR-007](ADR-007-command-entry-point.md) — § 2's bounds, which bound CH-3 where may-carry reads
  `UNDETERMINED` (§ 7).
- [ADR-010](ADR-010-per-traveler-approval-collection.md) — one of the homes of the `internal-hard`
  membership a new class under *Carry* would move.
- [ADR-012](ADR-012-people-library.md) — the person identity and merge semantics behind
  `closure(p)`, and O10's staleness ground, which refuses a cache and prices *Carry*'s second home.
- [ADR-013](ADR-013-count-assertion-basis.md) — the basis forms every count in this record is
  authored to.
- [ADR-014](ADR-014-cross-trip-consent-refusal.md) — the consent refusal the measured reads
  preserve by construction.
- [ADR-015](ADR-015-durable-field-validity-horizon.md) — clauses 4 and 6–8: the `Horizon` axis,
  no mechanical write, the report-line bound, and the present-mark rule the field inherits.
- [ADR-016](ADR-016-reusable-groups.md) — the group record. §§ 3–4 are the decisions § 2 declines to
  reverse, O8 is the renumber precedent *Carry* would take, and the record is untouched.
- [ADR-017](ADR-017-derived-trip-history.md) — `history(p)`, the reused scan, the operator-made
  match (O7), the terminal tokens (§ 5), the shared blind spot (§ 6), and § 9's open item, which
  § 2 decides for the group view.
- [ADR-023](ADR-023-interviewer-authored-home-and-form-contract.md) — D2.3, D2.4 and D2.6: the
  bracket as the authoritative home, the `open` / `closed` marker, and the `(section, label)` key.
- [ADR-024](ADR-024-form-contract-writer-boundary.md) — § 1's key of region and condition, in which
  the field's form-contract row is written.
- [ADR-025](ADR-025-engagement-model-over-time.md) — the engagement axis and the
  composition-precedence edge (§ 1), the carry rule and never-carries (§ 3), the join keys (§ 4)
  and the staleness family (§ 6) this record conforms to.
- [ADR-026](ADR-026-channel-architecture.md) — the channel-set, the `audience` and `observers`
  axes, the W- and R-rules and the `ARCHIVED` overlay this record conforms to; CH-3's `observers`
  value is the residual § 2 names.
- `reference/data-model.md` — § *Field Scope* (the classification, the decision rule, the starred
  pass), § *Composition* (the lattice, `ANSWERED()`, the report), § *The reference month*,
  § *Satisfaction Metrics* and § *Traveler identity*.
- `reference/data-architecture.md` — § 1.1's class enumeration, the `internal-hard` limb, §§ 7.2
  and 7.5's tolerant read, and the `count-assertion-digest` fence this record adds no row to.
- `reference/schemas/person-record.md` and `reference/schemas/group-record.md` — the two writer
  classes, and what each admits.
- `groups/README.md` — the references-only store § 2 leaves as it is.
- `skills/trip-record/SKILL.md` — § `erase` and its reach table, § `travelers` and the router's
  classes, § `history`, § `group-list`, § `group`, and the grant sentence W1a-0 may amend.
- `skills/trip/SKILL.md` — § *The freshness report*, and §§ `plan`, `replan` and `check`.
- `skills/trip-decommission/SKILL.md` — the standing rules and `archive`, unchanged.
- `agents/00-enrichment.md` — the composition-precedence clause, the trigger set, the report
  routing and the facet enumeration.
- `agents/06-validator.md` and `agents/destination-ideation.md` — the soft-signal reading of
  `Interests` and the veto reading of `Rather skip`, which together delineate the field.
- `templates/person-intake.template.md` — the form the field lands on.
- `scripts/test-artifact-schema.sh` — `HZ0`–`HZ2`, `ER14` and `GM1`–`GM3`.
- `CLAUDE.md` — § *Archived trips — what the freeze binds*, § *Resolving a trip* (`G1`, `G4`,
  `G8`) and § *Key Rules*.
- `examples/tokyo-2026/trip-context.md` and
  `examples/data-architecture-demo/outputs/satisfaction-metrics.md` — the party-level blocks read
  for § 2's first ground, and the C14 witness whose header W1a-2 accepts.
- **Work items.** #1200, the driving card, whose acceptance criteria this record answers. #1197,
  the epic this record gates, which stays open. Filed for what this record does not decide: #1457,
  erasure's reach missing names outside its listed places, group display names among them; #1458,
  the router's totality over unmapped `DEFAULT` facets, which decides where a composed `Dislikes`
  change routes; #1459, a trip's party-level preferences at synthesis; #1460, the C14 witness's
  layout; and #1353, CH-2's tests, where the tension with `ADR-017` § 4's enum offer is noted.
