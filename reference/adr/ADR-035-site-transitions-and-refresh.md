# ADR-035: The site's transitions — replace, never accumulate; what a traveller was shown; and the refresh obligation

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1296, the milestone-head design gate for the epic *The site serves every phase*
  (#1241). The epic's build slices are cut only after the card's records are accepted. The card's
  decision is recorded one topic to a record, under the operator's R2 on #1369, and this record
  carries what happens at a transition, and the refresh obligation; *References* lists the card's
  other records. The milestone's other cards are [the private-site
  record](ADR-030-what-the-private-site-may-show.md) (#1242) and [the contact and emergency
  record](ADR-038-contact-emergency-group-visibility.md) (#1545).
- **The precondition of this record's status flip.** This record flips to `Accepted` only after [the
  private-site record](ADR-030-what-the-private-site-may-show.md) reads `Accepted` — in its
  `Status:` line and in its index cell — because the card's pre-plan rows, in [the site phase-model
  record](ADR-031-site-phase-model.md), render values that record admits. The flip is the
  maintainer's, taken at this milestone's close, and it moves both halves of a two-artifact state:
  the `Status:` line above, and this record's `Status` cell in `reference/adr/README.md`.
- **What this record is.** A decision about **what happens to earlier-phase content at a transition, what a
  traveller was shown, and the refresh obligation**: the render policy at a change of state, the
  `build-to-published` relation, and the steps R0 to R3.
- **What this record is not.** It does not decide what each state renders, which is [the site
  phase-model record](ADR-031-site-phase-model.md)'s. It builds nothing, and in this release it
  changes no `publish:` value, no fence line and no per-verb requirement row: every change it
  decides lands in a later slice.
- **How it was decided.** In the second design pass on the card's design sub-task #1388, which decided the
  transitions; the milestone's fit review, which put the `list` edit in the shipped tokens (MG-4),
  and its scope lock, CR-2, whose first call fixes how a refusal reaches the page, are recorded on
  #1369. The card's one record was split by topic under the operator's R2, recorded on #1369,
  with no decision changed.

## Context

**The refresh obligation the card's shape creates.** [The site phase-model
record](ADR-031-site-phase-model.md) keys the site's shape on the resolved state σ = (`trip.mode`,
`trip.destination`), so a change of state is a change of shape, and the published render is out of
date until it is rebuilt **and** republished. That record names the obligation; this record sets its
policy.

**What the live target establishes.** Every fact below was read live at `8b2ac05`, the base of this
release.

- **The organizer-confirm gate keys on the visible text of the whole render**, less the coordination
  band and the render's declaration block.
- **The freshness relation already watches the Mode line.** `itinerary-to-build`, inside
  `trip.freshness`, reads its source side from the paths the `site` verb's **Reads:** line declares,
  and `/trip-record mode` writes the Mode line into `trip-context.md`, one of them.

**The inputs this record is bound by.** The milestone's surface map, recorded on #1369, fixed the
closed list of what this record still had to decide.

## Decision drivers

1. **The publish surface is fixed.** One self-contained file (`reference/site-layout-spec.md` § 8),
   guarded by one ciphertext check over one render (`ADR-008`), with one passphrase per repository.
   This record decides rendering, not reach.
2. **Reuse the shipped vocabulary** — the mode set `G5` declares, the cell grammar of `G7`, and the
   `rendered | excluded` enum — as `ADR-025` did when it withdrew a minted staleness vocabulary.
3. **Reversibility.** The card's tier is EXPENSIVE once slices build on it, so the option whose later
   correction is cheapest wins a tie.
4. **The milestone's surface map is the closed scope** of what this record decides.

## Options considered

### The transition policy, and the shown relation's observation

**Replace** is chosen. Accumulating is rejected: a second source, and a ciphertext that grows with
history. A client-side hide is rejected for the reason the client-side switch was
([the site phase-model record](ADR-031-site-phase-model.md)'s option F).

| Criterion | **Content identity** (chosen) | Order (today's `list`) |
|---|---|---|
| What it measures | whether what crossed the channel is the built artifact — `ADR-025` § 6's own words | whether anything was built after the last push |
| A rebuild that changes nothing | `CURRENT` | reads stale — a false positive |
| Clocks | none; the comparison is local | the local modification time against the remote commit's date, across two machines |
| Needs the network | no | yes |
| Reuses | the confirm gate's projection and the publish script's record of the last push | the file's timestamp and the remote commit date |
| Blind to | a push made from another machine | a content-free touch that reads as change |

## Decision

### 1. Transitions, what a traveller was shown, and the refresh obligation

**The render policy: replace, never accumulate.** A build renders exactly its state's row. Content from
a superseded phase is not rendered — not as history, not collapsed, not hidden, because hidden text still
ships inside the ciphertext.

| Transition | What the next build does | How |
|---|---|---|
| IDEATION × UNDECIDED → × DECIDED | the shortlist section goes; the hero names the destination in play; the group snapshot and the group contacts sections stay | **a create**: the file name's stem changes from the trip's slug to the destination, so the verb's existence probe misses and the first build with a destination writes a new page. The IDEATION page stays on disk, unpublished by rule, because publish and both relations take the newest page; nothing is deleted, as `ADR-007` § 2 requires, and erasure reaches both files ([the site-admission record](ADR-034-site-build-admission.md)) |
| IDEATION × DECIDED → a plan mode | the plan-phase shape; the group snapshot section leaves; the group contacts section stays | a structural patch of the same file; the shape pass catches a leftover section |
| a plan mode → a plan mode | no change of shape | a patch |
| a plan mode → IDEATION | the plan sections go; the group snapshot section returns; the shortlist returns only if the destination was cleared | a structural patch, or for *No destination yet* the slug-named page, patched if present and created if not |
| any state → `UNSET` | no build | the published page stays at its last build |

**A published page from a superseded phase is a liability, within a bound.** From the transition until
rebuild, confirm and republish, the group sees the superseded phase. The worked instance is the stale
shortlist: the group has chosen a place, and until the site is rebuilt and republished the page still
ranks it beside the places they passed over. **The liability lasts exactly as long as the relation below
reads `BEHIND`.**

**The relation — declared outside `trip.freshness`**, as `ADR-025` § *Decision* 6 requires of a relation
whose derived side is what a traveller was shown.

| Field | Declared value |
|---|---|
| **name** | `build-to-published`, in the shipped `<source>-to-<derived>` form |
| **derived side** | what crossed the channel: the render as last pushed |
| **source side** | the newest local render, the member publish itself takes |
| **observation** | **content identity** |
| **verdicts** | the shipped family, by exact token. `CURRENT` when they are equal; `BEHIND` when they differ, naming the local render as the leading source; `UNDETERMINED` when no push is recorded, naming the published side, or when the render cannot be projected, naming the render |
| **evaluated by** | `/trip-publish list`, in its own report, labelled as outside `trip.freshness` |
| **gating** | none; report-only. The publish verb never branches on freshness |
| **cannot observe** | a push made from another machine; anything outside the projection — the coordination band and the render's declaration block — by design; materiality |

`list` computes its staleness column today by order — the local modification time against the remote
commit's date — with its own tokens. The relation takes the shipped verdicts and the identity
observation, and the `list` edit — `scripts/publish-trip-site.sh`'s `cmd_list` and
`skills/trip-publish/SKILL.md` § *list* — is Wave 1's. `list` stays read-only and never gates.

**The refresh obligation.** Automating any step of it belongs to the living-site milestone.

| Step | Trigger | Signal | Remedy |
|---|---|---|---|
| **R0 reconcile** | a traveller's form, a person record, the roster or a link changes | the verb that made the change names `/trip-record travelers` without running it | `/trip-record travelers` |
| **R1 rebuild** | a change of σ — the trip context written by `/trip-record mode` or `/trip-record destination` — or of an admitted input: the shortlist by `/trip ideas`, the group snapshot and the group contacts file by the reconcile step, the plan artifacts by planning | `itinerary-to-build` reads `BEHIND`, naming the leading source | `/trip site` |
| **R2 confirm** | a rebuild that changes the visible text | the organizer-confirm gate refuses `update` | `confirm`. This is intended under `ADR-003` § *Decision* 2, not a deadlock: `confirm` is always the organizer's, and a digest-only change needs none. On a trip that declares approvers, `ADR-029` § *Decision* 3 extends the same step: the organizer records each declared approver's reply through `confirm`, and `update` proceeds once they reach the declared threshold |
| **R3 republish** | R1 and R2 done | `build-to-published` reads `BEHIND` | `/trip-publish update` |

**A refusal, a removal or a withdrawal reaches the page through R0 to R3.** Under the private-site
record's safeguard 4 it is recorded only through a verb that runs the reconcile step, so every staleness
report shows the page as behind until the organizer's next update carries it; no publish gate is added.

**The shortlist's own staleness case.** A shortlist built from the fallback read and later overtaken by
a model rebuild changes no class. If `/trip ideas` re-runs, R1 to R3 carry the new shortlist to the
page; if it does not, the shortlist against its own inputs is observed by no relation — a declared
residual, since the shortlist is rebuilt only by its own verb.

### 2. Conformance to `ADR-025`, `ADR-003`, `ADR-029` and `ADR-007`

| Accepted decision | How this record conforms |
|---|---|
| `ADR-025` § 6, staleness | `build-to-published` reuses the shipped verdict family and its rules, has no disposition column, is declared by its consumer, and is evaluated outside `trip.freshness` |
| `ADR-003` § 2 | A transition's or a snapshot change's visible-text change reaches the group only through the organizer's `confirm` (R2) |
| `ADR-029` § 3 | On a trip that declares approvers, the same visible-text change reaches the group only once the declared approvers' replies, recorded by the organizer through `confirm`, reach the threshold (R2). The remedy is unchanged |
| `ADR-007` § 2 | Nothing is deleted at a transition; the IDEATION page stays on disk |

## Consequences

**Positive**

- **The stale published shortlist has a declared signal**, `build-to-published`, a remedy (R1 to R3) and
  an owner for its automation, the living-site milestone.

**Costs and residuals, stated rather than smoothed**

- **Transitions that change visible text ask for the organizer's confirmation**, by `ADR-003`'s own
  logic — and, on a trip that declares approvers, for the approvals the organizer records up to the
  threshold, by `ADR-029`'s; that is new behaviour.
- **`build-to-published` cannot see a push made from another machine**, and the shortlist against its own
  inputs is observed by no relation.

**Aggregation trace — what consumes each new evaluand.**

| Evaluand | Consuming rule | Effect on the aggregate |
|---|---|---|
| `build-to-published` reads `BEHIND` | `/trip-publish` rule 7: "It never branches on freshness, and adds no gate that blocks on it." | report-only |
| a transition's, or a snapshot change's, visible-text change | the organizer-confirm gate, whose proceed set is the organizer's own confirmation — on a trip that declares approvers, `ADR-029` § *Decision* 3's threshold | `update` waits for `confirm` — intended under `ADR-003`, and under `ADR-029` on a trip that declares approvers |

**The non-blocking claims hold.** The shown relation never gates a publish.

**Blast radius — Wave 1, named here and not performed; this release keeps all of it out.**

| Surface | The change these decisions oblige |
|---|---|
| `scripts/publish-trip-site.sh` `cmd_list` · `skills/trip-publish/SKILL.md` § *list* | `build-to-published` |

**Three axes.** *Best practice:* a report-only relation. *Maintainability:* it reuses the shipped
verdict family and the confirm gate's projection, and renames nothing.

**Reversibility and confidence.**

| Decision | Reversibility | Confidence |
|---|---|---|
| § 1, transitions and staleness | **MODERATE** — report surfaces | HIGH on the policy; MEDIUM-HIGH on the identity observation |

## What this record does not decide

| Not decided here | Decided by |
|---|---|
| Scheduled refresh, re-encryption and republish | the living-site milestone |
| What each state renders | [the site phase-model record](ADR-031-site-phase-model.md) |
| The page's file name, and erasure's reach over every page file | [the site-admission record](ADR-034-site-build-admission.md) |

## Follow-on build slices

All Wave 1, none live before the fix for the rotation defect tracked privately. Each slice names
what Wave 1 must specify; the build detail this record does not carry is kept, non-binding, in the
Wave-1 working notes on its Stage-6 sub-task, #1392:

- **`build-to-published`** in `list`.
- **At this milestone's close**, in the ratify chore: this record's `Accepted` flip, after the
  private-site record's.

## References

- [The private-site record](ADR-030-what-the-private-site-may-show.md) — safeguard 4, which a
  refusal, a removal or a withdrawal reaches through R0 to R3.
- [The site phase-model record](ADR-031-site-phase-model.md) — what drives the site's shape, and the
  map of what each state's build renders.
- [The round-trip contract record](ADR-032-site-round-trip-contract.md) — the round-trip contract
  across the rendered artifacts, and the walk.
- [The section-ceiling record](ADR-033-site-section-ceiling.md) — the four-test ladder that decides
  what earns a section.
- [The site-admission record](ADR-034-site-build-admission.md) — the build verb's admission of the
  pre-plan states, the page's file name and the pre-plan classes.
- [The published-artifact record](ADR-036-published-artifact-model-row.md) — `ADR-026` Finding 1,
  declined in terms and routed.
- [The group-snapshot record](ADR-037-group-snapshot.md) — the group snapshot.
- [ADR-025](ADR-025-engagement-model-over-time.md) — § 6's staleness family.
- [ADR-003](ADR-003-group-coordination.md) — § 2, the organizer's confirmation.
- [ADR-029](ADR-029-group-approval-return-and-threshold.md) — § *Decision* 3, the approvals the
  organizer records through `confirm` against a declared threshold, on a trip that declares approvers.
- [ADR-007](ADR-007-command-entry-point.md) — § 2, under which nothing is deleted at a transition.
- `skills/trip/SKILL.md` — the freshness report.
- `skills/trip-publish/SKILL.md` — the `update` row, rule 7 and § *list*.
- `skills/trip-record/SKILL.md` — the reconcile-step namings.
- `scripts/publish-trip-site.sh` — the publish path and `cmd_list`.
- Provenance: the card, #1296; its design sub-task, #1388, carrying the second pass; the fit review,
  CR-2 and R2 on #1369; and the Wave-1 working notes this record's build detail moved to, on #1392.
