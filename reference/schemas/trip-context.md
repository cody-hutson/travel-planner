# Artifact schema — C1 `trip-context.md`

The trip's source of truth. Its `writer` is the sentinel `block-owned`: write access is granted per block by `CLAUDE.md` § *Write ownership*, and no tool resolves the sentinel to a writer id.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C1
artifact: trip-context.md
schema-version: 1
path-pattern: trips/*/trip-context.md
path-pattern: examples/*/trip-context.md
witness: examples/two-origin-demo/trip-context.md

# The universal block — reference/data-architecture.md § 4.4. No class removes a
# universal field; a class may only narrow one, and each narrowing is stated below.
field artifact: required string
field schema-version: required integer
field trip: required slug
field writer: required slug
field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]
field provenance: required enum [human|researched|derived|recorded]
field publish: required enum [bound|internal|internal-hard|output]
field generated: optional date
```

- **`writer` is the sentinel `block-owned`.** It types as a `slug` and is not a writer id; `CLAUDE.md` § *Write ownership* is where the per-block assignment lives.
- **`generated` is `optional` here.** § 4.4 states it is omitted on human-authored classes. That is a narrowing of an optional universal field, not the removal of one.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. From this commit a stripped or unversioned witness is finding `S6` — a coverage regression, fail-closed — without re-branching the tolerant read, because the failing assertion is this declaration and not the skip predicate. The gate reports the witness / no-witness split on every run, so the coverage question is answered by reading one emitted line rather than by auditing nineteen files.
