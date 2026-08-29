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
above and the per-entry `artifact-entry` marker below. See `README.md` § *Depth*.

**Entry marker.** C5 is prose-shaped, so each entry carries a fenced `artifact-entry`
block holding the entity key **and nothing else**, directly under that entry's own
heading. Display name, access, shade and booking posture stay in the entry's prose,
where the frontmatter/body test already puts them: this class's frontmatter is
file-scoped, so an entry-level value has no field to become. Only the key does.

## Initial Research (2026-08-29)

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

Booking: open. Access: level paths — clears `HC-1`. Outdoor, placed after 16:00 so it
sits outside the `HC-2` window; carries `ven-b5e0` as its indoor bailout.

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
nice-to-have.

### Miradouro da Vitória

```artifact-entry
venue: ven-e05b
```

Booking: open. Access: level approach. Outdoor, moved to 16:30 by the Saturday patch,
which is what takes it out of the `HC-2` window.

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

Booking: walk-up. Access: level. Indoor. **Not an anchor on any day** — it is the
standing `HC-2` bailout for the two outdoor blocks, which is why
`outputs/venue-matrix.md` shows it twice and marks it at the cap.

**Every key above resolves to a row in `outputs/links-reference.md`**, which is the
venue registry. A key here with no row there would be a referencing key with nothing
behind it.
