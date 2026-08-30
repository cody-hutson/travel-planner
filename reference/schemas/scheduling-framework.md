# Artifact schema — C8 `outputs/scheduling-framework.md`

The scheduling framework. `researched` covers analysis over research as well as research itself — the definition carries that precision deliberately (§ 4.4).

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C8
artifact: outputs/scheduling-framework.md
schema-version: 1
path-pattern: trips/*/outputs/scheduling-framework.md
path-pattern: examples/*/outputs/scheduling-framework.md
witness: examples/data-architecture-demo/outputs/scheduling-framework.md

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
- **Coverage.** This class declares `witness:`. The witness is the migrated fixture instance, **not** the `examples/tokyo-2026/` one — that tree is preserved unedited as this release's regression witness. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.

## The entry marker

`../data-architecture.md` § 4.5 rule 2 names this class entry-bearing and fixes the marker's form: **a fenced `artifact-entry` block carrying the entity key and nothing else**, with the entry's prose untouched. One block per entry, directly under that entry's own `**Day [N] — …**` line:

```artifact-entry
day: <YYYY-MM-DD>
```

- **The key is the Day, because it is the only key this class's entity set has.** § 1.1 lists this class's primary entities as *Day, Block, Signal*. **Day** is assigned a natural key — the ISO date — by § 3.4. **Block and Signal are named in that row and nowhere else in the document**: neither holds a row in § 2's ten-entity table, and neither appears in § 3.4's assignment, which partitions those ten five/five and closes. So neither has a key to carry, and the marker takes the one key that exists. That is the model's answer, not this schema's; the gap is reported rather than closed here, since minting an identity for an entity the model does not carry would be deciding identity case-by-case per artifact, which § 3 forbids in terms.
- **It binds three surfaces, not one.** `agents/03-scheduling.md` § *Output Format* emits a per-day entry three times — the day-by-day framework, the transit-cost/routing signal and the experience-balance signal. Those are three projections of one Day, so all three carry the same day key; that repetition **is** the join, not a duplicate home. § 4.3 is unaffected: the key is a key, and no value is copied.
- **The degenerate case is `day: undated`** — § 4.5 rule 3. Where a framework is produced against a trip whose calendar dates are not yet fixed, the marker declares the absence rather than omitting the block or synthesizing a date. A reader takes `undated` as *date not yet fixed*, never as *no day*.
- **`Day [N]` is not the key.** The day index is a file-scoped ordinal and this class is `accumulate-append`, so a later dated section either restarts or continues the numbering — the exact instability § 3.3 cites when it refuses an ordinal as an entry key. The index stays in the prose line where it reads well.
- **Nothing else enters the marker.** Energy level, day type, zone, presence and absence lists, the signal readings and every flag stay in the entry's labelled prose, where they already are. § 4.2's frontmatter/body test decides *frontmatter* versus *body*, and this class's frontmatter is file-scoped — one block, the first bytes of the file — so an entry-level value has no field to become. Only the key does, and § 4.5 rule 2 gives it the marker.
- **The entry's field-label surface is the prompt's**, per § 4.5 rule 3: `agents/03-scheduling.md` § *Output Format* enumerates the labels every per-day entry carries, and this schema does not restate them — a second copy of that list is a second home for it.

**Declared here, validated by nothing in this release.** The fence grammar in [`README.md`](README.md) admits no entry construct and the validator emits no entry-marker finding code, so this section is prose the gate does not read. Said plainly, so a green check is not mistaken for marker conformance.

**Info-string ownership.** § 4.5 records that the `artifact-entry` info string is shared with the venue-identity migration, **which owns it**; where the two disagree on the exact info string, the venue-identity definition wins. The spelling used here is the one `reference/schemas/activities-list.md`, `food-list.md` and `nightlife-list.md` already ship — one info string, one `<entity>: <key>` line, no second grammar.
