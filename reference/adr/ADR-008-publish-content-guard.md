# ADR-008: Publish-path content guard — a value-keyed predicate on the plaintext limb

- **Status:** Accepted (2026-08-23); Decision and Coverage boundary amended the same day after an
  independent adversarial design review confirmed four defects in the first implementation — the
  guard matched the visible-text projection rather than the published bytes, the name arm applied no
  stoplist, the class bound to a `[DERIVED]` cache with no freshness check, and the conjunctive window
  was calibrated on a single-occurrence fixture. The architecture below is unchanged; its **scope** is
  corrected, and the coverage boundary now states the measured boundary rather than the intended one.
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

**1. `nonpublishable_values <trip_dir> [site_html]` — the single home of the class.** It emits one
record per non-publishable value: `<member>` (`passport` or `third-party`), `<field>` (a locator),
`<rule>`, and the value. It returns `0` when the class is enumerated — *possibly empty* — and `2`
when the class cannot be determined. The `Passport:` label, `Category:` values, `Applies to:` link
text, and every field of a non-`[THIRD-PARTY]` entry other than `Passport:` are excluded **as
non-members**, which is the whole anti-over-block mechanism and is why the designed escalation path
for a first-party `[OPERATOR-PROVIDED]` need stays open. This function is the seam #278 re-keys:
swapping the membership rule for a declared attribute is a change to this body alone.

It reads **two sources, not one**. `outputs/traveler-model.md` is a `[DERIVED]` projection —
`CLAUDE.md` makes `travelers/<traveler>.md` authoritative and has the enrichment agent refresh the
model from those files whenever they change — so the Passport member is read from the per-traveler
files as well. `[THIRD-PARTY]` members are read from the model alone, because such a subject has no
file anywhere by construction. Binding only to the projection was measured to publish a passport that
was sitting in `travelers/rowan.md` at `rc=0`, reporting the class as *genuinely empty*: a silent
fail-open wearing the costume of a clean determinate measurement.

The projection is also **checked for freshness**, using this file's own `_epoch_of_file` / `_is_stale`
idiom — the one `cmd_list` already uses to flag a locally-rebuilt site against its deployment. A
per-traveler profile newer than the model is `2`, because the model has not absorbed it. An **empty**
class read from a model that predates the render is `2` as well, because that is the exact shape of
the measured fail-open. The second rule is deliberately conditioned on emptiness: in the normal
authoring order the render is written *after* the model, so an unconditional "render newer than
model" gate would refuse every correct publish rather than more of them, and an unusable fail-closed
control becomes fail-open in practice.

**2. The match rule travels *with* the record, assigned at membership time.** Membership and
matchability are one decision, so they are made in one place — which is what leaves the predicate a
pure consumer with no class knowledge.

| Member | Shape | Match rule |
|---|---|---|
| `Passport` value | short structured field | every distinctive token of the value must appear, and the occurrences must fall inside a 25-word window **within one structural block**; fewer than 2 distinctive tokens is undetermined |
| `[THIRD-PARTY]` need text | prose | contiguous 5-word containment; a pure-stopword window is not a key; under 5 words is undetermined |
| `[THIRD-PARTY]` name | proper noun | whole-word match, **stoplisted like its two siblings**; a name that reduces to no distinctive token is a *declared non-key* |

The block scoping and the stoplist on the name arm are both corrections, not refinements. The
25-word window alone was calibrated on a fixture carrying **one** occurrence of each token; a real
itinerary repeats both, so an N-day trip offers N² candidate pairings and a day-boundary pairing
lands inside 25 words. Measured: `Passport: Irish, valid to 2027` against a clean render that
mentions an Irish pub each day under 2027 date headings aborts **from two days onward and never
recovers**, while the same render with a 2033 validity publishes — isolating the cause to token
recurrence. A flat word window cannot tell *both facts in one sentence* from *one fact at the end of
Tuesday and the other in Wednesday's heading*; a block boundary can. Likewise `is_stop` was called in
the conjunctive and phrase branches but not the token branch, so a member named **Will** — a word in
this guard's own stoplist — aborted every publish of that trip, permanently, with no remedy that did
not require deleting the record the guard exists to protect.

A **single** rule across the whole class was tried first and falsified: a passport value is 2–5 words
*by construction*, so a uniform word-count floor makes every plaintext publish undetermined — forever,
for every trip. The conjunctive rule is also strictly more sensitive for that member than containment
would be: it catches a reworded ("… passport valid until 2033") and an order-swapped ("2033 is the
expiry on her … document") carry-through that no contiguous run would match, while still passing a
clean render that says "passport" three times. Both parameters were chosen on a measured sweep rather
than by taste, and both discriminate: at a floor of 3 an incidental run aborts a clean render; with an
unbounded window an innocent render that mentions one token early and the other late flips to a false
abort.

**3. `verify_publishable_content <site_html> <trip_dir>` — a pure consumer, matching two projections.**
It returns `0` (nothing non-publishable reached the published file), `1` (a hit), or `2`
(undetermined). Three codes where the sibling guard has two, because the regression suite has to tell
a *hit* from an *undetermined*: under a binary contract a guard that aborted for the wrong reason
would still pass its own tests. The call site collapses both non-zero codes into one `die`, so the
command's behaviour stays binary.

**The evaluand is the published file, not the painted page.** `cmd_publish` copies the whole file, so
each record is matched against *two* projections of it and a hit on either is a hit:

| Arm | Projection | Covers |
|---|---|---|
| visible | `strip_to_text_blocks` | text nodes — what a reader sees |
| published | `strip_to_published_text` | HTML comment bodies, every attribute value, `<script>`/`<style>` bodies |

Together these cover every content-bearing byte; what neither covers is tag names and attribute
names, which are machinery and carry no trip content. Matching only the visible projection was
measured to publish a class value carried in a comment, a meta description, an img alt, an inline
script, an aria-label, a style comment, or a `data-*` attribute — **7 of 8 surfaces tried**. (The
eighth, `<title>`, is visible text and was already caught.) Two of the seven — the img `alt` and the
meta description — are read aloud by assistive technology and shown in every link preview, so they
are not even hidden. This is `verify_ciphertext` check (d)'s own idiom: that check greps the **raw
bytes** precisely because the visible projection is not what gets published. (d) mitigates its
false positives by subtracting a content-free decoy built by `make_boilerplate` from the same
StatiCrypt build; this repo has no site build to run a decoy through, so the same subtraction is made
**structurally** — tag names and attribute names are dropped at extraction rather than differenced
away afterwards.

Fail-closed means `2` — abort — when the traveler model is absent, is not a readable regular file, is
empty, or parses with **zero `## <Name>` entries recognized**; when a per-traveler profile is newer
than the model, or is unreadable, or either mtime cannot be read; when the class reads empty from a
model older than the render; when a class value is below its rule's keyability floor; and when the
render is unreadable or yields under 20 words of visible text. But a model that **parses with a
genuinely empty class, and is not stale, returns `0` and publishes**. That distinction is
load-bearing: a parsed-and-empty class is a *measurement*, an unrecognized or stale file is a
*degradation*, and collapsing them would make a broken parser indistinguishable from a trip that has
nothing to hide.

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
  A fail-open inside a fail-closed guard is the wrong trade, whatever it buys. The one narrowing made
  is the stoplist now shared with the other two arms, and it is a **declared non-key** rather than a
  silent skip — see residual 2 below. A name that is merely *uncommon* still keys and can still
  over-block; that remains accepted.
- The guard's parser binds to field labels (`## <Name>`, `[THIRD-PARTY]`, `Passport:`, `Specific:`)
  that are guaranteed only by agent prose in `agents/00-enrichment.md` and
  `templates/traveler-intake.template.md`; no schema pins them. A total format drift is caught loudly
  by the zero-entries rule. A **partial** drift — one label renamed while the entry heading still
  parses — degrades quietly. Reading the per-traveler profiles widens this surface slightly: the
  profile parse binds to the same `Passport:` label and has no zero-entries backstop of its own, since
  a trip with no profiles is legitimate. This is a named residual and a strong candidate for what #278
  makes structural.
- The suite now runs in CI with a strict skip mode, so a transient npm-registry outage turns the check
  red. Accepted deliberately: the alternative is a green that proves less than it appears to.

**Coverage boundary — the part most likely to be forgotten and then over-claimed**

This section states the **measured** boundary. Every claim in it is pinned by a case in
`scripts/test-publish-guard.sh` groups L, M and N, each with a control arm, because a boundary that is
asserted rather than measured is the thing this section exists to prevent.

**What is caught.** A class value anywhere in the published bytes — visible text, an HTML comment, any
attribute value, a `<script>` or `<style>` body — on any of the 8 surfaces measured (group M1). A
value that reaches the render **de-attributed**, with the traveler name stripped, by construction:
the name was never the join key, so removing it changes nothing (L3). A passport value that is
reworded or order-swapped **within one block** (N1d). A passport that exists only in
`travelers/<traveler>.md` and has not reached the projection yet (M3d). A projection that is stale
against its first-party sources, or that reads empty while predating the render (M3b).

**What is not caught, and why. Four residuals, all deliberate:**

1. **Paraphrase.** A value the hub **reworded** on its way into `final-itinerary.md` breaks every
   n-gram and is **missed**. The class definition names one transform — *the name stripped* — and
   that one is covered completely; a paraphrase is a judgement no string match can make. #278 states
   the same limit in its own words, and that is the reason #278 exists.
2. **A stopword-only third-party name (new).** `is_stop` now applies to the name arm as it always did
   to the other two, so a member named **Will** is a *declared non-key* and their name reaching the
   render is not caught here. This is a bounded fail-open on the **name arm only** — the value arm,
   which is what the validator's anonymized-form clause is actually about, is untouched, and the need
   text is still matched whether attributed or de-attributed. It is deliberate: the alternative was a
   permanent, unremediable abort on every publish of that trip, and an unusable fail-closed control is
   fail-open in practice because it gets worked around. Note the residual is **narrowed, not solved**:
   `_GUARD_STOP` is normalization vocabulary, not a list of names, and it was **not** extended here, so
   May, Art, Grace and Rosa still key — and can still over-block.
3. **A passport value split across two structural blocks (new).** Scoping the conjunctive window to a
   block is what stops a clean multi-day itinerary aborting forever, and it costs this: a value whose
   two facts land in different blocks — say adjacent table cells — no longer pairs. A carry-through
   into prose, which is the realistic shape, sits in one block and is still caught (N1d).
4. **Tag names and attribute names.** Neither projection covers them. They are markup machinery and
   carry no trip content; this is the structural form of `verify_ciphertext`'s boilerplate
   subtraction, and it is what stops the published-bytes arm aborting on ordinary CSS and script
   (M1d). A render containing the literal sentinel `zzguardblockzz` would split a block that should
   not have split — a missed match, never a false abort.

**This layer does not subsume the validator's audit.** Three layers hold this invariant and they are
not interchangeable:

| Layer | Surface | Artifact audited | When | Catches paraphrase? |
|---|---|---|---|---|
| 1 — agent judgement | `agents/06-validator.md` | the five § 9.1 publish-bound sources | at validation | yes, judged |
| 2 — **this guard** | `verify_publishable_content` | the **published file**, both projections | at every publish | **no** |
| 3 — structural (#278) | a declared field attribute | the build's field selection | by construction | n/a — prevented, not detected |

The validator's dynamic-set clause — *"if the site build ever reads a new source, that source joins
this audit set"* — governs the **sources**; this guard governs the **published file**. Shipping layer
2 does not discharge layer 1, and a future reader should not conclude that it does — least of all for
residuals 1 to 3 above, where layers 1 and 3 are the only cover.

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
  `scripts/test-publish-guard.sh` groups **L** (the predicate and its class source), **M** (published
  bytes, the name-arm stoplist, class freshness) and **N** (the block-scoped conjunctive window),
  `.github/workflows/publish-guard.yml`.
- First-party source of the Passport member, and the label shape the profile parse binds to:
  `templates/traveler-intake.template.md`; the `[DERIVED]` status of the projection and the
  refresh contract: `CLAUDE.md` → *Satisfaction-layer artifacts*.
