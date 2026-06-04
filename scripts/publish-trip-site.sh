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
#   publish-trip-site.sh publish <trip-dir> [--plaintext]
#   publish-trip-site.sh update  <trip-dir>
#   publish-trip-site.sh rotate  <trip-dir> [--passphrase <new>]
#
#   <trip-dir>     A trip working dir, e.g. trips/tokyo-2026 (contains outputs/<name>-travel-site.html)
#   --plaintext    Opt OUT of privacy: publish the unencrypted site (default is encrypted).
#   --passphrase   Supply a specific new passphrase for rotate (else one is generated).
#
# Passphrase resolution (in order): $STATICRYPT_PASSWORD, then <trip-dir>/.passphrase,
# else a strong one is generated and saved to <trip-dir>/.passphrase (git-ignored, chmod 600).
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
preflight() {
  command -v npx >/dev/null 2>&1 || die "npx not found (install Node.js — StatiCrypt runs via npx)."
  command -v gh  >/dev/null 2>&1 || die "gh (GitHub CLI) not found."
  gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"
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

slug_for() { printf '%s-trip' "$(basename "$1")"; }   # trips/tokyo-2026 -> tokyo-2026-trip

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

# ═════════════════════════════════════════════════════════════════════════════
# verify_ciphertext — THE PRE-PUSH SAFETY GUARD  ◀── your high-judgment function
# ═════════════════════════════════════════════════════════════════════════════
# This is the single mechanism standing between "private site" and "accidentally
# re-published my plaintext itinerary." It is called immediately before every push
# and MUST be FAIL-CLOSED: return 0 only when the output is provably safe to publish;
# return non-zero for ANY doubt, which aborts the push.
#
# Contract:
#   verify_ciphertext <encrypted_index_html> <plaintext_source_html>
#   return 0  -> verified ciphertext, safe to push
#   return 1  -> NOT safe, abort (do not push)
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
verify_ciphertext() { # <enc> <src>
  local enc="$1" src="$2" tok enc_visible
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
  #     may appear anywhere in the published bytes (raw, scripts included).
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    if grep -qiF -- "$tok" "$enc"; then
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
cmd_publish() { # <trip_dir> [--plaintext]
  local trip_dir="${1:?usage: publish <trip-dir> [--plaintext]}"; shift || true
  local plaintext=0; [ "${1:-}" = "--plaintext" ] && plaintext=1
  [ -d "$trip_dir" ] || die "no such trip dir: $trip_dir"
  preflight; resolve_noreply_identity

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
    local passphrase enc
    passphrase="$(get_passphrase "$trip_dir" 0)"
    info "Encrypting site (StatiCrypt — AES-256-CBC + HMAC, 600k PBKDF2)…"
    enc="$(encrypt_to_tmp "$site_html" "$passphrase")"
    info "Running pre-push verify guard…"
    verify_ciphertext "$enc/index.html" "$site_html" \
      || { rm -rf "$enc"; die "GUARD ABORTED publish — output is not verified ciphertext. Nothing was pushed."; }
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

  local site_html pub_dir passphrase enc owner slug
  site_html="$(resolve_site_html "$trip_dir")"
  pub_dir="$(ensure_pub_clone "$trip_dir")"
  passphrase="$(get_passphrase "$trip_dir" 0)"
  owner="$(gh api user --jq '.login')"; slug="$(slug_for "$trip_dir")"

  info "Re-encrypting edited site…"
  enc="$(encrypt_to_tmp "$site_html" "$passphrase")"
  info "Running pre-push verify guard…"
  verify_ciphertext "$enc/index.html" "$site_html" \
    || { rm -rf "$enc"; die "GUARD ABORTED update — output is not verified ciphertext. Nothing was pushed."; }
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
# Dispatch
# ─────────────────────────────────────────────────────────────────────────────
usage() {
  sed -n '3,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    publish) cmd_publish "$@" ;;
    update)  cmd_update  "$@" ;;
    rotate)  cmd_rotate  "$@" ;;
    -h|--help|help|"") usage 0 ;;
    *) die "unknown subcommand: $sub (try: publish | update | rotate)" ;;
  esac
}

# Run only when executed directly; sourcing (e.g. for tests) exposes functions without dispatch.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
