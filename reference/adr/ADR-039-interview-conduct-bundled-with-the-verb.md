# ADR-039: The interview's shared conduct is bundled with the interviewer verb — a file beside its command file, superseding ADR-023 D1.1 in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *one interviewer, any conforming form* milestone. At that milestone's
  Collective Review the operator decided that the interview's shared conduct is placed in a file
  bundled inside the interviewer verb's own skill directory rather than in the verb's section, and
  that the constraint [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) R2 held is
  lifted at that milestone's scope. This record is that decision, written where the decision it
  changes can point at it.
- **What this record is.** A decision about **one placement**: the file the interview's shared
  conduct is authored in, what stays in the verb's section, and how the section reaches the file.
- **What this record is not.** It decides no conduct — no rule's content and no session behaviour,
  which are [`ADR-022`](ADR-022-interview-session-model.md)'s — and no part of the form contract. It
  changes no grant, no command surface, no install step and no artifact class.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the operator's, taken at this milestone's close, and it moves both halves of a
  two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md).

## Context

`ADR-023` D1.1 placed form-agnostic conduct in the Zone-B section of the new interviewer verb on
`skills/trip-record/SKILL.md`, and recorded the cost with the choice. Its § *Options considered*
rejects a reference document *"on the operator's constraint and not on merit"*, because the
milestone fixed the artifact set at skill plus form, and its R2 names the consequence: one verb
section becomes the de-facto conduct library, *"which will read oddly at the third caller"*.

That section sits inside a body `CLAUDE.md` § *Verb body size* records far over the budget the
published skill-authoring guidance sets for a skill's body, and the remedy that section names is
structural — the verbs merged into *a router plus its references*. The guidance names the same
remedy at the scale of a single file: keep the body inside the budget, and as it approaches it, move
detail into a file bundled with the skill and referenced directly from the body. A file inside the
verb's own directory is part of the skill at the format's own altitude, and `ADR-023`'s option table
did not weigh it: its reference-document column is a document outside the skill.

## Decision drivers

- **The skill directory is the unit an install carries.** The repository's `README.md` links each
  verb's directory rather than its `SKILL.md`, and updating is a `git pull`, so a file in that
  directory reaches every install on the path `ADR-023`'s install driver protects, with no step
  added.
- **Conduct is authored once, and that property does not move.** The decision changes where the
  text lives, not how many texts there are.
- **The verb's contract stays in the verb's section.** The command's own rules put three things
  there by name: the target path a write is taken on (standing rule 15, condition (a)), the reason
  for the lifecycle the requirement row admits (§ *The shape of a table row*), and the read scope
  (§ *What the blocks above are*).
- **Every reference stays one level deep.** The guidance warns that a file reached only through
  another referenced file may be read in part.

## Options considered

| | O1 the verb's section — `ADR-023` D1.1 | O2 a file beside `SKILL.md` in the verb's directory | O3 a subdirectory of references in the verb's directory | O4 a document under `reference/` |
|---|---|---|---|---|
| Conduct authored once | yes | yes | yes | yes |
| Part of the skill the format ships | yes | yes | yes | **no — engine reference** |
| Reachable after the documented upgrade | yes | yes | yes | yes |
| The verb's body carries the conduct | **yes** | no | no | no |
| Settles the layout the consolidation into one skill decides | no | no | **yes** | no |
| Verdict | superseded | **selected** | reject | reject |

**O3 is the skill-authoring scaffolder's layout, and it is rejected on timing rather than merit.**
With a single bundled file, a subdirectory organises files that do not exist, and the published
upstream surfaces name it differently — `references/` in the scaffolder's anatomy, `reference/` in
the authoring guide's domain example, beside flat files in its basic one — so choosing a name now
would settle, for one file, the layout the consolidation into one skill decides for all of them.
**O4 is `ADR-023`'s reference-document option, and it stays rejected**: it would put the conduct
outside the skill that runs it.

## Decision

**D0 — This record supersedes `ADR-023` D1.1 in part: only where it places the numbered conduct
rules**, in *"the Zone-B section of one new verb"*, where they *"live there and nowhere else"*.
Every other clause of D1.1 stands — conduct is authored once, one verb is the interviewer,
nothing is appended below the last verb section, and Zone A is touched only through the repair
extension point — and so does every other decision of `ADR-023`. D1.1's clause placing the output
contract is not decided here.

**D1 — The interview's shared conduct is authored in `skills/trip-record/interview-conduct.md`, and
nowhere else in the command.** The file carries the question set, the rules every interview shares
and the rules only a write-capable session adds. The verb's section names it on its `**Reads:**`
line, says when it is read, and binds the verb to follow it; `## profile <name>`, which runs the
interview inline, names it on its own `**Reads:**` line for the same reason.

**D2 — The verb's section keeps the verb's contract.** Its signature, its read scope, the forms it
admits and the conformance checks it consumes, where the file lives and the create-or-resume
selection, what the finished file carries, the presence refusal, the standing-rule discharge, the
refusals, the lifecycle reason and what it names. The test: what the verb settles once per
invocation, before the session runs, and what the command's own rules require of the verb's section
stay there; what the running session applies question by question and write by write — what is
asked, how, and each write's own test — moves.

**D3 — The file is named in full, and every reference stays one level deep.** Every mention of it
is repository-relative to the engine root, as every engine path in the command file is. The file
declares no read of its own: each file its rules read is named on the section's `**Reads:**` line,
so the model reaches every such file from the command file directly and never only through the
conduct file.

**D4 — `ADR-023` R2's constraint is lifted at this milestone's scope, by the operator's decision,
and the cost R2 names goes with it.** No verb section is the de-facto conduct library. **The output
contract is not placed here**: the interviewer verb has none (`ADR-022` D6.1), and where a channel
without a write path takes its contract is not this record's to decide.

## Consequences

- **The command file's body grows by less.** The conduct that would have been appended to the body
  is in the bundled file, which is outside the budget the guidance sets on the body.
  `CLAUDE.md` § *Verb body size* records the body's lines on the commit that makes this change.
- **The file is neither a command nor an artifact.** It carries no frontmatter, and no guard that
  reads command files reads it; what grades it is what grades the rules it carries, compared with
  any other text that must carry them word for word.
- **`ADR-023`'s other statements of the superseded placement are read through this record**: the
  paragraph in its § *Options considered* on why A2 does not breach the zone rule, D1.3's *"the
  script is that section"*, and R2's row. `ADR-023`'s `Status:` bullet records the supersession,
  a marker stands at D1.1, as `README.md` § *Convention* asks of a record superseded in part, and
  an amendment marks R2 lifted; the record is otherwise unedited.
- **The consolidation into one skill moves this file with the rest**, and decides the directory
  layout its references share.

## References

- [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) — D1.1, the decision
  superseded in part; § *Options considered*, Choice 1; R2
- [`ADR-022`](ADR-022-interview-session-model.md) — D6.1, the reason the interviewer verb has no
  output contract
- [`ADR-007`](ADR-007-command-entry-point.md) § *Context* — a command's conduct is written as a rule
  the command follows; this record keeps it one, written in a file the command's own section binds
  it to
- [`ADR-021`](ADR-021-installable-capability.md) — the engine is installed and each verb's directory
  is linked, which is why a file in that directory ships with it
- [`README.md`](README.md) § *Convention* — the supersession-in-part form this record uses
- `CLAUDE.md` § *Verb body size* — the budget, its source, and the router-plus-references remedy
- `skills/trip-record/SKILL.md` — § *How this file is extended*, § *What the blocks above are*,
  standing rule 15, and `## interview <form> [<target>]`
- `README.md` at the repository root — the install loop that links each verb's directory, and
  updating as a `git pull`
