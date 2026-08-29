# ADR-009: Data architecture — entity identity, serialization, publishability, topology, and schema evolution

- **Status:** Accepted (2026-08-28); **amended twice (2026-08-29)** — citation form, then the
  `provenance` enum's membership.
  **First amendment** — citation form only, and the whole population of it. This document cited
  `scripts/publish-trip-site.sh` by line number at **five anchor tokens** across **three citation
  sites** — three naming the file and two written as bare continuations of them. The script was
  rewritten in this same release and grew from 1,316 to 1,540 lines, so every one of the five pointed
  at unrelated content within a commit of this document landing — the exact rot the anchors were
  supposed to be immune to. All five are converted to the durable form this repository already uses
  for that file and which this document's own References section already used alongside them:
  **function name plus verbatim quotation**, naming `nonpublishable_values`, its reserved-key branch,
  the `CD-4` declaration comment and the top-level `_GUARD_RESERVED_KEYS` list. Two quotations that
  the rewrite had silently falsified are corrected to the text the source now carries. This document's
  two citations of the filename-derivation section of `.claude/commands/trip-new.md` named a heading
  that does not exist there; both now name the one that does,
  § *Travelers — count and names*. **No decision, rule, residual, coverage claim or key derivation is
  changed, and none is re-opened.** Recorded here rather than by supersession because an Accepted ADR
  is immutable **as to its decisions**, and `reference/adr/README.md § Convention` now states the
  amendment rule this correction follows.
  **Second amendment** — the `provenance:` enum's membership, at both sites that render it. This
  document declared a **five-member** enum, omitting `researched`. Every other surface ships **six**:
  `reference/data-architecture.md`, all **19** per-class schemas, and **six** of the class rows in its
  § 1.1 — classes 5–9 and 18, the whole research-output family — depend on that value, and
  `scripts/validate-artifacts.sh` reads the enum from that section rather than from this document. The
  omission is a transcription error in the record, not a narrower decision the implementation exceeded;
  the decision — that provenance is a frontmatter-declared closed enum — is unchanged. The mechanism
  is visible in Decision 5, which is left standing: the value-level bracket marks are a **four-member**
  vocabulary, and `researched`, like `human`, carries **no** value-level mark anywhere in the corpus,
  because both are artifact-scoped. Reading the enum off the marked values yields five. Both renderings
  now read `human | enrich | derived | operator-provided | third-party | researched`, the order all 19
  schemas already use. **No decision, rule, residual, coverage claim or key derivation is changed, and
  none is re-opened.**
- **Deciders:** repo maintainer
- **Driving work:** #275, under the engine-wide data-architecture epic #273. Records the six decisions
  settled by the specification slice #274 and consumed by #276–#288. Records the disposition of #156
  (venue identity). Amends the citation form of `ADR-008` (fourth amendment). Extends the publication
  reasoning in `ADR-004` and `ADR-006`.

## Context

The engine's per-trip artifacts are markdown documents written by nine agents, two templates, a
publish script and an operator. They are read by other agents, by a fail-closed publish guard, and by
a site build. Nothing in that chain is machine-validated: an artifact's identity, its writer, its
lifecycle, its publishability and its version are all carried in prose, or carried nowhere at all.

Four consequences are already measured in this repository, and they are the reason this record exists
rather than a style preference.

**The same place carries different names in different artifacts, and no rule can reach it.** #156
records three venue collisions; the cross-spoke join rule introduced in v0.9.0 resolves one. Its
collision 3 is *intra*-spoke — two entries in one file for one place — and #156's own body states the
limit exactly: *"Two names for one place cannot be deduplicated by any rule that keys on the name."*
The research artifacts compound this: their entry headings are compound display strings carrying a
file-scoped ordinal, and those files are append-with-dated-sections, so the ordinal is not stable
across a re-run either.

**The non-publication invariant is enforced by string-matching prose.** `ADR-006` forbids a
third-party-sourced value from reaching a published artifact *in attributed or anonymized form*, and
`ADR-008` implements that as a value-keyed predicate over the rendered bytes. `ADR-008`'s own coverage
boundary records eight residuals and states the root cause in terms: a short, common-vocabulary value
*"is not reliably keyable by string matching at all… That is a class-definition problem, not a guard
defect, and it belongs to #278."* The guard cannot be made complete from inside itself.

**The artifact set is larger than any document names.** The documented census is 17; the live per-trip
population carries **25** classes once every file class is disposed of, two of them with zero
references anywhere in the tracked corpus. A migration graded against 17 would pass while leaving
eight real classes undisposed.

**The governing document does not govern the whole engine.** `reference/data-model.md` scopes itself
on its own first line — *"Data Model — The Satisfaction Layer"* — and formally models 4 of the 19
in-model classes, yet `CLAUDE.md` cites it for lifecycle definitions covering artifacts its declared
scope excludes.

Two constraints bound every option below, and both are structural rather than stylistic.

**`reference/data-model.md` is pinned by line number.** It is cited at `path:NNN` **14 times across 3
files** — `reference/adr/ADR-008-publish-content-guard.md` (5 occurrences),
`scripts/publish-trip-site.sh` (7) and `scripts/test-publish-guard.sh` (2) — resolving to **four
distinct anchors: 139, 143, 170 and 266**, all within the first 41.0% of the 648-line pre-release
text. Two of the three citing files are executed by a CI workflow that runs on every push to every
branch. **Eight of this release's sixteen delivery slices edit this file.** Any net insertion above
line 266 silently invalidates all four anchors at once. The denominator is stated as *pre-release*
deliberately: this release appends below the anchor, which moves the percentage and must not be read
as moving the anchor.

**Migration is irreversible where it matters most.** A trip that has been migrated lives in a user's
git-ignored working directory. This repository cannot reach it, cannot inspect it and cannot migrate
it a second time. Every decision below that reaches a user's artifacts is therefore weighed as
irreversible in practice, whatever its in-repo revert cost.

## Decision drivers

- **One home per fact.** `reference/data-model.md` already states *link, don't copy — one source per
  fact*. The decisions below extend that rule to the serialization axis rather than introducing a
  second discipline beside it.
- **A rule must derive the decisions already made.** Three identity precedents already ship: the
  opaque day-independent Event ID, the traveler-name normalization executing in the publish guard, and
  the constraint-name link target. A rule that cannot explain them is a preference wearing a rule's
  clothes.
- **Structure must not be bought with output quality.** The engine's value is judgment written in
  prose — reasoning, caveats, voice. The tempting failure is to keep migrating prose into fields until
  the artifacts are databases that no longer say anything. The boundary must be a test that *cannot*
  pull narrative into a field, not a reminder not to.
- **Fail-closed controls stay fail-closed.** `ADR-008`'s guard reaches UNDETERMINED on five distinct
  conditions and aborts. Re-sourcing its class must not cost a single one of them: an unusable
  fail-closed control is fail-open in practice, because it gets worked around.
- **Existing line-number citations must survive an eight-way contended rewrite**, and the citation
  form that keeps failing must stop being authored.
- **A reader must never fail on a version it does not recognize**, and must never silently write over
  one it does not understand.

## Options considered

Four choices carried two or more genuine candidates and were explored divergently before the matrix
was scored. Two carried a single forced approach and are recorded as such rather than padded.

### D1 — Document topology

| Option | Mover-set | Line-anchor cost | Coherence | Verdict |
|---|---|---|---|---|
| **(a) New `reference/data-architecture.md` above a narrowed-in-place `reference/data-model.md`** | **empty** | The insertion point is a *new file*; `data-model.md` takes one bounded edit that can be confined below its last cited anchor | Layer-coherent — the satisfaction layer keeps its own document and its own boundary section | **CHOSEN** |
| (b) Expand `data-model.md` to engine-wide scope | empty | **Necessarily rewrites the scope declaration at lines 3–5, shifting all four anchors** cited 14 times across 3 files, 2 of them CI-guarded | Produces a single ~1400-line document mixing engine-wide contract with satisfaction-layer detail | Rejected |
| (c) Relocate `data-model.md` under a new `reference/data/` subtree | **16 files / 75 references, 2 CI-guarded scripts** | The same anchor problem *plus* a whole-corpus path sweep | — | Rejected |
| (d) Split into per-artifact schema files only, no prose spec | empty | — | Discards the reconciliation and lineage prose that is the document's actual value | Rejected |

**(b) is rejected on arithmetic, not taste.** Engine-wide scope requires rewriting the scope
declaration at lines 3–5. There is no edit that both achieves engine-wide scope and leaves line 139 at
line 139. Option (a) is the only option whose `data-model.md` edit can be confined below the last
cited anchor.

**(c) is priced explicitly rather than dropped.** Relocation converts a currently-empty mover-set into
a sweep of 16 files and 75 references, two of them CI-guarded shell scripts, inside a release already
carrying eight-way contention on that same file. It is not recommended, and the analysis does not
conclude it is nonetheless correct.

**A rejected reason, recorded so it is not re-proposed.** An earlier statement of this choice rejected
(b) on the ground that *the ADR-008 citations cannot be repaired because an Accepted ADR is
immutable*. **That premise is false** — `ADR-008`'s own status line records three amendments, and this
ADR carries a fourth. The conclusion is unchanged and rests on the three independent grounds above:
the mover-set, the monolith, and the fact that repairing citations in one ADR would not repair the
nine in the two CI-guarded scripts.

### D2 — Entity identity: surrogate or natural

| Option | Reproduces the Event precedent? | Resolves the venue collision? | Resolves the traveler case? | Verdict |
|---|---|---|---|---|
| (a) Surrogate everywhere | Yes | Yes | **No** — churns `travelers/<name>.md`, breaks the guard's `## <Name>` parse and `/trip-new`'s filename derivation | Rejected |
| (b) Natural everywhere | **No** — contradicts the opaque day-independent Event ID the engine already mints | **No** — #156's collision 3 is out of reach by construction | Yes | Rejected |
| **(c) A rule decided once per entity: origin of identity × natural-candidate stability** | **Yes, and explains why** | Yes | Yes | **CHOSEN** |
| (d) Case by case, per artifact | — | — | — | Rejected — this is the condition the epic exists to end |

Option (c) is chosen because it is **discriminating**: it splits ten entities five and five rather
than rubber-stamping one answer, and it *derives* all three shipped precedents instead of overriding
them.

### D3 — The frontmatter/body boundary

| Option | Protects narrative? | Decidable without judgment? | Verdict |
|---|---|---|---|
| (a) An enumerated list of frontmatter fields per class | No — the list grows by accretion and nothing resists the next addition | Yes | Rejected |
| (b) A prose guideline ("keep reasoning in the body") | No — a guideline is not a boundary | No | Rejected |
| **(c) A three-question test, all three of which must answer yes** | **Yes, by construction** — narrative fails question 2 and cannot be argued past it | Yes | **CHOSEN** |

### D4 — Publishability granularity

| Option | Expresses a non-publishable `Passport` field? | Expresses the `[THIRD-PARTY]` entry class? | One class source? | Verdict |
|---|---|---|---|---|
| (a) Per-artifact only | No — `traveler-model.md` is internal, but `trip-context.md` is publish-bound and can still carry a third-party value | No | Yes | Rejected |
| (b) Per-field only | Yes | **No** — the third-party bound is an *entry-class denylist*, not a field allowlist | Yes | Rejected |
| **(c) Both, composed by union** | Yes | Yes | Yes — the union is computed, never enumerated twice | **CHOSEN** |

The guard's own source settles this. `scripts/publish-trip-site.sh` states it twice — in the `CD-4`
declaration comment, *"the `[THIRD-PARTY]` member is an ENTRY DENYLIST, not a field allowlist"*, and
again at the entry limb inside function `nonpublishable_values`, *"a DENYLIST over the entry, not a
field allowlist"* — and the line below that limb records the composition: *"The declared selector is
read at BOTH granularities and the two are a UNION."* A per-field-only model cannot express an
entry-scoped denial, and `reference/data-model.md` § *Lifecycle facets* says the same thing in the
corpus: *"The bound is the entry class, not a list of fields… there is no default-allow outside it."*

**Single-approach choices, recorded rather than explored.** The frontmatter *format* — YAML opened and
closed by `---` as the first bytes — is the only fenced-frontmatter form this repo or its runtime
recognizes. The *placement* of the version field is frontmatter, because a body-level version cannot
be read without parsing prose, which is the condition being removed.

## Decision

Six decisions. Each is applied once, at the level stated, and is not re-litigated per artifact or per
slice.

### 1. Document topology — two layers, and a hard ordering rule on the lower one

**A new engine-wide document, `reference/data-architecture.md`, sits above
`reference/data-model.md`.** It owns the artifact enumeration, the entity model, the identity rule,
the frontmatter/body boundary, the publishability model, the lifecycle classification and the version
contract — for all 19 in-model artifact classes.

**`reference/data-model.md` is narrowed in place.** It is not moved, not renamed, not deleted and not
expanded. It remains the **satisfaction-layer specialization** of the engine-wide model and keeps its
own `§ What This Document Does Not Define` boundary. Where the two overlap, the engine-wide document
is authoritative for the shape and `data-model.md` for the satisfaction layer's own content.

**Lifecycle classification has exactly one home: `reference/data-architecture.md § Lifecycle
classes`.** `reference/data-model.md` cites it. `CLAUDE.md § Output Versioning` cites it. Neither
restates the definitions.

**The ordering rule — normative, and binding on every slice that edits `reference/data-model.md`.**

> **No slice may make a net insertion of lines above the end of `reference/data-model.md` § *Worked
> example — a per-traveler file*** — the section containing the last externally cited anchor. Edits
> above that point are **replace-in-place only**, at equal line count. New content is **appended below
> the current end of file**. A slice that cannot satisfy this stops and routes to the release hub
> rather than shifting the anchor.

At the pre-release text that section ends at line 290 and the last cited anchor is line 266 of 648.
The rule is stated against the **section** rather than the number because the number is exactly the
thing under threat; the number is given so the rule is checkable today.

**The rule exists because the citations are real, not because any document is unamendable.** Four
anchors are cited fourteen times across three files. Nine of those citations sit in two shell scripts
that `publish-guard.yml` executes on every push to every branch, so an anchor shift is a red release
branch, not a documentation defect. Those nine are converted to section-anchor form by #278, which
already opens both files. The five in `ADR-008` are converted by this ADR's fourth amendment to it —
and that amendment reaches further than those five. `ADR-008` also carried **seven** line anchors into
`agents/00-enrichment.md` and **four** into `agents/06-validator.md`, files this release edits and
which no ordering rule protects, so **all twenty of its anchor tokens are converted in one act** and
the document is left with one citation convention rather than two.

### 2. Entity identity — one rule, applied once per entity

> An entity takes a **surrogate key** when the **engine creates the entity record** and every natural
> candidate is a **mutable display string**. It takes a **natural key** when the entity's identity
> **originates outside the engine** *and* the natural candidate is **already the token the operator
> types** — the directory name, the file name, the heading, or the link target.

Two limbs. Both must hold for the natural branch. The rule is applied at the **entity** level, once.

**The assignment — ten entities, five and five.**

| Key | Entities |
|---|---|
| **Surrogate** | Event (`evt-<token>`), Venue (`ven-<token>`), Need (traveler-scoped), Desire (traveler-scoped), Leg |
| **Natural** | Trip (directory slug), Traveler (normalized name), Constraint (constraint name), Day (ISO date), Origin (origin letter) |

That the rule splits the set rather than answering one way for everything is the evidence that it is a
rule.

**2.1 — The Event ID is preserved, and it is the rule's validation case.** The hub *creates* the event
record on first placement, so limb 1 holds for the surrogate branch; every natural candidate — venue
name plus day, display title — is mutable, and resequencing routinely changes the day, so limb 2
fails. The rule therefore **yields the opaque, day-independent `evt-<token>` the engine already
mints.** It was derived to explain this decision, not to override it. The format, the four statuses
and the day-independence are unchanged by this ADR.

**2.2 — Traveler takes a natural key, and its normalization is adopted verbatim from running code.** A
person's identity originates outside the engine, and the name is *already* the filename, *already* the
`## <Name>` heading, *already* the `trip-context.md § Group` roster entry.

> **Canonical traveler key** = the `## <Name>` heading text, lowercased, with every character outside
> `[a-z0-9]` removed — the rule executing in `scripts/publish-trip-site.sh`, function
> `nonpublishable_values` (`key = tolower(nm); gsub(/[^a-z0-9]/, "", key)`). **Uniqueness is asserted
> over this key**, never over the display name.
>
> **Filename correspondence.** The stem of `travelers/<file>.md`, put through the same normalization,
> MUST equal the entry's traveler key. `.claude/commands/trip-new.md` § *Travelers — count and names*
> already derives the filename in the forward direction; this rule **closes that derivation in the
> reverse direction and does not author a second one.**
>
> **Two travelers whose keys collide are a hard stop at intake, never a silent merge.** The operator
> disambiguates the display name — `Sam B.` — which changes the key. The engine never mints a suffix:
> a minted suffix is a surrogate key wearing a natural key's clothes, and it would break the filename
> correspondence above.
>
> **Reserved keys are part of the schema.** The guard treats the normalized key `updatesignals` as a
> structural section rather than a person (the reserved-key branch of `nonpublishable_values`, which
> sets the live, third-party and entry flags to zero and skips the entry; the list itself is the
> top-level `_GUARD_RESERVED_KEYS`). A traveler whose normalized name lands on a reserved
> key is therefore **silently dropped from the non-publishable class — a fail-open inside a
> fail-closed guard.** The schema MUST carry the reserved-key list and intake MUST reject a collision
> with it.

**2.3 — Venue takes a surrogate key, and the evidence forces it.** The venue *record* is created by a
research spoke, so limb 1 holds for the surrogate branch. Limb 2 fails decisively: one venue carries
three different name strings across three artifacts in this repository's own worked example — a
compound H3 display heading with a file-scoped ordinal, a short name in the link reference, and a
third spelling inside a maps URL query. A second witness carries a fourth pattern.

**A third witness sits inside a single artifact, and it is exactly the case #156 says no name-keyed
rule can reach.** In the same worked example, `examples/tokyo-2026/outputs/links-reference.md` carries
one venue in **two separate rows under two different display names**, on a **byte-identical maps
URL**. The URL is the only field the two rows agree on, and a URL is not a declared key of anything.
**The fixture is deliberately left unrepaired.** It is a frozen worked example, and it is recorded
here as *evidence that the identity rule is needed* rather than as a defect to fix — repairing it
would delete the witness. It is also the intra-file shape: no cross-spoke join rule is even in play,
because both rows are in one file written by one writer.

> **Canonical venue key** = `ven-<token>`, opaque, **minted by the hub inside
> `agents/05-hub-planner.md` § *Pre-Work: Build Reference Artifacts First*, at first enumeration of
> the venue set — before it writes either reference file.** The mint point is stated against the
> enumeration rather than against an artifact for a measured reason: Pre-Work builds
> `links-reference.md` **first** and `venue-matrix.md` **second**
> (§ *Step 1 — links-reference.md*, then § *Step 2 — venue-matrix.md*), so
> minting at the matrix would leave the link file — the one-URL-per-venue SSOT that `ADR-005`'s
> location invariant resolves against — keyless at the moment it is written. Minting before Step 1
> gives both reference files the key on their first write, and carries the same opacity guarantee the
> Event ID already has, so the engine gains one identity convention rather than two.
>
> **The display name is a body value, not a key.** Every artifact keeps the display string its readers
> need. The key is what the two-appearance cap, the one-URL-per-venue rule in `links-reference.md`,
> and `ADR-005`'s location invariant all resolve against.
>
> **The entry ordinal is not a key and must not become one.** A file-scoped ordinal is structurally
> incompatible with an `accumulate-append` lifecycle: a second dated section either restarts or
> continues the numbering, and neither is stable.
>
> **The entry selector is an explicit marker, never a heading level.** In the worked example the
> entry-bearing file carries 51 H3 headings and 47 entries — four H3s are prose sections.

**2.4 — Constraint keeps its natural key, which preserves the `Applies to` link syntax.**
`<Section> → "<Constraint name>"` is already the link form, and the operator already types the
constraint name as its own heading, so the heading is already the link target. **No change to
`Applies to` is required by this ADR** — which is what keeps `ADR-008`'s citation of that rule
semantically true.

**2.5 — #156's disposition follows from this rule and is not decided separately.** #156's collision 3
is intra-spoke: two entries in one file naming one place. Its body states that no name-keyed rule can
reach it, and lists a canonical opaque venue identity as the first option worth weighing. **Decision
2.3 is that option.** The surrogate venue key resolves collision 3 by construction — both entries
resolve to one `ven-<token>` — and it reaches the food × nightlife pair #156 names as the likeliest
future collision on the same footing, because the key is spoke-independent. The third witness recorded
in 2.3 is the same shape observed a second time, in a different artifact class, and it is the reason
this disposition is recorded as evidence-backed rather than as a judgement call.

**#156's second criterion is also discharged, and it is a real change:** the two-appearance cap counts
**rows** today. Once a venue has a key, the cap counts **places**. That inversion must be stated
wherever the cap is defined — the definition site is `CLAUDE.md § Key Rules → Venue deduplication`;
the four agent prompts and the fixtures that repeat it are usages, not definitions.

### 3. Serialization — validated frontmatter, prose body, and the test that decides

Facts move into YAML frontmatter. Narrative stays in the body. The boundary is a test, not a list.

> A value belongs in **frontmatter** if and only if **all three** answer *yes*:
> 1. **Closed or referential?** Is it drawn from a closed enum, an identifier, a date, a number, a
>    boolean, or a reference to another entity's key?
> 2. **Byte-identical under independent authorship?** Would two correct writers, given the same
>    inputs, produce the same characters?
> 3. **Does a consumer branch on it?** Does some agent, script or the site build take a *different
>    action* depending on this value?
>
> Any *no* ⇒ **the value stays in the body.**

**Question 2 is what protects output quality, and it does so structurally rather than by reminder.**
Reasoning, caveats, judgment and voice fail it by construction — two good writers never phrase a
caveat identically — so no correct application of the test can pull narrative into a field. The
failure this decision exists to prevent is the slow migration of prose into fields, and a test that
*cannot* do it is a stronger guarantee than a rule that says not to.

**A model attribute is not automatically a frontmatter field.** The test decides field placement; the
entity model decides what an entity *has*. A Venue's display name is a key attribute of the Venue and
**fails question 2**, so it lives in the body while the key lives in the marker. Any later slice that
reads "key attribute" as "frontmatter field" is reading the model, not this test.

**No double home.** A value that lives in frontmatter is never restated in the body; the body cites
it. This is the existing *link, don't copy — one source per fact* rule extended to the serialization
axis. **One exception is declared, in Decision 5.**

**Universal frontmatter — every in-model class:**

```yaml
---
artifact: <class-name>              # closed enum, one value per artifact class
schema-version: <integer>           # monotonic per class; see Decision 6
trip: <trip-slug>                   # natural key of the owning Trip
writer: <writer-id>                 # exactly one
lifecycle: <accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output>
provenance: <human|enrich|derived|operator-provided|third-party|researched>
publish: <bound|internal|internal-hard|output>
generated: <YYYY-MM-DD>             # omitted on human-authored classes
---
```

Per-class fields extend this set; **no class removes a universal field.** Two classes carry a declared
exception: `satisfaction-metrics.md`, whose `writer` is a two-value section-owned list and whose
frontmatter partition is total and disjoint by construction — every universal field is written by the
creating writer and never re-written by the other; and `trip-context.md`, whose `writer` is the
sentinel `block-owned`, meaning *see `CLAUDE.md § Write ownership`* — it is not a writer id and no
tool resolves it to one.

**Three body rules, and only three, because over-structuring is the named risk.** Every class keeps
its H1 and its existing body structure — frontmatter is prepended and nothing existing moves.
Entry-bearing classes carry an explicit entry marker holding the entity key and nothing else, because
heading level is not a reliable selector. And **the degenerate case is part of every schema**: a class
defines the shape of an entry with no source, so a profile-less traveler reads as *unknown* with
declared-absent values rather than as an absent label a consumer must infer from.

**`trip-log.md` is in the artifact model and out of the entity model.** It takes frontmatter so
tooling can find and version it; **its body is never schema-constrained.** It is the narrative
register, and constraining its prose would be the exact failure Decision 3 exists to prevent.

### 4. Publishability — an artifact class and a field class, composed by union

Publishability is declared at **two granularities**, and they compose by **union, never by override**.

**4.1 — Artifact class,** the `publish:` field, a closed four-value enum. **`bound`** — the site build
reads it; exactly the five artifacts named in `reference/site-layout-spec.md § 9.1`, which remains the
authority while this field is its machine-readable projection, and the schema asserts the two agree.
**`internal`** — never rendered. **`internal-hard`** — never rendered *and* carrying values that must
not reach a rendered page **in any form, including anonymized**, per `ADR-006`. **`output`** — the
render itself: a sink, never a source.

**4.2 — Field class.** Each schema marks each field `publishable` (the default) or `non-publishable`.
`non-publishable` is **inherited** by every artifact the field is carried into, which is what makes a
`Passport` value non-publishable in the per-traveler profile *and* in the derived model from one
declaration.

**4.3 — The class is computed, never enumerated.**

> **non-publishable class = { every value of a field declared `non-publishable` } ∪ { every value of
> an entry whose `provenance` is `third-party` }**

Field-scoped union entry-scoped — the union the guard already implements, now sourced from the schema
instead of from two literals in shell. This is the seam `ADR-008` reserved: its `nonpublishable_values`
is re-keyed to evaluate this expression, and it **must not retain a `Passport`-plus-`[THIRD-PARTY]`
literal pair**.

**4.4 — The re-key must preserve every fail-closed path. All five, without exception.** A missing,
unreadable or empty model → UNDETERMINED, because an empty read is not an empty class. A per-traveler
profile newer than the derived model → UNDETERMINED, because the projection has not absorbed the
source. Zero `## <Name>` entries parsed → UNDETERMINED, because format drift is not an empty class. An
orphaned `[THIRD-PARTY]` mark that resolves to no record → UNDETERMINED, because an unresolved
presence is not zero either. An unsupported supersession → UNDETERMINED, because a provenance change
with no profile behind it is indistinguishable from the bad merge the enrichment contract forbids by
name.

The distinction those five protect is `ADR-008`'s: a parsed-and-empty class is a **measurement** and
publishes; an unrecognized or stale file is a **degradation** and aborts. A re-key that collapsed them
would make a broken parser indistinguishable from a trip with nothing to hide.

**4.5 — What this does not fix, stated plainly.** Keying the guard to a declared attribute makes the
class **sourced**, not **complete**. A value the model never captured, and a value the hub reworded on
its way into the itinerary, remain out of reach: paraphrase is a judgement no string match can make,
and `ADR-008` already records it, along with entity-encoding and mid-word tag splitting, as missed
transforms. **This ADR makes no claim otherwise, and the downstream slice's acceptance criteria must
not either.** The layered model in `ADR-008` stands unchanged: agent judgement, then this guard, then
the structural attribute — and shipping the third does not discharge the first.

### 5. Provenance — a frontmatter declaration over a retained inline marker

**`provenance:` is declared in frontmatter**, as a closed enum:
`human | enrich | derived | operator-provided | third-party | researched` — lowercase-hyphenated,
matching the repo's existing enum-value convention.

**The inline bracket marks are RETAINED as the per-value rendered marker.** `[THIRD-PARTY]`,
`[DERIVED]`, `[ENRICH]` and `[OPERATOR-PROVIDED]` are the observed vocabulary and they are
**load-bearing in CI**: `scripts/test-publish-guard.sh` carries **30** `[THIRD-PARTY]` and **28**
`[DERIVED]` assertions, and `publish-guard.yml` runs it on every push to every branch. Removing the
marks would red-line the release branch on the commit that landed the change — and, more importantly,
the enrichment contract requires the mark on *every value*, and names mark-stripping as a known agent
error that *silently strips the key the publication guard depends on*. The value-level mark is the
guard's backstop against exactly that.

**The declared exception to the no-double-home rule, stated once, here.** `provenance:` and the inline
marks are **not two homes for one fact — they are two granularities of one fact.** The frontmatter
field declares provenance for the **artifact or entry**; the bracket mark carries it for the
**individual value**. Neither can be derived from the other: an entry-level declaration cannot say
which of its values a later agent added second-hand, and a value-level mark cannot survive an agent
that strips it. **The schema asserts that the two correspond**, and a mark that resolves to no
declaration is an UNDETERMINED under Decision 4.4, not a silent pass.

### 6. Schema evolution — a monotonic integer, and one tolerant-read rule with a write-stop

**6.1 — The field.** `schema-version: <integer>`, monotonic, **per artifact class**, starting at `1`.
Not semver: there is no external publisher, the only consumers are agents and scripts inside one
repository, and an integer removes the `1.2 < 1.10` ordering-bug class entirely. It matches the
engine's existing bare-integer artifact versioning. The field is greenfield — measured zero
occurrences of `schema-version`, `schema_version`, `schemaVersion`, `artifact-version`,
`artifact_version` and `spec_version` across all 68 tracked files.

**6.2 — Tolerant read. One rule, stated once, cited by every reader, restated by none.**

> **Tolerant read.** A reader that encounters an artifact whose `schema-version` is:
> - **absent** → reads it as **version 0 (pre-migration)** and parses the body exactly as it did
>   before this architecture existed;
> - **lower than the reader's own** → reads the fields that version defined, and treats every later
>   field as **declared-absent** — never as a default value;
> - **higher than the reader's own** → reads the body, reports the artifact as newer-than-reader, and
>   **continues**.
>
> **A reader never fails on a version it does not recognize.**
>
> **The one hard stop: a reader MUST NOT WRITE an artifact whose `schema-version` is higher than its
> own.** It reports and declines.

**The write-stop is the load-bearing half.** Without it an un-migrated agent silently downgrades a
newer artifact — destroying fields it never knew existed, in a user's git-ignored directory this
repository cannot reach, with no way to detect it and no way to undo it. Every other clause in this
rule is about robustness; this one is about irreversibility.

**6.3 — One statement, cited by all nine agent prompts.** The definition lives in
`reference/data-architecture.md`; each reading agent cites it. The citation form is the one
`reference/data-model.md § Presence` already uses — *"This rule is stated here once; the scheduler, hub
and validator cite it and do not redefine it."* The alternative — a per-agent obligation — was rejected
because restatements drift, and this repository has already resolved the same question twice in the
same document.

**The reader set is stated structurally rather than as a count**, because a count of it is not
reproducible: one agent writes the derived model, six declare it as an input, two carry no `## Input`
section at all, and one references it nowhere — which is the open transport-agent gap tracked
separately. **The obligation is on every agent prompt that reads any versioned artifact**, and the
citation site is that prompt's input declaration where it has one, and its equivalent where it does
not.

**6.4 — The gate's skip predicate is this rule, not a second one.** *Absent version ⇒ version 0* is
exactly what lets the CI schema gate **skip an artifact carrying no `schema-version`** while **failing
closed on one that declares a version and violates its schema**. The gate evaluates this rule; it does
not invent another.

**6.5 — When the version bumps.** A change that only **adds an optional field** does not bump it —
readers already treat unknown fields as absent. A change that **adds a required field, removes a
field, narrows an enum, or changes a field's meaning** bumps it by one, and the changing slice states
the migration for version *n−1* instances.

### 7. Reversibility and confidence

Stated per decision, because the epic's own framing requires it and because the tiers genuinely
differ.

| # | Decision | In-repo reversibility | Reversibility for a migrated user trip | Confidence |
|---|---|---|---|---|
| 1 | Document topology | **CHEAP** before downstream slices cite it — two documents, one PR, one revert. **MODERATE** afterwards | n/a — touches no user artifact | HIGH |
| 2 | Entity identity | **MODERATE** — the rule is prose; the keys it mints are not | **IRREVERSIBLE** — a minted `ven-<token>` in a user's working directory cannot be re-keyed from here | HIGH |
| 3 | Serialization | **MODERATE** | **EXPENSIVE** — every migrated artifact embodies the split; unwinding it is a rewrite of the user's own files | HIGH |
| 4 | Publishability | **MODERATE** — a function-body re-key behind an unchanged 0/1/2 contract | n/a for the attribute; **but the failure consequence is IRREVERSIBLE** — a published value persists in third-party caches and clones after takedown | HIGH |
| 5 | Provenance | **CHEAP** — the frontmatter field is additive and the marks are retained, so nothing existing is removed | CHEAP | HIGH |
| 6 | Schema evolution | **CHEAP** | **IRREVERSIBLE** — the write-stop exists precisely because the un-migrated-writer case cannot be undone | HIGH |

Decisions 2, 3 and 6 are the expensive ones, exactly as the driving issue anticipated. Decision 4 is
the one whose *decision* is cheap and whose *error* is not, and that asymmetry is why its five
fail-closed paths are non-negotiable.

## Consequences

**Positive**

- **The venue-identity problem is settled rather than deferred.** #156's collision 3 was out of reach
  of every name-keyed rule; a hub-minted opaque key reaches it by construction, and reaches the food ×
  nightlife pair on the same footing.
- **The non-publication class gains a source.** `ADR-008` records that its class-definition problem
  *"belongs to #278"*; Decision 4.3 is the definition it was waiting for, and the guard consumes it
  through the seam that ADR already reserved.
- **The engine gains one identity convention, not two.** Venue keys are minted with the same opacity
  guarantee the Event ID already carries.
- **Narrative is protected by construction.** The boundary test's second question cannot be satisfied
  by prose, so the failure mode the epic names — migrating judgment into fields — is structurally
  unavailable rather than discouraged.
- **A fail-open in a fail-closed guard is closed.** The `updatesignals` reserved-key collision silently
  dropped a traveler from the non-publishable class; the reserved-key list makes it a hard stop at
  intake.
- **The mover-set stays empty.** The topology adds a file and appends to another. Nothing moves,
  nothing is renamed, nothing is deleted.

**Trade-offs, and two are real costs**

- **Eight slices now edit `reference/data-model.md` under an ordering constraint they did not have.**
  Replace-in-place above the worked-example section, append below. The constraint is mechanical, but it
  is a real restriction on eight concurrent editors and a slice that cannot satisfy it must stop.
- **Provenance is carried at two granularities, permanently.** The frontmatter declaration does not
  replace the inline marks and is not intended to. That is a deliberate exception to the one-home rule,
  and it is a maintenance surface: the schema must assert correspondence, and a future slice that
  "cleans up" the marks would break 58 CI assertions and remove the guard's only defence against
  value-level mark stripping.
- **Two entities are keyed on values a human types.** Trip and Traveler take natural keys, so a rename
  is a re-key. For Traveler this is bounded by the intake hard-stop; for Trip it is the directory name,
  which the engine already treats as identity.
- **The schema constrains frontmatter and declared entry markers only.** It never constrains narrative
  body content. A class can therefore be schema-valid and substantively poor; that is the line this ADR
  deliberately does not cross.

**What this ADR does NOT decide**

- **No metric formulas, scoring, weighting, ranking or optimization.** Inherited unchanged from
  `reference/data-model.md`; this ADR does not relax that boundary.
- **No control flow.** Who runs when, and in what order, belongs to the control-flow contract. This is
  the data contract.
- **No claim over `.claude/commands/*.md` frontmatter.** Those files carry an upstream schema this
  repository does not own and cannot change. The artifact schema set does not claim them and the CI
  gate does not validate them.
- **No prose validation**, and no change to the `Applies to` link syntax, the Event ID format, the four
  event statuses, or the presence predicate's semantics. Existing precedents are preserved; only their
  *declaration* moves into frontmatter.
- **Not the publish path's completeness.** Paraphrase and the two encoding transforms remain out of
  reach; `ADR-008`'s three-layer model stands.
- **No migration.** This ADR records the decisions; the migration slices execute them.
- **No repair of the worked-example fixture.** The third venue-identity witness recorded in Decision
  2.3 is left in `examples/tokyo-2026/` exactly as it stands. The example set is byte-frozen, and the
  witness is the evidence — a repaired fixture would remove the only in-repo demonstration that a
  name-keyed rule cannot reach the intra-file case.
- **`reference/adr/README.md § Convention` under-described its own corpus, and the reconciliation
  landed in this release rather than being left to be rediscovered.** When this ADR was written the
  Convention's `Sections:` line named six — Status · Context · Decision drivers · Options considered ·
  Decision · Consequences — while `## References` appeared in **6 of the 8** ADRs then existing and a
  `## Follow-on build slices` section in **4 of 8**, and the Convention named neither. It was also
  silent on **amendment**: it described only supersession, a path no ADR in this repository has ever
  used, while the path five amendments across two ADRs had actually taken was undocumented. That
  silence is what produced the falsified immutability premise twice in this release. The Convention
  now names `References` as part of the expected spine, states that the list is not a closed set, and
  carries an explicit amendment rule covering both renderings the corpus uses. This ADR's `##
  References` section is therefore **conformant**, not a recorded divergence.
- **Out-of-model file classes are named and excluded, not modelled** — secret material, the publish
  control file, third-party tool state inside `outputs/`, the publish staging clone, and two per-trip
  file classes with zero references anywhere in the tracked corpus. The last two warrant their own
  intake rather than a silent adoption.

## References

- The decisions recorded here and the specification that settled them: #275 and #274, under epic #273.
  The venue-identity disposition: #156.
- The model this ADR is authoritative over, and which is authoritative for the shape:
  `reference/data-architecture.md`. Its satisfaction-layer specialization: `reference/data-model.md`.
- The publish-path guard whose class source Decision 4.3 replaces, its five fail-closed paths, and its
  coverage boundary: `reference/adr/ADR-008-publish-content-guard.md`. This ADR amends that document's
  citation form (fourth amendment) across all twenty of its line-anchor tokens; it re-opens none of its
  decisions.
- The consent model that makes a third-party value non-publishable in attributed *or* anonymized form:
  `reference/adr/ADR-006-third-party-data-capture.md`; the PII precedent it extends:
  `reference/adr/ADR-004-contact-emergency-privacy.md`.
- The location invariant that resolves against the venue key: `reference/adr/ADR-005-location-invariant.md`.
- The command-surface bound on the plaintext publish limb: `reference/adr/ADR-007-command-entry-point.md` § 2.
- Identity conventions adopted verbatim from running code: the traveler-name normalization and the
  reserved-key branch in `scripts/publish-trip-site.sh`; the filename derivation in
  `.claude/commands/trip-new.md` § *Travelers — count and names*; the opaque day-independent Event ID in
  `CLAUDE.md § Key Rules`; the reference-file build order that fixes the venue-key mint point in
  `agents/05-hub-planner.md` § *Pre-Work: Build Reference Artifacts First* — § *Step 1 —
  links-reference.md*, then § *Step 2 — venue-matrix.md*.
- The venue-identity witnesses this ADR reads as evidence, left frozen:
  `examples/tokyo-2026/outputs/`.
- The publish-bound artifact set and its intentional exclusions:
  `reference/site-layout-spec.md § 9.1` / § 9.3.
- Write ownership, the venue-deduplication cap, and the output-versioning model this ADR's lifecycle
  classification supersedes as the single home: `CLAUDE.md`.
