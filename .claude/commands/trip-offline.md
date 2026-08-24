---
description: Take a trip's live site offline while keeping the repo. Reversible from repo Settings; never deletes anything.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(scripts/publish-trip-site.sh unpublish:*)
disallowed-tools: [Bash(scripts/publish-trip-site.sh publish:*), Bash(scripts/publish-trip-site.sh update:*), Bash(scripts/publish-trip-site.sh rotate:*), Bash(scripts/publish-trip-site.sh list:*), Bash(bash:*), Bash(sh:*), Write, Edit, NotebookEdit]
---

# Take a published site offline

Disables GitHub Pages for a trip's per-trip repo. The live URL stops serving.
**The repo, its name and its contents are kept**, so this is reversible: Pages is
re-enabled from the repo's Settings → Pages, branch `main`, root.

**It never deletes.** Deleting the per-trip repo is a different form of the same
subcommand, it is irreversible, and it is a **declared exclusion** of this
command surface. This command reaches only the reversible form and it always
passes the flag that selects it.

**Reversible is not inert.** A live site goes dark the moment this runs, and
anyone holding the URL loses it until Pages is re-enabled. Say what will happen
before running it, in one line, and let the user answer. The repo name stays
public either way, and content already fetched may persist in third-party
caches — say that too, because taking a site offline is not a retraction.

## Trips in this repo

!`ls -1 ${CLAUDE_PROJECT_DIR}/trips 2>&1`

## Resolve before running anything

The block above has already run and its output is above. Resolve the trip from
it. Do not list `trips/` again, and do not open a trip's files — this command's
assigned context is the trip directory path and nothing inside it.

`trips/README.md` is a tracked signpost, not a trip. Every other entry is a trip
directory.

Resolve exactly one case, in order.

### No trip yet

Nothing is published, so there is nothing to take offline. Say so and stop.

### More than one trip

Ask which one the user means. Do not guess and do not pick the most recently
modified — the wrong answer here takes down the wrong live site.

### Exactly one trip, or one the user named

Confirm the intent in one line before running: name the trip, say the live URL
will stop serving, say the repo is kept, and say Pages can be re-enabled from
the repo's Settings. Then proceed.

Where the user's intent is clearly to remove the published site permanently, do
**not** proceed. That is the excluded form — see below.

## The invocation

Run exactly this, once, with the resolved trip directory:

```
scripts/publish-trip-site.sh unpublish trips/<trip> --disable-pages-only
```

**The flag is not optional and it is not a default.** Without it the subcommand
takes the destructive path. Never issue this subcommand without
`--disable-pages-only` on the same line, and never add any other option to it.

It is idempotent. If the per-trip repo is already gone, or Pages is already
disabled, the subcommand reports a no-op and succeeds. That is a normal result,
not a failure — report it as "already offline", not as an error.

## Why the destructive form cannot be reached from here

Worth stating plainly, because a reader should not have to trust the flag alone:

- The reversible form **returns before** the destructive path is reached. It
  never evaluates the repo-scope requirement and never reaches the typed
  confirmation, because it exits above both.
- The destructive path additionally requires the `delete_repo` OAuth scope,
  which the subcommand refuses to proceed without.
- The destructive path's typed confirmation cannot be answered from a
  non-interactive caller, and the flag that would skip it is forbidden to every
  command in this surface by
  `reference/adr/ADR-007-command-entry-point.md` §2 — a bound no slice may
  negotiate. With no such flag, the subcommand refuses the non-interactive
  delete outright.

**The residual, stated rather than implied:** the tool grant in this file is
scoped to the subcommand, not to the flag, because the trip directory is a
positional argument that sits between them and no permission rule can reach past
it. The flag requirement is carried by this file's instruction, by the two
refusals above, and by the taxonomy guard's assertion that this subcommand never
appears here without it. Three layers, none of them the permission rule.

## What this command never does

It never runs any other subcommand of the publish script. First publish, site
update and passphrase rotation are separate request types; the first and the
third are **declared exclusions** of this surface, recorded with their reasons in
`reference/adr/ADR-007-command-entry-point.md` §4. For the second, name
`/trip-update`.

It never sets the plaintext override environment variable, and it never passes
the confirmation-skip flag to this subcommand or to any other.

It writes nothing locally. The trip directory, its site build and its passphrase
file are untouched, which is why re-publishing later needs nothing restored.

## Afterwards

Say which trip went offline, name the URL that has stopped serving, and name the
exact way back: repo Settings → Pages, branch `main`, root.

Then name the two things that did not change — the repo and its public name are
still there, and content already fetched may persist in third-party caches. A
user who wanted the site *gone* has not got that from this command, and should
hear it now rather than assume it.
