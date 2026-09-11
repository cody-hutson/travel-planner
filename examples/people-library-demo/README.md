# People-Library Demo — the durable person record, a group that references two, and a trip that references one

**Illustrative, sanitized example. Not a real person.** Two placeholder people, no real
personal detail, and — deliberately — no passport value of any kind.

A minimal worked example for class **C22 `people/<person>.md`**, the durable person record.
It exists to carry the one thing the schema gate cannot otherwise reach: **a tracked
instance of a class whose real store is git-ignored.**

It carries a second file for a second reason: [`travelers/noor.md`](travelers/noor.md), a
traveller file bearing `person: psn-3c7e`. That is the **composition witness** — the pair
of files across which a composed read can actually be traced — and § *The composition
witness* below says why it lands here rather than in a trip fixture.

**It now carries a third class for a third reason.** [`groups/grp-4a81.md`](groups/grp-4a81.md)
is the witness for **C23 `groups/<group>.md`**, the reusable-group record — a second
cross-trip class whose real store is ignored in exactly the same way. § *The group witness*
below says why it lands in this root rather than opening one of its own.

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

## The horizon record — what the second record witnesses that the first cannot

[`people/psn-9d42.md`](people/psn-9d42.md) is an ordinary instance of the same class, added
for one reason: **the validity horizon needed an instance the schema gate can reach.** The
real store is git-ignored, so an untracked record cannot witness anything; and the record
above cannot witness this particular mark, because it demonstrates the horizon's *home*
field, `Passport`, precisely by leaving it empty.

| Property | Where to look |
|---|---|
| **A `[VALID-THROUGH]` mark actually written** | `## Where you stay` and `## Needs` — the first tracked instance of the mark in this repository |
| **The mark on a `slot`-scoped field** | `Lodging style` — one owner for one fact, so a lapsed value composes `UNKNOWN` and is reported |
| **The mark on a `block`-scoped field** | the first `## Needs` block — one instance among several, so a lapsed block is **retained in the union** and reported, never dropped |
| **A marked and an un-marked block side by side** | `## Needs` — which is what makes the mark visibly a property of the *block* rather than of the section or the file |
| **Still no passport value** | `Passport:` — em-dashed here for exactly the reason it is em-dashed above |

**The horizon is demonstrated on a field that is not `Passport`, and that is a property of
the mechanism rather than a compromise.**
[`../../reference/data-model.md`](../../reference/data-model.md) § *Field Scope → The
classification* carries a per-field `Horizon` axis, so the mark is owed by *fields* rather
than by one field. A passport-specific mechanism would have had **no safe witness at all**:
the only demonstrable instance would have been one this class forbids a tracked file to
carry. A field-general one can be exercised in a tracked file without a passport value ever
entering one.

**`witness:` still names the record above.** The schema's declared witness is unchanged, so
the coverage assertions that key on it are untouched; this record is graded as an ordinary
instance under the same path pattern.

## What it deliberately does not exercise, and why

Named rather than left to be inferred from an absent line:

- **No passport value, and therefore no validity horizon on one.** `Passport:` ships as a
  label with an em dash **in both records**. The field is the class's most sensitive, the
  form asks only for an issuing country and a validity *month*, and a tracked worked example
  is the one place even that must not appear. The horizon mark's grammar is declared in
  [`../../reference/schemas/person-record.md`](../../reference/schemas/person-record.md) and
  its expiry semantics in [`../../reference/data-model.md`](../../reference/data-model.md);
  a fixture cannot demonstrate a mark on a value it must not carry. **This is a permanent
  residual by design, not a gap to close later** — `Passport` is the sole field whose
  `Horizon` axis reads `required`, so its slot path has no tracked witness carrying a real
  horizon and never can.
  [`../data-architecture-demo/travelers/alex.md`](../data-architecture-demo/travelers/alex.md)
  makes the same choice on the same field, for the same reason.
- **No `merged-into:` line, so no merge stub.** The field is optional and this record is a
  live one, not the loser of a merge. A stub is this class's own file rewritten in place —
  same frontmatter plus that one field, with the merge receipt as the body — so it validates
  under this schema without a second shape, and a fixture for it would demonstrate no
  grammar this one does not.
- **No `[THIRD-PARTY]` mark, and this class admits none anywhere.** A durable cross-trip
  record about someone who did not supply their own data is outside the consent boundary
  `../../reference/adr/ADR-006-third-party-data-capture.md` draws. Its absence here is a
  property of the class, not a gap in the fixture.

## The composition witness

[`travelers/noor.md`](travelers/noor.md) is the trip side of the same person. It carries
`person: psn-3c7e` in its frontmatter and **only trip-scoped and destination-scoped
fields** in its body: zero `PERSON` bullets, zero `DEFAULT` bullets, and no `## Needs`
section at all. Between the two files every answerable slot of the intake form appears
**exactly once**, and which file holds a slot is decided by
[`../../reference/data-model.md`](../../reference/data-model.md) § *Field Scope* rather
than by editorial taste.

**Why a trip file lands in the record's fixture, when the record never lands in a trip.**
The section above is right that a person record does not belong inside a trip root, and
nothing here softens it: in a real working tree `people/` is a **sibling** of `trips/`,
outside every trip, which is the scoping the class exists to establish. This fixture
cannot reproduce that layout for the same reason it exists at all — the repo-root store is
git-ignored, so it is **absent from a fresh checkout**, and a witness referencing it would
resolve on an author's machine and dangle in CI. The store-root rule reads
`<trip-root>/people/` **first** and the repo root second, so co-locating the two here makes
the reference resolve without leaving this directory, on any machine, with no dependence on
whether an operator store happens to exist. **The compression of the two roots into one
directory is this fixture's, and the file says so in its own prose so a reader does not
learn the wrong layout from it.**

**Why the reference witness is not the existing traveller fixture.** Two independent
reasons, either sufficient. Giving
[`../data-architecture-demo/travelers/`](../data-architecture-demo/travelers/) a resolving
reference would require a person record inside **that** root — the placement the section
above rejects — and it would **destroy the witness those files already are**: a trip
carrying no reference at all, composing to itself with no store read attempted. Both halves
of the mechanism need a witness, and one of them already exists for free. **Their being
byte-unchanged by the composition work is itself the assertion**, so a diff that touches
them is a regression rather than an improvement.

**What this pair does not exercise.** No divergence and no defect: `noor.md` claims nothing
the record claims, so composition reports **nothing** for it. It is the clean case on
purpose. A contested field, a redundant override, a dangling reference and a tombstone are
each defined in § *Composition — the trip-side read of a durable record*, and none has a
fixture here — stated so the absence reads as scope rather than as coverage.

## The group witness

[`groups/grp-4a81.md`](groups/grp-4a81.md) is a reusable group naming both records above as
its members. It lands **in this root rather than in a new one**, and the reason is the
opposite of the one that sent the person record out of a trip fixture: **a group's members
have to resolve.** A group is a list of person ids and nothing else, so a fixture for it in
any other root would either duplicate the two records it points at or name records the gate
cannot reach — and a witness whose references dangle demonstrates the failure state rather
than the class.

The ignore rule carries `/groups/*` with `!/groups/README.md`, **rooted**, on the same
arrangement and for the same reason as `/people/*` above: it catches the store at the repo
root and does not reach `examples/*/groups/`, so a real group record can never be committed
while this one can. Widening it to `groups/` or `**/groups/` would drop this file from the
index and leave the schema's `witness:` line naming a file the selector never reaches. The
invariant is asserted — see group `V` in
[`../../scripts/test-publish-guard.sh`](../../scripts/test-publish-guard.sh).

| Property | Where to look |
|---|---|
| **The cross-trip sentinel, reused rather than extended** | `trip: cross-trip` in the frontmatter — the same value C22 declares, so § 4.4's narrowing has two member classes and one value |
| **`writer: operator`, not `human`** | the frontmatter — `human` is reserved for a class whose *subject* authors it, and nobody is the subject of a group record |
| **`publish: internal-hard`** | the frontmatter — never rendered, in any form, including anonymized. A set of ids says these people travel together, which no anonymization removes |
| **Identity in the filename, display name in the H1** | `grp-4a81.md` and `# Ski crew`. The id appears nowhere inside the file, because the H1 is the position the identity rule keys on |
| **A member entry is a bare id** | `## Members` — two bullets, each `- psn-<token>` and nothing else. No name beside the id, no role, no note |
| **The closed section set** | the body — one `##` heading and no second one. There is no description slot, and that is the enforcement of *a group holds no personal data of its own* |
| **The membership edge is one-directional** | the two person records — **neither names this group**, and neither changed when it was added |

**What it deliberately does not exercise.** No dangling member and no merge-stub member. Both
are defined branches — a member id resolving to nothing renders `UNDETERMINED`, and one
resolving through a stub is followed to depth 1 — and neither has a fixture here, because a
tracked witness carrying a deliberately broken reference would be graded as the defect it
imitates. Stated so the absence reads as scope rather than as coverage.

**And the property it exists to hold is not one a check can see.** The two person records
above are **byte-unchanged** by this file's arrival, which is the whole of the
one-directional edge: adding a group touches nothing on the person side. A diff that changes
either of them is a regression rather than an improvement.

## What no check reads

**The body is prose, and the schema gate validates frontmatter.** The section count, the
bullet count, the label spellings and the placement of the relayed mark are the properties
this fixture exists to show, and none of them is graded by the artifact-schema gate. They
are stated here so a later editor knows what to preserve, and so a green check on this
commit is not mistaken for conformance to the shape above.
