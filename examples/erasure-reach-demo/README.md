# Erasure's reach — an active trip after an erasure

> **Illustrative, sanitized example. Not a real person.** Every person here is invented.

This fixture is the state `/trip-record erase` leaves on an **active** trip. It is drawn so that
the reach rows for `trip-context.md` and `outputs/traveler-model.md` each have something to
grade, and `scripts/test-artifact-schema.sh` arms `ER22` and `ER23` read the declaration below
and hold no copy of it. The archived half of the same rows is `../archived-trip-demo/`.

- **Reached** — the roster row and its prose, an origin's traveller slot, a constraint's
  `Applies to:` roster, a mobility note, a health note and the line nested under it, and every
  line of the derived model's body, the need of the party member recorded
  `[OPERATOR-PROVIDED]` + `[THIRD-PARTY]` included, whose text named the subject.
- **Reported, and left standing** — a line of `## Trip Style`, which states a fact about the
  trip, and the `Allergies:` list, where the subject's name is also a food. The name is still
  in both because those places are reported rather than rewritten, and the receipt names each
  with its count.
- **Kept by the bounds** — the same word in lower case, inside a health note the erasure does
  rewrite, and inside a longer word. A correct erasure leaves each of them alone.

**The subject's name on this trip is not the name on their record**, as a trip's may not be
(`reference/data-model.md` § *The display name has one authority*). The erasure matches the
trip's name here, and the declaration carries both, so the arm can show it keys on the right
one.

**The subject's name appears in this fixture on purpose.** It is invented, and a surviving
occurrence in a place the table reports is part of what this fixture shows. **The party member
recorded through the operator carries a label rather than a name**, the discipline
`../archived-trip-demo/` keeps for that class: the class is exercised, and no person is
depicted.

## The declaration

```erasure-reach-witness
# subject <token> <name-on-this-trip> <record-display-name>
subject per-2c9e Basil Vasileios
# survivor <display-name> — the control; found where the subject's name is not
survivor Odile
# third-party <label> — the both-marks entry whose text named the subject
third-party Companion
# keep <file>#<section-slug>[:<label-slug>] <string> <count> — occurrences the table does not rewrite
keep trip-context.md#trip-style Basil 1
keep trip-context.md#dietary-health:allergies Basil 1
keep trip-context.md#dietary-health:other-health-notes basil 1
keep outputs/traveler-model.md#body Basilica 3
```

A section slug is its heading with any trailing bracketed marker removed, lower-cased, every
character outside `a-z`, `0-9` and the space dropped, and each run of spaces turned into one
hyphen; a label slug is the label read the same way. A `:<label-slug>` narrows the region to
that labelled bullet and the lines that continue it — every following line up to the next line
that begins at column 0, a blank line or a heading, nested bullets included. `#body` is every
line of the file after its frontmatter that is not a `##` heading.
