# Travel Planner

Plan a group trip with [Claude Code](https://claude.com/claude-code). Tell it where you're going and
who's coming. A team of AI agents researches the destination and builds a day-by-day itinerary that
works for everyone in the group. The plan is checked before you rely on it, then turned into a
travel website that only people with the passphrase can open.

## What it produces

A self-contained website for the trip, with a day-by-day schedule, maps, food picks and a booking
checklist:

![Desktop layout of a generated travel site: a hero with the destination, dates and trip stats; a sticky day-navigation strip; a heat strip marking the no-unshaded-outdoor window; and a four-column day grid of schedule, featured stops, food and night cards, and a map, with a booking-status pill on every card.](examples/data-architecture-demo/site-preview.svg)

*A generated site's desktop layout, drawn from the example data in
[`examples/data-architecture-demo/`](examples/data-architecture-demo/). It is not a real trip.*

## How it works

1. **Each traveler fills in a short profile.** It covers what they want from this trip. A second
   profile, filled once and reused, covers what they always need, such as diet, mobility, heat and
   rest. A missing profile counts as *unknown*, never as *no constraints*.
2. **Research agents cover the destination.** One gathers context like weather, transit and local
   events. Others research activities, food, nightlife, transport and scheduling, and each writes
   its findings to its own file.
3. **A hub agent assembles the itinerary.** Everyone's needs are hard limits. Everyone's wishes are
   balanced across the group.
4. **A validator audits the plan.** It checks every constraint on every day, plus closures,
   reservations and an indoor fallback for every long outdoor block.
5. **You make changes in conversation.** Swap two days, ask for more dinner options near the hotel,
   or record a booking. Small changes are direct edits, and only the affected agents re-run.
6. **You publish the site encrypted.** Only ciphertext leaves your machine.

Each trip is a folder of plain markdown you can read, diff and edit. Your trip data lives in a
folder you choose, outside this repository, and stays on your machine.

## Requirements

- [Claude Code](https://claude.com/claude-code), desktop app or CLI
- `git`
- Only if you publish a site: `bash`, `perl`, [Node.js](https://nodejs.org) (which runs StatiCrypt
  through `npx`), and the [GitHub CLI](https://cli.github.com), signed in with `gh auth login`

## Install

The engine installs as a set of Claude Code personal skills. There is nothing to build. These steps
are for macOS and Linux. For Windows, see the notes at the end of this section.

**1. Clone the engine** into your Claude Code skills folder:

```bash
git clone https://github.com/cody-hutson/travel-planner ~/.claude/skills/travel-planner
```

**2. Link the commands** next to it, so each one is available under its own name:

```bash
for v in trip trip-new trip-record trip-publish trip-decommission; do ln -s ~/.claude/skills/travel-planner/skills/$v ~/.claude/skills/$v; done
```

**3. Create your data folder.** Your trips, traveler records and groups live here. Put it anywhere
*outside* the engine, so updating or removing the engine never touches your data. This example uses
`~/travel`. These commands give it the same empty `trips/`, `people/` and `groups/` folders the
engine ships, then record its location in a pointer file:

```bash
mkdir -p ~/travel && cd ~/travel
for d in trips people groups; do mkdir -p $d && cp ~/.claude/skills/travel-planner/$d/README.md $d/; done
mkdir -p ~/.travel-planner && printf '%s\n' "$(pwd)" > ~/.travel-planner/data-root
```

If you used an earlier version, your old checkout already holds your trips. Run only the last
line, from inside that checkout.

**4. Let Claude Code read your data folder.** The commands run from whatever project you have open,
so Claude Code needs permission to read the data folder and the pointer. Add both to your user
settings, `~/.claude/settings.json`. If that file already exists, add the entry to its
`permissions` object:

```json
{
  "permissions": {
    "additionalDirectories": ["~/travel", "~/.travel-planner"]
  }
}
```

To update the engine, run `git pull` in `~/.claude/skills/travel-planner`. If a release adds a new
command, link it the same way as in step 2.

<details>
<summary>Windows (not yet confirmed on Windows, so please <a href="https://github.com/cody-hutson/travel-planner/issues">report how it goes</a>)</summary>

From `cmd`, with no elevation needed:

```bat
git clone https://github.com/cody-hutson/travel-planner "%USERPROFILE%\.claude\skills\travel-planner"
for %v in (trip trip-new trip-record trip-publish trip-decommission) do mklink /J "%USERPROFILE%\.claude\skills\%v" "%USERPROFILE%\.claude\skills\travel-planner\skills\%v"
```

Then create your data folder as in step 3, and write its absolute path, on one line, to
`%USERPROFILE%\.travel-planner\data-root`. Allow both folders as in step 4. Publishing runs a bash
script, so use Git Bash or WSL for it.

</details>

### Verify

Restart Claude Code, open any project and type `/trip`. It should say there are no trips yet and
suggest `/trip-new`.

- **The commands don't appear:** `ls -l ~/.claude/skills/` should list the five links, next to the
  `travel-planner` directory itself.
- **They appear but can't find your trips, or ask for permission to read them:** check the path in
  `~/.travel-planner/data-root` and your `additionalDirectories` entry. The error message names the
  file to fix.

<details>
<summary>Upgrading from a version that copied commands into <code>~/.claude/commands/</code></summary>

Older copies still answer to `/trip` with the old behavior, so remove them one file at a time.
Other commands of your own may live in that folder, so don't delete the folder itself:

```bash
rm ~/.claude/commands/{trip,trip-new,trip-record,trip-publish,trip-decommission}.md
```

If you edited one of those copies by hand, `diff` it against `skills/<verb>/SKILL.md` in the engine
first, so you keep your changes.

</details>

<details>
<summary>Uninstalling</summary>

Remove the five links. Each one is only a link, so this leaves the engine in place:

```bash
for v in trip trip-new trip-record trip-publish trip-decommission; do rm ~/.claude/skills/$v; done
```

On Windows, `rmdir` each junction instead. Then delete the engine directory,
`~/.claude/skills/travel-planner`. Your data folder and `~/.travel-planner/` are left alone. Delete
them yourself if you want them gone.

</details>

## First run

```text
/trip-new lisbon-2027            set up the trip and walk through traveler intake
/trip-record destination Lisbon  record the destination once it's decided
/trip plan                       research, build and validate the itinerary
/trip site                       build the travel website
/trip                            see where the trip stands and what to do next
```

Each command tells you what comes next, so you don't need to memorize them. You can also describe
what you want, like *"we booked the hotel"* or *"find more dinner options near Bairro Alto"*, and
Claude names the command that does it. If the group hasn't chosen a destination yet, `/trip ideas` turns
everyone's leanings into a ranked shortlist.

| Command | Use it to |
|---|---|
| `/trip` | Check status, and plan, research, replan, audit and build the site |
| `/trip-new` | Start a trip |
| `/trip-record` | Record what you know: profiles, bookings, the destination, decisions, people and groups |
| `/trip-publish` | Re-publish a site after changes, or list what's published |
| `/trip-decommission` | Take a site offline, archive a finished trip, or reopen one |

The [command reference](reference/command-reference.md) lists every verb, its arguments, and when it
can run. If you have more than one trip, add `--trip <slug>` to say which one.

To see what a filled-in traveler profile looks like, read
[`examples/people-library-demo/travelers/noor.md`](examples/people-library-demo/travelers/noor.md).
To see a finished itinerary from a real trip, read
[`examples/tokyo-2026/outputs/final-itinerary.md`](examples/tokyo-2026/outputs/final-itinerary.md).
Traveler records that carry over between trips, and groups of people who travel together, are
covered in [`people/README.md`](people/README.md) and [`groups/README.md`](groups/README.md).

## Publishing a trip site

Publishing encrypts the site and pushes only the ciphertext to a new public GitHub repo, served
with GitHub Pages. Visitors enter a passphrase, and the page decrypts in their browser.

Run the publish script yourself, in a terminal. It lives in the engine, and `--data-root` tells it
where your data folder is (`~/travel` in the install example), so it works from any directory:

```bash
~/.claude/skills/travel-planner/scripts/publish-trip-site.sh publish trips/<slug> --data-root ~/travel
```

To run another subcommand from the table, swap it in for `publish trips/<slug>` and keep
`--data-root ~/travel` at the end.

| Subcommand | What it does |
|---|---|
| `publish trips/<slug>` | Encrypt and publish the first time. Add `--opaque` to give the repo a random name |
| `update trips/<slug>` | Re-publish after changes. `/trip-publish update` does this from Claude Code |
| `confirm trips/<slug>` | Record approval of a pending change |
| `rotate trips/<slug>` | Change the passphrase |
| `list` | Show every trip's publish state, and which sites are out of date |
| `unpublish trips/<slug>` | Take the site down. This deletes the repo unless you add `--disable-pages-only` |

- The passphrase is saved in your data folder, at `trips/<slug>/.passphrase`, and that file is
  the trip's key of record. Share it privately. The encryption is only as strong as the
  passphrase.
- If you set `STATICRYPT_PASSWORD` and it doesn't match the trip's `.passphrase`, `publish` and
  `update` refuse until you unset it.
- `rotate` protects what you publish from then on. Earlier versions of the site stay in the
  repo's history, readable with the old passphrase; to remove those too, `unpublish` and
  publish again.
- The repo name is public and includes the destination and year, unless you used `--opaque`.
- You can require named travelers to approve a plan change before it goes live. Declare them with
  `/trip-record .approvers`, and record their approvals with `confirm`.

[`SECURITY.md`](SECURITY.md) explains what the encryption and the approvals do and don't protect.
You can also publish without encryption, by adding `--plaintext` to the publish line. Only you can
run that, from a terminal. The publishing section of [`CLAUDE.md`](CLAUDE.md) describes the checks
it runs first.

## What it costs to run

Planning uses your Claude Code plan. The first full plan is the expensive part. Every agent runs,
several of them search the web, and all of them run on the top model tier, so set aside a sitting
for it. After that, most requests, like edits, lookups and bookings, run no agents at all.
Targeted research runs one agent. Keeping a trip current costs a small fraction of building it.

## Repository map

| Path | What's there |
|---|---|
| `CLAUDE.md` | The operating manual Claude follows: request routing, the agents, planning modes, rules |
| `SKILL.md` | The entry point that turns a request in your own words into the right command |
| `skills/` | The commands, one folder each |
| `agents/` | One prompt per agent |
| `templates/` | The blank trip context and the two traveler intake forms |
| `reference/` | Architecture, schemas, the site design spec, the command reference, and decision records (`adr/`) |
| `scripts/` | The publish script, the checks `/trip site` and `/trip schema` run, and the CI test suites |
| `examples/` | Worked examples. `tokyo-2026/` is a real trip, kept exactly as an earlier version of the engine planned it. `evening-boundary-demo/` shows how evenings are routed now |
| `trips/`, `people/`, `groups/` | Empty skeletons that install step 3 copies into your data folder |
| `analysis/` | Local scratch space for reviews of this repo. Git-ignored |

## Contributing, security and changes

See [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md) and
[`CHANGELOG.md`](CHANGELOG.md).

## License

[Business Source License 1.1](LICENSE). It allows non-production, personal, educational and
internal-business use. Commercial offerings need a separate license, so contact the owner. It
converts to Apache License 2.0 on 2030-05-27.
