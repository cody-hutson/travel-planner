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
# K = trips/ ignore invariant (#254) · L = plaintext content guard (#123).
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
  if printf '%s' "$NOREPLY_EMAIL" | grep -qE '@users\.noreply\.github\.com$'; then
    PASS "D1: resolved no-reply email ($NOREPLY_EMAIL)"
  else
    FAIL "D1: email is not a no-reply address ($NOREPLY_EMAIL)"
  fi
  R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q
  echo x > "$R/f"; git -C "$R" add f
  commit_noreply "$R" "test"
  ae="$(git -C "$R" log -1 --format='%ae')"
  if printf '%s' "$ae" | grep -qE '@users\.noreply\.github\.com$'; then PASS "D2: commit author email is no-reply ($ae)"; else FAIL "D2: commit leaked a non-no-reply email ($ae)"; fi
  # D3 — REGRESSION: hostile GIT_*_EMAIL env must NOT override the no-reply identity.
  R2="$WORK/repo2"; mkdir -p "$R2"; git -C "$R2" init -q
  echo x > "$R2/f"; git -C "$R2" add f
  GIT_AUTHOR_EMAIL='leak@personal.com' GIT_COMMITTER_EMAIL='leak@personal.com' \
    GIT_AUTHOR_NAME='Leaky' GIT_COMMITTER_NAME='Leaky' commit_noreply "$R2" "test"
  ae2="$(git -C "$R2" log -1 --format='%ae')"; ce2="$(git -C "$R2" log -1 --format='%ce')"
  if printf '%s|%s' "$ae2" "$ce2" | grep -qvE 'leak@personal\.com' && printf '%s' "$ae2" | grep -qE '@users\.noreply\.github\.com$'; then
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
if printf '%s' "$OSLUG" | grep -qiE 'tokyo|2026'; then FAIL "H2: opaque slug leaks destination/year ($OSLUG)"; else PASS "H2: opaque slug leaks neither destination nor year"; fi
ensure_opaque_slug "$OTD" >/dev/null 2>&1
[ "$(slug_for "$OTD")" = "$OSLUG" ] && PASS "H3: opaque slug is stable across calls (update/rotate resolve the same repo)" || FAIL "H3: opaque slug changed on re-run"
OTD2="$WORK/kyoto-2026"; mkdir -p "$OTD2"; printf 'chosen-name\n' > "$OTD2/.publish-slug"
ensure_opaque_slug "$OTD2" >/dev/null 2>&1
[ "$(slug_for "$OTD2")" = "chosen-name" ] && PASS "H4: pre-existing .publish-slug wins over --opaque" || FAIL "H4: --opaque overwrote an explicit .publish-slug"

echo "Inventory + date helpers (list, #25):"
EF="$WORK/site.html"; : > "$EF"
[ -n "$(_epoch_of_file "$EF")" ] && PASS "I1: _epoch_of_file returns an mtime epoch" || FAIL "I1: _epoch_of_file empty"
IE="$(_epoch_of_iso '2026-06-28T14:36:00Z')"
[ "$(_ymd_of_epoch "$IE")" = "2026-06-28" ] && PASS "I2: _epoch_of_iso + _ymd_of_epoch round-trip an ISO date" || FAIL "I2: ISO round-trip wrong ($IE -> $(_ymd_of_epoch "$IE"))"
[ "$(_ymd_of_epoch '')" = "-" ] && PASS "I3: _ymd_of_epoch renders empty as '-'" || FAIL "I3: empty epoch not '-'"
if _is_stale 200 100 && ! _is_stale 100 200 && ! _is_stale "" 100; then PASS "I4: stale iff local build newer than deployment (empty-safe)"; else FAIL "I4: stale rule wrong"; fi
if declare -f cmd_list | grep -qE 'git |commit_noreply|staticrypt|repo create|repo delete|api -X|rm -'; then
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

# L8 — AC 2 structurally: the class has ONE home. The predicate is a pure consumer with
# no class knowledge, which is what makes the #278 re-key a single-body edit. The second
# limb is the control arm: the same probe MUST fire on the class source, or the zero on
# the predicate is a broken probe rather than a clean result.
lpred="$(declare -f verify_publishable_content | grep -cE 'THIRD-PARTY|Passport:')"
lsrc="$(declare -f nonpublishable_values      | grep -cE 'THIRD-PARTY|Passport:')"
if [ "$lpred" -eq 0 ] && [ "$lsrc" -gt 0 ]; then
  PASS "L8: class knowledge lives in the class source ($lsrc hits) and not in the predicate (0) — control arm fires"
else
  FAIL "L8: the one-home seam is gone or the probe is broken (predicate=$lpred source=$lsrc)"
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
