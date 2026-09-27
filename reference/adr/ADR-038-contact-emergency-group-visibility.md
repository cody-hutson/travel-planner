# ADR-038: Contact and emergency information on the private site — what the group sees, the emergency contact as a third party, and the carrier

- **Status:** Accepted (2026-09-27)
- **Deciders:** repo maintainer
- **Driving work:** #1545, one of the records of the *The site serves every phase: the founding
  decision* milestone, beside [the private-site record](ADR-030-what-the-private-site-may-show.md)
  (#1242) and the #1296 card's records, which [the site phase-model
  record](ADR-031-site-phase-model.md) lists. The operator pulled the card into the milestone when
  the private-site verdict was locked.
- **The precondition of this record's status flip.** This record flips to `Accepted` only after
  [the private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
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
  dated note inside `ADR-004` that records this lands in the Wave-1 change that ships the replacement,
  the carrier slice — not in this release (§ 5). This record also supersedes
  [ADR-029](ADR-029-group-approval-return-and-threshold.md) **in part**: the gate step of its § *Decision* 3,
  step 6, and only for a change that only removes or narrows what the group sees about a person (§ 4).
  Everything else in `ADR-029` stays in force. `ADR-029` is never marked superseded either, its index
  cell stays `Accepted`, and its record of this supersession lands in the Wave-1 change that ships the
  replacement gate (§ 7) — the operator's R1, recorded on #1369, timed by the operator's T1, recorded
  there too.
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
  record's safeguard 7. The operator's R1, recorded on #1369 after the group-approval release merged,
  reconciled MG-C1 with that release's record, `ADR-029`, by superseding part of it.

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
| **A dated note inside `ADR-004`, in the form `ADR-009`'s eighth amendment already uses for a partial supersession** | **chosen** — the operator's D3. The note lands in the Wave-1 change that ships the replacement (CR-2's fifth call, as the operator's T1 re-timed it; § 5). `ADR-009`'s eighth amendment is the corpus precedent for recording a superseding decision in place |

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

**Terms.** The **organizer** is the person who runs the trip's planning and holds its local store —
`ADR-004` § 3's "coordinator who runs the build", and `ADR-003`'s organizer. The **in-trip contact**
is `ADR-004`'s "contact method", narrowed to this trip. The **emergency contact** is `ADR-004`'s
"one emergency contact (a name and how to reach them)". These are working names; Wave 1 chooses the
form labels.

### 1. Whether the group sees contact and emergency information at all — yes, in part

**What the group sees on the private site:**

- **each traveller's in-trip contact**, when that traveller marks it shared;
- **one trip-wide line** naming the organizer as the person to tell if something happens, because the
  organizer holds the emergency contacts travellers chose to give;
- **for each traveller who filed their own form, an emergency line** in one of three states: the
  emergency contact's **name**, only when the traveller confirms on their form that the contact agreed
  to be listed for the group (the operator's D1); *on file with the organizer*, when the traveller gave
  an emergency contact without that confirmation; or *no emergency contact on file* (the operator's
  D2).

**What stays with the organizer:** the way to reach an emergency contact. **What is never captured:**
the contact's relationship to the traveller.

**The coordination test, applied.**

| Item | Result | Why |
|---|---|---|
| The in-trip contact | **IN**, on the traveller's choice | it is how the group reaches someone during the trip, and the traveller filled in their own form, so safeguard 3 does not bar it |
| Who to tell if something happens | **IN** | it is about the trip's arrangements, and the only person it names is the organizer, who is already IN as one of the people coming |
| Whether an emergency contact is on file with the organizer | **IN** | the operator's D2 |
| The emergency contact's name | **IN only on the traveller's attestation** | the operator's D1: the contact is a third party (`ADR-006`), so the name shows only as the traveller's statement that the contact agreed to be listed |
| The way to reach the emergency contact | **OUT** — the organizer only | it is about a person outside the group who did not fill in a form of their own; safeguard 3 excludes such a person, and `ADR-006` stands |
| The emergency contact's relationship to the traveller | **never captured** | `ADR-004` § 2's closed set stands (CR-2's fourth call) |

**Why not a full "no", keeping `ADR-004` as it is.**
- `ADR-004`'s own trade-off rests on the premise that the organizer coordinates. The private-site
  record removed that premise: the private site is now the group's coordination surface.
- *Organizer-visible* in `ADR-004` § 3 means the data sits in the organizer's local trip store, which
  is not something the group carries on the trip, while the site is the one surface every traveller
  has with them.
- The strongest case for "no" is that friends usually have each other's numbers already. The share
  choice meets it: a traveller who prefers a group chat simply does not share, so the cost of "yes" is
  bounded by each person's own decision.

**Why not the full details.** The way to reach a third party stays with the organizer, and no
mechanism reaches that person for their own consent. The name shows only on the traveller's
attestation that the contact agreed, which records the traveller's statement and is never described
as the contact's consent.

### 2. At what level, per traveller — a closed list

| # | Item | About | The group sees it | The organizer holds it | Public page |
|---|---|---|---|---|---|
| L-1 | **In-trip contact**: one way to reach the traveller during this trip, in the traveller's own words | the traveller | when the traveller marks it shared | always, once given | never |
| L-2 | **Who to tell if something happens**: the organizer, who holds the emergency contacts travellers chose to give | the trip's arrangements | always, as one line for the whole trip | n/a | never |
| L-3 | **The emergency line**: the contact's name, on the traveller's attestation; otherwise *on file with the organizer*; otherwise *no emergency contact on file* | the traveller's arrangement, and a third party's name | for every traveller who filed their own form, and never for a traveller who refused | the contact's name, always once given | never |
| — | **The way to reach the emergency contact** | a third party | never | always, once given, in the organizer-only file (§ 3, rule 4) | never |

**The emergency line is shown for filers only**: the operator's D-1 shows nothing else about a person
who did not fill in their own form, and rule 1 below makes the field the traveller's own statement. It
is never shown for a traveller who has recorded a refusal, under the private-site record's safeguard 4.

**Nothing else. The exclusions are stated so that no later slice re-derives them:**
- **The emergency contact's relationship to the traveller** is never captured. In a small named group,
  "her sister" identifies a person — `ADR-006` Q3's reasoning applies: stripping a name does not strip
  the identification — and `ADR-004` § 2's closed field set, "No more", stays in force.
- **A free-text "if something happens" note.** Its obvious content is medical, so it would re-open the
  private-site record's row for needs and must-haves — the plan honours them without displaying them —
  by a side door. Free text also defeats a closed list.
- **A second emergency contact, an address, or any health information.**

**L-2's content rules.**
- It names the organizer only through the organizer's own entry in the trip context's `## Group`
  roster, which records the planner role and is already IN. If the organizer is not on the roster, the
  line carries no name.
- It is **rendered from the roster alone**: the render never reads an emergency-contact field to decide
  whether, or how, to show the line.
- It never suggests contacting the organizer instead of the local emergency services.

**Placement is the site phase-model record's.** The carrier this record decides (§ 6) is placed in
[the site phase-model record](ADR-031-site-phase-model.md)'s render table, by
citation to this record: a section in every state the site builds, and the organizer line as a field
of the hero.

### 3. The emergency contact is a third party — the rules

1. **Source.** The details are the traveller's own statement, on the traveller's own trip form. They
   are never entered by the operator on the traveller's behalf, and never copied from another trip or
   record.
2. **The ground for each value.**
   - Capture rests on the traveller's opt-in, which `ADR-004` § 3 already requires and this record
     keeps. The way to reach the contact is never published, so its capture rests on `ADR-006` Q1's
     ground: the consent hazard that record guards against does not arise where the value cannot be
     published by construction.
   - **The name's ground is the operator's D1 plus the traveller's attestation** that the contact
     agreed to be listed for the group. It is worded as the traveller's attestation, **never as the
     contact's consent**: in `ADR-006`'s own words, such a claim records the appearance of consent
     rather than consent itself, and must not be described as though it establishes consent.
     `ADR-006` Q1 is not cited for the name, because the name, once attested, is rendered.
   - The contact's own consent is not obtained and never claimed: no channel reaches a person who is
     not travelling, and `ADR-026` § 2 admits a new channel only by amendment or a superseding record.
3. **`ADR-006`'s refusal to capture identity data does not reach this.** That refusal is scoped to
   party members — people travelling without a profile — and an emergency contact is not travelling.
   `ADR-004` § 2 permitted one name and one way to reach them before `ADR-006` existed; this record
   keeps that permission exactly and does not widen it. `ADR-006` needs no edit.
4. **Where it lives — the storage rule (decision S).** The traveller gives the details on their own
   trip form, `travelers/<traveler>.md`, inside the trip's directory in the operator's trip store;
   rule 1 stands.
   - **When the form is filed, a script — not an agent step — moves the emergency contact's way to
     reach them, and any name the contact has not agreed to show, into an organizer-only file beside
     the traveller's trip file, in the same trip directory.** It runs before any agent step reads the
     form. The file's name is Wave 1's.
   - **The traveller's trip file keeps only what the group may see about the contact**: the agreed
     name, the agreement mark, and an *on file* marker.
   - This is data minimization: the organizer holds the way to reach the contact, and only the
     organizer and the filing script ever touch it.
   - The field-scope class is **`TRIP`**, under `reference/data-model.md` § *Field Scope* — test T1,
     its subject being this trip's safety arrangement, with the T4 fail-safe default behind it — and
     the `TRIP` rules apply to the organizer-only file unchanged. The existing machinery then keeps
     the details out of the durable person record: the person form never declares the fields, so
     `/trip-record promote` refuses them; `/trip-record extract` leaves a `TRIP` field in place; and
     the composition table treats a `TRIP` field found in the person record as a schema violation.
   - The details are **never projected into the derived traveller model or any planning artifact**,
     because nothing the planner does needs them. The one group-visible projection is the group
     contacts file (§ 6), written beside the model and never through it, and it carries no way to
     reach an emergency contact.
5. **Who reads it.** Only the organizer reads the organizer-only file. Nothing in the render or the
   planning pipeline reads it, and **no agent step reads it — Wave 1 enforces this mechanically, not by
   instruction alone**. This restores the design's rule that only the organizer reads the details,
   which the carrier design had relaxed for the carrier's writer: that writer now reads only the
   traveller file's agreed name, agreement mark and *on file* marker.
6. **Never on any page, in any form** — the way to reach the contact, and a name the contact has not
   agreed to show: not attributed, not anonymized, not reduced to a relationship. An attested name
   reaches the private site only, never a public page. This is `ADR-004` § 4, on today's machinery:
   - (a) the render never reads the way-to-reach field, and neither does the carrier's writer;
   - (b) one `field` row in `reference/data-architecture.md` § 5.6's `publish-contract-values` fence
     targets **the way to reach the contact, never the name**, scoped to the organizer-only file. It
     makes the value a member of the non-publishable class: the `--plaintext` limb's guard aborts on
     it, and the validator's privacy audit is Critical on it wherever that audit reads. § 5.6 calls a
     row outside the evaluator's queried pairs a code change, so the slice that lands this row widens
     the queried set in the same change: a row outside it aborts every publish as `UNDETERMINED`;
   - (c) the private-site record's safeguard 6, decision P, checks every file the site build reads for
     the non-publishable field class before every publish, on both limbs and in every phase, and the
     way to reach the contact joins that class when its capture ships. This is defense in depth: a
     mechanical check of the outcome, on top of the render's rule that it never reads those fields.

   `ADR-026` § 3 records that the encrypted limb's guard asserts encryption, not content. On that limb
   the guarantee rests on (a) to (c), the footing every never-rendered value stands on.
7. **The assisted interview never asks for or repeats the contact's details.** It tells the traveller
   the fields exist and that they write them into the form themselves. `ADR-026` § 3 declares the
   intake surface's observers to be `third-party`, because an assistant's history keeps the
   transcript; and `/trip-record erase` types the session transcript as a report, not swept, so a
   transcript copy is one that no removal reaches.
8. **Removal at the contact's request.** The contact may ask the traveller or the organizer, and the
   organizer removes the details. No reason is required. **A removal reaches forward only**: copies
   already published stay out of erasure's reach.
9. **What the group learns about the contact**: whether a traveller gave one, by the operator's D2,
   and the contact's name only on the traveller's attestation, by D1. Nothing else.

### 4. What the traveller opts in to, what they are told, and how they withdraw

**Opt-ins: separate choices, each off until the traveller makes it.** There is no pre-ticked answer,
and silence is not consent.

| # | Choice | Effect | Source |
|---|---|---|---|
| C-1 | Give an emergency contact | captured; the way to reach them is kept in the organizer-only file; the group sees the emergency line's *on file with the organizer* state | `ADR-004` § 3, kept |
| C-2 | Give an in-trip contact | captured; the organizer sees it | `ADR-004` § 3, kept |
| C-3 | Share the in-trip contact with the group | shown on the private site | **the private-site record's share mark, reused by citation** rather than a new device. Unmarked means organizer-only, as an unmarked desire means personal. C-3 requires C-2 |
| C-4 | Confirm that the emergency contact agreed to be listed for the group | the contact's name shows in the emergency line; without it the line reads *on file with the organizer* | the operator's D1. C-4 requires C-1 |

**An absent or malformed mark reads as unmarked, and an absent or malformed confirmation as not
confirmed.**

**What they are told.** It is told at collection, beside the fields, under the private-site record's
safeguard 1, and for these fields it replaces the form's current *private — never published* promise.
The list of elements is closed; Wave 1 writes the words.

| # | The traveller is told |
|---|---|
| N-1 | What each field is for: the in-trip contact lets the group reach them during the trip; the emergency contact lets the organizer reach someone for them if something happens |
| N-2 | Who sees each one. The way to reach the emergency contact: the organizer only, never on the site, in any form. The emergency contact's name: everyone with the trip's password, only when the traveller confirms the contact agreed to be listed; otherwise the group sees only that a contact is on file with the organizer. The in-trip contact: the organizer once given, plus everyone with the trip's password if marked shared. None of them ever appears on a public page |
| N-3 | The group sees who to tell — the organizer — and, for each traveller, whether an emergency contact is on file, by name when confirmed |
| N-4 | Both stay with this trip: neither is saved to their profile or carried into later trips |
| N-5 | The emergency contact is someone else's details: they should tell that person they have been listed, confirm on the form that the person agreed only if they have, and that person can ask the organizer to remove them |
| N-6 | They can change or remove either at any time; the site catches up at the organizer's next update; anyone who already saw a detail may have kept a note of it |
| N-7 | Only the organizer holds the ways to reach emergency contacts. If the organizer is the one affected, or cannot be reached, nobody on the trip can reach the traveller's emergency contact through the site, so they should keep it on their own phone too |

**The notice couples with the carrier.** It says that the group contacts section appears from the
first pre-plan page onward, and what each of the three emergency states means; N-2, N-3 and N-5 name
the carrier's lines. The notice carries no other new text.

**How they withdraw:**
- **W-1.** Unmark the in-trip contact, and it returns to organizer-only.
- **W-2.** Remove either value, and it is gone from the trip store.
- **W-3.** Or ask the organizer to do either.
- **W-4.** The emergency contact can ask the organizer directly (§ 3, rule 8).

**Timing and gates.**
- **A withdrawal is honoured at the organizer's next update**, under the private-site record's
  safeguard 4 as CR-2's first call reads it: it is recorded only through a verb that runs the reconcile
  step in the same act, so every staleness report shows the page as behind until the next update
  carries it. **No publish gate is added.** Today `/trip-record profile` names the reconcile step and
  does not run it, so the recording verb is a Wave-1 obligation shared with the private-site record.
- **No group approval.** A change to a traveller's own sharing choice, in either direction, is not a
  plan change: `ADR-003` § 2's approval governs plan changes.
  **The rule: a change that only removes or narrows what the group
  sees about a person is never held for the group's approval.** It binds any approval step on the
  publish path. The organizer's confirmation remains the only gate on such a change.
- **What this supersedes in `ADR-029`, once accepted — the operator's R1.** The gate on a republish
  is step 6 of [ADR-029](ADR-029-group-approval-return-and-threshold.md)'s § *Decision* 3:
  *"`update` proceeds only on `confirmed`: distinct declared approvers, each counted by their latest
  record for the outgoing digest, reach the threshold"*. For a change that only removes or narrows what the group sees about a person, and for
  no other change, this record supersedes that step once it is accepted: such a change is never held
  for the declared approvers, and the organizer's confirmation remains its only gate. The rest of
  `ADR-029` § *Decision* 3, and every other decision of that record, stands. The form is
  `reference/adr/README.md` § *Convention*'s partial one, the form `ADR-029` § *Decision* 7 itself uses
  for `ADR-003` § *Decision 2*: `ADR-029` is never marked `Superseded` and its index cell stays
  `Accepted`; its `Status:` line records this supersession, and an inline marker at step 6 points
  forward to this record. Both land in the Wave-1 change that ships the replacement gate (§ 7), because
  § *Convention* records a supersession *"when it takes effect and not before: for a rule implemented
  in code, that is the change that ships the replacement"* — the operator's T1, recorded on #1369. This
  record's change edits no line of `ADR-029`.
- **Withdrawing is as easy as giving**: the same form and fields, with no reason asked. A field that
  was declined or withdrawn is never asked about again on that trip — the form's own rule is "Never
  push twice".

**Erasure.**
- `/trip-record erase` rewrites the whole traveller file and deletes and rebuilds the render. **Under
  the storage rule it must also reach the organizer-only file**, and under CR-2's sixth call every trip
  page file, not only the newest: both are Wave-1 conditions of the slices that land the capture and
  the page's file-name rule. The carrier's own erase row deletes the subject's entry whole (§ 6).
- `examples/archived-trip-demo/` witnesses an `Emergency contact` override being reduced to the
  not-answered sentinel, through the artifact-schema suite's arm `ER15`. Once Wave 1 declares the
  field, the witness's descriptions of it — a label no schema declares, a divergent copy of a durable
  field — become false, so the slice that declares the field moves the witness to a label that is still
  undeclared, or rewords them, with `ER15` kept green.
- **Removal only works forward**: it cannot recall a copy someone already made.

### 5. What `ADR-004` keeps, and what this record supersedes

| `ADR-004` section | Disposition | What this record states |
|---|---|---|
| § 1 Storage location | **kept**, with clauses re-read | The data lives only in that trip's directory in the operator's trip store: never committed, never written to `trip-context.md`. The store resolves through the data root, per `ADR-021`'s amendment — a resolution change is not a relocation. Under the storage rule the way to reach the contact, and a name the contact has not agreed to show, live in the organizer-only file beside the traveller's trip file (§ 3, rule 4). § 1's *never written to the published artifact* now reads field by field: never, for the way to reach the contact; private site only, for a shared in-trip contact, an attested name and the emergency line's state |
| § 2 Minimum field set | **kept**, and stated as closed | A contact method — now the in-trip contact — plus one emergency contact: a name and one way to reach them. "No more": no relationship, address, second contact or free-text note |
| § 3 Consent & visibility | **consent kept; visibility superseded in part** | Opt-in is kept, now as the choices C-1 to C-4. The in-trip contact is organizer-visible by default and group-visible on the private site when marked shared; the emergency contact's name is group-visible on the traveller's attestation; whether a contact is on file is group-visible for every filer. The way to reach the contact stays organizer-only |
| § 4 Non-publication guarantee | **kept** for the way to reach the contact, an unshared in-trip contact and an unattested name; **narrowed** for a shared in-trip contact, an attested name and the emergency line's state: private site yes, public page never | Enforcement is § 3, rule 6. The group-visible items take the private-site record's handling of IN items, including its public-path refusal keyed on the group contacts section's presence, with no matching on values |
| Consequences — the trade-off accepted "since the organizer coordinates" | **withdrawn** | Its premise is gone (the private-site record) |
| Follow-on build slices | **handed to Wave 1** | The local capture goes to this record's capture build, with the filing script; the validator check becomes the § 5.6 row; the intake opt-in step becomes C-1 to C-4 and N-1 to N-7 |
| *Every section* | **Nothing ever reaches a public page** | It holds for L-1, L-2 and L-3 alike |

**How the supersession is recorded — the operator's D3, timed by CR-2's fifth call as the operator's
T1 revised it.** A dated note inside `ADR-004`, in the form `ADR-009`'s eighth amendment uses:
`ADR-004`'s `Status:` line records the supersession in part, and inline markers stand at § 1's *never
written to the published artifact*, § 3's visibility, § 4's guarantee and the Consequences trade-off;
everything else stays in force. The note lands in the Wave-1 change that ships the replacement: the
carrier slice (§ 7), the change that first brings a contact or emergency item to the private site,
because `reference/adr/README.md` § *Convention* records a supersession when it takes effect and not
before — the operator's T1, recorded on #1369. It lands neither in this release nor with this record's
`Accepted` flip, and until then `ADR-004` is the decision in force. `ADR-004` is never marked
superseded and its index cell stays `Accepted`, so this record carries no Supersedes bullet: it names
here the sections it supersedes in part, and states that the rest stands. **`ADR-011`'s two
restatements of `ADR-004`** — § 1's *never written to the published artifact*, and § 2 read as a
minimum rather than the closed set it is — are corrected by one dated amendment in `ADR-011`, which
lands with the `ADR-004` note; `ADR-011`'s own conclusion is untouched.

### 6. The carrier — how the group-visible items reach the page

The operator locked the carrier as decision K: C-1 to C-5 as designed, with the storage change of
§ 3, rule 4.

#### C-1 — The file

**A new per-trip derived file, `outputs/group-contacts.md`.** It holds one entry per traveller who
filed their own trip form. Each entry carries the **in-trip contact**, when shared, and the
**emergency line**, always, in one of its three states. The **organizer line** is not in it: it renders
from the trip context's roster. The in-trip contact is the traveller's own and the name is a third
party's, but both share one key — the traveller — one population, one writer, one lifecycle, one reach
and one purpose, so one entry holds both. The closures of every other home are under *Options
considered*.

#### C-2 — Who writes it, and from what

**The writer is the enrichment agent, in its reconciler role only** — one writer, as § 1.1 requires.
This reuses `ADR-028` § 2's pattern and the group snapshot's: the role already reads every
`travelers/<traveler>.md` and the roster, and already computes who filed — the engagement value
(`ADR-025` § 1), which is the carrier's population — so the carrier adds no agent, no dispatch and no
read.

| Carried | Read from | How |
|---|---|---|
| the entry key, `## <Name>` | the roster's display name | a projection of the roster cell — the Traveler natural key, as the group snapshot and `ADR-028` § 2 key theirs |
| the population | the engagement value computed in the same pass | used, never written |
| the in-trip contact | the traveller's trip file: its value and its share mark | verbatim, only when marked |
| the emergency line's state | the traveller's trip file: the *on file* marker | the marker only; the way to reach the contact is never read |
| the emergency contact's name | the traveller's trip file: the agreed name and its agreement mark | verbatim, only when on file and attested |

- **Never through the traveller model**, never from the trip context, never from the person record —
  the person form never declares these `TRIP` fields — and never from a session or the interview.
- **Under the private-site record's safeguard 7, decision Q**, the step that writes this file reads a
  script-made projection of the traveller data that omits the non-publishable field class, rather than
  the full trip file; the fields above pass through that projection unchanged.
- **The read set is closed by label**: each output line is filled only from its own label, verbatim —
  carry-through, not computation. An absent or malformed mark reads as unmarked, and an absent or
  malformed attestation as not attested.
- **The withhold rule**: a line is withheld whole, never trimmed, when its value states or implies a way
  to reach anyone but its own subject, a relationship, a person who did not file, or any OUT kind. A
  withheld name falls back to *on file with the organizer*; a withheld in-trip contact shows nothing.
- **The relationship is never captured**, and the file's grammar has no line for the way to reach an
  emergency contact.

**When: on every reconciler pass, in every mode.** The group snapshot is gated on IDEATION because
plan-mode renders exclude it; the carrier renders in every state the site builds, so that reason does
not arise.

**Lifecycle: `rebuilt-each-synthesis`**, rebuilt whole, with no carry-forward: `ADR-025` never-carry 1
applies with no third-party carve-out, because no third-party entry can enter. No pass runs on an
`ARCHIVED` trip, and the tolerant read's write-stop applies.

**Write ownership** (`CLAUDE.md` § *Write ownership*).
- Ownership follows the writer, not the caller: the file is the enrichment agent's, whichever verb
  dispatches it, and it adds no block to `trip-context.md`.
- It is never edited by hand: every change is made at the source.
- **Withdrawal and removal follow CR-2's first call.** Unsharing, removing a value, the organizer acting
  on request, the contact's own removal request and a refusal under the private-site record are each
  recorded at the source through a verb that runs the reconcile step in the same act. That step
  rewrites the carrier, so `itinerary-to-build` reads `BEHIND`, naming it, until the organizer's next
  update.

#### C-3 — Its class

**`publish: bound`.** The file exists to be rendered, and D1 and D2 admit every value in it on the
private site. It is not `internal-hard`, which is for values that must not reach a rendered page in any
form. § 5.1's enum is closed, so no group-only value is minted: the group-only property comes from the
private-site record's public-path refusal, keyed on the section (C-5). Every row below is decided here
and landed by Wave 1; none is edited in this release.

- **A § 1.1 row** for `outputs/group-contacts.md`: writer `enrichment`, lifecycle
  `rebuilt-each-synthesis`, provenance `derived`, **`publish: bound`**, primary entity Traveler. The
  class is named by path, never by ordinal; the landing slice derives the ordinal at its own base.
- **A § 9.1 authority row and a `publish-contract-artifacts` fence row**, landing with the § 1.1
  row in one commit, so group `PB` stays green.
- **The element fence `round-trip-contract-elements-group-contacts`**, at label grain, graded
  against the writer's grammar block. The labels are working names; Wave 1 spells them as the
  capture form does.
- **An erase reach row**, appended by the landing slice at its own base, which deletes the subject's
  entry whole, with no tombstone and no token — the roster carries the trip's tombstone, and the
  file holds no independent state — and never skips silently.

**§ 5.6: no row is scoped to this file.** The way to reach the contact never enters it; its own row is
the one § 3, rule 6 places on the organizer-only file. There is no row for the name, which D1 renders
when attested, and none for the in-trip contact, which is group-visible when shared, so a row would make
the validator Critical on a lawful line; its public-path protection is structural (C-5).

#### C-4 — Where it shows

**The section ceiling returns a section, `group-contacts`, in every state the site builds** — both
IDEATION rows and the four plan modes — as [the section-ceiling
record](ADR-033-site-section-ceiling.md)'s ladder runs it: the
element has
a § 9.1 authority once the class lands; every rendered value is admitted by D1 and D2, and the § 5.6
row involved names a value the file never carries; no § 3 component carries a per-traveller record in
every targeted state; and no section iterates travellers in every such state, while a snapshot region
in IDEATION plus a section in the plan modes would give one element a second home and move it at the
IDEATION exit. The site phase-model record carries the render-table rows by citation to this record,
and there is no § 9.3 row, because nothing is excluded in any built state.

**The organizer line is not re-decided.** It stays a field of the hero, rendered from the roster alone,
in every state the site builds, under § 2's content rules.

**Why IDEATION too.** The in-trip contact is how the group reaches each other while it coordinates,
before the trip as well as during it. Showing the section from the first page lets each traveller see
what the group sees about them, and correct or withdraw it, before anyone travels, and one section in
every built state means no transition moves it. When the page file changes its name at the first
build with a destination, both files carry the section, and CR-2's sixth call — erasure over every
trip page file — covers that.

**The section's three states**, none inferred from existence: present with entries → rendered; present
with none → the declared empty state, a neutral line that gives no reason; absent → a degraded read,
never a smaller site — the walk exits degraded, the verb does not present the site as current, and the
remedy is `/trip-record travelers`. Where the section sits, its title and its frame line are Wave 1's.

#### C-5 — What never happens

| Never | How it holds |
|---|---|
| **The way to reach an emergency contact on any page** | It is not in the carrier's grammar, and the carrier's writer never reads it: the emergency line's state reads the *on file* marker. It lives in the organizer-only file, which no agent step reads, and a value mixed into another line withholds that line. Its § 5.6 row makes it a class member, so the `--plaintext` guard aborts on it and the validator's audit is Critical on it wherever that audit reads, and the private-site record's safeguard 6 checks every file the site build reads for it before every publish. The encrypted limb asserts encryption, not content (`ADR-026` § 3), so there it rests on the writer's construction and on those checks |
| **The relationship** | never captured; no label carries it; a name value stating one is withheld whole, and the line falls back to *on file with the organizer* |
| **A public page** | the private-site record's public-path refusal covers the section **by its presence**, with no per-value matching; the render is limb-blind, and no redaction step is added |
| **A non-filer beyond their name** | the population's floor is `SELF-STATED` — `ADR-025` § 5's first-party reading — so no `OPERATOR-STATED`, `THIRD-PARTY-STATED`, `UNSOURCED` or erased member, and no refuser, has an entry, and `ENGAGEMENT-UNDETERMINED` admits no one, which the pass reports. The name shows through the hero, under D-1, and no line names or describes such a person. All of them look the same: no entry |
| **An unshared contact, or an unattested name** | each is carried only under its mark; an absent or malformed mark reads as not given |
| **A withdrawal held back** | recorded through a verb that runs the reconcile step; nothing carries forward, so the rebuild drops the line; `itinerary-to-build` reads `BEHIND` until the organizer's next update; no gate blocks on freshness. The residuals: a hand edit with no verb is observed only at the next reconcile, and removal reaches forward only |
| **Contact data in the traveller model or a planning artifact** | the file is written beside the model, never through it (§ 3, rule 4) |
| **Going live early** | the private-site record's safeguard 5 binds every Wave-1 slice of the carrier: nothing goes live before the fix for the rotation defect tracked privately ships |

### 7. Conditions carried to Wave 1

Each is a condition of the slice named, stated here so that no slice re-decides it:

- **The capture build**: the trip form's fields and the choices C-1 to C-4; the notice elements N-1 to
  N-7; **the filing script and the block on agent reads of the organizer-only file** (§ 3, rules 4 and
  5); the organizer-only file itself; the way-to-reach's § 5.6 row scoped to that file, with the
  evaluator's queried set widened in the same change (§ 3, rule 6); the `TRIP` rows in
  `reference/data-model.md` § *Field Scope* and their totals; and the recording verb for a withdrawal
  or a removal, shared with the private-site record (CR-2's first call).
- **Erasure** reaches every trip page file (CR-2's sixth call) and, under the storage rule, the
  organizer-only file.
- **The carrier slice**: the class, its fences and its section; its schema; its writer contract,
  **with the writer's input re-pointed to the script-made projection of the private-site record's
  safeguard 7**, and the split between writing internal files from full inputs and writing
  group-visible files from that projection; its erase row; the dispatchers' Reads lines; and a
  sanitized witness under `examples/`. **It ships the replacement of `ADR-004`'s visibility sections**,
  so the same change records it: the dated note inside `ADR-004`, with `ADR-011`'s dated amendment
  (§ 5).
- **The validator.** Its inline list of the publish-bound artifacts gains the carrier. The validator
  does not run in IDEATION, so for the field class the private-site record's safeguard 6 covers that
  half.
- **Two shared surfaces are re-read at the slice's own base** — `reference/site-layout-spec.md` § 3 and
  the `site` verb's section of `skills/trip/SKILL.md` — because both have changed since this record's
  base, `8b2ac05`.
- **The erasure witness** is relabelled or reworded, with `ER15` kept green (§ 4).
- **The approval gate is changed to match** § 4's rule (the operator's R1): the republish gate of
  `ADR-029` § *Decision* 3, step 6, never holds a change that only removes or narrows what the group
  sees about a person for the declared approvers, and the organizer's confirmation remains its only
  gate. **The same change records the supersession inside `ADR-029`**: the `Status:`-line entry and
  the inline marker at step 6 (§ 4).
- **Nothing goes live** before the fix for the rotation defect tracked privately ships.

## Consequences

**Positive**

- **If something happens**, at any point from the first page to the trip itself, the group can reach
  anyone who chose to be reachable, see whose emergency contact is on file — by name where the traveller
  confirmed the contact agreed — and know that the organizer holds the ways to reach them.
- **The way to reach an emergency contact never enters a file the site reads**, and only the organizer
  and the filing script ever touch it.
- **The third-party posture `ADR-004` and `ADR-006` built is kept** for everything the operator's D1 and
  D2 did not open.
- **Withdrawal, refusal, removal and erasure reach the carrier by construction**: nothing carries
  forward, and erasure deletes the entry.
- **Every mechanism is an existing one**: the private-site record's share mark; the § 5.6 declaration,
  which the validator and the guard both read; the field-scope classes, which `promote`, `extract` and
  composition already honour; erasure's whole-file rewrite; and the reconciler — no new agent, no new
  dispatch and no new read.

**Costs and residuals, stated rather than smoothed**

- **A new § 1.1 class is decided.**
- **The organizer is a single holder** (N-7). The mitigation is outside the system; a deputy holder is a
  candidate future card.
- **Removal only works forward.** It cannot recall a copy someone already made.
- **Retention after the trip is undecided.** `ADR-004` never set one; an archived trip is frozen, with
  erasure as its only stated exception, so an emergency contact survives the trip until someone asks
  for removal. The carrier joins that residual, and under D1 it now also covers copies of a name
  already published, which erasure reaches only going forward. It predates this card and is routed to
  an intake card.
- **"No emergency contact on file" discloses something about a person.** That is the operator's D2,
  recorded here as its cost.
- **Filer status is inferable on the private page**, as the private-site record states, and the carrier
  adds no new kind of inference.
- **The values are conduct; the labels are gradable.** Wave 1's schema arm grades the carrier's labels
  and its three state literals. No guard reads its values on the encrypted limb, and in IDEATION the
  validator does not run.
- **A form edited by hand is observed by nothing until the next reconcile**, the group snapshot's
  residual too.
- **Every render that carries the section refuses the `--plaintext` limb.** The section renders for any
  trip with a filer, so that opt-out is unavailable to such a trip in every phase — "nothing personal on
  a public page", applied.
- **Until Wave 1 changes the gate, the rule has no mechanism on a trip that declares approvers**:
  `ADR-029`'s threshold, as shipped, holds such a republish for the declared approvers (§ 7).
- **Go-live stays behind the private-site record's fifth safeguard**, unchanged.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| the carrier joins the `bound` set | group `PB`: "the publish-bound artifact set matches the spec fence that declares it." | a § 1.1 cell landed without its fence row, or the reverse, fails a required check, so both land in one commit — by design |
| the carrier absent in a build | the walker's exit contract, "Exit 0 clean, 1 findings, 2 degraded read."; the `site` verb: do not present the site as current | the walk exits degraded and the verb withholds "current"; nothing else blocks |
| the way to reach a contact in an audited artifact | the validator's privacy audit: any member of the non-publishable class reaching a publish-bound artifact is always Critical | Critical wherever the audit reads, once Wave 1 names the carrier in its list; in IDEATION the audit does not run, and safeguard 6 covers the field class there |
| the way to reach a contact in a plaintext render | the publish guard aborts on a member of the class | the `--plaintext` publish aborts |
| "the carrier's staleness never gates a build or a publish" | `CLAUDE.md` `G8`, and `/trip-publish` rule 7: "It never branches on freshness, and adds no gate that blocks on it." | **holds** |
| "a withdrawal needs no group approval" | the organizer-confirm gate, whose proceed set is the organizer's own confirmation | **holds at `8b2ac05`**. `ADR-029`'s approval threshold, since accepted, holds such a republish on the group on a trip that declares approvers; this record supersedes that step for such a change (§ 4), and Wave 1 changes the gate to match (§ 7) |

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `templates/traveler-intake.template.md` | the fields, the choices C-1 to C-4 and the notice N-1 to N-7, which replaces *private — never published* for these fields |
| the filing script, the organizer-only file and the read block | new, in the capture build |
| `reference/data-model.md` § *Field Scope* | the `TRIP` rows and their totals; the carrier's rules beside the group snapshot's |
| `reference/data-architecture.md` | the § 1.1 row; § 5.1's statement of the `bound` set; the render's sources; § 5.6's way-to-reach row, with the queried set widened |
| `reference/site-layout-spec.md` | § 3's `group-contacts` section; § 9.1's rows; § 9.2's render-table rows and element fence — re-read at the slice's base |
| `reference/schemas/group-contacts.md` (new) and `reference/schemas/README.md` | the class schema and its coverage declaration |
| `agents/00-enrichment.md` | the writer's contract: the read set through the projection, the population, the mark and attestation rules, the withhold rule, the grammar block and the write-stop; contact data never enters the derived model |
| `skills/trip/SKILL.md` | the `site` verb's Reads line, in every state; `plan`'s and `replan`'s naming of the carrier write |
| `skills/trip-record/SKILL.md` | `travelers` and `person`: the dispatcher naming; the recording verb; `erase`: the carrier's reach row, the organizer-only file, every page file, the accounting and the tally |
| `agents/06-validator.md` | the inline list of publish-bound artifacts |
| `CLAUDE.md` | the file-structure tree and § *How to build it* |
| `scripts/check-round-trip.sh` and `scripts/test-artifact-schema.sh` | the carrier's per-artifact declaration, the `PB` pairing, the label arm, the erase tally; the erasure witness and `ER15` |
| `scripts/publish-trip-site.sh` and `scripts/test-publish-guard.sh` | the widened queried set for the organizer-only file's row |
| `examples/` | a sanitized witness of the carrier's class |

**Structure determinations.**

| Structure | Determination |
|---|---|
| `ADR-004`'s model | **changed** in part: its premise is gone |
| the private-site record's share mark | **extended** to the in-trip contact, not built new |
| the § 5.6 declaration | **extended** by the way-to-reach's row, with the evaluator's queried set widened for the organizer-only file |
| the field-scope classes | **retained**: `TRIP` already bars the person record through `promote`, `extract` and composition |
| § 1.1 | **net-new** `outputs/group-contacts.md`, because in-place is infeasible: the group snapshot, the trip context, the traveller file, the traveller model, the itinerary and the presence file each fail as a host |
| the reconciler's write set | reviewed → **extended** by one file, written on every pass |
| the § 3 catalog | **net-new** `group-contacts`, because no component carries a per-traveller record in every state |
| § 9.1 and § 9.2 | **extended** by rows, in the round-trip contract record's shapes |
| the erase reach table | **extended** by the carrier's row |
| the freshness table | reviewed → **retained**: no new relation; the carrier rides `itinerary-to-build` and `build-to-published` |

**Standards followed**, adopted as design principles; the record makes no legal-compliance claim.

| Choice | Standard followed |
|---|---|
| Minimal fields for the purpose — the closed list and its exclusions; the way to reach the contact held by the organizer alone | GDPR Art. 5(1)(c), data minimisation, and Art. 25(1), protection by design · ISO/IEC 29100, data minimization and collection limitation |
| Consent from the person the data is about — the separate choices, and the notice given at collection | GDPR Art. 6(1)(a) and Art. 7; Recital 32 — granular, and silence or a pre-ticked box is not consent; Art. 13, information at collection · ISO/IEC 29100, consent and choice, and openness, transparency and notice |
| The emergency contact, who is not asked directly | GDPR Art. 14's principle, informing a data subject who was not asked, discharged through the traveller (N-5): an attestation, never the contact's own consent |
| Access limited to the people who need it — organizer-only, and the group only by the traveller's choice or attestation | GDPR Art. 25(2), protection by default · ISO/IEC 29100, need-to-know under data minimization |
| Removal on request — the withdrawals, the contact's request, erasure | GDPR Art. 7(3), withdrawal as easy as giving, and Art. 17, erasure · ISO/IEC 29100, individual participation and access |
| One trip only, never carried forward | GDPR Art. 5(1)(e), storage limitation — retention after the trip is the open half |
| No health information in an emergency note | GDPR Art. 9, special categories, consistent with the private-site record's row for needs |
| Group-only, never public | GDPR Art. 5(1)(f), confidentiality |

**Three axes.** *Best practice:* the most sensitive value is kept out of every rendered file by
construction, never redacted later; one writer per file; an undetermined read fails closed.
*Scalability:* a new traveller costs nothing; a new field costs one list row, one fence row and one
notice line; there is no new store beyond the organizer-only file. *Maintainability:* it reuses the
reconciler, the engagement tokens, `ADR-028`'s keying, erase-row and naming rules, the group snapshot's
mark and withhold rules and [the round-trip contract record](ADR-032-site-round-trip-contract.md)'s
two-grain contract, and mints
one class, one
component and one fence name.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, yes in part | **EXPENSIVE** once a value is published; CHEAP while this record reads `Proposed` | HIGH |
| § 2, the closed list, with D1's name and D2's line | **EXPENSIVE** once published | HIGH on the list; MEDIUM on D1's attestation condition, the operator's |
| § 3, the rules and the storage rule | **CHEAP** while nothing is built; **MODERATE** once built | HIGH |
| § 4, the choices, the notice and withdrawal | **CHEAP** | HIGH |
| § 5, `ADR-004` section by section, and the dated note | **CHEAP** — a note in a record | HIGH |
| § 6, the carrier | **CHEAP** while `Proposed`; **EXPENSIVE** once built | HIGH on the file, its class and its placement; MEDIUM-HIGH on the writer, whose values are conduct |
| § 4 and § 7, the approval rule and its supersession of `ADR-029` in part | **MODERATE** | MEDIUM — the operator's R1 |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| What the private site may show in general, the share mark and the safeguards | [the private-site record](ADR-030-what-the-private-site-may-show.md) |
| Where the group contacts section sits in each phase, and the page's shape | [the site phase-model record](ADR-031-site-phase-model.md) |
| What a channel is and what it may carry | `ADR-026` |
| The form labels, the notice's wording, the organizer-only file's name and the filing script's design | Wave 1 |
| Retention after the trip | a routed intake card |
| A deputy holder with the organizer's access | a candidate future card |
| How `ADR-029`'s gate is changed to match § 4's rule | Wave 1 (§ 7) |
| The record of this supersession inside `ADR-029` | the Wave-1 change that ships the replacement gate (§ 4, § 7) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1547:

- **The capture build**: the trip form's fields, choices and notice; the filing script, the
  organizer-only file and the block on agent reads; the way-to-reach's § 5.6 row with the queried set
  widened; the `TRIP` rows; and the recording verb, shared with the private-site record.
- **The carrier**: its class, schema, rules, writer contract through the projection, section, fences,
  erase row, dispatcher naming, validator list and sanitized witness; and, as the change that ships
  the replacement of `ADR-004`'s visibility sections, the dated note inside `ADR-004` with `ADR-011`'s
  dated amendment (§ 5).
- **Erasure's reach**: every trip page file, and the organizer-only file.
- **The erasure witness**: relabelled or reworded, with `ER15` green.
- **The private-site record's safeguard 6** gains the way to reach the contact when the capture ships.
- **The approval gate**, changed to match § 4's rule, with `ADR-029`'s record of this supersession in
  the same change (§ 7).
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's. The chore flips the status and nothing else: the notes inside `ADR-004` and
  `ADR-029`, and `ADR-011`'s dated amendment, land with the slices above.
- **Routed, not Wave 1's by this record:** retention after the trip; a deputy holder.

## References

- [The private-site record](ADR-030-what-the-private-site-may-show.md) — the coordination test, the
  share mark this record reuses, and the safeguards it cites: 1, the notice; 3, people who did not
  file; 4, refusal and removal at the next update; 5, the rotation fix first; 6, decision P; 7,
  decision Q.
- [The site phase-model record](ADR-031-site-phase-model.md) — the render table that places the
  carrier in every state
  the site builds.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the ladder that returns the carrier's section.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the two-grain contract
  whose rows and fences the carrier's
  slice extends.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot, whose writer and
  keying, and whose mark and
  withhold rules, the carrier reuses.
- [ADR-004](ADR-004-contact-emergency-privacy.md) — the contact and emergency model this record
  supersedes in part.
- [ADR-006](ADR-006-third-party-data-capture.md) — the third-party boundary: its scope, its Q1
  ground and its words on the appearance of consent.
- [ADR-026](ADR-026-channel-architecture.md) — § 2's channel admission, and § 3's intake observers and
  encrypted-limb assertion.
- [ADR-025](ADR-025-engagement-model-over-time.md) — the engagement value, the population floor and
  never-carry 1.
- [ADR-028](ADR-028-derived-planning-day-block-owners.md) — the reconciler-written derived file whose
  keying, write-set widening, erase-row shape and naming rules the carrier reuses.
- [ADR-003](ADR-003-group-coordination.md) — § 2, the approval that governs plan changes, which a
  withdrawal is not.
- [ADR-029](ADR-029-group-approval-return-and-threshold.md) — the gate step of § *Decision* 3, which this
  record supersedes in part once accepted, and § *Decision* 7, the partial form's precedent.
- [ADR-002](ADR-002-living-site-refresh.md) — the living-site record, whose privacy line, only to
  travellers, holds.
- [ADR-009](ADR-009-data-architecture.md) — its eighth amendment, the form the dated note inside
  `ADR-004` takes.
- [ADR-011](ADR-011-per-traveler-cost-estimation.md) — the restatements of `ADR-004` its dated
  amendment corrects.
- [ADR-021](ADR-021-installable-capability.md) — the data-root resolution the storage location reads
  through.
- [ADR-008](ADR-008-publish-content-guard.md) — the two-limb publish guard and the § 5.6 seam it
  reserved.
- `reference/data-architecture.md` — § 1.1's classes, § 5.1 and § 5.6's declaration.
- `reference/data-model.md` — § *Field Scope*.
- `templates/traveler-intake.template.md` and `templates/person-intake.template.md` — the forms the
  capture lands on, and the one that never declares it.
- `skills/trip-record/SKILL.md` — `promote`, `extract`, `profile` and the erase reach table.
- `agents/00-enrichment.md` and `agents/06-validator.md` — the carrier's writer, and the privacy audit.
- `scripts/publish-trip-site.sh`, `scripts/test-publish-guard.sh` and
  `scripts/test-artifact-schema.sh` — the guard and its queried set, and the erasure witness's arm.
- Provenance: the card, #1545; its design sub-task, #1546, carrying the design, the operator's D1 to
  D3, the carrier and its decisions K, S, P and MG-C1; the fit review, CR-2, R1 and T1 on #1369; decision Q
  on #1385; and the Wave-1 working notes this record's build detail moved to, on #1547.
