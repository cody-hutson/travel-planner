# Artifact schema — C19 `outputs/<destination>-travel-site.html`

The generated site. The one class whose declaration rides an **HTML comment block** rather than a YAML fence, because the file is HTML (§ 4.5). The field set and its meanings are identical — one grammar, two fences.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C19
artifact: outputs/<destination>-travel-site.html
schema-version: 1
path-pattern: trips/*/outputs/*-travel-site.html
path-pattern: examples/*/outputs/*-travel-site.html
no-witness-because: the class is a generated HTML render, not a source artifact, and reference/site-layout-spec.md § 8 declares it a plaintext source file that stays local and git-ignored; a tracked instance would contradict its own governing spec, and examples/tokyo-2026/README.md records the standing rationale for keeping a render out of the examples tree

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
- **Coverage.** This class declares `no-witness-because:`, and the clause is **terminal rather than pending**. Every other no-witness clause in this corpus named a condition a later slice could remove; this one names a property of the artifact itself. `reference/site-layout-spec.md` places the site source at `outputs/<destination>-travel-site.html` as a *"Source file (plaintext, stays local, git-ignored)"*, so there is no tracked instance to point at and there will not be one — a witness here would be a coverage claim contradicting the artifact's own governing spec. Reading this as a shortfall would invite exactly the wrong repair: committing a site file to satisfy the gate, which is the same trade as editing the frozen fixture. The gate reports the split on every run, so this disposition is visible in the emitted line rather than only here.
