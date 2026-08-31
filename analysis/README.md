# analysis/

Working space for analysis **about this repo** — audits, reviews, backlog scans, gap
analyses. One dated folder per piece of work.

Everything in here is git-ignored except this file. Analysis is working material: it is
written once, read for a while, and then goes stale. It is not repo content, so it stays
on your machine and never enters git history.

## Shape

One folder per analysis, named `<what>-YYYY-MM-DD/`, with a `SUMMARY.md` at its top:

```
analysis/
├── <what>-YYYY-MM-DD/
│   ├── SUMMARY.md      the findings — start here
│   ├── _cache/         raw pulls, intermediate scripts, scratch
│   └── evidence/       anything a finding cites
└── archive/            analyses kept past their sunset date
```

`SUMMARY.md` opens with frontmatter, so an analysis can always answer *what is this,
what was it for, and is it still good?*:

```yaml
---
analysis_type: audit | review | backlog-scan | link-audit | gap-analysis | research
work_item: what this analysis was serving
created: YYYY-MM-DD
sunset: YYYY-MM-DD        # default: created + 90 days
status: active | complete | executed | stale
---
```

## Sunset

Analysis accumulates unless something makes it stop. `sunset` is that something: past
its date, an analysis is stale — the repo has moved and its findings were true of a
commit that is no longer HEAD. Archive it or delete it; do not act on it.

Nothing expires on its own. No command sweeps this folder and no timer runs, so the
sunset date is a note to yourself, and the folder you have stopped opening is exactly
the one that will still be here in a year.

**Re-verify before acting on anything in here.** A finding is evidence about a past
state of the repo, not a claim about the current one — check it against the live tree
before it drives a change.

## Why this file is here

A clone has to show that `analysis/` is where analysis goes. This file is the only
tracked thing under it: `.gitignore` excludes the directory's *contents*
(`/analysis/*`) rather than the directory itself, so this signpost survives while
everything beside it stays local. The invariant is tested — see group Q in
[`../scripts/test-publish-guard.sh`](../scripts/test-publish-guard.sh).

Same arrangement as [`../trips/README.md`](../trips/README.md), for the same reason.
