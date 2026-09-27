# ADR-036: The published artifact takes no in-model row — `ADR-026` Finding 1 declined, in terms, and routed

- **Status:** Accepted (2026-09-27)
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries the card's answer to `ADR-026`'s Finding 1; *References* lists the card's other records.
  The milestone's other cards are [the private-site
  record](ADR-030-what-the-private-site-may-show.md) (#1242) and [the contact and emergency
  record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after [the
  private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because the card's pre-plan rows, in [the site phase-model
  record](ADR-031-site-phase-model.md), render values that record admits. The flip is the
  maintainer's, taken at this milestone's close, and it moves both halves of a two-artifact state:
  the `Status:` line above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision on **`ADR-026`'s Finding 1**: whether the published artifact takes a row
  in `reference/data-architecture.md` § 1.1, an assignment owed by whichever card next amends that
  enumeration.
- **What this record is not.** It does not decide the class of the object that crosses the channel, which is
  `ADR-026` § 3's subject, and it makes no § 1.1 edit. It builds nothing, and in this release it
  changes no `publish:` value, no fence line and no per-verb requirement row.
- **How it was decided.** In the second design pass on the card's design sub-task #1388, as its item
  O-4b; the milestone's fit review and scope lock, CR-2, are recorded on #1369. The card's one
  record was split by topic under the operator's R2, recorded on #1369, with no decision changed.

## Context

**The assignment.** `ADR-026`'s Finding 1 asks for a § 1.1 row for the published artifact, and
assigns it to whichever card next amends `reference/data-architecture.md` § 1.1. The #1296 card's
slices do: the destination shortlist's class edit lands in [the site phase-model
record](ADR-031-site-phase-model.md)'s render slice, and [the group-snapshot
record](ADR-037-group-snapshot.md) decides a new class.

## Decision drivers

1. **The publish surface is fixed.** One self-contained file (`reference/site-layout-spec.md` § 8),
   guarded by one ciphertext check over one render (`ADR-008`), with one passphrase per repository.
   The card decides rendering, not reach.
2. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
3. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### `ADR-026` Finding 1

| | Option | Disposition |
|---|---|---|
| A | Take it: an in-model § 1.1 row for the published artifact | **rejected**, on the grounds in § 1 |
| B | Take it: an explicit § 1.2 row, split from the `.publish/` row | **left to the routed card.** It is a disposition about the trust boundary, outside the card's domain, and it changes the enumeration's closed count |
| **C** | **Decline in terms, and route** | **chosen** |
| D | Decline silently | **rejected.** That is the pattern that orphaned it |

## Decision

### 1. `ADR-026` Finding 1 — declined, in terms, and routed

The finding asks for a § 1.1 row for the published artifact, at `<trip>/.publish/index.html`, owed by
whichever card next amends § 1.1 — which this card's slices do. **It is declined here, and routed to a
card of its own**, on four grounds, the limb-independent ones first:

1. **An in-model row would contradict an existing disposition.** § 1.2 disposes of `.publish/` out of
   the model — never traversed by any selector — and a row for the published artifact needs a selector
   inside it. This record cites that disposition by its path, never by an ordinal, because the
   out-of-model rows are renumbered by another milestone's slice.
2. **The published artifact is already governed** on the path that produces it, by two fail-closed
   pre-push predicates.
3. **The card decides the render's content per state**, in [the site phase-model
   record](ADR-031-site-phase-model.md), not the class of the object that crosses the channel, which
   is `ADR-026` § 3's subject.
4. **A corollary on the encrypted limb only.** There the published artifact is ciphertext and cannot
   carry the universal frontmatter every in-model class requires; on `--plaintext` it is the render
   byte for byte and does carry it, which is why this ground is a corollary.

**The route** is an intake observation carrying the orphaned-assignment evidence — the assignment
has already passed two cards, `ADR-027`'s and `ADR-028`'s, that each decided a new § 1.1 class and
answered neither, and an assignment keyed on a future event that nothing checks is a standing
exemption — and the § 1.2 option: an explicit out-of-model row split from the `.publish/` row. This
release makes no § 1.1 edit. **The new classes this milestone decides** — the group snapshot in [the
group-snapshot record](ADR-037-group-snapshot.md), the group contacts file in the contact and
emergency record — are not the published artifact, and they are what fired the milestone's re-size.

## Consequences

- **The assignment gets an owner.** It leaves this card as a routed intake observation carrying its
  evidence, rather than passing a third card unanswered.
- **No § 1.1 edit is made in this release**, and the § 1.2 option stays open to the routed card.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, Finding 1 | **CHEAP** | HIGH |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| An explicit § 1.2 row for the published artifact, split from the `.publish/` row — the finding's option B | the routed card |
| What the site renders in each state | [the site phase-model record](ADR-031-site-phase-model.md) |
| The class of the object that crosses the channel | `ADR-026` § 3 |

## Follow-on build slices

- **Routed, not Wave 1's by this record:** `ADR-026` Finding 1's card.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [ADR-026](ADR-026-channel-architecture.md) — Finding 1, declined here, and § 3's subject.
- [ADR-027](ADR-027-post-trip-preference-memory.md) and
  [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the two cards the assignment has already
  passed.
- [The site phase-model record](ADR-031-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [The contact and emergency record](ADR-038-contact-emergency-group-visibility.md) — the group
  contacts file, one of the new classes the milestone decides.
- `reference/data-architecture.md` — § 1.1's classes and § 1.2's out-of-model dispositions.
- `scripts/publish-trip-site.sh` — the fail-closed pre-push predicates that govern the published
  artifact.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the second pass's item O-4b; the
  fit review, CR-2 and R2 on #1369.
