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

*Authored in the commits that follow on this release branch.*

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
