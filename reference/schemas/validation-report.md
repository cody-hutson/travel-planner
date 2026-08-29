# Artifact schema — C17 `outputs/validation-report.md`

The validator's findings. `rebuilt-each-synthesis` for the same reason as C14 — a finding against a superseded itinerary is noise.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C17
artifact: outputs/validation-report.md
schema-version: 1
path-pattern: trips/*/outputs/validation-report.md
path-pattern: examples/*/outputs/validation-report.md
witness: examples/data-architecture-demo/outputs/validation-report.md

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

# Per-class field. § 4.4 admits per-class fields as extensions of the universal
# block; this class declares exactly one.
field critical-count: required integer
```

- **`critical-count` is this class's only per-class field, and it is `required`.** It is the count of Critical findings the report carries. It passes § 4.2's boundary test on all three questions, and question 3 is the one that decides it: exactly one consumer branches on validator severity — `CLAUDE.md`'s pipeline flow, which runs *remediation (if criticals found)*. Being `required` is the point: a `rebuilt-each-synthesis` report always carries the field, so `0` is a **measurement** and an absent value is an `A3` violation rather than an ambiguous read. That is absence-versus-zero resolved at the schema instead of at every reader.
- **`warning-count` and `note-count` are deliberately absent.** They are just as closed and just as byte-identical as `critical-count`; they fail question 3 alone, because no consumer in the corpus branches on either value. The resulting asymmetry — one severity declared in frontmatter, the others not — is not an omission. It **is** the structural distinction between a Critical and a Warning that this class owes: a consumer gates on a declared field rather than by parsing prose.
- **No boolean `blocking` field.** It is the cleaner expression of the predicate `CLAUDE.md` actually branches on, and it was the leading candidate until the grammar was checked: the artifact frontmatter grammar is scalar-only with a closed type set of `integer · date · slug · string · list<slug> · enum`, and **there is no boolean**. Faking one as a two-member enum would be a worse artifact than an integer that types natively and carries strictly more information. Recorded because a reader looking only at the consumer would reach for the boolean.
- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `witness:`. `examples/data-architecture-demo/` supplies the first tracked instance this class has ever had, and it is the only witness in the corpus exercising a **per-class** field — `critical-count`. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression. Note what the gate does and does not check: `critical-count` is validated as an `integer`, never against the number of Criticals the body lists. That agreement is a body-level property, and no schema check reaches a body.
