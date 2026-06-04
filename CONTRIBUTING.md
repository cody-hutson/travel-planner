# Contributing

Thanks for your interest in the travel-planner engine. It's a set of markdown agent
prompts driven by Claude Code — there's no build step and no application code.

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

## Reporting security issues

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Do not open a public issue, PR, or discussion.
