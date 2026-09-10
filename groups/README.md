# groups/

One record per reusable group — **a named set of people you travel with, held once rather than
assembled one person at a time on every trip.** The same four people going away together for the
third time are a group; referencing that group at setup expands it to its members.

Everything in here is git-ignored except this file.

## What a record is

`groups/grp-<token>.md`, one file per group. The filename carries the group's id — minted once and
never reused, so groups that happen to share a name still have separate records. The title line
carries the display name and nothing else.

A record holds **a list of person ids, and nothing else.** No names, no roles, no notes, no
description. A member entry is one id on one bullet:

```markdown
# Ski crew

## Members

- psn-3c7e
- psn-9d42
```

**Under `## Members` there are bullets and blank lines and nothing else** — not a sentence, not a
note, not a heading. That is the whole shape, and it is what makes the promise below structural
rather than a habit: a line that is not a bullet is not a member entry, so a fact written on one
would sit in a record that has no place to hold it and that erasure removes bullets from.

Names are looked up from each person's own record when a group is shown to you, so a person who is
renamed reads correctly here the moment their record changes — there is nothing to keep in step.

## Why this file is tracked and nothing beside it is

A clone has to show that `groups/` is where group records live. This file is the only tracked thing
under it: `.gitignore` excludes the directory's *contents* (`/groups/*`) rather than the directory
itself, so this signpost survives while every record beside it stays on your machine.

Same arrangement as [`../trips/README.md`](../trips/README.md),
[`../analysis/README.md`](../analysis/README.md) and [`../people/README.md`](../people/README.md),
for the same reason. The invariant is tested — see group `V` in
[`../scripts/test-publish-guard.sh`](../scripts/test-publish-guard.sh).

## What a record does not hold

**A group is a set of references and holds no personal data of its own.** It has no slot for any of
the following, and that is structural rather than a rule someone has to remember — none of these
exists in the form at all:

- **a member's name** — the id is the entry, and the name is read from that person's own record;
- **a role, a relationship, or a note about a member** — those describe the person, and a person's
  durable facts live in [`../people/README.md`](../people/README.md);
- **a description of the group** — see the paragraph below, which states the cost of that plainly;
- **anything a trip works out** — who roomed with whom, who split what, who peeled off with whom.
  Those belong to the trip they happened on.

**There is no free-text slot, and that is deliberate rather than unfinished.** A sentence about why
a group exists becomes a sentence about the people in it the moment it says anything specific, and
this store is not a place for that. **The cost, stated rather than hidden: there is nowhere here to
write a note about a group.** The name is where that meaning goes — `# Tahoe regulars — 2024 crew`
is a name, and it is the whole of what a record says about itself.

## Privacy

**A group record holds person ids, and a set of ids is more than the sum of them.** Any single id
says nothing on its own; a group says that these particular people travel together, and that is a
fact about all of them at once. Nothing here is ever published — the class is declared *never
rendered, in any form, including anonymized*, on the same footing as a person record. Stripping the
names from a small named party does not stop it identifying anybody.

## Expanding a group onto a trip

**`/trip-record group-expand <group-id>` puts the group's members on the trip you are working on**,
each linked to their own record exactly as if you had added them one at a time. It shows you what
the expansion would change before it writes anything, one line per member, and takes a single
confirmation.

**It is a point-in-time act, not a live binding.** Once a trip has been expanded, **editing the
group changes nothing on that trip** — no file in it names the group, so there is nothing to go
stale and nothing to re-sync. Add a member today and last year's trip is byte-identical tomorrow.
That is the property the store is built around, and it is why there is no "re-sync this trip"
command: the absence is deliberate.

**A member whose link would change something on this trip is left out and named**, with
`/trip-record link <name> <person-id>` given as the way to handle them one at a time — that command
shows the difference field by field, which is the detail a bulk preview cannot.

## Editing a group

| What you want | The verb |
|---|---|
| Make a new group | `/trip-record group-new <name>` |
| See the store, or one group's members | `/trip-record group-list [<group-id>]` |
| Add someone | `/trip-record group-add <group-id> <person-id>` |
| Take someone out | `/trip-record group-drop <group-id> <person-id>` |
| Delete the group | `/trip-record group-delete <group-id>` |

**Deleting a group deletes the group and nothing else.** Every person in it keeps their record, and
every trip that already expanded it is untouched. That is the whole of what deletion does, and it is
worth stating because the word invites a worse guess. It is not reversible — nothing here is in git,
so there is no earlier version to restore from — but it is **reconstructible**: a group is a name and
a list of ids, and you can make it again. Deleting a *person* is a different operation entirely, and
it is the one that cannot be undone: see [`../people/README.md`](../people/README.md) § *Deleting a
person*.

**Groups may share a name.** Their ids differ, so nothing is ambiguous, and creating a
same-named group tells you the existing one is there and lets you decide. **There is no merge and no
split** — a group is a set, and the way to change one is to add and drop members.

**A member whose person record was deleted reads as unknown**, never as *no such person* and never
silently dropped. Erasing a person removes them from every group they were in, and where that leaves
a group empty or down to one member, the group is kept and reported rather than deleted for you.

## Retention

**Nothing here expires on its own.** No command sweeps this folder and a group does not go stale
because it is old. Clearing is a thing you do.
