#!/usr/bin/env bash
#
# publish-trip-site.sh — private-by-default publishing for travel-planner trip sites.
#
# Encrypts a generated trip site with StatiCrypt (AES-256-GCM, 600k PBKDF2-SHA256)
# and publishes ONLY the ciphertext to a per-trip PUBLIC GitHub repo with Pages.
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
  git -C "$repo_dir" -c "user.name=${NOREPLY_NAME}" -c "user.email=${NOREPLY_EMAIL}" \
    commit --quiet -m "$msg"
}

# ─────────────────────────────────────────────────────────────────────────────
# Passphrase generation and resolution.
# NOTE: With KDF iterations fixed at 600k, passphrase entropy IS the security margin.
# Default = 6 dictionary words (~77 bits, human-shareable). Falls back to base64 if no
# system word list. Override the policy here if you want longer/stronger passphrases.
# ─────────────────────────────────────────────────────────────────────────────
gen_passphrase() {
  local wl=/usr/share/dict/words
  if [ -r "$wl" ]; then
    # 6 random lowercase words joined by hyphens (portable: awk, no GNU shuf).
    awk 'BEGIN{srand()} /^[a-z]{4,8}$/{w[n++]=$0}
         END{ if(n<6) exit 1; for(i=0;i<6;i++) printf "%s%s",(i?"-":""),w[int(rand()*n)]; print "" }' "$wl" 2>/dev/null \
      || openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 28
  else
    openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 28
  fi
}

get_passphrase() { # <trip_dir> <force_new:0|1>
  local trip_dir="$1" force_new="${2:-0}" pf="$1/.passphrase"
  if [ -n "${STATICRYPT_PASSWORD:-}" ]; then printf '%s' "$STATICRYPT_PASSWORD"; return; fi
  if [ "$force_new" != "1" ] && [ -r "$pf" ]; then printf '%s' "$(cat "$pf")"; return; fi
  local new; new="$(gen_passphrase)"
  printf '%s\n' "$new" > "$pf"; chmod 600 "$pf"
  printf '%s' "$new"
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
        npx --yes staticrypt@3 index.html --short --config false -d "$enc" ) >"$log" 2>&1; then
    warn "staticrypt failed:"; sed 's/^/    /' "$log" >&2
    rm -rf "$stage" "$enc"; rm -f "$log"; die "encryption step failed."
  fi
  rm -rf "$stage"; rm -f "$log"
  [ -f "$enc/index.html" ] || die "encryption produced no $enc/index.html"
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
#   • What proves "encrypted"? (StatiCrypt sentinel? absence of the body? entropy?)
#   • Which plaintext tokens must NEVER appear? Tokens are derived from the source's
#     VISIBLE TEXT (markup/scripts stripped) and filtered to distinctive itinerary
#     terms (an uppercase/digit, not generic markup words) — because naive markup
#     tokens like "DOCTYPE" appear in the encrypted shell too and abort every publish.
#   • How aggressive is fail-closed? A false abort is safe; a false pass leaks. The
#     STOPLIST below trades a little leak-coverage on those exact words for usability;
#     widen or narrow it to taste.
#
# Below is a working DEFAULT. Replace the body with your own predicate to taste.
verify_ciphertext() { # <enc> <src>
  local enc="$1" src="$2" tok
  local stoplist='^(doctype|html|head|body|title|meta|link|script|style|charset|viewport|password|passphrase|protected|loading|decrypt|please|enter|button|submit|window|document|function|staticrypt|leaflet|google|fonts)$'
  # (a) Positive: the StatiCrypt shell must be present.
  grep -qi 'staticrypt' "$enc" || { warn "guard: StatiCrypt markers absent in output"; return 1; }
  # (b) Positive: a passphrase prompt must be present (the gate the viewer hits).
  grep -qiE 'password|passphrase' "$enc" || { warn "guard: no passphrase prompt in output"; return 1; }
  # (c) Negative: NO distinctive plaintext token from the source's visible text may
  #     appear anywhere in the published bytes (we grep the RAW output, scripts included).
  while IFS= read -r tok; do
    [ -z "$tok" ] && continue
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

  local site_html slug pub_dir owner
  site_html="$(resolve_site_html "$trip_dir")"
  slug="$(slug_for "$trip_dir")"
  pub_dir="$trip_dir/.publish"
  owner="$(gh api user --jq '.login')"
  rm -rf "$pub_dir"; mkdir -p "$pub_dir"

  if [ "$plaintext" = "1" ]; then
    warn "PUBLISHING PLAINTEXT (privacy opt-out) — the itinerary will be world-readable."
    cp "$site_html" "$pub_dir/index.html"
  else
    local passphrase enc
    passphrase="$(get_passphrase "$trip_dir" 0)"
    info "Encrypting site (StatiCrypt, 600k PBKDF2)…"
    enc="$(encrypt_to_tmp "$site_html" "$passphrase")"
    cp "$enc/index.html" "$pub_dir/index.html"; rm -rf "$enc"
    info "Running pre-push verify guard…"
    verify_ciphertext "$pub_dir/index.html" "$site_html" || die "GUARD ABORTED publish — output is not verified ciphertext. Nothing was pushed."
    ok "Guard passed — only ciphertext will be pushed."
  fi

  info "Creating per-trip repo and pushing…"
  ( cd "$pub_dir"
    git init -q
    git add index.html
    git -C . -c "user.name=${NOREPLY_NAME}" -c "user.email=${NOREPLY_EMAIL}" commit --quiet -m "Publish trip site"
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

ensure_pub_clone() { # <trip_dir> -> ensures <trip_dir>/.publish is the per-trip repo
  local trip_dir="$1" pub_dir="$1/.publish" slug owner
  slug="$(slug_for "$trip_dir")"; owner="$(gh api user --jq '.login')"
  if [ ! -d "$pub_dir/.git" ]; then
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
  cp "$enc/index.html" "$pub_dir/index.html"; rm -rf "$enc"
  info "Running pre-push verify guard…"
  verify_ciphertext "$pub_dir/index.html" "$site_html" || die "GUARD ABORTED update — output is not verified ciphertext. Nothing was pushed."
  ok "Guard passed."

  ( cd "$pub_dir"
    if git diff --quiet -- index.html 2>/dev/null && git diff --cached --quiet -- index.html 2>/dev/null; then
      info "No ciphertext change — site is already up to date."; exit 0
    fi
    git add index.html
    git -C . -c "user.name=${NOREPLY_NAME}" -c "user.email=${NOREPLY_EMAIL}" commit --quiet -m "Update trip site"
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
  warn "Passphrase ROTATED — anyone you previously shared the site with must re-receive the new one."
  cmd_update "$trip_dir"
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
