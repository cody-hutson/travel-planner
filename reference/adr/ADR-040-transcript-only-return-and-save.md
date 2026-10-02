# ADR-040: What a transcript-only channel returns, and who saves it — superseding ADR-022 D6.1's tier-T row in part

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *one interviewer, any conforming form* milestone. At that milestone's
  Collective Review the operator ruled that the change the milestone makes to
  [`ADR-022`](ADR-022-interview-session-model.md) D6.1's tier-T row is a change of decision, not a
  correction of a claim. This record is that decision, written where the row can point at it.
- **What this record is.** A decision about **what a channel with no write path gives back, and
  who saves it**.
- **What this record is not.** It decides no conduct and no session behaviour, which stay
  `ADR-022`'s; where the shared conduct is authored is
  [`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md)'s. It decides no part of the
  form contract, and it changes no grant, no command surface and no artifact class. The disclosure
  `ADR-022` D6.2 and D6.4 require of tier T is unchanged and is not decided here.
- **The status flip is named here, because nothing grades it.** Moving this record from `Proposed`
  to `Accepted` is the operator's, taken at this milestone's close, and it moves both halves of a
  two-artifact state: the `Status:` line above, and this record's `Status` cell in
  [`README.md`](README.md).

## Context

`ADR-022` D6.1 branches the modality contract on one observable: does the channel hold a write path
to the artifact? Its tier-T row reads, as predicate, *"no write path, but the channel can return
text the traveller can save"*, and, as contract, *"the contract the forms already ship: one
markdown code block carrying the profile and nothing below its end marker. This is route 3,
unchanged and not dropped."*

The contract the forms shipped told the assistant to leave nothing bracketed, to delete the unused
repeated blocks, to write the computed `Overlap` field empty, to fill in the frontmatter's trip
placeholder and a durable-record token, and to tell the traveller where to save the file. The same
record's own decisions forbid most of that to an interviewer on any tier, and the milestone's
criteria forbid the rest: a traveller with no repository holds neither the trip's directory name
nor a place to save into. Moving the contract off the forms and onto the portable interview card,
`templates/interview-card.md`, therefore changed what it says and whom it tells to save the
result. That changes what the row decides, so it is recorded here rather than written into the
row as a correction.

## Decision drivers

- **A returned block is a file the engine resumes.** Once saved, it must read the way a
  write-capable session would have left it, so that `ADR-022` D1.4's resume asks exactly what
  nobody asked, and nothing else.
- **`ADR-022`'s behaviour decisions bind an interviewer on any tier.** A skip is heard and never
  inferred (D5.5), a spare unit is em-dashed rather than deleted (D3.3, D3.6), and a computed field
  is never asked (D3.5).
- **The recipient holds files, not repository facts** (`ADR-023` D4.2). Nothing they are asked to
  type can be a fact only the repository holds, and the trip's directory name is one.
- **The save is the sender's act.** The recipient has no repository to save into, so the
  instruction to save is addressed to whoever handed the form on.

## Options considered

| | O1 the forms' shipped contract, moved onto the card unchanged | O2 the file a write-capable session would leave, saved by the sender | O3 the shape alone, the rest left to each form |
|---|---|---|---|
| A field nobody asked | reads as skipped | **reads as un-asked** | unstated |
| A repeat unit nobody reached | deleted | **left as the form ships it** | unstated |
| A computed field | written empty | **left as the form ships it** | unstated |
| The frontmatter | filled in by the recipient, with a trip name they do not hold | **left as the form ships it; the save fills it** | unstated |
| Who saves | the recipient, into a repository they do not have | **the sender** | unstated |
| A saved block resumes correctly | no — its skips and its un-asked fields read alike | **yes** | unknown |
| Verdict | reject | **selected** | reject |

**O1 is rejected on the record's own decisions, not on taste.** Leaving nothing bracketed writes a
skip nobody uttered, which D5.5's first prohibition forbids, and it erases the difference D2.4
draws between un-asked and declined. Deleting the unused blocks is, in D3.3's own words, addressed
to a hand-filler. And a trip name typed by a recipient who was told it, or guessed it, passes the
frontmatter check whichever trip it names. **O3 is rejected because it hands the same questions to
whichever assistant the recipient uses**, with nothing to make two of them answer alike.

## Decision

**D0 — This record supersedes `ADR-022` D6.1's tier-T row in part: that row's predicate cell and
its contract cell.** Every other part of D6.1 stands — the one observable the modality contract
branches on, the tier-W row, the refuse row and the rejections beneath the table — and so does
every other decision of `ADR-022`.

**D1 — Tier T returns what the target file would hold if each answer had been written into it as
it was given, above the end marker and nothing below it.** In particular:

- **A field nobody asked keeps its bracketed placeholder**, the un-asked state and never the em
  dash — `ADR-022` D5.5's first prohibition, and the difference D2.4 draws.
- **A repeat unit stays.** A unit given an entry is filled, a label skipped inside it takes the em
  dash, a declined unit is em-dashed on each of its labels, and a unit nobody reached stays as the
  form ships it — `ADR-022` D3.3 and D3.6.
- **A field the form computes stays as the form ships it** — `ADR-022` D3.5, and D1.2's seed,
  which writes that line once and never again.
- **The frontmatter and the `intake-form` block stay exactly as the form ships them**, and the save
  fills in what the frontmatter asks for — `ADR-022` D2.5, which requires the seed to substitute the
  trip placeholder, and `ADR-023` D4.2, under which the recipient holds no repository fact.
- **The block goes back to whoever sent the form**, and saving it is that person's act, not the
  recipient's — the milestone's criterion that no instruction the recipient must follow resolves a
  repository path, and that the save instruction is addressed to the sender.

The shape is unchanged: one fenced block, carrying the form above its end marker and nothing below
it, returned by a channel that holds no write path.

**D2 — The predicate reads: no write path, but the channel can return text to whoever sent the
form, and that person saves it.** A returned trip profile is saved by
`skills/trip-record/SKILL.md` § `## profile <name>`: it writes route 2's seed where the path is
absent, which substitutes the trip placeholder as D2.5 requires, and merges the block into the file
field by field, each current line echoed before it is written and no bracketed field written at
all. A returned durable record is saved by the operator, writing down what its subject told them —
no rule of that command admits a verb to write a returned block into the store.

**D3 — The contract's home is the portable interview card** (`ADR-023` D4.1), and only there. The
guided forms carry their questions and their own asking notes, and no output contract.

## Consequences

- **A saved block resumes like any other file.** The fields nobody reached are the fields a later
  interview asks, and nothing the recipient skipped is asked again.
- **A returned trip profile fails the frontmatter check as returned and passes it as saved**,
  because the trip placeholder is filled by the save rather than by the recipient. A block saved by
  hand, outside `## profile <name>`, carries the placeholder and fails.
- **A merge can report and refuse what a whole-file write would have taken.** A label the block
  renamed or dropped is named and not written, and a repeat unit left part-answered is not written.
- **The durable record's return has no merge.** It is saved by the operator, and nothing checks its
  labels on return but the card's instruction to keep them exactly as the form writes them.
- **The tier-W row and the refuse row are unchanged**, and so is everything D6.2 to D6.5 decide.

## References

- [`ADR-022`](ADR-022-interview-session-model.md) — D6.1, whose tier-T row this record supersedes
  in part; D1.2, D1.4, D2.4, D2.5, D3.3, D3.5, D3.6 and D5.5, the decisions the contract is held to
- [`ADR-023`](ADR-023-interviewer-authored-home-and-form-contract.md) — D4.1, the card as a member of
  the hand-off set; D4.2, under which a recipient is handed files and never paths
- [`ADR-039`](ADR-039-interview-conduct-bundled-with-the-verb.md) — where the shared conduct the
  card carries is authored
- [`README.md`](README.md) § *Convention* — the supersession-in-part form this record uses
- `templates/interview-card.md` — the contract, in the words a recipient's assistant reads
- `skills/trip-record/SKILL.md` § `## profile <name>` — the save of a returned trip profile
- #1328 — this record's card: the no-repository hand-off, whose second criterion addresses the save
  instruction to the sender rather than to the recipient
