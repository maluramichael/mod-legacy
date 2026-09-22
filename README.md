# mod-legacy

An [AzerothCore](https://www.azerothcore.org/) module (WotLK 3.3.5a) that adds **account-wide
Legacy progression**: your characters earn Legacy Points by leveling, and every character on
the account spends from that same shared pool to raise ranks in 3 small perk trees.

## What it does

- **Earn**: leveling up credits Legacy Points to the account (any character's level-ups add
  to the same pool).
- **Spend**: each character independently chooses which perks to raise, but every character
  draws from the ONE account-wide pool — the account can never have spent, in total across
  every character, more than it has ever earned.
- **Apply**: bought perks are re-applied automatically on login and immediately after every
  buy/reset.

```
.legacy                    - show available points and every tree/node/rank
.legacy buy <tree> <node>  - spend a point to raise a node by one rank (1-based indices)
.legacy reset              - refund every node THIS character has bought
```

Each node has up to rank 3. Raising a node costs 1 / 2 / 3 Legacy Points for rank 1 / 2 / 3
(each rank's cost is on top of the previous one — 6 points total to max a node).

## The 3 trees

### Adventure

| # | Node | Effect |
|---|------|--------|
| 1 | Swift Boots | +move speed |
| 2 | Quick Study | +XP from all sources |
| 3 | Wanderlust | +bonus XP from area exploration (stacks with Quick Study) |

### Professions

| # | Node | Effect |
|---|------|--------|
| 1 | Steady Hands | +gathering skill-up rate (mining/herbalism/skinning) |
| 2 | Master Crafter | +crafting skill-up rate |
| 3 | Bountiful Harvest | +gather yield chance — **reserved, not purchasable yet** (see Limitations) |

### Resourcefulness

| # | Node | Effect |
|---|------|--------|
| 1 | Grave Robber | +gold looted from creatures/objects |
| 2 | Haggler | vendor buy-price discount (also nudges repair costs, see below) |
| 3 | Frugal Repairs | additional repair-cost discount (stacks with Haggler) |

## How the perks are applied

- **Swift Boots** (move speed) is carried by a single hidden, passive, server-side spell
  whose effect amount is rewritten at runtime to match the node's rank — the same technique
  several other modules on this server use for hidden stat auras. No client patch needed.
- **Quick Study / Wanderlust** (XP%) scale the XP amount directly when it is awarded.
- **Steady Hands / Master Crafter** (skill-up rate) scale the skill-up amount directly when
  a gathering/crafting skill-up is rolled.
- **Grave Robber** (kill gold%) scales the gold amount directly before it is looted from a
  creature or object.
- **Haggler** (vendor discount) hooks the same reputation-discount calculation the game
  itself uses for vendor buy prices — which is also the base of the repair-cost calculation,
  so Haggler quietly helps repair costs too.
- **Frugal Repairs** applies an additional, repair-specific discount on top of Haggler.

## Limitations

- **Earn source**: v1 only earns Legacy Points from leveling up. More sources (dungeon
  bosses, achievements, ...) are intentionally left for later.
- **Bountiful Harvest** (gather yield chance) is listed for visibility but not purchasable:
  there is no clean hook to raise a specific gathering node's yield without also affecting
  unrelated creature loot rolls. A future revision may add this once a suitable hook exists.

## Configuration

`conf/mod_legacy.conf.dist`:

| Key | Default | Description |
|-----|---------|-------------|
| `Legacy.Enable` | `1` | Master on/off switch |
| `Legacy.PointsPerLevel` | `1` | Legacy Points credited per level-step |
| `Legacy.LevelStep` | `1` | Award every N character levels |
| `Legacy.Adventure.MoveSpeed.PerRank` | `1.0` | Percent per rank |
| `Legacy.Adventure.Xp.PerRank` | `2.0` | Percent per rank |
| `Legacy.Adventure.ExploreXp.PerRank` | `10.0` | Percent per rank |
| `Legacy.Professions.GatherRate.PerRank` | `10.0` | Percent per rank |
| `Legacy.Professions.CraftRate.PerRank` | `10.0` | Percent per rank |
| `Legacy.Resourcefulness.KillGold.PerRank` | `5.0` | Percent per rank |
| `Legacy.Resourcefulness.VendorDiscount.PerRank` | `2.0` | Percent per rank |
| `Legacy.Resourcefulness.RepairDiscount.PerRank` | `5.0` | Percent per rank |

The module creates its own storage tables (`legacy_account`, `legacy_spent`) automatically on
first start. It also ships one small SQL file
(`data/sql/db-world/updates/mod_legacy_2026_09_22_00.sql`) that adds the single hidden carrier
spell used for the move-speed perk; if that SQL hasn't run yet, every perk except move speed
still works, and the module logs a warning at startup.

## Installation

Clone into your AzerothCore `modules/` directory, apply the SQL file above to your world
database, and rebuild the worldserver.

## License

Released under the GNU GPL v2 (or later).
