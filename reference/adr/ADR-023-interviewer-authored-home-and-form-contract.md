# ADR-023: The interviewer's authored home and the form contract — a declared fence, the restatement homes retired, and what the next form costs

- **Status:** Accepted (2026-09-20)
- **Deciders:** repo maintainer
- **Driving work:** the *interviewer becomes a component* milestone. This record is one of that
  milestone's two Wave-0 gating records, in the shape `ADR-012-people-library.md` and
  `ADR-016-reusable-groups.md` already ship: it lands before any feature slice and settles a
  cross-cutting question every slice would otherwise answer separately. The two records split one
  subject on a stated axis — **this record decides structure**, and its sibling
  [`ADR-022`](ADR-022-interview-session-model.md) decides **behaviour over time**. Slices are cut
  after both close.
- **What this record is.** A decision about **where interview conduct is authored, and what a form
  must expose to be interviewable by it**: the authored home and its command surface, the contract a
  conforming form satisfies, what changes in the shipped forms, what a reader with no repository
  receives, what the assertion surface becomes once conduct is no longer authored in the file the
  assertion walks, and what the next form costs. Its subject is a file and a declaration, not a
  session.
- **What this record is not. It decides no conduct, no tone, and no session behaviour.** It decides
  no lifecycle, no resumption, no write cadence, no sequencing, no proxy-vs-self rule, no
  conversational-integrity rule and no modality contract. Those are `ADR-022`'s, and this record
  neither quotes nor predicts a clause of it. Where the two must meet, they meet in
  § *The seam*, which states what a conforming form **exposes** and says nothing about what a
  session does with it.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the operator's, taken at this milestone's close, and it moves **both** halves of
  a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md). No required check here grades either half or their agreement, so the
  obligation travels with this line rather than with a gate.
  [`ADR-021`](ADR-021-installable-capability.md) carries the same clause for the same reason, and
  `ADR-022` carries it beside this record.

## Context

**Interview conduct is authored inside the artifact it interviews, once per form, and the metadata a
form-agnostic interviewer would need is split across homes that no single declaration binds
together.**

Both shipped guided forms carry an interview guide below their `<!-- PROFILE-END -->` sentinel: a
numbered rule block, a walk-through of that form's own sections, and an output contract. A third
guided form would be a third copy. The embedding was deliberate and the driver is recorded — the
appendix must travel to third-party assistants that cannot read `agents/`. The driver still holds.
What has changed is the number of forms the engine expects to carry.

**The duplication is real and it is smaller than it looks, and the difference changes the design.**
Measured over the two guides' lines by longest-common-subsequence at `edadfa9`: the identical share
is a minority of the total, and the remainder is each form's **own** per-section script, naming that
form's own fields. A design that treats the whole guide as duplication relocates form-specific
content away from the form it describes — the opposite of the reuse the move exists for. So the
cleave is not *guide against form*. It is **rule · script · restatement**:

| Layer | Disposition |
|---|---|
| The numbered conduct rules and the output contract | **authored once**, outside any form |
| The per-section ask-prose | **stays with the form** — it is about that form's own sections |
| The `Fields: **X**, **Y** (starred).` lines, and the rule-4 numeral | **deleted, not relocated** — the interviewer reads the bullets |

**That third layer is the one the framing does not contemplate**, and it is where the assertion
surface turns. Group `ST` of `scripts/test-artifact-schema.sh` grades a per-form star count across
the homes its own workflow comment enumerates: the banner numeral, the appendix rule-4 numeral,
the appendix's per-field annotations, and the marked fields themselves — *"the only home that is
not a restatement of another, and therefore the reference count."* The annotations and the rule-4
numeral are restatements **whose only reader is the conduct that is leaving**. They are not
relocated. They are retired, and `ST` grades what remains.

**A form-agnostic interviewer needs less declaration than it first appears to need, and one thing it
cannot get at all.** Section order, field order, exact labels, the star marker, the option text, the
examples and the skip-ifs are all already in the form's own markup, read by a language model that
reads the form. Cardinality, class, overridability, horizon and the never-asked set are already in
`reference/data-model.md` § *Field Scope*, keyed by label. What is missing is not capability: it is
**a surface something can grade**. The profile half's end is normative in the data model's own
denominator rule and **no script reads it** (probed over the tracked tree at `edadfa9`; the control
token `ANSWERED(` is read by `scripts/test-artifact-schema.sh`, so scripts *are* being read by the
same instrument). The form's contract version does not exist, so a skill and a form disagree
silently. And whether a field's option list is **closed** is declared nowhere.

**The suite does not know the boundary exists.** `rl_bullets` — reused across several groups — reads
`/^- /` across the whole file with no stop at the sentinel. Measured leakage today is nil: the guide
half contributes no labelled bullet to either form's count, against a non-zero count above the
boundary in both. That is a property of how the guides happen to be written, not of anything
declared, and a single `- **Label:**` line added below the sentinel changes several groups'
denominators with nothing to say so.

**The constraint this record is authored inside.** The milestone fixes the artifact set at **skill
plus form**. That constraint is held here, and § *Decision* 1 states what it cost.

## Decision drivers

- **A second source of truth for what a field is, is the defect.** `skills/trip-record/SKILL.md`
  already states the engine's verdict on this shape for the two predicates it reads live: *a second
  implementation of either predicate would be a second source of truth for what a field is.* Any
  contract that copies the classification table into a declaration re-creates exactly that.
- **A restatement is kept only where something grades it, and retired the moment its reader
  leaves.** A home with no reader is a drift target and an assertion cost, and nothing else.
- **A zero that nothing declared is not an assurance.** The boundary's current cleanliness is
  incidental. A contract that leaves it incidental has declared nothing.
- **The install path is part of the design surface.** `README.md` installs by a loop naming the
  shipped verbs literally and documents upgrade as a bare `git pull`, twice. A decision that adds a
  command is a decision about every existing install, whether or not it says so.
- **Cost per new form is the claim.** The record exists to make *the next form* cheap. A decision
  that shrinks conduct while growing declaration has moved the cost rather than removed it.
- **The engine's own idioms win over invented ones.** A machine-readable declaration inside prose has
  a shipped shape here — the custom fence info-string — used across the corpus in several distinct
  tags. A new mechanism needs a reason the shipped one does not serve.

## Options considered

Two decisions carry more than one live candidate. The rest are forced by measurement, and this
record says so rather than staging a comparison for appearance.

### Choice 1 — where form-agnostic conduct is authored

| | A1 a new skill | A2 a new Zone-B verb on `trip-record` | A3 reuse `profile` alone | A4 a reference document | A5 status quo |
|---|---|---|---|---|---|
| Conduct authored once | yes | yes | no — per form | yes | no |
| The durable form gains a route | yes | yes | **no** | yes | no |
| Reachable after the documented upgrade | **no** | yes | yes | yes | yes |
| Widens the grant union | no | no | no | no | no |
| Breaks a frozen rule | no | no | no | **yes — the milestone constraint** | no |
| Verdict | **reject** | **selected** | reject | reject on the constraint | reject |

**A1's disqualifier is mechanical, not stylistic.** `README.md` installs by a `for v in …; do ln -s`
loop naming the shipped verbs literally, uninstalls by the same literal list, and states that
updating is a `git pull` in both its install section and its maintenance section. A command outside that list therefore appears for **no
existing operator** on upgrade, with no error and no signal, and both of those sentences become
false. That is the silently-stale-coverage shape this repository's suites exist to refuse,
reproduced in an install path no suite reads. Secondarily,
`scripts/test-command-taxonomy.sh` enumerates `"$cdir"/*/SKILL.md`, so any new directory under
`skills/` is read as a command and owes the full command contract — there is no *library skill*
shape available to borrow.

**A4 is rejected on the operator's constraint and not on merit, and the distinction is recorded
because the record's honesty depends on it.** A reference document cited live at invocation is the
**cheapest** option in the table and it is the idiom `## profile` already uses for
`reference/data-model.md`. Conduct has exactly that shape. It is foreclosed because the milestone
fixes the artifact set at skill plus form, and a reference document is a third artifact. The
constraint was upheld at the Stage-5 gate **with this cost known**, and the cost is named in
§ *Residuals* rather than absorbed silently.

**Why A2 does not breach `trip-record`'s zone rule, and the one thing it cannot do.**
§ *How this file is extended* closes Zone A and states that **nothing may be appended below the last
verb section**, enumerating what a later slice may add: requirement-table rows, a `**Reads:**` line
per new verb section, one `## <verb>` section per row appended below every existing one,
`allowed-tools` additions, and — for a verb that changes a persist-mutable file — that file's own
no-overwrite shape, stated inside that verb's own section. A **shared, non-verb**
conduct section is none of those. So A2 authors conduct **inside the new verb's own Zone-B
section**, and the other callers cite it. That is admissible — an existing Zone-B section may be
edited — and it makes one verb section the de-facto library, which is the cost § *Residuals*
carries.

### Choice 2 — how conduct reaches a reader with no repository

| | P1 the hand-off set grows | P2 a declared derived region in each form | P3 assemble at hand-off | P4 split the conduct | P5 hand over the `SKILL.md` |
|---|---|---|---|---|---|
| One authored source | yes | yes | yes | **no — a second home** | yes |
| The recipient is self-contained | yes | yes | yes | yes | yes |
| The agreement is asserted | yes — a tracked asset | yes — by the check | **no — the assembly is untracked** | partial | yes |
| The marker survives its reader | n/a | **no** | n/a | n/a | n/a |
| Suppresses an existing gate | no | **yes, silently** | no | no | no |
| Leaks grant and contract text to a stranger | no | no | no | no | **yes** |
| Verdict | **selected** | reject | reject | reject | reject |

**Adjudication of the declared derived region, on merit.** It was named as a candidate with in-repo
precedent, and it deserves the weighing rather than a dismissal. It genuinely reconciles
skill-plus-form with the no-repository reader, and it is the only option that puts the assertion
**on the projection itself**. It is rejected on grounds in descending weight:

1. **The form licenses its reader to delete the region.** Both forms say, immediately below the
   sentinel: *"Delete this guide or leave it; the planner ignores anything below this line."* A
   marker discipline over a region the document invites its reader to remove is not a discipline.
   The one live precedent is the opposite case — `reference/command-reference.md` states that
   *"Nothing in this file is maintained by hand except the prose."*
2. **It would silently suppress an existing gate, on precisely the sentences at issue.**
   `scripts/test-corpus-hygiene.sh` treats a derived-region opener as a count-assertion suppression
   region, and [`ADR-013`](ADR-013-count-assertion-basis.md) says so in terms: a comment that merely
   *looks* like a derived-region opener suppresses everything beneath it whether or not anything
   regenerates it. The residual count-assertion site in each template is the rule-4 sentence, which
   sits exactly where a projected region would land. The declaring fence's rows would read clean and
   the suppression would be invisible.
3. **The precedent is a single instance.** One declared derived region exists in the corpus, probed
   at `edadfa9`, against a non-empty population of HTML comments by the same instrument. `ADR-013`
   rejected the derived-region-only option for exactly this reason — the corpus contains no such
   region for the purpose, so the rule would ship green over an empty population.
4. **There is no generator.** The precedent's regeneration is the test **printing the block for a
   human to paste**. Multiplying a paste-back loop across the shipped forms, then across the next
   one, is a per-form cost that § *Decision* 6 exists to shrink.

**P2's goal is adopted; only its mechanism is rejected.** One authored source, a self-contained
hand-off and asserted agreement are all met by P1, because route 3 already **hands files over**
rather than naming paths. A further tracked artifact is graded like any other tracked file.

## Decision

Six clusters. The decision count is `5 + 7 + 4 + 3 + 6 + 3 = 28`, one series per cluster.

### 1. Authored home and command surface

**D1.1 — Form-agnostic conduct is authored once, in the Zone-B section of one new verb on
`skills/trip-record/SKILL.md`.** The verb is the interviewer: it takes a form and a target and
conducts that form's interview. The numbered conduct rules and the output contract live there and
nowhere else. Nothing is appended below the last verb section, and Zone A is not touched except
through the repair extension point that the falsifying edit in D1.3 obliges.

*Rejected:* a new skill (the install loop names the shipped verbs literally and the documented
upgrade is a bare `git pull`, so the command is unreachable for every existing install); a shared
non-verb section in Zone A (the extension rule permits five kinds of addition and a shared section
is none of them); a reference document (the milestone constraint, not merit — see § *Options
considered* and R2).

**D1.2 — The new verb is also the durable form's first command surface.** No shipped verb interviews
`templates/person-intake.template.md` today: the tracked references to that path copy it, and none
conducts it. The durable half of intake is therefore reachable only by hand-editing or by the
third-party-assistant route. Any answer to the authored-home question that leaves that unchanged
leaves the epic's claim true of one form and not the other. This record closes it by making the
verb form-agnostic rather than by authoring a second guide.

**D1.3 — `## profile` route 1 is repaired in the same act, because this decision falsifies it.**
That route's shipped instruction is to run the interview using the template's own guide as the
script. Once the conduct lands in the verb's own section, the script is that section, and the `**Reads:**` line's declaration of
`templates/traveler-intake.template.md` as *the interview script on route 1* is false. The repair is
a **declaration edit and not a comment**: `CLAUDE.md` § *Step 1* states that the single source for a
verb's entry class is the verb's own section, whose `**Reads:**` block has to declare each of writes
nothing, dispatches no agent, and performs no act whose effect lands outside the trip's own files,
and that the boundary is fail-closed.

**Route 1 runs the conduct inline and dispatches nothing.** Dispatching the new verb by `Task` would
falsify *Dispatches no agent.* as well, and an agent dispatch for a conversation buys nothing. The
inline form keeps both declarations true.

**D1.4 — The grant set the decided surface requires is `{Read, Write, Edit}`, and the grant union is
unchanged.** Read live from the five shipped `allowed-tools` frontmatter blocks at `edadfa9`:
`trip` holds `Read`, `Task`, `Edit`, `Write` beside its `Bash` grants; `trip-new` holds `Read` and
`Write`; `trip-record` holds `Read`, `Write`, `Edit` and `Task` beside its `Bash` grants;
`trip-publish` holds `Bash` grants alone; `trip-decommission` holds `Read` and `Edit` beside its
`Bash` grants. `{Read, Write, Edit}` is a subset of `trip-record`'s own set, and `trip-record` is a
member of the union, so the union is unchanged. **The verb adds no `allowed-tools` line at all**,
which is a stronger claim than adding one inside the union. The five sets differ from one another,
so the read is not returning one repeated value.

**D1.5 — The relationship to the single-trip-skill privilege record is *independent of its
outcome*, and D1.4 is why.** That record bounds a grant union. This decision changes no grant on any
surface, so its correctness does not turn on whether the shipped skills become one or stay as they
are. The independence is demonstrated rather than asserted: the same subset relation holds under
either topology.

### 2. The form contract

**D2.1 — A form is interviewable if and only if it carries, above its boundary, exactly one fenced
`intake-form` block declaring the keys below — and nothing else new.** Everything else the
interviewer needs is read from the form's own markup, or from a home that already exists and is
**named, never copied**.

```intake-form
form: templates/traveler-intake.template.md
form-version: 1
writer: human
boundary: <!-- PROFILE-END -->
classification: reference/data-model.md § Field Scope → The classification
output: travelers/<traveler>.md
```

**The boundary is borne by two literals, and this contract names which one is normative.** Both
shipped forms carry them on consecutive lines: a line-initial heading,
`# END OF PROFILE — the guide below is not part of your profile`, and immediately beneath it the
HTML comment `<!-- PROFILE-END -->`. **`boundary:` names the comment, and the comment is the
normative literal.** The ground is measured rather than stylistic: at `edadfa9` the heading literal
occurs **twice** in each guided form — once as the heading, once inside that form's own hand-off
instruction, which names it in prose — while the comment occurs **once**. The heading literal
therefore cannot satisfy D2.6 question 2 and the comment can.

**The heading is not thereby demoted to decoration, and the record accounts for it because it is
load-bearing to a different consumer.** It is the human-facing rendering of the same boundary, and it
is the literal the skill surfaces match **line-initially**: probed at `edadfa9`,
`skills/trip-record/SKILL.md` carries three such sites and `skills/trip-new/SKILL.md` one, while
`reference/data-model.md`'s denominator rule reads the comment instead. **Today the two agree only
by adjacency, and nothing asserts it**: no script reads either literal (probed over the tracked tree
at `edadfa9`; the control token `ANSWERED(` is read by `scripts/test-artifact-schema.sh`, so scripts
*are* being read by the same instrument). D2.6 question 2 is what converts that adjacency into an
assertion, and D5.6 is what runs it.

*Rejected:* retargeting `boundary:` at the heading literal — it occurs twice per form, so the
exactly-once test that makes the boundary decidable fails on both shipped forms. *Rejected:*
declaring the heading as a second fence key — it puts a second copy of a literal the form already
carries into the declaration, which D2.2 refuses, and it grows the per-form cost § *Decision* 6
exists to shrink. *Rejected:* leaving the heading unmentioned, which is the shape this clause
replaces — a contract silent on the literal the skill surfaces key on declares a boundary the engine
does not use.

**D2.2 — The declaration points; it never copies.** Every key above is either a fact about the form
itself or an address. `classification:` names the table and its section anchor; the table's own
columns are read live at invocation and are not restated in the fence, in the form, or in the skill.
`output:` names the `artifact:` string of the corresponding `reference/schemas/<class>.md` fence —
`travelers/<traveler>.md` for the trip form and `people/<person>.md` for the durable form — which is
simultaneously the artifact class's identity and its path rule.

**Two of the keys restate a value the form's own frontmatter already carries, and this record states
which wins rather than leaving it to a consumer.** Both shipped forms declare `writer: human` in
their frontmatter, and both declare the finished file's class there as `artifact:` —
`travelers/<traveler>.md` and `people/<person>.md`. The fence's `writer:` and `output:` name those
same two facts. **The frontmatter is authoritative for both, unconditionally.** Three grounds, in
descending weight: it is the surface `scripts/validate-artifacts.sh` actually reads, so a consumer
preferring the fence would branch on a value the gate does not grade; it is the **artifact class's**
own declaration, which D2.5 has already separated from the form contract's axis; and the form's own
text tells its reader the fence is not a field they fill in, which makes it the more stable of the
two. **A fence that disagrees with the frontmatter is a non-conforming form**, graded by D2.6
question 5 — it is never a value a consumer may adopt, and never a reason to read the two keys as a
second home for the fact.

*Rejected:* **(a)** dropping `writer:` and `output:` from the fence and making the reader parse the
frontmatter — the fence is the one block a form-agnostic reader is guaranteed to find, and these two
keys are what let it refuse an uninterviewable form (question 5) without a frontmatter parser.
**(b)** declaring the fence authoritative — it inverts the direction the shipped gate reads and
would let a form claim a writer class the validator never sees. **(c)** leaving the precedence
unstated, which is the shape this clause replaces: a second home for the same fact, with the
arbitration left to whichever consumer reaches it first.

*Rejected:* consolidating the existing homes into one declaration. It would restate the `Scope`,
`Class`, `Ovr?` and `Horizon` columns, creating a further home for values `reference/data-model.md`
owns and the live extractor groups already grade. The engine's own verdict on that shape is
`## profile`'s: *a second implementation of either predicate would be a second source of truth for
what a field is.*

**D2.3 — Per-field option text stays prose in the bracketed placeholder, and the placeholder is the
authoritative home.** This is the amendment the Collective Review assigned to this record, and it
has two limbs. The first: **the field's own bracketed placeholder is the single authoritative source
of option text for that field.** No other text in the form — not a section's guidance quote, not the
per-section ask-prose below the boundary, not a worked example — is an option source, and no
consumer may treat one as such.

The limb matters because option text occurs today in more than one non-identical rendering per
field. On the trip form the `Trip vibe` bullet's bracket carries `beach / city / nature / culture /
food / mix` and the guide's own step restates them as `beach, city, nature, culture, food, or a
mix`. Both renderings are present at `edadfa9`, above and below the sentinel respectively; a probe
that found the same tokens in both was validated against guide-only prose, which it correctly found
below and not above. **The authoritative-home decision is what makes a substring test against *the*
form decidable — it is not a rescue of a list that would otherwise be lost**, and the record says so
rather than carrying a more dramatic premise it cannot support.

*Rejected:* declaring option lists, archetype menus, examples and skip-ifs per field in a
machine-readable syntax. Measured over the labelled bullets above the boundaries at `edadfa9`, the
option renderings in use span at least three distinct shapes, and skip-ifs and examples are present
on most bullets. Declaring them costs an authoring pass over every bullet today and a further pass
per new form — the per-form cost § *Decision* 6 exists to shrink — and it creates a second copy of a
value the bracket already carries, for **no capability gain**: the bracket is read today by two
readers, the in-harness interviewer and the stranger's assistant, and the form itself says so
(*"The bracketed text in the file is a hint for you."*). One source, two readers.

**D2.4 — Each field carries a declared closed/open marker, and closedness is never inferred from the
option text's shape.** This is the amendment's second limb, and it is the one genuinely new
authoring obligation this contract creates. A field is marked **closed** when its option list is the
complete admissible set, and **open** when the list is suggestive and a value outside it is a
legitimate answer. The marker is per field, it is form-side, and it is what a consumer branching on
closedness reads.

**The syntax, declared here because a marker with no syntax is not a marker.** The marker is a bare
token — `closed` or `open` — written as the **head of that field's own bracketed placeholder**,
followed by a colon and a single space, with the existing hint text after it:

```
- ⭐ **Trip vibe:** [closed: beach / city / nature / culture / food / mix]
- **Specific:** [open: the allergy, the heat ceiling, the mobility limit]
```

**Four properties of that placement, each load-bearing.** It adds **no new surface**: the bracket is
the per-field home D2.3 has just made authoritative, so the marker lands in the home the contract
already names rather than opening a second one. It is **already delimited**, so a reader that can
find the placeholder can find the marker with no further parse rule. It **travels with the form** to
the no-repository reader of D4.1, needing no addition to the hand-off set. And it **leaves every
existing predicate true**: the value still begins with `[` and ends with `]`, so `CLAUDE.md`
§ *Resolving a trip*'s placeholder predicate is unchanged, an unfilled field still reads unanswered
to `ANSWERED()`, and a form's bracketed-placeholder form stays the thing it was — which matters
because the sibling record's un-asked test is a comparison against exactly that form.

**One parse rule follows and is stated rather than left to be inferred:** a consumer reading option
text per D2.3 takes the placeholder's contents **after** the marker and its `: ` separator. The
marker is metadata about the list; it is not a member of it, and no offer may quote it.

*Rejected for the syntax:* **(a)** a second bullet-level glyph beside the star — it would need a
home in the form's own legend, and `ST2` already turns on the difference between counting marked
fields and counting glyphs, so a second glyph puts weight on a discriminator that exists for another
purpose. **(b)** a per-field key in the `intake-form` fence — it is a per-field value in a per-form
declaration, so it grows linearly with the field count in the one place D6.1 exists to keep flat,
and it separates the marker from the list it describes. **(c)** a suffix after the closing bracket —
it sits outside the placeholder, so it is neither covered by the placeholder predicate nor carried
by a form whose reader deletes the hint.

**The ground is a measurement of the alternative, and the alternative failed.** A shape heuristic
over the shipped brackets — the obvious way to avoid a marker — does not discriminate. Run at
`edadfa9` over the labelled bullets above both boundaries, a classifier keyed on the shipped
renderings (`Exactly one of:`, `one of:`, a slash-separated list, a backticked alternation) put the
durable form's `Specific` field — a free-text must-have — inside the option-carrying set on an
incidental slash, and put `Lodging style`, whose bracket reads *Hotel, rental, or hostel*, outside
it. **Both errors, in both directions, on one run.** The prose is genuinely ambiguous rather than
merely unparsed: the trip form's `Group time` bracket reads *"e.g., one of:"*, which is an example
marker and a closure marker in the same phrase. **Whether a list is closed is a fact about the
field, not about the sentence, so no reader of the sentence can decide it.** A declared marker can.

*Rejected:* inferring closedness from the rendering (the measurement above); inferring it from the
classification table (the table carries class, scope and horizon, and closedness is none of them —
adding a column there would put an interview concern into a planning table, the defect
`reference/data-model.md` already records against reusing its sibling predicate); declaring a
closed set's members in the fence (a second copy of the bracket's text, which D2.3 exists to avoid).

**D2.5 — The contract is versioned on its own axis, by `form-version:`.** A skill and a form can
then disagree **detectably** rather than silently.

*Rejected:* versioning by the frontmatter's `schema-version:`. That key is the **artifact class's**
version — `reference/schemas/traveler-profile.md` declares it as a required integer for the class —
and the template's own text states that the fence is *not a field you fill in* and that its values
are facts about the artifact class rather than answers. Overloading it would make a form-contract
bump read as an artifact-class bump to `scripts/validate-artifacts.sh`.

**D2.6 — The conformance test is six decidable questions, and none requires reading the
interviewer.** A reader takes an arbitrary form and answers:

1. Exactly one `intake-form` fence occurs, above the boundary, carrying every declared key.
2. The literal named by `boundary:` occurs exactly once in the file, **and** the form's
   end-of-profile heading — the literal the skill surfaces match — occurs **line-initially** exactly
   once, on the line immediately above it. The second limb is what asserts the two literals'
   agreement; without it they agree only by adjacency, which is the state D2.1 records.
3. Every `- [⭐ ]**<Label>:**` bullet **above** the boundary joins to exactly one row of the table
   `classification:` names, on **`(section, label)`** — with the section resolved as a **leading
   segment** of the bullet's enclosing `##` heading, never by exact equality. **All three candidate
   readings were measured at `edadfa9`** over the labelled bullets above both boundaries, and the
   selection is the measurement rather than a preference:

   | Reading of the key | Trip form | Durable form | Both |
   |---|---|---|---|
   | Exact `(section, label)` — section equal to the whole heading | 11 of 19 | 14 of 17 | `25/36` |
   | **Leading-segment `(section, label)` — SELECTED** | **19 of 19** | **17 of 17** | **`36/36`** |
   | Label alone | 19 of 19 | 17 of 17 | `36/36` |

   **Exact equality fails because the forms' own `##` headings carry display suffixes the table's
   `Section` cell does not** — `Desires — what you want` against `Desires`, `Needs — the must-haves`
   against `Needs`, `People dynamics & togetherness` against `People dynamics`. Leading-segment
   matching absorbs the suffix. **It therefore costs nothing in coverage: it scores exactly what the
   label alone scores, while keeping the section dimension the label alone discards.**

   **The section dimension is retained because a label-only key mis-resolves as soon as one label is
   carried by more than one row, and the corpus already carries that collision.** Probed at
   `edadfa9`: `templates/trip-context.template.md` carries a pair of `Applies to` bullets under
   `## Hard Constraints`, while the classification table carries a single `Applies to`, in section
   `Needs`. Under the label-alone reading that form's `Applies to` joins the `Needs` row — a wrong
   answer returned confidently. Under leading-segment it joins nothing, which is the correct answer
   for an artifact this contract does not serve (D3.3).

   **This is the key the shipped arm `XT12` already requires**, in `scripts/test-artifact-schema.sh`
   group `XT`: that the `## extract` section state the key as `(section, label)` rather than the
   label alone, resolve the section as a leading segment, and carry the reason. `XT4` is its
   companion, and it is the arm that measures both candidate section readings differing on the
   shipped headings. **On today's table the label and the pair are extensionally equal** — probed at
   `edadfa9`, the table's labelled rows carry one distinct label each **and** one distinct
   `(section, label)` pair each, which is what `XT12` reports live rather than asserts. That equality
   is the reason to *state* the key rather than a reason the choice does not matter: a wrong key
   resolves identically today and would land as-built and stay invisible. **The contract, the seam
   (`F11`) and this measurement therefore name one join, and it is the join the suite grades.**
4. **No** `- **<Label>:**` bullet occurs **below** the boundary.
5. `writer:` is `human`, and no field is marked `[DERIVED]` or `[ENRICH]`; **and the fence's
   `writer:` and `output:` agree with the frontmatter they restate** — `writer:` with the
   frontmatter's own `writer:`, and `output:` with its `artifact:`. Per D2.2's precedence rule the
   frontmatter is authoritative, so a disagreement here is a non-conforming **form**, never a
   licence for a consumer to prefer the fence.
6. **Every field whose bracketed placeholder carries an option list carries exactly one closed/open
   marker, well-formed by D2.4's syntax.** The two halves of that sentence are graded differently,
   on purpose. **Well-formedness is machine-decidable**: the token is `closed` or `open`, it is the
   head of that bullet's own bracketed placeholder, it is followed by `: `, and no bullet carries
   two. **Whether a given field owes a marker at all is the reviewer's judgement and not the
   machine's**, because deciding it mechanically needs precisely the shape heuristic D2.4 measured
   and rejected — a contract that graded it would be asserting the classifier it just refused.
   The conformance arm D5.6 adds grades the decidable half; the other half is named as `R11`
   rather than claimed.

Question 3 is one-directional by design: a classified row that renders as no bullet is conformant,
because the rows that ship today for exactly that case are the title-line `Name` and the computed
`Applies to`, which the data model's own denominator rule already reconciles as fields that are not
bullets.

Applied to the tree at `edadfa9`, the two guided forms satisfy questions 2 through 5 and fail
questions 1 and 6 — **both for the same reason, and it is not a defect in the forms**: the fence and
the markers are the authoring D3.1 and D3.2 add, and neither is in the tree yet.
`templates/trip-context.template.md` fails questions 1, 2, 3, 5 and 6.

**D2.7 — Why a fenced block, and not frontmatter or an HTML comment.** The custom fence info-string
is the engine's shipped idiom for machine-readable declaration inside prose, used across the tracked
markdown corpus in several distinct tags at `edadfa9` — `artifact-entry`, `artifact-schema`,
`trip-contract-header`, `trip-contract-evidence`, `archived-erasure-witness`,
`publish-contract-values`, `publish-contract-artifacts`, `frozen-witness-digest`,
`count-assertion-digest` and `horizon-verdict-cases`. Frontmatter is closed by the form's own text.
The HTML-comment region has a single precedent and carries the suppression hazard named under
§ *Options considered*.

### 3. Standardizing the shipped forms

**D3.1 — `templates/traveler-intake.template.md`.** Add the `intake-form` fence above the boundary.
Add the per-field closed/open marker. **Delete** the per-section `Fields: …` restatement lines and
the rule-4 numeral. **Delete** the numbered conduct rules and the *producing the finished file*
block, which move to the verb. **Keep** the per-section ask-prose, the archetype menu, the banner
numeral, the boundary and the worked-example pointer. **Keep** the *Filling this out with an
assistant* paste-line, retargeted from *the guide at the bottom of the file* to the portable card
that now travels with the form.

**D3.2 — `templates/person-intake.template.md`.** The identical treatment. The form-specific conduct
**stays**, because it is about *these* fields and has no other home: the *Before Step 1 — their
name* instruction, the cross-trip warning, the `Passport` narrowing rule, and the rule that this
form's needs block answers with a word rather than an em dash.

**D3.3 — `templates/trip-context.template.md` is out of scope for this epic and is named the first
consumer after it.** The ground is measured and it is a misclassification by **kind**, not by size.
Probed at `edadfa9`: its frontmatter declares `writer: block-owned` rather than `writer: human`; a
substantial minority of its bullets sit under a `[DERIVED]` or `[ENRICH]` heading and are
agent-owned, so interviewing a traveller for them would be a category error; and **not one of its
distinct labels joins** `reference/data-model.md`'s classification table under the key D2.6
question 3 selects. The control arm on the same join, same instrument, is total agreement for both
guided forms: every label of each joins. **The one apparent join is exactly what that key exists to
refuse** — under the rejected label-alone reading this form's `Applies to` bullets resolve to the
table's `Needs` row, which is a name collision and not a match; the leading-segment key reads the
enclosing `## Hard Constraints` heading and correctly joins nothing. It is not an unserved *form*;
it is a multi-writer trip artifact that shares a markup shape with a form.

**Its entry price, stated so the deferral is a decision rather than an omission.** A classification
row per new label, which for this artifact is nearly every label it carries; a **writer partition**
added to this contract, because its bullets are not uniformly human-owned and D2.6 question 5
refuses it as written; a boundary sentinel, which it does not carry; and a starred pass, which it
does not have — its star count is nil, against non-zero counts on both guided forms by the same
probe. Its repeated `## Hard Constraints ### [Constraint Name]` units are a block shape with no
`block`-scope declaration behind them.

*Rejected:* bringing it into this epic. Growing the contract's writer partition for a third form
before the first two are conformant inverts the order the milestone set, and the partition would be
authored against **no** conformant consumer.

**D3.4 — The retired lines are deleted, not relocated.** The `Fields:` restatement is a per-field
restatement of bullets that sit a short distance above it in the same file, it is `ST`'s drifting
home *because* it drifts, and its only reader is the conduct that is leaving. Keeping it keeps a
home with no reader and a gate that must keep grading it.

*Rejected:* moving the per-section ask-prose to the verb with the rules. The ask-prose is
form-specific and would then be authored in a file that does not carry the fields it names — the
drift the split exists to remove, relocated rather than removed.

### 4. Projection to the no-repository reader

**D4.1 — Route 3's hand-off set gains the portable card, and this record names the whole set the
recipient receives.** Named as a list, which is what the acceptance criterion asks for:

1. **the form itself** — `templates/traveler-intake.template.md` or
   `templates/person-intake.template.md`;
2. **the worked example** — `examples/people-library-demo/travelers/noor.md` for the trip form; the
   durable form gains its own worked record, `examples/people-library-demo/people/psn-3c7e.md`,
   which has no hand-off route today because the durable form has no verb;
3. **the portable interview card** — a new tracked engine asset, form-agnostic, carrying the
   numbered conduct rules and the output contract and nothing form-specific.

**D4.2 — The recipient receives files, not paths.** That is already how route 3 works, and it is why
`ADR-021`'s installable posture does not break it: the recipient never resolves an engine path. The
form's own sentence about the worked example — that the path will not open if the file reached them
alone, and to ask whoever sent it — is unchanged and now covers the card as well.

**D4.3 — Route 3 continues to work, and the record states why rather than asserting it.** The
recipient holds the questions and their hints (the form), the conduct (the card) and a filled
comparison (the example). The paste-line is retargeted to name the card. Nothing in the hand-off
resolves into the repository, and nothing in it is a restatement of anything in the repository:
the card is the **authored** home for conduct, not a copy of one.

*Rejected:* the declared derived region, on the weighted grounds under § *Options considered*;
assembling the hand-off at invocation, which leaves nothing tracked and therefore nothing asserting
the agreement, and gives a traveller who received the form by any other route a form with no
conduct; splitting the conduct between form and skill, which is a second home and therefore the defect;
and handing over the `SKILL.md`, which carries grant declarations and command contracts and is not a
document for a stranger.

### 5. The assertion surface after the move

**D5.1 — Group `ST`'s homes reduce from four to two, and the reduction is by retirement rather than
relocation.** The workflow comment names the four: the banner numeral, the appendix rule-4 numeral,
the appendix's per-field annotations, and the marked fields themselves. After this record the marked
fields and the banner numeral remain — `4 − 2 = 2` — and the two below the boundary are gone,
because rule 4 moves to the form-agnostic card, which carries no per-form numeral, and the
annotations have no reader.

**D5.2 — The interviewer *reads* the starred set and restates it nowhere.** No further home is
created. This is the decision the card's own framing offered as a binary — read or restate — and the
measurement supplies a third move that the binary does not contain: **retire the restatements that
already exist.**

**D5.3 — `ST0`'s fail-on-empty posture is preserved verbatim, over the reduced surface.** It grades
a smaller number of non-empty surfaces and still has no legitimate skip. `ST1`'s multi-home
agreement becomes an agreement between the marked count and the banner numeral. `ST2` is unaffected,
because the banner still carries the glyph.

**D5.4 — The arms and the branches come out together, in one commit, and `ST-COV` is the forcing
function.** The must-fire arm for the empty-annotation case and the annotation and label-order
branches of `st_violations` are removed as one act, because `ST-COV` fails when any code
`st_violations` can emit has no must-fire arm. Removing the arms without the branches turns the
suite red; removing the branches without the arms turns it red the other way.

**D5.5 — A new must-fire arm converts the incidental zero into an asserted one.** The arm inserts a
`- **Label:**` line below the boundary and requires the refusal to fire. `rl_bullets` gains a
boundary stop, and it is **fail-closed**: a form carrying the `intake-form` fence whose `boundary:`
literal is absent is a failure, never a whole-file fallback. This is the clause that discharges the
leak the context section names, and it is written to require evidence its subject could only have
produced by running, per [`ADR-019`](ADR-019-discriminating-evidence-rule.md).

**D5.6 — A second new arm grades contract conformance** — D2.6's six questions, over `ST_TEMPLATES`,
taking question 6 at its decidable half per that question's own statement.
It lands in `ST` and **not** in `scripts/validate-artifacts.sh`, because that validator's selector
excludes `templates/*.template.md` ahead of both of its arms, so a conformance check placed there
would never reach a form.

*Rejected:* relocating the annotations into the verb and widening `ST` to grade across a file boundary. It
preserves a per-field restatement whose reader has gone, converts an intra-file agreement into a
cross-file one — a strictly harder probe — and, decisively, the restatement would then be authored
in a file that does not contain the fields it names. *Rejected:* dropping `ST` once conduct leaves.
The marked set and the banner numeral still restate one fact to each other, the banner is still
hand-maintained, and `ST` is the arm that catches a star added without the banner following.
*Rejected:* keeping `rl_bullets` whole-file and relying on the measured zero, for the reason
D2.6 question 4 exists.

### 6. The cost of the next form

**D6.1 — What a fourth interviewable form costs, in the units this contract creates.** This is the
claim the record is for.

| Unit | Cost of the next form |
|---|---|
| `intake-form` fence | one block, with every declared key |
| Closed/open markers | one per field that carries an option list |
| Rows in `reference/data-model.md`'s classification table | one per new label — the irreducible cost, and it is the data model's, not this contract's |
| Per-section ask-prose | a sentence or three per section, authored in the form beside the fields |
| Numbered conduct rules | none |
| Output contract | none |
| `Fields:` restatement | none — retired |
| Star-count homes to keep in agreement | two, both in the form, both graded |
| `ST_TEMPLATES` | one line |
| The form lists of the other form-reading groups | one line each, where the form participates |
| Hand-off artifacts | none — the card is form-agnostic |
| Command surface | none if it reuses the interview verb; otherwise one requirement row, one Step-1 taxonomy row, and a regeneration of the command-reference derived region |
| Install or link changes | none |
| `README.md` loops | none |

**D6.2 — What a form costs today, for comparison.** A third guided form costs a hand-written conduct
appendix of roughly the length each shipped guide already carries, the whole `ST` home set to keep in
agreement rather than the reduced one, a re-pin of the `count-assertion-digest` row for the file,
and a further `ST_TEMPLATES` member grading every one of its homes.

**D6.3 — The honest residual, stated because a claim that hid it would be false.** **This contract
makes conduct free and leaves classification exactly as expensive as it was.** Nothing here removes
a classification row, and for a `trip-context`-shaped artifact that is a row for nearly every label
it carries. *A form costs a form* is true of the conduct and false of the data model, and the record
says which half it earned.

## The seam — every datum a conforming form exposes

**Per the seam statement's first clause: the enumerated list of every datum a conforming form is
required to expose, and the form in which it is expressed.** This is the **supply** side. The
sibling record states the **demand** side as its own enumerated list of what a session must read.
**The cross-walk that joins them is authored at S2 and is not authored here**, and this record
neither quotes nor predicts a clause of the sibling.

**A note on the numbering, because it is a reference the gates already cite.** `F1` through `F16`
carry the numbering and the semantics the Stage-5 design gave them, and the Stage-5 and Collective
Review dispositions cite several of them by number. The data this record adds are **appended** as
`F17` onward rather than interleaved, so that every existing citation still resolves to what it
meant.

**Declared in the fence.** Nothing here is copied from another home; each key is a fact about the
form or an address.

| # | Datum a conforming form exposes | Expressed as |
|---|---|---|
| **F1** | the form's own identity | `form:` — a repo-relative path |
| **F2** | the contract version the form was authored against | `form-version:` — an integer, so a skill and a form disagree detectably |
| **F3** | the writer class of the form's fields | `writer:` — `human`; a form carrying any `[DERIVED]`/`[ENRICH]` field is not interviewable |
| **F4** | where the profile half ends | `boundary:` — the **normative** sentinel literal, occurring exactly once. The form bears the same boundary a second time as the line-initial end-of-profile **heading** immediately above it — the literal the skill surfaces match, and the reason D2.1 names one of the two normative rather than swapping between them. The heading is **not** a fence key; D2.6 question 2 grades it against the sentinel |
| **F5** | which label-to-metadata table the form is keyed against | `classification:` — a path and a section anchor; **the table is not copied** |
| **F6** | the artifact class the finished file becomes, and its path rule | `output:` — the `artifact:` string of the corresponding `reference/schemas/<class>.md` fence, which is simultaneously the class identity and the path pattern |

**Read from the form's own markup above the boundary.** Every one of these is present in both
shipped forms at `edadfa9`; none is new authoring, and the contract's cost here is nil.

| # | Datum a conforming form exposes | Expressed as |
|---|---|---|
| **F7** | the ordered section list | `## ` headings above `F4`, in document order |
| **F8** | the ordered field list, with labels byte-exact | `- [⭐ ]**<Label>:**` bullets above `F4`, in document order |
| **F9** | which fields are starred | the `⭐` immediately after the bullet marker |
| **F10** | how many fields are starred | the banner numeral above `F4` — one prose home, graded against `F9` |
| **F14** | per-field hint — options, archetype menu, example, skip-if | the field's own bracketed placeholder, and the section's guidance quote, **as prose**. Per D2.3 the **placeholder is the authoritative home for option text**; nothing else in the form is an option source |
| **F15** | the unanswered / word-answer / em-dash distinction as the form states it | the guidance quotes above `F4`, and the per-field placeholder |
| **F17** | **per-field closedness** — whether the option list is the complete admissible set or a suggestion | the declared closed/open marker of D2.4. **This is the contract's one new authoring obligation**, and it is declared rather than inferred because D2.4's measurement shows the rendering cannot decide it |
| **F18** | the **title-line field** — a field borne by the H1 and by no bullet | the form's own title line, plus its classification row, which the denominator rule already reconciles as a field that is not a bullet. Invisible to any bullet-derived read of `F8`, and named separately for that reason |
| **F19** | **block cardinality as the form ships it** — the repeat units a seeded copy starts with | the repeated bullet groups above `F4`, in document order, read as `F8` renders them |
| **F20** | the **frontmatter block**, and which of its values are substituted when a copy is seeded versus fixed facts about the artifact class | the form's own frontmatter, plus the form's own instruction about it — the trip form directs its reader to replace the trip placeholder and leave the rest; the durable form directs its reader to leave the fence exactly as it stands |
| **F21** | the **artifact stem transform** — how the saved filename is derived | the form's own *How to use it* prose above `F4`: the trip form states the slugification of the roster name; the durable form states that the filename carries a minted id while the title line carries the name |

**Not exposed by the form. The form names where they live and never copies them.**

| # | Datum | Where it lives |
|---|---|---|
| **F11** | per-field cardinality — `slot` against `block` | the `Scope` column of the `F5` table, joined on **`(section, label)`** with the section read as a **leading segment** of the bullet's enclosing `##` heading — the one key D2.6 question 3 selects and `XT12` grades |
| **F12** | per-field class, overridability and horizon | the `Class`, `Ovr?` and `Horizon` columns of the same table, reached by the same `F11` join |
| **F13** | which fields are never asked | that table's *never asked — computed* rationale |
| **F16** | where the finished file is saved, and the write step | the output contract, in the verb and on the portable card, parameterised by `F6` and `F21` |

**Three properties of this list that matter to a consumer.**

- **`F11` through `F13` and `F16` are deliberately not form-exposed**, and that exclusion stands. A
  requirement for cardinality, class, horizon or the never-asked set is satisfied by the `F5` join,
  **not** by a new form declaration. Adding one would create the second source of truth D2.2
  refuses.
- **`F4` is the only datum whose status changes, and it changes in both of the literals that
  carry it.** The boundary exists today — normative in the denominator rule as the comment, matched
  line-initially as the heading by the skill surfaces D2.1 names — and **no script reads either
  literal.** After this record the comment is declared in the fence, read by the extractors, and
  graded fail-closed, and the heading is graded **against** it by D2.6 question 2. Neither literal
  is new authoring: both ship in both guided forms today.
- **`F17` is the only datum that costs new authoring.** Everything else is either a key in one new
  fence or a line the shipped forms already carry.

**The prose-grade residual, named so that a green is not read as more than it is.** `F14`, `F15`,
`F18`, `F20` and `F21` are prose read by a language model. Nothing grades that a hint's options were
offered, that a skip-if was honoured, or that a stem transform was applied. The contract makes those
data **locatable and single-homed**; it does not make them **asserted**. That is a non-goal of this
record and it is stated on `ADR-013`'s own model rather than left for a reader to discover.

## Consequences

### What this buys, stated as the surfaces it leaves untouched

- **No new artifact class, no new schema member, no new lifecycle and no new publish posture.** The
  contract is a fence inside files that already exist and a card that is a document rather than an
  artifact instance.
- **No new grant, on any surface.** D1.4 shows the union unchanged under either privilege topology.
- **No change to `reference/data-model.md`'s denominator.** The retired lines sit **below** the
  boundary and are not profile-half bullets, so the reconciliation that rule performs is unchanged
  by this record. Confirm at development testing rather than assuming it.
- **No branch-protection change.** The new arms land inside `ST`, which blocks from inside the
  existing required check by design.

### What later slices must change, each with an owner

| Change | Owner |
|---|---|
| The conduct extraction itself — the fence in, the rules and restatements out, `ST` re-grounded, the digest row re-pinned | **Wave 1**, and it is **one commit**: `ST0` fails on an empty surface and `ST-COV` fails on an unarmed branch, so the removal, the re-grounding and the re-pin cannot be sequenced apart without a red required check between them |
| `## profile` route 1's repair, per D1.3 | **Wave 1**, in the same act as the extraction that falsifies it |
| The CI workflow comment that spells out `ST`'s four homes — a fifth restatement, ungraded, and false the moment D5.1 lands | **Wave 1**, same commit |
| The command-reference derived region, which a new verb changes | **Wave 1** — one regeneration and a paste, with no skip path |
| The durable form's Step-1 taxonomy row | **Wave 1** — see R5 |

### Two facts a small-looking change would hide

**The extraction is not a documentation edit.** Removing the guide empties an `ST` surface whose
group declares it has no legitimate skip, and `ST` sits inside a required status check. The change
is a suite change with a documentation face.

**The boundary's cleanliness is being converted, not preserved.** Today no labelled bullet sits below
either sentinel, and nothing says it must stay that way. D5.5 is what makes that a property of the
contract rather than of the current authors' habits, and it is the reason the boundary stop is
fail-closed rather than falling back to a whole-file read.

### Reversibility summary

**CHEAP.** This record is a decision document: it moves no artifact, changes no script, and is
revertible in one commit. The slices it authorizes are not — the extraction touches a required check
and is **MODERATE** — and this record decides none of their sequencing beyond naming the one-commit
coupling above. **Confidence: HIGH** on D1, D3, D4, D5 and D6, each resting on a live measurement
with a firing control arm. **MEDIUM** on D2.3's rejection of declared option lists, which rests on
the judgement that a reader of the bracket suffices rather than on a measurement of one — and which
is the single decision here a Wave-1 spike could falsify.

## Residuals

Every residual is named with its owner. A residual with no owner is not a residual; it is a gap.

| # | Residual | Owner |
|---|---|---|
| **R1** | **`F14`, `F15`, `F18`, `F20` and `F21` stay prose, and nothing grades that a hint was offered or a transform applied.** Accepted, and stated as a non-goal rather than deferred work | **accepted**, stated by § *The seam* |
| **R2** | **The *skill plus form* constraint was held with its cost known.** A reference document cited live at invocation is the cheapest home for conduct and matches the idiom `## profile` already uses; it is foreclosed by the constraint and not by merit, and the constraint makes one verb section the de-facto conduct library, which will read oddly at the third caller | **operator**, at milestone scope |
| **R3** | `form-version:` disagreement is **detectable** and nothing acts on it in Wave 0 | **Wave 1**, the extraction slice |
| **R4** | The `Proposed` → `Accepted` flip moves this record's `Status:` line and its index cell, and no check grades either half or their agreement | **operator**, at milestone close |
| **R5** | **The durable form's command route needs a `CLAUDE.md` Step-1 taxonomy disposition that nobody has scoped.** `ADR-007` § 3's coverage identity requires every unit of the command surface to be covered by exactly one addressed row, and the shipped **Traveler profile** row addresses a traveller's own profile rather than a durable person record. Whether the new verb takes a new addressed row or joins the existing *whose answers* ambiguity set is a taxonomy call this record does not own. **This record edits no file but its own** | **Wave 1**, owner assigned at Wave-1 planning |
| **R6** | `templates/trip-context.template.md` remains uninterviewable, so **the contract ships unexercised on the artifact the scalability claim is usually argued from.** Its entry price is on record under D3.3 | **the first consumer slice, after this epic** |
| **R7** | The portable interview card is a **new tracked asset with no schema class** — it is a document rather than an artifact instance, and the class enumeration does not grow for it | **Wave 1**, stated here so the absence is a decision |
| **R8** | **The split of the guides' numbered rules is a joint act.** This record relocates the block and decides where it lands; the sibling governs the semantics of the rules it names. **Neither half is complete alone**, and this record states nothing about those semantics | **joint**, this milestone |
| **R9** | The `intake-form` fence is **not** graded by `scripts/validate-artifacts.sh`, whose selector excludes the templates ahead of both arms. D5.6 puts the conformance arm in `ST` instead, and this row exists so the validator's silence is read as a routing decision rather than as coverage | **Wave 1**, the extraction slice |
| **R10** | **The join key's own uniqueness is unasserted.** D2.6 question 3 requires each bullet to join *exactly one* row, and that totality holds today only because the classification table's labelled rows carry one distinct label each and one distinct `(section, label)` pair each — measured at `edadfa9` and reported live by `XT12`, but **required by nothing**. A row added with a duplicate label breaks nothing under the selected leading-segment key so long as the sections differ, and a row added with a duplicate pair breaks question 3 silently. The table's own *Totals* sentence reconciles class, scope and horizon against the row count and says nothing about key uniqueness. Closing it is one arm over `F5`, and it belongs beside D5.6's rather than in this record | **Wave 1**, the extraction slice |
| **R11** | **Question 6's undecidable half: whether a field that *ought* to carry a closed/open marker has one.** D2.4's measurement rules out deciding it from the option text's shape, so the conformance test grades well-formedness and leaves the obligation to a reviewer. The failure it admits is **fail-safe in the cheap direction** — an unmarked closed field is treated as open, so the interviewer records what was said rather than refusing a legitimate answer, which is the inverse and worse error. Named here so the asymmetry is a decision rather than an oversight | **Wave 1**, the extraction slice, with the marker authoring |
| **R12** | **D2.3's rejection of declared option lists is the one MEDIUM-confidence decision in this record**, and § *Reversibility summary* says a Wave-1 spike could falsify it. It rests on the judgement that a reader of the bracket suffices rather than on a measurement of one. Until that spike runs, the single-authoritative-home limb of D2.3 is a decision taken on judgement while every other decision here rests on a live measurement with a firing control arm | **Wave 1**, as a spike before the extraction slice commits to the bracket |
| **R13** | **The contract makes conduct free and leaves classification exactly as expensive as it was.** D6.3 states it; no row owned it. For a `trip-context`-shaped artifact the entry price is a classification row for nearly every label it carries, and that cost is the data model's rather than this contract's — which is a statement about *whose* cost it is, never a statement that it has been reduced. **The scalability claim this record makes is therefore about conduct alone**, and a reader comparing D6.1 against D6.2 should read it that narrowly | **accepted**, stated by D6.3; the data model's own, if anyone reduces it |

## References

- [ADR-006](ADR-006-third-party-data-capture.md), [ADR-012](ADR-012-people-library.md),
  [ADR-015](ADR-015-durable-field-validity-horizon.md) — cited to **mark the boundary** rather than
  to decide inside it: third-party capture, the person store's identity and erasure reach, and the
  validity horizon are the sibling record's territory and this record's contract leaves all three
  untouched
- [ADR-007](ADR-007-command-entry-point.md) § 3 — taxonomy ownership and the coverage identity, which
  is why a new verb owes a Step-1 row and why R5 exists
- [ADR-013](ADR-013-count-assertion-basis.md) — the admitted basis forms that govern how every count
  in this record is written, the derived-region option it rejected as a standalone, and the
  non-dereference boundary that makes a look-alike opener a silent suppression
- [ADR-019](ADR-019-discriminating-evidence-rule.md) — the standard D5.5's new arm is written to, so
  that it requires evidence its subject could only have produced by running
- [ADR-021](ADR-021-installable-capability.md) § 1 — the engine is installed, links are per verb, and
  the checkout is not the invocation surface, which is why D4.2's hand-off of files rather than
  paths survives it; and the two-location status-flip obligation this record's head block reuses
- [ADR-022](ADR-022-interview-session-model.md) — the sibling Wave-0 record. It decides **behaviour
  over time**: lifecycle, resumption, write cadence, sequencing, who is interviewed, conversational
  integrity and modality. It states the **demand** side of the seam; § *The seam* here states the
  **supply** side. **No clause of it is quoted or predicted here**
- [`README.md`](README.md) — the record convention, the status lifecycle, the file-name grammar, and
  the amendment-versus-supersession split this record's head block is authored against
- `reference/data-model.md` § *Field Scope* — `F5`'s target: § *The denominator* for the rule that
  already reconciles a field that is not a bullet, which is what makes D2.6 question 3
  one-directional and `F18` expressible; § *The classification* for `F11` through `F13`, read live
  and **never restated**; § *The starred pass*; and § *`ANSWERED()`* for the instance-against-document
  distinction this contract governs only the document half of
- `reference/data-architecture.md` § 10 `count-assertion-digest` — the declaring fence whose rows the
  extraction slice re-pins, asserted in both directions so a path that loses an assertion fails as
  loudly as one that gains one
- `reference/schemas/traveler-profile.md`, `reference/schemas/person-record.md` — `F6`'s targets, and
  the `schema-version:` declaration that D2.5 declines to overload
- `reference/command-reference.md` — the corpus's one declared derived region, cited **both** as the
  precedent that made the candidate worth weighing and as the contrast that defeated it: it states
  that nothing in it is maintained by hand except the prose, which is the opposite of a form its own
  text invites its reader to delete
- `scripts/test-artifact-schema.sh` — group `ST`, its `ST_TEMPLATES` membership, its surface
  discovery and its coverage arm; `rl_bullets`, which D5.5 gives a boundary stop; and the other
  form-reading groups whose lists a new form joins
- `scripts/test-corpus-hygiene.sh` — the derived-region recogniser behind the suppression hazard, and
  the bidirectional comparison against the declaring fence
- `scripts/validate-artifacts.sh` — the template exclusion that routes D5.6's conformance arm into
  `ST` rather than into the validator, which is R9
- `scripts/test-command-taxonomy.sh` — the directory-wide command discovery that denies a *library
  skill* shape and so disqualifies the new-skill option a second time
- `skills/trip-record/SKILL.md` — § *How this file is extended* for the zone rule, the enumerated
  permitted additions and the repair extension point, which together select D1.1's landing site;
  § *What the blocks above are* for the `**Reads:**` declaration D1.3 repairs; and `## profile` for
  the three create routes, for route 1's falsified script sentence, and for the live-read discipline
  this contract's `classification:` key extends rather than replaces; and, with
  `skills/trip-new/SKILL.md`, as the surfaces that match the boundary's **heading** literal
  line-initially rather than its comment — the asymmetry D2.1 names and D2.6 question 2 asserts
- `templates/traveler-intake.template.md`, `templates/person-intake.template.md` — cited as the
  authority on their own questions, their own option text, their own frontmatter instruction and
  their own stem transform. **Not restated**
- `CLAUDE.md` § *Step 1: Classify the request* — the **Traveler profile** row and the *whose answers*
  ambiguity set, which are the surfaces R5 routes to
- `.github/workflows/artifact-schema.yml` — the comment that enumerates `ST`'s homes, which is a
  further restatement, is graded by nothing, and is false the moment D5.1 lands
- `README.md` at the repository root — the install loop that names the shipped verbs literally, the
  uninstall loop that repeats them, and the two sentences stating that updating is a `git pull`,
  which together ground the new-skill rejection

## Follow-on build slices

Named, and deliberately not scoped. Scoping is Wave-1 planning's.

- **The extraction slice.** The fence in, the closed/open markers in, the rules and the restatements
  out, `ST` re-grounded, the workflow comment amended and the digest rows re-pinned — as **one
  commit**, for the reason D5.4 and § *Consequences* both state.
- **The conduct slice.** Authors the interviewer's conduct into the landing site D1.1 names, against
  the structure this record decides and the behaviour the sibling decides.
- **The portable card.** Authors the hand-off asset D4.1 adds, and retargets both forms' paste-lines
  at it.
- **The taxonomy slice.** Carries R5 — the durable form's Step-1 disposition and the requirement row
  the new verb owes.
- **The first `trip-context` consumer.** Carries R6, and is the slice at which this contract first
  meets the artifact it was deferred from.
