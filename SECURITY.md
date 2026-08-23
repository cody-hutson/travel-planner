# Security Policy

## Supported Versions

Only the latest commit on `main` is supported. Tagged releases are historical reference only — fixes ship to `main`.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this repository, please report it privately. **Do not open a public issue, PR, or discussion for security reports.**

- **Preferred:** [open a private security advisory](https://github.com/cody-hutson/travel-planner/security/advisories/new) (GitHub Private Vulnerability Reporting).
- **Email (alternate):** chutson.git@gmail.com — subject `[travel-planner security] <short description>`.
- **Include:** affected file(s) or commit, steps to reproduce, expected vs. actual behavior, and any proof-of-concept.

## Response Expectations

This is a personal project maintained by a single operator. Response targets are best-effort:

| Severity | Acknowledgement | Initial Response |
|----------|-----------------|------------------|
| Critical (RCE, credential exposure, data loss) | Within 1 business day | Within 3 business days |
| High (privilege escalation, secrets leakage) | Within 3 business days | Within 7 business days |
| Medium / Low | Within 7 business days | Best-effort |

You will receive an acknowledgement, an initial assessment, and a remediation plan or rationale for non-action.

## Scope

**In scope:**
- Agent prompts in `agents/` (markdown agent definitions consumed by Claude Code)
- Worked example artifacts in `examples/` (sanitized end-to-end trip walkthroughs)
- Reference architecture in `reference/` (site-layout spec and other design notes)
- Template files in `templates/` (trip-context templates)
- Top-level governance: `CLAUDE.md`, `README.md`
- GitHub Actions workflows in `.github/workflows/`
- Repository configuration (Dependabot, branch settings, issue templates, PR template)

**Out of scope:**
- Operator-local configuration (`~/.gitconfig`, IDE plugins, OS settings)
- Travel data the operator creates locally that does NOT land in `examples/` (operator-managed; never committed)
- Third-party services referenced by agent prompts (Google Maps, Tabelog, Yelp, etc. — report to the upstream service)

## Defenses Currently in Place

| Control | Status |
|---------|--------|
| Dependabot vulnerability alerts | Enabled (auto on visibility flip to public) |
| Dependabot security updates (auto-PR) | Enabled |
| Dependabot version updates (scheduled) | See `.github/dependabot.yml` (github-actions ecosystem only — this is a markdown-only repo) |
| Workflow YAML SAST (actionlint) | See `.github/workflows/security.yml` |
| Markdown link integrity (markdown-link-check) | See `.github/workflows/security.yml` |
| Secret scanning (gitleaks, full history) | See `.github/workflows/security.yml` |
| Native GitHub Secret Scanning | Auto-enables on visibility flip to public |
| Native GitHub Push Protection | Auto-enables on visibility flip to public |
| Branch protection on `main` | Enabled (force-push blocked, deletions blocked, required status checks, stale-review dismissal, required conversation resolution) — see *Branch Protection Posture* below for the administrator exemption |

## Branch Protection Posture

`main` runs with **`enforce_admins: false`**. That is a deliberate choice, recorded
here rather than left implicit, because it decides whether any of the protections
above bind the person most likely to touch the branch.

| Setting | Value | What it means |
|---------|-------|---------------|
| Require a pull request before merging | On | A non-administrator cannot push to `main` at all. |
| Required status checks | 4 — Workflow SAST (actionlint), Markdown link integrity (markdown-link-check), Secret scanning (gitleaks), Personal-data gate | A merge is blocked until all four pass. |
| Required approving reviews | 0 | Single-maintainer repository; there is no second reviewer to require. |
| Include administrators (`enforce_admins`) | **false** | The maintainer can push directly to `main`, bypassing the pull-request requirement and all four required checks in one step. |

**The consequence, stated plainly.** With `enforce_admins: false` the four required
checks are a *merge* gate, not a *branch* gate. An administrator pushing directly to
`main` does not fail them — they are simply never required, so the result reads as a
clean `main` rather than as a bypass. GitHub reports the bypass in the response to
that one push and nowhere the repository surfaces afterwards. This has happened once:
the `0.9.0` CHANGELOG commit reached `main` without a pull request, and the
personal-data gate is absent from the four checks recorded against it.

**The argument for keeping it.** A single maintainer with no second reviewer has no
one to unblock the repository if a required check itself becomes impossible to pass —
a bad workflow edit, or an outage in an action the check depends on.

**The argument against, which is the stronger one.** That break-glass path already
exists without the exemption: an administrator can turn `enforce_admins` off, push,
and turn it back on. Those are the same two clicks, but they leave an explicit,
timestamped settings change instead of a silent per-push bypass. `enforce_admins:
false` therefore buys convenience rather than capability, and it costs the only
automated guarantee this public repository has that nothing reaches `main` unscanned.

**The decision, and its mitigation.** The setting stays `false` for now. Both
workflows that guard `main` — `.github/workflows/security.yml` and
`.github/workflows/depersonalization.yml` — trigger on pushes to `main` as well as on
pull requests, so all four checks *run* against a direct push and a failure is
recorded against the commit. **Running is not blocking.** The residual risk is
therefore detection after the fact, not prevention: a direct push that carries
personal data still lands on `main`, and the gate reports it afterwards rather than
refusing it. Nothing here makes a direct push impossible; only `enforce_admins: true`
would do that.

**What should reopen this.** A second direct push to `main` outside a genuine
break-glass event, or any direct push whose personal-data gate run fails. Either one
means the mitigation is carrying weight the setting should be carrying instead.

## Automated Security PRs — Pipeline Exemption

Dependabot version-update PRs and Dependabot security-update PRs are tagged with the `dependabot` label and bypass the standard issue triage flow. Dependency bumps are self-contained, reversible, and CI-validated; subjecting each to full proposal review would create overhead disproportionate to risk.

The `cluster: security` label is retained on these PRs so they remain discoverable in security audits.
