# ADR-012: People library — cross-trip person identity, merge semantics, erasure reach, and reference discovery

- **Status:** Accepted (2026-09-03)
- **Deciders:** repo maintainer
- **Driving work:** the People library milestone. This record is the prerequisite architecture
  decision that milestone's first acceptance criterion requires, and it is the milestone-head
  decision gate for the spikes that feed it.
- **How this record was authored — the scaffold is now closed.** The milestone's design work was split
  across several spikes plus one ratifying record. Each spike contributed **one Context subsection**
  stating what it established, **as evidence**; those subsections are their authors' record and are
  not rewritten here. The ratifying record ran last, was the first artifact to see every spike's
  findings together, and wrote **Decision drivers**, **Options considered**, **Decision** and
  **Consequences**, and flipped the `Status:` line above to `Accepted`. **No *Not yet written* block
  remains.** Where ratification read a Context claim differently, the correction is stated in
  *Decision* § *Ratifier's notes* rather than written back over the subsection that made it. This
  two-step — a record landing `Proposed` and ratified by a later commit — is the one `ADR-006`,
  `ADR-007` and `ADR-010` already used, and `reference/adr/README.md` names it as the status
  lifecycle's entry state.

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

**One risk this spike could not discharge — subsequently closed in this milestone.** As written,
the *within-trip* half of the collision problem was unmitigated on the trip side: § 3.2 recorded that
the intake surface selected edit-over-create on a bare file-existence probe with no collision check,
so a second same-named traveler silently overwrote the first — *"in files the model itself describes
as carrying real personal detail."* The person store's own refusal predicate, above, covers the
**store** side only, and at ratification the trip-side half had no owner.

> **Superseded by what shipped.** The trip-side half did land in this milestone. The `profile` verb
> now computes § 3.2's key over the stems of `trips/<slug>/travelers/*.md` and halts on a key already
> held by a different person, running **before** the file-existence probe that used to decide alone.
> § 3.2's identity rule is unchanged; the section was extended to record the surface that enforces it.
> This paragraph is left standing because the risk it names was real at ratification, and the record
> of a risk being discharged is worth more than a risk quietly deleted.

### Erasure reach — what the erasure-reach spike established

*This subsection records the findings of the spike on how far erasure of a person record must reach,
**as evidence**. It states no decision. Where it reports that a mechanism "fails" or that a candidate
is "falsified", that is a measurement against shipped code and shipped prose — never a ratification of
whatever replaces it; ratification is the Decision section's, below. Two of the spike's own readings
were corrected after it ran, by siblings reading sources it had not. Each correction is carried **in
place** rather than appended, and named where it changed the reading.*

**Every artifact class below is named by path, never by its ordinal in `reference/data-architecture.md`
§ 1.1.** That enumeration is closed — § 1.1 bounds the in-model range and declares the out-of-model
classes — and its numbering
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

*Written by the ratifying record, over the three Context subsections above read together. Each driver
is a force that decided something below; a consideration that decided nothing is not listed.*

- **Apply the shipped identity rule; do not mint a second one.** The risk this milestone names is
  *inventing a second rule*, never *reaching a different answer than Traveler did*. § 3 is a procedure
  over entities that already splits its set five surrogate / five natural, so a different answer for an
  eleventh entity is the rule working rather than the rule being bypassed. Every identity question below
  is settled by running § 3. § 3.2's identity rule is left unchanged — the section was later extended
  to record the intake surface that now enforces it, which adds no rule and changes no answer.
- **A durable join key must not sit where an operator edits prose.** A key the operator retypes is a key
  a spelling correction re-identifies, orphaning every inbound reference. This is what separates a
  cross-trip Person from a trip-scoped Traveler, whose key the operator legitimately owns.
- **Records-minimization about a non-consenting person, as `ADR-006` reasoned it.** `ADR-006` rejected a
  proxy profile because it *"creates a durable identity artifact for a person who never asked for one"*
  and because *"fewer durable records about a non-consenting person is the better privacy posture."*
  That reasoning does not weaken at a wider scope — it strengthens — so it binds this record rather than
  being amended around.
- **No cross-trip pseudonym may survive a deletion.** Three findings arrived at this independently: the
  erasure work mints tombstone tokens per (person × trip); the discovery work rejects a back-reference
  list because it *survives erasure of the trip*; and the same work prohibits correlating tombstones
  across trips even to sharpen a diagnostic. A design decision that re-establishes that edge is refused
  here regardless of what it buys.
- **Keep the design machine-graded.** The `reference/schemas/` bijection is what makes the composition
  claims checkable rather than asserted. A disposition that moves the person record outside the corpus
  that grades it costs assertions this design depends on, and that cost outranks the elegance of the
  alternative.
- **Existing trips must not break, and the no-library case must not degrade.** A trip carrying no person
  reference has to behave byte-identically to today, and an unreadable store must not make a trip that
  references nothing worse off. Both are load-bearing on the reference field being **optional**.
- **Unknown, never the empty set.** An unresolvable reference read as *"no constraints"* turns erasure
  into a path to a compliant-looking unsafe plan. Every indeterminate branch below resolves to
  `UNDETERMINED`, inheriting the shipped fail-closed posture that *an empty read is not an empty class*.
- **Bound the blast radius of merge by construction, not by care.** Merge stays a single-field operation
  only while the person key is kept out of trip-internal joins. That is a constraint this record
  imposes, not an observation it reports.
- **State the exclusions.** Where a class is decided to have no record and no reference bearer, silence
  reads as coverage. Every exclusion below is written down with its ground and its cost.

## Options considered

*Consolidated at ratification. Options weighed inside a single spike are recorded as evidence in that
spike's Context subsection above and are not re-argued here; what follows is the set this record
decided over, each with the falsifier that removed it. **Cost is nowhere the dispositive falsifier** —
where cost is the only objection, it is named as a cost and the option survives to be weighed.*

| # | Option | Falsifier |
|---|---|---|
| **O1** | **Natural key for Person**, reusing the normalized display name § 3.2 already defines | § 3.2's own mandated collision remedy is that the operator disambiguates the display name, *"which changes the key."* A natural-keyed Person is therefore re-identified by an act the engine requires — **self-falsifying against the rule that would license it**. It additionally puts a durable join key under operator text editing |
| **O2** | **Store inside `trips/`** | Two independent falsifiers. `G2` derives `trips[]` as the lines of `E1` minus the `README.md` line, so a `trips/people/` directory becomes a phantom trip on every invocation of all five commands — a one-trip working directory resolves as `many`. And `.gitignore`'s own comment states the mechanism that forbids the signpost: *"git cannot re-include a file whose parent dir is excluded"* |
| **O3** | **Out-of-repo store** (`~/.travel-planner/people/` or `$XDG_DATA_HOME`) | The schema selector is computed from repo-relative `path-pattern:` globs, so an out-of-repo home is unreachable by the path arm: the class is unselectable and the bijection ungradable. It re-enters O5 by a different door. Every engine surface — the resolution contract, the publish guard, the schema gate — is repo-relative |
| **O4** | **Amend § 4.4 to let the person class *remove* `trip:`** | **Zero precedent.** Both declared narrowings re-type `writer` (`trip-context.md` to the `block-owned` sentinel, `outputs/satisfaction-metrics.md` to a section-owned list) and neither removes a field; `reference/schemas/traveler-profile.md` states the shipped reading in its own fence — *"a class may only narrow one."* It would also force a code change to the schema suite's universal-field group. **Superseded by the sentinel**, which needs neither |
| **O5** | **Out-of-model disposition** for the person record | Loses the `reference/schemas/` bijection, so the form recount and *the trip form carries zero `PERSON` fields* become ungradable, and the merge-stub shape needs a bespoke guard assertion. Measured by the identity spike: the out-of-model rows carry **zero** files in `reference/schemas/` |
| **O6** | **A new cross-trip band** whose schema lives outside `reference/schemas/` | Puts the schema outside the corpus that grades it: the band buys a selector arm and loses the assertion it was bought for |
| **O7** | **Reference borne on the derived model entry** (a mark on the `## <Name>` heading) | The derived model is `rebuilt-each-synthesis`, so the reference would have to survive regeneration. Worse, it places a **cross-trip identifier inside the artifact the erasure design works hardest to keep uncorrelated**. It would also give a file-less party member a bearer, which the exclusion below refuses |
| **O8** | **A roster reference in `trip-context.md` § *Group*** | Puts a durable cross-trip person identifier in a `publish: bound` artifact — the publish path — and adds a writer to a block-owned table for a fact that already has a home. A publish-surface risk created for no gain |
| **O9** | **A back-reference list of trips on the person record** | A durable plaintext list of the trips a person travelled on: the exact cross-trip linkage the tombstone design mints per (person × trip) tokens to destroy, and it **survives erasure of the trip**. Rejected on privacy, on one-source-per-fact, and on the archived write it forces — any one dispositive |
| **O10** | **An index or a persisted result cache in the store**, mapping person → trips | Staleness is **fatal and undetectable**: `trips/` is git-ignored and hand-edited, so a hand-deleted trip never updates it and nothing reveals the drift without running the forward scan anyway. **The idiom that would make it safe is the one that makes it pointless.** It fails silently, returning a plausible, wrong, non-empty set |
| **O11** | **A whole-directory scan or a content grep for the key** | Rejected on false positives before cost: a display name in an itinerary, or a key in a narrative or a receipt, is not a reference. *The person key is not a trip-internal join basis* is what makes that distinction crisp rather than heuristic |
| **O12** | **A third pre-execution evidence block** beside `E1`/`E2` for discovery | Refused by the contract's own text: `contract-depth` is an **equality, not a minimum**, so a third block would force **every** `G8` consumer to carry it and acquire a wider grant — editing a surface this milestone does not otherwise touch, for no gain |
| **O13** | **A person record for a `[THIRD-PARTY]` party member** | `ADR-006`'s Option 4 at a wider scope: a durable identity artifact for a person who never asked for one, now persisting past the trip and linking them across trips. Every ground `ADR-006` gave is stronger at cross-trip scope, not weaker |
| **O14** | **Reuse the person id as the erasure tombstone token** | Of the two rationales the erasure spike gave, **only the second survives, and it is dispositive**: a reused id is a **stable cross-trip pseudonym for someone who asked to be deleted**, outliving the record it named and disclosing that the same person travelled on those trips. The name-leak rationale is **struck** — under a surrogate the id carries no name — and is recorded as struck rather than quietly dropped |
| **O15** | **Substitute rather than remove the `person:` field on erasure** | Leaves a per-trip token in a **cross-trip-addressable** position, and defeats the structural tombstoned-versus-dangling discriminator, which keys on the field's *presence* |
| **O16** | **Erase an archived trip by `reopen` → erase → re-conclude**, rather than by declaring `lifecycle: ANY` | **The path runs; it is rejected for what it mutates, not for being refused.** `reopen` returns the trip to `ACTIVE`, which satisfies the concluding verb's own `lifecycle: ACTIVE` row, so the re-conclude step is admitted by the gate table. What disqualifies it is that the path **flips the lifecycle marker twice and appends a second closing entry to the log of an already-concluded trip** — mutating a trip's concluding record for an operation whose entire point is that it is a redaction. *(An earlier reading of this alternative had it refused at the gate. That sub-claim does not hold against the shipped table and is not carried forward; the erasure Context subsection above already corrects it in place.)* |
| **O17** | **Signal archived trips on a person edit and let the operator ignore it** | `G7`'s defaults make an archived trip refuse every verb that does not declare otherwise, so a signal written there instructs an engine that will refuse to act on it — noise unactionable without a reopen the operator did not ask for |
| **O18** | **Decide relevance by *presence* of a trip-side line** | Falsified by the shipped intake template, which mandates the opposite: *"Skipping a section never removes it from the output: every field still ships."* Presence discriminates nothing on a real profile, and the failure direction is the unsafe one — an em-dashed line reads as an override and the trip hears nothing about a durable fact it is actually planning on |
| **O19** | **Decide relevance by answered-ness alone, uniformly across all four field classes** | Measured false on the shipped fixtures: the `PERSON`-class bullets are present *and answered* trip-side today, so a uniform answered-ness predicate reads them as overrides and the safety class goes **silent** on a person edit. The lattice has to be **class-first**, with answered-ness consulted only where the class admits divergence |
| **O20** | **Match person display names against model entries** as a discovery fallback for a file-less entry | A name-similarity join — the mechanism § 3 forbids between naming and identity — and it resurrects the same-name collision the surrogate exists to prevent |
| **O21** | **Widen the person token beyond 4 hex digits** to shrink the collision space | Not falsified; **weighed and set aside.** It would make Person the only entity with a different token width, against a mint-assert-remint loop that is cheap at a store whose realistic size is tens of records. Recorded as a cost accepted, not an option refuted |

## Decision

**Accepted 2026-09-03 (Thursday).** Person is admitted as an eleventh entity with a cross-trip durable
record. What follows ratifies the three Context subsections above and settles the items each of them
left open. Where a spike's own reading needed correcting, the correction is stated here rather than
written back over their record — see *Ratifier's notes*, last.

**Every artifact class in this section is named by path, never by its ordinal in
`reference/data-architecture.md` § 1.1.** That enumeration is closed and its numbering moved
during this milestone; a path does not move.

### 1. Identity — a surrogate key, filename-borne

**Person takes the surrogate key `psn-[0-9a-f]{4}`, borne in the filename at `people/psn-<token>.md`
and never restated in frontmatter** (§ 4.3's no-double-home rule). **The display name is the body H1**,
and its normalized form — reusing § 3.2's existing normalization, not a new one — is what creation
refusal asserts over. Person is a distinct entity from Traveler: **Traveler's natural key, its filename
correspondence and its publish-guard normalization are byte-unchanged, and § 3.2's rule is not
changed. The section is reopened in this milestone only to record that its intake half now ships.**

Minting **asserts non-existence and re-mints on collision**; at four hex digits and a realistic store
of tens of records the re-mint loop is cheap, and widening the token is set aside per **O21**.

Three consequences this record states so no later reader reconstructs a misreading:

- **The rename criterion is a *prohibition*, not a natural-key mandate.** *A rename is a new id plus a
  supersession edge, never an in-place mutation of a join key* — under a surrogate, a rename touches a
  display-name **body value** only, and mutating a join key in place is **structurally unreachable**.
  The criterion is satisfied by construction rather than by a rule someone must follow.
- **The creation-collision criterion resolves against the *normalized display-name key*, never the
  surrogate.** Read against the surrogate it is vacuously true, because minted ids never collide, and
  its control evaporates. Refusal fires on **exact equality after § 3.2's normalization** against a live
  record — **never similarity, never edit distance, never fuzzy matching** — with three operator
  remedies: **link**, **disambiguate**, or **create anyway with the collision acknowledged**. The third
  branch exists because co-existence is safe when ids differ, which keeps a same-named couple
  representable. **No code path runs from a name comparison to a merge.**
- **`psn-` and `per-` are disjoint namespaces** — the person key and the erasure tombstone token. Any
  detector over either is **shape-anchored** `<prefix>-[0-9a-f]{4}`; a bare `per-` substring matches
  hundreds of English distributives (`per-traveler`, `per-trip`, `per-event`).

**Merge** is ratified as the identity spike established it: refuse → survivorship → **stub-first** →
lazy repoint of active trips only → signal only what was repointed. **Chain depth is pinned at exactly
1** by the refuse-if-either-id-is-already-a-stub rule; a second hop is typed `MALFORMED` and never
followed. Self-authored survives across differing provenance, forced by `ADR-006`'s consent boundary
rather than chosen; unequal field values **refuse** rather than resolve; an expired value loses to a
live one. **Merge takes no freeze exception**, because it re-addresses rather than rewrites. The stub
**is** the receipt, which is what makes unmerge a mechanical inverse and what moves an incorrect merge
from IRREVERSIBLE to MODERATE. **Split is out of scope**, with its reasoning recorded above.

**Reversibility: MODERATE · confidence HIGH.** Ids are minted, not derived; changing the scheme re-keys
the store.

### 2. Storage home — `people/` at the repo root, in-model, with the `trip:` sentinel

**The store is `people/`**, at the repo root, **contents git-ignored with a tracked
`people/README.md` signpost**, rooted in `.gitignore` as `/people/*` plus `!/people/README.md`. This is
the **third instance of a pattern this repo already ships twice** — `trips/*` + `!trips/README.md`, and
`/analysis/*` + `!/analysis/README.md`, whose own comment reads *"Same shape as trips/ above and for
the same reason."* Feasibility is not argued; it is demonstrated by two shipped precedents. `O2` and
`O3` are refused above.

**The person record is an in-model artifact class**, named `people/<person>.md`, **never numbered** —
the same angle-token shape § 1.1 already uses for `travelers/<traveler>.md`. Its schema file is
`reference/schemas/person-record.md`. In-model is taken because both alternatives cost the
machine-grading this design depends on (`O5`, `O6`).

**`trip: cross-trip` is RATIFIED as a narrowing, not a removal.** Both declared § 4.4 exceptions
re-type `writer` and neither removes a field, and `reference/schemas/traveler-profile.md` states the
shipped reading in its own fence: *"a class may only narrow one."* `cross-trip` type-checks as the
required `slug`, exactly as `trip-context.md` narrows `writer` to `block-owned` — a sentinel that *is
not a writer id and that no tool resolves to one*. **No § 4.4 removal-exception is created and the
schema suite's universal-field group is unchanged.**

**The sentinel is declared in `reference/data-architecture.md` § 4.4**, as a third narrowing beside the
existing two — **not** in `reference/data-model.md` § *Reserved keys*, whose own derivation rule scopes
that list to `##` headings the derived model's shape defines. This corrects the placement the
composition spike proposed; the sentinel itself is unchanged.

**The reservation is a forward obligation, not a repair.** No tracked file extracts the `trip:`
frontmatter **value**, so nothing resolves it to a directory today. It carries exactly one binding
consequence: **`/trip-new` must refuse a trip slug equal to a reserved sentinel**, or a real
`trips/cross-trip/` would collide with it.

**Reversibility: MODERATE · confidence HIGH.** Reversible on paper until records materialise in
operators' working directories; a relocation is a migration thereafter.

### 3. Referencing — one optional frontmatter field, on the traveller file alone

**`person: psn-<token>`, typed `optional slug`, on `travelers/<traveler>.md` and on no other class.**

**`optional` is forced, not stylistic.** That class is the one class the engine **never upgrades** —
version 0 is permanently valid for it — so a required field would make every existing traveller file
non-conforming the moment the schema ships, breaking both *existing trips do not break* and *the
mechanism is optional and progressive* in a single edit. **Absence is the pre-existing state of every
traveller file in existence.**

**Resolution has four branches, and only one is new behaviour:**

| Reference state | Resolution |
|---|---|
| **Absent** | The traveller file is self-contained. **No store read is attempted.** Behaviour is byte-identical to today |
| **Present, resolves** | Compose per *Decision* § 4 below. A `merged-into:` stub is followed to **depth 1**; a second hop is `MALFORMED` and never followed |
| **Present, does not resolve — `DANGLING`** | **`UNDETERMINED`.** Never `NOT-REFERENCING`, never *no constraints*. This inherits `G1`'s shipped canary rule verbatim rather than inventing a posture |
| **Store absent or unreadable** | **`UNDETERMINED` for every trip carrying a reference; a trip carrying none is unaffected.** The fail-safe must not degrade the no-library case |

**The person key is not a trip-internal join basis.** This is a binding constraint rather than a
description: it is what bounds merge to a single field in a single class, and what keeps discovery's
cheap stage a frontmatter read. A second in-trip join site re-derives both.

**Discovery is PULL ∪ PUSH, and correctness rides on PULL.** PULL — a trip resolving its own composed
source at its own next enrichment pass — **cannot miss a trip, because it is that trip's own read**.
PUSH shortens latency and is best-effort and fail-loud. *Every active referencing trip receives the
signal* is satisfied by the **union**; it must **not** be implemented as one session writing N trips,
which the one-trip-per-session bound forbids and which would write archived trips. **PULL's one
requirement, which this record depends on and does not own:** the per-trip diff must compare the
**composed** source — the traveller file **plus** the person record it references — not the trip file
alone.

**Erasure of the reference REMOVES the field; the derived model's entry heading is SUBSTITUTED.** Both
are erasure; the mechanism differs because the two locations have **opposite absence semantics**.
Removal is unsafe in the model — a stripped heading yields the empty key and hard-stops the reconciler
— and safe in the traveller file's frontmatter, because the field is optional and its absence is that
file's pre-existing normal state. The pairing is what makes the structural tombstoned-versus-dangling
discriminator work: **the trip still knows a person was erased**, while **no cross-trip identifier
survives anywhere** to correlate.

**Reach-set consequence.** This record adds **exactly one** location neither sibling set could name —
the `person:` field on each referencing `travelers/<traveler>.md` — and states its disposition
(removal). It adds **no** location for a file-less bearer, because *Decision* § 5 decides there is none.
`people/README.md` is **not** a reach location: it is a tracked signpost carrying no person data, and
that is a property the store's build must preserve.

**Reversibility: MODERATE · confidence HIGH**, except the erasure semantics, whose *effects* are
**IRREVERSIBLE · confidence HIGH**.

### 4. Composition — class-first, then answered-ness, and one-way

**The lattice is decided by field class first. Answered-ness is consulted only where the class admits
divergence, and it changes the verdict for exactly one class.**

| Changed field's class | Trip side | Verdict | What is emitted |
|---|---|---|---|
| **`PERSON`** | *not consulted* — the record is authoritative unconditionally | **`INHERITS`** | **Always signal.** An **answered** trip-side value is additionally reported as a **schema violation** |
| **`DEFAULT`** | **not answered** (absent, blank, em-dashed, or still bracketed) | **`INHERITS`** | **Signal** — the durable value is what this trip plans on |
| **`DEFAULT`** | **answered** | **`OVERRIDDEN`** | **No replanning signal**; **reported**, because a redundant override can silently become load-bearing when the record moves |
| **`TRIP`** / **`DEST`** | n/a | **`NOT-INHERITED`** | **No signal, no report** — the record is not their authoritative source |

**A trip-side `PERSON` value is a schema violation, not an override — REFUSE and REPORT.** Silent
precedence in either direction is exactly how the class collapses into `DEFAULT`. **Answered-ness does
not rescue this class**, and the reason is measured rather than argued: on the two shipped fixtures the
`PERSON`-class bullets are present *and answered* on the trip side **today**, because the intake form
has not yet been split. Under a presence predicate *or* a naive answered-ness predicate those bullets
read as overrides and the safety class goes **silent** on a person edit. **`DEFAULT` is the one class
the answered-ness predicate actually changes.**

**`PERSON` non-overridability is enforced by absence, not by a rule.** Once the intake form is split
the trip form carries no `PERSON` slots, so there is nothing to police and the class cannot collapse
via an override that has nowhere to live.

**`ANSWERED()` is an instance property; presence is a document property. They share the word *present*
and answer different questions, and this record does not collapse them.** *What the form asks* — the
labelled-field denominator, the four-class partition over it, and the starred-pass split — is keyed on
the **presence of a bullet in `templates/traveler-intake.template.md`**, correctly and unchangedly,
because a form asks a question by carrying its line. *Whether this traveller supplied a value* is keyed
on `ANSWERED()`. **Discovery and composition live wholly on the instance side.** The over-application
is measurable rather than hypothetical: applying the instance predicate to the document question scores
the blank intake form at zero answers, which would read as a form that asks no questions.

**Composition is ONE-WAY:**

> **A trip override never writes back to the person record.** Composition reads the record and writes
> the trip; it never writes the store. The sanctioned promotion of a trip value into the record is an
> **explicit, confirmed human act** through the command surface — never a side effect of composition,
> enrichment, or a synthesis pass.

**Unresolvable is always `UNKNOWN`, never an empty set.**

**Provenance is decided with no enum widening.** The record's artifact-level `provenance:` is **`human`**
— Layer-1 human input. **Self-authored versus operator-provided is entry- and field-scoped**, carried
by the existing inline `[OPERATOR-PROVIDED]` mark exactly as the derived model carries it today; it is
**not** a new frontmatter enum member, because § 4.4's `provenance:` key is artifact-scoped. Projection
into the derived model is unchanged **by identity, not by equivalence** — the same mark, in the same
place, read by the same guard limb. **The two marks stay orthogonal, and that is the seam *Decision* § 5 and § 6
turn on:** `[OPERATOR-PROVIDED]` answers *who supplied this*; `[THIRD-PARTY]` answers *whether the
person described spoke*. **The durable-storage bar attaches to `[THIRD-PARTY]`, never to
`[OPERATOR-PROVIDED]` alone.**

**Reversibility: CHEAP · confidence HIGH.**

### 5. The file-less reference-bearer — RESOLVED, and the exclusion is written down

**The population is two classes, not one, and the corpus separates them explicitly** — *"a profile not
filed yet, **and** a party member who will never file one."*

| Class | Marks | Decision |
|---|---|---|
| **A profile not filed yet** (the fixture's `Sam`) | `[OPERATOR-PROVIDED]` **alone** | **No reference bearer.** When the profile arrives it is a `travelers/<traveler>.md` file and bears `person:` normally |
| **A party member who will never file one** | `[OPERATOR-PROVIDED]` **and** `[THIRD-PARTY]` | **No reference bearer, and no person record.** Their durable record is the trip-scoped one *Decision* § 6 names |

**Neither file-less class bears a person reference, and neither receives a cross-trip person record.**
This is the branch that requires the exclusion to be **stated**, because silence here reads as coverage.

**The ground for the both-marks class is dispositive and is `ADR-006`'s own.** A cross-trip person
record for a `[THIRD-PARTY]` party member **is Option 4 at a wider scope** — a durable identity artifact
for a person who never asked for one, now persisting past the trip and linking them across trips. Every
ground `ADR-006` gave strengthens at cross-trip scope. Three siblings agree independently and without
citing `ADR-006` at all: tombstone tokens are minted per (person × trip) to destroy stable cross-trip
pseudonyms; a back-reference list is refused because it survives erasure of the trip; and correlating
tombstones across trips is prohibited even to sharpen a diagnostic. **A cross-trip record for a
non-consenting person is the linkage all three exist to prevent, granted by the front door.**

**The ground for the not-yet-filed class is weaker, and sufficient.** The library is opt-in and that
person has opted into nothing; creating a durable cross-trip record on another person's say-so, while
that person's own act is the thing being waited for, is authoring ahead of consent. **The remedy is the
profile, which is already what the branch is waiting for.**

**The cost is stated plainly rather than minimised.** A party member's needs are re-stated by the
operator on every trip. That is a real intake cost falling on the person least able to advocate for
themselves — the exact asymmetry this milestone set out to reduce. **It is not free and this record does
not pretend it is.** It is the cost `ADR-006` already accepted once, in terms: *"Refusing identity
capture means a party member's entry requirements are not determined unless they file their own
profile. This is the accepted cost of the opt-in boundary."* This record accepts the same cost at the
same boundary, one scope wider.

**Consequences, all of them favourable and each checkable:** discovery's bearer set is **complete as it
stands**; a party member is correctly `NOT-REFERENCING`, which is now a *true* answer rather than a
false negative; a person edit cannot reach a person who has no record to edit; the store's erasure reach
does not widen to a class that cannot consent to being in it; and the tolerant read gains a third
structural case, distinguished with **no store read** — a model entry with no source file and no
reference is **EXCLUDED-BY-DESIGN**, never DANGLING and never TOMBSTONED.

**Reversibility: EXPENSIVE · confidence HIGH.** This narrows the plain reading of the milestone's
promise that a party member who never authors a profile can still hold a durable record: it is
**satisfied on the trip-scoped reading** (*Decision* § 6) and **refused on the cross-trip one**. Reversing it would
require a consent mechanism `ADR-006` would admit, and `ADR-006` already measured and rejected the only
candidate — an unverifiable attestation — on reasoning that holds harder at this scope.

### 6. The `ADR-006` amendment

**Both halves are honoured. The consent boundary is preserved verbatim; the storage claim is amended
descriptively, in the direction the evidence supports rather than the one the milestone assumed.**

#### 6a. Needs-only consent boundary — PRESERVED, verbatim and unwidened

A `[THIRD-PARTY]` entry carries **needs and nothing else**: no passport, no origin, no lifecycle facets,
no documents line. **Identity capture stays REFUSED.** Nothing third-party-sourced is published, in
attributed **or** anonymized form. **The data class a party member carries does not widen by a single
field.** Consent language is unchanged and restated here: *provenance-marking records that a value is
second-hand; it does not establish consent and must never be written or described as though it does.*
**Carrying is not confirming.** Nothing in this amendment can be read as adding consent.

#### 6b. Storage claim — AMENDED, descriptively, and no capability is added

**The milestone proposed this amendment on the premise that `ADR-006`'s no-file claim is "a storage
consequence of a trip-scoped world, not a consent rule." That premise does not survive `ADR-006`'s own
Decision text**, which rejects a proxy profile because it *"creates a durable identity artifact for a
person who never asked for one"* and because *"fewer durable records about a non-consenting person is
the better privacy posture."* That is a records-minimization rule with a stated privacy rationale.
**The premise is superseded, not adjusted**, and it is recorded here as a rejected framing so it is not
re-proposed.

**The real ground is the opposite one, and it is a fact about shipped behaviour.** A durable record for
a `[THIRD-PARTY]` party member **already exists today, by design**: their `## <Name>` entry in that
trip's `outputs/traveler-model.md`, preserved **verbatim** across every regeneration by the
carry-forward rule, because that person has *"no source file by design"* and the model the engine last
wrote is *"the **only surviving record** of what the operator stated."* `ADR-006` rejected Option 4 on a
records-minimization comparison **while the Option 3 it accepted creates a durable record of its own**,
and `ADR-006` neither names that record nor gives it a way to be deleted.

**The amendment therefore says three things and adds no capability:**

1. **The record exists and is named** — the carried-forward `## <Name>` entry in that trip's
   `outputs/traveler-model.md`. It is a **record**, not a projection: the engine's own text says *"the
   derived model remains that entry's record rather than its authority."*
2. **Its bound is stated** — **trip-scoped**, resident only in the git-ignored working directory,
   non-publishable, and it **never enters the cross-trip person library**. It does not link that person
   across trips and acquires no identifier that could. *Decision* § 5 is what makes this bound true.
3. **It acquires a delete path** — the erasure verb reaches it by **substitution**, never by
   regeneration, because regeneration reproduces it verbatim by design.

**That change makes the consent posture strictly stronger than the one `ADR-006` accepted.** It does not
relax a reasoned consent rule; it stops an accepted decision resting on a comparison its own chosen
option partly defeats, and it gives the record it forgot a way to be deleted.

**Where the false claim actually lives — a citation correction this record makes rather than inherits.**
The absolute phrasing *"no durable artifact of any kind"* is **not in `ADR-006`.** Measured over the 109
tracked `.md`/`.sh`/`.yml`/`.html` files, it occurs **twice, in two files** — `agents/00-enrichment.md`
and `.claude/commands/trip-record.md` — and **both attribute it to `ADR-006`.** `agents/00-enrichment.md`
carries both halves of the contradiction fourteen lines apart: *"no durable artifact of any kind"*, and
then the carried-forward entry as *"the only surviving record."* **`ADR-006` is amended for the omission
that is genuinely its own** — an unnamed, undeletable durable record created by the option it accepted.
**The over-statement is those two surfaces' own** and is routed to their owning cards in *Consequences*;
this record does not edit them.

**Reversibility: EXPENSIVE · confidence HIGH.** This is a consent boundary on a live ADR. Reversing it
would remove a delete path from records about non-consenting people — a privacy regression with
stakeholder impact, not a rollback.

### 7. What this record does NOT decide

| Not decided here | Decided by |
|---|---|
| The person-record **body shape**, its field set, its schema file, and the store README | the schema-and-store slice |
| The **guard-suite boundary assertion** for the new `.gitignore` group and for the merge-stub shape | the guard-suite slice |
| The **composition implementation** and the tolerant read's third case | the composition slice |
| The **enrichment mechanism** — PUSH ∪ PULL, the composed-source diff, redundant-override normalization | the enrichment slice |
| The **publish-guard freshness walk**, and the § 5.6 fence row **coupled with** the evaluator widening | the publish-guard slice |
| The **two shipped intake forms** — the trip form and the durable form | the form-split slice |
| The **command surface**, including the promotion act and `/trip-new`'s sentinel-slug refusal | the command slice |
| The **archived-trip freeze rule** and its single erasure exception | the freeze slice |
| The **passport validity horizon** | the passport slice |
| **Extraction and migration** from existing traveller files | the migration slice |
| **Reconcile-on-link** | the reconcile slice |
| **Erasure** — its reach set, its receipt, and its typed confirmation | the erasure slice |
| The person record's **artifact-class ordinal** in § 1.1 | the schema-and-store slice, at its own commit |
| The **within-trip Traveler collision** — the intake surface selected edit-over-create on a bare file-existence probe | **UNOWNED at ratification; CLOSED in this milestone.** The `profile` verb now runs § 3.2's key check ahead of the existence probe and halts on a collision. Restated here because the record ratified it as out of scope |
| `trips/README.md`'s retention posture — *"No command deletes a trip folder"* — which the erasure verb falsifies | **UNOWNED in this milestone.** Named, not fixed |

### Ratifier's notes — Context claims corrected without editing their record

*The three Context subsections above are their authors' record and are not rewritten. Where this record
reads a claim differently, it says so here, plainly.*

- **The `PERSON`-bullet count in the reference-discovery subsection is understated.** That subsection
  reads *"all 8 `PERSON`-class bullets are present and answered on the trip side."* Re-measured on the
  same two fixtures with the star-decorated bullet form handled (`- ⭐ **Specific:**`, which an anchored
  `- **Label:**` pattern silently drops), the population is **10 `PERSON`-class bullets, of which 8 are
  answered and 2 are not** — the two `Passport: —` lines. **The subsection's conclusion is unaffected and
  in fact strengthens**: 8 of 10 answered is more than enough for a naive answered-ness predicate to read
  the safety class as overridden, which is exactly why *Decision* § 4 is class-first. The same instrument reproduces
  that subsection's other two counts on the same population — 107 labelled body bullets, 45 answered —
  so the divergence is in the `PERSON` subset alone, not in the instrument.
- **The erasure-reach subsection's gate correction is adopted as it stands.** Its parenthetical already
  records that the re-conclude step is *not* refused at the gate, because the concluding verb declares
  `lifecycle: ACTIVE` and a reopened trip satisfies it. **O16** above states the alternative's real
  disqualifier — the state it mutates — and no part of this record relies on a refusal that does not
  occur.
- **The erasure-reach subsection's id-reuse rejection stands on its second rationale only**, and this
  record carries it that way (**O14**): the name-leak rationale is **struck**, because the surrogate
  chosen in *Decision* § 1 carries no name; what remains and decides it is that a reused id is a stable cross-trip
  pseudonym for someone who asked to be deleted. **The outcome is unchanged. Do not revisit it.**

## Consequences

Final, for the decision above. **Classes are named by path, never by ordinal**, for the reason § 1.1's
mid-milestone renumbering already demonstrated.

### Blast radius — what changes, and who owns it

| Surface | Impact | Owner |
|---|---|---|
| `reference/adr/ADR-006-third-party-data-capture.md` | **Amended in place** per *Decision* § 6b — the consent decision is untouched, an unnamed durable record is named and bounded, and a delete path is attached. Recorded as an **amendment, not a supersession**: no decision reverses | **this record** |
| `reference/data-architecture.md` § 1 and the § 1.1 heading | **Two-sentence narrowing.** The *per-trip* qualifier moves off the class set and onto the per-trip rows, so a cross-trip class is not filed under a heading that denies it. Cheaper than a new band, and it preserves the `reference/schemas/` bijection a new band would break | schema-and-store slice |
| `reference/data-architecture.md` § 1.1 table | **One new row**: `people/<person>.md`, written by the person, `persist-mutable`, `provenance: human`, **`publish: internal-hard`** — not `internal`. It carries `Passport`, which § 5.6 already declares non-publishable in two other scopes, and `internal-hard` is the value § 5.1 reserves for a class whose values *"must not reach a rendered page in any form, including anonymized"* | schema-and-store slice |
| `reference/data-architecture.md` § 2 | **Eleventh entity row**: Person — surrogate `psn-<token>`; Person 1—N Traveler-reference; Person 0..1—1 Person via `merged-into:`, depth 1 | schema-and-store slice |
| `reference/data-architecture.md` § 3.4 | The assignment becomes **six surrogate / five natural**. **§ 3.2's rule is unchanged**; the section gains the intake-enforcement record | schema-and-store slice |
| `reference/data-architecture.md` § 4.4 | **A third declared narrowing**, beside the two existing `writer` narrowings: `trip:` narrowed to the reserved sentinel `cross-trip` | schema-and-store slice |
| `reference/schemas/person-record.md` (new) | The class schema, with the **two-root** `path-pattern:` shape the traveller class already ships — the store and its worked example. `person-id` is **absent by § 4.3**: it is the filename | schema-and-store slice |
| `reference/schemas/traveler-profile.md` | **One line**: `field person: optional slug`. `optional` is **forced** by § 7.6's never-upgrade rule, not chosen | schema-and-store / composition slices |
| `reference/schemas/README.md` | **Narrow** *"Every pattern is anchored at a trip root, and that is load-bearing"* to every **per-trip class's** pattern, and declare the store's two roots | schema-and-store / guard-suite slices |
| `.gitignore` | **+2 rooted lines**, mirroring `/analysis/*` exactly | schema-and-store / guard-suite slices |
| `scripts/test-publish-guard.sh` | **A new group** asserting those two lines, as the existing groups do for `trips/` and for `/analysis/` | guard-suite slice |
| **A tracked witness fixture** | Required, or an explicit no-witness declaration. **A new worked example carrying the store**, rather than reusing the existing data-architecture example — which would place a cross-trip record inside a trip root and re-teach the scoping this design breaks | schema-and-store slice |
| `scripts/publish-trip-site.sh` **and** `reference/data-architecture.md` § 5.6 | **COUPLED, and this is the highest-severity item here.** A `Passport` fence row for the person-record scope **and** a third artifact-scope constant in the evaluator must land **in the same change**. The evaluator holds exactly two artifact-scope literals today; § 5.6 states that a row naming any other pair *"is presently a code change"* and that **the guard aborts the publish as UNDETERMINED** rather than guarding less than it declares. **A fence row alone aborts every publish of every trip** | publish-guard slice |
| `.claude/commands/trip-new.md` | **Refuse a trip slug equal to a reserved sentinel** | command slice |
| `agents/00-enrichment.md` · `.claude/commands/trip-record.md` | **The absolute phrasing *"no durable artifact of any kind"* is false as written** and both surfaces attribute it to `ADR-006`, which does not say it. Each needs the same descriptive correction *Decision* § 6b makes: the entry has no *file*, and its durable record is the carried-forward model entry, trip-scoped and now deletable. **No shape or field changes** | enrichment slice · command slice |
| `trips/README.md` retention table | *"No command deletes a trip folder"* becomes false when the erasure verb ships, and the same table's *"Copy a profile forward"* contradicts one-source-per-fact | **UNOWNED — routed** |
| `outputs/traveler-model.md`, its schema, and the agents that consume it | **Unchanged.** No field added, no shape changed, projection unchanged by identity | — |
| `CLAUDE.md` § *Resolving a trip* | **Not touched.** No third evidence block, no new gate, and **no gate that blocks on freshness** — this design adds a relation and no gate | — |
| `trip-context.md` and its write-ownership table · `agents/06-validator.md` and the spokes | **Not touched** | — |

### What becomes true, and what becomes checkable

- **Existing trips are unaffected.** A traveller file with no `person:` field attempts no store read and
  behaves byte-identically to today. Adoption is per-traveller and progressive.
- **A merge is a single-field write in a single class**, and it stays that way only while the person key
  is kept out of trip-internal joins. That constraint is now stated rather than assumed.
- **The class partition becomes machine-graded** the moment both schemas exist — the trip form emitting
  zero `PERSON` bullets, and the person record's schema carrying them. That is why a **schema-bearing**
  home was load-bearing rather than incidental.
- **No cross-trip pseudonym survives a deletion.** The person record is the only cross-trip edge, and it
  is the thing being deleted; every other join the tombstone preserves is already trip-scoped.
- **No indeterminate branch returns an empty set.** Every one resolves to `UNDETERMINED`, and
  `UNDETERMINED` is never a pass.
- **The freeze gains no second exception.** Merge re-addresses rather than writes; an ordinary person
  edit does neither and qualifies for neither. Only erasure — which *removes* information — reaches an
  archived trip, and it substitutes rather than regenerates.

### Costs and residual risks, stated rather than minimised

- **A party member's needs are re-stated on every trip.** *Decision* § 5 accepts this explicitly. It falls on the
  person least able to advocate for themselves, and it is the cost `ADR-006` already accepted once at a
  narrower scope.
- **An archived trip's model is a frozen composition over a source that did not stay frozen**, and
  reading it you cannot tell. That is correct behaviour and it is invisible. It is detectable read-side
  with no new state and no write, by reporting an mtime relation — legal precisely because `G8` fixes
  freshness as reported `(relation, verdict)` pairs and **forbids a gate over them**.
- **The publish-guard coupling is a live trap** with the widest blast radius in this milestone: the
  wrong half landing alone breaks every publish of every trip, permanently, until the other half lands.
- **`[ERASED]` must never be added to the publish-contract fence.** Declaring it an entry selector would
  make the tombstone a non-publishable leak token in a `bound`, rendered artifact, and **every
  subsequent publish of that trip would abort, permanently.**
- **Every detector over `psn-` or `per-` must be shape-anchored** `<prefix>-[0-9a-f]{4}`. A bare `per-`
  matches hundreds of English distributives; a bare-substring detector is a silent false positive
  generator.
- **A store at realistic size has a non-trivial birthday-collision probability**, which is why minting
  asserts non-existence and re-mints rather than trusting the space.
- **`UNDETERMINED` is chosen over a synonym** for every fail-closed branch, because it is already the
  corpus's densest fail-closed token and already carries the rule this design needs.

### Reversibility summary

| Decision | Tier | Confidence |
|---|---|---|
| Identity — surrogate `psn-<token>`, filename-borne | **MODERATE** | HIGH |
| `trip: cross-trip` sentinel, declared as a § 4.4 narrowing | **CHEAP** | HIGH |
| Storage home `people/`, git-ignored, tracked signpost | **MODERATE** | HIGH |
| Artifact class in-model, named never numbered | **MODERATE** | HIGH |
| Reference `person:`, `optional slug`, traveller file alone | **MODERATE** | HIGH |
| Erasure removes the reference; the model heading is substituted | **IRREVERSIBLE** (its effects) | HIGH |
| Composition class-first and one-way; provenance with no enum widening | **CHEAP** | HIGH |
| File-less bearer excluded, for both file-less classes | **EXPENSIVE** | HIGH |
| `ADR-006` amendment | **EXPENSIVE** | HIGH |

## References

*Accumulating — each contributing card adds the sources its Context subsection relies on.*

- `reference/data-architecture.md` § 2 (the entity model this milestone extends) · § 3 (the identity
  rule, its two limbs, and the Event validation case) · § 3.2 (the Traveler natural key, its
  normalization, the same-name hard stop, and the unshipped intake half) · § 3.3 (the Venue
  surrogate, the measured divergence forcing it, and the opacity guarantee) · § 3.4 (the five/five
  assignment and the `Applies to` invariance) · § 4.1 (kebab-case keys) · § 4.3 (the no-double-home
  rule) · § 4.4 (universal frontmatter, the entry-scoped provenance marks, and the `researched`
  definition — *holds independent state*, *not a regenerable projection* — that forces substitution
  over regeneration) · § 1.1–1.2 (the enumeration's bounds, and the out-of-model dispositions the
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
