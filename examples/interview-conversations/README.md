# Interview conversations

Synthetic test conversations of an interview, each graded by the conversation checks `OW-C` and
`FB-C` that `reference/adr/ADR-045-interview-conversation-conduct.md` § *On a conversation* states.
They test the checks, so every check's verdict on one of them is known before it runs.

**Provenance.** Every traveller, name and answer here is invented for the suite. No real profile,
person, group or transcript is an input to any file in this directory, and none may become one.

**Two kinds of file.** An **authored** conversation has both sides written by its author, who
declares every label and states the verdict each check must give. A **generated** conversation is
produced by the interviewer under test, its labels assigned by an independent grader, and every
verdict on it is reported as resting on judged labels. The generated conversations and their grade
arrive with #2199; the ones here are authored.

## How to read a file

A file is plain text, one physical line to a record: a header of `key: value` lines, then the
turns — `T<n> I | …` for the interviewer and `T<n> P | …` for the person answering — each with the
labels beneath it, then `--- record` and the values the conversation wrote, each `V <field> = <value>`,
and the author's stated verdicts, each `X OW-C <field> = …` or `X FB-C <field> = …`. A field is named
`<section> › <label>`, with `#<unit>` in a repeat block. The grammar, what each label means, and how
each check reads them are stated in group `CF`'s banner in `scripts/test-artifact-schema.sh`, which
pins them; this file cites them and does not restate them.

## The set

Every file here is declared below, and group `CF` holds the fence and the directory to each other
both ways, each file's header to its row.

```interview-conversation-fixture
# <conversation> <origin> <form> <spoken> <traveller code>
af-trip-typed                      authored  templates/traveler-intake.template.md  no  AF
te-person-typed                    authored  templates/person-intake.template.md    no  TE
sk-trip-typed                      authored  templates/traveler-intake.template.md  no  SK
ds-person-spoken                   authored  templates/person-intake.template.md    yes DS
gs-trip-spoken                     authored  templates/traveler-intake.template.md  yes GS
of-person-typed                    authored  templates/person-intake.template.md    no  OF
q01-follow-up-then-silence         authored  templates/traveler-intake.template.md  no  TE
q02-reoffer-doubt-follow-up        authored  templates/traveler-intake.template.md  no  GS
q03-closed-no-member               authored  templates/traveler-intake.template.md  no  TE
q04-spoken-person-doubt            authored  templates/person-intake.template.md    yes DS
q05-needs-none                     authored  templates/person-intake.template.md    no  TE
q06-two-turn-value                 authored  templates/traveler-intake.template.md  no  AF
q07-style-offer-silence            authored  templates/traveler-intake.template.md  no  GS
q08-assent-to-example              authored  templates/traveler-intake.template.md  no  TE
q09-follow-up-with-example         authored  templates/traveler-intake.template.md  no  AF
q10-skip                           authored  templates/traveler-intake.template.md  no  SK
q11-delete-only                    authored  templates/traveler-intake.template.md  no  AF
q12-stuck-left-open                authored  templates/traveler-intake.template.md  no  TE
q13-follow-up-after-none           authored  templates/person-intake.template.md    no  TE
q14-skip-at-follow-up              authored  templates/traveler-intake.template.md  no  SK
owc-check                          authored  templates/traveler-intake.template.md  no  AF
owc-cross                          authored  templates/traveler-intake.template.md  no  AF
fbc-check                          authored  templates/traveler-intake.template.md  no  TE
fbc-cross                          authored  templates/traveler-intake.template.md  no  TE
rs21-reordered-confirmation        authored  templates/traveler-intake.template.md  no  AF
rs22-silence-then-unclear          authored  templates/traveler-intake.template.md  no  GS
rs22-unclear-then-silence          authored  templates/traveler-intake.template.md  no  GS
qa-two-field-follow-up             authored  templates/traveler-intake.template.md  no  TE
qa01-follow-up-reoffers-member     authored  templates/traveler-intake.template.md  no  TE
rs13-joined                        authored  templates/traveler-intake.template.md  no  AF
rs13-split                         authored  templates/traveler-intake.template.md  no  AF
a4-relayed-value                   authored  templates/traveler-intake.template.md  no  AF
a3-position-pick                   authored  templates/traveler-intake.template.md  no  TE
unlabelled-complete                authored  templates/traveler-intake.template.md  no  AF
seam3-spoken-desire                authored  templates/traveler-intake.template.md  yes AF
case-a2-not-empty                  authored  templates/person-intake.template.md    no  GS
case-word-from-other-field         authored  templates/traveler-intake.template.md  no  AF
case-folds-and-variants            authored  templates/traveler-intake.template.md  no  AF
case-example-echo                  authored  templates/traveler-intake.template.md  no  TE
case-assent-recorded               authored  templates/traveler-intake.template.md  no  TE
case-reversal-by-deletion          authored  templates/traveler-intake.template.md  no  AF
case-default-member                authored  templates/traveler-intake.template.md  no  TE
case-spoken-none                   authored  templates/person-intake.template.md    yes DS
case-skip-withdrawn                authored  templates/traveler-intake.template.md  no  SK
case-asked-for-turns               authored  templates/traveler-intake.template.md  no  TE
case-repeat-units                  authored  templates/traveler-intake.template.md  no  AF
case-answered-before               authored  templates/traveler-intake.template.md  no  TE
case-follow-up-after-answer        authored  templates/traveler-intake.template.md  no  AF
case-person-spoken-follow-up       authored  templates/person-intake.template.md    yes DS
case-put-after-skip                authored  templates/person-intake.template.md    no  SK
case-single-re-ask                 authored  templates/traveler-intake.template.md  no  TE
case-second-follow-up-as-doubt     authored  templates/traveler-intake.template.md  no  TE
case-directed-follow-up            authored  templates/traveler-intake.template.md  no  AF
case-follow-up-per-field           authored  templates/person-intake.template.md    no  TE
```
