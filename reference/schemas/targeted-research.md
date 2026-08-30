# Artifact schema — C18 `outputs/<slug>.md`

The targeted-research residual class: an `outputs/<slug>.md` no named class claims. Its `path-pattern` is deliberately the broadest in the corpus, and it never steals a named class's file — the selector ranks a matching pattern by **literal length**, so `examples/*/outputs/food-list.md` outranks this one on any file both match.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C18
artifact: outputs/<slug>.md
schema-version: 1
path-pattern: trips/*/outputs/*.md
path-pattern: examples/*/outputs/*.md
witness: examples/data-architecture-demo/outputs/rooftop-sunset-bars.md

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
- **Coverage.** This class declares `witness:`. The witness is the migrated fixture instance, **not** the `examples/tokyo-2026/` one — that tree is preserved unedited as this release's regression witness. It also demonstrates the residual class resolving correctly in a directory that contains named-class files: every one of those has a longer literal pattern and wins on any file both match, so the witness reaches C18 by construction rather than by ordering. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
