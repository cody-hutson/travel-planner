# Artifact schema — C13 `outputs/event-status.md`

Per-event status — the one artifact that must outlive a planning pass. `persist-mutable`: a re-synthesis reads existing status and never regenerates it.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C13
artifact: outputs/event-status.md
schema-version: 1
path-pattern: trips/*/outputs/event-status.md
path-pattern: examples/*/outputs/event-status.md
no-witness-because: no tracked instance of this class exists anywhere in the repository, so there is nothing to validate until a migrated fixture supplies one

# The universal block — reference/data-architecture.md § 4.4. No class removes a
# universal field; a class may only narrow one, and each narrowing is stated below.
field artifact: required string
field schema-version: required integer
field trip: required slug
field writer: required slug
field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]
field provenance: required enum [human|enrich|derived|operator-provided|third-party|researched]
field publish: required enum [bound|internal|internal-hard|output]
field generated: required date
```

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class currently declares `no-witness-because:`. The gate reports the witness / no-witness split on every run, so the coverage question is answered by reading one emitted line rather than by auditing nineteen files.
