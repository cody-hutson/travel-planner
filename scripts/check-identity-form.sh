#!/usr/bin/env bash
#
# check-identity-form.sh — the one definition of the no-reply identity form.
#
#   scripts/check-identity-form.sh <address>     say whether one address is in the form
#   source scripts/check-identity-form.sh        define identity_in_form, and run nothing
#
# CONTRIBUTING.md, Ground rules asks every identity that reaches this public repository to be a
# GitHub no-reply address. Two checks hold it to that, and both read this file rather than a copy:
# check 4 of .github/workflows/depersonalization.yml on a commit's author and committer, and the
# tagger limb of scripts/check-release-tag.sh on a release tag. The host's own committer address
# is an exception check 4 states for commits. It is no part of this form and a tag never takes it.
#
# ── THE RULE ──────────────────────────────────────────────────────────────────────────
# An address is in the form when the whole of it, byte for byte, reads
#     [<digits>+]<login>[[bot]]@users.noreply.github.com
# where <login> opens with an ASCII letter or digit and goes on in ASCII letters, digits and
# hyphens. Those are the shapes GitHub issues: the id-prefixed address of an account, the older
# address with no id, and either of them for a bot, whose login ends [bot].
#
# THE COMPARISON IS EXACT AND CASE-SENSITIVE. GitHub writes these addresses with the domain in
# lower case, and a login in the case its account chose. An upper-case domain is refused, and so is
# anything before or after the address, an `@` inside it, a login holding `.` or `_`, and a longer
# or shorter domain. Refusing an address the host would accept costs a clean re-commit; passing one
# it would not costs a permanent public identity, so an unlisted shape is refused rather than
# guessed at. A shape GitHub starts issuing is added here, and only here.
#
# ── WHAT IT CANNOT SAY ────────────────────────────────────────────────────────────────
# Whether the address belongs to whoever used it, or to any account at all: this reads text, and
# a no-reply address is public. It has no view of a signing key, whose identity only a verifier's
# own mapping supplies.
#
# ── EXIT STATUS, RUN AS A COMMAND ─────────────────────────────────────────────────────
#   0  in the form    1  not in the form    2  not one argument: nothing was judged
#
# Pure bash, written for bash 3.2 as well as 5. It reads and writes no file, and sourcing it sets
# no option and changes no state but the function and the pattern it defines.

IDENTITY_FORM_RE='^([0-9]+\+)?[A-Za-z0-9][A-Za-z0-9-]*(\[bot\])?@users\.noreply\.github\.com$'

# identity_in_form <address> — 0 when <address> is in the form, non-zero otherwise. The locale is
# set here because a bracket range reads through it, and the gate's shell does not pin one.
identity_in_form() {
  local LC_ALL=C
  [[ "${1-}" =~ $IDENTITY_FORM_RE ]]
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  [ "$#" -eq 1 ] || { printf 'usage: %s <address>\n' "${0##*/}" >&2; exit 2; }
  identity_in_form "$1" || exit 1
  exit 0
fi
