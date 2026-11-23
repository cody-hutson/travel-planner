# ADR-055: A publish stands on the live site and runs alone — the key is checked against the page the site serves, a failed rotation is finished only while its marker names the key file and the page, and the commands on one trip run under a per-trip lock

- **Status:** Proposed
- **Deciders:** repo maintainer
- **Driving work:** #1820 and #1819, in the *Publish commands are safe to run twice and stop on their
  own failures* milestone. The repository's maintainer ruled, at that milestone's collective review,
  on the options this record transcribes, as amended by its adversarial design review.
- **What this record is.** A decision about **the secret/publish model of `scripts/publish-trip-site.sh`**:
  what a push that re-encrypts must establish about the site before it runs, how a rotation whose push
  failed is told apart from a key that is simply wrong, and how a second publish command on one trip is
  kept from running into the first. It is addressed to whoever edits `cmd_update`, `cmd_rotate`, `write_passphrase_file`, the
  per-trip lock, or the groups RV and E of `scripts/test-publish-guard.sh` that grade them.
- **What this record is not.** It does not change how a key is generated, where it is stored, or what is
  encrypted; it does not reach two machines publishing one trip; and it decides nothing about
  `unpublish`'s reading of the host, which is a point fix inside the existing contract.

## Context

**Every key check before this record compared one store with another.** `update` took its key from
`STATICRYPT_PASSWORD` or `<trip-dir>/.passphrase` and checked that the two agreed; `rotate` refused a new
key equal to the one `.passphrase` held. Neither asked the site. A store that had drifted from the site —
a stale `.passphrase`, a variable left set, a key a failed first publish had generated — re-encrypted the
live page under a key its viewers were never given, and the command exited 0. That last case was
reproduced at the milestone's design baseline: `publish` on a failed host read took its create path and
recorded a generated key, and the next `update` re-keyed the site with everyone holding the real
passphrase locked out.

**A rotation whose push failed is meant to be finished by `update`.** `rotate` records its new key at its
commit point, before the push, so a push that fails leaves `.passphrase` holding a key the live page is not
yet under, and `update` publishes under it. A check against the site refuses exactly that state unless the
state is recognised, and it has to be recognised by something that survives the remedies the refusals
name — removing the per-trip clone among them.

**Commands on one trip were not serialized.** The script's header said so and asked for one at a time.
Re-derived at the design baseline, four interleavings still ended in a wrong state that nothing detected:
two first publishes leaving `.passphrase` under a key the live page is not under; two rotations whose
winner announced a file the loser then overwrote; two confirmations losing an approval in the ledger's
copy-and-rename; and a takedown reporting a no-op while a first publish made the site live.

## Decision drivers

- **A publish must stand on the site's state, not on a local copy of it.** The check reads what the push
  will replace.
- **No recovery route the script already names may close.** `update`'s own refusal sends an operator with a
  lost key, or a site published `--plaintext`, to `rotate`.
- **A refusal is deterministic and machine-readable where an unattended caller meets it.** No timing in a
  required check.
- **No new dependency on the takedown path.** `unpublish` runs with the GitHub CLI alone.
- **Fail closed.** A state the script cannot read is a refusal, never a pass.

## Options considered

Where the live page is read from:

| Option | Verdict |
|---|---|
| **The per-trip clone's fetched tip — the commit the leased push replaces** | **SELECTED.** It is exactly the page the push replaces, costs no new network read, and does not depend on the Pages build |
| The served URL | Rejected. A Pages build lags a push, so a correct `update` would be refused; a site taken offline answers 404; it adds `curl` |

What `rotate`'s check asserts:

| Option | Verdict |
|---|---|
| Refuse unless the retiring key opens the live page | Rejected. It closes the lost-key route `update` names, and the plaintext route |
| **Refuse a new key that already opens the live page; ask nothing of the retiring key** | **SELECTED.** It replaces the store-only test with a test against the site, and catches a rotation to the live key against a stale `.passphrase`, which revokes nothing |
| No check | Rejected. The store test alone misses that rotation |

What recognises a rotation whose push failed:

| Option | Verdict |
|---|---|
| The staged baseline record | Rejected. A rotation of an unchanged plan stages none, and `publish` stages the same record, so it would admit the residual it exists to stop |
| The clone's unpushed page | Rejected. The remedy the refusals name removes the clone |
| A marker naming the identity of the key file the rotation wrote | Rejected as written. It binds a local file and nothing about the site: a second copy of the trip moving the site to a third key, or the repository published again `--plaintext`, still matched it, and `update` pushed under a key nobody held |
| **`.rotation-pending`, written after the key, naming the key file's identity, `base-page`, the git blob id of the page the rotation replaced, and `base-commit`, the commit its leased push would have replaced** | **SELECTED.** `update` finishes the rotation only while all three still stand. The commit is what tells a site published again apart: an unchanged plaintext render reproduces the page's blob in a new repository, never the commit. It holds no key and no person data: an inode, a time, a size, and the content addresses of a public page and a public commit |

Whether a second command waits or refuses, and the lock's primitive:

| Option | Verdict |
|---|---|
| **Refuse at once, naming the holder** | **SELECTED.** Deterministic; an unattended caller chooses its own retry |
| Wait up to a bound | Rejected. A timing constant, a nondeterministic arm, and a command waiting silently behind a prompt |
| Wait without a bound | Rejected. A lock a killed run left behind hangs every later command |
| **`mkdir <trip-dir>/.publish-lock`, a holder record inside** | **SELECTED.** Atomic on every local filesystem, no dependency, a readable record |
| `flock` on a descriptor the shell holds | Rejected. Not on macOS as a command; through perl it adds a dependency to the takedown and stays held while any child of the run lives |
| A machine-local lock outside the trip directory | Not taken. It would let a proven-dead holder be broken safely, at the cost of a lock invisible beside the trip and the same blindness to a second machine |

The rule for a lock a killed run left behind:

| Option | Verdict |
|---|---|
| **Never break it automatically; the refusal says whether the holder runs on this machine and names the removal** | **SELECTED.** Safe whatever the data root is synced to |
| Break it when the recorded process is gone | Rejected. Two breakers race, and a lock synced from another machine reads as dead here while live there |
| Break it by age | Rejected. `confirm` can hold a prompt for any length of time |

## Decision

1. **A push that re-encrypts is made only under a key that opens the page the site serves now.** `update`
   reads the page at the lease — the per-trip clone's fetched tip — and refuses, before its push and
   taking its own commit back out, where the key it would encrypt under does not open that page, where the
   page is not encrypted, or where whether it opens cannot be established. The refusal names the store the
   key came from, never the key.
2. **`rotate` refuses a new key that already opens that page,** because such a rotation revokes nothing, and
   asks nothing of the key it retires.
3. **A rotation whose push failed is the one exception, and it is recognised by `.rotation-pending`.**
   `rotate` writes it immediately after it records the new key, naming the identity of the key file that
   write produced, `base-page`, the git blob id of the page at the lease, and `base-commit`, the lease itself.
   `update` admits a key that does not open the live page, or a page that is not encrypted, only while the key
   file is still that file and its own lease is still that commit carrying that page. A successful push by
   `update` or `rotate` clears it. Where another copy of the trip moved the site under the old key after the
   rotation read it, or the site was taken down and published again — always a new commit, even where an
   unchanged plaintext render reproduces the page's blob — `update` refuses and names `rotate` rather than
   finishing the rotation.
4. **The key file is flushed to disk before any push that depends on it.** The staged copy is flushed before
   its rename and its directory after it; at `rotate`'s commit point the order is the key, then the marker,
   then one flush of the directories holding them, so a directory that cannot be flushed is reported by the
   state both writes left.
5. **The commands on one trip run under a per-trip lock.** `publish`, `update`, `rotate` and `unpublish` take
   `<trip-dir>/.publish-lock` before they read anything; `confirm` takes it immediately before its first
   write; `list` takes none. A command that finds it held refuses at once — exit status 75 where the holder
   runs on this machine, 76 where it does not or its record cannot be read — and every exit of the shell that
   took it releases it, as do an interrupt, a hangup and a terminate signal. A lock a run killed outright left
   behind is never broken automatically: the refusal names its removal.

## Consequences

- **A push stands on the site.** Milestone 74's residual — an `update` re-keying the site under a key a failed
  first publish generated — ends at decision 1. The publish script's own source of that key, its host read
  reading every failure as an absent repository, is left as it was; decision 1 ends the harm it could do.
- **Every `update` and `rotate` that reaches its push decrypts the live page once,** with the same pinned
  StatiCrypt package the encryption already trusts, about half a second with the package cached. The trust
  boundary `reference/publishing-runbook.md` states is unchanged.
- **Two sidecars join the trip directory, `.rotation-pending` and `.publish-lock/`.** Neither holds person data
  or key material; the erase reach table's control-files row names both as OUT, and they join the publish
  script's other sidecars outside the data architecture's closed enumeration, the residual `ADR-046` records.
- **A manual step follows a run killed outright, a crash or a power loss:** the lock's removal, named in the
  refusal. An unattended republish can tell a busy trip from a lock left behind by the exit status alone,
  save in the first instants after a command creates the lock: before its record is in place, a second command
  is told 76, its record cannot be read, where 75 is due, and since that refusal's remedy holds only if no
  publish command is running, the operator checks before removing the lock.
- **The lock covers one machine's data root.** Two machines publishing one trip are still stopped only by the
  bound pushes, the read-backs and the residue refusal.
- **Residuals this record accepts.** A rotation back to a key an earlier rotation revoked passes both checks:
  the key is the operator's explicit choice, and decision 2 reads only the live page. A recorded process id can
  name an unrelated live process after a reboot, which reads as a running holder. Durability against power loss
  cannot be observed in a test; what is graded is the flush call, its order and its success.
- **What grades it.** Groups RV and E of `scripts/test-publish-guard.sh`: RV48–RV52 for decisions 1 to 4, E5–E8
  for the decrypt against the real tool, RV54 for decision 5, and RV54-release and RV56-values for the lock's
  release on every refusal and for no refusal printing a key.

## References

- `scripts/publish-trip-site.sh` — the header's passphrase and concurrency paragraphs, `_key_opens_page`,
  `_key_opens_live_page`, the pending-rotation helpers, `_flush_path`, and the per-trip lock.
- `reference/publishing-runbook.md` § *Passphrase*, § *One at a time* and § *A rotation that stops, and what it
  refuses* — the passphrase, one-at-a-time and rotation paragraphs.
- [`ADR-002`](ADR-002-living-site-refresh.md) — the secret model this record extends.
- [`ADR-046`](ADR-046-interview-rating-and-engagement-record.md) — the residual on the publish script's sidecars.
- Driving issues: #1820 (the key against the live site, carrying #1821's durable write) and #1819 (the per-trip
  lock, carrying #1822's per-step stops).
