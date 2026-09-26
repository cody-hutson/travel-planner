# ADR-029: What the private trip site may show — the coordination test, the share mark, and nothing personal on a public page

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1242, one of three records of the *The site serves every phase: the founding
  decision* milestone, beside [the site phase-model record](ADR-030-site-phase-model-and-surface-contract.md)
  (#1296) and [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md)
  (#1545). `ADR-026` names this card as the only one that may move a cell of its channel-axis
  table; this record is that move, together with the class-side change the move needs.
- **The verdict this record carries was locked by the operator, not chosen here.** It is CR-1d,
  recorded on the card's design sub-task #1385 on 2026-09-26, after four design passes and four
  independent reviews. Two decisions the operator added afterwards are transcribed as this record's
  sixth and seventh safeguards: a publish-time check of the non-publishable field class (decision
  P, recorded on #1546), and a projection that keeps that class away from every writer of a file
  the site build reads (decision Q, recorded on #1385). The execution conditions come from the
  milestone's fit review and its scope lock, CR-2, both recorded on #1369.
- **What this record is.** A decision about **what the private, encrypted trip site may show the
  travel group, and what never appears on any page.** It decides the coordination test, the list of
  what is in and what is out, the mark that lets a traveller share a desire or an occasion, how a
  private occasion appears, the seven safeguards any build owes, and how the class model reads the
  values the group may see.
- **What this record is not.** It builds nothing, and in this release it changes no `publish:`
  value, no fence line and no per-verb requirement row: every change it decides lands in a later
  slice. It does not decide where an item shows or in which phase — that is the site phase-model
  record's — and it does not decide what of a traveller's contact and emergency details the group
  sees, which is the contact and emergency record's.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the maintainer's, taken at this milestone's close, and it moves **both** halves
  of a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  `reference/adr/README.md`. The site phase-model record and the contact and emergency record each
  name this record's `Accepted` status as the precondition of their own flip, so this record flips
  first. The same close records, inside `ADR-009`, the part of `ADR-009` § *Decision* 4 this record
  supersedes (§ *Decision* 7 below).

## Context

**The gap, as the card states it.** `scripts/publish-trip-site.sh` has two publish limbs with
different guards: the encrypted limb runs `verify_ciphertext`, and the `--plaintext` limb runs a
content predicate, `verify_publishable_content`, because every ciphertext check inverts on plaintext
input (`ADR-008`). The data model does not make the same distinction. `publish:` is a property of the
artifact, not of the limb, and `reference/data-architecture.md` § 5.1 defines `internal-hard` as
*"never rendered **and** carrying values that must not reach a rendered page **in any form, including
anonymized**"*. A rendered page carries no encryption qualifier there, so an artifact unsafe on a
world-readable page is equally forbidden on a passphrase-gated one, and every capability wanting
per-traveller visibility inherits a prohibition calibrated to the plaintext limb.

**Partly addressed, one level up.** `ADR-026` § *Decision* 3 makes carry a relation —
`may-carry(v, A, CH) = ¬denied(v, A) ∧ carry-envelope(CH) admits v` — and gives the channel side
two axes, `audience` and `observers`, inert until this record. It names this card as the only one
that may move a cell, without naming the cell. The joint source-binding step of this milestone,
recorded on #1383, named it: **CH-1 · encrypted limb · `audience`**, whose value is `party` — the
only cell on which the two CH-1 limbs differ, and so the only channel-side input through which
`may-carry` can return different verdicts on them. The same step found the move necessary and not
sufficient: `internal-hard` is not a term of `may-carry`, so a widening has one footprint on the
channel side and one on the class side.

**What the operator's facts settled.** The group already sees the attributed destination shortlist
today, shared openly by hand, and travellers keep their leanings open within the party; only people
outside the party must not see them. Those facts were recorded on #1385 before the second design
pass. A site surface therefore moves an existing flow onto a governed channel rather than creating a
new exposure inside the party.

**How the verdict was reached.** Four design passes each weighed a narrower widening — the
destination leanings alone, consented per trip, admitted by their content and bound to their
shortlist by a digest — and four independent reviews each found the next condition it needed. At
CR-1d the operator locked a different and simpler rule: the private, encrypted site belongs to the
group, personal information the group needs to coordinate may appear there, and nothing personal
ever appears on a public page. **The detailed enforcement design of the third and fourth passes does
not carry forward.** It defended against a public site, which this product does not have, and it is
reference material for the later slices rather than a requirement of this record.

**Two records beside this one carry the rest.** The site phase-model record decides where each item
this record admits renders, in which phase, and under which section ceiling. The contact and
emergency record revisits `ADR-004` against this verdict, and decides what of a traveller's contact
and emergency details the group sees.

**Baseline.** Every corpus fact in this record was read live at `8b2ac05`, the base of this release.
Counts are authored to `ADR-013` form **F1**, anchored measurement.

## Decision drivers

- **The private site is the group's coordination surface.** The operator's facts make the group, not
  the organizer alone, the audience of the private site, and the list below is what that group needs
  to coordinate a trip.
- **Nothing personal on a public page.** A GitHub Pages repository is public: the encrypted limb
  publishes world-fetchable ciphertext, and the `--plaintext` limb is world-readable. Whatever the
  private site admits, the public path admits none of it.
- **Class-shaped, never an exception to a bound.** `ADR-025`'s never-carry 2, its § *Decision* 4
  render prohibition and `ADR-010` § 4 each track the class rather than deciding a bound of their
  own. The joint source-binding step found all three class-derived for a first-party value, and
  every value this record admits is first-party, because people who did not fill in their own form
  are out. A verdict expressed as a change to what the class reads therefore moves those bounds by
  pointer and supersedes no journey record; a verdict that left the class unchanged would contradict
  them.
- **`ADR-006` stands, and consent is not a function of transport.** A party member who never filed
  a profile consented to nothing, and encryption does not manufacture consent.
- **The producer excludes; the build never redacts.** No redaction step exists on the publish path
  (`ADR-026` § *Decision* 3), and paraphrase is out of reach of any string match
  (`reference/data-architecture.md` § 5.5). A withheld or reduced form is something a writer
  produces, never something the publish removes.
- **Data minimization first, then a mechanical check of the outcome.** A value that no writer of a
  group-visible file ever receives cannot reach the group's page. A check of what the build reads is
  defense in depth on top of that.
- **A published value cannot be unpublished.** It persists in caches, screenshots and anything
  forwarded, so the verdict is EXPENSIVE once a slice ships it, and every exposure it admits is
  stated rather than implied.

## Options considered

**The verdict.** Four options were weighed at the first design pass and narrowed across the next
three. CR-1d locked a fifth shape.

| Option | What the private site would carry | Disposition |
|---|---|---|
| **VO-1 — nothing moves** | no leaning value, in any form, on either limb | **Not locked.** It was safe, and it left an existing flow ungoverned: the group already relays the attributed shortlist by hand. It also left the milestone's pre-plan page with nothing to render, the empty surface #1241's third acceptance criterion rules out |
| **VO-2 — the intake position, as stated** | the shortlist as its writer produces it: names, counts, vetoes with their reasons, and verbatim leaning text | **Rejected from the first pass onward.** It renders a veto's free-text reason and a leaning's verbatim text, which every later pass kept off the page |
| **VO-3 — aggregate only** | candidates and counts, with no roster name beside any leaning | **Rejected at the second pass.** It lost its only advantage inside the party to the operator's facts — leanings are already open there — and it still needed the person record's class to move |
| **VO-4, revised as VO-4R to VO-4R4 — party leanings, consented per trip** | named leanings in a written allowlist form, only on a trip where every traveller who filed a form agreed, admitted by their content and bound to the shortlist by a digest | **Not carried forward.** Each revision needed a further condition, and CR-1d found that machinery defending against a public site the product does not have |
| **The group-site rule** | what the group needs to coordinate the trip, under the coordination test and its lists, with a share mark for desires and for the occasion | **Locked at CR-1d.** § *Decision* 1 to 6 |

**How the change is expressed.** The card asked whether a widening is a new class, a per-limb value,
or a model where the site declares its limb.

| Mechanism | Disposition |
|---|---|
| **A new value of the `publish:` enum**, such as a group-only class | **Rejected.** § 5.1's enum is closed at four values, and an artifact class cannot isolate a field: the traveller model and the person record carry values that are out beside values that are in, so no class value of either artifact can admit one without the other |
| **A per-limb `publish:` value, or a site that declares its limb** | **Rejected.** The render is limb-blind: the build writes one page before any limb is chosen and both limbs ship that page, so a limb-keyed class would need a build-time limb input the build does not have. The site phase-model record decides the shape limb-blind as well |
| **A field-keyed exception inside `internal-hard`**, consent-gated and bound by content and digest | **Not carried forward**, with the rest of the fourth pass's enforcement design |
| **A reading of the class for the values the group may see** — the class values stay; for those values alone, *never rendered* reads *never on a public page* on the private site; they reach the render only through a `bound` artifact their producer writes; and the public path refuses group-only content by structure | **Chosen.** § *Decision* 1 and 7. It changes no class value of the traveller model, the traveller file or the person record; the one class value that moves is the destination shortlist's |

## Decision

### 1. The verdict, and the coordination test

> **The private, encrypted trip site belongs to the travel group.** Personal information the group
> needs to coordinate the trip may appear there. **Nothing personal ever appears on a public page.**

**The rule.** In, if the group needs it to coordinate the trip. Out, if it is about the person rather
than the trip. Anything in between is personal by default, and the traveller can mark it shareable.

**Its reach over the two publish limbs.** On CH-1's encrypted limb — whose declared envelope, after
the `observers` correction this release carries into `ADR-026`, is (`party`, `world`) — the values in
§ 2's list may reach the render as § 4 and the site phase-model record admit them. On the
`--plaintext` limb, whose `audience` is `world`, none of them may, in any form (§ 6, safeguard 2).
**This is the one cell of `ADR-026`'s channel-axis table this record moves**: the encrypted limb's
`audience` cell, `party`, becomes load-bearing, because `carry-envelope(CH-1 encrypted) admits v` is
now defined — for exactly the values § 2 lists as in. The `observers` cell stays `world` on both
limbs; it is an input to the threat model in § 8, not the cell that moves. The channel-side move is
necessary and not sufficient; the class-side change is § 7.

**Its consumer.** [The site phase-model record](ADR-030-site-phase-model-and-surface-contract.md) is
the site-channel consumer of this verdict. Whether and where each item in § 2 shows, and in which
phase, is that record's call, made through its section ceiling and its render table; this record
decides only what may appear.

### 2. What may appear on the private site, and what never appears on any page

**IN — may appear on the private site.** Whether and where each item shows is the site phase-model
record's call.

- who is coming: name and relationship;
- destination leanings: `Would love`, `Rather skip`, `Trip vibe`, and the destination shortlist built
  from them;
- dates: can travel, blackout dates, trip length, arrive / leave;
- getting there: leaving from, journey comfort;
- where you stay: lodging style, rooming;
- interests and tastes: interests, cuisine appetite, been here before, already done;
- pace and day rhythm;
- **desires the traveller marks as group-facing** (§ 3);
- **the special occasion, only if the traveller marks it not private** (§ 3).

**OUT — never on any page.**

- costs and money: the cost estimate, comfort range, splurge appetite, budget caps;
- identification: the passport field;
- needs and must-haves (health). The plan honours them without displaying them (§ 5);
- **people who did not fill in their own form**, including a traveller's `Party` entry. `ADR-006`
  stands. Two readings are recorded so the lists cannot contradict each other. A roster name is
  *who is coming* for every member, so it shows for everyone and nothing else about a person who did
  not file does — the operator's decision on the site record's design sub-task, #1388. And an
  emergency contact's name, shown on the traveller's attestation that the contact agreed, is the
  contact and emergency record's decision rather than an exception to this row;
- **contact and emergency details** — what of them the group sees is decided by
  [the contact and emergency record](ADR-031-contact-emergency-group-visibility.md); everything else
  of them stays out;
- planner and operator internals: the trip log, the validation report, cross-trip group records;
- personal desires (unmarked), novelty vs comfort, planning style, togetherness (group time,
  whole-group moments, solo), *split off with*, and satisfaction metrics.

**Every value on the IN list is first-party.** People who did not fill in their own form are out, so
nothing third-party-sourced is admitted by this list, and `ADR-006`'s third-party prohibition is not
touched by it.

### 3. The share mark, and the concealed occasion

**Requirement 1 — a *share with the group* mark** on each desire and on the special occasion.
**Unmarked means personal.** The mark is the **only** path by which a desire or the occasion reaches
any rendered artifact; an absent or malformed mark reads as unmarked. The contact and emergency record
reuses this mark for a traveller's in-trip contact, by citation; this requirement is unchanged by that
reuse.

**Requirement 2 — a private occasion that becomes a trip event** appears on the calendar as a
**concealed block**: a generic title, its attendees and its time, with no identifying details. How the
block renders, and how the concealment binds every component that could identify the event, is the
site phase-model record's.

### 4. How the values reach the page — by carrier, never by the build reading a traveller's files

**The build reads none of `travelers/<traveler>.md`, `outputs/traveler-model.md` or
`people/<person>.md`, in any state.** Each stays at its class: the traveller file `internal`, the
traveller model and the person record `internal-hard`. A value on § 2's IN list reaches the render
only through a `bound` artifact that its producer writes — the trip context for who is coming and the
trip's own dates, the destination shortlist for the leanings, the itinerary for what the plan
expresses, and the further carriers the site phase-model record and the contact and emergency record
decide.

**The destination shortlist becomes `bound`.** `outputs/destination-shortlist.md` moves from
`internal` to `bound`, so that the build may read it. The move lands in the site phase-model record's
render slice, in one commit with its § 9.1 rows, and this release changes no `publish:` value.

**The source binding — one class in both enrichment states.** The joint source-binding step fixed it,
and this record states it as the reach clause of the verdict. A value of `Would love`, `Rather skip`
or `Trip vibe`, and everything the destination shortlist derives from them — candidates, love-counts
and lover names, vetoes, vibe lines, equity notes, coverage lines — is bound by the class of those
fields' source of record, `outputs/traveler-model.md`, in every artifact that carries it and whichever
file it was read from. The shortlist writer's fallback read of `travelers/<traveler>.md`, before the
model is built, changes where the bytes come from and never the bound.

**A-1 — a value from the person record, at the value level.** A value from `people/<person>.md`
carries the person record's class, `internal-hard`, in every artifact that carries it, by union with
that artifact's own class and never by override. For the IN fields only, *never rendered* reads
*never on a public page* on the private site. The person-record fields it covers, read from
`templates/person-intake.template.md` at `8b2ac05`, are `Would love`, `Rather skip`, `Leaving from`,
`Journey comfort`, `Lodging style`, `Interests`, `Cuisine appetite`, `Pace` and `Day rhythm`.

### 5. An out value stays out wherever it is carried

**The OUT list binds by the kind of value, not by the carrier.** An OUT value stays out wherever a
`bound` artifact carries it, and the exclusion is its producer's, never a build-side redaction. A
need, or who splits off with whom, is never named on any page.

**The planner honours needs under neutral labels.** A need shapes the plan through labels that name no
one — a *midday heat break*, never a label that names the traveller whose need it is — and the producer
does the excluding. The producers that owe this, all in Wave 1:

- the hub planner's TRIP OVERVIEW, Constraint Compliance, and the Parallel Track *Trigger* and
  *Needs honored* lines, and the `.track-why` text the site renders from them;
- the `Applies to:` lines of the trip context's constraints;
- the destination shortlist's writer, `agents/destination-ideation.md`. A veto reason that states or
  implies an OUT kind — money, a need, a person who did not file, togetherness — is left out whole,
  never trimmed or reworded. The veto line itself stays, because hiding an applied veto would mislead
  the group.

**Sites published before the Wave-1 fix keep today's labels.** Nothing is republished to retrofit
them. **The Tokyo worked example keeps its labels too**: it is a byte-frozen regression witness that a
required check grades, so a neutral-label witness is a new fixture rather than an edit to it.

### 6. The seven safeguards

**1 — Travellers are told at collection what the group sees**, replacing both intake forms' current
*never published* promise. The notice says what the private site shows, what the share mark does, and
that a change reaches the site at the organizer's next update while copies already seen may persist.
The same edit replaces the three example answers the forms carry today that put an OUT kind inside an
IN line — the person form's `Lodging style` and the trip form's `Rooming` and `Special occasion?` —
with examples that carry none.

**2 — Nothing personal on a public page.** The refusal on the `--plaintext` limb is **structural**: a
render carrying a group-only section — the destination shortlist's section, the group snapshot section
or the group contacts section — is refused by that section's presence, with no matching on values and
no redaction step. How the refusal keys on group-only content the plan itself carries, such as a
marked desire or a shared occasion the itinerary names, is Wave 1's to design under the same rule:
structural, never by value, never by redaction.

**3 — People who did not fill in their own form are excluded**, with the two readings § 2 records:
the roster name shows for everyone, and an emergency contact's name follows the contact and emergency
record. How the build tells who filed, and the fail-closed default where it cannot, is the site
phase-model record's.

**4 — Refusal and removal are honoured at the next update.** *The next update* is the organizer's
next full site update — reconcile, rebuild, confirm, republish. A refusal, a removal or a withdrawal
is recorded only through a verb that runs the reconcile step, so every staleness report shows the
page as behind until the next update carries it. No publish gate is added: nothing may block a
publish because something is out of date. The gap this leaves is declared: a form edited by hand, with
no verb, is observed only at the next reconcile.

**5 — The fix for the rotation defect tracked privately ships before any of this goes live.**

**6 — A publish-time check of the non-publishable field class** (decision P). Before every publish —
on the private site as on a public page, and in every phase, IDEATION included — a script checks every
file the site build reads for the field class of `reference/data-architecture.md` § 5.6: its `field`
rows, today `Passport` and `Documents`, which the contact and emergency record's way-to-reach joins
when its capture ships. A distinctive value — a way-to-reach, a date — is matched exactly; a value that
is an ordinary word — a country — is matched by its label; any match stops the publish. **This is
defense in depth: a mechanical check of the outcome, on top of the render's rule that it never reads
those fields, which continues to hold.** The residual: an ordinary-word value restated without its
label is not caught by this check, and under safeguard 7 no such value reaches a writer of a file the
site build reads, so the label match is a backstop rather than the only barrier. Whether to extend the
check to free-text OUT items is Wave 1's call, after measuring its false positives.

**7 — The non-publishable fields never reach a group-page writer** (decision Q). No agent step that
writes a file the site build reads receives a value of the non-publishable field class: § 5.6's
`field` rows, today `Passport` and `Documents`. The contact and emergency record's way-to-reach is
already kept out by that record's storage rule. Those writers read a script-made projection of the
traveller data that omits the class. A step that needs one of those fields for its own work, such as
the per-traveller document derivation, writes only files the site build never reads. **Safeguard 7
extends the contact and emergency record's data minimization to the whole field class; safeguard 6
stays as the mechanical check of the outcome.** Carried to Wave 1, and stated as conditions in the site
phase-model record and the contact and emergency record by citation to this safeguard: the projection
script; the split between writing internal files from full inputs and writing group-visible files
from the projection; and the group snapshot's and the group contacts file's writer inputs, re-pointed
to the projection.

### 7. What this record changes in the class model, and what it supersedes

- **For the IN values only, the class rules that read *never rendered* read *never on a public page*
  on the private site** — `ADR-009` § *Decision* 4, in part, and the matching person-record fields
  (A-1).
- **`ADR-025` § *Decision* 4's *that is permanent* is read as following from the class.** It is
  permanence against thresholds and state — no count, engagement value or accumulation opens the
  render ceiling — and not immunity from the record that owns the class.
- **The destination shortlist becomes `bound`** (§ 4).
- **Everything OUT stays exactly as it is today.**

**The part of `ADR-009` § *Decision* 4 this record supersedes, and the rest that stands.** This record
supersedes **one site** of Decision 4: 4.1's `internal-hard` sentence, which it reads for the IN values
as above. **The rest of Decision 4 stands as decided.** § 4's composition clause — *union, never by
override* — is not superseded: A-1 composes by union. 4.1's `bound` sentence is not superseded either:
it names § 9.1 as the authority, and its growth is a claim the new classes make stale once built,
which this release records as a pointer in `ADR-009` rather than as a supersession. The supersession
is recorded inside `ADR-009` in its eighth amendment's form — a `Status:`-line entry and an inline
marker, the superseded sentence retained as decided — at this milestone's close, in the same change
that flips this record to `Accepted`, and not before.

**The journey records' bounds move by pointer.** Never-carry 2 of `ADR-025`, its § *Decision* 4 render
prohibition and `ADR-010` § 4's bar on traveller identity reaching the render each carry a dated
pointer to this record in this release. Each pointer states that on the private site, rendering a
filer's IN values under their roster name is admitted by this verdict even though it lets a reader
infer who filed their own form; that the engagement value itself is never rendered; and that nothing
of it reaches a public page. **The approval attribution `ADR-010` § 4 bounds is not an IN value**, so
its bar on a receipt, a pseudonym or a key fingerprint stands exactly as written, and the approval
milestone's cards inherit nothing wider from this record.

### 8. The threat model the passphrase is assumed to defeat

**Readership is whoever holds the passphrase; the `audience` cell is a declaration of who is given
it.** It starts from `ADR-026`'s declared worst case for the encrypted limb, after this release's
correction: readable by the party, its bytes fetchable by anyone.

| Vector | What holds | What does not |
|---|---|---|
| **A shared passphrase** | the group receives it by design, and the verdict addresses that group | a passphrase shared beyond the party widens readership, and nothing in the engine observes or undoes that; the notice says so (safeguard 1) |
| **A forwarded link** | a link without the passphrase reaches only the passphrase entry page and ciphertext | a link forwarded with the passphrase is the row above |
| **A Pages repository that is public** | protection rests on passphrase strength and the key-derivation cost, not on access control; the ciphertext's `observers` value is `world` | an offline guess at the passphrase is the one path from `observers` to readership, which is why the rotation fix ships first (safeguard 5) |
| **Browser cache** | a republish replaces what the site serves | a copy already cached persists; removal reaches forward only (safeguard 4) |
| **A screenshot** | nothing on the page is protected against it, and nothing claims to be | a screenshot persists beyond every update; removal reaches forward only |

**What the passphrase defeats:** a reader outside the party who does not hold it. **What it does not
defeat:** a reader who holds it, and a copy already taken. That is why the public path carries none of
§ 2's IN list, and why every OUT value stays out even on the private site.

### 9. What does not move, whatever else does

- **`ADR-006`.** A `[THIRD-PARTY]` value is never published, in attributed or anonymized form.
  Consent is not a function of transport, and provenance-marking never establishes it.
- **`ADR-004`'s contact and emergency model binds on its own terms**, except where the contact and
  emergency record revisits it.
- **`ADR-025`'s never-carry 3.** A `both-marks` entry never carries across `EB-2`, permanently, by
  `ADR-014`'s refusal — a decision, not a class fact, and untouched here.
- **The engagement value itself** is never rendered (`ADR-025`'s never-carry 5).
- **`reference/data-architecture.md` § 5.1's four-value enum and the single-valued `publish:` column.**
  No enum value is added.

### 10. The enforcement clause

- **`verify_ciphertext` does not move.** It grades that the published page is ciphertext of the local
  render, not what the render contains, and it stays content-blind by design.
- **`verify_publishable_content` does not move.** Its predicate, its class source and § 5.6's fence
  are unchanged by this record.
- **What does move is on the producer side and the public path, all in Wave 1.** The build reads only
  `bound` artifacts, and the values in § 2 reach them only through their producers (§ 4, § 5). The
  public path refuses group-only content by structure (safeguard 2). A publish-time check of the
  non-publishable field class runs on both limbs (safeguard 6), and the writers of group-visible files
  read a projection that omits that class (safeguard 7).

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
