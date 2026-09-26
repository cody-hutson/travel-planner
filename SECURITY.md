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
| Required status checks | 9 — Workflow SAST (actionlint), Markdown link integrity (markdown-link-check), Secret scanning (gitleaks), Personal-data gate, Publish guard suite (test-publish-guard.sh), Artifact schema suite (test-artifact-schema.sh), Command taxonomy suite (test-command-taxonomy.sh), Trip resolution contract suite (test-trip-resolution-contract.sh), Corpus hygiene suite (test-corpus-hygiene.sh) | A merge is blocked until all nine pass. All nine are pinned to the GitHub Actions app, so only that app's check runs satisfy them. |
| Required approving reviews | 0 | Single-maintainer repository; there is no second reviewer to require. |
| Include administrators (`enforce_admins`) | **false** | The maintainer can push directly to `main`, bypassing the pull-request requirement and all nine required checks in one step. |

**All nine are app-pinned.** Each required context is bound to the GitHub Actions
app, so only a check run produced by that app satisfies it; a check run of the same
name from any other integration does not count. `Personal-data gate` was the one
exception until it was pinned — a weaker binding on one required check, never a
known bypass, and no evidence it was exercised.

**The consequence, stated plainly.** With `enforce_admins: false` the nine required
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

**The decision, and its mitigation.** The setting stays `false` for now. All seven
workflows that carry a required check — `.github/workflows/security.yml`,
`depersonalization.yml`, `publish-guard.yml`, `artifact-schema.yml`,
`command-taxonomy.yml`, `trip-resolution-contract.yml` and `corpus-hygiene.yml` —
trigger on pushes to `main` as well as on pull requests, so all nine checks *run*
against a direct push and a failure is recorded against the commit. **Running is
not blocking.** The residual risk is therefore detection after the fact, not
prevention: a direct push that carries personal data still lands on `main`, and
the gate reports it afterwards rather than refusing it. Nothing here makes a
direct push impossible; only `enforce_admins: true` would do that.

**What should reopen this.** A second direct push to `main` outside a genuine
break-glass event, or any direct push whose personal-data gate run fails. Either one
means the mitigation is carrying weight the setting should be carrying instead.

## Group approval — what an approval count proves

A trip can require named travellers' approvals before a changed plan republishes. This section states what that adds and what it can and cannot prove. The decision record behind it is [`reference/adr/ADR-029-group-approval-return-and-threshold.md`](reference/adr/ADR-029-group-approval-return-and-threshold.md).

**What it adds.** No server, account, key or service — the no-standing-server decision in [`reference/adr/ADR-002-living-site-refresh.md`](reference/adr/ADR-002-living-site-refresh.md) is upheld. On the organizer's machine, in the trip's git-ignored directory: `.approvers`, the declared approvers and how many of them must approve, and `.approvals`, one line for each approval or withdrawal the organizer records. On the group's own messaging service: a fixed-form approval line — the word `approve` and a 64-character code — which the service sees along with its usual metadata, such as who is in the group and when messages are sent. On the published site: an approval count and that code, and nothing that names anybody.

**What it proves, and what it does not.** Every approval is the organizer's statement, recorded at a terminal and marked `organizer-stated`; a traveller cannot sign their own. So the organizer can record an approval nobody gave, and can republish without the gate by not running it. What the feature delivers is **detectability**. An approval recorded for a traveller who did not give one is counted in the published count, which anyone can hold against the replies in the group's thread. An approver can compare the code they approved with the code on the site, and because the code is a SHA-256 digest of the plan, a different plan cannot carry the approved code. Each reply sits in the group's thread under the sender's own account, where the organizer cannot write for anyone else. The site shows the code's first eight characters grouped for comparison by eye, and a comparison by eye is bounded by that prefix: it catches an honest mistake, not a forgery.

**The trade-off against the no-server decision.** A service that collected approvals itself could count them without the organizer's hand, but this project rejects a standing server on merit rather than on cost, and even a signed approval would still reach the engine through the organizer's word about whose it is. The feature keeps the server-less model and pays for it in ceremony: the organizer transcribes each approval once, at a terminal. The change summary the organizer shares with the approval line is the same summary the group already received before this feature existed; how much of it the messaging service can read depends on whether the thread is end-to-end encrypted.

## Automated Security PRs — Pipeline Exemption

Dependabot version-update PRs and Dependabot security-update PRs are tagged with the `dependabot` label and bypass the standard issue triage flow. Dependency bumps are self-contained, reversible, and CI-validated; subjecting each to full proposal review would create overhead disproportionate to risk.

The `cluster: security` label is retained on these PRs so they remain discoverable in security audits.
