# ADR-029: Group approval — the inbound return as an operator-mediated crossing, approvals the organizer records against a declared threshold, and one decision of ADR-003 superseded in part

- **Status:** Proposed (2026-09-26)
- **Deciders:** repo maintainer
- **Driving work:** #718, the head design gate of the *Group approval engagement layer* milestone
  (#34), under the group-approval epic (#1297). The collection build that conforms to this record
  is #719, in the same release.
- **What this record is.** It decides the approval questions `ADR-026` and `ADR-025` left open —
  the inbound approval return `ADR-026` records as V-2, what a traveller does to approve, how an
  approval is tied to a traveller on the build host, and what may leave the build for a
  third-party surface — and it supersedes in part the gate rule of `ADR-003` § *Decision 2*,
  codifying the form `ADR-010` § 8 names as missing.
- **What this record is not.** It builds nothing: no script, verb, schema, render or skill changes
  here. It admits no channel, widens nothing — `internal-hard`, `ADR-006` and `ADR-014` stand
  unwidened — re-decides nothing `ADR-025` or `ADR-026` decided, and proposes no standing server
  (`ADR-002` upheld).
- **The status flip is named here, and so is what grades it.** Moving this record from `Proposed`
  to `Accepted` is the maintainer's, at this milestone's close. It moves both halves of a
  two-artifact state — this `Status:` line and this record's cell in `reference/adr/README.md` —
  and group `IX` of `scripts/test-adr-conformance.sh` compares them on every push, advisory rather
  than required. Until the flip, Accepted records cite a record that reads `Proposed`: the dated
  amendments this record's own change adds to `ADR-026` § *Decision* 2 and to `ADR-010` §§ 7–8 do
  so from the start, and `ADR-003`'s `Status:` line joins them when #719 ships the replacement
  rule. The suite's `LG` group reports each such citation as a status-lag candidate — it reports
  and never fails — and every one of them clears at the flip.

## Context

**The boundary, re-derived against the live records.** Read at `8b2ac05`, `ADR-026`
§ *Decision* 2 carries V-1 as *"DISCHARGED — it crosses on CH-1"* and V-2 as *"VACANCY. L2
UNDETERMINED … This is #718's work"*. `ADR-025` § *Decision* 4 fixes the render: *"At the render
boundary there is no join key, none may be minted, and that is permanent"*, and *"the only
admissible signal is an aggregate count paired with a content digest"*. `ADR-025` § *Decision* 1
makes `engagement(t)` `G8`-class — *"no gate may be added that blocks on it"*. `ADR-010`
§§ 1–5 are settled: transport not server, the attestation ceiling, the backend rejected on merit,
`internal-hard` binding attribution, and the `extend-seam` band. `ADR-010` § 7 leaves its
Candidates C and D unchosen, and § 8 names the partial-supersession form as missing. This record
decides only what those records left open.

**The seam this record specifies against, read live** in `scripts/publish-trip-site.sh` and cited
by function:

- `change_confirmation_state` (SEAM S2) emits one of five tokens — `none-pending`,
  `undetermined`, `unconfirmed`, `stale`, `confirmed`. Its banner says a replacement *"must emit
  `undetermined` whenever it cannot identify the outgoing render's itinerary content"*.
- `require_change_confirmation` (SEAM S3) proceeds on `none-pending|confirmed`, aborts on
  `undetermined` with a message of its own, and aborts on everything else through its `*)` arm.
- `cmd_confirm` is terminal-only with no override flag — *"no automation can attest a group's
  consensus on the group's behalf"*. It writes `.change-confirmed`, carrying `digest=` and
  `confirmed=`.
- `_digest_of` is the digest primitive, and its comment states the trade in full: *"cksum is
  CRC-32 — it detects change, it does not resist forgery"*, and *"Should #719 (ADR-010's successor
  to #88) later collect attributable per-traveler approvals, forgery resistance becomes real and
  the swap is this one function body."*
- `skills/trip/SKILL.md` § *site* reads `.change-confirmed` as *"the organizer's recorded
  approval"*, to decide the `coordination-state` its build writes and to date the `updated`
  state's decay.
- The erase reach table in `skills/trip-record/SKILL.md` lists `.change-confirmed` among its
  row-20 control files, *"declared to hold no person data"*.

**Why the candidate designs recorded on #708 are re-read and not adopted.** Four of their
premises have moved since they were written:

- **the paths** — the commands they cite moved from `.claude/commands/` to
  `skills/<verb>/SKILL.md`;
- **the vocabulary** — the gate's tokens went from four to five, and any replacement body owes
  `undetermined` (`ADR-010` § 5's amendment);
- **the binding** — #708's Candidate C keeps the CRC-32 token and signs it. A signature over a
  CRC-32 token binds nothing against an author who can choose the content, because a CRC
  collision with a chosen edit is constructible;
- **key custody** — #708's Candidate C keeps an **extractable** private key in script-writable
  browser storage, read and used by page script, on the ground that the page is the only script.
  The page is organizer-authored, and the organizer is the party the unforgeability limb exists
  to stop.

**The binding corollary.** The mechanism choice turns on one piece of reasoning, stated here once
and cited everywhere else in this record.

> **Corollary (of `ADR-010` §§ 2 and 4) — the binding.** An approval is tied to a traveller only
> through an identity binding: a key, an address, an account. Every binding the engine reads
> reaches the build host by the organizer's hand — an enrolled key, an email address and a passkey
> credential alike — and `ADR-010` § 4 keeps every binding off the render, which `ADR-025` § 4
> makes permanent. So the engine's approval **record** is organizer-attested as to *whose*
> approval it counts, whatever the mechanism: `ADR-010` § 2's ceiling, applied to the record.
>
> Unforgeability of the approval **token** stays reachable, as `ADR-010` § 2 says. It needs a
> traveller-held key in a tool the traveller controls, its public half published by the traveller
> under the messaging service's attribution. What it buys is evidence portability, not
> detectability: the verifier a traveller can trust is then the shared thread, and the thread
> already carries the same evidence without a key. Candidate C as specified on #708 does not reach
> even token-level unforgeability, because its key is enrolled through the organizer and held and
> exercised by organizer-authored page script.
>
> What every candidate delivers is **detectability**:
>
> - **by count** — a traveller who did not approve sees a count that says they did;
> - **by content** — an approver compares what they approved with what was published, and a
>   collision-resistant code anchors that comparison;
> - **by a record outside the engine** — the group's shared thread, where each reply is attributed
>   by the messaging service's accounts, which the organizer cannot author on another member's
>   behalf.

**One route out of the binding exists, and it is not proposed.** A transparency log, or a key
directory run by a party other than the organizer, would let the binding itself be checked without
the organizer's word. It is a standing third-party service — the question `ADR-002` and `ADR-010`
§ 3 answer — and not this record's.

**Domain practice, sourced.** Paraphrased from the sources named; their addresses are recorded
with this record's design, on #718's solutioning sub-task (#1507).

- **Browser-held keys are fragile, and usable by page script.** WebKit deletes all of a site's
  script-writable storage after seven days of Safari use without interaction with that site
  (WebKit blog, 2020-03-24). A non-extractable `CryptoKey` blocks export and not use (MDN,
  *CryptoKey: extractable*). Every project site under one GitHub account shares that account's
  `github.io` origin (GitHub community discussion). WebAuthn shows a generic prompt and never the
  signed challenge, so a traveller cannot see what a page asks them to sign (the W3C WebAuthn
  transaction-confirmation proposal, and the WebAuthn issue proposing removal of the
  unimplemented transaction extensions).
- **Messaging services see metadata.** WhatsApp's privacy policy lists automatically collected
  usage, connection and group information beside its end-to-end-encrypted content. Signal states
  it can produce only registration and last-connection dates. SMS content is visible to carriers.
  End-to-end-encrypted RCS between iPhone and Android entered beta in 2026-05, with metadata still
  collected (EFF). iMessage, WhatsApp and Signal build link previews on the sender's device
  (mysk, 2020-10-25).

## Decision drivers

- **Decide only the open column.** `ADR-026`, `ADR-025` and `ADR-010` §§ 1–5 are Accepted and are
  cited, not restated or re-opened.
- **Buildable in this release.** #719 is built against this record on the same branch, so every
  decision states a property a test can observe.
- **Honest ceiling over apparent guarantee.** A mechanism sold as unforgeable that is
  organizer-attested in substance is worse than one that says what it is. `ADR-010` § 2 calls the
  difference between *"the organizer cannot"* and *"the organizer would be caught"* *"the whole
  honest content of the feature"*.
- **Low ceremony is a constraint** — `ADR-003`'s driver, restated in `ADR-010`.
- **Fail-safe defaults.** Allowlists over denylists; a malformed record never reads as approval;
  nothing new on the render beyond a count and a code.
- **Reuse before create.** The S2 body, the `_digest_of` seam, `cmd_confirm`, the Coordination
  Notice, the per-class field pattern of `reference/schemas/travel-site.md` and the sidecar
  pattern already exist.
- **No new standing infrastructure** — `ADR-002`, and `ADR-010`'s *"Add no standing
  infrastructure"*.
- **Measure a name before minting it** — `ADR-025` § 7 and `ADR-026` § 6 — which is why the
  ledger's provenance token is `organizer-stated` and not `operator-stated`.

## Options considered

Each option set below was generated divergently — at least three candidates, and at least two
altitude bands wherever a new mechanism enters — then narrowed on hard constraints, each
elimination carrying a one-line kill reason, and the survivors scored on reversibility,
confidence, blast radius and upstream compatibility.

### O-1 — V-2: which transport carries the return, and is it a channel?

**Generation — the transports reachable from a local build with no standing server:**

| # | Transport | Mechanism | Altitude |
|---|---|---|---|
| T1 | The group's shared thread — a group chat or a group text | a traveller replies with the approval line where the group already talks | extend-seam — it names `ADR-003`'s *"their own channel"* |
| T2 | A direct message or text to the organizer | the same, one-to-one | extend-seam |
| T3 | An email reply, provider-signed (DKIM), verified at recording | the engine checks the sender's provider signature | new-abstraction |
| T4 | Voice, or in person | the organizer hears it | human, no artifact |
| T5 | A messaging-platform API or bot polling the thread | the build host reads the thread | new-abstraction, plus standing infrastructure |
| T6 | A traveller-writeable hosted form or issue tracker | travellers post approvals to a third-party store | new-abstraction |
| T7 | The published site posts the approval | a backend | `ADR-010`'s Option A |

**Elimination:**

| # | Verdict | Kill reason |
|---|---|---|
| T5 | eliminated | standing infrastructure — an account, a token, a long-running poller — against `ADR-010`'s *"Add no standing infrastructure"*; it also ingests the whole thread, third-party messages included (`ADR-006`) |
| T6 | eliminated | a trip-keyed, traveller-keyed record held at a third party — the exposure class of `ADR-010`'s Option B; on a public trip repository, participation becomes public (`ADR-003` § 4) |
| T7 | eliminated | `ADR-010` § 3: a backend is rejected on merit, and a re-proposal *"requires defeating this argument, not out-budgeting it"* |
| T4 | survives as a fallback only | the engine is transport-blind, so nothing can be designed against it |

**Matrix:**

| | Reversibility | Confidence | Blast radius | Upstream compatibility | Detectability it adds | Observer exposure |
|---|---|---|---|---|---|---|
| **T1 shared thread** ← recommended | CHEAP | HIGH | none in the engine | `ADR-003` § 2's own channel, named | every member sees every reply, attributed by the service; the published count is reconcilable against a record the organizer cannot author for another member | the service's metadata (membership, timing); content per the service's encryption |
| T2 direct message | CHEAP | HIGH | none in the engine | the same | count only — the organizer alone sees the replies | the same metadata; one-to-one replies carrying one code are linkable at the service |
| T3 DKIM-verified email | MODERATE — a MIME and DKIM verifier, and a DNS dependency, in a bash-and-markdown repository | LOW that it adds anything | structural | a build-host lookup, not a page fetch, so `ADR-002` § 2 is not engaged | none beyond T2: the address-to-traveller binding is organizer-registered (the corollary) | email providers see headers and any quoted change summary |

**Applying `ADR-026` § 1 to T1:**

- **L1** holds — a traveller is on the far side.
- **L2** does not hold for the traveller-side leg — no engine-side act governs a message crossing
  the service. The only engine-side act is the organizer's recording act, and its far side is the
  operator: that is CH-3.
- **L3** does not hold for that leg — there is no single point where the engine evaluates a
  predicate before a reply crosses.
- **Verdict:** not a channel. V-2 resolves as an **operator-mediated crossing that enters the
  engine on CH-3** — the classification `ADR-026` § 1 already gives *"their own channel"*.

`ADR-026` § 2's admission conditions are therefore not engaged, and no fourth member is admitted.
Even Candidate C would not honestly admit a CH-4: the engine can establish only that a token
verifies against a key whose binding to a traveller the organizer entered, not that a traveller is
on the far side (the corollary). For the verdict itself — admit V-2 as a channel, or record it as
an operator-mediated crossing — only the second survives the limbs, so the verdict is a forced
approach rather than a choice. For the transport, T1 is chosen on the matrix, and T2 and T4 remain
admissible, because the recording act cannot tell transports apart.

### O-2 — The mechanism, the maintainer's choice under `ADR-010` § 7

**Generation** — a new mechanism enters, so the altitude-band rule applies, and three bands are
present:

| # | Candidate | One-line mechanism | Altitude |
|---|---|---|---|
| M-C | `ADR-010`'s Candidate C, as specified on #708 | a browser-held ECDSA key; a signed token pasted back; a local `.mjs` verifier | new-abstraction |
| M-Cp | C with synced passkeys | a WebAuthn assertion whose challenge is the digest; the platform syncs the credential | new-abstraction |
| M-E | A provider-attested reply | a DKIM-verified email carries the approval | new-abstraction |
| M-D | `ADR-010`'s Candidate D, as specified on #708 | a keyless roster; the organizer records; `cksum`-bound; four tokens | extend-seam |
| **M-D+** | D, repaired and refined | organizer-stated records bound to a SHA-256 digest; a closed grammar; a name-free count and code on the render; a default population equal to the shipped gate; reconcilable against the thread | extend-seam |
| M-H | A count-only ledger | the organizer records a count, with no approver keys | extend-seam |
| M-0 | Null | keep the organizer-confirm gate, and record V-2 only | no change |

**Elimination:**

| # | Verdict | Kill reason — the hard constraint breached |
|---|---|---|
| M-0 | eliminated | governance conformance: the operator's decision to build the collection in this release, and the approved Release Outcome Statement, require a threshold-counting gate built in this release |
| M-H | eliminated | governance conformance: the Outcome Statement names *"an approval the organizer enters on a traveller's behalf"*, which a keyless count cannot express; it also has no de-duplication |
| M-D, as specified | eliminated | governance conformance: its resolver has four tokens and no `undetermined` arm, which the S2 contract now owes (`ADR-010` § 5's amendment); its binding is CRC-32. Its repaired form is M-D+ |
| M-C, M-Cp, M-E | survive to the matrix | no hard-constraint breach. The corollary is a finding the maintainer weighs, so it is scored rather than used to kill |

**Matrix:**

| | Reversibility | Confidence it delivers what it claims | Blast radius, in #719 | Upstream compatibility |
|---|---|---|---|---|
| M-C | **EXPENSIVE** — see the rollback statements below | **LOW** as specified on #708: its key is enrolled through the organizer and held and exercised by organizer-authored page script, so it does not reach even token-level unforgeability (the corollary); it signs a CRC-32 token; and WebKit's seven-day cap deletes script-writable storage, so re-enrolment churn is expected | structural — the repository's first asymmetric-cryptography surface (none exists outside `ADR-010`'s own quoted list, probed at `8b2ac05`), an `.mjs` verifier, browser code in the render, new subcommands and taxonomy rows | `ADR-002` upheld; `ADR-010` § 4 honoured, which is exactly why the binding cannot be checked at the render |
| M-Cp | **EXPENSIVE** — credentials registered at the organizer's origin persist in travellers' password managers | **LOW**: WebAuthn signs whatever challenge the page supplies behind a generic prompt, and the credential is registered through the organizer's page (the corollary) | structural — WebAuthn in the decrypted page, COSE and DER parsing | as M-C; custody moves to the platform vendor |
| M-E | MODERATE | **LOW** — the address binding is organizer-registered (the corollary) | structural | adds a network dependency to a local-only act |
| **M-D+** ← recommended | CHEAP to MODERATE — see below | **HIGH** on what it claims: it claims detectability only, and says so | behavioural to structural — the S2 body, the `_digest_of` body, `cmd_confirm` extended, a declaration surface, the count and code on the render, an erase row | extend-seam at S2 and at the Coordination Notice (`ADR-010` § 5); W-rule-conformant; `ADR-025` § 4-conformant; `ADR-007` § 2-conformant |

**Rollback statements.**

- **M-C — EXPENSIVE.** Once a traveller enrols, the key lives in script-writable storage on the
  organizer's shared `github.io` origin. No act of the engine or the organizer can recall it.
  Withdrawing the feature orphans the keys, and they stay usable by any page later published at
  that origin. Re-adopting means re-enrolling everyone. **Rollback infeasibility:** traveller-held
  key material lies outside every surface the engine can reach.
- **M-D+ — CHEAP to MODERATE.** Revert the build and this record. The sidecars on the organizer's
  machine are git-ignored and inert. Travellers hold nothing but their own thread messages. The
  one-way elements are this record's number, which is spent once published and whose revert
  leaves a declared-gap row, and the baselines re-anchored to SHA-256 after the digest swap: a
  revert of #719's build compares them against CRC-32 tokens, so the first `update` after a revert
  reads each such plan as moved until it is confirmed. That fails closed.

**Opposing view — the strongest losing candidate.** M-C raises the forger's cost from typing to
tampering: to forge, the organizer must substitute a key at enrolment or alter the page. M-D+ does
not do that. Repaired so that the key sits in a tool the traveller controls, with its public half
published by the traveller in the thread, C would reach token-level unforgeability — the property
`ADR-010` § 2 records as reachable. It still loses. The increment is bought at EXPENSIVE
reversibility, a first cryptographic surface and churn-prone key custody, and it changes nothing a
traveller can detect: the thread already carries the same evidence, and the engine's record of
whose approval it counts stays organizer-attested either way (the corollary).

### O-3 — What a traveller does

| # | Candidate | Verdict |
|---|---|---|
| I-1 | Reply with the approval line, copied from the organizer's post: `approve <code>` | **← recommended.** Self-describing and bound to a version, so it is auditable in the thread |
| I-2 | Tap a link that records the approval | eliminated — it needs a backend (`ADR-010` § 3) |
| I-3 | Reply with a short code only | survives; loses — the verdict is ambiguous, and a short code weakens the binding |
| I-4 | An emoji reaction | survives as a human signal the organizer may record; not the designed interaction — not self-describing across services, and not bound to a version |
| I-5 | Produce a signed token in the browser | follows M-C; not chosen |
| I-6 | A free-text "yes" | as I-4 |

Withdrawal is needed rather than optional. `ADR-007` § 2 forbids any command to overwrite or
delete existing trip content, so the only way a mistaken approval can re-open the gate is an
appended counter-record — `withdraw <code>`. Silence and refusal are the same state to the gate:
the plan holds.

### O-4 — Attribution, the local half

**The approver population:**

| # | Candidate | Verdict | Kill reason |
|---|---|---|---|
| P-1 | Every roster member, derived | eliminated | the denominator changes whenever the roster changes, and it is ill-defined under each of #1491's readings of roster standing |
| P-2 | Roster members at or above `SELF-STATED` | eliminated | `ADR-025` § 1 — *"no gate may be added that blocks on it"*; a gate whose denominator is a function of `engagement(t)` blocks on it |
| **P-3** | **An operator-declared subset of the roster, plus a threshold of `all` or an integer from 1 to n** | **← recommended** | — |
| P-4 | A declared integer only, with no keys | eliminated | this is M-H |

**The kinds.** A reading carried into this milestone held that K1 and K2 could approve
unforgeably, by `ADR-026` § 4. The live read corrects it. `ADR-026` § 4 makes K1 and K2 the only
kinds whose own statement can cross into the engine at all — on CH-2, directly — so that reading
is an upper bound, and under this record it is not attained: every record is the organizer's
statement, and the binding that tells the engine whose approval a record counts is
organizer-registered whatever the mechanism (the corollary). All five kinds therefore count
identically — one organizer-stated approval each, when declared — because the engine cannot tell
any kind's approval from the organizer's word, and it must not render a distinction it cannot
observe (the W-rule).

**The binding.** At recording, the organizer names a declared approver. The ledger key is that
approver's canonical traveller key, under the normalization `reference/data-architecture.md`
§ 3.2 fixes. It is local only and never emitted.

### O-5 — The digest an approval binds

| # | Candidate | Verdict | Reason |
|---|---|---|---|
| B-1 | Keep CRC-32 plus length — `_digest_of` as shipped | eliminated | governance conformance with the seam's own stated trade — *"it detects change, it does not resist forgery"* — once an approval binds to it; a traveller-side anchor that a chosen edit can collide proves nothing |
| B-2 | SHA-256, truncated for human comparison | survives; loses | a truncation floor is a threshold needing its own grounding, and it is unnecessary when the line is pasted rather than read |
| **B-3** | **SHA-256, carried in full as 64 lowercase hex characters, through the existing `_digest_of` seam** | **← recommended** | one function and one value for the gate, the carried code and the render |
| B-4 | A second, approval-only digest beside the CRC baseline | survives; loses | two digests of one projection would give the change being approved a second home — the double-home failure #708's own design named |

### O-6 — The privacy bound

| # | Candidate | Verdict | Reason |
|---|---|---|---|
| R-1 | A prose bound | eliminated | `ADR-026` § 5 — *"A channel with no stated test is unenforced regardless of the rule"*; the bound must carry an observable test |
| R-2 | A denylist: names, needs and URLs refused | survives; loses | it opens on omission |
| **R-3** | **An allowlist grammar — the line is exactly `approve` or `withdraw`, one space, and 64 lowercase hex — with must-refuse and must-accept arms** | **← recommended** | it closes on omission: the alphabet cannot express a name, a need, a URL or any value of the `ADR-008` class, which is the fail-safe-defaults principle |
| R-4 | Move the change summary onto the encrypted site, so nothing plan-bearing enters the thread | eliminated | `outputs/change-summary.md` is `publish: internal` — never rendered — so rendering it is a class change outside this record, and it contends with #1296's surface contract |

### O-7 — Superseding one decision of `ADR-003`

| # | Candidate | Verdict | Reason |
|---|---|---|---|
| S-4 | Name the card that will establish the form | eliminated | the replacement rule ships in this release, and `ADR-010` § 8 puts the form on *"whichever work item first actually ships a partial supersession"* |
| S-1 | Supersede `ADR-003` whole, restating its Decisions 1, 3 and 4 in the new record | eliminated | governance conformance: it re-decides three decisions #718 says stand, and `ADR-003` is mentioned 68 times across 16 files, probed at `8b2ac05` over the tracked tree — each citation of a decision still in force would then point at a `Superseded` record |
| **S-2** | **In-part supersession, recorded in `ADR-003`'s `Status:` line with an inline forward marker, codified as a § *Convention* bullet in the shape of `ADR-009`'s eighth amendment** | **← recommended** | — |
| S-3 | The same form, uncodified, with the deviation named | survives; loses | by this release's merge the form would have more than one use and no text, and `ADR-010` § 8 asks for it to be established deliberately |

## Decision

Nine decisions. Each names the criteria of #718 it answers; Decision 9 collects their
reversibility and confidence.

### 1. V-2 is an operator-mediated crossing entering on CH-3, and the channel-set is unchanged

Answers #718's first and sixth criteria.

- The inbound approval return travels on a human-carried path the engine does not govern. The
  recommended path is the group's shared thread; a direct message or an in-person relay is
  admissible, because the recording act is transport-blind.
- On its traveller-side leg the path fails `ADR-026` § 1's L2 and L3, so it is not a channel. The
  approval enters the engine only as the organizer's statement, on CH-3, through a terminal-only
  recording act.
- No fourth member is admitted, so `ADR-026` § 2's admission conditions are not engaged. V-1 is
  not re-decided: it stays discharged on CH-1.
- The V-2 row's ground moves from *L2 UNDETERMINED* to *L2 fails on the traveller leg*.
- **CHEAP · HIGH.**

### 2. The mechanism: recorded approvals counted against a declared threshold

Answers #718's second criterion. `ADR-010` § 7 reserves the choice to the maintainer.

- Republish gates on the approvals the organizer has recorded, counted against the trip's
  declared threshold. Each record is bound to the digest of the outgoing itinerary content and
  carries the provenance token `organizer-stated`.
- `ADR-010`'s Candidate C is not chosen, on the corollary and on proportionality: repaired to
  reach token-level unforgeability, it would buy evidence portability rather than detectability,
  at EXPENSIVE reversibility and a first cryptographic surface (O-2). The maintainer rendered the
  choice at the scope-lock gate, choosing this keyed ledger over a keyless, count-only variant put
  to them there as a live alternative.
- **#88's second criterion** — approvals captured *"attributably, not organizer-attested"* — **is
  unmet by construction under this decision, and delivered as detectability**, by the
  maintainer's proportionality choice under `ADR-010` § 7. `ADR-010` § 2's reduction of that
  criterion to unforgeability and detectability stands; this record delivers the second property,
  and says so.
- **The token's name.** `organizer-stated` names the **source** of the claim — the organizer
  stated it — rather than the scribe, and it sets the record against *"presented as the
  traveller's own"*, the milestone's own words. The token and its root each measured 0 lines in 0
  files, probed at `8b2ac05` over the tracked tree under `ADR-025` § 7's convention. It differs
  from the engagement axis's `OPERATOR-STATED` — a person's C12 entry, a different object — in its
  first word, not only in case.
- **CHEAP–MODERATE · HIGH** on the architecture; **MEDIUM** on the proportionality call, which is
  the maintainer's.

### 3. The interaction

Answers #718's second criterion. The flow, as a numbered step table:

| Step | Actor | Act | Where the engine acts |
|---|---|---|---|
| 1 — Declare | the operator | declares the approver population — a subset of the `## Group` roster's Person cells — and a threshold of `all` or an integer from 1 to n | a declaration surface #719 chooses; operator-stated policy, reversible, echoed outgoing-to-incoming, so it may be agent-addressable, as `/trip-record .publish-slug` already is |
| 2 — Request | the engine, to the organizer | emits the approval line for the outgoing itinerary, `approve <64 hex>`, from the same digest function the gate uses | a read-only emission on CH-3 |
| 3 — Share | the organizer, to the group's thread | posts the change summary and the approval line, exactly as `ADR-003` § 2 already has them share the summary | none — operator-mediated, outbound |
| 4 — Reply | each traveller who approves, in the thread | replies with that line; `withdraw <64 hex>` retracts; silence and refusal leave the plan held | none — V-2's traveller-side leg |
| 5 — Record | the organizer, at a terminal | runs `confirm`, extended: selects a declared approver, pastes their line and types `CONFIRM`; the line is refused if it fails the grammar, or if its code is not the current outgoing digest, which is named as stale; on acceptance one `organizer-stated` record is appended and the running count is shown | `confirm` — terminal-only, no override flag, on CH-3 |
| 6 — Gate | the engine | `update` proceeds only on `confirmed`: distinct declared approvers, each counted by their latest record for the outgoing digest, reach the threshold | S2 and S3 |
| 7 — Render | the engine, to the travellers | the `updated` notice carries the approval count and the approval code, with one static statement that names the organizer as the source of the count and shows no threshold — for example *"k approvals, as stated by the organizer"*, never *"k travellers approved"* | CH-1 |

- A withdrawal recorded after the change has published un-publishes nothing: the organizer
  decides whether to revert, and the site's count changes at the next rebuild.
- **Privilege split.** Declaring who approves is policy, and may be agent-addressable. Recording
  that someone approved is an attestation: **EXCLUDED `ADR-007 §2`, terminal-only, with no override
  flag** — the reason `ADR-007` § 4 row 11 already gives for `confirm`. With no declaration,
  `confirm` is unchanged byte for byte.
- **CHEAP · HIGH.**

### 4. Attribution, the local half

Answers #718's third criterion.

- **The binding.** An approval binds to a traveller only locally, when the organizer names a
  declared approver while recording it. The ledger key is that approver's canonical traveller key
  (O-4). Nothing that identifies an approver leaves the build: not on the V-2 path, and not on the
  render.
- **The kinds.** No kind of traveller approves unforgeably under this decision: every record is
  the organizer's statement, and the binding that tells the engine whose approval a record counts
  is organizer-registered whatever the mechanism (the corollary). K1 and K2 are the only kinds
  whose own statement can cross into the engine at all, and that crossing does not make an
  approval unforgeable. All five kinds count identically — one organizer-stated approval each,
  when declared.
- **The population.** It is declared by the operator and read by the gate as declared. The engine
  never adds, drops or weights an approver by `engagement(t)`, reads no C12, C3 or C22 file to
  count, and reads no provenance mark. A change in someone's axis value changes no verdict.
- **The default.** With no declaration, the population is the organizer alone at a threshold of
  1 — the gate `ADR-003` Decision 2 shipped. Every existing trip is therefore unchanged.
- **The threshold.** When approvers are declared, the threshold defaults to `all`, and `all` is
  the recommended setting. Under `all` the published count equals the declared population, so a
  declared approver who withheld approval sees a count that would have to include them, and a
  forged record shows in the count alone. Under a lower threshold a forged record can hide among
  genuine ones, and only reconciliation against the thread detects it.
- **Robust to #1491.** Whatever the roster holds, only what the operator declares from it counts.
- **CHEAP · HIGH.**

### 5. The binding digest is collision-resistant

Answers #718's third and fourth criteria.

- The digest an approval binds is SHA-256 over the itinerary-content projection the gate already
  computes, carried in full as 64 lowercase hex characters. It is one value for the gate, the
  carried line and the render.
- CRC-32 leaves the approval path. The recommended route is the one-body swap `_digest_of`'s
  comment names, using perl's core `Digest::SHA`: perl is already required, and this sidesteps
  the BSD and GNU dialect split the comment cites.
- **The legacy-baseline shim is a requirement on #719.** A stored baseline of CRC-32 shape is
  compared with the legacy projection of the outgoing render: equal reads `none-pending` and
  re-anchors to SHA-256 on the next successful push; a legacy token never counts as an approval.
- **Consequence.** A published trip whose plan did not move reads `none-pending` across the swap
  and re-anchors on its next successful push, so the gate never reports a change of digest
  function as a change of plan, and never asks a group to re-approve a plan that did not move.
- **MODERATE · HIGH.**

### 6. The privacy bound

Answers #718's fourth criterion.

- **The V-2 path's envelope.** Its `audience` is `party` — the shared thread — in the worst case,
  and `operator` for a direct message. Its `observers` value is **`third-party`**: the messaging
  service, or the carrier for SMS.
- **What may be carried: exactly the approval line.** Nothing else is emitted for the path, and
  nothing else is admitted from it. `denied` is UNDETERMINED here, because the path renders
  nothing and queries none of the pairs `ADR-026` § 3's `denied` reads, so the path takes its
  bound from its own rule — the allowlist.
- **The R-test for the V-2 path** is that allowlist, observable at both ends. The line the engine
  emits matches `^(approve|withdraw) [0-9a-f]{64}$` exactly. The recording act admits nothing that
  fails that grammar: it must refuse, writing nothing, a name appended, a URL, 63 or 65 hex
  characters, uppercase hex, a `cksum` token and a bare `yes`, and it must accept the exact line,
  appending exactly one record. Whether it trims surrounding whitespace or folds the verb's case
  before the check is #719's to decide, bounded by the allowlist's purpose: no normalization may
  admit a byte that could carry a name, a need or a URL.
- **The render (CH-1) gains at most two values: the approval count and the approval code.** Both
  are name-free, the threshold never reaches the render, and the pair is exactly `ADR-025` § 4's
  *"an aggregate count paired with a content digest"*. The `updated` notice's one static statement
  names the organizer as the source of the count and shows no threshold.
- **The W-test for the render** is that statement: it attributes the count to the organizer and
  never says that travellers approved — the W-rule of `ADR-026` § 5, *"the engine never authors a
  traveller's own statement"*.
- **The R-test for the render** is name-freedom. No approver key reaches any input of the site
  build except through the aggregate: no build input and no render lets a reader tell which roster
  members are declared approvers, or which of them approved. The roster's names already reach the
  render through the trip file, so what this test guards is approver-ness, not identity; #719
  builds its arms.
- **What a messaging service can learn:** that members exchanged a fixed-form 64-hex token at a
  time. With one-to-one replies it can also link the traveller replies that carried one code — a
  stated residual.
- **The change summary's outbound share** is `ADR-003` § 2's step, carried forward unchanged. This
  record neither widens nor narrows `ADR-003` § 4's bound on it. Its exposure depends on the
  thread's encryption — a residual, with the recommendation to use an end-to-end-encrypted thread.
- **The standing clauses:**
  - no `[THIRD-PARTY]` value reaches the V-2 path or the render, attributed or anonymized — the
    grammar cannot express one, and the ledger holds no C12 value;
  - transport and provenance never establish consent;
  - `internal-hard` binds the render, unchanged;
  - `ADR-006` is unwidened.
- **CHEAP as a rule · HIGH.** Each published count and code is IRREVERSIBLE once observed, and
  neither is sensitive.

### 7. The gate rule of `ADR-003` Decision 2 is superseded in part, and the form is codified

Answers #718's fifth criterion.

- **What is superseded.** The clauses of `ADR-003` § *Decision 2* that make republish wait on the
  organizer's confirmation — *"the organizer confirms → the republish path (#85) fires"* and
  *"Republish gates on the organizer's confirmation, not a system-counted quorum"*, quoted without
  the source's emphasis — are superseded by Decision 2 of this record. The rest of that decision
  stands: sharing the summary, the group's own channel, the rejected plan holding, and *"the
  humans do the consensus"*. Its Decisions 1, 3 and 4 stand. The default configuration reproduces
  the superseded rule exactly.
- **The form** is the new bullet of `reference/adr/README.md` § *Convention*, *Superseding one
  decision, or part of one*, which this record's change adds. `ADR-003` stays `Accepted` in its
  `Status:` value and in its index cell; its `Status:` line records the supersession as an
  amendment that records rather than decides; the superseded sentences are retained with an
  inline forward marker; and the supersession is recorded when it takes effect — for a rule
  implemented in code, in the change that ships the replacement, as `ADR-010` § 8 requires. Here
  that is #719's change that replaces the S2 body, in the same pull request as this record. This
  record's change edits no line of `ADR-003`.
- **Coordination.** The bullet is written in the shape `ADR-009`'s eighth amendment already has,
  which is also the shape #1242's planned amendment of `ADR-009` uses, so the order in which the
  two releases land does not matter.
- **MODERATE · HIGH** on the form; **MEDIUM** on #1242's final route, which is not yet rendered.

### 8. Reconciliation and what else moves

Answers #718's sixth criterion.

- This record conforms to `ADR-025` and `ADR-026` as Accepted, citing:
  - `ADR-026` for what a channel is, the channel-set and carry (§§ 1–3), the reach table and its
    kinds (§ 4), and the W-rule and R-rule (§ 5);
  - `ADR-025` for the render prohibition (§ 4), `engagement(t)`'s `G8` class (§ 1), and `EB-0`
    (§ 3) — an approval carries across a re-synthesis if and only if the itinerary text, and so
    its digest, is unchanged.
- It edits no decision of either record. Its change adds dated amendments to two records, and
  each decides nothing:
  - `ADR-026` § *Decision* 2 — a paragraph recording V-2's outcome;
  - `ADR-010` § 7 — a claim-correction scoped to Candidate C as specified on #708; and `ADR-010`
    § 8 — a correction of the now-false *"This corpus has no partial-supersession form, and no
    record in it has ever been superseded at all"*.
- **Journey-seam assumptions**, stated rather than decided:
  - **#1242**, whose design round is not yet rendered. This record moves no cell of `ADR-026`'s
    channel-axis table, and it is robust under either option #1385 proposes: one moves nothing,
    and the other's own text leaves the bound on approval attribution unchanged.
  - **#1357.** This record resolves V-2 against `ADR-026` §§ 1–2 as they stand. If #1357
    relocates the admission law first, this record conforms, and #1357's second item then carries
    V-2's new ground.
  - **#1491.** Robust under all three of its readings of roster standing, by Decision 4.
- **CHEAP · HIGH.**

### 9. Reversibility and confidence

| # | Decision | Reversibility | Confidence |
|---|---|---|---|
| 1 | V-2 an operator-mediated crossing; the channel-set unchanged | **CHEAP** | **HIGH** |
| 2 | Recorded approvals counted against a declared threshold | **CHEAP–MODERATE** | **HIGH** on the architecture; **MEDIUM** on the proportionality call, which is the maintainer's |
| 3 | The interaction | **CHEAP** | **HIGH** |
| 4 | Attribution, the local half | **CHEAP** | **HIGH** |
| 5 | A collision-resistant binding digest | **MODERATE** | **HIGH** |
| 6 | The privacy bound | **CHEAP** as a rule; each published count and code **IRREVERSIBLE** once observed | **HIGH** |
| 7 | The gate rule of `ADR-003` Decision 2 superseded in part; the form codified | **MODERATE** | **HIGH** on the form; **MEDIUM** on #1242's final route |
| 8 | Reconciliation | **CHEAP** | **HIGH** |

## Consequences

### What becomes false or is re-grounded

These are consequences, not a schedule; the last column names the change that carries each one.

| # | Surface | What becomes false or is re-grounded | Disposition | Owner |
|---|---|---|---|---|
| 1 | `ADR-026` § *Decision* 2 — the V-2 row (*"VACANCY. L2 UNDETERMINED … This is #718's work"*), the section's heading (*"… two typed vacancy rows, one of them discharged"*) and its *Follow-on* bullet for #718 | V-2 is resolved as an operator-mediated crossing on CH-3; its L2 ground is now *fails on the traveller leg* | retained as decided; a dated amendment paragraph at the end of the section records the outcome and discharges the *Follow-on* bullet | this record's change |
| 2 | `ADR-026` § *Decision* 1 — the candidate row *"The inbound approval return … UNDETERMINED … not a member — a typed vacancy"* | the verdict — not a member — is unchanged; the ground is determined | read through the amendment to § *Decision* 2 | this record's change |
| 3 | `ADR-010` § 7, the Candidate C bullet — *"Satisfies the unforgeability limb, provided the signing key never leaves the traveler"* | for Candidate C as specified on #708 the proviso is necessary and not sufficient: that specification enrols the key through the organizer and holds and exercises it in organizer-authored page script. `ADR-010` § 2 stays true — token-level unforgeability remains reachable with a traveller-held key in a tool the traveller controls — and its reduction of #88's second criterion stands | a dated claim-correction amendment at the end of § 7, scoped to Candidate C as specified on #708; the argument has one home, this record, as `ADR-010`'s *Consequences* route it (*"#718 should re-read rather than adopt"*) | this record's change |
| 4 | `ADR-010` § 8 — *"This corpus has no partial-supersession form, and no record in it has ever been superseded at all"*; its *Consequences* (*"the first work item that needs one will pay for establishing the form"*); its *Follow-on* (*"The partial-supersession form … established by whichever record first actually needs it"*) | made false by the new § *Convention* bullet; the never-superseded clause had already been overtaken on 2026-09-02, by `ADR-009`'s eighth amendment | a dated claim-correction amendment in § 8; the retained sentences are read through it | this record's change |
| 5 | `ADR-010` § 5 — *"A collection mechanism replaces one function body."* | false if #719 replaces `_digest_of`'s body as well as S2's, which is Decision 5's route | a dated amendment, only if the swap is taken | #719's change, conditional |
| 6 | `ADR-010` § 6's routing text — *"decides four things: the channel, …"* | a historical routing statement, not a live claim | not amended: `ADR-026` took the channel-roster half without amending it, and that is the precedent | none |
| 7 | the organizer-confirm rule in `ADR-003` § *Decision 2* | superseded in part by Decision 2 of this record | its `Status:` line gains a first-amendment entry; an inline forward marker at the superseded clauses; its index cell stays `Accepted` | #719's change, with the S2 body |
| 8 | the line-anchored citations `ADR-026` makes of `ADR-003` § *Decision* 3, in the V-1 row and in its *References* | the `Status:` block of `ADR-003` grows in #719's change, so the line they anchor moves | repaired to the quotation they already carry, in the same change | #719's change |
| 9 | `ADR-003` § *Consequences* — *"Approval is not system-enforced"*; *"Async approvals are not tracked by the tool"*; *"would require revisiting the server-less model"* | approvals are now tracked where declared, and are still not system-enforced — the ceiling; the server-less clause is refuted by `ADR-010` § 1 | retained as decided — historical | none |
| 10 | `ADR-007` § 4 row 11's rationale — *"the organizer's decision that ADR-003 § Decision 2 reserves to a person"* | the reservation carries forward: Decision 3 keeps the recording act person-reserved for the same reason | retained; re-grounded by Decision 3 | none |
| 11 | `reference/adr/README.md` § *Convention*'s status-lifecycle bullet — *"to change a decision, author a new ADR and mark the old one `Superseded by ADR-MMM`"* | incomplete for the partial case | a new bullet, and a forward clause on that bullet's continuation line — never on its first line, which the conformance suite reads as the lifecycle enum | this record's change |
| 12 | `scripts/publish-trip-site.sh` — the header comment naming the organizer-confirm gate and `ADR-003` § *Decision 2*, the S2 and S3 banners, and `_digest_of`'s *"there is no adversary in this threat model"* | the gate's authority moves to this record, and the binding digest gains an adversary | the comments naming the live authority are re-pointed; the historical banners describing what #552 built stay | #719 |
| 13 | `skills/trip/SKILL.md` § *site* — `.change-confirmed` read as *"the organizer's recorded approval"*, *"the only record any shipped surface writes when the organizer decides"* | with a declaration, the approval event is the declared threshold met for the outgoing itinerary | the mapping and its `**Reads:**` line re-grounded | #719 |
| 14 | `reference/site-layout-spec.md` § 3 — *"Content: a static label string + the `coordination-since` date. Nothing else"* and *"Its entire data input is `{enum, date}`"* | the `updated` variant gains the approval count and the approval code, which carry no plan content | amended in #719's slice, with the band re-measured against `_COORD_NOTICE_CAP` | #719 |
| 15 | `reference/schemas/travel-site.md` — *"this class declares two, and they are one concern"* | per-class fields are added for the count and the code | #719's slice | #719 |
| 16 | `skills/trip-record/SKILL.md`, the erase reach table — row 20, *"control files, declared to hold no person data"* | the new sidecars hold roster keys, so they cannot join row 20 | a new REACH row, with the tally arms moving with it, as `ADR-028`'s row did | #719 |
| 17 | #85's sixth criterion — *"the organizer confirmation `cmd_confirm` records today"* | the approved-change event is S2 resolving `confirmed` for the outgoing digest, whatever produced it | a coordination note for #85's author | #85 |
| 18 | #1357's second item — *"`V-2` is `UNDETERMINED`"* | V-2's ground changes | coordination: whichever lands second conforms | #1357 |
| 19 | #719's first criterion (*"… attributably, not organizer-attested"*) and its third, the `ADR-003` Decision 4 privacy guarantee | the first is contradicted by closed records under this record's mechanism; the third, read against the change summary `ADR-003` § 2 already has the organizer share, depends on the thread's encryption | both restated at the operator-gated crispness pre-gate, before #719's design; #88's second criterion is recorded as delivered by detectability, by the maintainer's proportionality choice | the maintainer, at that pre-gate |
| 20 | the planned risk of a first cryptographic surface | does not materialize under this record's mechanism | retired: the maintainer chose the keyed ledger | none |
| 21 | `reference/data-architecture.md` § 5.1 (`internal-hard`: *"Exactly C12, C14, C22 and C23"*), `ADR-025`, `ADR-006` | **unchanged** — the sidecars are not artifact classes, and nothing reaches the render beyond an aggregate | none | none |

### Positive

- **V-2 is resolved without a fourth channel**, by the classification `ADR-026` § 1 already gives
  the human-carried path.
- **The feature says what it is.** It claims detectability — by count, by content and by the
  thread — and delivers it, and it never presents an organizer-stated record as the traveller's
  own.
- **No standing infrastructure and no cryptographic surface.** The collision-resistant digest is a
  core perl module behind an existing seam, and the collection mechanism is one function body at
  the seam #552 built.
- **Every existing trip is unchanged until approvers are declared**, because the default
  reproduces the gate `ADR-003` Decision 2 shipped.
- **The corpus can now say "superseded in part"**, in the shape its only shipped instance already
  has, so the next record that needs the form finds it written down.

### Trade-offs

- **#88's second criterion is unmet by construction** and delivered as detectability, by the
  maintainer's proportionality choice under `ADR-010` § 7.
- **The organizer transcribes every approval.** Each declared approver's line is pasted once in
  the thread and once at the terminal, against `ADR-003`'s low-ceremony driver; that is the price
  of keeping the recording act person-reserved.
- **Under the recommended `all`, one silent approver holds the plan.** That is the default's
  point, and a lower threshold trades it for a count a forged record can hide in.

### Neutral and explicitly unchanged

- `ADR-002` — no standing server; upheld.
- `internal-hard` at C12, C14, C22 and C23 — unwidened.
- `ADR-006` and `ADR-014` — unwidened.
- `ADR-025` and `ADR-026` — no decision re-opened.
- `reference/data-architecture.md` — no class, row or field changes.

## Residuals

Stated rather than smoothed over:

- the organizer can record an approval never given — accepted, and detectable by count and thread;
- the organizer can bypass the gate by not running it (`ADR-010` § 2);
- the thread's service learns metadata, and can link one-to-one replies carrying one code;
- the change summary's outbound share exposes plan content according to the thread's encryption;
- the `updated` band decays after seven days, taking the count off the site;
- a withdrawal recorded after publication un-publishes nothing;
- the `*)` abort message keeps its *"no organizer confirmation covers it"* wording under a
  declaration;
- a revert of #719's build after baselines have re-anchored to SHA-256 reads each such plan as
  moved until it is confirmed — fail-closed, in the direction the shim does not cover.

## Follow-on build slices

- **#719** — this release. It builds against Decisions 2 to 6, carries the required
  legacy-baseline shim (Decision 5), and ships Decision 7's edit of `ADR-003`. Its first and third
  criteria are restated at the operator-gated crispness pre-gate before its design.
- **The observable tests** — the V-2 path's R-test, and the render's W-test and R-test
  (Decision 6) — are #719's arms.
- **A decaying count.** The `updated` band leaves the site after seven days — a candidate for
  #1296's surface contract.
- **The change summary's exposure** — recorded, not scheduled.
- **A binding the organizer does not register.** A transparency log, or an independent key
  directory, is the one route by which the binding itself could be checked without the
  organizer's word. It is **not proposed**, and it is an `ADR-002` question.
- **The operator's future-state direction — named, not decided.** An engine-reachable messaging
  channel, iMessage or another messaging app, on which the engine sends updates and reads approval
  replies. It is what T5 in O-1 eliminates today on standing-infrastructure grounds, so it would
  have to clear `ADR-002` and `ADR-010` § 3's backend argument, and be admitted under `ADR-026`
  § 2. Owner: the group-approval epic, #1297.

## References

- [ADR-002](ADR-002-living-site-refresh.md) — the secret model and the no-standing-server
  constraint, upheld.
- [ADR-003](ADR-003-group-coordination.md) — § *Decision 2*, whose gate rule this record
  supersedes in part, and §§ 1, 3 and 4, which stand.
- [ADR-006](ADR-006-third-party-data-capture.md) — a `[THIRD-PARTY]` value is never published, and
  provenance never establishes consent. Unwidened.
- [ADR-007](ADR-007-command-entry-point.md) — § 2's bounds, including that no command may
  overwrite or delete existing trip content, and § 4 row 11, the reason `confirm` is
  person-reserved.
- [ADR-008](ADR-008-publish-content-guard.md) — the value class the approval line's alphabet
  cannot express.
- [ADR-009](ADR-009-data-architecture.md) — its eighth amendment, the first instance of the
  partial-supersession form.
- [ADR-010](ADR-010-per-traveler-approval-collection.md) — §§ 1–5, inherited; § 7's candidates,
  re-read here; § 8's missing form, supplied.
- [ADR-013](ADR-013-count-assertion-basis.md) — every count in this record is authored to form
  **F1**, anchored measurement.
- [ADR-014](ADR-014-cross-trip-consent-refusal.md) — unwidened.
- [ADR-025](ADR-025-engagement-model-over-time.md) — `engagement(t)` and its `G8` class (§ 1),
  `EB-0` (§ 3), the render prohibition (§ 4), and the naming convention (§ 7).
- [ADR-026](ADR-026-channel-architecture.md) — what a channel is and the channel-set (§§ 1–2),
  carry (§ 3), the reach table and its kinds (§ 4), the W-rule and R-rule (§ 5), and the naming
  convention (§ 6).
- `reference/adr/README.md` — § *Convention*: the status lifecycle, the amendment rule, and the
  partial-supersession bullet this record's change adds.
- `reference/data-architecture.md` — § 3.2, the traveller key's normalization; § 5.1,
  `internal-hard`.
- `reference/site-layout-spec.md` — § 3, the Coordination Notice.
- `reference/schemas/travel-site.md` — the per-class coordination fields.
- `skills/trip/SKILL.md` — § *site*, the coordination-state mapping.
- `skills/trip-record/SKILL.md` — § *erase*, the reach table.
- `scripts/publish-trip-site.sh` — `change_confirmation_state`, `require_change_confirmation`,
  `cmd_confirm`, `_digest_of`, `itinerary_digest` and `strip_to_itinerary_text`.
- `scripts/test-publish-guard.sh` — group `S`, which grades the seam's contract whatever body S2
  holds.
- #718, its milestone (#34) and the group-approval epic (#1297); #719, the collection build;
  #708, whose candidate designs are re-read here; #88, whose second criterion this record delivers
  as detectability.
