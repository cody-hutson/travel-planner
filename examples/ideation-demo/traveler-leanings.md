# Destination-ideation demo — input leanings

The Destination Ideation agent reads each traveler's leanings from the
reconciled `outputs/traveler-model.md` (enrichment carries them there). This
file is a minimal stand-in showing just the three leaning fields the agent
uses, for four travelers deciding where to go together. No destination is set.

Being a partial projection rather than an instance, this file carries **no artifact
frontmatter** and is not a schema witness for `outputs/traveler-model.md`. Declaring
that class on a file holding three of its fields would claim a conformance the file
does not have; `reference/data-architecture.md` § 1.3 disposes of it on exactly those
terms, and no class path-pattern selects it.

## Ana
- **Would love:** the Portuguese coast; Italy
- **Rather skip:** —
- **Trip vibe:** food + coastal, slow mornings

## Ben
- **Would love:** Italy; Japan
- **Rather skip:** —
- **Trip vibe:** city + culture, museums

## Cyra
- **Would love:** Japan; Portugal
- **Rather skip:** anywhere very hot in summer
- **Trip vibe:** nature + food

## Dev
- **Would love:** Iceland
- **Rather skip:** Italy (been twice recently)
- **Trip vibe:** nature + quiet, few crowds
