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
| Branch protection on `main` | Enabled (force-push blocked, deletions blocked, required status checks, stale-review dismissal, required conversation resolution) |

## Automated Security PRs — Pipeline Exemption

Dependabot version-update PRs and Dependabot security-update PRs are tagged with the `dependabot` label and bypass the standard issue triage flow. Dependency bumps are self-contained, reversible, and CI-validated; subjecting each to full proposal review would create overhead disproportionate to risk.

The `cluster: security` label is retained on these PRs so they remain discoverable in security audits.
