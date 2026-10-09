# ADR-045: What comes back beside the profile — a rating asked after the give-back, an engagement record of identifiers and counts, a tagged return and a governed class, superseding ADR-040 D1 and ADR-022 D1.1 in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *interviewer becomes a conversation: the founding decision* milestone —
  its return card (#1768), cut from the interviewer epic (#1205) at that epic's refinement as the
  decision gate for the data half of the interviewer's conversation model. The operator rendered
  the decisions below at that card's Collective Review, in a first sitting and a confirm sitting,
  and ruled afterwards on what a pooled row counts where a section repeats a block. This record
  transcribes them.
- **What this record is.** A decision about **what comes back beside the profile after an
  interview, in what shape, and where it is kept**: how the traveller's rating of the interview is
  asked; what the engagement record — the interviewer's account of its own turns — may hold; how
  both come back from a session that can write and from one that cannot; the class that keeps
  them; and what the travel manager reads when a rating is low. It is addressed to whoever authors
  the interview card, the trip-record command and the data architecture.
- **What this record is not.** It decides no example rule, no follow-up bound and no rule about an
  interview style: those are [`ADR-044`](ADR-044-interview-conversation-conduct.md)'s, and every
  term used here for an interviewer turn or for an interview style is that record's, cited. It
  builds no class and edits no card, conduct, command, schema or specification:
  `templates/interview-card.md`, `skills/trip-record/interview-conduct.md`,
  `skills/trip-record/SKILL.md` and `reference/data-architecture.md` read after it as they read
  before, and a session follows them. It states rules, and carries no serialization, line grammar,
  file name, path pattern, reach-table row, schema or procedure for what it decides: that is
  settled design, pinned by the card that builds the class (#1770). And the *engagement record*
  named here is neither `engagement(t)`, the axis
  [`ADR-025`](ADR-025-engagement-model-over-time.md) defines, nor that record itself, which
  [`ADR-026`](ADR-026-channel-architecture.md) and an earlier `CHANGELOG.md` entry call by the
  same words.
- **The status flip is named here.** Moving this record from `Proposed` to `Accepted` is the
  operator's, taken in a change on `main` after the release that lands it merges, and it moves both
  halves of a two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md). `scripts/test-adr-conformance.sh` grades that the halves agree, and
  reports without failing an Accepted record that cites a `Proposed` one; nothing grades that the
  flip is made.

## Context

**An interview gives back the profile, and nothing that could explain a poor interview.**
[`ADR-040`](ADR-040-transcript-only-return-and-save.md) D1 has a channel with no write path return
one fenced block, carrying the form above its end marker *"and nothing below it"*, and whoever sent
the form saves it. [`ADR-022`](ADR-022-interview-session-model.md) D6.1 gives a session that can
write *"no output act at all"*: the file is the session. On neither route is the person asked how
the interview went, and nothing records what the interviewer did.

**The interviewer epic's refinement asks for both** (#1205): a rating asked at the end, which may be
skipped, and an account of the interviewer's side from which a low rating can be traced to which
questions, which follow-ups, which style and how long — and which is *"never a transcript"*. The
difficulty is the last clause. A record that carried the conversation would be a transcript by
another name; the no-repository route returns one block that somebody else saves; and a third-party
assistant's history is beyond the engine's reach (`ADR-022` D6.4).

**`ADR-022` weighed a stored record of what a person was asked, and refused it — for resumption.**
Its first choice rejected a stored cursor on reachability: *"A cursor recording what a person was
asked is person data at a new address, so `erase` must reach it"*, which adds a row to a reach table
that command's standing rules make total. It added a driver, *No new artifact class*, calling a
stored cursor *"a durable record of a person's interview progress"*, and D1.1 lists what a new class
would bring: a class id, a path pattern, a schema member, a row in the class enumeration, a
lifecycle, a publish posture, a witness, and a row in the `erase` reach table. What this record
keeps is not a cursor — nothing reads it to resume — but it is person data at a new address, and
the cost that option was rejected on is paid here and not avoided.

**The vocabulary is the conduct record's.** `ADR-044` fixes what an interviewer turn is called and
what an interview style is. This record reads those terms and counts with them; it defines none of
them again (§ *The terms this record fixes*).

**A session follows the card and the conduct file, and this record edits neither.** `ADR-040` D3
makes the portable interview card the one home of the contract for a channel with no write path, and
[`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md) D1 authors the shared conduct in
`skills/trip-record/interview-conduct.md`. This record says what their authors may write;
§ *Consequences* says what binds a session until they do.

### What the evidence says, and how far it goes

The decisions cite the voice-mode finding (#1766) and the interviewing-research finding (#1765),
read with its corrections. Each statement below is restated in this record's words, carries the
finding's own identifier, and says how far its source goes. § *References* locates each finding.

**One cell was measured, once.** The voice-mode finding is one run of one assistant — its cell
`claude-ios`, the Claude app's voice mode on iOS — with a scripted synthetic traveller
(`#1766` *Coverage*: derived, accepted with the record). Every other cell of its frame is
unmeasured. Its grades are text copied out (T) and operator-attested (A), and nothing in it is a
rate. The operator accepted the record incomplete: `#1766 Q2` and `Q5` are undetermined, and `Q4`
is uncoded by ruling.

**No rating was asked in that run, and no item of the finding codes anything about one.** So every
ground under D1 is the operator's judgment, informed by items that settle nothing by themselves.
**The same holds wherever a ground below rests on an item that is operator-attested, undetermined,
unmeasured, uncoded or inferred: it is the operator's judgment informed by that item, and no
decision here is presented as following from it.**

**On what comes back.**

- `#1766 Q3` — operator-attested. On the measured cell the finished form came back as text that
  could be copied, unprompted and not read aloud. Whether it came as one block or in pieces is not
  recorded.
- `#1766 Q3_fidelity` — T for the deviations; the rest not determinable. The returned block
  departed from the card's contract in several places. Whether it was fenced, whether the message
  held anything besides the block, and whether it came in pieces cannot be determined from the
  evidence.
- `#1766 V-3` — T. The block carried on past the end-of-profile heading with the form's guide,
  which the card told the assistant to leave out. So the one measured assistant has already put
  text where D3 puts the tagged return — the wrong text.
- `#1766 V-1` and `V-2` — T. An answered line came back as its unanswered placeholder, and lines
  the form computes came back blank. They show a give-back departing from a simpler contract than
  D3's.
- `#1766 cd6_outside_card` — not recorded. The one request outside the card, for something returned
  apart from the form, is not reported as made. Whether this assistant returns anything beside the
  form is unmeasured.
- `#1766 V-6`, and the `rule6_silence` limb of `Q2` — operator-attested; the limb is un-exercised.
  At a silence the assistant took no turn, so whether it makes any offer at a silence is
  unmeasured. It bears on what a silence at the rating ask costs, and on when the instruction to
  send the block back is given.
- `#1766 Q2` and `Q5` — undetermined. Whether the card is still being followed at the end of a
  session, which is where the tagged return, the rating ask and the rating's line all sit, is not
  determined. The run did reach the give-back (operator-attested).
- `#1766 Q4` — uncoded, by the operator's ruling. What a traveller can do about the assistant's
  copy of the conversation was not determined, and vendor-side retention is not observable.
- `#1766 V-7` — T. The returned block keeps the form's trip placeholder, which whoever saves it
  fills in: the save is where engine-side facts are added.
- The session's length is operator-attested, and no turn tally and no minute mark was kept (not
  settled). It bears on *how long*.
- `#1766` *Disagreement 4* — T. Most of the visible turns departed from the script, and the copy
  cannot separate the speaker's wording from the transcription. A number said aloud reaches the
  assistant as a transcription too.
- `#1766 V-8`, `V-10`, `V-11`, `V-14`, `V-15` and `V-16` — operator-attested, ungraded, and cited
  by identifier. They bear on how much a hand-off asks someone to carry (`V-8`), on how a prompt
  at a break and a closed set asked for directly land by voice (`V-10`, `V-11`, `V-14`), on
  questions asked for again (`V-15`), and on why a rating is wanted at all (`V-16`). `#1766 V-9`,
  of the same grade, bears on how many examples a question carries.

**On a rating said aloud.**

- `#1765 F-7` — **meets the finding's grade-B bar**; `COR-8` repairs one of its locators and leaves
  its bar status unchanged. People report fewer sensitive behaviours by voice than by text, with
  automated interviewers as well as human ones, and its mitigation is that a typed channel draws
  more candid answers. It is a finding about sensitive behaviours. **That it carries to a rating of
  the interviewer is an inference this record makes, and marks as one.**
- `#1765 F-3` — its speech effect is inference; strongest underlying grade A, with a construct
  transfer. A typed chatbot's ratings were not more positive than a web form's (grade A; typed, not
  spoken). People agree with what a question asserts more by telephone than face to face, and no
  included study measures that in voice against text. Its mitigation is to avoid yes-or-no and
  agree-or-disagree formats and to ask about the dimension directly.

## Decision drivers

- **The constraints `ADR-022` holds, held here too:** the engine never invents, on any modality;
  `Skip` stays valid and nothing pushes twice; the artifact set stays contained and closely
  maintained; and no new privilege is taken. The one this record engages is the third, and it is
  kept by a class inside the model, where a kept file outside the model would not keep it.
- **The driver `ADR-022` added — *No new artifact class* — is the ground of the decision this
  record supersedes in part.** It is given up as far as D0 says and no further.
- **The return is never a transcript.** It holds no word anyone said.
- **The profile is the primary output.** Nothing optional stands between the last answer and the
  give-back.
- **Nothing rests on a fence or on a position.** A return is found by what identifies it, or it is
  absent.
- **Nothing in the rule depends on an unmeasured assistant.** A return that does not come back
  costs the return and nothing else.
- **Settled design is not written into a record** (`ADR-042` § 3). The operator ruled that the
  detailed shape of each rule lives in no file of the release that lands this record.

## Options considered

Each choice was put to the operator at the Collective Review with the design's recommendation and
an independent review's. Where the operator ruled against the design, that is said.

### D1 — how the rating is asked

| Option | Verdict | Ground |
|---|---|---|
| Asked once, after the last question and **before anything is given back** — the first design's | rejected by ruling | On a channel where the answers exist only in the conversation, an optional question ahead of the give-back can stall the one output that matters, and `#1766 V-6` (operator-attested, un-exercised) leaves unmeasured whether an assistant takes any turn at a silence |
| **After the give-back, as a turn of its own** | **selected** | D1. Its cost — a rating given after the block needs a way back of its own — is met in D3 |
| At the end of each section | rejected | It multiplies the turn `#1766 V-10` bears on (operator-attested, ungraded), and a session then has as many ratings as sections with no rule for which one is the rating |
| **Whole numbers one to five, the two ends named** | **selected** | D1, as judgment: no measurement bears on the scale |
| Three named words | rejected | The low end is one member, so one cautious answer reads as low, and the words would need fixing in every interview style |
| Good or not | rejected | Half the scale is low |
| Nought to ten | rejected | Too many members to hold by ear, and more resolution than a handful of travellers supports |
| *Low* bound to the scale, at 1 or 2 — the first design's | not taken | A threshold that seldom fires makes the review silent; and bound to the scale it could not be moved without changing the scale |
| *Low* not fixed: every rating shown, and the reader names a threshold | not taken | No ground was recorded |
| **The rating alone** | **selected** | D1 |
| The rating, and a reason in the person's own words | rejected | Free text is a traveller answer in every sense: it needs the own-words rule, a class, a home and an erase reach of its own, on a record the epic says is never a transcript |
| A rating inferred when none is given — from skips, from length, from tone | rejected | It would be a statement the engine authors for a person, which `ADR-026` § 5's W-rule forbids on every channel |
| Asking again after a skip, in the same session | rejected | Nothing pushes twice |
| One rating a form, however many sessions fill it | rejected | It needs the interviewer to read what is kept, or the operator to say; and the rating's subject is the session |
| Every session on every form is asked | rejected | On a block-owned form the person answering is the operator, and where every answer is relayed the operator is the one answering too |
| No rating after a stop | not taken | The block is already given, and one skippable ask is not a push |
| Strictly one turn at the ask, with nothing offered again | not taken | No ground was recorded. The selected rule differs from the build card's "asked once" by one further offer |
| The ask treated as a closed field in full, its silence offer included | rejected | The form's block has already been given, so a silence there has nothing left to protect |
| Spoken only: the ask does not say the number may be typed | not taken | `#1765 F-7` informs the judgment that a typed number is more candid, by an inference marked as one |
| Not saying who reads the rating until after it is given | rejected | It would draw a more candid number by keeping from the person what they need to know to give it |
| The opening names the rating and the record, with no leave to decline; or the opening unchanged | not taken | The first leaves the person no say over a record that is, by inference, an account of how they responded (D2). The second rested on the rating being an answer the disclosure already covers, and that does not cover the record |
| A decline of the record taken at any time — the revised design's | rejected by ruling | Once the block is given or the entry written, nothing carries a later decline to whoever keeps the record |

### D2 — what the engagement record holds

| Option | Verdict | Ground |
|---|---|---|
| **A ledger by field, in a closed vocabulary, bounded by the field's class** | **selected** | D2 |
| A row for every field put, whatever its class — the first design's | rejected by ruling | A tally of the person's acts on a `PERSON`-class field is the row a reader can infer most from, and that class is the one the engine already treats with care |
| Totals for the session | rejected | They say how many follow-ups there were and not where, so they cannot identify the turns behind a low rating |
| The interviewer's turns, as text | rejected | A transcript by another name, which the epic rules out in terms; and it carries the person's words wherever the interviewer confirmed or followed up (`ADR-022` D5.1) |
| A line for every interviewer turn — its ordinal, its field, its kind | rejected | It is the skeleton of the whole conversation, longer to give back by voice, and its order adds nothing the epic asks for. Judgment: no measurement separates it from the ledger |
| One row a section, for every section | not taken | A weaker trace than the ruled grain, which pools only where a section holds a `PERSON`-class field |
| A pooled row holding the `PERSON`-class fields' turns alone, the section's other fields keeping rows of their own | rejected by ruling | Measured at `5d50eb5`, one of the sections that hold such a field holds exactly one, so that row would be the field's own tally under another name |
| A pooled row that says nothing of how many it pools | not taken | The operator ruled that it says how many |
| A pooled count that grows with each block a person filled | rejected by ruling | A count that tracked the number of a person's needs would be a fact about their answers, by inference |
| A field for how the session ended | rejected | It would be the mark `ADR-022` D1.2 declines to keep |
| An outcome for each field — answered, skipped or left open | rejected | A second home for a fact the profile owns |
| Minutes, or any clock time | rejected | A channel that cannot write has no clock the card can ask of an assistant, an estimated duration is an invented value, and an entry has one field list on every tier. That a session that can write could record minutes is a choice declined, not a constraint met |
| A count of confirmations | rejected | On a route that writes, nearly every taken answer is confirmed, so the count is the count of answers taken, which the profile already holds |
| A count of examples given, whichever turn carried them | not taken | A countable the conduct decisions did not fix |
| The field at which an interview style changed | rejected | It says at which question the person asked for a different manner |
| A kind of this record's own for a question said again | withdrawn | The conduct record's closed list already holds it |
| The rating as a field of the engagement record | rejected | The card's criterion that the record carries no traveller answer would then carry an exception in the sentence written to exclude one |
| The rating in a home of its own | rejected | A second home, for values that are never read apart, and a second erase reach |
| No per-field counts at all — the wider reading of the epic's eleventh criterion | not taken | The operator ruled the grain with the review's inferences in front of them; D2 says in terms what a count lets a reader infer |
| Another name for the engagement record | not taken | The name is the operator's across the epic, its cards and the plan gate; the header block says what it is not |

### D3 — how it comes back on each channel

| Option | Verdict | Ground |
|---|---|---|
| The form's block, then **a second fenced block** in the same message — the first design's | rejected by ruling | It rests on two fences surviving, and `#1766 Q3_fidelity` records the fence of the one returned block as not determinable |
| **One block; the return a tagged section below the end-of-profile heading** | **selected** | D3 |
| The engagement record in a second message | rejected | It puts the engagement record in a turn after the give-back, and whether a later turn is still on the card is `#1766 Q5`, undetermined. Under D3 a turn that does not come costs the rating only |
| Nothing returns on a channel that cannot write | rejected | Voice runs on such a channel, and the epic's refinement makes voice the primary channel. It is what the declared outcome leaves in force wherever a return does not come back |
| A different rule for each assistant | rejected | The operator chose a rule keyed to the tier at the plan gate, and only one cell has a measurement to write one from |
| **The rating as its own tagged line, after the block** | **selected** | D3. It amends the first sitting's ruling, which put the whole return in the block |
| The block given again, whole, with the rating in its return | rejected | It prints the form twice, and two blocks from one session can differ |
| The person tells the sender the number, recorded as relayed | not taken | No ground was recorded |
| No rating on a channel that cannot write | not taken | It applies both of the first sitting's rulings by giving the rating up there |
| The return taken whole or not at all — the first design's | rejected | It ties the rating to the engagement record, so a damaged record would discard a rating in its own closed set |
| The record states that a tag identifies the return, and the build names the token | not taken | The card, the save and the schema must share one literal |
| A session that can write records its ledger row by row as it runs | rejected | A row written as the session runs marks a session that was left, which `ADR-022` D1.2 declines to mark |
| A person-form return **copied into the store by the operator's hand** | rejected | No check, no pooling, and a second writer for the class |
| A person-form return **left in the saved file until a command next reads it and moves it out** — the revised design's | rejected by ruling | The review found that it takes lines out of a durable record, which no standing rule of the command admits; that it names no verb; and that until that read the return rests in the file unchecked and unpooled |
| **A person-form return handed to the save for the return alone** | **selected by ruling** | D3 |
| No return asked for on a form rooted in the people store | not taken | It gives up the return on the form that holds the most sensitive fields |

### D4 — where it is kept, and who saves it

| Option | Verdict | Ground |
|---|---|---|
| A sidecar in the trip's directory, **outside the artifact model** — the first design's | rejected by ruling | Declared in the data architecture it would have been a class its row did not call one; it pays most of what a class costs and stays outside the schema suite; and a kept file outside the model is neither contained nor closely maintained, which `ADR-022` holds as a constraint |
| Inside the profile's file, below its end-of-profile heading | rejected | The profile would differ with and without a rating; the file's declared writer is the traveller; a saved profile sent out again would carry the record with it; and the schema suite reads a filled profile whole, so a labelled line there is read as a field |
| **A governed class in the data model** | **selected** | D4 |
| Not kept: shown when it arrives, held nowhere | rejected | The card asks where it is kept, `erase` is to reach it, and a travel manager reading several returned forms over several days would have nothing to compare. It adds no person data at any address, which is its merit; the operator took the governed end |
| The trip log | rejected | `ADR-022` D6.5: the log is the decision register, and a traveller's answers are not decisions |
| A second file beside each profile, in the travellers directory | rejected | Every listing of that directory takes each file there for a traveller |
| A store of its own for entries | rejected | A further rooted store, with a signpost, a witness and a guard of its own, for a class that already has a root to sit in beside each form's file |
| Entries under a trip for a person-form interview | rejected | The interview verb writes nothing under a trip on a store-rooted form, and says why |
| Trips only: a person-form interview keeps nothing | rejected | It leaves half of intake outside the loop |
| One publish class for the whole class, `internal` — the revised design's | rejected by ruling | It puts under the people store a class weaker than every record beside it |
| One publish class for the whole class, `internal-hard` | not taken | The operator ruled that the publish class follows the profile an entry sits beside |
| One new verb for every write of the class | rejected | A change to the command surface |
| One file a root, holding every subject's keyed entries | rejected | A shared file from which `erase` must cut by key |
| The lifecycle `accumulate-append` | rejected | Nothing is deleted there, so `erase` would have to re-key |
| The provenance `human` | not taken | An entry's rows are acts, which is what `recorded` names (D4) |
| `erase` re-keys an entry to the trip's token | rejected | It keeps a per-field account of an erased person's interview under a pseudonym, for no use the plan has |
| A removal act the operator can call for any traveller | rejected | A new act on the command, and a standing rule |
| A return saved twice is kept twice | rejected | One session would count as two |

### D5 — how the travel manager reviews a low rating

| Option | Verdict | Ground |
|---|---|---|
| **The act that wrote it says what it kept, and the entry is read at its home** | **selected** | D5 |
| A new read verb of the trip-record command | rejected | A change to the command surface, which a required suite grades and the card does not name |
| A section of the report the travellers reconcile prints | rejected | It would make an agent a reader of interview data |
| A part of the trip site | rejected | The class is never rendered |
| A rule that acts on a low rating — asks the traveller again, or changes their interview style | rejected | Nothing pushes twice, and an interview style is the traveller's to choose |
| On a route that writes, the session says the rating and reads the record back at its end — the first design's | withdrawn | Reading the return back at the session's end sits close to the output act `ADR-022` D6.1 says such a session has none of, and it says the rating in front of its reader. The session confirms its writes and reports nothing else |

### The marks

| Option | Verdict | Ground |
|---|---|---|
| A second marker at `ADR-022`'s driver *No new artifact class* | rejected | A driver is not a decision |
| `ADR-022` D6.1's write-capable row superseded in part | rejected | Its reason is about answers handed back from a conversation; an entry holds none and is returned to nobody. It would be a further mark on that record in one release |
| `ADR-022`'s resumption decision superseded in part | rejected | Nothing of the class is read by the interviewer, and an entry has no field for how a session ended |
| A mark on `ADR-040` D2 | not taken | The operator read *"a returned block"* there as the form's block, so the return handed to the save writes none |
| A date for each mark, taken from its own commit | not taken | The operator confirmed one date for the release |

## Decision

### D0 — two decisions are superseded in part

**This record supersedes `ADR-040` D1 in part, as to what follows the end marker, and `ADR-022`
D1.1 in part, as to no new artifact class.** Every other decision of both records stands.

- **`ADR-040` D1.** D1 has a channel with no write path return one fenced block carrying the form
  above its end marker *"and nothing below it"*. It says so in its lead sentence and again in the
  paragraph that closes it. **What is superseded is that phrase.** Under D3 the block carries the
  end-of-profile heading and, below it, a tagged return; and after the block the rating follows as
  a tagged line of its own. **What stands:** that the form comes back as one fenced block, with no
  second block beside it; that above the end marker the block is what the target file would hold
  if each answer had been written into it as it was given; each bullet of D1; that record's D0;
  its D2, where *"a returned block"* is read as the form's block (D3), so D2 takes no mark; its D3,
  under which the return's contract goes on the card and nowhere else; and every consequence it
  states.
- **`ADR-022` D1.1.** D1.1's headline is a pair of sentences — *"Resumption state is DERIVED. No
  new artifact class is created."* — and the paragraph that closes it lists what is not created,
  ending *"no row in the `erase` reach table"*. **What is superseded is the second sentence and
  that list, as far as they reach beyond resumption state**: as far as they are read to say that
  the interview creates no artifact class and adds no reach row at all. **What stands:** the first
  sentence, whole; the inputs of the derivation; *"Nothing else is read and nothing is stored"*,
  said of resumption; that resumption state takes no class, no cursor and no frontmatter key; the
  rejection of O2, O3 and O4, each with its ground; and D1.2 to D1.5. The class D4 decides is not
  O2: it is no cursor, and nothing reads it to resume. The cost O2 was rejected on — a location
  `erase` must reach, and so a row in its table — is paid here and not avoided. That record's
  driver *No new artifact class*, its options table and the rows of its consequences table that say
  no class and no reach row are added are not decisions and are not marked; § *Consequences* names
  them.
- **`ADR-022`'s write-capable row and its resumption decision stand, and are named because this
  record sits close to both.** The row D6.1 gives a session that can write says *"there is no
  output act at all, because the answers were never held in conversation"*. Its reason is about
  answers handed back from a conversation: an entry holds no answer, is written by the session to
  its home, and is returned to nobody. Said plainly: the session does hold its own turn counts until its ending,
  which is the cadence that record rejected for answers. That is a choice (D3), taken so that
  nothing marks a session that was left. D1.1's *"Resumption state is DERIVED"* and D1.2's *"There
  is no abandon event and nothing marks one"* stand too: nothing of the class is ever read by the
  interviewer, on any tier; no entry is written for a session that is left or that ends on
  silence; and an entry has no field for how a session ended. Said plainly: that an entry exists
  shows a session reached one of the endings D1 names. It does not say which, and nothing reads it
  to resume.
- **When each takes effect.** The supersession of `ADR-040` D1 takes effect in the change that
  edits the card's § *Giving back the finished form* to this record; until then the card binds a
  session as it reads, and nothing is returned from the heading down. The supersession of
  `ADR-022` D1.1 takes effect in the change that adds the class to the data architecture; until
  then no class exists, and D1.1 reads true of the engine as built.
- **Why they are recorded before that, and the date each mark carries.** [`README.md`](README.md)
  § *Convention* says a supersession is recorded when it takes effect and not before. These are
  recorded ahead of it: the operator decided at this milestone's plan gate that the marks land in
  the release that lands this record. So each earlier record's `Status:` line carries a dated entry
  and each superseded text an inline marker. **A mark carries the release's one mark date, and not
  the date of its own commit: the operator-local calendar date of the first commit in the release
  that wrote a mark, which is 2026-10-09 (Friday).** The conduct record's marks and this record's
  were all written on that day, so here the rule and the commit dates agree; had the cards'
  changes been written on different days, this record's marks would still carry that date. It is
  when the supersession was recorded, not when it takes effect, and each entry points here for the
  condition and states none.

### D1 — how the rating is asked

**The rating is asked after the give-back, in one turn: a whole number from one to five, with the
ends named, and skipping is fine. Only the number the person said is recorded.**

1. **When.** On a channel that cannot write, after the form's block has been given back with the
   instruction to send it back. On one that can, after the session's entry has been written at its
   ending (D3). One turn. **A missing reply costs the rating only.**
2. **Which sessions.** A session in which a person answers for themselves on a guided form. Not on
   a block-owned form, where the person answering is the operator. Not where every answer of the
   session was relayed by the operator. The same sessions, and no others, make an entry at all.
3. **Which endings.** When the session ends because they finish, they stop, or nothing is left to
   ask. Never when a second silence ends it (`ADR-022` D5.5).
4. **The scale.** Whole numbers one to five. The names of its ends are words of the scale: the same
   in every interview style, so that ratings taken under different interview styles compare.
5. ***Low*, apart from the scale.** *Low* is 3 or under. It is a threshold for review and nothing
   else, and it can be moved later by re-reading kept numbers; the scale cannot. It is judgment:
   the one graded item that bears on it, `#1765 F-7`, points toward ratings shading upward when
   said aloud — by an inference — and reading a middling rating costs a minute.
6. **Typed, where the channel has text.** The ask says the number may be typed and not said. The
   interviewer does not say the number back; on a channel that returns text the person sees it in
   the line they are given.
7. **The rating alone.** No reason is asked for.
8. **What the ask says.** That it is the interview being rated and not the trip; the scale and the
   names of its ends; that skipping is fine; that the number may be typed; and, in a clause, who
   reads it — the person who sent the form, or on a route that writes, whoever keeps the files it
   writes to. Who reads it is also said before the first question (item 12), so it is never first
   heard after the answer.
9. **What may happen at the ask.** No example. No follow-up, and so no "why". Where the reply names
   no number, the numbers are offered again once, and then the rating is left unrated. A skip is
   taken at once. **A silence records nothing and is offered nothing, and it is not a silence
   `ADR-022` D5.5 counts**: the form's block has already been given, or the entry written, and the
   session has nothing left to protect.
10. **What is recorded.** The number the person said, as a digit or as its word; or a skip mark,
    where they uttered a skip; or nothing. Never a number inferred from words, tone or how the
    session went, and never the nearest number.
11. **One a session.** The rating's subject is the session it ends. A later session's ask is a
    different question, so it is asked whatever an earlier session's reply was. Nothing is asked
    twice inside one session.
12. **The opening sentence, and a decline of the record.** Before the first question the person is
    told, once, with the disclosure `ADR-022` D6.2 and D6.4 already require where the channel
    cannot write: that at the end they will be asked to rate the interview and may skip; and that
    a count of the interviewer's own turns, question by question, holding none of their words,
    goes with the rating to the same reader. **They may decline that record.** **A decline of the
    record counts only before the block is given or the entry is written.** Taken then, no
    engagement record is given back or written for that session, and a rating may still be given.
    It is an utterance of this record's own: it is not the decline of a field, which `ADR-022`
    D5.5 and the conduct record govern.
13. **An interview style** may change how the ask sounds, and never whether it is made, the scale,
    the names of its ends or what is recorded (`ADR-044` D4).

**Its permitted cases.** At the ask: the ask itself; the numbers offered again once, where the
reply names none; a skip taken. Nothing else — no example, no follow-up, no offer after a silence,
no second ask in the session, and no number said back. **Its inputs:** the reply at the rating ask.
**One worked example.** On a channel that cannot write, the form's block is given back with the
instruction to send it back, and the ask is put. The person says "four, I suppose": the rating's
line holds `4`. The person says "it was fine": the numbers are offered once more, they say "skip",
and the line holds the skip mark. The person says nothing: there is no line, and the block already
given is complete.

*Supersedes:* nothing.

### D2 — what the engagement record holds

**The engagement record holds identifiers and counts, and nothing else: one row for each field the
interviewer put, with a count for each kind of further turn it took there.** It is the
interviewer's account of its own turns. The rating is not part of it.

1. **The principle.** Every value in it is drawn from a closed set or is a count. The sets are the
   form's own text, for naming a field; names the conduct record fixes; names this record fixes;
   and whole numbers. Nothing in it is composed, quoted or paraphrased.
2. **What it holds, and why none of it is a traveller answer.**

   | | Holds | Why it carries no traveller answer |
   |---|---|---|
   | `EF-1` — the form | the form's own path and contract version, as its `intake-form` block spells them | It is the form's text, the same for every person |
   | `EF-2` — the channel tier | `W` or `T`, the names `ADR-022` D6.1 gives; set by the writer | It names the channel |
   | `EF-3` — the date saved | set by the writer when the entry reaches its home; never by a recipient's assistant | It is a date the engine supplies |
   | `EF-4` — the interview styles in force | in order, the name of each interview style the session used. Nothing is recorded for a change | Each is a name from the conduct record's set. Said plainly: a name other than the default interview style's shows the person chose it — a choice about the asking, not a value of any field. An interview style is a sound (`ADR-044` D4), so the names say how the asking sounded and nothing about which turns were taken |
   | `EF-5` — the ledger | one row for each field the interviewer put, in the order first put, with a count for each kind of further turn taken on it. A `PERSON`-class field has no row of its own (item 4) | A row's identifier is the form's section heading and label, as the form spells them. The kinds are names. The counts are numbers |

3. **The kinds counted.** Every kind in the conduct record's closed list of the kinds of
   interviewer turn that put or concern a field (`ADR-044` § *The terms this record fixes*,
   item 7), other than the pair it calls *ask* — which is what makes a row — and *confirmation*.
   This record cites that list and restates no other member of it. Said plainly, as the cost: an
   example that rides a first ask or a follow-up is not a turn of its own and is not seen, and an
   example given on request is counted inside the kind that list calls *asked-for* and is not told
   apart from a repeat. So no count here bears on `#1766 V-9`.
4. **A `PERSON`-class field.** Which fields are `PERSON`-class is read live from the `Class` column
   of `reference/data-model.md` § *Field Scope* — its classification table — joined on section
   and label as `ADR-022` D6.3 and that record's R8 read it. It is never read from a list of names
   in this record, the card or the save, so a field newly typed `PERSON` is covered with no edit.
   **A section that holds any `PERSON`-class field is one row for the section, pooling every field
   of it that was put, and saying how many it pools.** Where such a section repeats a block — the
   person form's needs section, one block for each need — **the count is of the labels the form
   prints for the section, and it does not grow with the number of entries a person gave**: a
   pooled row does not show how many needs a person listed. **The pooling is the writer's act, at
   the write.** A recipient's assistant holds no classification, so the section it gives back has
   a row for every field it put; the block around it holds those fields' answers themselves, so
   the rows add nothing to what is in transit. What rests in the class's home is pooled.
5. **What a count lets a reader infer, said so it can be seen.** Under *a traveller answer is a
   value of a field of a form*, the record holds none, and no word anyone said. It does hold
   something else. **Each counted kind is defined, in the conduct record, by what the person had
   just done**: a follow-up follows an answer the interviewer took as thin, a silence re-offer
   follows a silence or an unclear reply, and so for each kind in that list. **So a row is, by
   inference, an account of how the person responded at that field.** And it outlives the profile:
   an answer later taken back leaves the profile and not the entry. That is what "which
   follow-ups" costs. What bounds it is the grain as ruled, the pooling, that nothing is recorded
   for a change of interview style, and the person's leave to decline the record (D1).
6. **What it never holds.** A word the person said. A word the interviewer said: no question,
   example, confirmation or follow-up text. A value of any field of a form. The rating. A row of
   its own for a `PERSON`-class field. The field at which an interview style changed. A time of
   day, or a length in minutes. How the session ended. The person's name: their key is attached by
   the writer (D4), and a recipient's assistant never supplies it. A transcript, or any part of
   one.
7. **"How long"** is read off the ledger: how many fields were put, and how many further turns
   were taken. No clock time, on either tier. A channel that cannot write has no clock the card
   can ask of an assistant, and an estimated duration is an invented value; and an entry has one
   field list on every tier. That a session that can write could record minutes is a choice
   declined, not a constraint met. **The cost of item 4's count, as put to the operator with it:**
   for a section that repeats a block, "how long" understates the asking where a person gave
   several entries.
8. **The rating is held apart.** It is a separate value in the same entry, with its own rule (D1),
   its own provenance — a person's statement, where the engagement record is the interviewer's
   account — and its own acceptance (D3).
9. **What the record is evidence of.** The interviewer's own account of its own turns. On a real
   conversation nothing independent checks it, and on a channel that cannot write it is another
   assistant's account of itself. The travel manager reads it. It is never an input to the
   conduct record's checks on a conversation: an interviewer labelling its own turns is the
   interviewer under test grading itself, which that record refuses (`ADR-044` § *The
   predicates*).

**Its permitted cases.** A value of the record is a member of the set its field declares, or a whole
number; a row is a field's own row, or the one pooled row of a section that holds a `PERSON`-class
field. Nothing else is a value or a row. **Its inputs:** the form the entry names; and, for the
pooling, the classification, read live. **One worked example.** A session on the person form puts
the passport field and the other fields of its section, puts fields elsewhere, and puts nothing in
the needs section. The entry's ledger has a row of its own for each field put elsewhere, and one
row for the passport field's section, which says how many fields it pools and counts one silence
re-offer. Nothing in the entry says which of them the silence fell at. Had the session put the
needs section, that section's row would read the same whether the person listed one need or
several.

*Supersedes:* nothing.

### D3 — how it comes back on each channel

**One rule, keyed to the one observable `ADR-022` D6.1 branches on — whether the channel holds a
write path — and to nothing about the assistant.**

| Tier | How the return reaches its home |
|---|---|
| **W** — the session can write | Nothing is returned. At an ending D1 names, the session writes the entry — its engagement record — to the class's home; then it asks the rating, and a rating given or skipped is written into that entry. A session that ends on a second silence, or is left, writes no entry |
| **T** — no write path, and text can be returned | One fenced block, and no other block: the form as `ADR-040` D1 has it above its end-of-profile heading; that heading; and below it the tagged return, holding the engagement record. The instruction to send the block back is given with it. Then the rating ask. Then the rating, as a tagged line of its own, to be sent back with the block |
| **refuse** | No interview runs, so nothing returns |

1. **The order.** The form's block is given back first, on every tier that gives one back, with
   the instruction to send it back; the rating is asked after it. **The instruction to send the
   block back is given with the block, and never later than the ask.** Where the session can
   write, the entry is written first and the rating asked after it. A missing reply costs the
   rating only. **The give-back never waits on the rating.**
2. **One block, and the rating beside it.** At the first sitting the operator ruled one block,
   with the return a tagged section below the end-of-profile heading. At the confirm sitting the
   operator amended that ruling: **the tagged section inside the block carries the engagement
   record, and the rating travels beside it** — it comes back as its own tagged line, after the
   block, found by its tag.
3. **The tag.** The return is identified by a tag: a literal token of its own, unlike every tag
   and heading a form carries — **`interview-return`**. The card, the save and the class's schema
   share that one literal. Measured against the fence tags in use at `5d50eb5`, it collides with
   none.
4. **Found by its tag, never by its position.** Finding the return never depends on where in the
   handed-over text it sits, on any fence surviving, or on the end-of-profile heading being
   present. A return that arrives merged into the form's lines, or after the block, or with its
   fence lost, is still found or still absent by its tag.
5. **Its place, as the card asks for it:** below the end-of-profile heading, which the block now
   carries. Never above it. On the trip form the last line above that heading is one the merge
   finds by its place and not by a label.
6. **What the save does with it.** The save finds the tagged part, checks the engagement record
   against its closed vocabulary, pools it (D2), attaches the tier, the date and the subject's
   key, writes the entry, and says what it kept. **It never touches the profile's merge on the
   return's account**: the merge is never changed, delayed or refused for it, and nothing of the
   return is ever written into the profile's file.
7. **No line of the return has the shape of a form's field line.** The schema suite's label reader
   reads a filled profile whole, and takes a bullet that opens with a bold label and a colon for a
   field wherever it stands. The return's lines are never of that shape, so that neither that
   reader nor the merge can take one for an answer, whatever file it ends in.
8. **The rating and the engagement record are accepted apart.** The engagement record is taken
   whole or not at all. The rating is taken when it is in its own closed set, whatever becomes of
   the record. **One being absent or off its grammar does not discard the other.** The save says
   which it kept; a refusal names a line by its position and echoes nothing of it.
9. **The declared outcome.** *Absent* — no tag is found: the profile is saved exactly as today,
   nothing of the return is saved, and the save says the return did not come back. *Damaged* — a
   part fails its check: that part is not saved, and the other is. *More than one in what was
   handed over* — parts that read the same are one; parts that differ are not saved, as the save
   already refuses a returned block carrying more than one `intake-form` block. **In every case
   the traveller is not asked again.** What the traveller does instead: nothing is asked of them.
   They may tell the sender how it went, and the engine records no rating from that telling.
10. **What the card may ask of any assistant.** Only what a conversation alone supplies: the
    fields it put, a count of its own turns on each by kind, the interview styles it used, and the
    number the person said. No time, date or duration, nothing about the device or the app, and no
    name.
11. **A person-form interview, on a channel that cannot write.** The operator saves the person
    record by hand, as today (`ADR-040` D2), and hands the returned text to the save **for the
    return alone**. The save finds the tagged part, checks it, pools it and writes the entry. **It
    writes nothing of the record.** *"A returned block"*, in D2's *"no rule of that command admits
    a verb to write a returned block into the store"*, is read as the form's block, so that
    decision stands and takes no mark. Measured at `5d50eb5`, every `PERSON`-class field is on
    that form, so this is where the pooling does its work on such a channel.
12. **For each assistant the voice-mode finding measured.** That set is one cell, `claude-ios`.
    For it, run once: the form's block came back as copyable text, unprompted (`#1766 Q3`,
    operator-attested), with deviations (`#1766 Q3_fidelity`, T) — among them text below the
    end-of-profile heading that the card told it to leave out (`#1766 V-3`, T). **That a tagged
    return comes back below that heading, and a rating's line after the block, was not
    exercised**: the one request outside the card is not reported as made (`#1766
    cd6_outside_card`), so for this cell the rule is stated and not shown. No other cell was
    measured; for each the rule is stated and shown for none (§ *Residuals*). **Where the return
    does not come back, on this assistant or any other, the declared outcome is what happens: the
    profile is saved as today, and the traveller does nothing more.**

**Its permitted cases.** What is handed to the save holds a return that is found and kept; found
and kept in part; found more than once; or absent — each with the outcome item 9 declares, and in
none of them a different profile. **Its inputs:** the text handed to the save; the form. **One
worked example.** A returned block arrives with its fence lost and its tagged return after the
form's lines. The save finds the return by its tag and keeps the entry, and the profile's merge
writes what it would have written had no return come. Had the tagged section been damaged and the
rating's line sound, the engagement record would not be kept and the rating would, and the save
would say so, naming the damaged line by its position.

*Supersedes:* `ADR-040` D1 in part (D0).

### D4 — where it is kept, and who saves it

**What comes back is kept as a governed class in the data model: one writer, a lifecycle, a publish
class, a schema check and an erase row.** This record decides the class. Its schema, its file's
name, its path in each root and its reach-table rows are the build's (#1770).

1. **A class in the model.** Personal data about one person's interview sessions on one form.
   Never rendered, never published, never read by an agent, and never read by the interviewer.
   **The class table carries a row for each root an entry is kept in** (item 3).
2. **One writer.** The `/trip-record` command, and nothing else: no agent, no other command, no
   hand. It writes through the verb that conducts the interview where the session can write, and
   through the verb that saves a returned block where it cannot. The write is stated once, and
   both cite it. That is the shape the class table already gives a class the operator reaches
   through several verbs of one command.
3. **Its home, by one rule.** **An entry is kept in the root the interview's own file is rooted in
   — a trip's directory or the people store — beside that file and never inside it.** The rooting
   is the read the interview verb already makes of the form's own frontmatter. A trip-form
   interview's entry is under that trip's directory. A person-form interview's entry is under the
   people store's root. It sits where no existing listing of that root reads it as a traveller
   file or a person record, and no new store root is opened.
4. **Only beside its subject's file.** An entry is written only where the file its interview
   filled exists in that root, and it is keyed by the key that root already uses: the traveller's
   canonical key on a trip, the person's id in the store. The writer attaches the key. A
   recipient's assistant never names anybody.
5. **Its grain.** One file for each subject in a root, holding that person's entries. So removing
   one person's entries is removing one file, no file holds more than one person's key, and a
   re-save is checked inside one person's file.
6. **Lifecycle and provenance.** `persist-mutable`: a file updated in place that survives every
   re-run, from which a subject's rows go when the subject goes. `recorded`: its rows are acts —
   turns taken, a number given — that nothing upstream can reconstruct. Said plainly inside that:
   the rating is the person's own statement, and on a channel that cannot write the engagement
   record is another assistant's account of itself.
7. **Its publish class.** **An entry takes the publish class of the profile it sits beside.** As
   `reference/data-architecture.md` § 1.1 read at `5d50eb5`, a trip's traveller file is `internal`
   and a person record is `internal-hard`; so the row for a trip's root takes the first, and the
   row for the people store's root the second.
8. **Retention.** An entry is kept as long as the file it sits beside. It is never carried to
   another trip or root, and archiving a trip changes nothing in it.
9. **What `erase` does.** It removes every entry of the subject, in each root, and leaves no
   tombstone: nothing in the plan rests on an erased person's entries, and in the store a token
   would be a pseudonym that survives across trips — the ground on which the reach table's row for
   the group store removes and does not substitute.
10. **The reach `erase` has, stated as reach and not as totality.** In the store there is no
    precondition: `erase` resolves the person's id directly. On a trip, an entry has exactly the
    reach of the traveller file beside it. Discovery is the read of that file's `person:` key, so
    `erase` reaches the entries of a traveller who is linked, or whose trip the operator names to
    the run. For a traveller who was never linked, no `erase` runs. For a trip a person was
    unlinked from, discovery does not resolve it, and the residual scan matches a name where an
    entry holds a key, so nothing shows it. In both cases an entry is removed as the traveller
    file is: by the operator's hand, or with the trip's directory (§ *Residuals*).
11. **Saved twice, and what a rating's line joins.** An entry that reads the same as one already
    held for that subject — the writer's date aside — is named as already held and not written,
    as the merge already does for a repeat unit. Sessions that truly read alike count once; that
    is the accepted cost. **A rating's line joins the entry of the session it ends** (D1,
    item 11): handed over with a return, it is written into that return's entry, and a rating
    that arrives for an entry held without one is taken. **A rating that arrives alone is never
    dropped as a repeat**: the already-held rule is not applied to a rating by itself. Which
    entry a rating's line joins when it is handed over apart from its block, and more than one
    entry is held without a rating, is not decided here (§ *Residuals*).
12. **What nothing here reaches.** The copy in a recipient's assistant, and the message a returned
    block travelled in. That is `ADR-022` D6.4's residual, unchanged: the same class at the same
    boundary, since that history already holds the whole conversation.

**Its permitted cases.** An entry is written by the command, beside its subject's file, in the root
that file is rooted in; it is removed by `erase`, by the operator's hand, or with the directory
that holds it. Nothing else writes, moves or removes one. **Its inputs:** the form's own
frontmatter, for the rooting; the subject's file, for the key; the subject's entries already held,
for the already-held rule. **One worked example.** A traveller is interviewed on the trip form in
one session and again in a later one, each from a channel that cannot write, and the sender saves
each returned block. The subject's file of entries sits beside that traveller's file in the trip's
directory, keyed by the traveller's canonical key, and holds an entry for each session; it is
`internal`, as the profile beside it is. Handing the first block's text to the save again writes
nothing: that entry is named as already held. When the traveller is linked and that person is
erased, the file of entries goes, and no tombstone is left.

*Supersedes:* `ADR-022` D1.1 in part (D0).

### D5 — how the travel manager reviews a low rating

**The travel manager reads the entry at its home and, beside it, the profile. No verb is added, and
a rating gates nothing in the engine.**

1. **What is low.** D1's threshold: 3 or under.
2. **What they read.** The rating; that session's engagement record; and, beside it, the profile,
   which is where they see what came back answered, skipped or left open. Nothing else. The engine
   holds no transcript, and this record makes none a review surface.
3. **Where.** On a channel that cannot write, the save says in its closing report what it kept
   and, where the rating is low, says so. On one that can, the session confirms its writes as it
   confirms any write and reports nothing else: it does not read the rating or the record back.
   The review is at the entry's home, a plain-text file of the class. No new verb is needed. The
   cost, said plainly: on a route that writes, nothing prompts the travel manager to look.
4. **What they can change.** The conduct: the shared rules, or a form's own ask-prose. Only
   through a change whose pull request records the result of the conduct's synthetic suite
   (#1769). **A rating is a reason to open a change, never a change.**
5. **What they cannot change.** The rating: no verb edits it. The profile, on the strength of a
   rating. An interview style for a traveller: the conduct record makes the interview style the
   traveller's to choose.
6. **What they can do with no change at all.** Resume the interview over what the profile leaves
   un-asked. Use another route for that traveller. Talk to them.
7. **A rating gates nothing in the engine.** No verb blocks, re-plans or asks again on a rating or
   on a record. It is one of the signals a later conduct pass is graded on (#1330), and that
   pass's threshold is its own to declare: *low* here is the review's.
8. **A limit, named.** On a route that writes, the session runs at the travel manager's own
   terminal, so a rating given there is given in front of its reader.

**Its permitted cases.** A low rating is read, and may be acted on outside the engine or through a
change to the conduct; nothing in the engine acts on it. **Its inputs:** the entry; the profile
beside it. **One worked example.** A returned block is saved and its rating's line holds `2`. The
save's closing report says what it kept and that the rating is low. The travel manager opens the
entry: the ledger shows the further turns taken on each field put, and the profile beside it shows
which of them came back skipped or left open. They may talk to the traveller, resume the
interview, or open a change to the conduct. Nothing in the engine acts on the number.

*Supersedes:* nothing.

### The terms this record fixes

1. **a traveller answer** — a value of a field of a form: what a person says in reply to a
   question the form asks, as it is or would be written into that field.
2. **the return** — what comes back beside the profile: the rating, and the engagement record.
3. **the rating** — the person's reply to one question no form asks: a whole number on the scale,
   or a skip.
4. **the scale**, the **names of its ends**, and ***low*** — whole numbers one to five; the words
   that name its lowest and its highest number, which are part of the scale; and the threshold for
   review, 3 or under, which is not.
5. **the rating ask** — the one turn in which the rating is asked. It puts no field.
6. **the opening sentence** — what the person is told, before the first question, about the rating
   and the engagement record. It puts no field.
7. **a decline of the record** — the person's refusal of the engagement record for that session.
   It is not the decline of a field.
8. **the engagement record** — the interviewer's account of its own turns in one session, in
   identifiers and counts.
9. **the ledger**, and **a pooled row** — the engagement record's rows, one for each field put; and
   the one row kept for a section that holds any `PERSON`-class field.
10. **an entry** — one session's return as kept: its engagement record, and its rating where one
    was given.
11. **the tag** — the literal token by which the return is found: `interview-return`.

**Read from the conduct record, and restated nowhere here** (`ADR-044` § *The terms this record
fixes*): *put* and *first put* (its item 4); *follow-up*, and the turns it is not (item 6); the
kinds of interviewer turn, and the closed list of those that put or concern a field (item 7);
*example* (item 1); *the person answering* (item 3); *left open* (item 13); and *interview style*,
*default interview style* and the names it gives the interview styles (item 14). A *give-back*, a
*disclosure* and a *confirmation* are kinds that item 7 names, used here in its sense. The rating
ask and the opening sentence put no field; that record closes only its list of the kinds that put
or concern one, so they are this record's to name.

**Read from earlier records:** *field*, *section*, *repeat unit*, *closed* and *guided form*
(`ADR-023`); *block-owned form* (`ADR-024`); *session*, the tiers *W* and *T*, *spoken*, *skip* and
the endings (`ADR-022`); a field's *class* (`reference/data-model.md`). The *trip form* and the
*person form* are the guided forms `templates/traveler-intake.template.md` and
`templates/person-intake.template.md`.

**What the conduct record left to this one.** Its paragraph *Not this record's* says the rating's
ask is no field of a form, so its example rule and its follow-up bound do not reach it: D1 states
what may happen at the ask. Its residual `RS-2` names the rating among what reads the asking: D1
and D5 decide it. Its residual `RS-8` asks whether the engagement record carries labels: it
carries counts by kind, as the interviewer's own account, and is never an input to that record's
checks (D2). And that record's D4 says a silence at the offer of an interview style is not a
silence `ADR-022` D5.5 counts; D1 says the same of a silence at the rating ask.

**Not this record's:** the example rule, the follow-up bound, and what an interview style may
change.

## Consequences

**What this buys.**

- A low rating can be traced to what the interviewer did, without the conversation leaving the
  traveller's control.
- The return is found by a tag, so nothing rests on a fence or on a position, and a return that
  does not come back costs nothing but itself. The profile is the same with it and without it.
- What is kept is a governed class — one writer, a schema check, an erase row — where a kept file
  outside the model would have had none of them.

**Trade-offs, taken knowingly.**

- **A row is, by inference, an account of how the person responded**, and it outlives the profile
  (D2).
- **`ADR-022`'s *No new artifact class* is given up in part**, and what that record listed as the
  price of a class is paid.
- **The row for the people store's root is `internal-hard`**, so the set of classes that must not
  reach a page in any form gains a member.
- **On a route that writes, the session holds its own turn counts until its ending**, and a
  session that ends on silence, or is left, leaves no rating and no entry. The sessions most worth
  reading are the ones this loop sees least.
- **"How long" understates the asking on a section that repeats a block**, and a pooled row does
  not identify the turns behind a low rating on its own section.
- **The scale, *low* and the endings are judgment.** No measurement bears on them, and *low* rests
  on one inference.
- **The rule for a channel that cannot write is stated beyond the evidence**: it rests on one
  operator-attested observation and one assumption. The declared outcome is what keeps a wrong
  assumption from costing more than the return.

### The interim — what binds a session until the card, the command and the data architecture are edited

1. **This record is addressed to the authors of the card, the command and the data architecture,
   and a session follows the card and the conduct file.** Until they are edited a session asks for
   no rating, gives back one block with nothing from the heading down, and keeps nothing.
2. **Nothing this record decides is owed before those edits.** A session that gives back the
   form's block alone conforms to `ADR-040` as written and meets this record's declared outcome;
   an engine with no such class conforms to `ADR-022` as written.
3. **From the merge that lands this record until those edits, `ADR-040` D1 and `ADR-022` D1.1 each
   carry a mark for something not yet built.** Each mark says so by pointing here, where the
   condition is stated once.

| Clause of this record | The surface as it read at `5d50eb5` | Relation |
|---|---|---|
| A rating is asked, after the give-back | no sentence in either carrier mentions one | new; it waits for the edit |
| The block carries its heading and a tagged return below it | the card returns nothing from that heading down | the card is stricter, and binds until the edit |
| Above the heading the block is exactly what `ADR-040` D1 has | the same | the same; nothing is withdrawn |
| An entry is written at a session's ending | the interview verb has no output act | new; it waits for the edit |
| A class holds the entries | the class enumeration is closed without it | nothing to hold until it exists |
| `erase` reaches the class | no such location exists | nothing to reach until it does |
| A count for each kind of further turn | the carriers define no follow-up, no composed example and no interview style until the conduct is edited to `ADR-044` | until then such a count is nought and no interview style but the default is named; each kind's name enters a session's instruction in the change that defines the kind |

So a session following the files as they stand uses nothing this record gives, and breaks nothing
it says.

### What this decision makes false elsewhere

| Surface | What changes | Who brings it into line |
|---|---|---|
| `templates/interview-card.md`, its shared rules and § *Giving back the finished form* | the opening sentence and the rating ask are stated; *"Everything above the end-of-profile heading, and nothing from that heading down"* is no longer the contract, because the block carries that heading and the tagged return below it; the closing line that tells the person to send the block back is given with the block and, after a rating, names the rating's line too; the tagged return's contract is written there and nowhere else | #1770 |
| `skills/trip-record/interview-conduct.md` | the opening sentence and the rating ask, in the same words as the card's — `scripts/test-artifact-schema.sh` group `PC` fails the moment the carriers' shared rules differ; and its write-capable rule that nothing is held in conversation that the file does not hold gains a clause, because the session holds its count of its own turns until its ending | #1770 |
| `skills/trip-record/SKILL.md` § `## interview <form> [<target>]` | *"This verb has no output act"* stays true of a block and of answers, and gains a clause: the ending writes an entry | #1770 |
| The same file, § `## profile <name>` | its sentence that a returned block is merged "and nothing else is written" is no longer the whole of it, because the save also writes the entry; the passage that refuses a block carrying no `intake-form` block, or more than one, gains the return's step and says the return never stops the merge; its `Reads:` ceiling gains purposes — the handed-over text, for the tag, and the subject's file of the class, for the already-held rule; and it gains the branch that takes a store-rooted form's returned text for the return alone | #1770 |
| The same file, its standing clause | the write of an entry under the people store's root needs a standing rule of its own, since no standing rule admits that write today; and removing a subject's file of entries is a deletion its erasure rule does not yet list | #1770 |
| The same file, § `## erase <person-id>` | the reach table gains the class's rows, its stated tally moves with them, and the schema suite's arm that grades the tally moves too | #1770 |
| `reference/data-architecture.md` §§ 1 and 1.1, and the sections that state a class's lifecycle, provenance and publish class | the class's rows, one for each root, and every count, heading, identifier range and member list that moves with them — among them § 5.1's sentence naming the `internal-hard` classes as an exact set, which gains the row for the people store's root, and § 1's sentence on which classes are not per-trip | #1770 |
| The records that quote that § 5.1 sentence, or call a class its last member — `ADR-010`, `ADR-016`, `ADR-025`, `ADR-026`, `ADR-027` and `ADR-029` | each states the set as it stood when it was written | the operator, for whether any of them is corrected; #1770 names them when the set moves |
| `reference/schemas/`, and a witness under `examples/` | the class's schema, and its witness | #1770 |
| `scripts/validate-artifacts.sh` and `scripts/test-artifact-schema.sh` | the validator's class-heading constant, and the suite's arms over the class table and the reach table | #1770 |
| `ADR-022` § *Consequences*, *What this buys* — its rows for `reference/data-architecture.md` § 1.1 and for the `erase` reach table | they say what D1.1 bought — no new artifact class, and no new location — and stop being true of the engine once the class exists | nothing is owed: a record is marked at its decision, and the marker at D1.1 points here |
| `reference/adr/README.md` | the index row for this record | the change that lands it |

### What is untouched

**The hand-off set.** It is `ADR-023` D4.1's, and this record adds no file to it and removes none:
the return's contract goes on the card, which is a member already. Whether the set should be
leaner — what `#1766 V-8` bears on, operator-attested and ungraded — is not decided here; it is
#1327's to raise, from runs that start with the set.

**The profile.** The same answers produce the same profile with a return and without one. Nothing
of the return is written into the profile's file, and `reference/data-model.md`
§ *`ANSWERED()`* and its classification are read and not changed.

**The decisions beside this one.** Every decision of `ADR-044`, `ADR-039` and `ADR-023`.
`ADR-040` D0, D2 and D3. In `ADR-022`: D1.2 to D1.5; D3.2, under which one session covers one form,
so an entry is one session's; D5.1 and D5.2, since an entry holds no value and confirms none; D5.4,
read by analogy at the rating ask — the number named, never the nearest; D5.5, since nothing is
written on a silence, at a field or at the ask; D5.6; each row of D6.1; D6.2 to D6.5, the
disclosure among them; and D6.3, which D2's pooling reads and does not change. `ADR-025`'s definition of
*engaged* on what the engine holds and never on what a traveller did: neither a rating nor an
entry is an input to `engagement(t)`, and no floor is added. `ADR-026`: no further channel is
admitted — the return crosses as the form's block does, in the sender's hands — and its W-rule is
why no rating is ever inferred.

**The command surface.** No verb is added, and no grant changes.

### Reversibility

| What | Tier | Why |
|---|---|---|
| The decisions, before the card, the command and the data architecture are edited to them | **CHEAP** | a record and the marks that point at it, revertible together; no session behaves differently yet |
| The scale, once ratings are kept | **MODERATE** | ratings on different scales do not compare |
| *Low* | **CHEAP** | a threshold, moved by re-reading kept numbers |
| What the engagement record holds, once entries are kept | **MODERATE** | a value added later is a new permitted case, and so a new decision |
| The return's shape on a channel that cannot write | **MODERATE** | the card, the save and the class's schema share it |
| The class, once entries exist on users' machines | **EXPENSIVE** | they sit in directories this repository cannot reach or repair |
| This record's number and file name | **IRREVERSIBLE** | numbers are never reused, and other records cite a record by its file |

## Residuals

Every residual has an owner that is a card or the operator. The numbers are the design's, kept so
that a readiness input and this table name one thing by one number; a number missing from the run
is a residual a ruling overtook.

| # | Residual | Owner |
|---|---|---|
| RR-1 | **Every cell of the voice-mode finding's frame but one is unmeasured.** D3's rule is stated for each and shown for none | the operator, who set the scope to one cell |
| RR-2 | **`#1766 Q2` and `Q5` are undetermined.** They bear on whether the card is still followed at the end of a session — which is now where the tagged return, the rating ask and the rating's line all sit | #1327 |
| RR-3 | **`#1766 Q4` is uncoded.** What a traveller can do about the assistant's copy of the conversation — the return included — was not determined | #1327 |
| RR-4 | **No candidate workaround was recorded for `#1766 V-1` to `V-5` and `V-7`.** `V-3` changes character: the measured assistant put the form's guide below the heading, where the return now goes. The guide carries no tagged line, so the save finds no return in it and it stays inert | #1327 |
| RR-5 | **That an assistant gives back a tagged return below the heading, and a rating's line after the block, is an assumption.** It is first observed when the save is built on it | #1770 |
| RR-5b | **The same, on a real assistant** | #1327 |
| RR-6 | **The entry is a self-report**, and on a channel that cannot write it is another assistant's. On a real conversation nothing checks it | the operator |
| RR-7 | **A session that ends on silence, or is left, has no rating and no entry.** Where the session cannot write this is a limit; where it can, it is chosen (D0, D3) | the operator |
| RR-8 | **The scale, *low* and the endings rest on no measurement**, and *low* on one inference | the operator; read again when the conduct pass graded on the rating reports (#1330) |
| RR-9 | **A number said aloud may be transcribed as another word.** Narrowed by the leave to type it, and by the line the person can read | #1327 |
| RR-11 | **No dependency edge holds the card that builds the class behind the synthetic suite its checks join** (#1769) | #1770, at its own planning |
| RR-12 | **The build card's stated blast radius and reversibility are overtaken.** It describes a change contained to the interview's ending and the save path; it builds a class, with a row in each root | #1770, at its own planning |
| RR-13 | **Nothing says which conduct produced a rating.** The card carries no revision of its own, so ratings from before and after a change to the conduct cannot be told apart | #1770 |
| RR-14 | **The interim.** From the merge that lands this record, `ADR-040` D1 carries a mark while the card returns nothing from the heading down, and `ADR-022` D1.1 carries one while no class exists | #1770 |
| RR-15 | **`.approvers`, `.approvals`, `.change-confirmed` and `.published-itinerary`, in a trip's directory, are in no row of the data architecture's closed enumeration**, measured at `5d50eb5`. The class decided here does not add to that | the operator; outside this record's scope |
| RR-16 | **The message a returned block travels in, and the assistant's own history,** hold the return and are in no row of the reach table — the same class at the same boundary as the answers (`ADR-022` D6.4) | #1770 |
| RR-17 | **A run of `erase` interrupted before the class's row** leaves the subject's file of entries standing, and the next run reads the trip as already erased — the residue the reach table already states for the approval sidecars' row | #1770 |
| RR-18 | **The name.** *Engagement* is used in more than one sense across the records | the operator |
| RR-19 | **Held cards quote text this record overtakes.** The build card says the rating is asked once, at the end, which differs from D1 by one further offer; that the record comes back beside the profile on the route that writes, where nothing comes back and it is written; and that the record identifies the interviewer turns behind a rating, which a pooled row does not do for its own section. The epic's eleventh criterion says no traveller answer beyond what the profile holds, which D2 reads under a stated definition | #1770, at its own planning; the operator, for the epic's criterion (#1205) |
| RR-20 | **The status-lag report the marks cause**: `ADR-040` and `ADR-022` are Accepted and cite this record while it is `Proposed` | the operator; the change that sets this record `Accepted` clears it |
| RR-21 | **Whether a session that ends on silence gives the form back** is not stated on the card; and a non-reply at the rating ask is a case its runs should include | #1327 |
| RR-22 | **What the checks on this record's rules need declared**: the reply at the rating ask; a traveller who rates low; a returned block in each case of the declared outcome; and a person-form conversation that puts a `PERSON`-class field | #1770 |
| RR-23 | **An unlinked traveller's entries.** No `erase` runs; they go as the traveller file goes, by the operator's hand | the operator |
| RR-24 | **Entries on a trip a person was unlinked from** are unreached unless the operator names the trip, and nothing shows them: the residual scan reads a name, and an entry holds a key | #1770 |
| RR-25 | **A return carried into a file by hand.** Where a hand-save — of a person record, or of a trip profile saved outside the save — copies the tagged return in with the rest, it rests in that file unchecked and unpooled. Nothing this record decides takes it out | #1770 |
| RR-26 | **The pooling runs where the writer runs.** In transit, and in an assistant's history, the section has a row for every field put — beside those fields' answers. And the spoken care of `ADR-022` D6.3 is not in what that route reads (`ADR-044`'s `RS-15`) | #1327 |
| RR-27 | **Candour.** A rating given aloud, or at the travel manager's own terminal, may shade upward (`#1765 F-7`, carried by inference) | the operator |
| RR-28 | **`ADR-022`'s driver, its options table and its consequences rows** say *no new artifact class* with no marker | the operator, as accepted |
| RR-29 | **A class with a row in each root.** Its `trip:` value is a slug in one root and the cross-trip sentinel in the other, and its publish class differs between them | #1770 |
| RR-30 | **On a route that writes, nothing prompts the travel manager to look** at a low rating | the operator |
| RR-32 | **Which entry a rating's line joins when it is handed over apart from its block**, where more than one entry is held without a rating. A line handed over by itself names no session | the operator |
| RR-33 | **The return's lines as they are written**: how a row names a field where a form repeats a block or prints a line with no label; what carries the tag once a fence is lost; where a tagged part ends; and whether the rating's line carries the same token. Settled design, held to D3's rules | #1770 |
| RR-34 | **The pooled count at its edges**: whether *the labels the form prints for the section* reads a label once, or once for each block the form ships; and what it reads where a printed label was never put | the operator |
| RR-35 | **What a person hears before the first question now has parts from more than one record** — the disclosure `ADR-022` requires, the offer of an interview style, and this record's opening sentence — and no record bounds their total | the operator |

## References

**The findings.** Each entry gives the card, the comment's id, its permalink, the time it was
created — equal to the time it was last updated — and the sha256 of its body, hashed with no
trailing newline.

- #1766, the voice-mode finding — comment `5998506201` —
  <https://github.com/cody-hutson/travel-planner/issues/1766#issuecomment-5998506201> —
  2026-10-05T16:19:50Z —
  `8dea4146c211b54c41f729b9f9b24dda9d2bdc60f488228ebc3517d8a68f7b5e`
- #1765, the interviewing-research finding, part 1, which holds `F-3` and `F-7` — comment
  `5985438567` —
  <https://github.com/cody-hutson/travel-planner/issues/1765#issuecomment-5985438567> —
  2026-10-04T23:07:42Z —
  `3e9cd81d9455d8fe0da9ab7c52accfed8ab0e50ea0943465b3bedd928462f60f`
- #1765, the corrections, which govern where they differ from part 1 and hold `COR-8` — comment
  `5986303962` —
  <https://github.com/cody-hutson/travel-planner/issues/1765#issuecomment-5986303962> —
  2026-10-05T00:57:45Z —
  `32c0d42e78ae07ebf1fab6073f89e127b0fe624f3d4dc7fcc257ba8982598fb4`

**The records.**

- [`ADR-040`](ADR-040-transcript-only-return-and-save.md) — D1, superseded in part; D0, D2 and D3,
  kept by name
- [`ADR-022`](ADR-022-interview-session-model.md) — D1.1, superseded in part; D1.2, D3.2, D5.4,
  D5.5, D6.1, D6.2, D6.3, D6.4 and D6.5, read; its residual R8, for the join the classification is
  read by
- [`ADR-044`](ADR-044-interview-conversation-conduct.md) — the terms this record reads, the list of
  kinds it counts by and the names of the interview styles; D4; its residuals `RS-2`, `RS-8` and
  `RS-15`
- [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) — D4.1, the hand-off set; and
  the form's terms
- [`ADR-024`](ADR-024-form-contract-writer-boundary.md) — the block-owned form, on which no rating
  is asked and no entry is made
- [`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md) — D1: where the shared conduct is
  authored
- [`ADR-042`](ADR-042-accepted-record-growth.md) — § 3: settled design is never a record's
- [`ADR-025`](ADR-025-engagement-model-over-time.md) — `engagement(t)`, which the engagement record
  is not
- [`ADR-026`](ADR-026-channel-architecture.md) — § 5: the W-rule
- [`ADR-029`](ADR-029-group-approval-return-and-threshold.md) — the approval sidecars, the
  precedent the rejected sidecar was modelled on
- [`ADR-012`](ADR-012-people-library.md) — the people store, and the erasure reach its command
  carries
- [`README.md`](README.md) § *Convention* — the supersession-in-part form this record uses, and the
  sentence on when a supersession is recorded

**The files.**

- `templates/interview-card.md` — the card, and its § *Giving back the finished form*
- `skills/trip-record/interview-conduct.md` — the shared conduct, and what a write-capable session
  adds
- `skills/trip-record/SKILL.md` — § `## interview <form> [<target>]`, § `## profile <name>`,
  § `## erase <person-id>` and its standing clause
- `reference/data-architecture.md` — §§ 1 and 1.1, the class enumeration; and the sections that
  define a lifecycle, a provenance and a publish class
- `reference/data-model.md` — § *Field Scope*: each field's class, read live
- `templates/traveler-intake.template.md` and `templates/person-intake.template.md` — the guided
  forms

**The cards.** #1768, this record's; #1205, the epic; #1767, the conduct record's. #1770, which
builds what this record decides; #1327, #1330, #1771 and #1769, which read it.
