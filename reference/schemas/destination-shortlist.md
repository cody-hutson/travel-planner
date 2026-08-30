# Artifact schema — C4 `outputs/destination-shortlist.md`

The ranked group shortlist produced in IDEATION before a destination exists. `derived` despite a research-capable writer, because its own agent declares it holds no independent state — the classification follows the declared state property, never the producing agent (§ 4.4).

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C4
artifact: outputs/destination-shortlist.md
schema-version: 1
path-pattern: trips/*/outputs/destination-shortlist.md
path-pattern: examples/*/outputs/destination-shortlist.md
witness: examples/ideation-demo/outputs/destination-shortlist.md

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
- **Coverage.** This class declares `witness:`. The clause it replaces stated a **property of the checker** rather than of the artifact — the instance had been migrated and validated by the path arm since it landed, and it was the *declaration* that could not flip, because a declared witness is resolved against whatever tree the validator is invoked on and `scripts/test-artifact-schema.sh`'s control group built a fixture root carrying this corpus and none of the files it points at. That construction artefact is gone: `mk_root()` now copies every declared witness into the fixture root it builds, so a witness declared here resolves in the control group the same way it resolves in the tracked tree. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.

## The entry marker — this class has none, and the silence is deliberate

`../data-architecture.md` § 4.5 rule 2 enumerates the entry-bearing set and its two marker forms. **C4 appears in neither list** — not among the fenced-marker classes, not among the key-column classes. This section states that absence so a later slice does not read it as an oversight and repair it.

The reason is § 4.2's third question. **No consumer branches on any candidate-level value in this artifact**, and that is not an accident of the current corpus — it is a refusal the command surface states twice, in terms:

- `.claude/commands/trip-record.md` — *"Does not read `outputs/destination-shortlist.md` — the chosen value arrives as this verb's argument, and reading the shortlist would give that value a second source."*
- `.claude/commands/trip.md` — *"nothing under `trips/<slug>/outputs/` — the shortlist is the agent's to write and this verb never reads it back."*

So the rank ordinal, the love-count, the lover names, the vibe line, the equity note and the rationale all fail question 3, and a key for a Destination candidate would be a join nothing joins on. Giving this class an entry marker would build the consumer surface the architecture deliberately declines to have — the over-structuring risk this document names, committed on purpose. **This class takes the universal frontmatter block and nothing else**, and its `[DERIVED]` H1 mark is retained per § 4.4.

**Lifecycle, and the disagreement that used to sit on it.** § 1.1 assigns `rebuilt-each-synthesis`, and both consuming sites now agree: the writing agent's own prompt — *"refreshed when they change; it holds no independent state"* — and `.claude/commands/trip.md` — *"That artifact is `rebuilt-each-synthesis`: on a re-run the agent replaces it with the current ranking rather than appending to it."* **This schema follows § 1.1** either way, per § 12's rule that the model wins on the shape; on this class that rule now arbitrates nothing, because nothing dissents. The command file previously described the same artifact as append-only, which is `accumulate-append`; that sentence was the drift and the slice owning that file has since replaced it, so no repair is outstanding.
