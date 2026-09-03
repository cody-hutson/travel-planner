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
  rule) · § 4.4 (universal frontmatter and the entry-scoped provenance marks)
- `reference/data-model.md` — the *link, don't copy — one source per fact* rule that merge's
  absorb-and-stub sequence preserves, and the definition of a need as a constraint bounding the
  solution, which is why unequal field values refuse rather than resolve
- `reference/adr/ADR-006-third-party-data-capture.md` — the consent boundary that forces
  self-authored survivorship across a cross-provenance merge, rather than leaving it to the operator
- `reference/adr/ADR-009-data-architecture.md` — the record authoritative over the model this
  milestone extends
- `reference/adr/README.md` — the section spine, the `Proposed` → `Accepted` lifecycle this record is
  mid-way through, and the amendment-versus-supersession boundary
