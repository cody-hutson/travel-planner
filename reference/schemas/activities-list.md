# Artifact schema — C5 `outputs/activities-list.md`

Activity research, accumulated across sessions. `researched`: it holds independent state and nothing upstream can reconstruct it.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C5
artifact: outputs/activities-list.md
schema-version: 1
path-pattern: trips/*/outputs/activities-list.md
path-pattern: examples/*/outputs/activities-list.md
witness: examples/data-architecture-demo/outputs/activities-list.md

# The universal block — reference/data-architecture.md § 4.4. No class removes a
# universal field; a class may only narrow one, and each narrowing is stated below.
field artifact: required string
field schema-version: required integer
field trip: required slug
field writer: required slug
field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]
field provenance: required enum [human|researched|derived|recorded]
field publish: required enum [bound|internal|internal-hard|output]
field generated: required date
```

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: researched`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. The witness is the migrated fixture instance, **not** the `examples/tokyo-2026/` one — that tree is preserved unedited as this release's regression witness, and editing a fixture to satisfy a gate would trade a real regression guard for a green check. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.

## The entry marker

`../data-architecture.md` § 4.5 rule 2 names this class entry-bearing and fixes the marker's form: **a fenced `artifact-entry` block carrying the entity key and, since § 4.5.1 amended that rule, one optional `cost:` line — and nothing else**, with the entry's prose untouched. One block per entry, directly under that entry's own heading:

```artifact-entry
venue: ven-<token>
cost: <amount> <currency> per-person
```

- **The block is the entry selector.** A fence rather than a heading, and rather than an entry ordinal. This class's tracked instance carries **no entry ordinals at all** — its entries are bare third-level headings — while its sibling `outputs/food-list.md` numbers every entry. Two members of one lifecycle, two entry shapes: no positional or heading-shape selector is correct across the set, which is what § 3.3 means by *never a heading level*.
- **`ven-<token>` is minted by the hub**, at its first enumeration of the venue set — before it writes either reference file (§ 3.3) — which is downstream of this class's writer. On a pass where the hub has not yet enumerated, or where its reference files do not yet carry the venue, the block declares `venue: unminted`. That is a **declared absence, never a default value**, which is the degenerate case § 4.5 rule 3 requires every schema to define.
- **Nothing else enters the marker but the declared cost field.** Display name, zone, duration, bailout venue, booking posture and every judgement line stay in the entry's labelled prose, where they already are. § 4.2's frontmatter/body test decides *frontmatter* versus *body*, and this class's frontmatter is file-scoped — one block, the first bytes of the file — so an entry-level value has no field to become. The key does, and so — since `../data-architecture.md` § 4.5.1 amended rule 2 — does one optional `cost:` line. That is the model's answer rather than this schema's. **This class used to be the one cost-bearing member with no money label of its own**, and it is not any more: `reference/adr/ADR-018-cost-estimation-method.md` § *Decision 9* adds one, and `agents/01-activities.md` § *Output Format* now declares `**Entry cost:**` in its entry surface. The sentence is corrected rather than removed, because the state it described is the reason the label was added at all — the prompt already mandated researching a price and a price tier while declaring nowhere to write either down, so the marker would have emitted `undetermined` on every entry forever. **The `**Entry cost:**` prose line is the master** and § 4.5 rule 1 forbids moving it; the marker's scalar is a per-person low bound projected from it, and `free` is a value contributing `cost: 0 <CUR> per-person` rather than an absence. Admission is still not obligation — § 4.5.1 assigns the field by marker **form**, not by which classes happen to be priced, and that is why C8 admits the field and correctly emits nothing.
- **The entry's field-label surface is the prompt's**, per § 4.5 rule 3: `agents/01-activities.md` § *Output Format* enumerates the labels every entry carries, and this schema does not restate them — a second copy of that list is a second home for it.

**Declared here; the cost line's grammar is graded and the rest of this section is not.** The fence grammar in [`README.md`](README.md) admits no entry construct and the validator **still** emits no entry-marker finding code, so the schema gate reads none of this — which is precisely why `scripts/test-artifact-schema.sh` group `CE` grades the `cost:` line against the tracked tree instead, adding no finding code to the validator. What stays ungraded is everything else here: that an entry carries a marker at all, that its key resolves, and that its scalar agrees with the prose line it was projected from. Said plainly, so a green check is not mistaken for marker conformance.

**Info-string ownership.** § 4.5 records that the `artifact-entry` info string is shared with the venue-identity migration, **which owns it**; where the two disagree on the exact info string, the venue-identity definition wins. No in-repo definition of it exists yet, so this class is among the first to spell it.
