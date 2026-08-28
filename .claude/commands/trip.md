---
description: The trip entry point. Resolves the trip, then runs the verb you typed.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(grep:*), Read, Task, Edit, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), NotebookEdit]
---

# /trip

`/trip [verb] [--trip <slug>] [verb args...]`

The verb is the one the user typed, or — on an empty argument string — the `status` default
step 3 declares, which is the one verb this file supplies. Nothing in it reads the wording of
the request to decide one.

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`

## Trip records

!`grep -H -E '^\*\*Current mode:\*\*|^- \*\*Primary destination:\*\*|^\*\*Lifecycle:\*\*' "${CLAUDE_PROJECT_DIR}/trips"/*/trip-context.md 2>&1`

## Contract header

```
Contract: CLAUDE.md § Resolving a trip
contract-depth: G8
population-role: RESOLVE
```

| verb | lifecycle | mode | destination | depth |
|---|---|---|---|---|
| status | ANY | any | any | G8 |
| plan | ACTIVE | IDEATION, DISCOVERY, ENRICHMENT | DECIDED | G8 |
| replan | ACTIVE | DISCOVERY, ENRICHMENT, ITERATION | DECIDED | G8 |
| reorder | ACTIVE | ITERATION, RESEQUENCING | DECIDED | G7 |
| research | ACTIVE | IDEATION, DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | G7 |
| check | ACTIVE | any | DECIDED | G7 |
| ideas | ACTIVE | IDEATION | UNDECIDED | G7 |
| site | ACTIVE | DISCOVERY, ENRICHMENT, ITERATION, RESEQUENCING | DECIDED | G8 |

The ladder this cites is stated in one place and is not restated here. The blocks above
have already run, and their output is the whole of the trip state this file **resolves
against**: no verb re-runs either block and no verb re-derives what they already carry.

**The `destination` cell.** `UNDECIDED` is the value `G6` yields on a placeholder. A cell
reading `DECIDED` names `G6`'s decided disposition — the complement of `UNDECIDED` in the
value set the contract declares for `trip.destination`, which is the value or `UNDECIDED` —
and it is written as a value rather than as `any` because `any` admits the
non-nominal state by `G7`'s own rule, and a verb that must not run without a settled
destination has to say so in its own row. The token is a convention of this file until the
contract registers one for that disposition; nothing reads the column mechanically, so the
convention costs nothing while it waits, and any token naming `G6`'s decided disposition
serves in its place.

**The read ceiling, stated for this file.** Exactly two prohibitions hold file-general, and
both are checkable against every `**Reads:**` line below: **no verb reads `trip-context.md`
in full** — a verb that reads that file at all names the block it reads — and **no verb reads
`trip-log.md`**, which is read only by agents a verb dispatches and is attributed to them
there. **There is no third file-general prohibition, and in particular none over
`trips/<slug>/outputs/`:** `check` takes an existence probe there and `site` reads its content
sources, its status source and its own outgoing markup, each declared in that verb's own line.
Stating one would put a second description of the read scope beside the `**Reads:**` lines,
free to disagree with them — which is the whole reason the ceiling is this short. What a verb
reads is declared in its own `**Reads:**` line, which is its whole read scope, and a read no
section names is out of scope whether or not a file-general prohibition reaches it. The two
above are stated because they bind verbs whose lines do not mention those files at all.

Each pre-executed block above is a tool grant this file has to hold, and each is held for
a use the table above names: the listing block for `Bash(ls:*)`, and the record block for
`Bash(grep:*)`, which reads the lifecycle, the mode and the destination by value. Neither
grant is speculative and neither is unused. **The header block fixes how many pre-execution
blocks this file carries, and it already carries all of them** — no slice adds another, and a
verb needing to know whether an artifact exists asks at verb time with `Read` or
`Bash(ls:*)`, never with a block.

## Standing clause — binding every verb of this command, present and future

This clause sits outside every verb section on purpose: a rule written inside one verb
protects only the verbs that existed when it was written.

`/trip` never publishes. It never invokes `scripts/publish-trip-site.sh` — not directly,
not through `bash` or `sh`, not through any wrapper, alias or generated command line. It
never sets `ALLOW_PLAINTEXT`. It never passes `--yes` to `unpublish`. Where publishing is
what the user wants, name `/trip-publish` and stop; do not reach the script from here.

**Never overwrites and never deletes existing trip content.** `ADR-007` §2 bound 5 holds on
every verb here: a trip's working tree is git-ignored and carries no history, so a clobber is
recoverable from nothing. `Write` is reached where the target path does not exist. `Edit`
is reached where it exists — either only the named lines change, or the write adds lines that
were not there before while changing none that were. The probe that establishes which condition holds runs before either tool is
reached; it is a read, so the verb's `**Reads:**` line declares it. Where a derived artifact
genuinely must be replaced, the version being replaced is preserved first, or what will not
survive is said before writing. Regenerating a file, rewriting it from scratch, reordering it
or deleting a unit of it is none of these shapes and takes no licence from them.

**Writes only under `trips/<slug>/`**, where `<slug>` is `trip.slug` exactly as `E1` spelled
it. No path is ever built from the `--trip` value.

**The block of `trip-context.md` a verb of this file may claim.** `CLAUDE.md` →
*Write ownership — trip-context.md, block by block* carries a carve-out over `## Mode`.
**Read the membership of that carve-out live from that section.** It is not written into this
file and no verb section here carries a copy of it, because a copy is a second source able to
disagree with the enumeration that governs it. A verb the carve-out admits writes
`Current mode` and `Mode notes` and no other byte of that file. Every other verb of this file
writes no byte of it at all and says so in its own section. A `[ENRICH]` field written by an
agent a verb dispatched is that agent's under *ownership follows the writer, not the caller*,
and is not this file's write.

**Where a mode write lands in a verb's chain — one rule, and it places every one of them.** A
verb the carve-out admits writes the mode at the first point in its own chain where both of
these hold: the transition is **observable in an artifact this run has already produced**, and
**no leg still to run is one that must run under the outgoing mode**. It never lands later
than the first leg of that chain that branches on the incoming value — a mode written after
the legs that read it is the silent no-fire the carve-out exists to end.

The rule is stated here once and **applied** rather than restated. A verb section names the
value, the artifact whose production makes the transition observable, and the leg of its own
chain that produces that artifact; the placement follows from the rule. A section states that
placement only as the conclusion of the derivation it just showed — a placement carrying its
derivation cannot drift from the rule without the drift being visible in the same sentence,
which a bare placement stated on its own could. The two clauses above are what make the
placements differ — a chain whose remaining
legs must run under the outgoing mode carries the write to its end, and a chain whose
remaining legs branch on the incoming value takes it before the first of them.

**The write is conditional on the artifact, not on the verb.** Where this run did not produce
the artifact that would make the transition observable — the chain halted before that leg, or
the mode this run executed in produces no such artifact at all — **no mode is written and none
is announced.** That is the carve-out's own admission test applied literally, and it is a
branch a verb reaches from a state its own row admits, not a formality.

**Announcing it.** A verb that writes the mode states the transition in its own output and
names, **by path**, the artifact it just produced as the evidence; it writes `Mode notes` in
the same act from that same artifact. The evidence is never the wording of the request, never
the mode being requested, and never a statement the operator made — that is `/trip-record`'s
evidence and its territory. Where the value would not change, write nothing: the `Mode notes`
already in the file records the act that set it, and replacing it with a restatement
overwrites that record.

**Every verb of this file that dispatches more than one agent announces its set before the
first dispatch.** This rule sits here, not inside a verb, because it binds every such verb
this file carries and every one a later slice adds. Before dispatching anything, the verb
states in its output: each coupling condition it evaluated and the verdict it reached, with
the evidence that decided it; the agent set it is about to dispatch, in dispatch order, each
member named with the condition that admitted it; the legs that run whatever the conditions
say; the mode transition it expects to make and the artifact that will make it observable;
and the per-event status bound below. This is **disclosure, not confirmation** — it does not
stop for a yes, and the user is relieved of holding the dependency graph without being
relieved of knowing what ran.

**The announced set is a ceiling, not a floor.** The asymmetry is the point.

| what the run turns out to need | what the verb does |
|---|---|
| an agent the announcement did **not** name | **Stop before dispatching it.** Say the announced set was incomplete, name the agent and the condition that was missed, and stop. Do not silently widen. |
| **fewer** agents than announced — an announced member has nothing to do | **Run on.** Name each announced member that did not run, and why. Narrowing is not a defect; widening is. |

A disclosure the run then exceeds is a false statement about what happened, and it re-imports
the misrouting `ADR-007` exists to remove. A disclosure the run undershoots was conservative,
costs nothing, and is reported.

**The per-event status bound, placed on every dispatch whose chain reaches the hub.** The verb
states it in the announcement and binds it on the dispatch: only `planned` events change
freely; a `locked` or `firmed` event is preserved **unless the user's own argument text names
it**; an `option` is never auto-promoted into a primary slot. *Names it* is a **literal test
against the argument string** — never an inference from the wording of the request, and never
from which events would be convenient to move. `outputs/event-status.md` is persist-mutable:
the hub reads existing status and never regenerates it, so a human flip survives the pass.
**No verb of this file writes that file itself.**

## Selecting the verb

A literal lookup. Every step below is lexical, and the matching step — step 4 — has a
terminal else-branch, which is what separates a lookup from a classification.

1. Take `$ARGUMENTS` as a literal string.
2. Remove `--trip` together with the value that follows it, from wherever in the string it
   appears — it is accepted in any position. `--trip` is a contract-level token: it is
   removed before the verb is selected and it is passed to no verb. A `--trip` with no
   value after it is a malformed invocation — say that `--trip` was given without a slug,
   and stop.
3. The verb is the first remaining whitespace-delimited token, ASCII-case-folded. If no
   token remains, the verb is `status`.
4. Match that token by **exact string equality** against the recognition set: the verbs of
   this command named in `CLAUDE.md` → Step 1, in the `Command` column, whose cells render
   as `` `/trip <token>` ``. Read that column now, from the table already in context. Not a
   prefix match, not a nearest match, not a fuzzy match, not a substring match.
5. Everything after the verb token is that verb's argument string. Do not interpret it
   here.

Never infer the verb from the wording of the request, from the trip's mode, from which
files exist, or from anything other than the token step 3 produced.

The recognition set and the set this file implements are read from different places and
neither is derived from the other, so they are not guaranteed to coincide — they may agree
exactly at any given revision, and that agreement is an observation rather than a
guarantee. The recognition set is `CLAUDE.md`'s Step-1 `Command` column; the
set this file implements is the requirement table above. Both are read live, so a verb that is
recognised but not yet implemented is a fact this file reports rather than a fact it
records, and neither set is written down here as a number.

`trip.slug` is the directory name exactly as `E1` spelled it. The `--trip` value is a
selector matched against the members `E1` listed — it is never a path component, and no
path is ever built from it on this command.

## When the token is not a verb of this command

This refusal happens before the gate ladder runs — before its first gate — so no trip
state has been established and none is asserted. It sets no `trip.resolution` and no
`trip.stop_gate`: those are outputs of a ladder that did not run, and giving this refusal
a gate id would widen the contract's field set. Say nothing about whether a trip exists,
which trip is active, or what mode it is in.

Render exactly this, and nothing else:

1. The token, verbatim, as the user typed it.
2. The verbs of this command, read live from Step 1's `Command` column — not from a list
   written into this file.
3. Stop.

On this path, do not guess. Do not offer a near-match suggestion — no "did you mean" — for
a suggestion is a classification with an extra step and a reflexive accept, on the least
inspected path in this file. Do not fall back to any pipeline verb. Do not infer a verb
from the wording of the request.

## When the verb is recognised but this revision does not implement it

A distinct outcome from the one above, and it must not be collapsed into it. The token
matched the recognition set, and it names no row of the requirement table in this file.

Name the verb, say that it is recognised and that this file does not implement it at this
revision, and stop. Do not give a reason drawn from the resolved trip state: the resolved
state is not why, and naming it would be a false reason.

## status

Read-only, and read-only as a rule this verb follows. It writes nothing, dispatches no
agent, runs no script, and reads nothing beyond the pre-executed blocks above.

`status` is exactly two renders, mutually exclusive, selected by `trip.resolution`.

**`STOPPED`** — render the stop the contract produced: what could not be established, and
the remedy, in the terms the contract states for the gate that stopped. Add nothing,
interpret nothing, and assert no conclusion the gate did not observe.

The listing of trips on an ambiguous population is one of these renders. It is the
contract's own trip-population disposition, rendered — not a behaviour `status` owns. So
are the create pointer on an empty population, and the refusal when a supplied `--trip`
matched no member or matched more than one. These belong to the contract rather than to any
verb, so `status` renders what the contract produced and adds nothing of its own. What a
sibling command renders is that file's to state, not this one's.

**`RESOLVED`** — render, in this order:

1. The trip: `trip.slug` and `trip.destination`.
2. `trip.lifecycle`.
3. `trip.mode`, with one line on what that mode covers.
4. The verb index, below.

`trip.freshness` is empty at this revision, so render nothing from it. When it carries
entries, `status` is where they are reported.

### The verb index

Evaluate the requirement table in this file against the resolved record, using the same
predicate the dispatch above uses. Read this file's own table — do **not** derive the
index from `CLAUDE.md`'s Modes table and do **not** derive it from the agent roster. Those
answer which agents run, not which verbs this command runs; joining them would produce an
advisory list that can disagree with what the verbs actually do. Reading the same rows the
dispatch reads is what keeps the index from advertising a verb the **table** would then
refuse. It is not a guarantee of no refusal at all, and claiming one would be false: a verb
the table admits can still stop inside its own section — `check` where no itinerary exists,
`research` on an agent key that matches nothing. Those stops are the verb's own, declared in
its own section, and they are not the index disagreeing with the table.

Order:

1. The rows that `RUN` for this resolved record — lead with them. That is the answer to
   "what can I do next".
2. The rows that `REDIRECT`, each naming the command it redirects to.
3. The rows that `REFUSE`, each with the reason from its own row, so the index never goes
   silent on a verb this file's table declares.

Then name the Step-1 rows whose `Command` cell carries an `EXCLUDED:` marker, read live
from that table rather than listed here — those are the actions to just ask for, and they
are stated rather than left as a gap.

The index spans this file's table: a verb Step 1 declares and this file does not implement
holds no row here, so the index does not list it. That is not the surface going silent on the verb — typing it reaches *When the
verb is recognised but this revision does not implement it*, above — it is the index
declining to advertise what this file does not implement.

`status` declares `lifecycle: ANY` deliberately, rather than leaving that cell to its
default. Orientation is precisely what an archived trip still needs — it is where the
reopen path gets named — and a `status` that stopped resolving the moment a trip was
archived would withhold the answer at the one moment the user most needs it.

## plan

**Reads:** `agents/<name>.md` — the prompt of each agent this verb dispatches, the path taken
from that agent's own row in `CLAUDE.md`'s roster and read to supply that agent's
instructions; `trips/<slug>/trip-context.md` — the `## Mode` block alone, read before it is
written because `Current mode` and `Mode notes` are replaced in one act and the outgoing
`Mode notes` is echoed before it goes. It reads no other block of that file and does not
re-read it for the trip's mode or destination — the record block above carries both by value.
It reads nothing under `trips/<slug>/outputs/` itself: those artifacts are read by the agents
that consume them, and a read here would give the itinerary a second reader with no write to
justify it. **Agent reads, attributed:** enrichment reads `trips/<slug>/travelers/*.md` and
`trips/<slug>/trip-context.md`; each spoke reads `trips/<slug>/trip-context.md`,
`trips/<slug>/trip-log.md` and its own accumulated output file; the hub reads the spoke
outputs and `trips/<slug>/outputs/event-status.md`; the validator reads the itinerary the hub
produced and `trips/<slug>/outputs/event-status.md`. **Dispatches** enrichment, the spokes
§ *Modes* admits for the resolved mode, the hub, and the validator where that mode runs it —
each in the role its roster row states, each writing exactly the file or files that row names
and nothing else.

**The chain is § *Modes*' to decide, not this section's.** Read the resolved mode's row there
and dispatch what it says runs, in the pipeline order § *Dispatching agents* states. The
announcement obligation in the standing clause applies to this verb: the resolved mode is the
condition that admits each member, so the announcement names the mode, names each member, and
names the members § *Modes* withholds at that mode.

**Append and replace discipline.** Each spoke appends to its own output file under a new dated
section and rewrites, reorders and deletes nothing. Where the hub replaces
`outputs/final-itinerary.md`, the version being replaced is preserved as the numbered
predecessor § *Output Versioning* names before the replacement is written — bound 5's
preserve-first shape, not an exception to it.

**The mode.** The value is `ITERATION`: § *Modes* describes it as an existing plan the user
wants changes to, which is what a completed plan leaves behind. The artifact that makes the
transition observable is `trips/<slug>/outputs/final-itinerary.md`, produced by the hub leg.
Apply the placement rule: the `ITERATION` behaviours § *Modes* names — the hub's equity-aware
disruption recovery and the validator's recovery-equity check — are gated on a **disruption
recovery**, which this run is not, so no leg of this chain reaches one. It is not that the hub
and the validator never branch on `ITERATION`; they do, and `replan`'s section places its
write ahead of exactly those legs. And the validator still to run must run under the outgoing
mode — the full pass § *Modes* assigns it there, not the changed-days pass it would run under
`ITERATION` — so advancing before it would re-mode the validator into a pass it is not making.

**Where it writes no mode.** In `IDEATION` § *Modes* runs the overview-level form: the spokes
produce overview-level output, the hub compares options, and the validator is skipped.
§ *Modes* says nothing about `final-itinerary.md` at that mode, and the roster names that file
among the hub's outputs — so this section does **not** conclude from that silence that none is
produced. It applies the conditional above literally instead: **where the hub leg of this run
did not produce `trips/<slug>/outputs/final-itinerary.md`**, nothing this run produced makes
`ITERATION` observable, so `plan` writes no mode and announces none — and says so, naming
`/trip-record mode` as what records a transition whose evidence is a statement only the
operator can make. Where the hub leg did produce one, the transition is observable and the
write lands where the placement rule puts it. `IDEATION` is a state this verb's own row
admits, so that path is entered rather than described, and the same test disposes of a run
that halted before the hub leg.

**`outputs/event-status.md`.** This verb reads it only through the agents it dispatches — the
hub and the validator both read it — and the hub writes it, which is the hub's write under
*ownership follows the writer, not the caller*. **This verb writes no byte of it.** The
per-event status bound in the standing clause is placed on the dispatch and stated in the
announcement, because this chain reaches the hub.

**Depth.** The row declares `G8` because this verb announces derived-state freshness.
`trip.freshness` is empty at this revision, so there is nothing yet to announce from it.

## replan

**Reads:** `agents/<name>.md` — the prompt of each agent this verb dispatches, the path taken
from that agent's own row in `CLAUDE.md`'s roster; `trips/<slug>/trip-context.md` — the
`## Mode` block alone, read before it is written, for the reason `plan`'s section gives. It
reads no other block of that file and nothing under `trips/<slug>/outputs/` itself. **Agent
reads, attributed:** each affected spoke reads `trips/<slug>/trip-context.md`,
`trips/<slug>/trip-log.md` and its own accumulated output file; enrichment, where a changed
profile is what triggered the run, reads `trips/<slug>/travelers/*.md` and
`trips/<slug>/trip-context.md`; the hub reads the spoke outputs and
`trips/<slug>/outputs/event-status.md`; the validator reads the itinerary the hub produced and
`trips/<slug>/outputs/event-status.md`. **Dispatches** the spokes the coupling conditions
admit, the hub and the validator — each in the role its roster row states, each writing
exactly the file or files that row names.

**What it evaluates before it dispatches anything.** Each coupling condition below, with the
evidence that decided it, announced per the standing clause:

| condition | what its truth makes stale | the agent that admits |
|---|---|---|
| a **zone change** — the change moves an event into or out of a geographic zone the day was built around | the point-to-point leg set the day's routing rests on | transport |
| a **time-anchoring reservation** — the change adds, moves or drops a reservation the day's timing is pinned to | the day's timing framework and the slack around it | scheduling |
| a **day move** — the change relocates an event to a different day | the day-of-week assumptions the placed selections were checked against | scheduling |

**A condition belongs to that set by satisfying a rule, not by being written into it:** a
condition belongs where its truth makes another agent's output stale, and the agent whose
output goes stale is the agent it admits. A condition a later slice recognises is admitted by
that rule and inherits the announcement and the ceiling with no edit here.

**The floor.** `hub → validator` runs whatever the conditions say. The hub is the roster's
named writer of `outputs/final-itinerary.md` and the primary writer of
`outputs/event-status.md`, and the validator is the roster's named auditor of the itinerary
the hub just produced — so a run that skipped either would leave the itinerary unreconciled
or the status-integrity guarantee unaudited. The announcement names the floor as such.

**The mode.** The value is `ITERATION`. The artifact that makes the transition observable is
the research the affected spokes appended, named by path in the announcement. Apply the
placement rule: the hub's equity-aware disruption recovery and the validator's recovery-equity
check both branch on `ITERATION` and are both legs of this chain, so the write precedes the
first of them; and no remaining leg must run under the outgoing mode, because this run is the
iteration. Writing at the end of the chain would strand exactly the readers the carve-out
exists to reach.

**Where it writes no mode.** Where the coupling evaluation admitted no spoke, the floor runs
alone and **this run produced no artifact of its own before the hub leg** — so no mode is
written and none is announced. Say so, and name `/trip-record mode`: a transition with no
artifact behind it rests on a statement only the operator can make, which is that command's
evidence and its territory. `DISCOVERY` and `ENRICHMENT` are states this verb's own row
admits, and the floor-only path is reachable from either, so this is a branch the verb enters
rather than a sentence it carries.

**`outputs/event-status.md`.** Read through the agents this verb dispatches — the hub and the
validator both read it — and on a disruption recovery a `locked → planned` regression in it
**is** the trigger. The hub writes it; that write is the hub's. **This verb writes no byte of
it.** The per-event status bound is placed on the dispatch and stated in the announcement.

**Depth.** The row declares `G8` because this verb announces derived-state freshness.
`trip.freshness` is empty at this revision, so there is nothing yet to announce from it.

## reorder

**Reads:** `agents/<name>.md` — the prompt of each agent in the chain below, the path taken
from that agent's own row in `CLAUDE.md`'s roster; `trips/<slug>/trip-context.md` — the
`## Mode` block alone, read before it is written, for the reason `plan`'s section gives. It
reads no other block of that file and nothing under `trips/<slug>/outputs/` itself. **Agent
reads, attributed:** transport reads `trips/<slug>/trip-context.md` and its own accumulated
output file; scheduling reads `trips/<slug>/trip-context.md`,
`trips/<slug>/outputs/transport-brief.md` and its own accumulated output file; the hub reads
`trips/<slug>/outputs/scheduling-framework.md` and `trips/<slug>/outputs/event-status.md`; the
validator reads the itinerary the hub produced and `trips/<slug>/outputs/event-status.md`.
**Dispatches** transport, scheduling, the hub and the validator — each in the role its roster
row states, each writing exactly the file or files that row names.

**The chain: `transport → scheduling → hub → validator`.** Each link precedes the next because
of the artifact the next link consumes, not because the order feels right.

- **Transport precedes scheduling** because the scheduler's routing signal is arithmetic over
  the point-to-point leg matrix in `outputs/transport-brief.md`, and that matrix is defined
  over the consecutive-stop legs the itinerary actually uses. **Re-ordering the days changes
  which legs exist.** Run scheduling first and it reconciles over a matrix describing legs the
  new order does not contain — inventing leg times, and comparing an alternative ordering
  against nothing real.
- **Scheduling precedes the hub** because the hub resequences against the day order in
  `outputs/scheduling-framework.md`. Without that leg it has no new order to consume and would
  derive one, which is a second source for an artifact § *Modes* assigns to scheduling.
- **The hub precedes the validator** because the day-of-week closure pass is against the
  itinerary the hub just wrote. Run earlier it audits the order being replaced; omitted
  entirely, new closure conflicts ship and the resequence's own promise — that only `planned`
  moved — is unproven.

This is also why the resequence is its own verb rather than an argument to `replan`: under a
positional key, `replan scheduling …` dispatches scheduling without transport, which is the
stale-matrix failure above.

**When a link refuses.** The chain **halts at the refusing link, and nothing downstream
dispatches.** The output names the link that refused, its reason, and every link that did not
run. The announcement obligation and the ceiling in the standing clause apply to this verb
unchanged — it dispatches more than one agent.

**The mode.** The value is `RESEQUENCING`. The artifact that makes the transition observable
is the new day order in `outputs/scheduling-framework.md`, produced by the scheduling leg.
Apply the placement rule: the hub's resequence and the validator's full day-of-week pass both
branch on `RESEQUENCING` and are both legs of this chain, so the write precedes the first of
them; no remaining leg must run under the outgoing mode.

**The mode disposition on a refusal, on each side of that placement.**

| the link that refused | the mode |
|---|---|
| a link **before** the write's placement — `transport` or `scheduling` | **Not advanced.** The artifact that would make `RESEQUENCING` observable was never produced, so the conditional forbids the write, and no mode is announced. |
| a link **after** it — `hub` or `validator` | **Stands.** The days *were* resequenced in `outputs/scheduling-framework.md`; the trip **is** mid-resequence, which is what the cell should say. The output names the legs that did not run and names `/trip reorder` as the resume. |

That partition is a property of where the write is placed rather than a rule bolted on, which
is why the placement is the decision and the refusal behaviour falls out of it.

**`outputs/event-status.md`.** Read through the agents this verb dispatches — the hub and the
validator both read it. The hub writes it; that write is the hub's. **This verb writes no byte
of it.** The per-event status bound is placed on the dispatch and stated in the announcement,
because this chain reaches the hub; only `planned` events move.

## research

**Reads:** `agents/<name>.md` — the prompt of the spoke the agent key selects, the path taken
from that spoke's own row in `CLAUDE.md`'s roster. It reads nothing else: not
`trip-context.md`, whose mode and destination the record block already carries by value, and
nothing under `trips/<slug>/outputs/` — the spoke reads its own accumulated output file and
appending to it is the spoke's write, not this verb's. **Agent reads, attributed:** the spoke
reads what **its own prompt** declares — at minimum `trips/<slug>/trip-context.md`,
`trips/<slug>/trip-log.md` and its own accumulated output file, and for some spokes more:
`agents/03-scheduling.md` also declares `outputs/traveler-model.md` in every mode and, in
`ITERATION` and `RESEQUENCING`, `outputs/activities-list.md`, `outputs/food-list.md` and
`outputs/event-status.md`. That list is the spoke's, not this verb's, so it is cited rather
than closed here — a spoke's reads are read from its prompt at dispatch time.
**Dispatches** that one spoke, in the role its roster row states, writing exactly the file
that row names.

**The agent key.** Positional — the first token of the argument string, ASCII-case-folded —
matched by **exact string equality** against a set of **tokens** derived live from
`CLAUDE.md`'s agent roster. The derivation has two stages, and they must not be collapsed: a
row filter, then a cell that supplies the token. **Filter to the rows whose `Output File` cell
names exactly one path under `outputs/`, whose file § *Output Versioning* leaves in the
accumulating default — naming it in none of that section's replaced, rebuilt or
persist-mutable exceptions — and whose `When to dispatch` cell does not confine the row to a
state this verb's own row excludes. The token of an admitted row is its `Agent` cell,
ASCII-case-folded.** The filter yields rows; the `Agent` cell yields the comparand — **a typed
key is never compared against a row.** That set is **not written into this file and not
counted**, and it is what keeps a spoke a later release adds from needing an edit here.
Everything after the key is the topic, passed to the spoke and interpreted by it.

A key matching nothing is **this verb's own refusal**: render the token verbatim, render the
set read live from the roster, and stop. **No near-match, no *"did you mean"*, no fallback** —
the reasons § *When the token is not a verb of this command* gives hold identically here.

**It places nothing.** The spoke **appends** its research to its own output file under a new
dated section; it rewrites nothing, reorders nothing, and deletes no prior research. Research
that should change *what is placed* is `/trip replan`'s — name it and **do not run it**.

**`outputs/event-status.md`.** **This verb reads no byte of it and writes none.** Whether the
**spoke** reads it is that spoke's own prompt to say, and one of them does:
`agents/03-scheduling.md` declares a read of it in `ITERATION` and `RESEQUENCING` — both
states this verb's own row admits — to hold `locked` and `firmed` events fixed while it
re-times. That read is the
spoke's under *ownership follows the writer, not the caller*, and it is a read: no spoke this
key admits names `event-status.md` in its roster `Output File` cell, so **nothing this verb
dispatches writes it.** This chain does not reach the hub, so the per-event status bound does
not quantify over it.

**It writes no byte of `trip-context.md`.** The carve-out does not admit this verb.

## check

**Reads:** `agents/<name>.md` — the validator's prompt, the path taken from its own row in
`CLAUDE.md`'s roster; `trips/<slug>/outputs/` — the **existence probe** on the itinerary path,
taken only to establish whether there is an itinerary to audit, which is a read and is
declared. It reads no content under that directory itself, and it reads no block of
`trip-context.md`: the audit is the validator's and the constraint set is the validator's read.
**Agent reads, attributed:** the validator reads the current itinerary, the constraint set in
`trips/<slug>/trip-context.md`, and `trips/<slug>/outputs/event-status.md`, which it never
writes. **Dispatches** the validator alone, in the role its roster row states. **The dispatch
names no output path and instructs the validator, in terms, to write neither of the two files
its own prompt declares** — `outputs/validation-report.md` and `outputs/satisfaction-metrics.md`
— **and to return its findings in the response instead.**

**No output path, on purpose — and the dispatch has to say so.** § Step 1 states this audit
*"reports findings. No spokes, no hub, no edits."* `agents/06-validator.md` declares its writes
**unconditionally**: `outputs/validation-report.md` under *Output Format*, and
`outputs/satisfaction-metrics.md` — its own sections, read-merge-written — under *Input*.
Neither declaration is gated on a mode or a caller. **Naming no output path therefore
suppresses nothing**: an omission is not an instruction, and the agent's prompt is what the
agent follows. The suppression is an explicit instruction this verb places on the dispatch and
states in its output. A `check` that wrote `outputs/validation-report.md` would be replacing
an existing derived artifact and would owe the preserve-or-announce step bound 5 requires; a
`check` whose dispatch suppresses both writes owes none of it, and that is why the bound is
not engaged rather than satisfied.

**The observable post-condition, and what establishes it.** After `check` on a state its own
row admits, **no file under `trips/<slug>/` should differ** — a diff, not a reading, which is
what makes this verb gradeable by running it rather than by reading this section for the words
*writes nothing*. What establishes it is the suppression instruction above, **followed**:
nothing in the frontmatter and nothing in the dispatch mechanism enforces it, and the two
files the validator's prompt declares are precisely what a failed suppression leaves behind.
A diff showing either of them is this verb's defect and the first place to look.

**Frontmatter does not enforce this, and saying it did would be false.** `disallowed-tools` is
per file, and this file holds `Write` and `Edit` for other verbs. `ADR-007` § *Context* is explicit on
both halves: a command's conduct has to be written as a rule the command follows, never as a
property its frontmatter guarantees; and a tool left off the list is not thereby forbidden —
it routes through the usual permission settings instead. The rule above is the enforcement
this verb has until a verb-section parser asserts a read-only verb's section carries no write
instruction.

**Why the row reads `mode: any`.** It admits `UNSET` deliberately. The audit is against the
itinerary and the constraint set, neither of which is mode-derived. The validator behaviours
§ *Modes* gates to a mode — the recovery-equity check, and the full pass on all days after a
resequence — simply do not fire outside it, which is correct rather than a gap. This verb is
required to leave the trip tree unchanged, so admitting the non-nominal state costs nothing.

**Where there is nothing to audit.** Where the existence probe finds no itinerary — which is
what `IDEATION` leaves behind, a state this row admits — say so, name `/trip plan`, and stop.
Do not dispatch the validator against an itinerary that is not there.

**`outputs/event-status.md`.** The validator reads it and never writes it. **Nothing this verb
dispatches writes it, and this verb writes no byte of it.** This chain does not reach the hub,
so the per-event status bound does not quantify over it.

**It writes no byte of `trip-context.md`.** The carve-out does not admit this verb.

## ideas

**Reads:** `agents/<name>.md` — the Destination Ideation prompt, the path taken from its own
row in `CLAUDE.md`'s roster. It reads nothing else: not `trip-context.md`, whose mode and
destination the record block already carries by value, and nothing under
`trips/<slug>/outputs/` — the shortlist is the agent's to write and this verb never reads it
back. **Agent reads, attributed:** the ideation agent reads `trips/<slug>/travelers/*.md` for
the group's leanings and `trips/<slug>/trip-context.md` for the dates and party.
**Dispatches** Destination Ideation, in the role its roster row states, writing
`outputs/destination-shortlist.md` alone. On a re-run that agent appends under a new dated
section and rewrites nothing.

**Why the row's destination cell reads `UNDECIDED`.** A decided destination means the ideation
question is already answered, and running the pipeline anyway spends it re-ranking a settled
choice. On a decided destination this verb refuses and names the verb that does serve the
request.

**It performs no hand-off. It names the hand-off and stops there.** On completion it names the invocations `CLAUDE.md`
→ *Starting a new trip* states for the moment the group picks, **in the order that section
states them and read live from it** rather than copied here. It **runs neither**, and it
**writes no destination**: the ideation agent ends by saying it never writes a destination
into `trip-context.md` itself, and the `## Destination` block is `/trip-record`'s in
§ *Write ownership*. Named invocations in the stated order — not one compound step, and not a
suggestion to *"then set the mode"*.

**`outputs/event-status.md`.** Not read: this verb runs pre-destination, where no itinerary
and no placed event exists. Nothing it dispatches writes it, and this verb writes no byte of
it. This chain does not reach the hub, so the per-event status bound does not quantify over it.

**It writes no byte of `trip-context.md`.** The carve-out does not admit this verb.

## site

**Reads:** `trips/<slug>/outputs/final-itinerary.md`, `trips/<slug>/outputs/links-reference.md`
and `trips/<slug>/outputs/venue-matrix.md` — the plan artifacts § *How to build it* names as
the site's content sources; `trips/<slug>/trip-context.md` — the group, dates and trip-level
constraints the hero and overview render, and no other block;
`trips/<slug>/outputs/event-status.md` — the authoritative source
`reference/site-layout-spec.md` § 9.1 names for booking status, *needs booking* flags,
checklist membership and the per-card booking tiers, read because § 3 makes the site a read
surface for status; `reference/site-layout-spec.md` — the responsive architecture, the card
system, the booking indicators and the § 9 round-trip rules; the itinerary sources the
§ *Site References* table names, read as the quality bar rather than as templates;
`trips/<slug>/outputs/<destination>-travel-site.html` — the **existence probe** that selects
creating the site from patching it, and, on the patch route, the outgoing markup read before
it is changed, because that read is what preserves design already approved — within this run it
is the only copy of the outgoing markup there will be, the trip tree being git-ignored and
carrying no history. It does **not** make the no-regenerate rule below checkable: after the
write there is nothing left to diff the result against, so that rule stands as one this verb
follows, not one an inspection of the tree can settle afterwards. It does not read
`trips/<slug>/trip-log.md`: the log carries the reasoning behind choices, and the site renders
what was chosen. **Dispatches no agent** — the site is authored directly, which is why this
verb reaches `Write` for its own output rather than for an agent's.

**Update, do not regenerate.** Where the site exists, **patch the affected sections** and
preserve design tweaks already approved; `Write` is reached only where the file does not
exist. A regenerate silently drops plan detail and approved design, which is the overwrite
bound 5 forbids, and it takes no licence from the append shape either.

**The round-trip completeness check, run after every build and every patch.** Every element of
`outputs/final-itinerary.md` — **every day, and every track of a split day** — still resolves
to a rendered component or to a **named** exclusion. A dropped element is a defect; additive
site scaffolding with no plan source is not. Where the check does not close, say which element
did not resolve and do not present the site as current.

**It never publishes.** The standing clause binds this verb, and it binds it **as a rule this
verb follows**. `disallowed-tools` narrows the route — it names the script path, `bash` and
`sh` — but it does not close it: `ADR-007` § *Context* is explicit that `disallowed-tools` is
turn-scoped and that **durable blocking needs a permission-settings deny rule, a different
artifact this repo does not ship**, and that a tool left off `allowed-tools` is not thereby
forbidden. So nothing here is unreachable by construction, and saying it was would be the same
false move `check`'s section refuses to make about its own frontmatter. It is unreached because
the rule says so. Where publishing is what the user wants, name `/trip-publish` and stop.

**`outputs/event-status.md`.** **Read** — see the read line above. **Never written**, by this
verb or by anything it dispatches, which is nothing. This verb's one write under `outputs/` is
its own `<destination>-travel-site.html`; every other artifact there it reads and does not
write, this file among them. This chain does not reach the hub, so the per-event status bound
does not quantify over it.

**It writes no byte of `trip-context.md`.** The carve-out does not admit this verb.

**Depth.** The row declares `G8` because this verb announces derived-state freshness.
`trip.freshness` is empty at this revision, so there is nothing yet to announce from it.
