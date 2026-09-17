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
the obvious alternatives to the release branch both fail — for different reasons, and
only one of them is about the gates.

**A commit pushed straight to `main` after the release merges is not gate-covered.**
The required checks are a *merge* gate, not a *branch* gate — see
[SECURITY.md](SECURITY.md), *Branch Protection Posture* — so a direct push does not
fail them; they are simply never required, and the result reads as a clean `main`
rather than as a bypass. That argument rules out the direct push, and only the direct
push. A follow-up pull request that carries the entry is gate-covered like any other
pull request, so this reason does not rule that one out — step 6 gives the reason that
does.

**The `## [X.Y.Z]` CHANGELOG entry is a release-branch artifact.** Write it on the
release branch so it lands through the release PR with everything else. The entry
carries no merge SHA and no tag, so nothing in it has to wait for the merge.

1. Branch from `main` — `release/<short-slug>`, with no version in the name. The
   version is claimed when the release merges, so a branch cut days earlier cannot hold
   one: a name that asserts a version goes stale on its way to the merge.
2. Do the work of the release on that branch.
3. Add the `## [X.Y.Z]` CHANGELOG entry **on the same branch**, at any point before the PR merges — including after step 4, when a draft PR is opened early and extended.
   **Date the entry the day you write it** — not the merge day, not the tag day: the entry is
   authored before the merge, so the merge date isn't knowable without guessing at a future one,
   and re-dating at merge time would put back the post-merge touch this section exists to remove.
   An entry's date can therefore be a day or two earlier than its tag; entries before `0.12.0`
   predate this rule.
   **Stamp the version last.** Draft the entry's prose whenever it suits the work, but write
   the `## [X.Y.Z]` heading itself in the last commit before the merge, with the version
   checked unclaimed at that moment. Until the merge the entry is an ordinary branch
   artifact: if another release claims that version first, edit the heading and push again.
   Nothing is tagged yet, so nothing that would have to be undone has happened.
4. Open the release PR and fill in the template, per *Making a change* step 3.
5. Wait for CI, per *Making a change* step 4. The personal-data gate reads the PR's
   diff and the PR's commit messages and author identities — so the CHANGELOG entry
   is covered by it only if the entry is in the PR.
6. Merge the PR. Tag `vX.Y.Z` on the resulting merge commit and publish the release
   from that tag. The tag then carries its own changelog entry, which it does not if
   the entry lands afterwards. The tag is also the step with nothing after it — which is
   why every mutable part of this procedure, the branch name and the prose and the
   version heading alike, is ordered before it.

**Nothing in a release is committed to `main` directly** — not the CHANGELOG, not
anything else. A direct push to `main` skips the pull-request requirement and all
nine required checks in a single step; see [SECURITY.md](SECURITY.md), *Branch
Protection Posture*, for why that is possible and what it costs. The personal-data
gate also runs on pushes to `main`, so such a push is scanned and reported — but
after it has landed, not before.

### Why earlier tags look different

A reader comparing recent tags will find shapes this section does not describe. Both
came from the same cause: the `## [X.Y.Z]` entry was written *after* the release
merged, in a separate `chore` close-out pull request, rather than on the release
branch. What differed between them was only where the tag went.

- **`0.17.0` through `0.22.0` — tagged on the close-out merge.** The entry had landed by
  the time the tag was cut, so those tags do carry their own entry. The outcome this
  section wants was reached by a different route.
- **`0.24.0` through `0.31.0` — tagged on the release merge.** By then the release merge
  was where the version got claimed, but the entry was still written afterwards, so each
  of these tags points at a tree carrying no entry for its own version — the tree
  describes the release before it. That is the outcome step 6 exists to prevent, and it
  is why step 6's reason survives while the gate argument above was re-aimed.

`0.23.0` and `0.32.0` were cut the way this section describes. `0.32.0` executed it end
to end: the entry landed on the release branch shortly before the merge, the tag went on
the merge commit, and the entry in the tagged tree was what the published release used
as its body.

The branch name has the same root. A version chosen when the branch is cut is a guess; a
version claimed when the branch merges is a fact — which is why step 1 leaves the version
out of the name and step 3 stamps it last. Practice reached that answer first: no release
branch cut since `0.23.0` has carried a version in its name.

## Reporting security issues

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Do not open a public issue, PR, or discussion.
