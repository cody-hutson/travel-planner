# Returning-party set — a trip being planned, and the archived trips its travellers came from

> **Illustrative, sanitized example. Not a real trip and not real people.**

This directory and the pair of archived roots beside it are a single fixture set, read together.
It is the state `/trip-record past-coverage` is drawn against: a traveller on a trip that is
still being planned, linked to a durable person record, whose earlier trips are archived and
carry the coverage their plans last recorded.

| Root | What it is |
|---|---|
| `examples/returning-party-demo/` | the trip being planned. Its trip context carries no `**Lifecycle:**` marker line, so it is active, and it has no `outputs/` |
| `examples/returning-party-first-demo/` | an archived trip with a frozen `outputs/satisfaction-metrics.md` |
| `examples/returning-party-second-demo/` | an archived trip that an erasure has reached, with a frozen `outputs/satisfaction-metrics.md` |

`scripts/test-artifact-schema.sh` group `RP` reads the declaration fenced at the foot of this
file and holds no copy of it. It grades the states the set declares, never the verb: no suite
executes a verb.

## Where the person records are

The linked travellers reference records that are tracked in `../people-library-demo/people/`.
**Those records are not copied into this set.** A second tracked copy of a person record would be
a second source for the same person.

**So the references do not resolve in place in this tree.** The store-root rule looks for a
`people/` directory inside the trip's own root and otherwise in the data root. These roots carry
none of their own, and no data root holds them: the engine's own `people/` ships a README and no
record, and is never the store. They do resolve in an assembled data root, where `people/` is a
sibling of `trips/` — the layout an operator has, and the one an exercise builds by copy. Arm
`RP3` closes the gap a reader would worry about: every reference in this set must name a record
that is tracked under the declared store, and that record must be live rather than a merge stub.

## What each traveller is for

| Traveller | On the trip being planned | On the first archived trip | On the second archived trip |
|---|---|---|---|
| Noor, linked to `psn-3c7e` | a linked traveller the view can be asked about | a bearer with rows in the coverage table, so the trip reads as tallies | a bearer with rows, so tallies again. A row among them carries a per-day reading, and it is counted by its overall verdict cell alone |
| Rhian, linked to `psn-9d42` | a linked traveller the view can be asked about | a bearer with rows, so tallies | a bearer with no row under her key, so the trip *holds no outcome record* for her |
| Jordan, who carries no reference | asked about, the view answers `NO-REFERENCE` | rows in the coverage table that belong to no reference and reach no tally | not on this trip |
| `per-7c1e`, an erasure token | — | — | a roster cell that is a token, which is the cell the erasure reading is printed for, and rows in the coverage table that reach no tally |

The first archived trip writes its verdict cells in bold and the second writes them plain, so a
reader that strips emphasis and a reader that does not disagree across the pair.

## What this set does not carry, and why

- **No itinerary, traveller-model or event-status file.** The relation the view reports,
  `plan-to-coverage`, orders a trip's coverage file against those files by their stamps. A
  checkout sets every file's stamp, so a tracked set would carry no order worth reading, and the
  suite pins by name which example roots may carry an itinerary. As tracked, the relation reads
  `UNDETERMINED` on each archived root, naming the files it could not list. An exercise supplies
  them as empty placeholders, stamped in a stated order.
- **No dangling reference, no merge stub and no second bearer for a person.** A tracked file in
  any of those states would present as the defect it imitates. Each is a single-file change in an
  exercise root.
- **No trip log.** The view never reads a trip log.

## The declaration

```returning-party-fixture
# store <root> — where the records this set references are tracked
store examples/people-library-demo

# trip <root> <lifecycle>
trip examples/returning-party-demo        ACTIVE
trip examples/returning-party-first-demo  ARCHIVED
trip examples/returning-party-second-demo ARCHIVED

# bearer <root> <traveller-file-stem> <person-id | none>
bearer examples/returning-party-demo        noor   psn-3c7e
bearer examples/returning-party-demo        rhian  psn-9d42
bearer examples/returning-party-demo        jordan none
bearer examples/returning-party-first-demo  noor   psn-3c7e
bearer examples/returning-party-first-demo  rhian  psn-9d42
bearer examples/returning-party-first-demo  jordan none
bearer examples/returning-party-second-demo noor   psn-3c7e
bearer examples/returning-party-second-demo rhian  psn-9d42

# tally <root> <traveller-file-stem> <tier> <covered> <not-covered>
tally examples/returning-party-first-demo  noor  anchor        1 0
tally examples/returning-party-first-demo  noor  wish          1 1
tally examples/returning-party-first-demo  noor  nice-to-have  1 0
tally examples/returning-party-first-demo  rhian anchor        0 1
tally examples/returning-party-first-demo  rhian wish          1 0
tally examples/returning-party-second-demo noor  anchor        1 1
tally examples/returning-party-second-demo noor  wish          1 0

# no-record <root> <traveller-file-stem> — a bearer the trip's coverage table has no row for
no-record examples/returning-party-second-demo rhian

# token <root> <yes | no> — whether the roster's first column carries an erasure token
token examples/returning-party-first-demo  no
token examples/returning-party-second-demo yes
```
