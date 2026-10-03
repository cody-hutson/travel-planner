#!/usr/bin/env bash
#
# Lints every scripts/*.sh with shellcheck at the severity .github/workflows/shell-lint.yml
# declares, and shows on every run, before it reads a real file, that the lint can still fail.
#
# WHAT IT RUNS. Two passes over the same files. Both always run, so a red first pass never
# hides the second:
#   1. --severity=warning                   every finding at warning or error
#   2. --severity=style --include=SC2006    one style-level rule, by name: a command
#                                           substitution written with backticks
# The second pass exists because the defect that motivated this gate -- a backtick
# substitution inside a double-quoted FAIL message, on the limb that fires -- is reported by
# SC2006 alone, and SC2006 sits at style, below the first pass's floor. A $(...) substitution
# inside double quotes is this repository's house idiom and neither pass reports it.
#
# HOW IT READS. --norc, so no shellcheckrc on the reader's machine can change the verdict;
# --external-sources with --source-path=SCRIPTDIR, so a `# shellcheck source=` directive
# resolves to the file beside the script that carries it; --format=gcc, one line per finding.
# --extended-analysis=false, so the linter's dataflow analysis does not run. On this
# repository's largest suites that analysis needs more memory than a hosted runner has, and
# the job is stopped before it reports anything. The rules that need it are therefore not
# reported here, among them SC2324 (n+=1 appending where an increment was meant), SC2320
# ($? read after an echo or a printf), SC2319 ($? read after a test has overwritten it) and
# SC2318 (a name assigned and read in the same declaration, such as declare or local, where
# the read sees the old value) at this gate's severity, and SC2317 (a command that cannot be
# reached) below it. Arms C6 and C7 measure that boundary on every run.
# The linter takes options from one more place, the environment variable SHELLCHECK_OPTS, and
# --norc does not govern it: an exclusion set there lowers the count while every control arm
# still passes. So the run refuses while that variable is non-empty, and prints its value.
#
# THE CONTROL ARMS, built in a temporary directory on every run. The C arms are graded by the
# linter, with the same options as the real files; C6 alone adds one, which turns the dataflow
# analysis back on:
#   C1  SC2006 pass,  must fire      a backtick substitution in a double-quoted FAIL message
#   C2  SC2006 pass,  must not fire  the same message, with the substitution written $(...)
#   C3  warning pass, must fire      a variable assigned and never read
#   C4  warning pass, must not fire  the same variable, read
#   C5  SC2006 pass,  must not fire  backticks meant as literal text, each behind a backslash
#   C6  warning pass, must fire      with the dataflow analysis on: n+=1 meant as an increment,
#                                    which only that analysis reports (SC2324)
#   C7  warning pass, must not fire  the same file under this gate's own options
# The O and D arms grade the checks this file makes itself, without the linter:
#   O1  options check,   must fire      SHELLCHECK_OPTS carrying an exclusion
#   O2  options check,   must not fire  the variable empty
#   D1  directive scan,  must fire      each spelling of a directive that disables every rule
#   D2  directive scan,  must not fire  the near-misses: a coded directive, another key that
#                                       holds the same word, the form quoted inside a comment,
#                                       the same text inside a reason
#   D3  directive count, must fire      a directive before its file's first command
#   D4  directive count, must not fire  the same directive after the first command
# A control that misreads refuses the run: a lint that cannot fail on its own fixture cannot
# vouch for a clean reading of the real tree.
#
# WHICH SHELLCHECK. The one first on PATH. Findings differ between shellcheck versions, so CI
# installs one pinned upstream release and sets SHELLCHECK_EXPECT_VERSION, and any other
# version refuses. Left unset, the version is reported and not enforced, so the file runs
# under whatever shellcheck a contributor has.
#
# SCOPE. scripts/*.sh at the top level, by name. A shell file anywhere else, or one without
# the .sh suffix, is not linted here, and neither is shell embedded in a workflow -- actionlint
# reads that, in .github/workflows/security.yml.
#
# DIRECTIVES. A disable= directive is a finding nobody is shown again, so every run counts
# them: how many the files carry, and how many sit before their file's first command, where a
# directive covers the whole file. A directive whose list holds the word all is refused: it
# leaves its file, or the command under it, unread, and an unread file must not print LINT
# CLEAN. The scan reads lines, not shell. On a comment line the directive is the comment
# itself; on a line of code it is any comment the line carries, because the linter honors a
# directive that follows a semicolon, a then, a do or an opening brace. Text of that shape
# inside a string or a heredoc is therefore counted as well, and refused where it holds that
# word, which is the safe direction. A range of codes wide enough to cover every rule is
# counted and not refused.
#
# SUPPRESSING A FINDING. Fix it where you can. Where the flagged construct is the intent, put
#   # shellcheck disable=SC<code>  # <why the construct is deliberate>
# on the line above it, the reason on the directive's own line.
# A backtick finding from the second pass is not fixed by retyping it. Decide first what the
# backticks are for. Meant as literal text -- a file name or a command quoted in a message --
# they take a backslash before each backtick, or the text moves into single quotes. Only a
# substitution that is meant to run becomes $(...). Rewriting literal backticks as $(...)
# silences the pass and keeps the command running, which is the defect this gate exists to
# stop.
#
# Exit 0 clean / 1 finding(s) / 2 refused -- SHELLCHECK_OPTS set, no shellcheck on PATH, a
# version other than the expected one, no scripts/*.sh, a control arm that misread, a
# directive that disables every rule, or shellcheck failing to finish.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 2
cd "$ROOT" || exit 2

SC_OPTS=(--norc --external-sources --source-path=SCRIPTDIR --format=gcc --extended-analysis=false)
PASS1=(--severity=warning)
PASS2=(--severity=style --include=SC2006)

refuse() {
  printf 'REFUSED: %s\n' "$1"
  exit 2
}

# The number of findings in one gcc-format report: one line each, ending in the rule code.
count_findings() {
  awk '/\[SC[0-9]+\]$/ { n++ } END { print n + 0 }' <<<"$1"
}

# True when the value given, SHELLCHECK_OPTS's, would hand the linter an option.
opts_given() {
  [ -n "$1" ]
}

# directive_scan <file>...   Reads every line of every file given and prints
#   EARLY <file>:<line>   for each disable= directive before its file's first command
#   ALL <file>:<line>     for each disable= directive whose list holds the word all
#   COUNT <directives> <before the first command> <holding all> <files> <lines>   last, once
# A directive is a comment that opens with the linter's name and runs to the next `#`. On a
# comment line only the comment itself can be one. On a line of code every `#` is tried: the
# text before it may be a string, and a scan that stopped at the first would miss the comment
# after it.
directive_scan() {
  LC_ALL=C awk '
    FNR == 1 { files++; started = 0 }
    {
      lines++
      line = $0
      sub(/^[ \t]+/, "", line)
      comment = (line ~ /^#/)
      rest = line
      while (match(rest, /#[ \t]*shellcheck[ \t]+[^#]*/)) {
        if (comment && RSTART != 1) break
        text = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        if (text ~ /[ \t]disable=/) {
          total++
          if (comment && !started) { early++; printf "EARLY %s:%d\n", FILENAME, FNR }
          if (text ~ /[ \t]disable=[^ \t]*all/) { all++; printf "ALL %s:%d\n", FILENAME, FNR }
        }
        if (comment) break
      }
      if (line != "" && !comment) started = 1
    }
    END { printf "COUNT %d %d %d %d %d\n", total, early, all, files, lines }
  ' "$@"
}

printf 'SHELL SCRIPT LINT -- shellcheck over scripts/*.sh, two passes, both always run\n'

if opts_given "${SHELLCHECK_OPTS:-}"; then
  refuse "SHELLCHECK_OPTS is set to '${SHELLCHECK_OPTS:-}' -- the linter takes options from that variable and --norc does not govern it, so this run would not read what CI reads. Unset it and run again"
fi

command -v shellcheck >/dev/null 2>&1 \
  || refuse "no shellcheck on PATH, so nothing was linted"
SC_PATH="$(command -v shellcheck)"
SC_VERSION="$(shellcheck --version | awk '$1 == "version:" { print $2 }')"
[ -n "$SC_VERSION" ] \
  || refuse "shellcheck at $SC_PATH reported no version, so the reading cannot be pinned"
printf 'shellcheck %s at %s\n' "$SC_VERSION" "$SC_PATH"
if [ -n "${SHELLCHECK_EXPECT_VERSION:-}" ] && [ "$SC_VERSION" != "$SHELLCHECK_EXPECT_VERSION" ]; then
  refuse "shellcheck $SC_VERSION is not the expected $SHELLCHECK_EXPECT_VERSION -- findings differ between versions, and this gate is measured at the expected one"
fi
printf 'pass 1: shellcheck %s %s\n' "${SC_OPTS[*]}" "${PASS1[*]}"
printf 'pass 2: shellcheck %s %s\n' "${SC_OPTS[*]}" "${PASS2[*]}"
printf 'options from the environment: none -- SHELLCHECK_OPTS is empty\n'

shopt -s nullglob
FILES=(scripts/*.sh)
shopt -u nullglob
[ "${#FILES[@]}" -gt 0 ] \
  || refuse "no scripts/*.sh under $ROOT -- a lint over an empty population asserts nothing"
printf 'population: %s file(s)\n' "${#FILES[@]}"
printf '  %s\n' "${FILES[@]}"

# ── The control arms ──────────────────────────────────────────────────────────────
WORK="$(mktemp -d "${TMPDIR:-/tmp}/lint-shell.XXXXXX")" \
  || refuse "could not create a temporary directory for the control fixtures"
trap 'rm -rf "$WORK"' EXIT

# The fixtures are written from quoted heredocs: nothing in them is expanded here, and the
# linter reads none of their text as part of this file.
cat > "$WORK/c1.sh" <<'FIXTURE'
#!/usr/bin/env bash
FAIL() { printf 'FAIL %s\n' "$*"; }
f=/dev/null
FAIL "C1: the file has `wc -l < "$f"` lines"
FIXTURE
cat > "$WORK/c2.sh" <<'FIXTURE'
#!/usr/bin/env bash
FAIL() { printf 'FAIL %s\n' "$*"; }
f=/dev/null
FAIL "C2: the file has $(wc -l < "$f") lines"
FIXTURE
cat > "$WORK/c3.sh" <<'FIXTURE'
#!/usr/bin/env bash
c3_unread=1
FIXTURE
cat > "$WORK/c4.sh" <<'FIXTURE'
#!/usr/bin/env bash
c4_read=1
printf '%s\n' "$c4_read"
FIXTURE
cat > "$WORK/c5.sh" <<'FIXTURE'
#!/usr/bin/env bash
FAIL() { printf 'FAIL %s\n' "$*"; }
FAIL "C5: run \`wc -l\` on the file to count its lines"
FIXTURE
cat > "$WORK/c6.sh" <<'FIXTURE'
#!/usr/bin/env bash
c6_count=1
c6_count+=1
printf '%s\n' "$c6_count"
FIXTURE

# The directive fixtures are assembled as they are written, the linter's name and the word
# under test passed as arguments. A heredoc would put each directive on a line of this file,
# and the scan below reads this file as it reads every scripts/*.sh: it would count the
# fixtures as this file's own suppressions, and refuse on the ones D1 plants.
{
  printf '#!/usr/bin/env bash\n'
  printf 'echo start\n'
  printf '# %s disable=%s\n' shellcheck all
  printf '  # %s disable=SC2086,%s\n' shellcheck all
  printf 'true; # %s disable=%s\n' shellcheck all
  printf '# %s shell=bash disable="%s"\n' shellcheck all
  printf 'echo end\n'
} > "$WORK/d1.sh"
{
  printf '#!/usr/bin/env bash\n'
  printf 'echo start\n'
  printf '# %s disable=SC2034  # only its status is graded\n' shellcheck
  printf '# %s enable=%s\n' shellcheck all
  printf '#   # %s disable=%s\n' shellcheck all
  printf '# %s disable=SC2034  # never disable=%s\n' shellcheck all
  printf 'echo end\n'
} > "$WORK/d2.sh"
{
  printf '#!/usr/bin/env bash\n'
  printf '# a header comment\n'
  printf '# %s disable=SC2034\n' shellcheck
  printf 'd3_first=1\n'
  printf 'd3_second=2\n'
} > "$WORK/d3.sh"
{
  printf '#!/usr/bin/env bash\n'
  printf '# a header comment\n'
  printf 'd4_first=1\n'
  printf '# %s disable=SC2034\n' shellcheck
  printf 'd4_second=2\n'
} > "$WORK/d4.sh"

CONTROL_FAILED=0
# control <id> <pass: 1|2> <want: fire|silent> <code> <fixture> <what it models> [<option>]
# The optional last argument is one more option, given after this gate's own. The linter
# takes the later of two settings of the same option, so an arm can differ from the real
# reading by exactly that one.
control() {
  local id="$1" pass="$2" want="$3" code="$4" file="$5" what="$6" more="${7:-}" out rc n
  if [ "$pass" = 1 ]; then
    out="$(shellcheck "${SC_OPTS[@]}" ${more:+"$more"} "${PASS1[@]}" "$file" 2>&1)"; rc=$?
  else
    out="$(shellcheck "${SC_OPTS[@]}" ${more:+"$more"} "${PASS2[@]}" "$file" 2>&1)"; rc=$?
  fi
  n="$(count_findings "$out")"
  if [ "$want" = fire ] && [ "$rc" -eq 1 ] && [ "$n" -eq 1 ] && [[ "$out" == *"[$code]"* ]]; then
    printf 'CONTROL %s PASS: pass %s fires exactly once, %s -- %s\n' "$id" "$pass" "$code" "$what"
  elif [ "$want" = silent ] && [ "$rc" -eq 0 ] && [ "$n" -eq 0 ]; then
    printf 'CONTROL %s PASS: pass %s stays silent -- %s\n' "$id" "$pass" "$what"
  else
    printf 'CONTROL %s FAIL: pass %s exited %s with %s finding(s), wanted %s -- %s\n' \
      "$id" "$pass" "$rc" "$n" "$want" "$what"
    [ -n "$out" ] && printf '%s\n' "$out"
    CONTROL_FAILED=1
  fi
}
# opts_control <id> <want: fire|silent> <a value of SHELLCHECK_OPTS> <what it models>
opts_control() {
  local id="$1" want="$2" value="$3" what="$4" got=silent
  if opts_given "$value"; then got=fire; fi
  if [ "$got" != "$want" ]; then
    printf 'CONTROL %s FAIL: the options check answered %s, wanted %s -- %s\n' \
      "$id" "$got" "$want" "$what"
    CONTROL_FAILED=1
  elif [ "$want" = fire ]; then
    printf 'CONTROL %s PASS: the options check refuses -- %s\n' "$id" "$what"
  else
    printf 'CONTROL %s PASS: the options check stays silent -- %s\n' "$id" "$what"
  fi
}
# scan_control <id> <fixture> <want: the scan's five COUNT fields> <what it models>
scan_control() {
  local id="$1" file="$2" want="$3" what="$4" out got total early all lines
  out="$(cd "$WORK" && directive_scan "$file")"
  got="${out##*$'\n'}"
  if [ "$got" = "COUNT $want" ]; then
    read -r _ total early all _ lines <<<"$got"
    printf 'CONTROL %s PASS: the scan reads %s line(s) and finds %s directive(s), %s before the first command, %s disabling every rule -- %s\n' \
      "$id" "$lines" "$total" "$early" "$all" "$what"
  else
    printf 'CONTROL %s FAIL: the scan answered "%s", wanted "COUNT %s" -- %s\n' \
      "$id" "$got" "$want" "$what"
    CONTROL_FAILED=1
  fi
}
control C1 2 fire   SC2006 "$WORK/c1.sh" "a backtick substitution inside a double-quoted FAIL message"
control C2 2 silent SC2006 "$WORK/c2.sh" "the same message, the substitution written \$(...)"
control C3 1 fire   SC2034 "$WORK/c3.sh" "a variable assigned and never read"
control C4 1 silent SC2034 "$WORK/c4.sh" "the same variable, read"
control C5 2 silent SC2006 "$WORK/c5.sh" "backticks meant as literal text, each behind a backslash"
control C6 1 fire   SC2324 "$WORK/c6.sh" "with the dataflow analysis turned back on: n+=1 meant as an increment, which only that analysis reports" --extended-analysis=true
control C7 1 silent SC2324 "$WORK/c6.sh" "the same file under this gate's own options, which read without that analysis"
opts_control O1 fire   '--exclude=SC2034' "SHELLCHECK_OPTS carrying an exclusion"
opts_control O2 silent ''                 "the variable empty"
scan_control D1 d1.sh "4 0 4 1 7" "a directive that disables every rule: on its own line, as one member of a list, after code on the same line, and quoted behind another key"
scan_control D2 d2.sh "2 0 0 1 7" "the near-misses: a coded directive with its reason, another key holding the same word, the form quoted inside a comment, and the key and word inside a reason"
scan_control D3 d3.sh "1 1 0 1 5" "a coded directive before its file's first command"
scan_control D4 d4.sh "1 0 0 1 5" "the same directive after the first command"
[ "$CONTROL_FAILED" -eq 0 ] \
  || refuse "a control arm misread, so a clean reading of scripts/*.sh would prove nothing"

# ── The directives the real files carry ──────────────────────────────────────────
SCAN="$(directive_scan "${FILES[@]}")" \
  || refuse "the directive scan did not finish, so the files' suppressions are uncounted"
case "${SCAN##*$'\n'}" in
  COUNT\ *) read -r _ D_TOTAL D_EARLY D_ALL D_FILES D_LINES <<<"${SCAN##*$'\n'}" ;;
  *) refuse "the directive scan printed no count, so the files' suppressions are uncounted" ;;
esac
[ "$D_FILES" -eq "${#FILES[@]}" ] \
  || refuse "the directive scan read $D_FILES of ${#FILES[@]} file(s), so its count is not the population's"
printf "directives: %s disable= directive(s) in %s file(s), %s line(s) read; %s sit before their file's first command, where a directive covers the whole file\n" \
  "$D_TOTAL" "$D_FILES" "$D_LINES" "$D_EARLY"
while IFS= read -r scan_line; do
  case "$scan_line" in
    EARLY\ *) printf '  before the first command: %s\n' "${scan_line#EARLY }" ;;
    ALL\ *)   printf '  disables every rule: %s\n' "${scan_line#ALL }" ;;
  esac
done <<<"$SCAN"
[ "$D_ALL" -eq 0 ] \
  || refuse "$D_ALL directive(s) disable every rule, at the line(s) named above -- such a file, or the command under the directive, is not read, and an unread file must not print LINT CLEAN. Name the codes instead, each with its reason"

# ── The real files ───────────────────────────────────────────────────────────────
P1_OUT="$(shellcheck "${SC_OPTS[@]}" "${PASS1[@]}" "${FILES[@]}" 2>&1)"; P1_RC=$?
P2_OUT="$(shellcheck "${SC_OPTS[@]}" "${PASS2[@]}" "${FILES[@]}" 2>&1)"; P2_RC=$?
case "$P1_RC" in 0|1) ;; *) printf '%s\n' "$P1_OUT"; refuse "pass 1 did not finish (shellcheck exited $P1_RC)" ;; esac
case "$P2_RC" in 0|1) ;; *) printf '%s\n' "$P2_OUT"; refuse "pass 2 did not finish (shellcheck exited $P2_RC)" ;; esac
N1="$(count_findings "$P1_OUT")"
N2="$(count_findings "$P2_OUT")"
[ "$N1" -eq 0 ] || printf '%s\n' "$P1_OUT"
[ "$N2" -eq 0 ] || printf '%s\n' "$P2_OUT"
printf 'pass 1 (severity warning): %s finding(s) over %s file(s)\n' "$N1" "${#FILES[@]}"
printf 'pass 2 (SC2006, backtick substitution): %s finding(s) over %s file(s)\n' "$N2" "${#FILES[@]}"
[ "$N2" -eq 0 ] \
  || printf "PASS 2 REMEDY -- decide what the backticks are for before changing them. Meant as literal text, they take a backslash before each backtick, or the text moves into single quotes; only a substitution that is meant to run becomes \$(...). Rewriting literal backticks as \$(...) silences this pass and keeps the command running.\n"
if [ "$P1_RC" -eq 0 ] && [ "$P2_RC" -eq 0 ]; then
  printf 'LINT CLEAN -- both passes read every file and reported nothing, and every control arm fired as stated.\n'
  exit 0
fi
printf 'LINT FAILED -- fix each finding above or, where the construct is the intent, suppress it in place with a reason, in the form the header of scripts/lint-shell.sh gives.\n'
exit 1
