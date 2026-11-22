# Trip Lifecycle — What an Archived Trip Still Receives

**This document is the operative home of the rule on an archived trip.** A trip's lifecycle is the `**Lifecycle:**` marker line in its `trip-context.md`: `/trip-decommission` writes it, and gate `G4` of the resolution contract reads it and takes an absent line as `ACTIVE` (`reference/trip-resolution.md` § *Resolving a trip*). It is not an artifact's lifecycle class — `accumulate-append`, `rebuilt-each-synthesis`, `versioned`, `persist-mutable` or `output` — whose single home is `reference/data-architecture.md` § 6, and **the two axes are never the same field:** a `trip-context.md` carries `lifecycle: persist-mutable` in its frontmatter *and* a `**Lifecycle:** ARCHIVED` marker in its body, and neither is a rendering of the other. `reference/adr/ADR-012-people-library.md` records the decision; this document is the operative rule.

## Archived trips — what the freeze binds

**A trip whose `**Lifecycle:**` is `ARCHIVED` receives no derivation.** No update signal is written
to it, no artifact of it is regenerated, and no refresh pass composes it. `outputs/traveler-model.md`
holds the composition as it stood when the trip was archived: an edit to any person record it
references leaves it byte-unchanged and unsignalled. What the freeze protects is the plan **as it was
planned**.

**Erasure is the one stated exception, and it is the only one.** Erasure removes a person's
identifying values from a fixed set of locations; it composes nothing and regenerates nothing.
**On an archived trip, erasure substitutes and never regenerates.** Archived data is therefore
**reachable** — by that one operation, by that one mechanism, and by nothing else. A person who asks
to be erased is erased from archived trips too.

**Erasure must reach every model-entry class, and there are exactly three.** They are distinguished
by the provenance marks the entry carries, and they behave in three different ways under a
regeneration — which is why substituting rather than regenerating is the whole of the rule. An entry
carrying no mark is `first-party` and would be re-derived from its own source file. An entry carrying
`[OPERATOR-PROVIDED]` alone is `operator-provided-only` and would be **dropped**, having no source to
re-derive it from. An entry carrying both `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]` is `both-marks`
and would be **carried forward verbatim**, name and need intact — the erasure silently undone. The
two file-less classes fail in **opposite** directions, so no assertion over one of them detects a
wrong mechanism; only coverage of all three does. **Any fixture standing as the worked example of
this rule must exercise all three, and dropping one is a change to this rule, not a change to a
fixture.**

**The freeze binds derivation, not bytes.** `/trip-decommission archive` moves nothing: it takes the
site offline, sets the marker, and appends a closing entry. An archived trip's files sit at the same
paths as an active trip's and stay writable by whatever this rule admits. **"Frozen" means
underivable, never untouchable.**

**No other operation takes an exception, and two were tested against this rule and refused.** An
ordinary person-record edit is neither a redaction nor a re-addressing: it is not signalled, not
written, and is named in the discovery report as `ARCHIVED — not signalled`. A merge writes no
archived trip at all — the loser becomes a stub, and archived trips resolve through it. Anything that
composes, refreshes, regenerates or re-derives is inside the first paragraph and stays there.

**Reopening lifts the freeze prospectively.** `/trip-decommission reopen` sets the marker back to
`ACTIVE`; from that point the trip is in the ordinary refresh population and its next pass composes
current values. Reopen dispatches no agent and refreshes nothing itself, and nothing is queued while
a trip is archived — a reopened trip absorbs current state, never a replay.

**How the rule binds, and what it is not.** It binds the hub, the enrichment agent, the validator and the site build, and not all of them the same way. `CLAUDE.md` states its first sentence where every session reads it, the enrichment agent's prompt cites this section at the point it applies, and `/trip-record`'s `erase`, `history`, `past-coverage` and `interview` sections cite it for the ground they run on. Every verb that dispatches an agent is bound before it dispatches, by `G7`: each declares `lifecycle: ACTIVE`, so none resolves an archived trip, and `/trip-publish update` refuses on an archived trip before any build begins (`skills/trip-publish/SKILL.md` states that disposition in terms) — which is how `scripts/publish-trip-site.sh`, a shell script that never opens this document, is bound. Stating the rule binds its readers; `G7` binds its runners. The freeze stops no resolution and returns no `trip.stop_gate`, and `G8` is reserved and report-only. **The rule declares no artifact class and must never be read as a file-exception list**, which is why it stands apart from the exception sets in `CLAUDE.md` § *Output Versioning* that `reference/data-architecture.md` § 6's absence rule reads back to assign a class.

**The worked example is `examples/archived-trip-demo/`**, which carries an archived trip whose
erasure has already run, and `scripts/test-artifact-schema.sh` group `AF` asserts both halves against
it — that an ordinary person edit leaves it untouched, and that erasure reached it.
