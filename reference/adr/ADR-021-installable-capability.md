# ADR-021: The trip engine is an installable capability, not a folder you open

- **Status:** Accepted (2026-09-14)
- **Deciders:** repo maintainer
- **Driving work:** the architecture slice of the *trip engine ships as an installable
  capability* milestone. This record is that milestone's **head decision gate**, in the shape
  `ADR-012-people-library.md` and `ADR-016-reusable-groups.md` already ship: it lands before
  any feature slice and settles the cross-cutting question all of them would otherwise answer
  separately — whether the engine has a location of its own at all.
- **Supersedes** — the environment-variable resolution decision taken on the *trip commands
  outside the repo* milestone, whose release stopped at its own go/no-go gate. That decision's
  own record was authored but never merged: no tracked file carries it, and no blob of it is
  reachable from any ref in this repository. The control arm on that measurement fires — the
  in-flight sibling release branch's record **is** reachable by the same census — so the
  absence is a measurement and not a failed read. There is therefore no record to mark
  `Superseded by`, and none is invented here; the **decision** is superseded, and its
  falsifying evidence is carried inline in § *Decision drivers* rather than left on a branch
  that no longer exists.
- **What this record is.** A decision about **where the engine lives and how it is reached**.
  The engine is installed, and the checkout stops being the thing an operator opens in order
  to use it. It names the problem surface decomposed by how each reference is consumed, and it
  records what the choice forecloses — including a claim `README.md` currently makes.
- **What this record is not. This record selects no mechanism.** Every consumption surface is
  named below, each with the candidates considered, what each costs, the mechanism question
  still open, and the slice that owns the selection. Selection happens in those slices. This
  record also decides nothing about **where model inference becomes permitted** on the verb
  surface: `ADR-007-command-entry-point.md`'s addressing decision, its privilege boundary and
  the current description-invocation suppression posture are all untouched, and the arbitration
  of the inference question belongs to the milestone that owns conversational entry. And **no
  operator data moves** — § *Decision* 2.
- **The status flip is named here, because nothing grades it.** Moving this record from
  `Proposed` to `Accepted` is the operator's, taken at this milestone's close, and it moves
  **both** halves of a two-artifact state: the `Status:` line above, and this record's `Status`
  cell in `reference/adr/README.md`. No required check here grades either half or their
  agreement, so the obligation travels with this line rather than with a gate. The predecessor
  is instructive: the record immediately before this one was flipped in its own file by a
  merged pull request and its index cell was left behind, which is the divergence this
  record's own index edit repairs.

## Context

**The repository states one architecture and is operated under another, and nothing reconciles
them.** `README.md` tells a new operator, in terms, that *"there's nothing to build or install
into your system. You clone it and open it in Claude Code"*, and its setup section gives the
desktop path as *"open the `travel-planner` folder"*. The five trip verbs are nonetheless run
from copies placed outside the checkout, where they appear in every project and function in
none: each one resolves the operator's trip store through the **launching project's**
directory, so a verb invoked anywhere but the checkout looks for trips where there are none.

**Nothing in the repository sanctions that copy, and nothing in it promises the property the
copy was reaching for.** Probed at `8f3b3cb` over the 127 tracked markdown files: the
no-install family of claims appears in 0 files, the from-anywhere family in 0 files, and the
user-scope-copy family in 0 files, against a sensitivity arm on the bare word *install* that
returns 5 files and one on *trip* that returns 123. The repository does not claim the verbs
work from any working directory; it claims the opposite, that there is nothing to install. The
gap between what it claims and how it is operated is what this record closes.

**A prior release attempted to close that gap and was stopped at its go/no-go gate.** It
introduced a new variable into the verbs' pre-execution blocks, and it was built, dev-tested
and acceptance-reviewed before the premise underneath it was tested at all. What that release
established is the decision driver for this one, and it is stated next as **what was
falsified** rather than as a selection of what succeeds.

## Decision drivers

### 1. The premise that was falsified, and the scope of the refutation

**The premise.** That the harness would substitute a **project-introduced** variable naming
the engine's own location — so a verb could be taught where its engine lives by declaring a
variable for it.

**The refutation.** The harness substitutes a **closed set that a project cannot extend**. The
introduced variable was never substituted; it survived into the command text as a live shell
expansion, and the block was refused before it ran. That is not a mechanism with a defect to
fix. It is a branch that does not exist, in any spelling — so no amount of re-spelling the
variable, re-ordering the block or narrowing the grant reaches it.

**The positive measurement that came with it, stated because a refutation alone selects
nothing.** A skill installed outside the checkout receives a variable naming **its own
installed directory**, and that variable substitutes in the skill's **prose body** as well as
inside a pre-execution block. An ancestor traversal off that directory resolves for a read; a
script granted through the same traversal executes; and a deny pattern carrying the traversal
still matches and still restricts. So at least part of the problem is reachable with no
project-introduced variable at all.

**The configurations the refutation was measured in — named, because a refutation travels
further than its evidence if its population is left off.** Two: a bare installed skill with
its asset and its script **inside** the skill's own directory, invoked from a foreign working
directory; and a skills-directory plugin whose shared asset tree sits at an **ancestor** of
the skill directory, read and executed through the traversal. What the refutation refutes is
the **resolution** argument for introducing a project-owned variable. It says nothing about
**distribution and update** — whether a packaged form is the right way to ship and refresh the
engine is live, separate, and not decided here. And it reaches nothing about whether the
installed-directory variable is readable **inside a spawned process**: every arm substituted it
in the body before any process started, so a design that needs it in an environment needs its
own measurement.

### 2. A bare relative reference follows the session, not the file that contains it

Measured: a decoy placed at **both** candidate anchors resolved at **neither**. A bare path
inside an engine document is not file-relative and never was; it is resolved against whatever
working directory the session happens to have when a tool acts on it.

**This is why the decision is architectural rather than a tidier path spelling.** There is no
layout — assembled, nested or co-rooted — in which the bare form keeps working once the engine
is reached from outside the checkout. A reference therefore has to name a **root**, and a root
only exists if the engine has a location of its own. That is the whole of what this record
decides, and everything downstream of it is mechanism.

### 3. A property of the carrier that any installed form inherits

**A non-zero exit in a pre-execution block is fatal to the skill load.** The verb does not
degrade and does not warn — it ceases to exist. This is a measured property of the runtime,
not a requirement on any design, and it is true of every installed form regardless of which
mechanism a later slice selects, which is why it sits here among the drivers rather than in a
slice's own record.

**Its provenance is carried, because a reader who knows how it was obtained can judge its
scope.** It was the incidental product of a probe that aborted at its stated job: that probe's
negative control was sequenced ahead of its subject arms, the control's own non-zero exit
killed the skill carrying it, and the subjects never ran. The finding is sound and the probe
was not.

**What it forecloses is an option a reader would expect to have.** It removes any possibility
of diagnosing a resolution failure *from inside a pre-execution block* — which is exactly
where a reader looks for the diagnosis, because that is where the resolution happens. A record
that commits this engine to an installed form and stays silent about it costs the next reader
the same probe.

### 4. The drivers proper

- **A reference can only resolve against a root, and a root is a property of the engine.**
  Driver 2 removes every alternative. An architecture that keeps the engine as a folder you
  open has no root to offer and no way to acquire one.
- **Operator data must not move.** The stores hold real records in real working directories.
  A resolution change is cheap; a relocation is a migration. The two are separable and this
  record separates them.
- **An architecture decision must not smuggle a mechanism.** The superseded release chose its
  mechanism before the problem was decomposed, and the decomposition is what would have
  falsified it. The surfaces below differ in difficulty and do not share one answer; naming
  them without selecting for them is the point.
- **A refuted option is preserved, not deleted.** The predecessor's reasoning was good
  reasoning about a premise that turned out to be false. Deleting it invites the next reader
  to re-derive it; carrying it, with the observation that refuted it, does not.

## Options considered

Constrained to the **architecture** axis. Where the engine lives and how it is reached — not
which carrier names the root, which is § *The problem surface* and is left open.

| Option | Cost, and the verdict |
|---|---|
| **(a) The engine is a folder you open.** The status quo, and what `README.md` documents | **Rejected.** It is the state whose defect opened this milestone: a verb reached from outside the folder resolves the operator's store through the launching project, so the verbs appear everywhere and work in one place. The option is also already falsified in practice rather than in theory — the verbs are being run from outside the checkout today, which is why the mismatch in § *Context* exists at all |
| **(b) The engine is copied per project.** Each project that wants trip verbs gets its own copy of the engine beside it | **Rejected on three costs.** Every copy is a second home for the whole asset tree, so a correction lands in one project and not the others. The operator's data stores would either fork with the copies or be reached across project boundaries, which is the resolution problem again with more instances of it. And there is no update path: a copy is current only until the engine changes |
| **(c) The engine is an installable capability.** It is installed once, has a location of its own, and its verbs are reached without opening its folder | **Chosen.** It is the only option in which a reference has a root to resolve against — driver 2 makes that decisive rather than preferable. Its costs are real and are recorded rather than discounted: the *"nothing to install"* claim is reversed, an install step joins the prerequisites, and a reader of § *Consequences* will find five documented claims the choice invalidates |

**Two candidate mechanisms that were considered and are deliberately NOT ranked here.** A
project-introduced variable is not among the options above because driver 1 removes it from the
candidate set entirely, not because it lost a comparison. And the installed-directory variable
that measurement *did* establish is a **carrier**, not an architecture: it appears below as a
candidate on the surfaces it could serve, with its costs, and it is selected nowhere in this
record.

## Decision

### 1. The engine is an installable capability

The trip engine is **installed**, and a trip verb is reached without opening the engine's
folder. Three things follow, and each is a decision rather than a restatement of the heading:

1. **The engine has a location of its own, nameable from inside a verb.** Not inferable from
   the session, not assumed to be the working directory, and not re-derived per invocation
   from something the operator happens to have open.
2. **Every engine asset a verb reads or runs resolves against that location.** The working
   directory stops being an input to engine-asset resolution. Which carrier states the root,
   and in what spelling, is the open mechanism question of § *The problem surface*.
3. **The checkout stops being the invocation surface.** Cloning remains how the engine is
   acquired; it stops being how the engine is used.

**The home the conversion lands, named.** Verbs are discovered at `skills/<verb>/` beside the
asset tree each one reads, and the asset tree does not move at all. A nested `.claude/skills/<verb>/`
form is **not discovered** by the runtime — measured under the packaged form this record first
shipped: both arms were placed on disk and verified present, and only the control appeared in the
runtime's component inventory, so the absence is a measurement rather than a failed install.
Discovery is by a **personal-skill link**: each verb's directory is linked into the harness's own
skills directory under the verb's bare name, and the runtime reads the skill from the link's target
while naming the **link** as `${CLAUDE_SKILL_DIR}` — measured across every linked invocation. The
engine root is still the directory two levels above it, because the kernel resolves `..` after it
has followed the link: `<link>/../..` names the engine, and a lexical collapse of the same text
names the home directory, which is why the verbs say to read it as the kernel does. The engine directory itself is
the thing the links point into, and it carries a skill file of its own at its root — the guided-entry surface,
which names a verb and runs none — so it is a skill as well, though not a verb. An earlier planning document named the nested
form; that path is **superseded by the measurement**, and this sentence is the record of it.

**The invocation posture the conversion preserves.** Every verb carries
`disable-model-invocation: true` today, and the conversion preserves it **unchanged in
breadth**: a verb stays reachable by being typed, and stays absent from the model's context
until it is. `ADR-007-command-entry-point.md` § 1 decides that `/trip` is the single entry
point for addressing, and that decision survives a format change — an installed verb is still
addressed, by the same typed form. Its own amendment already records that a Markdown file
under `.claude/commands/` is *the older format of the same mechanism*, carrying the same
frontmatter but for two keys, so moving to the current format is continuous with that record
rather than in tension with it. What this record changes on that surface is its **location and
format**, and nothing else.

**Amendment (2026-09-18, Friday) — the engine directory now carries a skill file of its own.** The
paragraph naming the home the conversion lands said that the engine directory carried no skill file
at its root and was not a skill. That was true when this record was accepted, and it stopped being
true when the milestone that owns conversational entry added the guided-entry surface at the engine
root, so the claim is corrected in place above rather than left standing. This corrects a description
of the layout and changes nothing decided here: the verbs keep their home and are still reached
through their links, each verb keeps the invocation posture named above, and the surface at the root
declares no verb of its own. Where model inference becomes permitted was never decided by this
record, which says so in its opening; the rule that admits a surface which only proposes is recorded
in `ADR-007-command-entry-point.md` § 1, in its amendment of the same date.

### 2. Operator data does not move

The three operator stores keep their existing homes. `ADR-012-people-library.md` § 2 fixes the
person store — *"**The store is `people/`**, at the repo root, contents git-ignored with a
tracked `people/README.md` signpost"* — and `ADR-016-reusable-groups.md` § 2 fixes the group
store at `groups/` on the same pattern. Both remain literally true after this decision, and
**neither is reversed, narrowed nor re-opened.** What changes for a store is *how a verb
resolves it*, never *where it is*.

**ADR-012 § 2 forecast this disposition for exactly this state.** Its own reversibility note
reads: *"Reversible on paper until records materialise in operators' working directories; a
relocation is a migration thereafter."* Records have materialised. So no-movement is the
disposition that record predicted, rather than a constraint imposed on it from outside.

**One obligation this decision creates, and hands on rather than resolves.** ADR-012 refused an
out-of-repo store partly on the ground that *"Every engine surface — the resolution contract,
the publish guard, the schema gate — is repo-relative."* Once the engine's location and the
data's location need not coincide, **"repo-relative" acquires two referents**, and which one a
surface means stops being self-evident. That is not a narrowing of either storage decision — it
is a **disambiguation obligation**, and whichever per-store mechanism the owning slice selects
must keep each store reachable by every surface that refusal names, or it re-enters the refused
option by another door.

### 3. This record selects no mechanism

The qualifier is load-bearing and is kept. **This record** fixes that the engine has a location
and that engine references resolve against it; it does not fix *what names the location*, *in
what spelling*, or *through which carrier*. Selection happens in the four owning slices named
in § *The problem surface*, against measurement, simplest-first.

Two things this is **not**:

- **Not a claim that the mechanisms are undecided everywhere.** Each owning slice selects its
  own, and a later reader of this record should expect to find those selections in the slices
  rather than here. A record that asserted the question was open *for the release* would be
  false the day it merged; what is true permanently is that this record does not answer it.
- **Not a deferral of the architecture.** The architecture is decided above, unconditionally.
  Mechanism is a different altitude, and the superseded release is the evidence for keeping
  them apart: it selected a mechanism before decomposing the problem, and the decomposition is
  what would have falsified the selection.

## The problem surface, decomposed by how each reference is consumed

**The surface is four problems, not one.** They differ in how the reference is consumed, which
is what makes them differ in difficulty — and they do not share one answer. Sizes below were
probed at `8f3b3cb` with `python3` over the five verb files under `.claude/commands/`; each
figure carries its own extraction, because three of them do not reproduce on a naive read.

| Surface | How the reference is consumed | Size, with its extraction | Mechanism question still open | Owning slice |
|---|---|---|---|---|
| **S-A — assets read as documents** | the agent opens the file and is handed bytes; nothing substitutes anything inside it | `24 + 70 + 14 = 108` references, to `agents/`, `reference/` and `templates/` respectively | what states the root, and where | the engine-asset resolution slice |
| **S-B — assets executed through a tool grant** | the path is matched against a grant pattern, then handed to a tool | 57 references naming `scripts/`, resolving to 2 distinct scripts, carried on `4 + 12 = 16` grant patterns across 8 frontmatter lines — probed at `8f3b3cb` | what spelling a rooted grant pattern takes, and whether one spelling can be guaranteed per file | the engine-asset resolution slice |
| **S-C — pre-execution blocks** | the block runs at **load** time, before the body is read, and its exit status gates the verb's existence | 9 blocks — 10 occurrences of the marker less the 1 prose mention of it, probed at `8f3b3cb`; all 9 name the launching-project variable, which is the only harness variable present at 10 occurrences | whether a block can carry a root at all, and what replaces the evidence it gathers if it cannot | the operator-data resolution slice |
| **S-D — operator-owned data** | the agent resolves a store root and reads records the operator owns | `205 + 20 + 8 = 233` references across three stores — extraction below | what names a data root that is neither the engine nor the launching project | the operator-data resolution slice |

**Three of those figures do not reproduce on a naive read, and the difference is itself a
finding.** Probed at `8f3b3cb`: `trips/` returns 206 bare matches, of which one is a
working-directory-relative `./trips/` form, leaving 205; `people/` returns 27 and `groups/`
returns 19, of which 7 and 11 respectively are **already written behind a `<store-root>/`
placeholder** in the largest verb file. So the store figures above are the counts of references
**not yet abstracted**, and the resolution abstraction this milestone introduces is already
partly present in the corpus — a named root awaiting a mechanism, which is a design input to
the owning slice rather than a defect to remove.

### S-A — assets read as documents

**Candidates, with their costs.**

- **Rewrite every citation to carry the engine root.** Cost: the edits do not stop at the verb
  bodies — they reach transitively into the asset tree, and a rewrite there is **mechanically
  inert**, because this repository's own resolution contract states there is no include
  directive, so a file the agent opens is returned as bytes under either spelling. It also puts
  an unexpanded variable in front of every human reader of a public repository, and it collides
  with the citation-form gate, whose home map is derived from the tracked tree on every run and
  currently requires the repository-qualified form these citations already use.
- **State the root once, in prose, in each verb body.** Cost: it relies on the agent honouring
  a stated root when it chooses what to pass to a tool, which is not a harness guarantee and
  must therefore be graded by an assertion rather than observed from a substitution.
- **Read the base directory the runtime volunteers on each invocation.** Cost: it needs no
  variable and no declaration at all, which makes it the simplest candidate — and it rests on a
  runtime courtesy that nothing in this repository asserts, so a change in that behaviour would
  be silent.

**Not selected here.** The open question is which carrier states the root, and it belongs to
the engine-asset resolution slice.

### S-B — assets executed through a tool grant

**Candidates, with their costs.**

- **Root the grant pattern through the installed-directory variable.** Cost: a grant is a
  **string match**, so two spellings of one file are two patterns. A rooted permit standing
  beside a bare deny is the dangerous shape — the permit resolves and the prohibition matches
  nothing — and a normalised spelling of the same path is a third string. Whatever is selected
  needs one spelling per file, asserted rather than intended.
- **Leave the patterns repository-relative.** Cost: the grant does not resolve once the engine
  is reached from outside the checkout, which is the defect rather than a tolerance.

**Not selected here.** The open question is the spelling and its uniqueness guarantee, and it
belongs to the engine-asset resolution slice.

### S-C — pre-execution blocks

**This is the surface driver 3 bears on, and it is the hardest of the four.** A block runs
before the body, and a non-zero exit deletes the verb rather than degrading it.

**Candidates, with their costs.**

- **Root the blocks.** Cost: a rooted block that fails takes its verb with it, so the block
  must terminate in an unconditional-success construct — and the compound statement that does
  so needs shell commands that the verbs' own grant lines deny. The candidate is therefore not
  obviously reachable under the current privilege boundary, which this record does not relax.
- **Retire the blocks for the data stores.** Cost: the evidence they gather has to be
  re-sourced, and a verb that loses its evidence ladder loses the diagnosis that ladder
  carried. Its benefit is that it removes the fatal-exit surface rather than hardening it.

**Not selected here.** The open question is whether a block can carry a root at all, and it
belongs to the operator-data resolution slice. § *Open questions* records the collision it
arrives with.

### S-D — operator-owned data

**Candidates, with their costs.**

- **The engine's own root.** Cost: **disqualified by measurement, not by argument.** Each store
  ships a tracked signpost file, so an installed engine carries a present-but-record-free store.
  Evaluated against it, the trip resolution ladder's canary **passes** and the population reads
  zero, so the verb cleanly tells the operator they have no trips while their real trips sit
  elsewhere. A silent wrong answer is worse than a refusal, and this candidate produces one.
- **The launching project's directory.** Cost: it is the present defect. The store follows
  whichever project the operator happens to open.
- **One operator-declared data root, resolved by the agent.** Cost: a new configuration surface
  the operator has to set, and a resolution the harness does not enforce — so it needs the same
  assertion treatment as S-A's prose contract. Its benefit is that the three stores are three
  subdirectories of one root today, so one pointer serves all three.

**Not selected here.** The open question is what names a data root that is neither the engine
nor the launching project, and it belongs to the operator-data resolution slice — under § *Decision* 2,
with no data moving.

## Consequences

### Five documented claims this choice invalidates

The cost of this decision is mostly paid in the documentation that describes the old
architecture. Probed at `8f3b3cb` over the 127 tracked markdown files, five claims are
affected, and each is named so the cost is recorded here rather than discovered by a reader
later. Correcting them belongs to the legacy-surface retirement slice.

| # | The claim, and where | What this decision does to it |
|---|---|---|
| **F-1** | *"there's nothing to build or install into your system. You clone it and open it in Claude Code"* — `README.md`, intro | **Directly reversed.** There is now something to install |
| **F-2** | *"**Desktop app** — open the `travel-planner` folder"* — `README.md`, setup | **Reversed as the invocation path.** Opening the folder stops being how the engine is reached |
| **F-3** | *"`git` — to clone this repo"* as the sole acquisition prerequisite — `README.md` | **Narrowed.** Cloning stops being sufficient; an install step joins the prerequisite set |
| **F-4** | *"Confirm the engine cloned intact:"* — `README.md` | **Re-framed.** The integrity check's subject becomes the installed engine, not the clone |
| **F-5** | *"`.claude/commands/` ← the slash commands — the addressable surface"* — `CLAUDE.md`, tree diagram | **Re-pointed, and deliberately not reversed.** See the boundary below |

**F-5 is a foreclosure boundary rather than a foreclosure.** What moves is the surface's
**location and format**. What does not move, and is not touched by this record:
`ADR-007-command-entry-point.md`'s addressing decision, its privilege boundary, and the
description-invocation suppression posture — whose arbitration belongs to the milestone that
owns conversational entry. A skill is still addressable, so the entry-point decision survives
the format change intact. This record forecloses what it decides and no more.

### The fatal pre-execution exit, as a mechanism-independent cost

Driver 3's property is a **consequence of being installed at all**, not of any carrier:

- **A failing pre-execution block deletes its verb.** Any installed form inherits this. It is
  why the pre-execution surface is listed as its own problem in § *The problem surface* rather
  than folded into the asset surface it superficially resembles.
- **Diagnosis cannot live in the block.** The body that would carry the message is never
  reached when the block aborts, so a design that wants a resolution failure to *explain itself*
  cannot put the explanation where the failure happens.
- **An ordinary operator state reaches it.** `CLAUDE.md` § *Resolving a trip* declares, as
  correct behaviour, that the second evidence block **is expected to be error-shaped when the
  trip population is zero**. A fresh install has a zero population. So a charter-sanctioned
  normal state becomes, under an installed form, a verb that does not exist — and the listing
  canary protects the first block and not the second. This is a cost of the architecture; the
  treatment belongs to the slices.

### Amendment slot — the selected data-store mechanism's teardown behaviour

**Reserved deliberately, and filled by amendment below.** The operator-data resolution slice records the
teardown behaviour of whatever per-store mechanism it selects, as a dated amendment paragraph
in this subsection. That is an **amendment and not a supersession**: it adds a statement about a
mechanism this record declines to choose, and it reverses, narrows and re-opens nothing
decided above. Naming the slot here means that edit is an in-place addition rather than a
structural change to a merged record.

**Amendment (2026-09-13, Sunday) — the selected mechanism and what removing the engine does to operator data.**
The operator-data resolution slice selected **one data root shared by all three stores, named by one
operator-config pointer** — a single-line file at `${HOME}/.travel-planner/data-root` holding one
absolute path — **resolved by the agent** at gate `G0-root` of `CLAUDE.md` § *Resolving a trip*. One
mechanism rather than three, because the three stores are already three children of one root and the
store-root rule in `reference/data-model.md` already makes the person store's fallback the trip
store's root; separate pointers would buy nothing and cost three drift axes. No store moved.

Teardown, stated in the terms an operator needs before they uninstall anything:

> **Removing the engine removes the engine directory and the five verb links that point into it,
> and nothing else.** The pointer lives outside both and survives. The data lives outside both, at
> the path the pointer names, and survives — removing the data means deleting that directory
> yourself, deliberately. **An engine update replaces the engine directory and touches neither**;
> the links name that directory by path, so they resolve unchanged across an update. The engine's
> own `trips/`, `people/` and `groups/` are a tracked, record-free skeleton; they are not an operator
> store and nothing writes an operator record into them, which is what gate `G0-root` exists to
> guarantee.

This amendment reverses, narrows and re-opens nothing above, and it amends neither storage-home
decision: each of those fixes its store at the root of the tree that holds it, which stays literally
true — a resolution change is not a relocation.

### Costs and residual risks, stated rather than minimised

- **The number `ADR-020` is never used.** The record this one supersedes was assigned that
  number on a branch that has since been swept, and no blob of it is reachable from any ref.
  The index convention forbids reuse and renumbering, and a number whose freeness cannot be
  established is not free — so the sequence carries a permanent gap at `ADR-020`, between this
  record and `ADR-019`. That gap is now **declared**: it carries a row in the
  `adr-number-declaration` fence in `reference/adr/README.md`, and
  `scripts/test-corpus-hygiene.sh` group `D` grades the numbering against that fence. So the
  gap is non-blocking **because something measures it and passes** — which is the opposite of
  what this bullet said when it shipped, and the amendment below records the correction.
- **An index/file status divergence class exists and is ungraded.** This record's own index edit
  repairs the one live instance, which leaves the class with zero observed instances and still
  no check behind it. The next occurrence will be silent, and this record merging `Proposed`
  with the flip named in its Status block is the most likely candidate for it.
- **No assertion in this repository grades a stated root.** On more than one surface the
  simplest candidate rests on the agent honouring a root stated in prose. That is gradable by an
  assertion over the declared text, never by observing a substitution, and a slice selecting one
  of them owes the assertion rather than the intention.

**Amendment (2026-09-21, Monday) — record-number contiguity is graded now, and the first
bullet's closing claim is corrected in place rather than softened.** That bullet shipped saying
the gap at `ADR-020` was non-blocking *because nothing measures it, not because something
measured it and passed*. That was a true statement of the state it was written in and is a
false one now. `scripts/test-corpus-hygiene.sh` group `D` grades number uniqueness across the
record directory and across the index, grades contiguity against the `adr-number-declaration`
fence in `reference/adr/README.md`, and compares index against directory in both directions;
this record's gap is declared in that fence and passes. **Nothing else in this section moves,
and the scope of that is worth stating.** The second bullet names an index/file **status**
divergence — a row's `Status` cell disagreeing with the record's own — which is a different
property from the existence agreement group `D` grades, so that bullet stands unchanged and
its class stays ungraded. The third bullet is untouched. No decision in this record is
reversed, narrowed or re-opened.

### Reversibility summary

| What | Tier | Why |
|---|---|---|
| The architecture decision itself | **EXPENSIVE** | Reversing it means un-picking whatever the four slices select, and re-reversing the documentation this record forecloses |
| The record's number and filename | **IRREVERSIBLE** | Numbers are never reused or renumbered, and sibling prose cites this record by filename |
| The per-surface mechanisms | **CHEAP to MODERATE**, and not decided here | Each is a spelling or a carrier inside one slice; that is part of why selection is left to the slices |
| Operator data | **n/a — nothing moves** | § *Decision* 2. No migration is in scope, so there is nothing to roll back |

## Open questions

Each is stated with its owning slice, and none is answered here.

| # | Question | Surface | Owning slice |
|---|---|---|---|
| **Q-1** | What states the engine root for assets the agent reads as documents, and where is it stated | S-A | the engine-asset resolution slice |
| **Q-2** | What spelling a rooted grant pattern takes, and how one spelling per file is guaranteed rather than intended | S-B | the engine-asset resolution slice |
| **Q-3** | Whether a pre-execution block can carry a root at all under the current privilege boundary, and what replaces the evidence it gathers if it cannot | S-C | the operator-data resolution slice |
| **Q-4** | What names a data root that is neither the engine nor the launching project, with no data moving | S-D | the operator-data resolution slice |
| **Q-5** | Whether a packaged form is the right way to **distribute and update** the engine — live and separate, since driver 1 refutes only the resolution argument | the engine as a whole | not yet owned; recorded here so it is not read as settled |

**Q-3 arrives with a collision, recorded because the owning slice inherits it rather than
discovers it.** Two criteria on that slice pull against driver 3: a failure is required to name
its cause and its fix, and a listing canary is required to protect the ladder. A fatal abort
satisfies neither — the body carrying the message is never reached, and the canary covers the
first evidence block and not the second. Whichever treatment is selected has to answer that,
and this record's contribution is to say so before the slice starts rather than after.

**Amendment (2026-09-13, Sunday) — where each selection lives, as built.** The slices have run, and
the sentence above stays true: none of these questions is answered *here*. This paragraph records
**where** each answer lives in the tracked corpus, so the reader § *Decision* 3 sends to the slices
finds a location rather than a search, and it re-frames the one row that would otherwise mislead.

- **Q-1 / S-A** — the second candidate, *state the root once, in prose, in each verb body*: the
  **Engine root** paragraph that opens every `skills/<verb>/SKILL.md`, naming `${CLAUDE_SKILL_DIR}/../..`
  as the directory every engine path in that file and in any document opened from it resolves
  against. The first candidate was rejected on the cost stated above — a rewrite of the asset tree is
  inert under this repository's resolution contract. The third was the solutioning pass's original
  headline, *documents resolve by position*, and driver 2 is its falsification: a bare reference
  follows the session's directory, not the base the runtime names, so the prose contract was
  selected on measurement rather than by comparison of costs.
- **Q-2 / S-B** — the rooted spelling `${CLAUDE_SKILL_DIR}/../../scripts/<name>` in every grant, permit
  and deny alike, one spelling per file **asserted** by the command-taxonomy guard, which grades the
  permit set, the deny set and their vacuity. The rationale — the alternatives compared and why the
  harness-substituted variable won — is recorded in that slice's solutioning record and in the
  message of the commit that rooted the grants; this record carries the outcome, not the comparison.
- **Q-3 / S-C** — the second candidate, *retire the blocks*: all nine pre-execution blocks are gone.
  The evidence they gathered is now gathered by ordinary tool calls under the grants a verb already
  holds, after the data root is resolved; `CLAUDE.md` § *Resolving a trip* states the entries and the
  reason each terminates in an unconditional-success construct. The collision recorded above is
  discharged by the same retirement: a failure now names its cause because it runs as a tool call
  whose output the verb reads, rather than as a block whose failure is fatal to the load.
- **Q-4 / S-D** — answered by the amendment in § *Amendment slot* above; the same paragraph carries
  the teardown statement.
- **Q-5 — settled for this release, and the row above is read accordingly.** The packaged form was
  built first, and was found at the release gate to install every verb under a **namespaced** name:
  the runtime prefixes each skill a package carries with the package's own name, and neither the
  package declaration nor a verb's frontmatter removes the prefix — so the operator's requirement,
  a bare `/trip` that works from any folder, was not met by it. On the operator's ruling it was
  replaced by the **clone-and-link form**: the engine is cloned into the harness's skills directory
  as a plain directory, and each verb's `skills/<verb>/` is linked beside it under the verb's own
  name, so the verbs appear bare and nothing inside them changes. Distribution is that clone plus
  the link step; an update is a `git pull` in the engine directory, which the links follow by path.
  The packaged form is preserved here as a measured and rejected candidate, not deleted. `README.md`
  § *Install* is the operator-facing statement; the install-documentation slice owns it. "Not read
  as settled" described the state before the slices ran, and describes nothing now.

One consequence of Q-1 and Q-3 together is stated here because no slice owns it alone. `CLAUDE.md`
§ *Resolving a trip* is loaded with the workspace, not with an installed engine, so a verb that
consults it from an installed engine opens it at the engine root — **one read per invocation that
the workspace form never made.** ADR-007 § 2's first bound, *no per-invocation read*, is read as
binding the workspace form, which it still does; the installed form's single read is the cost of
driver 3 and is accepted with it. The verb bodies and `CLAUDE.md` state the two cases wherever they
say what is in context.

## Follow-on build slices

- **The verb-format conversion.** Converts the five verbs to the installed form at
  `skills/<verb>/`, preserving the invocation posture § *Decision* 1 names.
- **Engine-asset resolution.** Owns Q-1 and Q-2 — the document and executable surfaces.
- **Operator-data resolution.** Owns Q-3 and Q-4 — all three stores, resolved from any working
  directory, with no data moving.
- **Legacy-surface retirement.** Retires the old command surface and corrects the five claims
  in § *Consequences*, including the desktop path.

## References

- `ADR-007-command-entry-point.md` § 1 — the addressing decision and the privilege boundary this
  record re-points in location and format and does not otherwise touch, and whose own amendment
  records the two command formats as one mechanism
- `ADR-012-people-library.md` § 2 — the person store's home, its reversibility note, and the
  repo-relative refusal that § *Decision* 2 turns into a disambiguation obligation
- `ADR-016-reusable-groups.md` § 2 — the group store's home, unchanged here
- `ADR-013-count-assertion-basis.md` — the four admitted basis forms that govern how every count
  in this record is written
- `reference/adr/README.md` — the record convention, the status lifecycle, and the
  amendment-versus-supersession split this record's `Supersedes` clause is authored against
- `CLAUDE.md` § *Resolving a trip* — the evidence ladder, and the declaration that its second
  block is expected to be error-shaped at a zero trip population
- `README.md` — the install, setup and integrity claims enumerated as F-1 … F-4
