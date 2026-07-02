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
#   publish-trip-site.sh list                       (read-only inventory of all trips under trips/)
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
_epoch_of_file() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || true; }
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
  preflight_ro
  [ -d trips ] || die "no ./trips/ directory here — run list from the repo root."
  local owner; owner="$(gh api user --jq '.login')" || die "could not read GitHub user."

  printf '\n\033[1m%-22s %-24s %-14s %-12s %-12s %s\033[0m\n' \
    "TRIP" "REPO" "STATUS" "PUBLISHED" "EDITED" "STALE"
  local any=0 trip_dir base slug site edited_epoch pub_iso pub_epoch status stale
  for trip_dir in trips/*/; do
    [ -d "$trip_dir" ] || continue
    trip_dir="${trip_dir%/}"; base="$(basename "$trip_dir")"; any=1
    slug="$(slug_for "$trip_dir" 2>/dev/null || printf '?')"
    site="$(ls -1t "$trip_dir"/outputs/*-travel-site.html 2>/dev/null | head -1 || true)"
    edited_epoch=""; [ -n "$site" ] && edited_epoch="$(_epoch_of_file "$site")"
    if gh repo view "$owner/$slug" >/dev/null 2>&1; then
      status="live"
      pub_iso="$(gh api "repos/$owner/$slug/commits?per_page=1" --jq '.[0].commit.committer.date' 2>/dev/null || true)"
      pub_epoch="$(_epoch_of_iso "$pub_iso")"
    else
      status="not published"; pub_epoch=""
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
  [ "$any" = "1" ] || info "no trips found under ./trips/."
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
