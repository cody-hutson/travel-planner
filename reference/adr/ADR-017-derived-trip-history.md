# ADR-017: Derived trip history — a resolution rather than a record, a match the operator makes, and a suggestion that is never written

- **Status:** Accepted (2026-09-08)
- **Deciders:** repo maintainer
- **Driving work:** the Groups and trip history milestone. This is the **second** of that
  milestone's two head decision records, in the shape
  `reference/adr/ADR-012-people-library.md` already ships: it settles the cross-cutting
  questions its feature slice would otherwise answer inside a verb section, where a later
  author would not find them.
- **Sibling record.** `reference/adr/ADR-016-reusable-groups.md` covers reusable groups.
  **The coupling between the two records is recorded here**, in § 8, because it is this
  record that depends on that one and not the reverse. That record decides nothing about
  how trip history is derived, and this one decides nothing about the group store.

## Context

### The question, and the answer that was wrong first

A traveller who has been somewhere before wants a different plan from a traveller who has
not. The trip form already asks — `Been here before?` and `Already done`, on
`templates/traveler-intake.template.md` — and `agents/01-activities.md`,
`agents/02-food.md` and `agents/04-transport.md` each read the first of them to calibrate
how obvious or deep a candidate set runs. The question this record answers is
whether the platform can **answer that question from what it already knows** rather than
asking a returning traveller to re-state it.

The obvious shape is to keep the answer on the person: *a person record carries the trips
that person has taken.* **That shape is closed by shipped structure, and it was closed
before this milestone opened.** `people/README.md` § *What a record does not hold* lists
**trip history** among the things the durable form has no slot for, and
`reference/schemas/person-record.md` gives the mechanism: group and party composition, any
split, computed values, trip history and a second person's data all classify `TRIP` or
`DEST` under `reference/data-model.md` § *Field Scope*, *"so the durable form has no slot
for any of them"*. Nothing enforces it because nothing needs to — the classification is
the enforcement.

So the premise was re-scoped rather than the exclusion widened: **trip history is
resolvable for a person, and never stored on the person.**

### The three constraints the corpus already imposes on any answer

**One — there is no Destination entity, and therefore no destination key.**
`reference/data-architecture.md` § 3.4 assigns eleven entities across the two identity
kinds, and Destination is not among them. The two available proxies are both unusable as a
join basis: `- **Primary destination:**` in a trip's `trip-context.md` is free prose with
no controlled vocabulary, and the trip directory slug is the **Trip** natural key, whose
destination component is a naming convention rather than a field. Matching on either is a
**name-similarity join** — the mechanism
`reference/adr/ADR-012-people-library.md` refuses by name for person discovery, on the
ground that a mutable display string is not an identity. Here it is worse, because there is
no surrogate to fall back to.

**Two — the consuming rule is an aggregate, so *advisory* is not a property a written value
can keep.** `Been here before?` is not read per traveller and acted on per traveller. It
feeds a **party-level depth weighting** in `agents/01-activities.md`, `agents/02-food.md`
and `agents/04-transport.md`, and `agents/00-enrichment.md` states the abstention rule: an
unanswered field *"is `unknown`, never `never`"*, and that traveller *"contributes no depth
signal in either direction"*. Moving one traveller from abstention to a value therefore
changes the distribution the weighting reads, which changes which candidate sections carry
more candidates. **A value written into `travelers/<traveler>.md` is indistinguishable from
the traveller's own answer**, whatever the writer called it.

**Three — the corpus has already named this capability's output, twice, and named it the
same both times.** `reference/data-model.md` § *Composition and resolution* says of the
`DEST` class that the person record *"may supply a **suggestion**, never an authority"* and
that *"Trip wins. Direct entry stays available and stays authoritative for the trip."* Its
Field-Scope row for `Already done` says a later trip-history capability *"would
**supplement** these two, never replace them."* Those forward-hooks were written before this
milestone; this record realises them rather than re-deciding them.

## Decision drivers

- **One source per fact.** A stored history would be a second home for something the trips
  already say, and the two would drift with nothing arbitrating.
- **Erasure has to stay total.** Anything this capability creates is a location an erasure
  must reach, and the reach table is the receipt's whole population.
- **No invention.** A derived value may not assert something the derivation cannot ground.
- **Reuse over re-implementation.** A second identity predicate, a second discovery scan or
  a second resolution vocabulary would each be a second source of truth.
- **The read-scope ceilings already declared are properties, not defaults.** A verb that
  widens another verb's stated ceiling to avoid writing its own section erodes a shipped
  guarantee for a saving that is not real.

## Options considered

### Where a person's trip history lives

| | Option | Verdict |
|---|---|---|
| **O1** | **A back-reference list of trips on the person record.** | **Rejected — and it was already rejected.** This is `reference/adr/ADR-012-people-library.md`'s own `O9`, refused there on three independent grounds: one source per fact, privacy, and the archived write it forces — *"and it survives erasure of the trip."* Nothing about this milestone changes any of them. |
| **O2** | **An index or cache under the store, refreshed on write.** | **Rejected.** `reference/adr/ADR-012-people-library.md` `O10` refuses a persisted result on staleness: *"Staleness is fatal and undetectable … It fails silently, returning a plausible, wrong, non-empty set."* A history index has the same failure and a worse blast radius, because a stale one is read as *this person has not been here* — which is the one reading § 5 below forbids outright. |
| **O3** | **Resolve on demand by inverting the trip-side reference.** | **Chosen.** It is the **exact complement of `O1`**: the same information, carried with no durable artifact and no survival past erasure. |

**Why the complement framing is load-bearing rather than rhetorical.** `O1` was refused for
what it *leaves behind*. `O3` leaves nothing behind — so every one of `O1`'s three grounds
is not merely mitigated but structurally absent. That is the whole argument for the branch,
and it is checkable rather than asserted: § 6 states it as a set relation.

### How a prior trip is matched to this destination

| | Option | Verdict |
|---|---|---|
| **O4** | **Match on the trip slug's destination component.** | **Rejected.** The slug is the Trip natural key; its destination component is a naming convention. Two trips to the same city in different years share a prefix by habit, not by rule, and nothing asserts it. |
| **O5** | **Match on the `- **Primary destination:**` string, normalized.** | **Rejected.** Free prose. *"Lisbon"*, *"Lisbon, Portugal"* and *"Lisboa"* are one destination and three strings; a normalization that unified them would be a similarity join wearing a normalization's clothes. |
| **O6** | **Introduce a Destination entity and key.** | **Rejected — out of proportion, and not this card's to take.** It is a new entity in `reference/data-architecture.md` § 3.4, a controlled vocabulary, a backfill over every existing trip, and a migration path. A capability that only needs a *suggestion* does not get to mint an entity to produce one. |
| **O7** | **Present candidates; the human decides which are the same destination.** | **Chosen.** |

**What `O7` buys, and it is the design's main robustness argument.** Under `O4`–`O6` a
partial or ambiguous match is an exception branch, and an exception branch is where a wrong
rule hides. Under `O7` partial and ambiguous matching is the **general case** — every
candidate is presented and every match is confirmed — so there is no ambiguity rule to get
wrong, and no threshold anyone has to defend.

### Where the derived value goes

| | Option | Verdict |
|---|---|---|
| **O8** | **Write the suggested value into `travelers/<traveler>.md`, marked advisory.** | **Rejected, and the ground is constraint two above.** The mark is not read by the aggregate. Once written, the value enters the party depth weighting and changes the candidate sets the depth-reading agents produce. A value that changes the plan is not advisory, whatever its own field says. |
| **O9** | **Write it only where the field is unanswered.** | **Rejected — the same defect, narrowed.** Unanswered is precisely the state that abstains from the weighting, so this option writes exactly the values that change the distribution and skips exactly the ones that would not. It is the worst-targeted version of `O8`, not a safer one. |
| **O10** | **Present the suggestion at the point of asking; the traveller answers.** | **Chosen.** The engine writes nothing to either field. |

### The point of use

| | Option | Verdict |
|---|---|---|
| **O11** | **Extend `## profile <name>`.** | **Rejected by that verb's own declared read-scope ceiling**, which closes the exact reads history needs: *"Does not read `trip-context.md`, in either direction"* and *"Takes no `Bash(ls:*)` use."* |
| **O12** | **Extend `## link <name> <person-id>`.** | **Rejected.** `link` reads the store but not other trips, so this is the same widening — on a **writing** verb, which is worse. |
| **O13** | **Run it inside `agents/00-enrichment.md`.** | **Rejected — wrong moment and wrong role.** Enrichment carries values through; it does not ask. `agents/04-transport.md` binds the depth signal's reader in terms: *"Read this file for the depth signal and for nothing else."* |
| **O14** | **A new read-only verb on `/trip-record`.** | **Chosen.** `reference/adr/ADR-012-people-library.md`'s own principle is that discovery *"reads at its own point of use, inside the agent that needs it"*, and a per-verb `**Reads:**` line is how this corpus declares a new read scope. |

## Decision

### 1. History is a resolution, defined rather than stored

For a person id `psn-<token>`:

> `history(p)` is the set of trips `t` such that some `t/travelers/*.md` frontmatter
> **currently** carries `person: q`, where `q ∈ closure(p) = {p} ∪ {r : r.merged-into = p}`,
> with redirect depth pinned at exactly one hop.

The durable person record gains **no field**. The store gains **no file, no index and no
cache**. **No resolution result is persisted anywhere**, and the resolution runs on demand
at its point of use. Four properties follow, and each is checkable rather than asserted:

| Property | Why it holds |
|---|---|
| **Erasure-complete** | The `erase` reach table removes the `person:` field and rewrites the bearer to the tombstone stem. After an erasure the edge is gone, and what survives is a per-(person × trip) token that correlates with nothing. |
| **Merge-correct** | Closure over `merged-into:` at one hop means a merge does not split a person's history; a stub of a stub is `MALFORMED`, reported, never followed. |
| **Consent-safe by construction** | A party member admitted through the operator fallback has no traveller file bearing a reference, so no edge, so no history — the boundary `reference/adr/ADR-014-cross-trip-consent-refusal.md` draws is preserved without a rule being written for it. |
| **Not a travel record** | The set is *trips currently carrying the edge*, never *everywhere this person went*. A trip they were unlinked from is invisible to it, and § 5 forbids reading that invisibility as absence of travel. |

### 2. The scan is the shipped discovery scan, reused rather than re-authored

`reference/adr/ADR-012-people-library.md` already chose a two-stage forward scan over a
declared bearer set, against an index, a back-reference, a directory walk and a content
grep. **Resolution reuses that scan's first five steps unchanged** — the `merged-into:`
closure, the population and its canary, the lifecycle read, the frontmatter-only reference
read stopping at the closing `---`, and the match — and runs **neither** of its last two:
relevance is a per-field inheritance question history does not ask, and there is no update
signal because nothing is written.

Two deltas, both stated so a reader does not have to infer them. **Archived trips are in
the population and are read-only** — a past trip *is* the history, and reading is not
derivation, so the freeze has nothing to forbid. **The resolved trip is excluded from its
own history**, because a trip cannot be its own prior visit.

`UNDETERMINED` is **reused verbatim** rather than a synonym minted for this surface: it is
already the corpus's fail-closed token for a read that could not be completed, and a second
word for one state is a second thing to keep true.

### 3. The destination match is the operator's, and the engine never computes one

Resolution produces candidates and stops. Each is presented as its trip slug, that trip's
own `- **Primary destination:**` string, and its travel window; the operator or the
traveller says which candidates are the same destination, and that confirmation yields the
count `n`. **The engine offers no default selection, computes no similarity, and applies no
threshold.** Constraint one above is the whole of the reason: with no Destination key, any
automatic match is a name-similarity join over a mutable display string.

The travel window is included deliberately — it is what makes a match decidable when a
destination string is ambiguous, and it is trip metadata rather than person data. It widens
what a transcript carries, which § 9 records as a named residual rather than leaving it to
be discovered.

### 4. The suggestion is presented and never written, and the derivation refuses two values

Where the target field is **unanswered**, and only there, the resolution offers:

| Field | Offered | Refused |
|---|---|---|
| `Been here before?` | `n = 1` → **`once`** · `n ≥ 2` → **`a few times`** | **`know it well` — never.** It is a familiarity-depth claim and `n` is a visit count; a person may visit five times on business and not know a place, or once for a year and know it well. Offering it would be invention. **`never` — never.** See § 5. |
| `Already done` | **a pointer only** — that prior trips to this destination are on file, and which — | **any authored prose.** The field is the traveller's own statement of what they do not need to repeat, and nothing but they can supply it. |

**The mapping is total over what a count can ground and refuses exactly the two values it
cannot.** That is the whole of its justification, and it is why the enum is not mapped by
nearest ordinal.

**Where the field is already answered, nothing is offered at all** —
`agents/00-enrichment.md` binds the carry-through: *"carry the answer through verbatim,
never normalize it to a neighbouring value"*, and an offer over an answered field is the
first step of exactly that normalization.

**And no engine path writes either field.** The traveller's own answer is the only thing
that reaches `travelers/<traveler>.md`. This is a requirement derived from the aggregation
rule rather than a preference: written, the value stops being advisory at the aggregate and
the plan changes with nothing having asked.

### 5. Three states, and the two absences never collapse

Derivation creates a second kind of absence where the corpus had one, and conflating them
is the failure mode this section exists to close.

| State | Meaning | Offers a suggestion? |
|---|---|---|
| `RESOLVED(n ≥ 1)` | `n` operator-confirmed matching prior trips | **yes**, per § 4 |
| `NO-EDGE-FOUND` | the scan completed and no trip carries the edge | **no — never** |
| `UNDETERMINED` | the store or the trip population could not be read, a bearer was present but unreadable, a reference dangled, or a stub was malformed | **no — never**, and the indeterminacy is stated |

**`NO-EDGE-FOUND` and `UNDETERMINED` are reported differently and behave identically:**
neither yields a value, neither is ever rendered as *this person has not been here*, and
under both the field stays **unknown**. This is `reference/data-model.md`'s own rule —
*unanswered reads unknown, never `never`* — preserved at the new layer rather than restated
as a new one. The scan's population canary is inherited with it, so *no trip references this
person* can never be concluded from a directory that could not be listed.

### 6. Erasure — zero new reach rows, and the coverage is structural

The capability adds **no row to the `erase` reach table**, because it creates no location.
That is a checkable claim rather than a promise: the table's stated accounting is graded
against the table itself in both directions, so a row added without its accounting is red.

Coverage is a set relation and is proved rather than asserted:

> `history(p)` = { trips carrying `person: q`, `q ∈ closure(p)` } = **exactly** the
> population the `erase` verb's own discovery step reaches. That step removes the field
> from every one of them and the record is deleted, so after an erasure `history(p)` is
> empty and no id-based read reconstructs it.

**Two residuals are named rather than dropped.** The **session transcript** is typed
`REPORT` / `UNREACHABLE` by the reach table, with the standing instruction never to echo a
subject value — so a history read prints **trip slugs and a count only**, never a person's
name, never a field value from a prior trip, and never a record's body. That is the same
convention the profile-extraction preview already ships, which *"names fields rather than
showing values"* on exactly this ground. And the **unlinked trip** is invisible to history —
but it is equally invisible to erasure, which lists such trips and changes nothing in them.
**The two blind spots are the same set**, so derivation adds no reconstruction surface that
erasure did not already fail to reach.

### 7. The command surface — one read-only verb, and no new standing rule

The capability ships as a single verb on `/trip-record`, declaring its own `**Reads:**`
line and writing nothing anywhere. **It takes no widening of the standing clause**, and the
reason is worth stating because the sibling slice needed two: every widening in that clause
derives a permitted **write** target or operation, and a verb that writes nothing has
nothing to derive. `## profile <name>`'s read-scope ceiling is left exactly as it stands.

The verb reads the trip population and each trip's lifecycle and destination **from the
pre-executed blocks the command file already carries**, which is what keeps its own read
scope to the traveller frontmatter and the person store. No pre-execution block is added:
the contract's declared depth fixes how many the file carries, as an equality rather than a
minimum.

### 8. The coupling with the group store, recorded here

`reference/adr/ADR-016-reusable-groups.md` § 4 decides that expanding a group onto a trip
writes the **same `person:` field, with the same value, in the same position** as a
hand-made link, and writes nothing naming the group into any trip artifact. **That property
is load-bearing for this record.** Resolution inverts exactly that field, so a
group-expanded edge and a hand-linked one must be indistinguishable — if they ever diverge,
`history(p)` under-reports for every group-assembled trip, silently and with nothing
detecting it.

**The dependency runs one way and it is recorded here because it is this record that
depends.** It is preserved by construction rather than by a graded criterion; that record
names it in its own verb section, in its decision and again as a residual, and this section
is its fourth home for the same reason: an ungraded structural property holds until
something changes it and nothing notices.

### 9. What this record does NOT decide

- **How reusable groups work.** That is `reference/adr/ADR-016-reusable-groups.md`'s, in
  full.
- **Pre-filling a `Desire`.** `reference/data-model.md`'s Field-Scope row for `Desire`
  carries a permissive forward-hook that a later trip-history capability *may* pre-fill it.
  This record does not realise that hook: a desire is authored prose plus its ranking
  sub-fields, which is a materially different capability from offering one value from a
  closed enum. The hook stays open and stays permissive.
- **Whether resolution can run without naming a person.** Resolving every linked
  traveller's candidates in one pass multiplies the transcript surface § 6 names as a
  residual, for no need this milestone states. Left undecided rather than refused.
- **Any change to the erasure model, the person schema or the reach table.** All three are
  untouched, and § 6 is the argument for why they can be.

## Consequences

### What becomes true, and what becomes checkable

- A returning traveller is **offered** what the platform already knows, and still answers
  for themselves. The forward-hooks in `reference/data-model.md` that anticipated this
  capability are **realised** rather than left standing as unowned promises.
- The durable person record's exclusion list is **unchanged and still true**: history is
  resolvable *about* a person without anything being stored *on* them. The claim is
  mechanised — the class-field set of `reference/schemas/person-record.md` and the absence
  of `TRIP`/`DEST` labels from `templates/person-intake.template.md` are both graded by
  `scripts/test-artifact-schema.sh`, so the exclusion stops resting on care.
- The auto-write prohibition is **stated in the verb's own section and graded**, which is
  what stops it from being lost to a later author who reads *advisory* and writes the value.

### Costs and residual risks, stated rather than minimised

- **Resolution is `O(Σ K)` frontmatter reads** where `K` is the bearer count per trip,
  against the `O(1)` an index would pay. `reference/adr/ADR-012-people-library.md` already
  accepted the same trade for the same scan and said why: the cost becomes real only at a
  scale where an index's staleness is already unmanageable. At a household's trip count the
  comparison is academic.
- **The operator does work the engine will not do.** Confirming each destination match is
  the price of having no Destination key, and it is charged every time. `O6` is the option
  that would remove it, and it remains available to a later card that has a second reason
  to want an entity.
- **The transcript residual is real and is mitigated rather than closed.** Slugs and counts
  are still a correlation an erasure cannot reach. The mitigation is the convention this
  corpus already uses for the same hazard, not a new mechanism.
- **The coupling in § 8 is ungraded.** It was offered as an acceptance criterion and
  declined, so nothing downstream tests it. Recorded as a residual on both records.

### Reversibility summary

**MODERATE, confidence HIGH.** Reverting removes a verb, a section and some rationale
prose, and the guard suites re-assert the pre-state. **There is no operator-side data
residue at all** — the branch stores nothing, so no record, no trip and no store carries a
field that would survive the revert as inert text. The store branch `O1` would have been
EXPENSIVE for exactly the reason it was refused, and the asymmetry is itself an argument
for the branch taken.

## References

- `reference/adr/ADR-012-people-library.md` — the person identity, the discovery scan this
  record reuses, the erasure reach, and options `O9` and `O10`, which are the two shapes
  this record is the complement of.
- `reference/adr/ADR-014-cross-trip-consent-refusal.md` — the consent boundary § 1 inherits
  by construction.
- `reference/adr/ADR-016-reusable-groups.md` — the sibling record. The coupling is § 8 here.
- `reference/data-model.md` — § *Field Scope*, its `DEST` composition rule, and the two
  forward-hooks this record realises.
- `reference/data-architecture.md` — § 3.4, the entity assignment that establishes there is
  no Destination key.
- `reference/schemas/person-record.md` — the durable form's exclusion and the negative
  assertion it says is owed.
- `people/README.md` — § *What a record does not hold*, where the exclusion is stated for a
  reader rather than for a machine.
