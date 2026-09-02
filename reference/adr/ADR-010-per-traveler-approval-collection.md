# ADR-010: Per-traveler approval collection — transport over server, the attestation ceiling, and the unnamed channel

- **Status:** Proposed (2026-09-01). Ratification is this release's design gate. The two-step is the
  one this corpus already uses: `ADR-006` and `ADR-007` each landed `Proposed` and were flipped to
  `Accepted` by a later ratifying commit.
- **Deciders:** repo maintainer
- **Driving work:** #88, under the group-coordination epic (#77). This record is the prerequisite
  architecture decision #88's first acceptance criterion requires, and it is that card's whole
  delivery. The collection *mechanism* the card also asked for moved to #719, behind the channel
  gate #718, by operator decision at this release's solutioning gate.
- **What this record is not.** It decides a posture and rejects a class of design. **It does not
  specify a mechanism**, and it deliberately declines to name one — see Decision 7. A reader looking
  for the verifier, the key algorithm or the file format is looking in the wrong document; those are
  #718's and #719's, and this record explains why they cannot honestly be settled here.

## Context

`ADR-003` § *Decision 2* settled v1 group approval as **organizer-mediated and out-of-band**: the
organizer shares a change summary, "the group approves through their own channel (out-of-band), and
the organizer **confirms** → the republish path (#85) fires." That record states its own limit in
terms, under § *Consequences*: "Approval is **not system-enforced** — it relies on the organizer to
honor group consensus." The gate it describes now exists — #552 built it in this release, as
`require_change_confirmation` and `change_confirmation_state` in `scripts/publish-trip-site.sh`.

#88 asks for the v2 direction `ADR-003` § *Options considered* named and retained. It arrived
carrying a premise, stated in its own Notes: a static, encrypted GitHub Pages site has no backend to
collect votes, **therefore** the server-less / privacy-by-construction model must be revisited. Its
first acceptance criterion is written as a disjunction on exactly that premise — settle collection
without a server, **or** explicitly revise the posture `ADR-002` established.

**That premise is what this record tests first, because nothing downstream of it can be sized until
it is settled.** If it holds, this is a revision of the repository's security posture and the largest
architectural change since `ADR-002`. If it does not, it is a feature.

It does not hold. Collection needs a **transport**, not a **server**, and `ADR-003` § *Decision 2*
does not merely permit an out-of-band transport — it already **relies** on one, in the words "their
own channel." Nothing about a static site forecloses moving a small opaque value from a traveler to
the organizer; the site is not the only thing the group has.

Testing the premise surfaced a second thing, and it is the more useful half of this record.
**`ADR-003` never named that channel, and neither did the design that tested this premise.** "Their
own channel" and "out-of-band" are the same placeholder written twice, one release apart. The v1
model can live with the placeholder because a human reads the summary and a human reports the
answer, and humans resolve an unnamed channel by using whichever one they already have. A *mechanism*
cannot: what a traveler does to approve, whether an approval can be forged, and what reaches a third
party are all properties **of the channel**, and none of them can be decided against a placeholder.

So the honest state of this problem is not "we know the answer and must now build it." It is: the
posture question is settled, the class of wrong answers is settled, and the load-bearing question is
one nobody had asked. This record says all three, and stops there.

## Decision drivers

- **Preserve `ADR-002` unless a revision is *earned*.** A revision is earned when the requirement
  cannot be met inside the existing posture, not when meeting it inside the posture is inconvenient.
  #88 asserted the first and demonstrated neither.
- **`ADR-003`'s low-ceremony driver is a constraint, not a preference.** "This is a personal
  group-trip tool, not an enterprise approval system." A design that satisfies every acceptance
  criterion and that no group will actually complete has satisfied nothing.
- **The privacy bound is `internal-hard`, and it is stronger than #88 states.** #88's fourth
  criterion asks that no trip detail reach a public or third-party-visible surface.
  `reference/data-architecture.md` § 5.1 binds harder than that on the render, and the harder bound
  governs — see Decision 4.
- **Add no standing infrastructure.** No server, account, endpoint, cloud secret, uptime obligation,
  retention duty or recurring cost. This is the operational half of `ADR-002`'s privacy-by-
  construction posture: a thing that does not exist cannot leak, cannot lapse and cannot be
  subpoenaed.
- **Decide what the evidence supports, and no more.** An over-decided record is harder to walk back
  than an honestly scoped one, because the walk-back has to defeat a decision that was never
  grounded. Where this record's evidence runs out — at the channel — it says so and routes, rather
  than filling the gap with the most plausible mechanism.

## Options considered

Six candidates, scored against the two properties Decision 2 establishes as the real targets:
**unforgeability** (the organizer cannot manufacture an approval) and **detectability** (a traveler
can tell when the published plan is not the one that was approved). They are *not* scored against
"does it collect votes," because every one of them collects votes and that is why the naive
comparison is unhelpful.

| # | Option | Unforgeable? | Detectable? | `ADR-002` § *Decision 2* | Standing infrastructure | Ceremony | Verdict |
|---|---|---|---|---|---|---|---|
| **A** | **Backend** — a serverless function or small VPS; the decrypted page POSTs an approval | Only with keys the page already holds, in which case the server is pure transport | **No** — the record lives where the travelers do not look | **Revised.** A trip-keyed, traveler-keyed, time-correlated request to a third party | New third-party surface; uptime, secrets, abuse control, retention, deletion | Low | **REJECTED** — Decision 3 |
| **B** | **Identity provider** — OAuth from the decrypted page | Against the provider, yes | No | **Revised, and worse than A** — a redirect discloses the trip URL through `redirect_uri` / `Referer` | Provider registration and secrets | An account per traveler | **REJECTED** — ties a real identity to a specific trip at a third party; the intuitive answer and the worst privacy outcome available |
| **C** | **Out-of-band token round-trip**, verified locally, tally baked into the ciphertext | **Yes**, if the signing key never leaves the traveler | **Yes** — a count and a bound digest published inside the ciphertext | **Untouched** — no new request | **None** | One enrollment, then one copy/paste per change | **CANDIDATE** — Decision 7 |
| **D** | **Roster threshold with organizer-entered attribution** — no cryptography | **No, by construction** — every record is organizer-written | Partial — a published count is still checkable against a known roster size | Untouched | None | Near zero | **CANDIDATE** — Decision 7 |
| **E** | **Privacy-preserving aggregation** — threshold cryptography, secret sharing, blind tally | Yes | Yes | Untouched | None | High, plus a cryptography library inside the page | **REJECTED** — optimizes *anonymity* where #88 asks for the opposite, at the largest review surface of any option here |
| **F** | **Per-traveler ciphertexts or passphrases** | No — the organizer mints every passphrase | No | Untouched | None | Publish cost and repository count multiplied by the party size | **REJECTED** — identifies without attributing, and multiplies the public surface to do it |

**A survives a messaging channel, and the distinction is worth stating** because #718 will very
likely name a third-party channel, and a reader could reasonably conclude that a third party is
therefore no longer disqualifying. It is not the involvement of a third party that `ADR-002`
§ *Decision 2* governs — it is **what the published page fetches**. An out-of-band channel is carried
by the people, so the decrypted page issues no request under any of C, D, E or F. A backend requires
the page itself to POST, trip-keyed and traveler-keyed, at the moment a traveler reads the itinerary.
Those are different exposures with different observers, and only the second one is the class
`ADR-002` § *Decision 2* excluded. **Whatever channel #718 names, it will owe its own third-party
privacy bound — but it will not owe this one, and it does not reopen A.**

## Decision

Eight decisions. Six are settled. Two record what is deliberately **not** settled, and route it.

### 1. `ADR-002` is upheld. No supersession is proposed.

#88's first acceptance criterion resolves on its **first** limb: per-traveler approval collection is
reachable **without a server**, so the server-less posture is not revisited.

The card's inference fails at the "therefore." That a static site has no backend is true and is not
in dispute. What does not follow is that collecting an approval therefore requires one. Collection
requires a **transport** — some way for a small value to travel from a traveler to the organizer's
build host — and `ADR-003` § *Decision 2* already depends on exactly such a transport for the
summary and the group's answer. The v2 direction asks that transport to carry a *different payload*.
A different payload is not a different architecture.

`ADR-002`'s four decisions are each untouched by that:

- **§ *Decision 1* (no cloud secret)** — nothing is added to any cloud location, and no candidate in
  the matrix above except A and B puts one there.
- **§ *Decision 2* (client-side ambient data)** — governs what **the published page fetches**. A
  design in which the page fetches nothing does not engage it. This release already ships the
  precedent: `reference/schemas/travel-site.md` justifies `coordination-since` decaying against the
  reader's own clock as "local computation over baked bytes rather than a fetch, so `ADR-002`
  § *Decision 2* is untouched."
- **§ *Decision 3* (event-driven republish)** — unchanged; approval remains the event.
- **§ *Decision 4* (0-plaintext-leak under automation)** — unchanged; no new value crosses the guard,
  and neither guard function is touched by anything this record contemplates.

### 2. The attestation ceiling — what "not organizer-attested" can mean here

`ADR-002` § *Decision 1* puts the plaintext, the passphrase, the build host and the push credential
on **one machine the organizer owns**. Every byte that reaches a traveler is authored on that
machine by that person. **No mechanism running there can be enforced against its owner** — whatever
gate runs locally is a gate its owner can decline to run, patch out, or bypass by publishing by hand.

This is not a defect to engineer around. It is a consequence of a decision this repository already
took deliberately, and it would survive a backend: a backend can hold the tally, but the organizer
still authors every published byte, so the site can disagree with the tally and the site is what the
travelers read.

**Therefore #88's second criterion — approvals captured "attributably, not organizer-attested" —
cannot mean *the organizer is unable to republish without consent*.** Nothing available to this
architecture can mean that. It reduces, without loss, to two properties that *are* reachable:

- **Unforgeability** — the organizer cannot manufacture an approval that a traveler did not give.
  This requires the verifier to hold strictly less than the signer, which is why a shared secret
  cannot serve: the organizer must hold it to verify, and can therefore forge with it.
- **Detectability** — a traveler can tell that a republish did not carry their approval, or carried
  approval for content other than what was published.

Stating the ceiling is the point. A mechanism sold as *enforcement* would be claiming a property this
architecture cannot deliver, and the difference between "the organizer cannot" and "the organizer
would be caught" is the whole honest content of the feature.

### 3. A backend is rejected on merit, not on cost

`ADR-003` rejected system-enforced voting for v1 on cost — it "requires a backend, breaking the
server-less / privacy-by-construction model" — and retained it as a future direction. That left the
open question of whether the backend becomes right once someone is willing to pay for it. **It does
not**, and this is the first time that has been argued rather than assumed.

Under Decision 2 the targets are unforgeability and detectability. A backend delivers **neither**
better than an out-of-band transport does:

- It does not deliver unforgeability. The property is a function of *who holds the signing key*, not
  of where the tally is stored. Whatever the page can send, the organizer can send.
- It actively **costs** detectability. Detectability requires the travelers to be able to see the
  discrepancy, and the only channel that reaches every traveler is the published artifact they
  already open. A tally in a database the travelers never visit is a record of the truth in a place
  where nobody checks it.

And it charges `ADR-002` § *Decision 2* and `ADR-003` § *Decision 4* for the privilege, plus a
permanent operational surface — an endpoint, its secrets, its abuse controls, its retention and
deletion duties — attached to a tool whose entire security story is that no such surface exists.

**Re-proposing a backend therefore requires defeating this argument, not out-budgeting it.** A
proposal that concedes the impossibility result and still wants the server must say what property it
buys.

### 4. The binding privacy constraint is `internal-hard`, and no attribution model may cross it

#88's fourth criterion asks that "no trip detail reaches a public or third-party-visible surface."
The operative constraint is **stronger**, it is already in the corpus, and it binds the *render*
rather than the channel. `reference/data-architecture.md` § 5.1 defines the class:

> **`internal-hard`** — never rendered **and** carrying values that must not reach a rendered page
> **in any form, including anonymized**. Exactly C12 and C14.

C12 is `outputs/traveler-model.md` — the per-traveler artifact — and § 1.1 carries it at that class.
The same clause is restated in four tracked files — `reference/data-architecture.md`,
`reference/adr/ADR-009-data-architecture.md`, `agents/06-validator.md` and
`reference/site-layout-spec.md` — so it is a settled corpus-wide rule rather than one document's
phrasing.

**Traveler identity may therefore not reach the render even pseudonymously.** Not a name, not a
handle, not a stable pseudonym, not a key fingerprint, and not a per-traveler approval receipt, which
is one in substance: a receipt that lets a reader tell *which* traveler approved is an anonymized
projection of a C12 value, and § 5.1 forecloses the anonymized projection by name.

**Any attribution model #718 or #719 adopts must survive that bound**, and it is the sharpest
constraint on the whole problem — sharper than the one #88 wrote down. It is survivable: detectability
does not require identity. A traveler who did not approve, reading a count that says everyone did,
knows the count is wrong; a traveler who did approve, reading a digest other than the one they
approved, knows the published content is not what they approved. Both failure modes are detectable
from a count and a digest alone, and neither needs a name.

### 5. The abstraction band is `extend-seam`, not `new-abstraction`

The 2026-08-30 readiness note recorded a concern that #88's remediation implies a `new-abstraction`
against the `extend-seam` band of the existing publish path — "the seam a new collection abstraction
would duplicate." **That concern does not materialize.**

#552 built its organizer-confirm gate in this release specifically so that a later replacement would
be a substitution at a named seam rather than an excavation: the decision rule lives in the body of
`change_confirmation_state`, while `require_change_confirmation`, its call site in `cmd_update`, its
four-token vocabulary and its allowlist-proceed / wildcard-abort structure sit outside it and are
indifferent to how a confirmation was obtained. A collection mechanism replaces one function body.
On the render side, #551's Coordination Notice component is the extension point for any additional
coordination state, and it already exists.

**The band is `extend-seam` on both surfaces.** This matters to sequencing, not just to bookkeeping:
it is why the mechanism can be deferred behind #718 without the seam rotting, and why #719 is
instructed to use the seam rather than excavate it.

### 6. The transport is left unnamed here — and that, not the verifier, is what blocks the mechanism

This record says collection needs a transport. **It does not say which**, and the omission is
deliberate and load-bearing rather than an accident of scope.

"Out-of-band" is a placeholder. `ADR-003` § *Decision 2* wrote it as "their own channel" and this
record inherits it unimproved. Everything a mechanism must decide is downstream of resolving it:
what a traveler physically *does* to approve, how an approval is bound to a traveler at all, and
what leaves the local build for a third-party surface are each properties **of the channel**. A
verifier specified against a placeholder is a verifier specified against nothing — it will be
correct about a channel that may not be the one chosen.

**The channel decision is routed to #718**, the milestone-head design gate of *Group approval
engagement layer* (#34), which decides four things: the channel, the approval interaction, the
identity and attribution model, and the third-party privacy bound. That gate inherits Decisions 1–5
above as settled and not re-openable, and it owes its own third-party bound per Decision 4 and
`ADR-006`.

Naming this as the gap is the substantive output of this record, alongside upholding `ADR-002`.
Specifying a verifier before the channel is known solves step two first.

### 7. The verification mechanism is contingent on the channel. Two candidates are recorded; neither is chosen.

Options **C** and **D** in the matrix above both survive every rejection this record makes. They are
recorded here so that #718 and #719 do not re-derive them, and they are recorded **as candidates**.
Choosing between them requires the channel, and it also requires a proportionality judgment that
belongs to the maintainer rather than to a design stage.

**Candidate C — out-of-band token round-trip, verified locally, with the tally baked into the
ciphertext.** The traveler's browser produces a short opaque approval token; the traveler returns it
through the channel; the organizer feeds collected tokens to a local verifier; a count and the digest
those approvals bound are baked into the next published ciphertext.

- Satisfies the **unforgeability** limb, provided the signing key never leaves the traveler. That
  requirement is what forces asymmetric keys — a shared secret fails Decision 2's verifier-holds-less
  test — and it is a real commitment, not a detail.
- Satisfies **detectability** without crossing Decision 4, because the published values are a count
  and a digest and neither identifies anybody.
- **Would introduce this repository's first cryptographic surface.** Probed at this branch's head
  across all **121** tracked files: **0** occurrences of any asymmetric-cryptography primitive
  (`crypto.subtle`, `generateKeyPair`, `ECDSA`, `Ed25519`, `P-256`, `secp256`, `createSign`,
  `createVerify`, `importKey`, `SPKI`, `pkcs8`), against a sensitivity arm (`staticrypt`) returning
  **28** hits in 7 files and a specificity arm returning 0. The repository's only cryptography today
  is StatiCrypt, invoked as a tool rather than composed as a primitive.
- Costs **ceremony**: one enrollment per traveler per trip and one copy/paste per traveler per
  change, against `ADR-003`'s low-ceremony driver. Key custody is the traveler's browser, so cleared
  site data or a second device means re-enrolling, and no recovery path can exist — one held by the
  organizer would hand back exactly the forgery the design removes.

**Candidate D — roster threshold with organizer-entered attribution.** A per-trip roster declares a
threshold; the organizer records each traveler's approval; the gate counts records against the
threshold and the count is published.

- **Fails the unforgeability limb by construction.** Every record is organizer-written, which is what
  organizer-attested means. This is not a gap to be closed later; it is the definition of the option.
- Retains partial detectability — a published count remains checkable against a roster size the
  travelers know — and satisfies #88's third, fourth and fifth criteria.
- Requires **no cryptography, no enrollment and no new language runtime**, and is materially
  cheaper — roughly a third of C by the solutioning estimate.

**Neither is chosen here, and the choice is not merely deferred paperwork.** C is the only candidate
that satisfies #88's second criterion as written; D is the only one proportionate to a personal
group-trip tool. The technical comparison is settled above; what remains is a product judgment about
whether this tool should ask its users to hold keys — and that judgment is materially changed by
which channel #718 names, because the channel sets what a copy/paste actually costs a traveler.

### 8. This record changes no other record's status

**`ADR-003` § *Decision 2* stands, in full, and this record proposes no supersession of it.** The
gate #552 shipped is the live decision rule and remains so.

That is not a formality. A supersession fires when a *replacement decision rule ships* — and the
mechanism that would replace it moved to #719, behind #718. Marking `ADR-003` § *Decision 2*
superseded now would retire a rule while the thing meant to replace it does not exist, leaving the
publish path governed by a record that disclaims it.

There is also a governance obstacle, and it is recorded here as a **known gap rather than solved**.
`reference/adr/README.md` defines the status lifecycle at **whole-ADR** granularity — `Proposed` →
`Accepted` → `Superseded` — and defines amendment as explicitly unable to "reverse, narrow or
re-open a *decision*." Superseding **one** of `ADR-003`'s four decisions while the other three stand
fits neither form. **This corpus has no partial-supersession form, and no record in it has ever been
superseded at all**; all nine prior records read `Accepted`.

**This record does not invent that form.** Doing so would be governance authored as a side effect of
a build slice, and by a record that does not currently need it. The gap is real, it is now written
down, and whichever work item first actually ships a partial supersession will have to establish the
form deliberately — with #719 the likely occasion.

### 9. Reversibility and confidence

| # | Decision | Reversibility | Confidence |
|---|---|---|---|
| 1 | `ADR-002` upheld | **CHEAP** — nothing is built on it yet; a later record may still revise the posture on its own evidence | **HIGH** — the argument is a straight reading of § *Decision 2*'s own scope, and this release ships a precedent for it |
| 2 | The attestation ceiling | **CHEAP** as a record; **IRREVERSIBLE** as a fact — it follows from `ADR-002` § *Decision 1*, so only a revision of the secret model could change it | **HIGH** |
| 3 | Backend rejected on merit | **MODERATE** — a re-proposal must defeat the argument rather than restate the requirement | **HIGH** on unforgeability and detectability; **MEDIUM** on the operational-cost estimate, which is a judgment |
| 4 | `internal-hard` binds attribution | **CHEAP** here; the underlying bound is not this record's to move — it belongs to `reference/data-architecture.md` § 5.1 and `ADR-009` | **HIGH** — quoted verbatim from the governing document |
| 5 | Band is `extend-seam` | **CHEAP** — a re-measurement against the shipped seam settles it either way | **HIGH** — the seam exists and is named in this release |
| 6 | Transport left unnamed, routed to #718 | **CHEAP** — #718 names it, and naming it is the whole content of that gate | **HIGH** |
| 7 | Mechanism contingent; C and D both live | **CHEAP** — *because* nothing is committed. This is the decision the scoping exists to protect | **HIGH** that neither should be picked yet; **MEDIUM** that these two are the whole surviving field once a channel is known |
| 8 | No status change to any other record | **CHEAP** — a later record supersedes `ADR-003` § *Decision 2* when a replacement rule ships | **HIGH** |

## Consequences

**Positive**

- **The server-less posture is shown sufficient for the requirement thought to break it.** `ADR-002`
  survives intact, and the doubt #88 raised against it is now answered on the record rather than
  carried forward as an open question against every future coordination slice.
- **The backend is closed on merit.** `ADR-003` deferred it on cost, which left it open to anyone
  willing to pay. Decision 3 states what it would have to buy, and it does not buy it.
- **The real blocker is named.** "Out-of-band" was a placeholder written twice, one release apart,
  and no mechanism could have been correctly specified against it. #718 exists because this record
  says so.
- **The sharpest constraint is now written where a designer will meet it.** The `internal-hard` bound
  is stronger than #88's own criterion and would have been easy to satisfy accidentally and violate
  on the next iteration.
- **Nothing is over-committed.** No cryptographic primitive, no file format, no subcommand and no
  key-custody model is decided by a record that does not yet know the channel — so none of them has
  to be walked back when the channel is chosen.

**Trade-offs**

- **#88's second, third, fourth and fifth criteria are not satisfied by this release.** They moved to
  #719 with the mechanism. The card ships its first criterion and nothing else, and the gap between
  what #88's title promises and what shipped is real.
- **The attestation ceiling caps the feature permanently.** Whatever #719 builds, an organizer can
  still bypass it by declining to run the gate. The best achievable outcome converts that from
  *undetectable* to *detectable*, and this record says so rather than implying enforcement.
- **This record decides less than a reader may want.** Someone arriving at it looking for the
  collection design will find a rejection set and a routing decision. That is the intended shape, and
  Decision 7 states why, but it is a cost.
- **A latent governance gap is now documented and still open.** The corpus cannot express a partial
  supersession, and the first work item that needs one will pay for establishing the form.
- **The candidate analysis is perishable.** C and D were scored against the repository as it stands.
  A channel that changes what a traveler can do — or a later record that revisits the secret model —
  can move the comparison, and #718 should re-read rather than adopt.

## Follow-on build slices (out of scope for this record)

- **#718** — the milestone-head design gate of *Group approval engagement layer* (#34): the channel,
  the approval interaction, the identity and attribution model, and the third-party privacy bound.
  Inherits Decisions 1 through 5 as settled.
- **#719** — individual-channel approval collection, carrying #88's second through fifth acceptance
  criteria. Blocked on #718. Replaces the body of `change_confirmation_state` at the seam #552 built;
  it does not excavate the gate around it.
- **The partial-supersession form** in `reference/adr/README.md`, established by whichever record
  first actually needs it — most likely the one that supersedes `ADR-003` § *Decision 2* when a
  replacement decision rule ships.

## References

- The card this record discharges, and its first acceptance criterion: #88, under the group-
  coordination epic (#77). Its successor for the mechanism: #719, behind the channel gate #718, in
  milestone *Group approval engagement layer* (#34).
- The posture upheld, and the three decisions the argument turns on — the local secret model, the
  fetch-scoped client-side data rule, and the fail-closed publish guard:
  `reference/adr/ADR-002-living-site-refresh.md` § *Decision 1*, § *Decision 2* and § *Decision 4*.
- The v1 coordination model, its out-of-band channel, its privacy clause, and its own statement that
  approval is not system-enforced: `reference/adr/ADR-003-group-coordination.md` § *Decision 2*,
  § *Decision 4* and § *Consequences*.
- The publish class that binds any attribution model, quoted verbatim in Decision 4:
  `reference/data-architecture.md` § 5.1, and its § 1.1 row for C12 `outputs/traveler-model.md`. The
  record that is authoritative over that model: `reference/adr/ADR-009-data-architecture.md`
  § *Decision 4*.
- The consent model any third-party channel #718 names will also engage:
  `reference/adr/ADR-006-third-party-data-capture.md`.
- The seam a collection mechanism replaces, and the gate it replaces at that seam:
  `change_confirmation_state` and `require_change_confirmation` in `scripts/publish-trip-site.sh`,
  with their regression coverage in `scripts/test-publish-guard.sh`.
- The render-side extension point for coordination state, and the shipped precedent that local
  computation over baked bytes is not a fetch: `reference/site-layout-spec.md` § 3
  *Coordination Notice*, and `reference/schemas/travel-site.md`'s `coordination-since` rationale.
- The status lifecycle and amendment rule this record follows, and the partial-supersession form it
  declines to invent: `reference/adr/README.md` § *Convention*.
