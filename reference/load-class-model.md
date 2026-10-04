# Load-Class Model — What Loads a File, and When

**This document declares. It checks nothing, grades nothing and adds no gate.** It names the load
classes of the engine's tracked markdown, states the rule that puts every file in exactly one of
them, and carries the byte parameters a size assertion is to read. An assertion that cites a class
or a parameter cites it here; nothing here asserts, and whether an assertion exists is not this
document's to say.

**Load cost is a property of the edge between a consumer and a file, not of the file.** The same
bytes are in context from the first moment of a session, read once per invocation, read only when a
step names them, or never read by a session at all — depending on who loads them and when. A class
is therefore named by a consumer and a moment, and a file's class is the costliest edge that reaches
it. No class is a place in the tree: a file that moves keeps its class for as long as the same
consumer loads it at the same moment, and changes class the moment that stops being true.

**A load class is not a lifecycle class and not an artifact class.** Those classify a trip's
artifacts (`reference/data-architecture.md` § 1 and § 6); this classifies the engine's own files.

## 1. The consumers, and the moment each one loads a file

| Consumer | Moment | What it loads |
|---|---|---|
| The harness | the start of every session | the description of every installed skill file whose invocation flag is not set — what that flag does is cited below |
| The harness | a skill is invoked — its name is typed, or a request is routed to it | that skill file's body |
| A verb | every invocation, before it acts | the document its contract line names |
| The calling session, then the agent it dispatches | each dispatch | the agent's prompt, once in each of the two sessions |
| A session | a step of a loaded instruction names a file | the file named |
| The guard suites | every push | the worked instances they grade |
| The release procedure | each release | the release log — one entry appended, then published as that release's body |
| A person | by choice | what the repository host presents, and what another document cites |

**What a skill file's invocation flag does is arbitrated elsewhere, and is cited here rather than
re-derived:** `reference/adr/ADR-007-command-entry-point.md` § 1, in its amendments of 2026-09-11
and 2026-09-18. No class below says anything about that flag which that record does not.

**The dispatch mechanism is the charter's, and is cited rather than restated:** `CLAUDE.md`
§ *Dispatching agents* states it twice — in the section's opening instruction, and in its
*For Agent tool calls* paragraph. The prompt is read by the session that dispatches and handed to
the agent as its instructions, so its bytes are paid in both.

## 2. The posture these classes are stated against

**The decided posture leads: the engine is an installed capability**
(`reference/adr/ADR-021-installable-capability.md` § *Decision* 1, as amended on 2026-09-18). The
engine has a directory of its own, a verb is reached without opening it, and the directory
carries a skill file at its root — the guided-entry surface, which names a verb and runs none. In
this posture **the charter is not auto-loaded.** It is read: once per invocation by a verb, and live
by the guided-entry surface when a request is routed to it. Every class and every parameter below
is stated against this posture.

**The other posture is a workspace checkout, and what it adds is conditioned on it.** Where this
repository is itself the workspace, the harness loads the charter at the start of every session.
The charter is then paid for as the `listed` class is — from the first moment, whether or not a
verb runs — and for its whole length. That is the only sense in which anything here is always
loaded, and it holds in that posture alone. No parameter below is stated against it.

**A dispatched prompt has no posture.** Where the engine lives changes nothing about who reads a
prompt or when, so the `dispatched` class reads the same under both.

## 3. The classes

Costliest first. The order is also the tie-break: a file that more than one edge reaches takes the
first class that holds.

| Class | What loads it, and when | Budget posture, for a file that declares no growth property (§ 5) |
|---|---|---|
| `listed` | The harness — its description at the start of every session, its body when its name is typed or a request is routed to it | a ceiling row, from the floor up |
| `first-read` | A verb, once per invocation, before it acts — and the guided-entry surface, live, when it routes | a named constant, and its row |
| `typed` | The harness, when its verb is typed and at no other moment | a ceiling row, from the floor up |
| `dispatched` | The calling session and then the dispatched agent, at each dispatch | a ceiling row, from the floor up |
| `on-demand` | A session, when a step of an instruction surface names it | a ceiling row, from the floor up |
| `fixture` | The guard suites on every push, and a person following a worked example — no session, unless an instruction surface names it | none |
| `release-log` | The release procedure, once per release | none |
| `browsed` | A person, by choice — through the repository host, or by following a citation out of another document | a ceiling row, from the floor up |

**What orders them.** How often a session pays for the file's bytes comes first: at the start of
every session, then on every invocation, then when its own verb is typed, then at a dispatch, then
only when a step asks. Below that no session pays as a matter of course, and the order is how
regularly something else reads the file: a suite on every push, the release procedure once per
release, a person when they choose.

**Why some files take no instrument.** A file that declares a growth property takes none, whatever
its class (§ 5). A file a frozen-witness digest pins has its bytes fixed already, by a second
mechanism, so a ceiling beside the pin could only ever move in lockstep with it. The log only ever
grows, by design, an entry per release: a ceiling on it would fail on a schedule and decide nothing.
The `fixture` class takes none for a reason of its own: a fixture is a specimen — its size is
whatever the instance it shows requires, and the suites that read it grade its content.

## 4. The classification rule

Every tracked markdown file resolves to exactly one class by the rule below. The rule reads what
the tree says about a file — its own opening block, and the files that name it — and never where
the file sits. **A file no clause reaches is unclassified, and that is a finding about the file:**
nothing loads it, nothing cites it, and no reader has been named for it.

**Terms.**

- A **skill surface** is a file whose opening frontmatter block carries both `name` and
  `description`.
- A file **cites** another when the other's path stands anywhere in its text, fenced blocks
  included.
- A file **names** another when it cites it, or when the path of the directory that directly holds
  the other stands in its prose, ending in a slash. Prose is every line outside a fenced block. A
  directory path that a wildcard follows — an asterisk, a question mark or an opening square
  bracket, directly after its slash — is a pattern, not a directory, and names nothing.
- A file is **bundled** with a skill surface when the surface, or a file already bundled with it,
  cites the file through the skill-directory variable, `${CLAUDE_SKILL_DIR}`, standing for the
  surface's own directory; repeated until nothing more is added. A skill surface is bundled with
  no other.
- An **instruction surface** is a file of the first four classes, or a file bundled with a skill
  surface.

The block below fixes what a path is, where it resolves, and what a fence is.

```text
path      a run of segments joined by slashes, optionally ending in a slash;
          a single segment is a path too;
          a segment is letters, digits, underscore, hyphen and full stop
          taken whole — no segment character and no slash stands immediately before it;
          a trailing full stop is dropped
resolves  ${CLAUDE_SKILL_DIR}/path  against the directory of each skill surface the file holding
                                    the path is bundled with, a skill surface being bundled
                                    with itself; in a file bundled with none, against nothing
          <engine-root>/path        against the repository root
          path                      against the repository root, and failing that
                                    against the directory of the file holding the path
fenced    from a line whose first non-blank characters are three backticks
          to the next such line
tagged    a fence tagged T opens on a line that is exactly three backticks and T,
          and closes on the next line that is exactly three backticks
reserved  README.md  CONTRIBUTING.md  SECURITY.md  PULL_REQUEST_TEMPLATE.md
```

**The clauses, in order. The first that holds decides.**

1. `listed` — a skill surface whose frontmatter does not set `disable-model-invocation: true`.
2. `first-read` — a file named on the `Contract:` line of a skill surface.
3. `typed` — a skill surface whose frontmatter sets `disable-model-invocation: true`.
4. `dispatched` — a file named in the `Prompt File` column of a dispatch roster that a file of the
   classes above carries.
5. `on-demand` — a file an instruction surface names.
6. `fixture` — a file whose frontmatter declares `artifact`, or that is **pinned**: a row of a
   fence tagged `frozen-witness-digest`, in any tracked markdown file, pairs a forty-character
   hexadecimal digest with the file's path.
7. `release-log` — a file that carries **release entries**: at least one second-level heading
   stands outside its fenced blocks, and every such heading opens with a bracketed version of the
   `[X.Y.Z]` form, each part a number, or with `[Unreleased]`.
8. `browsed` — a file whose name is one the repository host reserves, listed in the block above, or
   a file that some other tracked markdown file cites.

**What the rule deliberately does not do.** It follows no chain but the bundle: a file that only an
on-demand document names is `browsed`, not `on-demand`, because no instruction names it. It reads a
name, not a reader's intent: a path an instruction surface cites for provenance counts as much as
one it tells an agent to open. And it reads a directory as naming the files directly in it only
where prose names the directory: a map's line inside a fenced block names nothing, and neither does
a pattern. None of these limits moves a ceiling — `on-demand` and `browsed` carry the same
parameters. That a pinned file and the log take no instrument is decided by a property each
declares (§ 5), not by the rank of its class. One line is still drawn by class: an instruction
surface that names a file declaring `artifact`, and pinned by no digest row, puts it on demand and
under that class's row.

**What bundling assumes.** The term reads the skill-directory variable, so it holds for any layout
of skill files — each verb in a directory of its own, or one router at the engine root whose bodies
sit beneath it — provided a skill names through the variable the files it reads as part of itself,
and names every other engine document by its path from the engine root. A document named through
the variable is bundled, so it is an instruction surface and what it names is on demand. A body a
skill names only by its path from the engine root is on demand and not bundled, so a file that it
alone cites is `browsed`.

## 5. The parameter table

Every quantity is in bytes — the size of the file as the repository stores it — and never in lines.
A row declares a parameter of a class: the key is the class and the parameter joined by a full
stop, the value follows after whitespace, a line whose first character is `#` is a comment, and a
blank line is ignored. It is the shape the declaring fences in `reference/data-architecture.md` and
`reference/adr/README.md` already use, so the reader those fences have reads this one.

```load-class-parameters
# class.parameter          value
listed.instrument          row
listed.floor               20000
listed.headroom            10%
listed.band                headroom
first-read.instrument      constant
first-read.floor           20000
first-read.headroom        10%
first-read.band            headroom
typed.instrument           row
typed.floor                20000
typed.headroom             10%
typed.band                 headroom
dispatched.instrument      row
dispatched.floor           20000
dispatched.headroom        10%
dispatched.band            headroom
on-demand.instrument       row
on-demand.floor            20000
on-demand.headroom         10%
on-demand.band             headroom
fixture.instrument         none
fixture.floor              -
fixture.headroom           -
fixture.band               -
release-log.instrument     none
release-log.floor          -
release-log.headroom       -
release-log.band           -
browsed.instrument         row
browsed.floor              20000
browsed.headroom           10%
browsed.band               headroom
```

**What each parameter means.**

- **`instrument`** — what a size assertion is to hold a file of the class to. `row`: a row of its
  own in a size fence — a declared byte ceiling that fails when the file exceeds it. `constant`:
  its row like any other, and a named constant as well; the lower of the two is the operative
  ceiling, and a row that stands above the constant is a disagreement between them, never a second
  budget. `none`: nothing — no size instrument applies, and a fence carries no row for the file.
  **A growth property the file declares decides `none` before its class does:** a file that is
  pinned, or that carries release entries, both as § 4 defines them, takes `none` whatever its
  class, because a second mechanism already fixes its bytes or its growth is its function. Every
  other file takes its class's instrument.
- **`floor`** — a file smaller than its class floor owes no row. A constant takes no floor: it
  bounds its file at any size, so where the instrument is `constant` the floor governs the row and
  not the constant. **A file owes a row** when its instrument is `row` or `constant` and its size
  is at or above its class floor.
- **`headroom`** — the allowance above a file's size at the moment its ceiling is seeded or
  re-pinned: that share of the size, rounded up to a whole byte. A ceiling is the size plus the
  headroom.
- **`band`** — how far a file may grow before its ceiling fails. It is the seeding headroom and
  nothing else, which is why the table writes it as `headroom` rather than as a number of its own:
  the two cannot be declared apart. It runs upward only. Nothing here bounds a file from below.

**Where each value comes from.** The instruments are decisions: a constant for the file every
invocation reads, a row for everything else an author grows, and nothing for the specimen, the
pinned file and the log. The floor and the headroom are chosen, not measured, and the band is
defined from the headroom rather than chosen at all. No value in the table is a measurement of this
tree, so none goes stale when the tree changes. Changing one is an edit to its row, and to nothing
else.

## 6. What reads this, and what this does not do

**A size assertion reads the table; this document reads no assertion.** A file's class comes from
the rule in § 4. Its instrument comes from § 5 — a growth property it declares first, and otherwise
its class's row — and its parameters from that class's rows. The assertion is its reader's own.
Nothing in this document runs.

**A class is a statement about cost. It is not a grant and not a rule of conduct.** It says how
often a file's bytes are paid for. Which verb may read which path is that verb's own declaration,
and what a file may say is that file's own business.

**The rule sees the edges the tree states, and only those.** A read that no file states — an agent
opening a document nothing names — is not an edge here. Where that matters, the remedy is to state
the read where it is made, and the class follows from the statement.
