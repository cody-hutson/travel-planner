# ADR-020: Trip-store root resolution — a named environment variable, and the user-scope surface it implies

- **Status:** Accepted (2026-09-11)
- **Deciders:** repo maintainer
- **Driving work:** the milestone covering trip commands invoked from outside the
  repository. The defect it answers is that the trip commands are installed at user scope,
  so they appear in the command picker from any working directory and do not function from
  one.

## Context

**A command that appears everywhere and works in one place is worse than a command that
appears in one place.** The trip commands can be copied to the user-scope commands
directory, and a copy placed there offers itself at the prompt from any project. Every one
of them opens with `!`-prefixed pre-execution blocks that read the trip store, and those
blocks resolved their root through the launching project's directory. Outside the
travel-planner checkout that variable names the project the user happens to have open, so
the listing fails, the trip population reads as nothing, and the failure surfaces as a raw
folder error rather than as a diagnosis.

**The evidence blocks are not free to restructure, and the reason is the contract.** The
charter's trip-resolution section declares the canonical evidence list once, and every
consuming command file carries a byte-identical contiguous prefix of it — exactly the
prefix its declared depth requires, never a longer one. The duplication is forced by the
platform, since the pre-execution mechanism fires only inside a command file's own body and
there is no include directive, and it is made safe by machine assertion rather than avoided.
Two consequences follow and both bound this decision.

First, **the prefix rule is an equality**, so the block count is load-bearing. Appending a
third canonical entry would leave the one consumer whose declared depth needs a single block
— the trip-creation command — receiving the first block and never the third, so a fix
expressed as a new block would not reach it while every required check stayed green.
Prepending one inverts the problem: that same consumer would carry the new block *instead
of* the listing, and the listing canary the first gate rests on would have nothing to fire
on. Both failures are silent.

Second, **every block a file carries is a grant it must hold.** The trip-creation command
holds the narrower listing grant and holds no grep grant and no test grant, and that
narrowness is only true while its prefix is the first entry and nothing else. Any mechanism
introducing a new command token into a block widens the grant on every command file that
carries one, with that command as the named casualty.

**The repository's stated install model is that there is nothing to install.** The README
describes a clone opened in Claude Code. A user-scope copy is therefore a surface the
repository has not previously acknowledged, and the copies observed in practice had already
drifted from their in-repo originals — which nothing in this repository could detect, since
they sit outside the working tree where no guard suite, no CI job and no git status reaches
them.

## Decision drivers

- **Reach all five consumers**, including the one whose declared depth carries a single
  evidence block.
- **Change no block count and no block ordering**, because both silent-failure shapes above
  are reachable only by a mechanism that does.
- **Introduce no command token**, so no tool grant on any command file widens.
- **Write no machine-specific path into tracked content.** This is a public repository under
  a third-party licence; a checkout location baked into a tracked file is wrong for every
  user but one, and wrong for that one the moment they move the clone.
- **Fail diagnosably rather than silently.** Where the root does not resolve, the user must
  be told what was tried and what would fix it.
- **Never assert a conclusion no gate observed.** The stop-message rule forbids it, and a
  location claim is exactly the shape it forbids.

## Options considered

**A pinned trip-store path.** A literal absolute path substituted into the evidence blocks.
Rejected. The realistic form — a path under an operating-system user home — is blocked by
the personal-data gate, which is a live required check; that was established by executing
the gate's own patterns against candidate strings rather than by reasoning about them, with
a control arm that fired on a known-bad string and a specificity arm that stayed silent on
prose. The variants the gate does *not* block, a home-relative or a non-home absolute pin,
are rejected on the weaker and honestly-labelled ground of portability: they work on one
machine. The distinction is recorded because it matters to a later reader — the gate
disqualifies the pin an operator would actually write, not the branch as a class.

**A longer fallback chain.** An ordered candidate list — the variable, then the project
directory, then a marker probe walking up the tree, then a conventional location. Rejected,
and the reason is that it is not really a separate option: a two-element parameter expansion
*is* a resolution chain, and it is the longest one expressible without a command token.
Every further arm needs a conditional or a command substitution, which widens the grant on
every command file carrying a block, with the trip-creation command as the named casualty.
It also buys a failure mode the stop-message rule forbids: a chain can silently select a *wrong* root and proceed, which
is a conclusion about location that no gate observed. This decision takes the part of the
chain that is free and declines the part that is expensive.

**A first-run configuration step.** A configuration file written once and read by every
command. Rejected as a different release rather than a worse idea: it is the only option
that makes resolution work with no user action at all, and its price is a new file class, a
new protocol, a read on every invocation that pressures the no-per-invocation-read bound,
and both block-count failure shapes live.

**A named environment variable with the project directory as its default.** Accepted.

## Decision

**The evidence blocks resolve their root through `TRAVEL_PLANNER_ROOT`, defaulting to the
launching project's directory when that variable is unset, and the substitution is made
IN PLACE inside the existing canonical entries.**

In place is the load-bearing half. The canonical entry count and their ordering are
unchanged, so neither silent-failure shape above is reachable — not avoided by care, but
unreachable by construction. The expansion introduces no command token, so every
`allowed-tools` and `disallowed-tools` line across the whole command surface is
byte-unchanged and the trip-creation command keeps its narrower grant. With the variable
unset inside the checkout, the default arm reproduces the previous behaviour exactly.

**The name is a public commitment, and it was chosen against a stated alternative.** The
leading alternative named the trip directory rather than the project root. A root is
required, not preferred: the default arm names a project root, and an expansion is sound
only where both arms denote the same kind of thing — a subdirectory name would force the
trailing path segment into one arm and not the other. The name is namespace-qualified
because the variable is exported into a user's shell environment, a global namespace shared
with every other tool on that machine, where an unqualified name is a plausible collision;
the repository's own precedent already splits this way, with bare names set inline for a
single invocation and prefixed names set in an environment and persisting. A root also
generalizes to the adjacent script-path problem with no second variable.

**The failure path is specified, not deferred.** Where the listing cannot be read, the first
gate's stop gains three clauses, each resting on something observed. It quotes the directory
actually tried, from the block's own output — which is available because stderr capture is
mandatory on every canonical entry, so a failed listing names the path it failed on. It
retains the existing prohibition unchanged: an unreadable listing is still not an empty one.
And it names the remedy **conditionally** — if the quoted directory is not the
travel-planner checkout, the variable set to that checkout's root resolves it. The condition
is the whole of it. This gate cannot distinguish a trip store that is genuinely missing from
one that lives elsewhere, so a stop asserting that the invocation is running outside the
repository would be the forbidden shape wearing a different subject.

**A sync path ships with the mechanism rather than after it**, because the two are one user
flow: the script that copies the commands is also the surface that knows the correct value
of the variable, having just been handed the checkout root. It reports per-file state by
default and writes only when asked; it preserves each file it replaces before replacing it,
into a location outside the commands directory; it is idempotent; and it prints the export
line on every run, read-only runs included. It deliberately does not edit a shell profile,
and it deliberately does not substitute the root at copy time — that would make the
installed copy differ from the repo copy by design, so sync could no longer be verified by
byte comparison and drift would become undetectable, which is the failure the script exists
to end.

## Consequences

**The command-entry-point record's bounds are untouched.** Nothing in it is reversed or
narrowed, which is why this is a new record rather than an amendment to that one. Its
minimum-grant bound is in fact what *selects* this mechanism: the accepted option is the
only one that widens no grant, and the rejected chain is rejected because it widens several.

**A named residual: the repo-relative script grants are out of scope.** The verbs that shell
out to the publish script spell that script's path repo-relative, and those grants are not
re-spelled here. Four reasons, in descending strength. The repository has already reasoned
about exactly this and recorded the residual in the decommission command's own frontmatter
discussion — that whether the runtime's matching reaches a second spelling of the same path
is not established anywhere here, and that what that file does about it is conduct rather
than coverage; re-spelling the grants would rest a fix on the very premise that residual
declines to assert, and would break the conduct alignment currently substituting for it. The
one-authorization-per-function rule makes a script-wide grant a privilege union, which is
why the arms are denied individually. The taxonomy guard classifies a script mention as a
grant by a literal path match, so re-spelling it in a body grant-inventory table would drop
the mention out of the grant class and break that guard's parse-coverage identity. And a
grant fix would not make the verb work anyway: the publish script needs the repository
working tree, and resolving a grant token from a foreign directory does not hand it one.

**The consequence of that residual is stated rather than buried.** Trip-store resolution
works from any working directory for every command on the surface. The script-invoking verbs do not:
they resolve the trip and then stop at the script boundary. Acceptance of this release is
graded against resolution, and the release does not claim the script verbs work from a
foreign directory.

**The install posture changes, mildly, and the tension is real.** The README says there is
nothing to build or install. That stays true — the commands work from a clone with nothing
installed and nothing set. What is added is an *opt-in* path for a surface that already
existed unacknowledged, so the sync script documents a practice rather than introducing an
obligation.

**The name cannot be withdrawn cheaply.** Once users have exported it, renaming it is a
breaking change with no deprecation path. That is part of why this decision earns a record.

**The mechanism is asserted, not described.** The contract guard gained a group that
executes the canonical entries rather than reading them, against a two-root fixture built on
every run, and its arms are paired so no zero stands alone. Run against the corpus as it
stood before this change, that group fails and the suite exits non-zero — so the assertion
is known to be capable of failing rather than assumed to be.

## Follow-on build slices

1. **Make the script-invoking verbs portable.** The named residual above. It is a distinct
   capability with its own boundary, and it depends on the unarbitrated question of whether
   runtime grant matching reaches a second spelling of a path — which is research before it
   is engineering. Routed as a separate work item rather than a slice of this one.
2. **Register the sync workflow as a required check.** It ships and reports; adding it to
   branch protection is a repository-settings change outside any pull request, and the
   release is correct whether or not it happens.

## References

- The trip-resolution contract, its gate ladder and the exactness rule on the evidence
  prefix: [`CLAUDE.md`](../../CLAUDE.md) § *Resolving a trip*.
- Command surface shape, the privilege boundary and the minimum-grant bound this decision
  leaves untouched: [`ADR-007`](ADR-007-command-entry-point.md).
- The count-assertion basis convention this record's prose is authored under:
  [`ADR-013`](ADR-013-count-assertion-basis.md).
- The guard that extracts the canonical and executes it:
  [`scripts/test-trip-resolution-contract.sh`](../../scripts/test-trip-resolution-contract.sh).
- The sync path and its guard: [`scripts/sync-commands.sh`](../../scripts/sync-commands.sh),
  [`scripts/test-command-sync.sh`](../../scripts/test-command-sync.sh).
