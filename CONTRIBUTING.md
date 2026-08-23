# Contributing

Thanks for your interest in the travel-planner engine. It's a set of markdown agent
prompts driven by Claude Code — there's no build step and no application code.

## Contribution model

This is a personal, single-maintainer project. Write access is limited to invited
collaborators, and unsolicited external pull requests generally won't be merged. If
you'd like to contribute, open an issue to ask about collaborator access — it's granted
by invitation only.

## Ground rules

- **Commit with a GitHub no-reply email, not a personal one.** Turn on
  *Settings → Emails → Keep my email address private*, then set your repo identity to the
  `…@users.noreply.github.com` address (`git config user.email`). A CI gate
  (`.github/workflows/depersonalization.yml`) blocks personal email addresses and OS
  user-home paths from entering the repo — in file content, in commit messages, and in
  commit author/committer identity.
- **No personal data in examples.** The worked examples under `examples/` are sanitized and
  illustrative (fixture names, representative bookings). Keep your own trip data in `trips/`,
  which is git-ignored and never published.
- **Keep links valid.** A CI gate checks markdown links; broken local links fail the build.

## Making a change

1. Branch from `main`.
2. Make the change. If it changes agent behavior, exercise it in Claude Code and sanity-check the output.
3. Open a PR and fill in the template. Put any `Closes #N` **only** in the *Issue References* block at the bottom of the PR body (the auto-close parser is lexical).
4. CI must be green: workflow lint, markdown link integrity, secret scan, and the personal-data gate.

## Cutting a release

A release is a change like any other: it follows *Making a change* above, start to
finish. The one part worth writing down is where the CHANGELOG entry goes, because
the obvious place — a quick commit to `main` once the release has merged — is the one
place the gates cannot see it.

**The `## [X.Y.Z]` CHANGELOG entry is a release-branch artifact.** Write it on the
release branch so it lands through the release PR with everything else. The entry
carries no merge SHA and no tag, so nothing in it has to wait for the merge.

1. Branch from `main` — `release/vX.Y.Z-<short-slug>`.
2. Do the work of the release on that branch.
3. Add the `## [X.Y.Z]` CHANGELOG entry **on the same branch**, before opening the PR.
4. Open the release PR and fill in the template, per *Making a change* step 3.
5. Wait for CI, per *Making a change* step 4. The personal-data gate reads the PR's
   diff and the PR's commit messages and author identities — so the CHANGELOG entry
   is covered by it only if the entry is in the PR.
6. Merge the PR. Tag `vX.Y.Z` on the resulting merge commit and publish the release
   from that tag. The tag then carries its own changelog entry, which it does not if
   the entry lands afterwards.

**Nothing in a release is committed to `main` directly** — not the CHANGELOG, not
anything else. A direct push to `main` skips the pull-request requirement and all
four required checks in a single step; see [SECURITY.md](SECURITY.md), *Branch
Protection Posture*, for why that is possible and what it costs. The personal-data
gate also runs on pushes to `main`, so such a push is scanned and reported — but
after it has landed, not before.

## Reporting security issues

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Do not open a public issue, PR, or discussion.
