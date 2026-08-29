#!/usr/bin/env bash
#
# validate-artifacts.sh — the artifact-schema validator.
#
# Validates in-repo engine artifacts against the per-class schemas in reference/schemas/.
# It is a LIBRARY FIRST and a CLI second: scripts/test-artifact-schema.sh sources it, and
# so does the local-trip validation surface. Sourcing exposes the functions without
# running the dispatch, exactly as publish-trip-site.sh already does for
# test-publish-guard.sh — the repo's only instance of that relation, and it points this
# way (a suite sources a production script, never the reverse).
#
#   ./scripts/validate-artifacts.sh [--root <dir>] [--scope tracked|dir <path>]
#
# ── THE RULE THIS GATE EVALUATES, AND THE ONE IT DOES NOT AUTHOR ─────────────────
# The skip predicate is NOT this script's rule. It is stated once, in
# reference/data-architecture.md -> "Tolerant read" and "The gate's skip predicate", and
# cited here rather than restated:
#
#     absent schema-version  =>  read as version 0 (pre-migration)  =>  the gate SKIPS
#     declares a version and violates that version's schema  =>  FAILS CLOSED
#
# This script evaluates that rule and invents no second one. Where its behaviour extends
# past the literal predicate it says so in terms, at the two boundary notes below (A2 and
# A6), so a reader finds the extension stated rather than discovering it.
#
# ── HOW A FILE IS SELECTED, AND WHY IT IS COMPUTED RATHER THAN LISTED ────────────
# The selector has two arms, and the second one exists because the first cannot see the
# failure it is for.
#
#   PATH ARM       a file is selected when it matches a path-pattern declared by a schema
#                  in reference/schemas/. The pattern is a property of the class, stated
#                  in that class's own schema file, so the selector is COMPUTED from the
#                  corpus and adding a class is one act: add its schema. Nothing here
#                  enumerates the class set a second time.
#
#   DECLARED ARM   a file that declares `artifact:` in its own frontmatter is resolved
#                  against the corpus even when no path-pattern matched it. Without this
#                  arm an artifact declaring a version for a class the corpus does not
#                  cover would simply not be selected — it would leave the gate silently,
#                  which is a fail-OPEN in the one place this gate exists to be closed.
#                  That state is real and dated: reference/data-architecture.md § 11
#                  records that a selector written from § 1.1 alone "picks them up at the
#                  one moment they declare a version and no schema for their class exists
#                  yet". This arm is what makes that moment observable (finding A2).
#
# EXCLUSIONS ARE NOT THIS SCRIPT'S TO DECIDE. Every exclusion below is declared in
# reference/data-architecture.md, and each carries the section that declares it. The suite
# asserts that pairing (finding S9): an exclusion this script applies whose literal is not
# present in its declaring section is a failure, so the gate cannot quietly acquire an
# ungoverned exclusion. This is a PROVENANCE assertion, not an extraction — the list lives
# here and its warrant lives in the document. That is weaker than holding no copy at all,
# and it is stated as what it is rather than dressed up.
#
# ── COVERAGE BOUNDARY ────────────────────────────────────────────────────────────
# IN SCOPE — frontmatter structure and declared entry markers, for in-repo artifacts only.
# OUT OF SCOPE, by name:
#   PROSE. The schema constrains frontmatter. It never constrains narrative body content,
#   and a green here says nothing about the quality or accuracy of any artifact's prose.
#   A USER'S trips/ DIRECTORY. .gitignore carries `trips/*` with `!trips/README.md`, so a
#   CI checkout contains no trip and this gate cannot reach one. Local trip validation is
#   a separate call site that drives these same functions with --scope dir.
#   .claude/commands/*.md. An upstream schema this repo does not own (§ 11).
#   THIS SCRIPT'S OWN SHELL QUALITY. No CI job shellchecks a standalone scripts/*.sh;
#   actionlint lints workflow-embedded shell only. Stated so a green is not read as more.
#
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────────
# Declared selector exclusions: "<glob>|<warrant literal>|<declaring section>".
#
# The GLOB is this gate's repo-relative implementation. The WARRANT LITERAL is the string
# the architecture document itself uses for the same class of file — the two differ where
# the document names a path as a trip writes it (`outputs/.staticrypt.json`) and the gate
# has to match it anywhere in a checkout. The suite asserts the warrant literal appears
# inside the named section (finding S9), so the gate cannot acquire an exclusion the corpus
# does not declare. Asserting the glob itself would have been the easier check and the
# wrong one: it would fail on a correct exclusion purely because the document spells the
# path without a `**/` prefix.
#
# `reference/schemas/*.md` is deliberately NOT excluded. It would need a warrant the corpus
# does not carry, and it does not need one: no class path-pattern reaches that directory
# and a schema file carries a fence rather than frontmatter, so it is never selected by
# either arm. That is asserted (AR6) rather than assumed. An unnecessary exclusion is not
# free — it is a scope narrowing nothing checks.
# ─────────────────────────────────────────────────────────────────────────────────
VA_EXCLUSIONS='.claude/commands/*.md|.claude/commands/*.md|## 11. What This Document Does Not Define
templates/*.template.md|templates/*.template.md|## 11. What This Document Does Not Define
examples/*/README.md|examples/*/README.md|### 1.3 In-repo files carrying no per-trip class
**/outputs/.staticrypt.json|outputs/.staticrypt.json|### 1.2 Out of model — explicit dispositions (6)
.publish/**|.publish/|### 1.2 Out of model — explicit dispositions (6)'

VA_ARCH_DOC='reference/data-architecture.md'
VA_SCHEMA_DIR='reference/schemas'
VA_CLASS_HEADING='### 1.1 In-model — per-trip artifact classes (19)'
# The internal record separator, named rather than written. A literal tab inside shell
# quoting is invisible in a diff, and one editor pass that converts it to spaces would
# silently break every field split in this file without producing an error.
VA_TAB=$'\t'
VA_NL=$'\n'

# ─────────────────────────────────────────────────────────────────────────────────
# Primitives
# ─────────────────────────────────────────────────────────────────────────────────

# va_trim <string> — strip leading and trailing whitespace.
va_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# va_seg_match <segment> <pattern-segment> — single path segment, `*` cannot cross `/`
# because it is only ever applied to one segment at a time. That restriction is the whole
# reason this is not a bare [[ $path == $pattern ]]: bash's `*` crosses `/` happily, and a
# selector whose wildcards silently span directories selects files nobody declared.
va_seg_match() {
  # SC2254 is disabled deliberately and this is the one place in the file where an
  # unquoted expansion in a case pattern is the intent: $2 IS a glob, and quoting it
  # would turn every path-pattern into a literal string comparison — the selector would
  # then match nothing and the gate would go green over an empty selection.
  # shellcheck disable=SC2254
  case "$1" in
    $2) return 0 ;;
    *)  return 1 ;;
  esac
}

# va_glob_match <path> <pattern> — segment-aware. `**` matches zero or more whole
# segments and is supported ONLY as the first or last segment; anywhere else it is a
# malformed pattern (finding S4) rather than a quietly-reinterpreted one.
va_glob_match() {
  local path="$1" pat="$2"
  case "$pat" in
    '**/'*)
      local tail="${pat#**/}" rest
      # try every suffix of path against the tail
      rest="$path"
      while : ; do
        va_glob_match "$rest" "$tail" && return 0
        case "$rest" in
          */*) rest="${rest#*/}" ;;
          *)   return 1 ;;
        esac
      done
      ;;
    *'/**')
      local head="${pat%/**}"
      case "$path" in
        "$head"/*) return 0 ;;
        *) return 1 ;;
      esac
      ;;
  esac
  # Plain, segment-by-segment. Walked with parameter expansion rather than by splitting
  # into arrays: an unquoted split of a PATTERN also triggers pathname expansion, so
  # `*.md` would silently expand against the working directory and the comparison would
  # then be against whatever files happen to be there. That failure is invisible — it
  # produces a plausible count, not an error.
  local prest="$path" qrest="$pat" pseg qseg
  while [ -n "$prest" ] || [ -n "$qrest" ]; do
    [ -n "$prest" ] || return 1
    [ -n "$qrest" ] || return 1
    case "$prest" in */*) pseg="${prest%%/*}"; prest="${prest#*/}" ;; *) pseg="$prest"; prest="" ;; esac
    case "$qrest" in */*) qseg="${qrest%%/*}"; qrest="${qrest#*/}" ;; *) qseg="$qrest"; qrest="" ;; esac
    va_seg_match "$pseg" "$qseg" || return 1
  done
  return 0
}

# va_is_excluded <path> — true when a declared exclusion claims this path.
va_is_excluded() {
  local path="$1" line pat
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    pat="${line%%|*}"
    va_glob_match "$path" "$pat" && return 0
  done <<EOF
$VA_EXCLUSIONS
EOF
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────────
# The class enumeration, read FROM reference/data-architecture.md § 1.1.
# This script holds no copy of the class list. A guard carrying its own copy of the
# thing it guards is a second source of truth: it stays green while the document it
# claims to enforce drifts away from it.
# ─────────────────────────────────────────────────────────────────────────────────

# va_class_rows <root> — emits "<n><TAB><class-name>" per in-model row of § 1.1.
va_class_rows() {
  local root="$1" doc="$1/$VA_ARCH_DOC"
  [ -r "$doc" ] || { printf 'FINDING X2 %s the architecture document is absent or unreadable\n' "$VA_ARCH_DOC"; return 1; }
  awk -v heading="$VA_CLASS_HEADING" '
    index($0, heading) == 1 { inside = 1; next }
    inside && (/^### / || /^## /) { inside = 0 }
    inside && /^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*`[^`]+`/ {
      line = $0
      sub(/^\|[[:space:]]*/, "", line)
      n = line; sub(/[[:space:]]*\|.*$/, "", n)
      rest = line; sub(/^[0-9]+[[:space:]]*\|[[:space:]]*/, "", rest)
      sub(/^`/, "", rest); sub(/`.*$/, "", rest)
      printf "%s\t%s\n", n, rest
    }
  ' "$doc"
}

# ─────────────────────────────────────────────────────────────────────────────────
# The schema corpus
# ─────────────────────────────────────────────────────────────────────────────────

# va_schema_files <root> — every schema file, README excluded (it declares, it is not a class).
va_schema_files() {
  local root="$1" f
  [ -d "$root/$VA_SCHEMA_DIR" ] || return 0
  for f in "$root/$VA_SCHEMA_DIR"/*.md; do
    [ -e "$f" ] || continue
    case "${f##*/}" in README.md) continue ;; esac
    printf '%s\n' "${f#"$root"/}"
  done
}

# va_fence <file> <info-string> — the body of the single fenced block with that info
# string. More than one such fence is itself a defect and is reported by the caller.
va_fence() {
  awk -v info="$2" '
    $0 == "```" info { n++; inside = 1; next }
    inside && $0 == "```" { inside = 0; next }
    inside { print }
    END { if (n > 1) exit 3 }
  ' "$1"
}

# va_schema_lines <root> <schema-path> — normalises one schema fence to "<key>\t<value>"
# and emits S2 for any line matching none of the declared forms. The grammar is CLOSED:
# an unrecognised construct is a violation of the corpus, never a parser limitation. That
# is what makes a hand-written extractor safe here — the extractor's reach IS the contract.
va_schema_lines() {
  local root="$1" rel="$2" body line key val
  body="$(va_fence "$root/$rel" 'artifact-schema')"
  if [ -z "$body" ]; then
    printf 'FINDING S2 %s no artifact-schema fence, or the fence is empty\n' "$rel"
    return 1
  fi
  local rc=0
  while IFS= read -r line; do
    line="$(va_trim "$line")"
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    case "$line" in
      *:*) key="$(va_trim "${line%%:*}")"; val="$(va_trim "${line#*:}")" ;;
      *)   printf 'FINDING S2 %s line is not <key>: <value> -- %s\n' "$rel" "$line"; rc=1; continue ;;
    esac
    case "$key" in
      class-id|artifact|schema-version|path-pattern|witness|no-witness-because)
        printf '%s\t%s\n' "$key" "$val" ;;
      'field '*)
        printf 'field\t%s %s\n' "${key#field }" "$val" ;;
      *)
        printf 'FINDING S2 %s unknown key %s\n' "$rel" "$key"; rc=1 ;;
    esac
  done <<EOF
$body
EOF
  return $rc
}

# va_schema_get <lines> <key> — first value for a key.
va_schema_get() {
  printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k { print $2; exit }'
}
# va_schema_all <lines> <key> — every value for a repeatable key.
va_schema_all() {
  printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k { print $2 }'
}

# ─────────────────────────────────────────────────────────────────────────────────
# Artifact frontmatter — S2 grammar. Scalar-only: no nesting, no boolean. The single
# declared exception is the inline two-value list, which exists for exactly one field of
# exactly one class (C14's section-owned `writer`, reference/data-architecture.md § 4.4).
# One grammar, two fences: markdown carries `---`, HTML carries `<!-- ... -->`, because
# § 4.5 puts C19's declaration in an HTML comment. The KEYS are identical.
# ─────────────────────────────────────────────────────────────────────────────────

# va_frontmatter <file> — the raw block body, or empty when the file carries none.
va_frontmatter() {
  local f="$1"
  case "$f" in
    *.html) awk 'NR==1 && $0 != "<!--" { exit } NR==1 { next } $0 == "-->" { exit } { print }' "$f" ;;
    *)      awk 'NR==1 && $0 != "---"  { exit } NR==1 { next } $0 == "---"  { exit } { print }' "$f" ;;
  esac
}

# va_fm_terminated <file> — the block opened and closed. An unterminated fence is A1:
# a file whose frontmatter runs to EOF has no body/frontmatter boundary at all, and
# guessing one is how a parser reads half a document as metadata.
va_fm_terminated() {
  local f="$1"
  case "$f" in
    *.html) awk 'NR==1 && $0 != "<!--" { exit 1 } NR>1 && $0 == "-->" { found=1; exit 0 } END { exit (found?0:1) }' "$f" ;;
    *)      awk 'NR==1 && $0 != "---"  { exit 1 } NR>1 && $0 == "---"  { found=1; exit 0 } END { exit (found?0:1) }' "$f" ;;
  esac
}

# va_fm_pairs <root> <rel> — normalises frontmatter to "<key>\t<value>", emitting A1 for
# a malformed block. Duplicate keys are A1 too: two values for one key is two homes for
# one fact, and picking either silently is the wrong answer to a question the file asks.
va_fm_pairs() {
  local root="$1" rel="$2" body line key val seen=""
  body="$(va_frontmatter "$root/$rel")"
  [ -n "$body" ] || return 0
  if ! va_fm_terminated "$root/$rel"; then
    printf 'FINDING A1 %s frontmatter block is not terminated\n' "$rel"
    return 1
  fi
  local rc=0
  while IFS= read -r line; do
    line="$(va_trim "$line")"
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    case "$line" in
      *:*) key="$(va_trim "${line%%:*}")"; val="$(va_trim "${line#*:}")" ;;
      *)   printf 'FINDING A1 %s field <none> out-of-grammar line -- %s\n' "$rel" "$line"; rc=1; continue ;;
    esac
    case "$key" in
      [a-z]*) : ;;
      *) printf 'FINDING A1 %s field %s key is not kebab-case\n' "$rel" "$key"; rc=1; continue ;;
    esac
    case "$key" in
      *[!a-z0-9-]*) printf 'FINDING A1 %s field %s key is not kebab-case\n' "$rel" "$key"; rc=1; continue ;;
    esac
    case " $seen " in
      *" $key "*) printf 'FINDING A1 %s field %s duplicate key\n' "$rel" "$key"; rc=1; continue ;;
    esac
    seen="$seen $key"
    # Scalar-only. A leading YAML structural sigil means the value is not a scalar; the
    # one admitted non-scalar is the inline list, and it is admitted by TYPE at the field
    # check, never by the grammar being widened for everyone.
    case "$val" in
      '['*']') : ;;
      [\{\|\>\&\*\!]*)
        printf 'FINDING A1 %s field %s value is not a scalar\n' "$rel" "$key"; rc=1; continue ;;
      '['*)
        printf 'FINDING A1 %s field %s value is not a scalar\n' "$rel" "$key"; rc=1; continue ;;
    esac
    printf '%s\t%s\n' "$key" "$val"
  done <<EOF
$body
EOF
  return $rc
}

# va_type_ok <type> <value> <enum-members>
va_type_ok() {
  local t="$1" v="$2" e="${3:-}"
  case "$t" in
    integer) case "$v" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac ;;
    date)    case "$v" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) return 0 ;; *) return 1 ;; esac ;;
    slug)    case "$v" in [a-z0-9]) return 0 ;; [a-z0-9]*[!a-z0-9-]*) return 1 ;; [a-z0-9]*) return 0 ;; *) return 1 ;; esac ;;
    string)  [ -n "$v" ] && return 0 || return 1 ;;
    'list<slug>')
      case "$v" in '['*']') : ;; *) return 1 ;; esac
      local inner="${v#[}"; inner="${inner%]}"
      local IFS=','; local item
      for item in $inner; do
        item="$(va_trim "$item")"
        va_type_ok slug "$item" || return 1
      done
      return 0 ;;
    enum)
      local IFS='|'; local m
      for m in $e; do [ "$m" = "$v" ] && return 0; done
      return 1 ;;
    *) return 1 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────────
# Corpus checks — S1..S8
# ─────────────────────────────────────────────────────────────────────────────────
va_check_corpus() {
  local root="$1" rc=0
  local classes rel lines cid art ver pats p wit nowit seen_cid="" seen_art="" corpus_ids=""

  classes="$(va_class_rows "$root")" || { printf '%s\n' "$classes"; return 1; }
  if [ -z "$classes" ]; then
    printf 'FINDING X2 %s no in-model class rows extracted from the class enumeration\n' "$VA_ARCH_DOC"
    return 1
  fi

  if [ ! -d "$root/$VA_SCHEMA_DIR" ]; then
    printf 'FINDING X2 %s the schema directory is absent\n' "$VA_SCHEMA_DIR"
    return 1
  fi

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    lines="$(va_schema_lines "$root" "$rel")" || rc=1
    printf '%s\n' "$lines" | grep '^FINDING ' 2>/dev/null
    lines="$(printf '%s\n' "$lines" | grep -v '^FINDING ' 2>/dev/null)"

    cid="$(va_schema_get "$lines" class-id)"
    art="$(va_schema_get "$lines" artifact)"
    ver="$(va_schema_get "$lines" schema-version)"

    # S1 — the schema's declared identity must agree with § 1.1's row for its class-id.
    local want=""
    case "$cid" in
      C[0-9]|C[0-9][0-9])
        want="$(printf '%s\n' "$classes" | awk -F'\t' -v n="${cid#C}" '$1 == n { print $2; exit }')" ;;
    esac
    if [ -z "$want" ]; then
      printf 'FINDING S1 %s class-id %s names no in-model row of the class enumeration\n' "$rel" "${cid:-<absent>}"; rc=1
    elif [ "$art" != "$want" ]; then
      printf 'FINDING S1 %s field artifact value %s disagrees with the class enumeration, which names %s for %s\n' \
        "$rel" "${art:-<absent>}" "$want" "$cid"; rc=1
    fi

    # S3 — one schema per class, both keys.
    case " $seen_cid " in *" $cid "*) printf 'FINDING S3 %s class-id %s is declared by more than one schema\n' "$rel" "$cid"; rc=1 ;; esac
    case " $seen_art " in *" $art "*) printf 'FINDING S3 %s artifact %s is declared by more than one schema\n' "$rel" "$art"; rc=1 ;; esac
    seen_cid="$seen_cid $cid"; seen_art="$seen_art $art"
    corpus_ids="$corpus_ids ${cid#C}"

    if ! va_type_ok integer "$ver"; then
      printf 'FINDING S1 %s field schema-version value %s is not a positive integer\n' "$rel" "${ver:-<absent>}"; rc=1
    fi

    # S4 — path-pattern present and inside the declared glob subset.
    pats="$(va_schema_all "$lines" path-pattern)"
    if [ -z "$pats" ]; then
      printf 'FINDING S4 %s no path-pattern declared\n' "$rel"; rc=1
    else
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        case "$p" in
          /*|*'***'*) printf 'FINDING S4 %s path-pattern %s is not repo-relative or uses an undeclared glob construct\n' "$rel" "$p"; rc=1; continue ;;
        esac
        case "$p" in *'?'*|*'['*) printf 'FINDING S4 %s path-pattern %s uses a glob construct outside * and **\n' "$rel" "$p"; rc=1; continue ;; esac
        # `**` only as the first or last segment. Checked by STRIPPING the two legal
        # positions and then looking for a survivor — a test for "starts with **/" alone
        # would accept `**/outputs/**/x.md`, because the illegal `**` sits behind a legal
        # one and the leading match is what the eye lands on.
        local core="$p"
        case "$core" in '**/'*) core="${core#**/}" ;; esac
        case "$core" in *'/**') core="${core%/**}" ;; esac
        case "$core" in
          *'**'*) printf 'FINDING S4 %s path-pattern %s places ** other than as the first or last segment\n' "$rel" "$p"; rc=1 ;;
        esac
      done <<EOF
$pats
EOF
    fi

    # S5/S6/S7 — the coverage declaration.
    wit="$(va_schema_get "$lines" witness)"
    nowit="$(va_schema_get "$lines" no-witness-because)"
    if [ -n "$wit" ] && [ -n "$nowit" ]; then
      printf 'FINDING S7 %s declares both witness and no-witness-because; they are mutually exclusive\n' "$rel"; rc=1
    elif [ -z "$wit" ] && [ -z "$nowit" ]; then
      printf 'FINDING S7 %s declares neither witness nor no-witness-because\n' "$rel"; rc=1
    elif [ -n "$wit" ]; then
      if [ ! -e "$root/$wit" ]; then
        printf 'FINDING S5 %s declared witness %s does not exist\n' "$rel" "$wit"; rc=1
      else
        local wfm
        wfm="$(va_fm_pairs "$root" "$wit" 2>/dev/null | awk -F'\t' '$1 == "schema-version" { print $2 }')"
        if [ -z "$wfm" ]; then
          printf 'FINDING S6 %s declared witness %s carries no schema-version -- coverage regression\n' "$rel" "$wit"; rc=1
        fi
      fi
    fi
  done <<EOF
$(va_schema_files "$root")
EOF

  # S8 — bijection with § 1.1. The corpus is asserted against the document, in both
  # directions: a class with no schema is as much a failure as a schema with no class.
  local row n cname
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    n="$(printf '%s\n' "$row" | cut -f1)"
    cname="$(printf '%s\n' "$row" | cut -f2)"
    case " $corpus_ids " in
      *" $n "*) : ;;
      *) printf 'FINDING S8 %s/ class C%s (%s) has no schema in the corpus\n' "$VA_SCHEMA_DIR" "$n" "$cname"; rc=1 ;;
    esac
  done <<EOF
$classes
EOF
  return $rc
}

# ─────────────────────────────────────────────────────────────────────────────────
# Selection
# ─────────────────────────────────────────────────────────────────────────────────

# va_corpus_patterns <root> — "<class-id>\t<artifact>\t<pattern>\t<schema-path>" per
# declared pattern. Memoised per root: the corpus is parsed once and re-read from the cache
# for the rest of the run. Without this the selector re-parses every schema for every file
# it considers, which turns a linear walk into a quadratic one.
VA_CACHE_ROOT=""
VA_CACHE_PATTERNS=""
va_corpus_patterns() {
  local root="$1" rel lines cid art p
  if [ "$VA_CACHE_ROOT" = "$root" ]; then printf '%s\n' "$VA_CACHE_PATTERNS"; return 0; fi
  local acc=""
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    lines="$(va_schema_lines "$root" "$rel" 2>/dev/null | grep -v '^FINDING ')"
    cid="$(va_schema_get "$lines" class-id)"
    art="$(va_schema_get "$lines" artifact)"
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      acc="${acc}${cid}${VA_TAB}${art}${VA_TAB}${p}${VA_TAB}${rel}${VA_NL}"
    done <<EOF
$(va_schema_all "$lines" path-pattern)
EOF
  done <<EOF
$(va_schema_files "$root")
EOF
  VA_CACHE_ROOT="$root"
  VA_CACHE_PATTERNS="${acc%"$VA_NL"}"
  printf '%s\n' "$VA_CACHE_PATTERNS"
}

# va_population <root> <scope> [dir] — the candidate file list, before exclusion.
va_population() {
  local root="$1" scope="${2:-tracked}" dir="${3:-}"
  case "$scope" in
    tracked) ( cd "$root" && git ls-files 2>/dev/null ) ;;
    dir)     ( cd "$root" && find "$dir" -type f 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort ) ;;
    *)       return 1 ;;
  esac
}

# va_select <root> <scope> [dir] — "<class-id>\t<artifact>\t<path>\t<arm>" for every
# selected file, plus "EXCLUDED\t<path>" and "UNMATCHED\t<path>" so the whole population
# is accounted for. A denominator you cannot reconstruct is not a denominator.
va_select() {
  local root="$1" scope="${2:-tracked}" dir="${3:-}"
  local pats f best_len best_cid best_art cid art p len plit declared
  pats="$(va_corpus_patterns "$root")"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if va_is_excluded "$f"; then printf 'EXCLUDED\t%s\n' "$f"; continue; fi
    best_len=-1; best_cid=""; best_art=""
    # Split on the named separator rather than by shelling out to cut per field: this is
    # the innermost loop of the whole gate (every candidate file x every declared pattern)
    # and three subprocesses per comparison is the difference between a second and a
    # minute.
    while IFS="$VA_TAB" read -r cid art p _; do
      [ -n "$p" ] || continue
      if va_glob_match "$f" "$p"; then
        # Rank two matching patterns by LITERAL length — the count of non-`*` characters —
        # and let the longest win. That is what lets C18 `outputs/<slug>.md` ship as a
        # genuine residual class without stealing every named class's file:
        # `examples/*/outputs/food-list.md` outranks `examples/*/outputs/*.md` on any file
        # both match, deterministically and with no precedence list to maintain.
        plit="${p//\*/}"; len="${#plit}"
        if [ "$len" -gt "$best_len" ]; then best_len="$len"; best_cid="$cid"; best_art="$art"; fi
      fi
    done <<EOF
$pats
EOF
    if [ -n "$best_cid" ]; then
      printf '%s\t%s\t%s\tpath\n' "$best_cid" "$best_art" "$f"
      continue
    fi
    # DECLARED ARM — see the header. A file the path arm did not claim, which declares a
    # class of its own, is resolved anyway rather than leaving the gate unobserved.
    declared="$(va_fm_pairs "$root" "$f" 2>/dev/null | awk -F'\t' '$1 == "artifact" { print $2; exit }')"
    if [ -n "$declared" ]; then
      cid="$(printf '%s\n' "$pats" | awk -F'\t' -v a="$declared" '$2 == a { print $1; exit }')"
      printf '%s\t%s\t%s\tdeclared\n' "${cid:-UNKNOWN}" "$declared" "$f"
      continue
    fi
    printf 'UNMATCHED\t%s\n' "$f"
  done <<EOF
$(va_population "$root" "$scope" "$dir")
EOF
}

# ─────────────────────────────────────────────────────────────────────────────────
# Artifact checks — A1..A6
# ─────────────────────────────────────────────────────────────────────────────────

# va_check_artifact <root> <path> <class-id> <artifact> — findings on stdout; rc 1 on any.
# Prints "SKIP <path> <class>" and returns 0 for the pre-migration case, so the skip is
# reported by path AND by resolved class rather than merely counted.
va_check_artifact() {
  local root="$1" rel="$2" cid="$3" art="$4"
  local pairs ver declared rc=0

  if [ ! -r "$root/$rel" ]; then
    printf 'FINDING X2 %s file is unreadable\n' "$rel"; return 1
  fi

  pairs="$(va_fm_pairs "$root" "$rel")" || rc=1
  printf '%s\n' "$pairs" | grep '^FINDING ' 2>/dev/null
  pairs="$(printf '%s\n' "$pairs" | grep -v '^FINDING ' 2>/dev/null)"

  ver="$(printf '%s\n' "$pairs" | awk -F'\t' '$1 == "schema-version" { print $2; exit }')"
  declared="$(printf '%s\n' "$pairs" | awk -F'\t' '$1 == "artifact" { print $2; exit }')"

  # ── THE SKIP PREDICATE. Cited, not restated:
  #    reference/data-architecture.md -> "Tolerant read" / "The gate's skip predicate".
  #    absent schema-version => version 0 => SKIP. This is the WHOLE predicate, and the
  #    gate keys on the absence of that one key and on nothing else.
  if [ -z "$ver" ]; then
    printf 'SKIP %s %s\n' "$rel" "${cid}"
    return 0
  fi

  # ── BOUNDARY NOTE (A2). From here the artifact has declared a version, so the rule's
  # second limb governs: declares a version and violates that version's schema => fails
  # closed. A class the corpus does not cover has no schema to violate, and § 11 names
  # this exact moment. The gate treats it as a broken REPOSITORY rather than a broken
  # artifact — it is an assertion about this repo's internal consistency, it cannot fire
  # on a user's trip because the gate cannot see one, and it is deliberately gated behind
  # the version check so an UNVERSIONED artifact naming an unknown class still skips.
  if [ "$cid" = "UNKNOWN" ] || [ -z "$cid" ]; then
    printf 'FINDING A2 %s field artifact value %s declares schema-version %s but no schema in %s/ covers that class\n' \
      "$rel" "${declared:-<absent>}" "$ver" "$VA_SCHEMA_DIR"
    return 1
  fi

  local lines sver
  lines="$(va_schema_lines "$root" "$(va_schema_for "$root" "$cid")" 2>/dev/null | grep -v '^FINDING ')"
  sver="$(va_schema_get "$lines" schema-version)"

  # A5 — the file's own declaration must agree with the class that selected it.
  if [ -n "$declared" ] && [ "$declared" != "$art" ]; then
    printf 'FINDING A5 %s field artifact value %s disagrees with %s, the class whose path-pattern selected it\n' \
      "$rel" "$declared" "$art"; rc=1
  fi

  # ── BOUNDARY NOTE (A6). The tolerant read tells a READER never to fail on a version it
  # does not recognise — and this gate is not that reader. It asserts the repository's own
  # consistency, where an in-repo artifact declaring a version its own in-repo schema does
  # not define is a broken repo rather than a forward-compatible trip. Stated here so the
  # one place the gate extends past the literal predicate is visible in the source.
  if [ -n "$sver" ] && [ "$ver" -gt "$sver" ] 2>/dev/null; then
    printf 'FINDING A6 %s field schema-version value %s exceeds %s, the version its own class schema defines\n' \
      "$rel" "$ver" "$sver"; rc=1
  fi

  # A3/A4 — the class's declared fields.
  local fl name req typ enum val
  while IFS= read -r fl; do
    [ -n "$fl" ] || continue
    name="${fl%% *}"; fl="${fl#* }"
    req="${fl%% *}"; fl="${fl#* }"
    typ="${fl%% *}"; enum=""
    case "$fl" in *'['*']'*) enum="${fl#*[}"; enum="${enum%]*}" ;; esac
    val="$(printf '%s\n' "$pairs" | awk -F'\t' -v k="$name" '$1 == k { print $2; exit }')"
    if [ -z "$val" ]; then
      if [ "$req" = "required" ]; then
        printf 'FINDING A3 %s field %s is required by %s and is absent\n' "$rel" "$name" "$art"; rc=1
      fi
      continue
    fi
    if ! va_type_ok "$typ" "$val" "$enum"; then
      if [ "$typ" = "enum" ]; then
        printf 'FINDING A4 %s field %s value %s is not in enum [%s]\n' "$rel" "$name" "$val" "$enum"; rc=1
      else
        printf 'FINDING A4 %s field %s value %s is not a valid %s\n' "$rel" "$name" "$val" "$typ"; rc=1
      fi
    fi
  done <<EOF
$(va_schema_all "$lines" field)
EOF
  return $rc
}

# va_schema_for <root> <class-id> — the schema file declaring that class. Answered from
# the memoised pattern table rather than by re-walking the corpus per artifact.
va_schema_for() {
  local root="$1" cid="$2" rel
  rel="$(va_corpus_patterns "$root" | awk -F'\t' -v c="$cid" '$1 == c { print $4; exit }')"
  [ -n "$rel" ] || return 1
  printf '%s' "$rel"
}

# ─────────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────────
va_usage() {
  cat <<'USAGE'
usage: validate-artifacts.sh [--root <dir>] [--scope tracked|dir <path>]

  --root <dir>          repository root (default: this script's parent directory)
  --scope tracked       every git-tracked file (default) -- the CI arm
  --scope dir <path>    every file beneath <path> -- the local-trip arm

Exit 0 when no finding fired; 1 otherwise. Every finding names the artifact and, where
the finding is field-scoped, the field.
USAGE
}

va_main() {
  local root="" scope="tracked" dir=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --root)  root="${2:-}"; shift 2 ;;
      --scope) scope="${2:-}"; shift 2
               if [ "$scope" = "dir" ]; then dir="${1:-}"; shift; fi ;;
      -h|--help) va_usage; return 0 ;;
      *) printf 'unknown argument: %s\n' "$1" >&2; va_usage >&2; return 2 ;;
    esac
  done
  if [ -z "$root" ]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi

  local rc=0 out sel
  out="$(va_check_corpus "$root")" || rc=1
  [ -n "$out" ] && printf '%s\n' "$out"

  sel="$(va_select "$root" "$scope" "$dir")"
  local nsel nexc nunm nskip=0 nver=0
  # Counted with awk on the TAB-delimited field, never with a shell pattern carrying a
  # literal tab: a tab inside shell quoting is invisible in a diff and one editor pass
  # that converts it to spaces would silently zero this denominator.
  nsel="$(printf '%s\n' "$sel" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {n++} END{print n+0}')"
  nexc="$(printf '%s\n' "$sel" | awk -F'\t' '$1=="EXCLUDED" {n++} END{print n+0}')"
  nunm="$(printf '%s\n' "$sel" | awk -F'\t' '$1=="UNMATCHED" {n++} END{print n+0}')"

  local line cid art path arm res
  while IFS= read -r line; do
    cid="$(printf '%s\n' "$line" | cut -f1)"
    case "$cid" in ''|EXCLUDED|UNMATCHED) continue ;; esac
    art="$(printf '%s\n' "$line" | cut -f2)"
    path="$(printf '%s\n' "$line" | cut -f3)"
    arm="$(printf '%s\n' "$line" | cut -f4)"
    res="$(va_check_artifact "$root" "$path" "$cid" "$art")" || rc=1
    case "$res" in
      'SKIP '*) nskip=$((nskip+1)); printf '%s (arm: %s)\n' "$res" "$arm" ;;
      *) nver=$((nver+1)); [ -n "$res" ] && printf '%s\n' "$res" ;;
    esac
  done <<EOF
$sel
EOF

  printf 'POPULATION selected=%s excluded=%s unmatched=%s\n' "$nsel" "$nexc" "$nunm"
  printf 'PREDICATE skipped=%s validated=%s\n' "$nskip" "$nver"
  return $rc
}

# Run only when executed directly; sourcing (e.g. for tests) exposes functions without
# dispatch. Same shape as publish-trip-site.sh, deliberately — one pattern, one reading.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  va_main "$@"
fi
