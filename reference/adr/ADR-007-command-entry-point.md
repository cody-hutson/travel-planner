# ADR-007: Command entry point — surface shape, privilege boundary, and taxonomy ownership

- **Status:** Accepted (2026-08-22)
- **Deciders:** repo maintainer
- **Driving work:** the Command entry point epic (#252); establishes the surface shape and privilege
  model its child slices build against, and fixes the sequencing constraint that binds the
  publish-addressing slice to #123.

## Context

Every way into the planner is a free-form chat. `CLAUDE.md` § "How to Use This" already holds a
complete dispatcher — a nine-row Step-1 table mapping intent signals to actions, each paired with a
Step-2 rule for how much trip state to read. That dispatcher is **implicit**: it fires only if the
model reads the table and classifies the user's prose correctly. Four consequences follow, each
observable in the repo as it stands — the nine agents and nine request types are invisible at the
prompt; classification is probabilistic, and `CLAUDE.md` warns against the precise failure ("Don't
dispatch agents to change an emoji"); sessions start cold with no consistent action that
re-establishes trip and mode; and `README.md` ends at "Tell Claude you want to plan a trip," which
offers a newly-cloned repo no concrete first move.

The engine's functions already exist. What is missing is a way to **address** them.

What makes a command surface a different class of fix from better documentation is that a Claude
Code command file is not merely a prompt shortcut. It carries two mechanisms the prose cannot:
`allowed-tools`, an **enforced** per-file permission set; and `!`-prefixed bash pre-execution, which
runs before the model sees the prompt and injects its output — **deterministic** context loading
rather than an instruction to go read something. A command therefore converts instruction into
mechanism, which is exactly what the four consequences above need. `CLAUDE.md` is already correct;
it is not already enforced.

One property of the existing publish path shapes this decision decisively. `scripts/publish-trip-site.sh`
protects its plaintext branch with a **TTY-conditional** gate: `if [ -t 0 ]` prompts for a typed
`PUBLISH` confirmation, and the `elif` branch refuses unless `ALLOW_PLAINTEXT=1` is set. The
encrypted branch additionally runs `verify_ciphertext` before every push; the plaintext branch does
not — it copies the rendered HTML straight to `index.html` (the gap #123 records). Bash
pre-execution inside a command file runs with stdin **not** a TTY. A command wrapping that script
therefore lands on the side of the branch where the typed confirmation structurally cannot fire and
the content guard was never called. `cmd_unpublish` has the same shape: its `--yes` flag skips the
confirmation, and a non-interactive caller needs that flag to function at all.

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

### 2. The privilege boundary

Four bounds hold on every command in this surface:

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
`verify_ciphertext` is absent from the plaintext branch until #123 lands, the publish lifecycle is
**not addressed by a command in the first release**. Where publishing is the user's intent, the
surface **prints the terminal command for the operator to run** — a handoff that preserves every
existing control at zero engineering cost.

The publish-addressing slice sequences **behind #123**. When it lands, the trust boundary between
the command surface and the publish script opens for the first time and earns its own control
review; it is deferred here, not solved.

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
- The publish lifecycle stays a manual terminal step until #123 ships — the surface is deliberately
  incomplete against its own lifecycle scope for one release.
- `CLAUDE.md`'s Step-1 table changes role from source of truth to documentation of one; the table
  must be kept accurate to the command set rather than the reverse, which inverts how contributors
  have edited it to date.
- Desktop-app and CLI parity for project-scoped commands is assumed and not yet verified; a failure
  there narrows the surface to one client.

## References

- Dispatcher and context-scoping rules being addressed: `CLAUDE.md` → "How to Use This (Claude Code
  as Primary Interface)", Step 1 and Step 2 tables.
- Agent roster addressed by the surface: `agents/` (nine agents; roster table in `CLAUDE.md`).
- TTY-conditional gates and the unguarded plaintext branch: `scripts/publish-trip-site.sh` →
  `cmd_publish`, `cmd_unpublish`, `verify_ciphertext`. The missing plaintext content guard is #123.
- Guard pattern the taxonomy bijection test follows: `scripts/test-publish-guard.sh`.
- First-run onboarding path: `README.md` → Install, Verify.
- Epic: #252.
