extends Node
## Catalog of every "Tech" the storm can bring in Tech Battle mode,
## autoloaded as "TechRuleDatabase".
##
## Each entry is a self-contained rule: {id, name, description, rarity,
## class, effect: {type, params}, tags}. Rules never expire once activated
## -- TechBattleMode just keeps appending to the active list each time the
## storm closes in, so a late-game match can be running 8-10 rules at once.
##
## To keep that chaos from producing unwinnable states (the classic
## "no building + no jumping + the floor is lava" softlock), every rule
## declares `tags`. A small set of tags mean something to
## `can_activate()`: a rule tagged "lethal_floor" refuses to activate
## unless the active pool already grants a way to avoid ever touching the
## ground (a tag in ESCAPE_TAGS) or does NOT already contain both
## "disables_jump" and "disables_build" (i.e. players can still at least
## jump or build their way to safety).

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum RuleClass { OFFENSE, DEFENSE, HEAL, UTILITY, MOVEMENT, CHAOS }

const ESCAPE_TAGS := ["grants_traversal", "grants_jump"]

var rules: Array[Dictionary] = []
var _by_id: Dictionary = {}

func _ready() -> void:
	_build_rules()
	for r in rules:
		_by_id[r.id] = r

func get_rule(id: String) -> Dictionary:
	return _by_id.get(id, {})

func rules_of_rarity(rarity: int) -> Array:
	return rules.filter(func(r): return r.rarity == rarity)

## Can `candidate` be safely added on top of the already-active rule set?
func can_activate(candidate: Dictionary, active_rules: Array[Dictionary]) -> bool:
	var active_tags: Array = []
	for r in active_rules:
		active_tags.append_array(r.get("tags", []))
	if active_rules.any(func(r): return r.id == candidate.id):
		return false
	if candidate.tags.has("lethal_floor"):
		var has_escape: bool = ESCAPE_TAGS.any(func(t): return active_tags.has(t))
		var fully_grounded_lock: bool = active_tags.has("disables_jump") and active_tags.has("disables_build")
		if fully_grounded_lock and not has_escape:
			return false
	if candidate.tags.has("disables_jump") or candidate.tags.has("disables_build"):
		var would_disable_jump: bool = candidate.tags.has("disables_jump") or active_tags.has("disables_jump")
		var would_disable_build: bool = candidate.tags.has("disables_build") or active_tags.has("disables_build")
		var has_escape: bool = ESCAPE_TAGS.any(func(t): return active_tags.has(t))
		if would_disable_jump and would_disable_build and active_tags.has("lethal_floor") and not has_escape:
			return false
	for excluded_id in candidate.get("excludes", []):
		if active_rules.any(func(r): return r.id == excluded_id):
			return false
	return true

## Picks a legal random rule weighted toward common/uncommon, with
## legendary being rare, given what's already active.
func roll_next_rule(active_rules: Array[Dictionary], rng: RandomNumberGenerator) -> Dictionary:
	var weights := {
		Rarity.COMMON: 40, Rarity.UNCOMMON: 27, Rarity.RARE: 18,
		Rarity.EPIC: 10, Rarity.LEGENDARY: 5,
	}
	var candidates := rules.filter(func(r): return can_activate(r, active_rules))
	if candidates.is_empty():
		return {}
	candidates.shuffle()
	# Weighted pick: build a bag proportional to rarity weight among legal candidates.
	var bag: Array = []
	for r in candidates:
		var w: int = weights.get(r.rarity, 10)
		for i in w:
			bag.append(r)
	return bag[rng.randi_range(0, bag.size() - 1)]

func rarity_name(r: int) -> String:
	return Rarity.keys()[r].capitalize()

func class_name_of(c: int) -> String:
	return RuleClass.keys()[c].capitalize()

# ---------------------------------------------------------------------
# Rule construction
# ---------------------------------------------------------------------

func _r(id: String, display_name: String, desc: String, rarity: int, cls: int,
		effect_type: String, params: Dictionary, tags: Array = [], excludes: Array = []) -> void:
	rules.append({
		"id": id, "name": display_name, "description": desc, "rarity": rarity, "class": cls,
		"effect": {"type": effect_type, "params": params}, "tags": tags, "excludes": excludes,
	})

func _build_rules() -> void:
	# ---- Movement & traversal ----
	_r("low_grav_1", "Moon Steps I", "Gravity drops 25%. Jumps carry further.", Rarity.COMMON, RuleClass.MOVEMENT, "gravity_scale", {"scale": 0.75})
	_r("low_grav_2", "Moon Steps II", "Gravity drops 45%. Everything floats.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "gravity_scale", {"scale": 0.55})
	_r("low_grav_3", "Moon Steps III", "Gravity drops 65%. Combat turns balletic.", Rarity.RARE, RuleClass.MOVEMENT, "gravity_scale", {"scale": 0.35})
	_r("high_grav_1", "Leaden Air I", "Gravity rises 30%. Jumping gets weaker.", Rarity.COMMON, RuleClass.MOVEMENT, "gravity_scale", {"scale": 1.3})
	_r("high_grav_2", "Leaden Air II", "Gravity rises 60%. Staying airborne is a fight.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "gravity_scale", {"scale": 1.6})
	_r("double_jump", "Second Wind", "Everyone gains a mid-air double jump.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "grant_double_jump", {}, ["grants_jump"])
	_r("no_jump", "Grounded", "Jumping is disabled entirely.", Rarity.RARE, RuleClass.MOVEMENT, "disable_jump", {}, ["disables_jump"])
	_r("no_build", "Bare Hands", "Building structures is disabled entirely.", Rarity.RARE, RuleClass.MOVEMENT, "disable_build", {}, ["disables_build"])
	_r("sprint_forever", "Endless Wind", "Sprint no longer drains stamina.", Rarity.COMMON, RuleClass.MOVEMENT, "infinite_sprint", {})
	_r("speed_up_1", "Quickstep I", "Everyone moves 15% faster.", Rarity.COMMON, RuleClass.MOVEMENT, "speed_scale", {"scale": 1.15})
	_r("speed_up_2", "Quickstep II", "Everyone moves 30% faster.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "speed_scale", {"scale": 1.3})
	_r("slow_down_1", "Molasses I", "Everyone moves 20% slower.", Rarity.COMMON, RuleClass.MOVEMENT, "speed_scale", {"scale": 0.8})
	_r("slow_down_2", "Molasses II", "Everyone moves 35% slower.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "speed_scale", {"scale": 0.65})
	_r("grapple_all", "Everyone's Grappling", "All players get a grapple-hook utility slot.", Rarity.RARE, RuleClass.MOVEMENT, "grant_grapple", {}, ["grants_traversal"])
	_r("jetpack_all", "Everyone's Flying", "All players get a light jetpack.", Rarity.EPIC, RuleClass.MOVEMENT, "grant_jetpack", {}, ["grants_traversal", "grants_jump"])
	_r("no_fall_damage", "Feather Fall", "Fall damage is disabled for everyone.", Rarity.COMMON, RuleClass.MOVEMENT, "disable_fall_damage", {}, ["grants_traversal"])
	_r("random_teleport", "Blink Storm", "Every 30s, all players teleport to a random safe point.", Rarity.EPIC, RuleClass.CHAOS, "periodic_teleport", {"interval": 30.0})
	_r("giant_mode", "Titan Sized", "Everyone doubles in size, gains 50% HP, moves 20% slower.", Rarity.LEGENDARY, RuleClass.CHAOS, "scale_players", {"scale": 2.0, "hp_mult": 1.5, "speed_mult": 0.8})
	_r("tiny_mode", "Pocket Sized", "Everyone shrinks to half size, moves 25% faster, has 30% less HP.", Rarity.LEGENDARY, RuleClass.CHAOS, "scale_players", {"scale": 0.5, "hp_mult": 0.7, "speed_mult": 1.25})

	# ---- Hazards (careful: lethal_floor rules gate against unwinnable states) ----
	_r("floor_lava_1", "The Floor is Lava I", "Standing on natural ground burns for 5/s.", Rarity.EPIC, RuleClass.CHAOS, "hazard_ground", {"dps": 5.0}, ["lethal_floor"])
	_r("floor_lava_2", "The Floor is Lava II", "Standing on natural ground burns for 12/s.", Rarity.LEGENDARY, RuleClass.CHAOS, "hazard_ground", {"dps": 12.0}, ["lethal_floor"])
	_r("acid_rain", "Acid Rain", "Being outdoors and exposed deals 3/s.", Rarity.RARE, RuleClass.CHAOS, "hazard_exposed", {"dps": 3.0})
	_r("storm_speedup", "Storm's Coming Fast", "The next storm circles close 40% faster.", Rarity.UNCOMMON, RuleClass.CHAOS, "storm_speed_scale", {"scale": 1.4})
	_r("storm_slowdown", "Eye of Calm", "The next storm circles close 30% slower.", Rarity.COMMON, RuleClass.CHAOS, "storm_speed_scale", {"scale": 0.7})
	_r("storm_heals", "Inverted Storm", "The storm ring heals instead of hurting; safe zone damages instead.", Rarity.LEGENDARY, RuleClass.CHAOS, "invert_storm", {})
	_r("explosive_deaths", "Going Out With a Bang", "Eliminated players explode, damaging anyone nearby.", Rarity.EPIC, RuleClass.CHAOS, "explosive_death", {"radius": 6.0, "damage": 60.0})
	_r("meteor_showers", "Meteor Shower", "Random small meteors strike the map every 20s.", Rarity.EPIC, RuleClass.CHAOS, "periodic_meteors", {"interval": 20.0, "damage": 45.0, "radius": 4.0})
	_r("one_hp_mode", "Glass Cannons", "Every player is reduced to 1 HP. One hit ends it.", Rarity.LEGENDARY, RuleClass.CHAOS, "set_hp", {"hp": 1})
	_r("mirror_damage", "Shared Pain", "20% of damage dealt is reflected back to the attacker.", Rarity.RARE, RuleClass.CHAOS, "reflect_damage", {"pct": 0.2})

	# ---- Offense class ----
	_r("dmg_up_1", "Sharpened Edge I", "All weapon damage +15%.", Rarity.COMMON, RuleClass.OFFENSE, "damage_scale", {"scale": 1.15})
	_r("dmg_up_2", "Sharpened Edge II", "All weapon damage +30%.", Rarity.UNCOMMON, RuleClass.OFFENSE, "damage_scale", {"scale": 1.3})
	_r("dmg_up_3", "Sharpened Edge III", "All weapon damage +50%.", Rarity.RARE, RuleClass.OFFENSE, "damage_scale", {"scale": 1.5})
	_r("headshots_only", "One and Done", "Headshots are always lethal; body shots deal 50% less.", Rarity.EPIC, RuleClass.OFFENSE, "headshot_lethal", {"body_scale": 0.5})
	_r("crit_chance", "Lucky Strikes", "Every shot has a 20% chance to deal double damage.", Rarity.RARE, RuleClass.OFFENSE, "crit_chance", {"chance": 0.2, "mult": 2.0})
	_r("no_reload", "Bottomless Mags", "Weapons no longer need to reload.", Rarity.UNCOMMON, RuleClass.OFFENSE, "infinite_ammo", {})
	_r("fire_rate_up", "Trigger Happy", "All weapon fire rate +25%.", Rarity.UNCOMMON, RuleClass.OFFENSE, "fire_rate_scale", {"scale": 1.25})
	_r("knockback_up", "Heavy Hitters", "All hits apply strong knockback.", Rarity.COMMON, RuleClass.OFFENSE, "knockback_scale", {"scale": 2.0})
	_r("weapon_evolve_boost", "Momentum Rising", "Evolving weapons upgrade 2x faster.", Rarity.RARE, RuleClass.OFFENSE, "evolve_rate_scale", {"scale": 2.0})
	_r("bleed_on_hit", "Open Wounds", "All hits apply a stacking bleed (2/s for 3s).", Rarity.RARE, RuleClass.OFFENSE, "apply_bleed_on_hit", {"dps": 2.0, "duration": 3.0})

	# ---- Defense class ----
	_r("dmg_down_1", "Thick Skin I", "All damage taken -15%.", Rarity.COMMON, RuleClass.DEFENSE, "damage_taken_scale", {"scale": 0.85})
	_r("dmg_down_2", "Thick Skin II", "All damage taken -30%.", Rarity.UNCOMMON, RuleClass.DEFENSE, "damage_taken_scale", {"scale": 0.7})
	_r("shield_regen", "Auto-Shield", "Shields slowly regenerate outside combat.", Rarity.RARE, RuleClass.DEFENSE, "shield_regen", {"rate": 2.0, "combat_cooldown": 5.0})
	_r("armor_all", "Standard Issue Plates", "Everyone starts with 50 bonus shield.", Rarity.UNCOMMON, RuleClass.DEFENSE, "grant_shield", {"amount": 50})
	_r("damage_cap", "Diminishing Returns", "No single hit can deal more than 40 damage.", Rarity.EPIC, RuleClass.DEFENSE, "damage_cap", {"cap": 40.0})
	_r("revive_enabled", "Second Chances", "Players are downed instead of eliminated; allies can revive them.", Rarity.EPIC, RuleClass.DEFENSE, "enable_revive", {"bleedout_time": 45.0})
	_r("last_stand", "Last Stand", "Downed players can crawl and shoot a sidearm.", Rarity.RARE, RuleClass.DEFENSE, "enable_last_stand", {})

	# ---- Heal class ----
	_r("regen_all_1", "Second Wind I", "Everyone slowly regenerates HP over time.", Rarity.COMMON, RuleClass.HEAL, "hp_regen", {"rate": 1.0})
	_r("regen_all_2", "Second Wind II", "Everyone regenerates HP faster.", Rarity.UNCOMMON, RuleClass.HEAL, "hp_regen", {"rate": 2.5})
	_r("heal_boost", "Field Medic", "Healing items and abilities are 50% more effective.", Rarity.RARE, RuleClass.HEAL, "heal_effect_scale", {"scale": 1.5})
	_r("no_heal_items", "No Bandages", "Healing items are disabled entirely.", Rarity.EPIC, RuleClass.HEAL, "disable_heal_items", {})
	_r("lifesteal_all", "Vampiric Pact", "All damage dealt heals the attacker for 15% of it.", Rarity.RARE, RuleClass.HEAL, "lifesteal_all", {"pct": 0.15})
	_r("heal_pulse", "Healing Pulse", "Every 25s, all players heal 20 HP simultaneously.", Rarity.UNCOMMON, RuleClass.HEAL, "periodic_heal_pulse", {"interval": 25.0, "amount": 20.0})
	_r("overheal", "Overcharge Heal", "Healing can push HP up to 150% of max, decaying slowly.", Rarity.EPIC, RuleClass.HEAL, "overheal", {"cap_pct": 1.5, "decay_rate": 1.0})

	# ---- Utility / loot / visibility ----
	_r("loot_magnet", "Magnetic Pull", "Nearby loot is pulled toward you automatically.", Rarity.COMMON, RuleClass.UTILITY, "loot_magnet", {"radius": 6.0})
	_r("loot_flood", "Loot Flood", "Chest and floor loot spawns are doubled map-wide.", Rarity.UNCOMMON, RuleClass.UTILITY, "loot_density_scale", {"scale": 2.0})
	_r("loot_drought", "Loot Drought", "Chest and floor loot spawns are halved map-wide.", Rarity.RARE, RuleClass.UTILITY, "loot_density_scale", {"scale": 0.5})
	_r("no_loot", "Bring What You Brought", "All new loot spawns are disabled; use what you have.", Rarity.LEGENDARY, RuleClass.UTILITY, "disable_loot_spawns", {})
	_r("vision_pulse", "Recon Sweep", "Every 40s, every player's position is revealed briefly.", Rarity.RARE, RuleClass.UTILITY, "periodic_reveal", {"interval": 40.0, "duration": 4.0})
	_r("footsteps_loud", "Heavy Footfalls", "Footstep sound range is tripled.", Rarity.COMMON, RuleClass.UTILITY, "footstep_range_scale", {"scale": 3.0})
	_r("invisible_still", "Stillness", "Standing perfectly still for 2s turns you nearly invisible.", Rarity.EPIC, RuleClass.UTILITY, "invisible_when_still", {"delay": 2.0})
	_r("random_weapon_kill", "Trophy Swap", "Eliminating a player grants you a random weapon.", Rarity.UNCOMMON, RuleClass.UTILITY, "random_weapon_on_kill", {})
	_r("friendly_fire_on", "Trust No One", "Damage to teammates is enabled (duos/squads modes).", Rarity.RARE, RuleClass.CHAOS, "friendly_fire", {"enabled": true})
	_r("third_person_lock", "Wide Eyes", "Camera is locked to third-person for everyone.", Rarity.COMMON, RuleClass.UTILITY, "force_camera_mode", {"mode": "third_person"})
	_r("first_person_lock", "Tunnel Vision", "Camera is locked to first-person for everyone.", Rarity.UNCOMMON, RuleClass.UTILITY, "force_camera_mode", {"mode": "first_person"})
	_r("supply_drop", "Emergency Supplies", "A supply drop with rare loot falls near the storm edge.", Rarity.RARE, RuleClass.UTILITY, "spawn_supply_drop", {})
	_r("chest_glow", "X Marks the Spot", "All unopened chests glow through walls.", Rarity.COMMON, RuleClass.UTILITY, "reveal_chests", {})

	# ---- Chaos wildcards ----
	_r("weapon_shuffle", "Musical Chairs", "Everyone's held weapon is randomly shuffled once.", Rarity.RARE, RuleClass.CHAOS, "shuffle_weapons_once", {})
	_r("gravity_flip", "Upside Down", "Gravity briefly inverts for 5s every 60s.", Rarity.LEGENDARY, RuleClass.CHAOS, "periodic_gravity_flip", {"interval": 60.0, "duration": 5.0})
	_r("day_night_fast", "Rapid Nightfall", "The day/night cycle speeds up dramatically.", Rarity.COMMON, RuleClass.CHAOS, "daynight_speed_scale", {"scale": 6.0})
	_r("fog_thick", "Rolling Fog", "Visibility distance is cut sharply by fog.", Rarity.UNCOMMON, RuleClass.CHAOS, "fog_density_scale", {"scale": 3.0})
	_r("wind_gusts", "Gale Force", "Strong random wind gusts push players and projectiles.", Rarity.UNCOMMON, RuleClass.CHAOS, "wind_gusts", {"strength": 8.0, "interval": 15.0})
	_r("earthquake", "Tremors", "Periodic screen-shake earthquakes briefly stun anyone airborne on landing.", Rarity.RARE, RuleClass.CHAOS, "periodic_earthquake", {"interval": 35.0})

	# ---- Extra common/uncommon filler tiers to round out the pool ----
	_r("dmg_up_4", "Sharpened Edge IV", "All weapon damage +70%.", Rarity.EPIC, RuleClass.OFFENSE, "damage_scale", {"scale": 1.7})
	_r("dmg_down_3", "Thick Skin III", "All damage taken -45%.", Rarity.RARE, RuleClass.DEFENSE, "damage_taken_scale", {"scale": 0.55})
	_r("speed_up_3", "Quickstep III", "Everyone moves 50% faster.", Rarity.RARE, RuleClass.MOVEMENT, "speed_scale", {"scale": 1.5})
	_r("slow_down_3", "Molasses III", "Everyone moves 50% slower.", Rarity.RARE, RuleClass.MOVEMENT, "speed_scale", {"scale": 0.5})
	_r("regen_all_3", "Second Wind III", "Everyone regenerates HP very fast.", Rarity.RARE, RuleClass.HEAL, "hp_regen", {"rate": 4.0})
	_r("loot_flood_2", "Loot Deluge", "Chest and floor loot spawns are tripled map-wide.", Rarity.RARE, RuleClass.UTILITY, "loot_density_scale", {"scale": 3.0})
	_r("storm_speedup_2", "Storm's Racing", "The next storm circles close 70% faster.", Rarity.RARE, RuleClass.CHAOS, "storm_speed_scale", {"scale": 1.7})
	_r("storm_slowdown_2", "Deep Calm", "The next storm circles close 55% slower.", Rarity.UNCOMMON, RuleClass.CHAOS, "storm_speed_scale", {"scale": 0.45})
	_r("fire_rate_up_2", "Hair Trigger", "All weapon fire rate +50%.", Rarity.RARE, RuleClass.OFFENSE, "fire_rate_scale", {"scale": 1.5})
	_r("heal_boost_2", "Combat Medic", "Healing items and abilities are 100% more effective.", Rarity.EPIC, RuleClass.HEAL, "heal_effect_scale", {"scale": 2.0})
	_r("crit_chance_2", "Fortune Favors", "Every shot has a 35% chance to deal double damage.", Rarity.EPIC, RuleClass.OFFENSE, "crit_chance", {"chance": 0.35, "mult": 2.0})
	_r("lifesteal_all_2", "Blood Pact", "All damage dealt heals the attacker for 30% of it.", Rarity.EPIC, RuleClass.HEAL, "lifesteal_all", {"pct": 0.3})
	_r("shield_regen_2", "Rapid Shield", "Shields regenerate quickly outside combat.", Rarity.EPIC, RuleClass.DEFENSE, "shield_regen", {"rate": 5.0, "combat_cooldown": 3.0})
	_r("bleed_on_hit_2", "Festering Wounds", "All hits apply a stronger stacking bleed (5/s for 4s).", Rarity.EPIC, RuleClass.OFFENSE, "apply_bleed_on_hit", {"dps": 5.0, "duration": 4.0})
	_r("knockback_up_2", "Sledgehammer", "All hits apply massive knockback.", Rarity.UNCOMMON, RuleClass.OFFENSE, "knockback_scale", {"scale": 3.5})
	_r("footsteps_quiet", "Silent Step", "Footstep sound range is cut to almost nothing.", Rarity.UNCOMMON, RuleClass.UTILITY, "footstep_range_scale", {"scale": 0.2})
	_r("fog_light", "Morning Mist", "Visibility distance is mildly reduced by fog.", Rarity.COMMON, RuleClass.CHAOS, "fog_density_scale", {"scale": 1.6})
	_r("wind_gusts_2", "Howling Gale", "Very strong wind gusts push players and projectiles often.", Rarity.RARE, RuleClass.CHAOS, "wind_gusts", {"strength": 14.0, "interval": 10.0})
	_r("meteor_showers_2", "Meteor Storm", "Larger, more frequent meteors strike the map.", Rarity.LEGENDARY, RuleClass.CHAOS, "periodic_meteors", {"interval": 12.0, "damage": 70.0, "radius": 6.0})
	_r("acid_rain_2", "Corrosive Downpour", "Being outdoors and exposed deals 6/s.", Rarity.EPIC, RuleClass.CHAOS, "hazard_exposed", {"dps": 6.0})
	_r("mirror_damage_2", "Twinned Pain", "35% of damage dealt is reflected back to the attacker.", Rarity.EPIC, RuleClass.CHAOS, "reflect_damage", {"pct": 0.35})
	_r("random_teleport_2", "Blink Chaos", "Every 18s, all players teleport to a random safe point.", Rarity.LEGENDARY, RuleClass.CHAOS, "periodic_teleport", {"interval": 18.0})
	_r("vision_pulse_2", "Deep Scan", "Every 22s, every player's position is revealed for longer.", Rarity.EPIC, RuleClass.UTILITY, "periodic_reveal", {"interval": 22.0, "duration": 7.0})
	_r("damage_cap_2", "Hard Cap", "No single hit can deal more than 25 damage.", Rarity.LEGENDARY, RuleClass.DEFENSE, "damage_cap", {"cap": 25.0})
	_r("overheal_2", "Radiant Overcharge", "Healing can push HP up to 200% of max, decaying slowly.", Rarity.LEGENDARY, RuleClass.HEAL, "overheal", {"cap_pct": 2.0, "decay_rate": 1.5})
	_r("no_heal_items_hard", "Total Deprivation", "Healing items AND regen effects are disabled.", Rarity.LEGENDARY, RuleClass.HEAL, "disable_all_healing", {}, [], ["heal_boost", "heal_boost_2", "overheal", "overheal_2"])
	_r("weapon_evolve_boost_2", "Ascendant Momentum", "Evolving weapons upgrade 4x faster.", Rarity.LEGENDARY, RuleClass.OFFENSE, "evolve_rate_scale", {"scale": 4.0})
	_r("earthquake_2", "Cataclysm", "Frequent earthquakes briefly stun anyone airborne on landing.", Rarity.EPIC, RuleClass.CHAOS, "periodic_earthquake", {"interval": 18.0})
	_r("day_night_fast_2", "Flicker", "The day/night cycle cycles extremely fast, strobing light.", Rarity.RARE, RuleClass.CHAOS, "daynight_speed_scale", {"scale": 12.0})
	_r("supply_drop_2", "Airlift", "Two supply drops with rare loot fall near the storm edge.", Rarity.EPIC, RuleClass.UTILITY, "spawn_supply_drop", {"count": 2})
	_r("chest_glow_2", "Beacon", "All unopened chests AND floor loot glow through walls.", Rarity.UNCOMMON, RuleClass.UTILITY, "reveal_chests", {"include_floor_loot": true})
	_r("random_weapon_kill_2", "Grand Trophy", "Eliminating a player grants you a random Epic-or-better weapon.", Rarity.RARE, RuleClass.UTILITY, "random_weapon_on_kill", {"min_rarity": WeaponDatabase.Rarity.EPIC})
	_r("armor_all_2", "Heavy Plates", "Everyone starts with 100 bonus shield.", Rarity.RARE, RuleClass.DEFENSE, "grant_shield", {"amount": 100})
	_r("last_stand_2", "Never Say Die", "Downed players crawl faster and hit harder with their sidearm.", Rarity.EPIC, RuleClass.DEFENSE, "enable_last_stand", {"buffed": true})
	_r("headshots_only_2", "Precision Only", "Headshots are always lethal; body shots deal 75% less.", Rarity.LEGENDARY, RuleClass.OFFENSE, "headshot_lethal", {"body_scale": 0.25})
	_r("friendly_fire_off", "Band of Brothers", "Damage to teammates is disabled (duos/squads modes).", Rarity.COMMON, RuleClass.DEFENSE, "friendly_fire", {"enabled": false})
	_r("no_reload_hard", "Perpetual Motion", "Weapons never need to reload AND fire 20% faster.", Rarity.LEGENDARY, RuleClass.OFFENSE, "infinite_ammo_and_rate", {"rate_scale": 1.2})
	_r("giant_mode_solo", "Colossus", "Killing an enemy makes you 10% bigger and tankier, permanently.", Rarity.LEGENDARY, RuleClass.CHAOS, "growth_on_kill", {"scale_step": 0.1, "hp_step": 0.08})
	_r("explosive_deaths_2", "Chain Reaction", "Eliminated players explode harder, chaining to other explosions nearby.", Rarity.LEGENDARY, RuleClass.CHAOS, "explosive_death", {"radius": 9.0, "damage": 90.0, "chain": true})
	_r("loot_magnet_2", "Vacuum Pull", "Loot is pulled toward you from much farther away.", Rarity.UNCOMMON, RuleClass.UTILITY, "loot_magnet", {"radius": 14.0})
	_r("shield_regen_off", "No Recovery", "Shields no longer regenerate from any source.", Rarity.EPIC, RuleClass.OFFENSE, "disable_shield_regen", {}, [], ["shield_regen", "shield_regen_2"])
	_r("double_jump_2", "Triple Threat", "Everyone gains two extra mid-air jumps.", Rarity.RARE, RuleClass.MOVEMENT, "grant_double_jump", {"extra_jumps": 2}, ["grants_jump"])
	_r("grapple_all_2", "Swing Kings", "All players get a faster, longer-range grapple hook.", Rarity.EPIC, RuleClass.MOVEMENT, "grant_grapple", {"range_scale": 1.6}, ["grants_traversal"])
	_r("no_fall_damage_hard", "Feather Fall+", "Fall damage disabled AND landing gives a small speed burst.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "disable_fall_damage_boost", {}, ["grants_traversal"])
	_r("sprint_forever_2", "Second Lung", "Sprint no longer drains stamina AND sprint speed +10%.", Rarity.UNCOMMON, RuleClass.MOVEMENT, "infinite_sprint_boost", {"scale": 1.1})
	_r("invisible_still_2", "Ghosted", "Standing still for 1s makes you fully invisible.", Rarity.LEGENDARY, RuleClass.UTILITY, "invisible_when_still", {"delay": 1.0, "full_invis": true})
	_r("crit_chance_3", "Death's Coin Flip", "Every shot has a 50% chance to deal double damage.", Rarity.LEGENDARY, RuleClass.OFFENSE, "crit_chance", {"chance": 0.5, "mult": 2.0})

	# ---- The two rules the design brief calls out as mutually exclusive ----
	# floor_lava_* rules already refuse to activate once no_jump + no_build
	# are both active (see can_activate()); no_jump/no_build likewise refuse
	# to stack a second traversal-removing rule once a lethal floor is live,
	# unless a grants_jump/grants_traversal rule (double_jump, grapple_all,
	# jetpack_all, no_fall_damage, ...) is already active to guarantee an escape.
