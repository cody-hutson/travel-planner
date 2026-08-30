---
artifact: outputs/activities-list.md
schema-version: 1
trip: data-architecture-demo
writer: activities
lifecycle: accumulate-append
provenance: researched
publish: internal
generated: 2026-08-29
---

# Activities List — Porto

> **Illustrative, sanitized example. Not a real trip.** Venue details are
> illustrative and are not researched recommendations.

**Depth: tier 2 — the migrated-shape minimum.** `examples/tokyo-2026/outputs/activities-list.md`
is the worked example for this class's *content*: the full field-label surface per
entry lives in `agents/01-activities.md` § *Output Format* and is not reproduced here.
What **is** reproduced exactly is the migrated **shape** — the file-scoped frontmatter
above, the per-entry `artifact-entry` marker below, and the accumulation across two
dated sections. See `README.md` § *Depth*.

**Entry marker.** C5 is prose-shaped, so each entry carries a fenced `artifact-entry`
block holding the entity key **and nothing else**, directly under that entry's own
heading. Display name, access, shade and booking posture stay in the entry's prose,
where the frontmatter/body test already puts them: this class's frontmatter is
file-scoped, so an entry-level value has no field to become. Only the key does.

## The marker transition — what the two sections below depict

**This file is the fixture's witness for the mint window, and it is why it carries
two dated sections rather than one.** `reference/data-architecture.md` § 3.3 fixes
the mint point at **the hub's first enumeration of the venue set, before it writes
either reference file** — and the research spokes run *before* the hub. So a spoke's
entry cannot carry a key on the pass that writes it. Every marker is born
`venue: unminted`, and **the spoke resolves its own marker, in place and one-way, on
its next pass**: `unminted → ven-<token>`.

Read the two sections against that rule and the whole mechanism is visible at once:

| Section | Written on | Marker state now | Why |
|---|---|---|---|
| *Initial Research (2026-08-28)* | pass 1 | `ven-<token>` | Born `unminted`. The spoke re-ran on pass 2 and resolved each of these markers in place. |
| *Targeted Update — anchor meals (2026-08-29)* | pass 2 | `venue: unminted` | Written before the hub's pass-2 enumeration. These resolve on the spoke's **next** pass, which has not run. |

**Only the marker's value moved.** Every heading, labelled line and word of the
pass-1 prose below stands exactly as pass 1 wrote it. `reference/data-architecture.md`
§ 7.6 is what makes that binding rather than stylistic: an `accumulate-append` class
upgrades its frontmatter block in place, and **body entries are never rewritten**,
because rewriting accumulated history to satisfy a schema would destroy the record
the lifecycle exists to keep. Resolving a marker is the same act performed at entry
scope, by the file's single writer — so one writer per file is preserved and the
append guarantee is untouched.

**`unminted` is a converging state, not an instantaneous one — and it is a recorded
disposition, not a defect.** Resolution is one pass late by construction. On a
single-pass trip that never re-runs a spoke it never converges at all, and the marker
stays `unminted` permanently; `outputs/rooftop-sunset-bars.md` carries that permanent
case for its own reason. The three entries in the second section below are the
*converging* case: the hub has already minted their keys and placed them — they carry
a row in `outputs/links-reference.md`, `outputs/venue-matrix.md` and
`outputs/event-status.md` — while their markers here still read `unminted`.

**The key is a convergence optimisation and never the join basis.** That the hub
could place three venues whose research markers carry no key is the demonstration:
the hub joined those mentions to those places by the **five-rung identity procedure**
it runs at every mint (`agents/05-hub-planner.md` § *Step 1 — links-reference.md*),
not by reading a token off this file. A fixture in which every marker were already
minted would show the endpoint and conceal the mechanism — and would teach a state
the engine cannot reach on a first pass.

## Initial Research (2026-08-28)

### Livraria Lello

```artifact-entry
venue: ven-7b2e
```

Booking: advance. Access: level — clears `HC-1`. Indoor, so `HC-2` does not reach it.
Serves Alex's *good bookshop* wish.

### Jardins do Palácio de Cristal

```artifact-entry
venue: ven-c41a
```

Booking: open. Access: level paths — clears `HC-1`. Outdoor, so its placement has to
clear the `HC-2` window; Café Majestic is the named indoor bailout within reach.

### Serralves

```artifact-entry
venue: ven-93d7
```

Booking: advance, **not yet held** — this is the one needs-booking event left open.
Access: lift. Indoor. Serves Robin's *contemporary art* anchor.

### Mercado do Bolhão

```artifact-entry
venue: ven-2f68
```

Booking: walk-up. Access: level. Covered. Serves Alex's *working food market*
nice-to-have, and the hall's own counters make it a usable anchor meal rather than a
sight alone.

### Miradouro da Vitória

```artifact-entry
venue: ven-e05b
```

Booking: open. Access: level approach. Outdoor, so its placement has to clear the
`HC-2` window.

### Ribeira riverside

```artifact-entry
venue: ven-6c72
```

Booking: open. Access: level. Outdoor, morning. Serves Robin's *walk along the river*
wish.

### Café Majestic

```artifact-entry
venue: ven-b5e0
```

Booking: walk-up. Access: level. Indoor. **Proposed as a standing bailout rather than
as an anchor** — the AC escape for both outdoor blocks, which is the
*Pre-Planned Bailout Options* role this class carries.

**No entry above names another venue's key, and that is deliberate.** A research
entry holds exactly one key — its own, in its marker — and speaks of every other
venue by display name, because a display name is what a spoke has. The keyed
relationships between venues live in `outputs/venue-matrix.md` and
`outputs/links-reference.md`, which the hub writes.

## Targeted Update — anchor meals for each day (2026-08-29)

Appended, not overwritten: nothing above is deleted or rewritten, because the hub
reads the whole accumulated file and earlier entries stay useful as alternatives and
as the record of what was already considered.

**Why this re-run happened, and why it landed here.** `agents/06-validator.md`
§ *What You Audit* → *Structural integrity* checks that **no day is missing an anchor
event or anchor meal**, and the first pass placed no meal on any day. The spoke was
re-run to research one anchor meal per day. **These are activities entries because
this fixture ships no `outputs/food-list.md`** — C6 is absent on purpose, for a reason
`README.md` § *What is absent, and why* states — so the food venues this trip needs
land in the research class the fixture does carry. That is a property of the fixture,
not of the engine: on a real trip these entries are the food agent's, in C6.

Every entry here is a walk-in, so none of them changes the needs-booking set.

### Tasca do Bairro

```artifact-entry
venue: unminted
```

Booking: walk-up — no reservation to hold. Access: street level — clears `HC-1`.
Indoor. A neighbourhood tavern for Thursday's anchor meal, a short walk from the
gardens block. Shellfish-free plates are the house default rather than a request, so
`DH-1` is honoured without a substitution.

### Casa de Pasto Central

```artifact-entry
venue: unminted
```

Booking: walk-up. Access: level entrance — clears `HC-1`. Indoor, which is what lets
it sit inside the 13:00–16:00 window without touching `HC-2` — the constraint bounds
**outdoor** blocks. Saturday's anchor meal, before the slowed afternoon rather than
inside it. `DH-1` is honoured from the menu as written.

### Padaria São Bento

```artifact-entry
venue: unminted
```

Booking: walk-up. Access: level. Indoor. A bakery counter for Sunday's anchor meal,
early enough to leave the riverside walk and the ~13:00 departure intact. No shellfish
on the counter at all, so `DH-1` is trivially honoured.

---

**Every minted key above resolves to a row in `outputs/links-reference.md`**, which is
the venue registry. A key here with no row there would be a referencing key with
nothing behind it. **An `unminted` marker is not such a key** — it names no token, so
it makes no claim the registry has to answer. The three venues it stands on *do* have
registry rows, minted by the hub at its pass-2 enumeration; the markers here catch up
on the next pass this spoke runs.
