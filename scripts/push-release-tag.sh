#!/usr/bin/env bash
#
# push-release-tag.sh — the sanctioned way a release tag leaves this machine.
#
#   scripts/push-release-tag.sh vX.Y.Z
#
# A pushed tag is not rewritten, so the one check that can still refuse a tag has to run before the
# push rather than after it. CONTRIBUTING.md, Cutting a release, step 6 pushes a release tag through
# this script, and scripts/test-corpus-hygiene.sh group G holds it to that against a bare remote.
# It follows the rule the repository's other irreversible push follows: the guard runs inside the
# script that pushes, and any failure stops the push (reference/adr/ADR-002-living-site-refresh.md,
# section 4).
#
# ── WHAT IT DOES, IN THIS ORDER, STOPPING AT THE FIRST THAT FAILS ─────────────────────
#   1. Compares this checkout's copy of the release scripts with the tagged commit's.
#   2. Runs scripts/check-release-tag.sh on the tag, and goes on only if that exits 0. Any other
#      status stops it. Exit 1 is a tag the check refused; exit 2 is a check that measured nothing,
#      which is not a clean result; any other status is a check that did not finish.
#   3. Asks origin whether it already has the tag.
#   4. Pushes that one tag, and nothing else, with no force. Git refuses a plain push that would
#      change a tag the remote holds, so this push can only create one.
#   5. Reads the tag back from origin before it says so.
#
# ── WHICH COPY OF THE CHECK RUNS, AND WHY STEP 1 COMES BEFORE IT ──────────────────────
# The checkout's: the one beside this file, because running code read out of a tag's own tree would
# let the commit being graded supply its own grader. A checkout can be behind, though, and then its
# check lacks whatever limb the tagged commit added, so a tag could go out past a rule its own
# release shipped. Step 1 closes that: this script, the check and the form's definition must each
# match the tagged commit's blob byte for byte, or nothing is pushed. It runs before the check, so a
# checkout whose check is not the tagged commit's says so, rather than its check speaking for the
# tag. It therefore also refuses a checkout with an uncommitted edit to any of the three, and a tag
# on a commit older than this script. Both are refused rather than guessed at: bringing the checkout
# to the tagged commit either clears the refusal or shows that the tag is on the wrong commit.
#
# ── WHAT IT CANNOT SEE ────────────────────────────────────────────────────────────────
#   - A raw `git push` of the tag, or a push from a clone that does not run this script.
#   - A tag made on the host: a Release published on a new tag name, or one made in the web
#     interface. Neither passes through this machine.
#   - A check edited on the tagged commit as well as here. Step 1 compares the two copies, and only
#     review of the pull request that changed them can say whether the check still checks.
#   - Whether the tagged commit is on `main`. Step 6 names the merge commit; this does not read it.
#   - The identity a signing key is bound to, for the reason the check's own banner gives.
# scripts/test-corpus-hygiene.sh group G is the backstop for the first two: it grades every tag on
# the next push to a branch, after the tag is public, when a declaration row is the remedy left.
#
# ── EXIT STATUS ───────────────────────────────────────────────────────────────────────
#   0  the tag was pushed, and origin was read back holding it
#   1  the check refused the tag: nothing was pushed
#   2  nothing was evaluated, or a precondition failed: not one argument, the tag names no
#      commit here, the copies differ, or the check said NOT-EVALUATED or did not finish.
#      Nothing was pushed
#   3  origin could not be read, already has the tag, refused the push, or did not read back holding
#      it. Origin's copy of a tag it already had is unchanged; the line printed says which case
#
# Pure bash, written for bash 3.2 as well as 5. It holds no pipe, and it writes to nothing but origin.
#
set -uo pipefail
export LC_ALL=C

RELEASE_SCRIPTS=(check-release-tag.sh check-identity-form.sh push-release-tag.sh)

stop() {  # stop <status> <cause>
  printf 'NOT-PUSHED: %s\n' "$2"
  exit "$1"
}

[ "$#" -eq 1 ] || { printf 'usage: %s vX.Y.Z\n' "${0##*/}" >&2; exit 2; }
tag="$1"
# The check takes --all as its census mode, and a census that exits 0 is no verdict on a tag.
case "$tag" in -*) stop 2 "'$tag' is an option, and this takes one release tag name." ;; esac
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || stop 2 "this script could not locate its own directory"

# 1. This checkout against the tagged commit, before the check runs, so that a check which is not
#    the tagged commit's never gives the verdict on the tag.
commit="$(git rev-parse --verify --quiet "refs/tags/${tag}^{commit}")" \
  || stop 2 "$tag names no commit in this clone. Create it, annotated, on the merge commit, then run this again."
for f in "${RELEASE_SCRIPTS[@]}"; do
  here_id="$(git hash-object --no-filters -- "$HERE/$f")" \
    || stop 2 "scripts/$f could not be read from this checkout."
  there_id="$(git rev-parse --verify --quiet "$commit:scripts/$f")" \
    || stop 2 "the commit $tag names carries no scripts/$f, so it predates this path. Check the tag is on the merge commit."
  [ "$here_id" = "$there_id" ] \
    || stop 2 "scripts/$f here differs from the commit $tag names. Bring this checkout to that commit, with no edit to that file, and run this again."
done

# 2. The check. Its own lines print as they are, and they name the cause.
"$HERE/check-release-tag.sh" "$tag"
rc=$?
case "$rc" in
  0) ;;
  1) stop 1 "the release-tag check refused $tag. Delete it (git tag -d $tag) and fix what it names." ;;
  *) stop 2 "the release-tag check exited $rc on $tag, so it measured nothing. Act on the cause above, then run this again." ;;
esac

# 3. Origin. --exit-code answers 2 for a ref it does not hold, which is the only way on.
git ls-remote --exit-code origin "refs/tags/$tag" >/dev/null
rc=$?
case "$rc" in
  2) ;;
  0) stop 3 "origin already has $tag, and a pushed tag is not rewritten." ;;
  *) stop 3 "git ls-remote could not read origin (status $rc), so nothing was pushed." ;;
esac

# 4. The one tag. No follow-tags, so a clone configured to carry others does not.
git push --no-follow-tags origin "refs/tags/$tag:refs/tags/$tag" \
  || stop 3 "git push failed for $tag; git's own line above names why."

# 5. Read back: the claim below is what origin says, not what the push said.
local_id="$(git rev-parse --verify --quiet "refs/tags/$tag")" \
  || stop 3 "$tag is no longer readable here, so the push could not be confirmed."
remote_line="$(git ls-remote origin "refs/tags/$tag")" \
  || stop 3 "git ls-remote could not read origin after the push, so $tag is unconfirmed."
read -r remote_id _ <<<"$remote_line"
[ "$remote_id" = "$local_id" ] \
  || stop 3 "origin reads ${remote_id:-nothing} for $tag after the push, where this clone holds $local_id."
printf 'PUSHED: %s %s; origin read back holding it.\n' "$tag" "$local_id"
exit 0
