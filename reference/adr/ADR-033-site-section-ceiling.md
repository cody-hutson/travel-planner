# ADR-033: The site's section-growth ceiling — four tests over declared tables, and what earns a section

- **Status:** Accepted (2026-09-27)
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries its section-growth ceiling; *References* lists the card's other records. The milestone's
  other cards are [the private-site record](ADR-030-what-the-private-site-may-show.md) (#1242) and
  [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after [the
  private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because the card's pre-plan rows, in [the site phase-model
  record](ADR-031-site-phase-model.md), render values that record admits. The flip is the
  maintainer's, taken at this milestone's close, and it moves both halves of a two-artifact state:
  the `Status:` line above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **what earns a section** on the site: a four-test ladder over
  declared tables, calibrated on the dispositions the corpus already decided.
- **What this record is not.** It does not decide what each state renders, or where a section sits
  in each state — that is [the site phase-model record](ADR-031-site-phase-model.md)'s. It builds
  nothing, and in this release it changes no `publish:` value, no fence line and no per-verb
  requirement row.
- **How it was decided.** In the first design pass on the card's design sub-task #1388, which
  decided the ceiling; the milestone's fit review and scope lock, CR-2, are recorded on #1369. The
  card's one record was split by topic under the operator's R2, recorded on #1369, with no decision
  changed.

## Context

**Nothing bounds surface growth.** No rule states what earns a section rather than a field on an
existing one, so every new artifact class is an unbounded negotiation; #87 is the downstream
symptom.

**Precedents this record reuses rather than mints.**

| Precedent | Where | What it already decided |
|---|---|---|
| Split-Day | `reference/site-layout-spec.md` § 3 | it replaced a page per subgroup with a region inside one day: the catalog has rejected pages per unit once |
| Coordination Notice | the same § 3 | site-additive scaffolding that no § 9 table carries, and that is not emitted when empty |
| Nightlife decline | the same spec, § 9.2 | rendered through the existing band, with no new card type |
| Structural-gap boundary | the same spec, § 9.5 | a new component is built only for an element no component can represent |

**The inputs this record is bound by.** The milestone's surface map, recorded on #1369, fixed the
closed list of what this record still had to decide.

## Decision drivers

1. **#1241's acceptance criteria.** Completeness per mode, checkable by the walk; shape as a function
   of the declared mode; and a ceiling that returns a yes or a no.
2. **One declared home per fact, graded by an existing suite** — the corpus pattern of groups `PB`,
   `W` and `MG`. A rule nobody grades is the defect group `W` was built to close.
3. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
4. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### The section ceiling

| | Option | Disposition |
|---|---|---|
| K1 | A numeric cap on sections per state | **rejected.** Nothing grounds the number, and a cap forces the re-litigation the criterion forbids |
| K2 | One section per distinct reader question | **rejected.** A judgment per card |
| K3 | One section per artifact | **rejected.** False today: the Hero, the Overview, the Day sections and the Checklist all render itinerary elements |
| **K4** | **A four-test ladder over declared tables** | **chosen.** It reuses § 9.5's representability test and the § 9.1, § 5.1 and § 5.6 declarations, and reproduces every decided case |
| K5 | A section budget per mode | **rejected.** A budget invites spending it |

## Decision

### 1. The section-growth ceiling

A proposed addition goes through four tests, in order. The first test that decides returns the
disposition; only a proposal that passes all four earns a section.

| Test | The question, answered from a declared table | If it decides |
|---|---|---|
| **Q1 Source** | Does it render plan content — an element type with a § 9.1 authority? | **No → scaffolding (D1).** Admitted only under § 9.2's additive clause: no plan content, reads only what the build already reads, not emitted when empty, no navigation entry |
| **Q2 Reach** | Is every value it renders readable in every state it targets — an authority that is `bound`, not denied by the § 5.6 value fence, and admitted by `may-carry`? | **No → blocked (D0).** Not a ceiling question; it goes to the class owner or the verdict |
| **Q3 Representability** | Can an existing § 3 component carry its element type as a field, a variant, or an entry in an existing region? | **Yes → a field or variant (D2)** of that component — § 9.5's test, applied at section level |
| **Q4 Placement** | Is its element keyed to a unit an existing section already iterates over — a day, a track, a booking item? | **Yes → a region (D3)** of that section; a new component is allowed only because Q3 found none |
| — | none of the four decided | **A section (D4)**, with its render-table rows, its element-fence rows and its declared empty state |

**Mode never earns a section by itself.** A proposal whose only ground is that one mode would like the
same content shown differently is a variant, under Q3; that is why the four plan modes share one
shape. #87 consumes Q3 and Q4 as its card-type questions.

**Calibration** — the ladder reproduces every disposition the corpus already decided:

| Case | Q1 | Q2 | Q3 | Q4 | Ladder | Corpus |
|---|---|---|---|---|---|---|
| Booking Checklist | the itinerary's checklist element | `bound` | no component renders a list spanning days ordered by action date | not per-day | **D4 section** | a section |
| Split-Day | the Parallel Track | `bound` | none could | per-day | **D3 region** | a region of one day |
| Nightlife decline | a line of the itinerary | `bound` | the band carries it | — | **D2 field** | no new card type |
| Coordination Notice | no plan source | — | — | — | **D1 scaffolding** | carried by no § 9 table |

**The worked example: an ENRICHMENT *Flights & lodging* section → NO.** Q1 passes: the facts belong to
the trip context, whose § 9.1 row already feeds the hero and the overview. Q2 passes: the trip context
is `bound`, and no § 5.6 row is scoped to it. **Q3 decides**: the Overview Dashboard and the Hero's
stats grid already carry the trip context's trip-level facts. It is **a field of the Overview
Dashboard**, filled when present in any plan mode and not emitted when absent, with no section, no
render-table row and no mode gate.

**The ladder, run on the additions the card's records and the contact and emergency record
decide:**

| Proposal | Q1 | Q2 | Q3 | Q4 | Result |
|---|---|---|---|---|---|
| **The destination shortlist** | its elements, with a § 9.1 authority row when it becomes `bound` | `bound` once moved; its values are in the private-site record's IN list; no § 5.6 row scopes it | no component represents a destination candidate | trip-level, not per-day | **D4: a section, `group-shortlist`** |
| **The concealed occasion** | an itinerary event | the concealed form carries only plan facts | the schedule-timeline entry can carry it | — | **D2: an `is-concealed` variant** of the schedule entry; no new card type |
| **The group snapshot**, by citation to [the group-snapshot record](ADR-037-group-snapshot.md) | its elements, with a § 9.1 authority row when its class lands | `bound`; every value in the private-site record's IN list; no § 5.6 row scopes it | no § 3 component carries a per-traveller record | keyed to a person, and no section iterates people | **D4: a section, `group-snapshot`** |
| **The group contacts file**, by citation to [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) | its elements, with a § 9.1 authority row when its class lands | `bound`; every rendered value admitted by that record; the one § 5.6 row involved names a value the file never carries | no component carries a per-traveller record in every state | keyed to a traveller, and no section iterates travellers in every state | **D4: a section, `group-contacts`** |

## Consequences

**Positive**

- **The section ceiling returns a yes or a no**, calibrated on the decided cases; #87 consumes Q3 and Q4.

**Costs and residuals, stated rather than smoothed**

- **Mode never earns a section by itself** (§ 1): a mode that would show the same content differently
  gets a variant under Q3, so the four plan modes share one shape — the cost [the site phase-model
  record](ADR-031-site-phase-model.md) states as its own.
- **The ladder does not decide reach.** A proposal whose values are not readable in every state it
  targets is blocked at Q2 (D0) and goes to the class owner or the verdict, not to the ceiling (§ 1).
- **The ceiling is rule text** and opens no build slice of its own (*Follow-on build slices*); per-card
  visual design is #87's, which consumes it.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, the ceiling | **CHEAP** — rule text | HIGH |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| Per-card visual design | #87, which consumes this record's ceiling |
| What each state renders, and where each section sits in each state | [the site phase-model record](ADR-031-site-phase-model.md) |
| What the group snapshot carries | [the group-snapshot record](ADR-037-group-snapshot.md) |
| What the group contacts file carries | [the contact and emergency record](ADR-038-contact-emergency-group-visibility.md) |

## Follow-on build slices

The ceiling is rule text and opens no build slice of its own. The build detail this record does not
carry is kept, non-binding, in the Wave-1 working notes on its Stage-6 sub-task, #1392.

- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The site phase-model record](ADR-031-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The site-transitions record](ADR-035-site-transitions-and-refresh.md) — transitions, what a
  traveller was shown, and the refresh obligation.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [The contact and emergency record](ADR-038-contact-emergency-group-visibility.md) — the group
  contacts file, whose section the ladder returns.
- `reference/site-layout-spec.md` — § 3's catalog, § 9.1, § 9.2 and § 9.5.
- `reference/data-architecture.md` — § 5.1 and § 5.6.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the first pass; the plan, its
  surface map, the fit review, CR-2 and R2 on #1369; and the Wave-1 working notes this record's
  build detail moved to, on #1392.
