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
the number without trusting the author.** That property is not itself machine-checkable — a
machine would have to follow every route to know it leads anywhere. What is checkable is a
proxy for it: whether the sentence *names* a route at all. The count is not the problem; the
missing basis is. A machine can settle whether a basis was offered, never whether the offered
basis holds.

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
| **F1 — anchored measurement** | The sentence names the commit, revision or date the count was probed at, so it is frozen to a point in history and cannot go stale. A past-tense or superseded claim is the same form: it describes a state that was. *Recognised by shape only, and the date half is not recognised at all — see the recogniser-coverage note below.* | `reference/adr/ADR-010-per-traveler-approval-collection.md`, whose crypto-primitive probe names its anchor commit and remains correct against a tree that has since grown |
| **F2 — derived-and-asserted region** | The count sits inside a region regenerated from its own source on every run, so nothing about it is maintained by hand. | the `command-surface: derived` region in `reference/command-reference.md`, regenerated and graded by `scripts/test-command-taxonomy.sh` |
| **F3 — reconciled rule** | The sentence writes out the arithmetic that produces the number, so a change moves a countable a reader can re-derive rather than silently invalidating one they cannot. | `reference/data-model.md`, which reconciles its labelled-field denominator inline and states this convention in the same section |
| **F4 — agreement-pinned population** | Several homes assert the same count and a marked population is the reference, so disagreement is what fails rather than any single home being trusted. *The sentence grader has no recogniser for this form and cannot see it — see the recogniser-coverage note below.* | the starred-field and class-assignment agreement groups in `scripts/test-artifact-schema.sh` |

**A count in none of those forms is a defect.** The remedy is any of: remove the assertion,
state the rule instead of the number, or give it one of the admitted bases. Which one is an
authoring judgement and this record does not rank them.

**Recogniser coverage — the admitted forms the gate cannot see.** The table states the
authoring convention, which is broader than the implementation that grades it, and the
difference is recorded here rather than left for a contributor to hit by surprise. **F4 has
no recogniser at all.** Agreement-pinning is a property of several homes agreeing, which no
single sentence carries, so the grader cannot detect it; an F4 sentence still registers as a
residual site and is carried by its fence row. **F1's date half has no recogniser either** —
the implemented arm reads a commit-shaped token and the phrases `probed at`, `as of` and
`baseline`, and nothing in it reads a date as the moment a count was probed. F2 and F3 are
implemented as the table describes, subject to the shape-only caveat below: the derived
region is recognised by its opening marker rather than by confirming a generator writes it,
and the arithmetic arm reads the arithmetic without evaluating it. **Authoring to a form the
gate cannot see is still sound authoring** — it will register a site, and the fence is where
that is carried, which is the fence's job and not a defect in the sentence.

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

**The non-goal, stated so a green is not read as more than it is.** The gate verifies that a
recognised **basis form is present** in the sentence. It does not verify that the count is
*correct* — a sentence can carry a perfectly good anchor and a wrong number, and this
convention will not notice. Nor, and this is the weaker guarantee worth being explicit about,
does it verify that the named basis **resolves to anything**. Nothing is dereferenced: a
commit-shaped token is never looked up, a derived-region marker is never matched against a
generator, and the word `baseline` is taken at face value.

**A fabricated basis therefore passes, and a reader of this record should expect that.**
`deadbee1` is not a commit in this repository and never has been, yet a sentence carrying it
is exempted purely on the shape of the token. A comment that merely looks like a
derived-region opener suppresses everything beneath it whether or not anything regenerates
it. The bare word `baseline`, standing alone in a sentence that anchors nothing, is enough.
None of that is a bug in the implementation; it is the boundary of what a text-shaped probe
can establish without resolving every reference it reads.

**So what the gate is for, stated positively, because the property is real and worth having.**
It stops **accidental drift** — the count written in good faith that silently goes stale when
the population moves, which is the failure this record was opened about and the one that
recurred in every kind of surface this repository has. It does **not** stop an author who
deliberately writes a false basis, and it could not be made to without dereferencing every
anchor a sentence names. The asymmetry is the point rather than an embarrassment: drift is
unintentional, so a check that merely obliges an author to *name* a route to the number
catches it, because an author made to name a route has been made to look at the number. What
the gate removes is the claim nobody can check without redoing the measurement from scratch.
What it leaves to review is the claim whose route is stated but wrong.

**Supersession: none.** This record generalizes the scope of a statement `reference/data-model.md`
already makes about its own denominator. That statement stays where it is and stays
authoritative for that document; nothing in it is reversed, narrowed or re-opened.

## Consequences

- **`scripts/test-corpus-hygiene.sh` enforces the convention as a basis-form-presence check**
  — not as a re-derivability check, per the non-goal above — alongside two citation-form
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
