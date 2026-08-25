---
description: Start a new trip — scaffolds the folder, context, log and traveler intake. Creates only; never overwrites an existing trip.
argument-hint: [destination-year]
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(date:*), Bash(mkdir:*), Read, Write
disallowed-tools: [Edit, NotebookEdit]
---

# New trip setup

Scaffolds a new trip: the trip directory, `outputs/`, `travelers/`,
`trip-context.md` from the template, and `trip-log.md` with its first session
entry. Sets the starting mode from what the user has actually stated, and hands
off to traveler intake.

**This command creates. It never overwrites.** Re-running it against a trip that
already exists adds only the members that are missing and leaves every existing
file exactly as it is. `trips/` is git-ignored, so there is no history to restore
from — a rewritten `trip-context.md` or `trip-log.md` is gone for good.

Takes an optional `[destination-year]` argument, such as `lisbon-2027`. The
argument is text. It is never executed, and it proposes a name rather than
settling a decision.

## Existing trips

!`ls -1 ${CLAUDE_PROJECT_DIR}/trips`

## Today

!`date +%F`

## What to do with this

Both blocks above have already run and their output is above. The first block is
the whole of the trip population you have read — do not list `trips/` again, and
do not read an existing trip's files to decide what to do here.

Work the three gates in order. Do not skip ahead to the scaffold.

### Gate 1 — is the listing trustworthy?

`trips/` always contains the tracked `README.md`. It is the only tracked file
under `trips/`, so a healthy repo always shows it.

**If `README.md` is not a line in the first block, the listing failed.** Either
the project directory did not resolve, or `trips/` is missing. An empty or
error-shaped block is *not* evidence that no trip exists.

In that case: say plainly that the trip listing could not be read, name `trips/`
as the directory that could not be listed, and **stop. Create nothing.** Do not
scaffold, do not create a directory, do not write a file.

Every other entry in the first block is a trip directory.

### Gate 2 — resolve the slug

The slug is `<destination>-<year>`, lowercase and hyphenated — `lisbon-2027`,
`tokyo-2026`. It is the trip's folder name.

- If the user passed an argument, that is the proposed slug.
- If they did not, and the conversation has settled a destination and a year,
  propose that.
- **If neither, ask for it.** Do not invent a slug, and never create a directory
  under a placeholder name.

**Check the slug's shape before using it for anything.** It becomes a directory
name, so a slug that is not a plain name does not stay inside `trips/`. A slug is
valid only if it is non-empty, begins with a letter or a digit, and every
character is a letter, a digit, `.`, `_` or `-` — one rule that rejects a path
separator, a `..` segment, a leading dot, and anything non-ASCII. It is the rule
`scripts/publish-trip-site.sh` already applies to a publish slug.

**If the slug fails that check, say plainly what was rejected and why**, name the
shape above as the form a slug takes, ask for a corrected one, and **stop. Create
nothing.** Do not scaffold, do not create a directory, do not write a file. The
argument is text, and a rejected slug is never repaired by guessing at what was
meant.

**Lowercase the slug that passes.** The documented form is lowercase, and Gate 3's
comparison is the only thing standing between a new trip and a live one — so
`Lisbon-2027` and `lisbon-2027` must not resolve to two different answers. Carry
the lowercased slug forward: it is the slug for Gate 3 and for every member below.

### Gate 3 — does it already exist?

Compare the resolved slug against the lines of the first block, **ignoring case on
both sides**. The volume folds case, so a directory differing only in case is the
same directory — reading it as a new trip would scaffold straight into a live one.

- **Not a line** → the trip is new. Go to **Create**.
- **A line** → the trip exists. Go to **Resume**, under the name exactly as the
  first block spelled it rather than the lowercased form — that is the directory
  that is actually there.

## Create

Build all eight members, in this order.

| # | Member | How |
|---|--------|-----|
| 1 | `trips/<slug>/` | created by member 4's write |
| 2 | `trips/<slug>/outputs/` | `mkdir -p` |
| 3 | `trips/<slug>/travelers/` | `mkdir -p` |
| 4 | `trips/<slug>/trip-context.md` | Read `templates/trip-context.template.md`, then Write it with the title line, `Current mode` and `Mode notes` filled |
| 5 | `trips/<slug>/trip-log.md` | Write, one initial session entry |
| 6 | the mode value | the mode rule below |
| 7 | the mode basis | written into `Mode notes` **and** the log entry |
| 8 | the intake handoff | rendered with the resolved slug |

Member 4 keeps every other field of the template exactly as it is — the bracketed
placeholders are the form the user fills in through conversation. Fill only the
title line, `Current mode`, and `Mode notes`. Write the mode's actual value, never
the bracketed list of options.

The title line `# Trip Context — [DESTINATION] [MONTH] [YEAR]` takes the trip's
own destination and year. Leave the month bracketed if it is not known yet.

Member 5's entry follows the `trip-log.md` structure `CLAUDE.md` documents, dated
from the second block above:

```markdown
# Trip Log — <Destination> <Year>

## Session <the date from the Today block> — Trip setup
**Topics:** Trip setup — directory scaffolded, starting mode set
**Decisions:**
- Starting mode <MODE> — <the basis, naming what the user stated>
**Rejected:**
- <the mode considered and not taken, and why — omit this line if nothing was in contention>
**Next steps:** <the mode-consequent next move, plus traveler intake>
**Open questions:** <any unresolved conflict — omit if none>
```

Use the bare `YYYY-MM-DD` date form, exactly as the second block printed it.

## Resume

The trip already exists. **Do not rewrite anything.**

1. Say which members already exist and which are missing.
2. Create only the missing ones. `outputs/` and `travelers/` use `mkdir -p`,
   which no-ops when the directory is already there. Write `trip-context.md` or
   `trip-log.md` **only if genuinely absent**.
3. If `trip-context.md` exists, **leave it.** Do not re-derive the mode, do not
   touch `Mode notes`, and do not read it to decide anything here.
4. If `trip-log.md` exists, **leave it.** Do not append a setup entry — this is
   not new-trip setup, and session logging is already covered by the existing
   request types.
5. Render the traveler-intake handoff below.
6. Name `/trip` for orientation on the trip as it stands.

This branch is the repair path for a trip created before `travelers/` was part of
the scaffold.

## The starting mode

Set the mode from what the user has **stated in this conversation**. Three rules,
first match wins.

| Order | What must be affirmatively stated | Mode |
|-------|-----------------------------------|------|
| 1 | A booked transport or lodging anchor — a flight, train, or place to stay the user says is booked, confirmed or paid, specific enough to be an anchor (a date, or a named property) | **ENRICHMENT** |
| 2 | A committed destination — where the trip is going, stated as a decision rather than a candidate | **DISCOVERY** |
| 3 | Neither of the above | **IDEATION** |

Only these three values are reachable here. `ITERATION` and `RESEQUENCING` both
presuppose an existing plan, and at setup there is none.

### What counts as evidence

- **Stated, not inferred.** It has to be something the user said in this
  conversation. This is a new trip; there is no prior session to recall.
- **A bracketed placeholder is never evidence.** `trip-context.md` was written
  from the template moments ago, so every field in it still reads `[like this]`.
  Never read it back and treat a placeholder as an answer.
- **Absence is never evidence for the rung below.** "They did not mention
  flights" does not make it DISCOVERY. Rule 2 needs its own affirmative
  destination statement.

### The slug proposes; the user confirms

`/trip-new lisbon-2027` names Lisbon. That alone does **not** reach rule 2 —
someone still weighing Lisbon against Porto types a slug anyway, because the
folder needs a name. Treating it as settled would silently skip Destination
Ideation.

Ask once: *"Is Lisbon settled, or still one of the options?"* One question, not a
questionnaire.

### When the evidence is thin, and when it conflicts

These are two different situations and they get different treatment.

**Not enough evidence is not ambiguity.** Nothing affirmative for rule 1 or rule 2
resolves to **IDEATION** by rule 3, deterministically. Do not ask. Leaving
IDEATION later costs one field edit, whereas a wrongly-promoted ENRICHMENT tells
every agent to plan around anchors nobody booked. **Default downward, never
upward.**

**Conflicting evidence is real ambiguity** — something satisfies a higher rung and
something contradicts it, as in *"flights are booked but we might switch to
Porto."* It is never resolved silently.

1. Ask exactly one question, naming both candidate modes **and what each one
   means**: DISCOVERY runs the full pipeline with all agents; ENRICHMENT runs the
   full pipeline with agents planning around fixed anchors.
2. If they answer, take their answer.
3. If they decline, or the answer does not resolve it, take the **lower** of the
   two candidates and record the unresolved conflict. Never invent a resolution.

### Record why, not just what

The mode value alone does not say what was known. Write the basis in both places:

- **`trip-context.md` → `Mode notes`** — one line naming the evidence that
  selected the mode, plus any unresolved conflict. For example:
  `IDEATION — destination not settled (Lisbon and Porto both in play at setup). No transport or lodging booked.`
- **`trip-log.md` → the initial entry** — `Decisions:` carries the mode and its
  basis, `Rejected:` carries a mode considered and not taken, and
  `Open questions:` carries an unresolved conflict.

A later reader should be able to see whether the mode rests on a booking or on a
guess.

### What the mode means for the next move

- **IDEATION with no destination settled** — name **Destination Ideation** as the
  next move: the prompt at `agents/destination-ideation.md`, producing
  `outputs/destination-shortlist.md`, a ranked shortlist for the group to decide
  from. **Name it; do not dispatch it.** Dispatching an agent is a different
  request type with its own command and its own permissions.
- **DISCOVERY or ENRICHMENT** — say the trip is ready for the full pipeline once
  traveler profiles are in, and that building the first full plan is the
  expensive operation, so the profiles are worth having first.

## Traveler intake — always render this

Creating `travelers/` does not discharge the intake obligation. An empty
`travelers/` is indistinguishable from a group with no constraints, and those are
not the same thing.

**Do not create any file under `travelers/`.** No names are known yet, and the
intake form's own rule is never to invent an answer.

Tell the user all four of these:

1. **Where a profile goes** — `trips/<slug>/travelers/<name>.md`, with the real
   resolved slug filled in, **one file per person**.
2. **The three ways to fill one in**, offered in this order:
   - **Walk through it here** — about two to three minutes for the starred
     fields.
   - **Fill it in themselves** — copy `templates/traveler-intake.template.md` to
     the path above and work through it.
   - **Send it to someone who is not here** — hand them the whole template file
     and have them paste it into any assistant with the one line the guide at the
     bottom gives them, then save the block it returns to the path above. On a
     group trip this is how most travelers will do it, so never drop this option.
3. **Where the profile ends** — only the content **above** the
   `# END OF PROFILE` line is the profile. The guide below it is instructions for
   whoever is helping, not content.
4. **The roster is left pointing at the gap on purpose.** The `## Group` table in
   `trip-context.md` still reads `travelers/[name].md` on every row, and those
   files do not exist yet. That is a standing reminder inside the file, not
   something to tidy away.

## What this command never does

It never dispatches an agent, never runs a script, never touches
`scripts/publish-trip-site.sh`, and never sets `ALLOW_PLAINTEXT`. It writes only
under `trips/<slug>/`, and only files that do not already exist.
