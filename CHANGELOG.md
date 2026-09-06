# Changelog

All notable changes to the travel-planner engine are documented here. The format
follows Keep a Changelog; versions follow Semantic Versioning.

## [0.25.0] — 2026-09-05 — Command verb discoverability

The trip commands take verbs, and until this release you had to already know the verb in order to
type it. `/trip`, the primary entry point, declared no `argument-hint` at all — commit to it and the
line went quiet. Three of its siblings did declare one, and each rendered `<verb>`: the argument's
*shape*, never its domain, which tells a reader that a verb belongs there and nothing whatever about
which. There was no complete list to fall back on either. `reference/` carried ADRs, schemas and
specs but no command reference, and the README's first-run table was partial by design and said
so — an honest disclaimer pointing at nothing.

This release gives each command a description that names what its verbs are *for*, a hint that
enumerates them, and a `reference/command-reference.md` carrying the whole surface: every verb, its
argument signature, and the trip state it requires before it will run.

The decision that shaped every other one was a measurement that contradicted the premise the work
started from. The card assumed `argument-hint` is what the command picker shows. It is not. Read
against the installed CLI's own renderer, the field draws as dim ghost text on the input line, and
only once a `/`-prefixed value has been typed — the moment at which the picker's suggestions have
already been cleared. The picker row renders `description`. The hub re-verified this independently,
with a differently-shaped probe, and reached the same conclusion. So the design stopped asking one
key to do three jobs and gave each of the surface's three moments one job apiece: `description`
names the verb domain while you are browsing, `argument-hint` enumerates the verbs at the instant
you are choosing one, and the reference carries the set for when you want all of it. The work did
not change; the claim the release made about which surface delivers it was wrong, and correcting
that before shipping belongs in this record rather than out of it.

No length constant entered the repository, and its absence is a decision rather than an oversight.
The rendering budget is the terminal's, mediated by a CLI this repository does not own, does not
version and cannot pin — committing a number would assert a fact about someone else's release that
nothing here could keep true, and would one day fail for a reason no contributor could act on. The
check therefore grades verb-set agreement and never length. `/trip-record` is the one command whose
list does not fit inline at the 80-column floor: it carries what fits, marks the truncation with a
token the verb rule ignores by construction, and its description points at the document. That
*pairing* is what is mechanically graded, rather than the size of either half.

The magnitude the work was scoped against had gone stale, and it mattered more than a magnitude
usually does. The milestone's own graded success indicator named a verb total the previous release
had already moved — the people library added verbs to `/trip-record` after this card was written. A
reference built to the old figure would have shipped short **while the indicator read green**: the
failure where the artifact and the measurement are wrong in the same direction and each confirms
the other. Both were corrected at the planning gate, and the correction is recorded as a re-scope
rather than a resolution, because the defect still reproduced — only its size had moved.

One consequence of that staleness was visible to every user and nobody had noticed it.
`/trip-record`'s description still covered the verbs the command had when the sentence was written:
`link`, `unlink` and `promote` had acquired no phrase, and `erase` — the one irreversible act
anywhere on this surface — was absent entirely from what a user sees. A description is not a
changelog and does not owe an entry per verb, but the verb that erases a person is not the one the
picker should forget to mention.

The reference is derived rather than remembered. The repository already stated the verb set in seven
places and machine-cross-checked every one, so an eighth statement that nothing graded would have
been a regression wearing a feature's clothes — the first uncomputed enumeration in a corpus whose
discipline is that enumerations are computed. The document instead carries a marker-delimited region
that the existing taxonomy guard recomputes from the command files' own requirement tables and
compares on every run, printing the block it expected when the two disagree, so a divergence is
repaired by a paste rather than a hunt. That the region comes from the guard's existing extractor
rather than a second one is the whole reason this form was chosen over a generator.

A check that still passes once deleted is not a check, so the new guard group's deletion-sensitivity
was demonstrated rather than asserted. Removing the reporting group fails the assertion inventory in
one direction and removing the control arms fails it in the other — but there is a third mode that
neither direction can see, in which the checker is quietly unwired from the real command tree while
every assertion id stays emittable, surfaced and armed, and every fixture still passes. That mode is
caught by a vacuity guard, which refuses to report a comparison that did not happen.

One thing changed at the last gate. `/trip`'s new description named a domain for every verb the
command declares but one: `schema` mapped to no phrase. The obvious repair is to append a clause,
and appending was the wrong move — truncation is tail-first, so a longer sentence would have pushed
text that was already earning its place past the cut in order to rescue text that was not there
yet. The sentence was re-read instead, and its trailing restatement of mechanism gave way: saying
that the command resolves the trip and then runs what you typed does not name a verb domain, and the
body below already states it normatively. The description ended up **shorter than it started while
gaining a domain** — an outcome an append could not have reached.

No verb count appears in anything this release authors, here or in the reference. The set grows, and
a number standing beside it reads its own growth as drift.

### Added

- **`reference/command-reference.md`** — the whole command surface in one table: every verb, the
  argument signature its own section heading states, and the lifecycle, mode, destination and depth
  it requires. The table sits inside a marker-delimited region recomputed from each command file's
  requirement table on every guard run; the prose around it explains how to *read* the table and
  deliberately names no verb and no total, because a second statement of the set is a second thing
  to keep true.
- **An `argument-hint` that enumerates verbs on every trip command that takes one.** `/trip` had no
  such key at all and now carries its full list; `/trip-decommission` and `/trip-publish` replace
  `<verb>` with theirs, the slug flag still fitting beside it. `/trip-new` takes a destination and
  year rather than a verb, so its hint was already correct and is left alone.
- **Group `H` in the command-taxonomy guard** — five assertions, five control arms, five fixture
  defect modes, and no SKIP path: an absent reference document is a hard failure rather than an
  expected skip, because declaring the group skippable would convert a red into a silent pass over
  an unshipped surface.

### Changed

- **Every trip command's `description` now leads with its verb domain rather than its role.**
  Truncation is tail-first, so the visible prefix is the scarce resource and a label spends it
  saying nothing. `/trip-record` gains the domains the people library left it without, `erase`
  among them, plus the pointer at the reference its own list overflows into.
- **The README's first-run table has something to point at.** It has always described itself as a
  starting point rather than the whole surface; that sentence was true and unactionable, and is now
  one clause away from the document that completes it.
- **The taxonomy workflow's coverage-boundary comment**, which would otherwise have carried a stale
  coverage claim on the very surface whose purpose is to be honest about coverage. Comment only —
  the `env:` block is byte-unchanged, and it stays that way precisely because group `H` needs no
  skip declaration.

### Known gaps, carried rather than hidden

- **Order is not graded.** The check asserts that a hint's verb set agrees with the command's own
  table; a hint whose set is right and whose ordering has rotted passes. Front-loading the verbs a
  reader is likeliest to want remains an authoring rule, stated in the reference and enforced by
  nothing.
- **Nothing grades the rendering budget**, by construction and not by omission. A hint can grow past
  what any given terminal will show and no check here will say so, because the number that would
  decide it belongs to software this repository does not version.
- **Desktop-app renderer parity is unmeasured.** The whole design is calibrated against the CLI's
  renderer; whether the desktop picker draws the hint is recorded as assumed and unverified, exactly
  as the governing decision record already admitted. If it does render it, this only improves.

## [0.24.0] — 2026-09-05 — People library

A traveller who has been on three trips has answered the same 38 intake questions three times.
Their passport does not change between trips; their dietary needs do not; the name they go by
does not. The engine has never had anywhere to put a fact that outlives the trip it was captured
in, so it re-asked — and the only reuse path the docs offered was an instruction to copy a
profile forward by hand, which contradicts the data model's own `link, don't copy` rule in the
same repository that states it.

This release gives a person a durable record, and gives every trip a reference to it instead of a
copy. A returning traveller's starred pass goes from ten fields to three.

The store holds the highest-sensitivity data in the system — passports, dates of birth, document
expiries, medical and dietary needs — so it is git-ignored, and the boundary that keeps it out of
a public repository is two lines whose shape is load-bearing rather than incidental. The rule is
rooted (`/people/*`) and not bare, because a bare form would also swallow the tracked example
witness the class schema names, and git cannot re-include a file whose parent directory is
excluded. Both properties were established by construction in a scratch repository across four
pattern variants before either was written down, and the obvious simplification really does break
both of the things the comment warns it breaks.

The harder decision was what happens when a trip and a store disagree. A trip-side value that
contradicts a durable one is not a merge conflict to be resolved by recency — it is either an
override the traveller meant for this trip, a stale copy nobody updated, or a schema violation.
Composition therefore decides on **class first, then answered-ness**, over a lattice enumerated
rather than asserted: 110 cells, no cell uncovered, no cell covered twice. Relevance is decided
by whether a field was *answered*, never by whether its line is *present*, because the intake form
keeps a line with an em dash for every question skipped — a presence test would read a deliberate
skip as an answer.

Erasure is the one operation here that cannot be undone, and it is deliberately inside this
release rather than deferred to a later one. A person who asks to be deleted should not have to
wait for a milestone. The verb walks a fixed reach set of 29 enumerated locations, substituting
values in place rather than regenerating, because a rebuild would leave standing every copy in a
class the schema declares holds independent state. Every location is either reached or reports
itself unreachable: a partial run is a run that says it was partial.

Its confirmation prompt changed at the last gate, and the change is worth recording because the
first design was wrong for a good reason. It withheld the person's name and asked the operator to
type the record's id, so that no erased value entered a transcript and no habit formed of typing
people's names at prompts. That reasoning is sound and it is preserved — the typed token is still
the id. But an id is opaque, and where two co-travellers each hold a record nothing at the prompt
distinguished them, so an operator who transposed two ids would have confirmed the wrong
irreversible erasure with no second signal. The prompt now names the record it is about to erase
before it accepts anything. The old design was not wrong about the cost; it was wrong about who
should bear it.

Archived trips receive no derivation at all, and erasure is the single stated exception — a
person's right to be forgotten does not stop at a trip that has ended.

### Added

- **`people/<person>.md` — a new cross-trip artifact class** — one durable record per person,
  held outside any trip, with a surrogate key borne by the filename. Its `trip:` universal field
  is *narrowed* to a cross-trip sentinel rather than removed, so the rule that no class removes a
  universal field holds unchanged. The store ships with a tracked README signpost and a guard
  group asserting the ignore pair in both directions.
- **A durable intake form**, split from the trip form. The trip form keeps trip-scoped questions
  plus the reference; the durable form carries the person-scoped ones. Every field in the model is
  classified into exactly one of four scopes, and the two forms' label sets are disjoint by
  measurement rather than by intention.
- **Four verbs** — link a trip to a record, detach it, promote a trip-side value into the store,
  and erase. Each declares its own read and write grants, and the detach verb holds no store write
  at all, so it is structurally incapable of erasure rather than merely forbidden from it.
- **A person-store collision check.** Two travellers whose display names normalise to one key used
  to share a file, and the second silently overwrote the first — in files the model itself
  describes as carrying real personal detail. The write path decided on a bare file-existence
  probe, which is structurally blind to that case: the filename derivation collapses out-of-charset
  runs to a single dash while the identity key removes them entirely, so two names can produce one
  key and two different filenames. The key check now runs *before* the existence probe.
- **A decision record** for the person entity — identity, storage home, referencing, and an
  additive amendment to the third-party-capture record it inherits from.

### Changed

- **The publish guard's freshness walk now covers referenced person records**, and the
  non-publishable fence gained a row plus the evaluator widening required to read it. Those two
  landed in one commit deliberately: a fence row naming a scope the evaluator cannot read aborts
  every publish as undetermined, and the *other* partial landing is silent — which is precisely
  the leak the fence exists to prevent.
- **The enrichment agent resolves references and composes the model with its shape unchanged.**
  The hub, the engines and the validator require no modification and do not learn that a library
  exists. Divergence between a trip value and a durable one is reported inside the existing
  signals block as information, never as a replanning signal.
- **`/trip-new` refuses a trip slug equal to a reserved `trip:` sentinel**, which a shape check
  cannot exclude because the sentinel is itself a valid slug.

### Known gaps, carried rather than hidden

- **The documents that govern behaviour are largely ungated.** The composition rules can be
  mutated to nonsense and every suite stays green; the paragraph stating the archived-trip freeze
  can be deleted with the same result. A verifier exists and is tracked, unshipped, pending an
  owner. This is the release's own largest finding about itself.
- **There is no executable erasure** — a command specification and a post-state witness fixture
  ship, so the receipt half of the erasure contract has nothing grading it.
- **An assertion that checks a rule is *present* cannot see a clause that is *added*.** Two
  acceptance criteria here say "removed or altered", and an addition is neither.

## [0.23.0] — 2026-09-02 — Per-traveler cost estimation

A traveller asked to preload a fare card, or to budget for a week, has had no basis for the
number. The plan already knows the activities, the meals and the movements; what it has never
known is where a cost *lives*, and after the artifact model that is not a question a feature is
allowed to leave open. This release answers it — and stops one step short of producing the
estimate, deliberately.

The entry marker's rule has said one thing since the model landed: it carries the entity key
**and nothing else**. The absoluteness was the point, because a marker that admits a second
field admits a third, and the entry's prose stops being where the entry's content lives.
Amending it was the more expensive of the two paths on the table, and it is the one taken here,
because the alternative was reading money out of running sentences. The corpus makes that case
against itself better than an argument could: within a single fixture the same currency is
spelled two ways — once with a yen sign, once with a bare ASCII letter — so a reader written
for one returns a confident nothing on the other. A rule that has to be amended is visible; an
extractor that quietly misses a file is not.

Rule 2 therefore admits exactly one optional field, in the fenced form only, and the
declared-key-column classes are untouched. The amendment is one field wide by construction
rather than by intention, and the classes that inherit it are decided on the form they already
carry rather than on whether they happen to hold prices today.

The third field on the new class is where the harder decision sits. A count of zero has two
meanings — *this trip has no priced items*, and *no price could be read* — and a two-field
artifact cannot separate them, because the zero is the whole of the answer. So coverage is
**declared rather than inferred**: `measured` says the counts are counts; `unverifiable` says
the file presented entries and no markers at all, and the denominator was never computable. The
estimate renders `undetermined` rather than a total of zero, and a partial total always carries
its own coverage — a partial total that looks whole is worse than none.

Nothing emits the field yet, and that is the shape of the release rather than a gap in it. The
grammar lands first so that a marker carrying a cost is *read* rather than rejected as out of
grammar; the writers that put one there arrive with the estimate itself.

### Added

- **`outputs/cost-estimate.md` — a new in-model artifact class (`C21`)** — the per-traveller
  spend estimate's declared home, written by the **hub** alone, `rebuilt-each-synthesis`,
  `derived`, and `publish: internal`. The hub is the one agent that already reads every input
  the estimate needs, so per-traveller attribution required no new read grant on any spoke — in
  particular the transport agent's `traveler-model.md` read stays narrowed to the depth signal,
  as its own prohibition intends.
- **`§ 4.5.1` — the cost field, the one addition rule 2 admits** — an optional
  `cost: <amount> <currency> <basis>` line beneath the key, in the fenced `artifact-entry` form
  only. `C8` and `C18` inherit the widened grammar on the form they carry; only `C18` enters the
  coverage denominator, which is keyed on entity rather than on form.
- **`reference/schemas/cost-estimate.md`** — three fields, of which the third is the load-bearing
  one: `cost-bearing-items`, `priced-items`, and `coverage: measured | unverifiable`. The reading
  rule binds every consumer — *read the pair only when `coverage: measured`*.
- **A degenerate witness in `examples/data-architecture-demo/`** — an instance whose entries carry
  markers and no costs, so it exercises the `measured, N = 0` limb rather than a populated one.
  The branch hardest to get right is the one with a fixture behind it.
- **`ADR-011`** — the founding decision record: the artifact home with the C14 and C15 rejections
  argued rather than named, the singular writer, the lifecycle, the publishability call
  reconciled against `ADR-004` and `ADR-008`, and the rule-2 amendment itself.

### Changed

- **`ADR-009` amended in place** to record that rule 2 now admits one field. The original
  sentence is retained rather than rewritten — an amendment may narrow what a decision permits
  going forward, never rewrite what it said.
- **`agents/02-food.md` declares `**Price:**`**, matching what every realised entry in the corpus
  already spells. The declaration moved to meet practice rather than the reverse, because the
  entries it describes sit inside a content-address-pinned tree and cannot be rewritten.
- **Five agent prompts and six schemas** reconciled against the amended rule. Each prompt states
  that it does **not** emit the field yet and that an entry carrying one is read rather than
  treated as out of grammar.

## [0.22.0] — 2026-09-02 — Pre-departure preparation layer

The itinerary began once the traveller was settled and ended before they left. Three of the
four gaps closed here sit in that unplanned space, and the fourth exists to stop the first
from going stale. What the three shared is that each is work a traveller has to have done
*before* they are moving — hold the right documents, understand how the fares work, know
where the bags go — and the engine planned the middle of the trip as though all of it had
somehow already happened.

Luggage is what makes the two edge days hard, and the reason neither can be planned as an
ordinary day with a flight note attached. A party that lands two hours before check-in is
holding its bags in a lobby; a party turned out of the room six hours before its flight is
doing the same in reverse. Both windows are bounded by values the brief already reads —
`Check-in time:` and `Check-out time:` — and neither had ever been read against the stream's
own arrival or departure instant.

The obvious way to keep that content fresh was wrong, instructively. `ITERATION` already said
a move updates the legs it touches and leaves *every other row of the brief standing*, which
is exactly right for the transit matrix, where an untouched leg genuinely has not changed.
Arrival- and departure-day content is not that kind of row: its validity depends on *which day
is the arrival day*, so a move onto or off one stales it while touching no leg it owns. The
rule that shipped **narrows** that sentence rather than replacing it — one named class of dated
content re-derives, and outside it every other row still stands. The dates it keys on are a
**set**, one per origin plus any traveller whose own window states its own, because a single
arrival day is the assumption the brief's own **single-origin** failure mode already names.

Four things are true now. The arrival and departure days are planned around the bags: a stated
bag count, the customs and collection flow where it moves a time or a mode, and a named home
for the luggage in each window — with a stated absence where no forwarding service exists.
Every traveller carries a derived, dated document set determined from their own passport facet
and the trip's destination pair, fenced by construction rather than by good intentions. A
traveller can learn how the fare system works before departure instead of on the platform. And
a move that lands on the arrival day, or leaves the departure day, now obliges a refresh of
exactly the lines it invalidated.

### Added

- **`§ Pre-Departure Transit Familiarization` in the transport brief (class `C9`)** — the fare
  *model* rather than the purchase steps: how fares are computed, tap-in versus
  tap-in-and-out, the transfer window and what forfeits it, who rides reduced; three to five
  destination-specific conventions a first-timer gets wrong; and two to four vetted primers
  with the publisher named on every one. It cites the sections that already own the
  obtain / load / tap sequence and the in-trip app set rather than copying them, and a
  resource whose publisher cannot be named does not go in the list. The section carries **no
  entry marker**, deliberately: `§ 1.1` gives this class the entities *Leg* and *Signal*, and
  a primer is neither, so there is no key for a marker to carry.
- **The per-traveller document set — one `- **Documents:**` line per entry on `C12`** — derived
  from the traveller's own `Passport:` facet and the origin / destination pair, over four
  statuses (`have`, `obtain`, `file-before-travel`, `unknown`), with an `ACTION:` prefix where
  the derivation found a *problem* rather than a step, and a required `· checked <YYYY-MM-DD>`
  on the same rule the corpus already puts on price and hours data: entry policy is
  time-sensitive, and an undated derivation cannot be judged current.
- **A publish-guard arm on the new field** — `field Documents outputs/traveler-model.md
  conjunctive`. The privacy requirement is a declaration the guard reads, not a rule an author
  has to remember at writing time.
- **`The dead zone`, a transport failure mode** — routing the party to the door and stopping
  there. The hours on either side of the room are part of the arrival and the departure day,
  and the luggage is the reason they are hard.

### Changed

- **`Luggage options:` is no longer conditional.** It shipped as `[If relevant]`, and that
  optionality is what let the departure half go unanswered on exactly the trips where it
  mattered — the shape **"The departure afterthought"** already names. Every departure stream
  has bags and a gap; what varies is the answer, never whether one is owed.
- **Luggage assembly folds into `Buffer rationale:` rather than taking a label of its own.**
  Getting a group and its cases out of a property is not instantaneous, and a buffer derived as
  though it were is the buffer that fails.
- **The dated and the undated halves of `C9` are separated in terms.** Per-stream arrival and
  departure lines change when the arrival instant or the bag count changes and are executed on
  the day; trip-level orientation is written once and read before departure. A sentence that
  would be true for any traveller arriving any day this year is not the per-stream section's.
  Two of this milestone's stories landed in the same class, and that boundary is what keeps
  them from blurring into each other.
- **The hub reads the widened `C9`.** The arrival and departure plans reach the day through
  those days' **Transit Notes** — carried, not re-derived and not dropped, and taking no block
  of their own. `Arrival/departure neglect` now names the bags: a day written as though the
  room is ready on landing, or as though the luggage disappears at check-out, is the same
  neglect wearing different clothes.
- **`Documents:` is derived content, not a tenth lifecycle facet.** The nine facets are carried
  through from what a traveller stated; this set is computed from their facets plus researched
  policy. Reading it as a facet would put a derived value under a rule written for stated ones,
  and the facet count is unchanged by it.

### Fixed

- **A derived requirement set could have been written about a person whose identity data was
  never captured.** A `[THIRD-PARTY]` entry carries no `Documents:` line at all: ADR-006 grants
  that entry exactly one class — the party member's needs — and deriving entry requirements
  about them is precisely the capture that grant refuses. An `[OPERATOR-PROVIDED]` traveller
  who is expected to file *does* carry the line, as `unknown` until their profile arrives.
- **An unreconciled traveller would have read as one needing no documents.** A first-party
  traveller with no filed profile carries the line as `unknown — no passport country on file`
  rather than not at all, so the absence of a *requirement* stays distinguishable from the
  absence of a *derivation*.
- **A payload the publish guard could not see.** The whole value sits on the label's own line.
  Rendered as a nested sub-list under `- **Documents:**`, the guard — which reads a field's
  value from the label's line — would have read straight past it. The fail-open direction is
  closed by shape rather than by care.
- **The passport country and expiry date have one home, and the derivation no longer copies
  them into a second.** The verdict is stated by reference — `passport — have (valid through
  the required buffer)` — never by restating the values that produced it. The `§ 5.6`
  publishability row is the backstop behind that rule, not a licence to ignore it.

## [0.21.0] — 2026-09-02 — Group coordination

A plan that changes has to say so, and this release is about the three audiences it has
to say it to: the organizer who decides, the traveller who arrives at the site, and the
record that has to still be readable afterwards. The four gaps closed here were not four
instances of one defect. What they shared is that every one of them had to be solved
*inside the published bytes* — `ADR-002` § *Decision 2* permits only a city-ambient
client-side fetch, so there is no side channel a coordination signal could travel down.

That constraint is what made the obvious gate wrong. The first cut refused a republish
whenever a change was pending, which reads as prudence and is in fact a deadlock: showing
a traveller that a change is pending *requires* a publish — of a site whose itinerary is
the one already published, carrying a marker that says pending. A gate keyed on
publish-as-such aborts precisely that act, and the state it exists to protect becomes
unreachable. The gate that shipped keys on itinerary-content change instead: a
marker-only republish passes, an unapproved plan change does not.

Four things are true now. A plan shift emits a before/after summary the organizer can
share out of band, bounded so it carries no more than the shift. A traveller arriving at
the site is told that a change is pending, or that the plan was recently updated, rather
than reading a page that looks settled while it is not. A republish that moves the
itinerary stops until the organizer confirms it, against a digest bound to the exact
content being approved. And the v2 direction has a decision record instead of an open
question.

### Added

- **`outputs/change-summary.md` (class `C20`)** — the before/after record of a plan shift,
  appended rather than rewritten, so a re-bake that shifts nothing appends nothing and a
  decision nobody made cannot be destroyed by a later pass. It is `publish: internal`: it is
  shared out of band, and a content guard holds it to that boundary.
- **The coordination notice, and non-emission as a contract rule** — a band the site emits
  in a `pending` or a recently-updated variant, plus two optional per-class fields carrying
  the state and the date it was anchored to. Absent or `none` coordination state emits
  *nothing*, and that silence is specified rather than incidental: it is what makes the
  band's absence readable as "no coordination activity" instead of "not implemented".
- **The organizer-confirm gate on the republish path** — a resolver, an abort, a recorder,
  and a `confirm` subcommand. The proceed set is the allowlist and the default aborts, so no
  token the resolver can emit — including one no author anticipated, including the empty
  string — reaches a push. The published baseline is a git-ignored sidecar in the trip dir:
  the published artifact is ciphertext by construction, and recording a plaintext fingerprint
  in the public repo would have been a new disclosure surface.
- **`ADR-010`** — per-traveller approval collection needs a **transport**, not a **server**.
  The card arrived carrying the opposite premise, and testing it first is what kept this from
  being scoped as a revision of the repository's security posture. `ADR-003` does not merely
  permit an out-of-band transport; it already relies on one, in the words *their own channel*.
  The more useful half of the record is what that test surfaced: **that channel has never been
  named**, in two records one release apart, and a mechanism — unlike a human reading a
  summary — cannot resolve a placeholder by using whichever channel it already has. The
  record states the attestation ceiling and declines to name the channel, deliberately.

### Changed

- **The itinerary-content projection is a sibling of the existing text projection, not an
  edit to it.** It excises the notice band and the declaration block, under a bounded cap that
  makes the fail-open direction unreachable: a mis-shaped band matches nothing, the marker
  text stays in the digest, and the republish then reads as an itinerary change and aborts.
  Both failure directions land fail-closed.
- **The projection has one limb.** It shipped carrying a `perl … || sed` fallback copied from
  a neighbour where the two limbs compute approximately the same answer. Here they do not —
  only the perl program excises the band — so a failing or absent perl silently substituted a
  different projection into the gate's digest and every marker-only republish aborted. The
  limb was removed rather than taught, because `sed` cannot express the excision.

### Fixed

- **A day-eight deadlock that nothing had been asserting against.** The build-time prune
  that rewrites coordination state to `none` once a trip's window closes is digest-neutral
  *only because* the declaration block leaves the digest — and the block's two coordination
  fields are covered by that excision and by nothing else. Had it stopped being neutral, every
  trip whose one change was confirmed would have found its next republish reading as an
  itinerary change and deadlocked at the gate on the day its window closed. The coupling was
  recorded and then held by nothing; arm `S13f` now names and asserts it, carrying its own
  discrimination limb so that a projection which swallowed its input could not satisfy it
  vacuously.

### Note on what this release did not close

This release did not go straight through. Six remediation rounds sit behind the four cards,
and three of the findings above — the publish-as-such gate, the two-limbed projection, and the
unnamed prune coupling — were each found after the design they belonged to had been accepted.
The pattern is worth stating: each was a case of a construct that looked correct in isolation
and was wrong only in relation to something else in the same release.

Two qualifications ride along, neither of them fixed here.

The `pending` state clears only where the change also moved the projected itinerary text.
`confirm` refuses to write while the resolver reads `none-pending`, and the resolver reads
`none-pending` whenever the outgoing render's itinerary digest already equals the published
one — so a confirmation cannot be recorded against a change the gate cannot see, and the band
stays up. It over-warns and never under-warns, and the next itinerary-moving change resolves
it. But a reader of the contract alone would predict the band clears one `confirm` away, and
on the first publish after a re-bake it does not.

And `C20`'s `status` field has no live consumer. The schema justifies the field on the ground
that a consumer branches on its value, naming the site's pending state and the confirm gate as
the two. Neither reads it: the gate is keyed on itinerary digests end to end and says so in
terms, and the site's state was re-keyed onto the confirmation record precisely because nothing
in the corpus ever moves `status` off `pending`. The field is display-only today, and the
schema's stated reason for requiring it is ahead of the code.

## [0.20.0] — 2026-09-01 — Short-horizon replan protocol

A replan had no clock. `ITERATION` reasoned identically three days before a trip and three
months before it, and the four gaps closed here all sat downstream of that. They were not four
instances of one defect — a missing behaviour contract, a file nobody had created, a coupling
table naming the wrong agent, a preference that could be traded away without saying so. What
they shared was how each presented: the plan changed, something the change had invalidated
stayed on the page still reading current, and nothing distinguished *not checked* from
*checked and fine*.

Near the trip's start the question stops being whether a booking window is under pressure and
becomes whether the thing can still be secured at all, and nothing asked it — no count of the
days left, and no rule against offering, as the fix for an unbookable item, an alternative whose
own lead time exceeds the days remaining. Nor could the engine always say what was booked.
`outputs/event-status.md` is created lazily, by whichever agent first writes it, and that
ordering is what guarantees no double-create and no wipe; the gap was what happens when neither
writer has run. `/trip-record event` halted on the absence with the words *there is no repair
path to name here*, and the status-integrity audit read a trip carrying no per-event status as a
trip with nothing wrong.

Moving an event to another day made the day's routing stale in a way nothing re-derived: the
table that says what a change makes stale listed a day move as scheduling's alone, so the hub
reconciled the receiving day over a route it had never published. And a re-sourced meal slot
could be quietly refilled at a lower price tier because the cheaper candidate was the one with a
table free — a trade that is often right, but is the traveller's to make, and that nothing
required anyone to state.

Four things are true now. A short-horizon replan reads its horizon from the plan, per item,
against the lead time that item's own row declares — no day count appears in the protocol,
because a fixed threshold is right for one category and wrong for every other. A synthesised plan
with no per-event status is reported, and the halt that had no remedy names the repair while
still creating nothing. A day move and a venue substitution both admit transport, and a changed
day whose route was never re-published is a Critical rather than an assumption. And a replacement
is held to the slot's price tier as a floor and says on the entry how its price sits against it —
a declared trade-down the hub can weigh, where a silent one was not.

### Added

- **`reference/replan-protocol.md`** — the short-horizon behaviour contract, and the home two
  hooks in `reference/data-model.md` already declared and left unnamed. It defines
  `days-to-trip-start` and the per-item booking horizon, and is as explicit about what it is not:
  no field, no dispatch rule, no threshold. The signal is derived at read time and never stored,
  and is named for the trip's start because the corpus already fixes *departure* as its end.
- **Four validator checks** — per-event status presence, transit currency on changed days,
  price-tier preservation on a replacement, and booking feasibility at the horizon. Each says
  where its population cannot be read, and that an unexercised check is declared rather than
  passed — a blocked input and an empty population are both not-exercised, and are repaired by
  opposite things.
- **An intent-by-reference section in `reference/data-model.md`** — price tier, subgroup and hard
  constraints are mastered elsewhere and reached through keys an event row already carries.
  Intent survives a replan because the research lists accumulate and the itinerary is versioned,
  not because the status model started holding a copy.
- **Group `PS` in the artifact-schema suite** — the presence check asserted against `examples/`
  rather than described, with a denominator derived from the tracked tree and a control arm that
  fails a detector flagging everything.

### Changed

- **A day move admits transport as well as scheduling, and a venue substitution is a new row that
  admits it too.** The admitted set is a set: a reserved event relocated to another day satisfies
  two rows and dispatches scheduling once.
- **`### Advance Booking Priorities` is ordered by what the days remaining no longer cover**, and
  re-produced on `ITERATION` whatever days changed — a window closing on a day this run did not
  touch is still closing.
- **A food replacement is held to the slot's price tier as a floor**, and a `Mixed` overall tier
  neither excuses the reconciliation statement nor supplies a verdict.
- **The enrichment setup seed fires on a stated condition** rather than at the agent's discretion,
  and writing nothing where `## Locked Elements` names no fixed event is explicitly not a finding.
- **Three of the new checks run on the `DISCOVERY` branch**, where the populations they exist
  for actually sit — a plan synthesised before this substrate existed stays in that mode
  precisely because nothing wrote a later one.

### Fixed

- **`/trip-record event` no longer halts with no remedy.** It names the repair the data model
  states — and which verb is available depends on the trip's mode, because the creation edge
  does. It still creates nothing: naming a verb is not writing the file.
- **A synthesised plan with no per-event status is reported rather than silently skipped**, as a
  Warning — nothing placed is wrong, so the plan is not defective; the engine simply cannot say
  what is booked.
- **Both `reference/data-model.md` hooks that deferred to "the replanning capability" now name
  the file.**

### Note on what this release did not close

Nothing exercises the validator's prose checks against `examples/` in general. The assertions
were written inside the four existing cards instead, which covers this release's checks and no
others. That was deliberate — the alternative was adding a fifth work item to a composition
already locked — and a shared harness is left to a later bundle.

Four facets of the acceptance criteria could not be assessed against the shipped corpus, each
recorded with which kind of unassessable it is. The near-trip Critical has an empty population
rather than a missing input: a sweep of 1,096 candidate reading dates found none both before the
trip starts and after the plan's one booking deadline, which falls the day after it begins. No
fixture would have closed that, and none of the four was counted as a pass.

And the detector written to police this release's own `tier` vocabulary allowlists `severity
tier` — a phrase occurring nowhere in the repository at either end of the release, where the
idiom that ships is `Critical tier`. The predicate holds on all four cards; the instrument does
not, failing by confident zero. That shape recurred: three of the four designs specified a check
that could never have fired, each gating its behaviour on a mode its own verb does not admit — a
signature `CLAUDE.md` already records and no design consulted. A control arm proves an instrument
is alive, never that it is aimed at the question.

## [0.19.0] — 2026-09-01 — Nightlife fast-follows

Three gaps shipped alongside the nightlife capability in 0.9.0 and were accepted as named
fast-follows rather than release blockers. They were not three instances of one defect — one was
structural, one was an advertised path that no code reached, one was a documentation claim the
engine had newly contradicted. What they shared was the reason none of them blocked: every one of
them fails silently. Nothing errors, nothing warns, and the plan a traveller reads looks complete.

The natural-occasion trigger was advertised in the architecture decision that introduced it, in the
hub's day template, and in the nightlife agent's own gate table. It was reachable from none of them.
Dispatch conditioned on a stated desire alone, so a Saturday, a birthday or a last night produced no
nightlife research at all; and even where dispatch had fired, the gate resolved against a file that
does not carry trip dates, leaving two of its three occasion members unevaluable. The agent then
wrote a stub asserting that no occasion applied — a claim it had no way to check, which downstream
consumers read as settled.

A split night had no join between the two things that describe it. The day-level Nightlife block
carries entries with no members field; the parallel track blocks carry members but refuse night
cards. On a fully-split day the day grid is omitted entirely, so those night cards had nowhere to
live. Every available encoding lost something, and the one that lost the most lost it invisibly: a
present traveller's nightlife desire could disappear into a decline line that the validator reads as
a correct outcome rather than a gap.

And the worked example the README points readers to still held all six of its evening venues under
Activities, which the three-way ownership boundary the engine now ships directly contradicts. That
example is a byte-identical regression witness and is not edited in place, so correcting it in the
obvious way was not available.

Four things are true now. The occasion limb resolves as a trip-level projection of the per-night
rule the hub and validator already apply, sourced from fields that exist, with the one member no
component could act on withdrawn rather than left advertised — a documented trigger no path can
reach is the condition this work existed to remove, not one to leave behind. A split night expresses
per-subgroup nightlife through a members slot on the entry line and the decline line alike, joined to
the track block by verbatim string equality, and a desire lost to a split night now produces a
finding at every priority tier the gate admits. A new fixture demonstrates the evening ownership
boundary end to end, including a venue whose primary draw reassigns it from Food to Nightlife.
And the frozen witness is untouched.

One thing worth recording about how this release was built: most of its defects were found by
reading rather than by running. Every gate stayed green through all of them, because a test suite
verifies behaviour a rule has and cannot see a rule that only appears to exist.

### Added

- **`examples/evening-boundary-demo/`** — a worked instance of the three-way evening ownership
  boundary, resolving two Activities, two Food and two Nightlife entries from one evening. It
  demonstrates the cross-spoke condition in both directions: a venue whose primary draw moves it
  from Food to Nightlife, and its mirror. Its `outputs/food-list.md` **discharges class C6's
  coverage declaration** — that class previously had no schema witness precisely because its only
  instance sat inside the frozen worked example and could not be versioned.
- **A per-subgroup member slot on the nightlife entry line and the no-nightlife line**, joined to
  the Parallel Track block's members string by verbatim string equality. On an unsplit night
  `whole group` reproduces prior behaviour exactly — the rule generalises, and the unsplit case is
  its identity.
- **A nightlife band as a declared region of the day body**, rendered on every day regardless of
  which day-body shape is present, so a fully-split day's night cards have a container.
- **A render-contract row for the nightlife decline line.** A *stated* decline and a *dropped*
  subgroup must not look alike on the page.

### Changed

- **The occasion limb is a trip-level projection**, not a per-night test evaluated by a night-blind
  gate. Each member resolves from a source that carries it: the weekend member from the outbound and
  return legs, the occasion member from the traveller carry-through and the calendar.
- **The gate's input set is stated at the gate** rather than inferred from the read-order list that
  happens to precede it, so a later addition to that list does not silently widen what resolves the
  gate.
- **A malformed no-nightlife line is judged by a criterion, not a list** — the test is whether *who
  declined* stays determinable. An unreadable member slot is never the reason a night passes.
- **The completeness walk covers the nightlife band's contents in full**, night cards and decline
  lines alike, rather than only its card-bearing elements.

### Fixed

- **The natural-occasion trigger is reachable end to end.** Dispatch admits it, and the component
  that evaluates it can read the fields it names.
- **The SKIP stub no longer asserts that no occasion applied** unless that was actually evaluated —
  an unverified claim that had been propagating into the validator's basis field.
- **A decline that covers a desire-holder is a gap, not a correct outcome.** The finding this work
  exists to surface is now reachable on the case it was written for.
- **The worked example's divergence note names the nightlife ownership boundary**, so a reader
  landing on the frozen example is told which of its sections predates the shipped behaviour and
  where the compliant instance lives.

## [0.18.0] — 2026-08-31 — Satisfaction fast-follows

Six items held out of earlier releases on purpose, each a gap in a specification rather than a
defect in a build. They shared a shape: a rule stated in one place, then narrowed or re-derived
or read somewhere nothing could check it.

The presence predicate decides whether a traveller counts as present on a given day, and it
quantified over whole days. Windows in this corpus are routinely bounded mid-day, so a day could
be half inside one — and nothing anywhere said whether such a day was in the set. Two consumers
citing the same predicate could classify an arrival day oppositely and both be defensible.

Recurring desires shipped with a scheduler that opens a standing slot on each of a traveller's
days, a hub that fills it and a validator that grades it — and three supplier agents that had
never heard of them. The consequence was visible in the corpus's own worked example, where a
three-day morning ritual grades `not covered` because nobody had been told to nominate a third
distinct venue.

The convenience-format cap was the only numeric cap in the corpus with no validator audit. The
marker it rested on was opt-in and named no category, so an omitted marker read as *eligible*
and the cap was not checkable from the produced file even by hand.

Two per-traveller signals stopped short of their readers. The transport agent read
`trip-context.md` and nothing else, so the depth signal never reached it and the anchor origin's
passenger list had no literal source. And a traveller with no profile on file had a place to be
named but no place to carry a field value.

Four things are true now. A partial day is a whole day to the presence predicate, settled in one
sentence at the definition and with no coverage threshold — a fraction of a day is never a
fraction of a membership. Suppliers are told to nominate enough distinct places to fill a
recurring slot on every day it is owed, inside the venue cap that already applies. The
convenience-format cap is audited from the produced artifact rather than from the agent's
behaviour. And the transport agent reads the per-traveller channel — for depth and nothing else —
while a profile-less traveller has a declared block to carry a facet value in.

### Added

- **A recurring desire's honored-day set** (`reference/data-model.md`) — the days a recurring
  desire is actually owed on: the traveller's present-day set intersected with the days that
  desire's own time block reaches. It exists because settling partial days made a second question
  visible — a day-granular presence rule cannot say whether a traveller's half day contains a
  morning. Trimming the obligation here leaves the presence predicate untouched: the day stays in
  the traveller's present-day set, and only this desire's claim on it narrows. Derived once, and
  cited rather than re-derived by the scheduler, the hub, the validator and all three suppliers.
- **A convenience-format anchor cap report** in the validator's output, counted per category from
  the food list's own eligibility lines. Its marker-coverage denominator is fixed by the entry
  marker rather than by the eligibility line, so a missing line lowers coverage instead of
  improving it — and where the selector cannot see an entry the file presents, the report refuses
  the measurement by name instead of certifying it.
- **A recurring-desire supply obligation** on the activities, food and nightlife agents — a count
  of distinct candidates, never a schedule — with the `Recurrence` marking added to each one's
  read order.
- **A depth lens on the transport agent**, expressed as how its existing sections are filled
  rather than as sections added or removed. Arrival and departure are never compressed, and no
  traveller's answer is written into the brief.
- **A `Trip-level facets` block on the profile-missing branch** of the enrichment agent, giving
  that class a defined home for a facet value. `Origin` is its only member today, and on a
  single-origin trip the block renders with `Origin` declared not applicable rather than left
  blank.

### Changed

- The presence predicate resolves partial arrival and departure days **at its definition**, and
  says in the same place that it settles membership only: a time block a traveller's window does
  not contain narrows what an obligation reaches, never whether the traveller is present.
- Recurring-desire coverage now reads against the honored-day set everywhere it read against the
  present-day set. A day trimmed by the desire's own time block renders that reason rather than
  silence — absent, unavailable, and present-but-out-of-block stay three distinct states.
- The hub no longer names a shortfall for a day the desire was never owed on.
- `Anchor-meal eligibility` is required on every food entry, in one of three spelled tokens, with
  the convenience-format category carried on the nomination the cap counts.
- The transport agent's anchor stream states the closed derivation for its passengers — every
  roster member not named under an additional origin — where the template previously made that
  derivable without giving it a source.
- An unassigned traveller's inherited origin carries basis `UNKNOWN` and the `(assumed)` marker on
  every trip shape, single-origin included, in the vocabulary the template already defines. The
  basis records what a person stated, not whether the inheritance could have gone another way.

### Fixed

- The scheduler's prose no longer reasons about a desire's priority tier, a field its own Input
  contract says it does not receive. The clause was a universal quantifier and nothing
  misbehaved; it read as though the scheduler could see something it cannot.
- The intake template's recurrence question sits beside the priority-tier question a traveller
  answers in the same breath, rather than after the overlap instruction where the specification's
  literal wording had put it.

### Note on what this release did not close

This is prompt and reference text — thirteen files, no code and no schema change. Nothing added
here is enforced by a gate: every rule is one an agent is told to follow, and the new cap audit
is an instruction to the validator rather than a script that runs.

Six follow-on cards were raised by the work itself and are open. Among them: the transport agent
is now a named reader of the mixed-party depth rule with no way to satisfy it or disclose an
exemption; a domain term the presence predicate leans on is used four times and defined none; the
new cap report's measurement path has no worked instance anywhere in the repository; and the
artifact-model section that four of these cards point-fixed still carries a row asserting a
shipped element this release falsified. They are tracked, not closed.

## [0.17.0] — 2026-08-31 — Corpus and process hygiene

This release is about the repository's own quality rather than the product's. Four things were
wrong with it, and they shared a shape: each was a claim the repository made about itself that
nothing checked.

The intake template told a reader that ten fields were starred. It said so in the banner, again
in the agent appendix, and once more as ten per-field annotations — and no script in the
repository read any of them. Starring an eleventh field and updating the banner alone would have
shipped a stale appendix, with every gate green, and the appendix is the surface an agent reads
to run the intake. The stale copy is the one that would have driven the conversation.

Two rendering rules that shipped in 0.10.0 had no worked instance anywhere. A rule with no
example is a rule nobody has read end to end, and one of them — the single-origin collapse —
turned out to be contradicted by the only fixture that met its precondition.

A decision record named one of its target files two ways inside a single paragraph. And the
`travelers/` artifact class, which a user must author by hand before anything else works, had a
filled example in the repository that the section documenting it never pointed at.

### Added

- **`examples/single-origin-demo/`** — a worked instance of the single-origin collapse
  rendering and the `**All travelers:**` marker. It ships the raw inputs alongside the collapsed
  line so the warrant census is independently derivable, states that the per-traveller table is
  absent rather than omitted, and names the falsifier: a traveller who states an origin — even
  the trip's own — pins it and breaks the collapse.
- **Group `ST` in the artifact-schema suite** — the starred-field count is now inspected across
  all four of its homes: the banner, the appendix rule, and the per-field annotations, compared
  against the marked fields themselves. Surfaces are discovered by markup shape rather than by
  line number, because the report that surfaced this defect cited lines 6 and 295 for content
  that had already moved to 21 and 320.

### Changed

- `README.md`'s traveller-profiles section now links the worked pair in
  `examples/data-architecture-demo/travelers/`, and the privacy rule that closes it is scoped to
  the reader's own profiles so a published fixture and an unpublished real profile describe
  disjoint populations rather than a rule and an exception.
- `examples/data-architecture-demo/` is marked as a deliberate non-collapse, so the corpus no
  longer holds a fixture that silently contradicts a shipped rule.
- ADR-008 names every target by its repository-relative path.

### Fixed

- Three citations in ADR-008 carried a bare basename where nine carried the path.

### Note on what this release did not buy

The defect class it exists to remove — a count asserted in prose that goes stale when its
subject moves — recurred five times during the work of removing it, including once in prose that
passed all eight required checks green. Every instance was caught by reading; none by a gate.
Where a numeral could be deleted rather than corrected it was, on the reasoning that a corrected
number is the same defect waiting for the next change. The gap that remains — that nothing
detects the next one — is tracked, not closed.

## [0.16.0] — 2026-08-30 — Artifact model and validation gate

The engine writes about twenty kinds of file, and until now none of them said what it was.
A research list and a validation report and a traveller profile were all just markdown, and
every agent that opened one had to work out from context what it had, whether it could be
appended to or had to be rebuilt, whether the facts in it were researched or derived or typed
by a person, and whether it was safe to publish. That worked because the agents were written
by the same hand at the same time. It was not going to keep working, and nothing would have
told you when it stopped.

This release gives every artifact class a declared identity. Each file now carries frontmatter
naming its class, its schema version, the trip it belongs to, the writer that owns it, its
lifecycle, the provenance of what is in it, and whether it may be published. Those are not
labels for a reader — a validator reads them, and a gate runs the validator on every change.

The part that matters most is publishability. A traveller profile holds passport-adjacent
detail and lodging and health needs, and the rule that keeps it out of a published site used
to live in prose that a person had to remember. It is now a field on the artifact, and the
publish guard reads the field.

### Added

- **A 19-class artifact model** (`reference/data-architecture.md`) with declared identity,
  lifecycle, provenance and publishability per class, plus the marker forms that carry entity
  identity inside a file.
- **Per-class schemas** (`reference/schemas/`) — one per class, declaring the fields that
  class must carry and the values each may take.
- **A validator and its CI gate** (`scripts/validate-artifacts.sh`, run by a workflow on every
  change). It checks that each artifact declares what its class requires and nothing outside
  the declared value sets.
- **A worked example** (`examples/data-architecture-demo/`) — a complete four-day trip carried
  through the model, deliberately uneven so that each class shows the rule it exists to
  demonstrate rather than repeating a full trip nineteen times.

### Changed

- Nine agent prompts, both templates, `CLAUDE.md` and `README.md` are reconciled to the model,
  so the file an agent writes matches the class it claims.
- The venue-deduplication cap now counts **places rather than rows**. Two spellings of one
  venue were previously two entries and could both appear; they are now one venue behind one
  key, and the two-appearance cap holds against that key.

### Notes

- **Your existing trips are untouched and keep working.** Artifacts written before this release
  carry no schema version, and the validator reads a missing version as pre-migration and skips
  the file. Nothing is rewritten, nothing fails, and nothing needs migrating by hand.
- **The frozen worked example is now protected by machine rather than by care.** Each of the
  ten files in `examples/tokyo-2026/` is pinned by content hash, with a test that proves the
  pin detects a single changed byte.
- **A same-name traveller collision is still possible and is now documented as such.** Two
  travellers whose display names normalise to the same key share a file, and the second
  overwrites the first. This predates the release and is unchanged by it; what changed is that
  `reference/data-architecture.md` now states the rule, states that the intake check has not
  shipped, and states what happens today instead of implying a control that does not exist.
- **A mistyped trip name no longer reports success.** `validate-artifacts.sh` given a path that
  does not resolve now fails with a finding, where it previously exited clean and looked
  identical to a real trip with nothing in it.

## [0.15.0] — 2026-08-28 — Trip closeout retention posture

A trip could be wound down but not put away. `/trip-decommission archive` arrived in the
last release and does the public half of that job well — the site goes offline, the trip
is marked `ARCHIVED`, the log takes a dated closing line — and it stops there deliberately,
because quietly deleting someone's trip content is not a thing a command should do. What it
left open was the private half. The folder is still on the machine, it still holds passport
numbers and lodging, and nothing in the repo said what to do about that. Past trips piled up
and the guidance for them was nowhere.

This release writes it down. The posture is per folder rather than per trip, because the
four parts of a trip do not age the same way: the two text files are small and are the part
worth rereading, the built outputs are the largest thing there and rebuild from those files,
and the traveller profiles are the most sensitive bytes in the repo and are the one part
that should not be left in a folder you have stopped opening. A single expiry rule would
have been wrong for all four.

### Added

- **A retention posture for `trips/` working directories (`trips/README.md`).** A new
  *After a trip* section states what `archive` does and does not do, then gives a keep or
  clear disposition for each of `trip-log.md`, `trip-context.md`, `outputs/` and
  `travelers/`, with the reason attached to each. It also states plainly that nothing
  expires on its own — no command deletes a trip folder and no timer runs — because the
  folder that has stopped being useful is the one that stops being noticed.

### Notes

- **The rest of the closeout issue was already shipped, and this release records that rather
  than rebuilding it.** Of the four acceptance criteria on the closeout story, three were
  satisfied by `/trip-decommission` in 0.14.0: a trip reaches an `ARCHIVED` state addressed
  as a taxonomy row, reaching it invokes the command-surface unpublish path with the
  pages-only flag, and no command passes `--yes` to `unpublish`. Only the retention posture
  was outstanding. Verified per criterion against the shipped surface before this release
  was scoped, so the closure rests on evidence rather than on the issue's original framing.

- **Both absolutes the new section states were probed, not assumed.** No command holds an
  `rm`, `rmdir` or `trash` grant — zero across all five command files, frontmatter and body
  — and `trips/` contents are git-ignored by `trips/*` with `!trips/README.md` as the
  exception, confirmed behaviourally rather than by reading the ignore file.

## [0.14.0] — 2026-08-28 — Consolidated trip command surface

Asking the planner to do something used to mean describing it in prose and hoping it
was read as the kind of request you meant. There was nothing to type that named the
thing you wanted, so the surface you actually had was a paragraph and a guess. This
release gives that surface a name: five commands covering trip creation, the people
and context you record, the planning you ask for, publishing, and winding a trip down.
Between them they answer twenty-four of the twenty-eight entries in the request table;
the other four say plainly that they are not commands and why, rather than being left
as a gap you discover by trying.

The commands are the taxonomy, not a restatement of it. That direction is deliberate
and it is the reason a check is cheap here: had the commands merely echoed a table
kept somewhere else, the two would drift and something would have to catch it. With
the commands owning it, a suite in CI asks only whether every entry resolves and
nothing is covered twice. What that suite does and does not prove is written down in
the workflow file rather than left to be assumed — because a green tick that reads as
more than it is would be worse here than no tick at all.

### Added

- **Five commands, and a verb after the first one
  (`.claude/commands/`).** `/trip` takes a verb for review and every planning
  procedure — `status`, `plan`, `replan`, `reorder`, `research`, `check`, `ideas`,
  `site`. `/trip-new` creates a trip, and is its own file because its subject is a
  trip that does not exist yet, so it takes no disposition from the resolution the
  others share. `/trip-record` covers travellers and context, which were the largest
  group of things with nowhere to be written down. `/trip-publish` covers updating a
  published site and listing what is published. `/trip-decommission` covers making a
  trip temporary, archiving it, and reopening it. Typing a command with no verb, or
  with one this revision does not implement, tells you so and names what it does
  implement, rather than proceeding on a guess.

- **A shared answer to "which trip is this about"
  (`CLAUDE.md`, `.claude/commands/`).** Every command that acts on an existing trip
  resolves which one through the same ladder of steps, in the same order, with the
  same answers — including the two answers that are not a trip: it could not tell, and
  it will not decide for you. Before this each surface would have had to work that out
  for itself, and they would have disagreed the first time an edge case arrived.

- **The request table is now checked, on every push and every pull request
  (`scripts/test-command-taxonomy.sh`, `.github/workflows/command-taxonomy.yml`).**
  The suite reads the request table and the command files and asks three things: that
  every addressed entry resolves to something real, that nothing on the command
  surface is left uncovered, and that nothing is covered twice. It runs with no path
  filter, so an edit anywhere is graded. **What it does not do is the part worth
  writing down.** It grades what the command files *declare*. It does not grade
  whether a declaration is honoured when the command actually runs — this repository
  carries two incompatible accounts of that, and the suite deliberately takes neither,
  so every statement it makes is true under both. A green result here is a statement
  about the table and the files, and not a statement about what a running command is
  permitted to do.

- **A first-run path in the README (`README.md`).** The README previously did not
  mention the commands at all — not once — which meant the surface this release exists
  to provide was invisible to anyone arriving new. It now says what to install, what
  to type first, and how to check it worked.

- **The decision and its limits are on the record
  (`reference/adr/ADR-007-command-entry-point.md`).** Why five files rather than one
  command or nine, what the alternatives cost, and which parts of the publish
  lifecycle are addressed now — three of its ten forms — versus the seven that are
  declared exclusions rather than pending work.

### Changed

- **The check asks about coverage, not a one-to-one match
  (`scripts/test-command-taxonomy.sh`, `reference/adr/ADR-007-command-entry-point.md`).**
  An earlier draft asserted that each entry maps to exactly one command file. Once a
  command takes a verb, the thing being matched is a command *and* a verb together,
  and there is no separate file to point at — so that assertion could not survive the
  design it was written for. It is replaced by a coverage question, which contains the
  old one rather than weakening it: where a command declares no verbs at all, the
  command itself is the unit and the two questions become the same. That is not
  argued in a comment — the suite constructs that world and demonstrates it. On the
  real table the difference is not academic: matching by command alone produces
  nineteen collisions where matching by command-and-verb produces none.

### Fixed

- **A number of things this repository said about itself were not true, and are now
  either accurate or gone (`.claude/commands/`, `reference/adr/`, `CHANGELOG.md`,
  `.github/workflows/`, `CLAUDE.md`).** Most were of one kind: a sentence saying that
  nothing here does some particular thing. Each was true when it was written and was
  made false later by something else being built — no one edited the sentence, and
  nothing was watching it. One said that no file in the repository reads a particular
  document, written an hour before the file that reads it was created. One said a
  check did not exist while that check was already running. They are repaired by
  saying what is true and where its boundary is, rather than by asserting the
  opposite, because the opposite is just as fragile and goes stale the same way. Where
  a sentence could only have been kept accurate by hand, it was removed instead of
  rewritten.

  **This did not come out of a review of the prose.** It came out of checking claims
  against the thing they described, one at a time, across every tracked file — which
  found roughly five times as many as reading had. Nothing in CI reads a pull request
  description, an issue, or a design note, and that is where several of these survived
  longest.

## [0.13.0] — 2026-08-23 — Publish-path content guard

Publishing a trip site has always had two paths: the default one encrypts the site
and checks the result before anything is pushed, and the opt-out one publishes it
in the clear. Only the first was checked. The path whose output is immediately
world-readable — no passphrase, anyone with the link — copied the rendered page
straight out with nothing looking at what was in it. That is the wrong way round,
and this release turns it round: the plaintext path now reads the page it is about
to publish and refuses if a traveller's passport details, or a need recorded for
someone who never filled in a profile of their own, have found their way into it.
It refuses equally when it cannot tell — an unanswerable question is treated as a
failure, not waved through. How far each of those two reaches is not the same, and
where the second one stops is written down below rather than left to be assumed.
Nothing changes for the encrypted path, which is still
the default and is still checked exactly as before.

### Added
- **The regression suite now runs on every push and pull request, and a green
  result means it actually ran (`.github/workflows/publish-guard.yml`,
  `scripts/test-publish-guard.sh`).** The suite that proves the publish guards
  work has existed for some time, but nothing ran it except a person remembering
  to. It now runs in CI. The part worth writing down is the second half of that
  sentence. The suite skips groups whose prerequisites are missing — real
  encryption needs Node, two groups need an authenticated GitHub CLI — and a
  skipped group used to count toward a pass exactly as a passing one did. Wiring
  the suite up naively would therefore have produced a green tick on a run where
  whole groups never executed, which is worse than no check at all, because it
  reads as proof. The CI run now provisions Node so the real-encryption groups
  genuinely run, treats any skip as a failure, and names the two GitHub-CLI groups
  it deliberately does not cover — so what the tick does and does not prove is
  written in the workflow file rather than assumed. Run by hand, the suite behaves
  exactly as it did before.
- **The decision, and its limits, are on the record
  (`reference/adr/ADR-008-publish-content-guard.md`).** A new architecture
  decision record covers why the existing pre-push check could not simply be
  called from one more place, which two alternatives were rejected and what killed
  each of them, and — the part most likely to be forgotten and then over-claimed —
  exactly what this guard catches and what it does not. It catches a value that
  reaches the page with the person's name stripped off, which is the case that
  matters most and the one a name-based check would miss entirely. It does not
  catch a value that was reworded on the way in. That limit is stated plainly
  rather than left to be discovered, because the guard is one layer of three and
  the other two are still doing work.

### Fixed
- **The plaintext publish path now checks what it is about to publish
  (`scripts/publish-trip-site.sh`, `scripts/test-publish-guard.sh`).** The check
  reads the page as a reader would see it and compares it against the two kinds of
  detail that must never be published: a traveller's passport country and
  validity, and any need recorded on behalf of a party member who has no profile
  of their own and so was never able to agree to it being written down. It keys on
  the traveller's own recorded values, never on words like "passport" — so a
  packing-list line telling everyone to bring theirs, and the visa and entry notes
  that belong on a published plan, are not flagged, and were never candidates to
  be. Stripping a person's name off a detail does not get it past the check, which
  is the case that motivated keying it this way. When something is found, the
  refusal names where it came from and never prints the value itself, so the check
  cannot leak what it exists to protect. If the record of who is travelling is
  missing, unreadable, out of date, or no longer in a shape the check recognises,
  the publish stops rather than proceeding on a guess; the remedy in every case is
  to publish encrypted, which is what the default already does. Nothing is pushed
  when the check refuses, and the refusal happens before the page is copied
  anywhere.

  **The check reads the whole page, not just the part you can see.** A first cut of
  this check read the page the way a browser paints it — the words a reader sees —
  while publishing copies the file itself. Those are not the same thing, and the
  gap between them was measured: a detail sitting in an HTML comment, in a page
  description, in the alt text of an image, in an inline script, in a style block,
  or in a data attribute went out unnoticed on seven of the eight places tried. Two
  of those are not even hidden — alt text and the page description are read aloud
  by screen readers and shown in every link preview. The check now reads both: what
  a reader sees, and what a reader can retrieve from the page source. What it
  deliberately ignores is the markup scaffolding itself — tag and attribute names —
  which is how it reads a page full of stylesheets and scripts without objecting to
  all of them.

  **It reads the travellers' own files, not only the summary built from them.** The
  summary of who is travelling is rebuilt from each traveller's own file whenever
  those change, so a passport recorded this morning may not be in it yet. The check
  used to read only the summary, and reported a trip as having nothing to protect
  when it plainly did. It now reads the travellers' files directly, and refuses to
  proceed at all when the summary is older than they are — an out-of-date answer is
  treated as no answer, which is the same rule the rest of this check already
  follows.

  **Two ways it used to refuse good pages, both fixed.** A party member recorded
  under an ordinary English name — Will — made every publish of that trip stop, for
  ever, with no way out that did not involve deleting the very record being
  protected. And because the check looked for a passport's country and expiry
  anywhere within twenty-five words of each other, an ordinary multi-day plan that
  mentioned, say, an Irish pub on each day under headings carrying the expiry year
  began refusing from the second day onward and never recovered. Both are corrected:
  a name made only of everyday words is no longer used as a search key, and the two
  halves of a passport must now appear in the same paragraph rather than merely
  nearby. A refusal that fires on correct pages is not a stricter check — it is one
  that gets switched off, which is worse than not having it. What each of these
  still does not catch is written down in the decision record rather than left to be
  discovered.

  **The half of the check covering party members is far wider than it was — and it
  is deliberately not complete.** Of the two
  kinds of detail this check protects, the second is a need recorded on behalf of
  someone who has no profile of their own. A first cut of it looked at two things
  and two things only: that person's name, and one particular line of their record.
  Everything else written about them was let through. That is backwards — the rule
  in the data model is that the whole entry for such a person is off limits, with
  nothing allowed out by default — and it mattered more than a missing line usually
  would, because the one line being looked for turned out to be the wrong one. It
  is the label used in a traveller's own hand-filled form, and the check was
  reading the summary built from those forms, which writes the same information
  differently. So on a real trip that half of the check could match nothing at all,
  while still reporting the page as clear. Three things are fixed together: every
  detail recorded about such a person is now checked rather than a chosen few; the
  marking that identifies them is read wherever it appears rather than only at the
  top of their entry, which matters because losing that top-line marking is a known
  mistake; and the check no longer looks for one particular label, because there is
  no agreed one to look for. Two related states now stop a publish instead of
  passing quietly: an entry whose marking has been removed while the details stayed
  behind, and a marking in the file that the check cannot tie to anything. The
  balance is kept the other way too — a need that a traveller stated about
  themselves and asked to have planned around is still allowed onto the page, as it
  always should have been.

  **Where that half stops, stated rather than left to be found.** It is wider, and
  it is not complete, and that was decided before this release shipped rather than
  discovered afterwards. Needs recorded for someone else are often very short and
  written in everyday words — "no stairs", "not in the afternoon", or simply the
  name of a category on the form. A check that works by looking for the recorded
  wording on the published page cannot use words like those as what it searches
  for, because it would then refuse every plan that happens to mention stairs or
  afternoons, on every attempt, with no way round it short of deleting the record
  being protected. A refusal like that does not make the check stricter; it makes
  it something people turn off. So a value made up entirely of everyday or
  form-vocabulary words is deliberately not used as a search term, and if such a
  value reaches the page it goes out unnoticed. A longer or more distinctive need
  is caught, and so is the person's name unless that too is an everyday word.

  There is a second reason, and it is about the records rather than the check. As
  first written, this paragraph said that nothing in the repository showed what an
  entry for such a person looks like, and offered a count of worked examples as
  support. **That was wrong on the day it was written, rather than overtaken
  afterwards**, and it is corrected here rather than quietly dropped.
  `scripts/test-publish-guard.sh` had been building worked entries of exactly that
  shape — a `## <Name>` heading carrying `[OPERATOR-PROVIDED]` and
  `[THIRD-PARTY]`, with that person's needs beneath it — since the three commits
  that added its third-party fixture groups, every one of them an ancestor of the
  commit that wrote the claim. The heading form is not left to a fixture to imply
  either: `CLAUDE.md` and `agents/00-enrichment.md` both state it. What those
  fixtures are is inputs written to exercise this very check, not a layout it
  matches against — and the marks an entry carries record **provenance**, who
  supplied a value and whether its subject is the person who spoke, where the
  check would need something different: a statement of whether a given line may be
  published. That is the thing still to be agreed. The check therefore reads
  whatever a line states instead of looking for an agreed layout — the right
  response to that, and not the same thing as covering everything written about
  that person. Agreeing that layout, and marking on each detail directly whether
  it may be published, is a separate piece of work already planned; it is not
  something this check can settle on its own. None of this
  affects the rest: passport details are covered as described above, an
  undeterminable answer still stops the publish, and the encrypted path — the
  default — is untouched.

## [0.12.0] — 2026-08-22 — First-run experience

Four fixes aimed at the first hour with this repository, and at the release
process that publishes it. Someone who has just cloned the repo now finds the
directory their trips belong in, is told why it is empty, and gets a straight
answer from the one read-only command instead of being sent back to a directory
they are already standing in. The two documents they are most likely to read
back-to-back name that directory the same way. They can size roughly what running
the engine costs before committing to setup. Nothing about how a trip is planned
changes — this release is about arriving, not about planning.

The fourth fix is about this file. A release changelog used to be written after
the release had already merged and been tagged, as a separate commit straight to
`main` — which meant the entry never travelled inside the release it described,
and never passed the check that reads everything else. This entry is the first one
written the other way.

### Added
- **`trips/` is present on a fresh clone, with a signpost that explains it
  (`trips/README.md`, `.gitignore`).** The directory your trips live in used to
  exist only after you created a trip, so a new clone simply did not have it and
  nothing said where trips were meant to go. It now ships with a tracked README
  explaining what belongs there and why the directory looks empty. Trip data
  itself is still ignored and still never published — the signpost is the single
  tracked exception, and a CI invariant now holds both halves of that: the
  signpost stays tracked, and a trip file underneath it stays ignored.
- **The README gives an order of magnitude for what running the engine costs
  (`README.md`).** Planning a trip end to end drives a lot of model usage, and
  until now nothing said how much. There is now a stated magnitude for a first
  full plan and for the cheaper things you do repeatedly afterwards — enough to
  decide whether to start, before investing in setup. It is a magnitude, not a
  quote: actual cost moves with the model you point at it and with how large the
  trip is.
- **A written release procedure (`CONTRIBUTING.md`).** There was no document
  anywhere in the repo describing how a release is cut. There is now, and the part
  it exists to state is that the changelog entry belongs on the release branch,
  landing through the release pull request with everything else — not as a commit
  to `main` afterwards.
- **The branch-protection posture is on the record (`SECURITY.md`).** `main`
  allows its administrator to push directly, bypassing the pull-request
  requirement and every required check in one step. That was true and undocumented;
  it is now written down as a decision, with the argument on both sides, the one
  time it has been used, and the condition that should cause it to be revisited.
  The mitigation below is honest about its limit: the checks now run on a direct
  push, but running is not blocking, so what this buys is detection after the
  fact rather than prevention.

### Changed
- **One notation for the trip directory, everywhere (`CLAUDE.md`,
  `templates/traveler-intake.template.md`, `templates/trip-context.template.md`,
  `agents/00-enrichment.md`, `agents/destination-ideation.md`,
  `reference/data-model.md`, `examples/two-origin-demo/trip-context.md`).** The
  documents and the templates they point at had drifted into different ways of
  writing the same placeholder path, so a reader moving between them had to work
  out that two spellings meant one directory. Twenty-eight occurrences are now a
  single convention, and the convention is stated once rather than left to be
  inferred.

### Fixed
- **`list` works on a plain clone, and says what is actually wrong
  (`scripts/publish-trip-site.sh`).** Listing your trips is a read-only scan of a
  local directory, but it used to require GitHub authentication before it would
  run — so a new user was stopped by a login prompt for a command that never
  needed one. It also reported a missing `trips/` directory as though you were
  running from the wrong place, which sent people to fix a working directory that
  was already correct. Both are fixed: no authentication for the read-only path,
  and a missing directory is now reported as a missing directory.
- **The personal-data gate covers commits that reach `main` without a pull
  request (`.github/workflows/depersonalization.yml`).** The gate that keeps
  personal email addresses and OS home paths out of this public repository ran
  only on pull requests, so anything pushed straight to `main` was never scanned —
  which is exactly how release changelog entries used to arrive. It now runs on
  pushes to `main` as well. Adding that trigger alone would have produced the
  worse outcome of a check that runs, reports clean, and reads nothing, because a
  push carries no pull-request context to derive a range from; the gate now works
  out its range from whichever event started it, says in its own output which
  commits and how many files it read, and fails rather than reporting clean if it
  cannot work that range out at all.

## [0.11.0] — 2026-08-22 — Satisfaction metric refinements

Three refinements to the satisfaction layer, each closing a place where the
coverage view described something other than the trip as it is actually lived. A
need was graded on days its traveller had not yet arrived. A want you have every
morning could only be recorded as a want you have once. And a day's anchor meals
could all drift into the same grab-and-go format with nothing in the metrics
noticing. Nothing new is asked of a traveller at intake beyond one optional line
per desire. The first two changes are invisible on a trip where everyone shares
the group's window and nobody holds a daily want; the third changes what the food
agent offers for the anchor role on any trip.

### Added
- **A want you have every day, recorded as one
  (`templates/traveler-intake.template.md`, `agents/00-enrichment.md`,
  `agents/03-scheduling.md`, `agents/05-hub-planner.md`,
  `agents/06-validator.md`, `reference/data-model.md`).** A desire can now carry
  an optional `Recurrence:` of `one-off` or `daily` — a morning coffee before the
  day starts, a swim, an evening walk. It is a separate question from how much
  the want matters: a daily want may be an anchor, a wish or a nice-to-have, and
  neither label implies the other. Only an explicit `daily` counts; a blank or
  em-dashed line is a one-off, and the wording of a desire is never read as
  evidence of cadence. A daily want becomes a standing slot on every day that
  traveller is present — their own window, not the trip's — placed in the time
  block the desire names, and no slot is placed on a day they are away. Three
  bounds hold: it is never the day's anchor whatever its tier, it never exempts a
  venue from the two-appearance cap (so a week-long ritual is a week of that kind
  of stop, not seven visits to one address), and it yields to needs like any
  other desire. It is reported per day and counts as covered only when every
  present day carries it; a partial run is not covered, with the missed days
  named.
- **Convenience formats are capped as anchor meals, not as entries
  (`agents/02-food.md`, `agents/05-hub-planner.md`, `reference/data-model.md`,
  `CLAUDE.md`).** Grab-and-go, konbini and counter, standing-counter,
  market-stall and the other minimal-commitment formats stay welcome without
  limit as grazing, snack and casual entries — a thin casual section was always
  the anti-pattern here. What is capped is how many of them are offered for the
  **anchor** role: at most two nominations per category across the list, the
  second one intentional rather than a default. The cap is about commitment and
  format, never about effort — a walk-in counter can be a legitimate anchor and
  nothing here pushes toward reservations. Each convenience entry now states its
  anchor eligibility, the hub honors that marker without recomputing it, and a
  new anti-pattern names the drift the rule exists to catch: anchors accumulating
  as convenience formats because they are easy, cheap and always open, until the
  trip's anchor meals are three konbini runs and a standing counter.
- **A sixth coverage dimension — meal-variety concentration
  (`reference/data-model.md`, `agents/05-hub-planner.md`,
  `agents/06-validator.md`, `CLAUDE.md`).** The satisfaction view now names six
  dimensions rather than five. The new one is a per-day balance signal for
  whether a day's meals concentrate in a single convenience format instead of
  ranging across formats. It follows the same seam the rest-recovery signal
  already follows: the per-category anchor cap above is the hard selection-time
  rule, and this is the softer per-day reading of whether the resulting spread is
  healthy beyond it. Like every balance signal it is named and tracked with its
  value left to design — nothing in the satisfaction layer scores or optimizes
  yet.

### Fixed
- **A need is graded only on the days its traveller is at the destination
  (`reference/data-model.md`, `agents/06-validator.md`,
  `agents/05-hub-planner.md`, `agents/03-scheduling.md`).** A need's applicable
  days are now the days its governing constraint governs **intersected with**
  that traveller's own at-destination days, so a mobility limit is no longer
  failed on a day its traveller had not yet landed. Absence is the only presence
  failure that removes a verdict: a traveller who is at the destination but
  **unavailable** is still graded, because they are here on a parallel track and
  their needs bound that track exactly as they bound the main one. Two readings
  are named separately so each consumer cites the one its own job needs —
  placement reads presence (there **and** free), grading reads the window alone —
  and both are defined once in `reference/data-model.md`, with the scheduler, hub
  and validator citing rather than re-deriving them. The trim is always shown
  with its reason (`D2–D4 (at destination D2–D4)`) so a reader can tell a
  presence trim from a constraint subset; a silently narrowed grade is the same
  failure as an unnamed absence. Where a window is only assumed, every day is
  still graded and the *(assumed)* marking travels with it — a hard gate is never
  dropped on a guess — and a party member recorded on needs alone, who carries no
  presence data at all, is graded on every day the constraint admits rather than
  none.

## [0.10.0] — 2026-08-21 — Per-traveler facet depth

A party who leave from different places, or arrive on different days, is now
modelled as the individual people they are rather than as one representative
traveller. Five capabilities land together because each is unusable alone: a
per-traveller derivation of available time, a trip context that can hold more
than one departure origin, a scheduler and transport brief that read presence, a
familiarity signal that calibrates recommendation depth, and a home for a party
member's needs that cannot be published. The single-origin case is unchanged
throughout — the trip-level blocks still render exactly as before.

### Added
- **Per-traveller effective planning days
  (`templates/trip-context.template.md`).** A `[DERIVED]` block sits alongside
  the trip-level one, deriving each traveller's own window, timezone delta and
  partial days from their own arrival and departure rather than the group's.
  `Arrive / leave` and `Leaving from` are each classified independently as
  stated-different, stated-same-as-group, or unanswered — so a window that is
  assumed rather than asserted is marked as assumed everywhere it is used.
  Classification follows what the traveller bound their window to, never numeric
  coincidence: dates that happen to match the group's stay pinned when the group
  rebooks.
- **Additional departure origins (`templates/trip-context.template.md`).** A trip
  can carry more than one origin, each with its own legs and its own list of who
  departs on them. The section's absence is what means single-origin, so existing
  trips are untouched. Leg field labels are identical across the anchor and
  additional origins, so a consumer parses them with one rule.
- **Presence in scheduling and transport (`agents/03-scheduling.md`,
  `agents/04-transport.md`).** Whole-group anchors prefer days on which everyone
  is present; when a booked event, a hard closure or an immovable need forces one
  outside a traveller's window, the day names who is absent and which of those
  reasons forced it. Absent (not at the destination) is kept distinct from
  unavailable (present but committed elsewhere) — only the latter has a parallel
  track worth planning. Transport derives one arrival-day stream per origin.
- **Prior-visit familiarity (`templates/traveler-intake.template.md`,
  `agents/01-activities.md`, `agents/02-food.md`).** An optional, unstarred field
  on a closed scale — never / once / a few times / know it well — calibrates how
  deep recommendations pitch. The starred quick-pass stays at ten fields.
- **A home for a party member's needs (`agents/00-enrichment.md`).** Where
  someone in the party will not file a profile of their own, the organiser can
  record their needs through the existing operator-provided path, marked as
  second-hand. They reach the planner exactly once, attributed to the right
  person, and are superseded rather than duplicated if that person later files a
  profile. The intake form is unchanged: nothing new is asked.

### Changed
- **Third-party information is barred from published output
  (`agents/00-enrichment.md`, `agents/06-validator.md`,
  `reference/data-model.md`).** A need recorded on someone else's behalf shapes
  the plan — pacing, rest, walking distances, venue choice — but never appears in
  any publish-bound artifact, in attributed or anonymised form; in a small named
  party, removing the name does not remove the identification. Two escalation
  paths that would have carried such a value into the published trip file are
  closed by carve-out, so first-party escalation continues to work unchanged. The
  validator treats any leak as Critical, with no warning tier, no waiver, and an
  undetermined result failing closed. Lifecycle facets are bound to first-party
  entries by a single class-wide rule rather than a list of fields, so facets
  added by a later release inherit the bound automatically.
- **Cold-assistant guidance names the third fallback branch (`CLAUDE.md`).** An
  assistant filling the form on someone's behalf is told where a profile-less
  party member's needs belong and that they are never published — the gap that
  produced this work in the first place.

### Decisions
- **ADR-006 — third-party data capture** is ratified. Needs recorded on behalf of
  a party member without a profile may be captured on a non-publishable surface;
  identity data about that person may not be captured at all. See
  `reference/adr/ADR-006-third-party-data-capture.md`.

## [0.9.1] — 2026-08-20 — Intake form: corrective

Three corrections to the traveler intake form that 0.8.0 shipped, and two
changelog headings that were dated a day early. None of the form fixes changes
what is asked for or withdraws a claim — each closes a place where the form left
the reader to guess: **whose** passport belongs on the passport line, whether an
unbooked flight makes the arrival question moot, and which two of the starred
fields actually ask you to think.

### Fixed
- **The `Passport` line covers exactly one person
  (`templates/traveler-intake.template.md`).** The field now reads **yours alone
  — not your party's**, and the section note names where a travelling companion's
  passport belongs: their own copy of this form, saved as
  `trips/[destination-year]/travelers/<their-name>.md`, on their own line there.
  If that person will not have a profile at all, the form now says so plainly —
  their passport is not recorded anywhere — rather than leaving the reader to
  assume it was captured somewhere. The embedded interview carries the same rule,
  and needed an explicit local carve-out from its own **keep their words** rule to
  do it: narrowing a party-shaped answer — *"two of us are Canadian, one is
  Australian"* — genuinely changes the meaning, so without the carve-out a
  compliant assistant would record the party-shaped answer verbatim.
- **`Arrive / leave` is no longer gated on group flights that may not exist
  (`templates/traveler-intake.template.md`).** The field was prefixed *only if
  you're not on the group's flights*, which made it unanswerable before anything
  was booked — the ordinary state of things at intake. It now asks for this
  traveler's own arrival and departure at any booking state, and *"I'm on whatever
  the group books"* is a stated answer rather than something inferred from an
  empty field. The interview says the same and adds the rule that makes it hold:
  an empty field means **unknown**, never *no constraints*.
- **The starred quick pass says on the line where the thinking is
  (`templates/traveler-intake.template.md`).** Eight of the ten starred fields are
  a pick-from-the-list or a short phrase; two — a need and a desire — ask you to
  think, and nothing said which. Both now carry **one line is a complete first
  pass** on the line itself, each with a start-here phrasing and a sharpen-later
  phrasing, and the desire field states that an archetype from the menu above is a
  complete answer on its own. `Comfort range` gained its option set on the line —
  *keep it lean / mid-range / spend freely* — so the one starred money question is
  answerable by recognition like the rest. Nothing was retracted here; a locator
  was added.
- **`[0.8.0]` is dated to the day it was published.** The heading ran a day early
  and now reads `2026-08-19`.
- **`[0.1.0]` is dated to the day it was published.** The same defect, further
  back; the heading now reads `2026-07-01`.

### Notes
- The two heading corrections are one defect, not two: a date taken from the UTC
  timestamp rather than from the publish date as it read where the release was
  cut. A release published in the evening Central time falls on the next day in
  UTC, so the UTC reading runs a day ahead. Dates in this file are the GitHub
  Release publish date rendered in Central — this entry's own heading included.
- The **2–3 minutes** on the starred first pass is unchanged, and is an estimate
  rather than a measurement — nothing in the repo times a real fill.

## [0.9.0] — 2026-08-20 — Nightlife agent

Going out at night now has **an owner**. Cocktail bars, clubs and live-music
rooms used to fall between the Activities evening section and the Food agent, so
nightlife came out inconsistently — sometimes planned, sometimes missing, and
filed under whichever agent happened to reach for it. A dedicated nightlife agent
now researches those venues, the hub places them into the evening, and the
validator checks the nights a traveler actually asked for.

### Added
- **Nightlife research agent (`agents/07-nightlife.md`).** Owns going-out venues
  — cocktail bars, clubs, live music, late-night rooms — by the primary-draw
  test: what is the reason you go? It produces `outputs/nightlife-list.md` and
  deliberately does not schedule. Night-fit is captured in three day-independent
  fields — `Nights & hours`, `Night type`, and **`Next-morning cost`** — so a
  late night is weighed against the morning after rather than judged alone.
- **A three-depth desire gate.** The agent runs FULL (a full menu, minimum 12
  entries), LIGHT (minimum 5, weighted to low-key and non-drinking options), or
  SKIP, depending on how much nightlife the party actually wants. A SKIP still
  writes a short gate-result note, so a missing list never reads ambiguously as
  "nobody wanted it" *or* "the agent never ran".
- **A nightlife block in the day template (`agents/05-hub-planner.md`).** The
  site layout spec already described how a night card should render; nothing
  emitted one for it. Each day now carries a Nightlife block — or an explicit
  no-nightlife line with its reason, never both and never neither.
- **Per-night coverage check (`agents/06-validator.md`).** On nights a present
  traveler wants nightlife, the validator reports whether the night is covered.
  Warning and Note only, with no Critical tier, so nightlife is optimized for
  and never forced onto a trip as a required anchor.

### Changed
- **A three-way going-out boundary (`agents/01-activities.md`,
  `agents/02-food.md`).** Activities, Food and Nightlife now state the same
  partition reciprocally. If the reason to go is the drinking or the room, it is
  Nightlife; if it is the eating, it is Food; if it is a sight, a view, or a
  scheduled event that happens to fall after dark, it is Activities. A venue that
  plausibly fits two is claimed by its primary draw and cross-referenced by the
  other, never listed twice.
- **Nightlife wired into the pipeline (`CLAUDE.md`, `README.md`).** The nightlife
  agent is dispatched in the research phase after Food and before scheduling,
  `outputs/nightlife-list.md` becomes a required hub input, and night venues
  carry the Category and Reservation wiring — for a nightlife venue the
  reservation slot holds the door policy: cover, guest list, dress code, or
  walk-in — so every night card resolves to a map link like every other card.
- **First cross-spoke venue dedup rule.** When two agents propose the same place,
  one rule now decides which of them keeps it, so a venue stops appearing twice
  in one plan under two different headings.

### Notes
- The **natural-occasion** path — nightlife proposed because the trip contains a
  weekend night, a birthday or a last night, rather than because someone asked
  for it — is documented but **not yet reachable**. Nightlife driven by a stated
  desire works throughout; the occasion path is a named follow-up.
- The Tokyo worked example under `examples/` still splits its evening venues the
  old way and now disagrees with the boundary this release ships. The example is
  unchanged here and is being corrected separately.
- On a night where the group splits into parallel tracks, the day carries one
  Nightlife block rather than one per track. Split-night nightlife is a named
  follow-up.

## [0.8.0] — 2026-08-19 — Self-guiding traveler intake

The traveler profile now **guides the person filling it in** — by itself, or through
any assistant they hand it to — and captures the whole journey rather than just the
in-destination experience. A traveler arriving at a blank form gets a two-to-three
minute starred first pass, recognition menus instead of open prompts, and an embedded
interview that travels to any model family. What they enter is carried all the way
through to the derived per-traveler model.

### Added
- **Embedded portable interview (`templates/traveler-intake.template.md`).** A
  model-agnostic guide below a clear end-of-profile delimiter. Upload the whole file
  to any assistant, say "help me fill this out", and get a section-by-section
  interview — one section at a time, choices offered, "skip" always valid, nothing
  invented — followed by one clean filled profile with the guide stripped. Harmless
  to a hand-filler who leaves it in place.
- **Cold-start essentials.** Ten starred fields, one per qualifying section, each
  answerable by recognition or a short phrase. The star means *start here*, never
  *required* — a blank profile has always been an operator fallback in this engine,
  not a failure.
- **Recognition menus for Interests and Desires.** A tick-what-sparks interest
  palette and a fifteen-item desire-archetype palette, so the two most open prompts
  in the form no longer start from a blank page. The archetype wording doubles as a
  theme-tag vocabulary, which sharpens desire-overlap matching.
- **Take-off→landing coverage.** New `Getting there & back` section (`Leaving from`,
  `Arrive / leave`, `Journey comfort`, `Passport`) and `Where you stay` pair
  (`Lodging style`, `Rooming`), plus `Party` and `Special occasion?`. Each links to
  its trip-level home — Logistics, Accommodation, Group — and refines it rather than
  restating it.
- **Fail-closed passport non-publication check (`agents/06-validator.md`).** Passport
  is captured as issuing country and validity month only, never a number. The
  validator now fails the trip if either reaches the published render path, and an
  undetermined result is a failure rather than a clean pass — so the field ships with
  its guard rather than on a documented promise.

### Changed
- **Lifecycle facets: six → nine (`reference/data-model.md`).** The facet table gains
  Party, Journey & origin, and Accommodation, each with its link target; both prose
  sites that enumerate the facets now agree with the table.
- **Enrichment carry-through (`agents/00-enrichment.md`).** All nine facets carried
  with every field label quoted, `Special occasion?` carried explicitly as a
  non-facet, and the desire parse anchored on its labels so the hub and validator
  `Priority tier` columns have something to bind to.
- **Desire label `Priority:` → `Priority tier:` (`templates/traveler-intake.template.md`).**
  Aligns the form to the label the data model, hub planner, and validator already use.

### Fixed
- **Non-conformant need-category values.** The data model's worked examples used
  `Required rest` and `Heat tolerance`, neither a member of its own enum; corrected
  to `Rest` and `Heat`. The enrichment agent's category vocabulary was corrected the
  same way. The template's enum was already correct and is unchanged.

### Notes
- Six of the eighteen existing facet labels were unquoted in the enrichment
  carry-through block while that block asserted a parse-by-the-labels contract;
  repaired in passing since the block was being rewritten.
- The matching facet enumeration in `CLAUDE.md` is carried separately — see the
  release PR.

## [0.7.0] — 2026-07-26 — Faithful site rendering

The published site now renders the plan **faithfully and legibly**: every event
carries a standard, validator-gated map link; days that split the group show as
parallel labeled tracks instead of duplicate pages; day headers read as editorial
travel voice rather than AI meta-notes; and the full plan — including split tracks
— round-trips into the site with nothing silently dropped.

### Added
- **Standard map-link component + location invariant (`reference/site-layout-spec.md`).**
  One `.map-link` treatment across every card tier, sourced from
  `outputs/links-reference.md` — one venue, one URL, everywhere it appears. Every
  event card carries exactly one; transit connectors carry none.
- **Location-invariant validator gate (`agents/06-validator.md`).** A new audit —
  every itinerary event must resolve to a map (or official-site fallback) link, and
  a missing link is Critical, so a trip with a missing link fails validation.
- **Day-header content contract (`reference/site-layout-spec.md`).** Day headers are
  specified as {day theme or anchor place} + {one editorial tagline}, with a ban
  list for meta/AI phrasing, voice exemplars, and a worked before/after. The hub's
  day-header output is bound to the contract.
- **First-class split-day component (`reference/site-layout-spec.md`).** A day that
  splits the group renders as N≥2 parallel labeled track columns, each with its own
  map and named split/rejoin endpoints, from the hub's Parallel Track blocks —
  replacing the old duplicate-full-day-page treatment.
- **Plan/site single-sourcing & round-trip fidelity (spec §9).** The site is
  single-sourced from `outputs/`; every plan element resolves to a rendered
  component or a named exclusion (surjective plan→site, nothing silently dropped),
  checked at build and at every update.
- **ADR-005 — Location invariant.** Records the cross-cutting decision that the
  split-day and unification slices build on.

### Notes
- A spec/contract release — the deliverables are the site-layout spec, the
  validator, and the hub contracts; a site is generated per trip from them.
- Follow-ups noted for a later release: re-synthesizing the Tokyo worked example out
  of its legacy duplicate-page form, and wiring the day-template nightlife block
  that §9's round-trip mapping references.

## [0.6.0] — 2026-07-01 — Destination ideation

The front of IDEATION: help a group decide *where* to go before any destination
is fixed. From each traveler's individual destination leanings, the planner now
derives one ranked group shortlist to choose from — so a trip can start at "we
don't know where to go yet" instead of assuming a destination is already picked.

### Added
- **Destination Ideation agent (`agents/destination-ideation.md`)** — reads every
  traveler's destination leanings (`Would love` / `Rather skip` / `Trip vibe`) and
  writes `outputs/destination-shortlist.md`, a ranked group shortlist. Ranking is
  **equity-weighted coverage**: love-count adjusted so every traveler is
  represented near the top, `Rather skip` as a hard veto, and `Trip vibe` as the
  rationale. It recommends only — the group decides, nothing auto-picks — and hands
  off to DISCOVERY once a destination is chosen.
- **Worked example (`examples/ideation-demo/`)** — a four-traveler run showing the
  ranked shortlist, an applied veto, and the equity case (a lone-lover destination
  kept that a popularity-only ranking would drop).

### Notes
- Realizes the data model's forward-hook (a): the per-traveler files still only
  *capture* leanings; the aggregation lives in the new agent, never in an
  individual file. Enrichment and the data model were updated to point at the
  now-realized hook.
- Ships the destination-ideation seed (group destination recommendation). A fuller
  ideation flow (group shortlist → group decision → DISCOVERY handoff) remains
  documented future growth.

## [0.5.0] — 2026-07-01 — Publish-flow privacy & lifecycle

Rounds out the private-publish flow (v0.1.0) with the privacy and lifecycle
controls a real "site manager" needs: hide the destination in the repo name, see
every published site at a glance, and take a site back down.

### Added
- **Opaque repo names (`publish --opaque`)** — name the per-trip repo with a random
  token (e.g. `trip-a1b2c3d4e5`) instead of the readable `[destination]-[year]-trip`,
  so the destination and year no longer show on your public profile. The name is
  saved to `.publish-slug`, so `update`/`rotate`/`unpublish` resolve the same repo.
  Readable names stay the default (opt in per publish).
- **`list` — published-site inventory (read-only)** — one command shows every trip
  under `trips/`: its repo, live URL (or "not published"), last-published vs
  last-edited, and a **stale** flag when your local build is newer than what's
  deployed. Never writes, encrypts, or pushes.
- **`unpublish` — takedown** — take a published site down: by default it deletes the
  per-trip repo (removing the site *and* the destination/year in its name), or
  `--disable-pages-only` keeps the repo and just takes the site offline. It confirms
  before an irreversible delete, is idempotent (a no-op if already gone), and is
  honest that content may linger in third-party caches after takedown.

### Notes
- Deleting a repo needs the `delete_repo` gh scope (`gh auth refresh -h github.com -s delete_repo`);
  `unpublish` says so and offers `--disable-pages-only` as the no-extra-scope path.
- The privacy model is unchanged: published bytes are world-fetchable ciphertext
  (secret-gated by passphrase + 600k-KDF, not access-controlled). `--opaque` closes
  the repo-name metadata leak; commit timestamps still reveal publish activity.
- Regression tests extended (`test-publish-guard.sh` groups H/I/J) covering opaque
  naming, the inventory helpers, and the takedown safety gates.

## [0.4.0] — 2026-07-01 — Orchestration: equity-aware planning & replanning

The group planner that runs all three optimization engines and reconciles them
into one itinerary — and, when plans fall through or someone's wishes change,
rebuilds it fairly instead of grabbing any replacement. Built on v0.3.0's engines;
this is the layer that makes them work together for the whole group.

### Added
- **Equity-aware planning** — the planner runs the routing, experience, and
  fair-coverage engines together and reconciles where they disagree (a tight route
  vs. protecting one person's must-see vs. a needed rest day) into a single plan —
  everyone's needs applied first as hard limits, plus a per-traveler view of who is
  served and where the trip is lopsided. When the objectives collide, the tradeoff
  is named and shown, never silently dropped.
- **Equity-aware replanning ("who lost what")** — when a booking falls through, or
  a traveler edits their profile (a new must-see, a dropped wish), the planner works
  out who lost the most, rebuilds toward them first, and regroups the scattered gaps
  into one coherent thread rather than unrelated swaps — keeping everyone's needs
  intact through the recovery.
- **Side-bars / group splits** — when someone wants their own time, or interests
  diverge enough, the planner proposes single / small-group / full-group side-bars
  instead of dragging everyone along or leaving anyone out. The default stays one
  shared plan, and any moment a traveler marks whole-group is never split off.

### Notes
- The *structure* ships here; the *scoring* is deliberately deferred — how the three
  objectives rank, how "hardest-hit" and "enough divergence" are measured, and how
  gaps cluster into a theme are left to a later design pass. Nothing scores yet; the
  planner reasons with the structure and shows its work.
- Every recovery and every side-bar still honors each traveler's needs as hard
  floors — a split or a rebuild never becomes a way to slip a need violation through.

## [0.3.0] — 2026-07-01 — Optimization engines

The first engines that actually *optimize* a trip against the satisfaction
substrate. Each one works a single objective and surfaces its read for the group
planner to weigh — built on v0.2.0; the planner that runs all three and reconciles
them across the whole group comes next.

### Added
- **Geographic routing** — treats travel between stops as a real, minimizable
  cost: it orders each day so the group spends less time in transit and more time
  at the places, surfaces that cost so one plan can be compared against another,
  and spends any freed time on a single deliberate use. It never routes a traveler
  through a must-avoid (a heat window, a mobility limit).
- **Experience balance** — shapes how the trip *feels* across the days, not just
  how tiring it is: it spreads new and exciting things out instead of front-loading
  them, and avoids stacking too many big days back-to-back with no breather.
  Required rest (a real need) is always protected.
- **Fair coverage** — makes sure the plan serves everyone, not just the majority:
  a want several travelers share is an easy win, while a want only one person holds
  is protected so no one is quietly left out. It works on wants only — must-haves
  are always met.

### Notes
- These engines *surface* their objective; the group planner that runs all three
  and reconciles them (efficient routing vs. everyone's coverage vs. the trip's
  arc) is the next release — equity-aware planning.
- Every engine optimizes *within* each traveler's hard needs. Needs are floors,
  never traded away for a better score.

## [0.2.0] — 2026-06-28 — Satisfaction substrate

A structured foundation for understanding what each traveler wants and tracking
what's settled — so trips can be planned for the whole group and picked up from
any stage. Foundation only: nothing optimizes yet.

### Added
- **Per-traveler profiles** — each traveler gets their own intake form (fill it
  yourself, or have an agent walk you through it): needs (must-haves), desires
  (anchor / wish / nice-to-have), plus destination leanings, dates, budget,
  travel style, interests, and people-dynamics. All optional — fill what fits
  your trip's stage.
- **Per-event status** (`planned` / `locked` / `firmed` / `option`) — re-running
  the planner refines only what's still open and leaves booked or settled
  choices alone.
- **Satisfaction metrics** — defined dimensions: needs-compliance (pass/fail),
  desire-coverage, and balance signals for equity, experience, and rest.
- **Data-model document** — the canonical architecture for the satisfaction
  layer (storage homes, reconciliation, lifecycle).

### Changed
- Iteration and resequencing touch only `planned` events; `locked` / `firmed`
  events are preserved unless you name them, and the validator flags any
  unintended change.

### Notes
- Per-traveler data stays in private, git-ignored working files and is never
  published.
- This release is substrate — nothing optimizes yet. The optimization engines,
  equity-aware (re)planning, group side-bars, and destination ideation build on
  it next.

## [0.1.0] — 2026-07-01 — Private-by-default trip sites

- Published trip sites are encrypted client-side and private by default — only
  ciphertext is pushed to the public per-trip repo, gated by a passphrase, so a
  trip's details are never world-readable.
- A fail-closed pre-push guard refuses to publish anything but verified
  ciphertext.
