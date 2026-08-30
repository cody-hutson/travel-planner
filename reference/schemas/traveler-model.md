# Artifact schema — C12 `outputs/traveler-model.md`

The derived per-traveler model. `internal-hard`: it carries `[THIRD-PARTY]` entries that must never reach a publish-bound artifact in attributed **or** anonymized form (`reference/adr/ADR-006-third-party-data-capture.md`).

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C12
artifact: outputs/traveler-model.md
schema-version: 1
path-pattern: trips/*/outputs/traveler-model.md
path-pattern: examples/*/outputs/traveler-model.md
witness: examples/data-architecture-demo/outputs/traveler-model.md

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

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. `examples/data-architecture-demo/` supplies the first tracked instance this class has ever had — one carrying no `[THIRD-PARTY]` entry, deliberately: such a value must not appear in any publish-bound artifact, so a tracked worked example is the wrong place to demonstrate one. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
