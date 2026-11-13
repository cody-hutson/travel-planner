# ADR-052: A body ends where the browser ends it — the visible and joined readings of a script or style body ended at the browser's end tag, kept beside the readings that end it at the exact tag, read and credited after every earlier arm, and named by two further projection values, superseding ADR-050 Decisions 1, 2 and 3 in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #2117, in the *Approvals stay true when the roster or the plan changes*
  milestone. Its triage measured two shapes of a protected value publishing after a `<script>` or
  `<style>` end tag written in a form other than the exact one, and the operator ruled at that
  milestone's plan gate that the visible and joined readers each gain a reading that ends a body
  where the browser does, kept beside the reading they have, with a record of its own. This record
  transcribes that ruling.
- **What this record is.** A decision about **which projections of the published file the
  plaintext content guard matches, in what order, and how a hit or a refusal on each is named.** It
  is addressed to whoever edits `verify_publishable_content` or any projection it reads in
  `scripts/publish-trip-site.sh`.
- **What this record is not.** It changes no class membership, no match rule and no return code of
  [ADR-008](ADR-008-publish-content-guard.md), it moves no end tag in the published or the shape
  projection, and it decides nothing about where a `<script>` or `<style>` element begins. The
  itinerary digest's reading of the same end tag is not decided here.

## Context

A browser ends a `<script>` or `<style>` body at the first `</` followed by the element's name, in
any letter case, and then whitespace — a tab, a line feed, a form feed, a carriage return or a
space — a `/` or a `>`; the end tag then runs to its `>`. The guard's visible and joined projections
end a body only at the exact tag, `</script>` or `</style>`, and the two readings disagree on two
kinds of page.

1. **An end tag of another form, followed later by an exact one.** The exact-tag reading deletes
   the stretch between the two; a browser shows it. A value written there in plain words is still
   caught, by the published arm, which reads the stretch as text. Two shapes are not: a value split
   mid-word by an inline tag, and one with an attribute-carrying tag around one of its words. Both
   published in every released tag that carried the guard, v0.13.0 through v0.62.0, as #2117's
   triage measured, and both publish at this record's base after each of six end-tag forms —
   `</script >`, a tab, a line feed, `</script/>`, `</script x>`, `</SCRIPT >` — and after
   `</style >`.
2. **An end tag of another form with no exact one after it.** The exact-tag reading keeps the body
   as visible text; a browser does not show it. The guard before 0.60.0 caught a value written inside
   such a body through that reading, and the suite pins it in M1x and M1y.

**No single reading holds both kinds, and that is measured rather than argued.** Each of the two
readers made to end a body at the browser's end tag — the suite's own mutation of them — catches the
two shapes of the first kind and publishes the M1x and M1y pages; each reader as it stands does the
reverse. The guard ORs its arms, so a reading of each kind per reader catches every page of both.

## Decision drivers

- **Monotone in catches.** A change aimed at a fail-open must not open another; under an OR
  composition an added arm can only add catches.
- **A page keeps its name.** A page another arm catches keeps the name it carried before this
  record, the reason [ADR-050](ADR-050-reading-by-shape-as-a-fourth-arm.md) credits its arm last.
- **One definition of each projection.** An added reading must not become a second copy of a reader
  that a later change to the reader can leave behind.
- **An undetermined result is a failure, never a clean pass.** An arm the guard could not read is
  refused, whatever the class holds.
- **Linear time.** A reading that slows on a long run is a guard that gets worked around.

## Options considered

1. **(A) Per reader, an added arm: the reader itself, run over a copy of the file whose script and
   style bodies each end at their browser end tag, written in the exact form.** **Chosen — see
   below.** The copy differs from the file only in those end tags, so on a page whose end tags are
   all exact each added stream is its reader's own, byte for byte.
2. **(B) Per reader, an added arm carrying its own program — the reader copied, with its body rule
   changed.** **Rejected.** *Kill-reason: two copies of one projection.* A later change to a reader
   would have to be made twice, and nothing would notice the pair drifting apart.
3. **(C) Change the two readers in place to end a body at the browser's end tag.** **Rejected.**
   *Kill-reason: it gives up the catches M1x and M1y pin* — the reason milestone 91's review declined
   it (#2094, decision 3 (B)).
4. **(D) State the stretch as a limit.** **Rejected.** *Kill-reason: it leaves a fail-open on the
   plaintext branch standing*, which the operator ruled is to be closed by adding catches.
5. **(E) A second stream inside each existing arm.** **Rejected.** *Kill-reason: it is (A) under
   another name.* A second stream is a projection, as [ADR-050](ADR-050-reading-by-shape-as-a-fourth-arm.md)
   records of its own option (D), and a phrase could straddle the seam between the two.

## Decision

**1. The guard matches six projections.** Beside the visible, published and joined projections of
[ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3 and the shape projection of
[ADR-050](ADR-050-reading-by-shape-as-a-fourth-arm.md) § *Decision* 1, `verify_publishable_content`
matches `strip_to_text_blocks_at_browser_end` and `strip_to_joined_text_at_browser_end`. Each is the
visible or the joined projection, unchanged, run over the output of `_browser_end_tags`, which writes
each script or style body's first browser end tag in the exact form and changes nothing else. This
supersedes the part of ADR-050 § *Decision* 1 that sets the projection count at four; the rest of
that decision stands.

**2. They are read after the shape arm and credited after it, the visible reading before the
joined one.** Each runs through the same arm helper and the same word count as every other arm, and
each refuses a pipeline that failed or a stream that came back empty, with no word floor. In the
combine, a hit on either is a hit; on a non-hit, its code is read after the shape arm's. In the
attribution, each is named only when no earlier arm hit. This supersedes the part of ADR-050
§ *Decision* 2 that reads and credits the shape arm last; the rest of that decision stands.

**3. Their names are a fifth and a sixth value of the projection enum:** `visible text, a script or
style body ended where a browser ends it` and `joined markup, a script or style body ended where a
browser ends it`. A hit attributed to either arm is named with its value, and a refusal of either
names it, from the same closed enum. This supersedes the part of ADR-050 § *Decision* 3 that closes
the enum at four values; the rest of that decision stands.

## Consequences

**Positive**

- A value split mid-word by an inline tag, or with an attribute-carrying tag around one of its
  words, written after an end tag of another form and before an exact one, aborts the publish.
- M1x and M1y keep their catches and their names, and every page an earlier arm catches keeps the
  name it carried.
- On a page whose end tags are all exact each added stream is its reader's, byte for byte, so the
  added arms can add no false abort there.

**Costs, and what holds them**

- **Two more streams per publish**, read from the same file through the same helper.
- **A render whose every visible word sits inside a body closed only by an end tag of another form
  is refused as undetermined**: a browser shows none of those words, and an added stream with no
  words is refused as a stream that did not run would be. A false abort, in the closed direction;
  the remedy is the encrypted publish or the exact end tag.
- **The reading follows the end tag and nothing else.** An opening tag that only looks like a
  script or style one — a custom element whose name begins `script` or `style`, or an unclosed
  `<script>` written inside a comment, an attribute value or a text box such as `<textarea>` or
  `<noscript>` — is read as the readers have always read it, as a body that runs to the next end
  tag. A commented-out script that carries its own end tag is not in that class: its body ends at
  that tag. That residual is stated, not closed, by this record.
- **A quoted `>` inside an end tag's attribute ends the tag early**, leaving the rest of it as text:
  more words in a stream, the closed direction.
- **Where a browser reads a script body past an end tag** — a `<!--` that opens a nested `<script>`
  inside the body — this reading ends the body earlier and puts more text in the streams: the
  closed direction too.

**What this decision makes false or necessary elsewhere**

- [ADR-050](ADR-050-reading-by-shape-as-a-fourth-arm.md) records the partial supersession of
  § *Decision* 1, 2 and 3 in its `Status:` line, retains the superseded text as decided, and carries
  an inline marker at each of the three.
- Every statement in `scripts/publish-trip-site.sh` and `scripts/test-publish-guard.sh` that counts
  the guard's arms counts six, and the comments above the visible and joined projections name the
  reading that now ends a body where the browser does.
- The itinerary digest's projection reads the same end tag, and the suite holds the two to one rule.
  Four classes of text a reader can see are known to stay outside that digest, named here so the
  rule is not read as the whole answer — the list is what has been found, not a proof that nothing
  else does: **(a)** text after an opening tag that only looks like a script or style one, the
  class above; **(b)** text after a stray `<` in the page's text, which the digest's tag strip
  reads as a tag's start, dropping everything up to the next `>`; **(c)** text a script or style
  draws — a map pop-up, a CSS `content:` label — which the digest does not read, by design; and
  **(d)** text a browser shows from an attribute — an `<input>` or button `value`, a
  `placeholder`, an `<option>` `label`, an `<img>` `alt` — and the body of a closed `<script>`
  written inside a text box such as `<textarea>`, which a browser shows as the box's text. One
  follow-up card owns (a), (b) and (d), the digest dropping text a browser shows; (c) stays out by
  design. How many renders carry (a), (b) or (d) is unmeasured: the repository tracks no render.
- A render with an end tag of another form reads as changed once under that digest, and the gate's
  `unconfirmed` message then says its itinerary content differs from the published plan, when what
  moved is the reading. The remedy is one `confirm`, which the release's changelog entry states.
  A follow-up card designs a reading-version field written beside each record's digest, so the gate
  can say that the reading changed; no old digest is ever accepted in its place.

## References

- The decisions this partly supersedes, and the arms, order and enum they leave standing:
  [ADR-050](ADR-050-reading-by-shape-as-a-fourth-arm.md) § *Decision* 1, 2 and 3.
- The class, rules, codes and coverage boundary it leaves unchanged:
  [ADR-008](ADR-008-publish-content-guard.md) § *Decision* 3 and 4, and its *Coverage boundary*.
- The rule every verdict guard in the suite that grades these arms meets:
  [ADR-048](ADR-048-guard-arm-falsifiability-rule.md).
- The card and its triage: #2117; milestone 91's review, #2094, decision 3 (B).
- Implementation: `_browser_end_tags`, `strip_to_text_blocks_at_browser_end`,
  `strip_to_joined_text_at_browser_end` and `verify_publishable_content` in
  `scripts/publish-trip-site.sh`. Regression coverage: `scripts/test-publish-guard.sh` group M,
  arms M9a–M9e, and group S, arm S32d, for the end-tag rule the digest shares.
