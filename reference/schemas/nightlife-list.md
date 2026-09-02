# Artifact schema — C7 `outputs/nightlife-list.md`

Nightlife research, accumulated across sessions. `researched`, for the same reason as C5.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C7
artifact: outputs/nightlife-list.md
schema-version: 1
path-pattern: trips/*/outputs/nightlife-list.md
path-pattern: examples/*/outputs/nightlife-list.md
witness: examples/data-architecture-demo/outputs/nightlife-list.md

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
- **Coverage.** This class declares `witness:`. `examples/data-architecture-demo/` supplies the first tracked instance this class has ever had. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.

## The entry marker

`../data-architecture.md` § 4.5 rule 2 names this class entry-bearing and fixes the marker's form: **a fenced `artifact-entry` block carrying the entity key and, since § 4.5.1 amended that rule, one optional `cost:` line — and nothing else**, with the entry's prose untouched. One block per entry, directly under that entry's own heading:

```artifact-entry
venue: ven-<token>
```

- **The block is the entry selector.** A fence rather than a heading, and rather than an entry ordinal, per § 3.3. **This class had no tracked instance anywhere in the repository when the marker was designed**, so its entry shape could not be pattern-matched from a witness the way its two siblings' could — which is the strongest possible argument for an explicit marker over any positional convention. The fixture has since supplied one (see *Coverage* above), and the argument is unchanged: it rests on the marker being independent of position, not on the absence of a witness. Its writer also emits a **gate-result stub** with no entries at all when the desire gate resolves SKIP; a stub carries no marker, and that is the correct reading of a file whose entry population is zero, never a defect.
- **`ven-<token>` is minted by the hub**, at its first enumeration of the venue set — before it writes either reference file (§ 3.3) — which is downstream of this class's writer. On a pass where the hub has not yet enumerated, or where its reference files do not yet carry the venue, the block declares `venue: unminted`. That is a **declared absence, never a default value**, which is the degenerate case § 4.5 rule 3 requires every schema to define.
- **Nothing else enters the marker but the declared cost field.** Display name, nights and hours, night type, entry policy, dry-friendliness and every judgement line stay in the entry's labelled prose, where they already are. § 4.2's frontmatter/body test decides *frontmatter* versus *body*, and this class's frontmatter is file-scoped — one block, the first bytes of the file — so an entry-level value has no field to become. The key does, and so — since `../data-architecture.md` § 4.5.1 amended rule 2 — does one optional `cost:` line. That is the model's answer rather than this schema's. **The `**Price range:**` prose line is unchanged and stays the master**: § 4.5 rule 1 forbids moving it, and the marker's scalar carries the range's low bound with a currency and a basis rather than the range itself. **`price band` used to be named in this sentence** as a value barred from the marker; it is removed rather than left standing, because the old wording would forbid what the model now admits.
- **The entry's field-label surface is the prompt's**, per § 4.5 rule 3: `agents/07-nightlife.md` § *Output Format* enumerates the labels every entry carries, and this schema does not restate them — a second copy of that list is a second home for it.

**Declared here, validated by nothing in this release.** The fence grammar in [`README.md`](README.md) admits no entry construct and the validator emits no entry-marker finding code, so this section is prose the gate does not read. Said plainly, so a green check is not mistaken for marker conformance — and that holds on the witness the fixture now supplies exactly as it held when this class had none, because no arm of the gate reads an entry marker at all.

**Info-string ownership.** § 4.5 records that the `artifact-entry` info string is shared with the venue-identity migration, **which owns it**; where the two disagree on the exact info string, the venue-identity definition wins. No in-repo definition of it exists yet, so this class is among the first to spell it.
