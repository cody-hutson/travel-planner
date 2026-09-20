---
name: travel-planner
description: Say what you want to do with a trip in your own words and be told which trip verb does it, with the options and the difference between them when more than one fits — it names the verb and hands you the exact command to type, and runs nothing itself.
---

# Travel Planner — the way in

Somebody has said, in their own words, what they want to do with a trip. This surface finds the
verb that does it and hands over the command to type. It is the way in for a person who does not
yet know the verb names, and it is the only part of this engine that reads a request before a verb
has been chosen.

It names a verb. It never runs one.

## What this surface declares

Stated as declarations rather than as description, because every other file in this engine
deliberately withholds itself from the model and this one does not. What it may do is therefore
written down here rather than left to be assumed:

- it **writes nothing**;
- it **dispatches no agent**;
- it **performs no act whose effect lands outside the trip's own files** — and in practice it
  performs no act at all, because naming a verb is the whole of what it does.

## Where the answer comes from

Read `CLAUDE.md` § *Step 1: Classify the request* **live, at the moment of invocation**, from
`${CLAUDE_SKILL_DIR}/CLAUDE.md`. This file's own directory is the engine root, so that charter sits
beside it. Its classification table is the routing map, and it is the only place a verb name may
come from on this surface.

**This file holds no verb list, no count of them, and no classification of its own.** That is the
design and not an omission. A second enumeration of the verb set is precisely the drift surface
`ADR-007` § 3 inverted the dependency to remove, and a list written down here would re-create it on
the one page a new user meets first. It is also what keeps this surface correct for free: a verb
added to the charter later is reachable from here with no edit to this file, and a verb that moves
or is folded into another is not left behind in a stale copy.

Read each candidate row's own cells, never a paraphrase of them:

- the **Signal** cell says what kind of request the row is for;
- the **Action** cell says what the row does, and where the row offers a choice it states the
  difference between the options in the charter's own words;
- the **Command** cell carries the outcome — a command to type, a declared exclusion, or a declared
  set of options.

## Reaching the verb

Every request lands in exactly one of these states. Work out which, then render only what that
state's row says to render.

| State | When it applies | What to render | Where it stops |
|---|---|---|---|
| **RESOLVED** | the request reaches exactly one option | name that option, and the exact command string to type | the typed hand-off |
| **CHOICE** | the request reaches two or more options, **and they are exactly the members of an authored `AMBIGUOUS:` row** | that row's members as the options, with that row's **own committed distinction** between them | a choice, never an execution |
| **NARROW** | the request reaches two or more options and they are **not** the members of an authored row | **one** question, built from the candidate rows' own Signal cells — then begin again with the answer | a question |
| **UNREACHED** | the request reaches no option at all | say plainly that the request reached no verb, name this surface, and stop | a statement |

**An option is a member of the row's set, and a member is not always a command.** Usually it is: a
command written in backticks, which the reader types. It may instead be a declared exclusion — the
charter's way of recording that the lightest-weight action is already the right one and needs no
verb at all. Both kinds are options and both are rendered. Counting only the commands would drop a
real option from a real choice, which is the guess this surface exists to avoid; a set always names
at least one command, so there is always something to hand over.

**Say which they are only where the charter has already said it; otherwise ask.** That is the whole
of the difference between CHOICE and NARROW. Where an `AMBIGUOUS:` row exists, its Action cell
already carries the distinction between its options and that distinction is stated as written.
Where no such row exists, the difference has not been committed anywhere, and inventing one here
would be a classification this surface has no standing to make — so it asks instead, from the
candidates' own Signal cells, and takes the answer.

**Render a declared exclusion as what it is.** It has no command string, because there is no verb
to type: describe it in the row's own terms as the direct action it names, and hand over a command
string only for the options that have one.

## Handing over

In every state that reaches a verb, name the verb and give the **exact command string** to type —
then stop. Take that string's operand signature from the derived **Arguments** column of
`${CLAUDE_SKILL_DIR}/reference/command-reference.md`, read live at the moment of the hand-off and
never copied into this file: fill the operands the request already supplied, and render the rest as
the placeholders that column spells.

**That path is anchored to the skill directory for the same reason the charter read above is, and
the reason is not stylistic.** This file's own directory is the engine root, so the reference sits
beneath it — while a bare relative path resolves against the **session's working directory**, which
on an installed engine is wherever the operator happened to open a session and is not the engine
root at all. Named bare, the read either fails or has to be recovered by a search, and a search is
not available on every installation.

That is the whole of the terminal, and deliberately so. The person typing the verb token is itself
the declaration that `ADR-007` § 1's amendment requires on a retained arm, so this surface needs no
confirmation step of its own and claims no control it does not hold. A confirmation rendered here
would be a gate asserted by a file that executes nothing, which is worse than no gate at all: it
would read as protection while protecting nothing.

## What this surface never does

Written as prohibitions because what gets eroded first is what was merely left unsaid.

- It never runs a verb.
- It never writes.
- It never dispatches.
- It never reads a trip's content.
- It never reads the data-root pointer.
- It never resolves a trip.
- It never offers a near-match on a mistyped token. No token was typed here — a request arrived in
  ordinary words — so there is nothing to near-match, and the prohibition the verb files carry
  against near-match suggestions is left exactly where it is rather than weakened by analogy.
