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
# Pure-bash tests (A–C2) always run. Identity tests (D) skip without gh auth.
# Real-StatiCrypt smoke test (E) skips if npx/staticrypt is unavailable.
#
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=publish-trip-site.sh
source "$HERE/publish-trip-site.sh"      # BASH_SOURCE guard prevents dispatch
set +e

pass=0; fail=0
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); }
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; }

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

echo
printf 'Result: \033[1;32m%d passed\033[0m, \033[1;31m%d failed\033[0m\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
