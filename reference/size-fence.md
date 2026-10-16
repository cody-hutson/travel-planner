# Size Fence — the Byte Ceiling Each Tracked Markdown File Is Held To

**This document declares; `scripts/test-corpus-hygiene.sh` asserts.** The fence below gives every
tracked markdown file that owes a row a byte ceiling. The suite reads the fence on every push and
fails a file whose size exceeds its row, a file that owes a row and has none, a row naming a path
the tree does not hold, and a file whose only citation is its own row. Which files owe a row, and
how large a row is, are not decided here: both come from `reference/load-class-model.md`, and
nothing below declares a class, an instrument, a floor or a headroom a second time.

**Which files owe a row.** A file owes a row when the classification rule of
`reference/load-class-model.md` § 4 puts it in a class whose instrument is `row` or `constant`,
and its size is at or above that class's floor. A file below its class floor carries no row. Every
other file carries none for one of the following reasons, and each reason is that declaration's:

- **It is pinned.** A `frozen-witness-digest` row fixes its bytes already, so
  `reference/load-class-model.md` § 5 gives it the instrument `none` before its class is read.
- **Its second-level headings are release entries.** Its growth is its function, so
  `reference/load-class-model.md` § 5 gives it the instrument `none` whatever its class.
- **Its class takes no instrument.** `reference/load-class-model.md` § 5 declares the instrument
  `none` for that class.

**A row is a ceiling, never a size.** A row is written when it is seeded and rewritten when it is
re-pinned, and both times its value is the file's size at that commit, in bytes as the repository
stores it, plus the headroom its class declares — that share of the size, rounded up to a whole
byte (`reference/load-class-model.md` § 5, *headroom*). A row written at the bare size leaves no
room, and the next sentence anyone adds to the file fails. A change that moves bytes from one file
to another, such as a section relocated out of a larger document, re-pins every row it moved, in
the same change and by the same rule. Re-pinning the row of the file the classification rule puts
in the class `first-read` writes the suite's constant for that file to the same value, in the same
change, and the constant is re-derived the same way — the file's size plus its class headroom.
`CH_EMIT=growth ./scripts/test-corpus-hygiene.sh` prints
each row's re-pin value beside the file's size and its ceiling, so the value is read off rather
than worked out by hand.

**A re-pin is a decision, not a repair.** Raising a row is how a file is allowed to grow past its
ceiling, so the change that raises it says why, and the release that ships it names it in its
changelog entry (`CONTRIBUTING.md` § *Cutting a release*). Re-pin only the rows you meant to
change: regenerating the whole fence turns every ceiling into a record of whatever the files
already weigh.

**The first-verb read is held twice.** The file the classification rule puts in the class
`first-read` — the charter, which every verb reads before it acts — carries its row like any other
file and is also bounded by a named constant in the suite. Its row is held equal to that constant,
and a row above it or below it fails; of the two, the lower is the ceiling
(`reference/load-class-model.md` § 5, *instrument*), and held equal they are one. Raising its
ceiling is therefore an edit to the constant, in a diff of its own.

**What a green suite does not say.** That a file is the right size, or that a raised row was the
right decision: the suite holds each file to its row and reads nothing else. Nothing compares a
file's size with a lower bound — a file that shrinks reaches a finding only through what the
removed text said, such as a citation, a frontmatter key or a digest row the classification reads,
and never through its size — so a row can stand above what its file now needs. A row for a file
that has fallen below its floor, or that the declaration no longer holds to a row, is reported on
every run and not failed, and the growth summary lists it so the next release can take it out.

**Grammar.** Two columns, both required, whitespace-separated: the ceiling in bytes, then the
file's path from the repository root. A line whose first non-blank character is `#` is a comment,
and a blank line is ignored — the shape every declaring fence in this repository uses, read by the
same reader. Rows stand in byte order of the path.

```size-ceiling
# ceiling  path
147230     CLAUDE.md
81120      agents/00-enrichment.md
26506      agents/01-activities.md
32180      agents/02-food.md
39526      agents/03-scheduling.md
41696      agents/04-transport.md
91420      agents/05-hub-planner.md
79349      agents/06-validator.md
32371      agents/07-nightlife.md
36055      examples/data-architecture-demo/README.md
58860      reference/adr/ADR-007-command-entry-point.md
83538      reference/adr/ADR-008-publish-content-guard.md
71493      reference/adr/ADR-009-data-architecture.md
46051      reference/adr/ADR-010-per-traveler-approval-collection.md
35514      reference/adr/ADR-011-per-traveler-cost-estimation.md
150274     reference/adr/ADR-012-people-library.md
29911      reference/adr/ADR-015-durable-field-validity-horizon.md
36475      reference/adr/ADR-016-reusable-groups.md
30291      reference/adr/ADR-017-derived-trip-history.md
32970      reference/adr/ADR-018-cost-estimation-method.md
22249      reference/adr/ADR-019-discriminating-evidence-rule.md
47141      reference/adr/ADR-021-installable-capability.md
100252     reference/adr/ADR-022-interview-session-model.md
91076      reference/adr/ADR-023-interviewer-authored-home-and-form-contract.md
42880      reference/adr/ADR-024-form-contract-writer-boundary.md
80707      reference/adr/ADR-025-engagement-model-over-time.md
84663      reference/adr/ADR-026-channel-architecture.md
73704      reference/adr/ADR-027-post-trip-preference-memory.md
85334      reference/adr/ADR-028-derived-planning-day-block-owners.md
64173      reference/adr/ADR-029-group-approval-return-and-threshold.md
51958      reference/adr/ADR-030-what-the-private-site-may-show.md
55113      reference/adr/ADR-031-site-phase-model.md
22378      reference/adr/ADR-035-site-transitions-and-refresh.md
41376      reference/adr/ADR-037-group-snapshot.md
74948      reference/adr/ADR-038-contact-emergency-group-visibility.md
34208      reference/adr/ADR-041-third-party-roster-standing.md
29243      reference/adr/ADR-043-required-check-census-parser.md
78668      reference/adr/ADR-045-interview-conversation-conduct.md
96483      reference/adr/ADR-046-interview-rating-and-engagement-record.md
27574      reference/adr/README.md
138521     reference/data-architecture.md
242401     reference/data-model.md
63987      reference/site-layout-spec.md
60026      skills/trip-decommission/SKILL.md
40851      skills/trip-new/SKILL.md
48711      skills/trip-publish/SKILL.md
419047     skills/trip-record/SKILL.md
105747     skills/trip/SKILL.md
22110      templates/traveler-intake.template.md
```
