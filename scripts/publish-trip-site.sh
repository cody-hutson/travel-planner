#!/usr/bin/env bash
#
# publish-trip-site.sh — private-by-default publishing for travel-planner trip sites.
#
# Encrypts a generated trip site with StatiCrypt (AES-256-CBC + HMAC-SHA256,
# 600k PBKDF2-SHA256) and publishes ONLY the ciphertext to a per-trip PUBLIC repo
# with GitHub Pages.
# The plaintext itinerary never leaves the git-ignored trips/ working dir, and is
# never written to the per-trip repo or its history. Because each trip is a fresh
# repo, privacy is by construction.
#
# Security model (be honest about it): the published artifact is world-fetchable
# ciphertext. Anyone can download it and attempt an OFFLINE brute force. The privacy
# guarantee therefore reduces to passphrase strength x KDF cost (600k iterations,
# fixed by StatiCrypt). This is "secret-gated", not "access-controlled". Use a strong
# passphrase and share it over a private channel.
#
# Usage:
#   publish-trip-site.sh publish   <trip-dir> [--plaintext] [--opaque]
#   publish-trip-site.sh update    <trip-dir>
#   publish-trip-site.sh confirm   <trip-dir>   (interactive; records the organizer's approval of an itinerary change)
#   publish-trip-site.sh rotate    <trip-dir> [--passphrase <new>]
#   publish-trip-site.sh list                       (read-only inventory of all trips under trips/; gh optional)
#   publish-trip-site.sh unpublish <trip-dir> [--disable-pages-only] [--yes]
#
#   <trip-dir>     A trip working dir, e.g. trips/tokyo-2026 (contains outputs/<name>-travel-site.html)
#   --plaintext    Opt OUT of privacy: publish the unencrypted site (default is encrypted).
#   --opaque       Name the per-trip repo opaquely (random slug — no destination/year); persisted to .publish-slug.
#   --passphrase   Supply a specific new passphrase for rotate (else one is generated).
#   --disable-pages-only   unpublish: take the site offline but KEEP the repo (reversible). Default DELETES the repo.
#   --yes          unpublish: skip the interactive confirmation (required for a non-interactive delete).
#
# Organizer-confirm gate (ADR-003 § Decision 2). update refuses when the itinerary content
# of the outgoing render differs from what is currently published and no organizer
# confirmation covers it; rotate republishes through update and inherits the refusal. A
# republish carrying the SAME itinerary content — a coordination-state marker change, say —
# is not a plan change and passes. Record the approval with `confirm` (terminal only, no
# override flag); it binds to that exact itinerary content, so a later edit re-opens the gate.
#
# Passphrase resolution (in order): $STATICRYPT_PASSWORD, then <trip-dir>/.passphrase,
# else a strong one is generated and saved to <trip-dir>/.passphrase (git-ignored, chmod 600).
#
# Repo slug resolution (in order): <trip-dir>/.publish-slug, else the convention
# <destination>-<year>-trip. Drop a repo name in .publish-slug to publish to a custom or
# pre-existing repo instead of the derived one (resolved identically by every subcommand).
# --opaque generates such a name for you (a random slug) and saves it there on first publish.
#
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Output helpers
# ─────────────────────────────────────────────────────────────────────────────
info() { printf '\033[1;34m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m✗ ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# Preflight — required tooling
# ─────────────────────────────────────────────────────────────────────────────
# Read-only preflight — gh only (no publish tooling). Used by list / unpublish.
preflight_ro() {
  command -v gh  >/dev/null 2>&1 || die "gh (GitHub CLI) not found."
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"
}

preflight() {
  command -v npx  >/dev/null 2>&1 || die "npx not found (install Node.js — StatiCrypt runs via npx)."
  # perl is not optional on the publish paths, and it is probed HERE so that its absence
  # is an early, named, actionable failure rather than a projection that quietly answers
  # differently mid-run. Every verdict this file reaches about the CONTENT of a render is
  # computed from a perl text projection — strip_to_text (verify_ciphertext),
  # strip_to_published_text (verify_publishable_content) and strip_to_itinerary_text (the
  # #552 organizer-confirm gate). The last of the three has no equivalent expressible in
  # sed, so there is nothing to degrade to; see the note above strip_to_itinerary_text.
  # cmd_update calls this BEFORE it resolves the render and before the gate runs, so on a
  # machine without perl the operator is told to install perl instead of being told, by
  # the gate itself, that an itinerary changed which did not.
  command -v perl >/dev/null 2>&1 || die "perl not found — this script derives every content verdict (the ciphertext guard, the publishable-content guard, and the organizer-confirm gate) from perl text projections. Install perl and re-run."
  preflight_ro
}

# ─────────────────────────────────────────────────────────────────────────────
# No-reply commit identity — never leak a real email into a public per-trip repo.
# Derives the canonical GitHub no-reply address: <id>+<login>@users.noreply.github.com
# ─────────────────────────────────────────────────────────────────────────────
NOREPLY_NAME=""
NOREPLY_EMAIL=""
resolve_noreply_identity() {
  local login id
  login=$(gh api user --jq '.login') || die "could not read GitHub user."
  id=$(gh api user --jq '.id')        || die "could not read GitHub user id."
  NOREPLY_NAME="$login"
  NOREPLY_EMAIL="${id}+${login}@users.noreply.github.com"
}

commit_noreply() { # <repo_dir> <message>
  local repo_dir="$1" msg="$2"
  # Identity is set via BOTH -c config AND the GIT_* env vars. The env vars take
  # PRECEDENCE over -c, so a hostile GIT_AUTHOR_EMAIL / GIT_COMMITTER_EMAIL already
  # in the environment cannot override the no-reply identity into a public repo.
  GIT_AUTHOR_NAME="$NOREPLY_NAME"    GIT_AUTHOR_EMAIL="$NOREPLY_EMAIL" \
  GIT_COMMITTER_NAME="$NOREPLY_NAME" GIT_COMMITTER_EMAIL="$NOREPLY_EMAIL" \
  git -C "$repo_dir" -c "user.name=${NOREPLY_NAME}" -c "user.email=${NOREPLY_EMAIL}" \
    commit --quiet -m "$msg"
}

# ─────────────────────────────────────────────────────────────────────────────
# Passphrase generation and resolution.
# NOTE: With KDF iterations fixed at 600k, passphrase entropy IS the security margin.
# Default = 6 word list words chosen with a CSPRNG (/dev/urandom), ~14 bits/word from a
# ~25k-word list ≈ 88 bits. Falls back to 48 hex chars (192 bits) with no word list.
# Override the policy here if you want longer/stronger passphrases.
# ─────────────────────────────────────────────────────────────────────────────
gen_passphrase() {
  local wl=/usr/share/dict/words n idx out="" tmp
  if [ -r "$wl" ]; then
    tmp=$(mktemp)
    LC_ALL=C grep -E '^[a-z]{4,8}$' "$wl" > "$tmp" 2>/dev/null || true
    n=$(wc -l < "$tmp"); n=${n//[^0-9]/}
    if [ "${n:-0}" -ge 2000 ]; then
      for _ in 1 2 3 4 5 6; do
        # Uniform-ish CSPRNG index: 4 random bytes from /dev/urandom, mod n.
        idx=$(( $(od -An -N4 -tu4 < /dev/urandom | tr -d ' ') % n + 1 ))
        out="${out:+$out-}$(sed -n "${idx}p" "$tmp")"
      done
      rm -f "$tmp"; printf '%s' "$out"; return
    fi
    rm -f "$tmp"
  fi
  # Fallback: 48 hex chars (192 bits) straight from the CSPRNG.
  od -An -N24 -tx1 /dev/urandom | tr -dc 'a-f0-9'
}

get_passphrase() { # <trip_dir> <force_new:0|1>
  local trip_dir="$1" force_new="${2:-0}" pf="$1/.passphrase" p=""
  if [ "$force_new" = "1" ]; then
    # Rotation: always generate a fresh one and persist it — ignore any env override.
    p="$(gen_passphrase)"; printf '%s\n' "$p" > "$pf"; chmod 600 "$pf"
  elif [ -n "${STATICRYPT_PASSWORD:-}" ]; then
    p="$STATICRYPT_PASSWORD"
  elif [ -r "$pf" ]; then
    p="$(cat "$pf")"
  else
    p="$(gen_passphrase)"; printf '%s\n' "$p" > "$pf"; chmod 600 "$pf"
  fi
  [ "${#p}" -ge 12 ] || die "passphrase too weak (need ≥12 chars for a public, brute-forceable ciphertext) — unset STATICRYPT_PASSWORD to auto-generate a strong one, or fix $pf"
  printf '%s' "$p"
}

# ─────────────────────────────────────────────────────────────────────────────
# Locate the trip's generated site HTML and derive the per-trip repo slug.
# ─────────────────────────────────────────────────────────────────────────────
resolve_site_html() { # <trip_dir>
  local trip_dir="$1" hit
  hit=$(ls -1t "$trip_dir"/outputs/*-travel-site.html 2>/dev/null | head -1 || true)
  [ -n "$hit" ] || die "no *-travel-site.html found in $trip_dir/outputs/ — build the site first."
  printf '%s' "$hit"
}

# Repo slug resolution (in order): <trip-dir>/.publish-slug, else the convention
# <basename>-trip. A .publish-slug file lets a convention-named trip dir publish to a
# custom or pre-existing repo name (e.g. trips/tokyo-2026 -> tokyo-trip) instead of the
# derived one. The slug names a PUBLIC repo, so it is not secret; it lives in the
# git-ignored trips/ tree regardless. Resolved identically by publish/update/rotate.
slug_for() { # <trip_dir>
  local trip_dir="$1" sf="$1/.publish-slug" slug
  if [ -s "$sf" ]; then
    slug="$(tr -d '[:space:]' < "$sf")"
  else
    slug="$(basename "$trip_dir")-trip"
  fi
  case "$slug" in
    ''|*[!A-Za-z0-9._-]*) die "invalid publish slug '$slug' — allowed chars: A-Z a-z 0-9 . _ - (fix ${sf} or remove it to use the default '<dir>-trip')" ;;
  esac
  printf '%s' "$slug"
}

# --opaque: give the per-trip repo a name that leaks neither destination nor year.
# Generates a random slug ONCE and persists it to .publish-slug (the file slug_for()
# resolves first), so publish/update/rotate all converge on the same repo. A pre-existing
# .publish-slug always wins — --opaque never overwrites a name the user already chose.
ensure_opaque_slug() { # <trip_dir>
  local trip_dir="$1" sf="$1/.publish-slug" tok
  if [ -s "$sf" ]; then
    info "opaque: .publish-slug already set ('$(tr -d '[:space:]' < "$sf")') — keeping it."
    return
  fi
  tok="trip-$(od -An -N5 -tx1 /dev/urandom | tr -dc 'a-f0-9')"
  printf '%s\n' "$tok" > "$sf"
  ok "opaque: per-trip repo will be '$tok' (saved to $sf — reused by update/rotate)."
}

# ─────────────────────────────────────────────────────────────────────────────
# Encrypt the site into a fresh temp dir; echo that dir. Output file: <dir>/index.html
# ─────────────────────────────────────────────────────────────────────────────
encrypt_to_tmp() { # <src_html> <passphrase>
  local src_html="$1" passphrase="$2" stage enc log
  stage=$(mktemp -d); enc=$(mktemp -d); log=$(mktemp)
  cp "$src_html" "$stage/index.html"
  if ! ( cd "$stage" && STATICRYPT_PASSWORD="$passphrase" \
        npx --yes staticrypt@3.5.4 index.html --short --config false -d "$enc" ) >"$log" 2>&1; then
    warn "staticrypt failed:"; sed 's/^/    /' "$log" >&2
    rm -rf "$stage" "$enc"; rm -f "$log"; die "encryption step failed."
  fi
  if [ ! -f "$enc/index.html" ]; then
    rm -rf "$stage" "$enc"; rm -f "$log"; die "encryption produced no $enc/index.html"
  fi
  rm -rf "$stage"; rm -f "$log"   # plaintext copy + log removed; only ciphertext (enc) remains
  printf '%s' "$enc"
}

# Visible text of an HTML file — markup and <script>/<style> blocks removed.
# Used so the guard derives leak-tokens from itinerary *content*, not shared markup.
strip_to_text() { # <html_file> -> visible text on stdout
  perl -0777 -pe 's/<(script|style)\b[^>]*>.*?<\/\1>//gis; s/<[^>]+>/ /g' "$1" 2>/dev/null \
    || sed -E 's/<[^>]*>/ /g' "$1"
}

# Everything a reader can retrieve from the PUBLISHED FILE that is not markup machinery:
# visible text, HTML comment BODIES, every attribute VALUE, and <script>/<style> BODIES.
# strip_to_text above is the VISIBLE projection and is deliberately left byte-for-byte as
# it was — verify_ciphertext consumes it, and AC 5 holds that function's behaviour fixed.
#
# Why a second projection exists at all: cmd_publish copies the WHOLE FILE, so the whole
# file is the evaluand, and strip_to_text is not it. strip_to_text deletes script/style
# bodies wholesale and turns every tag into a space, which discards comments and every
# attribute value. Measured on the shipped guard, a class value carried ONLY in an HTML
# comment, a meta description, an img alt, an inline script, an aria-label, a style
# comment or a data-* attribute published at rc=0 — 7 of the 8 surfaces tried. (The
# eighth, <title>, is visible text and was already caught; the review's 8/8 is 7/8.)
# Two of the seven, the img alt and the meta description, are read out by assistive
# technology and by every link preview, so they are not even "hidden".
#
# This is verify_ciphertext check (d)'s idiom — that check greps the RAW BYTES precisely
# because the visible projection is not what gets published — carried across to a content
# predicate. (d) needs boilerplate subtraction because StatiCrypt's shell shares ordinary
# vocabulary with an itinerary; make_boilerplate builds a CONTENT-FREE artifact from the
# same build and (d) skips any token found in it. This repo has no site build to run a
# decoy through — the site is authored per trip — so the same subtraction is made
# STRUCTURALLY instead: tag names and attribute NAMES are the entire machinery vocabulary
# and the only part of the file guaranteed to carry no trip content, so they are dropped
# at extraction rather than differenced away afterwards. Same mitigation, same reason,
# obtained without a decoy that cannot be built here.
strip_to_published_text() { # <html_file> -> retrievable non-machinery content on stdout
  perl -0777 -pe "
    s/<!DOCTYPE[^>]*>/ /gi;                            # the doctype is machinery
    s/<!--/ /g; s/-->/ /g;                             # drop the delimiters, KEEP the body
    s/<\s*\/?\s*($_GUARD_BLOCK_TAGS)\b/ $_GUARD_BLOCK /gi;   # block boundary, before tag names go
    s/<\s*\/?\s*([A-Za-z][-A-Za-z0-9]*)/ /g;           # the tag NAME (with its \"<\") is machinery
    s/([-A-Za-z_:][-A-Za-z0-9_:.]*)\s*=\s*/ /g;        # the attribute NAME is machinery; its VALUE stays
  " "$1" 2>/dev/null
}

# The VISIBLE projection, block-sentinelled. Byte-identical in outcome to strip_to_text
# except that a block-level tag leaves a sentinel where it left a space, and the matcher
# drops the sentinel from the token stream — so the visible arm sees exactly the tokens it
# always saw, plus the knowledge of where one block ended. strip_to_text itself is NOT
# touched: verify_ciphertext consumes it and AC 5 fixes that behaviour.
strip_to_text_blocks() { # <html_file> -> visible text with block sentinels on stdout
  perl -0777 -pe "
    s/<(script|style)\b[^>]*>.*?<\/\1>//gis;
    s/<\s*\/?\s*($_GUARD_BLOCK_TAGS)\b[^>]*>/ $_GUARD_BLOCK /gi;
    s/<[^>]+>/ /g;
  " "$1" 2>/dev/null || sed -E 's/<[^>]*>/ /g' "$1"
}

# StatiCrypt boilerplate reference — encrypt a token-LESS decoy so the guard can tell
# StatiCrypt's fixed shell vocabulary (already, center, click, password…) apart from a
# genuine itinerary leak. The readable boilerplate is passphrase-independent; only the tiny
# decoy ciphertext blob varies, so coincidental token matches are negligible. Echoes a temp
# dir whose index.html is the decoy output; the caller removes it.
make_boilerplate() { # -> echoes temp dir (boilerplate = <dir>/index.html)
  local d enc
  d="$(mktemp -d)"
  printf '<!DOCTYPE html><html><head><title>x</title></head><body>trip</body></html>' > "$d/src.html"
  enc="$(encrypt_to_tmp "$d/src.html" "staticrypt-boilerplate-decoy-passphrase")"
  rm -rf "$d"
  printf '%s' "$enc"
}

# ─────────────────────────────────────────────────────────────────────────────
# PLAINTEXT CONTENT GUARD (#123) — the second pre-push predicate.
#
# verify_ciphertext (below) answers "is this encrypted?". It cannot answer "is this
# safe to publish?": every one of its checks inverts on plaintext input, so wiring it
# into the plaintext limb would abort every plaintext publish rather than guard it.
# The plaintext limb therefore gets its own predicate here. verify_ciphertext is
# unchanged and still guards the encrypted limb of publish and all of update.
#
# The class of non-publishable content has ONE home: nonpublishable_values(). The
# predicate is a pure consumer of the records that function emits and holds no
# knowledge of what the class IS — so re-keying the class to a declared publishability
# attribute later (#278) is a change to one function body, not a rewrite.
#
# COVERAGE BOUNDARY, stated rather than implied. A value that reaches the render
# DE-ATTRIBUTED — the traveler name stripped — is caught, by construction: the name
# was never the join key, so removing it changes nothing. A value the hub REWORDED on
# its way into the render is NOT caught; detecting a paraphrase is a judgement no
# string match can make. This layer does not subsume the validator profile-privacy
# audit, which reads the five publish-bound SOURCES and judges; this guard reads the
# RENDER and matches. Both are needed. Full rationale + rejected alternatives:
# reference/adr/ADR-008-publish-content-guard.md.
# ─────────────────────────────────────────────────────────────────────────────

# Match parameters. Both are load-bearing and were chosen on a measured sweep rather
# than by taste (design record: sub-task #315):
#   GUARD_NGRAM  = 5  — at 3 an incidental three-word run aborts a clean render; at 6
#                       and above a real five-word carry-through is missed. 4 and 5
#                       both discriminate; 5 is the tighter of the two.
#   GUARD_WINDOW = 25 — unbounded (or 200+) an innocent render that mentions one token
#                       early and the other late FLIPS to a false abort; 50 and below
#                       does not. The window is what makes the conjunctive rule safe.
GUARD_NGRAM=5
GUARD_WINDOW=25

# The conjunctive window is scoped to ONE STRUCTURAL BLOCK as well as to W words.
# W=25 alone was calibrated on a fixture carrying one occurrence of each token, and a
# real itinerary repeats both: measured, `Passport: Irish, valid to 2027` against a clean
# multi-day render that mentions an Irish pub each day under 2027 date headings aborts
# from TWO DAYS onward and never recovers, while the same render with a 2033 validity
# publishes — so the cause is token recurrence across day boundaries, not a real
# carry-through. A flat word window cannot tell "both facts in one sentence" from "one
# fact at the end of Tuesday and the other in Wednesday's heading". A block boundary can.
#
# The sentinel is an ordinary-looking lowercase token because _norm_words keeps only
# [a-z0-9] and anything else would be filtered out before the matcher saw it. If a render
# ever contained this literal string it would split a block that should not have split —
# which narrows matching rather than widening it, so the failure direction is a missed
# match, not a false abort. Both are stated in ADR-008.
_GUARD_BLOCK='zzguardblockzz'
_GUARD_BLOCK_TAGS='p|div|h[1-6]|li|tr|td|th|dt|dd|section|article|header|footer|aside|nav|main|ul|ol|dl|table|blockquote|figure|figcaption|br|hr|form|fieldset|pre'

# Non-distinctive vocabulary, subtracted before a value is used as a key: articles,
# prepositions, auxiliaries, and the structural words a document-field value is written
# with. Requiring these would key on grammar rather than on the traveler value.
# This is NORMALIZATION vocabulary — it decides nothing about MEMBERSHIP, which is
# nonpublishable_values()'s job alone.
# Kept on ONE line by concatenation, deliberately: awk -v rejects a newline inside an
# assignment value on the BSD/macOS awk, and a stoplist that silently kills the matcher
# is a fail-closed guard that never actually matches anything.
_GUARD_STOP=' a an and any are as at be been being but by can cannot could did do does '\
'for from good had has have he her hers him his i if in into is it its me more most my '\
'no nor not of on or our ours out she so some such than that the their theirs them then '\
'there these they this those through thru till to too until up us valid validity valids '\
'was we were what when where which while who whom will with would you your yours '\
'passport passports document documents expire expired expires expiring expiry issue '\
'issued issuing issuance date dates day days month months year years number numbers '

# Shared normalization — ONE definition, used on BOTH sides of every comparison.
# stdin -> one lowercase [a-z0-9] token per line. Inlining this twice is exactly how
# the two sides drift apart, so it is a function and both sides call it.
_norm_words() {
  LC_ALL=C tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sed -e 's/[^a-z0-9]/ /g' -e 's/  */ /g' \
    | LC_ALL=C tr ' ' '\n' \
    | sed '/^$/d'
}

# _guard_match <rule> <value_tokens_file> <render_tokens_file>
#   exit 0  the value matched the render under <rule>          (a HIT)
#        1  no match
#        3  the value is below <rule>'s keyability floor — UNDETERMINED, never a pass
#        4  DECLARED NON-KEY — the value carries no distinctive token at all (token rule
#           only). Not a hit and NOT undetermined: a deliberate, bounded fail-open.
#   any other exit is the matcher itself failing, which the caller also treats as
#   UNDETERMINED. 3 rather than 2 on purpose: awk exits 2 on its OWN program error, and
#   a broken matcher must not be reported to the operator as "your value is too short".
#
# RESIDUAL, stated next to the paraphrase residual above and repeated in ADR-008.
# Exit 4 is a fail-open, and it reaches BOTH ARMS of the [THIRD-PARTY] member — the
# name and the need text alike. Within THIS matcher it is emitted from the `token` rule
# and from nowhere else, so its real scope is exactly the set of records
# nonpublishable_values assigns that rule to, and that set is two things:
#   • The NAME arm, ALWAYS. An entry name is emitted as `token` unconditionally, so a
#     member whose name is made only of stoplisted words is a declared non-key and
#     their name reaching the render is not caught by this guard.
#   • The VALUE arm, whenever the stated value is SHORTER THAN GUARD_NGRAM (5) tokens.
#     The rule assignment below picks `token` under that floor, so a short need value
#     with no distinctive token in it — `Timing: not on the day`, `Specific: no more
#     than most` — is a declared non-key too, and the need text reaching the render is
#     not caught either. An earlier revision of this note claimed the value arm was
#     untouched. That was true only while the third-party value rule was a hard-coded
#     `phrase`, which has no exit-4 path; the entry-denylist change replaced it with
#     the word-count choice, and that is what extended exit 4 to the value arm. State
#     it as the cost it is: `phrase` on a four-word value exits 3, and a sub-floor
#     UNDETERMINED aborts every publish of that trip forever, with no remedy — the same
#     unusable fail-closed control the token-branch note argues against. This buys that
#     back at the price of a wider fail-open, deliberately.
# What exit 4 does NOT reach, equally worth knowing:
#   • The PASSPORT member. It is always matched under `conjunctive`, which has no
#     exit-4 path — under two distinctive tokens is exit 3, UNDETERMINED, and aborts.
#     Exit 4 is a [THIRD-PARTY]-only fail-open.
#   • A third-party value of 5 tokens or more. That takes `phrase`, which has no exit-4
#     path either; its all-stopword windows are skipped and it ends at 1, not 4.
# Do not confuse any of this with the unrelated `exit 4` in the model-parse awk inside
# nonpublishable_values: that one is the orphaned-mark backstop and means UNDETERMINED,
# the opposite polarity. Same digit, different program, different contract.
# Layers 1 and 3 still cover everything exit 4 lets through. And _GUARD_STOP is
# NORMALIZATION vocabulary, not a list of names: it is not extended here, so May, Art,
# Grace and Rosa still key and can still over-block; only words already inside the
# stoplist (Will) become non-keys. The general problem — an ordinary-word name, or a
# short value written entirely in ordinary words — is narrowed, not solved.
#
# Per-member-class matching is deliberate, and a uniform word-count floor is the
# design error it exists to avoid: reference/data-model.md defines a passport value as
# "country + validity only — never a number", which is 2-5 words by construction, so a
# single floor across the whole class would make EVERY plaintext publish undetermined
# forever. The rule travels with the record; this function only applies it, and knows
# nothing about which class member produced it.
_guard_match() { # <rule> <value_tokens_file> <render_tokens_file>
  awk -v rule="$1" -v vfname="$2" -v W="$GUARD_WINDOW" -v F="$GUARD_NGRAM" -v STOP="$_GUARD_STOP" -v BLOCK="$_GUARD_BLOCK" '
    function is_stop(t) { return index(STOP, " " t " ") > 0 }
    BEGIN {
      gsub(/[ \t\n\r]+/, " ", STOP)
      if (substr(STOP, 1, 1) != " ") STOP = " " STOP
      if (substr(STOP, length(STOP), 1) != " ") STOP = STOP " "
      blkid = 0
    }
    FILENAME == vfname { v[++vn] = $0; next }
    # Block sentinels advance the block counter and are DROPPED from the token stream, so
    # rn, the phrase rule and the token rule see exactly the stream they saw before this
    # existed. Only the conjunctive rule reads blk[].
    $0 == BLOCK        { blkid++; next }
                       { r[++rn] = $0; blk[rn] = blkid }
    END {
      if (rn == 0) exit 3
      if (rule == "conjunctive") {
        # Every distinctive token of the value must appear, and the occurrences must
        # fall inside one W-word window. This is a direct encoding of the class
        # definition ("issuing country AND validity" — two facts), and it is strictly
        # more sensitive here than n-gram containment: it catches a reworded or
        # order-swapped carry-through that no contiguous run would match.
        k = 0
        for (i = 1; i <= vn; i++) {
          t = v[i]
          if (is_stop(t)) continue
          if (t in seen) continue
          seen[t] = 1; k++; key[k] = t; kidx[t] = k
        }
        if (k < 2) exit 3
        m = 0
        for (p = 1; p <= rn; p++) if (r[p] in kidx) { m++; pos[m] = p; who[m] = kidx[r[p]] }
        if (m < k) exit 1
        left = 1; covered = 0
        for (right = 1; right <= m; right++) {
          cnt[who[right]]++
          if (cnt[who[right]] == 1) covered++
          while (covered == k) {
            # Same block AND inside W. blk[] is non-decreasing, so equal endpoints mean
            # every token between them is in that block too. This is what separates
            # "both facts in one sentence" from "one fact per day, N days apart".
            if (pos[right] - pos[left] <= W && blk[pos[right]] == blk[pos[left]]) exit 0
            cnt[who[left]]--
            if (cnt[who[left]] == 0) covered--
            left++
          }
        }
        exit 1
      }
      if (rule == "phrase") {
        # Contiguous F-word containment. Catches the verbatim and the de-attributed
        # form; the floor bounds how small a partial carry-through may be and still
        # count as a key. A pure-stopword window is not a key.
        if (vn < F) exit 3
        for (s = 1; s + F - 1 <= vn; s++) {
          allstop = 1
          for (j = 0; j < F; j++) if (!is_stop(v[s + j])) { allstop = 0; break }
          if (allstop) continue
          for (p = 1; p + F - 1 <= rn; p++) {
            ok = 1
            for (j = 0; j < F; j++) if (r[p + j] != v[s + j]) { ok = 0; break }
            if (ok) exit 0
          }
        }
        exit 1
      }
      if (rule == "token") {
        # Whole-word match on the normalized stream. is_stop is applied HERE too, as the
        # two sibling branches already do — its absence was a defect, not a design.
        # Without it a third-party member named with an ordinary English word keys on
        # grammar: "will" already sits in _GUARD_STOP above, so a member named Will made
        # EVERY publish of that trip abort, forever, with no remedy available to the
        # operator — the entry cannot be deleted without deleting the very record the
        # guard exists to protect. An unusable fail-closed control is fail-open in
        # practice, because it gets worked around.
        # (No apostrophes in this block: it lives inside a single-quoted awk program.)
        if (vn < 1) exit 3
        distinctive = 0
        for (j = 1; j <= vn; j++) if (!is_stop(v[j])) { distinctive = 1; break }
        if (!distinctive) exit 4        # DECLARED NON-KEY — see the residual note above
        for (p = 1; p + vn - 1 <= rn; p++) {
          ok = 1
          for (j = 0; j < vn; j++) if (r[p + j] != v[j + 1]) { ok = 0; break }
          if (ok) exit 0
        }
        exit 1
      }
      exit 3   # unknown rule -> undetermined, never a pass
    }
  ' "$2" "$3"
}

# ── the evaluator for the declared non-publishable class ─────────────────────
# nonpublishable_values <trip_dir>
#   stdout : one TAB-separated record per line —  <member> <field> <rule> <value>
#            <member> the declaring limb of the row that put the value in class:
#                     `field` or `entry`. Sourced from the declaration, never
#                     enumerated here.
#            <field>  a DE-IDENTIFIED locator, e.g. "entry 3 / Specific". Never the
#                     traveler name: a third-party entry NAME is itself a member of
#                     this class, so reporting it would leak what the guard protects.
#            <rule>   one of: conjunctive | phrase | token
#   return : 0  class enumerated (possibly EMPTY — a determinate measurement)
#            2  UNDETERMINED — the class could not be determined; caller must abort
#
# The match RULE still travels WITH the record, because membership and matchability are
# one decision — but both halves of that decision now come from the declaration's row
# rather than from a literal in this body. The predicate consumes
# (member, field, rule, value) and knows nothing else.
#
# THE RE-KEY LANDED HERE, and the promise ADR-008 made about this seam held: the stdout
# contract, the return contract, the predicate, the call site and every content-guard
# assertion but one are unchanged. This body is now a parameterized evaluator — it
# knows how to PARSE an artifact and how to APPLY a row, and it knows no member of the
# class. Adding a member is a row in the declaration and no edit to this file.
#
# CD-4 — the [THIRD-PARTY] member is an ENTRY DENYLIST, not a field allowlist.
# The shipped guard enumerated exactly two things per third-party entry: the heading
# name, and the value of a line labelled `Specific:`. Every other field DEFAULT-ALLOWED.
# reference/data-model.md § Lifecycle facets states the opposite polarity outright — "The
# bound is the entry class, not a list of fields, so it holds for every facet below and for
# any facet a later release adds ... there is no default-allow outside it" — and the re-key
# would have inherited the allowlist shape from this seam. So: under a third-party entry,
# EVERY stated field value is in class, minus the short non-member list below.
#
# The label binding was independently wrong, which is why the polarity fix alone is not
# enough. `Specific:` is the PROFILE label. Measured over this repository: the
# line-anchored form occurs 3x in reference/data-model.md — all three under
# `# Traveler — Jordan` / `# Traveler — Pat`, i.e. `travelers/<name>.md` — and 2x in
# templates/traveler-intake.template.md, which governs that same profile. It occurs 0x in
# agents/00-enrichment.md, the spec that WRITES this file, and 0x in agents/06-validator.md,
# which defines the class. The derived model's own worked example (reference/data-model.md
# § Worked example — a per-traveler file)
# writes a need as `- Need → Hard Constraints "<c>" (Applies to: <n>); specific: <v>.` —
# a mid-line lowercase label, 4 occurrences, none of them line-anchored. The guard was
# parsing the derived file with the profile's label.
#
# And the third-party need's own line shape is UNDERSPECIFIED, which is the finding that
# decides the design. A third-party need cannot carry the first-party derived shape at
# all: reference/data-model.md § Needs (the stated third-party exception) bars it from ever
# escalating to a trip-level constraint or onto an `Applies to:` roster, and
# agents/06-validator.md § What You Audit, in its third-party mirror case, says it "by
# design has no governing trip-level constraint to key to". So the link head and the
# Applies-to are both unavailable to it, and what remains — a category and a specific —
# is serialized nowhere.
# Probed: of 44 fenced example blocks across every .md in the repository, 12 carry a
# `## <Name>` heading and 0 carry a [THIRD-PARTY] entry. There is no worked example.
# Binding to any label is therefore guessing, and a guard bound to a guessed shape is the
# defect this replaces. The entry denylist needs no label: it takes what the line states.
#
# EXCLUDED AS NON-MEMBERS, and this is the whole anti-over-block mechanism:
#   • the `Passport:` LABEL. The class is keyed on a traveler CAPTURED VALUE, never on
#     the word "passport" — so a legitimate packing-list line and a Destination
#     Baseline `Visa / entry` note are structurally outside the class rather than
#     stoplisted after the fact. They were never members.
#   • the `Applies to:` link, in both the parenthesized derived form and the standalone
#     profile form, and the quoted constraint name in the derived need-line head.
#     reference/data-model.md § Needs — "This is the link, **never a copy** of the
#     constraint text." Its target lives in trip-context.md, which IS publish-bound and
#     legitimately rendered; keying on it would abort on correct published content.
#   • a value made ENTIRELY of the closed need-category enum (_GUARD_NEED_ENUM) — schema
#     vocabulary, not a captured value. Same structural exclusion as the `Passport:`
#     label. Without it a `Category:` line keys on `rest` or `other` and aborts every
#     publish whose itinerary uses an ordinary English word. `Category:` is the EXAMPLE,
#     not the scope: enum_only() takes the value text and no field, so the exclusion is
#     FIELD-BLIND and applies under any label. Scoping it to `Category:` looks like the
#     obvious fix and is the wrong one — ADR-008 § Coverage boundary records why.
#   • every field of a non-third-party entry other than `Passport:` — so the designed
#     escalation path for a first-party operator-relayed need stays open. The key is
#     the third-party mark (the subject could not consent), not who supplied the value.
#
# CD-3 — the class binds to FIRST-PARTY SOURCES, not to a derived cache alone.
# outputs/traveler-model.md is a `[DERIVED]` projection: CLAUDE.md makes
# travelers/<traveler>.md authoritative and has the enrichment agent refresh the model
# from those files whenever they change. Binding the class to the projection alone means
# a passport sitting in travelers/rowan.md right now, but not yet reconciled, is reported
# as "class parsed and genuinely EMPTY" and the trip publishes at rc=0 — measured. That
# is a silent fail-open wearing the costume of a clean determinate measurement, which is
# worse than a loud refusal on an irreversible action. So the class now (a) reads the
# per-traveler files for the Passport member as well, and (b) refuses when the projection
# is behind them. Only Passport is read from the profiles: a `[THIRD-PARTY]` subject has
# no file anywhere, by construction, so the model remains their only source.
#
# Shared awk helpers, defined ONCE and used by BOTH parses below. Inlining them twice is
# exactly how the model parse and the profile parse would drift apart on what counts as
# "stated"; the same reasoning that makes _norm_words a function makes these one string.
_GUARD_AWK_HELPERS='
    function clean(s) {
      gsub(/\[[^]]*\]/, " ", s)          # bracketed provenance marks are metadata
      gsub(/[*_`]/, " ", s)              # markdown emphasis
      gsub(/[ \t]+/, " ", s)
      sub(/^ +/, "", s); sub(/ +$/, "", s)
      return s
    }
    function stated(s,   t) {            # a field present but not filled in is not a member
      t = tolower(s); gsub(/[^a-z0-9]/, "", t)
      if (t == "") return 0
      if (t == "na" || t == "nil" || t == "none" || t == "tbd") return 0
      if (t == "unknown" || t == "unspecified" || t == "notstated") return 0
      return 1
    }
    # Token count under the SAME normalization _norm_words applies, so a rule chosen
    # here from a word count is chosen against the stream the matcher will actually see.
    function wordcount(s,   t, a) {
      t = tolower(s); gsub(/[^a-z0-9]+/, " ", t)
      sub(/^ +/, "", t); sub(/ +$/, "", t)
      if (t == "") return 0
      return split(t, a, " ")
    }
    # ── the two declaration-driven primitives, shared by BOTH parses ───────────
    # True when <lab> is the declared field selector used as a label: the selector,
    # optional whitespace, then a colon. Case-insensitive, matching the shipped
    # behaviour. Deliberately index()-based rather than a built regex: a selector is
    # corpus text, and a selector carrying a regex metacharacter must not silently
    # become a pattern — a class definition that matched more than it declared would
    # be as wrong as one that matched less.
    function field_hit(lab, sel,   rest) {
      if (sel == "") return 0
      if (index(tolower(lab), tolower(sel)) != 1) return 0
      rest = substr(lab, length(sel) + 1)
      sub(/^[ \t]+/, "", rest)
      return (substr(rest, 1, 1) == ":")
    }
    # The rule the declaration put on the row, resolved against the value at emission
    # time. `by-wordcount` is the declared NAME of the shipped word-count choice, so
    # naming it expresses the existing behaviour rather than changing it:
    #   >= F tokens : prose. The phrase rule catches the verbatim and the de-attributed
    #                 carry-through.
    #   <  F tokens : the phrase rule would exit 3 (below its keyability floor) and every
    #                 publish of the trip would abort as UNDETERMINED, forever, with no
    #                 remedy — the unusable fail-closed control the token-branch note
    #                 calls fail-open in practice. The token rule is determinate on a
    #                 short value, and its is_stop / exit-4 path already handles a value
    #                 with nothing distinctive in it. Mitigated, not accepted.
    # An unrecognised rule token is returned verbatim and the matcher exits 3 on it —
    # undetermined, never a pass. A malformed declaration cannot widen what publishes.
    function rule_for(r, val,   n) {
      if (r == "by-wordcount") { n = wordcount(val); return (n >= F ? "phrase" : "token") }
      return r
    }
    # True when every token of the value is closed-enum SCHEMA vocabulary.
    function enum_only(s,   t, a, n, i) {
      if (ENUM == "") return 0
      t = tolower(s); gsub(/[^a-z0-9]+/, " ", t)
      sub(/^ +/, "", t); sub(/ +$/, "", t)
      if (t == "") return 0
      n = split(t, a, " ")
      for (i = 1; i <= n; i++) if (index(ENUM, " " a[i] " ") == 0) return 0
      return 1
    }
    # Everything a [THIRD-PARTY] entry line STATES, minus the non-member list below.
    # Shape-independent by construction: it removes the LINK constructs and an optional
    # label prefix, then takes whatever the line states. That reads the derived-model
    # need line, the profile-style block, and a bare bullet identically — which is the
    # point, because the corpus does not specify a third-party need line label at all.
    #
    # NON-MEMBERS, and this is the whole list:
    #   - the "Applies to" link, in both its parenthesized derived form and its
    #     standalone profile form. reference/data-model.md § Needs states it outright:
    #     "This is the link, never a copy of the constraint text." The constraint it
    #     points at lives in trip-context.md, which IS publish-bound and legitimately
    #     rendered, so keying on the link text would abort on correct published content.
    #     That section stated exception also bars a third-party person from an
    #     Applies-to roster, so on this member the field is doubly not a captured value.
    #   - the quoted constraint name in the derived need line head, for the same reason:
    #     it is that same link target.
    #   - a value that reduces entirely to the closed need-category enum. That enum is
    #     the SCHEMA vocabulary, not a traveler captured value — the same structural
    #     exclusion as the "Passport:" LABEL, and it is what stops a Category line
    #     aborting every publish whose itinerary says rest, timing, or other.
    #     The test is FIELD-BLIND: enum_only takes only the value text and is passed no
    #     field, so it applies under ANY label, not only Category. That is deliberate,
    #     and narrowing it to Category is the wrong fix — see ADR-008 coverage boundary.
    # Everything else under the entry is IN. reference/data-model.md § Lifecycle facets —
    # "The bound is the entry class, not a list of fields ... there is no default-allow
    # outside it."
    function tp_value(s,   t, c, nxt) {
      t = s
      sub(/^[Nn]eed[^"]*"[^"]*"[ \t]*/, "", t)                       # derived link head
      gsub(/\([ \t]*[Aa]pplies[ \t]+to[ \t]*:[^)]*\)/, " ", t)       # parenthesized link
      sub(/[Aa]pplies[ \t]+to[ \t]*:.*$/, "", t)                     # standalone link
      sub(/^[ \t]*[;,][ \t]*/, "", t)
      c = index(t, ":")
      nxt = substr(t, c + 1, 1)
      # A label prefix is a SHORT run followed by a colon and whitespace. The whitespace
      # test is what keeps a clock time in a value (no fixed plan before 10:00) from
      # being read as a label and having the value cut away behind it.
      if (c > 1 && c <= 40 && (nxt == " " || nxt == "\t" || nxt == "")) t = substr(t, c + 1)
      t = clean(t)
      if (enum_only(t)) return ""
      return t
    }
'

# The closed need-category enum (agents/00-enrichment.md § Where the source files come
# from) plus the schema words a
# need line is written with. This is SCHEMA vocabulary — it is not a list of names and it
# is not _GUARD_STOP, which is normalization vocabulary shared by all three match rules.
# Kept separate and used in ONE place: deciding that a value made only of these states no
# traveler fact. Extending it narrows the class, so it stays exactly the documented enum.
_GUARD_NEED_ENUM=' need needs category categories heat mobility dietary health '\
'rest budget cap timing sensory other specific '

# The RESERVED KEYS — the normalized keys of `## ` headings that the derived model's own
# shape defines as a STRUCTURAL SECTION rather than a person. Declared in the corpus at
# reference/data-model.md § *Reserved keys*, which is where a slice adding a structural
# section adds its key.
#
# HELD HERE RATHER THAN READ FROM THERE, and the asymmetry stated below the declaration
# block is exactly why. Reserving a key SUPPRESSES a heading from the entry and field
# limbs — it REMOVES values from the guarded set — so this is a NARROWING control, and a
# narrowing control read from a document is a fail-open surface: a corpus edit could widen
# the suppression without passing a diff of this script. Membership rows are declared
# because they widen; these are held because they narrow. Same rule, opposite direction.
#
# The list carries TWO members and carried one until this release. The second, the
# derived model's desire-overlap section, was counted as a person, and the consequence
# was not confined to the entry limb: `entries` is the operand of the END block's
# `entries == 0` fail-closed sentinel, so a structural section counted as a person is a
# phantom entry that keeps that sentinel from firing — a model drifted to carry no
# recognisable person parsed as a clean EMPTY class and published. Both directions are
# pinned by scripts/test-publish-guard.sh: L11c asserts the sentinel now fires, and L11d
# measures what the suppression costs under the second heading.
#
# Space-padded, and matched space-padded, so `overlap` never matches `desireoverlap` —
# the same containment rule _GUARD_NEED_ENUM is read with.
_GUARD_RESERVED_KEYS=' updatesignals desireoverlap '

# ═════════════════════════════════════════════════════════════════════════════
# THE PUBLISHABILITY DECLARATION — where the class lives now
# ═════════════════════════════════════════════════════════════════════════════
# Class MEMBERSHIP no longer lives in this file. It is declared in the corpus, in a
# named fenced block, and read from there. This script holds no copy of any row of
# it — that separation is the one-home property test-publish-guard.sh case L8
# asserts on every push, in both directions: the class source and the predicate must
# each hold ZERO declared selectors while the declaration holds all of them.
#
# What moved and what did NOT, because the asymmetry is the safety property:
# membership is a WIDENING control — a new row ADDS values to the guarded set — so it
# is declared. _GUARD_NEED_ENUM, _GUARD_STOP and tp_value()'s non-member list are
# NARROWING controls: extending any of them REMOVES values from the guarded set. They
# stay here, in code, behind a diff. "Finish the job by moving the rest of the class
# constants out" reads like tidying and is a fail-open change.
_GUARD_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# A plain assignment, and the two things it deliberately is not:
#   • NOT ${_GUARD_DECLARATION:-...}. An environment-defaulted path on a fail-closed
#     control is a fail-open surface — a caller could point the guard at a declaration
#     with fewer rows and narrow the class from outside the repository. This assignment
#     overwrites whatever it inherits, so a subprocess invocation cannot redirect it.
#   • NOT readonly. test-publish-guard.sh SOURCES this file and re-points the variable
#     inside its own process, which is how L9a/L9b/L10 prove the guard's verdict really
#     does follow the declaration rather than merely being described as following it.
_GUARD_DECLARATION="$_GUARD_REPO_ROOT/reference/data-architecture.md"
_GUARD_DECL_FENCE='publish-contract-values'
_GUARD_DECL_HEADING='### 5.6 The declaration'
_GUARD_DECL_ARTIFACT_MODEL='outputs/traveler-model.md'
_GUARD_DECL_ARTIFACT_PROFILE='travelers/<traveler>.md'

# Lines of the first fenced block carrying <info> inside the section headed <heading>.
# Emitted verbatim — nothing is trimmed here, because the row parse below owns that.
#
# Lifted from scripts/test-trip-resolution-contract.sh, the repository's only fenced-
# block reader, already executed by trip-resolution-contract.yml on every push to every
# branch. Pure bash, no external dependency: a fail-closed control standing in front of
# an irreversible action must not acquire a parser to do its job.
#
# ONE adaptation from the source, and it is measured rather than stylistic: this file
# runs under `set -e` and that one does not. A `while` whose last executed body command
# is a failing `&&` list returns 1, and `x="$(fence_block ...)"` would then abort the
# whole script. The explicit `return 0` is what makes the lift safe here; the algorithm
# is otherwise unchanged, byte for byte.
fence_block() {  # <file> <info> <heading>
  local f="$1" info="$2" heading="$3"
  local in_sec=0 in_fence=0 line
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_sec" -eq 0 ]; then
      [ "$line" = "$heading" ] && in_sec=1
      continue
    fi
    if [ "$in_fence" -eq 1 ]; then
      [ "$line" = '```' ] && break
      printf '%s\n' "$line"
      continue
    fi
    # Outside a fence, the next heading of level 1-3 ends the section.
    case "$line" in
      '# '*|'## '*|'### '*) break ;;
    esac
    [ "$line" = '```'"$info" ] && in_fence=1
  done < "$f"
  return 0
}

# The declaration's rows, normalized: one row per line as
#   <limb> <selector> <artifact-scope> <rule>
# Comment rows (first non-blank character `#`) and blank rows are dropped, and a row
# that does not carry exactly four fields is dropped rather than half-read — a
# malformed row that silently contributed three fields would be a class definition
# nobody wrote. Dropping every malformed row is what makes "zero rows" reachable, and
# zero rows is UNDETERMINED at the call site below, never an empty class.
_guard_declared_rows() {
  [ -f "$_GUARD_DECLARATION" ] && [ -r "$_GUARD_DECLARATION" ] || return 0
  fence_block "$_GUARD_DECLARATION" "$_GUARD_DECL_FENCE" "$_GUARD_DECL_HEADING" \
    | awk 'NF == 4 && $1 !~ /^#/ { print $1, $2, $3, $4 }'
  return 0
}

# Every row the declaration OFFERS: non-blank and non-comment, whatever its shape.
# _guard_declared_rows keeps only the well-formed four-field rows, so a difference
# between the two counts is a row the reader silently DROPPED — and a dropped row
# narrows the guarded class without narrowing anything the suite can observe.
_guard_declared_candidates() {
  [ -f "$_GUARD_DECLARATION" ] && [ -r "$_GUARD_DECLARATION" ] || return 0
  fence_block "$_GUARD_DECLARATION" "$_GUARD_DECL_FENCE" "$_GUARD_DECL_HEADING" \
    | awk 'NF > 0 && $1 !~ /^#/ { c++ } END { print c + 0 }'
  return 0
}

# Every selector the declaration names, one per line, de-duplicated in first-seen order.
# This is the probe surface case L8 runs against both function bodies; it is defined
# here, beside the declaration it reads, so the suite holds no copy of the fence name,
# the heading or the path either.
_guard_declared_selectors() {
  _guard_declared_rows | awk '!seen[$2]++ { print $2 }'
  return 0
}

# The selectors of one limb, scoped to one artifact class, space-joined; and the rules
# that travel with them, space-joined in the same order. Two accessors rather than one
# parsed structure, because awk receives them as parallel -v strings and a selector can
# contain no whitespace by the declaration's own column grammar.
_guard_limb_selectors() { # <limb> <artifact-scope>
  _guard_declared_rows | awk -v L="$1" -v A="$2" '$1 == L && $3 == A { printf "%s%s", (n++ ? " " : ""), $2 }'
  return 0
}
_guard_limb_rules() { # <limb> <artifact-scope>
  _guard_declared_rows | awk -v L="$1" -v A="$2" '$1 == L && $3 == A { printf "%s%s", (n++ ? " " : ""), $4 }'
  return 0
}

nonpublishable_values() { # <trip_dir> [site_html]
  local trip_dir="${1:-}" site_html="${2:-}" model out rc
  local model_epoch profile_epoch render_epoch pf pout prc had_profiles=0
  local decl_rows decl_n decl_cand decl_eval esel erule mfields mrules pfields prules
  if [ -z "$trip_dir" ]; then
    warn "guard: the non-publishable class needs a trip dir and none was given"; return 2
  fi

  # ── the SIXTH fail-closed path: the declaration itself ─────────────────────
  # Five UNDETERMINED paths below are properties of the artifact parse and the
  # freshness gate, and the re-key touches none of them. This one is new, and it is
  # stated here rather than discovered: a guard that cannot read its own class
  # definition has not measured an empty class, it has failed to measure. Falling
  # through to an empty record set would put the fail-open this guard refuses one
  # layer up, at the declaration instead of at the artifact.
  decl_rows="$(_guard_declared_rows)"
  decl_n="$(printf '%s' "$decl_rows" | awk 'NF { c++ } END { print c + 0 }')"
  if [ "$decl_n" -eq 0 ]; then
    warn "guard: the publishability declaration at $_GUARD_DECLARATION could not be read or yielded no rows — the class is UNDETERMINED, not empty"; return 2
  fi
  # The same path, for a PARTIAL read. The reader keeps four-field rows and drops the
  # rest, so a declaration that parses in part yields a class that is narrower than the
  # one declared — silently, and with the aggregate test above still satisfied. That is
  # the same fail-open this block refuses, one row down instead of one layer up.
  decl_cand="$(_guard_declared_candidates)"
  if [ "${decl_cand:-0}" -ne "$decl_n" ]; then
    warn "guard: the publishability declaration at $_GUARD_DECLARATION offers ${decl_cand:-0} rows but only $decl_n parse as four whitespace-separated fields — a partial read is UNDETERMINED, not a narrower class"; return 2
  fi
  # And the same path once more, for a row that PARSES but is never QUERIED. This
  # evaluator asks exactly three (limb, artifact-scope) questions; a row naming any
  # other pair is well-formed, accepted, selected by nothing, and observed by nobody —
  # so it reads as a member of the class while guarding none of it. That is the shape
  # fail-open above, one column over: there the row is dropped by the reader, here it
  # survives the reader and dies at the query. § 5.6 advertises both columns as open
  # domains, so a row outside the queried set is the documented extension path, not a
  # hypothetical.
  decl_eval="$(awk -v m="$_GUARD_DECL_ARTIFACT_MODEL" -v p="$_GUARD_DECL_ARTIFACT_PROFILE" '
      ($1 == "entry" && $3 == m) || ($1 == "field" && $3 == m) || ($1 == "field" && $3 == p) { c++ }
      END { print c + 0 }' <<<"$decl_rows")"
  if [ "${decl_eval:-0}" -ne "$decl_n" ]; then
    warn "guard: the publishability declaration at $_GUARD_DECLARATION parses $decl_n rows but this guard evaluates only ${decl_eval:-0} of them — a row naming a limb or artifact-scope the guard never queries guards nothing, and a class that silently guards less than it declares is UNDETERMINED"; return 2
  fi
  esel="$(_guard_limb_selectors entry "$_GUARD_DECL_ARTIFACT_MODEL")"
  erule="$(_guard_limb_rules     entry "$_GUARD_DECL_ARTIFACT_MODEL")"
  mfields="$(_guard_limb_selectors field "$_GUARD_DECL_ARTIFACT_MODEL")"
  mrules="$(_guard_limb_rules     field "$_GUARD_DECL_ARTIFACT_MODEL")"
  pfields="$(_guard_limb_selectors field "$_GUARD_DECL_ARTIFACT_PROFILE")"
  prules="$(_guard_limb_rules     field "$_GUARD_DECL_ARTIFACT_PROFILE")"

  model="$trip_dir/outputs/traveler-model.md"
  if [ ! -e "$model" ]; then
    warn "guard: $model is absent — the non-publishable class cannot be determined"; return 2
  fi
  if [ ! -f "$model" ] || [ ! -r "$model" ]; then
    warn "guard: $model is not a readable regular file — the class cannot be determined"; return 2
  fi
  if [ ! -s "$model" ]; then
    warn "guard: $model is empty — an empty read is not an empty class"; return 2
  fi

  # ── freshness gate (CD-3) ──────────────────────────────────────────────────
  # _epoch_of_file / _is_stale are this file's own staleness idiom — cmd_list already
  # flags a locally-rebuilt site against its deployment with them. A probe over the guard
  # block for that idiom returned 0 while the same probe over the whole file returned 11,
  # so the guard was the one consumer of a derived artifact that never asked how old it
  # was. Ties do not fire: _is_stale is a strict >, and mtime granularity is one second.
  model_epoch="$(_epoch_of_file "$model")"
  if [ -z "$model_epoch" ]; then
    warn "guard: the mtime of $model could not be read — its freshness is undetermined, and an undetermined result is never a pass"; return 2
  fi
  if [ -d "$trip_dir/travelers" ]; then
    for pf in "$trip_dir"/travelers/*.md; do
      [ -e "$pf" ] || continue
      had_profiles=1
      if [ ! -f "$pf" ] || [ ! -r "$pf" ]; then
        warn "guard: a per-traveler profile is not a readable regular file — the class cannot be determined"; return 2
      fi
      profile_epoch="$(_epoch_of_file "$pf")"
      if [ -z "$profile_epoch" ]; then
        warn "guard: a per-traveler profile's mtime could not be read — freshness undetermined"; return 2
      fi
      if _is_stale "$profile_epoch" "$model_epoch"; then
        warn "guard: a per-traveler profile is newer than $model — the [DERIVED] projection has not absorbed it, so the class is UNDETERMINED, not empty"; return 2
      fi
    done
  fi

  out="$(awk -v F="$GUARD_NGRAM" -v ENUM="$_GUARD_NEED_ENUM" -v RESERVED="$_GUARD_RESERVED_KEYS" \
            -v ESEL="$esel" -v ERULE="$erule" -v EFIELDS="$mfields" -v EFRULES="$mrules" \
            "$_GUARD_AWK_HELPERS"'
    # Index of the first declared entry selector occurring in s, or 0. The selectors and
    # their rules arrive as parallel space-joined lists — the declaration grammar makes a
    # selector whitespace-free, so joining on a space is lossless and both lists are built
    # from the same filtered rows in the same order.
    function esel_in(s,   i) { for (i = 1; i <= esn; i++) if (index(s, es[i]) > 0) return i; return 0 }
    # The same selectors with bracketing stripped and case folded — how the token reads
    # once it is prose rather than a mark. Used ONLY by the supersession detector below.
    function ebare_in(s,   i) { for (i = 1; i <= esn; i++) if (ebare[i] != "" && index(s, ebare[i]) > 0) return i; return 0 }
    BEGIN {
      esn = split(ESEL,    es, " ");  ern = split(ERULE,   er, " ")
      efn = split(EFIELDS, ef, " ");  efr = split(EFRULES, ers, " ")
      for (i = 1; i <= esn; i++) { ebare[i] = tolower(es[i]); gsub(/[][]/, "", ebare[i]) }
      entries = 0; idx = 0; tp = 0; ei = 0; live = 0; tprecs = 0; sawmark = 0; supersede = 0
    }
    # The raw text is inspected for a declared entry selector BEFORE any per-line
    # handling, so the orphaned-mark backstop in END sees marks the parse may fail to
    # resolve.
    esel_in($0) { sawmark = 1 }
    # A supersession removes the provenance mark by design (agents/00-enrichment.md
    # § Missing or blank profile, "supersede, do not merge"). Recording that it happened is what separates a sanctioned
    # provenance change from the bad merge the same passage forbids; the shell limb below
    # verifies it is supported. It cannot key on the mark — a supersession is exactly the
    # state in which the mark is gone — so it keys on the DECLARED selector read as prose.
    tolower($0) ~ /supersed/ { if (ebare_in(tolower($0))) supersede = 1 }
    /^##[ \t]/ {
      head = $0; sub(/^##[ \t]+/, "", head)
      nm = clean(head)
      key = tolower(nm); gsub(/[^a-z0-9]/, "", key)
      # Every member of the declared reserved-key list, not one literal. Space-padded on
      # both sides so a key is matched whole and never as a substring of another.
      if (index(RESERVED, " " key " ") > 0) { live = 0; tp = 0; ei = 0; next }   # structural section, not a person
      entries++; idx = entries; live = 1
      ei = esel_in(head); tp = (ei > 0)
      # The NAME record keeps the token rule as a property of the PARSE, not of the row:
      # an entry heading is a proper noun, and a proper noun is matched as a token
      # whatever match rule the row declares for the values beneath it.
      if (tp && stated(nm)) { printf "entry\tentry %d / Name\ttoken\t%s\n", idx, nm; tprecs++ }
      next
    }
    /^###/    { next }                          # deeper headings stay INSIDE the entry
    /^#[ \t]/ { live = 0; tp = 0; ei = 0; next } # the file title ends any entry
    live == 1 {
      raw = $0
      lab = $0
      sub(/^[ \t]*[-*+][ \t]+/, "", lab)
      gsub(/\*\*/, "", lab)
      sub(/^[ \t]+/, "", lab)
      # ── the FIELD limb: every declared field selector scoped to this artifact ──
      fh = 0
      for (i = 1; i <= efn; i++) {
        if (field_hit(lab, ef[i])) {
          val = lab; sub(/^[^:]*:[ \t]*/, "", val); val = clean(val)
          if (stated(val)) printf "field\tentry %d / %s\t%s\t%s\n", idx, ef[i], rule_for(ers[i], val), val
          fh = 1
          break
        }
      }
      if (fh) next
      # ── the ENTRY limb: a DENYLIST over the entry, not a field allowlist ───────
      # The declared selector is read at BOTH granularities and the two are a UNION. The
      # heading limb alone was the shipped defect: agents/00-enrichment.md § Missing or
      # blank profile, which requires the mark on "every value sourced this way" and names
      # mark-stripping as a KNOWN agent error which "silently strip[s] the key the
      # publication guard depends on" — the exact state in which a heading-only read
      # enumerates zero records for this limb and publishes.
      #
      # ORDERING IS LOAD-BEARING: the value-level selector is read off the RAW line,
      # before clean() runs. clean() deletes every bracketed provenance mark as metadata,
      # so a selector consulted after it has already been erased.
      vi = esel_in(raw)
      if (tp || vi > 0) {
        val = tp_value(lab)
        if (stated(val)) {
          # Membership and matchability are still one decision — but both halves now come
          # from the row that put this value in class, not from a literal here. The rule
          # keys off the VALUE and never off a field label: the label shape of an
          # entry-limb value is precisely what the corpus does not specify.
          ri = (vi > 0 ? vi : ei); if (ri < 1) ri = 1
          printf "entry\tentry %d / field %d\t%s\t%s\n", idx, ++fno[idx], \
                 rule_for(er[ri], val), val
          tprecs++
        }
        next
      }
    }
    END {
      if (entries == 0) exit 3
      # ORPHANED-MARK BACKSTOP. The file carries the non-publication key but the parse
      # resolved it to nothing. That is not an empty class — it is the parse failing on
      # a file that says outright it has third-party content, which is the silent
      # fail-open this guard exists to refuse. Absence is not zero; an unresolved
      # PRESENCE is not zero either.
      if (sawmark && tprecs == 0) exit 4
      if (supersede) exit 5
    }
  ' "$model" 2>/dev/null)" && rc=0 || rc=$?
  case "$rc" in
    0) ;;
    3) warn "guard: no '## <Name>' entry was recognized in $model — the derived-model format has drifted, so the class is UNDETERMINED, not empty"; return 2 ;;
    4) warn "guard: $model carries a declared entry mark ($esel) that resolved to no class record — the mark is orphaned or the entry did not parse, so the class is UNDETERMINED, not empty"; return 2 ;;
    5)
      # A recorded supersession is sanctioned ONLY by the person having filed their own
      # profile — that is the event that triggers it (agents/00-enrichment.md § Missing or
      # blank profile), and their own file is what becomes authoritative. A supersession
      # claimed with no profile anywhere is unsupported: the marks are gone and nothing
      # backs the drop, which is indistinguishable from the bad merge that section
      # forbids by name. Undetermined, never a pass.
      # had_profiles is the freshness gate's own glob result, computed above — reused
      # rather than re-scanned. Deliberately not `find -maxdepth 1 -print -quit`: that
      # is the same BSD/GNU divergence class as the _epoch_of_file defect this release
      # already tripped over, and the shell glob has one behaviour everywhere.
      if [ "$had_profiles" -ne 1 ]; then
        warn "guard: $model records a supersession of a declared entry class ($esel) but no per-traveler profile exists to support it — the provenance change is unverifiable, so the class is UNDETERMINED"; return 2
      fi
      ;;
    *) warn "guard: $model could not be parsed (exit $rc) — the class is undetermined"; return 2 ;;
  esac

  # ── first-party sources (CD-3) ─────────────────────────────────────────────
  # The FIELD limb read from the authoritative per-traveler files rather than only from
  # the projection of them — the rows whose declared artifact-scope is the profile class.
  # The label shape is the same one the model parse binds to — the intake template writes
  # each field as a bulleted, bold-emphasised label followed by a colon and the value — so
  # the same two lines of label handling serve both, and the placeholder brackets of an
  # unfilled form are
  # removed by clean() and rejected by stated(). The locator is "profile N", never the
  # file name: a file under travelers/ is named for the traveler, and naming them would
  # leak on the same axis this guard protects. N is the position in the shell's sorted
  # glob, so it is stable between runs.
  #
  # Only the FIELD limb is read here, and that is a property of the declaration rather
  # than of this code: an entry-limb subject has no profile file anywhere by
  # construction, so no row scopes that limb to this artifact class.
  if [ "$had_profiles" -eq 1 ]; then
    pout="$(awk -v F="$GUARD_NGRAM" -v ENUM="$_GUARD_NEED_ENUM" \
                -v PFIELDS="$pfields" -v PFRULES="$prules" "$_GUARD_AWK_HELPERS"'
      BEGIN { pfn = split(PFIELDS, pf, " "); pfr = split(PFRULES, pr, " ") }
      FNR == 1 { idx++ }
      {
        lab = $0
        sub(/^[ \t]*[-*+][ \t]+/, "", lab)
        gsub(/\*\*/, "", lab)
        sub(/^[ \t]+/, "", lab)
        for (i = 1; i <= pfn; i++) {
          if (field_hit(lab, pf[i])) {
            val = lab; sub(/^[^:]*:[ \t]*/, "", val); val = clean(val)
            if (stated(val)) printf "field\tprofile %d / %s\t%s\t%s\n", idx, pf[i], rule_for(pr[i], val), val
            break
          }
        }
      }
    ' "$trip_dir"/travelers/*.md 2>/dev/null)" && prc=0 || prc=$?
    if [ "${prc:-0}" -ne 0 ]; then
      warn "guard: the per-traveler profiles under $trip_dir/travelers could not be parsed (exit $prc) — the class is undetermined"; return 2
    fi
    [ -z "$pout" ] || out="${out:+$out
}$pout"
  fi

  # An EMPTY class is a MEASUREMENT only if the projection is at least as new as the
  # thing it is being asked about. Empty plus older-than-the-render is the exact shape of
  # the measured fail-open, so it is refused.
  #
  # Deliberately conditioned on emptiness rather than applied unconditionally, and this
  # is a narrowing of the counter-design that is worth stating. In the normal authoring
  # order the render is written AFTER the model — enrichment reconciles, then the hub
  # synthesises, then the site is built — so an unconditional "render newer than model"
  # gate refuses every correct publish rather than more of them. That is the unusable
  # fail-closed control the token-branch note above describes, and it ends as a
  # workaround rather than a guard. A non-empty class needs no such inference: the
  # projection demonstrably holds class content, and it is matched.
  if [ -z "$out" ] && [ -n "$site_html" ] && [ -e "$site_html" ]; then
    render_epoch="$(_epoch_of_file "$site_html")"
    if [ -n "$render_epoch" ] && _is_stale "$render_epoch" "$model_epoch"; then
      warn "guard: the class read EMPTY but $model predates the rendered site — an empty read from a projection older than the render is UNDETERMINED, not an empty class"; return 2
    fi
  fi

  [ -z "$out" ] || printf '%s\n' "$out"
  return 0
}

# verify_publishable_content <site_html> <trip_dir>
#   return 0  no non-publishable value reached the render — safe to copy
#          1  HIT          — a non-publishable value is in the render
#          2  UNDETERMINED — the class or the render could not be determined
#
# Three return codes where verify_ciphertext has two, because the test suite has to be
# able to tell a HIT from an UNDETERMINED: under a binary contract a guard that aborted
# for the WRONG REASON would still pass its own tests. The call site collapses both to
# one die, so cmd_publish behaviour stays binary; only the tests read the distinction.
#
# This function contains NO class knowledge — no field labels, no member names. It
# consumes records. That is mechanically checkable, and the suite checks it.
#
# It also NEVER echoes the matched value, deliberately diverging from the sibling guard
# below, which prints the offending token. The strings this one matches are passport
# values and third-party health needs, and this suite runs in a public Actions log —
# echoing them would make the guard leak exactly what it exists to protect. Member and
# field only. Stage 8: this is a decision, not an inconsistency to fix.
verify_publishable_content() { # <site_html> <trip_dir>
  local site_html="${1:-}" trip_dir="${2:-}"
  local recs rc rcv rcp work rfile pfile vfile n member field rule value hit=0 undet=0

  if [ -z "$site_html" ] || [ -z "$trip_dir" ]; then
    warn "guard: content check needs a rendered site and a trip dir"; return 2
  fi
  if [ ! -r "$site_html" ]; then
    warn "guard: the rendered site is absent or unreadable — what would be published cannot be certified"; return 2
  fi

  work="$(mktemp -d)" || { warn "guard: could not stage the content check"; return 2; }
  rfile="$work/render.words"; pfile="$work/published.words"; vfile="$work/value.words"

  # TWO projections of the same file, matched independently, because publish copies the
  # file and not the painting of it. The visible arm is what a reader sees; the published
  # arm is what a reader can retrieve. Both use the SAME _norm_words on both sides of the
  # comparison — one normalization, four streams, no chance of the sides drifting.
  strip_to_text_blocks "$site_html" | _norm_words > "$rfile"
  # Sentinels are not words and must not count toward the degraded-extraction floor.
  n="$(awk -v B="$_GUARD_BLOCK" '$0 != B { c++ } END { print c + 0 }' "$rfile")"; n="${n:-0}"
  if [ "$n" -lt 20 ]; then
    rm -rf "$work"
    warn "guard: the rendered site yielded only $n words of visible text — a degraded extraction is not a clean result"
    return 2
  fi
  # No word floor on the published arm: a page with no comments, attributes or scripts
  # yields little here and that is normal, not degraded. An EMPTY published stream is
  # simply not matched against — _guard_match reads an empty render as UNDETERMINED, and
  # a file with no markup to inspect is not an undetermined result.
  strip_to_published_text "$site_html" | _norm_words > "$pfile"

  recs="$(nonpublishable_values "$trip_dir" "$site_html")" && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then rm -rf "$work"; return 2; fi
  # A parsed-and-empty class is a MEASUREMENT; an unrecognized file is a DEGRADATION.
  # Collapsing them would make a broken parser indistinguishable from a trip that has
  # neither a passport value nor a third-party entry. Absence is not zero.
  if [ -z "$recs" ]; then rm -rf "$work"; return 0; fi

  while IFS="$(printf '\t')" read -r member field rule value; do
    [ -n "${rule:-}" ] || continue
    printf '%s' "$value" | _norm_words > "$vfile"
    _guard_match "$rule" "$vfile" "$rfile"; rcv=$?
    rcp=1
    [ -s "$pfile" ] && { _guard_match "$rule" "$vfile" "$pfile"; rcp=$?; }
    # Combine the two arms. A hit on EITHER projection is a hit — the value is in the
    # file either way. Otherwise the visible arm carries the verdict, because every
    # non-hit code is a property of the VALUE (its keyability floor, its distinctiveness)
    # rather than of the projection, so the arms agree on it by construction.
    if   [ "$rcv" -eq 0 ] || [ "$rcp" -eq 0 ]; then rc=0
    elif [ "$rcv" -eq 1 ] && [ "$rcp" -ne 1 ]; then rc="$rcp"
    else rc="$rcv"; fi
    case "$rc" in
      0) warn "guard: a non-publishable value reached the published file — member '$member', field '$field'. The value is deliberately not echoed."; hit=1 ;;
      1) ;;
      3) warn "guard: member '$member', field '$field' is below the keyability floor for rule '$rule' — its carry-through cannot be determined, and an undetermined result is a failure, never a clean pass."; undet=1 ;;
      4) warn "guard: member '$member', field '$field' carries no distinctive token and is a DECLARED NON-KEY — it is not matched, by design. See ADR-008 § Coverage boundary." ;;
      *) warn "guard: the match for member '$member', field '$field' could not be run (matcher exit $rc) — undetermined, not clean."; undet=1 ;;
    esac
  done <<EOF
$recs
EOF

  rm -rf "$work"
  [ "$hit"   -eq 0 ] || return 1
  [ "$undet" -eq 0 ] || return 2
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# The markdown sibling of the guard, for an artifact that is never published.
#
# ── WHY A SECOND EVALUAND AND NOT A SECOND MECHANISM ─────────────────────────
# outputs/change-summary.md (C20) is `publish: internal`. It is shared by the
# organizer out of band and never reaches the render, so verify_publishable_content
# never sees it: that function is HTML-bound on both of its projections and is called
# from exactly one site, cmd_publish's plaintext limb, on the file being published.
# Reusing it here would mean either widening it to a second evaluand class or calling
# it on a file it was not written for.
#
# What IS reused is everything below it, and all three are evaluand-agnostic by
# construction: nonpublishable_values (the class SOURCE), _norm_words (the shared
# normalization), and _guard_match (the matcher, which consumes two token files and
# knows nothing about the class that produced them). This function therefore adds one
# projection and no membership knowledge — it declares ZERO selectors, no literal
# field label and no literal member name, exactly as its HTML sibling does. That is
# the property test-publish-guard.sh case L8 grades, and L8 names its target functions
# explicitly, so this one is added to that list in the same change.

# The degraded-extraction floor for a markdown summary. DELIBERATELY NOT the 20-word
# floor verify_publishable_content applies, and copying that number here would be the
# error rather than the safe default.
#
# CALIBRATION. That floor is derived from a rendered multi-day site, where fewer than
# twenty visible words means the HTML extraction fell over. This artifact's minimum
# legitimate shape is one rendered change line: `Tuesday dinner moved 19:00 to 20:00`
# normalizes to SEVEN tokens. A floor of 20 would return 2 — UNDETERMINED, never a
# pass — on every small summary, and an UNDETERMINED that no correct input can clear
# is a fail-closed control with no remedy, which ADR-008 argues against twice and which
# in practice gets worked around rather than satisfied.
#
# 4 sits below the seven-token minimum with margin, and above what the cases this floor
# exists to catch actually produce: an empty, unreadable or truncated file yields 0.
# Note the asymmetry with the HTML arm and why it is correct — the markdown projection
# below is NON-LOSSY (it inserts sentinels and drops nothing), so there is no extraction
# machinery here that can silently degrade. The floor guards the file, not the parser.
GUARD_SUMMARY_FLOOR=4

# strip_md_to_text_blocks <markdown_file> -> text with block sentinels on stdout
#
# The markdown counterpart of strip_to_text_blocks. THE SENTINEL IS THE WHOLE POINT and
# it is not cosmetic: _guard_match's `conjunctive` rule requires both distinctive tokens
# of a value inside ONE structural block as well as inside GUARD_WINDOW. With no
# sentinel every token lands in block 0, blk[pos[right]] == blk[pos[left]] is true for
# every pair, and the rule degrades to a bare word window — which is verbatim the
# N-squared day-pairing false abort that ADR-008's first amendment exists to fix, and
# which measured as a permanent abort from two days onward. A summary accumulates a
# dated section per re-bake, so it has exactly the recurrence shape that defect needs.
#
# The block boundaries are markdown's own: a blank line, an ATX heading, a list item, a
# table row, a rule or frontmatter fence, a code fence, a block quote. Emitted BEFORE
# the line's own text, so the line opens the new block rather than closing the old one.
strip_md_to_text_blocks() { # <markdown_file> -> visible text with block sentinels on stdout
  awk -v B="$_GUARD_BLOCK" '
    /^[[:space:]]*$/                                  { print B; next }
    /^[[:space:]]*#{1,6}[[:space:]]/                  { print B }
    /^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]/      { print B }
    /^[[:space:]]*\|/                                 { print B }
    /^[[:space:]]*(---|===|___|\*\*\*)/               { print B }
    /^[[:space:]]*(```|~~~)/                          { print B }
    /^[[:space:]]*>/                                  { print B }
    { print }
  ' "$1"
}

# verify_summary_content <change_summary_md> <trip_dir>
#   return 0  no non-publishable value reached the summary
#          1  HIT          — a non-publishable value is in the summary
#          2  UNDETERMINED — the class or the summary could not be determined
#
# The same three-code contract as verify_publishable_content, for the same reason: a
# binary contract cannot tell a guard that aborted for the RIGHT reason from one that
# aborted for the wrong one, and the suite has to.
#
# ── THIS IS LAYER 2. LAYER 1 IS THE DERIVATION BOUND AND IT IS THE STRONGER ONE ──
# agents/05-hub-planner.md constrains the generator to read only `publish: bound`
# classes — C11, C13 and C1 — and never an `internal-hard` one, so the derived rows
# carry no more than the site already encrypts. That is a PROVABLE bound: a value never
# read cannot leak. What Layer 1 does not bound is free text an agent writes into the
# summary alongside the derived rows, and that residue is what this function grades.
#
# It NEVER echoes the matched value, deliberately, for the reason its HTML sibling
# states: the strings matched here are passport values and third-party health needs,
# and this runs in a public Actions log.
#
# ONE projection, not two. The HTML sibling matches a visible arm and a retrievable arm
# because publish copies the file rather than the painting of it. There is no such split
# here: the projection below drops nothing, so the tokens it yields ARE the file's, and a
# second arm would be the same stream twice.
verify_summary_content() { # <change_summary_md> <trip_dir>
  local summary_md="${1:-}" trip_dir="${2:-}"
  local recs rc work sfile vfile n member field rule value hit=0 undet=0

  if [ -z "$summary_md" ] || [ -z "$trip_dir" ]; then
    warn "guard: the summary check needs a change summary and a trip dir"; return 2
  fi
  if [ ! -r "$summary_md" ]; then
    warn "guard: the change summary is absent or unreadable — what would be shared cannot be certified"; return 2
  fi

  work="$(mktemp -d)" || { warn "guard: could not stage the summary check"; return 2; }
  sfile="$work/summary.words"; vfile="$work/value.words"

  strip_md_to_text_blocks "$summary_md" | _norm_words > "$sfile"
  # Sentinels are not words and must not count toward the floor — the same subtraction
  # the HTML arm makes, for the same reason.
  n="$(awk -v B="$_GUARD_BLOCK" '$0 != B { c++ } END { print c + 0 }' "$sfile")"; n="${n:-0}"
  if [ "$n" -lt "$GUARD_SUMMARY_FLOOR" ]; then
    rm -rf "$work"
    warn "guard: the change summary yielded only $n words — below the $GUARD_SUMMARY_FLOOR-word floor, so a degraded read is not a clean result"
    return 2
  fi

  # The class comes from the declaration, through the one function that owns it. The
  # second argument is the artifact being certified: nonpublishable_values uses it only
  # for the empty-class-versus-stale-model mtime comparison, which is not HTML-specific,
  # so passing the summary preserves the semantics exactly — the class read empty but
  # the model predates the artifact ⇒ 2.
  recs="$(nonpublishable_values "$trip_dir" "$summary_md")" && rc=0 || rc=$?
  if [ "$rc" -ne 0 ]; then rm -rf "$work"; return 2; fi
  # A parsed-and-empty class is a MEASUREMENT; an unrecognized model is a DEGRADATION,
  # and nonpublishable_values has already returned 2 for that above. Absence is not zero.
  if [ -z "$recs" ]; then rm -rf "$work"; return 0; fi

  while IFS="$(printf '\t')" read -r member field rule value; do
    [ -n "${rule:-}" ] || continue
    printf '%s' "$value" | _norm_words > "$vfile"
    _guard_match "$rule" "$vfile" "$sfile"; rc=$?
    case "$rc" in
      0) warn "guard: a non-publishable value reached the change summary — member '$member', field '$field'. The value is deliberately not echoed."; hit=1 ;;
      1) ;;
      3) warn "guard: member '$member', field '$field' is below the keyability floor for rule '$rule' — its carry-through cannot be determined, and an undetermined result is a failure, never a clean pass."; undet=1 ;;
      4) warn "guard: member '$member', field '$field' carries no distinctive token and is a DECLARED NON-KEY — it is not matched, by design. See ADR-008 § Coverage boundary." ;;
      *) warn "guard: the match for member '$member', field '$field' could not be run (matcher exit $rc) — undetermined, not clean."; undet=1 ;;
    esac
  done <<EOF
$recs
EOF

  rm -rf "$work"
  [ "$hit"   -eq 0 ] || return 1
  [ "$undet" -eq 0 ] || return 2
  return 0
}

# ═════════════════════════════════════════════════════════════════════════════
# verify_ciphertext — THE PRE-PUSH SAFETY GUARD  ◀── your high-judgment function
# ═════════════════════════════════════════════════════════════════════════════
# This is the single mechanism standing between "private site" and "accidentally
# re-published my plaintext itinerary." It is called immediately before every push
# and MUST be FAIL-CLOSED: return 0 only when the output is provably safe to publish;
# return non-zero for ANY doubt, which aborts the push.
#
# Contract:
#   verify_ciphertext <encrypted_index_html> <plaintext_source_html> [boilerplate_html]
#   return 0  -> verified ciphertext, safe to push
#   return 1  -> NOT safe, abort (do not push)
#   [boilerplate_html] is a token-less decoy encrypted with the same StatiCrypt build; any
#   token found there is StatiCrypt's own vocabulary (not an itinerary leak) and is not flagged.
#
# Design latitude (this is why it's yours to own):
#   • Proof of encryption is STRUCTURAL, not keyword-based: the published page's visible
#     text (markup + scripts stripped) must be near-empty, because StatiCrypt replaces the
#     body with a tiny prompt and the itinerary survives only as ciphertext. This is
#     casing-independent — it catches an all-lowercase plaintext a token scan would miss.
#   • The token backstop additionally rejects any distinctive source term that leaked into
#     the raw bytes. A false abort is safe; a false pass leaks — bias to abort.
#   • Earlier lesson baked in: a naive "any capitalized word" scan flagged markup like
#     DOCTYPE (present in the shell too) and aborted every publish — hence visible-text
#     derivation + a stoplist + the length-based structural proof.
#
# Below is a working DEFAULT. Replace the body with your own predicate to taste.
verify_ciphertext() { # <enc> <src> [boilerplate_html]
  local enc="$1" src="$2" boiler="${3:-}" tok enc_visible
  local stoplist='^(doctype|html|head|body|title|meta|link|script|style|charset|viewport|password|passphrase|protected|loading|decrypt|please|enter|button|submit|remember|window|document|function|staticrypt|leaflet|google|fonts)$'
  # Self-check: never certify the source file as its own ciphertext.
  if [ "$enc" -ef "$src" ]; then warn "guard: enc and src are the same file"; return 1; fi
  # (a) Positive: StatiCrypt ENCRYPTED-PAYLOAD markers (not merely the word "staticrypt",
  #     which a plaintext file could contain).
  grep -qiE 'staticryptEncrypted|staticryptConfig|cryptoEngine' "$enc" \
    || { warn "guard: StatiCrypt encrypted-payload markers absent"; return 1; }
  # (b) Positive: a passphrase prompt must be present (the gate the viewer hits).
  grep -qiE 'password|passphrase' "$enc" || { warn "guard: no passphrase prompt in output"; return 1; }
  # (c) STRUCTURAL fail-closed proof (casing-independent): the visible text of the
  #     published page must be near-empty. Real ciphertext shows only the prompt
  #     (~40 chars); a plaintext itinerary's visible text runs to hundreds+ of chars.
  enc_visible="$(strip_to_text "$enc" | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//')"
  if [ "${#enc_visible}" -gt 200 ]; then
    warn "guard: output has ${#enc_visible} visible chars (>200) — looks unencrypted"; return 1
  fi
  # (d) Negative backstop: no distinctive plaintext token from the source's visible text
  #     may appear in the published bytes (raw, scripts included) — UNLESS it belongs to
  #     StatiCrypt's own fixed shell vocabulary. Common itinerary words (Check, Close, Center,
  #     Already…) also occur in StatiCrypt's HTML/CSS/JS, so without subtracting that vocabulary
  #     the backstop false-aborts every real itinerary. When a boilerplate reference is supplied
  #     (a token-less decoy from the same StatiCrypt build), a token found there is boilerplate,
  #     not a leak, and is skipped; a distinctive leak token (a place/surname) is absent from
  #     the decoy and still aborts. Check (c) remains the primary structural proof.
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    if grep -qiF -- "$tok" "$enc"; then
      if [ -n "$boiler" ] && grep -qiF -- "$tok" "$boiler"; then continue; fi
      warn "guard: plaintext token '$tok' leaked into output"; return 1
    fi
  done < <(strip_to_text "$src" \
            | grep -oE '[A-Za-z0-9]{5,}' \
            | grep -ivE "$stoplist" \
            | grep -E '[A-Z0-9]' \
            | sort -u | head -80)
  return 0
}

# ═════════════════════════════════════════════════════════════════════════════
# ORGANIZER-CONFIRM GATE (#552) — ADR-003 § Decision 2
# ═════════════════════════════════════════════════════════════════════════════
# ADR-003 decided a republish gates on the ORGANIZER's confirmation, not on a
# system-counted quorum. This block is the gate: three pure resolvers, one abort,
# and one recorder. It is deliberately placed BELOW the ADR-008 guard region and
# ABOVE every subcommand, so it shares no hunk with either.
#
# ── WHAT THE GATE MEASURES, AND WHY IT IS NOT "A PUBLISH IS HAPPENING" ────────
# The first cut of this design blocked a republish whenever a change was pending.
# That is wrong here, and the reason is structural rather than stylistic: ADR-002
# Decision 2 permits only a city-ambient client-side fetch, so ALL coordination
# state lives inside the published bytes. Showing a traveller that a change is
# pending therefore REQUIRES a publish — of a site whose itinerary content is the
# one already published, carrying a coordination marker that says pending. A gate
# keyed on publish-as-such aborts exactly that act, and the "change pending" state
# becomes unreachable.
#
# So the gate keys on ITINERARY-CONTENT CHANGE:
#   • itinerary content == what is currently published  -> nothing to confirm
#   • itinerary content moved, and no confirmation      -> abort
# A coordination-marker-only republish passes. An unapproved plan change does not.
#
# ── THE ITINERARY-CONTENT BOUNDARY, STATED SO A REVIEWER CAN SEE THE BYTES ────
# "Itinerary content" is the VISIBLE TEXT of the site render, whitespace-collapsed,
# with the coordination-notice band excised. Three parts, each grounded:
#
#   (1) VISIBLE TEXT, not the whole file. This repository already names that
#       projection as itinerary content: strip_to_text's own contract line is
#       "so the guard derives leak-tokens from itinerary *content*, not shared
#       markup." Taking the whole file, or strip_to_published_text, would put the
#       notice's CSS rule, its script branch, its `is-pending` class token and
#       every attribute value inside the digest — and a marker-only republish
#       would then read as an itinerary change, which is the deadlock again.
#       strip_to_text deletes <script>/<style> bodies wholesale and turns every
#       tag into a space, so a pure styling or scripting change moves nothing here
#       by construction. That is the property this boundary needs.
#   (2) WHITESPACE-COLLAPSED, so a re-indent or a markup reflow is not a plan
#       change. The collapse is verify_ciphertext check (c)'s own idiom
#       (tr -s '[:space:]' ' ' then trim), reused rather than reinvented.
#   (3) THE NOTICE BAND EXCISED. The band is visible text, so without this it
#       would sit inside the digest. It is identified by its class token, and the
#       excision is bounded — see strip_to_itinerary_text.
#
# WHAT IS OUTSIDE THE BOUNDARY, stated rather than implied: markup, HTML comment
# bodies, attribute values, <script> and <style> bodies. A change confined to one
# of those does not move the digest and can ride a standing confirmation. That is
# the same coverage boundary ADR-008 draws between its two projections, and it is
# the deliberate price of (1): pulling those surfaces in would make every CSS or
# script edit — including #551's own — read as an itinerary change.
#
# ── WHY A PUBLISHED BASELINE EXISTS AT ALL ───────────────────────────────────
# "Differs from what is currently published" needs a local anchor, and there is
# none to be had from the published artifact: it is ciphertext by construction,
# which is the whole point of ADR-002. Recording a fingerprint of the plaintext in
# the per-trip PUBLIC repo would be a new disclosure surface, so it is not done.
# The anchor is therefore a git-ignored sidecar in the trip dir, written by the
# publish paths after a push succeeds. Absent, the gate has no anchor and the trip
# republishes exactly as it does today — which is also the back-compat property
# every trip published before this change relies on.
# ═════════════════════════════════════════════════════════════════════════════

# SEAM S4 (#551) — the coordination notice's identity, and the only line in this
# file that binds to #551's render. #551 declares the band as `.coord-notice` with
# variants `.coord-notice.is-pending` / `.coord-notice.is-updated`, and declares
# NON-EMISSION when coordination-state is absent or `none` — so on a trip with no
# coordination activity there is nothing here to excise and the projection equals
# strip_to_text exactly. If that class token changes, this line changes and nothing
# else does.
_COORD_NOTICE_CLASS='coord-notice'
# The excision cap, in source characters. #551 declares the band's content as "a
# static label string + the coordination-since date. Nothing else." — so a few
# hundred characters is generous. The cap is what makes the FAIL-OPEN direction
# unreachable: an unterminated or mis-shaped band matches nothing, the marker text
# stays in the digest, and a marker-only republish then reads as an itinerary
# change and ABORTS. Both failure directions land fail-closed; only an excision
# that ran PAST the band could hide a plan change, and the cap forbids it.
_COORD_NOTICE_CAP=512

# The itinerary-content projection. A SIBLING of strip_to_text, not an edit to it:
# verify_ciphertext consumes strip_to_text and #550's AC 5 holds its behaviour
# fixed, so this file's established pattern is a new projection beside it — the
# same reason strip_to_text_blocks and strip_to_published_text exist.
#
# ONE LIMB, AND WHY (#552 D10). This function shipped with strip_to_text's
# `perl … 2>/dev/null || sed -E 's/<[^>]*>/ /g'` idiom copied onto it. That idiom
# is honest THERE — strip_to_text's perl program is a tag-stripper and little else,
# so the sed limb computes approximately the same answer — and dishonest HERE,
# because the two limbs compute different things: this perl program also excises
# the coordination band, and the sed limb does not. A failing or absent perl
# therefore substituted a DIFFERENT projection into the gate's digest, silently
# (`||` reads a status, and `2>/dev/null` threw away the only message), a
# marker-only republish read as an itinerary change, and the gate aborted — which
# is operator decision D6 conditionally reinstated. Graded by group S11.
#
# The limb is REMOVED rather than taught to excise, because sed cannot express this
# program: it slurps the whole file (-0777), back-references the band's own tag name
# (\1), and BOUNDS the excision with a lazy quantifier. The bound is the single
# property that keeps the excision from running past the band into plan content — an
# over-running excision deletes plan text, the digest then reads "unchanged", and an
# unapproved change ships behind a marker. An approximate sed limb would put that one
# FAIL-OPEN direction back on the table, so there is no honest fallback to offer;
# strip_to_published_text, whose program is likewise inexpressible in sed, already has
# this shape. perl is asserted in preflight instead of assumed here.
#
# stderr is deliberately NOT discarded. The `2>/dev/null` existed to silence perl
# before falling back; with nothing to fall back to it would silence the one message
# that explains the failure. The non-zero status now reaches itinerary_digest, which
# turns it into this file's existing "nothing" answer for a projection it could not
# take — an answer every caller already handles as "not a match".
strip_to_itinerary_text() { # <html_file> -> visible itinerary text on stdout, or nothing on failure
  COORD_CLASS="$_COORD_NOTICE_CLASS" COORD_CAP="$_COORD_NOTICE_CAP" \
  perl -0777 -pe '
    my $c = quotemeta($ENV{COORD_CLASS}); my $cap = 0 + $ENV{COORD_CAP};
    s{<\s*([A-Za-z][-A-Za-z0-9]*)\b[^>]*\bclass\s*=\s*(["\x27])[^"\x27]*(?<![-\w])$c(?![-\w])[^"\x27]*\2[^>]*>.{0,$cap}?<\s*/\s*\1\s*>}{ }gis;
    s/<(script|style)\b[^>]*>.*?<\/\1>//gis;
    s/<[^>]+>/ /g;
  ' "$1"
}

# SEAM (#88) — the digest primitive, reading STDIN. cksum, not shasum/sha256sum:
# those are the BSD-vs-GNU dialect split this file documents at length above
# _epoch_of_file, and cksum in the stdin form is the repository's only existing
# digest idiom (scripts/test-command-taxonomy.sh). The stdin form omits the
# filename, so the token depends only on content; BOTH emitted fields (checksum and
# byte length) are combined, so the token binds size as well as CRC.
# STATED TRADE: cksum is CRC-32 — it detects change, it does not resist forgery.
# That is the correct property here, because ADR-003 places the trust in the
# organizer explicitly and there is no adversary in this threat model. Should #88
# later collect attributable per-traveler approvals, forgery resistance becomes
# real and the swap is this one function body.
_digest_of() { # (stdin) -> one stable identity token
  cksum | awk '{ printf "%s-%s", $1, $2 }'
}

# The itinerary-content identity of a site render. Nothing on an unreadable file —
# the caller decides what an unreadable render means, and every caller here treats
# it as "not a match" rather than as "unchanged".
#
# A FAILED PROJECTION TAKES THAT SAME "NOTHING" PATH (#552 D10), and the projection is
# therefore run and CHECKED before the pipeline rather than inside it. Written as a
# pipeline, a projection that failed still emitted nothing INTO the pipeline, and
# `cksum` over nothing is a perfectly well-formed token (`4294967295-0`) that
# _record_digest's charset test accepts and change_confirmation_state compares. The
# gate would then be deciding from a digest that identifies no itinerary at all. So
# the status is read first, and it is the ONLY discriminator: a render whose visible
# text is legitimately empty still projects successfully and still gets that token,
# because an empty itinerary is a real identity a trip may hold. Emptiness of the
# OUTPUT means "empty render"; a non-zero STATUS means "no answer". Graded by S11b/S11d.
#
# `local text` is declared on its own line and assigned on the next, then read with an
# explicit `||` — the combined `local text="$(…)"` form returns the status of `local`
# and would mask exactly the failure this is here to catch. Same bash trap
# require_change_confirmation names below, same reason.
#
# The output is byte-identical to the pipeline it replaces for every input the
# projection can take: command substitution strips trailing newlines, which
# `tr -s '[:space:]' ' '` followed by `sed 's/ *$//'` had already collapsed and
# trimmed. Existing .published-itinerary sidecars keep matching.
itinerary_digest() { # <html_file> -> identity token, or nothing
  [ -r "${1:-}" ] || return 0
  local text
  text="$(strip_to_itinerary_text "$1")" || return 0
  printf '%s' "$text" | tr -s '[:space:]' ' ' | sed 's/^ *//; s/ *$//' | _digest_of
}

# The three sidecars, one resolver each. All three sit inside the trip dir, which
# .gitignore excludes (`trips/*`) and which no subcommand ever copies into the
# per-trip repo — so none of them is a publish surface.
#
# SEAM S1 (#550) — DISPLAY ONLY, and deliberately not load-bearing. #550 landed the
# pending change as outputs/change-summary.md (class C20) carrying a `status`
# field, not as a presence-marker file. The gate does not read it: keying on it
# would key on publish-as-such, which is exactly what this design must not do.
# cmd_confirm prints it so the organizer confirms against a named artifact.
pending_change_path()     { printf '%s' "$1/outputs/change-summary.md"; }
# The organizer's recorded approval, digest-bound to the itinerary it approves.
change_confirmation_path() { printf '%s' "$1/.change-confirmed"; }
# The itinerary content as of the last successful push. Written by cmd_publish and
# cmd_update; read only here.
published_itinerary_path() { printf '%s' "$1/.published-itinerary"; }

# The `digest=` line of a two-line record, or NOTHING when the file is absent, the
# line is missing, or the token is not a well-formed digest. Folding those three
# into one empty answer is what satisfies ADR-007 §2's bound that no command may
# predicate a branch on a field's ABSENCE where a placeholder makes that field
# present: every caller branches on the VALUE, and a malformed record is never read
# as approval. Written as a read loop rather than a pipeline on purpose — a
# `sed ... | head -1` would be the early-exit-under-pipefail shape this suite's
# group PF grades against.
_record_digest() { # <record_file> -> digest token, or nothing
  local f="${1:-}" line tok=""
  [ -r "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      digest=*) tok="${line#digest=}"; break ;;
    esac
  done < "$f"
  case "$tok" in
    ''|*[!A-Za-z0-9-]*) return 0 ;;
  esac
  printf '%s' "$tok"
}

# Records the itinerary content that is now live. Called AFTER a push succeeds, so
# the sidecar never claims content that was not published. Atomic: written to a
# temp file in the same directory, then moved into place, so a crash mid-write
# cannot leave a half-record that _record_digest would read as a digest.
record_published_itinerary() { # <trip_dir> <site_html>
  local trip_dir="$1" site_html="$2" out tmp dg
  out="$(published_itinerary_path "$trip_dir")"
  dg="$(itinerary_digest "$site_html")"
  [ -n "$dg" ] || return 0
  tmp="$(mktemp "${out}.XXXXXX")" || return 0
  printf 'digest=%s\npublished=%s\n' "$dg" "$(_iso_now)" > "$tmp"
  mv -f "$tmp" "$out"
}

# SEAM S2 (#88) — the resolver. Pure: reads files, no network, no TTY, no writes.
# #88 replaces THIS BODY to aggregate per-traveler approvals against its decided
# threshold; the four-token contract, require_change_confirmation and its call site
# all survive that replacement unchanged, provided #88 emits from this vocabulary —
# which the allowlist-proceed case below enforces by aborting on anything else.
#
#   none-pending  no published baseline, OR the outgoing itinerary content is
#                 exactly what is already published        -> proceed
#   unconfirmed   itinerary content moved, and no parseable confirmation  -> abort
#   stale         itinerary content moved since it was confirmed          -> abort
#   confirmed     the confirmation covers this exact itinerary content    -> proceed
change_confirmation_state() { # <trip_dir> -> one token on stdout
  local trip_dir="$1" base_dg out_dg rec_dg
  base_dg="$(_record_digest "$(published_itinerary_path "$trip_dir")")"
  if [ -z "$base_dg" ]; then printf 'none-pending'; return 0; fi
  out_dg="$(itinerary_digest "$(resolve_site_html "$trip_dir")")"
  if [ "$out_dg" = "$base_dg" ]; then printf 'none-pending'; return 0; fi
  rec_dg="$(_record_digest "$(change_confirmation_path "$trip_dir")")"
  if [ -z "$rec_dg" ]; then printf 'unconfirmed'; return 0; fi
  if [ "$rec_dg" = "$out_dg" ]; then printf 'confirmed'; return 0; fi
  printf 'stale'
}

# SEAM S3 (#85) — THE GATE. One argument, no side effects, no TTY, no network, and
# bound to the site-HTML artifact rather than to any caller's locals — which is why
# relocating it onto #85's event-driven path is moving this one call line.
#
# TWO PROPERTIES ARE LOAD-BEARING AND MUST NOT BE VARIED:
#
#  1. `local state` is DECLARED on its own line and ASSIGNED on the next. A combined
#     `local state="$(…)"` returns the exit status of `local`, masking the command
#     substitution's status so `set -e` can never fire on it. Known bash trap.
#  2. The PROCEED SET IS THE ALLOWLIST and `*)` is the abort. Written the other way
#     round — enumerating the abort cases with a permissive default — an unknown or
#     empty token would PUBLISH. That inversion is the whole risk this design was
#     built against: with this ordering there is no value the resolver can emit,
#     including one no author anticipated and including the empty string, that
#     reaches a push. It is unreachable rather than merely tested.
#     Do NOT add a marker-only exemption branch here. Keying the gate on itinerary
#     content is what makes the marker-only republish pass; an exemption inside a
#     fail-closed guard is the failure mode this shape exists to remove.
require_change_confirmation() { # <trip_dir>
  local trip_dir="$1"
  local state
  state="$(change_confirmation_state "$trip_dir")"
  case "$state" in
    none-pending|confirmed) return 0 ;;
    *) die "GUARD ABORTED — the itinerary content differs from the published plan and no organizer confirmation covers it (state: ${state:-empty}). Nothing was pushed and the published plan is unchanged. Either confirm the change:  $(basename "$0") confirm ${trip_dir}  — or revert the working copy to the published plan and re-run." ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Subcommands
# ─────────────────────────────────────────────────────────────────────────────
cmd_publish() { # <trip_dir> [--plaintext] [--opaque]
  local trip_dir="${1:?usage: publish <trip-dir> [--plaintext] [--opaque]}"; shift || true
  local plaintext=0 opaque=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --plaintext) plaintext=1 ;;
      --opaque)    opaque=1 ;;
      *) die "unknown option for publish: $1 (try --plaintext or --opaque)" ;;
    esac
    shift
  done
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"
  preflight; resolve_noreply_identity

  # --opaque must run BEFORE slug resolution: it writes .publish-slug, which slug_for reads.
  [ "$opaque" = "1" ] && ensure_opaque_slug "$trip_dir"

  local site_html slug pub_dir owner ans
  site_html="$(resolve_site_html "$trip_dir")"
  slug="$(slug_for "$trip_dir")"
  pub_dir="$trip_dir/.publish"
  owner="$(gh api user --jq '.login')"
  if gh repo view "${owner}/${slug}" >/dev/null 2>&1; then
    die "per-trip repo ${owner}/${slug} already exists — use:  $(basename "$0") update ${trip_dir}  (or rotate)"
  fi
  rm -rf "$pub_dir"; mkdir -p "$pub_dir"

  if [ "$plaintext" = "1" ]; then
    warn "PLAINTEXT publish requested — the itinerary will be WORLD-READABLE, no passphrase."
    # The content guard runs BEFORE the human gate, not after: one insertion covers both
    # the interactive typed-PUBLISH limb and the ALLOW_PLAINTEXT non-interactive limb,
    # and asking someone to type PUBLISH and THEN refusing trains them to read the prompt
    # as noise. Nothing has been copied to the publish dir at this point.
    verify_publishable_content "$site_html" "$trip_dir" \
      || die "GUARD ABORTED publish — the rendered site carries content that must not be published, or the non-publishable class could not be determined. Nothing was pushed. Publish encrypted (drop --plaintext) or resolve the finding above."
    if [ -t 0 ]; then
      printf '  Type PUBLISH to confirm public, unencrypted publishing: '; read -r ans
      [ "${ans:-}" = "PUBLISH" ] || die "aborted — plaintext not confirmed."
    elif [ "${ALLOW_PLAINTEXT:-}" != "1" ]; then
      die "refusing non-interactive plaintext publish; re-run with ALLOW_PLAINTEXT=1 to override."
    fi
    cp "$site_html" "$pub_dir/index.html"
  else
    local passphrase enc boiler
    passphrase="$(get_passphrase "$trip_dir" 0)"
    info "Encrypting site (StatiCrypt — AES-256-CBC + HMAC, 600k PBKDF2)…"
    enc="$(encrypt_to_tmp "$site_html" "$passphrase")"
    info "Running pre-push verify guard…"
    boiler="$(make_boilerplate || true)"
    verify_ciphertext "$enc/index.html" "$site_html" "${boiler:+$boiler/index.html}" \
      || { rm -rf "$enc" "$boiler"; die "GUARD ABORTED publish — output is not verified ciphertext. Nothing was pushed."; }
    rm -rf "$boiler"
    cp "$enc/index.html" "$pub_dir/index.html"; rm -rf "$enc"
    ok "Guard passed — only ciphertext will be pushed."
  fi

  info "Creating per-trip repo and pushing…"
  ( cd "$pub_dir"
    git init -q
    git add index.html
    commit_noreply . "Publish trip site"
    git branch -M main
    gh repo create "$slug" --public --source=. --remote=origin --push >/dev/null
  )
  info "Enabling GitHub Pages…"
  gh api -X POST "repos/${owner}/${slug}/pages" -f "source.branch=main" -f "source.path=/" >/dev/null 2>&1 \
    || warn "Pages may already be enabled, or will activate shortly."

  # First publish establishes the baseline the #552 gate compares against. cmd_publish
  # itself stays UNGATED — it dies above when the per-trip repo already exists, so it
  # structurally cannot overwrite a published plan — but without this line the gate
  # would have no anchor on a freshly published trip and the FIRST unapproved change
  # after a publish would sail through. Recording is not gating.
  record_published_itinerary "$trip_dir" "$site_html"

  ok "Published: https://${owner}.github.io/${slug}/"
  if [ "$plaintext" != "1" ]; then
    printf '\n  Passphrase: \033[1;36m%s\033[0m  (saved to %s/.passphrase — git-ignored)\n' \
      "$(get_passphrase "$trip_dir" 0)" "$trip_dir"
    printf '  Share it over a private channel. To change it later: rotate %s\n\n' "$trip_dir"
  fi
}

ensure_pub_clone() { # <trip_dir> -> ensures <trip_dir>/.publish is the RIGHT per-trip repo
  local trip_dir="$1" pub_dir="$1/.publish" slug owner got
  slug="$(slug_for "$trip_dir")"; owner="$(gh api user --jq '.login')"
  if [ -d "$pub_dir/.git" ]; then
    # Reuse only if origin actually points at this trip's repo — never push to a
    # stale clone left over from a different trip.
    got="$(git -C "$pub_dir" remote get-url origin 2>/dev/null || true)"
    case "$got" in
      *"${owner}/${slug}"|*"${owner}/${slug}.git"|*":${slug}.git"|*"/${slug}.git") : ;;
      *) die "$pub_dir/origin is '$got', not ${owner}/${slug}. Remove $pub_dir and re-run." ;;
    esac
  else
    rm -rf "$pub_dir"
    gh repo clone "${owner}/${slug}" "$pub_dir" >/dev/null 2>&1 \
      || die "per-trip repo ${owner}/${slug} not found — run 'publish' first."
  fi
  printf '%s' "$pub_dir"
}

cmd_update() { # <trip_dir>
  local trip_dir="${1:?usage: update <trip-dir>}"
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"
  preflight; resolve_noreply_identity

  local site_html pub_dir passphrase enc owner slug boiler
  site_html="$(resolve_site_html "$trip_dir")"
  # THE ORGANIZER-CONFIRM GATE (#552, ADR-003 § Decision 2). Its position is exact
  # and load-bearing: after the render is resolved (the gate digests it) and BEFORE
  # ensure_pub_clone, which performs network I/O and can remove the publish dir. On
  # an abort nothing has been cloned, encrypted, copied or pushed — the same
  # discipline the plaintext gate states for itself in cmd_publish.
  require_change_confirmation "$trip_dir"
  pub_dir="$(ensure_pub_clone "$trip_dir")"
  passphrase="$(get_passphrase "$trip_dir" 0)"
  owner="$(gh api user --jq '.login')"; slug="$(slug_for "$trip_dir")"

  info "Re-encrypting edited site…"
  enc="$(encrypt_to_tmp "$site_html" "$passphrase")"
  info "Running pre-push verify guard…"
  boiler="$(make_boilerplate || true)"
  verify_ciphertext "$enc/index.html" "$site_html" "${boiler:+$boiler/index.html}" \
    || { rm -rf "$enc" "$boiler"; die "GUARD ABORTED update — output is not verified ciphertext. Nothing was pushed."; }
  rm -rf "$boiler"
  cp "$enc/index.html" "$pub_dir/index.html"; rm -rf "$enc"
  ok "Guard passed."

  ( cd "$pub_dir"
    git add index.html
    commit_noreply . "Update trip site"
    git push --quiet origin main
  )
  # The push succeeded, so this itinerary content IS what is published now. Recorded
  # here rather than earlier for that reason: a sidecar written before the push would
  # claim content a failed push never delivered, and the next republish would then
  # compare against a plan nobody can see.
  record_published_itinerary "$trip_dir" "$site_html"
  ok "Updated: https://${owner}.github.io/${slug}/  (changes appear behind the passphrase prompt)"
}

cmd_confirm() { # <trip_dir>
  local trip_dir="${1:?usage: confirm <trip-dir>}"
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"

  local site_html state pending rec tmp dg ans
  site_html="$(resolve_site_html "$trip_dir")"
  state="$(change_confirmation_state "$trip_dir")"

  # Refuse when there is no itinerary change in front of the organizer. A
  # confirmation recorded now would be a PRE-AUTHORISATION of an unseen future
  # change, and the gate would then wave through whatever the next bake produces.
  # Expressed through the resolver rather than through a second definition of
  # "pending", so there is exactly one answer to "has the plan moved?".
  [ "$state" != "none-pending" ] \
    || die "nothing to confirm for $trip_dir — the itinerary content of the outgoing render is the plan that is already published (or the trip has never been published). Confirmation binds to a change; there is none."

  # TTY-only, with no override flag, and the absence of the flag is the point.
  # ADR-007 §2 names the two existing flags that convert a refusal into a silent
  # pass for a non-interactive caller and states that bound is not negotiable by a
  # later slice. A third such override would be precisely the class of thing that
  # bound forbids, so this requirement is hard: no automation can attest a group's
  # consensus on the group's behalf.
  [ -t 0 ] || die "confirm requires a terminal — it records a human decision, and there is deliberately no flag to skip it. Run it yourself:  $(basename "$0") confirm ${trip_dir}"

  printf '\n  Confirming the itinerary change for: %s\n' "$trip_dir"
  printf '  Site render     : %s\n' "$site_html"
  pending="$(pending_change_path "$trip_dir")"
  if [ -r "$pending" ]; then
    printf '  Change summary  : %s\n' "$pending"
  else
    warn "no change summary at $pending — confirming from the render alone."
  fi
  printf '  Gate state      : %s\n' "$state"
  printf '  Type CONFIRM to record the group'"'"'s approval of this itinerary: '; read -r ans
  [ "${ans:-}" = "CONFIRM" ] || die "aborted — nothing confirmed. The published plan is unchanged."

  dg="$(itinerary_digest "$site_html")"
  [ -n "$dg" ] || die "could not read the itinerary content of $site_html — nothing was recorded."
  rec="$(change_confirmation_path "$trip_dir")"
  tmp="$(mktemp "${rec}.XXXXXX")" || die "could not stage the confirmation record beside $rec"
  printf 'digest=%s\nconfirmed=%s\n' "$dg" "$(_iso_now)" > "$tmp"
  mv -f "$tmp" "$rec"

  # The pending change summary is NOT deleted or promoted here. #551 reads it to
  # render the "change pending" state, and the writer never promotes its own output
  # — the promotion IS the organizer's decision, and this record is where that
  # decision lives. No post-republish cleanup is needed anywhere either: a later
  # re-bake moves the itinerary content, the digest stops matching, and the state
  # resolves `stale` on its own.
  ok "Confirmed. The next  $(basename "$0") update ${trip_dir}  will publish this itinerary; a further edit re-opens the gate."
}

cmd_rotate() { # <trip_dir> [--passphrase <new>]
  local trip_dir="${1:?usage: rotate <trip-dir> [--passphrase <new>]}"; shift || true
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"
  local pf="$trip_dir/.passphrase"
  if [ "${1:-}" = "--passphrase" ] && [ -n "${2:-}" ]; then
    printf '%s\n' "$2" > "$pf"; chmod 600 "$pf"
  else
    get_passphrase "$trip_dir" 1 >/dev/null   # force-generate a new one
  fi
  # Re-encrypt + push under the new passphrase FIRST; cmd_update dies on failure, so the
  # "rotated" confirmation below is only reached once the new ciphertext is actually live.
  cmd_update "$trip_dir"
  warn "Passphrase ROTATED — anyone you previously shared the site with must re-receive the new one."
  printf '\n  New passphrase: \033[1;36m%s\033[0m  (saved to %s)\n\n' "$(cat "$pf")" "$pf"
}

# ─────────────────────────────────────────────────────────────────────────────
# Portable date helpers (BSD/macOS first, then GNU/Linux). Echo empty on failure.
# ─────────────────────────────────────────────────────────────────────────────
# mtime epoch, or empty. The two stat dialects do not merely differ, they COLLIDE: BSD
# stat spells mtime `-f %m`, while on GNU coreutils `-f` is --file-system, so
# `stat -f %m FILE` there reports the FILESYSTEM for FILE, fails only on the bogus `%m`
# operand, and still writes to stdout — a bare `||` chain then concatenates that output
# with the fallback and returns something no arithmetic test can compare. Both forms are
# tried, and a result is accepted only when it is a bare integer.
#
# This surfaced through the freshness gate (#123): the gate read a non-comparable epoch,
# `_is_stale` errored rather than fired, and a stale model published on Linux while
# passing on macOS. The pre-existing I1 case asserted only that the output was NON-EMPTY,
# which filesystem noise satisfies, so it never caught it — see I1b.
_epoch_of_file() { # <file> -> mtime epoch on stdout, or nothing
  local e
  e="$(stat -f %m "$1" 2>/dev/null | head -1)"
  case "$e" in ''|*[!0-9]*) e="$(stat -c %Y "$1" 2>/dev/null | head -1)" ;; esac
  case "$e" in ''|*[!0-9]*) return 0 ;; esac
  printf '%s' "$e"
}
_epoch_of_iso()  { date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null || date -u -d "$1" +%s 2>/dev/null || true; }
# Now, in the same ISO-8601 UTC shape _epoch_of_iso parses back. One spelling that
# is identical on BSD and GNU date, so it does not join the dialect split above.
_iso_now()       { date -u +%Y-%m-%dT%H:%M:%SZ; }
_ymd_of_epoch()  { # <epoch> -> YYYY-MM-DD, or '-' when empty
  [ -n "${1:-}" ] || { printf '%s' '-'; return; }
  date -r "$1" +%Y-%m-%d 2>/dev/null || date -d "@$1" +%Y-%m-%d 2>/dev/null || printf '%s' '-'
}
# stale = a live site whose local build (edited epoch) is newer than the deployed commit.
_is_stale() { [ -n "${1:-}" ] && [ -n "${2:-}" ] && [ "$1" -gt "$2" ]; }

# ─────────────────────────────────────────────────────────────────────────────
# list — read-only inventory of every trip under ./trips/. Never writes/encrypts/pushes.
# ─────────────────────────────────────────────────────────────────────────────
cmd_list() { # (no args)
  [ -z "${1:-}" ] || die "list takes no arguments — run it from the repo root; it scans ./trips/."
  # Local first: scanning ./trips/ needs no GitHub. Only the publish-state columns do.
  [ -d trips ] || die "no ./trips/ directory here — trips/ ships with the repo, so this is probably not the repo root. cd there and re-run."
  # Publish state (STATUS/PUBLISHED/STALE) needs gh; the local inventory does not.
  # Degrade instead of dying, so list still works on a fresh clone with no gh.
  local owner="" online=0
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    owner="$(gh api user --jq '.login' 2>/dev/null || true)"
    [ -n "$owner" ] && online=1
  fi
  [ "$online" = "1" ] || warn "gh unavailable or not authenticated — showing local trips only. STATUS/PUBLISHED/STALE need: gh auth login"

  printf '\n\033[1m%-22s %-24s %-14s %-12s %-12s %s\033[0m\n' \
    "TRIP" "REPO" "STATUS" "PUBLISHED" "EDITED" "STALE"
  local any=0 trip_dir base slug site edited_epoch pub_iso pub_epoch status stale
  for trip_dir in trips/*/; do
    [ -d "$trip_dir" ] || continue
    trip_dir="${trip_dir%/}"; base="$(basename "$trip_dir")"; any=1
    slug="$(slug_for "$trip_dir" 2>/dev/null || printf '?')"
    site="$(ls -1t "$trip_dir"/outputs/*-travel-site.html 2>/dev/null | head -1 || true)"
    edited_epoch=""; [ -n "$site" ] && edited_epoch="$(_epoch_of_file "$site")"
    status="-"; pub_epoch=""
    if [ "$online" = "1" ]; then
      if gh repo view "$owner/$slug" >/dev/null 2>&1; then
        status="live"
        pub_iso="$(gh api "repos/$owner/$slug/commits?per_page=1" --jq '.[0].commit.committer.date' 2>/dev/null || true)"
        pub_epoch="$(_epoch_of_iso "$pub_iso")"
      else
        status="not published"
      fi
    fi
    # Stale = a live site whose local build is newer than the deployed commit.
    # Left as "-" (indeterminate) unless both timestamps are known.
    stale="-"
    if [ "$status" = "live" ] && [ -n "$edited_epoch" ] && [ -n "$pub_epoch" ]; then
      if _is_stale "$edited_epoch" "$pub_epoch"; then stale="⚠ stale"; else stale="ok"; fi
    fi
    printf '%-22s %-24s %-14s %-12s %-12s %s\n' \
      "$base" "$slug" "$status" "$(_ymd_of_epoch "$pub_epoch")" "$(_ymd_of_epoch "$edited_epoch")" "$stale"
  done
  [ "$any" = "1" ] || info "No trips yet — see trips/README.md to start one."
  printf '\n'
}

# ─────────────────────────────────────────────────────────────────────────────
# unpublish — take a published site down. Default DELETES the repo (IRREVERSIBLE);
# --disable-pages-only keeps the repo and just takes the site offline (reversible).
# Idempotent: a no-op (success) when the repo is already gone.
# ─────────────────────────────────────────────────────────────────────────────
cmd_unpublish() { # <trip_dir> [--disable-pages-only] [--yes]
  local trip_dir="${1:?usage: unpublish <trip-dir> [--disable-pages-only] [--yes]}"; shift || true
  local disable_only=0 assume_yes=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --disable-pages-only) disable_only=1 ;;
      --yes|-y)             assume_yes=1 ;;
      *) die "unknown option for unpublish: $1 (try --disable-pages-only or --yes)" ;;
    esac
    shift
  done
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"
  preflight_ro
  local owner slug ans
  owner="$(gh api user --jq '.login')" || die "could not read GitHub user."
  slug="$(slug_for "$trip_dir")"

  # Idempotent: nothing to take down if the repo isn't there.
  if ! gh repo view "$owner/$slug" >/dev/null 2>&1; then
    ok "unpublish: $owner/$slug does not exist — nothing to take down (no-op)."
    return 0
  fi

  if [ "$disable_only" = "1" ]; then
    info "Disabling GitHub Pages for $owner/$slug (repo kept)…"
    if gh api -X DELETE "repos/$owner/$slug/pages" >/dev/null 2>&1; then
      ok "Pages disabled — https://$owner.github.io/$slug/ is now offline. Repo $owner/$slug retained."
    else
      warn "Pages may already be disabled (nothing to do)."
    fi
    warn "To restore: re-enable Pages in the repo Settings → Pages (branch main / root)."
    warn "The repo name '$slug' is still public, and content may persist in third-party caches/clones."
    return 0
  fi

  # Default: delete the whole public repo (IRREVERSIBLE). Requires the delete_repo OAuth scope.
  # Here-string, not a pipeline: `grep -q` exits on first match, which under the `pipefail`
  # set at the top of this file can promote the writer's SIGPIPE death to the pipeline's
  # status and refuse a token that DOES carry the scope. The failure is safe — it aborts
  # rather than deleting — but it is a refusal the operator cannot act on, since the remedy
  # it prints has already been applied. A failing `gh` still reaches the same branch: the
  # substitution yields its diagnostic, the scope is absent from it, and grep returns 1.
  if ! grep -q 'delete_repo' <<<"$(gh auth status 2>&1)"; then
    warn "Deleting a repo needs the 'delete_repo' OAuth scope, which isn't present on your gh token."
    warn "Grant it once with:   gh auth refresh -h github.com -s delete_repo"
    die "unpublish aborted — missing delete_repo scope (or use --disable-pages-only to keep the repo)."
  fi
  if [ "$assume_yes" != "1" ]; then
    if [ -t 0 ]; then
      printf '  This DELETES the public repo %s/%s and its live site — \033[1mIRREVERSIBLE\033[0m.\n' "$owner" "$slug"
      printf '  Type the repo name (%s) to confirm: ' "$slug"; read -r ans
      [ "${ans:-}" = "$slug" ] || die "aborted — confirmation did not match '$slug'."
    else
      die "refusing a non-interactive delete without --yes. Re-run with --yes to confirm deleting $owner/$slug."
    fi
  fi
  info "Deleting $owner/$slug…"
  gh repo delete "$owner/$slug" --yes >/dev/null 2>&1 \
    || die "delete failed — check the delete_repo scope and that you own $owner/$slug."
  # The local mirror now points at a deleted repo; remove it so a later publish starts clean.
  rm -rf "$trip_dir/.publish" 2>/dev/null || true
  ok "Deleted $owner/$slug — the site and its public repo name are gone."
  warn "Content may persist in third-party caches/clones even after takedown."
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────────────────────────
usage() {
  # Print the header comment block (line 3 → the line before 'set -'), stripped of '# '.
  sed -n '3,/^set -/p' "$0" | sed '/^set -/d; s/^# \{0,1\}//'
  exit "${1:-0}"
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    publish)     cmd_publish   "$@" ;;
    update)      cmd_update    "$@" ;;
    confirm)     cmd_confirm   "$@" ;;
    rotate)      cmd_rotate    "$@" ;;
    list|status) cmd_list      "$@" ;;
    unpublish)   cmd_unpublish "$@" ;;
    -h|--help|help|"") usage 0 ;;
    *) die "unknown subcommand: $sub (try: publish | update | confirm | rotate | list | unpublish)" ;;
  esac
}

# Run only when executed directly; sourcing (e.g. for tests) exposes functions without dispatch.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
