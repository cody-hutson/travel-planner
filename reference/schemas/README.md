# Artifact schemas

One file per in-model artifact class. Each carries prose rationale plus exactly one fenced
`artifact-schema` block, which is the machine-readable half. `scripts/validate-artifacts.sh`
reads those fences and **holds no copy of them**, the same way
`scripts/test-trip-resolution-contract.sh` reads `CLAUDE.md`'s evidence list rather than
carrying one: a guard with its own copy of the thing it guards is a second source of truth,
and it stays green while the document drifts away from it.

The model lives in [`../data-architecture.md`](../data-architecture.md). **This directory
does not restate it.** Where the two could disagree, that document wins and the gate reports
the disagreement (findings `S1` and `S8`).

## Why these are not JSON Schema

The presumed choice was JSON Schema. It was measured and not taken, and the reason is
fail-open rather than taste.

This repository has **no JSON reader at all** — zero tracked `.json` files, zero standalone
`jq` invocations (every `jq` use is `gh api --jq`, `gh`'s own embedded evaluator), and zero
Python. Every route to real JSON Schema validation therefore *adds* a runtime to a repo whose
guard surface is deliberately pure bash:

- `npx ajv-cli` puts an npm fetch on every push of a long-lived release branch — the exact
  dependency-flakiness shape `.github/workflows/publish-guard.yml` has already recorded the
  accepted cost of.
- `python3` adds a second scripting language to a surface whose workflow headers assert
  pure-bash as a property, and it makes the suite's expected-skip set non-empty where every
  other pure-bash suite here has an empty one.
- A hand-rolled JSON reader in bash puts a silently-under-reading parser inside a
  **fail-closed gate**, which is the one place that failure is unacceptable.

So the schema is a fenced literal in a closed line grammar — the pattern this repo already
ships and already CI-guards for `CLAUDE.md § Resolving a trip`. **JSON Schema is deferred,
not foreclosed:** the grammar below is a strict `key: value` line form, so emitting `.json`
from it is a mechanical transform a later slice can add as a derived artifact while keeping
one home.

## The fence grammar

Every line inside an `artifact-schema` fence is one of the forms below. The grammar is
**closed**: a line matching none of them is finding `S2` — a violation of this corpus, not a
limitation of the parser. That is what makes a hand-written extractor safe here. The
extractor's reach *is* the contract.

| Form | Cardinality | Meaning |
|---|---|---|
| `class-id: C<n>` | exactly one | The class's row in `../data-architecture.md` § 1.1. |
| `artifact: <class>` | exactly one | The class string **as § 1.1 spells it**, which is also the value an artifact's own `artifact:` field carries. |
| `schema-version: <integer>` | exactly one | The version *this schema* defines. Starts at `1`. |
| `path-pattern: <glob>` | one or more | Repo-relative. `*` and `**` only; `**` only as the first or last segment. |
| `witness: <path>` | exactly one of these two | An in-repo instance the gate validates. |
| `no-witness-because: <clause>` | | Why this class has none. Spelled as a full clause so it cannot be filled with a token. |
| `field <name>: <required\|optional> <type> [<enum members>]` | zero or more | A field of the class. |
| `# comment` / blank | any | Ignored. |

**Types:** `integer` · `date` (`YYYY-MM-DD`) · `slug` (`[a-z0-9][a-z0-9-]*`) · `string` ·
`enum` (requires the bracketed member list) · `list<slug>`.

**`artifact:` is the § 1.1 class string, not a kebab token.** This is measured rather than
chosen: `templates/trip-context.template.md` and `templates/traveler-intake.template.md`
already ship `artifact: trip-context.md` and `artifact: travelers/<traveler>.md`, and § 4.4
binds the field to "one value per class row in § 1.1". The schema **file's** basename is a
filesystem-safe slug with no machine role — the machine keys are `class-id` and `artifact`,
and both are asserted against the document.

## The artifact grammar (what the gate parses in a selected file)

- **Markdown classes (C1–C18):** the first bytes are `---` and a newline; a closing `---` on
  its own line terminates the block.
- **The HTML class (C19):** the declaration rides an `<!--` … `-->` comment block as the
  first construct, per § 4.5. **The keys are identical.** One grammar, two fences.
- Inside the block every line is `<key>: <value>`, a `#` comment, or blank. `<key>` is
  kebab-case. **`<value>` is a scalar — no nesting and no boolean.**
- **One declared non-scalar, and only one:** the inline `[a, b]` list, which exists for
  C14's section-owned two-value `writer` (§ 4.4). It is admitted **by type on that one
  field**, never by widening the grammar for every class.
- A duplicate key, an unterminated fence, or an out-of-grammar line is finding `A1`.

## How a file is selected

```
SELECTED  =  { files matching >=1 path-pattern of >=1 schema here }        (path arm)
          U  { files declaring `artifact:` that the path arm did not claim } (declared arm)
          -  EXCLUDED
```

**The selector is computed from this directory, never enumerated twice.** Adding a class is
one act: add its schema file. That applies § 1.1's own principle — class source computed,
never enumerated — to the selector itself.

**Every pattern is anchored at a trip root, and that is load-bearing.** § 1.1 states each
class's path *trip-relative*, and this repository has exactly two trip roots:
`trips/<slug>/`, the git-ignored working directory, and `examples/<demo>/`, the worked-example
stand-in. So each class declares two patterns — `trips/*/outputs/food-list.md` and
`examples/*/outputs/food-list.md` — rather than one `**/`-prefixed pattern meaning *anywhere*.
An "anywhere" pattern selects any file that merely **shares a basename** with a class, and
this directory contains two of those: `trip-context.md` and `trip-log.md`. The alternative
fix was an exclusion for `reference/schemas/`, which the corpus does not declare and should
not have to — the selector was over-broad, and that is where the defect was.

**Two matching patterns are ranked by literal length, longest wins.** That is what lets C18
(`outputs/<slug>.md`) ship as a genuine residual class without colliding with every named
`outputs/` class, and it needs no precedence list to maintain.

**The declared arm exists to close a fail-open, and the state it closes is dated.**
`../data-architecture.md` § 11 records that a selector written from § 1.1 alone picks up
files the model has already declared out of scope, "at the one moment they declare a version
and no schema for their class exists yet". Without the declared arm, an artifact naming a
class this corpus does not cover would simply *not be selected* — it would leave the gate
silently. With it, that artifact is finding `A2`. **`A2` is deliberately gated behind the
version check**, so an *unversioned* artifact naming an unknown class still skips: the
tolerant read's first limb is not negotiable, and the gate does not get to invent a second
rule (§ 7.3).

**Exclusions are declared in the document, not decided here.** Each one the validator applies
carries the literal the document uses for it and the section that states it, and the suite
asserts that pairing inside that section (finding `S9`). The glob and the warrant differ where
the document names a path as a *trip* writes it and the gate has to match it anywhere in a
checkout; asserting the glob itself would have been the easier check and the wrong one.

| Exclusion (the gate's glob) | Warrant in the document | Declared at |
|---|---|---|
| `.claude/commands/*.md` | `.claude/commands/*.md` | § 11 — an upstream schema this repo does not own |
| `templates/*.template.md` | `templates/*.template.md` | § 11 — emitters, not instances |
| `examples/*/README.md` | `examples/*/README.md` | § 1.3 — fixture documentation |
| `**/outputs/.staticrypt.json` | `outputs/.staticrypt.json` | § 1.2 C24 — third-party tool state |
| `.publish/**` | `.publish/` | § 1.2 C25 — publish staging clone, never traversed |

**This directory is not on that list, deliberately.** Excluding `reference/schemas/*.md` would
need a warrant the corpus does not carry, and it does not need one: no class path-pattern
reaches this directory, and a schema file carries a *fence* rather than frontmatter, so
neither selector arm ever claims one. That is **asserted** on every run rather than assumed.
An unnecessary exclusion is not free — it is a scope narrowing with nothing behind it.

A user's `trips/` directory is **unreachable by construction rather than by exclusion**:
`.gitignore` carries `trips/*` with `!trips/README.md`, so a CI checkout contains no trip.
The `.staticrypt.json` exclusion is therefore **inert on the CI arm and load-bearing on the
local arm**, which traverses a real trip directory. It is written once, here, and both call
sites read it.

The `templates/` exclusion has the mirror-image shape and it is worth stating, because it
would otherwise read as decoration: it is **inert on the path arm** — no class pattern
matches a `*.template.md` basename — and **load-bearing on the declared arm**, which scans
every file carrying frontmatter and would otherwise resolve both templates as artifacts and
fail them (their `trip:` value is the placeholder `<trip-slug>`, not a slug). The suite
exercises both directions rather than asserting this.

## The skip predicate — inherited, not authored

Stated once in [`../data-architecture.md`](../data-architecture.md) → *Tolerant read* and
*The gate's skip predicate*, and cited here:

> **absent `schema-version` ⇒ version 0 (pre-migration) ⇒ the gate SKIPS.**
> **Declares a version and violates that version's schema ⇒ fails closed.**

The gate keys on the absence of that one key and on nothing else. The two places its
behaviour extends past the literal predicate — `A2` above and `A6` (an in-repo artifact
declaring a version its own in-repo schema does not define) — are **stated as boundary notes
in the validator's source**, so a reader finds them rather than discovering them. Both are
assertions about this repository's internal consistency, and neither can fire on a user's
trip, because the gate cannot see one.

## Coverage — `witness:` / `no-witness-because:`

Every schema declares exactly one of them, and the gate reports the split on every run:

```
CV: <n> witness / <m> no-witness / 19 total
```

That line is the coverage answer. It replaces a nineteen-file manual audit with a read, and
it lets the gate's teeth grow **with** the migration instead of all at once: as each
migration slice versions a class's in-repo instance it flips that class's declaration to
`witness: <path>`, and from that commit forward a stripped or unversioned witness is finding
`S6` — a coverage *regression*, fail-closed — **without re-branching the tolerant-read
rule**, because the failing assertion is the class's own coverage declaration and not the
skip predicate.

At the commit this corpus lands, **all 19 classes declare `no-witness-because:`**, because
nothing has been migrated yet. The reasons are not interchangeable and each schema states its
own:

| Bucket | Classes | Why |
|---|---|---|
| A migratable in-repo instance exists | **2** — C1, C4 | Not yet versioned. The slice that versions it flips the declaration in the same commit. |
| The only instance is frozen | **8** — C2, C5, C6, C8, C9, C10, C15, C18 | Its sole tracked instance sits inside the worked example this release preserves unedited as its regression witness. **Do not edit the fixture to satisfy the gate** — that trades a real regression guard for a green check. |
| No tracked instance at all | **9** — C3, C7, C11, C12, C13, C14, C16, C17, C19 | Nothing to validate until a migrated fixture exists. |

**Each reason is stated as a durable property rather than a ticket number.** A ticket number
is unresolvable to a reader of this repository and goes stale the moment the work ships; the
property behind it stays true and is what the next author actually needs.

**`witness` is deliberately the same word this repo uses for the `examples/tokyo-2026/`
regression witness.** The two senses are the same idea at different scopes — a fixed artifact
that proves something about the system — and inventing a third word would be worse than
reusing one.

## What a green check does not mean

- **Not that any artifact's prose is correct.** The schema constrains frontmatter and
  declared entry markers. It never constrains narrative body content.
- **Not that a user's trips validate.** CI cannot reach them.
- **Not that the guard scripts themselves are lint-clean.** No CI job shellchecks a
  standalone `scripts/*.sh`; `actionlint` lints workflow-embedded shell only.
- **Not, while the table above reads `0 witness`, that any real artifact was validated.**
  The suite renders `VACUOUS` rather than `PASS` in that state and says so out loud.
