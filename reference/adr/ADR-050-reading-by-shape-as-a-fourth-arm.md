# ADR-050: Reading by shape as a fourth arm — the published projection the guard before 0.60.0 wrote, kept beside the one that replaced it, read and credited last, and named by a fourth projection value, superseding ADR-008 Decisions 3 and 4 in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #2068 (carrying #2070), in the *A plaintext publish never lets through a value
  the guard used to catch* milestone. Its design measured that no reading of the published file in
  place reaches #2068's page without reopening criterion 5 of #1467, and the operator ruled at that
  milestone's collective review that the remedy is a fourth projection and a record of its own,
  named by a fourth value of the projection enum. This record transcribes those rulings.
- **What this record is.** A decision about **which projections of the published file the
  plaintext content guard matches, in what order, and how a hit or a refusal on each is named.** It
  is addressed to whoever edits `verify_publishable_content` or any projection it reads in
  `scripts/publish-trip-site.sh`.
- **What this record is not.** It changes no class membership, no match rule and no return code of
  [ADR-008](ADR-008-publish-content-guard.md), and it adds nothing to what the guard refuses before
  the class is read beyond one more arm refused the way the published arm is.

## Context

`verify_publishable_content` matches a non-publishable value against projections of the rendered
file and aborts on a hit in any of them ([ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3).
Until 0.60.0 its published projection found machinery by **shape**: a tag name was any word
directly after a `<`, an attribute name any word before a `=`, wherever either stood. Criterion 5 of
#1467 showed that shape rule dropping a key token written directly before `=` in a comment body, a
script body or an attribute value, so a page carrying `var Ruritanian = …` published. 0.60.0 made
the published projection find machinery by its **place** instead — a name inside a tag, outside its
quoted values — and that closed criterion 5.

Reading by place keeps as text every word a page can carry around a value inside those surfaces,
and four shapes the earlier reading blocked now publish. Each was measured publishing at the base
of this record's milestone and aborting under the earlier program:

1. **A `word=` inside a quoted attribute value** — spans whose `title="k= m="` wrap a value's words
   inside a script string. The names stay between the value's words, and no five-word run of a need
   survives (#2068).
2. **An attribute list read as text** — a kept tag whose list holds a quoted `>` with no tag after
   it, at a comment's end or in a template literal followed by a comparison's `<`. The fallback reads
   the list as text and its names stand between the value's words (#2070).
3. **A later name kept as value text** — an apostrophe inside an unquoted value opens what the
   reader takes as a quoted unit, which keeps the names after it (#2068's inferred form, built and
   measured).
4. **A tag on neither list inside a script string** — `<font>`, or a custom element, split a
   value's words; the published projection reads such a tag as text, its name with it. No card named
   this one; it is the projection's own stated residual, and the earlier reading caught it.

**No reading in place can hold both directions, and that is measured rather than argued.** Two
pairs settle it. In the first, #2068's page needs `k=` dropped inside `title="k= m="`, and
criterion 5's page needs `Ruritanian=` kept inside `title="Ruritanian= passport, valid to 2033"`:
the same shape — a word, a `=`, a space, inside a quoted value — with opposite needs. In the second,
`title="k="` around one of a value's words needs its name dropped, and
`<span title="Ruritanian=">entry</span> passport valid to 2033` needs its name kept: the same
whole-value shape — a quoted value holding nothing but a name and its `=` — again with opposite
needs, which excludes the narrower rule the first pair leaves open. A rule that decides from the
bytes alone gets one page of each pair wrong, and a rule that reads the value is a projection that
reads the class. A union of two readings gets every page of both pairs right, because the guard ORs
its arms.

## Decision drivers

- **The class has one home, and the predicate is a pure consumer of it.** Every refusal is written
  before the class is read ([ADR-008](ADR-008-publish-content-guard.md) § *Decision* 1 and 3). A
  remedy that makes a projection read the class breaks both.
- **Criterion 5 of #1467 stays closed.** A key token written directly before `=` is read, and the
  abort is named as its twin without the `=` is named.
- **Monotone in catches.** A change aimed at a fail-open must not open another; under an OR
  composition an added arm can only add catches.
- **An undetermined result is a failure, never a clean pass.** An arm the guard could not read is
  refused, whatever the class holds.
- **Linear time.** A projection that slows to seconds on a long run of spaces or name characters is
  a guard that gets worked around.

## Options considered

Two pairs of pages decide this list, both stated in *Context*: #2068's page against criterion 5's
`=` render inside a quoted value, and a name-only quoted value around a value's word against a
name-only quoted value carrying a key token.

1. **(A) An added arm: the earlier published program, with two anchors that change none of its
   output.** **Chosen — see below.** Its stream is the earlier program's (the anchors are proven
   language-preserving), and the matcher, the class source, the normalization and the entity
   decoder are unchanged between the two trees, so it restores every catch the earlier projection
   made.
2. **(E) An added arm: the current program plus a pass dropping every `word=`.** **Rejected.**
   *Kill-reason: a strict subset of (A) at the same decision cost.* Its catches are a subset of
   (A)'s on every page measured, and it misses the fourth shape above and #2055's spaced-close leak,
   both of which (A) catches.
3. **(H) In place: inside a quoted value the attribute reader reads, drop a `word=` followed by
   whitespace or the closing quote.** **Rejected.** *Kill-reason: it reopens criterion 5.* On
   `title="Ruritanian= passport, valid to 2033"` it publishes where the guard aborts, and it misses
   #2070's two renders.
4. **(B) In place: the earlier `=` rule applied inside every quoted value.** **Rejected.**
   *Kill-reason: it reopens criterion 5*, on the same page and on an `href` whose query carries the
   key token before `=`, and it misses #2070's two renders.
5. **(G) A value-aware projection: drop `word=` unless the word is a class token.** **Rejected.**
   *Kill-reason: it breaks the class's single home and the predicate's purity*, and a refusal could
   no longer be written before the class is read.
6. **(D) Two readings inside the published arm, one stream each.** **Rejected.** *Kill-reason: it
   is (A) under another name.* A second stream is a projection; emitting it inside an existing arm
   would add a member to a stated decision without saying so.
7. **(F) Revert the published projection to the earlier program.** **Rejected.** *Kill-reason:
   criterion 5* — the earlier program publishes every `=` render that criterion's arms carry.

**This reverses an elimination an earlier design made, on grounds that no longer hold.** #1467's
design rejected a fourth projection twice. First, because the projection enum was closed at three
values, so a fourth arm would be a new decision — still true, and this record is that decision.
Second, because criterion 5's `=` render would be named by the fourth arm rather than as its twin is
— which does not hold here: the added arm is credited **last**, so a page another arm catches keeps
that arm's name. The same design rejected two readings of one stream because a phrase
can straddle the seam between two copies and a hit in the copy has no true line; a separate arm has
no seam, and its program re-emits every newline it consumes, so its locator is a true line.

## Decision

**1. The guard matches four projections.** Beside the visible, published and joined projections
of [ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3, `verify_publishable_content` matches
`strip_to_shape_text`: the published projection as the guard before 0.60.0 wrote it — the doctype,
the comment delimiters, every tag name found by shape with the block boundary emitted before it, and
every attribute name found by shape — carrying a possessive tag head and a `=` rule anchored at the
start of a name run. Neither anchor changes the program's output; both make it linear. This
supersedes the part of [ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3 that sets the
projection count at three, and the rest of that decision stands: the evaluand is the published file,
a hit on any projection is a hit, and the three return codes are unchanged.

**2. It is read last and credited last.** The arm runs after the joined arm's refusal and before
the class is read, through the same arm helper and the same word count as every other arm. Like the
published arm it carries no word floor and refuses a pipeline that failed or a stream that came back
empty: on a render that cleared the visible floor its stream carries the visible words, so empty
means it did not run. In the combine, a hit on it is a hit; on a non-hit, its code is read after the
joined arm's, as the arms' own order reads each. In the attribution, it is named only when no other
arm hit, so a page another arm catches keeps the name it carried before this record.

**3. Its name is a fourth value of the projection enum:** `markup read by shape (every tag and
attribute name dropped)`. A hit attributed to the arm is named with it, and a refusal of the arm
names it, from the same closed enum the other three values belong to. This supersedes the part of
[ADR-008](ADR-008-publish-content-guard.md) § *Decision* 4 that closes the enum at three values; the
rest of that decision stands: the abort names a position in the evaluand, keeps the model coordinate
as provenance, and never echoes the value.

## Consequences

**Positive**

- Every catch the earlier published projection made is restored while the arm's stream is that
  program's, which the design's review measured identical on 401 synthetic renders. That includes
  the fourth shape in *Context*, a fail-open no card had named.
- Criterion 5 holds and keeps its name: its `=` render inside a quoted value is still caught by the
  published arm and named for it.
- Both anchors make the arm linear on a long run of spaces after a `<` and on a long run of name
  characters, so it adds no quadratic cost of its own.

**Costs, and what holds them**

- **The false aborts the arm can add are the earlier published arm's, and only those.** It is
  OR-ed, so it cannot remove an abort, and every abort it adds is one the guard before 0.60.0 made.
  None of the must-publish pages the guard's suite renders aborts with it present.
- **One more stream per publish**, read from the same file through the same helper.
- **The standing check is the pre-0.60.0 parity cells** in `scripts/test-publish-guard.sh`: every
  page the suite renders that the earlier guard blocked must be blocked at the head. Their legacy
  guard reads this arm through the frozen copy of the earlier program, so there the arm adds nothing
  the earlier guard lacked.
- **The program is frozen; two of its inputs are not.** It interpolates `_GUARD_BLOCK_TAGS` and
  `_GUARD_BLOCK` from the shell at run time, as the parity cells' frozen copies do. A change to either
  changes this arm and moves the parity oracle with it, which then stops being the earlier guard's;
  that change owes the oracle a decision of its own, to snapshot the old values or to accept the
  moved one.

**What this decision makes false or necessary elsewhere**

- [ADR-008](ADR-008-publish-content-guard.md) records the partial supersession of § *Decision* 3 and
  § *Decision* 4 in its `Status:` line, retains the superseded text as decided, and carries an inline
  marker at Decision 3's heading, its projection table, the layer table's row for this guard, and
  Decision 4's enum sentence.
- Every statement in `scripts/publish-trip-site.sh` and `scripts/test-publish-guard.sh` that counts
  the guard's arms counts four, and the guard's residual comments name the fourth arm as the reading
  that still drops what the published projection keeps as text.

## References

- The decision this partly supersedes, and the class, rules and codes it leaves unchanged:
  [ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3 and 4, and its *Coverage boundary*.
- The rule every verdict guard in the suite that grades this arm meets:
  [ADR-048](ADR-048-guard-arm-falsifiability-rule.md).
- The card and the shape it carries: #2068 and #2070; criterion 5 of #1467; #2055's spaced closing
  tag, which this arm catches before that card's own repair; #2072, whose anchors the arm carries.
- Implementation: `strip_to_shape_text` and `verify_publishable_content` in
  `scripts/publish-trip-site.sh`. Regression coverage: `scripts/test-publish-guard.sh` group M, arms
  M7a–M7h for the four shapes and criterion 5's name, M6a–M6e for the pre-0.60.0 parity cells, and
  group L's L17 cells for the arm's refusals.
