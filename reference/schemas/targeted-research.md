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
- **Reachability — the class is selector-reachable and has no producer, and that is the decided position rather than an omission.** Nothing in the engine writes an `outputs/<slug>.md`. The targeted-research verb, `.claude/commands/trip.md` § *research*, dispatches one spoke *"writing exactly the file that row names"* — the single path in that spoke's `CLAUDE.md` roster row — and appends to it; each spoke's own `## Output Format` names the same one file. `CLAUDE.md` § *Output Versioning* is what makes that the right behaviour: research accumulates in one place per spoke so the hub reads the whole record, and a per-topic file would split it. **So the two instances this corpus holds are fixtures** — `examples/tokyo-2026/outputs/casual-dining-family.md`, disposed of in `reference/data-architecture.md` § 1.3, which *depicts* a targeted re-run, and this class's own witness in the bullet below — **and neither was produced by the surface as it stands.** **What the class is for is the selector, not a writer:** it is the residual arm that gives any `outputs/*.md` no named class claims a schema to resolve against, instead of falling through the selector unvalidated — which is the property the witness demonstrates. A slice that wants C18 produced changes the append rule first and this bullet second; until then, *declared, selector-reachable, unproduced* is the whole of its status, and `reference/data-architecture.md` § 7.6 records what that means for the upgrade contract.
- **The entry marker, and why this class is the one that decided the cost amendment.** `reference/data-architecture.md` § 4.5 places C18 in the **fenced `artifact-entry`** row of the marker-form table, so its entries carry the same `venue: ven-<token>` block the named research classes carry, and this schema does not re-spell it. § 4.5.1 amended rule 2 to admit one optional `cost:` line in that form, and **C18 admits it — which is not a courtesy extension but the case that settled the rule's scope.** A residual class exists to give any `outputs/*.md` no named class claims a schema to resolve against; a targeted re-run of the food agent writes exactly the shape C6 writes, resolves here by the longest-literal-pattern rule, and would be **out of grammar at the one moment the residual exists to catch it** had the amendment been keyed to a roster of priced classes rather than to the marker form. The residual can never admit less than the classes it stands in for.
- **Coverage.** This class declares `witness:`. The witness is the migrated fixture instance, **not** the `examples/tokyo-2026/` one — that tree is preserved unedited as this release's regression witness. It also demonstrates the residual class resolving correctly in a directory that contains named-class files: every one of those has a longer literal pattern and wins on any file both match, so the witness reaches C18 by construction rather than by ordering. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
