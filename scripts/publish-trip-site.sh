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
  command -v npx >/dev/null 2>&1 || die "npx not found (install Node.js — StatiCrypt runs via npx)."
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

# ── the single home of the non-publishable class ─────────────────────────────
# nonpublishable_values <trip_dir>
#   stdout : one TAB-separated record per line —  <member> <field> <rule> <value>
#            <member> one of: passport | third-party  (the two members the validator
#                     profile-privacy check names today)
#            <field>  a DE-IDENTIFIED locator, e.g. "entry 3 / Specific". Never the
#                     traveler name: a third-party entry NAME is itself a member of
#                     this class, so reporting it would leak what the guard protects.
#            <rule>   one of: conjunctive | phrase | token
#   return : 0  class enumerated (possibly EMPTY — a determinate measurement)
#            2  UNDETERMINED — the class could not be determined; caller must abort
#
# The match RULE is assigned HERE, alongside membership, because they are one decision.
# The predicate consumes (member, field, rule, value) and knows nothing else. THIS is
# the seam #278 re-keys: replacing the membership rule below with "any field carrying
# the declared publishability attribute" is a change to this body only — the stdout
# contract, the return contract, the predicate, the call site and every test assertion
# are unchanged.
#
# CD-4 — the [THIRD-PARTY] member is an ENTRY DENYLIST, not a field allowlist.
# The shipped guard enumerated exactly two things per third-party entry: the heading
# name, and the value of a line labelled `Specific:`. Every other field DEFAULT-ALLOWED.
# reference/data-model.md:170 states the opposite polarity outright — "The bound is the
# entry class, not a list of fields, so it holds for every facet below and for any facet
# a later release adds ... there is no default-allow outside it" — and #278 would have
# inherited the allowlist shape when it re-keys this seam. So: under a third-party entry,
# EVERY stated field value is in class, minus the short non-member list below.
#
# The label binding was independently wrong, which is why the polarity fix alone is not
# enough. `Specific:` is the PROFILE label. Measured over this repository: the
# line-anchored form occurs 3x in reference/data-model.md — all three under
# `# Traveler — Jordan` / `# Traveler — Pat`, i.e. `travelers/<name>.md` — and 2x in
# templates/traveler-intake.template.md, which governs that same profile. It occurs 0x in
# agents/00-enrichment.md, the spec that WRITES this file, and 0x in agents/06-validator.md,
# which defines the class. The derived model's own worked example (data-model.md:266-283)
# writes a need as `- Need → Hard Constraints "<c>" (Applies to: <n>); specific: <v>.` —
# a mid-line lowercase label, 4 occurrences, none of them line-anchored. The guard was
# parsing the derived file with the profile's label.
#
# And the third-party need's own line shape is UNDERSPECIFIED, which is the finding that
# decides the design. A third-party need cannot carry the first-party derived shape at
# all: data-model.md:143 bars it from ever escalating to a trip-level constraint or onto
# an `Applies to:` roster, and 06-validator.md:231-243 says it "by design has no governing
# trip-level constraint to key to". So the link head and the Applies-to are both
# unavailable to it, and what remains — a category and a specific — is serialized nowhere.
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
#     data-model.md:139 — "This is the link, **never a copy** of the constraint text."
#     Its target lives in trip-context.md, which IS publish-bound and legitimately
#     rendered; keying on it would abort on correct published content.
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
    #     standalone profile form. reference/data-model.md:139 states it outright:
    #     "This is the link, never a copy of the constraint text." The constraint it
    #     points at lives in trip-context.md, which IS publish-bound and legitimately
    #     rendered, so keying on the link text would abort on correct published content.
    #     data-model.md:143 also bars a third-party person from an Applies-to roster, so
    #     on this member the field is doubly not a captured value.
    #   - the quoted constraint name in the derived need line head, for the same reason:
    #     it is that same link target.
    #   - a value that reduces entirely to the closed need-category enum. That enum is
    #     the SCHEMA vocabulary, not a traveler captured value — the same structural
    #     exclusion as the "Passport:" LABEL, and it is what stops a Category line
    #     aborting every publish whose itinerary says rest, timing, or other.
    #     The test is FIELD-BLIND: enum_only takes only the value text and is passed no
    #     field, so it applies under ANY label, not only Category. That is deliberate,
    #     and narrowing it to Category is the wrong fix — see ADR-008 coverage boundary.
    # Everything else under the entry is IN. reference/data-model.md:170 — "The bound is
    # the entry class, not a list of fields ... there is no default-allow outside it."
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

# The closed need-category enum (agents/00-enrichment.md:349-350) plus the schema words a
# need line is written with. This is SCHEMA vocabulary — it is not a list of names and it
# is not _GUARD_STOP, which is normalization vocabulary shared by all three match rules.
# Kept separate and used in ONE place: deciding that a value made only of these states no
# traveler fact. Extending it narrows the class, so it stays exactly the documented enum.
_GUARD_NEED_ENUM=' need needs category categories heat mobility dietary health '\
'rest budget cap timing sensory other specific '

nonpublishable_values() { # <trip_dir> [site_html]
  local trip_dir="${1:-}" site_html="${2:-}" model out rc
  local model_epoch profile_epoch render_epoch pf pout prc had_profiles=0
  if [ -z "$trip_dir" ]; then
    warn "guard: the non-publishable class needs a trip dir and none was given"; return 2
  fi
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

  out="$(awk -v F="$GUARD_NGRAM" -v ENUM="$_GUARD_NEED_ENUM" "$_GUARD_AWK_HELPERS"'
    BEGIN { entries = 0; idx = 0; tp = 0; live = 0; tprecs = 0; sawmark = 0; supersede = 0 }
    # The raw text is inspected for the mark BEFORE any per-line handling, so the
    # orphaned-mark backstop in END sees marks the parse may fail to resolve.
    /\[THIRD-PARTY\]/ { sawmark = 1 }
    # A supersession removes both marks by design (00-enrichment.md:456-466). Recording
    # that it happened is what separates a sanctioned provenance change from the bad
    # merge the same passage forbids; the shell limb below verifies it is supported.
    tolower($0) ~ /supersed/ && tolower($0) ~ /third-party/ { supersede = 1 }
    /^##[ \t]/ {
      head = $0; sub(/^##[ \t]+/, "", head)
      nm = clean(head)
      key = tolower(nm); gsub(/[^a-z0-9]/, "", key)
      if (key == "updatesignals") { live = 0; tp = 0; next }   # structural section, not a person
      entries++; idx = entries; live = 1
      tp = (index(head, "[THIRD-PARTY]") > 0)
      if (tp && stated(nm)) { printf "third-party\tentry %d / Name\ttoken\t%s\n", idx, nm; tprecs++ }
      next
    }
    /^###/    { next }                   # deeper headings stay INSIDE the entry
    /^#[ \t]/ { live = 0; tp = 0; next } # the file title ends any entry
    live == 1 {
      raw = $0
      lab = $0
      sub(/^[ \t]*[-*+][ \t]+/, "", lab)
      gsub(/\*\*/, "", lab)
      sub(/^[ \t]+/, "", lab)
      if (lab ~ /^[Pp]assport[ \t]*:/) {
        val = lab; sub(/^[^:]*:[ \t]*/, "", val); val = clean(val)
        if (stated(val)) printf "passport\tentry %d / Passport\tconjunctive\t%s\n", idx, val
        next
      }
      # ── the [THIRD-PARTY] member: an ENTRY DENYLIST, not a field allowlist ──────
      # The mark is read at BOTH granularities and the two are a UNION. The heading
      # limb alone was the shipped defect: 00-enrichment.md:407 requires the mark on
      # "every value sourced this way", and :468-473 names heading mark-stripping as a
      # KNOWN agent error which "silently strip[s] the key the publication guard
      # depends on" — the exact state in which a heading-only read enumerates zero
      # third-party records and publishes.
      #
      # ORDERING IS LOAD-BEARING: the value-level mark is read off the RAW line, before
      # clean() runs. clean() deletes every bracketed provenance mark as metadata, so a
      # mark consulted after it has already been erased.
      vmark = (index(raw, "[THIRD-PARTY]") > 0)
      if (tp || vmark) {
        val = tp_value(lab)
        if (stated(val)) {
          # Rule assignment travels with the record and is made HERE, alongside
          # membership, because the two are one decision. It keys off the VALUE, never
          # off a field label — the label shape of a third-party need is precisely what
          # the corpus does not specify (see the coverage-boundary note above).
          #   >= F tokens : prose. The phrase rule catches the verbatim and the
          #                 de-attributed carry-through.
          #   <  F tokens : the phrase rule would exit 3 (below its keyability floor)
          #                 and every publish of the trip would abort as UNDETERMINED,
          #                 forever, with no remedy — the unusable fail-closed control
          #                 the token-branch note calls fail-open in practice. The token
          #                 rule is determinate on a short value, and its is_stop /
          #                 exit-4 path already handles a value with nothing distinctive
          #                 in it. Mitigated, not accepted.
          n = wordcount(val)
          printf "third-party\tentry %d / field %d\t%s\t%s\n", idx, ++fno[idx], \
                 (n >= F ? "phrase" : "token"), val
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
    4) warn "guard: $model carries a [THIRD-PARTY] mark that resolved to no class record — the mark is orphaned or the entry did not parse, so the class is UNDETERMINED, not empty"; return 2 ;;
    5)
      # A recorded third-party supersession is sanctioned ONLY by the person having
      # filed their own profile — that is the event that triggers it
      # (00-enrichment.md:456-458), and their own file is what becomes authoritative.
      # A supersession claimed with no profile anywhere is unsupported: the marks are
      # gone and nothing backs the drop, which is indistinguishable from the bad merge
      # :467-473 forbids. Undetermined, never a pass.
      # had_profiles is the freshness gate's own glob result, computed above — reused
      # rather than re-scanned. Deliberately not `find -maxdepth 1 -print -quit`: that
      # is the same BSD/GNU divergence class as the _epoch_of_file defect this release
      # already tripped over, and the shell glob has one behaviour everywhere.
      if [ "$had_profiles" -ne 1 ]; then
        warn "guard: $model records a [THIRD-PARTY] supersession but no per-traveler profile exists to support it — the provenance change is unverifiable, so the class is UNDETERMINED"; return 2
      fi
      ;;
    *) warn "guard: $model could not be parsed (exit $rc) — the class is undetermined"; return 2 ;;
  esac

  # ── first-party sources (CD-3) ─────────────────────────────────────────────
  # The Passport member, read from the authoritative per-traveler files rather than only
  # from the projection of them. The label shape is the same one the model parse binds to
  # — templates/traveler-intake.template.md writes it as "- **Passport:** <country>,
  # valid through <month year>" — so the same two lines of label handling serve both, and
  # the placeholder brackets of an unfilled form are removed by clean() and rejected by
  # stated(). The locator is "profile N", never the file name: a file under travelers/ is
  # named for the traveler, and naming them would leak on the same axis this guard
  # protects. N is the position in the shell's sorted glob, so it is stable between runs.
  if [ "$had_profiles" -eq 1 ]; then
    pout="$(awk "$_GUARD_AWK_HELPERS"'
      FNR == 1 { idx++ }
      {
        lab = $0
        sub(/^[ \t]*[-*+][ \t]+/, "", lab)
        gsub(/\*\*/, "", lab)
        sub(/^[ \t]+/, "", lab)
        if (lab ~ /^[Pp]assport[ \t]*:/) {
          val = lab; sub(/^[^:]*:[ \t]*/, "", val); val = clean(val)
          if (stated(val)) printf "passport\tprofile %d / Passport\tconjunctive\t%s\n", idx, val
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
  ok "Updated: https://${owner}.github.io/${slug}/  (changes appear behind the passphrase prompt)"
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
  if ! gh auth status 2>&1 | grep -q 'delete_repo'; then
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
    rotate)      cmd_rotate    "$@" ;;
    list|status) cmd_list      "$@" ;;
    unpublish)   cmd_unpublish "$@" ;;
    -h|--help|help|"") usage 0 ;;
    *) die "unknown subcommand: $sub (try: publish | update | rotate | list | unpublish)" ;;
  esac
}

# Run only when executed directly; sourcing (e.g. for tests) exposes functions without dispatch.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
