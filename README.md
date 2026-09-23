# Royale Offline

A simplified, **fully offline** Battle Royale built in **Godot 4.3+**. One
big island, six biomes, POIs full of loot, a 45-second calm opening, then a
shrinking storm — with two game modes, a full cosmetics economy, and a
library of 119 chaotic "Tech" rules for the second mode to draw from.

Everything (terrain, buildings, characters, weapons, projectiles, UI) is
built from primitives at runtime in GDScript — there are **no imported art
assets** to fetch, so the project runs as soon as you open it in Godot.

## Running it

1. Open this folder in Godot 4.3 or newer.
2. Press Play. It boots to the main menu (`scenes/MainMenu.tscn`).
3. Pick a mode. You spawn with 11 wandering/shooting bots so it isn't a
   1-player sandbox offline.

**Controls:** WASD move, Space jump, Shift sprint, C crouch (also used for
descending in flight), Left Click fire, Q use consumable/ability item, R
reload, 1/2 place a wall/floor build piece, V toggle first/third person.

## Game modes

- **Battle Royale** — the standard loop: land, loot chests and floor
  weapons, survive the shrinking storm.
- **Tech Battle** — identical for the first 45 calm seconds, then every
  time the storm finishes closing in, one random **Tech rule** activates
  and stays active for the rest of the match (`scripts/modes/TechBattleMode.gd`).
  Rules never expire, so a match can end with 8-10+ stacked simultaneously.

### The 119 Tech rules (`scripts/autoload/TechRuleDatabase.gd`)

Rules span 5 rarities (Common → Legendary, legendaries are rarer and hit
harder) and 6 classes (Offense / Defense / Heal / Utility / Movement /
Chaos — including e.g. "healer" rules like `heal_boost`/`lifesteal_all` and
"hurt" rules like `dmg_up_*`/`headshots_only`). Every rule carries `tags`,
and `TechRuleDatabase.can_activate()` refuses illegal combinations —
concretely, it will never let **no-jump + no-build** stack with a
**lethal-floor** rule (e.g. "The Floor is Lava") unless a traversal-granting
rule (double jump, grapple, jetpack, ...) is already active, exactly the
softlock called out in the design brief.

`TechEffectApplier.gd` is the single place that turns a rule's
`{type, params}` into an actual gameplay change. About two dozen effect
types are fully wired to Player/StormManager/LootSpawner; the rest
(friendly fire, camera lock, reveal effects, wind, etc.) are marked as
explicit no-op hook points in that file's `match` statement — safe to
extend without touching the rule data.

## Weapons (`scripts/weapons/`)

Standard hitscan guns (AR, SMG, shotgun, sniper) all share one
`StandardWeapon.gd` driven purely by data in `WeaponDatabase.gd`. The
signature items each have their own script:

- **Momentum Blade** (`EvolvingWeapon.gd`) — a melee weapon that
  permanently upgrades through tiers as it lands damage, unlocking bleed →
  armor shred → lifesteal.
- **Truesight Compass** (`TrackerWeapon.gd`) — auto-targets the nearest
  enemy and fires a soft-homing projectile (`HomingProjectile.gd`).
- **Retribution Rig** (`BackupSniper.gd`) — rides on your back; auto-fires
  at whoever damages you, on its own cooldown.
- **Supercharge Core** (`SuperchargeItem.gd`) — temporary flight, drives
  `Player.set_flight_enabled()` and an `anim_state` of `fly_super`
  ("Superman" pose) an AnimationTree can key off.
- **Momentum Boots** (`SpeedBoost.gd`) — temporary super-speed with
  afterimages, `anim_state` `sprint_blur` (Flash/Sonic-style run).
- **Rampart Gauntlets** (`SmashGauntlets.gd`) — short-range ground pound
  that destroys `destructible`-group structures ("Hulk" smash).

Every `WeaponBase` exposes `get_anim_state()` so a real character rig's
AnimationTree can just `travel()` to whatever state is active — the
project ships the state names and hooks, not (obviously) hand-authored
animation clips.

## Cosmetics & economy (`scripts/autoload/`)

- **Battle Tokens** — the free currency, earned via `EconomyManager`
  (`TOKENS_PER_KILL` / `_WIN` / `_MINUTE`), spent on most skins.
- **Gems** — the paid currency. Most skins can alternatively cost Gems, and
  Gem packs are listed in `ShopManager.gem_packs`.
- **"Recruit"** (`default_recruit` in `SkinDatabase.gd`) is free for
  everyone and is the *only* skin you can freely recolor (head / body /
  clothes) in the Skin Customizer screen — every purchased skin has a
  fixed palette, priced to match its rarity.
- Wallet + owned skins persist offline to `user://wallet.save`; recolored
  Recruit colors persist to `user://recruit_colors.save`.

### ⚠️ About real money

`ShopManager.purchase_gem_pack()` is an **offline stand-in** — it grants
Gems locally so the single-player game is fully playable end-to-end. It is
**not** a real payment flow: a client must never be trusted to grant
itself paid currency. Taking real money requires a real backend (Stripe is
the natural fit, and is available as a connector in this workspace) that
verifies payment server-side before calling `EconomyManager.add_gems()`.
Say the word and I can wire that up as a separate step — it needs your own
Stripe account connected first, since that's where the revenue settles.

## World (`scripts/world/`, `scripts/storm/`)

`WorldGenerator.gd` lays out one island (six biomes as color-tinted zones:
Verdant Fields, Scorched Dunes, Frostpeak Ridge, Mire Marsh, Ashen Wastes,
Neon Sprawl) with ten named POIs built from simple block "buildings".
`LootSpawner.gd` scatters ~160 floor-loot pickups and a chest per building.
`StormManager.gd` holds still for `CALM_PHASE_SECONDS = 45`, then shrinks
the circle in phases, dealing damage outside it (and emits
`phase_advanced`, which is what feeds new Tech rules into Tech Battle).

## What's a stub vs. fully wired

This is a large scope for one pass, built and reviewed without access to
the Godot editor in this environment (no GPU/display here), so it hasn't
been visually playtested — expect to need a debugging pass in-editor. Fully
implemented: movement/camera, health/shield/elimination, the 8 weapon
scripts above, chest/floor loot, biome/POI generation, the storm circle,
both game modes, the Tech rule *data + compatibility logic* and ~24 of its
effect types, the skin/customization/shop/currency loop, and simple wander-
and-shoot bots. Explicitly stubbed as safe no-ops ready for extension:
grapple/jetpack ability visuals, several cosmetic Tech effects (camera
lock, wind, fog, reveal pulses), fall damage, and real payment processing.
