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
reads the table and classifies the user's prose correctly. Four consequences follow, each observable
in the repo as it stands — the nine agents and every request type the table carries are invisible at
the prompt; classification is probabilistic, and `CLAUDE.md` warns against the precise failure
("Don't dispatch agents to change an emoji"); sessions start cold with no consistent action that
re-establishes trip and mode; and `README.md`'s install path hands a newly-cloned repo exactly one
first move — "Tell Claude you want to plan a trip" — which is prose to type into the same free-form
chat rather than anything the repo makes addressable.

The engine's functions already exist. What is missing is a way to **address** them.

What makes a command surface a different class of fix from better documentation is that a Claude
Code command file is not merely a prompt shortcut. It carries two mechanisms the prose cannot:
`allowed-tools` and its companion `disallowed-tools`, a **declared** per-file permission posture;
and `!`-prefixed bash pre-execution, which runs before the model sees the prompt and injects its
output — **deterministic** context loading rather than an instruction to go read something. A
command therefore converts instruction into mechanism, which is exactly what the four consequences
above need. `CLAUDE.md` is already correct; what it is not is **addressable** — nothing in the repo
lets a user invoke one of its rows.

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
- Every Step-1 row maps to exactly one command **or** to a declared exclusion. Silent gaps are not
  permitted; an unaddressed request type is a stated one.
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
becomes a cheap assertion of **bijection** — every Step-1 row resolves to a command or a declared
exclusion, and every command resolves to a Step-1 row.

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
bounds are untouched, and the two forms those bounds cover stay out. The completeness claim below is
an **assertion maintained by review**, not a check: no artifact in this repository opens this file, so
no edit to this section can turn a check red. It becomes a check on the day one parses this table,
and may be re-stated as one then, naming that reader.

**The deferral had two legs and only one of them cleared.** The content-guard leg is gone: the
plaintext branch now runs a publishable-content predicate immediately before it copies anything, so
that branch is no longer unguarded. That predicate is **not** the ciphertext verify, and the two
branches carry different guards rather than the same guard reaching both — the ciphertext verify
still runs on the encrypted branch only. **The TTY leg is structurally permanent.** Bash
pre-execution has no terminal; nothing in this release changes that, and nothing proposes to.

**The TTY leg's determination: nothing replaces the human gates, because no addressed form reaches
one.** The script holds exactly two stdin-terminal gates and no stdout-terminal test at all. One
guards the plaintext publish; the other guards the repo delete. Every other reachable form passes
through no human gate whatsoever. The leg therefore does not bar the lifecycle — it bars two forms,
and §2 independently bars the same two by forbidding the only two flags that reach their
non-interactive limbs. **For those two forms the leg and the bound are co-extensive, and the bound is
the firmer basis**, because a review that "solved" the leg by inventing a non-interactive
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

**The disposition of every invocation form.** Ten forms exist: the dispatch table admits six
subcommand arms, and the user-facing options on those arms resolve to ten distinct parseable
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
why four of the ten forms are excluded. Separately, the plaintext opt-out is slated to be
hard-disabled at the script layer in the automated re-bake path, tracked in another milestone; this
decision converges with that by declining every plaintext form at the command layer, so no second
and softer invocation path is introduced.

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

- More files than a single-command shape, and a bijection guard to maintain alongside them.
- The publish lifecycle stayed a manual terminal step for one release, leaving the surface
  deliberately incomplete against its own lifecycle scope. The §4 amendment ends that for three of
  its ten invocation forms; the other seven are declared exclusions, so what remains outside the
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
- Guard pattern the taxonomy bijection test follows: `scripts/test-publish-guard.sh`.
- First-run onboarding path: `README.md` → Install, Verify.
- Epic: #252.
