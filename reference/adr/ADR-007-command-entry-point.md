# ADR-007: Command entry point — surface shape, privilege boundary, and taxonomy ownership

- **Status:** Accepted (2026-08-22)
- **Deciders:** repo maintainer
- **Driving work:** the Command entry point epic (#252); establishes the surface shape and privilege
  model its child slices build against, and fixes the sequencing constraint that binds the
  publish-addressing slice to #123.

## Context

Every way into the planner is a free-form chat. `CLAUDE.md` § "How to Use This" already holds a
complete dispatcher — a Step-1 table mapping intent signals to actions, each paired with a Step-2
rule for how much trip state to read. That dispatcher is **implicit**: it fires only if the model
reads the table and classifies the user's prose correctly. Four consequences followed, each
observable in the repo as it stood when this decision was taken — the nine agents and every request
type the table carried were invisible at the prompt; classification is probabilistic, and `CLAUDE.md`
warns against the precise failure ("Don't dispatch agents to change an emoji"); sessions started cold
with no consistent action that re-established trip and mode; and `README.md`'s install path handed a
newly-cloned repo exactly one first move — "Tell Claude you want to plan a trip" — which was prose to
type into the same free-form chat rather than anything the repo made addressable.

**Three of those four record the state this decision was taken against, not the state now, and they
are left in that tense rather than reversed.** The first, third and fourth describe the repo as it
then was, with no command file in it. The surface this decision authorises has since shipped: the
commands live in `skills/`, and `CLAUDE.md`'s Step-1 table carries a Command cell on every
row — naming a command or a declared exclusion — which is the coverage invariant §3 below makes
checkable and
which `scripts/test-command-taxonomy.sh` grades on every push. The second consequence is the standing
one, and is written in the present for that reason: classifying free-form prose stays probabilistic
whatever surface sits in front of it, which is why the decision rests on declared intent rather than
on better classification. **This section fixes no count of commands or verbs**, because that set
grows and a count here would read its growth as drift; the surface is read from that directory and
that column.

The engine's functions already existed. What was missing was a way to **address** them.

What makes a command surface a different class of fix from better documentation is that a Claude
Code command file is not merely a prompt shortcut. It carries two mechanisms the prose cannot:
`allowed-tools` and its companion `disallowed-tools`, a **declared** per-file permission posture;
and `!`-prefixed bash pre-execution, which runs before the model sees the prompt and injects its
output — **deterministic** context loading rather than an instruction to go read something. A
command therefore converts instruction into mechanism, which is exactly what the four consequences
above need. `CLAUDE.md` was already correct; what it was not is **addressable** — at that point
nothing in the repo let a user invoke one of its rows. That is the gap this decision closes, and the
tense is the one the paragraph above explains.

The strength of that first mechanism is worth stating precisely, because the obvious reading
overstates it. `allowed-tools` is a **pre-approval grant**, not an enforced permission set: every
tool remains callable, a tool left off the list is not thereby forbidden — it routes through the
usual permission settings instead — and the grant clears at the next message. `disallowed-tools`
does remove the named tools from the pool, which is a real restriction, but it is turn-scoped in the
same way. **Durable blocking needs a permission-settings deny rule — a different artifact, and one
this release deliberately does not ship.** Two things follow. Least privilege on this surface is
*declared and pre-approved* per file rather than *enforced* per file, which is the strength at which
the second decision driver below should be read. And a command's conduct has to be written as a rule
the command follows, never as a property its frontmatter guarantees. The decision itself is
untouched: its load-bearing claim is that declared intent beats inferred intent, so misrouting is
removed by construction — and that rests on the declaration, not on enforcement.

One property of the existing publish path shapes this decision decisively. `scripts/publish-trip-site.sh`
protects its plaintext branch with a **TTY-conditional** gate: `if [ -t 0 ]` prompts for a typed
`PUBLISH` confirmation, and the `elif` branch refuses unless `ALLOW_PLAINTEXT=1` is set. The
encrypted branch additionally runs `verify_ciphertext` before every push; the plaintext branch does
not — it copies the rendered HTML straight to `index.html`. That branch is no longer *unguarded*,
though: the content-guard gap #123 recorded has since been filled by a **different** predicate, a
publishable-content check inserted immediately above the copy. `verify_ciphertext` itself remains
encrypted-branch-only, so the two branches carry different guards rather than one guard reaching
both. Bash pre-execution inside a command file runs with stdin **not** a TTY. A command wrapping
that script therefore lands on the side of the branch where the typed confirmation structurally
cannot fire. `cmd_unpublish` has the same shape: its `--yes` flag skips the confirmation, and a
non-interactive caller needs that flag to function at all.

## Decision drivers

- **Declared intent beats inferred intent.** Misrouting is the costliest of the four consequences,
  and only a declaration eliminates it — any shape that still asks a model to classify prose
  re-imports the problem it was built to remove.
- **Least privilege is per-file.** `allowed-tools` is declared per command file, so the surface
  shape *is* the permission granularity. This makes a UX question into a security question.
- **The publish path's human gates are TTY-conditional.** Any non-interactive caller lands where
  they cannot fire, so the surface must not silently substitute itself for a human at a terminal.
- **One taxonomy, not two.** A command set that restates the Step-1 table creates a live drift
  surface between two descriptions of the same thing.
- **Address, do not modify.** The agent roster and the publish script are reused as they are; this
  layer adds a way to reach them and changes neither.

## Options considered

1. **A single command with modes** (`/trip food`, `/trip publish`). Rejected on two counts. The
   model still parses the subcommand out of `$ARGUMENTS`, which re-imports probabilistic
   classification one level down; and because `allowed-tools` is per file, one command must declare
   the **union** of every function's tools — so a food query would execute carrying publish-capable
   permissions. The privilege union, not the ergonomics, is what disqualifies it.
2. **Discrete commands only** (`/trip-new`, `/trip-plan`, `/trip-publish`). Sound on privilege and
   on routing, and it gains tab-completion discoverability. Rejected as the whole answer because it
   provides no single entry point — the newly-cloned-repo case still has no one concrete first move.
3. **Auto-routing** — one command that classifies the request and dispatches. Rejected: this is the
   current behavior with extra steps. Classification stays probabilistic, so it addresses none of
   the misrouting consequence while adding a surface to maintain.
4. **A read-only dispatcher plus discrete privileged commands.** Chosen — see below.

## Decision

### 1. Surface shape

`/trip` is the **single entry point**: a read-only command that pre-loads the active trip and its
mode, states what is available and what comes next, and mutates nothing. Alongside it sits one
**discrete command per privileged function**, each declaring the minimum `allowed-tools` for its own
job.

This keeps "one thing to remember" as the user-facing affordance and "one authorization per
function" as the security property. The two are not in tension once the dispatcher is read-only:
discoverability is served by the entry point, and least privilege by the commands it points to.

**Amendment (2026-08-28, Friday) — the chosen shape has been narrowed: the dispatcher is not
read-only.** The two paragraphs above stand as the record of what was chosen and are not rewritten,
and neither is Option 4's label, which names the shape by the very property this narrows. Both are
left as written on purpose: an ADR that edits its own decision text stops being a record of a
decision. What follows states the narrowing beside them.

`/trip` remains the **single entry point for addressing**. It is **not** read-only. Its
`allowed-tools` grant carries two write primitives — `Edit` and `Write` — and verbs that dispatch a
writing agent write through it. What survives is a read-only property held **per verb rather than per
file**: `status` states it as a rule the verb follows — *"It writes nothing and runs no script"* — and
`check` suppresses the validator's declared writes and offers a diff of `trips/<slug>/` as the
observable post-condition, rather than the words *writes nothing*. **Which verbs are read-only is
derived by reading each verb's own section for a stated no-write rule.** This amendment fixes no list
and no count, because the verb set grows and a count would read that growth as drift.

Two consequences for how the paragraphs above should be read. The tension they dissolve by making the
dispatcher read-only is dissolved instead by the **discrete privileged commands** — the half of the
chosen shape that held unchanged. And the privilege property is per-verb while a frontmatter field is
per-file, so no arrangement of the frontmatter expresses it; a verb's conduct is carried by the rule
its own section states, which is what § *Context* already requires of every command on this surface.

This amendment asserts nothing about what `disallowed-tools` does at runtime. This repository carries
more than one account of that and nothing in it arbitrates them, so no sentence above rests on any:
each is read from the `allowed-tools` grant or from a verb section instead.

**Amendment (2026-09-11, Friday) — the tool-list arbitration is discharged.** The paragraph
immediately above declines to arbitrate the tool-list keys, because nothing available to it when it
was written could. The published Claude Code contract now does, and it reaches this surface by name:
a Markdown file in `.claude/commands/` is documented as the older format of the same mechanism,
carrying the same frontmatter but for `name` and `paths`. Nothing above is rewritten — not that
paragraph, not the amendment it closes, not § *Context*'s account of the same keys. **The subject is
a risk this record declined to take a position on, not a decision**, so the status line is untouched:
a discharged risk is not a superseded decision.

**The contract is quoted rather than summarised**, because a summary would be one more account and
carrying more than one is the whole of the defect. On the grant:

> The `allowed-tools` field grants permission for the listed tools during the turn that invokes the
> skill, so Claude can use them without prompting you for approval. The grant clears when you send
> your next message, even though the skill content stays in context; invoking the skill again
> re-applies it for that turn. It does not restrict which tools are available: every tool remains
> callable, and your permission settings still govern tools that are not listed.

On the removal, and on what to reach for when a restriction has to outlive the turn:

> To remove tools from Claude's available pool while a skill is active, list them in
> `disallowed-tools` in the skill's frontmatter. The restriction clears when you send your next
> message.

> To block tools across all skills and prompts, add deny rules in your permission settings instead.

**The account § *Context* already gave is the one the contract confirms, clause for clause** — which
is why the arbitration lands on it rather than splitting the difference between the readings this
repository carries. `allowed-tools` is turn-scoped **pre-approval and not restriction**: every tool
stays callable, a tool left off the list falls through to the permission settings rather than being
forbidden, and the grant clears at the next message. `disallowed-tools` is turn-scoped **removal**,
the only real restriction of the pair. § *Context*'s conclusion is confirmed with its premises:
**durable blocking needs a permission-settings deny rule**, which the contract names as the remedy in
terms. The conclusion was reached here by reasoning about what a turn-scoped grant can and cannot do,
and it now rests on the contract instead. The wording it grounds does not move; the ground under it
does, and that is the change this amendment records.

**What the discharge removes is a standing caveat, not a claim.** No sentence above rested on either
account — each is read from the `allowed-tools` grant or from a verb section — so nothing above needs
restating now that the accounts are settled. § 2's bounds are untouched.

**The same source settles the per-file question the 2026-08-28 amendment reached by reasoning.**
`disable-model-invocation` is a **per-file boolean, and no per-verb key exists**. The published
invocation-control table is an **enumeration of the available states** rather than an illustration of
some of them, so the absence of a per-verb form is a documented negative and not documentation
silence — a distinction worth keeping, because the two warrant different confidence and this record
should not trade one for the other. It confirms against the contract what that amendment's closing
consequence concluded from the shape of the surface alone: the privilege property is per-verb, the
frontmatter field is per-file, and no arrangement of the frontmatter expresses it. **Splitting the
file is the only mechanism that does** — which is the shape § 1 chose for the tool grants, arrived at
there from the privilege union rather than from this key.

**That flag's documented effect is wider than its name, and belongs beside it.** The
invocation-control table's row for it reads *"Description not in context"* — so it does not merely
withhold the file from the model, it withholds any awareness that the file exists. Nothing on this
surface is discoverable unless a verb is typed, which is a property of the entry point this record
authorises and is stated here rather than left to be met.

**Two adjacent questions are not settled by this text, and are named so the discharge is not read
wider than it is.** Whether a `PreToolUse` hook fires at all for an injected `!` pre-execution block
is **unestablished** — nothing consulted here says either way. The refusal predicate for an unresolved
expansion inside such a block is **undocumented** — the abort path is described, the trigger that
reaches it is not. Both stay open, and no sentence in this record rests on either.

**Amendment (2026-09-18, Friday) — where inference is permitted, and where
declared intent is retained.** The decision above rests on *declared intent beats inferred intent*,
which the first decision driver states and which § *Context* calls the property that removes
misrouting by construction. A later initiative buys approachability by spending part of it. **This
amendment states which part may be spent, on which arms, and what is left standing after the
spending.** Nothing above is rewritten: § 2's bounds are untouched, the 2026-08-28 narrowing stands,
and the 2026-09-11 discharge stands. What follows is stated beside them.

**Inference can enter at more than one place, and only the first of them is enforced. They are kept
apart here, because a rule that runs them together claims a strength it does not hold.**

| Where inference can enter | What governs it | What that governance is |
|---|---|---|
| **Invocation** — whether a request in prose reaches this surface at all, with no verb typed | `disable-model-invocation`, declared per file | **Enforced.** The runtime declines the invocation, and while the flag is set it withholds the file's description from context as well |
| **Selection** — which verb an invocation runs, once the surface has been reached | the lookup each file states in its own § *Selecting the verb* | **Declared.** No frontmatter field expresses it |
| **Execution** — whether an act runs on a selection nobody declared | the confirmation the verb's own section states | **Declared.** No frontmatter field expresses it |

**Nothing in the frontmatter expresses a boundary finer than the file, and that was re-established
rather than carried over.** The 2026-09-11 amendment settled the model-invocation flag against the
published enumeration. Read again at the date above, the same reference carries no key of narrower
scope for the tool lists either; the permission-rule form that gates a model's use of a skill matches
the skill by name rather than by what follows it; and a hook declared in frontmatter registers when
the skill is first invoked, runs for the rest of the session, and receives nothing that names a verb
— so it can gate a tool call and cannot attribute one to the verb that made it. **Splitting the
surface remains the only mechanism that expresses the boundary**, which is the shape § 1 chose for the
tool grants and the shape the 2026-09-11 amendment recorded for this flag.

**The runtime does tell a typed invocation from a model's, and it tells the file nothing.** No field,
no substitution and no marker carries it. A file that is model-invocable therefore cannot establish
who supplied its argument string, and *"the verb is the one the user typed"* is a sentence whose truth
is held by the flag rather than by the file that states it. **That is the property being spent, named
exactly.**

**The line, by arm class, derived from what each verb's own section declares.** An arm is
**inference-admitted** where its own section declares each of these: that it **writes nothing**; that
it **dispatches no agent**; and that it **performs no act whose effect lands outside the trip's own
files**. Every other arm **retains declared intent** — including an arm whose section declares none of
them, because a property nobody has declared is not a property this line may assume. **The derivation
is the whole of the line: this amendment fixes no verb list and no count, and a verb a later slice
adds takes its side from its own section with no edit here.**

**Where in the section to read, fixed here rather than left to the reader.** Those declarations are
read from the section's own `**Reads:**` block and from nowhere else in it — the block every verb
section carries, and the one the taxonomy guard already parses. A statement made elsewhere in the
section does not count toward admission, and a block that does not carry all of them leaves its arm
on the retained side. **The boundary is fail-closed by construction**, so it can over-protect an arm
and can never under-protect one: where the block is silent, the arm retains declared intent.

**Why the admitted side is narrower than read-only — a different question, which the 2026-08-28
amendment already answers for its own purpose.** A verb that writes nothing may still dispatch an
agent, and a dispatch is spent whether or not it was wanted: no revert returns it. The failure
`CLAUDE.md` names by example is the dispatch nobody asked for, so a dispatching verb sits on the
retained side however little it writes.

**What retaining declared intent requires.** An act runs only on a declaration made in the same
exchange: the verb token typed by the operator, **or** a confirmation naming the verb and its target
which the operator answers before the act. Inference may reach a retained arm, may name it and may
prepare it; it may not execute on its own selection. Where a verb's section already states a
confirmation shape — an echoed outgoing-to-incoming pair, a preview total over a source's own
answered set, a typed identifier, a display name beside a member count — that shape stands unchanged
and this rule is added to it, never substituted for it.

**The confirmation is declared and not enforced, which is the half a later slice must not
overstate.** The tool lists are turn-scoped and they gate tools rather than acts, so no arrangement of
them makes a confirmation happen. The typed confirmations a non-interactive caller structurally
cannot answer belong to `scripts/publish-trip-site.sh`, and § 4 excludes every form they guard, so no
addressed form rests on one. A confirmation on this surface is a rule a verb follows — the form
§ *Context* requires of a command's conduct — and its strength is the strength of that rule.
**Saying so is the requirement; a slice that implemented it as though the frontmatter held it would
be claiming a control this record says is not there.**

**What the line costs on the mechanism this surface actually has.** The admitted side is a property
of arms and the enforced surface is a property of files, so the two meet in a single test: **a file
may declare `disable-model-invocation: false` only where every verb it declares is
inference-admitted.** A file carrying arms of both kinds cannot be relaxed for the cheap ones without
exposing the rest in the same act — the privilege union § 1 refused for the tool grants, arriving by
the other key. Where no file satisfies the test, the enforced posture does not move, and guided entry
is reached another way.

**A surface that only proposes satisfies the same test, and is named here rather than left to be
discovered.** A file that declares no verb of its own, writes nothing, dispatches nothing and acts
nowhere outside the trip's own files is inference-admitted by the test above; reaching a verb from it
is the operator typing what it named. **That is how prose can reach this surface with no verb file
relaxed at all**, and it spends none of the property named above.

**Consolidation, stated because it is in flight and is not decided here.** The line is a property of
arms, so it survives a change in how many files carry them. The enforced test is a property of files,
so under a single file it is evaluated over the union of every verb that file declares, and that union
holds retained arms. A consolidated surface that is model-invocable therefore exposes every arm it
carries, and one that is not carries this line as a declared rule alone. **The same asymmetry reaches
the tool grants:** a single file declares the union of every grant and can keep only the denials every
verb shares, so a denial that today holds for the turn of one verb is not expressible there. Which of
those to accept belongs to the record that decides a consolidated surface's privilege model; this
amendment states the consequence and takes no position on it.

**§ 2 is untouched, and what is not negotiable by a later slice is not negotiable by this one.** No
confirmation admits `ALLOW_PLAINTEXT`, none admits `--yes` to `unpublish`, and none makes an overwrite
or a deletion of existing trip content available: that bound's class is IRREVERSIBLE, and a
confirmation does not change a class. A confirmation is what an inferred selection needs **before** an
act the bounds already permit. It is never what makes an act they forbid available.

### 2. The privilege boundary

Six bounds hold on every command in this surface:

- A scoped invocation reads **no more** than the context its Step-2 row assigns. The `!`
  pre-execution mechanism that makes context loading deterministic can equally make it excessive —
  an unscoped preload on every invocation re-creates the over-read this epic exists to remove.
- Every command's `allowed-tools` is the **minimum** for its function. No command carries
  publish-capable tools unless it is the publish command.
- **No command may set `ALLOW_PLAINTEXT`, and no command may pass `--yes` to `unpublish`.** These
  are the two flags that convert a refusal into a silent pass on a non-interactive caller. This bound
  is not negotiable by a later slice.
- Every Step-1 row maps to exactly one command, **or** to a declared exclusion, **or** to a declared
  ambiguity set. A set's members are of two kinds: a member naming a verb maps to one command on its
  own row, and a member naming a **declared disposition** names one reason from the closed vocabulary
  and maps to no command at all. Every set names at least one verb. Silent gaps are not permitted; an
  unaddressed request type is a stated one, and a request type that reaches more than one command is a
  stated **choice** rather than a silent pick. *(Amended 2026-09-18, Friday: the third limb is added in
  the change that authors the first set, so the bound is never false. It was true of a Command column
  in which a row could only address a verb or declare an exclusion, and § 3 below admits the same class
  over the same rows — this limb and that identity are one statement seen from the bound and from the
  guard. Amended again in the change that admits a disposition as a set member: the two member kinds
  are named here because a bound stating only the first would be false at the first such member.)*
- **No command may overwrite or delete existing trip content.** A trip's working tree is git-ignored
  and carries no history, and `trip-log.md` **is** the rationale record rather than a copy of one —
  so a clobber is recoverable from nothing: not from a revert, not from the repo, not from the log.
  It is **IRREVERSIBLE**, which is the same class the two flags above are drawn from, not the cheap
  class it resembles. Three shapes satisfy this bound: create only what is missing; append under a
  new section rather than rewriting; or, where a derived artifact genuinely must be replaced,
  preserve the version being replaced first, or say before writing what will not survive. This bound
  is not negotiable by a later slice.
- **No command may treat a placeholder as evidence, and no command may predicate a branch on a
  field's absence where a placeholder makes that field present.** The templates ship every field
  bracketed, so a freshly-scaffolded trip *has* its `Primary destination` line — the line reads
  `[City, Country]`. The two halves are one mistake seen from opposite sides: reading the bracketed
  text as an answer promotes a trip that has settled nothing, and testing the field for absence finds
  it present and promotes the same trip by the other route. Where a branch means *not yet decided*,
  it tests the **value** against the placeholder form; absence is a different condition — a malformed
  or truncated file — and it is never the same branch. The cost is silent: the branch that misfires
  is the one whose whole purpose is to run the agent that resolves the undecided field, so the
  command proceeds against placeholder text and the agent never runs.

### 3. Taxonomy ownership

The command set **is** the request taxonomy; `CLAUDE.md`'s Step-1 table documents it. The dependency
is deliberately inverted from the obvious direction: had the commands restated the table, the two
would drift and a test would be needed to catch it. With the commands owning the taxonomy, the guard
becomes a cheap assertion of **coverage** — every Step-1 row resolves to a command or a declared
exclusion, and every unit of the command surface is covered by exactly one **addressed** row.

Under a `/trip <verb>` surface the unit is a (command, verb) pair, not a command, which is why this is
stated as coverage rather than as the one-to-one mapping an earlier draft of this section named: a
verbed **addressed** row covers the pair it names, a verbless **addressed** row covers every verb its
command declares, and where a command declares no verb the command itself is the unit. The guard
grades that this mapping is total and non-overlapping. It does not grade whether the taxonomy the
table documents is the right one — that stays review-maintained.

**Amendment (2026-09-18, Friday) — the identity admits a further row class, and the word
*addressed* above is what admits it.** The statement of coverage was written for a Command column
in which a row could only address a verb or declare an exclusion, and it is correct for that
column. A later slice admits an **ambiguity set**: the marker `AMBIGUOUS: `, then full-key code
spans joined by ` · `, each span matching the cell grammar **unchanged**. A set is how a row says
that an intent reaches more than one verb and is therefore rendered as a choice rather than
resolved to one. It is **declared** by its marker and is never inferred from a parse failure —
code spans joined in one cell without the marker remain a hard failure — so the accident and the
intent take different branches rather than the same one. This amendment restates the identity by
**narrowing its quantifier, not by weakening its predicate**, and what follows is the whole of the
restatement.

- **Totality does not weaken.** Every unit of the command surface is still covered, and set
  membership never satisfies that obligation. A verb reachable only as an option inside a set is
  an uncovered unit and a finding, exactly as it was before sets existed.
- **Exclusivity is unchanged where it bit.** A unit covered by more than one *addressed* row is
  the finding it always was, reached through the same predicate over the same records. What is
  new is only this: a unit named in a declared set **beside** its own addressed row is a choice,
  not a double cover.
- **A set carries obligations of its own.** Its members are of two kinds. A member naming a **verb**
  resolves to exactly one coverage unit — a member naming a whole command is refused, because a command
  is itself a choice. A member naming a **declared disposition** carries the exclusion marker and exactly
  one reason from the closed vocabulary § 4 states; it resolves to no coverage unit, because a
  disposition is not one, and a set whose members are all dispositions is refused, because a row that
  routes to no command is an exclusion rather than a choice. Across both kinds: nothing is named twice
  inside one set, and no two sets denote the same options.

*(Amended in the change that admits a disposition as a member. The bullet is edited in place rather
than corrected beneath, because a reader who stops at the bullet would otherwise carry away a rule that
is false — the same disposition taken in § 2's bound above, for the same shape. What did not change:
totality and exclusivity above, whose predicates and whose records are untouched. A disposition mints no
coverage unit and contributes no cover, so the identity is total over exactly the population it was
total over before.)*

What this amendment does **not** reach: the guard still does not grade whether the taxonomy the
table documents is the right one, and §4's disposition table is untouched, its cells still parsing
under the same unchanged cell grammar. The amendment governs the coverage identity stated in this
section and nothing else.

The guard is a test in the shape of the existing `scripts/test-publish-guard.sh`, which already
proves the pattern in this repo.

### 4. The publish lifecycle is excluded from the first release

Because the surface cannot reach the TTY-conditional gates described above, and because
`verify_ciphertext` is absent from the plaintext branch, the publish lifecycle is
**not addressed by a command in the first release**. Where publishing is the user's intent, the
surface **prints the terminal command for the operator to run** — a handoff that preserves every
existing control at zero engineering cost.

The publish-addressing slice sequences **behind #123**. When it lands, the trust boundary between
the command surface and the publish script opens for the first time and earns its own control
review; it is deferred here, not solved.

**Amendment (2026-08-24, Monday) — the deferral is discharged.** The decision above stands as the
record of the first release. Its substance is preserved; only a stale temporal clause naming the
content-guard dependency has been corrected in place, and nothing else about it is rewritten — the
claim that `verify_ciphertext` is absent from the plaintext branch remains, because it is still
true. What follows is the control review the decision called for,
and the partition that review produced. It **discharges** the deferral; it does not reverse it. §2's
bounds are untouched, and the two forms those bounds cover stay out. The completeness claim below was
recorded as an **assertion maintained by review** on the ground that nothing then parsed this table.
It anticipated becoming a check, and said it should be re-stated as one **naming that reader**. That
has happened, so it is re-stated here, with the reader named.

**Its reader, and the mechanism.** `scripts/test-command-taxonomy.sh` opens this file, slices it at
this section's `### 4.` heading, and parses the disposition table below row by row (`adr4_check`); the
findings it emits surface as Group E's arms, each of which returns non-zero and fails the suite.
`.github/workflows/command-taxonomy.yml` runs that suite on every push and on every pull request into
`main`, under no path filter — so **an edit to the table below can turn a check red.** What the guard
reads of this section is the table: it collects the lines beginning with a pipe and nothing else, so
the prose around it, this paragraph included, is not parsed.

**What that check grades, and what it leaves to review.** It grades shape and agreement: that every
row parses at five columns and carries exactly one of the two dispositions; that every EXCLUDED row
carries at least one reason from the closed vocabulary below and names no command; that every
ADDRESSED row's Command cell parses under the same cell grammar `CLAUDE.md`'s Step-1 table uses and
resolves to a key that is both live on the command surface and ADDRESSED in that table; and that the
set of forms this table dispositions matches the set the guard holds, compared in both directions. A
sentinel on the publish script's own dispatch arms fails the suite when they drift from that held set.
**What it does not grade is whether the held set is the true set of invocation forms** — that
denominator is still maintained by review, and the sentinel is what makes a drift in it observable
rather than silent. So the completeness claim below is graded against a denominator, and the
denominator is reviewed.

**The deferral had two legs and only one of them cleared.** The content-guard leg is gone: the
plaintext branch now runs a publishable-content predicate immediately before it copies anything, so
that branch is no longer unguarded. That predicate is **not** the ciphertext verify, and the two
branches carry different guards rather than the same guard reaching both — the ciphertext verify
still runs on the encrypted branch only. **The TTY leg is structurally permanent.** Bash
pre-execution has no terminal; nothing in this release changes that, and nothing proposes to.

**The TTY leg's determination: nothing replaces the human gates, because no addressed form reaches
one.** The script holds exactly three stdin-terminal gates and no stdout-terminal test at all. One
guards the plaintext publish, one guards the repo delete, and one guards `confirm`. Every other
reachable form passes through no human gate whatsoever. The leg therefore does not bar the lifecycle
— it bars three forms, and §2 independently bars two of them by forbidding the only two flags that
reach their non-interactive limbs. **For those two forms the leg and the bound are co-extensive, and
the bound is the firmer basis**, because a review that "solved" the leg by inventing a non-interactive
confirmation substitute would still be stopped by a bound it cannot negotiate. The correct output is
therefore not a substitute mechanism. It is the recorded finding that no substitute is needed,
because the surface declines the forms rather than standing in for the gates.

**The dominant risk is gate absence, not gate unreachability — and the deferral above pointed at the
smaller of the two.** Only two of the reachable forms are gated at all. Absence of a gate is the
publish lifecycle's dominant property: the default encrypted publish creates a public repo, enables
Pages and prints the passphrase, behind no confirmation of any kind. The TTY leg was the *visible*
risk, not the main one. The main ones are credential disclosure and un-gated out-of-repo effect, and
the partition below is drawn against those.

**The rule that produces the partition.** A publish-lifecycle invocation form is **ADDRESSED** only
if all three hold: **(i)** it requires no change to the publish script; **(ii)** it writes no
credential or secret into the session transcript, by standard output or by command-line argument;
**(iii)** its out-of-repo effects are either absent or operator-reversible without data loss, and the
reversal path is named. Otherwise it is **EXCLUDED**, carrying at least one reason. **§2's two
forbidden flags are evaluated first and are not negotiable by this rule.** Limb (i) is recorded as an
invariant that holds on the resulting set rather than as a test that decides a row — it never
independently decides one. Limb (iii) is what makes the revert property a criterion rather than a
coincidence of the current script. Limb (ii)'s *or by command-line argument* is what stops a secret
passed on the command line from reading as safe once a standard-output fix lands.

**The disposition of every invocation form.** Eleven forms exist: the dispatch table admits seven
subcommand arms, and the user-facing options on those arms resolve to eleven distinct parseable
invocations. Each carries exactly one disposition, and each excluded one carries at least one reason
from a closed vocabulary. A flag that changes neither the disposition nor the reason earns no
separate row in `CLAUDE.md`'s Step-1 table; it still earns one here, because completeness over
*forms* is what this table exists to assert and a form left off it is a silent gap.

| # | Invocation form | Disposition | Reasons | Command |
|---|---|---|---|---|
| 1 | `list` (alias `status`) | ADDRESSED | — | `/trip-publish list` |
| 2 | `update` | ADDRESSED | — | `/trip-publish update` |
| 3 | `unpublish --disable-pages-only` | ADDRESSED | — | `/trip-decommission temporary` |
| 4 | `publish` | EXCLUDED | `#330-disclosure` + `repo-creation` | — |
| 5 | `publish --opaque` | EXCLUDED | `#330-disclosure` | — |
| 6 | `publish --plaintext` | EXCLUDED | `ADR-007 §2` | — |
| 7 | `publish --plaintext --opaque` | EXCLUDED | `ADR-007 §2` | — |
| 8 | `rotate` | EXCLUDED | `#330-disclosure` | — |
| 9 | `rotate --passphrase` | EXCLUDED | `#330-disclosure` + `argv-secret` | — |
| 10 | `unpublish` (delete) | EXCLUDED | `ADR-007 §2` | — |
| 11 | `confirm` | EXCLUDED | `ADR-007 §2` | — |

**Row 11 is the substantive call this table exists to make, not bookkeeping.** `update` is
already ADDRESSED, so an agent can trigger a republish. `confirm` records the organizer's
approval of an itinerary change, and if it were addressable too, an agent could confirm and
then update in one breath — the gate would be decorative, and the organizer's decision that
ADR-003 § Decision 2 reserves to a person would be taken by the surface acting on their
behalf. Excluding it means an agent-triggered `update` on an unconfirmed itinerary change
**aborts**, which is the protection. The reason is §2's privilege boundary, whose second
bound requires a command's tool grant to be *"the minimum for its function"*: a command
carrying the confirm capability exceeds the minimum for every function the surface has.
The consequence is a constraint on the command surface rather than an omission from it —
`skills/trip-publish/SKILL.md` **must not** gain this invocation, because an EXCLUDED
row that names a command is a finding.

The reason vocabulary is closed at five values — `ADR-007 §2`, `#330-disclosure`, `repo-creation`,
`argv-secret` and `lightest-weight-action` — and is shared with `CLAUDE.md`'s Step-1 table so one
vocabulary covers both surfaces. Reasons on a row are joined by ` + `. The fifth value is exercised
only on that other surface, where some rows are excluded because the lightest-weight action is the
right one rather than for any publish property. **Two rows above carry a pair, and in both the second
reason outlives the first.** Row 4's repo creation survives any fix to the disclosure — the default
repo name leaks destination and year. Row 9's secret is supplied as a command-line argument, so it
sits in the command text itself and a standard-output fix does not reach it. A single-reason table
would flip both rows wrongly on the day the disclosure is fixed, which is why the pairs are carried
rather than collapsed.

**Residuals on the addressed set, because addressed does not mean inert.**

- `unpublish --disable-pages-only` is a **live-site takedown behind no gate at all**. It is reachable
  non-interactively, it needs no repo-delete scope, and it returns before both the scope check and
  the typed confirmation — no gate is bypassed because none exists on that path. It qualifies by
  reversibility, not by harmlessness. **Reversal:** re-enable Pages in the repo's Settings. The repo
  name stays public and already-fetched content may persist in third-party caches, so a takedown is
  not a retraction.
- `update` pushes a commit to an already-public repo. The commit timestamp is a metadata residual no
  revert reaches. **Reversal:** re-run from the prior build; the site was already public.
- `update` also carries a **silent re-key hazard**. Its passphrase resolution falls through to
  generating a fresh passphrase when the trip's passphrase file is unreadable and the environment
  override is unset; it then re-encrypts and pushes while printing nothing, locking out everyone
  previously given the old one. **The mitigation is in the command, not in the script:** the command
  asserts the passphrase file is present and readable before invoking, and refuses with an
  explanation otherwise. That is what keeps `update` inside the addressed partition under limb (i).
- `list` writes local trip directory names into the session transcript. The session protocol already
  places that class of information in context on every session, and a directory name is not a
  credential. Limb (ii) is about credential disclosure; this does not meet it.

**What §2's third bound binds.** Its text names commands, and the mechanical check for it searches
the command directory. Its **intent** is broader, and is recorded here so a later reader does not
walk through the gap: the two forbidden flags bind **any non-interactive caller this repository
ships**, whether or not that caller is a command file. §2's text is unchanged — this states what it
means, it does not amend it.

**References.** Two work items are named above; each is summarized here so the rules stand without
them. `#330-disclosure` refers to the finding that the publish script writes the passphrase to
standard output on the encrypted publish and rotate paths, where bash pre-execution would place it
in the session transcript. It is tracked separately, it is **not** fixed by this decision, and it is
why four of the eleven forms are excluded. Separately, the plaintext opt-out is slated to be
hard-disabled at the script layer in the automated re-bake path, tracked in another milestone; this
decision converges with that by declining every plaintext form at the command layer, so no second
and softer invocation path is introduced.

**Amendment (2026-09-18, Friday) — two restatements of this table's counts, corrected to agree
with it.** When the table gained its row for `confirm`, this section's opening statement of how
many forms exist was corrected in the same change, and two sentences restating the same counts
were not: the References paragraph above still counted ten forms, and the second trade-off in
§ *Consequences* counted ten forms and seven exclusions. Both are corrected in place to read from
the table as it stands — eleven forms, three addressed and eight excluded. The *four* in the
References paragraph was right and is unchanged: it counts the forms carrying `#330-disclosure`
among their reasons, a subset of the excluded forms rather than their total, and the row that was
added carries a different reason. No row, disposition or reason changes, and nothing decided above
moves.

## Consequences

**Positive**

- Intent is declared rather than inferred, so the misrouting consequence is removed by construction
  rather than mitigated by instruction.
- Permission granularity matches functional granularity: a food query cannot carry publish rights.
- Context loading is deterministic and bounded per request type, which is the substantive fix — a
  surface that only renamed the chat would add ceremony and remove nothing.
- The taxonomy has one owner, so the drift guard asserts an invariant that already holds structurally
  instead of patching one that does not.
- Every existing publish control survives untouched in the first release, because the surface does
  not cross that boundary at all.

**Trade-offs**

- More files than a single-command shape, and a taxonomy guard to maintain alongside them.
- The publish lifecycle stayed a manual terminal step for one release, leaving the surface
  deliberately incomplete against its own lifecycle scope. The §4 amendment ends that for three of
  its eleven invocation forms; the other eight are declared exclusions, so what remains outside the
  surface is stated rather than pending.
- `CLAUDE.md`'s Step-1 table changes role from source of truth to documentation of one; the table
  must be kept accurate to the command set rather than the reverse, which inverts how contributors
  have edited it to date.
- Desktop-app and CLI parity for project-scoped commands is assumed and not yet verified; a failure
  there narrows the surface to one client.

## References

- Dispatcher and context-scoping rules being addressed: `CLAUDE.md` → "How to Use This (Claude Code
  as Primary Interface)", Step 1 and Step 2 tables.
- Artifact implementing §2's sixth bound (a field read by value, with absence as its own branch): `CLAUDE.md` → "Resolving a trip", the single normative home of the trip-resolution gate ladder.
- Agent roster addressed by the surface: `agents/` (nine agents; roster table in `CLAUDE.md`).
- TTY-conditional gates and the plaintext branch: `scripts/publish-trip-site.sh` → `cmd_publish`,
  `cmd_unpublish`, `verify_ciphertext`. The plaintext content guard that #123 recorded as missing
  has since landed, as a predicate distinct from `verify_ciphertext`, which remains
  encrypted-branch-only.
- Taxonomy coverage guard, and the reader of §4's disposition table:
  `scripts/test-command-taxonomy.sh`, run by `.github/workflows/command-taxonomy.yml`. It follows the
  pattern `scripts/test-publish-guard.sh` established.
- First-run onboarding path: `README.md` → Install, First run, Verify.
- The arbitrating source for the tool-list keys and for `disable-model-invocation`, cited by § 1's
  2026-09-11 amendment: the published Claude Code documentation for slash commands and skills —
  § *Where skills live*, § *Control who invokes a skill*, and the frontmatter reference — read
  2026-09-11. It is an upstream contract this repository does not own and cannot change, which is why
  the sentences that amendment rests on are quoted there in full rather than pointed at: the record
  stands on its own if the page moves.
- Epic: #252.
- The references behind § 1's 2026-09-18 amendment: the published Claude Code
  documentation for skills — its frontmatter reference, § *Control who invokes a skill*,
  § *Pass arguments to skills* and § *Restricting Claude's skill access* — together with the
  hooks reference § *Hooks in skills and agents* and its common-input-field table, and the
  permissions reference, all read 2026-09-18. The 2026-09-11 amendment quotes the
  sentences it had to arbitrate between competing in-repo accounts; these are **named rather than
  quoted**, because nothing in this repository carries a competing account of them and a quotation
  would be a second copy to keep current.
