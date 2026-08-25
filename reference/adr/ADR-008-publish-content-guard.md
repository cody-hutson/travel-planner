# ADR-008: Publish-path content guard — a value-keyed predicate on the plaintext limb

- **Status:** Accepted (2026-08-23); Decision and Coverage boundary amended **three times** the same
  day.
  **First amendment** — an independent adversarial design review confirmed four defects in the first
  implementation: the guard matched the visible-text projection rather than the published bytes, the
  name arm applied no stoplist, the class bound to a `[DERIVED]` cache with no freshness check, and
  the conjunctive window was calibrated on a single-occurrence fixture.
  **Second amendment** — acceptance review found the `[THIRD-PARTY]` half of the class substantially
  inert against real data, on three compounding fail-open gaps: the arm was a two-**field allowlist**
  where `reference/data-model.md:170` states an entry-class bound with *no default-allow*; the
  `[THIRD-PARTY]` mark was read only off the **entry heading**, though `agents/00-enrichment.md:407`
  requires it on every value and `:468-473` names heading mark-stripping as a known agent error; and
  the field it did match, `Specific:`, is the **profile** label, bound against the **derived** file.
  **Third amendment** — a Stage 9 re-gate found two documentation defects and took one scope
  decision. The defects: this document, and the shipped source comment it is repeated in, both stated
  the exit-4 fail-open as reaching *"the name arm only"*, which the entry-denylist change had already
  falsified against this document's own rule table; and the Coverage boundary stated the closed-enum
  exclusion as `Category:`-scoped while the Decision section stated it, correctly, as field-blind. The
  decision: **#123's AC 3 is narrowed to the Passport member**, so the `[THIRD-PARTY]` arm — which
  ships and fires as described — is no longer claimed as **complete** coverage of that member
  (residual 8).
  The architecture below — value-keying, the class-source seam, the 0/1/2 contract — is unchanged
  through all three. Its **scope** is corrected, and the coverage boundary states the measured
  boundary rather than the intended one. Where any amendment disagreed with an earlier claim in this
  document, the claim is **corrected in place**, not softened.
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
when the class cannot be determined. This function is the seam #278 re-keys: swapping the membership
rule for a declared attribute is a change to this body alone.

**The `[THIRD-PARTY]` member is an entry denylist, not a field allowlist**, and the polarity is the
correction that matters most here — because it is the polarity #278 inherits. Under a
`[THIRD-PARTY]` entry, **every stated field value is in class**, which is what
`reference/data-model.md:170` says in its own words: *"The bound is the entry class, not a list of
fields, so it holds for every facet below and for any facet a later release adds … there is no
default-allow outside it."* The first implementation enumerated exactly two things per entry — the
heading name and the value of a line labelled `Specific:` — so every other field default-**allowed**.
Excluded **as non-members**, and this is the whole list: the `Passport:` **label**; the `Applies to:`
link in both its parenthesized derived form and its standalone profile form, together with the quoted
constraint name in the derived need-line head (`data-model.md:139` — *"This is the link, **never a
copy** of the constraint text"* — its target lives in the publish-bound `trip-context.md`, so keying
on it would abort on correct published content); a value made **entirely** of the closed
need-category enum, which is schema vocabulary rather than a captured value; and every field of a
non-`[THIRD-PARTY]` entry other than `Passport:`, which is why the designed escalation path for a
first-party `[OPERATOR-PROVIDED]` need stays open.

**The parse binds to the entry, not to a label — because the corpus does not specify one.** The
label the first implementation used, `Specific:`, is the **profile** label. Measured over this
repository: line-anchored, it occurs 3× in `reference/data-model.md`, all three under
`# Traveler — Jordan` / `# Traveler — Pat` (i.e. `travelers/<name>.md`), and 2× in
`templates/traveler-intake.template.md`, which governs that same profile — and **0×** in
`agents/00-enrichment.md`, the spec that *writes* the derived model, and **0×** in
`agents/06-validator.md`, which defines the class. The derived model's own worked example
(`data-model.md:266-283`) writes a need as
`- Need → Hard Constraints "<c>" (Applies to: <n>); specific: <v>.` — a **mid-line, lowercase**
label, 4 occurrences, none line-anchored. The guard was parsing the derived file with the profile's
label.

The deeper finding is that a third-party need's line shape is **underspecified**, and that is what
decides the design rather than a second label. A third-party need cannot carry the first-party
derived shape at all: `data-model.md:143` bars it from ever escalating to a trip-level constraint or
onto an `Applies to:` roster, and `agents/06-validator.md:231-243` says it *"by design has no
governing trip-level constraint to key to"*. So the link head and the `Applies to:` are both
unavailable to it, and what remains — a category and a specific — is serialized nowhere. Probed
across every `.md` in the repository: of 44 fenced example blocks, 12 carry a `## <Name>` heading and
**0** carry a `[THIRD-PARTY]` entry. There is no worked example to bind to. Any label binding is
therefore a guess, and a guard bound to a guessed shape is the defect this replaces. The entry
denylist needs no label: it strips the link constructs and an optional label prefix, then takes
whatever the line states — which reads the derived need line, the profile-style block and a bare
bullet identically. **This is a finding about the corpus, not only about the guard**, and #278 is
where it becomes structural.

**The mark is read at both granularities, and the ordering is load-bearing.** `[THIRD-PARTY]` is
consulted on the entry heading **and** on each value line, as a union.
`agents/00-enrichment.md:407` requires the mark on *"every value sourced this way"*, and `:468-473`
names heading mark-stripping as a **known agent error** that *"silently strip[s] the key the
publication guard depends on"* — the exact state in which a heading-only read enumerates zero
third-party records and publishes. The value-level mark is read off the **raw** line, *before*
`clean()` runs: `clean()` deletes every bracketed provenance mark as metadata, so a mark consulted
after it has already been erased. Two backstops sit behind this. A `[THIRD-PARTY]` mark present in
the file that resolves to **no** class record is `2` — an unresolved *presence* is no more an empty
class than an absence is. And a recorded third-party **supersession** with no per-traveler profile to
support it is `2`: the sanctioned provenance change is triggered by the person filing their own
profile (`00-enrichment.md:456-466`), so a supersession with no profile behind it is
indistinguishable from the bad merge `:467-473` forbids by name.

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
| `[THIRD-PARTY]` field value, ≥ 5 words | prose | contiguous 5-word containment; a pure-stopword window is not a key |
| `[THIRD-PARTY]` field value, < 5 words | short field | whole-phrase whole-word match; a value with no distinctive token is a *declared non-key* |
| `[THIRD-PARTY]` name | proper noun | whole-word match, **stoplisted like its two siblings**; a name that reduces to no distinctive token is a *declared non-key* |

**The rule is chosen from the value's own word count, and that is a mitigation rather than a
preference.** Under an entry denylist most third-party fields are short, and the prose rule reports
anything under five words as *below its keyability floor* — which the predicate surfaces as
UNDETERMINED, aborting **every** publish of that trip forever, with no remedy. That is the unusable
fail-closed control this document already argues against in the name-arm note below, and it would
have arrived as a side effect of widening the class. Two things prevent it: the short branch above,
which is determinate on a short value; and the closed-enum exclusion, which keeps a `Category:` line
from keying on `rest`, `timing` or `other` and aborting on ordinary itinerary English. A category
carrying text **beyond** the enum is a captured value and still keys. `Category:` is the *example*,
not the scope: the exclusion is **field-blind** — it tests the value text alone and applies under any
label. See the Coverage boundary, where scoping it to `Category:` is recorded as the wrong fix.

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
- **De-attribution** is handled by construction: the name was never the join key, so stripping it
  changes nothing about the match (L3).
- **Correct destination-level content is a non-member by construction — and that is a statement about
  MEMBERSHIP, not about OUTCOME.** An earlier revision of this document claimed both directions of
  the class definition were satisfied "by construction rather than by a stoplist", with destination
  content *"never a member"*. The membership half is true and is the mechanism's real achievement:
  the word "passport" is never a key, so a packing-list line and a `Visa / entry` note are outside
  the class rather than stoplisted after the fact. **The outcome half is false, and measurement
  contradicts it.** The *matcher* re-introduces the over-block the *membership* design was built to
  prevent: 3 of 3 renders carrying both Passport tokens inside one legitimate structural block
  falsely abort, against 2 of 2 controls that publish — and one of the three is a `Visa / entry`
  line, the exact class `agents/06-validator.md:145-147` names as *"correct content [that] is never
  flagged"*. It is fail-**closed**, so it leaks nothing; it is a false abort on protected content,
  and this document's own argument at the name-arm note — *an unusable fail-closed control is
  fail-open in practice, because it gets worked around* — applies to it unchanged. It is **open and
  undispositioned**, carried as residual 6 below rather than claimed as solved.
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
- The guard's parser binds to structural markers (`## <Name>`, `[THIRD-PARTY]`, `Passport:`) that are
  guaranteed only by agent prose in `agents/00-enrichment.md` and
  `templates/traveler-intake.template.md`; no schema pins them. The third-party arm no longer binds
  to a **need-field label** at all — it takes what an entry's lines state — precisely because the
  corpus specifies no such label for this artifact, and the first implementation guessed one and
  guessed wrong. That removes the largest instance of this residual without removing the residual: a
  total format drift is still caught loudly by the zero-entries rule, and a **partial** drift — the
  `Passport:` label renamed, or the `## <Name>` heading form changed — still degrades quietly.
  Reading the per-traveler profiles widens the surface slightly: the profile parse binds to the same
  `Passport:` label and has no zero-entries backstop of its own, since a trip with no profiles is
  legitimate. **That an entry-class bound had to be inferred from prose in three separate documents,
  with no worked example of the entry it governs, is itself the finding** — and it is a strong
  candidate for what #278 makes structural.
- The suite now runs in CI with a strict skip mode, so a transient npm-registry outage turns the check
  red. Accepted deliberately: the alternative is a green that proves less than it appears to.

**Coverage boundary — the part most likely to be forgotten and then over-claimed**

This section states the **measured** boundary. Every claim in it is pinned by a case in
`scripts/test-publish-guard.sh` groups L, M, N and O, each with a control arm, because a boundary
that is asserted rather than measured is the thing this section exists to prevent. An acceptance
review found the previous revision of this section diverging from the measurement in **six** places —
five silent omissions and one affirmative claim the measurement contradicted. All six are corrected
here: three by fixing the guard (the field allowlist, the heading-only mark, the model-shape
mismatch) and three by stating a residual that was previously absent or under-described (encoding
transforms, the same-block over-block, the line-based floor).

A **second** acceptance review, run on the revision that made those corrections, found six further
divergences and **two internal self-contradictions** — a section written to state the measured
boundary had come to disagree with the Decision section above it. Both self-contradictions are
corrected in the third amendment: the field-blind enum exclusion, immediately below, and the exit-4
scope, in residual 2. **Four divergences remain open and are named rather than fixed**, because the
Stage 9 re-gate scoped that amendment to the false statements and the self-contradictions. They are
listed here so this section does not read as complete: the `Applies to:` exclusion is **label-bound**,
so identical constraint text under any other label falsely aborts; the third-party supersede detector
is a loose whole-file two-substring test, and its `exit 5` also short-circuits a genuine hit into
UNDETERMINED; a **fully silent** mark strip — both marks gone, no supersession recorded, a real
profile present — returns `0` and appears in none of the residuals below; and the line-based floor
mitigation flipped a short value with partial carry-through from abort to publish. The first two are
fail-**closed** (false aborts); the last two are fail-**open**.

**What is caught.** A class value anywhere in the published bytes — visible text, an HTML comment,
any attribute value, a `<script>` or `<style>` body — on any of the 8 surfaces measured (group M1). A
value that reaches the render **de-attributed**, with the traveler name stripped, by construction:
the name was never the join key, so removing it changes nothing (L3). **Any** stated field of a
`[THIRD-PARTY]` entry, not a nominated subset of them (O1). A third-party value whose entry-heading
mark has been stripped but whose value-level mark survives (O2). A third-party need written in the
**real derived-model shape** rather than the profile shape (O3). A bad merge that strips both marks
while retaining the values, and a `[THIRD-PARTY]` mark that resolves to no record — both as
UNDETERMINED (O4b, O4c). A passport value that is reworded or order-swapped **within one block**
(N1d). A passport that exists only in `travelers/<traveler>.md` and has not reached the projection
yet (M3d). A projection that is stale against its first-party sources, or that reads empty while
predating the render (M3b).

**What is deliberately NOT in class**, each pinned by a control arm that must publish: a first-party
`[OPERATOR-PROVIDED]` need, whose escalation to `trip-context.md` is the designed path (O5b, O3c); a
field value under an **unmarked** entry (O1c); and **any** value, under **any** label, that reduces
entirely to the closed need-category enum. That exclusion is **field-blind**, exactly as the Decision
section states it: `enum_only()` takes only the value text, and no field parameter is passed or
consulted, so `- Specific: heat` and `- Trigger: rest` are out of class on the same footing as
`- Category: rest`. An earlier revision of this section wrote it as *"a `Category:` value"* — a
narrower boundary than the one that ships, wrong in the **fail-open** direction, and in direct
contradiction of the Decision section above. O6b/O6c pin only the `Category:` case, so the suite
measures the narrow reading and not the shipped one.

**Scoping that exclusion to `Category:` is the obvious fix, and it is wrong.** Recorded here because
it was proposed as a one-line change and passed by three review layers. None of `heat`, `mobility`,
`dietary`, `health`, `rest`, `budget`, `timing`, `sensory` or `other` is in `_GUARD_STOP` — measured,
0 of 9 against a 115-token stoplist, with a control arm confirming `will`, `valid`, `passport` and
`the` are in it. So under a `Category:`-scoped exclusion `- Specific: heat` becomes an in-class
**one-token key** on the token rule, and the guard aborts every publish whose itinerary contains the
word "heat" — permanently, with no remedy that does not delete the record the guard exists to
protect. That is the unusable fail-closed control CD-2 (the **Will** defect) existed to remove,
re-created at a wider blast radius: a broad fail-**closed** traded for a narrow fail-**open**, which
is the worse of the two by this document's own argument. The real problem is that a short value drawn
from common English vocabulary is not safely keyable by string matching at all. That is a
class-definition problem, not a guard defect, and it belongs to #278.

**What is not caught, and why. Eight residuals — four deliberate, three that are open defects
stated rather than claimed solved, and one that is a scope decision taken at the Stage 9 re-gate:**

1. **Paraphrase.** A value the hub **reworded** on its way into `final-itinerary.md` breaks every
   n-gram and is **missed**; a paraphrase is a judgement no string match can make. #278 states the
   same limit in its own words, and that is the reason #278 exists. **Paraphrase is not the only
   missed transform** — an earlier revision of this section implied it was. There are **three**
   transform classes that defeat matching, and the other two are residual 5 below.
2. **The exit-4 declared non-key — a stopword-only third-party name, OR a stopword-only short
   third-party value.** `is_stop` applies to the name arm as it always did to the other two, so a
   member named **Will** is a *declared non-key* and their name reaching the render is not caught
   here. **The fail-open reaches both arms of this member, not the name arm alone.** Within the
   matcher, exit 4 is emitted from the `token` rule and from nowhere else (the `exit 4` in the model
   parse is the unrelated orphaned-mark backstop and means UNDETERMINED — same digit, opposite
   polarity), and the rule table above assigns `token` to two kinds of record: every third-party
   **name**, and every third-party **field value under five words**. So a short need value with no distinctive token in it — `Timing: not on the day`,
   `Specific: no more than most` — is a declared non-key too, and the need text reaching the render
   is not caught either (3 of 3 measured, against a control carrying one distinctive token that is
   caught). An earlier revision of this residual said the value arm was *untouched*. That was true
   only while the third-party value rule was a hard-coded `phrase`, which has no exit-4 path; the
   entry denylist replaced it with the word-count choice in the rule table above, and that is what
   extended exit 4 to the value arm — so the claim contradicted this document's own rule table for a
   full revision, and the identical claim shipped in `scripts/publish-trip-site.sh` alongside it.
   Both are corrected here rather than softened.

   What exit 4 does **not** reach: the **Passport** member, always matched under `conjunctive`, which
   has no exit-4 path at all — under two distinctive tokens is `3`, undetermined, and aborts; and a
   third-party value of five words or more, which takes `phrase` and ends at `1`, not `4`.

   The widening is deliberate in its direction even though it was not stated: `phrase` on a four-word
   value exits `3`, and a sub-floor undetermined aborts every publish of that trip forever with no
   remedy — an unusable fail-closed control is fail-open in practice because it gets worked around.
   Note the residual is **narrowed, not solved**: `_GUARD_STOP` is normalization vocabulary, not a
   list of names, and it was **not** extended here, so May, Art, Grace and Rosa still key — and can
   still over-block.
3. **A passport value split across two structural blocks (new).** Scoping the conjunctive window to a
   block is what stops a clean multi-day itinerary aborting forever, and it costs this: a value whose
   two facts land in different blocks — say adjacent table cells — no longer pairs. A carry-through
   into prose, which is the realistic shape, sits in one block and is still caught (N1d).
4. **Tag names and attribute names.** Neither projection covers them. They are markup machinery and
   carry no trip content; this is the structural form of `verify_ciphertext`'s boilerplate
   subtraction, and it is what stops the published-bytes arm aborting on ordinary CSS and script
   (M1d). A render containing the literal sentinel `zzguardblockzz` would split a block that should
   not have split — a missed match, never a false abort.
5. **Encoding transforms — a second and third missed class, previously unstated.** `_norm_words`
   lowercases and reduces to `[a-z0-9]`; it does not decode HTML entities and does not rejoin a word
   split by a tag. Measured: a class value carried with a **numeric character entity** in place of a
   letter, and one **split mid-word by a tag**, both reach `rc=0` against a verbatim control at
   `rc=1`. So the missed-transform set is **three classes — paraphrase, entity encoding, and
   mid-word tag splitting — not one.** These are **open**, not accepted: unlike paraphrase they are
   mechanical and a normalizer could close them. They are stated here because the previous revision
   of this section named only paraphrase and therefore over-claimed.
6. **The same-block over-block, on content the class definition explicitly protects — an OPEN
   DEFECT.** Scoping the conjunctive window to a structural block fixed a permanent false abort
   across day boundaries and introduced a narrower one inside a block: 3 of 3 renders carrying both
   Passport tokens in one legitimate block falsely abort, against 2 of 2 controls that publish. One
   of the three is a `Visa / entry` line — the exact class `agents/06-validator.md:145-147` names as
   *"correct content [that] is never flagged"*. It is fail-**closed** and leaks nothing, and no
   acceptance criterion forbids a false abort, so it does not block. It is nonetheless a false abort
   on protected content, it is **undispositioned**, and the Consequences section above corrects the
   claim that construction alone prevented it.
7. **The coverage floor is LINE-based, and "the value" over-states it.** The model parse reads one
   line at a time with no continuation handling, so a **wrapped** field value contributes each of its
   lines as a separate record rather than as one value. Each line is matched on its own: a contiguous
   5-word run of any *single line* is caught, a run that **spans the wrap point** is not, and a
   continuation line under five words falls to the short-value rule. The entry denylist improved this
   — the previous revision matched the **first line only**, because only the labelled line was ever
   read — but it did not eliminate it. Read "what is caught" above with this floor in mind.
8. **The `[THIRD-PARTY]` member is not claimed as completely covered — a SCOPE DECISION, not a
   defect statement.** #123's AC 3 originally required this class to cover *"every `[THIRD-PARTY]`-
   marked value"*. At the Stage 9 re-gate the operator **narrowed AC 3 to the Passport member**, and
   this document must not read as though the narrowing did not happen. **The third-party arm still
   ships, and it still fires on the cases it covers** — every stated field of a marked entry (O1),
   the value-granularity mark (O2), the real derived-model shape (O3), the bad-merge and orphaned-mark
   backstops (O4b, O4c). What is retracted is the claim of **complete** coverage of that member.

   Two things sit under the retraction, and neither is a coding error.
   **(a) A short, common-vocabulary value is not reliably keyable by string matching.** A third-party
   need is often four words of ordinary English, and every route out of that is bad in one direction:
   key it and an itinerary using the same ordinary word aborts forever (the `Category:`-scoping trap
   recorded above); do not key it and it publishes (residual 2's value arm, and the field-blind enum
   exclusion). The exclusion and the short-value branch pick the fail-open side deliberately, and the
   result is that the arm's coverage is real but partial.
   **(b) The corpus underspecifies the shape this arm parses.** Measured across every tracked `.md`
   in this repository: **44** fenced example blocks, **12** carrying a `## <Name>` heading, and
   **0** carrying a `[THIRD-PARTY]` entry. There is no worked example of the artifact this arm reads,
   so the entry denylist takes what a line states rather than binding to a shape — which is the right
   response to the underspecification and is not the same thing as covering the member.

   **#278 is where this is carried.** A declared publishability attribute settles the class by
   construction rather than by string match, which is the only move that resolves (a), and making the
   third-party entry shape structural is what resolves (b). Neither is reachable from inside
   `nonpublishable_values`. Read residual 2 and the enum-exclusion note above as the two measured
   instances of this one residual.

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
  bytes, the name-arm stoplist, class freshness), **N** (the block-scoped conjunctive window) and
  **O** (the `[THIRD-PARTY]` entry denylist, value-granularity mark reading, the real derived-model
  shape, the bad-merge and orphaned-mark backstops, and the two over-block controls),
  `.github/workflows/publish-guard.yml`.
- The entry-class bound with no default-allow, and the `Applies to:` link-never-a-copy rule:
  `reference/data-model.md` § *Lifecycle facets* (:170) and § *Needs* (:139, :143). The only worked
  example of `outputs/traveler-model.md`, which is where the derived need-line shape is read from:
  `reference/data-model.md` § *Worked example — a per-traveler file* (:266-283). The third-party
  entry's marks, cardinality and needs-only bound, the value-granularity requirement, the named
  heading mark-stripping error, and the supersede-don't-merge rule: `agents/00-enrichment.md`
  § *A party member who will never file* (:396-473). That a third-party need has no governing
  constraint to key to: `agents/06-validator.md` (:231-243).
- First-party source of the Passport member, and the label shape the profile parse binds to:
  `templates/traveler-intake.template.md`; the `[DERIVED]` status of the projection and the
  refresh contract: `CLAUDE.md` → *Satisfaction-layer artifacts*.
