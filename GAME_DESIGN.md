# Waza - Game Design (draft v1)

Roblox game. Same blocky/studs map style as Heli Empire (corridor map with levels).

## Core loop
1. You have an **army** of units that follows you in formation.
2. Walk into a level and **fight creatures** with your army. Creatures drop coins.
3. Spend coins to **upgrade army size** (and unit levels, new unit types).
4. **PvP**: fight other players' armies in a PvP zone for bigger rewards.

## Units (first four, from the dream)
| Unit   | Role                         | Notes                                  |
|--------|------------------------------|----------------------------------------|
| Bee    | fast, flying, low HP         | stings from range; weak vs Knight      |
| Knight | tank, strong melee           | beats Bee; slow                        |
| Boxer  | fast melee, high DPS         | short range, quick punches             |
| Spider | support/control              | webs slow enemies                      |
Stats (HP / damage / speed / range) live in `Config` so they are easy to tune.

## Army
- Units trail the player in a loose formation (server-owned, replicated).
- Army size cap is an upgrade (start small, e.g. 3, grow with coins).
- Units attack the nearest enemy in range; the player can also attack.

## Creatures / levels (easy -> hard)
1. **Cat** (easiest): slams the ground to damage the area (telegraphed shockwave), then tries to hide behind cover and pops out again. Low HP.
2. (later) bigger creatures with new attacks; more levels = more HP/damage/rewards.

## PvP
- PvP zone, opt-in. Armies fight; winner takes a coin reward larger than creature drops.
- Server decides damage/winner; no client trust.

## Economy (server-authoritative)
- Coins from creatures and PvP. Upgrades: army size, unit level, buy units.

## Build order
1. Config (units, levels) + data
2. Army follow system
3. Unit combat AI (attack nearest enemy)
4. Cat level (ground slam + hide)
5. Coins + army size upgrade + HUD
6. PvP zone
7. More creatures/levels, shop, saving

## Built so far (v2)
- Map: corridor (green studded floor, red brick walls) along -Z; Cat arena = brown dirt patch at the far end.
- Army units fight: nearest creature in 70 studs, stand at their range, attack at their rate (server-side via Combat module).
- Cat (Lv1, easiest): never attacks. Wanders 4 s, digs underground (immune while hidden ~3.5 s + dirt mound), pops up elsewhere. 600 HP, 20 coins to everyone who damaged it, respawns after 8 s.
- Coins in leaderstats.
