# Artifact schema — C2 `trip-log.md`

The narrative register. It takes frontmatter so tooling can find and version it, and its **body is never schema-constrained** (§ 1.4) — constraining a decision log's prose is the structure-over-judgment failure this architecture exists to prevent.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C2
artifact: trip-log.md
schema-version: 1
path-pattern: trips/*/trip-log.md
path-pattern: examples/*/trip-log.md
no-witness-because: the only tracked instance is examples/tokyo-2026/trip-log.md, inside the worked example this release preserves unedited as its regression witness, so it cannot be versioned here

# The universal block — reference/data-architecture.md § 4.4. No class removes a
# universal field; a class may only narrow one, and each narrowing is stated below.
field artifact: required string
field schema-version: required integer
field trip: required slug
field writer: required slug
field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]
field provenance: required enum [human|enrich|derived|operator-provided|third-party|researched]
field publish: required enum [bound|internal|internal-hard|output]
field generated: optional date
```

- **`generated` is `optional` here.** § 4.4 states it is omitted on human-authored classes. That is a narrowing of an optional universal field, not the removal of one.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class currently declares `no-witness-because:`. The gate reports the witness / no-witness split on every run, so the coverage question is answered by reading one emitted line rather than by auditing nineteen files.
