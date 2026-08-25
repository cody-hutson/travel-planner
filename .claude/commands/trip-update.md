---
description: Re-publish a trip's already-live site from the current local build. Encrypted only; cannot create a repo, cannot change the passphrase.
disable-model-invocation: true
allowed-tools: Bash(ls:*), Bash(scripts/publish-trip-site.sh update:*)
disallowed-tools: [Bash(scripts/publish-trip-site.sh publish:*), Bash(scripts/publish-trip-site.sh rotate:*), Bash(scripts/publish-trip-site.sh unpublish:*), Bash(scripts/publish-trip-site.sh list:*), Bash(bash:*), Bash(sh:*), Write, Edit, NotebookEdit]
---

# Update a published site

Takes the trip's current site build, re-encrypts it, and pushes it to the
per-trip repo that is already live. The passphrase does not change, so everyone
you already shared it with keeps their access.

**It updates an existing site. It cannot create one.** The subcommand clones the
per-trip repo and fails if that repo does not exist — there is no path through
this command that creates a public repo, enables Pages, or names anything on
GitHub for the first time. That is a different request type and it is a declared
exclusion of this surface.

**It is encrypted-only.** There is no unencrypted branch to reach from here: the
subcommand encrypts, runs the pre-push ciphertext guard, and pushes only if that
guard passes. Nothing else is pushed and nothing is pushed unverified.

**It prints no passphrase.** Neither the subcommand nor this command emits the
secret, and neither block below reads its contents.

## Trips in this repo

!`ls -1 "${CLAUDE_PROJECT_DIR}/trips" 2>&1`

## Passphrase files present

!`ls -l "${CLAUDE_PROJECT_DIR}/trips"/*/.passphrase 2>&1`

This block lists the file's **path, permission bits, size and timestamp — never
its contents**. Its one job is the check below, and it is the reason this
command exists in the shape it does. The byte count is metadata, not the secret;
it is the cost of showing that the file is readable rather than merely present,
and it is stated here rather than left for a reader to notice.

## Resolve before running anything

Both blocks above have already run and their output is above. Resolve the trip
from them. Do not list `trips/` again, and do not open a trip's files to work
out which one is meant — this command's assigned context is the trip directory
path and nothing inside it.

`trips/README.md` is a tracked signpost, not a trip. Every other entry in the
first block is a trip directory.

Resolve exactly one case, in order. Every case that says stop, stops.

### No trip yet

The first block produced no trip directory. Say so, name `/trip-new`, and stop.

### More than one trip

Ask which one the user means. Do not guess, and do not pick the most recently
modified — this command pushes to a live public site, and picking wrong pushes
one trip's site into another trip's repo.

### The resolved trip has no passphrase file

**This is the check, and it is a hard stop.** The second block shows no
`.passphrase` under the resolved trip, or shows one whose permission bits mean
it cannot be read.

Do not run the subcommand. Say plainly what would happen if it ran:

> The subcommand resolves the passphrase before encrypting. With no readable
> passphrase file and no passphrase in the environment, it **generates a fresh
> one**, re-encrypts under it, and pushes — printing nothing. The site stays
> live and looks unchanged, and every person you already gave the old passphrase
> to is locked out with no signal that anything happened.

Then name the three states that produce it — a fresh clone of the repo, a trip
directory restored from a backup that did not carry the file, or a deleted
secret — and name the recovery: put the trip's existing passphrase back at
`trips/<trip>/.passphrase` before updating. Stop there. Restoring the file is
the user's move, not this command's.

### The resolved trip has a readable passphrase file

Proceed to the invocation.

## The invocation

Run exactly this, once, with the resolved trip directory:

```
scripts/publish-trip-site.sh update trips/<trip>
```

Run it from the repo root, and pass the trip directory as the only argument.
The subcommand takes no options at all — there is nothing to add to this line
and nothing that should be added to it.

## When it fails

The subcommand reports failures on stderr and stops before pushing. Three are
worth naming, because each has a different next move:

- **No site build.** No `outputs/<destination>-travel-site.html` exists in the
  trip. Name `/trip-site` as the command that builds one, and stop.
- **The per-trip repo does not exist.** Nothing has been published for this trip
  yet, so there is nothing to update. This is the declared exclusion — say so,
  and hand the first publish back as a terminal step the operator runs.
- **The pre-push guard aborted.** The encrypted output did not verify as
  ciphertext. Nothing was pushed. Report the finding as it came back and stop;
  do not retry, and do not look for a way around it.

## What this command never does

It never runs any other subcommand of the publish script. First publish,
passphrase rotation and repo deletion are **declared exclusions** of the command
surface — `reference/adr/ADR-007-command-entry-point.md` §4 records each form
with its reason, and the surface declines those forms rather than substituting
itself for a human at a terminal.

It never sets the plaintext override environment variable, and there is no
plaintext branch reachable from the update subcommand in any case.

It never changes the passphrase. Rotation is a separate, excluded form; if the
user wants a new passphrase, name that as a terminal step and stop.

## One residual worth stating

If `STATICRYPT_PASSWORD` is set in your shell environment, it takes precedence
over the trip's passphrase file, and the update encrypts under that value
instead. This command deliberately does **not** inspect it — reading it would
put the secret into the session transcript, which is the exact failure the
publish family's exclusions exist to avoid. The check above covers the file, not
the environment. If you keep that variable set, it — not the file — is what your
viewers will need.

## Afterwards

Say which trip was updated and name the live URL the subcommand reported. Say
that the passphrase is unchanged, so previously shared access still works.

Do not write `trip-log.md`. This command's assigned context does not include it,
and the push is its own visible record.
