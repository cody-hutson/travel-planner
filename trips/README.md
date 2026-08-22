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

## Why this file is here

A clone has to show that `trips/` is where trips live. This file is the only tracked
thing under `trips/`: `.gitignore` excludes the directory's *contents* (`trips/*`)
rather than the directory itself, so this signpost survives while everything beside
it stays private.

Full structure and the agent flow: [`../CLAUDE.md`](../CLAUDE.md).
Publishing a finished trip: [`../README.md`](../README.md).
