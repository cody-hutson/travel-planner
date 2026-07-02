# Destination-ideation demo

A worked run of the **Destination Ideation** agent (`agents/destination-ideation.md`)
— the front of IDEATION, for a group that hasn't chosen *where* to go yet. It
turns four travelers' individual destination leanings into one ranked group
shortlist using **equity-weighted coverage**.

## Files
- [`traveler-leanings.md`](traveler-leanings.md) — the input: four travelers'
  `Would love` / `Rather skip` / `Trip vibe` (as the agent reads them from the
  reconciled `outputs/traveler-model.md`).
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

## The equity point

Portugal and Japan tie on love-count (two each); Iceland has only one lover
(Dev). Ranking on **popularity alone** would cull Iceland and leave Dev with
nothing on the shortlist. **Equity-weighted coverage keeps Iceland** because it
is Dev's only surviving loved option — so every traveler is represented. That is
the whole difference between this policy and a popularity vote, and it mirrors
the equity ethos of the downstream satisfaction engine.
