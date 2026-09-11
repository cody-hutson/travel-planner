#!/usr/bin/env bash
#
# sync-commands.sh — copy the trip commands to a user-scope commands directory.
#
# The five trip commands live in this repository at .claude/commands/. Claude Code also
# reads a user-scope commands directory, and a copy placed there appears in the command
# picker from any working directory. This script is what puts them there and what keeps
# them current, and it is a LIBRARY FIRST and a CLI second: scripts/test-command-sync.sh
# sources it, exactly as scripts/test-artifact-schema.sh sources scripts/validate-artifacts.sh
# and scripts/test-publish-guard.sh sources scripts/publish-trip-site.sh. That is the
# repo's pattern and it points one way — a suite sources a production script, never the
# reverse.
#
#   ./scripts/sync-commands.sh [--root <dir>] [--dest <dir>] [--check | --apply]
#
# ── WHY THIS SCRIPT EXISTS AT ALL, WHICH IS NOT THE OBVIOUS REASON ───────────────
# It is not primarily a convenience. A user-scope copy is a SECOND COPY of a file whose
# in-repo original changes, and nothing in this repository could previously observe the
# two diverging: the copies sit outside the working tree, so no guard suite, no CI job and
# no git status can reach them. A user running a months-old copy sees behaviour this
# repository does not implement and has no way to discover why. `--check` is the answer to
# that, and it is the DEFAULT for the same reason: the question "have my copies drifted"
# must be answerable without risking a write.
#
# ── THE VARIABLE THIS SCRIPT PRINTS, AND WHY IT PRINTS IT EVERY RUN ──────────────
# A synced command resolves the trip store through TRAVEL_PLANNER_ROOT, falling back to
# the launching project when that variable is unset. From a foreign working directory the
# fallback names the wrong root, so the copy needs the variable to be useful — and this
# script is the one surface that KNOWS the correct value, because it was just handed the
# checkout root it is copying from. So it prints the export line on every run, `--check`
# included. Discovery is the point: a user who never reads this header still meets the
# line the first time they run the script, and meets it again in the STOP message the
# commands themselves emit when the root does not resolve.
#
# ── WHAT IT DELIBERATELY DOES NOT DO ─────────────────────────────────────────────
#   IT DOES NOT EDIT A SHELL PROFILE. Writing into a user's shell startup file is
#   un-idempotent in practice, unguardable from here, and outside anything this repository
#   can assert about a machine it does not own. The line is printed; the user places it.
#
#   IT DOES NOT SUBSTITUTE THE ROOT AT COPY TIME. The script could rewrite the expansion
#   to a literal path as it copies, and the user would then need to set nothing. That is
#   rejected on three grounds, and the first is the one that decides it: the installed copy
#   would differ from the repo copy BY DESIGN, so sync could no longer be verified by byte
#   comparison and drift would become undetectable — which is the exact failure this script
#   exists to end. It would also write a machine-specific path into a file, and it would
#   create a second source of truth for the block text, which is the condition the contract
#   guard's self-check exists to prevent.
#
# ── THE BACKUP LOCATION IS A DESIGN DECISION, NOT A DETAIL ───────────────────────
# `--apply` preserves the version it is about to replace before replacing it. Those backups
# land OUTSIDE the destination directory, never in a dot-directory inside it. A backup kept
# beside the commands would be a markdown file in a directory whose contents are read as
# commands, and whether the runtime's discovery skips a dot-directory there is not
# established anywhere in this repository. This design does not rest on an unestablished
# property when an adjacent directory costs nothing.
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# IN SCOPE — the command files, and only those: <root>/.claude/commands/trip*.md copied to
# <dest>/. It reads nothing under trips/, copies nothing else, and writes nowhere but
# <dest> and the backup directory.
# OUT OF SCOPE, by name:
#   WHETHER THE RUNTIME READS <dest>. This script copies files to a directory. That the
#   command picker reads that directory is a property of the runtime, not of this script,
#   and a green `--check` is not evidence of it.
#   THE SCRIPT-INVOKING VERBS. A synced copy resolves the TRIP STORE from any working
#   directory. The verbs that shell out to scripts/publish-trip-site.sh need the repository
#   working tree itself — templates, git, the guard surface — and resolving a path does not
#   hand them one. Those verbs resolve the trip and then stop at the script boundary.
#   THIS SCRIPT'S OWN SHELL QUALITY. No CI job shellchecks a standalone script under
#   scripts/; actionlint lints workflow-embedded shell only. Stated so a green is not read
#   as more than it is.
#
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────────
# Defaults. Resolved at source time, overridable per call — the suite re-points both.
# ─────────────────────────────────────────────────────────────────────────────────

# The repository root this script ships inside. A plain assignment rather than an
# environment default: an env-defaulted root would let a caller point the copy source
# somewhere else from outside the repository, and the one thing a sync must be certain of
# is what it is syncing FROM. The --root flag is the supported override, and it is
# explicit at the call site rather than ambient.
SC_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SC_CMD_SUBDIR='.claude/commands'
SC_PATTERN='trip*.md'
SC_BACKUP_SUBDIR='.claude/trip-command-backups'
SC_ROOT_VAR='TRAVEL_PLANNER_ROOT'

# The destination default is the user-scope commands directory. Computed rather than
# written so a HOME-less environment produces an empty default that the argument check
# below reports, instead of a path beginning with a stray separator.
sc_default_dest() {
  if [ -n "${HOME:-}" ]; then printf '%s/.claude/commands' "$HOME"; fi
}

sc_default_backup_base() {
  if [ -n "${HOME:-}" ]; then printf '%s/%s' "$HOME" "$SC_BACKUP_SUBDIR"; fi
}

# ─────────────────────────────────────────────────────────────────────────────────
# Primitives
# ─────────────────────────────────────────────────────────────────────────────────

# The command files present at <root>, one repo-relative path per line, sorted so two
# runs over one tree emit one order. Emits nothing when the directory is absent — the
# caller distinguishes "no source directory" from "no matching file", because those are
# different facts and a single verdict covering both would say less than either.
sc_source_files() {  # <root>
  local root="$1" d f
  d="$root/$SC_CMD_SUBDIR"
  [ -d "$d" ] || return 0
  for f in "$d"/$SC_PATTERN; do
    [ -e "$f" ] || continue
    printf '%s\n' "${f##*/}"
  done | LC_ALL=C sort
}

# Per-file state against <dest>. One of three, and they are three facts rather than two:
#   IDENTICAL  the destination holds a byte-identical copy
#   DIVERGED   the destination holds a copy whose bytes differ
#   ABSENT     the destination holds no file of that name
# ABSENT is not a kind of DIVERGED. A first install and a stale install need different
# things said about them, and collapsing them would report every first install as drift.
sc_file_state() {  # <root> <dest> <basename>
  local src="$1/$SC_CMD_SUBDIR/$3" dst="$2/$3"
  if [ ! -e "$dst" ]; then printf 'ABSENT'
  elif cmp -s "$src" "$dst"; then printf 'IDENTICAL'
  else printf 'DIVERGED'
  fi
}

# The export line a user adds to their shell profile. One home for the string, because it
# is printed by two arms and shown in a third place.
sc_export_line() {  # <root>
  printf 'export %s=%s' "$SC_ROOT_VAR" "$1"
}

# ─────────────────────────────────────────────────────────────────────────────────
# The two modes
# ─────────────────────────────────────────────────────────────────────────────────

# REPORT ONLY. This function writes nothing anywhere, and the suite asserts that by
# comparing the whole destination tree before and after — a claim about behaviour is worth
# less than a measurement of it.
sc_check() {  # <root> <dest>
  local root="$1" dest="$2" f st
  local n=0 ident=0 diverged=0 absent=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n+1))
    st="$(sc_file_state "$root" "$dest" "$f")"
    printf '%s %s\n' "$st" "$f"
    case "$st" in
      IDENTICAL) ident=$((ident+1)) ;;
      DIVERGED)  diverged=$((diverged+1)) ;;
      ABSENT)    absent=$((absent+1)) ;;
    esac
  done <<EOF
$(sc_source_files "$root")
EOF
  printf 'POPULATION source=%s identical=%s diverged=%s absent=%s\n' "$n" "$ident" "$diverged" "$absent"
  # An empty source population is a real measurement of the tree and not an error — but it
  # is also not evidence that anything is in sync, and it must not read as one. The sibling
  # suites render this verdict for the same reason.
  if [ "$n" -eq 0 ]; then
    printf 'VACUOUS no command file matched %s under %s/%s, so nothing was compared. A green over zero files is vacuous, not passing\n' \
      "$SC_PATTERN" "$root" "$SC_CMD_SUBDIR"
  fi
  [ "$diverged" -eq 0 ] && [ "$absent" -eq 0 ]
}

# PRESERVE, THEN COPY. The order is the whole of the safety property: a copy that fails
# after the backup leaves the user with both versions, while a backup that fails after the
# copy leaves them with neither.
sc_apply() {  # <root> <dest> <backup-base>
  local root="$1" dest="$2" bbase="$3" f st stamp bdir
  local n=0 copied=0 kept=0 preserved=0 rc=0
  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  bdir="$bbase/$stamp"

  if ! mkdir -p "$dest"; then
    printf 'ERROR the destination directory could not be created: %s\n' "$dest"
    return 1
  fi

  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n+1))
    st="$(sc_file_state "$root" "$dest" "$f")"
    if [ "$st" = "IDENTICAL" ]; then
      # Idempotence lives here. An unchanged file is not re-copied and, crucially, is not
      # backed up — so a second --apply over a synced tree creates no backup directory at
      # all, and the backup tree does not grow one entry per invocation.
      kept=$((kept+1))
      printf 'UNCHANGED %s\n' "$f"
      continue
    fi
    if [ "$st" = "DIVERGED" ]; then
      if ! mkdir -p "$bdir"; then
        printf 'ERROR the backup directory could not be created, so nothing was overwritten: %s\n' "$bdir"
        return 1
      fi
      if ! cp "$dest/$f" "$bdir/$f"; then
        printf 'ERROR the existing copy could not be preserved, so it was not overwritten: %s\n' "$f"
        rc=1
        continue
      fi
      preserved=$((preserved+1))
    fi
    if cp "$root/$SC_CMD_SUBDIR/$f" "$dest/$f"; then
      copied=$((copied+1))
      printf '%s %s\n' "$([ "$st" = "ABSENT" ] && printf 'INSTALLED' || printf 'UPDATED')" "$f"
    else
      printf 'ERROR the copy failed: %s\n' "$f"
      rc=1
    fi
  done <<EOF
$(sc_source_files "$root")
EOF

  printf 'POPULATION source=%s copied=%s unchanged=%s preserved=%s\n' "$n" "$copied" "$kept" "$preserved"
  if [ "$preserved" -gt 0 ]; then
    printf 'PRESERVED %s file(s) were kept before being overwritten, under %s\n' "$preserved" "$bdir"
  else
    printf 'PRESERVED nothing was overwritten, so no backup directory was created\n'
  fi
  if [ "$n" -eq 0 ]; then
    printf 'VACUOUS no command file matched %s under %s/%s, so nothing was copied\n' \
      "$SC_PATTERN" "$root" "$SC_CMD_SUBDIR"
  fi
  return $rc
}

# ─────────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────────
sc_usage() {
  cat <<'USAGE'
usage: sync-commands.sh [--root <dir>] [--dest <dir>] [--check | --apply]

  --root <dir>   the travel-planner checkout to copy FROM
                 (default: this script's parent directory)
  --dest <dir>   the commands directory to copy TO
                 (default: $HOME/.claude/commands)
  --check        report per-file state and write nothing (DEFAULT)
  --apply        preserve each file being replaced, then copy

Exit 0 when every source file is present and byte-identical at the destination
(--check), or when every copy succeeded (--apply); 1 otherwise.

Both modes print the export line that makes a synced copy resolve this checkout's
trip store from any working directory.
USAGE
}

sc_main() {
  local root="" dest="" bbase="" mode="check"
  while [ $# -gt 0 ]; do
    case "$1" in
      --root)   root="${2:-}"; shift 2 ;;
      --dest)   dest="${2:-}"; shift 2 ;;
      --backup) bbase="${2:-}"; shift 2 ;;
      --check)  mode="check"; shift ;;
      --apply)  mode="apply"; shift ;;
      -h|--help) sc_usage; return 0 ;;
      *) printf 'unknown argument: %s\n' "$1" >&2; sc_usage >&2; return 2 ;;
    esac
  done

  [ -n "$root" ]  || root="$SC_REPO_ROOT"
  [ -n "$dest" ]  || dest="$(sc_default_dest)"
  [ -n "$bbase" ] || bbase="$(sc_default_backup_base)"

  # ── BOTH PATHS MUST RESOLVE BEFORE ANYTHING IS COUNTED ─────────────────────────
  # A source directory that does not exist yields an empty file list, and an empty file
  # list produces the same zero counts and the same exit 0 as a directory holding no
  # command file. The two outputs would be indistinguishable, so a mistyped --root would
  # be reported as a clean sync — the one answer this script must never give to a question
  # it never asked. A destination that does not exist is NOT the same error: for --apply it
  # is the ordinary first-install case and is created below.
  if [ -z "$root" ] || [ ! -d "$root/$SC_CMD_SUBDIR" ]; then
    printf 'ERROR the source commands directory does not exist or is not a directory: %s\n' "$root/$SC_CMD_SUBDIR"
    return 1
  fi
  if [ -z "$dest" ]; then
    printf 'ERROR no destination could be resolved — pass --dest explicitly (HOME is unset)\n'
    return 1
  fi
  if [ "$mode" = "check" ] && [ ! -d "$dest" ]; then
    # Reported, and deliberately not an error. "The destination does not exist yet" is the
    # true and useful answer to a check run before the first install, and the per-file
    # ABSENT rows below say the same thing file by file.
    printf 'NOTE the destination directory does not exist yet: %s\n' "$dest"
  fi
  if [ "$mode" = "apply" ] && [ -z "$bbase" ]; then
    printf 'ERROR no backup location could be resolved — pass --backup explicitly (HOME is unset)\n'
    return 1
  fi

  local rc=0
  printf 'ROOT %s\n' "$root"
  printf 'DEST %s\n' "$dest"
  case "$mode" in
    check) sc_check "$root" "$dest" || rc=1 ;;
    apply) sc_apply "$root" "$dest" "$bbase" || rc=1 ;;
  esac

  # Printed on EVERY run, both modes, whatever the verdict. A user who ran --check to find
  # out whether their copies are current is exactly the user who has not set this variable.
  printf '\nTo let a synced command resolve this checkout from any working directory, add\nthis line to your shell profile:\n\n  %s\n\n' \
    "$(sc_export_line "$root")"
  return $rc
}

# Run only when executed directly; sourcing (e.g. for tests) exposes the functions without
# dispatch. Same shape as scripts/validate-artifacts.sh and scripts/publish-trip-site.sh,
# deliberately — one pattern, one reading.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  sc_main "$@"
fi
