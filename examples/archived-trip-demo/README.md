# Archived trip — the freeze, and the one thing that reaches through it

> **Illustrative, sanitized example. Not a real trip and not real people.**

This is the repository's **only archived trip**. Before it, no fixture carried a
`**Lifecycle:**` marker at all, so the rule in `CLAUDE.md` § *Archived trips — what the
freeze binds* had no subject to be asserted against.

It exists to make **both halves of that rule observable at once**:

- **an ordinary person-record edit leaves this trip untouched** — the trip is frozen,
  and the freeze is asserted by a content pin rather than held as a review convention;
- **an erasure reaches it** — three people asked to be erased, all three had travelled
  on this trip, and the trip carries their erasure.

`scripts/test-artifact-schema.sh` group `AF` is the assertion. It reads the declaration
fenced below and holds no copy of it.

## What the freeze binds, in one sentence

An archived trip receives **no derivation** — no update signal, no regeneration, no
refresh. Erasure is the **one stated exception and the only one**: it is a redaction, it
substitutes and never regenerates, so archived data is reachable by it and by nothing
else. **"Frozen" means underivable, never untouchable.**

## The three model-entry classes, and why all three are here

`reference/adr/ADR-012-people-library.md` records that the two file-less entry classes
fail in **opposite directions** under a regeneration: the `[OPERATOR-PROVIDED]`-alone
entry is **dropped** by a rebuild and its name then re-enters from the roster, while the
entry carrying **both** `[OPERATOR-PROVIDED]` and `[THIRD-PARTY]` is **carried forward
verbatim** and so survives the erasure outright. Both failures are properties **of
regeneration**, and an archived trip does not regenerate — so on this trip all three
classes take **one identical act: substitute**.

That convergence is the finding, and it is only checkable on a fixture that carries all
three classes. No other fixture does: `examples/data-architecture-demo/` states in terms
that it leaves the both-marks branch unexercised.

| Subject | Class | Roster row | Traveller file | Erased |
|---|---|---|---|---|
| `per-4f1c` | first-party — profile filed | yes | yes | yes |
| `per-9a3e` | `[OPERATOR-PROVIDED]` alone — roster row only | yes | no | yes |
| `per-b70d` | both marks — no durable surface anywhere | **no** | **no** | yes |
| Dana | first-party — profile filed | yes | yes | **no — the control** |

**Dana is not decoration.** Group `AF` runs one instrument over the subjects and the
survivor. The subjects must yield no surviving identifying value in the roster cell, the
model entry heading or a constraint's `Applies to:` line; **Dana must yield one in every
one of those places.** A run where both arms come back empty measured nothing.

## Why the both-marks entry appears here, when the sibling fixture declines it

`examples/data-architecture-demo/` names the both-marks branch and leaves it unexercised,
on the ground that a tracked, world-readable worked example is not the place to model
second-hand data about a person. **That reasoning is honoured here rather than
overridden**: the only both-marks entry this fixture carries is **already erased**. It
holds a token, a need and no name — the identifying value was never written into any
tracked byte of this repository. The class is exercised; the person is not depicted.

This matters because it is the class least able to ask for its own deletion — `ADR-006`
restricts it to needs, and it covers a child or a party member on someone else's
booking. It is also the class whose erasure behaviour was reasoned about wrongly twice
during this milestone. Leaving it untested was the larger risk.

## What erasure did to this trip, per location

Every location below held an identifying value and now holds a token. **Nothing was
recomposed**, and that is checkable rather than promised:

| Location | Before | After |
|---|---|---|
| `trip-context.md` § *Group* — the `Traveler` cell | the display name | the token |
| `trip-context.md` § *Hard Constraints* — `Applies to:` | the display name | the token, **never emptied** |
| `travelers/<stem>.md` — the filename stem | the display name | the token |
| `travelers/<stem>.md` — frontmatter `person:` | a record reference | **the line is gone** |
| `outputs/traveler-model.md` — the `##` entry heading | the display name | the token, marked `[ERASED]` |
| `trip-log.md` | the display name | the token |

**The roster cell is the load-bearing one, and it is why a model-only erasure would not
hold.** `agents/00-enrichment.md` § *Traveler identity* makes the roster cell the **name
authority** and calls the model heading and the file stem *projections* of it. So on the
first pass after `/trip-decommission reopen`, the party is re-enumerated from the roster —
and a name left standing there would return **by instruction**, not by an ordering bug.
The freeze is what makes an archived erasure simple; **reopening is where it could still
go wrong**, and it does not go wrong here only because the source-side values were
substituted too.

**Three things erasure deliberately did *not* do.** It did not empty any `Applies to:`
list — an emptied list is a path to a plan that grades compliant while no longer carrying
the need it was built around. It did not change `- **Total travelers:** 3` — erasure does
not reduce the party, because the person travelled. And it did not touch the
`**Lifecycle:**` marker: the trip was never reopened, never re-concluded, and gained no
second closing log entry.

## The `generated:` date is a signature

`outputs/traveler-model.md` carries `generated: 2025-10-08` — the date the model was last
**composed**, while the trip was still active. The erasure that later reached the file
substituted into it and did not rebuild it, so that date did not move. A regeneration
would have moved it.

## The declaration

Group `AF` reads the fence below and holds no copy of it, the same
declaration-in-the-corpus mechanism `reference/data-architecture.md` § 10 uses for the
frozen witness. **`README.md` carries this declaration and is therefore not pinned by
it** — a file cannot hold its own content address. Every other file of the fixture is
pinned, and the path set is compared **in both directions**, so a file added under the
fixture fails as loudly as one whose bytes moved.

If a change here is deliberate, edit the file and **re-pin its row in the same commit**,
so the diff carries the content change and the re-pin side by side.

```archived-erasure-witness
# subject <token> <class> <has-roster-row> <has-traveller-file>
subject per-4f1c first-party            yes yes
subject per-9a3e operator-provided-only yes no
subject per-b70d both-marks             no  no

# survivor <display-name> — the control arm; must be found where subjects are not
survivor Dana

# marker <path> <required-value>
marker examples/archived-trip-demo/trip-context.md ARCHIVED

# pin <content-address> <path>
pin 9243b408390a8eea7f31831c682b81d25bff6fa0 examples/archived-trip-demo/outputs/traveler-model.md
pin 894ea44e7de757c2e19a695fc7f569a1d5114161 examples/archived-trip-demo/travelers/dana.md
pin f9c8798c2f20c97d6b043cb4babc42c5419341ec examples/archived-trip-demo/travelers/per-4f1c.md
pin d3f07a1bc90aa7b447e3e714d3a3aa989433e430 examples/archived-trip-demo/trip-context.md
pin 8c829bc488357ea4ec216f4d71270b83194ffc56 examples/archived-trip-demo/trip-log.md
```

## What this fixture does not settle

**It is a state, not a run.** This engine's agents are prompt files rather than
executable code, so no suite in this repository can execute an erasure and observe its
effect. Group `AF` asserts the **properties a correct erasure leaves behind** — the
tombstone in every location, the entry census a rebuild could not have produced, the
untouched marker, the non-empty constraint rosters — and a mutation to any of them turns
a named assertion red. It does not assert that a future implementation performs them.

**The source-side substitution locus is not settled here.** Whether the display name is
substituted in the derived model's entry heading alone, or in the source-side field as
well, is an open question routed to the erasure verb's own slice. This fixture depicts
both being substituted, because that is what the reopen path requires — but group `AF`
asserts only that the roster cell and the file stem **agree**, which is the property the
post-reopen guarantee actually rests on, and which holds under either resolution.
