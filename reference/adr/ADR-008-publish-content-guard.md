# ADR-008: Publish-path content guard — a value-keyed predicate on the plaintext limb

- **Status:** Accepted (2026-08-23)
- **Deciders:** repo maintainer
- **Driving work:** #123, the plaintext content guard. Establishes the mechanism, the class-source
  seam that #278 later re-keys, and — above all — the coverage boundary this layer does and does
  not hold. Discharges the sequencing constraint `ADR-007` § 4 places on the publish-addressing
  slice (#266).

## Context

`scripts/publish-trip-site.sh` has two publish limbs. The encrypted limb runs `verify_ciphertext`
immediately before every push, and `cmd_update` runs it again on every re-publish. The
`--plaintext` limb — the one whose output is immediately world-readable, with no passphrase in
front of it — copies the rendered HTML straight into the publish directory with **no content
inspection at any point**. The guarded limb is the one that needed guarding least.

The obvious remedy, calling the existing guard from one more place, does not work. `verify_ciphertext`
is a *ciphertext* predicate — "is this encrypted?" — not a *content* predicate — "is this safe to
publish?". All four of its checks invert on plaintext input:

| Check | Requires | On a plaintext publish |
|---|---|---|
| (a) | StatiCrypt encrypted-payload markers | absent → fails |
| (b) | a passphrase prompt | absent → fails |
| (c) | visible text ≤ 200 chars | an itinerary runs to hundreds+ → fails |
| (d) | no source token appears in the output | on plaintext the source **is** the output → fails |

`scripts/test-publish-guard.sh` case A already encodes this: it asserts that certifying the
plaintext source as its own ciphertext **must fail**. Wiring the old guard into the plaintext limb
would abort every plaintext publish — removing the feature rather than guarding it.

The class of content that must not be published is defined in `agents/06-validator.md`, in prose, and
holds exactly two members today: a traveler's **Passport** value (issuing country and validity —
`reference/data-model.md` fixes it at "country + validity only — never a number"), and **every
`[THIRD-PARTY]`-marked value** in `outputs/traveler-model.md`, which describes a party member who was
never able to consent to the record, let alone its publication (`ADR-006`).

That definition pulls in two directions at once, and both pulls are explicit:

- It requires the **anonymized** form to be caught — *"a rest floor or a walking ceiling that reaches
  a published artifact with the name stripped is still a finding"*. In a small named party, stripping
  the name does not strip the identification.
- It **forbids** keying on the word "passport". The check binds to *"a specific traveler's captured
  value"*, and destination-level guidance that belongs on a published plan — a packing-list line,
  tax-free-shopping notes, the `Visa / entry` requirements enriched into `trip-context.md`
  `## Destination Baseline` — *"is correct content and is never flagged"*.

A keyword scan fails the second. A name-keyed scan fails the first. The mechanism has to satisfy both
at once, and that — not the call site — is the whole difficulty.

One further constraint shapes the choice. Publishing is irreversible in practice: content persists in
third-party caches and clones after a takedown, which is why `unpublish` says so in its own output.
The guard therefore has to be fail-closed in the strong sense — an *undetermined* result is a failure,
never a clean pass — which is the rule `agents/06-validator.md` already states for the same class.

## Decision drivers

- **Fail-closed on an irreversible action.** A false abort costs a re-run; a false pass publishes a
  passport value to the open web permanently. The file states the doctrine itself: *"A false abort is
  safe; a false pass leaks — bias to abort."*
- **The class needs exactly one home.** #278 will replace the membership rule with a declared
  publishability attribute. A guard that scatters class knowledge across its matching logic cannot
  absorb that change without a rewrite.
- **This layer must not become a second definition of the class.** The validator's audit and this
  guard read different artifacts at different times; the guard is a second layer, not a replacement.
- **It has to run where the publish runs.** The plaintext limb is an operator action in a terminal,
  never a Claude action (`ADR-007` § 2). There is no agent session to call and no network to rely on.
- **It must not print what it matches.** #123's AC 8 routes the regression suite into a GitHub Actions
  log on a public repository, and the strings this guard matches are passport values and third-party
  health needs.

## Options considered

1. **Marker scan** — scan the render for the literal marks (`[THIRD-PARTY]`, the label `Passport:`,
   the word "passport"). **Rejected.** *Kill-reason: it breaches the class definition in both
   directions at once.* It flags a legitimate packing-list line, a tax-free-shopping note and the
   `Visa / entry` baseline — all three of which the validator names explicitly as content that is
   never a finding — and it **misses** the anonymized carry-through, which by construction carries no
   marker at all. A predicate that over-blocks correct content *and* misses the named finding is not a
   cheaper option; it is a non-conforming one.

2. **Delegate to the validator agent** — invoke the `agents/06-validator.md` profile-privacy audit at
   publish time, or gate on the verdict it recorded in `outputs/validation-report.md`. **Rejected.**
   *Kill-reason: three independent breaches, any one of them fatal.* **(i) Not invocable** — the
   plaintext limb is a bash script an operator runs in their own terminal; there is no agent session
   for it to call. **(ii) Not deterministic** — a probabilistic judge fails in both directions under a
   fail-closed requirement: unreachable means every publish aborts, and a hallucinated "clean" is a
   silent fail-open in the only control standing on this limb. **(iii) Wrong artifact, wrong time** —
   the validator audits the five publish-bound *sources* named in `reference/site-layout-spec.md` § 9.1;
   this guard must certify the *render*, and `CLAUDE.md` routes a site tweak to a direct edit of the
   HTML with no agent involved, so the render can change after the last validation pass. The
   `validation-report.md` variant fails on (iii) alone: it certifies a different artifact at an
   earlier time.

3. **Value-keyed extraction and match** — read the class's own home, extract each traveler's captured
   *values*, and match those values against the render. **Chosen — see below.**

## Decision

**The predicate is keyed by the traveler's captured value, and the traveler's name is only ever
another member of the value set — never the join key.** That single choice dissolves the tension in
the class definition. The word "passport" is never a key, so a packing-list line and a `Visa / entry`
note are *structurally outside the class* rather than stoplisted after the fact — they were never
members. And the anonymized form is caught precisely *because* the name was never the join key:
strip the name from a rest floor and the value is unchanged, so the match is unchanged.

Four parts, all in `scripts/publish-trip-site.sh`:

**1. `nonpublishable_values <trip_dir>` — the single home of the class.** It emits one record per
non-publishable value: `<member>` (`passport` or `third-party`), `<field>` (a locator), `<rule>`, and
the value. It returns `0` when the class is enumerated — *possibly empty* — and `2` when the class
cannot be determined. The `Passport:` label, `Category:` values, `Applies to:` link text, and every
field of a non-`[THIRD-PARTY]` entry other than `Passport:` are excluded **as non-members**, which is
the whole anti-over-block mechanism and is why the designed escalation path for a first-party
`[OPERATOR-PROVIDED]` need stays open. This function is the seam #278 re-keys: swapping the
membership rule for a declared attribute is a change to this body alone.

**2. The match rule travels *with* the record, assigned at membership time.** Membership and
matchability are one decision, so they are made in one place — which is what leaves the predicate a
pure consumer with no class knowledge.

| Member | Shape | Match rule |
|---|---|---|
| `Passport` value | short structured field | every distinctive token of the value must appear, and the occurrences must fall inside a 25-word window; fewer than 2 distinctive tokens is undetermined |
| `[THIRD-PARTY]` need text | prose | contiguous 5-word containment; a pure-stopword window is not a key; under 5 words is undetermined |
| `[THIRD-PARTY]` name | proper noun | whole-word match; always keyable |

A **single** rule across the whole class was tried first and falsified: a passport value is 2–5 words
*by construction*, so a uniform word-count floor makes every plaintext publish undetermined — forever,
for every trip. The conjunctive rule is also strictly more sensitive for that member than containment
would be: it catches a reworded ("… passport valid until 2033") and an order-swapped ("2033 is the
expiry on her … document") carry-through that no contiguous run would match, while still passing a
clean render that says "passport" three times. Both parameters were chosen on a measured sweep rather
than by taste, and both discriminate: at a floor of 3 an incidental run aborts a clean render; with an
unbounded window an innocent render that mentions one token early and the other late flips to a false
abort.

**3. `verify_publishable_content <site_html> <trip_dir>` — a pure consumer.** It returns `0` (nothing
non-publishable reached the render), `1` (a hit), or `2` (undetermined). Three codes where the sibling
guard has two, because the regression suite has to tell a *hit* from an *undetermined*: under a binary
contract a guard that aborted for the wrong reason would still pass its own tests. The call site
collapses both non-zero codes into one `die`, so the command's behaviour stays binary.

Fail-closed means `2` — abort — when the traveler model is absent, is not a readable regular file, is
empty, or parses with **zero `## <Name>` entries recognized**; when a class value is below its rule's
keyability floor; and when the render is unreadable or yields under 20 words of visible text. But a
model that **parses with a genuinely empty class returns `0` and publishes**. That distinction is
load-bearing: a parsed-and-empty class is a *measurement*, an unrecognized file is a *degradation*, and
collapsing them would make a broken parser indistinguishable from a trip that has nothing to hide.

**4. The abort names the member and a locator, and never echoes the value.** This deliberately diverges
from `verify_ciphertext`, which prints the token it matched. Under AC 8 this suite runs in a public
Actions log, so echoing would make the guard leak exactly what it exists to protect. The report does
not name the traveler either — a `[THIRD-PARTY]` entry's *name* is itself a member of this class, so
naming the person would be the same leak by another route.

The guard is called once, in the plaintext limb, **before** the typed-`PUBLISH` confirmation and
before anything is copied to the publish directory. Before the prompt rather than after: either
placement satisfies "nothing is copied", but asking someone to type `PUBLISH` and *then* refusing
trains the operator to read the prompt as noise. `verify_ciphertext` is unchanged, and still guards
the encrypted limb of `publish` and all of `update`.

## Consequences

**Positive**

- The unguarded limb is guarded, and it is the limb whose output is immediately world-readable.
- The two directions of the class definition are satisfied **by construction** rather than by a
  stoplist: correct destination-level content was never a member, and de-attribution changes nothing
  because the name was never the key.
- The class has one home with a stable contract, so #278 re-keys it in a single function body — the
  predicate, the call site and every test assertion are untouched.
- `verify_ciphertext` is not read, called or edited by any of this, so the encrypted limb's behaviour
  is unchanged by construction rather than by testing.
- The trust boundary `ADR-007` § 4 deferred can now open: the control that was missing exists, and the
  publish-addressing slice (#266) is unblocked.

**Trade-offs, and one is a real cost**

- **A trip whose non-publishable class cannot be determined cannot be plaintext-published.** That is
  the correct direction and it is cheap to remedy — `--plaintext` is the opt-out from the privacy
  default, the encrypted path is unaffected, and the remedy is to publish encrypted, which is what the
  system wants anyway. A trip that never ran enrichment cannot opt out of encryption.
- **False positives are accepted, and one is known.** A third-party member's name is matched
  whole-word, so a person whose name coincides with a venue on their own trip aborts the publish. The
  obvious fix — subtracting venue names from a trip-specific corpus — was **rejected**: that corpus is
  trip-specific, so it would silently remove from the class exactly the person most likely to collide.
  A fail-open inside a fail-closed guard is the wrong trade, whatever it buys.
- The guard's parser binds to field labels (`## <Name>`, `[THIRD-PARTY]`, `Passport:`, `Specific:`)
  that are guaranteed only by agent prose in `agents/00-enrichment.md`; no schema pins them. A total
  format drift is caught loudly by the zero-entries rule. A **partial** drift — one label renamed while
  the entry heading still parses — degrades quietly. This is a named residual and a strong candidate
  for what #278 makes structural.
- The suite now runs in CI with a strict skip mode, so a transient npm-registry outage turns the check
  red. Accepted deliberately: the alternative is a green that proves less than it appears to.

**Coverage boundary — the part most likely to be forgotten and then over-claimed**

**De-attribution is caught. Paraphrase is not.** The class definition names one transform — *the name
stripped* — and that one is covered completely and by construction. A value the hub **reworded** on its
way into `final-itinerary.md` breaks every n-gram and is **missed**. This is not a defect being
conceded quietly; #278 states the same limit in its own words — detecting a paraphrase is a judgement
no string match can make — and that is the reason #278 exists.

**This layer does not subsume the validator's audit.** Three layers hold this invariant and they are
not interchangeable:

| Layer | Surface | Artifact audited | When | Catches paraphrase? |
|---|---|---|---|---|
| 1 — agent judgement | `agents/06-validator.md` | the five § 9.1 publish-bound sources | at validation | yes, judged |
| 2 — **this guard** | `verify_publishable_content` | the **render** | at every publish | **no** |
| 3 — structural (#278) | a declared field attribute | the build's field selection | by construction | n/a — prevented, not detected |

The validator's dynamic-set clause — *"if the site build ever reads a new source, that source joins
this audit set"* — governs the **sources**; this guard governs the **render**. Shipping layer 2 does
not discharge layer 1, and a future reader should not conclude that it does.

## References

- The gap this closes, and its acceptance criteria: #123. The class re-key that supersedes the
  membership rule here: #278. The slice this unblocks: #266.
- Class definition (both members, the anonymized clause, the never-a-finding clause, and the
  fail-closed rule): `agents/06-validator.md` → *Profile-privacy non-publication*.
- Field shapes the parser binds to: `agents/00-enrichment.md` and `reference/data-model.md` → *Needs*,
  *Lifecycle facets*.
- Publish-bound artifact set and its intentional exclusions: `reference/site-layout-spec.md` § 9.1 / § 9.3.
- Consent model for third-party capture: `ADR-006-third-party-data-capture.md`.
- The operator-only bound on the plaintext limb, and the deferred trust boundary:
  `ADR-007-command-entry-point.md` § 2 and § 4.
- Implementation and regression coverage: `scripts/publish-trip-site.sh`,
  `scripts/test-publish-guard.sh` group L, `.github/workflows/publish-guard.yml`.
