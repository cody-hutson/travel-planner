# Artifact schema — C20 `outputs/change-summary.md`

The group-facing record of what a re-bake moved. `accumulate-append` for a safety reason rather than a stylistic one: a change nobody has confirmed yet must survive the next synthesis, and only a lifecycle that deletes nothing guarantees that.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C20
artifact: outputs/change-summary.md
schema-version: 1
path-pattern: trips/*/outputs/change-summary.md
path-pattern: examples/*/outputs/change-summary.md
witness: examples/data-architecture-demo/outputs/change-summary.md

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

# Per-class field. § 4.4 admits per-class fields as extensions of the universal
# block; this class declares exactly one.
field status: required enum [pending|confirmed|rejected]
```

- **`status` is this class's only per-class field, and it is `required`.** It passes § 4.2's boundary test on all three questions, and question 3 is the one that decides it, on the same ground that admitted `critical-count` on C17: a consumer branches on the value. The site's "change pending" state is that branch, and so is the organizer-confirm gate that refuses a republish while a change is undecided. Being `required` is the point — a summary always carries the field, so `confirmed` is a **measurement** and an absent value is an `A3` violation rather than an ambiguous read.
- **`status` is artifact-scoped and answers exactly one question: *is a change pending for this trip?*** It is deliberately **not** repeated per dated section. Both declared consumers ask the artifact-level question, and a per-entry copy of the newest entry's disposition would give one fact two homes inside one file — the thing § 4.3 exists to prevent. A file whose `status` reads `pending` has at least one appended entry awaiting a decision; one reading `confirmed` or `rejected` has none.
- **The enum is three values and there is no fourth.** `pending` is the state a summary is written in — the writer never promotes its own output, because the promotion **is** the organizer's decision. `confirmed` and `rejected` are the two ways that decision can land. A `superseded` value was the leading candidate and is rejected: an entry that a later pass overtook is still an entry the group decided on, and inventing a fourth state to mean *we stopped caring* would let a change leave the record without anyone deciding it.
- **`lifecycle: accumulate-append`, and the choice is load-bearing twice over.** A re-bake that shifts nothing appends nothing, so the no-op this class's own emitter is bound to is **structurally** zero bytes rather than a rule the writer has to remember. And nothing in the lifecycle deletes, so a `pending` entry cannot be destroyed by a later pass. `rebuilt-each-synthesis` is disqualified by its own § 6 definition — it *"holds no independent state"*, and a pending decision is exactly independent state. `persist-mutable` is the runner-up, and it loses because an in-place update can overwrite a change nobody confirmed.
- **`publish: internal`, which is a derivation bound rather than a redaction.** ADR-003 § *Decision 2* has the organizer share the proposed change **out of band**, and § *Decision 3* has the site show the *state* rather than the summary, so this artifact is never a publish target. It therefore takes **no** row in `reference/site-layout-spec.md`'s `publish-contract-artifacts` fence: Group PB filters the § 1.1 side to the publish classes the fence carries, and `internal` is not one of them. Adding a row for this class would not make it safer; it would make Group PB disagree with the enumeration.
- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: derived`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob, for the reason C17's schema states in the same words. **On selection this class overlaps C18** `outputs/<slug>.md`, whose `examples/*/outputs/*.md` residual glob also matches this file: `va_select` ranks candidates by literal length and the longest wins, so the named pattern outranks the residual deterministically. No precedence list to maintain, and no path by which C18 swallows the class.
- **Coverage.** This class declares `witness:`. `no-witness-because:` was considered and rejected — its one precedent is C19, warranted as *"a generated HTML render, not a source artifact"*, and nothing about a markdown artifact the hub writes fits that warrant. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
- **What the gate does and does not check.** `status` is validated as a member of the enum, never against whether the change it describes was actually decided by a person. That agreement lives outside every artifact and no schema check reaches it.
