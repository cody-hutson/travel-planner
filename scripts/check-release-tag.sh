#!/usr/bin/env bash
#
# check-release-tag.sh — the release-tag check.
#
#   scripts/check-release-tag.sh vX.Y.Z    grade one release tag — the release procedure, at tag time
#   scripts/check-release-tag.sh --all     grade every v* tag in this repository — the census
#
# A release tag is the last step of a release and is not rewritten once it is pushed, so what a
# tag must carry is checked against the tag itself, before the push. This script is that check.
# scripts/push-release-tag.sh runs it on the tag CONTRIBUTING.md, Cutting a release, step 6 has
# just created locally, and pushes only on exit 0.
# scripts/test-corpus-hygiene.sh group G runs it over every tag on every push and pull request,
# and holds the tags known to fail against the release-tag-declaration fence in CONTRIBUTING.md.
# The predicate lives here and nowhere else: group G compares this script's verdicts with that
# declaration and grades nothing about a tag itself.
#
# ── WHAT IT ASSERTS — one LIMB per property, every limb on every tag ────────────────
#   changelog  The tagged tree's CHANGELOG.md carries the tag's own `## [X.Y.Z]` heading, outside
#              any fenced code block, and that heading is the NEWEST version heading there: no
#              other `## [<version>]` heading comes before it. A heading whose bracket does not
#              hold a three-part version — `## [Unreleased]` — is not a version heading and is
#              passed over. The version is the tag name without its leading `v`.
#
#              WHY "NEWEST" AND NOT MERELY "PRESENT". The heading is stamped last and the version
#              is claimed at the merge, so the version can move: another release may claim the
#              slot first. A tree that carries both releases' entries carries the other one's
#              heading as well, and a presence test would pass a tag that names it. Requiring the
#              tag's version to be the newest entry in its own tree refuses that tag, and refuses
#              a tag whose heading was not restamped after the slot moved.
#
#   tagger     The tag is an annotated tag whose tagger address is in the no-reply form. The form
#              is identity_in_form in scripts/check-identity-form.sh, the one definition the
#              personal-data gate applies to a commit's author and committer. The gate's exception
#              for the host's committer binds commits alone, so that address fails here. The tagger
#              graded is the tag object's own, as git reads it.
#
#              WHY A LIGHTWEIGHT TAG FAILS. It has no tagger to read, and a tag that cannot show
#              one is refused under a reason of its own rather than passed: a Release published on
#              a new tag name makes a lightweight tag on the host, and passing them would let that
#              one through unread.
#
#              WHAT THIS LIMB CANNOT SEE. The identity a signing key is bound to. A tag object holds
#              its tagger line and its signature; the identity a signature verifies to is supplied
#              only by a verifier's own mapping, on the verifier's machine. No check here reads that
#              mapping, so a tag can pass this limb and verify under another address. Nor can it see
#              whose address the tagger's is: this reads text, and a no-reply address is public.
#
#   Before any limb runs, the tag itself is checked, under the name `ref`: the name must be
#   vX.Y.Z and the tag must peel to a commit. A tag failing either is reported with no limb run.
#
# ── ADDING A LIMB ─────────────────────────────────────────────────────────────────────
# A limb is a function `limb_<id> <tag> <version> <commit>` that prints exactly one line,
#   TAG <tag> <id> PASS <detail>     or     TAG <tag> <id> FAIL <reason> <detail>
# and returns 0 (passed), 1 (failed) or 2 (could not evaluate). Adding one is adding its id to
# the LIMBS array and writing its function; both modes run every limb on every tag. A tag that fails a new
# limb for reasons in the past is declared in the release-tag-declaration fence as
# `<tag>  <id>:<reason>` — a reason is one token, so a row stays two columns.
#
# ── EXIT STATUS ───────────────────────────────────────────────────────────────────────
#   0  every graded tag passed every limb
#   1  at least one tag failed — a FINDING, and every failing tag is printed
#   2  NOT-EVALUATED — no tag was found, a named tag is absent, the argument is not vX.Y.Z, a read
#      failed, or the form's definition is not beside this script, cannot be run, or did not answer
#      1 and 0 for the two addresses it is asked first. Nothing is graded on this status and no
#      count is printed: it is never a clean result, and the census never reports one.
#
# ── WHAT IT READS, AND WHAT IT NEVER WRITES ──────────────────────────────────────────
# Refs and objects only, through git plumbing (for-each-ref, rev-parse, ls-tree, cat-file), in
# the repository of the working directory, as git itself resolves it. No working-tree file of that
# repository is read, and no ref, object, index entry or file is written; there is no network. The
# one file it uses is scripts/check-identity-form.sh, beside this script, which it runs as a
# command rather than sourcing it: twice before any tag is graded, on one planted address outside
# the form and one in it, then once per tagger. Sourced, a line that ended that file early would end
# this check with it, at exit 0 and silent, on every tag; run, the same line answers 0 for the
# address outside the form, and the check says NOT-EVALUATED. A CI checkout
# carries tags only at fetch-depth: 0 — at any lower depth the census finds none and says
# NOT-EVALUATED rather than reading an empty set as clean.
#
# ── OUTPUT ────────────────────────────────────────────────────────────────────────────
#   TAG <tag> <limb> PASS <detail>
#   TAG <tag> <limb> FAIL <reason> <detail>
#   READ <n> tag(s); limb(s): <ids>; <p> passed every limb, <f> failed
# or one line and nothing else:
#   NOT-EVALUATED: <cause> — this is not a clean result
#
# Reasons:  ref        malformed-name  the tag is not vX.Y.Z (census only; as an argument, exit 2)
#                      no-commit       the tag does not peel to a commit
#           changelog  no-changelog    the tagged tree has no CHANGELOG.md
#                      no-entry        no `## [X.Y.Z]` heading for the version, outside a fence
#                      not-newest      the heading is there, and another version's comes first
#           tagger     no-tagger       the tag is lightweight, or its tag object names no address
#                      out-of-form     the tagger's address is outside the no-reply form
#
# Pure bash and POSIX awk, written for bash 3.2 as well as 5, and for any POSIX awk. It holds no
# pipe: every reader is fed by a here-string or a file, so no writer can die on a closed pipe.
#
set -uo pipefail
export LC_ALL=C

LIMBS=(changelog tagger)
RELEASE_TAG_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'

usage() {
  printf 'usage: %s vX.Y.Z | --all\n' "${0##*/}" >&2
}

not_evaluated() {  # not_evaluated <cause> — the one line printed when nothing can be graded
  printf 'NOT-EVALUATED: %s — this is not a clean result\n' "$1"
  exit 2
}

# ── limb_changelog <tag> <version> <commit> ───────────────────────────────────────────
limb_changelog() {
  local tag="$1" version="$2" commit="$3" entry blob verdict newest line
  if ! entry="$(git ls-tree "$commit" -- CHANGELOG.md)"; then
    return 2
  fi
  if [ -z "$entry" ]; then
    printf 'TAG %s changelog FAIL no-changelog commit=%s\n' "$tag" "${commit:0:12}"
    return 1
  fi
  if ! blob="$(git cat-file blob "$commit:CHANGELOG.md")"; then
    return 2
  fi
  # One pass over the blob. The fence delimiter is built from its character code so this file
  # carries no backtick. A version heading is `## [` at column 1 holding a three-part version.
  if ! verdict="$(awk -v want="$version" '
    BEGIN { fm = sprintf("%c%c%c", 96, 96, 96); newest = ""; line = 0 }
    { t = $0; sub(/^[ \t]+/, "", t) }
    substr(t, 1, 3) == fm { fence = !fence; next }
    fence { next }
    substr($0, 1, 4) == "## [" {
      v = substr($0, 5); e = index(v, "]")
      if (e == 0) next
      v = substr(v, 1, e - 1)
      if (v !~ /^[0-9]+\.[0-9]+\.[0-9]+$/) next
      if (newest == "") newest = v
      if (v == want && line == 0) line = NR
    }
    END { printf "%s %d\n", (newest == "" ? "none" : newest), line }
  ' <<<"$blob")"; then
    return 2
  fi
  read -r newest line <<<"$verdict"
  if [ "${line:-0}" -eq 0 ]; then
    printf 'TAG %s changelog FAIL no-entry newest-entry=%s\n' "$tag" "$newest"
    return 1
  fi
  if [ "$newest" != "$version" ]; then
    printf 'TAG %s changelog FAIL not-newest line=%s newest-entry=%s\n' "$tag" "$line" "$newest"
    return 1
  fi
  printf 'TAG %s changelog PASS line=%s\n' "$tag" "$line"
  return 0
}

# ── limb_tagger <tag> <version> <commit> ──────────────────────────────────────────────
# Git's own reader, so an address means what it means to every other git command. A lightweight
# tag's object is its commit, and git prints no address for it.
limb_tagger() {
  local tag="$1" entry kind address
  if ! entry="$(git for-each-ref --format='%(objecttype) %(taggeremail)' "refs/tags/$tag")"; then
    return 2
  fi
  [ -n "$entry" ] || return 2
  read -r kind address <<<"$entry"
  address="${address#<}"
  address="${address%>}"
  if [ -z "$address" ]; then
    printf 'TAG %s tagger FAIL no-tagger object=%s\n' "$tag" "$kind"
    return 1
  fi
  if ! identity_in_form "$address"; then
    printf 'TAG %s tagger FAIL out-of-form address=%s\n' "$tag" "$address"
    return 1
  fi
  printf 'TAG %s tagger PASS in-form\n' "$tag"
  return 0
}

# ── grade <tag> — the ref checks, then every limb. Appends to OUT; sets TAG_FAILED. ──────
OUT=''
TAG_FAILED=0
grade() {
  local tag="$1" version commit limb line rc
  TAG_FAILED=0
  if ! [[ "$tag" =~ $RELEASE_TAG_RE ]]; then
    OUT="${OUT}TAG ${tag} ref FAIL malformed-name"$'\n'
    TAG_FAILED=1
    return 0
  fi
  version="${tag#v}"
  if ! commit="$(git rev-parse --verify --quiet "refs/tags/${tag}^{commit}" 2>/dev/null)"; then
    OUT="${OUT}TAG ${tag} ref FAIL no-commit"$'\n'
    TAG_FAILED=1
    return 0
  fi
  for limb in "${LIMBS[@]}"; do
    line="$("limb_$limb" "$tag" "$version" "$commit")"; rc=$?
    case "$rc" in
      0) ;;
      1) TAG_FAILED=1 ;;
      *) not_evaluated "the $limb limb could not read tag $tag (status $rc)" ;;
    esac
    OUT="${OUT}${line}"$'\n'
  done
  return 0
}

[ "$#" -eq 1 ] || { usage; exit 2; }
git rev-parse --git-dir >/dev/null 2>&1 || not_evaluated "the working directory is not inside a git repository"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || not_evaluated "this script could not locate its own directory"
[ -x "$HERE/check-identity-form.sh" ] || not_evaluated "scripts/check-identity-form.sh is not beside this script, or cannot be run, so the tagger limb has no rule to apply"
identity_in_form() { "$HERE/check-identity-form.sh" "$1" >/dev/null; }  # identity_in_form <address> — 0 when it is in the form
# Asked before any tag is graded. A definition that answered 0, or 1, to every address would grade
# every tagger alike, so nothing is graded unless it refuses the host's committer address and takes a
# synthetic one in the form: GitHub issues no account the id 0 and no login a doubled hyphen.
identity_in_form 'noreply@github.com'; form_out=$?
identity_in_form '0+release-tag--selftest@users.noreply.github.com'; form_in=$?
if [ "$form_out" -ne 1 ] || [ "$form_in" -ne 0 ]; then
  not_evaluated "scripts/check-identity-form.sh answered $form_out for an address outside the form and $form_in for one in it, where it must answer 1 and 0, so the tagger limb has no rule it can apply"
fi

case "$1" in
  --all)
    if ! tags="$(git for-each-ref --sort=version:refname --format='%(refname:strip=2)' 'refs/tags/v*')"; then
      not_evaluated "git for-each-ref could not list the tags"
    fi
    [ -n "$tags" ] || not_evaluated "no v* tag in this repository (a CI checkout carries tags only at fetch-depth: 0)"
    ;;
  -h|--help)
    usage; exit 2 ;;
  *)
    [[ "$1" =~ $RELEASE_TAG_RE ]] || { usage; not_evaluated "'$1' is not a release tag name of the form vX.Y.Z"; }
    git rev-parse --verify --quiet "refs/tags/$1" >/dev/null || not_evaluated "no tag $1 in this repository — create it locally first, then check it"
    tags="$1"
    ;;
esac

read_n=0; failed_n=0
while IFS= read -r t; do
  [ -n "$t" ] || continue
  read_n=$((read_n + 1))
  grade "$t"
  [ "$TAG_FAILED" -eq 0 ] || failed_n=$((failed_n + 1))
done <<<"$tags"

[ "$read_n" -gt 0 ] || not_evaluated "no tag was read"
printf '%s' "$OUT"
printf 'READ %d tag(s); limb(s): %s; %d passed every limb, %d failed\n' \
  "$read_n" "${LIMBS[*]}" "$((read_n - failed_n))" "$failed_n"
[ "$failed_n" -eq 0 ] || exit 1
exit 0
