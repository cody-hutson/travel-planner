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
field provenance: required enum [human|researched|derived|recorded]
field publish: required enum [bound|internal|internal-hard|output]
field generated: optional date

# Class fields.
field person: optional slug
```

- **`generated` is `optional` here.** § 4.4 states it is omitted on human-authored classes. That is a narrowing of an optional universal field, not the removal of one.
- **`person: optional slug` is the reference into the durable person store, and this class bears it alone.** It names a `people/<person>.md` record by its surrogate id, so it is referential, two writers produce the same characters for it, and resolution branches on it — the three questions § 4.2 asks of a frontmatter key. `reference/adr/ADR-012-people-library.md` § *Decision* 3 is authoritative for the field and for why no other class carries it: a second in-trip join site would widen merge's blast radius past one field and turn discovery's cheap stage into more than a frontmatter read.
- **`optional` is forced, not stylistic, and it is the whole of the compatibility guarantee.** This is the one class the engine **never upgrades** (§ 7.6) — version 0 is permanently valid for it — so a `required person:` would make **every traveller file in existence** non-conforming the moment this line shipped, and no upgrade pass will ever add the field to one. Absence is therefore the pre-existing and permanent state of every file written before the store existed, and the composition rules in `reference/data-model.md` § *Composition — the trip-side read of a durable record* are written so that absence is the **identity case** rather than a branch: no store read is attempted and the composed source equals this file. A pre-existing trip needs no migration because there is nothing for a migration to do.
- **The fence type is `slug`; the value domain is narrower, and the gap between them is a verdict.** `slug` is the § 4.4 vocabulary and is what this fence can express; the minted id is `psn-[0-9a-f]{4}`. So `person: alex` type-checks here and is **not** an id — `MALFORMED`, and it never was an id, so nothing can have been deleted. `person: psn-9999` is a well-formed id resolving to nothing — `DANGLING`, and a record may be missing. Collapsing the two loses the one distinction that tells a typo from a partial erasure, which is why the value domain is stated in the composition rules rather than tightened into this fence.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. The witness carries `artifact: travelers/<traveler>.md` — the class string, angle brackets and all — because that is the value § 1.1 declares and `templates/traveler-intake.template.md` already ships; a witness naming its own path would be finding `A5`. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
- **The `examples/` path-pattern is load-bearing for this class in particular.** Before this fixture there were **no** tracked `travelers/` files at all, so `examples/*/travelers/*.md` had no precedent and matched nothing. Without it a declared `witness:` here would name a file the selector never reaches — a coverage claim the gate is structurally unable to contradict, because the path arm would simply not select it.
