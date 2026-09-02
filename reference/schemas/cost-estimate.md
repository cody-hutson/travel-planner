# Artifact schema — C21 `outputs/cost-estimate.md`

The per-traveler cost projection. `rebuilt-each-synthesis` because it holds no independent state: every figure in it is derived from a cost signal another class masters, so regenerating it is safe and preserving it would only let it drift away from the entries it projects.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C21
artifact: outputs/cost-estimate.md
schema-version: 1
path-pattern: trips/*/outputs/cost-estimate.md
path-pattern: examples/*/outputs/cost-estimate.md
witness: examples/data-architecture-demo/outputs/cost-estimate.md

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
# block; this class declares three — the coverage pair and the verdict that says
# whether the pair is a measurement at all.
field cost-bearing-items: required integer
field priced-items: required integer
field coverage: required enum [measured|unverifiable]
```

## The coverage pair — the two fields, and why they are two

- **`cost-bearing-items` is M, and `priced-items` is N.** M is the number of entries the estimate **could** have read a cost from; N is the number it **did**. Both are `required`, for the reason [`validation-report.md`](validation-report.md) gives for `critical-count`: a `rebuilt-each-synthesis` artifact always carries the field, so `0` is a **measurement** and an absent value is an `A3` violation rather than an ambiguous read. Absence-versus-zero is resolved at the schema instead of at every reader.
- **M is defined independently of N, and that is the whole reason there are two counts.** If M were *the entries that carried a cost signal*, then N = M on every run and the ratio would report complete coverage forever — a number that cannot fail is not a measurement. So M is computed from the class model and N from the reading. `../data-architecture.md` § 4.5.1 fixes the computation: **M ranges over the entries of every class whose § 1.1 Primary-entities cell names `Venue` or `Leg`** — today C5, C6, C7, C9 and C18, and never C8, whose entities are Day, Block and Signal. The set is read out of the column that already holds it, so a class that later gains a priced entity enters the denominator with no edit here.
- **This argument is the corpus's own, and it is reused rather than re-derived.** `agents/06-validator.md` § *Marker coverage* fixes its `E of T` by the same reasoning, in terms: *"were T instead the count of entries carrying an eligibility line, E and T would be equal by construction, the ratio would read `T of T` on every file, and a missing line would make the coverage read better rather than worse."* **An entry is a marker there and here** — a fenced `artifact-entry` block, never a `###` heading and never an ordinal — so the two coverage measurements of one class agree on what they are counting.
- **`coverage` is the third field because a count of zero has two meanings and only one of them is a measurement.** `measured` says M and N are counts over a file whose entries carry markers. `unverifiable` says they are not: the file presents entries and **no** markers, so M could not be computed and `cost-bearing-items: 0` would assert an empty class where the truth is a failed read. This is the validator's own `unverifiable` limb — *"where the file carries entries but no markers at all, T is not measurable: report `unverifiable` and name the condition — never read a marker-less file as `0 of 0`"* — carried into frontmatter so a consumer branches on the verdict rather than re-deriving it. **The limb is reachable, not theoretical:** under § 7.2's tolerant read a pre-migration artifact in a user's git-ignored `trips/` carries no markers at all.
- **No field is the total.** No money figure reaches frontmatter. A total fails § 4.2's boundary test on question 2 — two correct writers rounding, converting or bounding a range differently do not produce the same characters — and on question 3, because nothing in the corpus branches on a trip's cost. The total lives in the body, where the prose can carry the caveats a scalar cannot.

## The rendering rule — `undetermined`, never a total of zero

| State | The body renders |
|---|---|
| `coverage: unverifiable` | **`undetermined`**, no total, **and the condition named** — which entries the selector could not see |
| `coverage: measured`, `N = 0` | **`undetermined`**, and no total |
| `coverage: measured`, `0 < N < M` | a total **carrying its own `N of M` coverage**, never presented as complete |
| `coverage: measured`, `N = M` | a total, **and still `N of M`** |

**`N = 0 ⇒ undetermined` is `../data-architecture.md` § 5.4's parsed-and-empty versus could-not-be-computed distinction, applied one layer up.** An estimate that answered a zero reading with `0` would report *this trip costs nothing* where the truth is *nothing was readable*, and a reader has no way to tell the two apart from the number alone — which is exactly the fail-open § 5.4 refuses at the publish guard.

**`N = M` still states `N of M`** because a reader cannot otherwise distinguish full coverage from a denominator that was never computed. **A partial total is useful; a partial total that looks whole is worse than none.**

**This class ships into a corpus where both `undetermined` limbs are live, and they are different limbs.** In `examples/data-architecture-demo/` the entries carry markers and none carries a cost, so `coverage: measured` with `N = 0`. Every other cost-bearing entry the repository tracks sits inside `examples/tokyo-2026/`, which carries **no markers at all** — it predates the migration and `../data-architecture.md` § 10 pins it by content address, with `scripts/test-artifact-schema.sh` group **FW** asserting it in both directions — so an estimate over that trip would be `coverage: unverifiable`. **The witnessed limb is the first**, which is the right way round: the branch that is hardest to get right is the one with a fixture behind it.

## The rest of the declaration

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `../data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it. What that row says, and does not: the writer is the **hub**, singular. **No spoke gains a read or a write here.** In particular `agents/04-transport.md` § *Input* is unchanged — its item 7 reads `outputs/traveler-model.md` *for the depth signal and for nothing else*, and a cost estimate is not a depth signal.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **`publish: internal`, and the derivation bound is what makes that classification hold.** The estimate may carry a traveller's **`## Group` roster name and a money figure, and nothing else** drawn from any per-traveler source. **No value is ever copied out of a `[THIRD-PARTY]` entry** — not attributed, not anonymized, not paraphrased into a justification. That entry class exists for a person who did not supply their own data and cannot consent to it (`reference/adr/ADR-006-third-party-data-capture.md`), and a cost line explaining *why* a figure is what it is would carry precisely the need or desire that entry holds.
- **The escalation tripwire, stated so a later slice meets it rather than trips it.** If a value in this artifact ever carries a **need-derived or desire-derived justification string** — any text saying which constraint or want a figure serves — then the artifact holds a projection of `outputs/traveler-model.md`'s content, and **its class moves to `internal-hard` and it takes a row in `reference/site-layout-spec.md` § 9.1's `publish-contract-artifacts` fence.** `internal` and `internal-hard` differ on exactly that axis (§ 5.1): `internal-hard` is *never rendered, and carrying values that must not reach a rendered page in any form, including anonymized*. A roster name beside a number does not meet that bar; a roster name beside a number beside a reason does.
- **Under `internal`, no fence row is owed today, and the reason is checkable rather than asserted.** `scripts/test-artifact-schema.sh` group **PB** derives its class selector *from the fence*, and § 9.1's fence declares only `bound` and `internal-hard` rows. An `internal` class is therefore outside PB's selector by construction — adding a row for it would make PB report an unmatched fence entry, which is the group's `only-in-fence` failure direction. The escalation above is what would earn the row.
- **Coverage.** This class declares `witness:`, and it points at `examples/data-architecture-demo/outputs/cost-estimate.md` — a **degenerate instance**, in § 4.5 rule 3's own sense: every field label the class carries is present, with declared-absent values, because that fixture ships no prices by its own § *Depth* rule. It declares `witness:` and never `no-witness-because:`, and the distinction matters: the class **has** a tracked instance, and what that instance witnesses is the `undetermined` branch. A clause would have said the class has no witness, which is false. **No file is added under `examples/tokyo-2026/`** — group `FW` asserts that tree's path set in both directions, so a file added there fails as loudly as a file whose bytes moved. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.

**Declared here, validated by nothing in this release.** The gate reads this fence and grades the frontmatter against it. It does **not** read the body: `cost-bearing-items` and `priced-items` are validated as `integer`s and never against the entries they count, and the `undetermined` rendering rule is prose no finding code reaches. That agreement is a body-level property, and no schema check reaches a body. Said plainly, so a green check is not mistaken for a correct estimate.
