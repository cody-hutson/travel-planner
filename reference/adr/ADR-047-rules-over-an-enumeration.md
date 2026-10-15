# ADR-047: Rules over an enumeration — precedence at the rule, one owner for the members, a criterion where the list is what goes stale, and what no check can see

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** the *Admission and precedence law* milestone — the card that states one
  resolution-and-admission law for rules over an enumeration (#674).

## Context

The card files a class and not its instances: **a rule stated over an enumeration its author
believed closed.** A sibling that arrives later is neither ranked against the enumerated members
nor admitted to them, and the sentence that told them apart goes on reading as complete. The
class was first written down as precedence alone — two rules matching one input with no stated
winner — and that described half of what was found. The other half was coverage: a sibling that
was never admitted at all, rather than one ranked wrongly.

The instances were found during the *Nightlife fast-follows* release, by its adversarial and
acceptance reviews, in prompts, a fixture's procedure and a render contract written by different
authors. The card records each by file and by its state when the card was filed:

| Where | What the rule left unranked or unadmitted | State |
|---|---|---|
| `agents/06-validator.md` | `covered` against `gap`, for a decline that covers a desire-holder | repaired in that release |
| `agents/06-validator.md` | the `covered` bullet the first repair missed | repaired in that release |
| `agents/06-validator.md` | `gap`'s third disjunct against `contradiction`, with no precedence | open |
| `examples/evening-boundary-demo/README.md` | the check procedure of its invariant E3 | repaired in that release |
| `agents/07-nightlife.md` | a routing claim naming a destination that carries part of the occasion limb | open |
| `agents/07-nightlife.md`, with both intake forms | a vocabulary that invites reading one datum as another | open |
| `agents/06-validator.md` | the entry line's member slot, with no well-formedness test where the decline line has one | open |
| `reference/site-layout-spec.md` | § 9.2 declared total, with an element neither mapped nor excluded | repaired in that release |

Two further findings sat beside them: the hub obliged every present traveler while the validator
scoped its finding to the travelers the gate obliged, and nothing said what the difference
resolved to; and `agents/00-enrichment.md` told the enrichment agent to carry a traveler's
`Special occasion?` answer through *"so the hub can see it"*, where neither the hub's prompt nor
the validator's read it. That sentence was false before the release began, and routing claims
downstream of it repeated it.

**Every one of these shipped with the required checks green**, before its discovery and after it.
A suite grades the behaviour a rule has. It does not see a rule whose member silently co-fires
with a sibling, or one that never admits a sibling at all. Authors also wrote the shape into
their own first drafts, twice while repairing an earlier instance: the prose falls into it under
ordinary care. And one instance failed toward a pass — an unreadable member slot fell through to
a passing verdict under a rationale that was true of the forms it was written for and false of
the one added later.

## Decision drivers

- **One statement, and one citation at each rule that applies it.** The law is not restated per
  file, and an application says which duty it discharges in its own words.
- **The statement is in context when an engine file is edited.** A rule an author must remember
  to go and read is the kind of control the evidence above argues against.
- **A check wherever one can reach, and the limit stated where it cannot.** A green suite on this
  subject must not be read as more than it is.
- **No sweep of rules that already stand.** A law that convicted every standing rule on the day
  it landed would be one nobody could satisfy, and would be read from then on as optional.
- **The charter's read cost.** `CLAUDE.md` is read on every invocation of every verb, so the
  section carries the rule and the citation and nothing a reader at run time does not need.

## Options considered

1. **One patch per locus.** Rejected. Each instance is individually deferrable, and that property
   is how the class accumulated; it was predicted during the source release that piecemeal repair
   would produce another instance, and it did.
2. **A precedence-only law.** Rejected. It reaches the loci where two members hold for one input
   and leaves untouched every locus where a member is never admitted.
3. **The decision record as the home of the rule.** Rejected. `ADR-042-accepted-record-growth.md`
   keeps an instruction a session follows in the surface that instructs it; a record is read only
   when a step names it, and no editing instruction names one.
4. **A new reference document holding the law, with a pointer from the charter.** Not taken. It
   is off the costliest read, which is its strength, and it takes the law out of the file that
   already holds the editing rules, so an author reaches it only by a read taken on good faith —
   the control the evidence in § *Context* argues against.
5. **The law's whole first draft in the charter.** Narrowed. The paragraph on what a green check
   does and does not establish, and the sentence on what the suite holds a repeat to, are in the
   register's section instead, where the limits of the check are stated once; the charter's
   section cites it.
6. **The law beside the declared gaps of `reference/data-architecture.md` § 8.** Weighed and not
   taken. It was admissible: that document's § 11 keeps prose validation out of the artifact
   schema, which is its subject, and does not bar a prose rule. It has the weakness of option 4 —
   one good-faith read away from an editor, where the charter is already in context.
7. **The corpus-hygiene suite's owned-rule class, extended to more owners.** Rejected. That class
   recognises its one rule by a lexicon written into the suite, so every enumeration would be a
   suite edit and the suite would spell the members it grades.
8. **The check as a group of the artifact-schema suite.** Weighed and not taken. It was
   admissible: both suites are required checks, and the contention that first ruled it out was
   removed by sequencing. The corpus-hygiene suite's owned-rule class is the nearer sibling in
   subject, and the declaring-fence document that suite already reads is where the register sits.
   What it would have bought: the artifact-schema suite grades its own rosters in both directions,
   and nothing grades the corpus-hygiene suite's.
9. **A tracked scenario fixture as the witness of the validator's ladder.** Rejected.
   `ADR-019-discriminating-evidence-rule.md` asks that a pass require evidence its subject could
   only have produced by running; no executable validator exists, so a tracked fixture would be a
   witness nothing grades.
10. **A detector for unregistered enumerations.** Rejected in general, and adopted in the one form
    that has a member set to look for. A scan for member tokens cannot tell a repeat of an
    enumeration from a sentence that mentions some of its members, and an enumeration with no
    owner has no member set to scan for. Once an enumeration is registered it has one, and an
    engine file that repeats it without a row fails.
11. **That reading over every tracked file.** Rejected. Decision records reuse the tokens of
    enumerations they decided, and on the day such a family is registered the reading would turn
    red on records that cannot follow an owner without a new decision.
12. **The files that reading passes over, written as a constant of the new class.** Rejected. The
    suite already declared those files, in one function of its owned-rule class; a constant
    beside it would be a second home. The files stay in that one function, which both classes
    now take.
13. **A second declaring fence for the files passed over.** Specified, and withdrawn before it
    landed: the suite already held that declaration.
14. **That fence, read by both classes.** Not taken. The owned-rule class also reads historical
    trees, where no such fence exists, so it would need a fallback — which is a second statement
    of the files again.
15. **Both declarations kept, and held equal by an arm.** Not taken. A copy held equal to its
    original by an arm is still a copy.
16. **An owner row admitted alone, so that an enumeration stated once could be watched for its
    first repeat.** Weighed and not taken. Every registration made with this record is built on
    an owner and at least one site, and the gain is for an enumeration nobody has proposed.
17. **The law in the charter beside the editing rules, decided here; a register that holds a
    repeat to its owner, read by a required check; and the limit of that check stated once.**
    Chosen.

## Decision

### 1. A rule over an enumeration owes three duties, and they are stated once

A rule stated over an enumeration owes precedence, admission, and a criterion in place of a list.
**Their one statement is `CLAUDE.md` § *Rules over an enumeration*; this record decides them and
does not restate them.** They are stated in the charter beside § *Editing an engine file —
reconcile, never accrete*, because they work only if they are in context when an engine file is
edited, and the charter is. Each rule that applies them states its application at the rule and
cites that section.

The duties bind whoever writes such a rule in an engine file, and an edit that adds, removes or
renames one of its members or changes the sentence that tells them apart — and no other edit to
the rule. The bound is decided with the duties for one reason: a trigger nobody can satisfy on
the day it lands is read from then on as optional, and a law that reached every standing rule
the day it landed would be that trigger. Nothing here orders a sweep of rules that already stand.

### 2. A repeat is held to its owner by a register

A repeat of an enumeration that is registered is held to its owner in both directions; an
unregistered repeat of a registered enumeration fails; and a reading that cannot be made
withholds its own enumeration's comparisons and no other's. **The shape — the fence, its rows,
what a reading is and what breaks one — is `reference/data-architecture.md` § *The enumeration
register*'s, and the class of `scripts/test-corpus-hygiene.sh` that reads it holds it.** This
record does not restate either.

### 3. What no mechanical check reaches is stated once, beside the register

What no check reaches on this class is listed once, in that same section, and this record carries
no copy of the list. A green suite is not evidence of absence on this subject, because the suite
grades what the register points it at and what it can find by token, while the class is defined
by what a sentence means. A general detector for unregistered enumerations was rejected for the
reason in option 10, and the register is the one form of it that has a member set to read.

## Consequences

**What this makes necessary elsewhere**

- The charter grew by 1,701 bytes when the section landed, its separating line included, on the
  file every verb reads.
- A registered reading is written in code spans at an anchor. Both kinds of reading read code
  spans and nothing else, so a surface that registers a repeat carries its members that way.
- Registering an enumeration is a statement about every engine file. From then on a paragraph of
  an engine file that carries no row for it, and writes more than one of its members as code
  spans, fails until it carries a row or is worded otherwise.
- A decision record that first stated an enumeration an instructing surface now owns stays as
  decided and carries no row. A record that repeats an enumeration an instructing surface already
  owned may carry a site row; when the owner gains or loses a member that row turns red, and a
  record cannot follow its owner without a new decision.
- A reading that cannot be made fails the run, and withholds its own enumeration only: every other
  registered enumeration is still read and graded.
- The files the unregistered-repeat reading passes over are chosen by path and not by kind.

**The residual, and its owner**

- What no check can see on this class — the list in `reference/data-architecture.md` § *The
  enumeration register* — is what this record leaves open. Its owner is the open epic on
  governing prose that binds behaviour with no executable assertion (#825).

## References

- The one statement of the law: `CLAUDE.md` § *Rules over an enumeration*.
- The editing rules it stands beside: `CLAUDE.md` § *Editing an engine file — reconcile, never
  accrete*.
- The register, what holds a repeat, what breaks a reading and what no check can see:
  `reference/data-architecture.md` § *The enumeration register*.
- The class that grades the register: its entry in the banner of `scripts/test-corpus-hygiene.sh`.
- The basis a count in this corpus carries: `ADR-013-count-assertion-basis.md`.
- A pass requires evidence its subject could only have produced by running:
  `ADR-019-discriminating-evidence-rule.md`.
- An instruction stays in the surface that instructs, and settled design belongs in the
  specification document for its subject: `ADR-042-accepted-record-growth.md`.
- Driving work: #674.
