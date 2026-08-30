# Artifact schema — C13 `outputs/event-status.md`

Per-event status — the one artifact that must outlive a planning pass. `persist-mutable`: a re-synthesis reads existing status and never regenerates it.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C13
artifact: outputs/event-status.md
schema-version: 1
path-pattern: trips/*/outputs/event-status.md
path-pattern: examples/*/outputs/event-status.md
witness: examples/data-architecture-demo/outputs/event-status.md

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

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: recorded`.
- **`provenance: recorded`, not `derived`.** This class is the sole member of `recorded` (§ 4.4). Its rows are the engine's own acts — an Event ID minted on first placement, a status moved to `locked`, a booking held — so regenerating the file would destroy state no input can reconstruct. `derived` is the corpus's word for *holds no independent state, so regenerating it is safe*, which is the opposite of what `persist-mutable` promises of this file.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. `examples/data-architecture-demo/` supplies the first tracked instance this class has ever had. From this commit a stripped or unversioned witness is finding `S6` — a fail-closed coverage regression — without re-branching the tolerant read, because the failing assertion is this declaration and not the skip predicate.
