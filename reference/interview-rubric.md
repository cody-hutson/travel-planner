# The interview rubric

What a grader reads one interview conversation against. Each dimension is one row below: what the
grader observes in the transcript, the finding it traces to, where a decision record settles the
point, the mechanical check it cites, and its pass level. The rubric grades the interviewer's side
of a conversation and nothing else.

**Where the dimensions come from.** They are the rubric outline of the conversation-conduct
finding, `#1765 § 6`, under its ids and names. Each traces to the finding's items its row names,
**read with the corrections first**: the finding's corrections comment supersedes parts of it, and a
cell lists, beside each item, every correction whose heading names that item (`COR-n · #1765
<item>`). Where `ADR-045` decides a point
(`reference/adr/ADR-045-interview-conversation-conduct.md`), the dimension follows the record, and
the record's column names the decision.

**What it cites and does not hold.** The admitted non-utterances `A1`–`A5` are `ADR-045` D2 item 4's
table, and the kinds of interviewer turn are its term 7. This rubric cites both by name and holds
neither list, so a change to either is made in the record and read here unchanged.

**Who reads it.** A grader. No interviewer reads this file: no verb's `**Reads:**` line names it, and
no conduct surface — the conduct file, the interview card or a form — cites it. Group `RB` of
`scripts/test-artifact-schema.sh` holds that, with the shape of this file.

## The dimensions

| Dim | Dimension | Pass level — `MET` when | `NA` when | Traces to, corrections first | Where the record decides | Check it cites | Residual taken up |
|---|---|---|---|---|---|---|---|
| `R-1` | Open first | every field's first put is open, or offers only the field's own listed options, quoted | the conversation puts no field | `T-3` (`COR-17`); `F-1` (`COR-11`, `COR-19`) | shared rule 3; `ADR-022` D5.3–D5.4; `ADR-045` D1 item 4 — a form's own kinds may come with the first ask | — | — |
| `R-2` | No offered values | no turn carries a value that is neither a listed option of the field asked nor their words; every example names more than one kind, within D1's occasions and count | the interviewer puts no field and gives no example | `F-1` (`COR-11`, `COR-19`); `F-2` (`COR-23`, `COR-24`); `X-1` (`COR-12`, `COR-16`, `COR-17`, `COR-21`) | `ADR-045` D1, items 1–5 and 8 | `OW-C`, with its echo report; `WT.P1` on the conduct | `RS-2` — leading: the grader reads the echo rate; `RS-3` — kind against value: the grader's judgment |
| `R-3` | Follow-up discipline | each follow-up follows an answer judged thin, refers to their words, and stays inside D3's bound and exclusions | the conversation holds no follow-up | `T-4` (`COR-18`); `X-2` (`COR-10`, `COR-15`) | `ADR-045` D3 item 4: an answer in doubt is not thin and gets the ask-on-doubt, so the finding's *thin or ambiguous* is graded as thin here, and ambiguity is graded under `R-7` | `FB-C` | `RS-4` — thin; `RS-5` — a second follow-up worded as a doubt: the grader reads each doubt question and judges whether it asks for more |
| `R-4` | Declines respected | a skip or decline is taken at once, and the field is never put again | the person utters no skip and no decline | `F-5` (`COR-13`); `F-2` (`COR-23`, `COR-24`) | `ADR-022` D5.5; `ADR-045` D3 item 2 | `FB-C` bullet 2 | — |
| `R-5` | Silence handled | a silence gets exactly one neutral re-offer naming answer, skip and stop, and no value or example goes into it | the person is never silent | `T-5` (`COR-14`); `F-1` (`COR-11`, `COR-19`) | `ADR-022` D5.5; `ADR-045` D1 item 2 — never an example into a silence | — | — |
| `R-6` | Turn economy | one question a turn, or the one grouped ask a form's ask-prose directs, and no more options in a turn than the field's own list | the interviewer asks nothing | `F-4` (`COR-7`, `COR-17`); `T-5` (`COR-14`); `S-3` (`COR-4`, `COR-5`, `COR-17`) | — | — | — |
| `R-7` | Clarification without content | a clarification carries no value, and an answer in doubt gets the ask-on-doubt | the person asks for no clarification and gives no answer in doubt | `T-6`; `F-8`; `S-2` (`COR-2`, `COR-3`) | `ADR-045` D1 item 7; `ADR-022` D5.6 | — | — |
| `R-8` | Confirmation economy | a confirmation holds only their words, the label and words that carry no value, and an example is never its object | the interviewer makes no confirmation | `T-7` (`COR-17`) | `ADR-022` D5.1, D6.3; `ADR-045` D1 item 5, D2 item 7 | — the `RS-21` order report is read, and fails nothing | `RS-21` |
| `R-9` | Cumulative load | follow-ups stay within the follow-up bound, `ADR-045` term 9, and a section transition carries no extra ask | the conversation holds no follow-up and crosses no section | `X-2` (`COR-10`, `COR-15`); `F-6` | `ADR-045` D3 | `FB-C` bullet 1 | — |
| `R-10` | Listening without endorsement | an acknowledgement neither approves the content nor restates it with added words | the interviewer makes no acknowledgement | `T-1` (`COR-20`); `F-7` (`COR-8`) | `ADR-045` D4 item 4; `ADR-022` D5.2 | — | — |

## Pass levels

Each dimension takes one value for each conversation:

- **`MET`** — its pass level holds at every occasion the conversation gives it.
- **`NOT MET`** — some occasion breaks it. The grade cites the turn.
- **`ND`** — the transcript cannot settle it. `ND` is never counted as `MET`.
- **`NA`** — the conversation gives it no occasion, and the grade says which, from the row's `NA`
  column.

The levels are binary judgments per dimension, never a scale or an average.

## The conversation rule

- A conversation's grade is **`PASS`** when every dimension is `MET` or `NA` and none is `ND`.
- **A mechanical check's fail** on the conversation makes the dimension citing that check
  **`NOT MET`**, unless the operator's adjudication rules on that fail.
- **A mechanical check's `ND`** on the conversation — a compound or typography reading on a
  generated value — makes the dimension citing that check **`ND`**, unless the operator's
  adjudication rules on that `ND`. Such a conversation therefore grades **`ND`, never `PASS`**, and
  `ND` is never counted as a pass (`ADR-045`).
- Both routes are the same as for a disputed dimension. `R-2`, `R-3`, `R-4` and `R-9` cite their
  checks by id.

## Not graded

Each of these is left to the operator, and the rubric says why:

- **`RS-6` — a meaning reversed by deletion or reorder.** No item of the finding grounds a test of
  meaning, and every dimension here must trace to one. `ADR-022` D5.1 rejected meaning as a test
  because reviewers disagree on it. It stays with the operator, if a rule is wanted.
- **`R-6`'s *nothing before the core question*.** No `ADR-045` decision and no check reaches it, and
  `ADR-045` D4 lets an interview style vary what is said around a question.
- **`R-8`'s *implicit confirmation by default*.** No record decides it, so it stays the grader's own
  reading, never a dimension's pass level.
