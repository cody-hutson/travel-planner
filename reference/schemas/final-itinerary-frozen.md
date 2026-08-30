# Artifact schema — C16 `outputs/final-itinerary-v<N>.md`

A frozen prior itinerary version. Same shape as C15 and `internal` rather than `bound`, because a superseded itinerary is not the published one.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C16
artifact: outputs/final-itinerary-v<N>.md
schema-version: 1
path-pattern: trips/*/outputs/final-itinerary-v*.md
path-pattern: examples/*/outputs/final-itinerary-v*.md
witness: examples/data-architecture-demo/outputs/final-itinerary-v1.md

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
- **Coverage.** This class declares `witness:`. `examples/data-architecture-demo/` supplies the first tracked instance this class has ever had. The witness file is named `final-itinerary-v1.md` and its `artifact:` value is `outputs/final-itinerary-v<N>.md` — the class string, not the instance path; the two differing is the point, and a witness naming its own path would be finding `A5`. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
