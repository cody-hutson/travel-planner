# People-Library Demo — the durable person record

**Illustrative, sanitized example. Not a real person.** One placeholder person, no real
personal detail, and — deliberately — no passport value of any kind.

A minimal worked example for class **C22 `people/<person>.md`**, the durable person record.
It exists to carry the one thing the schema gate cannot otherwise reach: **a tracked
instance of a class whose real store is git-ignored.**

## Why this is a new fixture root rather than a file in an existing one

Every other class's witness lives in a **trip** root —
[`../data-architecture-demo/`](../data-architecture-demo/) for most of them. This class has
no trip. Placing a cross-trip record inside a trip fixture would put the record in the one
place the design says it never goes, and would re-teach the scoping the class exists to
break: a person record is *referenced from* trips, never *inside* one.

So the fixture mirrors the real store's shape instead — a `people/` directory holding one
record — and this README sits beside it exactly as `people/README.md` sits beside the real
store's contents.

## Why the record is tracked when every real one is ignored

`.gitignore` carries `/people/*` with `!/people/README.md`, **rooted**. The leading slash is
what makes this fixture possible: the rule catches the store at the repo root and does not
reach `examples/*/people/`, so a real record can never be committed while this one can.

That is a coupling worth stating plainly, because breaking it is silent. Widening the ignore
rule to `people/` or `**/people/` would drop this file from the index; the schema's
`witness:` line would then name a file the selector never reaches, and the gate would report
coverage it is structurally unable to check. The invariant is asserted — see group `U` in
[`../../scripts/test-publish-guard.sh`](../../scripts/test-publish-guard.sh).

## What the record demonstrates

| Property | Where to look |
|---|---|
| **The cross-trip sentinel** | `trip: cross-trip` in the frontmatter — the narrowing that lets a class with no trip sit inside a model whose universal block requires one |
| **`publish: internal-hard`** | the frontmatter — never rendered, in any form, including anonymized |
| **Identity in the filename, display name in the H1** | `psn-3c7e.md` and `# Noor`. The id appears nowhere inside the file and the H1 carries the name and nothing else, because the normalized H1 is the key a creation collision is refused on |
| **Eight sections, seventeen bullets, plus the H1** | the body — eighteen durable answers, with every label byte-identical to the trip intake form's |
| **The four dropped sections** | their absence, explained in the record's own prose — each is dropped by field classification, not by editorial choice |
| **Field-scoped provenance** | `## Needs` — one relayed need and one self-authored one, in the same record. This is the case record-level provenance cannot express, and the reason the mark is per-field |
| **The needs-only consent boundary** | that the relayed mark appears **only** inside `## Needs`, and nowhere else in the file |
| **The declared-absence convention** | the em-dashed fields — a skipped field keeps its line and takes an em dash, so a reader sees *not answered* rather than inferring from a missing label |

## What it deliberately does not exercise, and why

Named rather than left to be inferred from an absent line:

- **No passport value, and therefore no validity horizon on one.** `Passport:` ships as a
  label with an em dash. The field is the class's most sensitive, the form asks only for an
  issuing country and a validity *month*, and a tracked worked example is the one place even
  that must not appear. The horizon mark's grammar and expiry semantics are declared in
  [`../../reference/schemas/person-record.md`](../../reference/schemas/person-record.md),
  which is their home; a fixture cannot demonstrate a mark on a value it must not carry.
  [`../data-architecture-demo/travelers/alex.md`](../data-architecture-demo/travelers/alex.md)
  makes the same choice on the same field, for the same reason.
- **No `merged-into:` line, so no merge stub.** The field is optional and this record is a
  live one, not the loser of a merge. A stub is this class's own file rewritten in place —
  same frontmatter plus that one field, with the merge receipt as the body — so it validates
  under this schema without a second shape, and a fixture for it would demonstrate no
  grammar this one does not.
- **No trip references it.** The reference is a `person:` field on a traveller's own file
  inside a trip, and it belongs to the trip fixture rather than here. A record is complete
  and valid with nothing pointing at it — that is the ordinary state of a person's first
  record.
- **No `[THIRD-PARTY]` mark, and this class admits none anywhere.** A durable cross-trip
  record about someone who did not supply their own data is outside the consent boundary
  `../../reference/adr/ADR-006-third-party-data-capture.md` draws. Its absence here is a
  property of the class, not a gap in the fixture.

## What no check reads

**The body is prose, and the schema gate validates frontmatter.** The section count, the
bullet count, the label spellings and the placement of the relayed mark are the properties
this fixture exists to show, and none of them is graded by the artifact-schema gate. They
are stated here so a later editor knows what to preserve, and so a green check on this
commit is not mistaken for conformance to the shape above.
