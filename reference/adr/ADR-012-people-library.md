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
