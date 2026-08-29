#!/usr/bin/env bash
#
# test-publish-guard.sh — regression tests for the publish safety guard + identity.
#
# Proves the security-critical behavior of publish-trip-site.sh without publishing
# anything: the pre-push guard is fail-closed (including against all-lowercase plaintext),
# plaintext leaks are caught, ciphertext passes, and commits use a no-reply identity even
# when hostile GIT_*_EMAIL env vars are set. Run it after editing verify_ciphertext.
#
#   ./scripts/test-publish-guard.sh
#
# Pure-bash tests (A–C2, F, H, I, K, L) always run. Identity (D) + unpublish idempotency (J1)
# skip without gh auth. Real-StatiCrypt tests (E, G) skip if npx/staticrypt is unavailable.
# H = --opaque naming (#6) · I = list / date helpers (#25) · J = unpublish / takedown (#7)
# K = trips/ ignore invariant (#254) · L = plaintext content guard (#123)
# L8-L10 grade the publishability DECLARATION: that the class has exactly one home, that
# the guard's verdict follows a change to it, and that an unreadable declaration is
# UNDETERMINED rather than an empty class. L11 pins the reserved-heading suppression —
# both limbs, one of which has no backstop.
# M = published-bytes / stoplist / freshness remediation (#123 A6.5) · N = block-scoped
# conjunctive window (#123 PR-7) · O = the [THIRD-PARTY] class: entry denylist,
# value-granularity mark, real derived-model shape (#123 AC 3).
#
# STRICT SKIP MODE (set by CI — .github/workflows/publish-guard.yml, per #123 AC 8).
#   GUARD_STRICT_SKIPS=1   a SKIP fails the run unless its group is declared below.
#   GUARD_EXPECTED_SKIPS   space-separated group ids whose skip is expected and stated.
# A skip used to contribute to the verdict exactly as a pass did, so a runner missing a
# dependency exited 0 with whole groups never run — a green that proves less than it
# looks like. Strict mode closes that. Unset, behaviour is exactly as it was.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolved BEFORE the source below, and absolutely: group PF reads this file and the
# publish script it sources. Taken after the source, BASH_SOURCE[0] is still this file,
# but the ordering is not left to be re-derived by a later reader.
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"
SELF_PUBLISH="$HERE/publish-trip-site.sh"
# shellcheck source=publish-trip-site.sh
source "$HERE/publish-trip-site.sh"      # BASH_SOURCE guard prevents dispatch
set +e

pass=0; fail=0; skip=0; SKIPPED=""
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
# Records the skipped group's id — the token before the first colon of the message — so
# the aggregate verdict at the bottom can refuse a run in which a group vanished.
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# Synthetic plaintext itinerary (no real data — generic place names only), token-rich.
SRC="$WORK/src.html"
cat > "$SRC" <<'HTML'
<!DOCTYPE html><html><head><title>Shibuya Trip</title></head><body>
<h1>Itinerary</h1>
<p>Day 1: Shibuya Crossing, then Marriott check-in. Dinner near Hokkaido Ramen.</p>
<p>Travelers: Tanaka party of four. Hotel confirmation TANAKA12345.</p>
</body></html>
HTML

# Tiny token-less source (to isolate the structural check in C2b).
TINY="$WORK/tiny.html"; printf '<html><body>trip</body></html>' > "$TINY"

# Well-formed StatiCrypt-like ciphertext (real markers, tiny visible body, no source tokens).
ENC_OK="$WORK/enc_ok.html"
cat > "$ENC_OK" <<'HTML'
<!DOCTYPE html><html><head><title>Protected Page</title></head><body>
<form id="staticrypt-form"><input type="password" placeholder="Enter passphrase"></form>
<script>var staticryptConfig={};var staticryptEncrypted="bb12ab";var cryptoEngine={};</script>
</body></html>
HTML

# LEAKY fixture: looks encrypted, tiny visible body, but a plaintext token sits in a script.
ENC_LEAK="$WORK/enc_leak.html"
cat > "$ENC_LEAK" <<'HTML'
<!DOCTYPE html><html><head><title>Protected Page</title></head><body>
<form id="staticrypt-form"><input type="password" placeholder="Enter passphrase"></form>
<script>var staticryptConfig={};var cryptoEngine={};var note="Shibuya Crossing at 9am";</script>
</body></html>
HTML

# THE C2 ATTACK: an ALL-LOWERCASE plaintext itinerary that carries the StatiCrypt sentinel
# strings + a password input, but whose body is plainly readable. The OLD token scan derived
# ZERO tokens from this (no uppercase/digits) and waved it through; the structural check must
# catch it on visible-body length alone.
PLAIN_LOWER="$WORK/plain_lower.html"
cat > "$PLAIN_LOWER" <<'HTML'
<!DOCTYPE html><html><head><title>my trip</title></head><body>
<p>day one: arrive in the morning, drop bags, then wander the old town for a few hours.
day two: a long lunch by the river, an afternoon museum, and a quiet dinner nearby.
day three: a day trip to the coast and back before the evening train home.</p>
<script>var staticryptConfig={};var cryptoEngine={};</script>
<input type="password" placeholder="passphrase">
</body></html>
HTML

echo "Guard behavior:"
# A — never certify the source as its own ciphertext (self-check).
if verify_ciphertext "$SRC" "$SRC"; then FAIL "A: guard certified the plaintext source as ciphertext"; else PASS "A: guard rejects source-as-output (self-check)"; fi
# B — passes clean ciphertext.
if verify_ciphertext "$ENC_OK" "$SRC"; then PASS "B: guard passes clean ciphertext"; else FAIL "B: guard rejected clean ciphertext"; fi
# C — catches a plaintext token leaked into otherwise-encrypted output.
if verify_ciphertext "$ENC_LEAK" "$SRC"; then FAIL "C: guard missed a leaked plaintext token"; else PASS "C: guard catches leaked plaintext token"; fi
# C2 — REGRESSION: all-lowercase plaintext with sentinel strings must be caught structurally.
if verify_ciphertext "$PLAIN_LOWER" "$TINY"; then FAIL "C2: guard PASSED all-lowercase plaintext (fail-open!)"; else PASS "C2: guard catches all-lowercase plaintext via visible-body check"; fi

echo "Slug resolution:"
# F — slug_for: default convention, .publish-slug override (whitespace-trimmed), invalid rejection.
SDIR="$WORK/osaka-2027"
[ "$(slug_for "$SDIR")" = "osaka-2027-trip" ] && PASS "F1: default slug = <dir>-trip" || FAIL "F1: default slug wrong"
mkdir -p "$SDIR"; printf '  custom-site-repo \n' > "$SDIR/.publish-slug"
[ "$(slug_for "$SDIR")" = "custom-site-repo" ] && PASS "F2: .publish-slug overrides default (trimmed)" || FAIL "F2: override not honored"
printf 'bad name!\n' > "$SDIR/.publish-slug"
if ( slug_for "$SDIR" ) >/dev/null 2>&1; then FAIL "F3: invalid slug not rejected (fail-open)"; else PASS "F3: invalid slug rejected"; fi
rm -f "$SDIR/.publish-slug"

echo "No-reply commit identity:"
if gh auth status >/dev/null 2>&1; then
  resolve_noreply_identity
  if grep -qE '@users\.noreply\.github\.com$' <<<"$NOREPLY_EMAIL"; then
    PASS "D1: resolved no-reply email ($NOREPLY_EMAIL)"
  else
    FAIL "D1: email is not a no-reply address ($NOREPLY_EMAIL)"
  fi
  R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q
  echo x > "$R/f"; git -C "$R" add f
  commit_noreply "$R" "test"
  ae="$(git -C "$R" log -1 --format='%ae')"
  if grep -qE '@users\.noreply\.github\.com$' <<<"$ae"; then PASS "D2: commit author email is no-reply ($ae)"; else FAIL "D2: commit leaked a non-no-reply email ($ae)"; fi
  # D3 — REGRESSION: hostile GIT_*_EMAIL env must NOT override the no-reply identity.
  R2="$WORK/repo2"; mkdir -p "$R2"; git -C "$R2" init -q
  echo x > "$R2/f"; git -C "$R2" add f
  GIT_AUTHOR_EMAIL='leak@personal.com' GIT_COMMITTER_EMAIL='leak@personal.com' \
    GIT_AUTHOR_NAME='Leaky' GIT_COMMITTER_NAME='Leaky' commit_noreply "$R2" "test"
  ae2="$(git -C "$R2" log -1 --format='%ae')"; ce2="$(git -C "$R2" log -1 --format='%ce')"
  if grep -qvE 'leak@personal\.com' <<<"$ae2|$ce2" && grep -qE '@users\.noreply\.github\.com$' <<<"$ae2"; then
    PASS "D3: hostile GIT_*_EMAIL env did NOT leak (author=$ae2 committer=$ce2)"
  else
    FAIL "D3: env var leaked a personal email into the commit (author=$ae2 committer=$ce2)"
  fi
else
  SKIP "D: gh not authenticated"
fi

echo "Real StatiCrypt smoke test:"
if command -v npx >/dev/null 2>&1; then
  ENC_DIR="$(encrypt_to_tmp "$SRC" "correct-horse-battery-staple-1" 2>/dev/null)"
  if [ -n "${ENC_DIR:-}" ] && [ -f "$ENC_DIR/index.html" ]; then
    real="$ENC_DIR/index.html"
    grep -qi staticrypt "$real" && PASS "E1: real output carries StatiCrypt markers" || FAIL "E1: no StatiCrypt markers"
    grep -qiE 'password|passphrase' "$real" && PASS "E2: real output shows a passphrase prompt" || FAIL "E2: no passphrase prompt"
    if grep -qF "Shibuya" "$real" || grep -qF "TANAKA12345" "$real"; then FAIL "E3: PLAINTEXT TOKEN found in real ciphertext"; else PASS "E3: zero plaintext itinerary tokens in real ciphertext"; fi
    if verify_ciphertext "$real" "$SRC"; then PASS "E4: guard passes real StatiCrypt output"; else FAIL "E4: guard rejected real StatiCrypt output"; fi
    rm -rf "$ENC_DIR"
  else
    SKIP "E: staticrypt could not run (offline or npx blocked)"
  fi
else
  SKIP "E: npx unavailable"
fi

echo "Boilerplate subtraction (false-positive fix):"
if command -v npx >/dev/null 2>&1; then
  # Itinerary whose words (Check, Center, Closed) also live in StatiCrypt's shell, plus a
  # distinctive token (Shibuya) that does not. Encrypts correctly either way; the only
  # difference is whether the guard false-flags the common words.
  CMN="$WORK/common.html"
  cat > "$CMN" <<'HTML'
<!DOCTYPE html><html><head><title>Trip</title></head><body>
<h1>Itinerary</h1><p>Check-in at the Center hotel. Museum Closed Monday. Shibuya at night.</p>
</body></html>
HTML
  ENC_CMN="$(encrypt_to_tmp "$CMN" "common-words-passphrase-1" 2>/dev/null)"
  BOIL="$(make_boilerplate 2>/dev/null || true)"
  if [ -n "${ENC_CMN:-}" ] && [ -n "${BOIL:-}" ] && [ -f "$ENC_CMN/index.html" ] && [ -f "$BOIL/index.html" ]; then
    if verify_ciphertext "$ENC_CMN/index.html" "$CMN" "$BOIL/index.html"; then PASS "G1: common itinerary words pass once StatiCrypt boilerplate is subtracted"; else FAIL "G1: false positive on common words persists even with boilerplate ref"; fi
    if verify_ciphertext "$ENC_CMN/index.html" "$CMN"; then FAIL "G2: expected pre-fix false positive not reproduced"; else PASS "G2: without boilerplate ref the false positive still fires (subtraction is the fix)"; fi
    rm -rf "$ENC_CMN" "$BOIL"
  else
    SKIP "G: staticrypt could not run (offline or npx blocked)"
  fi
else
  SKIP "G: npx unavailable"
fi

echo "Opaque repo naming (--opaque, #6):"
OTD="$WORK/tokyo-2026"; mkdir -p "$OTD/outputs"
ensure_opaque_slug "$OTD" >/dev/null 2>&1
OSLUG="$(slug_for "$OTD")"
case "$OSLUG" in trip-*) PASS "H1: --opaque generates a trip-<token> slug ($OSLUG)";; *) FAIL "H1: opaque slug lacks trip- prefix ($OSLUG)";; esac
if grep -qiE 'tokyo|2026' <<<"$OSLUG"; then FAIL "H2: opaque slug leaks destination/year ($OSLUG)"; else PASS "H2: opaque slug leaks neither destination nor year"; fi
ensure_opaque_slug "$OTD" >/dev/null 2>&1
[ "$(slug_for "$OTD")" = "$OSLUG" ] && PASS "H3: opaque slug is stable across calls (update/rotate resolve the same repo)" || FAIL "H3: opaque slug changed on re-run"
OTD2="$WORK/kyoto-2026"; mkdir -p "$OTD2"; printf 'chosen-name\n' > "$OTD2/.publish-slug"
ensure_opaque_slug "$OTD2" >/dev/null 2>&1
[ "$(slug_for "$OTD2")" = "chosen-name" ] && PASS "H4: pre-existing .publish-slug wins over --opaque" || FAIL "H4: --opaque overwrote an explicit .publish-slug"

echo "Inventory + date helpers (list, #25):"
EF="$WORK/site.html"; : > "$EF"
[ -n "$(_epoch_of_file "$EF")" ] && PASS "I1: _epoch_of_file returns an mtime epoch" || FAIL "I1: _epoch_of_file empty"
# I1b — I1 asserts only NON-EMPTY, which is satisfied by the wrong answer. On GNU
# coreutils `stat -f` is --file-system, so the BSD-first form emits filesystem noise on
# Linux; that is non-empty, so I1 passed while every arithmetic comparison downstream
# silently stopped working. The epoch must be a BARE INTEGER, and _is_stale must actually
# order two real files — the control arm is the reversed comparison, which must be false.
i1e="$(_epoch_of_file "$EF")"
EF2="$WORK/epoch2"; : > "$EF2"; touch -t 202001010000 "$EF2"; touch -t 203001010000 "$EF"
i1a="$(_epoch_of_file "$EF")"; i1b="$(_epoch_of_file "$EF2")"
case "$i1e" in ''|*[!0-9]*) i1ok=0 ;; *) i1ok=1 ;; esac
if [ "$i1ok" -eq 1 ] && _is_stale "$i1a" "$i1b" && ! _is_stale "$i1b" "$i1a"; then
  PASS "I1b: _epoch_of_file yields a bare integer and _is_stale orders two real files (control arm: the reverse is false)"
else
  FAIL "I1b: epoch is not a comparable integer ('$i1e') or _is_stale cannot order two real files ($i1a vs $i1b) — every freshness check downstream is inert"
fi
IE="$(_epoch_of_iso '2026-06-28T14:36:00Z')"
[ "$(_ymd_of_epoch "$IE")" = "2026-06-28" ] && PASS "I2: _epoch_of_iso + _ymd_of_epoch round-trip an ISO date" || FAIL "I2: ISO round-trip wrong ($IE -> $(_ymd_of_epoch "$IE"))"
[ "$(_ymd_of_epoch '')" = "-" ] && PASS "I3: _ymd_of_epoch renders empty as '-'" || FAIL "I3: empty epoch not '-'"
if _is_stale 200 100 && ! _is_stale 100 200 && ! _is_stale "" 100; then PASS "I4: stale iff local build newer than deployment (empty-safe)"; else FAIL "I4: stale rule wrong"; fi
if grep -qE 'git |commit_noreply|staticrypt|repo create|repo delete|api -X|rm -' <<<"$(declare -f cmd_list)"; then
  FAIL "I5: cmd_list contains a mutating operation (must be read-only)"
else
  PASS "I5: cmd_list is read-only (no git/push/encrypt/create/delete/write verbs)"
fi

echo "Trip-data ignore invariant (#254):"
if git -C "$HERE/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # K1 (positive) — the signpost ships. Trackedness, not ignore-state: a tracked
  # file bypasses .gitignore entirely, so ls-files is the unambiguous test.
  if git -C "$HERE/.." ls-files --error-unmatch trips/README.md >/dev/null 2>&1; then
    PASS "K1: trips/README.md is tracked (the signpost ships in a fresh clone)"
  else
    FAIL "K1: trips/README.md is NOT tracked — the signpost is absent from a fresh clone"
  fi
  # K2 (negative — R2, the limb that matters). check-ignore needs no file on disk,
  # so nothing synthetic is written. -q, NOT -v: verbose exits 0 on a NEGATION match
  # too, which would silently invert this verdict.
  if git -C "$HERE/.." check-ignore -q "trips/zzz-probe-2026/travelers/probe.md"; then
    PASS "K2: a synthetic trips/<trip>/travelers/<x>.md is still git-ignored"
  else
    FAIL "K2: TRIP DATA IS NO LONGER IGNORED — .gitignore stopped guarding trips/ contents"
  fi
  # K3 (control arm) — a zero whose control also returns zero is a broken probe.
  # A tracked, never-ignored path must come back NOT ignored.
  if git -C "$HERE/.." check-ignore -q "README.md"; then
    FAIL "K3: control arm broken — check-ignore calls the tracked root README.md ignored; K2 is unusable"
  else
    PASS "K3: control arm fires (root README.md not ignored) — K2's verdict is trustworthy"
  fi
else
  SKIP "K: not a git work tree"
fi

echo "Unpublish / takedown (#7):"
# J1 — idempotent no-op on an absent repo (real gh; the repo-view short-circuit).
if gh auth status >/dev/null 2>&1; then
  ABSENT="trip-$(od -An -N8 -tx1 /dev/urandom | tr -dc 'a-f0-9')"
  UDIR="$WORK/unpub"; mkdir -p "$UDIR"; printf '%s\n' "$ABSENT" > "$UDIR/.publish-slug"
  if ( cmd_unpublish "$UDIR" --yes ) >/dev/null 2>&1; then PASS "J1: unpublish on an absent repo is a no-op (idempotent)"; else FAIL "J1: unpublish errored on an absent repo"; fi
else
  SKIP "J1: gh not authenticated"
fi
# J2/J3 — decision-branch tests with a MOCK gh (isolates the destructive delete path; no network).
MDIR="$WORK/mock-trip"; mkdir -p "$MDIR"; printf 'mock-slug\n' > "$MDIR/.publish-slug"
GHLOG="$WORK/gh.log"
gh() {  # mock: record the call, respond per fixed scenario (repo EXISTS, delete_repo scope present)
  printf '%s\n' "$*" >> "$GHLOG"
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 0 ;;
    "auth status") printf "Token scopes: 'repo', 'delete_repo'\n" ;;
    *)             return 0 ;;
  esac
}
: > "$GHLOG"
if ( cmd_unpublish "$MDIR" </dev/null ) >/dev/null 2>&1; then rc=0; else rc=1; fi
if [ "$rc" -ne 0 ] && ! grep -q '^repo delete' "$GHLOG"; then PASS "J2: refuses non-interactive delete without --yes (never calls repo delete)"; else FAIL "J2: non-interactive delete not refused (rc=$rc)"; fi
: > "$GHLOG"
( cmd_unpublish "$MDIR" --disable-pages-only </dev/null ) >/dev/null 2>&1
if grep -q 'api -X DELETE' "$GHLOG" && ! grep -q '^repo delete' "$GHLOG"; then PASS "J3: --disable-pages-only disables Pages, never deletes the repo"; else FAIL "J3: disable-pages-only path wrong"; fi
unset -f gh

echo "Plaintext content guard (#123):"
# The content guard is a CONTENT predicate, not a ciphertext one, so group L exercises
# it directly on $WORK fixtures exactly as A/B/C/C2 exercise verify_ciphertext — no gh,
# no npx, no TTY, no network. L therefore cannot reach the SKIP path at all, so its
# verdicts are always real, on any runner.
LTD="$WORK/lisbon-2028"; mkdir -p "$LTD/outputs"
cat > "$LTD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Lisbon 2028 [DERIVED]

## Rowan
- Party: —
- Leaving from: Central Station
- Passport: Ruritanian, valid to 2033
- Interests: markets, museums

### Needs
- Category: dietary-health
  Specific: severe shellfish allergy, no shared fryers at any sit-down meal
  Applies to: ## Dietary & Health → "Shellfish"

## Wren [OPERATOR-PROVIDED]
- Passport: Ruritanian, valid to 2034

### Needs
- Category: rest
  Specific: needs a slow start and no fixed plan before ten in the morning
  Applies to: ## Hard Constraints → "Pacing"

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: cannot manage more than one flight of stairs in a single stretch
  Applies to: ## Hard Constraints → "Mobility"

## Update signals [DERIVED]
- Rowan: added anchor "night market" [new].
MD

# Every L render shares one body and differs only in its last paragraph, so a verdict
# difference between two cases is caused by that paragraph and nothing else. The shared
# body deliberately carries all three NEAR-MISSES a correct guard must NOT flag:
#   (i)   the word "passport" in a legitimate packing-list line
#   (ii)  destination-level entry guidance of the trip-context Destination Baseline kind
#   (iii) a first-party [OPERATOR-PROVIDED]-but-NOT-[THIRD-PARTY] need, verbatim — the
#         designed escalation path agents/06-validator.md keeps open
lrender() { # <out_file> <final paragraph>
  cat > "$1" <<HTML
<!DOCTYPE html><html><head><title>Lisbon Trip</title></head><body>
<h1>Itinerary</h1>
<p>Day 1: arrive at Central Station, drop bags at the guest house, then walk the covered
market for an hour before an early dinner at the noodle counter two streets over.</p>
<p>Day 2: the harbour museum in the morning, a long lunch by the water, and the hill
gardens in the late afternoon when the light is best and the crowds have thinned.</p>
<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>
<p>Visa / entry: no visa required for stays under ninety days; a passport valid for six
months beyond arrival is expected at the border.</p>
<p>Pacing: Wren needs a slow start and no fixed plan before ten in the morning.</p>
<p>$2</p>
</body></html>
HTML
}
LOUT="$WORK/l.err"; LRC=0
lguard() { verify_publishable_content "$1" "${2:-$LTD}" >/dev/null 2>"$LOUT"; LRC=$?; }

# L1 — a Passport value reaching the render aborts.
LHIT="$WORK/l_passport.html"
lrender "$LHIT" "Border note: carry your Ruritanian passport, valid to 2033, at all times."
lguard "$LHIT"
if [ "$LRC" -eq 1 ]; then PASS "L1: a Passport value reaching the render aborts the publish (rc=1)"; else FAIL "L1: a Passport value did NOT abort the publish (rc=$LRC)"; fi
# L1b — and the abort must NOT echo what it matched. This suite runs in a public CI log,
# and the strings it matches are passport values and third-party health needs; echoing
# them would make the guard leak precisely what it exists to protect. Deliberate
# divergence from verify_ciphertext, which does print its matched token.
if grep -qF 'entry 1 / Passport' "$LOUT" && ! grep -qF 'Ruritanian' "$LOUT" && ! grep -qF '2033' "$LOUT"; then
  PASS "L1b: the abort names member + field and never echoes the matched value"
else
  FAIL "L1b: the abort message echoed the matched value into the log"
fi

# L2 — a [THIRD-PARTY] value reaching the render, attributed, aborts.
LTP="$WORK/l_thirdparty.html"
lrender "$LTP" "Quill cannot manage more than one flight of stairs in a single stretch."
lguard "$LTP"
if [ "$LRC" -eq 1 ]; then PASS "L2: a [THIRD-PARTY] value reaching the render, attributed, aborts (rc=1)"; else FAIL "L2: an attributed [THIRD-PARTY] value did NOT abort (rc=$LRC)"; fi

# L3 — THE CASE THAT DISTINGUISHES THIS DESIGN FROM A NAME-KEYED ONE. The same value
# with the name stripped is still a finding: the name was never the join key, so
# de-attribution changes nothing about the match.
LANON="$WORK/l_anon.html"
lrender "$LANON" "One member of the party cannot manage more than one flight of stairs in a single stretch."
lguard "$LANON"
if [ "$LRC" -eq 1 ]; then PASS "L3: the same value with the NAME STRIPPED still aborts (rc=1) — de-attribution is caught"; else FAIL "L3: an anonymized [THIRD-PARTY] value passed (rc=$LRC) — the guard is name-keyed"; fi
# L3b — control: if the anonymized fixture still carried the name, L3 would be passing
# on the name arm and would prove nothing about de-attribution.
if grep -qF 'Quill' "$LANON"; then FAIL "L3b: the anonymized fixture still names the person — L3 is not testing de-attribution"; else PASS "L3b: the anonymized fixture carries no name — L3's verdict is about the value, not the name"; fi

# L4b — FIXTURE-INTEGRITY CONTROL ARM, graded BEFORE the clean case it protects. A clean
# render with no near-miss vocabulary passes under a correct guard AND under one that
# matches almost nothing, so without this arm L4a is vacuous rather than passing. Same
# rule as K3: a probe whose input is empty is broken, not clean.
LCLEAN="$WORK/l_clean.html"
lrender "$LCLEAN" "Evening: the riverside lantern walk, then back to the guest house."
lnm=0
grep -qF 'Packing list: passport'                                         "$LCLEAN" && lnm=$((lnm+1))
grep -qF 'Visa / entry: no visa required'                                 "$LCLEAN" && lnm=$((lnm+1))
grep -qF 'needs a slow start and no fixed plan before ten in the morning' "$LCLEAN" && lnm=$((lnm+1))
if [ "$lnm" -eq 3 ] && ! grep -qF 'Ruritanian' "$LCLEAN" && ! grep -qF 'Quill' "$LCLEAN"; then
  PASS "L4b: the clean fixture carries all 3 near-misses and no class value — L4a is a real specificity arm"
else
  FAIL "L4b: the clean fixture is not near-miss-rich ($lnm/3) or carries a class value — L4a would prove nothing"
fi
# L4a — the clean render publishes.
lguard "$LCLEAN"
if [ "$LRC" -eq 0 ]; then PASS "L4a: a near-miss-rich clean render publishes (rc=0) — the guard does not over-match"; else FAIL "L4a: a clean render was blocked (rc=$LRC) — the guard over-matches correct content"; fi

# L5a–L5e — fail-closed. An undetermined result is a failure, never a clean pass.
LMISS="$WORK/l_absent"; mkdir -p "$LMISS/outputs"
lguard "$LCLEAN" "$LMISS"
if [ "$LRC" -eq 2 ]; then PASS "L5a: an ABSENT traveler model aborts (rc=2)"; else FAIL "L5a: an absent traveler model did not abort (rc=$LRC)"; fi

LUNR="$WORK/l_unreadable"; mkdir -p "$LUNR/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Passport: Ruritanian, valid to 2033\n' > "$LUNR/outputs/traveler-model.md"
chmod 000 "$LUNR/outputs/traveler-model.md"
# A privileged runner (root in some containers) reads a 000 file anyway, which would
# turn this into a silent pass. Fall back to a construct no privilege can read AS A
# REGULAR FILE, so the case always renders a verdict and never becomes a skip.
if [ -r "$LUNR/outputs/traveler-model.md" ]; then
  rm -f "$LUNR/outputs/traveler-model.md"; mkdir -p "$LUNR/outputs/traveler-model.md"
fi
lguard "$LCLEAN" "$LUNR"
if [ "$LRC" -eq 2 ]; then PASS "L5b: an UNREADABLE traveler model aborts (rc=2)"; else FAIL "L5b: an unreadable traveler model did not abort (rc=$LRC)"; fi
chmod 644 "$LUNR/outputs/traveler-model.md" 2>/dev/null || true

LEMP="$WORK/l_empty"; mkdir -p "$LEMP/outputs"; : > "$LEMP/outputs/traveler-model.md"
lguard "$LCLEAN" "$LEMP"
if [ "$LRC" -eq 2 ]; then PASS "L5c: an EMPTY traveler model aborts (rc=2) — an empty read is not an empty class"; else FAIL "L5c: an empty traveler model did not abort (rc=$LRC)"; fi

LDRIFT="$WORK/l_drifted"; mkdir -p "$LDRIFT/outputs"
printf '# Traveler Model [DERIVED]\n\n## Update signals [DERIVED]\n- nothing this pass.\n' > "$LDRIFT/outputs/traveler-model.md"
lguard "$LCLEAN" "$LDRIFT"
if [ "$LRC" -eq 2 ]; then PASS "L5d: a model with ZERO '## <Name>' entries aborts (rc=2) — a format drift is a loud refusal"; else FAIL "L5d: a drifted model was read as a clean empty class (rc=$LRC) — silent under-matching"; fi

LSUB="$WORK/l_subfloor"; mkdir -p "$LSUB/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Passport: Ruritanian\n' > "$LSUB/outputs/traveler-model.md"
lguard "$LCLEAN" "$LSUB"
if [ "$LRC" -eq 2 ]; then PASS "L5e: a class value BELOW its keyability floor aborts (rc=2) — the guard refuses rather than guesses"; else FAIL "L5e: a sub-floor class value was waved through (rc=$LRC)"; fi

# L6 — absence is not zero. A model that PARSES with no class member is a determinate
# measurement and must publish; only an unrecognized file is a degradation. Collapsing
# the two would make a broken parser indistinguishable from a trip with nothing to hide.
LNONE="$WORK/l_noclass"; mkdir -p "$LNONE/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n### Needs\n- Category: rest\n  Specific: an early night on the first day of the trip\n' > "$LNONE/outputs/traveler-model.md"
nonpublishable_values "$LNONE" > "$WORK/l_noclass.out" 2>/dev/null; lnrc=$?
if [ "$lnrc" -eq 0 ] && [ ! -s "$WORK/l_noclass.out" ]; then
  PASS "L6a: a model that parses with no class member enumerates EMPTY and returns 0 (absence is not zero)"
else
  FAIL "L6a: parsed-and-empty was not distinguished from unparseable (rc=$lnrc)"
fi
lguard "$LCLEAN" "$LNONE"
if [ "$LRC" -eq 0 ]; then PASS "L6b: with a genuinely empty class the plaintext publish proceeds (rc=0)"; else FAIL "L6b: an empty class blocked the publish (rc=$LRC)"; fi

# L7 — AC 1 structurally: the guard runs BEFORE anything is copied to the publish dir.
lbody="$(declare -f cmd_publish)"
lgline="$(printf '%s\n' "$lbody" | grep -n 'verify_publishable_content' | head -1 | cut -d: -f1)"
lcline="$(printf '%s\n' "$lbody" | grep -nF 'cp "$site_html"'           | head -1 | cut -d: -f1)"
if [ -n "$lgline" ] && [ -n "$lcline" ] && [ "$lgline" -lt "$lcline" ]; then
  PASS "L7: the content guard runs before the copy into the publish dir (guard line $lgline < copy line $lcline)"
else
  FAIL "L7: guard/copy ordering not proven in cmd_publish (guard='$lgline' copy='$lcline')"
fi

# L8 — AC 2 structurally: the class has ONE home, and after the re-key that home is the
# DECLARATION, not this script. Three arms, because two of them are ZEROS: a zero whose
# control arm also returns zero is a broken probe, not a clean result. Same shape as
# scripts/test-trip-resolution-contract.sh case PIN5, which asserts the sibling contract
# with the same polarity — this file holds no copy of the canonical list, and the same
# probe that finds nothing here finds everything there.
#
# The selector list comes from the guard's own reader, so this case holds no copy of the
# declaration's path, its section heading, its fence name or any row of it. A suite that
# enumerated the selectors to check that nothing enumerates the selectors would be the
# second home it exists to detect.
#
# NOTE the polarity flip against the pre-re-key form of this case, which required
# `lsrc > 0` — the class source holding literals was the property it asserted. That form
# is structurally incapable of passing now, which is why it was rewritten in the same
# commit as the re-key rather than after it.
l8sel="$(_guard_declared_selectors)"
l8n="$(printf '%s\n' "$l8sel" | grep -c .)"
l8pred=0; l8src=0
while IFS= read -r l8s; do
  [ -n "$l8s" ] || continue
  l8pred=$(( l8pred + $(declare -f verify_publishable_content | grep -cF -- "$l8s") ))
  l8src=$((  l8src  + $(declare -f nonpublishable_values      | grep -cF -- "$l8s") ))
done <<EOF
$l8sel
EOF
if [ "$l8n" -gt 0 ] && [ "$l8pred" -eq 0 ] && [ "$l8src" -eq 0 ]; then
  PASS "L8: the class has ONE home — the declaration carries all $l8n selectors while neither the predicate (0) nor the class source (0) holds a copy; the control arm fires"
else
  FAIL "L8: the one-home seam is gone or the probe is broken (declaration=$l8n predicate=$l8pred source=$l8src)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L9 / L10 — the declaration IS the class source, proved by changing it.
#
# Every other case in group L would pass identically against the old shell-literal
# membership rule. Only a verdict that FOLLOWS the declaration distinguishes a re-key
# that happened from one that was described, so these are the cases that grade it.
#
# The declaration path is re-pointed by assigning the sourced variable in THIS process.
# publish-trip-site.sh deliberately does not environment-default it — an env-overridable
# class definition on a fail-closed control would let any caller narrow the class from
# outside the repository — so a subprocess cannot do what this sourced suite can. That
# asymmetry is the design, not a gap.
#
# The fixture declaration is BUILT FROM the guard's own constants and its own reader, so
# this file holds no copy of the heading, the fence name or any row.
L8DECL_REAL="$_GUARD_DECLARATION"
ldecl_write() { # <file>   (rows on stdin)
  { printf '%s\n\n' "$_GUARD_DECL_HEADING"
    printf '```%s\n' "$_GUARD_DECL_FENCE"
    cat
    printf '```\n'
  } > "$1"
}

# One fixture, one render, two declarations. The render is written BEFORE the model so
# the empty-class freshness gate reads the projection as at least as new as the render.
LDECLT="$WORK/l_decl"; mkdir -p "$LDECLT/outputs"
LDECLR="$WORK/l_decl.html"
lrender "$LDECLR" "Deposit note: the group papers are held at Meridian Vault 88 until departure."
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Custodian: Meridian Vault 88\n' > "$LDECLT/outputs/traveler-model.md"

# L9b — graded FIRST, because it is the arm that says the fixture is otherwise clean.
# Under the shipped declaration `Custodian` is not a declared selector, so its value is
# not in class and the identical render publishes.
lguard "$LDECLR" "$LDECLT"
l9b="$LRC"
if [ "$l9b" -eq 0 ]; then
  PASS "L9b: a value under an UNDECLARED field label publishes (rc=0) — the guard does not key on labels the declaration never named"
else
  FAIL "L9b: an undeclared field label blocked the publish (rc=$l9b) — the class is wider than the declaration"
fi

# L9a — the same trip and the same render, with one row added to the declaration. A
# verdict change here is caused by the declaration and by nothing else.
LDECLF="$WORK/l_decl_extra.md"
{ _guard_declared_rows
  printf 'field Custodian %s conjunctive\n' "$_GUARD_DECL_ARTIFACT_MODEL"
} | ldecl_write "$LDECLF"
_GUARD_DECLARATION="$LDECLF"
lguard "$LDECLR" "$LDECLT"
l9a="$LRC"
_GUARD_DECLARATION="$L8DECL_REAL"
if [ "$l9a" -eq 1 ] && [ "$l9b" -eq 0 ]; then
  PASS "L9a: adding ONE declaration row turns the same render from publish (rc=0) into abort (rc=1) — membership is sourced from the declaration, not from this script"
else
  FAIL "L9a: the verdict did not follow the declaration (with row=$l9a, without row=$l9b) — the re-key is described but not delivered"
fi

# L10 — the SIXTH fail-closed path. An unreadable declaration is not an empty class.
# Its control arm is L9b immediately above: the identical trip and render return 0 while
# the declaration resolves, so a 2 here is attributable to the declaration and not to the
# fixture.
_GUARD_DECLARATION="$WORK/l_decl_absent.md"
lguard "$LDECLR" "$LDECLT"
l10a="$LRC"
_GUARD_DECLARATION="$L8DECL_REAL"
if [ "$l10a" -eq 2 ] && [ "$l9b" -eq 0 ]; then
  PASS "L10: an ABSENT publishability declaration aborts (rc=2) while the same trip publishes (rc=0) once it resolves — a class that cannot be read is UNDETERMINED, never empty"
else
  FAIL "L10: an unreadable declaration was not fail-closed (absent=$l10a, present=$l9b)"
fi

# L10b — the SIXTH fail-closed path again, for a PARTIAL read. L10 proves an absent
# declaration is UNDETERMINED; this proves a declaration that parses in PART is too. The
# reader keeps four-field rows and drops the rest, so before this case a single malformed
# row silently narrowed the guarded class while the aggregate row count stayed non-zero.
#
# L8 could not see it: L8 counts DISTINCT selectors, and the shipped declaration carries
# `Passport` on two rows, so dropping one leaves the selector present and L8 green. The
# validator layer reads the SAME declaration, so both layers narrow together — this is
# common-mode, not defence in depth. Its control arm is L9b: the identical trip and render
# return 0 while every row parses, so a 2 here is attributable to the malformed row alone.
LDECLM="$WORK/l_decl_malformed.md"
_guard_declared_rows | awk 'NR == 1 { print $0 " extra"; next } { print }' | ldecl_write "$LDECLM"
_GUARD_DECLARATION="$LDECLM"
lguard "$LDECLR" "$LDECLT"
l10b="$LRC"
_GUARD_DECLARATION="$L8DECL_REAL"
if [ "$l10b" -eq 2 ] && [ "$l9b" -eq 0 ]; then
  PASS "L10b: a declaration with ONE malformed row aborts (rc=2) while the same trip publishes (rc=0) once every row parses — a PARTIAL read is UNDETERMINED, never a narrower class"
else
  FAIL "L10b: a partially-parsed declaration was not fail-closed (malformed=$l10b, well-formed=$l9b) — a dropped row silently narrows the guarded class"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L11 — THE RESERVED-HEADING SUPPRESSION, both halves.
#
# The model parse reserves one heading key for a structural section that is not a person,
# and clears the entry state on it. L5d already asserts the BRANCH — a model made only of
# that section parses zero entries and aborts. What was untested is what the branch
# SUPPRESSES when other entries exist, and the two limbs of the class are suppressed
# differently. These cases pin the current behaviour so it cannot drift silently and so
# the slice that changes it has a failing target to flip.
#
# READ THESE AS MEASUREMENTS, NOT AS ENDORSEMENTS. L11a records a value in class that is
# not caught at all; a PASS here means "the gap is exactly this shape", not "this is
# correct". The behaviour change belongs to the traveler-identity slice, which owns the
# reserved-key semantics; this slice owns these two files and so owns the coverage.

# L11a — the FIELD limb under the reserved heading has NO backstop of any kind. Both arms
# are graded together: the same line under an ordinary entry must abort, or the clean
# verdict below is a fixture that simply does not match rather than a suppression.
LSUPF="$WORK/l_sup_field"; mkdir -p "$LSUPF/outputs"
LSUPR="$WORK/l_sup.html"
lrender "$LSUPR" "Border note: carry your Ruritanian passport, valid to 2033, at all times."
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n## Update signals [DERIVED]\n- Passport: Ruritanian, valid to 2033\n' > "$LSUPF/outputs/traveler-model.md"
lguard "$LSUPR" "$LSUPF"
l11sup="$LRC"
LSUPC="$WORK/l_sup_ctl"; mkdir -p "$LSUPC/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Passport: Ruritanian, valid to 2033\n' > "$LSUPC/outputs/traveler-model.md"
lguard "$LSUPR" "$LSUPC"
l11ctl="$LRC"
if [ "$l11sup" -eq 0 ] && [ "$l11ctl" -eq 1 ]; then
  PASS "L11a: a declared FIELD value under the reserved heading reaches the render UNCAUGHT (rc=0) while the identical line under an ordinary entry aborts (rc=1) — the suppression has no backstop, measured not assumed"
else
  FAIL "L11a: the reserved-heading field suppression changed shape (suppressed=$l11sup control=$l11ctl) — re-read the heading branch before trusting either verdict"
fi

# L11b — the ENTRY limb IS backstopped by the orphaned-mark check, but only while no
# other entry produced a record. Two fixtures differing in exactly that.
LSUPE="$WORK/l_sup_entry"; mkdir -p "$LSUPE/outputs"
LSUPER="$WORK/l_sup_entry.html"
lrender "$LSUPER" "One member of the party cannot manage more than one flight of stairs in a single stretch."
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n## Update signals [DERIVED]\n- Relayed [THIRD-PARTY]: cannot manage more than one flight of stairs in a single stretch\n' > "$LSUPE/outputs/traveler-model.md"
lguard "$LSUPER" "$LSUPE"
l11e1="$LRC"
LSUPE2="$WORK/l_sup_entry2"; mkdir -p "$LSUPE2/outputs"
printf '# Traveler Model [DERIVED]\n\n## Marlow [OPERATOR-PROVIDED] [THIRD-PARTY]\n\n### Needs\n- Category: rest\n  Specific: an early night on the first evening after the long flight\n\n## Update signals [DERIVED]\n- Relayed [THIRD-PARTY]: cannot manage more than one flight of stairs in a single stretch\n' > "$LSUPE2/outputs/traveler-model.md"
lguard "$LSUPER" "$LSUPE2"
l11e2="$LRC"
if [ "$l11e1" -eq 2 ] && [ "$l11e2" -eq 0 ]; then
  PASS "L11b: a suppressed ENTRY mark aborts as UNDETERMINED (rc=2) when it is the only one, and is swallowed (rc=0) once another entry produced a record — the backstop is conditional, and this pins the condition"
else
  FAIL "L11b: the orphaned-mark backstop changed shape (alone=$l11e1 with-other-record=$l11e2) — re-read the END block before trusting either verdict"
fi

# L11c — THE RESERVED-KEY LIST HAS TWO MEMBERS, AND THE BRANCH READS BOTH.
#
# reference/data-model.md § *Reserved keys* declares two: `updatesignals` and
# `desireoverlap`. The branch held only the first, so `## Desire overlap` — a structural
# section of the derived model, defined in that document's own worked example — was counted
# as a person.
#
# That is not cosmetic, and the reason is the END block rather than the entry limb.
# `entries` is the operand of `entries == 0`, the fail-closed format-drift sentinel L5d
# asserts. A structural section counted as a person is a PHANTOM ENTRY, and a phantom entry
# is exactly what keeps that sentinel from firing: a model that has drifted to carry no
# recognisable person still parses as a clean EMPTY class, and an empty class publishes.
# This is L5d's fixture with the second reserved heading substituted for the first, and it
# must abort for the same reason L5d's does.
LDRIFT2="$WORK/l_drifted_overlap"; mkdir -p "$LDRIFT2/outputs"
printf '# Traveler Model [DERIVED]\n\n## Desire overlap\n- museums / slow-pace morning: Wren (anchor), Rowan (wish)\n' > "$LDRIFT2/outputs/traveler-model.md"
lguard "$LCLEAN" "$LDRIFT2"
if [ "$LRC" -eq 2 ]; then
  PASS "L11c: a model whose only section is the SECOND declared reserved heading aborts (rc=2) — both members of the declared list clear the entry state, so a structural section cannot stand in as a person and mask the zero-entry sentinel"
else
  FAIL "L11c: '## Desire overlap' was counted as a person (rc=$LRC) — the guard's reserved-key branch is narrower than the declared list, and a phantom entry can mask the fail-closed zero-entry sentinel"
fi

# L11d — AND THE COST OF THAT, MEASURED RATHER THAN LEFT TO BE DISCOVERED.
#
# READ THIS AS A MEASUREMENT, NOT AS AN ENDORSEMENT — the same reading L11a asks for, for
# the same reason: reserving a key SUPPRESSES the field and entry limbs beneath it, so
# widening the list widens L11a's backstop-free gap to a second heading. Both arms are
# graded together, so a clean verdict cannot be a fixture that simply does not match.
#
# The trade is stated where it is made. What is bought is the fail-closed sentinel above,
# which protects the whole class. What is paid is a declared field value under one further
# structural heading. The heading is machine-derived by the enrichment agent from the
# individual files, and a `[THIRD-PARTY]` subject contributes no desires by construction
# (CLAUDE.md § Key Rules — "needs only"), so nothing that belongs to the guarded class is
# authored there in the first place.
LSUPF2="$WORK/l_sup_field_overlap"; mkdir -p "$LSUPF2/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n## Desire overlap\n- Passport: Ruritanian, valid to 2033\n' > "$LSUPF2/outputs/traveler-model.md"
lguard "$LSUPR" "$LSUPF2"
l11dsup="$LRC"
if [ "$l11dsup" -eq 0 ] && [ "$l11ctl" -eq 1 ]; then
  PASS "L11d: the suppression under the second reserved heading has the same shape as under the first — a declared FIELD value reaches the render uncaught (rc=0) while the identical line under an ordinary entry aborts (rc=1). The gap is L11a's, now spanning both declared keys, and it is pinned rather than assumed"
else
  FAIL "L11d: the second reserved heading's field suppression is not L11a's shape (suppressed=$l11dsup control=$l11ctl) — re-read the heading branch before trusting either verdict"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Group M — the three confirmed defects from the Phase A6.5 adversarial design
# review of the shipped guard (#316). One regression case per counter-design:
#   M1  CD-1  the guard matched the visible-text PROJECTION while publish copies
#             the whole FILE, so a value in a comment or an attribute published.
#   M2  CD-2  the token branch never called is_stop, so a third-party member named
#             with an ordinary English word aborted every publish, permanently.
#   M3  CD-3  the class bound to a [DERIVED] cache with no freshness check, so a
#             passport that existed only in travelers/*.md read as "genuinely EMPTY".
# Every case carries a fixture-integrity control arm (the K2/K3 idiom): a case whose
# control arm also returns zero is a BROKEN PROBE, not a pass. Like L, group M runs
# purely on $WORK fixtures — no gh, no npx, no TTY, no network — so it cannot reach
# the SKIP path and its verdicts are real on every runner.
# ─────────────────────────────────────────────────────────────────────────────
echo "Published-bytes, stoplist and freshness remediation (#123 / A6.5):"

MOUT="$WORK/m.err"; MRC=0
mguard() { verify_publishable_content "$1" "$2" >/dev/null 2>"$MOUT"; MRC=$?; }

# The shared M render carries a REALISTIC machinery load — inline CSS, an inline
# script, a CDN stylesheet link, data-* attributes, ids and class names, a build
# comment. Without it the M1 specificity arm would prove nothing: a published-bytes
# arm that over-matches markup only shows itself against markup that is actually there.
mrender() { # <out_file> <injected markup>
  cat > "$1" <<HTML
<!DOCTYPE html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Porto Trip</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Karla&display=swap">
<style>:root{--accent:#1b4d3e}.day-card{display:grid;gap:12px}.act-mini{font-size:14px}</style>
</head><body>
<!-- build: day grid, booking checklist, map column -->
<h1>Itinerary</h1>
<div class="day-card" id="day-1" data-energy="high" data-booking="advance">
<p>Day 1: arrive at the river station, drop bags at the guest house, then walk the
covered market for an hour before an early dinner at the counter two streets over.</p></div>
<div class="day-card" id="day-2" data-energy="low" data-booking="walkup">
<p>Day 2: the harbour museum in the morning, a long lunch by the water, and the hill
gardens in the late afternoon when the light is best and the crowds have thinned.</p></div>
<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>
<script>var map = L.map('map').setView([41.15, -8.61], 13);</script>
$2
</body></html>
HTML
}

# ── M1 (CD-1) — the evaluand is the published file, not the painted page ─────
MTD="$WORK/porto-2029"; mkdir -p "$MTD/outputs"
cat > "$MTD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033
- Interests: markets, museums

## Quillon [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: cannot manage more than one flight of stairs in a single stretch
  Applies to: ## Hard Constraints → "Mobility"
MD
MV='cannot manage more than one flight of stairs in a single stretch'

# Eight surfaces, each carrying the class value ONLY in that surface. Two of the eight
# (doc-title, img-alt) are user-visible in a browser; the rest are retrievable from the
# bytes by anyone who opens the page source, which every reader can do.
mtotal=0; mabort=0; mbroken=0; mmissed=""
while IFS='|' read -r msurface mmarkup; do
  [ -n "$msurface" ] || continue
  mtotal=$((mtotal+1))
  mf="$WORK/m_$msurface.html"
  mrender "$mf" "$mmarkup"
  # Fixture-integrity control arm, per surface: the fixture must really carry the value
  # AND the value must really be absent from the visible-text projection, or the case is
  # not testing the published-bytes arm at all.
  if ! grep -qF "$MV" "$mf"; then mbroken=$((mbroken+1)); mmissed="$mmissed$msurface(no-value) "; continue; fi
  mguard "$mf" "$MTD"
  if [ "$MRC" -ne 0 ]; then mabort=$((mabort+1)); else mmissed="$mmissed$msurface "; fi
done <<MSURF
comment|<!-- planner note: $MV -->
meta-description|<meta name="description" content="$MV">
img-alt|<img src="street.png" alt="$MV">
doc-title|<title>$MV</title>
inline-script|<script>var note = "$MV";</script>
aria-label|<button aria-label="$MV">details</button>
style-content|<style>/* $MV */ .b{color:#333}</style>
data-attribute|<div data-planner-note="$MV">details</div>
MSURF
if [ "$mbroken" -eq 0 ] && [ "$mtotal" -eq 8 ]; then
  PASS "M1a: all $mtotal published-bytes fixtures carry the class value — the control arm fires, so M1b is a real probe"
else
  FAIL "M1a: $mbroken of $mtotal fixtures do not carry the value — M1b would be vacuous, not passing"
fi
if [ "$mabort" -eq "$mtotal" ]; then
  PASS "M1b: a class value carried ONLY in markup aborts on all $mtotal surfaces — the guard matches the published bytes"
else
  FAIL "M1b: only $mabort/$mtotal published-bytes surfaces aborted — still fail-open on: $mmissed"
fi

# M1c/M1d — specificity. The identical machinery-rich render with NO class value in it
# must still publish, or the published-bytes arm has simply learned to abort everything.
MCLEAN="$WORK/m_clean.html"
mrender "$MCLEAN" '<div class="closing" data-note="wrap up">Evening: the riverside lantern walk, then back to the guest house.</div>'
if ! grep -qF "$MV" "$MCLEAN" && ! grep -qF 'Ruritanian' "$MCLEAN" && ! grep -qF 'Quillon' "$MCLEAN" \
   && grep -qF 'data-energy' "$MCLEAN" && grep -qF '<style>' "$MCLEAN" && grep -qF '<!-- build:' "$MCLEAN"; then
  PASS "M1c: the control render carries no class value but does carry CSS, script, comments and data-* — a real specificity arm"
else
  FAIL "M1c: the control render is not machinery-rich or still carries a class value — M1d would prove nothing"
fi
mguard "$MCLEAN" "$MTD"
if [ "$MRC" -eq 0 ]; then PASS "M1d: the same machinery-rich render without the value publishes (rc=0) — the new arm does not blanket-abort markup"; else FAIL "M1d: a clean render was blocked (rc=$MRC) — the published-bytes arm over-matches ordinary markup"; fi

# ── M2 (CD-2) — is_stop in the token branch; a stopword-only name is a declared non-key ──
MSTOP="$WORK/porto-stopword"; mkdir -p "$MSTOP/outputs"
cat > "$MSTOP/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033

## Will [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: rest
  Specific: needs a long quiet break in the middle of every single afternoon
  Applies to: ## Hard Constraints → "Pacing"
MD
MSTOPR="$WORK/m_stopword.html"
mrender "$MSTOPR" '<p>The guest house will hold luggage after checkout, and the museum will be quiet.</p>'
# Control arm: the case is only meaningful if the model really names a third-party member
# with a stoplisted word AND the render really uses that word. Either missing and M2b
# passes for the wrong reason.
if grep -qF '## Will [OPERATOR-PROVIDED] [THIRD-PARTY]' "$MSTOP/outputs/traveler-model.md" \
   && grep -qiw 'will' "$MSTOPR" \
   && grep -qF ' will ' <<<"$_GUARD_STOP" \
   && ! grep -qF 'Ruritanian' "$MSTOPR" && ! grep -qF 'quiet break in the middle' "$MSTOPR"; then
  PASS "M2a: the model names a [THIRD-PARTY] member with a stoplisted word, the render uses it, and no other class value is present"
else
  FAIL "M2a: the stopword-name fixture is not set up as claimed — M2b would prove nothing"
fi
mguard "$MSTOPR" "$MSTOP"
if [ "$MRC" -eq 0 ]; then PASS "M2b: a [THIRD-PARTY] member named with a stopword-only name PUBLISHES (rc=0) — a declared non-key, not an unremediable abort"; else FAIL "M2b: an ordinary English word as a name still aborts (rc=$MRC) — the token branch keys on grammar"; fi

# M2c/M2d — sensitivity: the fix must not disarm the name arm. A DISTINCTIVE third-party
# name reaching the render is still a hit. Without this arm M2b is satisfied by a guard
# that stopped matching names altogether.
MNAMED="$WORK/m_named.html"
mrender "$MNAMED" '<p>Quillon will take the lift rather than the south stair on the museum day.</p>'
if grep -qF 'Quillon' "$MNAMED" && ! grep -qF "$MV" "$MNAMED" && ! grep -qF 'Ruritanian' "$MNAMED"; then
  PASS "M2c: the named fixture carries the distinctive [THIRD-PARTY] name and no other class value"
else
  FAIL "M2c: the named fixture is not set up as claimed — M2d would prove nothing"
fi
mguard "$MNAMED" "$MTD"
if [ "$MRC" -eq 1 ]; then PASS "M2d: a DISTINCTIVE [THIRD-PARTY] name still aborts (rc=1) — the stoplist narrowed the arm, it did not disarm it"; else FAIL "M2d: a distinctive third-party name no longer aborts (rc=$MRC) — CD-2 over-corrected into a fail-open"; fi

# ── M3 (CD-3) — bind to first-party sources and assert freshness ─────────────
# mtimes are set explicitly with touch -t rather than left to write order: a freshness
# gate tested against incidental mtimes is a coin toss, not a regression case.
MSTALE="$WORK/porto-stale"; mkdir -p "$MSTALE/outputs" "$MSTALE/travelers"
cat > "$MSTALE/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Interests: markets, museums
MD
cat > "$MSTALE/travelers/rowan.md" <<'MD'
# Rowan — traveler profile

## Getting there & back
- **Leaving from:** Central Station
- **Passport:** Ruritanian, valid to 2033
MD
MSTALER="$WORK/m_stale.html"
mrender "$MSTALER" '<p>Evening: the riverside lantern walk, then back to the guest house.</p>'
# Render OLDEST, then the model, then the profile NEWEST. Only the profile-vs-model
# comparison can fire, so an rc=2 here is attributable to that comparison alone.
touch -t 202601010900 "$MSTALER"
touch -t 202601011000 "$MSTALE/outputs/traveler-model.md"
touch -t 202601011100 "$MSTALE/travelers/rowan.md"
if grep -qF 'Passport:' "$MSTALE/travelers/rowan.md" \
   && ! grep -qF 'Passport' "$MSTALE/outputs/traveler-model.md" \
   && grep -qF '## Rowan' "$MSTALE/outputs/traveler-model.md" \
   && ! grep -qF 'Ruritanian' "$MSTALER"; then
  PASS "M3a: the profile carries a Passport the model does not, the model still parses, and the render carries neither — the fixture isolates freshness"
else
  FAIL "M3a: the stale-model fixture is not set up as claimed — M3b would prove nothing"
fi
mguard "$MSTALER" "$MSTALE"
if [ "$MRC" -eq 2 ]; then PASS "M3b: a traveler profile newer than the [DERIVED] model aborts as UNDETERMINED (rc=2) — a stale cache is not an empty class"; else FAIL "M3b: a stale derived model was read as a determinate result (rc=$MRC) — silent fail-open on an irreversible action"; fi

# M3c/M3d — the other half of CD-3: travelers/*.md is a CLASS SOURCE, not only a
# freshness witness. With the model fresh, a passport that exists only in the profile
# must still be matched against the render.
MFRESH="$WORK/porto-fresh"; mkdir -p "$MFRESH/outputs" "$MFRESH/travelers"
cat > "$MFRESH/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Interests: markets, museums
MD
cat > "$MFRESH/travelers/rowan.md" <<'MD'
# Rowan — traveler profile

## Getting there & back
- **Passport:** Ruritanian, valid to 2033
MD
MFRESHR="$WORK/m_fresh_hit.html"
mrender "$MFRESHR" '<p>Border note: carry your Ruritanian passport, valid to 2033, at all times.</p>'
touch -t 202601011000 "$MFRESH/travelers/rowan.md"
touch -t 202601011100 "$MFRESHR"
touch -t 202601011200 "$MFRESH/outputs/traveler-model.md"
if ! grep -qF 'Ruritanian' "$MFRESH/outputs/traveler-model.md" && grep -qF 'Ruritanian' "$MFRESH/travelers/rowan.md"; then
  PASS "M3c: the passport exists ONLY in travelers/*.md, never in the model — a hit here can only come from the first-party source"
else
  FAIL "M3c: the first-party-source fixture is not set up as claimed — M3d would prove nothing"
fi
mguard "$MFRESHR" "$MFRESH"
if [ "$MRC" -eq 1 ]; then PASS "M3d: a passport held only in travelers/*.md is matched against the render (rc=1) — the class reads first-party sources"; else FAIL "M3d: a first-party passport absent from the derived model did not abort (rc=$MRC)"; fi

# M3e — specificity for the whole of CD-3. A fresh model, a first-party passport, and a
# render that carries neither must still publish. Without this arm M3b and M3d are both
# satisfied by a guard that aborts unconditionally.
MFRESHC="$WORK/m_fresh_clean.html"
mrender "$MFRESHC" '<p>Evening: the riverside lantern walk, then back to the guest house.</p>'
touch -t 202601011100 "$MFRESHC"
mguard "$MFRESHC" "$MFRESH"
if [ "$MRC" -eq 0 ]; then PASS "M3e: a fresh model with a first-party passport absent from the render publishes (rc=0) — freshness gating is not a blanket abort"; else FAIL "M3e: a clean, fresh trip was blocked (rc=$MRC) — the freshness gate is unusable, which is fail-open in practice"; fi

# ── Group N (PR-7 / OB-1) — the conjunctive window is scoped to one block ────
# W=25 was calibrated on a fixture carrying ONE occurrence of each token. A real
# itinerary repeats both, so an N-day trip offers N-squared candidate pairings and a
# day-boundary pairing lands inside 25 words. Measured on the shipped guard, a clean
# render aborted from TWO days onward and never recovered — a permanent false abort in
# ordinary use. Group N pins both directions: the recurrence must not abort, and a real
# same-sentence carry-through must still abort.
echo "Conjunctive window, scoped to a structural block (#123 / PR-7):"
NTD="$WORK/galway-2027"; mkdir -p "$NTD/outputs"
cat > "$NTD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Galway 2027 [DERIVED]

## Rowan
- Passport: Irish, valid to 2027
MD
# A six-day render whose day headings carry the validity year and whose day bodies each
# mention the nationality adjective — both class tokens, many times, never together in
# one block. This is correct content: the year is a date, the adjective describes a pub.
nrender() { # <out_file> <days> [final paragraph]
  {
    printf '<!DOCTYPE html><html><head><title>Galway Trip</title></head><body>\n<h1>Itinerary</h1>\n'
    nd=1
    while [ "$nd" -le "$2" ]; do
      printf '<h2>Day %d — Friday 12 June 2027</h2>\n' "$nd"
      printf '<p>Morning at the covered market, then a long lunch by the water and an\n'
      printf 'afternoon walk through the old town before an evening at a traditional Irish\n'
      printf 'pub with music from about nine, back to the guest house before midnight.</p>\n'
      nd=$((nd+1))
    done
    [ -n "${3:-}" ] && printf '<p>%s</p>\n' "$3"
    printf '</body></html>\n'
  } > "$1"
}
NCLEAN="$WORK/n_clean.html"; nrender "$NCLEAN" 6
# Control arm: the case is only meaningful if BOTH class tokens really do recur, and the
# passport value never appears as a run. A fixture missing either makes N1b vacuous.
nirish="$(grep -c 'Irish' "$NCLEAN")"; nyear="$(grep -c '2027' "$NCLEAN")"
if [ "$nirish" -ge 2 ] && [ "$nyear" -ge 2 ] && ! grep -qF 'Irish, valid to 2027' "$NCLEAN"; then
  PASS "N1a: both class tokens recur across day boundaries ($nirish / $nyear lines) and never appear as the value itself — the recurrence case is real"
else
  FAIL "N1a: the recurrence fixture is not set up as claimed (Irish=$nirish, 2027=$nyear) — N1b would prove nothing"
fi
nfalse=0
for ndays in 1 2 3 4 6; do
  nf="$WORK/n_$ndays.html"; nrender "$nf" "$ndays"
  verify_publishable_content "$nf" "$NTD" >/dev/null 2>&1 || nfalse=$((nfalse+1))
done
if [ "$nfalse" -eq 0 ]; then
  PASS "N1b: a clean itinerary whose two class tokens recur across day boundaries publishes at 1, 2, 3, 4 and 6 days (0 false aborts)"
else
  FAIL "N1b: $nfalse of 5 day-counts falsely aborted — the conjunctive window still pairs across structural blocks"
fi
# N1c — SENSITIVITY. Without this arm N1b is satisfied by a matcher that stopped matching
# passports at all. The same render, plus the value carried in a single sentence.
NHIT="$WORK/n_hit.html"
nrender "$NHIT" 6 'Border note: carry your Irish passport, valid to 2027, at all times.'
if grep -qF 'Irish passport, valid to 2027' "$NHIT"; then
  PASS "N1c: the sensitivity fixture carries the passport value inside one block"
else
  FAIL "N1c: the sensitivity fixture does not carry the value — N1d would prove nothing"
fi
verify_publishable_content "$NHIT" "$NTD" >/dev/null 2>&1; nrc=$?
if [ "$nrc" -eq 1 ]; then PASS "N1d: the same render with the value in ONE block still aborts (rc=1) — block scoping narrowed the window, it did not disarm it"; else FAIL "N1d: a real same-block passport carry-through no longer aborts (rc=$nrc) — PR-7 over-corrected into a fail-open"; fi

# ─────────────────────────────────────────────────────────────────────────────
# Group O (#123 AC 3, second remediation) — the [THIRD-PARTY] member of the class.
# AC 3 says the class covers "every [THIRD-PARTY]-marked value in
# outputs/traveler-model.md". The shipped guard covered two things: the entry heading
# name, and the value of a line labelled `Specific:`. Three compounding gaps, all
# fail-OPEN, each pinned here by one case:
#   O1  the third-party arm was a FIELD ALLOWLIST — every other field default-allowed,
#       against reference/data-model.md § Lifecycle facets ("the bound is the entry
#       class, not a list of fields ... there is no default-allow outside it").
#   O2  the mark was read only off the ENTRY HEADING, though agents/00-enrichment.md
#       § Missing or blank profile, which requires it on "every value sourced this way"
#       and names mark-stripping as a KNOWN agent error. clean() also erased a value-level
#       mark before it could be consulted, so the ordering is part of the fix.
#   O3  `Specific:` is the PROFILE label. It occurs 0x in agents/00-enrichment.md (the
#       spec that WRITES the model) and 0x in agents/06-validator.md; the derived model's
#       own worked example (reference/data-model.md § Worked example — a per-traveler
#       file) writes the mid-line `; specific:` form. The guard bound a profile label to
#       a derived file.
#   O4  a bad merge strips both marks while retaining the values — the state
#       agents/00-enrichment.md § Missing or blank profile, which forbids it by name
#       ("supersede, do not merge"). It must never publish clean.
#   O5  the CONTROL that keeps the fix honest: a first-party operator-relayed need is
#       NOT in class (agents/06-validator.md § What You Audit, its profile-privacy
#       non-publication clause), and must still publish.
#   O6  the keyability-floor mitigation: a closed-enum category value is schema
#       vocabulary — neither a hit nor an UNDETERMINED sub-floor abort.
# Every case carries a fixture-integrity control arm graded BEFORE the verdict it
# protects (the K2/K3 idiom): a case whose control arm also returns zero is a BROKEN
# PROBE, not a pass. Every verdict asserts an EXACT return code rather than truthiness —
# `if func; then FAIL; else PASS` treats exit 127 from a deleted function as success, and
# the suite already carries four assertions of that shape (AI-009). This group adds none.
# Like L/M/N, group O runs purely on $WORK fixtures — no gh, no npx, no TTY, no network —
# so it cannot reach the SKIP path and its verdicts are real on every runner.
# ─────────────────────────────────────────────────────────────────────────────
echo "Third-party class: entry denylist, value-granularity mark, real model shape (#123 AC 3):"

OOUT="$WORK/o.err"; ORC=0
oguard() { verify_publishable_content "$1" "$2" >/dev/null 2>"$OOUT"; ORC=$?; }

# One shared render body, differing only in its final paragraph, so a verdict difference
# between two O cases is caused by that paragraph and nothing else. It carries the same
# near-misses group L uses (a packing-list "passport", destination-level entry guidance)
# and deliberately names NO party member, so a name-arm hit can never be the cause of an
# O verdict about a field.
orender() { # <out_file> <final paragraph>
  cat > "$1" <<HTML
<!DOCTYPE html><html><head><title>Porto Trip</title></head><body>
<h1>Itinerary</h1>
<p>Day 1: arrive at the river station, drop bags at the guest house, then walk the
covered market for an hour before an early dinner at the counter two streets over.</p>
<p>Day 2: the harbour museum in the morning, a long lunch by the water, then an
afternoon rest before the hill gardens in the late light.</p>
<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>
<p>Visa / entry: no visa required for stays under ninety days; a passport valid for six
months beyond arrival is expected at the border.</p>
<p>$2</p>
</body></html>
HTML
}
# The model is written AFTER its render in every case below. nonpublishable_values refuses
# an EMPTY class read from a projection older than the render (CD-3), so a case that
# expects rc=0 on an empty class must not have a model predating its own fixture render.
omodel() { # <trip_dir>  — model text on stdin
  mkdir -p "$1/outputs"; cat > "$1/outputs/traveler-model.md"
}

# ── O1 — a third-party field OTHER than the one the shipped guard matched ────
O1R="$WORK/o1.html"
orender "$O1R" 'Access note: crowded escalators and long unbroken stair flights bring on vertigo.'
O1TD="$WORK/o1_trip"
omodel "$O1TD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]
- Category: mobility
- Trigger: crowded escalators and long unbroken stair flights bring on vertigo
- Applies to: ## Hard Constraints -> "Mobility"
MD
# O1a — fixture integrity. The case is only about the allowlist if the entry carries NO
# `Specific:` field at all, the value really is in the render, and the party member is
# NOT named there (which would make the name arm the cause instead of the field).
if ! grep -qE '^[[:space:]]*-?[[:space:]]*Specific:' "$O1TD/outputs/traveler-model.md" \
   && grep -qF 'stair flights bring on vertigo' "$O1R" \
   && ! grep -qF 'Quill' "$O1R"; then
  PASS "O1a: the entry carries no 'Specific:' field, the render carries the value, and no name is in the render — O1b is about the field allowlist"
else
  FAIL "O1a: the O1 fixture is not set up as claimed — O1b would prove nothing"
fi
oguard "$O1R" "$O1TD"
if [ "$ORC" -eq 1 ]; then PASS "O1b: a third-party field other than 'Specific:' reaching the render aborts (rc=1) — the arm is an entry denylist, not a field allowlist"; else FAIL "O1b: a non-'Specific:' third-party field reached the render without aborting (rc=$ORC) — the field allowlist survives"; fi
# O1c — SPECIFICITY. The same field text under a NON-third-party entry must publish, or
# O1b is passing because the words are matched rather than because the entry is in class.
O1CTD="$WORK/o1_control"
omodel "$O1CTD" <<'MD'
# Traveler Model [DERIVED]

## Quill
- Trigger: crowded escalators and long unbroken stair flights bring on vertigo
MD
oguard "$O1R" "$O1CTD"
if [ "$ORC" -eq 0 ]; then PASS "O1c: the identical field text under an UNMARKED entry publishes (rc=0) — O1b's abort is caused by the [THIRD-PARTY] mark, not by the words"; else FAIL "O1c: an unmarked entry's field aborted (rc=$ORC) — the denylist is not bound to the mark"; fi

# ── O2 — the mark on the VALUE, not on the heading ───────────────────────────
O2R="$WORK/o2.html"
orender "$O2R" 'One member of the party cannot manage more than one flight of stairs in a single stretch.'
O2TD="$WORK/o2_trip"
omodel "$O2TD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED]
- Specific: cannot manage more than one flight of stairs in a single stretch [THIRD-PARTY]
MD
# O2a — fixture integrity. This is the corpus-named agent error: the heading mark is gone
# and only the value carries it. If the heading still carried the mark the case would be
# passing on the heading limb and would prove nothing about value granularity.
if ! grep -qF '## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]' "$O2TD/outputs/traveler-model.md" \
   && grep -qF '## Quill [OPERATOR-PROVIDED]'              "$O2TD/outputs/traveler-model.md" \
   && grep -qF 'single stretch [THIRD-PARTY]'              "$O2TD/outputs/traveler-model.md"; then
  PASS "O2a: the heading has NO mark and the value does — O2b is about value granularity"
else
  FAIL "O2a: the O2 fixture still marks the heading — O2b would prove nothing"
fi
oguard "$O2R" "$O2TD"
if [ "$ORC" -eq 1 ]; then PASS "O2b: a value-level [THIRD-PARTY] mark with a stripped heading mark aborts (rc=1) — the mark is read before clean() erases it"; else FAIL "O2b: a value-level mark was not consulted (rc=$ORC) — heading mark-stripping still empties the class silently"; fi
# O2c — SENSITIVITY. Remove the value-level mark and nothing else; the same render must
# publish. Without this arm O2b is satisfied by a guard that aborts on the text alone.
O2CTD="$WORK/o2_control"
omodel "$O2CTD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED]
- Specific: cannot manage more than one flight of stairs in a single stretch
MD
oguard "$O2R" "$O2CTD"
if [ "$ORC" -eq 0 ]; then PASS "O2c: the same model with the value-level mark REMOVED publishes (rc=0) — O2b's abort is caused by the mark itself"; else FAIL "O2c: an unmarked value aborted (rc=$ORC) — O2b is not measuring the mark"; fi

# ── O3 — the REAL derived-model shape ────────────────────────────────────────
O3R="$WORK/o3.html"
orender "$O3R" 'One member of the party cannot manage more than one flight of stairs in a single stretch.'
O3TD="$WORK/o3_trip"
omodel "$O3TD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]
- Need; specific: cannot manage more than one flight of stairs in a single stretch.
MD
# O3a — fixture integrity. The model must use the DERIVED mid-line `; specific:` form and
# carry zero line-anchored `Specific:` labels, or the case is re-testing the profile shape
# the shipped guard already matched.
if grep -qF '; specific:' "$O3TD/outputs/traveler-model.md" \
   && ! grep -qE '^[[:space:]]*-?[[:space:]]*Specific:' "$O3TD/outputs/traveler-model.md"; then
  PASS "O3a: the model uses the derived '; specific:' form and no profile-shape 'Specific:' label — O3b is about the model shape"
else
  FAIL "O3a: the O3 fixture is not in the derived shape — O3b would prove nothing"
fi
oguard "$O3R" "$O3TD"
if [ "$ORC" -eq 1 ]; then PASS "O3b: a third-party need in the REAL derived-model shape aborts (rc=1) — the guard is no longer bound to the profile label"; else FAIL "O3b: a derived-shape third-party need did not abort (rc=$ORC) — the guard still binds a profile label to a derived file"; fi
# O3c — SPECIFICITY, and it is the one that keeps the designed escalation path open. The
# first-party derived need line from data-model.md's own worked example, value carried
# verbatim into the render, must publish: a first-party need escalating to trip-context
# and thence to the page is correct content (agents/06-validator.md § What You Audit, its
# profile-privacy non-publication clause, "What is not a finding").
O3CR="$WORK/o3_control.html"
orender "$O3CR" 'Pacing: a ~15-min walking ceiling, step-free, on every travel day.'
O3CTD="$WORK/o3_control"
omodel "$O3CTD" <<'MD'
# Traveler Model [DERIVED]

## Jordan
- Need -> Hard Constraints "Limited stair & walking tolerance" (Applies to: Jordan); specific: ~15-min walking ceiling, step-free.
MD
oguard "$O3CR" "$O3CTD"
if [ "$ORC" -eq 0 ]; then PASS "O3c: a FIRST-PARTY need in the same derived shape, carried verbatim into the render, publishes (rc=0) — the escalation path stays open"; else FAIL "O3c: a first-party derived need aborted (rc=$ORC) — the denylist over-reaches beyond the third-party entry class"; fi

# ── O4 — a bad merge: both marks stripped, values retained ───────────────────
O4R="$WORK/o4.html"
orender "$O4R" 'One member of the party cannot manage more than one flight of stairs in a single stretch.'
O4TD="$WORK/o4_trip"
omodel "$O4TD" <<'MD'
# Traveler Model [DERIVED]

## Quill
- Specific: cannot manage more than one flight of stairs in a single stretch

## Update signals [DERIVED]
- Quill: profile filed; supersedes third-party-sourced entry [provenance change].
MD
# O4a — fixture integrity. The bad merge is defined by the marks being GONE while the
# values stay, with the provenance change recorded. If any mark survived, the case would
# be re-testing O2 rather than the merge. The count is of the MARK TOKEN in its uppercase
# form and must be zero; the recorded supersession says "third-party-sourced" in lower
# case and is deliberately not counted as a surviving mark.
o4marks="$(grep -c 'THIRD-PARTY' "$O4TD/outputs/traveler-model.md")"
o4vals="$(grep -c 'flight of stairs' "$O4TD/outputs/traveler-model.md")"
if [ "$o4marks" -eq 0 ] && [ "$o4vals" -ge 1 ] \
   && grep -qF 'supersedes third-party-sourced entry' "$O4TD/outputs/traveler-model.md" \
   && [ ! -d "$O4TD/travelers" ]; then
  PASS "O4a: both marks are stripped ($o4marks), the value survived ($o4vals), the supersession is recorded, and no profile backs it — O4b is about the merge"
else
  FAIL "O4a: the O4 fixture is not the bad-merge shape (marks=$o4marks values=$o4vals) — O4b would prove nothing"
fi
oguard "$O4R" "$O4TD"
if [ "$ORC" -eq 2 ]; then PASS "O4b: a recorded third-party supersession with no profile to support it is UNDETERMINED (rc=2) — never a clean publish"; else FAIL "O4b: a bad-merge model did not abort (rc=$ORC) — stripping the marks silently empties the class"; fi
# O4c — the ORPHANED-MARK backstop. The file says outright that it holds third-party
# content and the parse resolves it to nothing. That is the silent fail-open in its
# purest form: absence is not zero, and an unresolved PRESENCE is not zero either.
O4OTD="$WORK/o4_orphan"
omodel "$O4OTD" <<'MD'
# Traveler Model [DERIVED]
> One entry below was captured [THIRD-PARTY]; see the enrichment notes.

## Rowan
- Interests: markets, museums
MD
oguard "$O4R" "$O4OTD"
if [ "$ORC" -eq 2 ]; then PASS "O4c: a [THIRD-PARTY] mark that resolves to no class record is UNDETERMINED (rc=2) — an unresolved mark is not an empty class"; else FAIL "O4c: an orphaned [THIRD-PARTY] mark read as a clean empty class (rc=$ORC)"; fi
# O4d — SPECIFICITY for O4b. The same supersession WITH a profile backing it is the
# sanctioned provenance change (agents/00-enrichment.md § Missing or blank profile,
# "supersede, do not merge") and must not be refused,
# or the check is an always-abort rather than a discriminator.
O4STD="$WORK/o4_supported"
mkdir -p "$O4STD/travelers"
printf '# Traveler - Quill\n\n## Needs\n- Category: mobility\n' > "$O4STD/travelers/Quill.md"
omodel "$O4STD" <<'MD'
# Traveler Model [DERIVED]

## Quill
- Specific: cannot manage more than one flight of stairs in a single stretch

## Update signals [DERIVED]
- Quill: profile filed; supersedes third-party-sourced entry [provenance change].
MD
oguard "$O4R" "$O4STD"
if [ "$ORC" -eq 0 ]; then PASS "O4d: the same supersession WITH a per-traveler profile backing it publishes (rc=0) — the check discriminates supported from unsupported"; else FAIL "O4d: a supported supersession was refused (rc=$ORC) — the check is an always-abort, not a discriminator"; fi

# ── O5 — CONTROL: a first-party operator-relayed need must still publish ─────
O5R="$WORK/o5.html"
orender "$O5R" 'Pacing: Wren needs a slow start and no fixed plan before ten in the morning.'
O5TD="$WORK/o5_trip"
omodel "$O5TD" <<'MD'
# Traveler Model [DERIVED]

## Wren [OPERATOR-PROVIDED]
- Specific: needs a slow start and no fixed plan before ten in the morning
MD
# O5a — fixture integrity. The entry must carry [OPERATOR-PROVIDED] and NOT [THIRD-PARTY],
# and the render must really carry the need, or the publish proves nothing.
if grep -qF '[OPERATOR-PROVIDED]' "$O5TD/outputs/traveler-model.md" \
   && ! grep -qF 'THIRD-PARTY' "$O5TD/outputs/traveler-model.md" \
   && grep -qF 'slow start and no fixed plan before ten in the morning' "$O5R"; then
  PASS "O5a: the entry is [OPERATOR-PROVIDED] and NOT [THIRD-PARTY], and the render carries the need — O5b is a real control"
else
  FAIL "O5a: the O5 fixture is not set up as claimed — O5b would prove nothing"
fi
oguard "$O5R" "$O5TD"
if [ "$ORC" -eq 0 ]; then PASS "O5b: an [OPERATOR-PROVIDED] non-third-party need reaching the render PUBLISHES (rc=0) — the key is the mark whose subject could not consent, not who supplied it"; else FAIL "O5b: a first-party operator-relayed need aborted (rc=$ORC) — the denylist over-blocks the designed escalation path"; fi

# ── O6 — the keyability-floor mitigation, not an acceptance ──────────────────
# Under an entry denylist a one-word field would fall below the phrase rule's floor and
# return 3, which the predicate reports as UNDETERMINED — every publish of the trip
# aborting forever with no remedy. Two things prevent that: the rule is chosen from the
# value's own word count, and a value made entirely of closed-enum SCHEMA vocabulary
# states no traveler fact and is not a member at all.
O6R="$WORK/o6.html"
orender "$O6R" 'The afternoon rest is deliberate; the hill gardens are better in late light.'
O6TD="$WORK/o6_trip"
omodel "$O6TD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]
- Category: rest
MD
# O6a — fixture integrity. The render must actually use the enum word, and the entry's
# only field must be the enum-valued one, or the case is not testing the floor at all.
# `-e` is required, not stylistic: the pattern begins with a dash, and without `-e` grep
# parses it as an option bundle and exits 2 — which reads as "pattern absent" and failed
# this arm on its first CI run. The arm refused rather than passing quietly, which is the
# direction a fixture-integrity control is supposed to fail in.
if grep -qF 'afternoon rest' "$O6R" && grep -qF -e '- Category: rest' "$O6TD/outputs/traveler-model.md"; then
  PASS "O6a: the render uses the enum word and the entry's only field is the enum-valued one — O6b is about the floor"
else
  FAIL "O6a: the O6 fixture is not set up as claimed — O6b would prove nothing"
fi
oguard "$O6R" "$O6TD"
if [ "$ORC" -eq 0 ]; then PASS "O6b: a closed-enum category value neither aborts as a hit nor as a sub-floor UNDETERMINED (rc=0) — schema vocabulary is not a captured value"; else FAIL "O6b: an enum-only category value aborted (rc=$ORC) — the entry denylist turned a one-word field into a permanent abort"; fi
# O6c — SENSITIVITY. A category carrying text BEYOND the enum is a captured value and
# must still key, or O6b is passing because the category field was dropped entirely.
O6SR="$WORK/o6_sens.html"
orender "$O6SR" 'Access note: mobility, vertigo on unbroken stair flights.'
O6STD="$WORK/o6_sens"
omodel "$O6STD" <<'MD'
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]
- Category: mobility, vertigo on unbroken stair flights
MD
oguard "$O6SR" "$O6STD"
if [ "$ORC" -eq 1 ]; then PASS "O6c: a category carrying text beyond the enum still aborts (rc=1) — the enum exclusion is scoped to enum-ONLY values"; else FAIL "O6c: a category with a real captured value did not abort (rc=$ORC) — the enum exclusion dropped the whole field"; fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PF — no verdict in this suite, or in the publish script it guards, is decided by a
# pipeline's exit status.
#
# A verdict site whose writer pipes into an early-exiting `grep -q` is a live defect under
# the `pipefail` set at the top of this file, not a style preference: grep -q exits on
# first match, the writer dies on SIGPIPE, and pipefail reports the pipeline as failed
# although the match succeeded. Measured on an unchanged tree in the taxonomy suite before
# it was fixed: 10 red runs in 30, across two arms sharing nothing but the shape.
#
# Why a standing arm rather than a comment: the arms where this was OBSERVED are
# `if <test>; then PASS` sites, where the spurious status is a false RED and someone
# notices. This suite carried the inverted form too — I5 reads `if <test>; then FAIL`, so
# a spurious status there reported cmd_list read-only WITHOUT having checked it, and H2
# reported an opaque slug leak-free the same way. That direction announces nothing, which
# is why the shape is what is asserted absent rather than the arms it surfaced on.
#
# The publish script is in the scan set because this suite SOURCES it — its functions run
# in this shell under this file's `pipefail` — and because it is the production surface
# this repo actually ships; a scheduling-dependent verdict there refuses a correct publish.
#
# The needle is assembled from two pieces because this scan reads its own source — a
# literal spelling of the shape in the detector would make the detector match itself and
# report a defect it had just introduced.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group PF — no verdict here is decided by a pipeline's exit status."
PF_PIPE_SHAPE='| grep -'"q"
PF_PIPE_TIGHT='|grep -'"q"
PF_BAD=0; PF_GOOD=0; PF_UNREAD=0
for pffile in "$SELF" "$SELF_PUBLISH"; do
  if [ ! -r "$pffile" ]; then
    PF_UNREAD=$((PF_UNREAD+1)); continue
  fi
  while IFS= read -r pfline || [ -n "$pfline" ]; do
    # An OR-list is not a pipeline. Its two-character operator carries the one-character
    # one as a substring, so a correct `grep -qF a f OR grep -qF b f` line reads as the
    # defect shape and would turn this suite red for being right. Neutralise the operator
    # before the test rather than teaching both patterns about it — group E carries
    # exactly such a line, so this is a live concern and not a hypothetical one.
    pfscrub="${pfline//||/  }"
    case "$pfscrub" in
      *"$PF_PIPE_SHAPE"*|*"$PF_PIPE_TIGHT"*) PF_BAD=$((PF_BAD+1)) ;;
    esac
    case "$pfline" in
      *'grep -q'*'<<<'*) PF_GOOD=$((PF_GOOD+1)) ;;
    esac
  done < "$pffile"
done
# Graded in the order that makes the zero mean something: a scan that cannot read its
# inputs, or that finds no instance of the CORRECT form, is broken, and its zero on the
# incorrect form would be a probe failure wearing a pass. An empty input is broken, not
# clean — the same rule this suite's control arms apply to every other probe.
if [ "$PF_UNREAD" -ne 0 ]; then
  FAIL "PF1: $PF_UNREAD of the 2 files in the scan set were unreadable, so the verdict below would cover less than it claims"
elif [ "$PF_GOOD" -eq 0 ]; then
  FAIL "PF1: the scan found 0 here-string grep -q sites across the scan set, so its zero on the pipeline shape proves nothing — the convention or the scan has moved, and neither verdict is trustworthy"
elif [ "$PF_BAD" -eq 0 ]; then
  PASS "PF1: ${PF_GOOD} grep -q sites across this suite and the publish script it guards, 0 of them pipelines — no verdict here can be flipped by a SIGPIPE race under pipefail. The sensitivity arm fired (${PF_GOOD} > 0), so the zero is a measurement rather than an empty scan"
else
  FAIL "PF1: ${PF_BAD} verdict site(s) in the scan set pipe into an early-exiting grep under pipefail — it exits on first match, the writer takes SIGPIPE, and the pipeline reports failure on a successful match. Use the here-string form instead; it is a simple command, so pipefail has nothing to aggregate"
fi

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m, \033[1;33m%d skipped\033[0m\n' "$pass" "$fail" "$skip"
rc=0
[ "$fail" -eq 0 ] || rc=1
# STRICT SKIP MODE — a skip is a failure unless its group is declared. Without this the
# aggregate treats a skipped group exactly as a passing one, so a runner missing a
# dependency exits 0 with whole groups never run: a green that proves less than it
# appears to, which is worse than no CI at all. Unset, the verdict is the failure count
# alone and behaviour is unchanged.
if [ "${GUARD_STRICT_SKIPS:-0}" = "1" ]; then
  unexpected=""
  # shellcheck disable=SC2086
  for g in $SKIPPED; do
    case " ${GUARD_EXPECTED_SKIPS:-} " in
      *" $g "*) ;;
      *)        unexpected="$unexpected$g " ;;
    esac
  done
  if [ -n "$unexpected" ]; then
    printf 'STRICT: group(s) skipped but not declared in GUARD_EXPECTED_SKIPS: %s\n' "$unexpected"
    rc=1
  else
    printf 'STRICT: every skip was declared (%s) — no group vanished silently.\n' "${GUARD_EXPECTED_SKIPS:-none}"
  fi
fi
exit "$rc"
