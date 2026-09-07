---
artifact: travelers/<traveler>.md
schema-version: 1
trip: <trip-slug>
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
---

# Your Travel Profile — [Name]

> **This is *your* profile** — what you'd love out of the trip, what you need it to
> work around, and how you like to travel. One file per person.
>
> **The fence above is not a field you fill in.** Replace `<trip-slug>` with the trip's
> directory name and leave the rest exactly as it stands. **Your name does not go in it** —
> it goes in the title line below, and nowhere in the fence. Field shapes and permitted
> values: `reference/data-architecture.md` → "Universal frontmatter".
>
> **If you already have a durable person profile, add one line to the fence** —
> `person: psn-<your token>` — so this trip picks up the answers you have already given
> once. If you do not have one, leave the fence exactly as it stands: it is optional, and
> a profile without it is complete.
>
> **Short on time? Fill the ⭐ fields first — about 2–3 minutes.** There are three of them,
> at most one in a section, and most are a pick-from-the-list or a short phrase. The one
> that asks you to think — a desire — says so on the line: one line is a complete first
> pass there. Nothing here is compulsory: fill what fits where your trip is right now and
> come back for the rest.
>
> **How to use it:**
> - Copy this template to `trips/<destination>-<year>/travelers/<your-name>.md`, then
>   fill it in — or just ask, and an agent will walk you through it question by question.
>   For `<your-name>`, take your name as the trip's Group roster spells it, lowercase it,
>   replace every run of characters outside `A-Za-z0-9._-` with a single `-`, and trim any
>   leading or trailing `-` — so Dana Smith saves as `dana-smith.md`. **That stem is how the
>   planner joins your file to your roster entry**, so a name it cannot match reads as an
>   unresolved profile rather than as yours.
> - It lives in the git-ignored `trips/` working dir and is **private — never published**,
>   so put your real details here.
> - **Fill in the parts that fit where your trip is right now.** If the destination
>   isn't picked yet, the "Destination leanings" section matters most; if dates and a
>   hotel are already booked, you can skip it. A few lines is fine; a lot is fine too.
> - Every question has a short example and a "skip if it doesn't apply." Replace each
>   `[bracketed placeholder]` with your own answer. If a question doesn't apply to you,
>   keep the line and put a single em dash (`—`) where the answer would go. **Don't leave
>   the placeholder text sitting there** — a leftover `[bracketed placeholder]` reads as
>   *unanswered*, exactly like an empty line, and a profile still carrying its brackets
>   reads as one nobody has filled in yet.
> - For the repeatable desire blocks, **add as many as you like and delete the rest.**
>
> **Two things are worth keeping straight as you go:**
> - Your **needs** are non-negotiable — the boundary the plan has to stay inside (a heat
>   ceiling, a mobility limit, an allergy, a rest floor). A plan that breaks a need is broken.
>   **This form does not ask for them.** A need is a durable fact about you rather than about
>   one trip, so it lives in your person profile — `templates/person-intake.template.md`,
>   which you can fill at any time, before or after this. Something that has to be worked
>   around for **this trip alone** goes in the trip's own `trip-context.md`, under
>   `## Hard Constraints` or `## Dietary & Health`.
> - Your **desires** are what you *want* — the plan tries hard to land them inside the
>   bounds your needs set. A missed desire is a worse trip, not a broken one.
>
> Everything here is *your individual view*. The planner takes everyone's profiles and
> works out the group plan — any actual splits, side-trips, or trade-offs are decided
> there, not written here.
>
> Placeholders only in this template — no real personal data in the template file itself.

---

## About you

> Just so the plan knows whose profile this is. The trip's Group roster holds the
> full list — here you only add anyone travelling with you who won't fill in a
> form of their own.

- **Relationship:** [*(optional)* how you fit in the group — e.g., "Jordan's sister", "traveling with friends". Skip if it doesn't apply.]
- **Party:** [Anyone travelling with you who won't fill in their own form — e.g., "two kids, 6 and 9", "my dad, 78, travelling on my booking". Skip if everyone in your group is filling in their own.]

---

## Destination leanings

> *For when no destination is fixed yet.* Where would you love to go — and where would
> you rather not? Skip this whole section once the destination is already decided.

- ⭐ **Trip vibe:** [The kind of trip you're after — e.g., beach / city / nature / culture / food / mix. Skip if you're easy.]

> This is *your* wishlist for this trip. The planner gathers everyone's leanings into a
> group shortlist — you're not picking the destination here, just saying what you're after.

---

## Dates & availability

> When can you actually travel? Skip the parts that don't apply.

- ⭐ **Can travel:** [The windows that work for you — e.g., "any time in May", "the week of June 8", "weekends only". Skip if you're flexible.]
- **Blackout:** [Dates you absolutely can't do — e.g., "May 20–24 (work)", "nothing over the holidays". Skip if none.]
- **Trip length:** [How long feels right — e.g., "4–5 days", "a long weekend", "two weeks if we can". Skip if you're open.]

> Once the trip's dates are set, this links to the trip's logistics — it doesn't
> override them, it just tells the planner what works for you.

---

## Getting there & back

> When you'd get there and when you'd head home. Where you set out from and what a long
> travel day does to you are durable answers — they live in your person profile.

- **Arrive / leave:** [When you'd arrive and head home — even if nothing's booked yet. If you'll be on whatever the group books, say so — e.g., "same as the group", "arriving a day early", "back Sunday night, not Monday". Skip only if you'd rather not say.]

> This refines the trip's Logistics — it doesn't set it. When you arrive and leave tells
> the planner what your own journey looks like; the booked flights stay in the trip's own
> file.

---

## Where you stay

> Who you're sleeping near. Skip the line if the lodging is already booked or you
> genuinely don't mind. What kind of place you like is a durable answer and lives in your
> person profile.

- **Rooming:** [Whether you'd want your own room, are happy sharing, and with whom — e.g., "own room if it's affordable", "happy to share with Sam". Skip if you're travelling alone or don't know the group yet.]

> This refines the trip's Accommodation — it doesn't choose it. The property, the
> booking, and the room list stay in the trip's own file.

---

## Desires — what you want

> What would make this a great trip *for you*? The want-to-do, the would-love-to-see,
> the kind of day you're hoping for. Unlike a need, a desire is yours alone — and you
> tag each one with **how much it matters** so the plan knows what to protect.
>
> **Stuck? Start from an archetype.** These are the shapes a desire usually takes — pick
> the ones that sound like your trip, then make each one specific to you:
>
> `a signature meal` · `a slow morning` · `a market wander` · `a big view` ·
> `a museum or gallery` · `live music` · `a day trip out of town` · `time on the water` ·
> `a neighbourhood to just walk` · `something active` ·
> `a local ritual (bath, café, sauna)` · `one splurge experience` · `a night out` ·
> `a quiet hour in nature` · `a hands-on thing (class, workshop, market tour)`
>
> The archetype wording also makes a good **Theme tag** — reusing it helps the planner
> spot where the group already agrees.
>
> **Add an entry for each thing you want, and delete the rest.** Fill in the **Desire**
> and pick exactly one **Priority tier** — think of it as how much it matters, not a number —
> and say whether it is a one-off or something you want **every day**:

- ⭐ **Desire:** [What you want — an archetype from the list above is a complete answer on its own. **One line is a complete first pass.** e.g., start with "a slow morning", sharpen later to "a slow museum morning rather than a packed sightseeing sprint."]
- **Priority tier:** [Exactly one of:
    - **anchor** — you'd be genuinely disappointed to miss this; build the trip to land it.
    - **wish** — a real want to try hard for, but it can yield to a need or to someone else's anchor.
    - **nice-to-have** — a bonus; lovely if it fits, no loss if it doesn't.]
- **Recurrence:** [*(optional)* `one-off` or `daily`. Most wants are one-off — a single occasion somewhere in the trip. Say `daily` for something you want **every day you're there**: a morning coffee before the day starts, a swim, an evening walk. It's separate from how much it matters — a daily want can be an anchor, a wish, or a nice-to-have. Leave the em dash (`—`) if it's a one-off.]
- **Theme tag(s):** [*(optional)* a word or two grouping it by kind — e.g., `museums, slow-pace`, `markets, food`, `nature`, `nightlife`. Skip if none come to mind.]
- **Overlap:** [*(leave blank)* — the planner works out who else shares this; you don't fill it in. If you happen to know someone shares it, you can note who you *think* does, but the real answer is computed.]

- **Desire:** [Second thing you want — e.g., "explore the local markets."]
- **Priority tier:** [anchor / wish / nice-to-have]
- **Recurrence:** [*(optional)* `one-off` / `daily` — leave `—` for a one-off]
- **Theme tag(s):** [*(optional)* — e.g., `markets, food`]
- **Overlap:** [*(leave blank — the planner computes it)*]

- **Desire:** [Third thing you want — e.g., "one standout coffee place."]
- **Priority tier:** [anchor / wish / nice-to-have]
- **Recurrence:** [*(optional)* `one-off` / `daily` — leave `—` for a one-off]
- **Theme tag(s):** [*(optional)* — e.g., `food`]
- **Overlap:** [*(leave blank — the planner computes it)*]

> Add as many desires as you like; delete the spares. There's no trip-level "desire" —
> these are yours alone. Priority tier is a "how much it matters" label, not a score; nothing
> optimizes against it.

---

## Interests & tastes

>  How well you already know this destination — a soft signal that helps shape what gets
> picked. Skip either line if it doesn't apply.

- **Been here before?:** [How well you already know this destination — one of: never / once / a few times / know it well — e.g., "once, about ten years ago." Skip if the destination isn't decided yet, or if you'd rather not say.]
- **Already done:** [*(optional)* Anything you've already seen or eaten here that you don't need to repeat — e.g., "did the castle and the main museum last time." Skip if it doesn't apply.]

> This is about *this destination*, not your tastes in general — those live in your person
> profile. It informs selection; it's broader and looser than the ranked Desires above.

---

## People dynamics & togetherness

> How much together-time versus own-time feels right to you. This helps the planner give
> everyone their own space without anyone feeling dragged along or left out. It's *your
> individual view* — the planner decides any actual splits. Skip any line that doesn't apply.

- **Group time:** [How much of the trip you'd like as a group — e.g., one of: "Mostly together" / "Some solo or sub-group time" / "Lots of independent time." Skip if you don't mind.]
- **Split off with:** [Anyone you'd especially enjoy peeling off with — names, "anyone," or "no preference" — e.g., "Jordan, for the slower stuff." Skip if no preference.]
- **Whole-group moments:** [Things you want EVERYONE there for — e.g., "every dinner", "the day trip", "the first night." Skip if none feel essential.]

---

## Anything else

> Anything the questions above didn't capture? One quick prompt, then free text —
> say it however you like, or leave it blank.

- **Special occasion?:** [Is the trip marking anything — a birthday, an anniversary, a honeymoon, a milestone? e.g., "Mum's 70th, on the Thursday". Skip if it's just a trip.]

[Anything else worth knowing — a quirk, a hope, a worry, a "by the way." Skip if nothing comes to mind.]

---

# END OF PROFILE — the guide below is not part of your profile
<!-- PROFILE-END -->

> **Filling this in by hand? You're finished — everything above is your profile.** You can
> stop here. Delete this guide or leave it; the planner ignores anything below this line.

### What a filled-in one looks like

A worked profile ships with this engine at
[`examples/people-library-demo/travelers/noor.md`](../examples/people-library-demo/travelers/noor.md).
It carries this form's own sections and labels — the same ones, in the same order — with real
answers written into them, an em dash on every question its traveller skipped, and `Overlap` left
blank. Read it beside this form to see how long an answer needs to be, which is the one thing a
blank form cannot show you. It is an invented example person and carries no real personal detail.

**If this file reached you on its own, that path will not open** — it lives in the repository this
form came from. Ask whoever sent you this form to send that profile too: it reads on its own, and
nothing else from the repository is needed to use it.

### Filling this out with an assistant

Upload or paste **this whole file** into any assistant — Claude, ChatGPT, Gemini,
DeepSeek, Grok, whatever you use — and say:

> *Help me fill out this travel profile. Follow the guide at the bottom of the file.*

That is all you need to say. Everything below tells the assistant how to run it.

### Assistant — how to run this interview

You are helping one traveler fill out their own profile. Read the whole file first, then
follow these rules exactly.

1. **One section at a time,** in the order they appear. Never dump all the questions at
   once, and never jump ahead to a later section before the current one is settled.
2. **Two or three questions per section, maximum.** Ask in plain language. The bracketed
   text in the file is a hint for you — do not read it out as a script.
3. **Offer the choices.** Where a field lists options, or the section carries a menu, put
   those in front of them. Recognising something is far faster than recalling it.
4. **Do the starred fields first.** The three fields marked with a star are the two-to-three
   minute pass. When they are done, say what is left and ask whether they want to keep
   going, stop there, or jump to a particular section. All three are fine answers.
5. **"Skip" is always valid.** Accept it immediately and move on. Never push twice.
6. **Never invent.** An unanswered field is a skipped field. Do not fill one in with a
   plausible guess, and do not infer one field from another.
7. **Keep their words.** Tighten the wording; do not rewrite the meaning. If you are not
   sure what they meant, ask — do not paraphrase your way past it.
8. **One field is never asked about.** Leave **Overlap** blank. The planner works it out.

### Assistant — the sections, in order

### Step 1 — About you
Fields: **Relationship**, **Party**.
Ask whether anyone is travelling with them who will not fill in their own form — kids and
ages, a partner who is not doing this. Relationship only matters if the rest of the group
would not already know who they are. Their name goes in the title line at the top of the
file, not in a field of its own.

### Step 2 — Destination leanings
Fields: **Trip vibe** (starred).
Ask first whether the destination is already decided — if it is, skip the questions for
this whole section. **Skipping a section never removes it from the output:** every field
still ships, each with an em dash where the answer would go (see "producing the finished
file" below). Dropping the lines loses the labels the planner parses.
Otherwise offer the vibe options — beach, city, nature, culture, food, or a mix.

### Step 3 — Dates & availability
Fields: **Can travel** (starred), **Blackout**, **Trip length**.
When can they travel? Then anything they absolutely cannot do, and how long feels right.

### Step 4 — Getting there & back
Fields: **Arrive / leave**.
Ask when they expect to arrive and head home, whatever the booking state. If they will be
on whatever the group books, record that as their answer — an empty field means they did
not answer, never that they match the group. Where they set out from, what a long travel
day does to them, and their passport are **not asked here**: they are the same from one
trip to the next, so they live in the person profile.

### Step 5 — Where you stay
Fields: **Rooming**.
Whether they want their own room, are happy sharing, and with whom. Skip it if they are
travelling alone or do not know the group yet. What kind of place they like to sleep in is
a durable answer and lives in the person profile.

### Must-haves — asked somewhere else, never skipped
**This form has no needs section, and that is not an omission you should paper over.** A
must-have — a heat ceiling, a mobility limit, an allergy, a rest floor — is a durable fact
about the person rather than about one trip, so it belongs in their person profile at
`templates/person-intake.template.md`. That form can be filled **at any time**, before or
after this one; there is no order to get right.

If something has to be worked around **for this trip alone**, it is not a personal
must-have and does not need a profile at all: it belongs in the trip's own file,
`trip-context.md`, under `## Hard Constraints` or `## Dietary & Health`, whose
`Applies to:` line names the people it covers.

**Say one of those two routes to them out loud when you reach this point.** A must-have
nobody wrote down anywhere is the one thing this engine cannot plan around, and a
first-time traveller filling only this form has no other place to put it.

### Step 6 — Desires — what you want
Fields per block: **Desire** (starred), **Priority tier**, **Recurrence**, **Theme tag(s)**, **Overlap** (leave blank).
Offer the archetype menu from the section as starting points — an archetype on its own is
a complete first pass. Then make each one specific to
them. For every desire, ask for exactly one priority tier — *anchor* (would be genuinely
disappointed to miss it), *wish* (try hard, but it can yield), or *nice-to-have* (a bonus).
Then ask whether it is a one-off or something they want every day they are there — a
morning ritual, a daily swim. Record `daily` only when they say so; anything else is
`one-off`. It is a separate question from how much it matters: ask both, never one
instead of the other. Suggest a theme tag or two, reusing the archetype wording where
it fits. Leave **Overlap** blank.

### Step 7 — Interests & tastes
Fields: **Been here before?**, **Already done**.
Ask whether they have been here before — offer the four options (never, once, a few times,
know it well) — and if they have, anything they have already done that they would not need
to repeat. Skip both if the destination is not decided yet. What they are drawn to in
general, and how they eat when they travel, are durable answers and live in the person
profile.

### Step 8 — People dynamics & togetherness
Fields: **Group time**, **Split off with**, **Whole-group moments**.
Offer mostly together, some solo or sub-group time, or lots of independent time. Then who
they would enjoy peeling off with, and anything they want everyone present for. Skip the
section if they do not know the group yet. What they would do with an hour to themselves
is a durable answer and lives in the person profile.

### Step 9 — Anything else
Fields: **Special occasion?**, plus the free-text line at the end.
Is the trip marking anything — a birthday, an anniversary, a honeymoon, a milestone? Then:
anything the questions missed.

### Assistant — producing the finished file

When the interview is done, output **one markdown code block** containing the profile and
nothing else. No preamble, no commentary, no summary afterwards.

- Include **everything above the `# END OF PROFILE` line**, and nothing from below it.
- Keep every field label **exactly as written**, including the `**bold**` and the star
  markers. Do not rename, reorder, merge, add, or drop sections or fields.
- Replace each `[bracketed placeholder]` with their answer. Nothing bracketed survives.
- For a field they skipped, keep the line and put a single em dash where the answer
  would go — the bullet, the bold label, then `—`. Do not leave the placeholder text
  in, and do not delete the line.
- **Overlap** gets the label and nothing after it.
- Under **Desires**, delete the unused repeated blocks and keep one block per real desire —
  adding more blocks if they have more.
- Leave the `>` guidance quotes as they are.
- Leave the frontmatter fence as it stands, except `<trip-slug>`, which takes the trip's
  directory name, and — **only if they gave you a durable person token** — one added
  `person: psn-<token>` line, exactly as the guidance quote at the top of this form describes.
  If they have no durable record, add nothing: the line is optional and a profile without it is
  complete. The fence's other values are facts about the artifact class, not answers to a question.
- Put their name into the `# Your Travel Profile` title line — the first heading, **not** the
  frontmatter fence above it. A person's name is a body value and never a frontmatter value
  (`reference/data-architecture.md` → "Traveler — natural key").

Then tell them to save it as `trips/<destination>-<year>/travelers/<their-name>.md`, deriving
`<their-name>` from the name the trip's Group roster carries: lowercase it, replace every run of
characters outside `A-Za-z0-9._-` with a single `-`, then trim any leading or trailing `-` — so
Dana Smith becomes `dana-smith.md`. Say why, in one line: that stem is how the planner joins the
file to the roster entry, and a stem it cannot match reads as an unresolved profile rather than
as theirs.
