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

### What the group sees

Each option answers whether the group sees anything, at what level, and how the emergency contact's
details are handled, together.

| Option | The group sees | The emergency contact's details | Disposition |
|---|---|---|---|
| **A** — `ADR-004` stands | nothing | organizer only | **rejected.** Its premise is gone, and the group could reach no one |
| **B** — the shared in-trip contact and a trip-wide "who to tell" line | each traveller's in-trip contact, when shared; the organizer as the holder of the emergency contacts | organizer only | the design's recommendation, and the base of the locked outcome |
| **B′** — B plus a per-traveller "emergency contact on file with the organizer" line | B, and whether each traveller has one on file | organizer only | **taken by the operator's D2**, shown for every traveller who filed, as one of the emergency line's three states. Its cost is recorded under *Consequences* |
| **C** — B plus the contact's relationship to the traveller | B, plus a relationship | relationship published | **rejected.** In a small named group a relationship identifies a person, and `ADR-004` § 2's closed set stands: the relationship is never captured (CR-2's fourth call) |
| **D** — B plus the contact's name and way to reach them, on the traveller's attestation | everything | published to the group | **rejected for the way to reach the contact**, which stays with the organizer. The operator's D1 takes the name alone, shown only on the traveller's attestation that the contact agreed |
| **E** — the details on a separately encrypted, organizer-only page | B | inside a second ciphertext | **rejected.** A third party's data inside a world-fetchable ciphertext, which `ADR-004` refused even for the traveller's own data, and a new publish artifact |
| **F** — B plus a free-text "if something happens" note | B, plus the note | organizer only | **rejected.** Its obvious content is medical, which would re-open the needs row the private-site record keeps out, and free text defeats a closed list |
| **G** — B plus a deputy holder with the organizer's access | B | the organizer and a deputy | **deferred** to a candidate future card: a new role, and a second copy of a third party's data |

**Locked: B, plus D1, plus D2.** The group sees each traveller's shared in-trip contact, one line
naming who to tell, and — for each traveller who filed their own form — an emergency line that names
the contact on the traveller's attestation, says a contact is on file with the organizer, or says none
is on file.

### Where the way to reach an emergency contact is kept

| Option | Disposition |
|---|---|
| In the traveller's trip file, with the carrier's writer reading only whether it is answered — the carrier design | **superseded by S** |
| **Moved at filing, by a script, into an organizer-only file beside the traveller's trip file** — S | **chosen.** Data minimization: the organizer holds the way to reach the contact, and only the organizer and the filing script ever touch it |

### How `ADR-004` records the change

| Option | Disposition |
|---|---|
| Flip `ADR-004` to superseded, whole, when this record is accepted | **not taken.** The operator's D3 keeps `ADR-004`'s still-valid sections in force |
| The same, with a forward pointer written now | **not taken** |
| **A dated note inside `ADR-004`, in the form `ADR-009`'s eighth amendment already uses for a partial supersession** | **chosen** — the operator's D3. The note lands at the milestone's closing ratify chore, with this record's `Accepted` flip (CR-2's fifth call). `ADR-009`'s eighth amendment is the corpus precedent for recording a superseding decision in place |

### The carrier

| | Option | Disposition |
|---|---|---|
| **K1** | **A new per-trip `bound` file, `outputs/group-contacts.md`** | **chosen** — net-new, because in-place is infeasible |
| K2 | Extend the group snapshot into every phase | **rejected.** It re-opens the operator's D-3, which scopes the snapshot to before a plan and draws its fields only from the private-site record's IN list, and it re-opens the snapshot's own production gate and plan-mode exclusion |
| K3 | The snapshot in IDEATION, and another carrier in the plan modes | **rejected.** One element with a second home, and the snapshot's field list still bars it |
| K4 | The trip context; the traveller file made `bound`; the traveller model relaxed; the itinerary; the presence file | **rejected by constraint.** `ADR-004` § 1, kept, bars the trip context; the build reads no traveller file and never a raw hand-edited one; the model is `internal-hard`, and contact data stays out of it; the itinerary is absent in IDEATION, versioned, and written by a planning agent; the presence file is `internal` and bounded to its window lines |
| K5 | A first-party file and a separate third-party-derived one | **rejected.** It separates nothing the carrier needs separated — the way to reach the contact is in neither — and doubles the class, the fences and the erase rows |
| K6 | A follow-on card | **foreclosed** by CR-2's third call |

### The carrier's writer

| | Option | Disposition |
|---|---|---|
| **W1** | **The enrichment agent's reconciler role, reading the traveller's own trip data** | **chosen.** It already reads every traveller's trip file and the roster, and already computes who filed, which is the carrier's population. Its input is re-pointed to the script-made projection under the private-site record's safeguard 7 (§ 7) |
| W2 | The reconciler, projecting from the traveller model | **rejected.** Contact data never enters the model (§ 3, rule 4) |
| W3 | The site build, reading the traveller file | **rejected.** The build reads no traveller file, dispatches no agent, and edits no `outputs/` file |
| W4 | A `/trip-record` verb | **rejected.** That verb writes human source; a derived file's writer is the agent |
| W5 | The hub | **rejected.** It runs in synthesis only, and it is a planning agent |
| W6 | A deterministic script projection | **not chosen.** A new writer class in § 1.1's writer column, with no precedent |

### The smaller forks

| Fork | Chosen | Rejected, and why |
|---|---|---|
| Production | every reconciler pass, in every mode | gated on IDEATION like the snapshot: the carrier must stay current in the plan modes; the site verb dispatching the reconciler: the build never edits an `outputs/` file as a side effect |
| The emergency line | three states — D2's *whether*, with D1's name as the named state | two states: D2 locked *whether*; a name with no way to reach them on file: the organizer could not act on it |
| The population floor | `SELF-STATED` | `ADR-025`'s default floor, `OPERATOR-STATED`: the private-site record's safeguard 3 |
| A value mixing in something that is out | withhold the line whole | trim it: that publishes words the traveller did not write |
| Placement | a section in every state the site builds | a field of the hero: no component carries a per-traveller record; a region of the snapshot's section: the snapshot leaves the page once a plan exists |
| The name | `outputs/group-contacts.md` — the `group-*` family of group-facing homes | `traveler-contacts`: that family names `internal` reconciler files; `if-something-happens`: the in-trip contact also serves ordinary coordination |

## Decision

*Authored in the commits that follow on this release branch.*

## Consequences

*Authored in the commits that follow on this release branch.*

## References

*Authored in the commits that follow on this release branch.*
