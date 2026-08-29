# Artifact schema — C3 `travelers/<traveler>.md`

The traveler's own file, human-authored. It is the one class the engine **never upgrades** (§ 7.6): version 0 is permanently valid for it, because an upgrade pass that rewrote a person's own words to satisfy a schema would breach the engine's most explicit ownership boundary.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C3
artifact: travelers/<traveler>.md
schema-version: 1
path-pattern: trips/*/travelers/*.md
path-pattern: examples/*/travelers/*.md
witness: examples/data-architecture-demo/travelers/alex.md

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
- **Coverage.** This class declares `witness:`. The witness carries `artifact: travelers/<traveler>.md` — the class string, angle brackets and all — because that is the value § 1.1 declares and `templates/traveler-intake.template.md` already ships; a witness naming its own path would be finding `A5`. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
- **The `examples/` path-pattern is load-bearing for this class in particular.** Before this fixture there were **no** tracked `travelers/` files at all, so `examples/*/travelers/*.md` had no precedent and matched nothing. Without it a declared `witness:` here would name a file the selector never reaches — a coverage claim the gate is structurally unable to contradict, because the path arm would simply not select it.
