# Destination-ideation demo

A worked run of the **Destination Ideation** agent (`agents/destination-ideation.md`)
— the front of IDEATION, for a group that hasn't chosen *where* to go yet. It
turns the destination leanings of the travelers who filled in their own form
into one ranked group shortlist using **equity-weighted coverage**.

## Files
- [`traveler-leanings.md`](traveler-leanings.md) — the input: each traveler's
  `Would love` / `Rather skip` / `Trip vibe` (as the agent reads them from the
  reconciled `outputs/traveler-model.md`), one entry relayed by the organizer.
- [`outputs/destination-shortlist.md`](outputs/destination-shortlist.md) — the
  agent's output.

## What the run demonstrates

| Behavior | Where to see it |
|---|---|
| Aggregates every traveler's leanings into a ranked shortlist | The three-entry ranking |
| `Rather skip` respected as a hard filter | Italy (loved by two) removed by Dev's skip → *Vetoes applied* |
| `Trip vibe` reflected in each entry's rationale | The "Vibe:" line on every entry |
| Recommendation only — nothing auto-picks | *Handoff* section; no destination written anywhere |
| Hands off to DISCOVERY once chosen | *Handoff* section |
| Counts only travelers who filled in their own form | Eli's relayed leaning appears nowhere in the shortlist; *Conflicts & coverage* says how much of the group it reflects |
| A withheld veto reason reads as no reason | The Swiss Alps veto line carries none: Cyra's reason states a need |

## The equity point

Portugal and Japan tie on love-count (two each); Iceland has only one lover
(Dev). Ranking on **popularity alone** would cull Iceland and leave Dev with
nothing on the shortlist. **Equity-weighted coverage keeps Iceland** because it
is Dev's only surviving loved option — so every traveler is represented. That is
the whole difference between this policy and a popularity vote, and it mirrors
the equity ethos of the downstream satisfaction engine.
