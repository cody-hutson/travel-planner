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
#   ./scripts/validate-artifacts.sh [--root <dir>] [--data-root <dir>] [--scope tracked|dir <path>]
#
# ── TWO ROOTS, AND WHY ONE FLAG CANNOT CARRY BOTH ────────────────────────────────
# `--root` roots the SCHEMA CORPUS — reference/data-architecture.md and
# reference/schemas/ — which are ENGINE assets and must follow this script wherever it is
# installed. `--data-root` roots the POPULATION: the tree that is walked and the artifact
# content that is read. They are the same directory in this checkout and they diverge the
# moment the engine is installed, because operator trips live wherever the operator keeps
# them and the installed engine ships trips/README.md and nothing else under trips/.
#
# Before the seam existed there was one flag for both, and the local-trip arm the /trip
# schema verb composes pointed it at the operator's data home — a directory that by
# construction holds no reference/schemas/. Measured outcome: X2 on the architecture
# document, then either every artifact graded UNKNOWN with a spurious A2 (when the trip's
# files declare `artifact:`, as every example trip's do) or nothing selected at all and a
# VACUOUS verdict (when they do not). Both are the same conflation reported twice.
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
# ── FINDING X3 — A DEGRADED READ, AND WHY IT IS NOT X2 ───────────────────────────
# X3 says: the read of an input that should be there DID NOT COMPLETE. It is stated here,
# beside the A2 and A6 notes, rather than in a tracked document, because the corpus carries
# no registry of this script's finding codes and inventing one would be a second source of
# truth for a vocabulary that lives here.
#
# It is deliberately NOT X2, which this file already uses and keeps. X2 says the input IS
# NOT THERE — a property of the repository, reproducible on the next run, fixable by
# editing the tree. X3 says the input is there and the READ of it failed — a property of
# the environment, not reproducible, and fixable by nothing in the tree. Those are two
# different facts with two different remedies, and collapsing them into one code is the
# exact conflation this gate was converting into a quieter verdict at rc 0: a capture that
# came back empty read as an absent input, an absent input read as a legitimate answer, and
# the run went green over an artifact nothing had checked.
#
# Every X3 is emitted by va_read_ok below, which is the adjudication half of a captured
# read. The classification of WHICH captures are adjudicated, which are legitimately
# tolerant, and which are already guarded by a named finding is carried inline at each site
# as a `# va-capture:` marker, and the suite asserts that no capture is left without one.
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
#   skills/*/SKILL.md. An upstream schema this repo does not own (§ 11).
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
# ── `.publish/` IS ANCHORED ANYWHERE, AND THE `**/` PREFIX IS WHY ────────────────
# It was written `.publish/**`, which va_glob_match resolves through its `*'/**'` branch as a
# ROOT-ANCHORED prefix test. That excluded a `.publish/` at the repository root and failed to
# exclude one inside a trip — which is the only position a real user's publish directory ever
# occupies, since publish-trip-site.sh writes it under trips/<slug>/. Both arms were observed
# on identical bytes: excluded at the root, traversed in a trip. The corpus states the
# exclusion without qualification, so the glob is what was wrong, not the claim. `**/` makes
# it segment-anywhere, matching the form the .staticrypt.json exclusion above already uses.
# The WARRANT LITERAL is unchanged, so this is not a new exclusion and S9's provenance
# assertion grades the same string against the same section.
VA_EXCLUSIONS='skills/*/SKILL.md|skills/*/SKILL.md|## 11. What This Document Does Not Define
templates/*.template.md|templates/*.template.md|## 11. What This Document Does Not Define
examples/*/README.md|examples/*/README.md|### 1.3 In-repo files carrying no per-trip class
**/outputs/.staticrypt.json|outputs/.staticrypt.json|### 1.2 Out of model — explicit dispositions (6)
**/.publish/**|.publish/|### 1.2 Out of model — explicit dispositions (6)'

VA_ARCH_DOC='reference/data-architecture.md'
VA_SCHEMA_DIR='reference/schemas'
VA_CLASS_HEADING='### 1.1 In-model — artifact classes (23)'
# The internal record separator, named rather than written. A literal tab inside shell
# quoting is invisible in a diff, and one editor pass that converts it to spaces would
# silently break every field split in this file without producing an error.
VA_TAB=$'\t'
VA_NL=$'\n'

# ─────────────────────────────────────────────────────────────────────────────────
# The classifier character sets.
#
# ── WHY THESE ARE SPELLED OUT AND NEVER WRITTEN AS RANGES ────────────────────────
# A bracket RANGE is resolved against the collating sequence of the current locale, not
# against ASCII. Under a UTF-8 collation the lowercase range also matches uppercase, so the
# slug predicate ACCEPTED `Hub` and `HUB` for an operator whose shell carries a UTF-8 default
# while REJECTING them under the C locale CI happens to run in. Nothing pinned the locale for
# this script or its workflow, so CI enforced a rule an operator's own run did not, and a
# file that passed locally failed in CI for a reason nothing explained.
#
# Pinning LC_ALL was the other candidate and is the weaker one: it makes the answer depend on
# the pin holding at every entry point, and the suite calls these predicates DIRECTLY rather
# than through the CLI, so a pin taken at dispatch would not cover them. Spelling the sets
# removes the collating sequence from the question altogether — with no range to widen, a
# locale has nothing left to do. The predicate is then invariant by construction rather than
# by configuration.
#
# Asserted in both directions by the suite's group LC: through the real function, under every
# locale the host declares, and at this source, where the count of remaining ranges must be
# zero. The trailing `-` in VA_SLUGBODY is LAST on purpose — a `-` elsewhere in a bracket
# expression is a range operator rather than a literal hyphen.
# ─────────────────────────────────────────────────────────────────────────────────
VA_LOWER='abcdefghijklmnopqrstuvwxyz'
VA_DIGIT='0123456789'
VA_SLUGHEAD="${VA_LOWER}${VA_DIGIT}"
VA_SLUGBODY="${VA_LOWER}${VA_DIGIT}-"

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

# va_read_ok <label> <status> <captured> <empty-policy: allow|deny>
#
# The ADJUDICATION half of a captured read. The capture stays exactly where it is — `set -o
# pipefail` is on at the top of this file, so after `x="$(producer)"`, including a pipeline,
# `$?` already IS the producer's status — and this says what that status and that content
# mean HERE. Two limbs, and the census decides the second one per site:
#
#   status non-zero            => the read did not complete                 => X3, fail closed
#   empty AND policy is `deny` => the read completed and produced nothing
#                                 where content is structurally required    => X3, fail closed
#
# `allow` is not laxity. It is the recorded claim that emptiness is a REAL ANSWER at this
# site, and it carries its reason on the call line beside it. Adjudicating the STATUS and
# leaving the emptiness to the census is what keeps a 58-site sweep from turning a healthy
# repository red: empty is the correct answer at 21 of those sites, 1,393 times on a clean
# tree, and a rule that failed on emptiness would emit 94 findings at one of them alone.
#
# It is written as a post-hoc adjudicator rather than as a wrapper (`x="$(va_read producer
# args…)"`) because a wrapper cannot take a PIPELINE as its argument list, and several of
# the adjudicated sites are pipelines. This shape works identically for a plain capture, a
# pipeline and a function, and it keeps the diff to one appended line per site.
va_read_ok() {
  local label="$1" st="$2" body="$3" policy="$4"
  if [ "$st" -ne 0 ]; then
    printf 'FINDING X3 %s degraded read -- producer exited %s\n' "$label" "$st"; return 1
  fi
  if [ "$policy" = deny ] && [ -z "$body" ]; then
    printf 'FINDING X3 %s degraded read -- no output where output is structurally required\n' "$label"; return 1
  fi
  return 0
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

# va_class_rows <root> — emits one line per in-model row of § 1.1:
#
#   "<n><TAB><class-name><TAB><writer><TAB><lifecycle><TAB><provenance><TAB><publish>"
#
# ── THE FIRST TWO FIELDS ARE FROZEN, AND THE REASON IS NOT STYLE ─────────────────
# Fields 1 and 2 are computed by the ORIGINAL expression, character for character, and
# the four assignment fields are APPENDED. Every existing caller reads by field index —
# va_check_corpus's S1 lookup (`$1 == n { print $2 }`), its S8 bijection walk (`cut -f1`
# / `cut -f2`), and the suite's class count (`grep -c '^[0-9]'`) — so appending is
# transparent to all of them and rewriting either of the first two is not.
#
# That is a live hazard rather than a hypothetical one. The class column is extracted by
# truncating at the CLOSING backtick, not by stripping every backtick on the line, and
# the two differ on exactly one row: C18 renders as `outputs/<slug>.md` — targeted-research
# output, where stripping yields the prose tail as part of the class name. That value is
# what S1 compares a schema's `artifact:` against and what S8 walks for the bijection, so
# a stripped C18 fails BOTH against a corpus that is correct. The assignment cells take the
# stripping form because they are short tokens carrying markdown emphasis; the class column
# must not.
#
# ── WHY THE ASSIGNMENT CELLS ARE SPLIT SEPARATELY ────────────────────────────────
# A markdown row is split on `|` into a FIXED column count, and the split is only performed
# when that count is exactly right (7 columns => 9 fields, counting the empty leading and
# trailing pieces the delimiters produce). A row of any other width yields EMPTY assignment
# fields rather than fields shifted by one, so a changed table width surfaces as an absent
# assignment — which the suite grades as a parse failure — instead of as four plausible
# values read out of the wrong columns. A silently shifted field is the failure mode that
# produces a green over the wrong data.
va_class_rows() {
  local root="$1" doc="$1/$VA_ARCH_DOC"
  [ -r "$doc" ] || { printf 'FINDING X2 %s the architecture document is absent or unreadable\n' "$VA_ARCH_DOC"; return 1; }
  awk -v heading="$VA_CLASS_HEADING" '
    function cell(s) {
      gsub(/\*\*/, "", s); gsub(/`/, "", s)
      sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s)
      return s
    }
    index($0, heading) == 1 { inside = 1; next }
    inside && (/^### / || /^## /) { inside = 0 }
    inside && /^\|[[:space:]]*[0-9]+[[:space:]]*\|[[:space:]]*`[^`]+`/ {
      line = $0
      sub(/^\|[[:space:]]*/, "", line)
      n = line; sub(/[[:space:]]*\|.*$/, "", n)
      rest = line; sub(/^[0-9]+[[:space:]]*\|[[:space:]]*/, "", rest)
      sub(/^`/, "", rest); sub(/`.*$/, "", rest)
      w = ""; lc = ""; pv = ""; pb = ""
      if (split($0, F, "|") == 9) { w = cell(F[4]); lc = cell(F[5]); pv = cell(F[6]); pb = cell(F[7]) }
      printf "%s\t%s\t%s\t%s\t%s\t%s\n", n, rest, w, lc, pv, pb
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
  body="$(va_fence "$root/$rel" 'artifact-schema')"   # va-capture: guarded:S2 — an empty fence body is S2 immediately below, on both status and content
  if [ -z "$body" ]; then
    printf 'FINDING S2 %s no artifact-schema fence, or the fence is empty\n' "$rel"
    return 1
  fi
  local rc=0
  while IFS= read -r line; do
    line="$(va_trim "$line")"   # va-capture: tolerant(1) — a blank or comment-only schema line trims to nothing; 1,125 such trims on this tree, and no process runs here to fail
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    case "$line" in
      *:*) key="$(va_trim "${line%%:*}")"; val="$(va_trim "${line#*:}")" ;;   # va-capture: tolerant(2) — an empty key or value half is a real schema value; pure parameter expansion, so nothing here can fail to complete
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

# va_fm_declares_no_field <file> — STATUS ONLY. It writes nothing at all, on either stream.
# Exit 0 when the frontmatter block declares no field: no block, an empty block, blank lines
# only, comment lines only, or any mixture of those. Exit NON-ZERO when the block carries at
# least one line va_fm_pairs would turn into a pair or into an A1 — and non-zero as well
# whenever the question cannot be answered at all, so a caller that fails closed on non-zero
# fails closed on this probe's own failure too. That direction is deliberate: under a broken
# fork the honest verdict is that the read did not complete, not that the block was empty.
#
# WHY IT CARRIES NO OUTPUT, WHICH IS THE WHOLE POINT. The degraded-read limb in
# va_check_artifact exists to tell "the read failed" from "nothing was declared", and it used
# to ask that question of the SAME read it was adjudicating: va_fm_pairs reaches the file
# through va_frontmatter, so one transient emptied the pairs AND the probe meant to notice,
# the limb went quiet, and the artifact skipped at rc 0 — the exact signature this gate exists
# to remove. A discriminator that shares a failure mode with its subject is not one. This
# probe opens the file itself and returns a STATUS, so it has no capture to be emptied.
#
# THE `2>/dev/null` IS THE FIRST SENTENCE, ENFORCED — not noise to tidy away. awk writes its
# own diagnostic to stderr when it cannot open the file, so without the redirect that sentence
# is false on exactly the inputs this probe exists to survive. Nothing diagnostic is lost: the
# status is untouched and non-zero, the caller fails closed on it, and the gate reports an
# unreadable input in its own vocabulary rather than in awk's. Leaving it unredirected would
# be worse than untidy, because the validator's stderr is a GRADED surface — CTL-DATAROOT6
# asserts both of its invocations wrote nothing to it — so a stray line here would surface as
# a data-root spelling difference rather than as a named finding about a read. va_frontmatter
# and va_fm_terminated share the behaviour and are deliberately untouched: neither claims
# silence, so neither is made false by it.
#
# The line filter is va_fm_pairs' own, deliberately: a trimmed-empty line and a `#` line are
# what that function skips as legal content, so "a field was expected" here means exactly
# "va_fm_pairs had something to parse". KEEP THE TWO IN STEP — a grammar change there is a
# change here, and a drift between them re-opens the comment-only false positive.
#
# END computes the answer from a flag rather than each rule carrying its own status, because
# awk runs END on `exit` and an `exit <n>` there would override the rule's — the shape
# va_fm_terminated above already uses, for the same reason.
va_fm_declares_no_field() {
  local f="$1"
  case "$f" in
    *.html) awk 'NR==1 && $0 != "<!--" { exit } NR==1 { next } $0 == "-->" { exit }
                 { sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, "")
                   if ($0 != "" && substr($0, 1, 1) != "#") { found = 1; exit } }
                 END { exit (found ? 1 : 0) }' "$f" 2>/dev/null ;;
    *)      awk 'NR==1 && $0 != "---"  { exit } NR==1 { next } $0 == "---"  { exit }
                 { sub(/^[[:space:]]+/, ""); sub(/[[:space:]]+$/, "")
                   if ($0 != "" && substr($0, 1, 1) != "#") { found = 1; exit } }
                 END { exit (found ? 1 : 0) }' "$f" 2>/dev/null ;;
  esac
}

# va_fm_pairs <root> <rel> — normalises frontmatter to "<key>\t<value>", emitting A1 for
# a malformed block. Duplicate keys are A1 too: two values for one key is two homes for
# one fact, and picking either silently is the wrong answer to a question the file asks.
va_fm_pairs() {
  local root="$1" rel="$2" body line key val seen=""
  body="$(va_frontmatter "$root/$rel")"   # va-capture: tolerant(1) — a file carrying no frontmatter block is the pre-migration state the tolerant read exists for; 105 of 161 reads on this tree
  [ -n "$body" ] || return 0
  if ! va_fm_terminated "$root/$rel"; then
    printf 'FINDING A1 %s frontmatter block is not terminated\n' "$rel"
    return 1
  fi
  local rc=0
  while IFS= read -r line; do
    line="$(va_trim "$line")"   # va-capture: tolerant(1) — as the schema-side trim above: blank and comment lines trim to nothing
    [ -n "$line" ] || continue
    case "$line" in '#'*) continue ;; esac
    case "$line" in
      *:*) key="$(va_trim "${line%%:*}")"; val="$(va_trim "${line#*:}")" ;;   # va-capture: tolerant(2) — an empty key or value half is a real frontmatter value; pure parameter expansion, nothing to fail
      *)   printf 'FINDING A1 %s field <none> out-of-grammar line -- %s\n' "$rel" "$line"; rc=1; continue ;;
    esac
    # Spelled sets, not ranges — see the VA_LOWER block above. This predicate carried the
    # same collation dependence as the slug one and is fixed with it, so the two classifiers
    # cannot drift apart on what a lowercase character is.
    # shellcheck disable=SC2254
    case "$key" in
      [$VA_LOWER]*) : ;;
      *) printf 'FINDING A1 %s field %s key is not kebab-case\n' "$rel" "$key"; rc=1; continue ;;
    esac
    # shellcheck disable=SC2254
    case "$key" in
      *[!$VA_SLUGBODY]*) printf 'FINDING A1 %s field %s key is not kebab-case\n' "$rel" "$key"; rc=1; continue ;;
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
# The character sets arrive by expansion, which is the intent: the expansion IS the class.
# Quoting it would make the bracket contents a literal string and the predicate would match
# nothing — the same reason va_seg_match above leaves its pattern unquoted.
# shellcheck disable=SC2254
va_type_ok() {
  local t="$1" v="$2" e="${3:-}"
  case "$t" in
    integer) case "$v" in ''|*[!$VA_DIGIT]*) return 1 ;; *) return 0 ;; esac ;;
    date)    case "$v" in [$VA_DIGIT][$VA_DIGIT][$VA_DIGIT][$VA_DIGIT]-[$VA_DIGIT][$VA_DIGIT]-[$VA_DIGIT][$VA_DIGIT]) return 0 ;; *) return 1 ;; esac ;;
    slug)    case "$v" in
               '')                  return 1 ;;
               [!$VA_SLUGHEAD]*)    return 1 ;;
               *[!$VA_SLUGBODY]*)   return 1 ;;
               *)                   return 0 ;;
             esac ;;
    string)  [ -n "$v" ] && return 0 || return 1 ;;
    'list<slug>')
      case "$v" in '['*']') : ;; *) return 1 ;; esac
      local inner="${v#[}"; inner="${inner%]}"
      local IFS=','; local item
      for item in $inner; do
        item="$(va_trim "$item")"   # va-capture: tolerant(1) — an empty list item is adjudicated by the slug type check below, not by this trim
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

  classes="$(va_class_rows "$root")" || { printf '%s\n' "$classes"; return 1; }   # va-capture: guarded:X2 — the file's own worked exemplar: the status is carried AND the emptiness is tested, each with its own X2
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
    lines="$(va_schema_lines "$root" "$rel")" || rc=1   # va-capture: guarded:S2 — the status is carried into rc and va_schema_lines names the cause as S2
    printf '%s\n' "$lines" | grep '^FINDING ' 2>/dev/null   # va-capture: tolerant(1) — the finding-reporting pipeline; a clean schema reports nothing, which is the normal case
    lines="$(printf '%s\n' "$lines" | grep -v '^FINDING ' 2>/dev/null)"   # va-capture: guarded:S2 — the filter feeding the guarded reads below; a schema that is all findings filters to nothing and S2 has already fired

    cid="$(va_schema_get "$lines" class-id)"   # va-capture: guarded:S1 — an absent class-id is S1 below
    art="$(va_schema_get "$lines" artifact)"   # va-capture: guarded:S1 — an absent artifact is S1 below
    ver="$(va_schema_get "$lines" schema-version)"   # va-capture: guarded:S1 — an absent or non-integer schema-version is S1 below

    # S1 — the schema's declared identity must agree with § 1.1's row for its class-id.
    local want=""
    case "$cid" in
      C[0-9]|C[0-9][0-9])
        want="$(printf '%s\n' "$classes" | awk -F'\t' -v n="${cid#C}" '$1 == n { print $2; exit }')" ;;   # va-capture: guarded:S1 — an empty want is S1 below; the case arm only assigns for a well-formed class-id
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
    pats="$(va_schema_all "$lines" path-pattern)"   # va-capture: guarded:S4 — no path-pattern declared is S4 below
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
    wit="$(va_schema_get "$lines" witness)"   # va-capture: tolerant(1) — witness and no-witness-because are mutually exclusive by S7, so exactly one of this pair IS empty for every schema: 1 of 23 here
    nowit="$(va_schema_get "$lines" no-witness-because)"   # va-capture: tolerant(1) — the complement of the witness read above: 22 of 23 here
    if [ -n "$wit" ] && [ -n "$nowit" ]; then
      printf 'FINDING S7 %s declares both witness and no-witness-because; they are mutually exclusive\n' "$rel"; rc=1
    elif [ -z "$wit" ] && [ -z "$nowit" ]; then
      printf 'FINDING S7 %s declares neither witness nor no-witness-because\n' "$rel"; rc=1
    elif [ -n "$wit" ]; then
      if [ ! -e "$root/$wit" ]; then
        printf 'FINDING S5 %s declared witness %s does not exist\n' "$rel" "$wit"; rc=1
      else
        local wfm
        wfm="$(va_fm_pairs "$root" "$wit" 2>/dev/null | awk -F'\t' '$1 == "schema-version" { print $2 }')"   # va-capture: guarded:S6 — a declared witness carrying no schema-version is S6 below
        if [ -z "$wfm" ]; then
          printf 'FINDING S6 %s declared witness %s carries no schema-version -- coverage regression\n' "$rel" "$wit"; rc=1
        fi
      fi
    fi
  done <<EOF   # va-capture: guarded:S8 — an empty schema list leaves corpus_ids empty, and every class then has no schema, which is S8 for all of them
$(va_schema_files "$root")
EOF

  # S8 — bijection with § 1.1. The corpus is asserted against the document, in both
  # directions: a class with no schema is as much a failure as a schema with no class.
  local row n cname
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    n="$(printf '%s\n' "$row" | cut -f1)"   # va-capture: adjudicated — deny: every row is written by va_class_rows' own printf with six tab fields, so an empty field one means cut did not run
    va_read_ok 'va_check_corpus/s8-class-number' "$?" "$n" deny || return 1
    cname="$(printf '%s\n' "$row" | cut -f2)"   # va-capture: adjudicated — deny: an empty class name degenerates the S8 membership test below into a match on the boundary double space
    va_read_ok 'va_check_corpus/s8-class-name' "$?" "$cname" deny || return 1
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
# declared pattern. Memoised per root, so the corpus is parsed once and re-read from the
# cache for the rest of one invocation. Without the memo the selector re-parses every schema
# for every file it considers, which turns a linear walk into a quadratic one.
#
# ── THE CACHE ONLY HOLDS IF SOMETHING WARMS IT IN A PARENT SHELL ─────────────────
# Every call site in this file reaches this function from inside a command substitution or a
# pipeline, and a subshell's assignments die with it — so with nothing warming the globals
# below in va_main's OWN shell, each call was a cold parse and the memo delivered nothing it
# claims. Measured on this repository's tree: 21 cold parses per invocation, 25s against 4s.
# va_main now warms it as a plain command before any of them, and this comment describes what
# happens rather than what was intended. A caller that drives these functions directly —
# which the suite does — still gets the cold path, correctly: nothing has warmed anything.
VA_CACHE_ROOT=""
VA_CACHE_PATTERNS=""
# ── THE POLICY IN THIS FUNCTION IS `allow` THROUGHOUT, AND THAT IS A MEASURED CHOICE ──
# The design that reached here specified `deny` at each of these reads. Every one of them
# was measured against the states this repository's own arms construct, and `deny` is wrong
# at all of them for one reason: what is empty here is empty because of a REPOSITORY
# condition that another finding already names, never because a read failed.
#
#   a root carrying no reference/schemas/  => the schema list is empty at status 0. That is
#   the state the pre-seam conflation arm builds on purpose; X2 on the architecture document
#   reports it, and denying here would replace that finding with a degraded-read one.
#   a schema declaring no path-pattern     => the pattern list is empty at status 0. S4.
#   a malformed schema                     => its lines are empty, at status 1. S2.
#
# The last of those is why the schema-lines read below is NOT adjudicated at all rather than
# adjudicated with a softer policy: its non-zero status IS the corpus-defect signal, and
# va_read_ok cannot tell that apart from a read that did not complete. Reporting S2's fact
# as X3 is the same conflation X3 was introduced to remove, pointed the other way.
va_corpus_patterns() {
  local root="$1" rel lines cid art p files pats
  if [ "$VA_CACHE_ROOT" = "$root" ]; then printf '%s\n' "$VA_CACHE_PATTERNS"; return 0; fi
  local acc=""
  # Captured first and fed to the loop from the variable: a `$(…)` inside a here-document
  # body is expanded during redirection, so its status is lost and there is no statement to
  # attach a test to. This is the same restructure va_select's population feed takes.
  files="$(va_schema_files "$root")"   # va-capture: adjudicated — allow: a root carrying no reference/schemas/ is a real state, reported by X2 on the corpus rather than here
  va_read_ok 'va_corpus_patterns/schema-files' "$?" "$files" allow || return 1
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    lines="$(va_schema_lines "$root" "$rel" 2>/dev/null | grep -v '^FINDING ')"   # va-capture: guarded:S2 — a malformed schema makes this empty AT STATUS 1, and va_check_corpus reads the same schema and reports S2 for it. Adjudicating the status here would report that corpus defect as a degraded read
    cid="$(va_schema_get "$lines" class-id)"   # va-capture: adjudicated — allow: empty follows an empty lines capture, which S1 and S2 already name; the status is what is adjudicated
    va_read_ok "va_corpus_patterns/class-id $rel" "$?" "$cid" allow || return 1
    art="$(va_schema_get "$lines" artifact)"   # va-capture: adjudicated — allow: as the class-id beside it
    va_read_ok "va_corpus_patterns/artifact $rel" "$?" "$art" allow || return 1
    pats="$(va_schema_all "$lines" path-pattern)"   # va-capture: adjudicated — allow: a schema declaring no path-pattern is S4's subject, and it is empty here at status 0
    va_read_ok "va_corpus_patterns/path-patterns $rel" "$?" "$pats" allow || return 1
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      acc="${acc}${cid}${VA_TAB}${art}${VA_TAB}${p}${VA_TAB}${rel}${VA_NL}"
    done <<EOF
$pats
EOF
  done <<EOF
$files
EOF
  VA_CACHE_ROOT="$root"
  VA_CACHE_PATTERNS="${acc%"$VA_NL"}"
  printf '%s\n' "$VA_CACHE_PATTERNS"
}

# va_population <data-root> <scope> [dir] — the candidate file list, before exclusion.
#
# The root here is the DATA root, not the corpus root — every path this emits is relative
# to it, so it is also the root va_select and va_check_artifact must read the files back
# against. ONE population root, used by both arms, so no arm can walk one tree and read
# its content from another. Without --data-root the two roots are the same directory and
# this is the behaviour it has always had.
va_population() {
  local data_root="$1" scope="${2:-tracked}" dir="${3:-}"
  case "$scope" in
    tracked) ( cd "$data_root" && git ls-files 2>/dev/null ) ;;
    dir)     ( cd "$data_root" && find "$dir" -type f 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort ) ;;
    *)       return 1 ;;
  esac
}

# va_select <root> <scope> [dir] [data-root] — "<class-id>\t<artifact>\t<path>\t<arm>" for
# every selected file, plus "EXCLUDED\t<path>" and "UNMATCHED\t<path>" so the whole
# population is accounted for. A denominator you cannot reconstruct is not a denominator.
#
# TWO ROOTS, and the fourth argument is why. <root> is the CORPUS root: the patterns this
# selector ranks against are read from reference/schemas/ beneath it. <data-root> is the
# POPULATION root: the tree walked, and the tree the declared arm reads frontmatter back
# from. It is OPTIONAL and DEFAULTS TO <root>, so every caller written before the seam
# existed — including scripts/test-artifact-schema.sh, which sources this file and calls
# this function directly with two and with three arguments — keeps the behaviour it had.
# Appending rather than inserting is deliberate for the same reason.
va_select() {
  local root="$1" scope="${2:-tracked}" dir="${3:-}" data_root="${4:-$1}"
  local pats pop f best_len best_cid best_art cid art p len plit declared
  pats="$(va_corpus_patterns "$root")"   # va-capture: adjudicated — allow: an empty pattern table is what a root carrying no corpus produces, and the declared arm then resolves every file — the measured shape of the pre-seam conflation, reported by X2 rather than here
  # The captured body is printed before returning, following va_class_rows' exemplar: the
  # pattern builder's own X3 names WHICH read failed, and it lands in this capture rather
  # than on stdout. Swallowing it would leave only the outer finding, which names the seam
  # instead of the cause.
  va_read_ok 'va_select/pattern-table' "$?" "$pats" allow || { printf '%s\n' "$pats"; return 1; }
  # ── THE POPULATION IS CAPTURED HERE RATHER THAN INSIDE THE HERE-DOCUMENT BELOW ──
  # A `$(…)` inside a here-document body is expanded during redirection: there is no
  # statement for a status test to attach to and the producer's status is lost entirely —
  # measured, not inferred. Capturing first and feeding the body from the variable is a
  # shape this file already uses twice, and it is what makes the read adjudicable at all.
  pop="$(va_population "$data_root" "$scope" "$dir")"   # va-capture: adjudicated — allow: an empty population is a real measurement the VACUOUS verdict already reports, and the local-trip arm over an empty directory is exactly that
  va_read_ok 'va_select/population' "$?" "$pop" allow || return 1
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
    declared="$(va_fm_pairs "$data_root" "$f" 2>/dev/null | awk -F'\t' '$1 == "artifact" { print $2; exit }')"   # va-capture: tolerant(1) — the declared-arm probe reads every file the path arm did not claim; 94 of 94 come back empty on this tree and each is an UNMATCHED row. Empty is the answer this arm exists to get
    if [ -n "$declared" ]; then
      cid="$(printf '%s\n' "$pats" | awk -F'\t' -v a="$declared" '$2 == a { print $1; exit }')"   # va-capture: tolerant(1) — an unresolvable class falls back to UNKNOWN by design, which is what raises A2 downstream
      printf '%s\t%s\t%s\tdeclared\n' "${cid:-UNKNOWN}" "$declared" "$f"
      continue
    fi
    printf 'UNMATCHED\t%s\n' "$f"
  done <<EOF
$pop
EOF
}

# ─────────────────────────────────────────────────────────────────────────────────
# Artifact checks — A1..A6
# ─────────────────────────────────────────────────────────────────────────────────

# va_check_artifact <root> <path> <class-id> <artifact> [data-root] — findings on stdout;
# rc 1 on any. Prints "SKIP <path> <class>" and returns 0 for the pre-migration case, so
# the skip is reported by path AND by resolved class rather than merely counted.
#
# TWO ROOTS, the same split va_select carries: <path> is relative to <data-root> and the
# ARTIFACT is read there; the SCHEMA it is graded against is read beneath <root>. This is
# the one function where both reads happen in the same body, which is why conflating them
# was invisible until an install put the two roots in different places. <data-root> is
# OPTIONAL and DEFAULTS TO <root>, so a pre-seam caller is unchanged.
va_check_artifact() {
  local root="$1" rel="$2" cid="$3" art="$4" data_root="${5:-$1}"
  local pairs ver declared fm_body rc=0

  if [ ! -r "$data_root/$rel" ]; then
    printf 'FINDING X2 %s file is unreadable\n' "$rel"; return 1
  fi

  # ── WHY THE FRONTMATTER BLOCK IS READ MORE THAN ONCE ─────────────────────────────
  # An empty `pairs` is AMBIGUOUS on its own, and nothing downstream can disambiguate it.
  # The file may carry no frontmatter block at all — the pre-migration state the tolerant
  # read exists for — or the read that should have produced the pairs may simply not have
  # completed. Those are two different facts and they deserve two different verdicts, but
  # the skip predicate below sees only `ver`, and `ver` is empty in BOTH.
  #
  # TWO READS ANSWER TWO DIFFERENT QUESTIONS AND NEITHER SUBSUMES THE OTHER:
  #
  #   this capture             -> DID va_frontmatter COMPLETE? Adjudicated on STATUS by the
  #                               va_read_ok below, which fails closed when that producer
  #                               exits non-zero.
  #   va_fm_declares_no_field  -> WAS A FIELD EXPECTED? Asked of the file directly, by a
  #                               probe that returns a status and captures nothing.
  #
  # The second is deliberately NOT derived from this capture, and that independence is the
  # correction rather than a refinement of it. Deriving it here was the hole: va_fm_pairs
  # reaches the file's bytes through va_frontmatter too, so a single transient emptied the
  # pairs read and the probe meant to notice it, together, and the limb below went silent at
  # exactly the moment it was needed.
  #
  # It is a second read of bytes va_fm_pairs also reads, and that cost is the price of the
  # distinction. The alternative — widening va_fm_pairs' contract to report the block's
  # presence alongside its pairs — changes a function four other call sites depend on for
  # a fact only this one needs.
  fm_body="$(va_frontmatter "$data_root/$rel")"   # va-capture: adjudicated — allow: a file with no frontmatter block is the tolerant read's own subject, so only the status is adjudicated
  va_read_ok "va_check_artifact/frontmatter-presence $rel" "$?" "$fm_body" allow || return 1

  pairs="$(va_fm_pairs "$data_root" "$rel")" || rc=1   # va-capture: tolerant(1) — 11 of 45 on this tree; the degraded-read limb below is what separates an absent block from a failed read, so this site is adjudicated there rather than here
  printf '%s\n' "$pairs" | grep '^FINDING ' 2>/dev/null   # va-capture: tolerant(1) — the finding-reporting pipeline; a clean artifact reports nothing
  pairs="$(printf '%s\n' "$pairs" | grep -v '^FINDING ' 2>/dev/null)"   # va-capture: tolerant(1) — the filter feeding the reads below; an artifact whose frontmatter is all findings filters to nothing

  ver="$(printf '%s\n' "$pairs" | awk -F'\t' '$1 == "schema-version" { print $2; exit }')"   # va-capture: tolerant(1) — an absent schema-version is the whole subject of the tolerant read
  declared="$(printf '%s\n' "$pairs" | awk -F'\t' '$1 == "artifact" { print $2; exit }')"   # va-capture: tolerant(1) — a file need not declare artifact:; the path arm has already resolved its class

  # ── THE SKIP PREDICATE. Cited, not restated:
  #    reference/data-architecture.md -> "Tolerant read" / "The gate's skip predicate".
  #    absent schema-version => version 0 => SKIP. That is the WHOLE predicate, and the
  #    gate keys on the absence of that one key GIVEN A SUCCESSFUL READ and on nothing
  #    else. The qualification is not a second rule: the document's predicate is about what
  #    an artifact DECLARES, so a read that never delivered the declaration has not reached
  #    the predicate at all. It is evaluated in the limb immediately below, and the sentence
  #    above used to omit it because nothing here could tell the two states apart.
  if [ -z "$ver" ]; then
    # ── THE DEGRADED-READ LIMB. A block that DECLARED AT LEAST ONE FIELD and yielded NO
    # pair, with no finding of its own to account for it, is an incomplete read rather than
    # an artifact declaring no version. X2 is the code this gate already uses for a required
    # input it could not read, and this fails closed instead of reporting a skip — because a
    # SKIP is a claim about the artifact, and nothing was learned about the artifact here.
    #
    # THE FIRST LIMB ASKS WHETHER A FIELD WAS EXPECTED. It used to ask whether `fm_body` was
    # non-empty, and that was wrong in both directions at once.
    #
    #   TOO BROAD — a block of COMMENT lines is non-empty and yields no pair BY THE GRAMMAR'S
    #   OWN DESIGN, va_fm_pairs skipping `#` as legal content. So `---` / `# TODO: add
    #   schema-version` / `---` — a part-migrated artifact, which is precisely the state the
    #   tolerant read exists to protect — failed closed on a repository with nothing wrong
    #   with it, and the message told the operator a read had failed when it had not.
    #
    #   TOO NARROW — `fm_body` comes from va_frontmatter, and va_fm_pairs reaches the file
    #   through va_frontmatter too. One transient empties both, the limb goes false, and the
    #   artifact skips at rc 0 with the run green: the signature this gate exists to remove,
    #   surviving inside the check written to remove it.
    #
    # Both are closed by asking the file rather than the capture. The invariant the limb now
    # rests on is exact: every line va_fm_pairs does not skip either prints a pair or sets a
    # non-zero status, so "a field was declared" AND "no pair arrived" AND "nothing was
    # reported" is unreachable by any complete read.
    #
    # `rc` is part of the predicate rather than decoration. Where va_fm_pairs already
    # returned non-zero it has emitted its own A1 naming the malformation, and the block DID
    # answer — wrongly. Adding X2 on top of that would report one defect twice and name the
    # wrong cause for it.
    if ! va_fm_declares_no_field "$data_root/$rel" && [ -z "$pairs" ] && [ "$rc" -eq 0 ]; then
      printf 'FINDING X2 %s frontmatter block declares at least one field and the read of it returned none\n' "$rel"
      return 1
    fi
    printf 'SKIP %s %s\n' "$rel" "${cid}"
    return 0
  fi

  # ── BOUNDARY NOTE (A2). From here the artifact has declared a version, so the rule's
  # second limb governs: declares a version and violates that version's schema => fails
  # closed. A class the corpus does not cover has no schema to violate, and § 11 names
  # this exact moment. The gate treats it as a broken REPOSITORY rather than a broken
  # artifact — it is an assertion about this repo's internal consistency — and it is
  # deliberately gated behind the version check so an UNVERSIONED artifact naming an
  # unknown class still skips.
  #
  # THE PREDICATE IS "THE CLASS RESOLVES TO NO SCHEMA", NOT "THE CLASS-ID SPELLS UNKNOWN".
  # It is evaluated in TWO places and this is the first of them: the test below is the
  # SENTINEL arm, catching the id va_select's declared arm writes when it cannot resolve a
  # declared class. The second is the lookup's own status, at the schema resolution further
  # down, which catches a class-id that came from the PATH arm and therefore can never spell
  # the sentinel. Both emit this same finding because it is one condition; that it read as
  # two was the defect. No third boundary note is added — this note and A6 are still the two
  # the header enumerates.
  # This note once read that the finding could not fire on a
  # user's trip because the gate could not see one. That warrant no longer holds: the
  # --scope dir arm reaches a trip under trips/, and this finding is not scoped off that
  # arm, so it can fire there and exit non-zero. Whether the repo-consistency findings
  # should be scoped off the local arm is an open decision, recorded here, not settled.
  if [ "$cid" = "UNKNOWN" ] || [ -z "$cid" ]; then
    printf 'FINDING A2 %s field artifact value %s declares schema-version %s but no schema in %s/ covers that class\n' \
      "$rel" "${declared:-<absent>}" "$ver" "$VA_SCHEMA_DIR"
    return 1
  fi

  # ── THE SCHEMA RESOLUTION, STAGED SO EACH OUTCOME GETS ITS OWN VERDICT ───────────
  # This was ONE line — va_schema_lines wrapping a NESTED va_schema_for, with 2>/dev/null
  # outside it and `grep -v '^FINDING '` after it — and every signal that would have named a
  # failure died on it: the lookup's status died in the nested substitution, the parser's
  # status died in the outer one, its stderr died in the redirect, and the FINDING S2 it does
  # emit died in the filter. Four conditions then arrived at the same empty `lines`:
  #
  #   1  the pattern table came back empty        -> a read failure
  #   2  the table is fine; no row covers $cid    -> S8 already calls this a broken corpus
  #   3  a row exists; the schema will not parse  -> a read failure
  #   4  the schema resolves, parses, declares no field -> LEGITIMATE
  #
  # All four were byte-identical to a full clean validation, so the artifact was reported
  # `validated` against a schema nothing had read. Worse than unchecked: findings the gate
  # had ALREADY produced were erased — an artifact carrying five A3 violations returns rc 1
  # with 400 bytes normally and rc 0 with nothing at all under the degradation.
  #
  # Rows 1-3 are intercepted below, each with the finding that names what actually happened.
  # ROW 4 IS PRESERVED BY NOT BEING TOUCHED: once 1-3 return, `lines` is non-empty by
  # construction and the field loop below runs over a legitimately empty field list exactly
  # as it always has — same bytes, same rc, no new branch. Preservation by absence of code is
  # stronger than preservation by a carve-out, because there is no carve-out to get wrong.
  local schema sfrc lines sver
  schema="$(va_schema_for "$root" "$cid")"; sfrc=$?   # va-capture: guarded:A2/X3 — the three-status lookup, each status rendered by the branch immediately below; va_read_ok's two-valued adjudication would report status 1, a class the corpus does not cover, as a degraded read
  if [ "$sfrc" -eq 2 ]; then
    printf '%s\n' "$schema" | grep '^FINDING '   # va-capture: tolerant(1) — re-emits the pattern builder's own X3, which names WHICH read failed; the finding below names the artifact it cost
    printf 'FINDING X3 %s the schema corpus under %s/ could not be read, so class %s resolved to nothing -- the artifact is ungraded\n' \
      "$rel" "$VA_SCHEMA_DIR" "$cid"
    return 1
  fi
  if [ "$sfrc" -ne 0 ] || [ -z "$schema" ]; then
    # The SAME finding the UNKNOWN branch above emits, for the same condition. The defect it
    # replaces was that the guard tested how the class-id was SPELLED: a class-id reaching
    # here from the PATH arm can never spell UNKNOWN, so the identical condition produced
    # opposite verdicts depending on which arm selected the file.
    printf 'FINDING A2 %s field artifact value %s declares schema-version %s but no schema in %s/ covers that class\n' \
      "$rel" "${declared:-<absent>}" "$ver" "$VA_SCHEMA_DIR"
    return 1
  fi
  # Re-emit, then strip — the shape this file already uses at the va_fm_pairs capture above
  # and in va_check_corpus. The parser's status is NOT adjudicated by va_read_ok, for the
  # reason va_corpus_patterns states at its own schema-lines capture: a non-zero here IS the
  # corpus-defect signal, and reporting S2's fact as X3 is the conflation X3 exists to remove
  # pointed the other way. The emptiness is what is tested, and it is tested explicitly.
  lines="$(va_schema_lines "$root" "$schema")"   # va-capture: guarded:S2 — a schema that will not parse emits S2, re-emitted on the next line before being stripped, and the emptiness limb below fails closed on it
  printf '%s\n' "$lines" | grep '^FINDING '   # va-capture: tolerant(1) — the finding-reporting pipeline; a well-formed schema reports nothing
  lines="$(printf '%s\n' "$lines" | grep -v '^FINDING ')"   # va-capture: tolerant(1) — the filter feeding the reads below; a schema that is all findings filters to nothing, which is the limb immediately below
  if [ -z "$lines" ]; then
    printf 'FINDING X2 %s the schema %s declaring class %s could not be read\n' "$rel" "$schema" "$cid"
    return 1
  fi
  sver="$(va_schema_get "$lines" schema-version)"   # va-capture: adjudicated — allow: a schema declaring no schema-version is a real state the A6 limb below already tolerates through its own [ -n ] guard; the STATUS is what is adjudicated
  va_read_ok "va_check_artifact/schema-version $rel" "$?" "$sver" allow || return 1

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
  #
  # Captured first and fed to the loop from the variable, the shape va_corpus_patterns and
  # va_select already use: a `$(…)` inside a here-document BODY is expanded during
  # redirection, so there is no statement for a status test to attach to and the producer's
  # status is lost entirely. Adjudicated `allow`, which is what preserves the legitimate
  # zero-field schema — a schema that parses and declares no field is empty AT STATUS 0, the
  # loop runs zero times, and the artifact validates clean exactly as it does today.
  local fl name req typ enum val fields
  fields="$(va_schema_all "$lines" field)"   # va-capture: adjudicated — allow: a schema declaring no field is the legitimate zero-field case and is empty at status 0; the STATUS is what is adjudicated
  va_read_ok "va_check_artifact/field-list $rel" "$?" "$fields" allow || return 1
  while IFS= read -r fl; do
    [ -n "$fl" ] || continue
    name="${fl%% *}"; fl="${fl#* }"
    req="${fl%% *}"; fl="${fl#* }"
    typ="${fl%% *}"; enum=""
    case "$fl" in *'['*']'*) enum="${fl#*[}"; enum="${enum%]*}" ;; esac
    val="$(printf '%s\n' "$pairs" | awk -F'\t' -v k="$name" '$1 == k { print $2; exit }')"   # va-capture: tolerant(1) — an optional field that is absent has no value; 20 of 284 field reads on this tree, and A3 below grades a REQUIRED one
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
$fields
EOF
  return $rc
}

# va_schema_for <root> <class-id> — the schema file declaring that class. Answered from
# the memoised pattern table rather than by re-walking the corpus per artifact.
#
# ── THREE STATUSES, BECAUSE TWO CANNOT SAY WHAT HAPPENED ─────────────────────────
# This returned a bare non-zero for BOTH "the table was read and no row covers this class"
# and "the table could not be read at all", and its one caller wrapped it in a NESTED
# substitution where even that bare status was lost. Three independent failures and one
# legitimate condition therefore arrived at the same empty value, and the caller reported
# every one of them as a clean validation at rc 0.
#
# The status is widened HERE rather than tested downstream because only this function knows
# which of the two happened; a caller holding an empty string cannot recover it, and a
# caller that merely tests for emptiness re-creates the same conflation one level up.
#
#   0  resolved — the schema path is on stdout, exactly as before
#   1  the table WAS read and no row covers this class — the caller's A2, which is the
#      finding this gate already carries for precisely this condition
#   2  the pattern table could not be READ — the caller's X3. The finding naming WHICH read
#      failed is left on stdout for the caller to re-emit, following va_select's exemplar
#
# `1` keeps the meaning it already had, so the contract is purely ADDITIVE: nothing reading
# a bare non-zero changes verdict. `2` is the next free value and matches va_main's own use
# of 2 for an input that is wrong. A sentinel string on stdout was rejected — stdout carries
# the schema PATH, so a caller that forgot to test it would read the sentinel as a path,
# which is the same fail-open shape this change exists to close.
#
# An EMPTY table is deliberately status 1 and not status 2. A root carrying no
# reference/schemas/ is a real state, named as such at va_corpus_patterns' own capture
# markers and reported by X2 on the corpus; and a table with no rows genuinely covers no
# class, which is what A2 says in terms. Both fail closed, so nothing is admitted either way
# — what differs is whether the finding names a condition that is true.
va_schema_for() {
  local root="$1" cid="$2" rel pats
  pats="$(va_corpus_patterns "$root")"   # va-capture: adjudicated — allow: an empty table is a root carrying no corpus, a real state whose answer is "no row covers this class" at status 1 below, so only the STATUS is adjudicated here
  va_read_ok "va_schema_for/pattern-table $cid" "$?" "$pats" allow || { printf '%s\n' "$pats"; return 2; }
  rel="$(printf '%s\n' "$pats" | awk -F'\t' -v c="$cid" '$1 == c { print $4; exit }')"   # va-capture: adjudicated — allow: no row for this class is the real answer status 1 reports below, so only the STATUS is adjudicated
  va_read_ok "va_schema_for/class-lookup $cid" "$?" "$rel" allow || return 2
  [ -n "$rel" ] || return 1
  printf '%s' "$rel"
}

# ─────────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────────
va_usage() {
  cat <<'USAGE'
usage: validate-artifacts.sh [--root <dir>] [--data-root <dir>] [--scope tracked|dir <path>]

  --root <dir>          ENGINE root -- roots the schema corpus, reference/data-architecture.md
                        and reference/schemas/ (default: this script's parent directory)
  --data-root <dir>     OPERATOR DATA root -- roots the scanned population and every artifact
                        read (default: whatever --root resolved to, so a run that passes no
                        flag behaves exactly as it did before this seam existed)
  --scope tracked       every git-tracked file (default) -- the CI arm
  --scope dir <path>    every file beneath <path> -- the local-trip arm

<path> under --scope dir is relative to --data-root. The two roots are the same directory in
a checkout and diverge once the engine is installed: the engine carries the schema corpus, the
operator carries the trips. Passing --root at an operator data home points the corpus at a
directory that has none -- which is the whole reason --data-root is spelled separately.

Exit 0 when no finding fired; 1 otherwise. Every finding names the artifact and, where
the finding is field-scoped, the field.
USAGE
}

# va_main_unwind — restore the invocation-scoped corpus cache, and nothing else.
#
# It is called on every return path of va_main BELOW the warm-up, which the adjudications
# added there made more than one. Bash scopes function locals DYNAMICALLY, so va_main's own
# saved values are visible here; the `-` defaults mean a call from anywhere else clears the
# cache rather than aborting under `set -u`, which is the safe direction for a helper whose
# only job is to stop a stale pattern table outliving the run that built it.
va_main_unwind() {
  VA_CACHE_ROOT="${va_cache_root_in-}"; VA_CACHE_PATTERNS="${va_cache_patterns_in-}"
}

va_main() {
  local root="" scope="tracked" dir="" data_root="" data_root_explicit=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --root)  root="${2:-}"; shift 2 ;;
      # Both spellings, matching publish-trip-site.sh's parse_data_root, so an operator
      # who learned the seam on one granted script types it the same way on the other.
      --data-root)  data_root="${2:-}"; data_root_explicit=1; shift 2 ;;
      --data-root=*) data_root="${1#--data-root=}"; data_root_explicit=1; shift ;;
      --scope) scope="${2:-}"; shift 2
               if [ "$scope" = "dir" ]; then dir="${1:-}"; shift; fi ;;
      -h|--help) va_usage; return 0 ;;
      *) printf 'unknown argument: %s\n' "$1" >&2; va_usage >&2; return 2 ;;
    esac
  done
  if [ -z "$root" ]; then
    root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # va-capture: adjudicated(2) — deny: a root that does not resolve makes every read below relative to the wrong tree
    # The nested capture's own status is unrecoverable — an inner substitution's failure is
    # lost to the outer one, verified — so this adjudicates the OUTER read. That is the whole
    # of what is reachable here, and it is enough: an unresolvable engine root yields an
    # empty root and every read beneath it would then be relative to the filesystem root.
    va_read_ok 'va_main/engine-root' "$?" "$root" deny || return 1
  fi

  # ── THE DATA ROOT. An ARGUMENT and never an environment variable, for the reason
  # publish-trip-site.sh's _GUARD_DATA_ROOT block states about its own declaration: an
  # environment-defaulted path on a fail-closed control is a fail-open surface, and an
  # argument is visible in the invocation a verb's grant admits while an inherited
  # variable is not. There is no ${VA_DATA_ROOT:-} read anywhere in this file, and that
  # absence is the control.
  #
  # It defaults to whatever --root resolved to rather than to the engine root, because
  # --root alone has always moved the population as well as the corpus. Defaulting to the
  # engine would silently change that arm, which is a regression wearing a fix's clothes.
  if [ "$data_root_explicit" = "1" ]; then
    # Validated once, loudly, at the seam — never silently fallen back from. A --data-root
    # that does not resolve is an operator error with a remedy; reverting to the engine
    # root would turn it into a read of the record-free store skeleton, which is exactly
    # the clean, confident, wrong answer this seam exists to remove.
    if [ -z "$data_root" ]; then
      # `printf --` is load-bearing on BOTH of these, not decoration: the format string
      # begins with `--`, which bash's printf otherwise parses as an option terminator and
      # then rejects as an invalid one. Measured — the message rendered as
      # "printf: --: invalid option" before the terminator was added here.
      printf -- '--data-root was given an empty path.\n' >&2; return 2
    fi
    if [ ! -d "$data_root" ] || [ ! -r "$data_root" ]; then
      printf -- '--data-root is not a readable directory: %s\n' "$data_root" >&2; return 2
    fi
    data_root="$(cd "$data_root" && pwd)"   # va-capture: guarded:X2 — preceded by the -d and -r tests immediately above, which refuse at rc 2 before this runs
  else
    data_root="$root"
  fi

  # ── THE SCOPE MUST RESOLVE BEFORE ANYTHING IS COUNTED (X2) ─────────────────────
  # `find` on a path that does not exist writes to stderr and yields nothing, and
  # va_population discards that stderr — so a MISTYPED trip name produced the same empty
  # population, the same POPULATION line and the same rc 0 as a real directory holding no
  # files. The two outputs were byte-identical. A user who fat-fingers a trip name was
  # therefore told their trip was clean, which is the one answer this gate must never give
  # for a question it never asked.
  #
  # These are two different facts and they now take two different verdicts. A scope that does
  # not RESOLVE is X2 — the code this gate already uses for a required input that is absent or
  # unreadable — and it fails closed. A scope that resolves to an EMPTY population is not an
  # error at all; it is reported by the VACUOUS verdict at the end of this function. Keeping
  # them separate is the whole point: a single verdict covering both would say less than
  # either, and the empty-but-real case would inherit a failure it does not deserve.
  if [ "$scope" = "dir" ]; then
    local target
    case "$dir" in
      '') printf 'FINDING X2 <none> --scope dir requires a path\n'; return 1 ;;
      /*) target="$dir" ;;
      # Against the DATA root, because this is the same path va_population will walk and
      # a resolution probe that resolved against a different root than the walk would
      # green-light a scope the walk then finds empty.
      *)  target="$data_root/$dir" ;;
    esac
    if [ ! -d "$target" ]; then
      printf 'FINDING X2 %s the --scope dir target does not exist or is not a directory\n' "$dir"
      return 1
    fi
  fi

  local rc=0 out sel

  # ── THE CORPUS CACHE IS WARMED HERE, IN THIS FUNCTION'S OWN SHELL ───────────────
  # va_corpus_patterns memoises into the two globals below, and every call site beneath
  # this line reaches it from inside a command substitution or a pipeline — so those writes
  # died with the subshell that made them and the corpus was re-parsed once per selected
  # artifact. This one plain command populates the globals HERE, and every subshell below
  # then inherits a warm cache and answers from it. Measured: 21 cold parses per invocation
  # before, 1 after, with stdout byte-identical. It buys no new behaviour and it is not
  # meant to: it removes roughly six-sevenths of the wall time this run spends forking, and
  # with it the window in which a transient subprocess failure can land. Its own output and
  # status are discarded on purpose: this is a warm-up, and a builder that cannot build is
  # met again — and reported — at the real call site inside va_select.
  #
  # ── AND IT IS RESTORED ON THE WAY OUT, WHICH IS NOT OPTIONAL ────────────────────
  # A PROCESS-LIFETIME cache would be read by the NEXT va_main call in the same shell —
  # which scripts/test-artifact-schema.sh makes on every run, against several roots, one of
  # which it has just built — and a pattern table from a previous root is a confident wrong
  # answer. Saving and restoring bounds the cache's life to this invocation, during which
  # the corpus cannot change. Every return path AFTER this point restores; the returns
  # ABOVE it are argument and scope refusals that never warmed anything.
  local va_cache_root_in="$VA_CACHE_ROOT" va_cache_patterns_in="$VA_CACHE_PATTERNS"
  va_corpus_patterns "$root" >/dev/null

  out="$(va_check_corpus "$root")" || rc=1   # va-capture: tolerant(1) — a clean corpus emits nothing; 1 of 1 on this tree, and the status is already carried into rc
  [ -n "$out" ] && printf '%s\n' "$out"

  sel="$(va_select "$root" "$scope" "$dir" "$data_root")"   # va-capture: adjudicated — allow: an empty selection is a real measurement the VACUOUS verdict reports, and the local-trip arm over an empty directory is exactly that
  # The captured body is printed before returning, following va_class_rows' exemplar above:
  # a selector that failed has already said why, and swallowing that leaves the X3 as the
  # only thing a reader sees.
  va_read_ok 'va_main/select' "$?" "$sel" allow || { printf '%s\n' "$sel"; va_main_unwind; return 1; }
  local nsel nexc nunm nskip=0 nver=0
  # Counted with awk on the TAB-delimited field, never with a shell pattern carrying a
  # literal tab: a tab inside shell quoting is invisible in a diff and one editor pass
  # that converts it to spaces would silently zero this denominator.
  nsel="$(printf '%s\n' "$sel" | awk -F'\t' 'NF>1 && $1!="EXCLUDED" && $1!="UNMATCHED" {n++} END{print n+0}')"   # va-capture: impossible(1) — awk's END{print n+0} always emits; empty here would mean awk did not run at all
  nexc="$(printf '%s\n' "$sel" | awk -F'\t' '$1=="EXCLUDED" {n++} END{print n+0}')"   # va-capture: impossible(1) — as the selected count above
  nunm="$(printf '%s\n' "$sel" | awk -F'\t' '$1=="UNMATCHED" {n++} END{print n+0}')"   # va-capture: impossible(1) — as the selected count above

  local line cid art path arm res
  while IFS= read -r line; do
    # ── THE EMPTY-LINE GUARD IS WHAT MAKES `deny` SAFE TWO LINES DOWN ──────────────
    # An empty `sel` still feeds this loop one empty line, because the here-document body
    # below is `$sel` and a `printf '%s\n' ""` is one newline. That line's field one is
    # legitimately empty, and without this guard the `deny` adjudication would fire on it —
    # turning the VACUOUS case, which is a real and correct measurement of an empty tree,
    # into a failure. The `case` below already skipped that line, so this guard changes
    # nothing about what runs; it changes what the adjudication is allowed to conclude.
    [ -n "$line" ] || continue
    cid="$(printf '%s\n' "$line" | cut -f1)"   # va-capture: adjudicated — deny: field one of a row va_select wrote unconditionally; empty means cut did not run, and the case below then skips the artifact while the POPULATION line still reads correct
    va_read_ok 'va_main/row-class-id' "$?" "$cid" deny || { va_main_unwind; return 1; }
    case "$cid" in ''|EXCLUDED|UNMATCHED) continue ;; esac
    art="$(printf '%s\n' "$line" | cut -f2)"   # va-capture: adjudicated — allow: the artifact name is carried into messages only
    va_read_ok 'va_main/row-artifact' "$?" "$art" allow || { va_main_unwind; return 1; }
    path="$(printf '%s\n' "$line" | cut -f3)"   # va-capture: adjudicated — deny: this is the path the artifact is read from; empty means the wrong file, or none, is checked
    va_read_ok 'va_main/row-path' "$?" "$path" deny || { va_main_unwind; return 1; }
    arm="$(printf '%s\n' "$line" | cut -f4)"   # va-capture: adjudicated — allow: the arm is carried into the SKIP line only
    va_read_ok 'va_main/row-arm' "$?" "$arm" allow || { va_main_unwind; return 1; }
    res="$(va_check_artifact "$root" "$path" "$cid" "$art" "$data_root")" || rc=1   # va-capture: tolerant(1) — a clean artifact emits nothing; 34 of 45 on this tree, and the status is already carried into rc
    case "$res" in
      'SKIP '*) nskip=$((nskip+1)); printf '%s (arm: %s)\n' "$res" "$arm" ;;
      *) nver=$((nver+1)); [ -n "$res" ] && printf '%s\n' "$res" ;;
    esac
  done <<EOF
$sel
EOF

  printf 'POPULATION selected=%s excluded=%s unmatched=%s\n' "$nsel" "$nexc" "$nunm"
  printf 'PREDICATE skipped=%s validated=%s\n' "$nskip" "$nver"

  # ── A GREEN OVER AN EMPTY POPULATION IS VACUOUS, NOT PASSING ───────────────────
  # scripts/test-artifact-schema.sh has rendered this verdict on the CI arm since it shipped
  # (AR5), for the reason its own header states: an assertion over the empty set is vacuously
  # true, never skipped, silently green — a green that proves less than it looks like, which
  # is worse than no check because it reads as proof. The arm a user runs BY HAND rendered no
  # such verdict, which left the one surface reached directly as the only place where a pass
  # over nothing still read as a pass.
  #
  # It is a REPORT and deliberately not a failure. An empty population is a real measurement
  # of the tree and there is nothing wrong with it; what it is not is evidence that anything
  # was checked. Keyed on the SELECTED count rather than on the scope, because the property
  # belongs to the population and not to the arm that produced it. Distinct from the X2 above,
  # which is a scope that never resolved — that one fails closed, this one does not.
  if [ "$nsel" -eq 0 ]; then
    printf 'VACUOUS no file was selected, so nothing was validated and nothing was skipped. A green over zero selected files is vacuous, not passing -- the POPULATION line above is the measurement, and it is a statement about the tree rather than about the artifacts in it\n'
  fi
  # The cache's life ends with this invocation — see the warm-up note above.
  va_main_unwind
  return $rc
}

# Run only when executed directly; sourcing (e.g. for tests) exposes functions without
# dispatch. Same shape as publish-trip-site.sh, deliberately — one pattern, one reading.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  va_main "$@"
fi
