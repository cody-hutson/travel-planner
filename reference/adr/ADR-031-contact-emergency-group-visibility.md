# ADR-031: Contact and emergency information on the private site — what the group sees, the emergency contact as a third party, and the carrier

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1545, one of three records of the *The site serves every phase: the founding
  decision* milestone, beside [the private-site record](ADR-029-what-the-private-site-may-show.md)
  (#1242) and [the site phase-model record](ADR-030-site-phase-model-and-surface-contract.md)
  (#1296). The operator pulled the card into the milestone when the private-site verdict was locked.
- **The precondition of this record's status flip.** This record flips to `Accepted` only after
  [the private-site record](ADR-029-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because what this record shows rides that record's
  coordination test and share mark. The flip is the maintainer's, taken at this milestone's close, and
  it moves both halves of a two-artifact state: the `Status:` line above, and this record's `Status`
  cell in `reference/adr/README.md`.
- **What it supersedes, once accepted.** This record supersedes [ADR-004](ADR-004-contact-emergency-privacy.md)
  **in part**: § 3's organizer-only visibility, for the in-trip contact, the emergency contact's name
  and whether an emergency contact is on file; § 4's guarantee, narrowed for those three to the
  private site; § 1's "never written to the published artifact", now read field by field; and the
  trade-off its Consequences accepted. Everything else in `ADR-004` stays in force. `ADR-004` is never
  marked superseded, its index cell stays `Accepted`, and this record carries no Supersedes bullet. The
  dated note inside `ADR-004` that records this lands in the milestone's closing ratify chore, in the
  same change as this record's `Accepted` flip — not in this release (§ 5).
- **What this record is.** A decision about **what of a traveller's contact and emergency details the
  group sees on the private site**: whether it sees any, at what level per traveller, how an
  emergency contact's details are handled given the contact is a third party, what the traveller opts
  in to and how they withdraw, what `ADR-004` keeps and what this record supersedes, and the carrier
  that brings the group-visible items to the page.
- **What this record is not.** It does not decide where the carrier's section sits in each phase: the
  site phase-model record's render table places it, by citation to this record. It does not decide
  what the private site may show in general, or the share mark, which it reuses by citation. It builds
  nothing, and in this release it changes no `publish:` value, no fence line and no per-verb
  requirement row.
- **How it was decided.** In a design on the card's design sub-task #1546, then the operator's
  decisions D1 to D3; the milestone's fit review and its scope lock, CR-2, recorded on #1369; a
  scoped carrier design on #1546, ordered by CR-2's third call; and the operator's lock of that
  carrier as decision K, with the storage rule S, the publish-time check P and the approval rule
  MG-C1. Decision Q, recorded on #1385, binds the carrier's writer input through the private-site
  record's safeguard 7.

## Context

**`ADR-004` keeps contact and emergency details organizer-only.** It stores a traveller's contact
method and one emergency contact in the local trip store only, never in the published artifact,
"even encrypted", and names its trade-off: a traveller who is not the organizer cannot see the
others' emergency contacts on the site — "acceptable, since the organizer coordinates".

**The private-site record removes the premise that trade-off rested on.** The private, encrypted
trip site is now the group's coordination surface for the whole trip, under one rule: in if the group
needs it to coordinate the trip; out if it is about the person. If something happens on the trip, the
group — not only the organizer — may need to know who to contact, and under `ADR-004` the site cannot
say.

**`ADR-004`'s capture is not built.** At `8b2ac05`, the base of this release, neither intake form
carries a contact or emergency field, and the non-publishable class's declaration in
`reference/data-architecture.md` § 5.6 carries no contact selector. `ADR-004`'s follow-on slices — the
local capture, the validator's non-publication check and the intake opt-in step — are unscoped.

**An emergency contact is a third party.** `ADR-006` stands: its refusal to capture identity data is
scoped to party members, the people travelling without a profile of their own, and its guarantee that
nothing a third party reported is published covers needs. The private-site record's safeguard 3
excludes people who did not fill in their own form.

**The operator's position** at the private-site verdict was that contact and emergency details should
be shared at a high level, for the group to see if something happens. It is recorded as the position
to be argued, not as a decision already taken.

**The inputs this record is bound by.** The private-site record's verdict, its share mark and its
seven safeguards; `ADR-026`'s carry model for the site channel; and the rule that the public publish
path never carries contact or emergency data.

## Decision drivers

1. **The coordination test.** In if the group needs it to coordinate the trip; out if it is about the
   person.
2. **The emergency contact is a third party.** `ADR-006` stands, and the private-site record's
   safeguard 3 binds.
3. **Minimal fields for the purpose.** `ADR-004` § 2's set is closed: "No more."
4. **Consent from the person the data is about**, granular, and never given by silence or a
   pre-ticked answer.
5. **Nothing personal on a public page**, ever.
6. **Reuse existing mechanisms**: the share mark, the § 5.6 declaration, the field-scope classes, the
   reconciler and erasure.
7. **Reversibility.** A published name or number cannot be unpublished from a forwarded link, a cache
   or a screenshot, so the tier is EXPENSIVE once anything is published.

## Options considered

*Authored in the commits that follow on this release branch.*

## Decision

*Authored in the commits that follow on this release branch.*

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
