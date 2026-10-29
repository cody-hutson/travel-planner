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
# Pure-bash tests (A–C2, F, H, I, K, L, Q, U, MD, FZ, PP, RV, RS) always run. Identity (D) + unpublish idempotency (J1)
# skip without gh auth. Real-StatiCrypt tests (E, G) skip if npx/staticrypt is unavailable.
# That parenthesis is a reading aid and has never been complete — the AUTHORITATIVE roster
# of groups that run is the coverage boundary in .github/workflows/publish-guard.yml, and
# group RS below parses it and set-diffs it against this run in both directions. Read the
# boundary, not this line: it is asserted and this line is not.
# H = --opaque naming (#6) · I = list / date helpers (#25) · J = unpublish / takedown (#7)
# K = trips/ ignore invariant (#254) · L = plaintext content guard (#123)
# Q = analysis/ workspace ignore invariant (same shape as K, lower severity)
# U = people/ person-store ignore invariant (#534) — same shape as K and Q, highest severity.
# K4/Q4 are RULE-level, not state-level: they fail on a deleted negation line, which
# K1/Q1 cannot see because a tracked file bypasses .gitignore altogether.
# L8-L10 grade the publishability DECLARATION: that the class has exactly one home, that
# the guard's verdict follows a change to it, and that an unreadable declaration is
# UNDETERMINED rather than an empty class. L11 pins the reserved-heading suppression —
# both limbs, one of which has no backstop. L14 and L15 grade the --data-root seam: L14 on
# the person store, L15 on the <trip-dir> argument, EXECUTING the script from a working
# directory that is not the data root — the only shape an installed engine's verbs produce.
# L16 is the denial side of `may-carry` (ADR-026 § Decision 3), one must-fire per declared
# row: a value under each row's selector, planted at that row's scope, aborts as a HIT, and
# the same trip without it publishes. The rows are read from the live declaration.
# L17 grades the guard reading its own projections: one that fails, or a published or joined
# one that yields no words, is UNDETERMINED (rc=2) whatever the caller's `pipefail`, and the
# refusal names the projection and nothing else. L17f grades that every arm of both content
# guards runs through the one arm helper and counts through the one count, and L17g that the
# count subtracts both sentinels.
# M = published-bytes / stoplist / freshness remediation (#123 A6.5) · N = block-scoped
# conjunctive window (#123 PR-7) · O = the [THIRD-PARTY] class: entry denylist,
# value-granularity mark, real derived-model shape (#123 AC 3).
# M6 = the pre-0.60.0 parity cells (CIAC-1): every page the suite renders in groups L to O that
# the guard before 0.60.0 blocked is blocked at the head, read by a recorder that wraps the guard
# from group L to M6.
# M7 = the guard's fourth arm (#2068, ADR-050): the published projection as the guard before 0.60.0
# wrote it, read last and credited last, blocks again the pages it blocked — a value whose words
# tags and attribute names push apart inside a script string, a comment or an attribute value —
# while criterion 5's `=` render is still named for the published arm.
# R = the change-summary (#550). R1-R5 grade its CONTENT guard (AC 5) —
# verify_summary_content over outputs/change-summary.md, an `internal` artifact
# verify_publishable_content never sees: the clean/HIT/UNDETERMINED triple, the
# RE-DERIVED word floor, and the markdown block sentinel that keeps the conjunctive
# rule scoped. R6 grades the BUCKET PREDICATES (AC 1 / AC 4, second remediation) — that
# the placement tuple the emitter spec declares actually detects a same-day time move
# on the shipped witness, that an unchanged re-bake still detects nothing, that
# time is compared WITHIN the matched key rather than folded into it, and that a
# status-only change reaches STATUS-CHANGED instead of being re-reported as MOVED. R8
# grades the summary guard reading its projection's status: one that fails after a prefix
# clearing the floor is UNDETERMINED (rc=2), whatever the caller's `pipefail`.
# S = the organizer-confirm gate (#552 AC 5) — the republish path gates on the
# organizer's confirmation of an ITINERARY-CONTENT change, not on publish-as-such, so a
# coordination-marker-only republish still reaches the group. Grades both branches
# (confirmed republish, rejected hold), the stale and malformed-record cases, that the
# abort is the DEFAULT arm rather than an enumerated one, rotate's inheritance and
# cmd_publish's ungated safety end-to-end against a mock gh, and that neither ADR-002
# Decision 4 guard was touched. S11 grades the PROJECTION the gate reads (D10, second
# remediation) — that strip_to_itinerary_text has ONE limb, so a failing or absent perl
# cannot substitute a second, band-retaining projection into the digest; that the failure
# is audible and early rather than silent; and that an empty answer means the projection
# failed rather than that the render had no visible text. S12 grades that projection
# against a CONFORMANT C19 render (third remediation, SEAM-2) — that the declaration block
# C19 carries in an HTML comment leaves the itinerary digest by construction, so neither a
# coordination state transition nor a next-day `generated:` drift reads to the gate as an
# itinerary change, while a real plan edit still does.
# T = the coordination notice (#551 AC 5) — the band's IDENTITY (the class token the
# component contract declares is the one the shipped projection excises, read from the
# document rather than spelled here), its state VOCABULARY (the contract's variants and
# C19's coordination-state enum, set-diffed both ways), and the NULL CASE: absent a
# pending change or a recent update the render is byte-identical to a pre-component
# render and the itinerary projection is byte-identical to strip_to_text on the
# comment-free input this group builds (S12d owns the comment-bearing case, where the two
# are required to differ). T5 grades the
# ANCHOR (AC 2, second remediation) — that `coordination-since` for the `updated` state is
# read from the confirmation's own record rather than re-derived from the run, so the
# seven-day decay window does not restart on every rebuild. T6/T7 grade the STATE (AC 2 /
# AC 5, second remediation) — that the record the mapping derives coordination-state from is
# the record the shipped confirm subcommand writes, so `updated` is reachable and the pending
# band clears; and that the band is outside the itinerary digest on a render carrying C19's
# own declaration block. T7c grades the block itself: it once measured the residual that
# block left in the digest and now asserts its absence, the projection having been repaired
# by the third remediation graded in S12.
# PP = the site passphrase never reaches standard output (#330). publish and rotate are
# each run end-to-end offline and their captured standard output is graded COMPOUND: it
# must carry the passphrase FILE PATH and must not carry the value, because a plain
# value-absence test is satisfied by an announcer that never ran. PP7 restores the pre-fix
# value-emitting announcer on every run and requires the same arm to convict it; PP8 grades
# the env-supplied limb, where the shipped message claimed a file it had not written.
# RV = a rotation revokes (GHSA-gmm2-v7rr-jq7r). The page rotate pushes is bound, by a nonce in
# its ciphertext, to the key it was encrypted under, and must be under the key .passphrase
# records whatever STATICRYPT_PASSWORD carries. publish and update refuse when the variable
# and .passphrase disagree, before any network effect; an aborted rotation leaves .passphrase
# byte-identical at every abort point; an update stopped because the key of record changed
# under it leaves no commit behind for a later push to carry; a push publishes exactly the commit
# its own run made; and the arms that grade
# independence from errexit run without it, because that is what they grade.
# MD = the Discriminating-Evidence Rule, asserted against this file. Every assertion's
# PASS must require evidence its subject could only have produced by RUNNING. MD re-runs
# each REGISTERED assertion with its subject removed and requires that assertion to flip
# — per assertion, because the suite as a whole already went red under the mutation that
# left A, C, C2, G2 and I5 all PASSing, so a suite-level red/green oracle would certify a
# fix that changed nothing — and statically scans this file for the polarity-negative
# shape, so an assertion ADDED in that shape is caught even when nobody registers it.
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
# Group RS reads the workflow that runs this suite. Same idiom, and same reason, as the
# taxonomy suite binding its own trigger into group Z's watch set: a guard that cannot
# see the file declaring its own coverage is the one thing a reader would least expect
# it to miss.
ROOT="$(dirname "$HERE")"
# shellcheck source=publish-trip-site.sh
source "$HERE/publish-trip-site.sh"      # BASH_SOURCE guard prevents dispatch
set +e
# Hermetic: an inherited STATICRYPT_PASSWORD would silently turn every file-backed arm below
# into an environment-supplied one. Arms that need the variable set it in their own subshell.
unset STATICRYPT_PASSWORD

pass=0; fail=0; skip=0; SKIPPED=""; SEEN=""
# Every verdict records its assertion id — the token before the first colon of the
# message — so group RS at the bottom can ask which GROUPS actually emitted. SKIP has
# always done this; PASS and FAIL did not, and that asymmetry IS the gap RS closes. A
# group that is deleted, renamed or made unreachable emits nothing at all: it never
# skips, so it never reaches the strict-skip comparison below and vanishes silently.
# The two controls stay orthogonal — RS asks "did the group run", strict-skip asks "was
# the skip declared" — and a group that only ever skips is present to both.
PASS() { printf '  \033[1;32mPASS\033[0m %s\n' "$*"; pass=$((pass+1)); SEEN="$SEEN${*%%:*} "; }
FAIL() { printf '  \033[1;31mFAIL\033[0m %s\n' "$*"; fail=$((fail+1)); SEEN="$SEEN${*%%:*} "; }
# Records the skipped group's id — the token before the first colon of the message — so
# the aggregate verdict at the bottom can refuse a run in which a group vanished.
SKIP() { printf '  \033[1;33mSKIP\033[0m %s\n' "$*"; skip=$((skip+1)); SKIPPED="$SKIPPED${*%%:*} "; }

# ── THE DISCRIMINATING-EVIDENCE RULE (DER) — two helpers, asserted by group MD ─────
#
# THE RULE. An assertion is MUTATION-DETECTABLE iff every path to its PASS requires
# evidence the subject could only have produced by RUNNING. Equivalently: PASS may never
# be reached on a branch a DEGENERATE outcome also reaches — an absent subject, an empty
# haystack, an unreadable input, an empty population.
#
# expect_rc replaces bare truthiness with an exact expected status. `if f …; then FAIL;
# else PASS` puts the PASS on EVERY non-zero status, so rc=127 — "the function does not
# exist" — is graded identically to rc=1 — "the guard correctly rejected". That is not a
# hypothetical: deleting verify_ciphertext outright from the publish script left A, C, C2
# and G2 all reporting PASS, and deleting cmd_list entirely left I5 reporting PASS while
# the suite exited 0. The status is the evidence, so the status is what is asserted.
#
# An exact code is available here rather than merely stricter: verify_ciphertext returns
# exactly 0 or 1 (six `return` statements, five of them 1), `git check-ignore -q` returns
# 1 for not-ignored and 128 for an error, `grep -q` returns 1 for no-match and 2 for an
# unreadable input, and slug_for's rejection path exits 1. Each was read before the code
# it expects was written.
expect_rc() {   # expect_rc <want> <id> <prose> -- <cmd…>
  local want="$1" id="$2" prose="$3"; shift 3
  [ "${1:-}" = "--" ] && shift
  local subject="${1:-<no-command>}" got
  "$@" >/dev/null 2>&1; got=$?
  if [ "$got" -eq 127 ] && [ "$want" -ne 127 ]; then
    FAIL "$id: $prose -- rc=127: '$subject' is NOT DEFINED. The subject is ABSENT, not rejecting, so this assertion has no subject to grade"
  elif [ "$got" -eq "$want" ]; then
    PASS "$id: $prose [rc=$got, expected $want]"
  else
    FAIL "$id: $prose -- expected rc=$want, got rc=$got"
  fi
}

# md_probe re-runs an assertion in a subshell with its SUBJECT removed and reports the
# verdict counts it produced. It is the card's criterion made executable: for assertion X
# over subject S, removing S must flip X — and it must flip X SPECIFICALLY, not flip some
# other assertion that happens to point the other way. Group MD at the bottom grades it.
# PASS/FAIL are rebound to silent counters inside the subshell, so nothing a probe emits
# reaches the run's counters, the SEEN roster, or the output.
md_probe() {   # md_probe <subject-fn> <assertion-fn> [args…] -> "<pass> <fail>" on stdout
  local victim="$1"; shift
  ( unset -f "$victim" 2>/dev/null
    pass=0; fail=0
    PASS() { pass=$((pass+1)); }
    FAIL() { fail=$((fail+1)); }
    "$@" >/dev/null 2>&1
    printf '%d %d' "$pass" "$fail" )
}

md_flips() {   # md_flips <subject-fn> <id> <assertion-fn> [args…]
  local victim="$1" id="$2"; shift 2
  local out p f
  out="$(md_probe "$victim" "$@")"
  if ! [[ "$out" =~ ^[0-9]+[[:space:]][0-9]+$ ]]; then
    FAIL "MD[$id]: the oracle subshell returned '$out' rather than a '<pass> <fail>' pair — the probe itself failed, so this arm is not a measurement"
    return 0
  fi
  p="${out%% *}"; f="${out##* }"
  if [ "$f" -eq 1 ] && [ "$p" -eq 0 ]; then
    PASS "MD[$id]: with '$victim' removed the assertion reports exactly one FAIL and no PASS — it is mutation-detectable, so its verdict above required '$victim' to have RUN"
  else
    FAIL "MD[$id]: with '$victim' removed the assertion still reports pass=$p fail=$f — it is BLIND to its subject's absence, so its verdict above proves nothing about '$victim'"
  fi
  return 0
}

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
# A, C and C2 are each a NEGATIVE-polarity assertion — the guard is required to REJECT —
# and each is wrapped in its own function so group MD can re-run the identical argv with
# verify_ciphertext removed. The wrapper is not decoration: an assertion the oracle cannot
# re-invoke cannot be registered, and an unregistered assertion is graded by the static
# arm's shape rule alone.
#
# A — never certify the source as its own ciphertext (self-check).
a_assert() { expect_rc 1 "A" "guard rejects source-as-output (self-check)" -- verify_ciphertext "$SRC" "$SRC"; }
a_assert
# B — passes clean ciphertext. POSITIVE polarity: an absent subject exits 127, which lands
# on the FAIL limb, so this shape was already sound and is deliberately left alone.
if verify_ciphertext "$ENC_OK" "$SRC"; then PASS "B: guard passes clean ciphertext"; else FAIL "B: guard rejected clean ciphertext"; fi
# C — catches a plaintext token leaked into otherwise-encrypted output.
c_assert() { expect_rc 1 "C" "guard catches leaked plaintext token" -- verify_ciphertext "$ENC_LEAK" "$SRC"; }
c_assert
# C2 — REGRESSION: all-lowercase plaintext with sentinel strings must be caught structurally.
c2_assert() { expect_rc 1 "C2" "guard catches all-lowercase plaintext via visible-body check" -- verify_ciphertext "$PLAIN_LOWER" "$TINY"; }
c2_assert

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
    g2_assert() { expect_rc 1 "G2" "without boilerplate ref the false positive still fires (subtraction is the fix)" -- verify_ciphertext "$ENC_CMN/index.html" "$CMN"; }
    g2_assert
    # G2's MD registration is emitted HERE rather than with the rest of group MD at the
    # bottom, because its two fixtures are encrypted trees outside $WORK that the next
    # line deletes. Re-running the assertion after that point would fail on a missing
    # input rather than on a missing subject, which is a different claim. Everything the
    # registration asserts is the same; only its position in the output moves.
    md_flips verify_ciphertext "G2" g2_assert
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
# I5 — an INTROSPECTION assertion, and the emptiness conflation is its own defect class.
# `grep -q <verbs> <<<"$(declare -f cmd_list)"` on an absent cmd_list scans an EMPTY
# haystack, matches nothing, and reports the subcommand read-only. Measured: deleting
# cmd_list outright left this arm PASSing and the whole suite exiting 0.
#
# Three preconditions therefore run before the content is graded, and each is the
# discriminating evidence for a different degenerate input: the subject is DEFINED, its
# body is NON-DEGENERATE (a floor far below the 2,231-byte shipped body, so it catches a
# gutted subcommand without churning as the subcommand grows), and the verb probe itself
# actually RAN — grep exits 2 on an unreadable input, which is neither match nor no-match,
# and a clean verdict on an rc=2 would be an empty scan wearing a pass.
i5_assert() {
  local body mrc
  body="$(declare -f cmd_list 2>/dev/null)"
  grep -qE 'git |commit_noreply|staticrypt|repo create|repo delete|api -X|rm -' <<<"$body" >/dev/null 2>&1; mrc=$?
  if ! declare -f cmd_list >/dev/null 2>&1; then
    FAIL "I5: cmd_list is NOT DEFINED — the read-only verdict below would have no subject, so it would certify a subcommand that does not exist"
  elif [ "${#body}" -lt 200 ]; then
    FAIL "I5: cmd_list's body is only ${#body}B — too small to be the shipped subcommand, so a clean scan of it proves nothing"
  elif [ "$mrc" -eq 0 ]; then
    FAIL "I5: cmd_list contains a mutating operation (must be read-only)"
  elif [ "$mrc" -ne 1 ]; then
    FAIL "I5: the mutating-verb probe exited rc=$mrc — neither match (0) nor no-match (1), so the scan did not run and a clean verdict would be an empty scan"
  else
    PASS "I5: cmd_list is read-only (no git/push/encrypt/create/delete/write verbs) — subject present, body ${#body}B and non-degenerate, verb probe ran and returned no-match"
  fi
}
i5_assert

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
  # K4 (rule-level, not state-level). K1 proves the file is IN THE INDEX,
  # which stays true even if the negation line is deleted — a tracked file bypasses
  # .gitignore entirely, so K1 and K2 both keep passing while the rule rots.
  # --no-index is LOAD-BEARING: check-ignore consults the index by default and
  # short-circuits to "not ignored" for any tracked path WITHOUT evaluating the
  # rules, so without it this assertion re-reads state and can never go red.
  # Verified by falsification: with the negation line deleted, the default form
  # still passed. K2/Q2 need no such flag — they probe untracked synthetic paths.
  # This is the only assertion that fails on a deleted `!trips/README.md` line,
  # and the failure it prevents is a re-add after a delete silently not working.
  if git -C "$HERE/.." check-ignore -q --no-index "trips/README.md"; then
    FAIL "K4: the !trips/README.md negation is gone — the trips signpost survives only because it is already tracked"
  else
    PASS "K4: the negation pattern re-includes trips/README.md (the rule, not just the index, is intact)"
  fi
else
  SKIP "K: not a git work tree"
fi

echo "Analysis-workspace ignore invariant:"
# Same invariant shape as K, different blast radius. K guards passport-bearing trip
# data; Q guards the analysis workspace — operator working material (raw issue pulls,
# scratch scripts, findings about a commit that is no longer HEAD). Kept a separate
# group rather than folded into K so the two severities stay separately reportable.
if git -C "$HERE/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Q1 (positive) — the signpost ships. Trackedness, not ignore-state: a tracked file
  # bypasses .gitignore entirely, so ls-files is the unambiguous test.
  if git -C "$HERE/.." ls-files --error-unmatch analysis/README.md >/dev/null 2>&1; then
    PASS "Q1: analysis/README.md is tracked (the signpost ships in a fresh clone)"
  else
    FAIL "Q1: analysis/README.md is NOT tracked — the folder is absent from a fresh clone"
  fi
  # Q2 (negative — the limb that matters). Probes at the DEEPEST real shape, not the
  # shallowest: a dated subfolder's _cache/ is where the raw pulls land, so a rule that
  # only caught top-level files would pass a shallow probe and leak the bytes that
  # actually matter. check-ignore needs no file on disk; nothing synthetic is written.
  # -q, NOT -v: verbose exits 0 on a NEGATION match too, inverting the verdict.
  if git -C "$HERE/.." check-ignore -q "analysis/zzz-probe-2026-01-01/_cache/graphql_issues.json"; then
    PASS "Q2: a synthetic analysis/<name>-YYYY-MM-DD/_cache/<x> is still git-ignored"
  else
    FAIL "Q2: ANALYSIS IS NO LONGER IGNORED — .gitignore stopped guarding analysis/ contents"
  fi
  # Q3 (control arm) — a zero whose control also returns zero is a broken probe.
  if git -C "$HERE/.." check-ignore -q "README.md"; then
    FAIL "Q3: control arm broken — check-ignore calls the tracked root README.md ignored; Q2 is unusable"
  else
    PASS "Q3: control arm fires (root README.md not ignored) — Q2's verdict is trustworthy"
  fi
  # Q4 (rule-level, not state-level). Q1 proves the file is IN THE INDEX,
  # which stays true even if the negation line is deleted — a tracked file bypasses
  # .gitignore entirely, so Q1 and Q2 both keep passing while the rule rots.
  # --no-index is LOAD-BEARING: check-ignore consults the index by default and
  # short-circuits to "not ignored" for any tracked path WITHOUT evaluating the
  # rules, so without it this assertion re-reads state and can never go red.
  # Verified by falsification: with the negation line deleted, the default form
  # still passed. K2/Q2 need no such flag — they probe untracked synthetic paths.
  # This is the only assertion that fails on a deleted `!analysis/README.md` line,
  # and the failure it prevents is a re-add after a delete silently not working.
  if git -C "$HERE/.." check-ignore -q --no-index "analysis/README.md"; then
    FAIL "Q4: the !analysis/README.md negation is gone — the analysis signpost survives only because it is already tracked"
  else
    PASS "Q4: the negation pattern re-includes analysis/README.md (the rule, not just the index, is intact)"
  fi
else
  SKIP "Q: not a git work tree"
fi

echo "Person-store ignore invariant (#534):"
# Same invariant shape as K and Q, and the highest severity of the three. K guards
# passport-bearing trip data; Q guards operator working material; U guards the durable
# person store — one file per person, held across trips rather than copied into each.
# Kept a separate group rather than folded into K, on Q's stated rule, so a passport-store
# regression and a person-store regression are not one line of output.
# Every check-ignore call below takes the same modifiers — -c core.ignorecase=false, -q,
# and --no-index where the subject is or may be tracked — so a reader comparing two arms
# is comparing subjects, not spellings. The ignorecase pin is not decoration: it is `true`
# on a macOS working copy and `false` on the Linux CI runner, and without it a case-altered
# negation (!/people/readme.md) reads green on the host a human would break it on.
#
# Two probe-design rules this group learned the hard way and states so they are not undone:
#   (1) THE SUBJECT SET SPANS MORE THAN ONE EXTENSION. An ignore rule can be broken by
#       narrowing as well as by removal, and a group whose every probe path ends in .md
#       cannot see a narrowing — /people/* rewritten to /people/*.md left this group green
#       while making a scanned passport committable. U2 and U2b are that pair.
#   (2) A CONTROL'S INPUT IS NEVER GOVERNED BY THE RULE UNDER TEST. U0-CTL probes .env and
#       U3 probes an untracked synthetic, both outside /people/, so a store-rule change
#       moves the subject arms and leaves the controls alone. A control that reddens with
#       its own subject still detects, but it can no longer tell "the instrument is broken"
#       from "the rule is gone" — which is the one property that makes it a control.
if git -C "$HERE/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then

  # U0-CTL (MUST FIRE) — the instrument, before any verdict is read from it.
  # U4 and U5 both PASS on "not ignored". Nothing in K or Q proves that the
  # --no-index form is capable of returning "ignored" at all, so a form that
  # silently answered "not ignored" for every input would show as two green arms.
  # This arm is the one input that must come back IGNORED.
  #
  # ITS INPUT IS DELIBERATELY NOT A people/ PATH, and that is the whole point of the
  # arm. A control's defining property is independence from its subject. An earlier
  # form of this arm probed people/psn-zzzz-probe.md — a path that is ignored BY THE
  # VERY RULE this group tests — so deleting /people/* darkened the control alongside
  # U2, and the transcript then read "none of their verdicts can be trusted" at the
  # exact moment U2's verdict was both correct and the only one that mattered. A
  # reader who takes a control at its word would discount the arm that named the
  # defect. .env is ignored by the unrelated Environment block at the foot of
  # .gitignore: it is outside all three guarded stores (trips/, /analysis/, /people/),
  # so no mutation of any store rule can move it, and it is untracked so --no-index
  # changes nothing about the answer. Measured under every store mutation in the
  # group's ladder: IGNORED throughout.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index ".env"; then
    PASS "U0-CTL: MUST FIRE — the --no-index form returns IGNORED for .env, a path ignored by a rule none of the store groups touch, so U4/U5's NOT-IGNORED verdicts below are measurements rather than a form that cannot say otherwise"
  else
    FAIL "U0-CTL: MUST FIRE — the --no-index form called .env NOT ignored. .env is ignored by a rule independent of every store guard, so this is the instrument failing and not a store regression; every U arm reading that form is a broken probe and none of their verdicts can be trusted"
  fi

  # U1 (positive) — the signpost ships. Trackedness, not ignore-state: a tracked
  # file bypasses .gitignore entirely, so ls-files is the unambiguous test. (K1/Q1)
  if git -C "$HERE/.." ls-files --error-unmatch people/README.md >/dev/null 2>&1; then
    PASS "U1: people/README.md is tracked (the signpost ships in a fresh clone)"
  else
    FAIL "U1: people/README.md is NOT tracked — the store's signpost is absent from a fresh clone"
  fi

  # U2 (negative — the limb that matters). Probes at the DEEPEST shape the store
  # admits, not the shallowest. check-ignore needs no file on disk, so no synthetic
  # person record is ever written. -q, NOT -v: verbose exits 0 on a NEGATION match
  # too, inverting the verdict.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "people/psn-zzzz-probe.md"; then
    PASS "U2: a synthetic people/psn-<token>.md is still git-ignored"
  else
    FAIL "U2: PERSON RECORDS ARE NO LONGER IGNORED — .gitignore stopped guarding people/ contents, and this store holds the most sensitive bytes in the repository"
  fi

  # U2b (negative — the SUFFIX limb). U2 alone cannot see a narrowing, only a removal.
  # Every other probe path in this group ends in .md — U0-CTL's old input, U2's subject,
  # U4's signpost, U5's derived witness — so rewriting /people/* to /people/*.md left the
  # whole group green while making every non-markdown file in the store trackable. That is
  # not a hypothetical shape: a scanned passport is a .jpg, a .png or a .pdf, and a
  # narrowing that reads as tidying is exactly the "simplification" the .gitignore comment
  # warns against. The store rule is a CONTENTS rule and must hold for every extension, so
  # this arm probes the one thing a suffix pattern excludes: a subject that is not markdown.
  # It is a second probe path, not a second rule — U2 and U2b fail together on a removal
  # and only U2b fails on a narrowing, which is what makes the pair discriminating.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "people/psn-zzzz-probe.jpg"; then
    PASS "U2b: a synthetic NON-markdown people/psn-<token>.jpg is still git-ignored — the rule guards the store's contents by path, not by extension"
  else
    FAIL "U2b: A NON-MARKDOWN FILE IN THE PERSON STORE IS NOT IGNORED — a scanned passport, a PDF or an export at people/<record>.jpg is committable. Read U2 beside this: U2 green means the rule was NARROWED BY SUFFIX and only non-markdown is exposed; U2 red means the rule is gone entirely"
  fi

  # U3 (control arm) — a zero whose control also returns zero is a broken probe.
  # The subject is UNTRACKED and synthetic, which is load-bearing for the same reason
  # --no-index is on U4. Without --no-index, check-ignore short-circuits on the index and
  # answers NOT_IGNORED for any tracked path WITHOUT EVALUATING THE RULES. This arm used
  # to probe the tracked root README.md, so it was reading index state and asserting a
  # rule-level fact: prepending /README.md to .gitignore makes the rule genuinely ignore
  # it (--no-index returns IGNORED) while this arm's own form still returns NOT_IGNORED
  # and still passes. That is the defect U4 exists to close for U1, one arm over. An
  # untracked path is never short-circuited, so it reaches the same evaluator U2 uses on
  # the same code path — measured live in both directions: NOT_IGNORED under the shipped
  # rules, IGNORED as soon as a rule matching it is added.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "zzq-nonesuch-probe.md"; then
    FAIL "U3: control arm broken — check-ignore calls an untracked, unmatched synthetic path ignored, so it cannot distinguish ignored from not-ignored and U2/U2b are unusable"
  else
    PASS "U3: control arm fires (an untracked, rule-unmatched synthetic path is not ignored) — the rule evaluator U2/U2b read can return NOT_IGNORED, so their verdicts are trustworthy"
  fi

  # U4 (rule-level, not state-level). U1 proves the file is IN THE INDEX, which
  # stays true even if the negation line is deleted — a tracked file bypasses
  # .gitignore altogether, so U1 and U2 both keep passing while the rule rots.
  # --no-index is LOAD-BEARING (the K4/Q4 falsification). This arm is also the only
  # one that fails on a "simplification" to /people/ or people/ (the directory form
  # git cannot re-include through) and on a line-order swap, .gitignore being
  # last-match-wins.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index "people/README.md"; then
    FAIL "U4: the !/people/README.md negation is gone or unreachable — the store's signpost survives only because it is already tracked"
  else
    PASS "U4: the negation pattern re-includes people/README.md (the rule, not just the index, is intact)"
  fi

  # U5 — the arm neither K nor Q has, in two parts. The witness is READ FROM the
  # tree rather than spelled here: check-ignore answers for paths that do not
  # exist, so an arm naming a token this file guessed would return "not ignored"
  # for an absent file and pass. An empty derivation is a FAILURE, not a clean run.
  # --no-index is load-bearing HERE TOO, not only on U4: the witness is tracked, so
  # the default form short-circuits past the rules and returns "not ignored" under
  # the very widening (**/people/*) this arm exists to catch.
  U5_WIT="$(git -C "$HERE/.." ls-files 'examples/*/people/*.md')"
  U5_N="$(printf '%s\n' "$U5_WIT" | grep -c '[^[:space:]]')"
  U5_BAD=0
  while IFS= read -r u5p; do
    [ -n "$u5p" ] || continue
    git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index "$u5p" && U5_BAD=$((U5_BAD+1))
  done <<EOF
$U5_WIT
EOF
  if [ "$U5_N" -eq 0 ]; then
    FAIL "U5: no tracked witness matched examples/*/people/*.md — the schema names a witness the selector never reaches, and this arm would otherwise report a clean run over an empty set"
  elif [ "$U5_BAD" -eq 0 ]; then
    PASS "U5: all $U5_N tracked example witness record(s) under examples/*/people/ are NOT ignored — the store rule is rooted, so a same-named directory elsewhere in the tree keeps its tracked contents"
  else
    FAIL "U5: $U5_BAD of $U5_N tracked example witness record(s) are IGNORED — the people/ rule has been widened (**/people/* or an unrooted people/) and the schema's witness has silently left the index"
  fi

else
  SKIP "U: not a git work tree"
fi

echo "Group-store ignore invariant (#546):"
# The fourth store guard, and the same invariant shape as K, Q and U. K guards
# passport-bearing trip data; Q guards operator working material; U guards the durable
# person store; V guards the reusable-group store — one file per named set of people,
# holding person ids and nothing else. Kept a separate group rather than folded into U,
# on the rule Q stated and U repeated, so a person-store regression and a group-store
# regression are not one line of output.
#
# WHY THIS STORE EARNS ITS OWN GROUP AT ALL, stated because "it only holds ids" invites
# the opposite conclusion. A single person id discloses nothing on its own; a group record
# is a SET of them, and a set says that these particular people travel together — a fact
# about all of its members at once that no member's own record carries. That is why the
# class is `publish: internal-hard` alongside the person store rather than `internal`, and
# it is why this group's severity is read beside U's rather than below it.
#
# Every check-ignore call below takes the same modifiers as U's — -c core.ignorecase=false,
# -q, and --no-index where the subject is or may be tracked — so a reader comparing an arm
# here against its U counterpart is comparing subjects, not spellings. The ignorecase pin
# is not decoration: it is `true` on a macOS working copy and `false` on the Linux CI
# runner, and without it a case-altered negation (!/groups/readme.md) reads green on the
# host a human would break it on.
#
# The two probe-design rules U learned the hard way are INHERITED HERE RATHER THAN
# REDISCOVERED, and both shape the arms below:
#   (1) THE SUBJECT SET SPANS MORE THAN ONE EXTENSION. An ignore rule can be broken by
#       narrowing as well as by removal, and a group whose every probe path ends in .md
#       cannot see a narrowing. V2 and V2b are that pair.
#   (2) A CONTROL'S INPUT IS NEVER GOVERNED BY THE RULE UNDER TEST. V0-CTL probes .env and
#       V3 probes an untracked synthetic, both outside /groups/, so a store-rule change
#       moves the subject arms and leaves the controls alone.
if git -C "$HERE/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then

  # V0-CTL (MUST FIRE) — the instrument, before any verdict is read from it. V4 and V5
  # both PASS on "not ignored", so a form that silently answered "not ignored" for every
  # input would show as two green arms. This is the one input that must come back IGNORED,
  # and its subject is deliberately NOT a groups/ path: .env is ignored by the unrelated
  # Environment block at the foot of the ignore file, outside all four guarded stores, so
  # no mutation of any store rule can move it.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index ".env"; then
    PASS "V0-CTL: MUST FIRE — the --no-index form returns IGNORED for .env, a path ignored by a rule none of the store groups touch, so V4/V5's NOT-IGNORED verdicts below are measurements rather than a form that cannot say otherwise"
  else
    FAIL "V0-CTL: MUST FIRE — the --no-index form called .env NOT ignored. .env is ignored by a rule independent of every store guard, so this is the instrument failing and not a store regression; every V arm reading that form is a broken probe and none of their verdicts can be trusted"
  fi

  # V1 (positive) — the signpost ships. Trackedness, not ignore-state: a tracked file
  # bypasses the ignore rules entirely, so ls-files is the unambiguous test. (K1/Q1/U1)
  if git -C "$HERE/.." ls-files --error-unmatch groups/README.md >/dev/null 2>&1; then
    PASS "V1: groups/README.md is tracked (the signpost ships in a fresh clone)"
  else
    FAIL "V1: groups/README.md is NOT tracked — the store's signpost is absent from a fresh clone"
  fi

  # V2 (negative — the limb that matters). Probes at the DEEPEST shape the store admits.
  # check-ignore needs no file on disk, so no synthetic group record is ever written.
  # -q, NOT -v: verbose exits 0 on a NEGATION match too, inverting the verdict.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "groups/grp-zzzz-probe.md"; then
    PASS "V2: a synthetic groups/grp-<token>.md is still git-ignored"
  else
    FAIL "V2: GROUP RECORDS ARE NO LONGER IGNORED — the ignore file stopped guarding groups/ contents, and a group record names which people travel together"
  fi

  # V2b (negative — the SUFFIX limb). V2 alone cannot see a narrowing, only a removal.
  # Every other probe path in this group ends in .md — V4's signpost and V5's derived
  # witness — so rewriting /groups/* to /groups/*.md would leave the whole group green
  # while making every non-markdown file in the store trackable. A group store is a
  # plausible home for an exported roster or a scanned list, and a narrowing that reads as
  # tidying is exactly the "simplification" the ignore-file comment warns against. It is a
  # second probe path, not a second rule — V2 and V2b fail together on a removal and only
  # V2b fails on a narrowing, which is what makes the pair discriminating.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "groups/grp-zzzz-probe.csv"; then
    PASS "V2b: a synthetic NON-markdown groups/grp-<token>.csv is still git-ignored — the rule guards the store's contents by path, not by extension"
  else
    FAIL "V2b: A NON-MARKDOWN FILE IN THE GROUP STORE IS NOT IGNORED — an exported roster or a list at groups/<record>.csv is committable. Read V2 beside this: V2 green means the rule was NARROWED BY SUFFIX and only non-markdown is exposed; V2 red means the rule is gone entirely"
  fi

  # V3 (control arm) — a zero whose control also returns zero is a broken probe. The
  # subject is UNTRACKED and synthetic, which is load-bearing for the same reason
  # --no-index is on V4: without it, check-ignore short-circuits on the index and answers
  # NOT_IGNORED for any tracked path WITHOUT EVALUATING THE RULES. An untracked path is
  # never short-circuited, so it reaches the same evaluator V2 and V2b use.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "zzv-nonesuch-probe.md"; then
    FAIL "V3: control arm broken — check-ignore calls an untracked, unmatched synthetic path ignored, so it cannot distinguish ignored from not-ignored and V2/V2b are unusable"
  else
    PASS "V3: control arm fires (an untracked, rule-unmatched synthetic path is not ignored) — the rule evaluator V2/V2b read can return NOT_IGNORED, so their verdicts are trustworthy"
  fi

  # V4 (rule-level, not state-level). V1 proves the file is IN THE INDEX, which stays true
  # even if the negation line is deleted — a tracked file bypasses the ignore rules
  # altogether, so V1 and V2 both keep passing while the rule rots. --no-index is
  # LOAD-BEARING (the K4/Q4/U4 falsification). This arm is also the only one that fails on
  # a "simplification" to /groups/ or groups/ (the directory form git cannot re-include
  # through) and on a line-order swap, the ignore file being last-match-wins.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index "groups/README.md"; then
    FAIL "V4: the !/groups/README.md negation is gone or unreachable — the store's signpost survives only because it is already tracked"
  else
    PASS "V4: the negation pattern re-includes groups/README.md (the rule, not just the index, is intact)"
  fi

  # V5 — U5's shape, on this store's witness. The witness is READ FROM the tree rather
  # than spelled here: check-ignore answers for paths that do not exist, so an arm naming
  # a token this file guessed would return "not ignored" for an absent file and pass. AN
  # EMPTY DERIVATION IS A FAILURE, NOT A CLEAN RUN. --no-index is load-bearing here too:
  # the witness is tracked, so the default form short-circuits past the rules and returns
  # "not ignored" under the very widening (**/groups/*) this arm exists to catch.
  V5_WIT="$(git -C "$HERE/.." ls-files 'examples/*/groups/*.md')"
  V5_N="$(printf '%s\n' "$V5_WIT" | grep -c '[^[:space:]]')"
  V5_BAD=0
  while IFS= read -r v5p; do
    [ -n "$v5p" ] || continue
    git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index "$v5p" && V5_BAD=$((V5_BAD+1))
  done <<EOF
$V5_WIT
EOF
  if [ "$V5_N" -eq 0 ]; then
    FAIL "V5: no tracked witness matched examples/*/groups/*.md — the schema names a witness the selector never reaches, and this arm would otherwise report a clean run over an empty set"
  elif [ "$V5_BAD" -eq 0 ]; then
    PASS "V5: all $V5_N tracked example witness record(s) under examples/*/groups/ are NOT ignored — the store rule is rooted, so a same-named directory elsewhere in the tree keeps its tracked contents"
  else
    FAIL "V5: $V5_BAD of $V5_N tracked example witness record(s) are IGNORED — the groups/ rule has been widened (**/groups/* or an unrooted groups/) and the schema's witness has silently left the index"
  fi

else
  SKIP "V: not a git work tree"
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

# ── The pre-0.60.0 parity cells' RECORDER (CIAC-1), installed before group L's first arm ──
#
# Groups L to O pass page after page to verify_publishable_content, directly or through lguard,
# mguard and oguard. M6, after group O, asks of each of those pages that the guard before 0.60.0
# blocked whether the guard as it stands blocks it too. So from here to M6 the guard is wrapped:
# verify_publishable_content is a recorder that calls the production guard, renamed
# pp_real_verify, and keeps its status. While PP_ON=1, and only while every function the guard's
# verdict path reads is byte-identical to the definition this suite sourced and no command it
# runs is shadowed by a function — so a page graded under a stub is skipped and counted rather
# than recorded — it grades the same page again in a subshell through the three legacy readers
# below, discards that run's output, and appends one row to a manifest: the page's basename, the
# trip's, the head's status and the legacy status. It returns the head's status unchanged and
# writes nothing to its caller's streams, so no arm in between reads a different answer. M6e
# puts the production guard back and asserts it. An arm that reads the guard's TEXT while the
# recorder stands in for it reads it through pp_body, which returns the production definition.
#
# THE ORACLE, LABELLED AS SUCH: pp_legacy_pub is strip_to_published_text, and pp_legacy_vis and
# pp_legacy_joi are strip_to_text_blocks and strip_to_joined_text, each copied verbatim from
# v0.59.0, the guard before 0.60.0, with only its name changed. The three programs are frozen;
# TWO OF THEIR INPUTS ARE NOT. Each interpolates _GUARD_BLOCK_TAGS and _GUARD_BLOCK from this
# shell at run time, so a change to either moves this oracle with it, and it stops being
# v0.59.0's. Nothing else in the guard's verdict path differs between v0.59.0 and the head's
# base: _guard_match, nonpublishable_values, _norm_words and _decode_entities carry no changed
# line between the two, so a legacy rc=1 is a page the guard before 0.60.0 blocked.
pp_legacy_pub() { # v0.59.0's strip_to_published_text, verbatim but for its name — frozen; reads _GUARD_BLOCK_TAGS and _GUARD_BLOCK live
  perl -0777 -pe "
    s{<!DOCTYPE[^>]*>}{ ' ' . (\$& =~ tr/\n//cdr) }gie;      # the doctype is machinery
    s/<!--/ /g; s/-->/ /g;                             # drop the delimiters, KEEP the body
    s{<\s*/?\s*($_GUARD_BLOCK_TAGS)\b}{ ' $_GUARD_BLOCK ' . (\$& =~ tr/\n//cdr) }gie;   # block boundary, before tag names go
    s{<\s*/?\s*([A-Za-z][-A-Za-z0-9]*)}{ ' ' . (\$& =~ tr/\n//cdr) }ge;   # the tag NAME (with its \"<\") is machinery
    s{([-A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*}{ ' ' . (\$& =~ tr/\n//cdr) }ge;   # the attribute NAME is machinery; its VALUE stays
  " "$1"
}
pp_legacy_vis() { # v0.59.0's strip_to_text_blocks, verbatim but for its name — frozen; reads _GUARD_BLOCK_TAGS and _GUARD_BLOCK live
  perl -0777 -pe "
    s{<(script|style)\b[^>]*>.*?</\1>}{ \$& =~ tr/\n//cdr }gise;
    s{<\s*/?\s*($_GUARD_BLOCK_TAGS)\b[^>]*>}{ ' $_GUARD_BLOCK ' . (\$& =~ tr/\n//cdr) }gie;
    s{<[^>]+>}{ ' ' . (\$& =~ tr/\n//cdr) }ge;
  " "$1"
}
pp_legacy_joi() { # v0.59.0's strip_to_joined_text, verbatim but for its name — frozen; reads _GUARD_BLOCK_TAGS and _GUARD_BLOCK live
  perl -0777 -pe "
    s{<(script|style)\b[^>]*>.*?</\1>}{ \$& =~ tr/\n//cdr }gise;
    s{<\s*/?\s*($_GUARD_BLOCK_TAGS)\b[^>]*>}{ ' $_GUARD_BLOCK ' . (\$& =~ tr/\n//cdr) }gie;
    s{<[^>\n]+>}{}g;
    s{<[^>]+>}{ ' ' . (\$& =~ tr/\n//cdr) }ge;
  " "$1"
}
# The legacy guard: the guard as it stands, reading the page through the three legacy readers,
# with its fourth arm (ADR-050) reading the legacy published copy as well, so that arm adds nothing
# the guard before 0.60.0 lacked. PP_ON is cleared inside, so a recorder still standing in for the
# guard passes straight through.
pp_legacy_verify() { # <site_html> <trip_dir> -> the legacy guard's status on stdout
  ( PP_ON=0
    strip_to_published_text() { pp_legacy_pub "$1"; }
    strip_to_text_blocks()    { pp_legacy_vis "$1"; }
    strip_to_joined_text()    { pp_legacy_joi "$1"; }
    strip_to_shape_text()     { pp_legacy_pub "$1"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
PP_FNS='strip_to_published_text strip_to_text_blocks strip_to_joined_text strip_to_shape_text _decode_entities _line_sentinels _norm_words _guard_match _guard_arm _guard_words nonpublishable_values'
PP_CMDS='perl awk sed tr head tail grep cat mktemp rm basename'
# shellcheck disable=SC2086 # PP_FNS is a word list by construction
PP_FP="$(declare -f $PP_FNS)"
PP_VPC="$(declare -f verify_publishable_content)"
PP_MAN="$WORK/pp_manifest"; PP_SKIP="$WORK/pp_skipped"; : > "$PP_MAN"; : > "$PP_SKIP"
pp_record() { # <site_html> <trip_dir> <head status> -> one manifest row, or one skip
  local c
  for c in $PP_CMDS; do
    if declare -F "$c" >/dev/null 2>&1; then printf 'shadowed %s\n' "$c" >> "$PP_SKIP"; return 0; fi
  done
  # shellcheck disable=SC2086 # PP_FNS is a word list by construction
  if [ "$(declare -f $PP_FNS)" != "$PP_FP" ]; then printf 'stubbed\n' >> "$PP_SKIP"; return 0; fi
  printf '%s|%s|%s|%s\n' "${1##*/}" "${2##*/}" "$3" "$(pp_legacy_verify "$1" "$2")" >> "$PP_MAN"
}
pp_body() { # <function> -> its definition as the publish script wrote it: the production guard's while the recorder stands in for it
  if [ "$1" = verify_publishable_content ] && declare -F pp_real_verify >/dev/null 2>&1; then
    declare -f pp_real_verify | sed '1s/^pp_real_verify/verify_publishable_content/'
  else
    declare -f "$1"
  fi
}
eval "$(printf '%s\n' "$PP_VPC" | sed '1s/^verify_publishable_content/pp_real_verify/')"
verify_publishable_content() { # the RECORDER: the production guard's status, recorded beside the legacy guard's
  local pp_rc=0
  pp_real_verify "$@" || pp_rc=$?
  if [ "${PP_ON:-0}" -eq 1 ]; then pp_record "${1:-}" "${2:-}" "$pp_rc"; fi
  return "$pp_rc"
}
PP_ON=1

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
lgline="$(printf '%s\n' "$lbody" | grep -n 'verify_publishable_content' | awk 'NR == 1' | cut -d: -f1)"
lcline="$(printf '%s\n' "$lbody" | grep -nF 'cp "$site_html"'           | awk 'NR == 1' | cut -d: -f1)"
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
# THE PREDICATE SIDE IS ENUMERATED BY NAME, AND THAT IS THIS CASE'S ONE BLIND SPOT.
# The SELECTORS are derived; the FUNCTIONS graded against them are a list, so a predicate
# added to the publish script and not added here is an unguarded second home BY OMISSION
# -- L8 would stay green while the literal it exists to forbid sat in a function it never
# looked at. #550's verify_summary_content is the first addition; its projection helper is
# named too, because a selector could as easily be hardcoded into a stripper as into a
# matcher. l8absent below is what keeps the list honest: a name that no longer resolves
# contributes a silent zero, which reads exactly like compliance.
#
# NOTE the polarity flip against the pre-re-key form of this case, which required
# `lsrc > 0` — the class source holding literals was the property it asserted. That form
# is structurally incapable of passing now, which is why it was rewritten in the same
# commit as the re-key rather than after it.
l8sel="$(_guard_declared_selectors)"
l8n="$(printf '%s\n' "$l8sel" | grep -c .)"
# Every function that must hold ZERO selectors. Two predicates, the projection the summary
# predicate adds, and the two helpers every arm of both runs through: an arm's stages moved out
# of the predicates' bodies into those two, and a selector could be hardcoded there as easily.
L8_PREDICATES='verify_publishable_content verify_summary_content strip_md_to_text_blocks _guard_arm _guard_words'
l8absent=""
# Each body is read through pp_body, so the guard graded is the production one and not the
# parity cells' recorder standing in for it from group L to M6.
for l8f in $L8_PREDICATES; do
  pp_body "$l8f" >/dev/null 2>&1 || l8absent="$l8absent$l8f "
done
l8pred=0; l8src=0
while IFS= read -r l8s; do
  [ -n "$l8s" ] || continue
  for l8f in $L8_PREDICATES; do
    l8pred=$(( l8pred + $(pp_body "$l8f" | grep -cF -- "$l8s") ))
  done
  l8src=$((  l8src  + $(declare -f nonpublishable_values | grep -cF -- "$l8s") ))
done <<EOF
$l8sel
EOF
if [ "$l8n" -gt 0 ] && [ -z "$l8absent" ] && [ "$l8pred" -eq 0 ] && [ "$l8src" -eq 0 ]; then
  PASS "L8: the class has ONE home — the declaration carries all $l8n selectors while none of the graded predicates ($L8_PREDICATES) and not the class source holds a copy; every graded name resolves, and the control arm fires"
else
  FAIL "L8: the one-home seam is gone or the probe is broken (declaration=$l8n predicate=$l8pred source=$l8src unresolved='${l8absent:-none}')"
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

# L10c — the SIXTH fail-closed path a third time, for a row that PARSES but is never
# QUERIED. L10 covers an absent declaration and L10b a partial read; this covers the case
# where every row is well-formed and one names a (limb, artifact-scope) pair the evaluator
# does not ask about. Such a row is accepted, selected by nothing, and observed by nobody,
# so it reads as a member of the class while guarding none of it.
#
# This is L10b's defect one column over, and it is the DOCUMENTED extension path: § 5.6
# presents both columns as open domains while the evaluator matches literal strings. Four
# mutations were shown silently inert before this case existed — a typo'd artifact-scope,
# a typo'd limb, a limb outside the pair, and a glob scope. Control arm is L9b: the
# identical trip and render return 0 while every row is queried.
LDECLQ="$WORK/l_decl_unqueried.md"
_guard_declared_rows | awk 'NR == 1 { print $1, $2, $3 "x", $4; next } { print }' | ldecl_write "$LDECLQ"
_GUARD_DECLARATION="$LDECLQ"
lguard "$LDECLR" "$LDECLT"
l10c="$LRC"
_GUARD_DECLARATION="$L8DECL_REAL"
if [ "$l10c" -eq 2 ] && [ "$l9b" -eq 0 ]; then
  PASS "L10c: a well-formed row naming an artifact-scope the guard never queries aborts (rc=2) while the same trip publishes (rc=0) once every row is queried — a row that guards nothing is UNDETERMINED, not a narrower class"
else
  FAIL "L10c: an unqueried declaration row was not fail-closed (unqueried=$l10c, queried=$l9b) — a well-formed row can silently guard nothing"
fi

# L10d — the SHIPPED declaration is FULLY QUERIED. L10c proves the mechanism fires on a
# mutated declaration; this asserts the property on the real one, which is a different
# claim. Today the failure it names is caught only INCIDENTALLY: a shipped row the
# evaluator does not query aborts everything, so L9b and thirty other arms go red at once
# and a reader has to work backwards from the wreckage to the cause.
#
# THIS IS THE DURABLE GUARD AGAINST A COUPLING RECURRING. Adding an artifact scope to the
# fence and widening the evaluator that queries it are one indivisible change, and a later
# release may split them across cards that never read each other's output. When that
# happens this arm names the defect in one line instead of leaving it to be inferred.
# Deliberately built from the guard's own accessors, so this file still holds no copy of
# the fence name, the heading, any row or any artifact-scope literal.
l10dn="$(_guard_declared_rows | awk 'NF { c++ } END { print c + 0 }')"
l10dq="$(_guard_declared_rows | awk -v m="$_GUARD_DECL_ARTIFACT_MODEL" -v p="$_GUARD_DECL_ARTIFACT_PROFILE" \
                                   -v r="$_GUARD_DECL_ARTIFACT_PERSON" '
    ($1 == "entry" && $3 == m) || ($1 == "field" && $3 == m) || ($1 == "field" && $3 == p) ||
    ($1 == "field" && $3 == r) { c++ }
    END { print c + 0 }')"
if [ "$l10dn" -gt 0 ] && [ "$l10dq" -eq "$l10dn" ] && [ "$l9b" -eq 0 ]; then
  PASS "L10d: every one of the $l10dn shipped declaration rows names a (limb, artifact-scope) pair this guard actually queries — the fence and the evaluator have not been separated"
else
  FAIL "L10d: the shipped declaration carries $l10dn rows but only $l10dq are queried — a row that guards nothing shipped, and every --plaintext publish now aborts (control l9b=$l9b)"
fi

# L10e — the erasure tombstone is NOT a declared selector, and never becomes one.
# The tombstone is the one token in the engine that is mark-shaped, REQUIRED to be present
# in publish-bound artifacts, and designed to carry no personal information. Declaring it
# would invert the guard on it: a guarded token guaranteed present in the render is a HIT
# on every subsequent publish of any trip carrying one, permanently.
#
# It is authored while the corpus holds ZERO occurrences of the token, which is the only
# time it is cheap; and it is graded against the DECLARED SELECTOR SET rather than a text
# search of the file, because the fence's own reader is what decides whether a row is a
# selector. The control arm is the must-fire half: the shipped fence really does carry a
# selector, so an empty selector set cannot pass this as a vacuous zero.
l10esel="$(_guard_declared_selectors)"
l10emark="$(grep -cF "ERASED" <<<"$l10esel" || true)"
l10ectl="$(awk 'NF { c++ } END { print c + 0 }' <<<"$l10esel")"
# The must-fire control is a NAMED MEMBER, not a count. A count proves only that the
# reader returned something; it cannot tell the declared selector set from any other
# non-empty output. A mis-aimed reader yielding, say, section headings satisfies
# l10ectl > 0 and reports zero tombstone hits, so this arm would pass green over
# entirely the wrong population — the same count-is-not-a-set fault this suite has
# booked elsewhere. Passport is asserted because it is a shipped selector on all three
# artifact scopes: if the reader is aimed correctly it is present, and if it is aimed
# anywhere else it is not.
l10ehit="$(grep -cFx "Passport" <<<"$l10esel" || true)"
if [ "$l10emark" -eq 0 ] && [ "$l10ectl" -gt 0 ] && [ "$l10ehit" -ge 1 ]; then
  PASS "L10e: the erasure tombstone is not among the $l10ectl declared selectors, and the reader is aimed (the known selector Passport is present) — a privacy mark that must be published is the exact inverse of a non-publishable selector, and it has not been declared as one"
elif [ "$l10ehit" -eq 0 ]; then
  FAIL "L10e: CONTROL DID NOT FIRE — the known selector Passport is absent from the declared set ($l10ectl selector(s) read), so this arm is reading the wrong population and its tombstone verdict means nothing"
else
  FAIL "L10e: the erasure tombstone appears in the declared selector set ($l10emark hit(s) over $l10ectl selectors) — every subsequent publish of any trip carrying a tombstone will abort, permanently"
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

# L11b — THE ENTRY-LIMB BACKSTOP, NOW UNCONDITIONAL. RE-AUTHORED: THIS ARM WAS INVERTED.
#
# It used to pin the opposite verdict, and that was correct of the code it measured. The
# orphaned-mark backstop asked `sawmark && tprecs == 0`, and `tprecs` is a FILE-WIDE
# counter, so one entry producing one record absolved every other mark in the file: the
# suppressed mark aborted when it was alone (rc=2) and was SWALLOWED (rc=0) the moment any
# unrelated entry parsed. This arm recorded that as the shipped shape — "the backstop is
# conditional, and this pins the condition" — with the note that a slice closing it would
# need a failing target to flip. This is that slice, and this is that flip.
#
# The backstop now asks the question per mark rather than per file: a mark resolves when
# the entry it sits in produced a class record, and a mark sitting in no entry — here,
# under a reserved heading — resolves never. So BOTH arms are now rc=2 and the second one
# is the closure. Graded together and differently: the first arm alone would pass on a
# guard that aborts everything, and the second alone cannot tell a closure from an
# always-abort. The control is L11c/L11d plus group O5b, which still publish.
#
# READ THIS AS A CLOSURE, NOT AS A NEW MEASUREMENT. The two fixtures still differ in
# exactly one thing — whether another entry produced a record — and the point of the pair
# is now that the difference no longer changes the verdict.
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
if [ "$l11e1" -eq 2 ] && [ "$l11e2" -eq 2 ]; then
  PASS "L11b: a suppressed ENTRY mark aborts as UNDETERMINED (rc=$l11e1) when it is the only one AND (rc=$l11e2) alongside another entry that produced records — the backstop is no longer conditional on what the REST of the file parsed, and an orphaned mark can no longer be swallowed by an unrelated entry"
else
  FAIL "L11b: the orphaned-mark backstop is not in the closed shape (alone=$l11e1 with-other-record=$l11e2) — a second arm reading 0 is the file-wide tprecs fail-open returning; re-read the END block before trusting either verdict"
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
# L12 — EVERY declared field selector on the derived model is actually guarded, and a
# label that merely BEGINS with one is not.
#
# This case names no selector. It reads the field-limb selectors for the model class off
# the declaration through the guard's own accessor and its own constants, so it grades
# whatever § 5.6 says at the moment it runs rather than whatever it said when it was
# written. A row added to the fence is graded by this case on the next run with no edit
# here; a row removed leaves the rows that remain graded, and a declaration that yields
# no selectors at all is refused rather than passed.
#
# Two arms per selector, and the second is the point:
#   subject — the value under the declared label aborts (rc=1) and the record names
#             member + selector without echoing the value (L1b's rule, per selector).
#   R-5     — the IDENTICAL value under a label that merely begins with that selector
#             publishes (rc=0). field_hit is prefix-THEN-colon, so `<selector> foo:` is
#             not `<selector>:` and nothing matches it. That is a fail-OPEN direction on
#             a privacy fence, and it is the reason a requirement set gets its own
#             declared selector rather than being hung off an existing one under a
#             longer label. Pinned as measured behaviour, not endorsed.
#
# The selector count is asserted at one or more — a zero-population assertion, and not a
# claim about how large the class is. At zero selectors the loop never runs and every
# equality below is satisfied by 0 == 0, so a collapsed or unreadable selector list would
# otherwise pass this case having graded nothing. One is the whole of what that rationale
# needs: a higher floor re-encodes whatever the class happens to hold today, and fails
# both arms outright the moment the declaration legitimately narrows.
L12SEL="$(_guard_limb_selectors field "$_GUARD_DECL_ARTIFACT_MODEL")"
l12n=0; l12hit=0; l12named=0; l12open=0
for l12s in $L12SEL; do
  l12n=$((l12n + 1))
  L12T="$WORK/l12_$l12n"; mkdir -p "$L12T/outputs"
  L12R="$WORK/l12_$l12n.html"
  l12val="Kestrel Vault 41 clearance $l12n"
  # Render first, then the model, so the freshness gate reads the projection as at
  # least as new as the render (the L9 idiom).
  lrender "$L12R" "Holding note: $l12val is filed with the courier before departure."
  printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **%s:** %s\n' "$l12s" "$l12val" \
    > "$L12T/outputs/traveler-model.md"
  lguard "$L12R" "$L12T"
  [ "$LRC" -eq 1 ] && l12hit=$((l12hit + 1))
  if grep -qF "entry 1 / $l12s" "$LOUT" && ! grep -qF "$l12val" "$LOUT"; then
    l12named=$((l12named + 1))
  fi
  printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **%s requirements:** %s\n' "$l12s" "$l12val" \
    > "$L12T/outputs/traveler-model.md"
  lguard "$L12R" "$L12T"
  [ "$LRC" -eq 0 ] && l12open=$((l12open + 1))
done
if [ "$l12n" -ge 1 ] && [ "$l12hit" -eq "$l12n" ] && [ "$l12named" -eq "$l12n" ]; then
  PASS "L12: all $l12n declared field selectors on the model class abort the publish (rc=1) and name member + selector without echoing the value — the case reads the selectors off the declaration and hardcodes none"
else
  FAIL "L12: a declared field selector was not guarded (selectors=$l12n aborted=$l12hit named=$l12named) — either the class is narrower than the declaration or the probe read no selectors at all"
fi
if [ "$l12n" -ge 1 ] && [ "$l12open" -eq "$l12n" ]; then
  PASS "L12b: for all $l12n selectors, the identical value under a label that merely BEGINS with the selector publishes (rc=0) — field_hit is prefix-then-colon, so a longer label is UNGUARDED. Measured, and the reason a new requirement set owes its own declared selector rather than a longer label over an existing one"
else
  FAIL "L12b: the prefix-then-colon shape changed (selectors=$l12n published=$l12open) — re-read field_hit before trusting L12's verdict or any claim that a longer label is covered"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L13 — THE ABORT NAMES A POSITION IN THE ARTIFACT THE OPERATOR HAS TO EDIT.
#
# The shipped abort named a coordinate in the MODEL. The model and the render are two
# independent artifacts and the guard re-reads both, so the discoverable fix — delete the
# record the abort names — clears the abort and leaves the value in the published file.
# The operator resolves the finding by deleting the evidence for it. L13e asserts that
# consequence directly rather than inferring it from the message text.
#
# L13a is the case that makes the rest mean anything. "The message contains a colon and a
# number" passes against a hardcoded string; a locator is only a locator if it MOVES with
# what it locates, so the value is planted at three distinct source lines and each must be
# reported. A constant emitter passes a presence arm and fails this one.
#
# L13b is the case that rejected the obvious implementation. Injecting line sentinels into
# the raw file and stripping afterwards is the natural design and it under-counts: a
# multi-line tag swallows the sentinels inside it, a <script> deletion swallows every
# sentinel in the block, and the reported line comes out plausibly, consistently, silently
# too small. A line that is merely CLOSE is a FAIL here.
# ─────────────────────────────────────────────────────────────────────────────

# Plants a paragraph on an EXACT source line. Line 1 opens the document; lines 2..N-1 are
# filler; line N carries the plant; the trailing lines keep every render above the
# 20-word degraded-extraction floor, so no case here can abort for the wrong reason.
lplant() { # <out_file> <target_line> <paragraph text>
  local out="$1" want="$2" i=2
  printf '%s\n' '<!DOCTYPE html><html><head><title>Lisbon Trip</title></head><body>' > "$out"
  while [ "$i" -lt "$want" ]; do
    printf '<p>Filler %d: the covered market, the harbour museum, the hill gardens.</p>\n' "$i" >> "$out"
    i=$((i+1))
  done
  printf '<p>%s</p>\n' "$3" >> "$out"
  printf '%s\n' '<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>' >> "$out"
  printf '%s\n' '<p>Pacing: a slow start and no fixed plan before ten in the morning on any day.</p>' >> "$out"
  printf '%s\n' '</body></html>' >> "$out"
}

# The three readers of the captured abort. Each returns non-zero when the shape it reads
# is absent, and that absence is itself asserted below rather than defaulted away.
lline() { local ln; while IFS= read -r ln; do
  if [[ "$ln" =~ reached\ the\ published\ file\ at\ .*:([0-9?]+)\ \( ]]; then printf '%s' "${BASH_REMATCH[1]}"; return 0; fi
done < "$LOUT"; return 1; }
lprj() { local ln; while IFS= read -r ln; do
  if [[ "$ln" =~ reached\ the\ published\ file\ at\ .*:[0-9?]+\ \((.*)\)\. ]]; then printf '%s' "${BASH_REMATCH[1]}"; return 0; fi
done < "$LOUT"; return 1; }
# Any <file>.html:<digits> or <file>.md:<digits> shape anywhere in the captured stderr.
# Read in BOTH directions: a HIT must produce one, a non-HIT must not.
lhasloc() { local ln; while IFS= read -r ln; do
  [[ "$ln" =~ [^[:space:]]+\.(html|md):[0-9]+ ]] && return 0
done < "$LOUT"; return 1; }

l13val="Border note: carry your Ruritanian passport, valid to 2033, at all times."

# L13a — the locator TRACKS (three distinct positions, so a constant fails).
l13ok=1; l13seen=""
for l13n in 3 7 11; do
  lplant "$WORK/l13_$l13n.html" "$l13n" "$l13val"
  lguard "$WORK/l13_$l13n.html"
  l13got="$(lline)" || l13got="NONE"
  l13seen="$l13seen ${l13n}->${l13got}"
  { [ "$LRC" -eq 1 ] && [ "$l13got" = "$l13n" ]; } || l13ok=0
done
if [ "$l13ok" -eq 1 ]; then
  PASS "L13a: the render-side locator TRACKS the planted line (planted->reported:${l13seen}), rc=1 at each. Three distinct positions, so a constant emitter fails this case — a locator that does not move is not locating"
else
  FAIL "L13a: the reported line did not track the planted line (planted->reported:${l13seen}, last rc=$LRC). A locator that is merely PRESENT proves nothing; this is the arm that distinguishes the two"
fi

# L13b — the line map survives the two transforms that destroy lines. Exact, not close.
L13MT="$WORK/l13_multiline.html"
cat > "$L13MT" <<HTML
<!DOCTYPE html><html><head><title>Lisbon Trip</title></head><body>
<p>Filler 2: the covered market, the harbour museum, the hill gardens.</p>
<div
   class="multi
   line tag">
<p>Filler 6: a long lunch by the water and the gardens in the late afternoon.</p>
<p>$l13val</p>
</div>
<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>
</body></html>
HTML
lguard "$L13MT"; l13mrc="$LRC"; l13mline="$(lline)" || l13mline="NONE"
L13SC="$WORK/l13_script.html"
cat > "$L13SC" <<HTML
<!DOCTYPE html><html><head><title>Lisbon Trip</title></head><body>
<p>Filler 2: the covered market, the harbour museum, the hill gardens.</p>
<script>
var a = "a decoy line inside the script body";
var b = "another decoy line inside the script body";
</script>
<p>$l13val</p>
<p>Packing list: passport, adapter, light rain shell, comfortable shoes for cobbles.</p>
</body></html>
HTML
lguard "$L13SC"; l13src="$LRC"; l13sline="$(lline)" || l13sline="NONE"
if [ "$l13mrc" -eq 1 ] && [ "$l13mline" = "7" ] && [ "$l13src" -eq 1 ] && [ "$l13sline" = "7" ]; then
  PASS "L13b: the line map is lossless on both destroying transforms — a plant at true line 7 behind a multi-line tag reports 7, and behind a <script> block reports 7. The projections re-emit the newlines they consume, so neither a tag spanning lines nor a deleted block shifts the count"
else
  FAIL "L13b: the line map is not lossless (multi-line-tag: rc=$l13mrc reported=$l13mline, want 7; script-block: rc=$l13src reported=$l13sline, want 7). A reported line that is merely CLOSE is the pre-fix behaviour — plausible, consistent, and wrong"
fi

# L13c — both projections are located AND correctly attributed. A value only in a
# comment or only in an attribute value is invisible to the visible arm by construction,
# so the projection tag is what tells the operator whether to look at prose or at markup.
L13CM="$WORK/l13_comment.html"
lplant "$L13CM" 5 "nothing of interest on this line at all"
# rewrite line 5 as a comment carrying the value
{ head -4 "$L13CM"; printf '<!-- %s -->\n' "$l13val"; tail -n +6 "$L13CM"; } > "$L13CM.tmp" && mv "$L13CM.tmp" "$L13CM"
lguard "$L13CM"; l13crc="$LRC"; l13cline="$(lline)" || l13cline="NONE"; l13cprj="$(lprj)" || l13cprj="NONE"
L13AL="$WORK/l13_alt.html"
lplant "$L13AL" 5 "nothing of interest on this line at all"
{ head -4 "$L13AL"; printf '<img src="x.png" alt="%s">\n' "$l13val"; tail -n +6 "$L13AL"; } > "$L13AL.tmp" && mv "$L13AL.tmp" "$L13AL"
lguard "$L13AL"; l13arc="$LRC"; l13aline="$(lline)" || l13aline="NONE"; l13aprj="$(lprj)" || l13aprj="NONE"
lplant "$WORK/l13_vis.html" 5 "$l13val"; lguard "$WORK/l13_vis.html"
l13vrc="$LRC"; l13vprj="$(lprj)" || l13vprj="NONE"
if [ "$l13crc" -eq 1 ] && [ "$l13cline" = "5" ] && [ "$l13cprj" != "visible text" ] && [ "$l13cprj" != "NONE" ] \
   && [ "$l13arc" -eq 1 ] && [ "$l13aline" = "5" ] && [ "$l13aprj" != "visible text" ] && [ "$l13aprj" != "NONE" ] \
   && [ "$l13vrc" -eq 1 ] && [ "$l13vprj" = "visible text" ]; then
  PASS "L13c: both projections are located and attributed — an HTML comment at line 5 reports 5 as '$l13cprj', an img alt at line 5 reports 5 as '$l13aprj', and a visible-text plant reports 'visible text'. The tag is a structural fact carrying no class content, and it tells the operator whether to look at prose or at markup"
else
  FAIL "L13c: a projection was mislocated or misattributed (comment: rc=$l13crc line=$l13cline proj='$l13cprj'; alt: rc=$l13arc line=$l13aline proj='$l13aprj'; visible: rc=$l13vrc proj='$l13vprj')"
fi

# L13d — the non-HIT arms synthesise NOTHING, graded by absence. Six of the eight arms
# fire when nothing matched: there is no render position and none may be invented. The
# HIT arm is the control — without it, "no locator found" would pass against a guard that
# had stopped emitting locators entirely.
lguard "$WORK/l13_7.html";  lhasloc && l13hit_loc=1 || l13hit_loc=0     # HIT — must have one
lguard "$LCLEAN";           l13cln_rc="$LRC"; lhasloc && l13cln_loc=1 || l13cln_loc=0
lguard "$LCLEAN" "$LSUB";   l13sub_rc="$LRC"; lhasloc && l13sub_loc=1 || l13sub_loc=0
if [ "$l13hit_loc" -eq 1 ] && [ "$l13cln_rc" -eq 0 ] && [ "$l13cln_loc" -eq 0 ] \
   && [ "$l13sub_rc" -eq 2 ] && [ "$l13sub_loc" -eq 0 ]; then
  PASS "L13d: no non-HIT arm synthesises a position — a clean pass (rc=0) and a below-the-floor UNDETERMINED (rc=2) each emit no <path>:<line>, while the HIT arm on the same fixture set does. The zero is a measurement: the control arm fired"
else
  FAIL "L13d: a position was synthesised where none exists, or the control did not fire (hit_has_locator=$l13hit_loc clean rc=$l13cln_rc locator=$l13cln_loc subfloor rc=$l13sub_rc locator=$l13sub_loc)"
fi

# L13e — THE USER CONSEQUENCE, ASSERTED AS AN OBSERVATION RATHER THAN READ OFF THE
# MESSAGE. Delete the model record the abort points at, re-run: the guard now passes, and
# the render is byte-identical and still carries the value. That is the whole reason the
# leading coordinate had to move to the render.
L13TD="$WORK/l13-nopass"; mkdir -p "$L13TD/outputs"
sed '/^- Passport: Ruritanian, valid to 2033$/d' "$LTD/outputs/traveler-model.md" > "$L13TD/outputs/traveler-model.md"
L13H="$WORK/l13_ac3.html"; lplant "$L13H" 7 "$l13val"
l13sum1="$(cksum < "$L13H")"
lguard "$L13H";          l13rc1="$LRC"
lguard "$L13H" "$L13TD"; l13rc2="$LRC"
l13sum2="$(cksum < "$L13H")"
l13still=0; case "$(cat "$L13H")" in *Ruritanian*) l13still=1 ;; esac
l13del=0; case "$(cat "$L13TD/outputs/traveler-model.md")" in *"valid to 2033"*) ;; *) l13del=1 ;; esac
if [ "$l13del" -eq 1 ] && [ "$l13rc1" -eq 1 ] && [ "$l13rc2" -eq 0 ] && [ "$l13sum1" = "$l13sum2" ] && [ "$l13still" -eq 1 ]; then
  PASS "L13e: deleting the model record CLEARS THE ABORT WITHOUT CLEARING THE LEAK — rc goes 1 to 0 while the render is byte-identical and still carries the value. This is the consequence the abort now names in words, asserted here as an observation rather than inferred from the message text"
else
  FAIL "L13e: the AC-3 consequence did not reproduce (record deleted=$l13del rc before=$l13rc1 after=$l13rc2 render unchanged=$([ "$l13sum1" = "$l13sum2" ] && echo yes || echo no) value still present=$l13still)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L14 — THE DATA-ROOT SEAM ON STEP 2 OF THE STORE-ROOT RULE.
#
# Step 1 of the rule resolves a per-trip people/ store; step 2 falls back to a root-level
# one. That fallback used to resolve against $_GUARD_REPO_ROOT, which is BASH_SOURCE-
# derived and correct for engine assets and WRONG for operator data: once this engine is
# installed, its own people/ is a record-free skeleton of one tracked README, so step 2
# found a directory that exists and a record that does not — `return 2`, UNDETERMINED,
# which this script's own header calls aborting every publish of that trip forever.
#
# The seam is $_GUARD_DATA_ROOT, set only by an explicit --data-root argument and never
# from the environment, for the reason the declaration block states: an environment
# default on a fail-closed control is a fail-open surface.
#
# THE TWO ARMS ARE THE SAME TRIP, THE SAME RENDER AND THE SAME REFERENCE, differing only
# in the root. That is what makes a verdict change attributable to the root and to
# nothing else — the L9a/L9b idiom, applied to the other global this file re-points.
L14SAVE="$_GUARD_DATA_ROOT"
L14T="$WORK/l14_trip"; mkdir -p "$L14T/outputs" "$L14T/travelers"
L14R="$WORK/l14.html"
L14REAL="$WORK/l14_data";     mkdir -p "$L14REAL/people"
L14SKEL="$WORK/l14_skeleton"; mkdir -p "$L14SKEL/people"
L14KEY="psn-ab12"
# Written in dependency order so the freshness gates read the projection as at least as
# new as every source it projects: render, then the referenced record, then the profile,
# then the model last. Ties do not fire (_is_stale is a strict >).
lrender "$L14R" "Meeting point: the fountain by the south gate at nine, bags already dropped."
printf -- '---\ntitle: Rowan\n---\n\n# Rowan\n\n- **Diet:** no shellfish\n' > "$L14REAL/people/$L14KEY.md"
printf -- '# The person store\n\nOne file per person. This README is the only tracked file here.\n' > "$L14SKEL/people/README.md"
printf -- '---\nperson: %s\n---\n\n# Rowan\n' "$L14KEY" > "$L14T/travelers/rowan.md"
printf -- '# Traveler Model [DERIVED]\n\n## Rowan\n- **Diet:** no shellfish\n' > "$L14T/outputs/traveler-model.md"

# L14c — fixture integrity, graded FIRST. Without it the arms below prove nothing: a 2
# from the skeleton root is only about the ROOT if the record is genuinely present under
# the other one and genuinely absent under this one, and if the trip carries no per-trip
# store that would let step 1 answer before step 2 is reached at all.
if [ -f "$L14REAL/people/$L14KEY.md" ] && [ ! -e "$L14SKEL/people/$L14KEY.md" ] \
   && [ -d "$L14SKEL/people" ] && [ ! -d "$L14T/people" ]; then
  PASS "L14c: fixture integrity — the referenced record exists under one data root and not the other, the skeleton root's people/ is a real readable directory holding no record (which is exactly the installed engine's shape), and the trip carries no per-trip store, so step 2 is the step under test"
else
  FAIL "L14c: the data-root fixture is not set up as claimed — L14a and L14b would prove nothing"
fi

_GUARD_DATA_ROOT="$L14REAL"
lguard "$L14R" "$L14T"
l14a="$LRC"
_GUARD_DATA_ROOT="$L14SKEL"
lguard "$L14R" "$L14T"
l14b="$LRC"
_GUARD_DATA_ROOT="$L14SAVE"

if [ "$l14a" -eq 0 ]; then
  PASS "L14a: with the data root naming a store that HOLDS the referenced record, the publish proceeds (rc=0) — step 2 resolves through the seam"
else
  FAIL "L14a: a resolvable person reference did not publish (rc=$l14a) — either the seam is not wired to step 2 or the fixture carries an unrelated finding, and L14b's 2 would then be unattributable"
fi
if [ "$l14b" -eq 2 ] && [ "$l14a" -eq 0 ]; then
  PASS "L14b: MUST-FIRE — the SAME trip and the SAME render, with the data root pointed at a record-free store skeleton, aborts UNDETERMINED (rc=2) while the identical run against the real store returns 0. The verdict follows the data root, so the seam is delivered rather than described — and this is the exact state an installed engine is in before it is told where the operator store lives"
else
  FAIL "L14b: the verdict did not follow the data root (real=$l14a skeleton=$l14b) — a step-2 fallback that ignores the seam reads the engine's own skeleton after install, which returns 2 on every referencing trip"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L15 — THE SAME SEAM ON THE <trip-dir> ARGUMENT, driven as a SUBPROCESS.
#
# L14 grades the seam on the person store by calling a function with the root re-pointed.
# That shape cannot see this defect, and no other arm here could either: every one sources
# the script and hands cmd_* an ABSOLUTE $WORK path, so neither main()'s parse of
# --data-root nor a RELATIVE <trip-dir> in a foreign working directory was ever exercised.
# After an install that is the only shape a verb produces — `update trips/<slug>` and
# `unpublish trips/<slug> --disable-pages-only`, each with --data-root appended, from
# whatever directory the session has open — and it died "no such trip dir" everywhere but
# the data root. So these arms EXECUTE the script, from a working directory that is not the
# data root, and read what it names.
#
# THE DECOY IS THE DISCRIMINATOR. One working directory holds its own trips/<slug> whose
# .publish-slug names a different repo. A resolver that ignores the flag names the decoy's
# repo, and so does one that falls back to the working directory when the data root misses
# (L15e). Only a resolver that roots a relative path at the data root, and there alone,
# names the data-root trip's repo. Before resolve_trip_dir the script named the decoy's —
# a takedown reporting a no-op for the wrong repo while the real site stayed up.
#
# Offline, like the rest of L: gh and npx are stub FILES on a PATH prefix local to each run,
# because the subject is a separate process and a shell-function mock would not reach it.
# The gh stub answers the auth and user reads and fails every other call — every repo reads
# absent and every clone is refused — so no arm can create, clone, disable or push anything.
L15DATA="$WORK/l15_data"; L15DECOY="$WORK/l15_decoy_cwd"; L15EMPTY="$WORK/l15_empty_cwd"
L15BIN="$WORK/l15_bin"; L15LOG="$WORK/l15_gh.log"
mkdir -p "$L15DATA/trips/l15-trip/outputs" "$L15DECOY/trips/l15-trip" "$L15DECOY/trips/l15-cwd-only" \
         "$L15EMPTY" "$L15BIN"
printf '# trips\n' > "$L15DATA/trips/README.md"
printf '<!DOCTYPE html><html><head><title>x</title></head><body><h1>Day 1</h1><p>Harbour walk, then the lighthouse.</p></body></html>\n' \
  > "$L15DATA/trips/l15-trip/outputs/l15-trip-travel-site.html"
printf 'l15-dataroot-slug\n' > "$L15DATA/trips/l15-trip/.publish-slug"
printf 'l15-decoy-slug\n'    > "$L15DECOY/trips/l15-trip/.publish-slug"
cat > "$L15BIN/gh" <<L15GH
#!/usr/bin/env bash
printf 'gh %s\n' "\$*" >> "$L15LOG"
case "\${1:-} \${2:-}" in
  'auth status') exit 0 ;;
  'api user')    case "\$*" in *.login*) echo l15-owner ;; *.id*) echo 4242 ;; esac; exit 0 ;;
esac
exit 1
L15GH
printf '#!/usr/bin/env bash\nexit 0\n' > "$L15BIN/npx"
chmod +x "$L15BIN/gh" "$L15BIN/npx"
L15_OUT=""; L15_RC=0; L15_LOGT=""
l15_run() {   # l15_run <stub|bare> <cwd> <args…> — executes the script; sets L15_OUT L15_RC L15_LOGT
  local mode="$1" cwd="$2"; shift 2
  : > "$L15LOG"
  if [ "$mode" = stub ]; then
    L15_OUT="$( cd "$cwd" && PATH="$L15BIN:$PATH" "$SELF_PUBLISH" "$@" </dev/null 2>&1 )"; L15_RC=$?
  else
    L15_OUT="$( cd "$cwd" && "$SELF_PUBLISH" "$@" </dev/null 2>&1 )"; L15_RC=$?
  fi
  L15_LOGT="$(cat "$L15LOG" 2>/dev/null)"
}
l15_has() { case "$1" in *"$2"*) printf 1 ;; *) printf 0 ;; esac; }

# L15c — fixture integrity, graded FIRST, for the reason L14c gives: the arms below mean
# something only if the two trips genuinely coexist under different names, the empty working
# directory genuinely holds no trips/, the cwd-only trip genuinely exists in one place alone,
# and the stubs are really there to be found.
if [ "$(cat "$L15DATA/trips/l15-trip/.publish-slug")" = l15-dataroot-slug ] \
   && [ "$(cat "$L15DECOY/trips/l15-trip/.publish-slug")" = l15-decoy-slug ] \
   && [ ! -e "$L15EMPTY/trips" ] && [ -d "$L15DECOY/trips/l15-cwd-only" ] \
   && [ ! -e "$L15DATA/trips/l15-cwd-only" ] && [ -x "$L15BIN/gh" ] && [ -x "$L15BIN/npx" ] \
   && [ -x "$SELF_PUBLISH" ]; then
  PASS "L15c: fixture integrity — the data root and the decoy working directory each hold a trip of the same name naming a DIFFERENT repo, the empty working directory holds no trips/, one trip exists only in the decoy directory, and the script and both stubs are executable"
else
  FAIL "L15c: the <trip-dir> fixture is not set up as claimed — every L15 arm below would prove nothing"
fi

# L15a — MUST-FIRE: the decommission verb's invocation, from the DECOY directory.
l15_run stub "$L15DECOY" unpublish trips/l15-trip --disable-pages-only --data-root "$L15DATA"
l15a_rc="$L15_RC"; l15a_hit="$(l15_has "$L15_OUT" 'l15-owner/l15-dataroot-slug')"
l15a_decoy="$(l15_has "$L15_OUT$L15_LOGT" 'l15-decoy-slug')"; l15a_view="$(l15_has "$L15_LOGT" 'repo view l15-owner/l15-dataroot-slug')"
if [ "$l15a_rc" -eq 0 ] && [ "$l15a_hit" = 1 ] && [ "$l15a_view" = 1 ] && [ "$l15a_decoy" = 0 ]; then
  PASS "L15a: MUST-FIRE — \`unpublish trips/<slug> --disable-pages-only --data-root <root>\`, EXECUTED from a working directory holding a same-named decoy trip, resolves the trip under the data root: the repo it probes and reports is the data-root trip's (rc=$l15a_rc) and the decoy's name appears nowhere in its output or its gh calls"
else
  FAIL "L15a: the relative <trip-dir> was not rooted at --data-root (rc=$l15a_rc, data-root repo named=$l15a_hit, probed=$l15a_view, decoy named=$l15a_decoy). Output: $L15_OUT"
fi

# L15b — CONTROL: the same command WITHOUT the flag. The default is the working directory,
# unchanged, so this names the decoy — which is also what shows the probe above can tell the
# two trips apart rather than reporting one name whatever it resolved.
l15_run stub "$L15DECOY" unpublish trips/l15-trip --disable-pages-only
l15b_rc="$L15_RC"; l15b_decoy="$(l15_has "$L15_OUT" 'l15-owner/l15-decoy-slug')"; l15b_data="$(l15_has "$L15_OUT$L15_LOGT" 'l15-dataroot-slug')"
if [ "$l15b_rc" -eq 0 ] && [ "$l15b_decoy" = 1 ] && [ "$l15b_data" = 0 ]; then
  PASS "L15b: CONTROL — with no --data-root the same command resolves against the working directory exactly as before the seam and names the decoy's repo (rc=$l15b_rc); the resolver roots only on the flag, never on the variable's engine-root default"
else
  FAIL "L15b: with no --data-root the command did not resolve against the working directory (rc=$l15b_rc, decoy named=$l15b_decoy, data-root named=$l15b_data) — either the flagless default moved or L15a's discrimination proves nothing. Output: $L15_OUT"
fi

# L15d — THE INSTALLED CASE, on the publish verb's invocation: `update` from a working
# directory holding no trips/ at all. The stub refuses the clone, so the run stops at the
# first network step — and the per-trip repo that step names is the proof that the trip was
# found under the data root and carried through preflight, the render, and both guards.
l15_run stub "$L15EMPTY" update trips/l15-trip --data-root "$L15DATA"
l15d_rc="$L15_RC"; l15d_clone="$(l15_has "$L15_OUT" 'per-trip repo l15-owner/l15-dataroot-slug not found')"
l15d_nodir="$(l15_has "$L15_OUT" 'no such trip dir')"; l15d_log="$(l15_has "$L15_LOGT" 'repo clone l15-owner/l15-dataroot-slug')"
if [ "$l15d_rc" -eq 1 ] && [ "$l15d_clone" = 1 ] && [ "$l15d_log" = 1 ] && [ "$l15d_nodir" = 0 ]; then
  PASS "L15d: \`update trips/<slug> --data-root <root>\` EXECUTED from a directory with no trips/ — the shape every installed session has — finds the trip under the data root and reaches the clone of that trip's repo (refused by the stub, rc=$l15d_rc), where it used to die 'no such trip dir' before preflight"
else
  FAIL "L15d: update did not reach the data-root trip's clone (rc=$l15d_rc, clone named=$l15d_clone, clone attempted=$l15d_log, 'no such trip dir'=$l15d_nodir). Output: $L15_OUT"
fi

# L15e — NO FALLBACK. The trip exists only in the working directory. With the flag given it
# must not be found: the refusal names the data root it looked under — never the argument itself,
# which may be a passphrase typed in the trip's place (RV13-omitted) — and gh is never reached.
l15_run stub "$L15DECOY" unpublish trips/l15-cwd-only --disable-pages-only --data-root "$L15DATA"
l15e_rc="$L15_RC"; l15e_rooted="$(l15_has "$L15_OUT" "no such trip dir under $L15DATA/")"
if [ "$l15e_rc" -eq 1 ] && [ "$l15e_rooted" = 1 ] && [ -z "$L15_LOGT" ]; then
  PASS "L15e: NO FALLBACK — a trip present only in the working directory is refused as 'no such trip dir' naming the data root it looked under (rc=$l15e_rc), before any gh call. Falling back to the working directory would reach a different trip of the same name, which is L15a's defect"
else
  FAIL "L15e: a trip missing under --data-root was not refused under the data root (rc=$l15e_rc, data root named=$l15e_rooted, gh calls: ${L15_LOGT:-none}) — the resolver fell back to the working directory. Output: $L15_OUT"
fi

# L15f — an ABSOLUTE <trip-dir> is used as given, with the flag present.
l15_run stub "$L15EMPTY" unpublish "$L15DECOY/trips/l15-trip" --disable-pages-only --data-root "$L15DATA"
l15f_rc="$L15_RC"; l15f_decoy="$(l15_has "$L15_OUT" 'l15-owner/l15-decoy-slug')"
if [ "$l15f_rc" -eq 0 ] && [ "$l15f_decoy" = 1 ]; then
  PASS "L15f: an absolute <trip-dir> is taken as given even beside --data-root — the trip it names is the one resolved (rc=$l15f_rc); only a relative path is rooted"
else
  FAIL "L15f: an absolute <trip-dir> was re-based or refused (rc=$l15f_rc, its repo named=$l15f_decoy). Output: $L15_OUT"
fi

# L15g — confirm, with NO stub at all: it needs neither gh nor npx, so this is the real
# script in the real environment. Its refusal names the directory it resolved.
l15_run bare "$L15EMPTY" confirm trips/l15-trip --data-root "$L15DATA"
l15g_rc="$L15_RC"; l15g_rooted="$(l15_has "$L15_OUT" "nothing to confirm for $L15DATA/trips/l15-trip")"
if [ "$l15g_rc" -eq 1 ] && [ "$l15g_rooted" = 1 ]; then
  PASS "L15g: confirm, executed with no stub from a directory with no trips/, resolves the trip under --data-root and reads its render — its refusal names the rooted trip (rc=$l15g_rc), not 'no such trip dir'"
else
  FAIL "L15g: confirm did not resolve the trip under --data-root (rc=$l15g_rc, rooted trip named=$l15g_rooted). Output: $L15_OUT"
fi

# L15h — TOTALITY over the arms, read from PARSED bodies so a comment cannot fake it. Every
# cmd_* whose body refuses "no such trip dir" must call resolve_trip_dir BEFORE that refusal.
# The population is derived from the loaded functions, not listed here, so an arm added later
# joins it; publish and rotate, which no arm above executes, are held here. The detector is
# controlled on planted bodies first — one late, one missing — so its verdict is a measurement.
l15_order() {   # l15_order <fn> -> ok | late | missing | n/a
  local body pre
  body="$(declare -f "$1" 2>/dev/null)" || { printf 'n/a'; return 0; }
  case "$body" in *'no such trip dir'*) ;; *) printf 'n/a'; return 0 ;; esac
  pre="${body%%no such trip dir*}"
  case "$pre" in
    *resolve_trip_dir*) printf 'ok' ;;
    *) case "$body" in *resolve_trip_dir*) printf 'late' ;; *) printf 'missing' ;; esac ;;
  esac
}
zzl15_late()    { [ -d "$1" ] || die "no such trip dir: $1"; local d; d="$(resolve_trip_dir "$1")"; printf '%s' "$d"; }
zzl15_missing() { [ -d "$1" ] || die "no such trip dir: $1"; }
l15h_ctl="$(l15_order zzl15_late) $(l15_order zzl15_missing) $(l15_order resolve_trip_dir)"
unset -f zzl15_late zzl15_missing
l15h_pop=0; l15h_ok=0; l15h_bad=""; l15h_fn=""
while read -r _ _ l15h_fn; do
  case "$l15h_fn" in cmd_*) ;; *) continue ;; esac
  case "$(l15_order "$l15h_fn")" in
    ok)   l15h_pop=$((l15h_pop+1)); l15h_ok=$((l15h_ok+1)) ;;
    late|missing) l15h_pop=$((l15h_pop+1)); l15h_bad="$l15h_bad$l15h_fn " ;;
  esac
done <<< "$(declare -F)"
l15h_upd="$(l15_order cmd_update)"; l15h_unp="$(l15_order cmd_unpublish)"
if [ "$l15h_ctl" != 'late missing n/a' ]; then
  FAIL "L15h: CONTROL on the detector — planted late / missing bodies and a body with no refusal read '$l15h_ctl' rather than 'late missing n/a', so the totality verdict below is not a measurement"
elif [ "$l15h_pop" -gt 0 ] && [ "$l15h_ok" -eq "$l15h_pop" ] && [ "$l15h_upd" = ok ] && [ "$l15h_unp" = ok ]; then
  PASS "L15h: all $l15h_pop cmd_* arm(s) that refuse 'no such trip dir' call resolve_trip_dir before refusing, read from their parsed bodies — the verb-reached update and unpublish among them. The detector's control read planted late / missing bodies correctly"
else
  FAIL "L15h: cmd_* arm(s) refuse 'no such trip dir' without resolving first: ${l15h_bad:-none} (population $l15h_pop, ok $l15h_ok, update=$l15h_upd, unpublish=$l15h_unp) — a relative <trip-dir> reaching that arm is resolved against the working directory"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L16 — THE DENIAL SIDE OF may-carry, ONE MUST-FIRE PER DECLARED ROW.
#
# reference/adr/ADR-026-channel-architecture.md § Decision 3 types the denial side of
# `may-carry` over the (limb, artifact-scope) pairs this guard queries. The cases above arm
# that side by hand — L1 and L12 a field on the model, L2 an entry on it — and group M arms a
# field on a traveller file and on a person record. Which ROWS were armed therefore depended
# on which rows somebody thought to arm.
#
# This matrix reads the live declaration through the guard's own reader. For EVERY row whose
# pair is queried it plants a value under that row's selector, at that row's scope, and
# carries it into the render: the publish must abort as a HIT (rc=1). The same trip with a
# render that does not carry the value must publish (rc=0). A row added to the fence gets
# its must-fire on the commit that adds it, and this file still holds no row, no selector
# and no artifact scope.
#
# A row whose pair is NOT queried gets no case here. That is L10c's subject (rc=2), and
# L10d holds the shipped declaration fully queried.
#
# The value is built per the row's own rule, the way the cases above build theirs: a row
# under the word-count rule takes a sentence long enough to be matched as a phrase, as L2's
# does, and every other row a short distinctive value, as L12's does. mtimes are set with
# touch -t, never left to write order — group M's rule — with the model newest, so no
# freshness comparison can fire and an abort is attributable to the class alone.
l16_rows="$(_guard_declared_rows)"
l16_n="$(awk 'NF { c++ } END { print c + 0 }' <<<"$l16_rows")"
l16_q="$(awk -v m="$_GUARD_DECL_ARTIFACT_MODEL" -v p="$_GUARD_DECL_ARTIFACT_PROFILE" -v r="$_GUARD_DECL_ARTIFACT_PERSON" '
    ($1 == "entry" && $3 == m) || ($1 == "field" && ($3 == m || $3 == p || $3 == r)) { print }' <<<"$l16_rows")"
l16_nq="$(awk 'NF { c++ } END { print c + 0 }' <<<"$l16_q")"
l16_np="$(awk 'NF && !s[$1 " " $3]++ { c++ } END { print c + 0 }' <<<"$l16_q")"
if [ "$l16_n" -ge 1 ] && [ "$l16_np" -ge 1 ]; then
  PASS "L16a: the live declaration yields $l16_n row(s), $l16_nq of them on $l16_np queried (limb, artifact-scope) pair(s), read through the guard's own reader — the per-row matrix below has a population"
else
  FAIL "L16a: VACUOUS — the live declaration yields $l16_n row(s) and $l16_np queried pair(s), so the per-row matrix below would assert nothing"
fi
l16_i=0; l16_clean=0; l16_int=0
while read -r l16_limb l16_sel l16_scope l16_rule; do
  [ -n "$l16_limb" ] || continue
  l16_i=$((l16_i + 1))
  L16T="$WORK/l16_$l16_i"; mkdir -p "$L16T/outputs"
  L16R="$WORK/l16_$l16_i.html"; L16C="$WORK/l16_${l16_i}_clean.html"
  if [ "$l16_rule" = by-wordcount ]; then
    l16_val="cannot stand in a queue for longer than a quarter of an hour"
    lrender "$L16R" "Access note: one member of the party $l16_val."
  else
    l16_val="Kestrel Vault 41 clearance $l16_i"
    lrender "$L16R" "Holding note: $l16_val is filed with the courier before departure."
  fi
  lrender "$L16C" "Evening: the riverside lantern walk, then back to the guest house."
  l16_built=1
  case "$l16_limb:$l16_scope" in
    "entry:$_GUARD_DECL_ARTIFACT_MODEL")
      printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n## Quill [OPERATOR-PROVIDED] %s\n\n### Needs\n- Category: mobility\n  Specific: %s\n' "$l16_sel" "$l16_val" > "$L16T/outputs/traveler-model.md" ;;
    "field:$_GUARD_DECL_ARTIFACT_MODEL")
      printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **%s:** %s\n' "$l16_sel" "$l16_val" > "$L16T/outputs/traveler-model.md" ;;
    "field:$_GUARD_DECL_ARTIFACT_PROFILE")
      mkdir -p "$L16T/travelers"
      printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n' > "$L16T/outputs/traveler-model.md"
      printf '# Rowan — traveler profile\n\n## Getting there & back\n- **%s:** %s\n' "$l16_sel" "$l16_val" > "$L16T/travelers/rowan.md"
      touch -t 202601011000 "$L16T/travelers/rowan.md" ;;
    "field:$_GUARD_DECL_ARTIFACT_PERSON")
      mkdir -p "$L16T/travelers" "$L16T/$_GUARD_PERSON_STORE"
      printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n' > "$L16T/outputs/traveler-model.md"
      printf -- '---\nartifact: %s\nschema-version: 1\ntrip: zq-2001\nwriter: human\nlifecycle: persist-mutable\nprovenance: human\npublish: internal\n%s: psn-a1b2\n---\n\n# Rowan\n\n## Getting there & back\n- **Leaving from:** Central Station\n' "$_GUARD_DECL_ARTIFACT_PROFILE" "$_GUARD_REF_KEY" > "$L16T/travelers/rowan.md"
      printf -- '---\nartifact: %s\nschema-version: 1\ntrip: cross-trip\nwriter: human\nlifecycle: persist-mutable\nprovenance: human\npublish: internal-hard\n---\n\n# Rowan\n\n## Getting there & back\n- **%s:** %s\n' "$_GUARD_DECL_ARTIFACT_PERSON" "$l16_sel" "$l16_val" > "$L16T/$_GUARD_PERSON_STORE/psn-a1b2.md"
      touch -t 202601011000 "$L16T/travelers/rowan.md" "$L16T/$_GUARD_PERSON_STORE/psn-a1b2.md" ;;
    *) l16_built=0 ;;
  esac
  if [ "$l16_built" -ne 1 ]; then
    FAIL "L16b[$l16_limb,$l16_sel,$l16_scope]: NO BUILDER — the row's pair is queried and this matrix cannot plant a value at it, so the row has no must-fire. Add the scope's fixture shape here in the change that adds the pair"
    continue
  fi
  touch -t 202601011100 "$L16R" "$L16C"
  touch -t 202601011200 "$L16T/outputs/traveler-model.md"
  l16_hit="$(grep -c -F -- "$l16_val" "$L16R" || true)"; l16_miss="$(grep -c -F -- "$l16_val" "$L16C" || true)"
  [ "$l16_hit" -ge 1 ] && [ "$l16_miss" -eq 0 ] && l16_int=$((l16_int + 1))
  expect_rc 1 "L16b[$l16_limb,$l16_sel,$l16_scope]" "MUST-FIRE — a value under the declared $l16_limb selector $l16_sel, planted at $l16_scope and carried by the render, aborts the publish as a HIT (rule $l16_rule)" -- verify_publishable_content "$L16R" "$L16T"
  lguard "$L16C" "$L16T"
  [ "$LRC" -eq 0 ] && l16_clean=$((l16_clean + 1))
done <<EOF
$l16_q
EOF
if [ "$l16_i" -ge 1 ] && [ "$l16_i" -eq "$l16_nq" ] && [ "$l16_int" -eq "$l16_i" ] && [ "$l16_clean" -eq "$l16_i" ]; then
  PASS "L16c: CLEAN control — for all $l16_i row(s), the same trip with a render that does not carry the planted value publishes (rc=0), and each fixture pair was read back: the planted value is in the first render and absent from the second. Every abort above is caused by that value reaching the render"
else
  FAIL "L16c: the clean control did not hold for every row — $l16_i row(s) built of $l16_nq queried, $l16_int fixture pair(s) intact, $l16_clean clean render(s) published. A fixture that aborts without the planted value makes its row's must-fire above prove nothing"
fi

# ─────────────────────────────────────────────────────────────────────────────
# L17 — AN ARM THE GUARD COULD NOT READ IS UNDETERMINED, NEVER A PASS.
#
# Every case above runs each projection to completion. This one makes ONE projection fail
# on purpose and asks what the guard then certifies. Each arm of the guard is a pipeline —
# projection, entity decoding, line sentinels, normalization — and a stage that fails leaves
# nothing behind it, or a prefix of the render. A guard that matched whatever was left would
# certify a file it never read, and a value only that projection can see would publish. The
# guard reads each arm's status, and refuses an arm that failed or yielded no words, before
# the class is read.
#
# THE RENDERS ARE BUILT SO THAT ONE PROJECTION ALONE SEES THE VALUE. L17P carries it only in
# an img alt, which among the first three only the published projection reads — L13AL's
# construction, and L13c's attribution; the fourth, the shape projection, reads an attribute value
# as the published one does, so its cells use L17P too, and a failure forced on it is refused
# before the published arm's match is ever read. L17J splits its first word with an inline tag,
# which only the joined projection closes up. L17V separates its words with an image whose alt is long: the visible projection
# reads them as neighbours, the joined one fuses two of them into one token, and the published
# one puts the alt's words between them. A failure forced on that projection is therefore the
# only route by which the value could go unread, and the guard's answer is about that route.
#
# THE CELLS, every one graded EXACTLY at rc=2:
#   published, joined,  fails with no output · fails after writing a real prefix · the same
#   shape               prefix with the CALLER'S pipefail off · succeeds with no output, on
#                       the trip's class and on a class with no values
#   visible             fails with no output, on the trip's class and on a class with no
#                       values · fails after a real prefix of twenty words or more, pipefail off
#   normalization       tr, inside _norm_words, fails after a prefix, pipefail off
#   entity decoding     fails after a prefix on the PUBLISHED arm alone — its first call, on
#                       the visible arm, and every call after its second run as production
#                       does — pipefail off
#   matcher             fails on the joined arm alone
# The pipefail-off cells grade the status read rather than this suite's own `pipefail`.
# _guard_arm sets it inside each arm's subshell, so turning it off in the caller's subshell is
# the one thing varied, and it is enough — S15k needed a fresh shell for its own reasons, and
# the pin here lives inside the helper. Each prefix is a real one: the first lines of the same
# projection over the same render, written before any stub exists.
#
# WHAT DECIDES THE CELLS WITH NO OUTPUT. A published, joined or shape arm that succeeds with no output
# is refused by its emptiness limb, where the status limb cannot fire; a visible arm that fails
# with no output is refused by the twenty-word floor, which is asked first, and behind it by its
# status limb. On the trip's class the matcher stands behind all of them: it exits 3 on an empty
# stream, so with those limbs lost the guard still reads the record undetermined, and L17b
# stays green — only L17d's message tells the limb from the matcher there. On a class with no
# values nothing is matched and a lost limb publishes, so the four cells on that class are what
# decide the emptiness limbs and the visible arm's floor and status at rc=2, and the cells on
# the trip's class keep the control L17c reads: the same render is a HIT with the projection
# working. That class parses empty and is read as at least as new as the renders (L17a).
#
# A STAGE THE ARMS SHARE CANNOT CHOOSE THE ARM IT FAILS IN. Stubbed outright it fails on the
# visible arm, which is read first, so the normalization cell grades the VISIBLE arm's read of
# a shared stage. The entity-decoding cell fails on its SECOND call and on no other, so it
# grades the PUBLISHED arm's read of one: if that arm's failure were let through, the joined
# arm would read the render whole and the cell would publish, so its rc=2 is decided by the
# published arm's status read alone. Each call leaves a marker file keyed to the capture the
# caller names, and the oracle's re-run, which writes to its own directory, counts its own
# calls. Its prefix is the published projection's first three lines through the decoder,
# which L17a already grades as carrying words and not the value.
#
# Every stub is defined inside the subshell that uses it, so it dies with that subshell, and
# L17e asserts that. Offline, $WORK fixtures and shell-function stubs only; no legitimate skip.
# ─────────────────────────────────────────────────────────────────────────────
l17val="Border note: carry your Ruritanian passport, valid to 2033, at all times."
L17P="$WORK/l17_published.html"
lplant "$L17P" 5 "nothing of interest on this line at all"
{ head -4 "$L17P"; printf '<img src="x.png" alt="%s">\n' "$l17val"; tail -n +6 "$L17P"; } > "$L17P.tmp" && mv "$L17P.tmp" "$L17P"
L17J="$WORK/l17_joined.html"
lplant "$L17J" 5 "Border note: carry your Rurit<b>anian</b> passport, valid to 2033, at all times."
L17V="$WORK/l17_visible.html"
lplant "$L17V" 7 'Border note: Ruritanian<img src="x.png" alt="one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix">passport, valid to 2033, at all times.'
strip_to_published_text "$L17P" > "$WORK/l17_pfx_pub.txt"
strip_to_joined_text    "$L17J" > "$WORK/l17_pfx_join.txt"
strip_to_text_blocks    "$L17V" > "$WORK/l17_pfx_vis.txt"
strip_to_shape_text     "$L17P" > "$WORK/l17_pfx_shape.txt"
# The class with no values the *-noclass cells read: it parses, and it holds no record. An
# empty class read from a model older than the render is refused before anything is matched
# (CD-3), so the mtimes are set, never left to write order — group M's rule — with the model
# newest.
L17N="$WORK/l17_noclass"; mkdir -p "$L17N/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n### Needs\n- Category: rest\n  Specific: an early night on the first day of the trip\n' > "$L17N/outputs/traveler-model.md"
touch -t 202601011100 "$L17P" "$L17J" "$L17V"
touch -t 202601011200 "$L17N/outputs/traveler-model.md"
L17_DEFS="$(declare -f strip_to_published_text strip_to_joined_text strip_to_text_blocks strip_to_shape_text _guard_match _norm_words _decode_entities)"
L17_CELLS='pub-none pub-prefix pub-prefix-pfoff pub-empty pub-empty-noclass join-none join-prefix join-prefix-pfoff join-empty join-empty-noclass vis-none vis-none-noclass vis-prefix-pfoff norm-prefix-pfoff pub-decode-pfoff matcher-joined shape-none shape-prefix shape-prefix-pfoff shape-empty shape-empty-noclass'
L17_NCELLS=21

# The words in a prefix, counted the way the guard counts an arm: through the stages that
# follow the projection, with both sentinels subtracted.
l17_words() { # <prefix_file> <lines>
  head -n "$2" "$1" | _decode_entities | _line_sentinels | _norm_words \
    | awk -v B="$_GUARD_BLOCK" -v L="$_GUARD_LINE" '$0 != B && $0 != L { c++ } END { print c + 0 }'
}

# One cell: the stub its name declares, inside a subshell, and the guard's exact status.
l17_cell() { # <capture_file> <cell> -> rc on stdout
  local cap="$1" cell="$2" r td
  case "$cell" in
    pub-*) r="$L17P" ;; join-*|matcher-*) r="$L17J" ;; vis-*) r="$L17V" ;; *) r="$L17P" ;;
  esac
  case "$cell" in *-noclass) td="$L17N" ;; *) td="$LTD" ;; esac
  ( case "$cell" in *-pfoff) set +o pipefail ;; esac
    case "$cell" in
      pub-none)          strip_to_published_text() { return 1; } ;;
      pub-prefix*)       strip_to_published_text() { head -n 3 "$WORK/l17_pfx_pub.txt"; return 1; } ;;
      pub-empty*)        strip_to_published_text() { return 0; } ;;
      join-none)         strip_to_joined_text() { return 1; } ;;
      join-prefix*)      strip_to_joined_text() { head -n 3 "$WORK/l17_pfx_join.txt"; return 1; } ;;
      join-empty*)       strip_to_joined_text() { return 0; } ;;
      shape-none)        strip_to_shape_text() { return 1; } ;;
      shape-prefix*)     strip_to_shape_text() { head -n 3 "$WORK/l17_pfx_shape.txt"; return 1; } ;;
      shape-empty*)      strip_to_shape_text() { return 0; } ;;
      vis-none*)         strip_to_text_blocks() { return 1; } ;;
      vis-prefix-pfoff)  strip_to_text_blocks() { head -n 6 "$WORK/l17_pfx_vis.txt"; return 1; } ;;
      norm-prefix-pfoff) tr() { head -c 300 | command tr "$@"; return 1; } ;;
      pub-decode-pfoff)  eval "$(declare -f _decode_entities | sed '1s/^_decode_entities/l17_real_decode/')"
                         _decode_entities() { if [ -e "${cap%.err}.decoded2" ]; then l17_real_decode; return; fi; if [ -e "${cap%.err}.decoded" ]; then : > "${cap%.err}.decoded2"; l17_real_decode | awk 'NR <= 3'; return 1; fi; : > "${cap%.err}.decoded"; l17_real_decode; } ;;
      matcher-joined)    eval "$(declare -f _guard_match | sed '1s/^_guard_match/l17_real_match/')"
                         _guard_match() { case "$3" in *joined.words) return 2 ;; esac; l17_real_match "$@"; } ;;
    esac
    verify_publishable_content "$r" "$td" >/dev/null 2>"$cap" )
  printf '%s' "$?"
}

# L17a — FIXTURE INTEGRITY, graded FIRST. Each prefix must carry words, so that the
# prefix cells are refused by the STATUS limb and not by the emptiness limb — the visible
# one at least twenty, or the floor would refuse it instead — and no prefix may carry the
# value, or a cell could be decided by a match on the prefix. Each render must carry its
# value in the form that confines it to one projection.
l17_wp="$(l17_words "$WORK/l17_pfx_pub.txt" 3)"; l17_wj="$(l17_words "$WORK/l17_pfx_join.txt" 3)"; l17_wv="$(l17_words "$WORK/l17_pfx_vis.txt" 6)"; l17_ws="$(l17_words "$WORK/l17_pfx_shape.txt" 3)"
l17_pv=0
for l17_f in "$WORK/l17_pfx_pub.txt:3" "$WORK/l17_pfx_join.txt:3" "$WORK/l17_pfx_vis.txt:6" "$WORK/l17_pfx_shape.txt:3"; do
  case "$(head -n "${l17_f##*:}" "${l17_f%:*}" | _decode_entities | _norm_words | tr '\n' ' ')" in
    *ruritanian*|*2033*) l17_pv=$((l17_pv+1)) ;;
  esac
done
l17_rv="$(grep -c -F 'alt="Border note: carry your Ruritanian passport' "$L17P")$(grep -c -F 'Rurit<b>anian</b>' "$L17J")$(grep -c -F 'Ruritanian<img' "$L17V")"
# The class with no values must parse EMPTY and be read as fresh against each render, or the
# *-noclass cells would be refused by the class source before any limb they grade is reached.
l17_ne=0
for l17_f in "$L17P" "$L17J" "$L17V"; do
  nonpublishable_values "$L17N" "$l17_f" > "$WORK/l17_noclass.out" 2>/dev/null; l17_nrc=$?
  if [ "$l17_nrc" -eq 0 ] && [ ! -s "$WORK/l17_noclass.out" ]; then l17_ne=$((l17_ne+1)); fi
done
if [ "$l17_wp" -ge 1 ] && [ "$l17_wj" -ge 1 ] && [ "$l17_wv" -ge 20 ] && [ "$l17_ws" -ge 1 ] && [ "$l17_pv" -eq 0 ] && [ "$l17_rv" = "111" ] && [ "$l17_ne" -eq 3 ]; then
  PASS "L17a: fixture integrity — the published, joined and shape prefixes carry $l17_wp, $l17_wj and $l17_ws words and the visible one $l17_wv, none carries the value, and each render carries the value in the one form its projection alone reads among the first three; the class with no values parses empty, read as fresh against each of the $l17_ne renders. The prefix cells below are decided by the status limb"
else
  FAIL "L17a: the fixtures are not set up as claimed (prefix words published=$l17_wp joined=$l17_wj visible=$l17_wv shape=$l17_ws want >=1/>=1/>=20/>=1; prefixes carrying the value=$l17_pv want 0; renders carrying their value=$l17_rv want 111; renders the class with no values reads empty and fresh against=$l17_ne want 3) — L17b would not be measuring the status read"
fi

# L17b — THE SUBJECT, and the arm registered with the oracle. One verdict over every cell,
# so that with the guard removed every cell reads 127 and the arm reports exactly one FAIL.
# Captures go to the directory the caller names, so the oracle's re-run cannot overwrite
# the ones L17d reads.
l17_assert() { # <capture_dir>
  local d="$1" cell rc ok=0 n=0 bad=""
  mkdir -p "$d"
  for cell in $L17_CELLS; do
    n=$((n+1))
    rc="$(l17_cell "$d/$cell.err" "$cell")"
    if [ "$rc" = "2" ]; then ok=$((ok+1)); else bad="$bad $cell=rc$rc"; fi
  done
  if [ "$n" -eq "$L17_NCELLS" ] && [ "$ok" -eq "$n" ]; then
    PASS "L17b: all $n cells are UNDETERMINED (rc=2) — a published, joined or shape projection that fails with no output, fails after a real prefix (with the caller's pipefail on and off) or succeeds with no output, on the trip's class and on a class with no values, a visible projection that fails with no output, on either class, or after twenty words or more, a normalization stage that fails after a prefix, an entity-decoding stage that fails after a prefix on the published arm alone, and a matcher that fails on the joined arm alone. No path from a projection the guard could not read reaches a pass"
  else
    FAIL "L17b: $ok of $n cells (want $L17_NCELLS) returned rc=2 —$bad. A cell at rc=0 is the guard certifying a render one of its own projections never read; rc=1 is a match on a stream it should have refused"
  fi
}
l17_assert "$WORK/l17live"

# L17c — CONTROL. With every projection working, each render is a HIT attributed to the one
# projection that sees its value, so a refusal above is that projection's failure being read
# and not a render the guard refuses anyway. A pipefail-off run with nothing stubbed is a HIT
# too, so the off cells' refusals are not an artefact of turning the option off. On the class
# with no values each render publishes with nothing stubbed, so a *-noclass cell's refusal is
# its stub's and not that class's.
lguard "$L17P"; l17_cp="$LRC"; l17_ap="$(lprj)" || l17_ap="NONE"
lguard "$L17J"; l17_cj="$LRC"; l17_aj="$(lprj)" || l17_aj="NONE"
lguard "$L17V"; l17_cv="$LRC"; l17_av="$(lprj)" || l17_av="NONE"
( set +o pipefail; verify_publishable_content "$L17P" "$LTD" >/dev/null 2>&1 ); l17_coff=$?
lguard "$L17P" "$L17N"; l17_np="$LRC"
lguard "$L17J" "$L17N"; l17_nj="$LRC"
lguard "$L17V" "$L17N"; l17_nv="$LRC"
if [ "$l17_cp" -eq 1 ] && [ "$l17_ap" = "retrievable markup (comment, attribute or script body)" ] \
   && [ "$l17_cj" -eq 1 ] && [ "$l17_aj" = "joined markup (an inline tag split a word)" ] \
   && [ "$l17_cv" -eq 1 ] && [ "$l17_av" = "visible text" ] && [ "$l17_coff" -eq 1 ] \
   && [ "$l17_np" -eq 0 ] && [ "$l17_nj" -eq 0 ] && [ "$l17_nv" -eq 0 ]; then
  PASS "L17c: CONTROL — with every projection working the three renders abort as a HIT (rc=1), attributed to '$l17_ap', '$l17_aj' and '$l17_av' respectively, the published-only render is a HIT with the caller's pipefail off as well (rc=$l17_coff), and on the class with no values the three renders publish (rc=$l17_np, rc=$l17_nj, rc=$l17_nv)"
else
  FAIL "L17c: the control did not hold (published-only rc=$l17_cp '$l17_ap'; joined-only rc=$l17_cj '$l17_aj'; visible-only rc=$l17_cv '$l17_av'; pipefail off rc=$l17_coff; on the class with no values rc=$l17_np, rc=$l17_nj and rc=$l17_nv, want 0 for each) — a refusal in L17b cannot be attributed to the projection that was made to fail"
fi

# L17d — THE MESSAGE (AC-4). A projection refusal names the projection, from the closed
# enum the HIT arm uses, and nothing else: it is written before the class is read, so no
# value is in scope. A visible projection that fails with no output is refused by the
# twenty-word floor, which is asked before the status limb, so its capture carries the
# floor's message — naming visible text, from the same enum — and is counted apart from the
# status refusals. Read from the captures L17b's live run wrote. The value scan carries
# its own sensitivity arm, a planted line it must find.
l17_enum() { # <cell> -> the projection a refusal of that cell must name
  case "$1" in
    pub-*)  printf '%s' "retrievable markup (comment, attribute or script body)" ;;
    join-*) printf '%s' "joined markup (an inline tag split a word)" ;;
    vis-*)  printf '%s' "visible text" ;;
    shape-*) printf '%s' "markup read by shape (every tag and attribute name dropped)" ;;
  esac
}
l17_named=0; l17_floor=0; l17_misnamed=""; l17_leak=0; l17_ncap=0
for l17_c in $L17_CELLS; do
  l17_cap="$WORK/l17live/$l17_c.err"
  [ -r "$l17_cap" ] || continue
  l17_ncap=$((l17_ncap+1))
  case "$(cat "$l17_cap")" in *[Rr]uritanian*|*2033*) l17_leak=$((l17_leak+1)) ;; esac
  l17_want="$(l17_enum "$l17_c")"
  [ -n "$l17_want" ] || continue
  case "$l17_c" in
    vis-none*)
      case "$(cat "$l17_cap")" in
        *"yielded only 0 words of $l17_want"*) l17_floor=$((l17_floor+1)) ;;
        *) l17_misnamed="$l17_misnamed $l17_c" ;;
      esac ;;
    *)
      case "$(cat "$l17_cap")" in
        *"could not be read ($l17_want): its pipeline exited "*) l17_named=$((l17_named+1)) ;;
        *) l17_misnamed="$l17_misnamed $l17_c" ;;
      esac ;;
  esac
done
l17_mx=0; case "$(cat "$WORK/l17live/matcher-joined.err" 2>/dev/null)" in *"could not be run (matcher exit 2)"*) l17_mx=1 ;; esac
l17_plant="planted: carry your Ruritanian passport, valid to 2033"
l17_ctl=0; case "$l17_plant" in *[Rr]uritanian*|*2033*) l17_ctl=1 ;; esac
if [ "$l17_ctl" -eq 1 ] && [ "$l17_ncap" -eq "$L17_NCELLS" ] && [ "$l17_named" -eq 17 ] && [ "$l17_floor" -eq 2 ] && [ -z "$l17_misnamed" ] && [ "$l17_mx" -eq 1 ] && [ "$l17_leak" -eq 0 ]; then
  PASS "L17d: AC-4 — each of the 17 projection refusals names the projection that was made to fail, from the closed enum, the 2 visible projections that fail with no output are refused by the twenty-word floor, whose message names visible text, the matcher cell names the matcher, and none of the $l17_ncap captures carries the value; the value scan found the planted line, so its zero is a measurement"
else
  FAIL "L17d: captures=$l17_ncap of $L17_NCELLS, refusals naming their projection=$l17_named of 17, floor refusals naming visible text=$l17_floor of 2 (misnamed:${l17_misnamed:- none}), matcher named=$l17_mx, captures carrying the value=$l17_leak, scan control=$l17_ctl — a refusal names the wrong projection, or the value reached a log this suite publishes"
fi

# L17e — THE RESTORE. S6c's rule applied to these stubs: every one lived and died in a
# subshell, so the production definitions read now must be the ones read before L17b, and
# neither tr, the renamed matcher nor the renamed decoder may exist as a function in this shell.
l17_stub=""
declare -F tr             >/dev/null 2>&1 && l17_stub="$l17_stub tr"
declare -F l17_real_match >/dev/null 2>&1 && l17_stub="$l17_stub l17_real_match"
declare -F l17_real_decode >/dev/null 2>&1 && l17_stub="$l17_stub l17_real_decode"
if [ -n "$L17_DEFS" ] && [ "$(declare -f strip_to_published_text strip_to_joined_text strip_to_text_blocks strip_to_shape_text _guard_match _norm_words _decode_entities)" = "$L17_DEFS" ] && [ -z "$l17_stub" ]; then
  PASS "L17e: every L17 stub died with its subshell — the seven production definitions read now are byte-identical to the ones read before L17b, and no stub function survives in this shell"
else
  FAIL "L17e: a stub outlived its subshell (functions still defined:${l17_stub:- none}), or a production definition changed — every verdict after L17 would be grading the stub"
fi

# L17f — EVERY ARM OF BOTH CONTENT GUARDS RUNS THROUGH THE ONE ARM HELPER AND THE ONE COUNT
# (#2071 AC-1). L17b grades the status reads the guard makes; this grades that neither guard
# has an arm without one. A projection a guard calls other than as _guard_arm's argument is an
# arm whose status nothing reads, a guard body that names `pipefail` is running a pipeline of
# its own beside the helper, and an arm that counts its words other than through _guard_words
# carries a copy of the count — each reopens, for that arm, the fail-open L17b closes, while
# every L17 cell stays green. Read from the parsed bodies (declare -f drops comments), so a
# projection named in a comment is not counted. A projection is any word that begins `strip_`:
# every projection in the publish script is so named, so an arm added later is counted with no
# list here to update. The count's awk program is read as well: it is written once in the
# publish script, in _guard_words, so a copy anywhere in the script turns this red. The scan's
# control is a planted body carrying one arm of each kind, which it must tell apart.
l17f_scan() { # <function-body text> -> "<projections> <through-helper> <helper-calls> <counts> <pipefail-lines>"
  local line rest np=0 nh=0 na=0 nw=0 npf=0
  while IFS= read -r line; do
    rest="$line"; while [[ "$rest" =~ strip_[a-z_]+(.*) ]]; do np=$((np+1)); rest="${BASH_REMATCH[1]}"; done
    rest="$line"; while [[ "$rest" =~ _guard_arm[[:space:]]+(decode|raw)[[:space:]]+strip_[a-z_]+(.*) ]]; do nh=$((nh+1)); rest="${BASH_REMATCH[2]}"; done
    rest="$line"; while [[ "$rest" =~ _guard_arm[[:space:]](.*) ]]; do na=$((na+1)); rest="${BASH_REMATCH[1]}"; done
    rest="$line"; while [[ "$rest" =~ _guard_words[[:space:]](.*) ]]; do nw=$((nw+1)); rest="${BASH_REMATCH[1]}"; done
    case "$line" in *pipefail*) npf=$((npf+1)) ;; esac
  done <<EOF
$1
EOF
  printf '%d %d %d %d %d' "$np" "$nh" "$na" "$nw" "$npf"
}
L17F_PLANT='( set -o pipefail; strip_to_text_blocks "$1" | _decode_entities | _line_sentinels | _norm_words > "$2" ) || st=$?
_guard_arm decode strip_to_joined_text "$1" "$3" || sj=$?
n="$(_guard_words "$3")"'
l17f_ctl="$(l17f_scan "$L17F_PLANT")"
l17f_v="$(l17f_scan "$(pp_body verify_publishable_content)")"
l17f_s="$(l17f_scan "$(declare -f verify_summary_content)")"
read -r l17f_vp l17f_vh l17f_va l17f_vw l17f_vf <<< "$l17f_v"
read -r l17f_sp l17f_sh l17f_sa l17f_sw l17f_sf <<< "$l17f_s"
l17f_lit='$0 != B && $0 != L { c++ }'
l17f_nlit="$(grep -c -F -- "$l17f_lit" "$SELF_PUBLISH")"
l17f_lctl="$(grep -c -F -- "$l17f_lit" "$SELF")"
if [ "$l17f_ctl" = "2 1 1 1 1" ] && [ "$l17f_lctl" -ge 1 ] \
   && [ "$l17f_vp" -ge 3 ] && [ "$l17f_vh" -eq "$l17f_vp" ] && [ "$l17f_va" -eq "$l17f_vh" ] && [ "$l17f_vw" -eq "$l17f_va" ] && [ "$l17f_vf" -eq 0 ] \
   && [ "$l17f_sp" -ge 1 ] && [ "$l17f_sh" -eq "$l17f_sp" ] && [ "$l17f_sa" -eq "$l17f_sh" ] && [ "$l17f_sw" -eq "$l17f_sa" ] && [ "$l17f_sf" -eq 0 ] \
   && [ "$l17f_nlit" -eq 1 ]; then
  PASS "L17f: AC-1 — verify_publishable_content calls each of its $l17f_vp projections only as _guard_arm's argument and counts each arm through _guard_words ($l17f_vw calls), verify_summary_content its $l17f_sp the same way ($l17f_sw), neither body names pipefail, and the count's awk program is written $l17f_nlit time in the publish script. The scan told the planted body's hand-written arm from its helper arm (control '$l17f_ctl'), so these counts are a measurement"
else
  FAIL "L17f: control '$l17f_ctl' (want '2 1 1 1 1'; the count's awk program in this suite $l17f_lctl time(s), want >=1); verify_publishable_content '$l17f_v' and verify_summary_content '$l17f_s' (projections, through _guard_arm, _guard_arm calls, _guard_words calls, pipefail lines — want the first three equal, the fourth equal to them, the last 0, and at least 3 and 1 projections); the count's awk program $l17f_nlit time(s) in the publish script, want 1 — an arm runs outside the helper, counts outside it, or the scan cannot see one"
fi

# L17g — THE ONE COUNT SUBTRACTS BOTH SENTINELS, ON BOTH GUARDS (#2071). _guard_words is the
# count every arm's floor or emptiness check reads, and what makes it a count of WORDS is that
# neither sentinel is one. Two renders and two summaries, each pair with the same lines: one of
# each carries fewer words than its guard's floor, on more lines and more block boundaries than
# that floor, so a count that took either sentinel for a word would clear the floor and publish
# it; the other carries more words than the floor. Each is read against the class with no
# values, fresh against all four, so the floor is the only question: the under-floor files are
# UNDETERMINED (rc=2) and the others publish (rc=0), which also shows the refusals are the
# floor's and not the files' shape. Fixture integrity is counted by grep, not by the helper.
L17G="$WORK/l17g"; mkdir -p "$L17G"
{ printf '<html><body>\n'
  for l17g_i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
    case "$l17g_i" in *0) printf '<p>w%s</p>\n' "$l17g_i" ;; *) printf '<p></p>\n' ;; esac
  done
  printf '</body></html>\n'; } > "$L17G/under.html"
{ printf '<html><body>\n'
  for l17g_i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
    printf '<p>w%s</p>\n' "$l17g_i"
  done
  printf '</body></html>\n'; } > "$L17G/over.html"
printf '# Change Summary\n\n\n\n\n\n\n\n' > "$L17G/under.md"
printf '# Change Summary for the group\n\n\n\n\n\n\n\n' > "$L17G/over.md"
touch -t 202601011100 "$L17G/under.html" "$L17G/over.html" "$L17G/under.md" "$L17G/over.md"
strip_to_text_blocks "$L17G/under.html" | _decode_entities | _line_sentinels | _norm_words > "$L17G/under.html.words"
strip_md_to_text_blocks "$L17G/under.md" | _line_sentinels | _norm_words > "$L17G/under.md.words"
l17g_hw="$(grep -c -v -x -F -e "$_GUARD_BLOCK" -e "$_GUARD_LINE" "$L17G/under.html.words")"
l17g_hl="$(grep -c -x -F -e "$_GUARD_LINE" "$L17G/under.html.words")"; l17g_hb="$(grep -c -x -F -e "$_GUARD_BLOCK" "$L17G/under.html.words")"
l17g_mw="$(grep -c -v -x -F -e "$_GUARD_BLOCK" -e "$_GUARD_LINE" "$L17G/under.md.words")"
l17g_ml="$(grep -c -x -F -e "$_GUARD_LINE" "$L17G/under.md.words")"; l17g_mb="$(grep -c -x -F -e "$_GUARD_BLOCK" "$L17G/under.md.words")"
l17g_assert() {
  local f want rc ok=0 n=0 bad=""
  for f in under.html:2 over.html:0 under.md:2 over.md:0; do
    n=$((n+1)); want="${f##*:}"
    case "$f" in
      *.html:*) verify_publishable_content "$L17G/${f%:*}" "$L17N" >/dev/null 2>&1; rc=$? ;;
      *)        verify_summary_content     "$L17G/${f%:*}" "$L17N" >/dev/null 2>&1; rc=$? ;;
    esac
    if [ "$rc" -eq "$want" ]; then ok=$((ok+1)); else bad="$bad ${f%:*}=rc$rc/want$want"; fi
  done
  if [ "$l17g_hw" -lt 20 ] && [ $((l17g_hw + l17g_hl)) -ge 20 ] && [ $((l17g_hw + l17g_hb)) -ge 20 ] \
     && [ "$l17g_mw" -lt "$GUARD_SUMMARY_FLOOR" ] && [ $((l17g_mw + l17g_ml)) -ge "$GUARD_SUMMARY_FLOOR" ] && [ $((l17g_mw + l17g_mb)) -ge "$GUARD_SUMMARY_FLOOR" ] \
     && [ "$n" -eq 4 ] && [ "$ok" -eq 4 ]; then
    PASS "L17g: the count subtracts both sentinels on both guards — a render of $l17g_hw words on $l17g_hl lines and $l17g_hb blocks, and a summary of $l17g_mw words on $l17g_ml lines and $l17g_mb blocks, are UNDETERMINED (rc=2) under their floors of 20 and $GUARD_SUMMARY_FLOOR, which either sentinel counted as a word would have cleared; the same lines carrying more words than the floor publish (rc=0) on the same class"
  else
    FAIL "L17g: render words=$l17g_hw lines=$l17g_hl blocks=$l17g_hb (want words <20 and words plus either >=20); summary words=$l17g_mw lines=$l17g_ml blocks=$l17g_mb (want words <$GUARD_SUMMARY_FLOOR and words plus either >=$GUARD_SUMMARY_FLOOR); $ok of $n files returned their status —$bad. An under-floor file at rc=0 is a sentinel counted as a word"
  fi
}
l17g_assert

# ─────────────────────────────────────────────────────────────────────────────
# Group M — the three confirmed defects from the Phase A6.5 adversarial design
# review of the shipped guard (#316). One regression case per counter-design:
#   M1  CD-1  the guard matched the visible-text PROJECTION while publish copies
#             the whole FILE, so a value in a comment or an attribute published.
#   M2  CD-2  the token branch never called is_stop, so a third-party member named
#             with an ordinary English word aborted every publish, permanently.
#   M3  CD-3  the class bound to a [DERIVED] cache with no freshness check, so a
#             passport that existed only in travelers/*.md read as "genuinely EMPTY".
#   M4  CD-4  the freshness walk bound to the TRIP's own directory while the class
#             derives from a cross-trip store, so a durable edit made only in the
#             library read as fresh — and no fence row put its values in class.
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

# ── M1e–M1h (#1467) — a key token written directly before `=`, on the three surfaces only the
# published arm reads ──
#
# The published projection drops an attribute NAME as machinery, and it found one by its shape
# alone: any word followed by `=`, anywhere in the file. A word written that way in a comment
# body, a script body or an attribute value went with it, so each `=` render below published at
# rc=0 where its twin — the same render with that one `=` replaced by a space — aborted at rc=1.
# The projection now finds an attribute name by its place: inside a tag, outside its quoted
# values. Each surface arm grades the `=` render against its twin, by exit code and by the
# projection the abort names, and carries the defect inside the arm (ARMED-RED): the shape-only
# rule, run over the production projection's output in a subshell, must publish the `=` render
# again, so the arm is shown able to fail, and the stub dies with its subshell. The attribute-
# value arm also reads that the attribute's own NAME is still dropped: confining the rule must
# not delete it, and no other arm would notice if it did — measured, groups L to O stay green
# with the rule removed outright.
M1EQ_PRJ='retrievable markup (comment, attribute or script body)'
M1EQ_CM="$WORK/m1eq_comment.html"; mrender "$M1EQ_CM" '<!-- planner note: Ruritanian= passport valid to 2033 -->'
M1TW_CM="$WORK/m1tw_comment.html"; mrender "$M1TW_CM" '<!-- planner note: Ruritanian  passport valid to 2033 -->'
M1EQ_SC="$WORK/m1eq_script.html";  mrender "$M1EQ_SC" '<script>var Ruritanian = "passport valid to 2033";</script>'
M1TW_SC="$WORK/m1tw_script.html";  mrender "$M1TW_SC" '<script>var Ruritanian   "passport valid to 2033";</script>'
M1EQ_AV="$WORK/m1eq_attr.html";    mrender "$M1EQ_AV" '<a href="https://example.org/entry?Ruritanian=passport+valid+to+2033">entry rules</a>'
M1TW_AV="$WORK/m1tw_attr.html";    mrender "$M1TW_AV" '<a href="https://example.org/entry?Ruritanian passport+valid+to+2033">entry rules</a>'
m1eq_n() { "$1" "$2" | _decode_entities | _norm_words | awk -v T="$3" '$0 == T { c++ } END { print c + 0 }'; }   # <projection> <render> <token> -> its count

# M1e — FIXTURE INTEGRITY, graded FIRST. Each pair differs in exactly one byte, so a verdict that
# differs between them is that `=`'s; each `=` render spells the key token once; and neither the
# visible nor the joined projection of any of the six carries it, so a HIT below is the published
# arm's and a publish is that arm losing the token.
m1e_ok=0; m1e_bad=""
for m1e_p in "comment:$M1EQ_CM:$M1TW_CM" "script:$M1EQ_SC:$M1TW_SC" "attribute value:$M1EQ_AV:$M1TW_AV"; do
  m1e_n="${m1e_p%%:*}"; m1e_r="${m1e_p#*:}"; m1e_e="${m1e_r%%:*}"; m1e_t="${m1e_r#*:}"
  m1e_d="$(cmp -l "$m1e_e" "$m1e_t" 2>/dev/null | awk 'END { print NR + 0 }')"
  m1e_k="$(awk '{ c += gsub(/Ruritanian/, "&") } END { print c + 0 }' "$m1e_e")"
  m1e_o=$(( $(m1eq_n strip_to_text_blocks "$m1e_e" ruritanian) + $(m1eq_n strip_to_joined_text "$m1e_e" ruritanian) + $(m1eq_n strip_to_text_blocks "$m1e_t" ruritanian) + $(m1eq_n strip_to_joined_text "$m1e_t" ruritanian) ))
  if [ "$m1e_d" -eq 1 ] && [ "$m1e_k" -eq 1 ] && [ "$m1e_o" -eq 0 ]; then m1e_ok=$((m1e_ok+1)); else m1e_bad="$m1e_bad ${m1e_n}(bytes differing=$m1e_d, key spelled=$m1e_k, other arms=$m1e_o)"; fi
done
if [ "$m1e_ok" -eq 3 ]; then
  PASS "M1e: fixture integrity — each of the 3 '=' renders differs from its twin in exactly one byte and spells the key token once, and neither it nor its twin carries the token on the visible or the joined arm. A verdict difference below is that '=', read by the published arm"
else
  FAIL "M1e: the '=' fixtures are not set up as claimed:$m1e_bad — M1f to M1h would not be measuring the published arm"
fi

# M1f–M1h — one surface each, one verdict each, so the oracle can re-run each whole (group MD).
m1eq_prj() { local ln; while IFS= read -r ln; do
  if [[ "$ln" =~ reached\ the\ published\ file\ at\ .*:[0-9?]+\ \((.*)\)\. ]]; then printf '%s' "${BASH_REMATCH[1]}"; return 0; fi
done < "$MOUT"; return 1; }
m1eq_assert() { # <id> <surface> <=-render> <twin> [an attribute name the render carries] — one verdict
  local id="$1" what="$2" eq="$3" tw="$4" nm="${5:-}" rq pq rt pt mut nm_in=1 kept=0 nmok="" nmbad=""
  mguard "$eq" "$MTD"; rq="$MRC"; pq="$(m1eq_prj)" || pq="NONE"
  mguard "$tw" "$MTD"; rt="$MRC"; pt="$(m1eq_prj)" || pt="NONE"
  mut="$( eval "$(declare -f strip_to_published_text | sed '1s/^strip_to_published_text/m1eq_real/')"
          strip_to_published_text() { m1eq_real "$1" | perl -0777 -pe 's{([-A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*}{ q( ) . ($& =~ tr/\n//cdr) }ge'; }
          verify_publishable_content "$eq" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
  if [ -n "$nm" ]; then
    nm_in="$(awk -v N="$nm=" '{ c += gsub(N, "&") } END { print c + 0 }' "$eq")"
    kept="$(m1eq_n strip_to_published_text "$eq" "$nm")"
    nmok=", and the attribute name $nm is still dropped (in the file $nm_in time(s), in the published stream $kept)"
    nmbad="; attribute name $nm in the file $nm_in time(s), in the published stream $kept (want at least 1, and 0)"
  fi
  if [ "$rq" -eq 1 ] && [ "$pq" = "$M1EQ_PRJ" ] && [ "$rt" -eq 1 ] && [ "$pt" = "$M1EQ_PRJ" ] && [ "$mut" = "0" ] && [ "$nm_in" -ge 1 ] && [ "$kept" -eq 0 ]; then
    PASS "$id: a key token written directly before '=' in $what is read — the '=' render aborts as a HIT (rc=1) named '$pq', as its twin without the '=' does (rc=$rt); ARMED-RED — the shape-only rule run over the same projection publishes it (rc=$mut)$nmok"
  else
    FAIL "$id: a key token written before '=' in $what — '=' render rc=$rq '$pq', twin rc=$rt '$pt' (want 1 and '$M1EQ_PRJ' for both); shape-only mutant rc=$mut (want 0)$nmbad. A value only the published arm reads publishes, or this arm can no longer tell"
  fi
}
m1eq_assert M1f "a comment body"     "$M1EQ_CM" "$M1TW_CM"
m1eq_assert M1g "a script body"      "$M1EQ_SC" "$M1TW_SC"
m1eq_assert M1h "an attribute value" "$M1EQ_AV" "$M1TW_AV" href

# ── M1i–M1n (#1467) — a key token written directly after `<`, on the same three surfaces ──
#
# The published projection drops a tag NAME as machinery, and it found one by its shape alone:
# the word after any `<`, with nothing but spaces or a `/` between them, anywhere in the file. A
# word written that way in a comment body, a script body or an attribute value went with it —
# the address in `Name <address>`, the right-hand side of `n<limit` — so each `<` render below
# published at rc=0 where its twin, the same render with that one `<` replaced by a space,
# aborted at rc=1. The projection now reads those three surfaces as text, and keeps a `<` in
# them only where a block tag or a listed inline tag follows it. M1j writes the criterion's slash
# form (`</ word`) and M1l its spaced form (`< word`), beside the direct form M1k and M1m write,
# so a helper narrowed to a `<` directly before a letter turns M1j and M1l red. Each surface arm
# grades the `<` render against its
# twin, by exit code and by the projection the abort names, and carries the defect inside the
# arm (ARMED-RED): the shipped whole-file tag-name rule, run over the raw render ahead of the
# production projection in a subshell, must publish the `<` render again, so the arm is shown
# able to fail, and the stub dies with its subshell. Each also reads that the render's own
# `<link>` tag NAME is still dropped: reading those surfaces as text must not stop the rule
# dropping a real tag's name, and no other arm would notice if it did — measured, groups L to O
# stay green with the tag-name rule removed outright. M1m is the `Name <address>` form, on the
# comment surface M1j already registers, so it is not registered a second time. M1n grades the
# block-tag `<` those surfaces keep: a block tag inside a script string still ends a block, so a
# passport's two facts in two paragraphs of one string do not pair, as they do not on the page.
# M1o to M1s, after it, grade the inline-tag `<` they keep, the attribute list read with it, and
# the list itself.
M1LT_CM="$WORK/m1lt_comment.html"; mrender "$M1LT_CM" '<!-- planner note: </ Ruritanian passport valid to 2033 -->'
M1LW_CM="$WORK/m1lw_comment.html"; mrender "$M1LW_CM" '<!-- planner note:  / Ruritanian passport valid to 2033 -->'
M1LT_SC="$WORK/m1lt_script.html";  mrender "$M1LT_SC" '<script>var ok = n<Ruritanian && "passport valid to 2033";</script>'
M1LW_SC="$WORK/m1lw_script.html";  mrender "$M1LW_SC" '<script>var ok = n Ruritanian && "passport valid to 2033";</script>'
M1LT_AV="$WORK/m1lt_attr.html";    mrender "$M1LT_AV" '<img src="x.png" alt="a < Ruritanian passport valid to 2033">'
M1LW_AV="$WORK/m1lw_attr.html";    mrender "$M1LW_AV" '<img src="x.png" alt="a   Ruritanian passport valid to 2033">'
M1LT_NA="$WORK/m1lt_address.html"; mrender "$M1LT_NA" '<!-- maintainer: Travel Desk <quillon at example dot invalid> -->'
M1LW_NA="$WORK/m1lw_address.html"; mrender "$M1LW_NA" '<!-- maintainer: Travel Desk  quillon at example dot invalid> -->'

# M1i — FIXTURE INTEGRITY, graded FIRST. Each pair differs in exactly one byte, so a verdict that
# differs between them is that `<`'s; each `<` render spells its key token once; and neither the
# visible nor the joined projection of any of the eight carries it, so a HIT below is the
# published arm's and a publish is that arm losing the token.
m1i_ok=0; m1i_bad=""
for m1i_p in "comment:Ruritanian:$M1LT_CM:$M1LW_CM" "script:Ruritanian:$M1LT_SC:$M1LW_SC" "attribute value:Ruritanian:$M1LT_AV:$M1LW_AV" "address:quillon:$M1LT_NA:$M1LW_NA"; do
  m1i_n="${m1i_p%%:*}"; m1i_r="${m1i_p#*:}"; m1i_w="${m1i_r%%:*}"; m1i_r="${m1i_r#*:}"; m1i_e="${m1i_r%%:*}"; m1i_t="${m1i_r#*:}"
  m1i_lw="$(printf '%s' "$m1i_w" | _norm_words)"
  m1i_d="$(cmp -l "$m1i_e" "$m1i_t" 2>/dev/null | awk 'END { print NR + 0 }')"
  m1i_k="$(awk -v W="$m1i_w" '{ c += gsub(W, "&") } END { print c + 0 }' "$m1i_e")"
  m1i_o=$(( $(m1eq_n strip_to_text_blocks "$m1i_e" "$m1i_lw") + $(m1eq_n strip_to_joined_text "$m1i_e" "$m1i_lw") + $(m1eq_n strip_to_text_blocks "$m1i_t" "$m1i_lw") + $(m1eq_n strip_to_joined_text "$m1i_t" "$m1i_lw") ))
  if [ "$m1i_d" -eq 1 ] && [ "$m1i_k" -eq 1 ] && [ "$m1i_o" -eq 0 ]; then m1i_ok=$((m1i_ok+1)); else m1i_bad="$m1i_bad ${m1i_n}(bytes differing=$m1i_d, key spelled=$m1i_k, other arms=$m1i_o)"; fi
done
if [ "$m1i_ok" -eq 4 ]; then
  PASS "M1i: fixture integrity — each of the 4 '<' renders differs from its twin in exactly one byte and spells its key token once, and neither it nor its twin carries the token on the visible or the joined arm. A verdict difference below is that '<', read by the published arm"
else
  FAIL "M1i: the '<' fixtures are not set up as claimed:$m1i_bad — M1j to M1m would not be measuring the published arm"
fi

# M1j–M1m — one surface each, one verdict each, so the oracle can re-run each whole (group MD).
m1lt_assert() { # <id> <surface> <'<'-render> <twin> — one verdict
  local id="$1" what="$2" lt="$3" tw="$4" rq pq rt pt mut tg_in tg_out
  mguard "$lt" "$MTD"; rq="$MRC"; pq="$(m1eq_prj)" || pq="NONE"
  mguard "$tw" "$MTD"; rt="$MRC"; pt="$(m1eq_prj)" || pt="NONE"
  mut="$( eval "$(declare -f strip_to_published_text | sed '1s/^strip_to_published_text/m1lt_real/')"
          strip_to_published_text() { m1lt_real <(perl -0777 -pe 's{<\s*/?\s*[A-Za-z][-A-Za-z0-9]*}{ q( ) . ($& =~ tr/\n//cdr) }ge' "$1"); }
          verify_publishable_content "$lt" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
  tg_in="$(awk '{ c += gsub(/<link/, "&") } END { print c + 0 }' "$lt")"
  tg_out="$(m1eq_n strip_to_published_text "$lt" link)"
  if [ "$rq" -eq 1 ] && [ "$pq" = "$M1EQ_PRJ" ] && [ "$rt" -eq 1 ] && [ "$pt" = "$M1EQ_PRJ" ] && [ "$mut" = "0" ] && [ "$tg_in" -ge 1 ] && [ "$tg_out" -eq 0 ]; then
    PASS "$id: a key token written directly after '<' in $what is read — the '<' render aborts as a HIT (rc=1) named '$pq', as its twin without the '<' does (rc=$rt); ARMED-RED — the whole-file tag-name rule run ahead of the same projection publishes it (rc=$mut); and the tag name link is still dropped (in the file $tg_in time(s), in the published stream $tg_out)"
  else
    FAIL "$id: a key token written after '<' in $what — '<' render rc=$rq '$pq', twin rc=$rt '$pt' (want 1 and '$M1EQ_PRJ' for both); whole-file tag-name mutant rc=$mut (want 0); tag name link in the file $tg_in time(s), in the published stream $tg_out (want at least 1, and 0). A value only the published arm reads publishes, this arm can no longer tell, or a real tag's name now reaches the stream"
  fi
}
m1lt_assert M1j "a comment body"                      "$M1LT_CM" "$M1LW_CM"
m1lt_assert M1k "a script body"                       "$M1LT_SC" "$M1LW_SC"
m1lt_assert M1l "an attribute value"                  "$M1LT_AV" "$M1LW_AV"
m1lt_assert M1m "a comment body's Name <address> line" "$M1LT_NA" "$M1LW_NA"

# M1n — THE ONE `<` THOSE SURFACES KEEP. Two paragraphs of one script string carry a passport's
# two facts, one each. The block tags between them end a block inside the string as they would
# on the page, so the facts do not pair and the render publishes. The control holds the same
# words in ONE paragraph of the string and aborts, so the publish is the block boundary's and not
# a projection that cannot see the string. ARMED-RED: the same projection with its block
# boundaries removed must abort the two-paragraph render, so the arm is shown able to fail.
M1BK_SP="$WORK/m1bk_split.html"; mrender "$M1BK_SP" '<script>var pop = "<p>Lunch: Ruritanian deli</p><p>2033 Expo tour, tickets valid to noon</p>";</script>'
M1BK_ON="$WORK/m1bk_one.html";   mrender "$M1BK_ON" '<script>var pop = "<p>Lunch: Ruritanian deli. 2033 Expo tour, tickets valid to noon</p>";</script>'
m1bk_assert() { # one verdict
  local rs ro po mut oth
  mguard "$M1BK_SP" "$MTD"; rs="$MRC"
  mguard "$M1BK_ON" "$MTD"; ro="$MRC"; po="$(m1eq_prj)" || po="NONE"
  mut="$( eval "$(declare -f strip_to_published_text | sed '1s/^strip_to_published_text/m1bk_real/')"
          strip_to_published_text() { m1bk_real "$1" | sed "s/$_GUARD_BLOCK/ /g"; }
          verify_publishable_content "$M1BK_SP" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
  oth=$(( $(m1eq_n strip_to_text_blocks "$M1BK_SP" ruritanian) + $(m1eq_n strip_to_joined_text "$M1BK_SP" ruritanian) ))
  if [ "$rs" -eq 0 ] && [ "$ro" -eq 1 ] && [ "$po" = "$M1EQ_PRJ" ] && [ "$mut" = "1" ] && [ "$oth" -eq 0 ]; then
    PASS "M1n: a block tag inside a script string still ends a block — a passport's two facts in two paragraphs of one string publish (rc=$rs), the same words in one paragraph abort as a HIT (rc=$ro) named '$po', and with the block boundaries removed the two-paragraph render aborts (rc=$mut), so the publish is the boundary's. The visible and joined arms carry the key token $oth time(s)"
  else
    FAIL "M1n: two paragraphs of one script string rc=$rs (want 0), one paragraph rc=$ro '$po' (want 1 and '$M1EQ_PRJ'), boundaries removed rc=$mut (want 1), key token on the other arms $oth (want 0) — a block tag in a script string no longer ends a block, so the conjunctive window pairs across it, or this arm can no longer tell"
  fi
}
m1bk_assert

# ── M1o–M1p (#1467) — the INLINE-tag `<` those surfaces keep, in both directions ──
#
# Reading the three surfaces as text keeps a `<` that opens an inline tag on _GUARD_INLINE_TAGS,
# HTML's phrasing content, as markup, and the tag-name rule drops that tag's name there as it
# does on the page. M1o grades the OPEN direction: a value emphasised with listed tags inside a
# script string — a map pop-up's note, a checklist rule a template literal renders — keeps its
# words next to each other on the published arm, so the passport's two facts still pair and the
# need's five-word runs survive, as they did before those surfaces were read as text. M1p grades
# the CLOSED direction: a third-party member named like a listed tag does not abort a page that
# writes that tag in a script string, a comment and an attribute value, and the same member's
# name written as a word does abort, so the member is keyed and the publish is the list's doing.
# Each carries the defect inside the arm (ARMED-RED): the same projection with the inline list
# taken out of its helper, so that the helper keeps only a block tag's `<`, must publish M1o's
# two renders and abort M1p's. The model is synthetic: the suite's Porto passport, and a member
# named Em.
M1IN_POP="$WORK/m1in_popup.html";     mrender "$M1IN_POP" '<script>var pop = "<b>Border desk</b><br>Entry: <em>Ruritanian</em> passport, <strong>valid</strong> to <strong>2033</strong>";</script>'
M1IN_CHK="$WORK/m1in_checklist.html"; mrender "$M1IN_CHK" '<script>var rule = "Lift needed: <b>cannot manage</b> more than <b>one flight</b> of stairs"; var item = `<label><input type="checkbox"> <span>${rule}</span></label>`;</script>'
M1IN_TD="$WORK/porto-em"; mkdir -p "$M1IN_TD/outputs"
cat > "$M1IN_TD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033

## Em [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: cannot manage more than one flight of stairs in a single stretch
  Applies to: ## Hard Constraints → "Mobility"
MD
M1IN_TAG="$WORK/m1in_tagname.html"; mrender "$M1IN_TAG" '<script>var pop = "<b>Corner Roastery</b><br>Ask for the <em>window</em> table";</script>
<!-- promo: <em>two for one</em> on Tuesdays -->
<a href="#menu" title="the <em>new</em> menu">menu</a>'
M1IN_KEY="$WORK/m1in_keyed.html"; mrender "$M1IN_KEY" '<!-- planner note: ask Em at the desk -->'
m1in_off() { # <render> <trip_dir> -> the guard's status with the inline list taken out of the helper
  # The fourth arm (ADR-050) reads what the mutated projection reads: it drops every tag name by
  # shape, so left as it is it would catch the page the mutant exists to publish.
  ( eval "$(declare -f strip_to_published_text | sed 's/|\$_GUARD_INLINE_TAGS//')"
    strip_to_shape_text() { strip_to_published_text "$@"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
m1io_assert() { # one verdict
  local rp pp rl pl mp ml oth
  mguard "$M1IN_POP" "$MTD"; rp="$MRC"; pp="$(m1eq_prj)" || pp="NONE"
  mguard "$M1IN_CHK" "$MTD"; rl="$MRC"; pl="$(m1eq_prj)" || pl="NONE"
  mp="$(m1in_off "$M1IN_POP" "$MTD")"; ml="$(m1in_off "$M1IN_CHK" "$MTD")"
  oth=$(( $(m1eq_n strip_to_text_blocks "$M1IN_POP" ruritanian) + $(m1eq_n strip_to_joined_text "$M1IN_POP" ruritanian) + $(m1eq_n strip_to_text_blocks "$M1IN_CHK" flight) + $(m1eq_n strip_to_joined_text "$M1IN_CHK" flight) ))
  if [ "$rp" -eq 1 ] && [ "$pp" = "$M1EQ_PRJ" ] && [ "$rl" -eq 1 ] && [ "$pl" = "$M1EQ_PRJ" ] && [ "$mp" = "0" ] && [ "$ml" = "0" ] && [ "$oth" -eq 0 ]; then
    PASS "M1o: a value emphasised with listed inline tags inside a script string is read whole — the pop-up's passport note aborts as a HIT (rc=$rp) named '$pp', and the checklist rule a template literal renders aborts too (rc=$rl); ARMED-RED — with the inline list taken out of the helper both publish (rc=$mp, rc=$ml). The visible and joined arms carry the key tokens $oth time(s)"
  else
    FAIL "M1o: pop-up note rc=$rp '$pp', checklist rule rc=$rl '$pl' (want 1 and '$M1EQ_PRJ' for both); without the inline list rc=$mp and rc=$ml (want 0 and 0); key tokens on the other arms $oth (want 0). A value that listed inline tags break up inside a script string publishes, or this arm can no longer tell"
  fi
}
m1io_assert
m1ip_assert() { # one verdict
  local rt rk pk mt tg
  mguard "$M1IN_TAG" "$M1IN_TD"; rt="$MRC"
  mguard "$M1IN_KEY" "$M1IN_TD"; rk="$MRC"; pk="$(m1eq_prj)" || pk="NONE"
  mt="$(m1in_off "$M1IN_TAG" "$M1IN_TD")"
  tg="$(awk '{ c += gsub(/<em>/, "&") } END { print c + 0 }' "$M1IN_TAG")"
  if [ "$rt" -eq 0 ] && [ "$rk" -eq 1 ] && [ "$pk" = "$M1EQ_PRJ" ] && [ "$mt" = "1" ] && [ "$tg" -ge 3 ]; then
    PASS "M1p: a third-party member named like a listed inline tag does not abort a page that writes the tag in a script string, a comment and an attribute value ($tg times; rc=$rt), while the same name written as a word aborts as a HIT (rc=$rk) named '$pk'; ARMED-RED — with the inline list taken out of the helper the page aborts (rc=$mt)"
  else
    FAIL "M1p: the page writing the tag rc=$rt (want 0), the name written as a word rc=$rk '$pk' (want 1 and '$M1EQ_PRJ'), without the inline list rc=$mt (want 1), the tag in the page $tg time(s) (want at least 3). A member named like a listed tag aborts a clean page, or this arm can no longer tell"
  fi
}
m1ip_assert

# ── M1q–M1s (#1467) — a kept tag's ATTRIBUTE LIST, and the inline list's membership ──
#
# A tag kept as markup inside those surfaces is read as a tag is: where its attribute list runs on
# to a `>`, with no `<`, `;`, `(`, `)`, `{` or `}` outside its quoted values, each attribute NAME
# goes and each VALUE stays. A character reference in any of HTML's reference shapes, a template
# literal's one-line `${…}` placeholder and a quoted value after a `=` are each one unit of that
# list, and the list runs on past its line through lines the reader takes as names and
# `name=value` pairs. M1q grades the OPEN direction on the realistic form, inline markup that
# carries attributes: a pop-up note written with `<span class="…">` and a checklist rule written
# with `<b class="">`, inside script strings, keep the value's words next to each other and abort
# as M1o's bare forms do; so do pop-ups whose spans carry a `${…}` placeholder, whose class values
# are single-quoted, whose quotes are written `&quot;`, `&#34;` or `&#x22;`, or whose tooltip
# quotes are `&#39;`, pop-ups whose spans set their attributes on the next line — among them a
# value written `&-`, and a single-quoted value beside an entity-quoted one — and one whose quoted
# class values run over a line. Each of those cells pins one unit or one branch of the list, so a
# helper that loses it turns that cell red — save the three reference forms, whose lists the bounds
# below take as well — and so do nine more lists that only this read takes: spans whose quoted
# value holds a `<`, written in double quotes and in single quotes, and escaped inside a double-
# and a single-quoted script string; spans whose quoted values hold a `>` and then a `<` that opens
# a tag; a list on the head line holding a quoted `>`, which this read takes whole before anything
# below can end it at that `>`; and lists holding a quoted `>` and values quoted with `&#x22;`,
# `&#34;` and `&quot;`, one cell for each, with a comparison's `<` after the list, so that neither
# bound below reaches the tag's `>` and each reference form is pinned on its own. Where this read
# cannot reach the tag's `>`, the text up to the last `>` before the next tag, else up to the next
# `>` with no `<` before it,
# is read as the list instead, and M1q's other cells are the lists only those two bounds take:
# spans whose placeholder stands on the next line, alone or as an unquoted value, whose
# placeholder's braces nest or run over a line, whose next line starts with a word no attribute
# list carries, a pop-up whose entity-quoted value runs over a line, and an image with no tag after
# it in its string, which the second bound alone takes; and spans whose list holds a `>` inside a
# quoted value or a placeholder ahead of the tag's own — an arrow function's among them, on the
# next line or nested on the head line — with a closing tag, a comment or an opening tag after the
# list, which the first bound alone takes. M1r grades the PRICE the RESIDUAL states: a word written
# directly before `=` after such a `<` is dropped as an attribute name wherever it stands inside the
# text read as the tag's list, as the shipped guard dropped it, so that render publishes, and so do
# a comment that holds that word as an attribute on the line after its `<`, one whose quoted value
# after the `=` runs over a line, the same comparison closed by `)` with a `>` later in the script,
# a comparison whose next line is no attribute list, and a loop whose assignment stands between an
# arrow function's `>` and the last `>` before markup later in the script; a member named like an
# attribute that a list over lines carries does not abort the page either, written in double quotes
# with a tag after the list or in single quotes with none, and nor does one named like the attribute
# an arrow function's list carries ahead of a closing tag. A run that meets a `<` first keeps its
# word and aborts, its word after that `<` read as M1k's is, and so do the same `<` written inside a
# `${…}` placeholder, a comparison with no `>` after it at all, a comparison whose first `>` comes
# before the word with only a comparison's `<` after it, and a comparison closed by `)` with a
# quoted `<` after it, which this read does not reach past the `)`. A kept head followed by lines of
# nothing but spaces and then a line that is no attribute list aborts too, and so does the same head
# followed by lines that each hold a name and then spaces, both read under a five-second CPU cap,
# so a reader that backtracks over those spaces fails the arm instead of holding the run. Each line
# is long enough that one of those runs read without its possessive quantifier overruns the cap on
# its own: a line of spaces alone reaches only the line's leading run, which takes every space on
# it, so the lines holding a name first are what reach the runs after it. A comment left open to the
# end of the page is read to that end as a comment body, so a word written after a `<` in it aborts
# as it does in a closed one; with the comment tokenizer's end-of-input branch taken out that page
# publishes, as the shipped guard published it, so the abort is that branch's doing. Each arm
# carries the defect inside it (ARMED-RED): the same projection with
# the attribute-list read taken out of its helper — the `>` lookahead its three readings share made
# unsatisfiable, which leaves every `<` the helper keeps exactly as it was — must publish M1q's
# thirty-four renders and abort M1r's nine priced ones. M1s grades the LIST: every name of HTML's
# phrasing content, written here as a literal copy and never read from _GUARD_INLINE_TAGS, rendered
# as `<T>zq</T>` inside one comment body, must leave no listed name in the published stream while
# every `zq` reaches it; with the inline list taken out of the helper (M1o's control) each name
# reaches it twice. A name taken off the constant turns M1s red; a name added to it does not, and
# widening the list is a deliberate edit in three places — the constant, the copy here, and the
# count of names M1s's condition and its FAIL message carry. A comment body and not a script string:
# a `</script>` written inside a script string ends the script.
M1KA_POP="$WORK/m1ka_popup.html";     mrender "$M1KA_POP" '<script>var pop = `<b>Border desk</b><br>Entry: <span class="flag">Ruritanian</span> passport, <span class="ok">valid</span> to <span class="yr">2033</span>`;</script>'
M1KA_CHK="$WORK/m1ka_checklist.html"; mrender "$M1KA_CHK" '<script>var rule = `Lift needed: <b class="">cannot manage</b> more than <b class="">one flight</b> of stairs`; var item = `<label><input type="checkbox"> <span>${rule}</span></label>`;</script>'
M1KA_REF="$WORK/m1ka_charref.html";   mrender "$M1KA_REF" '<div data-popup="Entry: Ruritanian <span class=&quot;a&quot;>passport</span>, <span class=&quot;b&quot;>valid</span> to <span class=&quot;c&quot;>2033</span>">details</div>'
M1KA_N34="$WORK/m1ka_decimal.html";   mrender "$M1KA_N34" '<div data-popup="Entry: Ruritanian <span class=&#34;a&#34;>passport</span>, <span class=&#34;b&#34;>valid</span> to <span class=&#34;c&#34;>2033</span>">details</div>'
M1KA_X22="$WORK/m1ka_hex.html";       mrender "$M1KA_X22" '<div data-popup="Entry: Ruritanian <span class=&#x22;a&#x22;>passport</span>, <span class=&#x22;b&#x22;>valid</span> to <span class=&#x22;c&#x22;>2033</span>">details</div>'
M1KA_T39="$WORK/m1ka_tooltip.html";   mrender "$M1KA_T39" '<button data-tip="Entry: Ruritanian <b class=&#39;hl&#39;>passport</b>, <b class=&#39;hl&#39;>valid</b> to <b class=&#39;hl&#39;>2033</b>">?</button>'
M1KA_SQ="$WORK/m1ka_squote.html";     mrender "$M1KA_SQ" "<script>marker.bindPopup(\"<b>Border desk</b><br>Entry: <span class='flag'>Ruritanian</span> passport, <span class='ok'>valid</span> to <span class='yr'>2033</span>\");</script>"
M1KA_DL="$WORK/m1ka_placeholder.html"; mrender "$M1KA_DL" '<script>var pop = `Entry: <span ${c} class="">Ruritanian</span> passport, <span ${c} class="">valid</span> to <span ${c} class="">2033</span>`;</script>'
M1KA_ML="$WORK/m1ka_lines.html";      mrender "$M1KA_ML" '<script>var pop = `<b>Border desk</b><br>Entry: <span
 class="flag">Ruritanian</span> passport, <span
 class="ok">valid</span> to <span
 class="yr">2033</span>`;</script>'
M1KA_QML="$WORK/m1ka_qlines.html";    mrender "$M1KA_QML" '<script>var pop = `Entry: <span class="flag
">Ruritanian</span> passport, <span class="ok
">valid</span> to <span class="yr
">2033</span>`;</script>'
M1KA_AMP="$WORK/m1ka_nextamp.html";   mrender "$M1KA_AMP" '<script>var pop = `Entry: <span
 data-k=&- class="">Ruritanian</span> passport, <span
 data-k=&- class="">valid</span> to <span
 data-k=&- class="">2033</span>`;</script>'
M1KA_FSE="$WORK/m1ka_nextquotes.html"; mrender "$M1KA_FSE" "<div data-popup=\"Entry: Ruritanian <span
 data-tip='' class=&quot;&quot;>passport</span>, <span
 data-tip='' class=&quot;&quot;>valid</span> to <span
 data-tip='' class=&quot;&quot;>2033</span>\">details</div>"
M1KA_FLP="$WORK/m1ka_nextph.html";    mrender "$M1KA_FLP" '<script>var pop = `Entry: <span
 ${c} class="">Ruritanian</span> passport, <span
 ${c} class="">valid</span> to <span
 ${c} class="">2033</span>`;</script>'
M1KA_FLV="$WORK/m1ka_nextphvalue.html"; mrender "$M1KA_FLV" '<script>var pop = `Entry: <span
 data-k=${c} class="">Ruritanian</span> passport, <span
 data-k=${c} class="">valid</span> to <span
 data-k=${c} class="">2033</span>`;</script>'
M1KA_NEST="$WORK/m1ka_nested.html";   mrender "$M1KA_NEST" '<script>var pop = `Entry: <span class="">Ruritanian</span> passport, <span ${ {}[k] } class="">valid</span> to <span ${ {}[k] } class="">2033</span>`;</script>'
M1KA_MLBR="$WORK/m1ka_placeholderlines.html"; mrender "$M1KA_MLBR" '<script>var pop = `Entry: <span class="">Ruritanian</span> passport, <span ${
 k } class="">valid</span> to <span ${
 k } class="">2033</span>`;</script>'
M1KA_NAL="$WORK/m1ka_nextnotlist.html"; mrender "$M1KA_NAL" '<script>var pop = `Entry: <span
 1x class="">Ruritanian</span> passport, <span
 1x class="">valid</span> to <span
 1x class="">2033</span>`;</script>'
M1KA_ENQ="$WORK/m1ka_entitylines.html"; mrender "$M1KA_ENQ" '<div data-popup="Entry: Ruritanian <span title=&quot;a
b&quot; class=&quot;&quot;>passport</span>, valid to 2033">details</div>'
M1KA_QLT="$WORK/m1ka_quotedlt.html";  mrender "$M1KA_QLT" '<script>var pop = `Entry: <span data-op="<" class="">Ruritanian</span> passport, <span data-op="<" class="">valid</span> to <span data-op="<" class="">2033</span>`;</script>'
M1KA_SLT="$WORK/m1ka_squotedlt.html"; mrender "$M1KA_SLT" "<script>var pop = \`Entry: <span data-op='<' class=\"\">Ruritanian</span> passport, <span data-op='<' class=\"\">valid</span> to <span data-op='<' class=\"\">2033</span>\`;</script>"
M1KA_DQE="$WORK/m1ka_escapeddq.html"; mrender "$M1KA_DQE" '<script>marker.bindPopup("Entry: <span data-op=\"<\" class=\"\">Ruritanian</span> passport, <span data-op=\"<\" class=\"\">valid</span> to <span data-op=\"<\" class=\"\">2033</span>");</script>'
M1KA_SQE="$WORK/m1ka_escapedsq.html"; mrender "$M1KA_SQE" "<script>marker.bindPopup('Entry: <span data-op=\\'<\\' class=\\'\\'>Ruritanian</span> passport, <span data-op=\\'<\\' class=\\'\\'>valid</span> to <span data-op=\\'<\\' class=\\'\\'>2033</span>');</script>"
M1KA_TAG="$WORK/m1ka_quotedtag.html"; mrender "$M1KA_TAG" '<script>var pop = `Entry: <span title=">" data-op="<b" class="">Ruritanian</span> passport, <span title=">" data-op="<b" class="">valid</span> to <span title=">" data-op="<b" class="">2033</span>`;</script>'
M1KA_HQG="$WORK/m1ka_headquotedgt.html"; mrender "$M1KA_HQG" '<script>var pop = `Entry: <span title=">" class="" data-k="">Ruritanian</span> passport, <span title=">" class="" data-k="">valid</span> to <span title=">" class="" data-k="">2033</span>`;</script>'
M1KA_NTG="$WORK/m1ka_notag.html";     mrender "$M1KA_NTG" '<script>var pop = `Entry: Ruritanian <img
 ${c} class="" src="x.png">passport, valid to 2033`;</script>'
M1KA_QGT="$WORK/m1ka_quotedgt.html";  mrender "$M1KA_QGT" '<script>var pop = `Entry: <span
 ${c} title=">" class="">Ruritanian</span> passport, <span
 ${c} title=">" class="">valid</span> to <span
 ${c} title=">" class="">2033</span>`;</script>'
M1KA_PGT="$WORK/m1ka_placeholdergt.html"; mrender "$M1KA_PGT" '<script>var pop = `Entry: Ruritanian <span
 ${a>b} class="" title="">passport</span>, valid to 2033`;</script>'
M1KA_AFL="$WORK/m1ka_arrowline.html"; mrender "$M1KA_AFL" '<script>var pop = `Entry: Ruritanian <span
 ${f(x => x)} class="" title="">passport</span>, valid to 2033`;</script>'
M1KA_AHN="$WORK/m1ka_arrownest.html"; mrender "$M1KA_AHN" '<script>var pop = `Entry: Ruritanian <span ${f(x => { x })} class="" title="">passport</span>, valid to 2033`;</script>'
M1KA_BNG="$WORK/m1ka_beforecomment.html"; mrender "$M1KA_BNG" '<script>var pop = `Entry: <span
 ${c} title=">" class=""><!---->Ruritanian</span> passport, <span
 ${c} title=">" class=""><!---->valid</span> to <span
 ${c} title=">" class=""><!---->2033</span>`;</script>'
M1KA_LTR="$WORK/m1ka_beforetag.html"; mrender "$M1KA_LTR" '<script>var pop = `Entry: <span
 ${c} title=">" class=""><b>Ruritanian</b></span> passport, <span
 ${c} title=">" class=""><b>valid</b></span> to <span
 ${c} title=">" class=""><b>2033</b></span>`;</script>'
M1KA_RHX="$WORK/m1ka_refhex.html"; mrender "$M1KA_RHX" '<script>var pop = `Entry: Ruritanian <span title=">" class=&#x22;&#x22; data-k=&#x22;&#x22; data-m=&#x22;&#x22;>passport, valid to 2033 ${n < 3}</span>`;</script>'
M1KA_RDC="$WORK/m1ka_refdec.html"; mrender "$M1KA_RDC" '<script>var pop = `Entry: Ruritanian <span title=">" class=&#34;&#34; data-k=&#34;&#34; data-m=&#34;&#34;>passport, valid to 2033 ${n < 3}</span>`;</script>'
M1KA_RNM="$WORK/m1ka_refnamed.html"; mrender "$M1KA_RNM" '<script>var pop = `Entry: Ruritanian <span title=">" class=&quot;&quot; data-k=&quot;&quot; data-m=&quot;&quot;>passport, valid to 2033 ${n < 3}</span>`;</script>'
M1KA_EQ="$WORK/m1ka_price.html";     mrender "$M1KA_EQ" '<script>if (n<b && Ruritanian=="passport valid to 2033" > 0) { go(); }</script>'
M1KA_EQN="$WORK/m1ka_pricenext.html"; mrender "$M1KA_EQN" '<!-- planner note: n<b
 Ruritanian="passport valid to 2033" -->'
M1KA_EQV="$WORK/m1ka_pricevalue.html"; mrender "$M1KA_EQV" '<!-- planner note: n<b Ruritanian="passport
valid to 2033" -->'
M1KA_EQT="$WORK/m1ka_stopped.html";   mrender "$M1KA_EQT" '<script>if (n<b && Ruritanian=="passport valid to 2033") { go(); } if (k > 2) { stop(); }</script>'
M1KA_LT="$WORK/m1ka_lt.html";         mrender "$M1KA_LT" '<script>if (n<b && m<Ruritanian > 0) { note = "passport valid to 2033"; }</script>'
M1KA_LTB="$WORK/m1ka_ltbraces.html";  mrender "$M1KA_LTB" '<script>var pop = `Entry: <span ${n<Ruritanian ? 1 : 0} class="">passport</span>, valid to 2033`;</script>'
M1KA_EQL="$WORK/m1ka_eqlines.html";   mrender "$M1KA_EQL" '<script>if (n<b
 && Ruritanian=="passport valid to 2033"
 > 0) { go(); }</script>'
M1KA_NGT="$WORK/m1ka_nogt.html";      mrender "$M1KA_NGT" '<script>if (n<b && Ruritanian=="passport valid to 2033") { go(); }</script>'
M1KA_EQM="$WORK/m1ka_pricemarkup.html"; mrender "$M1KA_EQM" '<script>for (let i = 0; i < a.length; i++) { f(x => x); } const Ruritanian = "passport valid to 2033"; g(y => y); el.innerHTML = `<b>x</b>`;</script>'
M1KA_CLT="$WORK/m1ka_comparelt.html"; mrender "$M1KA_CLT" '<script>if (n<b && f(x) > 0 && Ruritanian=="passport valid to 2033") { show(y => y); } if (m < k) { go(); }</script>'
M1KA_PLT="$WORK/m1ka_parenlt.html";   mrender "$M1KA_PLT" '<script>var t = (n<b && Ruritanian=="passport valid to 2033") && op == "<" > 0;</script>'
M1KA_TD="$WORK/porto-type"; mkdir -p "$M1KA_TD/outputs"
cat > "$M1KA_TD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033

## Type [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: cannot manage more than one flight of stairs in a single stretch
  Applies to: ## Hard Constraints → "Mobility"
MD
M1KA_TYP="$WORK/m1ka_typemember.html"; mrender "$M1KA_TYP" '<div id="checklist"></div>
<script>document.getElementById("checklist").innerHTML = items.map(b => `<label class="chk-item">
  <input type="checkbox" data-id="${b.id}"
    ${done[b.id] ? "checked" : ""}>
  <span class="venue">${b.venue}</span></label>`).join("");</script>'
M1KA_TYS="$WORK/m1ka_typesquote.html"; mrender "$M1KA_TYS" "<div id=\"checklist\"></div>
<script>document.getElementById(\"checklist\").innerHTML = items.map(b => \`<input type=\"checkbox\" data-id=\"\${b.id}\"
    \${done[b.id] ? 'checked' : ''}>\`).join(\"\");</script>"
M1KA_CD="$WORK/porto-class"; mkdir -p "$M1KA_CD/outputs"
cat > "$M1KA_CD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033

## Class [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: cannot manage more than one flight of stairs in a single stretch
  Applies to: ## Hard Constraints → "Mobility"
MD
M1KA_LIC="$WORK/m1ka_classarrow.html"; mrender "$M1KA_LIC" '<script>list.innerHTML = stops.map(s => `<li
 ${f(x => x)} class="stop">${s.name}</li>`).join("");</script>'
m1ka_ws="$(printf '%s' '<!-- planner note: n<b'; printf '\n%32000s' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' ''; printf '\n%s' '( Ruritanian passport valid to 2033 -->')"
M1KA_WS="$WORK/m1ka_spaces.html";     mrender "$M1KA_WS" "$m1ka_ws"
m1ka_wsn="$(printf '%s' '<!-- planner note: n<b'; printf '\n x%32000s' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' '' ''; printf '\n%s' '( Ruritanian passport valid to 2033 -->')"
M1KA_WSN="$WORK/m1ka_namespaces.html"; mrender "$M1KA_WSN" "$m1ka_wsn"
M1KA_CMZ="$WORK/m1ka_opencomment.html"; mrender "$M1KA_CMZ" '<!-- planner note: n<Ruritanian passport valid to 2033'
{ sed '$d' "$M1KA_CMZ"; printf '%s\n' '</body' '></html' '>'; } > "$M1KA_CMZ.tmp" && mv "$M1KA_CMZ.tmp" "$M1KA_CMZ"
m1ka_off() { # <render> <trip_dir> -> the guard's status with the attribute-list read taken out of the helper
  # Each mutant here points the fourth arm (ADR-050) at the mutated projection, as m1in_off does.
  ( eval "$(declare -f strip_to_published_text | sed 's/(?=>)|)/(?!)|)/')"
    strip_to_shape_text() { strip_to_published_text "$@"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
m1kc_off() { # <render> <trip_dir> -> the guard's status with the comment tokenizer's end-of-input branch taken out
  ( eval "$(declare -f strip_to_published_text | sed 's/(<!--\.\*?(?:-->|\\z))/(<!--.*?-->)/')"
    strip_to_shape_text() { strip_to_published_text "$@"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
m1iq_assert() { # one verdict
  local rp pp rl pl rf pf rn pn rq pq rd pd ra pa rx px rt pt rs ps ra2 pa2 re pe rh ph rj pj rk pk ro po ry py rw pw re2 pe2 rs2 ps2 rd2 pd2 rq2 pq2 ri pi rv pv rn2 pn2 ru pu rz pz rb pb rg pg rf2 pf2 rl2 pl2 mp ml mf mn mq md ma mx mt ms ma2 me mh mj mk mo my mw me2 ms2 md2 mq2 mi mv mn2 mu mz mb mg mf2 ml2 rhx phx rdc pdc rnm pnm mhx mdc mnm oth rr
  mguard "$M1KA_POP" "$MTD"; rp="$MRC"; pp="$(m1eq_prj)" || pp="NONE"
  mguard "$M1KA_CHK" "$MTD"; rl="$MRC"; pl="$(m1eq_prj)" || pl="NONE"
  mguard "$M1KA_REF" "$MTD"; rf="$MRC"; pf="$(m1eq_prj)" || pf="NONE"
  mguard "$M1KA_ML" "$MTD"; rn="$MRC"; pn="$(m1eq_prj)" || pn="NONE"
  mguard "$M1KA_QML" "$MTD"; rq="$MRC"; pq="$(m1eq_prj)" || pq="NONE"
  mguard "$M1KA_DL" "$MTD"; rd="$MRC"; pd="$(m1eq_prj)" || pd="NONE"
  mguard "$M1KA_N34" "$MTD"; ra="$MRC"; pa="$(m1eq_prj)" || pa="NONE"
  mguard "$M1KA_X22" "$MTD"; rx="$MRC"; px="$(m1eq_prj)" || px="NONE"
  mguard "$M1KA_T39" "$MTD"; rt="$MRC"; pt="$(m1eq_prj)" || pt="NONE"
  mguard "$M1KA_SQ" "$MTD"; rs="$MRC"; ps="$(m1eq_prj)" || ps="NONE"
  mguard "$M1KA_AMP" "$MTD"; ra2="$MRC"; pa2="$(m1eq_prj)" || pa2="NONE"
  mguard "$M1KA_FSE" "$MTD"; re="$MRC"; pe="$(m1eq_prj)" || pe="NONE"
  mguard "$M1KA_FLP" "$MTD"; rh="$MRC"; ph="$(m1eq_prj)" || ph="NONE"
  mguard "$M1KA_FLV" "$MTD"; rj="$MRC"; pj="$(m1eq_prj)" || pj="NONE"
  mguard "$M1KA_NEST" "$MTD"; rk="$MRC"; pk="$(m1eq_prj)" || pk="NONE"
  mguard "$M1KA_MLBR" "$MTD"; ro="$MRC"; po="$(m1eq_prj)" || po="NONE"
  mguard "$M1KA_NAL" "$MTD"; ry="$MRC"; py="$(m1eq_prj)" || py="NONE"
  mguard "$M1KA_ENQ" "$MTD"; rw="$MRC"; pw="$(m1eq_prj)" || pw="NONE"
  mguard "$M1KA_QLT" "$MTD"; re2="$MRC"; pe2="$(m1eq_prj)" || pe2="NONE"
  mguard "$M1KA_SLT" "$MTD"; rs2="$MRC"; ps2="$(m1eq_prj)" || ps2="NONE"
  mguard "$M1KA_DQE" "$MTD"; rd2="$MRC"; pd2="$(m1eq_prj)" || pd2="NONE"
  mguard "$M1KA_SQE" "$MTD"; rq2="$MRC"; pq2="$(m1eq_prj)" || pq2="NONE"
  mguard "$M1KA_TAG" "$MTD"; ri="$MRC"; pi="$(m1eq_prj)" || pi="NONE"
  mguard "$M1KA_HQG" "$MTD"; rv="$MRC"; pv="$(m1eq_prj)" || pv="NONE"
  mguard "$M1KA_NTG" "$MTD"; rn2="$MRC"; pn2="$(m1eq_prj)" || pn2="NONE"
  mguard "$M1KA_QGT" "$MTD"; ru="$MRC"; pu="$(m1eq_prj)" || pu="NONE"
  mguard "$M1KA_PGT" "$MTD"; rz="$MRC"; pz="$(m1eq_prj)" || pz="NONE"
  mguard "$M1KA_AFL" "$MTD"; rb="$MRC"; pb="$(m1eq_prj)" || pb="NONE"
  mguard "$M1KA_AHN" "$MTD"; rg="$MRC"; pg="$(m1eq_prj)" || pg="NONE"
  mguard "$M1KA_BNG" "$MTD"; rf2="$MRC"; pf2="$(m1eq_prj)" || pf2="NONE"
  mguard "$M1KA_LTR" "$MTD"; rl2="$MRC"; pl2="$(m1eq_prj)" || pl2="NONE"
  mguard "$M1KA_RHX" "$MTD"; rhx="$MRC"; phx="$(m1eq_prj)" || phx="NONE"
  mguard "$M1KA_RDC" "$MTD"; rdc="$MRC"; pdc="$(m1eq_prj)" || pdc="NONE"
  mguard "$M1KA_RNM" "$MTD"; rnm="$MRC"; pnm="$(m1eq_prj)" || pnm="NONE"
  mp="$(m1ka_off "$M1KA_POP" "$MTD")"; ml="$(m1ka_off "$M1KA_CHK" "$MTD")"; mf="$(m1ka_off "$M1KA_REF" "$MTD")"
  mn="$(m1ka_off "$M1KA_ML" "$MTD")"; mq="$(m1ka_off "$M1KA_QML" "$MTD")"; md="$(m1ka_off "$M1KA_DL" "$MTD")"
  ma="$(m1ka_off "$M1KA_N34" "$MTD")"; mx="$(m1ka_off "$M1KA_X22" "$MTD")"; mt="$(m1ka_off "$M1KA_T39" "$MTD")"
  ms="$(m1ka_off "$M1KA_SQ" "$MTD")"; ma2="$(m1ka_off "$M1KA_AMP" "$MTD")"; me="$(m1ka_off "$M1KA_FSE" "$MTD")"
  mh="$(m1ka_off "$M1KA_FLP" "$MTD")"; mj="$(m1ka_off "$M1KA_FLV" "$MTD")"; mk="$(m1ka_off "$M1KA_NEST" "$MTD")"
  mo="$(m1ka_off "$M1KA_MLBR" "$MTD")"; my="$(m1ka_off "$M1KA_NAL" "$MTD")"; mw="$(m1ka_off "$M1KA_ENQ" "$MTD")"
  me2="$(m1ka_off "$M1KA_QLT" "$MTD")"; ms2="$(m1ka_off "$M1KA_SLT" "$MTD")"; md2="$(m1ka_off "$M1KA_DQE" "$MTD")"
  mq2="$(m1ka_off "$M1KA_SQE" "$MTD")"; mi="$(m1ka_off "$M1KA_TAG" "$MTD")"; mv="$(m1ka_off "$M1KA_HQG" "$MTD")"
  mn2="$(m1ka_off "$M1KA_NTG" "$MTD")"; mu="$(m1ka_off "$M1KA_QGT" "$MTD")"; mz="$(m1ka_off "$M1KA_PGT" "$MTD")"
  mb="$(m1ka_off "$M1KA_AFL" "$MTD")"; mg="$(m1ka_off "$M1KA_AHN" "$MTD")"; mf2="$(m1ka_off "$M1KA_BNG" "$MTD")"
  ml2="$(m1ka_off "$M1KA_LTR" "$MTD")"; mhx="$(m1ka_off "$M1KA_RHX" "$MTD")"; mdc="$(m1ka_off "$M1KA_RDC" "$MTD")"
  mnm="$(m1ka_off "$M1KA_RNM" "$MTD")"
  oth=$(( $(m1eq_n strip_to_text_blocks "$M1KA_CHK" flight) + $(m1eq_n strip_to_joined_text "$M1KA_CHK" flight) ))
  for rr in "$M1KA_POP" "$M1KA_REF" "$M1KA_ML" "$M1KA_QML" "$M1KA_DL" "$M1KA_N34" "$M1KA_X22" "$M1KA_T39" "$M1KA_SQ" "$M1KA_AMP" "$M1KA_FSE" "$M1KA_FLP" "$M1KA_FLV" "$M1KA_NEST" "$M1KA_MLBR" "$M1KA_NAL" "$M1KA_ENQ" "$M1KA_QLT" "$M1KA_SLT" "$M1KA_DQE" "$M1KA_SQE" "$M1KA_TAG" "$M1KA_HQG" "$M1KA_NTG" "$M1KA_QGT" "$M1KA_PGT" "$M1KA_AFL" "$M1KA_AHN" "$M1KA_BNG" "$M1KA_LTR" "$M1KA_RHX" "$M1KA_RDC" "$M1KA_RNM"; do oth=$(( oth + $(m1eq_n strip_to_text_blocks "$rr" ruritanian) + $(m1eq_n strip_to_joined_text "$rr" ruritanian) )); done
  if [ "$rp" -eq 1 ] && [ "$pp" = "$M1EQ_PRJ" ] && [ "$rl" -eq 1 ] && [ "$pl" = "$M1EQ_PRJ" ] && [ "$rf" -eq 1 ] && [ "$pf" = "$M1EQ_PRJ" ] && [ "$rn" -eq 1 ] && [ "$pn" = "$M1EQ_PRJ" ] && [ "$rq" -eq 1 ] && [ "$pq" = "$M1EQ_PRJ" ] && [ "$rd" -eq 1 ] && [ "$pd" = "$M1EQ_PRJ" ] && [ "$ra" -eq 1 ] && [ "$pa" = "$M1EQ_PRJ" ] && [ "$rx" -eq 1 ] && [ "$px" = "$M1EQ_PRJ" ] && [ "$rt" -eq 1 ] && [ "$pt" = "$M1EQ_PRJ" ] && [ "$rs" -eq 1 ] && [ "$ps" = "$M1EQ_PRJ" ] && [ "$ra2" -eq 1 ] && [ "$pa2" = "$M1EQ_PRJ" ] && [ "$re" -eq 1 ] && [ "$pe" = "$M1EQ_PRJ" ] && [ "$rh" -eq 1 ] && [ "$ph" = "$M1EQ_PRJ" ] && [ "$rj" -eq 1 ] && [ "$pj" = "$M1EQ_PRJ" ] && [ "$rk" -eq 1 ] && [ "$pk" = "$M1EQ_PRJ" ] && [ "$ro" -eq 1 ] && [ "$po" = "$M1EQ_PRJ" ] && [ "$ry" -eq 1 ] && [ "$py" = "$M1EQ_PRJ" ] && [ "$rw" -eq 1 ] && [ "$pw" = "$M1EQ_PRJ" ] && [ "$re2" -eq 1 ] && [ "$pe2" = "$M1EQ_PRJ" ] && [ "$rs2" -eq 1 ] && [ "$ps2" = "$M1EQ_PRJ" ] && [ "$rd2" -eq 1 ] && [ "$pd2" = "$M1EQ_PRJ" ] && [ "$rq2" -eq 1 ] && [ "$pq2" = "$M1EQ_PRJ" ] && [ "$ri" -eq 1 ] && [ "$pi" = "$M1EQ_PRJ" ] && [ "$rv" -eq 1 ] && [ "$pv" = "$M1EQ_PRJ" ] && [ "$rn2" -eq 1 ] && [ "$pn2" = "$M1EQ_PRJ" ] && [ "$ru" -eq 1 ] && [ "$pu" = "$M1EQ_PRJ" ] && [ "$rz" -eq 1 ] && [ "$pz" = "$M1EQ_PRJ" ] && [ "$rb" -eq 1 ] && [ "$pb" = "$M1EQ_PRJ" ] && [ "$rg" -eq 1 ] && [ "$pg" = "$M1EQ_PRJ" ] && [ "$rf2" -eq 1 ] && [ "$pf2" = "$M1EQ_PRJ" ] && [ "$rl2" -eq 1 ] && [ "$pl2" = "$M1EQ_PRJ" ] && [ "$rhx" -eq 1 ] && [ "$phx" = "$M1EQ_PRJ" ] && [ "$rdc" -eq 1 ] && [ "$pdc" = "$M1EQ_PRJ" ] && [ "$rnm" -eq 1 ] && [ "$pnm" = "$M1EQ_PRJ" ] && [ "$mp" = "0" ] && [ "$ml" = "0" ] && [ "$mf" = "0" ] && [ "$mn" = "0" ] && [ "$mq" = "0" ] && [ "$md" = "0" ] && [ "$ma" = "0" ] && [ "$mx" = "0" ] && [ "$mt" = "0" ] && [ "$ms" = "0" ] && [ "$ma2" = "0" ] && [ "$me" = "0" ] && [ "$mh" = "0" ] && [ "$mj" = "0" ] && [ "$mk" = "0" ] && [ "$mo" = "0" ] && [ "$my" = "0" ] && [ "$mw" = "0" ] && [ "$me2" = "0" ] && [ "$ms2" = "0" ] && [ "$md2" = "0" ] && [ "$mq2" = "0" ] && [ "$mi" = "0" ] && [ "$mv" = "0" ] && [ "$mn2" = "0" ] && [ "$mu" = "0" ] && [ "$mz" = "0" ] && [ "$mb" = "0" ] && [ "$mg" = "0" ] && [ "$mf2" = "0" ] && [ "$ml2" = "0" ] && [ "$mhx" = "0" ] && [ "$mdc" = "0" ] && [ "$mnm" = "0" ] && [ "$oth" -eq 0 ]; then
    PASS "M1q: listed inline tags that carry attributes are read as tags — the pop-up note written with span classes inside a script string aborts as a HIT (rc=$rp) named '$pp', the checklist rule written with class=\"\" on its b tags aborts (rc=$rl), and so do the pop-up held in an attribute value whose quotes are written as character references (rc=$rf), the one whose spans set their attributes on the next line (rc=$rn), the one whose quoted class values run over a line (rc=$rq), the one whose spans carry a \${…} placeholder (rc=$rd), the pop-ups whose quotes are decimal and hexadecimal references (rc=$ra, rc=$rx), the tooltip whose quotes are &#39; (rc=$rt), the pop-up whose class values are single-quoted (rc=$rs), and the next-line pop-ups with a value written &- (rc=$ra2) and with a single-quoted and an entity-quoted value (rc=$re); where the precise read cannot reach the tag's '>', the text up to the last '>' before the next tag, else up to the next '>', is read as the list, so the spans whose placeholder stands on the next line alone (rc=$rh) or as a value (rc=$rj), whose placeholder's braces nest (rc=$rk) or run over a line (rc=$ro), whose next line starts with a word no list carries (rc=$ry), the pop-up whose entity-quoted value runs over a line (rc=$rw) and the image with no tag after it in its string (rc=$rn2) abort too, and so do the spans whose list holds a quoted '>' (rc=$ru), a placeholder's '>' (rc=$rz), an arrow function on the next line (rc=$rb) or nested on the head line (rc=$rg), and a quoted '>' ahead of a comment (rc=$rf2) or of an opening tag (rc=$rl2); the precise read takes whole the spans whose quoted value holds a '<' in double quotes (rc=$re2), in single quotes (rc=$rs2), escaped inside a double-quoted (rc=$rd2) and a single-quoted script string (rc=$rq2), the spans whose quoted values hold a '>' and then a tag's '<' (rc=$ri), and the head-line list holding a quoted '>' (rc=$rv), and the spans whose list holds a quoted '>' and values quoted with hexadecimal, decimal and named references, with a comparison's '<' after the list, one cell per reference form (rc=$rhx, rc=$rdc, rc=$rnm), so those abort as well; ARMED-RED — with the attribute-list read taken out of the helper all thirty-four publish (rc=$mp, rc=$ml, rc=$mf, rc=$mn, rc=$mq, rc=$md, rc=$ma, rc=$mx, rc=$mt, rc=$ms, rc=$ma2, rc=$me, rc=$mh, rc=$mj, rc=$mk, rc=$mo, rc=$my, rc=$mw, rc=$me2, rc=$ms2, rc=$md2, rc=$mq2, rc=$mi, rc=$mv, rc=$mn2, rc=$mu, rc=$mz, rc=$mb, rc=$mg, rc=$mf2, rc=$ml2, rc=$mhx, rc=$mdc, rc=$mnm). The visible and joined arms carry the key tokens $oth time(s)"
  else
    FAIL "M1q: span-class pop-up note rc=$rp '$pp', class=\"\" checklist rule rc=$rl '$pl', character-reference pop-up rc=$rf '$pf', attributes on the next line rc=$rn '$pn', quoted values over a line rc=$rq '$pq', \${…} placeholder rc=$rd '$pd', decimal references rc=$ra '$pa', hexadecimal references rc=$rx '$px', &#39; tooltip rc=$rt '$pt', single-quoted class values rc=$rs '$ps', next-line &- value rc=$ra2 '$pa2', next-line single- and entity-quoted values rc=$re '$pe', next-line placeholder rc=$rh '$ph', next-line placeholder value rc=$rj '$pj', nested placeholder braces rc=$rk '$pk', placeholder over a line rc=$ro '$po', next line no list rc=$ry '$py', entity-quoted value over a line rc=$rw '$pw', quoted '<' in double quotes rc=$re2 '$pe2', quoted '<' in single quotes rc=$rs2 '$ps2', escaped double-quoted '<' rc=$rd2 '$pd2', escaped single-quoted '<' rc=$rq2 '$pq2', quoted '>' then a tag's '<' rc=$ri '$pi', head-line quoted '>' rc=$rv '$pv', image with no tag after it rc=$rn2 '$pn2', next-line list with a quoted '>' rc=$ru '$pu', next-line placeholder holding '>' rc=$rz '$pz', arrow function on the next line rc=$rb '$pb', arrow function nested on the head line rc=$rg '$pg', quoted '>' ahead of a comment rc=$rf2 '$pf2', quoted '>' ahead of an opening tag rc=$rl2 '$pl2', quoted '>' with hexadecimal-, decimal- and named-reference values and a comparison's '<' after the list rc=$rhx '$phx', rc=$rdc '$pdc' and rc=$rnm '$pnm' (want 1 and '$M1EQ_PRJ' for each); without the attribute-list read rc=$mp, rc=$ml, rc=$mf, rc=$mn, rc=$mq, rc=$md, rc=$ma, rc=$mx, rc=$mt, rc=$ms, rc=$ma2, rc=$me, rc=$mh, rc=$mj, rc=$mk, rc=$mo, rc=$my, rc=$mw, rc=$me2, rc=$ms2, rc=$md2, rc=$mq2, rc=$mi, rc=$mv, rc=$mn2, rc=$mu, rc=$mz, rc=$mb, rc=$mg, rc=$mf2, rc=$ml2, rc=$mhx, rc=$mdc and rc=$mnm (want 0 for each); key tokens on the other arms $oth (want 0). A kept tag's attribute names break a value up inside those surfaces again, or this arm can no longer tell"
  fi
}
m1iq_assert
m1ir_assert() { # one verdict
  local re rn rv rt rl pl rb pb rx rg pg ry rh rq rk ro po rf pf rw pw rwn pwn rcz pcz me mn mv mt mx my mh mq mk mcz oth rr
  mguard "$M1KA_EQ" "$MTD"; re="$MRC"
  mguard "$M1KA_EQN" "$MTD"; rn="$MRC"
  mguard "$M1KA_EQV" "$MTD"; rv="$MRC"
  mguard "$M1KA_EQT" "$MTD"; rt="$MRC"
  mguard "$M1KA_EQL" "$MTD"; rx="$MRC"
  mguard "$M1KA_TYP" "$M1KA_TD"; ry="$MRC"
  mguard "$M1KA_EQM" "$MTD"; rh="$MRC"
  mguard "$M1KA_TYS" "$M1KA_TD"; rq="$MRC"
  mguard "$M1KA_LIC" "$M1KA_CD"; rk="$MRC"
  mguard "$M1KA_LT" "$MTD"; rl="$MRC"; pl="$(m1eq_prj)" || pl="NONE"
  mguard "$M1KA_LTB" "$MTD"; rb="$MRC"; pb="$(m1eq_prj)" || pb="NONE"
  mguard "$M1KA_NGT" "$MTD"; rg="$MRC"; pg="$(m1eq_prj)" || pg="NONE"
  mguard "$M1KA_CLT" "$MTD"; ro="$MRC"; po="$(m1eq_prj)" || po="NONE"
  mguard "$M1KA_PLT" "$MTD"; rf="$MRC"; pf="$(m1eq_prj)" || pf="NONE"
  rw="$( ulimit -t 5; verify_publishable_content "$M1KA_WS" "$MTD" >/dev/null 2>"$MOUT"; printf '%s' "$?" )"; pw="$(m1eq_prj)" || pw="NONE"
  rwn="$( ulimit -t 5; verify_publishable_content "$M1KA_WSN" "$MTD" >/dev/null 2>"$MOUT"; printf '%s' "$?" )"; pwn="$(m1eq_prj)" || pwn="NONE"
  mguard "$M1KA_CMZ" "$MTD"; rcz="$MRC"; pcz="$(m1eq_prj)" || pcz="NONE"
  me="$(m1ka_off "$M1KA_EQ" "$MTD")"; mn="$(m1ka_off "$M1KA_EQN" "$MTD")"; mv="$(m1ka_off "$M1KA_EQV" "$MTD")"
  mt="$(m1ka_off "$M1KA_EQT" "$MTD")"; mx="$(m1ka_off "$M1KA_EQL" "$MTD")"; my="$(m1ka_off "$M1KA_TYP" "$M1KA_TD")"
  mh="$(m1ka_off "$M1KA_EQM" "$MTD")"; mq="$(m1ka_off "$M1KA_TYS" "$M1KA_TD")"; mk="$(m1ka_off "$M1KA_LIC" "$M1KA_CD")"
  mcz="$(m1kc_off "$M1KA_CMZ" "$MTD")"
  oth=$(( $(m1eq_n strip_to_text_blocks "$M1KA_TYP" type) + $(m1eq_n strip_to_joined_text "$M1KA_TYP" type) + $(m1eq_n strip_to_text_blocks "$M1KA_TYS" type) + $(m1eq_n strip_to_joined_text "$M1KA_TYS" type) + $(m1eq_n strip_to_text_blocks "$M1KA_LIC" class) + $(m1eq_n strip_to_joined_text "$M1KA_LIC" class) ))
  for rr in "$M1KA_EQ" "$M1KA_EQN" "$M1KA_EQV" "$M1KA_EQT" "$M1KA_EQL" "$M1KA_EQM" "$M1KA_LT" "$M1KA_LTB" "$M1KA_NGT" "$M1KA_CLT" "$M1KA_PLT" "$M1KA_WS" "$M1KA_WSN" "$M1KA_CMZ"; do oth=$(( oth + $(m1eq_n strip_to_text_blocks "$rr" ruritanian) + $(m1eq_n strip_to_joined_text "$rr" ruritanian) )); done
  if [ "$re" -eq 0 ] && [ "$rn" -eq 0 ] && [ "$rv" -eq 0 ] && [ "$rt" -eq 0 ] && [ "$rx" -eq 0 ] && [ "$ry" -eq 0 ] && [ "$rh" -eq 0 ] && [ "$rq" -eq 0 ] && [ "$rk" -eq 0 ] && [ "$rl" -eq 1 ] && [ "$pl" = "$M1EQ_PRJ" ] && [ "$rb" -eq 1 ] && [ "$pb" = "$M1EQ_PRJ" ] && [ "$rg" -eq 1 ] && [ "$pg" = "$M1EQ_PRJ" ] && [ "$ro" -eq 1 ] && [ "$po" = "$M1EQ_PRJ" ] && [ "$rf" -eq 1 ] && [ "$pf" = "$M1EQ_PRJ" ] && [ "$rw" = "1" ] && [ "$pw" = "$M1EQ_PRJ" ] && [ "$rwn" = "1" ] && [ "$pwn" = "$M1EQ_PRJ" ] && [ "$rcz" -eq 1 ] && [ "$pcz" = "$M1EQ_PRJ" ] && [ "$me" = "1" ] && [ "$mn" = "1" ] && [ "$mv" = "1" ] && [ "$mt" = "1" ] && [ "$mx" = "1" ] && [ "$my" = "1" ] && [ "$mh" = "1" ] && [ "$mq" = "1" ] && [ "$mk" = "1" ] && [ "$mcz" = "0" ] && [ "$oth" -eq 0 ]; then
    PASS "M1r: the stated price of reading a kept tag's attribute list — a word written directly before '=' after '<b' is dropped as an attribute name wherever it stands inside the text read as the tag's list, as the shipped guard dropped it, and that render publishes (rc=$re), as do the comment that holds that word as an attribute on the line after its '<b' (rc=$rn), the one whose quoted value after '=' runs over a line (rc=$rv), the same comparison closed by ')' with a '>' later in the script (rc=$rt), a comparison whose next line is no attribute list (rc=$rx) and a loop whose assignment stands before the last '>' ahead of markup later in the script (rc=$rh); a member named like an attribute that a list over lines carries does not abort the page, written in double quotes with a tag after the list (rc=$ry) or in single quotes with none (rc=$rq), nor does one named like the attribute an arrow function's list carries ahead of a closing tag (rc=$rk); a run that meets a '<' first aborts as a HIT (rc=$rl) named '$pl', and so do the same '<' written inside a \${…} placeholder (rc=$rb), a comparison with no '>' after it (rc=$rg), a comparison whose first '>' comes before the word with only a comparison's '<' after it (rc=$ro), a comparison closed by ')' with a quoted '<' after it (rc=$rf), a kept head followed by lines of nothing but spaces (rc=$rw) or by lines that each hold a name and then spaces (rc=$rwn), each read under a five-second CPU cap, and a comment left open to the end of the page, read to that end as a comment body (rc=$rcz); ARMED-RED — with the attribute-list read taken out of the helper the nine priced renders abort (rc=$me, rc=$mn, rc=$mv, rc=$mt, rc=$mx, rc=$mh, rc=$my, rc=$mq, rc=$mk), so their publish is that read's doing, and with the comment tokenizer's end-of-input branch taken out the open comment publishes (rc=$mcz), so its abort is that branch's doing. The visible and joined arms carry the key tokens $oth time(s)"
  else
    FAIL "M1r: the '=' render after '<b' rc=$re, its next-line form rc=$rn, its value-over-a-line form rc=$rv, the comparison closed by ')' rc=$rt, the comparison whose next line is no attribute list rc=$rx, the loop priced up to the markup after it rc=$rh, and the pages whose lists carry an attribute named like a member rc=$ry, rc=$rq and rc=$rk (want 0 for each, the stated price), the run that meets a '<' rc=$rl '$pl', the '<' inside a \${…} placeholder rc=$rb '$pb', the comparison with no '>' after it rc=$rg '$pg', the comparison whose first '>' comes before the word rc=$ro '$po', the comparison closed by ')' with a quoted '<' after it rc=$rf '$pf', the kept head followed by lines of spaces under a five-second CPU cap rc=$rw '$pw', the kept head followed by lines of a name and spaces under the same cap rc=$rwn '$pwn' and the comment left open to the end of the page rc=$rcz '$pcz' (want 1 and '$M1EQ_PRJ' for each), without the attribute-list read rc=$me, rc=$mn, rc=$mv, rc=$mt, rc=$mx, rc=$mh, rc=$my, rc=$mq and rc=$mk (want 1 for each), without the comment tokenizer's end-of-input branch rc=$mcz (want 0), key tokens on the other arms $oth (want 0). The price the RESIDUAL states is no longer the one the code pays, the read stalls on whitespace, or this arm can no longer tell"
  fi
}
m1ir_assert
M1IS_TAGS='a abbr area audio b bdi bdo button canvas cite code data datalist del dfn em embed i iframe img input ins kbd label link map mark math meta meter noscript object output picture progress q ruby s samp script select selectedcontent slot small span strong sub sup svg template textarea time u var video wbr'
M1IS_R="$WORK/m1is_list.html"
{ printf '%s' '<!-- '; for m1is_t in $M1IS_TAGS; do printf '<%s>zq</%s> ' "$m1is_t" "$m1is_t"; done; printf '%s\n' '-->'; } > "$M1IS_R"
m1is_n() { "$1" "$2" | _decode_entities | _norm_words | awk -v L=" $M1IS_TAGS " 'index(L, " " $0 " ") > 0 { c++ } END { print c + 0 }'; }   # <projection> <render> -> listed names in its stream
m1is_assert() { # one verdict
  local nt nl nz mo
  nt="$(printf '%s' "$M1IS_TAGS" | awk '{ print NF }')"
  nl="$(m1is_n strip_to_published_text "$M1IS_R")"
  nz="$(m1eq_n strip_to_published_text "$M1IS_R" zq)"
  mo="$( eval "$(declare -f strip_to_published_text | sed 's/|\$_GUARD_INLINE_TAGS//')"; m1is_n strip_to_published_text "$M1IS_R" )"
  if [ "$nt" -eq 56 ] && [ "$nz" -eq "$nt" ] && [ "$nl" -eq 0 ] && [ "$mo" -eq $((2 * nt)) ]; then
    PASS "M1s: every name of HTML's phrasing content ($nt, from this file's own copy) written as a tag inside a comment body stays markup — 0 listed names reach the published stream while all $nz zq words do; ARMED-RED — with the inline list taken out of the helper $mo listed names reach it, two for each tag"
  else
    FAIL "M1s: names in the copy $nt (want 56), zq words $nz (want $nt), listed names in the published stream $nl (want 0), with the inline list taken out $mo (want $((2 * nt))). A phrasing element left off _GUARD_INLINE_TAGS reads as text inside those surfaces again, or this arm can no longer tell"
  fi
}
m1is_assert

# ── M1t–M1u (#2055) — a <script> or <style> body ends at its closing tag, spaced or not ──
#
# A browser ends a script or style body at `</script >`, whitespace before the `>`, as it does at
# `</script>`. The published projection ended the body at an exact closing tag only, so after a
# spaced one it read the rest of the page as body text, up to the next exact closing tag or the
# end of the file. A tag on neither list met there was read as text, its name between the words
# around it (M1t), and every tag name met there reached its stream (M1u). The visible and joined
# projections still end the body at an exact closing tag (the comment above strip_to_text_blocks
# says why), so on M1t's renders they delete the stretch from the spaced closing tag to the next
# exact one, value and all, and the published arm is the one that reads it. M1t grades the value:
# a page whose need is split twice by `<font>` in that stretch, so that no five-word run survives
# the tag names, aborts as a HIT named for the published arm, in a script body and in a style
# body, and its exact-close twin aborts too. M1u grades the other direction: a member named
# Summary does not abort a page that writes `<details><summary>` after a spaced closing tag, and
# that page's published stream is its exact-close twin's, token for token. Each carries the defect
# inside the arm (ARMED-RED): the published projection's lookahead put back to the exact closing
# tag, in a subshell, must publish M1t's two spaced renders and abort M1u's.
M1T_V='cannot manage more than <font>one</font> flight of stairs <font>in</font> a single stretch'
M1T_SC="$WORK/m1t_script_spaced.html"; mrender "$M1T_SC" "<script>var a = 1;</script ><p>Note: $M1T_V.</p><script>var b = 2;</script>"
M1T_ST="$WORK/m1t_style_spaced.html";  mrender "$M1T_ST" "<style>.a{color:#333}</style ><p>Note: $M1T_V.</p><style>.b{color:#444}</style>"
M1T_EX="$WORK/m1t_script_exact.html";  mrender "$M1T_EX" "<script>var a = 1;</script><p>Note: $M1T_V.</p><script>var b = 2;</script>"
m1t_unfixed() { # <render> <trip_dir> -> the guard's status with the published lookahead put back to the exact closing tag
  # The fourth arm (ADR-050) reads what the mutated projection reads, for M1t's and M1u's
  # ARMED-RED and for M6d: it drops a tag on neither list by shape, so it would catch the leak page.
  ( eval "$(declare -f strip_to_published_text | sed 's#</\\3\\s\*>#</\\3>#')"
    strip_to_shape_text() { strip_to_published_text "$@"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
m1t_run() { # <projection> <render> -> how many times MV's twelve words stand in its stream as one run
  "$1" "$2" | _decode_entities | _norm_words | tr '\n' ' ' \
    | awk -v N=" $(printf '%s' "$MV" | _norm_words | tr '\n' ' ')" '{ s = " " $0; while ((i = index(s, N)) > 0) { c++; s = substr(s, i + length(N) - 1) } } END { print c + 0 }'
}
m1t_assert() { # one verdict
  local rs ps rt pt rx ms mt oth nf
  mguard "$M1T_SC" "$MTD"; rs="$MRC"; ps="$(m1eq_prj)" || ps="NONE"
  mguard "$M1T_ST" "$MTD"; rt="$MRC"; pt="$(m1eq_prj)" || pt="NONE"
  mguard "$M1T_EX" "$MTD"; rx="$MRC"
  ms="$(m1t_unfixed "$M1T_SC" "$MTD")"; mt="$(m1t_unfixed "$M1T_ST" "$MTD")"
  oth=$(( $(m1t_run strip_to_text_blocks "$M1T_SC") + $(m1t_run strip_to_joined_text "$M1T_SC") + $(m1t_run strip_to_text_blocks "$M1T_ST") + $(m1t_run strip_to_joined_text "$M1T_ST") ))
  nf="$(awk '{ c += gsub(/<font>/, "&") } END { print c + 0 }' "$M1T_SC" "$M1T_ST" "$M1T_EX")"
  if [ "$rs" -eq 1 ] && [ "$ps" = "$M1EQ_PRJ" ] && [ "$rt" -eq 1 ] && [ "$pt" = "$M1EQ_PRJ" ] && [ "$rx" -eq 1 ] && [ "$ms" = "0" ] && [ "$mt" = "0" ] && [ "$oth" -eq 0 ] && [ "$nf" -eq 6 ]; then
    PASS "M1t: a value written after a spaced closing tag is read — the need split twice by a tag on neither list, after '</script >', aborts as a HIT (rc=$rs) named '$ps', so does the same after '</style >' (rc=$rt), and the exact-close twin aborts too (rc=$rx); ARMED-RED — with the published lookahead put back to the exact closing tag both spaced renders publish (rc=$ms, rc=$mt). The visible and joined arms carry the need as one run $oth time(s) on the spaced renders, so the HIT is the published arm's"
  else
    FAIL "M1t: spaced script render rc=$rs '$ps', spaced style render rc=$rt '$pt' (want 1 and '$M1EQ_PRJ' for both), exact-close twin rc=$rx (want 1); with the lookahead put back rc=$ms and rc=$mt (want 0 and 0); the need as one run on the visible and joined arms $oth (want 0); splitting tags in the renders $nf (want 6). A value after a spaced closing tag publishes, or this arm can no longer tell"
  fi
}
m1t_assert
M1U_TD="$WORK/porto-summary"; mkdir -p "$M1U_TD/outputs"
cat > "$M1U_TD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Passport: Ruritanian, valid to 2033

## Summary [OPERATOR-PROVIDED] [THIRD-PARTY]

### Needs
- Category: mobility
  Specific: needs a bench to rest on at every stop along the way
  Applies to: ## Hard Constraints → "Mobility"
MD
M1U_SP="$WORK/m1u_spaced.html"; mrender "$M1U_SP" '<script>var a = 1;</script ><details><summary>Rainy-day options</summary>the tile museum</details>'
M1U_EX="$WORK/m1u_exact.html";  mrender "$M1U_EX" '<script>var a = 1;</script><details><summary>Rainy-day options</summary>the tile museum</details>'
m1u_stream() { strip_to_published_text "$1" | _decode_entities | _norm_words | tr '\n' ' '; }   # <render> -> its published stream on one line
m1u_assert() { # one verdict
  local rs rx ss sx ms mss same=no moved=no
  mguard "$M1U_SP" "$M1U_TD"; rs="$MRC"
  mguard "$M1U_EX" "$M1U_TD"; rx="$MRC"
  ss="$(m1u_stream "$M1U_SP")"; sx="$(m1u_stream "$M1U_EX")"
  ms="$(m1t_unfixed "$M1U_SP" "$M1U_TD")"
  mss="$( eval "$(declare -f strip_to_published_text | sed 's#</\\3\\s\*>#</\\3>#')"; m1u_stream "$M1U_SP" )"
  [ -n "$sx" ] && [ "$ss" = "$sx" ] && same=yes
  [ -n "$mss" ] && [ "$mss" != "$sx" ] && moved=yes
  if [ "$rs" -eq 0 ] && [ "$rx" -eq 0 ] && [ "$same" = "yes" ] && [ "$ms" = "1" ] && [ "$moved" = "yes" ]; then
    PASS "M1u: the markup after a spaced closing tag is read as markup — a member named Summary does not abort a page that writes '<details><summary>' after '</script >' (rc=$rs), as its exact-close twin does not (rc=$rx), and the two published streams are the same, token for token; ARMED-RED — with the published lookahead put back to the exact closing tag the spaced render aborts (rc=$ms) and its stream differs"
  else
    FAIL "M1u: spaced render rc=$rs, exact-close twin rc=$rx (want 0 and 0); published streams the same: $same (want yes); with the lookahead put back rc=$ms (want 1) and its stream differing: $moved (want yes). Tag names after a spaced closing tag reach the published stream again, or this arm can no longer tell"
  fi
}
m1u_assert

# ── M1x–M1y (#2055) — a value inside a body whose ONLY closing tag carries a space ──
#
# The visible and joined projections end a <script> or <style> body at an exact closing tag, so a
# body whose only closing tag is written with a space is not deleted there: they read it as
# visible text. The guard before 0.60.0 blocked a value written inside such a body through that
# reading, and so does the guard at the base: a value split mid-word by an inline tag is closed up
# by the joined arm (M1x), and a value around one of whose words a tag carries attribute-value
# words is read whole by the visible arm (M1y). The published arm alone reads neither, because
# inside a body a mid-word split stays split and a kept tag's attribute values stay as text, so
# each exact-close twin, whose body the visible and joined projections delete, publishes. Each
# need is split twice, so that no five-word run survives on the published arm. Each arm carries the
# change it guards against inside the arm (ARMED-RED): the visible and joined projections made to
# end a body at a spaced closing tag too, in a subshell, must publish its render — that change
# would give up this class, which is why it is not made (the comment above strip_to_text_blocks).
M1X_SP="$WORK/m1x_spaced.html"; mrender "$M1X_SP" "<script>var s = 'Note: cannot manage more than o<b>ne</b> flight of stairs i<b>n</b> a single stretch';</script >"
M1Y_SP="$WORK/m1y_spaced.html"; mrender "$M1Y_SP" "<script>var s = 'Note: cannot manage more than <span title=\"see note\">one</span> flight of stairs <span title=\"see note\">in</span> a single stretch';</script >"
M1X_EX="$WORK/m1x_exact.html"; sed 's#</script >#</script>#' "$M1X_SP" > "$M1X_EX"
M1Y_EX="$WORK/m1y_exact.html"; sed 's#</script >#</script>#' "$M1Y_SP" > "$M1Y_EX"
m1bc_off() { # <render> <trip_dir> -> the guard's status with the visible and joined readers ending a body at a spaced closing tag too
  ( eval "$(declare -f strip_to_text_blocks | sed 's#</\\1>#</\\1\\s*>#')"
    eval "$(declare -f strip_to_joined_text | sed 's#</\\1>#</\\1\\s*>#')"
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
m1bc_assert() { # <id> <shape> <spaced render> <exact-close twin> <the projection its abort names> — one verdict
  local id="$1" what="$2" sp="$3" tw="$4" want="$5" rs ps rt ms ks kt dz
  mguard "$sp" "$MTD"; rs="$MRC"; ps="$(m1eq_prj)" || ps="NONE"
  mguard "$tw" "$MTD"; rt="$MRC"
  ms="$(m1bc_off "$sp" "$MTD")"
  ks="$(awk '{ c += gsub(/<\/script >/, "&") } END { print c + 0 }' "$sp")"; kt="$(awk '{ c += gsub(/<\/script >/, "&") } END { print c + 0 }' "$tw")"
  dz=$(( $(wc -c < "$sp") - $(wc -c < "$tw") ))
  if [ "$rs" -eq 1 ] && [ "$ps" = "$want" ] && [ "$rt" -eq 0 ] && [ "$ms" = "0" ] && [ "$ks" -eq 1 ] && [ "$kt" -eq 0 ] && [ "$dz" -eq 1 ]; then
    PASS "$id: $what inside a <script> body whose only closing tag carries a space still aborts as a HIT (rc=$rs) named '$ps', as before 0.60.0; its exact-close twin, one byte shorter, publishes (rc=$rt), so the abort is that reading of the body; ARMED-RED — with the visible and joined readers ending a body at a spaced closing tag too the page publishes (rc=$ms)"
  else
    FAIL "$id: $what inside a body closed only with a space — spaced render rc=$rs '$ps' (want 1 and '$want'), exact-close twin rc=$rt (want 0), with the visible and joined readers ending a body at a spaced closing tag rc=$ms (want 0); spaced closing tags in the render $ks and in the twin $kt (want 1 and 0), bytes between them $dz (want 1). A class of pages the guard before 0.60.0 blocked publishes, or this arm can no longer tell"
  fi
}
m1bc_assert M1x "a value split mid-word by an inline tag"            "$M1X_SP" "$M1X_EX" 'joined markup (an inline tag split a word)'
m1bc_assert M1y "a value with an attribute-carrying tag around a word" "$M1Y_SP" "$M1Y_EX" 'visible text'

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

# ── M4 (CD-4) — the DURABLE source: the cross-trip person record ─────────────
# M3 bound the class to the trip's own first-party files. CD-4 is the same defect one
# scope out: a referenced person record is a durable source living OUTSIDE the trip, so a
# passport edited only in the library leaves every file under the trip untouched and every
# M3 comparison reads fresh while the projection is behind its real source set.
#
# THE STORE IS AT THE TRIP ROOT, DELIBERATELY. Store-root resolution is trip-root-first
# (reference/data-model.md -> "Composition — the trip-side read of a durable record"),
# so this fixture is self-contained. A fixture that reached the rule's second step would
# depend on which store that step finds, and that differs between an author's machine and
# CI — a witness whose verdict depends on the operator's private working directory is not
# a witness. It therefore depends on no tracked example fixture either.
#
# M4d IS THE LOAD-BEARING ARM, and it is worth saying which one and why. The partial
# landing that puts a fence row in without widening the evaluator is the LOUDEST possible
# failure — it aborts before the model is opened and turns this whole file red, so it
# cannot reach a merge through a green run. The dangerous partial is the inverse: an
# evaluator and a store with NO fence row is green, silent, and is the fail-open itself.
# M4b grades the clock; only M4d grades the CLASS, so only M4d fails on that partial.
MPPL="$WORK/porto-people"; mkdir -p "$MPPL/outputs" "$MPPL/travelers" "$MPPL/people"
cat > "$MPPL/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Interests: markets, museums
MD
# The traveller file carries the reference and NO PERSON-scoped field: the durable half of
# the profile lives in the record, which is the composition this class exists to express.
cat > "$MPPL/travelers/rowan.md" <<'MD'
---
artifact: travelers/<traveler>.md
schema-version: 1
trip: porto-2029
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal
person: psn-a1b2
---

# Rowan

## Getting there & back
- **Leaving from:** Central Station
MD
cat > "$MPPL/people/psn-a1b2.md" <<'MD'
---
artifact: people/<person>.md
schema-version: 1
trip: cross-trip
writer: human
lifecycle: persist-mutable
provenance: human
publish: internal-hard
---

# Rowan

## Getting there & back
- **Passport:** Ruritanian, valid to 2033
MD
MPPLR="$WORK/m_people.html"
mrender "$MPPLR" '<p>Evening: the riverside lantern walk, then back to the guest house.</p>'
# mtimes with touch -t, never write order — M3's rule, and it governs here verbatim.
# The TRAVELLER FILE IS PINNED NOT-NEWER THAN THE MODEL, which is what makes an rc=2 in
# M4b attributable to the record alone and not to the pre-existing profile comparison.
touch -t 202601010900 "$MPPLR"
touch -t 202601011000 "$MPPL/outputs/traveler-model.md"
touch -t 202601011000 "$MPPL/travelers/rowan.md"
touch -t 202601011100 "$MPPL/people/psn-a1b2.md"
if grep -qF 'Passport:' "$MPPL/people/psn-a1b2.md" \
   && ! grep -qF 'Passport' "$MPPL/outputs/traveler-model.md" \
   && ! grep -qF 'Passport' "$MPPL/travelers/rowan.md" \
   && grep -qF '## Rowan' "$MPPL/outputs/traveler-model.md" \
   && grep -qF 'person: psn-a1b2' "$MPPL/travelers/rowan.md" \
   && ! grep -qF 'Ruritanian' "$MPPLR" && ! grep -qF '2033' "$MPPLR"; then
  PASS "M4a: the passport exists ONLY in the person record — absent from the model, absent from the traveller file, absent from the render — and the traveller file is not newer than the model"
else
  FAIL "M4a: the person-record fixture is not set up as claimed — M4b and M4d would prove nothing"
fi
mguard "$MPPLR" "$MPPL"
if [ "$MRC" -eq 2 ]; then PASS "M4b: a durable edit made ONLY in the person library, with no trip-side change, aborts the publish as UNDETERMINED (rc=2) — the freshness walk follows the reference out of the trip"; else FAIL "M4b: a person record newer than the [DERIVED] model was read as a determinate result (rc=$MRC) — silent fail-open on an irreversible action"; fi

# M4c — SPECIFICITY. Without it M4b is satisfied by a guard that aborts unconditionally on
# any trip carrying a reference. M3e's role, for the new source.
touch -t 202601011200 "$MPPL/outputs/traveler-model.md"
mguard "$MPPLR" "$MPPL"
if [ "$MRC" -eq 0 ]; then PASS "M4c: the same trip with the model newest publishes (rc=0) — the walk gates on the comparison, it does not blanket-abort a trip that references a record"; else FAIL "M4c: a clean, fresh trip referencing a person record was blocked (rc=$MRC) — the walk is unusable, which is fail-open in practice"; fi

# M4d — THE CLASS, NOT THE CLOCK. THE LOAD-BEARING ARM. The model stays newest so the
# freshness comparison CANNOT fire; the only way to reach rc=1 is for the record's
# Passport to be in class (the declaration's row) AND to be read (the evaluator's third
# parse). This is M3c/M3d's role for the new scope, and it is the one arm that fails if
# the fence row is ever separated from the evaluator that queries it.
MPPLH="$WORK/m_people_hit.html"
mrender "$MPPLH" '<p>Border note: carry your Ruritanian passport, valid to 2033, at all times.</p>'
touch -t 202601011100 "$MPPLH"
if grep -qF 'Ruritanian passport, valid to 2033' "$MPPLH" \
   && ! grep -qF 'Ruritanian' "$MPPL/outputs/traveler-model.md" \
   && ! grep -qF 'Ruritanian' "$MPPL/travelers/rowan.md"; then
  PASS "M4d-fix: the render carries the passport value and neither the model nor the traveller file does — a hit here can only come from the person record"
else
  FAIL "M4d-fix: the class-arm fixture is not set up as claimed — M4d would prove nothing"
fi
mguard "$MPPLH" "$MPPL"
if [ "$MRC" -eq 1 ]; then PASS "M4d: a passport held ONLY in a person record is matched against the render (rc=1) with the model newest — the class reads durable sources, so the declaration row and the evaluator that queries it are BOTH present"; else FAIL "M4d: a passport held only in a person record did not abort (rc=$MRC) — a durable value sits in no fence row or in no parse, which is the silent fail-open no other arm in this file detects"; fi

# M4e — AC5, THE NO-REFERENCE CONTROL. A trip carrying no reference is unaffected by the
# store, including when the store does not exist. This is the clause that keeps the first
# run after the store shipped from aborting every trip in the working directory: the
# store is read ONLY after a bearer has produced a well-formed key.
MPNR="$WORK/porto-noref"; mkdir -p "$MPNR/outputs" "$MPNR/travelers"
cat > "$MPNR/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2029 [DERIVED]

## Rowan
- Interests: markets, museums
MD
cat > "$MPNR/travelers/rowan.md" <<'MD'
# Rowan — traveler profile

## Getting there & back
- **Leaving from:** Central Station
MD
MPNRR="$WORK/m_noref.html"
mrender "$MPNRR" '<p>Evening: the riverside lantern walk, then back to the guest house.</p>'
touch -t 202601010900 "$MPNRR"
touch -t 202601011000 "$MPNR/travelers/rowan.md"
touch -t 202601011200 "$MPNR/outputs/traveler-model.md"
if ! grep -q '^person:' "$MPNR/travelers/rowan.md" && [ ! -d "$MPNR/people" ]; then
  PASS "M4e-fix: the second trip carries no reference key and no store directory — the AC5 control is real"
else
  FAIL "M4e-fix: the no-reference fixture is not set up as claimed — M4e would prove nothing"
fi
mguard "$MPNRR" "$MPNR"
if [ "$MRC" -eq 0 ]; then PASS "M4e: a trip carrying NO reference publishes (rc=0) with no store present — an unreadable store never degrades a trip that references nothing"; else FAIL "M4e: a non-referencing trip was blocked (rc=$MRC) — an absent store is degrading trips it must not reach, which aborts every trip in the working directory"; fi

# M4f — AC3, UNRESOLVABLE IS NOT CLEAN. Paired with M4e, which is its control: the two
# together separate "unresolvable is undetermined" from "unresolvable is clean". Without
# the pair, a walk that quietly skipped every reference would satisfy M4e alone.
MPDG="$WORK/porto-dangling"; mkdir -p "$MPDG/outputs" "$MPDG/travelers" "$MPDG/people"
cp "$MPPL/outputs/traveler-model.md" "$MPDG/outputs/traveler-model.md"
sed 's/^person: psn-a1b2$/person: psn-9999/' "$MPPL/travelers/rowan.md" > "$MPDG/travelers/rowan.md"
MPDGR="$WORK/m_dangling.html"
mrender "$MPDGR" '<p>Evening: the riverside lantern walk, then back to the guest house.</p>'
touch -t 202601010900 "$MPDGR"
touch -t 202601011000 "$MPDG/travelers/rowan.md"
touch -t 202601011200 "$MPDG/outputs/traveler-model.md"
if grep -qF 'person: psn-9999' "$MPDG/travelers/rowan.md" && [ -d "$MPDG/people" ] \
   && [ ! -e "$MPDG/people/psn-9999.md" ]; then
  PASS "M4f-fix: the third trip names a well-formed id, the store exists, and the record does not — a DANGLING reference, not a malformed one"
else
  FAIL "M4f-fix: the dangling fixture is not set up as claimed — M4f would prove nothing"
fi
mguard "$MPDGR" "$MPDG"
if [ "$MRC" -eq 2 ]; then PASS "M4f: a well-formed reference resolving to no record aborts as UNDETERMINED (rc=2) — an unresolvable reference is not an empty class"; else FAIL "M4f: an unresolvable person reference was read as a determinate result (rc=$MRC) — an empty read is not an empty class"; fi

# ── M5 (#328 F4) — an ENCODING TRANSFORM must not carry a class value past the guard ──
#
# ADR-008 named three transforms it does not catch. Two of them are mechanical and a
# normalizer closes them; this is that normalizer, asserted. Measured on the shipped
# guard, against a verbatim control that aborted:
#   • `&#82;uritanian` — a numeric character reference. Every projection substitutes a
#     space for a tag but none decodes a reference, so _norm_words yields the two tokens
#     `82` and `uritanian` and the value is never matched. Published at rc=0.
#   • `Rurit<b>anian</b>` — an inline tag SPLITTING A WORD. Every projection substitutes
#     a SPACE for that tag, so the value normalizes to `rurit` + `anian`. Published at
#     rc=0.
# The remedies are different mechanisms because the two fail differently and carry
# opposite risks: _decode_entities is a filter on every arm, and strip_to_joined_text is
# a THIRD arm rather than an edit to an existing one — closing an inline tag up on the
# arm that carries the verdict would fuse two legitimate adjacent links into one false
# token, so the join happens on a stream nothing else reads and can only ADD matches.
#
# WHAT THIS GROUP ATTESTS IS ITS ENUMERATION, NOT THE MECHANISM BEHIND IT. The fixtures
# carry one class value in four renderings — verbatim, decimal reference, hex reference
# and a mid-word tag split — and each encoded one applies a SINGLE transform. A green M5b
# therefore says those four renderings abort. It does NOT say the decoder is wired to
# every arm, and it reaches no value COMPOSING two transforms in one word, because no
# fixture here builds one. The boundary is written down rather than left implied, so the
# attestation claims the control rather than the remedy the control was built for;
# widening it is a change to the fixture matrix and not to this wording.
#
# Every arm below grades an EXACT code and treats anything outside {0,1} as a probe
# failure rather than folding it into a verdict — with _decode_entities removed the
# visible arm empties and the guard returns 2, which is a DIFFERENT claim from "aborted".
M5V='Ruritanian'
m5render() { # <out_file> <final paragraph markup>
  cat > "$1" <<HTML
<!DOCTYPE html><html><head><title>Porto Trip</title></head><body>
<h1>Itinerary</h1>
<p>Day 1: arrive at the river station, drop bags at the guest house, then walk the
covered market for an hour before an early dinner at the counter two streets over.</p>
<p>Day 2: the harbour museum in the morning, a long lunch by the water, and the hill
gardens in the late afternoon when the light is best and the crowds have thinned.</p>
<p>$2</p>
</body></html>
HTML
}
M5VERB="$WORK/m5_verbatim.html"; m5render "$M5VERB" 'Border note: carry your Ruritanian passport, valid to 2033.'
M5DEC="$WORK/m5_dec.html";       m5render "$M5DEC"  'Border note: carry your &#82;uritanian passport, valid to 2033.'
M5HEX="$WORK/m5_hex.html";       m5render "$M5HEX"  'Border note: carry your &#x52;uritanian passport, valid to 2033.'
M5TAG="$WORK/m5_tag.html";       m5render "$M5TAG"  'Border note: carry your Rurit<b>anian</b> passport, valid to 2033.'
M5CLEAN="$WORK/m5_clean.html";   m5render "$M5CLEAN" 'Evening: the riverside lantern walk, then back to the guest house before ten.'
M5GLUE="$WORK/m5_glue.html";     m5render "$M5GLUE" 'We walked from <em>Dublin</em><em>Galway</em> road down to the river and back.'

# M5a — FIXTURE INTEGRITY, graded FIRST. Each encoded fixture must carry its encoded form
# and ZERO literal occurrences of the value: a fixture that still spelled the value
# outright would be re-testing the verbatim case under a new name. The verbatim control
# is graded in the same arm and must be non-zero, so the three zeros are measurements.
m5_bad=0; m5_detail=""
for m5pair in "dec:$M5DEC:&#82;uritanian" "hex:$M5HEX:&#x52;uritanian" "tag:$M5TAG:Rurit<b>anian</b>"; do
  m5n="${m5pair%%:*}"; m5rest="${m5pair#*:}"; m5f="${m5rest%%:*}"; m5needle="${m5rest#*:}"
  m5lit="$(grep -c "$M5V" "$m5f")"
  grep -qF "$m5needle" "$m5f" && m5has=1 || m5has=0
  [ "$m5lit" -eq 0 ] && [ "$m5has" -eq 1 ] || { m5_bad=$((m5_bad+1)); m5_detail="$m5_detail $m5n(lit=$m5lit,enc=$m5has)"; }
done
m5ctl="$(grep -c "$M5V" "$M5VERB")"
if [ "$m5_bad" -eq 0 ] && [ "$m5ctl" -ge 1 ]; then
  PASS "M5a: all 3 encoded fixtures carry their encoded form and ZERO literal occurrences of the class value, while the verbatim control carries it $m5ctl time(s) — the zeros are measurements and M5b is a real probe"
else
  FAIL "M5a: the encoding fixtures are not set up as claimed (bad:$m5_detail; verbatim control literal count=$m5ctl) — M5b would prove nothing"
fi

# M5b — THE SUBJECT. All four forms of the same value must abort. The verbatim arm is
# inside the same count deliberately: it is the shape that already aborted, so a run in
# which it stops aborting is a regression this arm sees rather than one it attributes to
# the encoding work.
m5_assert() {
  local f rc n=0 abort=0 bad=""
  for f in "$M5VERB" "$M5DEC" "$M5HEX" "$M5TAG"; do
    n=$((n+1)); verify_publishable_content "$f" "$MTD" >/dev/null 2>&1; rc=$?
    case "$rc" in 1) abort=$((abort+1)) ;; 0) bad="$bad $(basename "$f")=published" ;; *) bad="$bad $(basename "$f")=rc$rc" ;; esac
  done
  if [ "$abort" -eq "$n" ]; then
    PASS "M5b: the $n ENUMERATED renderings of one class value abort as a HIT (rc=1) — verbatim, decimal reference, hex reference and a mid-word tag split, a SINGLE transform in each encoded one. The claim is bounded by that enumeration and states nothing past it: it does not establish that the decoder is wired to every arm, and it does not reach a value composing two transforms in one word, because no fixture here builds one"
  else
    FAIL "M5b: only $abort/$n encodings aborted —$bad. A value that reaches the published page in an encoded form reaches it just as completely as one spelled out"
  fi
}
m5_assert

# M5c — SPECIFICITY, and the second arm is the one the third projection makes necessary.
# A clean render must still publish, and so must a render whose only unusual feature is
# two ADJACENT inline elements: `<em>Dublin</em><em>Galway</em>` is the same markup shape
# as a split word, and a joined arm that could not tell them apart would turn two
# legitimate links into one false token. This is the standing control on that risk.
m5_clean_assert() {
  local rc1 rc2
  verify_publishable_content "$M5CLEAN" "$MTD" >/dev/null 2>&1; rc1=$?
  verify_publishable_content "$M5GLUE"  "$MTD" >/dev/null 2>&1; rc2=$?
  if [ "$rc1" -eq 0 ] && [ "$rc2" -eq 0 ]; then
    PASS "M5c: the same render without the value publishes (rc=0), and so does one carrying two ADJACENT inline elements — the joined arm adds match opportunities without gluing legitimate neighbours into a false token"
  else
    FAIL "M5c: a clean render was blocked (clean rc=$rc1, adjacent-inline rc=$rc2) — the new projection over-matches ordinary markup"
  fi
}
m5_clean_assert

# M5d — THE LINE MAP, which is #326's L6 clause discharged at the point it binds. Every
# transform added to a projection must be line-count-preserving, or it shifts every
# reported line downstream of it while the token stream stays valid and the suite stays
# green. _decode_entities is one character away from violating it: `&#10;` and `&#13;`
# decode to newlines. The range restriction to printable ASCII is what makes that
# impossible, and this arm is what keeps the restriction from being quietly widened.
M5LINES="$WORK/m5_lines.html"
cat > "$M5LINES" <<'HTML'
<!DOCTYPE html><html><head><title>T</title></head><body>
<p>Filler line two here with several ordinary words in it.</p>
<script>
var a = "decoy line inside the script body";
var b = "another decoy line inside the script body";
</script>
<div
   class="multi
   line tag">
<p>Filler line nine with a Rurit<b>anian</b> split word and a &#82;ho entity.</p>
<p>Filler line ten.</p>
</div>
<p>Filler twelve.</p>
</body></html>
HTML
m5src="$(wc -l < "$M5LINES" | tr -d ' ')"
m5lj="$(strip_to_joined_text "$M5LINES" | _decode_entities | wc -l | tr -d ' ')"
m5lv="$(strip_to_text_blocks "$M5LINES" | _decode_entities | wc -l | tr -d ' ')"
m5lp="$(strip_to_published_text "$M5LINES" | _decode_entities | wc -l | tr -d ' ')"
m5ls="$(strip_to_shape_text "$M5LINES" | _decode_entities | wc -l | tr -d ' ')"
printf 'alpha &#10; beta &#13; gamma &#32; delta &#38; epsilon &#82;ho\n' > "$WORK/m5_adv.txt"
m5adv="$(_decode_entities < "$WORK/m5_adv.txt" | wc -l | tr -d ' ')"
if [ "$m5src" -ge 13 ] && [ "$m5lj" = "$m5src" ] && [ "$m5lv" = "$m5src" ] && [ "$m5lp" = "$m5src" ] && [ "$m5ls" = "$m5src" ] && [ "$m5adv" = "1" ]; then
  PASS "M5d: all four projections are line-count-preserving THROUGH the decoder — a $m5src-line render carrying a <script> block, a tag spanning three lines, a split word and a character reference yields $m5lj / $m5lv / $m5lp / $m5ls lines. The adversarial arm fires too: a single line of newline-yielding references (&#10;, &#13;) decodes to $m5adv line, so no locator downstream of an encoded value can shift"
else
  FAIL "M5d: a projection is no longer line-count-preserving (source=$m5src joined=$m5lj visible=$m5lv published=$m5lp shape=$m5ls; newline-reference arm=$m5adv, want 1). A transform that consumes a newline shifts every reported line after it while the token stream stays valid — the suite would not notice"
fi

# M5e — THE FAIL DIRECTION OF EACH NEW SUBJECT, and both directions are CLOSED. Removing
# _decode_entities empties the visible arm, the 20-word floor fires, and the verdict is
# rc=2 UNDETERMINED. Removing strip_to_joined_text fails the joined arm's pipeline; the
# guard reads that status and refuses the arm before any record is matched, and the verdict
# is rc=2 as well. A new arm inherits the posture of the guard it sits behind, and this arm
# is what makes that posture observable for both subjects: a removal that publishes would be
# the guard certifying a render one of its projections never read.
m5_dec_rc=0; m5_join_rc=0
m5_dec_rc="$( unset -f _decode_entities;    verify_publishable_content "$M5DEC" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
m5_join_rc="$( unset -f strip_to_joined_text; verify_publishable_content "$M5TAG" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
if [ "$m5_dec_rc" -eq 2 ] && [ "$m5_join_rc" -eq 2 ]; then
  PASS "M5e: both new subjects fail CLOSED when removed, and both are measured — without _decode_entities the entity case is rc=2 UNDETERMINED (the visible arm empties and the floor fires), and without strip_to_joined_text the tag-split case is rc=2 UNDETERMINED (the joined arm's failed status is refused). Neither removal can publish a render the guard did not read"
else
  FAIL "M5e: a removal did not fail closed (no decoder: rc=$m5_dec_rc want 2; no joined arm: rc=$m5_join_rc want 2) — rc=0 on either is the guard certifying a render one of its own projections never read"
fi

# ── M7a–M7h (#2068, ADR-050) — the guard's fourth arm, a reading by shape, read and credited last ──
#
# The published projection finds machinery by its place, which keeps a key token written directly
# before `=` (M1e–M1h), and so keeps as text words a page around a value can carry: a `word=`
# inside a quoted attribute value, a name read as text where a kept tag's list cannot be taken, a
# tag on neither list inside a script string. Those words push a value's own words apart, and a
# page the guard before 0.60.0 blocked published. The bytes such a page needs dropped and the bytes
# criterion 5 needs kept are the same shape, so no one reading holds both (ADR-050); the guard
# carries a fourth arm instead, strip_to_shape_text, the earlier published program with #2072's
# anchors, read last and credited last. Each arm grades its page against the guard as it stands
# and carries the defect inside it (ARMED-RED): with the fourth arm made to read what the published
# projection reads, in a subshell, the guard reads as it did before this change, and the page must
# publish again. A twin on the same fixture shows what the shape needs. Every page is rendered on
# group M's machinery-rich page against MTD, and every verdict is exact.
M7_PRJ='markup read by shape (every tag and attribute name dropped)'
m7_off() { # <render> <trip_dir> -> the guard's status with the fourth arm reading what the published projection reads
  ( strip_to_shape_text() { strip_to_published_text "$@"; }
    verify_publishable_content "$1" "$2" >/dev/null 2>&1; printf '%s' "$?" )
}
M7A_SP="$WORK/m7a_spans.html"; mrender "$M7A_SP" "<script>var pop = 'Note: cannot manage more than <span title=\"k= m=\">one</span> flight of stairs <span title=\"k= m=\">in</span> a single <span title=\"k= m=\">stretch</span>';</script>"
M7A_TW="$WORK/m7a_twin.html";  mrender "$M7A_TW" "<script>var pop = 'Note: cannot manage more than <span title=\"k m\">one</span> flight of stairs <span title=\"k m\">in</span> a single <span title=\"k m\">stretch</span>';</script>"
M7B_PP="$WORK/m7b_passport.html";   mrender "$M7B_PP" "<script>var pop = 'Entry: Ruritanian, <span title=\"k= m=\">valid</span> <span title=\"k= m=\">to</span> <span title=\"k= m=\">2033</span>';</script>"
M7B_NK="$WORK/m7b_need_one.html";   mrender "$M7B_NK" "<script>var pop = 'Note: cannot manage more than <span title=\"k=\">one</span> flight of stairs <span title=\"k=\">in</span> a single <span title=\"k=\">stretch</span>';</script>"
M7B_PK="$WORK/m7b_passport_one.html"; mrender "$M7B_PK" "<script>var pop = 'Entry: Ruritanian, <span title=\"k=\">valid</span> <span title=\"k=\">to</span> <span title=\"k=\">2033</span>';</script>"
M7C_A="$WORK/m7c_comment.html";   mrender "$M7C_A" "<!-- Entry: Ruritanian <span title=\">\" data-alpha= data-beta= onclick=go() valid to 2033 -->"
M7C_B="$WORK/m7c_template.html";  mrender "$M7C_B" "<script>var s = \`Entry: Ruritanian <span title=\">\" data-alpha= data-beta= onclick=go() valid to 2033\`; if (n < 3) { s = \"\"; }</script>"
M7C_AT="$WORK/m7c_comment_closed.html";  mrender "$M7C_AT" "<!-- Entry: Ruritanian <span title=\">\" data-alpha= data-beta= onclick=go()> valid to 2033</span> -->"
M7C_BT="$WORK/m7c_template_closed.html"; mrender "$M7C_BT" "<script>var s = \`Entry: Ruritanian <span title=\">\" data-alpha= data-beta= onclick=go()> valid to 2033</span>\`; if (n < 3) { s = \"\"; }</script>"
M7D_AP="$WORK/m7d_apostrophe.html"; mrender "$M7D_AP" "<!-- Entry: Ruritanian <span data-a=O'N class= title= lang= dir= x='>valid</span> to 2033 -->"
M7D_VN="$WORK/m7d_valued.html";     mrender "$M7D_VN" "<!-- Entry: Ruritanian <span data-a=O'N class=x title=y lang=z dir=w x='>valid</span> to 2033 -->"
M7E_U="$WORK/m7e_unlisted.html"; mrender "$M7E_U" "<script>var pop = 'Note: cannot manage more than <font>one</font> flight of stairs <trip-chip>in</trip-chip> a single stretch';</script>"
M7E_L="$WORK/m7e_listed.html";   mrender "$M7E_L" "<script>var pop = 'Note: cannot manage more than <em>one</em> flight of stairs <em>in</em> a single stretch';</script>"
M7F_P="$WORK/m7f_popup.html"; mrender "$M7F_P" '<div data-popup="Entry: Ruritanian <em>passport</em>, <strong>valid</strong> to <strong>2033</strong>">details</div>'
M7G_EQ="$WORK/m7g_eq_value.html"; mrender "$M7G_EQ" '<span title="Ruritanian= passport, valid to 2033">entry rules</span>'

# M7a — #2068's page: the need's words wrapped in three spans whose title carries `k= m=`, inside a
# script string. The published arm keeps `k m` between the need's words, so no five-word run
# survives there; the fourth arm drops both names and the need stands whole in its stream.
m7a_assert() { # one verdict
  local rs ps rt ms npub nshape oth
  mguard "$M7A_SP" "$MTD"; rs="$MRC"; ps="$(m1eq_prj)" || ps="NONE"
  mguard "$M7A_TW" "$MTD"; rt="$MRC"
  ms="$(m7_off "$M7A_SP" "$MTD")"
  npub="$(m1t_run strip_to_published_text "$M7A_SP")"; nshape="$(m1t_run strip_to_shape_text "$M7A_SP")"
  oth=$(( $(m1t_run strip_to_text_blocks "$M7A_SP") + $(m1t_run strip_to_joined_text "$M7A_SP") ))
  if [ "$rs" -eq 1 ] && [ "$ps" = "$M7_PRJ" ] && [ "$rt" -eq 0 ] && [ "$ms" = "0" ] && [ "$npub" -eq 0 ] && [ "$nshape" -eq 1 ] && [ "$oth" -eq 0 ]; then
    PASS "M7a: #2068's page — a need whose words three spans with title=\"k= m=\" push apart inside a script string aborts as a HIT (rc=$rs) named '$ps'; its twin with title=\"k m\" publishes (rc=$rt), so the HIT is the two names the fourth arm drops; ARMED-RED — with the fourth arm reading what the published projection reads the page publishes (rc=$ms). The need stands as one run $nshape time(s) in the fourth arm's stream and $npub time(s) in the published arm's, and $oth time(s) on the visible and joined arms"
  else
    FAIL "M7a: spans render rc=$rs '$ps' (want 1 and '$M7_PRJ'), title=\"k m\" twin rc=$rt (want 0), with the fourth arm reading as the published projection rc=$ms (want 0); the need as one run in the published stream $npub (want 0), in the fourth arm's $nshape (want 1), on the visible and joined arms $oth (want 0). #2068's page publishes again, or this arm can no longer tell"
  fi
}
m7a_assert

# M7b — the conjunctive member, and one span word as well as two. The Passport value with
# `k= m=` around three of its words goes past the conjunctive window on the published arm and is
# the fourth arm's to catch; so is the need with one name per span, `title="k="`. The Passport
# value with one name per span stays inside the window, so the published arm catches it as it did
# at the base, as #2068's card measured — its ARMED-RED reads 1, and it is not a page this arm
# restores.
m7b_assert() { # one verdict
  local rp pp rn pn rk pk mp mn mk
  mguard "$M7B_PP" "$MTD"; rp="$MRC"; pp="$(m1eq_prj)" || pp="NONE"
  mguard "$M7B_NK" "$MTD"; rn="$MRC"; pn="$(m1eq_prj)" || pn="NONE"
  mguard "$M7B_PK" "$MTD"; rk="$MRC"; pk="$(m1eq_prj)" || pk="NONE"
  mp="$(m7_off "$M7B_PP" "$MTD")"; mn="$(m7_off "$M7B_NK" "$MTD")"; mk="$(m7_off "$M7B_PK" "$MTD")"
  if [ "$rp" -eq 1 ] && [ "$pp" = "$M7_PRJ" ] && [ "$rn" -eq 1 ] && [ "$pn" = "$M7_PRJ" ] && [ "$rk" -eq 1 ] && [ "$pk" = "$M1EQ_PRJ" ] && [ "$mp" = "0" ] && [ "$mn" = "0" ] && [ "$mk" = "1" ]; then
    PASS "M7b: the conjunctive member — the Passport value with title=\"k= m=\" around three of its words aborts as a HIT (rc=$rp) named '$pp', and so does the need with one name per span (rc=$rn) named '$pn'; ARMED-RED — with the fourth arm reading as the published projection both publish (rc=$mp, rc=$mn). The Passport value with one name per span aborts on the published arm already (rc=$rk, '$pk', and $mk with the fourth arm so read), inside the conjunctive window as the card measured"
  else
    FAIL "M7b: Passport value with two names per span rc=$rp '$pp', need with one name per span rc=$rn '$pn' (want 1 and '$M7_PRJ' for both), Passport value with one name per span rc=$rk '$pk' (want 1 and '$M1EQ_PRJ'); with the fourth arm reading as the published projection rc=$mp, rc=$mn and rc=$mk (want 0, 0 and 1). A value the guard before 0.60.0 blocked publishes, or this arm can no longer tell"
  fi
}
m7b_assert

# M7c — #2070's two renders, absorbed into #2068: a kept tag's attribute list holding a quoted `>`
# with no tag after it, at a comment's end and in a template literal followed by a comparison's
# `<`. The published projection's fallback reads the list as text there, so its attribute names
# stand between the value's words; the fourth arm drops them. Each twin carries the tag's own `>`
# and `</span>` after the list, so the list is read and its names go on the published arm too.
m7c_assert() { # one verdict
  local ra pa rb pb rat rbt ma mb
  mguard "$M7C_A" "$MTD"; ra="$MRC"; pa="$(m1eq_prj)" || pa="NONE"
  mguard "$M7C_B" "$MTD"; rb="$MRC"; pb="$(m1eq_prj)" || pb="NONE"
  mguard "$M7C_AT" "$MTD"; rat="$MRC"
  mguard "$M7C_BT" "$MTD"; rbt="$MRC"
  ma="$(m7_off "$M7C_A" "$MTD")"; mb="$(m7_off "$M7C_B" "$MTD")"
  if [ "$ra" -eq 1 ] && [ "$pa" = "$M7_PRJ" ] && [ "$rb" -eq 1 ] && [ "$pb" = "$M7_PRJ" ] && [ "$rat" -eq 1 ] && [ "$rbt" -eq 1 ] && [ "$ma" = "0" ] && [ "$mb" = "0" ]; then
    PASS "M7c: #2070's renders — a list holding a quoted '>' with no tag after it, open at a comment's end, aborts as a HIT (rc=$ra) named '$pa', and in a template literal followed by a comparison's '<' (rc=$rb) named '$pb'; each twin carrying the tag's own '>' and closing tag aborts too (rc=$rat, rc=$rbt); ARMED-RED — with the fourth arm reading as the published projection both renders publish (rc=$ma, rc=$mb)"
  else
    FAIL "M7c: comment render rc=$ra '$pa', template render rc=$rb '$pb' (want 1 and '$M7_PRJ' for both), closed twins rc=$rat and rc=$rbt (want 1 and 1), with the fourth arm reading as the published projection rc=$ma and rc=$mb (want 0 and 0). #2070's renders publish again, or this arm can no longer tell"
  fi
}
m7c_assert

# M7d — #2068's apostrophe-opened form, measured and reached: an apostrophe inside an unquoted value
# opens what the published reader takes as a quoted unit, which keeps the later names as text
# between the value's words. Its twin gives each name a value: the unquoted values split the
# value's words under either reader, so it is not a shape the guard before 0.60.0 caught, and it
# stays outside the class this arm grades.
m7d_assert() { # one verdict
  local rd pd rv md
  mguard "$M7D_AP" "$MTD"; rd="$MRC"; pd="$(m1eq_prj)" || pd="NONE"
  mguard "$M7D_VN" "$MTD"; rv="$MRC"
  md="$(m7_off "$M7D_AP" "$MTD")"
  if [ "$rd" -eq 1 ] && [ "$pd" = "$M7_PRJ" ] && [ "$rv" -eq 0 ] && [ "$md" = "0" ]; then
    PASS "M7d: the apostrophe-opened form — names an apostrophe in an unquoted value keeps as text between a value's words abort as a HIT (rc=$rd) named '$pd'; ARMED-RED — with the fourth arm reading as the published projection the page publishes (rc=$md). Its twin with valued names publishes (rc=$rv): outside the class, because the guard before 0.60.0 published it too"
  else
    FAIL "M7d: apostrophe-opened render rc=$rd '$pd' (want 1 and '$M7_PRJ'), with the fourth arm reading as the published projection rc=$md (want 0), valued-names twin rc=$rv (want 0, outside the class). The apostrophe-opened form publishes again, or this arm can no longer tell"
  fi
}
m7d_assert

# M7e — a fourth regression no card named: a value split by a tag on neither list — `<font>`, a
# custom element — inside a script string. The published projection reads those tags as text,
# their names between the need's words; the fourth arm drops every tag name by shape. Its twin
# splits the need with a listed tag, which the published projection keeps as markup, so the twin
# aborts on both readings.
m7e_assert() { # one verdict
  local ru pu rl mu ml
  mguard "$M7E_U" "$MTD"; ru="$MRC"; pu="$(m1eq_prj)" || pu="NONE"
  mguard "$M7E_L" "$MTD"; rl="$MRC"
  mu="$(m7_off "$M7E_U" "$MTD")"; ml="$(m7_off "$M7E_L" "$MTD")"
  if [ "$ru" -eq 1 ] && [ "$pu" = "$M7_PRJ" ] && [ "$rl" -eq 1 ] && [ "$mu" = "0" ] && [ "$ml" = "1" ]; then
    PASS "M7e: a need split by a tag on neither list and by a custom element inside a script string aborts as a HIT (rc=$ru) named '$pu'; ARMED-RED — with the fourth arm reading as the published projection it publishes (rc=$mu). The twin split by a listed tag aborts on both readings (rc=$rl, rc=$ml)"
  else
    FAIL "M7e: unlisted-tag render rc=$ru '$pu' (want 1 and '$M7_PRJ'), with the fourth arm reading as the published projection rc=$mu (want 0); listed-tag twin rc=$rl and rc=$ml (want 1 and 1). A value split by a tag on neither list publishes again, or this arm can no longer tell"
  fi
}
m7e_assert

# M7f — milestone 69's Dev Testing note F-7: a value whose words bare listed inline tags wrap,
# inside an attribute value. The published arm reads it whole and names it; with the inline list
# taken out of the published projection and the fourth arm reading what that projection reads
# (m1in_off), the tag names stand between the words on every arm and the page publishes.
m7f_assert() { # one verdict
  local rf pf mf
  mguard "$M7F_P" "$MTD"; rf="$MRC"; pf="$(m1eq_prj)" || pf="NONE"
  mf="$(m1in_off "$M7F_P" "$MTD")"
  if [ "$rf" -eq 1 ] && [ "$pf" = "$M1EQ_PRJ" ] && [ "$mf" = "0" ]; then
    PASS "M7f: F-7 — a value whose words bare listed inline tags wrap inside an attribute value aborts as a HIT (rc=$rf) named '$pf'; ARMED-RED — with the inline list taken out of the published projection and the fourth arm reading what it reads, the page publishes (rc=$mf)"
  else
    FAIL "M7f: F-7 render rc=$rf '$pf' (want 1 and '$M1EQ_PRJ'), without the inline list and with the fourth arm so read rc=$mf (want 0). A value wrapped in listed inline tags inside an attribute value publishes, or this arm can no longer tell"
  fi
}
m7f_assert

# M7g — criterion 5 of #1467 inside a quoted value: a key token written directly before `=` and a
# space inside a quoted attribute value. That is #2068's shape exactly, so the fourth arm drops the
# token; the published arm keeps it and the abort is named for the published arm, not the fourth.
# The fourth arm alone made to read as the published projection changes nothing; the published
# projection read as the guard before 0.60.0 read it, with the fourth arm reading the same, loses
# the token and publishes.
m7g_assert() { # one verdict
  local rg pg ms ml
  mguard "$M7G_EQ" "$MTD"; rg="$MRC"; pg="$(m1eq_prj)" || pg="NONE"
  ms="$(m7_off "$M7G_EQ" "$MTD")"
  ml="$( strip_to_published_text() { pp_legacy_pub "$1"; }; strip_to_shape_text() { pp_legacy_pub "$1"; }
         verify_publishable_content "$M7G_EQ" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
  if [ "$rg" -eq 1 ] && [ "$pg" = "$M1EQ_PRJ" ] && [ "$ms" = "1" ] && [ "$ml" = "0" ]; then
    PASS "M7g: criterion 5 inside a quoted value — a key token written directly before '=' and a space there aborts as a HIT (rc=$rg) named '$pg', the published arm's and not the fourth's; with the fourth arm reading as the published projection it still aborts (rc=$ms); ARMED-RED — with the published projection read as the guard before 0.60.0 read it, and the fourth arm reading the same, it publishes (rc=$ml)"
  else
    FAIL "M7g: criterion-5 render rc=$rg '$pg' (want 1 and '$M1EQ_PRJ'), with the fourth arm reading as the published projection rc=$ms (want 1), with both read as the guard before 0.60.0 read them rc=$ml (want 0). The fourth arm took criterion 5's name, or criterion 5 is lost inside a quoted value"
  fi
}
m7g_assert

# M7h — #2070's assignment sites, absorbed into #2068 with milestone 69's bound of 8 of 23. #2070's
# own script is attached nowhere, so the count is taken on a reconstructed recipe-shaped one: 23
# uniquely named assignment sites, a loop whose `qxc < data.length` opens a kept `<data` tag, and a
# sort comparator whose `=>` ends that tag's list. A site is given back by a projection when its
# name stands in that projection's stream fewer times than in the source, which is the assignment's
# name dropped as an attribute name. The guard ORs its arms, so it gives a site back only when
# every arm does: the count on its verdict is the sites all four give back. Fixture integrity is
# the site count, and its control is the earlier published program, which gives every site back.
# One site the published arm keeps carries the Passport value's key token in a twin, which the
# guard must still abort on, named for the published arm: the fourth arm, which drops it, removes
# nothing another arm keeps.
M7H_R="$WORK/m7h_recipe.html"
mrender "$M7H_R" "$(printf '%s\n' '<script>' 'var qxa = steps.length;' 'var qxb = "two eggs";' 'for (var qxc = 0; qxc < data.length; qxc++) {' '  qxd = data[i].due;' '  qxe = data[i].name;' '  qxf = row.count + 1;' '  qxg = row.label.trim();' '  qxh = row.weight * 2;' '  qxi = row.notes.length;' '  qxj = total - 3;' '  qxk = total % 7;' '}' 'items.sort((a, b) => a.due < b.due ? -1 : 1);' 'qxl = items[0];' 'qxm = items[1];' 'qxn = first.due;' 'qxo = last.due;' 'qxp = span - 1;' 'qxq = span / 2;' 'qxr = base + 3;' 'qxs = base * 4;' 'qxt = mid - 1;' 'qxu = mid + 1;' 'qxv = end + 2;' 'qxw = end + 3;' '</script>')"
M7H_K="$WORK/m7h_recipe_key.html"
sed 's#^qxl = items\[0\];#var Ruritanian = "passport valid to 2033";#' "$M7H_R" > "$M7H_K"
perl -ne 'while (/(qx[a-z])\s*=(?![=>])/g) { print "$1\n" }' "$M7H_R" > "$WORK/m7h_sites"
_norm_words < "$M7H_R" > "$WORK/m7h_src.words"
m7h_gb() { # <projection> -> the site names its stream gives back, one per line
  "$1" "$M7H_R" | _decode_entities | _norm_words > "$WORK/m7h_$1.words"
  awk 'FILENAME == ARGV[1] { site[$0] = 1; next } FILENAME == ARGV[2] { if ($0 in site) src[$0]++; next } ($0 in site) { st[$0]++ } END { for (n in site) if (st[n] + 0 < src[n] + 0) print n }' "$WORK/m7h_sites" "$WORK/m7h_src.words" "$WORK/m7h_$1.words"
}
m7h_assert() { # one verdict
  local ns gp gs gv gj gl gg rk pk mk ws
  ns="$(awk 'END { print NR + 0 }' "$WORK/m7h_sites")"
  m7h_gb strip_to_published_text > "$WORK/m7h_gb_pub"; m7h_gb strip_to_shape_text > "$WORK/m7h_gb_shape"
  m7h_gb strip_to_text_blocks > "$WORK/m7h_gb_vis"; m7h_gb strip_to_joined_text > "$WORK/m7h_gb_joi"
  m7h_gb pp_legacy_pub > "$WORK/m7h_gb_legacy"
  # An empty stream gives every site back, so the fourth arm's count is read only beside proof
  # that its stream carries the page: its own word count, sentinels aside.
  ws="$(_guard_words "$WORK/m7h_strip_to_shape_text.words")"; ws="${ws:-0}"
  gp="$(awk 'END { print NR + 0 }' "$WORK/m7h_gb_pub")"; gs="$(awk 'END { print NR + 0 }' "$WORK/m7h_gb_shape")"
  gv="$(awk 'END { print NR + 0 }' "$WORK/m7h_gb_vis")"; gj="$(awk 'END { print NR + 0 }' "$WORK/m7h_gb_joi")"
  gl="$(awk 'END { print NR + 0 }' "$WORK/m7h_gb_legacy")"
  gg="$(awk '{ c[$0]++ } END { for (n in c) if (c[n] == 4) k++; print k + 0 }' "$WORK/m7h_gb_pub" "$WORK/m7h_gb_shape" "$WORK/m7h_gb_vis" "$WORK/m7h_gb_joi")"
  mguard "$M7H_K" "$MTD"; rk="$MRC"; pk="$(m1eq_prj)" || pk="NONE"
  mk="$( strip_to_published_text() { pp_legacy_pub "$1"; }; strip_to_shape_text() { pp_legacy_pub "$1"; }
         verify_publishable_content "$M7H_K" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
  if [ "$ns" -eq 23 ] && [ "$gl" -eq "$ns" ] && [ "$gp" -le 8 ] && [ "$gg" -le 8 ] && [ "$gg" -le "$gp" ] && [ "$gs" -eq "$ns" ] && [ "$ws" -ge 20 ] && [ "$rk" -eq 1 ] && [ "$pk" = "$M1EQ_PRJ" ] && [ "$mk" = "0" ]; then
    PASS "M7h: milestone 69's bound — on a recipe-shaped script of $ns assignment sites the published arm gives back $gp and the guard's verdict $gg (every arm must give a site back for the guard to), within 8 of 23; the fourth arm alone gives back $gs from a stream of $ws words, and the visible and joined arms $gv and $gj, so no site the published arm keeps is lost. The earlier published program gives back $gl, so the count can see a site given back. A site the published arm keeps, carrying the Passport value's key token, aborts as a HIT (rc=$rk) named '$pk'; ARMED-RED — read as the guard before 0.60.0 read it, that page publishes (rc=$mk)"
  else
    FAIL "M7h: sites $ns (want 23), given back by the earlier published program $gl (want all of them), by the published arm $gp and on the guard's verdict $gg (want at most 8 each, the guard's no more than the published arm's), by the fourth arm $gs from a stream of $ws words (want all of them, from at least 20); the key-token twin rc=$rk '$pk' (want 1 and '$M1EQ_PRJ'), read as the guard before 0.60.0 read it rc=$mk (want 0). More sites are given back than milestone 69's bound, or this arm can no longer tell"
  fi
}
m7h_assert

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

# ── N2 (#328 F1) — the conjunctive window is derived from the VALUE, not from a flat 25 ──
#
# N1 closed the cross-block pairing. What survived it is the WITHIN-block false abort: on
# a trip to the country in the passport's own year, ordinary destination guidance carries
# both class tokens in one legitimate sentence. Measured on the shipped guard, 3 of 3
# such lines aborted while 2 of 2 controls published — a permanent, unremediable abort on
# correct content, which this file argues three times is fail-open in practice.
#
# WHY A 17-FIXTURE MATRIX AND NOT THE 3 THE DEFECT NAMED. Two degenerate outcomes reach a
# PASS on an over-block-only criterion, and both were measured: a matcher stubbed to
# never match passes every over-block arm, and a one-limb fix passes exactly the three
# lines the defect named while still aborting 4 of 4 destination-guidance lines written
# afterwards. So the over-block arms are TWINNED with carry-through arms over the same
# render family, and the two are graded together rather than apart.
#
# The matrix: 9 over-block candidates · 6 true carry-throughs · 3 clean · 1 paraphrase.
# Every arm below grades an EXACT code and treats anything outside {0,1} as a probe
# failure rather than folding it into a count — with _guard_match removed the guard
# returns 127, which is a different claim from "aborted".
N2OB1='<h1>Galway 2027 — an Irish adventure</h1>'
N2OB2='<p>Visa / entry: Irish passport holders need no visa; check that validity runs beyond 2027.</p>'
N2OB3='<p>Booking note: the Irish ferry crossing must be reserved before the 2027 summer timetable opens.</p>'
N2OB4='<p>Booking note: the Irish ferry to the islands runs until 2027 on the summer timetable.</p>'
N2OB5='<p>Getting there: Irish Rail runs hourly from Dublin Heuston; the 2027 timetable is published each December.</p>'
N2OB6='<p>Money: cards are accepted almost everywhere in Irish cafes and bars, and the 2027 bank holidays fall on the first Monday of each month.</p>'
N2OB7='<p>Weather: the Irish west coast is wet in every season, so the packing list below holds for the whole 2027 trip.</p>'
# OB8 and OB9 exist because the first seven under-sampled the space in one direction: NONE
# of them carries the value's own connective vocabulary, so limb B alone rejected six of
# the seven and a sweep over that set showed limb A removing nothing. These two carry
# `to` and `valid` respectively — limb B admits them — and are rejected by limb A alone.
# Without them the matrix would have read "limb A is not load-bearing", which is a fact
# about the fixtures rather than about the rule. N2i is the arm that grades the
# difference.
N2OB8='<p>Visa / entry: an Irish passport is enough to enter, and no separate permit is required before 2027.</p>'
N2OB9='<p>Tickets: the festival pass is valid for the whole week, and an Irish student card gets a discount on the 2027 programme.</p>'
N2TP1='<p>Border note: carry your Irish passport, valid to 2027, at all times.</p>'
N2TP2='<p>Border note: valid to 2027 — that is the Irish passport you should be carrying.</p>'
N2TP3='<p>Document check: Irish, valid to 2027.</p>'
N2TP4='<p>Passport check: Irish and valid to 2027 for everyone travelling.</p>'
N2TP5='<p>Carry the Irish one, valid to 2027, in your day bag.</p>'
N2TP6='<p>Border note: the Irish one you carry is valid to 2027.</p>'
N2CL2='<h1>Galway 2027 — a west coast week</h1>'
N2CL3='<p>Visa / entry: no visa required for stays under ninety days; carry a passport valid for six months beyond arrival.</p>'
N2PP1='<p>Border note: the Irish passport you carry expires in 2027.</p>'

# nrender wraps its third argument in <p>; these fixtures supply their own element,
# because one of them is a HEADING and the heading case is the tightest span in the set.
n2render() { # <out_file> <raw final markup>
  {
    printf '<!DOCTYPE html><html><head><title>Galway Trip</title></head><body>\n<h1>Itinerary</h1>\n'
    n2d=1
    while [ "$n2d" -le 6 ]; do
      printf '<h2>Day %d — Friday 12 June 2027</h2>\n' "$n2d"
      printf '<p>Morning at the covered market, then a long lunch by the water and an\n'
      printf 'afternoon walk through the old town before an evening at a traditional Irish\n'
      printf 'pub with music from about nine, back to the guest house before midnight.</p>\n'
      n2d=$((n2d+1))
    done
    [ -n "${2:-}" ] && printf '%s\n' "$2"
    printf '</body></html>\n'
  } > "$1"
}
# The minimal within-block distance between the two class tokens, read off the visible
# projection the rule itself matches. It is what the proportional limb is compared
# against, so N2e can assert the residual as an OBSERVATION rather than as a claim.
n2span() { # <html_file> -> minimal same-block key window, or '-'
  strip_to_text_blocks "$1" | _line_sentinels | _norm_words | awk -v B="$_GUARD_BLOCK" -v L="$_GUARD_LINE" '
    $0==L { next } $0==B { blk++; next } { n++; t[n]=$0; b[n]=blk }
    END { best=-1
      for (i=1;i<=n;i++) for (j=1;j<=n;j++) {
        if (b[i]!=b[j]) continue
        if ((t[i]=="irish"&&t[j]=="2027")||(t[i]=="2027"&&t[j]=="irish")) { d=(i>j?i-j:j-i); if (best<0||d<best) best=d }
      }
      print (best<0 ? "-" : best) }'
}
n2rc() { # <raw final markup> -> the guard's exact status
  n2render "$WORK/n2_probe.html" "$1"
  verify_publishable_content "$WORK/n2_probe.html" "$NTD" >/dev/null 2>&1; printf '%s' "$?"
}

# N2a — FIXTURE INTEGRITY + THE DENOMINATOR, graded FIRST. Every over-block candidate must
# really carry both class tokens in one block and must NEVER carry the value as a
# contiguous run; every carry-through must carry the value's two facts in one block. A
# fixture set failing either half makes every verdict below vacuous rather than passing.
n2_bad=""; n2_ob=0; n2_tp=0
for n2x in "$N2OB1" "$N2OB2" "$N2OB3" "$N2OB4" "$N2OB5" "$N2OB6" "$N2OB7" "$N2OB8" "$N2OB9"; do
  n2_ob=$((n2_ob+1)); n2render "$WORK/n2_fi.html" "$n2x"
  n2s="$(n2span "$WORK/n2_fi.html")"
  { [ "$n2s" != "-" ] && ! grep -qF 'Irish, valid to 2027' "$WORK/n2_fi.html"; } || n2_bad="$n2_bad OB$n2_ob(span=$n2s)"
done
for n2x in "$N2TP1" "$N2TP2" "$N2TP3" "$N2TP4" "$N2TP5" "$N2TP6"; do
  n2_tp=$((n2_tp+1)); n2render "$WORK/n2_fi.html" "$n2x"
  n2s="$(n2span "$WORK/n2_fi.html")"
  [ "$n2s" != "-" ] || n2_bad="$n2_bad TP$n2_tp(no-pair)"
done
if [ -z "$n2_bad" ] && [ "$n2_ob" -eq 9 ] && [ "$n2_tp" -eq 6 ]; then
  PASS "N2a: the discrimination matrix is real — $n2_ob over-block candidates each carry both class tokens inside ONE block and none carries the value as a run, and $n2_tp carry-throughs each pair the two facts in one block. Denominator for every verdict below: 9 over-block / 6 carry-through / 3 clean / 1 paraphrase"
else
  FAIL "N2a: the matrix is not set up as claimed (ob=$n2_ob tp=$n2_tp; bad:$n2_bad) — the arms below would be vacuous rather than passing"
fi

# N2b — THE SUBJECT. The over-block candidates must publish. ONE is expected to survive
# and is named rather than hidden: N2e asserts why it is irreducible.
n2_over_assert() {
  local x rc pub=0 n=0 bad="" aborted=""
  for x in "$N2OB1" "$N2OB2" "$N2OB3" "$N2OB5" "$N2OB6" "$N2OB7" "$N2OB8" "$N2OB9"; do
    n=$((n+1)); rc="$(n2rc "$x")"
    case "$rc" in 0) pub=$((pub+1)) ;; 1) aborted="$aborted OB$n" ;; *) bad="$bad OB$n=rc$rc" ;; esac
  done
  if [ "$pub" -eq "$n" ]; then
    PASS "N2b: all $n non-residual over-block candidates publish (rc=0) — legitimate destination guidance, booking, visa, transport, money, weather and ticketing lines that mention the nationality adjective and the trip year no longer abort. The window is now derived from the value's own span and the match additionally requires the value's own connective vocabulary"
  else
    FAIL "N2b: only $pub/$n over-block candidates published — still aborting:$aborted$bad. A fail-closed control that refuses correct content is worked around rather than satisfied"
  fi
}
n2_over_assert

# N2c — SENSITIVITY, and it is the arm that makes N2b evidence rather than a green light.
# Without it N2b is satisfied by a matcher that stopped matching passports at all — which
# was measured: a stub returning "no match" passes every over-block arm in this group.
n2_carry_assert() {
  local x rc ab=0 n=0 bad=""
  for x in "$N2TP1" "$N2TP2" "$N2TP3" "$N2TP4" "$N2TP5" "$N2TP6"; do
    n=$((n+1)); rc="$(n2rc "$x")"
    case "$rc" in 1) ab=$((ab+1)) ;; 0) bad="$bad TP$n=published" ;; *) bad="$bad TP$n=rc$rc" ;; esac
  done
  if [ "$ab" -eq "$n" ]; then
    PASS "N2c: all $n real carry-throughs still abort (rc=1) — verbatim, order-swapped, de-attributed and three rewordings, including one whose two facts sit 7 tokens apart. The narrowing removed false aborts without disarming the rule"
  else
    FAIL "N2c: only $ab/$n carry-throughs aborted —$bad. This is the arm that distinguishes a fix from a disabled matcher, and it has stopped firing"
  fi
}
n2_carry_assert

# N2d — SPECIFICITY over the clean set, and the arm the whole group's PASS rests on being
# a property of the render rather than of the guard being off.
n2_clean_assert() {
  local x rc pub=0 n=0 bad=""
  for x in "" "$N2CL2" "$N2CL3"; do
    n=$((n+1)); rc="$(n2rc "$x")"
    case "$rc" in 0) pub=$((pub+1)) ;; *) bad="$bad CL$n=rc$rc" ;; esac
  done
  if [ "$pub" -eq "$n" ]; then
    PASS "N2d: all $n clean fixtures publish (rc=0) — the six-day render with no final paragraph, one whose heading carries only the year, and one whose visa line carries neither class token"
  else
    FAIL "N2d: only $pub/$n clean fixtures published —$bad. A clean render aborting is the defect this group exists to close, arriving from the other direction"
  fi
}
n2_clean_assert

# N2e — THE RESIDUAL, ASSERTED AS AN OBSERVATION RATHER THAN CLAIMED IN PROSE. One
# over-block candidate still aborts, and it is irreducible rather than mis-tuned: it and
# one of the carry-throughs have the SAME within-block span and both carry the value's
# connective token `to`, so no setting of GUARD_CONJ_SLACK and no connective test can
# separate them. Asserting the equality is what keeps the residual honest — if a later
# change makes the two spans differ, this arm fails and the residual must be restated.
n2render "$WORK/n2_res_ob.html" "$N2OB4"; n2_res_obs="$(n2span "$WORK/n2_res_ob.html")"
n2render "$WORK/n2_res_tp.html" "$N2TP6"; n2_res_tps="$(n2span "$WORK/n2_res_tp.html")"
n2_res_obrc="$(n2rc "$N2OB4")"; n2_res_tprc="$(n2rc "$N2TP6")"
if [ "$n2_res_obs" = "$n2_res_tps" ] && [ "$n2_res_obrc" -eq 1 ] && [ "$n2_res_tprc" -eq 1 ]; then
  PASS "N2e: the surviving over-block is IRREDUCIBLE, measured rather than asserted — it and a real carry-through have the same within-block span ($n2_res_obs) and both carry the value's connective token, so both abort and no value-derived rule can tell them apart. The residual is declared in ADR-008 rather than tuned away"
else
  FAIL "N2e: the residual's premise no longer holds (over-block span=$n2_res_obs rc=$n2_res_obrc; carry-through span=$n2_res_tps rc=$n2_res_tprc). If the spans now differ the residual is reducible and the declared coverage boundary is wrong"
fi

# N2f — THE PARAPHRASE, AND THE COST THIS CARD ACCEPTS. A carry-through that drops the
# value's own connective vocabulary entirely is no longer matched. It is stated as an
# assertion rather than left in prose because it is a NARROWING of a security control:
# the arm fails the day the paraphrase starts aborting again, which would mean the
# connective limb had been weakened, and it fails if someone reads this residual as a
# defect and "fixes" it without re-deriving the over-block measurements above.
n2_pp_rc="$(n2rc "$N2PP1")"
if [ "$n2_pp_rc" -eq 0 ]; then
  PASS "N2f: the declared cost is exactly what was declared — a paraphrase of the validity predicate ('the Irish passport you carry expires in 2027') carries no connective token of the value and is NOT matched (rc=0). This narrows coverage, it sits inside the paraphrase class ADR-008 already disclaims, and it is carried there as its own residual"
else
  FAIL "N2f: the paraphrase returned rc=$n2_pp_rc rather than 0 — the connective limb is behaving differently from the way the coverage boundary and the SLACK calibration were both derived, so both need re-deriving before this reads as an improvement"
fi

# N2g — THE DECLARED ESCAPE. A value with no stoplisted tokens of its own has no
# connective tissue to require, so limb B is vacuously satisfied and limb A alone applies.
# The consequence is stated in the matcher and measured here: on such a value the heading
# over-block PERSISTS while a real carry-through is still caught. The fix is proportional
# to how much connective tissue the value carries, and that bound is asserted rather than
# discovered by whoever next reads a bug report about it.
N2ETD="$WORK/galway-escape"; mkdir -p "$N2ETD/outputs"
cat > "$N2ETD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Galway 2027 [DERIVED]

## Rowan
- Passport: Irish 2027
MD
n2render "$WORK/n2_esc_ob.html" "$N2OB1"; verify_publishable_content "$WORK/n2_esc_ob.html" "$N2ETD" >/dev/null 2>&1; n2_esc_ob=$?
n2render "$WORK/n2_esc_tp.html" "$N2TP1"; verify_publishable_content "$WORK/n2_esc_tp.html" "$N2ETD" >/dev/null 2>&1; n2_esc_tp=$?
if [ "$n2_esc_ob" -eq 1 ] && [ "$n2_esc_tp" -eq 1 ]; then
  PASS "N2g: the ncon==0 escape behaves as declared — against the value 'Irish 2027', which carries no stoplisted token of its own, the connective limb is vacuous, the heading over-block still aborts (rc=1) and a real carry-through is still caught (rc=1). The remedy is proportional to the value, and that bound is measured here rather than assumed"
else
  FAIL "N2g: the connective-limb escape did not behave as declared (over-block rc=$n2_esc_ob want 1, carry-through rc=$n2_esc_tp want 1) — either the escape has widened into a fail-open or the over-block bound in the matcher comment is now wrong"
fi

# N2i — BOTH LIMBS ARE LOAD-BEARING, graded one limb at a time rather than argued in
# prose. The fix has two conjuncts and a reader is entitled to ask whether either is
# decoration. Each is answered by a fixture the OTHER limb admits:
#   • limb B is load-bearing — N2g already shows it: against a value carrying no
#     stoplisted tokens of its own the connective test goes vacuous and the heading
#     over-block, whose span is 2, aborts again. Limb A admits it at every setting.
#   • limb A is load-bearing — this arm. OB8 and OB9 both CARRY the value's connective
#     vocabulary in their own block, so limb B admits them; they are rejected by the
#     proportional window alone. Raising GUARD_CONJ_SLACK to GUARD_WINDOW makes limb A
#     non-binding — it is then exactly the flat window that shipped — and both abort.
# The second half is the one that matters, because the first seven over-block fixtures
# carried no connective token at all and a sweep over that set alone showed limb A
# removing nothing. That was a property of the fixtures. This arm is what keeps it from
# reading as a property of the rule.
n2_limbA_shipped_8="$(n2rc "$N2OB8")"; n2_limbA_shipped_9="$(n2rc "$N2OB9")"
n2_limbA_flat_8="$( GUARD_CONJ_SLACK="$GUARD_WINDOW"; n2rc "$N2OB8" )"
n2_limbA_flat_9="$( GUARD_CONJ_SLACK="$GUARD_WINDOW"; n2rc "$N2OB9" )"
if [ "$n2_limbA_shipped_8" -eq 0 ] && [ "$n2_limbA_shipped_9" -eq 0 ] \
   && [ "$n2_limbA_flat_8" -eq 1 ] && [ "$n2_limbA_flat_9" -eq 1 ]; then
  PASS "N2i: the proportional window is load-bearing on its own — two over-block candidates that DO carry the value's connective vocabulary (so the connective limb admits them) publish at the shipped GUARD_CONJ_SLACK and both abort when it is raised to GUARD_WINDOW, which is the flat window that shipped. Neither limb is decoration: N2g is the mirror arm for the other one"
else
  FAIL "N2i: the two limbs are no longer separable on these fixtures (shipped slack: OB8 rc=$n2_limbA_shipped_8 OB9 rc=$n2_limbA_shipped_9, want 0; flat window: OB8 rc=$n2_limbA_flat_8 OB9 rc=$n2_limbA_flat_9, want 1). If the proportional window now removes nothing these fixtures can see, either it is redundant or the matrix has stopped sampling the class it protects"
fi

# N2h — THE OTHER `conjunctive` ROW. The declaration assigns `conjunctive` to FOUR rows,
# and three of them are the `Passport` field at its three artifact scopes. The fourth is
# `Documents` in the derived model — a different selector, a different value shape, and
# the same rule — and no assertion in this suite had ever exercised it. Every fixture in
# group N and every over-block measurement behind the SLACK calibration is Passport-shaped,
# so the rule was calibrated on one of the two members it governs. This arm grades the
# other one in both directions, so a future change to the conjunctive rule is measured
# against the whole of what it binds rather than against the half that had fixtures.
N2DTD="$WORK/galway-documents"; mkdir -p "$N2DTD/outputs"
cat > "$N2DTD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Galway 2027 [DERIVED]

## Rowan

**Derived**

- **Documents:** Schengen visa, valid to 2028
MD
n2_doc_recs="$(nonpublishable_values "$N2DTD" 2>/dev/null | grep -c 'conjunctive')"
# A six-day render mentioning the two class tokens in SEPARATE blocks, then the same
# render with the value carried through inside one block. The pair differs only in the
# final element, so a verdict difference is caused by that element and nothing else.
n2doc() { # <out_file> <raw final markup>
  {
    printf '<!DOCTYPE html><html><head><title>Galway Trip</title></head><body>\n<h1>Itinerary</h1>\n'
    n2dd=1
    while [ "$n2dd" -le 6 ]; do
      printf '<h2>Day %d — the 2028 season opener</h2>\n' "$n2dd"
      printf '<p>Morning at the covered market, then a long lunch by the water and an\n'
      printf 'afternoon walk before an evening at a bar near the Schengen visa office on\n'
      printf 'the square, with music from about nine and a late walk back.</p>\n'
      n2dd=$((n2dd+1))
    done
    [ -n "${2:-}" ] && printf '%s\n' "$2"
    printf '</body></html>\n'
  } > "$1"
}
n2doc "$WORK/n2_doc_clean.html" ''
n2doc "$WORK/n2_doc_hit.html" '<p>Border note: the Schengen visa is valid to 2028 for everyone travelling.</p>'
verify_publishable_content "$WORK/n2_doc_clean.html" "$N2DTD" >/dev/null 2>&1; n2_doc_c=$?
verify_publishable_content "$WORK/n2_doc_hit.html"   "$N2DTD" >/dev/null 2>&1; n2_doc_h=$?
if [ "$n2_doc_recs" -ge 1 ] && [ "$n2_doc_c" -eq 0 ] && [ "$n2_doc_h" -eq 1 ]; then
  PASS "N2h: the OTHER conjunctive row is graded in both directions — the Documents selector yields $n2_doc_recs conjunctive record(s), a render whose two class tokens recur in SEPARATE blocks publishes (rc=0), and the same render carrying the value in ONE block aborts (rc=1). The rule was calibrated on Passport-shaped values; this is the member that had no fixture"
else
  FAIL "N2h: the Documents row did not grade in both directions (conjunctive records=$n2_doc_recs, cross-block render rc=$n2_doc_c want 0, same-block render rc=$n2_doc_h want 1) — a zero record count makes both verdicts vacuous rather than clean"
fi

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
# O4b — SPLIT, AND ITS MESSAGE CORRECTED. IT NEVER TESTED THE STRIP.
#
# O4's fixture carries TWO things — the stripped marks AND a recorded supersession — and
# this arm grades only the final rc. That rc is decided entirely by the supersession path:
# remove the supersession line and hold everything else constant, and the same fixture
# goes rc=2 -> rc=0. So the arm passed, its FAIL text claimed it guarded "stripping the
# marks silently empties the class", and it would have gone on passing if the strip hole
# had been made WORSE — its PASS requires no evidence about the strip at all.
#
# That is the compound-fixture shape: a verdict gated on two conditions where no arm
# isolates the named variable. ADR-019's Discriminating-Evidence Rule is the governing
# discipline; this is an instance its Class-1 scan shapes cannot find, because the PASS is
# reachable neither by an absent subject nor by an empty haystack.
#
# The message now names the supersession, which is what this arm really grades. O4e below
# is the arm it was missing.
oguard "$O4R" "$O4TD"
o4sup="$ORC"
if [ "$o4sup" -eq 2 ]; then PASS "O4b: a recorded third-party supersession with no profile to support it is UNDETERMINED (rc=$o4sup) — never a clean publish. This arm grades the SUPERSESSION path and nothing else: O4e holds the same fixture constant and removes only the supersession line"; else FAIL "O4b: an unsupported supersession did not abort (rc=$o4sup) — the provenance-change check is not firing"; fi
# O4e — THE ARM O4b WAS MISSING, and it is a MEASUREMENT, not an endorsement. Read it the
# way L11a asks to be read.
#
# The same fixture with the supersession line removed still satisfies every condition O4a
# enumerates — zero uppercase marks, the value retained, no profile anywhere — and it is
# therefore the bad merge O4b's old message named. It PUBLISHES. A fully silent strip
# leaves no residue in the only source the class has, so the parse enumerates zero records
# and a zero is accepted.
#
# THIS ARM PINS THE GAP AND MUST BE INVERTED, NOT DELETED, BY THE SLICE THAT CLOSES IT.
# The closure needs a WITNESS rather than a better parse, and the witness has to come from
# outside the model: this card measured that every out-of-model witness available today
# (a per-traveler profile, a provenance mark, a recorded gap) is absent from this fixture
# AND from nine of the guard's own must-publish controls, so a witness-based closure
# converts `absence is not zero` — L6a/L6b, the guard's founding distinction — into an
# abort. The closure is a model-side census attestation, which is a change to the
# enrichment contract and the model schema rather than to this predicate.
#
# Single-variable by construction: O4f asserts that the two fixtures differ in exactly the
# supersession line, so the rc flip is attributable to it and to nothing else.
O4NSTD="$WORK/o4_nosupersede"
omodel "$O4NSTD" <<'MD'
# Traveler Model [DERIVED]

## Quill
- Specific: cannot manage more than one flight of stairs in a single stretch
MD
# O4f — fixture integrity for O4e, graded FIRST. Both fixtures must satisfy O4a's stated
# bad-merge shape, and they must differ ONLY in the supersession line; otherwise O4e is
# measuring something other than the variable it names.
o4nmarks="$(grep -c 'THIRD-PARTY' "$O4NSTD/outputs/traveler-model.md" || true)"
o4nvals="$(grep -c 'flight of stairs' "$O4NSTD/outputs/traveler-model.md" || true)"
o4ndiff="$(diff "$O4TD/outputs/traveler-model.md" "$O4NSTD/outputs/traveler-model.md" | grep -c '^<' || true)"
if [ "$o4nmarks" -eq 0 ] && [ "$o4nvals" -ge 1 ] && [ ! -d "$O4NSTD/travelers" ] \
   && ! grep -qF 'supersedes third-party-sourced entry' "$O4NSTD/outputs/traveler-model.md"; then
  PASS "O4f: the O4e fixture is O4a's bad-merge shape with the supersession removed — marks=$o4nmarks, value survived ($o4nvals), no profile, no supersession, and it differs from O4's model in $o4ndiff removed line(s) — so O4e grades ONE variable"
else
  FAIL "O4f: the O4e fixture is not O4a's shape minus the supersession (marks=$o4nmarks values=$o4nvals) — O4e would not isolate the strip"
fi
oguard "$O4R" "$O4NSTD"
o4strip="$ORC"
if [ "$o4strip" -eq 0 ] && [ "$o4sup" -eq 2 ]; then
  PASS "O4e: a bad merge that strips BOTH marks and records no supersession PUBLISHES (rc=$o4strip) while the same fixture WITH the supersession aborts (rc=$o4sup) — measured, not assumed. O4b's verdict rests entirely on the supersession, so the strip is UNGUARDED, and ADR-008's coverage claim for it is corrected in this change. Invert this arm when a model-side attestation closes it"
else
  FAIL "O4e: the mark-strip gap is not in the measured shape (stripped=$o4strip with-supersession=$o4sup) — if the strip now aborts, this arm has been CLOSED and must be inverted rather than left pinning a gap that no longer exists; if the supersession stopped aborting, O4b is broken"
fi
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

# ── O7 — an entry's STRUCTURAL SUB-HEADINGS are not captured values ──────────
# The entry denylist emitted every line of a marked entry, INCLUDING the bold sub-headings
# the derived model writes its entry body under. Two of the three shipped ones became
# distinctive match keys, so a render carrying the ordinary English word `derived` or
# `desires` aborted a publish — measured live on examples/archived-trip-demo, against a
# control render that published.
#
# `**Needs**` was already a non-member, but only by the accident that `needs` is a member
# of the closed need-category enum; its two siblings had no such accident. That asymmetry
# is the finding: the exclusion was vocabulary-shaped where the thing being excluded is
# SHAPE-shaped.
#
# Graded on the SHIPPED fixture rather than a synthetic one, deliberately: this was a live
# false positive on the wired publish path of a public repository, and a synthetic model
# would let the fixture drift away from the shape that actually failed.
O7R="$WORK/o7_sub.html"
orender "$O7R" 'Build note: this page was derived from the current plan, and the desires list was checked.'
O7CR="$WORK/o7_clean.html"
orender "$O7CR" 'Build note: this page was rebuilt from the current plan, and the wish list was checked.'
O7SHIP="$HERE/../examples/archived-trip-demo"
# O7a — fixture integrity, and it is the arm that keeps O7b from passing vacuously. The
# shipped model must exist, must carry a [THIRD-PARTY] entry, must still enumerate a
# NON-EMPTY class, and the render must really carry both words.
o7recs="$(nonpublishable_values "$O7SHIP" 2>/dev/null | awk 'NF { c++ } END { print c + 0 }')"
if [ -f "$O7SHIP/outputs/traveler-model.md" ] \
   && grep -qF '[THIRD-PARTY]' "$O7SHIP/outputs/traveler-model.md" \
   && grep -qF '**Derived**' "$O7SHIP/outputs/traveler-model.md" \
   && grep -qF '**Desires**' "$O7SHIP/outputs/traveler-model.md" \
   && [ "$o7recs" -gt 0 ] \
   && grep -qF 'derived' "$O7R" && grep -qF 'desires' "$O7R"; then
  PASS "O7a: the shipped archived-trip-demo carries a [THIRD-PARTY] entry with both bold sub-headings, still enumerates $o7recs class record(s), and the render carries both words — O7b is graded against a live fixture and a non-degenerate class"
else
  FAIL "O7a: the O7 fixture is not the shipped shape (records=$o7recs) — O7b would prove nothing"
fi
oguard "$O7R" "$O7SHIP"
o7hit="$ORC"
oguard "$O7CR" "$O7SHIP"
o7ctl="$ORC"
# O7b — both arms graded together. Without the control arm a clean verdict on the first
# render is indistinguishable from a guard that stopped matching this model at all.
if [ "$o7hit" -eq 0 ] && [ "$o7ctl" -eq 0 ]; then
  PASS "O7b: a render whose only offence is the words 'derived' and 'desires' PUBLISHES (rc=$o7hit), as does the same render without them (rc=$o7ctl) — a bold-only sub-heading of an entry states no traveler value and is no longer a match key"
else
  FAIL "O7b: the structural sub-heading exclusion is not in the measured shape (with-the-words=$o7hit without=$o7ctl) — a value-free section name is keying a publish abort"
fi
# O7c — SENSITIVITY, and the reason O7b is a narrowing rather than a hole. Every value the
# same entry really states must still abort: the NAME arm and the need value. Two arms,
# because the exclusion could plausibly have swallowed either. This is the arm that
# CONVICTS a removed class source, which is why it carries the MD registration and O7b
# does not: with nonpublishable_values gone nothing aborts, so O7b would pass on a guard
# that had stopped reading the model at all.
O7N="$WORK/o7_name.html";  orender "$O7N"  'Rooming note: per-b70d will share with the group on the first night.'
O7V="$WORK/o7_value.html"; orender "$O7V"  'Pacing note: one of us tires quickly; long standing is not manageable on day two.'
o7c_assert() {
  local n v
  oguard "$O7N" "$O7SHIP"; n="$ORC"
  oguard "$O7V" "$O7SHIP"; v="$ORC"
  if [ "$n" -eq 1 ] && [ "$v" -eq 1 ]; then
    PASS "O7c: the same entry still aborts on its NAME (rc=$n) and on its need VALUE (rc=$v) — the sub-heading exclusion removed the section names and nothing the entry states"
  else
    FAIL "O7c: a real third-party value stopped aborting (name=$n value=$v) — the sub-heading exclusion is wider than a section name, or the class source is not running"
  fi
}
o7c_assert
# O7d — the exclusion is SHAPE-bounded, not a list of the three shipped literals. A bold
# span with ANY text beside it stays in class; a bold-only line does not. Both directions,
# because a one-directional check cannot tell a shape test from a literal match.
#
# The fixture word is deliberately NOT one of the three sub-headings this model ships. It
# was `Derived` — a member of that very list — which left this arm structurally unable to
# test the property its own verdict text asserts: a predicate rewritten AS the literal list
# would have excluded `Derived` and passed here, while being the second home for the class
# the declaration block rules out. `Update signals` is a section name the corpus declares
# (reference/data-model.md § Reserved keys) and this model does not ship, so that rewrite
# now FAILS this arm instead of passing it. Both fixture lines carry the SAME words and
# differ only in shape, which is what makes the verdict a reading of the shape rather than
# of the vocabulary — an exclusion keyed on these words in ANY shape fails the second arm.
O7BTD="$WORK/o7_bounded"
O7DNAME='Update signals'
omodel "$O7BTD" <<MD
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]

**${O7DNAME}**

**${O7DNAME}:** relayed by the operator at the request of the party lead
MD
o7d_assert() {
  local out bold text
  out="$(nonpublishable_values "$O7BTD" 2>/dev/null)"
  # Exact VALUE-field equality, not a substring scan: the question is whether the bold-only
  # line emitted a record of its own, and a substring would also answer yes to the label
  # line if the label prefix ever stopped being stripped — a FAIL for an unrelated reason.
  bold="$(awk -F'\t' -v v="$O7DNAME" '$4 == v { c++ } END { print c + 0 }' <<<"$out")"
  text="$(grep -cF 'relayed by the operator' <<<"$out")"
  if [ "$bold" -eq 0 ] && [ "$text" -eq 1 ]; then
    PASS "O7d: a bold-only line whose words are NOT one of the three sub-headings this model ships emits no record ($bold), while the SAME words carrying text as a bold LABEL still emit one ($text) — the exclusion reads the line shape, so a literal list of the three, or any rule keyed on this vocabulary, fails one of these two arms"
  else
    FAIL "O7d: the exclusion is not shape-bounded (bold-only=$bold bold-label-with-text=$text) — either it is matching literals, or it is swallowing labelled values, or the class source is not running"
  fi
}
o7d_assert
# O7e — the residual, asserted rather than left in prose. A markdown TABLE HEADER ROW is
# still emitted as a class record, so the entry's column names are still match keys. It
# takes all four of them in one render to abort, which is why no single ordinary word
# trips it — but it is the same class-source over-capture one shape over, and naming it
# here means the claim fails the day it stops being true.
o7tab="$(nonpublishable_values "$O7SHIP" 2>/dev/null | awk -F'\t' '$3 == "token" && $4 ~ /Governing constraint/ { c++ } END { print c + 0 }')"
if [ "$o7tab" -eq 1 ]; then
  PASS "O7e: the table HEADER row of the entry is still emitted as one token-rule record ($o7tab) — a stated residual of this narrowing, not a closed case, and it is pinned so the next change to the class source has to decide about it"
else
  FAIL "O7e: the table-header residual changed shape (records=$o7tab) — re-derive the class-source over-capture measurement before trusting O7b"
fi
# ── O7f/g/h — the arm O7d COULD NOT BE: a third-party VALUE wearing the section shape ──
# O7d grades the shape boundary in both directions and is correct about the shape. But
# BOTH of its inputs are SECTION-NAME-shaped — a bold-only line, and a bold label carrying
# text — so it asks "does the shape test work" and never "does the shape discriminate a
# section NAME from a VALUE". It did not. A third-party value written as a whole-line
# emphasis span was dropped from the class before the matcher saw it, and a render
# carrying that value verbatim went rc=1 at origin/main to rc=0 at the narrowing commit:
# a value that aborted before the release published after it. The enumeration was complete
# over the inputs it imagined and blind to the one that mattered.
#
# These three arms are the input class O7d cannot express, so the control can see it going
# forward. THREE renderings of ONE value, because the three failed for three different
# reasons — the list marker, the label-colon, and the bare line — and a single rendering
# would let two of them come back silently. The three shipped sub-headings sit in the SAME
# model, so a fix that merely reverts the narrowing fails here rather than passing: this is
# a discrimination assertion, not a shape assertion.
O7VAL='cannot manage more than one flight of stairs in a single stretch'
O7VTD="$WORK/o7_value_shape"
omodel "$O7VTD" <<MD
# Traveler Model [DERIVED]

## Quill \`[OPERATOR-PROVIDED]\` \`[THIRD-PARTY]\`

**Needs**

- **Trigger: $O7VAL**
- **$O7VAL**

**$O7VAL**

**Desires**

*None recorded.*

**Derived**

- **Documents:** unknown — no passport country on file
MD
O7VR="$WORK/o7_value.html";  orender "$O7VR"  "Pacing note: one of us $O7VAL, so day two stays flat."
O7VCR="$WORK/o7_value_ctl.html"; orender "$O7VCR" 'Pacing note: day two stays flat, with the hill gardens kept for the late light.'
# O7f — FIXTURE INTEGRITY, graded before the two verdicts it protects. The model must
# really carry all three renderings of the one value AND all three shipped sub-headings,
# and the render must really carry the value — otherwise O7g grades an absence and O7h
# grades a render that could not have aborted for this reason.
o7vsrc="$O7VTD/outputs/traveler-model.md"
if grep -qF -e "- **Trigger: $O7VAL**" "$o7vsrc" \
   && grep -qF -e "- **$O7VAL**" "$o7vsrc" \
   && grep -qxF "**$O7VAL**" "$o7vsrc" \
   && grep -qxF '**Needs**' "$o7vsrc" && grep -qxF '**Desires**' "$o7vsrc" \
   && grep -qxF '**Derived**' "$o7vsrc" \
   && grep -qF "$O7VAL" "$O7VR" && ! grep -qF "$O7VAL" "$O7VCR"; then
  PASS "O7f: the fixture carries one third-party value in all three whole-line-emphasis renderings (bulleted label, bulleted bare, unbulleted) beside all three shipped sub-headings, the render carries the value and the control render does not — O7g and O7h are graded against the discrimination, not against the shape"
else
  FAIL "O7f: the O7f/g/h fixture is not the shape claimed — O7g and O7h would prove nothing"
fi
# O7g — the CLASS SOURCE, both directions in one verdict. Reading the record stream rather
# than asking the predicate about itself: the model is short and every record is printed,
# so "is this value in class" is answered by the emitted rows and never by the detector.
o7g_assert() {
  local vals subs
  vals="$(nonpublishable_values "$O7VTD" 2>/dev/null | awk -F'\t' -v v="$O7VAL" '$4 == v { c++ } END { print c + 0 }')"
  subs="$(nonpublishable_values "$O7VTD" 2>/dev/null | awk -F'\t' '$4 == "Needs" || $4 == "Desires" || $4 == "Derived" { c++ } END { print c + 0 }')"
  if [ "$vals" -eq 3 ] && [ "$subs" -eq 0 ]; then
    PASS "O7g: all 3 whole-line-emphasis renderings of the third-party value are IN class ($vals) while all 3 structural sub-headings are OUT ($subs) — the exclusion discriminates a section NAME from a VALUE, and is not satisfied by either a revert or a bare shape test"
  else
    FAIL "O7g: the exclusion does not discriminate (value-renderings in class=$vals of 3, sub-headings in class=$subs of 0) — vals<3 is the fail-open this arm exists for, subs>0 is the false positive it must not reintroduce"
  fi
}
o7g_assert
# O7h — END TO END, with the control render that makes the abort a measurement. The record
# stream above proves membership; this proves the membership still reaches the publish
# verdict, which is where the regression was observable and where it mattered.
oguard "$O7VR"  "$O7VTD"; o7vhit="$ORC"
oguard "$O7VCR" "$O7VTD"; o7vctl="$ORC"
if [ "$o7vhit" -eq 1 ] && [ "$o7vctl" -eq 0 ]; then
  PASS "O7h: a render carrying the emphasis-wrapped third-party value verbatim ABORTS (rc=$o7vhit) while the same render without it PUBLISHES (rc=$o7vctl) — the class membership reaches the publish verdict, and the clean arm is what makes the abort a measurement rather than a guard that refuses everything"
else
  FAIL "O7h: the emphasis-wrapped value did not key the publish verdict (with-the-value=$o7vhit without=$o7vctl) — rc=0 on the first arm is the shipped fail-open; rc!=0 on the second is a guard refusing correct content"
fi
# ── O7i–O7m — ONE FIXTURE PER CONJUNCT, because a fixture that trips several ──
# certifies none of them. O7f/g/h above are honest about what they assert, but the value
# behind them is 64 characters and 12 words, so each of its three renderings is rejected
# by two to four of the predicate's conjuncts at once. Remove any single conjunct and the
# survivors still hold that value in class: the suite stays green at full count while the
# guarded set silently shrinks. It is the direction structural_subheading's own comment
# warns a future editor about — a change that drops one conjunct is removing values from
# the guarded set, whatever it says it is doing — and nothing here could see it happen.
#
# The predicate is a CONJUNCTION of four line properties, each of them a reason to keep a
# line IN class:
#   C1  the line is a list item                 — a list item states something
#   C2  the span carries sentence punctuation   — a label carries no sentence
#   C3  the span runs over 40 characters        — the short-run bound
#   C4  the span runs to more than three words  — below GUARD_NGRAM by construction
# A conjunct is load-bearing only where some fixture depends on it ALONE, so each arm
# below is built from a MINIMAL PAIR: two lines differing by exactly that one property,
# one in class and one out. The pair is what makes a single count two-directional — drop
# the conjunct and the in-class member leaves, delete the exclusion and the out-of-class
# member arrives — so neither failure mode needs an arm of its own to become visible.
#
# C3 and C4 are pinned AT the boundary rather than far from it: 41 characters against 40,
# four words against three. A bound RELAXED by one is caught, not only a bound removed.
#
# Deliberately NOT registered with md_flips, for the reason the registration block below
# gives: O7g is the one arm registered against nonpublishable_values for this subject, and
# five more registrations would re-grade the same removal five times over.
#
# The four line properties, measured on the FIXTURE. This grades the fixture and never the
# predicate: it answers whether a line carries exactly one of the four, which is what makes
# O7j–O7m single-conjunct arms. Whether the predicate still HONOURS a property is read off
# the class record stream in those arms. The two questions are kept apart deliberately —
# an arm that asked the predicate about itself would be worth nothing.
o7_props() { # <raw line> -> four digits, 1 = the line carries that property
  awk -v raw="$1" '
    BEGIN {
      t = raw
      c1 = (t ~ /^[ \t]*[-*+][ \t]+/) ? 1 : 0
      sub(/^[ \t]*[-*+][ \t]+/, "", t)
      sub(/^[ \t]+/, "", t); sub(/[ \t]+$/, "", t)
      inner = substr(t, 3, length(t) - 4)
      sub(/^[ \t]+/, "", inner); sub(/[ \t]+$/, "", inner)
      c2 = (inner ~ /[.,;:!?]/) ? 1 : 0
      c3 = (length(inner) > 40) ? 1 : 0
      n  = split(inner, a, " ")
      c4 = (n < 1 || n > 3) ? 1 : 0
      printf "%d%d%d%d", c1, c2, c3, c4
    }'
}
O7IC1='peanut anaphylaxis'                        # C1 pair — the SAME span, bulleted and bare
O7IC2='epilepsy, photosensitive'                  # C2 pair — one comma apart …
O7IC2B='epilepsy photosensitive'                  #           … from this one
O7IC3='wheelchair-accessible step-free bathrooms' # C3 pair — 41 characters …
O7IC3B='wheelchair-accessible step-free bathroom' #           … against 40, one letter apart
O7IC4='allergic to tree nuts'                     # C4 pair — four words …
O7IC4B='allergic to nuts'                         #           … against three, one word apart
O7ITD="$WORK/o7_isolation"
omodel "$O7ITD" <<MD
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]

- **${O7IC1}**

**${O7IC1}**

**${O7IC2}**

**${O7IC2B}**

**${O7IC3}**

**${O7IC3B}**

**${O7IC4}**

**${O7IC4B}**
MD
# One read of the record stream, counted by exact VALUE-field equality. Membership is read
# off the emitted rows and never from the predicate, the same way O7g reads it.
o7i_stream="$(nonpublishable_values "$O7ITD" 2>/dev/null)"
o7icount() { awk -F'\t' -v v="$1" '$4 == v { c++ } END { print c + 0 }' <<<"$o7i_stream"; }
# O7i — ISOLATION INTEGRITY, graded before the four verdicts it protects, in the same
# construction O7f uses for O7g/O7h. A fixture that silently gained a second property
# would leave its arm below passing while proving less — which is F6 one level up.
o7iA="$(o7_props "- **${O7IC1}**")"; o7iAp="$(o7_props "**${O7IC1}**")"
o7iB="$(o7_props "**${O7IC2}**")";   o7iBp="$(o7_props "**${O7IC2B}**")"
o7iC="$(o7_props "**${O7IC3}**")";   o7iCp="$(o7_props "**${O7IC3B}**")"
o7iD="$(o7_props "**${O7IC4}**")";   o7iDp="$(o7_props "**${O7IC4B}**")"
o7isrc="$O7ITD/outputs/traveler-model.md"
if [ "$o7iA" = "1000" ] && [ "$o7iB" = "0100" ] && [ "$o7iC" = "0010" ] && [ "$o7iD" = "0001" ] \
   && [ "$o7iAp" = "0000" ] && [ "$o7iBp" = "0000" ] \
   && [ "$o7iCp" = "0000" ] && [ "$o7iDp" = "0000" ] \
   && grep -qF -e "- **${O7IC1}**" "$o7isrc" \
   && grep -qxF "**${O7IC1}**"  "$o7isrc" && grep -qxF "**${O7IC2}**"  "$o7isrc" \
   && grep -qxF "**${O7IC2B}**" "$o7isrc" && grep -qxF "**${O7IC3}**"  "$o7isrc" \
   && grep -qxF "**${O7IC3B}**" "$o7isrc" && grep -qxF "**${O7IC4}**"  "$o7isrc" \
   && grep -qxF "**${O7IC4B}**" "$o7isrc"; then
  PASS "O7i: each of the four isolation fixtures carries EXACTLY ONE of the four line properties ($o7iA $o7iB $o7iC $o7iD, one digit per conjunct in C1 C2 C3 C4 order) and each minimal-pair partner carries none ($o7iAp $o7iBp $o7iCp $o7iDp), with both numeric pairs pinned at the boundary — 41 characters against 40, four words against three. A verdict in O7j–O7m therefore cannot be earned by a second conjunct"
else
  FAIL "O7i: the isolation fixtures are not one-property-each ($o7iA $o7iB $o7iC $o7iD, partners $o7iAp $o7iBp $o7iCp $o7iDp) or a fixture line is missing from the model — O7j–O7m would each prove less than they state"
fi
# O7j — C1, not a list item. Both lines carry the SAME span, so the list marker is the
# only difference between them and the count is the whole verdict.
o7jc="$(o7icount "$O7IC1")"
if [ "$o7jc" -eq 1 ]; then
  PASS "O7j: C1 (a list item states something, so it is not a section name) is LOAD-BEARING — the same span appears twice, bulleted and bare, and exactly 1 of the 2 lines is in class ($o7jc). Dropping that conjunct takes the bulleted value out of the guarded set"
else
  FAIL "O7j: C1 is not load-bearing (in class=$o7jc of the 2 lines carrying the span) — 0 is the bulleted value having LEFT the class, whether because the conjunct was dropped or because the exclusion widened back to a bare shape test; 2 is the exclusion no longer firing at all"
fi
# O7k — C2, no sentence punctuation in the span. One comma is the entire difference
# between the two spans, and it decides membership.
o7kin="$(o7icount "$O7IC2")"; o7kout="$(o7icount "$O7IC2B")"
if [ "$o7kin" -eq 1 ] && [ "$o7kout" -eq 0 ]; then
  PASS "O7k: C2 (a label carries no sentence punctuation) is LOAD-BEARING — one comma separates the two spans and decides class membership (punctuated in class=$o7kin, unpunctuated=$o7kout). The zero is stated against a paired non-empty arm rather than on its own"
else
  FAIL "O7k: C2 is not load-bearing (punctuated=$o7kin unpunctuated=$o7kout) — punctuated=0 is the conjunct dropped and a punctuated value gone from the guarded set; unpunctuated=1 is the exclusion no longer firing"
fi
# O7l — C3, the 40-character bound, pinned AT the boundary: 41 against 40, both of them
# three words and neither punctuated, so a bound relaxed by ONE character fails here.
o7lin="$(o7icount "$O7IC3")"; o7lout="$(o7icount "$O7IC3B")"
if [ "$o7lin" -eq 1 ] && [ "$o7lout" -eq 0 ]; then
  PASS "O7l: C3 (the span runs to at most 40 characters) is LOAD-BEARING AT THE BOUNDARY — 41 characters is in class and 40 is out ($o7lin / $o7lout), the two differing by one letter, so relaxing the bound by one is caught and not only removing it"
else
  FAIL "O7l: C3 is not load-bearing (41-character=$o7lin 40-character=$o7lout) — 41=0 is the bound dropped or relaxed past 41; 40=1 is the exclusion no longer firing"
fi
# O7m — C4, the three-word bound, pinned the same way: four words against three, both far
# under the character bound, so a bound relaxed by ONE word fails here.
o7min="$(o7icount "$O7IC4")"; o7mout="$(o7icount "$O7IC4B")"
if [ "$o7min" -eq 1 ] && [ "$o7mout" -eq 0 ]; then
  PASS "O7m: C4 (the span runs to at most three words) is LOAD-BEARING AT THE BOUNDARY — four words is in class and three is out ($o7min / $o7mout), the two differing by one word and both far under the character bound, so relaxing the word bound by one is caught and not only removing it"
else
  FAIL "O7m: C4 is not load-bearing (4-word=$o7min 3-word=$o7mout) — 4=0 is the bound dropped or relaxed past four; 3=1 is the exclusion no longer firing"
fi

# ── O7n–O7q — the exclusion is spelled `**`, and the OTHER FOUR renderings of ──
# the same emphasis stay IN class. ADR-008 residual 10 names them — `__X__`, `***X***`,
# `*X*`, `_X_` — records that all four remain in class, and DECLINES to widen the
# exclusion to cover them, because widening it would extend the first residual (a bare,
# unpunctuated, short span that a shape test cannot tell from a section name) over four
# more spellings, and nothing in the corpus reserves any of these renderings for a
# section name. That decline is the fail-CLOSED direction and it is not being reversed
# here.
#
# WHAT WAS MISSING IS THE CONVICTION, NOT THE DECISION. Measured before these arms
# existed: widen bold_only() to accept the four renderings and every O7 arm above stays
# green, because not one of them carries a fixture in any spelling but `**` — the
# fail-open re-opens with the suite at full count and nothing says so. A reasoned decline
# that no arm can catch being reversed is indistinguishable from a decline nobody made,
# which is the shape ADR-019 exists to remove. These arms make the decline enforced
# rather than merely intended.
#
# Each arm is the MINIMAL PAIR O7j uses, one spelling at a time: the SAME span written
# twice, once in the alternative rendering and once in `**`, so ONE count carries every
# direction that matters —
#   1  the shipped state — the alternative rendering is in class, the `**` twin is out
#   0  bold_only widened to that rendering — the value has LEFT the guarded set, which is
#      exactly the fail-open residual 10 declines, now visible
#   2  the exclusion not firing at all — the `**` twin is back in class
# Each pair carries its OWN span, so the four counts cannot borrow evidence from one
# another, and each arm greps its own two fixture lines so a vanished line reads as a
# broken fixture rather than as a verdict. Membership is read off the emitted record
# stream by exact VALUE-field equality, the way O7g and O7i–O7m read it, never from the
# predicate — an arm that asked the predicate about itself would be worth nothing.
#
# Deliberately NOT registered with md_flips, for the reason the O7i–O7m block gives: O7g
# is the one arm registered against nonpublishable_values for this subject, and four more
# registrations would re-grade that one removal four times over.
O7EU='vertigo'            # O7n — the `__X__` pair
O7ES='tinnitus'           # O7o — the `***X***` pair
O7EA='sleepwalks'         # O7p — the `*X*` pair
O7EL='claustrophobia'     # O7q — the `_X_` pair
O7ETD="$WORK/o7_emphasis"
omodel "$O7ETD" <<MD
# Traveler Model [DERIVED]

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]

__${O7EU}__

**${O7EU}**

***${O7ES}***

**${O7ES}**

*${O7EA}*

**${O7EA}**

_${O7EL}_

**${O7EL}**
MD
# One read of the record stream, counted per span by exact VALUE-field equality. Every
# span here is bare, unpunctuated, one word and far under 40 characters, so all four of
# structural_subheading's conjuncts are already satisfied on both members of each pair:
# the ONLY thing holding the alternative rendering in class is bold_only's `**` spelling,
# which is what makes each count a single-variable measurement of that spelling.
o7e_stream="$(nonpublishable_values "$O7ETD" 2>/dev/null)"
o7ecount() { awk -F'\t' -v v="$1" '$4 == v { c++ } END { print c + 0 }' <<<"$o7e_stream"; }
o7esrc="$O7ETD/outputs/traveler-model.md"
o7efx() { # <alt-rendering line> <bold twin line> -> 1 when both are in the model
  if grep -qxF "$1" "$o7esrc" && grep -qxF "$2" "$o7esrc"; then printf '1'; else printf '0'; fi
}
# O7n — `__X__`, the underscore spelling of strong emphasis.
o7n="$(o7ecount "$O7EU")"; o7nfx="$(o7efx "__${O7EU}__" "**${O7EU}**")"
if [ "$o7nfx" -eq 1 ] && [ "$o7n" -eq 1 ]; then
  PASS "O7n: \`__X__\` is IN class — the same span appears twice, once as \`__${O7EU}__\` and once as \`**${O7EU}**\`, and exactly 1 of those 2 lines is emitted ($o7n). The exclusion is spelled \`**\` and reaches no further, which is the decline ADR-008 residual 10 records: 0 is bold_only widened to this rendering and the value gone from the guarded set, 2 is the exclusion no longer firing at all"
else
  FAIL "O7n: the \`__X__\` pair is not in the measured shape (in class=$o7n of the 2 lines carrying the span, fixture=$o7nfx) — 0 is the FAIL-OPEN residual 10 declines to open: bold_only now accepts \`__X__\`, so a bare third-party value written that way has left the class. 2 is the exclusion no longer firing. fixture=0 is a missing model line, and this arm would have proven nothing"
fi
# O7o — `***X***`, triple-asterisk (strong + emphasis on one span).
o7o="$(o7ecount "$O7ES")"; o7ofx="$(o7efx "***${O7ES}***" "**${O7ES}**")"
if [ "$o7ofx" -eq 1 ] && [ "$o7o" -eq 1 ]; then
  PASS "O7o: \`***X***\` is IN class — the same span appears twice, once as \`***${O7ES}***\` and once as \`**${O7ES}**\`, and exactly 1 of those 2 lines is emitted ($o7o). The shape test is anchored on a span of exactly two asterisks a side, so a third asterisk leaves the line in class: 0 is bold_only widened to this rendering, 2 is the exclusion no longer firing at all"
else
  FAIL "O7o: the \`***X***\` pair is not in the measured shape (in class=$o7o of the 2 lines carrying the span, fixture=$o7ofx) — 0 is the FAIL-OPEN residual 10 declines to open: bold_only now accepts \`***X***\`, so a bare third-party value written that way has left the class. 2 is the exclusion no longer firing. fixture=0 is a missing model line, and this arm would have proven nothing"
fi
# O7p — `*X*`, single-asterisk emphasis.
o7p="$(o7ecount "$O7EA")"; o7pfx="$(o7efx "*${O7EA}*" "**${O7EA}**")"
if [ "$o7pfx" -eq 1 ] && [ "$o7p" -eq 1 ]; then
  PASS "O7p: \`*X*\` is IN class — the same span appears twice, once as \`*${O7EA}*\` and once as \`**${O7EA}**\`, and exactly 1 of those 2 lines is emitted ($o7p). A single-asterisk span is emphasis and not the strong-emphasis shape the exclusion tests, so it states a value as far as the class is concerned: 0 is bold_only widened to this rendering, 2 is the exclusion no longer firing at all"
else
  FAIL "O7p: the \`*X*\` pair is not in the measured shape (in class=$o7p of the 2 lines carrying the span, fixture=$o7pfx) — 0 is the FAIL-OPEN residual 10 declines to open: bold_only now accepts \`*X*\`, so a bare third-party value written that way has left the class. 2 is the exclusion no longer firing. fixture=0 is a missing model line, and this arm would have proven nothing"
fi
# O7q — `_X_`, single-underscore emphasis.
o7q="$(o7ecount "$O7EL")"; o7qfx="$(o7efx "_${O7EL}_" "**${O7EL}**")"
if [ "$o7qfx" -eq 1 ] && [ "$o7q" -eq 1 ]; then
  PASS "O7q: \`_X_\` is IN class — the same span appears twice, once as \`_${O7EL}_\` and once as \`**${O7EL}**\`, and exactly 1 of those 2 lines is emitted ($o7q). All four renderings this group pins are pinned the same way and separately, so widening the exclusion to any ONE of them reddens its own arm rather than hiding behind the other three: 0 is bold_only widened to this rendering, 2 is the exclusion no longer firing at all"
else
  FAIL "O7q: the \`_X_\` pair is not in the measured shape (in class=$o7q of the 2 lines carrying the span, fixture=$o7qfx) — 0 is the FAIL-OPEN residual 10 declines to open: bold_only now accepts \`_X_\`, so a bare third-party value written that way has left the class. 2 is the exclusion no longer firing. fixture=0 is a missing model line, and this arm would have proven nothing"
fi

# ── O8 — the guard's OWN zero carries a control arm (fix 5c) ────────────────
# nonpublishable_values reports "no class content" on the same branch a genuinely empty
# model reaches, so a BROKEN PARSE and an empty class were indistinguishable in every
# observable. That is the degenerate-PASS shape ADR-019 exists to eliminate, sitting
# inside the production predicate rather than inside an assertion: the rule is stated over
# suite assertions, and applying it to a predicate whose own verdict is a zero-population
# claim is a faithful extension of it.
#
# The guard now runs the SAME model-parse program over a known-marked control fixture
# built from the DECLARED selector before it accepts any zero, and refuses the zero when
# the control also reads zero.
O8TD="$WORK/o8_clean"
omodel "$O8TD" <<'MD'
# Traveler Model [DERIVED]

## Rowan
- Interests: markets, museums
MD
o8a_assert() {
  local broken clean
  # The mutation: the model-parse program emptied, which is what a parse that has stopped
  # enumerating looks like from inside. A subshell, so the live definition is untouched.
  broken="$( _GUARD_MODEL_AWK=''; nonpublishable_values "$O8TD" >/dev/null 2>&1; printf '%s' "$?" )"
  nonpublishable_values "$O8TD" >/dev/null 2>&1; clean=$?
  if [ "$broken" -eq 2 ] && [ "$clean" -eq 0 ]; then
    PASS "O8a: with the model parse emptied the guard reports UNDETERMINED (rc=$broken) instead of a clean empty class, while the SAME model on the intact parse publishes (rc=$clean) — the guard's own zero now carries a control arm, and a zero whose control also reads zero is refused as a broken probe rather than published"
  else
    FAIL "O8a: the parse sensitivity arm is not in the measured shape (broken-parse=$broken intact=$clean) — a broken=0 means a guard that enumerates nothing still publishes; an intact=2 means the control fixture stopped enumerating and every empty class now aborts"
  fi
}
o8a_assert

# ── O9 — the FIELD limb reads a wrapped value line by line (PR-6 / P2) ──────
# The two limbs of this class treated a wrapped value differently and only one of them
# was right. On the entry limb every line of a marked entry is its own record; on the
# field limb the value was whatever followed the colon on the FIRST line, so the
# continuation matched no field label, sat under no marked entry and fell through to
# nothing. A render carrying ONLY the continuation half of a wrapped `Passport:`
# PUBLISHED while the first line and the whole value both aborted.
#
# That is an under-block on the member #123 narrowed AC 3 to, which is what makes it a
# fix rather than a documentation correction. Both declared conjunctive rows are graded,
# because the calibration that shipped had only ever been exercised against one of them.
O9TD="$WORK/o9_passport"; mkdir -p "$O9TD/outputs"
O9DTD="$WORK/o9_documents"; mkdir -p "$O9DTD/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **Passport:** Ruritanian, valid to 2033\n  renewed at the Vilnius consulate in the spring of last year\n' > "$O9TD/outputs/traveler-model.md"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **Documents:** Ruritanian, valid to 2033\n  renewed at the Vilnius consulate in the spring of last year\n' > "$O9DTD/outputs/traveler-model.md"
O9F="$WORK/o9_first.html";  orender "$O9F" 'Border note: carry your Ruritanian passport, valid to 2033, at all times.'
O9C="$WORK/o9_cont.html";   orender "$O9C" 'Border note: it was renewed at the Vilnius consulate in the spring of last year.'
O9W="$WORK/o9_whole.html";  orender "$O9W" 'Border note: Ruritanian, valid to 2033, renewed at the Vilnius consulate in the spring of last year.'
O9K="$WORK/o9_clean.html";  orender "$O9K" 'Border note: bring comfortable shoes and a light jacket for the evenings.'
# O9a — fixture integrity, graded first. The model must really wrap the value, and the
# continuation render must carry ONLY the continuation half — no token of the first line —
# or O9b measures a render that would have aborted anyway.
o9recs="$(nonpublishable_values "$O9TD" 2>/dev/null | awk 'NF { c++ } END { print c + 0 }')"
if [ "$o9recs" -eq 2 ] \
   && grep -qF 'renewed at the Vilnius consulate' "$O9C" \
   && ! grep -qF 'Ruritanian' "$O9C" && ! grep -qF '2033' "$O9C"; then
  PASS "O9a: the wrapped Passport value emits $o9recs records (the first line and one sibling) and the continuation render carries no token of the first line — O9b grades the continuation and nothing else"
else
  FAIL "O9a: the O9 fixture is not the wrapped shape (records=$o9recs) — O9b would prove nothing"
fi
o9b_assert() {
  local f c w k dc dk
  oguard "$O9F" "$O9TD"; f="$ORC"
  oguard "$O9C" "$O9TD"; c="$ORC"
  oguard "$O9W" "$O9TD"; w="$ORC"
  oguard "$O9K" "$O9TD"; k="$ORC"
  oguard "$O9C" "$O9DTD"; dc="$ORC"
  oguard "$O9K" "$O9DTD"; dk="$ORC"
  if [ "$c" -eq 1 ] && [ "$dc" -eq 1 ] && [ "$f" -eq 1 ] && [ "$w" -eq 1 ] && [ "$k" -eq 0 ] && [ "$dk" -eq 0 ]; then
    PASS "O9b: a render carrying ONLY the continuation half of a wrapped value now aborts on both declared conjunctive rows (Passport rc=$c, Documents rc=$dc), while the first line (rc=$f) and the whole value (rc=$w) still abort and a clean render still publishes (rc=$k / rc=$dk) — the field limb reads a wrapped value line by line, as the entry limb already did"
  else
    FAIL "O9b: the field-limb continuation is not in the measured shape (Passport cont=$c first=$f whole=$w clean=$k / Documents cont=$dc clean=$dk) — a continuation reading 0 is the under-block returning; a clean reading 1 is the sibling record over-blocking"
  fi
}
o9b_assert
# O9c — the REWORDING LIMIT, measured on BOTH rules, because it is not one number and the
# coverage boundary used to state it as though it were. The sweep is the assertion: a
# prose claim about a bound is a claim nothing re-checks.
o9c_assert() {
  local n k j w val rew rc phrase_flip=0 conj_missed=0 nn=0 stopctl=-1
  local -a WD=(alpha bravo charlie delta echo foxtrot golf hotel india juliet kilo lima)
  local T="$WORK/o9c"; mkdir -p "$T/outputs" "$T/conj/outputs"
  for n in 5 6 7 8 9 10 11 12; do
    val=""; for ((j=0;j<n;j++)); do val="$val ${WD[$j]}"; done; val="${val# }"
    k=$(( (n+1)/2 )); rew=""; j=0
    for w in $val; do j=$((j+1)); if [ "$j" -eq "$k" ]; then rew="$rew zulu"; else rew="$rew $w"; fi; done
    rew="${rew# }"
    nn=$((nn+1))
    local R="$WORK/o9c_r.html"; orender "$R" "Note: $rew is recorded."
    printf '# Traveler Model [DERIVED]\n\n## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]\n- Specific: %s\n' "$val" > "$T/outputs/traveler-model.md"
    oguard "$R" "$T"; rc="$ORC"
    if [ "$n" -ge 10 ] && [ "$rc" -eq 1 ]; then phrase_flip=$((phrase_flip+1)); fi
    if [ "$n" -le 9 ] && [ "$rc" -eq 0 ]; then phrase_flip=$((phrase_flip+1)); fi
    printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **Passport:** %s\n' "$val" > "$T/conj/outputs/traveler-model.md"
    oguard "$R" "$T/conj"; rc="$ORC"
    if [ "$rc" -eq 0 ]; then conj_missed=$((conj_missed+1)); fi
  done
  # The control on the conjunctive claim: substituting a STOPLISTED word instead of a
  # distinctive one must still be caught, or "any length" is fragility rather than the
  # distinctive-token requirement.
  printf '# Traveler Model [DERIVED]\n\n## Rowan\n- **Passport:** Ruritanian issued at Vilnius in the spring\n' > "$T/conj/outputs/traveler-model.md"
  local S="$WORK/o9c_s.html"; orender "$S" 'Note: Ruritanian issued at Vilnius during the spring is recorded.'
  oguard "$S" "$T/conj"; stopctl="$ORC"
  if [ "$phrase_flip" -eq "$nn" ] && [ "$conj_missed" -eq "$nn" ] && [ "$stopctl" -eq 1 ]; then
    PASS "O9c: over $nn value lengths (n=5..12) a single worst-case reword defeats the PHRASE rule at n<=9 and is caught at n>=10, the derivable n>=2F boundary; it defeats the CONJUNCTIVE rule at EVERY length ($conj_missed/$nn), because that rule requires every distinctive token. Control: substituting a STOPLISTED word instead is still caught (rc=$stopctl), so the conjunctive limit is the distinctive-token requirement and not fragility in general"
  else
    FAIL "O9c: the rewording limit is not in the measured shape (phrase boundary held on $phrase_flip/$nn lengths, conjunctive missed $conj_missed/$nn, stopword control rc=$stopctl) — the coverage boundary states these numbers, so re-derive them before trusting either"
  fi
}
o9c_assert

# ── M6 — the pre-0.60.0 parity cells (CIAC-1) ────────────────────────────────
#
# The recorder installed before group L graded every page the suite rendered and passed to
# verify_publishable_content from there to here twice: through the guard as it stands, and
# through the same guard reading the page with v0.59.0's three readers in place of the head's —
# the guard before 0.60.0. A legacy rc=1 is a page that guard blocked. These cells ask, of that
# population and of no other, that the guard as it stands blocks each such page too, except a
# page the fence below names with an operator's ruling. Their reach is the pages this suite
# renders: a shape no arm here writes is not in the population, and a PASS says nothing about
# it. A page an arm grades under a stub, or with a command shadowed by a function, was skipped
# and counted rather than recorded, because what was graded there is not the guard.
#   M6a  the population: pairs recorded, calls skipped, the legacy-blocked denominator, legacy
#        rc=2 reported outside it, and #2055's leak page (M1t's) among the blocked
#   M6b  every legacy-blocked page is blocked at the head, unless the fence names it — the
#        fence held one way — and the pages only the fourth arm blocks (M7) are graded again
#        live, so a change to that arm moves this verdict after the manifest is fixed
#   M6c  the fence held the other way: an entry whose page no longer differs fails. The fence
#        is EMPTY at release; its check is shown able to fire on a planted entry
#   M6d  ARMED-RED: #2055's leak page graded with the published lookahead put back is flagged
#        by M6b's own predicate (head 0, legacy 1)
#   M6e  the recorder is gone and the production guard is back, byte for byte
# Every verdict names pages by basename only: no value reaches this log.
#
# THE FENCE, a literal list, one `<page basename> <reason-token>` per line. An entry is added
# only where an operator ruling records a deliberate limit for a shape the guard before 0.60.0
# blocked, and the same change narrows the milestone's AFTER for that shape.
PP_FENCE=''
PP_ON=0
pp_fenced() { # <page basename> <fence text> -> status 0 when the fence names the page
  local b
  while read -r b _; do
    if [ -n "$b" ] && [ "$b" = "$1" ]; then return 0; fi
  done <<EOF
$2
EOF
  return 1
}
pp_regressed() { # <page basename> <head rc> <legacy rc> <fence text> -> status 0 when M6b reports the pair
  [ "$3" = "1" ] && [ "$2" != "1" ] && ! pp_fenced "$1" "$4"
}
pp_stale() { # <fence text> -> each fenced page the manifest does NOT show blocked by the legacy guard alone, one per line
  local b
  while read -r b _; do
    [ -n "$b" ] || continue
    awk -F '|' -v P="$b" '$1 == P && $4 == "1" && $3 != "1" { f = 1 } END { exit f ? 0 : 1 }' "$PP_MAN" || printf '%s\n' "$b"
  done <<EOF
$1
EOF
}
pp_leakp="${M1T_SC##*/}"
pp_n="$(awk 'END { print NR + 0 }' "$PP_MAN")"
pp_sk="$(awk 'END { print NR + 0 }' "$PP_SKIP")"
pp_shd="$(awk '$1 == "shadowed" { c++ } END { print c + 0 }' "$PP_SKIP")"
pp_l1="$(awk -F '|' '$4 == "1" { c++ } END { print c + 0 }' "$PP_MAN")"
pp_l2="$(awk -F '|' '$4 == "2" { c++ } END { print c + 0 }' "$PP_MAN")"
pp_hn="$(awk -F '|' '$3 == "1" && $4 != "1" { c++ } END { print c + 0 }' "$PP_MAN")"
pp_leak="$(awk -F '|' -v P="$pp_leakp" '$1 == P && $4 == "1" { c++ } END { print c + 0 }' "$PP_MAN")"
if [ "$pp_l1" -ge 1 ] && [ "$pp_leak" -ge 1 ]; then
  PASS "M6a: pre-0.60.0 parity — over the pages the suite renders in groups L to O: $pp_n graded pairs recorded, $pp_sk calls skipped under a stub or a shadowed command ($pp_shd shadowed), $pp_l1 pairs the guard before 0.60.0 blocks (rc=1, the denominator), $pp_l2 it could not determine (rc=2, reported and outside the denominator), $pp_hn the head blocks and it did not, and #2055's leak page ($pp_leakp) among the blocked $pp_leak time(s). The legacy guard reads through v0.59.0's three readers, frozen copies that interpolate _GUARD_BLOCK_TAGS and _GUARD_BLOCK live"
else
  FAIL "M6a: pre-0.60.0 parity — the population is not a measurement: $pp_l1 legacy-blocked pair(s) of $pp_n recorded ($pp_sk skipped), #2055's leak page $pp_leakp blocked $pp_leak time(s) (want at least 1 of each). The recorder did not run, so the cells below would grade nothing"
fi
# The pages only the fourth arm blocks (M7), graded again live by M6b beside the manifest. The
# manifest is fixed once group O ends, so group MD's re-run of M6b with the fourth arm removed
# would read the same rows and stay green; these pages are graded through the guard as it stands
# at that moment, so that re-run sees the arm gone.
PP_LIVE="$M7A_SP $M7B_PP $M7B_NK $M7C_A $M7C_B $M7D_AP $M7E_U"
PP_NLIVE="$(printf '%s' "$PP_LIVE" | awk '{ print NF }')"
m6b_assert() { # one verdict
  local p h g den=0 nb=0 bad="" ctl=0 lv=0 lb=0
  if pp_regressed planted-control 0 1 ""; then ctl=1; fi
  while IFS='|' read -r p _ h g; do
    if [ "$g" = "1" ]; then den=$((den+1)); fi
    if pp_regressed "$p" "$h" "$g" "$PP_FENCE"; then nb=$((nb+1)); bad="$bad $p"; fi
  done < "$PP_MAN"
  for p in $PP_LIVE; do
    h="$( verify_publishable_content "$p" "$MTD" >/dev/null 2>&1; printf '%s' "$?" )"
    g="$(pp_legacy_verify "$p" "$MTD")"
    if [ "$g" = "1" ]; then lv=$((lv+1)); fi
    if pp_regressed "${p##*/}" "$h" "$g" "$PP_FENCE"; then lb=$((lb+1)); bad="$bad ${p##*/}"; fi
  done
  if [ "$ctl" -eq 1 ] && [ "$den" -ge 1 ] && [ "$nb" -eq 0 ] && [ "$PP_NLIVE" -ge 1 ] && [ "$lv" -eq "$PP_NLIVE" ] && [ "$lb" -eq 0 ]; then
    PASS "M6b: pre-0.60.0 parity — every one of the $den pairs the guard before 0.60.0 blocks, among the pages the suite renders, is blocked at the head, and the fence excuses none of them; the $lv pages only the fourth arm blocks, graded again live, are blocked at the head as the guard before 0.60.0 blocks them; the predicate flags a planted pair (head 0, legacy 1), so the zero is a measurement"
  else
    FAIL "M6b: pre-0.60.0 parity — $nb of $den legacy-blocked pair(s) in the manifest and $lb of the $PP_NLIVE pages graded live ($lv of them legacy-blocked, want all) publish or go undetermined at the head with no fence entry:$bad (predicate control $ctl, want 1). A page the guard before 0.60.0 caught is no longer caught"
  fi
}
m6b_assert
pp_fe="$(printf '%s\n' "$PP_FENCE" | awk 'NF { c++ } END { print c + 0 }')"
pp_st="$(pp_stale "$PP_FENCE" | awk 'NF { c++ } END { print c + 0 }')"
pp_lhp="${LHIT##*/}"
pp_lh="$(awk -F '|' -v P="$pp_lhp" '$1 == P && $3 == "1" && $4 == "1" { c++ } END { print c + 0 }' "$PP_MAN")"
pp_pl="$(pp_stale "$pp_lhp planted-control" | awk 'NF { c++ } END { print c + 0 }')"
pp_px=0; pp_regressed "$pp_leakp" 0 1 "$pp_leakp planted-control" || pp_px=1
if [ "$pp_st" -eq 0 ] && [ "$pp_lh" -ge 1 ] && [ "$pp_pl" -eq 1 ] && [ "$pp_px" -eq 1 ]; then
  PASS "M6c: pre-0.60.0 parity — the fence holds $pp_fe entr(ies) and none is stale; held both ways: a planted entry naming L1's page ($pp_lhp), which both guards block, is reported stale, and a planted entry naming a page excuses that page from M6b's predicate, so an entry can neither outlive its page's difference nor fail to excuse it"
else
  FAIL "M6c: pre-0.60.0 parity — $pp_st of $pp_fe fence entr(ies) stale (want 0); L1's page blocked by both guards $pp_lh time(s) (want at least 1); planted stale entry reported $pp_pl time(s) (want 1); planted entry excusing its page $pp_px (want 1). The fence names a page that no longer differs, or its check cannot tell"
fi
m6d_assert() { # one verdict
  local h g fl=no
  h="$(m1t_unfixed "$M1T_SC" "$MTD")"
  g="$(pp_legacy_verify "$M1T_SC" "$MTD")"
  if pp_regressed "${M1T_SC##*/}" "$h" "$g" "$PP_FENCE"; then fl=yes; fi
  if [ "$h" = "0" ] && [ "$g" = "1" ] && [ "$fl" = "yes" ]; then
    PASS "M6d: pre-0.60.0 parity — ARMED-RED: #2055's leak page, graded with the published lookahead put back to the exact closing tag, publishes (rc=$h) where the guard before 0.60.0 blocks it (rc=$g), and M6b's predicate flags the pair, so the cells can fail"
  else
    FAIL "M6d: pre-0.60.0 parity — the unfixed published program gives rc=$h (want 0), the legacy guard rc=$g (want 1), M6b's predicate flagged it: $fl (want yes). The cells could not see the regression #2055 repairs"
  fi
}
m6d_assert
pp_rec="$(declare -f verify_publishable_content)"
eval "$PP_VPC"
unset -f pp_real_verify
pp_gone=yes; declare -F pp_real_verify >/dev/null 2>&1 && pp_gone=no
pp_back=no; [ -n "$PP_VPC" ] && [ "$(declare -f verify_publishable_content)" = "$PP_VPC" ] && pp_back=yes
pp_was=no; [ "$pp_rec" != "$PP_VPC" ] && pp_was=yes
if [ "$pp_back" = yes ] && [ "$pp_was" = yes ] && [ "$pp_gone" = yes ]; then
  PASS "M6e: pre-0.60.0 parity — the recorder is gone: verify_publishable_content is byte-identical to the definition the suite sourced, the renamed production guard is undefined, and the recorder read before the restore differed from it, so the comparison can tell"
else
  FAIL "M6e: pre-0.60.0 parity — the recorder outlived its cells (production definition restored: $pp_back, recorder differed from it before the restore: $pp_was, renamed guard gone: $pp_gone; want yes for each). Every verdict after this point would grade the recorder"
fi

# ── Group R (#550 AC 5) — the change-summary content guard ───────────────────
# outputs/change-summary.md (C20) is `publish: internal`: it is shared out of band and
# never reaches the render, so verify_publishable_content -- HTML-bound, and called only
# from cmd_publish's plaintext limb on the file being published -- never sees it. The
# predicate for it is verify_summary_content, which reuses the CLASS SOURCE
# (nonpublishable_values) and the MATCHER (_norm_words + _guard_match) and adds only a
# markdown projection.
#
# Four properties are graded here, each with a control arm, because three of the four
# verdicts are the kind that a disarmed guard also produces:
#   R1  a clean summary passes                  (control: the class is really non-empty)
#   R2  a carried-through value aborts as a HIT (the sensitivity arm for R1)
#   R3  a degraded read is UNDETERMINED         (control: the same file, above the floor)
#   R4  the floor was RE-DERIVED, not copied    -- a legitimately short summary passes,
#       which it could not do under the HTML arm's 20-word floor
#   R5  the block sentinel is present and scoped, mirroring group N for this evaluand
echo
echo "Change-summary content guard (#550 AC 5):"

RTD="$WORK/porto-2026"; mkdir -p "$RTD/outputs"
cat > "$RTD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2026 [DERIVED]

## Rowan
- Passport: Irish, valid to 2027
MD

# The frontmatter every fixture below opens with. Written once: a summary that omitted
# it would not be an instance of the class, and a per-fixture copy is how the fixtures
# drift apart from each other.
rfront() { # <file>
  cat > "$1" <<'MD'
---
artifact: outputs/change-summary.md
schema-version: 1
trip: porto-2026
writer: hub
lifecycle: accumulate-append
provenance: derived
publish: internal
generated: 2026-05-10
status: pending
---

# Change Summary
MD
}

# R0 — CONTROL for R1. A clean verdict over an EMPTY class is not a clean verdict; it is
# a guard with nothing to match. Assert the class is populated before reading R1.
RRECS="$(nonpublishable_values "$RTD" 2>/dev/null)"; RN="$(printf '%s\n' "$RRECS" | grep -c .)"
if [ "$RN" -gt 0 ]; then
  PASS "R0: the fixture's non-publishable class is populated ($RN record(s)) — R1's clean verdict is a measurement rather than an empty scan"
else
  FAIL "R0: the fixture's class read empty ($RN records) — every verdict below would be vacuous"
fi

# R1 — a summary carrying only derived rows is clean.
RCLEAN="$WORK/r_clean.md"; rfront "$RCLEAN"
cat >> "$RCLEAN" <<'MD'

## 2026-05-10 — proposed change

**In plain language:** the Saturday viewpoint moved later in the afternoon.

| Bucket | Key | What | Before | After |
|--------|-----|------|--------|-------|
| MOVED | `evt-c052` | The viewpoint | May 16 (Sat) 14:00 | May 16 (Sat) 16:30 |
MD
verify_summary_content "$RCLEAN" "$RTD" >/dev/null 2>&1; RRC=$?
if [ "$RRC" -eq 0 ]; then PASS "R1: a summary of derived rows carrying no class value passes (rc=0)"; else FAIL "R1: a clean summary was rejected (rc=$RRC) — the predicate is unusable on correct input"; fi

# R2 — SENSITIVITY for R1. Without this arm R1 is satisfied by a guard that matches
# nothing at all. The value is carried in ONE block, which is what the conjunctive rule
# is defined over.
RHIT="$WORK/r_hit.md"; cp "$RCLEAN" "$RHIT"
printf '\nNote for the group: carry your Irish passport, valid to 2027, on the day.\n' >> "$RHIT"
if grep -qF 'Irish passport, valid to 2027' "$RHIT"; then
  PASS "R2a: the sensitivity fixture carries the passport value inside one block"
else
  FAIL "R2a: the sensitivity fixture does not carry the value — R2b would prove nothing"
fi
verify_summary_content "$RHIT" "$RTD" >/dev/null 2>&1; RRC=$?
if [ "$RRC" -eq 1 ]; then PASS "R2b: a non-publishable value carried into the summary aborts as a HIT (rc=1) — free text beside the derived rows is graded"; else FAIL "R2b: a carried-through passport value did not abort (rc=$RRC) — AC 5's bound is not enforced"; fi

# R3 — a degraded read is UNDETERMINED, never a pass. Its control is R4: the same
# predicate on a file that is short but legitimate must NOT return 2, or "undetermined"
# would just be this guard's name for "small".
RSHORT="$WORK/r_degraded.md"
printf '# Change\n' > "$RSHORT"
verify_summary_content "$RSHORT" "$RTD" >/dev/null 2>&1; RRC=$?
if [ "$RRC" -eq 2 ]; then PASS "R3: a summary below the $GUARD_SUMMARY_FLOOR-word floor is UNDETERMINED (rc=2), never a pass"; else FAIL "R3: a degraded read returned rc=$RRC — a guard that cannot read its evaluand must not report clean"; fi

# R4 — THE FLOOR WAS RE-DERIVED. This is the arm that fails if someone "simplifies"
# verify_summary_content by reusing verify_publishable_content's 20-word visible-text
# floor. A one-line summary is the class's minimum legitimate shape; under a 20-word
# floor every one of them is UNDETERMINED forever, with no remedy available to the
# operator — the unusable fail-closed control ADR-008 argues against twice.
RTINY="$WORK/r_tiny.md"
printf '# Change Summary\n\nTuesday dinner moved 19:00 to 20:00.\n' > "$RTINY"
RTN="$(strip_md_to_text_blocks "$RTINY" | _norm_words | grep -cv "^$_GUARD_BLOCK\$")"
verify_summary_content "$RTINY" "$RTD" >/dev/null 2>&1; RRC=$?
if [ "$RRC" -eq 0 ] && [ "$RTN" -lt 20 ] && [ "$RTN" -ge "$GUARD_SUMMARY_FLOOR" ]; then
  PASS "R4: a legitimate $RTN-word summary passes (rc=0) while sitting BELOW the HTML arm's 20-word floor — the floor is this artifact's, not an inherited one"
else
  FAIL "R4: the short-summary arm did not discriminate (rc=$RRC, words=$RTN, floor=$GUARD_SUMMARY_FLOOR) — either the floor was copied from the HTML arm or the fixture no longer sits between the two"
fi

# R5 — the block sentinel, mirroring group N for this evaluand. A summary accumulates a
# dated section per re-bake, so both class tokens recur across section boundaries by
# construction; with no sentinel every token lands in block 0, the conjunctive rule
# degrades to a bare word window, and the N-squared false abort ADR-008's first
# amendment fixed comes straight back on a different file type.
rsections() { # <out_file> <sections>
  rfront "$1"
  rs=1
  while [ "$rs" -le "$2" ]; do
    printf '\n## 2027-06-0%d — proposed change\n\n' "$rs" >> "$1"
    printf '| Bucket | Key | What | Before | After |\n|---|---|---|---|---|\n' >> "$1"
    printf '| MOVED | `evt-c052` | An Irish pub near the water | 19:00 | 20:00 |\n' >> "$1"
    rs=$((rs+1))
  done
}
RREC="$WORK/r_recur.md"; rsections "$RREC" 6
rirish="$(grep -c 'Irish' "$RREC")"; ryear="$(grep -c '2027' "$RREC")"
if [ "$rirish" -ge 2 ] && [ "$ryear" -ge 2 ] && ! grep -qF 'Irish, valid to 2027' "$RREC"; then
  PASS "R5a: both class tokens recur across dated-section boundaries ($rirish / $ryear lines) and the value itself never appears — the recurrence case is real"
else
  FAIL "R5a: the recurrence fixture is not set up as claimed (Irish=$rirish, 2027=$ryear) — R5b would prove nothing"
fi
rfalse=0
for rn in 1 2 3 4 6; do
  rf="$WORK/r_recur_$rn.md"; rsections "$rf" "$rn"
  verify_summary_content "$rf" "$RTD" >/dev/null 2>&1 || rfalse=$((rfalse+1))
done
if [ "$rfalse" -eq 0 ]; then
  PASS "R5b: an accumulating summary whose two class tokens recur across section boundaries passes at 1, 2, 3, 4 and 6 sections (0 false aborts) — the markdown projection emits block sentinels"
else
  FAIL "R5b: $rfalse of 5 section-counts falsely aborted — strip_md_to_text_blocks is not emitting \$_GUARD_BLOCK at markdown block boundaries, and the conjunctive window is pairing across them"
fi
# R5c — SENSITIVITY. Without it R5b is satisfied by a projection that emits a sentinel
# on EVERY line, which would scope the window so tightly nothing could ever match.
RRECH="$WORK/r_recur_hit.md"; rsections "$RRECH" 6
printf '\nNote for the group: carry your Irish passport, valid to 2027, on the day.\n' >> "$RRECH"
verify_summary_content "$RRECH" "$RTD" >/dev/null 2>&1; RRC=$?
if [ "$RRC" -eq 1 ]; then PASS "R5c: the same accumulating summary with the value inside ONE block still aborts (rc=1) — the sentinel narrowed the window, it did not disarm it"; else FAIL "R5c: a real same-block carry-through no longer aborts (rc=$RRC) — the projection over-corrected into a fail-open"; fi


# ── Group R, second remediation (#550 AC 1 / AC 4) — the bucket predicates ──
#
# R1–R5 grade what a summary may CARRY (AC 5). R6 grades what decides whether a summary
# is written at all: the bucket predicates. MOVED is where R6 started. Stage 7 found that
# predicate comparing `(day, role)` — the venue matrix's placement tuple — while the field
# a re-timed event actually changes, the clock time, sat in no structured source. A dinner
# moving 19:00 to 20:00 on the same day produced no row; and because the no-op rule (AC 4)
# suppresses a summary whose difference is empty, a re-bake whose ONLY change was that move
# published silently. AC 1's "what moved" failed and AC 4 inverted — the rule that exists
# to suppress noise suppressed the signal.
#
# WHY THESE ARMS READ THE CONTRACT RATHER THAN SPELLING IT. This predicate is a document
# contract, not a shipped function — the hub emits the summary. So R6 reads the placement
# tuple out of `agents/05-hub-planner.md`, resolves its field names against the C13 table
# header, and then EXECUTES it over the shipped witness. An arm that spelled `(day, time)`
# itself would stay green through a spec that had dropped the time back out, which is the
# one regression it exists to catch.
#
# THE DESIGN CONSTRAINT THE ARMS HOLD. Time is an attribute compared WITHIN a matched key
# and is never part of one. Fold it into the identity and a re-timed event becomes a
# different key: the diff then reports DROPPED + ADDED, two rows about one thing, which is
# worse than the silence it replaced. R6e reads that property directly (the key is on both
# sides of a time move) and R6f is its sensitivity arm — mutate the KEY instead and the
# same machinery does report DROPPED + ADDED with zero MOVED, so R6e's verdict is a
# discrimination rather than a shape that cannot fail.
#
# THE FOURTH BUCKET, AND WHY IT IS THE SAME MACHINERY. The bucket table declares MOVED and
# STATUS-CHANGED as two disjoint TUPLES over one key — `(day, time)` against `Status` — not
# as two algorithms. So the status arms choose their bucket by the tuple they project, and
# the set difference underneath is the one every other arm here already uses. R6g asserts a
# status-only re-bake is observable at all; R6h is the discrimination and is the reason the
# bucket is worth grading — an arm that fires on a status change while the machinery
# re-reports it as MOVED grades nothing, so R6h asserts BOTH directions of the separation
# and the disjointness of the two tuples as the contract declares them.
#
#   R6a  the Step-2 before-map for event-status HOLDS a time  (control: it holds status)
#   R6b  the C13 header carries `Time` in BOTH of its homes, and they agree
#   R6c  REGRESSION — a same-day time-only move yields exactly one MOVED row
#   R6d  CONTROL for R6c — an unmutated re-bake yields zero (AC 4's no-op rule, intact)
#   R6e  the moved key is on BOTH sides — MOVED, not DROPPED + ADDED
#   R6f  SENSITIVITY for R6e — a KEY mutation does report DROPPED + ADDED, 0 MOVED
#   R6g  THE ARM — a status-only re-bake yields exactly one STATUS-CHANGED row
#   R6h  DISCRIMINATION for R6g — status-only is not MOVED, time-only is not
#        STATUS-CHANGED, and the two tuples the contract states are disjoint
#   R6i  CONTROL for R6g, R6d's sibling — an unmutated re-bake yields zero STATUS-CHANGED
#
# Offline: three tracked files and awk. No network, no gh, no Node, no TTY. This group has
# no legitimate skip and is deliberately NOT declared in GUARD_EXPECTED_SKIPS.
echo
echo "The bucket predicates see a same-day time move and a status-only move (#550 AC 1 / AC 4, second remediation):"

R6_SPEC="$HERE/../agents/05-hub-planner.md"
R6_MODEL="$HERE/../reference/data-model.md"
R6_WITNESS="$HERE/../examples/data-architecture-demo/outputs/event-status.md"
R6D="$WORK/r550_moved"; mkdir -p "$R6D"

# What the before-map HOLDS for outputs/event-status.md, read from the Step 2 capture
# table in the emitter spec. Nothing downstream of the overwrite can reconstruct it, so a
# field absent from this cell is a field no bucket can ever compare.
r6_held_tuple() { # [<spec>]
  awk -F'|' '$0 ~ /`outputs\/event-status\.md`/ && $0 ~ /`Event ID`/ {
               v = $4; gsub(/[`() \t]/, "", v); print v; exit
             }' "${1:-$R6_SPEC}"
}

# The placement tuple MOVED compares for an Event ID, read from the bucket table. The
# limb is located by the key space it is stated for, so the venue limb's `(day, role)`
# cannot be mistaken for it.
r6_moved_tuple() { # [<spec>]
  awk '$0 ~ /^\|[[:space:]]*\*\*MOVED\*\*[[:space:]]*\|/ {
         p = index($0, "for an `Event ID`")
         if (p == 0) exit
         s = substr($0, 1, p - 1); t = ""
         while (match(s, /`\([^)]*\)`/)) {
           t = substr(s, RSTART + 2, RLENGTH - 4)
           s = substr(s, RSTART + RLENGTH)
         }
         gsub(/[ \t]/, "", t); print t; exit
       }' "${1:-$R6_SPEC}"
}

# The field STATUS-CHANGED compares, read from ITS OWN row of the same bucket table — the
# sibling of r6_moved_tuple and read for the same reason. Spelling `Status` here would let
# the arm stay green through a contract that had renamed the field or dropped the bucket,
# which is the one regression it exists to catch. The row is located by its bucket name, so
# MOVED's own `differs` clause cannot be mistaken for it. The contract's capitalisation is
# preserved: r6_project case-folds on lookup, so a failure message naming `Status` names the
# field the way the contract writes it.
r6_status_tuple() { # [<spec>]
  awk '$0 ~ /^\|[[:space:]]*\*\*STATUS-CHANGED\*\*[[:space:]]*\|/ {
         if (match($0, /`[^`]+`[[:space:]]*differs/)) {
           t = substr($0, RSTART + 1, RLENGTH - 1)
           sub(/`.*$/, "", t); gsub(/[ \t]/, "", t); print t; exit
         }
       }' "${1:-$R6_SPEC}"
}

# The C13 table header, one column per line, from whichever of its two homes is asked.
r6_c13_cols() { # <file>
  awk '/^\|[[:space:]]*Event ID[[:space:]]*\|/ {
         n = split($0, f, "|")
         for (i = 2; i < n; i++) { c = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", c); print c }
         exit
       }' "$1"
}

# Project the event table to <key TAB the named fields>, using the field names the CONTRACT
# gave. The fields are whatever the caller asks for — the placement tuple is one caller's
# choice and not this function's subject, which is what lets a second bucket reuse it whole.
# A field the header does not carry projects as <<ABSENT>> rather than being skipped: a
# dropped column must not quietly degrade into an equal comparison.
r6_project() { # <file> <comma-separated field names>
  awk -v cols="$2" '
    BEGIN { nc = split(cols, want, ",") }
    /^\|[[:space:]]*Event ID[[:space:]]*\|/ && !hdr {
      n = split($0, f, "|")
      for (i = 2; i < n; i++) { c = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", c); idx[tolower(c)] = i }
      hdr = 1; next
    }
    hdr && /^\|[[:space:]]*`evt-/ {
      n = split($0, f, "|")
      k = f[2]; gsub(/[` \t]/, "", k)
      out = ""
      for (j = 1; j <= nc; j++) {
        w = want[j]; gsub(/[ \t]/, "", w)
        ci = idx[tolower(w)]
        v = (ci ? f[ci] : "<<ABSENT>>"); gsub(/^[ \t]+|[ \t]+$/, "", v)
        out = out (j > 1 ? " ~ " : "") v
      }
      print k "\t" out
    }' "$1"
}

# Rewrite one cell of one row — the re-bake the arms below diff against. A column the
# header does not carry leaves the row untouched, which is precisely the pre-fix state.
r6_mutate() { # <file> <key> <column name> <new cell value>
  awk -v key="$2" -v col="$3" -v nv="$4" '
    /^\|[[:space:]]*Event ID[[:space:]]*\|/ && !hdr {
      n = split($0, f, "|")
      for (i = 2; i < n; i++) { c = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", c); idx[tolower(c)] = i }
      hdr = 1; print; next
    }
    hdr && /^\|[[:space:]]*`evt-/ {
      n = split($0, f, "|")
      k = f[2]; gsub(/[` \t]/, "", k)
      if (k == key) {
        ci = idx[tolower(col)]
        if (!ci) { print; next }
        f[ci] = " " nv " "
        line = f[1]
        for (i = 2; i <= n; i++) line = line "|" f[i]
        print line; next
      }
      print; next
    }
    { print }' "$1"
}

# The keyed set difference, computed exactly as the bucket table states it. MOVED and
# CHANGED select the same condition — key on both sides, projected value differs — because
# the table states them as two disjoint TUPLES over one key rather than as two algorithms.
# The caller names the bucket it is asserting, so a call site reads as the bucket it grades
# instead of asserting STATUS-CHANGED under the word MOVED, which is the conflation the arms
# below exist to refute.
r6_diff() { # <before-projection> <after-projection> <ADDED|DROPPED|MOVED|CHANGED>
  awk -F'\t' -v want="$3" '
    NR == FNR { b[$1] = $2; seenb[$1] = 1; next }
    { a[$1] = $2; seena[$1] = 1 }
    END {
      for (k in seena) {
        if (!(k in seenb)) { if (want == "ADDED") print k; continue }
        if (b[k] != a[k] && (want == "MOVED" || want == "CHANGED")) print k
      }
      if (want == "DROPPED") for (k in seenb) if (!(k in seena)) print k
    }' "$1" "$2"
}

r6_n() { printf '%s\n' "$1" | grep -c .; }

R6HELD="$(r6_held_tuple)"
R6TUP="$(r6_moved_tuple)"

# R6a — the before-map holds a time. Its control is `status`: the cell has held that
# since the artifact shipped, so a parse that cannot see it is reading the wrong cell and
# its verdict on `time` would be an artefact of the parse rather than of the contract.
if [ -z "$R6HELD" ]; then
  FAIL "R6a: the Step-2 capture table's held value for outputs/event-status.md did not parse at all — every arm below would be reading an empty contract"
elif ! grep -q 'status' <<<"$R6HELD"; then
  FAIL "R6a: the held value parsed as '$R6HELD', which does not name the status it has always held — the parse is off the intended cell, so its reading of 'time' proves nothing"
elif grep -q 'time' <<<"$R6HELD"; then
  PASS "R6a: the before-map captured at Step 2 holds a time for outputs/event-status.md (held = '$R6HELD') — a re-timed event has a before-value to be compared against"
else
  FAIL "R6a: the before-map holds '$R6HELD' — no time. Nothing captured before the overwrite can witness a re-timing, so a same-day time move is unobservable whatever the bucket table says"
fi

# R6b — the column exists, in both of its homes, spelled the same way. One table shape
# with two homes that disagree is the drift this arm exists to refuse.
R6WCOLS="$(r6_c13_cols "$R6_WITNESS")"
R6MCOLS="$(r6_c13_cols "$R6_MODEL")"
R6WN="$(r6_n "$R6WCOLS")"; R6MN="$(r6_n "$R6MCOLS")"
if [ "$R6WN" -eq 0 ] || [ "$R6MN" -eq 0 ]; then
  FAIL "R6b: the C13 header did not parse in one of its two homes (witness=$R6WN columns, model=$R6MN) — the column verdict would be vacuous"
elif [ "$R6WCOLS" != "$R6MCOLS" ]; then
  FAIL "R6b: the C13 header differs between reference/data-model.md and the shipped witness — one table shape, two homes, and they disagree about it"
elif grep -qx 'Time' <<<"$R6WCOLS"; then
  PASS "R6b: the C13 table carries a Time column in both of its homes and the two headers agree ($R6WN columns) — the field a re-bake re-times has a structured home"
else
  FAIL "R6b: the C13 table carries no Time column (header: $(printf '%s' "$R6WCOLS" | tr '\n' '/')) — the only clock time on a keyed row is free text in Notes, and AC 2 forbids diffing prose"
fi

# The key is read off the witness rather than spelled here: this group asserts a property
# of the shipped instance, not of a fixture written to make it true. The first `planned`
# row is taken, because `planned` is the only status a re-bake may move freely.
R6KEY="$(awk '
  /^\|[[:space:]]*Event ID[[:space:]]*\|/ && !hdr {
    n = split($0, f, "|")
    for (i = 2; i < n; i++) { c = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", c); idx[tolower(c)] = i }
    hdr = 1; next
  }
  hdr && /^\|[[:space:]]*`evt-/ {
    si = idx["status"]; if (!si) next
    n = split($0, f, "|"); s = f[si]; gsub(/[` \t]/, "", s)
    if (s == "planned") { k = f[2]; gsub(/[` \t]/, "", k); print k; exit }
  }' "$R6_WITNESS")"
R6BEFORE="$R6D/before.md"; cp "$R6_WITNESS" "$R6BEFORE"
R6AFTER="$R6D/after_time.md"; r6_mutate "$R6BEFORE" "$R6KEY" time '18:45' > "$R6AFTER"
R6PB="$R6D/proj_before.tsv"; r6_project "$R6BEFORE" "$R6TUP" > "$R6PB"
R6PA="$R6D/proj_after.tsv";  r6_project "$R6AFTER"  "$R6TUP" > "$R6PA"
R6ROWS="$(grep -c . "$R6PB")"
R6MOVED="$(r6_diff "$R6PB" "$R6PA" MOVED)"; R6MVN="$(r6_n "$R6MOVED")"

# R6c — THE REGRESSION ARM. Same day, same venue, same role, same status; only the clock
# moved. If this reports nothing, a real user-visible shift publishes in silence.
if [ -z "$R6KEY" ] || [ "$R6ROWS" -eq 0 ]; then
  FAIL "R6c: the witness yielded no planned-status key ('$R6KEY') or projected to 0 event rows under the contract's tuple ('$R6TUP') — the regression verdict below would be measuring an empty table"
elif [ "$R6MVN" -eq 1 ] && [ "$R6MOVED" = "$R6KEY" ]; then
  PASS "R6c: a same-day time-only re-bake of the shipped witness ($R6ROWS rows projected over '$R6TUP') yields exactly one MOVED row, keyed $R6KEY — AC 1's \"what moved\" is observable"
else
  FAIL "R6c: a same-day time-only re-bake yielded $R6MVN MOVED row(s) ('$R6MOVED') over tuple '$R6TUP' — the field that changed is not in the compared tuple, so the shift is silent and AC 4's no-op rule then suppresses the whole summary"
fi

# R6d — CONTROL for R6c, and AC 4 read directly. A comparison that fires on an unchanged
# re-bake would make R6c's single row meaningless and would append an empty section on
# every synthesis.
R6NOOP="$(r6_diff "$R6PB" "$R6PB" MOVED)"; R6NN="$(r6_n "$R6NOOP")"
if [ "$R6NN" -eq 0 ]; then
  PASS "R6d: an unchanged re-bake yields 0 MOVED rows over the same tuple — AC 4's no-op rule survives the widened predicate, so R6c's single row is the mutation and not a comparison that always fires"
else
  FAIL "R6d: an unchanged re-bake yielded $R6NN MOVED row(s) ('$R6NOOP') — the predicate fires on identity, every synthesis would append a section saying nothing, and R6c proves nothing"
fi

# R6e — the design constraint, read as a property of the two projections.
R6INB="$(cut -f1 "$R6PB" | grep -cx "$R6KEY")"
R6INA="$(cut -f1 "$R6PA" | grep -cx "$R6KEY")"
if [ "$R6INB" -eq 1 ] && [ "$R6INA" -eq 1 ]; then
  PASS "R6e: $R6KEY is present on both sides of the time move (before=$R6INB, after=$R6INA) — time is compared WITHIN the matched key and is not part of it"
else
  FAIL "R6e: $R6KEY is not on both sides of a time move (before=$R6INB, after=$R6INA) — time has joined the identity, so a re-timed event is a different event and the group is told a thing was dropped and an unrelated thing added"
fi

# R6f — SENSITIVITY for R6e. Without it, R6e is satisfied by any construction in which
# keys never change at all.
R6AKEY="$R6D/after_key.md"; r6_mutate "$R6BEFORE" "$R6KEY" 'event id' '`evt-zzzz`' > "$R6AKEY"
R6PK="$R6D/proj_key.tsv"; r6_project "$R6AKEY" "$R6TUP" > "$R6PK"
R6KM="$(r6_n "$(r6_diff "$R6PB" "$R6PK" MOVED)")"
R6KD="$(r6_n "$(r6_diff "$R6PB" "$R6PK" DROPPED)")"
R6KA="$(r6_n "$(r6_diff "$R6PB" "$R6PK" ADDED)")"
if [ "$R6KD" -eq 1 ] && [ "$R6KA" -eq 1 ] && [ "$R6KM" -eq 0 ]; then
  PASS "R6f: mutating the KEY instead of the time reports 1 DROPPED + 1 ADDED and 0 MOVED — the same machinery does produce the two-row shape, so R6e's verdict discriminates rather than being unable to fail"
else
  FAIL "R6f: a key mutation reported DROPPED=$R6KD ADDED=$R6KA MOVED=$R6KM, not the 1/1/0 that distinguishes a re-identification from a re-timing — R6e cannot be read as evidence"
fi

# The status limb. Same witness, same key, same set difference — a different projected
# tuple, which is the whole of what makes it a different bucket. `firmed` is chosen because
# the model declares it a legal forward move from `planned`, so the fixture asserts a state
# the model permits; it carries the same backtick markup the column's other cells carry, so
# the diff fires on the status and not on the formatting.
R6STUP="$(r6_status_tuple)"
R6SAFT="$R6D/after_status.md"; r6_mutate "$R6BEFORE" "$R6KEY" status '`firmed`' > "$R6SAFT"
R6PSB="$R6D/proj_status_before.tsv"; r6_project "$R6BEFORE" "$R6STUP" > "$R6PSB"
R6PSA="$R6D/proj_status_after.tsv";  r6_project "$R6SAFT"   "$R6STUP" > "$R6PSA"
R6PSX="$R6D/proj_place_status.tsv";  r6_project "$R6SAFT"   "$R6TUP"  > "$R6PSX"
R6PTS="$R6D/proj_status_time.tsv";   r6_project "$R6AFTER"  "$R6STUP" > "$R6PTS"
R6SROWS="$(grep -c . "$R6PSB")"
R6SC="$(r6_diff "$R6PSB" "$R6PSA" CHANGED)"; R6SCN="$(r6_n "$R6SC")"

# R6g — THE ARM. The fourth declared bucket, which shipped with nothing asserting it. If
# this reports nothing, a booking that fell through publishes in silence exactly the way a
# re-timed dinner used to.
if [ -z "$R6STUP" ] || [ "$R6SROWS" -eq 0 ]; then
  FAIL "R6g: the bucket table's STATUS-CHANGED row yielded no field name ('$R6STUP') or the witness projected to 0 event rows under it — the verdict below would be measuring an empty table, so re-read the STATUS-CHANGED row of the bucket table in agents/05-hub-planner.md"
elif [ "$R6SCN" -eq 1 ] && [ "$R6SC" = "$R6KEY" ]; then
  PASS "R6g: a status-only re-bake of the shipped witness ($R6SROWS rows projected over '$R6STUP') yields exactly one STATUS-CHANGED row, keyed $R6KEY — the fourth bucket is observable and no longer ships ungraded"
else
  FAIL "R6g: a status-only re-bake yielded $R6SCN STATUS-CHANGED row(s) ('$R6SC') over tuple '$R6STUP', not the single row keyed $R6KEY — either the field the contract names is absent from the compared tuple, or the set difference does not answer to this bucket at all"
fi

# R6h — DISCRIMINATION, and the reason the bucket is worth grading. One direction proves
# nothing: an arm that fires on a status change while the machinery re-reports that same
# change as MOVED has graded a re-timing twice and the status bucket not at all. So both
# directions are asserted, and so is the disjointness of the two tuples AS THE CONTRACT
# DECLARES THEM — the separation is then a property of the declaration rather than of the
# fixture. Each zero below is a real mutation that the OTHER projection does report (R6c
# and R6g are those two reports), which is what keeps it from being a zero that cannot move.
R6HXM="$(r6_n "$(r6_diff "$R6PB" "$R6PSX" MOVED)")"
R6HTS="$(r6_n "$(r6_diff "$R6PSB" "$R6PTS" CHANGED)")"
if [ "$R6HXM" -eq 0 ] && [ "$R6HTS" -eq 0 ] && [ "$R6STUP" != "$R6TUP" ]; then
  PASS "R6h: the buckets discriminate in both directions — a status-only move reports 0 MOVED over '$R6TUP', a time-only move reports 0 STATUS-CHANGED over '$R6STUP', and the two tuples the contract states are disjoint. A status change is not re-reported as a placement change, nor the reverse"
else
  FAIL "R6h: the buckets do not separate (status-only under placement=$R6HXM, expected 0; time-only under status=$R6HTS, expected 0; placement tuple '$R6TUP' vs status tuple '$R6STUP'). Fold one tuple into the other and both buckets report the same event twice while one of them reports nothing of its own"
fi

# R6i — CONTROL for R6g, and R6d's sibling one bucket over. Without it R6g's single row is
# satisfied by a comparison that fires on identity, and AC 4's no-op rule would append an
# empty status section on every synthesis.
R6SNN="$(r6_n "$(r6_diff "$R6PSB" "$R6PSB" CHANGED)")"
if [ "$R6SNN" -eq 0 ]; then
  PASS "R6i: an unchanged re-bake yields 0 STATUS-CHANGED rows over '$R6STUP' — AC 4's no-op rule survives the fourth bucket, so R6g's single row is the mutation and not a comparison that always fires"
else
  FAIL "R6i: an unchanged re-bake yielded $R6SNN STATUS-CHANGED row(s) over '$R6STUP' — the predicate fires on identity, every synthesis would append a status section saying nothing, and R6g proves nothing"
fi

# ── Group R, Stage 9 pre-merge (#550 AC 5) — the OTHER member of the class ───
#
# NOT A REMEDIATION, and the distinction matters to how a failure here is read. Nothing
# below fixes a defect: R7 exercises behaviour believed correct and never exercised, so
# it is expected to PASS on its first run. A failure would be a Stage 9 finding about
# what the release actually enforces, not a bug to repair in place.
#
# WHAT R1-R5 LEFT UNGRADED. AC 5 binds the summary against the ADR-008 non-publishable
# class, and reference/data-architecture.md § 5.6 declares that class as three rows over
# TWO members: `Passport`, on the profile and derived-model scopes, and the
# `[THIRD-PARTY]` entry mark on the derived model. R1-R5's fixture carries a `Passport`
# line and nothing else, so every verdict above is about one of the two. R0 asserts the
# class is non-empty, which is the arm that keeps those verdicts from being vacuous — but
# non-empty is not complete, and one populated record is what it takes to satisfy it.
#
# WHY THE GAP IS NOT COSMETIC, and it is a property of the DECLARATION rather than of the
# fixture. The two members do not travel the same code path:
#   • `Passport` declares rule `conjunctive`, which is the ONLY branch of _guard_match
#     that reads blk[]. R5 grades the markdown block sentinel, so R5 grades it for that
#     member alone.
#   • `[THIRD-PARTY]` declares `by-wordcount`, which rule_for resolves to `phrase` or
#     `token` at emission time against the VALUE. Neither branch reads blk[] at all, so
#     the sentinel R5 validates is INERT for exactly this member and nothing above
#     reaches its matching path.
# It is also the member with the more elaborate parse — an entry DENYLIST read at heading
# AND value granularity, with a supersession detector and an orphaned-mark backstop.
# Group O grades all of that through verify_publishable_content, the HTML arm.
# verify_summary_content consumes the SAME records through a DIFFERENT projection
# (strip_md_to_text_blocks, not strip_to_text / strip_to_published_text), and whether the
# records survive that projection was, until this arm, unmeasured on this side.
#
#   R7a  DENOMINATOR — this fixture puts an entry-limb record in class; R1-R5's does not
#   R7b  THE SUBJECT — a third-party value carried into the summary aborts as a HIT
#   R7c  SPECIFICITY — the summary R1 certifies clean still passes on the same fixture
#
# Offline like the rest of group R: fixtures under $WORK, two sourced functions, no gh,
# no npx, no TTY, no network. It cannot reach the SKIP path.
echo
echo "Change-summary content guard, the [THIRD-PARTY] member (#550 AC 5):"

# A SECOND fixture trip rather than another entry in $RTD. Adding a class member there
# would change what R0-R5 measure, and R7a's denominator is precisely that the two
# fixtures differ. The entry's shape is the derived model's own, as group O writes it:
# the mark on the heading, a closed-enum `Category` line (schema vocabulary, not a
# captured value — O6), a stated need line, and the Applies-to LINK that is deliberately
# NOT a member (reference/data-model.md § Needs: "the link, never a copy").
R7TD="$WORK/r7_trip"; mkdir -p "$R7TD/outputs"
cat > "$R7TD/outputs/traveler-model.md" <<'MD'
# Traveler Model — Porto 2026 [DERIVED]

## Rowan
- Passport: Irish, valid to 2027

## Quill [OPERATOR-PROVIDED] [THIRD-PARTY]
- Category: mobility
- Trigger: crowded escalators and long unbroken stair flights bring on vertigo
- Applies to: ## Hard Constraints -> "Mobility"
MD

# R7a — THE DENOMINATOR, and it is the whole reason the arms below are here. Both counts
# come from the SHIPPED class evaluator rather than from a grep of the fixture, so what
# is compared is what the guard will actually be handed: R1-R5's fixture must contribute
# NO entry-limb record — that is the coverage gap, measured rather than asserted — and
# this one must contribute at least one carrying a rule OTHER than `conjunctive`, which
# is what puts it on the phrase/token branches the block sentinel does not reach.
R7RECS="$(nonpublishable_values "$R7TD" 2>/dev/null)"; R7RC=$?
R7ERECS="$(printf '%s\n' "$R7RECS" | awk -F'\t' '$1 == "entry" { c++ } END { print c + 0 }')"
R7ENONC="$(printf '%s\n' "$R7RECS" | awk -F'\t' '$1 == "entry" && $3 != "conjunctive" { c++ } END { print c + 0 }')"
R7RULES="$(printf '%s\n' "$R7RECS" | awk -F'\t' '$1 == "entry" { printf "%s%s", (n++ ? " " : ""), $3 }')"
R7OLDE="$(nonpublishable_values "$RTD" 2>/dev/null | awk -F'\t' '$1 == "entry" { c++ } END { print c + 0 }')"
if [ "$R7RC" -ne 0 ]; then
  FAIL "R7a: the class could not be enumerated from the third-party fixture (rc=$R7RC) — every verdict below would be over an UNDETERMINED read rather than over a class"
elif [ "$R7OLDE" -ne 0 ]; then
  FAIL "R7a: R1-R5's fixture now contributes $R7OLDE entry-limb record(s) — those arms are no longer scoped to the \`Passport\` member alone, so the gap this arm closes has MOVED rather than closed and R7a's denominator no longer says what it claims"
elif [ "$R7ERECS" -ge 1 ] && [ "$R7ENONC" -ge 1 ]; then
  PASS "R7a: DENOMINATOR — the third-party fixture puts $R7ERECS entry-limb record(s) in class carrying rule(s) [$R7RULES], $R7ENONC of them NOT \`conjunctive\`, while R1-R5's fixture contributes $R7OLDE. So R1-R5 grade one declared member and the arms below grade the other, on the phrase/token branches that read no block sentinel"
else
  FAIL "R7a: the third-party fixture yielded $R7ERECS entry-limb record(s), $R7ENONC of them non-conjunctive, rules [$R7RULES] — the declared entry mark did not reach the class, so an abort below would be caused by the \`Passport\` record and would prove nothing about this member"
fi

# R7b — THE SUBJECT. The third-party need value carried into the summary as free text
# beside the derived rows. That residue is exactly what this predicate exists to grade:
# Layer 1's derivation bound (agents/05-hub-planner.md, `publish: bound` classes only)
# provably covers the derived ROWS and does not cover prose an agent writes around them.
R7HIT="$WORK/r7_hit.md"; rfront "$R7HIT"
cat >> "$R7HIT" <<'MD'

## 2026-05-10 — proposed change

**In plain language:** the Saturday viewpoint moved later in the afternoon.

| Bucket | Key | What | Before | After |
|--------|-----|------|--------|-------|
| MOVED | `evt-c052` | The viewpoint | May 16 (Sat) 14:00 | May 16 (Sat) 16:30 |

Note for the group: it moved because crowded escalators and long unbroken stair flights bring on vertigo.
MD
R7HITOK=0
grep -qF 'crowded escalators and long unbroken stair flights bring on vertigo' "$R7HIT" && R7HITOK=1
verify_summary_content "$R7HIT" "$R7TD" >/dev/null 2>&1; R7HRC=$?
if [ "$R7HITOK" -ne 1 ]; then
  FAIL "R7b: the fixture does not carry the third-party value inside one block — the verdict below would be about a summary that never held the subject"
elif [ "$R7HRC" -eq 1 ]; then
  PASS "R7b: a [THIRD-PARTY] need value carried into the change summary aborts as a HIT (rc=1) — AC 5 names two members of the ADR-008 class with \`or\`, and the summary guard is now measured against BOTH rather than against the one R1-R5 exercise"
else
  FAIL "R7b: a third-party need value carried into the summary returned rc=$R7HRC, not 1 — the summary guard enforces AC 5 for the \`Passport\` member and not for the \`[THIRD-PARTY]\` one. A third-party health need shared out of band with the group is the class this bound exists for"
fi

# R7c — SPECIFICITY. The summary R1 certifies clean against the ONE-member fixture must
# still certify clean against the TWO-member one. Without it R7b is satisfied by a guard
# that aborts on any summary once an entry-limb record is in class — which would make
# every trip carrying a third-party entry unable to publish a summary at all, the
# unusable fail-closed control ADR-008 argues against twice. Deliberately R1's own
# artifact rather than a fresh one: what is asserted is that GROWING THE CLASS changed no
# verdict on a correct summary, and only the same file can say that.
verify_summary_content "$RCLEAN" "$R7TD" >/dev/null 2>&1; R7CRC=$?
if [ "$R7CRC" -eq 0 ]; then
  PASS "R7c: SPECIFICITY — the summary R1 certifies clean still passes (rc=0) against the fixture carrying the [THIRD-PARTY] entry, whose class holds $R7ERECS further record(s). So R7b's abort is caused by the value that was carried, not by the entry's presence in the class"
else
  FAIL "R7c: a clean summary returned rc=$R7CRC against the third-party fixture — the entry-limb records abort or undetermine a correct summary on their own, so R7b is not evidence and no trip carrying a third-party entry could ever publish a change summary"
fi

# ── Group R, #2071 — the summary arm reads its projection's status ──────────────────
# verify_summary_content runs its one arm through _guard_arm, as each arm of the HTML guard
# does, and refuses a projection that failed after writing GUARD_SUMMARY_FLOOR words or more.
# Below the floor such a read was always refused (R3); above it the stream was a prefix of the
# summary, a value past the point of failure read as absent, and the summary certified clean.
#   R8a  FIXTURE INTEGRITY, graded first: each prefix clears the floor and carries no class
#        value, the summary carries the value past both, and the class with no values parses
#        empty and fresh against the summary its cells read
#   R8b  THE SUBJECT, and the arm registered with the oracle. Its cells are of both kinds in
#        ONE verdict: the projection, or a stage after it, fails after a prefix (rc=2, the
#        caller's pipefail on and off, and on a class with no values), and the same projection
#        succeeds (rc=1 on the trip's class, pipefail on and off; rc=0 on the class with no
#        values). With either arm helper removed every cell reads rc=2, so the failing cells
#        alone would still PASS; the succeeding ones are what make the registrations against
#        _guard_arm and _guard_words discriminate
#   R8c  THE MESSAGE: each refusal names the status read and carries no class value
# Every stub is defined inside the subshell that uses it, and dies with it, as L17's do.
R8_PFX="$WORK/r8_pfx_md.txt"; strip_md_to_text_blocks "$RHIT" > "$R8_PFX"
R8_PFXL=12
# The class with no values the *-noclass cells read is NEWER than the summary they read, so it
# is a fresh empty class and not a stale one, which is refused before any limb is reached.
R8N="$WORK/r8_noclass"; mkdir -p "$R8N/outputs"
printf '# Traveler Model [DERIVED]\n\n## Rowan\n- Interests: markets, museums\n\n### Needs\n- Category: rest\n  Specific: an early night on the first day of the trip\n' > "$R8N/outputs/traveler-model.md"
R8S="$WORK/r8_noclass_summary.md"; cp "$RHIT" "$R8S"
touch -t 202601011100 "$R8S"
touch -t 202601011200 "$R8N/outputs/traveler-model.md"
R8_CELLS='md-prefix md-prefix-pfoff norm-prefix-pfoff md-prefix-noclass md-ctl md-ctl-pfoff md-ctl-noclass'
R8_NCELLS=7

# The words in a stream file, counted by a reader that is not _guard_words, so the fixture
# check does not lean on the helper under test.
r8_words() { grep -c -v -x -F -e "$_GUARD_BLOCK" -e "$_GUARD_LINE" "$1"; }

r8_cell() { # <capture_file> <cell> -> rc on stdout
  local cap="$1" cell="$2" s="$RHIT" td="$RTD"
  case "$cell" in *-noclass) s="$R8S"; td="$R8N" ;; esac
  ( case "$cell" in *-pfoff) set +o pipefail ;; esac
    case "$cell" in
      md-prefix*)        strip_md_to_text_blocks() { head -n "$R8_PFXL" "$R8_PFX"; return 1; } ;;
      norm-prefix-pfoff) tr() { head -c 300 | command tr "$@"; return 1; } ;;
    esac
    verify_summary_content "$s" "$td" >/dev/null 2>"$cap" )
  printf '%s' "$?"
}
r8_want() { # <cell> -> the exact status that cell must return
  case "$1" in md-ctl-noclass) printf '0' ;; md-ctl*) printf '1' ;; *) printf '2' ;; esac
}

# R8a — FIXTURE INTEGRITY, graded FIRST, for L17a's reason: each prefix must clear the floor,
# so that its cell is refused by the status read and not by the floor, and neither may carry
# the value, or a cell could be decided by a match on the prefix.
head -n "$R8_PFXL" "$R8_PFX" | _line_sentinels | _norm_words > "$WORK/r8_pfx_md.words"
strip_md_to_text_blocks "$RHIT" | _line_sentinels | perl -0777 -pe '$_ = substr($_, 0, 300)' | _norm_words > "$WORK/r8_pfx_norm.words"
r8_wm="$(r8_words "$WORK/r8_pfx_md.words")"; r8_wn="$(r8_words "$WORK/r8_pfx_norm.words")"
r8_pv=0
for r8_f in "$WORK/r8_pfx_md.words" "$WORK/r8_pfx_norm.words"; do
  case " $(tr '\n' ' ' < "$r8_f") " in *" irish "*|*" 2027 "*) r8_pv=$((r8_pv+1)) ;; esac
done
r8_sv=0; case " $(strip_md_to_text_blocks "$RHIT" | _norm_words | tr '\n' ' ') " in *" irish "*" 2027 "*) r8_sv=1 ;; esac
nonpublishable_values "$R8N" "$R8S" > "$WORK/r8_noclass.out" 2>/dev/null; r8_nrc=$?
r8_ne=0; if [ "$r8_nrc" -eq 0 ] && [ ! -s "$WORK/r8_noclass.out" ]; then r8_ne=1; fi
if [ "$r8_wm" -ge "$GUARD_SUMMARY_FLOOR" ] && [ "$r8_wn" -ge "$GUARD_SUMMARY_FLOOR" ] && [ "$r8_pv" -eq 0 ] && [ "$r8_sv" -eq 1 ] && [ "$r8_ne" -eq 1 ]; then
  PASS "R8a: fixture integrity — the projection's prefix carries $r8_wm words and the normalization stage's $r8_wn, both at or above the $GUARD_SUMMARY_FLOOR-word floor and neither carrying the value, which the summary carries past both; the class with no values parses empty and fresh against its summary. The failing cells below are decided by the status read"
else
  FAIL "R8a: the fixtures are not set up as claimed (prefix words projection=$r8_wm normalization=$r8_wn want >=$GUARD_SUMMARY_FLOOR; prefixes carrying the value=$r8_pv want 0; summary carrying it=$r8_sv want 1; class with no values empty and fresh=$r8_ne want 1) — R8b would not be measuring the status read"
fi

# R8b — THE SUBJECT, and the arm registered with the oracle against the guard and both of its
# arm helpers. Captures go to the directory the caller names, so the oracle's re-runs cannot
# overwrite the ones R8c reads.
r8_assert() { # <capture_dir>
  local d="$1" cell rc want ok=0 n=0 bad=""
  mkdir -p "$d"
  for cell in $R8_CELLS; do
    n=$((n+1))
    rc="$(r8_cell "$d/$cell.err" "$cell")"; want="$(r8_want "$cell")"
    if [ "$rc" = "$want" ]; then ok=$((ok+1)); else bad="$bad $cell=rc$rc/want$want"; fi
  done
  if [ "$n" -eq "$R8_NCELLS" ] && [ "$ok" -eq "$n" ]; then
    PASS "R8b: all $n cells returned their exact status — the summary's projection failing after a prefix that clears the floor is UNDETERMINED (rc=2) with the caller's pipefail on and off, so is a normalization stage failing after a prefix, and so is a failing projection on a class with no values; the same projection succeeding is a HIT on the trip's class (rc=1, pipefail on and off) and publishes on the class with no values (rc=0). No path from a projection the summary guard could not read reaches a pass, and its refusals are the projection's, not a guard that refuses whatever it reads"
  else
    FAIL "R8b: $ok of $n cells (want $R8_NCELLS) returned their exact status —$bad. rc=0 on a failing cell is the summary certified from a prefix; rc=2 on a succeeding cell is a guard that refuses whatever it reads, which also satisfies every failing cell"
  fi
}
r8_assert "$WORK/r8live"

# R8c — THE MESSAGE. A refusal of a failing cell names the status read and nothing else: it is
# written before the class is read, so no value is in scope. Read from the captures R8b's live
# run wrote; the value scan carries its own sensitivity arm, a planted line it must find.
r8_named=0; r8_leak=0; r8_ncap=0
for r8_c in $R8_CELLS; do
  r8_cap="$WORK/r8live/$r8_c.err"
  [ -r "$r8_cap" ] || continue
  r8_ncap=$((r8_ncap+1))
  case "$(cat "$r8_cap")" in *[Ii]rish*|*2027*) r8_leak=$((r8_leak+1)) ;; esac
  case "$r8_c" in md-ctl*) continue ;; esac
  case "$(cat "$r8_cap")" in *"could not be read: its pipeline exited "*) r8_named=$((r8_named+1)) ;; esac
done
r8_plant="planted: carry your Irish passport, valid to 2027"
r8_ctl=0; case "$r8_plant" in *[Ii]rish*|*2027*) r8_ctl=1 ;; esac
if [ "$r8_ctl" -eq 1 ] && [ "$r8_ncap" -eq "$R8_NCELLS" ] && [ "$r8_named" -eq 4 ] && [ "$r8_leak" -eq 0 ]; then
  PASS "R8c: each of the 4 refusals names the status read, and none of the $r8_ncap captures carries the value; the value scan found the planted line, so its zero is a measurement"
else
  FAIL "R8c: captures=$r8_ncap of $R8_NCELLS, refusals naming the status read=$r8_named of 4, captures carrying the value=$r8_leak, scan control=$r8_ctl — a refusal is not the status read's, or the value reached a log this suite publishes"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group S (#552 AC 5) — the organizer-confirm gate on the republish path
#
# GROUP LETTER. This group's design specified `R`, chosen when `R` was the next free
# letter; #550 then took it for the change-summary content guard. `S` is the next free
# letter under the same rule — the monotonic sequence with `P` skipped, because `P`
# collides on prefix with the existing two-letter group `PF`.
#
# WHAT THIS GROUP GRADES, and why it is keyed the way it is. ADR-002 Decision 2 permits
# only a city-ambient client-side fetch, so every coordination marker lives inside the
# published bytes: showing a traveller that a change is pending REQUIRES a publish, of a
# site whose itinerary content is the one already published. A gate keyed on
# publish-as-such aborts that act and the pending state becomes unreachable. So the gate
# keys on ITINERARY-CONTENT CHANGE, and this group grades both halves of that:
#
#   S0   the itinerary projection MOVES on a plan edit          (the group's denominator)
#   S1   no published baseline -> ungated, exactly as today      (back-compat)
#   S2   plan moved, nothing confirmed -> ABORT, nothing pushed  (AC 2, rejected hold)
#   S3   plan moved, confirmation covers it -> proceed           (AC 1, confirmed republish)
#   S4   plan moved AFTER it was confirmed -> stale -> ABORT     (stale-approval hole)
#   S5   a malformed record is never read as approval            (ADR-007 §2 placeholder bound)
#   S6   the abort is the DEFAULT ARM, not an enumerated case    (structural)
#   S7   marker-only republish passes, and an edit under the same marker does not  (D6)
#   S8   rotate applies the gate itself                          (no rotate exemption)
#   S9   cmd_publish stays ungated and cannot overwrite a plan   (ungated-path proof)
#   S10  the two ADR-002 D4 guards are untouched by this gate    (CIAC-3)
#
# S6 IS THE ARM THAT DISCHARGES THE RISK. S2 and S4 test that the KNOWN rejection paths
# abort; S6 injects a token no author anticipated, and the empty string, and tests that
# those abort too — that the wildcard is the default rather than a listed case. Without
# it the design is merely tested against the failure mode; with it, no resolver output
# reaches a push.
#
# Every arm is offline: no network, no real gh, no Node, no TTY. The two end-to-end arms
# drive a shell-function mock of gh (and of npx, which preflight probes), the same
# technique groups J2/J3 already use — so this group has no legitimate skip and is
# deliberately NOT declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "Organizer-confirm gate (#552 AC 5):"
# The failure count as group S opens — read back by S16n (#719), the regression floor, which
# requires every verdict from here to the end of group T to have held under the new S2 body.
S_FAIL_BASE=$fail

# A render carrying real itinerary text, an optional coordination-notice band, and both
# a <style> rule and a <script> body — so the arms below cover the whole boundary rather
# than only the paragraph text.
s_render() { # <file> <viewpoint-time> <marker: none|pending|updated>
  local f="$1" t="$2" m="${3:-none}" band=""
  if [ "$m" != "none" ]; then
    band="<div class=\"coord-notice is-${m}\"><span>A change is ${m}</span> <time>2027-06-02</time></div>"
  fi
  cat > "$f" <<HTML
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>.coord-notice{background:#eee}.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
${band}
<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at ${t}. Then the riverside walk to the bridge.</p>
<p>Dinner at Tasca do Bairro, eight in the evening.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
}

# One trip dir per scenario. Separate dirs rather than one dir mutated between arms:
# several arms turn on a sidecar being ABSENT, and a fixture whose absence is produced by
# a removal is a fixture whose setup can silently half-succeed.
s_fixture() { # <name> <viewpoint-time> <marker> -> echoes the trip dir
  local d="$WORK/$1"
  mkdir -p "$d/outputs"
  s_render "$d/outputs/porto-travel-site.html" "$2" "$3"
  printf '%s' "$d"
}

s_record() { # <file> <digest> <second-key>
  printf 'digest=%s\n%s=2027-06-01T00:00:00Z\n' "$2" "$3" > "$1"
}

# ── S0 — THE DENOMINATOR. Every "unchanged" verdict below is an equality between two
# digests, and an equality between two EMPTY strings would satisfy most of them. This arm
# establishes that the projection reads something and that it discriminates.
S_SCRATCH="$WORK/s_scratch.html"
s_render "$S_SCRATCH" "14:00" none      ; S_DA="$(itinerary_digest "$S_SCRATCH")"
s_render "$S_SCRATCH" "16:30" none      ; S_DB="$(itinerary_digest "$S_SCRATCH")"
s_render "$S_SCRATCH" "14:00" pending   ; S_DAP="$(itinerary_digest "$S_SCRATCH")"
s_render "$S_SCRATCH" "14:00" updated   ; S_DAU="$(itinerary_digest "$S_SCRATCH")"
S_TEXTLEN=${#S_DA}
if [ "$S_TEXTLEN" -gt 0 ] && [ "$S_DA" != "$S_DB" ]; then
  PASS "S0: the itinerary projection is non-empty and MOVES when one scheduled time moves ($S_DA -> $S_DB) — the equalities asserted below are measurements, not two empty strings compared"
else
  FAIL "S0: the projection read '$S_DA' / '$S_DB' — it is empty, or it does not discriminate a plan edit, and every verdict in this group would be vacuous"
fi

# ── S1 — BACK-COMPAT. No published baseline means the gate has no anchor, and a trip with
# no coordination history republishes exactly as it did before this card. This is the
# property every already-published trip relies on, so it is graded first.
S1D="$(s_fixture s1 14:00 none)"
S_ST="$(change_confirmation_state "$S1D")"
( require_change_confirmation "$S1D" ) >/dev/null 2>&1; S_RC=$?
if [ "$S_ST" = "none-pending" ] && [ "$S_RC" -eq 0 ]; then
  PASS "S1: a trip with no published-itinerary baseline resolves none-pending and the gate returns 0 — behaviour is byte-preserved for every trip with no coordination state"
else
  FAIL "S1: an ungated trip resolved '$S_ST' (rc=$S_RC) — this card would break every trip published before it"
fi

# ── S2 — AC 2, THE REJECTED HOLD. The plan moved and nobody confirmed it.
S2D="$(s_fixture s2 16:30 none)"
s_record "$S2D/.published-itinerary" "$S_DA" published
S_ST="$(change_confirmation_state "$S2D")"
( require_change_confirmation "$S2D" ) >/dev/null 2>&1; S_RC=$?
if [ "$S_ST" = "unconfirmed" ] && [ "$S_RC" -ne 0 ]; then
  PASS "S2: an itinerary change with no confirmation resolves unconfirmed and the gate ABORTS (rc=$S_RC) — the published plan holds unchanged"
else
  FAIL "S2: an unconfirmed itinerary change resolved '$S_ST' (rc=$S_RC) — a change nobody approved would republish"
fi

# ── S3 — AC 1, THE CONFIRMED REPUBLISH.
S3D="$(s_fixture s3 16:30 none)"
s_record "$S3D/.published-itinerary" "$S_DA" published
s_record "$S3D/.change-confirmed"    "$S_DB" confirmed
S_ST="$(change_confirmation_state "$S3D")"
( require_change_confirmation "$S3D" ) >/dev/null 2>&1; S_RC=$?
if [ "$S_ST" = "confirmed" ] && [ "$S_RC" -eq 0 ]; then
  PASS "S3: a confirmation whose digest covers this exact itinerary content resolves confirmed and the gate returns 0 — the approved republish proceeds"
else
  FAIL "S3: a correctly confirmed change resolved '$S_ST' (rc=$S_RC) — the gate is unusable on its own happy path"
fi

# ── S4 — THE STALE-APPROVAL HOLE. The organizer confirmed, then the plan moved again. An
# approval that carried forward across a later re-bake would approve content nobody saw.
S4D="$(s_fixture s4 16:30 none)"
s_record "$S4D/.published-itinerary" "$S_DA" published
s_record "$S4D/.change-confirmed"    "$S_DA" confirmed
S_ST="$(change_confirmation_state "$S4D")"
( require_change_confirmation "$S4D" ) >/dev/null 2>&1; S_RC=$?
if [ "$S_ST" = "stale" ] && [ "$S_RC" -ne 0 ]; then
  PASS "S4: a confirmation recorded before a further re-bake resolves stale and the gate ABORTS (rc=$S_RC) — an approval cannot carry forward onto content it never covered"
else
  FAIL "S4: a superseded confirmation resolved '$S_ST' (rc=$S_RC) — a stale approval rides a later edit"
fi

# ── S5 — ADR-007 §2's PLACEHOLDER BOUND. A record that is present but says nothing is
# never read as approval. Two shapes, because they fail at different places: no digest
# line at all, and a placeholder value where a digest belongs.
S5D="$(s_fixture s5d 16:30 none)"
s_record "$S5D/.published-itinerary" "$S_DA" published
printf 'confirmed=2027-06-01T00:00:00Z\nnote=approved verbally\n' > "$S5D/.change-confirmed"
S_ST5A="$(change_confirmation_state "$S5D")"
S5E="$(s_fixture s5e 16:30 none)"
s_record "$S5E/.published-itinerary" "$S_DA" published
printf 'digest=[TBD]\nconfirmed=2027-06-01T00:00:00Z\n' > "$S5E/.change-confirmed"
S_ST5B="$(change_confirmation_state "$S5E")"
if [ "$S_ST5A" = "unconfirmed" ] && [ "$S_ST5B" = "unconfirmed" ]; then
  PASS "S5: a record with no digest line ($S_ST5A) and a record whose digest is a placeholder ($S_ST5B) both resolve unconfirmed — the branch tests the VALUE, so a malformed record is never approval"
else
  FAIL "S5: malformed records resolved '$S_ST5A' / '$S_ST5B' — one of them is being read as an approval"
fi

# ── S6 — STRUCTURAL. THIS IS THE ARM THAT DISCHARGES THE RISK THE DESIGN WAS BUILT
# AGAINST. S2 and S4 prove the two KNOWN rejection paths abort. S6 proves the UNKNOWN ones
# do — that `*)` is the default arm rather than an enumerated case — by injecting a token
# no author anticipated and, separately, the empty string. Its control arm is the same
# stub emitting `confirmed`: without that arm, a require_change_confirmation that aborted
# on absolutely everything would pass S6 while being useless.
S_ORIG_RESOLVER="$(declare -f change_confirmation_state)"
change_confirmation_state() { printf 'zzz-unrecognised-token'; }
( require_change_confirmation "$S1D" ) >/dev/null 2>&1; S_RC6A=$?
change_confirmation_state() { printf ''; }
( require_change_confirmation "$S1D" ) >/dev/null 2>&1; S_RC6B=$?
change_confirmation_state() { printf 'confirmed'; }
( require_change_confirmation "$S1D" ) >/dev/null 2>&1; S_RC6C=$?
eval "$S_ORIG_RESOLVER"
if [ "$S_RC6C" -eq 0 ]; then
  PASS "S6a: CONTROL — the injection harness itself lets an allowlisted token through (rc=$S_RC6C), so a non-zero below is the wildcard firing rather than the gate refusing everything"
else
  FAIL "S6a: the control stub emitting 'confirmed' did NOT proceed (rc=$S_RC6C) — S6b would prove nothing"
fi
if [ "$S_RC6A" -ne 0 ] && [ "$S_RC6B" -ne 0 ]; then
  PASS "S6b: an unrecognised token (rc=$S_RC6A) and the EMPTY STRING (rc=$S_RC6B) both abort — the proceed set is the allowlist and the abort is the default arm, so no resolver output reaches a push"
else
  FAIL "S6b: unrecognised=$S_RC6A empty=$S_RC6B — at least one unlisted token PUBLISHES; the case has been inverted into an enumerated-abort with a permissive default"
fi
if [ "$(change_confirmation_state "$S1D")" = "none-pending" ]; then
  PASS "S6c: the real resolver was restored after the injection — the arms below grade production code"
else
  FAIL "S6c: the stub survived the restore; every arm after S6 is grading a stub"
fi

# ── S7 — D6, THE MARKER-ONLY REPUBLISH. #551 must be able to publish a site whose
# itinerary content is the published one and whose coordination-state marker says pending.
# The three arms are one assertion and two controls: without the S7c control, S7a and S7b
# are equally satisfied by a projection that discriminates nothing at all.
S7D="$(s_fixture s7d 14:00 pending)"
s_record "$S7D/.published-itinerary" "$S_DA" published
S_ST7A="$(change_confirmation_state "$S7D")"
( require_change_confirmation "$S7D" ) >/dev/null 2>&1; S_RC7A=$?
S7E="$(s_fixture s7e 14:00 updated)"
s_record "$S7E/.published-itinerary" "$S_DAP" published
S_ST7B="$(change_confirmation_state "$S7E")"
( require_change_confirmation "$S7E" ) >/dev/null 2>&1; S_RC7B=$?
S7F="$(s_fixture s7f 16:30 pending)"
s_record "$S7F/.published-itinerary" "$S_DA" published
S_ST7C="$(change_confirmation_state "$S7F")"
( require_change_confirmation "$S7F" ) >/dev/null 2>&1; S_RC7C=$?
if [ "$S_ST7A" = "none-pending" ] && [ "$S_RC7A" -eq 0 ]; then
  PASS "S7a: a republish whose itinerary content is unchanged and whose coordination-state marker was ADDED passes the gate (state=$S_ST7A, rc=$S_RC7A) — 'change pending' is reachable"
else
  FAIL "S7a: adding a coordination marker resolved '$S_ST7A' (rc=$S_RC7A) — the pending state cannot be shown, and #551 AC 1 and AC 3 fail inside this file"
fi
if [ "$S_ST7B" = "none-pending" ] && [ "$S_RC7B" -eq 0 ] && [ "$S_DAP" = "$S_DAU" ]; then
  PASS "S7b: the marker CHANGING (pending -> updated, with its date) also passes (state=$S_ST7B, rc=$S_RC7B) and both marked renders carry the same itinerary digest as the unmarked one — the notice band is outside the boundary, not merely absent from it"
else
  FAIL "S7b: a marker transition resolved '$S_ST7B' (rc=$S_RC7B); marked digests $S_DAP / $S_DAU vs unmarked $S_DA — the band is inside the digest and a standing confirmation is invalidated by a state change"
fi
if [ "$S_ST7C" != "none-pending" ] && [ "$S_RC7C" -ne 0 ]; then
  PASS "S7c: CONTROL — the SAME marker with the itinerary edited underneath it still ABORTS (state=$S_ST7C, rc=$S_RC7C) — the excision removes the band, not the plan, so S7a/S7b are not a projection that ignores everything"
else
  FAIL "S7c: an itinerary edit published under a coordination marker resolved '$S_ST7C' (rc=$S_RC7C) — the band excision is swallowing plan content and an unapproved change would ship behind a marker"
fi
# S7d — THE CAP'S POLARITY. The excision is bounded, and the bound is what forbids the
# only dangerous failure: an excision running PAST the band would delete plan content and
# a real change would read as "unchanged". A band the pattern cannot resolve must therefore
# leave its text IN the digest — the republish then reads as a change and aborts, which is
# an inconvenience rather than a leak. This arm asserts that polarity on a band whose
# closing tag never arrives.
S7G="$(s_fixture s7g 14:00 none)"
cat > "$S7G/outputs/porto-travel-site.html" <<'HTML'
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>.coord-notice{background:#eee}.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
<div class="coord-notice is-pending"><span>A change is pending</span>
<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at 14:00. Then the riverside walk to the bridge.</p>
<p>Dinner at Tasca do Bairro, eight in the evening.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
s_record "$S7G/.published-itinerary" "$S_DA" published
S_ST7D="$(change_confirmation_state "$S7G")"
( require_change_confirmation "$S7G" ) >/dev/null 2>&1; S_RC7D=$?
if [ "$S_ST7D" != "none-pending" ] && [ "$S_RC7D" -ne 0 ]; then
  PASS "S7d: an unterminated coordination band is NOT excised, so its text stays inside the digest and the republish ABORTS (state=$S_ST7D, rc=$S_RC7D) — the bounded excision fails closed, and cannot run past the band into plan content"
else
  FAIL "S7d: a band the pattern could not resolve still resolved '$S_ST7D' (rc=$S_RC7D) — the excision is unbounded and can delete itinerary content, which is the one failure direction that hides a real change"
fi

# ── S8 / S9 — the two END-TO-END arms, driven by a shell-function mock of gh and npx
# (groups J2/J3 use the same technique). These are the arms that prove the gate's POSITION
# rather than its logic: on an abort nothing has been cloned and nothing pushed.
S_GHLOG="$WORK/s_gh.log"
gh() {   # mock: record the call, answer the read-only probes, create/clone nothing real
  printf '%s\n' "$*" >> "$S_GHLOG"
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 0 ;;
    "auth status") printf "Token scopes: 'repo'\n" ;;
    *)             return 0 ;;
  esac
}
npx() { return 0; }   # preflight probes for it; no arm below reaches an encryption

# S8 — ROTATE INHERITS THE GATE, and must not be exempted. cmd_rotate re-encrypts the same
# render, so an exempt rotate is a silent republish of unapproved content by another route.
S8D="$(s_fixture s8 16:30 none)"
s_record "$S8D/.published-itinerary" "$S_DA" published
: > "$S_GHLOG"
( cmd_rotate "$S8D" ) >/dev/null 2>&1; S_RC8A=$?
S_LOG8A="$(cat "$S_GHLOG")"
S_REACHED8A="$(printf '%s\n' "$S_LOG8A" | grep -c .)"
S8E="$(s_fixture s8e 16:30 none)"
s_record "$S8E/.published-itinerary" "$S_DA" published
s_record "$S8E/.change-confirmed"    "$S_DB" confirmed
: > "$S_GHLOG"
( cmd_rotate "$S8E" ) >/dev/null 2>&1
S_LOG8B="$(cat "$S_GHLOG")"
case "$S_LOG8B" in *"repo clone"*) S_CLONE8B=1 ;; *) S_CLONE8B=0 ;; esac
case "$S_LOG8A" in *"repo clone"*) S_CLONE8A=1 ;; *) S_CLONE8A=0 ;; esac
if [ "$S_REACHED8A" -gt 0 ] && [ "$S_CLONE8B" -eq 1 ]; then
  PASS "S8a: CONTROL — the mock was reached on the blocked run ($S_REACHED8A gh calls) and a CONFIRMED rotate does go on to clone the per-trip repo, so the zero asserted below is a measurement rather than a run that never got started"
else
  FAIL "S8a: reached=$S_REACHED8A clone-on-confirmed=$S_CLONE8B — the harness never exercised the publish path, and S8b would prove nothing"
fi
if [ "$S_RC8A" -ne 0 ] && [ "$S_CLONE8A" -eq 0 ]; then
  PASS "S8b: rotate on an unconfirmed itinerary change ABORTS (rc=$S_RC8A) and never clones the per-trip repo — rotate applies the gate itself, and it fires before any network effect"
else
  FAIL "S8b: rotate returned rc=$S_RC8A with clone=$S_CLONE8A — rotate is exempt from the gate, which republishes unapproved content by another route"
fi

# S9 — cmd_publish STAYS UNGATED, and that is safe rather than assumed: it dies when the
# per-trip repo already exists, so it structurally cannot overwrite a published plan.
S9D="$(s_fixture s9 16:30 none)"
s_record "$S9D/.published-itinerary" "$S_DA" published
: > "$S_GHLOG"
( cmd_publish "$S9D" ) >/dev/null 2>&1; S_RC9=$?
S_LOG9="$(cat "$S_GHLOG")"
case "$S_LOG9" in *"repo view"*)   S_VIEW9=1 ;;   *) S_VIEW9=0 ;; esac
case "$S_LOG9" in *"repo create"*) S_CREATE9=1 ;; *) S_CREATE9=0 ;; esac
unset -f gh npx
if [ "$S_VIEW9" -eq 1 ] && [ "$S_RC9" -ne 0 ] && [ "$S_CREATE9" -eq 0 ]; then
  PASS "S9a: cmd_publish against an existing per-trip repo dies (rc=$S_RC9) after the existence probe and before any repo creation — leaving it ungated cannot overwrite a published plan"
else
  FAIL "S9a: probe=$S_VIEW9 rc=$S_RC9 create=$S_CREATE9 — cmd_publish reached a publish over an existing repo, and the ungated-path argument does not hold"
fi
# The structural half of the same claim, read from the PARSED function bodies rather than
# from source text: bash discards comments, so a mention of an identifier in a comment
# cannot fake a call site.
S_BODY_PUB="$(declare -f cmd_publish)"
S_BODY_UPD="$(declare -f cmd_update)"
# #719, the scope-lock's C5: cmd_update reaches the gate through ONE call line,
# require_publish_guards, which calls require_change_confirmation unchanged and then the
# render's approval-code guard — so relocating the gate onto #85's path stays a one-line move.
# The gate is therefore read through that wrapper here, and ONLY where cmd_update's own parsed
# body calls it: a wrapper that still exists but is no longer called gates nothing, and must not
# keep S9b and S10 green.
case "$S_BODY_UPD" in *require_publish_guards*) S_BODY_UPD="$S_BODY_UPD
$(declare -f require_publish_guards 2>/dev/null)" ;; esac
case "$S_BODY_PUB" in *require_change_confirmation*) S_PUBGATED=1 ;; *) S_PUBGATED=0 ;; esac
case "$S_BODY_PUB" in *record_published_itinerary*)  S_PUBRECS=1 ;; *) S_PUBRECS=0 ;; esac
case "$S_BODY_UPD" in *require_change_confirmation*) S_UPDGATED=1 ;; *) S_UPDGATED=0 ;; esac
if [ "$S_UPDGATED" -eq 1 ] && [ "$S_PUBGATED" -eq 0 ] && [ "$S_PUBRECS" -eq 1 ]; then
  PASS "S9b: cmd_update calls the gate and cmd_publish does not, while cmd_publish DOES record the baseline — recording is not gating, and the sensitivity arm (cmd_update=$S_UPDGATED) shows the detector fires"
else
  FAIL "S9b: cmd_update gated=$S_UPDGATED, cmd_publish gated=$S_PUBGATED, cmd_publish records=$S_PUBRECS — the gate has moved onto the wrong path, or the first-publish baseline is no longer established"
fi

# ── S10 — CIAC-3. This card must not weaken the two guards carrying ADR-002 Decision 4's
# fail-closed zero-plaintext-leak invariant. Read from the parsed bodies for the same
# reason as S9b. STATED BOUND: this is the coupling test, not a byte-identity test —
# byte-identity against origin/main cannot be asserted here because the CI checkout is
# shallow and a git-based arm would SKIP, which under GUARD_STRICT_SKIPS turns the job red
# for an undeclared group. Byte-identity is verified at review against origin/main; what
# this arm holds is that no part of the gate has reached inside either guard.
S_BODY_VPC="$(declare -f verify_publishable_content)"
S_BODY_VC="$(declare -f verify_ciphertext)"
S_LEAK=0
for s_tok in require_change_confirmation change_confirmation_state itinerary_digest \
             strip_to_itinerary_text record_published_itinerary published_itinerary_path; do
  case "$S_BODY_VPC" in *"$s_tok"*) S_LEAK=$((S_LEAK+1)) ;; esac
  case "$S_BODY_VC"  in *"$s_tok"*) S_LEAK=$((S_LEAK+1)) ;; esac
done
S_SENS=0
for s_tok in require_change_confirmation record_published_itinerary; do
  case "$S_BODY_UPD" in *"$s_tok"*) S_SENS=$((S_SENS+1)) ;; esac
done
S_SPEC=0
for s_body in "$S_BODY_VPC" "$S_BODY_VC" "$S_BODY_UPD" "$S_BODY_PUB"; do
  case "$s_body" in *zzz_not_a_real_identifier*) S_SPEC=$((S_SPEC+1)) ;; esac
done
if [ "${#S_BODY_VPC}" -gt 0 ] && [ "${#S_BODY_VC}" -gt 0 ] && [ "$S_SENS" -eq 2 ] && [ "$S_SPEC" -eq 0 ] && [ "$S_LEAK" -eq 0 ]; then
  PASS "S10: 0 of 12 (6 identifiers x 2 guards) gate identifiers appear inside verify_publishable_content (${#S_BODY_VPC}B) or verify_ciphertext (${#S_BODY_VC}B); the sensitivity arm found both identifiers in cmd_update (2/2) and the specificity arm found a fabricated one in 0 of 4 bodies — the zero is a measurement"
else
  FAIL "S10: leak=$S_LEAK sensitivity=$S_SENS specificity=$S_SPEC vpc=${#S_BODY_VPC}B vc=${#S_BODY_VC}B — either the gate has reached inside an ADR-002 D4 guard, or this probe cannot see one"
fi

# ── Group S, second remediation (#552, operator decision D10) — ONE limb ─────
#
# S0–S10 grade the GATE. S11 grades the PROJECTION the gate's verdict is computed from.
# Stage 7 found strip_to_itinerary_text carrying a second limb:
#
#     perl -0777 -pe '…excise the band; drop script/style bodies; drop tags…' "$1" \
#       2>/dev/null || sed -E 's/<[^>]*>/ /g' "$1"
#
# The two limbs do not compute the same thing. The perl limb excises the coordination
# band AND deletes <script>/<style> bodies; the sed limb only turns tags into spaces, so
# the band's label and its date, the CSS rule and the script body all survive into the
# projection. Feed that second projection to itinerary_digest and a marker-only republish
# — the exact act D6 exists to permit — digests differently from the recorded baseline,
# resolves `unconfirmed`, and ABORTS. D6 reinstated, conditionally and silently, with the
# gate's own message telling the organizer the itinerary changed when it did not.
#
# THREE THINGS MADE THE SUBSTITUTION SILENT, and the arms below grade all three:
#   * `2>/dev/null` discarded perl's stderr, so the switch announced nothing;
#   * `preflight` probed `gh` and `npx` and NOT `perl`, so nothing failed early;
#   * `||` reads a NON-ZERO STATUS, so the switch is invisible in the exit code too —
#     the sed limb succeeds and the function returns 0 carrying the wrong answer.
#
# WHY THE LIMB IS REMOVED RATHER THAN TAUGHT TO EXCISE THE BAND. A fallback is honest
# only where the fallback can compute the same answer. strip_to_text's can — its perl
# program is a tag-stripper and little else — which is why that function legitimately
# keeps one and is byte-frozen by #550 AC 5. This projection's cannot: it slurps the whole
# file (-0777), back-references the band's own tag name, and BOUNDS the excision with a
# lazy quantifier. POSIX sed expresses none of the three, and the bound is the single
# property that keeps the excision from running past the band into plan content. A sed
# limb that approximated it would put the one FAIL-OPEN direction this design forbids back
# on the table — an over-running excision deletes plan text, the digest then reads
# "unchanged", and an unapproved change ships behind a marker. So the limb goes and perl
# becomes an asserted dependency instead of an assumed one. That is the shape
# strip_to_published_text already has: a perl program with no sed equivalent, and no
# fallback offered.
#
#   S11a  DENOMINATOR — with a working perl the marked render digests EQUAL to the
#         unmarked one and the token is non-empty: the band really is excised, so the
#         comparisons below have something to compare
#   S11b  THE REGRESSION — with perl failing, NO second projection reaches the gate
#   S11c  VISIBILITY — perl's stderr is no longer discarded; control: a working perl
#         writes 0 bytes there, so the non-zero is the failure surfacing, not chatter
#   S11d  SPECIFICITY for S11b — a render whose visible text is GENUINELY empty still
#         yields a well-formed token, so S11b's empty answer is the failure signal and
#         not "empty input yields nothing"
#   S11e  the perl stub was withdrawn — the arms after it grade production code
#   S11f  STRUCTURAL — the parsed projection body carries no second limb at all;
#         sensitivity: the same detector finds one in strip_to_text, which keeps one
#   S11g  PREFLIGHT — perl's absence is an EARLY, NAMED failure on the publish paths
#         rather than a projection that quietly answers differently mid-run
#   S11h  THE SAME PROBE WITHOUT preflight (#749) — the assertion is reachable as
#         require_perl by a command that needs neither gh nor npx. No stubs are set for
#         it, and that absence IS the evidence
#   S11i  REACHABILITY AT THE SOURCE, AND THE ORDER (#749) — cmd_confirm calls it, and
#         calls it BEFORE it resolves the gate state, so a perl-less host meets a failure
#         that names perl
#
# Offline: $WORK fixtures, a shell-function stub for perl and for gh/npx (the S8/S9
# technique), and a PATH with no perl on it. No network, no Node, no TTY, no real gh. This
# group has no legitimate skip and is deliberately NOT declared in GUARD_EXPECTED_SKIPS.
echo
echo "The itinerary projection has one limb (#552 D10, second remediation):"

S11_MARK="$WORK/s11_mark.html";   s_render "$S11_MARK"  "14:00" pending
S11_PLAIN="$WORK/s11_plain.html"; s_render "$S11_PLAIN" "14:00" none
# A render carrying markup, a style rule and a script body but NO visible text. Its
# projection is legitimately empty, and its digest is therefore a legitimate token —
# S11d's whole point.
S11_VOID="$WORK/s11_void.html"
printf '%s' '<!DOCTYPE html><html><head><style>.hero{color:#333}</style></head><body><script>var mapReady=1;</script></body></html>' > "$S11_VOID"

S11_ERR_OK="$WORK/s11_stderr_ok.txt"
S11_ERR_FAIL="$WORK/s11_stderr_fail.txt"

# ── S11a — THE DENOMINATOR.
S11_PERL="$(itinerary_digest "$S11_MARK" 2>"$S11_ERR_OK")"
S11_BARE="$(itinerary_digest "$S11_PLAIN")"
S11_VOIDDG="$(itinerary_digest "$S11_VOID")"
S11_ERRLEN_OK="$(wc -c < "$S11_ERR_OK" | tr -d ' ')"
if [ -n "$S11_PERL" ] && [ "$S11_PERL" = "$S11_BARE" ]; then
  PASS "S11a: DENOMINATOR — the perl limb reads the marked render as $S11_PERL, the SAME token the unmarked render yields, and it is non-empty; the band is excised rather than the projection being empty, so the arms below compare real values"
else
  FAIL "S11a: the marked render digested '$S11_PERL' and the unmarked one '$S11_BARE' — the projection is empty, or the band is not being excised, and every S11 verdict below would be vacuous"
fi

# ── S11b — THE REGRESSION. perl is stubbed to fail the way a missing or too-old perl
# fails: non-zero, nothing on stdout. The question is what the gate is then handed. Before
# this remediation it was handed the sed limb's output — a well-formed token computed from
# a DIFFERENT projection, one that still carries the band, the CSS rule and the script
# body. A marker-only republish then reads as an itinerary change and aborts, which is
# exactly the deadlock D6 resolved. The fix is not a better fallback: it is that there is
# no second answer to hand over.
perl() { printf 'perl: simulated failure (S11 stub)\n' >&2; return 127; }
S11_FALLBACK="$(itinerary_digest "$S11_MARK" 2>"$S11_ERR_FAIL")"
unset -f perl
S11_ERRLEN_FAIL="$(wc -c < "$S11_ERR_FAIL" | tr -d ' ')"
if [ -n "$S11_PERL" ] && [ -z "$S11_FALLBACK" ]; then
  PASS "S11b: with perl failing, itinerary_digest yields NO token (the working limb yields $S11_PERL) — there is no second projection for the gate to act on, so a coordination-marker republish can never be re-read as an itinerary change by a machine whose perl is missing"
else
  FAIL "S11b: a failed perl still produced the token '$S11_FALLBACK' against the perl limb's '$S11_PERL' — a SECOND projection is reaching the gate. It does not excise the coordination band, so a marker-only republish digests as a plan change, resolves unconfirmed and ABORTS: operator decision D6 is silently reinstated on every machine without a working perl"
fi

# ── S11c — VISIBILITY. The status is only half of it: a projection that fails must also
# SAY so. `2>/dev/null` was there to silence perl before falling back, and once there is
# nothing to fall back to it silences the one message that explains the failure. The
# control is the same call with a working perl, which must write nothing.
if [ "$S11_ERRLEN_OK" -eq 0 ] && [ "$S11_ERRLEN_FAIL" -gt 0 ]; then
  PASS "S11c: a failing perl wrote ${S11_ERRLEN_FAIL}B to stderr while a working one wrote ${S11_ERRLEN_OK}B — the projection no longer discards its own diagnostic, and the non-zero is the failure surfacing rather than ordinary chatter"
else
  FAIL "S11c: working-perl stderr=${S11_ERRLEN_OK}B, failing-perl stderr=${S11_ERRLEN_FAIL}B — the projection is still swallowing perl's stderr (or is writing on the happy path, which would make this probe meaningless). A failure that announces nothing is the property that made this defect silent"
fi

# ── S11d — SPECIFICITY for S11b. S11b's verdict is an EMPTY answer, and an empty answer
# is worthless unless emptiness means one specific thing. It must mean "the projection
# FAILED", not "the projection was empty": a render with markup, a style rule and a script
# body but no visible text projects to nothing legitimately, and that is a real itinerary
# identity a trip may hold. The discriminator is the exit STATUS, not the byte count.
if [ -n "$S11_VOIDDG" ] && [ "$S11_VOIDDG" != "$S11_PERL" ]; then
  PASS "S11d: a render whose visible text is genuinely empty still yields the well-formed token $S11_VOIDDG, distinct from $S11_PERL — so S11b's empty answer discriminates a FAILED projection from an empty one, and the failure is read off the status rather than off the output"
else
  FAIL "S11d: the empty-visible-text render digested '$S11_VOIDDG' against the marked render's '$S11_PERL' — an empty projection and a failed projection are indistinguishable here, so S11b's zero proves nothing"
fi

# ── S11e — THE RESTORE. S6c's rule applied to this stub: an injection that outlives its
# arm turns every later verdict into a grade of the stub.
S11_RESTORED="$(itinerary_digest "$S11_MARK")"
if [ "$S11_RESTORED" = "$S11_PERL" ]; then
  PASS "S11e: the perl stub was withdrawn and the projection reads $S11_RESTORED again — group T and everything after it grade production code"
else
  FAIL "S11e: after the restore the projection reads '$S11_RESTORED' rather than '$S11_PERL' — the stub survived its arm and every verdict below is grading it"
fi

# ── S11f — STRUCTURAL, and the arm that outlives this particular fallback. S11b measures
# the sed limb specifically; this one asserts the CONTRACT — the projection is a single
# limb — so a future `|| awk …`, `|| python3 …` or `|| true` is caught by the same arm
# rather than needing its own. Read from the PARSED body, so a mention inside a comment
# cannot fake it. Its sensitivity arm is strip_to_text, which legitimately keeps a
# fallback and is byte-frozen by #550 AC 5: the detector demonstrably fires on the shape
# it is looking for, so the zero on this projection is a measurement.
S11_BODY_ITIN="$(declare -f strip_to_itinerary_text)"
S11_BODY_TEXT="$(declare -f strip_to_text)"
case "$S11_BODY_ITIN" in *'||'*) S11_ITIN_LIMB=1 ;; *) S11_ITIN_LIMB=0 ;; esac
case "$S11_BODY_TEXT" in *'||'*) S11_TEXT_LIMB=1 ;; *) S11_TEXT_LIMB=0 ;; esac
case "$S11_BODY_ITIN" in *zzz_not_a_real_identifier*) S11_ITIN_SPEC=1 ;; *) S11_ITIN_SPEC=0 ;; esac
if [ "${#S11_BODY_ITIN}" -gt 0 ] && [ "${#S11_BODY_TEXT}" -gt 0 ] \
   && [ "$S11_ITIN_LIMB" -eq 0 ] && [ "$S11_TEXT_LIMB" -eq 1 ] && [ "$S11_ITIN_SPEC" -eq 0 ]; then
  PASS "S11f: the parsed body of strip_to_itinerary_text (${#S11_BODY_ITIN}B) carries 0 fallback limbs; the sensitivity arm found 1 in strip_to_text (${#S11_BODY_TEXT}B), which legitimately keeps one, and the specificity arm found a fabricated token in 0 of them — the zero is a measurement, and any future second limb of any kind fails here"
else
  FAIL "S11f: itinerary-limb=$S11_ITIN_LIMB text-limb=$S11_TEXT_LIMB specificity=$S11_ITIN_SPEC itin=${#S11_BODY_ITIN}B text=${#S11_BODY_TEXT}B — the itinerary projection carries a second limb (or the detector cannot see the one strip_to_text carries, in which case its zero proves nothing)"
fi

# ── S11g — PREFLIGHT. S11b/S11c make the failure safe and audible; this one makes it
# EARLY. cmd_update runs preflight before it resolves the render, so a probe here means
# the operator is told "install perl" before anything is cloned, encrypted or pushed,
# instead of meeting the gate's own message claiming an itinerary change that never
# happened. gh and npx are function-stubbed (the S8/S9 technique) so the ONLY thing the
# stripped PATH removes is perl, and the control run — same stubs, real PATH — shows
# preflight still passes when perl is there.
gh() { case "${1:-} ${2:-}" in "auth status") printf "Token scopes: 'repo'\n" ;; *) return 0 ;; esac; }
npx() { return 0; }
# shellcheck disable=SC2123  # PATH is cleared on purpose, inside a subshell, so that perl cannot be found
S11_MSG_NOPERL="$( ( PATH=/nonexistent/s11-no-perl; preflight ) 2>&1 >/dev/null )"; S11_RC_NOPERL=$?
# shellcheck disable=SC2034  # the control is shaped like the subject above it; only its status is graded
S11_MSG_PERL="$( ( preflight ) 2>&1 >/dev/null )";                                  S11_RC_PERL=$?
unset -f gh npx
case "$S11_MSG_NOPERL" in *perl*) S11_NAMES_PERL=1 ;; *) S11_NAMES_PERL=0 ;; esac
if [ "$S11_RC_PERL" -eq 0 ] && [ "$S11_RC_NOPERL" -ne 0 ] && [ "$S11_NAMES_PERL" -eq 1 ]; then
  PASS "S11g: preflight passes with perl present (rc=$S11_RC_PERL, the control, so the stubs are not refusing everything) and ABORTS naming perl when it is absent (rc=$S11_RC_NOPERL) — the dependency fails early and by name, before any clone, encryption or push"
else
  FAIL "S11g: control rc=$S11_RC_PERL, stripped-PATH rc=$S11_RC_NOPERL, message names perl=$S11_NAMES_PERL (message: ${S11_MSG_NOPERL:-none}) — preflight does not probe perl, so its absence is discovered mid-run as a projection that answers differently rather than up front as a missing dependency"
fi

# ── S11h — THE SAME PROBE, REACHABLE WITHOUT preflight (#749). S11g grades the probe where
# it has always sat, INSIDE preflight — and preflight is the wrong caller for a local
# command, because it also demands npx and an authenticated gh. cmd_confirm needs neither:
# it reads a file, prompts a terminal and writes a sidecar. Calling preflight from it would
# break a working command on every host without Node or a logged-in gh. So the one
# assertion cmd_confirm does need is extracted into require_perl — one message, one
# definition, two callers — and graded here on its own.
#
# NO gh OR npx STUB IS SET FOR THIS ARM, and that absence is not an oversight: it is the
# evidence. require_perl uses only `command -v`, `printf` and `exit`, all builtins, so it
# reaches both verdicts under a PATH carrying nothing at all. A helper that needed a stub
# here would be a helper that had handed cmd_confirm a network dependency.
S11H_MSG_OK="$( ( require_perl ) 2>&1 >/dev/null )";                              S11H_RC_OK=$?
# shellcheck disable=SC2123  # PATH is cleared on purpose, inside a subshell, so that perl cannot be found
S11H_MSG="$( ( PATH=/nonexistent/s11h-no-perl; require_perl ) 2>&1 >/dev/null )"; S11H_RC=$?
case "$S11H_MSG" in *perl*) S11H_NAMES=1 ;; *) S11H_NAMES=0 ;; esac
if [ "$S11H_RC_OK" -eq 0 ] && [ "$S11H_RC" -ne 0 ] && [ "$S11H_NAMES" -eq 1 ]; then
  PASS "S11h: require_perl passes with perl present (rc=$S11H_RC_OK — the control, so the helper is not refusing everything) and ABORTS naming perl under a stripped PATH (rc=$S11H_RC), with NO gh or npx stub in scope. The dependency cmd_confirm actually has is assertable on its own, without dragging in the two external services it does not use"
else
  FAIL "S11h: control rc=$S11H_RC_OK (message: ${S11H_MSG_OK:-none}), stripped-PATH rc=$S11H_RC, message names perl=$S11H_NAMES (message: ${S11H_MSG:-none}) — either require_perl does not exist, or it does not die by name without perl, or it needs something the stripped PATH removed. A control rc of 127 with a 'command not found' message is the first case, and note that such a message contains the substring 'perl' too, which is why the CONTROL rather than the name is what convicts it"
fi

# ── S11i — REACHABILITY AT THE SOURCE, AND THE ORDER (#749). S11h proves the helper
# aborts; this proves cmd_confirm reaches it, and reaches it EARLY ENOUGH. The order is the
# substance, not a detail: placing the call merely "before the prompt" would name the
# SYMPTOM rather than the CAUSE. change_confirmation_state runs one step earlier, and on a
# perl-less host its itinerary_digest call returns EMPTY; since #1184 the resolver reads
# that as `undetermined` and cmd_confirm refuses it before the terminal check and the
# prompt. That is safe, but the refusal says the itinerary's state could not be
# determined, when what is wrong is that perl is missing. (Before #1184 the same path fell
# through to `unconfirmed` or `stale`, showed the organizer `Gate state      : stale` for a
# plan that may not have moved, and asked for a CONFIRM against that fabricated state —
# which is why #749 moved the probe.) The probe therefore belongs before the state
# resolution, so that the failure names perl.
#
# Read from the PARSED bodies, so a mention inside a comment cannot fake any of it. The
# sensitivity arm is preflight, which calls the same helper, so the detector demonstrably
# fires; the specificity arm is cmd_rotate, which must not.
S11I_CONF="$(declare -f cmd_confirm)"
S11I_PRE="$(declare -f preflight)"
S11I_ROT="$(declare -f cmd_rotate)"
case "$S11I_CONF" in *require_perl*)              S11I_CALLS=1 ;; *) S11I_CALLS=0 ;; esac
case "$S11I_CONF" in *change_confirmation_state*) S11I_STATE=1 ;; *) S11I_STATE=0 ;; esac
case "$S11I_PRE"  in *require_perl*)              S11I_SENS=1  ;; *) S11I_SENS=0  ;; esac
case "$S11I_ROT"  in *require_perl*)              S11I_SPEC=1  ;; *) S11I_SPEC=0  ;; esac
S11I_AT_CALL="${S11I_CONF%%require_perl*}"
S11I_AT_STATE="${S11I_CONF%%change_confirmation_state*}"
if [ "$S11I_CALLS" -ne 1 ]; then
  FAIL "S11i: cmd_confirm's parsed body (${#S11I_CONF}B) DOES NOT CALL require_perl at all. On a host without perl it runs change_confirmation_state first, is handed an empty digest and resolves 'undetermined', so the organizer is refused on the SYMPTOM — the state could not be determined — and is never told that perl is missing"
elif [ "$S11I_STATE" -ne 1 ]; then
  FAIL "S11i: cmd_confirm's parsed body carries no change_confirmation_state call, so the ordering comparison below has no right-hand side — the resolver was renamed or the gate was restructured, and this arm is no longer reading what it claims"
elif [ "$S11I_SENS" -ne 1 ] || [ "$S11I_SPEC" -ne 0 ]; then
  FAIL "S11i: the detector's own arms did not fire — sensitivity (require_perl in preflight, ${#S11I_PRE}B) = $S11I_SENS, specificity (require_perl in cmd_rotate, ${#S11I_ROT}B) = $S11I_SPEC. Until both fire, a hit in cmd_confirm proves nothing about what this scan can see"
elif [ "${#S11I_AT_CALL}" -lt "${#S11I_AT_STATE}" ]; then
  PASS "S11i: cmd_confirm calls require_perl at byte ${#S11I_AT_CALL} of its parsed body and change_confirmation_state at byte ${#S11I_AT_STATE} — the dependency is asserted BEFORE the gate state is resolved, so a perl-less host meets a failure that names perl instead of an 'undetermined' refusal that names only the symptom. Sensitivity: the same scan finds the call in preflight; specificity: it finds none in cmd_rotate"
else
  FAIL "S11i: cmd_confirm CALLS require_perl TOO LATE — at byte ${#S11I_AT_CALL} of its parsed body, after change_confirmation_state at byte ${#S11I_AT_STATE}. The state is then resolved from an empty digest before the probe is ever reached: it reads 'undetermined', so a perl-less host is refused on the symptom rather than told that perl is missing"
fi

# ── Group S, third remediation (#552, SEAM-2) — C19's DECLARATION BLOCK ──────
#
# S0–S10 grade the GATE. S11 grades the PROJECTION's single limb. S12 grades what that
# projection does with the one construct EVERY conformant render carries and no fixture
# in this suite had ever built.
#
# THE DEFECT. The projection's last limb is `s/<[^>]+>/ /g`, and it stops at the first
# `>`. It therefore cannot collapse an HTML comment whose body contains one. C19's
# declaration rides an `<!-- … -->` block (reference/data-architecture.md § 4.5), and its
# `artifact:` field — `required`, per its own schema fence — carries a `>` inside
# `outputs/<destination>-travel-site.html`. scripts/validate-artifacts.sh finding A5 holds
# that value equal to the selecting class's own declared string, so the `>` is not an edge
# case a render may happen to avoid: it is mandatory on every CONFORMANT render, and the
# normal path is the broken one.
#
# WHAT IT COSTS, and why it is a defect rather than a preference. The block's body then
# sits inside the itinerary digest. `generated:` sits inside the block. `generated:`
# changes every day. So a next-day republish carrying ZERO itinerary change digests
# differently, the gate reads "content changed", and it demands an organizer confirmation
# for a routine rebuild. Operator decision D6 keys this gate on itinerary-CONTENT change
# precisely so it is not keyed on publish-as-such — and a build timestamp inside "content"
# collapses the first back toward the second. It fails CLOSED, so it is a usability and
# semantic defect and not a leak; that is why it is repaired rather than escalated.
#
# THE BOUNDARY THIS RESTORES IS THE ONE THE SCRIPT ALREADY DECLARED. publish-trip-site.sh
# states in terms, above strip_to_itinerary_text: "WHAT IS OUTSIDE THE BOUNDARY, stated
# rather than implied: markup, HTML COMMENT BODIES, attribute values, <script> and <style>
# bodies." The comment body was inside the digest anyway. This is conformance to a stated
# boundary, not a new policy.
#
# WHY NOTHING CAUGHT IT. Every fixture that reaches this projection — s_render above,
# t_page and t_page_pre in group T — builds no frontmatter at all, so the construct was
# never in front of the projection. T7 built the first conformant render and MEASURED the
# residual (T7c), correctly declining to repair a projection owned by another card. S12 is
# that repair's grade, and T7c is re-scoped to the invariance in the same commit.
#
#   S12a  the whole state transition — band AND frontmatter — leaves the digest fixed
#   S12b  `generated:` drift alone moves nothing         (the next-day republish)
#   S12c  CONTROL — a real itinerary change still moves it
#   S12d  the projection DIFFERS from strip_to_text on comment-bearing input and still
#         AGREES on comment-free input                   (T4's identity, scoped)
#
# S12c IS WHAT MAKES a AND b MEASUREMENTS. A projection that dropped everything it was
# given would satisfy both perfectly. Without an arm showing the same projection still
# moves on a real plan edit, the two invariances prove nothing.
#
# THE FIXTURE'S `>` IS THE CORPUS'S, NOT THIS FILE'S. The artifact string is READ FROM
# C19's schema fence below rather than spelled here — the same discipline T1 applies to
# the class token. A fixture that spelled it would stay green through a corpus that had
# moved the placeholder, which is the one change that would make these arms vacuous, and
# S12a's first guard fails loudly on exactly that.
S12_SCHEMA="$HERE/../reference/schemas/travel-site.md"
S12_ART="$(awk -F': ' '/^artifact: / { print $2; exit }' "$S12_SCHEMA" 2>/dev/null)"

# A CONFORMANT C19 render: the declaration block, then the site. Parameterised on the two
# frontmatter coordination fields, the band, the plan text and `generated:`, so each arm
# below varies exactly one thing and holds the rest fixed.
s12_page() { # <file> <fm-state> <fm-since> <band-state> <plan-time> <generated>
  local f="$1" fs="$2" fc="$3" bs="$4" tm="$5" gen="$6" band="" rule="" since=""
  [ -z "$fc" ] || since="coordination-since: ${fc}
"
  if [ "$bs" != "none" ]; then
    band="<div class=\"coord-notice is-${bs}\"><span>A change is ${bs}</span> <time>2027-06-02</time></div>
"
    rule=".coord-notice{background:#eee}"
  fi
  cat > "$f" <<HTML
<!--
artifact: ${S12_ART}
schema-version: 1
trip: porto-2027
writer: site
lifecycle: output
provenance: derived
publish: output
generated: ${gen}
coordination-state: ${fs}
${since}-->
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>${rule}.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
${band}<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at ${tm}. Then the riverside walk to the bridge.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
}

# The three states as a real transition moves them: the band and the frontmatter TOGETHER.
# T7a holds the frontmatter fixed and varies only the band; T7c holds the band fixed and
# varies only the frontmatter. Neither is the transition a trip actually undergoes.
s12_page "$WORK/s12_st_none.html"    none    ""           none    16:30 2027-06-02
s12_page "$WORK/s12_st_pending.html" pending 2027-05-30   pending 16:30 2027-06-02
s12_page "$WORK/s12_st_updated.html" updated 2027-06-01   updated 16:30 2027-06-02
# The same pending render, rebuilt the next day. NOTHING else moves.
s12_page "$WORK/s12_gen_day2.html"   pending 2027-05-30   pending 16:30 2027-06-03
# The same pending render with one scheduled time moved — the control.
s12_page "$WORK/s12_plan_moved.html" pending 2027-05-30   pending 21:00 2027-06-02
S12_DN="$(itinerary_digest "$WORK/s12_st_none.html")"
S12_DP="$(itinerary_digest "$WORK/s12_st_pending.html")"
S12_DU="$(itinerary_digest "$WORK/s12_st_updated.html")"
S12_G2="$(itinerary_digest "$WORK/s12_gen_day2.html")"
S12_PM="$(itinerary_digest "$WORK/s12_plan_moved.html")"

# ── S12a — THE SUBJECT. On a conformant render the coordination state transition is
# outside the itinerary digest — the band AND the declaration block's two coordination
# fields move together and the token does not move at all.
if [ -z "$S12_ART" ] || [ "${S12_ART#*>}" = "$S12_ART" ]; then
  FAIL "S12a: the artifact string read from $(basename "$S12_SCHEMA") is '${S12_ART:-<empty>}' and carries no '>' — the fixture below then builds a comment the old tag-strip collapses anyway, this group stops exercising the defect it exists for, and every equality in it would be vacuous. C19's placeholder has moved, or the fence has"
elif [ -z "$S12_DN" ]; then
  FAIL "S12a: itinerary_digest returned nothing for the conformant render — the projection is not readable here and no equality below would mean anything"
elif [ "$S12_DN" = "$S12_DP" ] && [ "$S12_DN" = "$S12_DU" ]; then
  PASS "S12a: on a render carrying C19's declaration block the WHOLE coordination transition is outside the itinerary digest — none, pending and updated all read $S12_DN with the band and the frontmatter's two coordination fields moving together. S12c shows the same projection still moves on a plan edit ($S12_DP -> $S12_PM), so this is a measurement and not a projection that drops everything"
else
  FAIL "S12a: the coordination state is INSIDE the itinerary digest on a conformant render — none=$S12_DN pending=$S12_DP updated=$S12_DU. \`s/<[^>]+>/ /g\` stops at the '>' inside '$S12_ART', so the declaration block survives into the projection and every state transition reads to the gate as an itinerary change. Operator decision D6's deadlock is reinstated on the normal path"
fi

# ── S12b — THE NEXT-DAY REPUBLISH. `generated:` is a required field carrying the build
# date, so it changes on every rebuild. If it is inside the digest, the gate demands a
# confirmation for a republish that changed no itinerary content at all — which is the
# gate keying on publish-as-such by the back door.
if cmp -s "$WORK/s12_st_pending.html" "$WORK/s12_gen_day2.html"; then
  FAIL "S12b: the two renders are byte-identical, so the equality below compares a file with itself — the fixture is not varying \`generated:\` and this arm measures nothing"
elif [ -z "$S12_G2" ]; then
  FAIL "S12b: itinerary_digest returned nothing for the next-day render — no equality here would mean anything"
elif [ "$S12_DP" = "$S12_G2" ]; then
  PASS "S12b: rebuilding the same site the next day moves \`generated:\` 2027-06-02 -> 2027-06-03 and the itinerary digest not at all ($S12_G2) — the two renders DO differ in bytes, so the equality is over a real change that the projection correctly declines to see. A routine rebuild no longer asks the organizer to confirm an itinerary change that did not happen"
else
  FAIL "S12b: a one-day \`generated:\` drift moved the digest $S12_DP -> $S12_G2 with no itinerary change whatsoever. Every next-day republish aborts at the gate, and the build timestamp is being treated as itinerary content"
fi

# ── S12c — THE CONTROL. Depends on no defect and holds in both directions: it is what
# makes S12a and S12b measurements rather than the signature of a projection that
# discriminates nothing.
if [ -n "$S12_PM" ] && [ "$S12_PM" != "$S12_DP" ]; then
  PASS "S12c: CONTROL — moving one scheduled time (16:30 -> 21:00) under the SAME conformant fixture moves the digest ($S12_DP -> $S12_PM), so the invariances above are properties of the excision and not of a projection that drops its input"
else
  FAIL "S12c: a plan edit under the conformant fixture left the digest at '$S12_PM' against '$S12_DP' — the projection cannot see an itinerary change on a render carrying a declaration block, so S12a and S12b prove nothing and the gate would wave an unapproved plan change through"
fi

# ── S12d — WHERE THE TWO PROJECTIONS MUST NOW DIVERGE, AND WHERE THEY MUST NOT.
# T4 asserts strip_to_itinerary_text byte-identical to strip_to_text on the null case.
# That identity is still intended — on input carrying no HTML comment, which is what
# T4's fixtures build. It is NOT intended here: this projection must excise the comment
# construct and strip_to_text (byte-frozen, on verify_ciphertext's path) must not. So the
# divergence is asserted in the same arm as the identity, and the arm carries both — an
# inequality alone would be satisfied by any change at all, and the equality alone is
# what T4 already holds.
#
# The subject render carries a declaration block and NO band, so the band limb cannot
# fire and the comment excision is the only thing the two projections can disagree about.
S12_FREE="$WORK/s12_comment_free.html"
cat > "$S12_FREE" <<'HTML'
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at 16:30. Then the riverside walk to the bridge.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
strip_to_itinerary_text "$WORK/s12_st_none.html" > "$WORK/s12_itin_bearing.txt"
strip_to_text           "$WORK/s12_st_none.html" > "$WORK/s12_text_bearing.txt"
strip_to_itinerary_text "$S12_FREE"              > "$WORK/s12_itin_free.txt"
strip_to_text           "$S12_FREE"              > "$WORK/s12_text_free.txt"
# `provenance` is a C19 field name and appears in this fixture ONLY inside the block, so
# its presence in one projection and absence from the other names WHAT the difference is.
# Read with `case` rather than grep: group PF's rule, and no pipeline to be decided by.
S12_TOK_IN_TEXT=0; S12_TOK_IN_ITIN=0
case "$(cat "$WORK/s12_text_bearing.txt")" in *provenance*) S12_TOK_IN_TEXT=1 ;; esac
case "$(cat "$WORK/s12_itin_bearing.txt")" in *provenance*) S12_TOK_IN_ITIN=1 ;; esac
if [ ! -s "$WORK/s12_text_bearing.txt" ] || [ ! -s "$WORK/s12_text_free.txt" ]; then
  FAIL "S12d: strip_to_text produced nothing for one of the two fixtures, so the comparisons below would be between empty files"
elif [ "$S12_TOK_IN_TEXT" -ne 1 ]; then
  FAIL "S12d: the token 'provenance' is not in strip_to_text's output for the comment-bearing render — the fixture is not carrying a declaration block, or the detector cannot see one, and its absence from the itinerary projection would prove nothing"
elif ! cmp -s "$WORK/s12_itin_free.txt" "$WORK/s12_text_free.txt"; then
  FAIL "S12d: the two projections disagree on a COMMENT-FREE render ($(wc -c < "$WORK/s12_itin_free.txt" | tr -d ' ')B vs $(wc -c < "$WORK/s12_text_free.txt" | tr -d ' ')B) — the excision is firing where there is nothing to excise, and T4's identity is broken with it"
elif cmp -s "$WORK/s12_itin_bearing.txt" "$WORK/s12_text_bearing.txt"; then
  FAIL "S12d: the two projections are byte-identical on a COMMENT-BEARING render, and 'provenance' is in both — strip_to_itinerary_text is not excising C19's declaration block, so its body is in the digest and S12a/S12b's invariances cannot hold"
elif [ "$S12_TOK_IN_ITIN" -ne 0 ]; then
  FAIL "S12d: the projections differ on the comment-bearing render but 'provenance' survives into the itinerary projection — the difference is something other than the declaration block, and the block is still in the digest"
else
  PASS "S12d: the two projections AGREE on a comment-free render ($(wc -c < "$WORK/s12_itin_free.txt" | tr -d ' ')B, T4's identity, still intended and still held) and DIFFER on a comment-bearing one ($(wc -c < "$WORK/s12_itin_bearing.txt" | tr -d ' ')B vs $(wc -c < "$WORK/s12_text_bearing.txt" | tr -d ' ')B). The difference is named rather than assumed: 'provenance' is present in strip_to_text's output and absent from the itinerary projection's, so what was removed is the declaration block. strip_to_text is untouched — CIAC-3 keeps it on verify_ciphertext's path byte-for-byte"
fi


# ═════════════════════════════════════════════════════════════════════════════════
# Group S13 (#552, AI-012) — THE FAIL-OPEN, AND THE ONLY RESIDUAL ON THIS RELEASE
# THAT DOES NOT FAIL CLOSED.
#
# S12's excision reads `s/<!--.*?-->/ /gs` — a regex over raw text with no notion of
# HTML structure. It therefore treats `<!--` as a comment opener WHEREVER it appears,
# including inside a QUOTED ATTRIBUTE VALUE, where HTML5 says it is character data and
# not a comment at all. The lazy match then runs from that attribute to the next
# genuine `-->` and deletes EVERYTHING BETWEEN — markup and reader-visible plan text
# alike.
#
# THE DIRECTION IS WHAT SEPARATES THIS FROM EVERY OTHER RESIDUAL IN THIS FILE. The
# band's cap, an unterminated comment, a failed projection, a malformed record: each
# of those leaves MORE in the digest, so the gate demands a confirmation it did not
# need and the republish ABORTS — noisy, and safe. This one leaves LESS. A real
# itinerary edit lands inside the swallowed span, the digest does not move, the gate
# reads "content unchanged", and AN UNAPPROVED PLAN CHANGE PUBLISHES behind a
# confirmation the organizer never gave. That is the fail-OPEN direction, and making
# it unreachable is the entire point of ADR-003 § Decision 2.
#
# THE RENDER IS WELL-FORMED — this is the normal path, not a malformed-input edge
# case. An `html.parser` oracle over the subject fixture below sees TWO comments, not
# three: the attribute-borne `<!--` is an attribute value. The arms make that point
# WITHOUT a parser, using strip_to_text — the VISIBLE projection, byte-frozen by #550
# AC 5, carrying no comment limb at all, and therefore the one reference here that
# cannot have been bent to suit this group. What IT keeps is what a reader sees.
#
#   S13a  THE SUBJECT — a real plan edit MUST move the digest on a render whose
#         attribute value carries a `<!--`                          (the fail-open)
#   S13b  THE PREMISE — the span the projection loses is reader-VISIBLE text, read off
#         strip_to_text rather than asserted
#   S13c  CONTROL — the same edit on the same fixture WITHOUT the attribute opener
#         moves the digest, so S13a's equality is caused by the opener and by nothing
#         else the fixture varies
#   S13d  THE BOUNDARY IN BYTES — subject and control digest the SAME, which is what
#         this file's "attribute values are outside the digest" claim means measurably
#   S13e  D12 — `generated:` drift still moves nothing, ON THE HAZARD SHAPE
#   S13f  AI-013 — #551's build-time prune is still digest-neutral. NAMED and asserted
#         rather than assumed: the prune is digest-neutral only because this block
#         leaves the digest, no arm on this release said so, and this is the first
#         change to this function since that coupling was recorded.
#
# S13c AND S13d ARE WHAT MAKE S13a A MEASUREMENT. A projection that dropped its whole
# input would satisfy no equality here: S13c shows the same projection still moves on
# a plan edit, and S13d shows the subject and the control are the same itinerary. Each
# of S13e and S13f carries its OWN discrimination limb for the same reason — a
# pre-fix projection that swallows everything satisfies both invariances perfectly and
# neither would mean anything.
echo "Comment excision — a comment opener inside an attribute value (#552, AI-012):"

# The S12 fixture with one thing added: an attribute value carrying an UNCLOSED `<!--`,
# and a later ordinary comment to supply the `-->` the lazy match runs to. Both are
# ordinary things for a template-built render to carry. `<attr-open>` empty builds the
# control, so subject and control differ in exactly that attribute and nothing else.
s13_page() { # <file> <fm-state> <fm-since> <band-state> <plan-time> <plan-word> <generated> <attr-open>
  local f="$1" fs="$2" fc="$3" bs="$4" tm="$5" wd="$6" gen="$7" ao="$8"
  local band="" rule="" since="" attr=""
  [ -z "$fc" ] || since="coordination-since: ${fc}
"
  [ -z "$ao" ] || attr=" data-tpl=\"${ao}\""
  if [ "$bs" != "none" ]; then
    band="<div class=\"coord-notice is-${bs}\"><span>A change is ${bs}</span> <time>2027-06-02</time></div>
"
    rule=".coord-notice{background:#eee}"
  fi
  cat > "$f" <<HTML
<!--
artifact: ${S12_ART}
schema-version: 1
trip: porto-2027
writer: site
lifecycle: output
provenance: derived
publish: output
generated: ${gen}
coordination-state: ${fs}
${since}-->
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>${rule}.hero{color:#333}</style></head><body>
<section class="hero"${attr}><h1>Porto 2027</h1></section>
${band}<section class="day"><h2>Saturday</h2>
<p>Miradouro at ${tm}. Then ${wd} by the river.</p></section>
<!-- build: ok -->
<script>var mapReady=1;</script>
</body></html>
HTML
}

S13_OPENER='<!-- slot'
s13_page "$WORK/s13_sub_a.html" none    ""         none    16:30 breakfast        2027-06-02 "$S13_OPENER"
s13_page "$WORK/s13_sub_b.html" none    ""         none    21:00 "DINNER instead" 2027-06-02 "$S13_OPENER"
s13_page "$WORK/s13_ctl_a.html" none    ""         none    16:30 breakfast        2027-06-02 ""
s13_page "$WORK/s13_ctl_b.html" none    ""         none    21:00 "DINNER instead" 2027-06-02 ""
s13_page "$WORK/s13_sub_g2.html" none   ""         none    16:30 breakfast        2027-06-03 "$S13_OPENER"
s13_page "$WORK/s13_pr_upd.html" updated 2027-06-01 updated 16:30 breakfast       2027-06-02 "$S13_OPENER"
s13_page "$WORK/s13_pr_non.html" none    ""         none    16:30 breakfast       2027-06-02 "$S13_OPENER"

S13_SA="$(itinerary_digest "$WORK/s13_sub_a.html")"
S13_SB="$(itinerary_digest "$WORK/s13_sub_b.html")"
S13_CA="$(itinerary_digest "$WORK/s13_ctl_a.html")"
S13_CB="$(itinerary_digest "$WORK/s13_ctl_b.html")"
S13_G2="$(itinerary_digest "$WORK/s13_sub_g2.html")"
S13_PU="$(itinerary_digest "$WORK/s13_pr_upd.html")"
S13_PN="$(itinerary_digest "$WORK/s13_pr_non.html")"

# strip_to_text is the reader's-eye reference — frozen, comment-limb-free. Read with
# `case` rather than grep: group PF's rule, and no pipeline to be decided by.
strip_to_text "$WORK/s13_sub_a.html" > "$WORK/s13_vis_a.txt"
strip_to_text "$WORK/s13_sub_b.html" > "$WORK/s13_vis_b.txt"
S13_VIS_A=0; S13_VIS_B=0
case "$(cat "$WORK/s13_vis_a.txt")" in *"Then breakfast by the river"*)      S13_VIS_A=1 ;; esac
case "$(cat "$WORK/s13_vis_b.txt")" in *"Then DINNER instead by the river"*) S13_VIS_B=1 ;; esac

# ── S13b — THE PREMISE, graded before the subject that rests on it. If the edit is not
# reader-visible, S13a is grading a change no traveller could ever see and its verdict
# means nothing either way.
if [ "$S13_VIS_A" -ne 1 ] || [ "$S13_VIS_B" -ne 1 ]; then
  FAIL "S13b: the edited sentence is not in strip_to_text's output for one of the two subject renders (a=$S13_VIS_A b=$S13_VIS_B) — the fixture is not carrying the plan text where a reader would see it, so S13a would grade an invisible change and prove nothing"
elif cmp -s "$WORK/s13_vis_a.txt" "$WORK/s13_vis_b.txt"; then
  FAIL "S13b: strip_to_text is byte-identical across the two subject renders, so the 'edit' changes nothing a reader sees and S13a's equality would be correct rather than a defect"
else
  PASS "S13b: PREMISE — the edit 16:30/breakfast -> 21:00/DINNER instead is READER-VISIBLE. strip_to_text, the byte-frozen visible projection that carries no comment limb, keeps both sentences and differs across the two renders ($(wc -c < "$WORK/s13_vis_a.txt" | tr -d ' ')B vs $(wc -c < "$WORK/s13_vis_b.txt" | tr -d ' ')B). Whatever the itinerary projection does below, the span in question is text a traveller reads"
fi

# ── S13a — THE SUBJECT. The fail-open itself.
if [ -z "$S13_SA" ] || [ -z "$S13_SB" ]; then
  FAIL "S13a: itinerary_digest returned nothing for a subject render (a='$S13_SA' b='$S13_SB') — the projection is not readable here and no comparison below is a measurement"
elif [ "$S13_SA" != "$S13_SB" ]; then
  PASS "S13a: on a render whose attribute value carries a '<!--', a real itinerary edit STILL moves the digest ($S13_SA -> $S13_SB). The comment excision no longer treats an attribute-borne opener as a comment, so the span between it and the next '-->' is no longer deleted, and an unapproved plan change can no longer ride a standing confirmation"
else
  FAIL "S13a: FAIL-OPEN — a genuine itinerary edit (16:30/breakfast -> 21:00/DINNER instead, reader-visible per S13b) digested IDENTICALLY at $S13_SA on both sides. \`s/<!--.*?-->/ /gs\` opened a comment at the '<!--' inside data-tpl and ran to the next '-->', deleting the plan text in between. The gate reads 'content unchanged' and publishes an UNAPPROVED CHANGE behind a confirmation the organizer never gave. Every other residual on this release fails closed; this one does not"
fi

# ── S13c — CONTROL. Without the attribute opener the same edit moves the digest. This
# depends on no defect and must hold in both directions.
if [ -n "$S13_CA" ] && [ -n "$S13_CB" ] && [ "$S13_CA" != "$S13_CB" ]; then
  PASS "S13c: CONTROL — the same edit on the same fixture WITHOUT the attribute-borne opener moves the digest ($S13_CA -> $S13_CB). S13a's verdict is therefore a property of the opener and not of the fixture, the edit or the projection in general"
else
  FAIL "S13c: the control render, which carries no attribute-borne '<!--' at all, digested '$S13_CA' and '$S13_CB' across a real plan edit — the fixture or the projection cannot see an itinerary change even with nothing to swallow it, so S13a grades nothing"
fi

# ── S13d — THE BOUNDARY IN BYTES. This file states that attribute values are OUTSIDE
# the itinerary digest. Subject and control are the same itinerary differing in exactly
# one attribute value, so that claim has a measurement: they must digest the SAME.
if [ -z "$S13_SA" ] || [ -z "$S13_CA" ]; then
  FAIL "S13d: a digest was empty (subject='$S13_SA' control='$S13_CA'), so the equality below would compare nothing"
elif [ "$S13_SA" = "$S13_CA" ] && [ "$S13_SB" = "$S13_CB" ]; then
  PASS "S13d: adding a data-tpl attribute carrying a '<!--' moves the itinerary digest NOT AT ALL — subject and control agree at $S13_SA before the edit and at $S13_SB after it. That is this file's declared boundary ('attribute values' are outside the digest) stated in bytes rather than in prose, and S13c shows the same pair still discriminates a plan change"
else
  FAIL "S13d: an attribute value is INSIDE the itinerary digest — subject/control read $S13_SA/$S13_CA before the edit and $S13_SB/$S13_CB after it. A render that merely carries a '<!--' in an attribute digests differently from the identical itinerary without one, so the boundary this file declares is not the boundary it computes"
fi

# ── S13e — D12, ON THE HAZARD SHAPE. S12b holds this on a clean render; it has to hold
# on this one too, or the repair bought the fail-open back at the cost of the invariance
# it was protecting. Carries its own discrimination limb: pre-repair every digest here
# is the same token and the equality alone would be satisfied by the defect.
if [ "$S13_SA" = "$S13_SB" ]; then
  FAIL "S13e: the projection cannot discriminate a plan edit on this fixture (both $S13_SA), so the \`generated:\` equality below is satisfied by a projection that swallowed its input and is not a measurement of D12"
elif cmp -s "$WORK/s13_sub_a.html" "$WORK/s13_sub_g2.html"; then
  FAIL "S13e: the two renders are byte-identical, so the equality compares a file with itself and the fixture is not varying \`generated:\`"
elif [ "$S13_SA" = "$S13_G2" ]; then
  PASS "S13e: D12 HOLDS ON THE HAZARD SHAPE — rebuilding the same site the next day moves \`generated:\` 2027-06-02 -> 2027-06-03 and the digest not at all ($S13_G2), on a render that also carries the attribute-borne opener. The declaration block still leaves the digest, and it does so while the projection can still see a plan edit ($S13_SA -> $S13_SB)"
else
  FAIL "S13e: a one-day \`generated:\` drift moved the digest $S13_SA -> $S13_G2 on the hazard-shaped render — the declaration block is back inside the digest and every routine rebuild asks the organizer to confirm an itinerary change that did not happen"
fi

# ── S13f — AI-013, THE COUPLING, NAMED. #551's build-time prune rewrites
# `coordination-state: updated` + `coordination-since:` to `none` in the DECLARATION
# BLOCK and stops emitting the band and its CSS rule. The band limb covers the band and
# the style limb covers the rule; the two frontmatter fields are covered by nothing but
# this excision. The prune is therefore digest-neutral ONLY because the block leaves the
# digest — and if it stopped being neutral, every trip whose one change was confirmed
# would deadlock at the gate on the day its seven-day window closes. No arm on this
# release named that dependency. This one does, and asserts it.
if [ "$S13_SA" = "$S13_SB" ]; then
  FAIL "S13f: the projection cannot discriminate a plan edit on this fixture (both $S13_SA), so the prune equality below is satisfied by a projection that swallowed its input and says nothing about AI-013"
elif [ -z "$S13_PU" ] || [ -z "$S13_PN" ]; then
  FAIL "S13f: a digest was empty for the prune pair (updated='$S13_PU' none='$S13_PN'), so no equality here is a measurement"
elif cmp -s "$WORK/s13_pr_upd.html" "$WORK/s13_pr_non.html"; then
  FAIL "S13f: the pre-prune and post-prune renders are byte-identical — the fixture is not performing the prune transition and the equality compares a file with itself"
elif [ "$S13_PU" = "$S13_PN" ]; then
  PASS "S13f: AI-013 HOLDS — #551's build-time prune is still digest-neutral. The whole transition (coordination-state updated -> none, coordination-since dropped, band and CSS rule no longer emitted) leaves the digest at $S13_PN, on a render that also carries the attribute-borne opener, and while the same projection still moves on a plan edit ($S13_SA -> $S13_SB). The coupling recorded against this function survives its first change"
else
  FAIL "S13f: AI-013 IS BROKEN — the prune moved the digest $S13_PU -> $S13_PN. #551's prune fires the day a trip's seven-day window closes, so every trip that has ever had a confirmed change would find its next republish reading as an itinerary change and DEADLOCK at the gate on day 8. The declaration block's coordination fields are back inside the digest"
fi

# ── Group S14 (#749) — THE OTHER PROJECTION'S SECOND LIMB ────────────────────
#
# S11 removed the fallback from strip_to_itinerary_text and stated, in its own preamble,
# the criterion that decided it: A FALLBACK IS HONEST ONLY WHERE THE FALLBACK CAN COMPUTE
# THE SAME ANSWER. strip_to_text's can — its perl program is a tag-stripper and little
# else — which is why that function legitimately keeps one. S14 applies the SAME criterion
# to the one remaining site, strip_to_text_blocks, and the criterion decides against it:
# three perl substitutions against one sed expression.
#
#   1  script/style BODIES deleted      needs a -0777 slurp, a back-reference to the
#                                       opening tag name and a lazy bound     sed: NO
#   2  the BLOCK SENTINEL emitted       needs the block-tag class and an emission
#                                                                             sed: NO
#   3  tag -> space                                                           sed: yes
#
# SUBSTITUTION 2 IS THE ENTIRE REASON THIS FUNCTION EXISTS APART FROM strip_to_text, and
# losing it is not cosmetic. _guard_match's conjunctive rule requires both distinctive
# tokens of a value inside ONE structural block. With no sentinel every token lands in
# block 0, the same-block conjunct is vacuously true for every pair, and the rule degrades
# to a bare word window — which is verbatim the N-squared day-pairing false abort that
# ADR-008's first amendment exists to fix, and which measured as a permanent abort from two
# days onward. Substitution 1's absence compounds it: script and style bodies survive into
# the token stream on the arm that carries the verdict, adding machinery vocabulary to it
# and inflating the word count that the degraded-extraction floor is supposed to catch.
#
# REACHABILITY, STATED PRECISELY, because it is what makes this card correctly low-priority
# and also what stops it being nothing. strip_to_text_blocks's sole caller is
# verify_publishable_content, reached from cmd_publish and cmd_update, both of which
# preflight first — so a perl-ABSENT host never reaches the limb at all. Two windows
# remain. perl PRESENT but this program failing: `||` reads a non-zero STATUS, not an
# absence, so a perl too old for a construct, a memory limit on the -0777 slurp of a large
# render, or a locale abort all switch the projection silently. And a future caller that
# does not preflight — verify_publishable_content is the natural predicate for any later
# non-interactive publish path, and today it is safe only by caller discipline. Removing
# the limb makes it safe BY CONSTRUCTION. Both windows are fail-CLOSED directions — a
# false abort — which is exactly why nothing ever caught this: a false abort looks like
# the guard working.
#
#   S14a  DENOMINATOR — with a working perl the projection is non-empty, carries a block
#         sentinel, has dropped the script body, and clears the 20-word floor. Without
#         this every verdict below is vacuous
#   S14b  THE REGRESSION — with perl failing, NO second projection is produced: no output
#         AND a non-zero status. Both halves invert, so the arm cannot pass by accident
#   S14c  VISIBILITY — a failing perl writes to stderr; control: a working one writes 0B
#   S14d  SPECIFICITY for S14b — a render whose visible text is GENUINELY empty still
#         SUCCEEDS, so S14b's discriminator is the STATUS and not the byte count
#   S14e  the perl stub was withdrawn — everything after it grades production code
#   S14f  STRUCTURAL — the parsed body carries 0 fallback limbs of ANY kind, so a future
#         `|| awk`, `|| python3` or `|| true` fails here too; sensitivity: the same
#         detector finds the one strip_to_text legitimately keeps
#   S14g  THE ANSWER, KEPT EXECUTABLE — the removed limb is run over the same fixture and
#         its output compared against the real one. The card asked whether the two limbs
#         compute the same answer; this arm is that question standing in the suite with
#         its input, its comparison and its difference, rather than settled once in prose
#
# THE SECOND IDENTICAL SHAPE IS DELIBERATELY NOT TOUCHED, and the reason is mechanical
# rather than cautious. strip_to_text keeps its `|| sed` limb because S11f AND S14f both
# use it as their SENSITIVITY arm: remove it and both zeroes stop being measurements, and
# two required arms turn red for a reason unrelated to their subject. It is byte-frozen by
# #550 AC 5 besides. Any future change extending there must re-point both arms in the same
# commit.
#
# Offline: $WORK fixtures and a shell-function stub for perl. No network, no Node, no TTY,
# no gh. This group has no legitimate skip and is deliberately NOT declared in
# GUARD_EXPECTED_SKIPS.
echo
echo "The visible block projection has one limb (#749, D-5(A) as extended by D-14):"

# A render carrying (i) a script body whose distinctive token appears nowhere in the
# visible text, (ii) two block-level elements from the block-tag class, and (iii) enough
# visible words that the degraded-extraction floor is cleared on the working path.
S14_FIX="$WORK/s14_fix.html"
printf '%s' '<!DOCTYPE html><html><head><style>.hero{color:#333}</style><script>var s14Machinery="zzs14scriptonlyzz";</script></head><body><h2>Day Three</h2><p>Breakfast at the harbour bakery, then a slow walk along the old aqueduct before lunch.</p><div>Dinner is booked for eight at the tiled tavern near the castle gate.</div></body></html>' > "$S14_FIX"
# The strip_to_text_blocks counterpart of S11_VOID: markup, a style rule and a script body
# but NO visible text. Its projection is legitimately empty and its STATUS is still 0.
S14_VOID="$WORK/s14_void.html"
printf '%s' '<!DOCTYPE html><html><head><style>.hero{color:#333}</style></head><body><script>var mapReady=1;</script></body></html>' > "$S14_VOID"
S14_TOKEN='zzs14scriptonlyzz'
S14_ERR_OK="$WORK/s14_stderr_ok.txt"
S14_ERR_FAIL="$WORK/s14_stderr_fail.txt"
S14_ERR_VOID="$WORK/s14_stderr_void.txt"

# ── S14a — THE DENOMINATOR. Taken BEFORE the stub, as S11a is, so the values every arm
# below compares against are readings of production code.
S14_OK="$(strip_to_text_blocks "$S14_FIX" 2>"$S14_ERR_OK")";      S14_RC_OK=$?
S14_VOID_OUT="$(strip_to_text_blocks "$S14_VOID" 2>"$S14_ERR_VOID")"; S14_RC_VOID=$?
S14_ERRLEN_OK="$(wc -c < "$S14_ERR_OK" | tr -d ' ')"
S14_WORDS_OK="$(printf '%s' "$S14_OK" | _norm_words | wc -l | tr -d ' ')"
S14_WORDS_VOID="$(printf '%s' "$S14_VOID_OUT" | _norm_words | wc -l | tr -d ' ')"
case "$S14_OK" in *"$_GUARD_BLOCK"*) S14_SENT_OK=1 ;; *) S14_SENT_OK=0 ;; esac
case "$S14_OK" in *"$S14_TOKEN"*)    S14_SCRIPT_OK=1 ;; *) S14_SCRIPT_OK=0 ;; esac
if [ "$S14_RC_OK" -eq 0 ] && [ -n "$S14_OK" ] && [ "$S14_SENT_OK" -eq 1 ] \
   && [ "$S14_SCRIPT_OK" -eq 0 ] && [ "$S14_WORDS_OK" -ge 20 ]; then
  PASS "S14a: DENOMINATOR — with a working perl the projection of the fixture is ${#S14_OK}B carrying at least one block sentinel, the script body's token is gone, and ${S14_WORDS_OK} visible words clear the 20-word degraded-extraction floor. The projection is doing all three of its jobs, so the arms below compare real values"
else
  FAIL "S14a: rc=$S14_RC_OK len=${#S14_OK}B sentinel=$S14_SENT_OK script-token-survived=$S14_SCRIPT_OK words=$S14_WORDS_OK — the projection is empty, is emitting no block sentinel, is leaking the script body, or falls under the 20-word floor. Every S14 verdict below would be vacuous"
fi

# ── S14b — THE REGRESSION. perl is stubbed to fail the way a missing or too-old perl
# fails: non-zero, nothing on stdout. The question is what verify_publishable_content is
# then handed. With the fallback in place it is handed the sed limb's output — a
# well-formed, plausible, NON-EMPTY stream carrying no sentinels at all, at status 0. Both
# halves of this arm invert across the fix, which is what stops it passing by accident.
perl() { printf 'perl: simulated failure (S14 stub)\n' >&2; return 127; }
S14_FALLBACK="$(strip_to_text_blocks "$S14_FIX" 2>"$S14_ERR_FAIL")"; S14_RC_FAIL=$?
unset -f perl
S14_ERRLEN_FAIL="$(wc -c < "$S14_ERR_FAIL" | tr -d ' ')"
case "$S14_FALLBACK" in *"$_GUARD_BLOCK"*) S14_SENT_FB=1 ;; *) S14_SENT_FB=0 ;; esac
if [ -n "$S14_OK" ] && [ -z "$S14_FALLBACK" ] && [ "$S14_RC_FAIL" -ne 0 ]; then
  PASS "S14b: with perl failing, strip_to_text_blocks yields NO output and a non-zero status (rc=$S14_RC_FAIL), against the working limb's ${#S14_OK}B — there is no second projection for the content guard to act on, so it cannot be handed a sentinel-free stream that collapses the conjunctive rule to a bare word window"
else
  FAIL "S14b: a failed perl still produced ${#S14_FALLBACK}B at rc=$S14_RC_FAIL (working limb: ${#S14_OK}B), block sentinels in it = $S14_SENT_FB — a SECOND projection is reaching verify_publishable_content. It emits no block sentinel, so every token lands in block 0, the same-block conjunct is true for every pair, and the visible arm reverts to the N-squared day-pairing false abort ADR-008's first amendment removed"
fi

# ── S14c — VISIBILITY. The status is only half of it: a projection that fails must also
# SAY so. The `2>/dev/null` existed to silence perl before falling back, and with nothing
# to fall back to it silences the one message that explains the failure — leaving the
# consumer's own wording ("the rendered site yielded only 0 words of visible text") naming
# the symptom and never the cause. The control is the same call with a working perl, which
# must write nothing at all.
if [ "$S14_ERRLEN_OK" -eq 0 ] && [ "$S14_ERRLEN_FAIL" -gt 0 ]; then
  PASS "S14c: a failing perl wrote ${S14_ERRLEN_FAIL}B to stderr while a working one wrote ${S14_ERRLEN_OK}B — the projection no longer discards its own diagnostic, and the working-perl zero is what makes the non-zero the failure surfacing rather than ordinary chatter"
else
  FAIL "S14c: working-perl stderr=${S14_ERRLEN_OK}B, failing-perl stderr=${S14_ERRLEN_FAIL}B — the projection is still swallowing perl's stderr, or it is writing on the happy path, which would make this probe meaningless. A failure that announces nothing is the first of the three properties that made this defect silent"
fi

# ── S14d — SPECIFICITY for S14b. S14b's verdict is an EMPTY answer, and an empty answer is
# worthless unless emptiness means one specific thing. A render with markup, a style rule
# and a script body but no visible text projects to nothing LEGITIMATELY — that is a real
# identity a render may hold — and it still SUCCEEDS. The discriminator is therefore the
# exit status, not the byte count.
#
# THIS ARM IS A CONTROL AND IT HOLDS IN BOTH DIRECTIONS, which is why it gates on the
# near-miss ALONE and not on S14b's subject. Its being green before the fix as well as
# after is what makes S14b's red a measurement rather than a pair of arms agreeing with
# each other; folding S14_RC_FAIL into the condition here would make the control a second
# reading of the thing it is supposed to be independent of. The failed-projection status is
# REPORTED in both messages for the contrast, and decides neither of them.
if [ "$S14_RC_VOID" -eq 0 ] && [ "$S14_WORDS_VOID" -eq 0 ]; then
  PASS "S14d: a render whose visible text is genuinely empty projects to ${S14_WORDS_VOID} words and still SUCCEEDS (rc=$S14_RC_VOID) — so an empty output is a legitimate answer here and S14b's discriminator has to be the STATUS, which S14b reads (failed projection, for contrast: rc=$S14_RC_FAIL)"
else
  FAIL "S14d: the empty-visible-text render returned rc=$S14_RC_VOID with $S14_WORDS_VOID word(s) — a legitimately empty render is either failing or is not projecting to nothing, so S14b's empty answer no longer discriminates a failed projection from an empty one and its zero proves nothing (failed projection, for contrast: rc=$S14_RC_FAIL)"
fi

# ── S14e — THE RESTORE. S6c's rule applied to this stub: an injection that outlives its
# arm turns every later verdict into a grade of the stub.
S14_RESTORED="$(strip_to_text_blocks "$S14_FIX" 2>/dev/null)"
if [ -n "$S14_OK" ] && [ "$S14_RESTORED" = "$S14_OK" ]; then
  PASS "S14e: the perl stub was withdrawn and the projection reads its ${#S14_RESTORED}B denominator again — group T and everything after it grade production code"
else
  FAIL "S14e: after the restore the projection reads ${#S14_RESTORED}B rather than the ${#S14_OK}B S14a measured — the stub survived its arm and every verdict below is grading it"
fi

# ── S14f — STRUCTURAL, and the arm that outlives this particular fallback. S14b measures
# the sed limb specifically; this one asserts the CONTRACT — the projection is a single
# limb — so a future `|| awk …`, `|| python3 …` or `|| true` is caught by the same arm
# rather than needing its own. Read from the PARSED body, so a mention inside a comment
# cannot fake it. Its sensitivity arm is strip_to_text, which legitimately keeps a fallback
# and is byte-frozen by #550 AC 5: the detector demonstrably fires on the shape it is
# looking for, so the zero on this projection is a measurement. This is S11f's shape with
# a second subject, and the two share that one control.
S14_BODY_BLK="$(declare -f strip_to_text_blocks)"
S14_BODY_TEXT="$(declare -f strip_to_text)"
case "$S14_BODY_BLK"  in *'||'*) S14_BLK_LIMB=1 ;; *) S14_BLK_LIMB=0 ;; esac
case "$S14_BODY_TEXT" in *'||'*) S14_TEXT_LIMB=1 ;; *) S14_TEXT_LIMB=0 ;; esac
case "$S14_BODY_BLK"  in *zzz_not_a_real_identifier*) S14_BLK_SPEC=1 ;; *) S14_BLK_SPEC=0 ;; esac
if [ "${#S14_BODY_BLK}" -gt 0 ] && [ "${#S14_BODY_TEXT}" -gt 0 ] \
   && [ "$S14_BLK_LIMB" -eq 0 ] && [ "$S14_TEXT_LIMB" -eq 1 ] && [ "$S14_BLK_SPEC" -eq 0 ]; then
  PASS "S14f: the parsed body of strip_to_text_blocks (${#S14_BODY_BLK}B) carries 0 fallback limbs; the sensitivity arm found 1 in strip_to_text (${#S14_BODY_TEXT}B), which legitimately keeps one and is byte-frozen, and the specificity arm found a fabricated token in 0 of them — the zero is a measurement, and a second limb of ANY kind fails here"
else
  FAIL "S14f: blocks-limb=$S14_BLK_LIMB text-limb=$S14_TEXT_LIMB specificity=$S14_BLK_SPEC blocks=${#S14_BODY_BLK}B text=${#S14_BODY_TEXT}B — the visible block projection carries a second limb, or the detector cannot see the one strip_to_text carries, in which case its zero proves nothing"
fi

# ── S14g — THE ANSWER, KEPT EXECUTABLE. The card asks whether the two limbs compute the
# same answer. Settling that in a comment makes it true on the day it was written; running
# it makes it true on every push. The removed limb is restored under the projection's own
# name, run over the SAME fixture, and withdrawn again — and the withdrawal is graded here
# rather than assumed, because a shadow that outlived this arm would silently turn every
# later reader of this function into a reader of a sed expression.
S14_PROD_DEF="$(declare -f strip_to_text_blocks)"
strip_to_text_blocks() { sed -E 's/<[^>]*>/ /g' "$1"; }   # the removed limb, verbatim
S14_SHADOW="$(strip_to_text_blocks "$S14_FIX" 2>/dev/null)"
eval "$S14_PROD_DEF"                                      # the shadow is withdrawn HERE
S14_AFTER="$(strip_to_text_blocks "$S14_FIX" 2>/dev/null)"
case "$S14_SHADOW" in *"$_GUARD_BLOCK"*) S14_SENT_SH=1 ;; *) S14_SENT_SH=0 ;; esac
case "$S14_SHADOW" in *"$S14_TOKEN"*)    S14_SCRIPT_SH=1 ;; *) S14_SCRIPT_SH=0 ;; esac
if [ -z "$S14_SHADOW" ] || [ -z "$S14_OK" ]; then
  FAIL "S14g: one of the two projections produced nothing (shadow=${#S14_SHADOW}B real=${#S14_OK}B), so the comparison below would be between empty streams and would say nothing about whether the limbs agree"
elif [ "$S14_AFTER" != "$S14_OK" ]; then
  FAIL "S14g: THE SHADOW WAS NOT WITHDRAWN — after the restore the projection reads ${#S14_AFTER}B rather than S14a's ${#S14_OK}B. Every later caller of strip_to_text_blocks in this process is reading a sed expression, and the comparison this arm makes is worth less than the damage it left behind"
elif [ "$S14_SENT_SH" -eq 0 ] && [ "$S14_SENT_OK" -eq 1 ] && [ "$S14_SCRIPT_SH" -eq 1 ] && [ "$S14_SCRIPT_OK" -eq 0 ]; then
  PASS "S14g: THE TWO LIMBS DO NOT COMPUTE THE SAME ANSWER, measured rather than asserted — over one fixture the removed sed limb yields ${#S14_SHADOW}B carrying ZERO block sentinels and the script body's token INTACT, while the perl limb yields ${#S14_OK}B carrying sentinels and no script token. That is the card's question with its input, its comparison and its difference standing in the suite; the shadow was withdrawn and the projection reads its denominator again"
else
  FAIL "S14g: the comparison did not separate the limbs — shadow sentinels=$S14_SENT_SH real sentinels=$S14_SENT_OK, shadow script-token=$S14_SCRIPT_SH real script-token=$S14_SCRIPT_OK. Either the fixture stopped carrying a block tag or a script body, or the two limbs now agree, in which case the premise of this whole group has changed and the removal needs re-deciding rather than re-asserting"
fi

# ── Group S15 (#1184) — THE UNDETERMINED STATE: "could not read it" is not "it changed" ──
#
# S0–S14 grade the gate, the projection it reads and the projections beside it. S15 grades
# what the gate does when the outgoing render has NO itinerary identity at all. Before this
# card the resolver could not tell the two apart: an empty outgoing digest never equals the
# recorded baseline, so an unreadable or unprojectable render fell through to `unconfirmed`
# or `stale`, the gate's abort told the organizer that the itinerary content differed, and
# confirm went on to the CONFIRM prompt against a state nobody had computed. The conflation
# was not confined to an empty digest either. Until the pin (#1468 case 1), BSD `tr` under a
# UTF-8 locale exited 1 AFTER writing a prefix when it met a byte that is not valid UTF-8, so
# the digest identified a TRUNCATED itinerary, and a day appended behind such a byte read as
# `none-pending`, or as `confirmed` when a confirmation covered the prefix — either member of the
# proceed set publishes an unapproved change.
#
#   S15a  THE SUBJECT, unreadable — a dangling-symlink render with a recorded baseline
#         resolves `undetermined`, with no confirmation record and with an old one
#   S15b  THE SUBJECT, unprojectable — perl failing resolves `undetermined`; control: the
#         same trip with perl working resolves `none-pending`
#   S15c  THE SUBJECT, unnormalizable — the normalization stage failing yields NO digest
#         and `undetermined`; control: with it working the render digests to its baseline
#   S15d  CONTROL — a READABLE changed render still resolves `unconfirmed` / `stale`
#   S15e  SPECIFICITY — the token keys on a FAILED read, not an empty one: no baseline with
#         an unreadable render stays `none-pending`, and a render whose visible text is
#         genuinely empty still resolves `unconfirmed`
#   S15f  AC-2 — the gate aborts, names the token, and makes no content claim in either
#         direction; controls: a readable changed render's abort does make the content claim,
#         and the claim lexicon flags a planted change claim and a planted no-change claim
#   S15g  AC-3 — confirm refuses before the terminal check and records nothing; control: a
#         readable changed render reaches the terminal check
#   S15h  AC-4, VISIBILITY — a failing perl's stderr now reaches the caller from each of the
#         three programs that used to discard it; control: a working perl writes 0 bytes
#   S15i  AC-4, POLICY — over the parsed bodies of every perl-bearing function, a discard
#         appears exactly where a fallback does, and only strip_to_text carries both
#   S15j  THE RESTORE — every stub this group set is withdrawn
#   S15k  THE PIN — with `pipefail` turned OFF in a fresh shell that sourced the script, a
#         day appended behind such a byte still resolves `undetermined` on both routes and
#         the gate refuses; control: the same day in valid UTF-8 resolves `unconfirmed`
#   S15l  THE RECORDER — on an unreadable render it warns NOT ACTIVE only with no baseline
#         and keeps-the-baseline only with one, writing no sidecar either way; control: a
#         readable render writes the sidecar. Neither arm sets a stub in this shell
#
# HOW THE ARMS ARE WRITTEN, because this suite enforces three rules on itself. Every
# negative is a captured value inside a `[ … ]` conjunction that leads to a PASS — never a
# live command whose failure lands on a PASS limb, which group MD's static arm refuses and
# which MD_LEGACY is not allowed to grow to excuse. No verdict is read through a pipeline
# into an early-exiting grep (group PF). And every stub is unset in the arm that set it.
#
# S15c STUBS `tr` RATHER THAN FEEDING IT A REAL INVALID BYTE: no real byte makes `tr` fail
# under `LC_ALL=C` on either platform, which is where the normalization runs since the pin
# (#1468 case 1), so the stage is stubbed. A stubbed stage fails on both, and a failing stage
# is exactly what the digest's status read must catch.
#
# Offline: $WORK fixtures, a dangling symlink, and shell-function stubs for perl and tr. No
# network, no Node, no TTY, no gh. This group has no legitimate skip and is deliberately
# NOT declared in GUARD_EXPECTED_SKIPS.
echo
echo "The undetermined state — could not read is not changed (#1184):"

S15_RENDER='outputs/porto-travel-site.html'
# A render the resolver can LOCATE but nothing can READ. A dangling symlink rather than a
# chmod 000 file, because a privileged runner reads a 000 file anyway (the note on L5b) and
# nothing, root included, reads through a link to a file that does not exist.
s15_dangling() { # <name> -> a trip dir whose render is a dangling symlink
  local d="$WORK/$1"
  mkdir -p "$d/outputs"
  ln -s "$d/outputs/zzq-s15-no-such-render.html" "$d/$S15_RENDER"
  printf '%s' "$d"
}

# ── S15a — THE SUBJECT, UNREADABLE. Two trips, both with a recorded baseline: one with no
# confirmation record (which used to read `unconfirmed`) and one with an old one (which
# used to read `stale`). Fixture integrity is graded first: the render must be a link, must
# be unreadable, and must still be what resolve_site_html hands the resolver.
S15AD="$(s15_dangling s15a)"
s_record "$S15AD/.published-itinerary" "$S_DA" published
S15AD2="$(s15_dangling s15a2)"
s_record "$S15AD2/.published-itinerary" "$S_DA" published
s_record "$S15AD2/.change-confirmed"    "$S_DA" confirmed
S15A_RES="$(resolve_site_html "$S15AD" 2>/dev/null)"
S15A_ST1="$(change_confirmation_state "$S15AD" 2>/dev/null)"
S15A_ST2="$(change_confirmation_state "$S15AD2" 2>/dev/null)"
S15A_LINK=0; [ -L "$S15AD/$S15_RENDER" ] && S15A_LINK=1
S15A_READ=0; [ -r "$S15AD/$S15_RENDER" ] && S15A_READ=1
if [ "$S15A_LINK" -ne 1 ] || [ "$S15A_READ" -ne 0 ] || [ "$S15A_RES" != "$S15AD/$S15_RENDER" ]; then
  FAIL "S15a: fixture integrity — the render is a symlink=$S15A_LINK and readable=$S15A_READ, and resolve_site_html returned '$S15A_RES'. The fixture is not an unreadable render the resolver can still locate, so the verdict would be about something else"
elif [ "$S15A_ST1" = "undetermined" ] && [ "$S15A_ST2" = "undetermined" ]; then
  PASS "S15a: an UNREADABLE outgoing render with a recorded baseline resolves undetermined — with no confirmation record ($S15A_ST1) and with an old one ($S15A_ST2). Neither is read as the itinerary having moved, which is what unconfirmed and stale both assert"
else
  FAIL "S15a: an unreadable render resolved '$S15A_ST1' with no record and '$S15A_ST2' with an old one — the resolver still reads 'could not read it' as 'it changed', and the gate and confirm will say so to the organizer"
fi

# ── S15b — THE SUBJECT, UNPROJECTABLE. The render is IDENTICAL to the baseline, so the plan
# has not moved at all; the perl stub is the only thing that differs between the two
# resolutions, and the control is the same trip read again once the stub is gone.
S15BD="$(s_fixture s15b 14:00 none)"
s_record "$S15BD/.published-itinerary" "$S_DA" published
perl() { printf 'perl: simulated failure (S15 stub)\n' >&2; return 127; }
S15B_ST="$(change_confirmation_state "$S15BD" 2>/dev/null)"
unset -f perl
S15B_CTL="$(change_confirmation_state "$S15BD" 2>/dev/null)"
if [ "$S15B_CTL" != "none-pending" ]; then
  FAIL "S15b: CONTROL — with perl working the same trip resolved '$S15B_CTL', not none-pending. Its render does not match its own baseline, so an undetermined here would not be attributable to the stub"
elif [ "$S15B_ST" = "undetermined" ]; then
  PASS "S15b: with perl failing, a trip whose render is IDENTICAL to its baseline resolves undetermined, and with perl working the same trip resolves $S15B_CTL — an UNPROJECTABLE render is its own state, not a plan change"
else
  FAIL "S15b: with perl failing, a trip whose render has not moved resolved '$S15B_ST' — a projection that could not run is being read as a change to the plan"
fi

# ── S15c — THE SUBJECT, UNNORMALIZABLE. No real byte makes `tr` fail under `LC_ALL=C` on either
# platform, so the stage is stubbed to fail. What is graded is the digest's own STATUS read: a
# pipeline whose stage fails still ends in cksum, and cksum over whatever arrived is a
# well-formed token (the empty-input token, here) that identifies no itinerary at all.
S15CD="$(s_fixture s15c 14:00 none)"
s_record "$S15CD/.published-itinerary" "$S_DA" published
tr() { return 1; }
S15C_DG="$(itinerary_digest "$S15CD/$S15_RENDER" 2>/dev/null)"
S15C_ST="$(change_confirmation_state "$S15CD" 2>/dev/null)"
unset -f tr
S15C_CTL="$(itinerary_digest "$S15CD/$S15_RENDER")"
if [ -z "$S15C_CTL" ] || [ "$S15C_CTL" != "$S_DA" ]; then
  FAIL "S15c: CONTROL — with tr working the render digested '$S15C_CTL' against its baseline $S_DA, so the fixture's identity is not known and the verdict below would not be attributable to the stub"
elif [ -z "$S15C_DG" ] && [ "$S15C_ST" = "undetermined" ]; then
  PASS "S15c: with the normalization stage failing, itinerary_digest yields NO token and the state is undetermined, while with it working the same render digests $S15C_CTL — a failing stage is 'no answer', so a truncated or empty normalization is never compared as though it were the itinerary"
else
  FAIL "S15c: with the normalization stage failing, itinerary_digest yielded '$S15C_DG' and the state read '$S15C_ST' — a failed pipeline still produced a token, which identifies a truncated or empty normalization, and the gate would compare it as though it identified the itinerary"
fi

# ── S15d — CONTROL. A readable render whose itinerary DID move must still read as a change.
# It gates on the near-miss alone (S14d's rule): it holds before this card and after it,
# which is what makes S15a–S15c measurements rather than a resolver that stopped seeing
# changes altogether.
S15DD="$(s_fixture s15d 16:30 none)"
s_record "$S15DD/.published-itinerary" "$S_DA" published
S15DD2="$(s_fixture s15d2 16:30 none)"
s_record "$S15DD2/.published-itinerary" "$S_DA" published
s_record "$S15DD2/.change-confirmed"    "$S_DA" confirmed
S15D_ST1="$(change_confirmation_state "$S15DD")"
S15D_ST2="$(change_confirmation_state "$S15DD2")"
if [ "$S15D_ST1" = "unconfirmed" ] && [ "$S15D_ST2" = "stale" ]; then
  PASS "S15d: CONTROL — a READABLE render whose itinerary moved still resolves unconfirmed with no confirmation record and stale with an old one, so the new token does not swallow a real change"
else
  FAIL "S15d: a readable changed render resolved '$S15D_ST1' with no record and '$S15D_ST2' with an old one, not unconfirmed and stale — a real itinerary change is no longer reported as one"
fi

# ── S15e — SPECIFICITY. The token must key on a FAILED read and on nothing else. (i) With no
# baseline the answer does not depend on the render, so an unreadable one still reads
# `none-pending`: the no-baseline branch answers first. (ii) A render whose visible text is
# genuinely empty projects SUCCESSFULLY to nothing and gets a real token — S11d's property,
# one level up — so against a real baseline it reads `unconfirmed`, never `undetermined`.
S15ED="$(s15_dangling s15e)"
S15ED2="$(s_fixture s15e2 14:00 none)"
printf '%s' '<!DOCTYPE html><html><head><style>.hero{color:#333}</style></head><body><script>var mapReady=1;</script></body></html>' > "$S15ED2/$S15_RENDER"
s_record "$S15ED2/.published-itinerary" "$S_DA" published
S15E_ST1="$(change_confirmation_state "$S15ED" 2>/dev/null)"
S15E_ST2="$(change_confirmation_state "$S15ED2")"
S15E_DG2="$(itinerary_digest "$S15ED2/$S15_RENDER")"
if [ -z "$S15E_DG2" ]; then
  FAIL "S15e: the empty-visible-text render yielded no digest at all, so it cannot show that an empty OUTPUT differs from a failed STATUS — the specificity arm would be vacuous"
elif [ "$S15E_ST1" = "none-pending" ] && [ "$S15E_ST2" = "unconfirmed" ]; then
  PASS "S15e: SPECIFICITY — with NO baseline an unreadable render still resolves none-pending, and a render whose visible text is genuinely empty digests to $S15E_DG2 and resolves unconfirmed against a real baseline. The token keys on a failed read, never on an empty one"
else
  FAIL "S15e: no baseline with an unreadable render resolved '$S15E_ST1' (want none-pending), and an empty-visible-text render with a baseline resolved '$S15E_ST2' (want unconfirmed) — the token is firing on emptiness, or ahead of the no-baseline branch"
fi

# ── S15f — AC-2, THE GATE. Three things at once, and the second and third are why the arm
# exists: the gate aborts, its message names the token, and its message makes NO CONTENT
# CLAIM IN EITHER DIRECTION — neither that the itinerary changed nor that it did not. What
# the gate failed to establish is the render's identity, and its message may speak of that
# and of nothing else.
#
# THE CLAIM IS GRADED BY A LEXICON OF THE VOCABULARY OF CHANGE, BOTH POLARITIES, not by the
# one phrase `*)` uses. The earlier form of this arm looked only for "itinerary content
# differs", and a message saying "This is not an itinerary change" — the opposite claim,
# which nobody computed either — passed it, as did one saying the itinerary "changed" in
# other words. A word from the lexicon anywhere in the message fails the arm, even where the
# sentence around it only wonders about a change, because such a sentence is one edit away
# from making one. The stated boundary: a lexicon is a list, so a claim made entirely in
# words outside it is not seen.
#
# Three controls. The gate on a readable changed render must abort carrying the vocabulary,
# so the capture can see a claim. The lexicon must flag a planted change claim and a planted
# no-change claim, so both polarities are in it. And it must pass a planted identity
# sentence, so it is not flagging everything. The trip dir is scrubbed from each message
# first, so a path can never supply a stem.
S15F_LEX='differ chang move same identical match modif altered edit'
s15f_claims() { # <text> -> the lexicon stems the text carries, space-separated; empty when none
  local t="$1" w out=""
  shopt -s nocasematch
  for w in $S15F_LEX; do
    case "$t" in *"$w"*) out="$out$w " ;; esac
  done
  shopt -u nocasematch
  printf '%s' "${out% }"
}
S15F_TRIP='<trip>'
S15F_ERR="$( ( require_change_confirmation "$S15AD" ) 2>&1 >/dev/null )"; S15F_RC=$?
S15F_CERR="$( ( require_change_confirmation "$S15DD" ) 2>&1 >/dev/null )"; S15F_CRC=$?
S15F_MSG="${S15F_ERR//"$S15AD"/$S15F_TRIP}"
S15F_CMSG="${S15F_CERR//"$S15DD"/$S15F_TRIP}"
S15F_TOKEN=0
case "$S15F_MSG" in *undetermined*) S15F_TOKEN=1 ;; esac
S15F_HITS="$(s15f_claims "$S15F_MSG")"
S15F_CHITS="$(s15f_claims "$S15F_CMSG")"
S15F_YES="$(s15f_claims 'the itinerary changed since the published plan')"
S15F_NO="$(s15f_claims 'This is not an itinerary change')"
S15F_ID="$(s15f_claims 'could not identify the itinerary content of the outgoing render')"
if [ "$S15F_CRC" -eq 0 ] || [ -z "$S15F_CHITS" ]; then
  FAIL "S15f: CONTROL — the gate on a readable changed render returned rc=$S15F_CRC carrying claim vocabulary [$S15F_CHITS], so this probe cannot see the claim it is looking for and a zero on the subject would prove nothing"
elif [ -z "$S15F_YES" ] || [ -z "$S15F_NO" ] || [ -n "$S15F_ID" ]; then
  FAIL "S15f: CONTROL on the lexicon — a planted change claim read [$S15F_YES], a planted no-change claim read [$S15F_NO] and a planted identity sentence read [$S15F_ID]. Both claims must be flagged and the identity sentence must not, or the lexicon is missing a polarity or flagging everything"
elif [ "$S15F_RC" -ne 0 ] && [ "$S15F_TOKEN" -eq 1 ] && [ -z "$S15F_HITS" ]; then
  PASS "S15f: AC-2 — on an unreadable render the gate ABORTS (rc=$S15F_RC), names the token undetermined, and its message carries none of the vocabulary of change in either polarity ($S15F_LEX), so it claims neither that the itinerary changed nor that it did not. The control, a readable changed render, aborts carrying that vocabulary [$S15F_CHITS], and the lexicon flags a planted change claim [$S15F_YES] and a planted no-change claim [$S15F_NO] while passing an identity sentence"
else
  FAIL "S15f: on an unreadable render the gate returned rc=$S15F_RC, named the token=$S15F_TOKEN and carried claim vocabulary [$S15F_HITS] — it either publishes, or its abort makes a content claim nobody computed, in one direction or the other. Message: ${S15F_MSG:0:600}"
fi

# ── S15g — AC-3, CONFIRM. It must refuse BEFORE the terminal check — which is also before
# the prompt, so on a TTY the CONFIRM prompt is unreachable on this state — and record
# nothing. stdin is /dev/null, so a run that got past the refusal would die at the terminal
# check instead, and that difference is what the arm reads. The control is confirm on a
# readable changed render, which must reach the terminal check.
S15G_ERR="$( ( cmd_confirm "$S15AD" ) </dev/null 2>&1 >/dev/null )"; S15G_RC=$?
S15G_CERR="$( ( cmd_confirm "$S15DD" ) </dev/null 2>&1 >/dev/null )"; S15G_CRC=$?
S15G_CAUSE=0; S15G_TERM=0; S15G_CTERM=0; S15G_REC=0
case "$S15G_ERR"  in *"could not determine"*) S15G_CAUSE=1 ;; esac
case "$S15G_ERR"  in *"requires a terminal"*) S15G_TERM=1 ;;  esac
case "$S15G_CERR" in *"requires a terminal"*) S15G_CTERM=1 ;; esac
[ -e "$S15AD/.change-confirmed" ] && S15G_REC=1
if [ "$S15G_CRC" -eq 0 ] || [ "$S15G_CTERM" -ne 1 ]; then
  FAIL "S15g: CONTROL — confirm on a readable changed render returned rc=$S15G_CRC and reached the terminal check=$S15G_CTERM, so this probe cannot tell a refusal before the prompt from a death at the terminal check"
elif [ "$S15G_RC" -ne 0 ] && [ "$S15G_CAUSE" -eq 1 ] && [ "$S15G_TERM" -eq 0 ] && [ "$S15G_REC" -eq 0 ]; then
  PASS "S15g: AC-3 — confirm on an unreadable render REFUSES (rc=$S15G_RC), saying it could not determine whether the itinerary changed, never reaches the terminal check, and writes no confirmation record; the control, a readable changed render, does reach the terminal check (rc=$S15G_CRC). On a TTY the CONFIRM prompt is unreachable on this state"
else
  FAIL "S15g: confirm on an unreadable render returned rc=$S15G_RC, named the cause=$S15G_CAUSE, reached the terminal check=$S15G_TERM and wrote a record=$S15G_REC — on a terminal the organizer would be asked to type CONFIRM against a state nobody could compute"
fi

# ── S15h — AC-4, VISIBILITY. Each program that used to discard its stderr is run with a
# failing perl and its stderr captured: strip_to_published_text, strip_to_joined_text and
# _decode_entities. The control is the same three calls with perl working, over a healthy
# render, which must write nothing — so the non-zero is the failure surfacing and not chatter.
S15H_FIX="$WORK/s15h.html"; s_render "$S15H_FIX" 14:00 pending
strip_to_published_text "$S15H_FIX" >/dev/null 2>"$WORK/s15h_ok_pub.err"
strip_to_joined_text    "$S15H_FIX" >/dev/null 2>"$WORK/s15h_ok_join.err"
_decode_entities       < "$S15H_FIX" >/dev/null 2>"$WORK/s15h_ok_dec.err"
perl() { printf 'perl: simulated failure (S15 stub)\n' >&2; return 127; }
strip_to_published_text "$S15H_FIX" >/dev/null 2>"$WORK/s15h_fail_pub.err"
strip_to_joined_text    "$S15H_FIX" >/dev/null 2>"$WORK/s15h_fail_join.err"
_decode_entities       < "$S15H_FIX" >/dev/null 2>"$WORK/s15h_fail_dec.err"
unset -f perl
S15H_OKP="$(wc -c < "$WORK/s15h_ok_pub.err" | tr -d ' ')"
S15H_OKJ="$(wc -c < "$WORK/s15h_ok_join.err" | tr -d ' ')"
S15H_OKD="$(wc -c < "$WORK/s15h_ok_dec.err" | tr -d ' ')"
S15H_FAP="$(wc -c < "$WORK/s15h_fail_pub.err" | tr -d ' ')"
S15H_FAJ="$(wc -c < "$WORK/s15h_fail_join.err" | tr -d ' ')"
S15H_FAD="$(wc -c < "$WORK/s15h_fail_dec.err" | tr -d ' ')"
if [ "$S15H_OKP" -ne 0 ] || [ "$S15H_OKJ" -ne 0 ] || [ "$S15H_OKD" -ne 0 ]; then
  FAIL "S15h: CONTROL — with perl working the three programs wrote ${S15H_OKP}B / ${S15H_OKJ}B / ${S15H_OKD}B of stderr over a healthy render, so a non-zero under the stub would not be distinguishable from ordinary output"
elif [ "$S15H_FAP" -gt 0 ] && [ "$S15H_FAJ" -gt 0 ] && [ "$S15H_FAD" -gt 0 ]; then
  PASS "S15h: AC-4 — with perl failing, strip_to_published_text, strip_to_joined_text and _decode_entities each pass its diagnostic through (${S15H_FAP}B / ${S15H_FAJ}B / ${S15H_FAD}B), where a working perl writes 0B from each. A failure in any of the three now says why, ahead of the guard's own refusal of the projection it could not read"
else
  FAIL "S15h: with perl failing the three programs wrote ${S15H_FAP}B / ${S15H_FAJ}B / ${S15H_FAD}B of stderr — at least one still discards the only trace of why it failed, so the guard downstream can refuse the projection and name it but cannot say what went wrong"
fi

# ── S15i — AC-4, POLICY, read from the PARSED bodies so a comment cannot fake it. The rule
# is stated once, above strip_to_published_text: a program discards its stderr only when a
# fallback limb follows it. So over every perl-bearing function, `/dev/null` is present
# exactly where `||` is, and strip_to_text — the single function with a fallback — is the
# single one with both. `declare -f` renders the redirection as `2> /dev/null`, which is why
# the discard is matched on `/dev/null` alone.
#
# COMPLETENESS, AND ITS STATED BOUNDARY. The list of functions below is a list, so an
# eighth perl program added to the publish script would be invisible to it. The arm
# therefore counts the script's non-comment lines that invoke perl and requires the count
# to equal the length of the list, so a new program fails here until it is listed. The
# count reads an invocation by NAME — at line start, or after whitespace, `(`, `|`, `;`, a
# backtick or `$` — so a program inside a command substitution counts as well as one at
# the start of a line; its control fixture carries both. What it does not see, by
# construction: perl invoked through a variable or by a path (`$PERL`, `/usr/bin/perl`),
# and a change that removes one program while adding another, because it compares a count
# and not a set.
S15I_FNS='strip_to_text strip_to_published_text strip_to_text_blocks strip_to_joined_text strip_to_shape_text _decode_entities strip_to_itinerary_text _digest_of'
S15I_RE='(^|[[:space:](|;`$])perl[[:space:]]+-'
s15_perl_lines() { # <file> -> the number of non-comment lines that invoke perl by name
  local line t n=0
  while IFS= read -r line || [ -n "$line" ]; do
    t="${line#"${line%%[![:space:]]*}"}"
    case "$t" in '#'*) continue ;; esac
    [[ "$line" =~ $S15I_RE ]] && n=$((n+1))
  done < "$1"
  printf '%d' "$n"
}
S15I_SYNF="$WORK/s15i_perl_lines.sh"
{
  printf '%s\n' '  perl -0777 -pe "s/a/b/" "$1"'
  printf '%s\n' 'x="$(perl -e "print 1")"'
  printf '%s\n' '  # perl -pe 1'
  printf '%s\n' 'y=superperl -x'
} > "$S15I_SYNF"
S15I_SYN="$(s15_perl_lines "$S15I_SYNF")"
S15I_NLINE="$(s15_perl_lines "$SELF_PUBLISH")"
S15I_NFN=0; S15I_EMPTY=0; S15I_SPEC=0; S15I_TEXT=""; S15I_BAD=""; S15I_BITS=""
for s15fn in $S15I_FNS; do
  S15I_NFN=$((S15I_NFN+1))
  s15body="$(declare -f "$s15fn" 2>/dev/null)"
  [ -n "$s15body" ] || S15I_EMPTY=$((S15I_EMPTY+1))
  s15dn=0; s15fb=0
  case "$s15body" in *'/dev/null'*) s15dn=1 ;; esac
  case "$s15body" in *'||'*)        s15fb=1 ;; esac
  case "$s15body" in *zzz_not_a_real_identifier*) S15I_SPEC=$((S15I_SPEC+1)) ;; esac
  S15I_BITS="$S15I_BITS $s15fn=$s15dn$s15fb"
  if [ "$s15fn" = "strip_to_text" ]; then S15I_TEXT="$s15dn$s15fb"
  elif [ "$s15dn$s15fb" != "00" ]; then S15I_BAD="$S15I_BAD $s15fn=$s15dn$s15fb"; fi
done
if [ "$S15I_EMPTY" -ne 0 ]; then
  FAIL "S15i: $S15I_EMPTY of the $S15I_NFN listed functions have no parsed body — a name no longer resolves, and a clean reading of a missing body would be an empty scan"
elif [ "$S15I_SYN" -ne 2 ]; then
  FAIL "S15i: CONTROL on the completeness count — over a fixture carrying a line-start invocation, a mid-line one inside a command substitution, a comment and a longer name, the scan counted $S15I_SYN, not 2, so its count over the publish script is not a measurement"
elif [ "$S15I_TEXT" != "11" ]; then
  FAIL "S15i: SENSITIVITY — strip_to_text reads discard/fallback=$S15I_TEXT, not 11. It is the one function that legitimately carries both, so the detector either cannot see a discard or a fallback, and every 00 below proves nothing"
elif [ "$S15I_NLINE" -ne "$S15I_NFN" ]; then
  FAIL "S15i: COMPLETENESS — $S15I_NLINE non-comment lines of the publish script invoke perl, but $S15I_NFN functions are listed here. A perl program exists that this policy check does not read; list it, or remove the listing of one that is gone"
elif [ "$S15I_SPEC" -ne 0 ]; then
  FAIL "S15i: SPECIFICITY — a fabricated identifier was found in $S15I_SPEC parsed body/bodies, so the matcher is reading something other than the bodies"
elif [ -z "$S15I_BAD" ]; then
  PASS "S15i: AC-4 — over the parsed bodies of all $S15I_NFN perl-bearing functions (bits discard/fallback:$S15I_BITS) a discard appears exactly where a fallback does, and only strip_to_text carries both. The completeness count agrees ($S15I_NLINE invoking lines against $S15I_NFN listed functions), and its control fixture counted the mid-line invocation as well as the line-start one"
else
  FAIL "S15i: the rule 'discard only in front of a fallback' is broken by:$S15I_BAD — a program with no fallback is discarding the only message that explains its failure, or a fallback is running with its first limb's error in view"
fi

# ── S15j — THE RESTORE. S6c's rule applied to this group's stubs: an injection that outlives
# its arm turns every later verdict into a grade of the stub. Both stubbed names must be
# gone as functions, and the projection must read S0's token again on a fresh render.
S15J_R="$WORK/s15j.html"; s_render "$S15J_R" 14:00 none
S15J_DG="$(itinerary_digest "$S15J_R")"
S15J_STUBS=""
declare -F perl >/dev/null 2>&1 && S15J_STUBS="$S15J_STUBS perl"
declare -F tr   >/dev/null 2>&1 && S15J_STUBS="$S15J_STUBS tr"
if [ -z "$S15J_STUBS" ] && [ -n "$S15J_DG" ] && [ "$S15J_DG" = "$S_DA" ]; then
  PASS "S15j: every stub this group set is withdrawn — neither perl nor tr is a shell function any more, and a fresh render digests $S15J_DG, the token S0 read before any stub existed. Group T and everything after it grade production code"
else
  FAIL "S15j: after the group the stubs still defined are [${S15J_STUBS# }] and a fresh render digests '$S15J_DG' against S0's $S_DA — a stub outlived its arm, and every verdict after it is grading the stub"
fi

# ── S15k — THE PIN. itinerary_digest reads its pipeline's status with `pipefail` set INSIDE
# its own command substitution, and this arm is what shows the placement holds. Every arm
# above runs in this suite's shell, which sets `pipefail` itself before sourcing the script,
# so none of them can tell the pin from that line or from the script's own `set` line:
# remove the pin, or reduce the script's `set -euo pipefail` to `set -eu`, and they all stay
# green. This arm starts a FRESH bash from the repository root, sources the script by its
# repository-relative path, and turns `pipefail` OFF, so the pin is the only `pipefail` left.
#
# ITS INPUT IS THE RENDER THAT OPENED THE FAIL-OPEN: the baseline render with a day inserted
# after its last published text, the day's own text opening with byte 0xC9, which is not
# valid UTF-8, read under LC_ALL=en_US.UTF-8. It goes through both routes that published it
# before #1184 — `none-pending` (the baseline is the render without the day) and `confirmed`
# (the baseline is an older plan, and the confirmation is the render without the day). Both
# must read `undetermined`, and the gate must refuse on both.
#
# THE FAILING STAGE IS EMULATED. Under the pin (#1468 case 1) the normalization runs under
# LC_ALL=C, where no platform's `tr` stops on that byte, so the case is graded on every
# platform, the CI runner included, through a `tr` defined in the fresh shell alone, which
# writes the translation of everything before the first 0xC9 byte and returns 1 — the failure
# BSD `tr` showed under a UTF-8 locale before the pin, reproduced. The emulation lives and dies
# with that shell; this shell never holds it, and S15j's restore is unaffected.
#
# FIXTURE INTEGRITY, graded first. Every fresh shell must report `pipefail` off. The emulated
# stage must fail on the render and pass the valid-UTF-8 one. And the prefix digest — the same
# pipeline with no `pipefail` at all, which is what the digest reads if the pin is removed —
# must equal the baseline, so this input really does publish without the pin and a pass here
# is the pin's doing. The control is the same day in valid UTF-8 through the same fresh shell:
# that render can be identified, so it must read `unconfirmed`, which shows the harness does
# not read everything as `undetermined`.
S15K_FRESH="$WORK/s15k_fresh.sh"
cat > "$S15K_FRESH" <<'FRESH'
m="$1"; d="$2"; r="$3"
source scripts/publish-trip-site.sh || { printf 'SOURCE-FAILED'; exit 0; }
set +o pipefail
if [ "$m" = emulated ]; then
  tr() {
    perl -0777 -e 'binmode STDIN; binmode STDOUT; my $s = <STDIN>; $s = "" unless defined $s; my $cut = ($s =~ s/\xC9.*//s); print $s; exit($cut ? 1 : 0)' | command tr "$@"
    local ps=("${PIPESTATUS[@]}")
    [ "${ps[0]}" -eq 0 ] || return 1
    return "${ps[1]}"
  }
fi
pf=off; case ":$SHELLOPTS:" in *:pipefail:*) pf=on ;; esac
tf=0; LC_ALL=C tr -s '[:space:]' ' ' < "$r" >/dev/null 2>&1 || tf=$?
pre="$(printf '%s' "$(strip_to_itinerary_text "$r")" | LC_ALL=C sed "$_ITINERARY_WS_SED" | LC_ALL=C tr -s '[:space:]' ' ' | LC_ALL=C sed 's/^ *//; s/ *$//' | _digest_of)"
st="$(change_confirmation_state "$d")"
rc=0; ( require_change_confirmation "$d" ) >/dev/null 2>&1 || rc=$?
printf '%s %s %s %s %s' "${st:-empty}" "$rc" "$pf" "$tf" "${pre:-empty}"
FRESH
s15k_run() { # <real|emulated> <trip_dir> <render> -> "state gate-rc pipefail tr-status prefix-digest"
  ( cd "$ROOT" && LC_ALL=en_US.UTF-8 bash "$S15K_FRESH" "$1" "$2" "$3" 2>/dev/null )
}
s15k_trip() { # <name> <render> <baseline-digest> [<confirmation-digest>] -> the trip dir
  local d="$WORK/$1"
  mkdir -p "$d/outputs"
  cp "$2" "$d/$S15_RENDER"
  s_record "$d/.published-itinerary" "$3" published
  [ -z "${4:-}" ] || s_record "$d/.change-confirmed" "$4" confirmed
  printf '%s' "$d"
}
S15K_R0="$WORK/s15k_r0.html"; s_render "$S15K_R0" 14:00 none
S15K_R0DG="$(itinerary_digest "$S15K_R0")"
S15K_H1="$WORK/s15k_h1.html"; S15K_OK="$WORK/s15k_ok.html"
{ sed '/<script>/,$d' "$S15K_R0"; printf '<section class="day"><h2>%svora</h2><p>A day trip by train.</p></section>\n' $'\311'; sed -n '/<script>/,$p' "$S15K_R0"; } > "$S15K_H1"
{ sed '/<script>/,$d' "$S15K_R0"; printf '<section class="day"><h2>%svora</h2><p>A day trip by train.</p></section>\n' $'\303\211'; sed -n '/<script>/,$p' "$S15K_R0"; } > "$S15K_OK"
S15KN="$(s15k_trip s15kn "$S15K_H1" "$S_DA")"
S15KC="$(s15k_trip s15kc "$S15K_H1" "$S_DB" "$S_DA")"
S15KV="$(s15k_trip s15kv "$S15K_OK" "$S_DA")"
read -r S15K_EN_ST S15K_EN_RC S15K_EN_PF S15K_EN_TF S15K_EN_PRE <<<"$(s15k_run emulated "$S15KN" "$S15KN/$S15_RENDER")"
read -r S15K_EC_ST S15K_EC_RC S15K_EC_PF _ _ <<<"$(s15k_run emulated "$S15KC" "$S15KC/$S15_RENDER")"
read -r S15K_EV_ST S15K_EV_RC S15K_EV_PF S15K_EV_TF _ <<<"$(s15k_run emulated "$S15KV" "$S15KV/$S15_RENDER")"
S15K_PFS="$S15K_EN_PF$S15K_EC_PF$S15K_EV_PF"
if [ "$S15K_R0DG" != "$S_DA" ] || [ "$S15K_PFS" != "offoffoff" ] || [ "${S15K_EN_TF:-0}" = "0" ] || [ "$S15K_EV_TF" != "0" ] || [ "$S15K_EN_PRE" != "$S_DA" ]; then
  FAIL "S15k: fixture integrity — the render without the day digests '$S15K_R0DG' against the baseline $S_DA; pipefail in the fresh shells reads [$S15K_PFS] (want off in all three); the emulated stage returned ${S15K_EN_TF:-none} on the render (want non-zero) and ${S15K_EV_TF:-none} on the valid one (want 0); and the prefix digest is '$S15K_EN_PRE' (want the baseline). The fixture does not reproduce the fail-open's precondition, so no verdict below would be about the pin"
elif [ "$S15K_EV_ST" != "unconfirmed" ] || [ "$S15K_EV_RC" = "0" ]; then
  FAIL "S15k: CONTROL — the same day in valid UTF-8 resolved '$S15K_EV_ST' with gate rc=$S15K_EV_RC through the same fresh shell, not unconfirmed with a refusal. The harness is not reading an identifiable render as one, so an undetermined below would not be attributable to the failing stage"
elif [ "$S15K_EN_ST" = "undetermined" ] && [ "$S15K_EN_RC" != "0" ] && [ "$S15K_EC_ST" = "undetermined" ] && [ "$S15K_EC_RC" != "0" ]; then
  PASS "S15k: with pipefail OFF in a fresh shell that sourced the script, a day appended behind a byte that is not valid UTF-8, read by a normalization stage that fails there after writing the prefix before it, resolves undetermined on the none-pending route and on the confirmed route, and the gate refuses on both (rc $S15K_EN_RC / $S15K_EC_RC). The failing stage is emulated: under the pin no platform's tr stops on that byte. The prefix digest without pipefail equals the baseline, so this input publishes if the pin is removed; the pin is what holds it. Control: the valid-UTF-8 day resolves unconfirmed"
else
  FAIL "S15k: with pipefail OFF in a fresh shell, the render resolved emulated '$S15K_EN_ST' (gate rc $S15K_EN_RC) on the none-pending route and '$S15K_EC_ST' (gate rc $S15K_EC_RC) on the confirmed route. The digest's status read no longer carries its own pipefail: a stage that failed after writing a prefix digests as the truncated itinerary, which equals the baseline or the confirmation, and the gate proceeds with an unapproved change"
fi

# ── S15l — THE RECORDER'S TWO WARNINGS (#1184, the Stage 5 review's FM-1). After a push the
# recorder cannot refuse; it can only say which state an unidentifiable render leaves the
# trip in, and the two states are opposite. With a baseline recorded the gate keeps it and
# refuses the next update as `undetermined`; with none the gate has no anchor and is NOT
# ACTIVE. Swapping the two warnings tells a trip with no baseline that the gate still guards
# it, and silencing them tells nobody anything. Both were invisible to every arm above, which
# read the recorder only statically. So it runs on an unreadable render twice, once per
# state: each warning must appear on its own branch alone, no sidecar may be written or
# changed, and rc must be 0. The control is a readable render with no baseline, which must
# write the sidecar and warn nothing, so "nothing written" above is a measurement of a writer
# that can write.
S15LA="$(s15_dangling s15la)"
S15LB="$(s15_dangling s15lb)"
s_record "$S15LB/.published-itinerary" "$S_DA" published
cp "$S15LB/.published-itinerary" "$WORK/s15lb.before"
S15LC="$(s_fixture s15lc 14:00 none)"
S15L_BASEB="$(_record_digest "$S15LB/.published-itinerary")"
S15L_UNR=0; [ -L "$S15LA/$S15_RENDER" ] && [ ! -r "$S15LA/$S15_RENDER" ] && [ -L "$S15LB/$S15_RENDER" ] && [ ! -r "$S15LB/$S15_RENDER" ] && S15L_UNR=1
S15L_ERRA="$( ( record_published_itinerary "$S15LA" "$S15LA/$S15_RENDER" ) 2>&1 >/dev/null )"; S15L_RCA=$?
S15L_ERRB="$( ( record_published_itinerary "$S15LB" "$S15LB/$S15_RENDER" ) 2>&1 >/dev/null )"; S15L_RCB=$?
S15L_ERRC="$( ( record_published_itinerary "$S15LC" "$S15LC/$S15_RENDER" ) 2>&1 >/dev/null )"; S15L_RCC=$?
S15L_A=""; S15L_B=""; S15L_C=""
case "$S15L_ERRA" in *"NOT ACTIVE"*) S15L_A="${S15L_A}N" ;; esac
case "$S15L_ERRA" in *"keeps the baseline it already had"*) S15L_A="${S15L_A}K" ;; esac
case "$S15L_ERRB" in *"NOT ACTIVE"*) S15L_B="${S15L_B}N" ;; esac
case "$S15L_ERRB" in *"keeps the baseline it already had"*) S15L_B="${S15L_B}K" ;; esac
case "$S15L_ERRC" in *"NOT ACTIVE"*) S15L_C="${S15L_C}N" ;; esac
case "$S15L_ERRC" in *"keeps the baseline it already had"*) S15L_C="${S15L_C}K" ;; esac
S15L_SIDEA=0; [ -e "$S15LA/.published-itinerary" ] && S15L_SIDEA=1
S15L_SAMEB=0; cmp -s "$WORK/s15lb.before" "$S15LB/.published-itinerary" && S15L_SAMEB=1
S15L_RECC="$(_record_digest "$S15LC/.published-itinerary")"
if [ "$S15L_UNR" -ne 1 ] || [ "$S15L_BASEB" != "$S_DA" ]; then
  FAIL "S15l: fixture integrity — both renders unreadable symlinks=$S15L_UNR, and the recorded baseline reads '$S15L_BASEB' against $S_DA. The fixture is not the two states the recorder distinguishes, so the verdict would be about something else"
elif [ "$S15L_RCC" -ne 0 ] || [ "$S15L_RECC" != "$S_DA" ] || [ -n "$S15L_C" ]; then
  FAIL "S15l: CONTROL — on a readable render with no baseline the recorder returned rc=$S15L_RCC, wrote a sidecar reading '$S15L_RECC' (want $S_DA) and warned [$S15L_C] (want nothing). It cannot be shown to write, so the absence of a write below proves nothing"
elif [ "$S15L_RCA" -eq 0 ] && [ "$S15L_RCB" -eq 0 ] && [ "$S15L_A" = "N" ] && [ "$S15L_B" = "K" ] && [ "$S15L_SIDEA" -eq 0 ] && [ "$S15L_SAMEB" -eq 1 ]; then
  PASS "S15l: on an unreadable render the recorder warns NOT ACTIVE when no baseline is recorded and that the gate keeps the baseline it already had when one is, each on its own branch alone; it writes no sidecar on the first, leaves the recorded one byte-identical on the second, and returns 0 on both. The control, a readable render, writes the sidecar ($S15L_RECC) and warns nothing"
else
  FAIL "S15l: on an unreadable render the recorder warned [$S15L_A] with no baseline (want N, NOT ACTIVE) and [$S15L_B] with one (want K, keeps the baseline), returned rc $S15L_RCA / $S15L_RCB, wrote a sidecar with no baseline=$S15L_SIDEA and left the recorded one unchanged=$S15L_SAMEB. The warnings are swapped or silent, so a trip is told the gate guards it when it does not, or is told nothing"
fi
# ═════════════════════════════════════════════════════════════════════════════════
# Group T (#551 AC 5) — the coordination notice: its identity, its state vocabulary,
# and the null case.
#
# GROUP LETTER. `R` was taken by #550 (the change-summary content guard) and `S` by
# #552 (the organizer-confirm gate). `T` is the next free letter under the rule group
# S states — the monotonic sequence with `P` skipped for its prefix collision with the
# existing two-letter group `PF`. Every assertion id in this file was censused before
# the letter was chosen; `T` appeared in none of them.
#
# WHY THIS GROUP IS HERE AND NOT IN THE ARTIFACT-SCHEMA SUITE. Three of its four arms
# run the SHIPPED publish-script projections — strip_to_itinerary_text, strip_to_text
# and itinerary_digest — which are in scope only because this suite sources
# publish-trip-site.sh. And the coupling it holds fails HERE when it breaks: a drifted
# class token is a marker-only republish that ABORTS.
#
#   T1  the band the SPEC declares is the band the SCRIPT excises   (the coupling)
#   T2  the component's variants and the schema's enum agree        (spec <-> schema)
#   T3  absent a pending change, the render emits nothing           (AC 5, the render)
#   T4  absent a pending change, the publish path is what it was    (AC 5, the digest)
#   T5  coordination-since is anchored to the confirmation, not the run   (AC 2)
#
# T1 IS THE ARM THAT HOLDS THE ONE THING #552 ASKED #551 TO HOLD, AND IT IS NOT S7a.
# publish-trip-site.sh binds the notice's identity at the line marked SEAM S4, and the
# consequence of drift is stated there in terms: change that line in the same commit or
# every marker-only republish aborts. S7a already proves a marker-only republish
# passes — but its fixture spells the class token literally, so it would stay GREEN
# through a spec that had renamed the band. T1 builds its band from the token the SPEC
# DOCUMENT declares and asserts the shipped projection actually excises THAT. It is
# behavioural rather than a string comparison, because two strings can be equal and
# both wrong; a projection either excises the band or it does not.
#
# STATED BOUND, because it is the honest limit of every arm below. There is no site
# BUILD in this repository — the render is authored by the `site` verb in
# skills/trip/SKILL.md, from a spec. So T3 grades a render built TO the contract,
# not a build script's output: what it proves is that the contract's null case,
# followed, emits nothing and disturbs nothing. That a given run followed it is not
# something any test here reaches, and no arm below claims it.
#
# Every arm is offline: two tracked files, three sourced shell functions, no network,
# no gh, no Node, no TTY. This group has no legitimate skip and is deliberately NOT
# declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "Coordination notice — identity, vocabulary, and the null case (#551 AC 5):"

T_SPEC="$HERE/../reference/site-layout-spec.md"
T_SCHEMA="$HERE/../reference/schemas/travel-site.md"
T_DIR="$WORK/t551"; mkdir -p "$T_DIR"

# The class token the COMPONENT CONTRACT declares, read from the document rather than
# spelled here. A literal in this file would be a second home for the notice's identity
# and would make T1 unable to see the drift it exists to see.
t_spec_class() { # [<spec-file>]
  awk '/^### Coordination Notice/ {
         if (match($0, /`\.[a-z][-a-z0-9]*`/)) print substr($0, RSTART + 2, RLENGTH - 3)
         exit
       }' "${1:-$T_SPEC}"
}

# The variant suffixes the contract declares, bound to the class token so a variant
# hung off some OTHER class is not silently counted as one of this component's.
t_spec_variants() { # <class-token> [<spec-file>]
  awk -v c="$1" '
    /^- Two variants:/ {
      s = $0
      while (match(s, "`\\." c "\\.is-[a-z][-a-z0-9]*`")) {
        tok = substr(s, RSTART, RLENGTH)
        sub(/.*\.is-/, "", tok); sub(/`$/, "", tok)
        print tok
        s = substr(s, RSTART + RLENGTH)
      }
    }' "${2:-$T_SPEC}" | sort -u
}

# coordination-state's enum members, from C19's schema fence and nowhere else.
t_schema_enum() { # [<schema-file>]
  awk -F'[][]' '/^field coordination-state:/ { print $2; exit }' "${1:-$T_SCHEMA}" | tr '|' '\n' | sort -u
}

# Occurrence counter. Pure bash: no pipeline, so nothing here can be decided by an
# exit status under pipefail (group PF's rule), and no external process to be missing.
t_count() { # <needle> <file> -> occurrences on stdout
  local n=0 s
  s="$(cat "$2")"
  while [ -n "$s" ]; do
    case "$s" in
      *"$1"*) s="${s#*"$1"}"; n=$((n+1)) ;;
      *)      break ;;
    esac
  done
  printf '%d' "$n"
}

# The page in two forms, produced by DIFFERENT code on purpose. t_page_pre is the
# render as it stood BEFORE this card: no coordination construct of any kind. t_page is
# the render built to the component contract, parameterised by state. Under the
# contract's null case the two must be the same BYTES — an assertion worth making only
# because an emitter that leaked an empty container, or a CSS rule, on `none` would
# come out of the second function and not the first.
t_page_pre() { # <file>
  cat > "$1" <<'HTML'
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at 16:30. Then the riverside walk to the bridge.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
}

t_page() { # <file> <none|pending|updated> [<class-token>]
  local f="$1" st="$2" cls="${3:-$T_CLASS}" band="" rule=""
  # The contract: rendered ONLY when coordination-state is `pending` or `updated`;
  # absent or `none` emits no node AND no CSS rule.
  if [ "$st" != "none" ]; then
    band="<div class=\"${cls} is-${st}\"><span>A change is ${st}</span> <time>2027-06-02</time></div>
"
    rule=".${cls}{background:#eee}"
  fi
  cat > "$f" <<HTML
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>${rule}.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
${band}<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at 16:30. Then the riverside walk to the bridge.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
}

T_CLASS="$(t_spec_class)"

# ── T1 — THE COUPLING. The band the component contract declares is the band the
# shipped projection excises. Behavioural: build one from the DOCUMENT's token, one
# from a token the script cannot know, and read the digests.
t_page "$T_DIR/none.html"    none    "$T_CLASS"
t_page "$T_DIR/spec.html"    pending "$T_CLASS"
t_page "$T_DIR/fake.html"    pending "zzq-not-a-notice"
T_D_NONE="$(itinerary_digest "$T_DIR/none.html")"
T_D_SPEC="$(itinerary_digest "$T_DIR/spec.html")"
T_D_FAKE="$(itinerary_digest "$T_DIR/fake.html")"
if [ -z "$T_CLASS" ] || [ ! -r "$T_SPEC" ]; then
  FAIL "T1: no class token could be read from $T_SPEC — the component contract has moved or been renamed, and every verdict below would be over an empty token rather than a measurement"
elif [ -z "$T_D_NONE" ]; then
  FAIL "T1: itinerary_digest returned nothing for the null-case render — the projection is not readable here and no equality below would mean anything"
elif [ "$T_D_FAKE" = "$T_D_NONE" ]; then
  FAIL "T1: a band carrying the fabricated class 'zzq-not-a-notice' was excised too ($T_D_FAKE), so this probe cannot tell an excision from a projection that drops everything — the subject equality would prove nothing"
elif [ "$T_D_SPEC" = "$T_D_NONE" ]; then
  PASS "T1: the band built from the class token '$T_CLASS' READ FROM $(basename "$T_SPEC") is excised by the shipped projection — marked and unmarked renders share one itinerary digest ($T_D_NONE), while the fabricated-class band is NOT excised ($T_D_FAKE != $T_D_NONE), so the equality is a measurement. This is the SEAM S4 agreement, and unlike S7a's literal fixture it fails when the document renames the band"
else
  FAIL "T1: the component contract declares '.$T_CLASS' but the shipped projection does not excise it — marked $T_D_SPEC vs unmarked $T_D_NONE. SEAM S4 in publish-trip-site.sh binds a different token, and EVERY marker-only republish will abort until the two agree"
fi

# ── T2 — SPEC <-> SCHEMA. The component's two variants are exactly the schema enum's
# two non-`none` members. Set-diffed in BOTH directions, because a one-way containment
# check stays green on a schema that has quietly grown a fourth state nothing renders.
#
# THE CONTROL ARM IS A RUNTIME MUTATION, NOT A FABRICATED-TOKEN LOOKUP. Asking whether
# an invented token appears in the extracted sets is a question whose answer is `no`
# whether the extractors work or not — it would pass over two empty sets just as
# happily. So both extractors are re-run against copies of their own source documents
# with a token INJECTED, and each must come back carrying it. An extractor whose regex
# has stopped matching the document returns the same set from the mutated copy, and
# this arm is what notices. Same technique as UF-CTL2 in the artifact-schema suite.
T_VARIANTS="$(t_spec_variants "$T_CLASS")"
T_ENUM_ALL="$(t_schema_enum)"
printf '%s\n' "$T_VARIANTS"  | awk 'NF' | sort -u > "$T_DIR/var.txt"
printf '%s\n' "$T_ENUM_ALL"  | awk 'NF && $0 != "none"' | sort -u > "$T_DIR/enum_active.txt"
T_NVAR="$(awk 'END { print NR }' "$T_DIR/var.txt")"
T_NENUM="$(printf '%s\n' "$T_ENUM_ALL" | awk 'NF' | wc -l | tr -d ' ')"
comm -23 "$T_DIR/var.txt" "$T_DIR/enum_active.txt" > "$T_DIR/only_spec.txt"
comm -13 "$T_DIR/var.txt" "$T_DIR/enum_active.txt" > "$T_DIR/only_schema.txt"

# CONTROL: inject a variant into the contract and a member into the schema, then re-run
# the SAME extractors over the mutated copies. Both must pick the injection up.
T_SPEC_MUT="$T_DIR/spec_mut.md"; T_SCHEMA_MUT="$T_DIR/schema_mut.md"
awk -v c="$T_CLASS" '
  /^- Two variants:/ { printf "%s and `.%s.is-zzqfab`\n", $0, c; next }
  { print }' "$T_SPEC" > "$T_SPEC_MUT"
awk '/^field coordination-state:/ { sub(/\]$/, "|zzqfab]"); print; next } { print }' "$T_SCHEMA" > "$T_SCHEMA_MUT"
T_CTL_VAR="$(t_spec_variants "$T_CLASS" "$T_SPEC_MUT")"
T_CTL_ENUM="$(t_schema_enum "$T_SCHEMA_MUT")"
T_CTL_VAR_HIT=0; T_CTL_ENUM_HIT=0
case " $(printf '%s ' $T_CTL_VAR) "  in *' zzqfab '*) T_CTL_VAR_HIT=1 ;;  esac
case " $(printf '%s ' $T_CTL_ENUM) " in *' zzqfab '*) T_CTL_ENUM_HIT=1 ;; esac

if [ "$T_NVAR" -eq 0 ] || [ "$T_NENUM" -eq 0 ]; then
  FAIL "T2: extracted $T_NVAR variant(s) from the component contract and $T_NENUM enum member(s) from C19's schema — one side is empty, so the set difference below would be vacuously clean"
elif [ "$T_CTL_VAR_HIT" -ne 1 ] || [ "$T_CTL_ENUM_HIT" -ne 1 ]; then
  FAIL "T2-CTL: an injected token was NOT recovered (variant arm=$T_CTL_VAR_HIT, enum arm=$T_CTL_ENUM_HIT of 1 each) — at least one extractor has stopped reading its document, so the agreement below would be between two sets this file computed rather than two the corpus declares"
elif [ -s "$T_DIR/only_spec.txt" ] || [ -s "$T_DIR/only_schema.txt" ]; then
  FAIL "T2: the component's variants and coordination-state's enum disagree — only in the contract: [$(tr '\n' ' ' < "$T_DIR/only_spec.txt")]; only in the schema: [$(tr '\n' ' ' < "$T_DIR/only_schema.txt")]. A state the schema admits and the contract cannot render is a render with nowhere to put it; a variant the schema cannot express is a class that never validates"
else
  PASS "T2: the component's $T_NVAR variant(s) [$(tr '\n' ' ' < "$T_DIR/var.txt")] are exactly coordination-state's $T_NENUM-member enum less \`none\` — set-diffed in both directions, 0 either way. Both extractors recovered a token injected into a copy of their own source document, so each set is read from the corpus rather than assumed"
fi

# ── T3 — AC 5, AT THE RENDER. Absent a pending change or a recent update, the site
# renders exactly as it does today: no node, no CSS rule, no script branch. Asserted as
# BYTE IDENTITY against a render authored before this component existed, because on a
# file encrypted wholesale a hidden-but-present element is still a publish diff.
t_page_pre "$T_DIR/pre.html"
T_N_CLASS_NULL="$(t_count "$T_CLASS" "$T_DIR/none.html")"
T_N_CLASS_MARK="$(t_count "$T_CLASS" "$T_DIR/spec.html")"
T_N_VAR_NULL=0
for t_v in $T_VARIANTS; do
  T_N_VAR_NULL=$(( T_N_VAR_NULL + $(t_count "is-$t_v" "$T_DIR/none.html") ))
done
T_N_VAR_MARK="$(t_count "is-pending" "$T_DIR/spec.html")"
if [ "$T_N_CLASS_MARK" -eq 0 ] || [ "$T_N_VAR_MARK" -eq 0 ]; then
  FAIL "T3: the sensitivity arm did not fire — the MARKED render carries $T_N_CLASS_MARK occurrence(s) of '$T_CLASS' and $T_N_VAR_MARK of 'is-pending', so a zero on the null render would mean the counter is blind rather than that nothing was emitted"
elif ! cmp -s "$T_DIR/none.html" "$T_DIR/pre.html"; then
  FAIL "T3: the null-case render is NOT byte-identical to a render authored before this component existed — $(wc -c < "$T_DIR/none.html" | tr -d ' ')B vs $(wc -c < "$T_DIR/pre.html" | tr -d ' ')B. AC 5 is a byte claim on an artifact encrypted wholesale: anything emitted here is a publish diff on a trip with no coordination activity at all"
elif [ "$T_N_CLASS_NULL" -ne 0 ] || [ "$T_N_VAR_NULL" -ne 0 ]; then
  FAIL "T3: the null-case render carries $T_N_CLASS_NULL occurrence(s) of '$T_CLASS' and $T_N_VAR_NULL variant token(s) — non-emission means no node AND no CSS rule, not display:none and not an empty container"
else
  PASS "T3: the null-case render is byte-identical to a pre-component render and carries 0 occurrences of '$T_CLASS' and 0 of its $T_NVAR variant token(s); the sensitivity arm found $T_N_CLASS_MARK and $T_N_VAR_MARK of them in the marked render built by the same function, so both zeros are measurements"
fi

# ── T4 — AC 5, AT THE PUBLISH PATH. With nothing emitted there is nothing to excise,
# so #552's itinerary projection must be byte-for-byte the projection that shipped
# before it. This is the half of AC 5 that lives in the guard rather than on the page,
# and it is what makes "renders exactly as it does today" true of the pushed bytes too.
#
# SCOPE, NARROWED BY THE THIRD REMEDIATION — READ THIS BEFORE RE-POINTING THE FIXTURE.
# The identity is claimed on input carrying NO HTML COMMENT, which is what this group's
# fixtures build. It is not claimed in general, and it must not be: strip_to_itinerary_text
# now excises the comment construct and strip_to_text — byte-frozen, on
# verify_ciphertext's path — does not, so on a comment-bearing render the two projections
# are REQUIRED to differ. S12d owns that difference and asserts both directions in one arm.
#
# THE SCOPE IS CHECKED RATHER THAN DESCRIBED. If these fixtures ever grow a declaration
# block, the first branch below says which assumption moved instead of leaving a reader to
# reconstruct it from a byte-count mismatch.
T4_HAS_COMMENT=0
case "$(cat "$T_DIR/none.html")" in *'<!--'*) T4_HAS_COMMENT=1 ;; esac
strip_to_itinerary_text "$T_DIR/none.html" > "$T_DIR/proj_new_null.txt"
strip_to_text            "$T_DIR/none.html" > "$T_DIR/proj_old_null.txt"
strip_to_itinerary_text "$T_DIR/spec.html" > "$T_DIR/proj_new_mark.txt"
strip_to_text            "$T_DIR/spec.html" > "$T_DIR/proj_old_mark.txt"
if [ "$T4_HAS_COMMENT" -ne 0 ]; then
  FAIL "T4: the null-case fixture now carries an HTML comment, and the identity this arm asserts does not hold on that input by design — strip_to_itinerary_text excises the comment construct and strip_to_text does not. Re-point this arm at a comment-free render, or retire it in favour of S12d, which asserts the identity and the difference together"
elif [ ! -s "$T_DIR/proj_old_null.txt" ]; then
  FAIL "T4: strip_to_text produced nothing for the null-case render, so the identity below would be an equality between two empty files"
elif cmp -s "$T_DIR/proj_new_mark.txt" "$T_DIR/proj_old_mark.txt"; then
  FAIL "T4: the two projections agree on a MARKED render as well, so this comparator cannot tell them apart and its agreement on the null render proves nothing about non-emission"
elif cmp -s "$T_DIR/proj_new_null.txt" "$T_DIR/proj_old_null.txt"; then
  PASS "T4: on the null-case render — which carries no HTML comment, checked above — the itinerary projection is byte-identical to strip_to_text ($(wc -c < "$T_DIR/proj_old_null.txt" | tr -d ' ')B), so absent a pending change the publish path is exactly what it was before this milestone. The control arm confirms the two projections DIFFER on a marked render, so the identity is a measurement. On comment-BEARING input they are required to differ instead; that is S12d"
else
  FAIL "T4: the itinerary projection and strip_to_text disagree on a render with NO coordination band — $(wc -c < "$T_DIR/proj_new_null.txt" | tr -d ' ')B vs $(wc -c < "$T_DIR/proj_old_null.txt" | tr -d ' ')B. Something in the excision is firing with no band present, and every trip with no coordination activity would republish differently than it does today"
fi

# ── T5 — THE ANCHOR. `coordination-since` for the `updated` state must not move when the
# underlying confirmation has not. A rule that anchors `updated` to the run re-derives a fresh
# date on EVERY later rebuild, the seven-day decay window § 3 evaluates at open restarts each
# time, and a trip rebuilt months later still announces itself as recently updated. That is
# precisely the failure C19's schema says this field exists to prevent, one state over from the
# presence-keying the design already rejected for `pending` — and one state short of the
# `status`-keying T6 replaces, which is the same argument run to its end.
#
# THE RULE IS READ FROM THE DOCUMENT, NOT SPELLED HERE — the same reason T1 reads the
# class token from the component contract rather than holding a literal.
# reference/site-layout-spec.md § 3 says in terms that it keeps no second copy of where
# the state comes from and names the `site` verb in skills/trip/SKILL.md as the one
# home. A literal here would be that second copy, and it would leave this arm green
# through a document that had moved the anchor back to the build.
#
# WHAT IS EXTRACTED, and the pairing rule. From the `confirmed` -> `updated` limb of that
# mapping: the first backticked FIELD token (the `name=` shape) and the first backticked
# PATH token that FOLLOWS it. A limb naming neither has no artifact-side source at all —
# it can only be anchored to the run, and the resolver below then has nothing to return
# but the build's own date, which is what the subject comparison sees.
#
# STATED BOUND, the same one T3 carries: there is no site BUILD in this repository. T5
# grades the CONTRACT's anchor and a resolution built to it — not a build script's output,
# and it does not claim that a given run followed the contract.
T_TRIPMD="$HERE/../skills/trip/SKILL.md"
# RECONCILED with the mapping this remediation replaced (D11). The limb is no longer keyed
# to a `status` VALUE, so `\`confirmed\` → \`updated\`` is not the marker any more and
# `\`rejected\`` is not a limb at all: the arrow into `updated` is what locates it, and the
# `none` limb that follows is what bounds it. Markers are LOCATORS pointing at the document,
# never a copy of the rule — the rule itself is still read out of what they bracket.
# THE MUTATION INJECTOR, shared by T5's control and T6a's. Paragraph-scoped and
# newline-normalising, so it injects after a marker the document has WRAPPED across two
# lines exactly as it does after one held on a single line. The line-based form this
# replaces was silently layout-dependent: a reflow of the mapping moved the marker across a
# line break, the injection then landed nowhere, and the control failed for a reason that
# had nothing to do with the extractor it exists to grade. Only the FIRST matching paragraph
# is normalised, and the extractors it feeds normalise newlines themselves, so nothing about
# the copy's line layout reaches a verdict.
t_inject_after_mark() { # <file> <mark> <injection> -> mutated document on stdout
  awk -v mark="$2" -v inj="$3" '
    BEGIN { RS = ""; ORS = "\n\n" }
    {
      p = $0
      if (!done) {
        gsub(/\n/, " ", p)
        a = index(p, mark)
        if (a > 0) { p = substr(p, 1, a + length(mark) - 1) inj substr(p, a + length(mark)); done = 1 }
        else p = $0
      }
      print p
    }' "$1"
}

T5_MARK='→ `updated`'
T5_STOP='`none`'

# The `confirmed` -> `updated` limb, as one line. Paragraph-scoped (RS="") so a marker
# elsewhere in a 1000-line command file cannot be mistaken for this one.
t5_limb() { # <trip-md> -> the limb text on stdout
  awk -v mark="$T5_MARK" -v stop="$T5_STOP" '
    BEGIN { RS = ""; FS = "\n" }
    {
      p = $0
      gsub(/\n/, " ", p)
      a = index(p, mark)
      if (a == 0) next
      p = substr(p, a + length(mark))
      b = index(p, stop)
      if (b > 0) p = substr(p, 1, b - 1)
      print p
      exit
    }' "$1"
}

# Every backticked token of a file, one per line, in document order.
t5_tokens() { # <file>
  awk '{
    s = $0
    while ((a = index(s, "`")) > 0) {
      s = substr(s, a + 1)
      b = index(s, "`")
      if (b == 0) break
      print substr(s, 1, b - 1)
      s = substr(s, b + 1)
    }
  }' "$1"
}

# The pair, read in two passes rather than one space-joined line: splitting a joined pair
# is shell-dependent and buys nothing here.
t5_field() { awk '$0 ~ /^[a-z][a-z0-9-]*=$/ && f == "" { f = $0 } END { print f }' "$1"; }
t5_path()  { awk '$0 ~ /^[a-z][a-z0-9-]*=$/ && f == "" { f = $0; next }
                  f != "" && p == "" && $0 ~ /\// && $0 ~ /\./ { p = $0 }
                  END { print p }' "$1"; }

# coordination-since for `updated`, resolved exactly as the document declares it. Where
# the limb names a record and a field, the value is that record's, and the build date
# passed in is unused — which is the whole property. Where the limb names neither, the
# rule is anchored to the run and the build's own date is all there is to return, so the
# build date is a real limb of this function rather than a decoration.
t5_since() { # <trip_dir> <build_date> <field-token> <path-token>
  local dir="$1" build="$2" field="$3" path="$4" rel line v
  if [ -z "$field" ] || [ -z "$path" ]; then printf '%s' "$build"; return 0; fi
  rel="$path"
  case "$rel" in
    trips/*/*) rel="${rel#trips/}"; rel="${rel#*/}" ;;
  esac
  [ -r "$dir/$rel" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$field"*) v="${line#"$field"}"; printf '%s' "${v:0:10}"; return 0 ;;
    esac
  done < "$dir/$rel"
  return 0
}

# Two trips differing in ONE thing: the date on the organizer's recorded approval. Both take
# the `updated` limb, and under the mapping this remediation replaced they could only take it
# through a MANUFACTURED `status: confirmed` — a value no shipped surface writes, which was the
# tell that the state was keyed on a phantom source. The summaries below carry
# `status: pending`, the only value anything in this repository produces, and both trips still
# resolve `updated` because their recorded approval post-dates every entry. The fixture is
# therefore conformant with what the corpus can actually emit, and it doubles as a specificity
# arm for D11: an implementation still reading `status` resolves `pending` on both.
T5_CONF_A='2027-06-01T09:14:22Z'
T5_CONF_B='2027-08-15T11:02:47Z'
T5_BUILD_1='2027-06-02'
T5_BUILD_2='2027-11-20'
T5_EXPECT_A="${T5_CONF_A:0:10}"
T5_EXPECT_B="${T5_CONF_B:0:10}"

t5_trip() { # <dir> <confirmed-iso>
  mkdir -p "$1/outputs"
  printf 'digest=4294967295-1234\nconfirmed=%s\n' "$2" > "$1/.change-confirmed"
  {
    printf -- '---\nartifact: outputs/change-summary.md\nschema-version: 1\ntrip: t5-fixture\n'
    printf -- 'writer: hub\nlifecycle: accumulate-append\nprovenance: derived\n'
    printf -- 'publish: internal\ngenerated: %s\nstatus: pending\n---\n\n' "${2:0:10}"
    printf -- '## 2027-05-28 — first synthesis\n\n## 2027-05-30 — proposed change\n'
  } > "$1/outputs/change-summary.md"
}
t5_trip "$T_DIR/tripA" "$T5_CONF_A"
t5_trip "$T_DIR/tripB" "$T5_CONF_B"

t5_limb   "$T_TRIPMD"            > "$T_DIR/limb.txt"
t5_tokens "$T_DIR/limb.txt"      > "$T_DIR/limb_tok.txt"
T5_FIELD="$(t5_field "$T_DIR/limb_tok.txt")"
T5_PATH="$(t5_path   "$T_DIR/limb_tok.txt")"

# CONTROL — the extractor must be reading the DOCUMENT. A fabricated (field, path) pair is
# injected into a copy of trip.md immediately after the limb marker, and the same three
# steps are re-run over the copy; both halves must come back carrying the injection.
# Asking instead whether an invented token appears in the REAL extraction is a question
# whose answer is `no` whether the extractor works or not — it would answer the same over
# an empty file. Same technique as T2's mutation control and UF-CTL2's in the schema suite.
t_inject_after_mark "$T_TRIPMD" "$T5_MARK" ' the `zzqfab=` line of `zzq/fab/.zzq-record` and' \
  > "$T_DIR/tripmd_mut.md"
t5_limb   "$T_DIR/tripmd_mut.md"  > "$T_DIR/limb_mut.txt"
t5_tokens "$T_DIR/limb_mut.txt"   > "$T_DIR/limb_mut_tok.txt"
T5_CTL_FIELD="$(t5_field "$T_DIR/limb_mut_tok.txt")"
T5_CTL_PATH="$(t5_path   "$T_DIR/limb_mut_tok.txt")"

# The subject: ONE trip, ONE unchanged confirmation, TWO builds months apart.
T5_A1="$(t5_since "$T_DIR/tripA" "$T5_BUILD_1" "$T5_FIELD" "$T5_PATH")"
T5_A2="$(t5_since "$T_DIR/tripA" "$T5_BUILD_2" "$T5_FIELD" "$T5_PATH")"
T5_B1="$(t5_since "$T_DIR/tripB" "$T5_BUILD_1" "$T5_FIELD" "$T5_PATH")"

if [ "$T5_BUILD_1" = "$T5_BUILD_2" ] || [ "$T5_CONF_A" = "$T5_CONF_B" ]; then
  FAIL "T5: fixture integrity — the two build dates ($T5_BUILD_1, $T5_BUILD_2) or the two recorded confirmations ($T5_CONF_A, $T5_CONF_B) are equal, so neither the invariance nor the sensitivity below could fail"
elif [ "$T5_CTL_FIELD" != 'zzqfab=' ] || [ "$T5_CTL_PATH" != 'zzq/fab/.zzq-record' ]; then
  FAIL "T5-CTL: a (field, path) pair injected into a copy of $(basename "$T_TRIPMD") was NOT recovered (field='$T5_CTL_FIELD', path='$T5_CTL_PATH', both expected) — the extractor has stopped reading the mapping, so whatever it reports about the real document is this file's own answer rather than the document's"
elif [ "$T5_A1" != "$T5_A2" ]; then
  FAIL "T5: coordination-since MOVED with the build on an UNCHANGED confirmation — '$T5_A1' at build $T5_BUILD_1 against '$T5_A2' at build $T5_BUILD_2, over one trip whose recorded approval did not move. The limb yielded field='$T5_FIELD' path='$T5_PATH'; empty means it names no artifact-side source and is anchored to the RUN, so every rebuild re-stamps the date and § 3's seven-day window restarts instead of decaying from the confirmation. Limb read: [$(cat "$T_DIR/limb.txt")]"
elif [ -z "$T5_A1" ]; then
  FAIL "T5: the source the limb names (field='$T5_FIELD' path='$T5_PATH') resolved to NOTHING on a fixture that carries it, so the equality above is between two empty strings rather than between two dates"
elif [ "$T5_A1" = "$T5_BUILD_1" ] || [ "$T5_A1" = "$T5_BUILD_2" ]; then
  FAIL "T5: coordination-since resolved to a BUILD date ('$T5_A1') rather than to the confirmation's own — the two builds happen to agree, but the value is still the run's"
elif [ "$T5_A1" != "$T5_EXPECT_A" ]; then
  FAIL "T5: coordination-since resolved '$T5_A1' where the trip's recorded confirmation is $T5_CONF_A — the anchor is neither the build nor the confirmation, and the decay window would start from a third date"
elif [ "$T5_B1" != "$T5_EXPECT_B" ]; then
  FAIL "T5-CTL: the second trip's recorded confirmation is $T5_CONF_B but coordination-since resolved '$T5_B1' — the resolver is not reading the record it was pointed at, so the agreement above is a constant this file produced rather than a measurement of the document's anchor"
else
  PASS "T5: coordination-since for \`updated\` is anchored to the confirmation, not to the run — one trip whose recorded approval did not move resolved '$T5_A1' at build $T5_BUILD_1 AND at build $T5_BUILD_2, months apart, so § 3's seven-day window decays from the confirmation instead of restarting on every rebuild. The value is neither build date and equals the trip's own recorded confirmation ($T5_CONF_A); the second fixture, differing only in that record, resolved '$T5_B1' — so the invariance is a measurement and not a constant. The (field, path) pair '$T5_FIELD' / '$T5_PATH' was read from $(basename "$T_TRIPMD"), and an injected pair was recovered from a mutated copy, so the anchor is the document's rather than this file's"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group T, second remediation (#551, operator decision D11) — the record the STATE is
# derived from, and the residual a state transition rides through.
#
# WHAT T1-T5 LEFT UNGRADED. T1-T4 grade the BAND: its identity, its state vocabulary and
# the null case. T5 grades the DATE the band carries, and the first remediation moved that
# date's anchor onto `trips/<slug>/.change-confirmed`. Nothing graded where the STATE
# itself comes from, and it was still keyed on C20's artifact-level `status`.
#
# WHY THAT IS A DEFECT AND NOT A PREFERENCE. `cmd_confirm` records the organizer's decision
# by writing `digest=` and `confirmed=` to `trips/<slug>/.change-confirmed`, and it writes
# nothing else — in particular it does not promote `outputs/change-summary.md`'s `status`,
# and no other shipped surface promotes it either. On a mapping keyed to that field
# `confirmed` is a value nothing can produce: `updated` is structurally unreachable,
# `coordination-state` can only ever be `pending` or `none`, and because § 3 gives the
# seven-day decay window to `is-updated` ALONE the pending band then LATCHES. A traveller
# opens the site after the organizer confirmed and the plan republished and still reads
# "change pending", indefinitely. That is a persistent wrong statement to the reader, which
# is the behaviour this milestone exists to remove.
#
# THE TELL, and it is why T5's fixture is reconciled in the same change: T5 had to
# MANUFACTURE `status: confirmed` to reach the `updated` limb at all, because no shipped
# surface can produce it. A fixture that has to invent its subject's precondition is a
# fixture asserting against a source the implementation cannot reach.
#
#   T6a  the STATE's record is the DATE's record             (one event, one record)
#   T6b  and it is the record a shipped surface WRITES       (reachability at the source)
#   T6c  that shipped write MOVES the state                  (the latch, removed)
#   T6d  CONTROL — a later entry re-opens `pending`          (the resolver is not a constant)
#   T6e  the null case, the no-approval case, the placeholder case
#   T7a  the band is outside the digest on a CONFORMANT render      (SEAM-2, the subject)
#   T7b  CONTROL — a plan edit under the same fixture moves it      (discrimination)
#   T7c  the residual: C19's own declaration block is INSIDE it     (SEAM-2, re-priced)
#
# HOW THE RULE IS READ. From the document, as in T5, and for the same reason:
# reference/site-layout-spec.md § 3 says in terms that it holds no second copy of where the
# state comes from and names the `site` verb in skills/trip/SKILL.md as the one home. So
# the record is EXTRACTED — the first trip-relative path token after that mapping's own
# "decides it from" clause — and the resolver below is generic over whatever the extraction
# yields. What is held here is the rule's SHAPE; its SOURCE is the document's. A document
# pointing the state at an artifact that carries no `confirmed=` line resolves every entry
# undecided, which is the latch, which is what T6c measures.
#
# STATED BOUND, the same one T3 and T5 carry: there is no site BUILD in this repository. The
# render is authored by the `site` verb from a spec, so these arms grade the CONTRACT's
# derivation and a resolution built to it — not a build script's output, and no arm here
# claims that a given run followed the contract.
#
# Every arm is offline: three tracked documents, four sourced shell functions, fixture trip
# dirs under the suite's own temp dir, awk and bash. No network, no gh, no Node, no TTY, and
# no `bash -n` of anything. This group has no legitimate skip and is deliberately NOT
# declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "Coordination state — its record, its reachability, and the digest residual (#551 AC 2 / AC 5):"

T6_DIR="$WORK/t551b"; mkdir -p "$T6_DIR"

# The record the mapping decides the STATE from. The locator is the mapping's own
# "decides it from" clause; what is taken from it is the first backticked token carrying a
# path separator. Paragraph-scoped (RS="") for the reason T5's extractor is: a phrase
# elsewhere in a 1000-line command file must not be mistaken for this one.
T6_MARK='decides it from'
t6_state_record() { # <trip-md> -> the record path the mapping names, or nothing
  awk -v mark="$T6_MARK" '
    BEGIN { RS = ""; FS = "\n" }
    {
      p = $0
      gsub(/\n/, " ", p)
      a = index(p, mark)
      if (a == 0) next
      p = substr(p, a + length(mark))
      while ((i = index(p, "`")) > 0) {
        p = substr(p, i + 1)
        j = index(p, "`")
        if (j == 0) break
        tok = substr(p, 1, j - 1)
        p = substr(p, j + 1)
        if (index(tok, "/") > 0) { print tok; exit }
      }
      exit
    }' "$1"
}

# A declared trip-relative path, reduced to its form inside a trip dir — the same reduction
# t5_since performs inline, factored out here because three call sites below need it.
t6_rel() { # <declared-path> -> trip-relative path
  local rel="$1"
  case "$rel" in trips/*/*) rel="${rel#trips/}"; rel="${rel#*/}" ;; esac
  printf '%s' "$rel"
}

# The newest dated entry of a change summary. C20 is not in § 4.5's entry-bearing set, so
# its entries carry no key marker and a dated heading is what there is to read.
t6_newest_entry() { # <change-summary.md> -> newest YYYY-MM-DD, or nothing
  [ -r "${1:-}" ] || return 0
  awk '/^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
         d = substr($2, 1, 10); if (d > m) m = d }
       END { if (m != "") print m }' "$1"
}

# coordination-state, resolved from the record the DOCUMENT names, and generic over it.
# THREE lines of that record are read: `digest=` decides whether the record counts as an
# approval at all — through the shipped parser, so a record present but saying nothing is not
# one (ADR-007 § 2's placeholder bound, the property S5 grades on the gate's side of the same
# file) — `confirmed=` supplies the moment every entry is measured against, and
# `approval-count=` decides the no-entry limb. With no entry, the mapping reads `none` unless the
# record carries an approval count — a line only the declared path writes — and then the record
# is itself the decided event and the state is `updated` (#719's Stage 7 F-01, decided option i);
# a record without that line, the organizer's two-line confirmation, still reads `none` exactly as
# before. S21l builds a render through this function and pushes it.
t6_state() { # <trip_dir> <state-record-path> -> none|pending|updated
  local dir="$1" rel line c="" e="" n=""
  rel="$(t6_rel "$2")"
  e="$(t6_newest_entry "$dir/outputs/change-summary.md")"
  if [ -n "$(_record_digest "$dir/$rel")" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        confirmed=*)      if [ -z "$c" ]; then c="${line#confirmed=}"; c="${c:0:10}"; fi ;;
        approval-count=*) if [ -z "$n" ]; then n="${line#approval-count=}"; fi ;;
      esac
    done < "$dir/$rel"
  fi
  if [ -z "$e" ]; then
    case "$n" in ''|*[!0123456789]*) printf 'none'; return 0 ;; esac
    if [ -z "$c" ]; then printf 'none'; return 0; fi
    printf 'updated'; return 0
  fi
  if [ -z "$c" ]; then printf 'pending'; return 0; fi
  if [[ "$e" > "$c" ]]; then printf 'pending'; return 0; fi
  printf 'updated'
}

# The bytes the SHIPPED confirm subcommand records with, read out of the script rather than
# invented here. A record this file made up would demonstrate the document self-consistent
# and nothing at all about whether any shipped surface can produce the state — which is the
# whole subject of T6b and T6c. `\047` is awk's single quote; spelling it that way keeps the
# extractor from needing a quote it cannot carry through this function's own quoting.
t6_confirm_fmt() { # -> the printf format cmd_confirm writes its record with
  awk '
    /^cmd_confirm\(\)/ { inf = 1; next }
    inf && /^}/        { exit }
    inf && /printf / && /digest=/ {
      s = $0
      a = index(s, "\047"); if (a == 0) next
      s = substr(s, a + 1)
      b = index(s, "\047"); if (b == 0) next
      print substr(s, 1, b - 1); exit
    }' "$SELF_PUBLISH"
}

# A fixture trip: a change summary carrying dated entries, and NO approval record. The
# summary's `status` is deliberately `pending` on every fixture in this group — see T6c.
t6_trip() { # <dir> <entry-date>...
  local d="$1"; shift
  mkdir -p "$d/outputs"
  {
    printf -- '---\nartifact: outputs/change-summary.md\nschema-version: 1\ntrip: t6-fixture\n'
    printf -- 'writer: hub\nlifecycle: accumulate-append\nprovenance: derived\n'
    printf -- 'publish: internal\ngenerated: %s\nstatus: pending\n---\n\n' "$1"
    while [ $# -gt 0 ]; do printf -- '## %s — an entry\n\n' "$1"; shift; done
  } > "$d/outputs/change-summary.md"
  printf '%s' "$d"
}

T6_DOCREC="$(t6_state_record "$T_TRIPMD")"
T6_FMT="$(t6_confirm_fmt)"
T6_CONF='2027-06-01T09:14:22Z'
T6_E1='2027-05-30'
T6_E2='2027-07-04'

# ── T6a — ONE EVENT, ONE RECORD. The record the mapping decides the STATE from is the
# record it takes the `updated` DATE from. Operator decision D11 in one assertion: the
# confirmation is a single event, and a design in which one surface writes it while another
# surface reads somewhere else is the shape that produced this defect.
#
# THE CONTROL IS A RUNTIME MUTATION, not a fabricated-token lookup. A fabricated path is
# injected into a copy of the command file immediately after the locator and the extractor
# is re-run over the copy; it must come back carrying the injection. Asking whether an
# invented token appears in the REAL extraction is a question whose answer is `no` whether
# the extractor works or not — it answers the same over an empty file. Same technique as
# T2's and T5's controls, and UF-CTL2's in the artifact-schema suite.
t_inject_after_mark "$T_TRIPMD" "$T6_MARK" ' `zzq/fab/.zzq-state-record` and' \
  > "$T6_DIR/tripmd_mut.md"
T6_CTL_REC="$(t6_state_record "$T6_DIR/tripmd_mut.md")"
if [ -z "$T6_DOCREC" ]; then
  FAIL "T6a: no record could be extracted from the '$T6_MARK' clause of $(basename "$T_TRIPMD") — the mapping has moved or been renamed, and every verdict below would be over an empty token rather than a measurement"
elif [ "$T6_CTL_REC" != 'zzq/fab/.zzq-state-record' ]; then
  FAIL "T6a-CTL: a record path injected into a copy of $(basename "$T_TRIPMD") was NOT recovered (got '$T6_CTL_REC', expected 'zzq/fab/.zzq-state-record') — the extractor has stopped reading the mapping, so whatever it reports about the real document is this file's answer rather than the document's"
elif [ -z "$T5_PATH" ]; then
  FAIL "T6a: T5's limb yielded no path, so there is no date-side record to compare the state-side record against"
elif [ "$T6_DOCREC" = "$T5_PATH" ]; then
  PASS "T6a: the mapping derives the coordination STATE and the \`updated\` DATE from the same record — '$T6_DOCREC', extracted from the '$T6_MARK' clause and from the \`updated\` limb independently. One event, one record: the confirmation is a single act and both consumers read it. An injected path was recovered from a mutated copy of the document, so the agreement is the document's rather than this file's"
else
  FAIL "T6a: the mapping decides the STATE from '$T6_DOCREC' but takes the \`updated\` DATE from '$T5_PATH' — two records for one event. Whichever of the two no shipped surface writes is a limb of the state model nothing can reach, and the state and its date can disagree about whether a change was decided"
fi

# ── T6b — REACHABILITY AT THE SOURCE. The record the mapping names must be the record a
# shipped surface actually writes. The shipped side is the SOURCED resolver, not a literal:
# `change_confirmation_path` is what cmd_confirm records through, so this compares the
# document against the running script rather than against a second copy of its path.
T6_TRIP_P="$(t6_trip "$T6_DIR/tripP" "$T6_E1")"
T6_SHIPREC_ABS="$(change_confirmation_path "$T6_TRIP_P")"
T6_SHIPREC="${T6_SHIPREC_ABS#"$T6_TRIP_P"/}"
T6_DOCREL="$(t6_rel "$T6_DOCREC")"
if [ -z "$T6_SHIPREC" ] || [ "$T6_SHIPREC" = "$T6_SHIPREC_ABS" ]; then
  FAIL "T6b: change_confirmation_path returned '$T6_SHIPREC_ABS', which does not resolve inside the trip dir it was given — the shipped side of this comparison is unreadable and the agreement below would mean nothing"
elif [ -z "$T6_FMT" ] || [ "${T6_FMT#digest=}" = "$T6_FMT" ]; then
  FAIL "T6b: no record format could be read out of cmd_confirm in $(basename "$SELF_PUBLISH") (got '$T6_FMT') — the shipped write is what T6c applies, and a format this file invented would prove nothing about it"
elif [ "$T6_DOCREL" = "$T6_SHIPREC" ]; then
  PASS "T6b: the record the mapping derives the state from ('$T6_DOCREL') is the record the shipped confirm subcommand writes ('$T6_SHIPREC', from the sourced change_confirmation_path), and that write's format is '$(printf '%s' "$T6_FMT" | tr '\n' ' ')' read out of cmd_confirm itself — so the decided state has a producer"
else
  FAIL "T6b: the mapping derives the state from '$T6_DOCREL' but the shipped confirm subcommand writes '$T6_SHIPREC'. Nothing in this repository moves the field the mapping keys on, so its decided value is unreachable, coordination-state can only ever be \`pending\` or \`none\`, and — § 3 giving the decay window to \`is-updated\` alone — the pending band never clears"
fi

# ── T6c — THE LATCH, REMOVED. One trip, one shipped write, two resolutions. Before the
# write the state is `pending`; after it the state must be `updated`. The write is the
# format read out of cmd_confirm, applied to the record the sourced resolver names, so what
# moves the state here is the organizer's own recorded act rather than a fixture edit.
#
# THE SUMMARY'S `status` STAYS `pending` ON EVERY FIXTURE IN THIS GROUP, and that is the
# point rather than an oversight. Under the rule this remediation replaces, `updated` was
# reached by manufacturing `status: confirmed` — a value no shipped surface writes. A
# fixture whose summary still says `pending` and which resolves `updated` anyway is the
# assertion that the implementation has stopped reading that field.
#
# The second-build limb is NOT restated here: t6_state is a pure function of the two
# records and takes no build date at all, and T5 already grades the DATE's invariance
# across two builds months apart.
T6_ST_BEFORE="$(t6_state "$T6_TRIP_P" "$T6_DOCREC")"
# shellcheck disable=SC2059  # the format IS the subject — it is read out of cmd_confirm
printf "$T6_FMT" '4294967295-1234' "$T6_CONF" > "$T6_TRIP_P/$T6_SHIPREC"
T6_ST_AFTER="$(t6_state "$T6_TRIP_P" "$T6_DOCREC")"
T6_REC_PARSED="$(_record_digest "$T6_TRIP_P/$T6_SHIPREC")"
if [ -z "$T6_REC_PARSED" ]; then
  FAIL "T6c: the record written with cmd_confirm's own format did not parse under the shipped _record_digest — the fixture never became an approval, so neither state below is a measurement of the mapping"
elif [ "$T6_ST_BEFORE" != 'pending' ]; then
  FAIL "T6c: a trip carrying an undecided entry dated $T6_E1 and NO approval record resolved '$T6_ST_BEFORE' rather than 'pending' — the transition asserted next would start from the wrong state"
elif [ "$T6_ST_AFTER" = 'updated' ]; then
  PASS "T6c: the shipped confirm write moves the coordination state — 'pending' before it and 'updated' after, over one trip whose change summary still reads \`status: pending\` throughout. The pending band therefore CLEARS: what clears it is an approval recorded later than the newest entry, an event with its own moment, rather than a field promotion no surface performs"
else
  FAIL "T6c: after applying cmd_confirm's own recorded approval ($T6_CONF) the state resolved '$T6_ST_AFTER', not 'updated' — the organizer confirmed, the plan republished, and the site still announces a change pending. § 3 gives the seven-day decay to \`is-updated\` alone, so this state does not decay either: the band latches and a traveller reads a wrong statement indefinitely"
fi

# ── T6d — CONTROL. A resolver returning a constant satisfies T6c's second half perfectly
# and measures nothing. A change raised AFTER the recorded approval must re-open `pending`,
# and its `coordination-since` must be the new entry's date rather than the old one's.
t6_trip "$T6_DIR/tripQ" "$T6_E1" "$T6_E2" >/dev/null
# shellcheck disable=SC2059  # as above
printf "$T6_FMT" '4294967295-1234' "$T6_CONF" > "$T6_DIR/tripQ/$T6_SHIPREC"
T6_ST_REOPEN="$(t6_state "$T6_DIR/tripQ" "$T6_DOCREC")"
T6_SINCE_REOPEN="$(t6_newest_entry "$T6_DIR/tripQ/outputs/change-summary.md")"
if [ "$T6_ST_REOPEN" = 'pending' ] && [ "$T6_SINCE_REOPEN" = "$T6_E2" ]; then
  PASS "T6d: CONTROL — a trip identical to T6c's but carrying one further entry dated $T6_E2, later than the same recorded approval ($T6_CONF), resolves back to 'pending' with coordination-since $T6_SINCE_REOPEN. So T6c's 'updated' is a measurement rather than a constant, and a new change re-opens the notice on the strength of the entry alone"
else
  FAIL "T6d: an entry dated $T6_E2 raised AFTER the approval at $T6_CONF resolved '$T6_ST_REOPEN' with coordination-since '$T6_SINCE_REOPEN' — expected 'pending' at $T6_E2. Either the resolver is returning a constant, in which case T6c proves nothing, or a change raised after a confirmation is never announced at all"
fi

# ── T6e — THE THREE NEGATIVE CASES, one verdict. `none` must stay reachable or AC 5's null
# case has nowhere to come from; an entry with no approval must read `pending` or nothing is
# ever announced; and a record that is present but says nothing must not count as approval,
# which is ADR-007 § 2's placeholder bound on the read side of the same file S5 grades on
# the gate side.
mkdir -p "$T6_DIR/tripN/outputs"
T6_ST_NONE="$(t6_state "$T6_DIR/tripN" "$T6_DOCREC")"
t6_trip "$T6_DIR/tripU" "$T6_E1" >/dev/null
T6_ST_UNCONF="$(t6_state "$T6_DIR/tripU" "$T6_DOCREC")"
t6_trip "$T6_DIR/tripZ" "$T6_E1" >/dev/null
printf 'digest=\nconfirmed=%s\n' "$T6_CONF" > "$T6_DIR/tripZ/$T6_SHIPREC"
T6_ST_PLACEHOLDER="$(t6_state "$T6_DIR/tripZ" "$T6_DOCREC")"
if [ "$T6_ST_NONE" = 'none' ] && [ "$T6_ST_UNCONF" = 'pending' ] && [ "$T6_ST_PLACEHOLDER" = 'pending' ]; then
  PASS "T6e: all three negative cases resolve as the mapping declares — a trip with no change summary reads 'none' (so AC 5's null case is reachable and the band is not emitted), a summary with an entry and no approval reads 'pending', and an approval record whose \`digest=\` is empty reads 'pending' rather than being taken as consent"
else
  FAIL "T6e: negative cases resolved none-case='$T6_ST_NONE' (expected none), no-approval='$T6_ST_UNCONF' (expected pending), placeholder-record='$T6_ST_PLACEHOLDER' (expected pending). A wrong none-case emits a band on a trip with no coordination activity at all and breaks AC 5's byte claim; a placeholder read as approval is a republish waved through on a record that says nothing"
fi

# ── T7 — SEAM-2, RE-PRICED. Stage 7 graded this minor because the state transition was
# UNREACHABLE. T6 makes it reachable, so it is re-measured here against the render C19
# actually declares rather than against a bare one.
#
# WHAT RESTS ON IT. #552's gate keys on itinerary CONTENT, and a coordination-marker-only
# republish passes only because the band sits OUTSIDE that projection. If a state transition
# moves the digest, the gate reads the marker change as an unapproved plan change and aborts
# — operator decision D6's deadlock, reinstated.
#
# WHY THE FIXTURE CARRIES A FRONTMATTER COMMENT. T1-T4's fixtures do not, so nothing in this
# suite has ever graded the projection against a conformant C19 render. C19's declaration
# rides an `<!-- ... -->` block (§ 4.5), the projection's last limb is `s/<[^>]+>/ /g`, and
# that collapses a comment only when the comment contains no `>`. The class's own `artifact:`
# value carries one. It is READ FROM THE SCHEMA below rather than spelled here, so the `>`
# in this fixture is the corpus's and not this file's invention.
T7_ART="$(awk -F': ' '/^artifact: / { print $2; exit }' "$T_SCHEMA")"
t7_page() { # <file> <fm-state> <fm-since> <band-state> <plan-time>
  local f="$1" fs="$2" fc="$3" bs="$4" tm="$5" band="" rule="" since=""
  [ -z "$fc" ] || since="coordination-since: ${fc}
"
  if [ "$bs" != "none" ]; then
    band="<div class=\"${T_CLASS} is-${bs}\"><span>A change is ${bs}</span> <time>2027-06-02</time></div>
"
    rule=".${T_CLASS}{background:#eee}"
  fi
  cat > "$f" <<HTML
<!--
artifact: ${T7_ART}
schema-version: 1
trip: porto-2027
writer: site
lifecycle: output
provenance: derived
publish: output
generated: 2027-06-02
coordination-state: ${fs}
${since}-->
<!DOCTYPE html><html><head><title>Porto 2027</title>
<style>${rule}.hero{color:#333}</style></head><body>
<section class="hero"><h1>Porto 2027</h1></section>
${band}<section class="day"><h2>Saturday</h2>
<p>Miradouro da Vitoria at ${tm}. Then the riverside walk to the bridge.</p></section>
<script>var mapReady=1;</script>
</body></html>
HTML
}

# The BAND varies across all three states; the frontmatter is held fixed.
t7_page "$T6_DIR/band_none.html"    pending 2027-05-30 none    16:30
t7_page "$T6_DIR/band_pending.html" pending 2027-05-30 pending 16:30
t7_page "$T6_DIR/band_updated.html" pending 2027-05-30 updated 16:30
T7_BN="$(itinerary_digest "$T6_DIR/band_none.html")"
T7_BP="$(itinerary_digest "$T6_DIR/band_pending.html")"
T7_BU="$(itinerary_digest "$T6_DIR/band_updated.html")"
# The PLAN TEXT varies; everything else is held fixed.
t7_page "$T6_DIR/plan_edit.html"    pending 2027-05-30 pending 14:00
T7_PE="$(itinerary_digest "$T6_DIR/plan_edit.html")"
# The FRONTMATTER's coordination fields vary; the band is held fixed.
t7_page "$T6_DIR/fm_none.html"      none    ""         pending 16:30
t7_page "$T6_DIR/fm_updated.html"   updated 2027-06-01 pending 16:30
T7_FN="$(itinerary_digest "$T6_DIR/fm_none.html")"
T7_FU="$(itinerary_digest "$T6_DIR/fm_updated.html")"

# ── T7a — THE SUBJECT. On a render carrying C19's own declaration block, the band is
# outside the itinerary digest: all three of its states share one token.
if [ -z "$T7_ART" ] || [ "${T7_ART#*>}" = "$T7_ART" ]; then
  FAIL "T7a: the artifact string read from $(basename "$T_SCHEMA") is '$T7_ART' and carries no '>' — this fixture is then no different from T1-T4's, the comment collapses, and T7c below would be measuring nothing. The class string has moved, or its placeholder has"
elif [ -z "$T7_BN" ]; then
  FAIL "T7a: itinerary_digest returned nothing for the band-free conformant render — the projection is not readable here and no equality below would mean anything"
elif [ "$T7_BN" = "$T7_BP" ] && [ "$T7_BN" = "$T7_BU" ]; then
  PASS "T7a: on a render carrying C19's own declaration block the coordination band is outside the itinerary digest — none, pending and updated all read $T7_BN with the frontmatter held fixed. This is the property #552's marker-only republish rests on, measured for the first time against a conformant render rather than a bare one"
else
  FAIL "T7a: the band is INSIDE the digest on a conformant render — none=$T7_BN pending=$T7_BP updated=$T7_BU. Every coordination-marker-only republish aborts, and operator decision D6's deadlock is reinstated"
fi

# ── T7b — CONTROL. A projection that discriminates nothing satisfies T7a perfectly. A plan
# edit under the same fixture must move the token. This arm depends on no defect: it holds
# whether or not the residual T7c measures is ever closed.
if [ -n "$T7_PE" ] && [ "$T7_PE" != "$T7_BP" ]; then
  PASS "T7b: CONTROL — moving one scheduled time under the same conformant fixture moves the digest ($T7_BP -> $T7_PE), so T7a's three-way equality is a measurement and not a projection that drops everything it is given"
else
  FAIL "T7b: a plan edit under the conformant fixture left the digest at '$T7_PE' against '$T7_BP' — the projection cannot see an itinerary change here, so T7a proves nothing and #552's gate would wave an unapproved plan change through"
fi

# ── T7c — THE RESIDUAL, CLOSED AND RE-SCOPED. This arm used to MEASURE a defect and pass
# on its presence: the band was excised and C19's DECLARATION BLOCK was not, because
# `s/<[^>]+>/ /g` treats `<!--` … `<destination>` as one tag and stops at that `>`, so the
# block's body — `coordination-state`, `coordination-since` and every other declared field —
# survived into the digest. Repairing it was out of that card's scope: the projection is
# strip_to_itinerary_text, another card's surface.
#
# ITS FAILURE BRANCH ANNOUNCED ITS OWN OBSOLESCENCE, and this is that re-scope. The
# projection now excises HTML comments as a construct, so the premise the old assertion
# rested on is closed and the arm asserts the INVARIANCE directly. An arm still asserting
# the old inequality would be asserting something now false, which is worse than no arm.
#
# WHY THIS IS NOT A DUPLICATE OF S12a. This arm varies ONLY the frontmatter's coordination
# fields, with the band held fixed; S12a varies the band and the frontmatter TOGETHER, which
# is the transition a trip actually undergoes. Held apart on purpose: if the comment excision
# regressed while the band excision survived, both fail, and this one names the frontmatter
# as the mover rather than leaving a reader to isolate it.
#
# T7b IS THE CONTROL for this equality as well as for T7a's — a plan edit under the same
# fixture moves the token, so an invariance here is a property of the excision rather than
# of a projection that drops everything it is given.
if [ -z "$T7_BP" ]; then
  FAIL "T7c: itinerary_digest returned nothing for the band-fixed conformant render, so the equality below would be between two empty strings"
elif cmp -s "$T6_DIR/fm_none.html" "$T6_DIR/band_pending.html" || cmp -s "$T6_DIR/fm_updated.html" "$T6_DIR/band_pending.html"; then
  FAIL "T7c: two of the three fixtures are byte-identical, so this arm is comparing a render with itself — the frontmatter's coordination fields are not actually varying and the equality measures nothing"
elif [ "$T7_FN" = "$T7_BP" ] && [ "$T7_FU" = "$T7_BP" ]; then
  PASS "T7c: C19's DECLARATION BLOCK is outside the itinerary digest — with the band held fixed, varying only the frontmatter's coordination fields leaves the token at $T7_BP for all three states, and the three renders do differ in bytes. The block is excised as a comment CONSTRUCT rather than left to the tag strip, which stops at the '>' inside '$T7_ART'. T7b shows the same projection still moves on a plan edit, so this is a measurement"
else
  FAIL "T7c: the frontmatter's coordination fields still move the digest (none=$T7_FN pending=$T7_BP updated=$T7_FU) — the comment excision in strip_to_itinerary_text has regressed or been removed, the declaration block is back inside the digest, and on a conformant render every state transition reads to the gate as an itinerary change"
fi

# ── Group T, Stage 9 pre-merge (#551 AC 5) — THE PRUNE, and how `none` is reached
#    on a trip that has history ─────────────────────────────────────────────────
#
# NOT A REMEDIATION. Nothing below fixes a defect: T8 exercises a declared rule that was
# never exercised, so it is expected to PASS on its first run. A failure would be a
# Stage 9 finding about what the release actually enforces.
#
# WHAT T6 LEFT UNGRADED, and it is a proper SUBSET rather than an omission at the edge.
# t6_state is a pure function of two records: it takes no build date and it has no
# window. Under it, once a trip has carried a dated entry `e` is non-empty forever, so
# every later resolution is `pending` or `updated` and `none` is unreachable. T6e does
# reach `none` — over a trip with NO change summary at all, a trip that has never
# coordinated anything. So the three arms above grade the mapping's entry-bearing limbs and
# its null case on a trip with no history — the no-entry `updated` limb a declared approval
# record reaches is S21l's — and say nothing about the one state a trip WITH history has to
# be able to return to.
#
# WHY THAT MATTERS TO AC 5. T3 asserts the null-case render is BYTE-IDENTICAL to a
# pre-component render, and § 3 makes non-emission a byte-level property because the site
# is encrypted wholesale. But T3 grades what `none` DOES; nothing graded how a trip that
# has coordinated once ever REACHES it again. skills/trip/SKILL.md answers that in
# one clause: "the `updated` limb is pruned at the build where its window has already
# closed ... this build writes `none` and emits no band". Without the prune, a trip whose
# one change was confirmed a year ago carries an `updated` frontmatter, a band node, a
# CSS rule and a script branch in every render for the rest of its life — and AC 5's byte
# claim, which asks that a site with no pending change and no RECENT update render exactly
# as it does today, is false for every trip that has ever had a change.
#
# WHAT THE PRUNE IS NOT. It is not § 3's decay moved to build time. § 3 evaluates the
# window at OPEN against the reader's own clock and nothing here touches that. The prune
# is a FLOOR in the one direction that cannot freeze: the build is never earlier than the
# approval and an open is never earlier than the build, so a window already closed at the
# build is closed at every open of what the build produced. It can only remove a band
# that was already dead.
#
#   T8a  the WINDOW and the null-state token, read from the two documents, both controlled
#   T8b  THE SUBJECT — a trip WITH history reaches `none` through the prune
#   T8c  CONTROL — the same trip inside the window still resolves `updated`
#   T8d  SCOPE — the prune does not reach the `pending` limb
#
# HOW THE RULE IS READ, and it is the same discipline T1, T2, T5 and T6a follow: the
# SHAPE is held here, the SOURCE is the documents'. The window comes from § 3 of the
# component contract, the state the prune writes comes from the `site` verb's own clause,
# and the record comes from T6a's extraction. Each is recovered from a mutated copy of
# its own source, so an extractor that has stopped reading its document fails here rather
# than quietly supplying this file's answer.
#
# STATED BOUND, the same one T3, T5 and T6 carry: there is no site BUILD in this
# repository. These arms grade the CONTRACT's prune and a resolution built to it, not a
# build script's output, and no arm claims that a given run followed it.
#
# Offline: two tracked documents, four sourced shell functions, fixtures under $WORK, awk
# and bash. No network, no gh, no Node, no TTY. No legitimate skip, and deliberately NOT
# declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "Coordination state — the build-time prune, and the null state on a trip with history (#551 AC 5):"

T8_DIR="$WORK/t551c"; mkdir -p "$T8_DIR"
T8_BT='`'

# The window § 3 declares, read from the component contract rather than spelled here —
# the same reason T1 reads the class token from it instead of holding a literal.
t8_window() { # [<spec-file>] -> the window in whole days, or nothing
  awk 'match($0, /W = [0-9]+ days/) {
         s = substr($0, RSTART, RLENGTH); gsub(/[^0-9]/, "", s); print s; exit
       }' "${1:-$T_SPEC}"
}

# The state the `site` verb's PRUNE clause says the build writes. Paragraph-scoped (RS="")
# for the reason T5's and T6a's extractors are: a phrase elsewhere in a 1000-line command
# file must not be mistaken for this one. Taken from the document so that a corpus which
# renamed the null state does not leave this group asserting the old name.
T8_MARK='pruned at the build'
T8_WRITES='this build writes'
t8_prune_state() { # <trip-md> -> the state the prune clause names, or nothing
  awk -v mark="$T8_MARK" -v w="$T8_WRITES" '
    BEGIN { RS = ""; FS = "\n" }
    {
      p = $0
      gsub(/\n/, " ", p)
      a = index(p, mark); if (a == 0) next
      b = index(p, w);    if (b == 0 || b < a) next
      p = substr(p, b + length(w))
      i = index(p, "`"); if (i == 0) exit
      p = substr(p, i + 1)
      j = index(p, "`"); if (j == 0) exit
      print substr(p, 1, j - 1); exit
    }' "$1"
}

# The `updated` limb's `coordination-since`: the YYYY-MM-DD prefix of the record's
# `confirmed=` line, which is what the mapping declares and what T5 grades. Read behind
# the SHIPPED _record_digest, so a record present but saying nothing yields no date —
# ADR-007 § 2's placeholder bound, the same read T6e's third case grades.
t8_since() { # <trip_dir> <state-record-path> -> YYYY-MM-DD, or nothing
  local dir="$1" rel line
  rel="$(t6_rel "$2")"
  [ -n "$(_record_digest "$dir/$rel")" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      confirmed=*) line="${line#confirmed=}"; printf '%s' "${line:0:10}"; return 0 ;;
    esac
  done < "$dir/$rel"
  return 0
}

# coordination-state as the BUILD writes it: t6_state's limbs, then the prune on the `updated`
# state alone, whichever limb reached it. Generic over the record, the window and the null-state
# token, all three of which come from the documents rather than from this file.
#
# _epoch_of_iso is the SOURCED converter, not date arithmetic written here. The BSD/GNU
# divergence it exists to absorb is the same class of defect this release already tripped
# over once in _epoch_of_file, and a second hand-rolled date path is how the two drift
# apart. An unconvertible date prints NOTHING rather than falling back to the un-pruned
# state: a silent degradation here would let T8b pass without the prune ever running.
t8_state_at_build() { # <trip_dir> <state-record> <build-YYYY-MM-DD> <window-days> <none-token>
  local st since se be
  st="$(t6_state "$1" "$2")"
  [ "$st" = 'updated' ] || { printf '%s' "$st"; return 0; }
  since="$(t8_since "$1" "$2")"
  [ -n "$since" ] || { printf '%s' "$st"; return 0; }
  se="$(_epoch_of_iso "${since}T00:00:00Z")"
  be="$(_epoch_of_iso "${3}T00:00:00Z")"
  [ -n "$se" ] && [ -n "$be" ] || return 0
  if [ "$(( (be - se) / 86400 ))" -gt "$4" ]; then printf '%s' "$5"; return 0; fi
  printf '%s' "$st"
}

T8_W="$(t8_window)"
T8_NONE="$(t8_prune_state "$T_TRIPMD")"

# CONTROLS — runtime mutations, not fabricated-token lookups. Both extractors are re-run
# over copies of their OWN source documents with a value injected, and each must come back
# carrying the injection. Asking whether an invented token appears in the REAL extraction
# is a question whose answer is `no` whether the extractor works or not — it answers the
# same over an empty file. Index-based substitution rather than a regex, for the reason
# field_hit() is index-based: corpus text carrying a metacharacter must not become a
# pattern. Same technique as T2's, T5's and T6a's controls.
T8_SPEC_MUT="$T8_DIR/spec_mut.md"
awk -v old="W = $T8_W days" -v new="W = 4242 days" '
  { i = index($0, old); if (i > 0) $0 = substr($0, 1, i - 1) new substr($0, i + length(old)); print }
' "$T_SPEC" > "$T8_SPEC_MUT"
T8_TRIPMD_MUT="$T8_DIR/tripmd_mut.md"
awk -v old="$T8_WRITES $T8_BT$T8_NONE$T8_BT" -v new="$T8_WRITES ${T8_BT}zzqfab${T8_BT}" '
  { i = index($0, old); if (i > 0) $0 = substr($0, 1, i - 1) new substr($0, i + length(old)); print }
' "$T_TRIPMD" > "$T8_TRIPMD_MUT"
T8_CTL_W="$(t8_window "$T8_SPEC_MUT")"
T8_CTL_NONE="$(t8_prune_state "$T8_TRIPMD_MUT")"

# ── T8a — THE TWO DOCUMENT-SOURCED INPUTS. A window this file invented would make every
# verdict below this file's own answer, and a null-state token spelled here would leave
# the group green through a corpus that had renamed it.
T8_WOK=0
case "$T8_W" in ''|*[!0-9]*) ;; *) [ "$T8_W" -gt 0 ] && T8_WOK=1 ;; esac
if [ "$T8_WOK" -ne 1 ]; then
  FAIL "T8a: no positive whole-day window could be read from $(basename "$T_SPEC") (got '$T8_W') — § 3 declares the window this prune is measured against, and every verdict below would be over a window this file invented"
elif [ -z "$T8_NONE" ]; then
  FAIL "T8a: the '$T8_MARK' clause in $(basename "$T_TRIPMD") named no state for the build to write — the prune clause has moved or been renamed, so the rule graded below is one this file holds rather than one the corpus declares"
elif [ "$T8_CTL_W" != '4242' ] || [ "$T8_CTL_NONE" != 'zzqfab' ]; then
  FAIL "T8a-CTL: an injected value was NOT recovered (window arm='$T8_CTL_W', expected 4242; state arm='$T8_CTL_NONE', expected zzqfab) — at least one extractor has stopped reading its document, so what it reports about the real one is this file's answer rather than the document's"
else
  PASS "T8a: the window is $T8_W day(s), read from § 3 of $(basename "$T_SPEC"), and the '$T8_MARK' clause in $(basename "$T_TRIPMD") writes '$T8_NONE' — each recovered from a mutated copy of its own source document (4242 / zzqfab), so the rule graded below is the corpus's and not this file's"
fi

# THE FIXTURE: a trip that HAS carried an entry and whose one change was approved. This is
# the case T6c/T6d/T6e cannot reach — t6_state resolves it `updated` at every build,
# forever, because it takes no build date and has no window.
T8_TRIP="$(t6_trip "$T8_DIR/tripW" "$T6_E1")"
# shellcheck disable=SC2059  # the format IS the subject — it is read out of cmd_confirm
printf "$T6_FMT" '4294967295-1234' "$T6_CONF" > "$T8_TRIP/$T6_SHIPREC"
T8_SINCE="$(t8_since "$T8_TRIP" "$T6_DOCREC")"
T8_ENTRY="$(t6_newest_entry "$T8_TRIP/outputs/change-summary.md")"
T8_UNPRUNED="$(t6_state "$T8_TRIP" "$T6_DOCREC")"
T8_BUILD_FAR='2027-09-30'
T8_BUILD_NEAR='2027-06-02'
T8_FAR="$(t8_state_at_build  "$T8_TRIP" "$T6_DOCREC" "$T8_BUILD_FAR"  "$T8_W" "$T8_NONE")"
T8_NEAR="$(t8_state_at_build "$T8_TRIP" "$T6_DOCREC" "$T8_BUILD_NEAR" "$T8_W" "$T8_NONE")"

# ── T8b — THE SUBJECT. The first two branches are what separate this arm from T6e: a
# `none` over a trip with no entry would be T6e's limb re-graded, and a fixture that did
# not resolve `updated` first would give the prune nothing to act on.
if [ -z "$T8_ENTRY" ]; then
  FAIL "T8b: the fixture's change summary carries no dated entry, so a '$T8_NONE' below would be T6e's no-entry limb rather than the prune — telling those two apart is what this arm exists for"
elif [ "$T8_UNPRUNED" != 'updated' ]; then
  FAIL "T8b: the fixture resolves '$T8_UNPRUNED' before the prune, not 'updated' — the prune is scoped to the \`updated\` limb, so there would be nothing here for it to act on"
elif [ -z "$T8_FAR" ]; then
  FAIL "T8b: the prune returned nothing — _epoch_of_iso converted neither '$T8_SINCE' nor '$T8_BUILD_FAR' on this runner, so no verdict here is a measurement"
elif [ "$T8_FAR" = "$T8_NONE" ]; then
  PASS "T8b: a trip that HAS carried an entry (dated $T8_ENTRY), approved at $T8_SINCE, resolves '$T8_NONE' at a build outside the ${T8_W}-day window ($T8_BUILD_FAR) — while the un-pruned mapping resolves '$T8_UNPRUNED' on that same trip at every build forever. This is the ONLY route back to '$T8_NONE' once a trip has history: T6e reaches it over a trip with no change summary at all. AC 5's byte claim rests on it, and T3 grades what the state then does to the render"
else
  FAIL "T8b: a trip whose approval is far outside the ${T8_W}-day window resolved '$T8_FAR', not '$T8_NONE' — the prune the \`site\` verb declares is not being applied, so a trip whose one change was confirmed long ago carries a band node, a CSS rule and a script branch in every render for the rest of its life, and AC 5's byte claim is false for every trip that has ever had a change"
fi

# ── T8c — CONTROL. A resolver that returned the null token whenever it saw a build date
# would satisfy T8b perfectly and measure nothing. The SAME trip and the SAME approval,
# read at a build INSIDE the window, must still resolve `updated` and still emit the band.
if [ "$T8_NEAR" = 'updated' ]; then
  PASS "T8c: CONTROL — the same trip and the same approval read at a build INSIDE the window ($T8_BUILD_NEAR, one day after $T8_SINCE against a ${T8_W}-day window) resolves 'updated'. So T8b's '$T8_NONE' is a measurement of the window rather than a resolver returning one value, and the prune removes only a band that was already dead"
else
  FAIL "T8c: a build one day after the approval resolved '$T8_NEAR', not 'updated' — the prune is firing INSIDE the window, so a change confirmed yesterday is never announced to the group at all, which is the opposite defect and a worse one than the latch"
fi

# ── T8d — SCOPE. The prune is the `updated` limb's alone. An entry raised AFTER the
# approval is undecided, the state is `pending`, and `pending` has no window to close —
# § 3 gives the seven-day decay to `is-updated` alone. A prune that reached `pending`
# would stop announcing a change the group never approved, once the build was old enough.
T8_TRIPV="$(t6_trip "$T8_DIR/tripV" "$T6_E1" "$T6_E2")"
# shellcheck disable=SC2059  # as above
printf "$T6_FMT" '4294967295-1234' "$T6_CONF" > "$T8_TRIPV/$T6_SHIPREC"
T8_PEND="$(t8_state_at_build "$T8_TRIPV" "$T6_DOCREC" "$T8_BUILD_FAR" "$T8_W" "$T8_NONE")"
if [ "$T8_PEND" = 'pending' ]; then
  PASS "T8d: SCOPE — a trip carrying a further entry dated $T6_E2, later than the same approval, still resolves 'pending' at the same far build ($T8_BUILD_FAR). The prune is scoped to the \`updated\` limb and does not reach an unapproved change: a pending band has no window to close, § 3 giving the decay to \`is-updated\` alone"
else
  FAIL "T8d: an UNDECIDED entry dated $T6_E2 resolved '$T8_PEND' at build $T8_BUILD_FAR — the prune has reached the \`pending\` limb, so a change the group never approved stops being announced once the build is old enough. That is a silent wrong statement to the reader, in the opposite direction from the latch T6c removed"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group S, #719 — THE APPROVAL COLLECTION (ADR-029), as built and as corrected at its scope-lock.
#
#   S16  INT-1   S2's new body: the five tokens, the declared tally, #718's FM-2 absence states
#   S17  INT-2   the binding digest, one value throughout, and the legacy-baseline shim
#   S18  INT-3   the approval line: its grammar, its normalization, stale codes, its emission
#   S19  INT-4   recording is terminal-only, with no override flag
#   S20  INT-5   the ledger: append-only, atomic, grammar-bound
#   S21  INT-6   the render's approval-code guard; C2's presence rule; rotate, the third push path
#   S22  INT-8   independence from engagement(t)
#   S23  INT-9   the threshold-met record as C2 corrected it, and confirm's re-anchoring (C1)
#   S24  INT-10  erasure's key substitution leaves the verdict unchanged
#   S25  INT-7   name-freedom, stated over approver-ness
#   S26          the restore: every stub and mutant these arms set is withdrawn
#
# PLACEMENT. These arms sit after group T rather than beside S0–S15 because three of them read
# group T's own extractors — S21l builds its render through t8_state_at_build and t6_state, S23b
# applies t6_confirm_fmt and S23c t6_state — and T10b reads S25a's records. Group RS reduces every id to its leading capitals, so where an arm sits in this
# file changes nothing it grades.
#
# HOW THE ARMS ARE WRITTEN — group S15's three rules, unchanged. Every negative is a captured
# value inside a `[ … ]` conjunction that leads to a PASS; nothing is read through a pipeline into
# an early-exiting grep (group PF); every stub is withdrawn in the arm that set it — by
# re-evaluating the saved production definition rather than by unsetting the name, so no
# production function is ever left undefined. An ARMED-RED arm carries its defect inside the arm:
# the defect is injected, must be convicted by the same assertion, and is withdrawn before the
# verdict prints.
#
# Offline: $WORK fixtures, shell-function mocks of gh and npx on the push paths (S8's technique),
# a stubbed terminal test for confirm's interactive branch, and no network, no Node, no TTY. No
# legitimate skip, and deliberately NOT declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "The approval collection — ADR-029, built by #719:"

# ── S16n — THE REGRESSION FLOOR, taken FIRST so it measures only what came before this block.
# Every verdict from S0 through T8d grades the gate, its projections and the coordination notice
# whatever body S2 holds, and all of them must still hold under the new one. Two edits to those
# arms are sanctioned, each forced by a change the scope-lock made: S15i lists _digest_of, now a
# perl program (its comment count moves to "an eighth"); and S9b/S10 read cmd_update's gate
# through its one wrapper line (C5). S6a–S6c are among the arms counted, untouched.
if [ -n "${S_FAIL_BASE:-}" ] && [ "$fail" -eq "$S_FAIL_BASE" ]; then
  PASS "S16n: the regression floor holds — no verdict from S0 through T8d failed under the new S2 body (failure count $S_FAIL_BASE as group S opened, $fail now). The two sanctioned edits are S15I_FNS gaining _digest_of and S9b/S10 reading the gate through require_publish_guards; S6a–S6c are unchanged"
else
  FAIL "S16n: $((fail - ${S_FAIL_BASE:-0})) verdict(s) from S0 through T8d failed under the new S2 body (base '${S_FAIL_BASE:-unset}') — the replacement moved a property an existing arm grades, or the base count was never taken"
fi

# Every production function an arm below stubs or mutates, saved before any arm runs. sa_restore
# re-evaluates the saved text; S26a compares each against it, so a stub that outlives its arm is
# found by name rather than by the arms after it going quietly wrong.
SA_SAVED_FNS='_iso_now _approval_tally _approvals_grammar _approval_policy _ledger_append _record_threshold_met _baseline_matches _digest_of _approval_line_parse _confirm_has_terminal change_confirmation_state require_render_approval_code _undecided_entry'
for safn in $SA_SAVED_FNS; do
  eval "SA_SAVED_${safn}=\"\$(declare -f ${safn})\""
done
sa_restore() { # <fn> — the saved production definition, re-evaluated; unset where none was saved
  local v="SA_SAVED_$1"
  if [ -n "${!v}" ]; then eval "${!v}"; else unset -f "$1"; fi
}

# A trip dir holding an s_render render, and a published baseline where one is given.
sa_trip() { # <name> <plan-time> [<baseline-digest>] -> the trip dir
  local d="$WORK/sa-$1"
  mkdir -p "$d/outputs"
  s_render "$d/outputs/porto-travel-site.html" "$2" none
  if [ -n "${3:-}" ]; then s_record "$d/.published-itinerary" "$3" published; fi
  printf '%s' "$d"
}
# A declaration in EG-3's grammar, and one ledger record written fixture-side.
sa_declare() { # <trip> <threshold> <key>...
  local d="$1" th="$2" k; shift 2
  { printf 'threshold=%s\n' "$th"; for k in "$@"; do printf 'approver=%s\n' "$k"; done; } > "$d/.approvers"
}
sa_rec() { # <trip> <key> <approve|withdraw> <digest>
  printf 'organizer-stated %s %s %s 2027-06-01T00:00:00Z\n' "$2" "$3" "$4" >> "$1/.approvals"
}
sa_state() { change_confirmation_state "$1" 2>/dev/null; }
sa_gate()  { ( require_change_confirmation "$1" ) >/dev/null 2>&1; }

# ── S16a — declared `all` over three, and all three approve the outgoing plan.
SA16A="$(sa_trip s16a 16:30 "$S_DA")"
sa_declare "$SA16A" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16A" "$sak" approve "$S_DB"; done
SA_ST="$(sa_state "$SA16A")"; sa_gate "$SA16A"; SA_RC=$?
if [ "$SA_ST" = confirmed ] && [ "$SA_RC" -eq 0 ]; then
  PASS "S16a: three declared approvers under \`all\`, each with an approve for the outgoing plan, resolve confirmed and the gate returns 0 — the declared threshold is what opens it"
else
  FAIL "S16a: a fully approved declared plan resolved '$SA_ST' (gate rc=$SA_RC) — the shipped body reads only .change-confirmed, which this trip does not have"
fi

# ── S16b — THE DECLARATION BINDS. A .change-confirmed covering the plan is beside two of three
# approvals: on a declaring trip the gate reads the tally, never the organizer's record.
SA16B="$(sa_trip s16b 16:30 "$S_DA")"
sa_declare "$SA16B" all zqa1 zqb2 zqc3
sa_rec "$SA16B" zqa1 approve "$S_DB"; sa_rec "$SA16B" zqb2 approve "$S_DB"
s_record "$SA16B/.change-confirmed" "$S_DB" confirmed
SA_ST="$(sa_state "$SA16B")"; sa_gate "$SA16B"; SA_RC=$?
if [ "$SA_ST" = unconfirmed ] && [ "$SA_RC" -ne 0 ]; then
  PASS "S16b: two of three declared approvals, beside an organizer confirmation covering the same plan, resolve unconfirmed and the gate ABORTS (rc=$SA_RC) — the declaration binds, and the organizer's own confirmation cannot stand in for the approvers"
else
  FAIL "S16b: a short tally beside a covering .change-confirmed resolved '$SA_ST' (rc=$SA_RC) — the organizer-confirm default is overriding the declaration"
fi

# ── S16c — threshold 2 of 3 with three approvals: met, and the count is not clipped.
SA16C="$(sa_trip s16c 16:30 "$S_DA")"
sa_declare "$SA16C" 2 zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16C" "$sak" approve "$S_DB"; done
SA_ST="$(sa_state "$SA16C")"; SA_TALLY="$(_approval_tally "$SA16C" "$S_DB")"
if [ "$SA_ST" = confirmed ] && [ "$SA_TALLY" = '3 2 0' ]; then
  PASS "S16c: threshold 2 of 3 with three approvals resolves confirmed and the tally reads '$SA_TALLY' — k counts every approving declared key and is not clipped to t"
else
  FAIL "S16c: threshold 2 of 3 with three approvals resolved '$SA_ST' with tally '$SA_TALLY' (want confirmed, '3 2 0')"
fi

# ── S16d — approvals only for the OLD plan read stale; rebound to the outgoing plan, confirmed.
SA16D="$(sa_trip s16d 16:30 "$S_DA")"
sa_declare "$SA16D" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16D" "$sak" approve "$S_DA"; done
SA16D2="$(sa_trip s16d2 16:30 "$S_DA")"
sa_declare "$SA16D2" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16D2" "$sak" approve "$S_DB"; done
SA_ST1="$(sa_state "$SA16D")"; SA_ST2="$(sa_state "$SA16D2")"
if [ "$SA_ST1" = stale ] && [ "$SA_ST2" = confirmed ]; then
  PASS "S16d: approvals that exist only for the previous plan resolve stale, and the SAME records rebound to the outgoing plan resolve confirmed (control) — an approval never carries forward onto content it did not cover"
else
  FAIL "S16d: approvals for the old plan resolved '$SA_ST1' (want stale) and rebound resolved '$SA_ST2' (want confirmed)"
fi

# ── S16e — THE LATEST RECORD COUNTS. approve-then-withdraw is no approval; withdraw-then-approve
# is one. ARMED-RED: a tally counting any approve at all, ignoring later records, reads the first
# case confirmed — it is injected, convicted, and withdrawn inside this arm.
SA16E="$(sa_trip s16e 16:30 "$S_DA")"
sa_declare "$SA16E" all zqa1 zqb2 zqc3
sa_rec "$SA16E" zqa1 approve "$S_DB"; sa_rec "$SA16E" zqb2 approve "$S_DB"
sa_rec "$SA16E" zqc3 approve "$S_DB"; sa_rec "$SA16E" zqc3 withdraw "$S_DB"
SA16E2="$(sa_trip s16e2 16:30 "$S_DA")"
sa_declare "$SA16E2" all zqa1 zqb2 zqc3
sa_rec "$SA16E2" zqa1 approve "$S_DB"; sa_rec "$SA16E2" zqb2 approve "$S_DB"
sa_rec "$SA16E2" zqc3 withdraw "$S_DB"; sa_rec "$SA16E2" zqc3 approve "$S_DB"
SA_ST1="$(sa_state "$SA16E")"; SA_ST2="$(sa_state "$SA16E2")"
_approval_tally() { # MUTANT: a key counts once it holds ANY approve for the digest
  local trip_dir="$1" dg="$2" line key keys="" thr="" nk=0 k=0 hit
  while IFS= read -r line; do
    case "$line" in threshold=*) thr="${line#threshold=}" ;; approver=*) keys="$keys ${line#approver=}"; nk=$((nk+1)) ;; esac
  done < "$trip_dir/.approvers"
  if [ "$thr" = all ]; then thr="$nk"; fi
  for key in $keys; do
    hit=0
    while IFS= read -r line; do
      case "$line" in "organizer-stated $key approve $dg "*) hit=1 ;; esac
    done < "$trip_dir/.approvals"
    k=$((k+hit))
  done
  printf '%s %s 0' "$k" "$thr"
}
SA_MUT="$(sa_state "$SA16E")"
sa_restore _approval_tally
SA_BACK="$(sa_state "$SA16E")"
if [ "$SA_ST1" = unconfirmed ] && [ "$SA_ST2" = confirmed ] && [ "$SA_MUT" = confirmed ] && [ "$SA_BACK" = unconfirmed ]; then
  PASS "S16e: approve-then-withdraw for one key under \`all\` resolves unconfirmed and withdraw-then-approve resolves confirmed (control); ARMED-RED — a tally counting any approve reads the first case '$SA_MUT', so this arm convicts that defect, and after the restore it reads '$SA_BACK' again"
else
  FAIL "S16e: latest-record semantics — approve-then-withdraw '$SA_ST1' (want unconfirmed), withdraw-then-approve '$SA_ST2' (want confirmed), mutant '$SA_MUT' (want confirmed), restored '$SA_BACK' (want unconfirmed)"
fi

# ── S16f — an approve by an UNDECLARED key counts for nothing.
SA16F="$(sa_trip s16f 16:30 "$S_DA")"
sa_declare "$SA16F" all zqa1 zqb2 zqc3
sa_rec "$SA16F" zqa1 approve "$S_DB"; sa_rec "$SA16F" zqb2 approve "$S_DB"; sa_rec "$SA16F" zqx9 approve "$S_DB"
SA_ST="$(sa_state "$SA16F")"; SA_TALLY="$(_approval_tally "$SA16F" "$S_DB")"
if [ "$SA_ST" = unconfirmed ] && [ "$SA_TALLY" = '2 3 0' ]; then
  PASS "S16f: an approve by a key the declaration does not name, beside two declared approvals under \`all\` of three, resolves unconfirmed with tally '$SA_TALLY' — only declared approvers count"
else
  FAIL "S16f: an undeclared key's approve moved the verdict to '$SA_ST' (tally '$SA_TALLY', want unconfirmed and '2 3 0')"
fi

# ── S16g — ONE OFF-GRAMMAR LINE POISONS THE LEDGER. With three valid approvals and one bad line
# the state is unconfirmed and stderr names .approvals; a CORRUPTED withdraw that is a key's latest
# record is the fail-open case. ARMED-RED: a reader that skips bad lines reads that one confirmed.
SA16G="$(sa_trip s16g 16:30 "$S_DA")"
sa_declare "$SA16G" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16G" "$sak" approve "$S_DB"; done
printf 'organizer-stated zqa1 approve not-a-code 2027-06-01T00:00:00Z\n' >> "$SA16G/.approvals"
SA_ST1="$(change_confirmation_state "$SA16G" 2>"$WORK/sa16g.err")"
SA_NAMES=0; case "$(cat "$WORK/sa16g.err")" in *.approvals*) SA_NAMES=1 ;; esac
SA16G2="$(sa_trip s16g2 16:30 "$S_DA")"
sa_declare "$SA16G2" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA16G2" "$sak" approve "$S_DB"; done
printf 'organizer-stated zqc3 withdraw %s 2027-06-01T00:00:00Z\n' "${S_DB:0:63}" >> "$SA16G2/.approvals"
SA_ST2="$(sa_state "$SA16G2")"
_approvals_grammar() { return 0; }   # MUTANT: every line conforms, so a bad line is skipped by the tally
SA_MUT="$(sa_state "$SA16G2")"
sa_restore _approvals_grammar
if [ "$SA_ST1" = unconfirmed ] && [ "$SA_NAMES" -eq 1 ] && [ "$SA_ST2" = unconfirmed ] && [ "$SA_MUT" = confirmed ]; then
  PASS "S16g: three valid approvals plus one off-grammar line resolve unconfirmed with stderr naming .approvals, and a corrupted withdraw that is a key's latest record resolves unconfirmed too; ARMED-RED — a skip-bad-lines reader reads that second trip '$SA_MUT', the fail-open this closes"
else
  FAIL "S16g: bad line '$SA_ST1' (names .approvals=$SA_NAMES), corrupted withdraw '$SA_ST2' (both want unconfirmed), skip-bad-lines mutant '$SA_MUT' (want confirmed)"
fi

# ── S16h — #718's FM-2(ii): a ledger with no declaration is malformed, never the default.
SA16H="$(sa_trip s16h 16:30 "$S_DA")"
sa_rec "$SA16H" zqa1 approve "$S_DB"
s_record "$SA16H/.change-confirmed" "$S_DB" confirmed
SA_ST="$(sa_state "$SA16H")"
if [ "$SA_ST" = unconfirmed ]; then
  PASS "S16h: FM-2(ii) — a ledger with no declaration, beside an organizer confirmation covering a changed plan, resolves unconfirmed: a half-retired declaration never falls back to the organizer-confirm default"
else
  FAIL "S16h: a ledger with no declaration resolved '$SA_ST' — the organizer default is reading a trip whose approval state is broken"
fi

# ── S16i — #718's FM-2(i): a declaring trip with NO baseline is still evaluated.
SA16I="$(sa_trip s16i 16:30)"
sa_declare "$SA16I" 1 zqa1
SA16I2="$(sa_trip s16i2 16:30)"
sa_declare "$SA16I2" 1 zqa1
sa_rec "$SA16I2" zqa1 approve "$S_DB"
SA_ST1="$(sa_state "$SA16I")"; SA_ST2="$(sa_state "$SA16I2")"
if [ "$SA_ST1" = unconfirmed ] && [ "$SA_ST2" = confirmed ]; then
  PASS "S16i: FM-2(i) — a declaring trip with no baseline and no approvals resolves unconfirmed, never none-pending, and the same trip with its threshold met resolves confirmed (control)"
else
  FAIL "S16i: no baseline, no approvals resolved '$SA_ST1' (want unconfirmed); no baseline, threshold met resolved '$SA_ST2' (want confirmed)"
fi

# ── S16j — UNDETERMINED ON EVERY POLICY. A dangling render on a declaring trip, with a baseline
# and without one. ARMED-RED: a declared branch that tallies the EMPTY digest reads unconfirmed.
SA16J="$(s15_dangling sa-s16j)"
s_record "$SA16J/.published-itinerary" "$S_DA" published
sa_declare "$SA16J" 1 zqa1
SA16J2="$(s15_dangling sa-s16j2)"
sa_declare "$SA16J2" 1 zqa1
SA_ST1="$(sa_state "$SA16J")"; SA_ST2="$(sa_state "$SA16J2")"
sa16j_mutant() { # the declared branch WITHOUT the identity check: the empty digest is tallied
  local trip_dir="$1" out k t s
  out="$(itinerary_digest "$(resolve_site_html "$trip_dir" 2>/dev/null)")"
  read -r k t s <<<"$(_approval_tally "$trip_dir" "$out")"
  if [ "$k" -ge "$t" ]; then printf confirmed; elif [ "$s" = 1 ]; then printf stale; else printf unconfirmed; fi
}
SA_MUT="$(sa16j_mutant "$SA16J2")"
if [ "$SA_ST1" = undetermined ] && [ "$SA_ST2" = undetermined ] && [ "$SA_MUT" = unconfirmed ]; then
  PASS "S16j: a dangling render on a declaring trip resolves undetermined with a baseline and without one — the owed emission survives the declared branch; ARMED-RED — tallying the empty digest instead reads '$SA_MUT', the claim 'it changed' nobody computed"
else
  FAIL "S16j: dangling render with baseline '$SA_ST1', without '$SA_ST2' (both want undetermined); empty-digest mutant '$SA_MUT' (want unconfirmed)"
fi

# ── S16k — EACH MALFORMED DECLARATION, one fixture per malformation. Each trip also carries an
# organizer confirmation covering its changed plan, so reading the declaration as absent would
# resolve confirmed: an unconfirmed here is the malformed limb, not the default.
SA_K_OK=0; SA_K_N=0; SA_K_BAD=""
for saspec in 'threshold=all\n\napprover=zqa1\n' 'threshold=all\napprover=zqa1\nnote=hello\n' \
              'threshold=0\napprover=zqa1\n' 'threshold=3\napprover=zqa1\napprover=zqb2\n' \
              'threshold=all\napprover=zqa1\napprover=zqa1\n' 'threshold=all\napprover=\n' \
              'threshold=all\napprover=Zqa1\n' 'approver=zqa1\n' 'threshold=all\n'; do
  SA_K_N=$((SA_K_N+1))
  sad="$(sa_trip "s16k$SA_K_N" 16:30 "$S_DA")"
  s_record "$sad/.change-confirmed" "$S_DB" confirmed
  # shellcheck disable=SC2059  # the specification IS the format: it carries only \n escapes
  printf "$saspec" > "$sad/.approvers"
  sapol="$(_approval_policy "$sad" 2>"$WORK/sa16k.err")"
  saerr="$(wc -c < "$WORK/sa16k.err" | tr -d ' ')"
  sast="$(sa_state "$sad")"
  if [ "$sapol" = malformed ] && [ "$saerr" -gt 0 ] && [ "$sast" = unconfirmed ]; then
    SA_K_OK=$((SA_K_OK+1))
  else
    SA_K_BAD="$SA_K_BAD #$SA_K_N=$sapol/$sast/${saerr}B"
  fi
done
SA_K_CTL="$(_approval_policy "$SA16A" 2>"$WORK/sa16k_ctl.err")"
SA_K_CTLERR="$(wc -c < "$WORK/sa16k_ctl.err" | tr -d ' ')"
if [ "$SA_K_CTL" != declared ] || [ "$SA_K_CTLERR" -ne 0 ]; then
  FAIL "S16k: CONTROL — S16a's conforming declaration read '$SA_K_CTL' with ${SA_K_CTLERR}B of diagnostic, so the grammar is refusing a good file and the nine refusals below prove nothing"
elif [ "$SA_K_OK" -eq 9 ] && [ "$SA_K_N" -eq 9 ]; then
  PASS "S16k: all 9 malformed declarations — a blank line, an unknown key, threshold=0, a threshold above the count, a duplicate approver, an empty key, an uppercase key, no threshold= line, no approver= line — read malformed with a diagnostic and resolve unconfirmed; the conforming declaration reads declared and silent (control)"
else
  FAIL "S16k: $SA_K_OK of $SA_K_N malformed declarations were refused as policy/state/diagnostic —$SA_K_BAD"
fi

# ── S16l — #719's DR-2 reading of FM-2: a malformed state is `none-pending` only where the
# outgoing plan IS the baseline; with the plan changed, the same state is unconfirmed. ARMED-RED:
# the literal reading — a malformed state never reads unchanged — holds even a marker-only
# republish, and this arm convicts it; the baseline comparison is stubbed off, then restored.
SA16L="$(sa_trip s16l 14:00 "$S_DA")"
printf 'threshold=all\n' > "$SA16L/.approvers"
SA16L2="$(sa_trip s16l2 16:30 "$S_DA")"
printf 'threshold=all\n' > "$SA16L2/.approvers"
SA_ST1="$(sa_state "$SA16L")"; SA_ST2="$(sa_state "$SA16L2")"
_baseline_matches() { return 1; }   # MUTANT: the literal reading of FM-2
SA_MUT="$(sa_state "$SA16L")"
sa_restore _baseline_matches
if [ "$SA_ST1" = none-pending ] && [ "$SA_ST2" = unconfirmed ] && [ "$SA_MUT" = unconfirmed ]; then
  PASS "S16l: a malformed declaration on an UNCHANGED plan resolves none-pending — nothing new can publish, so a marker-only republish is not held — and the same state with the plan changed resolves unconfirmed (control); ARMED-RED — the literal reading holds the unchanged plan too ('$SA_MUT')"
else
  FAIL "S16l: malformed and unchanged '$SA_ST1' (want none-pending), malformed and changed '$SA_ST2' (want unconfirmed), literal-reading mutant '$SA_MUT' (want unconfirmed)"
fi

# ── S16m — A DANGLING DECLARATION IS PRESENT, not absent. ARMED-RED: an existence-only presence
# test reads it absent and hands the trip to the organizer default, which reads confirmed here.
SA16M="$(sa_trip s16m 16:30 "$S_DA")"
ln -s "$SA16M/zzq-no-such-declaration" "$SA16M/.approvers"
s_record "$SA16M/.change-confirmed" "$S_DB" confirmed
SA_ST="$(sa_state "$SA16M")"
_approval_policy() { # MUTANT: presence by existence alone
  if [ -e "$1/.approvers" ] || [ -e "$1/.approvals" ]; then printf declared; else printf none; fi
}
SA_MUT="$(sa_state "$SA16M")"
sa_restore _approval_policy
if [ -L "$SA16M/.approvers" ] && [ ! -e "$SA16M/.approvers" ] && [ "$SA_ST" = unconfirmed ] && [ "$SA_MUT" = confirmed ]; then
  PASS "S16m: a declaration that is a dangling link reads present-and-unreadable, so the trip resolves unconfirmed; ARMED-RED — an existence-only test reads it absent and resolves '$SA_MUT' through the organizer default"
else
  FAIL "S16m: dangling declaration resolved '$SA_ST' (want unconfirmed); existence-only mutant '$SA_MUT' (want confirmed)"
fi

# ── S17a — KNOWN ANSWERS. The digest is SHA-256 over the bytes: FIPS 180-4's own `abc` vector,
# and the empty string's digest for empty input.
SA17_ABC="$(printf 'abc' | _digest_of)"
SA17_NIL="$(printf '' | _digest_of)"
if [ "$SA17_ABC" = 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' ] \
   && [ "$SA17_NIL" = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' ]; then
  PASS "S17a: _digest_of returns the SHA-256 known answers — 'abc' gives ba7816bf…15ad and empty input gives e3b0c442…b855, the real empty-string token, so an empty projection still has an identity"
else
  FAIL "S17a: _digest_of gave '$SA17_ABC' for 'abc' and '$SA17_NIL' for empty input — not SHA-256 (cksum gives 1219131554-3 and 4294967295-0)"
fi

# ── S17b — one itinerary byte apart, two different 64-character codes.
s_render "$WORK/sa17b1.html" 14:00 none; s_render "$WORK/sa17b2.html" 14:01 none
SA17_B1="$(itinerary_digest "$WORK/sa17b1.html")"; SA17_B2="$(itinerary_digest "$WORK/sa17b2.html")"
SA17_HEX=1
for sad in "$SA17_B1" "$SA17_B2"; do
  case "$sad" in *[!0123456789abcdef]*|'') SA17_HEX=0 ;; esac
  if [ "${#sad}" -ne 64 ]; then SA17_HEX=0; fi
done
if [ "$SA17_HEX" -eq 1 ] && [ "$SA17_B1" != "$SA17_B2" ]; then
  PASS "S17b: two renders one itinerary byte apart (14:00 and 14:01) digest to two different 64-character lowercase-hex codes"
else
  FAIL "S17b: the codes '$SA17_B1' and '$SA17_B2' are not two distinct 64-hex values"
fi

# ── S17c — THE SHIM, UNCHANGED PLAN. A CRC-shaped baseline recorded before the swap, equal to
# the legacy digest of the unchanged render, reads none-pending and the gate passes. ARMED-RED:
# with the shim replaced by exact equality the same trip reads unconfirmed, and the gate's abort
# then claims the itinerary differs — a statement nobody computed (#718's FM-1).
SA17C="$(sa_trip s17c 14:00)"
SA17C_CRC="$(_legacy_itinerary_digest "$SA17C/outputs/porto-travel-site.html")"
s_record "$SA17C/.published-itinerary" "$SA17C_CRC" published
SA17C_SHAPE=0; case "$SA17C_CRC" in *[!0123456789-]*|''|-*|*-|*-*-*) ;; *-*) SA17C_SHAPE=1 ;; esac
SA_ST="$(sa_state "$SA17C")"; sa_gate "$SA17C"; SA_RC=$?
_baseline_matches() { [ "$2" = "$3" ]; }   # MUTANT: no shim
SA_MUT="$(sa_state "$SA17C")"
SA_MUTMSG="$( ( require_change_confirmation "$SA17C" ) 2>&1 >/dev/null )"
sa_restore _baseline_matches
SA_DIFFERS=0; case "$SA_MUTMSG" in *differs*) SA_DIFFERS=1 ;; esac
if [ "$SA17C_SHAPE" -ne 1 ]; then
  FAIL "S17c: fixture integrity — the legacy digest '$SA17C_CRC' is not CRC-shaped, so this is not a pre-swap baseline"
elif [ "$SA_ST" = none-pending ] && [ "$SA_RC" -eq 0 ] && [ "$SA_MUT" = unconfirmed ] && [ "$SA_DIFFERS" -eq 1 ]; then
  PASS "S17c: a CRC-shaped baseline ($SA17C_CRC) equal to the legacy digest of the unchanged render resolves none-pending and the gate passes — the digest swap is never read as a plan change; ARMED-RED — without the shim the same trip resolves '$SA_MUT' and the abort claims the content differs"
else
  FAIL "S17c: shim state '$SA_ST' (gate rc=$SA_RC; want none-pending, 0), no-shim mutant '$SA_MUT' with a 'differs' claim=$SA_DIFFERS (want unconfirmed, 1)"
fi

# ── S17d — THE SHIM, CHANGED PLAN. A CRC baseline of the old plan against a new render.
s_render "$WORK/sa17d_old.html" 14:00 none
SA17D="$(sa_trip s17d 16:30 "$(_legacy_itinerary_digest "$WORK/sa17d_old.html")")"
SA_ST="$(sa_state "$SA17D")"
if [ "$SA_ST" = unconfirmed ]; then
  PASS "S17d: a CRC-shaped baseline of the previous plan against a changed render resolves unconfirmed — the shim admits only an unchanged plan"
else
  FAIL "S17d: a CRC baseline of D0 against a render of D1 resolved '$SA_ST' (want unconfirmed) — the shim is admitting a changed plan"
fi

# ── S17e — A LEGACY TOKEN NEVER COUNTS AS AN APPROVAL. A trip that declares nothing, with a CRC
# baseline of the old plan and a CRC-shaped confirmation equal to the legacy digest of the NEW
# plan: before the swap that confirmation matched and the trip read confirmed; now it reads stale.
SA17E="$(sa_trip s17e 16:30 "$(_legacy_itinerary_digest "$WORK/sa17d_old.html")")"
s_record "$SA17E/.change-confirmed" "$(_legacy_itinerary_digest "$SA17E/outputs/porto-travel-site.html")" confirmed
SA_ST="$(sa_state "$SA17E")"
if [ "$SA_ST" = stale ]; then
  PASS "S17e: a CRC-shaped organizer confirmation of the new plan, recorded before the swap, resolves stale — a legacy token is never an approval, at the price of one more confirm"
else
  FAIL "S17e: a legacy CRC confirmation resolved '$SA_ST' (want stale) — a legacy token is being counted as an approval"
fi

# ── S17f — the recorder writes SHA-256. CONTROL: with the digest stubbed to the legacy body the
# same call writes `<digits>-<digits>`, so the 64-hex result is the swap's doing.
SA17F="$(sa_trip s17f 14:00)"
( record_published_itinerary "$SA17F" "$SA17F/outputs/porto-travel-site.html" ) >/dev/null 2>&1
SA17F_REC="$(_record_digest "$SA17F/.published-itinerary")"
SA17F2="$(sa_trip s17f2 14:00)"
_digest_of() { _legacy_digest_of; }   # the pre-#719 body, restored for the control
( record_published_itinerary "$SA17F2" "$SA17F2/outputs/porto-travel-site.html" ) >/dev/null 2>&1
sa_restore _digest_of
SA17F_OLD="$(_record_digest "$SA17F2/.published-itinerary")"
SA17F_HEX=0; case "$SA17F_REC" in *[!0123456789abcdef]*|'') ;; *) [ "${#SA17F_REC}" -eq 64 ] && SA17F_HEX=1 ;; esac
SA17F_CRC=0; case "$SA17F_OLD" in *[!0123456789-]*|''|-*|*-|*-*-*) ;; *-*) SA17F_CRC=1 ;; esac
if [ "$SA17F_HEX" -eq 1 ] && [ "$SA17F_CRC" -eq 1 ]; then
  PASS "S17f: record_published_itinerary writes a 64-hex baseline, and with the pre-#719 digest restored the same call writes '$SA17F_OLD' (control) — the recorder follows the one digest function"
else
  FAIL "S17f: the recorder wrote '$SA17F_REC' (want 64 hex) and, under the legacy body, '$SA17F_OLD' (want digits-digits)"
fi

# The approval line in a captured confirm output: how many lines read exactly `approve <64 hex>`,
# and the code on the last of them. A read loop, not grep: group PF's rule.
sa_line_codes() { # <text> -> "n code"
  local line c n=0 last=''
  while IFS= read -r line; do
    case "$line" in
      'approve '*) c="${line#approve }"
        if [ "${#c}" -eq 64 ]; then
          case "$c" in *[!0123456789abcdef]*) ;; *) n=$((n+1)); last="$c" ;; esac
        fi ;;
    esac
  done <<<"$1"
  printf '%s %s' "$n" "${last:--}"
}

# ── S17g — ONE VALUE. The gate's outgoing digest, the code in the line confirm emits, and the
# digest the ledger records for that line are the same bytes, for one render.
SA17G="$(sa_trip s17g 16:30 "$S_DA")"
sa_declare "$SA17G" 1 zqa1
SA17G_GATE="$(itinerary_digest "$SA17G/outputs/porto-travel-site.html")"
SA17G_OUT="$( ( cmd_confirm "$SA17G" ) </dev/null 2>/dev/null )"
read -r SA17G_N SA17G_LINE <<<"$(sa_line_codes "$SA17G_OUT")"
( _ledger_append "$SA17G" zqa1 approve "$SA17G_LINE" ) >/dev/null 2>&1
SA17G_REC=''
while IFS= read -r saline; do
  sar="${saline#* }"; sar="${sar#* }"; sar="${sar#* }"; SA17G_REC="${sar%% *}"
done < "$SA17G/.approvals"
if [ "$SA17G_N" -eq 1 ] && [ -n "$SA17G_GATE" ] && [ "$SA17G_LINE" = "$SA17G_GATE" ] && [ "$SA17G_REC" = "$SA17G_GATE" ]; then
  PASS "S17g: ONE VALUE — the gate's outgoing digest, the code in the approval line confirm emits, and the digest the ledger records for it are byte-equal ($(_code_prefix "$SA17G_GATE") …)"
else
  FAIL "S17g: gate '$SA17G_GATE', emitted line '$SA17G_LINE' ($SA17G_N matching line(s)), recorded '$SA17G_REC' — the three are not one value"
fi

# ── S17h — S15i's POLICY OVER THE NEW PROGRAM, and F4: the completeness count must be proof
# against a SUBSTITUTION, not merely balanced. It compares a count and not a set, so a _digest_of
# written without perl plus an unlisted perl program elsewhere would balance it; so the listed
# body must itself be an invocation by S15i's own regex. And the CRC shape still parses, so
# group T's fixtures (T6c, T8b) and a pre-swap record are still read as tokens.
SA17H_BODY="$(declare -f _digest_of)"
SA17H_DN=0; SA17H_FB=0
case "$SA17H_BODY" in *'/dev/null'*) SA17H_DN=1 ;; esac
case "$SA17H_BODY" in *'||'*) SA17H_FB=1 ;; esac
SA17H_RE=0; if [[ "$SA17H_BODY" =~ $S15I_RE ]]; then SA17H_RE=1; fi
SA17H_NFN=0; for sad in $S15I_FNS; do SA17H_NFN=$((SA17H_NFN+1)); done
SA17H_NLINE="$(s15_perl_lines "$SELF_PUBLISH")"
printf 'digest=4294967295-1234\nconfirmed=2027-06-01T00:00:00Z\n' > "$WORK/sa17h.rec"
SA17H_CRC="$(_record_digest "$WORK/sa17h.rec")"
if [ "$SA17H_DN$SA17H_FB" = 00 ] && [ "$SA17H_RE" -eq 1 ] && [ "$SA17H_NFN" -eq 8 ] && [ "$SA17H_NLINE" -eq 8 ] && [ "$SA17H_CRC" = '4294967295-1234' ]; then
  PASS "S17h: _digest_of's parsed body reads discard/fallback 00, invokes perl by S15i's own regex (F4 — the listed body is a perl program, so the count cannot be balanced by a substitution), S15I_FNS lists 8 and the script has 8 perl-invoking lines; the CRC token still parses for group T and for a pre-swap record"
else
  FAIL "S17h: bits $SA17H_DN$SA17H_FB (want 00), regex match $SA17H_RE (want 1), listed $SA17H_NFN and counted $SA17H_NLINE (want 8 and 8), CRC parse '$SA17H_CRC'"
fi

# ── S18a — MUST REFUSE. Ten lines the grammar must not admit, each refused with nothing printed:
# a name appended, a URL, 63 and 65 hex, uppercase hex, a CRC token, a bare yes, the verb alone,
# two lines, and a non-breaking space between the tokens.
SA_H="$S_DB"
SA_UP="$(printf '%s' "$SA_H" | tr 'abcdef' 'ABCDEF')"
SA18_REFUSE=( "approve $SA_H Dana" "approve https://example.invalid/approve?code=$SA_H" "approve ${SA_H:0:63}"
              "approve ${SA_H}0" "approve $SA_UP" "approve 4294967295-1234" "yes" "approve"
              "approve $SA_H"$'\n'"approve $SA_H" "approve"$'\xc2\xa0'"$SA_H" )
SA18_OK=0; SA18_BAD=""
for (( sai=0; sai<${#SA18_REFUSE[@]}; sai++ )); do
  saout="$(_approval_line_parse "${SA18_REFUSE[$sai]}" 2>/dev/null)"; sarc=$?
  if [ "$sarc" -eq 1 ] && [ -z "$saout" ]; then SA18_OK=$((SA18_OK+1)); else SA18_BAD="$SA18_BAD #$((sai+1))=rc$sarc"; fi
done
if [ "$SA18_OK" -eq 10 ] && [ "${#SA18_REFUSE[@]}" -eq 10 ]; then
  PASS "S18a: all 10 must-refuse lines are refused with nothing printed — a name appended, a URL, 63 and 65 hex, uppercase hex, a CRC token, a bare yes, the verb alone, two lines, and a non-breaking space between the tokens. The alphabet cannot carry a name, a need or a URL"
else
  FAIL "S18a: $SA18_OK of ${#SA18_REFUSE[@]} must-refuse lines were refused —$SA18_BAD"
fi

# ── S18b — MUST ACCEPT, each normalized to the exact form. ARMED-RED: a byte-exact parser
# accepts only the two lines already in that form.
SA18_ACCEPT=( "approve $SA_H" "approve $SA_H " $'\r\n'"approve $SA_H"$'\r\n' "Approve $SA_H" "APPROVE $SA_H" "withdraw $SA_H" "approve"$'\t'"$SA_H" )
SA18_WANT=( "approve $SA_H" "approve $SA_H" "approve $SA_H" "approve $SA_H" "approve $SA_H" "withdraw $SA_H" "approve $SA_H" )
sa18_count() { # -> how many of SA18_ACCEPT the live parser normalizes to SA18_WANT
  local i o n=0
  for (( i=0; i<${#SA18_ACCEPT[@]}; i++ )); do
    o="$(_approval_line_parse "${SA18_ACCEPT[$i]}" 2>/dev/null)"
    if [ "$o" = "${SA18_WANT[$i]}" ]; then n=$((n+1)); fi
  done
  printf '%d' "$n"
}
SA18_GOOD="$(sa18_count)"
_approval_line_parse() { # MUTANT: byte-exact, no normalization
  local v="${1%% *}" c="${1#* }"
  case "$v" in approve|withdraw) ;; *) return 1 ;; esac
  if [ "${#c}" -ne 64 ]; then return 1; fi
  case "$c" in *[!0123456789abcdef]*) return 1 ;; esac
  printf '%s %s' "$v" "$c"
}
SA18_EXACT="$(sa18_count)"
sa_restore _approval_line_parse
if [ "$SA18_GOOD" -eq 7 ] && [ "$SA18_EXACT" -eq 2 ]; then
  PASS "S18b: all 7 must-accept lines normalize to the exact form — the exact line, a trailing space, surrounding CRLF, 'Approve', 'APPROVE', 'withdraw', a tab between the tokens; ARMED-RED — a byte-exact parser accepts only $SA18_EXACT of them"
else
  FAIL "S18b: the live parser normalized $SA18_GOOD of 7 (want 7); the byte-exact mutant accepted $SA18_EXACT (want 2)"
fi

# ── S18c — A WELL-FORMED LINE FOR ANOTHER PLAN IS REFUSED AS STALE, and the ledger is untouched.
# Driven end to end through confirm, with the terminal test stubbed and the prompts fed from a
# fixture; the stub is withdrawn in the arm.
SA18C="$(sa_trip s18c 16:30 "$S_DA")"
sa_declare "$SA18C" 1 zqa1
sa_rec "$SA18C" zqa1 withdraw "$S_DA"
cp "$SA18C/.approvals" "$WORK/sa18c.before"
_confirm_has_terminal() { return 0; }
SA18C_ERR="$( printf '1\napprove %s\nCONFIRM\n' "$S_DA" | ( cmd_confirm "$SA18C" ) 2>&1 >/dev/null )"; SA18C_RC=$?
sa_restore _confirm_has_terminal
SA18C_STALE=0; case "$SA18C_ERR" in *"different version of the plan"*) SA18C_STALE=1 ;; esac
SA18C_SAME=0; cmp -s "$WORK/sa18c.before" "$SA18C/.approvals" && SA18C_SAME=1
if [ "$SA18C_RC" -ne 0 ] && [ "$SA18C_STALE" -eq 1 ] && [ "$SA18C_SAME" -eq 1 ] && [ ! -e "$SA18C/.change-confirmed" ]; then
  PASS "S18c: a well-formed approval line for the previous plan is refused as stale (rc=$SA18C_RC, naming the current code), the ledger is byte-identical and no approval record is written"
else
  FAIL "S18c: a line for another plan returned rc=$SA18C_RC, stale-named=$SA18C_STALE, ledger unchanged=$SA18C_SAME — a stale code reached the ledger or the refusal said the wrong thing"
fi

# ── S18d — THE EMISSION, END TO END, WITH NO TERMINAL. confirm on a declaring trip with a changed
# plan and stdin from /dev/null prints exactly one approval line for the outgoing plan and then
# refuses at the terminal check. Its pre-terminal output names NO approver and states NO threshold
# (F5 a): a non-interactive read of confirm discloses the line to share and a count, and nothing
# that says who is declared or how many are needed. Nothing is written.
SA18D="$(sa_trip s18d 16:30 "$S_DA")"
sa_declare "$SA18D" all zqaria zqbeno zqcass
sa_rec "$SA18D" zqaria approve "$S_DB"
cp "$SA18D/.approvals" "$WORK/sa18d.before"
SA18D_OUT="$( ( cmd_confirm "$SA18D" ) </dev/null 2>"$WORK/sa18d.err" )"; SA18D_RC=$?
read -r SA18D_N SA18D_CODE <<<"$(sa_line_codes "$SA18D_OUT")"
SA18D_LEAK=0; SA18D_SENS=0
for sak in zqaria zqbeno zqcass; do
  case "$SA18D_OUT" in *"$sak"*) SA18D_LEAK=$((SA18D_LEAK+1)) ;; esac
  case "$(cat "$SA18D/.approvers")" in *"$sak"*) SA18D_SENS=$((SA18D_SENS+1)) ;; esac
done
SA18D_THR=0; case "$SA18D_OUT" in *needed*|*threshold*) SA18D_THR=1 ;; esac
SA18D_COUNT=0; case "$SA18D_OUT" in *"Approvals recorded for this plan: 1"*) SA18D_COUNT=1 ;; esac
SA18D_TERM=0; case "$(cat "$WORK/sa18d.err")" in *"requires a terminal"*) SA18D_TERM=1 ;; esac
SA18D_SAME=0; cmp -s "$WORK/sa18d.before" "$SA18D/.approvals" && SA18D_SAME=1
if [ "$SA18D_SENS" -ne 3 ]; then
  FAIL "S18d: fixture integrity — the declaration carries $SA18D_SENS of its 3 keys, so their absence from the output would prove nothing"
elif [ "$SA18D_RC" -ne 0 ] && [ "$SA18D_N" -eq 1 ] && [ "$SA18D_CODE" = "$S_DB" ] && [ "$SA18D_LEAK" -eq 0 ] && [ "$SA18D_THR" -eq 0 ] && [ "$SA18D_COUNT" -eq 1 ] && [ "$SA18D_TERM" -eq 1 ] && [ "$SA18D_SAME" -eq 1 ] && [ ! -e "$SA18D/.change-confirmed" ]; then
  PASS "S18d: with no terminal, confirm prints exactly one line of the form 'approve <64 hex>' carrying the outgoing plan's code and the recorded count, names none of the 3 declared keys (all 3 are in the declaration — the sensitivity arm), states no threshold, refuses at the terminal check, and writes nothing"
else
  FAIL "S18d: rc=$SA18D_RC, approval lines=$SA18D_N (code matches=$([ "$SA18D_CODE" = "$S_DB" ] && echo 1 || echo 0)), keys leaked=$SA18D_LEAK, threshold shown=$SA18D_THR, count shown=$SA18D_COUNT, terminal refusal=$SA18D_TERM, ledger unchanged=$SA18D_SAME"
fi

# ── S19a — RECORDING IS TERMINAL-ONLY. With stdin not a terminal the declared branch refuses
# after printing the line and appends nothing. ARMED-RED: with the terminal test stubbed true and
# the prompts fed from a fixture, the same call DOES append a record — so the refusal is the
# terminal test's doing, and nothing else stands between a non-interactive caller and the ledger.
SA19A="$(sa_trip s19a 16:30 "$S_DA")"
sa_declare "$SA19A" 1 zqa1
SA19A_OUT="$( ( cmd_confirm "$SA19A" ) </dev/null 2>/dev/null )"; SA19A_RC=$?
read -r SA19A_N _ <<<"$(sa_line_codes "$SA19A_OUT")"
SA19A_NONE=0; [ ! -e "$SA19A/.approvals" ] && SA19A_NONE=1
_confirm_has_terminal() { return 0; }
printf '1\napprove %s\nCONFIRM\n' "$S_DB" | ( cmd_confirm "$SA19A" ) >/dev/null 2>&1; SA19A_ARC=$?
sa_restore _confirm_has_terminal
SA19A_ALINES=0; [ -r "$SA19A/.approvals" ] && SA19A_ALINES="$(wc -l < "$SA19A/.approvals" | tr -d ' ')"
if [ "$SA19A_RC" -ne 0 ] && [ "$SA19A_N" -eq 1 ] && [ "$SA19A_NONE" -eq 1 ] && [ "$SA19A_ARC" -eq 0 ] && [ "$SA19A_ALINES" -eq 1 ]; then
  PASS "S19a: with no terminal the declared branch prints the approval line, refuses (rc=$SA19A_RC) and appends nothing; ARMED-RED — with the terminal test stubbed true the same call appends $SA19A_ALINES record, so the terminal test is the only thing a non-interactive caller meets. The stub is withdrawn"
else
  FAIL "S19a: no-terminal rc=$SA19A_RC, lines=$SA19A_N, ledger absent=$SA19A_NONE; stubbed rc=$SA19A_ARC, records appended=$SA19A_ALINES"
fi

# ── S19b — THE ORDER AND THE ABSENCE OF AN OVERRIDE, read from the parsed bodies so a comment
# cannot fake either: in _confirm_declared the terminal test precedes the first append, and
# neither confirm body carries --yes, --force or ALLOW_. Sensitivity: the same scan finds
# ALLOW_PLAINTEXT in cmd_publish, which does carry an override.
SA19_DECL="$(declare -f _confirm_declared)"; SA19_CONF="$(declare -f cmd_confirm)"; SA19_PUB="$(declare -f cmd_publish)"
SA19_TERM=0; SA19_APP=0
case "$SA19_DECL" in *_confirm_has_terminal*) SA19_TERM=1 ;; esac
case "$SA19_DECL" in *_ledger_append*) SA19_APP=1 ;; esac
SA19_AT_T="${SA19_DECL%%_confirm_has_terminal*}"; SA19_AT_A="${SA19_DECL%%_ledger_append*}"
SA19_FLAGS=0
for satok in '--yes' '--force' 'ALLOW_'; do
  case "$SA19_DECL" in *"$satok"*) SA19_FLAGS=$((SA19_FLAGS+1)) ;; esac
  case "$SA19_CONF" in *"$satok"*) SA19_FLAGS=$((SA19_FLAGS+1)) ;; esac
done
SA19_SENS=0; case "$SA19_PUB" in *ALLOW_PLAINTEXT*) SA19_SENS=1 ;; esac
if [ "$SA19_TERM" -eq 1 ] && [ "$SA19_APP" -eq 1 ] && [ "${#SA19_AT_T}" -lt "${#SA19_AT_A}" ] && [ "$SA19_FLAGS" -eq 0 ] && [ "$SA19_SENS" -eq 1 ]; then
  PASS "S19b: in _confirm_declared's parsed body the terminal test (byte ${#SA19_AT_T}) precedes the first ledger append (byte ${#SA19_AT_A}), and neither confirm body carries --yes, --force or ALLOW_; the sensitivity arm finds ALLOW_PLAINTEXT in cmd_publish"
else
  FAIL "S19b: terminal test present=$SA19_TERM at ${#SA19_AT_T}, append present=$SA19_APP at ${#SA19_AT_A}, override tokens=$SA19_FLAGS (want 0), sensitivity=$SA19_SENS (want 1)"
fi

# ── S20a — THE APPEND PRESERVES EVERY PRIOR BYTE. The pre-append ledger is a byte-prefix of the
# post-append one, exactly one line is added, and the result is on the grammar. ARMED-RED: a
# writer that truncates fails the prefix check.
SA20="$WORK/sa-s20"; mkdir -p "$SA20"
sa_rec "$SA20" zqa1 approve "$S_DA"
cp "$SA20/.approvals" "$WORK/sa20.pre"
( _ledger_append "$SA20" zqb2 approve "$S_DB" ) >/dev/null 2>&1; SA20_RC=$?
sa20_prefix() { # <before> <after> -> 1 when <before> is a byte-prefix of <after>
  local n
  n="$(wc -c < "$1" | tr -d ' ')"
  head -c "$n" "$2" > "$WORK/sa20.cut"
  if cmp -s "$WORK/sa20.cut" "$1"; then printf 1; else printf 0; fi
}
SA20_PFX="$(sa20_prefix "$WORK/sa20.pre" "$SA20/.approvals")"
SA20_ADDED=$(( $(wc -l < "$SA20/.approvals" | tr -d ' ') - $(wc -l < "$WORK/sa20.pre" | tr -d ' ') ))
SA20_GRAM="$(_approvals_grammar "$SA20/.approvals")"
SA20M="$WORK/sa-s20m"; mkdir -p "$SA20M"
sa_rec "$SA20M" zqa1 approve "$S_DA"
cp "$SA20M/.approvals" "$WORK/sa20m.pre"
_ledger_append() { printf 'organizer-stated %s %s %s %s\n' "$2" "$3" "$4" "$(_iso_now)" > "$(approval_ledger_path "$1")"; }   # MUTANT: truncates
( _ledger_append "$SA20M" zqb2 approve "$S_DB" ) >/dev/null 2>&1
sa_restore _ledger_append
SA20_MPFX="$(sa20_prefix "$WORK/sa20m.pre" "$SA20M/.approvals")"
if [ "$SA20_RC" -eq 0 ] && [ "$SA20_PFX" = 1 ] && [ "$SA20_ADDED" -eq 1 ] && [ -z "$SA20_GRAM" ] && [ "$SA20_MPFX" = 0 ]; then
  PASS "S20a: the ledger before the append is a byte-prefix of the ledger after it, exactly 1 line was added, and the result conforms to the grammar; ARMED-RED — a truncating writer fails the same prefix check"
else
  FAIL "S20a: rc=$SA20_RC, prefix=$SA20_PFX, lines added=$SA20_ADDED, grammar='$SA20_GRAM', truncating mutant prefix=$SA20_MPFX (want 0)"
fi

# ── S20b — three scripted appends give three conformant lines; a planted free-text record makes
# the ledger malformed rather than being read.
SA20B="$WORK/sa-s20b"; mkdir -p "$SA20B"
for sak in zqa1 zqb2 zqc3; do ( _ledger_append "$SA20B" "$sak" approve "$S_DB" ) >/dev/null 2>&1; done
SA20B_N="$(wc -l < "$SA20B/.approvals" | tr -d ' ')"
SA20B_GRAM="$(_approvals_grammar "$SA20B/.approvals")"
printf 'organizer-stated zqa1 approve %s 2027-06-01T00:00:00Z because Dana said yes on the call\n' "$S_DB" >> "$SA20B/.approvals"
SA20B_BAD="$(_approvals_grammar "$SA20B/.approvals")"
if [ "$SA20B_N" -eq 3 ] && [ -z "$SA20B_GRAM" ] && [ -n "$SA20B_BAD" ]; then
  PASS "S20b: three scripted appends give 3 conformant organizer-stated records, and a planted free-text record is refused by the grammar ('$SA20B_BAD') rather than read"
else
  FAIL "S20b: lines=$SA20B_N (want 3), grammar='$SA20B_GRAM' (want empty), free-text verdict='$SA20B_BAD' (want a refusal)"
fi

# ── S20c — ATOMIC. With mv failing, the append returns exactly 1, the ledger is byte-identical
# and no temp file remains. CONTROL: the same call with mv working returns 0 and adds the line, so
# the refusal is the failed move's and not an append that could not run at all.
SA20C="$WORK/sa-s20c"; mkdir -p "$SA20C"
sa_rec "$SA20C" zqa1 approve "$S_DA"
cp "$SA20C/.approvals" "$WORK/sa20c.pre"
SA20C2="$WORK/sa-s20c2"; mkdir -p "$SA20C2"
cp "$SA20C/.approvals" "$SA20C2/.approvals"
( _ledger_append "$SA20C2" zqb2 approve "$S_DB" ) >/dev/null 2>&1; SA20C_CRC=$?
SA20C_CLINES="$(wc -l < "$SA20C2/.approvals" | tr -d ' ')"
mv() { return 1; }
( _ledger_append "$SA20C" zqb2 approve "$S_DB" ) >/dev/null 2>&1; SA20C_RC=$?
unset -f mv
SA20C_TMP=0; for saf in "$SA20C"/.approvals.*; do [ -e "$saf" ] && SA20C_TMP=$((SA20C_TMP+1)); done
SA20C_SAME=0; cmp -s "$WORK/sa20c.pre" "$SA20C/.approvals" && SA20C_SAME=1
if [ "$SA20C_CRC" -eq 0 ] && [ "$SA20C_CLINES" -eq 2 ] && [ "$SA20C_RC" -eq 1 ] && [ "$SA20C_SAME" -eq 1 ] && [ "$SA20C_TMP" -eq 0 ]; then
  PASS "S20c: with mv failing the append returns exactly 1, the ledger is byte-identical and no temp file remains — a partial line never lands; the control, the same append with mv working, returns 0 and adds its line. The mv stub is withdrawn"
else
  FAIL "S20c: control rc=$SA20C_CRC lines=$SA20C_CLINES (want 0 and 2); failed-move rc=$SA20C_RC (want 1), ledger unchanged=$SA20C_SAME, temp files left=$SA20C_TMP"
fi

# ── S21 — THE RENDER'S APPROVAL-CODE GUARD (FM-3), C2's PRESENCE RULE, AND rotate (F3). These
# arms drive update, publish, confirm and rotate end to end against a mock gh and npx, as S8/S9
# do, and read the mock's log: an abort that happened before `repo clone` (update, rotate) or
# before `repo view` (publish) touched nothing. The renders carry C19's own declaration block,
# built by sa_page with the artifact string read from the schema (S12's discipline).
SA_GHLOG="$WORK/sa_gh.log"
gh() {   # mock: record the call, answer the read-only probes, create or clone nothing real
  printf '%s\n' "$*" >> "$SA_GHLOG"
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 0 ;;
    "auth status") printf "Token scopes: 'repo'\n" ;;
    *)             return 0 ;;
  esac
}
npx() { return 0; }
sa_page() { # <file> <count-or-empty> <code-or-empty> <plan-time> [<coordination-state> <since>]
  local f="$1" cnt="$2" code="$3" tm="$4" st="${5:-updated}" since="${6:-2027-06-02}"
  {
    printf '<!--\nartifact: %s\nschema-version: 1\ntrip: porto-2027\nwriter: site\nlifecycle: output\nprovenance: derived\npublish: output\ngenerated: 2027-06-02\ncoordination-state: %s\n' "$S12_ART" "$st"
    if [ "$st" != none ]; then printf 'coordination-since: %s\n' "$since"; fi
    if [ -n "$cnt" ]; then printf 'approval-count: %s\n' "$cnt"; fi
    if [ -n "$code" ]; then printf 'approval-code: %s\n' "$code"; fi
    printf -- '-->\n<!DOCTYPE html><html><head><title>Porto 2027</title>\n<style>.hero{color:#333}</style></head><body>\n<section class="hero"><h1>Porto 2027</h1></section>\n'
    printf '<section class="day"><h2>Saturday</h2>\n<p>Miradouro da Vitoria at %s. Then the riverside walk to the bridge.</p></section>\n<script>var mapReady=1;</script>\n</body></html>\n' "$tm"
  } > "$f"
}
sa_page "$WORK/sa_p14.html" '' '' 14:00; SA_P14="$(itinerary_digest "$WORK/sa_p14.html")"
sa_page "$WORK/sa_p16.html" '' '' 16:30; SA_P16="$(itinerary_digest "$WORK/sa_p16.html")"
SA_WRONG="$(printf 'a plan nobody approved' | _digest_of)"
sa_ptrip() { # <name> <count> <code> <plan-time> [<baseline-digest>] [<state>] -> a trip dir with an sa_page render
  local d="$WORK/sa-$1"
  mkdir -p "$d/outputs"
  sa_page "$d/outputs/porto-travel-site.html" "$2" "$3" "$4" "${6:-updated}"
  if [ -n "${5:-}" ]; then s_record "$d/.published-itinerary" "$5" published; fi
  printf '%s' "$d"
}
# The flags are computed OUTSIDE any command substitution: bash 3.2 mis-parses a `case`
# pattern's closing parenthesis inside `$( … )`, which is the runner's bash on macOS.
sa_push() { # <update|publish> <trip> -> "rc clone view create"; stderr to $WORK/sa_push.err
  local rc log cl=0 vw=0 cr=0
  : > "$SA_GHLOG"
  if [ "$1" = publish ]; then ( cmd_publish "$2" ) >/dev/null 2>"$WORK/sa_push.err"; rc=$?
  else ( cmd_update "$2" ) >/dev/null 2>"$WORK/sa_push.err"; rc=$?; fi
  log="$(cat "$SA_GHLOG")"
  case "$log" in *"repo clone"*)  cl=1 ;; esac
  case "$log" in *"repo view"*)   vw=1 ;; esac
  case "$log" in *"repo create"*) cr=1 ;; esac
  printf '%s %s %s %s' "$rc" "$cl" "$vw" "$cr"
}

# ── S21a — update refuses a render stating another plan's approval code, before any clone.
# CONTROL: the same render stating its OWN code reaches the clone.
SA21A="$(sa_ptrip s21a 2 "$SA_WRONG" 16:30 "$SA_P16")"
read -r SA21A_RC SA21A_CL _ _ <<<"$(sa_push update "$SA21A")"
SA21A_MSG="$(cat "$WORK/sa_push.err")"
SA21A2="$(sa_ptrip s21a2 2 "$SA_P16" 16:30 "$SA_P16")"
read -r SA_RC SA21A_CCL _ _ <<<"$(sa_push update "$SA21A2")"
SA21A_CODE=0; case "$SA21A_MSG" in *"approval code"*) SA21A_CODE=1 ;; esac
if [ "$SA21A_RC" -ne 0 ] && [ "$SA21A_CL" -eq 0 ] && [ "$SA21A_CODE" -eq 1 ] && [ "$SA21A_CCL" -eq 1 ]; then
  PASS "S21a: update ABORTS on a render whose approval code is not its own plan's (rc=$SA21A_RC), before any clone, naming the code; the control — the same render stating its own code — reaches the clone"
else
  FAIL "S21a: mismatch rc=$SA21A_RC clone=$SA21A_CL code-named=$SA21A_CODE; own-code control clone=$SA21A_CCL"
fi

# ── S21b — THE PAIR TRAVELS TOGETHER. Either half alone is refused before any clone; a render
# carrying neither field proceeds exactly as today.
SA21B1="$(sa_ptrip s21b1 2 '' 16:30 "$SA_P16")"
SA21B2="$(sa_ptrip s21b2 '' "$SA_P16" 16:30 "$SA_P16")"
SA21B3="$(sa_ptrip s21b3 '' '' 16:30 "$SA_P16")"
read -r SA_B1RC SA_B1CL _ _ <<<"$(sa_push update "$SA21B1")"
read -r SA_B2RC SA_B2CL _ _ <<<"$(sa_push update "$SA21B2")"
read -r _ SA_B3CL _ _ <<<"$(sa_push update "$SA21B3")"
if [ "$SA_B1RC" -ne 0 ] && [ "$SA_B1CL" -eq 0 ] && [ "$SA_B2RC" -ne 0 ] && [ "$SA_B2CL" -eq 0 ] && [ "$SA_B3CL" -eq 1 ]; then
  PASS "S21b: a render carrying the count alone, or the code alone, is refused before any clone; a render carrying neither field reaches the clone, so an undeclared render is unaffected"
else
  FAIL "S21b: count-only rc=$SA_B1RC clone=$SA_B1CL; code-only rc=$SA_B2RC clone=$SA_B2CL (both want refusal, no clone); neither-field clone=$SA_B3CL (want 1)"
fi

# ── S21c — publish refuses the same mismatch before the repo is even probed. CONTROL: a render
# carrying no approval field still reaches the existence probe, and still dies there (S9a).
SA21C="$(sa_ptrip s21c 2 "$SA_WRONG" 16:30)"
read -r SA21C_RC _ SA21C_V SA21C_C <<<"$(sa_push publish "$SA21C")"
SA21C2="$(sa_ptrip s21c2 '' '' 16:30)"
read -r SA_RC _ SA21C_CV _ <<<"$(sa_push publish "$SA21C2")"
if [ "$SA21C_RC" -ne 0 ] && [ "$SA21C_V" -eq 0 ] && [ "$SA21C_C" -eq 0 ] && [ "$SA21C_CV" -eq 1 ]; then
  PASS "S21c: publish ABORTS on a mismatched approval code (rc=$SA21C_RC) before the repo is probed or created; the control, a render with no approval field, reaches the existence probe"
else
  FAIL "S21c: mismatch rc=$SA21C_RC view=$SA21C_V create=$SA21C_C (want refusal before both); no-field control view=$SA21C_CV (want 1)"
fi

# ── S21d — C2: AN APPROVED DECLARED PUSH CARRIES ITS OWN PAIR. The threshold is met for the
# changed plan, but no approval record was ever written — the state a declaration change reaches
# with no terminal act — so the site build could only render a pending band with no count or
# code. update refuses, before any clone, and its message names the refresh at the terminal. The
# refusal must be C2's rule and not S3's: the state here is `confirmed`, which S3 lets through.
SA21D="$(sa_ptrip s21d '' '' 16:30 "$SA_P14" pending)"
sa_declare "$SA21D" 1 zqa1
sa_rec "$SA21D" zqa1 approve "$SA_P16"
SA21D_ST="$(sa_state "$SA21D")"
read -r SA21D_RC SA21D_CL _ _ <<<"$(sa_push update "$SA21D")"
SA21D_MSG="$(cat "$WORK/sa_push.err")"
SA21D_C2=0; case "$SA21D_MSG" in *"carries no approval count or code"*confirm*) SA21D_C2=1 ;; esac
if [ "$SA21D_ST" = confirmed ] && [ "$SA21D_RC" -ne 0 ] && [ "$SA21D_CL" -eq 0 ] && [ "$SA21D_C2" -eq 1 ]; then
  PASS "S21d: C2 — a declaring trip whose changed plan is approved (state $SA21D_ST) but whose render carries no approval count or code is refused before any clone, and the refusal is C2's own, naming the terminal refresh; without it the plan would publish behind a pending band with no count or code"
else
  FAIL "S21d: state '$SA21D_ST' (want confirmed), rc=$SA21D_RC, clone=$SA21D_CL, C2 message=$SA21D_C2 — an approved declared plan can publish without its pair, or the refusal is not the one C2 specifies"
fi

# ── S21e — AND THE REFRESH PROCEEDS. confirm at a terminal, pressing Enter at the approver
# prompt, records nothing and writes the approval record from the verdict; the site rebuilt from
# that record carries the pair, and update reaches the clone.
_confirm_has_terminal() { return 0; }
_iso_now() { printf '2027-06-10T09:00:00Z'; }
printf '\n' | ( cmd_confirm "$SA21D" ) >/dev/null 2>&1; SA21E_RC=$?
sa_restore _confirm_has_terminal; sa_restore _iso_now
SA21E_REC="$(cat "$SA21D/.change-confirmed" 2>/dev/null)"
SA21E_WANT="$(printf 'digest=%s\nconfirmed=2027-06-10T09:00:00Z\napproval-count=1' "$SA_P16")"
sa_page "$SA21D/outputs/porto-travel-site.html" 1 "$SA_P16" 16:30 updated 2027-06-10
read -r _ SA21E_CL _ _ <<<"$(sa_push update "$SA21D")"
SA21E_NOLEDGER=0; [ "$(wc -l < "$SA21D/.approvals" | tr -d ' ')" -eq 1 ] && SA21E_NOLEDGER=1
if [ "$SA21E_RC" -eq 0 ] && [ "$SA21E_REC" = "$SA21E_WANT" ] && [ "$SA21E_NOLEDGER" -eq 1 ] && [ "$SA21E_CL" -eq 1 ]; then
  PASS "S21e: C2's refresh — confirm at a terminal with nothing recorded writes the approval record from the verdict (the plan's code, the act's own time, the count) and adds no ledger line; the site rebuilt from it carries the pair and update reaches the clone"
else
  FAIL "S21e: refresh rc=$SA21E_RC, record='${SA21E_REC//$'\n'/ | }' (want the three lines for this plan), ledger untouched=$SA21E_NOLEDGER, push clone=$SA21E_CL"
fi

# ── S21f — C2 AND #718's F2: A PUSH LONG AFTER THE THRESHOLD WAS MET. The record says the
# threshold was met on 2027-06-01; a site built eight days later has pruned the `updated` limb, so
# its render carries neither the band nor the pair. update refuses; the refresh RE-STAMPS
# confirmed= at its own time, the rebuilt render carries the pair, and the push proceeds.
SA21F="$(sa_ptrip s21f '' '' 16:30 "$SA_P14" none)"
sa_declare "$SA21F" 1 zqa1
sa_rec "$SA21F" zqa1 approve "$SA_P16"
printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=1\n' "$SA_P16" > "$SA21F/.change-confirmed"
read -r SA21F_RC SA21F_CL _ _ <<<"$(sa_push update "$SA21F")"
_confirm_has_terminal() { return 0; }
_iso_now() { printf '2027-06-09T09:00:00Z'; }
printf '\n' | ( cmd_confirm "$SA21F" ) >/dev/null 2>&1
sa_restore _confirm_has_terminal; sa_restore _iso_now
SA21F_CONF=''
while IFS= read -r saline; do case "$saline" in confirmed=*) SA21F_CONF="${saline#confirmed=}" ;; esac; done < "$SA21F/.change-confirmed"
sa_page "$SA21F/outputs/porto-travel-site.html" 1 "$SA_P16" 16:30 updated 2027-06-09
read -r SA_RC SA21F_CL2 _ _ <<<"$(sa_push update "$SA21F")"
if [ "$SA21F_RC" -ne 0 ] && [ "$SA21F_CL" -eq 0 ] && [ "$SA21F_CONF" = '2027-06-09T09:00:00Z' ] && [ "$SA21F_CL2" -eq 1 ]; then
  PASS "S21f: a render built after the seven-day window closed carries no pair and update refuses it; the terminal refresh re-stamps confirmed= to its own time ($SA21F_CONF), and the render rebuilt from that record reaches the clone — the pair's window runs from the last terminal act before publication"
else
  FAIL "S21f: pruned push rc=$SA21F_RC clone=$SA21F_CL (want refusal), refreshed confirmed='$SA21F_CONF' (want 2027-06-09T09:00:00Z), rebuilt push clone=$SA21F_CL2"
fi

# ── S21g — CONTROL: C2 reaches no push it was not written for. An undeclared trip whose change
# the organizer confirmed, and a declaring trip republishing its UNCHANGED plan, both proceed with
# a render that carries no approval pair.
SA21G1="$(sa_ptrip s21g1 '' '' 16:30 "$SA_P14" pending)"
s_record "$SA21G1/.change-confirmed" "$SA_P16" confirmed
SA21G2="$(sa_ptrip s21g2 '' '' 16:30 "$SA_P16" pending)"
sa_declare "$SA21G2" 1 zqa1
sa_rec "$SA21G2" zqa1 approve "$SA_P16"
SA21G_ST1="$(sa_state "$SA21G1")"; SA21G_ST2="$(sa_state "$SA21G2")"
read -r SA_RC SA21G_CL1 _ _ <<<"$(sa_push update "$SA21G1")"
read -r SA_RC SA21G_CL2 _ _ <<<"$(sa_push update "$SA21G2")"
# ARMED-RED: a presence rule that over-reached — requiring the pair on every update — refuses
# both of these pushes, and this arm convicts it. The guard is saved, overridden and restored.
require_render_approval_code() { # MUTANT: the pair required on every update
  local nc nk code
  read -r nc nk code <<<"$(_render_approval_pair "$2")"
  if [ "${3:-update}" = update ] && [ "$nc" -eq 0 ]; then die "mutant: no approval pair"; fi
  return 0
}
read -r SA_RC SA21G_M1 _ _ <<<"$(sa_push update "$SA21G1")"
read -r SA_RC SA21G_M2 _ _ <<<"$(sa_push update "$SA21G2")"
sa_restore require_render_approval_code
if [ "$SA21G_ST1" = confirmed ] && [ "$SA21G_ST2" = none-pending ] && [ "$SA21G_CL1" -eq 1 ] && [ "$SA21G_CL2" -eq 1 ] && [ "$SA21G_M1" -eq 0 ] && [ "$SA21G_M2" -eq 0 ]; then
  PASS "S21g: CONTROL — an undeclared trip with an organizer-confirmed change, and a declaring trip republishing its unchanged plan, both reach the clone with a pair-less render: C2's presence rule binds only an approved change on a declaring trip; ARMED-RED — an over-reaching rule requiring the pair on every update refuses both"
else
  FAIL "S21g: undeclared '$SA21G_ST1' clone=$SA21G_CL1, declared-unchanged '$SA21G_ST2' clone=$SA21G_CL2 (want 1 and 1); over-reaching mutant clones $SA21G_M1 / $SA21G_M2 (want 0 and 0)"
fi

# ── S21h–S21k — rotate, THE THIRD PUSH PATH (the scope-lock's F3). rotate no longer republishes
# through update: it applies update's own guards itself, as the same one call line, and they run
# BEFORE rotate writes the new passphrase (GHSA-gmm2-v7rr-jq7r). So every refusal #719 adds on
# update's path reaches rotate too, and now leaves the passphrase file exactly as it was — the
# residual these arms used to measure (#1468's third case, which #719 widened) is closed, and they
# were re-pointed at its absence as their own note asked. Each arm asserts the refusal, that nothing
# was cloned, and that the file is unchanged, so a guard moved back behind the write turns them red.
# No passphrase value is ever printed here; the file is compared, not shown.
sa_rotate() { # <trip> -> "rc clone passphrase-rewritten"; the refusal's text to $WORK/sa_rot.err
  local d="$1" before after rc ch=0 cl=0 log
  printf 'zzq-residual-passphrase-before-rotate\n' > "$d/.passphrase"
  before="$(cat "$d/.passphrase")"
  : > "$SA_GHLOG"
  ( cmd_rotate "$d" ) >/dev/null 2>"$WORK/sa_rot.err"; rc=$?
  after="$(cat "$d/.passphrase" 2>/dev/null)"
  if [ "$after" != "$before" ]; then ch=1; fi
  log="$(cat "$SA_GHLOG")"
  case "$log" in *"repo clone"*) cl=1 ;; esac
  printf '%s %s %s' "$rc" "$cl" "$ch"
}
SA21H="$(sa_ptrip s21h '' '' 16:30 '' pending)"
sa_declare "$SA21H" 1 zqa1
read -r SA_HRC SA_HCL SA_HCH <<<"$(sa_rotate "$SA21H")"
SA_HMSG=0; case "$(cat "$WORK/sa_rot.err")" in *"state: unconfirmed"*) SA_HMSG=1 ;; esac
SA21H2="$(sa_ptrip s21h2 1 "$SA_P16" 16:30 "$SA_P14")"
sa_declare "$SA21H2" 1 zqa1
sa_rec "$SA21H2" zqa1 approve "$SA_P16"
read -r SA_RC SA_H2CL _ <<<"$(sa_rotate "$SA21H2")"
if [ "$SA_H2CL" -ne 1 ]; then
  FAIL "S21h: CONTROL — rotate on an approved declaring trip whose render carries its own pair did not reach the clone, so a refusal below would not be attributable to the state under test"
elif [ "$SA_HRC" -ne 0 ] && [ "$SA_HCL" -eq 0 ] && [ "$SA_HMSG" -eq 1 ] && [ "$SA_HCH" -eq 0 ]; then
  PASS "S21h: rotate on a declaring trip with NO baseline and no approvals (#718's FM-2 i) is refused by the gate (state: unconfirmed) before any clone — and the passphrase file is exactly as it was, because the guards run before rotate writes it; the control, an approved trip carrying its pair, reaches the clone"
else
  FAIL "S21h: rotate with no baseline rc=$SA_HRC clone=$SA_HCL refused-as-unconfirmed=$SA_HMSG passphrase-rewritten=$SA_HCH"
fi
SA21I="$(sa_ptrip s21i 2 "$SA_WRONG" 16:30 "$SA_P16")"
read -r SA_IRC SA_ICL SA_ICH <<<"$(sa_rotate "$SA21I")"
SA_IMSG=0; case "$(cat "$WORK/sa_rot.err")" in *"approval code"*"must be the code of the plan"*) SA_IMSG=1 ;; esac
if [ "$SA_IRC" -ne 0 ] && [ "$SA_ICL" -eq 0 ] && [ "$SA_IMSG" -eq 1 ] && [ "$SA_ICH" -eq 0 ]; then
  PASS "S21i: rotate on a render stating another plan's approval code is refused by the code guard before any clone — and the passphrase file is exactly as it was"
else
  FAIL "S21i: rotate with a mismatched code rc=$SA_IRC clone=$SA_ICL code-guard-refusal=$SA_IMSG passphrase-rewritten=$SA_ICH"
fi
SA21J="$(sa_ptrip s21j 2 '' 16:30 "$SA_P16")"
read -r SA_JRC SA_JCL SA_JCH <<<"$(sa_rotate "$SA21J")"
SA_JMSG=0; case "$(cat "$WORK/sa_rot.err")" in *"travels together"*) SA_JMSG=1 ;; esac
if [ "$SA_JRC" -ne 0 ] && [ "$SA_JCL" -eq 0 ] && [ "$SA_JMSG" -eq 1 ] && [ "$SA_JCH" -eq 0 ]; then
  PASS "S21j: rotate on a render carrying half the approval pair is refused by the code guard before any clone — and the passphrase file is exactly as it was"
else
  FAIL "S21j: rotate with half a pair rc=$SA_JRC clone=$SA_JCL pair-refusal=$SA_JMSG passphrase-rewritten=$SA_JCH"
fi
SA21K="$(sa_ptrip s21k '' '' 16:30 "$SA_P14" pending)"
sa_declare "$SA21K" 1 zqa1
sa_rec "$SA21K" zqa1 approve "$SA_P16"
read -r SA_KRC SA_KCL SA_KCH <<<"$(sa_rotate "$SA21K")"
SA_KMSG=0; case "$(cat "$WORK/sa_rot.err")" in *"carries no approval count or code"*) SA_KMSG=1 ;; esac
if [ "$SA_KRC" -ne 0 ] && [ "$SA_KCL" -eq 0 ] && [ "$SA_KMSG" -eq 1 ] && [ "$SA_KCH" -eq 0 ]; then
  PASS "S21k: rotate on an approved declaring trip whose render carries no pair is refused by C2's own rule before any clone — and the passphrase file is exactly as it was"
else
  FAIL "S21k: rotate with an approved plan and no pair rc=$SA_KRC clone=$SA_KCL C2-refusal=$SA_KMSG passphrase-rewritten=$SA_KCH"
fi

# ── S21l — #719's Stage 7 F-01: AN APPROVED DECLARED CHANGE WITH NO CHANGE-SUMMARY ENTRY PUBLISHES.
# THE RENDER IS BUILT THROUGH THE MAPPING, never by hand. sa_build takes the state and its date from
# group T's own resolver — t8_state_at_build, which is t6_state's limbs and then the prune, over the
# record, the window and the null token read from the documents — and the approval pair from that
# record on an `updated` render alone. sa_page is only the printer: every coordination value it
# prints is the mapping's. S21d–S21f pass those values in by hand, which is why no arm could see a
# mapping that resolves `none` where C2's presence rule requires the pair.
#
# THE SUBJECT: two declaring trips whose changed plan is approved — one with no change summary at
# all, one whose summary holds no entry. The first build resolves `none` and update refuses it with
# C2's message; the terminal refresh that message names writes the approval record; the rebuilt
# render resolves `updated`, carries the pair, and update reaches the clone. ARMED-RED: under
# t6_state's earlier body — no entry reads `none` before the record is read — the same refreshed
# fixture builds a pair-less render and update refuses it again: the refresh cannot converge. The
# mutant is saved, swapped in and restored inside this arm. CONTROL — the undeclared path is
# unchanged: an undeclared trip whose organizer confirmed a change, with no entry, builds
# byte-identically under both resolvers, reads `none`, carries no pair, and reaches the clone.
sa_build() { # <trip> <plan-time> <build-YYYY-MM-DD> — writes the render through the mapping; prints the state
  local d="$1" st since="" cnt="" code="" line
  st="$(t8_state_at_build "$d" "$T6_DOCREC" "$3" "$T8_W" "$T8_NONE")"
  case "$st" in
    pending) since="$(t6_newest_entry "$d/outputs/change-summary.md")" ;;
    updated)
      since="$(t8_since "$d" "$T6_DOCREC")"
      if [ -r "$d/$(t6_rel "$T6_DOCREC")" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
          case "$line" in
            digest=*)         code="${line#digest=}" ;;
            approval-count=*) cnt="${line#approval-count=}" ;;
          esac
        done < "$d/$(t6_rel "$T6_DOCREC")"
      fi
      case "$cnt" in ''|*[!0123456789]*) cnt=""; code="" ;; esac ;;
  esac
  sa_page "$d/outputs/porto-travel-site.html" "$cnt" "$code" "$2" "${st:-zzq-unresolved}" "$since"
  printf '%s' "$st"
}
SA21L1="$WORK/sa-s21l1"; SA21L2="$WORK/sa-s21l2"
mkdir -p "$SA21L1/outputs" "$SA21L2/outputs"
{
  printf -- '---\nartifact: outputs/change-summary.md\nschema-version: 1\ntrip: s21l-fixture\n'
  printf -- 'writer: hub\nlifecycle: accumulate-append\nprovenance: derived\n'
  printf -- 'publish: internal\ngenerated: 2027-06-10\nstatus: pending\n---\n'
} > "$SA21L2/outputs/change-summary.md"
SA21L_PRE_OK=0; SA21L_POST_OK=0; SA21L_MUT_OK=0; SA21L_DETAIL=""
for sad in "$SA21L1" "$SA21L2"; do
  s_record "$sad/.published-itinerary" "$SA_P14" published
  sa_declare "$sad" 1 zqa1
  sa_rec "$sad" zqa1 approve "$SA_P16"
  sast1="$(sa_build "$sad" 16:30 2027-06-10)"
  read -r sarc1 sacl1 _ _ <<<"$(sa_push update "$sad")"
  samsg1=0; case "$(cat "$WORK/sa_push.err")" in *"carries no approval count or code"*) samsg1=1 ;; esac
  _confirm_has_terminal() { return 0; }
  _iso_now() { printf '2027-06-10T09:00:00Z'; }
  printf '\n' | ( cmd_confirm "$sad" ) >/dev/null 2>&1
  sa_restore _confirm_has_terminal; sa_restore _iso_now
  sast2="$(sa_build "$sad" 16:30 2027-06-10)"
  read -r sanc sank sacode <<<"$(_render_approval_pair "$sad/outputs/porto-travel-site.html")"
  read -r sarc2 sacl2 _ _ <<<"$(sa_push update "$sad")"
  SA21L_DETAIL="$SA21L_DETAIL [$(basename "$sad"): first build '$sast1' rc=$sarc1 clone=$sacl1 C2=$samsg1; rebuilt '$sast2' pair=$sanc/$sank code-own=$([ "$sacode" = "$SA_P16" ] && echo 1 || echo 0) rc=$sarc2 clone=$sacl2]"
  if [ "$sast1" = none ] && [ "$sarc1" -ne 0 ] && [ "$sacl1" -eq 0 ] && [ "$samsg1" -eq 1 ]; then SA21L_PRE_OK=$((SA21L_PRE_OK+1)); fi
  if [ "$sast2" = updated ] && [ "$sanc" -eq 1 ] && [ "$sank" -eq 1 ] && [ "$sacode" = "$SA_P16" ] && [ "$sacl2" -eq 1 ]; then SA21L_POST_OK=$((SA21L_POST_OK+1)); fi
done
# The undeclared control: an organizer-confirmed change, no entry, built under the resolver as it is.
SA21L3="$WORK/sa-s21l3"; mkdir -p "$SA21L3/outputs"
s_record "$SA21L3/.published-itinerary" "$SA_P14" published
s_record "$SA21L3/.change-confirmed" "$SA_P16" confirmed
SA21L3_ST="$(sa_build "$SA21L3" 16:30 2027-06-10)"
cp "$SA21L3/outputs/porto-travel-site.html" "$WORK/sa21l3_now.html"
read -r SA_RC SA21L3_CL _ _ <<<"$(sa_push update "$SA21L3")"
# ARMED-RED — the mapping's earlier resolver, swapped in and restored.
SA21L_T6_SAVED="$(declare -f t6_state)"
t6_state() { # MUTANT: t6_state's earlier body — with no entry it reads `none` before the record is read
  local dir="$1" rel line c="" e=""
  rel="$(t6_rel "$2")"
  e="$(t6_newest_entry "$dir/outputs/change-summary.md")"
  if [ -z "$e" ]; then printf 'none'; return 0; fi
  if [ -n "$(_record_digest "$dir/$rel")" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in confirmed=*) c="${line#confirmed=}"; c="${c:0:10}"; break ;; esac
    done < "$dir/$rel"
  fi
  if [ -z "$c" ]; then printf 'pending'; return 0; fi
  if [[ "$e" > "$c" ]]; then printf 'pending'; return 0; fi
  printf 'updated'
}
SA21L_MST="$(sa_build "$SA21L1" 16:30 2027-06-10)"
read -r SA21L_MRC SA21L_MCL _ _ <<<"$(sa_push update "$SA21L1")"
SA21L_MMSG=0; case "$(cat "$WORK/sa_push.err")" in *"carries no approval count or code"*) SA21L_MMSG=1 ;; esac
sa_build "$SA21L3" 16:30 2027-06-10 >/dev/null
SA21L3_SAME=0; cmp -s "$WORK/sa21l3_now.html" "$SA21L3/outputs/porto-travel-site.html" && SA21L3_SAME=1
eval "$SA21L_T6_SAVED"
SA21L_T6_BACK=0; [ "$(declare -f t6_state)" = "$SA21L_T6_SAVED" ] && SA21L_T6_BACK=1
if [ "$SA21L_MST" = none ] && [ "$SA21L_MRC" -ne 0 ] && [ "$SA21L_MCL" -eq 0 ] && [ "$SA21L_MMSG" -eq 1 ]; then SA21L_MUT_OK=1; fi
if [ "$SA21L_PRE_OK" -eq 2 ] && [ "$SA21L_POST_OK" -eq 2 ] && [ "$SA21L_MUT_OK" -eq 1 ] && [ "$SA21L3_ST" = none ] && [ "$SA21L3_CL" -eq 1 ] && [ "$SA21L3_SAME" -eq 1 ] && [ "$SA21L_T6_BACK" -eq 1 ]; then
  PASS "S21l: F-01 — with no change-summary entry (absent, and present but empty), an approved declared change builds through the mapping to 'none' and update refuses it naming the refresh; after that refresh the rebuilt render resolves 'updated', carries its own count and code, and update reaches the clone — the refusal converges. ARMED-RED: under t6_state's earlier body the refreshed fixture still builds 'none' and update refuses it; CONTROL: an undeclared trip with no entry builds byte-identically under both resolvers, reads 'none' and reaches the clone"
else
  FAIL "S21l: before-refresh refusals $SA21L_PRE_OK/2, after-refresh publishes $SA21L_POST_OK/2 (want 2 and 2)$SA21L_DETAIL; earlier-resolver mutant state '$SA21L_MST' rc=$SA21L_MRC clone=$SA21L_MCL C2=$SA21L_MMSG (want none, refusal); undeclared control '$SA21L3_ST' clone=$SA21L3_CL byte-identical=$SA21L3_SAME (want none, 1, 1); t6_state restored=$SA21L_T6_BACK"
fi
# The mocks are withdrawn here, and their text is kept for S23i, the one later arm that pushes: it
# re-evaluates them and withdraws them again itself, so S26a still finds neither left defined.
SA_MOCK_GH="$(declare -f gh)"; SA_MOCK_NPX="$(declare -f npx)"
unset -f gh npx

# ── S22a — INDEPENDENT OF engagement(t) (ADR-025 § 1, ADR-029 § Decision 4). One approver's
# entry in the derived traveller model moves from unmarked to [OPERATOR-PROVIDED] to
# [OPERATOR-PROVIDED] [THIRD-PARTY], and then their traveller file gains a person: reference. The
# token and the tally are the same across all four states; the four states do differ in bytes.
SA22="$(sa_trip s22 16:30 "$S_DA")"
sa_declare "$SA22" 2 zqa1 zqb2
sa_rec "$SA22" zqa1 approve "$S_DB"; sa_rec "$SA22" zqb2 approve "$S_DB"
mkdir -p "$SA22/travelers"
SA22_TOK=""; SA22_SNAP=""
for sastate in 1 2 3 4; do
  case "$sastate" in
    1) printf '## Zqa1\n- Mobility: no stairs\n' > "$SA22/outputs/traveler-model.md"; printf '# Zqa1\n' > "$SA22/travelers/zqa1.md" ;;
    2) printf '## Zqa1 [OPERATOR-PROVIDED]\n- Mobility: no stairs\n' > "$SA22/outputs/traveler-model.md" ;;
    3) printf '## Zqa1 [OPERATOR-PROVIDED] [THIRD-PARTY]\n- Mobility: no stairs\n' > "$SA22/outputs/traveler-model.md" ;;
    4) printf -- '---\nperson: psn-zqa1\n---\n# Zqa1\n' > "$SA22/travelers/zqa1.md" ;;
  esac
  SA22_TOK="$SA22_TOK $(sa_state "$SA22")/$(_approval_tally "$SA22" "$S_DB" | tr ' ' ',')"
  SA22_SNAP="$SA22_SNAP|$(cat "$SA22/outputs/traveler-model.md" "$SA22/travelers/zqa1.md" | _digest_of)"
done
SA22_DISTINCT="$(printf '%s\n' "${SA22_SNAP#|}" | tr '|' '\n' | sort -u | wc -l | tr -d ' ')"
if [ "$SA22_TOK" = ' confirmed/2,2,0 confirmed/2,2,0 confirmed/2,2,0 confirmed/2,2,0' ] && [ "$SA22_DISTINCT" -eq 4 ]; then
  PASS "S22a: across four engagement states of one approver — unmarked, operator-provided, third-party, and a person: reference added — the token and the tally are identical (confirmed, 2 of 2), while the four states are $SA22_DISTINCT distinct byte states: no approval verdict reads engagement"
else
  FAIL "S22a: tokens/tallies across the four states:$SA22_TOK (want confirmed/2,2,0 four times); distinct byte states $SA22_DISTINCT (want 4)"
fi

# ── S22b — the same property read from the PARSED bodies: S2 and every function it calls, and the
# recording act's functions, name no traveller file, person record, derived model or provenance
# mark. Sensitivity: the class-source function that does read the derived model names it.
# Specificity: a fabricated token is in none of them.
SA22_FNS='change_confirmation_state _approval_policy _approvers_grammar _approvals_grammar _approval_tally _baseline_matches _legacy_itinerary_digest _legacy_digest_of itinerary_digest strip_to_itinerary_text _digest_of _record_digest _baseline_record staged_record_path published_itinerary_path change_confirmation_path approver_declaration_path approval_ledger_path resolve_site_html _confirm_declared _approval_line_parse _ledger_append _record_threshold_met _published_record_date _undecided_entry'
SA22_EMPTY=0; SA22_HIT=""; SA22_SPEC=0; SA22_N=0
for safn in $SA22_FNS; do
  SA22_N=$((SA22_N+1))
  sabody="$(declare -f "$safn" 2>/dev/null)"
  if [ -z "$sabody" ]; then SA22_EMPTY=$((SA22_EMPTY+1)); fi
  for satok in traveler-model travelers/ people/ OPERATOR-PROVIDED THIRD-PARTY; do
    case "$sabody" in *"$satok"*) SA22_HIT="$SA22_HIT $safn:$satok" ;; esac
  done
  case "$sabody" in *zzq-fabricated-s22b*) SA22_SPEC=$((SA22_SPEC+1)) ;; esac
done
SA22_SENS=0; case "$(declare -f nonpublishable_values)" in *traveler-model*) SA22_SENS=1 ;; esac
if [ "$SA22_EMPTY" -eq 0 ] && [ -z "$SA22_HIT" ] && [ "$SA22_SENS" -eq 1 ] && [ "$SA22_SPEC" -eq 0 ]; then
  PASS "S22b: the parsed bodies of all $SA22_N functions on the gate's and the recording act's paths name no traveller file, person record, derived model or provenance mark; the sensitivity arm finds the derived model in nonpublishable_values, and a fabricated token is in none"
else
  FAIL "S22b: empty bodies=$SA22_EMPTY, hits:${SA22_HIT:- none}, sensitivity=$SA22_SENS, specificity=$SA22_SPEC"
fi

# ── S23a — THE THRESHOLD-MET RECORD, AS C2 CORRECTED IT: the record mirrors the verdict. Threshold
# 2 of 3, with the clock pinned at each act: below the threshold nothing is written; the act that
# meets it writes the three lines with confirmed= at its own instant; a later act while met
# RE-STAMPS confirmed= (the design had kept the first stamp — C2 moved it to the last terminal act
# before publication); and a withdrawal that drops below the threshold rewrites the count alone.
SA23="$(sa_trip s23 16:30 "$S_DA")"
sa_declare "$SA23" 2 zqa1 zqb2 zqc3
_iso_now() { printf '%s' "$SA23_NOW"; }
SA23_NOW='2027-06-01T09:00:00Z'; sa_rec "$SA23" zqa1 approve "$S_DB"; _record_threshold_met "$SA23" "$S_DB"
SA23_R1=0; [ -e "$SA23/.change-confirmed" ] && SA23_R1=1
SA23_NOW='2027-06-02T09:00:00Z'; sa_rec "$SA23" zqb2 approve "$S_DB"; _record_threshold_met "$SA23" "$S_DB"
SA23_R2="$(cat "$SA23/.change-confirmed" 2>/dev/null)"
SA23_NOW='2027-06-03T09:00:00Z'; sa_rec "$SA23" zqc3 approve "$S_DB"; _record_threshold_met "$SA23" "$S_DB"
SA23_R3="$(cat "$SA23/.change-confirmed" 2>/dev/null)"
SA23_NOW='2027-06-04T09:00:00Z'; sa_rec "$SA23" zqc3 withdraw "$S_DB"; sa_rec "$SA23" zqb2 withdraw "$S_DB"; _record_threshold_met "$SA23" "$S_DB"
SA23_R4="$(cat "$SA23/.change-confirmed" 2>/dev/null)"
sa_restore _iso_now
SA23_W2="$(printf 'digest=%s\nconfirmed=2027-06-02T09:00:00Z\napproval-count=2' "$S_DB")"
SA23_W3="$(printf 'digest=%s\nconfirmed=2027-06-03T09:00:00Z\napproval-count=3' "$S_DB")"
SA23_W4="$(printf 'digest=%s\nconfirmed=2027-06-03T09:00:00Z\napproval-count=1' "$S_DB")"
if [ "$SA23_R1" -eq 0 ] && [ "$SA23_R2" = "$SA23_W2" ] && [ "$SA23_R3" = "$SA23_W3" ] && [ "$SA23_R4" = "$SA23_W4" ]; then
  PASS "S23a: below the threshold no record is written; the act that meets it writes digest=, confirmed= at its instant and approval-count=; a later act while met re-stamps confirmed= to its own instant (C2); a withdrawal below the threshold rewrites only the count, keeping confirmed= — the record mirrors the verdict, and names nobody"
else
  FAIL "S23a: after the first approval a record existed=$SA23_R1 (want 0); after meeting [${SA23_R2//$'\n'/ | }]; after a later approval [${SA23_R3//$'\n'/ | }]; after withdrawals [${SA23_R4//$'\n'/ | }]"
fi

# ── S23b — THE UNDECLARED WRITE IS UNCHANGED: the format group T reads out of cmd_confirm's own
# body is still exactly the two-line record, so T6's extractor still reads the undeclared limb.
SA23B_FMT="$(t6_confirm_fmt)"
# ARMED-RED: over a copy of the script whose cmd_confirm writes the declared record FIRST, the same
# extractor reads the three-line format — so this arm sees the regression it guards against.
SA23B_MUT="$WORK/sa23b_mut.sh"; : > "$SA23B_MUT"
while IFS= read -r saline || [ -n "$saline" ]; do
  printf '%s\n' "$saline" >> "$SA23B_MUT"
  case "$saline" in
    'cmd_confirm() {'*) printf '%s\n' "  printf 'digest=%s\\nconfirmed=%s\\napproval-count=%s\\n' 1 2 3 >/dev/null" >> "$SA23B_MUT" ;;
  esac
done < "$SELF_PUBLISH"
SA23B_SELF="$SELF_PUBLISH"; SELF_PUBLISH="$SA23B_MUT"
SA23B_MUTFMT="$(t6_confirm_fmt)"
SELF_PUBLISH="$SA23B_SELF"
if [ "$SA23B_FMT" = 'digest=%s\nconfirmed=%s\n' ] && [ "$SA23B_MUTFMT" = 'digest=%s\nconfirmed=%s\napproval-count=%s\n' ]; then
  PASS "S23b: t6_confirm_fmt reads '$SA23B_FMT' out of cmd_confirm — the first record write in its own body is still the organizer's two-line confirmation, and the declared writer sits outside it; ARMED-RED — over a copy whose cmd_confirm writes the declared record first, it reads the three-line format"
else
  FAIL "S23b: t6_confirm_fmt read '$SA23B_FMT' (want the two-line format) and over the mutated copy '$SA23B_MUTFMT' (want the three-line format)"
fi

# ── S23c — the record the declared writer produces decides `updated` under group T's own
# resolver, so the notice clears on a declaring trip exactly as it does on any other.
SA23C="$(t6_trip "$WORK/sa-s23c" 2027-05-30)"
s_render "$SA23C/outputs/porto-travel-site.html" 16:30 none
sa_declare "$SA23C" 1 zqa1
sa_rec "$SA23C" zqa1 approve "$S_DB"
_iso_now() { printf '2027-06-02T09:00:00Z'; }
_record_threshold_met "$SA23C" "$S_DB"
sa_restore _iso_now
SA23C_ST="$(t6_state "$SA23C" "$T6_DOCREC")"
if [ "$SA23C_ST" = updated ]; then
  PASS "S23c: t6_state over a record _record_threshold_met wrote resolves 'updated' — the declared record clears a pending entry raised before it, as the organizer's does"
else
  FAIL "S23c: t6_state over the declared record resolved '$SA23C_ST' (want updated) — the notice would latch on a declaring trip"
fi

# The declared branch driven end to end: terminal test stubbed, clock pinned, prompts fed from a
# fixture, and every stub withdrawn before the caller reads the result.
sa_confirm() { # <trip> <stdin-text> <now> -> the exit status
  local rc
  _confirm_has_terminal() { return 0; }
  _iso_now() { printf '%s' "$SA_CONF_NOW"; }
  SA_CONF_NOW="$3"
  printf '%s\n' "$2" | ( cmd_confirm "$1" ) >"$WORK/sa_conf.out" 2>"$WORK/sa_conf.err"; rc=$?
  sa_restore _confirm_has_terminal; sa_restore _iso_now
  return "$rc"
}

# ── S23d — C1: A WITHDRAWAL AFTER PUBLICATION IS RECORDABLE. The plan is published and its
# approvals met the threshold; a traveller withdraws. confirm records it against the published
# plan — exactly one ledger line — the record's count drops and its date stays, and the gate still
# reads the published plan unchanged. Before C1, confirm refused here with "nothing to confirm".
SA23D="$(sa_trip s23d 16:30 "$S_DB")"
sa_declare "$SA23D" 2 zqa1 zqb2
sa_rec "$SA23D" zqa1 approve "$S_DB"; sa_rec "$SA23D" zqb2 approve "$S_DB"
printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=2\n' "$S_DB" > "$SA23D/.change-confirmed"
SA23D_PRE="$(wc -l < "$SA23D/.approvals" | tr -d ' ')"
sa_confirm "$SA23D" "$(printf '1\nwithdraw %s\nCONFIRM\n' "$S_DB")" '2027-06-05T09:00:00Z'; SA23D_RC=$?
SA23D_POST="$(wc -l < "$SA23D/.approvals" | tr -d ' ')"
SA23D_LAST=''; while IFS= read -r saline; do SA23D_LAST="$saline"; done < "$SA23D/.approvals"
SA23D_REC="$(cat "$SA23D/.change-confirmed")"
SA23D_WANT="$(printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=1' "$S_DB")"
SA23D_ST="$(sa_state "$SA23D")"
if [ "$SA23D_RC" -eq 0 ] && [ $((SA23D_POST - SA23D_PRE)) -eq 1 ] && [ "$SA23D_LAST" = "organizer-stated zqa1 withdraw $S_DB 2027-06-05T09:00:00Z" ] && [ "$SA23D_REC" = "$SA23D_WANT" ] && [ "$SA23D_ST" = none-pending ]; then
  PASS "S23d: C1 — on a published plan, confirm records a withdrawal as exactly one organizer-stated ledger line, the approval record's count drops to 1 with its date kept, and the gate still reads the published plan unchanged (none-pending); the site's count changes at the next rebuild"
else
  FAIL "S23d: rc=$SA23D_RC, ledger lines $SA23D_PRE -> $SA23D_POST, last '$SA23D_LAST', record [${SA23D_REC//$'\n'/ | }], state '$SA23D_ST' — a withdrawal after publication is not recordable as C1 requires"
fi

# ── S23e — C1: A REVERTED PLAN RE-ANCHORS AT THE TERMINAL. Approvals were recorded for a plan
# that was then abandoned — the record names it — and the working copy is back on the published
# plan, whose own approvals meet the threshold. confirm, recording nothing, re-anchors the record
# to the published plan rather than leaving the site stating the abandoned plan's code.
SA23E="$(sa_trip s23e 14:00 "$S_DA")"
sa_declare "$SA23E" 1 zqa1
sa_rec "$SA23E" zqa1 approve "$S_DA"; sa_rec "$SA23E" zqa1 approve "$S_DB"
printf 'digest=%s\nconfirmed=2027-06-03T09:00:00Z\napproval-count=1\n' "$S_DB" > "$SA23E/.change-confirmed"
sa_confirm "$SA23E" $'\n' '2027-06-06T09:00:00Z'; SA23E_RC=$?
SA23E_REC="$(cat "$SA23E/.change-confirmed")"
SA23E_WANT="$(printf 'digest=%s\nconfirmed=2027-06-06T09:00:00Z\napproval-count=1' "$S_DA")"
if [ "$SA23E_RC" -eq 0 ] && [ "$SA23E_REC" = "$SA23E_WANT" ]; then
  PASS "S23e: C1 — with the plan reverted to the published one and that plan's own approvals meeting the threshold, confirm (recording nothing) re-anchors the approval record to the published plan, dated at the act; the abandoned plan's code leaves the next build"
else
  FAIL "S23e: rc=$SA23E_RC, record [${SA23E_REC//$'\n'/ | }] — the reverted plan did not re-anchor, so the site keeps the abandoned code and every push refuses until the window closes"
fi

# ── S23f — C1: THE RETIRE, and what refusing it leaves. On a trip published before its
# declaration existed, the published plan has no approvals of its own; the record names an
# abandoned plan. Declining the offer writes nothing. Accepting it rewrites the record to name the
# published plan with no approval count, and keeps the replaced bytes beside it.
SA23F="$(sa_trip s23f 14:00 "$S_DA")"
sa_declare "$SA23F" 1 zqa1
sa_rec "$SA23F" zqa1 approve "$S_DB"
printf 'digest=%s\nconfirmed=2027-06-03T09:00:00Z\napproval-count=1\n' "$S_DB" > "$SA23F/.change-confirmed"
cp "$SA23F/.change-confirmed" "$WORK/sa23f.before"
sa_confirm "$SA23F" "$(printf '\nno\n')" '2027-06-07T09:00:00Z'; SA23F_RC1=$?
SA23F_SAME=0; cmp -s "$WORK/sa23f.before" "$SA23F/.change-confirmed" && SA23F_SAME=1
SA23F_KEPT1=0; for saf in "$SA23F"/.change-confirmed.replaced-*; do [ -e "$saf" ] && SA23F_KEPT1=$((SA23F_KEPT1+1)); done
sa_confirm "$SA23F" "$(printf '\nCONFIRM\n')" '2027-06-07T09:00:00Z'; SA23F_RC2=$?
SA23F_REC="$(cat "$SA23F/.change-confirmed")"
SA23F_WANT="$(printf 'digest=%s\nconfirmed=2027-06-07T09:00:00Z' "$S_DA")"
SA23F_KEPT=0; SA23F_KEPTSAME=0
for saf in "$SA23F"/.change-confirmed.replaced-*; do
  if [ -e "$saf" ]; then SA23F_KEPT=$((SA23F_KEPT+1)); cmp -s "$saf" "$WORK/sa23f.before" && SA23F_KEPTSAME=1; fi
done
if [ "$SA23F_RC1" -eq 0 ] && [ "$SA23F_SAME" -eq 1 ] && [ "$SA23F_KEPT1" -eq 0 ] && [ "$SA23F_RC2" -eq 0 ] && [ "$SA23F_REC" = "$SA23F_WANT" ] && [ "$SA23F_KEPT" -eq 1 ] && [ "$SA23F_KEPTSAME" -eq 1 ]; then
  PASS "S23f: C1 — declining the retire leaves the record byte-identical and keeps no copy; accepting it rewrites the record to name the published plan with no approval count, dated at the act, and keeps the replaced record beside it byte for byte (ADR-007 § 2's replace-with-preservation shape)"
else
  FAIL "S23f: declined rc=$SA23F_RC1 unchanged=$SA23F_SAME copies=$SA23F_KEPT1; accepted rc=$SA23F_RC2 record [${SA23F_REC//$'\n'/ | }] copies=$SA23F_KEPT identical=$SA23F_KEPTSAME"
fi

# ── S23g — CONTROL: a trip that declares no approvers is untouched by C1. confirm on its
# unchanged plan still refuses with the shipped "nothing to confirm" message, word for word, and
# writes nothing.
SA23G="$(sa_trip s23g 14:00 "$S_DA")"
SA23G_ERR="$( ( cmd_confirm "$SA23G" ) </dev/null 2>&1 >/dev/null )"; SA23G_RC=$?
SA23G_SHIPPED="nothing to confirm for $SA23G — the itinerary content of the outgoing render is the plan that is already published (or the trip has never been published). Confirmation binds to a change; there is none."
SA23G_SAME=0; case "$SA23G_ERR" in *"$SA23G_SHIPPED") SA23G_SAME=1 ;; esac
# ARMED-RED: were the declared branch taken by a trip that declares nothing, the shipped refusal
# would be gone — injected by a policy that answers `declared` for every trip, then restored.
_approval_policy() { printf declared; }
SA23G_MERR="$( ( cmd_confirm "$SA23G" ) </dev/null 2>&1 >/dev/null )"
sa_restore _approval_policy
SA23G_MSAME=0; case "$SA23G_MERR" in *"$SA23G_SHIPPED") SA23G_MSAME=1 ;; esac
if [ "$SA23G_RC" -ne 0 ] && [ "$SA23G_SAME" -eq 1 ] && [ ! -e "$SA23G/.change-confirmed" ] && [ ! -e "$SA23G/.approvals" ] && [ "$SA23G_MSAME" -eq 0 ]; then
  PASS "S23g: CONTROL — on a trip that declares no approvers, confirm over an unchanged plan still refuses with the shipped 'nothing to confirm' message word for word and writes nothing; C1's reordering reaches the declared branch alone. ARMED-RED — a policy answering 'declared' for this trip loses that message"
else
  FAIL "S23g: an undeclared trip's confirm returned rc=$SA23G_RC with the shipped message=$SA23G_SAME (want 1); under the all-declared mutant the message survived=$SA23G_MSAME (want 0)"
fi

# ── S23h — #719's Stage 7 F-02: ONCE THE PLAN IS PUBLISHED, A TERMINAL ACT KEEPS THE DATE. The plan
# is published — the baseline is its own digest — and the approval record names it: 3 of 3 approved
# at 2 of 3, dated 2027-06-01. A withdrawal that keeps the threshold met, and then a bare Enter, each
# rewrite the count alone and keep confirmed=, so no later act revives a recently-updated notice for
# a plan that did not change; and confirm no longer tells the organizer the record is dated now.
# CONTROL — the plan not yet published (C2's T + 8 case, S21f's shape): the same bare Enter still
# re-stamps confirmed= at its own time, so a late push can be preceded by a refresh. ARMED-RED — with
# _baseline_matches answering "not published", the same bare Enter on a fresh copy moves the date:
# this arm sees the re-stamp it guards against. The stub is withdrawn here, and S26a checks it.
sa23h_fixture() { # <name> <baseline-digest> -> a declaring trip, 3 of 3 approved at 2 of 3, record dated 06-01
  local d
  d="$(sa_trip "$1" 16:30 "$2")"
  sa_declare "$d" 2 zqa1 zqb2 zqc3
  for sak in zqa1 zqb2 zqc3; do sa_rec "$d" "$sak" approve "$S_DB"; done
  printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=3\n' "$S_DB" > "$d/.change-confirmed"
  printf '%s' "$d"
}
SA23H="$(sa23h_fixture s23h "$S_DB")"
sa_confirm "$SA23H" "$(printf '3\nwithdraw %s\nCONFIRM\n' "$S_DB")" '2027-06-21T09:00:00Z'; SA23H_RC1=$?
SA23H_R1="$(cat "$SA23H/.change-confirmed")"
sa_confirm "$SA23H" $'\n' '2027-06-23T09:00:00Z'; SA23H_RC2=$?
SA23H_R2="$(cat "$SA23H/.change-confirmed")"
SA23H_NOW=0; case "$(cat "$WORK/sa_conf.out")" in *"dated now"*) SA23H_NOW=1 ;; esac
SA23H_WANT="$(printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=2' "$S_DB")"
SA23H_ST="$(sa_state "$SA23H")"
SA23H2="$(sa23h_fixture s23h2 "$S_DA")"
sa_confirm "$SA23H2" $'\n' '2027-06-23T09:00:00Z'; SA23H_RC3=$?
SA23H_R3="$(cat "$SA23H2/.change-confirmed")"
SA23H_WANT3="$(printf 'digest=%s\nconfirmed=2027-06-23T09:00:00Z\napproval-count=3' "$S_DB")"
SA23H3="$(sa23h_fixture s23h3 "$S_DB")"
_baseline_matches() { return 1; }   # MUTANT: the published plan reads as not yet published
sa_confirm "$SA23H3" $'\n' '2027-06-23T09:00:00Z'
sa_restore _baseline_matches
SA23H_MKEPT=0; case "$(cat "$SA23H3/.change-confirmed")" in *'confirmed=2027-06-01T09:00:00Z'*) SA23H_MKEPT=1 ;; esac
if [ "$SA23H_RC1" -eq 0 ] && [ "$SA23H_R1" = "$SA23H_WANT" ] && [ "$SA23H_RC2" -eq 0 ] && [ "$SA23H_R2" = "$SA23H_WANT" ] && [ "$SA23H_NOW" -eq 0 ] && [ "$SA23H_ST" = none-pending ] && [ "$SA23H_RC3" -eq 0 ] && [ "$SA23H_R3" = "$SA23H_WANT3" ] && [ "$SA23H_MKEPT" -eq 0 ]; then
  PASS "S23h: F-02 — on a published plan at 2 of 3, a withdrawal that keeps the threshold met and then a bare Enter each rewrite only the count (3 -> 2) and keep confirmed= at 2027-06-01, confirm does not say the record is dated now, and the gate still reads the plan unchanged; CONTROL — before publication the same bare Enter re-stamps confirmed= to its own time (C2's T + 8 case); ARMED-RED — with the plan read as unpublished the date moves"
else
  FAIL "S23h: withdrawal rc=$SA23H_RC1 record [${SA23H_R1//$'\n'/ | }]; bare Enter rc=$SA23H_RC2 record [${SA23H_R2//$'\n'/ | }] (want both [${SA23H_WANT//$'\n'/ | }]); 'dated now' printed=$SA23H_NOW (want 0); state '$SA23H_ST' (want none-pending); unpublished control rc=$SA23H_RC3 record [${SA23H_R3//$'\n'/ | }] (want [${SA23H_WANT3//$'\n'/ | }]); unpublished-reading mutant kept the date=$SA23H_MKEPT (want 0)"
fi

# ── S23i — #719's item 8, THE ABANDONED-CHANGE EXIT (the operator's decision, option B). A change
# raised after the published plan's approval record was dated, and abandoned before any approval,
# leaves an entry the mapping reads as undecided while the working copy is back on the published
# plan: the band reads `pending`, and under item 7's kept date alone no terminal act clears it. The
# fixture: a declaring trip at 2 of 3 whose plan is published and approved by all three, its record
# dated 2027-06-01, with the plan's own entry (2027-05-30) and the abandoned change's (2027-06-05) in
# its change summary. SUBJECT: a bare Enter on 2027-06-10 re-stamps confirmed= at the act, adds no
# ledger line and says "dated now"; the render built THROUGH THE MAPPING on 2027-06-11 (sa_build)
# resolves `updated` · 2027-06-10 with the plan's own count and code; update passes both guards and
# reaches the clone; and the gate reads the published plan unchanged before and after. ARMED-RED:
# with _undecided_entry reading no entry — the writer as it stood before this exit — the same Enter
# on a fresh copy keeps 2027-06-01 and the rebuilt band stays `pending`. CONTROLS: entries dated
# 2027-05-30 and the approval's own day keep the date, so "later than" is strict, as the mapping's
# is; a summary that cannot be read (a dangling link) keeps it, and so does one whose only later
# headings are not dated entries — the stated fail direction, which never puts a false "recently
# updated" on the site; and a trip that declares nobody, with the same history, is refused by
# confirm with the shipped message word for word, its record byte-unchanged. The push mocks S21l
# withdrew are re-evaluated for this arm and withdrawn again at its end.
sa23i_fixture() { # <name> [<entry-date>...] -> a declaring trip at 2 of 3, published, approved 3 of 3, record dated 06-01
  local d n="$1" sak; shift
  d="$(sa_ptrip "$n" '' '' 16:30 "$SA_P16" pending)"
  sa_declare "$d" 2 zqa1 zqb2 zqc3
  for sak in zqa1 zqb2 zqc3; do sa_rec "$d" "$sak" approve "$SA_P16"; done
  printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=3\n' "$SA_P16" > "$d/.change-confirmed"
  if [ $# -gt 0 ]; then t6_trip "$d" "$@" >/dev/null; fi
  printf '%s' "$d"
}
eval "$SA_MOCK_GH"; eval "$SA_MOCK_NPX"
SA23I_KEPT_WANT="$(printf 'digest=%s\nconfirmed=2027-06-01T09:00:00Z\napproval-count=3' "$SA_P16")"
# The subject.
SA23I="$(sa23i_fixture s23i 2027-05-30 2027-06-05)"
SA23I_ST0="$(sa_state "$SA23I")"
SA23I_B0="$(sa_build "$SA23I" 16:30 2027-06-06)"
SA23I_L0="$(wc -l < "$SA23I/.approvals" | tr -d ' ')"
sa_confirm "$SA23I" $'\n' '2027-06-10T09:00:00Z'; SA23I_RC=$?
SA23I_OUT="$(cat "$WORK/sa_conf.out")"
SA23I_REC="$(cat "$SA23I/.change-confirmed")"
SA23I_WANT="$(printf 'digest=%s\nconfirmed=2027-06-10T09:00:00Z\napproval-count=3' "$SA_P16")"
SA23I_L1="$(wc -l < "$SA23I/.approvals" | tr -d ' ')"
SA23I_NOW=0; case "$SA23I_OUT" in *"dated now"*) SA23I_NOW=1 ;; esac
SA23I_KEEPS=0; case "$SA23I_OUT" in *"keeps the date"*) SA23I_KEEPS=1 ;; esac
SA23I_B1="$(sa_build "$SA23I" 16:30 2027-06-11)"
SA23I_SINCE=''
while IFS= read -r saline; do case "$saline" in coordination-since:*) SA23I_SINCE="${saline#coordination-since: }" ;; esac; done < "$SA23I/outputs/porto-travel-site.html"
read -r SA23I_NC SA23I_NK SA23I_CODE <<<"$(_render_approval_pair "$SA23I/outputs/porto-travel-site.html")"
read -r SA_RC SA23I_CL _ _ <<<"$(sa_push update "$SA23I")"
SA23I_ST1="$(sa_state "$SA23I")"
# ARMED-RED — the writer reading no entry date, swapped in and restored.
SA23IM="$(sa23i_fixture s23im 2027-05-30 2027-06-05)"
_undecided_entry() { return 1; }   # MUTANT: no entry is ever read, so item 7's kept date has no exception
sa_confirm "$SA23IM" $'\n' '2027-06-10T09:00:00Z'
sa_restore _undecided_entry
SA23IM_KEPT=0; case "$(cat "$SA23IM/.change-confirmed")" in *'confirmed=2027-06-01T09:00:00Z'*) SA23IM_KEPT=1 ;; esac
SA23IM_B="$(sa_build "$SA23IM" 16:30 2027-06-11)"
# CONTROL — no entry later than the record: one before it, and one on the approval's own day.
SA23IC="$(sa23i_fixture s23ic 2027-05-30 2027-06-01)"
sa_confirm "$SA23IC" $'\n' '2027-06-10T09:00:00Z'; SA23IC_RC=$?
SA23IC_REC="$(cat "$SA23IC/.change-confirmed")"
SA23IC_KEEPS=0; case "$(cat "$WORK/sa_conf.out")" in *"keeps the date"*) SA23IC_KEEPS=1 ;; esac
# CONTROL — the fail direction: a summary present as a dangling link, which cannot be read.
SA23ID="$(sa23i_fixture s23id)"
ln -s "$WORK/zzq-no-such-summary.md" "$SA23ID/outputs/change-summary.md"
sa_confirm "$SA23ID" $'\n' '2027-06-10T09:00:00Z'; SA23ID_RC=$?
SA23ID_REC="$(cat "$SA23ID/.change-confirmed")"
# CONTROL — later headings that are not dated entries: neither reader counts them.
SA23IH="$(sa23i_fixture s23ih 2027-05-30)"
printf -- '### 2027-06-05 — a sub-heading\n\n## 2027-6-5 — a heading with no YYYY-MM-DD date\n\n' >> "$SA23IH/outputs/change-summary.md"
sa_confirm "$SA23IH" $'\n' '2027-06-10T09:00:00Z'; SA23IH_RC=$?
SA23IH_REC="$(cat "$SA23IH/.change-confirmed")"
SA23IH_MAP="$(t6_newest_entry "$SA23IH/outputs/change-summary.md")"
# CONTROL — a trip that declares nobody, with the same history: the organizer's two-line record
# names the published plan, and the abandoned change's entry post-dates it.
SA23IU="$(sa_ptrip s23iu '' '' 16:30 "$SA_P16" pending)"
s_record "$SA23IU/.change-confirmed" "$SA_P16" confirmed
t6_trip "$SA23IU" 2027-05-30 2027-06-05 >/dev/null
cp "$SA23IU/.change-confirmed" "$WORK/sa23iu.before"
SA23IU_ERR="$( ( cmd_confirm "$SA23IU" ) </dev/null 2>&1 >/dev/null )"; SA23IU_RC=$?
SA23IU_SHIPPED="nothing to confirm for $SA23IU — the itinerary content of the outgoing render is the plan that is already published (or the trip has never been published). Confirmation binds to a change; there is none."
SA23IU_SAME=0; case "$SA23IU_ERR" in *"$SA23IU_SHIPPED") SA23IU_SAME=1 ;; esac
SA23IU_KEPT=0; cmp -s "$WORK/sa23iu.before" "$SA23IU/.change-confirmed" && SA23IU_KEPT=1
unset -f gh npx
if [ "$SA23I_ST0" = none-pending ] && [ "$SA23I_B0" = pending ] && [ "$SA23I_RC" -eq 0 ] && [ "$SA23I_REC" = "$SA23I_WANT" ] && [ "$SA23I_L1" = "$SA23I_L0" ] && [ "$SA23I_NOW" -eq 1 ] && [ "$SA23I_KEEPS" -eq 0 ] \
   && [ "$SA23I_B1" = updated ] && [ "$SA23I_SINCE" = 2027-06-10 ] && [ "$SA23I_NC" -eq 1 ] && [ "$SA23I_NK" -eq 1 ] && [ "$SA23I_CODE" = "$SA_P16" ] && [ "$SA23I_CL" -eq 1 ] && [ "$SA23I_ST1" = none-pending ] \
   && [ "$SA23IM_KEPT" -eq 1 ] && [ "$SA23IM_B" = pending ] \
   && [ "$SA23IC_RC" -eq 0 ] && [ "$SA23IC_REC" = "$SA23I_KEPT_WANT" ] && [ "$SA23IC_KEEPS" -eq 1 ] \
   && [ "$SA23ID_RC" -eq 0 ] && [ "$SA23ID_REC" = "$SA23I_KEPT_WANT" ] \
   && [ "$SA23IH_RC" -eq 0 ] && [ "$SA23IH_REC" = "$SA23I_KEPT_WANT" ] && [ "$SA23IH_MAP" = 2027-05-30 ] \
   && [ "$SA23IU_RC" -ne 0 ] && [ "$SA23IU_SAME" -eq 1 ] && [ "$SA23IU_KEPT" -eq 1 ]; then
  PASS "S23i: item 8 — on a published plan at 2 of 3 whose record is dated before an abandoned change's entry, the build reads 'pending'; a bare Enter re-stamps confirmed= to the act, adds no ledger line and says 'dated now'; the render built through the mapping resolves 'updated' · 2027-06-10 with the plan's own count and code, update passes both guards to the clone, and the gate reads none-pending throughout. ARMED-RED — a writer reading no entry keeps the date and the band stays 'pending'; CONTROLS — an entry on or before the record's day keeps the date, an unreadable summary and later non-entry headings keep it (the fail direction), and an undeclared trip with the same history is refused word for word with its record untouched"
else
  FAIL "S23i: gate before '$SA23I_ST0' (want none-pending), first build '$SA23I_B0' (want pending), Enter rc=$SA23I_RC record [${SA23I_REC//$'\n'/ | }] (want [${SA23I_WANT//$'\n'/ | }]), ledger lines $SA23I_L0 -> $SA23I_L1, 'dated now'=$SA23I_NOW 'keeps the date'=$SA23I_KEEPS (want 1 and 0); rebuilt '$SA23I_B1' since '$SA23I_SINCE' (want updated, 2027-06-10), pair $SA23I_NC/$SA23I_NK code-own=$([ "$SA23I_CODE" = "$SA_P16" ] && echo 1 || echo 0), clone=$SA23I_CL, gate after '$SA23I_ST1'; mutant kept the date=$SA23IM_KEPT band '$SA23IM_B' (want 1, pending); no-later-entry control rc=$SA23IC_RC record [${SA23IC_REC//$'\n'/ | }] keeps-message=$SA23IC_KEEPS; dangling-link control rc=$SA23ID_RC record [${SA23ID_REC//$'\n'/ | }]; non-entry-heading control rc=$SA23IH_RC record [${SA23IH_REC//$'\n'/ | }] mapping newest '$SA23IH_MAP'; undeclared control rc=$SA23IU_RC shipped-message=$SA23IU_SAME record untouched=$SA23IU_KEPT"
fi

# ── S24a — ERASURE (#719 INT-10). Substituting one approver's key with the erasure token's key
# form in BOTH sidecars, in one step, leaves the token and the tally unchanged. CONTROL: the same
# substitution in the declaration alone orphans that approver's records, and the plan is held —
# which is why reach row 31 writes both files in one step.
SA24="$(sa_trip s24 16:30 "$S_DA")"
sa_declare "$SA24" all zqa1 zqb2 zqc3
for sak in zqa1 zqb2 zqc3; do sa_rec "$SA24" "$sak" approve "$S_DB"; done
SA24_BEFORE="$(sa_state "$SA24")/$(_approval_tally "$SA24" "$S_DB")"
sa24_sub() { # <file> — the subject's key replaced by the token's key form, wherever it is a whole field
  local f="$1" line out=''
  while IFS= read -r line; do
    case "$line" in
      approver=zqa1) line='approver=per3c7e' ;;
      'organizer-stated zqa1 '*) line="organizer-stated per3c7e ${line#organizer-stated zqa1 }" ;;
    esac
    out="$out$line
"
  done < "$f"
  printf '%s' "$out" > "$f"
}
SA24C="$(sa_trip s24c 16:30 "$S_DA")"
cp "$SA24/.approvers" "$SA24/.approvals" "$SA24C/"
sa24_sub "$SA24/.approvers"; sa24_sub "$SA24/.approvals"
sa24_sub "$SA24C/.approvers"
SA24_AFTER="$(sa_state "$SA24")/$(_approval_tally "$SA24" "$S_DB")"
SA24_CTL="$(sa_state "$SA24C")"
if [ "$SA24_BEFORE" = 'confirmed/3 3 0' ] && [ "$SA24_AFTER" = "$SA24_BEFORE" ] && [ "$SA24_CTL" = unconfirmed ]; then
  PASS "S24a: replacing an approver's key with the erasure token's key form in both sidecars leaves the verdict and the tally unchanged ($SA24_AFTER); the control, the declaration alone, reads '$SA24_CTL' — so the row must write both files in one step"
else
  FAIL "S24a: before '$SA24_BEFORE', after both files '$SA24_AFTER' (want equal, confirmed/3 3 0), declaration-only control '$SA24_CTL' (want unconfirmed)"
fi

# ── S25a — NAME-FREEDOM, STATED OVER APPROVER-NESS (#718's FM-4). Two trips share one
# five-member roster, one outgoing plan and a count of 2, and differ only in who is declared and
# who approved. With the clock pinned, the approval records the two writes produce are
# BYTE-IDENTICAL, so no input the site build reads can tell which roster members are approvers.
# ARMED-RED: a writer that let the keys into the record makes the two differ.
SA25_ROSTER='## Group\n\n| Person | Notes |\n|---|---|\n| Aria | — |\n| Beno | — |\n| Cass | — |\n| Dara | — |\n| Enzo | — |\n'
SA25A="$(sa_trip s25a 16:30 "$S_DA")"; SA25B="$(sa_trip s25b 16:30 "$S_DA")"
# shellcheck disable=SC2059  # the roster literal carries only \n escapes
printf "$SA25_ROSTER" > "$SA25A/trip-context.md"; cp "$SA25A/trip-context.md" "$SA25B/trip-context.md"
sa_declare "$SA25A" 2 aria beno; sa_rec "$SA25A" aria approve "$S_DB"; sa_rec "$SA25A" beno approve "$S_DB"
sa_declare "$SA25B" 2 cass dara; sa_rec "$SA25B" cass approve "$S_DB"; sa_rec "$SA25B" dara approve "$S_DB"
_iso_now() { printf '2027-06-02T09:00:00Z'; }
_record_threshold_met "$SA25A" "$S_DB"; _record_threshold_met "$SA25B" "$S_DB"
SA25_SAME=0; cmp -s "$SA25A/.change-confirmed" "$SA25B/.change-confirmed" && SA25_SAME=1
SA25_DIFFDECL=0; cmp -s "$SA25A/.approvers" "$SA25B/.approvers" || SA25_DIFFDECL=1
SA25_DIFFLEDG=0; cmp -s "$SA25A/.approvals" "$SA25B/.approvals" || SA25_DIFFLEDG=1
SA25M1="$(sa_trip s25m1 16:30 "$S_DA")"; SA25M2="$(sa_trip s25m2 16:30 "$S_DA")"
cp "$SA25A/.approvers" "$SA25A/.approvals" "$SA25M1/"; cp "$SA25B/.approvers" "$SA25B/.approvals" "$SA25M2/"
_record_threshold_met() { # MUTANT: the record names who approved
  local rec; rec="$(change_confirmation_path "$1")"
  printf 'digest=%s\nconfirmed=%s\napproval-count=2\napprovers=%s\n' "$2" "$(_iso_now)" "$(tr '\n' ' ' < "$1/.approvers")" > "$rec"
}
_record_threshold_met "$SA25M1" "$S_DB"; _record_threshold_met "$SA25M2" "$S_DB"
sa_restore _record_threshold_met; sa_restore _iso_now
SA25_MDIFF=0; cmp -s "$SA25M1/.change-confirmed" "$SA25M2/.change-confirmed" || SA25_MDIFF=1
if [ "$SA25_SAME" -eq 1 ] && [ "$SA25_DIFFDECL" -eq 1 ] && [ "$SA25_DIFFLEDG" -eq 1 ] && [ "$SA25_MDIFF" -eq 1 ]; then
  PASS "S25a: two trips with one roster, one plan and a count of 2, differing only in who is declared and who approved, produce BYTE-IDENTICAL approval records — while their declarations and ledgers differ (sensitivity); ARMED-RED — a writer that let the keys in makes the records differ"
else
  FAIL "S25a: records identical=$SA25_SAME (want 1), declarations differ=$SA25_DIFFDECL, ledgers differ=$SA25_DIFFLEDG (want 1 and 1), key-writing mutant differs=$SA25_MDIFF (want 1)"
fi

# ── S26a — THE RESTORE (S15j's rule, applied to this block). Every production function an arm
# above stubbed or mutated reads exactly as saved, none of the external commands stubbed here is
# still a shell function, and a fresh render digests to the SHA-256 token S0 read.
SA26_MOVED=""
for safn in $SA_SAVED_FNS; do
  sav="SA_SAVED_$safn"
  if [ "$(declare -f "$safn")" != "${!sav}" ]; then SA26_MOVED="$SA26_MOVED $safn"; fi
done
SA26_STUBS=""
for safn in mv gh npx perl tr; do
  declare -F "$safn" >/dev/null 2>&1 && SA26_STUBS="$SA26_STUBS $safn"
done
s_render "$WORK/sa26.html" 14:00 none
SA26_DG="$(itinerary_digest "$WORK/sa26.html")"
SA26_HEX=0; case "$SA26_DG" in *[!0123456789abcdef]*|'') ;; *) [ "${#SA26_DG}" -eq 64 ] && SA26_HEX=1 ;; esac
if [ -z "$SA26_MOVED" ] && [ -z "$SA26_STUBS" ] && [ "$SA26_HEX" -eq 1 ] && [ "$SA26_DG" = "$S_DA" ]; then
  PASS "S26a: every production function this block stubbed or mutated reads exactly as saved, no stubbed external command is still a function, and a fresh render digests to S0's SHA-256 token — the arms after this one grade production code"
else
  FAIL "S26a: functions not restored:[${SA26_MOVED# }], stubs left:[${SA26_STUBS# }], fresh digest '$SA26_DG' against S0's '$S_DA'"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group S, #1468 — THE BASELINE THE GATE COMPARES AGAINST
#
# Every verdict from S0 to S26a reads the published baseline, .published-itinerary, and none
# grades what writes it after a push, what a push leaves when it cannot be written, or what the
# gate does with one that is present and cannot be used. This block grades the recorder that
# writes it and the classifier that reads it.
#
#   S27a  THE RECORDER'S OWN WARNING — the staging step failing after a push, on a trip with no
#         baseline, warns NOT ACTIVE, returns 0 under errexit and writes no sidecar
#   S27b  every failure the recorder meets — mktemp refusing, mktemp naming a path under a missing
#         directory, mv refusing — on a trip with no baseline, on one whose baseline records
#         another plan and on one whose baseline is present but unusable, and the sidecar's path
#         a directory (S27b′): each warns by the state it leaves, returns 0, keeps the sidecar
#         byte-identical and leaves no temporary; control: unstubbed, it writes the sidecar;
#         ARMED-RED: the shipped recorder's silent `mktemp … || return 0` is convicted
#   S28a  CASE 5 — nine shapes of a present but unusable baseline, on both policies and both
#         renders, all resolve `undetermined`; six controls keep their verdicts, a legacy CRC
#         baseline included; ARMED-RED: the old fold reads one of them `none-pending`
#   S28b  the gate refuses each unusable shape naming the file and making no claim about change
#   S28c  update, end to end, refuses before any clone — the Success Indicator's arm
#   S28d  confirm refuses each shape on both policies before its terminal check
#   S28e  the classifier itself: nine shapes `unusable`, absence `absent`, a token itself
#   S29a  CASES 2 AND 4 AT THE SOURCE — publish refuses a render nothing can read before the repo
#         is probed or created
#   S29b  update on an ungated trip with no baseline refuses the same render before any clone
#   S29c  the other two refusals — a baseline that cannot be staged, a sidecar path that is not a
#         regular file — on update, publish and rotate, rotate leaving .passphrase as it was
#   S29d  structural: the guard's place in require_publish_guards and in publish, publish ungated
#   S27c  a trip that declares approvers, or whose approval sidecars are malformed, is never told
#         NOT ACTIVE, and each is told the exit that works on it
#   S27d  a trip directory that loses write between the staging and the move still gets the
#         warning and rc 0: the clean-up of the temporary cannot end the command after a push
#   S27e  a push that re-published the recorded plan, with no record written, is told the kept
#         baseline records this same plan
#   S29e  the guard's probe is skipped for a push that re-publishes the recorded plan, and not
#         where another plan's record is outstanding
#   S31a  D-6 — a staged record holds exactly the verdicts that rest on which plan is live
#   S31b  S31c  the gate and confirm refuse a held trip, naming the outstanding record
#   S31d  the stager writes the push's record, refuses when it cannot, and stages nothing on a
#         re-publish
#   S31e  the recorder on every state the staged record can be in after the push
#   S31f  S31g  the push sites as built: guard < stager < push < recorder, and only `info` or
#         `cd` between a stager and its push
#   S31h  the digest the stager hands back
#   S31i  the order in which a refusal names its cause, and the exits each one offers
#   S30a  CASE 1 — the 18 code points macOS's UTF-8 [:space:] holds digest as a space under
#         LC_ALL=C and under a UTF-8 locale; ARMED-RED: the unpinned body is convicted
#   S30b  code points outside the set still read as text; the legacy digest moves with the pin
#   S30c  a byte that is not valid UTF-8 digests the same under both locales
#   S30d  THE RESTORE — every production function this block saved reads exactly as saved, and
#         none of the commands its arms stub is still a function
#
# HOW THE ARMS ARE WRITTEN — group S15's three rules, unchanged. Every negative is a captured
# value inside a `[ … ]` conjunction that leads to a PASS; nothing is read through a pipeline into
# an early-exiting grep (group PF); every stub is withdrawn in the arm that set it, and an
# ARMED-RED mutant is withdrawn by re-evaluating the production definition saved below, S16's
# SA_SAVED_* idiom. No group letter is minted: RS reduces every id to its leading capitals.
#
# Offline: $WORK fixtures and shell-function stubs. No network, no Node, no TTY. No legitimate
# skip, and deliberately NOT declared in GUARD_EXPECTED_SKIPS.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "The baseline the gate compares against (#1468):"

# Every production function an arm below stubs or mutates, saved before any arm runs. sb_restore
# re-evaluates the saved text; S30d compares each against it.
SB_SAVED_FNS='change_confirmation_state _baseline_record record_published_itinerary require_recordable_baseline itinerary_digest _legacy_itinerary_digest staged_record_path'
for sbfn in $SB_SAVED_FNS; do
  eval "SB_SAVED_${sbfn}=\"\$(declare -f ${sbfn})\""
done
sb_restore() { # <fn> — the saved production definition, re-evaluated; unset where none was saved
  local v="SB_SAVED_$1"
  if [ -n "${!v}" ]; then eval "${!v}"; else unset -f "$1"; fi
}
# The staging primitive's temporaries beside a trip's sidecar: mktemp's six-character suffix.
sb_temps() { local n=0 f; for f in "$1"/.published-itinerary.??????; do [ -e "$f" ] && n=$((n+1)); done; printf '%s' "$n"; }

# ── S27a — THE RECORDER'S OWN WARNING (#1468 case 4). The staging step fails after a push on a
# trip that declares no approvers and has no baseline. The recorder must say the gate is NOT
# ACTIVE, return 0 under the errexit production runs it with — the after-marker is the proof that
# no failed step ended the command — and leave no sidecar behind. Registered: with the recorder
# removed its subshell exits 127 under errexit, so no marker prints and the verdict is a FAIL.
s27a_assert() {
  local d e rc aft=0 na=0 side=0
  d="$(s_fixture "s27a-$RANDOM" 14:00 none)"
  mktemp() { return 1; }
  e="$( ( set -e; record_published_itinerary "$d" "$d/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rc=$?
  unset -f mktemp
  case "$e" in *S27-AFTER*) aft=1 ;; esac
  case "$e" in *"NOT ACTIVE"*) na=1 ;; esac
  [ -e "$d/.published-itinerary" ] && side=1
  if [ "$rc" -eq 0 ] && [ "$aft" -eq 1 ] && [ "$na" -eq 1 ] && [ "$side" -eq 0 ]; then
    PASS "S27a: when the staging step fails after a push on a trip with no baseline, the recorder says the gate is NOT ACTIVE, returns 0 under errexit with the after-marker printed, and writes no sidecar"
  else
    FAIL "S27a: rc=$rc after-marker=$aft NOT-ACTIVE=$na sidecar=$side — the recorder stayed silent, ended the command, or left a sidecar it could not stage"
  fi
}
s27a_assert

# ── S27b — EVERY FAILURE THE RECORDER MEETS, ON EVERY STATE IT CAN LEAVE. Three failures, each on a
# trip with no baseline (marker N: NOT ACTIVE), on one whose baseline records another plan (marker
# K: keeps the baseline it already had) and on one whose baseline is present but unusable (marker
# U: present but cannot be used), nine cells; and S27b′'s tenth, the sidecar's path a directory,
# which needs no stub because the move lands the record inside it. Each must return 0 under
# errexit with the after-marker, carry its own state's marker and no other, leave the sidecar
# byte-identical (absent where there was none) and leave no temporary beside it; after the
# directory cell the classifier still reads the path `unusable`, and the record sits inside the
# directory rather than at the path. CONTROL: the recorder unstubbed on a trip with no baseline
# writes the sidecar and warns nothing, so "nothing written" above is a measurement of a writer
# that can write. ARMED-RED: the shipped recorder's body, whose `mktemp … || return 0` returns
# silently, is put back for the first cell and must leave no marker, then the production recorder
# is re-evaluated.
s27b_assert() {
  local f s d e rc aft n k u ok=1 why="" cells=0 c ce crc cn=0 ck=0 me mn=0 mk=0
  for f in mktemp-fails mktemp-missing mv-fails; do
    for s in absent kept unusable; do
      cells=$((cells+1))
      if [ "$s" = absent ]; then
        d="$(s_fixture "s27b-$f-$s-$RANDOM" 14:00 none)"
      elif [ "$s" = kept ]; then
        d="$(s_fixture "s27b-$f-$s-$RANDOM" 16:30 none)"; s_record "$d/.published-itinerary" "$S_DA" published; cp "$d/.published-itinerary" "$d.before"
      else
        d="$(s_fixture "s27b-$f-$s-$RANDOM" 16:30 none)"; printf 'published=2027-06-01T00:00:00Z\n' > "$d/.published-itinerary"; cp "$d/.published-itinerary" "$d.before"
      fi
      case "$f" in
        mktemp-fails)   mktemp() { return 1; } ;;
        mktemp-missing) mktemp() { printf '%s' "$WORK/zzq-s27b-no-such-dir/rec.XXXXXX"; } ;;
        mv-fails)       mv() { return 1; } ;;
      esac
      e="$( ( set -e; record_published_itinerary "$d" "$d/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rc=$?
      unset -f mktemp mv
      aft=0; n=0; k=0; u=0
      case "$e" in *S27-AFTER*) aft=1 ;; esac
      case "$e" in *"NOT ACTIVE"*) n=1 ;; esac
      case "$e" in *"keeps the baseline it already had"*) k=1 ;; esac
      case "$e" in *"present but cannot be used"*) u=1 ;; esac
      [ "$rc" -eq 0 ] && [ "$aft" -eq 1 ] || { ok=0; why="$why $f/$s:rc=$rc,after=$aft"; }
      [ "$(sb_temps "$d")" -eq 0 ] || { ok=0; why="$why $f/$s:temps=$(sb_temps "$d")"; }
      if [ "$s" = absent ]; then
        [ "$n$k$u" = 100 ] || { ok=0; why="$why $f/$s:marker=N$n/K$k/U$u"; }
        [ ! -e "$d/.published-itinerary" ] || { ok=0; why="$why $f/$s:sidecar-written"; }
      elif [ "$s" = kept ]; then
        [ "$n$k$u" = 010 ] || { ok=0; why="$why $f/$s:marker=N$n/K$k/U$u"; }
        cmp -s "$d.before" "$d/.published-itinerary" || { ok=0; why="$why $f/$s:sidecar-changed"; }
      else
        [ "$n$k$u" = 001 ] || { ok=0; why="$why $f/$s:marker=N$n/K$k/U$u"; }
        cmp -s "$d.before" "$d/.published-itinerary" || { ok=0; why="$why $f/$s:sidecar-changed"; }
      fi
    done
  done
  # S27b′ — the sidecar's path a directory. The move lands the record inside it, and the read-back
  # is what catches that: the classifier still reads the path `unusable`, the record sits inside
  # the directory, and nothing is left beside it.
  cells=$((cells+1))
  d="$(s_fixture "s27b-dir-$RANDOM" 16:30 none)"; mkdir -p "$d/.published-itinerary"
  e="$( ( set -e; record_published_itinerary "$d" "$d/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rc=$?
  aft=0; n=0; k=0; u=0
  case "$e" in *S27-AFTER*) aft=1 ;; esac
  case "$e" in *"NOT ACTIVE"*) n=1 ;; esac
  case "$e" in *"keeps the baseline it already had"*) k=1 ;; esac
  case "$e" in *"present but cannot be used"*) u=1 ;; esac
  [ "$rc" -eq 0 ] && [ "$aft" -eq 1 ] && [ "$n$k$u" = 001 ] || { ok=0; why="$why dir:rc=$rc,after=$aft,marker=N$n/K$k/U$u"; }
  [ "$(_baseline_record "$d/.published-itinerary")" = unusable ] && [ -d "$d/.published-itinerary" ] || { ok=0; why="$why dir:classified=$(_baseline_record "$d/.published-itinerary")"; }
  [ "$(sb_temps "$d/.published-itinerary")" -eq 1 ] && [ "$(sb_temps "$d")" -eq 0 ] || { ok=0; why="$why dir:inside=$(sb_temps "$d/.published-itinerary"),beside=$(sb_temps "$d")"; }
  c="$(s_fixture "s27b-ctl-$RANDOM" 14:00 none)"
  ce="$( ( set -e; record_published_itinerary "$c" "$c/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; crc=$?
  case "$ce" in *"NOT ACTIVE"*) cn=1 ;; esac
  case "$ce" in *"keeps the baseline it already had"*) ck=1 ;; esac
  d="$(s_fixture "s27b-mut-$RANDOM" 14:00 none)"
  record_published_itinerary() { # MUTANT: the shipped staging step, which returned silently
    local out tmp dg; out="$(published_itinerary_path "$1")"; dg="$(itinerary_digest "$2")"; [ -n "$dg" ] || return 0
    tmp="$(mktemp "${out}.XXXXXX")" || return 0; printf 'digest=%s\npublished=%s\n' "$dg" "$(_iso_now)" > "$tmp"; mv -f "$tmp" "$out"
  }
  mktemp() { return 1; }
  me="$( ( set -e; record_published_itinerary "$d" "$d/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"
  unset -f mktemp
  sb_restore record_published_itinerary
  case "$me" in *"NOT ACTIVE"*) mn=1 ;; esac
  case "$me" in *"keeps the baseline it already had"*) mk=1 ;; esac
  if [ "$crc" -ne 0 ] || [ "$(_record_digest "$c/.published-itinerary")" != "$S_DA" ] || [ "$cn" -ne 0 ] || [ "$ck" -ne 0 ]; then
    FAIL "S27b: CONTROL — the unstubbed recorder on a trip with no baseline returned rc=$crc, wrote '$(_record_digest "$c/.published-itinerary")' (want $S_DA) and warned N=$cn K=$ck (want neither), so the absence of a write below is not a measurement"
  elif [ "$ok" -eq 1 ] && [ "$cells" -eq 10 ] && [ "$mn" -eq 0 ] && [ "$mk" -eq 0 ]; then
    PASS "S27b: on each of $cells cells — mktemp refusing, mktemp naming a missing directory and mv refusing, each with no baseline, with a baseline of another plan and with one present but unusable, and the sidecar's path a directory — the recorder returns 0 under errexit, warns NOT ACTIVE, that it keeps the baseline it already had, or that the sidecar is present but cannot be used, by the state it leaves, keeps the sidecar byte-identical and leaves no temporary beside it, and the record moved into a directory is caught by the read-back; the control writes the sidecar; ARMED-RED: the shipped recorder's silent return leaves no marker, and the assertion convicts it"
  else
    FAIL "S27b: cells=$cells$why; ARMED-RED read N=$mn K=$mk (want neither)"
  fi
}
s27b_assert

# ── S28 — CASE 5: A BASELINE SIDECAR THAT IS PRESENT BUT CANNOT BE USED (#1468). ADR-007 § 2 makes
# absence and a malformed or truncated file different conditions and never the same branch, so
# each shape below must reach the gate as `undetermined`, never as "no baseline". s28_plant writes
# one of the nine shapes at a trip's sidecar path. The mode-000 shape takes L5b's form: a runner
# that can still read a 000 file gets a directory instead, a construct no privilege reads as a
# regular file, so every cell renders a verdict on every runner and none becomes a skip. S_LA is
# the legacy CRC token of the 14:00 render, which must still read as a baseline.
S28_SHAPES='dangling mode000 badtoken nodigest empty directory hex20 upper64 crlf'
s28_plant() { # <trip> <shape> — a present but unusable baseline sidecar, one of S28_SHAPES
  local f="$1/.published-itinerary"
  case "$2" in
    dangling)  ln -s "$1/zzq-no-such-baseline" "$f" ;;
    mode000)   s_record "$f" "$S_DA" published; chmod 000 "$f"
               if [ -r "$f" ]; then chmod 644 "$f"; rm -f "$f"; mkdir -p "$f"; fi ;;
    badtoken)  printf 'digest=not*a*digest\npublished=2027-06-01T00:00:00Z\n' > "$f" ;;
    nodigest)  printf 'published=2027-06-01T00:00:00Z\n' > "$f" ;;
    empty)     : > "$f" ;;
    directory) mkdir -p "$f" ;;
    hex20)     printf 'digest=0123456789abcdef0123\npublished=2027-06-01T00:00:00Z\n' > "$f" ;;
    upper64)   printf 'digest=%s\npublished=2027-06-01T00:00:00Z\n' "$(tr 'abcdef' 'ABCDEF' <<<"$S_DA")" > "$f" ;;
    crlf)      printf 'digest=%s\r\npublished=2027-06-01T00:00:00Z\r\n' "$S_DA" > "$f" ;;
  esac
}
s_render "$WORK/sb-la.html" 14:00 none; S_LA="$(_legacy_itinerary_digest "$WORK/sb-la.html")"

# ── S28a — THE SUBJECT. Nine shapes × {a trip that declares no approvers, one that declares one
# approver at threshold all} × {the 14:00 render, which is the baseline's own plan where one could
# be read, and the 16:30 render} — 36 trips, every one `undetermined`. Fixture integrity first:
# the mode-000 sidecar must not be a readable regular file. SIX CONTROLS keep their verdicts, so
# the 36 are not a resolver that answers `undetermined` to everything: no sidecar at all, on both
# policies; an S_DA baseline under its own plan and under a moved one; and a legacy CRC baseline
# under each — the last two are criterion 1's "a legacy CRC-shaped baseline still reads as a
# baseline". ARMED-RED: _baseline_record replaced by the old fold (a digest if _record_digest
# reads one, else `absent`) makes the undeclared, moved trip with no digest= line read
# none-pending, which the assertion convicts; the classifier is then re-evaluated from its saved
# text. Registered: with the resolver removed every state is empty.
s28a_assert() {
  local sh pol t d st n=0 got=0 bad="" integ=1 c1 c2 c3 c4 c5 c6 md mut
  for sh in $S28_SHAPES; do
    for pol in undeclared declared; do
      for t in 14:00 16:30; do
        n=$((n+1))
        d="$(s_fixture "s28a-$sh-$pol-${t%%:*}-$RANDOM" "$t" none)"
        [ "$pol" = undeclared ] || sa_declare "$d" all zqa1
        s28_plant "$d" "$sh"
        if [ "$sh" = mode000 ] && [ -f "$d/.published-itinerary" ] && [ -r "$d/.published-itinerary" ]; then integ=0; fi
        st="$(change_confirmation_state "$d" 2>/dev/null)"
        if [ "$st" = undetermined ]; then got=$((got+1)); else bad="$bad $sh/$pol/$t=${st:-empty}"; fi
      done
    done
  done
  d="$(s_fixture "s28a-c1-$RANDOM" 14:00 none)"; c1="$(change_confirmation_state "$d" 2>/dev/null)"
  d="$(s_fixture "s28a-c2-$RANDOM" 14:00 none)"; sa_declare "$d" all zqa1; c2="$(change_confirmation_state "$d" 2>/dev/null)"
  d="$(s_fixture "s28a-c3-$RANDOM" 14:00 none)"; s_record "$d/.published-itinerary" "$S_DA" published; c3="$(change_confirmation_state "$d" 2>/dev/null)"
  d="$(s_fixture "s28a-c4-$RANDOM" 16:30 none)"; s_record "$d/.published-itinerary" "$S_DA" published; c4="$(change_confirmation_state "$d" 2>/dev/null)"
  d="$(s_fixture "s28a-c5-$RANDOM" 14:00 none)"; s_record "$d/.published-itinerary" "$S_LA" published; c5="$(change_confirmation_state "$d" 2>/dev/null)"
  d="$(s_fixture "s28a-c6-$RANDOM" 16:30 none)"; s_record "$d/.published-itinerary" "$S_LA" published; c6="$(change_confirmation_state "$d" 2>/dev/null)"
  md="$(s_fixture "s28a-mut-$RANDOM" 16:30 none)"; s28_plant "$md" nodigest
  _baseline_record() { local t; t="$(_record_digest "${1:-}")"; if [ -n "$t" ]; then printf '%s' "$t"; else printf 'absent'; fi; }   # MUTANT: the old fold
  mut="$(change_confirmation_state "$md" 2>/dev/null)"
  sb_restore _baseline_record
  if [ "$integ" -ne 1 ]; then
    FAIL "S28a: fixture integrity — a mode-000 sidecar is still a readable regular file after L5b's fallback, so that shape is not unusable on this runner and its cells would grade something else"
  elif [ "$c1 $c2 $c3 $c4 $c5 $c6" != "none-pending unconfirmed none-pending unconfirmed none-pending unconfirmed" ]; then
    FAIL "S28a: CONTROL — with no sidecar (undeclared, declared), an S_DA baseline (unmoved, moved) and a legacy CRC baseline (unmoved, moved) the states read [$c1 $c2 $c3 $c4 $c5 $c6], want [none-pending unconfirmed none-pending unconfirmed none-pending unconfirmed], so an undetermined below would not be attributable to the sidecar"
  elif [ "$got" -eq 36 ] && [ "$n" -eq 36 ] && [ "$mut" = none-pending ]; then
    PASS "S28a: case 5 — $got of $n trips whose baseline sidecar is present but unusable (dangling link, mode 000, a token not a digest, no digest= line, empty, a directory, a 20-hex token, a 64-character uppercase token, CRLF), on both policies and both renders, resolve undetermined; the six controls keep their verdicts, a legacy CRC baseline among them reading as a baseline; ARMED-RED: the old fold reads the undeclared moved no-digest= trip none-pending"
  else
    FAIL "S28a: $got of $n cells read undetermined;${bad:- none other} ARMED-RED read '$mut' (want none-pending)"
  fi
}
s28a_assert

# ── S28b — THE GATE ON EACH SHAPE. The nine undeclared trips under the moved render, each through
# ( require_change_confirmation … ): each must refuse, name `(state: undetermined)`, say the
# baseline is present but cannot be used, name the sidecar's path, and carry none of S15f's
# vocabulary of change once the trip path is scrubbed — and must not speak of the outgoing render,
# which is the other cause's message. CONTROL: an unreadable render (S15a's trip) keeps the render
# cause and not this one, and a readable moved render's refusal carries the vocabulary, so the scan
# can see a claim.
s28b_assert() {
  local sh d e rc m ok=1 n=0 why="" ce cr cc=0 crr=0 cu=0
  for sh in $S28_SHAPES; do
    n=$((n+1))
    d="$(s_fixture "s28b-$sh-$RANDOM" 16:30 none)"; s28_plant "$d" "$sh"
    e="$( ( require_change_confirmation "$d" ) 2>&1 >/dev/null )"; rc=$?
    m="${e//"$d"/<trip>}"
    [ "$rc" -ne 0 ] || { ok=0; why="$why $sh:rc=0"; }
    case "$e" in *"(state: undetermined)"*) ;; *) ok=0; why="$why $sh:no-token" ;; esac
    case "$e" in *"present but cannot be used"*) ;; *) ok=0; why="$why $sh:no-cause" ;; esac
    case "$e" in *"$d/.published-itinerary"*) ;; *) ok=0; why="$why $sh:no-path" ;; esac
    case "$e" in *"outgoing render"*) ok=0; why="$why $sh:render-cause" ;; esac
    [ -z "$(s15f_claims "$m")" ] || { ok=0; why="$why $sh:claims[$(s15f_claims "$m")]"; }
  done
  ce="$( ( require_change_confirmation "$S15AD" ) 2>&1 >/dev/null )"
  cr="$( ( require_change_confirmation "$S15DD" ) 2>&1 >/dev/null )"
  case "$ce" in *"outgoing render"*) crr=1 ;; esac
  case "$ce" in *"present but cannot be used"*) cu=1 ;; esac
  [ -n "$(s15f_claims "${cr//"$S15DD"/<trip>}")" ] && cc=1
  if [ "$crr" -ne 1 ] || [ "$cu" -ne 0 ] || [ "$cc" -ne 1 ]; then
    FAIL "S28b: CONTROL — the unreadable render's refusal names the render=$crr and this cause=$cu (want 1 and 0), and the readable moved render's refusal carries the vocabulary of change=$cc (want 1), so the readings below are not measurements"
  elif [ "$ok" -eq 1 ] && [ "$n" -eq 9 ]; then
    PASS "S28b: on each of the $n shapes the gate refuses, names undetermined, says the baseline at the sidecar's path is present but cannot be used, and makes no claim about change in either direction; the render cause keeps its own words, and a readable moved render's refusal carries the vocabulary the scan looks for"
  else
    FAIL "S28b: the gate's refusals on the $n shapes:$why"
  fi
}
s28b_assert

# ── S28c — THE SUCCESS INDICATOR'S ARM: update, end to end, refuses an unusable baseline before any
# network effect. S8's mock of gh and npx is defined here and withdrawn here. Two undeclared trips —
# a dangling link, which no privilege reads, and a sidecar with no digest= line — must each return
# 1, name the cause, and leave no `repo clone` in the mock's log. CONTROL: a trip with a usable
# S_DA baseline and a confirmation of the 16:30 plan it carries does reach the clone, so the zero
# below is a measurement of a path that can clone.
SB_GHLOG="$WORK/sb_gh.log"
s28c_assert() {
  local dl nd cc e1 e2 r1 r2 l1 l2 lc m1=0 m2=0 cl1=0 cl2=0 clc=0
  dl="$(s_fixture "s28cl-$RANDOM" 16:30 none)"; s28_plant "$dl" dangling
  nd="$(s_fixture "s28cn-$RANDOM" 16:30 none)"; s28_plant "$nd" nodigest
  cc="$(s_fixture "s28cc-$RANDOM" 16:30 none)"; s_record "$cc/.published-itinerary" "$S_DA" published; s_record "$cc/.change-confirmed" "$S_DB" confirmed
  gh() {   # mock: S8's — record the call, answer the read-only probes, create or clone nothing real
    printf '%s\n' "$*" >> "$SB_GHLOG"
    case "${1:-} ${2:-}" in
      "api user")    printf 'testowner' ;;
      "repo view")   return 0 ;;
      "auth status") printf "Token scopes: 'repo'\n" ;;
      *)             return 0 ;;
    esac
  }
  npx() { return 0; }
  : > "$SB_GHLOG"; e1="$( ( cmd_update "$dl" ) 2>&1 >/dev/null )"; r1=$?; l1="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; e2="$( ( cmd_update "$nd" ) 2>&1 >/dev/null )"; r2=$?; l2="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; ( cmd_update "$cc" ) >/dev/null 2>&1; lc="$(cat "$SB_GHLOG")"
  unset -f gh npx
  case "$e1" in *"present but cannot be used"*) m1=1 ;; esac
  case "$e2" in *"present but cannot be used"*) m2=1 ;; esac
  case "$l1" in *"repo clone"*) cl1=1 ;; esac
  case "$l2" in *"repo clone"*) cl2=1 ;; esac
  case "$lc" in *"repo clone"*) clc=1 ;; esac
  if [ "$clc" -ne 1 ]; then
    FAIL "S28c: CONTROL — a confirmed update over a usable baseline never reached the clone in the mock's log, so the absence of a clone below proves nothing"
  elif [ "$r1" -eq 1 ] && [ "$r2" -eq 1 ] && [ "$m1" -eq 1 ] && [ "$m2" -eq 1 ] && [ "$cl1" -eq 0 ] && [ "$cl2" -eq 0 ]; then
    PASS "S28c: update over a baseline sidecar that is a dangling link, and over one with no digest= line, returns 1 naming the unusable baseline and never clones the per-trip repo; a confirmed update over a usable baseline does reach the clone"
  else
    FAIL "S28c: dangling rc=$r1 named=$m1 cloned=$cl1; no digest= rc=$r2 named=$m2 cloned=$cl2 — an unusable baseline let update through, or its refusal came after a network effect"
  fi
}
s28c_assert

# ── S28d — CONFIRM ON EACH SHAPE, BOTH POLICIES. ( cmd_confirm … ) </dev/null on the nine shapes
# under the moved render, on a trip that declares no approvers and on one that declares an
# approver: each must return 1 saying it could not determine whether the itinerary changed and
# naming the published baseline, never reach the terminal check, write no .change-confirmed, and
# print no approval line — so the declared branch was never entered. CONTROL: a moved render over
# a usable S_DA baseline does reach the terminal check.
s28d_assert() {
  local sh pol d out e rc ok=1 n=0 why="" ce ct=0
  for sh in $S28_SHAPES; do
    for pol in undeclared declared; do
      n=$((n+1))
      d="$(s_fixture "s28d-$sh-$pol-$RANDOM" 16:30 none)"
      [ "$pol" = undeclared ] || sa_declare "$d" all zqa1
      s28_plant "$d" "$sh"
      out="$( ( cmd_confirm "$d" ) </dev/null 2>"$WORK/s28d.err" )"; rc=$?; e="$(cat "$WORK/s28d.err")"
      [ "$rc" -eq 1 ] || { ok=0; why="$why $sh/$pol:rc=$rc"; }
      case "$e" in *"could not determine"*) ;; *) ok=0; why="$why $sh/$pol:no-cd" ;; esac
      case "$e" in *"published baseline"*) ;; *) ok=0; why="$why $sh/$pol:no-cause" ;; esac
      case "$e" in *"requires a terminal"*) ok=0; why="$why $sh/$pol:reached-terminal" ;; esac
      [ ! -e "$d/.change-confirmed" ] || { ok=0; why="$why $sh/$pol:wrote"; }
      [ "$(sa_line_codes "$out")" = "0 -" ] || { ok=0; why="$why $sh/$pol:approval-line"; }
    done
  done
  d="$(s_fixture "s28d-ctl-$RANDOM" 16:30 none)"; s_record "$d/.published-itinerary" "$S_DA" published
  ce="$( ( cmd_confirm "$d" ) </dev/null 2>&1 >/dev/null )"
  case "$ce" in *"requires a terminal"*) ct=1 ;; esac
  if [ "$ct" -ne 1 ]; then
    FAIL "S28d: CONTROL — confirm on a moved render over a usable baseline did not reach the terminal check, so a refusal below could not be told from a death at it"
  elif [ "$ok" -eq 1 ] && [ "$n" -eq 18 ]; then
    PASS "S28d: confirm refuses all $n cells — nine unusable shapes on both policies — saying it could not determine whether the itinerary changed and naming the published baseline, before the terminal check, writing nothing and printing no approval line; a moved render over a usable baseline reaches the terminal check"
  else
    FAIL "S28d: confirm on the $n cells:$why"
  fi
}
s28d_assert

# ── S28e — THE CLASSIFIER ITSELF. _baseline_record over the nine shapes, an absent path, an S_DA
# record and a legacy CRC record must print `unusable` nine times, `absent`, the S_DA token and the
# CRC token — the last is criterion 1's legacy baseline, read as one. Registered: with the
# classifier removed every answer is empty.
s28e_assert() {
  local sh d got="" want="" ab da la
  for sh in $S28_SHAPES; do
    d="$(s_fixture "s28e-$sh-$RANDOM" 14:00 none)"; s28_plant "$d" "$sh"
    got="$got $(_baseline_record "$d/.published-itinerary" 2>/dev/null)"; want="$want unusable"
  done
  d="$(s_fixture "s28e-ab-$RANDOM" 14:00 none)"; ab="$(_baseline_record "$d/.published-itinerary" 2>/dev/null)"
  d="$(s_fixture "s28e-da-$RANDOM" 14:00 none)"; s_record "$d/.published-itinerary" "$S_DA" published; da="$(_baseline_record "$d/.published-itinerary" 2>/dev/null)"
  d="$(s_fixture "s28e-la-$RANDOM" 14:00 none)"; s_record "$d/.published-itinerary" "$S_LA" published; la="$(_baseline_record "$d/.published-itinerary" 2>/dev/null)"
  if [ -z "$S_LA" ] || [ "${#S_DA}" -ne 64 ]; then
    FAIL "S28e: fixture integrity — the legacy token reads '$S_LA' and the S_DA token is ${#S_DA} characters, so the two readings below would not be about a CRC token and a SHA-256 one"
  elif [ "$got" = "$want" ] && [ "$ab" = absent ] && [ "$da" = "$S_DA" ] && [ "$la" = "$S_LA" ]; then
    PASS "S28e: _baseline_record reads each of the nine shapes as unusable, an absent sidecar as absent, an S_DA record as its own token and a legacy CRC record as its own token — a legacy baseline still reads as a baseline"
  else
    FAIL "S28e: shapes [$got] want [$want]; absent '$ab'; S_DA '$da'; CRC '$la' (want $S_LA)"
  fi
}
s28e_assert

# ── S29 — CASES 2 AND 4 AT THE SOURCE (#1468, under direction (A)): no push begins that could not
# end with a recorded baseline. require_recordable_baseline refuses before anything is cloned,
# created or pushed when the outgoing render has no itinerary identity, when the sidecar's path is
# not a regular file, or when the recorder's own staging step fails beside it. publish calls it
# directly, and update and rotate through require_publish_guards. Each arm that drives a command
# defines S8's mock of gh and npx through sb_gh, and withdraws both before its verdict.
sb_gh() { # S8's mock of gh, shared by the S29 arms: record the call, answer the read-only probes
  printf '%s\n' "$*" >> "$SB_GHLOG"
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 0 ;;
    "auth status") printf "Token scopes: 'repo'\n" ;;
    *)             return 0 ;;
  esac
}

# ── S29a — publish, end to end, on a render nothing can read: it must return 1 naming the render's
# identity, and the mock's log must carry neither the existence probe nor a repo creation, with no
# sidecar written. CONTROL: an identifiable render reaches the existence probe (the mock answers
# that the repo exists, so it then stops, as S9 does). Registered: with the guard removed, publish
# runs on to the probe.
s29a_assert() {
  local d c e rc log clog msg=0 vw=0 cr=0 cvw=0 side=0
  d="$(s15_dangling "s29a-$RANDOM")"; c="$(s_fixture "s29ac-$RANDOM" 14:00 none)"
  gh() { sb_gh "$@"; }; npx() { return 0; }
  : > "$SB_GHLOG"; e="$( ( cmd_publish "$d" ) 2>&1 >/dev/null )"; rc=$?; log="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; ( cmd_publish "$c" ) >/dev/null 2>&1; clog="$(cat "$SB_GHLOG")"
  unset -f gh npx
  case "$e" in *"could not identify the itinerary content of the outgoing render"*) msg=1 ;; esac
  case "$log" in *"repo view"*) vw=1 ;; esac
  case "$log" in *"repo create"*) cr=1 ;; esac
  case "$clog" in *"repo view"*) cvw=1 ;; esac
  [ -e "$d/.published-itinerary" ] && side=1
  if [ "$cvw" -ne 1 ]; then
    FAIL "S29a: CONTROL — publish of an identifiable render never reached the existence probe in the mock's log, so its absence below proves nothing"
  elif [ "$rc" -eq 1 ] && [ "$msg" -eq 1 ] && [ "$vw" -eq 0 ] && [ "$cr" -eq 0 ] && [ "$side" -eq 0 ]; then
    PASS "S29a: publish of a render nothing can read returns 1 naming the render's identity, before the repo is probed or created and with no sidecar written; an identifiable render reaches the probe"
  else
    FAIL "S29a: rc=$rc named=$msg probed=$vw created=$cr sidecar=$side — publish began a push that could not end with a baseline"
  fi
}
s29a_assert

# ── S29b — update, end to end, on an undeclared trip with NO baseline and a render nothing can
# read: the gate reads none-pending there, so the guard is the only thing standing between it and
# a push that would leave the trip with no anchor. It must return 1 naming the render's identity,
# with no clone in the mock's log. CONTROL: the same shape of trip with an identifiable render
# reads none-pending at the gate and reaches the clone.
s29b_assert() {
  local d c e rc log clog st msg=0 cl=0 ccl=0
  d="$(s15_dangling "s29b-$RANDOM")"; c="$(s_fixture "s29bc-$RANDOM" 14:00 none)"
  st="$(change_confirmation_state "$c" 2>/dev/null)"
  gh() { sb_gh "$@"; }; npx() { return 0; }
  : > "$SB_GHLOG"; e="$( ( cmd_update "$d" ) 2>&1 >/dev/null )"; rc=$?; log="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; ( cmd_update "$c" ) >/dev/null 2>&1; clog="$(cat "$SB_GHLOG")"
  unset -f gh npx
  case "$e" in *"could not identify the itinerary content of the outgoing render"*) msg=1 ;; esac
  case "$log" in *"repo clone"*) cl=1 ;; esac
  case "$clog" in *"repo clone"*) ccl=1 ;; esac
  if [ "$st" != none-pending ] || [ "$ccl" -ne 1 ]; then
    FAIL "S29b: CONTROL — the identifiable trip with no baseline read '$st' (want none-pending) and reached the clone=$ccl (want 1), so the refusal below is not attributable to the render"
  elif [ "$rc" -eq 1 ] && [ "$msg" -eq 1 ] && [ "$cl" -eq 0 ]; then
    PASS "S29b: update on an undeclared trip with no baseline, whose gate reads none-pending, refuses a render nothing can read (rc=1, the render's identity named) before any clone; the same trip with an identifiable render reaches the clone"
  else
    FAIL "S29b: rc=$rc named=$msg cloned=$cl — update began a push that would leave the trip with no baseline"
  fi
}
s29b_assert

# ── S29c — THE OTHER TWO REFUSALS, ON ALL THREE PUSH PATHS. (i) update with mktemp failing: "could
# not stage the baseline", no clone. (ii) publish with the sidecar's path a directory: "is not a
# regular file", no existence probe. (iii) rotate with mktemp failing, a usable baseline and the
# outgoing plan confirmed: rc 1, the staging refusal, .passphrase byte-identical, no clone — the
# guard runs before the key is written. CONTROL: (i)'s trip unstubbed reaches the clone.
s29c_assert() {
  local u p r c ue pe re ur pr rr ul pl rl cl um=0 pm=0 rmsg=0 ucl=0 pvw=0 rcl=0 rsame=0 ccl=0
  u="$(s_fixture "s29cu-$RANDOM" 14:00 none)"
  p="$(s_fixture "s29cp-$RANDOM" 14:00 none)"; mkdir -p "$p/.published-itinerary"
  r="$(s_fixture "s29cr-$RANDOM" 16:30 none)"; s_record "$r/.published-itinerary" "$S_DA" published; s_record "$r/.change-confirmed" "$S_DB" confirmed
  printf '%s\n' 'sb-live-synthetic-key-0029' > "$r/.passphrase"; chmod 600 "$r/.passphrase"; cp -p "$r/.passphrase" "$r.pp-before"
  c="$(s_fixture "s29cc-$RANDOM" 14:00 none)"
  gh() { sb_gh "$@"; }; npx() { return 0; }
  mktemp() { return 1; }
  : > "$SB_GHLOG"; ue="$( ( cmd_update "$u" ) 2>&1 >/dev/null )"; ur=$?; ul="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; re="$( ( cmd_rotate "$r" ) 2>&1 >/dev/null )"; rr=$?; rl="$(cat "$SB_GHLOG")"
  unset -f mktemp
  : > "$SB_GHLOG"; pe="$( ( cmd_publish "$p" ) 2>&1 >/dev/null )"; pr=$?; pl="$(cat "$SB_GHLOG")"
  : > "$SB_GHLOG"; ( cmd_update "$c" ) >/dev/null 2>&1; cl="$(cat "$SB_GHLOG")"
  unset -f gh npx
  case "$ue" in *"could not stage the baseline"*) um=1 ;; esac
  case "$pe" in *"is not a regular file"*) pm=1 ;; esac
  case "$re" in *"could not stage the baseline"*) rmsg=1 ;; esac
  case "$ul" in *"repo clone"*) ucl=1 ;; esac
  case "$pl" in *"repo view"*) pvw=1 ;; esac
  case "$rl" in *"repo clone"*) rcl=1 ;; esac
  case "$cl" in *"repo clone"*) ccl=1 ;; esac
  cmp -s "$r.pp-before" "$r/.passphrase" && rsame=1
  if [ "$ccl" -ne 1 ]; then
    FAIL "S29c: CONTROL — update on (i)'s trip unstubbed never reached the clone, so the absence of one below proves nothing"
  elif [ "$ur" -eq 1 ] && [ "$um" -eq 1 ] && [ "$ucl" -eq 0 ] && [ "$pr" -eq 1 ] && [ "$pm" -eq 1 ] && [ "$pvw" -eq 0 ] && [ "$rr" -eq 1 ] && [ "$rmsg" -eq 1 ] && [ "$rsame" -eq 1 ] && [ "$rcl" -eq 0 ]; then
    PASS "S29c: update refuses a baseline it cannot stage before any clone, publish refuses a sidecar path that is not a regular file before the existence probe, and rotate refuses a baseline it cannot stage before any clone with .passphrase byte-identical; the unstubbed control reaches the clone"
  else
    FAIL "S29c: update rc=$ur named=$um cloned=$ucl; publish rc=$pr named=$pm probed=$pvw; rotate rc=$rr named=$rmsg passphrase-unchanged=$rsame cloned=$rcl"
  fi
}
s29c_assert

# ── S29d — STRUCTURAL, from the PARSED bodies as S9b reads them. require_publish_guards calls the
# baseline guard after the render's approval-code guard; cmd_publish calls the baseline guard and
# not the gate, ahead of its existence probe. SENSITIVITY: cmd_update's body names its one call
# line, require_publish_guards. SPECIFICITY: a fabricated token is in none of the three bodies.
s29d_assert() {
  local g p u pre gc gr pg pv ok=1 why="" sens=0 spec=0
  g="$(declare -f require_publish_guards)"; p="$(declare -f cmd_publish)"; u="$(declare -f cmd_update)"
  gc=-1; gr=-1; pg=-1; pv=-1
  case "$g" in *require_render_approval_code*) pre="${g%%require_render_approval_code*}"; gc=${#pre} ;; esac
  case "$g" in *require_recordable_baseline*) pre="${g%%require_recordable_baseline*}"; gr=${#pre} ;; esac
  case "$p" in *require_recordable_baseline*) pre="${p%%require_recordable_baseline*}"; pg=${#pre} ;; esac
  case "$p" in *"gh repo view"*) pre="${p%%gh repo view*}"; pv=${#pre} ;; esac
  [ "$gc" -ge 0 ] && [ "$gr" -gt "$gc" ] || { ok=0; why="$why guards:$gc/$gr"; }
  [ "$pg" -ge 0 ] && [ "$pv" -gt "$pg" ] || { ok=0; why="$why publish:$pg/$pv"; }
  case "$p" in *require_change_confirmation*) ok=0; why="$why publish-gated" ;; esac
  case "$u" in *require_publish_guards*) sens=1 ;; esac
  case "$g$p$u" in *zzq_fabricated_s29d*) spec=1 ;; esac
  if [ "$sens" -ne 1 ] || [ "$spec" -ne 0 ]; then
    FAIL "S29d: CONTROL — cmd_update's parsed body names require_publish_guards=$sens (want 1) and a fabricated token appears=$spec (want 0), so the offsets below are not measurements"
  elif [ "$ok" -eq 1 ]; then
    PASS "S29d: in the parsed bodies, require_publish_guards calls the baseline guard after the render's approval-code guard, and cmd_publish calls it ahead of its existence probe and does not call the gate — publish stays ungated"
  else
    FAIL "S29d: guard placement:$why"
  fi
}
s29d_assert

# ── Group S, #1468 amendment 1 (D-6, FM-1, FM-3, CD-1) — the staged record, and the recorder's words ──
# Helpers for S27c–S27e, S29e and S31a–S31f. s31_trip builds a trip with a baseline (A = S0's S_DA,
# B = S_DB), an optional staged record, an optional declaration with an approval of B (or of A and
# B), and an optional confirmation of B. Every negative is a captured value inside a `[ … ]`
# conjunction; every stub is withdrawn in the arm that set it.
S27D_PRIV=0; s27d_probe="$(mktemp -d "$WORK/s27dp.XXXXXX")"; chmod a-w "$s27d_probe"; [ -w "$s27d_probe" ] && S27D_PRIV=1; chmod u+w "$s27d_probe"
s27_run() { S27_ERR="$( ( set -e; record_published_itinerary "$1" "$1/$S15_RENDER"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; S27_RC=$?; }
s31_trip() { # <name> <render-time> <baseline A|B|-> <staged A|B|dir|-> [declared|declaredAB|declaredABw|-] [confirmation B]
  local d="$WORK/sb-$1-$RANDOM"; mkdir -p "$d/outputs"; s_render "$d/$S15_RENDER" "$2" none
  case "$3" in A) s_record "$d/.published-itinerary" "$S_DA" published ;; B) s_record "$d/.published-itinerary" "$S_DB" published ;; esac
  case "$4" in A) s_record "$d/.published-itinerary.next" "$S_DA" published ;; B) s_record "$d/.published-itinerary.next" "$S_DB" published ;; dir) mkdir -p "$d/.published-itinerary.next" ;; esac
  case "${5:-}" in
    declared)    sa_declare "$d" 1 zqa1; sa_rec "$d" zqa1 approve "$S_DB" ;;
    declaredAB)  sa_declare "$d" 1 zqa1; sa_rec "$d" zqa1 approve "$S_DA"; sa_rec "$d" zqa1 approve "$S_DB" ;;
    declaredABw) sa_declare "$d" 1 zqa1; sa_rec "$d" zqa1 approve "$S_DA"; sa_rec "$d" zqa1 approve "$S_DB"; sa_rec "$d" zqa1 withdraw "$S_DA" ;;
  esac
  case "${6:-}" in B) s_record "$d/.change-confirmed" "$S_DB" confirmed ;; esac
  printf '%s' "$d"
}
s27c_assert() {
  local u d m eu ed em ru rd rmal nu=0 nd=0 nm=0 ad=0 am=0 rp=0
  u="$(s_fixture "s27cu-$RANDOM" 14:00 none)"; d="$(s_fixture "s27cd-$RANDOM" 14:00 none)"; sa_declare "$d" 1 zqa1
  m="$(s_fixture "s27cm-$RANDOM" 14:00 none)"; sa_rec "$m" zqa1 approve "$S_DA"
  mktemp() { return 1; }
  s27_run "$u"; eu="$S27_ERR"; ru=$S27_RC
  s27_run "$d"; ed="$S27_ERR"; rd=$S27_RC
  s27_run "$m"; em="$S27_ERR"; rmal=$S27_RC
  unset -f mktemp
  case "$eu" in *"NOT ACTIVE"*) nu=1 ;; esac
  case "$ed" in *"NOT ACTIVE"*) nd=1 ;; esac
  case "$em" in *"NOT ACTIVE"*) nm=1 ;; esac
  case "$ed" in *"until approvals of its outgoing plan are recorded"*) ad=1 ;; esac
  case "$em" in *"until approvals of its outgoing plan are recorded"*) am=1 ;; esac
  case "$em" in *"until they are repaired"*) rp=1 ;; esac
  if [ "$ru" -ne 0 ] || [ "$nu" -ne 1 ]; then
    FAIL "S27c: CONTROL — an undeclared trip with no baseline returned rc=$ru and NOT ACTIVE=$nu (want 0 and 1)"
  elif [ "$rd" -eq 0 ] && [ "$rmal" -eq 0 ] && [ "$nd" -eq 0 ] && [ "$nm" -eq 0 ] && [ "$ad" -eq 1 ] && [ "$am" -eq 0 ] && [ "$rp" -eq 1 ]; then
    PASS "S27c: declaring and malformed trips are never told NOT ACTIVE; each warning names the exit that works on it — approvals of the outgoing plan where approvers are declared, repairing the sidecars where they are malformed"
  else
    FAIL "S27c: declared rc=$rd notactive=$nd approvals-exit=$ad; malformed rc=$rmal notactive=$nm approvals-exit=$am repair-exit=$rp"
  fi
}
s27d_assert() {
  local c d a=0 n=0 side=0 csd
  c="$(s_fixture "s27dc-$RANDOM" 14:00 none)"; s27_run "$c"; csd="$(_baseline_record "$c/.published-itinerary")"
  d="$(s_fixture "s27d-$RANDOM" 14:00 none)"; S27D_DIR="$d"
  if [ "${S27D_PRIV:-0}" -eq 1 ]; then
    mv() { return 1; }; rm() { return 1; }
  else
    mv() { chmod a-w "$S27D_DIR"; command mv "$@"; }
  fi
  s27_run "$d"
  unset -f mv rm; chmod u+w "$d"
  case "$S27_ERR" in *S27-AFTER*) a=1 ;; esac
  case "$S27_ERR" in *"NOT ACTIVE"*) n=1 ;; esac
  [ -e "$d/.published-itinerary" ] && side=1
  if [ "$csd" != "$S_DA" ]; then
    FAIL "S27d: CONTROL — the same recorder on a writable trip wrote '$csd', not $S_DA"
  elif [ "$S27_RC" -eq 0 ] && [ "$a" -eq 1 ] && [ "$n" -eq 1 ] && [ "$side" -eq 0 ]; then
    PASS "S27d: a trip directory that loses write between the staging and the move (priv-fallback=${S27D_PRIV:-0}) still gets the recorder's NOT ACTIVE warning and rc 0 under errexit — the temp file's clean-up cannot end the command after a push"
  else
    FAIL "S27d: rc=$S27_RC after-marker=$a NOT-ACTIVE=$n sidecar=$side — the clean-up ended the command, or the warning was lost"
  fi
}
s29e_assert() {
  local x l m o rx rl rmv ro em st=0
  x="$(s31_trip s29ex 14:00 A -)"; l="$(s31_trip s29el 14:00 - -)"; s_record "$l/.published-itinerary" "$S_LA" published
  m="$(s31_trip s29em 16:30 A -)"; o="$(s31_trip s29eo 14:00 A B)"
  mktemp() { return 1; }
  ( require_recordable_baseline "$x" "$x/$S15_RENDER" ) >/dev/null 2>&1; rx=$?
  ( require_recordable_baseline "$l" "$l/$S15_RENDER" ) >/dev/null 2>&1; rl=$?
  em="$( ( require_recordable_baseline "$m" "$m/$S15_RENDER" ) 2>&1 >/dev/null )"; rmv=$?
  ( require_recordable_baseline "$o" "$o/$S15_RENDER" ) >/dev/null 2>&1; ro=$?
  unset -f mktemp
  case "$em" in *"could not stage the baseline"*) st=1 ;; esac
  if [ "$rmv" -ne 1 ] || [ "$st" -ne 1 ]; then
    FAIL "S29e: CONTROL — a moved plan with staging failing returned rc=$rmv, staging refusal=$st (want 1, 1)"
  elif [ "$rx" -eq 0 ] && [ "$rl" -eq 0 ] && [ "$ro" -eq 1 ]; then
    PASS "S29e: with staging failing, the guard passes a push that re-publishes the recorded plan (exact rc=$rx, legacy CRC rc=$rl) and still refuses one where another plan's record is outstanding (rc=$ro); a moved plan is refused (control)"
  else
    FAIL "S29e: exact rc=$rx (want 0), legacy rc=$rl (want 0), outstanding-record rc=$ro (want 1)"
  fi
}
s31a_assert() {
  local got="" t want saved mut
  for t in "ua 14:00 A B" "u0 14:00 - B" "da 14:00 A B declared" "ub 16:30 A B - B" "u0b 16:30 - B" "db 16:30 A B declared" "uc 18:15 A B" "ux 14:00 A dir" "ua0 14:00 A -" "u00 14:00 - -" "da0 14:00 A - declared" "na 14:00 A B declaredAB" "na0 14:00 A - declaredAB" "naa 14:00 A A declaredAB" "naw 14:00 A A declaredABw"; do
    # shellcheck disable=SC2086
    set -- $t
    got="$got $(change_confirmation_state "$(s31_trip "s31a$1" "$2" "$3" "$4" "${5:-}" "${6:-}")" 2>/dev/null)"
  done
  saved="$(declare -f staged_record_path)"
  staged_record_path() { printf '%s' "$1/zzq-no-staged-record"; }
  mut="$(change_confirmation_state "$(s31_trip s31amut 14:00 A B)" 2>/dev/null)"
  if [ -n "$saved" ]; then eval "$saved"; else unset -f staged_record_path; fi
  want=' undetermined undetermined undetermined confirmed none-pending confirmed unconfirmed undetermined none-pending none-pending none-pending confirmed none-pending confirmed undetermined'
  if [ "$got" = "$want" ] && [ "$mut" = none-pending ]; then
    PASS "S31a: a staged record holds exactly the verdicts that rest on which plan is live — 11 cells and 4 controls as specified, a declared trip's published plan whose own approvals meet the threshold reading confirmed while held, and a record of that same plan holding it once its approval is withdrawn; ARMED-RED: with the staged record unread the held cell reads none-pending"
  else
    FAIL "S31a: states [$got] want [$want]; ARMED-RED read '$mut' (want none-pending)"
  fi
}
s31b_assert() {
  local ua da cu cr e1 e2 c5 rr r1 r2 m1 m2 ok=1 ctl=1 x why=""
  ua="$(s31_trip s31bua 14:00 A B)"; da="$(s31_trip s31bda 14:00 A B declared)"
  cu="$(s31_trip s31bcu 14:00 - -)"; printf 'published=2027-06-01T00:00:00Z\n' > "$cu/.published-itinerary"
  cr="$(s15_dangling "s31bcr-$RANDOM")"; s_record "$cr/.published-itinerary" "$S_DA" published
  e1="$( ( require_change_confirmation "$ua" ) 2>&1 >/dev/null )"; r1=$?
  e2="$( ( require_change_confirmation "$da" ) 2>&1 >/dev/null )"; r2=$?
  c5="$( ( require_change_confirmation "$cu" ) 2>&1 >/dev/null )"
  rr="$( ( require_change_confirmation "$cr" ) 2>&1 >/dev/null )"
  m1="${e1//"$ua"/<trip>}"; m2="${e2//"$da"/<trip>}"
  for x in "$m1" "$m2"; do
    case "$x" in *"(state: undetermined)"*) ;; *) ok=0; why="$why no-token" ;; esac
    case "$x" in *"still outstanding"*) ;; *) ok=0; why="$why no-cause" ;; esac
    case "$x" in *"<trip>/.published-itinerary.next"*) ;; *) ok=0; why="$why no-path" ;; esac
    case "$x" in *"outgoing render"*|*"present but cannot be used"*) ok=0; why="$why other-cause" ;; esac
    [ -z "$(s15f_claims "$x")" ] || { ok=0; why="$why claims[$(s15f_claims "$x")]"; }
  done
  case "$c5" in *"present but cannot be used"*) ;; *) ctl=0 ;; esac
  case "$c5" in *"still outstanding"*) ctl=0 ;; esac
  case "$rr" in *"outgoing render"*) ;; *) ctl=0 ;; esac
  case "$rr" in *"still outstanding"*) ctl=0 ;; esac
  if [ "$ctl" -ne 1 ]; then
    FAIL "S31b: CONTROL — the unusable-baseline and unreadable-render messages do not keep their own causes"
  elif [ "$r1" -ne 0 ] && [ "$r2" -ne 0 ] && [ "$ok" -eq 1 ]; then
    PASS "S31b: the gate refuses a held trip on both policies, names undetermined, the outstanding staged record and its path, and makes no change claim; the other two causes keep their own words"
  else
    FAIL "S31b: rc $r1/$r2;$why"
  fi
}
s31c_assert() {
  local ua da uc e1 e2 ec r1 r2 ok=1 ct=0 x why=""
  ua="$(s31_trip s31cua 14:00 A B)"; da="$(s31_trip s31cda 14:00 A B declared)"; uc="$(s31_trip s31cuc 18:15 A B)"
  e1="$( ( cmd_confirm "$ua" ) </dev/null 2>&1 >/dev/null )"; r1=$?
  e2="$( ( cmd_confirm "$da" ) </dev/null 2>&1 >/dev/null )"; r2=$?
  ec="$( ( cmd_confirm "$uc" ) </dev/null 2>&1 >/dev/null )"
  for x in "$e1" "$e2"; do
    case "$x" in *"could not determine"*) ;; *) ok=0; why="$why no-cd" ;; esac
    case "$x" in *"still outstanding"*) ;; *) ok=0; why="$why no-cause" ;; esac
    case "$x" in *"requires a terminal"*) ok=0; why="$why reached" ;; esac
  done
  [ ! -e "$ua/.change-confirmed" ] || { ok=0; why="$why wrote"; }
  case "$ec" in *"requires a terminal"*) ct=1 ;; esac
  if [ "$ct" -ne 1 ]; then
    FAIL "S31c: CONTROL — confirm on a held trip whose plan moved did not reach the terminal check"
  elif [ "$r1" -eq 1 ] && [ "$r2" -eq 1 ] && [ "$ok" -eq 1 ]; then
    PASS "S31c: confirm refuses a held trip before the terminal check on both policies, naming the outstanding record, and records nothing; a held trip whose plan moved still reaches the terminal check"
  else
    FAIL "S31c: rc $r1/$r2;$why"
  fi
}
s31d_assert() {
  local a b c x ra rb rc rx eb ec gb=0 gc=0
  a="$(s31_trip s31da 16:30 A -)"; b="$(s31_trip s31db 16:30 A -)"; c="$(s31_trip s31dc 16:30 A -)"; x="$(s31_trip s31dx 14:00 A -)"
  ( stage_baseline_record "$a" "$a/$S15_RENDER" update ) >/dev/null 2>&1; ra=$?
  mktemp() { return 1; }
  eb="$( ( stage_baseline_record "$b" "$b/$S15_RENDER" update ) 2>&1 >/dev/null )"; rb=$?
  ec="$( ( stage_baseline_record "$c" "$c/$S15_RENDER" rotate ) 2>&1 >/dev/null )"; rc=$?
  ( stage_baseline_record "$x" "$x/$S15_RENDER" rotate ) >/dev/null 2>&1; rx=$?
  unset -f mktemp
  case "$eb" in *"could not stage this push's baseline record"*) gb=1 ;; esac
  case "$ec" in *"run update"*) gc=1 ;; esac
  if [ "$ra" -eq 0 ] && [ -f "$a/.published-itinerary.next" ] && [ ! -L "$a/.published-itinerary.next" ] && [ "$(_baseline_record "$a/.published-itinerary.next")" = "$S_DB" ] && [ "$(_baseline_record "$a/.published-itinerary")" = "$S_DA" ] && [ "$(sb_temps "$a")" -eq 0 ] && [ "$rb" -eq 1 ] && [ "$gb" -eq 1 ] && [ ! -e "$b/.published-itinerary.next" ] && [ "$rc" -eq 1 ] && [ "$gc" -eq 1 ] && [ "$rx" -eq 0 ] && [ ! -e "$x/.published-itinerary.next" ]; then
    PASS "S31d: the stager writes the push's record as a regular file reading its plan, leaves the baseline and no temp behind; refuses when it cannot stage (rotate's refusal names update); stages nothing for a push that re-publishes the recorded plan"
  else
    FAIL "S31d: ra=$ra staged=$(_baseline_record "$a/.published-itinerary.next" 2>/dev/null) base=$(_baseline_record "$a/.published-itinerary") temps=$(sb_temps "$a") rb=$rb named=$gb rc=$rc update-named=$gc rx=$rx x-staged=$([ -e "$x/.published-itinerary.next" ] && echo 1 || echo 0)"
  fi
}
# S31e's cell (g) and its unreadable twin (#1468 amendment-3 review, R3-FM-1). Amendment 3 split the
# recorder's "changed or removed" branch in two, and no cell reached the "changed" limb, the one a
# staged record of ANOTHER plan takes when the recorder is handed this push's digest. (g) stages a
# third plan's record (the 18:15 render's digest) beside an S_DA baseline and hands the recorder
# S_DB; the twin puts a directory at the staged path. Each must leave that record as it is, say it
# was changed while the push was under way, keep the baseline, and hold a working copy reverted to
# the baseline's plan.
s31e_assert() {
  local a b p c d f e g x xu ea eb ep ec ed ef ee eg ex exu ra rb rp rc rd rf re rg rx rxu rcd st gr pst pgr dst dgr est xst xgr xust xugr
  local aft=0 left=0 wa=0 pa=0 pl=0 ac=0 wcc=0 da=0 dw=0 fa=0 frm=0 ena=0 enw=0 ga=0 gsame=0 grec=0 eflip=0 gsame_b=0 xa=0 xch=0 xua=0 xuch=0
  a="$(s31_trip s31ea 16:30 A B)"; b="$(s31_trip s31eb 16:30 A B)"; p="$(s31_trip s31ep 16:30 A B)"; c="$(s31_trip s31ec 16:30 A B)"
  d="$(s31_trip s31ed 16:30 A -)"; f="$(s31_trip s31ef 16:30 A -)"; e="$(s31_trip s31ee 14:00 A -)"; g="$(s31_trip s31eg 14:00 A -)"
  x="$(s31_trip s31ex 16:30 A -)"; xu="$(s31_trip s31exu 16:30 A dir)"
  cp "$e/.published-itinerary" "$e.before"; cp "$g/.published-itinerary" "$g.before"
  s27_run "$a"; ea="$S27_ERR"; ra=$S27_RC
  mv() { case "$*" in *".published-itinerary.next "*) return 1 ;; esac; command mv "$@"; }
  s27_run "$b"; eb="$S27_ERR"; rb=$S27_RC
  ep="$( ( set -e; record_published_itinerary "$p" "$p/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rp=$?
  unset -f mv
  s_render "$c/$S15_RENDER" 18:15; rcd="$(itinerary_digest "$c/$S15_RENDER")"
  ec="$( ( set -e; record_published_itinerary "$c" "$c/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rc=$?
  ed="$( ( set -e; record_published_itinerary "$d" "$d/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rd=$?
  s_record "$x/.published-itinerary.next" "$rcd" published
  ex="$( ( set -e; record_published_itinerary "$x" "$x/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rx=$?
  exu="$( ( set -e; record_published_itinerary "$xu" "$xu/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rxu=$?
  s_render "$e/$S15_RENDER" 18:15
  ee="$( ( set -e; record_published_itinerary "$e" "$e/$S15_RENDER" "$S_DA"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; re=$?
  mktemp() { return 1; }
  ef="$( ( set -e; record_published_itinerary "$f" "$f/$S15_RENDER" "$S_DB"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rf=$?
  eg="$( ( set -e; record_published_itinerary "$g" "$g/$S15_RENDER" "$S_DA"; printf 'S27-AFTER\n' >&2 ) 2>&1 >/dev/null )"; rg=$?
  unset -f mktemp
  case "$ea" in *"push itself succeeded"*) wa=1 ;; esac
  case "$eb" in *S27-AFTER*) aft=1 ;; esac
  case "$eb" in *"left staged"*) left=1 ;; esac
  case "$ep" in *S27-AFTER*) pa=1 ;; esac
  case "$ep" in *"left staged"*) pl=1 ;; esac
  case "$ec" in *S27-AFTER*) ac=1 ;; esac
  case "$ec" in *"push itself succeeded"*) wcc=1 ;; esac
  case "$ed" in *S27-AFTER*) da=1 ;; esac
  case "$ed" in *"staged again"*) dw=1 ;; esac
  case "$ef" in *S27-AFTER*) fa=1 ;; esac
  case "$ef" in *"removed while the push was under way"*) frm=1 ;; esac
  case "$ee" in *S27-AFTER*) ena=1 ;; esac
  case "$ee" in *"push itself succeeded"*) enw=1 ;; esac
  case "$eg" in *S27-AFTER*) ga=1 ;; esac
  case "$eg" in *"could not record the baseline"*) grec=1 ;; esac
  case "$eg" in *"records this same plan"*) gsame=1 ;; esac
  case "$ex" in *S27-AFTER*) xa=1 ;; esac
  case "$ex" in *"changed while the push was under way"*) xch=1 ;; esac
  case "$exu" in *S27-AFTER*) xua=1 ;; esac
  case "$exu" in *"changed while the push was under way"*) xuch=1 ;; esac
  cmp -s "$e.before" "$e/.published-itinerary" || eflip=1
  cmp -s "$g.before" "$g/.published-itinerary" && gsame_b=1
  est="$(change_confirmation_state "$e" 2>/dev/null)"
  s_render "$b/$S15_RENDER" 14:00; s_render "$p/$S15_RENDER" 14:00; s_render "$d/$S15_RENDER" 14:00; s_render "$x/$S15_RENDER" 14:00; s_render "$xu/$S15_RENDER" 14:00
  st="$(change_confirmation_state "$b" 2>/dev/null)"; ( require_change_confirmation "$b" ) >/dev/null 2>&1; gr=$?
  pst="$(change_confirmation_state "$p" 2>/dev/null)"; ( require_change_confirmation "$p" ) >/dev/null 2>&1; pgr=$?
  dst="$(change_confirmation_state "$d" 2>/dev/null)"; ( require_change_confirmation "$d" ) >/dev/null 2>&1; dgr=$?
  xst="$(change_confirmation_state "$x" 2>/dev/null)"; ( require_change_confirmation "$x" ) >/dev/null 2>&1; xgr=$?
  xust="$(change_confirmation_state "$xu" 2>/dev/null)"; ( require_change_confirmation "$xu" ) >/dev/null 2>&1; xugr=$?
  if [ "$ra" -ne 0 ] || [ "$wa" -ne 0 ] || [ "$(_baseline_record "$a/.published-itinerary")" != "$S_DB" ] || [ -e "$a/.published-itinerary.next" ] || [ "$(sb_temps "$a")" -ne 0 ] || [ -z "$rcd" ] || [ "$rcd" = "$S_DB" ] || [ "$rcd" = "$S_DA" ] || [ "$rf" -ne 0 ] || [ "$fa" -ne 1 ] || [ "$frm" -ne 1 ] || [ "$(_baseline_record "$f/.published-itinerary")" != "$S_DA" ] || [ -e "$f/.published-itinerary.next" ] || [ "$(sb_temps "$f")" -ne 0 ]; then
    FAIL "S31e: CONTROL — the recorder did not move a movable staged record into place (rc=$ra warned=$wa base=$(_baseline_record "$a/.published-itinerary") staged-left=$([ -e "$a/.published-itinerary.next" ] && echo 1 || echo 0)), the rebuilt render does not carry a third plan, other than both staged and baseline (its digest '${rcd:0:12}'), or a removed record that could not be staged again did not keep the baseline and say so (rc=$rf after=$fa named=$frm base=$(_baseline_record "$f/.published-itinerary") staged-left=$([ -e "$f/.published-itinerary.next" ] && echo 1 || echo 0))"
  elif [ "$rb" -eq 0 ] && [ "$aft" -eq 1 ] && [ "$left" -eq 1 ] && [ "$(_baseline_record "$b/.published-itinerary")" = "$S_DA" ] && [ "$(_baseline_record "$b/.published-itinerary.next")" = "$S_DB" ] && [ "$st" = undetermined ] && [ "$gr" -ne 0 ] && [ "$rp" -eq 0 ] && [ "$pa" -eq 1 ] && [ "$pl" -eq 1 ] && [ "$(_baseline_record "$p/.published-itinerary")" = "$S_DA" ] && [ "$(_baseline_record "$p/.published-itinerary.next")" = "$S_DB" ] && [ "$pst" = undetermined ] && [ "$pgr" -ne 0 ] && [ "$rc" -eq 0 ] && [ "$ac" -eq 1 ] && [ "$wcc" -eq 0 ] && [ "$(_baseline_record "$c/.published-itinerary")" = "$S_DB" ] && [ ! -e "$c/.published-itinerary.next" ] && [ "$(sb_temps "$c")" -eq 0 ] && [ "$rd" -eq 0 ] && [ "$da" -eq 1 ] && [ "$dw" -eq 1 ] && [ "$(_baseline_record "$d/.published-itinerary")" = "$S_DA" ] && [ "$(_baseline_record "$d/.published-itinerary.next")" = "$S_DB" ] && [ "$(sb_temps "$d")" -eq 0 ] && [ "$dst" = undetermined ] && [ "$dgr" -ne 0 ] && [ "$re" -eq 0 ] && [ "$ena" -eq 1 ] && [ "$enw" -eq 0 ] && [ "$eflip" -eq 1 ] && [ "$(_baseline_record "$e/.published-itinerary")" = "$S_DA" ] && [ ! -e "$e/.published-itinerary.next" ] && [ "$(sb_temps "$e")" -eq 0 ] && [ "$est" = unconfirmed ] && [ "$rg" -eq 0 ] && [ "$ga" -eq 1 ] && [ "$grec" -eq 1 ] && [ "$gsame" -eq 1 ] && [ "$gsame_b" -eq 1 ] && [ ! -e "$g/.published-itinerary.next" ] && [ "$rx" -eq 0 ] && [ "$xa" -eq 1 ] && [ "$xch" -eq 1 ] && [ "$(_baseline_record "$x/.published-itinerary")" = "$S_DA" ] && [ "$(_baseline_record "$x/.published-itinerary.next")" = "$rcd" ] && [ "$(sb_temps "$x")" -eq 0 ] && [ "$xst" = undetermined ] && [ "$xgr" -ne 0 ] && [ "$rxu" -eq 0 ] && [ "$xua" -eq 1 ] && [ "$xuch" -eq 1 ] && [ "$(_baseline_record "$xu/.published-itinerary")" = "$S_DA" ] && [ -d "$xu/.published-itinerary.next" ] && [ "$xust" = undetermined ] && [ "$xugr" -ne 0 ]; then
    PASS "S31e: a staged record that cannot be moved into place is left staged and named, the recorder returns 0 under errexit, and a working copy reverted to the kept baseline reads undetermined and is refused — on the recorder's own path and when it is handed the staged digest, as the three push sites hand it; handed the digest of the plan its push carried, the recorder installs that record though the render was rebuilt during the push, stages it again where it was removed during the push so that a revert reads undetermined, and, where the push re-published the recorded plan, records that plan though the render was rewritten during the push, or says the kept baseline records this same plan where it cannot write; where another plan's record, or one that cannot be read, stands staged (cell g and its twin), it leaves that record as it is, says it was changed while the push was under way, keeps the baseline, and a revert reads undetermined and is refused; controls: a movable record is consumed, the rebuilt render carries a third plan, and a removed record that cannot be staged again keeps the baseline and says so"
  else
    FAIL "S31e: rename refused: rc=$rb after=$aft left-staged=$left base=$(_baseline_record "$b/.published-itinerary") staged=$(_baseline_record "$b/.published-itinerary.next") revert-state=$st gate-rc=$gr; handed the staged digest: rc=$rp after=$pa left-staged=$pl base=$(_baseline_record "$p/.published-itinerary") staged=$(_baseline_record "$p/.published-itinerary.next") revert-state=$pst gate-rc=$pgr; rebuilt render: rc=$rc after=$ac warned=$wcc base=$(_baseline_record "$c/.published-itinerary") staged-left=$([ -e "$c/.published-itinerary.next" ] && echo 1 || echo 0); record removed: rc=$rd after=$da staged-again=$dw base=$(_baseline_record "$d/.published-itinerary") staged=$(_baseline_record "$d/.published-itinerary.next") revert-state=$dst gate-rc=$dgr; re-publish, render rewritten: rc=$re after=$ena warned=$enw rerecorded=$eflip base=$(_baseline_record "$e/.published-itinerary") state=$est; re-publish, cannot write: rc=$rg after=$ga named=$grec same-plan=$gsame unchanged=$gsame_b; another plan's record (g): rc=$rx after=$xa named=$xch base=$(_baseline_record "$x/.published-itinerary") staged=$(_baseline_record "$x/.published-itinerary.next") revert-state=$xst gate-rc=$xgr; unreadable record: rc=$rxu after=$xua named=$xuch base=$(_baseline_record "$xu/.published-itinerary") revert-state=$xust gate-rc=$xugr"
  fi
}
s27e_assert() {
  local m k em ek rsm rsk mm=0 mk=0 km=0 kk=0 same=0
  m="$(s31_trip s27em 14:00 A -)"; cp "$m/.published-itinerary" "$m.before"
  k="$(s31_trip s27ek 16:30 A -)"
  mktemp() { return 1; }
  s27_run "$m"; em="$S27_ERR"; rsm=$S27_RC
  s27_run "$k"; ek="$S27_ERR"; rsk=$S27_RC
  unset -f mktemp
  case "$em" in *"records this same plan"*) mm=1 ;; esac
  case "$em" in *"keeps the baseline it already had"*) mk=1 ;; esac
  case "$ek" in *"records this same plan"*) km=1 ;; esac
  case "$ek" in *"keeps the baseline it already had"*) kk=1 ;; esac
  cmp -s "$m.before" "$m/.published-itinerary" && same=1
  if [ "$rsk" -ne 0 ] || [ "$kk" -ne 1 ] || [ "$km" -ne 0 ]; then
    FAIL "S27e: CONTROL — a baseline of another plan read rc=$rsk keep=$kk same-plan=$km (want 0, 1, 0)"
  elif [ "$rsm" -eq 0 ] && [ "$mm" -eq 1 ] && [ "$mk" -eq 0 ] && [ "$same" -eq 1 ]; then
    PASS "S27e: where the push re-published the recorded plan and no record could be written, the recorder says the kept baseline records this same plan, not that a revert would publish unasked; control: a baseline of another plan keeps that warning"
  else
    FAIL "S27e: rc=$rsm same-plan-words=$mm keep-words=$mk baseline-unchanged=$same"
  fi
}
s31f_pos() { # <body> <token> -> the offset of the token's first occurrence, or -1
  local b="$1" pre
  case "$b" in *"$2"*) pre="${b%%"$2"*}"; printf '%s' "${#pre}" ;; *) printf '%s' -1 ;; esac
}
s31f_assert() {
  local v fn push guard b gd st pu re ok=1 why="" sens spec
  for v in 'cmd_update|push_trip_site "$pub_dir" "$mine" update|require_publish_guards' \
           'cmd_rotate|push_trip_site "$pub_dir" "$mine" rotate|write_passphrase_file' \
           'cmd_publish|gh repo create|require_recordable_baseline'; do
    fn="${v%%|*}"; v="${v#*|}"; push="${v%%|*}"; guard="${v#*|}"
    b="$(declare -f "$fn")"
    gd="$(s31f_pos "$b" "$guard")"; st="$(s31f_pos "$b" stage_baseline_record)"
    pu="$(s31f_pos "$b" "$push")"; re="$(s31f_pos "$b" record_published_itinerary)"
    if [ "$gd" -ge 0 ] && [ "$st" -gt "$gd" ] && [ "$pu" -gt "$st" ] && [ "$re" -gt "$pu" ]; then :; else ok=0; why="$why $fn:$gd/$st/$pu/$re"; fi
  done
  sens="$(s31f_pos "$(declare -f cmd_update)" push_trip_site)"
  spec="$(s31f_pos "$(declare -f cmd_update)" zzq_fabricated_s31f)"
  if [ "$sens" -lt 0 ] || [ "$spec" -ge 0 ]; then
    FAIL "S31f: CONTROL — the parsed body of cmd_update locates push_trip_site at $sens and a fabricated token at $spec; the offsets below would not be measurements"
  elif [ "$ok" -eq 1 ]; then
    PASS "S31f: in update, rotate and publish the staged record is written after the guard and before the push, and the recorder runs after the push — read from the parsed bodies"
  else
    FAIL "S31f: guard/stager/push/recorder offsets out of order:$why"
  fi
}
# ── Group S, #1468 amendment 2 (CD-1, CD-2, CD-3, FM-3) — the push sites as built, the digest the stager
# hands back, and the order in which a refusal names its cause. Same three rules as above.
# s31g_words prints the command word of every statement in a parsed body strictly between the end of
# the stager's call and the push token; quoted text is read as no command at all.
# S31g READS COMMAND WORDS, NOT WRITES (X-FM-3 of the #1468 amendment-2 review). Text inside double
# quotes, a command substitution there included, is blanked before the words are read, and a
# redirection is never read, so a write made through an allowed word's argument or redirection passes
# it: `info "x $(git add -A)"`, `info x > file` and `cd "$(mktemp -d …)"` each read ok. That the two
# allowed words write nothing to the trip is read from the words themselves (info prints to standard
# output, cd changes directory), not graded here; a word outside {info, cd} is what this arm grades.
s31g_words() { # <body> <stager-token> <push-token> -> the command words between them, or '?'
  local b="$1" seg q piece out="" first=1 w
  local -a ws
  case "$b" in *"$2"*"$3"*) ;; *) printf '%s' '?'; return 0 ;; esac
  seg="${b#*"$2"}"; seg="${seg%%"$3"*}"
  while :; do
    case "$seg" in *\"*\"*) q="${seg#*\"}"; seg="${seg%%\"*} Q ${q#*\"}" ;; *) break ;; esac
  done
  seg="${seg//;/$'\n'}"; seg="${seg//&/$'\n'}"; seg="${seg//|/$'\n'}"; seg="${seg//(/$'\n'}"; seg="${seg//)/$'\n'}"
  while IFS= read -r piece; do
    if [ "$first" -eq 1 ]; then first=0; continue; fi
    read -r -a ws <<<"$piece"
    for w in ${ws[@]+"${ws[@]}"}; do
      case "$w" in if|then|else|'!'|'{'|'}') continue ;; esac
      out="$out$w "; break
    done
  done <<<"$seg"
  printf '%s' "${out% }"
}
s31g_shape() { # <body> <own-write-token> <push-token> -> " ok", or what is wrong
  local b="$1" w pre st pu var rec why="" first
  local -a ws
  case "$b" in *stage_baseline_record*) ;; *) printf '%s' 'no-stager'; return 0 ;; esac
  pre="${b%%stage_baseline_record*}"; st="${#pre}"
  case "$b" in *"$2"*) pre="${b%%"$2"*}"; [ "${#pre}" -lt "$st" ] || why="$why write-after-stager" ;; *) why="$why no-own-write" ;; esac
  case "$b" in *"$3"*) pre="${b%%"$3"*}"; pu="${#pre}"; [ "$pu" -gt "$st" ] || why="$why push-before-stager" ;; *) why="$why no-push" ;; esac
  read -r -a ws <<<"$(s31g_words "$b" stage_baseline_record "$3")"
  for w in ${ws[@]+"${ws[@]}"}; do
    case "$w" in info|cd) ;; *) why="$why between:$w" ;; esac
  done
  first="${b#*stage_baseline_record}"; first="${first%%$'\n'*}"; first="${first%%;*}"
  read -r -a ws <<<"$first"; var="${ws[3]:-}"
  rec="${b#*record_published_itinerary}"; rec="${rec%%$'\n'*}"; rec="${rec%%;*}"
  case "$var" in
    ''|*[!A-Za-z0-9_]*) why="$why no-hand-off" ;;
    *) case "$rec" in *"\"\$$var\""*|*"\"\${$var}\""*) ;; *) why="$why recorder-not-given-$var" ;; esac ;;
  esac
  printf '%s' "${why:- ok}"
}
s31g_ctl_bad()  { stage_baseline_record a b publish; git add index.html; commit_noreply . m; gh repo create z; record_published_itinerary a b; }
s31g_ctl_good() { commit_noreply . m; stage_baseline_record a b update v; info "x; git y"; ( cd q
  gh repo create z ); record_published_itinerary a b "$v"; }
s31g_assert() {
  local bad good v fn wr push b sh all="" ok=1
  bad="$(s31g_shape "$(declare -f s31g_ctl_bad)" commit_noreply 'gh repo create')"
  good="$(s31g_shape "$(declare -f s31g_ctl_good)" commit_noreply 'gh repo create')"
  for v in 'cmd_update|encrypt_verify_commit|push_trip_site "$pub_dir" "$mine" update' \
           'cmd_rotate|write_passphrase_file|push_trip_site "$pub_dir" "$mine" rotate' \
           'cmd_publish|commit_noreply|gh repo create'; do
    fn="${v%%|*}"; v="${v#*|}"; wr="${v%%|*}"; push="${v#*|}"
    b="$(declare -f "$fn")"
    sh="$(s31g_shape "$b" "$wr" "$push")"
    all="$all $fn:[$sh]"
    [ "$sh" = " ok" ] || ok=0
  done
  case "$bad" in *write-after-stager*between:git*between:commit_noreply*no-hand-off*) bad=flagged ;; esac
  if [ "$bad" != flagged ] || [ "$good" != " ok" ]; then
    FAIL "S31g: CONTROL — a planted push site with writes between its stager and its push read [$bad] (want each flaw flagged), and a clean one carrying a quoted ';' read [$good] (want ok); the readings below would not be measurements"
  elif [ "$ok" -eq 1 ]; then
    PASS "S31g: in update, rotate and publish the stager follows the command's own last write, only a progress line or the push subshell's entry into the clone stands between it and the push, and the digest it hands back is what the recorder is given — read from the parsed bodies;$all"
  else
    FAIL "S31g: push sites as built:$all"
  fi
}
s31h_assert() {
  local a x v vx vk
  a="$(s31_trip s31ha 16:30 A -)"; x="$(s31_trip s31hx 14:00 A -)"
  v="$( stage_baseline_record "$a" "$a/$S15_RENDER" update S31H_V >/dev/null 2>&1; printf '%s' "${S31H_V:-}" )"
  vx="$( S31H_V=zzq-stale; stage_baseline_record "$x" "$x/$S15_RENDER" update S31H_V >/dev/null 2>&1; printf '%s' "${S31H_V-unset}" )"
  vk="$( S31H_V=zzq-kept; stage_baseline_record "$x" "$x/$S15_RENDER" update >/dev/null 2>&1; printf '%s' "${S31H_V-unset}" )"
  if [ "$vk" != zzq-kept ]; then
    FAIL "S31h: CONTROL — called with no variable named, the stager changed one it was not given (read '$vk'), so what it hands back below would not be attributable to the argument"
  elif [ "$v" = "$S_DB" ] && [ "$(_baseline_record "$a/.published-itinerary.next")" = "$v" ] && [ "$vx" = "$S_DA" ] && [ ! -e "$x/.published-itinerary.next" ]; then
    PASS "S31h: the stager hands back, in the variable it is given, exactly the digest its staged record holds, and, over a stale value, the recorded plan's digest where the push re-publishes it and nothing is staged; control: a call that names no variable changes none"
  else
    FAIL "S31h: handed '$v' (want $S_DB, the staged record's digest '$(_baseline_record "$a/.published-itinerary.next")'); on the re-publish path '$vx' (want $S_DA, the recorded plan's), staged there=$([ -e "$x/.published-itinerary.next" ] && echo 1 || echo 0)"
  fi
}
# S31i's delete exit, keyed on the BASELINE's plan (#1468 amendment-3 review, R3-FM-2 with R3-CD-1).
# Deleting the staged record leaves the gate comparing the outgoing plan with .published-itinerary
# alone, so deleting is safe exactly where the site carries the plan THAT file records. Every
# staged-record refusal, in the gate and in confirm and on both of its branches, must condition its
# delete exit on that plan, never on the record's plan and never on nothing; the other case is told
# to publish the plan the site should carry. Trip `t` is the L1-held state the review measured: an
# S_DA baseline beside a third plan's record (the 18:15 render's digest), with the baseline's plan
# going out.
s31i_assert() {
  local n2 n3l n3d h o t dc e2 c2 e3l c3l e3d c3d eh ch eo co et ct x ok=1 ctl=1 why=""
  n2="$(s15_dangling "s31in2-$RANDOM")"; s_record "$n2/.published-itinerary" "$S_DA" published; s_record "$n2/.published-itinerary.next" "$S_DB" published
  n3l="$(s31_trip s31in3l 14:00 A -)"; ln -s "$n3l/zzq-no-such-record" "$n3l/.published-itinerary.next"
  n3d="$(s31_trip s31in3d 14:00 A dir)"
  h="$(s31_trip s31ih 14:00 A B)"
  o="$(s31_trip s31io 14:00 A A)"
  t="$(s31_trip s31it 14:00 A -)"; s_render "$WORK/s31i-c.html" 18:15 none; dc="$(itinerary_digest "$WORK/s31i-c.html")"; s_record "$t/.published-itinerary.next" "$dc" published
  e2="$( ( require_change_confirmation "$n2" ) 2>&1 >/dev/null )"
  c2="$( ( cmd_confirm "$n2" ) </dev/null 2>&1 >/dev/null )"
  e3l="$( ( require_change_confirmation "$n3l" ) 2>&1 >/dev/null )"
  c3l="$( ( cmd_confirm "$n3l" ) </dev/null 2>&1 >/dev/null )"
  e3d="$( ( require_change_confirmation "$n3d" ) 2>&1 >/dev/null )"
  c3d="$( ( cmd_confirm "$n3d" ) </dev/null 2>&1 >/dev/null )"
  eh="$( ( require_change_confirmation "$h" ) 2>&1 >/dev/null )"
  ch="$( ( cmd_confirm "$h" ) </dev/null 2>&1 >/dev/null )"
  eo="$( ( require_change_confirmation "$o" ) 2>&1 >/dev/null )"
  co="$( ( cmd_confirm "$o" ) </dev/null 2>&1 >/dev/null )"
  et="$( ( require_change_confirmation "$t" ) 2>&1 >/dev/null )"
  ct="$( ( cmd_confirm "$t" ) </dev/null 2>&1 >/dev/null )"
  for x in "$e2" "$c2"; do
    case "$x" in *"outgoing render"*) ;; *) ok=0; why="$why render-not-named" ;; esac
    case "$x" in *"still outstanding"*) ok=0; why="$why record-named-first" ;; esac
  done
  for x in "$e3l" "$e3d" "$eo" "$et"; do
    [ -z "$(s15f_claims "${x//"$WORK"/<work>}")" ] || { ok=0; why="$why claims[$(s15f_claims "${x//"$WORK"/<work>}")]"; }
  done
  for x in "$e3l" "$c3l" "$e3d" "$c3d"; do
    case "$x" in *"present but cannot be read"*) ;; *) ok=0; why="$why unreadable-not-named" ;; esac
    case "$x" in *"Repair that file, or delete it"*) ;; *) ok=0; why="$why no-repair-exit" ;; esac
    case "$x" in *"Re-run update with the plan"*) ok=0; why="$why rerun-offered" ;; esac
  done
  for x in "$eh" "$ch" "$et" "$ct"; do
    case "$x" in *"unpublish, then publish again"*) ;; *) ok=0; why="$why no-first-publish-exit" ;; esac
    case "$x" in *"Re-run update with the plan the site should carry"*) ;; *) ok=0; why="$why no-live-plan-exit" ;; esac
  done
  for x in "$eo" "$co"; do
    case "$x" in *"still outstanding"*"names the plan going out"*) ;; *) ok=0; why="$why own-plan-record-not-named" ;; esac
    case "$x" in *"delete that file"*) ;; *) ok=0; why="$why own-plan-no-delete-exit" ;; esac
    case "$x" in *"Re-run update with the plan"*) ok=0; why="$why own-plan-rerun-offered" ;; esac
    case "$x" in *"publish the plan the site should carry"*) ;; *) ok=0; why="$why own-plan-no-live-plan-exit" ;; esac
  done
  for x in "$eh" "$ch" "$eo" "$co" "$et" "$ct"; do
    case "$x" in *"If the site carries the plan the published baseline records"*) ;; *) ok=0; why="$why delete-not-keyed-on-baseline" ;; esac
    case "$x" in *"does not carry that plan"*) ok=0; why="$why delete-keyed-on-record" ;; esac
    case "$x" in *"which plan the site carries, delete"*) ok=0; why="$why delete-unconditioned" ;; esac
  done
  case "$eh" in *"still outstanding"*"Re-run update with the plan"*) ;; *) ctl=0 ;; esac
  case "$eh" in *"names the plan going out"*) ctl=0 ;; esac
  if [ "$ctl" -ne 1 ]; then
    FAIL "S31i: CONTROL — the gate on a held trip with a readable record of another plan and its render did not name the outstanding record and its re-run exit alone, so the readings below are not measurements"
  elif [ "$ok" -eq 1 ]; then
    PASS "S31i: the gate and confirm name the cause the resolver acted on, in its order — an unidentifiable render beside a readable staged record is named as the render, and a staged record that cannot be read is told to be repaired or deleted, never re-run; a held trip's refusal names the first-publish exit (unpublish, then publish); a record naming the plan going out, which the baseline records as well, is told to delete the file, never to re-run update with that plan; every staged-record refusal, a third plan's record beside the baseline included, conditions its delete exit on the plan the published baseline records and tells the other case to publish the plan the site should carry; control: the held trip whose record names another plan names its record and the re-run exit"
  else
    FAIL "S31i: cause order and exits:$why"
  fi
}
s27c_assert
s27d_assert
s27e_assert
s29e_assert
s31a_assert
s31b_assert
s31c_assert
s31d_assert
s31e_assert
s31f_assert
s31g_assert
s31h_assert
s31i_assert
md_flips change_confirmation_state   "S31a" s31a_assert
md_flips stage_baseline_record       "S31d" s31d_assert
md_flips record_published_itinerary  "S31e" s31e_assert
md_flips stage_baseline_record       "S31h" s31h_assert
md_flips require_change_confirmation "S31i" s31i_assert

# ── S30 — CASE 1: THE ITINERARY DIGEST NO LONGER DEPENDS ON THE CALLER'S LOCALE (#1468). The
# normalization runs under LC_ALL=C, with the 18 non-ASCII code points macOS's UTF-8 [:space:]
# holds rewritten to an ASCII space first. s30_render writes S0's 14:00 render with the given
# bytes in place of the space between "Miradouro" and "da"; the space itself gives S0's own
# render. S30_U is the first UTF-8 locale this host lists, read through `locale charmap`, and an
# arm that needs it and finds none fails as fixture integrity, never skips.
s30_render() { # <file> <bytes standing where the space after "Miradouro" stands>
  local t
  s_render "$1" 14:00 none; t="$(cat "$1")"; printf '%s\n' "${t/Miradouro da/Miradouro$2da}" > "$1"
}
S30_U=""
for s30l in C.UTF-8 en_US.UTF-8; do
  if [ "$(LC_ALL=$s30l locale charmap 2>/dev/null)" = UTF-8 ]; then S30_U="$s30l"; break; fi
done
S30_CP=( $'\302\240' $'\341\232\200' $'\342\200\200' $'\342\200\201' $'\342\200\202' $'\342\200\203' $'\342\200\204' $'\342\200\205' $'\342\200\206' $'\342\200\207' $'\342\200\210' $'\342\200\211' $'\342\200\212' $'\342\200\250' $'\342\200\251' $'\342\200\257' $'\342\201\237' $'\343\200\200' )

# ── S30a — THE SUBJECT. Eighteen renders, each carrying one of the 18 code points (U+00A0, U+1680,
# U+2000–U+200A, U+2028, U+2029, U+202F, U+205F, U+3000) between two words, each digest a 64-hex
# token equal to the space render's under LC_ALL=C and under the UTF-8 locale — so a digest macOS
# recorded under a UTF-8 locale is reproduced under any locale, and no baseline or approval code
# recorded there moves. Fixture integrity first: a UTF-8 locale is listed, and the space render
# digests to S0's token. ARMED-RED: the unpinned body the digest had before the pin, put back,
# reads the U+00A0 render as another plan under LC_ALL=C; the production digest is then
# re-evaluated from its saved text. Registered: with the digest removed every token is empty.
s30a_assert() {
  local i f sp dsc dsu dc du n=0 bad="" mut msp
  sp="$WORK/s30a-space.html"; s30_render "$sp" ' '
  dsc="$(LC_ALL=C itinerary_digest "$sp")"; dsu="$(LC_ALL=$S30_U itinerary_digest "$sp")"
  for i in "${!S30_CP[@]}"; do
    f="$WORK/s30a-$i.html"; s30_render "$f" "${S30_CP[$i]}"
    dc="$(LC_ALL=C itinerary_digest "$f")"; du="$(LC_ALL=$S30_U itinerary_digest "$f")"
    if [ "${#dc}" -eq 64 ] && [ "$dc" = "$dsc" ] && [ "$du" = "$dsc" ]; then n=$((n+1)); else bad="$bad cp$i:${dc:0:8}/${du:0:8}"; fi
  done
  itinerary_digest() { [ -r "${1:-}" ] || return 0; local text dg; text="$(strip_to_itinerary_text "$1")" || return 0; dg="$(set -o pipefail; printf '%s' "$text" | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//' | _digest_of)" || return 0; printf '%s' "$dg"; }   # MUTANT: the unpinned body
  mut="$(LC_ALL=C itinerary_digest "$WORK/s30a-0.html")"; msp="$(LC_ALL=C itinerary_digest "$sp")"
  sb_restore itinerary_digest
  if [ -z "$S30_U" ] || [ "$dsc" != "$S_DA" ] || [ "$dsu" != "$S_DA" ]; then
    FAIL "S30a: fixture integrity — the UTF-8 locale is '${S30_U:-none listed}', and the space render digests '${dsc:0:12}' under C and '${dsu:0:12}' under it against S0's '${S_DA:0:12}', so the 18 comparisons below would not be about the code points"
  elif [ "$n" -eq 18 ] && [ "${#S30_CP[@]}" -eq 18 ] && [ -n "$mut" ] && [ "$mut" != "$msp" ]; then
    PASS "S30a: each of the $n renders carrying one of the 18 code points digests to the space render's 64-hex token under LC_ALL=C and under $S30_U — the digest no longer depends on the caller's locale; ARMED-RED: the unpinned body reads the U+00A0 render as another plan under LC_ALL=C"
  else
    FAIL "S30a: $n of ${#S30_CP[@]} code points digest equal under both locales;${bad:- none other} ARMED-RED read '${mut:0:12}' against the space render's '${msp:0:12}' (want two different tokens)"
  fi
}
s30a_assert

# ── S30b — SPECIFICITY. Code points outside the set must still read as text: U+0085 (the one
# White_Space member macOS's class does not hold), U+00C9 and U+200B each digest to a token other
# than the space render's under both locales; the ASCII render digests the same under both; and
# the legacy digest the baseline shim compares reads the U+00A0 render as the space render under
# both locales, so a legacy baseline of that plan still matches it.
s30b_assert() {
  local sp f d c u ok=1 why="" asc asu lnc lnu lsp
  sp="$WORK/s30b-space.html"; s30_render "$sp" ' '
  asc="$(LC_ALL=C itinerary_digest "$sp")"; asu="$(LC_ALL=$S30_U itinerary_digest "$sp")"
  for c in $'\302\205' $'\303\211' $'\342\200\213'; do
    f="$WORK/s30b-$RANDOM.html"; s30_render "$f" "$c"
    d="$(LC_ALL=C itinerary_digest "$f")"; u="$(LC_ALL=$S30_U itinerary_digest "$f")"
    [ "${#d}" -eq 64 ] && [ "${#u}" -eq 64 ] && [ "$d" != "$asc" ] && [ "$u" != "$asc" ] || { ok=0; why="$why outside-set:${d:0:8}/${u:0:8}"; }
  done
  f="$WORK/s30b-nbsp.html"; s30_render "$f" $'\302\240'
  lnc="$(LC_ALL=C _legacy_itinerary_digest "$f")"; lnu="$(LC_ALL=$S30_U _legacy_itinerary_digest "$f")"; lsp="$(LC_ALL=C _legacy_itinerary_digest "$sp")"
  if [ -z "$S30_U" ] || [ "${#asc}" -ne 64 ]; then
    FAIL "S30b: fixture integrity — the UTF-8 locale is '${S30_U:-none listed}' and the ASCII render digests '${asc:0:12}', so the comparisons below would not be measurements"
  elif [ "$ok" -eq 1 ] && [ "$asc" = "$asu" ] && [ -n "$lsp" ] && [ "$lnc" = "$lsp" ] && [ "$lnu" = "$lsp" ]; then
    PASS "S30b: U+0085, U+00C9 and U+200B each read as text, a token other than the space render's, under both locales; the ASCII render digests the same under both; and the legacy digest reads the U+00A0 render as the space render under both, so a legacy baseline still matches its plan"
  else
    FAIL "S30b:$why ASCII C/UTF-8 ${asc:0:8}/${asu:0:8}; legacy U+00A0 C/UTF-8 ${lnc:-empty}/${lnu:-empty} against the space render's ${lsp:-empty}"
  fi
}
s30b_assert

# ── S30c — THE BYTE THAT USED TO STOP THE PIPELINE. The 14:00 render with byte 0xC9, which is not
# valid UTF-8, between two words: under the UTF-8 locale its digest is a 64-hex token equal to
# the one under LC_ALL=C. Before the pin BSD `tr` stopped there under a UTF-8 locale, and the
# digest read no answer; under LC_ALL=C no stage stops on it, and it is digested as it stands.
s30c_assert() {
  local f dc du
  f="$WORK/s30c.html"; s30_render "$f" $'\311'
  dc="$(LC_ALL=C itinerary_digest "$f")"; du="$(LC_ALL=$S30_U itinerary_digest "$f")"
  if [ -z "$S30_U" ] || [ "${#dc}" -ne 64 ]; then
    FAIL "S30c: fixture integrity — the UTF-8 locale is '${S30_U:-none listed}' and the render digests '${dc:0:12}' under LC_ALL=C, so the comparison below would not be a measurement"
  elif [ "${#du}" -eq 64 ] && [ "$du" = "$dc" ]; then
    PASS "S30c: a render carrying a byte that is not valid UTF-8 digests under $S30_U to the same 64-hex token as under LC_ALL=C — no stage stops on it"
  else
    FAIL "S30c: under $S30_U the render with 0xC9 digests '${du:-empty}', against '$dc' under LC_ALL=C"
  fi
}
s30c_assert

# ── S30d — THE RESTORE (S26a's rule, applied to this block). Every production function this block
# saved reads exactly as saved, and none of the commands its arms stub is still a function.
# CONTROL: the recorder's saved text is not empty, so the comparison reads a definition.
SB30_MOVED=""
for sbfn in $SB_SAVED_FNS; do
  sbv="SB_SAVED_$sbfn"
  if [ "$(declare -f "$sbfn")" != "${!sbv}" ]; then SB30_MOVED="$SB30_MOVED $sbfn"; fi
done
SB30_STUBS=""
for sbfn in mktemp mv perl tr gh npx rm; do
  declare -F "$sbfn" >/dev/null 2>&1 && SB30_STUBS="$SB30_STUBS $sbfn"
done
if [ -z "$SB_SAVED_record_published_itinerary" ]; then
  FAIL "S30d: CONTROL — the saved text of record_published_itinerary is empty, so a comparison against it reads nothing"
elif [ -z "$SB30_MOVED" ] && [ -z "$SB30_STUBS" ]; then
  PASS "S30d: every production function this block saved reads exactly as saved, and none of mktemp, mv, perl, tr, gh, npx or rm is still a shell function — the arms after this one grade production code"
else
  FAIL "S30d: functions not restored:[${SB30_MOVED# }], stubs left:[${SB30_STUBS# }]"
fi

# The block's registrations, at its end as PP and RV register inside their own groups. Each
# re-runs the SAME argv its live arm ran, with the named subject removed.
md_flips record_published_itinerary "S27a" s27a_assert
md_flips change_confirmation_state  "S28a" s28a_assert
md_flips _baseline_record           "S28e" s28e_assert
md_flips require_recordable_baseline "S29a" s29a_assert
md_flips itinerary_digest            "S30a" s30a_assert

# ═════════════════════════════════════════════════════════════════════════════════
# Group T, #719 — THE APPROVAL PAIR ON THE RENDER: the schema's two fields, the band's statement,
# the site verb's name-free read, and the band's excision with the pair inside it.
#
#   T9   INT-6   C19 declares exactly the pair — typed, optional, no threshold — and the band's
#                static statement names the organizer and never says that travellers approved
#   T10  INT-7   the site verb reads neither approver sidecar, and two trips differing only in
#                who approved render byte-identically
#   T11  INT-9   the mapping reads the count after the date and conditions the pair on it, and
#                the widest band the contract admits is still excised from the digest
#
# As T1–T8 do, every rule is read out of the documents — the fence, § 3 of the component
# contract and the `site` verb's section — and each extractor is shown to recover a value injected
# into a mutated copy of its own source, so a green here is the corpus's and not this file's.
# These arms follow S26a because T10b reads S25a's records. Offline; no legitimate skip.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "The approval pair on the render — #719 (INT-6, INT-7, INT-9):"

# The per-class fields C19's fence declares: every `field` line after its `# Per-class fields`
# comment, as `name|type`, in document order.
t9_perclass() { # [<schema-file>]
  awk '/^```artifact-schema/ { f = 1; next } f && /^```/ { exit }
       f && /^# Per-class fields/ { p = 1; next }
       f && p && /^field / { n = $2; sub(/:$/, "", n); t = $0; sub(/^field [^:]*: /, "", t); print n "|" t }' "${1:-$T_SCHEMA}"
}
T9_FIELDS="$(t9_perclass)"
T9_N="$(printf '%s\n' "$T9_FIELDS" | awk 'NF' | wc -l | tr -d ' ')"
T9_CNT=0; T9_CODE=0; T9_THR=0
while IFS= read -r t9f; do
  case "$t9f" in 'approval-count|optional integer') T9_CNT=1 ;; 'approval-code|optional slug') T9_CODE=1 ;; esac
  case "${t9f%%|*}" in *threshold*|*required*) T9_THR=$((T9_THR+1)) ;; esac
done <<<"$T9_FIELDS"
awk '{ print } /^field coordination-since:/ { print "field zzqfab: optional integer" }' "$T_SCHEMA" > "$T_DIR/t9_schema_mut.md"
T9_CTL="$(t9_perclass "$T_DIR/t9_schema_mut.md")"
T9_CTLHIT=0; case "$T9_CTL" in *'zzqfab|optional integer'*) T9_CTLHIT=1 ;; esac
if [ "$T9_CTLHIT" -ne 1 ]; then
  FAIL "T9a-CTL: a field injected into a copy of $(basename "$T_SCHEMA") was not recovered — the extractor is not reading the fence, so its count below would be this file's"
elif [ "$T9_N" -eq 4 ] && [ "$T9_CNT" -eq 1 ] && [ "$T9_CODE" -eq 1 ] && [ "$T9_THR" -eq 0 ]; then
  PASS "T9a: C19's fence declares exactly 4 per-class fields — the coordination pair and the approval pair — with approval-count typed 'optional integer' and approval-code 'optional slug', and no per-class field names a threshold or a requirement; an injected field was recovered from a mutated copy"
else
  FAIL "T9a: per-class fields=$T9_N (want 4), approval-count typed right=$T9_CNT, approval-code typed right=$T9_CODE, threshold/required-named fields=$T9_THR (want 0). Fields: $(printf '%s' "$T9_FIELDS" | tr '\n' ' ')"
fi

# The band's static statement: the first bold span after "one static statement and the two
# values:" in § 3's approval-fields paragraph. Paragraph-scoped, as T5's extractor is.
T9_MARK='one static statement and the two values:'
t9_statement() { # [<spec-file>] -> the statement, or nothing
  awk -v mark="$T9_MARK" '
    BEGIN { RS = ""; FS = "\n" }
    { p = $0; gsub(/\n/, " ", p); a = index(p, mark); if (a == 0) next
      p = substr(p, a + length(mark)); i = index(p, "**"); if (i == 0) exit
      p = substr(p, i + 2); j = index(p, "**"); if (j == 0) exit
      print substr(p, 1, j - 1); exit }' "${1:-$T_SPEC}"
}
# The lexicon of a traveller-approval claim — a list, so its boundary is stated: a claim made
# entirely in other words is not seen (S15f's shape).
T9_LEX='travellers approved|travelers approved|approved by|have approved|has approved'
t9_claims() { # <text> -> the lexicon phrases the text carries
  local t="$1" out="" w IFS='|'
  shopt -s nocasematch
  for w in $T9_LEX; do case "$t" in *"$w"*) out="${out}[$w]" ;; esac; done
  shopt -u nocasematch
  printf '%s' "$out"
}
T9_STMT="$(t9_statement)"
t_inject_after_mark "$T_SPEC" "$T9_MARK" ' **Travellers approved:** and' > "$T_DIR/t9_spec_mut.md"
T9_MSTMT="$(t9_statement "$T_DIR/t9_spec_mut.md")"
T9_HITS="$(t9_claims "$T9_STMT")"; T9_MHITS="$(t9_claims "$T9_MSTMT")"
T9_PLANT="$(t9_claims 'Approved by Dana and Eli')"; T9_NEUT="$(t9_claims 'Approvals recorded for this plan')"
T9_ORG=0; case "$T9_STMT" in *organizer*) T9_ORG=1 ;; esac
if [ -z "$T9_STMT" ] || [ "$T9_MSTMT" != 'Travellers approved:' ]; then
  FAIL "T9b-CTL: the statement read '$T9_STMT' and, from a copy with a counter-statement injected, '$T9_MSTMT' — the extractor is not reading § 3, so a clean statement below would prove nothing"
elif [ -z "$T9_MHITS" ] || [ -z "$T9_PLANT" ] || [ -n "$T9_NEUT" ]; then
  FAIL "T9b: CONTROL on the lexicon — the injected counter-statement read [$T9_MHITS], a planted claim [$T9_PLANT] (both must be flagged) and a neutral line [$T9_NEUT] (must not be)"
elif [ "$T9_ORG" -eq 1 ] && [ -z "$T9_HITS" ]; then
  PASS "T9b: § 3's static statement is '$T9_STMT' — it names the organizer as the source of the count and carries none of the traveller-approval phrases; the lexicon flags an injected counter-statement and a planted claim, and passes a neutral line"
else
  FAIL "T9b: the statement '$T9_STMT' names the organizer=$T9_ORG and carries claim phrases [$T9_HITS] — the band would say travellers approved, which is the organizer's statement on their behalf"
fi

# ── T10a — the site verb's read declaration names neither approver sidecar.
t10_reads() { # [<trip-md>] -> every backticked token of the `site` section's **Reads:** paragraph
  awk '/^## site$/ { s = 1; next } s && /^## / { exit }
       s && /^\*\*Reads:\*\*/ { r = 1 } s && r && /^$/ { exit }
       s && r { print }' "${1:-$T_TRIPMD}" > "$T_DIR/t10_reads.txt"
  t5_tokens "$T_DIR/t10_reads.txt"
}
T10_TOK="$(t10_reads)"
T10_N="$(printf '%s\n' "$T10_TOK" | awk 'NF' | wc -l | tr -d ' ')"
T10_HIT=0
while IFS= read -r t10t; do case "$t10t" in *.approvers*|*.approvals*) T10_HIT=$((T10_HIT+1)) ;; esac; done <<<"$T10_TOK"
awk '/^## site$/ { s = 1 } s && /^\*\*Reads:\*\*/ && !d { sub(/\*\*Reads:\*\*/, "**Reads:** `trips/<slug>/.approvers` — injected;"); d = 1 } { print }' "$T_TRIPMD" > "$T_DIR/t10_trip_mut.md"
T10_CTL=0
while IFS= read -r t10t; do case "$t10t" in *.approvers*) T10_CTL=1 ;; esac; done <<<"$(t10_reads "$T_DIR/t10_trip_mut.md")"
T10_CONF=0; case "$T10_TOK" in *'.change-confirmed'*) T10_CONF=1 ;; esac
if [ "$T10_CTL" -ne 1 ] || [ "$T10_CONF" -ne 1 ]; then
  FAIL "T10a-CTL: an injected sidecar path was recovered=$T10_CTL and the paragraph's own .change-confirmed token was found=$T10_CONF — the extractor is not reading the site verb's read declaration"
elif [ "$T10_HIT" -eq 0 ] && [ "$T10_N" -gt 0 ]; then
  PASS "T10a: the $T10_N backticked token(s) of the site verb's read declaration name neither .approvers nor .approvals — it reads the record, never the roster keys; ARMED-RED — the same predicate over a copy with a sidecar path injected into that declaration finds it"
else
  FAIL "T10a: the site verb's read declaration names an approver sidecar in $T10_HIT token(s) — a build reading it could render who was declared or who approved"
fi

# ── T10b — renders built to the contract from S25a's two records are byte-identical, and both
# carry every roster name in the hero: names reach the page as bound content either way, and
# approver-ness is what never does.
t10_render() { # <trip> <out> — hero from the roster's Person cells, the pair and band from the record
  local d="$1" out="$2" names="" line cnt="" dg=""
  while IFS= read -r line; do
    case "$line" in '| Person'*|'|---'*) ;; '| '*) line="${line#| }"; names="$names ${line%% |*}" ;; esac
  done < "$d/trip-context.md"
  while IFS= read -r line; do
    case "$line" in approval-count=*) cnt="${line#approval-count=}" ;; digest=*) dg="${line#digest=}" ;; esac
  done < "$d/.change-confirmed"
  {
    printf '<!--\nartifact: %s\nschema-version: 1\ntrip: porto-2027\nwriter: site\nlifecycle: output\nprovenance: derived\npublish: output\ngenerated: 2027-06-02\n' "$S12_ART"
    printf 'coordination-state: updated\ncoordination-since: 2027-06-02\napproval-count: %s\napproval-code: %s\n-->\n' "$cnt" "$dg"
    printf '<!DOCTYPE html><html><body><section class="hero"><h1>Porto 2027</h1><p>%s</p></section>\n' "${names# }"
    printf '<div class="%s is-updated"><span>Recently updated</span> <time>2027-06-02</time> <span>%s</span> <span>%s</span> <span>%s</span> <code>%s</code></div>\n' "$T_CLASS" "$T9_STMT" "$cnt" "$(_code_prefix "$dg")" "$dg"
    printf '<section class="day"><p>Miradouro da Vitoria at 16:30.</p></section></body></html>\n'
  } > "$out"
}
t10_render "$SA25A" "$T_DIR/t10_a.html"; t10_render "$SA25B" "$T_DIR/t10_b.html"
T10B_SAME=0; cmp -s "$T_DIR/t10_a.html" "$T_DIR/t10_b.html" && T10B_SAME=1
T10B_NAMES=0
for t10n in Aria Beno Cass Dara Enzo; do
  case "$(cat "$T_DIR/t10_a.html")" in *"$t10n"*) T10B_NAMES=$((T10B_NAMES+1)) ;; esac
done
# ARMED-RED: a builder that also read the declaration — the read the contract forbids — renders the
# two trips differently, so the byte comparison above can see approver-ness when it leaks.
t10_render_mut() { # <trip> <out> — t10_render, plus the declared keys the site must never read
  t10_render "$1" "$2"
  printf '<!-- %s -->\n' "$(tr '\n' ' ' < "$1/.approvers")" >> "$2"
}
t10_render_mut "$SA25A" "$T_DIR/t10_ma.html"; t10_render_mut "$SA25B" "$T_DIR/t10_mb.html"
T10B_MDIFF=0; cmp -s "$T_DIR/t10_ma.html" "$T_DIR/t10_mb.html" || T10B_MDIFF=1
if [ "$T10B_SAME" -eq 1 ] && [ "$T10B_NAMES" -eq 5 ] && [ "$T10B_MDIFF" -eq 1 ]; then
  PASS "T10b: renders built to the contract from S25a's two records — declared {aria, beno} and {cass, dara}, each approving — are byte-identical, and each carries all 5 roster names in its hero: the names are bound content either way, and which of them approved never reaches the page; ARMED-RED — a builder that read the declaration renders the two differently"
else
  FAIL "T10b: the two renders are byte-identical=$T10B_SAME (want 1), carry $T10B_NAMES of 5 roster names (want 5); a declaration-reading builder renders them differently=$T10B_MDIFF (want 1)"
fi

# ── T11a — in the `site` verb's section, `approval-count=` first appears only after `confirmed=`,
# and the pair is conditioned on that line reading as a non-negative integer.
t11_order() { # [<trip-md>] -> "confirmed-offset count-offset conditioned"
  awk '/^## site$/ { s = 1; next } s && /^## / { exit } s { print }' "${1:-$T_TRIPMD}" > "$T_DIR/t11_site.txt"
  local body a b cond=0
  body="$(tr '\n' ' ' < "$T_DIR/t11_site.txt")"
  a="${body%%confirmed=*}"; b="${body%%approval-count=*}"
  case "$body" in *'approval-count='*'reads as a non-negative integer'*) cond=1 ;; esac
  printf '%s %s %s' "${#a}" "${#b}" "$cond"
}
read -r T11_CONF T11_CNT T11_COND <<<"$(t11_order)"
awk '/^## site$/ { s = 1 } s && /^\*\*Reads:\*\*/ && !d { sub(/\*\*Reads:\*\*/, "**Reads:** the `approval-count=` line first;"); d = 1 } { print }' "$T_TRIPMD" > "$T_DIR/t11_trip_mut.md"
read -r T11_MCONF T11_MCNT _ <<<"$(t11_order "$T_DIR/t11_trip_mut.md")"
if [ "$T11_MCNT" -ge "$T11_MCONF" ]; then
  FAIL "T11a-CTL: with approval-count= injected ahead of confirmed= in a copy, the order read count=$T11_MCNT against confirmed=$T11_MCONF — the extractor cannot see an inversion"
elif [ "$T11_CONF" -lt "$T11_CNT" ] && [ "$T11_COND" -eq 1 ]; then
  PASS "T11a: in the site verb's section confirmed= first appears at offset $T11_CONF and approval-count= at $T11_CNT — the count is read after the date — and the pair is conditioned on that line reading as a non-negative integer; an injected inversion in a copy is detected"
else
  FAIL "T11a: confirmed= at $T11_CONF, approval-count= at $T11_CNT (want the count after), conditioned=$T11_COND (want 1)"
fi

# ── T11b — THE WIDEST BAND THE CONTRACT ADMITS IS STILL EXCISED. An `updated` band carrying the
# statement read from § 3, a count of 999, the grouped prefix and the full code stays inside the
# excision cap and flat, so the render digests exactly as its band-free twin. CONTROL: the same
# band with one nested element of the band's own tag is NOT excised — the flat-markup rule, measured.
T11_CODE="$(printf 'the widest code' | _digest_of)"
t11_page() { # <file> <band-or-empty>
  printf '<!DOCTYPE html><html><body><section class="hero"><h1>Porto 2027</h1></section>\n%s<section class="day"><p>Miradouro da Vitoria at 16:30.</p></section></body></html>\n' "$2" > "$1"
}
T11_REST="<time>2027-06-02</time> <span>$T9_STMT</span> <span>999</span> <span>$(_code_prefix "$T11_CODE")</span> <code>$T11_CODE</code>"
T11_INNER="<span>Recently updated</span> $T11_REST"
t11_page "$T_DIR/t11_none.html" ''
t11_page "$T_DIR/t11_flat.html" "<div class=\"$T_CLASS is-updated\">$T11_INNER</div>
"
# The nested element opens the band, so the lazy match stops at ITS closing tag and the rest of
# the band — the date, the statement, the count and the code — is left inside the digest.
t11_page "$T_DIR/t11_nest.html" "<div class=\"$T_CLASS is-updated\"><div><span>Recently updated</span></div> $T11_REST</div>
"
T11_DN="$(itinerary_digest "$T_DIR/t11_none.html")"
T11_DF="$(itinerary_digest "$T_DIR/t11_flat.html")"
T11_DX="$(itinerary_digest "$T_DIR/t11_nest.html")"
T11_LEN=${#T11_INNER}
if [ -z "$T9_STMT" ] || [ -z "$T11_DN" ]; then
  FAIL "T11b: the statement ('$T9_STMT') or the band-free digest ('$T11_DN') is empty, so the equality below would compare nothing"
elif [ "$T11_LEN" -le "$_COORD_NOTICE_CAP" ] && [ "$T11_DF" = "$T11_DN" ] && [ "$T11_DX" != "$T11_DN" ]; then
  PASS "T11b: an updated band carrying the statement, a count of 999, the grouped prefix and the full code is $T11_LEN characters against the cap of $_COORD_NOTICE_CAP, and it is excised — the render digests exactly as its band-free twin; the control, the same band with one nested element of its own tag, is NOT excised, which is the flat-markup rule measured"
else
  FAIL "T11b: band length $T11_LEN against cap $_COORD_NOTICE_CAP; flat band excised=$([ "$T11_DF" = "$T11_DN" ] && echo 1 || echo 0) (want 1); nested band left in the digest=$([ "$T11_DX" != "$T11_DN" ] && echo 1 || echo 0) (want 1)"
fi

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

# PF2 — no unbraced dollar-name is directly followed by a non-ASCII byte, in this suite or the
# publish script. Under a UTF-8 locale, bash 3.2 — macOS's /bin/bash — reads such a byte as part
# of the NAME: a name followed straight by an ellipsis expands a variable whose name ends in the
# ellipsis's first byte, which is unset, and under set -u the run dies. That is how unpublish's
# delete path died, deleting nothing, on the platform this suite runs on, while every CI run on
# bash 5 stayed green. The scan is perl under LC_ALL=C, so its byte class means bytes on every
# host and every grep; a site planted in a control file is the evidence that it can find one.
PF2_CTL="$WORK/pf2-control.sh"; printf 'x=1; echo "$x\342\200\246"\n' > "$PF2_CTL"
pf2_scan() { LC_ALL=C perl -ne 'while (/\$[A-Za-z_]\w*[\x80-\xff]/g) { (my $f = $ARGV) =~ s{.*/}{}; print "$f:$.\n" } close ARGV if eof' "$@" 2>/dev/null; }
PF2_CTL_HITS="$(pf2_scan "$PF2_CTL")"
PF2_HITS="$(pf2_scan "$SELF" "$SELF_PUBLISH")"
if [ -z "$PF2_CTL_HITS" ]; then
  FAIL "PF2: the scan did not find the site planted in its control file, so its zero on this suite and the publish script would prove nothing. VERDICT WITHHELD"
elif [ -z "$PF2_HITS" ]; then
  PASS "PF2: no unbraced dollar-name is directly followed by a non-ASCII byte in this suite or the publish script, so bash 3.2 cannot read a multibyte character into a variable name here. The planted control site was found, so the zero is a measurement"
else
  FAIL "PF2: an unbraced dollar-name is directly followed by a non-ASCII byte at: $(tr '\n' ' ' <<< "$PF2_HITS")— under macOS's bash 3.2 in a UTF-8 locale that byte becomes part of the name, and set -u kills the run. Brace the name"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group MD — the Discriminating-Evidence Rule, asserted against this file.
#
# THE RULE. An assertion is MUTATION-DETECTABLE iff every path to its PASS requires
# evidence the subject could only have produced by RUNNING. Equivalently: PASS may never
# be reached on a branch a DEGENERATE outcome also reaches — an absent subject, an empty
# haystack, an unreadable input, an empty population.
#
# WHY A GROUP AND NOT A CONVENTION. Deleting verify_ciphertext outright from the publish
# script left A, C, C2 and G2 all reporting PASS, and deleting cmd_list entirely left I5
# reporting PASS with the suite exiting 0. The suite DID go red under the first of those
# mutations — through B, E4, G1 and S10, assertions that happen to point the other way and
# have nothing to do with the defect. So a suite-level red/green oracle certifies a fix
# that changed nothing, and two of those four collateral assertions live in the
# real-StatiCrypt group, which skips without npx: the redness was accidental AND
# environment-dependent. This group therefore grades PER ASSERTION.
#
# TWO ARMS, closing different halves.
#   The DYNAMIC arm re-runs a REGISTERED assertion in a subshell with its subject
#   `unset -f` and requires exactly one FAIL and no PASS. It is the criterion made
#   executable: for assertion X over subject S, removing S must flip X specifically.
#   The STATIC arm scans this file for the polarity-negative SHAPE, so an assertion ADDED
#   later in that shape is caught even though nobody registered it. Registration alone
#   would close today's five and leave the growth surface open, and the growth is real:
#   two sibling suites gained +499 and +278 lines in a single prior release.
#
# THE VACUITY GUARD RUNS FIRST, for the same reason PF1's and RS0's do. A scan that cannot
# read its input, or that finds no instance of the REMEDIATED form, has a zero on the
# defective form that proves nothing. MD0 fails loud on each degenerate input before any
# count renders a verdict.
#
# THE CONTROLS ARE STANDING ARMS rather than a check performed once at authoring time.
# MD1 proves the SCANNER can tell the defective shape from the sound one, over a fixture
# built here; MD4 proves the ORACLE convicts a legacy-shaped assertion; MD5 proves the same
# oracle certifies a remediated one. Without all three, a green MD proves only that MD ran.
#
# WHAT THIS GROUP DELIBERATELY DOES NOT DO. It does not grade a Class-2 (zero-population)
# verdict as a defect. `[ "$n" -eq 0 ] && PASS` is CONDITIONAL, not broken: it is sound
# when it states its denominator and carries a sensitivity arm, and many here already do.
# MD3 reports that population with its denominator so the residual is carried on every run
# rather than in a comment; it is remediated on touch, not in bulk.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group MD — every PASS here must require evidence its subject could only have produced by running."

# ── The three shapes the STATIC arm decides. Written down, because what it matches is an
# ENUMERATION WITH A STATED BOUNDARY and not a closed class.
#
#   Form 1  one line:   if <cond>; then FAIL "<id>: …"; else PASS "<id>: …"; fi
#   Form 2  block:      if|elif <cond>; then / FAIL "<id>: …" / else / PASS "<id>: …"
#   Form 3  trailing:   if|elif <cond>; then FAIL "<id>: …"; <more statements>
#                       else PASS "<id>: …"
#
# in each case ONLY when <cond> is LIVE — a command invocation, a here-string probe or an
# external tool, i.e. something that can exit 127 ("absent") or 2 ("could not read"). A
# condition opening with `[`, `[[`, `test` or `((` is a shell test: it cannot report an
# absent subject, so a PASS on its else limb is not this defect and is NOT flagged. Form 3
# is the one that matters most and is the easiest to miss — it was found by measurement
# rather than by reading, and it carries 36 of the 59 sites counted across the five suites
# that existed when this group was installed.
#
# The condition is read up to the FIRST `;`. What is OUTSIDE this scan, so the next vector
# is a documented exclusion rather than a surprise: a condition carrying an embedded `;`,
# a verdict reached through a `case` arm, a verdict whose id is only known at call time, a
# limb separated from its opener by a non-comment statement, and any verdict inside a
# here-document. It fails open on each. The DYNAMIC arm covers a registered assertion
# regardless of shape; the static arm is the net under the ones nobody registers.
MD_RE_OPENF='^(if|elif)[[:space:]]+([^;]+);[[:space:]]*then[[:space:]]+FAIL[[:space:]]+"'
MD_RE_OPENB='^(if|elif)[[:space:]]+([^;]+);[[:space:]]*then[[:space:]]*$'
MD_RE_INLE=';[[:space:]]*else[[:space:]]+PASS[[:space:]]+"([^":]*):'
MD_RE_ELSEP='^else[[:space:]]+PASS[[:space:]]+"([^":]*):'
MD_RE_FAILV='^FAIL[[:space:]]+"'
MD_RE_PASSV='^PASS[[:space:]]+"([^":]*):'
MD_RE_ZERO='(-eq|-le|-lt)[[:space:]]+0([[:space:]]|\]|$)|-z[[:space:]]+"'

MD_L=(); MD_N=0; MD_J=-1
MD_C1_IDS=""; MD_C1_N=0; MD_C2_N=0; MD_PASS_N=0; MD_RC_N=0; MD_UNREAD=0
md_reset() { MD_C1_IDS=""; MD_C1_N=0; MD_C2_N=0; MD_PASS_N=0; MD_RC_N=0; MD_UNREAD=0; }

md_live() {   # md_live <condition> -> 0 when the condition can report an ABSENT subject
  local c="$1"
  c="${c#"${c%%[![:space:]]*}"}"
  case "$c" in '!'*) c="${c#!}"; c="${c#"${c%%[![:space:]]*}"}" ;; esac
  case "$c" in ''|'['*|'test '*|'(('*) return 1 ;; esac
  return 0
}

md_next() {   # md_next <index> -> MD_J = next non-blank, non-comment index STRICTLY after it
  local j=$(( $1 + 1 )) t
  while [ "$j" -lt "$MD_N" ]; do
    t="${MD_L[$j]}"; t="${t#"${t%%[![:space:]]*}"}"
    case "$t" in ''|'#'*) j=$((j+1)); continue ;; esac
    MD_J=$j; return 0
  done
  MD_J=-1; return 1
}

md_scan() {   # md_scan <file> -> accumulates MD_C1_IDS MD_C1_N MD_C2_N MD_PASS_N MD_RC_N MD_UNREAD
  local f="$1"
  if [ ! -r "$f" ]; then MD_UNREAD=$((MD_UNREAD+1)); return 0; fi
  MD_L=(); local ln
  while IFS= read -r ln || [ -n "$ln" ]; do MD_L+=("$ln"); done < "$f"
  MD_N=${#MD_L[@]}
  local i s t u c id
  for (( i=0; i<MD_N; i++ )); do
    s="${MD_L[$i]}"; s="${s#"${s%%[![:space:]]*}"}"
    case "$s" in *'PASS "'*)     MD_PASS_N=$((MD_PASS_N+1)) ;; esac
    case "$s" in *'expect_rc '*) MD_RC_N=$((MD_RC_N+1)) ;; esac
    # ── Class 2 — a PASS gated on an empty population. Counted, never failed.
    if [[ "$s" =~ $MD_RE_ZERO ]]; then
      case "$s" in
        *'PASS "'*) MD_C2_N=$((MD_C2_N+1)) ;;
        *) if [[ "$s" =~ $MD_RE_OPENB ]] && md_next "$i"; then
             t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
             [[ "$t" =~ $MD_RE_PASSV ]] && MD_C2_N=$((MD_C2_N+1))
           fi ;;
      esac
    fi
    # ── Class 1 — the polarity-negative shape over a live condition. BASH_REMATCH is
    # clobbered by every [[ =~ ]], so each capture is taken on the line that produced it.
    c=""; id=""
    if [[ "$s" =~ $MD_RE_OPENF ]]; then
      c="${BASH_REMATCH[2]}"
      if [[ "$s" =~ $MD_RE_INLE ]]; then
        id="${BASH_REMATCH[1]}"
      elif md_next "$i"; then
        t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
        if [[ "$t" =~ $MD_RE_ELSEP ]]; then
          id="${BASH_REMATCH[1]}"
        elif [ "$t" = "else" ] && md_next "$MD_J"; then
          u="${MD_L[$MD_J]}"; u="${u#"${u%%[![:space:]]*}"}"
          [[ "$u" =~ $MD_RE_PASSV ]] && id="${BASH_REMATCH[1]}"
        fi
      fi
    elif [[ "$s" =~ $MD_RE_OPENB ]]; then
      c="${BASH_REMATCH[2]}"
      if md_next "$i"; then
        t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
        if [[ "$t" =~ $MD_RE_FAILV ]] && md_next "$MD_J"; then
          t="${MD_L[$MD_J]}"; t="${t#"${t%%[![:space:]]*}"}"
          if [[ "$t" =~ $MD_RE_ELSEP ]]; then
            id="${BASH_REMATCH[1]}"
          elif [ "$t" = "else" ] && md_next "$MD_J"; then
            u="${MD_L[$MD_J]}"; u="${u#"${u%%[![:space:]]*}"}"
            [[ "$u" =~ $MD_RE_PASSV ]] && id="${BASH_REMATCH[1]}"
          fi
        fi
      fi
    fi
    if [ -n "$id" ] && md_live "$c"; then
      MD_C1_N=$((MD_C1_N+1)); MD_C1_IDS="$MD_C1_IDS$id "
    fi
  done
  return 0
}

md_diff() {   # md_diff <a-set> <b-set> -> members of a absent from b, deduped
  local x out=" "
  # shellcheck disable=SC2086
  for x in $1; do
    case " $2 " in *" $x "*) continue ;; esac
    case "$out"  in *" $x "*) continue ;; esac
    out="$out$x "
  done
  printf '%s' "${out# }"
}
md_count() { local x n=0; for x in $1; do n=$((n+1)); done; printf '%s' "$n"; }

# ── The control fixture, built here from PIECES. This scan reads its own source, so a
# literal verdict token in the writer below would be read as a real site and the detector
# would convict the fixture it had just written — the same self-matching problem group PF
# solves with a two-piece needle. The fixture carries one site per defective form (ZMDA,
# ZMDB, ZMDF), one shell-test site that must NOT be flagged (ZMDT), one zero-population
# site (ZMDZ), and one remediated site (ZMDR). Sensitivity and specificity in one input.
MD_FIX="$WORK/md-control-fixture.sh"
MD_VP='PASS'; MD_VF='FAIL'
{
  printf 'if zzq_md_subject a; then %s "ZMDA: rejected"; else %s "ZMDA: accepted"; fi\n' "$MD_VF" "$MD_VP"
  printf 'if zzq_md_subject b; then\n  %s "ZMDB: rejected"\nelse\n  %s "ZMDB: accepted"\nfi\n' "$MD_VF" "$MD_VP"
  printf 'if zzq_md_subject c; then %s "ZMDF: rejected"; show zzq\nelse %s "ZMDF: accepted"; fi\n' "$MD_VF" "$MD_VP"
  printf 'if [ "$zzn" -eq 0 ]; then\n  %s "ZMDT: rejected"\nelse\n  %s "ZMDT: accepted"\nfi\n' "$MD_VF" "$MD_VP"
  printf 'if [ "$zzn" -eq 0 ]; then %s "ZMDZ: the population is empty"; else %s "ZMDZ: not empty"; fi\n' "$MD_VP" "$MD_VF"
  printf 'expect_rc 1 "ZMDR" "the remediated form grades an exact status" -- zzq_md_subject d\n'
} > "$MD_FIX"

md_reset; md_scan "$MD_FIX"
MD_FX_C1="${MD_C1_IDS% }"; MD_FX_C2="$MD_C2_N"; MD_FX_RC="$MD_RC_N"; MD_FX_UNREAD="$MD_UNREAD"
md_reset; md_scan "$SELF"
MD_SELF_C1="${MD_C1_IDS% }"

# ── The DECLARED residual. These sites carry the polarity-negative shape and are NOT
# remediated by this change: #327's locked scope is the five named assertions (A, C, C2,
# G2, I5) plus this oracle, and a 59-site sweep across the five suites that existed when
# that scope was locked is exactly the blind bulk edit this repository's own discipline
# forbids. They are declared here rather than
# left silent, and the diff below runs in BOTH directions — an undeclared site FAILS, and
# a declared site that no longer scans FAILS too, so remediating one obliges removing its
# line. The list can only shrink; it cannot quietly absorb a new defect.
#   F3 E3 H2 L3b S13b — live probes whose else limb is reached by rc=2 (unreadable input)
#                       or rc=127, not only by the no-match the assertion means
#   K3 K4 Q3 Q4 U3 U4 V3 V4 — `git check-ignore -q`, whose rc=128 (git error) lands on the
#                       PASS limb exactly as rc=1 (not ignored) does
MD_LEGACY='F3 E3 H2 K3 K4 Q3 Q4 U3 U4 V3 V4 L3b S13b'

if [ "$MD_UNREAD" -ne 0 ]; then
  FAIL "MD0: this file is unreadable at $SELF, so the scan below would cover nothing while reporting a zero — an unreadable scan set is a finding, never a clean file"
elif [ "$MD_PASS_N" -eq 0 ]; then
  FAIL "MD0: the scan found 0 verdict lines in this file, so its count on the polarity-negative shape proves nothing — either the PASS/FAIL grammar moved or the scan did, and no verdict below is trustworthy"
elif [ "$MD_RC_N" -eq 0 ]; then
  FAIL "MD0: the scan found 0 expect_rc sites — no assertion here is written in the REMEDIATED form, so a clean reading of the defective form is an empty scan rather than a clean file"
else
  PASS "MD0: the scan set is readable and non-degenerate — ${MD_PASS_N} verdict line(s) and ${MD_RC_N} expect_rc site(s) read from this file. Every count below is a measurement rather than an empty scan"

  # MD1 — CONTROL on the scanner, both directions, before any count it produces is read.
  if [ "$MD_FX_UNREAD" -ne 0 ]; then
    FAIL "MD1: CONTROL — the fixture at $MD_FIX was unreadable, so the scanner was never exercised and MD2's count is not a measurement"
  elif [ "$MD_FX_C1" != "ZMDA ZMDB ZMDF" ]; then
    FAIL "MD1: CONTROL on the scanner — over a fixture carrying one site per defective form (ZMDA one-line, ZMDB block, ZMDF trailing-statement), one shell-test site (ZMDT) and one remediated site (ZMDR), the scanner reported '$MD_FX_C1' rather than 'ZMDA ZMDB ZMDF'. MD2's verdict proves nothing until this control fires"
  elif [ "$MD_FX_C2" -ne 1 ]; then
    FAIL "MD1: CONTROL on the Class-2 detector — the fixture carries exactly one zero-population site (ZMDZ) and the detector found $MD_FX_C2, so MD3's inventory is not a measurement"
  elif [ "$MD_FX_RC" -eq 0 ]; then
    FAIL "MD1: CONTROL — the fixture carries one expect_rc site (ZMDR) and the scanner found none, so MD0's non-degeneracy arm is reading something other than what it claims"
  else
    PASS "MD1: CONTROL on the scanner — SENSITIVITY and SPECIFICITY over one fixture: all three defective forms are found (ZMDA, ZMDB, ZMDF), and neither the shell-test site (ZMDT, whose condition cannot report an absent subject) nor the remediated site (ZMDR) is flagged. A detector that flagged everything would be as useless as one that flagged nothing; both arms fired"

    MD_NEW="$(md_diff "$MD_SELF_C1" "$MD_LEGACY")"
    MD_STALE="$(md_diff "$MD_LEGACY" "$MD_SELF_C1")"
    MD_NDEC="$(md_count "$MD_LEGACY")"
    if [ -n "$MD_NEW" ]; then
      FAIL "MD2: assertion(s) carry the polarity-negative shape and are not in the declared residual: ${MD_NEW% } — their PASS limb is reached by rc=127 (the subject is absent) exactly as it is by the rejection they mean to assert. Either grade an exact status with expect_rc, or declare the site in MD_LEGACY above with the reason it stays"
    elif [ -n "$MD_STALE" ]; then
      FAIL "MD2: declared residual site(s) no longer carry the shape: ${MD_STALE% } — the remediation landed but its MD_LEGACY line did not come out. A declaration that outlives its defect is a standing exemption for whatever next takes that id"
    else
      PASS "MD2: every polarity-negative site in this file is accounted for — ${MD_C1_N} found, all ${MD_NDEC} declared, none undeclared and none stale, over a denominator of ${MD_PASS_N} verdict line(s). The five this card remediated (A, C, C2, G2, I5) have left the population; MD1's control is what makes that a measurement"
    fi

    PASS "MD3: INVENTORY — ${MD_C2_N} of ${MD_PASS_N} verdict line(s) gate a PASS on an empty population ('-eq 0' / '-le 0' / '-z'). That shape is CONDITIONAL rather than defective: it is sound when it states its denominator and carries a sensitivity arm, which many here already do, so it is counted on every run and remediated on touch rather than swept in bulk. The count is a measurement — MD1's Class-2 arm found the one planted site in the fixture"
  fi
fi

# ── MD4 / MD5: the controls on the ORACLE. They do not depend on the static scan, so they
# run outside MD0's guard: a broken scanner must not suppress the oracle's own evidence.
#
# zzq_md_subject exists and returns 1, so BOTH probes below pass while it is present. The
# question each control asks is what happens when it is removed. md_legacy_probe is written
# as a single-line function definition on purpose: the static arm scans THIS file, and a
# bare legacy shape here would be a real finding in its own ledger. Its job is to be
# legacy-shaped for the oracle, not to be a site in the corpus, so it is kept out of the
# scanner's reach by form — and the scanner's own sensitivity is proven on the fixture in
# MD1 instead, where a planted site is exactly what is wanted.
zzq_md_subject()  { return 1; }
md_legacy_probe() { if zzq_md_subject; then FAIL "ZMDL: subject accepted"; else PASS "ZMDL: subject rejected"; fi; }
md_sound_probe()  { expect_rc 1 "ZMDS" "the remediated form grades an exact status" -- zzq_md_subject; }

MD_CL="$(md_probe zzq_md_subject md_legacy_probe)"
if [ "$MD_CL" = "1 0" ]; then
  PASS "MD4: CONTROL on the oracle — a deliberately legacy-shaped assertion still reports pass=1 fail=0 with its subject removed, so the oracle CONVICTS the shape this group exists for. Every MD[...] verdict is therefore a measurement rather than a statement that the oracle ran"
else
  FAIL "MD4: CONTROL on the oracle did not fire — the planted legacy-shaped assertion returned '$MD_CL' rather than '1 0' with its subject removed. Until the oracle convicts a known-blind assertion, an MD[...] pass proves only that md_probe executed"
fi

MD_CS="$(md_probe zzq_md_subject md_sound_probe)"
if [ "$MD_CS" = "0 1" ]; then
  PASS "MD5: CONTROL on the oracle — a remediated assertion over the same subject returns pass=0 fail=1 with that subject removed, so the oracle CERTIFIES the sound shape as well as convicting the defective one. Both directions fired on the same subject in the same process"
else
  FAIL "MD5: CONTROL on the oracle did not fire — the planted remediated assertion returned '$MD_CS' rather than '0 1' with its subject removed. An oracle that convicts everything is as useless as one that convicts nothing"
fi

# ── The registrations. Each re-runs the SAME argv the live arm above ran, with the named
# subject removed. G2's registration is emitted earlier, inside group G, because its
# fixtures are deleted there; the other four are here.
md_flips verify_ciphertext "A"  a_assert
md_flips verify_ciphertext "C"  c_assert
md_flips verify_ciphertext "C2" c2_assert
md_flips cmd_list          "I5" i5_assert

# #328's four subjects. Each arm above grades an EXACT status and treats anything outside
# {0,1} as a probe failure, which is what makes the flip specific rather than incidental:
# with its subject removed each one reports the removal as a broken probe rather than
# silently re-classifying a 127 or a 2 as "aborted". The pairing is deliberate —
#   _guard_match          → the OVER-BLOCK arm, because a stubbed matcher passes it
#                           (measured) and the carry-through arm is what convicts that;
#   _guard_match          → the CARRY-THROUGH arm, which is that convicting arm itself;
#   verify_publishable_content → the CLEAN arm, the one whose subject is the guard rather
#                           than the matcher inside it;
#   _decode_entities and strip_to_joined_text → the ENCODING arm, the only arm both
#                           reach, and either removal now reaches it as a refusal (M5e).
md_flips _guard_match               "N2b" n2_over_assert
md_flips _guard_match               "N2c" n2_carry_assert
md_flips verify_publishable_content "N2d" n2_clean_assert
md_flips _decode_entities           "M5b" m5_assert
md_flips strip_to_joined_text       "M5b-join" m5_assert
md_flips verify_publishable_content "M5c" m5_clean_assert

# #325's subjects. The pairing follows the same rule: register the arm that CONVICTS a
# removed subject, never the arm an absent subject also satisfies.
#   nonpublishable_values → O7c, the sensitivity arm of the sub-heading exclusion. O7b is
#                           the publish arm and an absent class source publishes too, so
#                           registering O7b would certify a guard that reads nothing.
#   nonpublishable_values → O7d, which calls the class source directly and grades both
#                           directions of the shape test on one model.
#   nonpublishable_values → O7g, the DISCRIMINATION arm beside it: same subject, but its
#                           two directions are a value and a section name rather than two
#                           section-name shapes. O7f is fixture integrity and O7h grades
#                           the publish verdict, so neither is registered — O7g is the one
#                           whose whole verdict is what the class source emitted. O7j–O7m
#                           read the same stream one conjunct at a time and O7i grades
#                           their fixture, and O7n–O7q read it one emphasis rendering at a
#                           time, so none of them is registered either: a registration per
#                           arm would re-grade this one removal once for every arm and say
#                           nothing O7g does not already say about it. The rule, rather
#                           than the roster: an arm reading this stream is registered only
#                           where its verdict is not already carried by O7g.
#   nonpublishable_values → O4e, the mark-strip oracle: the whole verdict is the class
#                           source refusing to accept an uncorroborated zero.
#   nonpublishable_values → O8a, the parse sensitivity arm, whose subject is the guard's
#                           own zero rather than any fixture.
#   verify_publishable_content → O9b, the field-limb continuation arm, whose subject is
#                           the guard rather than the parse inside it.
md_flips nonpublishable_values      "O7c" o7c_assert
md_flips nonpublishable_values      "O7d" o7d_assert
md_flips nonpublishable_values      "O7g" o7g_assert
md_flips nonpublishable_values      "O8a" o8a_assert
md_flips verify_publishable_content "O9b" o9b_assert
md_flips nonpublishable_values      "O9c" o9c_assert

# The projection-status arm's subject. L17b grades an EXACT status on every cell and counts
# anything else as that cell failing, so with the guard removed every cell reads 127 and the
# one verdict the arm emits is a FAIL. Its captures go to their own directory here, so this
# re-run cannot overwrite the ones L17d read.
md_flips verify_publishable_content "L17b" l17_assert "$WORK/l17md"

# The change-summary guard's projection status (#2071), registered against the guard and against
# both arm helpers. R8b grades an EXACT status on every cell, and its cells are of both kinds in
# ONE verdict: with the guard removed every cell reads 127; with _guard_arm removed, or
# _guard_words, every cell reads rc=2, which the failing cells expect and the succeeding cells do
# not, so each removal leaves exactly one FAIL. An arm over the failing cells alone — L17b's shape
# — would read blind to either helper, which is why L17b is registered against the guard only.
md_flips verify_summary_content     "R8b"       r8_assert "$WORK/r8md"
md_flips _guard_arm                 "R8b-arm"   r8_assert "$WORK/r8md"
md_flips _guard_words               "R8b-words" r8_assert "$WORK/r8md"
# The count itself (#2071): L17g grades an EXACT status on files either side of each floor, so
# with _guard_words removed every file reads rc=2, which its over-floor files do not expect.
md_flips _guard_words               "L17g"      l17g_assert

# The published projection's '=' arms (#1467). Each grades an EXACT status on its render and on
# its twin, so with the projection removed the guard refuses its published arm (rc=2) and each
# arm's one verdict is a FAIL. One registration per surface, because each verdict rests on a
# different part of the tag reading — a comment body passed whole, a script body passed whole, a
# quoted value kept — and none of the three carries another's.
md_flips strip_to_published_text    "M1f" m1eq_assert M1f "a comment body"     "$M1EQ_CM" "$M1TW_CM"
md_flips strip_to_published_text    "M1g" m1eq_assert M1g "a script body"      "$M1EQ_SC" "$M1TW_SC"
md_flips strip_to_published_text    "M1h" m1eq_assert M1h "an attribute value" "$M1EQ_AV" "$M1TW_AV" href

# The published projection's '<' arms (#1467), on the same rule: each grades an EXACT status on
# its render and on its twin, so with the projection removed the guard refuses its published arm
# (rc=2) and each arm's one verdict is a FAIL. One registration per surface, as for the '=' arms,
# and one for the block boundary those surfaces keep, which rests on a part of the reading none of
# the three carries. M1m reads the comment surface M1j registers, so it is not registered twice.
md_flips strip_to_published_text    "M1j" m1lt_assert M1j "a comment body"     "$M1LT_CM" "$M1LW_CM"
md_flips strip_to_published_text    "M1k" m1lt_assert M1k "a script body"      "$M1LT_SC" "$M1LW_SC"
md_flips strip_to_published_text    "M1l" m1lt_assert M1l "an attribute value" "$M1LT_AV" "$M1LW_AV"
md_flips strip_to_published_text    "M1n" m1bk_assert
# The inline-tag `<` those surfaces keep (#1467): each arm grades an EXACT status, so with the
# projection removed the guard refuses its published arm (rc=2) and each arm's one verdict is a
# FAIL.
md_flips strip_to_published_text    "M1o" m1io_assert
md_flips strip_to_published_text    "M1p" m1ip_assert
# A kept tag's attribute list and the list's membership (#1467): each grades an EXACT status or
# an exact count, so with the projection removed each arm's one verdict is a FAIL.
md_flips strip_to_published_text    "M1q" m1iq_assert
md_flips strip_to_published_text    "M1r" m1ir_assert
md_flips strip_to_published_text    "M1s" m1is_assert
# Where a <script> or <style> body ends (#2055). Each grades an EXACT status, so with its subject
# removed the guard refuses that projection (rc=2) and the arm's one verdict is a FAIL. M1t rests on
# the published projection, which reads the value after a spaced closing tag; M1x and M1y rest on
# the joined and the visible projection, which read a body closed only with a space as visible text.
md_flips strip_to_published_text    "M1t" m1t_assert
md_flips strip_to_joined_text       "M1x" m1bc_assert M1x "a value split mid-word by an inline tag"            "$M1X_SP" "$M1X_EX" 'joined markup (an inline tag split a word)'
md_flips strip_to_text_blocks       "M1y" m1bc_assert M1y "a value with an attribute-carrying tag around a word" "$M1Y_SP" "$M1Y_EX" 'visible text'
# The pre-0.60.0 parity cells' armed-red control (CIAC-1). M6d grades an EXACT status from the
# legacy guard, so with the frozen published copy removed that guard refuses its published arm
# (rc=2), the pair is not flagged, and the arm's one verdict is a FAIL.
md_flips pp_legacy_pub              "M6d" m6d_assert
# The guard's fourth arm (#2068, ADR-050). Each arm grades an EXACT status on a page only that arm
# blocks, so with strip_to_shape_text removed the guard refuses the arm (rc=2) and the arm's one
# verdict is a FAIL. One registration per shape the arm restores: the span names inside a quoted
# value, #2070's list read as text, the apostrophe-opened unit, and a tag on neither list. M6b is
# registered too, through the pages it grades again live; its manifest alone could not see it.
md_flips strip_to_shape_text        "M7a" m7a_assert
md_flips strip_to_shape_text        "M7c" m7c_assert
md_flips strip_to_shape_text        "M7d" m7d_assert
md_flips strip_to_shape_text        "M7e" m7e_assert
md_flips strip_to_shape_text        "M6b" m6b_assert

# ═════════════════════════════════════════════════════════════════════════════════
# Group FZ — every verdict arm in this file must be able to FAIL.
#
# ── WHY THIS GROUP IS HERE AND NOT ONLY IN THE SUITE WHERE IT WAS FOUNDED ────────
# The rule was founded in the trip-resolution-contract suite, after that suite shipped two
# verdict arms unable to fail and both were found by a human reading predicates at Stage 7
# rather than by a check. The shape is not local to that suite. When this group was installed
# here its walker was first run over every guard suite, and it found the shape in one of them,
# three guards, rewritten in the same change. A guard whose failure branch is unreachable
# reports PASS forever, and that PASS is indistinguishable from a real one in every run, so a
# rule enforced in one suite leaves the growth surface of the others unguarded. The same
# group, the same walker and the same controls ship in every guard suite, each over its own
# source, so a finding is reported by the suite whose arm it is.
#
# ── THE RULE IT ENFORCES, AND WHY THAT RULE ──────────────────────────────────────
# Reachability is not decidable in general, so this group does not claim to decide it. It
# enforces a SHAPE, and the shape is the one both founding instances had:
#
#     a verdict guard that reaches PASS through a DISJUNCTION.
#
# Written `if A or B; then PASS ... else FAIL`, the failure branch requires `not A and
# not B` — a CONJUNCTION the author never wrote down and therefore never checked. That is
# where unsatisfiability hides. In both founding instances the second disjunct was implied
# by the first's negation, so the conjunction could never hold. The same disjunction
# reaching FAIL is the opposite case and is not flagged: `if A or B; then FAIL` fires
# whenever either holds.
#
# The shape is not merely suspicious, it is never NECESSARY. Every arm written that way can
# be written as a chain — one `elif` per condition, one message per branch — which is
# strictly better for a second reason: a branch that can fire for several reasons proves
# that something was wrong, not WHICH thing. And where a disjunct exists to excuse an empty
# population, the honest verdict for that case is never PASS, unless a live arm already
# carries that red and the message names it: otherwise it is VACUOUS where the suite has
# that verdict, or a FAIL that names the empty population. So the rule costs nothing it
# should keep.
#
# ── COVERAGE BOUNDARY — WHAT THIS GROUP DOES NOT GRADE ───────────────────────────
# Stated plainly, because an overclaiming meta-arm is the same defect one level up.
#   *  It decides a SHAPE, never reachability. A tautological guard — `[ "$n" -ge 0 ]` over
#      a count, `[ -n "$x" ]` over a value assigned a literal just above it, or a comparison
#      between two values the suite itself constructs to be equal — reaches PASS without a
#      disjunction and is INVISIBLE here. This group would not have caught such an arm, and
#      does not claim it would. The class is a DECLARED RESIDUAL, not an oversight, and no
#      detector for it ships, for a stated reason: whether a guard can fail is whether its
#      negation is satisfiable over the values this file can produce, which is not decidable
#      in general, and a detector for a few literal spellings would grade those spellings
#      while reading as coverage of the class — the very failure this group exists to catch.
#      Group MD's static arm leaves every shell-test condition unflagged by design; its
#      dynamic arm convicts a REGISTERED assertion whose PASS survives its subject's removal,
#      which some tautological guards do. An unregistered tautological guard is seen by
#      nothing in this file, and this paragraph is where a reader is told so.
#   *  It grades the guards whose taken branch carries a verdict on the line that branch
#      starts on — the rest of the guard's own line after `then`, or else the next non-blank
#      non-comment line — and it reads the FIRST verdict there, so `then FAIL ...; else
#      PASS ...` is a guard that reaches FAIL. A verdict that first appears deeper inside a
#      branch is counted as a non-verdict guard and is not graded. The counts are printed, so
#      the ungraded remainder is visible rather than implied.
#   *  It locates a guard only where `if` or `elif` opens a line of top-level code, so three
#      verdict forms are never located and never graded: (a) a list-form verdict,
#      `A && PASS "..." or FAIL "..."`, which with a disjunction for A is the most compact
#      spelling of the banned shape; (b) a guard whose `if` is not the first word on its
#      line — a `case` arm, a one-line function body, or one after `;` or `&&`; and (c) a
#      disjunction decided in a helper or an assignment and compared afterwards, where the
#      guard that reaches PASS tests the stored result and never sees the disjunction — the
#      artifact-schema suite's `st_cf_dfired` is one. FZ3 prints FZ_UNLOCATED, the top-level
#      lines that carry a PASS verdict and are no located guard's verdict line. Forms (a) and
#      (b) fall inside it when they stand on a line of their own, and so does a PASS reached
#      through an `else` on a later line or first appearing deeper in a branch, so the count
#      bounds (a) and (b) from above and is no census of them. It never counts form (c),
#      whose comparing guard is located and whose PASS is read as that guard's verdict, nor a
#      list-form verdict or an `else` PASS standing on the line a located guard's branch
#      starts on, which is read as that guard's verdict line and graded against that guard's
#      condition.
#   *  It walks TOP-LEVEL CODE ONLY. A lexer tracks what is open at each point — quotes,
#      $( ), backticks, ${ }, $(( )) and here-documents — and a line that begins inside one
#      of them is an embedded program or a payload, never a shell guard: an awk program's
#      `if`, a script written out through a here-document, a mock defined inside a
#      multi-line command substitution. Inside a guard the operator counts only at the
#      guard's own level, so one inside a substitution, a quoted literal or a here-document
#      is not this guard's disjunction, while one inside [[ ]] or (( )) is. The number of
#      lines not walked is printed with FZ3. A verdict placed inside a multi-line command
#      substitution runs in a subshell whose counters never reach this run, and it is not
#      graded here either. A `<<` whose delimiter is neither a word nor quoted — the
#      shift-assign `<<=` is one — names no line on which a here-document would end, so the
#      lexer records it rather than guess, and FZ3 refuses a file that carries one.
#   *  It recognises the operator as two bars. A disjunction spelled `-o` inside [ ] or
#      test, a `case` alternation, a negated group, and a `then` standing alone on its own
#      line are not recognised; none of them was written into a verdict guard in any guard
#      suite when this group was installed, and the walk does not grade them.
#   *  The walk is line-oriented and does not track nesting, so it attributes a verdict to
#      the guard it most recently completed. Every control below runs on a synthetic source
#      of known shape precisely because the parser's own correctness cannot be assumed.
#   *  Its scan set is THIS FILE — not a script it sources, and not a sibling suite. Each
#      guard suite carries this group over its own source, so a finding is reported by the
#      suite whose arm it is. The walker is the same text in every suite that carries it, by
#      the convention group MD follows, and nothing asserts the copies agree: a correction to
#      one is a correction owed to all of them.
#
# ── THE CONTROLS ARE PERMANENT, NOT A ONE-TIME DEMONSTRATION ─────────────────────
# FZ1 plants an arm carrying the banned shape and requires the detector to flag it. FZ2
# plants the conforming source — the same arm rewritten as a chain, PLUS a conjunctive
# PASS-reaching guard — and requires silence over it; that second guard is the only
# specimen an over-matching detector can be seen on, and FZ2 asserts its presence rather
# than assuming it. Three more plants each stand behind one correction the walker carries,
# and each is a source a walker without that correction reads wrongly. FZ5 is a one-line
# guard that names FAIL first: a walker taking any PASS after `then` reads it as a
# PASS-reaching disjunction. FZ6 is two awk programs carrying the operator, each followed by
# a shell guard: a walker reading awk's `if` as a shell guard flags the awk line and lets it
# swallow the guard after it, so FZ6 requires the second, disjunctive guard flagged at its
# OWN line. FZ7 puts the operator inside a command substitution, a quoted literal and a
# here-document, then a `<<` whose delimiter is no word, which must be refused without
# hiding what follows, then a real one inside [[ ]] that must still be flagged. Every plant is
# built and run on EVERY invocation, so a detector that stops detecting is caught by the
# next run rather than by the next reader. FZ1 is graded FIRST, and FZ3 reads FZ1, FZ6 and
# FZ7 before it reads this file: a zero whose sensitivity arms did not fire is a broken
# probe, not a clean file. FZ3 also refuses a scan whose lexer ended this file inside a
# construct it never saw closed, because every line after the opener was invisible to it,
# and one whose lexer met a `<<` it could not delimit.
#
# The needle is assembled from two pieces, and the comments above spell it `or` rather
# than literally. The plants are the deliberate exception: each spells the operator in full,
# so that no plant is built out of the needle it is meant to test — a control assembled from
# the thing it validates cannot detect that thing drifting. The literal is safe in the plants
# because the walker reads only top-level code, and every plant line is a quoted argument.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group FZ — every verdict arm in this file must be able to FAIL."

FZ_OR='|'"|"
FZ_Q="'"
FZ_GUARDS=0; FZ_ARMS=0; FZ_PASSARMS=0; FZ_FAILARMS=0; FZ_NONVERDICT=0; FZ_UNRESOLVED=0
FZ_BAD=0; FZ_BAD_AT=""; FZ_LINES=0; FZ_EMBEDDED=0; FZ_LEXEND=""
FZ_PASSTOP=0; FZ_PASSREAD=0; FZ_UNLOCATED=0
FZ_PJ=(); FZ_CO=()

# fz_lex — one pass over a shell source, keeping a stack of the constructs open at each point:
# T top-level code; S '…'; A $'…'; D "…"; B a backtick; C $( … ) and c a ( ) inside it; P ${ … };
# R and r $(( … )). A comment is dropped where a word may start; a here-document's body is
# every line after its opener up to its delimiter. A `<<` whose delimiter is neither a word nor
# quoted, as in the shift-assign `<<=`, opens no body: no line can be named on which it would
# end, so its line number is recorded instead. Per line it records the TOP-LEVEL projection —
# the line with the inside of every open construct removed and the quote marks kept — and
# whether the line BEGAN in top-level code. A line that began inside a construct is part of an
# embedded program or a payload, never a shell guard. FZ_LEXEND is the state at end of input:
# "T|" when every construct closed and no here-document is pending, and the lines of any `<<`
# it could not delimit follow a second bar, so the state is then never "T|".
fz_lex() {  # <file> -> FZ_PJ[] FZ_CO[] FZ_EMBEDDED FZ_LEXEND
  local f="$1" line rest pre c c2 c3 st="T" top proj last hdq="" tag dash k qd hbad=""
  FZ_PJ=(); FZ_CO=(); FZ_EMBEDDED=0; FZ_LEXEND=""
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$hdq" ]; then
      tag="${hdq%% *}"; k="$line"
      case "$tag" in -*) tag="${tag#-}"; k="${k#"${k%%[!	]*}"}" ;; esac
      [ "$k" = "$tag" ] && hdq="${hdq#* }"
      FZ_PJ+=(""); FZ_CO+=(0); FZ_EMBEDDED=$((FZ_EMBEDDED+1)); continue
    fi
    if [ "$st" = T ]; then FZ_CO+=(1); else FZ_CO+=(0); FZ_EMBEDDED=$((FZ_EMBEDDED+1)); fi
    proj=""; rest="$line"; last=" "
    while [ -n "$rest" ]; do
      top="${st:$((${#st}-1))}"
      case "$top" in
        T|C|c) pre="${rest%%[\'\"\\\`\$#\<\(\)]*}" ;;
        S)     pre="${rest%%\'*}" ;;
        A)     pre="${rest%%[\\\']*}" ;;
        D)     pre="${rest%%[\\\"\`\$]*}" ;;
        B)     pre="${rest%%[\\\`\'\"]*}" ;;
        P)     pre="${rest%%[\\\}\$]*}" ;;
        R|r)   pre="${rest%%[\(\)\$]*}" ;;
      esac
      if [ -n "$pre" ]; then
        [ "$st" = T ] && proj="$proj$pre"
        last="${pre:$((${#pre}-1))}"
        rest="${rest:${#pre}}"
        [ -n "$rest" ] || break
      fi
      c="${rest:0:1}"; c2="${rest:0:2}"; c3="${rest:0:3}"
      case "$top" in
        T|C|c)
          case "$c" in
            \\) [ "$st" = T ] && proj="$proj$c2"; rest="${rest:2}"; last=x ;;
            \') [ "$st" = T ] && proj="$proj'"; st="${st}S"; rest="${rest:1}" ;;
            \") [ "$st" = T ] && proj="$proj\""; st="${st}D"; rest="${rest:1}" ;;
            \`) st="${st}B"; rest="${rest:1}" ;;
            \$) case "$c3" in
                  '$(('*) st="${st}Rr"; rest="${rest:3}" ;;
                  *) case "$c2" in
                       "\$'") st="${st}A"; rest="${rest:2}" ;;
                       '$(') st="${st}C"; rest="${rest:2}" ;;
                       '${') st="${st}P"; rest="${rest:2}" ;;
                       *) [ "$st" = T ] && proj="$proj\$"; rest="${rest:1}"; last='$' ;;
                     esac ;;
                esac ;;
            \#) case "$last" in
                  ' '|'	'|';'|'&'|'|'|'('|')') rest="" ;;
                  *) [ "$st" = T ] && proj="$proj#"; rest="${rest:1}"; last='#' ;;
                esac ;;
            \<) if [ "$c3" = '<<<' ]; then
                  [ "$st" = T ] && proj="$proj<<<"; rest="${rest:3}"; last='<'
                elif [ "$c2" = '<<' ]; then
                  rest="${rest:2}"; dash=""; qd=""
                  case "$rest" in -*) dash="-"; rest="${rest:1}" ;; esac
                  rest="${rest#"${rest%%[! 	]*}"}"
                  case "$rest" in
                    \'*) rest="${rest:1}"; tag="${rest%%\'*}"; rest="${rest#*\'}"; qd=q ;;
                    \"*) rest="${rest:1}"; tag="${rest%%\"*}"; rest="${rest#*\"}"; qd=q ;;
                    \\*) rest="${rest:1}"; tag="${rest%%[!A-Za-z0-9_]*}"; rest="${rest:${#tag}}" ;;
                    *)   tag="${rest%%[!A-Za-z0-9_]*}"; rest="${rest:${#tag}}" ;;
                  esac
                  if [ -n "$tag$qd" ]; then hdq="$hdq$dash$tag "; else hbad="$hbad${#FZ_CO[@]} "; fi
                  [ "$st" = T ] && proj="$proj<<$tag"; last=x
                else
                  [ "$st" = T ] && proj="$proj<"; rest="${rest:1}"; last='<'
                fi ;;
            \() if [ "$top" = T ]; then proj="$proj("; else st="${st}c"; fi; rest="${rest:1}"; last='(' ;;
            \)) if [ "$top" = T ]; then proj="$proj)"; else st="${st%?}"; fi; rest="${rest:1}"; last=')' ;;
          esac ;;
        S) st="${st%?}"; [ "$st" = T ] && proj="$proj'"; rest="${rest:1}"; last="'" ;;
        A) if [ "$c" = '\' ]; then rest="${rest:2}"; else st="${st%?}"; [ "$st" = T ] && proj="$proj'"; rest="${rest:1}"; last="'"; fi ;;
        D) case "$c" in
             \\) rest="${rest:2}" ;;
             \") st="${st%?}"; [ "$st" = T ] && proj="$proj\""; rest="${rest:1}"; last='"' ;;
             \`) st="${st}B"; rest="${rest:1}" ;;
             \$) case "$c3" in
                   '$(('*) st="${st}Rr"; rest="${rest:3}" ;;
                   *) case "$c2" in
                        '$(') st="${st}C"; rest="${rest:2}" ;;
                        '${') st="${st}P"; rest="${rest:2}" ;;
                        *) rest="${rest:1}" ;;
                      esac ;;
                 esac ;;
           esac ;;
        B) case "$c" in
             \\) rest="${rest:2}" ;;
             \`) st="${st%?}"; rest="${rest:1}" ;;
             \') st="${st}S"; rest="${rest:1}" ;;
             \") st="${st}D"; rest="${rest:1}" ;;
           esac ;;
        P) case "$c" in
             \\) rest="${rest:2}" ;;
             \}) st="${st%?}"; rest="${rest:1}" ;;
             \$) case "$c2" in
                   '$(') st="${st}C"; rest="${rest:2}" ;;
                   '${') st="${st}P"; rest="${rest:2}" ;;
                   *) rest="${rest:1}" ;;
                 esac ;;
           esac ;;
        R|r) case "$c" in
               \() st="${st}r"; rest="${rest:1}" ;;
               \)) st="${st%?}"; rest="${rest:1}" ;;
               \$) case "$c2" in
                     '$(') st="${st}C"; rest="${rest:2}" ;;
                     *) rest="${rest:1}" ;;
                   esac ;;
             esac ;;
      esac
    done
    FZ_PJ+=("$proj")
  done < "$f"
  FZ_LEXEND="$st|$hdq"
  if [ -n "$hbad" ]; then FZ_LEXEND="$FZ_LEXEND|${hbad% }"; fi
  return 0
}

# Resolve one located guard against the FIRST verdict of its taken branch — the earliest PASS or
# FAIL on the line that branch starts on, so `then FAIL …; else PASS …` reaches FAIL.
fz_resolve() {
  local p=-1 q=-1 x
  case "$fz_rest" in *'PASS "'*) x="${fz_rest%%PASS \"*}"; p=${#x} ;; esac
  case "$fz_rest" in *'FAIL "'*) x="${fz_rest%%FAIL \"*}"; q=${#x} ;; esac
  if [ "$p" -lt 0 ] && [ "$q" -lt 0 ]; then
    FZ_NONVERDICT=$((FZ_NONVERDICT+1))
  elif [ "$p" -lt 0 ]; then
    FZ_ARMS=$((FZ_ARMS+1)); FZ_FAILARMS=$((FZ_FAILARMS+1))
  elif [ "$q" -ge 0 ] && [ "$q" -lt "$p" ]; then
    FZ_ARMS=$((FZ_ARMS+1)); FZ_FAILARMS=$((FZ_FAILARMS+1))
  else
    FZ_ARMS=$((FZ_ARMS+1)); FZ_PASSARMS=$((FZ_PASSARMS+1))
    case "$fz_guard" in
      *"$FZ_OR"*) FZ_BAD=$((FZ_BAD+1)); FZ_BAD_AT="$FZ_BAD_AT$fz_gline " ;;
    esac
  fi
}

# Walk the top-level projection of a shell source and grade every verdict guard it can locate.
fz_scan() {  # <file>
  local f="$1" i=0 n t co pend=0 want=0
  FZ_GUARDS=0; FZ_ARMS=0; FZ_PASSARMS=0; FZ_FAILARMS=0; FZ_NONVERDICT=0; FZ_UNRESOLVED=0
  FZ_BAD=0; FZ_BAD_AT=""; FZ_LINES=0; FZ_PASSTOP=0; FZ_PASSREAD=0; FZ_UNLOCATED=0
  fz_guard=""; fz_gline=0; fz_rest=""
  fz_lex "$f"; n=${#FZ_PJ[@]}
  while [ "$i" -lt "$n" ]; do
    t="${FZ_PJ[$i]}"; co="${FZ_CO[$i]}"; i=$((i+1)); FZ_LINES=$i
    t="${t#"${t%%[![:space:]]*}"}"
    [ -n "$t" ] || continue
    case "$t" in *'PASS "'*) FZ_PASSTOP=$((FZ_PASSTOP+1)) ;; esac
    if [ "$pend" -eq 1 ]; then
      fz_guard="$fz_guard $t"
      case "$t" in
        *' then'*|*';then'*) pend=0; FZ_GUARDS=$((FZ_GUARDS+1)); fz_rest="${t#*then}"; want=1 ;;
        *) continue ;;
      esac
    else
      case "$co$t" in
        '1if '*|'1elif '*|'1if	'*|'1elif	'*)
          [ "$want" -eq 1 ] && FZ_UNRESOLVED=$((FZ_UNRESOLVED+1))
          want=0
          fz_guard="$t"; fz_gline="$i"
          case "$t" in
            *' then'*|*';then'*) pend=0; FZ_GUARDS=$((FZ_GUARDS+1)); fz_rest="${t#*then}"; want=1 ;;
            *) pend=1; continue ;;
          esac ;;
        *)
          if [ "$want" -eq 1 ]; then
            fz_rest="$t"; want=0
            case "$t" in 'else'*|'fi'*) FZ_NONVERDICT=$((FZ_NONVERDICT+1)); continue ;; esac
            fz_resolve
            case "$t" in *'PASS "'*) FZ_PASSREAD=$((FZ_PASSREAD+1)) ;; esac
          fi
          continue ;;
      esac
    fi
    fz_rest="${fz_rest#"${fz_rest%%[![:space:]]*}"}"
    if [ -n "$fz_rest" ]; then
      want=0; fz_resolve
      case "$t" in *'PASS "'*) FZ_PASSREAD=$((FZ_PASSREAD+1)) ;; esac
    fi
  done
  [ "$want" -eq 1 ] && FZ_UNRESOLVED=$((FZ_UNRESOLVED+1))
  FZ_UNLOCATED=$((FZ_PASSTOP-FZ_PASSREAD))
  return 0
}

fz_plant() {  # <path> <banned|conforming|oneline|embedded|substitution>
  local p="$1"
  mkdir -p "${p%/*}"
  {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'p="$1"; n="$2"'
    case "$2" in
      banned)
        printf '%s\n' 'if [ ! -e "$p/canary" ] || [ "$n" -gt 0 ]; then'
        printf '%s\n' '  PASS "PLANT: nothing was written"'
        printf '%s\n' 'else'
        printf '%s\n' '  FAIL "PLANT: something was written"'
        printf '%s\n' 'fi' ;;
      conforming)
        # The same arm as a chain: one condition per branch, one message per branch.
        printf '%s\n' 'if [ ! -e "$p/canary" ]; then'
        printf '%s\n' '  FAIL "PLANT: the canary is absent"'
        printf '%s\n' 'elif [ "$n" -eq 0 ]; then'
        printf '%s\n' '  FAIL "PLANT: the watched surface was empty"'
        printf '%s\n' 'else'
        printf '%s\n' '  PASS "PLANT: measured"'
        printf '%s\n' 'fi'
        # And a plain CONJUNCTIVE guard that reaches PASS — the only specimen an over-match can be
        # seen on, which is why FZ2 asserts its presence.
        printf '%s\n' 'if [ -e "$p/canary" ] && [ "$n" -gt 0 ]; then'
        printf '%s\n' '  PASS "PLANT: the surface was watched and is unchanged"'
        printf '%s\n' 'else'
        printf '%s\n' '  FAIL "PLANT: the surface changed"'
        printf '%s\n' 'fi' ;;
      oneline)
        # One line, FAIL first: a disjunction that REACHES FAIL, which this rule permits.
        printf '%s\n' 'if [ ! -e "$p/canary" ] || [ "$n" -gt 0 ]; then FAIL "PLANT: the canary is absent or something was written"; else PASS "PLANT: the canary is present and nothing was written"; fi' ;;
      embedded)
        # Two awk programs whose OWN control flow carries the operator, each followed by a shell
        # guard: the first conjunctive, the second disjunctive, at line 16 of the plant.
        printf 'x="$(awk %s{\n' "$FZ_Q"
        printf '%s\n' '  if (a || b) next' '  print'
        printf '}%s "$p")"\n' "$FZ_Q"
        printf '%s\n' 'if [ -e "$p/canary" ] && [ "$n" -gt 0 ]; then' '  PASS "PLANT: measured after an embedded program"' 'else' '  FAIL "PLANT: not measured"' 'fi'
        printf 'x="$(awk %s{\n' "$FZ_Q"
        printf '%s\n' '  if (a || b) next' '  print'
        printf '}%s "$p")"\n' "$FZ_Q"
        printf '%s\n' 'if [ ! -e "$p/canary" ] || [ "$n" -gt 0 ]; then' '  PASS "PLANT: nothing was written"' 'else' '  FAIL "PLANT: something was written"' 'fi' ;;
      substitution)
        # The operator inside a command substitution, inside a quoted literal and inside a
        # here-document — none of them the guard's own — then, at line 18, a `<<` whose
        # delimiter is no word, which must be refused and must not hide what follows, then a
        # real one in [[ ]], at line 19.
        printf '%s\n' 'if [ "$(grep -c x "$p" || true)" -gt 0 ]; then' '  PASS "PLANT: the count was taken"' 'else' '  FAIL "PLANT: the count was not taken"' 'fi'
        printf '%s\n' 'if grep -q "a||b" "$p"; then' '  PASS "PLANT: the literal was found"' 'else' '  FAIL "PLANT: the literal was absent"' 'fi'
        printf '%s\n' 'cat > "$p.sh" <<"EOF"' 'if [ -e a ] || [ -e b ]; then' '  PASS "PLANT: written into a here-document, never run here"' 'fi' 'EOF'
        printf '%s\n' '(( m <<= 1 ))'
        printf '%s\n' 'if [[ -e "$p/canary" || "$n" -gt 0 ]]; then' '  PASS "PLANT: either held"' 'else' '  FAIL "PLANT: neither held"' 'fi' ;;
    esac
  } > "$p"
}

FZ_BANNED="$WORK/fz/banned.sh"
FZ_CLEAN="$WORK/fz/conforming.sh"
FZ_ONELINE="$WORK/fz/oneline.sh"
FZ_EMBEDSRC="$WORK/fz/embedded.sh"
FZ_SUBST="$WORK/fz/substitution.sh"
fz_plant "$FZ_BANNED" banned
fz_plant "$FZ_CLEAN" conforming
fz_plant "$FZ_ONELINE" oneline
fz_plant "$FZ_EMBEDSRC" embedded
fz_plant "$FZ_SUBST" substitution

# ── FZ1 — SENSITIVITY, graded FIRST.
fz_scan "$FZ_BANNED"
FZ1_BAD="$FZ_BAD"; FZ1_AT="$FZ_BAD_AT"; FZ1_PASSARMS="$FZ_PASSARMS"
if [ "$FZ1_BAD" -eq 1 ] && [ "$FZ1_PASSARMS" -eq 1 ]; then
  PASS "FZ1: SENSITIVITY — a planted arm whose PASS is guarded by a disjunction is detected (1 finding, at line ${FZ1_AT% } of the plant), so the detector fires on the shape both shipped instances had"
else
  FAIL "FZ1: SENSITIVITY — the planted unfirable arm was NOT detected as expected (findings=$FZ1_BAD, PASS-reaching arms located=$FZ1_PASSARMS, expected 1 and 1). Every verdict below rests on this arm, so none of them is trustworthy"
fi

# ── FZ2 — SPECIFICITY over the conforming source, a PASS-reaching guard included.
fz_scan "$FZ_CLEAN"
FZ2_BAD="$FZ_BAD"; FZ2_ARMS="$FZ_ARMS"; FZ2_FAILARMS="$FZ_FAILARMS"; FZ2_PASSARMS="$FZ_PASSARMS"
if [ "$FZ2_BAD" -eq 0 ] && [ "$FZ2_ARMS" -ge 3 ] && [ "$FZ2_FAILARMS" -ge 2 ] && [ "$FZ2_PASSARMS" -ge 1 ]; then
  PASS "FZ2: SPECIFICITY — the conforming source is NOT flagged, over $FZ2_ARMS located verdict arm(s): $FZ2_FAILARMS reaching FAIL and $FZ2_PASSARMS reaching PASS through a conjunction, which is the specimen a widened detector would over-match. The detector discriminates the shape rather than rejecting every guard"
else
  FAIL "FZ2: SPECIFICITY — the conforming source was flagged, or the walker located too little of it to say (findings=$FZ2_BAD, arms=$FZ2_ARMS, FAIL-reaching=$FZ2_FAILARMS, PASS-reaching=$FZ2_PASSARMS; want 0 findings over >=3 arms with >=2 FAIL-reaching and >=1 PASS-reaching). The detector cannot tell the shapes apart, or there is nothing in the sample for an over-match to show on, and FZ3's verdict means nothing either way"
fi

# ── FZ5 — FIRST VERDICT. A one-line guard reads FAIL first; read by any PASS after `then`, it
# would be a PASS-reaching disjunction and a false finding.
fz_scan "$FZ_ONELINE"
FZ5_BAD="$FZ_BAD"; FZ5_ARMS="$FZ_ARMS"; FZ5_FAILARMS="$FZ_FAILARMS"; FZ5_PASSARMS="$FZ_PASSARMS"
if [ "$FZ5_BAD" -eq 0 ] && [ "$FZ5_ARMS" -eq 1 ] && [ "$FZ5_FAILARMS" -eq 1 ] && [ "$FZ5_PASSARMS" -eq 0 ]; then
  PASS "FZ5: FIRST VERDICT — a one-line guard whose branch names FAIL first and PASS only after its else is read as the FAIL-reaching guard it is, and its disjunction is NOT flagged: a disjunction reaching FAIL fires whenever either side holds, which this rule permits"
else
  FAIL "FZ5: FIRST VERDICT — the one-line FAIL-first specimen read findings=$FZ5_BAD, arms=$FZ5_ARMS, FAIL-reaching=$FZ5_FAILARMS, PASS-reaching=$FZ5_PASSARMS where 0, 1, 1 and 0 are owed. The walker is grading a verdict other than the first one after then"
fi

# ── FZ6 — EMBEDDED PROGRAMS. Control flow inside an awk program is not a shell guard, and
# stepping over it must not blind the walker to the guard after it.
fz_scan "$FZ_EMBEDSRC"
FZ6_BAD="$FZ_BAD"; FZ6_AT="$FZ_BAD_AT"; FZ6_GUARDS="$FZ_GUARDS"; FZ6_PASSARMS="$FZ_PASSARMS"
if [ "$FZ6_BAD" -eq 1 ] && [ "${FZ6_AT% }" = 16 ] && [ "$FZ6_GUARDS" -eq 2 ] && [ "$FZ6_PASSARMS" -eq 2 ]; then
  PASS "FZ6: EMBEDDED PROGRAM — over a plant carrying two awk programs whose own control flow holds the operator, the walker locates exactly the 2 shell guards, leaves the conjunctive one unflagged, and flags the disjunctive one at its own line (line ${FZ6_AT% } of the plant), not at the awk line above it"
else
  FAIL "FZ6: EMBEDDED PROGRAM — the plant read findings=$FZ6_BAD at line(s) ${FZ6_AT% }, guards=$FZ6_GUARDS, PASS-reaching=$FZ6_PASSARMS where 1 finding at line 16 over 2 guards, both PASS-reaching, is owed. Control flow inside an embedded program was read as a shell guard, or stepping over it hid the guard that follows"
fi

# ── FZ7 — THE OPERATOR OUTSIDE THE GUARD'S OWN LIST. Inside a command substitution, a quoted
# literal or a here-document it is not this guard's disjunction; inside [[ ]] it is. And a `<<`
# whose delimiter is no word is refused, at its own line, without hiding the guard after it.
fz_scan "$FZ_SUBST"
FZ7_BAD="$FZ_BAD"; FZ7_AT="$FZ_BAD_AT"; FZ7_GUARDS="$FZ_GUARDS"; FZ7_PASSARMS="$FZ_PASSARMS"; FZ7_LEXEND="$FZ_LEXEND"
if [ "$FZ7_BAD" -eq 1 ] && [ "${FZ7_AT% }" = 19 ] && [ "$FZ7_GUARDS" -eq 3 ] && [ "$FZ7_PASSARMS" -eq 3 ] && [ "$FZ7_LEXEND" = "T||18" ]; then
  PASS "FZ7: SPECIFICITY AND SENSITIVITY IN ONE PLANT — the operator inside a command substitution, inside a quoted literal and inside a here-document is not flagged, the here-document's own guard is not located, a << whose delimiter is no word is refused at its own line (line ${FZ7_LEXEND##*|} of the plant) without hiding what follows, and the disjunction inside [[ ]] is flagged at its own line (line ${FZ7_AT% } of the plant), over the 3 shell guards the plant carries"
else
  FAIL "FZ7: the plant read findings=$FZ7_BAD at line(s) ${FZ7_AT% }, guards=$FZ7_GUARDS, PASS-reaching=$FZ7_PASSARMS and lexer end state '$FZ7_LEXEND', where 1 finding at line 19 over 3 guards, all PASS-reaching, and the end state 'T||18' are owed. The operator was read where it is not the guard's own, the walker stopped seeing guards after a substitution, a literal or a here-document, or a << it cannot delimit was taken for a here-document rather than refused"
fi

# ── FZ3 — THIS FILE. The claim and its denominator, graded only once every control above that
# could make its zero a false one has been read.
fz_scan "$SELF"
FZ_WC="$(wc -l < "$SELF" | tr -d ' ')"
if [ "$FZ1_BAD" -ne 1 ]; then
  FAIL "FZ3: the sensitivity arm did not fire on the plant (FZ1 above), so whatever this scan found or did not find in this file is untrustworthy — a zero from a detector never shown to detect anything is a broken probe, not a clean result"
elif [ "$FZ6_BAD" -ne 1 ]; then
  FAIL "FZ3: the disjunction planted after an embedded program was not seen (FZ6 above), so stepping over this file's embedded programs may have hidden guards — its zero is not a measurement"
elif [ "$FZ7_BAD" -ne 1 ]; then
  FAIL "FZ3: the disjunction planted after a substitution, a literal and a here-document was not seen (FZ7 above), so this file's zero may be a walker gone blind rather than a clean file"
elif [ "$FZ7_LEXEND" != "T||18" ]; then
  FAIL "FZ3: the << planted in FZ7 with a delimiter that is neither a word nor quoted was not refused (FZ7 above, end state '$FZ7_LEXEND'), so a here-document this lexer cannot delimit could close early in this file and hide every line after it — its zero is not a measurement"
elif [ "$FZ_LEXEND" != "T|" ]; then
  FAIL "FZ3: the lexer ended this file in state '$FZ_LEXEND' where 'T|' is owed — the constructs still open, a bar, any here-document still pending and, after a second bar, the line(s) of any << whose delimiter is neither a word nor quoted, which it refuses to guess the end of. Every line past such a point may have been invisible to the walker, so its zero describes at best a prefix"
elif [ "$FZ_ARMS" -eq 0 ]; then
  FAIL "FZ3: the walker located 0 verdict arms in this file, so its zero on the banned shape is an empty scan and not a clean result — the file's shape or this walker has moved"
elif [ "$FZ_BAD" -eq 0 ]; then
  PASS "FZ3: $FZ_GUARDS guard(s) in this file's top-level code — $FZ_ARMS located verdict arm(s) ($FZ_PASSARMS reaching PASS, $FZ_FAILARMS reaching FAIL), $FZ_NONVERDICT non-verdict, $FZ_UNRESOLVED unresolved — and 0 of the $FZ_PASSARMS PASS-reaching guards is a disjunction. $FZ_EMBEDDED line(s) lay inside quoted payloads, substitutions or here-documents and were not walked. $FZ_UNLOCATED of the $FZ_PASSTOP top-level line(s) carrying a PASS verdict are no located guard's verdict line — reached through an else, first appearing deeper in a branch, or written in a form the walker does not locate — and are not graded. The controls fired, so this zero is a measurement. It grades a shape, not reachability: see this group's coverage boundary for what it cannot see"
else
  FAIL "FZ3: $FZ_BAD verdict arm(s) in this file reach PASS through a disjunction, at line(s) ${FZ_BAD_AT% }. The failure branch then needs every disjunct false at once — a conjunction nobody wrote down — which is how both previously shipped arms became unable to fail. Rewrite as a chain: one condition per branch, one message per branch"
fi

# ── FZ4 — the walk covered the file, measured by a differently-shaped counter.
if [ "$FZ_LINES" -ge "$FZ_WC" ] && [ "$FZ_LINES" -le "$((FZ_WC+1))" ] && [ "$FZ_WC" -gt 0 ]; then
  PASS "FZ4: the walker read $FZ_LINES line(s) of this file against $FZ_WC counted independently — the scan covered the whole source, so FZ3's population is the file's and not a prefix of it"
else
  FAIL "FZ4: the walker read $FZ_LINES line(s) of this file while an independent count reads $FZ_WC — the walk did not cover the source, so FZ3 graded a prefix and its verdict does not describe this file"
fi

# ═════════════════════════════════════════════════════════════════════════════════
# Group PP — the site passphrase never reaches standard output (#330).
#
# THE DEFECT, measured end-to-end before this group existed: a publish run to completion
# with its standard output captured carried the resolved passphrase VALUE — 667 bytes of
# capture, a 49-character value — and a rotate carried its own, 448 bytes and 41
# characters. Standard output is what a command file's bash pre-execution injects into a
# session transcript, so the disclosure was never confined to a human's scrollback.
#
# WHAT IS GRADED IS A SHAPE, NOT A POLICY. announce_passphrase_file takes the passphrase
# FILE PATH and never the value, so the emission site is INCAPABLE of disclosing rather
# than declining to. There is no terminal test, no flag and no environment probe to take
# wrongly, because the secret never arrives at the site that prints.
#
# WHY EVERY CAPTURE ARM HERE IS COMPOUND. The obvious assertion — "the capture does not
# contain the passphrase" — is the emptiness conflation group MD exists for: delete the
# announcer and the capture satisfies it trivially, so the assertion passes against a
# subject that never ran. Every capture arm below therefore grades a POSITIVE limb FIRST
# — the capture must carry the passphrase file PATH, evidence only a running announcer,
# handed the right path, could produce — and only then the negative one. A capture missing
# the pointer is FAIL — verdict withheld, never a pass. The path is computed here from the
# fixture directory this group created, so the script cannot supply it by accident.
#
# THE DENOMINATOR of a string-absence verdict is not a population count, because there is
# no population to count. It is stated as the triple (capture bytes, value length, pointer
# found) — the three numbers that decide whether the absence was measured or merely empty.
#
# NO ANSI STRIPPING, deliberately: every arm is a substring test over the value and over
# the path, and a colour escape sits outside both. The pre-fix emitter wrapped the value in
# escapes and the value still read as a contiguous substring, which is how the measurement
# above was taken and how PP7's restored mutant is convicted.
#
# PP IS PURE BASH PLUS GIT. gh and npx are shell functions here, encrypt_to_tmp is shimmed
# to the known-good ciphertext fixture this suite already builds, make_boilerplate declines
# exactly as it does without npx, and rotate pushes to a bare repository created under
# $WORK. No network, no Node, no authenticated CLI, no terminal — and this group creates
# its own repositories, so unlike K/Q/U/V it does not require the suite to be running
# inside a git work tree. It has no legitimate skip and is deliberately NOT declared in
# GUARD_EXPECTED_SKIPS.
#
# SHIMMING encrypt_to_tmp IS BOUNDED AND DELIBERATE. This group's subject is the
# announcement channel, which is strictly downstream of encryption; groups E and G own real
# StatiCrypt and skip without it. An arm here that depended on StatiCrypt would have to be
# skippable, and a skippable privacy control is the green that proves less than it appears
# to. The shimmed originals are restored at the end of the group rather than unset, so a
# group added after this one inherits the production functions and not these stand-ins.
#
# THE MD REGISTRATIONS ARE EMITTED HERE rather than in group MD, for the reason G2's are
# emitted inside group G: they need this group's mocks and fixtures, which are torn down at
# the end of it. MD's own controls (MD4/MD5) have already run by this point, so every
# MD[PP…] verdict below stands on an oracle whose sensitivity and specificity are measured.
#
# TWO ARMS ARE DECLARED MD OPT-OUTS rather than silently left unregistered, because
# `unset -f` is inapplicable to their subjects: PP0's subject is a synthetic string and the
# substring test over it, and PP9's is a filesystem mode. Neither is a shell function, so
# there is nothing for the oracle to remove; registering them would grade the oracle rather
# than the assertion. Every other arm here is registered.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group PP — the passphrase VALUE never reaches standard output; the PATH does."

PPW="$WORK/pp"; mkdir -p "$PPW"

# The originals, saved before the shims below replace them, and re-defined at the end of
# the group. `unset -f` would remove the production function rather than the stand-in.
PP_ORIG_ENC="$(declare -f encrypt_to_tmp)"
PP_ORIG_BOIL="$(declare -f make_boilerplate)"

# Commit signing is pinned OFF for the throwaway repositories this group creates, so the
# fixture does not depend on the operator's global git configuration — measured: a global
# commit.gpgsign=true reads as false under these entries. GIT_CONFIG_* overrides
# configuration files, and `commit_noreply` passes only user.name/user.email with -c, so
# nothing here contests them. Undone at the end of the group.
export GIT_CONFIG_COUNT=3 \
  GIT_CONFIG_KEY_0=commit.gpgsign     GIT_CONFIG_VALUE_0=false \
  GIT_CONFIG_KEY_1=tag.gpgsign        GIT_CONFIG_VALUE_1=false \
  GIT_CONFIG_KEY_2=init.defaultBranch GIT_CONFIG_VALUE_2=main

gh() {   # mock: answer the read-only probes; create, clone and push nothing real
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 1 ;;          # no per-trip repo yet, so publish proceeds
    "auth status") printf "Token scopes: 'repo'\n" ;;
    *)             return 0 ;;
  esac
}
npx() { return 0; }
# A fresh ciphertext marker per call, as real StatiCrypt's per-encryption salt gives: every
# re-encryption differs from the one already committed. A shim returning ENC_OK's fixed bytes made
# every rotation an EMPTY commit — the first included, because PP2's seed commit is ENC_OK itself —
# which failed, and this suite's errexit-off hid it until the GHSA-gmm2-v7rr-jq7r fix made the
# commit fail closed. The graded channel is unchanged.
encrypt_to_tmp() { local e n; e="$(mktemp -d)"; n="$(od -An -N4 -tx1 /dev/urandom | tr -dc 'a-f0-9')"; sed "s/bb12ab/pp$n/" "$ENC_OK" > "$e/index.html"; printf '%s' "$e"; }
make_boilerplate() { return 1; }

# $SRC is this suite's synthetic plaintext itinerary and $ENC_OK the ciphertext group A
# already proves clean against it, so the real verify_ciphertext runs on a pair it has
# graded rather than on a fixture invented here.
pp_fixture() { # <name> -> trip dir on stdout
  local d="$PPW/$1"
  rm -rf "$d"; mkdir -p "$d/outputs"
  cp "$SRC" "$d/outputs/$1-travel-site.html"
  printf '%s' "$d"
}

# Occurrence count with no pipeline anywhere in it — group PF forbids a verdict decided by
# a pipeline's exit status, and this feeds verdicts.
pp_count() { # <haystack> <needle> -> count on stdout
  local h="$1" n="$2" c=0
  while [ -n "$h" ]; do
    case "$h" in *"$n"*) c=$((c+1)); h="${h#*"$n"}" ;; *) break ;; esac
  done
  printf '%s' "$c"
}

# The captures are taken INSIDE the registered assertions' own call chain, which is a
# factoring requirement rather than a convenience: an assertion handed a capture computed
# elsewhere would be unaffected by `unset -f` and group MD would correctly convict it as
# blind. stdin is /dev/null and stderr is discarded, so what is graded is standard output
# and nothing else.
pp_capture_publish() { # <trip_dir> [env_passphrase] -> the run's captured STANDARD OUTPUT
  if [ -n "${2:-}" ]; then
    ( STATICRYPT_PASSWORD="$2" cmd_publish "$1" ) </dev/null 2>/dev/null
  else
    ( cmd_publish "$1" ) </dev/null 2>/dev/null
  fi
}
pp_capture_rotate() { # <trip_dir> -> the run's captured STANDARD OUTPUT
  ( cmd_rotate "$1" ) </dev/null 2>/dev/null
}

# ── PP0 — the leak detector's own sensitivity, graded FIRST and MD-opt-out (its subject is
# a synthetic string, not a shell function). Every verdict below is a substring test; if
# that test cannot tell a capture carrying the value from one that does not, every PP
# verdict is vacuous and its zero proves nothing.
PP_SYN='zzq-synthetic-passphrase-value'
PP_D_HIT=0; PP_D_MISS=0
case "prefix $PP_SYN suffix"        in *"$PP_SYN"*) PP_D_HIT=1 ;; esac
# shellcheck disable=SC2194  # the constant is the arm: the capture that does not carry the value
case "prefix (value absent) suffix" in *"$PP_SYN"*) PP_D_MISS=1 ;; esac
if [ "$PP_D_HIT" -eq 1 ] && [ "$PP_D_MISS" -eq 0 ]; then
  PASS "PP0: CONTROL on the leak detector — over 2 synthetic captures it fires on the one carrying the value and stays silent on the one that does not, so both arms fired. Every absence asserted below is a measurement rather than a detector that matches nothing"
else
  FAIL "PP0: the leak detector is broken over 2 of 2 synthetic captures — hit arm=$PP_D_HIT (want 1), miss arm=$PP_D_MISS (want 0). Every PP verdict below would be vacuous, so none of them is trustworthy"
fi

# ── PP1 — the publish path, executed end-to-end and offline. Compound: pointer present
# (positive, non-degenerate haystack) AND value absent.
pp_publish_assert() { # <id> <trip_dir>
  local id="$1" d="$2" pf="$2/.passphrase" cap val="" hasp=0 hasv=0
  cap="$(pp_capture_publish "$d")"
  [ -r "$pf" ] && val="$(cat "$pf")"
  case "$cap" in *"$pf"*) hasp=1 ;; esac
  [ -n "$val" ] && case "$cap" in *"$val"*) hasv=1 ;; esac
  if [ "$hasp" -eq 0 ]; then
    FAIL "$id: the capture carries no '$pf' pointer — DEGENERATE HAYSTACK, VERDICT WITHHELD. An absent announcer produces a capture with no passphrase in it, which is not evidence that the announcer withheld one (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  elif [ "$hasv" -eq 1 ]; then
    FAIL "$id: the passphrase VALUE reached standard output on the publish path — a captured or transcript-injected publish discloses the secret (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  else
    PASS "$id: publish ran end-to-end and its captured standard output carries the passphrase FILE PATH and not the ${#val}-character value (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  fi
}
PP1D="$(pp_fixture pp1)"
pp_publish_assert "PP1" "$PP1D"

# ── PP2 — the rotate path, same shape, pushing to a bare repository created here so the
# push is offline. ensure_pub_clone reuses .publish when its origin resolves to this trip's
# slug, which is why the remote's basename is <slug>.git.
pp_rotate_assert() { # <id> <trip_dir>
  local id="$1" d="$2" pf="$2/.passphrase" cap val="" hasp=0 hasv=0
  cap="$(pp_capture_rotate "$d")"
  [ -r "$pf" ] && val="$(cat "$pf")"
  case "$cap" in *"$pf"*) hasp=1 ;; esac
  [ -n "$val" ] && case "$cap" in *"$val"*) hasv=1 ;; esac
  if [ "$hasp" -eq 0 ]; then
    FAIL "$id: the capture carries no '$pf' pointer — DEGENERATE HAYSTACK, VERDICT WITHHELD (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  elif [ "$hasv" -eq 1 ]; then
    FAIL "$id: the NEW passphrase VALUE reached standard output on the rotate path — rotation is exactly the moment a fresh secret is disclosed to a capture (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  else
    PASS "$id: rotate ran end-to-end and its captured standard output carries the passphrase FILE PATH and not the ${#val}-character new value (denominator: ${#cap} capture bytes, ${#val}-char value, pointer found=$hasp)"
  fi
}
PP2D="$(pp_fixture pp2)"
PP2SLUG="$(basename "$PP2D")-trip"
PP2BARE="$PPW/origin/$PP2SLUG.git"; mkdir -p "$PP2BARE"; git init -q --bare "$PP2BARE"
PP2PUB="$PP2D/.publish"; mkdir -p "$PP2PUB"
git init -q "$PP2PUB"
git -C "$PP2PUB" remote add origin "$PP2BARE"
cp "$ENC_OK" "$PP2PUB/index.html"
git -C "$PP2PUB" add index.html
git -C "$PP2PUB" -c user.name=t -c user.email=t@example.invalid commit -q -m seed
git -C "$PP2PUB" branch -M main
git -C "$PP2PUB" push -q origin main
pp_rotate_assert "PP2" "$PP2D"

# ── PP3 — the announcer's own exit status, graded EXACTLY rather than truthily, so a 127
# is diagnosed as an ABSENT SUBJECT and never as a rejection.
pp_rc_assert() { # <id>
  expect_rc 0 "$1" "the announcer returns cleanly against a path it can read" -- announce_passphrase_file "Passphrase" "$PP1D/.passphrase"
}
pp_rc_assert "PP3"

# ── PP4 — the announcer CANNOT disclose: the value is not a parameter and the body holds
# no construct that could fetch it. The complement arm requires the printf sites fed from
# the path parameter, so a body that merely lacks the bad constructs — an empty one, or a
# stub — cannot satisfy this.
pp_cannot_disclose_assert() { # <id>
  local id="$1" body="" nd n_bad=0 n_pf=0 n_pr=0
  body="$(declare -f announce_passphrase_file 2>/dev/null)"
  for nd in 'get_passphrase' 'STATICRYPT_PASSWORD' '$(cat' '$passphrase'; do
    n_bad=$(( n_bad + $(pp_count "$body" "$nd") ))
  done
  n_pf="$(pp_count "$body" '"$pf"')"
  n_pr="$(pp_count "$body" 'printf')"
  if [ "${#body}" -lt 300 ]; then
    FAIL "$id: announce_passphrase_file's parsed body is ${#body} bytes, below the 300-byte floor — the subject is absent or a stub, so a clean reading of it would be an empty scan rather than a clean function"
  elif [ "$n_pr" -lt 2 ] || [ "$n_pf" -lt 2 ]; then
    FAIL "$id: COMPLEMENT ARM — the body holds $n_pr printf site(s) and $n_pf reference(s) to the path parameter, below the 2 each a two-limbed announcer must have. The absence asserted next would be an absence in something that does not announce"
  elif [ "$n_bad" -ne 0 ]; then
    FAIL "$id: the announcer body carries $n_bad value-obtaining construct(s) (get_passphrase / STATICRYPT_PASSWORD / \$(cat / \$passphrase) — it can reach the secret, so withholding it is a branch that can be taken wrongly rather than a shape"
  else
    PASS "$id: the announcer is INCAPABLE of disclosing — 0 value-obtaining constructs over a ${#body}-byte parsed body, and the complement arm fired ($n_pr printf sites, $n_pf path-parameter references). The value is not a parameter, so there is no branch that could print it"
  fi
}
pp_cannot_disclose_assert "PP4"

# ── PP5 — single-limb: the announcement is not conditional on the CALLER. This is the arm
# that fails the day a `[ -t 1 ]` gate is reintroduced. Its sensitivity arm runs the
# identical scan over cmd_confirm, which does gate on a terminal, so the zero here is a
# measurement rather than a scan that matches nothing.
pp_single_limb_assert() { # <id>
  local id="$1" body="" ctl="" nd n_gate=0 n_ctl=0
  body="$(declare -f announce_passphrase_file 2>/dev/null)"
  ctl="$(declare -f cmd_confirm 2>/dev/null)"
  for nd in '-t 0' '-t 1' '/dev/tty'; do
    n_gate=$(( n_gate + $(pp_count "$body" "$nd") ))
  done
  n_ctl="$(pp_count "$ctl" '-t 0')"
  if [ "${#body}" -lt 300 ]; then
    FAIL "$id: announce_passphrase_file's parsed body is ${#body} bytes, below the 300-byte floor — the subject is absent or a stub and the terminal-gate zero below would be an empty scan"
  elif [ "$n_ctl" -lt 1 ]; then
    FAIL "$id: SENSITIVITY ARM DID NOT FIRE — the identical scan over cmd_confirm, which does gate on a terminal, found $n_ctl '-t 0' site(s). The detector is not reading what it claims, so the zero over the announcer proves nothing"
  elif [ "$n_gate" -ne 0 ]; then
    FAIL "$id: the announcer branches on the CALLER — $n_gate terminal-or-tty construct(s) in its body. A privacy property that depends on how the script was invoked takes its disclosing limb on any host that allocates a pseudo-terminal, so the same script withholds or discloses according to how it was run — and a property the caller decides is not a property this guard holds"
  else
    PASS "$id: the announcement is UNCONDITIONAL on the caller — 0 '-t 0' / '-t 1' / '/dev/tty' constructs over a ${#body}-byte parsed body, while the identical scan over cmd_confirm found $n_ctl, so the zero is a measurement"
  fi
}
pp_single_limb_assert "PP5"

# ── PP6 — the wiring, read from the PARSED function bodies rather than from source text:
# bash discards comments, so a mention of the identifier in a comment cannot fake a call
# site. The get_passphrase count is exact at 1 because cmd_publish resolved the passphrase
# TWICE before this change — once for encryption and once, redundantly, to print.
pp_wiring_assert() { # <id>
  local id="$1" pub="" rot="" n_pub=0 n_rot=0 n_get=0 n_cat=0
  pub="$(declare -f cmd_publish 2>/dev/null)"
  rot="$(declare -f cmd_rotate 2>/dev/null)"
  n_pub="$(pp_count "$pub" 'announce_passphrase_file')"
  n_rot="$(pp_count "$rot" 'announce_passphrase_file')"
  n_get="$(pp_count "$pub" 'get_passphrase')"
  n_cat="$(pp_count "$rot" 'cat "$pf"')"
  if [ "${#pub}" -lt 1000 ] || [ "${#rot}" -lt 300 ]; then
    FAIL "$id: parsed bodies are ${#pub} bytes (cmd_publish) and ${#rot} bytes (cmd_rotate), below the 1000/300 floors — a subject is absent or a stub, so the counts below would be read off an empty haystack"
  elif [ "$n_pub" -lt 1 ] || [ "$n_rot" -lt 1 ]; then
    FAIL "$id: cmd_publish calls announce_passphrase_file $n_pub time(s) and cmd_rotate $n_rot — a path that announces without it prints whatever its own printf interpolates, which is where the disclosure lived"
  elif [ "$n_get" -ne 1 ] || [ "$n_cat" -ne 0 ]; then
    FAIL "$id: cmd_publish holds $n_get get_passphrase call(s) (want exactly 1, the encryption resolution) and cmd_rotate $n_cat 'cat \"\$pf\"' construct(s) (want 0) — a second resolution at the announcement site is the value arriving where it must not"
  else
    PASS "$id: both paths announce through the helper — cmd_publish $n_pub call, cmd_rotate $n_rot call, over ${#pub}/${#rot}-byte parsed bodies; cmd_publish resolves the passphrase exactly $n_get time (for encryption) and cmd_rotate carries $n_cat reads of the passphrase file"
  fi
}
pp_wiring_assert "PP6"

# ── PP7 — the control case the card requires, EXECUTED on every run rather than performed
# once by hand: restore the pre-fix emitter, which interpolates the value it reads from the
# path, re-run PP1's own argv, and require exactly one FAIL and no PASS. Without this, a
# green PP1 proves only that PP1 ran.
pp_mutant_probe() { # <assertion-fn> [args…] -> "<pass> <fail>" on stdout
  ( announce_passphrase_file() {   # the PRE-FIX emitter, restored in shape
      printf '\n  %s: \033[1;36m%s\033[0m  (saved to %s)\n' "$1" "$(cat "$2")" "$2"
    }
    pass=0; fail=0
    PASS() { pass=$((pass+1)); }
    FAIL() { fail=$((fail+1)); }
    "$@" >/dev/null 2>&1
    printf '%d %d' "$pass" "$fail" )
}
PP_MUT="$(pp_mutant_probe pp_publish_assert "PP7-inner" "$PP1D")"
if [ "$PP_MUT" = "0 1" ]; then
  PASS "PP7: CONTROL on the capture arm — with the pre-fix value-emitting announcer restored, PP1's own argv reports pass=0 fail=1, diagnosed as the VALUE reaching standard output. The arm convicts the defect this card removed, so its green above is a measurement"
else
  FAIL "PP7: CONTROL did not fire — with the pre-fix value-emitting announcer restored, PP1's argv returned '$PP_MUT' rather than '0 1'. Until the arm convicts a known-disclosing announcer, PP1's pass proves only that the assertion executed"
fi

# ── PP8 — the env-override limb, and it is a defect in its own right. With
# $STATICRYPT_PASSWORD set and no .passphrase present (the arm removes it first — a differing
# file is now refused before resolution, GHSA-gmm2-v7rr-jq7r), the resolver takes the
# environment value and writes NO file, while the message this change replaced announced it as "saved to …/.passphrase"
# unconditionally. Measured before the fix: 653 capture bytes, env value present, the
# saved-to claim present, the file absent. The helper branches on the DESTINATION's state,
# so both limbs stay value-free and neither makes a claim about a file that is not there.
pp_env_assert() { # <id> <trip_dir> <env_value>
  local id="$1" d="$2" v="$3" pf="$2/.passphrase" cap hasp=0 hasv=0 claims=0 exists=0
  rm -f "$pf"
  cap="$(pp_capture_publish "$d" "$v")"
  [ -e "$pf" ] && exists=1
  case "$cap" in *"$pf"*) hasp=1 ;; esac
  case "$cap" in *"$v"*)  hasv=1 ;; esac
  case "$cap" in *"saved to"*) claims=1 ;; esac
  if [ "$exists" -eq 1 ]; then
    FAIL "$id: the fixture is broken — a .passphrase file exists at $pf after an env-supplied publish, so this arm is not exercising the branch it names and its verdict would be about a different path"
  elif [ "$hasp" -eq 0 ]; then
    FAIL "$id: the capture carries no '$pf' pointer — DEGENERATE HAYSTACK, VERDICT WITHHELD (denominator: ${#cap} capture bytes, ${#v}-char env value, pointer found=$hasp)"
  elif [ "$hasv" -eq 1 ]; then
    FAIL "$id: the environment-supplied passphrase VALUE reached standard output (denominator: ${#cap} capture bytes, ${#v}-char env value, pointer found=$hasp)"
  elif [ "$claims" -eq 1 ]; then
    FAIL "$id: the capture says the passphrase was 'saved to' a file that does not exist — the announcement branched on the CALLER rather than on the destination, and a pointer at nothing is worse than the message it replaced (denominator: ${#cap} capture bytes, ${#v}-char env value, pointer found=$hasp)"
  else
    PASS "$id: with the passphrase supplied from the environment and no file written, the capture names the path, carries neither the ${#v}-character value nor a claim that it was saved, and says plainly that this run stored no copy (denominator: ${#cap} capture bytes, ${#v}-char env value, pointer found=$hasp)"
  fi
}
PP8D="$(pp_fixture pp8)"
PP_ENVVAL='zzq-env-supplied-passphrase-for-pp8'
pp_env_assert "PP8" "$PP8D" "$PP_ENVVAL"

# ── PP9 — the delivery path is INTACT, and MD-opt-out (its subject is a filesystem mode).
# Without this arm PP1 could be satisfied by a build in which the passphrase stopped
# existing at all: the pointer must point at something real, mode 600, holding a value that
# clears get_passphrase's own 12-character floor.
PP_MODE="$(ls -l "$PP1D/.passphrase" 2>/dev/null)"; PP_MODE="${PP_MODE:0:10}"
PP_VAL=""; [ -r "$PP1D/.passphrase" ] && PP_VAL="$(cat "$PP1D/.passphrase")"
if [ "$PP_MODE" = "-rw-------" ] && [ "${#PP_VAL}" -ge 12 ]; then
  PASS "PP9: the delivery path survives the fix — $PP1D/.passphrase exists at mode $PP_MODE and holds a ${#PP_VAL}-character value, so the pointer PP1 asserted points at a real, private, usable passphrase"
else
  FAIL "PP9: the passphrase file reads mode '$PP_MODE' (want -rw-------) with a ${#PP_VAL}-character value (want >= 12) — either the persistence broke or the file is world-readable, and PP1's pointer-only verdict would be satisfied by a build that delivers no passphrase at all"
fi

# ── The MD registrations. Each re-runs the SAME argv its live arm ran, with the named
# subject removed. announce_passphrase_file is the subject of every capture arm and of both
# introspection arms; PP6 is registered twice, once per call site, because an absent
# cmd_publish and an absent cmd_rotate are different removals of the same claim.
md_flips announce_passphrase_file "PP1"     pp_publish_assert        "PP1" "$PP1D"
md_flips announce_passphrase_file "PP2"     pp_rotate_assert         "PP2" "$PP2D"
md_flips announce_passphrase_file "PP3"     pp_rc_assert             "PP3"
md_flips announce_passphrase_file "PP4"     pp_cannot_disclose_assert "PP4"
md_flips announce_passphrase_file "PP5"     pp_single_limb_assert    "PP5"
md_flips announce_passphrase_file "PP8"     pp_env_assert            "PP8" "$PP8D" "$PP_ENVVAL"
md_flips cmd_publish              "PP6"     pp_wiring_assert         "PP6"
md_flips cmd_rotate               "PP6-rot" pp_wiring_assert         "PP6"

# Teardown: the mocks go, and the two shimmed production functions are RE-DEFINED from the
# definitions saved above rather than unset — `unset -f` here would delete the real ones.
unset -f gh npx
eval "$PP_ORIG_ENC"
eval "$PP_ORIG_BOIL"
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 \
      GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1 GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2

# ═════════════════════════════════════════════════════════════════════════════════
# Group RV — a rotation revokes: the page rotate pushes is under the key it records,
# whatever the environment carries (GHSA-gmm2-v7rr-jq7r).
#
# THE DEFECT, through 0.43.0. rotate wrote a fresh passphrase to .passphrase and then
# re-published through update, whose resolution returns $STATICRYPT_PASSWORD before it
# reads the file. With the variable set, the site was re-encrypted under the variable, so
# the previous passphrase kept working while rotate reported a rotation. A routine update
# with the variable still set did the same after a CORRECT rotation. And rotate wrote the
# file before any of update's checks ran, so an aborted rotation left .passphrase holding a
# key the live site was not under — after a too-short --passphrase, the only on-disk copy
# of the live key was gone.
#
# WHAT THE ARMS BIND TO. The key of the PUSHED page, not the key a function was handed:
# rv_enc_shim writes a per-call nonce into the ciphertext it returns and records nonce ->
# key, and rv_pushed_key reads the nonce back out of the bare repository's main:index.html.
# RV10b reads every revision main holds, not only its tip: history is published too.
#
# DISCIPLINES, each load-bearing:
#   - Every subject runs in its own subshell with STATICRYPT_PASSWORD unset or set by the
#     arm. An inherited variable would silently turn a control into the attack.
#   - Subjects run under ( set -e; … ), production's errexit — EXCEPT RV8, whose subject IS
#     independence from errexit: a caller in an `||` context, or this suite's own set +e,
#     disables -e for the whole function body, and the fix must stop on its own.
#   - Scratch repositories pin commit signing OFF. The arms that need a commit to FAIL pin
#     commit.gpgsign=true with gpg.format=openpgp and gpg.program=false inside their own
#     subshell: deterministic, offline, and never reaching an operator's signing agent.
#   - Every refusal or abort arm asserts an exact rc AND a witness only the graded point
#     prints, so an absent subject (rc=127) cannot satisfy it. Conditions in the verdict
#     chains are shell tests over flags computed first (MD2).
#   - The "unreadable" arm assumes a non-root runner, as CI's is: root reads mode 000.
#
# ORDER. RV6 and RV12 grade the REAL encrypt_to_tmp and run before its shim is installed:
# md_probe removes its subject by name, so a shim standing in that name would leave both
# arms blind to the function they exist to grade.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group RV — a rotation revokes: the pushed page is under the key rotate records, whatever the environment carries."

RVW="$WORK/rv"; mkdir -p "$RVW/origin"
RV_GHLOG="$RVW/gh.log"; RV_NPXLOG="$RVW/npx.log"; RV_KEYLOG="$RVW/keys.log"
: > "$RV_GHLOG"; : > "$RV_NPXLOG"; : > "$RV_KEYLOG"
RV_ORIG_ENC="$(declare -f encrypt_to_tmp)"
RV_ORIG_BOIL="$(declare -f make_boilerplate)"
export GIT_CONFIG_COUNT=3 \
  GIT_CONFIG_KEY_0=commit.gpgsign     GIT_CONFIG_VALUE_0=false \
  GIT_CONFIG_KEY_1=tag.gpgsign        GIT_CONFIG_VALUE_1=false \
  GIT_CONFIG_KEY_2=init.defaultBranch GIT_CONFIG_VALUE_2=main

rv_has()   { case "$1" in *"$2"*) return 0 ;; esac; return 1; }          # substring, no pipeline
rv_lines() { local n; n="$(wc -l < "$1")"; printf '%s' "${n//[^0-9]/}"; }   # line count, no pipeline
rv_head()  { git -C "$1" rev-parse main 2>/dev/null; }

gh() {   # mock: log the call, answer the read-only probes, create and clone nothing real
  printf '%s\n' "$*" >> "$RV_GHLOG"
  case "${1:-} ${2:-}" in
    "api user")    printf 'testowner' ;;
    "repo view")   return 1 ;;
    "auth status") [ -z "${RV_GH_AUTH_FAIL:-}" ] || return 1; printf "Token scopes: 'repo'\n" ;;
    "repo clone")  return 1 ;;
    *)             return 0 ;;
  esac
}
npx() { printf 'npx\n' >> "$RV_NPXLOG"; return 0; }

# A trip whose per-trip clone already exists, pushing to a local bare repository named
# <name>-trip.git so ensure_pub_clone reuses it. The optional key seeds .passphrase.
rv_fixture() { # <name> [key] -> trip dir
  local d="$RVW/$1" bare="$RVW/origin/$1-trip.git"
  mkdir -p "$d/outputs" "$bare"
  cp "$SRC" "$d/outputs/$1-travel-site.html"
  git init -q --bare "$bare"
  git init -q "$d/.publish"
  git -C "$d/.publish" remote add origin "$bare"
  cp "$ENC_OK" "$d/.publish/index.html"
  git -C "$d/.publish" add index.html
  git -C "$d/.publish" -c user.name=t -c user.email=t@example.invalid commit -q -m seed
  git -C "$d/.publish" branch -M main
  git -C "$d/.publish" push -q origin main
  if [ "$#" -ge 2 ]; then printf '%s\n' "$2" > "$d/.passphrase"; chmod 600 "$d/.passphrase"; fi
  printf '%s' "$d"
}

# The key the page at <bare>'s main was encrypted under, read from the nonce the encrypt
# shim wrote into it. Prints nothing when no pushed page carries a nonce.
rv_pushed_key() { # <bare>
  local html n line re='staticryptEncrypted="(rv[0-9a-f]+)"'
  html="$(git -C "$1" show main:index.html 2>/dev/null)" || return 0
  [[ "$html" =~ $re ]] || return 0
  n="${BASH_REMATCH[1]}"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in "$n "*) printf '%s' "${line#"$n "}"; return 0 ;; esac
  done < "$RV_KEYLOG"
}

# The encrypt shim: ENC_OK (or $RV_ENC_SRC) with a per-call nonce in place of its
# ciphertext marker. The keys it records are synthetic and never printed by any arm.
rv_enc_shim() { # <src_html> <passphrase> -> dir holding index.html
  local e n
  n="rv$(od -An -N6 -tx1 /dev/urandom | tr -dc 'a-f0-9')"
  e="$(mktemp -d)"
  sed "s/bb12ab/$n/" "${RV_ENC_SRC:-$ENC_OK}" > "$e/index.html"
  printf '%s %s\n' "$n" "$2" >> "$RV_KEYLOG"
  printf '%s' "$e"
}

# ── RV6 / RV12 — the REAL encrypt_to_tmp, before any shim. RV6: a key below the 12-character
# floor must be refused BEFORE StatiCrypt is reached, with errexit OFF (this suite's default),
# because the floor may not depend on how the caller spelled the call. The npx mock PRODUCES
# output: a non-producing one fails the call for an unrelated reason and would read as the
# floor holding. RV6c is the control — a long key reaches npx exactly once.
rv6_assert() { # <id> <short|long>
  local id="$1" which="$2" key rc calls
  case "$which" in short) key='short-key' ;; *) key='rv-long-enough-synthetic-key' ;; esac
  : > "$RV_NPXLOG"
  ( npx() {
      local a dd=""
      printf 'npx\n' >> "$RV_NPXLOG"
      for a in "$@"; do [ "$dd" = next ] && dd="$a"; [ "$a" = -d ] && dd=next; done
      mkdir -p "$dd"; printf 'ciphertext\n' > "$dd/index.html"
    }
    encrypt_to_tmp "$SRC" "$key" ) >/dev/null 2>&1; rc=$?
  calls="$(rv_lines "$RV_NPXLOG")"
  if [ "$which" = short ]; then
    if [ "$rc" -ne 1 ]; then
      FAIL "$id: encrypt_to_tmp handed a 9-character key returned rc=$rc, want exactly 1 — StatiCrypt may run under a key below the floor ($calls npx call(s))"
    elif [ "$calls" != "0" ]; then
      FAIL "$id: encrypt_to_tmp refused the short key only after $calls npx call(s) — the floor must stop it before StatiCrypt is reached"
    else
      PASS "$id: a key below the 12-character floor is refused before StatiCrypt runs (rc=1, 0 npx calls), with errexit off"
    fi
  else
    if [ "$rc" -ne 0 ] || [ "$calls" != "1" ]; then
      FAIL "$id: CONTROL — a key above the floor returned rc=$rc with $calls npx call(s), want rc=0 and exactly 1: the arm above cannot tell a floor from a broken path"
    else
      PASS "$id: CONTROL — a key above the floor reaches StatiCrypt exactly once (rc=0), so RV6's zero is a measurement"
    fi
  fi
}
rv6_assert "RV6" short
rv6_assert "RV6c" long

# RV12 — the key reaches StatiCrypt only through the STATICRYPT_PASSWORD prefix assignment.
# StatiCrypt 3.5.4 prefers a set STATICRYPT_PASSWORD over -p, so an inherited variable would
# beat an explicit -p — and -p would put the key in argv.
rv12_assert() { # <id>
  local id="$1" b hasprefix=0 hasp=0
  b="$(declare -f encrypt_to_tmp 2>/dev/null)"
  rv_has "$b" 'STATICRYPT_PASSWORD="$passphrase"' && hasprefix=1
  { rv_has "$b" ' -p ' || rv_has "$b" '--password'; } && hasp=1
  if [ "${#b}" -lt 200 ]; then
    FAIL "$id: encrypt_to_tmp's parsed body is ${#b} bytes — the subject is absent or a stub. VERDICT WITHHELD"
  elif [ "$hasprefix" -eq 0 ]; then
    FAIL "$id: encrypt_to_tmp no longer hands StatiCrypt the key through the STATICRYPT_PASSWORD prefix assignment"
  elif [ "$hasp" -eq 1 ]; then
    FAIL "$id: encrypt_to_tmp passes the key with -p/--password — an inherited STATICRYPT_PASSWORD would win over it, and the key would sit in argv"
  else
    PASS "$id: encrypt_to_tmp hands the key over only through the prefix assignment, never -p or --password (${#b}-byte body)"
  fi
}
rv12_assert "RV12"
md_flips encrypt_to_tmp "RV6"  rv6_assert  "RV6" short
md_flips encrypt_to_tmp "RV6c" rv6_assert  "RV6c" long
md_flips encrypt_to_tmp "RV12" rv12_assert "RV12"

# Every arm below runs against the shims.
encrypt_to_tmp()   { rv_enc_shim "$@"; }
make_boilerplate() { return 1; }

# ── RV1 — AC1. rotate, with STATICRYPT_PASSWORD holding the current key: the pushed page
# must be under the key .passphrase now holds, and that must not be the previous key.
# RV1c is the same rotation with the variable unset.
rv1_assert() { # <id> <set|unset>
  local id="$1" mode="$2" name d k rc now old='rv-previous-synthetic-key-0001'
  name="rv1-$mode-$RANDOM"; d="$(rv_fixture "$name" "$old")"
  if [ "$mode" = set ]; then
    ( export STATICRYPT_PASSWORD="$old"; set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc=$?
  else
    ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc=$?
  fi
  k="$(rv_pushed_key "$RVW/origin/$name-trip.git")"
  now="$(cat "$d/.passphrase" 2>/dev/null)"
  if [ "$rc" -ne 0 ]; then
    FAIL "$id: rotate (variable $mode) returned rc=$rc, want 0"
  elif [ -z "$k" ]; then
    FAIL "$id: no pushed page carries a nonce — the push was not observed. DEGENERATE, VERDICT WITHHELD"
  elif [ "$k" = "$old" ]; then
    FAIL "$id: the pushed page is still under the PREVIOUS passphrase (variable $mode) — rotate reported a rotation and revoked nothing"
  elif [ "$k" != "$now" ]; then
    FAIL "$id: the pushed page is not under the key .passphrase holds (variable $mode) — the passphrase rotate announces does not open the site"
  else
    PASS "$id: with the variable $mode, rotate pushed a page under the key .passphrase now holds, and it is not the previous key"
  fi
}
rv1_assert "RV1"  set
rv1_assert "RV1c" unset

# ── RV2 / RV2c — AC2. The variable and .passphrase disagree: update and publish must refuse
# before any gh call — on a never-cloned trip, so a refusal that followed the clone could not
# hide — and the refusal must name both sources and carry neither value.
rv2_assert() { # <id> <update|publish>
  local id="$1" verb="$2" name d out rc calls named=0 leaks=0
  name="rv2-$verb-$RANDOM"; d="$RVW/$name"; mkdir -p "$d/outputs"
  cp "$SRC" "$d/outputs/$name-travel-site.html"
  printf '%s\n' 'rv-file-synthetic-key-AAAA-1' > "$d/.passphrase"
  : > "$RV_GHLOG"
  out="$( ( export STATICRYPT_PASSWORD='rv-env-synthetic-key-BBBB-2'; set -e; "cmd_$verb" "$d" ) 2>&1 )"; rc=$?
  calls="$(rv_lines "$RV_GHLOG")"
  rv_has "$out" 'STATICRYPT_PASSWORD' && rv_has "$out" "$d/.passphrase" && named=1
  { rv_has "$out" 'rv-env-synthetic-key-BBBB-2' || rv_has "$out" 'rv-file-synthetic-key-AAAA-1'; } && leaks=1
  if [ "$rc" -ne 1 ]; then
    FAIL "$id: $verb with the variable and .passphrase disagreeing returned rc=$rc, want exactly 1 (a refusal)"
  elif [ "$named" -eq 0 ]; then
    FAIL "$id: $verb exited 1, but not with a refusal naming both STATICRYPT_PASSWORD and the trip's .passphrase — some other failure, so the disagreement was never graded"
  elif [ "$calls" != "0" ]; then
    FAIL "$id: $verb refused only after $calls gh call(s) — the disagreement must stop it before any network effect"
  elif [ "$leaks" -eq 1 ]; then
    FAIL "$id: the refusal carries a passphrase VALUE"
  else
    PASS "$id: $verb refuses the disagreement before any gh call (rc=1, 0 calls), naming both sources and carrying neither value"
  fi
}
rv2_assert "RV2"  update
rv2_assert "RV2c" publish

# RV2b — the refusal states no value, length or prefix. A substring test cannot show a
# length is absent, so this is differential: two refusals over key pairs of different
# lengths and prefixes, from the same trip path, must be byte-identical.
rv2b_assert() { # <id>
  local id="$1" name d m1 m2 r1 r2 both=0
  name="rv2b-$RANDOM"; d="$RVW/$name"; mkdir -p "$d/outputs"
  cp "$SRC" "$d/outputs/$name-travel-site.html"
  printf '%s\n' 'aa-short-file-key-01' > "$d/.passphrase"
  m1="$( ( export STATICRYPT_PASSWORD='bb-short-env-key-02'; set -e; cmd_update "$d" ) 2>&1 )"; r1=$?
  printf '%s\n' 'zz-a-considerably-longer-synthetic-file-key-0003' > "$d/.passphrase"
  m2="$( ( export STATICRYPT_PASSWORD='yy-another-much-longer-synthetic-env-key-000004'; set -e; cmd_update "$d" ) 2>&1 )"; r2=$?
  rv_has "$m1" 'STATICRYPT_PASSWORD' && rv_has "$m2" 'STATICRYPT_PASSWORD' && both=1
  if [ "$r1" -ne 1 ] || [ "$r2" -ne 1 ] || [ "$both" -eq 0 ]; then
    FAIL "$id: the two disagreeing runs did not both refuse naming STATICRYPT_PASSWORD (rc=$r1/$r2) — nothing to compare. VERDICT WITHHELD"
  elif [ "$m1" != "$m2" ]; then
    FAIL "$id: the refusal text changed when only the passphrases' lengths and prefixes changed — it discloses something about a value"
  else
    PASS "$id: two refusals over key pairs of different lengths and prefixes are byte-identical (${#m1} bytes) — the refusal states no value, length or prefix"
  fi
}
rv2b_assert "RV2b"

# RV2d — controls. Where the sources do not disagree, update publishes exactly as before:
# variable only, file only, both equal, and an EMPTY variable (which is unset, everywhere).
rv2d_assert() { # <id> <env-only|file-only|agree|empty-env>
  local id="$1" c="$2" name d k rc want
  name="rv2d-$c-$RANDOM"
  case "$c" in
    env-only)  want='rv-env-only-synthetic-key-01'; d="$(rv_fixture "$name")"
               ( export STATICRYPT_PASSWORD="$want"; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc=$? ;;
    file-only) want='rv-file-only-synthetic-key-02'; d="$(rv_fixture "$name" "$want")"
               ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc=$? ;;
    agree)     want='rv-agreeing-synthetic-key-003'; d="$(rv_fixture "$name" "$want")"
               ( export STATICRYPT_PASSWORD="$want"; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc=$? ;;
    *)         want='rv-empty-env-synthetic-key-04'; d="$(rv_fixture "$name" "$want")"
               ( export STATICRYPT_PASSWORD=''; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc=$? ;;
  esac
  k="$(rv_pushed_key "$RVW/origin/$name-trip.git")"
  if [ "$rc" -ne 0 ] || [ -z "$k" ]; then
    FAIL "$id: update ($c) returned rc=$rc and pushed no page bound to a key — a non-conflicting case must publish"
  elif [ "$k" != "$want" ]; then
    FAIL "$id: update ($c) pushed a page under a key other than the one its sources name"
  else
    PASS "$id: update ($c) publishes under the key its sources name — no disagreement, no refusal, unchanged behaviour"
  fi
}
for rv_c in env-only file-only agree empty-env; do rv2d_assert "RV2d-$rv_c" "$rv_c"; done

# RV2e — FM-4's domain. A .passphrase the resolver cannot read AS the variable's key is a
# disagreement, not an absence: unreadable, empty, newline only, a second line, CRLF. Each
# file's first line equals the variable where it has one, so only the shape triggers.
rv2e_assert() { # <id> <unreadable|empty|newline-only|two-line|crlf>
  local id="$1" s="$2" name d out rc calls named=0 key='rv-domain-synthetic-key-0005'
  name="rv2e-$s-$RANDOM"; d="$(rv_fixture "$name")"
  case "$s" in
    unreadable)   printf '%s\n' "$key" > "$d/.passphrase"; chmod 000 "$d/.passphrase" ;;
    empty)        : > "$d/.passphrase" ;;
    newline-only) printf '\n' > "$d/.passphrase" ;;
    two-line)     printf '%s\n%s\n' "$key" 'rv-second-line' > "$d/.passphrase" ;;
    *)            printf '%s\r\n' "$key" > "$d/.passphrase" ;;
  esac
  : > "$RV_GHLOG"
  out="$( ( export STATICRYPT_PASSWORD="$key"; set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  calls="$(rv_lines "$RV_GHLOG")"
  chmod 600 "$d/.passphrase" 2>/dev/null
  rv_has "$out" 'STATICRYPT_PASSWORD' && named=1
  if [ "$rc" -ne 1 ] || [ "$named" -eq 0 ]; then
    FAIL "$id: with the variable set and a .passphrase that is $s, update returned rc=$rc without the refusal"
  elif [ "$calls" != "0" ]; then
    FAIL "$id: the $s-file refusal came after $calls gh call(s)"
  else
    PASS "$id: a .passphrase that is $s, beside a set variable, is refused before any gh call"
  fi
}
for rv_s in unreadable empty newline-only two-line crlf; do rv2e_assert "RV2e-$rv_s" "$rv_s"; done

# ── RV3 — AC3. A rotation aborted before its push leaves .passphrase byte-identical, at every
# abort point, each proven REACHED by the point's own message. "absent": a trip with no
# .passphrase keeps none after an aborted rotation.
rv3_assert() { # <id> <floor|gate|preflight|clone|encrypt|guard|commit|absent|unusable>
  local id="$1" p="$2" name d bare out rc h0 h1 w seen=0 same=0
  name="rv3-$p-$RANDOM"; bare="$RVW/origin/$name-trip.git"
  case "$p" in
    gate|absent|unusable) d="$(s_fixture "$name" 16:30 none)"
                 if [ "$p" = unusable ]; then printf 'published=2027-06-01T00:00:00Z\n' > "$d/.published-itinerary"
                 else s_record "$d/.published-itinerary" "$S_DA" published; fi ;;
    clone)       d="$RVW/$name"; mkdir -p "$d/outputs"; cp "$SRC" "$d/outputs/$name-travel-site.html" ;;
    *)           d="$(rv_fixture "$name")" ;;
  esac
  [ "$p" = absent ] || printf '%s\n' 'rv-live-synthetic-key-0006' > "$d/.passphrase"
  [ -e "$d/.passphrase" ] && cp -p "$d/.passphrase" "$RVW/$name.before"
  h0="$(rv_head "$bare")"
  case "$p" in
    floor)     w='shorter than 12 characters'
               out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" --passphrase 'short-key' ) 2>&1 )"; rc=$? ;;
    gate|absent) w='itinerary content differs'
               out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    unusable)  w='present but cannot be used'
               out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    preflight) w='gh is not authenticated'
               out="$( ( unset STATICRYPT_PASSWORD; export RV_GH_AUTH_FAIL=1; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    clone)     w="run 'publish' first"
               out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    encrypt)   w='rv-encrypt-shim-refused'
               out="$( ( unset STATICRYPT_PASSWORD
                         encrypt_to_tmp() { printf 'rv-encrypt-shim-refused\n' >&2; return 1; }
                         set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    guard)     w='not verified ciphertext'
               out="$( ( unset STATICRYPT_PASSWORD; export RV_ENC_SRC="$ENC_LEAK"; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
    *)         w='failed to sign'
               out="$( ( unset STATICRYPT_PASSWORD
                         export GIT_CONFIG_COUNT=5 GIT_CONFIG_VALUE_0=true \
                           GIT_CONFIG_KEY_3=gpg.format GIT_CONFIG_VALUE_3=openpgp \
                           GIT_CONFIG_KEY_4=gpg.program GIT_CONFIG_VALUE_4=false
                         set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$? ;;
  esac
  h1="$(rv_head "$bare")"
  rv_has "$out" "$w" && seen=1
  if [ "$p" = absent ]; then
    [ ! -e "$d/.passphrase" ] && same=1
  else
    cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  fi
  if [ "$rc" -ne 1 ]; then
    FAIL "$id: rotate aborted at the $p point returned rc=$rc, want exactly 1"
  elif [ "$seen" -eq 0 ]; then
    FAIL "$id: rotate exited 1 without the $p point's own message — the abort was not observed where this arm grades it. VERDICT WITHHELD"
  elif [ "$h0" != "$h1" ]; then
    FAIL "$id: the per-trip repository moved during a rotation aborted at the $p point"
  elif [ "$same" -eq 0 ]; then
    FAIL "$id: a rotation aborted at the $p point left .passphrase changed or created — it no longer names the key the live site is under"
  else
    PASS "$id: rotate aborted at the $p point (rc=1, the point's own message) and .passphrase is exactly as it was"
  fi
}
for rv_p in floor gate preflight clone encrypt guard commit absent unusable; do rv3_assert "RV3-$rv_p" "$rv_p"; done

# ── RV4 — AC4. The push fails after the commit point: .passphrase must already name the new
# key, and the next update must publish under it — never back under the revoked one.
rv4_assert() { # <id>
  local id="$1" name d bare out rc k2 now old='rv-before-rotation-key-07' told=0
  name="rv4-$RANDOM"; d="$(rv_fixture "$name" "$old")"; bare="$RVW/origin/$name-trip.git"
  git -C "$d/.publish" remote set-url origin "$RVW/missing/$name-trip.git"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$?
  git -C "$d/.publish" remote set-url origin "$bare"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  k2="$(rv_pushed_key "$bare")"
  now="$(cat "$d/.passphrase" 2>/dev/null)"
  rv_has "$out" 'ROTATED' && told=1
  if [ "$rc" -eq 0 ] || [ "$told" -eq 1 ]; then
    FAIL "$id: a rotation whose push failed reported success (rc=$rc)"
  elif [ -z "$k2" ]; then
    FAIL "$id: the follow-up update pushed no page bound to a key — convergence was not observed. VERDICT WITHHELD"
  elif [ "$k2" = "$old" ]; then
    FAIL "$id: after a failed-push rotation, the next update published under the REVOKED key — the rotation was silently undone"
  elif [ "$k2" != "$now" ]; then
    FAIL "$id: after a failed-push rotation, the next update did not publish under the key .passphrase names"
  else
    PASS "$id: a rotation whose push failed left .passphrase naming the new key, and the next update converged the site onto it"
  fi
}
rv4_assert "RV4"

# ── RV5 — rotate's arguments. A --passphrase with no value, and an unknown option, are
# refused before anything is written; neither may silently generate a key and rotate.
rv5_assert() { # <id> <no-value|unknown>
  local id="$1" f="$2" name d bare out rc h0 h1 w seen=0 same=0
  name="rv5-$f-$RANDOM"; d="$(rv_fixture "$name" 'rv-live-synthetic-key-0008')"; bare="$RVW/origin/$name-trip.git"
  cp -p "$d/.passphrase" "$RVW/$name.before"; h0="$(rv_head "$bare")"
  if [ "$f" = no-value ]; then
    w='needs a value'
    out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" --passphrase ) 2>&1 )"; rc=$?
  else
    w='unknown option'
    out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" --bogus ) 2>&1 )"; rc=$?
  fi
  h1="$(rv_head "$bare")"
  rv_has "$out" "$w" && seen=1
  cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  if [ "$rc" -ne 1 ]; then
    FAIL "$id: rotate with $f returned rc=$rc, want exactly 1 — it went ahead instead of refusing"
  elif [ "$seen" -eq 0 ]; then
    FAIL "$id: rotate exited 1 without saying why ($f). VERDICT WITHHELD"
  elif [ "$h0" != "$h1" ] || [ "$same" -eq 0 ]; then
    FAIL "$id: rotate with $f changed the site or .passphrase"
  else
    PASS "$id: rotate with $f refuses (rc=1) and changes nothing"
  fi
}
for rv_f in no-value unknown; do rv5_assert "RV5-$rv_f" "$rv_f"; done

# ── RV13 — Q-1. An unknown option is refused WITHOUT being echoed. A mistyped
# "--passphrase=<value>", or a value typed with its flag forgotten, IS the token, so echoing it
# puts a passphrase on stderr — and into any captured log or transcript. rotate's parser is new in
# this release; publish's and unpublish's carried the same echo before it.
rv13_assert() { # <id> <rotate|publish|unpublish> <eq|bare>
  local id="$1" verb="$2" form="$3" name d out rc tok seen=0 leak=0
  local k='rv-mistyped-synthetic-key-18'
  name="rv13-$verb-$form-$RANDOM"; d="$(rv_fixture "$name" 'rv-live-synthetic-key-0019')"
  case "$form" in eq) tok="--passphrase=$k" ;; *) tok="$k" ;; esac
  out="$( ( unset STATICRYPT_PASSWORD; set -e; "cmd_$verb" "$d" "$tok" ) 2>&1 )"; rc=$?
  rv_has "$out" 'unknown option' && seen=1
  rv_has "$out" "$k" && leak=1
  if [ "$rc" -ne 1 ] || [ "$seen" -eq 0 ]; then
    FAIL "$id: $verb did not refuse the mistyped option as an unknown option (rc=$rc). VERDICT WITHHELD"
  elif [ "$leak" -eq 1 ]; then
    FAIL "$id: $verb echoed the unknown option, so a mistyped passphrase reached the output"
  else
    PASS "$id: $verb refuses an unknown option without echoing it, so a mistyped passphrase never reaches the output"
  fi
}
for rv_v in rotate publish unpublish; do rv13_assert "RV13-$rv_v" "$rv_v" eq; done
rv13_assert "RV13-rotate-bare" rotate bare

# ── RV7 — D-5. When STATICRYPT_PASSWORD is still set after a rotation and differs from the
# new key, rotate says so — value-free, on stderr — because the next publish or update will
# refuse. It stays silent when the variable matches the new key, or is unset. The warning's
# rotation is captured with its two channels APART: merged, a warning moved to stdout (the
# announcer's channel) reads exactly like one on stderr, and the arm could not tell.
rv7_assert() { # <id>
  local id="$1" d1 d2 d3 o1 e1 o2 o3 r1 r2 r3 k1 w1=0 wout=0 w23=0 leak=0
  local env='rv-stale-env-synthetic-key-09' nk='rv-chosen-new-synthetic-key-10' cur='rv-current-synthetic-key-11'
  d1="$(rv_fixture "rv7a-$RANDOM" "$cur")"; d2="$(rv_fixture "rv7b-$RANDOM" "$cur")"; d3="$(rv_fixture "rv7c-$RANDOM" "$cur")"
  o1="$( ( export STATICRYPT_PASSWORD="$env"; set -e; cmd_rotate "$d1" ) 2>"$RVW/$id.stderr" )"; r1=$?
  e1="$(cat "$RVW/$id.stderr" 2>/dev/null)"
  o2="$( ( export STATICRYPT_PASSWORD="$nk"; set -e; cmd_rotate "$d2" --passphrase "$nk" ) 2>&1 )"; r2=$?
  o3="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d3" ) 2>&1 )"; r3=$?
  k1="$(cat "$d1/.passphrase" 2>/dev/null)"
  rv_has "$e1" 'still set in this environment' && w1=1
  rv_has "$o1" 'still set in this environment' && wout=1
  { rv_has "$o2" 'still set in this environment' || rv_has "$o3" 'still set in this environment'; } && w23=1
  { rv_has "$o1$e1" "$env" || { [ -n "$k1" ] && rv_has "$o1$e1" "$k1"; }; } && leak=1
  if [ "$r1" -ne 0 ] || [ "$r2" -ne 0 ] || [ "$r3" -ne 0 ]; then
    FAIL "$id: a rotation did not complete (rc=$r1/$r2/$r3) — nothing to grade. VERDICT WITHHELD"
  elif [ "$wout" -eq 1 ]; then
    FAIL "$id: rotate's warning about a still-set STATICRYPT_PASSWORD reached standard output — it belongs on stderr, apart from the announcer's channel"
  elif [ "$w1" -eq 0 ]; then
    FAIL "$id: rotate with a different STATICRYPT_PASSWORD still set gave no warning on stderr — the next publish or update will refuse, and the operator was not told why"
  elif [ "$w23" -eq 1 ]; then
    FAIL "$id: rotate warned although the variable matched the new key or was unset"
  elif [ "$leak" -eq 1 ]; then
    FAIL "$id: rotate's output carries a passphrase VALUE"
  else
    PASS "$id: rotate warns on stderr, value-free, only when the variable is set and differs from the new key"
  fi
}
rv7_assert "RV7"

# ── RV8 — FM-1. The commit is forced to fail and errexit cannot stop it: once with this
# suite's own errexit OFF, once with the caller spelling `cmd_rotate … || true` under set -e.
# In both, bash ignores -e for the whole function body; the rotation must stop on its own.
rv8_assert() { # <id> <errexit-off|or-true>
  local id="$1" how="$2" name d bare out rc h0 h1 told=0 same=0
  name="rv8-$how-$RANDOM"; d="$(rv_fixture "$name" 'rv-live-synthetic-key-0012')"; bare="$RVW/origin/$name-trip.git"
  cp -p "$d/.passphrase" "$RVW/$name.before"; h0="$(rv_head "$bare")"
  if [ "$how" = errexit-off ]; then
    out="$( ( unset STATICRYPT_PASSWORD
              export GIT_CONFIG_COUNT=5 GIT_CONFIG_VALUE_0=true \
                GIT_CONFIG_KEY_3=gpg.format GIT_CONFIG_VALUE_3=openpgp \
                GIT_CONFIG_KEY_4=gpg.program GIT_CONFIG_VALUE_4=false
              cmd_rotate "$d"; printf 'rv8-caller-continued\n' ) 2>&1 )"; rc=$?
  else
    out="$( ( unset STATICRYPT_PASSWORD
              export GIT_CONFIG_COUNT=5 GIT_CONFIG_VALUE_0=true \
                GIT_CONFIG_KEY_3=gpg.format GIT_CONFIG_VALUE_3=openpgp \
                GIT_CONFIG_KEY_4=gpg.program GIT_CONFIG_VALUE_4=false
              set -e; cmd_rotate "$d" || true; printf 'rv8-caller-continued\n' ) 2>&1 )"; rc=$?
  fi
  h1="$(rv_head "$bare")"
  { rv_has "$out" 'ROTATED' || rv_has "$out" 'rv8-caller-continued'; } && told=1
  cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  if [ "$rc" -ne 1 ]; then
    FAIL "$id: with the commit forced to fail ($how), the run ended rc=$rc, want exactly 1 — the failure did not stop it"
  elif [ "$told" -eq 1 ]; then
    FAIL "$id: a rotation whose commit failed was reported done, or its caller carried on ($how)"
  elif [ "$h0" != "$h1" ]; then
    FAIL "$id: the per-trip repository moved although the commit failed ($how)"
  elif [ "$same" -eq 0 ]; then
    FAIL "$id: a rotation whose commit failed changed .passphrase ($how)"
  else
    PASS "$id: a failed commit stops the rotation by itself ($how): rc=1, nothing reported, the repository unmoved, .passphrase exactly as it was"
  fi
}
rv8_assert "RV8-errexit-off" errexit-off
rv8_assert "RV8-or-true"     or-true

# ── RV9 — the operator's path shape. Every other fixture path here is absolute; the command
# people type is relative (rotate trips/<dir>). A key write placed inside a `cd` would break
# exactly this form while every other arm stayed green.
rv9_assert() { # <id>
  local id="$1" name d rc k now
  name="rv9-$RANDOM"; d="$(rv_fixture "$name" 'rv-live-synthetic-key-0013')"
  ( cd "$RVW" || exit 1; unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$name" ) >/dev/null 2>&1; rc=$?
  k="$(rv_pushed_key "$RVW/origin/$name-trip.git")"
  now="$(cat "$d/.passphrase" 2>/dev/null)"
  if [ "$rc" -ne 0 ] || [ -z "$k" ]; then
    FAIL "$id: rotate given a relative trip path returned rc=$rc with no observable push"
  elif [ "$k" != "$now" ]; then
    FAIL "$id: rotate given a relative trip path pushed a page not under the key .passphrase holds"
  else
    PASS "$id: rotate works from a relative trip path — the page it pushed is under the key .passphrase holds"
  fi
}
rv9_assert "RV9"

# ── RV10 — FM-6. Another rotation changes .passphrase after this update resolved its key and
# before it pushes (simulated inside the encrypt step). update must re-read the key of record
# and stop, or it pushes the revoked key over the rotation.
rv10_assert() { # <id>
  local id="$1" name d bare out rc h0 h1 seen=0
  name="rv10-$RANDOM"; d="$(rv_fixture "$name" 'rv-resolved-synthetic-key-14')"; bare="$RVW/origin/$name-trip.git"
  h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; rv10_pf="$d/.passphrase"
            encrypt_to_tmp() { rv_enc_shim "$@"; printf '%s\n' 'rv-concurrent-rotation-key-15' > "$rv10_pf"; }
            set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  h1="$(rv_head "$bare")"
  rv_has "$out" 'changed while this update was running' && seen=1
  if [ "$rc" -ne 1 ]; then
    FAIL "$id: update carried on although .passphrase changed under it (rc=$rc) — it would push the revoked key over a concurrent rotation"
  elif [ "$h0" != "$h1" ]; then
    FAIL "$id: the per-trip repository moved although the key of record changed mid-update"
  elif [ "$seen" -eq 0 ]; then
    FAIL "$id: update exited 1 without the key-of-record message — the check was not the cause. VERDICT WITHHELD"
  else
    PASS "$id: update re-reads the key of record before its push and stops when it has changed — the revoked key is never pushed over a rotation"
  fi
}
rv10_assert "RV10"

# ── RV10b — FM-6, followed through. RV10 shows the aborted update pushes nothing at the moment it
# stops. But it has already COMMITTED, under the key the concurrent rotation revoked, and the
# per-trip clone is reused as it stands: a commit left there rides the next push, and the next
# routine update is the refusal's own remedy. So abort one update exactly as RV10 does, run a
# second, and read the key of EVERY revision the bare repository's main now holds — the page at
# the tip is the control that the walk reads keys at all. None may be the key the aborted run
# resolved.
rv10b_assert() { # <id>
  local id="$1" name d bare o1 rc1 rc2 revs rev html n line head_key="" carried=0 seen=0
  local k1='rv-resolved-synthetic-key-16' k2='rv-concurrent-rotation-key-17' re='staticryptEncrypted="(rv[0-9a-f]+)"'
  name="rv10b-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  o1="$( ( unset STATICRYPT_PASSWORD; rv10b_pf="$d/.passphrase"; rv10b_k2="$k2"
           encrypt_to_tmp() { rv_enc_shim "$@"; printf '%s\n' "$rv10b_k2" > "$rv10b_pf"; }
           set -e; cmd_update "$d" ) 2>&1 )"; rc1=$?
  rv_has "$o1" 'changed while this update was running' && seen=1
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc2=$?
  head_key="$(rv_pushed_key "$bare")"
  revs="$(git -C "$bare" rev-list main 2>/dev/null)"
  while IFS= read -r rev; do
    [ -n "$rev" ] || continue
    html="$(git -C "$bare" show "$rev:index.html" 2>/dev/null)" || continue
    [[ "$html" =~ $re ]] || continue
    n="${BASH_REMATCH[1]}"
    while IFS= read -r line || [ -n "$line" ]; do
      [ "$line" = "$n $k1" ] && carried=1
    done < "$RV_KEYLOG"
  done <<< "$revs"
  if [ "$rc1" -ne 1 ] || [ "$seen" -eq 0 ]; then
    FAIL "$id: the first update did not stop at the key-of-record re-check (rc=$rc1) — nothing to follow up. VERDICT WITHHELD"
  elif [ "$rc2" -ne 0 ] || [ "$head_key" != "$k2" ]; then
    FAIL "$id: the follow-up update did not publish under the key of record (rc=$rc2) — the history walk has no control. VERDICT WITHHELD"
  elif [ "$carried" -eq 1 ]; then
    FAIL "$id: the follow-up update pushed the aborted run's commit — the site's history now holds a page under the key the rotation revoked"
  else
    PASS "$id: an update stopped by the key-of-record re-check leaves nothing behind — the next update's push carries no page under the revoked key"
  fi
}
rv10b_assert "RV10b"

# 0 when any revision of <bare>'s main carries a page whose nonce the encrypt shim recorded for
# <key>. History is published too, so a page anywhere in it counts, not only the tip.
rv_history_has_key() { # <bare> <key>
  local revs rev html n line re='staticryptEncrypted="(rv[0-9a-f]+)"'
  revs="$(git -C "$1" rev-list main 2>/dev/null)"
  while IFS= read -r rev; do
    [ -n "$rev" ] || continue
    html="$(git -C "$1" show "${rev}:index.html" 2>/dev/null)" || continue
    [[ "$html" =~ $re ]] || continue
    n="${BASH_REMATCH[1]}"
    while IFS= read -r line || [ -n "$line" ]; do
      [ "$line" = "$n $2" ] && return 0
    done < "$RV_KEYLOG"
  done <<< "$revs"
  return 1
}

# ── RV14 — Q-3. A .passphrase that is a symbolic link is written THROUGH, as it was before the
# atomic writer: the link survives, and its target holds the new key — the key the pushed page is
# under. Replacing the link would leave the operator's key store holding the revoked key.
rv14_assert() { # <id>
  local id="$1" name d bare rc store link=0 key pushed
  name="rv14-$RANDOM"; d="$(rv_fixture "$name")"; bare="$RVW/origin/$name-trip.git"
  store="$RVW/$name-store"; mkdir -p "$store"
  printf '%s\n' 'rv-stored-synthetic-key-0020' > "$store/key"; chmod 600 "$store/key"
  ln -s "$store/key" "$d/.passphrase"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc=$?
  [ -L "$d/.passphrase" ] && link=1
  key="$(cat "$store/key" 2>/dev/null)"; pushed="$(rv_pushed_key "$bare")"
  if [ "$rc" -ne 0 ]; then
    FAIL "$id: rotate through a symlinked .passphrase did not complete (rc=$rc) — nothing to grade. VERDICT WITHHELD"
  elif [ "$link" -eq 0 ]; then
    FAIL "$id: rotate replaced the symlinked .passphrase with a regular file — the linked key store keeps the revoked key"
  elif [ -z "$pushed" ] || [ "$key" != "$pushed" ]; then
    FAIL "$id: the link's target does not hold the key the pushed page is under"
  else
    PASS "$id: rotate writes the new key through a symlinked .passphrase — the link survives, and its target holds the key the pushed page is under"
  fi
}
rv14_assert "RV14"

# ── RV15 — Q-2. A page an earlier update committed but failed to push stays in the reused clone,
# encrypted under the current key. A rotation committing on top would push it too — publishing,
# under the key being revoked, content that was never live under it, to exactly the holders the
# rotation exists to cut off. rotate must refuse while the clone holds a commit the remote does
# not, and change nothing. Removing the clone, the remedy it names first, must then let the
# rotation publish only its own page: the whole history is read for the pending page's key.
rv15_assert() { # <id>
  local id="$1" name d bare out rc0 rc1 rc2 h0 h1 ahead same=0 seen=0 carried=0
  local k1='rv-pending-page-synthetic-key-21'
  name="rv15-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  git -C "$d/.publish" remote set-url origin "$RVW/missing/$name-trip.git"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc0=$?
  git -C "$d/.publish" remote set-url origin "$bare"
  ahead="$(git -C "$d/.publish" rev-list --count refs/remotes/origin/main..HEAD 2>/dev/null)"
  cp -p "$d/.passphrase" "$RVW/$name.before"; h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc1=$?
  h1="$(rv_head "$bare")"
  cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  rv_has "$out" 'not yet pushed' && seen=1
  rm -rf "$d/.publish"
  ( unset STATICRYPT_PASSWORD; rv15_bare="$bare"
    gh() {
      printf '%s\n' "$*" >> "$RV_GHLOG"
      case "${1:-} ${2:-}" in
        "api user")    printf 'testowner' ;;
        "repo view")   return 1 ;;
        "auth status") printf "Token scopes: 'repo'\n" ;;
        "repo clone")  git clone -q "$rv15_bare" "$4" ;;
        *)             return 0 ;;
      esac
    }
    set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc2=$?
  rv_history_has_key "$bare" "$k1" && carried=1
  if [ "$rc0" -ne 1 ] || [ "$ahead" != 1 ]; then
    FAIL "$id: the failed update did not leave exactly one unpushed commit (rc=$rc0, ahead=$ahead) — nothing to grade. VERDICT WITHHELD"
  elif [ "$rc1" -ne 1 ]; then
    FAIL "$id: rotate went ahead (rc=$rc1) with a page in the clone the remote does not have — its push carries that page, under the key it revokes"
  elif [ "$seen" -eq 0 ]; then
    FAIL "$id: rotate exited 1 without naming the unpushed page. VERDICT WITHHELD"
  elif [ "$h0" != "$h1" ] || [ "$same" -eq 0 ]; then
    FAIL "$id: the refusal changed the site or .passphrase"
  elif [ "$rc2" -ne 0 ]; then
    FAIL "$id: after the named remedy (remove the clone), the rotation did not complete (rc=$rc2)"
  elif [ "$carried" -eq 1 ]; then
    FAIL "$id: the site's history holds the pending page under the revoked key"
  else
    PASS "$id: rotate refuses while the clone holds an unpushed page and changes nothing; after its named remedy the rotation publishes only its own page — no page under the revoked key reaches the history"
  fi
}
rv15_assert "RV15"

# ── RV16 — Q-5. The discard takes back only this run's OWN commit. When another command commits
# on top of it before the re-check — named residual (i) — HEAD is no longer this run's commit, and
# discarding HEAD would drop the other command's page and leave the clone behind the remote. The
# ownership test is the ciphertext itself: nonced, so no other commit carries the same page. The
# stop may come at the read-back right after this run's commit, or at the re-check: either way the
# other command's commit stays where it is, and no discard is claimed.
rv16_assert() { # <id>
  local id="$1" name d out rc rot tip claimed=0
  local k1='rv-racing-update-synthetic-key-22' k2='rv-racing-rotation-synthetic-key-23'
  name="rv16-$RANDOM"; d="$(rv_fixture "$name" "$k1")"
  out="$( ( unset STATICRYPT_PASSWORD; rv16_d="$d"; rv16_k2="$k2"; rv16_rot="$RVW/$name.rot"
            commit_noreply() {
              local e
              git -C "$1" -c user.name=t -c user.email=t@example.invalid commit --quiet -m "$2" || return 1
              # another command commits its own page on top, and records its key, before this run re-checks
              e="$(rv_enc_shim "$SRC" "$rv16_k2")"; cp "$e/index.html" "$1/index.html"; rm -rf "$e"
              git -C "$1" add index.html || return 1
              git -C "$1" -c user.name=t -c user.email=t@example.invalid commit --quiet -m rotation || return 1
              git -C "$1" rev-parse HEAD > "$rv16_rot"
              printf '%s\n' "$rv16_k2" > "$rv16_d/.passphrase"
            }
            set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  rot="$(cat "$RVW/$name.rot" 2>/dev/null)"; tip="$(git -C "$d/.publish" rev-parse main 2>/dev/null)"
  rv_has "$out" 'discarded its own commit' && claimed=1
  if [ "$rc" -ne 1 ] || [ -z "$rot" ]; then
    FAIL "$id: the update did not stop with another command's commit on top of its own (rc=$rc). VERDICT WITHHELD"
  elif [ "$tip" != "$rot" ]; then
    FAIL "$id: the update moved main off the other command's commit — it discarded a page that was not its own and left the clone behind the remote"
  elif [ "$claimed" -eq 1 ]; then
    FAIL "$id: the update reported discarding its own commit when the commit on top was another command's"
  else
    PASS "$id: with another command's commit on top of its own, the update stops, leaves the clone as it is and claims no discard — it never takes back a commit it cannot show is its own"
  fi
}
rv16_assert "RV16"

# ── RV17 — DQ-1, the β interleaving. rotate commits; an update commits on top before rotate pushes.
# A push of the BRANCH publishes that update's page — under the key the rotation revokes — as the
# live page, while rotate reports that the passphrase rotated. rotate must publish exactly its own
# commit, so that its success means its own page is the one live.
rv17_assert() { # <id>
  local id="$1" name d bare rc live pf
  local k1='rv-beta-old-synthetic-key-24'
  name="rv17-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  ( unset STATICRYPT_PASSWORD; rv17_pub="$d/.publish"; rv17_k1="$k1"
    write_passphrase_file() {   # rotate's commit point: an update commits on top here, before rotate pushes
      local e
      e="$(rv_enc_shim "$SRC" "$rv17_k1")"; cp "$e/index.html" "$rv17_pub/index.html"; rm -rf "$e"
      git -C "$rv17_pub" add index.html || return 1
      git -C "$rv17_pub" -c user.name=t -c user.email=t@example.invalid commit --quiet -m update || return 1
      printf '%s\n' "$2" > "$1"
    }
    set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc=$?
  live="$(rv_pushed_key "$bare")"; pf="$(cat "$d/.passphrase" 2>/dev/null)"
  if [ "$rc" -ne 0 ] || [ -z "$live" ]; then
    FAIL "$id: the rotation did not complete with a readable live page (rc=$rc) — nothing to grade. VERDICT WITHHELD"
  elif [ "$live" = "$k1" ]; then
    FAIL "$id: rotate reported success while the live page is another command's, under the key the rotation revoked — it pushed the branch, not its own commit"
  elif [ "$live" != "$pf" ]; then
    FAIL "$id: the live page is not under the key rotate recorded"
  else
    PASS "$id: with another command's commit stacked on top, rotate publishes exactly its own commit — its success means its own page, under the key it recorded, is the one live"
  fi
}
rv17_assert "RV17"

# ── RV18 — DQ-1, the γ interleaving. rotate commits; an update commits on top AND pushes before rotate
# records its key. rotate's own push then has nothing new to send, and a branch push reports success
# with the update's old-key page live. A rotation that lost that race must say so — its push must
# fail — and the next update, the remedy its message names, must bring the live page under the key
# the rotation recorded.
rv18_assert() { # <id>
  local id="$1" name d bare rc rc2 live live2 pf
  local k1='rv-gamma-old-synthetic-key-25'
  name="rv18-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  ( unset STATICRYPT_PASSWORD; rv18_pub="$d/.publish"; rv18_k1="$k1"
    write_passphrase_file() {   # an update commits on top AND pushes, before rotate records its key
      local e
      e="$(rv_enc_shim "$SRC" "$rv18_k1")"; cp "$e/index.html" "$rv18_pub/index.html"; rm -rf "$e"
      git -C "$rv18_pub" add index.html || return 1
      git -C "$rv18_pub" -c user.name=t -c user.email=t@example.invalid commit --quiet -m update || return 1
      git -C "$rv18_pub" push --quiet origin main || return 1
      printf '%s\n' "$2" > "$1"
    }
    set -e; cmd_rotate "$d" ) >/dev/null 2>&1; rc=$?
  live="$(rv_pushed_key "$bare")"; pf="$(cat "$d/.passphrase" 2>/dev/null)"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc2=$?
  live2="$(rv_pushed_key "$bare")"
  if [ "$rc" -eq 0 ] && [ "$live" != "$pf" ]; then
    FAIL "$id: rotate reported success while the live page stayed under the key it revoked — a rotation that loses the race must fail at its push"
  elif [ "$rc" -eq 0 ]; then
    FAIL "$id: the rotation was meant to lose the race, and it completed — the interleaving was not reproduced. VERDICT WITHHELD"
  elif [ "$rc2" -ne 0 ] || [ -z "$live2" ] || [ "$live2" != "$pf" ]; then
    FAIL "$id: after the rotation failed, the next update did not bring the live page under the key rotate recorded (rc=$rc2)"
  else
    PASS "$id: a rotation that lost the race to a concurrent update fails at its push instead of reporting success, and the next update brings the live page under the key it recorded"
  fi
}
rv18_assert "RV18"

# ── RV19 — DQ-2, the δ interleaving: γ with the two pushes the other way round. An update commits on
# top of a rotation's commit, reads it back and re-checks .passphrase a moment BEFORE the rotation
# records its key; the rotation then records it and pushes first. The update's own push is an
# ordinary fast-forward on top of the rotation's commit, so it put its page — under the key the
# rotation revoked — back as the live one while both commands reported success. The update's push
# must be bound to the remote state its re-check saw: it fails, takes back exactly its own commit
# and says so, and the rotation's page, under the key it recorded, stays live.
rv19_assert() { # <id>
  local id="$1" name d bare pub e r1 out rc live tip otip injected=0 claimed=0
  local k1='rv-delta-old-synthetic-key-26' k2='rv-delta-new-synthetic-key-27'
  name="rv19-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  # the rotation's commit, made before the update runs and not yet pushed; its key is not yet recorded
  e="$(rv_enc_shim "$SRC" "$k2")"; cp "$e/index.html" "$pub/index.html"; rm -rf "$e"
  git -C "$pub" add index.html
  git -C "$pub" -c user.name=t -c user.email=t@example.invalid commit -q -m rotation
  r1="$(git -C "$pub" rev-parse HEAD)"
  out="$( ( unset STATICRYPT_PASSWORD; rv19_d="$d"; rv19_pub="$pub"; rv19_r1="$r1"; rv19_k2="$k2"; rv19_mark="$RVW/$name.injected"
            rv19_def="$(declare -f require_key_of_record)"; eval "rv19_real_rkr ${rv19_def#require_key_of_record}"
            require_key_of_record() {   # the update re-checks and passes; THEN the rotation records its key and pushes first
              rv19_real_rkr "$@" || return $?
              if [ ! -e "$rv19_mark" ]; then
                : > "$rv19_mark"
                printf '%s\n' "$rv19_k2" > "$rv19_d/.passphrase"
                git -C "$rv19_pub" push --quiet origin "$rv19_r1:refs/heads/main" || return 1
              fi
            }
            set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  [ -e "$RVW/$name.injected" ] && injected=1
  live="$(rv_pushed_key "$bare")"
  tip="$(git -C "$pub" rev-parse main 2>/dev/null)"; otip="$(git -C "$pub" rev-parse refs/remotes/origin/main 2>/dev/null)"
  rv_has "$out" 'discarded its own commit' && claimed=1
  if [ "$injected" -eq 0 ]; then
    FAIL "$id: the rotation's key write and push were never reached between the update's re-check and its push — the interleaving was not reproduced. VERDICT WITHHELD"
  elif [ "$rc" -eq 0 ] && [ "$live" = "$k1" ]; then
    FAIL "$id: the update reported success and put its page, under the key the rotation revoked, back as the live one — its push was not bound to the remote state its re-check saw"
  elif [ "$rc" -ne 1 ]; then
    FAIL "$id: the update did not stop (rc=$rc) after a rotation recorded its key and pushed between the update's re-check and its push"
  elif [ "$live" != "$k2" ]; then
    FAIL "$id: the live page is not the rotation's, under the key the rotation recorded"
  elif [ "$claimed" -eq 0 ] || [ "$tip" != "$r1" ] || [ "$tip" != "$otip" ]; then
    FAIL "$id: the update did not take back exactly its own commit and say so (claimed=$claimed) — the clone is not at the rotation's commit, or is behind the remote"
  else
    PASS "$id: an update that re-checked the key a moment before a rotation recorded its new one fails at its push, takes back exactly its own commit and says so — the rotation's page, under the key it recorded, stays live"
  fi
}
rv19_assert "RV19"

# ── RV20 — DQ-6. A reused clone on a branch other than main — a pre-existing repository served from
# master, say — took this run's commit on that branch while the push targeted main, a branch nothing
# serves: update reported "Updated" and rotate "Passphrase ROTATED" with the served page unchanged.
# Both must refuse, naming the branch, before anything is committed; rotate must leave .passphrase as
# it was.
rv20_assert() { # <id> <update|rotate>
  local id="$1" verb="$2" name d bare pub out rc h0 h1 ahead mainref=0 named=0 same=0
  local k1='rv-master-served-synthetic-key-28'
  name="rv20-$verb-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  # re-shape the fixture into a repository served from master: the clone and the bare hold master only
  git -C "$pub" branch -M master
  git -C "$pub" push -q origin master
  git -C "$bare" symbolic-ref HEAD refs/heads/master
  git -C "$bare" update-ref -d refs/heads/main
  git -C "$pub" update-ref -d refs/remotes/origin/main
  git -C "$pub" fetch -q origin
  cp -p "$d/.passphrase" "$RVW/$name.before"; h0="$(git -C "$bare" rev-parse master)"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; "cmd_$verb" "$d" ) 2>&1 )"; rc=$?
  h1="$(git -C "$bare" rev-parse master)"
  git -C "$bare" rev-parse --verify -q refs/heads/main >/dev/null && mainref=1
  rv_has "$out" "'master'" && named=1
  cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  ahead="$(git -C "$pub" rev-list --count refs/remotes/origin/master..HEAD 2>/dev/null)"
  if [ "$rc" -eq 0 ]; then
    FAIL "$id: $verb reported success on a clone of a site served from master — its push went to main, a branch nothing serves, and the served page is unchanged"
  elif [ "$rc" -ne 1 ] || [ "$named" -eq 0 ]; then
    FAIL "$id: $verb did not refuse naming the clone's branch (rc=$rc). VERDICT WITHHELD"
  elif [ "$mainref" -eq 1 ] || [ "$h0" != "$h1" ]; then
    FAIL "$id: the refusal still changed the per-trip repository"
  elif [ "$ahead" != 0 ] || [ "$same" -eq 0 ]; then
    FAIL "$id: the refusal left a commit in the clone or changed .passphrase"
  else
    PASS "$id: $verb refuses a clone on a branch other than main, naming it, before anything is committed — the per-trip repository and .passphrase are exactly as they were"
  fi
}
rv20_assert "RV20-update" update
rv20_assert "RV20-rotate" rotate

# ── RV21 — DQ-4. push_trip_site builds "<commit>:refs/heads/main". An empty commit id makes that
# ":refs/heads/main" — a DELETION of the site's branch, which a remote permitting it carries out —
# and an id naming no commit is not a page any run made. The push must refuse both, naming the
# reason, before git is asked to push anything. The bare repository here permits the deletion.
rv21_assert() { # <id> <empty|junk>
  local id="$1" form="$2" name d bare pub own desc out rc h0 h1 said=0
  name="rv21-$form-$RANDOM"; d="$(rv_fixture "$name")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  git -C "$bare" config receive.denyDeleteCurrent ignore
  case "$form" in
    empty) own='';                desc='an empty commit id' ;;
    *)     own='not-a-commit-id'; desc='a commit id that names no commit' ;;
  esac
  h0="$(rv_head "$bare")"
  out="$( ( set -e; push_trip_site "$pub" "$own" update ) 2>&1 )"; rc=$?
  h1="$(rv_head "$bare")"
  rv_has "$out" 'not a commit' && said=1
  if [ -z "$h1" ]; then
    FAIL "$id: push_trip_site deleted the site's branch when handed $desc"
  elif [ "$h0" != "$h1" ]; then
    FAIL "$id: push_trip_site changed the site's branch when handed $desc"
  elif [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: push_trip_site did not refuse $desc as not a commit (rc=$rc). VERDICT WITHHELD"
  else
    PASS "$id: push_trip_site refuses $desc before pushing anything — the site's branch is untouched"
  fi
}
rv21_assert "RV21-empty" empty
rv21_assert "RV21-junk" junk

# ── RV13-omitted — DQ-3. With the trip left out, the first argument after the command is whatever
# came next — a passphrase typed with its flag forgotten, say — and the trip-directory refusal
# repeated it on stderr, where a captured log or transcript keeps it. The refusal says where it
# looked instead, and never repeats the argument; with --data-root it names that root.
rv13o_assert() { # <id> <verb> <bare|eq|rooted>
  local id="$1" verb="$2" form="$3" out rc tok seen=0 leak=0 where=1
  local k='rv-omitted-trip-synthetic-key-29'
  case "$form" in eq) tok="--passphrase=$k" ;; *) tok="$k" ;; esac
  if [ "$form" = rooted ]; then
    out="$( ( unset STATICRYPT_PASSWORD; _GUARD_DATA_ROOT="$RVW"; _GUARD_DATA_ROOT_EXPLICIT=1; set -e; "cmd_$verb" "$tok" ) 2>&1 )"; rc=$?
    rv_has "$out" "no such trip dir under $RVW/" || where=0
  else
    out="$( ( unset STATICRYPT_PASSWORD; set -e; "cmd_$verb" "$tok" ) 2>&1 )"; rc=$?
  fi
  rv_has "$out" 'no such trip dir' && seen=1
  rv_has "$out" "$k" && leak=1
  if [ "$rc" -ne 1 ] || [ "$seen" -eq 0 ] || [ "$where" -eq 0 ]; then
    FAIL "$id: $verb did not refuse the missing trip directory, saying where it looked (rc=$rc). VERDICT WITHHELD"
  elif [ "$leak" -eq 1 ]; then
    FAIL "$id: $verb repeated the argument in its trip-directory refusal, so a passphrase typed in the trip's place reached the output"
  else
    PASS "$id: $verb refuses a missing trip directory without repeating the argument, so a passphrase typed in the trip's place never reaches the output"
  fi
}
for rv_v in rotate publish unpublish update confirm; do rv13o_assert "RV13-omitted-$rv_v" "$rv_v" bare; done
rv13o_assert "RV13-omitted-rotate-eq" rotate eq
rv13o_assert "RV13-omitted-rooted" rotate rooted

# ── RV13-subcommand — DQ-3's sixth site: the dispatcher. A flag typed before the subcommand, as many
# command lines teach, became the subcommand, and its refusal repeated it. It must refuse without
# repeating it.
rv13s_assert() { # <id>
  local id="$1" out rc seen=0 leak=0
  local k='rv-subcommand-synthetic-key-33'
  out="$( ( unset STATICRYPT_PASSWORD; set -e; main "--passphrase=$k" rotate "$RVW/rv13s-none" ) 2>&1 )"; rc=$?
  rv_has "$out" 'unknown subcommand' && seen=1
  rv_has "$out" "$k" && leak=1
  if [ "$rc" -ne 1 ] || [ "$seen" -eq 0 ]; then
    FAIL "$id: the dispatcher did not refuse the flag typed in the subcommand's place as an unknown subcommand (rc=$rc). VERDICT WITHHELD"
  elif [ "$leak" -eq 1 ]; then
    FAIL "$id: the dispatcher repeated the unknown subcommand, so a passphrase typed before the subcommand reached the output"
  else
    PASS "$id: the dispatcher refuses an unknown subcommand without repeating it, so a passphrase typed before the subcommand never reaches the output"
  fi
}
rv13s_assert "RV13-subcommand"

# ── RV22 — DQ-5. rotate records its key through a link where .passphrase is one, and refuses a link
# it cannot follow or a key file it cannot stage beside. It resolved that path only at its commit
# point, after committing: a bad path stopped rotate with a commit left in the clone, and the next
# rotate refused that commit as a page an earlier run left unpushed. The path must be proven before
# anything is committed.
rv22_assert() { # <id> <missing-dir|loop>
  local id="$1" form="$2" name d bare pub out rc h0 h1 ahead lnk0 lnk1 said=0
  name="rv22-$form-$RANDOM"; d="$(rv_fixture "$name")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  case "$form" in
    missing-dir) ln -s "$RVW/$name-keystore/missing-dir/sub/key" "$d/.passphrase" ;;
    *)           ln -s "$d/.passphrase-b" "$d/.passphrase"; ln -s "$d/.passphrase" "$d/.passphrase-b" ;;
  esac
  lnk0="$(readlink "$d/.passphrase")"; h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$?
  h1="$(rv_head "$bare")"; lnk1="$(readlink "$d/.passphrase")"
  ahead="$(git -C "$pub" rev-list --count refs/remotes/origin/main..HEAD 2>/dev/null)"
  case "$form" in
    missing-dir) rv_has "$out" 'missing-dir/sub/key' && said=1 ;;
    *)           rv_has "$out" 'could not follow' && said=1 ;;
  esac
  if [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: rotate did not refuse the key path it cannot write (rc=$rc). VERDICT WITHHELD"
  elif [ "$ahead" != 0 ]; then
    FAIL "$id: rotate refused the key path only after committing — a commit is left in the clone (ahead=$ahead), and the next rotate refuses it as an unpushed page from an earlier run"
  elif [ "$h0" != "$h1" ] || [ "$lnk0" != "$lnk1" ]; then
    FAIL "$id: the refusal changed the site or the .passphrase link"
  else
    PASS "$id: rotate refuses a key path it cannot write before anything is committed — the clone, the site and the link are exactly as they were"
  fi
}
rv22_assert "RV22-missing-dir" missing-dir
rv22_assert "RV22-loop" loop

# ── RV23 — DQ-7, the discard's "already on the remote" test. When the key-of-record check stops an
# update whose OWN commit another command has already pushed — a branch push from elsewhere carried
# it — that commit is published. Taking it back would leave the clone behind the remote and claim a
# discard that did not happen. The discard must refuse, and the update must say the commit may be
# live. This is the shape only that test guards: with another commit stacked on top instead, the
# discard's compare-and-swap refuses on its own.
rv23_assert() { # <id>
  local id="$1" name d bare pub out rc tip otip injected=0 claimed=0 honest=0
  local k1='rv-pushed-own-synthetic-key-30' k2='rv-pushed-own-new-synthetic-key-31'
  name="rv23-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  out="$( ( unset STATICRYPT_PASSWORD; rv23_d="$d"; rv23_pub="$pub"; rv23_k2="$k2"; rv23_mark="$RVW/$name.injected"
            rv23_def="$(declare -f require_key_of_record)"; eval "rv23_real_rkr ${rv23_def#require_key_of_record}"
            require_key_of_record() {   # another command pushes the branch, carrying the commit this run made, then records a new key
              if [ ! -e "$rv23_mark" ]; then
                : > "$rv23_mark"
                git -C "$rv23_pub" push --quiet origin main || return 1
                printf '%s\n' "$rv23_k2" > "$rv23_d/.passphrase"
              fi
              rv23_real_rkr "$@"
            }
            set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  [ -e "$RVW/$name.injected" ] && injected=1
  tip="$(git -C "$pub" rev-parse main 2>/dev/null)"; otip="$(git -C "$pub" rev-parse refs/remotes/origin/main 2>/dev/null)"
  rv_has "$out" 'discarded its own commit' && claimed=1
  rv_has "$out" 'may already have published it' && honest=1
  if [ "$injected" -eq 0 ] || [ "$rc" -ne 1 ]; then
    FAIL "$id: the update did not stop at its key check after its own commit was pushed from elsewhere (rc=$rc). VERDICT WITHHELD"
  elif [ "$claimed" -eq 1 ] || [ "$tip" != "$otip" ]; then
    FAIL "$id: the update took back a commit that was already published — it claimed a discard and left the clone behind the remote"
  elif [ "$honest" -eq 0 ]; then
    FAIL "$id: the update did not say its commit may already be published"
  else
    PASS "$id: an update whose own commit was already pushed from elsewhere refuses to take it back, says it may be live, and leaves the clone level with the remote"
  fi
}
rv23_assert "RV23"

# ── RV24 — DQ-7, the refusal's unreadable-ref branch. rotate counts the clone's unpushed pages against
# its record of the remote; when that record cannot be read it cannot tell whether a page under the
# key being revoked would ride its push. It must refuse and change nothing — never read the
# unreadable record as "no unpushed pages".
rv24_assert() { # <id>
  local id="$1" name d bare pub out rc h0 h1 same=0 said=0
  local k1='rv-unreadable-ref-synthetic-key-32'
  name="rv24-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  git -C "$pub" update-ref -d refs/remotes/origin/main
  cp -p "$d/.passphrase" "$RVW/$name.before"; h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$?
  h1="$(rv_head "$bare")"
  cmp -s "$RVW/$name.before" "$d/.passphrase" && same=1
  rv_has "$out" 'could not tell' && said=1
  if [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: rotate did not refuse when it could not read its record of the remote (rc=$rc)"
  elif [ "$h0" != "$h1" ] || [ "$same" -eq 0 ]; then
    FAIL "$id: the refusal changed the site or .passphrase"
  else
    PASS "$id: rotate refuses when it cannot read its record of the remote, and changes nothing — it never reads an unreadable record as no unpushed pages"
  fi
}
rv24_assert "RV24"

# ── RV25 — DQ3-1. A push the server applied but the clone never recorded — a connection dropped after
# the server accepted it — left the clone's record of the remote behind for good. update leased its
# push on that record, so every later update refused and its "re-run update" looped. update must
# refresh the record before it leases, and converge: the next update succeeds with the live page
# under the key .passphrase names. The push below goes by path. Since Git 2.56 a push by path or URL
# to a uniquely matching remote moves that remote's tracking ref as well, so the setup puts the clone's
# record back where it stood before the push: the state a dropped connection leaves.
rv25_assert() { # <id> <rotate|update>
  local id="$1" form="$2" name d bare pub e c rec_pre rec0 srv0 rc live pf
  local k1='rv-unrecorded-old-synthetic-key-34' k2='rv-unrecorded-new-synthetic-key-35'
  name="rv25-$form-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  case "$form" in
    rotate) e="$(rv_enc_shim "$SRC" "$k2")"; printf '%s\n' "$k2" > "$d/.passphrase" ;;
    *)      e="$(rv_enc_shim "$SRC" "$k1")" ;;
  esac
  cp "$e/index.html" "$pub/index.html"; rm -rf "$e"
  git -C "$pub" add index.html
  git -C "$pub" -c user.name=t -c user.email=t@example.invalid commit -q -m "$form"
  c="$(git -C "$pub" rev-parse HEAD)"
  rec_pre="$(git -C "$pub" rev-parse -q --verify refs/remotes/origin/main)"
  git -C "$pub" push -q "$bare" "$c:refs/heads/main"
  if [ -n "$rec_pre" ]; then
    git -C "$pub" update-ref refs/remotes/origin/main "$rec_pre"
  elif git -C "$pub" rev-parse -q --verify refs/remotes/origin/main >/dev/null; then
    git -C "$pub" update-ref -d refs/remotes/origin/main
  fi
  rec0="$(git -C "$pub" rev-parse refs/remotes/origin/main 2>/dev/null)"; srv0="$(rv_head "$bare")"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc=$?
  live="$(rv_pushed_key "$bare")"; pf="$(cat "$d/.passphrase" 2>/dev/null)"
  if [ "$srv0" != "$c" ] || [ "$rec0" = "$c" ]; then
    FAIL "$id: the push was not applied-but-unrecorded as set up — nothing to grade. VERDICT WITHHELD"
  elif [ "$rc" -ne 0 ]; then
    FAIL "$id: after a $form push the server applied but the clone never recorded, update did not converge (rc=$rc) — the stale record kept it refusing"
  elif [ -z "$live" ] || [ "$live" != "$pf" ]; then
    FAIL "$id: update completed, but the live page is not under the key .passphrase names"
  else
    PASS "$id: after a $form push the server applied but the clone never recorded, the next update converges — the live page is under the key .passphrase names"
  fi
}
rv25_assert "RV25-rotate" rotate
rv25_assert "RV25-update" update

# ── RV26 — the rewind guard the refreshed record needs. When the site's history was rewound from
# elsewhere — pages withdrawn by a force-push from another machine — an update whose clone still
# records the old tip must not publish those pages again. After refreshing its record it refuses,
# naming the rewind, unless its old record is an ancestor of the new one.
rv26_assert() { # <id>
  local id="$1" name d bare p0 out rc n0 n1 said=0
  local k1='rv-rewind-synthetic-key-36'
  name="rv26-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  p0="$(rv_head "$bare")"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  git -C "$bare" update-ref refs/heads/main "$p0"
  n0="$(git -C "$bare" rev-list --count main)"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  n1="$(git -C "$bare" rev-list --count main)"
  rv_has "$out" 'rewound' && said=1
  if [ "$n0" != 1 ]; then
    FAIL "$id: the remote was not rewound to its first page as set up — nothing to grade. VERDICT WITHHELD"
  elif [ "$n1" != "$n0" ]; then
    FAIL "$id: the update published pages the rewind had withdrawn"
  elif [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: the update did not refuse naming the rewind (rc=$rc). VERDICT WITHHELD"
  else
    PASS "$id: after the site's history was rewound elsewhere, update refuses naming the rewind and publishes nothing — withdrawn pages stay withdrawn"
  fi
}
rv26_assert "RV26"

# ── RV27 — DQ3-4. A .passphrase that resolves to a directory took a rotation's key INTO that directory,
# at a random name, while rotate reported success: the site was re-keyed and the key stranded. rotate
# must refuse before anything is committed.
rv27_assert() { # <id>
  local id="$1" name d bare pub out rc h0 h1 ahead said=0
  name="rv27-$RANDOM"; d="$(rv_fixture "$name")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  mkdir -p "$RVW/$name-keydir"; ln -s "$RVW/$name-keydir" "$d/.passphrase"
  h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$?
  h1="$(rv_head "$bare")"; ahead="$(git -C "$pub" rev-list --count refs/remotes/origin/main..HEAD 2>/dev/null)"
  rv_has "$out" 'not a regular file' && said=1
  if [ "$rc" -eq 0 ]; then
    FAIL "$id: rotate reported success with its new key stranded inside a directory"
  elif [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: rotate did not refuse a key path that is a directory (rc=$rc). VERDICT WITHHELD"
  elif [ "$ahead" != 0 ] || [ "$h0" != "$h1" ]; then
    FAIL "$id: rotate refused only after committing, or changed the site"
  else
    PASS "$id: rotate refuses a key path that is a directory before anything is committed — the clone and the site are exactly as they were"
  fi
}
rv27_assert "RV27"

# ── RV26-retry — DQ4-1. The rewind refusal fired once. Its own fetch had already moved the clone's
# record to the rewound tip, so the same command run again — the natural retry after any refusal —
# found an old record that was an ancestor of the new one, passed the guard, and published the
# withdrawn pages. A refused rewind must stay refused until the clone is removed, which is the
# remedy the refusal names.
rv26r_assert() { # <id>
  local id="$1" name d bare p0 out1 out2 rc1 rc2 n_pre n0 n1 n2 said1=0 said2=0
  local k1='rv-rewind-retry-synthetic-key-37'
  name="rv26r-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  p0="$(rv_head "$bare")"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  n_pre="$(git -C "$bare" rev-list --count main)"
  git -C "$bare" update-ref refs/heads/main "$p0"
  n0="$(git -C "$bare" rev-list --count main)"
  out1="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) 2>&1 )"; rc1=$?
  n1="$(git -C "$bare" rev-list --count main)"
  out2="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) 2>&1 )"; rc2=$?
  n2="$(git -C "$bare" rev-list --count main)"
  rv_has "$out1" 'rewound' && said1=1
  rv_has "$out2" 'rewound' && said2=1
  if [ "$n_pre" != 3 ] || [ "$n0" != 1 ]; then
    FAIL "$id: the site did not carry two update pages that a rewind to its first page withdrew, as set up ($n_pre, then $n0) — nothing to grade. VERDICT WITHHELD"
  elif [ "$rc1" -ne 1 ] || [ "$said1" -eq 0 ] || [ "$n1" != "$n0" ]; then
    FAIL "$id: the first update after the rewind did not refuse naming it with nothing published (rc=$rc1) — that is the case RV26 grades. VERDICT WITHHELD"
  elif [ "$n2" != "$n0" ]; then
    FAIL "$id: the same update run again after the rewind refusal published the withdrawn pages (the site went from $n0 to $n2 commits) — the refusal's own fetch left the record at the rewound tip, so the retry passed"
  elif [ "$rc2" -ne 1 ] || [ "$said2" -eq 0 ]; then
    FAIL "$id: the retry did not refuse naming the rewind (rc=$rc2). VERDICT WITHHELD"
  else
    PASS "$id: after the site's history was rewound elsewhere, update refuses on the retry too, naming the rewind, and publishes nothing — the refusal holds until the clone is removed"
  fi
}
rv26r_assert "RV26-retry"

# ── RV28 — DQ4-1, its second path. With no record of the remote in the clone, the rewind guard had
# nothing to compare and was skipped: the fetch created the record at the rewound tip, and the
# update published the withdrawn pages. An update that cannot read its record must refuse, naming
# it, before anything reaches the site — a fresh clone always carries a record, so removing the
# clone, the remedy the refusal names, converges.
rv28_assert() { # <id>
  local id="$1" name d bare pub p0 out rc n_pre n0 n1 hasrec=0 said=0
  local k1='rv-no-record-rewind-synthetic-key-38'
  name="rv28-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  p0="$(rv_head "$bare")"
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1
  n_pre="$(git -C "$bare" rev-list --count main)"
  git -C "$bare" update-ref refs/heads/main "$p0"
  git -C "$pub" update-ref -d refs/remotes/origin/main
  git -C "$pub" rev-parse --verify -q refs/remotes/origin/main >/dev/null && hasrec=1
  n0="$(git -C "$bare" rev-list --count main)"
  out="$( ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  n1="$(git -C "$bare" rev-list --count main)"
  rv_has "$out" 'could not read the record' && said=1
  if [ "$n_pre" != 3 ] || [ "$n0" != 1 ] || [ "$hasrec" -eq 1 ]; then
    FAIL "$id: the site was not rewound with the clone's record removed, as set up — nothing to grade. VERDICT WITHHELD"
  elif [ "$n1" != "$n0" ]; then
    FAIL "$id: an update whose clone had no record of the remote published the pages a rewind withdrew (the site went from $n0 to $n1 commits) — with nothing to compare, the rewind guard was skipped"
  elif [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: the update did not refuse naming the missing record (rc=$rc). VERDICT WITHHELD"
  else
    PASS "$id: an update whose clone has no record of the remote refuses, naming it, and publishes nothing — a rewind cannot pass the guard by the record being absent"
  fi
}
rv28_assert "RV28"

# ── RV29 — DQ4-2. An update that could not fetch the site stopped before its key check. When a
# rotation had recorded a new key by then, the update kept its own commit, a page under the key the
# rotation replaced, and its "re-run update" remedy pushed that page into the site's history. The
# fetch failure must run the key check first, as the push failure does: take back exactly its own
# commit and say so, so the next update publishes no page under the replaced key. The git shim
# below stands for both events at the one fetch the script makes: the rotation's key write, then
# the unreachable site.
rv29_assert() { # <id>
  local id="$1" name d bare pub out rc rc2 h0 h1 ahead injected=0 claimed=0 hist=0
  local k1='rv-fetch-fail-old-synthetic-key-39' k2='rv-fetch-fail-new-synthetic-key-40'
  name="rv29-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"; pub="$d/.publish"
  h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; rv29_d="$d"; rv29_k2="$k2"; rv29_mark="$RVW/$name.injected"
            git() {   # a rotation records its key, then the site cannot be reached when the update fetches
              if [ "${1:-}" = -C ] && [ "${3:-}" = fetch ] && [ ! -e "$rv29_mark" ]; then
                : > "$rv29_mark"
                printf '%s\n' "$rv29_k2" > "$rv29_d/.passphrase"
                return 1
              fi
              command git "$@"
            }
            set -e; cmd_update "$d" ) 2>&1 )"; rc=$?
  [ -e "$RVW/$name.injected" ] && injected=1
  h1="$(rv_head "$bare")"
  ahead="$(git -C "$pub" rev-list --count refs/remotes/origin/main..main 2>/dev/null)"
  rv_has "$out" 'discarded its own commit' && claimed=1
  ( unset STATICRYPT_PASSWORD; set -e; cmd_update "$d" ) >/dev/null 2>&1; rc2=$?
  rv_history_has_key "$bare" "$k1" && hist=1
  if [ "$injected" -eq 0 ]; then
    FAIL "$id: the fetch after the update's commit was never reached — the interleaving was not reproduced. VERDICT WITHHELD"
  elif [ "$hist" -eq 1 ]; then
    FAIL "$id: a page under the key the rotation replaced reached the site's history — the update that could not fetch kept its commit, and the next update carried it"
  elif [ "$rc" -ne 1 ] || [ "$claimed" -eq 0 ] || [ "$ahead" != 0 ] || [ "$h0" != "$h1" ]; then
    FAIL "$id: the update that could not fetch after a key change did not stop, take back exactly its own commit and say so (rc=$rc, claimed=$claimed, ahead=$ahead)"
  elif [ "$rc2" -ne 0 ]; then
    FAIL "$id: CONTROL — the next update, with the site reachable, did not complete (rc=$rc2), so the history check above graded nothing"
  else
    PASS "$id: an update that cannot fetch after a rotation recorded a new key takes back its own commit and says so, and the next update publishes no page under the replaced key"
  fi
}
rv29_assert "RV29"

# ── RV30 — review 4's I-5, the write-time guard. rotate proves its key path a regular file before
# committing, and write_passphrase_file checks again at the write, for a directory put in place
# between the two. Nothing graded that second check, so removing it moved no arm. It must refuse,
# record nothing into the directory, and leave the site as it was.
rv30_assert() { # <id>
  local id="$1" name d bare out rc h0 h1 left injected=0 said=0
  local k1='rv-write-time-synthetic-key-41'
  name="rv30-$RANDOM"; d="$(rv_fixture "$name" "$k1")"; bare="$RVW/origin/$name-trip.git"
  h0="$(rv_head "$bare")"
  out="$( ( unset STATICRYPT_PASSWORD; rv30_d="$d"; rv30_mark="$RVW/$name.injected"
            rv30_def="$(declare -f refuse_unpushed_residue)"; eval "rv30_real_rur ${rv30_def#refuse_unpushed_residue}"
            refuse_unpushed_residue() {   # the key path was proven a regular file; THEN a directory takes its place
              rv30_real_rur "$@" || return $?
              if [ ! -e "$rv30_mark" ]; then
                : > "$rv30_mark"
                mv "$rv30_d/.passphrase" "$rv30_d/.passphrase-before"
                mkdir "$rv30_d/.passphrase"
              fi
            }
            set -e; cmd_rotate "$d" ) 2>&1 )"; rc=$?
  [ -e "$RVW/$name.injected" ] && injected=1
  h1="$(rv_head "$bare")"
  left="$(find "$d/.passphrase" -mindepth 1 2>/dev/null)"
  rv_has "$out" 'not a regular file' && said=1
  if [ "$injected" -eq 0 ] || [ ! -d "$d/.passphrase" ]; then
    FAIL "$id: the directory never took the key path's place between the proof and the write — nothing to grade. VERDICT WITHHELD"
  elif [ "$rc" -eq 0 ] || [ -n "$left" ]; then
    FAIL "$id: rotate recorded its key into a directory that replaced .passphrase after the path was proven (rc=$rc) — the write-time check did not hold"
  elif [ "$rc" -ne 1 ] || [ "$said" -eq 0 ]; then
    FAIL "$id: rotate did not refuse the directory at the write, naming it (rc=$rc). VERDICT WITHHELD"
  elif [ "$h0" != "$h1" ]; then
    FAIL "$id: the refusal at the write still changed the site"
  else
    PASS "$id: a directory put in place of .passphrase after rotate proved the path is refused at the write — nothing is recorded into it and the site is as it was"
  fi
}
rv30_assert "RV30"

# ── The MD registrations — each re-runs the SAME argv its live arm ran, with the subject
# removed. RV6 and RV12 were registered above, against the real encrypt_to_tmp.
md_flips cmd_rotate  "RV1"  rv1_assert  "RV1"  set
md_flips cmd_rotate  "RV1c" rv1_assert  "RV1c" unset
md_flips cmd_update  "RV2"  rv2_assert  "RV2"  update
md_flips cmd_publish "RV2c" rv2_assert  "RV2c" publish
md_flips cmd_update  "RV2b" rv2b_assert "RV2b"
for rv_c in env-only file-only agree empty-env; do md_flips cmd_update "RV2d-$rv_c" rv2d_assert "RV2d-$rv_c" "$rv_c"; done
for rv_s in unreadable empty newline-only two-line crlf; do md_flips cmd_update "RV2e-$rv_s" rv2e_assert "RV2e-$rv_s" "$rv_s"; done
for rv_p in floor gate preflight clone encrypt guard commit absent unusable; do md_flips cmd_rotate "RV3-$rv_p" rv3_assert "RV3-$rv_p" "$rv_p"; done
md_flips cmd_rotate  "RV4"  rv4_assert  "RV4"
for rv_f in no-value unknown; do md_flips cmd_rotate "RV5-$rv_f" rv5_assert "RV5-$rv_f" "$rv_f"; done
md_flips cmd_rotate  "RV7"  rv7_assert  "RV7"
md_flips cmd_rotate  "RV8-errexit-off" rv8_assert "RV8-errexit-off" errexit-off
md_flips cmd_rotate  "RV8-or-true"     rv8_assert "RV8-or-true"     or-true
md_flips cmd_rotate  "RV9"  rv9_assert  "RV9"
md_flips cmd_update  "RV10" rv10_assert "RV10"
# RV10b is registered against the discard itself, not the whole command: with it removed the
# update still stops and still says why, so the arm can only fail because the commit stayed.
md_flips discard_own_commit "RV10b" rv10b_assert "RV10b"
# RV13 flips when its verb is gone; RV14 and RV15 are registered against the function each one
# grades, so a PASS can only come from that function having run. RV16's safe outcome is "no
# discard", which any removal also produces, so it is registered against the command it drives.
for rv_v in rotate publish unpublish; do md_flips "cmd_$rv_v" "RV13-$rv_v" rv13_assert "RV13-$rv_v" "$rv_v" eq; done
md_flips cmd_rotate "RV13-rotate-bare" rv13_assert "RV13-rotate-bare" rotate bare
md_flips resolve_key_path "RV14" rv14_assert "RV14"
md_flips refuse_unpushed_residue "RV15" rv15_assert "RV15"
md_flips cmd_update "RV16" rv16_assert "RV16"
# RV17 and RV18 grade what a push publishes, so they are registered against the push itself.
md_flips push_trip_site "RV17" rv17_assert "RV17"
md_flips push_trip_site "RV18" rv18_assert "RV18"
# RV19 and RV23 end safe — no push, no discard — whenever their subject is removed, so like RV16 they
# are registered against the command they drive; the lease and the "already on the remote" test they
# answer to are proven by mutation instead. RV20, RV21, RV22 and RV24 are registered against the
# function each one grades.
md_flips cmd_update "RV19" rv19_assert "RV19"
for rv_c in update rotate; do md_flips require_publish_branch "RV20-$rv_c" rv20_assert "RV20-$rv_c" "$rv_c"; done
for rv_c in empty junk; do md_flips push_trip_site "RV21-$rv_c" rv21_assert "RV21-$rv_c" "$rv_c"; done
for rv_v in rotate publish unpublish update confirm; do md_flips "cmd_$rv_v" "RV13-omitted-$rv_v" rv13o_assert "RV13-omitted-$rv_v" "$rv_v" bare; done
md_flips cmd_rotate "RV13-omitted-rotate-eq" rv13o_assert "RV13-omitted-rotate-eq" rotate eq
md_flips cmd_rotate "RV13-omitted-rooted" rv13o_assert "RV13-omitted-rooted" rotate rooted
md_flips main "RV13-subcommand" rv13s_assert "RV13-subcommand"
for rv_c in missing-dir loop; do md_flips prove_key_path "RV22-$rv_c" rv22_assert "RV22-$rv_c" "$rv_c"; done
md_flips cmd_update "RV23" rv23_assert "RV23"
md_flips refuse_unpushed_residue "RV24" rv24_assert "RV24"
# RV25 and RV26 are registered against the command they drive: the fetch and the rewind guard they
# answer to are proven by mutation. RV27 is registered against the function it grades.
for rv_c in rotate update; do md_flips cmd_update "RV25-$rv_c" rv25_assert "RV25-$rv_c" "$rv_c"; done
md_flips cmd_update "RV26" rv26_assert "RV26"
md_flips prove_key_path "RV27" rv27_assert "RV27"
# RV26-retry and RV28 are registered against the command they drive, as RV25 and RV26 are: the
# restored record and the missing-record refusal they answer to sit inside cmd_update and are proven
# by mutation. RV29 and RV30 are registered against the function whose check each one grades.
md_flips cmd_update "RV26-retry" rv26r_assert "RV26-retry"
md_flips cmd_update "RV28" rv28_assert "RV28"
md_flips require_key_of_record "RV29" rv29_assert "RV29"
md_flips write_passphrase_file "RV30" rv30_assert "RV30"

# Teardown: mocks go; the shimmed production functions are RE-DEFINED from the saved
# definitions, never unset — `unset -f` here would delete the real ones.
unset -f gh npx
eval "$RV_ORIG_ENC"
eval "$RV_ORIG_BOIL"
unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0 \
      GIT_CONFIG_KEY_1 GIT_CONFIG_VALUE_1 GIT_CONFIG_KEY_2 GIT_CONFIG_VALUE_2

# ═════════════════════════════════════════════════════════════════════════════════
# Group RS — the coverage boundary in .github/workflows/publish-guard.yml enumerates
# the groups that run here, and that workflow's closing sentence QUANTIFIES over the
# enumeration: "every in-scope group above ran and passed". Nothing asserted it.
#
# GUARD_STRICT_SKIPS below is a real control and it covers exactly one vanishing mode:
# a group that SKIPS without being declared. A group that is deleted, renamed, or made
# unreachable emits nothing at all — it never skips, so it never reaches that
# comparison. PASS and FAIL did not record their ids until this group needed them;
# only SKIP did. That asymmetry is the defect.
#
# It is not hypothetical. Before this group existed, five always-run groups — PF, R, S,
# T and V — were absent from the boundary: 72 of 177 verdicts, 40.7% of the suite,
# running outside a boundary that claimed to enumerate them. Each of R, S and T arrived
# with a release that could have added its line by hand and did not, which is the
# measurement that says hand-maintenance is the cause rather than the cure.
#
# So the enumeration is PARSED and SET-DIFFED BOTH WAYS rather than read and believed.
# RS1 catches a declared group that stopped emitting; RS2 catches an emitted group that
# was never declared. A one-way check catches one of those and reads green on the other.
#
# The roster deliberately does NOT live in this file. A roster the suite derives from
# itself is the self-referential-validation defect: deleting a group and its roster line
# is then one edit, and the check can never fire. It lives in the workflow, which is
# also where #123 AC 8 requires the coverage boundary to be stated.
#
# RS is pure bash reading a tracked file. It has no legitimate skip, and it must never
# be added to GUARD_EXPECTED_SKIPS — an RS that skipped would be indistinguishable from
# the drift it exists to detect.
#
# What RS deliberately does NOT do: assert a per-group MINIMUM verdict count. That would
# catch a group gutted from 35 assertions to 1, which the roster does not. It is declined
# rather than omitted: the failure modes this group exists for — deletion, rename,
# unreachability — are all zero-verdict conditions the roster already covers, and a
# declared per-group floor churns on every assertion added and, unraised, silently stops
# binding. That is a copy with a decaying assertion behind it — the same defect one level
# down. The only floor that ships is RS0's vacuity guard, which cannot rot.
# ═════════════════════════════════════════════════════════════════════════════════
echo
echo "── Group RS — the workflow's stated coverage boundary, asserted against the run."

RS_WF="$ROOT/.github/workflows/publish-guard.yml"

# ONE grammar, stated here and stated in the file it reads. Inside a boundary block, a
# roster line carries the group id as its leading field at exactly THREE spaces after
# the comment marker; an explanation continues at nine and therefore cannot match. A
# block opens at `# IN SCOPE` or `# OUT OF SCOPE` and closes at the next `# ──` section
# rule, so a roster-shaped line elsewhere in the file is not read as a declaration.
# A group id may be declared in both blocks — J is, because J2/J3 run and J1 does not —
# so the parse dedupes rather than treating the second mention as a new group.
rs_parse() { # <workflow_file> -> space-delimited declared GROUP ids on stdout
  local line inb=0 out=" "
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '# IN SCOPE'*|'# OUT OF SCOPE'*) inb=1; continue ;;
      '# ──'*)                         inb=0 ;;
    esac
    [ "$inb" -eq 1 ] || continue
    [[ "$line" =~ ^\#\ \ \ ([A-Z][A-Za-z0-9]*)([[:space:]]|$) ]] || continue
    case "$out" in *" ${BASH_REMATCH[1]} "*) ;; *) out="$out${BASH_REMATCH[1]} " ;; esac
  done < "$1"
  printf '%s' "${out# }"
}

# An assertion id reduced to its GROUP id — the leading run of capitals. This is the id
# grammar SKIP has always used, taken one step further: `${*%%:*}` yields `PF1`, `C2`,
# `V0-CTL`; the groups are `PF`, `C`, `V`. No second grammar is introduced, because two
# id namespaces that can disagree is exactly the failure this group is about.
rs_group() { [[ "$1" =~ ^([A-Z]+) ]] && printf '%s' "${BASH_REMATCH[1]}"; }

# Set difference: members of <a> absent from <b>, deduped. Used in BOTH directions.
rs_diff() { # <a-set> <b-set> -> space-delimited members of a not in b
  local x out=" "
  # shellcheck disable=SC2086
  for x in $1; do
    case " $2 " in *" $x "*) continue ;; esac
    case "$out"  in *" $x "*) continue ;; esac
    out="$out$x "
  done
  printf '%s' "${out# }"
}

rs_count() { local x n=0; for x in $1; do n=$((n+1)); done; printf '%s' "$n"; }

# The ids this run actually emitted, reduced to groups: SEEN ∪ SKIPPED. The union is
# load-bearing — a group whose only emission is a declared skip still RAN as far as this
# question is concerned, and asking otherwise would duplicate the strict-skip control
# instead of complementing it.
RS_EMITTED=" "
# shellcheck disable=SC2086
for rsid in $SEEN $SKIPPED; do
  rsg="$(rs_group "$rsid")"
  [ -n "$rsg" ] || continue
  case "$RS_EMITTED" in *" $rsg "*) ;; *) RS_EMITTED="$RS_EMITTED$rsg " ;; esac
done
# RS is emitting its own verdicts on the next lines, so it is a member of the emitted set
# by construction — SEEN cannot yet hold a verdict this group has not printed. Added
# explicitly rather than left implicit, because this is what makes RS2 require RS's OWN
# declaration in the roster exactly as it requires every other live group's.
case "$RS_EMITTED" in *" RS "*) ;; *) RS_EMITTED="${RS_EMITTED}RS " ;; esac
RS_EMITTED="${RS_EMITTED# }"

RS_DECLARED=""; RS_READABLE=0
if [ -r "$RS_WF" ]; then RS_READABLE=1; RS_DECLARED="$(rs_parse "$RS_WF")"; fi
RS_NDEC="$(rs_count "$RS_DECLARED")"
RS_NEMIT="$(rs_count "$RS_EMITTED")"

# RS0 runs FIRST and the ordering is what makes every zero below mean something. A parse
# that reads zero ids makes both set-diffs empty and RS1/RS2 pass against nothing — a
# probe failure wearing a pass. Unreadable, zero-parsed and zero-emitted are each a
# FAIL, and only then may the diffs render a verdict. Same rule, same reason, as PF1.
if [ "$RS_READABLE" -ne 1 ]; then
  FAIL "RS0: the coverage boundary at .github/workflows/publish-guard.yml is unreadable, so the verdicts below would cover nothing — a roster that cannot be read is a finding, never a clean scan"
elif [ "$RS_NDEC" -eq 0 ]; then
  FAIL "RS0: the coverage boundary parsed to 0 group ids, so both set-diffs would be empty and would pass against nothing. The grammar is one id per line at three spaces after the comment marker, inside the IN SCOPE / OUT OF SCOPE blocks — either the block moved or the grammar did, and neither verdict below is trustworthy"
elif [ "$RS_NEMIT" -eq 0 ]; then
  FAIL "RS0: this run emitted 0 group ids, so the roster would be compared against an empty run. PASS/FAIL/SKIP record the token before the first colon; if that grammar moved, the comparison is vacuous"
else
  PASS "RS0: the boundary is readable and non-degenerate — ${RS_NDEC} declared group id(s) parsed from .github/workflows/publish-guard.yml, ${RS_NEMIT} emitted by this run. Both arms below are therefore measurements rather than empty scans"

  RS_MISSING="$(rs_diff "$RS_DECLARED" "$RS_EMITTED")"
  if [ -n "$RS_MISSING" ]; then
    FAIL "RS1: declared group(s) emitted no verdict in this run: ${RS_MISSING% } — deleted, renamed or unreachable. A vanished group emits nothing at all, so it never skips and GUARD_STRICT_SKIPS never sees it. Either restore the group or remove its line from the coverage boundary"
  else
    PASS "RS1: all ${RS_NDEC} declared group(s) emitted at least one verdict — no declared group vanished from the run (denominator: ${RS_NEMIT} emitted group ids)"
  fi

  RS_EXTRA="$(rs_diff "$RS_EMITTED" "$RS_DECLARED")"
  if [ -n "$RS_EXTRA" ]; then
    FAIL "RS2: group(s) emitted verdicts but are not declared in the coverage boundary: ${RS_EXTRA% } — they run outside the boundary the workflow's closing sentence quantifies over, so a green check there claims more than it proves. Add one line per id to the IN SCOPE block of .github/workflows/publish-guard.yml, id first at three spaces"
  else
    PASS "RS2: all ${RS_NEMIT} emitted group(s) are declared in the coverage boundary — nothing ran outside it, so the workflow's \"every in-scope group above ran and passed\" is true of this run rather than merely stated"
  fi

  RS_INTER=0
  # shellcheck disable=SC2086
  for rsid in $RS_EMITTED; do
    case " $RS_DECLARED " in *" $rsid "*) RS_INTER=$((RS_INTER+1)) ;; esac
  done
  PASS "RS3: |declared| = ${RS_NDEC}, |emitted| = ${RS_NEMIT}, |declared ∩ emitted| = ${RS_INTER} — the two zeros above are stated against those denominators, not against an unstated one"

  # ── RS4 / RS5 / RS6: the controls on the controls ───────────────────────────────
  # An arm that reports "no difference" is worth exactly as much as the evidence that
  # it CAN report a difference. RS4 and RS5 mutate the two inputs one at a time and
  # require the corresponding arm's predicate to name the mutation; RS6 mutates the
  # FILE and re-parses it, which is the only one of the three that proves the roster is
  # genuinely read from the workflow rather than computed from something already here.
  # Every victim is chosen from live data, so no id is hardcoded and none can rot.
  #
  # Each control grades the DELTA its own mutation caused — the predicate's output over
  # the mutated input, MINUS its output over the real one — never the raw output. The
  # difference matters on exactly the run that matters: when RS1 or RS2 has a genuine
  # finding, a control written as an exact-equality test fails too, and three cascading
  # control failures bury the one real finding the operator needs to read. A control
  # must stay valid whether or not the arm it controls is currently clean.

  RS_V1=""; for rsid in $RS_EMITTED; do RS_V1="$rsid"; break; done
  RS_E4="$(rs_diff "$RS_EMITTED" "$RS_V1")"      # the emitted set with one real group gone
  RS_M4="$(rs_diff "$RS_DECLARED" "$RS_E4")"     # RS1's own predicate, over that
  RS_D4="$(rs_diff "$RS_M4" "$RS_MISSING")"      # what the mutation ADDED to RS1's finding
  if [ "${RS_D4% }" = "$RS_V1" ]; then
    PASS "RS4: CONTROL on RS1 — removing group '${RS_V1}' from the emitted set adds exactly '${RS_V1}' to RS1's finding and nothing else. RS1's verdict above is a measurement: the arm fires when a declared group stops emitting"
  else
    FAIL "RS4: CONTROL on RS1 did not fire as specified — removing '${RS_V1}' from the emitted set added '${RS_D4% }' to RS1's finding rather than '${RS_V1}'. RS1's clean verdict proves nothing until this control fires"
  fi

  RS_X5="$(rs_diff "$RS_EMITTED ZZQ" "$RS_DECLARED")"   # RS2's predicate, with a synthetic id
  RS_D5="$(rs_diff "$RS_X5" "$RS_EXTRA")"               # what the mutation ADDED
  if [ "${RS_D5% }" = "ZZQ" ]; then
    PASS "RS5: CONTROL on RS2 — a synthetic group id 'ZZQ' in the emitted set adds exactly 'ZZQ' to RS2's finding and nothing else. RS2's verdict above is a measurement: the arm fires on an undeclared group"
  else
    FAIL "RS5: CONTROL on RS2 did not fire as specified — a synthetic 'ZZQ' in the emitted set added '${RS_D5% }' to RS2's finding rather than 'ZZQ'. RS2's clean verdict proves nothing until this control fires"
  fi

  # RS6 mutates the workflow FILE. Victim: the first declared id that this run also
  # emitted, so removing its declaration produces a genuine emitted-but-undeclared
  # finding rather than a vacuous one.
  RS_V2=""
  # shellcheck disable=SC2086
  for rsid in $RS_DECLARED; do
    case " $RS_EMITTED " in *" $rsid "*) RS_V2="$rsid"; break ;; esac
  done
  RS_COPY="$WORK/rs-roster-minus-one.yml"
  : > "$RS_COPY"
  while IFS= read -r rsline || [ -n "$rsline" ]; do
    if [[ "$rsline" =~ ^\#\ \ \ ([A-Z][A-Za-z0-9]*)([[:space:]]|$) ]] && [ "${BASH_REMATCH[1]}" = "$RS_V2" ]; then
      continue
    fi
    printf '%s\n' "$rsline" >> "$RS_COPY"
  done < "$RS_WF"
  RS_DEC2="$(rs_parse "$RS_COPY")"
  RS_N2="$(rs_count "$RS_DEC2")"
  RS_X6="$(rs_diff "$RS_EMITTED" "$RS_DEC2")"    # RS2's predicate against the mutated roster
  RS_D6="$(rs_diff "$RS_X6" "$RS_EXTRA")"        # what deleting that one line ADDED
  if [ -z "$RS_V2" ]; then
    FAIL "RS6: CONTROL on the parser could not run — no declared group id was also emitted, which contradicts RS1/RS2 above and means the two sets are not being read from what they claim"
  elif [ "$RS_N2" -ne $((RS_NDEC - 1)) ]; then
    FAIL "RS6: CONTROL on the parser — deleting group '${RS_V2}'s roster line from a copy of the workflow changed the parsed count from ${RS_NDEC} to ${RS_N2}, not to $((RS_NDEC - 1)). The parse is not tracking the file line-for-line, so the declared set above is not the file's"
  elif [ "${RS_D6% }" = "$RS_V2" ]; then
    PASS "RS6: CONTROL on the parser — deleting group '${RS_V2}'s roster line from a COPY of the workflow drops the parsed count ${RS_NDEC} → ${RS_N2} and adds exactly '${RS_V2}' to RS2's finding. The roster is read from the workflow on every run, not derived from this file, so deleting a group and its declaration in one edit cannot pass"
  else
    FAIL "RS6: CONTROL on the parser did not fire as specified — deleting '${RS_V2}'s roster line from a copy of the workflow added '${RS_D6% }' to RS2's finding rather than '${RS_V2}'"
  fi
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
