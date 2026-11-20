# Artifact schema — C24 `outputs/traveler-presence.md`

Each traveller's planning-day window, one entry per first-party roster member: a heading keyed by the roster's display name, two warrant tokens, and three window lines. `internal`, not `internal-hard`: it carries roster names, warrant tokens, local instants, day counts and a zone delta, and no entry carrying `[THIRD-PARTY]` (`reference/adr/ADR-028-derived-planning-day-block-owners.md` § 2, *Publishability*).

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C24
artifact: outputs/traveler-presence.md
schema-version: 1
path-pattern: trips/*/outputs/traveler-presence.md
path-pattern: examples/*/outputs/traveler-presence.md
witness: examples/two-origin-demo/outputs/traveler-presence.md

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
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it.
- **The two `path-pattern:` lines are the two trip roots**, as [`traveler-model.md`](traveler-model.md) states for its own: a trip root is `trips/<slug>/` or `examples/<demo>/`, and anchoring there keeps the selector off a file that only shares the basename. Until this schema existed the residual targeted-research class claimed the file by its `trips/*/outputs/*.md` selector, which is why the class and its schema land together.
- **The body is not declared here.** The entry headings and the lines beneath each are rules of the file's writer contract, and this fence types the frontmatter alone, as every schema in this directory does. A second statement of those lines here would be a second home for them.
- **Coverage.** This class declares `witness:`. `examples/two-origin-demo/` supplies it: its four travellers' windows, derived from the answers that example's `README.md` tabulates, as of the witness's `generated:` date. Sam's `Full + partial` is clipped to the trip's own days, though Sam's window opens a day before the trip begins. From this commit a stripped or unversioned witness is finding `S6`, a fail-closed coverage regression.
