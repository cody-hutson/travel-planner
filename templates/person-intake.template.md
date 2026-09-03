---
artifact: people/<person>.md
schema-version: 1
trip: cross-trip
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal-hard
---

# [Name]

> **This is *your* durable profile** — the answers about you that stay the same from one
> trip to the next. One file per person, written once and pointed at by every trip, so you
> never fill them in twice.
>
> **The fence above is not a field you fill in.** Leave it exactly as it stands, including
> `trip: cross-trip` — that value says this record belongs to no single trip. **Your name
> does not go in it** — it goes in the title line above, replacing `[Name]`, and nowhere in
> the fence. Field shapes and permitted values: `reference/data-architecture.md` →
> "Universal frontmatter".
>
> **Your name is the one thing this record cannot do without.** The title line is the
> display name and nothing else — not a decorated heading — because it is what a duplicate
> record is checked against.
>
> **Short on time? Fill the ⭐ fields first — about 2–3 minutes.** There are six of them,
> at most one in a section, and most are a pick-from-the-list or a short phrase. The one
> that asks you to think — a must-have — says so on the line: one line is a complete first
> pass there. Nothing here is compulsory, and you can come back for the rest.
>
> **How to use it:**
> - Copy this template to `people/psn-<token>.md`, then fill it in — or just ask, and an
>   agent will walk you through it question by question. `<token>` is four hex characters
>   minted once for you: **the filename carries your id, the title line carries your name.**
> - It lives in the git-ignored `people/` store and is **never published**, so put your real
>   details here.
> - **This record is used by every trip and is never trip-specific.** Anything true of only
>   one trip — your dates, what you want to do there, who you are rooming with — belongs on
>   that trip's own form, `templates/traveler-intake.template.md`, not here.
> - A trip picks this record up through a single `person:` line in that trip form's fence.
>   You can write this record before your first trip, between trips, or years after — there
>   is no order to get right.
> - Every question has a short example and a "skip if it doesn't apply." Replace each
>   `[bracketed placeholder]` with your own answer. If a question doesn't apply to you,
>   keep the line and put a single em dash (`—`) where the answer would go. **Don't leave
>   the placeholder text sitting there** — a leftover `[bracketed placeholder]` reads as
>   *unanswered*, exactly like an empty line, and a profile still carrying its brackets
>   reads as one nobody has filled in yet.
> - For the repeatable need blocks, **add as many as you like and delete the rest.**
>
> **Your needs are why this file is worth keeping.** A need is non-negotiable — the boundary
> a plan has to stay inside (a heat ceiling, a mobility limit, an allergy, a rest floor). A
> plan that breaks a need is broken. A need is also the answer least likely to change
> between trips, which is exactly why it is written here once instead of retyped every time.
> What you *want* out of a particular trip is a **desire**, and desires are asked for on the
> trip form, not here.
>
> Placeholders only in this template — no real personal data in the template file itself.

---

## Destination leanings

> Where you'd love to go, and where you'd rather not — in general, across any trip. A trip
> that has already picked its destination simply doesn't read these.

- **Would love:** [Places or kinds of places you'd be thrilled to go — e.g., "somewhere coastal in Portugal", "Japan", "anywhere with great food and walkable cities". Skip if nothing comes to mind.]
- **Rather skip:** [Anywhere you'd generally prefer to avoid — e.g., "long-haul flights", "anywhere very hot in summer". Skip if nothing comes to mind.]

> These are *your* standing leanings. When a trip is still choosing, the planner gathers
> everyone's into a group shortlist — you're not picking a destination here.

---

## Getting there & back

> Your side of any journey — where you set out from, and what a long travel day does to
> you. Skip anything that doesn't apply to you.

- ⭐ **Leaving from:** [The city or airport you'd set out from — e.g., "Austin (AUS)", "Manchester". Skip if it changes from trip to trip.]
- **Journey comfort:** [What you can take on a travel day — long-haul, red-eyes, layovers — and whether you lean towards flying, rail, or driving — e.g., "one long-haul is fine, no red-eyes; happy to take the train if it's under 5 hours". Skip if you're easy.]
- **Passport:** [*International trips only — the issuing country and the month it's valid through. Never the number.* **Yours alone — not your party's.** e.g., "United States, valid through March 2029". Skip for a domestic trip.]

> These refine a trip's Logistics — they never set them. Your usual origin tells the planner
> where your journey starts; the booked flights stay in each trip's own file. The passport
> line exists only so a trip's entry requirements can be checked against your nationality
> and your document's dates — which is why it never needs a number, and why it covers
> exactly one person: you. **Never put a second person's passport on yours.** Anyone else
> whose entry requirements need checking has a record of their own, and their passport goes
> on their own line there. This line is a **declared non-publishable field** — its class is
> declared in `reference/data-architecture.md` § *Publishability*, and both the publish guard
> and the validator read it from there — so what you write here shapes a plan and never
> reaches a published page, in named or anonymised form.

---

## Where you stay

> The kind of place you're comfortable sleeping in. Who you share a room with is a
> per-trip answer and is asked on the trip form instead.

- ⭐ **Lodging style:** [Hotel, rental, or hostel — plus anything that's a must for you — e.g., "rental with a kitchen", "hotel; need a lift rather than stairs", "anywhere quiet". Skip if you're happy with whatever the group picks.]

> This refines a trip's Accommodation — it doesn't choose it. The property, the booking, and
> the room list stay in each trip's own file.

---

## Budget appetite

> How you like to spend on a trip — your personal lean. Skip either part if you'd
> rather not say.

- ⭐ **Comfort range:** [Your day-to-day spend comfort — keep it lean / mid-range / spend freely, plus anything worth adding — e.g., "mid-range; happy with simple lunches and a nice dinner", "keep it lean", "comfortable spending freely". Skip if you'd rather not say.]
- **Splurge appetite:** [What you'd happily pay up for versus stay lean on — e.g., "splurge on one standout meal, save on the rest", "pay for comfort on transit, casual on food". Skip if nothing stands out.]

> This is *your* personal lean. It refines — it doesn't replace — the trip-level budget
> the group sets together.

---

## Needs — the must-haves

> **Anything a trip MUST accommodate for you?** These are the non-negotiables — the
> boundaries a plan has to stay inside. Write *your* specific detail: the *how much* and the
> *what exactly*. You are not linking it to anything here. Each trip has its own rules (a
> heat ceiling, a mobility limit, an allergy), and an agent is the one that points your need
> at the matching rule when it reads this record — you never write that link yourself.
>
> **Add a block for each need you have, and delete the rest.** If you have a real need no
> trip has captured as a rule yet (say, a rest floor), still write it here — an agent flags
> it so it can be added. Pick the closest **Category** for each:
> Heat / Mobility / Dietary-health / Rest / Budget cap / Timing / Sensory / Other.
>
> **If you have no must-haves at all, write `none`** rather than leaving it blank — blank
> reads as *not answered yet*, and the planner treats an unanswered need as unknown, never
> as none. **This is the one place `none` is used instead of the em dash**: everywhere else
> an em dash means "no answer", but for needs the difference between *"I have none"* and
> *"not asked yet"* is load-bearing, so say it in words.

- **Category:** [One of: Heat / Mobility / Dietary-health / Rest / Budget cap / Timing / Sensory / Other — e.g., Heat]
- ⭐ **Specific:** [Your personal detail — the *how much* and the *what exactly*. **One line is a complete first pass.** e.g., start with "no direct sun after early afternoon", sharpen later to "fades fast above ~82°F / 28°C in direct sun; needs shade or indoors by early afternoon on hot days." Skip the block entirely if this one doesn't apply to you.]

- **Category:** [Heat / Mobility / Dietary-health / Rest / Budget cap / Timing / Sensory / Other]
- **Specific:** [Second must-have — e.g., "prefers under ~15 minutes continuous walking before a sit-down break; step-free routing." Delete this block if you have only one need.]

- **Category:** [Heat / Mobility / Dietary-health / Rest / Budget cap / Timing / Sensory / Other]
- **Specific:** [Third must-have — e.g., "tree-nut allergy; carries an epi-pen; needs nut-free confirmation before any tasting menu." Delete this block if it doesn't apply.]

> Add as many need blocks as you like; delete the spares. Each need is exactly one Category.
> A need is non-negotiable — if it's more of a "would be nice," it is a desire, and desires
> are asked for on a trip's own form.

---

## Travel style & pace

> How you like a trip to *feel*, day to day. Skip any line that doesn't fit.

- ⭐ **Pace:** [packed / balanced / relaxed — e.g., "balanced: a couple of things a day with room to breathe." Skip if you're easy.]
- **Day rhythm:** [morning or evening person — e.g., "early riser, fading by 9 PM", "slow mornings, alive at night." Skip if it varies.]
- **Novelty vs comfort:** [how far you like to stray from the familiar — e.g., "love the unfamiliar", "a bit of adventure, but a comfortable base." Skip if no strong lean.]
- **Planning style:** [planned / spontaneous — e.g., "like a loose plan with room to wander", "book everything in advance." Skip if you don't mind.]

---

## Interests & tastes

> The broad stuff you're drawn to — a soft signal that helps shape what gets picked on any
> trip. Skip either line if nothing stands out.
>
> **Tick what sparks.** Scan the list and copy across the ones that land — add anything
> that's missing. Three or four is plenty; there's no right number.
>
> `museums` · `history` · `art & design` · `architecture` · `nature & hiking` ·
> `beaches & water` · `food & markets` · `coffee & cafés` · `bars & nightlife` ·
> `live music` · `shopping` · `sport` · `photography` · `walking a neighbourhood` ·
> `festivals & events` · `spa & wellness`

- ⭐ **Interests:** [Copy across the ones that spark from the list above, comma-separated — e.g., "museums, food & markets, walking a neighbourhood." Skip if you're open to anything.]
- **Cuisine appetite:** [How you eat when you travel — adventurous / familiar / specific loves & avoids — e.g., "adventurous; love street food; not big on seafood." Skip if no strong feelings.]

> This is a soft signal that informs selection. Whether you have been to a *particular*
> destination before, and what you already did there, are per-trip answers and are asked on
> the trip form.

---

## People dynamics & togetherness

> What you'd do with time to yourself. How much together-time you want on a given trip is a
> per-trip answer and is asked on the trip form.

- **Solo, I'd:** [What you'd love to do on your own if there's a chance — e.g., "find a quiet café and read", "go for a long morning run." Skip if nothing comes to mind.]

---

# END OF PROFILE — the guide below is not part of your profile
<!-- PROFILE-END -->

> **Filling this in by hand? You're finished — everything above is your profile.** You can
> stop here. Delete this guide or leave it; the planner ignores anything below this line.

### Filling this out with an assistant

Upload or paste **this whole file** into any assistant — Claude, ChatGPT, Gemini,
DeepSeek, Grok, whatever you use — and say:

> *Help me fill out this durable travel profile. Follow the guide at the bottom of the file.*

That is all you need to say. Everything below tells the assistant how to run it.

### Assistant — how to run this interview

You are helping one person fill out their own durable, cross-trip record. Read the whole
file first, then follow these rules exactly.

1. **One section at a time,** in the order they appear. Never dump all the questions at
   once, and never jump ahead to a later section before the current one is settled.
2. **Two or three questions per section, maximum.** Ask in plain language. The bracketed
   text in the file is a hint for you — do not read it out as a script.
3. **Offer the choices.** Where a field lists options, or the section carries a menu, put
   those in front of them. Recognising something is far faster than recalling it.
4. **Do the starred fields first.** The six fields marked with a star are the two-to-three
   minute pass. When they are done, say what is left and ask whether they want to keep
   going, stop there, or jump to a particular section. All three are fine answers.
5. **"Skip" is always valid.** Accept it immediately and move on. Never push twice.
6. **Never invent.** An unanswered field is a skipped field. Do not fill one in with a
   plausible guess, and do not infer one field from another.
7. **Keep their words.** Tighten the wording; do not rewrite the meaning. If you are not
   sure what they meant, ask — do not paraphrase your way past it.

### Assistant — the sections, in order

**Before Step 1 — their name.** The title line is the one required field in this file.
Ask it first and put it in the `# ` heading, plain: **Name** — the display name and nothing
else. It never goes in the frontmatter fence.

**Everything in this file is cross-trip.** If an answer comes back shaped like one trip
("I want to see the castle", "we're going in May", "I'm sharing with Sam"), that is a
*trip* answer: tell them it belongs on that trip's own form,
`templates/traveler-intake.template.md`, and do not record it here.

### Step 1 — Destination leanings
Fields: **Would love**, **Rather skip**.
Where would they love to go in general, and anywhere they would rather avoid. These are
standing leanings, not a vote on any one trip.

### Step 2 — Getting there & back
Fields: **Leaving from** (starred), **Journey comfort**, **Passport**.
Where do they usually set out from? Journey comfort covers long-haul, red-eyes, layovers,
and whether they lean towards flying, train, or driving. Passport is for international
trips and is **country and expiry month only — never a passport number.** If they start to
give you a number, stop them. It covers **this person alone, never their party** — if the
answer comes back party-shaped ("two of us are Canadian, one is Australian"), record only
this person's own country and dates. This is the one field where you narrow what they said
rather than **keeping their words** (rule 7): a second person's passport never goes on this
line. Anyone else whose entry requirements need checking has a record of their own.

### Step 3 — Where you stay
Fields: **Lodging style** (starred).
Hotel, rental, or hostel — plus anything that is a must for them (a kitchen, a lift, quiet).

### Step 4 — Budget appetite
Fields: **Comfort range** (starred), **Splurge appetite**.
Offer the three shapes — keep it lean, mid-range, or spend freely — then ask what they would
happily pay up for. This is their personal lean, not any group's budget.

### Step 5 — Needs — the must-haves
Fields per block: **Category**, **Specific** (starred).
This is the important one, and it is the reason this record exists. Ask whether anything has
to be worked around for them: heat, walking or stairs, food or allergies, rest, a spending
ceiling, a fixed time, noise or crowds. One block per need, in their own words, as specific
as they can make it — one line is a complete first pass, so take what they give you rather
than pressing for more. If nothing is a hard must, write `none` rather than leaving it
blank — blank reads as *not answered yet*, and the planner treats an unanswered need as
unknown, never as none. **This is the one place `none` is used instead of the em dash**:
everywhere else an em dash means "no answer", but for needs the difference between *"I have
none"* and *"not asked yet"* is load-bearing, so say it in words. Do not link the need to
any trip rule — that link is computed when a trip reads this record.

### Step 6 — Travel style & pace
Fields: **Pace** (starred), **Day rhythm**, **Novelty vs comfort**, **Planning style**.
Offer packed, balanced, or relaxed. Then morning or evening person, how far they like to
stray from the familiar, and planned versus spontaneous.

### Step 7 — Interests & tastes
Fields: **Interests** (starred), **Cuisine appetite**.
Read out the tick list from the section and let them pick — three or four is plenty. Then how
they eat when they travel, including anything they avoid.

### Step 8 — People dynamics & togetherness
Fields: **Solo, I'd**.
What they would love to do on their own given the chance.

### Assistant — producing the finished file

When the interview is done, output **one markdown code block** containing the record and
nothing else. No preamble, no commentary, no summary afterwards.

- Include **everything above the `# END OF PROFILE` line**, and nothing from below it.
- Keep every field label **exactly as written**, including the `**bold**` and the star
  markers. Do not rename, reorder, merge, add, or drop sections or fields. **A relabelled
  field is not a smaller error than a missing one** — a trip joins this record to its own
  answers by matching these labels, so a renamed field simply never arrives.
- Replace each `[bracketed placeholder]` with their answer. Nothing bracketed survives.
- For a field they skipped, keep the line and put a single em dash where the answer
  would go — the bullet, the bold label, then `—`. Do not leave the placeholder text
  in, and do not delete the line. **The needs fields are the one exception**: `none` in
  words, never an em dash, when they say they have none.
- Under **Needs**, delete the unused repeated blocks and keep one block per real need —
  adding more blocks if they have more.
- Leave the `>` guidance quotes as they are.
- Leave the frontmatter fence exactly as it stands. Its values are facts about the artifact
  class, not answers to a question — `trip: cross-trip` in particular is a reserved value
  and never a trip's name.
- Put their name into the `# ` title line — the first heading, **not** the frontmatter fence
  above it. A person's name is a body value and never a frontmatter value
  (`reference/data-architecture.md` → "Traveler — natural key").

Then tell them to save it as `people/psn-<token>.md`, where `<token>` is the four hex
characters minted for this record. Say why, in one line: the filename carries the id every
trip points at, so the name in the title line can change without any trip losing the link.
