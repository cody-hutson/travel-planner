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
# Pure-bash tests (A–C2, F, H, I, K, L, Q, U) always run. Identity (D) + unpublish idempotency (J1)
# skip without gh auth. Real-StatiCrypt tests (E, G) skip if npx/staticrypt is unavailable.
# H = --opaque naming (#6) · I = list / date helpers (#25) · J = unpublish / takedown (#7)
# K = trips/ ignore invariant (#254) · L = plaintext content guard (#123)
# Q = analysis/ workspace ignore invariant (same shape as K, lower severity)
# U = people/ person-store ignore invariant (#534) — same shape as K and Q, highest severity.
# K4/Q4 are RULE-level, not state-level: they fail on a deleted negation line, which
# K1/Q1 cannot see because a tracked file bypasses .gitignore altogether.
# L8-L10 grade the publishability DECLARATION: that the class has exactly one home, that
# the guard's verdict follows a change to it, and that an unreadable declaration is
# UNDETERMINED rather than an empty class. L11 pins the reserved-heading suppression —
# both limbs, one of which has no backstop.
# M = published-bytes / stoplist / freshness remediation (#123 A6.5) · N = block-scoped
# conjunctive window (#123 PR-7) · O = the [THIRD-PARTY] class: entry denylist,
# value-granularity mark, real derived-model shape (#123 AC 3).
# R = the change-summary (#550). R1-R5 grade its CONTENT guard (AC 5) —
# verify_summary_content over outputs/change-summary.md, an `internal` artifact
# verify_publishable_content never sees: the clean/HIT/UNDETERMINED triple, the
# RE-DERIVED word floor, and the markdown block sentinel that keeps the conjunctive
# rule scoped. R6 grades the MOVED PREDICATE (AC 1 / AC 4, second remediation) — that
# the placement tuple the emitter spec declares actually detects a same-day time move
# on the shipped witness, that an unchanged re-bake still detects nothing, and that
# time is compared WITHIN the matched key rather than folded into it.
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
if git -C "$HERE/.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then

  # U0-CTL (MUST FIRE) — the instrument, before any verdict is read from it.
  # U4 and U5 both PASS on "not ignored". Nothing in K or Q proves that the
  # --no-index form is capable of returning "ignored" at all, so a form that
  # silently answered "not ignored" for every input would show as two green arms.
  # This arm is the one input that must come back IGNORED.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q --no-index "people/psn-zzzz-probe.md"; then
    PASS "U0-CTL: MUST FIRE — the --no-index form returns IGNORED for a synthetic person record, so U4/U5's NOT-IGNORED verdicts below are measurements rather than a form that cannot say otherwise"
  else
    FAIL "U0-CTL: MUST FIRE — the --no-index form called a synthetic people/<record> NOT ignored; every U arm reading that form is a broken probe and none of their verdicts can be trusted"
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

  # U3 (control arm) — a zero whose control also returns zero is a broken probe.
  if git -C "$HERE/.." -c core.ignorecase=false check-ignore -q "README.md"; then
    FAIL "U3: control arm broken — check-ignore calls the tracked root README.md ignored; U2 is unusable"
  else
    PASS "U3: control arm fires (root README.md not ignored) — U2's verdict is trustworthy"
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
# Every function that must hold ZERO selectors. Two predicates and one projection.
L8_PREDICATES='verify_publishable_content verify_summary_content strip_md_to_text_blocks'
l8absent=""
for l8f in $L8_PREDICATES; do
  declare -f "$l8f" >/dev/null 2>&1 || l8absent="$l8absent$l8f "
done
l8pred=0; l8src=0
while IFS= read -r l8s; do
  [ -n "$l8s" ] || continue
  for l8f in $L8_PREDICATES; do
    l8pred=$(( l8pred + $(declare -f "$l8f" | grep -cF -- "$l8s") ))
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
if [ "$l10emark" -eq 0 ] && [ "$l10ectl" -gt 0 ]; then
  PASS "L10e: the erasure tombstone is not among the $l10ectl declared selectors — a privacy mark that must be published is the exact inverse of a non-publishable selector, and it has not been declared as one"
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
# L12 — EVERY declared field selector on the derived model is actually guarded, and a
# label that merely BEGINS with one is not.
#
# This case names no selector. It reads the field-limb selectors for the model class off
# the declaration through the guard's own accessor and its own constants, so it grades
# whatever § 5.6 says at the moment it runs rather than whatever it said when it was
# written. A row added to the fence is graded by this case on the next run with no edit
# here; a row removed shrinks the denominator instead of silently passing.
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
# The denominator is asserted at two or more so a collapsed selector list cannot pass
# this case vacuously — a zero-length loop would otherwise satisfy every equality below.
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
if [ "$l12n" -ge 2 ] && [ "$l12hit" -eq "$l12n" ] && [ "$l12named" -eq "$l12n" ]; then
  PASS "L12: all $l12n declared field selectors on the model class abort the publish (rc=1) and name member + selector without echoing the value — the case reads the selectors off the declaration and hardcodes none"
else
  FAIL "L12: a declared field selector was not guarded (selectors=$l12n aborted=$l12hit named=$l12named) — either the class is narrower than the declaration or the probe read no selectors at all"
fi
if [ "$l12n" -ge 2 ] && [ "$l12open" -eq "$l12n" ]; then
  PASS "L12b: for all $l12n selectors, the identical value under a label that merely BEGINS with the selector publishes (rc=0) — field_hit is prefix-then-colon, so a longer label is UNGUARDED. Measured, and the reason a new requirement set owes its own declared selector rather than a longer label over an existing one"
else
  FAIL "L12b: the prefix-then-colon shape changed (selectors=$l12n published=$l12open) — re-read field_hit before trusting L12's verdict or any claim that a longer label is covered"
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
# THE STORE IS AT THE TRIP ROOT, DELIBERATELY. Store-root resolution is trip-root-first,
# so this fixture is self-contained. A fixture that fell through to the repo-root store
# would be RESOLVED on an author's machine and DANGLING in CI, because that directory is
# git-ignored and absent from a clean checkout — a witness whose verdict depends on the
# operator's private working directory is not a witness. It therefore depends on no
# tracked example fixture either.
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


# ── Group R, second remediation (#550 AC 1 / AC 4) — MOVED sees a same-day TIME move ──
#
# R1–R5 grade what a summary may CARRY (AC 5). R6 grades what decides whether a summary
# is written at all: the MOVED predicate. Stage 7 found it comparing `(day, role)` — the
# venue matrix's placement tuple — while the field a re-timed event actually changes, the
# clock time, sat in no structured source. A dinner moving 19:00 to 20:00 on the same day
# produced no row; and because the no-op rule (AC 4) suppresses a summary whose difference
# is empty, a re-bake whose ONLY change was that move published silently. AC 1's "what
# moved" failed and AC 4 inverted — the rule that exists to suppress noise suppressed the
# signal.
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
#   R6a  the Step-2 before-map for event-status HOLDS a time  (control: it holds status)
#   R6b  the C13 header carries `Time` in BOTH of its homes, and they agree
#   R6c  REGRESSION — a same-day time-only move yields exactly one MOVED row
#   R6d  CONTROL for R6c — an unmutated re-bake yields zero (AC 4's no-op rule, intact)
#   R6e  the moved key is on BOTH sides — MOVED, not DROPPED + ADDED
#   R6f  SENSITIVITY for R6e — a KEY mutation does report DROPPED + ADDED, 0 MOVED
#
# Offline: three tracked files and awk. No network, no gh, no Node, no TTY. This group has
# no legitimate skip and is deliberately NOT declared in GUARD_EXPECTED_SKIPS.
echo
echo "MOVED sees a same-day time move (#550 AC 1 / AC 4, second remediation):"

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

# The C13 table header, one column per line, from whichever of its two homes is asked.
r6_c13_cols() { # <file>
  awk '/^\|[[:space:]]*Event ID[[:space:]]*\|/ {
         n = split($0, f, "|")
         for (i = 2; i < n; i++) { c = f[i]; gsub(/^[ \t]+|[ \t]+$/, "", c); print c }
         exit
       }' "$1"
}

# Project the event table to <key TAB placement> using the field names the CONTRACT gave.
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

# The keyed set difference, computed exactly as the bucket table states it.
r6_diff() { # <before-projection> <after-projection> <ADDED|DROPPED|MOVED>
  awk -F'\t' -v want="$3" '
    NR == FNR { b[$1] = $2; seenb[$1] = 1; next }
    { a[$1] = $2; seena[$1] = 1 }
    END {
      for (k in seena) {
        if (!(k in seenb)) { if (want == "ADDED") print k; continue }
        if (b[k] != a[k] && want == "MOVED") print k
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
#   S8   rotate inherits the gate through cmd_update             (no rotate exemption)
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
  PASS "S8b: rotate on an unconfirmed itinerary change ABORTS (rc=$S_RC8A) and never clones the per-trip repo — the gate is inherited through cmd_update and fires before any network effect"
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
S11_MSG_NOPERL="$( ( PATH=/nonexistent/s11-no-perl; preflight ) 2>&1 >/dev/null )"; S11_RC_NOPERL=$?
S11_MSG_PERL="$( ( preflight ) 2>&1 >/dev/null )";                                  S11_RC_PERL=$?
unset -f gh npx
case "$S11_MSG_NOPERL" in *perl*) S11_NAMES_PERL=1 ;; *) S11_NAMES_PERL=0 ;; esac
if [ "$S11_RC_PERL" -eq 0 ] && [ "$S11_RC_NOPERL" -ne 0 ] && [ "$S11_NAMES_PERL" -eq 1 ]; then
  PASS "S11g: preflight passes with perl present (rc=$S11_RC_PERL, the control, so the stubs are not refusing everything) and ABORTS naming perl when it is absent (rc=$S11_RC_NOPERL) — the dependency fails early and by name, before any clone, encryption or push"
else
  FAIL "S11g: control rc=$S11_RC_PERL, stripped-PATH rc=$S11_RC_NOPERL, message names perl=$S11_NAMES_PERL (message: ${S11_MSG_NOPERL:-none}) — preflight does not probe perl, so its absence is discovered mid-run as a projection that answers differently rather than up front as a missing dependency"
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
# .claude/commands/trip.md, from a spec. So T3 grades a render built TO the contract,
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
# the state comes from and names the `site` verb in .claude/commands/trip.md as the one
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
T_TRIPMD="$HERE/../.claude/commands/trip.md"
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
# state comes from and names the `site` verb in .claude/commands/trip.md as the one home. So
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
# BOTH declared lines of that record are read: `digest=` decides whether the record counts
# as an approval at all — through the shipped parser, so a record present but saying nothing
# is not one (ADR-007 § 2's placeholder bound, the property S5 grades on the gate's side of
# the same file) — and `confirmed=` supplies the moment every entry is measured against.
t6_state() { # <trip_dir> <state-record-path> -> none|pending|updated
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
# coordinated anything. So the three arms above grade the mapping's three limbs on a
# trip with no history, and say nothing about the one state a trip WITH history has to
# be able to return to.
#
# WHY THAT MATTERS TO AC 5. T3 asserts the null-case render is BYTE-IDENTICAL to a
# pre-component render, and § 3 makes non-emission a byte-level property because the site
# is encrypted wholesale. But T3 grades what `none` DOES; nothing graded how a trip that
# has coordinated once ever REACHES it again. .claude/commands/trip.md answers that in
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

# coordination-state as the BUILD writes it: t6_state's three limbs, then the prune on the
# `updated` limb alone. Generic over the record, the window and the null-state token, all
# three of which come from the documents rather than from this file.
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
