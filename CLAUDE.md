# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Lumbervivor** — top-down 2D pixel art survival roguelike in Godot 4.6. A lumberjack chops trees to collect wood and defends a cabin from zombie waves. During the day: chop trees, craft upgrades at the workbench. At night: survive zombie attacks. The cabin's fence is the central object to protect — if it's destroyed, it's Game Over.

**Spec:** `lumberjack_survival_GDD.md` is the source of truth for all design decisions. All implementation must derive from the GDD (SDD methodology).

## Development workflow

Before implementing any major system, run `/code-review` on the current diff to catch issues early.

After implementing any major system, run `/verify` to confirm the change works as intended in the game.

"Major system" = any ⬜ item from the implementation status table (zombie AI, HUD, day/night cycle, cabin/fence, crafting, game over screen, etc.).

## Running the game

Open the project in the Godot 4.6 editor and press **F5** (or the Play button). There is no CLI build step. The main scene is `scenes/world/main.tscn`.

## Architecture

### Scene tree (runtime)
```
Main (Node2D)                  ← main.gd: spawning, game state, day/night cycle, crafting toggle
├── World (Node2D)
│   ├── Terrain (Polygon2D)    ← visual placeholder, no logic
│   ├── Cabin (Node2D)         ← cabin + CabinFence child — PENDING
│   ├── Trees (Node2D)         ← container; ChoppableTree instances added at runtime
│   ├── Zombies (Node2D)       ← container; Zombie instances added at runtime
│   └── Player (CharacterBody2D)  ← player.gd
│       ├── Axe (Area2D)           ← axe.gd: swing hitbox + animation
│       └── Camera2D
├── DayNightTimer (Timer)      ← 5 min per phase — PENDING
├── ZombieSpawnTimer (Timer)   ← active only during night phase
└── UI (CanvasLayer)
    ├── HUD (Control)          ← hud.gd: health, wood, round, phase
    └── CraftingBench (Control) ← crafting.gd: hidden until B key, day-only
```

### Signal flow for combat
```
Player (left click) → axe.swing()
  → Axe.body_entered → hit_zombie / hit_tree signals
    → player._on_axe_hit_zombie → zombie.take_damage()
    → player._on_axe_hit_tree  → tree.take_damage()
                                → tree.chopped (CONNECT_ONE_SHOT)
                                  → player._on_tree_chopped → wood += 6

Zombie (in range) → player.take_damage() / fence.take_damage()
  → player.died → GameOverScreen
  → fence.destroyed → GameOverScreen
```

### Class names
| class_name        | File                                           | Base              | Status |
|-------------------|------------------------------------------------|-------------------|--------|
| `Player`          | `scenes/characters/player/player.gd`           | CharacterBody2D   | ✅ |
| `Axe`             | `scenes/components/axe/axe.gd`                 | Area2D            | ✅ |
| `Zombie`          | `scenes/characters/zombie/zombie.gd`           | CharacterBody2D   | ⬜ AI pending |
| `ChoppableTree`   | `scenes/objects/tree/tree.gd`                  | StaticBody2D      | ✅ |
| `CabinFence`      | `scenes/objects/cabin/fence.gd`                | StaticBody2D      | ⬜ PENDING |
| `WoodBarricade`   | `scenes/objects/cabin/barricade.gd`            | StaticBody2D      | ⬜ PENDING |
| `HUD`             | `scenes/ui/hud/hud.gd`                         | Control           | ⬜ stubs only |
| `CraftingBench`   | `scenes/ui/crafting/crafting.gd`               | Control           | ⬜ PENDING |

> **Important:** Do NOT use `Tree` as a class name — it conflicts with Godot's built-in UI widget. The chopping tree class is `ChoppableTree`.

### Input actions (defined in project.godot)
| Action         | Binding            | Status |
|----------------|--------------------|--------|
| `move_left`    | A / ←              | ✅ |
| `move_right`   | D / →              | ✅ |
| `move_up`      | W / ↑              | ✅ |
| `move_down`    | S / ↓              | ✅ |
| `attack`       | Left mouse click   | ✅ |
| `push`         | Right mouse click  | ⬜ PENDING |
| `open_bench`   | B                  | ⬜ PENDING |

### What is implemented vs placeholder
| System                        | Status                                                       |
|-------------------------------|--------------------------------------------------------------|
| Player movement               | ✅ WASD + mouse facing (`look_at`)                           |
| Axe swing + hitbox            | ✅ cooldown, arc animation, one-hit-per-swing                |
| Tree take_damage              | ✅ health reduction, `chopped` signal, queue_free            |
| Zombie take_damage            | ✅ health reduction, `died` signal, queue_free               |
| Wood collection               | ✅ +6 per tree, `wood_changed` signal                        |
| Spawning (initial)            | ✅ 15 trees + 5 zombies at start                             |
| Zombie AI / movement          | ⬜ `_physics_process` is empty                              |
| Zombie attack (player/fence)  | ⬜ no attack logic                                          |
| Player take_damage            | ⬜ no `take_damage` method                                  |
| HUD display                   | ⬜ `update_health/wood` are empty stubs                     |
| Day/night cycle               | ⬜ no `DayNightTimer`, no phase logic                       |
| Cabin + CabinFence            | ⬜ no scene created                                         |
| CraftingBench                 | ⬜ replaces old Shop (P key) — not yet created              |
| Push mechanic (right click)   | ⬜ input action not mapped                                  |
| Zombie types (runner / tank)  | ⬜ round 3+                                                 |
| Difficulty scaling per round  | ⬜ +10% HP/damage per round                                 |
| Night-end condition           | ⬜ no zombie counter, no transition block                   |
| Game Over screen              | ⬜ no scene                                                 |
| Round victory screen          | ⬜ "Sobreviviste la noche X" overlay                        |

### Terrain bounds
The playable area is a `Polygon2D` in World: **1600×1000 px** centered at origin (±800 x, ±500 y). Spawning uses a slightly smaller inner rect (±750 x, ±450 y) to keep entities off the edges.

## Balance values (confirmed)

### Player
| Stat | Value |
|------|-------|
| Max health | 100 HP |
| Axe damage | 25 |
| Move speed | 250 px/s |

### CraftingBench upgrades (single-level, not stackable)
| Upgrade | Cost | Effect |
|---------|------|--------|
| Upgraded axe | 8 wood | `axe.damage += 15` → 40 total |
| Wooden armor | 10 wood | `max_health += 30` → 130 total |
| Wood barricade | 6 wood | `fence.current_health += 100` |

### Zombies
| Type | HP | Damage | Speed | Placeholder color | Available |
|------|----|--------|-------|-------------------|-----------|
| Normal | 50 | 10 | 75 px/s | Red `#CC3333` | Round 1+ |
| Runner | 35 | 8 | 130 px/s | Yellow `#DDCC00` | Round 3+ |
| Tank | 120 | 20 | 45 px/s | Dark red `#8B0000` | Round 3+ |

Scaling per round: `stat * (1.0 + 0.1 * (round - 1))`. Round 3+ spawn mix: 50% normal / 30% runner / 20% tank.

### CabinFence
| Stat | Value |
|------|-------|
| Base HP | 200 HP |

## Known gaps / non-obvious decisions

**`axe.damage` is the single source of truth for axe damage.**
`Player` previously had a redundant `@export var axe_damage` that was never linked to `Axe.damage`. The fix: remove `axe_damage` from `Player`; `CraftingBench` writes directly to `axe.damage`. Do not re-introduce `Player.axe_damage`.

**Collision layers are not configured — configure before implementing zombie AI.**
Everything uses Godot's default layer 1. Set up layers first (GDD §8.4):
- Layer 1 = player
- Layer 2 = zombies
- Layer 3 = trees
- Layer 4 = fence / barricades

**+X axis is "forward" for the player.**
`look_at()` rotates the node so its local **+X axis** points toward the mouse. All visuals that need to face the same direction (the `DirectionIndicator` triangle, the `Axe` offset at `Vector2(32, 0)`) are aligned along +X. Any new child visual or weapon offset must follow this convention.

**CraftingBench replaces the old Shop.**
The previous placeholder `scenes/ui/shop/shop.gd` and `shop.tscn` used a P-key toggle. Per the GDD, this is replaced by `CraftingBench` (B key, day-only). Delete `shop.gd` / `shop.tscn` and all references when implementing crafting.

**Zombie target assignment: 70% fence / 30% player.**
Each zombie picks its target at spawn (GDD §4). Once a zombie begins attacking the fence/barricade, it ignores the player until the structure is destroyed or the zombie dies. Zombies targeting the player pursue actively.

## Development blocks

All design TODOs resolved. Full task lists in GDD §11. Execution order: **A → B → C → D → E → F → G → H**

| Block | Name | Status | Depends on |
|-------|------|--------|------------|
| A | Setup & Fixes | ⬜ | — |
| B | Zombie AI & Targeting | ⬜ | A |
| C | Cabin & CabinFence | ⬜ | A |
| D | Damage Exchange & Push | ⬜ | B + C |
| E | Day/Night Cycle | ⬜ | C |
| F | HUD & CraftingBench | ⬜ | D + E |
| G | Zombie Types & Scaling | ⬜ | E |
| H | Game Over & Screens | ⬜ | D + E + F |

**Pre-implementation fix (Block A):** `player.move_speed` is currently 150 in code — must be corrected to 250 (GDD §4.1). `Player.axe_damage` still exists in `player.gd` — must be removed (GDD §10.3).
