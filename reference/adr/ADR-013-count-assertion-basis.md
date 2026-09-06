# ADR-013: Count assertions carry a re-derivable basis

- **Status:** Accepted (2026-09-06)
- **Deciders:** repo maintainer
- **Driving work:** the corpus-hygiene fast-follows milestone. This record ratifies the
  authoring convention that milestone's count-assertion gate enforces. The gate is an
  implementation of the convention and is not itself the decision — enforcing an unwritten
  rule is how a gate acquires a reputation for arbitrariness, and this record exists so the
  rule is written before it is enforced.

## Context

**A count written into prose is a claim about a population, and the population moves.** The
sentence stays where it is. Everything that made the number true happens somewhere else — a
file is added, a row is dropped, a section is split — and nothing about that edit brings the
reader back to the sentence. The claim does not decay gracefully; it stays confidently
wrong, and it reads as authoritative for exactly as long as nobody re-derives it.

**This is not a hypothetical failure and it is not rare here.** A prior milestone existed to
remove instances of it, and the defect recurred *inside the work of removing it*, repeatedly
and in every kind of surface the repository has: an architecture decision record whose
amendment invalidated its own claim in the sentence that made it, a test suite that gained
stale roster counts in the commit that fixed one, a CI workflow comment that acquired one in
a block which twice forbids exactly this, and release briefing material that framed a live
defect as a closed one. Every instance was caught by a person reading. None was caught by a
gate, and every one of them passed the repository's required checks green.

**The corpus already states the rule, in one place, and already obeys it in several.**
`reference/data-model.md` puts it plainly:

> **The denominator is stated as a rule, not as a number.** A literal count in prose goes
> stale the first time a form gains or drops a line; the rule above does not.

That statement is scoped to one document's field denominator. The repository nonetheless
implements the same idea in unconnected places — the starred-field agreement group and the
class-assignment agreement group in `scripts/test-artifact-schema.sh`, and the
`command-surface: derived` region in `reference/command-reference.md` that
`scripts/test-command-taxonomy.sh` regenerates. What is missing is not the idea. It is a
statement of the idea at corpus scope, and a machine that reads it.

**The unit of the defect is not the numeral.** This is the load-bearing observation, and
getting it wrong produces a gate that is worse than none. A detector that flags cardinals
governing countable nouns finds, in this corpus, mostly grammar: the determiners `no` and
`one` carry the bulk of its hits, and *"it dispatches **no** agent"* and *"**one** row per
key"* are rules rather than censuses. Worse, such a detector turns red on content that is
**correct**: `reference/adr/ADR-010-per-traveler-approval-collection.md` asserts a
tracked-file count that the live tree has since grown past, and it is right, because the
same sentence names the commit it was probed at. A gate that reports a sound sentence as a
defect trains contributors to reach for the exemption marker, which is how a gate becomes
decorative.

**What separates the sound sentence from the rotting one is whether a reader can re-derive
the number without trusting the author.** That property is machine-checkable. The count is
not the problem; the missing basis is.

## Decision drivers

- **The number must be recoverable by someone who does not trust it.** A reader who doubts a
  count needs a stated route to checking it — a commit to probe at, a region that regenerates,
  an arithmetic identity, or a declared population several homes agree on.
- **Correct content must not be flagged.** An anchored measurement and a past-tense claim are
  both sound and both look exactly like the defect to a numeral-matching probe.
- **The rule must bind prose that no schema reaches.** Every enforcement surface this
  repository already has constrains frontmatter, a declared marker, or a generated region.
  The recurrences all happened in narrative body text, which none of them adjudicate.
- **A convention nobody wrote down cannot be enforced fairly.** The remedy applied in the
  prior milestone was to delete numerals rather than update them, which is a repair and not a
  rule — it leaves the next author with no statement of what is permitted.
- **The residual must be declared rather than exempted.** Whatever the corpus already carries
  has to be visible and asserted, because the recurrences were overwhelmingly *second*
  instances inside documents that already had one.

## Options considered

**(1) Forbid a count in prose outright.** Simple to state and simple to check. Rejected: it
bans the anchored measurement, which is the most rigorous form of evidence this corpus
produces, and it would have deleted the probe records that make several decision records
worth reading. A rule that forbids the good case to catch the bad one is not a hygiene rule.

**(2) Flag every cardinal governing a countable noun.** The literal reading of the defect.
Rejected on measurement: over this corpus it is mostly grammar rather than counting, hand
classification of a sample put roughly one hit in ten as a genuine defect, and it turns red
on anchored content that is correct. Precision that low is self-defeating — the exemption
marker becomes the routine response and the gate stops meaning anything.

**(3) Admit only a declared derived region.** Ship the positive limb alone: a count is
permitted inside a region a script regenerates, and nowhere else. Rejected as a standalone:
the corpus contains no such region for this purpose today, so the rule would ship green over
an empty population — the precise pathology this milestone was opened to remove, reproduced
in the fix. Retained as one admitted form.

**(4) Admit a count that carries any of several re-derivable bases, and declare the
residual.** Chosen. It matches what the corpus already does, it protects the anchored
measurement by construction, and it makes the leftover population visible instead of
forgiven.

## Decision

**A count asserted about a countable population in this repository's durable prose carries a
re-derivable basis. Four forms are admitted, each already demonstrated here.**

| Form | What makes it sound | Demonstrated at |
|---|---|---|
| **F1 — anchored measurement** | The sentence names the commit, revision or date the count was probed at, so it is frozen to a point in history and cannot go stale. A past-tense or superseded claim is the same form: it describes a state that was. | `reference/adr/ADR-010-per-traveler-approval-collection.md`, whose crypto-primitive probe names its anchor commit and remains correct against a tree that has since grown |
| **F2 — derived-and-asserted region** | The count sits inside a region regenerated from its own source on every run, so nothing about it is maintained by hand. | the `command-surface: derived` region in `reference/command-reference.md`, regenerated and graded by `scripts/test-command-taxonomy.sh` |
| **F3 — reconciled rule** | The sentence writes out the arithmetic that produces the number, so a change moves a countable a reader can re-derive rather than silently invalidating one they cannot. | `reference/data-model.md`, which reconciles its labelled-field denominator inline and states this convention in the same section |
| **F4 — agreement-pinned population** | Several homes assert the same count and a marked population is the reference, so disagreement is what fails rather than any single home being trusted. | the starred-field and class-assignment agreement groups in `scripts/test-artifact-schema.sh` |

**A count in none of those forms is a defect.** The remedy is any of: remove the assertion,
state the rule instead of the number, or give it one of the four bases. Which one is an
authoring judgement and this record does not rank them.

**Three shapes are not counts and this convention does not reach them.** A **locator** is an
address — a section, row, step or wave number names a position, not a population. A
**threshold** is a requirement — `minimum`, `at least`, `per` — and nothing about the tree
makes it true or false. A **year, price or version** is a value that happens to be a numeral.
The determiners `no`, `one` and `both` are likewise grammar rather than counting; where a
zero or a one is genuinely load-bearing it belongs in an F2 region, which is where a
load-bearing count belongs regardless.

**The residual population is declared, not exempted.** Whatever the corpus carries at the
moment this convention becomes enforced is pinned per path in the `count-assertion-digest`
fence in `reference/data-architecture.md` § 10, on the model of the freeze declaration that
already sits beside it, and is asserted **in both directions**: a path that gains an
assertion fails, and so does a path that loses one without its row being updated. That
two-directional property is what makes the fence a pin rather than an allowlist. An
allowlist entry blinds a document permanently; the recurrences this record was written about
were mostly *second* instances inside documents that already had one, which is the case a
pin catches and an allowlist does not.

**The non-goal, stated so a green is not read as more than it is.** The gate does not verify
that a count is *correct*. It verifies that a count is *re-derivable*, which is a different
and much weaker property — a sentence can carry a perfectly good anchor and a wrong number,
and this convention will not notice. What it removes is the class of claim that nobody,
including its author, can check without redoing the measurement from scratch.

**Supersession: none.** This record generalizes the scope of a statement `reference/data-model.md`
already makes about its own denominator. That statement stays where it is and stays
authoritative for that document; nothing in it is reversed, narrowed or re-opened.

## Consequences

- **`scripts/test-corpus-hygiene.sh` enforces the convention**, alongside two citation-form
  rules that share its motivation: a bare basename cited where the document has a unique
  directory-qualified home, and a `path.ext:NNN` line-number locator. Its finding codes are
  derived from its own emission sites and each carries a must-fire control arm.
- **The enforcing check is registered by name in branch protection**, which is an operator
  action taken outside any pull request. Until it is registered the workflow runs and blocks
  nothing.
- **Rolling the gate back is two ordered steps**, de-registration first — see
  `.github/workflows/corpus-hygiene.yml`, which carries the procedure and the reason the
  order is not optional.
- **The prose surfaces this convention binds gain a maintenance obligation.** A document that
  legitimately adds or removes a count updates its fence row in the same commit, so the diff
  carries both halves. `CHANGELOG.md` carries the largest row and will bump most often; the
  friction is real and is accepted, because the changelog is one of the surfaces where this
  defect actually recurred.
- **The convention reaches markdown and not the scripts or workflows.** One of the recurrences
  named in Context lived in a CI workflow comment, which the enforcing suite does not read.
  That surface is left to review, and saying so here is the point: an unstated gap is
  indistinguishable from coverage.
- **This record is itself in scope.** Its own prose is graded by the gate it ratifies, which
  is the weakest available guarantee that the convention can be written to.

## References

- `reference/data-model.md` — states the denominator rule this record generalizes, and
  demonstrates form F3 in the same section.
- `reference/data-architecture.md` § 10 — carries the `count-assertion-digest` fence and the
  freeze declaration it is modelled on.
- `reference/adr/ADR-010-per-traveler-approval-collection.md` — the F1 exemplar: an anchored
  measurement that remains correct against a tree that has grown past it.
- `reference/command-reference.md` — the F2 exemplar.
- `scripts/test-artifact-schema.sh` — the F4 exemplars.
- `scripts/test-corpus-hygiene.sh` and `.github/workflows/corpus-hygiene.yml` — the
  enforcement surface, its control arms, and the rollback procedure.
