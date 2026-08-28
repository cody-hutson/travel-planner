# trips/

Working directories for your trips — **one folder per trip**.

Everything in here is git-ignored except this file. Trip folders hold real personal
detail (traveler profiles with passports, dates and lodging), so they never leave
your machine and are never published.

## Starting a trip

Open the repo in Claude Code and say you want to plan a trip — the conversation
creates the folder for you. The shape it creates:

```
trips/<destination>-<year>/
├── trip-context.md     source of truth for the trip
├── trip-log.md         decision history; bridges planning sessions
├── travelers/          one profile per person, copied from
│                       templates/traveler-intake.template.md
└── outputs/            agent artifacts, including the built travel site
```

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
| `travelers/` | **move what you will reuse, then clear** | The most sensitive bytes in the repo — passport numbers, dates of birth, document expiries. Copy a profile forward into the next trip rather than leaving it in a folder you have stopped opening. |

**Nothing here expires on its own.** No command deletes a trip folder, no timer runs,
and archiving a trip does not shrink it. Clearing is a thing you do, and the point of
writing it down is that the folder that has stopped being useful is exactly the one you
stop noticing.

**The privacy posture above still holds for archived trips.** An archived trip is not a
published one — its contents remain git-ignored, remain on your machine, and remain
outside the repo. Archiving changes what is *public*; it does not change what is *kept*.

## Why this file is here

A clone has to show that `trips/` is where trips live. This file is the only tracked
thing under `trips/`: `.gitignore` excludes the directory's *contents* (`trips/*`)
rather than the directory itself, so this signpost survives while everything beside
it stays private.

Full structure and the agent flow: [`../CLAUDE.md`](../CLAUDE.md).
Publishing a finished trip: [`../README.md`](../README.md).
