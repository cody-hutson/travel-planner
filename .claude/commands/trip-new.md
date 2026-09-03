---
description: Start a new trip — scaffolds the folder, context, log and traveler intake. Creates only; never overwrites an existing trip.
argument-hint: [destination-year]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(date:*), Bash(mkdir:*), Read, Write
disallowed-tools: [Bash(scripts/publish-trip-site.sh:*), Bash(bash:*), Bash(sh:*), Edit, NotebookEdit]
---

# New trip setup

Scaffolds a new trip: the trip directory, `outputs/`, `travelers/`, `trip-context.md` from the
template, and `trip-log.md` with its first session entry. Sets the starting mode from what the user
has actually stated, records who is going, and hands off to traveler intake.

**This command creates. It never overwrites.** Re-running it against a trip that already exists adds
only the members that are missing and leaves every existing file exactly as it is. `trips/` is
git-ignored, so there is no history to restore from — a rewritten `trip-context.md` or `trip-log.md`
is gone for good. That severity is not this file's own rating:
`reference/adr/ADR-007-command-entry-point.md` § 2, **bound 5** — *no command may overwrite or
delete existing trip content* — types a clobber **IRREVERSIBLE**, and names *create only what is
missing* as the first of the three shapes that satisfy it. **This command takes that shape, and the
rule above is the whole of what makes it hold.**

**What `disallowed-tools` does at runtime is contested, and this file does not settle it.** Two
accounts ship in this repo and they are not compatible. `ADR-007` § *Context* says the field
*removes the named tools from the pool* — a real restriction, turn-scoped like the grant. The
trip-resolution contract workflow's coverage-boundary note says the opposite where it matters:
`allowed-tools` and `disallowed-tools` are a turn-scoped pre-approval grant, **every tool stays
callable**, and a green check there is **not a privilege guarantee** and must not be read as one.
**Nothing in this repo arbitrates**, and the reason is narrower than *nothing reads the field*.
`scripts/test-command-taxonomy.sh` does read it: its invocation classifier walks the command
directory and matches this file's `disallowed-tools:` line on the publish-script grant token that
line carries, counting it into a **tool-grant tally** — one term of a parse-coverage identity that
guard asserts and fails on. That reading is of what this file **declares**; the guard says in terms
that it takes neither account, because every assertion it makes is about a declaration and none
about what a declaration enforces. **A declaration-level reading is what leaves the runtime question
unarbitrated** — not the absence of a reader. Where else the field appears is **re-derived from the
tree rather than listed here**: the list this sentence used to carry named the five command files,
one workflow note and the ADR, and was two short — it missed a second workflow note and the guard
itself, which is what a written-down census does.

**What the two accounts agree on is all this file relies on.** Under both, the declaration is
turn-scoped and clears at the next message, and a tool left off `allowed-tools` is not thereby
forbidden — it routes through the usual permission settings instead. **Omission is not prohibition**
either way. And `ADR-007` adds that durable blocking would need a permission-settings deny rule — a
different artifact, and one this release does not ship. **So the create-only rule above is written
as a rule this command follows, never as a property its frontmatter guarantees**, which is the form
`ADR-007` § *Context* requires of a command's conduct — and it therefore holds under
either account, with nothing left depending on which one is true. The `Edit` and `NotebookEdit`
denials **corroborate** it as a *declared* restriction whose runtime force this repo does not
establish. They are not what makes it true, and no bound stated anywhere in this file rests on them.

Takes an optional `[destination-year]` argument, such as `lisbon-2027`. The argument is text. It is
never executed, and it proposes a name rather than settling a decision.

`--trip <slug>` is accepted and **never consumed here.** It is not a slug proposal —
`/trip-new --trip lisbon-2027` does not mean "create `lisbon-2027`" — and the positional
`[destination-year]` argument is the only slug proposal this command reads. Because this command
creates rather than selects, **a `--trip` naming a slug no existing trip carries is ordinary input
here: neither a conflict nor a stop.** Where `--trip` and the positional argument are both supplied
and **disagree, say so and ask which was meant.** Do not pick one.

## Existing trips

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`

```trip-contract-header
Contract: CLAUDE.md § Resolving a trip
contract-depth: G2
population-role: CREATE
```

| verb | lifecycle | mode | destination | depth |
|---|---|---|---|---|
| new (create) | not read at this depth | not read at this depth | not read at this depth | G2 |
| new (resume) | not read at this depth | not read at this depth | not read at this depth | G2 |

## What to do with this

The block above has already run and its output sits above this line. **The resolved trip population
comes from it, as the contract states.** Do not list `trips/` again to re-derive that population, and
do not read an existing trip's files to decide anything here.

The fenced block above is this file's contract declaration, and the requirement table that follows
it states what each of its two branches requires. The block cites the one normative home of the
resolution rules and states the depth this file runs at and the role it plays. Both are declarations,
not procedures: nothing either one states is re-derived below.

Work Gate A and then Gate B, in that order. Do not skip ahead to the scaffold.

## Gate A — the slug

Ordered, and the order is load-bearing.

**1. Take the proposed slug and trim it.** The slug is `<destination>-<year>`, lowercase and
hyphenated — `lisbon-2027`, `tokyo-2026`. It is the trip's folder name.

- If the user passed a positional argument, that is the proposed slug.
- If they did not, and the conversation has settled a destination and a year, propose that.
- **If neither, ask for it.** Never invent a slug, and never create a directory under a placeholder
  name.

**2. Check its shape. Three conjuncts, and all three must hold.** The slug is valid only if it is
**non-empty**; **and every** character is a letter, a digit, `.`, `_` or `-`; **and the first**
character is a letter or a digit.

**3. If any conjunct fails → STOP. Create nothing** — no directory, no file. Say plainly **what was
rejected and why**, state the shape a slug takes (the three conjuncts above), and **ask for a
corrected one.** The argument is text, and **a rejected slug is never repaired by guessing** at what
was meant.

**4. Lowercase the slug that passes.** This is the normalised slug, and it happens **before** the
existence comparison in Gate B. The order is the point: that comparison is what stands between a
new trip and a live one, and on a case-folding volume `Lisbon-2027` and `lisbon-2027` are
the same directory. Comparing before normalising lets a case variant read as absent and scaffold
straight into a live trip. Carry the normalised slug forward — it is what Gate B compares and what
every member below uses.

**5. Only now does the existence comparison run.** Gate B is next.

**Where this rule comes from, in two halves with different provenance.** The **charset** half mirrors
`slug_for()` in `scripts/publish-trip-site.sh`, whose rejection case is exactly
`''|*[!A-Za-z0-9._-]*`. The **first-character anchor is an addition this command makes** —
`slug_for()` does not carry it, and that charset rule on its own accepts `..`, `.hidden` and `-rf`.
Do not describe the anchor as a rule the publish script already applies; it is not.

**Why the anchor is sufficient rather than merely helpful.** The charset excludes `/` and `\`, so a
slug that passes is always a **single path segment**. The only single segments that can traverse are
`.` and `..`, and both begin with a character that is neither a letter nor a digit — so the
first-character anchor closes traversal completely. It independently rejects a leading `-`, which
would otherwise reach `mkdir` as an option rather than as an operand.

**What an unvalidated slug costs, stated in terms.** The slug becomes a directory name. A slug that
is not a plain single segment **does not stay inside `trips/`**, and `trips/` is exactly what this
repository's ignore rule is scoped to. Escape it and the trip's traveler data — real names, ages,
home cities, dietary and medical needs — lands in tracked space in a **public repository**. That is
why this gate stops rather than repairs.

## Gate B — does it already exist?

Compare the normalised slug against the resolved trip population, **case-folded on both sides.**

**Test every member of the population, whatever its size.** The question here is *"does this name
collide?"*, never *"which trip did you mean?"* — so this command poses no which-trip question
anywhere, and **a population of zero collides with nothing and goes straight to Create.** That is the
normal path for this command, not an error condition.

- **No collision** → **Create**, under the normalised lowercase slug.
- **A collision** → **Resume**, under the name **exactly as the population spelled it** — that is the
  directory that is actually there.

## Create

**Reads:** `templates/trip-context.template.md` — the copy source member 4 reads before it writes,
and reading it before the write is what makes member 4's *keeps every other field exactly as it
ships* rule checkable rather than merely asserted. It reads **no existing trip file**: the trip
population is carried by the block above, and on this branch no trip directory exists to read. In
particular it does not read `trip-context.md` or `trip-log.md` — this branch is what creates them,
and a read of either here would be a read of a file this command had just written. Dispatches no
agent.

Build all nine members, in this order.

| # | Member | How |
|---|---|---|
| 1 | `trips/<slug>/` | created by member 4's write |
| 2 | `trips/<slug>/outputs/` | `mkdir -p` |
| 3 | `trips/<slug>/travelers/` | `mkdir -p` — **the directory only. No file is ever created inside it.** |
| 4 | `trips/<slug>/trip-context.md` | `Read` `templates/trip-context.template.md`, then `Write` it with exactly five things filled: the title line, `Current mode`, `Mode notes`, the `## Group` roster, and `- **Total travelers:**` |
| 5 | `trips/<slug>/trip-log.md` | `Write` — the frontmatter fence below, then one initial session entry, dated from the `date` call below |
| 6 | the mode value | the three-rule ladder under *The starting mode* |
| 7 | the mode basis | written into `Mode notes` **and** into the log entry |
| 8 | the roster and the traveler count | the rules under *Travelers — count and names* |
| 9 | the traveler-intake hand-off | rendered with the resolved slug |

**The date.** Member 5's entry is dated `YYYY-MM-DD`. Get it by running `date +%F` as a tool call
here in the body, **not** as a pre-execution block: the contract header block above fixes how many
pre-execution blocks this file carries, and it already carries all of them.

Member 4 keeps **every other field of the template exactly as it ships.** A bracketed placeholder is
a legitimate *not yet answered* — the form the user fills in through conversation — and never a gap
to fill opportunistically. Write the mode's actual value, never the template's bracketed list of
options.

The title line `# Trip Context — [DESTINATION] [MONTH] [YEAR]` takes the trip's own destination and
year. Leave the month bracketed if it is not known yet.

**Three fields are deliberately not written — ownership, not oversight.** `CLAUDE.md`
§ *Write ownership* names this command as a writer of exactly two rows: the title line with the
`## Group` roster and `- **Total travelers:**`, and `## Mode` with `Current mode` and `Mode notes`.
Everything else in that file belongs to another writer.

- `- **Primary destination:**` — **not written, in any mode.** `## Destination` is `/trip-record`'s
  block. Even when the user named a destination and that statement is exactly what set the mode, this
  command does not write the field: the destination reaches the title line and `Mode notes`, both of
  which this command owns, and stops there. **A freshly scaffolded trip therefore has no decided
  destination whatever its mode**, and `/trip-record destination` is what changes that.
- `- **Travel mode:**` and `- **Subgroup notes:**` — **not written.** The ownership row names the
  roster and the traveler count, not every line under `## Group`. These two fall to the default row,
  which is `/trip-record`. They stay bracketed.

No `**Lifecycle:**` line is written, and none is added to the template.

Member 5 writes the fence and then the entry, and the two together are the file's whole content at
creation. **Write the block as it stands**, filling `<slug>` and the entry's angle-bracket
placeholders and nothing else. The entry half follows the `trip-log.md` structure `CLAUDE.md`
documents:

```markdown
---
artifact: trip-log.md
schema-version: 1
trip: <slug>
writer: operator
lifecycle: accumulate-append
provenance: human
publish: internal
---

# Trip Log — <Destination> <Year>

## Session <YYYY-MM-DD> — Trip setup
**Topics:** Trip setup — directory scaffolded, starting mode set, party recorded
**Decisions:**
- Starting mode <MODE> — <the basis, naming what the user stated>
**Rejected:**
- <the mode considered and not taken, and why — omit this line if nothing was in contention>
**Next steps:** <the mode-consequent next move, plus traveler intake>
**Open questions:** <any unresolved conflict — omit if none>
```

Use the bare `YYYY-MM-DD` form exactly as the `date +%F` call returned it.

**`trip:` is the only fence field this command fills**, and it takes the normalised slug Gate A
carried forward. Every other field is a fact about the artifact class rather than about this trip —
`reference/data-architecture.md` § *In-model — artifact classes* decides them on this
class's row, and `reference/schemas/trip-log.md` declares the field set and the enum each value is
drawn from. Write them exactly as they stand, and cite those two rather than re-deriving one.
**`generated:` is absent by design** — `reference/data-architecture.md` § *Universal frontmatter*
omits it on human-authored classes, and this class's schema types it optional for that reason. The
`date +%F` value is at hand here for the entry heading and is **not** a field of this fence.

**The fence reaches member 5 and nothing else — Resume writes none into a log that already exists.**
Step 4 there leaves an existing `trip-log.md` alone, and that is unchanged: a log carrying no
`schema-version` is read as version 0 under `reference/data-architecture.md` § *Tolerant read* and
stays valid indefinitely, so there is nothing to repair. Writing one would be a rewrite of exactly
the file the create-only rule at the top of this file exists to protect, and `trips/` is git-ignored.

## Resume — repair only

**Reads:** `trips/<slug>/` — the member listing step 1 takes with `ls`, read only to establish which
scaffold members are present, which is a filesystem observation and is therefore declared;
`templates/trip-context.template.md` — the copy source, read only on the branch where
`trip-context.md` is genuinely absent and step 2 reaches `Write`. It reads **no member's content**.
That is step 3's contract-conformance rule rather than a courtesy: this branch observes member
**existence** only, and reading a field would change the depth this file declares in its contract
header block. So it does not read an existing `trips/<slug>/trip-context.md` or
`trips/<slug>/trip-log.md` — not for the mode, not for `Mode notes`, not for the roster, and not to
decide anything here. Dispatches no agent.

The trip already exists. **Nothing is rewritten.**

1. **Say by name which directory was matched**, and which members exist versus which are missing.
   Establish that by listing `trips/<slug>/` with `ls` — a different directory and a different
   question from the population listing above, so it is not a re-derivation of that population.
2. Create only the missing ones. `outputs/` and `travelers/` use `mkdir -p`, which no-ops when the
   directory is already there. `Write` `trip-context.md` or `trip-log.md` **only if genuinely
   absent.**
3. If `trip-context.md` exists — **leave it.** Do not re-derive the mode, do not touch `Mode notes`,
   do not touch the roster, and **do not read it to decide anything here.** *This is a
   contract-conformance rule, not a courtesy.* This branch observes member **existence** only, never
   member **content**; reading a field here would change the depth this file declares in its contract
   header block, and with it the evidence prefix it must carry and the tool grant that prefix
   obliges. Deleting this rule breaks the file's declaration, not just its manners.
4. If `trip-log.md` exists — **leave it.** No setup entry is appended; this is not new-trip setup,
   and session logging is already covered by the existing request types.
5. Render the traveler-intake hand-off below.
6. Name `/trip` for orientation on the trip as it stands.

This branch is also the repair path for a trip created before `travelers/` was part of the scaffold.

## The starting mode

Set the mode from what the user has **stated in this conversation.** Three rules, first match wins.

| Order | What must be affirmatively stated | Mode |
|---|---|---|
| 1 | A booked transport or lodging anchor — a flight, train, or place to stay the user says is booked, confirmed or paid, specific enough to be an anchor (a date, or a named property) | **ENRICHMENT** |
| 2 | A committed destination — where the trip is going, stated as a decision rather than a candidate | **DISCOVERY** |
| 3 | Neither of the above | **IDEATION** |

Only these three values are reachable here. `ITERATION` and `RESEQUENCING` both presuppose an
existing plan, and at setup there is none.

This command owns the mode **only at creation.** Any later change goes through `/trip-record mode`.

### What counts as evidence

- **Stated, not inferred.** It has to be something the user said in this conversation. This is a new
  trip; there is no prior session to recall.
- **A bracketed placeholder is never evidence.** `trip-context.md` was written from the template
  moments ago, so its fields still read `[like this]`. Never read one back and treat a placeholder as
  an answer.
- **Absence is never evidence for the rung below.** "They did not mention flights" does not make it
  DISCOVERY. Rule 2 needs its own affirmative destination statement.
- **The slug proposes; the user confirms.** `/trip-new lisbon-2027` names Lisbon. That alone does
  **not** reach rule 2 — someone still weighing Lisbon against Porto types a slug anyway, because the
  folder needs a name. Ask once: *"Is Lisbon settled, or still one of the options?"* One question,
  not a questionnaire.

### When the evidence is thin, and when it conflicts

Two different situations, and they get different treatment.

**Thin evidence is not ambiguity.** Nothing affirmative for rule 1 or rule 2 resolves to
**IDEATION** by rule 3, deterministically. **Do not ask.** Leaving IDEATION later costs one field
edit, whereas a wrongly-promoted ENRICHMENT tells every agent to plan around anchors nobody booked.
**Default downward, never upward.**

**Conflicting evidence is real ambiguity** — something satisfies a higher rung and something
contradicts it, as in *"flights are booked but we might switch to Porto."* It is never resolved
silently.

1. Ask exactly one question, naming both candidate modes **and what each one means**: DISCOVERY runs
   the full pipeline with all agents; ENRICHMENT runs the full pipeline with agents planning around
   fixed anchors.
2. If they answer, take their answer.
3. If they decline, or the answer does not resolve it, take the **lower** of the two candidates and
   record the unresolved conflict. Never invent a resolution.

### Record why, not just what

The mode value alone does not say what was known. Write the basis in both places:

- **`trip-context.md` → `Mode notes`** — one line naming the evidence that selected the mode, plus
  any unresolved conflict. For example:
  `IDEATION — destination not settled (Lisbon and Porto both in play at setup). No transport or lodging booked.`
- **`trip-log.md` → the initial entry** — `Decisions:` carries the mode and its basis, `Rejected:`
  carries a mode considered and not taken, and `Open questions:` carries an unresolved conflict.

A later reader should be able to see whether the mode rests on a booking or on a guess.

### What the mode means for the next move

- **IDEATION** — rule 3 was reached, so no destination was stated and `- **Primary destination:**`
  still reads its template placeholder. Name **`/trip ideas`** as the next move: it turns the group's
  leanings into a ranked shortlist at `outputs/destination-shortlist.md` for the group to decide
  from. **It is a command. Name it; do not dispatch anything.** Once the group picks, the hand-off
  is two named invocations, in this order: **`/trip-record destination <chosen>`**, which writes
  `## Destination` — this command does not own that block — then **`/trip-record mode DISCOVERY`**.
  Name both. Naming only the first leaves the trip in `IDEATION`, where `CLAUDE.md` § *Modes*
  skips the Validator — an under-run with nothing announcing it.
- **DISCOVERY or ENRICHMENT** — the trip is ready for the full pipeline once traveler profiles are
  in, and building the first full plan is the expensive operation, so the profiles are worth having
  first. **Name `/trip-record destination` here too.** A destination *was* stated and the ownership
  row above still does not give this command that field — a rule it follows, not an inability — so
  without that naming the trip sits with `- **Primary destination:**` left bracketed and nothing
  pointing at the fix.

## Travelers — count and names

Ask **one** question, after the mode is settled and before member 4's write:

> *"Who's going? First names are fine. If you don't know everyone yet, tell me how many there are in
> total."*

That is one question, not a questionnaire. Together with the mode-disambiguation question above,
**this command asks at most two questions before it writes anything.**

| Input | Disposition | Basis |
|---|---|---|
| Traveler names → the `## Group` `Person` cells | **ASKED** | No derivation source exists at scaffold, and the roster is the only enumeration of who should have a profile |
| `- **Total travelers:**` | **DERIVED** — the stated total if one was given, otherwise the count of names | Never asked as a second question, and never allowed to disagree with the roster silently |
| Roster row count | **DERIVED** — the template's four `[Name]` rows are resized to the named set: rows deleted below the count, rows added above it | The template ships a fixed four-row roster; leaving it at four is a party of four asserted by a template |
| `Traveler file` cell → `travelers/<name>.md` | **DERIVED** from the name: lowercase it, replace every run of characters outside `A-Za-z0-9._-` with a single `-`, then trim leading and trailing `-` | Reuses Gate A's charset rather than inventing a second rule, which is also what keeps the path inside `travelers/`. It transforms a **filename** only — the `Person` cell carries the name **verbatim**. If the result is empty, leave the cell bracketed and say which name needs a filename |
| Row 1 `Role / Relationship` | **DEFERRED** — the template's literal `Primary traveler / planner` is kept exactly as it ships | Keeping a template literal is not an assertion this command made, and `/trip-record` owns the cell thereafter |
| Rows 2+ `Role / Relationship` | **DEFERRED** — stays `[Relationship]` | Nothing at scaffold reads it; `/trip-record` owns it thereafter |
| `- **Travel mode:**` and `- **Subgroup notes:**` | **DEFERRED** — stay bracketed | Not in this command's ownership row; they fall to `/trip-record` |
| Ages, origins, dates, needs, desires, dietary, budget | **DEFERRED** — to the traveler intake form | The intake template is their home, and its own rule is never to invent an answer |

**When the stated total exceeds the names given.** Write roster rows for the names that were given,
and write the stated total. The two legitimately differ — *"six of us, I know four names"* — and the
difference is visible by arithmetic. **Never pad the roster with invented placeholder rows to reach
the total.** A `[Name]` row is indistinguishable from a real traveler with a missing profile, which
is exactly the confusion downstream must not inherit.

**When the user does not answer at all.** Leave the roster and `- **Total travelers:**` **exactly as
the template ships them** — bracketed — and **say so plainly**: the party is unrecorded, so nothing
downstream can enumerate who is missing a profile until it is, and `/trip-record` is where that goes.
**Invent no name and invent no count.**

**Why a bracketed `- **Total travelers:**` is not a harmless placeholder.** Three downstream
contracts are specified as if the number already existed:

1. **`agents/00-enrichment.md` — the `PROFILE MISSING` branch.** It writes one entry per traveler who
   has no profile, keyed to the name, so the gap stays visible to the hub and validator. Against four
   `[Name]` rows and a bracketed total it has no enumeration to complement: it either writes four
   ghost entries or writes none and silently loses the gap. The roster is the **denominator** for
   profile-gap detection and there is no second source for it.
2. **`templates/trip-context.template.md` — `### Per-Traveler Planning Days [DERIVED]`.** One row per
   traveler, and it reads each traveler's own profile **by link** — the `## Group` roster carries the
   path, so the roster is its input. Its single-origin collapse line is a count, not a description.
3. **`reference/data-model.md` — the satisfaction layer.** Desire-coverage is graded per traveler and
   group-equity is a balance signal across travelers; both take the party as their denominator, and
   needs-compliance has nothing to intersect without a traveler.

**Resizing the roster is not the same instruction as deleting a placeholder.** Outside the roster, an
unfilled field is **left** as its bracketed placeholder and never removed to express an unknown.
Inside the roster, rows **are** added and deleted — because the roster's row count is *data about the
party* rather than a field awaiting an answer.

## Traveler intake — always render this

Creating `travelers/` does not discharge the intake obligation. An empty `travelers/` is
indistinguishable from a group with no constraints, and those are not the same thing.

**No file is ever created under `travelers/`.** The directory is created; the profiles are not. No
name is invented, and the intake form's own rule is never to invent an answer.

Tell the user all four of these:

1. **Where a profile goes** — `trips/<slug>/travelers/<name>.md`, with the real resolved slug filled
   in, **one file per person.**
2. **The three ways to fill one in**, offered in this order:
   - **Walk through it here** — about two to three minutes for the starred fields.
   - **Fill it in themselves** — copy `templates/traveler-intake.template.md` to the path above and
     work through it.
   - **Send it to someone who is not here** — hand them the whole template file and have them paste
     it into any assistant with the one line the guide at the bottom gives them, then save the block
     it returns to the path above. On a group trip this is how most travelers will do it, so **never
     drop this option.**
3. **Where the profile ends** — only the content **above** the `# END OF PROFILE` line is the
   profile. The guide below that line is instructions for whoever is helping, not content.
4. **The roster points at the gap on purpose.** With real names written, the roster reads
   `travelers/dana.md` for a file that does not exist yet — a **named** standing reminder inside the
   file rather than something to tidy away. That is the point of having filled it in.

## What this command never does

**Each bound here is labelled by what establishes it, and the three bases are not interchangeable.**
A **rule** holds because this file says so, and nothing but this file says so. A **declared** denial
names a `disallowed-tools` entry as corroboration — a restriction whose runtime force this repo does
not establish, per the contest stated at the top of this file. And a tool left off `allowed-tools`
establishes **nothing**: omission is not prohibition, so no bound below is claimed from one.

- **It dispatches no agent.** A **rule**. The agent-dispatch tool is neither granted nor denied here,
  so the deny grammar does not reach it and the allow side would forbid nothing either way; the bound
  is that no construct in this file dispatches one, and naming a command is not dispatching one.
- **It runs no script, reaches `scripts/publish-trip-site.sh` by no route, and never sets
  `ALLOW_PLAINTEXT`.** A **rule**, corroborated by **declared** denials of that script and of the
  `bash` and `sh` wrappers. The wrapper denial is an enumeration, so a shell outside it is not denied
  by it — which is why the rule, and not the list, is what carries this. `ALLOW_PLAINTEXT` rests
  additionally on `ADR-007` § 2, **bound 3**, which forbids it to every command and is not negotiable
  by a later slice.
- **It writes no `[ENRICH]` block, no `[DERIVED]` block, and no lifecycle marker line.** A **rule**,
  resting on `CLAUDE.md` § *Write ownership*: the `[ENRICH]` fields belong to the enrichment agent,
  the `[DERIVED]` blocks to no writer at all, and the `**Lifecycle:**` line to `/trip-decommission`.
- **It writes only under `trips/<slug>/`, and only files that do not already exist.** A **rule**, and
  the one that satisfies `ADR-007` § 2, **bound 5**. It is the create-only rule stated at the top of
  this file, restated here as a bound rather than re-derived — and, as there, it holds without either
  account of `disallowed-tools` being the true one.
