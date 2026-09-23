extends Node
## Registry of every weapon / activatable item in the game, autoloaded as
## "WeaponDatabase". Each entry names a `script` (a WeaponBase subclass in
## res://scripts/weapons/weapons_impl/) that implements its unique behavior,
## plus an `anim_state` the player's AnimationTree should travel to while
## the item is active (see Player.gd -> _apply_weapon_animation_state).

enum Slot { PRIMARY, SECONDARY, BACK, CONSUMABLE }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }

var weapons: Dictionary = {}

func _ready() -> void:
	# --- Standard guns found on the floor / in chests ---
	_reg("ar_common", "Scrapworks Rifle", Rarity.COMMON, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/StandardWeapon.gd",
		{"damage": 22, "fire_rate": 0.15, "mag_size": 30, "reload_time": 2.0, "range": 60.0, "hitscan": true, "anim_state": "fire_rifle"})
	_reg("shotgun_rare", "Boombox Pump", Rarity.RARE, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/StandardWeapon.gd",
		{"damage": 90, "fire_rate": 0.85, "mag_size": 5, "reload_time": 2.6, "range": 12.0, "hitscan": true, "pellets": 8, "spread_deg": 12.0, "anim_state": "fire_shotgun"})
	_reg("sniper_epic", "Longshot .50", Rarity.EPIC, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/StandardWeapon.gd",
		{"damage": 140, "fire_rate": 1.4, "mag_size": 3, "reload_time": 3.2, "range": 250.0, "hitscan": true, "anim_state": "fire_sniper"})
	_reg("smg_uncommon", "Wasp SMG", Rarity.UNCOMMON, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/StandardWeapon.gd",
		{"damage": 14, "fire_rate": 0.08, "mag_size": 40, "reload_time": 1.8, "range": 35.0, "hitscan": true, "anim_state": "fire_smg"})

	# --- Signature special weapons ---
	_reg("evolving_blade", "Momentum Blade", Rarity.LEGENDARY, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/EvolvingWeapon.gd",
		{"base_damage": 18, "fire_rate": 0.5, "range": 2.5, "hitscan": false, "anim_state": "melee_swing",
		 "tiers": [
			{"name": "Momentum Blade", "damage_needed": 0, "damage": 18, "bonus": "none"},
			{"name": "Momentum Blade+", "damage_needed": 250, "damage": 28, "bonus": "bleed"},
			{"name": "Kinetic Edge", "damage_needed": 700, "damage": 42, "bonus": "armor_shred"},
			{"name": "Apex Reaver", "damage_needed": 1500, "damage": 65, "bonus": "lifesteal"},
		]})
	_reg("tracker_compass", "Truesight Compass", Rarity.EPIC, Slot.SECONDARY,
		"res://scripts/weapons/weapons_impl/TrackerWeapon.gd",
		{"damage": 35, "fire_rate": 1.2, "mag_size": 6, "reload_time": 2.2, "range": 120.0, "hitscan": false,
		 "homing_strength": 2.5, "lock_radius": 80.0, "anim_state": "fire_tracker"})
	_reg("backup_sniper", "Retribution Rig", Rarity.EPIC, Slot.BACK,
		"res://scripts/weapons/weapons_impl/BackupSniper.gd",
		{"damage": 55, "range": 150.0, "trigger_cooldown": 6.0, "reaction_delay": 0.35, "anim_state": "backup_snipe"})
	_reg("supercharge_core", "Supercharge Core", Rarity.MYTHIC, Slot.CONSUMABLE,
		"res://scripts/weapons/weapons_impl/SuperchargeItem.gd",
		{"duration": 12.0, "fly_speed": 22.0, "cooldown": 45.0, "anim_state": "fly_super"})
	_reg("momentum_boots", "Momentum Boots", Rarity.LEGENDARY, Slot.CONSUMABLE,
		"res://scripts/weapons/weapons_impl/SpeedBoost.gd",
		{"duration": 8.0, "speed_multiplier": 3.2, "cooldown": 30.0, "leaves_afterimages": true, "anim_state": "sprint_blur"})
	_reg("smash_gauntlets", "Rampart Gauntlets", Rarity.LEGENDARY, Slot.PRIMARY,
		"res://scripts/weapons/weapons_impl/SmashGauntlets.gd",
		{"damage": 80, "fire_rate": 0.9, "range": 3.0, "hitscan": false, "breaks_structures": true, "knockback": 14.0, "anim_state": "smash_ground"})

func _reg(id: String, display_name: String, rarity: int, slot: int, script_path: String, stats: Dictionary) -> void:
	var entry := stats.duplicate()
	entry["id"] = id
	entry["name"] = display_name
	entry["rarity"] = rarity
	entry["slot"] = slot
	entry["script_path"] = script_path
	weapons[id] = entry

func get_weapon(id: String) -> Dictionary:
	return weapons.get(id, {})

func all_ids() -> Array:
	return weapons.keys()

func random_floor_loot_id(rng: RandomNumberGenerator) -> String:
	var ids := all_ids()
	return ids[rng.randi_range(0, ids.size() - 1)]

func rarity_name(rarity: int) -> String:
	return Rarity.keys()[rarity].capitalize()
