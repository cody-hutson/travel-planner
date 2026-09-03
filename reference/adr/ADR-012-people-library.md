# ADR-012: People library — cross-trip person identity, merge semantics, erasure reach, and reference discovery

- **Status:** Proposed (2026-09-03) — this record is a scaffold mid-authorship; see *Scaffold state*.
- **Deciders:** repo maintainer
- **Driving work:** the People library milestone. This record is the prerequisite architecture
  decision that milestone's first acceptance criterion requires, and it is the milestone-head
  decision gate for the spikes that feed it.
- **Scaffold state — this record is deliberately incomplete, and every incomplete section says so.**
  The milestone's design work is split across several spikes plus one ratifying record. Each spike
  contributes **one Context subsection** stating what it established, as evidence. The ratifying
  record runs last, is the first artifact to see every spike's findings together, and writes
  **Decision drivers**, **Options considered**, **Decision**, **Consequences**, and the flip of the
  `Status:` line above to `Accepted`. A section below carrying a *Not yet written* block is
  unwritten, not empty-by-decision: **read it as absent, never as a claim that there is nothing to
  say.** This two-step — a record landing `Proposed` and ratified by a later commit — is the one
  `ADR-006`, `ADR-007` and `ADR-010` already used, and `reference/adr/README.md` names it as the
  status lifecycle's entry state.

## Context

### The person store — what the identity-and-merge spike established

*This subsection records the findings of the spike on person identity collision and merge semantics,
**as evidence**. It states no decision. Where it says the shipped rule "yields" an answer, that is a
report of running a rule the corpus already carries, not a ratification of the result — ratification
is the Decision section's, below.*

**The card asked one question that is two, and the corpus already answers the first.**
`reference/data-architecture.md` § 3.2 decided the *within-trip* same-name case: the operator
disambiguates the display name, *"which changes the key,"* and *"the engine never mints a suffix."*
That case is closed and this milestone does not reopen it. What remains is the *cross-trip* case —
one human holding two records across two trips — and it is a different question because **it is
about a different entity.**

**Person is not Traveler.** Traveler is the trip-scoped participation record: natural key,
`trips/*/travelers/*.md`, publish-guard normalization, all untouched here. Person is the durable
cross-trip record this milestone introduces — an **eleventh entity**, absent from § 2's ten-row
table. Applying the shipped rule to that new entity is the whole question, and it is the opposite of
minting a competing convention. The risk the milestone names is *inventing a second **rule***, not
*reaching a different **answer** than Traveler did*: § 3 is explicitly a procedure over entities that
already returns different answers for different entities, splitting the set five surrogate / five
natural in § 3.4.

**Running the shipped rule on Person.** § 3 states two limbs, *both* of which must hold for the
natural branch: identity **originates outside the engine**, and the natural candidate is **already
the token the operator types** — *"the directory name, the file name, the heading, or the link
target."*

| Limb | Traveler (§ 3.2) | Venue (§ 3.3) | **Person** |
|---|---|---|---|
| 1 — identity originates outside the engine | holds — a human | holds — a real place | **holds** — a human |
| 2 — the natural candidate is already the token the operator types | holds — filename, `## <Name>` heading, roster entry; one trip, one token | fails — one venue carries three name strings across three artifacts | **fails** — three falsifiers below |
| **Rule yields** | natural | surrogate `ven-` | **surrogate** |

Limb 2 fails for Person on three independent grounds, in descending strength:

1. **§ 3.2's own mandated remedy mutates the candidate.** When two travelers collide, § 3.2 requires
   the operator to disambiguate the display name, *"which changes the key."* A person travelling
   alone on one trip and alongside a same-named traveler on another is therefore typed under **two
   different tokens by the engine's own rule.** A natural-keyed Person would be split, or
   re-identified, by a governance act the engine mandates — self-falsifying against the rule that
   would license it. No other entity's natural key is mutated by a rule the same document ships.
2. **The operator types a per-trip token, and Person spans trips.** Every source limb 2 names sits
   *inside a trip directory*. For a cross-trip entity there is no such token: a candidate would have
   to be **elected** from N per-trip tokens, and electing one is minting a key, not reading one.
3. **The divergence that forced `ven-` applies verbatim.** § 3.3 grounds Venue's surrogate on one
   venue carrying three name strings. A person recorded twice under different spellings is the same
   divergence.

**The rejected alternative, recorded as evidence.** A natural-keyed Person reusing § 3.2's normalized
name is genuinely attractive — zero new convention. It fails on falsifier 1, and it would additionally
place a durable join key under operator text editing, so that correcting a spelling would
re-identify a personal record and orphan every inbound reference.

**The canonicalizations, each grounded in a measurement of the tracked corpus.** Measured on this
branch over **126 tracked files**; each row's sensitivity arm is a variant that must fire and its
specificity arm a variant that must not.

| Canonicalization | Current state measured | Sensitivity arm | Specificity arm | Yields |
|---|---|---|---|---|
| **Key prefix** | `ven-` 156 · `evt-` 99 · `per-` 536 across 69 files, **0 of them token-shaped** (all English distributive: `per-traveler` 165, `per-trip` 65, `per-event` 54) | `ven-` → 156 | `psn-` → **0**, a free namespace | an opaque three-letter prefix on the `evt-`/`ven-` formation, disjoint from the corpus's densest English prefix |
| **Token format** | every id in instance data is 4 lowercase hex; charset measured as exactly `0123456789abcdef`; the 2-char forms appear only as prose illustration | 4-char hex in `examples/` → 140 | non-hex token in `examples/` → **0** (the 6 non-hex tokens in the corpus are all documentation placeholders or test fixtures, in 3 files, none instance data) | `[0-9a-f]{4}`, matching the opacity guarantee § 3.3 cites for the Event id |
| **Reference field name** | the corpus names an entity-reference field after the entity (`venue:`, `trip:`), never with an `-id` or `-ref` suffix; frontmatter keys are kebab-case (§ 4.1) | `venue:` → 11, and it is the **only** such key observed | camelCase / snake_case key → **0** | `person:` on the traveler record; `merged-into:` on a merge stub |

Because the prefix is a **surrogate**, the person key carries no name and is therefore not itself a
disclosure surface. `per-` and the person prefix are disjoint, so the erasure spike's tombstone
namespace and this one do not collide — but **any detector over either must be shape-anchored**
(`<prefix>-[0-9a-f]{4}`), never a bare substring: a bare `per-` matches 536 English occurrences.

At four hex digits the space is 65,536 values, so at a store of ~100 records the birthday collision
probability is about 7%. Minting must therefore **assert non-existence and re-mint on collision**.
Widening the token was weighed and set aside as evidence, not settled here: it would make Person the
only entity with a different token width, against a re-mint loop that is cheap at a store whose
realistic size is tens of records.

**The record's shape.** The key is **filename-borne** and is **not restated in frontmatter** —
§ 4.3's no-double-home rule bars copying a value that already lives in a structural position. The
**display name is the body H1**, never a frontmatter value, which is § 3.2's own posture applied to a
record whose filename is opaque: the H1 becomes the display name's single home, and its normalized
form is what creation-refusal asserts over.

**Creation refusal, and why it needs a predicate.** Under a surrogate, minted ids never collide, so
an acceptance criterion phrased as *"creating a record whose identity collides with an existing one
fails with a named remedy"* is **vacuously true if read against the surrogate** and its control
evaporates. The spike found that its *identity* must resolve to the **normalized display-name key**:
refusal fires on **exact equality after § 3.2's existing normalization** (lowercased, every
non-`[a-z0-9]` character removed — reused, not re-authored) against a live record. Exact equality
after a defined normalization — **never similarity, never edit distance, never fuzzy matching.** The
remedy has three branches, all operator acts: **link** to the existing record, **disambiguate** the
display name and create, or **create anyway with the collision acknowledged**. The third branch is
available *because* the key is a surrogate — co-existence is safe when ids differ and merely
confusing, so the refusal exists to make the operator look, not to prevent a corrupt state, and it
keeps a same-named couple from being unrepresentable. The separation between refusal and merge is
structural rather than procedural: refusal reads a name and refuses a **creation**; merge reads two
operator-supplied **ids** and never reads a name at all. No code path runs from a name comparison to
a merge.

**The reference topology is what makes merge cheap, and it is a constraint rather than an
observation.** A trip points at a person exactly once — one field on the traveler-profile class. The
person key is deliberately **not a join basis inside trip artifacts**: trip-internal joins run on the
Traveler natural key (§ 3.2) and on `Applies to`, which § 3.4 states needs no change. A merge
therefore touches **one field in one class**, and never reaches trip rosters, itineraries, research
lists, the derived model, or the publish path. **Keeping the person key out of trip-internal joins is
what bounds merge's blast radius**; the bound does not survive without it.

**Merge semantics, as the spike established them.** Merge is operator-initiated with two explicit
ids, never triggered by name similarity, and proceeds in five steps:

1. **Refuse before writing anything** — when either id fails to resolve, when **either id is already
   a stub** (which pins redirect-chain depth at exactly 1, permanently and testably), when the two
   ids are equal, or when **the referencing set cannot be determined**. An indeterminate set is never
   treated as an empty one; merge refuses rather than repointing a partial one.
2. **Survivorship, decided by rule rather than by the operator where consent is in play.** Where
   provenance differs the **self-authored record survives**, and this is forced by `ADR-006`'s
   consent boundary rather than chosen: if an operator-provided record survived, self-authored values
   would inherit its provenance and be wrongly fenced, while the reverse would silently **un-fence**
   third-party values — a consent-laundering path straight through that boundary. Provenance
   therefore **travels with the value, not with the record**, carried by the entry-scoped inline mark
   § 4.4's enum already defines. Field-level: present in one record only, or present in both with
   equal values → absorbed; present in both and **unequal → CONFLICT, and the merge refuses**,
   reporting every conflicting field for adjudication. No automatic pick, because newest-wins on a
   need silently overwrites a bound on the plan — `reference/data-model.md` records that *a need is a
   constraint that bounds the solution* — and silently choosing between two allergy or mobility
   values reproduces the very failure the milestone exists to prevent, at field granularity. The one
   deterministic exception is an **expired** field losing to a live one, an expired value not being a
   competing claim. The display name is a normal conflicting field, adjudicated the same way, and
   that is the correct and only place for the operator's choice.
3. **The stub lands first, and this is the atomicity argument.** The loser is rewritten in place at
   its own path as a **permanent stub** carrying `merged-into:`, the merge timestamp, and the receipt.
   **From that single write forward the state is correct** — every existing reference to the loser
   resolves, through exactly one redirect hop, to the survivor. Repointing N traveler files is not
   atomic; a one-file stub write is. A crash after this step leaves a correct system, and so does a
   crash during the next one.
4. **Repoint lazily, and only where it is free.** Active referencing trips get the person field
   rewritten to the survivor. **Archived trips are never written**; they keep pointing at the stub
   and resolve through it indefinitely.
5. **Signal only the active trips actually repointed.** The stub write alone is not a content change
   and signals nothing.

Merge **repoints links; it never copies facts.** An absorbed field *moves*: the loser stops asserting
it in the same write that makes the survivor assert it, so `reference/data-model.md`'s *one source
per fact* rule holds **across** the operation, not merely after it.

**The freeze interaction, and a useful negative result.** Erasure must reach an archived trip because
it **removes information**. Merge needs **no freeze exception at all**, because it only
**re-addresses**, and a redirect re-addresses without writing. The general form both cases
instantiate: *a frozen trip admits no derivation; an operation that must still reach one should
re-address in place of rewriting wherever a redirect can carry the change.* The freeze rule therefore
gains no second exception from this half of the milestone.

**The inverse case is solved, not deferred — and the receipt is the whole of it.** The stub *is* the
receipt: it retains, in the loser's own file, the loser's **complete pre-merge body and frontmatter**,
the **survivor's pre-merge values for every field the merge changed**, the **per-field survivorship
decisions**, and the **list of traveler-file paths repointed**. Unmerge is then a mechanical
inverse — clear the redirect, restore the loser's content, restore the survivor's changed fields,
repoint the listed files back — with no search, no inference and no name matching.

The bound is stated rather than hidden: unmerge is *exact* only while the survivor has not been
edited since the merge. After a later edit it is **exact for the reversal and honest about the
remainder**, restoring both records and **reporting every field changed after the merge as
unattributed** for operator adjudication; it never guesses which record a post-merge edit belonged
to. Detecting that condition needs one field on the survivor — a last-written timestamp compared
against the stub's merge timestamp. **Without it, "has the survivor been edited?" is unanswerable and
the honest report is impossible**; it is a requirement, not an assumption.

**Reversibility is a property of the receipt, not of merge.** The person store is git-ignored, so
there is no revert to fall back on. With the receipt an incorrect merge is **MODERATE** — a
mechanical undo in minutes with one honest gap. Without it, it is **IRREVERSIBLE**. That distance is
why the receipt is mandatory rather than a nicety.

**One case merge cannot fix, routed rather than absorbed.** If a record turns out to describe *the
wrong human* — one record holding two people's facts because of a mis-attribution at intake, rather
than two records for one person — the remedy is a **split**, and split has no receipt to work from
because no merge ever happened. Split is **out of scope** for this milestone, with reasoning: it is a
data-correction operation over a single record with no prior transaction to invert, its inputs are
per-field operator judgments, and nothing in this milestone creates it. Recorded so that "the inverse
case" is not silently read as covering it.

**What this spike did not settle, stated so it is not read as settled.** The person store's on-disk
**location**, and the **artifact-class band** the record occupies, are both the ratifying record's.
The design depends on exactly one property of that band: that `merged-into:` is a machine-checkable
field on a **schema-bearing** class, which the schema-bearing options supply and under which the
existing schema-bijection gate covers the stub form at no extra cost. Under an out-of-model
disposition the design still works but **loses its test surface** — measured: the out-of-model rows
carry **zero** files in `reference/schemas/` — and would need a bespoke stub-shape assertion in the
guard suite. Named, not hand-waved.

**One risk this spike could not discharge, recorded as still open.** The *within-trip* half of the
collision problem remains unmitigated on the trip side, and this design does not change it: § 3.2
records that the intake surface selects edit-over-create on a bare file-existence probe with no
collision check, so a second same-named traveler silently overwrites the first — *"in files the
model itself describes as carrying real personal detail."* That is the Traveler entity, which § 3.2
governs and this design deliberately leaves untouched. The person store's own refusal predicate,
above, covers the **store** side only. The trip-side half has no owner in this milestone.

### Erasure reach — what the erasure-reach spike established

*This subsection records the findings of the spike on how far erasure of a person record must reach,
**as evidence**. It states no decision. Where it reports that a mechanism "fails" or that a candidate
is "falsified", that is a measurement against shipped code and shipped prose — never a ratification of
whatever replaces it; ratification is the Decision section's, below. Two of the spike's own readings
were corrected after it ran, by siblings reading sources it had not. Each correction is carried **in
place** rather than appended, and named where it changed the reading.*

**Every artifact class below is named by path, never by its ordinal in `reference/data-architecture.md`
§ 1.1.** That enumeration is closed at 27 — 21 in-model, 6 declared out of model — and its numbering
moved *during this milestone*, when a sibling release inserted a class ahead of the person store. The
spike's own output cited ordinals; six of those citations came to name the wrong class before the
milestone that produced them had shipped, one of them across the in-model/out-of-model boundary. A
path does not do that.

#### Why regeneration is the wrong mechanism — measured, not asserted

The obvious design is *clean the sources, then regenerate everything downstream*. It fails, and the
failure is arithmetic rather than aesthetic: **regeneration reaches only the `rebuilt-each-synthesis`
classes**, and a traveller's display name is not confined to them.

| Class group | Lifecycle · provenance | Reached by regeneration? |
|---|---|---|
| `outputs/final-itinerary.md` and every `outputs/final-itinerary-v<N>.md` | `versioned` · `derived` | **No.** The versioned siblings are frozen by their own class: a re-synthesis produces a *new* version, it does not clean an old one |
| `outputs/activities-list.md` · `food-list.md` · `nightlife-list.md` · `scheduling-framework.md` · `transport-brief.md` · the targeted-research outputs | `accumulate-append` · **`researched`** | **No.** § 4.4 defines `researched` as holding *"independent state"* and being *"not a regenerable projection: re-running the writer against the same inputs is not guaranteed to reproduce it"* |
| `trip-log.md` | `accumulate-append` · `human` | **No.** A narrative register whose body is never schema-constrained |
| `trip-context.md` | `persist-mutable` · `human` | **No.** The Layer-1 human source — the thing regeneration reads *from* |
| `outputs/event-status.md` | `persist-mutable` · `recorded` | **No.** Surviving a re-synthesis is the whole point of the class |
| `engine-learnings.md` | **out of model** — no declared writer, no lifecycle, no schema | **No writer exists to instruct** |
| the rendered site HTML and its secondary renders | `output` · `derived` | Yes — a sink, never a source |
| `outputs/traveler-model.md` · `links-reference.md` · `venue-matrix.md` · `satisfaction-metrics.md` · `validation-report.md` · `destination-shortlist.md` · `cost-estimate.md` | `rebuilt-each-synthesis` · `derived` | Yes for the **file** — but not for every **entry** in it. See *Two entry classes*, below |

**The measurement, and its baseline.** On the one live multi-traveller trip in the working directory,
at the spike's baseline, a display name rested in twelve in-model artifact classes plus files at the
trip root. The frozen itinerary siblings alone carried **143** occurrences and the `researched` classes
**43**; the rendered site — the only large group regeneration does reach — carried 45. Trip trees are
git-ignored, so **those counts are not reproducible from the tracked corpus** and are recorded as the
spike measured them, against a baseline that no longer exists. What the tracked corpus does support,
and what the design actually rests on, is the class table above: every row of it is read from
`reference/data-architecture.md` § 1.1 and § 4.4 rather than from any trip.

**The conclusion the table forces:** a design that says *erasure regenerates the derived model* has
covered one class and left the rest standing. **Erasure is value substitution across a fixed reach
set, and never regeneration.**

#### The reach set — a fixed table, two axes, and a receipt that is total over it

**Disposition is static, compiled into the spec; outcome is dynamic, emitted per run.** That split is
what lets a caller tell three different silences apart, and it is the whole answer to *how does a
caller know a location was not missed?*

| Disposition | Meaning | Emits a receipt row? |
|---|---|---|
| **REACH** | erasure must reach it | yes |
| **REPORT** | erasure **cannot** reach it and **must name it**, because it may hold person data | yes — outcome `UNREACHABLE`, carrying a concrete path or URL |
| **OUT** | erasure cannot reach it and owes no report, because the location is *declared* to hold no person data | **no** — a caller checks "no row" against the spec's OUT list, and never infers it from silence |

Outcome tokens on a row are `ERASED` (removed; a re-read confirms), `TOMBSTONED` (the row survives,
carrying the tombstone), `UNREACHABLE` (a REPORT row's only outcome) and `UNDETERMINED` (could not be
measured). **`UNDETERMINED` is never a pass** — erasure inherits the fail-closed posture § 5.4 already
fixes for the publish guard, that *an empty read is not an empty class*.

**The receipt is total over the table**, and that is a structural property rather than a diligence
one: every REACH and REPORT row emits exactly one row on every run, so a location can only be missing
from the receipt **by being missing from the spec**. "Silently partial" stops being a failure mode the
implementation can have and becomes one only the *spec* can have — which moves it somewhere a review
can see it.

**Two of the table's verification methods prove more than "the record file is gone", and they are the
two worth naming here.** The frozen-sibling assertion runs over the **whole** `final-itinerary*` glob
rather than the current version, which is the only way a `versioned` class can be checked at all. And
the `researched`-class assertion bounds the **byte-length delta** by (occurrences × token-length
delta): zero subject hits proves the name went, and the length bound proves *nothing else moved* —
the property a substitution into an independent-state artifact must carry and a regeneration cannot.

**The set's size, and why the number moved.** The spike enumerated **22** locations. It re-derives to
**28** against the current tracked corpus: **+2** for two name-bearing surfaces inside the `## Group`
block that the spike's roster locators did not name; **+1** for the person-reference field the
identity work above added *after* the spike ran; **+2** for the two merge-stub directions, counted as
a single location by the first reconciliation; and **−1** for the file-less model entry, which is an
entry **class inside** an existing location rather than a location of its own. The derivation is
recorded alongside the number because a receipt's row count is graded against the spec table: the two
must agree, and a count carried forward without its derivation is a count that silently stops
agreeing.

#### Two entry classes, failing in opposite directions

**This is where the spike's own reading was wrong**, and the correction is load-bearing rather than
tidying. The spike gave `outputs/traveler-model.md` the disposition *active trip → regenerate,
archived trip → substitute*. Regeneration does not erase every entry in that file.

`agents/00-enrichment.md` names one entry class it **preserves rather than regenerates**, and states
the reason in terms: that person has *"no source file to be refreshed from"* and *"no source file by
design"*, so the model about to be replaced is read first and the entry *"carried into the newly
written model **verbatim** — same name key, same need text, both marks"*. **The predicate is both
marks** — `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` — and the agent states the exception four
separate times in that file, so it is a deliberate design property rather than a phrasing accident.

| Entry class | What a regeneration does to it | How erasure fails if it regenerates |
|---|---|---|
| carrying **both** `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]` | **carried forward verbatim** — there is no source file to re-derive it from | the entry **survives the erasure**. A person who asked to be deleted keeps their recorded need on every subsequent synthesis |
| carrying `[OPERATOR-PROVIDED]` **alone** | **not** carried forward — the carry-forward predicate does not match it, and there is no usable profile to project from | the entry is **dropped**, and the display name **re-enters** from the roster on the next pass |

**These are not one defect at two addresses; they are inverses**, and conflating them is precisely the
error the first reconciliation of this finding made. The both-marks class is the population `ADR-006`
restricts to needs — a child, or a party member on someone else's booking — and it is the class least
able to ask for its own deletion.

**The re-entry surface is the `## Group` roster in `trip-context.md`, and it is measured.** The
enrichment agent's § *Traveler identity* makes the roster cell **the name authority**, and calls the
model heading and the traveller-file stem *projections of that cell*. So a model-only erasure is not
merely incomplete: the next reconciliation is *instructed* to re-enumerate the party under the roster
name, and the name returns **by design**.

| Probe | Population | Subject | Sensitivity arm | Specificity arm |
|---|---|---|---|---|
| Is `## Group` a `trip-context` surface? | every tracked `trip-context` surface — the four example trips and the template | **5 of 5** | any `## ` heading → 5 of 5 | `## Zzqxwvblorp` → 0 of 5 |
| Is `## Group` a `traveler-model` surface? | the one tracked `outputs/traveler-model.md` | **0 of 1** | any `## ` heading → 1 of 1 | — |

An earlier null result on this question was a **wrong-surface probe**, not a false claim: the section
was looked for in the derived model, where it correctly is not.

#### The freeze boundary — real, but narrower than it looks

**The freeze protects derivation, not bytes.** Concluding a trip performs a takedown, writes a
`**Lifecycle:**` marker and appends a closing log entry. **It moves nothing** — an archived trip's
artifacts sit at exactly the paths an active trip's do. The freeze is enforced entirely by the gate
table in `CLAUDE.md` § *Resolving a trip*, whose own defaults say so: *"an undeclared `lifecycle` is
`ACTIVE`"*, *"a verb absent from the table is `REFUSE`, never `RUN`"*. It is a **policy over the
refresh path**, never a filesystem barrier.

> An archived trip receives **no derivation** — no update signal, no regeneration, no refresh.
> **Erasure is not a derivation; it is a redaction, and it reaches an archived trip.**
> Concretely and checkably: **on an archived trip, erasure substitutes and never regenerates.**

**Why that wording rather than a blanket exception.** "Erasure may write archived trips" would license
any future erasure-adjacent operation to rewrite history. The narrow form binds the *mechanism*:
substitution replaces exactly the erased person's identifying values and can **prove** it touched
nothing else — the byte-length bound above is that proof. What the freeze protects, the plan as it was
planned, survives byte-for-byte apart from one name. The two rules never actually collided;
**"frozen" was being read as "untouchable" when it means "underivable".**

Three consequences, each falsifiable:

1. **Erasure declares `lifecycle: ANY` in its own gate row** — the shape the reopen verb already uses
   with `lifecycle: ARCHIVED` — and it **never flips the marker.** The alternative this displaces is
   reopen → erase → re-conclude, and its cost is read from the concluding verb's own text: that path
   flips the lifecycle marker twice and **appends a second closing entry to the log of an
   already-concluded trip**, for an operation meant to be a redaction. *(The spike additionally
   recorded that the re-conclude step would be refused at the gate. That sub-claim does not hold
   against the shipped table, where the concluding verb declares `lifecycle: ACTIVE` and a reopened
   trip satisfies it. The alternative is displaced by the state it mutates, not by a refusal.)*
2. **Sources before derived, and the order is load-bearing rather than tidy.** Derived-first leaves an
   interrupted run's sources dirty, and the next reconciliation **resurrects** the name into a
   freshly-cleaned model. Source-first makes an interrupted run self-healing on an active trip; on an
   archived trip nothing regenerates, which is why the receipt is per-file and the operation must be
   idempotent and re-runnable. Which source goes *first* is fixed by the name authority above.
3. **Reopening a trip resumes normal refresh with no special case** — and only because the tombstone
   is written into the **source** traveller file rather than into the derived model. A reopened trip
   regenerates the model from source and reproduces the tombstone, instead of resurrecting the name or
   dropping the entry.

#### UNKNOWN, never the empty set

**The requirement is a safety property, not a cosmetic one.** The milestone's own risk register names
the failure: a dangling reference read as *"no constraints"* → a traveller's needs vanish and the plan
grades as compliant. If erasure empties an `Applies to:` list, the hub stops auditing that constraint
on every applicable day and the validator agrees with it. **Erasure would become a path to a
compliant-looking unsafe plan.** So a constraint's `Applies to:` is substituted and **never emptied**,
the roster row **survives**, and `- **Total travelers:**` is **unchanged** — erasure does not reduce
the party, because the person travelled.

**The tombstone is `## per-<token> [ERASED]`**, carried in every location it reaches — `Applies to:
per-<token>`, and so on. Four properties, each verified against running code in
`scripts/publish-trip-site.sh` rather than asserted:

| Property | Mechanism |
|---|---|
| Survives the parse | `clean()` strips bracketed spans as metadata, leaving the bare `per-<token>` |
| Never an empty key | the literal `per` prefix guarantees ≥ 3 characters in `[a-z0-9]` after normalization **even if the token folded to nothing**, so the guard's empty-key hard stop becomes structurally unreachable |
| Never a reserved key | `per…` is not a member of the guard's reserved-key set |
| Never blocks a publish | the entry carries no *declared entry selector*, so the guard's leak-token branch is not taken and no name token enters the non-publishable class |

**Three candidates were falsified against that same code rather than merely dispreferred:**

- **a bare `[ERASED]` mark** — `clean()` strips bracketed spans, so the key normalizes to the empty
  string and the reconciler hard-stops;
- **the literal `UNKNOWN`** — `unknown` already sits in `stated()`'s stop-list, and two people erased
  from one trip collide on one key, halting reconciliation for that whole trip;
- **reusing the person-record id.** The spike rejected this for two reasons and **only the second
  survives.** Once the identity work above chose a *surrogate*, the id carries no name and the
  name-leak reason is void. What stands is that a reused id is a **stable cross-trip pseudonym for
  someone who asked to be deleted**, and it silently discloses that the same person travelled on those
  trips.

**Token uniqueness is per (person × trip), not per person**, for that same reason — and it costs
nothing, because § 2 makes every Traveler relationship trip-internal, so every join the tombstone must
preserve is already trip-scoped. The **only** cross-trip edge is the person record: the thing being
deleted.

**Two constraints this places on work outside the spike, both traps rather than preferences.**
`[ERASED]` **must never be added to the publish-contract fence** — declaring it an entry selector
would make the tombstone a non-publishable leak token, and because it appears in `trip-context.md`
§ Group, which is `publish: bound` and rendered, **every subsequent publish of that trip would abort,
permanently.** And any detector over the tombstone namespace **must be shape-anchored**
`per-[0-9a-f]{4}`: a bare `per-` substring matches **546** occurrences across **70** tracked files,
every one of them the English distributive (`per-traveler`, `per-trip`, `per-event`). The literal
`[ERASED]` measures **0** corpus-wide against a `[THIRD-PARTY]` sensitivity arm of 143 and a nonsense
specificity arm of 0 — **the namespace is free.**

#### Irreversibility, and what a mistaken erasure actually costs

**Tier: IRREVERSIBLE · confidence HIGH.** The rollback-infeasibility statement: no revert reaches it.
Trip trees are git-ignored, so the erased bytes are recoverable from nothing — not from a revert, not
from the repo, not from the log. The `researched` classes hold independent state nothing upstream can
reconstruct. And the published surface is beyond any local act at all: prior ciphertext commits remain
in the public per-trip repo, rotation re-encrypts **forward only**, and re-publishing adds a commit
rather than removing one. That is why the published surface is REPORT and not REACH, and why its
receipt row carries the repo URL and a commit count instead of a verdict.

**The cost is stated separately from the tier, because the tier does not carry it.** A mistaken
erasure destroys one person's durable record **and** silently degrades every trip they were on:
substitutions into the frozen, `researched` and narrative classes cannot be reversed even where the
person record could be re-entered by hand. A re-entered person gets a **new** identity and a **new**
history. That is a worse outcome than a mistaken takedown of a published site, which the shipped
corpus already gates behind a typed confirmation at a terminal.

**Guard rails the spike found owed** — recorded here because two of them fall to work landing *before*
the erasure verb, which is a sequencing fact rather than an implementation detail: a dry-run reach
report, confirmed **against** the write, showing locations and counts and **never values**; a typed
confirmation, refusing a non-interactive run without an explicit flag; a standing rule that the
operation **never echoes an erased value**, deliberately inverting the echo-the-row-verbatim rule the
roster-edit verb carries, because echoing here is what would put the value into a transcript; the
person store's own README naming the erasure verb **at record-creation time**, so a user learns the
exit exists when they create the first record rather than when they need it; a tolerant read that
distinguishes a **tombstoned** reference from a **dangling** one — both resolve to UNKNOWN, only one
is a defect; and erasure being **never inferred and never cascading**, an explicit verb over an
explicit subject.

#### Unlink and erase are near-inverses, which is why they cannot share a verb

The shipped roster-edit verb already proves the distinction is real: it removes a roster row while
stating that it *"never delete[s] anything under `travelers/`"*, because that file is Layer-1 source
and the verb has no path to it.

| | **unlink** — a traveller leaves a trip | **erase** — a person is deleted |
|---|---|---|
| Roster row | **removed** | **survives**, tombstoned |
| `- **Total travelers:**` | decremented | **unchanged** |
| The traveller's own source file | untouched | rewritten to a tombstone stub |
| The person record | untouched | deleted |
| Scope | one trip | every trip, plus the store |
| Reversibility | CHEAP | **IRREVERSIBLE** |

They are near-inverses **on the roster row**, so sharing a verb would be dangerous rather than merely
untidy — and the same argument reaches the leave-a-trip verb this milestone adds. It also matters for
detection: were erasure to remove the row, its post-state would converge with unlink's and the
tombstoned-versus-dangling distinction above would stop working **with a green build**.

#### What this spike did not settle, stated so it is not read as settled

**The reach set is neutral on the person store's artifact-class band** — in-model class or an
out-of-model disposition — and nothing in it depends on the choice, because the tombstone lives
entirely inside classes that already exist. It imposes one constraint that holds either way: **the
person record must carry a `lifecycle` whose definition admits deletion**, and of the five tokens in
§ 6 only `persist-mutable` does. One clause of that definition needs disambiguating, because read
carelessly it forbids the tombstone. *"No ghost row lingers"* governs a row whose **subject was
removed from the trip** — the unlink case. The tombstone is the opposite fact: the subject did **not**
leave the trip, they were erased, and the row must persist so the reference resolves to UNKNOWN rather
than to an empty set. **The tombstone is not a ghost row; it is the record that a row was here.**

**One documentation surface the spike surfaced has no owner in this milestone.** `trips/README.md`
ships a retention posture — *"Nothing here expires on its own. No command deletes a trip folder, no
timer runs"* — which is the baseline this design replaces, and which becomes false the moment an
erasure verb ships. The same table also instructs the reader to *"Copy a profile forward"*, which
contradicts the one-source-per-fact rule this milestone extends. Named, not fixed.

### Reference discovery — what the person-edit discovery spike established

*This subsection records the findings of the spike on how a person edit discovers the trips that
reference it, **as evidence**. It states no decision. Where it reports a premise "falsified" or a
mechanism "rejected", that is a measurement against shipped prose and shipped code, never a
ratification of whatever replaces it; ratification is the Decision section's, below. **One of the
spike's own readings was corrected after it ran** — its relevance predicate keyed on the *presence*
of a trip-side line, which the shipped intake template forbids as a discriminator. The correction is
carried **in place** rather than appended, and the paragraph it changed says so. Artifact classes
below are named by path, never by ordinal, for the reason the erasure-reach subsection above states.*

**The card's premise contains the cost it fears, and the shipped engine has already paid it.** The
framing was that a person edit has no way to find its referencing trips *without scanning the whole
working directory on every pass.* But `CLAUDE.md` § *Resolving a trip* ships `E2` — a `grep` over
`trips/*/trip-context.md`, a **cross-trip glob executed on every invocation** of the four commands
declaring `population-role: RESOLVE`. A cross-trip read at marker granularity is not a new cost this
design introduces; it is the shipped baseline. The open question was never *may we look across
trips*, it is *how much of each trip must we open* — and under a reference borne on **one frontmatter
field**, the answer is: the frontmatter and nothing else. Measured on the tracked fixture, that is
**332 bytes across the 2 bearer files, 3.15% of their own bytes and 1/597 of the 21-file, 198,329-byte
example trip** a whole-directory walk would open. *(The scope of that measurement is named because a
ratio measured on an operator's own git-ignored working directory is not reproducible from this repo
and is therefore not restated here. The tracked figure is the one anyone can re-derive.)*

#### Two directions, and only one carries the guarantee

The card asks for *a defined mechanism for resolving a person record to its referencing trips*. That
is one direction of a two-direction problem, and naming the other changes what the mechanism has to
be good at.

| | **PULL** — a trip asks about its people | **PUSH** — a person edit asks about its trips |
|---|---|---|
| Trigger | the trip's own enrichment pass (already runs) | the moment a person record is written |
| Scope | the travellers on **this** trip | the bearer files across the **population** |
| Session boundary | **inside** the resolved trip | **across** unresolved trips |
| Can it miss a trip? | **No** — it *is* that trip's own read | Yes: an unreadable store, a bearer it does not know about, an interrupted run |
| What a miss costs | — | the operator is surprised at that trip's next open |
| Carries the fan-out risk? | **Yes** | **No** |
| Existing machinery | the shipped per-trip diff, source set widened | none — this is the new mechanism |

> The milestone's risk register names a fan-out that misses a referencing trip, leaving that trip
> planning against durable facts that have changed. **That risk is not mitigated by making the scan
> complete. It is mitigated by making the scan unnecessary for correctness.** A trip cannot plan
> against stale durable facts, because it recomposes its own source set before it plans. The
> cross-trip scan exists to *shorten the latency* between a person edit and each affected trip
> learning about it — never to be the thing that guarantees they learn.

Three consequences fall out of that reclassification, each of which the card would otherwise have to
solve the hard way:

1. **The fail-safe becomes affordable.** A mechanism on the correctness path cannot fail loudly and
   proceed; one on the latency path can. Discovery may report `UNDETERMINED` and stop.
2. **The cost ceiling drops.** PUSH runs **once per person edit**, not *on every pass*. The per-pass
   cost is PULL's, which is per-trip and already paid.
3. **The every-referencing-trip criterion becomes satisfiable at all.** `G2` resolves **exactly one**
   trip per session — *many* → *ask which, never guessing* — and a session's write surface is its
   resolved trip. So *every active referencing trip receives the signal* is satisfied by the **union**
   of PUSH (the resolved trip, now) and PULL (every other trip, at its own next resolution), and never
   by one session writing N trips. Any other reading asks a session to write trips it never resolved,
   crossing the trip-resolution contract and writing archived ones — breaking the criterion's second
   half while satisfying its first.

**PULL's one requirement, stated because this design depends on it and does not own it.** The shipped
per-trip diff compares a derived model entry to *its source file*. PULL works **only if the thing
diffed is the composed source** — the trip's `travelers/<traveler>.md` **plus** the person record it
references — not the trip file alone. If the diff stays trip-file-only, a person-record edit is
invisible to PULL and the fan-out guarantee falls back onto the best-effort scan, which is exactly the
fragile design this split exists to avoid.

#### The mechanism — a two-stage forward scan over a declared bearer set

`T` = trips, `K` = bearer files per trip, `P` = person records.

| | **A · Forward scan (frontmatter)** ✅ | **B · Index in the store** | **C · Back-reference on the record** | **D · Whole-directory scan** | **E · Content grep for the key** |
|---|---|---|---|---|---|
| Mechanism | read the reference field from each bearer | a `person → [trips]` map maintained on link/unlink | each record lists the trips referencing it | walk every trip file, match anywhere | grep the key across every trip file |
| Bytes read | the frontmatter — **3.15%** of the bearer bytes on the tracked fixture | ~1 KB **plus the scan needed to trust it** | ~1 KB **plus the scan needed to trust it** | every byte under `trips/` | every byte under `trips/` |
| Complexity | O(Σ K) tiny reads | O(1) read, O(1) write per link | O(P) reads | O(all files) | O(all files) |
| **Staleness** | **none — no persisted state to go stale** | **fatal and undetectable**: `trips/` is git-ignored and hand-edited, so a hand-deleted trip never updates it, and you cannot tell without running A | same, plus it goes stale when a *trip* changes while the record does not | none | none |
| One source per fact | ✅ reads the one source | ❌ **a second home for the reference field** | ❌ same, and it **inverts** the reference direction the identity work fixed | ✅ | ✅ |
| Privacy | ✅ nothing new written | ⚠️ a cross-trip travel map in the durable store | ❌ **a durable plaintext list of the trips a person travelled on** — the cross-trip linkage the erasure work mints per-(person × trip) tokens to destroy, and it **survives erasure of the trip** | ✅ | ✅ |
| Archived trips | read-only, never written | **a write on link/unlink → writes an archived trip** | same | read-only | read-only |
| False positives | none — the field **is** the reference | none | none | **high** — a display name in an itinerary is not a reference | **high** — the key in a narrative or a receipt is not a reference |
| Fails how | loudly | **silently** — a stale index returns a *plausible, wrong, non-empty* set | silently | loudly | silently on a rejected pattern |

**A is chosen. B and C are rejected on three independent grounds each — one source per fact, privacy,
and the archived write — any one of which is dispositive; cost is not among them and is not the
argument.** D and E are rejected on cost **and** on false positives: a name or a key appearing in a
file is not a reference, and *the person key is not a trip-internal join basis* is what makes that
distinction crisp rather than heuristic.

**The honest cost of A.** It pays O(Σ K) per person edit where B pays O(1). At a household's trips
and tens of records that comparison is academic — and **A's cost becomes real only at a scale where
B's staleness is already unmanageable**, because B's correctness assumes every trip mutation went
through a linking verb, and `trips/` is a git-ignored directory the operator edits by hand. **The
idiom that would make B safe is the one that makes B pointless: validate the index by running A.**

**Two mechanisms are rejected for reasons that are not cost.** The tempting move is a third
pre-execution evidence block beside `E1`/`E2`. It is refused by the contract's own text:
`contract-depth` is an **equality, not a minimum**, the depth→prefix map is fixed, and *a file
carrying more of the list than its declared depth requires is exactly as non-conforming as one
carrying less.* A third block would force **all** `G8` consumers to carry it and acquire a wider
grant, editing a surface this milestone does not otherwise touch, for no gain. **Discovery reads at
its own point of use, inside the agent that needs it**; `E1`/`E2` are cited as precedent for shape
and cost, never as a surface to extend. A **persisted result cache** is refused on the same grounds as
B: it is an index with a shorter half-life and the identical failure mode.

**The scan, specified. Every failure branch is named, and none of them returns an empty set.** The
input is an edited person id together with the set of field names that changed — the edit knows what
it wrote.

1. **Closure.** The id set is the edited id plus every record in the store carrying a `merged-into:`
   pointing at it. **Redirect-chain depth is pinned at exactly 1** by the identity work's
   refuse-if-either-id-is-already-a-stub rule, so this is a single pass and not a fixpoint; a stub
   whose target is itself a stub is typed **`MALFORMED`**, reported, and never followed. A store that
   cannot be listed → **`UNDETERMINED`**, stop.
2. **Population.** Enumerate the trip directories — the `E1` shape. **`G1`'s canary applies
   verbatim**: `README.md` must appear as an exact trimmed line, and absent → **`UNDETERMINED`**,
   naming `trips/` as the directory that could not be listed. **The conclusion "no trip references
   this person" is forbidden here**, exactly as `G1` already forbids concluding that no trip exists.
3. **Lifecycle.** Read `**Lifecycle:**` per trip — the `E2` shape — with `G4`'s shipped default,
   **absent ⇒ `ACTIVE`**. An unreadable `trip-context.md` makes that trip **`UNDETERMINED`**, never
   silently `ACTIVE` and never silently dropped.
4. **Reference read — stage 1, cheap.** For each trip, read **frontmatter only** from every member of
   the declared bearer set and extract the reference field, stopping at the closing `---`. A bearer
   present but unreadable makes that trip **`UNDETERMINED`**.
5. **Match.** A trip is **`REFERENCING`** exactly when some bearer carries a reference in the closure.
6. **Relevance — stage 2, scoped.** For **matched trips only**, read the bearer bodies and decide
   per-field inheritance by the rule below. **The expensive read is scoped to the answer of the cheap
   one.** An unreadable body makes relevance **`UNDETERMINED`** for that trip, which **degrades to
   reference-level signalling** — noisier, never silent.
7. **Partition and emit.** `ACTIVE` and relevant → **signal**. `ACTIVE` and not relevant → **report
   only**. `ARCHIVED` → **report only, never written**. Anything `UNDETERMINED` → reported as
   `UNDETERMINED`, and the run's overall verdict is `UNDETERMINED`.

Delivery honours the one-trip-per-session bound: the **resolved** trip's `## Update signals` block is
written by this session, and every other trip is named in the report and receives its signal at its
own next resolution through PULL. That block is **reused, not invented** — it measures **13
occurrences across 5 files**, including the shipped fixture. The run writes no other state, so it is
idempotent and re-runnable.

**The result vocabulary, measured against the tracked corpus rather than minted freely.**
`UNDETERMINED` is reused **verbatim** for every indeterminate branch: it is the corpus's densest
fail-closed token (**71 occurrences across 9 files** on this branch) and already carries the rule this
design needs, that an undetermined result is never a pass and *an empty read is not an empty class*.
Minting a synonym would create a second vocabulary for one posture. Of the tokens this design needs
beyond it, `REFERENCING`, `NOT-REFERENCING`, `OVERRIDDEN` and `DANGLING` each measure **0** and are
free; **`TOMBSTONED` is reused from the erasure-reach subsection above**, where it is already an
outcome token meaning *the row survives, carrying the tombstone* — the write-side and the read-side of
one state, so discovery adds no synonym; and **`MALFORMED` is reused rather than minted**, because it
measures **4** occurrences in `scripts/test-command-taxonomy.sh` as a finding token for a row that
does not parse to its expected shape — the same sense, the same polarity. `INHERITS` measures **1**,
and that one is English prose in a shell comment (*ROTATE INHERITS THE GATE*), not a status token; the
namespace is free **as a token** and the distinction is recorded rather than rounded to zero, for the
same reason the identity work records that a bare `per-` matches hundreds of English distributives.

#### Relevance is decided by answered-ness, never by presence

**This is the spike's own reading, corrected in place.** The spike decided relevance by *presence of a
trip-side line*, reasoning from the rule that *a trip carries a `DEFAULT` field only when it diverges*
and concluding that a line's presence therefore signals divergence. **That predicate is falsified by
the shipped intake template**, which mandates the opposite: *"Skipping a section never removes it from
the output: every field still ships, each with an em dash where the answer would go … Dropping the
lines loses the labels the planner parses."* A skipped field keeps its line. **Presence therefore
discriminates nothing on a real profile**, and the divergence-only rule has to be read as *carries an
answer*, not as *carries a line*.

**The engine already carries the correct predicate, in three places, and invents none of it.**

| Unanswered form | Where the engine says so |
|---|---|
| **blank or em-dashed** | `agents/00-enrichment.md`, twice: *"An absent, blank or em-dashed line is `one-off`"*, and *"A blank or em-dashed field … is **`unknown`, never `never`**"* |
| **absent** | the same first clause, which folds absence into the same equivalence class — so presence and absence reach one verdict rather than two |
| **a leftover `[bracketed placeholder]`** | `CLAUDE.md` § *Resolving a trip*: *"A field whose **trimmed value begins with `[` and ends with `]` is a placeholder**, never an answer"*, tested **by value**; and the template's own *"a leftover `[bracketed placeholder]` reads as unanswered, exactly like an empty line"* |

So **`ANSWERED()` is the negation of a union of shipped conditions**, and the shipped fixture states
the same rule in its own voice: *"Every label ships; the ones this fixture has no fact for carry `—`,
which the reconciler reads as not answered, never as an answer."*

**Measured, unanswered is the majority case rather than the exception.** Over the three tracked
bearer-shaped artifacts — the blank form and the two fixture profiles — each carrying the same **38
distinct labelled fields** the denominator rule derives:

| Population | Labelled body bullets | Answered | **Unanswered** |
|---|---|---|---|
| The two filled fixture profiles | 107 | 45 | **62 (58%)** |
| …restricted to the `DEFAULT` class | 30 | 4 | **26 (87%)** |
| All three artifacts, `DEFAULT` class | 45 | 4 | **41 (91%)** |

*Instrument: `python3`, an anchored label regex over body bullets, with the three unanswered forms
above. **Sensitivity** — `Name` and both `Specific` bullets on a fixture return answered, so the
predicate does fire. **Specificity** — the blank form returns **0 answered of 54 bullets present**, a
real population with a real known-zero count on the same live instrument that returns 45 answers
elsewhere, so the arm is neither dead nor tautological; a nonsense label returns 0. **Denominator
check** — all three artifacts independently yield 38 distinct labels, matching the denominator rule's
own derivation, so the instrument is aimed at the declared population. **A probe corrected before
use:** the first pass typed one blank-form bullet as answered — `Priority tier:` opens a **multi-line**
bracketed placeholder whose closing bracket a single-line anchored pattern cannot see. That was a
defect in the instrument, not a fact about the corpus; the arm reads 0 once the pattern spans lines,
and the correction is reported rather than quietly absorbed.*

**Answered-ness alone does not rescue every class, and this is where the corrected reading has to be
class-first.** On the two fixtures **all 8 `PERSON`-class bullets are present *and answered* on the
trip side** — the allergy and the heat ceiling are written into the trip's own traveller file today,
because the intake form has not yet been split. Under *either* a presence predicate or a naive
answered-ness predicate those bullets read as an override, and the safety class goes **silent** on a
person edit. The composition rule is what prevents that, and it is not a predicate over the line at
all: **`PERSON` is not overridable, so a trip-side `PERSON` value is a schema violation rather than an
override — refuse and report, never silently prefer one.**

| Changed field's class | Trip side | Verdict | What discovery emits |
|---|---|---|---|
| **`PERSON`** | *not consulted* — the person record is authoritative unconditionally | **`INHERITS`** | **Always signal.** Additionally, an **answered** trip-side value is reported as a **schema violation**, not as an override |
| **`DEFAULT`** | **not answered** (absent, blank, em-dashed, or still bracketed) | **`INHERITS`** | **Signal** — the durable value is what this trip plans on |
| **`DEFAULT`** | **answered** | **`OVERRIDDEN`** | **No replanning signal** — the trip already decided to diverge. **Reported**, for the reason below |
| **`TRIP`** / **`DEST`** | n/a | **`NOT-INHERITED`** | **No signal, no report** — the person record is not their authoritative source, and no person edit can touch them |

**So the correction replaces presence with answered-ness on exactly one class — `DEFAULT` — and
changes nothing elsewhere.** `PERSON` is decided by class authority, `TRIP` and `DEST` consult neither
predicate. And the direction of the change is the safe one: under presence, an em-dashed `DEFAULT`
line read as `OVERRIDDEN` and the trip **heard nothing** about a durable fact it was actually planning
on — the very fan-out failure the risk register names, arriving through the relevance rule rather than
through the scan. Under answered-ness the same line reads as `INHERITS` and signals. **The mistake
that remains possible is a spurious signal, not a silence.**

**Answered-ness is an instance property. Presence is a document property. They share a word and
answer different questions, and the correction must not be carried across the seam.** *What the form
asks* — the denominator of 38 distinct labelled fields plus one unlabelled slot, the four-class
partition over them, and the starred-pass split of library-sourced against re-asked — is keyed on the
**presence of a bullet in `templates/traveler-intake.template.md`**, correctly and unchangedly, because
a form asks a question by carrying its line. *Whether this traveller supplied a value* is keyed on
`ANSWERED()`. Discovery lives wholly on the instance side. The over-application is measurable rather
than hypothetical: applying the instance predicate to the document question scores the blank form at
**0 answered of 54**, which would read as a form that asks no questions and a starred set that is
entirely re-asked. That absurdity is the tell, and it is why the seam is written down here.

**Why an `OVERRIDDEN` trip is reported and not dropped.** The milestone's risk register names a
redundant override silently becoming meaningful, and **a person edit is that risk's trigger**: a trip
that wrote `Pace: relaxed` while the record also said `relaxed` holds a redundant override, and the
record moving to `packed` converts that line into a live divergence nobody decided on. The trip is
*correctly* un-signalled for replanning — its planned value did not move — and *incorrectly* silent if
the operator never learns the line became load-bearing. **Two dispositions, one edit; discovery emits
both and adjudicates neither.** It deliberately does **not** compute whether an override was
redundant: that needs the record's pre-edit value, and redundant-override normalization is already
assigned to enrichment, which holds that value as the model's last-processed composition. Computing it
here would put a second adjudicator on a rule enrichment owns.

**The card's own warning, answered rather than accepted.** *A design that notifies on reference alone
is noisy by construction* — quantified: notifying on reference alone signals **every** referencing
trip on **every** person edit, when 20 of the 38 labelled fields are `TRIP` or `DEST` and cannot be
touched by a person edit at all. Field-granular relevance signals only trips that inherit the changed
field. **Reference-level signalling survives only as the declared degradation** when a body read
fails, chosen deliberately, because noise is recoverable and silence is not.

#### Where the reference lives — a declared set, and one member is missing

**The mechanism is parameterized on a declared reference-bearer set, never on a hardcoded glob.**
Membership is the ratifying record's to fix; discovery's contract is *read the reference from wherever
the composition reads it.*

| Bearer | Reference field | Status |
|---|---|---|
| `trips/*/travelers/*.md` frontmatter | the person-reference field the identity work adds | **decided above.** The measured cost basis |
| the person store's own records | `merged-into:` | **decided above.** The closure input, step 1 |
| a **file-less** `[OPERATOR-PROVIDED]` + `[THIRD-PARTY]` model entry | **none exists** | **a named gap** |

**The gap is measured on the shipped fixture rather than hypothesized.**
`examples/data-architecture-demo/` holds **2 files under `travelers/` against 3 person entries in
`outputs/traveler-model.md`** — `Alex`, `Robin`, and `Sam [OPERATOR-PROVIDED]`. Sam has no source file
**by design**: `ADR-006` chose it, and the enrichment agent states it in terms — that entry *has no
source file to be refreshed from* and *the derived model remains that entry's record rather than its
authority.* The milestone gives exactly that person a durable record. Under a reference borne solely
on `travelers/<traveler>.md` **there is no file to bear it**, so discovery would return
`NOT-REFERENCING` for a trip that genuinely references the person — a **false negative**, the failure
the fan-out risk names — and the class it is blind to is the one `ADR-006` restricts to **needs**.
Sam's single recorded datum is a mobility limit. **The obvious scoping misses precisely the
safety-critical class.**

Discovery's behaviour is stated under each branch the ratifying record might take, so this reading is
decided either way: **(1)** a second bearer is declared — a roster reference, or a mark on the model
entry — and it simply joins the set, with **no mechanism change**, which is why the set is declared
rather than hardcoded; **(2)** party members are excluded from durable records, in which case the set
is complete as it stands **and the exclusion must be written down**, because silence here reads as
coverage; **(3)** undecided at implementation, in which case **discovery reports every file-less entry
in a candidate trip as `UNDETERMINED`, never as non-referencing** — fail-safe, and it makes the gap
visible at runtime instead of silently absent.

**One non-goal, stated because it is the tempting fix.** Discovery must **not** fall back to matching
person **display names** against model entries. That is a name-similarity join, it is the mechanism
the identity work forbids between naming and identity, and it would resurrect the same-name collision
the surrogate key exists to prevent.

#### The archived-trip case — no signal, never written, named in the report

| | Disposition | Grounding |
|---|---|---|
| Update signal | **none** | *An archived trip receives no derivation — no update signal, no regeneration, no refresh* |
| Any write to the trip | **none** | An ordinary content edit is neither a redaction nor a re-addressing. Erasure earned its exception because it **removes information**; merge needed none because a redirect **re-addresses** without writing. **An ordinary person edit does neither and qualifies for neither** |
| Discovery report | **named, and typed archived-and-not-signalled** | absence must be *stated*, never inferred from silence |
| Its `outputs/traveler-model.md` | unchanged — it holds the pre-edit composition | that is what the freeze protects: the plan as it was planned |
| On reopen | absorbs the new value at the next enrichment pass | reopening resumes normal refresh, the same shape the tombstone relies on |

**The residual this creates is named rather than left latent.** An archived trip's model is a frozen
composition over a source that did not stay frozen: the plan embeds person facts that have since
moved, and reading it you cannot tell. That is correct behaviour, not a defect — but it is invisible.

**It is detectable read-side with no new state and no write.** The shipped `_epoch_of_file` /
`_is_stale` idiom in `scripts/publish-trip-site.sh` — strict `>`, one-second granularity, its BSD/GNU
`stat` divergence already solved in-file — compares the referenced record's mtime against the derived
model's. Reporting that relation is legal precisely because `G8` fixes `trip.freshness` as
`(relation, verdict)` pairs whose membership is *that consumer's own declaration*, **and forbids a
gate**: *no gate may be added that blocks on freshness.* **This design adds a relation and no gate.**

**Why not simply signal archived trips and let the operator ignore it.** `G7`'s defaults make an
archived trip refuse every verb that does not declare otherwise, so a signal written there instructs
an engine that will refuse to act on it — noise unactionable without a reopen the operator did not ask
for. **The freeze gains no second exception from this half of the milestone**, which extends the
negative result the identity work already recorded for merge.

#### Telling a tombstone from a dangling reference, structurally

The erasure-reach subsection assigns the tolerant read a requirement: distinguish a tombstoned
reference from a dangling one — both `UNKNOWN`, only one a defect. This is discovery's half of it.
**The distinguisher is the presence of the reference field, not the outcome of resolving it**, which
is what makes it structural rather than heuristic and needs **no store lookup at all** for the
tombstone case.

| Observed | Disposition | Defect? | Verdict for that trip |
|---|---|---|---|
| A reference in the closure resolving to a live record | resolved | no | **`REFERENCING`** |
| A reference resolving to a `merged-into:` stub, one hop | redirected | no | **`REFERENCING`** — archived trips resolve through the stub indefinitely |
| A stub whose target is itself a stub | **`MALFORMED`** | **yes** | **`UNDETERMINED`** — chain depth is pinned at 1; a second hop is a store defect, reported, never followed |
| A tombstoned entry carrying `[ERASED]` and **no reference field** | **`TOMBSTONED`** | **no** | **`NOT-REFERENCING`, by design** — a declared, intentional absence: erasure removed the record and rewrote the bearer, so **there is no reference left to dangle** |
| A **well-formed** reference resolving to nothing | **`DANGLING`** | **yes** | **`UNDETERMINED`** — never `NOT-REFERENCING`. The trip may hold needs whose source is gone |
| The store unlistable, or the trip listing untrustworthy | **`UNDETERMINED`** | maybe | **`UNDETERMINED` for the whole run** — `G1`'s forbidden conclusion |

**The asymmetry that makes it work: a tombstone has no reference field to dangle, and a dangling
reference has a field that fails to resolve.** They are told apart by *shape*, locally, before any
store read — strictly stronger than telling them apart by *outcome*, and the same static-disposition
against dynamic-outcome split the erasure receipt is built on. **A partial erasure surfaces as
`DANGLING`, and that is correct**: erasure is idempotent and per-file, so an interrupted run can leave
a bearer still carrying a reference after the record is gone. That state **is** a defect, so reporting
it as one is right.

**One correlation discovery must never perform, stated as a prohibition rather than a preference.** It
is tempting to sharpen the diagnostic by correlating tombstone tokens across trips to prove an erasure
ran. **Do not.** The token is minted per (person × trip) precisely so that no cross-trip edge
survives, because *a single token reused across trips is a stable cross-trip pseudonym for someone who
asked to be deleted.* Re-establishing that edge to improve an error message reintroduces the linkage
erasure exists to destroy. **The diagnostic loss is accepted, and the trade is recorded here so it is
not silently re-litigated at implementation.**

**Staleness — the question dissolves rather than being answered.** The chosen mechanism holds **no
persisted state**, so there is nothing that can be out of date relative to the files: every run reads
the files. What *can* be stale is the composed model, which is a pre-existing condition of every
derived artifact in this engine and already has a shipped answer in the `_is_stale` relation above.
**A design whose staleness answer is "there is no cached state" is the strongest available answer, and
it is the sharpest single reason to prefer the forward scan over an index.**

#### How this set relates to the erasure reach set

The two sets answer the same question — *where does this person appear?* — for different purposes, and
the difference is **direction**, not scope. Erasure walks the person to every location their **data**
rests, and needs every byte; discovery walks the person to every trip holding a **reference edge**, and
needs only the edge. **Neither is a subset of the other.** They coincide on exactly two locations of
substance — the person record itself, which erasure removes and discovery resolves against, and
`trips/*/travelers/*.md`, which is simultaneously the densest erasure location and the primary
reference bearer. They diverge on four in principle: the roster and its `Applies to:` lines carry the
**name** and no reference field, so discovery does not read them *(unless the roster is later declared
a bearer)*; the research, itinerary and published surfaces are data-at-rest holding no edge, and
reading them **is** the whole-directory scan already rejected. And two locations are new here: **a
merge stub read as a discovery input** — the erasure work added stubs to its reach set in their
*erasure* role, while the role that a stub is how an archived trip's stale id still resolves is this
spike's — and **the file-less model entry**, which is in neither set: discovery is blind to it, and
the reach set's own re-derivation counts it as an entry class **inside** a location rather than a
location of its own.

#### What this spike did not settle, and one finding it routed rather than fixed

**The design is neutral on the person store's on-disk location and on its artifact-class band, and
depends on no property of either.** Discovery reads two frontmatter fields and one filename, and
assumes only that the store is **listable**. It assumes no schema, so an out-of-model disposition
costs this half of the milestone nothing — unlike the identity work, whose stub form loses its test
surface under that branch.

**The reference-bearer for a file-less entry is the one open item this spike surfaced that the
milestone does not already own.** It is a decision rather than a build, and the third branch above
gives discovery a safe posture until it is made — but until it is made, *every active referencing trip
receives the signal* is false for party members, and the fan-out risk fires on exactly the class
`ADR-006` restricts to needs.

**One finding against the erasure-reach subsection above, recorded because it was found here and is
not this spike's to fix.** That subsection's own correction already types the both-marks entry as
carried forward verbatim rather than regenerated. This spike reached the same conclusion from the
other side — the derived model is that entry's **record**, not a projection of it — which is the
reason the carry-forward exists at all, and it is why the erasure disposition for that entry must be
substitution rather than regeneration. **The readings agree; only the route differs**, and the route
matters because it also makes the entry a **source** for discovery's purposes, which is the sense in
which it is absent from the reach set.

**Reversibility: CHEAP · confidence HIGH.** This spike writes no engine file, creates no state, and
adds no gate. Its output is this subsection. The tier rises when the mechanism lands in
`agents/00-enrichment.md`, which is a different card's write.

## Decision drivers

> **Not yet written.** Authored by the ratifying record once every spike's Context subsection above
> is in. Read this section as absent, not as an assertion that no drivers apply.

## Options considered

> **Not yet written.** Authored by the ratifying record. Options weighed *inside* a single spike are
> recorded as evidence in that spike's Context subsection above — the rejected natural-keyed Person
> is one — and are consolidated here at ratification.

## Decision

> **Not yet written.** Authored by the ratifying record, which runs last and is the first artifact to
> see every spike's findings together. **Nothing in this record is decided until this section is
> written and the `Status:` line above reads `Accepted`.**

## Consequences

> **Not yet written.** Authored by the ratifying record, together with the Decision it follows from.

## References

*Accumulating — each contributing card adds the sources its Context subsection relies on.*

- `reference/data-architecture.md` § 2 (the entity model this milestone extends) · § 3 (the identity
  rule, its two limbs, and the Event validation case) · § 3.2 (the Traveler natural key, its
  normalization, the same-name hard stop, and the unshipped intake half) · § 3.3 (the Venue
  surrogate, the measured divergence forcing it, and the opacity guarantee) · § 3.4 (the five/five
  assignment and the `Applies to` invariance) · § 4.1 (kebab-case keys) · § 4.3 (the no-double-home
  rule) · § 4.4 (universal frontmatter, the entry-scoped provenance marks, and the `researched`
  definition — *holds independent state*, *not a regenerable projection* — that forces substitution
  over regeneration) · § 1.1–1.2 (the enumeration closed at 27, and the out-of-model dispositions the
  reach set must still name) · § 5.1 and § 5.4 (the `publish:` enum, and the fail-closed *an empty
  read is not an empty class* posture erasure's `UNDETERMINED` outcome inherits) · § 6 (the five
  lifecycle tokens, and the `persist-mutable` deletion clause whose *no ghost row lingers* wording
  needs disambiguating against the tombstone)
- `reference/data-model.md` — the *link, don't copy — one source per fact* rule that merge's
  absorb-and-stub sequence preserves, and the definition of a need as a constraint bounding the
  solution, which is why unequal field values refuse rather than resolve
- `reference/adr/ADR-006-third-party-data-capture.md` — the consent boundary that forces
  self-authored survivorship across a cross-provenance merge, rather than leaving it to the operator,
  and the needs-only restriction that makes the carried both-marks entry the population least able to
  ask for its own deletion
- `agents/00-enrichment.md` — the carry-forward exception whose predicate is **both**
  `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]`, stated four times in that file, which is what falsifies
  *regenerate the derived model* as an erasure mechanism; and § *Traveler identity*, which makes the
  `## Group` roster cell the **name authority** and the model heading and traveller-file stem its
  projections — the mechanism by which an `[OPERATOR-PROVIDED]`-only entry's name re-enters
- `CLAUDE.md` § *Resolving a trip* — the gate ladder and the two defaults the freeze rests on
  (*an undeclared `lifecycle` is `ACTIVE`*; *a verb absent from the table is `REFUSE`, never `RUN`*),
  which is what makes the freeze a policy over the refresh path rather than a filesystem barrier
- `.claude/commands/trip-decommission.md` — the concluding verb's load-bearing order (takedown,
  marker, closing log entry) and its `lifecycle: ACTIVE` row, against the reopen verb's
  `lifecycle: ARCHIVED`; together these price the reopen → erase → re-conclude alternative
- `.claude/commands/trip-record.md` — the roster-edit verb's *never delete anything under
  `travelers/`* rule, which is the shipped proof that unlink and erase are already distinct effects
- `scripts/publish-trip-site.sh` — `clean()`, `stated()`, the reserved-key set and the leak-token
  branch, against which the tombstone's four properties are verified and its three rejected
  alternatives falsified
- `trips/README.md` — the shipped retention posture (*Nothing here expires on its own*) that this
  design replaces, and the *Copy a profile forward* instruction that contradicts one-source-per-fact
- `reference/adr/ADR-009-data-architecture.md` — the record authoritative over the model this
  milestone extends
- `reference/adr/README.md` — the section spine, the `Proposed` → `Accepted` lifecycle this record is
  mid-way through, and the amendment-versus-supersession boundary
- `templates/traveler-intake.template.md` — the rule that falsifies a presence-keyed relevance
  predicate (*Skipping a section never removes it from the output: every field still ships*, each
  skipped field keeping its line and taking an em dash, because *dropping the lines loses the labels
  the planner parses*), and the companion statement that a leftover bracketed placeholder *reads as
  unanswered, exactly like an empty line*
- `reference/data-model.md` § *Field Scope — person-scoped, trip-scoped* — the four-class partition
  and its `PERSON` / `DEFAULT` / `TRIP` / `DEST` totals; the denominator rule stated as a derivation
  from the template rather than a literal; the composition-and-resolution table that makes a
  trip-side `PERSON` value a **schema violation rather than an override**, and makes a `DEFAULT`
  field's durable value authoritative unless the trip carries an answer; the redundant-override
  normalization assigned to enrichment; and the starred-pass split, which is the document-side
  counterpart this subsection is careful not to re-grade on the instance-side predicate
- `agents/00-enrichment.md` — the two statements of the unanswered equivalence (*an absent, blank or
  em-dashed line is `one-off`*; *a blank or em-dashed field … is `unknown`, never `never`*) that
  ground `ANSWERED()`; the `## Update signals` block this design emits into rather than inventing;
  and the carry-forward clause read here from the other side — the derived model is the file-less
  entry's **record**, which is why that entry is a discovery **source** with no bearer to carry a
  reference
- `CLAUDE.md` § *Resolving a trip* — the `E1`/`E2` evidence blocks whose shape and cost this design
  reuses without extending; the `contract-depth` **equality** that refuses a third block; `G1`'s
  canary and its forbidden conclusion, inherited verbatim by the population step; `G4`'s *absent ⇒
  `ACTIVE`* default; `G2`'s one-trip-per-session resolution, which is why the every-referencing-trip
  criterion is satisfied by a union rather than by a multi-trip write; and `G8`'s `trip.freshness`
  `(relation, verdict)` pairs with the rule that *no gate may be added that blocks on freshness*
- `examples/data-architecture-demo/` — the shipped fixture on which the answered-ness measurement,
  its known-zero specificity arm and the file-less-entry gap are all reproducible: two files under
  `travelers/` against three person entries in `outputs/traveler-model.md`, and profiles whose own
  prose states that a skipped label ships with an em dash the reconciler reads as *not answered*
- `scripts/test-command-taxonomy.sh` and `scripts/test-publish-guard.sh` — the measured occupancy of
  the result vocabulary this design needs: `MALFORMED` already a finding token for a row that does
  not parse to its expected shape, and the single `INHERITS` that is English prose in a comment
  rather than a status token
