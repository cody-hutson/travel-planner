# Artifact schema — C9 `outputs/transport-brief.md`

The transport brief. `researched`, on the same reading as C8.

The fenced block below is the machine-readable half; `scripts/validate-artifacts.sh` reads it and holds no copy of it. Everything outside the fence is rationale.

```artifact-schema
class-id: C9
artifact: outputs/transport-brief.md
schema-version: 1
path-pattern: trips/*/outputs/transport-brief.md
path-pattern: examples/*/outputs/transport-brief.md
no-witness-because: the only tracked instance is examples/tokyo-2026/outputs/transport-brief.md, inside the worked example this release preserves unedited as its regression witness, so it cannot be versioned here

# The universal block — reference/data-architecture.md § 4.4. No class removes a
# universal field; a class may only narrow one, and each narrowing is stated below.
field artifact: required string
field schema-version: required integer
field trip: required slug
field writer: required slug
field lifecycle: required enum [accumulate-append|rebuilt-each-synthesis|versioned|persist-mutable|output]
field provenance: required enum [human|enrich|derived|operator-provided|third-party|researched]
field publish: required enum [bound|internal|internal-hard|output]
field generated: required date
```

- **`generated` is `required` here.** § 4.4 omits it only on human-authored classes, and this class is `provenance: researched`.
- **`writer` is typed, not enumerated.** The writer assignment lives in `reference/data-architecture.md` § 1.1 and this schema does not restate it — a second copy of that assignment would be a second home for it.
- **The two `path-pattern:` lines are the two trip roots**, not a widened glob. § 1.1 states this class's path trip-relative, and a trip root is either `trips/<slug>/` (the git-ignored working directory) or `examples/<demo>/` (the worked-example stand-in). Anchoring there rather than writing `**/` is what keeps the selector off a file that merely shares a basename with the class — this schema file itself, for one.
- **Coverage.** This class currently declares `no-witness-because:`. The gate reports the witness / no-witness split on every run, so the coverage question is answered by reading one emitted line rather than by auditing nineteen files.

## The entry marker

`../data-architecture.md` § 4.5 rule 2 names this class entry-bearing and fixes the marker's form: **a fenced `artifact-entry` block carrying the entity key and nothing else**, with the entry's prose untouched. One block per entry, directly under that entry's own `**Stream — …**` line:

```artifact-entry
leg: leg-<token>
```

- **The key is the Leg, because it is the only key this class's entity set has.** § 1.1 lists this class's primary entities as *Leg, Signal*. **Leg** is assigned a surrogate key by § 3.4. **Signal is named in that row and nowhere else in the document** — it holds no row in § 2's ten-entity table and no place in § 3.4's assignment, which partitions those ten five/five and closes — so it has no key to carry. The marker takes the one key that exists. Reported rather than closed here: minting an identity for an entity the model does not carry would be deciding identity case-by-case per artifact, which § 3 forbids in terms.
- **The mint point is the writing agent, and this is the one class where that follows from the rule rather than from a stated precedent.** § 3.3 names the hub as Venue's mint point and § 3.1 the hub as Event's; **§ 3.4 declares Leg surrogate and names no mint point for it anywhere in the document.** Under one-writer-per-file the transport agent is the only writer of this artifact, and the Leg record exists nowhere else in the engine, so there is no upstream writer that could mint one first. The agent therefore mints `leg-<token>` on first write of the stream, opaque and day-independent — the same opacity guarantee `evt-<token>` and `ven-<token>` carry. **The corpus statement of that mint point belongs in `../data-architecture.md` § 3, not here**, and is routed rather than authored.
- **The degenerate case is a stream with no source, not a stream with no key** — § 4.5 rule 3. `agents/04-transport.md` § *Arrival Transport* already writes a stream for a traveler whose own window states an arrival no booked leg records, flagged `VERIFY`. That record exists, so it is minted and marked like any other; what is declared absent is the booking, in the prose the `VERIFY` flag governs. There is no `unminted` value for this class — unlike `ven-<token>`, nothing downstream mints this key later.
- **The point-to-point transit matrix carries no marker, and the silence is explicit.** Its rows are legs, but it is table-shaped, and § 4.5's marker-form table assigns **this class** the fenced form on the ground that its entries are prose-shaped — recording in the same table that a fenced block per row *"would restructure a table for no gain"*. The declared-key-column form is assigned to C10, C11 and C13, not to C9. Adopting it here would give one class two marker forms, which § 4.5 does not authorize; adding a fence per row is what its own rationale rules out. **So the matrix ships unkeyed, and whether it should carry one is an architecture question** — it matters because `agents/03-scheduling.md` § *Transit Cost & Routing Signal* consumes those durations numerically, which is the one cross-artifact read in this class that a key would actually serve.
- **Nothing else enters the marker.** Origin letter, airport codes, mode, duration, passenger list, cost and every flag stay in the entry's labelled prose, where they already are. § 4.2's frontmatter/body test decides *frontmatter* versus *body*, and this class's frontmatter is file-scoped — one block, the first bytes of the file — so an entry-level value has no field to become. Only the key does, and § 4.5 rule 2 gives it the marker.
- **The entry's field-label surface is the prompt's**, per § 4.5 rule 3: `agents/04-transport.md` § *Output Format* enumerates the labels every stream carries, and this schema does not restate them — a second copy of that list is a second home for it.

**Declared here, validated by nothing in this release.** The fence grammar in [`README.md`](README.md) admits no entry construct and the validator emits no entry-marker finding code, so this section is prose the gate does not read. Said plainly, so a green check is not mistaken for marker conformance.

**Info-string ownership.** § 4.5 records that the `artifact-entry` info string is shared with the venue-identity migration, **which owns it**; where the two disagree on the exact info string, the venue-identity definition wins. The spelling used here is the one `reference/schemas/activities-list.md`, `food-list.md` and `nightlife-list.md` already ship — one info string, one `<entity>: <key>` line, no second grammar.
