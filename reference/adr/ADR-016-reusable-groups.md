# ADR-016: Reusable groups — a second cross-trip store, a one-directional membership edge, and an expansion that leaves no residue

- **Status:** Accepted (2026-09-08)
- **Deciders:** repo maintainer
- **Driving work:** the Groups and trip history milestone. This record is that milestone's
  **head decision gate**, in the shape `reference/adr/ADR-003-group-coordination.md` and
  `reference/adr/ADR-012-people-library.md` already ship: it lands before either feature slice and
  settles the cross-cutting questions both of them would otherwise answer separately.
- **Sibling record.** This milestone carries **two** records rather than one.
  `ADR-017-derived-trip-history.md` covers derived trip history and is authored by the other slice;
  the coupling between the two is recorded there. **This record decides nothing about how trip
  history is derived**, and § 7 below says so in terms. The split was taken deliberately over a
  single joint record, and its stated cost is that a reader wanting the milestone's whole design
  reads two files instead of one.

## Context

### What shipped, and what it does not remove

The person library removed per-person re-entry: a durable record per person, held across trips
rather than copied into each one, referenced from a trip by a single `person:` field on that trip's
traveller file. `reference/adr/ADR-012-people-library.md` is authoritative for it.

It does not remove per-**group** re-entry. The same four people travelling together for the third
time are still assembled one at a time — four `link` invocations, or four `profile` interviews, on
every trip. For a recurring party that assembly is the larger share of the remaining setup cost, and
nothing in the shipped design shortens it.

### The three constraints the corpus already imposes on any answer

None of these was chosen by this record. Each was read out of shipped text, and together they
determine most of the design below.

**A person record has no slot for group composition, and that is structural.**
`people/README.md` § *What a record does not hold* and `reference/schemas/person-record.md` both
declare that *group or party composition* — who is travelling together, who is rooming with whom —
has no slot in the durable form at all. The schema states the idiom in its own words: *"no rule
enforces it because none is needed… What is owed is the negative assertion, not a rule."* Any design
that reached its answer by adding a field to the person record would have to reopen that
enumeration.

**The person key is not a trip-internal join basis.** `ADR-012` § 3 places `person:` on
`travelers/<traveler>.md` **and on no other class**, and says why: a cross-trip identifier inside a
trip artifact widens the reach set every erasure has to walk. The reach set is fixed at exactly one
trip-side location on purpose.

**`group` is already a verb, and it means something else.** `/trip-record group [<name>]` ships and
manages **this trip's roster** — the `## Group` block of `trip-context.md`, `publish: bound`.
`ADR-003` uses "group" in the same trip-scoped sense throughout. Whatever this record decides, it
inherits a live token collision with the word the card uses.

## Decision drivers

1. **The six acceptance criteria of the card should be satisfied structurally, not by a guard.** The
   person library's own idiom: where a fact has nowhere to live, no rule has to keep it out.
2. **No second convention for a thing the repo already does once.** A cross-trip store, a surrogate
   key, a rooted-ignore signpost pair, a resolution posture for a dangling reference — each of these
   already ships, and reaching a different answer for a new entity would leave the corpus holding
   two.
3. **Erasure's reach must stay computable.** Anything this record adds that can hold a person id is
   a location `/trip-record erase` has to reach, and the reach table is the population its receipt is
   total over.
4. **The membership relation must not become a second home for a person-scoped fact.** AC6 is the
   criterion most easily satisfied on paper and most easily lost in implementation — a display name
   beside an id is the whole failure.
5. **A group is a convenience. It must not become a dependency.** A trip that expanded a group must
   keep working, unchanged, if the group is later edited or deleted.

## Options considered

### Where the store lives

| | **O1 — `groups/` at the repo root** | **O2 — `people/groups/`** | **O3 — inside each trip** |
|---|---|---|---|
| Signpost survivable | yes — a rooted `/groups/*` + `!/groups/README.md` pair | **no** | n/a |
| Cross-trip by construction | yes | yes | **no — defeats the capability** |
| New convention introduced | none — the fourth instance of a shipped pattern | none | a per-trip copy of a cross-trip set |

**O2 is refused on a mechanical ground, not a taste one.** `.gitignore`'s own comment states it:
*"git cannot re-include a file whose parent dir is excluded."* `/people/*` excludes the directory
`people/groups`, so `!/people/groups/README.md` cannot re-include the signpost, and recovering it
needs an un-exclude/re-exclude dance inside a block whose own comment forbids simplifying it.
It would also falsify `people/README.md`'s own sentence *"Everything in here is git-ignored
except this file."*

**O3 is refused because it answers a different question.** A per-trip group is the roster, and the
roster already ships as the incumbent `group` verb.

### Which direction the membership edge runs

| | **O4 — group → person, no back-reference** | **O5 — both directions** |
|---|---|---|
| `people/README.md` no-slot list | **untouched** | **reopened** — a back-reference is *group or party composition*, bullet 1 |
| Survives erasure of the group | n/a — nothing on the person side to strand | **yes, and that is the defect** — the identical ground `ADR-012` § 5 gives for refusing a back-reference list on the person side |
| A person in several groups (AC4) | free — N groups carry the id, the person record records no multiplicity | needs a list field on the person record |

**O5 is refused.** It is the option that would force a reopening of the very enumeration this record
is trying to leave intact, and it buys a query — *which groups is this person in?* — that a scan of
a store of tens of files answers without a stored edge.

### What an expansion leaves behind in the trip

| | **O6 — nothing names the group** | **O7 — the trip records the group id** |
|---|---|---|
| AC3 — membership editable without disturbing an expanded trip | **satisfied by construction** — there is nothing in the trip pointing at the group | needs a rule saying the binding is not followed |
| `ADR-012` § 3's one-location reach set | preserved | **widened** — a second cross-trip identifier lands in a trip artifact |
| *"re-sync this trip with the group's current membership"* | unavailable | available |

**O7 is refused, and the thing it offers is the thing AC3 forbids.** A live binding from a trip to a
group is precisely what acceptance criterion 3 rules out; its absence is the criterion, not a gap in
the design. The cost is stated rather than minimised in *Consequences*.

### The class ordinal

| | **O8 — C23, renumbering out-of-model to C24–C29** | **O9 — C29, appending past the closed set** |
|---|---|---|
| Extra citation edits | **four** — `reference/data-architecture.md` § 1.2's out-of-model rows and two `C23–C28` sentences, plus two ordinal citations in `reference/schemas/README.md` | none |
| Structural cost | none — the in-model / out-of-model partition stays a contiguous range | **permanent** — § 4.4's heading becomes `C1–C22, C29`, and every future in-model class widens the scar |

**O8 is taken.** Four mechanical bumps buy a partition that stays readable as a range.
`reference/adr/ADR-011-per-traveler-cost-estimation.md` records a prior renumber of this same
enumeration and is **preserved rather than edited** — it is a record of a past act, not a claim about
the present numbering.

### Whether the incumbent `group` verb is renamed

**It is not.** § *Selecting the verb* in `.claude/commands/trip-record.md` is frozen and specifies
**exact string equality** — *"Not a prefix match, not a nearest match, not a fuzzy match, not a
substring match."* Under that selector `group` and `group-new` are disjoint tokens with no collision
risk, so a rename would be a four-surface cascade performed to make room for a newcomer that does not
need it.

## Decision

**Accepted 2026-09-08 (Tuesday).** Group is admitted as a **twelfth entity** with its own cross-trip
store, a one-directional membership edge, and an expansion that writes no residue into the trip.

**Every artifact class in this section is named by path, never by its ordinal in
`reference/data-architecture.md` § 1.1.** That enumeration is closed and its numbering moves; a path
does not. This is `ADR-012`'s rule, taken unchanged.

### 1. Identity — a surrogate key, filename-borne

**Group takes the surrogate `grp-[0-9a-f]{4}`, borne in the filename at `groups/grp-<token>.md` and
never restated in frontmatter** (§ 4.3's no-double-home rule). **The display name is the body H1 and
nothing else** — the same structural position the person identity rule keys on.

**The surrogate branch is taken by § 3's rule, not by analogy to Person.** The engine creates the
group record — it does not exist until the store is asked for one — so limb 1 holds for the
engine-created branch; and every natural candidate is a mutable display string that is not already
the token the operator types. A group name is *more* volatile than a person's, so the property
`ADR-012` § 1 names — *a rename touches a display-name body value only, and mutating a join key in
place is structurally unreachable* — is worth more here than there.

**Minting asserts non-existence and re-mints on collision**, as the person store's does.

**`grp-` is a disjoint namespace**, and any detector over it is **shape-anchored**
`grp-[0-9a-f]{4}` — the requirement `ADR-012` § 1 states, and one this prefix satisfies cheaply:
unlike `per-`, `grp` matches no English word.

**Creation refuses on exact equality of the normalized H1 against a live record**, reusing § 3.2's
existing normalization — **never a second implementation**, which `ADR-012` § 1 names as *"a second
source of truth for identity."* Three remedies, `ADR-012`'s own: link to the existing group,
disambiguate the name, or create anyway with the collision acknowledged.

**Group merge and group split are OUT OF SCOPE, explicitly.** Silence here would read as coverage.
Same-named groups co-exist safely because their ids differ, and the operator's remedy is
`group-drop` / `group-add`, which is cheap and reversible. A merge would need survivorship rules for
a set union that has no field conflicts to resolve — a mechanism with nothing to decide. **There is
no `merged-into:` field on this class**, and consequently no stub, no chain and no depth rule.

**Reversibility: MODERATE · confidence HIGH.** Ids are minted, not derived; changing the scheme
re-keys the store.

### 2. Storage home — `groups/` at the repo root, in-model, reusing the `cross-trip` sentinel

**The store is `groups/`**, at the repo root, **contents git-ignored with a tracked
`groups/README.md` signpost**, rooted in `.gitignore` as `/groups/*` plus `!/groups/README.md`. This
is the **fourth instance of a pattern this repo already ships three times** — `trips/*`,
`/analysis/*`, `/people/*`. Feasibility is demonstrated, not argued. `O2` and `O3` are refused above.

**The leading `/` is load-bearing**, for the reason `reference/schemas/person-record.md` already
states for `people/`: the rule must catch the store at the repo root and **not** the tracked witness
under `examples/`, which this class's own `path-pattern` names. A widened rule would silently drop
that witness from the index — *a coverage claim the gate is structurally unable to contradict*.

**The group record is an in-model artifact class**, named `groups/<group>.md`, taking the ordinal
**C23** per `O8`. Its schema file is `reference/schemas/group-record.md`. In-model is taken for
`ADR-012` § 2's reason: an `internal-hard` store holding cross-trip join keys cannot take a weaker
machine-grading posture than the store it references.

**`trip: cross-trip` is the EXISTING sentinel, reused rather than extended.** `ADR-012` § 2 declared
it and `reference/data-architecture.md` § 4.4 carries it; this class becomes its second member. **The
sentinel's value is unchanged, so `/trip-new`'s refusal of a trip slug equal to a reserved sentinel
covers this class with no edit** — this record adds no forward obligation to that command. That is
the single largest reuse in this design, and it is asserted by the guard suite rather than assumed.

**`writer: operator`, not `human`.** `human` is reserved for a class whose *subject* authors it —
`travelers/<traveler>.md` and `people/<person>.md`. An operator selecting references through a
command is `operator`, which is `trip-log.md`'s shipped slug, and § 1.1's `W` cell takes that class's
shape: prose naming the verb.

**`publish: internal-hard` — the class is the fourth member**, beside C12, C14 and C22.
Anonymization does not help, and the incumbent `group` verb's own text already says why: *in a small
named party, stripping the name does not strip the identification.* Rendering a group in any form
publishes that these N people travel together.

**Reversibility: MODERATE · confidence HIGH — and EXPENSIVE once operator records materialise.**
Reversible on paper until real group records exist in operators' working directories; a relocation is
a migration thereafter, exactly as `ADR-012` § 2 records for `people/`. **Settle the store path
here, before the first `group-new` ships.**

### 3. Membership — a bare person id, group → person, and no back-reference

**A membership entry is a bare person id and nothing else.** The body admits `# <H1>` and
`## Members`, and every member bullet matches `^- psn-[0-9a-f]{4}$` — no trailing text, no display
name, no role, no note. **That one anchored regex is the whole of AC6's enforcement**, and it is
closed-by-construction in exactly the sense `people/README.md` uses: there is no slot.

**The display name is deliberately absent from the entry.** A name beside an id would be a second
home for the person record's H1 (§ 4.3) and would drift the moment the person is renamed — the
shadow-SSOT cost `ADR-012`'s first amendment already paid once. **Names are resolved at render time
from each record's own H1.**

**The relation is one-directional, and the direction is forced rather than chosen.** `O5` above is
refused: a back-reference on the person record is *group or party composition*, bullet 1 of the
no-slot list, and it survives deletion of the group. **AC4 is therefore free** — N groups may each
carry the same id, and nothing on the person side records the multiplicity.

**Resolution inherits `ADR-012` § 3's branches verbatim; no new posture is invented.** A member id
resolving through a `merged-into:` stub is followed to **depth 1**; a second hop is `MALFORMED`. A
member id that does not resolve is `DANGLING` and renders **`UNDETERMINED`** — never *no such person*
and never silently dropped. **A person merge writes nothing under `groups/`**: resolution is lazy
through the stub, which is the shipped posture.

**There is no free-text section, and that is AC1's enforcement rather than minimalism.** A record
that says *why* a group exists becomes personal data about its members the instant it says anything
about them. **The accepted cost, stated rather than hidden: there is no cross-trip narrative home for
a note about a group.** The name carries that meaning (`# Tahoe regulars — 2024 crew`), and
`trip-log.md`, the narrative register, is trip-scoped and cannot hold it.

**Reversibility: CHEAP · confidence HIGH.**

### 4. Expansion — point-in-time, and it writes no residue

**What is copied: the member's display name, and nothing else.** It lands where the shipped path already puts
it and nowhere else — the `## Group` roster row in `trip-context.md`, and the
`travelers/<file>.md` stem via `/trip-new`'s transform. **Expansion introduces no newly-copied
value; it is N invocations of a shipped path.**

**That equivalence is load-bearing rather than descriptive, and it settles one question the command
file would otherwise leave to the reader.** `group` reconciles `- **Total travelers:**` on every
invocation that changes the roster, so N of them reconcile it N times; an expansion that left the
field alone would therefore not be N invocations of anything, and would end a successful run with a
populated roster beside the bracketed total that `/trip-new` records three downstream contracts as
being broken by. **Expansion reconciles that field once, after the last member, by `group`'s own
table** — a delegation, on a verb whose every other step is one.

**What is referenced: everything durable.** Passport, needs, preferences, travel style — all read
through `person:` at composition time. Composition reads the record and writes the trip, never the
reverse.

**What is recorded nowhere: the group id.** No trip artifact — not `trip-context.md`, not the
traveller file, not the derived model, not `trip-log.md` — receives a byte naming the group. **This
is the whole of AC3.** Membership is editable without disturbing an expanded trip because there is
nothing in the trip pointing at the group: not a weak binding, not a stale one, none.

**One property of that absence is load-bearing beyond this record, and it is stated here so a later
change does not cost it silently.** Because expansion writes the same `person:` edge that `link`
writes, **a group-expanded traveller file is byte-identical to a hand-linked one.** Any surface that
derives a person's history by inverting that edge therefore sees no difference between the two, and
needs no group-awareness at all. `ADR-017-derived-trip-history.md` is the record that depends on it.
**Nothing tests this property**, and *Consequences* carries it as a named residual rather than a
claim.

**A `NEW` member's file is created from `## profile <name>`'s route 2, and the delegation is decided
here rather than left to be inferred.** `NEW` means *no traveller file exists for that member*, and on
a freshly scaffolded trip — where `travelers/` ships empty — it is **every** member, so this is the
primary path of the whole capability rather than an edge. Two candidates were weighed. **Narrowing
`NEW` to refuse and route to `profile`, the way `link` does, was rejected**: it makes the verb refuse
on every member of exactly the trip it exists to set up, leaving *expands to its members*
unsatisfiable on the only branch a new trip reaches. **Declaring the source was taken instead** —
`Read` `templates/traveler-intake.template.md`, `Write` it to the path unmodified, which is the one
create path this class has. `link`'s refusal is honoured by that choice rather than overridden: its
stated ground is that a `link` minting a file *would author a second shape of this class that no
schema check has seen, and would duplicate a write that is already someone's*, and copying the
shipped template mints no shape and opens no second home. `profile`'s create-side **collision check**
comes with the route, because its predicate is the coarser canonical traveller key and a
file-existence probe alone cannot see the two-names-one-key case that check exists to stop; a member
reaching it renders `UNDETERMINED` and is excluded. **The residual cost, stated: `group-expand` now
cites two verbs' read sets rather than one**, and a change to `profile`'s create route reaches this
verb.

**Expansion runs `link`'s per-member consequence survey and does not suppress it.** Suppression would
regress a deliberate safety property. The presentation is bulk; the survey is not: run the shipped
survey once per member writing nothing, emit **one consolidated preview** — one line per member, a
verdict from the closed set `NEW` · `CLEAN` · `DIVERGES` — and take **one confirmation**. A
`DIVERGES` member is **named by field label only, never by value** (echoing a value into a transcript
is a new copy of personal data in a place erasure cannot reach) and is **excluded by default**, with
`/trip-record link <name> <person-id>` given as the per-member path where the field-by-field
side-by-side already lives. Per-member confirmation would put a gate on every member, on the
setup convenience this capability exists to remove.

**Partial failure is reported, never rolled back.** A rollback would itself be writes, and the state
is recoverable because `unlink` is the cheap inverse.

**Reversibility: CHEAP · confidence HIGH.**

### 5. Erasure reach — one new row, remove-the-bullet, no tombstone

**A group record holds person ids, so it is a location `/trip-record erase` must reach.** The reach
table in `.claude/commands/trip-record.md` gains one row for `groups/*.md`, disposition **REACH**:
remove the member bullet naming the subject id, **and** any bullet naming a `merged-into:` stub id
that redirects to it.

**No tombstone, and the reason is the mint's own.** A `per-<token>` written into a group record would
be a stable **cross-trip** pseudonym surviving in a **cross-trip** store — precisely the correlation
the per-(person × trip) mint exists to destroy. Removal is safe because a member set is
variable-length by construction and a smaller set is a valid one. **Where removal empties a group or
leaves a single member, the group is not deleted — it is reported.**

**The stub half needs no new machinery**: erase's discovery step already computes the stubs that
redirect to the record, and the group sweep consumes that set. **The verb's `Reads:` declaration
gains the store**, or the row names a location the verb never opens.

**`groups/README.md` is not a reach location**, on the same ground `people/README.md` is not: a
tracked signpost carrying no person data. Keeping it that way is a property of the store's build,
not something the erase verb checks.

**The accounting sentence is restated in the same commit as the row.** It is graded in both
directions, and on row-number contiguity.

**Reversibility: MODERATE · confidence HIGH.**

### 6. The command surface — six verbs under `/trip-record`, and a standing rule that admits them

**The verbs live under `/trip-record`, not a new command.** The person library — also a cross-trip
store — is managed entirely from there, and `erase` already sits at lifecycle `ANY` managing one. A
second command for the same shape would be a second convention.

| Verb | Arguments | Lifecycle | What it does |
|---|---|---|---|
| `group-new` | `<name>` | `ANY` | Mint `grp-<token>`; write the record with an empty `## Members`; refuse on normalized-H1 equality with three remedies |
| `group-list` | `[<group-id>]` | `ANY` | No argument → the store. An argument → that group's members, each id resolved to its H1; a dangling id renders `UNDETERMINED` |
| `group-add` | `<group-id> <person-id>` | `ANY` | Append a member bullet. Refuse a duplicate; refuse an id that does not resolve — **never mint a person record** |
| `group-drop` | `<group-id> <person-id>` | `ANY` | Remove the bullet, echoed verbatim first |
| `group-delete` | `<group-id>` | `ANY` | Delete the record and nothing else. Confirm by echoing the H1 and member count |
| `group-expand` | `<group-id>` | `ACTIVE` | § 4 above. The only one of the six that requires a trip |

**These verbs write outside `trips/<slug>/`, and the standing clause forbids that until a rule
admits it.** Standing rule 9 states it in terms: *until such a rule exists, no other write outside
`trips/<slug>/` is available to any verb of this command.* So this slice appends **standing rule 12**
under the clause's own Extension rule, deriving the group store's target class and operation class
the way rules 9, 10 and 11 derive theirs. It binds every verb, present and future — its prohibition
half is that **no verb may reach the group store except by satisfying it** — which is the test the
Extension rule sets for an append.

**`group-delete` does not take erase's typed-back confirmation, and that is a decision rather than a
shortcut.** Flattening the two would erode the distinction erase works to preserve. Group deletion
destroys a set of references the operator can rebuild; erasure destroys a person's durable record and
cannot be undone.

**That nonetheless falsifies three shipped sentences, and this slice repairs each in place** under
§ *The repair extension point*: erase's claim to be *the only irreversible operation on this command
surface*, stated twice in its own section; standing rule 10's *the one write that may delete a
record*; and standing rule 11's *no other verb of this command may create a file under the store*.
Each is **narrowed to the person store rather than softened** — erase remains the only operation on
this surface that destroys personal data irrecoverably, which is the property those sentences were
protecting.

**A further sentence is falsified, it sits in Zone A rather than in a verb section, and its
disposition is therefore a different one.** § *When no verb was typed* gives the ground for refusing
a bare invocation as *every verb of this command writes* — a universal over the verb set — and
`group-list` falsifies it by declaring in its own section that it writes nothing on either branch.
(`ADR-017-derived-trip-history.md`'s `history` verb falsifies the same sentence independently, which
is why it is recorded in this cross-cutting record rather than in either slice's.) The same sentence
also stood in § *The shape of a table row*, and **that site was already converted** when this
milestone's earlier work landed — so **the surviving site is the part that conversion did not reach**.
§ *The repair extension point* clause 3 governs and is explicit that finishing such a conversion is
*that same conversion reaching the part it missed, not a second one*, and is available. So the
survivor is **converted rather than repaired**: the universal comes out, and the rule that derives it
goes in — *which of this command's verbs write is read from each verb's own section and never
enumerated here*. The refusal is unchanged, and so is the clause beside it that no permitted edit
falsified.

**The conversion is also made executable, because prose is what failed here.** The sentence shipped
false at one site with every guard green, having been repaired at the other in the same milestone —
the same enumeration going stale at the site nobody re-read. A repair that leaves the next author the
same silence is not a repair. `scripts/test-command-taxonomy.sh` group `UW` asserts it: for each
command file it splits Zone A from Zone B by that file's own zone rule, derives the read-only verb
set from each verb region's own no-write declaration, and fails when a Zone A universal over the verb
set stands beside one.

**Reversibility: CHEAP · confidence HIGH.**

### 7. What this record does NOT decide

| Not decided here | Decided by |
|---|---|
| **Derived trip history** — how a person's trip set is computed, what it renders, and what it costs | `ADR-017-derived-trip-history.md` |
| **Group merge and group split** | nothing — declared out of scope above, not deferred |
| The person record's no-slot enumeration, and the sentence at `reference/schemas/person-record.md` that states it | **unchanged by this record.** A group record is a different class, and the edge direction is what keeps the exclusion true |
| `reference/data-model.md` § *Field Scope* | **untouched.** A group record is not an intake form and has no answerable slot, so this record adds and changes zero rows there |
| The **publish-guard group letter** and its arm ladder | the guard-suite slice, at its own commit |
| Whether `trips/*` should be rooted in `.gitignore` as its two siblings are | **UNOWNED.** Named here because this record read the difference; `trips/` has no tracked witness, so it is not a live defect |
| The extractor coupling in `scripts/validate-artifacts.sh`, which matches § 1.1's heading **including its count** as a whole literal | **UNOWNED beyond this milestone.** This slice moves the literal because it must; making the extractor read the count rather than match it is a later card |

## Consequences

### What becomes true, and what becomes checkable

- A named group is referenceable as a unit and expands to its members, which is the card's outcome.
- **AC1, AC5 and AC6 are satisfied structurally**: there is no slot for a person-scoped fact, and no
  code path from any `group-*` verb to a delete under `people/`. What is owed is the negative
  assertion, not a rule — `reference/schemas/person-record.md` states that idiom and this class
  inherits it.
- **AC3 is checkable as a byte-identity**: after a membership edit, every file under the expanded
  trip is unchanged.
- The class joins the machine-graded corpus — a schema, a tracked witness, a coverage row, a
  publish-guard group, and a taxonomy row per verb.

### Costs and residual risks, stated rather than minimised

- **No narrative home for a group.** § 3 above. Accepted.
- **No re-sync.** § 4. This is AC3, not a gap — but an operator who wants one will look for it.
- **The store materialises outside git.** Once real records exist, relocating the store is a
  migration and revert does not reach a git-ignored tree. **EXPENSIVE**, and the mitigation is to
  settle the path here rather than later.
- **The byte-identity property in § 4 is ungraded.** A cross-issue acceptance criterion covering it
  was offered and declined, so the property holds by construction and **nothing tests it**. An
  ungraded structural property holds until something changes it and nothing notices; that is the
  accepted residual, and it is recorded here so a later reader finds it rather than rediscovering it.
- **The class-count literal in `scripts/validate-artifacts.sh` will break again.** This slice moves
  it; the next in-model class moves it again. Routed to § 7 as unowned.

### Reversibility summary

| Decision | Tier | Confidence |
|---|---|---|
| § 1 identity scheme | MODERATE | HIGH |
| § 2 store home | MODERATE (EXPENSIVE once records exist) | HIGH |
| § 3 membership shape and direction | CHEAP | HIGH |
| § 4 expansion semantics | CHEAP | HIGH |
| § 5 erasure reach row | MODERATE | HIGH |
| § 6 command surface | CHEAP | HIGH |

## References

- `reference/adr/ADR-012-people-library.md` — the person store this record builds beside: § 1
  identity and the disjoint-namespace requirement, § 2 the store home and the `cross-trip` sentinel,
  § 3 the `person:` edge and its four resolution branches, § 5 the refused back-reference, § 7 what
  it does not decide. **Edited by this milestone on one line only**, to route the group store here.
- `reference/adr/ADR-017-derived-trip-history.md` — the sibling record. The coupling between the two
  is recorded there; § 4 above names the property it rests on.
- `reference/adr/ADR-003-group-coordination.md` — the incumbent trip-scoped sense of "group", and the
  anonymization argument § 2 above cites.
- `reference/adr/ADR-007-command-entry-point.md` — § 3 fixes the direction: to add a request type,
  add the command first. The command file's requirement table is the edit; the derived region in
  `reference/command-reference.md` is regenerated, never hand-edited.
- `reference/adr/ADR-011-per-traveler-cost-estimation.md` — records a prior renumber of § 1.1's
  enumeration. **Preserved, not edited**: it is a record of a past act.
- `reference/adr/ADR-013-count-assertion-basis.md` — governs every numeral this milestone moves.
- `reference/adr/ADR-014-cross-trip-consent-refusal.md` — the boundary `group-add` respects when it
  refuses to mint a person record.
- `reference/data-architecture.md` — § 1.1 the class enumeration, § 3 the identity rule, § 4.2 the
  frontmatter/body boundary, § 4.3 no-double-home, § 4.4 the universal block and the `cross-trip`
  narrowing, § 5.1 the publish enum, § 7.6 the upgrade contract, § 10's count-assertion fence.
- `reference/schemas/person-record.md` — the schema this class is shaped after, and the no-slot
  sentence § 7 above leaves unchanged.
- `people/README.md` — § *What a record does not hold*, whose five bullets this record does not
  touch, and § *Why this file is tracked and nothing beside it is*, whose arrangement `groups/`
  reuses.
- `.claude/commands/trip-record.md` — § *Selecting the verb* (frozen; exact string equality), the
  standing clause whose Extension rule admits rule 12, the incumbent `group` verb, and the erase
  reach table § 5 above extends.
- `.gitignore` — the three shipped store-guard pairs and the comment stating why a signpost under an
  excluded parent cannot be re-included.
