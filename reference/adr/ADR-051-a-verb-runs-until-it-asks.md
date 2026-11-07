# ADR-051: A verb runs until it asks — what a run nobody can answer writes, stated in each command file's standing clause, cited by every verb on the declared-intent side, and holding whether or not a session recognises print mode

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1671 (carrying #1947), in the *Each verb's reads and writes are stated truly*
  milestone. Its design placed the rule and stated what it says, and the operator ruled at that
  milestone's Collective Review that the rule is written down as a record, on the threshold this
  corpus sets for one: a decision that is cross-cutting or hard to reverse. This record transcribes
  the design's decisions on where the rule lives and what it says, and the review's reading of why a
  record is owed.
- **What this record is.** A decision about **what a verb writes when no later message can reach
  the session**, and about where that rule is stated. It is addressed to whoever writes or edits a
  verb section in `skills/*/SKILL.md`, or adds a command file.
- **What this record is not.** It changes no verb's confirmation shape, no grant and no refusal a
  verb already states, and it widens no write any verb is bounded to.

## Context

A command file's `allowed-tools` is a pre-approval grant, and it clears at the next message; so a
command's conduct has to be written as a rule the command follows, never as a property its
frontmatter guarantees ([ADR-007](ADR-007-command-entry-point.md) § *Context*). That premise has a
consequence nothing stated until now. A run is non-interactive where no later message can reach the
session: print mode, or a scheduled task. In such a run an answer never arrives, and if one did, the
grant a write behind it relied on would already have cleared. #1524's live pass observed the second
half: a write taken in the turn after a question was denied.

What a verb then does was stated verb by verb, and most verbs said nothing (#1947). The verbs that
did say were not alike. `## link`'s gated branch refuses a run nobody can answer and its clean branch
runs, so that nothing that runs today acquires a gate; `## erase` states that it has no
non-interactive path; others refuse by a row of their refusal table. A reader of a verb that said
nothing could not tell whether a run nobody can answer refuses, writes without a confirmation, or
stops at a permission denial.

No measurement in this repository establishes whether a session recognises that it is running in
print mode. A rule that depended on that recognition would rest on what nobody has observed.

**Why this is a record and not an amendment.** `reference/adr/README.md` § *Convention* asks for a
record where a decision is cross-cutting **or** hard to reverse. This rule binds every verb of every
command, present and future, under each standing clause's extension rule, so it is cross-cutting
whatever it would cost to reverse. [ADR-007](ADR-007-command-entry-point.md) § *Context* supplies its
premise and states no rule about what a run then does. The nearest precedent,
[ADR-022](ADR-022-interview-session-model.md) D6.1's refuse tier, refuses a whole run — "the
interview does not run" — on a predicate of its own, no write path and no text-returnable surface,
which is the option this record rejects below. The rule is new text a reader must follow, and
§ *What an amendment may add* puts that outside what an amendment may carry.

## Decision drivers

- **A command's conduct is the command's to state.** [ADR-007](ADR-007-command-entry-point.md)
  § *Context* requires it, and the runs this rule is for are the ones least likely to read
  `CLAUDE.md`: on Claude Code 2.1.280, in print mode, no verb read it in any run measured.
- **Nothing that runs today acquires a gate.** A verb that writes without asking anything still
  writes in the turn it was typed in.
- **No reliance on a recognition nobody has measured.** The rule's effect is the same whether or not
  a session knows it is in print mode.
- **A write behind an answer holds no grant when the answer comes**, so no rule may treat a later
  answer as available.
- **Copies a suite can hold equal.** Where a text has to stand in more than one file, a required
  check grades the copies as one text.

## Options considered

Where the rule lives:

1. **(A) The same text in each command file's standing clause, cited by each verb.** **Chosen —
   see below.** Every installed verb can read it, the standing confirm rule already ships this
   shape, and a suite can hold the copies equal.
2. **(B) A row in every verb's refusal table.** **Rejected.** *Kill-reason: a normative sentence
   copied into every verb section, most of which carry no such table, where a rule with a home is
   cited there* (`CLAUDE.md` § *Editing an engine file*).
3. **(C) One rule in `CLAUDE.md` § *Resolving a trip*, cited by each verb.** **Rejected.**
   *Kill-reason: the runs it is for are the least likely to reach it* — on 2.1.280 in print mode no
   verb read `CLAUDE.md` in any run measured — and [ADR-007](ADR-007-command-entry-point.md)
   § *Context* makes a command's conduct the command's to state.
4. **(D) The rule in the standing clauses, cited by no verb.** **Rejected.** *Kill-reason: a verb
   inherits it, but a reader of that verb cannot see that it does*, which #1671 asks a verb to show
   by citing the rule.

What the rule says:

5. **(E) A verb runs until its section asks, and stops there.** **Chosen — see below.** It is the
   split `## link` already ships, and it takes nothing from a verb that asks nothing.
6. **(F) Every verb that writes refuses a non-interactive run.** **Rejected.** *Kill-reason: `## link`
   states the opposite in terms* — its clean branch does not refuse, so that nothing that runs today
   acquires a gate — *and it would take away what a typed `/trip-record mode` does in one turn.* It is
   also [ADR-022](ADR-022-interview-session-model.md) D6.1's whole-run refusal, carried to verbs
   whose predicate is not that tier's.
7. **(G) Each verb decides.** **Rejected.** *Kill-reason: it is the state #1947 reports.*

## Decision

**1. A run nobody can answer writes only what its verb writes without asking.** A run is
non-interactive where no later message can reach the session: print mode, or a scheduled task.
Where a verb's section reaches a write without asking anything, the write runs in this turn, under
this turn's grants, because typing the verb is what asked for it. Where the section asks first — a
question, a choice of routes, a confirmation, a typed token — the verb stops there: it names what it
would have asked, writes nothing past that point, and takes no default, no assumed answer and no flag
in the answer's place. What it wrote before that point stands, and it says so. A write the harness
denies is relayed as a denial and never reported as done.

**2. The rule does not rest on recognising print mode.** A question nobody answers writes nothing
either way, so a session that does not recognise the run writes no more than the rule allows. A
verb's own non-interactive row stands, and stops no later than this rule would.

**3. The rule is stated in each command file and cited by each verb on the declared-intent side.**
The same text stands in each command file's standing clause, because a citation to another
command's file would make this command's conduct that file's to state. A verb whose read declaration
does not declare that it writes nothing, that it dispatches no agent and that it performs no act
whose effect lands outside the trip's own files — the fail-closed line
[ADR-007](ADR-007-command-entry-point.md) § 1 draws — carries the rule's citation or a statement of
its own. `CLAUDE.md`'s paragraph on the evidence grants in print mode speaks for evidence reads alone
and names the rule.

**4. The rule is followed, not enforced.** No frontmatter key makes a session stop at a question.
`scripts/test-command-taxonomy.sh` group NR grades presence: each command file states the rule, the
statements are the same text, and each verb on the declared-intent side carries the citation or its
own statement. Whether a session follows it is observed live, never by a suite.

## Consequences

**Positive**

- A reader of any verb can tell, from that verb's own section, what a run nobody can answer does.
- No verb that runs today acquires a gate: a verb that writes without asking still writes in the turn
  it was typed in, and a verb that asks still asks.
- The rule's effect is independent of what a session makes of print mode.

**Costs, and what holds them**

- **Copies of the text in each command file**, held to the same text by group NR. A new command file
  carries the rule, and the group fails until it does.
- **A citation in each verb section on the declared-intent side**, held present by the same group.
  Presence is all it grades, so a citation on a verb that then behaves otherwise reads green.
- **Residual: a dispatched agent's writes in print mode have not been measured.** Where such a write
  is denied, the rule's last limb — a denial relayed, never reported as done — is what carries it.

**What this decision makes false or necessary elsewhere**

- Each command file's standing clause states the rule, and each verb section on the declared-intent
  side cites it in its first read declaration or states what a non-interactive run does in its own
  text. A verb section that already states it keeps its statement.
- `CLAUDE.md` § *Resolving a trip*, the paragraph opening "The evidence grants are each verb's
  declared minimum privilege", says that it speaks for evidence reads and names the rule.

## References

- The premise: [ADR-007](ADR-007-command-entry-point.md) § *Context*, on the grant that clears at
  the next message, and § 1, on the fail-closed inference line.
- The nearest precedent, and where it differs: [ADR-022](ADR-022-interview-session-model.md) D6.1's
  refuse tier.
- The rule beside which this one stands: the standing confirm rule, in each command file's standing
  clause.
- The cards and the observation: #1671 and #1947; #1524's live pass, whose write in the turn after a
  question was denied.
- Implementation: the standing clause of each `skills/*/SKILL.md`. Regression coverage:
  `scripts/test-command-taxonomy.sh` group NR.
