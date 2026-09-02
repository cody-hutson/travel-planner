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

# Per-class fields. § 4.4 admits per-class fields as extensions of the universal
# block; this class declares two, and they are one concern.
field coordination-state: optional enum [none|pending|updated]
field coordination-since: optional date
```

- **`coordination-state` and `coordination-since` are this class's per-class fields, and both are `optional`.** They carry the coordination state ADR-003 § *Decision 3* makes pull-based: there is no server and no push channel, so an async traveler learns a change is pending by opening the site, and the state has to be inside the bytes that were pushed. They pass § 4.2's boundary test on all three questions, and question 3 is the one that decides them on the same ground that admitted `critical-count` on C17 and `status` on C20 — a consumer branches on the value. `reference/site-layout-spec.md` § 3's Coordination Notice is that consumer, and its three-way branch **is** the state. § 7.4 puts the version consequence beyond argument: a schema change that only adds an optional field does not bump `schema-version`, and this one does not.
- **`optional`, with `none` explicit, and the two are not the same reading.** **Absent** is a render built before these fields existed — § 7.2's tolerant read takes that as declared-absent, never as a default value. **`none`** is a build that looked and measured no coordination activity. Collapsing them would make *we did not look* indistinguishable from *we looked and there is nothing*, which is the absence-versus-zero distinction C17 resolves at the schema rather than at every reader. Both render identically — nothing — so the distinction costs the reader nothing and leaves the difference legible to a consumer that needs it.
- **An enum rather than a boolean, and the grammar is the smaller of the two reasons.** The frontmatter grammar is scalar-only over a closed type set of `integer · date · slug · string · list<slug> · enum` and **there is no boolean**, exactly as C17's schema records. The deciding reason is arity: the state is three-valued, so even with a boolean in the grammar it would take two of them, and a pair of booleans admits a fourth combination the state model does not have. A three-member enum is closed by construction and there is nothing to say about the fourth case because there is no fourth case.
- **The enum members are bare tokens, not ADR-003's display phrases.** ADR-003 writes *"change pending"* and *"recently updated"*; those are the strings a reader sees, and `pending` / `updated` are what the machine matches. Keeping them apart is what stops a copy edit to the visible label from becoming a schema change — one fact, one home, and the label's home is the component contract in `reference/site-layout-spec.md` § 3.
- **`coordination-since` is a `date`, so the validator requires exactly `YYYY-MM-DD`.** For `pending` it is the date the proposed change was raised; for `updated` it is the date the confirmed republish landed; for `none` it is omitted. It exists so the *recently updated* state can **decay**: § 3's Coordination Notice compares it against the reader's own clock at open, which is local computation over baked bytes rather than a fetch, so ADR-002 § *Decision 2* is untouched. A window evaluated at build time would freeze at whatever the build decided — a site built six months ago would still announce itself as recently updated — and that is the failure this field's existence prevents.
- **Neither field adds a row to `reference/site-layout-spec.md`'s `publish-contract-artifacts` fence, and adding one would be a defect rather than an extra safeguard.** Group `PB` derives the class filter it compares on **from that fence**, so a row of a class the fence does not already carry widens the filter and drags every § 1.1 row of that class into the comparison. This class is `publish: output`; the fence carries `bound` and `internal-hard` only. The fields are frontmatter on an artifact the fence already governs by its absence, and the fence is a declaration of which artifacts the site build may **read** — not of what a render carries.
- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class declares `no-witness-because:`, and the clause is **terminal rather than pending**. Every other no-witness clause in this corpus named a condition a later slice could remove; this one names a property of the artifact itself. `reference/site-layout-spec.md` places the site source at `outputs/<destination>-travel-site.html` as a *"Source file (plaintext, stays local, git-ignored)"*, so there is no tracked instance to point at and there will not be one — a witness here would be a coverage claim contradicting the artifact's own governing spec. Reading this as a shortfall would invite exactly the wrong repair: committing a site file to satisfy the gate, which is the same trade as editing the frozen fixture. The gate reports the split on every run, so this disposition is visible in the emitted line rather than only here. **What that costs the two per-class fields above, stated rather than left to be discovered:** they are the only per-class fields in this corpus with no witness exercising them, because this class can have none. `scripts/validate-artifacts.sh` still types them — an `optional` field that is present is checked, and `coordination-since` is held to `YYYY-MM-DD` — but no tracked instance demonstrates the three-way branch, and no fixture in this corpus can. What holds the render's conformance instead is `scripts/test-publish-guard.sh` group `T`, which reads the class token and the variant set from `reference/site-layout-spec.md` § 3 and this fence, and grades them against the shipped publish-path projection — a coupling test in place of a coverage fixture, which is the only shape available to a class that can never have one.
