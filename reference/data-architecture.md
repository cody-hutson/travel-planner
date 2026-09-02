# Data Architecture — Engine-Wide

The canonical data-architecture document for the **whole engine**. It defines the closed set of
per-trip artifact classes, the entities behind them, how identity is assigned, what is serialized as
structure versus what stays as prose, which values may reach a published page, how each artifact
behaves across re-runs, and how a schema change is versioned and read tolerantly.

`reference/data-model.md` remains the **satisfaction-layer specialization** of this document — the
deep model for the four satisfaction artifacts and the reconciliation rules around them. Where the
two overlap, **this document is authoritative for the shape and that one is authoritative for the
satisfaction layer's own content.**

This document governs the data **contract** only. It defines no metric formula, no scoring, no
optimization, and no control flow — see *What This Document Does Not Define*.

---

## What This Document Governs

| Dimension | Where it is fixed here |
|---|---|
| Which artifacts exist, and which are deliberately outside the model | § 1 The Artifact Classes |
| The entities the engine manipulates, and their relationships | § 2 The Entity Model |
| Which entities take surrogate keys and which take natural keys | § 3 Identity Conventions |
| What goes in frontmatter, what stays in the body | § 4 Serialization |
| What may reach a published page | § 5 Publishability |
| How each artifact behaves across re-runs — **the single home for the class tokens and their definitions**, with `CLAUDE.md` § *Output Versioning* retained as a live input (§ 6) | § 6 Lifecycle Classes |
| How a schema change is versioned and read tolerantly | § 7 Schema Versioning |
| Which model element prevents which class of contract defect | § 8 Contracts, Granularity, Enforcement |
| Current state against target state, per class | § 9 Per-Artifact Gap Analysis |
| The order in which migration lands | § 10 Migration Sequence |

---

## 1. The Artifact Classes

The enumeration is **closed at 26**: 20 in-model per-trip artifact classes, and 6 classes explicitly
declared out of the model. Every class has a target state **or** a stated out-of-model disposition.
Declaring a class out is a valid outcome; leaving one unmentioned is not.

**Class identifiers are written `C1` … `C26`** and are used throughout this document to refer to a
row of the enumeration below. `W` = the single writer · `L` = lifecycle class (§ 6) ·
`Prov` = provenance (§ 4.4) · `P` = publishability class (§ 5.1).

### 1.1 In-model — per-trip artifact classes (20)

| C | Class | W (exactly one) | L | Prov | P | Primary entities |
|---|---|---|---|---|---|---|
| 1 | `trip-context.md` | **block-owned** (`CLAUDE.md` § *Write ownership*) | `persist-mutable` | `human` | `bound` | Trip, Constraint, Logistics, Origin |
| 2 | `trip-log.md` | operator, via `/trip-record log` | `accumulate-append` | `human` | `internal` | — (narrative register, § 1.4) |
| 3 | `travelers/<traveler>.md` | human (the traveler) | `persist-mutable` | `human` | `internal` | Traveler, Need, Desire |
| 4 | `outputs/destination-shortlist.md` | destination-ideation | `rebuilt-each-synthesis` | `derived` | `internal` | Destination candidate |
| 5 | `outputs/activities-list.md` | activities | `accumulate-append` | `researched` | `internal` | Venue, Candidate |
| 6 | `outputs/food-list.md` | food | `accumulate-append` | `researched` | `internal` | Venue, Candidate |
| 7 | `outputs/nightlife-list.md` | nightlife | `accumulate-append` | `researched` | `internal` | Venue, Candidate |
| 8 | `outputs/scheduling-framework.md` | scheduling | `accumulate-append` | `researched` | `internal` | Day, Block, Signal |
| 9 | `outputs/transport-brief.md` | transport | `accumulate-append` | `researched` | `internal` | Leg, Signal |
| 10 | `outputs/links-reference.md` | hub | `rebuilt-each-synthesis` | `derived` | **`bound`** | Venue |
| 11 | `outputs/venue-matrix.md` | hub | `rebuilt-each-synthesis` | `derived` | **`bound`** | Venue, Day, Placement |
| 12 | `outputs/traveler-model.md` | enrichment | `rebuilt-each-synthesis` | `derived` | **`internal-hard`** | Traveler, Need, Desire |
| 13 | `outputs/event-status.md` | hub (primary); enrichment seeds; `/trip-record event` | `persist-mutable` | `recorded` | **`bound`** | Event |
| 14 | `outputs/satisfaction-metrics.md` | hub + validator (**section-owned**) | `rebuilt-each-synthesis` | `derived` | **`internal-hard`** | Metric |
| 15 | `outputs/final-itinerary.md` | hub | `versioned` | `derived` | **`bound`** | Day, Event, Venue |
| 16 | `outputs/final-itinerary-v<N>.md` | hub | `versioned` (frozen sibling) | `derived` | `internal` | as C15 |
| 17 | `outputs/validation-report.md` | validator | `rebuilt-each-synthesis` | `derived` | `internal` | Finding |
| 18 | `outputs/<slug>.md` — targeted-research output | the spoke that re-ran | `accumulate-append` | `researched` | `internal` | Venue, Candidate |
| 19 | `outputs/<destination>-travel-site.html` | `site-build` | `output` | `derived` | **`output`** | (render of C1, C10, C11, C13, C15) |
| 20 | `outputs/change-summary.md` | hub | `accumulate-append` | `derived` | `internal` | Venue, Event, Day |

**C17 gains its first declared lifecycle here.** `outputs/validation-report.md` had no lifecycle anywhere in
the corpus. It is `rebuilt-each-synthesis` because a finding against a superseded itinerary is noise,
which is the same reason C14 is rebuilt. This table is that declaration; the default-and-exception
reading in `CLAUDE.md` § *Output Versioning* governs an artifact that is **undeclared**, and after
this document no in-model class is.

### 1.2 Out of model — explicit dispositions (6)

| C | Class | Disposition |
|---|---|---|
| 21 | `engine-learnings.md` (trip root) | **OUT — ungoverned, and that is the finding.** A real per-trip file with no writer, no lifecycle and no schema, and no reference in any tracked file but this row. Declared out of the artifact model; it warrants its own intake — either governed or deliberately declared engine-external. |
| 22 | `outputs/<destination>-<topic>.html` — secondary generated render | **OUT — a second generated render**, with no corpus reference but this row. It obeys the same rule as C19 (a render is a sink, never a source) but it is not the publish target. |
| 23 | `.passphrase` | **OUT — secret material.** Never schema-bearing, never published, never read by an agent. |
| 24 | `.publish-slug` | **OUT — publish control file.** Governed by the publish surface, not by the artifact model. |
| 25 | `outputs/.staticrypt.json` | **OUT — third-party tool state**, created by the encryption step; the engine neither writes nor reads it. **The schema selector must exclude it** — it is the one non-`.md` file that lands inside `outputs/`. |
| 26 | `.publish/` | **OUT — publish staging clone** (it contains its own `.git`). Never traversed by any selector. |

### 1.3 In-repo files carrying no per-trip class

These are worked-example fixtures and emitters, not classes. They are disposed of here so the
enumeration stays closed.

| File | Disposition |
|---|---|
| `examples/tokyo-2026/outputs/casual-dining-family.md` | **IN — an instance of class C18.** `examples/tokyo-2026/README.md` already names its writer as the food agent on a targeted re-run. It is a variant of the research-list class, never an 18th class. |
| `examples/*/README.md` | **OUT — fixture documentation.** Not per-trip artifacts; excluded from the gate selector. |
| `examples/ideation-demo/traveler-leanings.md` | **OUT as a class; IN as a partial fixture instance of C12.** Its own text calls it a minimal stand-in showing the three leaning fields the agent uses — a projection of `outputs/traveler-model.md`. |
| `templates/*.template.md` | **OUT as per-trip artifacts; IN as emitters.** A template is not an instance, but it **must emit a conforming one**: a template's rendered output validates against the schema of the class it seeds — `templates/traveler-intake.template.md` → C3, `templates/trip-context.template.md` → C1. |

### 1.4 `trip-log.md` — in the artifact model, out of the entity model

`trip-log.md` is a class (it takes frontmatter, so tooling can find and version it) whose **body is
never schema-constrained.** It is the narrative register: reasoning, options rejected, and the
conversational context that informs later decisions. Constraining its prose would be exactly the
structure-over-judgment failure this architecture exists to prevent.

---

## 2. The Entity Model

Ten entities. The attributes listed are the identity-bearing and relationship-bearing ones; the full
field set per class lives in that class's own schema.

| Entity | Identity | Key attributes | Relationships (with cardinality) |
|---|---|---|---|
| **Trip** | natural — the directory slug | `slug`, `destination`, `mode`, `lifecycle`, window | Trip 1—N Traveler · 1—N Day · 1—N Constraint · 1—N Origin |
| **Traveler** | **natural — normalized name** (§ 3.2) | `name`, `window-basis`, presence facets | Traveler 1—N Need · 1—N Desire · N—1 Origin · N—M Day (presence) |
| **Need** | surrogate, traveler-scoped | `category` (closed enum), `specific`, `applies-to` | Need N—1 Traveler · **N—1 Constraint** (the `Applies to` link) |
| **Desire** | surrogate, traveler-scoped | `priority-tier`, `recurrence`, `theme-tags` | Desire N—1 Traveler · N—M Desire (overlap signal) |
| **Constraint** | **natural — the constraint name** | `name`, `description`, `applies-to[]`, `time-blocks` | Constraint 1—N Need · N—M Traveler |
| **Event** | **surrogate — `evt-<token>`, opaque, day-independent** | `status` (4-enum), `requires-booking` | Event N—1 Day · N—1 Venue · N—0..1 Event (`option` → primary) |
| **Venue** | **surrogate — `ven-<token>`** (§ 3.3) | `display-name`, `canonical-url`, `neighborhood` | Venue 1—N Event · N—M Day (at most 2 appearances) |
| **Day** | natural — ISO date | `date`, `day-index`, `energy` | Day N—1 Trip · 1—N Event · N—M Traveler (presence) |
| **Leg** | surrogate | `mode`, `from`, `to`, `duration` | Leg N—1 Origin · N—1 Day |
| **Origin** | natural — the origin letter (`Origin A` …) | `letter`, `departure-point` | **Origin 1—N Traveler — cardinality is O(origins), not O(travelers)** |

The Origin row is stated because `reference/data-model.md` already fixes that cardinality: `## Logistics`
carries one origin block per **additional** departure origin, never one per traveler. A schema that
modelled one origin per traveler would silently contradict it.

---

## 3. Identity Conventions — the stated rule

Identity is decided **by a rule applied once per entity**, never case-by-case per artifact.

> An entity takes a **surrogate key** when the **engine creates the entity record** and every natural
> candidate is a **mutable display string**. It takes a **natural key** when the entity's identity
> **originates outside the engine** and the natural candidate is **already the token the operator
> types** — the directory name, the file name, the heading, or the link target.

Two limbs; **both** must hold for the natural branch.

### 3.1 Why the Event precedent is correct — preserved, not re-decided

The hub *creates* the event record on first placement, so limb 1 holds for the engine-created branch.
Every natural candidate — the venue name plus the day, the display title — is mutable, and
resequencing routinely changes the day, so limb 2 fails. The rule therefore yields
**`evt-<token>`, opaque and day-independent** — exactly what the engine already mints. This is the
rule's validation case: it was derived to explain the existing decision, not to override it.

### 3.2 Traveler — natural key

A person's identity originates outside the engine (limb 1), and the name is *already* the filename
`travelers/<name>.md`, *already* the `## <Name>` heading in `outputs/traveler-model.md`, and
*already* the roster entry in `trip-context.md` § *Group* (limb 2).

**The normalization is not invented here — it is the rule the publish guard already executes**
(`scripts/publish-trip-site.sh`, the derived-model entry parser):

> **Canonical traveler key** = the `## <Name>` heading text, lowercased, with every non-`[a-z0-9]`
> character removed. **Uniqueness is asserted over this key**, never over the display name.
>
> **Filename correspondence.** The stem of `travelers/<file>.md`, put through the same
> normalization, MUST equal the entry's traveler key. `.claude/commands/trip-new.md`
> § *Travelers — count and names* already derives the filename from the display name; this rule
> **cites and closes that derivation in the reverse direction** rather than authoring a second one.
>
> **The same-name case is specified as a hard stop at intake, and the intake half has not
> shipped.** The rule is that the operator disambiguates the display name, which changes the key,
> and the engine never mints a suffix: a minted suffix is a surrogate key wearing a natural key's
> clothes, and it would break the correspondence above. **No intake surface enforces this today.**
> `.claude/commands/trip-record.md` selects edit-over-create on a file-existence probe with no
> collision check, so two travelers whose display names normalize to one key share a file and the
> second overwrites the first, silently — in files the model itself describes as carrying real
> personal detail. That behaviour predates this release and is unchanged by it; what this section
> adds is the rule the intake half will hold, not a control that holds it now.
>
> **The empty key is a decided case, not an assumed one.** A display name carrying no `[a-z0-9]`
> character normalizes to the empty string, where the uniqueness assertion above has nothing to
> assert over and no filename exists for the key to correspond to. That degenerate point is a hard
> stop, decided as case **C2** in `reference/data-model.md` § *The four cases the correspondence
> does not reach*. It is cited here rather than re-decided, and it is what makes the assertion
> above total.
>
> **Reserved-key hazard.** The publish guard treats **two** normalized keys — `updatesignals` and
> `desireoverlap` — as structural sections rather than as people, reading them from a list rather
> than as a literal. The list the schema carries is declared in `reference/data-model.md`
> § *Reserved keys*, and intake MUST reject a traveler whose normalized key lands on it. **The
> intake half has not shipped**: such a traveler is still silently dropped from the non-publishable
> class — a fail-open inside a fail-closed guard, and the guard-side half of it is pinned open by
> cases `L11a`, `L11b` and `L11d` in `scripts/test-publish-guard.sh`.
>
> **The display name is a body value, never a frontmatter value.** It already has a home in the
> filename and the heading, so § 4.3's no-double-home rule bars restating it in frontmatter. This
> is binding on the intake template: prepending a frontmatter fence must never relocate a person's
> name into the fence, and any template instruction that says to put the name "at the very top"
> means the title line, not the fence.

### 3.3 Venue — surrogate key, forced by measured evidence

The venue *record* is created by a research spoke (limb 1). Limb 2 fails decisively: one venue
carries three different name strings across three in-repo artifacts — a compound display heading in
the food list, a plain name in the link reference, and a query-encoded form in the maps URL — and a
second venue witnesses the same divergence.

> **Canonical venue key** = `ven-<token>`, opaque, **minted by the hub at its first enumeration of
> the venue set — before it writes either reference file** (`agents/05-hub-planner.md`
> § *Pre-Work: Build Reference Artifacts First*). The mint point is fixed against the enumeration
> rather than against an artifact because Pre-Work writes `outputs/links-reference.md` **first** and
> `outputs/venue-matrix.md` **second**: minting at the matrix would leave the link file — the
> one-URL-per-venue SSOT that `reference/adr/ADR-005-location-invariant.md`'s location invariant
> resolves against — keyless at the moment it is written. `ADR-009` Decision 2.3 is the decision and
> this is its shape (§ 12). Minting before the first write gives both reference files the key on
> their first write, and carries the same opacity guarantee the Event ID already has, so the engine
> gains one identity convention rather than two.
>
> **The display name is a field, not a key.** Every artifact keeps the display string its readers
> need; the key is what the venue matrix's two-appearance cap, the link reference's one-URL-per-venue
> rule, and the location invariant in `reference/adr/ADR-005-location-invariant.md` all resolve
> against.
>
> **The entry ordinal is not a key and must not become one.** The research artifacts number their
> entries, and those numbers are unique *today* — but those files are `accumulate-append`: a second
> dated section either restarts or continues the numbering, and neither is stable. **A file-scoped
> ordinal is structurally incompatible with an accumulate-append lifecycle.**
>
> **Not every heading is an entry.** The food list carries more third-level headings than entries,
> because several are prose sections. **The entry selector must be an explicit marker, never a
> heading level** — see § 4.5 rule 2.

**How a key reaches an entry written before the mint.** The mint point above opens a window: the
research spokes write their entry markers before the hub has enumerated, so on a first pass every
one of those markers reads `venue: unminted` — the declared absence § 8 records for these classes.
**The spoke resolves its own marker, in place and one-way, on its next pass:** `unminted` →
`ven-<token>`. The full statement belongs to the prompts that perform it — `agents/01-activities.md`,
`agents/02-food.md` and `agents/07-nightlife.md`, each § *Output Format*, with the hub's half in
`agents/05-hub-planner.md` § *Step 1 — links-reference.md*. It is cited here, not restated.

**The grounding is a distinction this document already draws.** The entry marker is the
entry-scoped member of the class § 4.5 rule 2 defines — a declared machine-readable block carrying
the entity key and nothing else — and § 7.6 already separates that class from accumulated prose: a
frontmatter block is *upgraded in place* on the next write, while **body entries are never
rewritten**. Resolving a marker is the first of those two acts performed at entry scope, by the
file's single writer. **One writer per file is preserved and the append guarantee is untouched:**
the hub never reaches into a spoke's file, and the entry's heading, labelled lines and prose stand
exactly as written.

**What the window costs, stated rather than deferred.** Resolution is **one pass late**. `unminted`
is a **converging** state, not an instantaneous one — and on a single-pass trip that never re-runs a
spoke it never converges, so the marker stays `unminted` permanently. **The key is therefore a
convergence optimisation and never the join basis: the hub joins two mentions to one place by the
identity procedure at every mint**, not only at the first. That procedure is five ordered rungs in
`agents/05-hub-planner.md` § *Step 1 — links-reference.md*, stopped at the first rung that decides
and biased toward splitting an uncertain pair. **The warrant for that bias is visibility, and it is
stated once, there** — a wrong split leaves two adjacent rows a reader can see, while a merged place
is simply absent. It is *not* that a wrong split is the safe direction for the cap: the cap counts
appearances per key, so a split lowers both counts and can let a real violation through. That
section carries the full statement and the cost; this one cites it and does not restate it.
Downstream the same asymmetry is honoured rather than
worked around: `agents/06-validator.md` § *What You Audit* counts a still-`unminted` entry as its own
venue, so the two-appearance cap over-counts rather than passing silently on a merge nobody made.

**Why the two alternatives were worse.** Having the hub back-fill the spokes' markers would give
those files a second writer, against § 1.1's `W (exactly one)` column, which every class is
declared on. A
deterministic key each spoke could derive for itself would close the window entirely, but it takes
the display name as input — name-keying wearing a hash — and the divergence measured above, one
venue carrying three name strings across three artifacts, is exactly what the surrogate key exists to
escape. The window is the price of a key no display string can perturb, and it is paid once per
entry.

### 3.4 The full assignment

**Surrogate:** Event, Venue, Need, Desire, Leg.
**Natural:** Trip (slug), Traveler (normalized name), Constraint (name), Day (ISO date), Origin (letter).

The rule splits the entity set five/five. It does not rubber-stamp one answer, and it reproduces
every precedent the engine already runs on.

**Constraint keeps its natural key, which preserves the `Applies to` link syntax.**
`<Section> → "<Constraint name>"` is already the link form, and the constraint name is already the
heading an operator types. **No change to `Applies to` is required by this document.**

---

## 4. Serialization — frontmatter and the frontmatter/body boundary

### 4.1 Format

YAML frontmatter, opened and closed by `---` on its own line, as the first bytes of the file. Keys
are **kebab-case** — the only frontmatter that exists in this repo is kebab-case, and every file name
in the repo is kebab-case.

### 4.2 The boundary test — a test, not a list

> A value belongs in **frontmatter** if and only if **all three** answer *yes*:
>
> 1. **Closed or referential?** Is it drawn from a closed enum, an identifier, a date, a number, a
>    boolean, or a reference to another entity's key?
> 2. **Byte-identical under independent authorship?** Would two correct writers, given the same
>    inputs, produce the same characters?
> 3. **Does a consumer branch on it?** Does some agent, script, or the site build take a *different
>    action* depending on this value?
>
> Any *no* ⇒ **the value stays in the body.**

**The test protects narrative by construction.** Reasoning, caveats, judgment and voice fail
question 2 — two good writers never phrase a caveat identically — so prose can never be pulled into
frontmatter by a correct application of the test. That is a structural guarantee, not a reminder.

**One stated carve-out, and its reason.** A value that already has a home elsewhere in the file's
own structure — the traveler display name in the H1 and filename (§ 3.2), the trip slug in the
directory name — passes all three questions but is still barred, by § 4.3. The test admits a value
to frontmatter; the no-double-home rule decides whether it already lives somewhere.

### 4.3 The no-double-home rule

A value that lives in frontmatter **is never restated in the body**; the body cites it. And a value
that already lives in a structural position — a filename, a directory name, a heading the identity
rule keys on — **is not copied into frontmatter.** This is `reference/data-model.md`'s existing *link, don't
copy — one source per fact* rule extended to the serialization axis, and it is what keeps a migrated
artifact from acquiring two owners for one fact.

### 4.4 Universal frontmatter — every in-model class (C1–C20)

```yaml
---
artifact: <class-name>              # closed enum, one value per class row in § 1.1
schema-version: <integer>           # monotonic per class; see § 7
trip: <trip-slug>                   # natural key of the owning Trip
writer: <writer-id>                 # exactly one; the W column in § 1.1
lifecycle: <accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output>
provenance: <human|researched|derived|recorded>
publish: <bound|internal|internal-hard|output>
generated: <YYYY-MM-DD>             # omitted on human-authored classes
---
```

Per-class fields extend this set; **no class removes a universal field.** Two classes carry a
declared exception:

- **C14 `outputs/satisfaction-metrics.md`** — `writer` is a two-value **section-owned** list, and no other
  field is writable by both. **The two-value list is a statement about the file's sections, not
  about its frontmatter block: the block has exactly one declared writer, the validator**
  (`reference/data-model.md` § *Write split — section ownership*, the `Frontmatter block` row, and
  `agents/06-validator.md`, which authors and refreshes it). The hub carries the block through its
  own read-merge-write and preserves it byte-for-byte, never authoring it. The frontmatter
  partition is therefore total and disjoint by construction — every universal field has that one
  owner, and none is re-written by the other writer. **Read as *whichever writer created the file*
  this sentence would decide the opposite on a pass where the hub writes its sections first**,
  which is the reading it exists to close.
- **C1 `trip-context.md`** — `writer` is `block-owned`, a sentinel meaning *see `CLAUDE.md`
  § Write ownership*. It is not a writer id and no tool resolves it to one.

**The `W` cell is a bare writer-id wherever the class has exactly one, and prose wherever it names
an ownership arrangement no single id can carry** — a sentinel, a verb, a human author, or several
writers. Every per-class schema types `writer` as a `slug`, so only the first kind round-trips into
a frontmatter block; a single-writer class whose cell reads as prose is a **type disagreement
between this table and that class's own schema**, not a licence the schema grants. That divergence
is also why `scripts/test-artifact-schema.sh` excludes `writer` from its cross-home comparison and
**measures** the excluded cell count instead of omitting it silently (arm `CA7`) — the exclusion is
a recorded property of the data, and it narrows as single-writer cells are regularised.

**C19 carries its declaration in an HTML comment block rather than a YAML fence**, because the file
is HTML. The field set and its meanings are identical.

#### The `provenance` enum

**The vocabulary is seven values across three granularities; the `provenance:` frontmatter key is
artifact-scoped and its enum is the four artifact-level rows.** The field- and entry-scoped rows are
carried by the inline bracket marks, below, and never by the key.

| Value | Granularity | Means |
|---|---|---|
| `human` | artifact | Layer-1 human input, authored by the traveler or the operator. |
| `researched` | artifact | The writing agent's own original **research or analysis**. It **holds independent state** and is **not a regenerable projection** of another artifact: re-running the writer against the same inputs is not guaranteed to reproduce it, and nothing upstream can reconstruct it. |
| `derived` | artifact | A projection of authoritative inputs. It **holds no independent state**, so regenerating it is safe. |
| `recorded` | artifact | **State the engine itself maintains across runs.** Its values are **acts, not findings or projections** — an identity minted, a status transitioned, a booking held — so nothing upstream can reconstruct them and a regeneration would destroy them rather than reproduce them. |
| `enrich` | field | The enrichment agent's rollups into `trip-context.md` — a field-scoped class inside a `human` artifact. |
| `operator-provided` | entry | A value the operator supplied on someone else's behalf. |
| `third-party` | entry | A value describing a person who did not supply it and cannot consent to it. Never published, in attributed **or** anonymized form (`reference/adr/ADR-006-third-party-data-capture.md`). |

**`researched` is added here because the enum had no member for original agent work.** Before it,
the research and analysis artifacts could only be declared `derived` by elimination — and `derived`
is actively wrong for them: it is the corpus's established word for *holds no independent state*,
which is precisely what a research list is not. `enrich` was unavailable, being bound to the
enrichment agent's own rollups.

**Members of `researched`: C5, C6, C7, C8, C9, C18.** The discriminator is the corpus's own
language. Each of those six carries **no** `[DERIVED]` declaration anywhere. By contrast C4 is
tagged `[DERIVED]` and declared to *hold no independent state* by its own writing agent, so it stays
`derived` despite being produced by a research-capable agent — **the classification follows the
declared state property, never the producing agent.**

**Naming `researched` — a stated choice, not a silent one.** `researched` slightly under-describes C8
and C9, whose content is analytic judgment over research rather than research itself. `agent-authored`
would cover the union more literally, but it collides conceptually with `enrich`, which is also agent
authorship. The name `researched` is kept and **the definition above carries the precision** by
saying *research or analysis* in terms. This is a judgment call and is recorded as one.

**The `provenance:` key is artifact-scoped, and the four artifact-level values above are the whole
of its enum.** `enrich`, `operator-provided` and `third-party` are field- and entry-scoped: they mark
values *inside* a mixed artifact, which is a different granularity, and the inline bracket marks are
what carry them. The key admitted all six before this document narrowed it, and three of the six were
**structurally undeclarable through it** — no class row in § 1.1 carries one, and none could, because
a scalar artifact-level key has no way to say *which value* inside the artifact it describes.
Narrowing the key to its own scope loses nothing: § 5.3 composes the two granularities by union, so
what the marks carry is read at the granularity that carries it.

**`recorded` is added here because the enum had no artifact-level member for state the engine
maintains across runs**, and the two halves are one defect from opposite ends: the enum was short a
member it needed *because* three of its slots were spent on a granularity it was never able to
describe. `outputs/event-status.md` was declared `derived` — *holds no independent state, so
regenerating it is safe* — while its own lifecycle is `persist-mutable`, defined at § 6 as *survives
every re-run; synthesis reads it and never regenerates it*. Both cannot be true of one class, and it
is the only class that carried the pair. `derived` was wrong for it for the same reason it was wrong
for the research lists before `researched` existed: it is the corpus's established word for *holds no
independent state*, which is exactly what a booking record is not.

**Members of `recorded`: C13.** The discriminator is the property, not the writer: a class is
`recorded` when its rows are the engine's own **acts** — an `evt-<token>` minted on first placement, a
status moved from `planned` to `locked`, a reservation held — so that regenerating the file would
destroy state no input can reconstruct. That is what `agents/05-hub-planner.md` § *Pre-Work: Build
Reference Artifacts First* means by naming it the one artifact that must outlive a planning pass.

**Naming `recorded` — a stated choice, not a silent one.** `maintained` describes what happens to an
artifact *after* it is written, which is the lifecycle's axis rather than provenance's; using it here
would fuse two axes this document and § 6 deliberately keep apart. `persisted` collides outright with
the `persist-mutable` token. `recorded` takes the participle form the other artifact-level values
already take — `human`, `researched` and `derived` each say how the content came to be — and it is the
corpus's own verb for this artifact, `/trip-record event` being what transitions its rows. **It does
not make `trip-log.md` `recorded`**, and the discriminator is the one the enum already runs on:
provenance follows what **originated** the content, never which verb filed it. The trip log's body is
the operator's own narrative (§ 1.4), so C2 stays `human`; C13's rows are the engine's own acts, so it
is `recorded`. This is a judgment call and is recorded as one.

**What the pair of changes buys, and it is checkable against § 1.1.** Every class still carrying
`derived` now sits in a lifecycle that rebuilds it wholesale — `rebuilt-each-synthesis`, `versioned`
or `output` — which is § 7.6's self-upgrading row exactly. `derived` therefore means what its
definition says of every class that declares it, which it did not before.

**This narrowing does not bump `schema-version`, and the reason is stated rather than assumed.**
§ 7.4 bumps on a narrowed enum because an instance at version *n−1* may no longer validate at *n*.
Here that set is empty for every artifact the engine produced: the three removed values are emitted by
no agent prompt and no template — the artifact-level set any writer emits is `human`, `researched`,
`derived` — so nothing the engine wrote can carry one. Against the values instances actually occupy
the change is a **widening**: everything that validated before validates after, and one further value
becomes available. § 7.4's trigger is an instance that must be migrated, and there is none.

**The four existing inline bracket marks are retained** as the per-value rendered marker; the
`provenance` key is the artifact-level **declaration**. They are different granularities,
not a duplicate home — and the narrowing above is what makes that split exact rather than merely
stated. **That they correspond is a declared gap:** the word `correspond` occurs
nowhere in `reference/schemas/`, and no enforcement file reads an inline mark against a
`provenance:` value. **No new inline mark is minted for `researched` or for `recorded`**: the existing
marks exist to mark individual values inside a mixed artifact, whereas a research list is researched
and a status file recorded in their entirety, so an artifact-level declaration is the whole of each.
A correspondence assertion, when one ships, reaches only where a mark exists.

### 4.5 Body-shape rules

Only three, because over-structuring is the named risk.

**Rule 1 — every class keeps its H1 and its existing body structure.** Frontmatter is *prepended*;
nothing existing moves.

**Rule 2 — entry-bearing classes carry an explicit entry marker**, because heading level is not a
reliable selector (§ 3.3). **The marker carries the entity key and nothing else**; the entry's prose
is untouched.

The entry-bearing set is nine classes, and it takes **two marker forms** because the classes have two
shapes:

| Marker form | Classes | Why this form |
|---|---|---|
| **A fenced `artifact-entry` block** carrying the key | C5, C6, C7, C8, C9, C18 | These are prose-shaped: entries are headings and paragraphs, so there is no column to declare. A fence is the only marker that attaches a key to a prose entry without restructuring it. |
| **A declared key column** in the entry table | C10, C11, C13 | These are table-shaped, and the repo already does exactly this — `outputs/event-status.md` declares an `Event ID` column as its cross-run join key. A fenced block per row would restructure a table for no gain, and the per-class frontmatter grammar is scalar-only, so the key cannot be hoisted out of the table into the fence. |

Both forms satisfy the rule's wording — *the marker carries the entity key and nothing else*. The
`artifact-entry` fence info-string is shared with the venue-identity migration, which owns it; where
the two disagree on the fence's exact info-string, **the venue-identity definition wins.**

**Two cases fall outside both forms, and the disposition is that they carry no marker.** Each was
raised by the migration slice that met it and routed here rather than decided there. Silence would
read as an omission a later slice may close; this is the decision instead.

- **A secondary table inside a fence-form class carries no marker.** The form is assigned per
  **class**, and it attaches to that class's **entries** — not to every table the artifact happens to
  hold. The live case is C9's *Point-to-Point Transit Matrix*: its rows are legs, but it is a derived
  cost table sitting beneath the class's prose-shaped stream entries, which already carry the fenced
  form. Giving one class both forms would make the marker a property of a surface rather than of a
  class, and nothing would then tell a reader which surface to check. **What it costs, stated rather
  than deferred:** those door-to-door durations are read numerically by `agents/03-scheduling.md`
  § *Transit Cost & Routing Signal*, which makes them the highest-value join the class has, and they
  carry no key — a consumer matches on the leg's stop pair as written, with the display-string
  fragility § 3.3 measured. Assigning a key there is an identity decision for a later ADR, not a
  body-shape rule; until one is taken, the matrix is written exactly as its prompt writes it today.
- **C15 and C16 carry no marker, because they hold no entries of their own.** § 9 gives them an
  identity target — events by `evt-<token>`, venues by `ven-<token>` — and each of those is a
  **reference** to an entity another class masters: the Event by C13, the Venue by C11 under the
  identity § 3.3 fixes. A reference resolves against the mastering class's key and does not make the
  referring artifact entry-bearing, which is why **the entry-bearing set is nine and the itinerary is
  not in it.** **What it costs:** the join runs one way. From `outputs/event-status.md` or
  `outputs/venue-matrix.md` a reader reaches an itinerary day by key; from the itinerary back, only
  by display title. Closing that would mean structuring the most narrative artifact in the engine,
  which Decision 3 of `ADR-009` and the Day-Header Content Contract in `reference/site-layout-spec.md`
  both rule out — so it is recorded as a cost, not repaired here.

**Rule 3 — the degenerate case is part of every schema.** A class's schema defines the shape of an
entry with **no source** — the field-label surface exists whether populated or not. A profile-less
traveler's entry in C12 carries the same field labels as a populated one, with declared-absent
values, so a consumer reads *unknown* rather than inferring from a missing label.

---

## 5. Publishability

### 5.1 Artifact class — `publish:`, a closed four-value enum

- **`bound`** — the site build reads it. Exactly the five artifacts named in
  `reference/site-layout-spec.md` § 9.1: C1, C10, C11, C13, C15. That section remains the authority
  and this field is its machine-readable projection. **That the two agree is asserted, and not by a
  schema.** Each schema still constrains `publish:` to the enum domain and carries no per-class
  *value*, so the correspondence was a declared gap for as long as the schemas were the only place
  it could have lived. It is now held one layer up: `scripts/test-artifact-schema.sh` group `PB`
  resolves the `publish-contract-artifacts` fence § 9.1 declares and requires the fence and this
  column to be the same set, agreeing per row, in both directions. **The gap the fourth amendment of
  `ADR-009` declared is closed, and its seventh amendment records the closure**; what remains open
  is narrower and is stated at the group rather than here — the class selector is derived from the
  fence, so the wholesale disappearance of every row of one publish class would narrow the selector
  with it. The schema half of the corpus is asserted against this section independently and by other
  findings — a schema's `class-id` and `artifact` each against § 1.1, as `S1` and `S8` — so the two
  layers check different things and neither stands in for the other.
- **`internal`** — never rendered.
- **`internal-hard`** — never rendered **and** carrying values that must not reach a rendered page
  **in any form, including anonymized**. Exactly C12 and C14.
- **`output`** — the render itself: a sink, never a source.

### 5.2 Field classification

A field is `publishable` (the default) or `non-publishable`. **The schema half is a declared gap:**
the token `non-publishable` occurs zero times across the twenty-one files in `reference/schemas/`, that
directory's fence grammar is explicitly closed so a schema cannot express the marking, and no
enforcement file reads it. What shipped is the repo-side fence at § 5.6, and it does **not**
inherit — it carries one row per field *per artifact scope*, so a passport value is non-publishable
in C3 **and** in C12 by **two rows**, not from a single declaration carried into both. Expressing
the class **in the artifacts** is the residue, and it needs a schema grammar that can carry the
marking; § 5.6 is the half that did ship, and it says so in its own terms.

### 5.3 The class source — computed, never enumerated

> **non-publishable class = { every value of a field declared `non-publishable` }
> ∪ { every value of an entry whose `provenance` is `third-party` }**

Field-scoped union entry-scoped. This is the *read at both granularities, composing by union* rule
the publish guard already implements, now sourced from the schema instead of from two literals in
shell. **This is the answer to the open question of whether publishability is per-artifact or
per-field: it is both, and the two compose by union, never by override.** A per-field-only model
cannot express an entry-scoped denial, and a per-artifact-only model cannot express a single
non-publishable field inside a publish-bound artifact.

### 5.4 Hard constraints on the guard re-key

The guard's value is its **fail-closed posture**, not its literals. A re-key to the expression above
MUST preserve every one of these paths:

| Guard behaviour | Must survive because |
|---|---|
| Missing / unreadable / empty model → **UNDETERMINED** | an empty read is not an empty class |
| Profile newer than model → **UNDETERMINED** | the derived projection has not absorbed the source |
| No `## <Name>` entry parsed → **UNDETERMINED** | format drift is not an empty class |
| Orphaned third-party mark → **UNDETERMINED** | an unresolved presence is not zero either |
| Unsupported supersession → **UNDETERMINED** | a provenance change with no profile backing it |

A parsed-and-empty class must stay distinguishable from a class that **could not be computed**. An
attribute lookup that returned empty on error would destroy that distinction and turn a fail-closed
guard into a fail-open one.

### 5.5 What this does not fix, stated plainly

**Paraphrase remains out of reach by construction.** Keying the guard to a declared attribute makes
the class *sourced*, not *complete*: a value the model never captured, or a rendered paraphrase of
one, is still unreachable. This document makes no claim otherwise.

### 5.6 The declaration

This is the **machine-readable form of § 5.3's union**, and it is the single home of the
non-publishable class. `scripts/publish-trip-site.sh` reads the fence below and holds no copy of
any row in it: `nonpublishable_values` became a parameterized evaluator when the class moved here,
and `scripts/test-publish-guard.sh` case **L8** asserts that separation on every push — the class
source and the predicate must each carry **zero** declared selectors while this fence carries all
of them.

**Adding a member of the class inside the queried set is one row here and no edit to any shell
script.** The evaluator asks exactly three `(limb, artifact-scope)` questions — `entry` and `field`
against `outputs/traveler-model.md`, and `field` against `travelers/<traveler>.md` — so a further
non-publishable field on either of those two classes, or a further entry mark on the derived model,
is one row and nothing else. **A row naming any other pair is presently a code change:** it parses,
it is queried by nothing, and rather than guard less than it declares the guard aborts the publish
as UNDETERMINED (`scripts/test-publish-guard.sh` case **L10c**). The columns below admit any of
`limb`'s two values against **any** repo-relative artifact-class path, while the evaluator matches
three literal pairs, so the distance between what the declaration admits and what the guard asks is
a **declared gap** — widening the queried set is what closes it, and until then the fail-closed
abort is what keeps it visible rather than silent. That a member is admitted by the fence and not
by a shell literal remains the property to test a future change against.

```publish-contract-values
# limb   selector        artifact-scope              rule
field    Passport        travelers/<traveler>.md     conjunctive
field    Passport        outputs/traveler-model.md   conjunctive
entry    [THIRD-PARTY]   outputs/traveler-model.md   by-wordcount
field    Documents       outputs/traveler-model.md   conjunctive
```

Four columns, all required, whitespace-separated. A line whose first non-blank character is `#` is a
comment and is ignored; a blank line is ignored.

| Column | Domain | Meaning |
|---|---|---|
| `limb` | `field` \| `entry` | Which half of § 5.3's union the row contributes to. `field` = *every value of a field declared non-publishable*; `entry` = *every value of an entry whose provenance is third-party*. |
| `selector` | a field label, or an entry-level mark token | What the parse binds to. A `field` selector is matched case-insensitively as a label prefix followed by `:`, after the existing bullet/emphasis stripping. An `entry` selector is matched as a literal substring of the entry heading **and** of each raw value line — the two granularities compose by union, never by override. |
| `artifact-scope` | a repo-relative artifact-class path, with `<traveler>` admitted as a glob token | Which artifacts the row is evaluated against. |
| `rule` | `conjunctive` \| `phrase` \| `token` \| `by-wordcount` | The match rule that travels with the record, because membership and matchability are one decision. `by-wordcount` is the declared name of the shipped `n >= GUARD_NGRAM ? phrase : token` choice, so the declaration expresses today's behaviour rather than changing it. |

**The declaration is itself fail-closed, and this is a sixth UNDETERMINED path added to § 5.4's
five.** If this file is absent or unreadable, or the fence yields zero rows, `nonpublishable_values`
returns `2` and the publish aborts. A guard that cannot read its own class definition has not
measured an empty class; it has failed to measure — and an empty read falling through to a clean
publish is the exact fail-open § 5.4 exists to refuse, re-created one layer up.

**What deliberately did *not* move here.** The class's **widening** controls are declared; its
**narrowing** controls stay in the shell. `_GUARD_NEED_ENUM`, the `_GUARD_STOP` normalization
vocabulary, and `tp_value()`'s non-member exclusions all *shrink* the guarded set when extended, so
making them easy to edit would be a fail-open surface. A reader who concludes that every
class-shaped constant should follow the membership rule into this fence would weaken the control
while appearing to finish the job.

**Composition with per-artifact frontmatter.** This declaration is repo-side and the artifact parse
is unchanged, so it reaches an artifact carrying no frontmatter at all — which, under § 7.2's
tolerant read, is every pre-migration artifact and every trip in the git-ignored working dir. Once
an artifact carries its own frontmatter, the two sources compose by **union, never by override**:
at version 0 the frontmatter limb contributes nothing and the declaration carries the class; at
version ≥ 1 both contribute. No artifact loses coverage by not being migrated yet, and none gains a
second home by being migrated.

---

## 6. Lifecycle Classes

**This section is the single home for the canonical class tokens and their definitions.**
`reference/data-model.md` cites it for the satisfaction artifacts and restates none of them.
`CLAUDE.md` § *Output Versioning* cites it too — its § *Satisfaction-layer artifacts* subsection
says in terms that it assigns and does not define — but the rest of that section **still states the
engine's default-and-exception model in its own words, and is retained deliberately for it.** That
statement is a **live input**, not a leftover: this section's own absence rule below reads it, and
`.claude/commands/trip.md` derives the `/trip research` agent key from it, admitting exactly the
roster rows it leaves in the accumulating default. Where the two overlap, the tokens and
definitions above govern.

**What is not a restatement, and what is.** The twenty per-class schemas in `reference/schemas/`
each carry `field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]`
— the identical five-value **value domain**, a vocabulary constraint rather than a per-class
assignment, so no schema restates this section (each says the same of `writer:` in terms: *typed,
not enumerated*). What does restate the assignment is **inside this document**: § 9's
`Lifecycle: current → target` column states it a third time, after § 1.1's `L` column and the
`Members` column below. It is named here rather than left unnamed, and § 9 carries the same
membership disclaimer § 7.6 already carries.

| Canonical token | Definition | Members |
|---|---|---|
| `accumulate-append` | Each re-run **appends** a new dated section; nothing is deleted. The full accumulated file is what downstream reads. | C2, C5, C6, C7, C8, C9, C18, C20 |
| `rebuilt-each-synthesis` | Regenerated from scratch each synthesis pass from authoritative inputs. Safe to regenerate because it holds no independent state. | C4, C10, C11, C12, C14, C17 |
| `versioned` | Each synthesis produces a new numbered version; prior versions are preserved as sibling files. | C15, C16 |
| `persist-mutable` | A single file, updated **in place**, that survives every re-run. Synthesis *reads* it and never regenerates it. Not append-only: a row is deleted in the one case where its subject is removed, so no ghost row lingers. | C1, C3, C13 |
| `output` | A render, not a lifecycle-managed source. Rebuilt from the artifacts it renders; never read back as a source. | C19 |

**Legacy spellings — a closed record, not an open instruction.** Two legacy forms existed in the
corpus before this release, and they were **spellings, not additional classes**:

- the **Title-case prose-heading spellings** that `reference/data-model.md` § *Artifact Lifecycle
  Classification* carried — `(a) Accumulate-append-with-dated-sections`, `(b) Rebuilt-each-synthesis`,
  `(c) Versioned` — introduced as prose headings rather than tokens. That lettered enumeration is
  gone: the section now cites this one and states that it does not restate the definitions;
- a **slash-joined variant** of `rebuilt-each-synthesis`, `rebuilt/refreshed`, carried by
  `CLAUDE.md` § *Output Versioning*, `agents/05-hub-planner.md`, `agents/06-validator.md` and
  `reference/data-model.md` in **two casings**, so that a case-sensitive sweep would have missed one
  of them.

**Both were replaced in this release, and no tracked file but this one still carries either.**
Measured across all tracked files, **this document included**: the slash-joined variant stood at
**11** occurrences before this release — `CLAUDE.md` 2, `agents/05-hub-planner.md` 2,
`agents/06-validator.md` 1, `reference/data-model.md` 6, and zero anywhere else — and stands at
**1** now, that one being this section's own quotation of it in the closed record above; it is **0**
in every other tracked file. The lettered prose headings are dissolved. A count taken over a
population that excluded the measuring document would have read **0** and been wrong, which is why
the population is named. **No sweep remains to run, and a reader who takes the paragraph above as an
instruction runs a vacuous one.**

The canonical tokens above are the hyphenated lowercase forms — the form the corpus already used
everywhere for `persist-mutable`. They are recorded here because the compatibility surface reaches
past the repository: an artifact written before the migration, in a user's git-ignored `trips/`
directory, may still carry a legacy spelling, and a reader that meets one collapses it onto the
canonical token above rather than treating it as a sixth class.

**Two classes are assigned by the absence of an exception, and the absence is the assignment.**
`CLAUDE.md` § *Output Versioning* states one default — agent outputs accumulate, they do not
overwrite — and then names an exception set of six files. C8 and C9 are in neither the exception set
nor any contrary declaration, so they take the default. C9's writing agent puts it beyond doubt by
instructing in terms that the brief is not to be regenerated; three of the four agents carrying that
same instruction shape are already `accumulate-append`. C4 is the converse case: it is not in
`CLAUDE.md`'s exception set either, but its own writing agent declares it refreshed and holding no
independent state, so the declaration governs and it is `rebuilt-each-synthesis`.

**C17 is the third case, and it is the one the absence rule does not reach.**
`outputs/validation-report.md` is absent from `CLAUDE.md`'s exception set exactly as C8 and C9 are,
and — unlike C4 — its writing agent declares no lifecycle either. Read by absence alone it would
take the accumulating default. It does not, and the ground is substance rather than default: a
validation report is a **findings snapshot against one itinerary**, so a finding carried past the
itinerary it was made against reads as live when it is noise. That is the same property that makes
C14 `rebuilt-each-synthesis`, and C17 is its structural sibling — both are computed from the current
itinerary and hold no independent state of their own. § 1.1's table is that declaration; this note
is why the declaration governs and the absence rule yields. **Absence assigns only where nothing
else declares** — C4 and C17 are the two artifacts where something does, so they are bounded
exceptions to the rule above rather than counter-examples to it, and a reader who finds the rule
applied to C8 and C9 but not to C17 is looking at a stated exception, not an inconsistency.

---

## 7. Schema Versioning and Tolerant Read

### 7.1 The field

`schema-version: <integer>`, monotonic, **per artifact class**, starting at `1`. Not semver: there is
no external publisher, the only consumers are agents and scripts inside one repo, and an integer
removes the ordering-bug class that dotted versions invite. It also matches the repo's existing
bare-integer artifact versioning on `final-itinerary-v<N>`. Semver stays this repo's **release**
vocabulary; reusing it for artifacts would make a release version and a schema version visually
interchangeable and semantically unrelated.

### 7.2 Tolerant read — one rule, stated once, cited by every reader

> **Tolerant read.** A reader that encounters an artifact whose `schema-version` is:
>
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

The write-stop is the load-bearing half. Without it an un-migrated agent silently downgrades a newer
artifact — an irreversible loss inside a user's git-ignored working directory that this repo cannot
reach or repair.

**Every reading agent cites this rule; none restates it.** That is the pattern `reference/data-model.md`
already uses for the presence predicate and the applicable-day set: state it once, cite it
everywhere.

### 7.3 The gate's skip predicate

*Absent version ⇒ version 0* is exactly the validating gate's skip predicate. A gate **skips** an
artifact carrying no `schema-version`, and **fails closed** on one that declares a version and
violates that version's schema. The gate evaluates this rule; it does not invent a second one.

### 7.4 Evolution

A schema change that only **adds an optional field** does not bump the version — readers already
treat unknown fields as absent. A change that **adds a required field, removes a field, narrows an
enum, or changes a field's meaning** bumps the version by one, and the change states the migration
for instances at version *n−1*.

### 7.5 The compatibility guarantee

§ 7.2 says what a reader *does*. This says what the engine *promises*, which is the thing a future
schema change is weighed against. A trip that already exists in a user's working directory keeps
reading. The engine guarantees three things and declines to guarantee a fourth.

> 1. **An artifact carrying no `schema-version` stays readable at every future version**, and is
>    never a failure. There is no end-of-support version and no flag day. § 7.2's *absent ⇒ version
>    0* limb is the whole of the mechanism, which is why that limb is not negotiable later.
> 2. **A version bump never removes a reader's ability to read an older instance.** A change that
>    would make an older instance unreadable is not a version bump at all — it is a **new artifact
>    class**, and § 1.1 gains a row for it. This is what keeps § 7.4's bump rule from quietly
>    becoming a break rule.
> 3. **The write-stop is what makes 1 and 2 hold in practice**, and it is stated once at § 7.2. A
>    guarantee that a newer instance survives contact with an older reader is worth exactly as much
>    as that reader's refusal to write it — so the write-stop ships as a **refusal, never a
>    warning**. A warning that is ignored leaves the same destroyed file as no rule at all.
> 4. **Not guaranteed: that an older instance carries every *field* a newer reader knows.** Later
>    fields read as declared-absent, never as a default value (§ 7.2, second limb). A consumer that
>    needs a field its instance predates handles the absence; it does not substitute a default.
>    Guaranteeing otherwise would require rewriting artifacts the engine has no right to rewrite.

**Why this is stated rather than assumed.** The compatibility surface is a git-ignored directory
this repository cannot reach, inspect, or repair. A schema change weighed against this guarantee is
reversible; one weighed against nothing is not — the damage is discovered by a user, in their own
working directory, after it is already done.

### 7.6 The upgrade contract

**Most of this requirement is already discharged by § 6, and the residue is smaller than it looks.**
An artifact does not need a migration pass to reach the current version if its own lifecycle
regenerates it. Partitioning the 20 in-model classes by § 6 membership:

| Upgrade burden | Which lifecycle classes | Count | Mechanism |
|---|---|---|---|
| **None — self-upgrading by construction** | `rebuilt-each-synthesis` · `versioned` · `output` | **9** | All three rebuild wholesale from authoritative inputs on the next run, emitting the current version. There is no older instance to migrate, because the next pass does not preserve one. |
| **Writer-upgraded, in place** | `persist-mutable` · `accumulate-append` — **less the four classes named in the two rows below** | **7** | The owning writer upgrades the block on its next write. A `persist-mutable` class is read-then-written by its writer, which populates newly-required fields from the body it just parsed and reports the upgrade. An `accumulate-append` class upgrades its frontmatter block in place on the next append; **body entries are never rewritten**, because rewriting accumulated history to satisfy a schema would destroy the record the lifecycle exists to keep. |
| **Permanently tolerated at version 0** | C3 `travelers/<traveler>.md`, the one human-authored `persist-mutable` class | **1** | **Never engine-upgraded. This is a rule, not an omission.** |
| **No emitting writer — the upgrade has nobody to perform it** | C1 `trip-context.md` · C2 `trip-log.md` · C18 `outputs/<slug>.md` | **3** | **A declared gap, not a mechanism.** The writer-upgraded row assigns the upgrade to *the owning writer*; these three have no writer surface that emits their frontmatter block at all, so there is no next write for the upgrade to ride. Stated per class below. |

**9 + 7 + 1 + 3 = 20.** No class is unaccounted for. **The upgrade is not free of the operator across
all twenty:** for C18 a hand edit is today the only path to a versioned instance, and for C1 and C2
it is the only path for an instance that predates the surface that now emits each one's block at
creation. The fourth row is where that is stated rather than assumed away.

**Membership is § 6's, not this table's.** This partitions the lifecycle classes by upgrade burden;
**§ 6 governs which artifact class sits in which lifecycle**, and a class that moves between its rows
moves between these with it. The counts above are that assignment totalled, not a second roster —
naming the members again here would give the classification the two homes § 6 exists to prevent. The
two exception rows name their members because an exception is not derivable from a lifecycle: C3 is
excepted on authorship and the three below on the absence of an emitting writer, and neither property
is one § 6 records.

**Why C3 is never upgraded, and why that still satisfies the requirement.** `travelers/<traveler>.md`
is human-authored Layer 1 — the traveler's own words. `agents/00-enrichment.md` § *Second Role*
states the boundary in terms: the engine does not write those files and does not edit a traveler's
desires. An upgrade pass that rewrote a person's own file to add a frontmatter fence would breach
the engine's most explicit ownership boundary to satisfy a convenience. **Guarantee 1 is what
discharges the requirement for this class:** version 0 is permanently valid, so the file never needs
upgrading. That is an answer, not a deferral.

**The three with no emitting writer, and what each is waiting on.** The test is a writer surface — an
agent prompt, a command file or a template — that emits this class's frontmatter block. A class leaves
that row on the commit that gives it one, which makes the row self-clearing rather than a standing
exception. **This is a gap, not an answer**, and that is what separates it from C3 above: C3 is never
upgraded because upgrading it would breach an ownership boundary, while these three are not upgraded
because nothing is positioned to do it.

- **C1 `trip-context.md`** — its `writer` is the `block-owned` sentinel, which § 4.4 states in terms
  *is not a writer id and no tool resolves it to one*. `templates/trip-context.template.md` emits the
  block, so a trip scaffolded after this ships is born at the current version; nothing upgrades an
  instance that predates it. `agents/00-enrichment.md` is the one agent with a write grant on this
  file and its own prompt bars the upgrade — *a block you do not own, you do not upgrade* — because
  the `[ENRICH]` contract is field-scoped and is not a licence to touch the fence. **That bar is
  correct and is not the gap**; the gap is that no other writer holds the block.
- **C2 `trip-log.md`** — no template, and `/trip-record log`, its declared writer, emits no block.
  `/trip-new` **does** emit the fence, at scaffold and into that member only, so a trip created
  after that ships is born at the current version and the gap **ages out** rather than reproducing
  on every new trip. What keeps C2 in this row is what keeps C1 in it: the scaffold writes the block
  once, at creation, and no writer of a log that already exists emits one — so an instance predating
  the scaffold has no next write for an upgrade to ride.
- **C18 `outputs/<slug>.md`** — the targeted-research class is named on no writer surface at all,
  and for this class that is more than a missing emitter: **no surface produces an instance of it
  either.** The one targeted-research verb dispatches a spoke to append to the single output file
  that spoke's roster row names, and each spoke's own `## Output Format` names that same one file —
  so nothing in the engine opens a new slug file to carry a topic. **C18 is therefore a
  selector-reachable class with no producer**, which is a different position from C1's and C2's and
  is stated as such in `reference/schemas/targeted-research.md` → "Reachability", its own home. What
  follows for this row is that the gap neither ages out nor reproduces: it is dormant, and it goes
  live on the commit that gives the class a producer — which is the same commit that would have to
  give it an emitter.

**Guarantee 1 is what keeps all three readable in the meantime**, exactly as it does for C3: an
artifact carrying no `schema-version` is read as version 0 and stays valid forever, and the gate skips
it (§ 7.3). The cost is not a broken read — it is that a class carrying no version cannot be graded
against its schema, so its shape stays declared and unenforced until a writer emits the block.

**No new command verb, and no migration script.** The upgrade is a property of each writer's
existing write, not a separate operation an operator invokes. A verb would add a surface to the
command taxonomy — and its guard — for work the writer-upgraded classes' writers already do on their
next run. **That holds for the three classes above too, and it is what makes them repairable rather
than deferred:** each needs its existing writer to emit the block it already declares, not a new
surface for an operator to invoke.

### 7.7 The citation-anchor register

`ADR-009` Decision 6.3 states the obligation structurally: it binds **every agent prompt that reads
any versioned artifact**, and the citation site is *that prompt's input declaration where it has
one, and its equivalent where it does not*. This register is that statement made executable — it
names the site per prompt, so the obligation can be discharged and audited rather than interpreted.

**The uniform thing is a role, not a heading.** Eight prompts realize *declare what I read* as a
heading; one realizes it as a named role. Measured across the nine prompts, the partition is
`## Input` **7**, `## Inputs` **1**, neither **1** — so a rule keyed to the exact string `## Input`
would be unexecutable in two of nine, and it is not the corpus's convention in any case: of the
existing `reference/data-model.md` citations across these prompts, all but one sit outside `## Input`
altogether. **The anchor is the prompt's own read-declaration site**, enumerated here:

| # | Agent prompt | Read-declaration site | Note |
|---|---|---|---|
| 1 | `agents/00-enrichment.md` | `## Second Role — Reader / Reconciler of the Per-Traveler Model` | Carries no input heading at any spelling. This role declares both its reads **and** its write, which is the better fit — the rule's load-bearing half is a write-stop. |
| 2 | `agents/01-activities.md` | `## Input` | |
| 3 | `agents/02-food.md` | `## Input` | |
| 4 | `agents/03-scheduling.md` | `## Input` | |
| 5 | `agents/04-transport.md` | `## Input` | |
| 6 | `agents/05-hub-planner.md` | `## Input` | |
| 7 | `agents/06-validator.md` | `## Input` | |
| 8 | `agents/07-nightlife.md` | `## Input` | |
| 9 | `agents/destination-ideation.md` | `## Inputs` | **Plural. Cite in place; do not rename the heading.** The citation reads identically under either spelling, so a rename buys nothing — and agent section headings *are* cited by name elsewhere in the corpus, so a rename is not free either. |

**The citation form is the corpus's own**, not one invented here: a backticked path, an arrow, and
the section name in quotes — `` `reference/data-architecture.md` → "Tolerant read" `` — which is the
shape every existing reference-corpus citation in these prompts already uses. **A citation authored
against this register never carries a line number.** Line-anchored citations into the agent prompts
are the debt this release is retiring; a new one would add to it.

**What checks this form, and what does not — stated so a green is not read as coverage it does not
give.** The form carries no inline-link syntax — no square-bracketed text immediately followed by a
parenthesised path — so the repository's link-integrity job, `.github/workflows/security.yml` job
*Markdown link integrity (markdown-link-check)*, whose scope is that syntax and which requires each
one to *"resolve to a file that exists"*, has **an empty population over any document written in
this form.** Its green over such a document is therefore **vacuous, not passing**: it reports that
zero links were broken, which is a measurement of zero links, and it says nothing whatever about
whether these citations resolve. **Nothing in the repository resolves a `` `path` → "Section" ``
citation today.** A moved path, or a heading renamed against the table above, is caught by a reader
opening the file and by no gate.

**That is the accepted cost of the form, and the alternative is worse rather than merely
different.** A line anchor is *checkable and wrong* — the failure the first amendment of `ADR-009`
recorded across five tokens in one file — and converting these citations to inline links would
close the gap only for the ones converted, leaving a corpus in which two citation forms sit side by
side and a reader cannot tell which of them any gate stands behind. **One unchecked form applied
uniformly is more honest than a checked form and an unchecked form that look alike.** What closes
this properly is a resolver over the form itself — a check that reads the backticked path, requires
it to exist, and requires the quoted section name to be a heading of it. That is a gate, not a
prose change, and it is named here so the boundary is a declared gap rather than an unnoticed one.

**A prompt cites; it never restates.** A tenth agent added later declares its site in this table and
carries the citation — which is the reason the register is a closed table here rather than a
convention each new prompt rediscovers.

**This table names headings, so renaming one is an edit to this table.** That is the maintenance
cost the register accepts, deliberately and in exchange for the obligation being auditable at all:
a heading name is a far more stable anchor than a line number, and — unlike a line number — a stale
one is visible to any reader who opens the prompt. It is not free, and it is stated so that a later
rename repairs the register rather than silently orphaning a row.

---

## 8. Contracts, Granularity and Enforcement

Five known contract defects each name a model element that would prevent them. **One of the five
shipped in this release; four did not, and this section declares them rather than continuing to
assert them.** The `Shipped?` column is the reconciliation — it was written against a tree in which
`reference/schemas/` held no files, and the twenty schemas that arrived later implement one row of
it.

| Defect class | Model element that prevents it | Shipped? |
|---|---|---|
| A predicate two consumers read oppositely on a partial day | **`granularity:` as a declared property of every predicate and every factor** (`day` \| `time-block` \| `instant`), with **every predicate total over its declared domain.** The known mismatch — a time-block-granular constraint factor against a day-granular presence factor — would become a *declared, visible* mismatch rather than an implicit one. | **No — declared gap.** No schema carries a `granularity:` field, and totality is asserted nowhere. The mismatch remains implicit. |
| An agent that cannot read a signal another agent publishes | **`reads:` and `writes:` declared per agent, and `readers:` per artifact class — a closed set, with the two required to agree.** A signal published on a channel no consumer opens would become a *detectable* contract violation rather than a silent one. | **No — declared gap.** No schema carries `readers:`, and no agent prompt carries a machine-readable `reads:` / `writes:` declaration. A prompt's read-declaration *site* is registered in § 7.7, but that register names where a citation goes, not what an agent reads. |
| Suppliers blind to a field added upstream | **The propagation rule.** Adding a field to an artifact would oblige updating every agent in that artifact's declared `readers:` set, **derivable from the model rather than remembered.** | **No — declared gap, and it follows the row above.** The propagation rule is defined over the `readers:` set, so it cannot ship before that set does. |
| A subject with no source having no field-label surface | **§ 4.5 rule 3 — the degenerate case is part of every schema**, plus § 4.3, so shared vocabulary is single-sourced and two writers cannot describe the same distinction two ways. | **Yes.** Every class whose shape admits a degenerate entry declares it — `venue: unminted` in the research classes, `day: undated` in C8, the no-source stream in C9 — each stated as a declared absence rather than a default value. |
| A stated cap with no validator that audits it | **`enforced-by:` as a required property of every declared rule and every numeric cap** in the model. A rule with no enforcement point would be surfaced at authoring time instead of discovered by a later census. | **No — declared gap, and the sharpest one**, because this row states the rule the other three fail: *a rule with no enforcement point is a declared gap*. No schema carries `enforced-by:`; the caps this document states are audited by the guard suites where they are audited at all, and that correspondence is not declared anywhere a reader can query. |

**The four gaps are declared, not deferred silently — and declaring them is what this section's own
last row requires.** They are properties a later slice may add to the schema grammar; until it does,
nothing in `reference/schemas/` asserts them, and a reader grading a class against this section
grades it against the one row that shipped.

---

## 9. Per-Artifact Gap Analysis

**The pre-migration baseline**, measured against the target state fixed above. **Every in-model
class had the same delta on the first four dimensions** — no artifact carried frontmatter, a schema
version, a declared provenance field, or a declared publishability class — so those are stated once
here rather than repeated twenty times.

**This release closed that universal delta.** The migrated artifacts carry all four, and
`examples/data-architecture-demo/` is the worked instance. The table below is retained as the record
of what the migration had to do; it is not a description of the tree today.

**Universal pre-migration state (all of C1–C19):**

| Dimension | Current | Target | Delta |
|---|---|---|---|
| Frontmatter | **None.** No engine artifact opens with a `---` fence. The only frontmatter in the repo belongs to the command files, whose schema is upstream-owned. | § 4.4 universal frontmatter | Prepend the fence; move nothing. |
| `schema-version` | **None.** No version field of any spelling exists in the corpus. | `schema-version: 1` | Greenfield — nothing to collide with. |
| `provenance` declaration | **None as a field.** Provenance exists only as four inline bracket marks on individual values. | § 4.4 `provenance:` | Add the declaration; **retain** the marks; assert correspondence. |
| `publish` class | **None as a field.** Publishability is inferable only from prose in the site-layout spec and from two literals in the publish guard. | § 5.1 `publish:` | Add the field as the machine-readable projection of the spec section. |

**Per-class deltas on identity and lifecycle** — the dimensions where classes differ. **The
`Lifecycle` column is § 6's assignment projected as a delta, not a second roster** — § 6 governs
which class sits in which lifecycle, and a class that moves between its rows moves here with it.
That is the same disclaimer § 7.6 carries, stated here because this column is the third place in
this document the assignment appears.

| C | Identity: current → target | Lifecycle: current → target |
|---|---|---|
| 1 | Trip slug is the directory name → unchanged, now declared | Undeclared → `persist-mutable` (**new declaration**) |
| 2 | No key → none needed (§ 1.4) | Undeclared → `accumulate-append` (**new declaration**) |
| 3 | Filename + heading, no stated correspondence → **normalized traveler key with a stated reverse correspondence and a reserved-key list** | Undeclared → `persist-mutable` (**new declaration**) |
| 4 | No key → Destination candidate keyed by name | Declared by its agent as refreshed → `rebuilt-each-synthesis` (token assigned) |
| 5–7 | Entries keyed by a **file-scoped ordinal**, unstable under append → **`ven-<token>`**, hub-minted; explicit entry marker | Default-rule accumulate → `accumulate-append` (token assigned) |
| 8 | No entity key at all → explicit entry marker carrying the key | **Undeclared** → `accumulate-append` (**new declaration**, by the absence of an exception) |
| 9 | No entity key at all → explicit entry marker carrying the key | **Undeclared** → `accumulate-append` (**new declaration**, on its agent's own do-not-regenerate instruction) |
| 10 | Venue by display name, divergent across artifacts → `ven-<token>` as a declared key column | Declared rebuilt in prose → `rebuilt-each-synthesis` (token assigned) |
| 11 | Venue by display name → `ven-<token>` as a declared key column | Declared rebuilt in prose → `rebuilt-each-synthesis` (token assigned) |
| 12 | `## <Name>` heading, normalization only in shell → the same normalization, stated as the model's rule | Declared → `rebuilt-each-synthesis` (spelling canonicalized) |
| 13 | **`Event ID` column already correct** → unchanged; it is the precedent the rule reproduces | Declared → `persist-mutable` (already the canonical token) |
| 14 | No key → Metric keyed by dimension name | Declared → `rebuilt-each-synthesis` (spelling canonicalized) |
| 15–16 | Events by display title → `evt-<token>`; venues by `ven-<token>` | Declared → `versioned` (token assigned) |
| 17 | Findings unkeyed → Finding, surrogate | **Undeclared anywhere** → `rebuilt-each-synthesis` (**new declaration**) |
| 18 | Same as C5–C7 | Not previously named as a class → `accumulate-append` |
| 19 | N/A — a render | Not previously named as a class → `output` (**new class token**) |
| 20 | n/a — post-migration class | n/a — declared `accumulate-append` at creation |

**Out-of-model classes C21–C26** carry no target state by construction; their delta is the explicit
disposition in § 1.2, which is what makes them non-silent.

---

## 10. Migration Sequence

The order is fixed by two constraints, and both are hard.

1. **The version contract lands before any artifact is migrated.** § 7's tolerant read — and
   specifically its write-stop — is what keeps a partially-migrated working directory readable. A
   migration that landed first would put artifacts into the field that un-migrated agents could
   silently downgrade, in a git-ignored directory this repo cannot reach.
2. **The worked example is a byte-identical regression witness and is not edited in place.** Every
   file under `examples/tokyo-2026/` is pinned by content address in the freeze declaration below,
   and `scripts/test-artifact-schema.sh` group **FW** asserts each one byte-for-byte on every push —
   the comparison is `git hash-object`'s, so byte-identity is literally what is compared. The pinned
   set is checked against the tracked set **in both directions**, so a file added under the witness
   or deleted from it fails as loudly as a file whose bytes moved. Migration adds *new* fixtures that
   instantiate the schema; it does not rewrite the witness.

   **What that assertion does not reach, stated so the freeze is not read as more than it is.** It
   is a statement about *content identity*, not about *conformance*: none of these files carries a
   `schema-version`, so the validating gate selects them and then **skips** them under § 7.2's
   tolerant read, exactly as it does every other version-0 artifact. The witness is frozen and
   unvalidated, and those are two different properties — freezing it is what makes it a regression
   witness, and migrating it is what would make it a conformance one. This constraint deliberately
   chooses the first.

#### The freeze declaration

**This fence is the machine-readable form of constraint 2, and it is the single home of the
freeze.** `scripts/test-artifact-schema.sh` group **FW** reads it, recomputes each file's content
hash from the working tree, and compares — so the freeze is asserted on every push rather than
held only as a review constraint. It is the same declaration-in-the-corpus mechanism § 5.6 uses
for the non-publishable class: the document declares, the script reads, and neither holds a copy
of the other's answer.

The digest is `git hash-object`'s — git's own content address, so the comparison is byte-for-byte
by construction and needs no external hashing tool, no network, and no second commit to diff
against. **A path set mismatch fails in both directions:** a file added under the witness, or one
deleted from it, fails as loudly as a file whose bytes moved.

```frozen-witness-digest
# blob-sha1                                  path
4d21d3f1ed0243926708c9e0c6db0cc0252efc8e  examples/tokyo-2026/README.md
4e8ca528f8d42b2772a862ca1fe2f0fe9ac6e7be  examples/tokyo-2026/trip-context.md
31ccf68d0ae6ae0fc59fefae90b3568df6d641b3  examples/tokyo-2026/trip-log.md
c060dbd10e190ae95cd2cfbf7357d4a58e88e60d  examples/tokyo-2026/outputs/casual-dining-family.md
edb650563899d0e3f0719bb284174d70e5bee063  examples/tokyo-2026/outputs/final-itinerary.md
b22d10458c35ad2e12dbd1dc068ec20444b28424  examples/tokyo-2026/outputs/food-list.md
b0763fc90e320a678912f5a89d5d33a0a0740242  examples/tokyo-2026/outputs/links-reference.md
4221c899f6729c6e712bffec1d4bb00f772fcf52  examples/tokyo-2026/outputs/scheduling-framework.md
e671aa24effdb9f3e8e1791b9d2edc70447b847f  examples/tokyo-2026/outputs/transport-brief.md
d658872d50bf7b50d60192871dc8465dbd948f14  examples/tokyo-2026/outputs/activities-list.md
```

Two columns, both required, whitespace-separated. A line whose first non-blank character is `#`
is a comment and is ignored; a blank line is ignored.

**What to do when the witness legitimately has to change.** The freeze is a review constraint,
not a prohibition — it exists so that a change is *deliberate and visible*, never so that it is
impossible. Edit the file and update its row here **in the same commit**. The diff then carries
both halves side by side, which is the whole point: a reviewer sees the content change and the
re-pin together, and a content change arriving *without* its re-pin turns the branch red. Do not
regenerate the whole fence to make a red go away — re-pin only the rows you meant to change, or
the assertion stops being a freeze and becomes a rubber stamp.

Within those bounds: the schema definitions and the validating gate precede the per-class migrations;
the publish-guard re-key precedes or accompanies the classes whose publishability it reads; and the
fixture work lands last, because a fixture can only witness a schema that already exists. **Eight
in-model classes had no in-repo instance at all** when this order was set, so the fixture step is
what gives them their first witness — and a fixture that instantiates an `accumulate-append` class
should carry at least two dated sections, or that lifecycle stays declared and unwitnessed.

**That step has landed, and the two-dated-section criterion is met by two instances of six.**
Measured across the six tracked instances declaring `lifecycle: accumulate-append`, all of them in
`examples/data-architecture-demo/`: `trip-log.md` and `outputs/activities-list.md` carry two dated
sections each, and the other four — `outputs/nightlife-list.md`, `outputs/rooftop-sunset-bars.md`,
`outputs/scheduling-framework.md` and `outputs/transport-brief.md` — carry one each. In the
criterion's own terms those four leave the lifecycle **declared and unwitnessed**: their frontmatter
is witnessed, their accumulation is not. `examples/data-architecture-demo/README.md` § *Depth* holds
the live count and is the authority if the fixture deepens again — this paragraph cites it rather
than keeping a second copy of the number, because the first copy of it went stale inside this
release when the fixture gained its second witness. Whether to deepen the fixture is an open decision and is
not taken here.

**The grading basis that step settles is read from one place.** Which classes hold a tracked
witness, which do not, and why each one that does not never will, is declared per class in
`reference/schemas/*.md` and reported by the gate on every run as its `CV:` coverage line; the two
standing exceptions are named, with their reasons stated as durable properties, in
`reference/schemas/README.md` § *Coverage*. It is not restated here — a second copy of a coverage
answer is a second home for it, which § 4.3 forbids. **What that home settles for a reader grading a
migration:** a class whose instances are per-trip files under the git-ignored `trips/` tree can be
migrated only at its **emitter** — the agent prompt that writes it, and the schema that declares its
shape — so a class carrying no witness is graded there and never against a repository artifact. That
is a statement about where a class can exist, not a relaxation of any criterion.

---

## 11. What This Document Does Not Define

Following the precedent set by `reference/data-model.md` § *What This Document Does Not Define*, which is why
that document has held up.

- **No metric formulas, scoring, weighting, ranking or optimization.** This document inherits that
  boundary from `reference/data-model.md` and does not relax it.
- **No control flow.** Who runs when, and in what order, belongs to the control-flow contract. This
  is the data contract.
- **`.claude/commands/*.md` frontmatter is out of scope and out of the gate's selection set.** Those
  files carry an **upstream schema** this repo does not own and cannot change. The artifact schema
  set does not claim them, and the validating gate does not check them.
- **`templates/*.template.md` are out of the gate's selection set too.** § 1.3 already disposes of
  them as **emitters, not instances**, and binds the schema to a template's *rendered output* rather
  than to the template file. The gate therefore adjudicates the instance a template seeds and never
  the emitter. This is stated because the exclusion is otherwise only inferable: a selector written
  from § 1.1 alone picks up two files the artifact model has already declared out of scope, and it
  picks them up at the one moment they declare a version and no schema for their class exists yet.
- **No prose validation.** The schema constrains frontmatter and declared entry markers. It never
  constrains narrative body content.
- **No change to the `Applies to` link syntax, the Event ID format, the four event statuses, or the
  presence predicate's semantics.** Existing precedents are preserved; only their *declaration*
  moves into frontmatter.
- **Not the publish path's completeness.** Paraphrase remains out of reach (§ 5.5).
- **No migration.** This document specifies; the migration slices migrate.
- **Out-of-model classes C21–C26** are named and excluded, not modelled.

---

## 12. Decisions Handed to the ADR

This document is authoritative for the **model**; the engine-wide data-architecture ADR (`ADR-009`,
in `reference/adr/`) is authoritative for the **decisions**. Where they overlap they must agree: the
ADR wins on the decision, this document wins on the shape.

| Decision | Recorded where |
|---|---|
| **Document topology** — a new engine-wide document above a narrowed-in-place `reference/data-model.md` | § *What This Document Governs*; the alternative was rejected because engine-wide scope necessarily rewrites `reference/data-model.md`'s scope declaration, which shifts line anchors cited from three other files |
| **Identity rule** — origin-of-identity × natural-candidate stability, five surrogate / five natural | § 3 |
| **Frontmatter/body boundary** — the three-question test | § 4.2 |
| **Publishability** — artifact class **and** field classification, composing by **union** | § 5 |
| **Schema versioning** — monotonic integer plus one stated tolerant-read rule carrying a write-stop | § 7 |
| **Provenance** — a frontmatter-declared closed enum beside retained inline marks; the `provenance:` key narrowed to its own artifact scope, with `researched` and `recorded` as its added members | § 4.4 |

**No item remains open here, and the one that stood is discharged.** It asked for a decision on
several line-number citations into `reference/data-model.md` held by an Accepted ADR: pin them as
historical provenance, or amend them to anchor form. The second was taken through the governed path,
and the corpus now carries **no** line-number citation into that file in any direction — every
reference is section-anchor form. The entry is kept rather than deleted because it records a
decision that was made, and because it is a worked instance of this release's most persistent
defect: a statement true when written, left standing after the work it describes was finished.
