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
  illustrative (fixture names, representative bookings). Keep your own trip data in your data
  folder — the one `~/.travel-planner/data-root` names (`CLAUDE.md` § *Resolving a trip*) — and
  never in the engine's own `trips/`; it is never published.
- **Keep links valid.** A CI gate checks markdown links; broken local links fail the build.

## Making a change

1. Branch from `main`.
2. Make the change. If it changes agent behavior, exercise it in Claude Code and sanity-check the output.
3. Open a PR and fill in the template. Put any `Closes #N` **only** in the *Issue References* block at the bottom of the PR body (the auto-close parser is lexical).
4. CI must be green — the required status checks are listed in [SECURITY.md](SECURITY.md), *Branch Protection Posture*.

**Adding or renaming a workflow job** meets the required-check registration census, a step
of the `Workflow SAST (actionlint)` job that reads every workflow through a YAML parser on
each pull request into `main` and fails it unless each job declares whether it binds, with
exactly one `# gate-efficacy: posture=required` or `# gate-efficacy: posture=advisory` line
as the first line of the comment block directly above its key and at the key's indentation,
and unless each job claiming `required` reports a literal name (its `name:`, or its key
where it has none) that no other job reports, carries no job-level `if:`, needs only jobs
that also claim `required`, sits in a workflow that `pull_request` triggers with no literal
`branches:` list that leaves out `main`, no `branches-ignore:` list that names it unless an entry opens with `!`
and no `types:` list that leaves out `synchronize`, and is listed both in `CONTEXT_ORDER` in
`scripts/pin-required-checks.py` and in [SECURITY.md](SECURITY.md), *Branch Protection
Posture*.

### Locale posture of the guard suites

A suite's verdicts are not meant to depend on the locale your shell exports. Each suite either
exports `LC_ALL=C` at its top, or leaves the locale unpinned and sets `LC_ALL=C` only on the calls
that need byte semantics — and the unpinned ones differ in what they assert about the rest. When
you move between suites, read the row for the one you are running rather than carrying the last
one's habit across.

| Suite | Posture | When you run it |
|---|---|---|
| `scripts/test-corpus-hygiene.sh`, `scripts/test-adr-conformance.sh` | export `LC_ALL=C` at the top of the file | your shell's locale never reaches them |
| `scripts/test-artifact-schema.sh` | unpinned; `LC_ALL=C` on the individual calls that need byte semantics, and group `LC` sets each member's locale inside the arm that compares under it | Group `LC` asserts on every run that `va_type_ok`'s slug predicate and `ca_delta`'s range parse answer the same under C and under a UTF-8 locale the host lists, and fails the run if none loads. The rest of the suite reads your locale: its verdict set was measured identical under `LC_ALL=C` and a UTF-8 default when this row was written, and that is not asserted. On an awk that answers the same in every locale, the `ca_delta` half of group `LC` skips instead, and `CA10` grades the engine by name, running `ca_delta` under mawk and gawk. |
| `scripts/test-command-taxonomy.sh` | unpinned; `LC_ALL=C` on the calls that need byte semantics, group `W`'s awk program and the command-order sort, and its locale arms set each member's locale inside the subshell that reads under it | Its edge trims read no locale: `trim` and group J's `rj_trimv` strip one fixed set, ASCII whitespace and U+00A0; its readers of a verb's frontmatter strip ASCII whitespace alone, so a frontmatter edge carrying U+00A0 is kept and reported, and the guided-entry carrier's two flag readers take `trim`'s set, because there the flag's presence is the defect, so a flag key led by U+00A0 is reported whichever way the runtime reads it. Arms `GQL`, `GJU` and `GQF` assert this on every run under C and under a UTF-8 locale the host lists, and fail the run if none loads. The rest of the suite reads your locale — every POSIX character class and bracket range it matches with, `collapse`, `lower`, the delimiter-row test and group J's class-row match among them, and every awk program and sort not pinned to C: its verdict set was measured identical under `LC_ALL=C` and a UTF-8 locale when this row was written, and that is not asserted. |
| `scripts/test-publish-guard.sh`, `scripts/test-trip-resolution-contract.sh` | unpinned; `LC_ALL=C` on the individual calls that need byte semantics | your shell's locale reaches everything except those calls |

A suite that reads differently with `LC_ALL=C` set than without it has a defect in the suite.
Report it against the suite rather than reading it as a failure of your change.

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
   **A decision record's number is taken on `main` before the record is written under it.**
   Releases that each pick the next free `ADR-NNN` race as releases that each pick the next
   version do, and the race ends differently. A version lost to another release is restamped,
   as step 3 says, and nothing published has to change. A record number is never reused or
   renumbered once it is published, so a collision that reaches `main` cannot be repaired by
   renaming either record. A release that authors a decision record therefore takes the
   record's number first, in a pull request of its own that merges before the record's file is
   named: `reference/adr/README.md` § *Number declarations* states how a number is taken and
   what holds it.
3. Add the `## [X.Y.Z]` CHANGELOG entry **on the same branch**, at any point before the PR merges — including after step 4, when a draft PR is opened early and extended.
   **Date the entry the day you write it** — not the merge day, not the tag day: the entry is
   authored before the merge, so the merge date isn't knowable without guessing at a future one,
   and re-dating at merge time would put back the post-merge touch this section exists to remove.
   An entry's date can therefore be a day or two earlier than its tag; entries before `0.12.0`
   predate this rule.
   **The entry also says what moved in the size fence this release**, read from what
   `CH_EMIT=growth ./scripts/test-corpus-hygiene.sh` prints before the entry's prose is final,
   and the decision taken on it — a row re-pinned, and why, or a section relocating, with its
   issue filed and linked — or it says that nothing moved worth naming; at the release that
   seeds `reference/size-fence.md` every row is new, so nothing moved against an earlier fence,
   and the entry says so.
   **Stamp the version last.** Draft the entry's prose whenever it suits the work, but write
   the `## [X.Y.Z]` heading itself in the last commit before the merge, with the version
   checked unclaimed at that moment. Until the merge the entry is an ordinary branch
   artifact: if another release claims that version first, edit the heading and push again.
   Nothing is tagged yet, so nothing that would have to be undone has happened.
4. Open the release PR and fill in the template, per *Making a change* step 3.
5. Wait for CI, per *Making a change* step 4. The personal-data gate reads the PR's
   diff and the PR's commit messages and author identities — so the CHANGELOG entry
   is covered by it only if the entry is in the PR.
6. Merge the PR. Tag `vX.Y.Z` on the resulting merge commit — locally first — and run
   `scripts/check-release-tag.sh vX.Y.Z` before the tag leaves your machine. The check reads
   the tagged tree and refuses the tag unless its `CHANGELOG.md` carries `## [X.Y.Z]` as the
   newest version heading; it changes nothing. Push the tag only when the check exits 0, then
   publish the release from that tag. The tag then carries its own changelog entry, which it
   does not if the entry lands afterwards. The tag is also the step that cannot be taken back —
   which is why every mutable part of this procedure, the branch name and the prose and the
   version heading alike, is ordered before it, and why the check runs before the push.
   **If the check refuses the tag, do not push it.** Delete it locally (`git tag -d vX.Y.Z`),
   land the missing or corrected heading through a pull request, and tag that pull request's
   merge commit instead. A version that moved after its heading was stamped is refused the
   same way: if another release claimed the version first and the heading was not restamped,
   the version this tag names is not the newest entry in its own tree.
   The same check runs over every existing tag on every push and pull request, in
   `scripts/test-corpus-hygiene.sh` group **G**. A tag pushed without its entry turns that
   required check red until it is declared under *Why earlier tags look different* below —
   a pushed tag is not rewritten, so the declaration is the remedy left.
7. After the release, ratify any decision record it landed as `Proposed`: a pull request of its
   own into `main`. `reference/adr/README.md` § *Convention* states the practice and what the
   ratifying change sets, under *What an amendment may add*.

**The release PR body is a summary plus links, not a second copy of the work.**
Each stage of a release records its own detail durably, in a comment on that
stage's sub-task, so the body's job is to say what the release does and point at
those records. Write it when the PR opens and leave it that way: a later slice, a
remediation round or a re-review belongs where the rest of its stage's detail
already lives, or in a comment on the PR — not appended to the body. Appending
makes the body a moving target for whoever is reviewing it, and stores a second
copy of something that was never at risk of being lost. The only addition the body
takes after the PR opens is an integration note that the integration-note check
(`.github/workflows/integration-note.yml`) asks for, because that check reads the
body and nothing else.

**Nothing in a release is committed to `main` directly** — not the CHANGELOG, not
anything else. A direct push to `main` skips the pull-request requirement and all
ten required checks in a single step; see [SECURITY.md](SECURITY.md), *Branch
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

`0.9.0` through `0.11.0` and `0.34.0` also point at trees carrying no entry for their own
version. Each of the first group's entries first appears in the next release's tagged tree;
`0.34.0`, the first release cut after this section was written, was tagged on its release merge
before its entry landed. `0.1.0` predates the CHANGELOG itself.

The fence below declares every tag whose own tree does not carry the entry step 6 requires.
`scripts/check-release-tag.sh --all` grades every tag, and `scripts/test-corpus-hygiene.sh`
group **G** holds its failures against this declaration in both directions: a tag that fails
and is not declared here fails the suite, and so does a row naming a tag that no longer fails
for the reason given. Tags are not protected against being moved or deleted, and a declaration
must not outlive the failure it excepts. Two columns, both required, whitespace-separated, as in
`reference/adr/README.md` § *Number declarations*: the tag, and one token naming the check's
limb and the reason it gives. A line whose first non-blank character is `#` is a comment.

```release-tag-declaration
# tag     limb:reason
v0.1.0    changelog:no-changelog
v0.9.0    changelog:no-entry
v0.9.1    changelog:no-entry
v0.10.0   changelog:no-entry
v0.11.0   changelog:no-entry
v0.24.0   changelog:no-entry
v0.25.0   changelog:no-entry
v0.26.0   changelog:no-entry
v0.27.0   changelog:no-entry
v0.28.0   changelog:no-entry
v0.29.0   changelog:no-entry
v0.30.0   changelog:no-entry
v0.31.0   changelog:no-entry
v0.34.0   changelog:no-entry
```

## Reporting security issues

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Do not open a public issue, PR, or discussion.
