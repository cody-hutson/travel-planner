# Publishing Runbook — the Publish Script's Operator Reference

**This document is the operator's reference for `scripts/publish-trip-site.sh`.** `CLAUDE.md` § *Publishing to GitHub Pages* keeps what an agent hands to the operator and can read nowhere else: what `<engine-root>` and `<data-root>` stand for, the first publish and the guard it runs, a rotation, the deleting takedown, and the plaintext opt-out with the rule that an agent never runs it. This document carries the rest, and every command in it runs as printed from any directory, its placeholders read as that section defines them.

## Private by default

A trip itinerary — dates, lodging, who you're travelling with — must not be world-readable, which is why the publish flow encrypts it (`CLAUDE.md` § *Publishing to GitHub Pages*). Free public Pages hosting still works because decryption happens client-side, in the viewer's browser, after they enter the passphrase.

## What a first publish prints

After the push, `publish` enables Pages and prints the live URL plus **where the passphrase is saved** — the path, never the value. Where the host reports no Pages site built from `main` at its root once the push has landed, it prints no URL, says how to serve the site, and exits non-zero: the one `gh api` line that enables Pages where no Pages site could be read back, or the repository's Pages settings, with the source the host reported, where one is built from elsewhere. The passphrase itself never reaches standard output on any path, so a captured or transcript-injected publish cannot disclose it; read it yourself with `cat <data-root>/trips/<destination>-<year>/.passphrase`, the path the publish prints.

## Passphrase

**Passphrase.** The trip's key of record is `trips/<destination>-<year>/.passphrase` (under `<data-root>`, never published); `publish` generates a strong one and saves it there when no key file exists there; a `.passphrase` that exists but cannot be read is refused, never replaced. `update` never generates a key: with no key it can read and `$STATICRYPT_PASSWORD` unset it refuses, naming `rotate`, and a site published `--plaintext` is in that state, where `rotate` encrypts it from then on and `unpublish` followed by `publish --plaintext` keeps it plaintext. `$STATICRYPT_PASSWORD`, when set, is used in its place — but where the trip also has a `.passphrase` holding a different key, or one that cannot be read as a key, `publish` and `update` refuse rather than choose between the two, before any network call. The remedy is to unset the variable; the only way to change the key is `rotate`. Before a push that re-encrypts, `update` confirms that the key it will use opens the page the site serves now, whichever store supplied it, and refuses otherwise, naming the mismatch; nothing is pushed. The key file is flushed to disk before any push that depends on it. Share the passphrase over a private channel — anyone with the passphrase can view the site; without it, the page is just a prompt.

## One at a time

**One at a time.** Publish commands on one trip run one at a time: a second `publish`, `update`, `rotate`, `unpublish` or `confirm` refuses at once, naming the one running. One that arrives in the first instants after another starts, before that one has recorded itself in the lock, reads the lock again for up to half a second and names it then; only where that record is still missing after the half second — a run stopped between taking the lock and recording itself, say — does the refusal say which command holds the lock is unknown. A lock left by a run that was killed outright is named in the refusal together with how to remove it, where that run's process is no longer running. A holder reported as running may still be stale: after a crash or a restart its process id can belong to an unrelated process, which the start time the refusal prints tells, and `ps -p <pid>` shows what that process is.

## Repo name

**Repo name.** By default the per-trip repo is `<destination>-<year>-trip`. Pass `--opaque` to `publish` to name it with a random token instead (`trip-<hex>`, no destination/year); the name is saved to `.publish-slug` so every later command resolves the same repo. To publish to a custom or pre-existing repo — a shorter shared name or an existing site — put the bare repo name in `trips/<destination>-<year>/.publish-slug` (under `<data-root>`). `publish`/`update`/`rotate`/`list`/`unpublish` all resolve it the same way. A pre-existing repo must serve its site from `main`: `update` and `rotate` refuse a trip whose clone is on any other branch, and name it. Its first push belongs to `publish`, and it must then be empty and public, as the host reports it: `publish` refuses a repo that holds anything, enables Pages and sets `main` as the default branch itself, and `update` and `rotate` refuse an empty repo, naming `publish`.

**Site is live at:** `https://<github-username>.github.io/<destination>-<year>-trip/` — the URL shows a passphrase prompt, not the itinerary.

## Updating after edits

**Updating after edits** (re-encrypt and re-publish only ciphertext):
```bash
<engine-root>/scripts/publish-trip-site.sh update trips/<destination>-<year> --data-root <data-root>
```

## A rotation that stops, and what it refuses

If an earlier `update` or `rotate` stopped at its push, `rotate` refuses until that page is dealt with: remove the trip's `.publish` directory (it is cloned again, and nothing is lost), or run `update` first if the current passphrase's holders should see the page. It reads the site before it writes anything, and refuses one it cannot reach, one rewound since this clone last recorded it, and one this clone is behind; the remedy for the last two is the same removal. A push that fails may still have reached the site: `.passphrase` already holds the new passphrase, and `update` finishes the rotation. `rotate` records that rotation beside the trip immediately after it writes the new key — the key file it wrote, and the page and the commit it replaced — and that record is what lets `update` publish under a key the live page is not yet under, while all three still stand; a site taken down and published again is a new commit, so it never matches. A successful push by `update` or `rotate` clears it. `rotate` also refuses a new passphrase that already opens the live page, because such a rotation would revoke nothing.

## Listing published sites

**Listing published sites** (read-only — never writes, encrypts, or pushes):
```bash
<engine-root>/scripts/publish-trip-site.sh list --data-root <data-root>
```
Prints every trip under `<data-root>/trips/` with its repo, live URL (or "not published"), last-published vs last-edited dates, and `build-to-published`: whether the page last pushed is the newest local build, compared by content rather than by clock. It is evaluated outside `trip.freshness`, is report-only, and needs no network (`skills/trip-publish/SKILL.md` § *list* declares it).

## What a takedown needs, and what persists after it

The default `unpublish` deletes the per-trip repo, and `CLAUDE.md` § *Publishing to GitHub Pages* carries both takedown lines. Deletion needs the `delete_repo` gh scope (grant once with `gh auth refresh -h github.com -s delete_repo`), and prompts you to type the repo name to confirm. `--disable-pages-only` instead disables Pages and keeps the repo (reversible). Either way `unpublish` is idempotent: it is a no-op where GitHub reports the repository — or, under `--disable-pages-only`, its Pages site — already gone. Where GitHub cannot be asked, or refuses the takedown, it says the site may still be served and exits non-zero, so `/trip-decommission archive` stops before it marks the trip. Content may persist in third-party caches or clones after takedown.

## What "private" means here

> **What "private" means here.** The published bytes are world-fetchable ciphertext; security rests on passphrase strength plus the 600k-iteration KDF, not on access control — anyone can download the file and attempt an offline guess. Use a strong passphrase. This is privacy-by-construction (a fresh repo, only ciphertext ever committed), not an identity-gated ACL.
>
> **What still leaks (metadata).** By default the per-trip repo is named `<destination>-<year>-trip` and is public, so the destination and year show on your GitHub profile even though the itinerary itself is encrypted; commit timestamps reveal when you publish. Only the itinerary *content* is protected — not the fact that the trip exists. Pass `--opaque` at publish (or set a custom name in `trips/<destination>-<year>/.publish-slug`) to keep destination/year out of the repo name; commit timestamps still reveal publish activity.
>
> **Trust boundary.** Encryption runs via `npx staticrypt` (pinned to an exact version); your passphrase is passed to that package at publish time, so you are trusting the pinned StatiCrypt release and the npm supply chain.
>
> The trip repo is independent from this engine repo — a standalone public repo containing only the encrypted `index.html`. The plaintext itinerary, agent outputs, and `.passphrase` stay under `<data-root>/trips/` and are never published.
