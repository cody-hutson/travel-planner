# ADR-014: Cross-trip consent for a party member — the mechanism space, and why the refusal closes rather than defers

- **Status:** Accepted (2026-09-07)
- **Deciders:** repo maintainer
- **Driving work:** the Person data lifecycle milestone. `ADR-012` § *Decision* § 5 excluded a party
  member from the cross-trip person store and named a condition under which that exclusion would
  reverse — *"a consent mechanism `ADR-006` would admit."* This record answers whether such a
  mechanism exists. It concludes that none does, and that none can, so the exclusion stops being a
  choice held open and becomes a boundary the architecture cannot cross.

## Context

### The question this record answers, and the one it does not re-open

`ADR-006` permits an organizer to record a party member's **needs** — a mobility limit, a dietary
constraint — through the operator-provided path, marked with its provenance, resident only in the
git-ignored working directory. **That permission is not re-opened here.** It stands exactly as
written, and this record adds no restriction to it.

What is open is narrower and sits one scope wider. `ADR-012` § *Decision* § 5 grants a party member's
durable record **trip-scoped** and refuses it **cross-trip**, and `ADR-006`'s own amendment of
2026-09-03 states the refusal in terms. Both records leave the same door ajar: reversal is possible
*if* a consent mechanism turns up that `ADR-006` would admit. Neither record enumerated the mechanism
space, so the exclusion has been carried as a preference awaiting a better idea.

The population is precise, and its precision is what makes the question hard. It is a person admitted
to a trip's `outputs/traveler-model.md` as a single `## <Name>` heading marked `[OPERATOR-PROVIDED]`
**and** `[THIRD-PARTY]` — whose needs the organizer supplied, who authors nothing, who has no source
file by design, and who does not know the record exists. Everyone else who holds a durable record in
this repository put themselves there.

### The consent question, stated in full

No tracked artifact stated this. Each limb is answered against shipped behaviour, and **the last two
limbs are the finding**.

| Limb | Answer |
|---|---|
| **Who consents** | The **party member**, not the organizer. `ADR-006` already fixes that distinction: *"Provenance-marking documents that a constraint is second-hand. It does not establish consent, and must not be described as though it does."* The organizer is the actor, never the consenting subject |
| **To what** | To the creation and indefinite retention of a **durable cross-trip identity artifact** — a record in the person store bearing a surrogate key whose whole function is to link that person across trips. Not to the needs themselves, which `ADR-006` already permits trip-scoped and non-publishable |
| **At what moment** | At **record creation**. For every person holding a record today, that moment is an act *they* performed — filling the person-intake template, or extraction over a profile they wrote. A party member performs no such act, so the moment would be one the **organizer** performs on their behalf, at a machine the subject is not at |
| **How it would be recorded** | **No mechanism exists.** The store carries no consent field and the record schema declares none. Any mechanism would be an organizer-authored attestation on the record — the shape `ADR-006` measured and rejected |
| **How it would be revoked** | **By the erasure verb — and this limb is where the question fails.** Erasure is total over its declared reach and follows a record into archived trips, but it is **organizer-initiated and id-addressed**: the organizer types the record's opaque key at a terminal. A person who never asked for the record does not know it exists, does not know its key, and has no channel to that machine. **The subject cannot exercise the revocation** |

A consent model whose recording surface does not exist, and whose withdrawal only a third party can
exercise, is not a consent model with a gap in it. It is the absence of one. Consent whose withdrawal
only another party can perform is not consent.

## Decision drivers

- **`ADR-006`'s objection attaches to the artifact, not to the attestation beside it.** The proxy
  profile was rejected *"notwithstanding its more explicit consent story"* — that is, despite carrying
  the best consent apparatus on offer. An objection to a thing is not discharged by improving the
  paperwork that authorises the thing.
- **`ADR-010` § 2 already measured what an attestation can mean on this architecture**, and reduced
  it to a floor of unforgeability and detectability. That ceiling was established for approvals. It
  applies unchanged to consent, and this record is the first to apply it there.
- **The exclusion must be *written down* to be correct.** `ADR-012` names the refusal branch as the
  posture under which discovery's declared bearer set is complete as it stands, *"and the exclusion
  must be written down, because silence here reads as coverage."* A refusal held as an unstated
  preference does not satisfy that.
- **The cost falls on the person least able to object**, and is accepted with that named rather than
  minimised.

## Options considered

**The objection, quoted rather than paraphrased.** From `reference/adr/ADR-006-third-party-data-capture.md`
§ *Decision* → *Constraints (a party member's needs) — CAPTURE PERMITTED, via Option 3*:

> **Option 4 (proxy profile) rejected**, notwithstanding its more explicit consent story. A proxy
> profile creates a **durable identity artifact for a person who never asked for one**, backed by an
> attestation the system cannot verify. Fewer durable records about a non-consenting person is the
> better privacy posture; an unverifiable consent claim records the appearance of consent rather than
> consent itself.

And from that record's amendment of 2026-09-03, which already extends the objection to this exact
scope:

> A cross-trip person record for a `[THIRD-PARTY]` party member is **Option 4 at a wider scope** — a
> durable identity artifact for a person who never asked for one, now linking them across trips — and
> every ground given for rejecting Option 4 is *stronger* at that scope, so it is refused, not
> permitted.

**Read the first clause carefully, because it decides the record.** *"Notwithstanding its more
explicit consent story"* means the proxy profile fell **despite** its consent apparatus. The objection
therefore attaches to the **output** — a durable identity artifact about a non-consenting person —
and not to the attestation standing next to it. Any mechanism whose output is that artifact fails the
objection **whatever consent apparatus it carries**. The rescuing class is empty by construction, not
by exhaustion.

The table below **is** the enumerated space; its extent is its own row set rather than a claim about
one.

| # | Mechanism | What it does | Verdict against the objection |
|---|---|---|---|
| **M1** | **Organizer attestation on the record** — Option 4 at cross-trip scope: a consent field recording *"I have this person's agreement"*, typed at creation | Produces the record; adds an unverifiable claim beside it | **REJECTED — identical to the measured candidate.** The output is the durable identity artifact, and the attestation is precisely what `ADR-006` names *"an unverifiable consent claim [that] records the appearance of consent rather than consent itself."* `ADR-010` § 2 supplies an independent ground: the organizer both signs and verifies, where unforgeability *"requires the verifier to hold strictly less than the signer"* |
| **M2** | **Direct consent by the subject** — the person fills the person-intake template themselves | Produces the record, consented at creation by the subject's own act | **ADMITTED — and already shipped.** This is the existing opt-in path and the store already holds records made this way. **It is not an extension.** It also does not reach the population in question, which is a party member *who never authors a profile*; this mechanism converts them into someone who did. The capability already exists for anyone who asks for it. What is refused is granting it to someone who did not |
| **M3** | **Deferred or countersigned consent** — mint the record quarantined and unusable, activating only when the subject countersigns | Defers the artifact's *use*, never its *existence* | **REJECTED on two independent grounds, either dispositive.** First, the durable artifact exists before any consent does, which is the objection itself, and quarantine does not un-create it. Second, **there is no channel**: `ADR-010` § 2's detectability floor rests on a published artifact the subject reads, and a party member's record is git-ignored and non-publishable under `ADR-006` Q3. The subject can observe nothing. Both floor properties fail |
| **M4** | **Pseudonymous cross-trip continuity** — carry the needs forward without a stable identity key | Attempts the capability while avoiding the artifact | **REJECTED as self-defeating.** Cross-trip continuity *is* the stable linkage; a key minted per trip provides none. Worse, `ADR-012` mints tombstone tokens per person-and-trip **precisely to destroy stable cross-trip pseudonyms**, and prohibits correlating them across trips even to sharpen a diagnostic. A stable cross-trip pseudonym is the artifact several shipped mechanisms exist to prevent |
| **M5** | **Organizer-mediated carry-forward** — at intake the organizer is offered the needs recorded for the same person on a prior trip, and re-states them; nothing durable is minted | Reduces intake cost without creating a record | **REJECTED on a structural impossibility, independent of consent.** The offer requires a cross-trip join key, and this class has no reference bearer at all — `ADR-012` types the file-less both-marks entry's reference as *"none exists"* and the bearer itself as *"a named gap."* The only remaining candidate key is the display name, which `ADR-012` forbids in terms: discovery *"must **not** fall back to matching person **display names** against model entries"* because *"it would resurrect the same-name collision the surrogate key exists to prevent."* There is no admissible key, so the mechanism cannot be built |

**Convergent narrowing.** M2 is admitted and is not an extension. M1, M3 and M4 each terminate in the
refused artifact. M5 cannot be constructed at all. **No surviving mechanism both grants a cross-trip
record to someone who never authored a profile and survives `ADR-006`'s objection.**

## Decision

> **REFUSE. A party member's durable record does not extend across trips. The cross-trip reading is
> closed permanently rather than deferred.**

Three grounds, each independently dispositive.

### 1. The revocation limb is unsatisfiable for this class, by construction

A durable record for a person who never asked for one has **no subject-initiated revocation path**.
The erasure verb is organizer-initiated and addressed by the record's opaque key; the subject does not
know the record exists, does not hold its key, and has no channel to the machine that would run the
verb. Every other durable record in this store is held by someone who created it and can ask for it to
go. Consent that only a third party can withdraw is not consent, and a mechanism cannot supply a limb
the architecture gives the subject no way to reach.

### 2. The mechanism space is empty for a structural reason, not for want of invention

`ADR-006` rejected the proxy profile *"notwithstanding its more explicit consent story."* The
objection therefore attaches to the artifact rather than to the attestation, and **no property of a
consent mechanism can discharge an objection to the thing the mechanism authorises.** The enumeration
above bears this out: every candidate either terminates in the refused artifact, or is already
shipped and is not an extension, or cannot be constructed for want of an admissible key.

This **corrects** `ADR-012` § *Decision* § 5, which reports that `ADR-006` *"already measured and
rejected the only candidate — an unverifiable attestation."* The space is larger than that sentence
allows. The conclusion is **stronger** once the space is enumerated rather than weaker: the space is
not merely exhausted, it is closed, because the objection is to the output and not to the apparatus.

### 3. `ADR-010`'s attestation ceiling applies to consent, and consent falls below it

`ADR-010` § 2 established that on this architecture *"No mechanism running there can be enforced
against its owner"*, and reduced the reachable floor to two properties:

- **Unforgeability** — *"the organizer cannot manufacture an approval that a traveler did not give.
  This requires the verifier to hold strictly less than the signer."*
- **Detectability** — *"a traveler can tell that a republish did not carry their approval, or carried
  approval for content other than what was published."*

A third-party consent attestation fails **both**. The organizer both signs and verifies it, so
unforgeability is unreachable by the record's own reasoning. And the subject has no channel on which
to detect a discrepancy, because the record is git-ignored and non-publishable by `ADR-006` Q3 — so
detectability has no surface to stand on. That ceiling was measured for approvals; this is its first
application to consent. It is what converts *"we choose not to"* into *"the architecture cannot mean
it."*

### Reversibility

**IRREVERSIBLE as a decision posture · confidence HIGH.** The distinction is deliberate.
`ADR-012` § *Decision* § 5 tiered its exclusion EXPENSIVE, reversible at cost and conditional on a
mechanism `ADR-006` would admit. This record changes the tier's **ground**: that condition cannot be
satisfied by any mechanism this architecture admits, so the exclusion stops being expensive-to-reverse
and becomes closed by construction. Reversal now requires **superseding `ADR-006`'s consent objection,
or revising `ADR-002`'s single-machine secret model** — supersession-path acts, not reversals of this
record. The corpus edits implementing the closure remain cheap to revert; it is the consent boundary
that does not move.

### The cost, stated plainly

A party member's needs are re-stated by the organizer on every trip. That is a real intake cost, and
it falls on the person least able to advocate for themselves — the exact asymmetry the person-library
work set out to reduce. **It is not free and this record does not pretend it is.** It is the cost
`ADR-006` already accepted once, at the same boundary, one scope narrower. What it buys is that the
person least able to consent does not acquire a cross-trip identity artifact they cannot ask to have
deleted.

## Consequences

**What this record changes:** the standing of the exclusion, and nothing else. No schema field, no
command verb, no agent prompt, no fixture and no executable surface changes. There is nothing to
guard, because the refused artifact has no creation path today, and the promotion verb already
refuses a `[THIRD-PARTY]` trip-side value on this same ground.

**What becomes true:**

- `ADR-012`'s discovery bearer set is **complete as it stands**, and the exclusion that makes it
  complete is now written down rather than implied. This is the branch `ADR-012` named as posture (2),
  under which *"the set is complete as it stands and the exclusion must be written down, because
  silence here reads as coverage."*
- A party member is correctly reported as non-referencing, which is a **true** answer rather than a
  false negative.
- The store's erasure reach does not widen to a class that cannot consent to being in it, and the
  declared reach accounting gains no location and loses none.
- The two erasure failure modes that already run in opposite directions for this class — an entry
  carried forward verbatim by regeneration, and an entry dropped by regeneration whose name re-enters
  from the roster — are **not multiplied across trips**, because no cross-trip record exists to
  multiply them.

**What remains a live cost, named rather than absorbed:** the per-trip re-statement above; and the
file-less entry's absent reference bearer, which `ADR-012` types as a named gap and which this record
does not close. Under the refusal that gap is no longer a coverage hole, because the class it would
serve holds no cross-trip record to discover.

**Residual, recorded so it is not rediscovered:** the retention posture in `trips/README.md` —
*"No command deletes a trip folder"* — is falsified by the shipped erasure verb, and `ADR-012` § 7
already marks that contradiction unowned. It is adjacent to this record's subject and is not fixed
here; it is tracked on its own card (#906).

## References

- `reference/adr/ADR-006-third-party-data-capture.md` § *Decision* → *Constraints (a party member's
  needs) — CAPTURE PERMITTED, via Option 3* — the objection quoted above, its
  *"notwithstanding its more explicit consent story"* clause on which this record turns, the
  provenance-versus-consent distinction, the Q3 non-publishability that removes detectability's
  surface, and the amendment of 2026-09-03 already refusing promotion to a cross-trip record
- `reference/adr/ADR-010-per-traveler-approval-collection.md` § 2 — the attestation ceiling, its
  *"No mechanism running there can be enforced against its owner"* premise, and the unforgeability
  and detectability floor this record applies to consent for the first time. **Cited, not amended:**
  applying a record's ceiling to a new question uses that record rather than changing it
- `reference/adr/ADR-012-people-library.md` § *Decision* § 5 — the exclusion this record closes, the
  reversal condition it left open, the *"only candidate"* sentence corrected here, the file-less
  bearer typed as *"none exists"* and *"a named gap"*, the display-name join forbidden as the
  tempting fix, and posture (2)'s requirement that the exclusion be written down
- `reference/adr/ADR-002-living-site-refresh.md` — the single-machine secret model whose revision is
  one of the two supersession-path acts a reversal of this record would require
- `reference/adr/README.md` — the section spine this record follows, and the decision-versus-amendment
  boundary that makes this output a new record rather than an in-place edit
- `.claude/commands/trip-record.md` — the erasure verb's organizer-initiated, key-addressed interface
  on which the revocation limb fails, its declared reach and the residues it names as out of reach,
  and the promotion verb that already refuses a `[THIRD-PARTY]` trip-side value
- `agents/00-enrichment.md` — the carry-forward rule whose predicate is **both** marks, which is what
  makes the trip-scoped entry durable and what gives this class its two opposed erasure failure modes
- Card #820 — the question this record answers. Epic #527 — the capability statement whose
  cross-trip reading this record closes, reconciled in the same change
