# trips/

Working directories for your trips — **one folder per trip**.

**Your trip folders live in the `trips/` folder of your data folder** — the folder
`~/.travel-planner/data-root` names. This file is kept in both of the places it is
read: beside your trip folders there, and in the engine's own `trips/` folder, which
holds this file and never a trip. Everything below describes the folder in your data
folder, except where § *Why this file is here* speaks of the engine's copy.

Trip folders hold real personal detail (traveler profiles with passports, dates and
lodging), so the engine never publishes them and never copies them into its own
repository.

## Starting a trip

In Claude Code, type `/trip-new`, and the folder is created for you under the
`trips/` folder of your data folder. The shape it creates:

```
trips/<destination>-<year>/
├── trip-context.md     source of truth for the trip
├── trip-log.md         decision history; bridges planning sessions
├── travelers/          one profile per person for THIS trip, copied from the engine's
│                       templates/traveler-intake.template.md — each may carry a
│                       person: line pointing at that person's durable record
└── outputs/            agent artifacts, including the built travel site
```

Intake is split, and only the trip half lands here. The answers that stay the same
from one trip to the next are asked on the engine's
`templates/person-intake.template.md` and held once in
[`../people/`](../people/README.md), outside every trip — so a second trip with the
same people re-asks only what is genuinely new.

## After a trip

`/trip-decommission archive` ends a trip: it takes the published site offline, marks the
trip `ARCHIVED` in `trip-context.md`, and dates a closing entry in `trip-log.md`. It
**never deletes trip content** — that is deliberate, and it is why this section exists.
Archiving settles the *public* side of a trip. What stays on your machine afterwards is
left to you, so here is the retention posture to take.

Keep or clear per folder, because the four parts of a trip do not age the same way:

| Part | Posture | Why |
|---|---|---|
| `trip-log.md` | **keep** | Small, and the decision history is the part worth rereading when you plan the next one. |
| `trip-context.md` | **keep** | Small, and it is the trip's shape — where you went, when, and what you booked. |
| `outputs/` | **clear once archived** | The largest thing in the folder, and rebuildable from the two files above. |
| `travelers/` | **clear once archived — durable answers belong in `people/`** | The most sensitive bytes in a trip folder — passport details, dates of birth, document expiries. **Do not copy a profile forward into the next trip.** A person's durable facts belong in `people/`, held once and referenced by each trip's `person:` line, so a trip folder is never how a person's facts survive. If someone filled a trip form before they had a record, `/trip-record extract <name>` builds the record from that profile's own answers and points the file at it — then clear. |

**Nothing here expires on its own.** No command deletes a trip folder, no timer runs,
and archiving a trip does not shrink it. Clearing is a thing you do, and the point of
writing it down is that the folder that has stopped being useful is exactly the one you
stop noticing.

**Erasure is the one exception, and it removes a person rather than a trip.**
`/trip-record erase <person-id>` exists for the person who asks to be deleted. It deletes no trip
folder: it substitutes that person's identifying values at every location its own reach table
names, rewrites their `travelers/` profile as a tombstone, deletes their record in
[`../people/`](../people/README.md), and removes the built site and the publish staging clone. The
roster row survives and the party size is unchanged — the person travelled. What the sweep cannot
reach it names, rather than implying it was total. It is the operation the archive freeze still
lets through, it runs only when you type the record's id at a terminal, and nothing it destroys can
be made again. So clearing is still a thing you do — this is the act the engine does for you, and
it happens because someone asked, not because a folder went stale.

**The privacy posture above still holds for archived trips.** An archived trip is not a
published one — its contents stay where they were in your data folder, and the engine
still publishes none of them. Archiving changes what is *public*; it does not change
what is *kept*.

## Why this file is here

**In your data folder**, the trip commands look for this file by name before they trust
a listing of the folder — the engine's `CLAUDE.md` § *Resolving a trip* states that
check — so leave it where install put it.

**In the engine's repository**, and only there, this file is the only tracked thing
under `trips/`: the engine's `.gitignore` excludes that directory's *contents*
(`trips/*`) rather than the directory itself, so every checkout carries the signpost
and none carries a trip. None of that is a promise about your data folder, even where
it is an earlier checkout of the engine's repository: whether it is tracked, backed up
or synced is yours to decide.

Full structure and the agent flow: the engine's `CLAUDE.md`.
Publishing a finished trip: the engine's `README.md`.
