# Command Reference

The whole command surface in one table: every verb each command in `.claude/commands/` takes, the
arguments it expects, and the trip state it requires. It exists because the two surfaces a reader
meets first are both deliberately partial — the picker row names a command's verb *domain*, and the
inline hint enumerates as much of the verb list as the terminal will show. Neither is the surface.
This is.

**The table below is derived. Do not restate it.** Its rows are recomputed from each command file's
own requirement table on every run of `scripts/test-command-taxonomy.sh`, and compared against what
is committed here; a divergence fails the run and the guard prints the block it expected. The
enumeration is the derived region and nothing else — no sentence in this file names which verbs
exist, gives their number, or summarises the set, because a second statement of the set is a second
thing to keep true. Prose here explains how to *read* the table; the table is what says what is in
it.

## How to read it

| Column | What it carries | Where it comes from |
|---|---|---|
| **Command** | The slash command the verb belongs to | the command file's own name |
| **Verb** | The token you type after the command | field 1 of that file's requirement table |
| **Arguments** | The argument signature the verb expects, as its own section heading states it. `—` where the verb takes none | the verb's `## <verb> <signature>` heading |
| **Lifecycle** | The trip lifecycle state the verb requires — a verb declaring `ACTIVE` refuses on an archived trip | the requirement table |
| **Mode** | The planning mode(s) the verb runs in, or `any` | the requirement table |
| **Destination** | Whether the trip's destination must be settled | the requirement table |
| **Depth** | The gate on the § *Resolving a trip* ladder in [`CLAUDE.md`](../CLAUDE.md) that the command's contract header declares | the requirement table |

A command's own file is still the authority on what a verb *does*: what it reads, what it writes,
what it refuses and why. This table says which verbs exist and what each one needs before it will
run — it does not replace the per-verb sections, and a verb's own section is where its behaviour is
stated.

`/trip-new` takes a destination and year rather than a verb; its single row records the create
branch so the table stays total over the command surface.

Once `trips/` holds more than one trip, every command also takes `--trip <slug>` to say which.

## The surface

<!-- command-surface: derived — regenerate by running scripts/test-command-taxonomy.sh -->
| Command | Verb | Arguments | Lifecycle | Mode | Destination | Depth |
|---|---|---|---|---|---|---|
| `/trip` | `status` | — | ANY | any | any | G8 |
| `/trip` | `plan` | — | ACTIVE | IDEATION, DISCOVERY, ENRICHMENT | DECIDED | G8 |
| `/trip` | `replan` | — | ACTIVE | DISCOVERY, ENRICHMENT, ITERATION | DECIDED | G8 |
| `/trip` | `reorder` | — | ACTIVE | ITERATION, RESEQUENCING | DECIDED | G7 |
| `/trip` | `research` | — | ACTIVE | IDEATION, DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | G7 |
| `/trip` | `check` | — | ACTIVE | any | DECIDED | G7 |
| `/trip` | `ideas` | — | ACTIVE | IDEATION | UNDECIDED | G7 |
| `/trip` | `site` | — | ACTIVE | DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | G8 |
| `/trip` | `schema` | — | ANY | any | any | G7 |
| `/trip-decommission` | `temporary` | — | ACTIVE | any | any | G8 |
| `/trip-decommission` | `archive` | — | ACTIVE | any | any | G8 |
| `/trip-decommission` | `reopen` | — | ARCHIVED | any | any | G8 |
| `/trip-new` | `new` | — | not read at this depth | not read at this depth | not read at this depth | G2 |
| `/trip-publish` | `update` | — | ACTIVE | any | any | G8 |
| `/trip-publish` | `list` | — | ANY | any | any | G0 |
| `/trip-record` | `profile` | `<name>` | ACTIVE | any | any | G8 |
| `/trip-record` | `person` | `<name>` | ACTIVE | any | any | G8 |
| `/trip-record` | `travelers` | — | ACTIVE | any | any | G8 |
| `/trip-record` | `destination` | `<value...>` | ACTIVE | any | any | G8 |
| `/trip-record` | `mode` | `<MODE>` | ACTIVE | any | any | G8 |
| `/trip-record` | `group` | `[<name>]` | ACTIVE | any | any | G8 |
| `/trip-record` | `fact` | `<statement>` | ACTIVE | any | any | G8 |
| `/trip-record` | `.publish-slug` | `<name>` | ACTIVE | any | any | G8 |
| `/trip-record` | `event` | `<id> <state>` | ACTIVE | any | any | G8 |
| `/trip-record` | `log` | — | ACTIVE | any | any | G8 |
| `/trip-record` | `link` | `<name> <person-id>` | ACTIVE | any | any | G8 |
| `/trip-record` | `unlink` | `<name>` | ACTIVE | any | any | G8 |
| `/trip-record` | `promote` | `<name> <field-label>` | ACTIVE | any | any | G8 |
| `/trip-record` | `erase` | `<person-id>` | ANY | any | any | G8 |
<!-- /command-surface -->

## Where this fits

The command files own the taxonomy — [`reference/adr/ADR-007-command-entry-point.md`](adr/ADR-007-command-entry-point.md)
§ 3 settled that, so a restatement of the verb set anywhere else would be a surface that drifts. This
file is a restatement, and it is committed only because it is *derived and asserted* rather than
remembered: the same guard that grades the command surface recomputes the region above and fails on a
divergence, so the eighth enumeration is held to the standard the other seven already meet.

Three publish actions stay deliberately outside this surface and remain terminal commands you run
yourself — creating the published repo, rotating its passphrase, and deleting it. ADR-007 § 4
dispositions every publish form one way or the other and records the reasoning.

**When a verb is added, removed or renamed**, the command file's requirement table is the thing to
edit. Run `./scripts/test-command-taxonomy.sh`; it will fail on the stale region here and print the
replacement block. Paste it in. Nothing in this file is maintained by hand except the prose.
