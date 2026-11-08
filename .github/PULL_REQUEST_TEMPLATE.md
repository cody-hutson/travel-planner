<!-- This body is a summary plus links: say what the change does and point at its records. -->
<!-- Per-stage detail belongs in the stage sub-task comments, not in new body sections. -->

## Summary

<!-- What changed and why, in 2-3 sentences. -->

## Type of change

<!-- Check all that apply -->
- [ ] Agent prompt (`agents/`)
- [ ] Worked example (`examples/`)
- [ ] Template (`templates/`)
- [ ] Reference / site spec (`reference/`)
- [ ] Docs (`README`, `CLAUDE.md`, `SECURITY.md`)
- [ ] Repo config (`.github/`)

## Checklist

- [ ] If this changes agent behavior, I exercised it in Claude Code and the output is sensible
- [ ] Markdown links resolve (local files exist; external links load)
- [ ] No personal data, secrets, or private-repo references introduced

## Conduct suite result

<!-- Asked for only when .github/workflows/integration-note.yml's conduct-suite job flags this pull -->
<!-- request: a change to skills/trip-record/interview-conduct.md or templates/interview-card.md, a -->
<!-- guided form's line at or below its end-of-profile marker, or a block-owned form's > line. -->
<!-- Write it as plain lines, with no heading, no bold-led block and no task-list item: the -->
<!-- mechanical suite's status by reference (its required check reports on this pull request), the -->
<!-- grade record's revision, and each generated conversation's verdict. Left as these comments, -->
<!-- the section reads as empty; on a draft that is a notice, and it binds once ready for review. -->
<!-- The job also reads freshness on every flagged pull request. Where it applies, say so on a line -->
<!-- of its own: regrade: pending — <where it is tracked>, or: not exercised by the generated route -->
<!-- To know before opening whether it is asked for, run -->
<!-- ./scripts/check-integration-note.py --check-conduct --base origin/main --head HEAD --body-file <draft body> -->

## Integration note

<!-- Asked for only when .github/workflows/integration-note.yml flags a file: a large addition to -->
<!-- an existing tracked markdown file that deletes little. Say what this change removed, merged -->
<!-- or superseded to make room, or say in a sentence why nothing could be. Left as these -->
<!-- comments, the section reads as empty; the check reads that a note is there, never whether it is true. -->
<!-- A heading of any level ends this section: write the note as plain lines. -->
<!-- Write it when the pull request opens. To know before opening whether one is asked for, run -->
<!-- ./scripts/check-integration-note.py --check --base origin/main --head HEAD --body-file <draft body> -->

---

### Issue References

<!-- THIS is the only place a close-family verb may appear with #N. -->
<!-- GitHub's auto-close parser is lexical — a "closes #N" in any other section triggers an -->
<!-- unintended auto-close regardless of surrounding wording. CI enforces this via -->
<!-- .github/workflows/pr-body-parser-clean.yml. -->
<!-- Use "Closes #N" for a full fix, or "Refs #N" for partial / ongoing work. -->
