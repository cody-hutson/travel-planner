# ADR-044: The interviewer's conversation conduct — examples by kind, own words as a predicate, a follow-up bound and a chosen interview style, superseding ADR-022 D5.3 and ADR-026 § 5's CH-2 W-test in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *interviewer becomes a conversation: the founding decision* milestone —
  its conduct card (#1767), cut from the interviewer epic (#1205) at that epic's refinement as the
  decision gate at the head of the work it opens. The operator rendered the decisions below at that
  card's design gate, in a first sitting and a confirm sitting, and amended the closing clause of
  the fifth at the Collective Review of the milestone's other card. This record transcribes them.
- **What this record is.** A decision about **what the interviewer may say, and how far it may
  go**: when it may give an example and what one may contain, what must be true of every value it
  records, how often it may come back to a field, and what a traveller's choice of interview style
  may change. It is addressed to whoever authors the interview's conduct, and it replaces each
  floor it relaxes with a guard a check can evaluate.
- **What this record is not.** It edits no conduct: `skills/trip-record/interview-conduct.md` and
  `templates/interview-card.md` read after it as they read before, and a session follows them. It
  decides no return path, no rating and no engagement record — what comes back beside the profile
  is the milestone's other record's (#1768). It decides no placement and no part of the form
  contract, and it changes no grant, no command surface and no artifact class.
- **The status flip is named here.** Moving this record from `Proposed` to `Accepted` is the
  operator's, taken in a change on `main` after the release that lands it merges, and it moves both
  halves of a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md). `scripts/test-adr-conformance.sh` grades that the halves agree, and
  reports without failing an Accepted record that cites a `Proposed` one; nothing grades that the
  flip is made.

## Context

**The floors this record relaxes were set on purpose.** Three texts bound what an interviewer may
put in front of someone, as they read on `main`:

- [`ADR-022`](ADR-022-interview-session-model.md) D5.3 lets an offer contain only option text the
  form itself carries, quoted; has the interviewer offer no option for a field whose form carries
  no option list — *"an open question stays open"*; and calls an offer that paraphrases the form's
  options an invention.
- [`ADR-026`](ADR-026-channel-architecture.md) § 5 gives the interview channel, CH-2, a W-test
  whose first sentence reads: a prompt *"may name a field and a remedy; it may **never carry,
  quote, or offer a candidate value**"*. Its second says silence is not assent in a spoken
  modality.
- Shared rule 2 of `skills/trip-record/interview-conduct.md` caps a section — *"Two or three
  questions a section at most"* — and calls a bracketed placeholder a hint for the interviewer,
  never a script to read out. It cites no record. `templates/interview-card.md` carries the shared
  rules word for word.

**One reading of those floors was already taken, and it is the reading this record starts from.**
Commit `14043ee` records the operator's decision on the durable form's must-haves step: the kinds
of need that step lists may be shared as examples, never as a list to choose from, and they are
given with the ask. It added a clause to shared rule 3 — an example the ask-prose gives for its section
*"may still be mentioned as an example, never offered as a choice"* — and its message records two
things this record relies on. The grading of D5.3 on that release *"read the mention as an offer"*.
And the candidate value shared rule 7 bars *"is one arrived at"*, where an example the ask-prose
gives is the form's own text.

**The interviewer epic's refinement asks for more than those floors admit** (#1205): an interviewer
that may give an example to help someone answer and may follow up when an answer is thin, while
recording only the traveller's own words, in a style the traveller chooses. Those changes cross the
records above and the conduct file, and a cross-cutting decision is taken at the head of the work
and not inside a slice of it.

**A session follows the conduct file, and this record does not edit it.**
[`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md) D1 authors the interview's shared
conduct in `skills/trip-record/interview-conduct.md` and nowhere else. This record says what that
file's authors may write; § *Consequences* says what binds a session until they do.

### What the evidence says, and how far it goes

The decisions cite the interviewing-research finding (#1765), read with its corrections, and the
voice-mode finding (#1766). Each statement below is restated in this record's words, carries the
finding's own identifier, and says how far its source goes. § *References* locates each finding.

**Almost all of it is inference.** Of the research finding's seventeen load-bearing statements, as
its corrections leave them, one meets the finding's grade-B bar (`#1765 F-7`'s speech effect), one
is a search that found nothing (`#1765 F-5`'s speech effect), and fifteen are marked inference:
positions the sources do not settle. Most of its sources study human interviewers, remembered
events or typed exchanges. Four of the machine-interviewer studies it includes are spoken, and in
two of those a person operated the system behind the machine voice (`#1765 COR-9`). The voice-mode
finding is one run of one assistant with a scripted synthetic traveller: its grades are text copied
out (T) and operator-attested (A), and nothing in it is a rate. **So a ground below that rests on
an inference or on an operator-attested item is the operator's judgment informed by it. It settles
nothing by itself, and no decision here is presented as following from it.**

**On examples.**

- `#1765 X-1` — inference; strongest underlying grade A; read with `COR-12`, `COR-16` and `COR-21`.
  No included source tests how many examples an interviewer may offer, of what kind, or at what
  point. The bound it recommends is: an example offered only after a thin or stuck answer or on
  request; as an illustration of the kind of answer, and never as a value from the form's domain
  that the person might adopt; several spanning the range rather than one; at most a few in a
  spoken turn; and never repeated after the person answers. The review behind it reports that
  examples may both remind people of what they would leave out and shift what they report
  (`COR-12`). Its statement that steering is strongest where a person's own answer is weakest comes
  from eyewitness memory under load, and applying it to preferences is a transfer (`COR-16`).
  Options heard favour the last one heard, and a survey-design chapter expects options read to
  favour early ones (`COR-21`; grade C for the contrast). One text study, on attitudes, found that
  content a machine offered shifted people's views more as in-line suggestions than as a static
  list; carried to a spoken example, that is a transfer.
- `#1765 F-1` — its speech effect is inference, grade C; read with `COR-11` and `COR-19`. A prompt
  that implies its answer shifts the answer given. Slanted suggestions from a language model
  shifted people's later attitudes, mostly unnoticed, and warning them did not significantly reduce
  the effect — in text, on attitudes. Whether speech makes leading worse is not settled.
- `#1765 F-3` — its speech effect is inference, grade A with a construct transfer. People endorse
  what a question asserts, more by telephone than face to face. No included study measures it in
  voice against text.
- `#1765 F-4` — its speech effect is inference; read with `COR-7` and `COR-17`. Long turns and many
  options are hard to hold by ear. Four short options in a spoken turn did not lower task success
  in one wizard-operated system, which did not measure order bias.
- `#1766 V-9` — operator-attested, ungraded. It bears on how many examples a question carries and
  on how form text sounds when voiced.
- `#1766 V-4` — operator-attested; the finding marks it not load-bearing. One returned value
  carried a form's own example wording and not the scripted answer. Whether the assistant
  substituted it is unconfirmed and will not be settled.

**On follow-ups.**

- `#1765 X-2` — inference; strongest underlying grade A; read with `COR-10` and `COR-15`. **The
  evidence supports no specific number.** The bound it recommends is: at most one follow-up on a
  field, asked only when the answer is thin or ambiguous and referring back to the person's own
  words; none after a skip, a decline or a stop; none that repeats the question; and a total for a
  section kept within that section's asking budget. What its sources report is what interviewers
  did. Language-model interviewers replaying a scripted interview asked between about 0.35 and 0.85
  follow-ups a main question; the one rated highest for necessity asked fewer than the
  high-intensity ones; and no person answered them — a language-model interviewee did, in text
  (`COR-10`). A probing chatbot asked each participant for more about three times across a survey.
  No included source varied the number of follow-ups on a field and measured where answers changed
  or people disengaged.
- `#1765 T-4` — grade A, from text studies, so its transfer to speech is not discharged; `COR-18`
  regrades one of its sources to D. A probe that refers back to what the person just wrote drew
  longer answers with more ideas, and probes planned for a particular answer were more useful than
  improvised ones.
- `#1765 F-2` — grade A with transfers; its speech effect is inference (`COR-24`). Repeating a
  question can act as negative feedback on the answer already given — a summary of a primary not
  read, about remembered events (`COR-23`).
- `#1765 F-5`, read with `COR-13`. No comparison of pushing after a decline in speech against text
  was found. "Take the decline and do not ask again" is itself a transfer its source does not make,
  and is marked inference.
- `#1765 F-6` — its speech effect is inference, grade A. Breaking off rises with an interview's
  length and clusters on burdensome questions and on the openings of sections — in telephone
  interviews with human interviewers.
- `#1765 F-7` — **meets the grade-B bar**; `COR-8` repairs one of its locators. People report fewer
  sensitive behaviours by voice than by text, with automated interviewers as well as human ones.
  Its mitigation is a typed channel, which `ADR-022` D6.3 already offers. It says nothing about a
  further question.
- `#1765 T-6` and `F-8` — grade A, where the clarifying was done by a person behind the machine
  voice — with `COR-2`. An interviewer able to clarify what a question means got more accurate
  answers than a strictly scripted one. Whether a clarification that carries content leads is
  tested by no source.
- `#1766 V-6` — operator-attested. In that run the assistant took no turn during one silence, so
  whether it makes shared rule 6's offer after a silence is unmeasured. `#1766 V-12` and `V-15` —
  operator-attested, ungraded — bear on silences and on repeated questions.

**On styles.** `#1765 S-1` to `S-4`, their crosswalk and the default the finding recommends, read
with `COR-1` to `COR-6` and `COR-18`. Four styles are attested as styles: standardized,
collaborative, brief and efficient, and responsive listening. Every statement of what a style
raises, and the recommended default, is inference. *Gentle* is an inferred combination of listening
and pacing. *Fun* and *playful* have no attested style, because the search for one was cut short
and not because anything was found against them.

**On what a grader reads.** `#1765 R-2`, `R-3`, `R-9` and `R-10` outline what a grader looks for in
a transcript — no offered values, follow-up discipline, cumulative load, listening without
endorsement. #1769 sets every pass level.

### The own-words rule was worded two ways, and the operator ruled between them

The epic's fourth criterion, as refined, and #1769's third say each recorded value is a
*subsequence* of the traveller's own turns. This record's card says every recorded value *contains
only words the traveller said*. `ADR-022` D5.1 tests a confirmation as a subsequence of the
utterance in its turn, and D5.2 makes *keep their words* delete-only and calls it the same rule
seen from the recording side.

On the one measured run a value and its confirmation put the traveller's own words in a different
order, and the operator ruled that not a break of shared rule 7, recorded as a fidelity note
(`#1766` D-SpecialOccasion — a ruling on one run). In that run most of the visible turns departed
from the script, and the copy cannot separate the speaker's wording from the transcription
(`#1766` *Disagreement 4*, grade T).

At this card's design gate the operator ruled first that the words decide and order is reported and
not failed, and then, when the design showed that ruling and `ADR-022` D5.1 did not reconcile, that
order stays the interviewer's rule. D2 states both.

## Decision drivers

- **The four constraints `ADR-022` holds, held here too:** the engine never invents, on any
  modality; `Skip` stays valid and nothing pushes twice; the artifact set stays contained; and no
  new privilege is taken.
- **A relaxed floor is replaced by a guard a check can evaluate.** Where no check can reach —
  whether a phrase names a kind or a value, whether an answer was thin — the record names the
  grader whose judgment it is, and does not dress a judgment as a test.
- **The record binds the conduct's authors, and a session follows the conduct file.** Every
  permission here is a ceiling, and nothing an interviewer does changes on the day this record
  lands.
- **Settled design is not written into a record** (`ADR-042` § 3). The record states each rule and
  its permitted cases. How a check evaluates one is pinned by the suite that runs it.

## Options considered

Each choice was put to the operator at the design gate with the design's recommendation and an
independent review's. Where the operator ruled against the design, that is said.

### D1 — where an example's words come from, and when one may be given

| Option | Verdict | Ground |
|---|---|---|
| **The field's own placeholder example, quoted** — the first design's | rejected by ruling | It is the kind of example `#1765 X-1` recommends against: a value from the form's domain that a person might adopt (inference). And on the reading commit `14043ee` records, quoting form text supersedes nothing, so neither mark below would have an object |
| **Only kinds the form's author wrote** | rejected by ruling | Not every section's ask-prose gives kinds, so it helps only where a form has been edited, section by section. What it gets right is kept: kinds the form's own ask-prose gives may come with the first ask |
| **The form's where it carries one, composed where it does not** | not taken | Moot once the source is composed |
| **No example beyond what shared rule 3 admits today** | rejected | It contradicts the epic's fourth criterion as refined |
| **The interviewer composes an example of the kinds of answer** | **selected** | D1 |
| A composed example **with the first ask** | rejected | `#1765 X-1` (inference) and `#1766 V-9` (operator-attested, ungraded) both pull away from it, and it is the occasion on which words the interviewer wrote reach someone before they have tried to answer |
| An example **on request only** | rejected | It leaves a thin answer with no help unless the person knows to ask |
| **A single kind** | rejected | `#1765 X-1` asks for several rather than one (inference); a lone example reads as a suggestion |
| **Voicing a placeholder's instance when asked** | rejected | It is a value the person might adopt, which the bound excludes without exception |
| A section's menu or tick list **mentioned as examples** — the revised design's | rejected by ruling | Wider than the bound the operator had ruled: the form itself calls an item of such a list a complete answer, so mentioning the items voices values. The lists are described and not read out |
| A section's menu or tick list **as an option source** for the field that points at it | rejected | A change to [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) D2.3, beyond this record |
| On a field whose answer is itself a kind: **nothing composed there**, or **an adoptable value said as an example** | not taken | The operator ruled for the option between them: a composed example one level up, held to a floor a check can run. The second would narrow the ruled bound on those fields; no ground was recorded for the first |

### D2 — what decides whether a recorded value is the person's own

| Option | Verdict | Ground |
|---|---|---|
| **Words and order both required** — the first design's | rejected by ruling | It fails the reorder the operator ruled not a break (`#1766` D-SpecialOccasion); it fails a value built over more than one turn whose later turn supplies its head; and the reason given for it does not hold, because a meaning can be reversed by deletion alone, inside a subsequence |
| **The words decide; order is reported** | **selected** | D2 |
| **A test of meaning** | rejected | `ADR-022` D5.1's own ground: two reviewers disagree about meaning |
| **A window of every earlier turn** | rejected | It passes a value assembled from answers to other fields |
| **Refusing or failing an echoed example** | rejected | It would refuse someone whose true answer is the example. Reporting it costs no verdict |
| **Order no longer a rule for the interviewer** — on the value written and the confirmation spoken | rejected by ruling | It supersedes `ADR-022` D5.1 and D5.2 in part as to order: further marks on decisions the card lists as unchanged. The operator kept order as the rule and took no further mark |
| **A member a form declares as its default**, admitted as a further non-utterance | rejected | It is a value taken from a default and not from the person. The form's ask-prose is reworded |
| A form's declared word written **only when the person says that word or picks it** | rejected | The durable form directs the word for an empty answer however it is said, and the em dash is already written for a skip uttered in any words |

### D3 — what the bound counts, and how many

| Option | Verdict | Ground |
|---|---|---|
| **One budget**: at most one further interviewer-initiated turn a field, for any reason — the first design's | rejected by ruling | It withdraws `ADR-022` D5.5's re-offer from a field that has used its follow-up; it leaves no move where D5.6 makes a question the only one; and it gives a closed field no exit |
| **Follow-ups only**, one a field | **selected** | D3 |
| **No follow-up at all** | rejected | It contradicts the epic's eighth criterion |
| **Two follow-ups on a field** | rejected | No source tested two, and `#1765 F-2` informs the judgment that coming back twice reads as pressure (grade A with transfers) |
| **A word count as the test of a thin answer** | rejected | A short answer can be complete and a long one thin; any threshold would be an invented number |
| **A total that includes first asks**, at shared rule 2's figure | rejected | It is the cap the card says is replaced, and one shipped form's own ask-prose already asks more than that of a repeat block |
| **No number for a section**; **one a section**; **a second number for a repeat unit** | not taken | The operator took at most two a section, as judgment. `#1765 X-2` supports no number (inference) |
| A field whose replies name no member: **no stated count**, or **a second such reply read as a skip** | rejected | The first states no point at which the interviewer stops offering; the second writes an em dash for a skip nobody uttered, which `ADR-022` D5.5 forbids |
| A follow-up **after an empty answer** — the revised design did not bar it | rejected by ruling | It is a probe after a negative, and the review found it on a form's safety field. Barred, as after a decline |
| **No speech clause** | rejected | A spoken answer is audible to a room, and a follow-up asks for more of it aloud |

### D4 — how a style is chosen, and what it may change

| Option | Verdict | Ground |
|---|---|---|
| A style varies **how much of the permitted example and follow-up it uses** — the first design's | rejected by ruling | An ask-on-doubt after an answer would then be the style's to drop, and a session that dropped it and one that kept its style leave the same transcript |
| A style changes **how the asking sounds, and nothing else** | **selected** | D4 |
| **Never offered, honoured when asked** | rejected | A choice nobody is told about is not a choice |
| **Set by whoever sends the form** | rejected | It moves the choice from the traveller |
| **Picked by the interviewer from how they talk** | rejected | An inference about a person, undisclosed, that no check could grade |
| **No names in the record** | rejected | The milestone's other record reads which style was in force, and needs a value set |
| The names **`thorough`, `brisk`, `gentle`** | rejected | *Thorough* names follow-up use, which no style now varies |
| The names with **`playful`** | not taken | No style of that name is attested (`#1765`, its crosswalk) — an absence of search, not evidence against it |

### The marks, and where a predicate's shape lives

| Option | Verdict | Ground |
|---|---|---|
| Each mark lands **with the change that ships its replacement** | rejected by the operator at the plan gate | The marks land in the release that lands this record. No rationale was stated at the gate |
| Each mark **states its own effective condition** | rejected | It leaves a tensed sentence in the `Status:` line of each accepted record that no later change is bound to finish, and it pins rule numbers an edit may renumber |
| **Plain marks**, saying nothing of effect | rejected | A reader of `ADR-022` would be told D5.3 is superseded in part with no sign that shared rule 3 still binds |
| **A plain mark and one pointing sentence**, the condition stated once here | **selected** | D0 |
| A predicate's whole shape **in this record** | rejected | `ADR-042` § 3: tables, enumerations and procedures are never a record's |
| That shape in **a new specification under `reference/`** — the revised design's | rejected by ruling | No new file; the approved change set stands. Nothing is built yet, so no change writes that shape into a record and none owes it a document; and part of what would move is not settled |
| That shape in a new section of `reference/data-model.md` | rejected | Its subject is the data model, and a turn-level check on a conversation is not one |
| The record states the rules; **the cards that build the checks pin their shape** | **selected** | § *The predicates* |
| The arm over the forms' own conduct lands **with the change that rewords the forms** — the revised design's | rejected by ruling | An arm scoped away from the one input known to trip it cannot fail. It lands with the other prohibition limbs, against a declared ledger |
| The restatement of the shared rules **moved into the change that builds the text-level checks** | rejected | A larger change there and a re-pointed tone pass. Splitting each check by limb makes every arm true when it lands |
| **The interviewer labels its own turns** | rejected | The interviewer under test would be grading itself |

## Decision

### D0 — two decisions are superseded in part, each as far as it reaches an example

**This record supersedes `ADR-022` D5.3 in part, and the first sentence of CH-2's W-test in
`ADR-026` § 5 in part: each as far as it reaches an example, and no further.** Every other decision
of both records stands.

- **`ADR-022` D5.3.** An example is not an option, and D5.3 is a decision about options. It reaches
  an example on one reading: that whatever is said beside an open question is an offer — which its
  opening sentences bound to the form's own text, and which its clause *"an open question stays
  open"* withholds from a field whose form carries no option list. That is the reading the grading recorded in commit `14043ee` took
  when it *"read the mention as an offer"*, and the reading shared rule 3 follows where it says to
  ask such a field open and offer none. A composed example is text the form does not carry, said
  beside an open question, so on that reading D5.3 bars it — and on that reading D5.3 is
  superseded. **Everything D5.3 says of an option stands:** an option is offered only from the
  form's own option text, quoted; none is offered for a field whose form carries no option list;
  and a paraphrase of the form's options is an invention. So do that record's paragraph on what
  makes D5.3 and D5.4 gradeable, its reading of D5.3 at the close of its § *Decision* 5, and its
  rows `S13` and `OS-4`, which are about the option list's one home.
- **`ADR-026` § 5, CH-2's W-test, its first sentence.** The candidate value that sentence bars is,
  in shared rule 7's gloss and in the reading commit `14043ee` records, a value *arrived at* rather
  than one the form lists. A composed example is text the interviewer arrives at, so the sentence
  reaches it, and as far as it does it is superseded: D1 restates what a prompt may carry. **What
  stands:** that a prompt carries no value the person might adopt, other than an option the form
  lists or their own words; the second sentence of that cell, that silence is not assent in a
  spoken modality; CH-2's R-test; its enforcement-strength cell; the W-rule and the R-rule; and the
  residual paragraph beneath that table.
- **When each takes effect.** Both take effect in the change that edits the shared rules, in both
  carriers, to this record. Until that change those rules bind a session as they read.
- **Why they are recorded before that.** [`README.md`](README.md) § *Convention* says a
  supersession is recorded when it takes effect and not before. These are recorded ahead of it: the
  operator decided at this milestone's plan gate that the marks land in the release that lands this
  record. So each earlier record's `Status:` line carries a dated entry and each superseded text an
  inline marker, dated 2026-10-09 (Friday), the day they were written. That date is when the
  supersession was recorded, not when it takes effect, and each entry points here for the condition
  and states none.

Shared rule 2 cites no record, so no record's text is superseded by D3 and nothing is marked for
it.

### D1 — examples

**The interviewer may compose an example. It names two or three kinds of answer — never one
alone, never a list — it is said as an example, and it is never a value the person might adopt.**

1. **One level up, with a floor a check can run.** A composed example sits one level up from an
   answer: it names what an answer might be about. **It contains no placeholder example, menu item
   or tick-list item of its section.** Beyond that floor, whether a phrase names a kind or a value
   is a grader's judgment and has no mechanical test (§ *Residuals*).
2. **Occasions.** On request. Or once, on the interviewer's own initiative: with the field's
   follow-up after a thin answer, or when the person says they are stuck — there an example turn
   that hands the question back is no follow-up, because no answer has been taken. Never into a
   silence: a silence gets `ADR-022` D5.5's re-offer and nothing more. Never on a field whose
   placeholder lists options, closed or open: the options are what is offered. Never once the
   field has its answer and its follow-up is spent.
3. **Count.** One example turn a field on the interviewer's own initiative, in a session; as many
   as the person asks for.
4. **The form's own text.**
   - A placeholder's `e.g.` text stays a hint for the interviewer, as shared rule 2 says today, and
     is not voiced — on request either. Inside an `open:` or `closed:` bracket the options are
     offered as shared rules 3 and 4 say, and the `e.g.` clause is not.
   - A section's menu or tick list is **described** — that it exists, and what it lists — and is
     **not read out**. It is no option source (`ADR-023` D2.3).
   - Where a form's own ask-prose gives kinds — as the durable form's must-haves step does, by the
     operator's ruling recorded in commit `14043ee` — they may come with the first ask, said as
     examples, **and that counts as the field's one example**. On such a field the interviewer
     uses the form's kinds and composes none.
   - The worked example is for the person to compare against. It is never a source of answers,
     options or examples.
5. **Distinct from an answer.** The turn says these are only examples and hands the question back.
   An example is never the object of a confirmation (`ADR-022` D5.1). It is never chosen by
   position: a pick by position is for a closed field's members (D5.4). Assent to an example
   records nothing.
6. **A `PERSON`-class field in a spoken session.** `ADR-022` D6.3's one offer comes first,
   unchanged. The field is then asked, with the form's own kinds where its ask-prose gives them. A
   composed example is given there only on request. No follow-up is put there (D3), so no example
   rides one.
7. **What may be said besides.** Saying why a question is asked, or what it means, carries no
   value and was never barred.
8. **CH-2's W-test, as restated — the sentence a check of the conduct's text is held to.**

   > A prompt may carry or quote a value only where **(a)** the form lists it as an option of the
   > field being asked and it is offered as the option rules admit, or **(b)** the person answering
   > said it in this session. A prompt may also give an example as this decision bounds one; an
   > example carries no value. A prompt carries, quotes or offers nothing else. Silence is not
   > assent.

   Clause (a) relaxes nothing: `ADR-022` D5.3 and D5.4 had the interviewer offering the form's
   options before `ADR-026` was written, and shared rule 7 already reads the row that way.

*Supersedes:* `ADR-022` D5.3 and `ADR-026` § 5's CH-2 W-test, each in part (D0).

### D2 — own words

**A recorded value passes when every word of it is the answering person's own, from that field's
turns.** Nothing else decides.

1. **Whose words, and which turns.** The person answering is the traveller, or the operator where
   an answer is relayed. A turn can answer several fields, so each of their turns concerns a set of
   fields; a field's turns are theirs whose set holds it, from its first put — or from the turn in
   which they volunteered it — to the write.
2. **Reported, and never failing a value.** *Order* — whether the value's words stand in the order
   they were said. *Example echo* — whether every word of the value also occurs in example text the
   interviewer gave on that field in this session. Both are reported for each value, and a suite
   reports their rates for each conversation and each style.
3. **Order remains the interviewer's rule.** `ADR-022` D5.1 and D5.2 stand as written: what a
   confirmation keeps of their words is a subsequence of what they said in that turn, and
   tightening may delete words and may never add one, which keeps their order. **The check is
   looser than the rule on that one point, on purpose.** From *"With Sam."* and then *"Happy to
   share."*, the value *"happy to share with Sam"* passes the check and is reported as reordered;
   the write the rule asks for is *"With Sam, happy to share"*.
   A reorder — in a value written or a confirmation spoken — is a reported fidelity note that fails
   nothing. #1769's suite produces the report, and the operator reads it: what a reorder that fails
   no check leaves standing is the operator's (§ *Residuals*).
4. **The admitted non-utterances are a closed list of five.** An addition is a new decision.

   | | What is written | When | Already decided in |
   |---|---|---|---|
   | `A1` | the em dash | they uttered a skip, in any words | `ADR-022` D5.5, D2.4 |
   | `A2` | the text a form declares for an empty answer — `none` on the needs block | they gave the empty answer, in that word or in any words that state it. Where it is unclear whether they meant the empty answer or a skip, ask. Never on silence | `ADR-022` D3.6, D5.6, and D5.4 as amended |
   | `A3` | a member of a `closed:` set, as the form spells it | their words contain the member, or pick it unambiguously by position | `ADR-022` D5.4, its test whole |
   | `A4` | a provenance mark the output class admits | a relayed answer; the mark is struck before the value beside it is evaluated | `ADR-022` D4.1 |
   | `A5` | the form's own fixed text — a label, a heading, a computed line, a bracket nobody reached or resolved | always | `ADR-022` D3.5, D1.3; [`ADR-040`](ADR-040-transcript-only-return-and-save.md) D1 |

   **A member a form declares as its default is not admitted as a sixth** — the trip form's
   `one-off` for "anything else" is the known case — and the form's ask-prose is reworded.
5. **What a word is.** A difference of case, spacing, punctuation or typographic form is not a
   difference of word. Nothing that changes which word it is — a spelling repair, a stem, a
   synonym, a digit for a word — is admitted. This record does not close the list of folded forms:
   the definition a check runs is settled design.
6. **What it is compared against.** The turn as the transcript holds it. Speech the transcription
   got wrong is outside the predicate.
7. **A value built over two turns, on the route that cannot write,** is confirmed by naming the
   field and voicing no value. That form passes `ADR-022` D5.1's test as written — strike the label
   and the words that carry no value and nothing remains — and D5.1's window stays *this turn*.

**Why this is enough, and what it does not guard.** The predicate guards the **record**: no
artifact holds a word its subject did not say. It does not guard the **asking**: a person who says
an example back has said those words, and the value passes. With a composed example that echo is no
longer the same event as a hand-filler copying the form, and the guard is weaker than a form-only
rule had. What stands in its place is the operator's judgment, informed by `#1765 F-1` and `X-1`
(both inference): the bound keeps an example at the level of a kind and names more than one; an
example is never the object of a confirmation, and assent to one records nothing; the echo is
reported, so the residual is observed and not only owned; and a grader and the traveller's own
rating read the conversation.

*Supersedes:* nothing.

### D3 — follow-ups

**At most one follow-up a field in a session, and at most two a section.** A follow-up is a
further question on a field, put by the interviewer on its own initiative, after an answer to that
field that it has taken as thin, asking for more. A *taken* answer is one it can record as it
stands.

1. **The turns a follow-up is not. Each keeps its own count and stays a floor, in every style.**

   | Turn | The state it answers | Its count |
   |---|---|---|
   | **ask-on-doubt** | they answered, and the interviewer cannot tell what they meant, so nothing can be recorded yet | none stated — `ADR-022` D5.6 |
   | **member re-offer** | a closed field, and their reply names no member | `ADR-022` D5.4 states none; item 5 gives it an exit |
   | **silence re-offer** | silence, or a reply that is not clearly an answer, a skip or a stop | exactly one, and a second silence ends the session — `ADR-022` D5.5 |
   | **single re-ask** | one question named several fields, and the reply left this one untouched | it is still the field's ask; unanswered, `ADR-022` D5.5 governs |

   A check tells these from a follow-up by the state each follows, which the person's side of the
   conversation fixes. The bound replaces only the cap in shared rule 2.
2. **Never.** After a skip, a decline of the field or of its section, a stop, or an empty answer —
   the ask-on-doubt still applies where the empty answer itself was unclear. On a field the file
   already answers from an earlier session (`ADR-022` D1.4). On a closed field, which records a
   member and leaves a follow-up nothing to add. As a repeat of the question in the same words. And
   **on a `PERSON`-class field in a spoken session** — a follow-up only: the ask-on-doubt and both
   re-offers are kept there as everywhere.
3. **Content.** A follow-up carries no value but the person's own words, the field's label, and an
   example where D1 lets one be given.
4. **The trigger, in what a check sees and what a grader judges.** A check sees that the follow-up
   follows an answer of theirs to that field which was taken, that no follow-up has yet been put on
   the field, and that the section's limit is unspent. A grader judges that the answer was thin
   (`#1765 R-3`). An answer whose meaning is in doubt is not thin: it gets the ask-on-doubt.
5. **How a field's turns end, and what is written.**

   | How its turns end | What is written | A later session |
   |---|---|---|
   | The follow-up is answered | their words from both turns, tightened by deletion only | does not ask it |
   | The follow-up is declined, or met with silence | the answer already taken stands. A silence there gets `ADR-022` D5.5's re-offer, which the follow-up did not spend | does not ask it |
   | They say "skip" at a follow-up | nothing on that word: **it is clarified by asking** whether they are leaving the follow-up or skipping the field | as their reply decides |
   | Doubt remains after asking, on an open field | their words as they said them, quoted. A verbatim value can always be built there, so `ADR-022` D5.6 never leaves an open field without an exit | does not ask it |
   | They utter a skip | the em dash (`A1`) | does not ask it |
   | They give the empty answer a form declares a word for | that declared text (`A2`) | does not ask it |
   | Silence, the re-offer, silence | nothing new; the session ends (`ADR-022` D5.5) | asks it |
   | **Their replies are neither an answer, a skip nor a silence — on an open field or a closed one** | the field is **offered again once**; then nothing is written and its bracket stays — never the nearest member, never the em dash — and **the interviewer says the field is left open and moves on** | asks it |

   A session that cannot write gives back the same, and its bracket for a field left open or
   un-asked. The last row is a bound `ADR-022` never stated, and is not a supersession of it.
6. **Not a follow-up, and not counted.** A confirmation that asks for nothing more; a repeat, a
   clarification or an example the person asked for; their own return to a field, or their change
   of an answer; the starred pass's decision point; the style offer; a disclosure; the spoken-care
   offer; a routing statement.
7. **Shared rule 2's cap goes.** Each field is put once, and the form's ask-prose says how a
   section's fields are grouped into questions. The sentence carrying the cap leaves both carriers
   in the change that writes this bound in. That rule's other sentence — a placeholder is a hint,
   never a script to read out — stands with no opening.

**The speech clause is a new prohibition, taken as judgment.** `#1765 F-7`, the one item that meets
the grade-B bar, says people report less by voice than by text, and its mitigation is the typed
channel `ADR-022` D6.3 already offers. It says nothing about a further question and is not this
clause's ground. The ground is the purpose D6.3 and CH-2's R-test already state: a spoken answer is
audible to a room, and a follow-up asks for more of it aloud. A follow-up is a permission this
record creates, so limiting it narrows no kept decision.

**Both numbers are the operator's judgment.** `#1765 X-2` supports no number (inference). The
figure for a section counts follow-ups and is not shared rule 2's, which counted questions.

*Supersedes:* shared rule 2's cap, which cites no record — so there is no mark.

### D4 — interview style

**A style changes how the asking sounds — wording, register, pace, turn length — and nothing else.
Whether any turn is taken is the same in every style.**

1. **The term is *interview style*.** Bare *style* is already taken by the forms' own sections and
   fields.
2. **How it is chosen.** It is offered once: one turn, after any disclosure the session owes and
   before the first question, naming the styles and saying that keeping the default is fine.
   Keeping the default is a complete answer. It changes later only when the person asks, from the
   next question, and nothing is asked again.
3. **The offer puts no field and records nothing.** The default is in force before the offer is
   made, so no reply, or an unclear one, changes nothing, and no assent is read from silence. **A
   silence at the style offer is not a silence `ADR-022` D5.5 counts**: its count starts at the
   first question.
4. **What a style may vary — a closed list.** The wording of a question and of everything said
   around it, acknowledgements included. Register. Pace. Turn length. Never a label as written or
   confirmed.
5. **What no style may vary.** Whether any turn is taken — an example, a follow-up, a re-offer, an
   ask-on-doubt, a confirmation, the decision point, a disclosure. What is recorded, and how. The
   question set and its order. Every bound in D1 and D3. A skip taken at once; silence neither a
   skip nor assent.
6. **The invariant a check can evaluate.** Given the same turns from the person, any pair of styles
   takes the same kinds of interviewer turn on the same fields and writes the same bytes.
7. **The names: `warm` (the default), `brisk`, `gentle`.** Each names a sound. `warm` is the sound
   of the default persona #1330 authors. `brisk` is short turns, a quick pace and a plain
   register. `gentle` is an unhurried pace and a soft register.

*Supersedes:* nothing.

### D5 — what does not change

**`ADR-022` D5.1, D5.2, D5.4, D5.5, D5.6 and D6.3 stand, and this record changes no other
decision.**

- **D5.1** — no confirmation proposes a value, and its window is the turn. An example is never a
  confirmation's object.
- **D5.2** — *keep their words* is delete-only. D2's check is looser on order and says so.
- **D5.4** — a closed field records a member the answer names, never the nearest. Its re-offer is
  no follow-up.
- **D5.5** — silence is not a skip; one re-offer naming answer, skip and stop; a second silence
  ends the session. Its re-offer is the nudge after a silence, a style may soften its wording, and
  no follow-up spends it.
- **D5.6** — on doubt, ask. The ask-on-doubt is no follow-up and carries no count.
- **D6.3** — the spoken care for `PERSON`-class questions. Its reach is unchanged, and whether it
  should cover health-shaped fields typed otherwise stays the question #1353 already carries.

Left as they are, each by the operator's confirmation: the worked example stays for the person to
compare against, and the hand-off set is the other record's subject; a form's label is the form's,
and plainer words when asking are already admitted; and how the starred pass's decision point is
voiced is wording, which a style may change while its three branches stay.

### The predicates — what a check evaluates

The own-words rule and the follow-up bound each have a **text-level** form, evaluated on the
authored conduct, and a **transcript-level** form, evaluated on a conversation. The restated W-test
of D1 is evaluated on the authored conduct as well. **This record states each rule, its permitted
cases, its inputs, its verdicts and one worked pair, and no more.** A check's word lists, clause
windows and engine, what separates one word from the next, how a turn's kind is derived, the labels
a test conversation declares and the verdict for each further case are settled design (`ADR-042`
§ 3). They are written into no record, and are pinned by the suites of the cards that build the
checks: #1353 for the text-level forms, #1769 for the transcript-level ones. Every example below is
synthetic.

**The verdicts, in every form.** *Pass*. *Fail*, naming the limb and the words or the turn. *Not
determinable*, naming the missing input — a verdict of the predicate, not a failure to give one.
Whatever consumes these is held to this: a reported observation never changes a value's verdict or
a conversation's; and *not determinable* is never counted as a pass, and never as a fail of the
conversation — a consumer branches on it before it reads any count.

#### On the conduct's text — `OW-T`, `FB-T` and `WT`

**Inputs.** (i) `skills/trip-record/interview-conduct.md` — the shared rules and the rules only a
write-capable session adds. (ii) `templates/interview-card.md` — its copy of the shared rules, and
its give-back section. (iii) Each interviewable form's own conduct: the ask-prose below a guided
form's boundary, and the guidance quotes of a block-owned form.

**Limbs.** A limb suffixed `.P` is a prohibition: no sentence of the inputs directs or permits the
thing named, unless that sentence denies it. A limb suffixed `.E` is an existence limb: a sentence
the inputs must carry.

| Limb | Condition | Lands with |
|---|---|---|
| `OW-T.P1` — no licence | recording or confirming a value from a source other than the answering person's words: an example, an option they did not choose, another field, a guess, a default, assent alone | #1353 |
| `OW-T.P2` — closure | admitting into a recorded value a non-utterance that is not one of `A1` to `A5` | #1353 |
| `OW-T.E1` — the rule is stated | the shared rules say, in the same words in both carriers, that a recorded value is made only of what the answering person said | #1353 — it holds today, in shared rules 7 and 8 |
| `OW-T.E2` — the example sentences | once the rules admit an example, they also say that an example not taken up in the person's own words is never recorded, and that assent to one records nothing | #1330 |
| `FB-T.P1` — no licence | a second follow-up on a field; a follow-up after a skip, a decline, a stop or an empty answer; or a follow-up on a `PERSON`-class field in a spoken session | #1353 |
| `FB-T.E1` — the bound is stated | both carriers state the bound, with the numbers D3 states | #1330 |
| `FB-T.E2` — the exclusions are stated | both carriers state D3's exclusions | #1330 |
| `FB-T.E3` — the exit is stated | both carriers say what is written when a field's turns end | #1330 |
| `FB-T.E4` — retirement | the sentence carrying shared rule 2's cap is gone from both carriers | #1330 |
| `WT.P1` — no value in a prompt | a prompt carrying, quoting or offering a value outside clauses (a) and (b) of the restated W-test, or a value under the name of an example | #1353 |
| `WT.P2` — silence | treating silence as assent | #1353 |
| `WT.E1` — the example rule is stated | both carriers state the example rule: kinds and never a value, the occasions, the count, never the object of a confirmation | #1330 |

**Where the limbs land.** Every prohibition limb lands with #1353, over all three inputs. The
forms' own ask-prose carried, at `5d50eb5`, five known sentences that direct what the shared rules
already bar; so #1353's check covers the forms against a declared ledger of those sentences —
failing on an undeclared hit, and on a declared row that no longer trips — and #1330 rewords them.
Every existence limb lands with the change that makes it true, #1330, except `OW-T.E1`, which holds
today and lands with #1353. No arm is handed to a card that lands before the sentence it looks for.

| Check | | A sentence in the conduct | Verdict |
|---|---|---|---|
| `OW-T.P1` | ✗ | "If they like one of the examples, put it down." | fails — it records from an example |
| | ✓ | "An example they did not take up in their own words is never recorded." | passes — the same act, denied |
| `FB-T.P1` | ✗ | "If the answer is short, keep asking until you have enough detail." | fails — unbounded |
| | ✓ | "When an answer is thin you may ask one more question about it, and never a second." | passes — bounded in its own clause |
| `WT.P1` | ✗ | "Suggest a theme tag or two, reusing the archetype wording where it fits." | fails — a value the interviewer arrives at for the person's field |
| | ✓ | "give some kinds of need as examples … and say that they are only examples, never a list to choose from" | passes — an example, said as one |

The last pair is drawn from the guided forms' ask-prose as it read at `5d50eb5`.

#### On a conversation — `OW-C` and `FB-C`

**Inputs.** (i) The conversation as ordered turns, each with its speaker. (ii) Each recorded value
with its field — section, label and, in a repeat block, the unit — from the file, or from the block
a session that cannot write gives back. (iii) For each of the person's turns, silences included,
the fields it concerns and what it is for each. (iv) For each interviewer turn, the fields it puts,
its kind, and whether it gave an example. (v) The form — its labels, its heads and their lists, its
declared text and its computed lines — each field's class from `reference/data-model.md`, and the
marks the output class admits. (vi) Whether the session is spoken.

**Their scope.** These are checks for #1769's synthetic suite. They are **exact on an authored test
conversation**, where the fixture's author writes both sides and declares (iii), (iv) and (vi). On a
**generated** one, where the interviewer under test produces its own side, which field a turn puts
and whether it gave an example are judged labels: a verdict that rests on a judged label says so,
and a turn the check cannot see returns *not determinable*, naming what is missing. A label the
interviewer writes about its own turns is the interviewer under test grading itself, and is not an
input. On a real conversation nothing independent supplies (iii) and (iv), so both forms return
*not determinable* there — except that a recorded word found in none of the person's turns of a
complete transcript fails.

**`OW-C` — for each recorded value, with its field.** The value passes when it is an admitted
non-utterance on that non-utterance's own terms (`A1` to `A5`), or when every word of it occurs
among the words of the answering person's turns on that field, counted with multiplicity. A fail
names the words. *Order* and *example echo* are reported beside the verdict, as D2 states them.

| | Their turn on the field | Recorded | Verdict |
|---|---|---|---|
| ✓ | "I'd want my own room if it isn't too expensive." | "own room if it isn't too expensive" | pass — order kept |
| ✗ | the same | "own room if it's affordable" | fail — "affordable" is in no turn of theirs; it is the form's placeholder wording |

**`FB-C` — for each field, in one session.** All of these hold:

- at most one turn of the kind *follow-up* puts it, and across its section the follow-ups number at
  most two;
- no turn of any kind puts it after an uttered skip, decline or stop for it or for its section; no
  follow-up is put after an empty answer; and none on a field the file already answered when the
  session began;
- a follow-up does not repeat the ask in the same words, and carries no value but the person's own
  words, the field's label and an example as D1 bounds one;
- where the session is spoken and the field is typed `PERSON`, no follow-up puts it;
- a follow-up follows an answer taken as thin: **in an authored test conversation, a follow-up
  after an answer the fixture declares not thin fails**; in a generated one, whether the answer was
  thin is a grader's judgment, and the verdict says it rests on one.

| | The exchange, on a field asking about rooming | Verdict |
|---|---|---|
| ✓ | "How do you feel about rooming?" — "Share." — "You said 'share' — anyone in particular?" — "With Sam." | passes — one follow-up, after a taken answer, carrying only their word |
| ✗ | the same, then: "And would a twin or a double suit you both?" | fails twice — a second follow-up on the field, and, under the restated W-test, values that are neither theirs nor the form's |

### The terms this record fixes

Each is a term the milestone's other record may read.

1. **example** — a short illustration of the kinds of answer a question takes: it names kinds and
   never a value. Composed by the interviewer, or carried by the form's ask-prose for its section.
   Said as an example. Never an option.
2. **candidate value** — any value a prompt carries that is neither an option the form lists for
   the field being asked nor the answering person's own words in this session. A value said under
   the name of an example is a candidate value.
3. **the person answering** — the traveller; the operator, where an answer is relayed.
4. **put**, **first put**, **grouped ask** — an interviewer turn *puts* a field when it asks for
   that field's answer. A grouped ask is one question naming several fields, and it puts each one
   it names.
5. **a taken answer** — an answer the interviewer can record as it stands.
6. **follow-up**, and the turns it is not: **ask-on-doubt**, **member re-offer**, **silence
   re-offer**, **single re-ask**. The first three name turns `ADR-022` D5.6, D5.4 and D5.5 decide;
   this record names them and decides nothing about them but the exit in D3.
7. **the kinds of interviewer turn.** Those that put or concern a field: *ask*, *follow-up*,
   *ask-on-doubt*, *member re-offer*, *silence re-offer*, *asked-for* (a repeat, a clarification or
   an example the person asked for), *example* (an example turn on the interviewer's own initiative
   that rides no follow-up) and *confirmation*. Those that put no field: *decision point*, *style
   offer*, *disclosure*, *spoken-care offer*, *routing statement* and *give-back*. **The list of
   kinds that put or concern a field is closed.**
8. **thin answer** — the warrant for a follow-up; judged by a grader, never by a count.
   **Stuck** — the person says they do not know what to answer.
9. **the follow-up bound** — at most one follow-up a field in a session, and at most two a section.
10. **the turns of a field** (*a field's turns*) — the person's turns whose set holds the field,
    from its first put, or from the turn in which they volunteered it, to the write — or to the
    give-back, in a session that cannot write.
11. **recorded value**, and the **admitted non-utterances** `A1` to `A5`.
12. **the words limb** — D2's test; the **reported observations**, *order* and *example echo*; and
    the **verdicts**, *pass*, *fail* and *not determinable*.
13. **left open** — a field that ends a session neither answered nor skipped: its bracket stays.
14. **interview style**; **default interview style**; and the names `warm`, `brisk` and `gentle`.

**Read, not fixed:** *option*, *closed*, *open* (`ADR-023` D2.3, D2.4); *session* (`ADR-022` D1.2,
D3.2 — one form, and every count here is for one session); *spoken session* (D6.3); *skip*,
*decline* (D5.5, D2.4); *confirmation* (D5.1); *decision point* (D3.1).

**Not this record's:** rating, engagement record, return path, what comes back and who saves it.
The rating's ask is no field of a form, so D1's example rule and D3's bound do not reach it. A style
is a sound, so a style named beside a session says how the asking sounded and nothing about which
turns were taken.

## Consequences

**What this buys.**

- An interviewer may help someone answer — with an example of the kinds of answer, and with a
  further question when an answer is thin — under bounds a check can count.
- The rule that the engine never invents is stated, for a recorded value, as a predicate with a
  pass and a fail, and its admitted exceptions are a closed list.
- A follow-up is told apart from the turns `ADR-022` already requires, so none of those floors is
  spent by it or reachable from a style.

**Trade-offs, taken knowingly.**

- **The guard against leading is weaker than a form-only rule had.** An echoed example passes, and
  is reported (D2).
- **Styles differ by sound alone.** The slice that builds them (#1771) may find that thin.
- **The form's kinds may still come with the first ask**, where `#1765 X-1` recommends no example
  before a thin answer (inference). It stands because it is the one example device the operator had
  already ruled on, and it is confined to text the form's author wrote. A report of echoed examples
  running higher on fields asked that way would be the evidence against it.
- **Every number here is judgment** — the kinds in an example, a follow-up a field, the limit for a
  section — recorded as judgment (§ *Residuals*).

### The interim — what binds a session until the conduct is edited

1. **This record is addressed to the conduct's authors, and a session follows the conduct file.**
   From the merge that lands this record until the change that edits the carriers, that file is
   unchanged and binds as written.
2. **Every permission is a ceiling.** Conduct that gives no example and asks no follow-up conforms
   to this record.
3. **Every bound this record adds waits for the edit that states it.**

| Clause of this record | The conduct as it read at `5d50eb5` | Relation |
|---|---|---|
| A composed example, on request or once after a thin answer | no rule admits one; shared rule 2: a placeholder is never read out | the conduct is stricter; the permission waits for the edit |
| The form's kinds with the first ask | the durable form's must-haves step gives them (`14043ee`) | the same; nothing is withdrawn |
| One follow-up a field | no shared rule directs a follow-up | the conduct is stricter |
| The limit for a section | shared rule 2 caps a section's questions, first asks included; the trip form's own ask-prose already directs a sharpening question for each desire | shared rule 2 is stricter; that form's ask-prose is already looser, so a session following it through three desires exceeds the limit until the edit |
| The ask-on-doubt and the re-offers keep their own counts | shared rules 4, 6 and 9 | the same |
| A field left open | no rule states the exit | new; it waits for the edit |
| Own words — the words limb | shared rules 7 and 8 | the same rule, as a predicate; looser than `ADR-022` D5.2's manner on order alone |
| The restated W-test | the known sentences of the forms' ask-prose | already overridden by shared rules 3, 4 and 7 through shared rule 14; not made false by this record |
| An interview style | none exists | nothing to break |

So an interviewer following the conduct as it stands uses no permission this record gives, and can
exceed one bound it adds, in one corner, until the edit that writes the bound in.

### What this decision makes false elsewhere

| Surface | What changes | Who brings it into line |
|---|---|---|
| `skills/trip-record/interview-conduct.md`, shared rules 2, 3 and 7, and the card's copy of each | the cap goes; the example rule, the bound with its exclusions and exit, and the restated W-test are stated. Both carriers change together: `scripts/test-artifact-schema.sh` group `PC` fails the moment the texts differ | #1330 |
| The same file's write-capable rule on the skip, where it says a surviving bracket means nobody has asked | not true of a field left open, whose bracket survives although it was asked | #1330 |
| The style set, each style's line and the offer, in the conduct and on the card | written | #1771 |
| The forms' own conduct — the known sentences of the guided forms' ask-prose, and the trip-context form's declared phrase where the conduct says "a word" | reworded; `A2` is already worded for the text a form declares | #1330, its scope amended at its own planning; #1353 holds the ledger until then |
| The route that cannot write | neither `ADR-022` D6.3's care nor D3's speech clause is in what that route reads: the card carries the shared rules only | #1327 |
| `ADR-026` § 5's enforcement-strength cell for CH-2 | unchanged here; it moves when the check exists | #1353 |
| `reference/adr/README.md` | the index row for this record | the change that lands it |

### What is untouched

`reference/data-model.md` § *`ANSWERED()`* and the interview's read of an unstated value; the
artifact set and every schema; every command's grants and the command surface; the question set and
its order; every decision of `ADR-023`, `ADR-039` and `ADR-040`; and `ADR-022` D3.1, D4.3 and D4.4.
D1's example rule is about an interview prompt: `ADR-015`'s rule that a report line never carries a
candidate value is untouched, and so is `ADR-027`'s statement that CH-2's W-test holds for its own
view, which stays true of that surface.

### Reversibility

| What | Tier | Why |
|---|---|---|
| The decisions, before the conduct is edited to them | **CHEAP** | a record, revertible in one commit; no session behaves differently yet |
| The example bound, the follow-up shape and the two lists a style is held to, once slices are built on them | **MODERATE** | a record superseded in part can be superseded again, but the slices built on it follow it |
| The own-words predicate | **CHEAP** until a suite pins it, **MODERATE** after | the suite's fixtures encode it |
| The style names | **CHEAP** | product vocabulary |
| This record's number and file name | **IRREVERSIBLE** | numbers are never reused, and other records cite a record by its file |

## Residuals

Every residual has an owner that is a card or the operator.

| # | Residual | Owner |
|---|---|---|
| RS-1 | **Every ground but one is an inference.** An example's occasions and count, both follow-up numbers and the default style rest on inference; each names the experiment that would settle it, and none is planned | the operator, as a judgment recorded as one; read again when #1769's suite and #1330's signals report |
| RS-2 | **The own-words rule does not detect leading.** An echoed example passes, and is reported | #1769, for the report and for its rubric (`#1765 R-2`, `R-10`); the rating, through the milestone's other record and #1770 |
| RS-3 | **Whether an example names a kind or a value has no mechanical test** beyond D1's floor | #1769's grader (`#1765 R-2`) |
| RS-4 | **"Thin" has no mechanical test** | #1769 (`#1765 R-3`) |
| RS-5 | **A second follow-up worded as a doubt passes the count** wherever a turn's kind is a judged label | #1769 (`#1765 R-3`) |
| RS-6 | **A value that reverses meaning by deletion or by reorder passes.** The predicate guards words, not meaning | #1769, to say whether a rubric dimension grades it; the operator, if a rule is wanted |
| RS-7 | **The text-level checks' word lists, clause windows and engine**, and the ledger of the forms' known sentences | #1353 |
| RS-8 | **The test conversations' labels, the harness that derives a turn's kind, what a word is for a check, and the verdict for each further case** | #1769; the milestone's other record, if its engagement record carries labels |
| RS-9 | **Shared rules 2, 3 and 7, the card's copy, every existence limb but the one that holds today, and the default style's persona** — unedited here | #1330 |
| RS-10 | **The forms' known ask-prose sentences and the declared phrase**, and whether a one-off and an unanswered field must be told apart where a form writes the em dash for both | #1330 |
| RS-11 | **Where option text ends inside a headed bracket.** Shared rule 3 does not say whether an `e.g.` clause there is offered, and `ADR-023` D2.3 declined a grammar | #1330, for the rule's wording; the operator, if a grammar is wanted |
| RS-12 | **The style set's text**, each style's line, and whether *playful* is admitted | #1771; the operator for *playful* |
| RS-13 | **Speech-to-text.** A value faithful to a wrong transcription passes. And whether a compound joined or split is the same word is not settled here | #1327 for the first; #1769 for the second |
| RS-14 | **Whether a voice assistant can make `ADR-022` D5.5's re-offer after a silence at all** (`#1766 V-6`, unmeasured) | #1327 |
| RS-15 | **The spoken care is not in what the route that cannot write reads**, so neither it nor D3's speech clause reaches that route until a change writes them where it reads | #1327 |
| RS-16 | **Held cards quote text this record overtakes.** #1330 quotes D5.3 as a floor. #1353 quotes the W-test, and it and #1327 call `ADR-022` D6.3's confirmation a follow-up. #1769 and the epic's fourth criterion (#1205) say *subsequence*, which is stricter than D2's check. The epic's eighth criterion has a follow-up on a thin *or ambiguous* answer, where an ambiguous one gets the ask-on-doubt | each card, at its own planning |
| RS-17 | **The interim.** Shared rule 3 cites D5.3 while D5.3 carries a mark, from the merge that lands this record to the rule's edit | #1330 |
| RS-18 | **`ADR-026` § 5's enforcement-strength cell and residual paragraph**, and the order in which this record's mark there and the pending correction of that table's CH-3 row land | #1353 for the cell and the paragraph; the operator, who merges both, for the order |
| RS-19 | **The status-lag report the marks cause**: `ADR-022` and `ADR-026` are Accepted and cite this record while it is `Proposed` | the operator; the change that sets this record `Accepted` clears it |
| RS-20 | **A reorder, in a value written or a confirmation spoken, does not conform to `ADR-022` D5.1 and D5.2 and fails no check** | the operator, who reads the report #1769's suite produces |

## References

**The findings.** Each entry gives the card, the comment's id, its permalink, the time it was
created — equal to the time it was last updated — and the sha256 of its body, hashed with no
trailing newline.

- #1765, the interviewing-research finding, part 1 — comment `5985438567` —
  <https://github.com/cody-hutson/travel-planner/issues/1765#issuecomment-5985438567> —
  2026-10-04T23:07:42Z —
  `3e9cd81d9455d8fe0da9ab7c52accfed8ab0e50ea0943465b3bedd928462f60f`
- #1765, part 2 — comment `5985439675` —
  <https://github.com/cody-hutson/travel-planner/issues/1765#issuecomment-5985439675> —
  2026-10-04T23:07:50Z —
  `3b0970245838f0e8784b705a51921e0f7a0f1e03f421c748b252abc67d0fd81a`
- #1765, the corrections, which govern where they differ from parts 1 and 2 — comment
  `5986303962` —
  <https://github.com/cody-hutson/travel-planner/issues/1765#issuecomment-5986303962> —
  2026-10-05T00:57:45Z —
  `32c0d42e78ae07ebf1fab6073f89e127b0fe624f3d4dc7fcc257ba8982598fb4`
- #1766, the voice-mode finding — comment `5998506201` —
  <https://github.com/cody-hutson/travel-planner/issues/1766#issuecomment-5998506201> —
  2026-10-05T16:19:50Z —
  `8dea4146c211b54c41f729b9f9b24dda9d2bdc60f488228ebc3517d8a68f7b5e`

**The records.**

- [`ADR-022`](ADR-022-interview-session-model.md) — D5.3, superseded in part; D5.1, D5.2, D5.4,
  D5.5, D5.6 and D6.3, kept by name; D1.3, D1.4, D2.4, D3.1, D3.5, D3.6, D4.1, D4.3 and D4.4, read
- [`ADR-026`](ADR-026-channel-architecture.md) — § 5: CH-2's W-test, its first sentence superseded
  in part; the W-rule, the R-rule and the rest of that row, kept
- [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) — D2.3 and D2.4: the
  placeholder as the home of a field's option text, and the `closed:` and `open:` heads
- [`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md) — D1: where the shared conduct is
  authored
- [`ADR-040`](ADR-040-transcript-only-return-and-save.md) — D1: what a channel that cannot write
  gives back
- [`ADR-042`](ADR-042-accepted-record-growth.md) — § 3: settled design is never a record's
- [`README.md`](README.md) § *Convention* — the supersession-in-part form this record uses, and the
  sentence on when a supersession is recorded

**The files, and one commit.**

- `skills/trip-record/interview-conduct.md` and `templates/interview-card.md` — the shared rules, in
  both carriers
- `templates/traveler-intake.template.md` and `templates/person-intake.template.md` — the guided
  forms, and their own ask-prose
- `reference/data-model.md` — each field's class, read live
- Commit `14043ee` — the operator's ruling on the durable form's must-haves step, and the clause it
  added to shared rule 3

**The cards.** #1767, this record's; #1205, the epic. #1353, #1769, #1330, #1771 and #1327, which
read this record. #1768 and #1770, for what comes back beside the profile.
